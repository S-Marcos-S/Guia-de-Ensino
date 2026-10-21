import 'dart:convert';

import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_item.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Repositório de persistência transacional da fila de saída (Outbox),
/// lápides (Tombstones) e estado de revisão local (`SyncStateTable`).
class SyncOutboxRepository {
  SyncOutboxRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Enfileira atomicamente uma mutação na `SyncOutboxTable`.
  ///
  /// Executa dentro da transação ativa do banco de dados para garantir
  /// que a mutação local e seu registro na Outbox sejam confirmados
  /// ou revertidos conjuntamente.
  Future<SyncOutboxItem> enqueueOperation({
    required String entityType,
    required String entityId,
    required String operation,
    Map<String, dynamic>? payload,
    String? customOperationId,
    DateTime? createdAt,
  }) async {
    final operationId = customOperationId ?? _uuid.v4();
    final localRevision = await getNextLocalRevision();
    final payloadJson = payload != null ? jsonEncode(payload) : null;
    final created = (createdAt ?? DateTime.now()).toUtc();
    final createdSec = created.millisecondsSinceEpoch ~/ 1000;

    await _db.customStatement(
      '''
      INSERT INTO sync_outbox_table (operation_id, entity_type, entity_id, operation, payload_json, local_revision, status, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        operationId,
        entityType,
        entityId,
        operation,
        payloadJson,
        localRevision,
        SyncOutboxStatus.pending,
        createdSec,
      ],
    );

    return SyncOutboxItem(
      operationId: operationId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      localRevision: localRevision,
      status: SyncOutboxStatus.pending,
      createdAt: created,
    );
  }

  /// Enfileira atomicamente uma exclusão na Outbox e gera a respectiva lápide em `SyncTombstonesTable`.
  Future<SyncOutboxItem> enqueueDelete({
    required String entityType,
    required String entityId,
    String? customOperationId,
    DateTime? deletedAt,
  }) async {
    final op = await enqueueOperation(
      entityType: entityType,
      entityId: entityId,
      operation: SyncMutationType.delete,
      payload: null,
      customOperationId: customOperationId,
      createdAt: deletedAt,
    );

    final tombstoneId = _uuid.v4();
    final deleted = (deletedAt ?? op.createdAt).toUtc();
    final deletedSec = deleted.millisecondsSinceEpoch ~/ 1000;

    await _db.customStatement(
      '''
      INSERT INTO sync_tombstones_table (id, entity_type, entity_id, operation_id, deleted_at, local_revision, synced)
      VALUES (?, ?, ?, ?, ?, ?, 0)
      ON CONFLICT (entity_type, entity_id) DO UPDATE SET
        operation_id = EXCLUDED.operation_id,
        deleted_at = EXCLUDED.deleted_at,
        local_revision = EXCLUDED.local_revision,
        synced = 0;
      ''',
      [
        tombstoneId,
        entityType,
        entityId,
        op.operationId,
        deletedSec,
        op.localRevision,
      ],
    );

    return op;
  }

  /// Consulta itens pendentes da Outbox em ordem FIFO estritamente crescente de revisão local.
  Future<List<SyncOutboxItem>> getPendingOperations({int limit = 100}) async {
    final rows = await _db
        .customSelect(
          '''
          SELECT operation_id, entity_type, entity_id, operation, payload_json, local_revision, status, created_at
          FROM sync_outbox_table
          WHERE status = ?
          ORDER BY local_revision ASC
          LIMIT ?;
          ''',
          variables: [
            const Variable<String>(SyncOutboxStatus.pending),
            Variable<int>(limit),
          ],
        )
        .get();

    return rows.map(_mapOutboxItem).toList();
  }

  /// Consulta todas as operações da Outbox (para auditoria ou inspeção de testes).
  Future<List<SyncOutboxItem>> getAllOperations() async {
    final rows = await _db.customSelect('''
          SELECT operation_id, entity_type, entity_id, operation, payload_json, local_revision, status, created_at
          FROM sync_outbox_table
          ORDER BY local_revision ASC;
          ''').get();

    return rows.map(_mapOutboxItem).toList();
  }

  /// Atualiza o status de um conjunto de operações (ex: transição para `sending` ou `failed`).
  Future<void> updateStatus(List<String> operationIds, String newStatus) async {
    if (operationIds.isEmpty) return;

    final placeholders = List.filled(operationIds.length, '?').join(', ');
    await _db.customStatement(
      '''
      UPDATE sync_outbox_table
      SET status = ?
      WHERE operation_id IN ($placeholders);
      ''',
      [newStatus, ...operationIds],
    );
  }

  /// Remove operações confirmadas pelo servidor (ACK recebido).
  Future<void> removeOperations(List<String> operationIds) async {
    if (operationIds.isEmpty) return;

    final placeholders = List.filled(operationIds.length, '?').join(', ');
    await _db.customStatement('''
      DELETE FROM sync_outbox_table
      WHERE operation_id IN ($placeholders);
      ''', operationIds);
  }

  /// Recuperação pós-queda/reinicialização: reverte operações em trânsito (`sending`)
  /// de volta para `pending`, permitindo nova tentativa segura sem perda de dados.
  Future<int> resetSendingToPending() async {
    final rowsBefore = await _db
        .customSelect(
          "SELECT COUNT(*) AS c FROM sync_outbox_table WHERE status = 'sending';",
        )
        .getSingle();
    final count = rowsBefore.read<int>('c');

    if (count > 0) {
      await _db.customStatement('''
        UPDATE sync_outbox_table
        SET status = 'pending'
        WHERE status = 'sending';
        ''');
    }

    return count;
  }

  /// Consulta lápides registradas, opcionalmente filtrando por status de sincronização.
  Future<List<SyncTombstoneItem>> getTombstones({bool? synced}) async {
    final String sql;
    final List<Variable> vars;

    if (synced != null) {
      sql = '''
        SELECT id, entity_type, entity_id, operation_id, deleted_at, local_revision, synced
        FROM sync_tombstones_table
        WHERE synced = ?
        ORDER BY local_revision ASC;
      ''';
      vars = [Variable<int>(synced ? 1 : 0)];
    } else {
      sql = '''
        SELECT id, entity_type, entity_id, operation_id, deleted_at, local_revision, synced
        FROM sync_tombstones_table
        ORDER BY local_revision ASC;
      ''';
      vars = const [];
    }

    final rows = await _db.customSelect(sql, variables: vars).get();
    return rows.map(_mapTombstoneItem).toList();
  }

  /// Marca lápides como sincronizadas com o servidor a partir dos IDs das próprias lápides.
  Future<void> markTombstonesSynced(List<String> tombstoneIds) async {
    if (tombstoneIds.isEmpty) return;

    final placeholders = List.filled(tombstoneIds.length, '?').join(', ');
    await _db.customStatement('''
      UPDATE sync_tombstones_table
      SET synced = 1
      WHERE id IN ($placeholders);
      ''', tombstoneIds);
  }

  /// Marca lápides como sincronizadas a partir dos identificadores de operação (`operation_id` / `clientOpId`)
  /// confirmados com sucesso pelo servidor através de ACKs de Push.
  Future<void> markTombstonesSyncedByOperationIds(
    List<String> operationIds,
  ) async {
    final uniqueIds = operationIds.toSet().toList();
    if (uniqueIds.isEmpty) return;

    const chunkSize = 100;
    for (var i = 0; i < uniqueIds.length; i += chunkSize) {
      final chunk = uniqueIds.sublist(
        i,
        i + chunkSize > uniqueIds.length ? uniqueIds.length : i + chunkSize,
      );
      final placeholders = List.filled(chunk.length, '?').join(', ');
      await _db.customStatement('''
        UPDATE sync_tombstones_table
        SET synced = 1
        WHERE operation_id IN ($placeholders);
        ''', chunk);
    }
  }

  /// Reserva e avança atomicamente a próxima revisão local (`local_revision`) em `SyncStateTable`.
  Future<int> getNextLocalRevision() async {
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    // Garante que o registro default existe antes de incrementar
    final existing = await _db
        .customSelect(
          "SELECT local_revision FROM sync_state_table WHERE id = 'default';",
        )
        .getSingleOrNull();

    if (existing == null) {
      await getOrCreateSyncState();
    }

    await _db.customStatement(
      '''
      UPDATE sync_state_table
      SET local_revision = local_revision + 1, updated_at = ?
      WHERE id = 'default';
      ''',
      [nowSec],
    );

    final row = await _db
        .customSelect(
          "SELECT local_revision FROM sync_state_table WHERE id = 'default';",
        )
        .getSingle();

    return row.read<int>('local_revision');
  }

  /// Retorna a revisão local atual sem incrementá-la.
  Future<int> getCurrentLocalRevision() async {
    final row = await _db
        .customSelect(
          "SELECT local_revision FROM sync_state_table WHERE id = 'default';",
        )
        .getSingleOrNull();

    return row?.read<int>('local_revision') ?? 0;
  }

  /// Obtém ou inicializa o registro único de estado de sincronização local (`SyncStateTable`).
  Future<SyncStateItem> getOrCreateSyncState({String? deviceId}) async {
    final row = await _db
        .customSelect("SELECT * FROM sync_state_table WHERE id = 'default';")
        .getSingleOrNull();

    if (row != null) {
      return _mapStateItem(row);
    }

    final devId = deviceId ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final nowSec = now.millisecondsSinceEpoch ~/ 1000;

    await _db.customStatement(
      '''
      INSERT INTO sync_state_table (id, device_id, local_revision, account_epoch, last_sync_status, updated_at)
      VALUES ('default', ?, 0, 1, 'idle', ?)
      ON CONFLICT (id) DO NOTHING;
      ''',
      [devId, nowSec],
    );

    final insertedRow = await _db
        .customSelect("SELECT * FROM sync_state_table WHERE id = 'default';")
        .getSingle();

    return _mapStateItem(insertedRow);
  }

  /// Atualiza o cursor do servidor e a data da última sincronização bem-sucedida.
  Future<void> updateSyncSuccess({
    required String serverCursor,
    DateTime? lastSyncedAt,
  }) async {
    final synced = (lastSyncedAt ?? DateTime.now()).toUtc();
    final syncedSec = synced.millisecondsSinceEpoch ~/ 1000;
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    await _db.customStatement(
      '''
      UPDATE sync_state_table
      SET server_cursor = ?, last_synced_at = ?, last_sync_status = 'idle', last_sync_error = NULL, updated_at = ?
      WHERE id = 'default';
      ''',
      [serverCursor, syncedSec, nowSec],
    );
  }

  /// Atualiza o cursor do servidor, a época ativa e a data da última sincronização bem-sucedida em `SyncStateTable`,
  /// redefinindo o status para 'idle', limpando eventuais erros e preservando identificadores locais.
  Future<void> updateSyncState({
    required String serverCursor,
    required int accountEpoch,
    DateTime? lastSyncedAt,
  }) async {
    final existing = await _db
        .customSelect("SELECT id FROM sync_state_table WHERE id = 'default';")
        .getSingleOrNull();

    if (existing == null) {
      await getOrCreateSyncState();
    }

    final synced = (lastSyncedAt ?? DateTime.now()).toUtc();
    final syncedSec = synced.millisecondsSinceEpoch ~/ 1000;
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    await _db.customStatement(
      '''
      UPDATE sync_state_table
      SET server_cursor = ?, account_epoch = ?, last_synced_at = ?, last_sync_status = 'idle', last_sync_error = NULL, updated_at = ?
      WHERE id = 'default';
      ''',
      [serverCursor, accountEpoch, syncedSec, nowSec],
    );
  }

  /// Atualiza o status de sincronização para falha com registro do erro.
  Future<void> updateSyncFailure(String errorMessage) async {
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    await _db.customStatement(
      '''
      UPDATE sync_state_table
      SET last_sync_status = 'error', last_sync_error = ?, updated_at = ?
      WHERE id = 'default';
      ''',
      [errorMessage, nowSec],
    );
  }

  SyncOutboxItem _mapOutboxItem(QueryRow r) {
    return SyncOutboxItem(
      operationId: r.read<String>('operation_id'),
      entityType: r.read<String>('entity_type'),
      entityId: r.read<String>('entity_id'),
      operation: r.read<String>('operation'),
      payloadJson: r.readNullable<String>('payload_json'),
      localRevision: r.read<int>('local_revision'),
      status: r.read<String>('status'),
      createdAt: r.read<DateTime>('created_at').toUtc(),
    );
  }

  SyncTombstoneItem _mapTombstoneItem(QueryRow r) {
    return SyncTombstoneItem(
      id: r.read<String>('id'),
      entityType: r.read<String>('entity_type'),
      entityId: r.read<String>('entity_id'),
      operationId: r.read<String>('operation_id'),
      deletedAt: r.read<DateTime>('deleted_at').toUtc(),
      localRevision: r.read<int>('local_revision'),
      synced: r.read<bool>('synced'),
    );
  }

  SyncStateItem _mapStateItem(QueryRow r) {
    return SyncStateItem(
      id: r.read<String>('id'),
      lastSyncedAt: r.readNullable<DateTime>('last_synced_at')?.toUtc(),
      lastSyncStatus: r.read<String>('last_sync_status'),
      lastSyncError: r.readNullable<String>('last_sync_error'),
      serverCursor: r.readNullable<String>('server_cursor'),
      deviceId: r.read<String>('device_id'),
      accountEmail: r.readNullable<String>('account_email'),
      localRevision: r.read<int>('local_revision'),
      accountEpoch: r.read<int>('account_epoch'),
      updatedAt: r.read<DateTime>('updated_at').toUtc(),
    );
  }
}
