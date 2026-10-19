import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';

/// Resultado detalhado e determinístico do progresso letivo e pedagógico de uma disciplina na turma.
class ClassroomSubjectDetailedProgress {
  const ClassroomSubjectDetailedProgress({
    required this.classroomSubjectId,
    required this.totalLessonsPlanned,
    required this.completedLessonsCount,
    required this.partiallyCompletedLessonsCount,
    required this.notHeldLessonsCount,
    required this.pendingPastLessonsCount,
    required this.pendingTodayLessonsCount,
    required this.futureLessonsCount,
    required this.totalContentsPlannedCount,
    required this.completedContentsCount,
    required this.inProgressContentsCount,
    required this.notStartedContentsCount,
    required this.distinctContentsTaughtIds,
    required this.pendingFollowUpsCount,
    required this.followUpRecords,
  });

  final String classroomSubjectId;

  // --- Classificação Mutuamente Exclusiva e Exaustiva de Aulas ---
  /// Total de aulas previstas no universo consultado.
  final int totalLessonsPlanned;

  /// Aulas realizadas integralmente com registro formal (completed).
  final int completedLessonsCount;

  /// Aulas realizadas parcialmente com registro formal (partiallyCompleted).
  final int partiallyCompletedLessonsCount;

  /// Aulas não realizadas com motivo justificado no diário (notHeld).
  final int notHeldLessonsCount;

  /// Aulas de datas anteriores ao dia atual que continuam sem registro docente.
  final int pendingPastLessonsCount;

  /// Aulas programadas para a data de hoje que ainda não foram apontadas.
  final int pendingTodayLessonsCount;

  /// Aulas programadas para datas futuras (sem registro).
  final int futureLessonsCount;

  // --- Contadores Agregados ---
  /// Total de aulas que já possuem registro fático no diário docente.
  int get totalLessonsRecorded =>
      completedLessonsCount +
      partiallyCompletedLessonsCount +
      notHeldLessonsCount;

  /// Total de aulas com efetivo aproveitamento pedagógico (integral ou parcial).
  int get totalLessonsEffective =>
      completedLessonsCount + partiallyCompletedLessonsCount;

  /// Total de aulas que ainda aguardam apontamento docente.
  int get totalLessonsPending =>
      pendingPastLessonsCount + pendingTodayLessonsCount + futureLessonsCount;

  // --- Taxas Percentuais Determinísticas ---
  /// Taxa de cumprimento pedagógico efetivo em relação ao total previsto.
  /// - Numerador: [totalLessonsEffective]
  /// - Denominador: [totalLessonsPlanned]
  double get effectiveCompletionRate => totalLessonsPlanned > 0
      ? totalLessonsEffective / totalLessonsPlanned
      : 0.0;

  /// Taxa estrita de aulas integralmente concluídas em relação ao total previsto.
  /// - Numerador: [completedLessonsCount]
  /// - Denominador: [totalLessonsPlanned]
  double get strictCompletionRate => totalLessonsPlanned > 0
      ? completedLessonsCount / totalLessonsPlanned
      : 0.0;

  /// Taxa de apontamento docente lançado no diário frente ao total planejado.
  /// - Numerador: [totalLessonsRecorded]
  /// - Denominador: [totalLessonsPlanned]
  double get recordingRate => totalLessonsPlanned > 0
      ? totalLessonsRecorded / totalLessonsPlanned
      : 0.0;

  /// Taxa de aulas não realizadas frente ao total de aulas registradas.
  /// - Numerador: [notHeldLessonsCount]
  /// - Denominador: [totalLessonsRecorded]
  double get cancellationRate => totalLessonsRecorded > 0
      ? notHeldLessonsCount / totalLessonsRecorded
      : 0.0;

  // --- Indicadores Curriculares de Conteúdo ---
  final int totalContentsPlannedCount;
  final int completedContentsCount;
  final int inProgressContentsCount;
  final int notStartedContentsCount;
  final List<String> distinctContentsTaughtIds;

  /// Taxa de conteúdos curriculares concluídos com base na duração estimada em aulas.
  /// - Numerador: [completedContentsCount]
  /// - Denominador: [totalContentsPlannedCount]
  double get contentCompletionRate => totalContentsPlannedCount > 0
      ? completedContentsCount / totalContentsPlannedCount
      : 0.0;

  // --- Continuidade Pedagógica ---
  final int pendingFollowUpsCount;
  final List<LessonExecutionRecord> followUpRecords;
}

/// Caso de uso para calcular deterministicamente os indicadores de progresso
/// pedagógico de uma disciplina na turma.
class GetClassroomSubjectProgressUseCase {
  const GetClassroomSubjectProgressUseCase({
    required this.plannedLessonRepository,
    required this.lessonExecutionRepository,
    required this.courseContentRepository,
    this.clock,
  });

