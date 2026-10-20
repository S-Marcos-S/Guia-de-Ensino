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
      getChangesSinceCursor: jest.fn().mockResolvedValue({
        currentSeq: 10n,
        epoch: 1n,
        changes: [],
        nextCursor: '0:0',
        hasMore: false,
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

  describe('parseCursor', () => {
    it('deve retornar (0n, 0n) para cursor nulo, indefinido ou vazio', async () => {
      const resNull = await syncService.processPull(uuidv4(), { cursor: undefined });
      expect(resNull).toBeDefined();

      const resEmpty = await syncService.processPull(uuidv4(), { cursor: '' });
      expect(resEmpty).toBeDefined();
    });

    it('deve rejeitar cursores malformados, negativos ou não numéricos com BadRequestException', async () => {
      const invalidCursors = [
        'abc',
        '-1:5',
        '10:-2',
        '10',
        '10:20:30',
        ':::',
        'null',
        'undefined:1',
      ];

      for (const cursor of invalidCursors) {
        await expect(syncService.processPull(uuidv4(), { cursor })).rejects.toThrow(
          BadRequestException,
        );
      }
    });
  });

  describe('processPull', () => {
    it('deve processar consulta válida retornando alterações formatadas e nextCursor', async () => {
      const userId = uuidv4();
      mockSyncStorageService.getChangesSinceCursor = jest.fn().mockResolvedValue({
        currentSeq: 25n,
        epoch: 1n,
        changes: [
          {
            id: 101n,
            serverSeq: 20n,
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Matemática' },
            deviceId: 'dev-1',
            createdAt: new Date('2026-10-20T14:40:00.000Z'),
          },
        ],
        nextCursor: '20:101',
        hasMore: false,
      });

      const response = await syncService.processPull(userId, {
        cursor: '15:100',
        limit: 50,
      });

      expect(response.epoch).toBe('1');
      expect(response.currentServerSeq).toBe('25');
      expect(response.nextCursor).toBe('20:101');
      expect(response.hasMore).toBe(false);
      expect(response.changes).toHaveLength(1);
      expect(response.changes[0].serverSeq).toBe('20');
      expect(response.changes[0].changeLogId).toBe('101');

      expect(mockSyncStorageService.getChangesSinceCursor).toHaveBeenCalledWith(
        userId,
        15n,
        100n,
        50,
        undefined,
      );
    });

    it('deve lançar SyncEpochMismatchException (HTTP 410 Gone / RESYNC_REQUIRED) quando clientEpoch for divergente', async () => {
      const userId = uuidv4();
      mockSyncStorageService.getChangesSinceCursor = jest.fn().mockResolvedValue({
        currentSeq: 25n,
        epoch: 2n, // Servidor está na época 2!
        changes: [],
        nextCursor: '0:0',
        hasMore: false,
      });

      await expect(
        syncService.processPull(userId, {
          cursor: '0:0',
          clientEpoch: '1', // Cliente está na época 1!
        }),
      ).rejects.toThrow('Época de sincronização divergente');
    });

    it('deve aceitar cursor além da sequência atual sem lançar erro retornando lista vazia', async () => {
      const userId = uuidv4();
      mockSyncStorageService.getChangesSinceCursor = jest.fn().mockResolvedValue({
        currentSeq: 10n,
        epoch: 1n,
        changes: [],
        nextCursor: '999:0',
        hasMore: false,
      });

      const response = await syncService.processPull(userId, { cursor: '999:0' });
      expect(response.changes).toHaveLength(0);
      expect(response.hasMore).toBe(false);
      expect(response.nextCursor).toBe('999:0');
    });
  });
});
