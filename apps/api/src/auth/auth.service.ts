import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';

import { PrismaService } from '../prisma';

import {
  RegisterDto,
  LoginDto,
  AuthResponseDto,
  TokenResponseDto,
  UserResponseDto,
  MeResponseDto,
  HouseholdResponseDto,
} from './dto';

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
  iat?: number;
  exp?: number;
}

@Injectable()
export class AuthService {
  private readonly saltRounds = 12;
  private readonly accessTokenExpiresIn: number;
  private readonly refreshTokenExpiresInDays: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {
    this.accessTokenExpiresIn = this.configService.get<number>('JWT_ACCESS_EXPIRES_IN', 900); // 15 min
    this.refreshTokenExpiresInDays = this.configService.get<number>('JWT_REFRESH_EXPIRES_DAYS', 7);
  }

  async register(dto: RegisterDto, userAgent?: string, ipAddress?: string): Promise<AuthResponseDto> {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (existingUser) {
      throw new ConflictException('A user with this email already exists');
    }

    const passwordHash = await this.hashPassword(dto.password);

    // Create user with a default household in a transaction
    const result = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: dto.email.toLowerCase(),
          passwordHash,
          firstName: dto.firstName,
          lastName: dto.lastName,
          phone: dto.phone,
          role: UserRole.HOMEOWNER,
        },
      });

      // Create default household for the user
      const household = await tx.household.create({
        data: {
          name: `${dto.firstName}'s Home`,
          ownerId: user.id,
          members: {
            create: {
              userId: user.id,
              role: 'OWNER',
              status: 'ACTIVE',
              joinedAt: new Date(),
            },
          },
        },
      });

      return { user, household };
    });

    const tokens = await this.generateTokens(result.user, userAgent, ipAddress);

    return {
      user: this.mapUserToResponse(result.user),
      ...tokens,
    };
  }

  async login(dto: LoginDto, userAgent?: string, ipAddress?: string): Promise<AuthResponseDto> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const isPasswordValid = await this.comparePasswords(dto.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // Update last login
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const tokens = await this.generateTokens(user, userAgent, ipAddress);

    return {
      user: this.mapUserToResponse(user),
      ...tokens,
    };
  }

  async refresh(refreshToken: string, userAgent?: string, ipAddress?: string): Promise<TokenResponseDto> {
    const storedToken = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!storedToken) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (storedToken.isRevoked) {
      // Potential token reuse attack - revoke all tokens for this user
      await this.revokeAllUserTokens(storedToken.userId);
      throw new UnauthorizedException('Refresh token has been revoked');
    }

    if (storedToken.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token has expired');
    }

    // Revoke the old refresh token (rotation)
    await this.prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { isRevoked: true },
    });

    // Generate new access token only (no refresh token rotation for simplicity)
    const accessToken = this.generateAccessToken(storedToken.user);

    return {
      accessToken,
      expiresIn: this.accessTokenExpiresIn,
    };
  }

  async logout(userId: string, refreshToken?: string): Promise<void> {
    if (refreshToken) {
      await this.prisma.refreshToken.updateMany({
        where: { userId, token: refreshToken },
        data: { isRevoked: true },
      });
    } else {
      await this.revokeAllUserTokens(userId);
    }
  }

  async getMe(userId: string): Promise<MeResponseDto> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        householdMembers: {
          where: { status: 'ACTIVE' },
          include: { household: true },
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const households: HouseholdResponseDto[] = user.householdMembers.map((member) => ({
      id: member.household.id,
      name: member.household.name,
      description: member.household.description,
      role: member.role,
    }));

    return {
      user: this.mapUserToResponse(user),
      households,
    };
  }

  async validateUser(payload: JwtPayload): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id: payload.sub },
    });
  }

  // Private methods

  private async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, this.saltRounds);
  }

  private async comparePasswords(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }

  private generateAccessToken(user: User): string {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    return this.jwtService.sign(payload, {
      expiresIn: this.accessTokenExpiresIn,
    });
  }

  private async generateRefreshToken(
    userId: string,
    userAgent?: string,
    ipAddress?: string,
  ): Promise<string> {
    const token = randomBytes(64).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + this.refreshTokenExpiresInDays);

    await this.prisma.refreshToken.create({
      data: {
        userId,
        token,
        expiresAt,
        userAgent,
        ipAddress,
      },
    });

    return token;
  }

  private async generateTokens(
    user: User,
    userAgent?: string,
    ipAddress?: string,
  ): Promise<{ accessToken: string; refreshToken: string; expiresIn: number }> {
    const accessToken = this.generateAccessToken(user);
    const refreshToken = await this.generateRefreshToken(user.id, userAgent, ipAddress);

    return {
      accessToken,
      refreshToken,
      expiresIn: this.accessTokenExpiresIn,
    };
  }

  private async revokeAllUserTokens(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, isRevoked: false },
      data: { isRevoked: true },
    });
  }

  private mapUserToResponse(user: User): UserResponseDto {
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      role: user.role,
      emailVerified: user.emailVerified,
      createdAt: user.createdAt,
    };
  }
}
