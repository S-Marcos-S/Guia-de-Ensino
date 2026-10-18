/// Slot de horário semanal para a aula de uma disciplina em uma turma.
class ScheduleSlot {
  const ScheduleSlot({
    required this.id,
    required this.classroomSubjectId,
    required this.weekday,
    required this.orderIndex,
    this.startTime,
    this.endTime,
  });

  final String id;
  final String classroomSubjectId;

  /// Dia da semana (1 = Segunda-feira ... 7 = Domingo)
  final int weekday;

  /// Ordem da aula no dia (1 = 1ª aula, 2 = 2ª aula...)
  final int orderIndex;

  /// Horário inicial opcional (ex: "07:30")
  final String? startTime;

  /// Horário de término opcional (ex: "08:20")
  final String? endTime;

  /// Nome legível do dia da semana em português
  String get weekdayName {
    switch (weekday) {
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Dia $weekday';
    }
  }

  bool isValid() {
    return weekday >= 1 && weekday <= 7 && orderIndex >= 1;
  }

  ScheduleSlot copyWith({
    String? id,
    String? classroomSubjectId,
    int? weekday,
    int? orderIndex,
    String? startTime,
    String? endTime,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
      weekday: weekday ?? this.weekday,
      orderIndex: orderIndex ?? this.orderIndex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleSlot &&
        other.id == id &&
        other.classroomSubjectId == classroomSubjectId &&
        other.weekday == weekday &&
        other.orderIndex == orderIndex &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(
    id,
    classroomSubjectId,
    weekday,
    orderIndex,
    startTime,
    endTime,
  );
}
