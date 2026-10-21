import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../domain/models/auth_user.dart';
import '../exceptions/auth_exceptions.dart';
import '../models/auth_dtos.dart';

/// Cliente HTTP especializado na comunicação com os endpoints de autenticação do backend NestJS.
///
/// Encapsula:
/// 1. `POST /api/auth/register` (cadastro de novo usuário).
/// 2. `POST /api/auth/login` (autenticação de usuário).
/// 3. `GET /api/auth/me` (consulta do perfil autenticado via Bearer token).
/// 4. Mapeamento estrito e tipado de respostas, status HTTP e falhas de rede.
/// 5. Sigilo estrito de tokens: nenhuma credencial ou token é impresso em logs de erro.
class AuthApiClient {
  AuthApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;
  final Duration timeout;

  static String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Registra um novo usuário no backend.
  /// Endpoint: `POST /api/auth/register`
  Future<AuthResponseDto> register(RegisterRequestDto request) async {
    request.validate();

    final uri = Uri.parse('$_baseUrl/api/auth/register');
    final body = jsonEncode(request.toJson());

    final response = await _executeWithHandling(
      () => _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeout),
      contextDescription: 'POST /api/auth/register',
    );

    _validateResponseStatus(response, 'Cadastro');

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponseDto.fromJson(decoded);
    } on FormatException catch (e) {
      throw AuthFormatException(
        'Resposta do servidor não é um JSON válido: ${e.message}',
        statusCode: response.statusCode,
        originalError: e,
      );
    }
  }

  /// Realiza login de um usuário existente.
  /// Endpoint: `POST /api/auth/login`
  Future<AuthResponseDto> login(LoginRequestDto request) async {
    request.validate();

    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final body = jsonEncode(request.toJson());

    final response = await _executeWithHandling(
      () => _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeout),
      contextDescription: 'POST /api/auth/login',
    );

    _validateResponseStatus(response, 'Login');

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponseDto.fromJson(decoded);
    } on FormatException catch (e) {
      throw AuthFormatException(
        'Resposta do servidor não é um JSON válido: ${e.message}',
        statusCode: response.statusCode,
        originalError: e,
      );
    }
  }

  /// Obtém o perfil do usuário atualmente autenticado a partir do Bearer Token.
  /// Endpoint: `GET /api/auth/me`
  Future<AuthUser> getProfile(String token) async {
    if (token.trim().isEmpty) {
      throw const UnauthenticatedException('Token de autenticação ausente.');
    }

    final uri = Uri.parse('$_baseUrl/api/auth/me');

    final response = await _executeWithHandling(
      () => _httpClient
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer ${token.trim()}',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout),
      contextDescription: 'GET /api/auth/me',
    );

    _validateResponseStatus(response, 'Consulta de Perfil');

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthUser.fromJson(decoded);
    } on FormatException catch (e) {
      throw AuthFormatException(
        'Resposta do servidor não é um JSON válido: ${e.message}',
        statusCode: response.statusCode,
        originalError: e,
      );
    }
  }

  Future<http.Response> _executeWithHandling(
    Future<http.Response> Function() action, {
    required String contextDescription,
  }) async {
    try {
      return await action();
    } on SocketException catch (e) {
      throw AuthNetworkException(
        'Falha de conexão com o servidor de autenticação ($contextDescription). Verifique sua internet.',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw AuthNetworkException(
        'Tempo limite esgotado ao contatar o servidor de autenticação ($contextDescription).',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw AuthNetworkException(
        'Erro na comunicação HTTP com o servidor ($contextDescription).',
        originalError: e,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthNetworkException(
        'Erro inesperado na requisição HTTP ($contextDescription): $e',
        originalError: e,
      );
    }
  }

  void _validateResponseStatus(http.Response response, String operation) {
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      return;
    }

    String serverMessage = '';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String) {
          serverMessage = msg;
        } else if (msg is List) {
          serverMessage = msg.join(' ');
        }
      }
    } catch (_) {
      // Se não for JSON, ignora e usa mensagem padrão
    }

    if (status == 401) {
      throw InvalidCredentialsException(
        serverMessage.isNotEmpty ? serverMessage : 'Credenciais inválidas.',
        status,
      );
    }

    if (status == 409) {
      throw EmailAlreadyInUseException(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'Já existe um usuário cadastrado com este e-mail.',
        status,
      );
    }

    if (status == 400) {
      throw AuthValidationException(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'Dados inválidos fornecidos para $operation.',
        statusCode: status,
      );
    }

    if (status >= 500) {
      throw AuthServerException(
        'Erro interno no servidor ($status) durante $operation: $serverMessage',
        statusCode: status,
      );
    }

    throw AuthServerException(
      'Resposta inesperada do servidor ($status) durante $operation: $serverMessage',
      statusCode: status,
    );
  }
}
