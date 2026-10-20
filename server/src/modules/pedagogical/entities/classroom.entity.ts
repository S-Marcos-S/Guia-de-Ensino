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
import { AcademicYear } from './academic-year.entity';

@Entity('classrooms')
@Unique('uq_classrooms_user', ['id', 'userId'])
@Index('idx_classrooms_user_year_name', ['userId', 'academicYearId', 'name'], { unique: true })
export class Classroom {
  @PrimaryColumn({ type: 'uuid' })
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'academic_year_id', type: 'uuid' })
  academicYearId!: string;

  @ManyToOne(() => AcademicYear, { onDelete: 'RESTRICT' })
  @JoinColumn([
    { name: 'academic_year_id', referencedColumnName: 'id' },
    { name: 'user_id', referencedColumnName: 'userId' },
  ])
  academicYear?: AcademicYear;

  @Column({ type: 'varchar', length: 100 })
  name!: string;

  @Column({ name: 'grade_level', type: 'varchar', length: 50 })
  gradeLevel!: string;

  @Column({ type: 'varchar', length: 50 })
  shift!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz', nullable: true })
  updatedAt?: Date;
}
