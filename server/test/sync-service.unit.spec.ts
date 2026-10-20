import { BadRequestException } from '@nestjs/common';
import { SyncService } from '../src/modules/sync/sync.service';
import { SyncStorageService } from '../src/modules/sync-storage/sync-storage.service';
import { PushRequestDto } from '../src/modules/sync/dto/push-request.dto';
import { v4 as uuidv4 } from 'uuid';

describe('SyncService (Unit Tests)', () => {
  let syncService: SyncService;
  let mockSyncStorageService: Partial<SyncStorageService>;

  beforeEach(() => {
    mockSyncStorageService = {
      processBatchMutations: jest.fn().mockResolvedValue([
        {
          clientOpId: 'op-1',
          serverSeq: 10n,
          status: 'APPLIED',
          appliedAt: new Date('2026-10-20T14:30:00.000Z'),
        },
      ]),
      getUserSyncVersion: jest.fn().mockResolvedValue({
        currentSeq: 10n,
        epoch: 1n,
      }),
    };

    syncService = new SyncService(mockSyncStorageService as SyncStorageService);
  });

  it('deve processar push válido retornando ACKs formatados com BIGINT serializado como string', async () => {
    const userId = uuidv4();
    const dto: PushRequestDto = {
      deviceId: 'device-test',
      clientBatchId: uuidv4(),
      operations: [
        {
          clientOpId: 'op-1',
          entityType: 'academic_year',
          entityId: uuidv4(),
          mutationType: 'INSERT',
          baseSeq: '0',
          clientCreatedAt: new Date().toISOString(),
          payload: { year: 2026, title: 'Ano 2026' },
        },
      ],
    };

    const response = await syncService.processPush(userId, dto);

    expect(response.clientBatchId).toBe(dto.clientBatchId);
    expect(response.serverEpoch).toBe('1');
    expect(response.currentServerSeq).toBe('10');
    expect(response.acks).toHaveLength(1);
    expect(response.acks[0]).toEqual({
      clientOpId: 'op-1',
      status: 'APPLIED',
      serverSeq: '10',
      appliedAt: '2026-10-20T14:30:00.000Z',
      conflict: null,
    });

    expect(mockSyncStorageService.processBatchMutations).toHaveBeenCalledWith(
      userId,
      'device-test',
      expect.arrayContaining([
        expect.objectContaining({
          clientOpId: 'op-1',
          entityType: 'academic_year',
          mutationType: 'INSERT',
        }),
      ]),
    );
  });

  it('deve rejeitar lote contendo clientOpIds duplicados dentro do próprio array lançando BadRequestException', async () => {
    const userId = uuidv4();
    const duplicatedOpId = uuidv4();

    const dto: PushRequestDto = {
      deviceId: 'device-test',
      clientBatchId: uuidv4(),
      operations: [
        {
          clientOpId: duplicatedOpId,
          entityType: 'subject',
          entityId: uuidv4(),
          mutationType: 'INSERT',
          payload: { name: 'Matemática' },
        },
        {
          clientOpId: duplicatedOpId, // Repetido!
          entityType: 'subject',
          entityId: uuidv4(),
          mutationType: 'INSERT',
          payload: { name: 'História' },
        },
      ],
    };

    await expect(syncService.processPush(userId, dto)).rejects.toThrow(BadRequestException);
    expect(mockSyncStorageService.processBatchMutations).not.toHaveBeenCalled();
  });
});
