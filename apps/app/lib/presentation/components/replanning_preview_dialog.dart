import 'package:app/core/di/app_dependencies.dart';
import 'package:app/domain/models/replanning_models.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:app/presentation/components/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal comparativo para visualização explicável "Antes vs. Depois",
/// revisão e homologação da proposta de replanejamento pelo professor.
class ReplanningPreviewDialog extends StatefulWidget {
  const ReplanningPreviewDialog({
    super.key,
    required this.classroomName,
    required this.subjectName,
    required this.proposal,
    required this.onPlanApplied,
  });

  final String classroomName;
  final String subjectName;
  final ReplanningProposal proposal;
  final VoidCallback onPlanApplied;

  @override
  State<ReplanningPreviewDialog> createState() =>
      _ReplanningPreviewDialogState();
}

class _ReplanningPreviewDialogState extends State<ReplanningPreviewDialog> {
  bool _isApplying = false;
  int _selectedScenarioIndex = 0;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _applyProposal() async {
    setState(() => _isApplying = true);
    try {
      final deps = AppDependencyScope.of(context);
      await deps.applyReplanningProposalUseCase.execute(widget.proposal);

      if (mounted) {
        Navigator.pop(context);
        widget.onPlanApplied();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Replanejamento homologado e aplicado com sucesso! Histórico preservado.',
            ),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } on OutdatedReplanningProposalException catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao homologar replanejamento: $e'),
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
    final prop = widget.proposal;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Proposta de Replanejamento',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (prop.capacityAnalysis != null)
                              StatusBadge.custom(
                                label: prop
                                    .capacityAnalysis!
                                    .viabilityStatus
                                    .displayName,
                                background: _getViabilityBackground(
                                  prop.capacityAnalysis!.viabilityStatus,
                                ),
                                foreground: _getViabilityForeground(
                                  prop.capacityAnalysis!.viabilityStatus,
                                ),
                              )
                            else if (prop.isIdenticalToCurrentPlan)
                              StatusBadge.custom(
                                label: 'Em Dia',
                                background: const Color(0xFFE8F5E9),
                                foreground: const Color(0xFF2E7D32),
                              )
                            else
                              StatusBadge.custom(
                                label: 'Ajuste Necessário',
                                background: const Color(0xFFFFF3E0),
                                foreground: const Color(0xFFE65100),
                              ),
                          ],
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
                    onPressed: _isApplying
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Painel de Métricas e Capacidade
              _buildMetricsPanel(context),
              const SizedBox(height: 8),

              // Card de Viabilidade Curricular e Ritmo de Ensino
              if (prop.capacityAnalysis != null) ...[
                _buildViabilityCard(context),
                const SizedBox(height: 8),
              ],

              // Seletor de Cenários de Recuperação
              if (prop.recoveryScenarios.isNotEmpty) ...[
                _buildScenariosSelector(context),
                const SizedBox(height: 8),
              ],

              // Alertas de Conflito e Déficit
              if (prop.planningResult.conflicts.isNotEmpty) ...[
                _buildConflictsView(context),
                const SizedBox(height: 8),
              ],

