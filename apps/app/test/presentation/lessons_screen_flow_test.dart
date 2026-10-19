import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/domain/usecases/get_classroom_subject_lessons_usecase.dart';
import 'package:app/domain/usecases/record_lesson_execution_usecase.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/presentation/components/status_badge.dart';
import 'package:app/presentation/screens/lessons_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Caso de uso controlado para teste de concorrência com atraso induzido via Completer.
class ConcurrencyControlledUseCase extends GetClassroomSubjectLessonsUseCase {
  ConcurrencyControlledUseCase({
    required super.plannedLessonRepository,
    required super.lessonExecutionRepository,
    required super.courseContentRepository,
    required this.slowCompleter,
  });

  final Completer<List<ClassroomSubjectLessonItem>> slowCompleter;

  @override
  Future<List<ClassroomSubjectLessonItem>> execute({
    required String classroomSubjectId,
  }) async {
    if (classroomSubjectId == 'cs-slow') {
      return slowCompleter.future;
    }

    if (classroomSubjectId == 'cs-fast') {
      return [
        ClassroomSubjectLessonItem(
          plannedLesson: PlannedLesson(
            id: 'l-fast-1',
            classroomSubjectId: 'cs-fast',
            date: DateTime.utc(2026, 3, 10),
            orderInDay: 1,
            status: LessonExecutionStatus.completed,
          ),
          plannedContentTitles: const ['Conteúdo Rápido de Física'],
          actualContentTitles: const ['Conteúdo Rápido de Física'],
          temporalCategory: LessonTemporalCategory.today,
          executionRecord: LessonExecutionRecord(
            id: 'rec-fast-1',
            plannedLessonId: 'l-fast-1',
            classroomSubjectId: 'cs-fast',
            executionDate: DateTime.utc(2026, 3, 10),
            status: LessonExecutionStatus.completed,
            actualContentIds: const [],
            recordedAt: DateTime.utc(2026, 3, 10, 10, 0),
          ),
        ),
      ];
    }

    return super.execute(classroomSubjectId: classroomSubjectId);
  }
}

/// Caso de uso que dispara falha intencional para teste de erro e retry.
class FailingLessonsUseCase extends GetClassroomSubjectLessonsUseCase {
  FailingLessonsUseCase({
    required super.plannedLessonRepository,
    required super.lessonExecutionRepository,
    required super.courseContentRepository,
  });

  bool shouldFail = true;

  @override
  Future<List<ClassroomSubjectLessonItem>> execute({
    required String classroomSubjectId,
  }) async {
    if (shouldFail) {
      throw Exception('Falha simulada na leitura de banco de dados');
    }
    return super.execute(classroomSubjectId: classroomSubjectId);
  }
}

