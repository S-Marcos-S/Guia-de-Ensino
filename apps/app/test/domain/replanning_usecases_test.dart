import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/replanning_models.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/domain/services/replanning_engine_service.dart';
import 'package:app/domain/usecases/apply_replanning_proposal_usecase.dart';
import 'package:app/domain/usecases/detect_schedule_delay_usecase.dart';
import 'package:app/domain/usecases/generate_replanning_proposal_usecase.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_calendar_event_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_course_content_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_schedule_slot_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftAcademicYearRepository academicYearRepo;
  late DriftClassroomRepository classroomRepo;
  late DriftCalendarEventRepository calendarEventRepo;
  late DriftScheduleSlotRepository scheduleSlotRepo;
  late DriftCourseContentRepository courseContentRepo;
  late DriftPlannedLessonRepository plannedLessonRepo;
  late DriftLessonExecutionRepository lessonExecutionRepo;

  late DetectScheduleDelayUseCase detectDelayUseCase;
  late GenerateReplanningProposalUseCase generateProposalUseCase;
  late ApplyReplanningProposalUseCase applyProposalUseCase;

  DateTime testClock() => DateTime.utc(2026, 2, 10, 12, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    academicYearRepo = DriftAcademicYearRepository(db);
    classroomRepo = DriftClassroomRepository(db);
    calendarEventRepo = DriftCalendarEventRepository(db);
    scheduleSlotRepo = DriftScheduleSlotRepository(db);
    courseContentRepo = DriftCourseContentRepository(db);
    plannedLessonRepo = DriftPlannedLessonRepository(db);
    lessonExecutionRepo = DriftLessonExecutionRepository(db);

    const replanningEngineService = ReplanningEngineService();
    const calendarCalculationService = CalendarCalculationService();

    detectDelayUseCase = DetectScheduleDelayUseCase(
      plannedLessonRepository: plannedLessonRepo,
      lessonExecutionRepository: lessonExecutionRepo,
      courseContentRepository: courseContentRepo,
      replanningEngineService: replanningEngineService,
      clock: testClock,
    );

    generateProposalUseCase = GenerateReplanningProposalUseCase(
      classroomRepository: classroomRepo,
      academicYearRepository: academicYearRepo,
      calendarEventRepository: calendarEventRepo,
      calendarCalculationService: calendarCalculationService,
      scheduleSlotRepository: scheduleSlotRepo,
      courseContentRepository: courseContentRepo,
      plannedLessonRepository: plannedLessonRepo,
      lessonExecutionRepository: lessonExecutionRepo,
      replanningEngineService: replanningEngineService,
      clock: testClock,
    );

    applyProposalUseCase = ApplyReplanningProposalUseCase(
      plannedLessonRepository: plannedLessonRepo,
      lessonExecutionRepository: lessonExecutionRepo,
    );

    // Setup base do ano letivo 2026
    await db.into(db.academicYearsTable).insert(
      AcademicYearsTableCompanion.insert(
        id: 'ay-test',
        year: 2026,
        title: 'Ano Letivo 2026',
        startDate: DateTime.utc(2026, 2, 2),
        endDate: DateTime.utc(2026, 12, 18),
        createdAt: DateTime.now(),
      ),
    );

    // Turma 6º Ano A
    await db.into(db.classroomsTable).insert(
      ClassroomsTableCompanion.insert(
        id: 'c-test',
        academicYearId: 'ay-test',
        name: '6º Ano A',
        gradeLevel: '6º Ano',
        shift: 'morning',
        createdAt: DateTime.now(),
      ),
    );

    // Disciplina Matemática
    await db.into(db.subjectsTable).insert(
      SubjectsTableCompanion.insert(
        id: 's-test',
        name: 'Matemática',
        colorHex: '#2196F3',
        createdAt: DateTime.now(),
      ),
    );

    // Vínculo Turma-Disciplina
    await db.into(db.classroomSubjectsTable).insert(
      ClassroomSubjectsTableCompanion.insert(
        id: 'cs-test',
        classroomId: 'c-test',
        subjectId: 's-test',
        weeklyLessons: 2,
        createdAt: DateTime.now(),
      ),
    );

    // Grade semanal: Segundas-feiras aula 1
    await scheduleSlotRepo.save(
      const ScheduleSlot(
        id: 'slot-seg-1',
        classroomSubjectId: 'cs-test',
        weekday: 1, // Segunda
        orderIndex: 1,
      ),
    );

    // Conteúdos da disciplina
    await courseContentRepo.save(
      const CourseContent(
        id: 'c1',
        classroomSubjectId: 'cs-test',
        title: 'Frações Básicas',
        estimatedLessons: 2,
        orderIndex: 1,
        isMandatory: true,
        origin: ContentOrigin.manual,
      ),
    );
    await courseContentRepo.save(
      const CourseContent(
        id: 'c2',
        classroomSubjectId: 'cs-test',
        title: 'Frações Equivalentes',
        estimatedLessons: 1,
        orderIndex: 2,
        isMandatory: true,
        origin: ContentOrigin.manual,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Casos de Uso de Replanejamento - Integração e Salvaguardas', () {
    test('DetectScheduleDelayUseCase identifica ausência de atraso quando cronograma está regular', () async {
      // Aula em 02/02 realizada
      final l1 = PlannedLesson(
        id: 'l1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 2),
        orderInDay: 1,
        contentIds: const ['c1'],
        status: LessonExecutionStatus.completed,
      );
      await plannedLessonRepo.save(l1);

      final r1 = LessonExecutionRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        classroomSubjectId: 'cs-test',
        executionDate: DateTime.utc(2026, 2, 2),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
        recordedAt: DateTime.utc(2026, 2, 2, 12, 0),
      );
      await lessonExecutionRepo.save(r1);

      // Aula em 09/02 realizada
      final l2 = PlannedLesson(
        id: 'l2',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 9),
        orderInDay: 1,
        contentIds: const ['c1'],
        status: LessonExecutionStatus.completed,
      );
      await plannedLessonRepo.save(l2);

      final r2 = LessonExecutionRecord(
        id: 'r2',
        plannedLessonId: 'l2',
        classroomSubjectId: 'cs-test',
        executionDate: DateTime.utc(2026, 2, 9),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
        recordedAt: DateTime.utc(2026, 2, 9, 12, 0),
      );
      await lessonExecutionRepo.save(r2);

      // Em 10/02/2026, ambas as aulas passadas foram cumpridas
      final result = await detectDelayUseCase.execute(
        classroomSubjectId: 'cs-test',
        referenceDate: testClock(),
      );

      expect(result.hasDelay, isFalse);
      expect(result.notHeldCount, 0);
      expect(result.summaryMessage, contains('Cronograma em dia'));
    });

    test('DetectScheduleDelayUseCase identifica atraso fático quando aula foi cancelada (notHeld)', () async {
      final l1 = PlannedLesson(
        id: 'l1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 2),
        orderInDay: 1,
        contentIds: const ['c1'],
        status: LessonExecutionStatus.notHeld,
      );
      await plannedLessonRepo.save(l1);

      final r1 = LessonExecutionRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        classroomSubjectId: 'cs-test',
        executionDate: DateTime.utc(2026, 2, 2),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.teacherAbsence,
        recordedAt: DateTime.utc(2026, 2, 2, 12, 0),
      );
      await lessonExecutionRepo.save(r1);

      final result = await detectDelayUseCase.execute(
        classroomSubjectId: 'cs-test',
        referenceDate: testClock(),
      );

      expect(result.hasDelay, isTrue);
      expect(result.notHeldCount, 1);
      expect(result.delayReasons.first, contains('Aula cancelada'));
    });

    test('GenerateReplanningProposalUseCase orquestra e gera proposta comparativa estruturada', () async {
      // Aula de 02/02 cancelada
      final l1 = PlannedLesson(
        id: 'l1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 2),
        orderInDay: 1,
        contentIds: const ['c1'],
        status: LessonExecutionStatus.notHeld,
      );
      await plannedLessonRepo.save(l1);

      final r1 = LessonExecutionRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        classroomSubjectId: 'cs-test',
        executionDate: DateTime.utc(2026, 2, 2),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.infrastructureIssue,
        recordedAt: DateTime.utc(2026, 2, 2, 12, 0),
      );
      await lessonExecutionRepo.save(r1);

      // Aulas futuras planejadas existentes
      final l2 = PlannedLesson(
        id: 'l2',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 9),
        orderInDay: 1,
        contentIds: const ['c1'],
      );
      final l3 = PlannedLesson(
        id: 'l3',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 16),
        orderInDay: 1,
        contentIds: const ['c2'],
      );
      await plannedLessonRepo.saveAll([l2, l3]);

      final proposal = await generateProposalUseCase.execute(
        classroomSubjectId: 'cs-test',
        referenceDate: testClock(),
      );

      expect(proposal.classroomSubjectId, 'cs-test');
      expect(proposal.preservedHistoricLessonsCount, 1);
      expect(proposal.planningResult.isSuccessful, isTrue);
      expect(proposal.shifts.isNotEmpty, isTrue);

      // A aula histórica em 02/02 deve estar preservada no shift
      final historicShift = proposal.shifts.firstWhere((s) => s.plannedLessonId == 'l1');
      expect(historicShift.isPreservedHistoric, isTrue);
      expect(historicShift.shiftType, LessonReplanningShiftType.unchanged);
    });

    test('ApplyReplanningProposalUseCase persiste novas aulas e preserva registro factual', () async {
      final l1 = PlannedLesson(
        id: 'l1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 2),
        orderInDay: 1,
        contentIds: const ['c1'],
        status: LessonExecutionStatus.notHeld,
      );
      await plannedLessonRepo.save(l1);

      final r1 = LessonExecutionRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        classroomSubjectId: 'cs-test',
        executionDate: DateTime.utc(2026, 2, 2),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.teacherAbsence,
        recordedAt: DateTime.utc(2026, 2, 2, 12, 0),
      );
      await lessonExecutionRepo.save(r1);

      final proposal = await generateProposalUseCase.execute(
        classroomSubjectId: 'cs-test',
        referenceDate: testClock(),
      );

      // Aplica a proposta homologada
      await applyProposalUseCase.execute(proposal);

      // Verifica no banco real Drift se o registro factual de l1 continuou 100% intacto
      final savedRecord = await lessonExecutionRepo.findById('r1');
      expect(savedRecord, isNotNull);
      expect(savedRecord!.status, LessonExecutionStatus.notHeld);
      expect(savedRecord.cancellationReason, LessonCancellationReason.teacherAbsence);

      // Verifica se a aula histórica l1 continuou salva
      final savedHistoricLesson = await plannedLessonRepo.findById('l1');
      expect(savedHistoricLesson, isNotNull);
      expect(savedHistoricLesson!.date, DateTime.utc(2026, 2, 2));

      // Verifica se as aulas futuras foram geradas e salvas
      final allLessons = await plannedLessonRepo.getByClassroomSubject('cs-test');
      expect(allLessons.length, greaterThanOrEqualTo(3));
    });

    test('Salvaguarda 4 - Idempotência da aplicação: aplicar repetidas vezes não duplica registros', () async {
      final l1 = PlannedLesson(
        id: 'l1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 2),
        orderInDay: 1,
        contentIds: const ['c1'],
        status: LessonExecutionStatus.completed,
      );
      await plannedLessonRepo.save(l1);

      final r1 = LessonExecutionRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        classroomSubjectId: 'cs-test',
        executionDate: DateTime.utc(2026, 2, 2),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
        recordedAt: DateTime.utc(2026, 2, 2, 12, 0),
      );
      await lessonExecutionRepo.save(r1);

      final proposal = await generateProposalUseCase.execute(
        classroomSubjectId: 'cs-test',
        referenceDate: testClock(),
      );

      // 1ª Aplicação
      await applyProposalUseCase.execute(proposal);
      final countFirst = (await plannedLessonRepo.getByClassroomSubject('cs-test')).length;

      // 2ª Aplicação consecutiva da mesma proposta
      await applyProposalUseCase.execute(proposal);
      final countSecond = (await plannedLessonRepo.getByClassroomSubject('cs-test')).length;

      expect(countSecond, countFirst, reason: 'Aplicação repetida não deve duplicar aulas');
    });

    test('Salvaguarda 6 - Concorrência: proposta desatualizada é rejeitada com OutdatedReplanningProposalException', () async {
      final l1 = PlannedLesson(
        id: 'l1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 2, 2),
        orderInDay: 1,
        contentIds: const ['c1'],
      );
      await plannedLessonRepo.save(l1);

      // Gera proposta baseada no estado atual (sem registros)
      final proposal = await generateProposalUseCase.execute(
        classroomSubjectId: 'cs-test',
        referenceDate: testClock(),
      );

      // Intercorrência: antes de homologar a proposta, um apontamento fático é gravado no diário!
      final rIntercorrencia = LessonExecutionRecord(
        id: 'r-novo',
        plannedLessonId: 'l1',
        classroomSubjectId: 'cs-test',
        executionDate: DateTime.utc(2026, 2, 2),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
        recordedAt: DateTime.now().toUtc(),
      );
      await lessonExecutionRepo.save(rIntercorrencia);

      // Tentar aplicar a proposta obsoleta deve lançar OutdatedReplanningProposalException
      expect(
        () => applyProposalUseCase.execute(proposal),
        throwsA(isA<OutdatedReplanningProposalException>()),
      );
    });
  });
}
