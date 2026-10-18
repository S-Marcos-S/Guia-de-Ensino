/// Tipos de eventos do calendário escolar.
enum SchoolEventType {
  holiday,
  recess,
  pedagogicalMeeting,
  administrativeBreak,
  other,
}

extension SchoolEventTypeExtension on SchoolEventType {
  String get displayName {
    switch (this) {
      case SchoolEventType.holiday:
        return 'Feriado';
      case SchoolEventType.recess:
        return 'Recesso Escolar';
      case SchoolEventType.pedagogicalMeeting:
        return 'Planejamento Pedagógico';
      case SchoolEventType.administrativeBreak:
        return 'Suspensão Administrativa';
      case SchoolEventType.other:
        return 'Outro Evento';
    }
  }
}

/// Entidade de domínio pura para Eventos, Feriados e Recessos do Calendário.
class SchoolCalendarEvent {
  const SchoolCalendarEvent({
    required this.id,
    required this.academicYearId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.type = SchoolEventType.holiday,
    this.affectsClasses = true,
  });

  final String id;
  final String academicYearId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final SchoolEventType type;
  final bool affectsClasses;

  /// Valida se o período do evento é cronologicamente válido (endDate >= startDate)
  bool isValidPeriod() {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !end.isBefore(start);
  }

  /// Verifica se uma data específica cai dentro deste evento
  bool coversDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return (target.isAtSameMomentAs(start) || target.isAfter(start)) &&
        (target.isAtSameMomentAs(end) || target.isBefore(end));
  }

  SchoolCalendarEvent copyWith({
    String? id,
    String? academicYearId,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    SchoolEventType? type,
    bool? affectsClasses,
  }) {
    return SchoolCalendarEvent(
      id: id ?? this.id,
      academicYearId: academicYearId ?? this.academicYearId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      affectsClasses: affectsClasses ?? this.affectsClasses,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchoolCalendarEvent &&
        other.id == id &&
        other.academicYearId == academicYearId &&
        other.title == title &&
        other.startDate.year == startDate.year &&
        other.startDate.month == startDate.month &&
        other.startDate.day == startDate.day &&
        other.endDate.year == endDate.year &&
        other.endDate.month == endDate.month &&
        other.endDate.day == endDate.day &&
        other.type == type &&
        other.affectsClasses == affectsClasses;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academicYearId,
    title,
    startDate.year,
    startDate.month,
    startDate.day,
    endDate.year,
    endDate.month,
    endDate.day,
    type,
    affectsClasses,
  );
}
