import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/domain/usecases/get_classroom_subject_lessons_usecase.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_course_content_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlannedLessonRepository implements PlannedLessonRepository {
  FakePlannedLessonRepository(this.lessons);
  final List<PlannedLesson> lessons;

  @override
  Future<List<PlannedLesson>> getByClassroomSubject(
    String classroomSubjectId,
  ) async {
    return lessons
        .where((l) => l.classroomSubjectId == classroomSubjectId)
        .toList();
  }

  @override
  Future<void> save(PlannedLesson lesson) async {}
  @override
  Future<void> saveAll(List<PlannedLesson> list) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<PlannedLesson?> findById(String id) async => null;
  @override
  Future<List<PlannedLesson>> getByDate(DateTime date) async => [];
  @override
  Future<List<PlannedLesson>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async => [];
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftPlannedLessonRepository plannedLessonRepo;
  late DriftLessonExecutionRepository lessonExecutionRepo;
  late DriftCourseContentRepository courseContentRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    plannedLessonRepo = DriftPlannedLessonRepository(db);
    lessonExecutionRepo = DriftLessonExecutionRepository(db);
    courseContentRepo = DriftCourseContentRepository(db);

    // Setup de tabelas base
    await db
        .into(db.academicYearsTable)
        .insert(
          AcademicYearsTableCompanion.insert(
            id: 'ay-test',
            year: 2026,
            title: 'Ano Letivo 2026',
            startDate: DateTime.utc(2026, 2, 2),
            endDate: DateTime.utc(2026, 12, 18),
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.classroomsTable)
        .insert(
          ClassroomsTableCompanion.insert(
            id: 'c-test',
            academicYearId: 'ay-test',
            name: '8º Ano B',
            gradeLevel: '8º Ano',
            shift: 'morning',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.subjectsTable)
        .insert(
          SubjectsTableCompanion.insert(
            id: 's-test',
            name: 'História',
            colorHex: '#795548',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.classroomSubjectsTable)
        .insert(
          ClassroomSubjectsTableCompanion.insert(
            id: 'cs-test',
            classroomId: 'c-test',
            subjectId: 's-test',
            weeklyLessons: 3,
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.subjectsTable)
        .insert(
          SubjectsTableCompanion.insert(
            id: 's-other',
            name: 'Outra Disciplina',
            colorHex: '#9C27B0',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.classroomSubjectsTable)
        .insert(
          ClassroomSubjectsTableCompanion.insert(
            id: 'cs-other',
            classroomId: 'c-test',
            subjectId: 's-other',
            weeklyLessons: 1,
            createdAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('GetClassroomSubjectLessonsUseCase Tests', () {
    test('deve ordenar deterministicamente por (1) data, (2) orderInDay e (3) id como desempate', () async {
      // Criar aulas em ordem embaralhada, incluindo empate de data e orderInDay
      final lessons = [
        PlannedLesson(
          id: 'l-z-empate',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 2,
          status: LessonExecutionStatus.planned,
        ),
        PlannedLesson(
          id: 'l-a-empate',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 2,
          status: LessonExecutionStatus.planned,
        ),
        PlannedLesson(
          id: 'l-primeira-dia',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        ),
        PlannedLesson(
          id: 'l-dia-anterior',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 9),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        ),
        PlannedLesson(
          id: 'l-dia-posterior',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 11),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        ),
      ];

      final fakeRepo = FakePlannedLessonRepository(lessons);

      final useCase = GetClassroomSubjectLessonsUseCase(
        plannedLessonRepository: fakeRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: () => DateTime.utc(2026, 3, 10, 12, 0),
      );

      final result = await useCase.execute(classroomSubjectId: 'cs-test');

      expect(result.length, 5);
      // 1ª aula: dia 9 (orderInDay 1)
      expect(result[0].plannedLesson.id, 'l-dia-anterior');
      // 2ª aula: dia 10 (orderInDay 1)
      expect(result[1].plannedLesson.id, 'l-primeira-dia');
      // 3ª aula: dia 10 (orderInDay 2, id l-a-empate vem antes de l-z-empate)
      expect(result[2].plannedLesson.id, 'l-a-empate');
      // 4ª aula: dia 10 (orderInDay 2, id l-z-empate)
      expect(result[3].plannedLesson.id, 'l-z-empate');
      // 5ª aula: dia 11 (orderInDay 1)
      expect(result[4].plannedLesson.id, 'l-dia-posterior');
    });

    test('deve interpretar fronteiras de datas civis sem distorção por fuso horário (23:59:59 e 00:00:01)', () async {
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-past',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 9),
          orderInDay: 1,
        ),
      );
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-today',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 1,
        ),
      );
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-future',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 11),
          orderInDay: 1,
        ),
      );

      // Cenário A: Clock próximo do fim do dia (23:59:59)
      final useCaseNearMidnight = GetClassroomSubjectLessonsUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: () => DateTime(2026, 3, 10, 23, 59, 59),
      );

      final resultA = await useCaseNearMidnight.execute(
        classroomSubjectId: 'cs-test',
      );
      expect(resultA[0].temporalCategory, LessonTemporalCategory.past);
      expect(resultA[1].temporalCategory, LessonTemporalCategory.today);
      expect(resultA[2].temporalCategory, LessonTemporalCategory.future);

      // Cenário B: Clock no início do dia (00:00:01)
      final useCaseEarlyMorning = GetClassroomSubjectLessonsUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: () => DateTime(2026, 3, 10, 0, 0, 1),
      );

      final resultB = await useCaseEarlyMorning.execute(
        classroomSubjectId: 'cs-test',
      );
      expect(resultB[0].temporalCategory, LessonTemporalCategory.past);
      expect(resultB[1].temporalCategory, LessonTemporalCategory.today);
      expect(resultB[2].temporalCategory, LessonTemporalCategory.future);
    });

    test('deve separar estritamente conteúdos planejados de conteúdos executados e resolver títulos', () async {
      // Cadastrar conteúdos no repositório
      await courseContentRepo.save(
        const CourseContent(
          id: 'cnt-1',
          classroomSubjectId: 'cs-test',
          title: 'Revolução Francesa: Iluminismo',
          orderIndex: 1,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'cnt-2',
          classroomSubjectId: 'cs-test',
          title: 'Revolução Francesa: Queda da Bastilha',
          orderIndex: 2,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'cnt-3',
          classroomSubjectId: 'cs-test',
          title: 'Introdução aos Direitos Humanos',
          orderIndex: 3,
        ),
      );

      // Cadastrar cnt-inexistente em outra disciplina para satisfazer integridade referencial do SQLite,
      // mas permanecer ausente da consulta da disciplina atual ('cs-test') para testar fallback de título.
      await courseContentRepo.save(
        const CourseContent(
          id: 'cnt-inexistente',
          classroomSubjectId: 'cs-other',
          title: 'Conteúdo de Outra Disciplina',
          orderIndex: 1,
        ),
      );

      // Aula planejada com cnt-1, cnt-2 e cnt-inexistente (não cadastrado em cs-test)
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-diff-contents',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 1,
          contentIds: const ['cnt-1', 'cnt-2', 'cnt-inexistente'],
        ),
      );

      // Registro de execução fático onde foi ministrado cnt-1 e cnt-3 (adaptativo/fático)
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-1',
          plannedLessonId: 'l-diff-contents',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 10),
          status: LessonExecutionStatus.partiallyCompleted,
          actualContentIds: const ['cnt-1', 'cnt-3'],
          pedagogicalNotes:
              'Focamos em Iluminismo e fizemos introdução aos direitos.',
          recordedAt: DateTime.utc(2026, 3, 10, 11, 0),
        ),
      );

      final useCase = GetClassroomSubjectLessonsUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: () => DateTime.utc(2026, 3, 10, 12, 0),
      );

      final result = await useCase.execute(classroomSubjectId: 'cs-test');
      expect(result.length, 1);

      final item = result.first;
      // Conteúdos planejados (incluindo fallback de ID inexistente)
      expect(item.plannedContentTitles, [
        'Revolução Francesa: Iluminismo',
        'Revolução Francesa: Queda da Bastilha',
        'cnt-inexistente',
      ]);

      // Conteúdos executados fáticos
      expect(item.actualContentTitles, [
        'Revolução Francesa: Iluminismo',
        'Introdução aos Direitos Humanos',
      ]);

      // Status efetivo e apontamento
      expect(item.hasExecutionRecord, isTrue);
      expect(item.effectiveStatus, LessonExecutionStatus.partiallyCompleted);
      expect(item.isPastUnrecorded, isFalse);
    });

    test('deve identificar aulas passadas sem registro como isPastUnrecorded == true', () async {
      // Aula no passado sem registro de execução
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-past-unrecorded',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 8),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        ),
      );

      // Aula no passado com registro de execução
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-past-recorded',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 9),
          orderInDay: 1,
          status: LessonExecutionStatus.completed,
        ),
      );
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-past',
          plannedLessonId: 'l-past-recorded',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 9),
          status: LessonExecutionStatus.completed,
          recordedAt: DateTime.utc(2026, 3, 9, 12, 0),
        ),
      );

      // Aula de hoje sem registro
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-today-unrecorded',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        ),
      );

      // Aula futura sem registro
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-future-unrecorded',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 11),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        ),
      );

      final useCase = GetClassroomSubjectLessonsUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: () => DateTime.utc(2026, 3, 10, 10, 0),
      );

      final result = await useCase.execute(classroomSubjectId: 'cs-test');
      expect(result.length, 4);

      // 1. Passada sem registro -> isPastUnrecorded == true
      expect(result[0].plannedLesson.id, 'l-past-unrecorded');
      expect(result[0].temporalCategory, LessonTemporalCategory.past);
      expect(result[0].hasExecutionRecord, isFalse);
      expect(result[0].isPastUnrecorded, isTrue);

      // 2. Passada com registro -> isPastUnrecorded == false
      expect(result[1].plannedLesson.id, 'l-past-recorded');
      expect(result[1].temporalCategory, LessonTemporalCategory.past);
      expect(result[1].hasExecutionRecord, isTrue);
      expect(result[1].isPastUnrecorded, isFalse);

      // 3. Hoje sem registro -> isPastUnrecorded == false
      expect(result[2].plannedLesson.id, 'l-today-unrecorded');
      expect(result[2].temporalCategory, LessonTemporalCategory.today);
      expect(result[2].hasExecutionRecord, isFalse);
      expect(result[2].isPastUnrecorded, isFalse);

      // 4. Futura sem registro -> isPastUnrecorded == false
      expect(result[3].plannedLesson.id, 'l-future-unrecorded');
      expect(result[3].temporalCategory, LessonTemporalCategory.future);
      expect(result[3].hasExecutionRecord, isFalse);
      expect(result[3].isPastUnrecorded, isFalse);
    });

    test('deve incluir justificativa de cancelamento e notas pedagógicas quando a aula não foi realizada', () async {
      await plannedLessonRepo.save(
        PlannedLesson(
          id: 'l-not-held',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 1,
          notes: 'Nota original do planejamento: Levar mapas.',
        ),
      );

      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-not-held',
          plannedLessonId: 'l-not-held',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 10),
          status: LessonExecutionStatus.notHeld,
          cancellationReason: LessonCancellationReason.schoolEvent,
          cancellationDetails: 'Conselho Pedagógico Extraordinário',
          pedagogicalNotes: 'Aula remarcada para semana que vem.',
          needsFollowUp: true,
          followUpNotes: 'Reagendar conteúdo de mapas.',
          recordedAt: DateTime.utc(2026, 3, 10, 14, 0),
        ),
      );

      final useCase = GetClassroomSubjectLessonsUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: () => DateTime.utc(2026, 3, 10, 16, 0),
      );

      final result = await useCase.execute(classroomSubjectId: 'cs-test');
      expect(result.length, 1);

      final item = result.first;
      expect(item.effectiveStatus, LessonExecutionStatus.notHeld);
      expect(
        item.executionRecord!.cancellationReason,
        LessonCancellationReason.schoolEvent,
      );
      expect(
        item.executionRecord!.cancellationDetails,
        'Conselho Pedagógico Extraordinário',
      );
      expect(
        item.executionRecord!.pedagogicalNotes,
        'Aula remarcada para semana que vem.',
      );
      expect(item.executionRecord!.needsFollowUp, isTrue);
      expect(
        item.executionRecord!.followUpNotes,
        'Reagendar conteúdo de mapas.',
      );
      expect(
        item.plannedLesson.notes,
        'Nota original do planejamento: Levar mapas.',
      );
    });
  });
}
