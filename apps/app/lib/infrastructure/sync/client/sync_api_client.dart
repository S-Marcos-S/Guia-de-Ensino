import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/pull_query_dto.dart';
import '../models/pull_response_dto.dart';
import '../models/push_request_dto.dart';
import '../models/push_response_dto.dart';
import '../models/snapshot_response_dto.dart';
import 'sync_exceptions.dart';

/// Cliente HTTP de alta confiabilidade para comunicação com a API de sincronização do Guia de Ensino.
///
/// Encapsula:
/// 1. Autenticação JWT via Bearer Token.
/// 2. Timeouts explícitos em todas as operações de transporte.
/// 3. Mapeamento tipado e sanitizado de códigos HTTP e exceções de rede.
/// 4. Validação estrutural de DTOs antes do despacho de envelopes.
class SyncApiClient {
  SyncApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
    this.tokenProvider,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;
  final Duration timeout;

  /// Provedor assíncrono ou síncrono do token JWT ativo do usuário.
  final FutureOr<String?> Function()? tokenProvider;

  static String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Despacha um lote de operações locais para o backend (Push).
  ///
  /// Endpoint: `POST /api/sync/push`
  Future<PushResponseDto> push(PushRequestDto request) async {
    request.validate();

    final uri = Uri.parse('$_baseUrl/api/sync/push');
    final headers = await _buildHeaders();
    final body = jsonEncode(request.toJson());

    final response = await _executeWithHandling(
      () =>
          _httpClient.post(uri, headers: headers, body: body).timeout(timeout),
      contextDescription: 'POST /api/sync/push',
    );

    _validateResponseStatus(response, 'Push');

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return PushResponseDto.fromJson(decoded);
    } on FormatException catch (e) {
      throw SyncServerException(
        'Resposta do servidor não é um JSON válido: ${e.message}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Consulta uma página incremental de alterações registradas no servidor (Pull).
  ///
  /// Endpoint: `GET /api/sync/pull`
  Future<PullResponseDto> pull(PullQueryDto query) async {
    final baseUri = Uri.parse('$_baseUrl/api/sync/pull');
    final uri = baseUri.replace(queryParameters: query.toQueryParams());
    final headers = await _buildHeaders();

    final response = await _executeWithHandling(
      () => _httpClient.get(uri, headers: headers).timeout(timeout),
      contextDescription: 'GET /api/sync/pull',
    );

    _validateResponseStatus(response, 'Pull');

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return PullResponseDto.fromJson(decoded);
    } on FormatException catch (e) {
      throw SyncServerException(
        'Resposta do servidor não é um JSON válido: ${e.message}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Baixa o snapshot canônico consistente de todas as 13 coleções pedagógicas.
  ///
  /// Endpoint: `GET /api/sync/snapshot`
  Future<SnapshotResponseDto> getSnapshot({String? snapshotToken}) async {
    final baseUri = Uri.parse('$_baseUrl/api/sync/snapshot');
    final queryParams = <String, String>{
      if (snapshotToken != null && snapshotToken.isNotEmpty)
        'snapshotToken': snapshotToken,
    };
    final uri = queryParams.isNotEmpty
        ? baseUri.replace(queryParameters: queryParams)
        : baseUri;
    final headers = await _buildHeaders();

    final response = await _executeWithHandling(
      () => _httpClient.get(uri, headers: headers).timeout(timeout),
      contextDescription: 'GET /api/sync/snapshot',
    );

    _validateResponseStatus(response, 'Snapshot');

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return SnapshotResponseDto.fromJson(decoded);
    } on FormatException catch (e) {
      throw SyncServerException(
        'Resposta do servidor não é um JSON válido: ${e.message}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Fecha as conexões ativas do cliente HTTP subjacente.
  void close() {
    _httpClient.close();
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (tokenProvider != null) {
      final token = await tokenProvider!();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> _executeWithHandling(
    Future<http.Response> Function() action, {
    required String contextDescription,
  }) async {
    try {
      return await action();
    } on TimeoutException {
      throw SyncTimeoutException(
        'Tempo limite de comunicação ($timeout) excedido durante $contextDescription.',
      );
    } on SocketException catch (e) {
      throw SyncNetworkException(
        'Falha de conectividade ou socket durante $contextDescription: ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw SyncNetworkException(
        'Falha na comunicação HTTP durante $contextDescription: ${e.message}',
      );
    }
  }

  void _validateResponseStatus(
    http.Response response,
    String operationContext,
  ) {
    final statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    Map<String, dynamic>? errorBody;
    String? serverMessage;
    String? errorCode;

    try {
      if (response.body.isNotEmpty) {
        errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
        if (errorBody != null) {
          final rawMsg = errorBody['message'];
          if (rawMsg is List) {
            serverMessage = rawMsg.join('; ');
          } else if (rawMsg is String) {
            serverMessage = rawMsg;
          }
          errorCode = errorBody['code'] as String?;
        }
      }
    } catch (_) {
      // Ignora erro de parsing no corpo de erro e usa mensagem padrão
    }

    final effectiveMessage =
        serverMessage ??
        'Erro na operação $operationContext (HTTP $statusCode: ${response.reasonPhrase}).';

    switch (statusCode) {
      case 400:
        if (errorCode == 'INVALID_CURSOR') {
          throw SyncInvalidCursorException(
            effectiveMessage,
            requestedSeq: errorBody?['requestedSeq'] as String?,
            currentServerSeq: errorBody?['currentServerSeq'] as String?,
            details: errorBody,
          );
        }
        throw SyncBadRequestException(
          effectiveMessage,
          errorCode: errorCode,
          details: errorBody,
        );

      case 401:
        throw SyncUnauthorizedException(effectiveMessage, details: errorBody);

      case 409:
        throw SyncConflictException(
          effectiveMessage,
          errorCode: errorCode ?? (errorBody?['error'] as String?),
          conflictReason: errorBody?['reason'] as String?,
          clientOpId: errorBody?['clientOpId'] as String?,
          details: errorBody,
        );

      case 410:
        if (errorCode == 'SNAPSHOT_EXPIRED') {
          throw SyncSnapshotExpiredException(
            effectiveMessage,
            details: errorBody,
          );
        }
        // RESYNC_REQUIRED ou divergência de época
        throw SyncResyncRequiredException(
          effectiveMessage,
          serverEpoch: errorBody?['serverEpoch'] as String?,
          errorCode: errorCode ?? 'RESYNC_REQUIRED',
          details: errorBody,
        );

      case 422:
        throw SyncFactualIntegrityException(
          effectiveMessage,
          errorCode: errorCode ?? (errorBody?['error'] as String?),
          details: errorBody,
        );

      default:
        throw SyncServerException(
          effectiveMessage,
          statusCode: statusCode,
          errorCode: errorCode,
          details: errorBody,
        );
    }
  }
}
