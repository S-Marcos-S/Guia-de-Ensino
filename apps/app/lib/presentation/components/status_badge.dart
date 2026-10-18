import 'package:app/core/theme/app_colors.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:flutter/material.dart';

/// Badge semântico para exibição do status de aulas, calendários e turmas.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status})
    : customLabel = null,
      customBackground = null,
      customForeground = null;

  const StatusBadge.custom({
    super.key,
    required String label,
    Color? background,
    Color? foreground,
  }) : status = null,
       customLabel = label,
       customBackground = background,
       customForeground = foreground;

  final LessonExecutionStatus? status;
  final String? customLabel;
  final Color? customBackground;
  final Color? customForeground;

  @override
  Widget build(BuildContext context) {
    if (status != null) {
      final (
        String label,
        Color background,
        Color foreground,
      ) = switch (status!) {
        LessonExecutionStatus.planned => (
          'Prevista',
          AppColors.primaryContainerLight,
          AppColors.primaryLight,
        ),
        LessonExecutionStatus.completed => (
          'Realizada',
          AppColors.secondaryContainerLight,
          AppColors.success,
        ),
        LessonExecutionStatus.partiallyCompleted => (
          'Parcial',
          AppColors.tertiaryContainerLight,
          AppColors.warning,
        ),
        LessonExecutionStatus.notHeld => (
          'Não Realizada',
          const Color(0xFFFEE2E2),
          AppColors.error,
        ),
      };

      return _buildContainer(label, background, foreground);
    }

    final theme = Theme.of(context);
    final bg = customBackground ?? theme.colorScheme.surfaceContainerHighest;
    final fg = customForeground ?? theme.colorScheme.onSurface;

    return _buildContainer(customLabel ?? '', bg, fg);
  }

  Widget _buildContainer(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
