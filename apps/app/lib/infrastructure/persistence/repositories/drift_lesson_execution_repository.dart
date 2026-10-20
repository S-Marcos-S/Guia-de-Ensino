import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/converters/calendar_date_converter.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/outbox/sync_payload_serializer.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de persistência de diário e registros de execução de aula via Drift/SQLite.
class DriftLessonExecutionRepository implements LessonExecutionRepository {
  DriftLessonExecutionRepository(
    this._db, [
    SyncOutboxRepository? outboxRepository,
  ]) : _outboxRepository = outboxRepository ?? SyncOutboxRepository(_db);

  final AppDatabase _db;
  final SyncOutboxRepository _outboxRepository;
  static const _dateConverter = CalendarDateConverter();

  @override
  Future<void> save(LessonExecutionRecord record) async {
    await _db.transaction(() async {
      // 1. Validação de consistência do vínculo: a aula planejada deve existir
      final plannedLesson =
          await (_db.select(_db.plannedLessonsTable)
                ..where((tbl) => tbl.id.equals(record.plannedLessonId)))
              .getSingleOrNull();

      if (plannedLesson == null) {
        throw LessonExecutionIntegrityException(
          'Aula planejada com ID "${record.plannedLessonId}" não foi encontrada no banco.',
        );
      }

      // 2. Validação de correspondência de contexto: disciplina e turma devem coincidir
      if (plannedLesson.classroomSubjectId != record.classroomSubjectId) {
        throw LessonExecutionIntegrityException(
          'Inconsistência de contexto: a disciplina da turma do registro (${record.classroomSubjectId}) '
          'não corresponde à disciplina da turma da aula planejada (${plannedLesson.classroomSubjectId}).',
        );
      }

      // 3. Validação dos conteúdos ministrados: devem existir e pertencer à mesma disciplina/turma
      if (record.actualContentIds.isNotEmpty) {
        final contents = await (_db.select(
          _db.courseContentsTable,
        )..where((tbl) => tbl.id.isIn(record.actualContentIds))).get();

        if (contents.length != record.actualContentIds.length) {
          throw const LessonExecutionIntegrityException(
            'Um ou mais conteúdos programáticos informados no registro de execução não foram encontrados.',
          );
        }

        for (final content in contents) {
          if (content.classroomSubjectId != record.classroomSubjectId) {
            throw LessonExecutionIntegrityException(
              'O conteúdo "${content.title}" (ID: ${content.id}) pertence a outra turma ou disciplina '
              'e não pode ser vinculado a esta execução.',
            );
          }
        }
      }

      final existingRecord = await findById(record.id);
      final isUpdate = existingRecord != null;
      final now = DateTime.now().toUtc();
      final effectiveUpdatedAt = isUpdate ? (record.updatedAt ?? now) : null;

      // 4. Gravação atômica do registro de execução
      await _db
          .into(_db.lessonExecutionRecordsTable)
          .insertOnConflictUpdate(
            LessonExecutionRecordsTableCompanion.insert(
              id: record.id,
              plannedLessonId: record.plannedLessonId,
              classroomSubjectId: record.classroomSubjectId,
              executionDate: record.executionDate,
              status: record.status.name,
              cancellationReason: Value(record.cancellationReason?.name),
              cancellationDetails: Value(record.cancellationDetails),
              pedagogicalNotes: Value(record.pedagogicalNotes),
              needsFollowUp: Value(record.needsFollowUp),
              followUpNotes: Value(record.followUpNotes),
              recordedAt: record.recordedAt,
              updatedAt: Value(effectiveUpdatedAt),
            ),
          );

      await _outboxRepository.enqueueOperation(
        entityType: SyncEntityType.lessonExecutionRecord,
        entityId: record.id,
        operation: isUpdate ? SyncMutationType.update : SyncMutationType.insert,
        payload: SyncPayloadSerializer.lessonExecutionRecord(
          record,
          updatedAt: effectiveUpdatedAt,
        ),
      );

      // 5. Consulta alocações anteriores de conteúdos ministrados
      final oldAllocRows = await (_db.select(
        _db.executionContentAllocationsTable,
      )..where((tbl) => tbl.recordId.equals(record.id))).get();
      final oldContentIds = oldAllocRows.map((r) => r.contentId).toSet();
      final newContentIds = record.actualContentIds.toSet();

      // Remove alocações descartadas e registra tombstones
      for (final oldAlloc in oldAllocRows) {
        if (!newContentIds.contains(oldAlloc.contentId)) {
          await (_db.delete(_db.executionContentAllocationsTable)..where(
                (tbl) =>
                    tbl.recordId.equals(record.id) &
                    tbl.contentId.equals(oldAlloc.contentId),
              ))
              .go();

          await _outboxRepository.enqueueDelete(
            entityType: SyncEntityType.executionContentAllocation,
            entityId: '${record.id}:${oldAlloc.contentId}',
          );
        }
      }

      // Atualiza ou insere as alocações vigentes
      for (var i = 0; i < record.actualContentIds.length; i++) {
        final contentId = record.actualContentIds[i];
        final orderIndex = i + 1;
        final existed = oldContentIds.contains(contentId);

        await _db
            .into(_db.executionContentAllocationsTable)
            .insert(
              ExecutionContentAllocationsTableCompanion.insert(
                recordId: record.id,
                contentId: contentId,
                orderIndex: Value(orderIndex),
              ),
              mode: InsertMode.insertOrReplace,
            );

        await _outboxRepository.enqueueOperation(
          entityType: SyncEntityType.executionContentAllocation,
          entityId: '${record.id}:$contentId',
          operation: existed
              ? SyncMutationType.update
              : SyncMutationType.insert,
          payload: SyncPayloadSerializer.executionContentAllocation(
            recordId: record.id,
            contentId: contentId,
            orderIndex: orderIndex,
          ),
        );
      }

      // 6. Sincronização do status da PlannedLesson para manter integridade com o modelo legado,
      // preservando estritamente a anotação original do planejamento (plannedLesson.notes).
      await (_db.update(
        _db.plannedLessonsTable,
      )..where((tbl) => tbl.id.equals(record.plannedLessonId))).write(
        PlannedLessonsTableCompanion(
          status: Value(record.status.name),
          notes: Value(plannedLesson.notes),
          updatedAt: Value(now),
        ),
      );

      final lessonStatus = LessonExecutionStatus.values.firstWhere(
        (s) => s.name == record.status.name,
        orElse: () => LessonExecutionStatus.planned,
      );

      final updatedPlannedLesson = PlannedLesson(
        id: plannedLesson.id,
        classroomSubjectId: plannedLesson.classroomSubjectId,
        date: plannedLesson.lessonDate,
        orderInDay: plannedLesson.orderInDay,
        status: lessonStatus,
        isLocked: plannedLesson.isLocked,
        notes: plannedLesson.notes,
      );

      await _outboxRepository.enqueueOperation(
        entityType: SyncEntityType.plannedLesson,
        entityId: plannedLesson.id,
        operation: SyncMutationType.update,
        payload: SyncPayloadSerializer.plannedLesson(
          updatedPlannedLesson,
          updatedAt: now,
        ),
      );
    });
  }

