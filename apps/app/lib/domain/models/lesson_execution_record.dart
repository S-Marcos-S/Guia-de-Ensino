import 'package:app/domain/models/planned_lesson.dart';

/// Categorias padronizadas para justificativa de aula não realizada.
enum LessonCancellationReason {
  /// Evento no calendário escolar, comemoração, conselho de classe ou reunião pedagógica.
  schoolEvent,

  /// Ausência, atestado ou licença do professor.
  teacherAbsence,

  /// Ausência coletiva de alunos, paralisação ou suspensão de aulas.
  studentAbsenceOrSuspension,

  /// Problema de infraestrutura (falta de água/luz, obra, evento climático adverso).
  infrastructureIssue,

  /// Remanejamento de horário ou ajuste pedagógico da escola.
  pedagogicalAdjustment,

  /// Outro motivo justificado no campo de detalhes.
  other,
}

extension LessonCancellationReasonExtension on LessonCancellationReason {
  String get label {
    switch (this) {
      case LessonCancellationReason.schoolEvent:
        return 'Evento Escolar / Reunião';
      case LessonCancellationReason.teacherAbsence:
        return 'Falta / Licença do Professor';
      case LessonCancellationReason.studentAbsenceOrSuspension:
        return 'Ausência de Alunos / Suspensão';
      case LessonCancellationReason.infrastructureIssue:
        return 'Problema de Infraestrutura / Força Maior';
      case LessonCancellationReason.pedagogicalAdjustment:
        return 'Ajuste ou Remanejamento de Horário';
      case LessonCancellationReason.other:
        return 'Outro Motivo';
    }
  }

  String get description {
    switch (this) {
      case LessonCancellationReason.schoolEvent:
        return 'Atividade do calendário escolar, evento letivo ou conselho de classe.';
      case LessonCancellationReason.teacherAbsence:
        return 'Ausência justificada, licença médica ou compromisso externo do docente.';
      case LessonCancellationReason.studentAbsenceOrSuspension:
        return 'Falta coletiva de estudantes, suspensão formal de aulas ou paralisação.';
      case LessonCancellationReason.infrastructureIssue:
        return 'Interrupção por motivos de força maior, falta de insumos essenciais ou condições climáticas.';
      case LessonCancellationReason.pedagogicalAdjustment:
        return 'Ajuste de grade semanal ou substituição pedagógica determinada pela coordenação.';
      case LessonCancellationReason.other:
        return 'Outro motivo pedagógico ou institucional detalhado pelo professor.';
    }
  }
}

/// Exceção de validação de regras de negócio de registro de aula.
class LessonExecutionValidationException implements Exception {
  const LessonExecutionValidationException(this.message);

  final String message;

  @override
  String toString() => 'LessonExecutionValidationException: $message';
}

/// Entidade de domínio representando o fato histórico da execução real de uma aula.
///
/// Mantém separação semântica estrita da [PlannedLesson]: enquanto a aula planejada
/// representa o cronograma projetado no calendário, o [LessonExecutionRecord] representa
/// o diário pedagógico fático (se ocorreu, o que foi ministrado e intercorrências).
class LessonExecutionRecord {
  LessonExecutionRecord({
    required this.id,
    required this.plannedLessonId,
    required this.classroomSubjectId,
    required DateTime executionDate,
    required this.status,
    this.actualContentIds = const [],
    this.cancellationReason,
    this.cancellationDetails,
    this.pedagogicalNotes,
    this.needsFollowUp = false,
    this.followUpNotes,
    required this.recordedAt,
    this.updatedAt,
  }) : executionDate = DateTime.utc(
         executionDate.year,
         executionDate.month,
         executionDate.day,
       ) {
    validate();
  }

  /// Identificador único e estável (UUID).
  final String id;

  /// Vínculo à aula planejada no calendário escolar.
  final String plannedLessonId;

  /// Vínculo com a disciplina na turma correspondente.
  final String classroomSubjectId;

  /// Data de referência da realização da aula (normalizada sem horário, em UTC).
  final DateTime executionDate;

  /// Status fático da aula (completed, partiallyCompleted, notHeld).
  ///
  /// O status `planned` é proibido nesta entidade, pois a ausência de registro
  /// já denota que a aula continua em estado planejado.
  final LessonExecutionStatus status;

  /// Identificadores dos conteúdos programáticos efetivamente ministrados.
  final List<String> actualContentIds;

  /// Categoria padronizada de motivo caso a aula não tenha sido realizada.
  final LessonCancellationReason? cancellationReason;

  /// Detalhes ou justificativa textual adicional para o cancelamento.
  final String? cancellationDetails;

  /// Anotações pedagógicas do professor sobre o andamento da aula.
  final String? pedagogicalNotes;

  /// Sinalização de que esta aula requer continuidade em aula subsequente.
  final bool needsFollowUp;

  /// Detalhes ou anotações específicas sobre a continuidade pedagógica necessária.
  final String? followUpNotes;

  /// Timestamp da criação original do registro.
  final DateTime recordedAt;

