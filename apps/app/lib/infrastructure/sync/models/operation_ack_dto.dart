/// Detalhes estruturados de um conflito concorrente rejeitado pelo backend.
class ConflictDetailsDto {
  const ConflictDetailsDto({
    required this.reason,
    this.serverVersion,
    this.clientVersion,
  });

  final String reason;
  final Map<String, dynamic>? serverVersion;
  final Map<String, dynamic>? clientVersion;

  factory ConflictDetailsDto.fromJson(Map<String, dynamic> json) {
    return ConflictDetailsDto(
      reason: json['reason'] as String? ?? 'UNKNOWN_CONFLICT',
      serverVersion: json['serverVersion'] as Map<String, dynamic>?,
      clientVersion: json['clientVersion'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      if (serverVersion != null) 'serverVersion': serverVersion,
      if (clientVersion != null) 'clientVersion': clientVersion,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConflictDetailsDto &&
          runtimeType == other.runtimeType &&
          reason == other.reason;

  @override
  int get hashCode => reason.hashCode;
}

/// DTO de confirmação (ACK) individual de operação retornado pelo backend.
///
/// Espelha o contrato `OperationAckDto` do servidor NestJS.
class OperationAckDto {
  const OperationAckDto({
    required this.clientOpId,
    required this.status,
    required this.serverSeq,
    required this.appliedAt,
    this.conflict,
  });

  /// Identificador UUID da operação correspondente.
  final String clientOpId;

  /// Status do ACK: 'APPLIED', 'SKIPPED' ou 'CONFLICT'.
  final String status;

  /// Sequência atribuída ou associada pelo servidor (string decimal de BIGINT).
  final String serverSeq;

  /// Timestamp UTC de comutação do recibo no servidor.
  final DateTime appliedAt;

  /// Detalhes de conflito, caso o status seja CONFLICT.
  final ConflictDetailsDto? conflict;

  bool get isApplied => status == 'APPLIED';
  bool get isSkipped => status == 'SKIPPED';
  bool get isConflict => status == 'CONFLICT';

  factory OperationAckDto.fromJson(Map<String, dynamic> json) {
    return OperationAckDto(
      clientOpId: json['clientOpId'] as String,
      status: json['status'] as String,
      serverSeq: json['serverSeq'] as String,
      appliedAt: DateTime.parse(json['appliedAt'] as String).toUtc(),
      conflict: json['conflict'] != null
          ? ConflictDetailsDto.fromJson(
              json['conflict'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientOpId': clientOpId,
      'status': status,
      'serverSeq': serverSeq,
      'appliedAt': appliedAt.toUtc().toIso8601String(),
      'conflict': conflict?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationAckDto &&
          runtimeType == other.runtimeType &&
          clientOpId == other.clientOpId &&
          status == other.status &&
          serverSeq == other.serverSeq &&
          appliedAt == other.appliedAt &&
          conflict == other.conflict;

  @override
  int get hashCode =>
      Object.hash(clientOpId, status, serverSeq, appliedAt, conflict);
}
