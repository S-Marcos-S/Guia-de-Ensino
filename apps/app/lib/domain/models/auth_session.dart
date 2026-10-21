import 'package:flutter/foundation.dart';

import 'auth_user.dart';

/// Representação de uma sessão ativa autenticada no aplicativo.
///
/// Protege o token JWT em tempo de execução, garantindo que
/// [toString] nunca exponha o segredo em logs ou mensagens de depuração.
@immutable
class AuthSession {
  const AuthSession({required this.token, required this.user});

  /// Token JWT Bearer emitido pelo backend.
  final String token;

  /// Usuário associado a esta sessão.
  final AuthUser user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          user == other.user;

  @override
  int get hashCode => Object.hash(token, user);

  @override
  String toString() => 'AuthSession(user: ${user.email}, token: [PROTECTED])';
}
