import 'package:app/core/di/app_dependencies.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/main.dart';
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

  group('Classroom & Subjects Flow Widget Tests', () {
    testWidgets(
      'deve cadastrar uma nova turma quando houver ano letivo ativo',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Pré-cadastra o Ano Letivo 2026
        await dependencies.academicYearRepository.save(
          AcademicYear(
            id: 'ay-2026',
            year: 2026,
            title: 'Ano Letivo 2026',
            startDate: DateTime(2026, 2, 2),
            endDate: DateTime(2026, 12, 18),
          ),
        );

        await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        // Navega para aba Turmas
        final classroomsTab = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.groups_outlined),
        );
        await tester.tap(classroomsTab);
        await tester.pumpAndSettle();

        expect(
          find.text('Nenhuma turma cadastrada neste ano letivo'),
          findsOneWidget,
        );

        // Clica em Nova Turma
        final newClassBtn = find.text('Nova Turma');
        expect(newClassBtn, findsOneWidget);
        await tester.tap(newClassBtn);
        await tester.pumpAndSettle();

        // Preenche o formulário da nova turma
        expect(find.text('Cadastrar Nova Turma'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome da Turma'),
          '9º Ano A',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Ano / Série Escolar'),
          'Ensino Fundamental 9º ano',
        );

        // Clica em Salvar
        final saveBtn = find.text('Salvar');
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verifica se a turma cadastrada aparece na listagem
        expect(find.text('9º Ano A'), findsOneWidget);
        expect(
          find.textContaining('Ensino Fundamental 9º ano'),
          findsOneWidget,
        );
        expect(find.text('0 disciplinas'), findsOneWidget);
      },
    );

    testWidgets(
      'deve vincular disciplina à turma e permitir exclusão da turma',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Pré-cadastra ano letivo e uma turma
        await dependencies.academicYearRepository.save(
          AcademicYear(
            id: 'ay-2026',
            year: 2026,
            title: 'Ano Letivo 2026',
            startDate: DateTime(2026, 2, 2),
            endDate: DateTime(2026, 12, 18),
          ),
        );

        await dependencies.classroomRepository.save(
          const Classroom(
            id: 'cls-1',
            academicYearId: 'ay-2026',
            name: '6º Ano B',
            gradeLevel: '6º Ano EF',
          ),
        );

        await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        // Navega para aba Turmas
        final classroomsTab = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.groups_outlined),
        );
        await tester.tap(classroomsTab);
        await tester.pumpAndSettle();

        expect(find.text('6º Ano B'), findsOneWidget);

        // Abre diálogo de gerenciamento de disciplinas
        final configBtn = find.text('Disciplinas e Grade');
        expect(configBtn, findsOneWidget);
        await tester.tap(configBtn);
        await tester.pumpAndSettle();

        expect(find.text('Disciplinas — 6º Ano B'), findsOneWidget);

        // Clica em Vincular Disciplina
        final bindBtn = find.text('Vincular Disciplina');
        await tester.tap(bindBtn);
        await tester.pumpAndSettle();

        // Como não há disciplinas cadastradas ainda, abre o formulário de novo componente
        expect(find.text('Associar Disciplina'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome do Componente Curricular'),
          'Ciências Naturais',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Aulas Semanais nesta Turma'),
          '3',
        );

        // Salva o vínculo
        final confirmBindBtn = find.text('Vincular');
        await tester.tap(confirmBindBtn);
        await tester.pumpAndSettle();

        // Fecha o diálogo de disciplinas
        final closeBtn = find.text('Fechar');
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();

        // Confirma que a turma agora exibe 1 disciplina vinculada
        expect(find.text('1 disciplinas'), findsOneWidget);

        // Agora testa exclusão da turma com AppConfirmDialog
        final deleteClassBtn = find.byTooltip('Excluir Turma');
        await tester.tap(deleteClassBtn);
        await tester.pumpAndSettle();

        expect(find.text('Excluir Turma'), findsOneWidget);
        final confirmDeleteBtn = find.text('Excluir');
        await tester.tap(confirmDeleteBtn);
        await tester.pumpAndSettle();

        // A lista deve voltar a estar vazia
        expect(find.text('6º Ano B'), findsNothing);
        expect(
          find.text('Nenhuma turma cadastrada neste ano letivo'),
          findsOneWidget,
        );
      },
    );
  });
}
