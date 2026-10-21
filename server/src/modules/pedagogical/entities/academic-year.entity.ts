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

@Entity('academic_years')
@Unique('uq_academic_years_user', ['id', 'userId'])
@Index('idx_academic_years_user_year', ['userId', 'year'], { unique: true })
export class AcademicYear {
  @PrimaryColumn({ type: 'uuid' })
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ type: 'int' })
  year!: number;

  @Column({ type: 'varchar', length: 255 })
  title!: string;

  @Column({ name: 'start_date', type: 'date' })
  startDate!: string;

  @Column({ name: 'end_date', type: 'date' })
  endDate!: string;

  @Column({ name: 'total_mandatory_days', type: 'int', default: 200 })
  totalMandatoryDays!: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz', nullable: true })
  updatedAt?: Date;
}
