import 'dart:async';

import 'package:uuid/uuid.dart';

import '../client/sync_api_client.dart';
import '../client/sync_exceptions.dart';
import '../models/operation_ack_dto.dart';
import '../models/pull_query_dto.dart';
import '../models/pull_response_dto.dart';
import '../models/push_request_dto.dart';
import '../models/push_response_dto.dart';
import '../outbox/sync_outbox_item.dart';
import '../outbox/sync_outbox_repository.dart';
import 'sync_staging_handler.dart';

/// Status resultante de uma tentativa de ciclo de sincronização.
enum SyncOrchestrationStatus {
  /// Ciclo executado com êxito (Push e/ou Pull concluídos com sucesso).
  success,

  /// Um ciclo de sincronização já estava em andamento (bloqueio de exclusão mútua ativo).
  alreadyInProgress,

  /// Falha durante a execução do ciclo de sincronização.
  failure,
}

/// Resultado detalhado e observável da execução do ciclo de sincronização.
class SyncResult {
  const SyncResult({
    required this.status,
    this.pushedOperationsCount = 0,
    this.appliedChangesCount = 0,
    this.snapshotApplied = false,
    this.error,
    this.conflictDetails = const [],
  });

  const SyncResult.success({
    int pushedOperationsCount = 0,
    int appliedChangesCount = 0,
    bool snapshotApplied = false,
    List<ConflictDetailsDto> conflictDetails = const [],
  }) : this(
         status: SyncOrchestrationStatus.success,
         pushedOperationsCount: pushedOperationsCount,
         appliedChangesCount: appliedChangesCount,
         snapshotApplied: snapshotApplied,
         conflictDetails: conflictDetails,
       );

  const SyncResult.alreadyInProgress()
    : this(status: SyncOrchestrationStatus.alreadyInProgress);

  const SyncResult.failure({
    required Object error,
    int pushedOperationsCount = 0,
    int appliedChangesCount = 0,
    bool snapshotApplied = false,
    List<ConflictDetailsDto> conflictDetails = const [],
  }) : this(
         status: SyncOrchestrationStatus.failure,
         pushedOperationsCount: pushedOperationsCount,
         appliedChangesCount: appliedChangesCount,
         snapshotApplied: snapshotApplied,
         error: error,
         conflictDetails: conflictDetails,
       );

  final SyncOrchestrationStatus status;
  final int pushedOperationsCount;
  final int appliedChangesCount;
  final bool snapshotApplied;
  final Object? error;
  final List<ConflictDetailsDto> conflictDetails;

  bool get isSuccess => status == SyncOrchestrationStatus.success;
  bool get isAlreadyInProgress =>
      status == SyncOrchestrationStatus.alreadyInProgress;
  bool get isFailure => status == SyncOrchestrationStatus.failure;

  @override
  String toString() {
    return 'SyncResult(status: $status, pushed: $pushedOperationsCount, '
        'applied: $appliedChangesCount, snapshot: $snapshotApplied, '
        'conflicts: ${conflictDetails.length}, error: $error)';
  }
}

/// Orquestrador de sincronização local-first entre o SQLite local (via Drift) e o backend NestJS.
///
/// Responsabilidades principais:
/// 1. Coordenação de exclusão mútua local via [_isSyncing] prevenindo execuções simultâneas.
/// 2. Recuperação de falhas e redefinição de operações penduradas em 'sending' para 'pending'.
/// 3. Ciclo Push: envio em lotes ordenados pela revisão local (teto de 100 operações por lote).
/// 4. Processamento estrito de ACKs ('APPLIED', 'SKIPPED', 'CONFLICT') e confirmação de lápides.
/// 5. Ciclo Pull: leitura incremental paginada com cursor composto e descarte de eco via [excludeDeviceId].
/// 6. Ingestão direta via [SyncStagingHandler], eliminando geração de ecos na Outbox local.
/// 7. Recuperação segura via Snapshot em caso de HTTP 410 / [SyncResyncRequiredException].
/// 8. Manutenção atômica do estado de sincronização em `sync_state_table`.
class SyncOrchestrator {
  SyncOrchestrator({
    required SyncApiClient apiClient,
    required SyncOutboxRepository outboxRepository,
    required SyncStagingHandler stagingHandler,
    Uuid? uuid,
  }) : _apiClient = apiClient,
       _outboxRepository = outboxRepository,
       _stagingHandler = stagingHandler,
       _uuid = uuid ?? const Uuid();

