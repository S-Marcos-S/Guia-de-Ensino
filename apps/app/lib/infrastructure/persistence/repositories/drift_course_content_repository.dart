import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de conteúdos programáticos no SQLite via Drift.
class DriftCourseContentRepository implements CourseContentRepository {
  DriftCourseContentRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(CourseContent content) async {
    await _db.transaction(() async {
      await _db
          .into(_db.courseContentsTable)
          .insertOnConflictUpdate(
            CourseContentsTableCompanion.insert(
              id: content.id,
              classroomSubjectId: content.classroomSubjectId,
              title: content.title,
              description: Value(content.description),
              thematicUnit: Value(content.thematicUnit),
              estimatedLessons: Value(content.estimatedLessons),
              orderIndex: content.orderIndex,
              curriculumCompetencyId: Value(content.curriculumCompetencyId),
              origin: content.origin.name,
              isMandatory: Value(content.isMandatory),
              createdAt: DateTime.now().toUtc(),
            ),
          );

      // Atualiza os pré-requisitos do conteúdo
      await (_db.delete(
        _db.contentPrerequisitesTable,
      )..where((tbl) => tbl.contentId.equals(content.id))).go();

      if (content.prerequisiteIds.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.contentPrerequisitesTable,
            content.prerequisiteIds.map(
              (preId) => ContentPrerequisitesTableCompanion.insert(
                contentId: content.id,
                prerequisiteContentId: preId,
              ),
            ),
          );
        });
      }
    });
  }

  @override
  Future<void> saveAll(List<CourseContent> contents) async {
    for (final content in contents) {
      await save(content);
    }
  }

  @override
  Future<CourseContent?> findById(String id) async {
    final query = _db.select(_db.courseContentsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final prereqIds = await getPrerequisiteIds(id);
    return _toDomain(row, prereqIds);
  }

  @override
  Future<List<CourseContent>> getByClassroomSubject(
    String classroomSubjectId,
  ) async {
    final rows =
        await (_db.select(_db.courseContentsTable)
              ..where(
                (tbl) => tbl.classroomSubjectId.equals(classroomSubjectId),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderIndex)]))
            .get();

    final result = <CourseContent>[];
    for (final row in rows) {
      final prereqIds = await getPrerequisiteIds(row.id);
      result.add(_toDomain(row, prereqIds));
    }
    return result;
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      // Exclui pré-requisitos onde o conteúdo é dependente ou pré-requisito
      await (_db.delete(_db.contentPrerequisitesTable)..where(
            (tbl) =>
                tbl.contentId.equals(id) | tbl.prerequisiteContentId.equals(id),
          ))
          .go();

      await (_db.delete(
        _db.courseContentsTable,
      )..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  @override
  Future<void> reorder(
    String classroomSubjectId,
    List<String> orderedContentIds,
  ) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedContentIds.length; i++) {
        final contentId = orderedContentIds[i];
        await (_db.update(_db.courseContentsTable)..where(
              (tbl) =>
                  tbl.id.equals(contentId) &
                  tbl.classroomSubjectId.equals(classroomSubjectId),
            ))
            .write(CourseContentsTableCompanion(orderIndex: Value(i)));
      }
    });
  }

  @override
  Future<List<String>> getPrerequisiteIds(String contentId) async {
    final rows = await (_db.select(
      _db.contentPrerequisitesTable,
    )..where((tbl) => tbl.contentId.equals(contentId))).get();
    return rows.map((r) => r.prerequisiteContentId).toList();
  }

  @override
  Future<void> setPrerequisites(
    String contentId,
    List<String> prerequisiteIds,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.contentPrerequisitesTable,
      )..where((tbl) => tbl.contentId.equals(contentId))).go();

      if (prerequisiteIds.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.contentPrerequisitesTable,
            prerequisiteIds.map(
              (preId) => ContentPrerequisitesTableCompanion.insert(
                contentId: contentId,
                prerequisiteContentId: preId,
              ),
            ),
          );
        });
      }
    });
  }

  CourseContent _toDomain(
    CourseContentsTableData data,
    List<String> prerequisiteIds,
  ) {
    return CourseContent(
      id: data.id,
      classroomSubjectId: data.classroomSubjectId,
      title: data.title,
      description: data.description,
      thematicUnit: data.thematicUnit,
      estimatedLessons: data.estimatedLessons,
      orderIndex: data.orderIndex,
      curriculumCompetencyId: data.curriculumCompetencyId,
      origin: ContentOrigin.values.byName(data.origin),
      isMandatory: data.isMandatory,
      prerequisiteIds: prerequisiteIds,
    );
  }
}