              // Explicações estruturadas
              if (prop.explanations.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: prop.explanations.map((exp) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          exp,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Título da Lista
              Text(
                'Comparativo de Aulas (\'Antes\' vs. \'Depois\')',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              // Lista Comparativa
              Expanded(
                child: prop.shifts.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma aula afetada.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: prop.shifts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final shift = prop.shifts[index];
                          return _buildShiftCard(context, shift);
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Rodapé com ações explícitas (Rejeitar vs Homologar)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isApplying
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Rejeitar e Descartar'),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: _isApplying
                        ? 'Aplicando Replanejamento...'
                        : 'Homologar e Aplicar',
                    icon: Icons.check_circle_outline,
                    onPressed: prop.hasFatalConflicts || _isApplying
                        ? null
                        : _applyProposal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prop = widget.proposal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              context,
              label: 'Histórico Intacto',
              value: '${prop.preservedHistoricLessonsCount}',
              icon: Icons.history,
              color: const Color(0xFF2E7D32),
            ),
          ),
          Expanded(
            child: _buildMetricItem(
              context,
              label: 'Bloqueadas',
              value: '${prop.preservedLockedLessonsCount}',
              icon: Icons.lock_outline,
              color: const Color(0xFF5D4037),
            ),
          ),
          Expanded(
            child: _buildMetricItem(
              context,
              label: 'Reprogramadas',
              value: '${prop.affectedFutureLessonsCount}',
              icon: Icons.update,
              color: prop.affectedFutureLessonsCount > 0
                  ? const Color(0xFFE65100)
                  : colorScheme.primary,
            ),
          ),
          Expanded(
            child: _buildMetricItem(
              context,
              label: 'Déficit',
              value: '${prop.lessonDeficit}',
              icon: prop.lessonDeficit > 0
                  ? Icons.warning_amber
                  : Icons.check_circle_outline,
              color: prop.lessonDeficit > 0
                  ? const Color(0xFFC62828)
                  : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
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
    final prop = widget.proposal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: prop.hasFatalConflicts
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: prop.hasFatalConflicts
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
                prop.hasFatalConflicts
                    ? Icons.error_outline
                    : Icons.warning_amber,
                color: prop.hasFatalConflicts
                    ? const Color(0xFFC62828)
                    : const Color(0xFFF57F17),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                prop.hasFatalConflicts
                    ? 'Conflitos Impeditivos'
                    : 'Aviso de Déficit de Carga Horária',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: prop.hasFatalConflicts
                      ? const Color(0xFFC62828)
                      : const Color(0xFFF57F17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...prop.planningResult.conflicts.map(
            (c) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• ${c.message}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: prop.hasFatalConflicts
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

  Widget _buildViabilityCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final analysis = widget.proposal.capacityAnalysis!;
    final pace = widget.proposal.paceAnalysis;

    final atRiskContents = analysis.contentsAtRisk
        .where((c) => c.isAtRisk)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analysis.capacityDeficit > 0
            ? const Color(0xFFFFF3E0)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: analysis.capacityDeficit > 0
              ? const Color(0xFFFFB74D)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                analysis.capacityDeficit > 0
                    ? Icons.event_busy
                    : Icons.event_available,
                size: 18,
                color: analysis.capacityDeficit > 0
                    ? const Color(0xFFE65100)
                    : const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Projeção de Viabilidade Curricular',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Término: ${_dateFormat.format(analysis.academicYearEndDate)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            analysis.summaryMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: analysis.capacityDeficit > 0
                  ? const Color(0xFF5D4037)
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  context,
                  label: 'Vagas Livres',
                  value: '${analysis.totalFutureAvailableSlots}',
                  icon: Icons.event_seat_outlined,
                  color: colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  context,
                  label: 'Demanda Restante',
                  value: '${analysis.totalRemainingDemandLessons} aulas',
                  icon: Icons.menu_book_outlined,
                  color: colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  context,
                  label: analysis.capacityDeficit > 0 ? 'Déficit' : 'Folga',
                  value: analysis.capacityDeficit > 0
                      ? '-${analysis.capacityDeficit} aulas'
                      : '+${analysis.safetyMarginLessons} vagas',
                  icon: analysis.capacityDeficit > 0
                      ? Icons.trending_down
                      : Icons.trending_up,
                  color: analysis.capacityDeficit > 0
                      ? const Color(0xFFC62828)
                      : const Color(0xFF2E7D32),
                ),
              ),
              if (analysis.estimatedCompletionDate != null)
                Expanded(
                  child: _buildMiniStat(
                    context,
                    label: 'Conclusão Estimada',
                    value: _dateFormat.format(
                      analysis.estimatedCompletionDate!,
                    ),
                    icon: Icons.flag_outlined,
                    color: analysis.overflowsAcademicYear
                        ? const Color(0xFFC62828)
                        : const Color(0xFF2E7D32),
                  ),
                ),
            ],
          ),
          if (pace != null && pace.hasSufficientHistoricalData) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.speed, size: 14, color: Color(0xFF1565C0)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ritmo de ensino observado: ${pace.observedPaceRatio.toStringAsFixed(1)} aulas gastas por aula estimada nos conteúdos já iniciados.'
                    '${pace.projectedAdditionalLessonsIfPaceMaintained > 0 ? ' Se mantido, projetará +${pace.projectedAdditionalLessonsIfPaceMaintained} aula(s).' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF0D47A1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (atRiskContents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 14,
                        color: Color(0xFFC62828),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Conteúdos em Risco de Não Conclusão (${atRiskContents.length}):',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...atRiskContents.map((risk) {
                    return Text(
                      '• ${risk.content.title}: faltam ${risk.missingLessons} aula(s). ${risk.riskReason}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFB71C1C),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScenariosSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scenarios = widget.proposal.recoveryScenarios;
    if (scenarios.isEmpty) return const SizedBox.shrink();

    final selected =
        scenarios[_selectedScenarioIndex.clamp(0, scenarios.length - 1)];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, size: 16),
              const SizedBox(width: 6),
              Text(
                'Cenários de Recuperação Curricular',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(scenarios.length, (idx) {
                final sc = scenarios[idx];
                final isSelected = idx == _selectedScenarioIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(sc.title),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedScenarioIndex = idx);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Premissas: ${selected.hypothesis}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (selected.extraLessonsNeeded > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Aulas adicionais necessárias para zerar déficit: ${selected.extraLessonsNeeded} aula(s).',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (selected.unallocatedContentTitles.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Conteúdos não alocados neste cenário: ${selected.unallocatedContentTitles.join(', ')}.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getViabilityBackground(CurricularViabilityStatus? status) {
    switch (status) {
      case CurricularViabilityStatus.viable:
        return const Color(0xFFE8F5E9);
      case CurricularViabilityStatus.viableWithAdjustments:
        return const Color(0xFFE1F5FE);
      case CurricularViabilityStatus.atRisk:
        return const Color(0xFFFFF3E0);
      case CurricularViabilityStatus.unfeasible:
        return const Color(0xFFFFEBEE);
      case CurricularViabilityStatus.indeterminate:
      default:
        return const Color(0xFFECEFF1);
    }
  }

  Color _getViabilityForeground(CurricularViabilityStatus? status) {
    switch (status) {
      case CurricularViabilityStatus.viable:
        return const Color(0xFF2E7D32);
      case CurricularViabilityStatus.viableWithAdjustments:
        return const Color(0xFF0277BD);
      case CurricularViabilityStatus.atRisk:
        return const Color(0xFFE65100);
      case CurricularViabilityStatus.unfeasible:
        return const Color(0xFFC62828);
      case CurricularViabilityStatus.indeterminate:
      default:
        return const Color(0xFF455A64);
    }
  }

  Widget _buildShiftCard(BuildContext context, LessonReplanningShift shift) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final origDateStr = _dateFormat.format(shift.originalDate);
    final propDateStr = _dateFormat.format(shift.proposedDate);
    final origContentStr = shift.originalContentTitles.join(', ');
    final propContentStr = shift.proposedContentTitles.join(', ');

    final Color badgeBg;
    final Color badgeFg;
    final String badgeLabel;

    if (shift.isPreservedHistoric) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeFg = const Color(0xFF2E7D32);
      badgeLabel = 'Histórico Preservado';
    } else if (shift.isLocked) {
      badgeBg = const Color(0xFFEFEBE9);
      badgeFg = const Color(0xFF4E342E);
      badgeLabel = 'Bloqueada';
    } else {
      switch (shift.shiftType) {
        case LessonReplanningShiftType.unchanged:
          badgeBg = colorScheme.surfaceContainerHighest;
          badgeFg = colorScheme.onSurfaceVariant;
          badgeLabel = 'Sem Alteração';
          break;
        case LessonReplanningShiftType.rescheduledDate:
          badgeBg = const Color(0xFFE3F2FD);
          badgeFg = const Color(0xFF1565C0);
          badgeLabel = 'Data Remanejada';
          break;
        case LessonReplanningShiftType.reallocatedContent:
          badgeBg = const Color(0xFFFFF3E0);
          badgeFg = const Color(0xFFE65100);
          badgeLabel = 'Conteúdo Remanejado';
          break;
        case LessonReplanningShiftType.rescheduledDateAndContent:
          badgeBg = const Color(0xFFEDE7F6);
          badgeFg = const Color(0xFF512DA8);
          badgeLabel = 'Data e Conteúdo';
          break;
        case LessonReplanningShiftType.newlyAdded:
          badgeBg = const Color(0xFFE0F2F1);
          badgeFg = const Color(0xFF00695C);
          badgeLabel = 'Nova Aula';
          break;
        case LessonReplanningShiftType.removed:
          badgeBg = const Color(0xFFFFEBEE);
          badgeFg = const Color(0xFFC62828);
          badgeLabel = 'Liberada';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: shift.shiftType != LessonReplanningShiftType.unchanged
              ? colorScheme.outline
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.custom(
                label: badgeLabel,
                background: badgeBg,
                foreground: badgeFg,
              ),
              const Spacer(),
              if (shift.hasDateChanged)
                Text(
                  '$origDateStr (${shift.originalOrderInDay}ª) ➔ $propDateStr (${shift.proposedOrderInDay}ª)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                )
              else
                Text(
                  '$propDateStr (${shift.proposedOrderInDay}ª aula)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (shift.hasContentChanged && origContentStr.isNotEmpty) ...[
            Text(
              'Antes: ${origContentStr.isNotEmpty ? origContentStr : 'Sem conteúdo'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Depois: ${propContentStr.isNotEmpty ? propContentStr : 'Sem conteúdo'}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              propContentStr.isNotEmpty
                  ? propContentStr
                  : 'Sem conteúdo vinculado',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            shift.reason,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