  /// Timestamp da última retificação ou edição do registro.
  final DateTime? updatedAt;

  /// Indica se o registro foi retificado após sua gravação original.
  bool get isRectified => updatedAt != null;

  /// Retorna se a aula teve atividade pedagógica real (total ou parcial).
  bool get isHeld =>
      status == LessonExecutionStatus.completed ||
      status == LessonExecutionStatus.partiallyCompleted;

  /// Executa todas as regras de validação invariantes do domínio.
  void validate() {
    if (id.trim().isEmpty) {
      throw const LessonExecutionValidationException(
        'O identificador do registro de execução não pode ser vazio.',
      );
    }
    if (plannedLessonId.trim().isEmpty) {
      throw const LessonExecutionValidationException(
        'O vínculo com a aula planejada é obrigatório.',
      );
    }
    if (classroomSubjectId.trim().isEmpty) {
      throw const LessonExecutionValidationException(
        'O vínculo com a disciplina da turma é obrigatório.',
      );
    }

    if (status == LessonExecutionStatus.planned) {
      throw const LessonExecutionValidationException(
        'Um registro de execução não pode possuir status "planned". '
        'Aulas ainda não realizadas não devem possuir registro.',
      );
    }

    // Valida unicidade na lista de conteúdos ministrados
    final uniqueContentIds = actualContentIds.toSet();
    if (uniqueContentIds.length != actualContentIds.length) {
      throw const LessonExecutionValidationException(
        'A lista de conteúdos ministrados contém referências duplicadas.',
      );
    }

    // Regras para aula não realizada
    if (status == LessonExecutionStatus.notHeld) {
      if (actualContentIds.isNotEmpty) {
        throw const LessonExecutionValidationException(
          'Aulas não realizadas não podem conter conteúdos ministrados.',
        );
      }
      if (cancellationReason == null) {
        throw const LessonExecutionValidationException(
          'Aulas não realizadas exigem a indicação de um motivo padronizado.',
        );
      }
    }

    // Regras para aula parcialmente realizada
    if (status == LessonExecutionStatus.partiallyCompleted) {
      final hasContents = actualContentIds.isNotEmpty;
      final hasNotes =
          pedagogicalNotes != null && pedagogicalNotes!.trim().isNotEmpty;
      final hasFollowUp = needsFollowUp;

      if (!hasContents && !hasNotes && !hasFollowUp) {
        throw const LessonExecutionValidationException(
          'Aulas parcialmente realizadas devem conter ao menos um conteúdo ministrado, '
          'observações pedagógicas ou indicação de continuidade necessária.',
        );
      }
    }

    // Valida coerência temporal entre criação e retificação
    if (updatedAt != null && updatedAt!.isBefore(recordedAt)) {
      throw const LessonExecutionValidationException(
        'A data de retificação (updatedAt) não pode ser anterior à data de criação (recordedAt).',
      );
    }
  }

  LessonExecutionRecord copyWith({
    String? id,
    String? plannedLessonId,
    String? classroomSubjectId,
    DateTime? executionDate,
    LessonExecutionStatus? status,
    List<String>? actualContentIds,
    LessonCancellationReason? cancellationReason,
    String? cancellationDetails,
    String? pedagogicalNotes,
    bool? needsFollowUp,
    String? followUpNotes,
    DateTime? recordedAt,
    DateTime? updatedAt,
  }) {
    return LessonExecutionRecord(
      id: id ?? this.id,
      plannedLessonId: plannedLessonId ?? this.plannedLessonId,
      classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
      executionDate: executionDate ?? this.executionDate,
      status: status ?? this.status,
      actualContentIds: actualContentIds ?? this.actualContentIds,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationDetails: cancellationDetails ?? this.cancellationDetails,
      pedagogicalNotes: pedagogicalNotes ?? this.pedagogicalNotes,
      needsFollowUp: needsFollowUp ?? this.needsFollowUp,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LessonExecutionRecord) return false;

    if (other.id != id ||
        other.plannedLessonId != plannedLessonId ||
        other.classroomSubjectId != classroomSubjectId ||
        other.executionDate != executionDate ||
        other.status != status ||
        other.cancellationReason != cancellationReason ||
        other.cancellationDetails != cancellationDetails ||
        other.pedagogicalNotes != pedagogicalNotes ||
        other.needsFollowUp != needsFollowUp ||
        other.followUpNotes != followUpNotes ||
        other.recordedAt != recordedAt ||
        other.updatedAt != updatedAt) {
      return false;
    }

    if (other.actualContentIds.length != actualContentIds.length) return false;
    for (int i = 0; i < actualContentIds.length; i++) {
      if (other.actualContentIds[i] != actualContentIds[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    plannedLessonId,
    classroomSubjectId,
    executionDate,
    status,
    Object.hashAll(actualContentIds),
    cancellationReason,
    cancellationDetails,
    pedagogicalNotes,
    needsFollowUp,
    followUpNotes,
    recordedAt,
    updatedAt,
  );
}
