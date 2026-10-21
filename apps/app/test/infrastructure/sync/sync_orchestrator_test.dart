import 'dart:async';

import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/client/sync_api_client.dart';
import 'package:app/infrastructure/sync/client/sync_exceptions.dart';
import 'package:app/infrastructure/sync/models/change_dto.dart';
import 'package:app/infrastructure/sync/models/operation_ack_dto.dart';
import 'package:app/infrastructure/sync/models/pull_query_dto.dart';
import 'package:app/infrastructure/sync/models/pull_response_dto.dart';
import 'package:app/infrastructure/sync/models/push_request_dto.dart';
import 'package:app/infrastructure/sync/models/push_response_dto.dart';
import 'package:app/infrastructure/sync/models/snapshot_response_dto.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_orchestrator.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_staging_handler.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_item.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cliente falso para testes determinísticos sem dependência de rede real.
class FakeSyncApiClient extends SyncApiClient {
  FakeSyncApiClient() : super(baseUrl: 'https://test.api');

  Future<PushResponseDto> Function(PushRequestDto request)? onPush;
  Future<PullResponseDto> Function(PullQueryDto query)? onPull;
  Future<SnapshotResponseDto> Function(String? snapshotToken)? onGetSnapshot;

  final List<PushRequestDto> pushedRequests = [];
  final List<PullQueryDto> pulledQueries = [];
  int snapshotCallsCount = 0;

  @override
  Future<PushResponseDto> push(PushRequestDto request) async {
    pushedRequests.add(request);
    if (onPush != null) {
      return await onPush!(request);
    }
    return PushResponseDto(
      clientBatchId: request.clientBatchId,
      serverEpoch: '1',
      currentServerSeq: '10',
      acks: request.operations
          .map(
            (op) => OperationAckDto(
              clientOpId: op.clientOpId,
              status: 'APPLIED',
              serverSeq: '10',
              appliedAt: DateTime.now().toUtc(),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<PullResponseDto> pull(PullQueryDto query) async {
    pulledQueries.add(query);
    if (onPull != null) {
      return await onPull!(query);
    }
    return PullResponseDto(
      epoch: query.clientEpoch ?? '1',
      currentServerSeq: '10',
      nextCursor: query.cursor ?? '10:0',
      hasMore: false,
      changes: const [],
    );
  }

  @override
  Future<SnapshotResponseDto> getSnapshot({String? snapshotToken}) async {
    snapshotCallsCount++;
    if (onGetSnapshot != null) {
      return await onGetSnapshot!(snapshotToken);
    }
    return SnapshotResponseDto(
      epoch: '2',
      snapshotSeq: '50',
      snapshotToken: 'test-token',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
      entities: const SnapshotEntitiesDto(),
    );
  }
}

void main() {
  late AppDatabase db;
  late SyncOutboxRepository outboxRepo;
  late SyncStagingHandler stagingHandler;
  late FakeSyncApiClient fakeApiClient;
  late SyncOrchestrator orchestrator;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outboxRepo = SyncOutboxRepository(db);
    stagingHandler = SyncStagingHandler(db);
    fakeApiClient = FakeSyncApiClient();
    orchestrator = SyncOrchestrator(
      apiClient: fakeApiClient,
      outboxRepository: outboxRepo,
      stagingHandler: stagingHandler,
    );

    await db.customStatement('PRAGMA foreign_keys = ON;');
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncOrchestrator — Suíte Completa de Testes Obrigatórios', () {
    // 1. Ciclo bem-sucedido de Push e Pull
    test('1. Ciclo bem-sucedido de Push e Pull', () async {
      // Enfileira operação local
      await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-1',
        operation: SyncMutationType.insert,
        payload: {'name': 'Matemática'},
      );

      // Configura Pull com delta remoto
      fakeApiClient.onPull = (query) async {
        return PullResponseDto(
          epoch: '1',
          currentServerSeq: '2',
          nextCursor: '2:0',
          hasMore: false,
          changes: [
            ChangeDto(
              serverSeq: '2',
              changeLogId: '201',
              entityType: SyncEntityType.academicYear,
              entityId: 'ay-1',
              mutationType: 'INSERT',
              payload: {
                'id': 'ay-1',
                'year': 2026,
                'title': 'Ano 2026',
                'start_date': '2026-02-01',
                'end_date': '2026-12-15',
                'total_mandatory_days': 200,
                'created_at': '2026-01-10T00:00:00.000Z',
              },
              deviceId: 'other-device',
              createdAt: DateTime.utc(2026, 1, 10),
            ),
          ],
        );
      };

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);
      expect(result.pushedOperationsCount, equals(1));
      expect(result.appliedChangesCount, equals(1));
      expect(result.snapshotApplied, isFalse);

      // Verifica se a operação local foi removida da Outbox
      final pendingAfter = await outboxRepo.getPendingOperations();
      expect(pendingAfter, isEmpty);

      // Verifica se o delta remoto foi persistido no banco
      final yearRows = await db
          .customSelect("SELECT * FROM academic_years_table WHERE id = 'ay-1';")
          .get();
      expect(yearRows, hasLength(1));

      // Verifica se o cursor e o estado foram atualizados
      final state = await outboxRepo.getOrCreateSyncState();
      expect(state.serverCursor, equals('2:0'));
      expect(state.lastSyncStatus, equals('idle'));
      expect(state.lastSyncedAt, isNotNull);
    });

    // 2. Recuperação inicial das operações "sending"
    test('2. Recuperação inicial das operações sending', () async {
      final op = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-stale',
        operation: SyncMutationType.insert,
        payload: {'name': 'Física'},
      );

      // Simula queda anterior que deixou o status como 'sending'
      await outboxRepo.updateStatus([op.operationId], SyncOutboxStatus.sending);

      final before = await outboxRepo.getAllOperations();
      expect(before.first.status, equals(SyncOutboxStatus.sending));

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);
      expect(result.pushedOperationsCount, equals(1));

      // Verifica se a operação foi enviada e removida com sucesso
      final allOps = await outboxRepo.getAllOperations();
      expect(allOps, isEmpty);
    });

