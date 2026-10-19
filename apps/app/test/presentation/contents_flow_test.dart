import 'package:app/core/di/app_dependencies.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/curriculum_competency.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AppDependencies dependencies;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dependencies = AppDependencies(database: db);

    // Pré-configura ano letivo, disciplina e turma com disciplina vinculada
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
      const Subject(id: 'sub-mat', name: 'Matemática'),
    );

    await dependencies.classroomRepository.save(
      const Classroom(
        id: 'cls-9a',
        academicYearId: 'ay-2026',
        name: '9º Ano A',
        gradeLevel: '9º ano',
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cs-mat-9a',
            classroomId: 'cls-9a',
            subjectId: 'sub-mat',
            weeklyLessons: 4,
          ),
        ],
      ),
    );

    await dependencies.curriculumCompetencyRepository.save(
      const CurriculumCompetency(
        id: 'comp-seed-1',
        code: 'EF06MA01',
        description: 'Comparar e ordenar números racionais',
        thematicUnit: 'Números',
        stage: 'Ensino Fundamental',
        gradeLevel: '6º ano',
        subjectName: 'Matemática',
        sourceName: 'BNCC MEC',
        sourceVersion: 'Resolução CNE/CP 2/2017',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ContentsScreen Flow Widget Tests', () {
    testWidgets(
      'deve exibir tela de conteúdos com turma e disciplina selecionadas',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        // Navega para aba Conteúdos
        final contentsTab = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.menu_book_outlined),
        );
        await tester.tap(contentsTab);
        await tester.pumpAndSettle();

        // Deve exibir o cabeçalho e o estado vazio inicial de conteúdos
        expect(find.text('Conteúdos Programáticos'), findsOneWidget);
        expect(find.text('Nenhum conteúdo adicionado'), findsOneWidget);
        expect(find.text('Novo Conteúdo'), findsOneWidget);
      },
    );

    testWidgets('deve cadastrar um novo conteúdo personalizado com sucesso', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      final contentsTab = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.menu_book_outlined),
      );
      await tester.tap(contentsTab);
      await tester.pumpAndSettle();

      // Abre diálogo de novo conteúdo
      await tester.tap(find.text('Novo Conteúdo'));
      await tester.pumpAndSettle();

      expect(find.text('Novo Conteúdo Programático'), findsOneWidget);

      // Preenche o título
      final titleField = find.widgetWithText(
        TextFormField,
        'Título do Conteúdo *',
      );
      await tester.enterText(titleField, 'Álgebra e Equações');

      // Clica em Salvar
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Confirma que o conteúdo aparece na lista
      expect(find.text('Álgebra e Equações'), findsOneWidget);
      expect(find.text('Personalizado'), findsOneWidget);
      expect(find.text('Obrigatório'), findsOneWidget);

      final contents = await dependencies.courseContentRepository
          .getByClassroomSubject('cs-mat-9a');
      expect(contents.length, equals(1));
      expect(contents.first.title, equals('Álgebra e Equações'));
    });

    testWidgets('deve excluir um conteúdo programático', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await dependencies.courseContentRepository.save(
        const CourseContent(
          id: 'cnt-del',
          classroomSubjectId: 'cs-mat-9a',
          title: 'Conteúdo para Deletar',
          estimatedLessons: 2,
          orderIndex: 1,
        ),
      );

      await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      final contentsTab = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.menu_book_outlined),
      );
      await tester.tap(contentsTab);
      await tester.pumpAndSettle();

      expect(find.text('Conteúdo para Deletar'), findsOneWidget);

      // Clica no botão de lixeira
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Excluir Conteúdo?'), findsOneWidget);

      // Confirma exclusão
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Conteúdo para Deletar'), findsNothing);
      expect(find.text('Nenhum conteúdo adicionado'), findsOneWidget);
    });
  });
}
