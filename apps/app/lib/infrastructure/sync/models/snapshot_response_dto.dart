/// Estrutura de dados contendo o conjunto atômico completo das 13 coleções pedagógicas.
///
/// Espelha o contrato `SnapshotEntitiesDto` do backend NestJS.
class SnapshotEntitiesDto {
  const SnapshotEntitiesDto({
    this.academicYears = const [],
    this.classrooms = const [],
    this.subjects = const [],
    this.classroomSubjects = const [],
    this.schoolCalendarEvents = const [],
    this.scheduleSlots = const [],
    this.curriculumCompetencies = const [],
    this.courseContents = const [],
    this.contentPrerequisites = const [],
    this.plannedLessons = const [],
    this.lessonContentAllocations = const [],
    this.lessonExecutionRecords = const [],
    this.executionContentAllocations = const [],
  });

  final List<Map<String, dynamic>> academicYears;
  final List<Map<String, dynamic>> classrooms;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> classroomSubjects;
  final List<Map<String, dynamic>> schoolCalendarEvents;
  final List<Map<String, dynamic>> scheduleSlots;
  final List<Map<String, dynamic>> curriculumCompetencies;
  final List<Map<String, dynamic>> courseContents;
  final List<Map<String, dynamic>> contentPrerequisites;
  final List<Map<String, dynamic>> plannedLessons;
  final List<Map<String, dynamic>> lessonContentAllocations;
  final List<Map<String, dynamic>> lessonExecutionRecords;
  final List<Map<String, dynamic>> executionContentAllocations;

  static List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  factory SnapshotEntitiesDto.fromJson(Map<String, dynamic> json) {
    return SnapshotEntitiesDto(
      academicYears: _parseList(json['academic_years']),
      classrooms: _parseList(json['classrooms']),
      subjects: _parseList(json['subjects']),
      classroomSubjects: _parseList(json['classroom_subjects']),
      schoolCalendarEvents: _parseList(json['school_calendar_events']),
      scheduleSlots: _parseList(json['schedule_slots']),
      curriculumCompetencies: _parseList(json['curriculum_competencies']),
      courseContents: _parseList(json['course_contents']),
      contentPrerequisites: _parseList(json['content_prerequisites']),
      plannedLessons: _parseList(json['planned_lessons']),
      lessonContentAllocations: _parseList(json['lesson_content_allocations']),
      lessonExecutionRecords: _parseList(json['lesson_execution_records']),
      executionContentAllocations: _parseList(
        json['execution_content_allocations'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'academic_years': academicYears,
      'classrooms': classrooms,
      'subjects': subjects,
      'classroom_subjects': classroomSubjects,
      'school_calendar_events': schoolCalendarEvents,
      'schedule_slots': scheduleSlots,
      'curriculum_competencies': curriculumCompetencies,
      'course_contents': courseContents,
      'content_prerequisites': contentPrerequisites,
      'planned_lessons': plannedLessons,
      'lesson_content_allocations': lessonContentAllocations,
      'lesson_execution_records': lessonExecutionRecords,
      'execution_content_allocations': executionContentAllocations,
    };
  }
}

/// DTO de resposta do endpoint de Full Resync / Snapshot Consistente.
///
/// Espelha o contrato `SnapshotResponseDto` do backend NestJS.
class SnapshotResponseDto {
  const SnapshotResponseDto({
    required this.epoch,
    required this.snapshotSeq,
    required this.snapshotToken,
    required this.expiresAt,
    required this.entities,
  });

  /// Época de sincronização no instante do snapshot (string decimal).
  final String epoch;

  /// Sequência de corte transacional lida sob REPEATABLE READ.
  final String snapshotSeq;

  /// Token opaco assinado via HMAC-SHA256 atestando autenticidade do marco.
  final String snapshotToken;

  /// Timestamp UTC de expiração do token (TTL padrão de 15 minutos).
  final DateTime expiresAt;

  /// Estado completo das 13 coleções pedagógicas.
  final SnapshotEntitiesDto entities;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  factory SnapshotResponseDto.fromJson(Map<String, dynamic> json) {
    return SnapshotResponseDto(
      epoch: json['epoch'] as String,
      snapshotSeq: json['snapshotSeq'] as String,
      snapshotToken: json['snapshotToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
      entities: SnapshotEntitiesDto.fromJson(
        json['entities'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'epoch': epoch,
      'snapshotSeq': snapshotSeq,
      'snapshotToken': snapshotToken,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'entities': entities.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnapshotResponseDto &&
          runtimeType == other.runtimeType &&
          epoch == other.epoch &&
          snapshotSeq == other.snapshotSeq &&
          snapshotToken == other.snapshotToken &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(epoch, snapshotSeq, snapshotToken, expiresAt);
}