void main() {
  late AppDatabase db;
  late AppDependencies dependencies;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dependencies = AppDependencies(database: db);

    // Setup de ano letivo, turmas e disciplinas
    await dependencies.academicYearRepository.save(
      AcademicYear(
        id: 'ay-2026',
        year: 2026,
        title: 'Ano Letivo 2026',
        startDate: DateTime.utc(2026, 2, 2),
        endDate: DateTime.utc(2026, 12, 18),
      ),
    );

    await dependencies.subjectRepository.save(
      const Subject(id: 'subj-mat', name: 'Matemática', colorHex: '#2196F3'),
    );

    await dependencies.subjectRepository.save(
      const Subject(id: 'subj-cie', name: 'Ciências', colorHex: '#4CAF50'),
    );

    await dependencies.classroomRepository.save(
      const Classroom(
        id: 'c-9a',
        academicYearId: 'ay-2026',
        name: '9º Ano A',
        gradeLevel: '9º Ano EF',
        shift: ClassroomShift.morning,
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cs-9a-mat',
            classroomId: 'c-9a',
            subjectId: 'subj-mat',
            weeklyLessons: 4,
          ),
          ClassroomSubjectConfig(
            id: 'cs-9a-cie',
            classroomId: 'c-9a',
            subjectId: 'subj-cie',
            weeklyLessons: 3,
          ),
        ],
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableScreen({
    AppDependencies? customDeps,
    String? initialClassroomId,
    String? initialClassroomSubjectId,
  }) {
    return MaterialApp(
      home: AppDependencyScope(
        dependencies: customDeps ?? dependencies,
        child: LessonsScreen(
          initialClassroomId: initialClassroomId,
          initialClassroomSubjectId: initialClassroomSubjectId,
        ),
      ),
    );
  }

  group('LessonsScreen Widget & Integration Tests', () {
    testWidgets(
      'deve renderizar a tela exibindo aulas passadas, hoje e futuras com distinção de conteúdos planejados e executados',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Cadastrar conteúdos
        await dependencies.courseContentRepository.save(
          const CourseContent(
            id: 'cnt-fracoes',
            classroomSubjectId: 'cs-9a-mat',
            title: 'Frações e Números Decimais',
            orderIndex: 1,
          ),
        );
        await dependencies.courseContentRepository.save(
          const CourseContent(
            id: 'cnt-geometria',
            classroomSubjectId: 'cs-9a-mat',
            title: 'Teorema de Pitágoras',
            orderIndex: 2,
          ),
        );

        // Aula 1: Passada e sem registro fático (pendente de apontamento)
        final pastDate = DateTime.now().subtract(const Duration(days: 3));
        await dependencies.plannedLessonRepository.save(
          PlannedLesson(
            id: 'l-past-unrec',
            classroomSubjectId: 'cs-9a-mat',
            date: DateTime.utc(pastDate.year, pastDate.month, pastDate.day),
            orderInDay: 1,
            contentIds: const ['cnt-fracoes'],
          ),
        );

        // Aula 2: Aula de hoje realizada com anotações e registro fático
        final today = DateTime.now();
        await dependencies.plannedLessonRepository.save(
          PlannedLesson(
            id: 'l-today-rec',
            classroomSubjectId: 'cs-9a-mat',
            date: DateTime.utc(today.year, today.month, today.day),
            orderInDay: 2,
            contentIds: const ['cnt-geometria'],
          ),
        );
        await dependencies.lessonExecutionRepository.save(
          LessonExecutionRecord(
            id: 'rec-today-rec',
            plannedLessonId: 'l-today-rec',
            classroomSubjectId: 'cs-9a-mat',
            executionDate: DateTime.utc(today.year, today.month, today.day),
            status: LessonExecutionStatus.completed,
            actualContentIds: const ['cnt-geometria'],
            pedagogicalNotes:
                'Alunos resolveram exercícios de triângulos retângulos.',
            recordedAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          buildTestableScreen(
            initialClassroomId: 'c-9a',
            initialClassroomSubjectId: 'cs-9a-mat',
          ),
        );
        await tester.pumpAndSettle();

        // 1. Cabeçalho e seletores
        expect(find.text(AppStrings.lessonsScreenTitle), findsOneWidget);
        expect(find.text('9º Ano A'), findsWidgets);
        expect(find.text('Matemática'), findsWidgets);

        // 2. Badges de status dos cards
        expect(
          find.widgetWithText(StatusBadge, AppStrings.badgePastUnrecorded),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(StatusBadge, AppStrings.badgeToday),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(StatusBadge, AppStrings.statusCompleted),
          findsOneWidget,
        );

        // 3. Conteúdos planejados e ministrados
        expect(find.text('• Frações e Números Decimais'), findsOneWidget);
        expect(find.text('• Teorema de Pitágoras'), findsWidgets);
        expect(
          find.textContaining(
            'Alunos resolveram exercícios de triângulos retângulos.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'deve proteger estritamente contra respostas concorrentes obsoletas usando Completer (primeira consulta lenta não sobrescreve a segunda rápida)',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Configura uma turma com duas disciplinas: lenta e rápida
        await dependencies.subjectRepository.save(
          const Subject(
            id: 'subj-slow',
            name: 'História Lenta',
            colorHex: '#FF5722',
          ),
        );
        await dependencies.subjectRepository.save(
          const Subject(
            id: 'subj-fast',
            name: 'Física Rápida',
            colorHex: '#009688',
          ),
        );

        await dependencies.classroomRepository.save(
          const Classroom(
            id: 'c-concurrency',
            academicYearId: 'ay-2026',
            name: 'Turma Concorrência',
            gradeLevel: '1º EM',
            shift: ClassroomShift.morning,
            subjectConfigs: [
              ClassroomSubjectConfig(
                id: 'cs-slow',
                classroomId: 'c-concurrency',
                subjectId: 'subj-slow',
                weeklyLessons: 2,
              ),
              ClassroomSubjectConfig(
                id: 'cs-fast',
                classroomId: 'c-concurrency',
                subjectId: 'subj-fast',
                weeklyLessons: 2,
              ),
            ],
          ),
        );

        final slowCompleter = Completer<List<ClassroomSubjectLessonItem>>();
        final concurrencyUseCase = ConcurrencyControlledUseCase(
          plannedLessonRepository: dependencies.plannedLessonRepository,
          lessonExecutionRepository: dependencies.lessonExecutionRepository,
          courseContentRepository: dependencies.courseContentRepository,
          slowCompleter: slowCompleter,
        );

        final customDeps = AppDependencies(
          database: db,
          getClassroomSubjectLessonsUseCase: concurrencyUseCase,
        );

        // Inicia abrindo a disciplina LENTA
        await tester.pumpWidget(
          buildTestableScreen(
            customDeps: customDeps,
            initialClassroomId: 'c-concurrency',
            initialClassroomSubjectId: 'cs-slow',
          ),
        );

        // A consulta lenta está rodando (aguardando slowCompleter.future)
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Usuário troca de disciplina para a RÁPIDA
        final subjectDropdown = find.widgetWithText(
          DropdownButtonFormField<ClassroomSubjectConfig>,
          'História Lenta',
        );
        expect(subjectDropdown, findsOneWidget);
        await tester.tap(subjectDropdown);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Toca na opção Física Rápida no menu suspenso
        final fastMenuItem = find.text('Física Rápida').last;
        await tester.tap(fastMenuItem);
        await tester.pumpAndSettle();

        // A consulta rápida completou imediatamente e a tela exibe seus dados
        expect(find.textContaining('Conteúdo Rápido de Física'), findsWidgets);

        // Agora, com atraso, a consulta antiga LENTA finalmente termina
        slowCompleter.complete([
          ClassroomSubjectLessonItem(
            plannedLesson: PlannedLesson(
              id: 'l-slow-obsoleta',
              classroomSubjectId: 'cs-slow',
              date: DateTime.utc(2026, 3, 10),
              orderInDay: 1,
            ),
            plannedContentTitles: const ['Conteúdo Lento Obsoleto de História'],
            actualContentTitles: const [],
            temporalCategory: LessonTemporalCategory.today,
          ),
        ]);

        await tester.pumpAndSettle();

        // VALIDAÇÃO CRÍTICA: O conteúdo rápido de Física CONTINUA na tela!
        // O resultado obsoleto de História Lenta foi descartado e NÃO sobrescreveu a interface!
        expect(find.textContaining('Conteúdo Rápido de Física'), findsWidgets);
        expect(
          find.textContaining('Conteúdo Lento Obsoleto de História'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'deve filtrar aulas por Todas, Passadas, Hoje e Futuras ao acionar os segmentos temporais',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Cria conteúdos
        await dependencies.courseContentRepository.save(
          const CourseContent(
            id: 'c-past',
            classroomSubjectId: 'cs-9a-mat',
            title: 'Conteúdo Passado',
            orderIndex: 1,
          ),
        );
        await dependencies.courseContentRepository.save(
          const CourseContent(
            id: 'c-today',
            classroomSubjectId: 'cs-9a-mat',
            title: 'Conteúdo de Hoje',
            orderIndex: 2,
          ),
        );
        await dependencies.courseContentRepository.save(
          const CourseContent(
            id: 'c-future',
            classroomSubjectId: 'cs-9a-mat',
            title: 'Conteúdo Futuro',
            orderIndex: 3,
          ),
        );

        final now = DateTime.now();
        final pastDate = now.subtract(const Duration(days: 4));
        final futureDate = now.add(const Duration(days: 4));

        await dependencies.plannedLessonRepository.save(
          PlannedLesson(
            id: 'l-past-filt',
            classroomSubjectId: 'cs-9a-mat',
            date: DateTime.utc(pastDate.year, pastDate.month, pastDate.day),
            orderInDay: 1,
            contentIds: const ['c-past'],
          ),
        );

        await dependencies.plannedLessonRepository.save(
          PlannedLesson(
            id: 'l-today-filt',
            classroomSubjectId: 'cs-9a-mat',
            date: DateTime.utc(now.year, now.month, now.day),
            orderInDay: 1,
            contentIds: const ['c-today'],
          ),
        );

        await dependencies.plannedLessonRepository.save(
          PlannedLesson(
            id: 'l-future-filt',
            classroomSubjectId: 'cs-9a-mat',
            date: DateTime.utc(
              futureDate.year,
              futureDate.month,
              futureDate.day,
            ),
            orderInDay: 1,
            contentIds: const ['c-future'],
          ),
        );

        await tester.pumpWidget(
          buildTestableScreen(
            initialClassroomId: 'c-9a',
            initialClassroomSubjectId: 'cs-9a-mat',
          ),
        );
        await tester.pumpAndSettle();

        // Inicialmente no filtro Todas: todas as 3 aulas aparecem
        expect(find.text('• Conteúdo Passado'), findsOneWidget);
        expect(find.text('• Conteúdo de Hoje'), findsOneWidget);
        expect(find.text('• Conteúdo Futuro'), findsOneWidget);

        // Filtra por Passadas
        await tester.tap(find.text(AppStrings.filterPast));
        await tester.pumpAndSettle();
        expect(find.text('• Conteúdo Passado'), findsOneWidget);
        expect(find.text('• Conteúdo de Hoje'), findsNothing);
        expect(find.text('• Conteúdo Futuro'), findsNothing);

        // Filtra por Hoje
        await tester.tap(find.text(AppStrings.filterToday));
        await tester.pumpAndSettle();
        expect(find.text('• Conteúdo Passado'), findsNothing);
        expect(find.text('• Conteúdo de Hoje'), findsOneWidget);
        expect(find.text('• Conteúdo Futuro'), findsNothing);

        // Filtra por Futuras
        await tester.ensureVisible(find.text(AppStrings.filterFuture));
        await tester.tap(find.text(AppStrings.filterFuture));
        await tester.pumpAndSettle();
        expect(find.text('• Conteúdo Passado'), findsNothing);
        expect(find.text('• Conteúdo de Hoje'), findsNothing);
        expect(find.text('• Conteúdo Futuro'), findsOneWidget);

        // Retorna para Todas
        await tester.tap(find.text(AppStrings.filterAll));
        await tester.pumpAndSettle();
        expect(find.text('• Conteúdo Passado'), findsOneWidget);
        expect(find.text('• Conteúdo de Hoje'), findsOneWidget);
        expect(find.text('• Conteúdo Futuro'), findsOneWidget);
      },
    );

    testWidgets(
      'deve exibir erro e permitir tentar novamente quando a busca falhar',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final failingUseCase = FailingLessonsUseCase(
          plannedLessonRepository: dependencies.plannedLessonRepository,
          lessonExecutionRepository: dependencies.lessonExecutionRepository,
          courseContentRepository: dependencies.courseContentRepository,
        );

        final customDeps = AppDependencies(
          database: db,
          getClassroomSubjectLessonsUseCase: failingUseCase,
        );

        await tester.pumpWidget(buildTestableScreen(customDeps: customDeps));
        await tester.pumpAndSettle();

        // Mensagem de erro e botão de retry
        expect(find.text(AppStrings.loadingLessonsError), findsOneWidget);
        final retryBtn = find.text(AppStrings.retryButton);
        expect(retryBtn, findsOneWidget);

        // Desativa falha e toca em tentar novamente
        failingUseCase.shouldFail = false;
        await tester.tap(retryBtn);
        await tester.pumpAndSettle();

        // Erro desaparece
        expect(find.text(AppStrings.loadingLessonsError), findsNothing);
      },
    );

    testWidgets(
      '8 e 9. Novo apontamento e retificação com persistência Drift real e atualização do cartão',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Cria conteúdo
        const content = CourseContent(
          id: 'cnt-mat-1',
          classroomSubjectId: 'cs-9a-mat',
          title: 'Equações de 2º Grau',
          orderIndex: 1,
        );
        await dependencies.courseContentRepository.save(content);

        // Cria aula planejada sem registro
        final planned = PlannedLesson(
          id: 'l-flow-rec-1',
          classroomSubjectId: 'cs-9a-mat',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 1,
          contentIds: ['cnt-mat-1'],
          status: LessonExecutionStatus.planned,
        );
        await dependencies.plannedLessonRepository.save(planned);

        await tester.pumpWidget(
          buildTestableScreen(
            initialClassroomId: 'c-9a',
            initialClassroomSubjectId: 'cs-9a-mat',
          ),
        );
        await tester.pumpAndSettle();

        // Verifica presença do botão "Apontar Aula"
        final recordBtn = find.text(AppStrings.recordLessonAction);
        expect(recordBtn, findsOneWidget);

        // 1. Abre o diálogo de apontamento
        await tester.tap(recordBtn);
        await tester.pumpAndSettle();

        // Diálogo aberto: clica em "Salvar Apontamento" (conteúdo sugerido já marcado)
        await tester.tap(find.text(AppStrings.saveRecordButton));
        await tester.pumpAndSettle();

        // Diálogo fechou, SnackBar exibido e botão mudou para "Retificar Apontamento"
        expect(find.text(AppStrings.lessonRecordedSuccess), findsOneWidget);
        expect(find.text(AppStrings.rectifyLessonAction), findsOneWidget);
        expect(find.text(AppStrings.statusCompleted), findsOneWidget);

        // Comprova persistência real no Drift
        final savedRecord = await dependencies.lessonExecutionRepository
            .findByPlannedLessonId('l-flow-rec-1');
        expect(savedRecord, isNotNull);
        expect(savedRecord!.status, equals(LessonExecutionStatus.completed));
        expect(savedRecord.actualContentIds, equals(['cnt-mat-1']));
        expect(savedRecord.updatedAt, isNull);

        // 2. Retificação pedagógica: abre o diálogo novamente
        await tester.tap(find.text(AppStrings.rectifyLessonAction));
        await tester.pumpAndSettle();

        // Altera para "Não Realizada", seleciona motivo e salva
        await tester.tap(find.text(AppStrings.statusNotHeldOption));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byType(DropdownButtonFormField<LessonCancellationReason>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Falta / Licença do Professor').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.saveRecordButton));
        await tester.pumpAndSettle();

        // Diálogo fechou, SnackBar de retificação exibido e status mudou para "Não Realizada"
        expect(find.text(AppStrings.lessonRectifiedSuccess), findsOneWidget);
        expect(find.text(AppStrings.statusNotHeld), findsOneWidget);

        // Comprova retificação real no Drift
        final rectifiedRecord = await dependencies.lessonExecutionRepository
            .findByPlannedLessonId('l-flow-rec-1');
        expect(rectifiedRecord, isNotNull);
        expect(rectifiedRecord!.id, equals(savedRecord.id));
        expect(rectifiedRecord.recordedAt, equals(savedRecord.recordedAt));
        expect(rectifiedRecord.updatedAt, isNotNull);
        expect(rectifiedRecord.status, equals(LessonExecutionStatus.notHeld));
        expect(
          rectifiedRecord.cancellationReason,
          equals(LessonCancellationReason.teacherAbsence),
        );
        expect(rectifiedRecord.actualContentIds, isEmpty);
      },
    );

    testWidgets(
      '10. Preservação do filtro temporal ativo após gravação e recarga',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Cria aula de hoje
        final todayLesson = PlannedLesson(
          id: 'l-filter-test-1',
          classroomSubjectId: 'cs-9a-mat',
          date: DateTime.now().toUtc(),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        );
        await dependencies.plannedLessonRepository.save(todayLesson);

        await tester.pumpWidget(
          buildTestableScreen(
            initialClassroomId: 'c-9a',
            initialClassroomSubjectId: 'cs-9a-mat',
          ),
        );
        await tester.pumpAndSettle();

        // Seleciona o filtro "Hoje"
        await tester.tap(find.text(AppStrings.filterToday));
        await tester.pumpAndSettle();

        // Aponta a aula
        await tester.tap(find.text(AppStrings.recordLessonAction));
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.saveRecordButton));
        await tester.pumpAndSettle();

        // O filtro "Hoje" deve permanecer ativo e o cartão continua visível
        final segmentedButton = tester.widget<SegmentedButton<LessonFilter>>(
          find.byType(SegmentedButton<LessonFilter>),
        );
        expect(segmentedButton.selected, equals({LessonFilter.today}));
        expect(find.text(AppStrings.statusCompleted), findsOneWidget);
      },
    );

    testWidgets(
      '12. Atualização dos indicadores de progresso após novo apontamento e retificação',
      (tester) async {
        // Conteúdo com 2 aulas estimadas
        const content = CourseContent(
          id: 'cnt-prog-1',
          classroomSubjectId: 'cs-9a-mat',
          title: 'Geometria Espacial',
          estimatedLessons: 2,
          orderIndex: 1,
        );
        await dependencies.courseContentRepository.save(content);

        final lesson = PlannedLesson(
          id: 'l-prog-test-1',
          classroomSubjectId: 'cs-9a-mat',
          date: DateTime.utc(2026, 3, 9),
          orderInDay: 1,
          contentIds: ['cnt-prog-1'],
          status: LessonExecutionStatus.planned,
        );
        await dependencies.plannedLessonRepository.save(lesson);

        // Progresso inicial: 0 aulas executadas
        var progress = await dependencies.getClassroomSubjectProgressUseCase
            .execute(classroomSubjectId: 'cs-9a-mat');
        expect(progress.totalLessonsRecorded, equals(0));
        expect(progress.completedLessonsCount, equals(0));

        // Grava apontamento como realizada
        await dependencies.recordLessonExecutionUseCase.execute(
          RecordLessonExecutionParams(
            plannedLessonId: 'l-prog-test-1',
            classroomSubjectId: 'cs-9a-mat',
            executionDate: DateTime.utc(2026, 3, 9),
            status: LessonExecutionStatus.completed,
            actualContentIds: ['cnt-prog-1'],
          ),
        );

        // Progresso pós-gravação: 1 executada e 1 completada
        progress = await dependencies.getClassroomSubjectProgressUseCase
            .execute(classroomSubjectId: 'cs-9a-mat');
        expect(progress.totalLessonsRecorded, equals(1));
        expect(progress.completedLessonsCount, equals(1));
        expect(progress.notHeldLessonsCount, equals(0));

        // Retifica para não realizada
        await dependencies.recordLessonExecutionUseCase.execute(
          RecordLessonExecutionParams(
            plannedLessonId: 'l-prog-test-1',
            classroomSubjectId: 'cs-9a-mat',
            executionDate: DateTime.utc(2026, 3, 9),
            status: LessonExecutionStatus.notHeld,
            cancellationReason: LessonCancellationReason.schoolEvent,
          ),
        );

        // Progresso pós-retificação: 1 executada, 0 completadas, 1 notHeld
        progress = await dependencies.getClassroomSubjectProgressUseCase
            .execute(classroomSubjectId: 'cs-9a-mat');
        expect(progress.totalLessonsRecorded, equals(1));
        expect(progress.completedLessonsCount, equals(0));
        expect(progress.notHeldLessonsCount, equals(1));
      },
    );
  });
}
