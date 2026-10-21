/// DTO que representa uma operação atômica de sincronização enviada na outbox (Push).
///
/// Espelha o contrato `SyncOperationDto` do backend NestJS.
class SyncOperationDto {
  const SyncOperationDto({
    required this.clientOpId,
    required this.entityType,
    required this.entityId,
    required this.mutationType,
    this.baseSeq,
    this.clientCreatedAt,
    this.payload,
  });

  /// Identificador UUID v4 universalmente único e estável da operação.
  final String clientOpId;

  /// Tipo canônico da entidade (ex: 'academic_year', 'classroom', etc.).
  final String entityType;

  /// Identificador único da entidade (UUID ou tupla '${id1}:${id2}' para tabelas associativas).
  final String entityId;

  /// Tipo de mutação ('INSERT', 'UPDATE', 'DELETE').
  final String mutationType;

  /// Sequência base do servidor sobre a qual a alteração local foi gerada (opcional).
  final String? baseSeq;

  /// Timestamp UTC de criação da mutação no cliente.
  final DateTime? clientCreatedAt;

  /// Payload com dados relacionais serializados em snake_case (nulo em DELETE).
  final Map<String, dynamic>? payload;

  factory SyncOperationDto.fromJson(Map<String, dynamic> json) {
    return SyncOperationDto(
      clientOpId: json['clientOpId'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      mutationType: json['mutationType'] as String,
      baseSeq: json['baseSeq'] as String?,
      clientCreatedAt: json['clientCreatedAt'] != null
          ? DateTime.parse(json['clientCreatedAt'] as String).toUtc()
          : null,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientOpId': clientOpId,
      'entityType': entityType,
      'entityId': entityId,
      'mutationType': mutationType,
      if (baseSeq != null) 'baseSeq': baseSeq,
      if (clientCreatedAt != null)
        'clientCreatedAt': clientCreatedAt!.toUtc().toIso8601String(),
      if (payload != null) 'payload': payload,
    };
  }

  SyncOperationDto copyWith({
    String? clientOpId,
    String? entityType,
    String? entityId,
    String? mutationType,
    String? baseSeq,
    DateTime? clientCreatedAt,
    Map<String, dynamic>? payload,
  }) {
    return SyncOperationDto(
      clientOpId: clientOpId ?? this.clientOpId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      mutationType: mutationType ?? this.mutationType,
      baseSeq: baseSeq ?? this.baseSeq,
      clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
      payload: payload ?? this.payload,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationDto &&
          runtimeType == other.runtimeType &&
          clientOpId == other.clientOpId &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          mutationType == other.mutationType &&
          baseSeq == other.baseSeq &&
          clientCreatedAt == other.clientCreatedAt;

  @override
  int get hashCode => Object.hash(
    clientOpId,
    entityType,
    entityId,
    mutationType,
    baseSeq,
    clientCreatedAt,
  );
}
