import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/usecases/record_lesson_execution_usecase.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:flutter/material.dart';

/// Diálogo modal interativo para registro inicial e retificação pedagógica
/// do diário de classe fático de uma aula planejada.
class RecordLessonDialog extends StatefulWidget {
  const RecordLessonDialog({
    super.key,
    required this.plannedLesson,
    required this.classroomSubjectId,
    required this.classroomName,
    required this.subjectName,
    this.executionRecord,
    this.initialAvailableContents,
    this.courseContentRepository,
    this.recordLessonExecutionUseCase,
  });

  final PlannedLesson plannedLesson;
  final String classroomSubjectId;
  final String classroomName;
  final String subjectName;
  final LessonExecutionRecord? executionRecord;
  final List<CourseContent>? initialAvailableContents;
  final CourseContentRepository? courseContentRepository;
  final RecordLessonExecutionUseCase? recordLessonExecutionUseCase;

  @override
  State<RecordLessonDialog> createState() => _RecordLessonDialogState();
}

class _RecordLessonDialogState extends State<RecordLessonDialog> {
  late LessonExecutionStatus _status;
  late Set<String> _selectedContentIds;
  LessonCancellationReason? _cancellationReason;
  late final TextEditingController _cancellationDetailsController;
  late final TextEditingController _pedagogicalNotesController;
  late bool _needsFollowUp;
  late final TextEditingController _followUpNotesController;

  bool _isSaving = false;
  String? _errorMessage;

  bool _isLoadingContents = false;
  String? _contentsError;
  List<CourseContent> _availableContents = const [];

  bool get _isRectification => widget.executionRecord != null;

