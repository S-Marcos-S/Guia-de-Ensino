import 'package:app/core/localization/app_strings.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:flutter/material.dart';

/// Tela de Conteúdos Programáticos e Referências Curriculares (BNCC).
class ContentsScreen extends StatelessWidget {
  const ContentsScreen({super.key});

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
                title: AppStrings.cardContentsTitle,
                subtitle: AppStrings.cardContentsDesc,
              ),
              Expanded(
                child: EmptyStateView(
                  title: AppStrings.emptyContentsTitle,
                  description: AppStrings.emptyContentsDesc,
                  icon: Icons.menu_book_outlined,
                  actionLabel: 'Saiba Mais',
                  onActionPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'A base curricular e importação serão integradas na Etapa 4.',
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
