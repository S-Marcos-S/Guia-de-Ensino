/// DTO que representa um delta de alteração registrado no servidor retornado via Pull.
///
/// Espelha o contrato `ChangeDto` do backend NestJS.
class ChangeDto {
  const ChangeDto({
    required this.serverSeq,
    required this.changeLogId,
    required this.entityType,
    required this.entityId,
    required this.mutationType,
    required this.payload,
    required this.deviceId,
    required this.createdAt,
  });

  /// Sequência estritamente monotônica do usuário no servidor (string decimal).
  final String serverSeq;

  /// ID sequencial único da linha de log de alterações no PostgreSQL (string decimal).
  final String changeLogId;

  /// Tipo canônico da entidade (ex: 'academic_year', 'classroom', etc.).
  final String entityType;

  /// Identificador da entidade (UUID ou tupla '${id1}:${id2}').
  final String entityId;

  /// Tipo de mutação ('INSERT', 'UPDATE', 'DELETE').
  final String mutationType;

  /// Payload com os dados da entidade em snake_case (nulo em exclusões).
  final Map<String, dynamic>? payload;

  /// Identificador do dispositivo originador da alteração.
  final String deviceId;

  /// Timestamp UTC de gravação do evento no servidor.
  final DateTime createdAt;

  factory ChangeDto.fromJson(Map<String, dynamic> json) {
    return ChangeDto(
      serverSeq: json['serverSeq'] as String,
      changeLogId: json['changeLogId'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      mutationType: json['mutationType'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      deviceId: json['deviceId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverSeq': serverSeq,
      'changeLogId': changeLogId,
      'entityType': entityType,
      'entityId': entityId,
      'mutationType': mutationType,
      'payload': payload,
      'deviceId': deviceId,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeDto &&
          runtimeType == other.runtimeType &&
          serverSeq == other.serverSeq &&
          changeLogId == other.changeLogId &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          mutationType == other.mutationType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => Object.hash(
    serverSeq,
    changeLogId,
    entityType,
    entityId,
    mutationType,
    deviceId,
  );
}
