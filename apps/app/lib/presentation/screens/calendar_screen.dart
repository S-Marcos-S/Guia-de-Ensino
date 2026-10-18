import 'package:app/core/localization/app_strings.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:flutter/material.dart';

/// Tela de Calendário Escolar e Dias Letivos.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

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
                title: AppStrings.cardCalendarTitle,
                subtitle: AppStrings.cardCalendarDesc,
              ),
              Expanded(
                child: EmptyStateView(
                  title: AppStrings.emptyCalendarTitle,
                  description: AppStrings.emptyCalendarDesc,
                  icon: Icons.calendar_month_outlined,
                  actionLabel: 'Saiba Mais',
                  onActionPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'O motor de calendário escolar será implementado na Etapa 3 e 5.',
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
