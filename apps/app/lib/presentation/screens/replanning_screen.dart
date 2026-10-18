import 'package:app/core/localization/app_strings.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:flutter/material.dart';

/// Tela do Motor de Replanejamento Automático.
class ReplanningScreen extends StatelessWidget {
  const ReplanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(
                title: AppStrings.cardReplanningTitle,
                subtitle: AppStrings.cardReplanningDesc,
              ),
              Expanded(
                child: EmptyStateView(
                  title: AppStrings.emptyReplanningTitle,
                  description: AppStrings.emptyReplanningDesc,
                  icon: Icons.auto_mode_outlined,
                  actionLabel: 'Ver Regras do Motor',
                  onActionPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Replanejamento Automático'),
                          content: const Text(
                            'O motor determinístico recalculará as aulas futuras preservando '
                            'as aulas já realizadas e avaliações fixas. Ele será ativado na Etapa 7.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Entendido'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
