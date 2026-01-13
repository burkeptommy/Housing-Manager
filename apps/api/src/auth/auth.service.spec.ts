import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma';

import { AuthService } from './auth.service';
import { RegisterDto, LoginDto } from './dto';

describe('AuthService', () => {
  let service: AuthService;
  let prismaService: PrismaService;
  let jwtService: JwtService;

  const mockUser = {
    id: 'user-123',
    email: 'test@example.com',
    passwordHash: '$2b$12$hashedpassword',
    firstName: 'John',
    lastName: 'Doe',
    phone: null,
    avatarUrl: null,
    role: UserRole.HOMEOWNER,
    emailVerified: false,
    emailVerifiedAt: null,
    lastLoginAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockHousehold = {
    id: 'household-123',
    name: "John's Home",
    description: null,
    ownerId: 'user-123',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockRefreshToken = {
    id: 'token-123',
    userId: 'user-123',
    token: 'refresh-token-value',
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    isRevoked: false,
    userAgent: 'test-agent',
    ipAddress: '127.0.0.1',
    createdAt: new Date(),
    updatedAt: new Date(),
    user: mockUser,
  };

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    household: {
      create: jest.fn(),
    },
    refreshToken: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    householdMember: {
      create: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const mockJwtService = {
    sign: jest.fn().mockReturnValue('mock-access-token'),
    verify: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string, defaultValue?: unknown) => {
      const config: Record<string, unknown> = {
        JWT_SECRET: 'test-secret',
        JWT_ACCESS_EXPIRES_IN: 900,
        JWT_REFRESH_EXPIRES_DAYS: 7,
      };
      return config[key] ?? defaultValue;
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    prismaService = module.get<PrismaService>(PrismaService);
    jwtService = module.get<JwtService>(JwtService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('register', () => {
    const registerDto: RegisterDto = {
      email: 'test@example.com',
      password: 'Password123!',
      firstName: 'John',
      lastName: 'Doe',
    };

    it('should successfully register a new user', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);
      mockPrismaService.$transaction.mockImplementation(async (callback) => {
        return callback({
          user: {
            create: jest.fn().mockResolvedValue(mockUser),
          },
          household: {
            create: jest.fn().mockResolvedValue(mockHousehold),
          },
        });
      });
      mockPrismaService.refreshToken.create.mockResolvedValue(mockRefreshToken);

      const result = await service.register(registerDto);

      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe(mockUser.email);
    });

    it('should throw ConflictException if user already exists', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);

      await expect(service.register(registerDto)).rejects.toThrow(ConflictException);
    });
  });

  describe('login', () => {
    const loginDto: LoginDto = {
      email: 'test@example.com',
      password: 'Password123!',
    };

    it('should successfully login a user with valid credentials', async () => {
      const hashedPassword = await bcrypt.hash('Password123!', 12);
      const userWithValidPassword = { ...mockUser, passwordHash: hashedPassword };

      mockPrismaService.user.findUnique.mockResolvedValue(userWithValidPassword);
      mockPrismaService.user.update.mockResolvedValue(userWithValidPassword);
      mockPrismaService.refreshToken.create.mockResolvedValue(mockRefreshToken);

      const result = await service.login(loginDto);

      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
    });

    it('should throw UnauthorizedException if user does not exist', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(service.login(loginDto)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException if password is invalid', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);

      await expect(service.login(loginDto)).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('refresh', () => {
    it('should return new access token for valid refresh token', async () => {
      mockPrismaService.refreshToken.findUnique.mockResolvedValue(mockRefreshToken);
      mockPrismaService.refreshToken.update.mockResolvedValue({
        ...mockRefreshToken,
        isRevoked: true,
      });

      const result = await service.refresh('refresh-token-value');

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('expiresIn');
    });

    it('should throw UnauthorizedException for invalid refresh token', async () => {
      mockPrismaService.refreshToken.findUnique.mockResolvedValue(null);

      await expect(service.refresh('invalid-token')).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for revoked refresh token', async () => {
      mockPrismaService.refreshToken.findUnique.mockResolvedValue({
        ...mockRefreshToken,
        isRevoked: true,
      });
      mockPrismaService.refreshToken.updateMany.mockResolvedValue({ count: 1 });

      await expect(service.refresh('refresh-token-value')).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for expired refresh token', async () => {
      mockPrismaService.refreshToken.findUnique.mockResolvedValue({
        ...mockRefreshToken,
        expiresAt: new Date(Date.now() - 1000), // Expired
      });

      await expect(service.refresh('refresh-token-value')).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('logout', () => {
    it('should revoke specific refresh token', async () => {
      mockPrismaService.refreshToken.updateMany.mockResolvedValue({ count: 1 });

      await service.logout('user-123', 'refresh-token-value');

      expect(mockPrismaService.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-123', token: 'refresh-token-value' },
        data: { isRevoked: true },
      });
    });

    it('should revoke all refresh tokens when no specific token provided', async () => {
      mockPrismaService.refreshToken.updateMany.mockResolvedValue({ count: 3 });

      await service.logout('user-123');

      expect(mockPrismaService.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-123', isRevoked: false },
        data: { isRevoked: true },
      });
    });
  });

  describe('getMe', () => {
    it('should return user with household and memberships', async () => {
      const userWithHouseholds = {
        ...mockUser,
        householdMembers: [
          {
            role: 'OWNER',
            status: 'ACTIVE',
            household: {
              ...mockHousehold,
              homeProfile: {
                id: 'home-profile-1',
                addressLine1: '123 Main St',
                city: 'Springfield',
                state: 'IL',
                postalCode: '62701',
              },
            },
          },
        ],
      };

      mockPrismaService.user.findUnique.mockResolvedValue(userWithHouseholds);

      const result = await service.getMe('user-123');

      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('household');
      expect(result).toHaveProperty('memberships');
      expect(result.memberships).toHaveLength(1);
      expect(result.household).not.toBeNull();
      expect(result.household?.hasProperty).toBe(true);
    });

    it('should throw UnauthorizedException if user not found', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(service.getMe('non-existent')).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('validateUser', () => {
    it('should return user for valid payload', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.validateUser({
        sub: 'user-123',
        email: 'test@example.com',
        role: UserRole.HOMEOWNER,
      });

      expect(result).toEqual(mockUser);
    });

    it('should return null for invalid payload', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      const result = await service.validateUser({
        sub: 'non-existent',
        email: 'test@example.com',
        role: UserRole.HOMEOWNER,
      });

      expect(result).toBeNull();
    });
  });
});
