import 'package:app/domain/models/school_calendar_event.dart';
import 'package:app/domain/repositories/calendar_event_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Implementação Drift/SQLite para persistência de eventos escolares e feriados.
class DriftCalendarEventRepository implements CalendarEventRepository {
  DriftCalendarEventRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(SchoolCalendarEvent event) async {
    final companion = SchoolCalendarEventsTableCompanion(
      id: Value(event.id),
      academicYearId: Value(event.academicYearId),
      title: Value(event.title),
      startDate: Value(event.startDate),
      endDate: Value(event.endDate),
      type: Value(event.type.name),
      affectsClasses: Value(event.affectsClasses),
      createdAt: Value(DateTime.now()),
    );

    await _db
        .into(_db.schoolCalendarEventsTable)
        .insertOnConflictUpdate(companion);
  }

  @override
  Future<SchoolCalendarEvent?> findById(String id) async {
    final query = _db.select(_db.schoolCalendarEventsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  @override
  Future<List<SchoolCalendarEvent>> getByAcademicYear(
    String academicYearId,
  ) async {
    final query = _db.select(_db.schoolCalendarEventsTable)
      ..where((tbl) => tbl.academicYearId.equals(academicYearId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startDate)]);

    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.schoolCalendarEventsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  SchoolCalendarEvent _toDomain(SchoolCalendarEventsTableData row) {
    final type = SchoolEventType.values.firstWhere(
      (e) => e.name == row.type,
      orElse: () => SchoolEventType.holiday,
    );

    return SchoolCalendarEvent(
      id: row.id,
      academicYearId: row.academicYearId,
      title: row.title,
      startDate: row.startDate,
      endDate: row.endDate,
      type: type,
      affectsClasses: row.affectsClasses,
    );
  }
}
