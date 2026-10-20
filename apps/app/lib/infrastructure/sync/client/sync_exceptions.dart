/// Exceção base para todas as falhas ocorridas no protocolo de sincronização.
sealed class SyncException implements Exception {
  const SyncException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (statusCode != null) buffer.write(' (HTTP $statusCode)');
    if (errorCode != null) buffer.write(' [Code: $errorCode]');
    return buffer.toString();
  }
}

/// Falha de conectividade de rede, resolução de DNS ou queda de socket.
class SyncNetworkException extends SyncException {
  const SyncNetworkException(super.message, {super.details});
}

/// Tempo limite de comunicação com o servidor esgotado (timeout).
class SyncTimeoutException extends SyncException {
  const SyncTimeoutException(super.message, {super.details});
}

/// Falha de autenticação (HTTP 401 Unauthorized): token JWT expirado ou ausente.
class SyncUnauthorizedException extends SyncException {
  const SyncUnauthorizedException(
    super.message, {
    super.statusCode = 401,
    super.errorCode = 'UNAUTHORIZED',
    super.details,
  });
}

/// Requisição malformada ou inválida rejeitada pelo servidor (HTTP 400 Bad Request).
class SyncBadRequestException extends SyncException {
  const SyncBadRequestException(
    super.message, {
    super.statusCode = 400,
    super.errorCode,
    super.details,
  });
}

/// Cursor composto inválido, negativo ou futuro rejeitado pelo backend (HTTP 400 INVALID_CURSOR).
class SyncInvalidCursorException extends SyncBadRequestException {
  const SyncInvalidCursorException(
    super.message, {
    this.requestedSeq,
    this.currentServerSeq,
    super.details,
  }) : super(errorCode: 'INVALID_CURSOR');

  final String? requestedSeq;
  final String? currentServerSeq;
}

/// Conflito concorrente ou divergência de idempotência rejeitado pelo servidor (HTTP 409 Conflict).
class SyncConflictException extends SyncException {
  const SyncConflictException(
    super.message, {
    super.statusCode = 409,
    super.errorCode,
    this.conflictReason,
    this.clientOpId,
    super.details,
  });

  final String? conflictReason;
  final String? clientOpId;
}

/// Época de sincronização divergente entre cliente e servidor (HTTP 410 Gone / RESYNC_REQUIRED).
///
/// Sinaliza formalmente ao cliente a obrigatoriedade de reiniciar o estado via Full Resync (Snapshot).
class SyncResyncRequiredException extends SyncException {
  const SyncResyncRequiredException(
    super.message, {
    this.serverEpoch,
    super.statusCode = 410,
    super.errorCode = 'RESYNC_REQUIRED',
    super.details,
  });

  final String? serverEpoch;
}

/// Token de snapshot expirado (TTL de 15 minutos esgotado) (HTTP 410 Gone / SNAPSHOT_EXPIRED).
class SyncSnapshotExpiredException extends SyncException {
  const SyncSnapshotExpiredException(
    super.message, {
    super.statusCode = 410,
    super.errorCode = 'SNAPSHOT_EXPIRED',
    super.details,
  });
}

/// Violação de integridade fática ou regras sagradas de diário de classe (HTTP 422 Unprocessable Entity).
class SyncFactualIntegrityException extends SyncException {
  const SyncFactualIntegrityException(
    super.message, {
    super.statusCode = 422,
    super.errorCode = 'FACTUAL_INTEGRITY_VIOLATION',
    super.details,
  });
}

/// Erro interno do servidor (HTTP 500 ou 5xx) ou resposta inesperada.
class SyncServerException extends SyncException {
  const SyncServerException(
    super.message, {
    super.statusCode = 500,
    super.errorCode,
    super.details,
  });
}
