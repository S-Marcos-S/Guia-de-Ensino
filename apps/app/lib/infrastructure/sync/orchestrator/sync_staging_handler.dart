import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/change_dto.dart';
import 'package:app/infrastructure/sync/models/snapshot_response_dto.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:drift/drift.dart';

/// Camada de ingestão remota direta no banco de dados SQLite via Drift.
///
/// Responsável por aplicar deltas de Pull e Snapshots atômicos diretamente
/// nas tabelas de dados sem invocar repositórios de domínio ou a Outbox,
/// eliminando integralmente a geração indevida de ecos na fila de sincronização.
class SyncStagingHandler {
  SyncStagingHandler(this._db);

  final AppDatabase _db;

  /// Aplica um único delta de alteração remota (`ChangeDto`) diretamente no Drift.
  Future<void> applyChange(ChangeDto change) async {
    final mutation = change.mutationType.toUpperCase();

    if (mutation == 'DELETE') {
      await _deleteEntity(change.entityType, change.entityId, change.payload);
      return;
    }

    if (mutation == 'INSERT' || mutation == 'UPDATE') {
      final payload = change.payload;
      if (payload == null || payload.isEmpty) {
        throw FormatException(
          'Payload não pode ser nulo ou vazio para mutações remotas do tipo $mutation '
          'na entidade "${change.entityType}:${change.entityId}".',
        );
      }
      await _upsertEntity(change.entityType, payload);
      return;
    }

    throw UnsupportedError(
      'Tipo de mutação não suportado pelo SyncStagingHandler: "$mutation".',
    );
  }

  /// Aplica um lote de deltas de alteração (`ChangeDto`) sob uma transação atômica.
  Future<void> applyChanges(List<ChangeDto> changes) async {
    if (changes.isEmpty) return;

    await _db.transaction(() async {
      for (final change in changes) {
        await applyChange(change);
      }
    });
  }

  /// Aplica um Snapshot atômico consistente de todas as 13 coleções pedagógicas.
  ///
  /// Executa estritamente sob transação atômica e segue a ordenação topológica
  /// de integridade referencial exigida pelas chaves estrangeiras com `PRAGMA foreign_keys = ON;`.
  Future<void> applySnapshot(SnapshotEntitiesDto entities) async {
    await _db.transaction(() async {
      // 1. academic_years (sem chaves estrangeiras)
      for (final item in entities.academicYears) {
        await _upsertAcademicYear(item);
      }

      // 2. subjects (sem chaves estrangeiras)
      for (final item in entities.subjects) {
        await _upsertSubject(item);
      }

      // 3. classrooms (depende de academic_years)
      for (final item in entities.classrooms) {
        await _upsertClassroom(item);
      }

      // 4. classroom_subjects (depende de classrooms e subjects)
      for (final item in entities.classroomSubjects) {
        await _upsertClassroomSubject(item);
      }

      // 5. school_calendar_events (depende de academic_years)
      for (final item in entities.schoolCalendarEvents) {
        await _upsertSchoolCalendarEvent(item);
      }

      // 6. schedule_slots (depende de classroom_subjects)
      for (final item in entities.scheduleSlots) {
        await _upsertScheduleSlot(item);
      }

      // 7. curriculum_competencies (sem chaves estrangeiras obrigatórias)
      for (final item in entities.curriculumCompetencies) {
        await _upsertCurriculumCompetency(item);
      }

      // 8. course_contents (depende de classroom_subjects e curriculum_competencies opcional)
      for (final item in entities.courseContents) {
        await _upsertCourseContent(item);
      }

      // 9. content_prerequisites (depende de course_contents para ambos os lados)
      for (final item in entities.contentPrerequisites) {
        await _upsertContentPrerequisite(item);
      }

      // 10. planned_lessons (depende de classroom_subjects)
      for (final item in entities.plannedLessons) {
        await _upsertPlannedLesson(item);
      }

      // 11. lesson_content_allocations (depende de planned_lessons e course_contents)
      for (final item in entities.lessonContentAllocations) {
        await _upsertLessonContentAllocation(item);
      }

      // 12. lesson_execution_records (depende de planned_lessons e classroom_subjects)
      for (final item in entities.lessonExecutionRecords) {
        await _upsertLessonExecutionRecord(item);
      }

      // 13. execution_content_allocations (depende de lesson_execution_records e course_contents)
      for (final item in entities.executionContentAllocations) {
        await _upsertExecutionContentAllocation(item);
      }
    });
  }

