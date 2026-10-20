import { Column, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { CourseContent } from './course-content.entity';
import { LessonExecutionRecord } from './lesson-execution-record.entity';

@Entity('execution_content_allocations')
export class ExecutionContentAllocation {
  @PrimaryColumn({ name: 'record_id', type: 'uuid' })
  recordId!: string;

  @PrimaryColumn({ name: 'content_id', type: 'uuid' })
  contentId!: string;

  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @ManyToOne(() => LessonExecutionRecord, { onDelete: 'CASCADE' })
  @JoinColumn([
    { name: 'record_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  record?: LessonExecutionRecord;

  @ManyToOne(() => CourseContent, { onDelete: 'RESTRICT' })
  @JoinColumn([
    { name: 'content_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  content?: CourseContent;

  @Column({ name: 'order_index', type: 'int', default: 1 })
  orderIndex!: number;
}
