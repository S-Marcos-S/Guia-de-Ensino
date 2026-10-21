import 'dart:async';

import '../../../domain/models/auth_session.dart';
import '../../../domain/models/auth_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../client/auth_api_client.dart';
import '../exceptions/auth_exceptions.dart';
import '../models/auth_dtos.dart';
import '../storage/token_storage.dart';

/// Implementação concreta de [AuthRepository] integrando [AuthApiClient] e [TokenStorage].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.apiClient, required this.tokenStorage});

  final AuthApiClient apiClient;
  final TokenStorage tokenStorage;

  final StreamController<AuthSession?> _sessionController =
      StreamController<AuthSession?>.broadcast();

  AuthSession? _currentSession;
  AuthUser? _cachedUser;

  @override
  AuthSession? get currentSession => _currentSession;

  @override
  bool get isAuthenticated => _currentSession != null;

  @override
  Stream<AuthSession?> get sessionStream => _sessionController.stream;

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      _currentSession = null;
      _sessionController.add(null);
      return null;
    }

    try {
      final user = await apiClient.getProfile(token);
      _cachedUser = user;
      final session = AuthSession(token: token, user: user);
      _currentSession = session;
      _sessionController.add(session);
      return session;
    } on InvalidCredentialsException {
      // Token expirado ou revogado no servidor: limpa armazenamento
      await tokenStorage.deleteToken();
      _cachedUser = null;
      _currentSession = null;
      _sessionController.add(null);
      return null;
    } on AuthNetworkException {
      // Em caso de falha de rede (offline), se tivermos o usuário em cache,
      // restaura a sessão offline preservando o token persistido
      if (_cachedUser != null) {
        final session = AuthSession(token: token, user: _cachedUser!);
        _currentSession = session;
        _sessionController.add(session);
        return session;
      }
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.login(
      LoginRequestDto(email: email, password: password),
    );

    await tokenStorage.writeToken(response.accessToken);
    _cachedUser = response.user;

    final session = AuthSession(
      token: response.accessToken,
      user: response.user,
    );

    _currentSession = session;
    _sessionController.add(session);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.register(
      RegisterRequestDto(email: email, password: password),
    );

    await tokenStorage.writeToken(response.accessToken);
    _cachedUser = response.user;

    final session = AuthSession(
      token: response.accessToken,
      user: response.user,
    );

    _currentSession = session;
    _sessionController.add(session);
    return session;
  }

  @override
  Future<AuthUser> fetchCurrentUser() async {
    final session = _currentSession;
    if (session == null) {
      throw const UnauthenticatedException();
    }

    final user = await apiClient.getProfile(session.token);
    _cachedUser = user;
    if (user != session.user) {
      _currentSession = AuthSession(token: session.token, user: user);
      _sessionController.add(_currentSession);
    }
    return user;
  }

  @override
  Future<void> logout() async {
    await tokenStorage.deleteToken();
    _currentSession = null;
    _cachedUser = null;
    _sessionController.add(null);
  }

  @override
  void dispose() {
    _sessionController.close();
  }
}