  // ===========================================================================
  // Roteamento de Upserts e Deleções
  // ===========================================================================

  Future<void> _upsertEntity(
    String entityType,
    Map<String, dynamic> payload,
  ) async {
    switch (entityType) {
      case SyncEntityType.academicYear:
        await _upsertAcademicYear(payload);
      case SyncEntityType.classroom:
        await _upsertClassroom(payload);
      case SyncEntityType.subject:
        await _upsertSubject(payload);
      case SyncEntityType.classroomSubject:
        await _upsertClassroomSubject(payload);
      case SyncEntityType.schoolCalendarEvent:
        await _upsertSchoolCalendarEvent(payload);
      case SyncEntityType.scheduleSlot:
        await _upsertScheduleSlot(payload);
      case SyncEntityType.curriculumCompetency:
        await _upsertCurriculumCompetency(payload);
      case SyncEntityType.courseContent:
        await _upsertCourseContent(payload);
      case SyncEntityType.contentPrerequisite:
        await _upsertContentPrerequisite(payload);
      case SyncEntityType.plannedLesson:
        await _upsertPlannedLesson(payload);
      case SyncEntityType.lessonContentAllocation:
        await _upsertLessonContentAllocation(payload);
      case SyncEntityType.lessonExecutionRecord:
        await _upsertLessonExecutionRecord(payload);
      case SyncEntityType.executionContentAllocation:
        await _upsertExecutionContentAllocation(payload);
      default:
        throw UnsupportedError(
          'Tipo de entidade desconhecido para ingestão remota: "$entityType".',
        );
    }
  }

