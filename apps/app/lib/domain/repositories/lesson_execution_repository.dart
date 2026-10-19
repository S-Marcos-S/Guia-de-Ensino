import 'package:app/domain/models/lesson_execution_record.dart';

/// Contrato do repositório de domínio para persistência de registros fáticos de execução de aula.
abstract interface class LessonExecutionRepository {
  /// Salva ou atualiza um registro de execução de aula.
  Future<void> save(LessonExecutionRecord record);

  /// Busca um registro de execução pelo seu identificador único estável.
  Future<LessonExecutionRecord?> findById(String id);

  /// Busca o registro fático de execução vinculado a uma aula planejada específica.
  /// Retorna `null` se a aula ainda não possui registro histórico (aula pendente/planejada).
  Future<LessonExecutionRecord?> findByPlannedLessonId(String plannedLessonId);

  /// Lista todos os registros de execução fática vinculados a uma disciplina da turma.
  Future<List<LessonExecutionRecord>> getByClassroomSubject(
    String classroomSubjectId,
  );

  /// Lista os registros de execução fática de uma disciplina da turma dentro de um intervalo de datas.
  Future<List<LessonExecutionRecord>> getByDateRange(
    String classroomSubjectId,
    DateTime start,
    DateTime end,
  );

  /// Exclui um registro de execução fático pelo identificador.
  Future<void> delete(String id);
}
