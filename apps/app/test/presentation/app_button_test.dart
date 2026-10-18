import 'package:app/presentation/components/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppButton Component Tests', () {
    testWidgets(
      'deve renderizar rótulo e disparar evento onTap quando clicado',
      (tester) async {
        var clicked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Salvar Planejamento',
                onPressed: () => clicked = true,
              ),
            ),
          ),
        );

        expect(find.text('Salvar Planejamento'), findsOneWidget);

        await tester.tap(find.byType(AppButton));
        await tester.pump();

        expect(clicked, isTrue);
      },
    );

    testWidgets(
      'deve exibir indicador de carregamento quando isLoading for true',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Processando',
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Processando'), findsNothing);
      },
    );
  });
}
