/// Status da realização de uma aula na rotina docente.
enum LessonExecutionStatus { planned, completed, partiallyCompleted, notHeld }

/// Entidade representando uma aula no cronograma letivo.
class PlannedLesson {
  const PlannedLesson({
    required this.id,
    required this.classroomSubjectId,
    required this.date,
    required this.orderInDay,
    this.contentIds = const [],
    this.status = LessonExecutionStatus.planned,
    this.isLocked = false,
    this.notes,
  });

  final String id;
  final String classroomSubjectId;
  final DateTime date;
  final int orderInDay;
  final List<String> contentIds;
  final LessonExecutionStatus status;
  final bool isLocked;
  final String? notes;

  /// Retorna se a aula já foi executada ou registrada
  bool get hasExecutionRecord => status != LessonExecutionStatus.planned;

  PlannedLesson copyWith({
    String? id,
    String? classroomSubjectId,
    DateTime? date,
    int? orderInDay,
    List<String>? contentIds,
    LessonExecutionStatus? status,
    bool? isLocked,
    String? notes,
  }) {
    return PlannedLesson(
      id: id ?? this.id,
      classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
      date: date ?? this.date,
      orderInDay: orderInDay ?? this.orderInDay,
      contentIds: contentIds ?? this.contentIds,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlannedLesson &&
        other.id == id &&
        other.classroomSubjectId == classroomSubjectId &&
        other.date == date &&
        other.orderInDay == orderInDay &&
        other.status == status &&
        other.isLocked == isLocked;
  }

  @override
  int get hashCode =>
      Object.hash(id, classroomSubjectId, date, orderInDay, status, isLocked);
}
