import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/repositories/schedule_slot_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/outbox/sync_payload_serializer.dart';
import 'package:drift/drift.dart';

/// Implementação Drift/SQLite para persistência da grade semanal de horários.
class DriftScheduleSlotRepository implements ScheduleSlotRepository {
  DriftScheduleSlotRepository(
    this._db, [
    SyncOutboxRepository? outboxRepository,
  ]) : _outboxRepository = outboxRepository ?? SyncOutboxRepository(_db);

  final AppDatabase _db;
  final SyncOutboxRepository _outboxRepository;

  @override
  Future<void> saveSlots(
    String classroomSubjectId,
    List<ScheduleSlot> slots,
  ) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();

      // Consulta slots anteriores para identificar remoções e atualizações
      final oldSlots =
          await (_db.select(_db.scheduleSlotsTable)..where(
                (tbl) => tbl.classroomSubjectId.equals(classroomSubjectId),
              ))
              .get();
      final newSlotIds = slots.map((s) => s.id).toSet();

      // Remove slots prévios excluídos da grade e enfileira tombstones
      for (final oldSlot in oldSlots) {
        if (!newSlotIds.contains(oldSlot.id)) {
          await (_db.delete(
            _db.scheduleSlotsTable,
          )..where((tbl) => tbl.id.equals(oldSlot.id))).go();
          await _outboxRepository.enqueueDelete(
            entityType: SyncEntityType.scheduleSlot,
            entityId: oldSlot.id,
          );
        }
      }

      // Atualiza ou insere os slots vigentes na grade horária
      for (final slot in slots) {
        final existing = oldSlots.where((s) => s.id == slot.id).firstOrNull;
        final isUpdate = existing != null;

        if (isUpdate) {
          await (_db.update(
            _db.scheduleSlotsTable,
          )..where((tbl) => tbl.id.equals(slot.id))).write(
            ScheduleSlotsTableCompanion(
              classroomSubjectId: Value(classroomSubjectId),
              weekday: Value(slot.weekday),
              orderIndex: Value(slot.orderIndex),
              startTime: Value(slot.startTime),
              endTime: Value(slot.endTime),
              updatedAt: Value(now),
            ),
          );
        } else {
          await _db
              .into(_db.scheduleSlotsTable)
              .insert(
                ScheduleSlotsTableCompanion(
                  id: Value(slot.id),
                  classroomSubjectId: Value(classroomSubjectId),
                  weekday: Value(slot.weekday),
                  orderIndex: Value(slot.orderIndex),
                  startTime: Value(slot.startTime),
                  endTime: Value(slot.endTime),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }

        final payload = SyncPayloadSerializer.scheduleSlot(
          slot,
          classroomSubjectId: classroomSubjectId,
          createdAt: isUpdate ? null : now,
          updatedAt: now,
        );

        await _outboxRepository.enqueueOperation(
          entityType: SyncEntityType.scheduleSlot,
          entityId: slot.id,
          operation: isUpdate
              ? SyncMutationType.update
              : SyncMutationType.insert,
          payload: payload,
        );
      }
    });
  }

  @override
  Future<List<ScheduleSlot>> getByClassroomSubject(
    String classroomSubjectId,
  ) async {
    final query = _db.select(_db.scheduleSlotsTable)
      ..where((tbl) => tbl.classroomSubjectId.equals(classroomSubjectId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.weekday),
        (tbl) => OrderingTerm.asc(tbl.orderIndex),
      ]);

    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<ScheduleSlot>> getByClassroom(String classroomId) async {
    // Join entre ScheduleSlotsTable e ClassroomSubjectsTable
    final query =
        _db.select(_db.scheduleSlotsTable).join([
            innerJoin(
              _db.classroomSubjectsTable,
              _db.classroomSubjectsTable.id.equalsExp(
                _db.scheduleSlotsTable.classroomSubjectId,
              ),
            ),
          ])
          ..where(_db.classroomSubjectsTable.classroomId.equals(classroomId))
          ..orderBy([
            OrderingTerm.asc(_db.scheduleSlotsTable.weekday),
            OrderingTerm.asc(_db.scheduleSlotsTable.orderIndex),
          ]);

    final rows = await query.get();
    return rows.map((row) {
      final slotData = row.readTable(_db.scheduleSlotsTable);
      return _toDomain(slotData);
    }).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      final deletedCount = await (_db.delete(
        _db.scheduleSlotsTable,
      )..where((tbl) => tbl.id.equals(id))).go();

      if (deletedCount > 0) {
        await _outboxRepository.enqueueDelete(
          entityType: SyncEntityType.scheduleSlot,
          entityId: id,
        );
      }
    });
  }

  ScheduleSlot _toDomain(ScheduleSlotsTableData row) {
    return ScheduleSlot(
      id: row.id,
      classroomSubjectId: row.classroomSubjectId,
      weekday: row.weekday,
      orderIndex: row.orderIndex,
      startTime: row.startTime,
      endTime: row.endTime,
    );
  }
}
