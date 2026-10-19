import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:app/presentation/components/app_confirm_dialog.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:app/presentation/components/status_badge.dart';
import 'package:app/presentation/screens/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Tela de Gerenciamento de Turmas, Disciplinas e Grade Horária Semanal.
class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({super.key});

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  AcademicYear? _activeYear;
  List<Classroom> _classrooms = [];
  Map<String, Subject> _allSubjectsMap = {};
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final deps = AppDependencyScope.of(context);
    final years = await deps.academicYearRepository.getAll();

    if (years.isEmpty) {
      if (mounted) {
        setState(() {
          _activeYear = null;
          _classrooms = [];
          _allSubjectsMap = {};
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

    if (mounted) {
      setState(() {
        _activeYear = year;
        _classrooms = classrooms;
        _allSubjectsMap = subjectMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateClassroomDialog() async {
    if (_activeYear == null) return;

    final nameController = TextEditingController();
    final gradeController = TextEditingController();
    ClassroomShift selectedShift = ClassroomShift.morning;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cadastrar Nova Turma'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Turma',
                      hintText: 'Ex: 9º Ano A, 1º Ano EM B',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gradeController,
                    decoration: const InputDecoration(
                      labelText: 'Ano / Série Escolar',
                      hintText: 'Ex: Ensino Fundamental 9º ano',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe a série'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ClassroomShift>(
                    initialValue: selectedShift,
                    decoration: const InputDecoration(labelText: 'Turno'),
                    items: const [
                      DropdownMenuItem(
                        value: ClassroomShift.morning,
                        child: Text('Manhã'),
                      ),
                      DropdownMenuItem(
                        value: ClassroomShift.afternoon,
                        child: Text('Tarde'),
                      ),
                      DropdownMenuItem(
                        value: ClassroomShift.evening,
                        child: Text('Noite'),
                      ),
                      DropdownMenuItem(
                        value: ClassroomShift.fullTime,
                        child: Text('Integral'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedShift = v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final deps = AppDependencyScope.of(context);
                final newClassroom = Classroom(
                  id: const Uuid().v4(),
                  academicYearId: _activeYear!.id,
                  name: nameController.text.trim(),
                  gradeLevel: gradeController.text.trim(),
                  shift: selectedShift,
                );

                await deps.classroomRepository.save(newClassroom);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                await _loadData();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manageSubjectsDialog(Classroom classroom) async {
    final deps = AppDependencyScope.of(context);
    final allSubjects = await deps.subjectRepository.getAll();

    if (!mounted) return;

    var currentClassroom = classroom;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final configs = currentClassroom.subjectConfigs;

          return AlertDialog(
            title: Text('Disciplinas — ${currentClassroom.name}'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Defina as disciplinas e a carga horária semanal específica para esta turma.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (configs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Nenhuma disciplina vinculada a esta turma ainda.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: configs.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final config = configs[index];
                          final subject = _allSubjectsMap[config.subjectId];
                          final subjectName = subject?.name ?? 'Disciplina';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Carga Horária: ${config.weeklyLessons} aulas por semana',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Consultar Aulas',
                                  icon: const Icon(
                                    Icons.assignment_outlined,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => LessonsScreen(
                                          initialClassroomId:
                                              currentClassroom.id,
                                          initialClassroomSubjectId: config.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Configurar Grade Semanal',
                                  icon: const Icon(
                                    Icons.schedule,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    await _showScheduleSlotsDialog(
                                      classroom: currentClassroom,
                                      config: config,
                                      subjectName: subjectName,
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Remover Disciplina da Turma',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final updatedConfigs =
                                        List<ClassroomSubjectConfig>.from(
                                          currentClassroom.subjectConfigs,
                                        )..removeAt(index);

                                    final updatedClassroom = Classroom(
                                      id: currentClassroom.id,
                                      academicYearId:
                                          currentClassroom.academicYearId,
                                      name: currentClassroom.name,
                                      gradeLevel: currentClassroom.gradeLevel,
                                      shift: currentClassroom.shift,
                                      subjectConfigs: updatedConfigs,
                                    );

                                    await deps.classroomRepository.save(
                                      updatedClassroom,
                                    );
                                    await _loadData();
                                    setDialogState(() {
                                      currentClassroom = updatedClassroom;
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Fechar'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Vincular Disciplina'),
                onPressed: () async {
                  await _showAddSubjectToClassroomDialog(
                    currentClassroom,
                    allSubjects,
                  );
                  final updated = await deps.classroomRepository.findById(
                    currentClassroom.id,
                  );
                  if (updated != null) {
                    setDialogState(() {
                      currentClassroom = updated;
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddSubjectToClassroomDialog(
    Classroom classroom,
    List<Subject> existingSubjects,
  ) async {
    final deps = AppDependencyScope.of(context);
    String? selectedSubjectId;
    final newSubjectNameController = TextEditingController();
    final lessonsController = TextEditingController(text: '4');
    bool isCreatingNewSubject = existingSubjects.isEmpty;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Associar Disciplina'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existingSubjects.isNotEmpty) ...[
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Existente'),
                          icon: Icon(Icons.list),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Novo Componente'),
                          icon: Icon(Icons.add),
                        ),
                      ],
                      selected: {isCreatingNewSubject},
                      onSelectionChanged: (set) {
                        setDialogState(() => isCreatingNewSubject = set.first);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!isCreatingNewSubject && existingSubjects.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Disciplina',
                      ),
                      items: existingSubjects
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedSubjectId = v),
                      validator: (v) =>
                          v == null ? 'Selecione uma disciplina' : null,
                    )
                  else
                    TextFormField(
                      controller: newSubjectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Componente Curricular',
                        hintText: 'Ex: Matemática, Robótica, História',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lessonsController,
                    decoration: const InputDecoration(
                      labelText: 'Aulas Semanais nesta Turma',
                      helperText: 'Ex: 4 aulas por semana',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val <= 0) {
                        return 'Informe um número de aulas válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                String subjectId;
                if (isCreatingNewSubject) {
                  final newSub = Subject(
                    id: const Uuid().v4(),
                    name: newSubjectNameController.text.trim(),
                  );
                  await deps.subjectRepository.save(newSub);
                  subjectId = newSub.id;
                } else {
                  subjectId = selectedSubjectId!;
                }

                final weeklyLessons = int.parse(lessonsController.text.trim());
                final updatedConfigs =
                    List<ClassroomSubjectConfig>.from(classroom.subjectConfigs)
                      ..add(
                        ClassroomSubjectConfig(
                          id: const Uuid().v4(),
                          classroomId: classroom.id,
                          subjectId: subjectId,
                          weeklyLessons: weeklyLessons,
                        ),
                      );

                final updatedClassroom = Classroom(
                  id: classroom.id,
                  academicYearId: classroom.academicYearId,
                  name: classroom.name,
                  gradeLevel: classroom.gradeLevel,
                  shift: classroom.shift,
                  subjectConfigs: updatedConfigs,
                );

                await deps.classroomRepository.save(updatedClassroom);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                await _loadData();
              },
              child: const Text('Vincular'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleSlotsDialog({
    required Classroom classroom,
    required ClassroomSubjectConfig config,
    required String subjectName,
  }) async {
    final deps = AppDependencyScope.of(context);
    final currentSlots = await deps.scheduleSlotRepository
        .getByClassroomSubject(config.id);

    final selectedSlots = List<ScheduleSlot>.from(currentSlots);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isMismatch = selectedSlots.length != config.weeklyLessons;

          return AlertDialog(
            title: Text('Grade Semanal — $subjectName (${classroom.name})'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carga configurada: ${config.weeklyLessons} aulas por semana.\n'
                      'Slots atuais alocados: ${selectedSlots.length} aulas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    if (isMismatch)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          'Atenção: a quantidade de slots alocados (${selectedSlots.length}) é diferente da carga semanal estipulada (${config.weeklyLessons}).',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Aulas na Semana',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Aula'),
                          onPressed: () {
                            setDialogState(() {
                              selectedSlots.add(
                                ScheduleSlot(
                                  id: const Uuid().v4(),
                                  classroomSubjectId: config.id,
                                  weekday: 1, // Segunda
                                  orderIndex: selectedSlots.length + 1,
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (selectedSlots.isEmpty)
                      const Text(
                        'Nenhuma aula alocada na grade ainda.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedSlots.length,
                        itemBuilder: (context, idx) {
                          final slot = selectedSlots[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButton<int>(
                                      value: slot.weekday,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 1,
                                          child: Text('Segunda'),
                                        ),
                                        DropdownMenuItem(
                                          value: 2,
                                          child: Text('Terça'),
                                        ),
                                        DropdownMenuItem(
                                          value: 3,
                                          child: Text('Quarta'),
                                        ),
                                        DropdownMenuItem(
                                          value: 4,
                                          child: Text('Quinta'),
                                        ),
                                        DropdownMenuItem(
                                          value: 5,
                                          child: Text('Sexta'),
                                        ),
                                        DropdownMenuItem(
                                          value: 6,
                                          child: Text('Sábado'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() {
                                            selectedSlots[idx] = slot.copyWith(
                                              weekday: val,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButton<int>(
                                      value: slot.orderIndex,
                                      isExpanded: true,
                                      items: List.generate(6, (i) => i + 1)
                                          .map(
                                            (ord) => DropdownMenuItem(
                                              value: ord,
                                              child: Text('$ordª aula'),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() {
                                            selectedSlots[idx] = slot.copyWith(
                                              orderIndex: val,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedSlots.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  await deps.scheduleSlotRepository.saveSlots(
                    config.id,
                    selectedSlots,
                  );
                  if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                },
                child: const Text('Salvar Grade'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteClassroom(Classroom classroom) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Excluir Turma',
      message:
          'Tem certeza que deseja excluir a turma "${classroom.name}" e todas as suas configurações?',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final deps = AppDependencyScope.of(context);
      await deps.classroomRepository.delete(classroom.id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_activeYear == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(
                  title: AppStrings.cardClassroomsTitle,
                  subtitle: AppStrings.cardClassroomsDesc,
                ),
                Expanded(
                  child: EmptyStateView(
                    title: 'Ano Letivo Necessário',
                    description: 'Antes de cadastrar turmas e disciplinas, configure o Ano Letivo na aba Calendário.',
                    icon: Icons.calendar_month,
                    actionLabel: 'Ir para Calendário',
                    onActionPressed: () {
                      // Orienta o usuário a ir ao Calendário
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Acesse a aba Calendário para configurar o ano letivo.',
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppHeader(
                      title: 'Turmas — ${_activeYear!.title}',
                      subtitle: 'Gerenciamento de turmas, disciplinas e grade horária',
                    ),
                  ),
                  AppButton(
                    label: 'Nova Turma',
                    icon: Icons.add,
                    onPressed: _showCreateClassroomDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_classrooms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(100),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma turma cadastrada neste ano letivo',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toque em "Nova Turma" para cadastrar sua primeira turma.',
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _classrooms.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final classroom = _classrooms[index];
                    final totalLessons = classroom.subjectConfigs.fold<int>(
                      0,
                      (acc, c) => acc + c.weeklyLessons,
                    );

                    return Card(
                      color: colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.class_,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      classroom.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                StatusBadge.custom(
                                  label:
                                      '${classroom.subjectConfigs.length} disciplinas',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Série: ${classroom.gradeLevel} • Turno: ${_getShiftName(classroom.shift)} • Total semanal: $totalLessons aulas',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.assignment_outlined),
                                  label: const Text('Aulas'),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => LessonsScreen(
                                          initialClassroomId: classroom.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Disciplinas e Grade'),
                                  onPressed: () =>
                                      _manageSubjectsDialog(classroom),
                                ),
                                IconButton(
                                  tooltip: 'Excluir Turma',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteClassroom(classroom),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShiftName(ClassroomShift shift) {
    switch (shift) {
      case ClassroomShift.morning:
        return 'Manhã';
      case ClassroomShift.afternoon:
        return 'Tarde';
      case ClassroomShift.evening:
        return 'Noite';
      case ClassroomShift.fullTime:
        return 'Integral';
    }
  }
}
