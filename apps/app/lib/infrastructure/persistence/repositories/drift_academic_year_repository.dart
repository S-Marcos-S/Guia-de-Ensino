import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/repositories/academic_year_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/outbox/sync_payload_serializer.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de Anos Letivos utilizando Drift e SQLite.
class DriftAcademicYearRepository implements AcademicYearRepository {
  DriftAcademicYearRepository(
    this._db, [
    SyncOutboxRepository? outboxRepository,
  ]) : _outboxRepository = outboxRepository ?? SyncOutboxRepository(_db);

  final AppDatabase _db;
  final SyncOutboxRepository _outboxRepository;

  @override
  Future<void> save(AcademicYear academicYear) async {
    await _db.transaction(() async {
      final existing = await findById(academicYear.id);
      final isUpdate = existing != null;
      final now = DateTime.now().toUtc();

      await _db
          .into(_db.academicYearsTable)
          .insertOnConflictUpdate(
            AcademicYearsTableCompanion(
              id: Value(academicYear.id),
              year: Value(academicYear.year),
              title: Value(academicYear.title),
              startDate: Value(academicYear.startDate),
              endDate: Value(academicYear.endDate),
              totalMandatoryDays: Value(academicYear.totalMandatoryDays),
              createdAt: isUpdate ? const Value<DateTime>.absent() : Value(now),
              updatedAt: Value(now),
            ),
          );

      final payload = SyncPayloadSerializer.academicYear(
        academicYear,
        createdAt: isUpdate ? null : now,
        updatedAt: now,
      );

      await _outboxRepository.enqueueOperation(
        entityType: SyncEntityType.academicYear,
        entityId: academicYear.id,
        operation: isUpdate ? SyncMutationType.update : SyncMutationType.insert,
        payload: payload,
      );
    });
  }

  @override
  Future<AcademicYear?> findById(String id) async {
    final query = _db.select(_db.academicYearsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<AcademicYear?> findByYear(int year) async {
    final query = _db.select(_db.academicYearsTable)
      ..where((tbl) => tbl.year.equals(year));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<List<AcademicYear>> getAll() async {
    final rows = await (_db.select(
      _db.academicYearsTable,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.year)])).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.academicYearsTable,
      )..where((tbl) => tbl.id.equals(id))).go();

      await _outboxRepository.enqueueDelete(
        entityType: SyncEntityType.academicYear,
        entityId: id,
      );
    });
  }

  AcademicYear _toDomain(AcademicYearsTableData data) {
    return AcademicYear(
      id: data.id,
      year: data.year,
      title: data.title,
      startDate: data.startDate,
      endDate: data.endDate,
      totalMandatoryDays: data.totalMandatoryDays,
    );
  }
}
