import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/domain/usecases/get_classroom_subject_lessons_usecase.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:app/presentation/components/record_lesson_dialog.dart';
import 'package:app/presentation/components/status_badge.dart';
import 'package:app/presentation/screens/replanning_screen.dart';
import 'package:flutter/material.dart';

/// Filtro temporal de consulta de aulas.
enum LessonFilter { all, past, today, future }

/// Tela de consulta cronológica das aulas planejadas e executadas por turma e disciplina.
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({
    super.key,
    this.initialClassroomId,
    this.initialClassroomSubjectId,
  });

  final String? initialClassroomId;
  final String? initialClassroomSubjectId;

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  AcademicYear? _activeYear;
  List<Classroom> _classrooms = [];
  Classroom? _selectedClassroom;
  ClassroomSubjectConfig? _selectedClassroomSubject;
  Map<String, Subject> _subjectsMap = {};

  List<ClassroomSubjectLessonItem> _lessons = [];
  LessonFilter _selectedFilter = LessonFilter.all;

  bool _isInitializing = true;
  bool _isLoadingLessons = false;
  String? _errorMessage;
  int _activeLoadRequestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitializing) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final deps = AppDependencyScope.of(context);

    final years = await deps.academicYearRepository.getAll();
    if (years.isEmpty) {
      if (mounted) {
        setState(() {
          _activeYear = null;
          _isInitializing = false;
        });
      }
      return;
    }

    final year = years.first;
    final classrooms = await deps.classroomRepository.getByAcademicYear(
      year.id,
    );
    final subjects = await deps.subjectRepository.getAll();
    final subjectMap = {for (final s in subjects) s.id: s};

    // Resolução da turma inicial
    Classroom? defaultClassroom;
    if (widget.initialClassroomId != null) {
      defaultClassroom = classrooms
          .where((c) => c.id == widget.initialClassroomId)
          .firstOrNull;
    }
    defaultClassroom ??= classrooms.isNotEmpty ? classrooms.first : null;

    // Resolução da disciplina da turma inicial
    ClassroomSubjectConfig? defaultClassroomSubject;
    if (defaultClassroom != null &&
        defaultClassroom.subjectConfigs.isNotEmpty) {
      if (widget.initialClassroomSubjectId != null) {
        defaultClassroomSubject = defaultClassroom.subjectConfigs
            .where((cs) => cs.id == widget.initialClassroomSubjectId)
            .firstOrNull;
      }
      defaultClassroomSubject ??= defaultClassroom.subjectConfigs.first;
    }

    if (mounted) {
      setState(() {
        _activeYear = year;
        _classrooms = classrooms;
        _subjectsMap = subjectMap;
        _selectedClassroom = defaultClassroom;
        _selectedClassroomSubject = defaultClassroomSubject;
        _isInitializing = false;
      });

      if (defaultClassroomSubject != null) {
        await _loadLessons(defaultClassroomSubject.id);
      }
    }
  }

  Future<void> _loadLessons(String classroomSubjectId) async {
    final requestId = ++_activeLoadRequestId;

    setState(() {
      _isLoadingLessons = true;
      _errorMessage = null;
      _lessons = [];
    });

    try {
      final deps = AppDependencyScope.of(context);
      final items = await deps.getClassroomSubjectLessonsUseCase.execute(
        classroomSubjectId: classroomSubjectId,
      );

      // Proteção estrita de concorrência: descarta se a tela foi desmontada
      // ou se outra consulta mais recente já foi solicitada pelo usuário.
      if (!mounted || requestId != _activeLoadRequestId) {
        return;
      }

      setState(() {
        _lessons = items;
        _isLoadingLessons = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted || requestId != _activeLoadRequestId) {
        return;
      }

      setState(() {
        _errorMessage = AppStrings.loadingLessonsError;
        _isLoadingLessons = false;
      });
    }
  }

  List<ClassroomSubjectLessonItem> get _filteredLessons {
    switch (_selectedFilter) {
      case LessonFilter.all:
        return _lessons;
      case LessonFilter.past:
        return _lessons
            .where((l) => l.temporalCategory == LessonTemporalCategory.past)
            .toList();
      case LessonFilter.today:
        return _lessons
            .where((l) => l.temporalCategory == LessonTemporalCategory.today)
            .toList();
      case LessonFilter.future:
        return _lessons
            .where((l) => l.temporalCategory == LessonTemporalCategory.future)
            .toList();
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.lessonsScreenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeYear == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.lessonsScreenTitle)),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: EmptyStateView(
              title: 'Ano Letivo Necessário',
              description: 'Antes de consultar aulas, configure o Ano Letivo na aba Calendário.',
              icon: Icons.calendar_month,
            ),
          ),
        ),
      );
    }

    if (_classrooms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.lessonsScreenTitle)),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: EmptyStateView(
              title: 'Nenhuma Turma Cadastrada',
              description: 'Cadastre turmas e vincule disciplinas para consultar o cronograma de aulas.',
              icon: Icons.people_outline,
            ),
          ),
        ),
      );
    }

    final filtered = _filteredLessons;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.lessonsScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.lessonsScreenSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              // Barra de seleção de Turma e Disciplina
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Seletor de Turma
                      Expanded(
                        child: DropdownButtonFormField<Classroom>(
                          key: ValueKey(_selectedClassroom?.id),
                          initialValue: _selectedClassroom,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: AppStrings.classroomSelectorLabel,
                            isDense: true,
                          ),
                          items: _classrooms.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newClassroom) {
                            if (newClassroom != null &&
                                newClassroom.id != _selectedClassroom?.id) {
                              setState(() {
                                _selectedClassroom = newClassroom;
                                _selectedClassroomSubject =
                                    newClassroom.subjectConfigs.isNotEmpty
                                    ? newClassroom.subjectConfigs.first
                                    : null;
                              });

                              if (_selectedClassroomSubject != null) {
                                _loadLessons(_selectedClassroomSubject!.id);
                              } else {
                                setState(() => _lessons = []);
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Seletor de Disciplina da Turma
                      Expanded(
                        child: DropdownButtonFormField<ClassroomSubjectConfig>(
                          key: ValueKey(
                            '${_selectedClassroom?.id}_${_selectedClassroomSubject?.id}',
                          ),
                          initialValue: _selectedClassroomSubject,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: AppStrings.subjectSelectorLabel,
                            isDense: true,
                          ),
                          items: (_selectedClassroom?.subjectConfigs ?? [])
                              .map<DropdownMenuItem<ClassroomSubjectConfig>>((
                                ClassroomSubjectConfig cs,
                              ) {
                                final name =
                                    _subjectsMap[cs.subjectId]?.name ??
                                    'Disciplina';
                                return DropdownMenuItem(
                                  value: cs,
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (newSubject) {
                            if (newSubject != null &&
                                newSubject.id !=
                                    _selectedClassroomSubject?.id) {
                              setState(() {
                                _selectedClassroomSubject = newSubject;
                              });
                              _loadLessons(newSubject.id);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Barra de filtros temporais
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<LessonFilter>(
                  segments: const [
                    ButtonSegment(
                      value: LessonFilter.all,
                      label: Text(AppStrings.filterAll),
                      icon: Icon(Icons.list_alt),
                    ),
                    ButtonSegment(
                      value: LessonFilter.past,
                      label: Text(AppStrings.filterPast),
                      icon: Icon(Icons.history),
                    ),
                    ButtonSegment(
                      value: LessonFilter.today,
                      label: Text(AppStrings.filterToday),
                      icon: Icon(Icons.today),
                    ),
                    ButtonSegment(
                      value: LessonFilter.future,
                      label: Text(AppStrings.filterFuture),
                      icon: Icon(Icons.event),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedFilter = newSelection.first;
                    });
                  },
                ),
              ),
              if (_lessons.any(
                (l) =>
                    l.effectiveStatus == LessonExecutionStatus.notHeld ||
                    (l.executionRecord?.needsFollowUp ?? false),
              )) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFE65100),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aulas não realizadas ou com continuidade pendente identificadas.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5D4037),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReplanningScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFFE65100),
                        ),
                        child: const Text('Replanejar'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Conteúdo principal (Carregando, Erro, Vazio ou Lista de Aulas)
              Expanded(child: _buildContent(context, filtered)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ClassroomSubjectLessonItem> filtered,
  ) {
    if (_isLoadingLessons) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_selectedClassroomSubject != null)
              AppButton(
                label: AppStrings.retryButton,
                icon: Icons.refresh,
                onPressed: () => _loadLessons(_selectedClassroomSubject!.id),
              ),
          ],
        ),
      );
    }

    if (_selectedClassroomSubject == null) {
      return const EmptyStateView(
        title: 'Nenhuma Disciplina Selecionada',
        description: AppStrings.selectClassroomAndSubjectPrompt,
        icon: Icons.menu_book_outlined,
      );
    }

    if (_lessons.isEmpty) {
      return const EmptyStateView(
        title: AppStrings.emptyLessonsTitle,
        description: 'Não há aulas cadastradas para esta turma e disciplina.',
        icon: Icons.event_busy,
      );
    }

    if (filtered.isEmpty) {
      return const EmptyStateView(
        title: AppStrings.emptyLessonsTitle,
        description: AppStrings.emptyLessonsDesc,
        icon: Icons.filter_alt_off,
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildLessonCard(context, item);
      },
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    ClassroomSubjectLessonItem item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lesson = item.plannedLesson;
    final record = item.executionRecord;

    final isToday = item.temporalCategory == LessonTemporalCategory.today;
    final isPastUnrecorded = item.isPastUnrecorded;

    // Borda e fundo com destaque visual para hoje e pendências passadas
    final Border border;
    final Color cardBackground;

    if (isToday) {
      border = Border.all(color: colorScheme.primary, width: 1.5);
      cardBackground = colorScheme.primaryContainer.withAlpha(40);
    } else if (isPastUnrecorded) {
      border = Border.all(color: Colors.amber.shade700, width: 1.2);
      cardBackground = Colors.amber.withAlpha(20);
    } else {
      border = Border.all(color: colorScheme.outlineVariant.withAlpha(80));
      cardBackground = colorScheme.surfaceContainerLow;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da aula: Data, dia da semana, ordem no dia e badges
          Row(
            children: [
              Icon(
                isToday ? Icons.today : Icons.calendar_today_outlined,
                size: 18,
                color: isToday
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatDate(lesson.date)} • ${_weekdayName(lesson.date.weekday)} • ${lesson.orderInDay}ª aula',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isToday) ...[
                const StatusBadge.custom(
                  label: AppStrings.badgeToday,
                  background: Color(0xFFEDE7F6),
                  foreground: Color(0xFF512DA8),
                ),
                const SizedBox(width: 6),
              ],
              _buildStatusBadge(item),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Seção 1: Conteúdos Planejados
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.menu_book,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.plannedContentsSectionLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (item.plannedContentTitles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.plannedContentTitles
                    .map(
                      (title) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $title',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Text(
                AppStrings.noPlannedContents,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // Seção 2: Registro Fático de Execução (se houver)
          if (record != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 15,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.actualContentsSectionLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (item.actualContentTitles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 21),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.actualContentTitles
                      .map(
                        (title) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• $title',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 21),
                child: Text(
                  AppStrings.noActualContents,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // Justificativa / Motivo de Cancelamento
            if (record.cancellationReason != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 21),
                child: Text(
                  '${AppStrings.cancellationReasonPrefix}${record.cancellationReason!.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC62828),
                  ),
                ),
              ),
              if (record.cancellationDetails != null &&
                  record.cancellationDetails!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 21, top: 2),
                  child: Text(
                    '${AppStrings.cancellationDetailsPrefix}${record.cancellationDetails}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ),
            ],

            // Anotações Pedagógicas
            if (record.pedagogicalNotes != null &&
                record.pedagogicalNotes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 21),
                child: Text(
                  '${AppStrings.pedagogicalNotesPrefix}${record.pedagogicalNotes}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],

            // Continuidade Pedagógica
            if (record.needsFollowUp) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 21),
                child: Text(
                  '${AppStrings.followUpPrefix}${record.followUpNotes ?? 'Necessária'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ],

          // Observações originais do planejamento (se houver e não cobertas pelo diário)
          if (lesson.notes != null && lesson.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Text(
                '${AppStrings.plannedNotesPrefix}${lesson.notes}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          // Ação Contextual: Apontar Aula ou Retificar Apontamento
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: record == null
                  ? AppStrings.recordLessonAction
                  : AppStrings.rectifyLessonAction,
              icon: record == null
                  ? Icons.check_circle_outline
                  : Icons.edit_note,
              variant: record == null
                  ? AppButtonVariant.primary
                  : AppButtonVariant.outlined,
              onPressed: () => _openRecordDialog(item),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRecordDialog(ClassroomSubjectLessonItem item) async {
    final deps = AppDependencyScope.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RecordLessonDialog(
        plannedLesson: item.plannedLesson,
        classroomSubjectId: _selectedClassroomSubject!.id,
        classroomName: _selectedClassroom?.name ?? '',
        subjectName:
            _subjectsMap[_selectedClassroomSubject?.subjectId]?.name ?? '',
        executionRecord: item.executionRecord,
        courseContentRepository: deps.courseContentRepository,
        recordLessonExecutionUseCase: deps.recordLessonExecutionUseCase,
      ),
    );

    if (result == true && mounted) {
      final isRectification = item.executionRecord != null;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isRectification
                ? AppStrings.lessonRectifiedSuccess
                : AppStrings.lessonRecordedSuccess,
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      await _loadLessons(_selectedClassroomSubject!.id);
    }
  }

  Widget _buildStatusBadge(ClassroomSubjectLessonItem item) {
    final record = item.executionRecord;

    if (record != null) {
      switch (record.status) {
        case LessonExecutionStatus.completed:
          return const StatusBadge.custom(
            label: AppStrings.statusCompleted,
            background: Color(0xFFE8F5E9),
            foreground: Color(0xFF2E7D32),
          );
        case LessonExecutionStatus.partiallyCompleted:
          return const StatusBadge.custom(
            label: AppStrings.statusPartiallyCompleted,
            background: Color(0xFFFFF3E0),
            foreground: Color(0xFFE65100),
          );
        case LessonExecutionStatus.notHeld:
          return const StatusBadge.custom(
            label: AppStrings.statusNotHeld,
            background: Color(0xFFFFEBEE),
            foreground: Color(0xFFC62828),
          );
        case LessonExecutionStatus.planned:
          break;
      }
    }

    if (item.isPastUnrecorded) {
      return const StatusBadge.custom(
        label: AppStrings.badgePastUnrecorded,
        background: Color(0xFFFFF3E0),
        foreground: Color(0xFFE65100),
      );
    }

    return const StatusBadge.custom(
      label: AppStrings.statusPlanned,
      background: Color(0xFFE3F2FD),
      foreground: Color(0xFF1565C0),
    );
  }
}
