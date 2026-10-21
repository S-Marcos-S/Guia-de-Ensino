import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/repositories/classroom_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/outbox/sync_payload_serializer.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de Turmas e vínculos de disciplinas utilizando Drift.
class DriftClassroomRepository implements ClassroomRepository {
  DriftClassroomRepository(this._db, [SyncOutboxRepository? outboxRepository])
    : _outboxRepository = outboxRepository ?? SyncOutboxRepository(_db);

  final AppDatabase _db;
  final SyncOutboxRepository _outboxRepository;

  @override
  Future<void> save(Classroom classroom) async {
    await _db.transaction(() async {
      final existing = await findById(classroom.id);
      final isUpdate = existing != null;
      final now = DateTime.now().toUtc();

      if (isUpdate) {
        await (_db.update(
          _db.classroomsTable,
        )..where((tbl) => tbl.id.equals(classroom.id))).write(
          ClassroomsTableCompanion(
            academicYearId: Value(classroom.academicYearId),
            name: Value(classroom.name),
            gradeLevel: Value(classroom.gradeLevel),
            shift: Value(classroom.shift.name),
            updatedAt: Value(now),
          ),
        );
      } else {
        await _db
            .into(_db.classroomsTable)
            .insert(
              ClassroomsTableCompanion(
                id: Value(classroom.id),
                academicYearId: Value(classroom.academicYearId),
                name: Value(classroom.name),
                gradeLevel: Value(classroom.gradeLevel),
                shift: Value(classroom.shift.name),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }

      await _outboxRepository.enqueueOperation(
        entityType: SyncEntityType.classroom,
        entityId: classroom.id,
        operation: isUpdate ? SyncMutationType.update : SyncMutationType.insert,
        payload: SyncPayloadSerializer.classroom(
          classroom,
          createdAt: isUpdate ? null : now,
          updatedAt: now,
        ),
      );

      // Consulta vínculos existentes para comparar adições, atualizações e exclusões
      final oldConfigs = await (_db.select(
        _db.classroomSubjectsTable,
      )..where((tbl) => tbl.classroomId.equals(classroom.id))).get();
      final currentConfigIds = classroom.subjectConfigs
          .map((c) => c.id)
          .toSet();

      // Sincroniza vínculos: remove configurações desassociadas da turma com tombstones
      for (final oldConfig in oldConfigs) {
        if (!currentConfigIds.contains(oldConfig.id)) {
          await (_db.delete(
            _db.classroomSubjectsTable,
          )..where((tbl) => tbl.id.equals(oldConfig.id))).go();
          await _outboxRepository.enqueueDelete(
            entityType: SyncEntityType.classroomSubject,
            entityId: oldConfig.id,
          );
        }
      }

      // Atualiza ou insere os vínculos vigentes das disciplinas da turma
      for (final config in classroom.subjectConfigs) {
        final existingConfig = oldConfigs
            .where((c) => c.id == config.id)
            .firstOrNull;
        final isConfigUpdate = existingConfig != null;

        if (isConfigUpdate) {
          await (_db.update(
            _db.classroomSubjectsTable,
          )..where((tbl) => tbl.id.equals(config.id))).write(
            ClassroomSubjectsTableCompanion(
              classroomId: Value(classroom.id),
              subjectId: Value(config.subjectId),
              weeklyLessons: Value(config.weeklyLessons),
              updatedAt: Value(now),
            ),
          );
        } else {
          await _db
              .into(_db.classroomSubjectsTable)
              .insert(
                ClassroomSubjectsTableCompanion(
                  id: Value(config.id),
                  classroomId: Value(classroom.id),
                  subjectId: Value(config.subjectId),
                  weeklyLessons: Value(config.weeklyLessons),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }

        await _outboxRepository.enqueueOperation(
          entityType: SyncEntityType.classroomSubject,
          entityId: config.id,
          operation: isConfigUpdate
              ? SyncMutationType.update
              : SyncMutationType.insert,
          payload: SyncPayloadSerializer.classroomSubject(
            config,
            classroomId: classroom.id,
            createdAt: isConfigUpdate ? null : now,
            updatedAt: now,
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
    await _db.transaction(() async {
      final configs = await (_db.select(
        _db.classroomSubjectsTable,
      )..where((tbl) => tbl.classroomId.equals(id))).get();

      for (final config in configs) {
        await (_db.delete(
          _db.classroomSubjectsTable,
        )..where((tbl) => tbl.id.equals(config.id))).go();
        await _outboxRepository.enqueueDelete(
          entityType: SyncEntityType.classroomSubject,
          entityId: config.id,
        );
      }

      await (_db.delete(
        _db.classroomsTable,
      )..where((tbl) => tbl.id.equals(id))).go();

      await _outboxRepository.enqueueDelete(
        entityType: SyncEntityType.classroom,
        entityId: id,
      );
    });
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
