import 'package:app/domain/models/subject.dart';
import 'package:app/domain/repositories/subject_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de Disciplinas utilizando Drift e SQLite.
class DriftSubjectRepository implements SubjectRepository {
  DriftSubjectRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Subject subject) async {
    await _db
        .into(_db.subjectsTable)
        .insertOnConflictUpdate(
          SubjectsTableCompanion.insert(
            id: subject.id,
            name: subject.name,
            colorHex: subject.colorHex,
            createdAt: DateTime.now().toUtc(),
          ),
        );
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
    await (_db.delete(
      _db.subjectsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  Subject _toDomain(SubjectsTableData data) {
    return Subject(id: data.id, name: data.name, colorHex: data.colorHex);
  }
}
