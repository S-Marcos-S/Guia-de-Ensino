import 'dart:async';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/curriculum_competency.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/domain/services/curriculum_integrity_service.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:app/presentation/components/app_confirm_dialog.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:app/presentation/components/planning_preview_dialog.dart';
import 'package:app/presentation/components/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Tela de Gerenciamento de Conteúdos Programáticos e Base Curricular (BNCC).
class ContentsScreen extends StatefulWidget {
  const ContentsScreen({super.key});

  @override
  State<ContentsScreen> createState() => _ContentsScreenState();
}

class _ContentsScreenState extends State<ContentsScreen> {
  AcademicYear? _activeYear;
  List<Classroom> _classrooms = [];
  Classroom? _selectedClassroom;
  ClassroomSubjectConfig? _selectedClassroomSubject;
  Map<String, Subject> _subjectsMap = {};

  List<CourseContent> _contents = [];
  List<CurriculumCompetency> _allCompetencies = [];
  bool _isLoading = true;
  bool _initialized = false;
  String? _filterQuery;

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
    final competencies = await deps.curriculumCompetencyRepository.getAll();

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
        _allCompetencies = competencies;
        _selectedClassroom = defaultClassroom;
        _selectedClassroomSubject = defaultClassroomSubject;
        _contents = [];
        _isLoading = false;
      });
      if (defaultClassroomSubject != null) {
        final contents = await deps.courseContentRepository
            .getByClassroomSubject(defaultClassroomSubject.id);
        if (mounted) {
          setState(() {
            _contents = contents;
          });
        }
      }
    }
  }

  Future<void> _loadContents() async {
    if (_selectedClassroomSubject == null) {
      if (mounted) {
        setState(() {
          _contents = [];
          _isLoading = false;
        });
      }
      return;
    }

    final deps = AppDependencyScope.of(context);
    final contents = await deps.courseContentRepository.getByClassroomSubject(
      _selectedClassroomSubject!.id,
    );

    if (mounted) {
      setState(() {
        _contents = contents;
        _isLoading = false;
      });
    }
  }

  Future<void> _showContentFormDialog({CourseContent? contentToEdit}) async {
    if (_selectedClassroomSubject == null) return;

    final deps = AppDependencyScope.of(context);
    final isEditing = contentToEdit != null;
    final titleController = TextEditingController(
      text: contentToEdit?.title ?? '',
    );
    final descController = TextEditingController(
      text: contentToEdit?.description ?? '',
    );
    final thematicUnitController = TextEditingController(
      text: contentToEdit?.thematicUnit ?? '',
    );
    final lessonsController = TextEditingController(
      text: contentToEdit != null
          ? contentToEdit.estimatedLessons.toString()
          : '2',
    );

    bool isMandatory = contentToEdit?.isMandatory ?? true;
    ContentOrigin origin = contentToEdit?.origin ?? ContentOrigin.manual;
    String? selectedCompetencyId = contentToEdit?.curriculumCompetencyId;
    final selectedPrereqIds = List<String>.from(
      contentToEdit?.prerequisiteIds ?? [],
    );

    final formKey = GlobalKey<FormState>();

    final availablePrereqs = _contents
        .where((c) => !isEditing || c.id != contentToEdit.id)
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectedCompetency = selectedCompetencyId != null
              ? _allCompetencies.cast<CurriculumCompetency?>().firstWhere(
                  (c) => c?.id == selectedCompetencyId,
                  orElse: () => null,
                )
              : null;

          return AlertDialog(
            title: Text(
              isEditing ? 'Editar Conteúdo' : 'Novo Conteúdo Programático',
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título do Conteúdo *',
                          hintText: 'Ex: Funções Afins e Gráficos Cartesianos',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o título do conteúdo'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descrição / Objetivos (opcional)',
                          hintText: 'Ex: Resolução de problemas práticos...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: thematicUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Unidade Temática (opcional)',
                          hintText: 'Ex: Álgebra, Geometria, Números...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: lessonsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Aulas Estimadas *',
                              ),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n <= 0) {
                                  return 'Informe um número positivo';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<ContentOrigin>(
                              initialValue: origin,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Origem',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: ContentOrigin.manual,
                                  child: Text(
                                    'Personalizado',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ContentOrigin.officialCurriculumImport,
                                  child: Text(
                                    'BNCC Oficial',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ContentOrigin.documentImport,
                                  child: Text(
                                    'Importação',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => origin = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Conteúdo Obrigatório'),
                        subtitle: const Text(
                          'Conteúdos obrigatórios não podem ser descartados em replanejamentos.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: isMandatory,
                        onChanged: (val) {
                          setDialogState(() => isMandatory = val);
                        },
                      ),
                      const Divider(height: 24),
                      Text(
                        'Referência Curricular (BNCC Oficial - Opcional)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (selectedCompetency != null)
                        Card(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${selectedCompetency.code} (${selectedCompetency.subjectName})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        selectedCompetency.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  tooltip: 'Remover vínculo',
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedCompetencyId = null;
                                      if (origin ==
                                          ContentOrigin
                                              .officialCurriculumImport) {
                                        origin = ContentOrigin.manual;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Vincular Habilidade da BNCC'),
                          onPressed: () async {
                            final comp = await _showCompetencySelectionDialog();
                            if (comp != null) {
                              setDialogState(() {
                                selectedCompetencyId = comp.id;
                                origin = ContentOrigin.officialCurriculumImport;
                                if (titleController.text.isEmpty) {
                                  titleController.text =
                                      '${comp.code} - ${comp.thematicUnit}';
                                }
                                if (descController.text.isEmpty) {
                                  descController.text = comp.description;
                                }
                                if (thematicUnitController.text.isEmpty) {
                                  thematicUnitController.text =
                                      comp.thematicUnit;
                                }
                              });
                            }
                          },
                        ),
                      const Divider(height: 24),
                      Text(
                        'Pré-requisitos Pedagógicos (Opcional)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Selecione conteúdos que devem ser ensinados antes deste:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (availablePrereqs.isEmpty)
                        const Text(
                          'Nenhum outro conteúdo disponível nesta disciplina.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: availablePrereqs.map((prereq) {
                            final isSelected = selectedPrereqIds.contains(
                              prereq.id,
                            );
                            return FilterChip(
                              label: Text(
                                prereq.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedPrereqIds.add(prereq.id);
                                  } else {
                                    selectedPrereqIds.remove(prereq.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              AppButton(
                label: 'Salvar',
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final contentId = contentToEdit?.id ?? const Uuid().v4();
                  final newContent = CourseContent(
                    id: contentId,
                    classroomSubjectId: _selectedClassroomSubject!.id,
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    thematicUnit: thematicUnitController.text.trim().isEmpty
                        ? null
                        : thematicUnitController.text.trim(),
                    estimatedLessons: int.parse(lessonsController.text.trim()),
                    orderIndex:
                        contentToEdit?.orderIndex ?? _contents.length + 1,
                    curriculumCompetencyId: selectedCompetencyId,
                    origin: origin,
                    isMandatory: isMandatory,
                    prerequisiteIds: selectedPrereqIds,
                  );

                  // Validação determinística de pré-requisitos e integridade curricular
                  final testList = List<CourseContent>.from(_contents);
                  final idx = testList.indexWhere((c) => c.id == contentId);
                  if (idx >= 0) {
                    testList[idx] = newContent;
                  } else {
                    testList.add(newContent);
                  }

                  try {
                    deps.curriculumIntegrityService.validateContents(testList);
                  } on CircularDependencyException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          content: Text(
                            'Erro de Pré-requisito: ${e.message}\nCaminho: ${e.cyclePath.join(' -> ')}',
                          ),
                        ),
                      );
                    }
                    return;
                  } on CurriculumValidationException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          content: Text('Erro de validação: ${e.message}'),
                        ),
                      );
                    }
                    return;
                  }

                  await deps.courseContentRepository.save(newContent);
                  if (ctx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  await _loadContents();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<CurriculumCompetency?> _showCompetencySelectionDialog() async {
    final deps = AppDependencyScope.of(context);
    final searchController = TextEditingController();
    List<CurriculumCompetency> results = List.from(_allCompetencies);

    return showDialog<CurriculumCompetency>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Selecionar Habilidade Oficial da BNCC'),
            content: SizedBox(
              width: 600,
              height: 480,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText:
                          'Buscar por código, descrição ou unidade temática',
                      hintText: 'Ex: EF06MA01, Geometria, Números...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setDialogState(() {
                                  results = List.from(_allCompetencies);
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (query) async {
                      final filtered = await deps.curriculumCompetencyRepository
                          .search(query: query);
                      setDialogState(() {
                        results = filtered;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${results.length} habilidades encontradas (BNCC MEC)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(),
                  Expanded(
                    child: results.isEmpty
                        ? const Center(
                            child: Text('Nenhuma habilidade localizada.'),
                          )
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, index) {
                              final item = results[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  '${item.code} — ${item.subjectName} (${item.gradeLevel})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '[${item.thematicUnit}] ${item.description}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.pop(dialogCtx, item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteContent(CourseContent content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Excluir Conteúdo?',
        message:
            'Tem certeza de que deseja remover "${content.title}"? Os vínculos de pré-requisito com este conteúdo também serão desfeitos.',
        confirmLabel: 'Excluir',
        isDestructive: true,
      ),
    );

    if (confirmed == true && mounted) {
      final deps = AppDependencyScope.of(context);
      await deps.courseContentRepository.delete(content.id);
      await _loadContents();
    }
  }

  Future<void> _onReorderItem(int oldIndex, int newIndex) async {
    final item = _contents.removeAt(oldIndex);
    _contents.insert(newIndex, item);

    final orderedIds = _contents.map((c) => c.id).toList();
    final deps = AppDependencyScope.of(context);
    await deps.courseContentRepository.reorder(
      _selectedClassroomSubject!.id,
      orderedIds,
    );
    await _loadContents();
  }

  Future<void> _openPlanningPreview() async {
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
              _loadContents();
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
                  title: AppStrings.cardContentsTitle,
                  subtitle: AppStrings.cardContentsDesc,
                ),
                Expanded(
                  child: EmptyStateView(
                    title: AppStrings.emptyContentsTitle,
                    description: 'Configure o ano letivo e as turmas para começar a planejar os conteúdos programáticos.',
                    icon: Icons.calendar_today_outlined,
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
                  title: AppStrings.cardContentsTitle,
                  subtitle: AppStrings.cardContentsDesc,
                ),
                Expanded(
                  child: EmptyStateView(
                    title: 'Nenhuma Turma Cadastrada',
                    description: 'Cadastre suas turmas e disciplinas na aba "Turmas" para associar conteúdos programáticos.',
                    icon: Icons.people_outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredContents =
        _filterQuery == null || _filterQuery!.trim().isEmpty
        ? _contents
        : _contents.where((c) {
            final q = _filterQuery!.toLowerCase();
            return c.title.toLowerCase().contains(q) ||
                (c.description?.toLowerCase().contains(q) ?? false);
          }).toList();

    final totalLessons = _contents.fold<int>(
      0,
      (sum, c) => sum + c.estimatedLessons,
    );
    final subjectConfig = _selectedClassroomSubject;
    final subjectObj = subjectConfig != null
        ? _subjectsMap[subjectConfig.subjectId]
        : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: AppStrings.cardContentsTitle,
                subtitle: 'Planeje e sequencie as unidades didáticas para suas turmas.',
                action: AppButton(
                  label: 'Novo Conteúdo',
                  icon: Icons.add,
                  onPressed: _selectedClassroomSubject != null
                      ? () => _showContentFormDialog()
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
                          key: ValueKey(_selectedClassroom?.id),
                          initialValue: _selectedClassroom,
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
                              _loadContents();
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
                              _loadContents();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Resumo de Horas da Disciplina
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
                        label: '${_contents.length} conteúdos',
                        background: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        foreground: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                      StatusBadge.custom(
                        label: 'Total Estimado: $totalLessons aulas',
                        background: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        foreground: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      SizedBox(
                        width: 180,
                        height: 38,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Filtrar...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            setState(() => _filterQuery = val);
                          },
                        ),
                      ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.auto_awesome_motion, size: 18),
                        label: const Text('Distribuir Aulas'),
                        onPressed: _contents.isEmpty
                            ? null
                            : _openPlanningPreview,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // Lista reordenável de conteúdos
              Expanded(
                child: _selectedClassroomSubject == null
                    ? const Center(
                        child: Text(
                          'Esta turma não possui disciplinas vinculadas.',
                        ),
                      )
                    : filteredContents.isEmpty
                    ? EmptyStateView(
                        title: AppStrings.emptyContentsTitle,
                        description: 'Adicione conteúdos personalizados ou importe referências da BNCC para compor o plano de aula.',
                        icon: Icons.menu_book_outlined,
                        actionLabel: 'Adicionar Primeiro Conteúdo',
                        onActionPressed: () => _showContentFormDialog(),
                      )
                    : ReorderableListView.builder(
                        itemCount: filteredContents.length,
                        onReorderItem: _onReorderItem,
                        itemBuilder: (ctx, index) {
                          final content = filteredContents[index];
                          final competency =
                              content.curriculumCompetencyId != null
                              ? _allCompetencies
                                    .cast<CurriculumCompetency?>()
                                    .firstWhere(
                                      (c) =>
                                          c?.id ==
                                          content.curriculumCompetencyId,
                                      orElse: () => null,
                                    )
                              : null;

                          final prereqNames = content.prerequisiteIds
                              .map(
                                (id) => _contents
                                    .cast<CourseContent?>()
                                    .firstWhere(
                                      (c) => c?.id == id,
                                      orElse: () => null,
                                    )
                                    ?.title,
                              )
                              .whereType<String>()
                              .toList();

                          return Card(
                            key: ValueKey(content.id),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    content.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (content.origin ==
                                      ContentOrigin.officialCurriculumImport)
                                    StatusBadge.custom(
                                      label: 'BNCC Oficial',
                                      background: Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer,
                                      foreground: Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer,
                                    )
                                  else
                                    StatusBadge.custom(
                                      label: 'Personalizado',
                                      background: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      foreground: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  if (content.isMandatory)
                                    const StatusBadge.custom(
                                      label: 'Obrigatório',
                                      background: Color(0xFFFEF3C7),
                                      foreground: Color(0xFF92400E),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (content.description != null &&
                                      content.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        content.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (competency != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'BNCC: ${competency.code} — ${competency.description}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (prereqNames.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Pré-requisitos: ${prereqNames.join(', ')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.brown,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Aulas estimadas: ${content.estimatedLessons}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Editar Conteúdo',
                                    onPressed: () => _showContentFormDialog(
                                      contentToEdit: content,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Excluir Conteúdo',
                                    onPressed: () => _deleteContent(content),
                                  ),
                                  const Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey,
                                  ),
                                ],
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
