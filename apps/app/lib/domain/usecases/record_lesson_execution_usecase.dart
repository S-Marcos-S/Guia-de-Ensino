import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:uuid/uuid.dart';

/// Parâmetros de entrada para registrar ou retificar uma execução de aula.
class RecordLessonExecutionParams {
  const RecordLessonExecutionParams({
    required this.plannedLessonId,
    required this.classroomSubjectId,
    required this.executionDate,
    required this.status,
    this.actualContentIds = const [],
    this.cancellationReason,
    this.cancellationDetails,
    this.pedagogicalNotes,
    this.needsFollowUp = false,
    this.followUpNotes,
  });

  final String plannedLessonId;
  final String classroomSubjectId;
  final DateTime executionDate;
  final LessonExecutionStatus status;
  final List<String> actualContentIds;
  final LessonCancellationReason? cancellationReason;
  final String? cancellationDetails;
  final String? pedagogicalNotes;
  final bool needsFollowUp;
  final String? followUpNotes;
}

/// Caso de uso responsável por gravar ou retificar o apontamento fático do diário de aula,
/// preservando a integridade contextual, o timestamp original de criação (`recordedAt`)
/// e a compatibilidade do modelo de dados.
class RecordLessonExecutionUseCase {
  const RecordLessonExecutionUseCase({
    required this.lessonExecutionRepository,
    required this.plannedLessonRepository,
    this.clock,
  });

  final LessonExecutionRepository lessonExecutionRepository;
  final PlannedLessonRepository plannedLessonRepository;
  final DateTime Function()? clock;

  static const _uuid = Uuid();

  /// Executa o apontamento da aula.
  ///
  /// Se a aula planejada ainda não possuir registro, cria um novo com `recordedAt`
  /// definido pelo relógio. Se já possuir registro, efetua uma retificação pedagógica
  /// preservando `id` e `recordedAt`, e atualizando `updatedAt`.
  Future<LessonExecutionRecord> execute(
    RecordLessonExecutionParams params,
  ) async {
    // 1. Validar a existência da aula planejada
    final plannedLesson = await plannedLessonRepository.findById(
      params.plannedLessonId,
    );

    if (plannedLesson == null) {
      throw LessonExecutionIntegrityException(
        'Aula planejada com ID "${params.plannedLessonId}" não foi encontrada.',
      );
    }

    // 2. Validar consistência de contexto (turma e disciplina)
    if (plannedLesson.classroomSubjectId != params.classroomSubjectId) {
      throw LessonExecutionIntegrityException(
        'A disciplina da turma indicada (${params.classroomSubjectId}) não corresponde '
        'à aula planejada (${plannedLesson.classroomSubjectId}).',
      );
    }

    // 3. Consultar se já existe registro fático prévio para a aula
    final existingRecord = await lessonExecutionRepository
        .findByPlannedLessonId(params.plannedLessonId);

    final now = (clock ?? DateTime.now)().toUtc();

    final LessonExecutionRecord recordToSave;

    if (existingRecord == null) {
      // Criação de novo registro
      recordToSave = LessonExecutionRecord(
        id: _uuid.v4(),
        plannedLessonId: params.plannedLessonId,
        classroomSubjectId: params.classroomSubjectId,
        executionDate: params.executionDate,
        status: params.status,
        actualContentIds: params.actualContentIds,
        cancellationReason: params.cancellationReason,
        cancellationDetails: params.cancellationDetails,
        pedagogicalNotes: params.pedagogicalNotes,
        needsFollowUp: params.needsFollowUp,
        followUpNotes: params.followUpNotes,
        recordedAt: now,
        updatedAt: null,
      );
    } else {
      // Retificação pedagógica de registro existente: preserva id e recordedAt
      // Garante monotonicidade (updatedAt >= recordedAt) caso o relógio retroceda.
      final effectiveUpdatedAt = now.isBefore(existingRecord.recordedAt)
          ? existingRecord.recordedAt
          : now;

      recordToSave = LessonExecutionRecord(
        id: existingRecord.id,
        plannedLessonId: params.plannedLessonId,
        classroomSubjectId: params.classroomSubjectId,
        executionDate: params.executionDate,
        status: params.status,
        actualContentIds: params.actualContentIds,
        cancellationReason: params.cancellationReason,
        cancellationDetails: params.cancellationDetails,
        pedagogicalNotes: params.pedagogicalNotes,
        needsFollowUp: params.needsFollowUp,
        followUpNotes: params.followUpNotes,
        recordedAt: existingRecord.recordedAt,
        updatedAt: effectiveUpdatedAt,
      );
    }

    // 4. Gravação atômica via repositório
    await lessonExecutionRepository.save(recordToSave);

    return recordToSave;
  }
}
