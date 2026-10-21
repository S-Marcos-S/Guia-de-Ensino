import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreatePedagogicalEntities1710000002000 implements MigrationInterface {
  name = 'CreatePedagogicalEntities1710000002000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. academic_years
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS academic_years (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        year INT NOT NULL,
        title VARCHAR(255) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        total_mandatory_days INT NOT NULL DEFAULT 200,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_academic_years_user UNIQUE (id, user_id)
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_academic_years_user_year 
      ON academic_years (user_id, year);
    `);

    // 2. classrooms
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS classrooms (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        academic_year_id UUID NOT NULL,
        name VARCHAR(100) NOT NULL,
        grade_level VARCHAR(50) NOT NULL,
        shift VARCHAR(50) NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_classrooms_user UNIQUE (id, user_id),
        CONSTRAINT fk_classrooms_academic_year 
          FOREIGN KEY (academic_year_id, user_id) 
          REFERENCES academic_years(id, user_id) 
          ON DELETE RESTRICT
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_classrooms_user_year_name 
      ON classrooms (user_id, academic_year_id, name);
    `);

    // 3. subjects
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS subjects (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name VARCHAR(100) NOT NULL,
        color_hex VARCHAR(10) NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_subjects_user UNIQUE (id, user_id)
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_subjects_user_name 
      ON subjects (user_id, name);
    `);

    // 4. classroom_subjects
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS classroom_subjects (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        classroom_id UUID NOT NULL,
        subject_id UUID NOT NULL,
        weekly_lessons INT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_classroom_subjects_user UNIQUE (id, user_id),
        CONSTRAINT fk_classroom_subjects_classroom 
          FOREIGN KEY (classroom_id, user_id) 
          REFERENCES classrooms(id, user_id) 
          ON DELETE CASCADE,
        CONSTRAINT fk_classroom_subjects_subject 
          FOREIGN KEY (subject_id, user_id) 
          REFERENCES subjects(id, user_id) 
          ON DELETE RESTRICT
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_classroom_subjects_user_class_subj 
      ON classroom_subjects (user_id, classroom_id, subject_id);
    `);

    // 5. school_calendar_events
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS school_calendar_events (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        academic_year_id UUID NOT NULL,
        title VARCHAR(255) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        type VARCHAR(50) NOT NULL,
        affects_classes BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_school_calendar_events_user UNIQUE (id, user_id),
        CONSTRAINT fk_school_calendar_events_academic_year 
          FOREIGN KEY (academic_year_id, user_id) 
          REFERENCES academic_years(id, user_id) 
          ON DELETE CASCADE
      );
    `);

    // 6. schedule_slots
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS schedule_slots (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        classroom_subject_id UUID NOT NULL,
        weekday INT NOT NULL,
        order_index INT NOT NULL,
        start_time VARCHAR(5),
        end_time VARCHAR(5),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_schedule_slots_user UNIQUE (id, user_id),
        CONSTRAINT fk_schedule_slots_classroom_subject 
          FOREIGN KEY (classroom_subject_id, user_id) 
          REFERENCES classroom_subjects(id, user_id) 
          ON DELETE CASCADE
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_schedule_slots_user_slot 
      ON schedule_slots (user_id, classroom_subject_id, weekday, order_index);
    `);

    // 7. curriculum_competencies
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS curriculum_competencies (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        code VARCHAR(50) NOT NULL,
        description TEXT NOT NULL,
        thematic_unit VARCHAR(255) NOT NULL,
        knowledge_object TEXT,
        stage VARCHAR(100) NOT NULL,
        grade_level VARCHAR(50) NOT NULL,
        subject_name VARCHAR(100) NOT NULL,
        source_name VARCHAR(100) NOT NULL,
        source_version VARCHAR(50) NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (id),
        CONSTRAINT uq_curriculum_competencies_user UNIQUE (id, user_id)
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_curriculum_competencies_user_code 
      ON curriculum_competencies (user_id, code);
    `);

    // 8. course_contents
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS course_contents (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        classroom_subject_id UUID NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        thematic_unit VARCHAR(255),
        estimated_lessons INT NOT NULL DEFAULT 1,
        order_index INT NOT NULL,
        is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
        curriculum_competency_id UUID,
        origin VARCHAR(50) NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_course_contents_user UNIQUE (id, user_id),
        CONSTRAINT fk_course_contents_classroom_subject 
          FOREIGN KEY (classroom_subject_id, user_id) 
          REFERENCES classroom_subjects(id, user_id) 
          ON DELETE RESTRICT,
        CONSTRAINT fk_course_contents_competency 
          FOREIGN KEY (curriculum_competency_id, user_id) 
          REFERENCES curriculum_competencies(id, user_id) 
          ON DELETE SET NULL
      );
    `);

    // 9. content_prerequisites
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS content_prerequisites (
        content_id UUID NOT NULL,
        prerequisite_content_id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        PRIMARY KEY (content_id, prerequisite_content_id, user_id),
        CONSTRAINT fk_content_prerequisites_content 
          FOREIGN KEY (content_id, user_id) 
          REFERENCES course_contents(id, user_id) 
          ON DELETE CASCADE,
        CONSTRAINT fk_content_prerequisites_prereq 
          FOREIGN KEY (prerequisite_content_id, user_id) 
          REFERENCES course_contents(id, user_id) 
          ON DELETE RESTRICT
      );
    `);

    // 10. planned_lessons
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS planned_lessons (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        classroom_subject_id UUID NOT NULL,
        lesson_date DATE NOT NULL,
        order_in_day INT NOT NULL,
        status VARCHAR(50) NOT NULL,
        is_locked BOOLEAN NOT NULL DEFAULT FALSE,
        notes TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_planned_lessons_user UNIQUE (id, user_id),
        CONSTRAINT fk_planned_lessons_classroom_subject 
          FOREIGN KEY (classroom_subject_id, user_id) 
          REFERENCES classroom_subjects(id, user_id) 
          ON DELETE RESTRICT
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_planned_lessons_user_slot 
      ON planned_lessons (user_id, classroom_subject_id, lesson_date, order_in_day);
    `);

    // 11. lesson_content_allocations
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS lesson_content_allocations (
        lesson_id UUID NOT NULL,
        content_id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        order_index INT NOT NULL DEFAULT 1,
        PRIMARY KEY (lesson_id, content_id, user_id),
        CONSTRAINT fk_lesson_content_allocations_lesson 
          FOREIGN KEY (lesson_id, user_id) 
          REFERENCES planned_lessons(id, user_id) 
          ON DELETE CASCADE,
        CONSTRAINT fk_lesson_content_allocations_content 
          FOREIGN KEY (content_id, user_id) 
          REFERENCES course_contents(id, user_id) 
          ON DELETE RESTRICT
      );
    `);

    // 12. lesson_execution_records
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS lesson_execution_records (
        id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        planned_lesson_id UUID NOT NULL,
        classroom_subject_id UUID NOT NULL,
        execution_date DATE NOT NULL,
        status VARCHAR(50) NOT NULL,
        cancellation_reason VARCHAR(100),
        cancellation_details TEXT,
        pedagogical_notes TEXT,
        needs_follow_up BOOLEAN NOT NULL DEFAULT FALSE,
        follow_up_notes TEXT,
        recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ,
        PRIMARY KEY (id),
        CONSTRAINT uq_lesson_execution_records_user UNIQUE (id, user_id),
        CONSTRAINT fk_lesson_execution_records_planned_lesson 
          FOREIGN KEY (planned_lesson_id, user_id) 
          REFERENCES planned_lessons(id, user_id) 
          ON DELETE RESTRICT,
        CONSTRAINT fk_lesson_execution_records_classroom_subject 
          FOREIGN KEY (classroom_subject_id, user_id) 
          REFERENCES classroom_subjects(id, user_id) 
          ON DELETE RESTRICT
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_lesson_execution_records_user_lesson 
      ON lesson_execution_records (user_id, planned_lesson_id);
    `);

    // 13. execution_content_allocations
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS execution_content_allocations (
        record_id UUID NOT NULL,
        content_id UUID NOT NULL,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        order_index INT NOT NULL DEFAULT 1,
        PRIMARY KEY (record_id, content_id, user_id),
        CONSTRAINT fk_execution_content_allocations_record 
          FOREIGN KEY (record_id, user_id) 
          REFERENCES lesson_execution_records(id, user_id) 
          ON DELETE CASCADE,
        CONSTRAINT fk_execution_content_allocations_content 
          FOREIGN KEY (content_id, user_id) 
          REFERENCES course_contents(id, user_id) 
          ON DELETE RESTRICT
      );
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS execution_content_allocations CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS lesson_execution_records CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS lesson_content_allocations CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS planned_lessons CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS content_prerequisites CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS course_contents CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS curriculum_competencies CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS schedule_slots CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS school_calendar_events CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS classroom_subjects CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS subjects CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS classrooms CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS academic_years CASCADE;`);
  }
}
