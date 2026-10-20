import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/converters/calendar_date_converter.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/outbox/sync_payload_serializer.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de Aulas e Registros Históricos utilizando Drift.
class DriftPlannedLessonRepository implements PlannedLessonRepository {
  DriftPlannedLessonRepository(
    this._db, [
    SyncOutboxRepository? outboxRepository,
  ]) : _outboxRepository = outboxRepository ?? SyncOutboxRepository(_db);

  final AppDatabase _db;
  final SyncOutboxRepository _outboxRepository;
  static const _dateConverter = CalendarDateConverter();

  @override
  Future<void> save(PlannedLesson lesson) async {
    await _db.transaction(() async {
      await _saveSingleLessonInternal(lesson);
    });
  }

  @override
  Future<void> saveAll(List<PlannedLesson> lessons) async {
    await _db.transaction(() async {
      for (final lesson in lessons) {
        await _saveSingleLessonInternal(lesson);
      }
    });
  }

  Future<void> _saveSingleLessonInternal(PlannedLesson lesson) async {
    final existing = await findById(lesson.id);
    final isUpdate = existing != null;
    final now = DateTime.now().toUtc();

    await _db
        .into(_db.plannedLessonsTable)
        .insertOnConflictUpdate(
          PlannedLessonsTableCompanion.insert(
            id: lesson.id,
            classroomSubjectId: lesson.classroomSubjectId,
            lessonDate: lesson.date,
            orderInDay: lesson.orderInDay,
            status: lesson.status.name,
            isLocked: Value(lesson.isLocked),
            notes: Value(lesson.notes),
            createdAt: isUpdate ? Value.absent() : Value(now),
            updatedAt: Value(now),
          ),
        );

    await _outboxRepository.enqueueOperation(
      entityType: SyncEntityType.plannedLesson,
      entityId: lesson.id,
      operation: isUpdate ? SyncMutationType.update : SyncMutationType.insert,
      payload: SyncPayloadSerializer.plannedLesson(
        lesson,
        createdAt: isUpdate ? null : now,
        updatedAt: now,
      ),
    );

    // Consulta alocações anteriores de conteúdos
    final oldAllocRows = await (_db.select(
      _db.lessonContentAllocationsTable,
    )..where((tbl) => tbl.lessonId.equals(lesson.id))).get();
    final oldContentIds = oldAllocRows.map((r) => r.contentId).toSet();
    final newContentIds = lesson.contentIds.toSet();

    // Remove alocações descartadas e registra tombstones
    for (final oldAlloc in oldAllocRows) {
      if (!newContentIds.contains(oldAlloc.contentId)) {
        await (_db.delete(_db.lessonContentAllocationsTable)..where(
              (tbl) =>
                  tbl.lessonId.equals(lesson.id) &
                  tbl.contentId.equals(oldAlloc.contentId),
            ))
            .go();

        await _outboxRepository.enqueueDelete(
          entityType: SyncEntityType.lessonContentAllocation,
          entityId: '${lesson.id}:${oldAlloc.contentId}',
        );
      }
    }

    // Insere ou atualiza novas alocações
    for (var i = 0; i < lesson.contentIds.length; i++) {
      final contentId = lesson.contentIds[i];
      final orderIndex = i + 1;
      final existed = oldContentIds.contains(contentId);

      await _db
          .into(_db.lessonContentAllocationsTable)
          .insert(
            LessonContentAllocationsTableCompanion.insert(
              lessonId: lesson.id,
              contentId: contentId,
              orderIndex: Value(orderIndex),
            ),
            mode: InsertMode.insertOrReplace,
          );

      await _outboxRepository.enqueueOperation(
        entityType: SyncEntityType.lessonContentAllocation,
        entityId: '${lesson.id}:$contentId',
        operation: existed ? SyncMutationType.update : SyncMutationType.insert,
        payload: SyncPayloadSerializer.lessonContentAllocation(
          lessonId: lesson.id,
          contentId: contentId,
          orderIndex: orderIndex,
        ),
      );
    }
  }

