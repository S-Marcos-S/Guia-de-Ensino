import 'dart:async';
import 'dart:io';

import 'package:app/core/network/connectivity_service.dart';
import 'package:app/domain/models/auth_session.dart';
import 'package:app/domain/models/auth_user.dart';
import 'package:app/domain/repositories/auth_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/client/sync_api_client.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_orchestrator.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_staging_handler.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/triggers/sync_trigger_manager.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSyncOrchestrator implements SyncOrchestrator {
  int syncCallCount = 0;
  bool isSyncingMock = false;
  Completer<SyncResult>? activeSyncCompleter;
  Object? errorToReturn;

  @override
  bool get isSyncing => isSyncingMock;

  @override
  Future<SyncResult> synchronize({
    bool forceSnapshot = false,
    bool rethrowExceptions = true,
  }) async {
    if (isSyncingMock) {
      return const SyncResult.alreadyInProgress();
    }

    syncCallCount++;

    if (activeSyncCompleter != null) {
      isSyncingMock = true;
      try {
        final res = await activeSyncCompleter!.future;
        return res;
      } finally {
        isSyncingMock = false;
      }
    }

    if (errorToReturn != null) {
      if (rethrowExceptions) {
        throw errorToReturn!;
      }
      return SyncResult.failure(error: errorToReturn!);
    }

    return const SyncResult.success(pushedOperationsCount: 1);
  }

  @override
  SyncApiClient get apiClient => throw UnimplementedError();

  @override
  SyncOutboxRepository get outboxRepository => throw UnimplementedError();

  @override
  SyncStagingHandler get stagingHandler => throw UnimplementedError();
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSession? initialSession})
    : _currentSession = initialSession;

  AuthSession? _currentSession;
  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();

  @override
  AuthSession? get currentSession => _currentSession;

  @override
  bool get isAuthenticated => _currentSession != null;

  @override
  Stream<AuthSession?> get sessionStream => _controller.stream;

  void emitSession(AuthSession? session) {
    _currentSession = session;
    _controller.add(session);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = AuthSession(
      token: 'jwt-token',
      user: AuthUser(id: 'u-1', email: email),
    );
    emitSession(session);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) => login(email: email, password: password);

  @override
  Future<AuthSession?> restoreSession() async => _currentSession;

  @override
  Future<AuthUser> fetchCurrentUser() async {
    if (_currentSession == null) throw Exception('Unauthenticated');
    return _currentSession!.user;
  }

  @override
  Future<void> logout() async {
    emitSession(null);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  const testSession = AuthSession(
    token: 'jwt-token-123',
    user: AuthUser(id: 'user-1', email: 'prof@escola.gov.br'),
  );

  late AppDatabase db;
  late SyncOutboxRepository outboxRepo;
  late InMemoryConnectivityService connectivity;
  late FakeAuthRepository authRepo;
  late FakeSyncOrchestrator fakeOrchestrator;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outboxRepo = SyncOutboxRepository(db);
    connectivity = InMemoryConnectivityService(true);
    authRepo = FakeAuthRepository();
    fakeOrchestrator = FakeSyncOrchestrator();
  });

  tearDown(() async {
    outboxRepo.dispose();
    connectivity.dispose();
    authRepo.dispose();
    await db.close();
  });

  group('SyncTriggerManager', () {
    test('Gatilho 1: não deve sincronizar ao iniciar desautenticado (modo convidado)', () async {
      final manager = SyncTriggerManager(
        orchestratorProvider: () => fakeOrchestrator,
        authRepository: authRepo,
        connectivityService: connectivity,
        outboxRepository: outboxRepo,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeOrchestrator.syncCallCount, equals(0));

      manager.dispose();
    });

    test('Gatilho 1: deve disparar sincronização inicial ao iniciar com sessão autenticada e online', () async {
      authRepo.emitSession(testSession);

      final manager = SyncTriggerManager(
        orchestratorProvider: () => fakeOrchestrator,
        authRepository: authRepo,
        connectivityService: connectivity,
        outboxRepository: outboxRepo,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeOrchestrator.syncCallCount, equals(1));

      manager.dispose();
    });

    test(
      'Gatilho 1: deve disparar sincronização quando o usuário fizer login',
      () async {
        final manager = SyncTriggerManager(
          orchestratorProvider: () => fakeOrchestrator,
          authRepository: authRepo,
          connectivityService: connectivity,
          outboxRepository: outboxRepo,
        );

        expect(fakeOrchestrator.syncCallCount, equals(0));

        // Usuário faz login
        await authRepo.login(email: 'prof@escola.gov.br', password: '123');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(fakeOrchestrator.syncCallCount, equals(1));

        manager.dispose();
      },
    );

    test('Gatilho 2: deve disparar sincronização ao reconectar à rede (offline -> online)', () async {
      connectivity.setOnline(false);
      authRepo.emitSession(testSession);

      final manager = SyncTriggerManager(
        orchestratorProvider: () => fakeOrchestrator,
        authRepository: authRepo,
        connectivityService: connectivity,
        outboxRepository: outboxRepo,
      );

      // Offline: nada deve ter executado
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeOrchestrator.syncCallCount, equals(0));

      // Rede restabelecida
      connectivity.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fakeOrchestrator.syncCallCount, equals(1));

      manager.dispose();
    });

    test(
      'Gatilho 3: solicitação manual deve sincronizar se autenticado e online',
      () async {
        authRepo.emitSession(testSession);

        final manager = SyncTriggerManager(
          orchestratorProvider: () => fakeOrchestrator,
          authRepository: authRepo,
          connectivityService: connectivity,
          outboxRepository: outboxRepo,
        );

        // Limpa a chamada inicial
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeOrchestrator.syncCallCount, equals(1));

        final result = await manager.triggerSync(source: 'manual_button');
        expect(result, isNotNull);
        expect(result!.isSuccess, isTrue);
        expect(fakeOrchestrator.syncCallCount, equals(2));

        manager.dispose();
      },
    );

    test('Gatilho 3: solicitação manual sem autenticação deve retornar null e não sincronizar', () async {
      final manager = SyncTriggerManager(
        orchestratorProvider: () => fakeOrchestrator,
        authRepository: authRepo, // desautenticado
        connectivityService: connectivity,
        outboxRepository: outboxRepo,
      );

      final result = await manager.triggerSync(source: 'manual_guest');
      expect(result, isNull);
      expect(fakeOrchestrator.syncCallCount, equals(0));

      manager.dispose();
    });

    test('Gatilho 4: mutações sucessivas na Outbox devem ser agrupadas pelo debounce', () async {
      authRepo.emitSession(testSession);

      final manager = SyncTriggerManager(
        orchestratorProvider: () => fakeOrchestrator,
        authRepository: authRepo,
        connectivityService: connectivity,
        outboxRepository: outboxRepo,
        debounceDuration: const Duration(milliseconds: 40),
      );

      // Aguarda a sincronização inicial
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeOrchestrator.syncCallCount, equals(1));

      // Enfileira 5 mutações rápidas na Outbox em intervalos de 5ms (menor que o debounce de 40ms)
      for (var i = 1; i <= 5; i++) {
        await outboxRepo.enqueueOperation(
          entityType: 'subject',
          entityId: 'sub-$i',
          operation: 'INSERT',
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      // Antes de expirar a janela total de 40ms desde a última mutação: nenhuma sincronização nova
      expect(fakeOrchestrator.syncCallCount, equals(1));

      // Aguarda expiração do debounce
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // Exatamente 1 sincronização adicional deve ter ocorrido
      expect(fakeOrchestrator.syncCallCount, equals(2));

      manager.dispose();
    });

    test('Coalescing: chamada concorrente durante sincronização ativa deve agendar follow-up sequencial único', () async {
      authRepo.emitSession(testSession);
      final syncCompleter = Completer<SyncResult>();
      fakeOrchestrator.activeSyncCompleter = syncCompleter;

      final manager = SyncTriggerManager(
        orchestratorProvider: () => fakeOrchestrator,
        authRepository: authRepo,
        connectivityService: connectivity,
        outboxRepository: outboxRepo,
      );

      // Dispara primeiro sync longo
      final syncFuture1 = manager.triggerSync(source: 'sync_1');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(fakeOrchestrator.isSyncing, isTrue);
      expect(fakeOrchestrator.syncCallCount, equals(1));

      // Dispara segundo sync concorrente enquanto o primeiro ainda executa
      final syncFuture2 = manager.triggerSync(source: 'sync_2_concurrent');
      final res2 = await syncFuture2;

      expect(res2?.isAlreadyInProgress, isTrue);
      // O segundo ciclo HTTP não pode ter iniciado ainda
      expect(fakeOrchestrator.syncCallCount, equals(1));

      // Completa o primeiro ciclo
      fakeOrchestrator.activeSyncCompleter = null;
      syncCompleter.complete(const SyncResult.success());
      await syncFuture1;

      // Aguarda execução do follow-up automático agendado
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // O follow-up deve ter executado exatamente uma vez
      expect(fakeOrchestrator.syncCallCount, equals(2));

      manager.dispose();
    });

    test('Falhas de rede devem ser capturadas como SyncResult.failure sem interromper a aplicação', () async {
      authRepo.emitSession(testSession);
      fakeOrchestrator.errorToReturn = const SocketException('Sem internet');

      final manager = SyncTriggerManager(
        orchestratorProvider: () => fakeOrchestrator,
        authRepository: authRepo,
        connectivityService: connectivity,
        outboxRepository: outboxRepo,
      );

      final result = await manager.triggerSync();
      expect(result, isNotNull);
      expect(result!.isFailure, isTrue);
      expect(result.error, isA<SocketException>());

      manager.dispose();
    });

    test('Logout durante a janela de debounce deve cancelar o timer e prevenir sincronização', () async {
      authRepo.emitSession(testSession);

      final manager = SyncTriggerManager(
        orchestratorProvider: () => fakeOrchestrator,
        authRepository: authRepo,
        connectivityService: connectivity,
        outboxRepository: outboxRepo,
        debounceDuration: const Duration(milliseconds: 50),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeOrchestrator.syncCallCount, equals(1));

      // Enfileira mutação que inicia o debounce
      await outboxRepo.enqueueOperation(
        entityType: 'classroom',
        entityId: 'c-1',
        operation: 'INSERT',
      );

      // Usuário faz logout antes do timer de 50ms expirar
      await authRepo.logout();

      // Aguarda expiração do tempo de debounce original
      await Future<void>.delayed(const Duration(milliseconds: 70));

      // Nenhuma sincronização adicional deve ter ocorrido
      expect(fakeOrchestrator.syncCallCount, equals(1));

      manager.dispose();
    });

    test(
      'dispose deve cancelar observadores e desativar o gerenciador',
      () async {
        authRepo.emitSession(testSession);

        final manager = SyncTriggerManager(
          orchestratorProvider: () => fakeOrchestrator,
          authRepository: authRepo,
          connectivityService: connectivity,
          outboxRepository: outboxRepo,
        );

        manager.dispose();

        // Tentativa de sincronização após dispose deve retornar null
        final result = await manager.triggerSync();
        expect(result, isNull);
      },
    );
  });
}
