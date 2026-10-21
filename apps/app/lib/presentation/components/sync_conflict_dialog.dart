import 'dart:convert';

import 'package:app/core/localization/app_strings.dart';
import 'package:app/infrastructure/sync/models/operation_ack_dto.dart';
import 'package:flutter/material.dart';

/// Diálogo de apresentação de conflitos de sincronização.
///
/// Apresenta com transparência pedagógica os motivos do conflito e as versões
/// em disputa (servidor vs. local), respeitando a regra inviolável do Guia de Ensino:
/// nenhum dado local é descartado ou sobrescrito silenciosamente por automação.
class SyncConflictDialog extends StatelessWidget {
  const SyncConflictDialog({super.key, required this.conflicts});

  /// Lista de detalhes de conflitos retornados pelo ciclo de sincronização.
  final List<ConflictDetailsDto> conflicts;

  /// Exibe o diálogo na árvore de navegação atual.
  static Future<void> show(
    BuildContext context, {
    required List<ConflictDetailsDto> conflicts,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => SyncConflictDialog(conflicts: conflicts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.error,
        size: 32,
      ),
      title: const Text(
        AppStrings.syncConflictDialogTitle,
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner informativo sobre preservação de dados
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withAlpha(120)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.syncConflictPreservationNotice,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Identificamos ${conflicts.length} conflito(s) entre alterações no servidor e modificações no seu dispositivo:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              // Lista de Conflitos
              ...conflicts.map(
                (conflict) => _buildConflictCard(context, conflict),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.understandButton),
        ),
      ],
    );
  }

  Widget _buildConflictCard(BuildContext context, ConflictDetailsDto conflict) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const encoder = JsonEncoder.withIndent('  ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync_problem_outlined,
                  size: 18,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.syncConflictReasonLabel} ${conflict.reason}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            if (conflict.clientVersion != null) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.syncConflictClientVersionLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  encoder.convert(conflict.clientVersion),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            if (conflict.serverVersion != null) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.syncConflictServerVersionLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  encoder.convert(conflict.serverVersion),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
