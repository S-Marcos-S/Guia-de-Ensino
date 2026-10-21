import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
} from 'typeorm';
import { bigintTransformer } from '../../../common/transformers/bigint.transformer';
import { User } from '../../auth/entities/user.entity';

export type MutationType = 'INSERT' | 'UPDATE' | 'DELETE';

@Entity('user_change_log')
@Index('idx_user_change_log_cursor', ['userId', 'serverSeq', 'id'])
export class UserChangeLog {
  @PrimaryColumn({
    name: 'id',
    type: 'bigint',
    generated: 'identity',
    transformer: bigintTransformer,
  })
  id!: bigint;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({
    name: 'server_seq',
    type: 'bigint',
    transformer: bigintTransformer,
  })
  serverSeq!: bigint;

  @Column({ name: 'entity_type', type: 'varchar', length: 50 })
  entityType!: string;

  @Column({ name: 'entity_id', type: 'uuid' })
  entityId!: string;

  @Column({ name: 'mutation_type', type: 'varchar', length: 10 })
  mutationType!: MutationType;

  @Column({ name: 'payload', type: 'jsonb', nullable: true })
  payload!: Record<string, unknown> | null;

  @Column({ name: 'device_id', type: 'varchar', length: 100 })
  deviceId!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
