import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/converters/calendar_date_converter.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Implementação do repositório de Aulas e Registros Históricos utilizando Drift.
class DriftPlannedLessonRepository implements PlannedLessonRepository {
  DriftPlannedLessonRepository(this._db);

  final AppDatabase _db;
  static const _dateConverter = CalendarDateConverter();

  @override
  Future<void> save(PlannedLesson lesson) async {
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
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  @override
  Future<void> saveAll(List<PlannedLesson> lessons) async {
    await _db.batch((batch) {
      for (final lesson in lessons) {
        batch.insert(
          _db.plannedLessonsTable,
          PlannedLessonsTableCompanion.insert(
            id: lesson.id,
            classroomSubjectId: lesson.classroomSubjectId,
            lessonDate: lesson.date,
            orderInDay: lesson.orderInDay,
            status: lesson.status.name,
            isLocked: Value(lesson.isLocked),
            notes: Value(lesson.notes),
            createdAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<PlannedLesson?> findById(String id) async {
    final query = _db.select(_db.plannedLessonsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
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
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<PlannedLesson>> getByDate(DateTime date) async {
    final dateStr = _dateConverter.toSql(date);
    final rows =
        await (_db.select(_db.plannedLessonsTable)
              ..where((tbl) => tbl.lessonDate.equals(dateStr))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderInDay)]))
            .get();
    return rows.map(_toDomain).toList();
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
    return rows.map(_toDomain).toList();
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

    await (_db.delete(
      _db.plannedLessonsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  PlannedLesson _toDomain(PlannedLessonsTableData data) {
    final status = LessonExecutionStatus.values.firstWhere(
      (s) => s.name == data.status,
      orElse: () => LessonExecutionStatus.planned,
    );

    return PlannedLesson(
      id: data.id,
      classroomSubjectId: data.classroomSubjectId,
      date: data.lessonDate,
      orderInDay: data.orderInDay,
      status: status,
      isLocked: data.isLocked,
      notes: data.notes,
    );
  }
}
