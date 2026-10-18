import 'package:app/presentation/components/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppCard Component Tests', () {
    testWidgets('deve exibir título, descrição, badge e responder ao toque', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              title: 'Minhas Turmas',
              description: 'Gerencie horários e disciplinas',
              icon: Icons.groups,
              badgeText: 'Ativo',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Minhas Turmas'), findsOneWidget);
      expect(find.text('Gerencie horários e disciplinas'), findsOneWidget);
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.byIcon(Icons.groups), findsOneWidget);

      await tester.tap(find.byType(AppCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
