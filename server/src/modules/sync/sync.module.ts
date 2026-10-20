import { Module } from '@nestjs/common';
import { SyncStorageModule } from '../sync-storage/sync-storage.module';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';

@Module({
  imports: [SyncStorageModule],
  controllers: [SyncController],
  providers: [SyncService],
  exports: [SyncService],
})
export class SyncModule {}
