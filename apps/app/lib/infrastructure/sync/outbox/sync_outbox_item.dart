import 'dart:convert';

import 'package:app/infrastructure/sync/models/sync_operation_dto.dart';

/// Status de processamento de um registro na fila de saída (Outbox).
abstract final class SyncOutboxStatus {
  static const String pending = 'pending';
  static const String sending = 'sending';
  static const String failed = 'failed';

  static bool isValid(String status) =>
      status == pending || status == sending || status == failed;
}

/// Item da fila de saída transacional (`SyncOutboxTable`).
class SyncOutboxItem {
  const SyncOutboxItem({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payloadJson,
    required this.localRevision,
    this.status = SyncOutboxStatus.pending,
    required this.createdAt,
  });

  /// Identificador UUID v4 universalmente único e estável da operação.
  final String operationId;

  /// Tipo canônico da entidade sincronizada (ex: `academic_year`, `planned_lesson`).
  final String entityType;

  /// Identificador único da entidade (UUID ou tupla `${id1}:${id2}`).
  final String entityId;

  /// Tipo de mutação (`INSERT`, `UPDATE`, `DELETE`).
  final String operation;

  /// Payload JSON serializado da entidade ou null se for exclusão.
  final String? payloadJson;

  /// Número de sequência/revisão local monotônica e estritamente crescente.
  final int localRevision;

  /// Status na fila de saída (`pending`, `sending`, `failed`).
  final String status;

  /// Timestamp UTC de inclusão da operação na outbox.
  final DateTime createdAt;

  /// Converte o JSON do payload em mapa Dart ou retorna null se ausente.
  Map<String, dynamic>? get payloadMap {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    return jsonDecode(payloadJson!) as Map<String, dynamic>;
  }

  /// Converte para o DTO canônico de Push do protocolo de sincronização.
  SyncOperationDto toDto() {
    return SyncOperationDto(
      clientOpId: operationId,
      entityType: entityType,
      entityId: entityId,
      mutationType: operation,
      payload: payloadMap,
      clientCreatedAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOutboxItem &&
          runtimeType == other.runtimeType &&
          operationId == other.operationId &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          operation == other.operation &&
          payloadJson == other.payloadJson &&
          localRevision == other.localRevision &&
          status == other.status &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    operationId,
    entityType,
    entityId,
    operation,
    payloadJson,
    localRevision,
    status,
    createdAt,
  );
}

/// Registro de lápide de exclusão de entidade (`SyncTombstonesTable`).
class SyncTombstoneItem {
  const SyncTombstoneItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationId,
    required this.deletedAt,
    required this.localRevision,
    this.synced = false,
  });

  /// Identificador UUID da lápide.
  final String id;

  /// Tipo canônico da entidade excluída.
  final String entityType;

  /// Identificador da entidade excluída.
  final String entityId;

  /// Identificador da operação DELETE correspondente na Outbox.
  final String operationId;

  /// Timestamp UTC em que a exclusão local ocorreu.
  final DateTime deletedAt;

  /// Revisão local associada à exclusão.
  final int localRevision;

  /// Indica se a exclusão já foi propagada e confirmada pelo servidor.
  final bool synced;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncTombstoneItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          operationId == other.operationId &&
          deletedAt == other.deletedAt &&
          localRevision == other.localRevision &&
          synced == other.synced;

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operationId,
    deletedAt,
    localRevision,
    synced,
  );
}

/// Metadados e estado de controle de sincronização local (`SyncStateTable`).
class SyncStateItem {
  const SyncStateItem({
    this.id = 'default',
    this.lastSyncedAt,
    this.lastSyncStatus = 'idle',
    this.lastSyncError,
    this.serverCursor,
    required this.deviceId,
    this.accountEmail,
    this.localRevision = 0,
    this.accountEpoch = 1,
    required this.updatedAt,
  });

  final String id;
  final DateTime? lastSyncedAt;
  final String lastSyncStatus;
  final String? lastSyncError;
  final String? serverCursor;
  final String deviceId;
  final String? accountEmail;
  final int localRevision;
  final int accountEpoch;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStateItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          lastSyncedAt == other.lastSyncedAt &&
          lastSyncStatus == other.lastSyncStatus &&
          lastSyncError == other.lastSyncError &&
          serverCursor == other.serverCursor &&
          deviceId == other.deviceId &&
          accountEmail == other.accountEmail &&
          localRevision == other.localRevision &&
          accountEpoch == other.accountEpoch &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    lastSyncedAt,
    lastSyncStatus,
    lastSyncError,
    serverCursor,
    deviceId,
    accountEmail,
    localRevision,
    accountEpoch,
    updatedAt,
  );
}
