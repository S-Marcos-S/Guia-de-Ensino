import { Column, Entity, JoinColumn, OneToOne, PrimaryColumn, UpdateDateColumn } from 'typeorm';
import { bigintTransformer } from '../../../common/transformers/bigint.transformer';
import { User } from '../../auth/entities/user.entity';

@Entity('user_sync_version')
export class UserSyncVersion {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({
    name: 'current_seq',
    type: 'bigint',
    default: '0',
    transformer: bigintTransformer,
  })
  currentSeq!: bigint;

  @Column({
    name: 'epoch',
    type: 'bigint',
    default: '1',
    transformer: bigintTransformer,
  })
  epoch!: bigint;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
