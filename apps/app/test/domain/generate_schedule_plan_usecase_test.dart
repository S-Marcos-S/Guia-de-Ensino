import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/domain/services/planning_engine_service.dart';
import 'package:app/domain/usecases/generate_schedule_plan_usecase.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_calendar_event_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_course_content_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_schedule_slot_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_subject_repository.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftAcademicYearRepository academicYearRepo;
  late DriftClassroomRepository classroomRepo;
  late DriftSubjectRepository subjectRepo;
  late DriftCalendarEventRepository calendarEventRepo;
  late DriftScheduleSlotRepository scheduleSlotRepo;
  late DriftCourseContentRepository courseContentRepo;
  late DriftPlannedLessonRepository plannedLessonRepo;
  late GenerateSchedulePlanUseCase useCase;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    academicYearRepo = DriftAcademicYearRepository(db);
    classroomRepo = DriftClassroomRepository(db);
    subjectRepo = DriftSubjectRepository(db);
    calendarEventRepo = DriftCalendarEventRepository(db);
    scheduleSlotRepo = DriftScheduleSlotRepository(db);
    courseContentRepo = DriftCourseContentRepository(db);
    plannedLessonRepo = DriftPlannedLessonRepository(db);

    useCase = GenerateSchedulePlanUseCase(
      planningEngineService: const PlanningEngineService(),
      calendarCalculationService: const CalendarCalculationService(),
      academicYearRepository: academicYearRepo,
      classroomRepository: classroomRepo,
      calendarEventRepository: calendarEventRepo,
      scheduleSlotRepository: scheduleSlotRepo,
      courseContentRepository: courseContentRepo,
      plannedLessonRepository: plannedLessonRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('executa preview de planejamento e persiste via applyPlan preservando integridade', () async {
    // 1. Cadastra Ano Letivo (Fevereiro 2026, 2 segundas-feiras: 02/02 e 09/02)
    final year = AcademicYear(
      id: 'ay-usecase',
      year: 2026,
      title: 'Ano Letivo 2026',
      startDate: DateTime.utc(2026, 2, 1),
      endDate: DateTime.utc(2026, 2, 15),
      totalMandatoryDays: 10,
    );
    await academicYearRepo.save(year);

    // 2. Cadastra Disciplina e Turma
    const subject = Subject(
      id: 's-mat',
      name: 'Matemática',
      colorHex: '#2196F3',
    );
    await subjectRepo.save(subject);

    const csConfig = ClassroomSubjectConfig(
      id: 'cs-mat-6a',
      classroomId: 'c-6a',
      subjectId: 's-mat',
      weeklyLessons: 1,
    );

    const classroom = Classroom(
      id: 'c-6a',
      academicYearId: 'ay-usecase',
      name: '6º Ano A',
      gradeLevel: '6º Ano',
      shift: ClassroomShift.morning,
      subjectConfigs: [csConfig],
    );
    await classroomRepo.save(classroom);

    // 3. Cadastra Grade Semanal (Segunda-feira, 1ª aula)
    const slot = ScheduleSlot(
      id: 'slot-seg-1',
      classroomSubjectId: 'cs-mat-6a',
      weekday: 1,
      orderIndex: 1,
    );
    await scheduleSlotRepo.saveSlots('cs-mat-6a', [slot]);

    // 4. Cadastra 2 Conteúdos Programáticos (1 aula cada)
    const content1 = CourseContent(
      id: 'cnt-1',
      classroomSubjectId: 'cs-mat-6a',
      title: 'Sistemas de Numeração',
      estimatedLessons: 1,
      orderIndex: 1,
      origin: ContentOrigin.manual,
    );
    const content2 = CourseContent(
      id: 'cnt-2',
      classroomSubjectId: 'cs-mat-6a',
      title: 'Operações com Naturais',
      estimatedLessons: 1,
      orderIndex: 2,
      origin: ContentOrigin.manual,
    );
    await courseContentRepo.save(content1);
    await courseContentRepo.save(content2);

    // 5. Executa preview do planejamento
    final result = await useCase.execute(classroomSubjectId: 'cs-mat-6a');

    expect(result.isSuccessful, isTrue);
    expect(result.availableLessonOccurrences, 2);
    expect(result.usedLessonOccurrences, 2);
    expect(result.plannedLessons.length, 2);
    expect(result.plannedLessons[0].contentIds, ['cnt-1']);
    expect(result.plannedLessons[1].contentIds, ['cnt-2']);

    // Verifica que nada foi gravado no banco ainda
    final initialLessons = await plannedLessonRepo.getByClassroomSubject(
      'cs-mat-6a',
    );
    expect(initialLessons, isEmpty);

    // 6. Aplica o plano homologado
    await useCase.applyPlan(result);

    // 7. Confirma persistência real das aulas e vínculos no banco
    final persistedLessons = await plannedLessonRepo.getByClassroomSubject(
      'cs-mat-6a',
    );
    expect(persistedLessons.length, 2);
    expect(persistedLessons[0].contentIds, ['cnt-1']);
    expect(persistedLessons[1].contentIds, ['cnt-2']);
    expect(persistedLessons[0].date, DateTime.utc(2026, 2, 2));
    expect(persistedLessons[1].date, DateTime.utc(2026, 2, 9));
  });

  test('replanejamento preserva aula já executada e atualiza apenas aulas puramente planejadas', () async {
    // Ano Letivo com 3 segundas (02/02, 09/02, 16/02)
    final year = AcademicYear(
      id: 'ay-hist',
      year: 2026,
      title: 'Ano Letivo 2026',
      startDate: DateTime.utc(2026, 2, 1),
      endDate: DateTime.utc(2026, 2, 22),
      totalMandatoryDays: 15,
    );
    await academicYearRepo.save(year);

    const subject = Subject(id: 's-cie', name: 'Ciências', colorHex: '#4CAF50');
    await subjectRepo.save(subject);

    const csConfig = ClassroomSubjectConfig(
      id: 'cs-cie-7a',
      classroomId: 'c-7a',
      subjectId: 's-cie',
      weeklyLessons: 1,
    );
    const classroom = Classroom(
      id: 'c-7a',
      academicYearId: 'ay-hist',
      name: '7º Ano A',
      gradeLevel: '7º Ano',
      shift: ClassroomShift.morning,
      subjectConfigs: [csConfig],
    );
    await classroomRepo.save(classroom);

    const slot = ScheduleSlot(
      id: 'slot-seg-cie',
      classroomSubjectId: 'cs-cie-7a',
      weekday: 1,
      orderIndex: 1,
    );
    await scheduleSlotRepo.saveSlots('cs-cie-7a', [slot]);

    const content1 = CourseContent(
      id: 'cnt-bio-1',
      classroomSubjectId: 'cs-cie-7a',
      title: 'Vírus e Bactérias',
      estimatedLessons: 1,
      orderIndex: 1,
      origin: ContentOrigin.manual,
    );
    const content2 = CourseContent(
      id: 'cnt-bio-2',
      classroomSubjectId: 'cs-cie-7a',
      title: 'Vacinas e Saúde',
      estimatedLessons: 1,
      orderIndex: 2,
      origin: ContentOrigin.manual,
    );
    await courseContentRepo.save(content1);
    await courseContentRepo.save(content2);

    // Já existe uma aula em 02/02 com status 'completed' (histórico sagrado)
    final completedLesson = PlannedLesson(
      id: 'hist-aula-01',
      classroomSubjectId: 'cs-cie-7a',
      date: DateTime.utc(2026, 2, 2),
      orderInDay: 1,
      contentIds: ['cnt-bio-1'],
      status: LessonExecutionStatus.completed,
    );
    await plannedLessonRepo.save(completedLesson);

    // Executa planejamento
    final result = await useCase.execute(classroomSubjectId: 'cs-cie-7a');

    expect(result.isSuccessful, isTrue);
    expect(result.preservedLessons.length, 1);
    expect(result.preservedLessons.first.id, 'hist-aula-01');

    // Aplica o plano
    await useCase.applyPlan(result);

    final finalLessons = await plannedLessonRepo.getByClassroomSubject(
      'cs-cie-7a',
    );
    expect(finalLessons.length, 2);

    // Aula histórica intacta com seu ID original e status completed
    final lesson1 = finalLessons.firstWhere(
      (l) => l.date == DateTime.utc(2026, 2, 2),
    );
    expect(lesson1.id, 'hist-aula-01');
    expect(lesson1.status, LessonExecutionStatus.completed);

    // Aula 2 alocada para o próximo dia livre (09/02)
    final lesson2 = finalLessons.firstWhere(
      (l) => l.date == DateTime.utc(2026, 2, 9),
    );
    expect(lesson2.contentIds, ['cnt-bio-2']);
    expect(lesson2.status, LessonExecutionStatus.planned);
  });
}
