import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/models/school_calendar_event.dart';

/// Resultado determinístico do cálculo do calendário escolar.
class CalendarCalculationResult {
  const CalendarCalculationResult({
    required this.teachingDays,
    required this.totalTeachingDays,
    required this.targetMandatoryDays,
    required this.isTargetMet,
    required this.missingDays,
  });

  /// Lista ordenada de todas as datas letivas calculadas
  final List<DateTime> teachingDays;

  /// Quantidade total de dias letivos calculados
  final int totalTeachingDays;

  /// Meta mínima configurada no Ano Letivo
  final int targetMandatoryDays;

  /// Indica se a meta de dias letivos foi atingida
  final bool isTargetMet;

  /// Quantidade de dias faltantes para a meta (0 se já atingida)
  final int missingDays;
}

/// Serviço determinístico de regras de negócio e cálculo de calendário escolar.
/// Não depende de widgets de interface nem de banco de dados.
class CalendarCalculationService {
  const CalendarCalculationService();

  /// Calcula deterministamente todas as datas letivas do ano escolar.
  ///
  /// - [academicYear]: O ano letivo com datas de início, fim e meta de dias mínimos.
  /// - [events]: Lista de eventos, feriados e recessos cadastrados.
  /// - [activeWeekdays]: Conjunto de dias da semana letivos regulares (Padrão: 1 a 5, Segunda a Sexta).
  CalendarCalculationResult calculateTeachingDays({
    required AcademicYear academicYear,
    List<SchoolCalendarEvent> events = const [],
    Set<int> activeWeekdays = const {1, 2, 3, 4, 5},
  }) {
    if (!academicYear.isValidPeriod()) {
      return CalendarCalculationResult(
        teachingDays: const [],
        totalTeachingDays: 0,
        targetMandatoryDays: academicYear.totalMandatoryDays,
        isTargetMet: false,
        missingDays: academicYear.totalMandatoryDays,
      );
    }

    final start = DateTime(
      academicYear.startDate.year,
      academicYear.startDate.month,
      academicYear.startDate.day,
    );
    final end = DateTime(
      academicYear.endDate.year,
      academicYear.endDate.month,
      academicYear.endDate.day,
    );

    // Filtra eventos que de fato afetam as aulas
    final blockingEvents = events.where((e) => e.affectsClasses).toList();

    final teachingDays = <DateTime>[];
    var current = start;

    while (!current.isAfter(end)) {
      final weekday = current.weekday;

      // Verifica se o dia da semana é um dia letivo regular
      if (activeWeekdays.contains(weekday)) {
        // Verifica se há algum evento bloqueando esta data (mesmo que haja múltiplos ou coincidentes)
        final isBlocked = blockingEvents.any(
          (event) => event.coversDate(current),
        );

        if (!isBlocked) {
          teachingDays.add(current);
        }
      }

      current = current.add(const Duration(days: 1));
    }

    final total = teachingDays.length;
    final target = academicYear.totalMandatoryDays;
    final isMet = total >= target;
    final missing = isMet ? 0 : target - total;

    return CalendarCalculationResult(
      teachingDays: teachingDays,
      totalTeachingDays: total,
      targetMandatoryDays: target,
      isTargetMet: isMet,
      missingDays: missing,
    );
  }

  /// Calcula a quantidade exata de aulas que ocorrerão para uma disciplina ao longo do ano,
  /// com base nos dias letivos reais calculados e nos slots de horário da turma.
  int calculateSubjectLessonCount({
    required List<DateTime> teachingDays,
    required List<ScheduleSlot> subjectSlots,
  }) {
    if (teachingDays.isEmpty || subjectSlots.isEmpty) {
      return 0;
    }

    // Mapeia quantos slots a disciplina tem para cada dia da semana (ex: Segunda: 2 aulas, Quinta: 1 aula)
    final slotsPerWeekday = <int, int>{};
    for (final slot in subjectSlots) {
      slotsPerWeekday[slot.weekday] = (slotsPerWeekday[slot.weekday] ?? 0) + 1;
    }

    var totalLessons = 0;
    for (final day in teachingDays) {
      final lessonsOnThisDay = slotsPerWeekday[day.weekday] ?? 0;
      totalLessons += lessonsOnThisDay;
    }

    return totalLessons;
  }

  /// Verifica se há conflito de horários na grade semanal de uma turma
  /// (ex: dois slots atribuídos ao mesmo dia da semana e mesmo índice de aula).
  List<String> validateScheduleConflicts(
    List<ScheduleSlot> allSlotsForClassroom,
  ) {
    final conflicts = <String>[];
    final seen = <String>{};

    for (final slot in allSlotsForClassroom) {
      final key = '${slot.weekday}-${slot.orderIndex}';
      if (seen.contains(key)) {
        conflicts.add(
          'Conflito na ${slot.weekdayName}, ${slot.orderIndex}ª aula: mais de uma disciplina alocada no mesmo horário.',
        );
      } else {
        seen.add(key);
      }
    }

    return conflicts;
  }
}
