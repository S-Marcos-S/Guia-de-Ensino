import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/domain/models/auth_session.dart';
import 'package:app/domain/models/auth_user.dart';
import 'package:app/infrastructure/auth/client/auth_api_client.dart';
import 'package:app/infrastructure/auth/exceptions/auth_exceptions.dart';
import 'package:app/infrastructure/auth/models/auth_dtos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const testBaseUrl = 'https://api.guiadeensino.test';
  const testEmail = 'professor@escola.edu.br';
  const testPassword = 'Password123!';
  const testToken = 'jwt-token-xyz-secret-12345';
  const testUserId = 'user-uuid-123-abc';

  group('AuthApiClient - register', () {
    test(
      'deve registrar usuário com sucesso e retornar AuthResponseDto',
      () async {
        late http.Request capturedRequest;

        final mockClient = MockClient((request) async {
          capturedRequest = request;
          expect(request.method, equals('POST'));
          expect(
            request.url.toString(),
            equals('$testBaseUrl/api/auth/register'),
          );
          expect(request.headers['Content-Type'], contains('application/json'));

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['email'], equals(testEmail));
          expect(body['password'], equals(testPassword));

          return http.Response(
            jsonEncode({
              'accessToken': testToken,
              'user': {'id': testUserId, 'email': testEmail},
            }),
            201,
          );
        });

        final client = AuthApiClient(
          baseUrl: '$testBaseUrl/',
          httpClient: mockClient,
        );

        final response = await client.register(
          const RegisterRequestDto(email: testEmail, password: testPassword),
        );

        expect(response.accessToken, equals(testToken));
        expect(response.user.id, equals(testUserId));
        expect(response.user.email, equals(testEmail));
        expect(capturedRequest.url.path, equals('/api/auth/register'));
      },
    );

    test('deve lançar EmailAlreadyInUseException em HTTP 409', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'statusCode': 409,
            'message': 'Já existe um usuário cadastrado com este e-mail.',
            'error': 'Conflict',
          }),
          409,
        );
      });

      final client = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      await expectLater(
        () => client.register(
          const RegisterRequestDto(email: testEmail, password: testPassword),
        ),
        throwsA(isA<EmailAlreadyInUseException>()),
      );
    });

    test('deve validar e-mail antes de enviar requisição', () async {
      final client = AuthApiClient(baseUrl: testBaseUrl);

      expect(
        () => client.register(
          const RegisterRequestDto(email: 'invalido', password: testPassword),
        ),
        throwsA(isA<AuthValidationException>()),
      );
    });

    test(
      'deve validar tamanho mínimo de senha antes de enviar requisição',
      () async {
        final client = AuthApiClient(baseUrl: testBaseUrl);

        expect(
          () => client.register(
            const RegisterRequestDto(email: testEmail, password: 'curta'),
          ),
          throwsA(isA<AuthValidationException>()),
        );
      },
    );

    test('deve lançar AuthServerException em HTTP 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final client = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      await expectLater(
        () => client.register(
          const RegisterRequestDto(email: testEmail, password: testPassword),
        ),
        throwsA(isA<AuthServerException>()),
      );
    });

    test(
      'deve lançar AuthFormatException quando o corpo não for JSON válido',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('{ invalid-json', 201);
        });

        final client = AuthApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        await expectLater(
          () => client.register(
            const RegisterRequestDto(email: testEmail, password: testPassword),
          ),
          throwsA(isA<AuthFormatException>()),
        );
      },
    );
  });

  group('AuthApiClient - login', () {
    test(
      'deve realizar login com sucesso e retornar AuthResponseDto',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.toString(), equals('$testBaseUrl/api/auth/login'));

          return http.Response(
            jsonEncode({
              'accessToken': testToken,
              'user': {'id': testUserId, 'email': testEmail},
            }),
            200,
          );
        });

        final client = AuthApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        final response = await client.login(
          const LoginRequestDto(email: testEmail, password: testPassword),
        );

        expect(response.accessToken, equals(testToken));
        expect(response.user.id, equals(testUserId));
        expect(response.user.email, equals(testEmail));
      },
    );

    test('deve lançar InvalidCredentialsException em HTTP 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'statusCode': 401,
            'message': 'Credenciais inválidas.',
            'error': 'Unauthorized',
          }),
          401,
        );
      });

      final client = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      await expectLater(
        () => client.login(
          const LoginRequestDto(email: testEmail, password: testPassword),
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test(
      'deve lançar AuthNetworkException em falha de conexão (SocketException)',
      () async {
        final mockClient = MockClient((request) async {
          throw const SocketException('Failed host lookup');
        });

        final client = AuthApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        await expectLater(
          () => client.login(
            const LoginRequestDto(email: testEmail, password: testPassword),
          ),
          throwsA(isA<AuthNetworkException>()),
        );
      },
    );

    test('deve lançar AuthNetworkException em timeout', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Request timed out');
      });

      final client = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      await expectLater(
        () => client.login(
          const LoginRequestDto(email: testEmail, password: testPassword),
        ),
        throwsA(isA<AuthNetworkException>()),
      );
    });
  });

  group('AuthApiClient - getProfile', () {
    test('deve obter perfil com sucesso e enviar Bearer token', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals('$testBaseUrl/api/auth/me'));
        expect(request.headers['Authorization'], equals('Bearer $testToken'));

        return http.Response(
          jsonEncode({'userId': testUserId, 'email': testEmail}),
          200,
        );
      });

      final client = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final user = await client.getProfile(testToken);
      expect(user.id, equals(testUserId));
      expect(user.email, equals(testEmail));
    });

    test('deve lançar UnauthenticatedException se token for vazio', () async {
      final client = AuthApiClient(baseUrl: testBaseUrl);

      await expectLater(
        () => client.getProfile('   '),
        throwsA(isA<UnauthenticatedException>()),
      );
    });

    test(
      'deve lançar InvalidCredentialsException se token for rejeitado em 401',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'statusCode': 401, 'message': 'Sessão expirada.'}),
            401,
          );
        });

        final client = AuthApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        await expectLater(
          () => client.getProfile(testToken),
          throwsA(isA<InvalidCredentialsException>()),
        );
      },
    );
  });

  group('Sigilo e Proteção de Segredos', () {
    test('toString de AuthSession não deve vazar token', () {
      const session = AuthSession(
        token: 'super-sensitive-jwt-token-123',
        user: AuthUser(id: '1', email: 'prof@test.com'),
      );

      final str = session.toString();
      expect(str, isNot(contains('super-sensitive-jwt-token-123')));
      expect(str, contains('[PROTECTED]'));
    });

    test('toString de AuthResponseDto não deve vazar token', () {
      const dto = AuthResponseDto(
        accessToken: 'sensitive-token-abc',
        user: AuthUser(id: '1', email: 'prof@test.com'),
      );

      final str = dto.toString();
      expect(str, isNot(contains('sensitive-token-abc')));
      expect(str, contains('[PROTECTED]'));
    });

    test(
      'toString de LoginRequestDto e RegisterRequestDto não devem vazar senha',
      () {
        const login = LoginRequestDto(
          email: 'prof@test.com',
          password: 'secret-password',
        );
        expect(login.toString(), isNot(contains('secret-password')));
        expect(login.toString(), contains('[PROTECTED]'));

        const reg = RegisterRequestDto(
          email: 'prof@test.com',
          password: 'secret-password',
        );
        expect(reg.toString(), isNot(contains('secret-password')));
        expect(reg.toString(), contains('[PROTECTED]'));
      },
    );
  });
}
