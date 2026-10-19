/// Exceção de validação de métricas de progresso de turma e disciplina.
class ClassroomSubjectProgressValidationException implements Exception {
  const ClassroomSubjectProgressValidationException(this.message);

  final String message;

  @override
  String toString() => 'ClassroomSubjectProgressValidationException: $message';
}

/// Objeto de valor (Value Object) contendo indicadores determinísticos de progresso
/// e cumprimento do cronograma de uma disciplina na turma.
class ClassroomSubjectProgress {
  ClassroomSubjectProgress({
    required this.classroomSubjectId,
    required this.totalLessonsPlanned,
    required this.completedLessonsCount,
    required this.partiallyCompletedLessonsCount,
    required this.notHeldLessonsCount,
    required this.pendingRecordLessonsCount,
    required this.futureLessonsCount,
  }) {
    validate();
  }

  /// Identificador do vínculo disciplina/turma (ClassroomSubject).
  final String classroomSubjectId;

  /// Total de ocorrências de aulas previstas no calendário escolar para a disciplina.
  final int totalLessonsPlanned;

  /// Quantidade de aulas com registro de conclusão integral (completed).
  final int completedLessonsCount;

  /// Quantidade de aulas com registro de realização parcial (partiallyCompleted).
  final int partiallyCompletedLessonsCount;

  /// Quantidade de aulas com registro de não realização (notHeld).
  final int notHeldLessonsCount;

  /// Quantidade de aulas ocorridas em datas passadas que ainda não possuem registro docente.
  final int pendingRecordLessonsCount;

  /// Quantidade de aulas programadas para datas futuras (sem registro).
  final int futureLessonsCount;

  /// Total de aulas que já possuem algum registro formal de execução fática.
  int get totalLessonsRecorded =>
      completedLessonsCount +
      partiallyCompletedLessonsCount +
      notHeldLessonsCount;

  /// Total de aulas com efetivo aproveitamento pedagógico (total ou parcial).
  int get totalLessonsEffective =>
      completedLessonsCount + partiallyCompletedLessonsCount;

  /// Taxa de cumprimento pedagógico efetivo em relação ao total planejado (0.0 a 1.0).
  double get completionRate => totalLessonsPlanned > 0
      ? totalLessonsEffective / totalLessonsPlanned
      : 0.0;

  /// Taxa de registro docente fático em relação ao total planejado (0.0 a 1.0).
  double get recordingRate => totalLessonsPlanned > 0
      ? totalLessonsRecorded / totalLessonsPlanned
      : 0.0;

  /// Sinaliza se existem aulas pendentes de registro em datas já passadas.
  bool get hasPendingPastLessons => pendingRecordLessonsCount > 0;

  /// Valida as invariantes matemáticas e pedagógicas do progresso.
  void validate() {
    if (classroomSubjectId.trim().isEmpty) {
      throw const ClassroomSubjectProgressValidationException(
        'O identificador da disciplina da turma não pode ser vazio.',
      );
    }
    if (totalLessonsPlanned < 0 ||
        completedLessonsCount < 0 ||
        partiallyCompletedLessonsCount < 0 ||
        notHeldLessonsCount < 0 ||
        pendingRecordLessonsCount < 0 ||
        futureLessonsCount < 0) {
      throw const ClassroomSubjectProgressValidationException(
        'Nenhum contador de progresso de aulas pode ser negativo.',
      );
    }

    final sum =
        completedLessonsCount +
        partiallyCompletedLessonsCount +
        notHeldLessonsCount +
        pendingRecordLessonsCount +
        futureLessonsCount;

    if (sum != totalLessonsPlanned) {
      throw ClassroomSubjectProgressValidationException(
        'Inconsistência nos contadores de progresso: a soma das categorias ($sum) '
        'não corresponde ao total de aulas planejadas ($totalLessonsPlanned).',
      );
    }
  }

  ClassroomSubjectProgress copyWith({
    String? classroomSubjectId,
    int? totalLessonsPlanned,
    int? completedLessonsCount,
    int? partiallyCompletedLessonsCount,
    int? notHeldLessonsCount,
    int? pendingRecordLessonsCount,
    int? futureLessonsCount,
  }) {
    return ClassroomSubjectProgress(
      classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
      totalLessonsPlanned: totalLessonsPlanned ?? this.totalLessonsPlanned,
      completedLessonsCount:
          completedLessonsCount ?? this.completedLessonsCount,
      partiallyCompletedLessonsCount:
          partiallyCompletedLessonsCount ?? this.partiallyCompletedLessonsCount,
      notHeldLessonsCount: notHeldLessonsCount ?? this.notHeldLessonsCount,
      pendingRecordLessonsCount:
          pendingRecordLessonsCount ?? this.pendingRecordLessonsCount,
      futureLessonsCount: futureLessonsCount ?? this.futureLessonsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassroomSubjectProgress &&
        other.classroomSubjectId == classroomSubjectId &&
        other.totalLessonsPlanned == totalLessonsPlanned &&
        other.completedLessonsCount == completedLessonsCount &&
        other.partiallyCompletedLessonsCount ==
            partiallyCompletedLessonsCount &&
        other.notHeldLessonsCount == notHeldLessonsCount &&
        other.pendingRecordLessonsCount == pendingRecordLessonsCount &&
        other.futureLessonsCount == futureLessonsCount;
  }

  @override
  int get hashCode => Object.hash(
    classroomSubjectId,
    totalLessonsPlanned,
    completedLessonsCount,
    partiallyCompletedLessonsCount,
    notHeldLessonsCount,
    pendingRecordLessonsCount,
    futureLessonsCount,
  );
}
