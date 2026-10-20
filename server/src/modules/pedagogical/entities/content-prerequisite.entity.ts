import { Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { CourseContent } from './course-content.entity';

@Entity('content_prerequisites')
export class ContentPrerequisite {
  @PrimaryColumn({ name: 'content_id', type: 'uuid' })
  contentId!: string;

  @PrimaryColumn({ name: 'prerequisite_content_id', type: 'uuid' })
  prerequisiteContentId!: string;

  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @ManyToOne(() => CourseContent, { onDelete: 'CASCADE' })
  @JoinColumn([
    { name: 'content_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  content?: CourseContent;

  @ManyToOne(() => CourseContent, { onDelete: 'RESTRICT' })
  @JoinColumn([
    { name: 'prerequisite_content_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  prerequisiteContent?: CourseContent;
}
