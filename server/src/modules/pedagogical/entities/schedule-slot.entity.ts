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

@Entity('schedule_slots')
@Unique('uq_schedule_slots_user', ['id', 'userId'])
@Index('idx_schedule_slots_user_slot', ['userId', 'classroomSubjectId', 'weekday', 'orderIndex'], {
  unique: true,
})
export class ScheduleSlot {
  @PrimaryColumn({ type: 'uuid' })
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'classroom_subject_id', type: 'uuid' })
  classroomSubjectId!: string;

  @ManyToOne(() => ClassroomSubject, { onDelete: 'CASCADE' })
  @JoinColumn([
    { name: 'classroom_subject_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  classroomSubject?: ClassroomSubject;

  @Column({ type: 'int' })
  weekday!: number;

  @Column({ name: 'order_index', type: 'int' })
  orderIndex!: number;

  @Column({ name: 'start_time', type: 'varchar', length: 5, nullable: true })
  startTime?: string;

  @Column({ name: 'end_time', type: 'varchar', length: 5, nullable: true })
  endTime?: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz', nullable: true })
  updatedAt?: Date;
}
