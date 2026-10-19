import 'dart:async';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:app/presentation/components/planning_preview_dialog.dart';
import 'package:app/presentation/components/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tela de Planejamento e Replanejamento Automático de Aulas.
class ReplanningScreen extends StatefulWidget {
  const ReplanningScreen({super.key});

  @override
  State<ReplanningScreen> createState() => _ReplanningScreenState();
}

class _ReplanningScreenState extends State<ReplanningScreen> {
  AcademicYear? _activeYear;
  List<Classroom> _classrooms = [];
  Classroom? _selectedClassroom;
  ClassroomSubjectConfig? _selectedClassroomSubject;
  Map<String, Subject> _subjectsMap = {};
  Map<String, CourseContent> _contentsMap = {};

  List<PlannedLesson> _lessons = [];
  bool _isLoading = true;
  bool _initialized = false;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
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
          _isLoading = false;
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

    Classroom? defaultClassroom = _selectedClassroom;
    if (defaultClassroom == null ||
        !classrooms.any((c) => c.id == defaultClassroom!.id)) {
      defaultClassroom = classrooms.isNotEmpty ? classrooms.first : null;
    }

    ClassroomSubjectConfig? defaultClassroomSubject;
    if (defaultClassroom != null &&
        defaultClassroom.subjectConfigs.isNotEmpty) {
      defaultClassroomSubject = defaultClassroom.subjectConfigs.first;
    }

    if (mounted) {
      setState(() {
        _activeYear = year;
        _classrooms = classrooms;
        _subjectsMap = subjectMap;
        _selectedClassroom = defaultClassroom;
        _selectedClassroomSubject = defaultClassroomSubject;
        _isLoading = false;
      });
      if (defaultClassroomSubject != null) {
        await _loadLessons(defaultClassroomSubject.id);
      }
    }
  }

  Future<void> _loadLessons(String classroomSubjectId) async {
    final deps = AppDependencyScope.of(context);
    final lessons = await deps.plannedLessonRepository.getByClassroomSubject(
      classroomSubjectId,
    );
    final contents = await deps.courseContentRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    if (mounted) {
      setState(() {
        _lessons = lessons;
        _contentsMap = {for (final c in contents) c.id: c};
      });
    }
  }

  Future<void> _generatePlan() async {
    if (_selectedClassroomSubject == null) return;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final deps = AppDependencyScope.of(context);
      final result = await deps.generateSchedulePlanUseCase.execute(
        classroomSubjectId: _selectedClassroomSubject!.id,
      );

      if (mounted) {
        Navigator.pop(context); // Fecha loading
        final subjectName =
            _subjectsMap[_selectedClassroomSubject!.subjectId]?.name ??
            'Disciplina';

        await showDialog<void>(
          context: context,
          builder: (ctx) => PlanningPreviewDialog(
            classroomName: _selectedClassroom?.name ?? '',
            subjectName: subjectName,
            result: result,
            onPlanApplied: () {
              _loadLessons(_selectedClassroomSubject!.id);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao calcular planejamento: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_activeYear == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeader(
                  title: AppStrings.cardReplanningTitle,
                  subtitle: AppStrings.cardReplanningDesc,
                ),
                Expanded(
                  child: EmptyStateView(
                    title: AppStrings.emptyReplanningTitle,
                    description: AppStrings.emptyReplanningDesc,
                    icon: Icons.auto_mode_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_classrooms.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeader(
                  title: AppStrings.cardReplanningTitle,
                  subtitle: AppStrings.cardReplanningDesc,
                ),
                Expanded(
                  child: EmptyStateView(
                    title: 'Nenhuma Turma Cadastrada',
                    description: 'Cadastre turmas e vincule disciplinas para gerar cronogramas de aula.',
                    icon: Icons.people_outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subjectConfig = _selectedClassroomSubject;
    final subjectObj = subjectConfig != null
        ? _subjectsMap[subjectConfig.subjectId]
        : null;

    final completedCount = _lessons
        .where((l) => l.status == LessonExecutionStatus.completed)
        .length;
    final plannedCount = _lessons
        .where((l) => l.status == LessonExecutionStatus.planned)
        .length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: AppStrings.cardReplanningTitle,
                subtitle: 'Distribua ou reorganize os conteúdos pedagógicos no calendário letivo.',
                action: AppButton(
                  label: 'Gerar Planejamento',
                  icon: Icons.auto_awesome_motion,
                  onPressed: _selectedClassroomSubject != null
                      ? _generatePlan
                      : null,
                ),
              ),
              const SizedBox(height: 8),

              // Barra de seleção de Turma e Disciplina
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Seletor de Turma
                      Expanded(
                        child: DropdownButtonFormField<Classroom>(
                          value: _selectedClassroom,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Turma',
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
                          onChanged: (newClasroom) {
                            if (newClasroom != null) {
                              setState(() {
                                _selectedClassroom = newClasroom;
                                _selectedClassroomSubject =
                                    newClasroom.subjectConfigs.isNotEmpty
                                    ? newClasroom.subjectConfigs.first
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
                          value: _selectedClassroomSubject,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Disciplina',
                            isDense: true,
                          ),
                          items: (_selectedClassroom?.subjectConfigs ?? [])
                              .map<DropdownMenuItem<ClassroomSubjectConfig>>((
                                ClassroomSubjectConfig cs,
                              ) {
                                final name =
                                    _subjectsMap[cs.subjectId]?.name ??
                                    'Disciplina desconhecida';
                                return DropdownMenuItem<ClassroomSubjectConfig>(
                                  value: cs,
                                  child: Text(
                                    '$name (${cs.weeklyLessons}h/sem)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (newSubject) {
                            if (newSubject != null) {
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
              const SizedBox(height: 8),

              // Badges de Status do Cronograma
              if (subjectConfig != null && subjectObj != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge.custom(
                        label: '${_lessons.length} aulas no cronograma',
                        background: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        foreground: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                      StatusBadge.custom(
                        label: '$plannedCount previstas',
                        background: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        foreground: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      if (completedCount > 0)
                        StatusBadge.custom(
                          label: '$completedCount realizadas',
                          background: const Color(0xFFE8F5E9),
                          foreground: const Color(0xFF2E7D32),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // Lista de Aulas Planejadas
              Expanded(
                child: _selectedClassroomSubject == null
                    ? const Center(
                        child: Text(
                          'Esta turma não possui disciplinas vinculadas.',
                        ),
                      )
                    : _lessons.isEmpty
                    ? EmptyStateView(
                        title: 'Nenhum Cronograma Gerado',
                        description:
                            'Clique no botão "Gerar Planejamento" acima para distribuir os conteúdos cadastrados '
                            'nas datas letivas desta disciplina.',
                        icon: Icons.calendar_today_outlined,
                        actionLabel: 'Gerar Planejamento Agora',
                        onActionPressed: _generatePlan,
                      )
                    : ListView.separated(
                        itemCount: _lessons.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return _buildLessonCard(context, lesson);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, PlannedLesson lesson) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final contentTitles = lesson.contentIds
        .map((id) => _contentsMap[id]?.title ?? id)
        .join(', ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _dateFormat.format(lesson.date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${lesson.orderInDay}ª aula',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(status: lesson.status),
                      if (lesson.isLocked) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Color(0xFF5D4037),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contentTitles.isNotEmpty
                        ? contentTitles
                        : 'Sem conteúdo vinculado',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (lesson.notes != null && lesson.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lesson.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
