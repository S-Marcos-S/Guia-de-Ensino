import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
  Unique,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';

@Entity('curriculum_competencies')
@Unique('uq_curriculum_competencies_user', ['id', 'userId'])
@Index('idx_curriculum_competencies_user_code', ['userId', 'code'], { unique: true })
export class CurriculumCompetency {
  @PrimaryColumn({ type: 'uuid' })
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ type: 'varchar', length: 50 })
  code!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({ name: 'thematic_unit', type: 'varchar', length: 255 })
  thematicUnit!: string;

  @Column({ name: 'knowledge_object', type: 'text', nullable: true })
  knowledgeObject?: string;

  @Column({ type: 'varchar', length: 100 })
  stage!: string;

  @Column({ name: 'grade_level', type: 'varchar', length: 50 })
  gradeLevel!: string;

  @Column({ name: 'subject_name', type: 'varchar', length: 100 })
  subjectName!: string;

  @Column({ name: 'source_name', type: 'varchar', length: 100 })
  sourceName!: string;

  @Column({ name: 'source_version', type: 'varchar', length: 50 })
  sourceVersion!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