  @override
  void initState() {
    super.initState();

    final record = widget.executionRecord;
    if (record != null) {
      _status = record.status;
      _selectedContentIds = Set<String>.from(record.actualContentIds);
      _cancellationReason = record.cancellationReason;
      _cancellationDetailsController = TextEditingController(
        text: record.cancellationDetails ?? '',
      );
      _pedagogicalNotesController = TextEditingController(
        text: record.pedagogicalNotes ?? '',
      );
      _needsFollowUp = record.needsFollowUp;
      _followUpNotesController = TextEditingController(
        text: record.followUpNotes ?? '',
      );
    } else {
      _status = LessonExecutionStatus.completed;
      // Pré-seleciona como sugestão editável os conteúdos planejados
      _selectedContentIds = Set<String>.from(widget.plannedLesson.contentIds);
      _cancellationReason = null;
      _cancellationDetailsController = TextEditingController();
      _pedagogicalNotesController = TextEditingController();
      _needsFollowUp = false;
      _followUpNotesController = TextEditingController();
    }

    if (widget.initialAvailableContents != null) {
      _availableContents = widget.initialAvailableContents!;
      _isLoadingContents = false;
    } else {
      _isLoadingContents = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAvailableContents();
      });
    }
  }

  @override
  void dispose() {
    _cancellationDetailsController.dispose();
    _pedagogicalNotesController.dispose();
    _followUpNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableContents() async {
    if (!mounted) return;
    setState(() {
      _isLoadingContents = true;
      _contentsError = null;
    });

    try {
      final repo =
          widget.courseContentRepository ??
          AppDependencyScope.of(context).courseContentRepository;
      final contents = await repo.getByClassroomSubject(
        widget.classroomSubjectId,
      );
      if (!mounted) return;
      setState(() {
        _availableContents = contents;
        _isLoadingContents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contentsError = e.toString();
        _isLoadingContents = false;
      });
    }
  }

  void _onStatusChanged(LessonExecutionStatus newStatus) {
    if (_status == newStatus) return;
    setState(() {
      _status = newStatus;
      _errorMessage = null;

      // Se a aula não foi realizada, limpa a seleção de conteúdos
      if (_status == LessonExecutionStatus.notHeld) {
        _selectedContentIds.clear();
      }
    });
  }

  void _quickSelectPlannedContents() {
    setState(() {
      _selectedContentIds = Set<String>.from(widget.plannedLesson.contentIds);
      _errorMessage = null;
    });
  }

  void _quickClearContents() {
    setState(() {
      _selectedContentIds.clear();
      _errorMessage = null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Segunda-feira';
      case DateTime.tuesday:
        return 'Terça-feira';
      case DateTime.wednesday:
        return 'Quarta-feira';
      case DateTime.thursday:
        return 'Quinta-feira';
      case DateTime.friday:
        return 'Sexta-feira';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return '';
    }
  }

  Future<void> _saveRecord() async {
    if (_isSaving) return;

    // 1. Validações reativas na interface antes da submissão
    if (_status == LessonExecutionStatus.notHeld) {
      if (_cancellationReason == null) {
        setState(() {
          _errorMessage = AppStrings.validationNotHeldReasonRequired;
        });
        return;
      }
      if (_selectedContentIds.isNotEmpty) {
        setState(() {
          _errorMessage = AppStrings.validationNotHeldContentsForbidden;
        });
        return;
      }
    }

    if (_status == LessonExecutionStatus.partiallyCompleted) {
      final hasContents = _selectedContentIds.isNotEmpty;
      final hasNotes = _pedagogicalNotesController.text.trim().isNotEmpty;
      final hasFollowUp = _needsFollowUp;

      if (!hasContents && !hasNotes && !hasFollowUp) {
        setState(() {
          _errorMessage = AppStrings.validationPartialLessonRequired;
        });
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final useCase =
          widget.recordLessonExecutionUseCase ??
          AppDependencyScope.of(context).recordLessonExecutionUseCase;

      final params = RecordLessonExecutionParams(
        plannedLessonId: widget.plannedLesson.id,
        classroomSubjectId: widget.classroomSubjectId,
        executionDate: widget.plannedLesson.date,
        status: _status,
        actualContentIds: _status == LessonExecutionStatus.notHeld
            ? const []
            : _selectedContentIds.toList(),
        cancellationReason: _status == LessonExecutionStatus.notHeld
            ? _cancellationReason
            : null,
        cancellationDetails:
            _status == LessonExecutionStatus.notHeld &&
                _cancellationDetailsController.text.trim().isNotEmpty
            ? _cancellationDetailsController.text.trim()
            : null,
        pedagogicalNotes: _pedagogicalNotesController.text.trim().isNotEmpty
            ? _pedagogicalNotesController.text.trim()
            : null,
        needsFollowUp: _needsFollowUp,
        followUpNotes:
            _needsFollowUp && _followUpNotesController.text.trim().isNotEmpty
            ? _followUpNotesController.text.trim()
            : null,
      );

      await useCase.execute(params);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on LessonExecutionValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    } on LessonExecutionIntegrityException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Erro ao salvar apontamento: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lesson = widget.plannedLesson;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isRectification ? Icons.edit_note : Icons.assignment_add,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRectification
                              ? AppStrings.rectifyLessonDialogTitle
                              : AppStrings.recordLessonDialogTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.classroomName} • ${widget.subjectName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_formatDate(lesson.date)} • ${_weekdayName(lesson.date.weekday)} • ${lesson.orderInDay}ª aula',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: AppStrings.closeButton,
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Corpo do Formulário com Rolagem
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner de erro, caso exista
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.error),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 1. Situação da Aula (SegmentedButton)
                      Text(
                        AppStrings.lessonStatusSectionLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final button = SegmentedButton<LessonExecutionStatus>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            segments: const [
                              ButtonSegment(
                                value: LessonExecutionStatus.completed,
                                label: Text(AppStrings.statusCompletedOption),
                                icon: Icon(Icons.check_circle_outline),
                              ),
                              ButtonSegment(
                                value: LessonExecutionStatus.partiallyCompleted,
                                label: Text(
                                  AppStrings.statusPartiallyCompletedOption,
                                ),
                                icon: Icon(Icons.timelapse),
                              ),
                              ButtonSegment(
                                value: LessonExecutionStatus.notHeld,
                                label: Text(AppStrings.statusNotHeldOption),
                                icon: Icon(Icons.cancel_outlined),
                              ),
                            ],
                            selected: {_status},
                            onSelectionChanged: (newSelection) {
                              _onStatusChanged(newSelection.first);
                            },
                          );

                          if (constraints.maxWidth < 380) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: button,
                            );
                          }
                          return button;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Seção de Conteúdos Ministrados (oculta/desabilitada se notHeld)
                      if (_status != LessonExecutionStatus.notHeld) ...[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              AppStrings.contentsTaughtSectionLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _quickSelectPlannedContents,
                              icon: const Icon(Icons.bookmark_added, size: 14),
                              label: const Text(
                                AppStrings.selectPlannedContentsQuickAction,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _quickClearContents,
                              icon: const Icon(Icons.clear_all, size: 14),
                              label: const Text(
                                AppStrings.clearSelectedContentsQuickAction,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildContentsSection(theme, colorScheme),
                        const SizedBox(height: 18),
                      ] else ...[
                        // Mensagem de aviso para aula não realizada
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.notHeldNoContentsNotice,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Motivo do Cancelamento
                        DropdownButtonFormField<LessonCancellationReason>(
                          initialValue: _cancellationReason,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText:
                                '${AppStrings.cancellationReasonLabel} *',
                            hintText: AppStrings.selectCancellationReasonHint,
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: LessonCancellationReason.values.map((reason) {
                            return DropdownMenuItem(
                              value: reason,
                              child: Text(reason.label),
                            );
                          }).toList(),
                          onChanged: (reason) {
                            setState(() {
                              _cancellationReason = reason;
                              _errorMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Detalhes do Cancelamento (opcional)
                        TextFormField(
                          controller: _cancellationDetailsController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: AppStrings.cancellationDetailsLabel,
                            hintText: AppStrings.cancellationDetailsHint,
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 3. Observações Pedagógicas (opcional)
                      TextFormField(
                        controller: _pedagogicalNotesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: AppStrings.pedagogicalNotesLabel,
                          hintText: AppStrings.pedagogicalNotesHint,
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Continuidade Pedagógica
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          AppStrings.needsFollowUpLabel,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        value: _needsFollowUp,
                        onChanged: (val) {
                          setState(() {
                            _needsFollowUp = val ?? false;
                            _errorMessage = null;
                          });
                        },
                      ),
                      if (_needsFollowUp) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _followUpNotesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: AppStrings.followUpNotesLabel,
                            hintText: AppStrings.followUpNotesHint,
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Rodapé com Ações
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text(AppStrings.cancelButton),
                  ),
                  AppButton(
                    label: AppStrings.saveRecordButton,
                    icon: Icons.save,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveRecord,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentsSection(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingContents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_contentsError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.error.withAlpha(100)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.loadingContentsError,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _contentsError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadAvailableContents,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(AppStrings.retryButton),
            ),
          ],
        ),
      );
    }

    if (_availableContents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
        ),
        child: Text(
          AppStrings.noContentsForClassroomSubject,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _availableContents.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: colorScheme.outlineVariant.withAlpha(50),
          ),
          itemBuilder: (context, index) {
            final content = _availableContents[index];
            final isSelected = _selectedContentIds.contains(content.id);
            final isPlanned = widget.plannedLesson.contentIds.contains(
              content.id,
            );

            return CheckboxListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              value: isSelected,
              title: Text(
                content.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isPlanned ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: isPlanned
                  ? Text(
                      AppStrings.plannedContentBadge,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedContentIds.add(content.id);
                  } else {
                    _selectedContentIds.remove(content.id);
                  }
                  _errorMessage = null;
                });
              },
            );
          },
        ),
      ),
    );
  }
}
