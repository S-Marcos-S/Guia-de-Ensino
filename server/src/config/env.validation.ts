import { plainToInstance } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  MinLength,
  validateSync,
} from 'class-validator';

export enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
}

export class EnvironmentVariables {
  @IsEnum(Environment)
  NODE_ENV: Environment = Environment.Development;

  @IsNumber()
  PORT: number = 3000;

  @IsString()
  DATABASE_HOST: string = 'localhost';

  @IsNumber()
  DATABASE_PORT: number = 5432;

  @IsString()
  DATABASE_USER: string = 'guia_user';

  @IsString()
  DATABASE_PASSWORD!: string;

  @IsString()
  DATABASE_NAME: string = 'guia_de_ensino_db';

  @IsBoolean()
  @IsOptional()
  DATABASE_SSL: boolean = false;

  @IsString()
  @MinLength(32, {
    message: 'JWT_SECRET deve possuir no mínimo 32 caracteres para garantir entropia de segurança.',
  })
  JWT_SECRET!: string;

  @IsString()
  @IsOptional()
  JWT_EXPIRATION: string = '7d';
}

export function validateEnvironment(config: Record<string, unknown>): EnvironmentVariables {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    const errorMessages = errors
      .map((e) => Object.values(e.constraints ?? {}).join(', '))
      .join('; ');
    throw new Error(`[Configuração Inválida] Erros nas variáveis de ambiente: ${errorMessages}`);
  }

  return validatedConfig;
}
