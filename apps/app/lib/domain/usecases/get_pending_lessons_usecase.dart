import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';

/// Sumário estruturado e categorizado de aulas que demandam apontamento docente.
class PendingLessonsSummary {
  const PendingLessonsSummary({
    required this.classroomSubjectId,
    required this.overdueLessons,
    required this.todayLessons,
    required this.futureLessons,
  });

  final String classroomSubjectId;

  /// Aulas de datas passadas que continuam sem registro (atrasadas).
  final List<PlannedLesson> overdueLessons;

  /// Aulas programadas para o dia de hoje que ainda não foram apontadas.
  final List<PlannedLesson> todayLessons;

  /// Aulas programadas para datas futuras (sem apontamento).
  final List<PlannedLesson> futureLessons;

  /// Total geral de aulas sem apontamento no universo consultado.
  int get totalPendingCount =>
      overdueLessons.length + todayLessons.length + futureLessons.length;

  /// Indica se há pendências com atraso (passadas).
  bool get hasOverdueLessons => overdueLessons.isNotEmpty;
}

/// Caso de uso para consultar aulas pendentes de apontamento docente,
/// separando deterministicamente em atrasadas, de hoje e futuras.
class GetPendingLessonsUseCase {
  const GetPendingLessonsUseCase({
    required this.plannedLessonRepository,
    required this.lessonExecutionRepository,
    this.clock,
  });

  final PlannedLessonRepository plannedLessonRepository;
  final LessonExecutionRepository lessonExecutionRepository;
  final DateTime Function()? clock;

  Future<PendingLessonsSummary> execute({
    required String classroomSubjectId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // 1. Carregar aulas planejadas da disciplina/turma
    final allPlanned = await plannedLessonRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // Filtrar por período se aplicável
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

    // 2. Carregar registros existentes para excluir aulas que já possuem diário
    final allRecords = await lessonExecutionRepository.getByClassroomSubject(
      classroomSubjectId,
    );
    final recordedLessonIds = {for (final r in allRecords) r.plannedLessonId};

    // 3. Normalizar data de referência de "hoje"
    final now = (clock ?? DateTime.now)();
    final today = DateTime.utc(now.year, now.month, now.day);

    final overdue = <PlannedLesson>[];
    final todayLessons = <PlannedLesson>[];
    final future = <PlannedLesson>[];

    for (final lesson in plannedLessons) {
      // Ignora se a aula já possui registro histórico fático
      if (recordedLessonIds.contains(lesson.id)) {
        continue;
      }

      final lessonDateUtc = DateTime.utc(
        lesson.date.year,
        lesson.date.month,
        lesson.date.day,
      );

      if (lessonDateUtc.isBefore(today)) {
        overdue.add(lesson);
      } else if (lessonDateUtc == today) {
        todayLessons.add(lesson);
      } else {
        future.add(lesson);
      }
    }

    // 4. Ordenação determinística por data e por ordem no dia
    int compareLessons(PlannedLesson a, PlannedLesson b) {
      final dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return a.orderInDay.compareTo(b.orderInDay);
    }

    overdue.sort(compareLessons);
    todayLessons.sort(compareLessons);
    future.sort(compareLessons);

    return PendingLessonsSummary(
      classroomSubjectId: classroomSubjectId,
      overdueLessons: overdue,
      todayLessons: todayLessons,
      futureLessons: future,
    );
  }
}
