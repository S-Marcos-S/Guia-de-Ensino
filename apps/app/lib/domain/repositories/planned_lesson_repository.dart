import 'package:app/domain/models/planned_lesson.dart';

/// Exceção lançada ao tentar apagar uma aula com registro de execução histórico.
class LessonExecutionProtectedException implements Exception {
  const LessonExecutionProtectedException([
    this.message =
        'Aulas com registros históricos de realização não podem ser excluídas.',
  ]);
  final String message;

  @override
  String toString() => 'LessonExecutionProtectedException: $message';
}

/// Contrato de repositório de domínio para persistência de Aulas e Registros.
abstract interface class PlannedLessonRepository {
  Future<void> save(PlannedLesson lesson);
  Future<void> saveAll(List<PlannedLesson> lessons);
  Future<PlannedLesson?> findById(String id);
  Future<List<PlannedLesson>> getByClassroomSubject(String classroomSubjectId);
  Future<List<PlannedLesson>> getByDate(DateTime date);
  Future<List<PlannedLesson>> getByDateRange(DateTime start, DateTime end);

  /// Exclui uma aula apenas se for prevista (`status == LessonExecutionStatus.planned`).
  /// Se houver registro de execução, deve lançar [LessonExecutionProtectedException].
  Future<void> delete(String id);
}
