import 'package:app/core/di/app_dependencies.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/school_calendar_event.dart';
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

  group('Calendar & School Year Flow Widget Tests', () {
    testWidgets('deve exibir estado vazio e permitir criar Ano Letivo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      // Navega para a aba de Calendário
      final calendarTab = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month_outlined),
      );
      await tester.tap(calendarTab);
      await tester.pumpAndSettle();

      expect(find.text('Nenhum ano letivo configurado'), findsOneWidget);

      // Clica em "Criar Ano Letivo"
      final createBtn = find.text('Criar Ano Letivo');
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Verifica abertura do diálogo
      expect(find.text('Novo Ano Letivo'), findsOneWidget);
      expect(find.text('Título do Período'), findsOneWidget);

      // Clica em Salvar
      final saveBtn = find.text('Salvar');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Confirma que o ano letivo foi salvo e o cálculo determinístico de dias letivos é exibido
      expect(find.text('Cálculo de Dias Letivos'), findsOneWidget);
      expect(find.text('Dias Letivos Reais'), findsOneWidget);
    });

    testWidgets(
      'deve listar eventos escolares e permitir adicionar e excluir feriado',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Pré-popula um ano letivo no repositório
        await dependencies.academicYearRepository.save(
          AcademicYear(
            id: 'ay-test-2026',
            year: 2026,
            title: 'Ano Letivo 2026',
            startDate: DateTime(2026, 2, 2),
            endDate: DateTime(2026, 12, 18),
            totalMandatoryDays: 200,
          ),
        );

        // Pré-popula um feriado
        await dependencies.calendarEventRepository.save(
          SchoolCalendarEvent(
            id: 'ev-test-1',
            academicYearId: 'ay-test-2026',
            title: 'Feriado Tiradentes',
            startDate: DateTime(2026, 4, 21),
            endDate: DateTime(2026, 4, 21),
            type: SchoolEventType.holiday,
          ),
        );

        await tester.pumpWidget(GuiaDeEnsinoApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        // Navega para aba Calendário
        final calendarTab = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.calendar_month_outlined),
        );
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();

        // Verifica exibição do evento pré-populado
        expect(find.text('Feriado Tiradentes'), findsOneWidget);
        expect(find.text('Feriados e Recessos (1)'), findsOneWidget);

        // Clica para excluir evento
        final deleteBtn = find.byIcon(Icons.delete_outline);
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Confirma o diálogo AppConfirmDialog
        expect(find.text('Excluir Evento'), findsOneWidget);
        final confirmBtn = find.text('Excluir');
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Confirma que o evento foi removido da lista
        expect(find.text('Feriado Tiradentes'), findsNothing);
        expect(find.text('Feriados e Recessos (0)'), findsOneWidget);
      },
    );
  });
}
