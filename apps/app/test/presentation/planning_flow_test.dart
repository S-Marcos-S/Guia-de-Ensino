import 'package:app/core/di/app_dependencies.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/presentation/components/planning_preview_dialog.dart';
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

  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      home: AppDependencyScope(
        dependencies: dependencies,
        child: Scaffold(body: child),
      ),
    );
  }

  group('PlanningPreviewDialog Tests', () {
    testWidgets('exibe métricas de capacidade e alocações de conteúdos', (
      tester,
    ) async {
      const content = CourseContent(
        id: 'c1',
        classroomSubjectId: 'cs1',
        title: 'Geometria Básica',
        estimatedLessons: 2,
        orderIndex: 1,
        origin: ContentOrigin.manual,
      );

      final lesson1 = PlannedLesson(
        id: 'l1',
        classroomSubjectId: 'cs1',
        date: DateTime(2026, 2, 2),
        orderInDay: 1,
        contentIds: const ['c1'],
      );
      final lesson2 = PlannedLesson(
        id: 'l2',
        classroomSubjectId: 'cs1',
        date: DateTime(2026, 2, 9),
        orderInDay: 1,
        contentIds: const ['c1'],
      );

      final result = PlanningEngineResult(
        classroomSubjectId: 'cs1',
        isSuccessful: true,
        plannedLessons: [
          PlannedLessonAllocation(
            lesson: lesson1,
            contentIds: const ['c1'],
            isPreservedFromHistory: false,
          ),
          PlannedLessonAllocation(
            lesson: lesson2,
            contentIds: const ['c1'],
            isPreservedFromHistory: false,
          ),
        ],
        preservedLessons: const [],
        contentAllocations: [
          ContentAllocationStatus(
            content: content,
            allocatedLessons: 2,
            requiredLessons: 2,
            isFullyAllocated: true,
            allocatedDates: [DateTime(2026, 2, 2), DateTime(2026, 2, 9)],
          ),
        ],
        availableLessonOccurrences: 2,
        usedLessonOccurrences: 2,
        conflicts: const [],
        warnings: const [],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: PlanningPreviewDialog(
            classroomName: '6º Ano A',
            subjectName: 'Matemática',
            result: result,
            onPlanApplied: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Distribuição de Aulas Planejadas'), findsOneWidget);
      expect(find.text('6º Ano A • Matemática'), findsOneWidget);
      expect(find.text('Disponíveis'), findsOneWidget);
      expect(find.text('Utilizadas'), findsOneWidget);
      expect(find.text('Déficit'), findsOneWidget);
      expect(find.text('Geometria Básica'), findsOneWidget);
      expect(find.text('2/2 aulas'), findsOneWidget);
      expect(find.text('Homologar e Salvar Plano'), findsOneWidget);
    });

    testWidgets(
      'exibe aviso de déficit e desabilita botão apenas se houver conflito bloqueante',
      (tester) async {
        const content = CourseContent(
          id: 'c1',
          classroomSubjectId: 'cs1',
          title: 'Álgebra com Déficit',
          estimatedLessons: 4,
          orderIndex: 1,
          origin: ContentOrigin.manual,
        );

        const resultWithDeficit = PlanningEngineResult(
          classroomSubjectId: 'cs1',
          isSuccessful: false,
          plannedLessons: [],
          preservedLessons: [],
          contentAllocations: [
            ContentAllocationStatus(
              content: content,
              allocatedLessons: 2,
              requiredLessons: 4,
              isFullyAllocated: false,
              reasonNotFullyAllocated:
                  'Capacidade letiva esgotada: faltam 2 aula(s)',
            ),
          ],
          availableLessonOccurrences: 2,
          usedLessonOccurrences: 2,
          conflicts: [
            PlanningConflict(
              type: PlanningConflictType.insufficientCapacity,
              message: 'O conteúdo "Álgebra com Déficit" necessita de 4 aulas, mas apenas 2 puderam ser alocadas.',
            ),
          ],
          warnings: [],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: PlanningPreviewDialog(
              classroomName: '7º Ano B',
              subjectName: 'Matemática',
              result: resultWithDeficit,
              onPlanApplied: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Aviso de Insuficiência de Carga Horária'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'O conteúdo "Álgebra com Déficit" necessita de 4 aulas',
          ),
          findsOneWidget,
        );

        // Conflito de insuficiência de capacidade não é bloqueante (permite homologar a distribuição viável)
        final homologarButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Homologar e Salvar Plano'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(homologarButton.onPressed, isNotNull);

        // Agora testa com conflito bloqueante (circularPrerequisite)
        const resultFatal = PlanningEngineResult(
          classroomSubjectId: 'cs1',
          isSuccessful: false,
          plannedLessons: [],
          preservedLessons: [],
          contentAllocations: [],
          availableLessonOccurrences: 0,
          usedLessonOccurrences: 0,
          conflicts: [
            PlanningConflict(
              type: PlanningConflictType.circularPrerequisite,
              message: 'Dependência circular detectada entre os conteúdos.',
            ),
          ],
          warnings: [],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: PlanningPreviewDialog(
              classroomName: '7º Ano B',
              subjectName: 'Matemática',
              result: resultFatal,
              onPlanApplied: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Conflitos Impeditivos'), findsOneWidget);
        expect(find.textContaining('Dependência circular'), findsOneWidget);

        final fatalButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Homologar e Salvar Plano'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(fatalButton.onPressed, isNull);
      },
    );
  });
}
