import 'dart:convert';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/domain/models/academic_year.dart';
import 'package:app/infrastructure/auth/client/auth_api_client.dart';
import 'package:app/infrastructure/auth/repositories/auth_repository_impl.dart';
import 'package:app/infrastructure/auth/storage/in_memory_token_storage.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const testBaseUrl = 'https://api.guiadeensino.test';
  const testEmail = 'professor@escola.gov.br';
  const testPassword = 'Password123!';
  const testToken = 'bearer-jwt-token-valido-123';
  const testUserId = 'user-uuid-12345';

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDependencies - Modo Híbrido e Injeção Reativa', () {
    test('deve iniciar em modo convidado/offline quando não houver sessão autenticada', () async {
      final dependencies = AppDependencies(database: db);

      expect(dependencies.isAuthenticated, isFalse);
      expect(dependencies.isGuestMode, isTrue);
      expect(dependencies.currentSession, isNull);
      expect(dependencies.syncApiClient, isNull);
      expect(dependencies.syncOrchestrator, isNull);

      // Repositórios locais continuam funcionando no modo offline
      final academicYear = AcademicYear(
        id: 'year-offline-1',
        year: 2026,
        title: 'Ano Letivo 2026 Convidado',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 12, 15),
        totalMandatoryDays: 200,
      );

      await dependencies.academicYearRepository.save(academicYear);

      final loaded = await dependencies.academicYearRepository.findById(
        'year-offline-1',
      );
      expect(loaded, isNotNull);
      expect(loaded!.title, equals('Ano Letivo 2026 Convidado'));

      // Valida que foi enfileirado na Outbox para sincronização futura
      final pendingOps = await dependencies.syncOutboxRepository
          .getPendingOperations();
      expect(pendingOps.length, equals(1));
      expect(pendingOps.first.entityId, equals('year-offline-1'));

      dependencies.dispose();
    });

    test('deve disponibilizar SyncApiClient e SyncOrchestrator reativamente após login', () async {
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

      final authApiClient = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final authRepository = AuthRepositoryImpl(
        apiClient: authApiClient,
        tokenStorage: tokenStorage,
      );

      final dependencies = AppDependencies(
        database: db,
        authRepository: authRepository,
        apiBaseUrl: testBaseUrl,
      );

      var notified = false;
      dependencies.addListener(() {
        notified = true;
      });

      expect(dependencies.syncApiClient, isNull);
      expect(dependencies.syncOrchestrator, isNull);

      // Executa login
      final session = await authRepository.login(
        email: testEmail,
        password: testPassword,
      );

      expect(session.token, equals(testToken));
      await Future<void>.delayed(Duration.zero);

      expect(notified, isTrue);
      expect(dependencies.isAuthenticated, isTrue);
      expect(dependencies.isGuestMode, isFalse);
      expect(dependencies.syncApiClient, isNotNull);
      expect(dependencies.syncOrchestrator, isNotNull);
      expect(dependencies.currentSession?.user.email, equals(testEmail));

      dependencies.dispose();
    });

    test('logout deve encerrar acesso autenticado e PRESERVAR o banco local e a Outbox', () async {
      final tokenStorage = InMemoryTokenStorage(testToken);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({'userId': testUserId, 'email': testEmail}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final authApiClient = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final authRepository = AuthRepositoryImpl(
        apiClient: authApiClient,
        tokenStorage: tokenStorage,
      );

      // Restaura sessão inicial
      await authRepository.restoreSession();

      final dependencies = AppDependencies(
        database: db,
        authRepository: authRepository,
        apiBaseUrl: testBaseUrl,
      );

      expect(dependencies.isAuthenticated, isTrue);
      expect(dependencies.syncOrchestrator, isNotNull);

      // Insere dados pedagógicos enquanto logado
      final year = AcademicYear(
        id: 'year-auth-1',
        year: 2026,
        title: 'Planejamento Autenticado',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 12, 15),
        totalMandatoryDays: 200,
      );
      await dependencies.academicYearRepository.save(year);

      final outboxBeforeLogout = await dependencies.syncOutboxRepository
          .getPendingOperations();
      expect(outboxBeforeLogout.length, equals(1));

      // Executa logout
      var notifiedOnLogout = false;
      dependencies.addListener(() {
        notifiedOnLogout = true;
      });

      await authRepository.logout();
      await Future<void>.delayed(Duration.zero);

      expect(notifiedOnLogout, isTrue);
      expect(dependencies.isAuthenticated, isFalse);
      expect(dependencies.isGuestMode, isTrue);
      expect(dependencies.syncApiClient, isNull);
      expect(dependencies.syncOrchestrator, isNull);

      // PRESERVAÇÃO INTEGRAL: banco Drift e Outbox devem continuar intactos
      final savedYearAfterLogout = await dependencies.academicYearRepository
          .findById('year-auth-1');
      expect(savedYearAfterLogout, isNotNull);
      expect(savedYearAfterLogout!.title, equals('Planejamento Autenticado'));

      final outboxAfterLogout = await dependencies.syncOutboxRepository
          .getPendingOperations();
      expect(outboxAfterLogout.length, equals(1));
      expect(outboxAfterLogout.first.entityId, equals('year-auth-1'));

      dependencies.dispose();
    });

    test('sessão expirada (401) não deve autorizar sincronização e deve reverter para modo convidado', () async {
      final tokenStorage = InMemoryTokenStorage('token-expirado');

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({'statusCode': 401, 'message': 'Token revogado'}),
            401,
          );
        }
        return http.Response('Not Found', 404);
      });

      final authApiClient = AuthApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final authRepository = AuthRepositoryImpl(
        apiClient: authApiClient,
        tokenStorage: tokenStorage,
      );

      final dependencies = AppDependencies(
        database: db,
        authRepository: authRepository,
        apiBaseUrl: testBaseUrl,
      );

      // Restauração falha com 401
      final session = await authRepository.restoreSession();
      expect(session, isNull);

      await Future<void>.delayed(Duration.zero);

      expect(dependencies.isAuthenticated, isFalse);
      expect(dependencies.isGuestMode, isTrue);
      expect(dependencies.syncApiClient, isNull);
      expect(dependencies.syncOrchestrator, isNull);
      expect(await tokenStorage.readToken(), isNull);

      dependencies.dispose();
    });

    test('deve manter retrocompatibilidade com mocks estáticos de syncApiClient/syncOrchestrator', () async {
      final mockClient = MockClient(
        (request) async => http.Response('{}', 200),
      );
      final customApiClient = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final dependencies = AppDependencies(
        database: db,
        syncApiClient: customApiClient,
      );

      expect(dependencies.syncApiClient, equals(customApiClient));
      expect(dependencies.syncOrchestrator, isNotNull);

      dependencies.dispose();
    });

    test(
      'deve expor e inicializar ConnectivityService e SyncTriggerManager',
      () async {
        final dependencies = AppDependencies(database: db);

        expect(dependencies.connectivityService, isNotNull);
        expect(dependencies.syncTriggerManager, isNotNull);
        expect(dependencies.connectivityService.isOnline, isTrue);

        dependencies.dispose();
      },
    );
  });
}
