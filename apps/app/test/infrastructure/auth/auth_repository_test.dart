import 'dart:convert';

import 'package:app/domain/models/auth_session.dart';
import 'package:app/infrastructure/auth/client/auth_api_client.dart';
import 'package:app/infrastructure/auth/exceptions/auth_exceptions.dart';
import 'package:app/infrastructure/auth/repositories/auth_repository_impl.dart';
import 'package:app/infrastructure/auth/storage/in_memory_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const testBaseUrl = 'https://api.guiadeensino.test';
  const testEmail = 'professor@escola.gov.br';
  const testPassword = 'Password123!';
  const testToken = 'valid-jwt-token-777';
  const testUserId = 'user-uuid-999';

  group('AuthRepositoryImpl', () {
    test('deve realizar login, persistir token e emitir nova sessão', () async {
      final tokenStorage = InMemoryTokenStorage();

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'accessToken': testToken,
              'user': {'id': testUserId, 'email': testEmail},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final repository = AuthRepositoryImpl(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final emittedSessions = <AuthSession?>[];
      final sub = repository.sessionStream.listen(emittedSessions.add);

      expect(repository.isAuthenticated, isFalse);
      expect(repository.currentSession, isNull);

      final session = await repository.login(
        email: testEmail,
        password: testPassword,
      );

      expect(session.token, equals(testToken));
      expect(session.user.id, equals(testUserId));
      expect(session.user.email, equals(testEmail));
      expect(repository.isAuthenticated, isTrue);
      expect(repository.currentSession, equals(session));

      // Token deve ter sido persistido no storage
      expect(await tokenStorage.readToken(), equals(testToken));

      // Stream deve ter emitido a nova sessão
      await Future<void>.delayed(Duration.zero);
      expect(emittedSessions, contains(session));

      await sub.cancel();
      repository.dispose();
    });

    test(
      'deve realizar cadastro, persistir token e emitir nova sessão',
      () async {
        final tokenStorage = InMemoryTokenStorage();

        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/auth/register') {
            return http.Response(
              jsonEncode({
                'accessToken': testToken,
                'user': {'id': testUserId, 'email': testEmail},
              }),
              201,
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = AuthApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        final repository = AuthRepositoryImpl(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
        );

        final session = await repository.register(
          email: testEmail,
          password: testPassword,
        );

        expect(session.token, equals(testToken));
        expect(session.user.id, equals(testUserId));
        expect(await tokenStorage.readToken(), equals(testToken));

        repository.dispose();
      },
    );

    test('deve restaurar sessão se houver token válido persistido', () async {
      final tokenStorage = InMemoryTokenStorage(testToken);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          expect(request.headers['Authorization'], equals('Bearer $testToken'));
          return http.Response(
            jsonEncode({'userId': testUserId, 'email': testEmail}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final repository = AuthRepositoryImpl(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final restored = await repository.restoreSession();

      expect(restored, isNotNull);
      expect(restored!.token, equals(testToken));
      expect(restored.user.id, equals(testUserId));
      expect(repository.isAuthenticated, isTrue);

      repository.dispose();
    });

    test('deve limpar token se servidor rejeitar token persistido em restoreSession', () async {
      final tokenStorage = InMemoryTokenStorage('expired-token-xyz');

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({'statusCode': 401, 'message': 'Token expirado'}),
            401,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final repository = AuthRepositoryImpl(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final restored = await repository.restoreSession();

      expect(restored, isNull);
      expect(repository.isAuthenticated, isFalse);
      // Storage deve ter sido limpo
      expect(await tokenStorage.readToken(), isNull);

      repository.dispose();
    });

    test(
      'deve retornar null em restoreSession se não houver token no storage',
      () async {
        final tokenStorage = InMemoryTokenStorage();
        final apiClient = AuthApiClient(baseUrl: testBaseUrl);

        final repository = AuthRepositoryImpl(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
        );

        final restored = await repository.restoreSession();
        expect(restored, isNull);
        expect(repository.isAuthenticated, isFalse);

        repository.dispose();
      },
    );

    test('deve restaurar sessão offline se houver falha de rede e usuário em cache', () async {
      final tokenStorage = InMemoryTokenStorage();

      var isOnline = true;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'accessToken': testToken,
              'user': {'id': testUserId, 'email': testEmail},
            }),
            200,
          );
        }
        if (request.url.path == '/api/auth/me') {
          if (!isOnline) {
            throw http.ClientException('Sem conexão com a internet');
          }
          return http.Response(
            jsonEncode({'userId': testUserId, 'email': testEmail}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final repository = AuthRepositoryImpl(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      // 1. Faz login online (popula cache de usuário)
      await repository.login(email: testEmail, password: testPassword);

      // 2. Simula desconexão de rede
      isOnline = false;

      // 3. Tenta restaurar sessão offline
      final offlineSession = await repository.restoreSession();
      expect(offlineSession, isNotNull);
      expect(offlineSession!.token, equals(testToken));
      expect(offlineSession.user.id, equals(testUserId));
      expect(await tokenStorage.readToken(), equals(testToken));

      repository.dispose();
    });

    test(
      'deve realizar logout, remover token do storage e emitir null no stream',
      () async {
        final tokenStorage = InMemoryTokenStorage(testToken);

        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'accessToken': testToken,
              'user': {'id': testUserId, 'email': testEmail},
            }),
            200,
          );
        });

        final apiClient = AuthApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        final repository = AuthRepositoryImpl(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
        );

        await repository.login(email: testEmail, password: testPassword);
        expect(repository.isAuthenticated, isTrue);

        final emittedSessions = <AuthSession?>[];
        final sub = repository.sessionStream.listen(emittedSessions.add);

        await repository.logout();

        expect(repository.isAuthenticated, isFalse);
        expect(repository.currentSession, isNull);
        expect(await tokenStorage.readToken(), isNull);

        await Future<void>.delayed(Duration.zero);
        expect(emittedSessions.last, isNull);

        await sub.cancel();
        repository.dispose();
      },
    );

    test('fetchCurrentUser deve lançar UnauthenticatedException se não autenticado', () async {
      final repository = AuthRepositoryImpl(
        apiClient: AuthApiClient(baseUrl: testBaseUrl),
        tokenStorage: InMemoryTokenStorage(),
      );

      await expectLater(
        () => repository.fetchCurrentUser(),
        throwsA(isA<UnauthenticatedException>()),
      );

      repository.dispose();
    });
  });
}
