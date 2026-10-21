import 'package:flutter/foundation.dart';

/// Representação de domínio de um usuário/docente autenticado no Guia de Ensino.
@immutable
class AuthUser {
  const AuthUser({required this.id, required this.email});

  /// Identificador único universal do usuário (UUID v4 gerado pelo servidor).
  final String id;

  /// E-mail do usuário normalizado em caixa baixa.
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['userId']) as String?;
    final email = json['email'] as String?;

    if (id == null || id.isEmpty) {
      throw const FormatException(
        'Objeto AuthUser sem identificador id/userId válido.',
      );
    }
    if (email == null || email.isEmpty) {
      throw const FormatException('Objeto AuthUser sem e-mail válido.');
    }

    return AuthUser(id: id, email: email.trim().toLowerCase());
  }

  Map<String, dynamic> toJson() => {'id': id, 'email': email};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, email);

  @override
  String toString() => 'AuthUser(id: $id, email: $email)';
}
