import 'package:app/domain/models/curriculum_competency.dart';
import 'package:app/domain/repositories/curriculum_competency_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de competências/habilidades da base curricular no SQLite via Drift.
class DriftCurriculumCompetencyRepository
    implements CurriculumCompetencyRepository {
  DriftCurriculumCompetencyRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(CurriculumCompetency competency) async {
    await _db
        .into(_db.curriculumCompetenciesTable)
        .insertOnConflictUpdate(
          CurriculumCompetenciesTableCompanion.insert(
            id: competency.id,
            code: competency.code,
            description: competency.description,
            thematicUnit: competency.thematicUnit,
            knowledgeObject: Value(competency.knowledgeObject),
            stage: competency.stage,
            gradeLevel: competency.gradeLevel,
            subjectName: competency.subjectName,
            sourceName: competency.sourceName,
            sourceVersion: competency.sourceVersion,
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  @override
  Future<void> saveAll(List<CurriculumCompetency> competencies) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.curriculumCompetenciesTable,
        competencies.map(
          (c) => CurriculumCompetenciesTableCompanion.insert(
            id: c.id,
            code: c.code,
            description: c.description,
            thematicUnit: c.thematicUnit,
            knowledgeObject: Value(c.knowledgeObject),
            stage: c.stage,
            gradeLevel: c.gradeLevel,
            subjectName: c.subjectName,
            sourceName: c.sourceName,
            sourceVersion: c.sourceVersion,
            createdAt: DateTime.now().toUtc(),
          ),
        ),
      );
    });
  }

  @override
  Future<CurriculumCompetency?> findById(String id) async {
    final query = _db.select(_db.curriculumCompetenciesTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<CurriculumCompetency?> findByCode(String code) async {
    final query = _db.select(_db.curriculumCompetenciesTable)
      ..where((tbl) => tbl.code.equals(code.trim().toUpperCase()));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<List<CurriculumCompetency>> getAll() async {
    final rows = await (_db.select(
      _db.curriculumCompetenciesTable,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.code)])).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<CurriculumCompetency>> search({
    String? query,
    String? stage,
    String? subjectName,
  }) async {
    final selectQuery = _db.select(_db.curriculumCompetenciesTable);

    selectQuery.where((tbl) {
      final List<Expression<bool>> predicates = [];

      if (query != null && query.trim().isNotEmpty) {
        final term = '%${query.trim().toLowerCase()}%';
        predicates.add(
          tbl.code.lower().like(term) |
              tbl.description.lower().like(term) |
              tbl.thematicUnit.lower().like(term),
        );
      }

      if (stage != null && stage.trim().isNotEmpty) {
        predicates.add(tbl.stage.equals(stage.trim()));
      }

      if (subjectName != null && subjectName.trim().isNotEmpty) {
        predicates.add(tbl.subjectName.equals(subjectName.trim()));
      }

      return predicates.isEmpty
          ? const Constant(true)
          : Expression.and(predicates);
    });

    selectQuery.orderBy([(tbl) => OrderingTerm.asc(tbl.code)]);

    final rows = await selectQuery.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<int> count() async {
    final countExp = _db.curriculumCompetenciesTable.id.count();
    final query = _db.selectOnly(_db.curriculumCompetenciesTable)
      ..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  CurriculumCompetency _toDomain(CurriculumCompetenciesTableData data) {
    return CurriculumCompetency(
      id: data.id,
      code: data.code,
      description: data.description,
      thematicUnit: data.thematicUnit,
      knowledgeObject: data.knowledgeObject,
      stage: data.stage,
      gradeLevel: data.gradeLevel,
      subjectName: data.subjectName,
      sourceName: data.sourceName,
      sourceVersion: data.sourceVersion,
    );
  }
}
