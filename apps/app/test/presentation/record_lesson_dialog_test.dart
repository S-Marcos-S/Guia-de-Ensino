import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/usecases/record_lesson_execution_usecase.dart';
import 'package:app/presentation/components/record_lesson_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCourseContentRepository implements CourseContentRepository {
  FakeCourseContentRepository({
    this.contents = const [],
    this.shouldThrow = false,
  });

  final List<CourseContent> contents;
  final bool shouldThrow;

  @override
  Future<List<CourseContent>> getByClassroomSubject(
    String classroomSubjectId,
  ) async {
    if (shouldThrow) {
      throw Exception('Falha de conexão ao carregar conteúdos');
    }
    return contents;
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<CourseContent?> findById(String id) async => null;

  @override
  Future<List<String>> getPrerequisiteIds(String contentId) async => [];

  @override
  Future<void> reorder(
    String classroomSubjectId,
    List<String> orderedContentIds,
  ) async {}

  @override
  Future<void> save(CourseContent content) async {}

  @override
  Future<void> saveAll(List<CourseContent> contents) async {}

  @override
  Future<void> setPrerequisites(
    String contentId,
    List<String> prerequisiteIds,
  ) async {}
}

class FakeRecordLessonExecutionUseCase implements RecordLessonExecutionUseCase {
  FakeRecordLessonExecutionUseCase({this.shouldThrow = false, this.delay});

  final bool shouldThrow;
  final Duration? delay;
  int callCount = 0;
  RecordLessonExecutionParams? lastParams;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<LessonExecutionRecord> execute(
    RecordLessonExecutionParams params,
  ) async {
    callCount++;
    lastParams = params;

    if (delay != null) {
      await Future<void>.delayed(delay!);
    }

    if (shouldThrow) {
      throw const LessonExecutionIntegrityException(
        'Erro simulado de integridade na gravação',
      );
    }

    return LessonExecutionRecord(
      id: 'rec-fake-1',
      plannedLessonId: params.plannedLessonId,
      classroomSubjectId: params.classroomSubjectId,
      executionDate: params.executionDate,
      status: params.status,
      actualContentIds: params.actualContentIds,
      cancellationReason: params.cancellationReason,
      cancellationDetails: params.cancellationDetails,
      pedagogicalNotes: params.pedagogicalNotes,
      needsFollowUp: params.needsFollowUp,
      followUpNotes: params.followUpNotes,
      recordedAt: DateTime.utc(2026, 3, 10, 10, 0),
    );
  }
}

