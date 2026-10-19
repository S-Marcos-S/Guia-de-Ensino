import 'package:app/core/di/app_dependencies.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
import 'package:app/domain/models/replanning_models.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/presentation/components/replanning_preview_dialog.dart';
import 'package:app/presentation/screens/replanning_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AppDependencies dependencies;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dependencies = AppDependencies(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget({required Widget child, TextScaler? textScaler}) {
    return MaterialApp(
      home: AppDependencyScope(
        dependencies: dependencies,
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(800, 800),
            textScaler: textScaler ?? TextScaler.noScaling,
          ),
          child: child,
        ),
      ),
    );
  }

  group('ReplanningPreviewDialog Flow Tests', () {
    testWidgets('exibe métricas de aulas preservadas, reprogramadas e comparativo antes vs depois', (
      tester,
    ) async {
      final shift1 = LessonReplanningShift(
        plannedLessonId: 'l1',
        originalDate: DateTime(2026, 2, 2),
        originalOrderInDay: 1,
        originalContentIds: const ['c1'],
        originalContentTitles: const ['Frações Básicas'],
        proposedDate: DateTime(2026, 2, 2),
        proposedOrderInDay: 1,
        proposedContentIds: const ['c1'],
        proposedContentTitles: const ['Frações Básicas'],
        shiftType: LessonReplanningShiftType.unchanged,
        reason: 'Preservada: registro histórico factual (completed).',
        isPreservedHistoric: true,
      );

      final shift2 = LessonReplanningShift(
        plannedLessonId: 'l2',
        originalDate: DateTime(2026, 2, 9),
        originalOrderInDay: 1,
        originalContentIds: const ['c2'],
        originalContentTitles: const ['Geometria'],
        proposedDate: DateTime(2026, 2, 16),
        proposedOrderInDay: 1,
        proposedContentIds: const ['c2'],
        proposedContentTitles: const ['Geometria'],
        shiftType: LessonReplanningShiftType.rescheduledDate,
        reason: 'Data reprogramada de 09/02 para 16/02 devido a reposição.',
      );

      final l1 = PlannedLesson(
        id: 'l1',
        classroomSubjectId: 'cs1',
        date: DateTime(2026, 2, 2),
        orderInDay: 1,
        contentIds: const ['c1'],
        status: LessonExecutionStatus.completed,
      );
      final l2 = PlannedLesson(
        id: 'l2',
        classroomSubjectId: 'cs1',
        date: DateTime(2026, 2, 16),
        orderInDay: 1,
        contentIds: const ['c2'],
      );

      final planningResult = PlanningEngineResult(
        classroomSubjectId: 'cs1',
        isSuccessful: true,
        plannedLessons: [
          PlannedLessonAllocation(
            lesson: l1,
            contentIds: const ['c1'],
            isPreservedFromHistory: true,
          ),
          PlannedLessonAllocation(
            lesson: l2,
            contentIds: const ['c2'],
            isPreservedFromHistory: false,
          ),
        ],
        preservedLessons: [l1],
        contentAllocations: const [],
        availableLessonOccurrences: 2,
        usedLessonOccurrences: 2,
        conflicts: const [],
        warnings: const [],
      );

      final proposal = ReplanningProposal(
        classroomSubjectId: 'cs1',
        generatedAt: DateTime.utc(2026, 2, 10),
        referenceDate: DateTime.utc(2026, 2, 10),
        sourcePlannedLessonIds: {'l1', 'l2'},
        sourceExecutionRecordIds: {'r1'},
        planningResult: planningResult,
        shifts: [shift1, shift2],
        preservedHistoricLessonsCount: 1,
        preservedLockedLessonsCount: 0,
        affectedFutureLessonsCount: 1,
        unaffectedFutureLessonsCount: 0,
        isIdenticalToCurrentPlan: false,
        explanations: ['Foram reprogramadas 1 aula(s) futuras para absorver o atraso.'],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: ReplanningPreviewDialog(
            classroomName: '6º Ano A',
            subjectName: 'Matemática',
            proposal: proposal,
            onPlanApplied: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Proposta de Replanejamento'), findsOneWidget);
      expect(find.text('Histórico Intacto'), findsOneWidget);
      expect(find.text('Reprogramadas'), findsOneWidget);
      expect(find.text('Frações Básicas'), findsOneWidget);
      expect(find.text('Geometria'), findsWidgets);
      expect(find.text('Rejeitar e Descartar'), findsOneWidget);
      expect(find.text('Homologar e Aplicar'), findsOneWidget);
    });

    testWidgets('Salvaguarda 7 - Rejeitar e Descartar fecha o modal sem disparar onPlanApplied', (
      tester,
    ) async {
      var planAppliedCalled = false;

      final proposal = ReplanningProposal(
        classroomSubjectId: 'cs1',
        generatedAt: DateTime.utc(2026, 2, 10),
        referenceDate: DateTime.utc(2026, 2, 10),
        sourcePlannedLessonIds: const {},
        sourceExecutionRecordIds: const {},
        planningResult: const PlanningEngineResult(
          classroomSubjectId: 'cs1',
          isSuccessful: true,
          plannedLessons: [],
          preservedLessons: [],
          contentAllocations: [],
          availableLessonOccurrences: 0,
          usedLessonOccurrences: 0,
          conflicts: [],
          warnings: [],
        ),
        shifts: const [],
        preservedHistoricLessonsCount: 0,
        preservedLockedLessonsCount: 0,
        affectedFutureLessonsCount: 0,
        unaffectedFutureLessonsCount: 0,
        isIdenticalToCurrentPlan: true,
        explanations: const [],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: ctx,
                  builder: (_) => ReplanningPreviewDialog(
                    classroomName: '6º Ano A',
                    subjectName: 'Matemática',
                    proposal: proposal,
                    onPlanApplied: () {
                      planAppliedCalled = true;
                    },
                  ),
                );
              },
              child: const Text('Abrir Diálogo'),
            ),
          ),
        ),
      );

      // Abre o diálogo
      await tester.tap(find.text('Abrir Diálogo'));
      await tester.pumpAndSettle();

      expect(find.text('Proposta de Replanejamento'), findsOneWidget);

      // Clica em Rejeitar e Descartar
      await tester.tap(find.text('Rejeitar e Descartar'));
      await tester.pumpAndSettle();

      // Diálogo fechou e callback não foi chamado
      expect(find.text('Proposta de Replanejamento'), findsNothing);
      expect(planAppliedCalled, isFalse);
    });

    testWidgets('exibe aviso explícito de déficit de carga horária quando houver capacidade insuficiente', (
      tester,
    ) async {
      final planningResult = PlanningEngineResult(
        classroomSubjectId: 'cs1',
        isSuccessful: false,
        plannedLessons: const [],
        preservedLessons: const [],
        contentAllocations: const [],
        availableLessonOccurrences: 2,
        usedLessonOccurrences: 2,
        conflicts: const [
          PlanningConflict(
            type: PlanningConflictType.insufficientCapacity,
            message: 'Capacidade letiva esgotada: faltam 3 aula(s) para cobrir o conteúdo.',
          ),
        ],
        warnings: const [],
      );

      final proposal = ReplanningProposal(
        classroomSubjectId: 'cs1',
        generatedAt: DateTime.utc(2026, 2, 10),
        referenceDate: DateTime.utc(2026, 2, 10),
        sourcePlannedLessonIds: const {},
        sourceExecutionRecordIds: const {},
        planningResult: planningResult,
        shifts: const [],
        preservedHistoricLessonsCount: 0,
        preservedLockedLessonsCount: 0,
        affectedFutureLessonsCount: 0,
        unaffectedFutureLessonsCount: 0,
        isIdenticalToCurrentPlan: false,
        explanations: ['Atenção: capacidade letiva insuficiente. Déficit de 3 aula(s).'],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: ReplanningPreviewDialog(
            classroomName: '6º Ano A',
            subjectName: 'Matemática',
            proposal: proposal,
            onPlanApplied: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aviso de Déficit de Carga Horária'), findsOneWidget);
      expect(find.textContaining('Capacidade letiva esgotada'), findsOneWidget);
    });

    testWidgets('exibe card de viabilidade curricular, métricas de capacidade e cenários de recuperação', (
      tester,
    ) async {
      final capacityAnalysis = CurricularCapacityAnalysis(
        classroomSubjectId: 'cs1',
        referenceDate: DateTime(2026, 3, 2),
        academicYearEndDate: DateTime(2026, 12, 18),
        totalFutureAvailableSlots: 20,
        totalRemainingDemandLessons: 25,
        mandatoryRemainingDemandLessons: 20,
        optionalRemainingDemandLessons: 5,
        capacityDeficit: 5,
        mandatoryCapacityDeficit: 0,
        safetyMarginLessons: 0,
        viabilityStatus: CurricularViabilityStatus.viableWithAdjustments,
        estimatedCompletionDate: DateTime(2026, 12, 18),
        overflowsAcademicYear: false,
        contentsAtRisk: const [],
        limitingConstraints: const ['Término do ano letivo em 18/12/2026.'],
        summaryMessage: 'Viável com priorização de obrigatórios.',
      );

      final scenario = RecoveryScenario(
        type: RecoveryScenarioType.essentialPriority,
        title: 'Cenário C — Priorização de Obrigatórios',
        description: 'Prioriza integralmente os conteúdos essenciais.',
        hypothesis: 'Garante o cumprimento dos conteúdos obrigatórios.',
        capacityAnalysis: capacityAnalysis,
        proposedAllocations: const [],
        extraLessonsNeeded: 0,
        unallocatedContentTitles: const ['Atividade Opcional'],
        canBeAppliedDirectly: true,
      );

      final proposal = ReplanningProposal(
        classroomSubjectId: 'cs1',
        generatedAt: DateTime.utc(2026, 2, 10),
        referenceDate: DateTime.utc(2026, 2, 10),
        sourcePlannedLessonIds: const {},
        sourceExecutionRecordIds: const {},
        planningResult: const PlanningEngineResult(
          classroomSubjectId: 'cs1',
          isSuccessful: true,
          plannedLessons: [],
          preservedLessons: [],
          contentAllocations: [],
          availableLessonOccurrences: 20,
          usedLessonOccurrences: 20,
          conflicts: [],
          warnings: [],
        ),
        shifts: const [],
        preservedHistoricLessonsCount: 0,
        preservedLockedLessonsCount: 0,
        affectedFutureLessonsCount: 0,
        unaffectedFutureLessonsCount: 0,
        isIdenticalToCurrentPlan: false,
        explanations: const [],
        capacityAnalysis: capacityAnalysis,
        recoveryScenarios: [scenario],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: ReplanningPreviewDialog(
            classroomName: '6º Ano A',
            subjectName: 'Matemática',
            proposal: proposal,
            onPlanApplied: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Viável com Ajustes'), findsOneWidget);
      expect(find.text('Projeção de Viabilidade Curricular'), findsOneWidget);
      expect(find.text('Cenários de Recuperação Curricular'), findsOneWidget);
      expect(find.text('Cenário C — Priorização de Obrigatórios'), findsOneWidget);
      expect(find.text('Viável com priorização de obrigatórios.'), findsOneWidget);
    });
  });

  group('ReplanningScreen Flow Tests', () {
    testWidgets('exibe tela vazia de forma graciosa quando não há turmas cadastradas', (
      tester,
    ) async {
      // Insere apenas ano letivo no banco
      await dependencies.academicYearRepository.save(
        AcademicYear(
          id: 'ay-empty',
          year: 2026,
          title: 'Ano 2026',
          startDate: DateTime(2026, 2, 2),
          endDate: DateTime(2026, 12, 18),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const ReplanningScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma Turma Cadastrada'), findsOneWidget);
    });

    testWidgets('suporta acessibilidade e layout responsivo com texto ampliado', (
      tester,
    ) async {
      await dependencies.academicYearRepository.save(
        AcademicYear(
          id: 'ay-empty',
          year: 2026,
          title: 'Ano 2026',
          startDate: DateTime(2026, 2, 2),
          endDate: DateTime(2026, 12, 18),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          textScaler: const TextScaler.linear(1.5),
          child: const ReplanningScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma Turma Cadastrada'), findsOneWidget);
    });
  });
}
