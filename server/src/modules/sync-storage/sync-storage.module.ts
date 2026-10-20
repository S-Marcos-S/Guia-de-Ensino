import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserSyncVersion } from './entities/user-sync-version.entity';
import { UserChangeLog } from './entities/user-change-log.entity';
import { IdempotencyReceipt } from './entities/idempotency-receipt.entity';
import { SyncStorageService } from './sync-storage.service';

@Module({
  imports: [TypeOrmModule.forFeature([UserSyncVersion, UserChangeLog, IdempotencyReceipt])],
  providers: [SyncStorageService],
  exports: [SyncStorageService],
})
export class SyncStorageModule {}
