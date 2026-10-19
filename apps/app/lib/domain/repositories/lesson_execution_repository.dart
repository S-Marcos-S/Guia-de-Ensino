import 'package:app/domain/models/lesson_execution_record.dart';

/// Exceção lançada ao violar a integridade referencial ou contextual de um registro de execução
/// (ex: aula planejada inexistente, divergência de turma/disciplina ou conteúdo pertencente a outro contexto).
class LessonExecutionIntegrityException implements Exception {
  const LessonExecutionIntegrityException(this.message);

  final String message;

  @override
  String toString() => 'LessonExecutionIntegrityException: $message';
}

/// Contrato do repositório de domínio para persistência de registros fáticos de execução de aula.
///
/// **Preservação Histórica e Imutabilidade Fática:**
/// Conforme as regras permanentes do Guia de Ensino (GEMINI.md regras 2 e 5), fatos históricos
/// de aulas registradas no diário docente não podem ser excluídos fisicamente do banco de dados.
/// Ajustes, correções e complementações devem ser realizados através de retificação pedagógica
/// via [save], mantendo o registro de data de retificação ([LessonExecutionRecord.updatedAt])
/// e a rastreabilidade do histórico letivo.
abstract interface class LessonExecutionRepository {
  /// Salva ou atualiza/retifica um registro de execução de aula e seus conteúdos ministrados.
  ///
  /// A operação deve ser executada atomicamente. Lança [LessonExecutionIntegrityException]
  /// se a aula planejada não existir, se a turma/disciplina for incompatível ou se algum
  /// conteúdo informado não pertencer ao contexto curricular da turma.
  Future<void> save(LessonExecutionRecord record);

  /// Busca um registro de execução pelo seu identificador único estável.
  Future<LessonExecutionRecord?> findById(String id);

  /// Busca o registro fático de execução vinculado a uma aula planejada específica.
  /// Retorna `null` se a aula ainda não possui registro histórico (aula pendente/planejada).
  Future<LessonExecutionRecord?> findByPlannedLessonId(String plannedLessonId);

  /// Lista todos os registros de execução fática vinculados a uma disciplina da turma,
  /// ordenados cronologicamente pela data de execução.
  Future<List<LessonExecutionRecord>> getByClassroomSubject(
    String classroomSubjectId,
  );

  /// Lista os registros de execução fática de uma disciplina da turma dentro de um intervalo de datas.
  Future<List<LessonExecutionRecord>> getByDateRange(
    String classroomSubjectId,
    DateTime start,
    DateTime end,
  );
}
