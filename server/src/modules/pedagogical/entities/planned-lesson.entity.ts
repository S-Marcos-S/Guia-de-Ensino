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

@Entity('planned_lessons')
@Unique('uq_planned_lessons_user', ['id', 'userId'])
@Index(
  'idx_planned_lessons_user_slot',
  ['userId', 'classroomSubjectId', 'lessonDate', 'orderInDay'],
  { unique: true },
)
export class PlannedLesson {
  @PrimaryColumn({ type: 'uuid' })
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'classroom_subject_id', type: 'uuid' })
  classroomSubjectId!: string;

  @ManyToOne(() => ClassroomSubject, { onDelete: 'RESTRICT' })
  @JoinColumn([
    { name: 'classroom_subject_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  classroomSubject?: ClassroomSubject;

  @Column({ name: 'lesson_date', type: 'date' })
  lessonDate!: string;

  @Column({ name: 'order_in_day', type: 'int' })
  orderInDay!: number;

  @Column({ type: 'varchar', length: 50 })
  status!: string;

  @Column({ name: 'is_locked', type: 'boolean', default: false })
  isLocked!: boolean;

  @Column({ type: 'text', nullable: true })
  notes?: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz', nullable: true })
  updatedAt?: Date;
}
