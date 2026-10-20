import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/outbox/sync_payload_serializer.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de conteúdos programáticos no SQLite via Drift.
class DriftCourseContentRepository implements CourseContentRepository {
  DriftCourseContentRepository(
    this._db, [
    SyncOutboxRepository? outboxRepository,
  ]) : _outboxRepository = outboxRepository ?? SyncOutboxRepository(_db);

  final AppDatabase _db;
  final SyncOutboxRepository _outboxRepository;

  @override
  Future<void> save(CourseContent content) async {
    await _db.transaction(() async {
      final existing = await findById(content.id);
      final isUpdate = existing != null;
      final now = DateTime.now().toUtc();

      await _db
          .into(_db.courseContentsTable)
          .insertOnConflictUpdate(
            CourseContentsTableCompanion(
              id: Value(content.id),
              classroomSubjectId: Value(content.classroomSubjectId),
              title: Value(content.title),
              description: Value(content.description),
              thematicUnit: Value(content.thematicUnit),
              estimatedLessons: Value(content.estimatedLessons),
              orderIndex: Value(content.orderIndex),
              curriculumCompetencyId: Value(content.curriculumCompetencyId),
              origin: Value(content.origin.name),
              isMandatory: Value(content.isMandatory),
              createdAt: isUpdate ? const Value<DateTime>.absent() : Value(now),
              updatedAt: Value(now),
            ),
          );

      await _outboxRepository.enqueueOperation(
        entityType: SyncEntityType.courseContent,
        entityId: content.id,
        operation: isUpdate ? SyncMutationType.update : SyncMutationType.insert,
        payload: SyncPayloadSerializer.courseContent(
          content,
          createdAt: isUpdate ? null : now,
          updatedAt: now,
        ),
      );

      // Consulta pré-requisitos vigentes no banco para rastrear adições e exclusões
      final oldPrereqRows = await (_db.select(
        _db.contentPrerequisitesTable,
      )..where((tbl) => tbl.contentId.equals(content.id))).get();
      final oldPrereqIds = oldPrereqRows
          .map((r) => r.prerequisiteContentId)
          .toSet();
      final newPrereqIds = content.prerequisiteIds.toSet();

      // Remove pré-requisitos descartados e enfileira tombstones
      for (final oldPreId in oldPrereqIds) {
        if (!newPrereqIds.contains(oldPreId)) {
          await (_db.delete(_db.contentPrerequisitesTable)..where(
                (tbl) =>
                    tbl.contentId.equals(content.id) &
                    tbl.prerequisiteContentId.equals(oldPreId),
              ))
              .go();

          await _outboxRepository.enqueueDelete(
            entityType: SyncEntityType.contentPrerequisite,
            entityId: '${content.id}:$oldPreId',
          );
        }
      }

      // Insere novos pré-requisitos e enfileira na Outbox
      for (final newPreId in newPrereqIds) {
        if (!oldPrereqIds.contains(newPreId)) {
          await _db
              .into(_db.contentPrerequisitesTable)
              .insert(
                ContentPrerequisitesTableCompanion.insert(
                  contentId: content.id,
                  prerequisiteContentId: newPreId,
                ),
                mode: InsertMode.insertOrReplace,
              );

          await _outboxRepository.enqueueOperation(
            entityType: SyncEntityType.contentPrerequisite,
            entityId: '${content.id}:$newPreId',
            operation: SyncMutationType.insert,
            payload: SyncPayloadSerializer.contentPrerequisite(
              contentId: content.id,
              prerequisiteContentId: newPreId,
            ),
          );
        }
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
      // Consulta pré-requisitos vinculados para remoção e registro de tombstones
      final relatedPrereqs =
          await (_db.select(_db.contentPrerequisitesTable)..where(
                (tbl) =>
                    tbl.contentId.equals(id) |
                    tbl.prerequisiteContentId.equals(id),
              ))
              .get();

      for (final prereq in relatedPrereqs) {
        await (_db.delete(_db.contentPrerequisitesTable)..where(
              (tbl) =>
                  tbl.contentId.equals(prereq.contentId) &
                  tbl.prerequisiteContentId.equals(
                    prereq.prerequisiteContentId,
                  ),
            ))
            .go();

        await _outboxRepository.enqueueDelete(
          entityType: SyncEntityType.contentPrerequisite,
          entityId: '${prereq.contentId}:${prereq.prerequisiteContentId}',
        );
      }

      await (_db.delete(
        _db.courseContentsTable,
      )..where((tbl) => tbl.id.equals(id))).go();

      await _outboxRepository.enqueueDelete(
        entityType: SyncEntityType.courseContent,
        entityId: id,
      );
    });
  }

  @override
  Future<void> reorder(
    String classroomSubjectId,
    List<String> orderedContentIds,
  ) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();

      for (int i = 0; i < orderedContentIds.length; i++) {
        final contentId = orderedContentIds[i];
        final existing = await findById(contentId);
        if (existing == null) continue;

        await (_db.update(_db.courseContentsTable)..where(
              (tbl) =>
                  tbl.id.equals(contentId) &
                  tbl.classroomSubjectId.equals(classroomSubjectId),
            ))
            .write(
              CourseContentsTableCompanion(
                orderIndex: Value(i),
                updatedAt: Value(now),
              ),
            );

        final updatedContent = existing.copyWith(orderIndex: i);
        await _outboxRepository.enqueueOperation(
          entityType: SyncEntityType.courseContent,
          entityId: contentId,
          operation: SyncMutationType.update,
          payload: SyncPayloadSerializer.courseContent(
            updatedContent,
            updatedAt: now,
          ),
        );
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
      final oldPrereqRows = await (_db.select(
        _db.contentPrerequisitesTable,
      )..where((tbl) => tbl.contentId.equals(contentId))).get();
      final oldPrereqIds = oldPrereqRows
          .map((r) => r.prerequisiteContentId)
          .toSet();
      final newPrereqIds = prerequisiteIds.toSet();

      for (final oldPreId in oldPrereqIds) {
        if (!newPrereqIds.contains(oldPreId)) {
          await (_db.delete(_db.contentPrerequisitesTable)..where(
                (tbl) =>
                    tbl.contentId.equals(contentId) &
                    tbl.prerequisiteContentId.equals(oldPreId),
              ))
              .go();

          await _outboxRepository.enqueueDelete(
            entityType: SyncEntityType.contentPrerequisite,
            entityId: '$contentId:$oldPreId',
          );
        }
      }

      for (final newPreId in newPrereqIds) {
        if (!oldPrereqIds.contains(newPreId)) {
          await _db
              .into(_db.contentPrerequisitesTable)
              .insert(
                ContentPrerequisitesTableCompanion.insert(
                  contentId: contentId,
                  prerequisiteContentId: newPreId,
                ),
                mode: InsertMode.insertOrReplace,
              );

          await _outboxRepository.enqueueOperation(
            entityType: SyncEntityType.contentPrerequisite,
            entityId: '$contentId:$newPreId',
            operation: SyncMutationType.insert,
            payload: SyncPayloadSerializer.contentPrerequisite(
              contentId: contentId,
              prerequisiteContentId: newPreId,
            ),
          );
        }
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
