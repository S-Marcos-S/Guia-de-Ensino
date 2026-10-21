import { Column, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { bigintTransformer } from '../../../common/transformers/bigint.transformer';
import { User } from '../../auth/entities/user.entity';

export type IdempotencyStatus = 'APPLIED' | 'SKIPPED';

@Entity('idempotency_receipts')
export class IdempotencyReceipt {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @PrimaryColumn({ name: 'device_id', type: 'varchar', length: 100 })
  deviceId!: string;

  @PrimaryColumn({ name: 'client_op_id', type: 'uuid' })
  clientOpId!: string;

  @Column({
    name: 'server_seq',
    type: 'bigint',
    transformer: bigintTransformer,
  })
  serverSeq!: bigint;

  @Column({ name: 'status', type: 'varchar', length: 20 })
  status!: IdempotencyStatus;

  @Column({ name: 'payload_hash', type: 'varchar', length: 64 })
  payloadHash!: string;

  @Column({ name: 'applied_at', type: 'timestamptz' })
  appliedAt!: Date;
}
