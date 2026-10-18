import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
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

  group('Navigation & App Integration Tests (Mobile Layout)', () {
    testWidgets(
      'deve iniciar na tela inicial exibindo cabeçalho e cartões de acesso',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
        expect(find.text(AppStrings.cardClassroomsTitle), findsWidgets);
        expect(find.text(AppStrings.cardCalendarTitle), findsWidgets);
      },
    );

    testWidgets('deve alternar para tela de Turmas ao tocar na aba Turmas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      // Encontra a aba Turmas na barra de navegação inferior
      final classroomsTab = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.groups_outlined),
      );
      expect(classroomsTab, findsOneWidget);

      await tester.tap(classroomsTab);
      await tester.pumpAndSettle();

      expect(find.text('Ano Letivo Necessário'), findsOneWidget);
    });

    testWidgets(
      'deve alternar para tela de Calendário ao tocar na aba Calendário',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        // Encontra a aba Calendário na barra de navegação inferior
        final calendarTab = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.calendar_month_outlined),
        );
        expect(calendarTab, findsOneWidget);

        await tester.tap(calendarTab);
        await tester.pumpAndSettle();

        expect(find.text('Nenhum ano letivo configurado'), findsOneWidget);
      },
    );

    testWidgets(
      'deve rolar e alternar para tela de Replanejamento ao tocar no cartão',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        final replanningCard = find.text(AppStrings.cardReplanningDesc);
        await tester.scrollUntilVisible(
          replanningCard,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(replanningCard);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.emptyReplanningTitle), findsOneWidget);
      },
    );
  });

  group('Navigation & App Integration Tests (Desktop Layout)', () {
    testWidgets('deve exibir NavigationRail em telas amplas de desktop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // Clica na opção de Conteúdos no NavigationRail
      final contentsDest = find.text(AppStrings.navContents);
      expect(contentsDest, findsOneWidget);

      await tester.tap(contentsDest);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.emptyContentsTitle), findsOneWidget);
    });
  });
}
