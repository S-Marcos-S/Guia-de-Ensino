import { Column, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { CourseContent } from './course-content.entity';
import { PlannedLesson } from './planned-lesson.entity';

@Entity('lesson_content_allocations')
export class LessonContentAllocation {
  @PrimaryColumn({ name: 'lesson_id', type: 'uuid' })
  lessonId!: string;

  @PrimaryColumn({ name: 'content_id', type: 'uuid' })
  contentId!: string;

  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @ManyToOne(() => PlannedLesson, { onDelete: 'CASCADE' })
  @JoinColumn([
    { name: 'lesson_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  lesson?: PlannedLesson;

  @ManyToOne(() => CourseContent, { onDelete: 'RESTRICT' })
  @JoinColumn([
    { name: 'content_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  content?: CourseContent;

  @Column({ name: 'order_index', type: 'int', default: 1 })
  orderIndex!: number;
}
