import { ConflictException, Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import { User } from './entities/user.entity';
import { UserSyncVersion } from '../sync-storage/entities/user-sync-version.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

export const BCRYPT_SALT_ROUNDS = 12;

export interface AuthResponse {
  accessToken: string;
  user: {
    id: string;
    email: string;
  };
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly jwtService: JwtService,
  ) {}

  /**
   * Registra um novo usuário com senha criptografada em bcrypt (fator de custo 12)
   * e inicializa atomicamente a versão de sincronização (user_sync_version)
   * na mesma transação de banco.
   */
  async register(dto: RegisterDto): Promise<AuthResponse> {
    const emailNormalized = dto.email.trim().toLowerCase();

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const existingUser = await queryRunner.manager.findOne(User, {
        where: { email: emailNormalized },
      });

      if (existingUser) {
        throw new ConflictException('Já existe um usuário cadastrado com este e-mail.');
      }

      const passwordHash = await bcrypt.hash(dto.password, BCRYPT_SALT_ROUNDS);
      const userId = uuidv4();

      // 1. Cria a entidade User
      const user = queryRunner.manager.create(User, {
        id: userId,
        email: emailNormalized,
        passwordHash,
        createdAt: new Date(),
      });
      await queryRunner.manager.save(User, user);

      // 2. Inicializa atomicamente a linha de user_sync_version com current_seq = 0n e epoch = 1n
      const syncVersion = queryRunner.manager.create(UserSyncVersion, {
        userId,
        currentSeq: 0n,
        epoch: 1n,
        updatedAt: new Date(),
      });
      await queryRunner.manager.save(UserSyncVersion, syncVersion);

      await queryRunner.commitTransaction();

      this.logger.log(`[AuthService] Usuário ${userId} registrado com sucesso.`);

      const token = this.generateToken(userId, emailNormalized);
      return {
        accessToken: token,
        user: { id: userId, email: emailNormalized },
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Autentica as credenciais com bcrypt e emite token JWT assinado.
   */
  async login(dto: LoginDto): Promise<AuthResponse> {
    const emailNormalized = dto.email.trim().toLowerCase();

    const user = await this.dataSource.getRepository(User).findOne({
      where: { email: emailNormalized },
    });

    if (!user) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    const token = this.generateToken(user.id, user.email);
    return {
      accessToken: token,
      user: { id: user.id, email: user.email },
    };
  }

  private generateToken(userId: string, email: string): string {
    const payload = { sub: userId, email };
    return this.jwtService.sign(payload);
  }
}
