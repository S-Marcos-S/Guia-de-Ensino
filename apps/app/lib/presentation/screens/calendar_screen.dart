import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/school_calendar_event.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/presentation/components/app_button.dart';
import 'package:app/presentation/components/app_confirm_dialog.dart';
import 'package:app/presentation/components/app_header.dart';
import 'package:app/presentation/components/empty_state_view.dart';
import 'package:app/presentation/components/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Tela de Calendário Escolar e Configuração Pedagógica.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  AcademicYear? _currentYear;
  List<SchoolCalendarEvent> _events = [];
  CalendarCalculationResult? _calculationResult;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    final deps = AppDependencyScope.of(context);
    final years = await deps.academicYearRepository.getAll();

    if (years.isEmpty) {
      if (mounted) {
        setState(() {
          _currentYear = null;
          _events = [];
          _calculationResult = null;
          _isLoading = false;
        });
      }
      return;
    }

    final year = years.first;
    final events = await deps.calendarEventRepository.getByAcademicYear(
      year.id,
    );
    final calc = deps.calendarCalculationService.calculateTeachingDays(
      academicYear: year,
      events: events,
    );

    if (mounted) {
      setState(() {
        _currentYear = year;
        _events = events;
        _calculationResult = calc;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAcademicYearFormDialog({AcademicYear? yearToEdit}) async {
    final titleController = TextEditingController(
      text: yearToEdit?.title ?? 'Ano Letivo ${DateTime.now().year}',
    );
    final yearController = TextEditingController(
      text: (yearToEdit?.year ?? DateTime.now().year).toString(),
    );
    final mandatoryDaysController = TextEditingController(
      text: (yearToEdit?.totalMandatoryDays ?? 200).toString(),
    );

    DateTime startDate =
        yearToEdit?.startDate ?? DateTime(DateTime.now().year, 2, 2);
    DateTime endDate =
        yearToEdit?.endDate ?? DateTime(DateTime.now().year, 12, 18);

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            yearToEdit == null ? 'Novo Ano Letivo' : 'Editar Ano Letivo',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título do Período',
                      hintText: 'Ex: Ano Letivo 2026',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o título'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Ano de Referência',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val < 2000 || val > 2100) {
                        return 'Ano inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: mandatoryDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Meta Mínima de Dias Letivos',
                      helperText:
                          'Ex: 200 dias (ou conforme sua rede de ensino)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val <= 0) {
                        return 'Meta deve ser superior a zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data de Início das Aulas'),
                    subtitle: Text(
                      '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data de Término do Período'),
                    subtitle: Text(
                      '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
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

                if (!endDate.isAfter(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A data final deve ser posterior à data inicial.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final deps = AppDependencyScope.of(context);
                final year = AcademicYear(
                  id: yearToEdit?.id ?? const Uuid().v4(),
                  year: int.parse(yearController.text.trim()),
                  title: titleController.text.trim(),
                  startDate: DateTime(
                    startDate.year,
                    startDate.month,
                    startDate.day,
                  ),
                  endDate: DateTime(endDate.year, endDate.month, endDate.day),
                  totalMandatoryDays: int.parse(
                    mandatoryDaysController.text.trim(),
                  ),
                );

                await deps.academicYearRepository.save(year);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                await _loadCalendarData();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEventDialog() async {
    if (_currentYear == null) return;

    final titleController = TextEditingController();
    SchoolEventType selectedType = SchoolEventType.holiday;
    bool affectsClasses = true;

    DateTime eventStart = _currentYear!.startDate;
    DateTime eventEnd = _currentYear!.startDate;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Novo Evento / Recesso'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Evento',
                      hintText: 'Ex: Feriado de Tiradentes',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SchoolEventType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: SchoolEventType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          selectedType = v;
                          // Recesso e feriado tipicamente afetam as aulas
                          if (v == SchoolEventType.holiday ||
                              v == SchoolEventType.recess) {
                            affectsClasses = true;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cancela Aulas Regulares'),
                    subtitle: const Text('Desconta do cômputo de dias letivos'),
                    value: affectsClasses,
                    onChanged: (val) {
                      setDialogState(() => affectsClasses = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data Inicial'),
                    subtitle: Text(
                      '${eventStart.day.toString().padLeft(2, '0')}/${eventStart.month.toString().padLeft(2, '0')}/${eventStart.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: eventStart,
                        firstDate: _currentYear!.startDate,
                        lastDate: _currentYear!.endDate,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          eventStart = picked;
                          if (eventEnd.isBefore(eventStart)) {
                            eventEnd = eventStart;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data Final'),
                    subtitle: Text(
                      '${eventEnd.day.toString().padLeft(2, '0')}/${eventEnd.month.toString().padLeft(2, '0')}/${eventEnd.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: eventEnd,
                        firstDate: eventStart,
                        lastDate: _currentYear!.endDate,
                      );
                      if (picked != null) {
                        setDialogState(() => eventEnd = picked);
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

                if (eventEnd.isBefore(eventStart)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Data final não pode ser anterior à inicial.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final deps = AppDependencyScope.of(context);
                final event = SchoolCalendarEvent(
                  id: const Uuid().v4(),
                  academicYearId: _currentYear!.id,
                  title: titleController.text.trim(),
                  startDate: DateTime(
                    eventStart.year,
                    eventStart.month,
                    eventStart.day,
                  ),
                  endDate: DateTime(
                    eventEnd.year,
                    eventEnd.month,
                    eventEnd.day,
                  ),
                  type: selectedType,
                  affectsClasses: affectsClasses,
                );

                await deps.calendarEventRepository.save(event);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                await _loadCalendarData();
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(SchoolCalendarEvent event) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Excluir Evento',
      message: 'Deseja remover "${event.title}" do calendário escolar?',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final deps = AppDependencyScope.of(context);
      await deps.calendarEventRepository.delete(event.id);
      await _loadCalendarData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentYear == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(
                  title: AppStrings.cardCalendarTitle,
                  subtitle: AppStrings.cardCalendarDesc,
                ),
                Expanded(
                  child: EmptyStateView(
                    title: 'Nenhum ano letivo configurado',
                    description: 'Configure o período escolar, início e término das aulas para calcular deterministamente os dias letivos.',
                    icon: Icons.calendar_month_outlined,
                    actionLabel: 'Criar Ano Letivo',
                    onActionPressed: () => _showAcademicYearFormDialog(),
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
    final calc = _calculationResult;

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
                      title: _currentYear!.title,
                      subtitle:
                          'Período: ${_currentYear!.startDate.day.toString().padLeft(2, '0')}/${_currentYear!.startDate.month.toString().padLeft(2, '0')} a ${_currentYear!.endDate.day.toString().padLeft(2, '0')}/${_currentYear!.endDate.month.toString().padLeft(2, '0')}/${_currentYear!.endDate.year}',
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Editar Período do Ano Letivo',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        _showAcademicYearFormDialog(yearToEdit: _currentYear),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Resumo Determinístico de Dias Letivos
              Card(
                color: colorScheme.surfaceContainerHighest.withAlpha(120),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Cálculo de Dias Letivos',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusBadge.custom(
                            label: (calc?.isTargetMet ?? false)
                                ? 'Meta Atingida'
                                : 'Insuficiente',
                            background: (calc?.isTargetMet ?? false)
                                ? Colors.green.withAlpha(40)
                                : Colors.amber.withAlpha(40),
                            foreground: (calc?.isTargetMet ?? false)
                                ? Colors.green.shade800
                                : Colors.amber.shade900,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _buildMetricTile(
                            label: 'Dias Letivos Reais',
                            value: '${calc?.totalTeachingDays ?? 0}',
                            theme: theme,
                            highlight: true,
                          ),
                          _buildMetricTile(
                            label: 'Meta Configurada',
                            value: '${_currentYear!.totalMandatoryDays} dias',
                            theme: theme,
                          ),
                          _buildMetricTile(
                            label: 'Dias Corridos',
                            value: '${_currentYear!.totalCalendarDays}',
                            theme: theme,
                          ),
                        ],
                      ),
                      if (calc != null && !calc.isTargetMet) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withAlpha(100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Atenção: o calendário atual possui ${calc.missingDays} dias a menos que o mínimo de ${_currentYear!.totalMandatoryDays} dias estabelecido.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Seção de Feriados, Recessos e Eventos
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'Feriados e Recessos (${_events.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppButton(
                    label: 'Adicionar Evento',
                    icon: Icons.add,
                    onPressed: _showAddEventDialog,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_events.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(100),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Nenhum feriado ou recesso cadastrado para este ano letivo.',
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _events.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ev = _events[index];
                    final dateText = ev.startDate == ev.endDate
                        ? '${ev.startDate.day.toString().padLeft(2, '0')}/${ev.startDate.month.toString().padLeft(2, '0')}'
                        : '${ev.startDate.day.toString().padLeft(2, '0')}/${ev.startDate.month.toString().padLeft(2, '0')} a ${ev.endDate.day.toString().padLeft(2, '0')}/${ev.endDate.month.toString().padLeft(2, '0')}';

                    return ListTile(
                      tileColor: colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        ev.type == SchoolEventType.holiday
                            ? Icons.beach_access
                            : Icons.event_note,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        ev.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '$dateText • ${ev.type.displayName}${ev.affectsClasses ? ' (Sem aulas)' : ' (Com aula normal)'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Excluir Evento',
                        onPressed: () => _deleteEvent(ev),
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

  Widget _buildMetricTile({
    required String label,
    required String value,
    required ThemeData theme,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
