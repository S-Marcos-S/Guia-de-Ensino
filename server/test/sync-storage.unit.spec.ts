import { bigintTransformer } from '../src/common/transformers/bigint.transformer';
import { SyncStorageService } from '../src/modules/sync-storage/sync-storage.service';
import { IdempotencyConflictException } from '../src/common/exceptions/idempotency-conflict.exception';
import { validateEnvironment } from '../src/config/env.validation';
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
