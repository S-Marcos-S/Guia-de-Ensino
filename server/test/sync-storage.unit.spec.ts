import { bigintTransformer } from '../src/common/transformers/bigint.transformer';
import { SyncStorageService } from '../src/modules/sync-storage/sync-storage.service';
import { IdempotencyConflictException } from '../src/common/exceptions/idempotency-conflict.exception';
import { validateEnvironment } from '../src/config/env.validation';
import { SnapshotTokenHelper } from '../src/modules/sync/helpers/snapshot-token.helper';
import { DataSource } from 'typeorm';

describe('SyncStorage & Common Utilities (Unit Tests)', () => {
  describe('bigintTransformer', () => {
    it('deve preservar a precisão de inteiros de 64 bits além do Number.MAX_SAFE_INTEGER', () => {
      // 2^53 - 1 = 9007199254740991
      // Valor significativamente maior que excede a precisão segura do IEEE 754 float
      const hugeBigInt = 900719925474099199999n;

      const serialized = bigintTransformer.to(hugeBigInt);
      expect(serialized).toBe('900719925474099199999');

      const restored = bigintTransformer.from(serialized);
      expect(restored).toBe(hugeBigInt);
      expect(typeof restored).toBe('bigint');
    });

    it('deve tratar null e undefined sem lançar exceções', () => {
      expect(bigintTransformer.to(null)).toBeNull();
      expect(bigintTransformer.to(undefined)).toBeNull();
      expect(bigintTransformer.from(null)).toBeNull();
      expect(bigintTransformer.from(undefined)).toBeNull();
    });
  });

  describe('computePayloadHash', () => {
    let service: SyncStorageService;

    beforeEach(() => {
      service = new SyncStorageService({} as DataSource);
    });

    it('deve ser estritamente determinístico independentemente da ordem das chaves no objeto', () => {
      const obj1 = { title: 'Aula de Matemática', order: 1, isLocked: false };
      const obj2 = { isLocked: false, order: 1, title: 'Aula de Matemática' };

      const hash1 = service.computePayloadHash(obj1);
      const hash2 = service.computePayloadHash(obj2);

      expect(hash1).toBe(hash2);
      expect(hash1).toHaveLength(64); // SHA-256 hex
    });

    it('deve gerar hashes distintos para conteúdos diferentes', () => {
      const obj1 = { title: 'Aula 1' };
      const obj2 = { title: 'Aula 2' };

      const hash1 = service.computePayloadHash(obj1);
      const hash2 = service.computePayloadHash(obj2);

      expect(hash1).not.toBe(hash2);
    });

    it('deve gerar hash determinístico para payload nulo', () => {
      const hashNull1 = service.computePayloadHash(null);
      const hashNull2 = service.computePayloadHash(null);
      expect(hashNull1).toBe(hashNull2);
      expect(hashNull1).toHaveLength(64);
    });
  });

  describe('getChangesSinceCursor (Janela de Eventos Examinados e Cursor Progression)', () => {
    let service: SyncStorageService;
    let mockQueryRunner: {
      connect: jest.Mock;
      startTransaction: jest.Mock;
      commitTransaction: jest.Mock;
      rollbackTransaction: jest.Mock;
      release: jest.Mock;
      manager: { query: jest.Mock };
    };
    let mockDataSource: { createQueryRunner: jest.Mock };

    beforeEach(() => {
      mockQueryRunner = {
        connect: jest.fn().mockResolvedValue(undefined),
        startTransaction: jest.fn().mockResolvedValue(undefined),
        commitTransaction: jest.fn().mockResolvedValue(undefined),
        rollbackTransaction: jest.fn().mockResolvedValue(undefined),
        release: jest.fn().mockResolvedValue(undefined),
        manager: {
          query: jest.fn(),
        },
      };

      mockDataSource = {
        createQueryRunner: jest.fn().mockReturnValue(mockQueryRunner),
      };

      service = new SyncStorageService(mockDataSource as unknown as DataSource);
    });

    it('1. Todos os eventos examinados pertencem ao dispositivo excluído: cursor deve avançar para o último examinado', async () => {
      mockQueryRunner.manager.query
        .mockResolvedValueOnce([{ current_seq: '5', epoch: '1' }]) // user_sync_version
        .mockResolvedValueOnce([
          {
            id: '10',
            server_seq: '1',
            entity_type: 'subject',
            entity_id: 's-1',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-1',
            created_at: new Date(),
          },
          {
            id: '11',
            server_seq: '2',
            entity_type: 'subject',
            entity_id: 's-2',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-1',
            created_at: new Date(),
          },
        ]);

      const result = await service.getChangesSinceCursor('u-1', 0n, 0n, 10, 'dev-1');

      // changes vazio (eco descartado), mas o cursor avança para a última linha examinada (2:11)
      expect(result.changes).toHaveLength(0);
      expect(result.hasMore).toBe(false);
      expect(result.nextCursor).toBe('2:11');
      expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
    });

    it('2. Eventos próprios e de outros dispositivos intercalados: retorna apenas terceiros e avança cursor', async () => {
      mockQueryRunner.manager.query
        .mockResolvedValueOnce([{ current_seq: '5', epoch: '1' }])
        .mockResolvedValueOnce([
          {
            id: '101',
            server_seq: '1',
            entity_type: 'subject',
            entity_id: 's-1',
            mutation_type: 'INSERT',
            payload: { name: 'Matemática' },
            device_id: 'dev-1',
            created_at: new Date(),
          },
          {
            id: '102',
            server_seq: '1',
            entity_type: 'subject',
            entity_id: 's-2',
            mutation_type: 'INSERT',
            payload: { name: 'História' },
            device_id: 'dev-2',
            created_at: new Date(),
          },
          {
            id: '103',
            server_seq: '2',
            entity_type: 'subject',
            entity_id: 's-3',
            mutation_type: 'INSERT',
            payload: { name: 'Geografia' },
            device_id: 'dev-1',
            created_at: new Date(),
          },
        ]);

      const result = await service.getChangesSinceCursor('u-1', 0n, 0n, 10, 'dev-1');

      // Apenas evento de dev-2 é retornado, mas nextCursor é a última linha examinada (2:103)
      expect(result.changes).toHaveLength(1);
      expect(result.changes[0].deviceId).toBe('dev-2');
      expect(result.changes[0].entityId).toBe('s-2');
      expect(result.nextCursor).toBe('2:103');
      expect(result.hasMore).toBe(false);
    });

    it('3. Mais eventos do que o limite da página (hasMore: true): delimita janela examinada e cursor da página', async () => {
      // limit = 2. A query solicita limit + 1 = 3 linhas
      mockQueryRunner.manager.query
        .mockResolvedValueOnce([{ current_seq: '5', epoch: '1' }])
        .mockResolvedValueOnce([
          {
            id: '1',
            server_seq: '1',
            entity_type: 'subject',
            entity_id: 's-1',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-2',
            created_at: new Date(),
          },
          {
            id: '2',
            server_seq: '2',
            entity_type: 'subject',
            entity_id: 's-2',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-2',
            created_at: new Date(),
          },
          {
            id: '3',
            server_seq: '3',
            entity_type: 'subject',
            entity_id: 's-3',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-2',
            created_at: new Date(),
          },
        ]);

      const result = await service.getChangesSinceCursor('u-1', 0n, 0n, 2, undefined);

      expect(result.hasMore).toBe(true);
      expect(result.changes).toHaveLength(2); // Retorna exatamente limit = 2
      expect(result.nextCursor).toBe('2:2'); // Cursor aponta para o 2º elemento examinado
    });

    it('4. Eventos que compartilham server_seq e diferem em id: ordenação determinística e cursor preservado', async () => {
      mockQueryRunner.manager.query
        .mockResolvedValueOnce([{ current_seq: '5', epoch: '1' }])
        .mockResolvedValueOnce([
          {
            id: '20',
            server_seq: '3',
            entity_type: 'planned_lesson',
            entity_id: 'pl-1',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-2',
            created_at: new Date(),
          },
          {
            id: '21',
            server_seq: '3',
            entity_type: 'planned_lesson',
            entity_id: 'pl-2',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-2',
            created_at: new Date(),
          },
        ]);

      const result = await service.getChangesSinceCursor('u-1', 3n, 19n, 10, undefined);

      expect(result.changes).toHaveLength(2);
      expect(result.changes[0].serverSeq).toBe(3n);
      expect(result.changes[0].id).toBe(20n);
      expect(result.changes[1].serverSeq).toBe(3n);
      expect(result.changes[1].id).toBe(21n);
      expect(result.nextCursor).toBe('3:21');
    });

    it('5. Novos eventos confirmados entre chamadas consecutivas de Pull: retoma exatamente a partir de nextCursor', async () => {
      // Chamada 1: alcança (10, 50)
      mockQueryRunner.manager.query
        .mockResolvedValueOnce([{ current_seq: '10', epoch: '1' }])
        .mockResolvedValueOnce([
          {
            id: '50',
            server_seq: '10',
            entity_type: 'subject',
            entity_id: 's-50',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-2',
            created_at: new Date(),
          },
        ]);

      const page1 = await service.getChangesSinceCursor('u-1', 9n, 0n, 10, undefined);
      expect(page1.nextCursor).toBe('10:50');

      // Chamada 2: novos eventos comutados em serverSeq = 11
      mockQueryRunner.manager.query
        .mockResolvedValueOnce([{ current_seq: '11', epoch: '1' }])
        .mockResolvedValueOnce([
          {
            id: '51',
            server_seq: '11',
            entity_type: 'subject',
            entity_id: 's-51',
            mutation_type: 'INSERT',
            payload: {},
            device_id: 'dev-2',
            created_at: new Date(),
          },
        ]);

      const page2 = await service.getChangesSinceCursor('u-1', 10n, 50n, 10, undefined);
      expect(page2.changes).toHaveLength(1);
      expect(page2.changes[0].serverSeq).toBe(11n);
      expect(page2.changes[0].id).toBe(51n);
      expect(page2.nextCursor).toBe('11:51');

      // Verifica que a query utilizou os parâmetros do cursor anterior
      expect(mockQueryRunner.manager.query).toHaveBeenLastCalledWith(
        expect.stringContaining('(server_seq, id) > ($2, $3)'),
        ['u-1', '10', '50', 11],
      );
    });
  });

  describe('SnapshotTokenHelper (Derivação HKDF e Criptografia)', () => {
    const validMasterSecret =
      'chave-mestre-secreta-com-mais-de-trinta-e-dois-caracteres-de-entropia';

    it('deve derivar uma subchave exclusiva de 32 bytes via HKDF-SHA256 com contexto específico', () => {
      const derivedKey = SnapshotTokenHelper.deriveKey(validMasterSecret);
      expect(Buffer.isBuffer(derivedKey)).toBe(true);
      expect(derivedKey.length).toBe(32); // 256 bits

      // Deve ser determinístico para a mesma chave mestre
      const derivedKey2 = SnapshotTokenHelper.deriveKey(validMasterSecret);
      expect(derivedKey.equals(derivedKey2)).toBe(true);

      // Deve ser diferente para chaves mestres distintas
      const differentKey = SnapshotTokenHelper.deriveKey(validMasterSecret + '-diferente');
      expect(derivedKey.equals(differentKey)).toBe(false);
    });

    it('deve rejeitar chave mestre com menos de 32 caracteres para derivação segura', () => {
      expect(() => SnapshotTokenHelper.deriveKey('chave-curta-insegura')).toThrow(
        /O segredo mestre deve possuir no mínimo 32 caracteres/,
      );
    });

    it('deve gerar e verificar tokens com sucesso utilizando a subchave derivada via HKDF', () => {
      const { token, expiresAt } = SnapshotTokenHelper.generateToken(
        'user-uuid-1',
        25n,
        1n,
        validMasterSecret,
        15,
      );

      expect(typeof token).toBe('string');
      expect(expiresAt.getTime()).toBeGreaterThan(Date.now());

      const payload = SnapshotTokenHelper.verifyToken(token, 'user-uuid-1', validMasterSecret);
      expect(payload.userId).toBe('user-uuid-1');
      expect(payload.snapshotSeq).toBe(25n);
      expect(payload.epoch).toBe(1n);
    });
  });

  describe('IdempotencyConflictException', () => {
    it('deve retornar status 409 (Conflict) e mensagem contextual em português', () => {
      const ex = new IdempotencyConflictException('op-uuid-123');
      expect(ex.getStatus()).toBe(409);
      expect(ex.message).toContain('op-uuid-123');
      expect(ex.message).toContain('já foi registrada anteriormente com payload diferente');
    });
  });

  describe('validateEnvironment', () => {
    it('deve aceitar variáveis válidas com JWT_SECRET de pelo menos 32 caracteres', () => {
      const validConfig = {
        NODE_ENV: 'test',
        PORT: '3000',
        DATABASE_HOST: 'localhost',
        DATABASE_PORT: '5432',
        DATABASE_USER: 'guia_user',
        DATABASE_PASSWORD: 'guia_password',
        DATABASE_NAME: 'guia_de_ensino_db',
        JWT_SECRET: 'uma_chave_secreta_com_mais_de_trinta_e_dois_caracteres_segura',
      };

      const result = validateEnvironment(validConfig);
      expect(result.JWT_SECRET).toBe(
        'uma_chave_secreta_com_mais_de_trinta_e_dois_caracteres_segura',
      );
      expect(result.PORT).toBe(3000);
    });

    it('deve rejeitar JWT_SECRET com menos de 32 caracteres para impedir segredos fracos', () => {
      const weakConfig = {
        NODE_ENV: 'test',
        DATABASE_PASSWORD: 'pass',
        JWT_SECRET: 'curta_demais', // menos de 32 chars
      };

      expect(() => validateEnvironment(weakConfig)).toThrow(
        /JWT_SECRET deve possuir no mínimo 32 caracteres/,
      );
    });
  });
});
