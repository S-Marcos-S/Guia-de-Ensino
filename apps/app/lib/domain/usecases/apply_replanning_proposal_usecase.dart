import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/replanning_models.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';

/// Caso de uso responsável por aplicar a proposta de replanejamento homologada pelo professor,
/// validando a compatibilidade de concorrência, preservando o histórico factual e garantindo
/// idempotência estrita.
class ApplyReplanningProposalUseCase {
  const ApplyReplanningProposalUseCase({
    required this.plannedLessonRepository,
    required this.lessonExecutionRepository,
  });

  final PlannedLessonRepository plannedLessonRepository;
  final LessonExecutionRepository lessonExecutionRepository;

  /// Aplica a proposta de replanejamento no banco de dados.
  ///
  /// Lança [StateError] se a proposta contiver conflitos bloqueantes fatais.
  /// Lança [OutdatedReplanningProposalException] se o estado fático do banco tiver sido
  /// alterado desde a geração da proposta.
  Future<void> execute(ReplanningProposal proposal) async {
    // 1. Validar se há conflitos impeditivos fatais
    if (proposal.hasFatalConflicts) {
      final fatalMessages = proposal.planningResult.conflicts
          .where((c) => !c.message.toLowerCase().contains('capacidade'))
          .map((c) => c.message)
          .join('; ');
      throw StateError(
        'Não é possível homologar replanejamento com conflitos bloqueantes: $fatalMessages',
      );
    }

    // 2. Carregar aulas e registros atuais do banco para conferência de concorrência e integridade
    final currentLessons = await plannedLessonRepository.getByClassroomSubject(
      proposal.classroomSubjectId,
    );
    final currentRecords = await lessonExecutionRepository
        .getByClassroomSubject(proposal.classroomSubjectId);

    final currentLessonIds = currentLessons.map((l) => l.id).toSet();
    final currentRecordIds = currentRecords.map((r) => r.id).toSet();

    // 3. Validação de Idempotência e Concorrência (Salvaguardas 4 e 6)
    final proposedNewLessonIds = proposal.planningResult.plannedLessons
        .map((a) => a.lesson.id)
        .toSet();

    // Se o banco já possui exatamente o conjunto de aulas da proposta homologada, a aplicação é idempotente
    final isAlreadyApplied =
        currentLessonIds.length == proposedNewLessonIds.length &&
        currentLessonIds.containsAll(proposedNewLessonIds);

    if (!isAlreadyApplied) {
      // Verificar se novos apontamentos foram feitos após a geração da proposta
      final hasNewRecords = !currentRecordIds
          .difference(proposal.sourceExecutionRecordIds)
          .isEmpty;

      // Verificar se aulas foram modificadas ou excluídas externamente
      final hasDivergentLessons = currentLessonIds
          .difference(proposal.sourcePlannedLessonIds)
          .isNotEmpty;

      if (hasNewRecords || hasDivergentLessons) {
        throw const OutdatedReplanningProposalException(
          'O diário de classe ou o cronograma da disciplina foram alterados após o cálculo '
          'desta proposta. Por favor, recalcule o replanejamento antes de homologar.',
        );
      }
    }

    // 4. Mapear registros por plannedLessonId para dupla proteção de histórico
    final recordMap = {for (final r in currentRecords) r.plannedLessonId: r};

    // 5. Excluir com segurança apenas aulas antigas puramente previstas que não fazem parte do novo plano
    for (final PlannedLesson oldLesson in currentLessons) {
      final hasRecord =
          recordMap.containsKey(oldLesson.id) || oldLesson.hasExecutionRecord;
      final isLocked = oldLesson.isLocked;

      // Proteção inviolável: NUNCA apagar aulas históricas nem travadas (Salvaguarda 3)
      if (!hasRecord && !isLocked) {
        if (!proposedNewLessonIds.contains(oldLesson.id)) {
          await plannedLessonRepository.delete(oldLesson.id);
        }
      }
    }

    // 6. Persistir todas as aulas do plano (preservadas e novas reprogramadas)
    final lessonsToSave = proposal.planningResult.plannedLessons
        .map((a) => a.lesson)
        .toList();

    await plannedLessonRepository.saveAll(lessonsToSave);
  }
}
