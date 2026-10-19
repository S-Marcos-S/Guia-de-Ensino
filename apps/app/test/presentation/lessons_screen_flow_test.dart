import 'dart:async';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/domain/usecases/get_classroom_subject_lessons_usecase.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
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
            subjectId: 'subj-mat',
            weeklyLessons: 4,
          ),
          ClassroomSubjectConfig(
            id: 'cs-9a-cie',
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

        await tester.pumpWidget(buildTestableScreen());
        await tester.pumpAndSettle();

        // 1. Cabeçalho e seletores
        expect(find.text(AppStrings.lessonsScreenTitle), findsOneWidget);
        expect(find.text('9º Ano A'), findsWidgets);
        expect(find.text('Matemática'), findsWidgets);

        // 2. Badges de status
        expect(find.text(AppStrings.badgePastUnrecorded), findsOneWidget);
        expect(find.text(AppStrings.badgeToday), findsOneWidget);
        expect(find.text(AppStrings.statusCompleted), findsOneWidget);

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
                subjectId: 'subj-slow',
                weeklyLessons: 2,
              ),
              ClassroomSubjectConfig(
                id: 'cs-fast',
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
        await tester.pumpAndSettle();

        // Toca na opção Física Rápida no menu suspenso
        final fastMenuItem = find.text('Física Rápida').last;
        await tester.tap(fastMenuItem);
        await tester.pumpAndSettle();

        // A consulta rápida completou imediatamente e a tela exibe seus dados
        expect(find.text('Conteúdo Rápido de Física'), findsOneWidget);

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
        expect(find.text('Conteúdo Rápido de Física'), findsOneWidget);
        expect(find.text('Conteúdo Lento Obsoleto de História'), findsNothing);
      },
    );

    testWidgets(
      'deve filtrar aulas por Todas, Passadas, Hoje e Futuras ao acionar os segmentos temporais',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1000);
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

        await tester.pumpWidget(buildTestableScreen());
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
  });
}
