import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DataSource, EntityManager, QueryRunner } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { AuthService, BCRYPT_SALT_ROUNDS } from '../src/modules/auth/auth.service';
import { User } from '../src/modules/auth/entities/user.entity';
import { UserSyncVersion } from '../src/modules/sync-storage/entities/user-sync-version.entity';

describe('AuthService (Unit Tests)', () => {
  let authService: AuthService;
  let jwtService: JwtService;
  let dataSource: DataSource;
  let queryRunner: jest.Mocked<QueryRunner>;
  let manager: jest.Mocked<EntityManager>;

  beforeEach(async () => {
    manager = {
      findOne: jest.fn(),
      create: jest.fn().mockImplementation((entity, dto) => ({ ...dto })),
      save: jest.fn().mockImplementation((entity, obj) => Promise.resolve(obj)),
    } as unknown as jest.Mocked<EntityManager>;

    queryRunner = {
      connect: jest.fn().mockResolvedValue(undefined),
      startTransaction: jest.fn().mockResolvedValue(undefined),
      commitTransaction: jest.fn().mockResolvedValue(undefined),
      rollbackTransaction: jest.fn().mockResolvedValue(undefined),
      release: jest.fn().mockResolvedValue(undefined),
      manager,
    } as unknown as jest.Mocked<QueryRunner>;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: JwtService,
          useValue: {
            sign: jest.fn().mockReturnValue('mocked.jwt.token'),
          },
        },
        {
          provide: DataSource,
          useValue: {
            createQueryRunner: jest.fn().mockReturnValue(queryRunner),
            getRepository: jest.fn().mockReturnValue({
              findOne: jest.fn(),
            }),
          },
        },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
    jwtService = module.get<JwtService>(JwtService);
    dataSource = module.get<DataSource>(DataSource);
  });

  it('deve confirmar que o fator de custo do bcrypt está fixado em 12', () => {
    expect(BCRYPT_SALT_ROUNDS).toBe(12);
  });

  describe('register', () => {
    it('deve registrar usuário com sucesso e inicializar atomicamente user_sync_version com current_seq = 0n', async () => {
      manager.findOne.mockResolvedValue(null);

      const result = await authService.register({
        email: 'professor@escola.gov.br',
        password: 'senha_segura_123',
      });

      expect(queryRunner.connect).toHaveBeenCalled();
      expect(queryRunner.startTransaction).toHaveBeenCalled();
      expect(manager.save).toHaveBeenCalledWith(
        User,
        expect.objectContaining({
          email: 'professor@escola.gov.br',
        }),
      );
      expect(manager.save).toHaveBeenCalledWith(
        UserSyncVersion,
        expect.objectContaining({
          currentSeq: 0n,
          epoch: 1n,
        }),
      );
      expect(queryRunner.commitTransaction).toHaveBeenCalled();
      expect(queryRunner.release).toHaveBeenCalled();
      expect(jwtService.sign).toHaveBeenCalledWith({
        sub: expect.any(String),
        email: 'professor@escola.gov.br',
      });
      expect(result.accessToken).toBe('mocked.jwt.token');
      expect(result.user.email).toBe('professor@escola.gov.br');
    });

    it('deve lançar ConflictException e abortar transação quando o e-mail já existir', async () => {
      manager.findOne.mockResolvedValue({ id: 'existing-id' });

      await expect(
        authService.register({
          email: 'duplicado@escola.gov.br',
          password: 'senha_segura_123',
        }),
      ).rejects.toThrow(ConflictException);

      expect(queryRunner.rollbackTransaction).toHaveBeenCalled();
      expect(queryRunner.release).toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('deve autenticar usuário e retornar token JWT para credenciais válidas', async () => {
      const hashedPassword = await bcrypt.hash('minha_senha_correta', 12);
      const mockUser = {
        id: 'u-123',
        email: 'valido@escola.gov.br',
        passwordHash: hashedPassword,
      };

      jest.spyOn(dataSource.getRepository(User), 'findOne').mockResolvedValue(mockUser as User);

      const result = await authService.login({
        email: 'valido@escola.gov.br',
        password: 'minha_senha_correta',
      });

      expect(jwtService.sign).toHaveBeenCalledWith({
        sub: 'u-123',
        email: 'valido@escola.gov.br',
      });
      expect(result.accessToken).toBe('mocked.jwt.token');
      expect(result.user.id).toBe('u-123');
    });

    it('deve lançar UnauthorizedException quando o usuário não for encontrado', async () => {
      jest.spyOn(dataSource.getRepository(User), 'findOne').mockResolvedValue(null);

      await expect(
        authService.login({
          email: 'inexistente@escola.gov.br',
          password: 'qualquer_senha',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('deve lançar UnauthorizedException quando a senha estiver incorreta', async () => {
      const hashedPassword = await bcrypt.hash('senha_correta', 12);
      const mockUser = {
        id: 'u-123',
        email: 'valido@escola.gov.br',
        passwordHash: hashedPassword,
      };

      jest.spyOn(dataSource.getRepository(User), 'findOne').mockResolvedValue(mockUser as User);

      await expect(
        authService.login({
          email: 'valido@escola.gov.br',
          password: 'senha_errada',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});