  Future<void> _deleteEntity(
    String entityType,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    switch (entityType) {
      case SyncEntityType.academicYear:
        await (_db.delete(
          _db.academicYearsTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.classroom:
        await (_db.delete(
          _db.classroomsTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.subject:
        await (_db.delete(
          _db.subjectsTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.classroomSubject:
        await (_db.delete(
          _db.classroomSubjectsTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.schoolCalendarEvent:
        await (_db.delete(
          _db.schoolCalendarEventsTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.scheduleSlot:
        await (_db.delete(
          _db.scheduleSlotsTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.curriculumCompetency:
        await (_db.delete(
          _db.curriculumCompetenciesTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.courseContent:
        await (_db.delete(
          _db.courseContentsTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.contentPrerequisite:
        final parts = entityId.split(':');
        final contentId =
            payload?['content_id'] as String? ??
            (parts.isNotEmpty ? parts[0] : '');
        final prereqId =
            payload?['prerequisite_content_id'] as String? ??
            (parts.length > 1 ? parts[1] : '');
        await (_db.delete(_db.contentPrerequisitesTable)..where(
              (tbl) =>
                  tbl.contentId.equals(contentId) &
                  tbl.prerequisiteContentId.equals(prereqId),
            ))
            .go();

      case SyncEntityType.plannedLesson:
        // Regra Inviolável (GEMINI.md e Schema v5): Preservação de registros fáticos
        final execution =
            await (_db.select(_db.lessonExecutionRecordsTable)
                  ..where((tbl) => tbl.plannedLessonId.equals(entityId)))
                .getSingleOrNull();
        if (execution != null) {
          throw LessonExecutionProtectedException(
            'Tentativa de exclusão remota rejeitada: a aula planejada "$entityId" '
            'possui registro histórico de execução registrado no diário de classe.',
          );
        }
        await (_db.delete(
          _db.plannedLessonsTable,
        )..where((tbl) => tbl.id.equals(entityId))).go();

      case SyncEntityType.lessonContentAllocation:
        final parts = entityId.split(':');
        final lessonId =
            payload?['lesson_id'] as String? ??
            (parts.isNotEmpty ? parts[0] : '');
        final contentId =
            payload?['content_id'] as String? ??
            (parts.length > 1 ? parts[1] : '');
        await (_db.delete(_db.lessonContentAllocationsTable)..where(
              (tbl) =>
                  tbl.lessonId.equals(lessonId) &
                  tbl.contentId.equals(contentId),
            ))
            .go();

      case SyncEntityType.lessonExecutionRecord:
        // Regra Inviolável (GEMINI.md Seção 2 e 5): Registros históricos fáticos nunca são apagados
        throw const LessonExecutionProtectedException(
          'Violação de integridade fática: registros históricos de realização de aula não podem ser excluídos.',
        );

      case SyncEntityType.executionContentAllocation:
        final parts = entityId.split(':');
        final recordId =
            payload?['record_id'] as String? ??
            (parts.isNotEmpty ? parts[0] : '');
        final contentId =
            payload?['content_id'] as String? ??
            (parts.length > 1 ? parts[1] : '');
        await (_db.delete(_db.executionContentAllocationsTable)..where(
              (tbl) =>
                  tbl.recordId.equals(recordId) &
                  tbl.contentId.equals(contentId),
            ))
            .go();

      default:
        throw UnsupportedError(
          'Tipo de entidade desconhecido para exclusão remota: "$entityType".',
        );
    }
  }

  // ===========================================================================
  // Mapeamentos Específicos para Drift Companion (Upserts Diretos)
  // ===========================================================================

  Future<void> _upsertAcademicYear(Map<String, dynamic> p) async {
    final id = _requireId(p, 'academic_year');
    await _db
        .into(_db.academicYearsTable)
        .insertOnConflictUpdate(
          AcademicYearsTableCompanion(
            id: Value(id),
            year: Value(_parseInt(p['year'])),
            title: Value(p['title'] as String? ?? ''),
            startDate: Value(_parseCalendarDate(p['start_date'])),
            endDate: Value(_parseCalendarDate(p['end_date'])),
            totalMandatoryDays: Value(
              _parseInt(p['total_mandatory_days'], fallback: 200),
            ),
            createdAt: Value(_parseDateTime(p['created_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertClassroom(Map<String, dynamic> p) async {
    final id = _requireId(p, 'classroom');
    await _db
        .into(_db.classroomsTable)
        .insertOnConflictUpdate(
          ClassroomsTableCompanion(
            id: Value(id),
            academicYearId: Value(p['academic_year_id'] as String? ?? ''),
            name: Value(p['name'] as String? ?? ''),
            gradeLevel: Value(p['grade_level'] as String? ?? ''),
            shift: Value(p['shift'] as String? ?? 'morning'),
            createdAt: Value(_parseDateTime(p['created_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertSubject(Map<String, dynamic> p) async {
    final id = _requireId(p, 'subject');
    await _db
        .into(_db.subjectsTable)
        .insertOnConflictUpdate(
          SubjectsTableCompanion(
            id: Value(id),
            name: Value(p['name'] as String? ?? ''),
            colorHex: Value(p['color_hex'] as String? ?? '#000000'),
            createdAt: Value(_parseDateTime(p['created_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertClassroomSubject(Map<String, dynamic> p) async {
    final id = _requireId(p, 'classroom_subject');
    await _db
        .into(_db.classroomSubjectsTable)
        .insertOnConflictUpdate(
          ClassroomSubjectsTableCompanion(
            id: Value(id),
            classroomId: Value(p['classroom_id'] as String? ?? ''),
            subjectId: Value(p['subject_id'] as String? ?? ''),
            weeklyLessons: Value(_parseInt(p['weekly_lessons'], fallback: 1)),
            createdAt: Value(_parseDateTime(p['created_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertSchoolCalendarEvent(Map<String, dynamic> p) async {
    final id = _requireId(p, 'school_calendar_event');
    await _db
        .into(_db.schoolCalendarEventsTable)
        .insertOnConflictUpdate(
          SchoolCalendarEventsTableCompanion(
            id: Value(id),
            academicYearId: Value(p['academic_year_id'] as String? ?? ''),
            title: Value(p['title'] as String? ?? ''),
            startDate: Value(_parseCalendarDate(p['start_date'])),
            endDate: Value(_parseCalendarDate(p['end_date'])),
            type: Value(p['type'] as String? ?? 'holiday'),
            affectsClasses: Value(
              _parseBool(p['affects_classes'], fallback: true),
            ),
            createdAt: Value(_parseDateTime(p['created_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertScheduleSlot(Map<String, dynamic> p) async {
    final id = _requireId(p, 'schedule_slot');
    await _db
        .into(_db.scheduleSlotsTable)
        .insertOnConflictUpdate(
          ScheduleSlotsTableCompanion(
            id: Value(id),
            classroomSubjectId: Value(
              p['classroom_subject_id'] as String? ?? '',
            ),
            weekday: Value(_parseInt(p['weekday'], fallback: 1)),
            orderIndex: Value(_parseInt(p['order_index'], fallback: 1)),
            startTime: Value(p['start_time'] as String?),
            endTime: Value(p['end_time'] as String?),
            createdAt: Value(_parseDateTime(p['created_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertCurriculumCompetency(Map<String, dynamic> p) async {
    final id = _requireId(p, 'curriculum_competency');
    await _db
        .into(_db.curriculumCompetenciesTable)
        .insertOnConflictUpdate(
          CurriculumCompetenciesTableCompanion(
            id: Value(id),
            code: Value(p['code'] as String? ?? ''),
            description: Value(p['description'] as String? ?? ''),
            thematicUnit: Value(p['thematic_unit'] as String? ?? ''),
            knowledgeObject: Value(p['knowledge_object'] as String?),
            stage: Value(p['stage'] as String? ?? ''),
            gradeLevel: Value(p['grade_level'] as String? ?? ''),
            subjectName: Value(p['subject_name'] as String? ?? ''),
            sourceName: Value(p['source_name'] as String? ?? ''),
            sourceVersion: Value(p['source_version'] as String? ?? ''),
            createdAt: Value(_parseDateTime(p['created_at'])),
          ),
        );
  }

  Future<void> _upsertCourseContent(Map<String, dynamic> p) async {
    final id = _requireId(p, 'course_content');
    await _db
        .into(_db.courseContentsTable)
        .insertOnConflictUpdate(
          CourseContentsTableCompanion(
            id: Value(id),
            classroomSubjectId: Value(
              p['classroom_subject_id'] as String? ?? '',
            ),
            title: Value(p['title'] as String? ?? ''),
            description: Value(p['description'] as String?),
            thematicUnit: Value(p['thematic_unit'] as String?),
            estimatedLessons: Value(
              _parseInt(p['estimated_lessons'], fallback: 1),
            ),
            orderIndex: Value(_parseInt(p['order_index'], fallback: 0)),
            isMandatory: Value(_parseBool(p['is_mandatory'], fallback: true)),
            curriculumCompetencyId: Value(
              p['curriculum_competency_id'] as String?,
            ),
            origin: Value(p['origin'] as String? ?? 'manual'),
            createdAt: Value(_parseDateTime(p['created_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertContentPrerequisite(Map<String, dynamic> p) async {
    final contentId = p['content_id'] as String?;
    final prereqId = p['prerequisite_content_id'] as String?;

    if (contentId == null ||
        contentId.isEmpty ||
        prereqId == null ||
        prereqId.isEmpty) {
      throw const FormatException(
        'Payload inválido para content_prerequisite: "content_id" e '
        '"prerequisite_content_id" são obrigatórios.',
      );
    }

    await _db
        .into(_db.contentPrerequisitesTable)
        .insertOnConflictUpdate(
          ContentPrerequisitesTableCompanion(
            contentId: Value(contentId),
            prerequisiteContentId: Value(prereqId),
          ),
        );
  }

  Future<void> _upsertPlannedLesson(Map<String, dynamic> p) async {
    final id = _requireId(p, 'planned_lesson');
    await _db
        .into(_db.plannedLessonsTable)
        .insertOnConflictUpdate(
          PlannedLessonsTableCompanion(
            id: Value(id),
            classroomSubjectId: Value(
              p['classroom_subject_id'] as String? ?? '',
            ),
            lessonDate: Value(_parseCalendarDate(p['lesson_date'])),
            orderInDay: Value(_parseInt(p['order_in_day'], fallback: 1)),
            status: Value(p['status'] as String? ?? 'planned'),
            isLocked: Value(_parseBool(p['is_locked'], fallback: false)),
            notes: Value(p['notes'] as String?),
            createdAt: Value(_parseDateTime(p['created_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertLessonContentAllocation(Map<String, dynamic> p) async {
    final lessonId = p['lesson_id'] as String?;
    final contentId = p['content_id'] as String?;

    if (lessonId == null ||
        lessonId.isEmpty ||
        contentId == null ||
        contentId.isEmpty) {
      throw const FormatException(
        'Payload inválido para lesson_content_allocation: "lesson_id" e '
        '"content_id" são obrigatórios.',
      );
    }

    await _db
        .into(_db.lessonContentAllocationsTable)
        .insertOnConflictUpdate(
          LessonContentAllocationsTableCompanion(
            lessonId: Value(lessonId),
            contentId: Value(contentId),
            orderIndex: Value(_parseInt(p['order_index'], fallback: 1)),
          ),
        );
  }

  Future<void> _upsertLessonExecutionRecord(Map<String, dynamic> p) async {
    final id = _requireId(p, 'lesson_execution_record');
    final plannedLessonId = p['planned_lesson_id'] as String? ?? '';
    final classroomSubjectId = p['classroom_subject_id'] as String? ?? '';

    await _db
        .into(_db.lessonExecutionRecordsTable)
        .insertOnConflictUpdate(
          LessonExecutionRecordsTableCompanion(
            id: Value(id),
            plannedLessonId: Value(plannedLessonId),
            classroomSubjectId: Value(classroomSubjectId),
            executionDate: Value(_parseCalendarDate(p['execution_date'])),
            status: Value(p['status'] as String? ?? 'completed'),
            cancellationReason: Value(p['cancellation_reason'] as String?),
            cancellationDetails: Value(p['cancellation_details'] as String?),
            pedagogicalNotes: Value(p['pedagogical_notes'] as String?),
            needsFollowUp: Value(
              _parseBool(p['needs_follow_up'], fallback: false),
            ),
            followUpNotes: Value(p['follow_up_notes'] as String?),
            recordedAt: Value(_parseDateTime(p['recorded_at'])),
            updatedAt: Value(_parseNullableDateTime(p['updated_at'])),
          ),
        );
  }

  Future<void> _upsertExecutionContentAllocation(Map<String, dynamic> p) async {
    final recordId = p['record_id'] as String?;
    final contentId = p['content_id'] as String?;

    if (recordId == null ||
        recordId.isEmpty ||
        contentId == null ||
        contentId.isEmpty) {
      throw const FormatException(
        'Payload inválido para execution_content_allocation: "record_id" e '
        '"content_id" são obrigatórios.',
      );
    }

    await _db
        .into(_db.executionContentAllocationsTable)
        .insertOnConflictUpdate(
          ExecutionContentAllocationsTableCompanion(
            recordId: Value(recordId),
            contentId: Value(contentId),
            orderIndex: Value(_parseInt(p['order_index'], fallback: 1)),
          ),
        );
  }

  // ===========================================================================
  // Utilitários de Parsing Defensivo e Validação
  // ===========================================================================

  static String _requireId(Map<String, dynamic> p, String entityType) {
    final id = p['id'];
    if (id is! String || id.trim().isEmpty) {
      throw FormatException(
        'Payload inválido para entidade $entityType: campo "id" obrigatório ausente ou vazio.',
      );
    }
    return id.trim();
  }

  static DateTime _parseCalendarDate(dynamic val) {
    if (val == null) {
      throw const FormatException('Data obrigatória não informada no payload.');
    }
    if (val is DateTime) return val.toUtc();
    if (val is String) {
      final parsed = DateTime.tryParse(val.trim());
      if (parsed != null) return parsed.toUtc();
    }
    throw FormatException('Formato de data inválido no payload: "$val".');
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now().toUtc();
    if (val is DateTime) return val.toUtc();
    if (val is num) {
      return val > 10000000000
          ? DateTime.fromMillisecondsSinceEpoch(val.toInt(), isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(
              val.toInt() * 1000,
              isUtc: true,
            );
    }
    if (val is String) {
      final parsed = DateTime.tryParse(val.trim());
      if (parsed != null) return parsed.toUtc();
    }
    throw FormatException(
      'Formato de data/hora ISO inválido no payload: "$val".',
    );
  }

  static DateTime? _parseNullableDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val.toUtc();
    if (val is num) {
      return val > 10000000000
          ? DateTime.fromMillisecondsSinceEpoch(val.toInt(), isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(
              val.toInt() * 1000,
              isUtc: true,
            );
    }
    if (val is String) {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return null;
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) return parsed.toUtc();
    }
    return null;
  }

  static int _parseInt(dynamic val, {int fallback = 0}) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val.trim()) ?? fallback;
    return fallback;
  }

  static bool _parseBool(dynamic val, {bool fallback = false}) {
    if (val == null) return fallback;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final lower = val.toLowerCase().trim();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }
}
