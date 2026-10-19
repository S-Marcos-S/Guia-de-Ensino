import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';

/// Classificação temporal da aula em relação à data civil corrente.
enum LessonTemporalCategory {
  /// Aula cuja data letiva civil é anterior à data de hoje.
  past,

  /// Aula cuja data letiva civil coincide com a data de hoje.
  today,

  /// Aula cuja data letiva civil é posterior à data de hoje.
  future,
}

/// Modelo de leitura agregado e imutável para exibição cronológica de uma aula.
class ClassroomSubjectLessonItem {
  const ClassroomSubjectLessonItem({
    required this.plannedLesson,
    required this.plannedContentTitles,
    required this.actualContentTitles,
    required this.temporalCategory,
    this.executionRecord,
  });

  /// Dados do planejamento original da aula.
  final PlannedLesson plannedLesson;

  /// Títulos dos conteúdos curriculares programados no planejamento.
  final List<String> plannedContentTitles;

  /// Títulos dos conteúdos efetivamente ministrados conforme registro fático (se houver).
  final List<String> actualContentTitles;

  /// Categorização temporal em relação à data de hoje (past, today ou future).
  final LessonTemporalCategory temporalCategory;

  /// Registro fático de execução (nulo se a aula não possui apontamento).
  final LessonExecutionRecord? executionRecord;

  /// Identifica se a aula possui apontamento fático formal no diário.
  bool get hasExecutionRecord => executionRecord != null;

  /// Identifica se é uma aula de data passada que continua sem apontamento docente.
  bool get isPastUnrecorded =>
      temporalCategory == LessonTemporalCategory.past && executionRecord == null;

  /// Status de execução fático se houver registro; caso contrário, status do planejamento.
  LessonExecutionStatus get effectiveStatus =>
      executionRecord?.status ?? plannedLesson.status;
}

/// Caso de uso para consultar deterministicamente todas as aulas planejadas de uma disciplina
/// na turma, associando registros de execução, títulos de conteúdos e categorização temporal civil.
class GetClassroomSubjectLessonsUseCase {
  const GetClassroomSubjectLessonsUseCase({
    required this.plannedLessonRepository,
    required this.lessonExecutionRepository,
    required this.courseContentRepository,
    this.clock,
  });

  final PlannedLessonRepository plannedLessonRepository;
  final LessonExecutionRepository lessonExecutionRepository;
  final CourseContentRepository courseContentRepository;
  final DateTime Function()? clock;

  Future<List<ClassroomSubjectLessonItem>> execute({
    required String classroomSubjectId,
  }) async {
    // 1. Carregar aulas planejadas, registros fáticos e conteúdos da disciplina
    final plannedLessons = await plannedLessonRepository.getByClassroomSubject(
      classroomSubjectId,
    );
    final executionRecords =
        await lessonExecutionRepository.getByClassroomSubject(
          classroomSubjectId,
        );
    final courseContents = await courseContentRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // 2. Mapeamento de títulos dos conteúdos por ID para resolução O(1)
    final contentTitleMap = {
      for (final c in courseContents) c.id: c.title,
    };

    // 3. Mapeamento de registros fáticos por plannedLessonId
    final recordMap = {
      for (final r in executionRecords) r.plannedLessonId: r,
    };

    // 4. Normalização estrita da data civil de referência ("Hoje")
    // Extrai ano, mês e dia da hora local/injetada para evitar deslocamento de fuso
    final now = (clock ?? DateTime.now)();
    final todayCivil = DateTime.utc(now.year, now.month, now.day);

    // 5. Ordenação determinística estrita:
    //    1º: Data da aula em ordem crescente
    //    2º: orderInDay em ordem crescente
    //    3º: PlannedLesson.id em ordem lexicográfica crescente
    final sortedLessons = List<PlannedLesson>.from(plannedLessons)..sort((a, b) {
      final dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;

      final orderComp = a.orderInDay.compareTo(b.orderInDay);
      if (orderComp != 0) return orderComp;

      return a.id.compareTo(b.id);
    });

    // 6. Construção da coleção agregada de leitura
    final items = <ClassroomSubjectLessonItem>[];

    for (final lesson in sortedLessons) {
      final record = recordMap[lesson.id];

      // Normaliza a data da aula em data civil pura
      final lessonDateCivil = DateTime.utc(
        lesson.date.year,
        lesson.date.month,
        lesson.date.day,
      );

      final LessonTemporalCategory temporalCategory;
      if (lessonDateCivil.isBefore(todayCivil)) {
        temporalCategory = LessonTemporalCategory.past;
      } else if (lessonDateCivil == todayCivil) {
        temporalCategory = LessonTemporalCategory.today;
      } else {
        temporalCategory = LessonTemporalCategory.future;
      }

      // Resolução dos títulos dos conteúdos planejados
      final plannedTitles = lesson.contentIds
          .map((id) => contentTitleMap[id] ?? id)
          .toList();

      // Resolução dos títulos dos conteúdos efetivamente abordados
      final actualTitles = record != null
          ? record.actualContentIds
              .map((id) => contentTitleMap[id] ?? id)
              .toList()
          : const <String>[];

      items.add(
        ClassroomSubjectLessonItem(
          plannedLesson: lesson,
          plannedContentTitles: plannedTitles,
          actualContentTitles: actualTitles,
          temporalCategory: temporalCategory,
          executionRecord: record,
        ),
      );
    }

    return items;
  }
}