    // 3. Respeito ao limite de operações por lote (teto de 100)
    test('3. Respeito ao limite de operações por lote (<= 100)', () async {
      // Enfileira 105 operações
      for (var i = 1; i <= 105; i++) {
        await outboxRepo.enqueueOperation(
          entityType: SyncEntityType.subject,
          entityId: 'sub-$i',
          operation: SyncMutationType.insert,
          payload: {'name': 'Disciplina $i'},
        );
      }

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);
      expect(result.pushedOperationsCount, equals(105));
      expect(fakeApiClient.pushedRequests, hasLength(2));
      // Primeiro lote com 100, segundo com 5
      expect(fakeApiClient.pushedRequests[0].operations, hasLength(100));
      expect(fakeApiClient.pushedRequests[1].operations, hasLength(5));

      final pendingAfter = await outboxRepo.getPendingOperations();
      expect(pendingAfter, isEmpty);
    });

    // 4. Tratamento correto de ACKs "APPLIED", "SKIPPED" e "CONFLICT"
    test('4. Tratamento correto de ACKs APPLIED, SKIPPED e CONFLICT', () async {
      final op1 = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-applied',
        operation: SyncMutationType.insert,
        payload: {'name': 'Sub 1'},
      );
      final op2 = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-skipped',
        operation: SyncMutationType.insert,
        payload: {'name': 'Sub 2'},
      );
      final op3 = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-conflict',
        operation: SyncMutationType.insert,
        payload: {'name': 'Sub 3'},
      );

      fakeApiClient.onPush = (request) async {
        return PushResponseDto(
          clientBatchId: request.clientBatchId,
          serverEpoch: '1',
          currentServerSeq: '15',
          acks: [
            OperationAckDto(
              clientOpId: op1.operationId,
              status: 'APPLIED',
              serverSeq: '13',
              appliedAt: DateTime.now().toUtc(),
            ),
            OperationAckDto(
              clientOpId: op2.operationId,
              status: 'SKIPPED',
              serverSeq: '14',
              appliedAt: DateTime.now().toUtc(),
            ),
            OperationAckDto(
              clientOpId: op3.operationId,
              status: 'CONFLICT',
              serverSeq: '15',
              appliedAt: DateTime.now().toUtc(),
              conflict: const ConflictDetailsDto(
                reason: 'VERSION_MISMATCH',
                serverVersion: {'v': 2},
                clientVersion: {'v': 1},
              ),
            ),
          ],
        );
      };

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);
      expect(result.pushedOperationsCount, equals(2)); // op1 e op2
      expect(result.conflictDetails, hasLength(1));
      expect(result.conflictDetails.first.reason, equals('VERSION_MISMATCH'));

      // op1 e op2 foram removidas da Outbox
      final allOps = await outboxRepo.getAllOperations();
      expect(allOps, hasLength(1));
      // op3 permanece marcada como 'failed'
      expect(allOps.first.operationId, equals(op3.operationId));
      expect(allOps.first.status, equals(SyncOutboxStatus.failed));
    });

    // 5. ACK parcial sem confirmação indevida de operações
    test('5. ACK parcial sem confirmação indevida de operações', () async {
      final op1 = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-ack-ok',
        operation: SyncMutationType.insert,
        payload: {'name': 'OK'},
      );
      final op2 = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-ack-missing',
        operation: SyncMutationType.insert,
        payload: {'name': 'Missing'},
      );

      // Resposta omite o ACK de op2
      fakeApiClient.onPush = (request) async {
        return PushResponseDto(
          clientBatchId: request.clientBatchId,
          serverEpoch: '1',
          currentServerSeq: '20',
          acks: [
            OperationAckDto(
              clientOpId: op1.operationId,
              status: 'APPLIED',
              serverSeq: '20',
              appliedAt: DateTime.now().toUtc(),
            ),
          ],
        );
      };

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);
      expect(result.pushedOperationsCount, equals(1));

      // op1 foi removida
      // op2 foi revertida para 'pending' para reenvio futuro
      final allOps = await outboxRepo.getAllOperations();
      expect(allOps, hasLength(1));
      expect(allOps.first.operationId, equals(op2.operationId));
      expect(allOps.first.status, equals(SyncOutboxStatus.pending));
    });

    // 6. Confirmação correta de lápides por IDs de operação
    test('6. Confirmação correta de lápides por IDs de operação', () async {
      await outboxRepo.enqueueDelete(
        entityType: SyncEntityType.subject,
        entityId: 'sub-to-delete',
      );

      final tombstonesBefore = await outboxRepo.getTombstones();
      expect(tombstonesBefore, hasLength(1));
      expect(tombstonesBefore.first.synced, isFalse);

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);

      final tombstonesAfter = await outboxRepo.getTombstones();
      expect(tombstonesAfter, hasLength(1));
      expect(tombstonesAfter.first.synced, isTrue);
    });

    // 7. Pull com múltiplas páginas e persistência correta do cursor
    test(
      '7. Pull com múltiplas páginas e persistência correta do cursor',
      () async {
        var pullCallCount = 0;
        fakeApiClient.onPull = (query) async {
          pullCallCount++;
          if (pullCallCount == 1) {
            return const PullResponseDto(
              epoch: '1',
              currentServerSeq: '20',
              nextCursor: '10:0',
              hasMore: true,
              changes: [],
            );
          } else {
            return const PullResponseDto(
              epoch: '1',
              currentServerSeq: '20',
              nextCursor: '20:0',
              hasMore: false,
              changes: [],
            );
          }
        };

        final result = await orchestrator.synchronize();

        expect(result.isSuccess, isTrue);
        expect(pullCallCount, equals(2));

        final state = await outboxRepo.getOrCreateSyncState();
        expect(state.serverCursor, equals('20:0'));
      },
    );

    // 8. Falha durante a aplicação de um delta sem avanço indevido do cursor
    test(
      '8. Falha durante aplicação de delta sem avanço indevido do cursor',
      () async {
        // Inicializa cursor pré-existente
        await outboxRepo.updateSyncState(
          serverCursor: '5:0',
          accountEpoch: 1,
          lastSyncedAt: DateTime.utc(2026, 1, 1),
        );

        // Pull retorna delta com payload inválido para INSERT (payload nulo dispara FormatException)
        fakeApiClient.onPull = (query) async {
          return PullResponseDto(
            epoch: '1',
            currentServerSeq: '10',
            nextCursor: '10:0',
            hasMore: false,
            changes: [
              ChangeDto(
                serverSeq: '6',
                changeLogId: '601',
                entityType: 'academic_year',
                entityId: 'ay-fail',
                mutationType: 'INSERT',
                payload: null, // Inválido!
                deviceId: 'other-device',
                createdAt: DateTime.utc(2026, 1, 1),
              ),
            ],
          );
        };

        await expectLater(
          () => orchestrator.synchronize(),
          throwsA(isA<FormatException>()),
        );

        // Verifica que o cursor NÃO avançou para '10:0'
        final state = await outboxRepo.getOrCreateSyncState();
        expect(state.serverCursor, equals('5:0'));
        expect(state.lastSyncStatus, equals('error'));
        expect(state.lastSyncError, contains('Payload não pode ser nulo'));
      },
    );

    // 9. Resposta "RESYNC_REQUIRED"/HTTP 410 e aplicação de Snapshot
    test('9. Resposta RESYNC_REQUIRED e aplicação de Snapshot', () async {
      var pullCalled = 0;
      fakeApiClient.onPull = (query) async {
        pullCalled++;
        if (pullCalled == 1) {
          throw const SyncResyncRequiredException(
            'Época divergente detectada',
            serverEpoch: '2',
          );
        }
        return const PullResponseDto(
          epoch: '2',
          currentServerSeq: '50',
          nextCursor: '50:0',
          hasMore: false,
          changes: [],
        );
      };

      fakeApiClient.onGetSnapshot = (token) async {
        return SnapshotResponseDto(
          epoch: '2',
          snapshotSeq: '45',
          snapshotToken: 'valid-token',
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
          entities: const SnapshotEntitiesDto(
            academicYears: [
              {
                'id': 'ay-snap',
                'year': 2026,
                'title': 'Ano Snapshot',
                'start_date': '2026-02-01',
                'end_date': '2026-12-15',
                'total_mandatory_days': 200,
                'created_at': '2026-01-01T00:00:00.000Z',
              },
            ],
          ),
        );
      };

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);
      expect(result.snapshotApplied, isTrue);
      expect(fakeApiClient.snapshotCallsCount, equals(1));

      // Ingestão do snapshot persistida
      final snapRow = await db
          .customSelect(
            "SELECT * FROM academic_years_table WHERE id = 'ay-snap';",
          )
          .get();
      expect(snapRow, hasLength(1));

      // Cursor e época atualizados
      final state = await outboxRepo.getOrCreateSyncState();
      expect(state.accountEpoch, equals(2));
      expect(state.serverCursor, equals('50:0'));
    });

    // 10. Falha durante o Snapshot sem declarar recuperação concluída
    test(
      '10. Falha durante o Snapshot sem declarar recuperação concluída',
      () async {
        await outboxRepo.updateSyncState(
          serverCursor: '1:0',
          accountEpoch: 1,
          lastSyncedAt: DateTime.utc(2026, 1, 1),
        );

        fakeApiClient.onPull = (query) async {
          throw const SyncResyncRequiredException(
            'Época inválida',
            serverEpoch: '2',
          );
        };

        // Snapshot com entidade violando chave estrangeira
        fakeApiClient.onGetSnapshot = (token) async {
          return SnapshotResponseDto(
            epoch: '2',
            snapshotSeq: '99',
            snapshotToken: 'invalid',
            expiresAt: DateTime.now().toUtc(),
            entities: const SnapshotEntitiesDto(
              // classroom sem academic_year existente dispara SqliteException sob foreign_keys = ON
              classrooms: [
                {
                  'id': 'cls-orphan',
                  'academic_year_id': 'non-existent-year',
                  'name': 'Turma Órfã',
                  'stage': 'elementary',
                  'year_number': 6,
                  'created_at': '2026-01-01T00:00:00.000Z',
                },
              ],
            ),
          );
        };

        await expectLater(() => orchestrator.synchronize(), throwsException);

        // Estado local não foi avançado para época 2 nem cursor 99:0
        final state = await outboxRepo.getOrCreateSyncState();
        expect(state.accountEpoch, equals(1));
        expect(state.serverCursor, equals('1:0'));
        expect(state.lastSyncStatus, equals('error'));
      },
    );

    // 11. Duas chamadas concorrentes sem execução simultânea dos ciclos
    test(
      '11. Duas chamadas concorrentes sem execução simultânea dos ciclos',
      () async {
        final completer = Completer<PullResponseDto>();
        fakeApiClient.onPull = (query) async {
          return await completer.future;
        };

        // Dispara primeira chamada assíncrona
        final future1 = orchestrator.synchronize();

        // Aguarda breve instante para que o lock seja adquirido
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(orchestrator.isSyncing, isTrue);

        // Segunda chamada concorrente
        final result2 = await orchestrator.synchronize();

        expect(result2.isAlreadyInProgress, isTrue);
        expect(result2.isSuccess, isFalse);

        // Desbloqueia a primeira chamada
        completer.complete(
          const PullResponseDto(
            epoch: '1',
            currentServerSeq: '10',
            nextCursor: '10:0',
            hasMore: false,
            changes: [],
          ),
        );

        final result1 = await future1;
        expect(result1.isSuccess, isTrue);
        expect(orchestrator.isSyncing, isFalse);
      },
    );

    // 12. Liberação do bloqueio após sucesso e após exceção
    test('12. Liberação do bloqueio após sucesso e após exceção', () async {
      // 1. Sucesso
      expect(orchestrator.isSyncing, isFalse);
      await orchestrator.synchronize();
      expect(orchestrator.isSyncing, isFalse);

      // 2. Exceção
      fakeApiClient.onPull = (query) async {
        throw const SyncNetworkException('Queda repentina de rede');
      };

      await expectLater(
        () => orchestrator.synchronize(),
        throwsA(isA<SyncNetworkException>()),
      );
      // Bloqueio liberado no bloco finally
      expect(orchestrator.isSyncing, isFalse);
    });

    // 13. Falha de rede preservando operações pendentes
    test('13. Falha de rede preservando operações pendentes', () async {
      final op = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-preserve',
        operation: SyncMutationType.insert,
        payload: {'name': 'Química'},
      );

      fakeApiClient.onPush = (request) async {
        throw const SyncNetworkException('Conexão recusada');
      };

      await expectLater(
        () => orchestrator.synchronize(),
        throwsA(isA<SyncNetworkException>()),
      );

      // A operação deve ter sido revertida para 'pending' (não 'sending', não 'failed')
      final pendingAfter = await outboxRepo.getPendingOperations();
      expect(pendingAfter, hasLength(1));
      expect(pendingAfter.first.operationId, equals(op.operationId));
      expect(pendingAfter.first.status, equals(SyncOutboxStatus.pending));

      // Estado de sincronização registrou erro
      final state = await outboxRepo.getOrCreateSyncState();
      expect(state.lastSyncStatus, equals('error'));
      expect(state.lastSyncError, contains('Conexão recusada'));
    });

    // 14. Atualização correta do "account_epoch" e do estado de sincronização
    test(
      '14. Atualização correta do account_epoch e do estado de sincronização',
      () async {
        fakeApiClient.onPull = (query) async {
          return const PullResponseDto(
            epoch: '3',
            currentServerSeq: '30',
            nextCursor: '30:0',
            hasMore: false,
            changes: [],
          );
        };

        final result = await orchestrator.synchronize();

        expect(result.isSuccess, isTrue);
        final state = await outboxRepo.getOrCreateSyncState();
        expect(state.accountEpoch, equals(3));
        expect(state.serverCursor, equals('30:0'));
        expect(state.lastSyncStatus, equals('idle'));
        expect(state.lastSyncError, isNull);
      },
    );

    // 15. Ausência de eco na Outbox durante a ingestão remota
    test('15. Ausência de eco na Outbox durante a ingestão remota via StagingHandler', () async {
      // Banco com ano letivo prévio para foreign key
      await db.customStatement('''
        INSERT INTO academic_years_table (id, year, title, start_date, end_date, total_mandatory_days, created_at)
        VALUES ('ay-base', 2026, 'Ano Base', '2026-02-01', '2026-12-15', 200, 1700000000);
      ''');

      fakeApiClient.onPull = (query) async {
        return PullResponseDto(
          epoch: '1',
          currentServerSeq: '15',
          nextCursor: '15:0',
          hasMore: false,
          changes: [
            ChangeDto(
              serverSeq: '12',
              changeLogId: '1201',
              entityType: SyncEntityType.subject,
              entityId: 'sub-remote-1',
              mutationType: 'INSERT',
              payload: {'id': 'sub-remote-1', 'name': 'Artes'},
              deviceId: 'peer-device',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
            ChangeDto(
              serverSeq: '13',
              changeLogId: '1301',
              entityType: SyncEntityType.classroom,
              entityId: 'cls-remote-1',
              mutationType: 'INSERT',
              payload: {
                'id': 'cls-remote-1',
                'academic_year_id': 'ay-base',
                'name': '6º Ano A',
                'stage': 'elementary',
                'year_number': 6,
                'created_at': '2026-01-01T00:00:00.000Z',
              },
              deviceId: 'peer-device',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
          ],
        );
      };

      // Verifica que outbox está inicialmente vazia
      final outboxBefore = await outboxRepo.getAllOperations();
      expect(outboxBefore, isEmpty);

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);
      expect(result.appliedChangesCount, equals(2));

      // As tabelas de domínio receberam os dados
      final subjects = await db
          .customSelect('SELECT * FROM subjects_table;')
          .get();
      final classrooms = await db
          .customSelect('SELECT * FROM classrooms_table;')
          .get();
      expect(subjects, hasLength(1));
      expect(classrooms, hasLength(1));

      // ZERO ECOS NA OUTBOX!
      final outboxAfter = await outboxRepo.getAllOperations();
      expect(outboxAfter, isEmpty);
    });

    // Teste complementar: forceSnapshot: true sob demanda
    test('forceSnapshot: true executa Snapshot inicial sob demanda', () async {
      fakeApiClient.onGetSnapshot = (token) async {
        return SnapshotResponseDto(
          epoch: '5',
          snapshotSeq: '80',
          snapshotToken: 'forced-token',
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
          entities: const SnapshotEntitiesDto(),
        );
      };

      final result = await orchestrator.synchronize(forceSnapshot: true);

      expect(result.isSuccess, isTrue);
      expect(result.snapshotApplied, isTrue);
      expect(fakeApiClient.snapshotCallsCount, equals(1));

      final state = await outboxRepo.getOrCreateSyncState();
      expect(state.accountEpoch, equals(5));
      expect(state.serverCursor, equals('80:0'));
    });
  });
}