void main() {
  final testLesson = PlannedLesson(
    id: 'l-dialog-1',
    classroomSubjectId: 'cs-test',
    date: DateTime.utc(2026, 3, 10),
    orderInDay: 1,
    contentIds: const ['cnt-1', 'cnt-2'],
    status: LessonExecutionStatus.planned,
  );

  final testContents = [
    const CourseContent(
      id: 'cnt-1',
      classroomSubjectId: 'cs-test',
      title: 'Tópico 1 - Funções Afins',
      orderIndex: 1,
    ),
    const CourseContent(
      id: 'cnt-2',
      classroomSubjectId: 'cs-test',
      title: 'Tópico 2 - Gráfico da Função Afim',
      orderIndex: 2,
    ),
    const CourseContent(
      id: 'cnt-3',
      classroomSubjectId: 'cs-test',
      title: 'Tópico 3 - Raiz da Função',
      orderIndex: 3,
    ),
  ];

  Widget createWidget({
    PlannedLesson? lesson,
    LessonExecutionRecord? record,
    CourseContentRepository? contentRepo,
    RecordLessonExecutionUseCase? useCase,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RecordLessonDialog(
          plannedLesson: lesson ?? testLesson,
          classroomSubjectId: 'cs-test',
          classroomName: '7º Ano A',
          subjectName: 'Matemática',
          executionRecord: record,
          courseContentRepository:
              contentRepo ??
              FakeCourseContentRepository(contents: testContents),
          recordLessonExecutionUseCase:
              useCase ?? FakeRecordLessonExecutionUseCase(),
        ),
      ),
    );
  }

  group('RecordLessonDialog Widget Tests', () {
    testWidgets('1. Pré-seleção editável e seleção de conteúdos adicionais', (
      tester,
    ) async {
      final fakeUseCase = FakeRecordLessonExecutionUseCase();

      await tester.pumpWidget(
        createWidget(
          useCase: fakeUseCase,
          contentRepo: FakeCourseContentRepository(contents: testContents),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica que os conteúdos planejados (cnt-1 e cnt-2) estão inicialmente marcados
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(3));

      // Desmarca o cnt-1 (primeiro checkbox)
      await tester.tap(find.text('Tópico 1 - Funções Afins'));
      await tester.pumpAndSettle();

      // Marca o cnt-3 (terceiro checkbox, não planejado originalmente)
      await tester.tap(find.text('Tópico 3 - Raiz da Função'));
      await tester.pumpAndSettle();

      // Clica em Salvar
      await tester.tap(find.text(AppStrings.saveRecordButton));
      await tester.pumpAndSettle();

      expect(fakeUseCase.callCount, equals(1));
      expect(fakeUseCase.lastParams, isNotNull);
      expect(
        fakeUseCase.lastParams!.actualContentIds,
        unorderedEquals(['cnt-2', 'cnt-3']),
      );
      expect(
        fakeUseCase.lastParams!.actualContentIds,
        isNot(contains('cnt-1')),
      );
      expect(
        fakeUseCase.lastParams!.status,
        equals(LessonExecutionStatus.completed),
      );
    });

    testWidgets(
      '2. Aula não realizada sem motivo de cancelamento bloqueia e exibe erro',
      (tester) async {
        final fakeUseCase = FakeRecordLessonExecutionUseCase();

        await tester.pumpWidget(createWidget(useCase: fakeUseCase));
        await tester.pumpAndSettle();

        // Seleciona status "Não Realizada"
        await tester.tap(find.text(AppStrings.statusNotHeldOption));
        await tester.pumpAndSettle();

        // Conteúdos devem ser limpos e aviso exibido
        expect(find.text(AppStrings.notHeldNoContentsNotice), findsOneWidget);

        // Tenta salvar sem motivo
        await tester.tap(find.text(AppStrings.saveRecordButton));
        await tester.pumpAndSettle();

        // Valida que erro foi exibido e useCase NÃO foi chamado
        expect(
          find.text(AppStrings.validationNotHeldReasonRequired),
          findsOneWidget,
        );
        expect(fakeUseCase.callCount, equals(0));
      },
    );

    testWidgets('3. Motivo "other" com e sem detalhes adicionais', (
      tester,
    ) async {
      final fakeUseCase = FakeRecordLessonExecutionUseCase();

      await tester.pumpWidget(createWidget(useCase: fakeUseCase));
      await tester.pumpAndSettle();

      // Seleciona status "Não Realizada"
      await tester.tap(find.text(AppStrings.statusNotHeldOption));
      await tester.pumpAndSettle();

      // Seleciona motivo "Outro Motivo"
      await tester.tap(
        find.byType(DropdownButtonFormField<LessonCancellationReason>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outro Motivo').last);
      await tester.pumpAndSettle();

      // Salva sem detalhes (opcional conforme regra do domínio)
      await tester.tap(find.text(AppStrings.saveRecordButton));
      await tester.pumpAndSettle();

      expect(fakeUseCase.callCount, equals(1));
      expect(
        fakeUseCase.lastParams!.cancellationReason,
        equals(LessonCancellationReason.other),
      );
      expect(fakeUseCase.lastParams!.cancellationDetails, isNull);
    });

    testWidgets(
      '4. Regras de validação da aula parcial (invariantes do domínio)',
      (tester) async {
        final fakeUseCase = FakeRecordLessonExecutionUseCase();

        await tester.pumpWidget(createWidget(useCase: fakeUseCase));
        await tester.pumpAndSettle();

        // Seleciona status "Parcial"
        await tester.tap(find.text(AppStrings.statusPartiallyCompletedOption));
        await tester.pumpAndSettle();

        // Limpa todos os conteúdos
        await tester.tap(
          find.text(AppStrings.clearSelectedContentsQuickAction),
        );
        await tester.pumpAndSettle();

        // Tenta salvar sem conteúdos, sem notas e sem continuidade
        await tester.tap(find.text(AppStrings.saveRecordButton));
        await tester.pumpAndSettle();

        expect(
          find.text(AppStrings.validationPartialLessonRequired),
          findsOneWidget,
        );
        expect(fakeUseCase.callCount, equals(0));

        // Informa apenas observações pedagógicas e tenta novamente
        await tester.enterText(
          find.widgetWithText(TextFormField, AppStrings.pedagogicalNotesLabel),
          'Apenas metade da atividade foi concluída devido a dúvidas conceituais.',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.saveRecordButton));
        await tester.pumpAndSettle();

        expect(fakeUseCase.callCount, equals(1));
        expect(
          fakeUseCase.lastParams!.status,
          equals(LessonExecutionStatus.partiallyCompleted),
        );
        expect(
          fakeUseCase.lastParams!.pedagogicalNotes,
          contains('Apenas metade da atividade foi concluída'),
        );
      },
    );

    testWidgets(
      '5. Falha de persistência com preservação dos campos preenchidos',
      (tester) async {
        final fakeUseCase = FakeRecordLessonExecutionUseCase(shouldThrow: true);

        await tester.pumpWidget(createWidget(useCase: fakeUseCase));
        await tester.pumpAndSettle();

        // Digita observações pedagógicas
        await tester.enterText(
          find.widgetWithText(TextFormField, AppStrings.pedagogicalNotesLabel),
          'Anotação persistida mesmo com erro.',
        );

        // Marca continuidade
        await tester.tap(find.text(AppStrings.needsFollowUpLabel));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, AppStrings.followUpNotesLabel),
          'Retomar na próxima aula.',
        );

        // Clica em salvar
        await tester.tap(find.text(AppStrings.saveRecordButton));
        await tester.pumpAndSettle();

        // O diálogo permanece aberto, exibe erro e mantém os textos
        expect(
          find.text('Erro simulado de integridade na gravação'),
          findsOneWidget,
        );
        expect(
          find.text('Anotação persistida mesmo com erro.'),
          findsOneWidget,
        );
        expect(find.text('Retomar na próxima aula.'), findsOneWidget);
        expect(find.byType(RecordLessonDialog), findsOneWidget);
      },
    );

    testWidgets(
      '6. Prevenção de duplo envio enquanto a gravação está em andamento',
      (tester) async {
        final fakeUseCase = FakeRecordLessonExecutionUseCase(
          delay: const Duration(milliseconds: 200),
        );

        await tester.pumpWidget(createWidget(useCase: fakeUseCase));
        await tester.pumpAndSettle();

        // Dispara o primeiro clique
        await tester.tap(find.text(AppStrings.saveRecordButton));
        await tester.pump(); // Inicia o salvamento sem avançar o timer

        // Dispara o segundo clique enquanto está salvando
        await tester.tap(find.byType(RecordLessonDialog));

        // Avança o timer até o fim da gravação
        await tester.pumpAndSettle();

        // Deve ter chamado o use case rigorosamente uma única vez
        expect(fakeUseCase.callCount, equals(1));
      },
    );

    testWidgets('7. Cancelamento do diálogo sem gravação', (tester) async {
      final fakeUseCase = FakeRecordLessonExecutionUseCase();
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => RecordLessonDialog(
                      plannedLesson: testLesson,
                      classroomSubjectId: 'cs-test',
                      classroomName: '7º Ano A',
                      subjectName: 'Matemática',
                      courseContentRepository: FakeCourseContentRepository(
                        contents: testContents,
                      ),
                      recordLessonExecutionUseCase: fakeUseCase,
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Clica em Cancelar
      await tester.tap(find.text(AppStrings.cancelButton));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(fakeUseCase.callCount, equals(0));
    });

    testWidgets(
      '11. Falha ao carregar conteúdos curriculares exibe erro e botão de tentar novamente',
      (tester) async {
        final failingRepo = FakeCourseContentRepository(shouldThrow: true);

        await tester.pumpWidget(createWidget(contentRepo: failingRepo));
        await tester.pumpAndSettle();

        // Verifica que o erro de carregamento foi exibido
        expect(find.text(AppStrings.loadingContentsError), findsOneWidget);
        expect(find.text(AppStrings.retryButton), findsOneWidget);
        // Não deve exibir como se estivesse vazio com sucesso
        expect(
          find.text(AppStrings.noContentsForClassroomSubject),
          findsNothing,
        );
      },
    );
  });
}
