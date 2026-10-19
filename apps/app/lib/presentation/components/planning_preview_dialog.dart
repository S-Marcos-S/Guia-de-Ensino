import 'package:app/core/di/app_dependencies.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:app/presentation/components/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal para exibição prévia, explicabilidade e homologação
/// do plano de aulas gerado pelo Motor Determinístico de Planejamento.
class PlanningPreviewDialog extends StatefulWidget {
  const PlanningPreviewDialog({
    super.key,
    required this.classroomName,
    required this.subjectName,
    required this.result,
    required this.onPlanApplied,
  });

  final String classroomName;
  final String subjectName;
  final PlanningEngineResult result;
  final VoidCallback onPlanApplied;

  @override
  State<PlanningPreviewDialog> createState() => _PlanningPreviewDialogState();
}

class _PlanningPreviewDialogState extends State<PlanningPreviewDialog> {
  bool _isApplying = false;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  bool get _hasFatalConflicts => widget.result.conflicts.any(
    (c) => c.type != PlanningConflictType.insufficientCapacity,
  );

  Future<void> _applyPlan() async {
    setState(() => _isApplying = true);
    try {
      final deps = AppDependencyScope.of(context);
      await deps.generateSchedulePlanUseCase.applyPlan(widget.result);

      if (mounted) {
        Navigator.pop(context);
        widget.onPlanApplied();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Planejamento de aulas homologado e salvo com sucesso!',
            ),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar planejamento: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final r = widget.result;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distribuição de Aulas Planejadas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.classroomName} • ${widget.subjectName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Painel de Resumo e Capacidade
              _buildCapacitySummary(context),
              const SizedBox(height: 16),

              // Alertas de Conflito e Déficit
              if (r.conflicts.isNotEmpty) ...[
                _buildConflictsView(context),
                const SizedBox(height: 16),
              ],

              // Título da Lista
              Text(
                'Alocação dos Conteúdos (${r.contentAllocations.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Lista de conteúdos e datas
              Expanded(
                child: r.contentAllocations.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum conteúdo a alocar.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: r.contentAllocations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final alloc = r.contentAllocations[index];
                          return _buildContentItem(context, alloc);
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // Rodapé com botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isApplying
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: _isApplying
                        ? 'Homologando...'
                        : 'Homologar e Salvar Plano',
                    icon: Icons.check_circle_outline,
                    onPressed: _hasFatalConflicts || _isApplying
                        ? null
                        : _applyPlan,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapacitySummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final r = widget.result;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetric(
              context,
              label: 'Disponíveis',
              value: '${r.availableLessonOccurrences}',
              icon: Icons.event_available,
              color: colorScheme.primary,
            ),
          ),
          Expanded(
            child: _buildMetric(
              context,
              label: 'Utilizadas',
              value: '${r.usedLessonOccurrences}',
              icon: Icons.calendar_today,
              color: const Color(0xFF2E7D32),
            ),
          ),
          Expanded(
            child: _buildMetric(
              context,
              label: 'Déficit',
              value: '${r.lessonDeficit}',
              icon: r.lessonDeficit > 0
                  ? Icons.warning_amber
                  : Icons.check_circle,
              color: r.lessonDeficit > 0
                  ? const Color(0xFFC62828)
                  : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConflictsView(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.result;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasFatalConflicts
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasFatalConflicts
              ? const Color(0xFFEF5350)
              : const Color(0xFFFFCA28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasFatalConflicts ? Icons.error_outline : Icons.warning_amber,
                color: _hasFatalConflicts
                    ? const Color(0xFFC62828)
                    : const Color(0xFFF57F17),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _hasFatalConflicts
                    ? 'Conflitos Impeditivos'
                    : 'Aviso de Insuficiência de Carga Horária',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _hasFatalConflicts
                      ? const Color(0xFFC62828)
                      : const Color(0xFFF57F17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...r.conflicts.map(
            (c) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• ${c.message}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _hasFatalConflicts
                      ? const Color(0xFFB71C1C)
                      : const Color(0xFFE65100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentItem(
    BuildContext context,
    ContentAllocationStatus alloc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final c = alloc.content;

    final datesText = alloc.allocatedDates.isEmpty
        ? 'Nenhuma aula alocada'
        : alloc.allocatedDates.map((d) => _dateFormat.format(d)).join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alloc.isFullyAllocated
              ? colorScheme.outlineVariant
              : const Color(0xFFFFCC80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge.custom(
                label: alloc.isFullyAllocated
                    ? '${alloc.allocatedLessons}/${alloc.requiredLessons} aulas'
                    : '${alloc.allocatedLessons}/${alloc.requiredLessons} aulas (déficit)',
                background: alloc.isFullyAllocated
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                foreground: alloc.isFullyAllocated
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE65100),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Datas: $datesText',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (alloc.reasonNotFullyAllocated != null) ...[
            const SizedBox(height: 4),
            Text(
              alloc.reasonNotFullyAllocated!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFC62828),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
