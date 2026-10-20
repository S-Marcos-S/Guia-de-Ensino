import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/models/school_calendar_event.dart';
import 'package:app/domain/models/subject.dart';

/// Serializador canônico de entidades locais para payloads JSON compatíveis
/// com o backend PostgreSQL e o protocolo de sincronização da Subetapa 9.3/9.4.
abstract final class SyncPayloadSerializer {
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String formatDateTime(DateTime dt) => dt.toUtc().toIso8601String();

  /// Payload para `academic_year`.
  static Map<String, dynamic> academicYear(
    AcademicYear year, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': year.id,
      'year': year.year,
      'title': year.title,
      'start_date': formatDate(year.startDate),
      'end_date': formatDate(year.endDate),
      'total_mandatory_days': year.totalMandatoryDays,
      'created_at': ?createdAt?.toUtc().toIso8601String(),
      'updated_at': ?updatedAt?.toUtc().toIso8601String(),
    };
  }

  /// Payload para `classroom`.
  static Map<String, dynamic> classroom(
    Classroom classroom, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': classroom.id,
      'academic_year_id': classroom.academicYearId,
      'name': classroom.name,
      'grade_level': classroom.gradeLevel,
      'shift': classroom.shift.name,
      'created_at': ?createdAt?.toUtc().toIso8601String(),
      'updated_at': ?updatedAt?.toUtc().toIso8601String(),
    };
  }

  /// Payload para `subject`.
  static Map<String, dynamic> subject(
    Subject subject, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': subject.id,
      'name': subject.name,
      'color_hex': subject.colorHex,
      'created_at': ?createdAt?.toUtc().toIso8601String(),
      'updated_at': ?updatedAt?.toUtc().toIso8601String(),
    };
  }

  /// Payload para `classroom_subject`.
  static Map<String, dynamic> classroomSubject(
    ClassroomSubjectConfig config, {
    required String classroomId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': config.id,
      'classroom_id': classroomId,
      'subject_id': config.subjectId,
      'weekly_lessons': config.weeklyLessons,
      'created_at': ?createdAt?.toUtc().toIso8601String(),
      'updated_at': ?updatedAt?.toUtc().toIso8601String(),
    };
  }

  /// Payload para `school_calendar_event`.
  static Map<String, dynamic> schoolCalendarEvent(
    SchoolCalendarEvent event, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': event.id,
      'academic_year_id': event.academicYearId,
      'title': event.title,
      'start_date': formatDate(event.startDate),
      'end_date': formatDate(event.endDate),
      'type': event.type.name,
      'affects_classes': event.affectsClasses,
      'created_at': ?createdAt?.toUtc().toIso8601String(),
      'updated_at': ?updatedAt?.toUtc().toIso8601String(),
    };
  }

  /// Payload para `schedule_slot`.
  static Map<String, dynamic> scheduleSlot(
    ScheduleSlot slot, {
    required String classroomSubjectId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': slot.id,
      'classroom_subject_id': classroomSubjectId,
      'weekday': slot.weekday,
      'order_index': slot.orderIndex,
      'start_time': ?slot.startTime,
      'end_time': ?slot.endTime,
      'created_at': ?createdAt?.toUtc().toIso8601String(),
      'updated_at': ?updatedAt?.toUtc().toIso8601String(),
    };
  }

  /// Payload para `course_content`.
  static Map<String, dynamic> courseContent(
    CourseContent content, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': content.id,
      'classroom_subject_id': content.classroomSubjectId,
      'title': content.title,
      'description': ?content.description,
      'thematic_unit': ?content.thematicUnit,
      'estimated_lessons': content.estimatedLessons,
      'order_index': content.orderIndex,
      'is_mandatory': content.isMandatory,
      'curriculum_competency_id': ?content.curriculumCompetencyId,
      'origin': content.origin.name,
      'created_at': ?createdAt?.toUtc().toIso8601String(),
      'updated_at': ?updatedAt?.toUtc().toIso8601String(),
    };
  }

  /// Payload para tabela associativa `content_prerequisite`.
  static Map<String, dynamic> contentPrerequisite({
    required String contentId,
    required String prerequisiteContentId,
  }) {
    return {
      'content_id': contentId,
      'prerequisite_content_id': prerequisiteContentId,
    };
  }

  /// Payload para `planned_lesson`.
  static Map<String, dynamic> plannedLesson(
    PlannedLesson lesson, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': lesson.id,
      'classroom_subject_id': lesson.classroomSubjectId,
      'lesson_date': formatDate(lesson.date),
      'order_in_day': lesson.orderInDay,
      'status': lesson.status.name,
      'is_locked': lesson.isLocked,
      'notes': ?lesson.notes,
      'created_at': ?createdAt?.toUtc().toIso8601String(),
      'updated_at': ?updatedAt?.toUtc().toIso8601String(),
    };
  }

  /// Payload para tabela associativa `lesson_content_allocation`.
  static Map<String, dynamic> lessonContentAllocation({
    required String lessonId,
    required String contentId,
    required int orderIndex,
  }) {
    return {
      'lesson_id': lessonId,
      'content_id': contentId,
      'order_index': orderIndex,
    };
  }

  /// Payload para `lesson_execution_record`.
  static Map<String, dynamic> lessonExecutionRecord(
    LessonExecutionRecord record, {
    DateTime? updatedAt,
  }) {
    return {
      'id': record.id,
      'planned_lesson_id': record.plannedLessonId,
      'classroom_subject_id': record.classroomSubjectId,
      'execution_date': formatDate(record.executionDate),
      'status': record.status.name,
      'cancellation_reason': ?record.cancellationReason?.name,
      'cancellation_details': ?record.cancellationDetails,
      'pedagogical_notes': ?record.pedagogicalNotes,
      'needs_follow_up': record.needsFollowUp,
      'follow_up_notes': ?record.followUpNotes,
      'recorded_at': formatDateTime(record.recordedAt),
      'updated_at': ?(updatedAt ?? record.updatedAt)?.toUtc().toIso8601String(),
    };
  }

  /// Payload para tabela associativa `execution_content_allocation`.
  static Map<String, dynamic> executionContentAllocation({
    required String recordId,
    required String contentId,
    required int orderIndex,
  }) {
    return {
      'record_id': recordId,
      'content_id': contentId,
      'order_index': orderIndex,
    };
  }
}
