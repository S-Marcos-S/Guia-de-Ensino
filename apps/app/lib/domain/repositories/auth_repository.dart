import '../models/auth_session.dart';
import '../models/auth_user.dart';

/// Contrato de domínio para o repositório de autenticação e gestão de sessão docente.
abstract interface class AuthRepository {
  /// Retorna a sessão ativa em memória, se houver.
  AuthSession? get currentSession;

  /// Indica se há uma sessão autenticada ativa no momento.
  bool get isAuthenticated;

  /// Stream reativo que emite atualizações no estado da sessão (login, logout, restauração).
  Stream<AuthSession?> get sessionStream;

  /// Restaura a sessão a partir do token persistido no armazenamento seguro.
  ///
  /// - Se o token for válido e o servidor confirmar via `getProfile`, restaura a sessão.
  /// - Se o token for rejeitado (401), limpa o armazenamento e encerra a sessão.
  /// - Se não houver token salvo, retorna `null`.
  Future<AuthSession?> restoreSession();

  /// Realiza login de usuário existente com e-mail e senha.
  Future<AuthSession> login({required String email, required String password});

  /// Cadastra um novo usuário com e-mail e senha.
  Future<AuthSession> register({
    required String email,
    required String password,
  });

  /// Consulta os dados atualizados do usuário autenticado no backend.
  Future<AuthUser> fetchCurrentUser();

  /// Encerra a sessão ativa e remove o token do armazenamento seguro.
  Future<void> logout();

  /// Libera recursos e encerra os controladores de stream.
  void dispose();
}