  @override
  Future<LessonExecutionRecord?> findById(String id) async {
    final query = _db.select(_db.lessonExecutionRecordsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final contentMap = await _loadActualContentIds([id]);
    return _toDomain(row, contentMap[id] ?? const []);
  }

  @override
  Future<LessonExecutionRecord?> findByPlannedLessonId(
    String plannedLessonId,
  ) async {
    final query = _db.select(_db.lessonExecutionRecordsTable)
      ..where((tbl) => tbl.plannedLessonId.equals(plannedLessonId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final contentMap = await _loadActualContentIds([row.id]);
    return _toDomain(row, contentMap[row.id] ?? const []);
  }

  @override
  Future<List<LessonExecutionRecord>> getByClassroomSubject(
    String classroomSubjectId,
  ) async {
    final rows =
        await (_db.select(_db.lessonExecutionRecordsTable)
              ..where(
                (tbl) => tbl.classroomSubjectId.equals(classroomSubjectId),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.executionDate)]))
            .get();

    final recordIds = rows.map((r) => r.id).toList();
    final contentMap = await _loadActualContentIds(recordIds);

    return rows.map((r) => _toDomain(r, contentMap[r.id] ?? const [])).toList();
  }

  @override
  Future<List<LessonExecutionRecord>> getByDateRange(
    String classroomSubjectId,
    DateTime start,
    DateTime end,
  ) async {
    final startStr = _dateConverter.toSql(start);
    final endStr = _dateConverter.toSql(end);

    final rows =
        await (_db.select(_db.lessonExecutionRecordsTable)
              ..where(
                (tbl) =>
                    tbl.classroomSubjectId.equals(classroomSubjectId) &
                    tbl.executionDate.isBiggerOrEqualValue(startStr) &
                    tbl.executionDate.isSmallerOrEqualValue(endStr),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.executionDate)]))
            .get();

    final recordIds = rows.map((r) => r.id).toList();
    final contentMap = await _loadActualContentIds(recordIds);

    return rows.map((r) => _toDomain(r, contentMap[r.id] ?? const [])).toList();
  }

  Future<Map<String, List<String>>> _loadActualContentIds(
    List<String> recordIds,
  ) async {
    if (recordIds.isEmpty) return const {};

    final rows =
        await (_db.select(_db.executionContentAllocationsTable)
              ..where((tbl) => tbl.recordId.isIn(recordIds))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderIndex)]))
            .get();

    final map = <String, List<String>>{};
    for (final r in rows) {
      map.putIfAbsent(r.recordId, () => []).add(r.contentId);
    }
    return map;
  }

  LessonExecutionRecord _toDomain(
    LessonExecutionRecordsTableData data,
    List<String> actualContentIds,
  ) {
    final status = LessonExecutionStatus.values.firstWhere(
      (s) => s.name == data.status,
      orElse: () => LessonExecutionStatus.completed,
    );

    LessonCancellationReason? cancellationReason;
    if (data.cancellationReason != null) {
      cancellationReason = LessonCancellationReason.values.firstWhere(
        (r) => r.name == data.cancellationReason,
        orElse: () => LessonCancellationReason.other,
      );
    }

    return LessonExecutionRecord(
      id: data.id,
      plannedLessonId: data.plannedLessonId,
      classroomSubjectId: data.classroomSubjectId,
      executionDate: data.executionDate,
      status: status,
      actualContentIds: actualContentIds,
      cancellationReason: cancellationReason,
      cancellationDetails: data.cancellationDetails,
      pedagogicalNotes: data.pedagogicalNotes,
      needsFollowUp: data.needsFollowUp,
      followUpNotes: data.followUpNotes,
      recordedAt: data.recordedAt.toUtc(),
      updatedAt: data.updatedAt?.toUtc(),
    );
  }
}
