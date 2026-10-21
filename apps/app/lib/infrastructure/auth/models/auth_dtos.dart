import 'package:flutter/foundation.dart';

import '../../../domain/models/auth_user.dart';
import '../exceptions/auth_exceptions.dart';

/// DTO de requisição para cadastro de novo usuário.
/// Endpoint: `POST /api/auth/register`
@immutable
class RegisterRequestDto {
  const RegisterRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  /// Validação defensiva nos limites do sistema antes de despachar a requisição.
  void validate() {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty ||
        !trimmedEmail.contains('@') ||
        !trimmedEmail.contains('.')) {
      throw const AuthValidationException('Formato de e-mail inválido.');
    }
    if (password.length < 8) {
      throw const AuthValidationException(
        'A senha deve conter no mínimo 8 caracteres.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
  };

  @override
  String toString() =>
      'RegisterRequestDto(email: ${email.trim().toLowerCase()}, password: [PROTECTED])';
}

/// DTO de requisição para login de usuário existente.
/// Endpoint: `POST /api/auth/login`
@immutable
class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  /// Validação defensiva nos limites do sistema antes de despachar a requisição.
  void validate() {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw const AuthValidationException('Formato de e-mail inválido.');
    }
    if (password.isEmpty) {
      throw const AuthValidationException('A senha é obrigatória.');
    }
  }

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
  };

  @override
  String toString() =>
      'LoginRequestDto(email: ${email.trim().toLowerCase()}, password: [PROTECTED])';
}

/// DTO canônico de resposta para register e login.
/// Resposta padrão do backend: `{ "accessToken": string, "user": { "id": string, "email": string } }`
@immutable
class AuthResponseDto {
  const AuthResponseDto({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] as String?;
    if (token == null || token.trim().isEmpty) {
      throw const AuthFormatException(
        'Resposta de autenticação sem accessToken válido.',
      );
    }

    final userMap = json['user'] as Map<String, dynamic>?;
    if (userMap == null) {
      throw const AuthFormatException(
        'Resposta de autenticação sem objeto user.',
      );
    }

    return AuthResponseDto(
      accessToken: token.trim(),
      user: AuthUser.fromJson(userMap),
    );
  }

  @override
  String toString() =>
      'AuthResponseDto(user: ${user.email}, accessToken: [PROTECTED])';
}
