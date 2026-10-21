import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateUsersAndSyncTables1710000001000 implements MigrationInterface {
  name = 'CreateUsersAndSyncTables1710000001000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Tabela de Usuários
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY,
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ
      );
    `);

    // 2. Tabela de Controle de Versão e Sequência de Sincronização
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS user_sync_version (
        user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        current_seq BIGINT NOT NULL DEFAULT 0,
        epoch BIGINT NOT NULL DEFAULT 1,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 3. Tabela de Log de Alterações Imutável
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS user_change_log (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        server_seq BIGINT NOT NULL,
        entity_type VARCHAR(50) NOT NULL,
        entity_id UUID NOT NULL,
        mutation_type VARCHAR(10) NOT NULL,
        payload JSONB,
        device_id VARCHAR(100) NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_user_change_log_cursor 
      ON user_change_log (user_id, server_seq ASC, id ASC);
    `);

    // 4. Tabela de Recibos de Idempotência
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS idempotency_receipts (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        device_id VARCHAR(100) NOT NULL,
        client_op_id UUID NOT NULL,
        server_seq BIGINT NOT NULL,
        status VARCHAR(20) NOT NULL,
        payload_hash VARCHAR(64) NOT NULL,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (user_id, device_id, client_op_id)
      );
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS idempotency_receipts CASCADE;`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_user_change_log_cursor;`);
    await queryRunner.query(`DROP TABLE IF EXISTS user_change_log CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS user_sync_version CASCADE;`);
    await queryRunner.query(`DROP TABLE IF EXISTS users CASCADE;`);
  }
}
