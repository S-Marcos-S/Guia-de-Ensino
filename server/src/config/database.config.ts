import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { allEntities, allMigrations } from '../database/data-source';

export function getDatabaseConfig(configService: ConfigService): TypeOrmModuleOptions {
  return {
    type: 'postgres',
    host: configService.get<string>('DATABASE_HOST', 'localhost'),
    port: configService.get<number>('DATABASE_PORT', 5432),
    username: configService.get<string>('DATABASE_USER', 'guia_user'),
    password: configService.get<string>('DATABASE_PASSWORD'),
    database: configService.get<string>('DATABASE_NAME', 'guia_de_ensino_db'),
    ssl: configService.get<boolean>('DATABASE_SSL', false) ? { rejectUnauthorized: false } : false,
    entities: allEntities,
    migrations: allMigrations,
    synchronize: false, // Regra inviolável do projeto
    logging: configService.get<string>('NODE_ENV') === 'development',
  };
}
