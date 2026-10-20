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
import { Classroom } from './classroom.entity';
import { Subject } from './subject.entity';

@Entity('classroom_subjects')
@Unique('uq_classroom_subjects_user', ['id', 'userId'])
@Index('idx_classroom_subjects_user_class_subj', ['userId', 'classroomId', 'subjectId'], {
  unique: true,
})
export class ClassroomSubject {
  @PrimaryColumn({ type: 'uuid' })
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'classroom_id', type: 'uuid' })
  classroomId!: string;

  @ManyToOne(() => Classroom, { onDelete: 'CASCADE' })
  @JoinColumn([
    { name: 'classroom_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  classroom?: Classroom;

  @Column({ name: 'subject_id', type: 'uuid' })
  subjectId!: string;

  @ManyToOne(() => Subject, { onDelete: 'RESTRICT' })
  @JoinColumn([
    { name: 'subject_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  subject?: Subject;

  @Column({ name: 'weekly_lessons', type: 'int' })
  weeklyLessons!: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz', nullable: true })
  updatedAt?: Date;
}
