/// Tipos canônicos de entidade suportados pelo protocolo de sincronização.
///
/// Mapeiam 1:1 com os identificadores permitidos no backend (ALLOWED_SYNC_ENTITIES).
abstract final class SyncEntityType {
  static const String academicYear = 'academic_year';
  static const String classroom = 'classroom';
  static const String subject = 'subject';
  static const String classroomSubject = 'classroom_subject';
  static const String schoolCalendarEvent = 'school_calendar_event';
  static const String scheduleSlot = 'schedule_slot';
  static const String curriculumCompetency = 'curriculum_competency';
  static const String courseContent = 'course_content';
  static const String contentPrerequisite = 'content_prerequisite';
  static const String plannedLesson = 'planned_lesson';
  static const String lessonContentAllocation = 'lesson_content_allocation';
  static const String lessonExecutionRecord = 'lesson_execution_record';
  static const String executionContentAllocation =
      'execution_content_allocation';

  static const List<String> all = [
    academicYear,
    classroom,
    subject,
    classroomSubject,
    schoolCalendarEvent,
    scheduleSlot,
    curriculumCompetency,
    courseContent,
    contentPrerequisite,
    plannedLesson,
    lessonContentAllocation,
    lessonExecutionRecord,
    executionContentAllocation,
  ];

  static bool isValid(String value) => all.contains(value);
}

/// Tipos canônicos de mutação suportados pelo protocolo de sincronização.
abstract final class SyncMutationType {
  static const String insert = 'INSERT';
  static const String update = 'UPDATE';
  static const String delete = 'DELETE';

  static const List<String> all = [insert, update, delete];

  static bool isValid(String value) => all.contains(value);
}

/// Status canônicos de confirmação (ACK) emitidos pelo servidor.
abstract final class SyncAckStatus {
  static const String applied = 'APPLIED';
  static const String skipped = 'SKIPPED';
  static const String conflict = 'CONFLICT';

  static const List<String> all = [applied, skipped, conflict];

  static bool isValid(String value) => all.contains(value);
}