  final SyncApiClient _apiClient;
  final SyncOutboxRepository _outboxRepository;
  final SyncStagingHandler _stagingHandler;
  final Uuid _uuid;

  bool _isSyncing = false;

  /// Indica se um ciclo de sincronização está ativo no momento.
  bool get isSyncing => _isSyncing;

  /// Executa o ciclo completo de sincronização (Push -> Pull).
  ///
  /// Caso [forceSnapshot] seja true, solicita e ingere um Snapshot completo
  /// antes de prosseguir com os ciclos ordinários.
  ///
  /// Caso [rethrowExceptions] seja true (padrão), qualquer falha de transporte
  /// ou persistência será propagada após o registro em banco e liberação do mutex.
  Future<SyncResult> synchronize({
    bool forceSnapshot = false,
    bool rethrowExceptions = true,
  }) async {
    if (_isSyncing) {
      return const SyncResult.alreadyInProgress();
    }

    _isSyncing = true;
    try {
      final result = await _executeSyncCycle(forceSnapshot: forceSnapshot);
      return result;
    } catch (e) {
      await _outboxRepository.updateSyncFailure(e.toString());
      if (rethrowExceptions) {
        rethrow;
      }
      return SyncResult.failure(error: e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<SyncResult> _executeSyncCycle({required bool forceSnapshot}) async {
    // 1. Recuperação defensiva de operações interrompidas em trânsito
    await _outboxRepository.resetSendingToPending();

    var state = await _outboxRepository.getOrCreateSyncState();
    var snapshotApplied = false;

    // 2. Snapshot forçado sob demanda
    if (forceSnapshot) {
      state = await _recoverSnapshot(state);
      snapshotApplied = true;
    }

    // 3. Loop de Push (envio das mutações locais pendentes)
    final pushResult = await _executePushLoop(state);

    // Atualiza estado local caso o push tenha alterado metadados locais
    state = await _outboxRepository.getOrCreateSyncState();

    // 4. Loop de Pull (recebimento incremental de alterações remotas)
    final pullResult = await _executePullLoop(state);

    final finalSnapshotApplied = snapshotApplied || pullResult.snapshotApplied;

    return SyncResult.success(
      pushedOperationsCount: pushResult.pushedCount,
      appliedChangesCount: pullResult.appliedChangesCount,
      snapshotApplied: finalSnapshotApplied,
      conflictDetails: pushResult.conflicts,
    );
  }

  Future<_PushLoopResult> _executePushLoop(SyncStateItem state) async {
    var totalPushed = 0;
    final allConflicts = <ConflictDetailsDto>[];

    while (true) {
      // Lê até 100 operações pendentes na ordem FIFO de revisão local
      final pendingOps = await _outboxRepository.getPendingOperations(
        limit: 100,
      );
      if (pendingOps.isEmpty) {
        break;
      }

      final batchOpIds = pendingOps.map((op) => op.operationId).toList();

      // Transiciona operações para 'sending' antes da chamada de rede
      await _outboxRepository.updateStatus(
        batchOpIds,
        SyncOutboxStatus.sending,
      );

      final clientBatchId = _uuid.v4();
      final request = PushRequestDto(
        deviceId: state.deviceId,
        clientBatchId: clientBatchId,
        operations: pendingOps.map((op) => op.toDto()).toList(),
      );

      PushResponseDto response;
      try {
        response = await _apiClient.push(request);
      } catch (e) {
        // Falha no envio: reverte lote inteiro para 'pending' para permitir nova tentativa
        await _outboxRepository.updateStatus(
          batchOpIds,
          SyncOutboxStatus.pending,
        );
        rethrow;
      }

      // Processamento granular de ACKs
      final batchIdSet = batchOpIds.toSet();
      final appliedIds = <String>[];
      final conflictIds = <String>[];

      for (final ack in response.acks) {
        if (!batchIdSet.contains(ack.clientOpId)) {
          // Ignora ACK de operação não pertencente a este lote
          continue;
        }

        if (ack.isApplied || ack.isSkipped) {
          appliedIds.add(ack.clientOpId);
        } else if (ack.isConflict) {
          conflictIds.add(ack.clientOpId);
          if (ack.conflict != null) {
            allConflicts.add(ack.conflict!);
          }
        }
      }

      // Operações do lote que não receberam ACK reconhecido voltam para 'pending'
      final unacknowledged = batchOpIds
          .where((id) => !appliedIds.contains(id) && !conflictIds.contains(id))
          .toList();
      if (unacknowledged.isNotEmpty) {
        await _outboxRepository.updateStatus(
          unacknowledged,
          SyncOutboxStatus.pending,
        );
      }

      // Operações confirmadas são removidas e lápides marcadas como sincronizadas
      if (appliedIds.isNotEmpty) {
        await _outboxRepository.removeOperations(appliedIds);
        await _outboxRepository.markTombstonesSyncedByOperationIds(appliedIds);
        totalPushed += appliedIds.length;
      }

      // Conflitos são marcados como 'failed'
      if (conflictIds.isNotEmpty) {
        await _outboxRepository.updateStatus(
          conflictIds,
          SyncOutboxStatus.failed,
        );
      }

      // Se o lote tinha menos de 100 itens, todos os pendentes foram processados
      if (pendingOps.length < 100) {
        break;
      }
    }

    return _PushLoopResult(pushedCount: totalPushed, conflicts: allConflicts);
  }

  Future<_PullLoopResult> _executePullLoop(SyncStateItem initialState) async {
    var state = initialState;
    var totalAppliedChanges = 0;
    var snapshotRecovered = false;

    while (true) {
      final query = PullQueryDto(
        cursor: state.serverCursor,
        excludeDeviceId: state.deviceId,
        clientEpoch: state.accountEpoch.toString(),
        limit: 100,
      );

      PullResponseDto response;
      try {
        response = await _apiClient.pull(query);
      } on SyncResyncRequiredException {
        // Servidor sinalizou RESYNC_REQUIRED (HTTP 410) por descontinuidade de época
        state = await _recoverSnapshot(state);
        snapshotRecovered = true;
        // Recomeça o ciclo de pull com o novo cursor derivado do snapshot
        continue;
      }

      // Ingestão remota direta dos deltas via StagingHandler
      if (response.changes.isNotEmpty) {
        await _stagingHandler.applyChanges(response.changes);
        totalAppliedChanges += response.changes.length;
      }

      // O cursor e a época só avançam após o término bem-sucedido da aplicação das alterações
      final epochInt = int.tryParse(response.epoch) ?? state.accountEpoch;
      await _outboxRepository.updateSyncState(
        serverCursor: response.nextCursor,
        accountEpoch: epochInt,
        lastSyncedAt: DateTime.now().toUtc(),
      );

      state = await _outboxRepository.getOrCreateSyncState();

      if (!response.hasMore) {
        break;
      }

      // Prevenção contra loops infinitos em caso de resposta anômala do servidor
      if (response.changes.isEmpty && response.nextCursor == query.cursor) {
        break;
      }
    }

    return _PullLoopResult(
      appliedChangesCount: totalAppliedChanges,
      snapshotApplied: snapshotRecovered,
    );
  }

  Future<SyncStateItem> _recoverSnapshot(SyncStateItem currentState) async {
    final snapshot = await _apiClient.getSnapshot();

    // Aplicação atômica transacional de todas as 13 coleções pedagógicas
    await _stagingHandler.applySnapshot(snapshot.entities);

    final newEpoch =
        int.tryParse(snapshot.epoch) ?? (currentState.accountEpoch + 1);
    final newCursor = '${snapshot.snapshotSeq}:0';

    await _outboxRepository.updateSyncState(
      serverCursor: newCursor,
      accountEpoch: newEpoch,
      lastSyncedAt: DateTime.now().toUtc(),
    );

    return await _outboxRepository.getOrCreateSyncState();
  }
}

class _PushLoopResult {
  const _PushLoopResult({required this.pushedCount, required this.conflicts});

  final int pushedCount;
  final List<ConflictDetailsDto> conflicts;
}

class _PullLoopResult {
  const _PullLoopResult({
    required this.appliedChangesCount,
    required this.snapshotApplied,
  });

  final int appliedChangesCount;
  final bool snapshotApplied;
}
