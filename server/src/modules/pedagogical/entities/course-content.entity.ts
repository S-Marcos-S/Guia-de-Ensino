import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
  Unique,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { ClassroomSubject } from './classroom-subject.entity';
import { CurriculumCompetency } from './curriculum-competency.entity';

@Entity('course_contents')
@Unique('uq_course_contents_user', ['id', 'userId'])
export class CourseContent {
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

  @Column({ type: 'varchar', length: 255 })
  title!: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'thematic_unit', type: 'varchar', length: 255, nullable: true })
  thematicUnit?: string;

  @Column({ name: 'estimated_lessons', type: 'int', default: 1 })
  estimatedLessons!: number;

  @Column({ name: 'order_index', type: 'int' })
  orderIndex!: number;

  @Column({ name: 'is_mandatory', type: 'boolean', default: true })
  isMandatory!: boolean;

  @Column({ name: 'curriculum_competency_id', type: 'uuid', nullable: true })
  curriculumCompetencyId?: string;

  @ManyToOne(() => CurriculumCompetency, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn([
    { name: 'curriculum_competency_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  curriculumCompetency?: CurriculumCompetency;

  @Column({ type: 'varchar', length: 50 })
  origin!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz', nullable: true })
  updatedAt?: Date;
}
