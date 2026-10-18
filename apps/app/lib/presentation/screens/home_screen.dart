import 'package:app/core/localization/app_strings.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:app/presentation/components/app_card.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:flutter/material.dart';

/// Tela inicial funcional do Guia de Ensino.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigateToTab});

  final void Function(int tabIndex) onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho de Boas-vindas
              const AppHeader(
                title: AppStrings.welcomeTitle,
                subtitle: AppStrings.welcomeSubtitle,
              ),
              const SizedBox(height: 8),

              // Cartão de Resumo do Planejamento
              Card(
                color: colorScheme.primaryContainer.withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.primary.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.currentStatusSection,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.noActivePlanning,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: AppStrings.startSetupButton,
                        icon: Icons.add_circle_outline,
                        variant: AppButtonVariant.primary,
                        onPressed: () {
                          // Navega para aba de Turmas
                          onNavigateToTab(1);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Seção de Acesso Rápido
              Text(
                AppStrings.quickAccessSection,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 14),

              // Grade / Lista de Cartões de Acesso Rápido
              AppCard(
                title: AppStrings.cardClassroomsTitle,
                description: AppStrings.cardClassroomsDesc,
                icon: Icons.groups_outlined,
                onTap: () => onNavigateToTab(1),
              ),
              const SizedBox(height: 12),
              AppCard(
                title: AppStrings.cardCalendarTitle,
                description: AppStrings.cardCalendarDesc,
                icon: Icons.calendar_month_outlined,
                onTap: () => onNavigateToTab(2),
              ),
              const SizedBox(height: 12),
              AppCard(
                title: AppStrings.cardContentsTitle,
                description: AppStrings.cardContentsDesc,
                icon: Icons.menu_book_outlined,
                onTap: () => onNavigateToTab(3),
              ),
              const SizedBox(height: 12),
              AppCard(
                title: AppStrings.cardReplanningTitle,
                description: AppStrings.cardReplanningDesc,
                icon: Icons.auto_mode_outlined,
                badgeText: 'Determinístico',
                onTap: () => onNavigateToTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
