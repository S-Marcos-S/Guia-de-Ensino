import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
  Unique,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { ClassroomSubject } from './classroom-subject.entity';
import { PlannedLesson } from './planned-lesson.entity';

@Entity('lesson_execution_records')
@Unique('uq_lesson_execution_records_user', ['id', 'userId'])
@Index('idx_lesson_execution_records_user_lesson', ['userId', 'plannedLessonId'], { unique: true })
export class LessonExecutionRecord {
  @PrimaryColumn({ type: 'uuid' })
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'planned_lesson_id', type: 'uuid' })
  plannedLessonId!: string;

  @ManyToOne(() => PlannedLesson, { onDelete: 'RESTRICT' })
  @JoinColumn([
    { name: 'planned_lesson_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  plannedLesson?: PlannedLesson;

  @Column({ name: 'classroom_subject_id', type: 'uuid' })
  classroomSubjectId!: string;

  @ManyToOne(() => ClassroomSubject, { onDelete: 'RESTRICT' })
  @JoinColumn([
    { name: 'classroom_subject_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  classroomSubject?: ClassroomSubject;

  @Column({ name: 'execution_date', type: 'date' })
  executionDate!: string;

  @Column({ type: 'varchar', length: 50 })
  status!: string;

  @Column({ name: 'cancellation_reason', type: 'varchar', length: 100, nullable: true })
  cancellationReason?: string;

  @Column({ name: 'cancellation_details', type: 'text', nullable: true })
  cancellationDetails?: string;

  @Column({ name: 'pedagogical_notes', type: 'text', nullable: true })
  pedagogicalNotes?: string;

  @Column({ name: 'needs_follow_up', type: 'boolean', default: false })
  needsFollowUp!: boolean;

  @Column({ name: 'follow_up_notes', type: 'text', nullable: true })
  followUpNotes?: string;

  @CreateDateColumn({ name: 'recorded_at', type: 'timestamptz' })
  recordedAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz', nullable: true })
  updatedAt?: Date;
}
