import 'change_dto.dart';

/// DTO de resposta paginada do endpoint de Pull incremental.
///
/// Espelha o contrato `PullResponseDto` do backend NestJS.
class PullResponseDto {
  const PullResponseDto({
    required this.epoch,
    required this.currentServerSeq,
    required this.nextCursor,
    required this.hasMore,
    required this.changes,
  });

  /// Época ativa da conta no servidor (string decimal).
  final String epoch;

  /// Sequência máxima atual comutada no histórico do usuário no servidor.
  final String currentServerSeq;

  /// Cursor composto para solicitar a próxima página ('${serverSeq}:${id}').
  final String nextCursor;

  /// Indicador de existência de mais eventos além da página atual.
  final bool hasMore;

  /// Lista de deltas de alteração contidos na página atual.
  final List<ChangeDto> changes;

  factory PullResponseDto.fromJson(Map<String, dynamic> json) {
    return PullResponseDto(
      epoch: json['epoch'] as String,
      currentServerSeq: json['currentServerSeq'] as String,
      nextCursor: json['nextCursor'] as String,
      hasMore: json['hasMore'] as bool,
      changes: (json['changes'] as List<dynamic>)
          .map((e) => ChangeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'epoch': epoch,
      'currentServerSeq': currentServerSeq,
      'nextCursor': nextCursor,
      'hasMore': hasMore,
      'changes': changes.map((c) => c.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PullResponseDto &&
          runtimeType == other.runtimeType &&
          epoch == other.epoch &&
          currentServerSeq == other.currentServerSeq &&
          nextCursor == other.nextCursor &&
          hasMore == other.hasMore &&
          changes.length == other.changes.length;

  @override
  int get hashCode =>
      Object.hash(epoch, currentServerSeq, nextCursor, hasMore, changes.length);
}
