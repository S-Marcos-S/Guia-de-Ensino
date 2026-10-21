import 'sync_operation_dto.dart';

/// DTO de envelope de requisição de sincronização por lote (Push).
///
/// Espelha o contrato `PushRequestDto` do backend NestJS.
class PushRequestDto {
  const PushRequestDto({
    required this.deviceId,
    required this.clientBatchId,
    required this.operations,
  });

  /// Identificador persistente do dispositivo cliente.
  final String deviceId;

  /// Identificador UUID v4 exclusivo do lote de transmissão.
  final String clientBatchId;

  /// Lote de 1 a 100 operações de sincronização ordenadas causalmente.
  final List<SyncOperationDto> operations;

  /// Valida as restrições estruturais exigidas pelo contrato do backend antes do envio:
  /// 1. Pelo menos 1 operação.
  /// 2. Máximo de 100 operações.
  /// 3. clientOpIds estritamente únicos dentro do lote.
  void validate() {
    if (operations.isEmpty) {
      throw ArgumentError.value(
        operations,
        'operations',
        'O lote de sincronização deve conter pelo menos 1 operação.',
      );
    }
    if (operations.length > 100) {
      throw ArgumentError.value(
        operations.length,
        'operations',
        'O lote de sincronização não pode exceder o teto máximo de 100 operações.',
      );
    }
    final seen = <String>{};
    for (final op in operations) {
      if (seen.contains(op.clientOpId)) {
        throw ArgumentError(
          'Identificadores de operação duplicados no mesmo lote: clientOpId '
          "'${op.clientOpId}' repetido não é permitido.",
        );
      }
      seen.add(op.clientOpId);
    }
  }

  factory PushRequestDto.fromJson(Map<String, dynamic> json) {
    return PushRequestDto(
      deviceId: json['deviceId'] as String,
      clientBatchId: json['clientBatchId'] as String,
      operations: (json['operations'] as List<dynamic>)
          .map((e) => SyncOperationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'clientBatchId': clientBatchId,
      'operations': operations.map((op) => op.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushRequestDto &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          clientBatchId == other.clientBatchId &&
          operations.length == other.operations.length;

  @override
  int get hashCode => Object.hash(deviceId, clientBatchId, operations.length);
}
