import 'dart:async';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/core/network/connectivity_service.dart';
import 'package:app/domain/models/auth_session.dart';
import 'package:app/domain/models/auth_user.dart';
import 'package:app/domain/repositories/auth_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/operation_ack_dto.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_orchestrator.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/triggers/sync_trigger_manager.dart';
import 'package:app/presentation/components/sync_conflict_dialog.dart';
import 'package:app/presentation/components/sync_status_indicator.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSession? initialSession})
    : _currentSession = initialSession;

  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();
  AuthSession? _currentSession;

  @override
  AuthSession? get currentSession => _currentSession;

  @override
  bool get isAuthenticated => _currentSession != null;

  @override
  Stream<AuthSession?> get sessionStream => _controller.stream;

  void setSession(AuthSession? session) {
    _currentSession = session;
    _controller.add(session);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final s = AuthSession(
      token: 'fake-token',
      user: AuthUser(id: 'u1', email: email),
    );
    setSession(s);
    return s;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final s = AuthSession(
      token: 'fake-token',
      user: AuthUser(id: 'u2', email: email),
    );
    setSession(s);
    return s;
  }

  @override
  Future<AuthUser> fetchCurrentUser() async => _currentSession!.user;

  @override
  Future<AuthSession?> restoreSession() async => _currentSession;

  @override
  Future<void> logout() async {
    setSession(null);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class FakeSyncTriggerManager extends SyncTriggerManager {
  FakeSyncTriggerManager({
    required super.orchestratorProvider,
    required super.authRepository,
    required super.connectivityService,
    required super.outboxRepository,
  });

  bool triggerSyncCalled = false;
  String? lastSource;
  SyncResult? nextResult;

  @override
  Future<SyncResult?> triggerSync({String source = 'manual'}) async {
    triggerSyncCalled = true;
    lastSource = source;
    return nextResult ?? const SyncResult.success();
  }
}

Widget createTestApp({
  required AppDependencies dependencies,
  bool compact = false,
}) {
  return AppDependencyScope(
    dependencies: dependencies,
    child: MaterialApp(
      home: Scaffold(
        body: Center(child: SyncStatusIndicator(compact: compact)),
      ),
    ),
  );
}

void main() {
  late AppDatabase db;
  late FakeAuthRepository fakeAuth;
  late InMemoryConnectivityService fakeConnectivity;
  late SyncOutboxRepository outboxRepo;
  late FakeSyncTriggerManager fakeTriggerManager;
  late AppDependencies dependencies;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeAuth = FakeAuthRepository();
    fakeConnectivity = InMemoryConnectivityService(true);
    outboxRepo = SyncOutboxRepository(db);
    fakeTriggerManager = FakeSyncTriggerManager(
      orchestratorProvider: () => null,
      authRepository: fakeAuth,
      connectivityService: fakeConnectivity,
      outboxRepository: outboxRepo,
    );

    dependencies = AppDependencies(
      database: db,
      authRepository: fakeAuth,
      connectivityService: fakeConnectivity,
      syncOutboxRepository: outboxRepo,
      syncTriggerManager: fakeTriggerManager,
    );
  });

  tearDown(() async {
    dependencies.dispose();
    fakeAuth.dispose();
    fakeConnectivity.dispose();
    await db.close();
  });

  group('SyncStatusIndicator Widget Tests', () {
    testWidgets('deve exibir Modo Local (Convidado) quando não autenticado', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.authGuestMode), findsOneWidget);
    });

    testWidgets(
      'deve exibir Sincronizado quando autenticado, online e sem pendências',
      (tester) async {
        fakeAuth.setSession(
          const AuthSession(
            token: 'token',
            user: AuthUser(id: 'u1', email: 'prof@escola.gov.br'),
          ),
        );

        await tester.pumpWidget(createTestApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.syncStatusSynced), findsOneWidget);
      },
    );

    testWidgets('deve exibir Offline quando sem conexão de rede', (
      tester,
    ) async {
      fakeAuth.setSession(
        const AuthSession(
          token: 'token',
          user: AuthUser(id: 'u1', email: 'prof@escola.gov.br'),
        ),
      );
      fakeConnectivity.setOnline(false);

      await tester.pumpWidget(createTestApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.syncStatusOffline), findsOneWidget);
    });

    testWidgets('deve exibir pendências na fila Outbox', (tester) async {
      fakeAuth.setSession(
        const AuthSession(
          token: 'token',
          user: AuthUser(id: 'u1', email: 'prof@escola.gov.br'),
        ),
      );

      // Enfileira 2 mutações na Outbox
      await outboxRepo.enqueueOperation(
        entityType: 'academic_year',
        entityId: 'year-1',
        operation: 'create',
      );
      await outboxRepo.enqueueOperation(
        entityType: 'classroom',
        entityId: 'room-1',
        operation: 'create',
      );

      await tester.pumpWidget(createTestApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      expect(
        find.text('2 ${AppStrings.syncStatusPendingPlural}'),
        findsOneWidget,
      );
    });

    testWidgets(
      'deve exibir Erro de sincronização quando houver falha registrada',
      (tester) async {
        fakeAuth.setSession(
          const AuthSession(
            token: 'token',
            user: AuthUser(id: 'u1', email: 'prof@escola.gov.br'),
          ),
        );

        await outboxRepo.updateSyncFailure('Erro HTTP 500 no servidor');

        await tester.pumpWidget(createTestApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.syncStatusError), findsOneWidget);
      },
    );

    testWidgets(
      'toque no indicador abre modal de detalhes e permite sincronização manual',
      (tester) async {
        fakeAuth.setSession(
          const AuthSession(
            token: 'token',
            user: AuthUser(id: 'u1', email: 'prof@escola.gov.br'),
          ),
        );

        await tester.pumpWidget(createTestApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        // Toca no chip do indicador
        await tester.tap(find.byType(ActionChip));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.syncDetailsTitle), findsOneWidget);
        expect(find.text('prof@escola.gov.br'), findsOneWidget);
        expect(find.text(AppStrings.syncActionNow), findsOneWidget);

        // Toca no botão Sincronizar agora
        await tester.tap(find.text(AppStrings.syncActionNow));
        await tester.pumpAndSettle();

        expect(fakeTriggerManager.triggerSyncCalled, isTrue);
        expect(fakeTriggerManager.lastSource, equals('manual_ui'));
      },
    );

    testWidgets(
      'SyncConflictDialog exibe versões em disputa sem sobrescrever dados',
      (tester) async {
        const conflict = ConflictDetailsDto(
          reason: 'OUTDATED_BASE_REVISION',
          clientVersion: {'notes': 'Anotação local'},
          serverVersion: {'notes': 'Anotação servidor'},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  child: const Text('Abrir Conflito'),
                  onPressed: () {
                    SyncConflictDialog.show(ctx, conflicts: const [conflict]);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abrir Conflito'));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.syncConflictDialogTitle), findsOneWidget);
        expect(
          find.text(AppStrings.syncConflictPreservationNotice),
          findsOneWidget,
        );
        expect(find.textContaining('OUTDATED_BASE_REVISION'), findsOneWidget);
        expect(find.text(AppStrings.understandButton), findsOneWidget);

        await tester.tap(find.text(AppStrings.understandButton));
        await tester.pumpAndSettle();

        expect(find.byType(SyncConflictDialog), findsNothing);
      },
    );
  });
}
