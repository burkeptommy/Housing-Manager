import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
  Inject,
  forwardRef,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';

import { PrismaService } from '../prisma';
import { PropertyEnrichmentService } from '../property/property-enrichment.service';
import { generateUniqueAlfredEmailCode } from '../alfred-email/utils';

import {
  RegisterDto,
  RegisterSimpleDto,
  RegisterSocialDto,
  LoginDto,
  AuthResponseDto,
  TokenResponseDto,
  UserResponseDto,
  MeResponseDto,
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
  private readonly logger = new Logger(AuthService.name);
  private readonly saltRounds = 12;
  private readonly accessTokenExpiresIn: number;
  private readonly refreshTokenExpiresInDays: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(forwardRef(() => PropertyEnrichmentService))
    private readonly enrichmentService: PropertyEnrichmentService,
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

  /**
   * Simplified registration for Alfred-first flow
   * Creates user, household, home profile with address, and triggers enrichment
   */
  async registerSimple(
    dto: RegisterSimpleDto,
    userAgent?: string,
    ipAddress?: string,
  ): Promise<{ user: UserResponseDto; householdId: string; message: string }> {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (existingUser) {
      throw new ConflictException('A user with this email already exists');
    }

    const passwordHash = await this.hashPassword(dto.password);

    // Generate Alfred email code from address
    const alfredEmailCode = dto.address.addressLine1
      ? await generateUniqueAlfredEmailCode(this.prisma, dto.address.addressLine1)
      : null;

    // Create user, household, home profile in a transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Create user
      const user = await tx.user.create({
        data: {
          email: dto.email.toLowerCase(),
          passwordHash,
          firstName: dto.firstName,
          lastName: dto.lastName,
          role: UserRole.HOMEOWNER,
        },
      });

      // 2. Create household with Alfred email code
      const household = await tx.household.create({
        data: {
          name: `The ${dto.lastName} Family`,
          ownerId: user.id,
          subscriptionPlan: 'ESSENTIALS',
          subscriptionStatus: 'ACTIVE',
          alfredEmailCode,
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

      // 3. Create home profile with address
      await tx.homeProfile.create({
        data: {
          householdId: household.id,
          addressLine1: dto.address.addressLine1,
          addressLine2: dto.address.addressLine2,
          city: dto.address.city,
          state: dto.address.state,
          postalCode: dto.address.zipCode,
        },
      });

      // 4. Create family member entry for the owner
      await tx.familyMember.create({
        data: {
          householdId: household.id,
          firstName: dto.firstName,
          lastName: dto.lastName,
          email: dto.email.toLowerCase(),
          relationship: 'Owner',
          type: 'ADULT',
        },
      });

      return { user, household };
    });

    // 5. Trigger ATTOM enrichment in background (async - don't wait)
    this.enrichmentService
      .enrichHouseholdFromAttom(result.household.id, {})
      .catch((err) => {
        this.logger.error(`ATTOM enrichment failed for household ${result.household.id}:`, err);
      });

    return {
      user: this.mapUserToResponse(result.user),
      householdId: result.household.id,
      message: 'Account created successfully',
    };
  }

  /**
   * Social registration for Apple/Google Sign-In users
   * Creates user, household, home profile with address - no password needed
   * Firebase handles authentication, we just need to create our database records
   */
  async registerSocial(
    dto: RegisterSocialDto,
    userAgent?: string,
    ipAddress?: string,
  ): Promise<{ user: UserResponseDto; householdId: string; message: string }> {
    // Check if user already exists (may have been auto-created by FirebaseAuthGuard)
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
      include: {
        householdMembers: {
          where: { status: 'ACTIVE' },
        },
      },
    });

    // If user exists AND already has a household, they're already registered
    if (existingUser && existingUser.householdMembers.length > 0) {
      throw new ConflictException('A user with this email already exists and has a household');
    }

    // Generate Alfred email code from address
    const alfredEmailCode = dto.address.addressLine1
      ? await generateUniqueAlfredEmailCode(this.prisma, dto.address.addressLine1)
      : null;

    // Create household and home profile in a transaction
    // User may already exist (auto-created by FirebaseAuthGuard) or need to be created
    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Get or create user
      let userId: string;
      let userRecord: User;

      if (!existingUser) {
        // Create new user (no password hash for social auth)
        userRecord = await tx.user.create({
          data: {
            email: dto.email.toLowerCase(),
            passwordHash: '', // Empty - social auth via Firebase
            firstName: dto.firstName,
            lastName: dto.lastName,
            role: UserRole.HOMEOWNER,
            emailVerified: true, // Social providers verify email
          },
        });
        userId = userRecord.id;
      } else {
        userId = existingUser.id;
        // Update existing user with name if not set
        if (!existingUser.firstName || !existingUser.lastName) {
          userRecord = await tx.user.update({
            where: { id: existingUser.id },
            data: {
              firstName: dto.firstName || existingUser.firstName,
              lastName: dto.lastName || existingUser.lastName,
            },
          });
        } else {
          userRecord = existingUser;
        }
      }

      // 2. Create household with utility info from ATTOM and Alfred email code
      const household = await tx.household.create({
        data: {
          name: `The ${dto.lastName} Family`,
          ownerId: userId,
          subscriptionPlan: 'ESSENTIALS',
          subscriptionStatus: 'ACTIVE',
          alfredEmailCode,
          // Utility/system data from ATTOM (if available)
          waterSource: dto.propertyDetails?.waterType ?? undefined,
          sewerType: dto.propertyDetails?.sewerType ?? undefined,
          heatingFuel: dto.propertyDetails?.heatingFuel ?? undefined,
          attomDataFetched: dto.propertyDetails ? true : false,
          enrichmentData: dto.propertyDetails ? { ...dto.propertyDetails } : undefined,
          members: {
            create: {
              userId: userId,
              role: 'OWNER',
              status: 'ACTIVE',
              joinedAt: new Date(),
            },
          },
        },
      });

      // 3. Create home profile with address and property details from ATTOM
      await tx.homeProfile.create({
        data: {
          householdId: household.id,
          addressLine1: dto.address.addressLine1,
          addressLine2: dto.address.addressLine2,
          city: dto.address.city,
          state: dto.address.state,
          postalCode: dto.address.zipCode,
          // Property details from ATTOM (if available)
          bedrooms: dto.propertyDetails?.bedrooms ?? undefined,
          bathrooms: dto.propertyDetails?.bathrooms ?? undefined,
          squareFeet: dto.propertyDetails?.squareFeet ?? undefined,
          yearBuilt: dto.propertyDetails?.yearBuilt ?? undefined,
          stories: dto.propertyDetails?.stories ?? undefined,
          garageSpaces: dto.propertyDetails?.garageSpaces ?? undefined,
        },
      });

      // 4. Create family member entry for the owner
      await tx.familyMember.create({
        data: {
          householdId: household.id,
          firstName: dto.firstName,
          lastName: dto.lastName,
          email: dto.email.toLowerCase(),
          relationship: 'Owner',
          type: 'ADULT',
        },
      });

      return { user: userRecord, household };
    });

    // 5. Trigger ATTOM enrichment in background (async - don't wait)
    this.enrichmentService
      .enrichHouseholdFromAttom(result.household.id, {})
      .catch((err) => {
        this.logger.error(`ATTOM enrichment failed for household ${result.household.id}:`, err);
      });

    // 6. Initialize Alfred data gaps based on missing property info
    // Build list of what we don't have
    const dataGaps: string[] = [];
    const pd = dto.propertyDetails;
    if (!pd?.waterType) dataGaps.push('water_source');
    if (!pd?.sewerType) dataGaps.push('sewer_type');
    if (!pd?.heatingFuel) dataGaps.push('heating_fuel');
    if (!pd?.yearBuilt) dataGaps.push('year_built');
    if (!pd?.bedrooms) dataGaps.push('bedrooms');
    if (!pd?.bathrooms) dataGaps.push('bathrooms');
    if (!pd?.squareFeet) dataGaps.push('square_feet');
    if (pd?.garageSpaces === null || pd?.garageSpaces === undefined) dataGaps.push('garage');

    if (dataGaps.length > 0) {
      this.prisma.household
        .update({
          where: { id: result.household.id },
          data: { alfredDataGaps: dataGaps },
        })
        .catch((err) => {
          this.logger.error(`Failed to set Alfred data gaps for household ${result.household.id}:`, err);
        });
    }

    return {
      user: this.mapUserToResponse(result.user),
      householdId: result.household.id,
      message: 'Account created successfully',
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
          include: {
            household: {
              include: {
                homeProfile: {
                  select: {
                    id: true,
                    addressLine1: true,
                    city: true,
                    state: true,
                    postalCode: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Build memberships array
    const memberships = user.householdMembers.map((member) => ({
      householdId: member.household.id,
      householdName: member.household.name,
      role: member.role,
      status: member.status,
    }));

    // Get primary household (first active membership)
    const primaryMembership = user.householdMembers[0];
    let household = null;

    if (primaryMembership) {
      const h = primaryMembership.household;
      const homeProfile = h.homeProfile;
      const hasProperty = !!homeProfile;
      const propertyAddress = homeProfile
        ? `${homeProfile.addressLine1}, ${homeProfile.city}, ${homeProfile.state} ${homeProfile.postalCode}`
        : undefined;

      household = {
        id: h.id,
        name: h.name,
        description: h.description,
        subscriptionPlan: h.subscriptionPlan,
        subscriptionStatus: h.subscriptionStatus,
        billingCycleDay: h.billingCycleDay,
        role: primaryMembership.role,
        hasProperty,
        propertyAddress,
      };
    }

    return {
      user: this.mapUserToResponse(user),
      household,
      memberships,
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
