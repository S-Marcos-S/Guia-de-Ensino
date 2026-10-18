import 'package:app/core/localization/app_strings.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:flutter/material.dart';

/// Tela de Gerenciamento de Turmas e Disciplinas.
class ClassroomsScreen extends StatelessWidget {
  const ClassroomsScreen({super.key});

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
                title: AppStrings.cardClassroomsTitle,
                subtitle: AppStrings.cardClassroomsDesc,
              ),
              Expanded(
                child: EmptyStateView(
                  title: AppStrings.emptyClassroomsTitle,
                  description: AppStrings.emptyClassroomsDesc,
                  icon: Icons.groups_outlined,
                  actionLabel: 'Saiba Mais',
                  onActionPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'O cadastro de turmas será implementado na Etapa 3 do Roadmap.',
                        ),
                      ),
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
