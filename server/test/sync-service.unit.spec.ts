import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SyncService } from '../src/modules/sync/sync.service';
import { SyncStorageService } from '../src/modules/sync-storage/sync-storage.service';
import { PushRequestDto } from '../src/modules/sync/dto/push-request.dto';
import { InvalidCursorException } from '../src/common/exceptions/invalid-cursor.exception';
import { SyncEpochMismatchException } from '../src/common/exceptions/sync-epoch-mismatch.exception';
import { SnapshotExpiredException } from '../src/common/exceptions/snapshot-expired.exception';
import { SnapshotTokenHelper } from '../src/modules/sync/helpers/snapshot-token.helper';
import { v4 as uuidv4 } from 'uuid';

describe('SyncService (Unit Tests)', () => {
  let syncService: SyncService;
  let mockSyncStorageService: Partial<SyncStorageService>;
  let mockConfigService: Partial<ConfigService>;
  const testSecret = 'test-secret-with-minimum-32-chars-long-entropy';

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
      getUserSnapshot: jest.fn().mockResolvedValue({
        snapshotSeq: 15n,
        epoch: 1n,
        entities: {
          academic_years: [{ id: uuidv4(), year: 2026, title: '2026' }],
          classrooms: [],
          subjects: [],
          classroom_subjects: [],
          school_calendar_events: [],
          schedule_slots: [],
          curriculum_competencies: [],
          course_contents: [],
          content_prerequisites: [],
          planned_lessons: [],
          lesson_content_allocations: [],
          lesson_execution_records: [],
          execution_content_allocations: [],
        },
      }),
    };

    mockConfigService = {
      get: jest.fn().mockImplementation((key: string) => {
        if (key === 'JWT_SECRET') return testSecret;
        return undefined;
      }),
    };

    syncService = new SyncService(
      mockSyncStorageService as SyncStorageService,
      mockConfigService as ConfigService,
    );
  });

  describe('processPush', () => {
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

  describe('parseCursor e Validação de Cursor no Pull (Gate de Consistência)', () => {
    it('deve retornar (0n, 0n) para cursor nulo, indefinido ou vazio', async () => {
      const resNull = await syncService.processPull(uuidv4(), { cursor: undefined });
      expect(resNull).toBeDefined();

      const resEmpty = await syncService.processPull(uuidv4(), { cursor: '' });
      expect(resEmpty).toBeDefined();

      const resSpaces = await syncService.processPull(uuidv4(), { cursor: '   ' });
      expect(resSpaces).toBeDefined();
    });

    it('deve rejeitar cursores malformados com InvalidCursorException (HTTP 400, code INVALID_CURSOR)', async () => {
      const invalidCursors = ['abc', '10', '10:20:30', ':::', 'null', 'undefined:1'];

      for (const cursor of invalidCursors) {
        await expect(syncService.processPull(uuidv4(), { cursor })).rejects.toThrow(
          InvalidCursorException,
        );
      }
    });

    it('deve rejeitar cursores com valores negativos com InvalidCursorException', async () => {
      const negativeCursors = ['-1:5', '10:-2', '-5:-5'];

      for (const cursor of negativeCursors) {
        await expect(syncService.processPull(uuidv4(), { cursor })).rejects.toThrow(
          InvalidCursorException,
        );
      }
    });

    it('deve rejeitar cursor futuro (serverSeq > currentServerSeq) com HTTP 400 e code INVALID_CURSOR', async () => {
      const userId = uuidv4();
      mockSyncStorageService.getChangesSinceCursor = jest.fn().mockResolvedValue({
        currentSeq: 10n,
        epoch: 1n,
        changes: [],
        nextCursor: '999:0',
        hasMore: false,
      });

      try {
        await syncService.processPull(userId, { cursor: '999:0' });
        fail('Deveria ter lançado InvalidCursorException');
      } catch (error: unknown) {
        expect(error).toBeInstanceOf(InvalidCursorException);
        const err = error as InvalidCursorException;
        expect(err.getStatus()).toBe(400);
        const resp = err.getResponse() as Record<string, unknown>;
        expect(resp.code).toBe('INVALID_CURSOR');
        expect(resp.requestedSeq).toBe('999');
        expect(resp.currentServerSeq).toBe('10');
      }
    });

    it('deve aceitar cursor no limite válido (serverSeq === currentServerSeq) sem lançar erro', async () => {
      const userId = uuidv4();
      mockSyncStorageService.getChangesSinceCursor = jest.fn().mockResolvedValue({
        currentSeq: 10n,
        epoch: 1n,
        changes: [],
        nextCursor: '10:0',
        hasMore: false,
      });

      const response = await syncService.processPull(userId, { cursor: '10:0' });
      expect(response.changes).toHaveLength(0);
      expect(response.hasMore).toBe(false);
      expect(response.currentServerSeq).toBe('10');
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
      ).rejects.toThrow(SyncEpochMismatchException);
    });
  });

  describe('processSnapshot (Full Resync Consistente)', () => {
    it('deve extrair snapshot consistente com 13 coleções e gerar snapshotToken HMAC assinado', async () => {
      const userId = uuidv4();
      const response = await syncService.processSnapshot(userId, {});

      expect(response.epoch).toBe('1');
      expect(response.snapshotSeq).toBe('15');
      expect(response.snapshotToken).toBeDefined();
      expect(typeof response.snapshotToken).toBe('string');
      expect(response.expiresAt).toBeDefined();
      expect(response.entities).toBeDefined();
      expect(response.entities.academic_years).toHaveLength(1);
      expect(response.entities.academic_years[0].year).toBe(2026);
      expect(mockSyncStorageService.getUserSnapshot).toHaveBeenCalledWith(userId);

      // Valida o token gerado com o helper
      const verified = SnapshotTokenHelper.verifyToken(response.snapshotToken, userId, testSecret);
      expect(verified.userId).toBe(userId);
      expect(verified.snapshotSeq).toBe(15n);
      expect(verified.epoch).toBe(1n);
    });

    it('deve aceitar requisição de snapshot com snapshotToken válido', async () => {
      const userId = uuidv4();
      const { token } = SnapshotTokenHelper.generateToken(userId, 15n, 1n, testSecret, 15);

      const response = await syncService.processSnapshot(userId, { snapshotToken: token });

      expect(response.snapshotSeq).toBe('15');
      expect(mockSyncStorageService.getUserSnapshot).toHaveBeenCalledWith(userId);
    });

    it('deve rejeitar snapshotToken expirado com SnapshotExpiredException (HTTP 410 Gone / SNAPSHOT_EXPIRED)', async () => {
      const userId = uuidv4();
      // Gera token com TTL negativo (-1 minuto)
      const { token } = SnapshotTokenHelper.generateToken(userId, 15n, 1n, testSecret, -1);

      await expect(syncService.processSnapshot(userId, { snapshotToken: token })).rejects.toThrow(
        SnapshotExpiredException,
      );
    });

    it('deve rejeitar snapshotToken adulterado com BadRequestException (code: INVALID_SNAPSHOT_TOKEN)', async () => {
      const userId = uuidv4();
      const { token } = SnapshotTokenHelper.generateToken(userId, 15n, 1n, testSecret, 15);
      const tampered = token.substring(0, token.length - 4) + 'zzzz';

      await expect(
        syncService.processSnapshot(userId, { snapshotToken: tampered }),
      ).rejects.toThrow(BadRequestException);
    });

    it('deve rejeitar snapshotToken de outro usuário com BadRequestException', async () => {
      const userA = uuidv4();
      const userB = uuidv4();
      const { token } = SnapshotTokenHelper.generateToken(userA, 15n, 1n, testSecret, 15);

      await expect(syncService.processSnapshot(userB, { snapshotToken: token })).rejects.toThrow(
        BadRequestException,
      );
    });
  });
});
