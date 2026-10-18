import 'package:app/core/theme/app_colors.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:flutter/material.dart';

/// Badge semântico para exibição do status de aulas e planejamentos.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final LessonExecutionStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color background, Color foreground) = switch (status) {
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
