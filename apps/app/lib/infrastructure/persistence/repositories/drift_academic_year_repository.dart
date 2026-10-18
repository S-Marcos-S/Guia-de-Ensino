import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/repositories/academic_year_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de Anos Letivos utilizando Drift e SQLite.
class DriftAcademicYearRepository implements AcademicYearRepository {
  DriftAcademicYearRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(AcademicYear academicYear) async {
    await _db
        .into(_db.academicYearsTable)
        .insertOnConflictUpdate(
          AcademicYearsTableCompanion.insert(
            id: academicYear.id,
            year: academicYear.year,
            title: academicYear.title,
            startDate: academicYear.startDate,
            endDate: academicYear.endDate,
            totalMandatoryDays: Value(academicYear.totalMandatoryDays),
            createdAt: DateTime.now().toUtc(),
          ),
        );
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
    await (_db.delete(
      _db.academicYearsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
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