  @override
  Future<PlannedLesson?> findById(String id) async {
    final query = _db.select(_db.plannedLessonsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final contentMap = await _loadContentIdsForLessons([id]);
    return _toDomain(row, contentMap[id] ?? const []);
  }

  @override
  Future<List<PlannedLesson>> getByClassroomSubject(
    String classroomSubjectId,
  ) async {
    final rows =
        await (_db.select(_db.plannedLessonsTable)
              ..where(
                (tbl) => tbl.classroomSubjectId.equals(classroomSubjectId),
              )
              ..orderBy([
                (tbl) => OrderingTerm.asc(tbl.lessonDate),
                (tbl) => OrderingTerm.asc(tbl.orderInDay),
              ]))
            .get();

    final lessonIds = rows.map((r) => r.id).toList();
    final contentMap = await _loadContentIdsForLessons(lessonIds);

    return rows.map((r) => _toDomain(r, contentMap[r.id] ?? const [])).toList();
  }

  @override
  Future<List<PlannedLesson>> getByDate(DateTime date) async {
    final dateStr = _dateConverter.toSql(date);
    final rows =
        await (_db.select(_db.plannedLessonsTable)
              ..where((tbl) => tbl.lessonDate.equals(dateStr))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderInDay)]))
            .get();

    final lessonIds = rows.map((r) => r.id).toList();
    final contentMap = await _loadContentIdsForLessons(lessonIds);

    return rows.map((r) => _toDomain(r, contentMap[r.id] ?? const [])).toList();
  }

  @override
  Future<List<PlannedLesson>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final startStr = _dateConverter.toSql(start);
    final endStr = _dateConverter.toSql(end);

    final rows =
        await (_db.select(_db.plannedLessonsTable)
              ..where(
                (tbl) =>
                    tbl.lessonDate.isBiggerOrEqualValue(startStr) &
                    tbl.lessonDate.isSmallerOrEqualValue(endStr),
              )
              ..orderBy([
                (tbl) => OrderingTerm.asc(tbl.lessonDate),
                (tbl) => OrderingTerm.asc(tbl.orderInDay),
              ]))
            .get();

    final lessonIds = rows.map((r) => r.id).toList();
    final contentMap = await _loadContentIdsForLessons(lessonIds);

    return rows.map((r) => _toDomain(r, contentMap[r.id] ?? const [])).toList();
  }

  @override
  Future<void> delete(String id) async {
    final existing = await findById(id);
    if (existing == null) return;

    // Regra Inviolável (GEMINI.md e Condição 5):
    // Preservação do histórico docente. Não apague registros de aulas realizadas ou parciais.
    if (existing.hasExecutionRecord) {
      throw const LessonExecutionProtectedException(
        'Aulas com registros históricos de realização não podem ser excluídas.',
      );
    }

    await _db.transaction(() async {
      final allocations = await (_db.select(
        _db.lessonContentAllocationsTable,
      )..where((tbl) => tbl.lessonId.equals(id))).get();

      for (final alloc in allocations) {
        await (_db.delete(_db.lessonContentAllocationsTable)..where(
              (tbl) =>
                  tbl.lessonId.equals(id) &
                  tbl.contentId.equals(alloc.contentId),
            ))
            .go();

        await _outboxRepository.enqueueDelete(
          entityType: SyncEntityType.lessonContentAllocation,
          entityId: '$id:${alloc.contentId}',
        );
      }

      await (_db.delete(
        _db.plannedLessonsTable,
      )..where((tbl) => tbl.id.equals(id))).go();

      await _outboxRepository.enqueueDelete(
        entityType: SyncEntityType.plannedLesson,
        entityId: id,
      );
    });
  }

  Future<Map<String, List<String>>> _loadContentIdsForLessons(
    List<String> lessonIds,
  ) async {
    if (lessonIds.isEmpty) return const {};

    final rows =
        await (_db.select(_db.lessonContentAllocationsTable)
              ..where((tbl) => tbl.lessonId.isIn(lessonIds))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderIndex)]))
            .get();

    final map = <String, List<String>>{};
    for (final r in rows) {
      map.putIfAbsent(r.lessonId, () => []).add(r.contentId);
    }
    return map;
  }

  PlannedLesson _toDomain(
    PlannedLessonsTableData data, [
    List<String> contentIds = const [],
  ]) {
    final status = LessonExecutionStatus.values.firstWhere(
      (s) => s.name == data.status,
      orElse: () => LessonExecutionStatus.planned,
    );

    return PlannedLesson(
      id: data.id,
      classroomSubjectId: data.classroomSubjectId,
      date: data.lessonDate,
      orderInDay: data.orderInDay,
      contentIds: contentIds,
      status: status,
      isLocked: data.isLocked,
      notes: data.notes,
    );
  }
}