  final PlannedLessonRepository plannedLessonRepository;
  final LessonExecutionRepository lessonExecutionRepository;
  final CourseContentRepository courseContentRepository;
  final DateTime Function()? clock;

  Future<ClassroomSubjectDetailedProgress> execute({
    required String classroomSubjectId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // 1. Carregar todas as aulas planejadas da turma/disciplina
    final allPlanned = await plannedLessonRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // Filtrar pelo período letivo se fornecido
    final List<PlannedLesson> plannedLessons;
    if (startDate != null || endDate != null) {
      plannedLessons = allPlanned.where((l) {
        if (startDate != null && l.date.isBefore(startDate)) return false;
        if (endDate != null && l.date.isAfter(endDate)) return false;
        return true;
      }).toList();
    } else {
      plannedLessons = allPlanned;
    }

    // 2. Carregar os registros de execução fáticos da turma/disciplina
    final allRecords = await lessonExecutionRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // 3. Carregar os conteúdos programáticos planejados da disciplina
    final courseContents = await courseContentRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // 4. Mapear registros por plannedLessonId
    final recordMap = <String, LessonExecutionRecord>{};
    for (final r in allRecords) {
      recordMap[r.plannedLessonId] = r;
    }

    // 5. Data de referência de "hoje" (normalizada em UTC, ano-mês-dia)
    final now = (clock ?? DateTime.now)();
    final today = DateTime.utc(now.year, now.month, now.day);

    var completedCount = 0;
    var partiallyCompletedCount = 0;
    var notHeldCount = 0;
    var pendingPastCount = 0;
    var pendingTodayCount = 0;
    var futureCount = 0;

    final distinctContentsTaught = <String>{};
    final completedLessonCounts = <String, int>{};
    final followUpRecords = <LessonExecutionRecord>[];

    for (final lesson in plannedLessons) {
      final record = recordMap[lesson.id];

      if (record != null) {
        switch (record.status) {
          case LessonExecutionStatus.completed:
            completedCount++;
            for (final cid in record.actualContentIds) {
              distinctContentsTaught.add(cid);
              completedLessonCounts[cid] =
                  (completedLessonCounts[cid] ?? 0) + 1;
            }
            break;
          case LessonExecutionStatus.partiallyCompleted:
            partiallyCompletedCount++;
            for (final cid in record.actualContentIds) {
              distinctContentsTaught.add(cid);
            }
            break;
          case LessonExecutionStatus.notHeld:
            notHeldCount++;
            break;
          case LessonExecutionStatus.planned:
            // Status planned é inválido em registros, mas se ocorrer tratamos como sem registro
            break;
        }

        if (record.needsFollowUp) {
          followUpRecords.add(record);
        }
      } else {
        // Aula sem registro fático: classificar temporalmente contra a data de hoje
        final lessonDateUtc = DateTime.utc(
          lesson.date.year,
          lesson.date.month,
          lesson.date.day,
        );

        if (lessonDateUtc.isBefore(today)) {
          pendingPastCount++;
        } else if (lessonDateUtc == today) {
          pendingTodayCount++;
        } else {
          futureCount++;
        }
      }
    }

    // 6. Apuração da conclusão dos conteúdos programáticos com base na duração estimada
    // Regra conservadora: apenas aulas integralmente concluídas (completed)
    // acumulam carga horária para atingir a estimativa pedagógica (estimatedLessons).
    // Aulas parcialmente concluídas (partiallyCompleted) marcam o conteúdo como abordado / em andamento,
    // mas não comprovam por si sós sua conclusão integral.
    var completedContents = 0;
    var inProgressContents = 0;
    var notStartedContents = 0;

    for (final content in courseContents) {
      final completedLessons = completedLessonCounts[content.id] ?? 0;
      final isAddressed = distinctContentsTaught.contains(content.id);

      if (completedLessons >= content.estimatedLessons &&
          content.estimatedLessons > 0) {
        completedContents++;
      } else if (isAddressed || completedLessons > 0) {
        inProgressContents++;
      } else {
        notStartedContents++;
      }
    }

    return ClassroomSubjectDetailedProgress(
      classroomSubjectId: classroomSubjectId,
      totalLessonsPlanned: plannedLessons.length,
      completedLessonsCount: completedCount,
      partiallyCompletedLessonsCount: partiallyCompletedCount,
      notHeldLessonsCount: notHeldCount,
      pendingPastLessonsCount: pendingPastCount,
      pendingTodayLessonsCount: pendingTodayCount,
      futureLessonsCount: futureCount,
      totalContentsPlannedCount: courseContents.length,
      completedContentsCount: completedContents,
      inProgressContentsCount: inProgressContents,
      notStartedContentsCount: notStartedContents,
      distinctContentsTaughtIds: distinctContentsTaught.toList(),
      pendingFollowUpsCount: followUpRecords.length,
      followUpRecords: followUpRecords,
    );
  }
}
