/// Parâmetros de consulta para o endpoint de Pull paginado.
///
/// Espelha o contrato `PullQueryDto` do backend NestJS.
class PullQueryDto {
  const PullQueryDto({
    this.cursor,
    this.limit = 100,
    this.excludeDeviceId,
    this.clientEpoch,
  });

  /// Cursor composto no formato '${serverSeq}:${id}'. Se nulo, assume '0:0'.
  final String? cursor;

  /// Limite máximo de itens por página (entre 1 e 500, padrão 100).
  final int limit;

  /// Identificador do próprio dispositivo para descarte de eco pelo servidor.
  final String? excludeDeviceId;

  /// Época ativa conhecida pelo cliente para validação de integridade.
  final String? clientEpoch;

  Map<String, String> toQueryParams() {
    return {
      if (cursor != null) 'cursor': cursor!,
      'limit': limit.toString(),
      if (excludeDeviceId != null) 'excludeDeviceId': excludeDeviceId!,
      if (clientEpoch != null) 'clientEpoch': clientEpoch!,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PullQueryDto &&
          runtimeType == other.runtimeType &&
          cursor == other.cursor &&
          limit == other.limit &&
          excludeDeviceId == other.excludeDeviceId &&
          clientEpoch == other.clientEpoch;

  @override
  int get hashCode => Object.hash(cursor, limit, excludeDeviceId, clientEpoch);
}
