import { DataSource, DataSourceOptions } from 'typeorm';
import { User } from '../modules/auth/entities/user.entity';
import { UserSyncVersion } from '../modules/sync-storage/entities/user-sync-version.entity';
import { UserChangeLog } from '../modules/sync-storage/entities/user-change-log.entity';
import { IdempotencyReceipt } from '../modules/sync-storage/entities/idempotency-receipt.entity';
import { AcademicYear } from '../modules/pedagogical/entities/academic-year.entity';
import { Classroom } from '../modules/pedagogical/entities/classroom.entity';
import { Subject } from '../modules/pedagogical/entities/subject.entity';
import { ClassroomSubject } from '../modules/pedagogical/entities/classroom-subject.entity';
import { SchoolCalendarEvent } from '../modules/pedagogical/entities/school-calendar-event.entity';
import { ScheduleSlot } from '../modules/pedagogical/entities/schedule-slot.entity';
import { CurriculumCompetency } from '../modules/pedagogical/entities/curriculum-competency.entity';
import { CourseContent } from '../modules/pedagogical/entities/course-content.entity';
import { ContentPrerequisite } from '../modules/pedagogical/entities/content-prerequisite.entity';
import { PlannedLesson } from '../modules/pedagogical/entities/planned-lesson.entity';
import { LessonContentAllocation } from '../modules/pedagogical/entities/lesson-content-allocation.entity';
import { LessonExecutionRecord } from '../modules/pedagogical/entities/lesson-execution-record.entity';
import { ExecutionContentAllocation } from '../modules/pedagogical/entities/execution-content-allocation.entity';
import { CreateUsersAndSyncTables1710000001000 } from './migrations/1710000001000-CreateUsersAndSyncTables';
import { CreatePedagogicalEntities1710000002000 } from './migrations/1710000002000-CreatePedagogicalEntities';

export const allEntities = [
  User,
  UserSyncVersion,
  UserChangeLog,
  IdempotencyReceipt,
  AcademicYear,
  Classroom,
  Subject,
  ClassroomSubject,
  SchoolCalendarEvent,
  ScheduleSlot,
  CurriculumCompetency,
  CourseContent,
  ContentPrerequisite,
  PlannedLesson,
  LessonContentAllocation,
  LessonExecutionRecord,
  ExecutionContentAllocation,
];

export const allMigrations = [
  CreateUsersAndSyncTables1710000001000,
  CreatePedagogicalEntities1710000002000,
];

export const dataSourceOptions: DataSourceOptions = {
  type: 'postgres',
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432', 10),
  username: process.env.DATABASE_USER || 'guia_user',
  password: process.env.DATABASE_PASSWORD || 'guia_password',
  database: process.env.DATABASE_NAME || 'guia_de_ensino_db',
  ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : false,
  entities: allEntities,
  migrations: allMigrations,
  synchronize: false, // Regra inviolável: nunca usar synchronize em produção ou homologação
  logging: process.env.NODE_ENV === 'development',
};

const AppDataSource = new DataSource(dataSourceOptions);
export default AppDataSource;
