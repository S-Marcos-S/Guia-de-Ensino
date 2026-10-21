export class SnapshotEntitiesDto {
  academic_years!: Record<string, unknown>[];
  classrooms!: Record<string, unknown>[];
  subjects!: Record<string, unknown>[];
  classroom_subjects!: Record<string, unknown>[];
  school_calendar_events!: Record<string, unknown>[];
  schedule_slots!: Record<string, unknown>[];
  curriculum_competencies!: Record<string, unknown>[];
  course_contents!: Record<string, unknown>[];
  content_prerequisites!: Record<string, unknown>[];
  planned_lessons!: Record<string, unknown>[];
  lesson_content_allocations!: Record<string, unknown>[];
  lesson_execution_records!: Record<string, unknown>[];
  execution_content_allocations!: Record<string, unknown>[];
}

export class SnapshotResponseDto {
  epoch!: string;
  snapshotSeq!: string;
  snapshotToken!: string;
  expiresAt!: string;
  entities!: SnapshotEntitiesDto;
}
