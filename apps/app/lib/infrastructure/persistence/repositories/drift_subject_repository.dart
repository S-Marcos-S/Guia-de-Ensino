import 'package:app/domain/models/subject.dart';
import 'package:app/domain/repositories/subject_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/outbox/sync_payload_serializer.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de Disciplinas utilizando Drift e SQLite.
class DriftSubjectRepository implements SubjectRepository {
  DriftSubjectRepository(this._db, [SyncOutboxRepository? outboxRepository])
    : _outboxRepository = outboxRepository ?? SyncOutboxRepository(_db);

  final AppDatabase _db;
  final SyncOutboxRepository _outboxRepository;

  @override
  Future<void> save(Subject subject) async {
    await _db.transaction(() async {
      final existing = await findById(subject.id);
      final isUpdate = existing != null;
      final now = DateTime.now().toUtc();

      if (isUpdate) {
        await (_db.update(
          _db.subjectsTable,
        )..where((tbl) => tbl.id.equals(subject.id))).write(
          SubjectsTableCompanion(
            name: Value(subject.name),
            colorHex: Value(subject.colorHex),
            updatedAt: Value(now),
          ),
        );
      } else {
        await _db
            .into(_db.subjectsTable)
            .insert(
              SubjectsTableCompanion(
                id: Value(subject.id),
                name: Value(subject.name),
                colorHex: Value(subject.colorHex),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }

      final payload = SyncPayloadSerializer.subject(
        subject,
        createdAt: isUpdate ? null : now,
        updatedAt: now,
      );

      await _outboxRepository.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: subject.id,
        operation: isUpdate ? SyncMutationType.update : SyncMutationType.insert,
        payload: payload,
      );
    });
  }

  @override
  Future<Subject?> findById(String id) async {
    final query = _db.select(_db.subjectsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<Subject?> findByName(String name) async {
    final query = _db.select(_db.subjectsTable)
      ..where((tbl) => tbl.name.equals(name));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<List<Subject>> getAll() async {
    final rows = await (_db.select(
      _db.subjectsTable,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.name)])).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.subjectsTable,
      )..where((tbl) => tbl.id.equals(id))).go();

      await _outboxRepository.enqueueDelete(
        entityType: SyncEntityType.subject,
        entityId: id,
      );
    });
  }

  Subject _toDomain(SubjectsTableData data) {
    return Subject(id: data.id, name: data.name, colorHex: data.colorHex);
  }
}
