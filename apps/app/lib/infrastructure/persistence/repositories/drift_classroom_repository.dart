import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/repositories/classroom_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de Turmas e vínculos de disciplinas utilizando Drift.
class DriftClassroomRepository implements ClassroomRepository {
  DriftClassroomRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Classroom classroom) async {
    await _db.transaction(() async {
      await _db
          .into(_db.classroomsTable)
          .insertOnConflictUpdate(
            ClassroomsTableCompanion.insert(
              id: classroom.id,
              academicYearId: classroom.academicYearId,
              name: classroom.name,
              gradeLevel: classroom.gradeLevel,
              shift: classroom.shift.name,
              createdAt: DateTime.now().toUtc(),
            ),
          );

      // Sincroniza vínculos: remove configurações que foram desassociadas da turma
      final currentConfigIds = classroom.subjectConfigs
          .map((c) => c.id)
          .toList();
      if (currentConfigIds.isEmpty) {
        await (_db.delete(
          _db.classroomSubjectsTable,
        )..where((tbl) => tbl.classroomId.equals(classroom.id))).go();
      } else {
        await (_db.delete(_db.classroomSubjectsTable)..where(
              (tbl) =>
                  tbl.classroomId.equals(classroom.id) &
                  tbl.id.isNotIn(currentConfigIds),
            ))
            .go();
      }

      // Atualiza ou insere os vínculos vigentes das disciplinas da turma
      for (final config in classroom.subjectConfigs) {
        await _db
            .into(_db.classroomSubjectsTable)
            .insertOnConflictUpdate(
              ClassroomSubjectsTableCompanion.insert(
                id: config.id,
                classroomId: classroom.id,
                subjectId: config.subjectId,
                weeklyLessons: config.weeklyLessons,
                createdAt: DateTime.now().toUtc(),
              ),
            );
      }
    });
  }

  @override
  Future<Classroom?> findById(String id) async {
    final query = _db.select(_db.classroomsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final configs = await _getConfigsForClassroom(id);
    return _toDomain(row, configs);
  }

  @override
  Future<List<Classroom>> getByAcademicYear(String academicYearId) async {
    final rows =
        await (_db.select(_db.classroomsTable)
              ..where((tbl) => tbl.academicYearId.equals(academicYearId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();

    final result = <Classroom>[];
    for (final row in rows) {
      final configs = await _getConfigsForClassroom(row.id);
      result.add(_toDomain(row, configs));
    }
    return result;
  }

  @override
  Future<List<Classroom>> getAll() async {
    final rows = await (_db.select(
      _db.classroomsTable,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.name)])).get();

    final result = <Classroom>[];
    for (final row in rows) {
      final configs = await _getConfigsForClassroom(row.id);
      result.add(_toDomain(row, configs));
    }
    return result;
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.classroomsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<ClassroomSubjectConfig>> _getConfigsForClassroom(
    String classroomId,
  ) async {
    final rows = await (_db.select(
      _db.classroomSubjectsTable,
    )..where((tbl) => tbl.classroomId.equals(classroomId))).get();

    return rows
        .map(
          (r) => ClassroomSubjectConfig(
            id: r.id,
            classroomId: r.classroomId,
            subjectId: r.subjectId,
            weeklyLessons: r.weeklyLessons,
          ),
        )
        .toList();
  }

  Classroom _toDomain(
    ClassroomsTableData data,
    List<ClassroomSubjectConfig> configs,
  ) {
    final shift = ClassroomShift.values.firstWhere(
      (s) => s.name == data.shift,
      orElse: () => ClassroomShift.morning,
    );

    return Classroom(
      id: data.id,
      academicYearId: data.academicYearId,
      name: data.name,
      gradeLevel: data.gradeLevel,
      shift: shift,
      subjectConfigs: configs,
    );
  }
}
