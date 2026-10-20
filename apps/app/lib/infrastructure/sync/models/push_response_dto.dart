import 'operation_ack_dto.dart';

/// DTO de resposta de processamento do lote de sincronização (Push).
///
/// Espelha o contrato `PushResponseDto` do backend NestJS.
class PushResponseDto {
  const PushResponseDto({
    required this.clientBatchId,
    required this.serverEpoch,
    required this.currentServerSeq,
    required this.acks,
  });

  /// Identificador do lote processado no servidor.
  final String clientBatchId;

  /// Época ativa de sincronização da conta do usuário no servidor.
  final String serverEpoch;

  /// Sequência atual do servidor após a comutação do lote (string decimal de BIGINT).
  final String currentServerSeq;

  /// Lista ordenada de confirmações (ACKs) para cada operação do lote.
  final List<OperationAckDto> acks;

  factory PushResponseDto.fromJson(Map<String, dynamic> json) {
    return PushResponseDto(
      clientBatchId: json['clientBatchId'] as String,
      serverEpoch: json['serverEpoch'] as String,
      currentServerSeq: json['currentServerSeq'] as String,
      acks: (json['acks'] as List<dynamic>)
          .map((e) => OperationAckDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientBatchId': clientBatchId,
      'serverEpoch': serverEpoch,
      'currentServerSeq': currentServerSeq,
      'acks': acks.map((ack) => ack.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushResponseDto &&
          runtimeType == other.runtimeType &&
          clientBatchId == other.clientBatchId &&
          serverEpoch == other.serverEpoch &&
          currentServerSeq == other.currentServerSeq &&
          acks.length == other.acks.length;

  @override
  int get hashCode =>
      Object.hash(clientBatchId, serverEpoch, currentServerSeq, acks.length);
}
