import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AcademicYear } from './entities/academic-year.entity';
import { Classroom } from './entities/classroom.entity';
import { Subject } from './entities/subject.entity';
import { ClassroomSubject } from './entities/classroom-subject.entity';
import { SchoolCalendarEvent } from './entities/school-calendar-event.entity';
import { ScheduleSlot } from './entities/schedule-slot.entity';
import { CurriculumCompetency } from './entities/curriculum-competency.entity';
import { CourseContent } from './entities/course-content.entity';
import { ContentPrerequisite } from './entities/content-prerequisite.entity';
import { PlannedLesson } from './entities/planned-lesson.entity';
import { LessonContentAllocation } from './entities/lesson-content-allocation.entity';
import { LessonExecutionRecord } from './entities/lesson-execution-record.entity';
import { ExecutionContentAllocation } from './entities/execution-content-allocation.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
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
    ]),
  ],
  exports: [TypeOrmModule],
})
export class PedagogicalModule {}
