import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/usecases/get_classroom_subject_progress_usecase.dart';
import 'package:app/domain/usecases/get_pending_lessons_usecase.dart';
import 'package:app/domain/usecases/record_lesson_execution_usecase.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_course_content_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftPlannedLessonRepository plannedLessonRepo;
  late DriftLessonExecutionRepository lessonExecutionRepo;
  late DriftCourseContentRepository courseContentRepo;

  // Relógio fixo controlado para testes: 10 de Março de 2026, 10:00 UTC
  DateTime testClock() => DateTime.utc(2026, 3, 10, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    plannedLessonRepo = DriftPlannedLessonRepository(db);
    lessonExecutionRepo = DriftLessonExecutionRepository(db);
    courseContentRepo = DriftCourseContentRepository(db);

    // Setup base de ano letivo, turma e disciplina
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
            name: '7º Ano A',
            gradeLevel: '7º Ano',
            shift: 'morning',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.subjectsTable)
        .insert(
          SubjectsTableCompanion.insert(
            id: 's-test',
            name: 'Matemática',
            colorHex: '#2196F3',
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
            weeklyLessons: 4,
            createdAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('RecordLessonExecutionUseCase Tests', () {
    test('deve registrar uma nova execução e atualizar a aula planejada sem sobrescrever notas de planejamento', () async {
      final useCase = RecordLessonExecutionUseCase(
        lessonExecutionRepository: lessonExecutionRepo,
        plannedLessonRepository: plannedLessonRepo,
        clock: testClock,
      );

      // Cria aula planejada com anotação prévia de planejamento
      final plannedLesson = PlannedLesson(
        id: 'l-rec-1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 9),
        orderInDay: 1,
        status: LessonExecutionStatus.planned,
        notes: 'Planejamento: Usar sala de vídeo e projetor.',
      );
      await plannedLessonRepo.save(plannedLesson);

      // Cria conteúdo
      const content = CourseContent(
        id: 'cnt-rec-1',
        classroomSubjectId: 'cs-test',
        title: 'Frações Equivalentes',
        orderIndex: 1,
      );
      await courseContentRepo.save(content);

      // Executa apontamento docente
      final saved = await useCase.execute(
        RecordLessonExecutionParams(
          plannedLessonId: 'l-rec-1',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 9),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['cnt-rec-1'],
          pedagogicalNotes:
              'Diário: Aula concluída, alunos entenderam equivalência.',
        ),
      );

      expect(saved.plannedLessonId, equals('l-rec-1'));
      expect(saved.status, equals(LessonExecutionStatus.completed));
      expect(saved.actualContentIds, equals(['cnt-rec-1']));
      expect(saved.recordedAt, equals(DateTime.utc(2026, 3, 10, 10, 0)));
      expect(saved.updatedAt, isNull);

      // Valida que a PlannedLesson foi sincronizada com status completed,
      // mas manteve a nota original de planejamento!
      final updatedPlanned = await plannedLessonRepo.findById('l-rec-1');
      expect(updatedPlanned!.status, equals(LessonExecutionStatus.completed));
      expect(
        updatedPlanned.notes,
        equals('Planejamento: Usar sala de vídeo e projetor.'),
      );
    });

    test('deve retificar execução existente preservando recordedAt e atualizando updatedAt', () async {
      var currentTime = DateTime.utc(2026, 3, 10, 8, 0);
      final useCase = RecordLessonExecutionUseCase(
        lessonExecutionRepository: lessonExecutionRepo,
        plannedLessonRepository: plannedLessonRepo,
        clock: () => currentTime,
      );

      final plannedLesson = PlannedLesson(
        id: 'l-retif-1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 9),
        orderInDay: 1,
        status: LessonExecutionStatus.planned,
      );
      await plannedLessonRepo.save(plannedLesson);

      // 1. Gravação inicial às 08:00
      final initial = await useCase.execute(
        RecordLessonExecutionParams(
          plannedLessonId: 'l-retif-1',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 9),
          status: LessonExecutionStatus.partiallyCompleted,
          pedagogicalNotes: 'Aula parcial por falta de tempo.',
          needsFollowUp: true,
        ),
      );
      expect(initial.recordedAt, equals(DateTime.utc(2026, 3, 10, 8, 0)));
      expect(initial.updatedAt, isNull);

      // 2. Retificação às 14:00 do mesmo dia
      currentTime = DateTime.utc(2026, 3, 10, 14, 0);
      final rectified = await useCase.execute(
        RecordLessonExecutionParams(
          plannedLessonId: 'l-retif-1',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 9),
          status: LessonExecutionStatus.completed,
          pedagogicalNotes: 'Retificado: atividade complementar finalizada.',
          needsFollowUp: false,
        ),
      );

      // ID e recordedAt devem ser rigorosamente idênticos
      expect(rectified.id, equals(initial.id));
      expect(rectified.recordedAt, equals(DateTime.utc(2026, 3, 10, 8, 0)));
      // updatedAt deve ser o novo horário
      expect(rectified.updatedAt, equals(DateTime.utc(2026, 3, 10, 14, 0)));
      expect(rectified.isRectified, isTrue);
      expect(rectified.status, equals(LessonExecutionStatus.completed));
    });

    test('deve permitir que conteúdos reais divirjam dos planejados', () async {
      final useCase = RecordLessonExecutionUseCase(
        lessonExecutionRepository: lessonExecutionRepo,
        plannedLessonRepository: plannedLessonRepo,
        clock: testClock,
      );

      const c1 = CourseContent(
        id: 'cnt-p1',
        classroomSubjectId: 'cs-test',
        title: 'Conteúdo Planejado',
        orderIndex: 1,
      );
      const c2 = CourseContent(
        id: 'cnt-r2',
        classroomSubjectId: 'cs-test',
        title: 'Conteúdo Real Efetivo',
        orderIndex: 2,
      );
      await courseContentRepo.save(c1);
      await courseContentRepo.save(c2);

      // Aula planejada com c1
      final plannedLesson = PlannedLesson(
        id: 'l-diff-1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 9),
        orderInDay: 1,
        contentIds: ['cnt-p1'],
        status: LessonExecutionStatus.planned,
      );
      await plannedLessonRepo.save(plannedLesson);

      // Docente precisou ministrar c2 em vez de c1
      final record = await useCase.execute(
        RecordLessonExecutionParams(
          plannedLessonId: 'l-diff-1',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 9),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['cnt-r2'],
          pedagogicalNotes:
              'Conteúdo adaptado para suprir lacuna de pré-requisito.',
        ),
      );

      expect(record.actualContentIds, equals(['cnt-r2']));
      expect(record.actualContentIds, isNot(contains('cnt-p1')));
    });

    test('deve lançar exceção se aula planejada não existir', () async {
      final useCase = RecordLessonExecutionUseCase(
        lessonExecutionRepository: lessonExecutionRepo,
        plannedLessonRepository: plannedLessonRepo,
        clock: testClock,
      );

      expect(
        () async => await useCase.execute(
          RecordLessonExecutionParams(
            plannedLessonId: 'inexistente',
            classroomSubjectId: 'cs-test',
            executionDate: DateTime.utc(2026, 3, 9),
            status: LessonExecutionStatus.completed,
          ),
        ),
        throwsA(isA<LessonExecutionIntegrityException>()),
      );
    });

    test(
      'deve lançar exceção se houver divergência de turma/disciplina',
      () async {
        final useCase = RecordLessonExecutionUseCase(
          lessonExecutionRepository: lessonExecutionRepo,
          plannedLessonRepository: plannedLessonRepo,
          clock: testClock,
        );

        final plannedLesson = PlannedLesson(
          id: 'l-div-1',
          classroomSubjectId: 'cs-test',
          date: DateTime.utc(2026, 3, 9),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        );
        await plannedLessonRepo.save(plannedLesson);

        expect(
          () async => await useCase.execute(
            RecordLessonExecutionParams(
              plannedLessonId: 'l-div-1',
              classroomSubjectId: 'cs-outra',
              executionDate: DateTime.utc(2026, 3, 9),
              status: LessonExecutionStatus.completed,
            ),
          ),
          throwsA(isA<LessonExecutionIntegrityException>()),
        );
      },
    );
  });

  group('GetClassroomSubjectProgressUseCase Tests', () {
    test('deve classificar aulas em categorias mutuamente exclusivas e calcular indicadores determinísticos', () async {
      final useCase = GetClassroomSubjectProgressUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: testClock, // 2026-03-10
      );

      // Conteúdos:
      // c1: 2 aulas estimadas
      // c2: 1 aula estimada
      // c3: 2 aulas estimadas
      await courseContentRepo.save(
        const CourseContent(
          id: 'c1',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo 1',
          estimatedLessons: 2,
          orderIndex: 1,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'c2',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo 2',
          estimatedLessons: 1,
          orderIndex: 2,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'c3',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo 3',
          estimatedLessons: 2,
          orderIndex: 3,
        ),
      );

      // 6 aulas planejadas:
      // 1. 2026-03-02 (passado): completed com c1
      // 2. 2026-03-03 (passado): completed com c1 (c1 atinge 2 aulas -> concluído!)
      // 3. 2026-03-04 (passado): notHeld (motivo: schoolEvent)
      // 4. 2026-03-05 (passado): sem registro (pendingPast)
      // 5. 2026-03-10 (hoje): sem registro (pendingToday)
      // 6. 2026-03-17 (futuro): sem registro (future)
      final l1 = PlannedLesson(
        id: 'l-p1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 1,
      );
      final l2 = PlannedLesson(
        id: 'l-p2',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 3),
        orderInDay: 1,
      );
      final l3 = PlannedLesson(
        id: 'l-p3',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 4),
        orderInDay: 1,
      );
      final l4 = PlannedLesson(
        id: 'l-p4',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 5),
        orderInDay: 1,
      );
      final l5 = PlannedLesson(
        id: 'l-p5',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 10),
        orderInDay: 1,
      );
      final l6 = PlannedLesson(
        id: 'l-p6',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 17),
        orderInDay: 1,
      );

      await plannedLessonRepo.saveAll([l1, l2, l3, l4, l5, l6]);

      // Apontamentos fáticos para l1, l2, l3:
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'r1',
          plannedLessonId: 'l-p1',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 2),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['c1'],
          recordedAt: DateTime.utc(2026, 3, 2, 10, 0),
        ),
      );

      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'r2',
          plannedLessonId: 'l-p2',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 3),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['c1'],
          recordedAt: DateTime.utc(2026, 3, 3, 10, 0),
          needsFollowUp: true,
          followUpNotes: 'Revisar exercícios da página 45.',
        ),
      );

      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'r3',
          plannedLessonId: 'l-p3',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 4),
          status: LessonExecutionStatus.notHeld,
          cancellationReason: LessonCancellationReason.schoolEvent,
          cancellationDetails: 'Conselho de Classe',
          recordedAt: DateTime.utc(2026, 3, 4, 10, 0),
        ),
      );

      // Executa cálculo de progresso
      final progress = await useCase.execute(classroomSubjectId: 'cs-test');

      // 1. Universo total
      expect(progress.totalLessonsPlanned, equals(6));

      // 2. Classificação mútua e exaustiva
      expect(progress.completedLessonsCount, equals(2));
      expect(progress.partiallyCompletedLessonsCount, equals(0));
      expect(progress.notHeldLessonsCount, equals(1));
      expect(progress.pendingPastLessonsCount, equals(1)); // l4
      expect(progress.pendingTodayLessonsCount, equals(1)); // l5
      expect(progress.futureLessonsCount, equals(1)); // l6

      // Invariante de soma: soma das 6 categorias deve ser exatamente 6!
      final sum =
          progress.completedLessonsCount +
          progress.partiallyCompletedLessonsCount +
          progress.notHeldLessonsCount +
          progress.pendingPastLessonsCount +
          progress.pendingTodayLessonsCount +
          progress.futureLessonsCount;
      expect(sum, equals(progress.totalLessonsPlanned));

      // 3. Totais agregados
      expect(
        progress.totalLessonsRecorded,
        equals(3),
      ); // 2 completed + 1 notHeld
      expect(progress.totalLessonsEffective, equals(2)); // 2 completed
      expect(
        progress.totalLessonsPending,
        equals(3),
      ); // 1 past + 1 today + 1 future

      // 4. Taxas com numerador e denominador documentados
      expect(progress.effectiveCompletionRate, closeTo(2 / 6, 0.0001));
      expect(progress.strictCompletionRate, closeTo(2 / 6, 0.0001));
      expect(progress.recordingRate, closeTo(3 / 6, 0.0001)); // 50%
      expect(
        progress.cancellationRate,
        closeTo(1 / 3, 0.0001),
      ); // 1 notHeld de 3 registradas

      // 5. Progresso de conteúdos
      expect(progress.totalContentsPlannedCount, equals(3));
      expect(
        progress.completedContentsCount,
        equals(1),
      ); // c1 foi ministrado 2 vezes de 2 estimadas!
      expect(progress.inProgressContentsCount, equals(0));
      expect(progress.notStartedContentsCount, equals(2)); // c2 e c3
      expect(progress.contentCompletionRate, closeTo(1 / 3, 0.0001));
      expect(progress.distinctContentsTaughtIds, equals(['c1']));

      // 6. Continuidade pedagógica
      expect(progress.pendingFollowUpsCount, equals(1));
      expect(progress.followUpRecords.first.plannedLessonId, equals('l-p2'));
    });

    test(
      'deve retornar taxas zeradas sem divisão por zero para turma sem aulas',
      () async {
        final useCase = GetClassroomSubjectProgressUseCase(
          plannedLessonRepository: plannedLessonRepo,
          lessonExecutionRepository: lessonExecutionRepo,
          courseContentRepository: courseContentRepo,
          clock: testClock,
        );

        final progress = await useCase.execute(classroomSubjectId: 'cs-vazia');

        expect(progress.totalLessonsPlanned, equals(0));
        expect(progress.effectiveCompletionRate, equals(0.0));
        expect(progress.strictCompletionRate, equals(0.0));
        expect(progress.recordingRate, equals(0.0));
        expect(progress.cancellationRate, equals(0.0));
        expect(progress.contentCompletionRate, equals(0.0));
      },
    );

    test('deve distinguir conclusão efetiva de abordagem parcial de conteúdos (regra conservadora)', () async {
      final useCase = GetClassroomSubjectProgressUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: testClock,
      );

      // c-single: estimatedLessons = 1 (será testado com aula parcial)
      // c-done1: estimatedLessons = 1 (será testado com aula completed)
      // c-two-mix: estimatedLessons = 2 (será testado com 1 parcial + 1 completed)
      // c-two-done: estimatedLessons = 2 (será testado com 2 completed)
      // c-not-held: estimatedLessons = 1 (será associado a aula notHeld)
      // c-untouched: estimatedLessons = 1 (sem nenhuma aula)
      await courseContentRepo.save(
        const CourseContent(
          id: 'c-single',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo Parcial Único',
          estimatedLessons: 1,
          orderIndex: 1,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'c-done1',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo Concluído 1',
          estimatedLessons: 1,
          orderIndex: 2,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'c-two-mix',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo Misto 2 Aulas',
          estimatedLessons: 2,
          orderIndex: 3,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'c-two-done',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo Concluído 2 Aulas',
          estimatedLessons: 2,
          orderIndex: 4,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'c-not-held',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo Aula Cancelada',
          estimatedLessons: 1,
          orderIndex: 5,
        ),
      );
      await courseContentRepo.save(
        const CourseContent(
          id: 'c-untouched',
          classroomSubjectId: 'cs-test',
          title: 'Conteúdo Intocado',
          estimatedLessons: 1,
          orderIndex: 6,
        ),
      );

      final l1 = PlannedLesson(
        id: 'lp-1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 1,
      );
      final l2 = PlannedLesson(
        id: 'lp-2',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 3),
        orderInDay: 1,
      );
      final l3 = PlannedLesson(
        id: 'lp-3',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 4),
        orderInDay: 1,
      );
      final l4 = PlannedLesson(
        id: 'lp-4',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 5),
        orderInDay: 1,
      );
      final l5 = PlannedLesson(
        id: 'lp-5',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 6),
        orderInDay: 1,
      );
      final l6 = PlannedLesson(
        id: 'lp-6',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 7),
        orderInDay: 1,
      );
      final l7 = PlannedLesson(
        id: 'lp-7',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 8),
        orderInDay: 1,
        contentIds: const ['c-not-held'],
      );

      await plannedLessonRepo.saveAll([l1, l2, l3, l4, l5, l6, l7]);

      // 1. Aula partiallyCompleted ministrando 'c-single' (estimatedLessons = 1)
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-1',
          plannedLessonId: 'lp-1',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 2),
          status: LessonExecutionStatus.partiallyCompleted,
          actualContentIds: ['c-single'],
          recordedAt: DateTime.utc(2026, 3, 2, 10, 0),
        ),
      );

      // 2. Aula completed ministrando 'c-done1' (estimatedLessons = 1)
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-2',
          plannedLessonId: 'lp-2',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 3),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['c-done1'],
          recordedAt: DateTime.utc(2026, 3, 3, 10, 0),
        ),
      );

      // 3. Duas aulas para 'c-two-mix' (estimatedLessons = 2): 1 partiallyCompleted + 1 completed
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-3',
          plannedLessonId: 'lp-3',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 4),
          status: LessonExecutionStatus.partiallyCompleted,
          actualContentIds: ['c-two-mix'],
          recordedAt: DateTime.utc(2026, 3, 4, 10, 0),
        ),
      );
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-4',
          plannedLessonId: 'lp-4',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 5),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['c-two-mix'],
          recordedAt: DateTime.utc(2026, 3, 5, 10, 0),
        ),
      );

      // 4. Duas aulas para 'c-two-done' (estimatedLessons = 2): 2 completed
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-5',
          plannedLessonId: 'lp-5',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 6),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['c-two-done'],
          recordedAt: DateTime.utc(2026, 3, 6, 10, 0),
        ),
      );
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-6',
          plannedLessonId: 'lp-6',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 7),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['c-two-done'],
          recordedAt: DateTime.utc(2026, 3, 7, 10, 0),
        ),
      );

      // 5. Aula notHeld (sem conteúdos ministrados, conforme validação de domínio)
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-7',
          plannedLessonId: 'lp-7',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 8),
          status: LessonExecutionStatus.notHeld,
          actualContentIds: const [],
          cancellationReason: LessonCancellationReason.teacherAbsence,
          recordedAt: DateTime.utc(2026, 3, 8, 10, 0),
        ),
      );

      final progress = await useCase.execute(classroomSubjectId: 'cs-test');

      expect(progress.totalContentsPlannedCount, equals(6));

      // Concluídos (completedContentsCount):
      // 'c-done1' (1/1 completed) e 'c-two-done' (2/2 completed) = 2
      // 'c-single' (0/1 completed, 1 partial) -> NÃO CONCLUÍDO!
      // 'c-two-mix' (1/2 completed, 1 partial) -> NÃO CONCLUÍDO!
      expect(progress.completedContentsCount, equals(2));

      // Em andamento (inProgressContentsCount):
      // 'c-single' e 'c-two-mix' = 2
      expect(progress.inProgressContentsCount, equals(2));

      // Não iniciados (notStartedContentsCount):
      // 'c-not-held' (aula cancelada não conta) e 'c-untouched' = 2
      expect(progress.notStartedContentsCount, equals(2));

      // Invariante de integridade
      expect(
        progress.completedContentsCount +
            progress.inProgressContentsCount +
            progress.notStartedContentsCount,
        equals(progress.totalContentsPlannedCount),
      );

      // Conteúdos efetivamente abordados (parciais ou completos)
      expect(
        progress.distinctContentsTaughtIds,
        containsAll(['c-single', 'c-done1', 'c-two-mix', 'c-two-done']),
      );
      expect(progress.distinctContentsTaughtIds, isNot(contains('c-not-held')));
      expect(
        progress.distinctContentsTaughtIds,
        isNot(contains('c-untouched')),
      );
    });

    test('conteúdo com estimatedLessons = 1 abordado somente em aula partiallyCompleted não é concluído e permanece em andamento', () async {
      final useCase = GetClassroomSubjectProgressUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: testClock,
      );

      await courseContentRepo.save(
        const CourseContent(
          id: 'c-partial-only',
          classroomSubjectId: 'cs-iso-1',
          title: 'Conteúdo Parcial',
          estimatedLessons: 1,
          orderIndex: 1,
        ),
      );

      final lesson = PlannedLesson(
        id: 'lp-iso-1',
        classroomSubjectId: 'cs-iso-1',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 1,
      );
      await plannedLessonRepo.save(lesson);

      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-1',
          plannedLessonId: 'lp-iso-1',
          classroomSubjectId: 'cs-iso-1',
          executionDate: DateTime.utc(2026, 3, 2),
          status: LessonExecutionStatus.partiallyCompleted,
          actualContentIds: const ['c-partial-only'],
          recordedAt: DateTime.utc(2026, 3, 2, 10, 0),
        ),
      );

      final progress = await useCase.execute(classroomSubjectId: 'cs-iso-1');

      expect(progress.totalContentsPlannedCount, equals(1));
      expect(progress.completedContentsCount, equals(0));
      expect(progress.inProgressContentsCount, equals(1));
      expect(progress.notStartedContentsCount, equals(0));
      expect(progress.distinctContentsTaughtIds, equals(['c-partial-only']));
    });

    test('conteúdo abordado em aula completed atingindo a carga estimada é considerado concluído', () async {
      final useCase = GetClassroomSubjectProgressUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: testClock,
      );

      await courseContentRepo.save(
        const CourseContent(
          id: 'c-completed-single',
          classroomSubjectId: 'cs-iso-2',
          title: 'Conteúdo Completo',
          estimatedLessons: 1,
          orderIndex: 1,
        ),
      );

      final lesson = PlannedLesson(
        id: 'lp-iso-2',
        classroomSubjectId: 'cs-iso-2',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 1,
      );
      await plannedLessonRepo.save(lesson);

      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-2',
          plannedLessonId: 'lp-iso-2',
          classroomSubjectId: 'cs-iso-2',
          executionDate: DateTime.utc(2026, 3, 2),
          status: LessonExecutionStatus.completed,
          actualContentIds: const ['c-completed-single'],
          recordedAt: DateTime.utc(2026, 3, 2, 10, 0),
        ),
      );

      final progress = await useCase.execute(classroomSubjectId: 'cs-iso-2');

      expect(progress.totalContentsPlannedCount, equals(1));
      expect(progress.completedContentsCount, equals(1));
      expect(progress.inProgressContentsCount, equals(0));
      expect(progress.notStartedContentsCount, equals(0));
      expect(
        progress.distinctContentsTaughtIds,
        equals(['c-completed-single']),
      );
    });

    test('conteúdo abordado em aula parcial e posteriormente em aula completa conclui apenas ao atingir a carga estimada por aulas completas', () async {
      final useCase = GetClassroomSubjectProgressUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: testClock,
      );

      // Exige 2 aulas estimadas
      await courseContentRepo.save(
        const CourseContent(
          id: 'c-partial-then-complete',
          classroomSubjectId: 'cs-iso-3',
          title: 'Conteúdo Misto',
          estimatedLessons: 2,
          orderIndex: 1,
        ),
      );

      final l1 = PlannedLesson(
        id: 'lp-iso-3a',
        classroomSubjectId: 'cs-iso-3',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 1,
      );
      final l2 = PlannedLesson(
        id: 'lp-iso-3b',
        classroomSubjectId: 'cs-iso-3',
        date: DateTime.utc(2026, 3, 3),
        orderInDay: 1,
      );
      final l3 = PlannedLesson(
        id: 'lp-iso-3c',
        classroomSubjectId: 'cs-iso-3',
        date: DateTime.utc(2026, 3, 4),
        orderInDay: 1,
      );
      await plannedLessonRepo.saveAll([l1, l2, l3]);

      // 1ª aula: partiallyCompleted -> ainda inProgress
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-3a',
          plannedLessonId: 'lp-iso-3a',
          classroomSubjectId: 'cs-iso-3',
          executionDate: DateTime.utc(2026, 3, 2),
          status: LessonExecutionStatus.partiallyCompleted,
          actualContentIds: const ['c-partial-then-complete'],
          recordedAt: DateTime.utc(2026, 3, 2, 10, 0),
        ),
      );

      var p = await useCase.execute(classroomSubjectId: 'cs-iso-3');
      expect(p.completedContentsCount, equals(0));
      expect(p.inProgressContentsCount, equals(1));

      // 2ª aula: completed (1ª aula completa de 2 necessárias) -> ainda inProgress!
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-3b',
          plannedLessonId: 'lp-iso-3b',
          classroomSubjectId: 'cs-iso-3',
          executionDate: DateTime.utc(2026, 3, 3),
          status: LessonExecutionStatus.completed,
          actualContentIds: const ['c-partial-then-complete'],
          recordedAt: DateTime.utc(2026, 3, 3, 10, 0),
        ),
      );

      p = await useCase.execute(classroomSubjectId: 'cs-iso-3');
      expect(p.completedContentsCount, equals(0));
      expect(p.inProgressContentsCount, equals(1));

      // 3ª aula: completed (2ª aula completa de 2 necessárias) -> agora sim concluído!
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-3c',
          plannedLessonId: 'lp-iso-3c',
          classroomSubjectId: 'cs-iso-3',
          executionDate: DateTime.utc(2026, 3, 4),
          status: LessonExecutionStatus.completed,
          actualContentIds: const ['c-partial-then-complete'],
          recordedAt: DateTime.utc(2026, 3, 4, 10, 0),
        ),
      );

      p = await useCase.execute(classroomSubjectId: 'cs-iso-3');
      expect(p.completedContentsCount, equals(1));
      expect(p.inProgressContentsCount, equals(0));
      expect(p.notStartedContentsCount, equals(0));
    });

    test('conteúdo que exige múltiplas aulas completas conclui somente ao atingir a carga estimada', () async {
      final useCase = GetClassroomSubjectProgressUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: testClock,
      );

      await courseContentRepo.save(
        const CourseContent(
          id: 'c-multi-complete',
          classroomSubjectId: 'cs-iso-4',
          title: 'Conteúdo Múltiplo',
          estimatedLessons: 3,
          orderIndex: 1,
        ),
      );

      final l1 = PlannedLesson(
        id: 'lp-iso-4a',
        classroomSubjectId: 'cs-iso-4',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 1,
      );
      final l2 = PlannedLesson(
        id: 'lp-iso-4b',
        classroomSubjectId: 'cs-iso-4',
        date: DateTime.utc(2026, 3, 3),
        orderInDay: 1,
      );
      final l3 = PlannedLesson(
        id: 'lp-iso-4c',
        classroomSubjectId: 'cs-iso-4',
        date: DateTime.utc(2026, 3, 4),
        orderInDay: 1,
      );
      await plannedLessonRepo.saveAll([l1, l2, l3]);

      // Aula 1 completed: 1/3 -> inProgress
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-4a',
          plannedLessonId: 'lp-iso-4a',
          classroomSubjectId: 'cs-iso-4',
          executionDate: DateTime.utc(2026, 3, 2),
          status: LessonExecutionStatus.completed,
          actualContentIds: const ['c-multi-complete'],
          recordedAt: DateTime.utc(2026, 3, 2, 10, 0),
        ),
      );
      var p = await useCase.execute(classroomSubjectId: 'cs-iso-4');
      expect(p.completedContentsCount, equals(0));
      expect(p.inProgressContentsCount, equals(1));

      // Aula 2 completed: 2/3 -> inProgress
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-4b',
          plannedLessonId: 'lp-iso-4b',
          classroomSubjectId: 'cs-iso-4',
          executionDate: DateTime.utc(2026, 3, 3),
          status: LessonExecutionStatus.completed,
          actualContentIds: const ['c-multi-complete'],
          recordedAt: DateTime.utc(2026, 3, 3, 10, 0),
        ),
      );
      p = await useCase.execute(classroomSubjectId: 'cs-iso-4');
      expect(p.completedContentsCount, equals(0));
      expect(p.inProgressContentsCount, equals(1));

      // Aula 3 completed: 3/3 -> concluído!
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-4c',
          plannedLessonId: 'lp-iso-4c',
          classroomSubjectId: 'cs-iso-4',
          executionDate: DateTime.utc(2026, 3, 4),
          status: LessonExecutionStatus.completed,
          actualContentIds: const ['c-multi-complete'],
          recordedAt: DateTime.utc(2026, 3, 4, 10, 0),
        ),
      );
      p = await useCase.execute(classroomSubjectId: 'cs-iso-4');
      expect(p.completedContentsCount, equals(1));
      expect(p.inProgressContentsCount, equals(0));
      expect(p.notStartedContentsCount, equals(0));
    });

    test('aula notHeld não incrementa a carga ministrada nem marca conteúdo como abordado', () async {
      final useCase = GetClassroomSubjectProgressUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: testClock,
      );

      await courseContentRepo.save(
        const CourseContent(
          id: 'c-cancelled-content',
          classroomSubjectId: 'cs-iso-5',
          title: 'Conteúdo Aula Cancelada',
          estimatedLessons: 1,
          orderIndex: 1,
        ),
      );

      final lesson = PlannedLesson(
        id: 'lp-iso-5',
        classroomSubjectId: 'cs-iso-5',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 1,
        contentIds: const ['c-cancelled-content'],
      );
      await plannedLessonRepo.save(lesson);

      // Aula cancelada por motivo de força maior
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-iso-5',
          plannedLessonId: 'lp-iso-5',
          classroomSubjectId: 'cs-iso-5',
          executionDate: DateTime.utc(2026, 3, 2),
          status: LessonExecutionStatus.notHeld,
          actualContentIds: const [],
          cancellationReason: LessonCancellationReason.infrastructureIssue,
          recordedAt: DateTime.utc(2026, 3, 2, 10, 0),
        ),
      );

      final progress = await useCase.execute(classroomSubjectId: 'cs-iso-5');

      expect(progress.completedContentsCount, equals(0));
      expect(progress.inProgressContentsCount, equals(0));
      expect(progress.notStartedContentsCount, equals(1));
      expect(progress.distinctContentsTaughtIds, isEmpty);
    });

    test('conteúdo não abordado permanece notStarted', () async {
      final useCase = GetClassroomSubjectProgressUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        courseContentRepository: courseContentRepo,
        clock: testClock,
      );

      await courseContentRepo.save(
        const CourseContent(
          id: 'c-never-touched',
          classroomSubjectId: 'cs-iso-6',
          title: 'Conteúdo Não Abordado',
          estimatedLessons: 2,
          orderIndex: 1,
        ),
      );

      final progress = await useCase.execute(classroomSubjectId: 'cs-iso-6');

      expect(progress.totalContentsPlannedCount, equals(1));
      expect(progress.completedContentsCount, equals(0));
      expect(progress.inProgressContentsCount, equals(0));
      expect(progress.notStartedContentsCount, equals(1));
      expect(progress.distinctContentsTaughtIds, isEmpty);
    });
  });

  group('GetPendingLessonsUseCase Tests', () {
    test('deve retornar apenas aulas sem registro, categorizando em atrasadas, de hoje e futuras com ordenação', () async {
      final useCase = GetPendingLessonsUseCase(
        plannedLessonRepository: plannedLessonRepo,
        lessonExecutionRepository: lessonExecutionRepo,
        clock: testClock, // 2026-03-10
      );

      // Aulas:
      // l-old1: 2026-03-02 ordem 2 (atrasada)
      // l-old2: 2026-03-02 ordem 1 (atrasada)
      // l-recorded: 2026-03-05 (com registro -> NÃO DEVE APARECER)
      // l-today: 2026-03-10 ordem 1 (de hoje)
      // l-fut2: 2026-03-18 ordem 1 (futura)
      // l-fut1: 2026-03-15 ordem 1 (futura)
      final lOld1 = PlannedLesson(
        id: 'l-old1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 2,
      );
      final lOld2 = PlannedLesson(
        id: 'l-old2',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 2),
        orderInDay: 1,
      );
      final lRecorded = PlannedLesson(
        id: 'l-recorded',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 5),
        orderInDay: 1,
      );
      final lToday = PlannedLesson(
        id: 'l-today',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 10),
        orderInDay: 1,
      );
      final lFut2 = PlannedLesson(
        id: 'l-fut2',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 18),
        orderInDay: 1,
      );
      final lFut1 = PlannedLesson(
        id: 'l-fut1',
        classroomSubjectId: 'cs-test',
        date: DateTime.utc(2026, 3, 15),
        orderInDay: 1,
      );

      await plannedLessonRepo.saveAll([
        lOld1,
        lOld2,
        lRecorded,
        lToday,
        lFut2,
        lFut1,
      ]);

      // Grava registro fático para lRecorded
      await lessonExecutionRepo.save(
        LessonExecutionRecord(
          id: 'rec-done',
          plannedLessonId: 'l-recorded',
          classroomSubjectId: 'cs-test',
          executionDate: DateTime.utc(2026, 3, 5),
          status: LessonExecutionStatus.completed,
          recordedAt: DateTime.utc(2026, 3, 5, 10, 0),
        ),
      );

      final summary = await useCase.execute(classroomSubjectId: 'cs-test');

      // Total pendente: 5 (6 planejadas - 1 registrada)
      expect(summary.totalPendingCount, equals(5));
      expect(summary.hasOverdueLessons, isTrue);

      // Atrasadas: lOld2 primeiro (ordem 1), depois lOld1 (ordem 2)
      expect(summary.overdueLessons.length, equals(2));
      expect(summary.overdueLessons[0].id, equals('l-old2'));
      expect(summary.overdueLessons[1].id, equals('l-old1'));

      // De hoje
      expect(summary.todayLessons.length, equals(1));
      expect(summary.todayLessons.first.id, equals('l-today'));

      // Futuras: lFut1 primeiro (15/03), depois lFut2 (18/03)
      expect(summary.futureLessons.length, equals(2));
      expect(summary.futureLessons[0].id, equals('l-fut1'));
      expect(summary.futureLessons[1].id, equals('l-fut2'));

      // Garante que a aula com registro NÃO apareceu em nenhuma lista
      final allReturnedIds = [
        ...summary.overdueLessons.map((l) => l.id),
        ...summary.todayLessons.map((l) => l.id),
        ...summary.futureLessons.map((l) => l.id),
      ];
      expect(allReturnedIds, isNot(contains('l-recorded')));
    });
  });
}
