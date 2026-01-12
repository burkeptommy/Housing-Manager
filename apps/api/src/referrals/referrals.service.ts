import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReferralStatus, Prisma } from '@prisma/client';
import { CreateReferralDto, ReferralResponseDto, ReferralStatsDto } from './dto';
import { randomBytes } from 'crypto';

const REFERRAL_REWARD_AMOUNT = 50; // $50 per successful referral
const REFERRAL_EXPIRY_DAYS = 90;

@Injectable()
export class ReferralsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generate a unique referral code for a user
   */
  private generateReferralCode(): string {
    return randomBytes(4).toString('hex').toUpperCase();
  }

  /**
   * Get or create a user's referral code
   */
  async getOrCreateUserReferralCode(userId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { referralCode: true },
    });

    if (!user) throw new NotFoundException('User not found');

    if (user.referralCode) {
      return user.referralCode;
    }

    // Generate a unique code
    let code: string;
    let isUnique = false;
    while (!isUnique) {
      code = this.generateReferralCode();
      const existing = await this.prisma.user.findUnique({
        where: { referralCode: code },
      });
      isUnique = !existing;
    }

    // Save the code
    await this.prisma.user.update({
      where: { id: userId },
      data: { referralCode: code! },
    });

    return code!;
  }

  /**
   * Create a new referral
   */
  async createReferral(
    userId: string,
    dto: CreateReferralDto,
  ): Promise<ReferralResponseDto> {
    const userCode = await this.getOrCreateUserReferralCode(userId);

    // If email provided, check if already referred
    if (dto.email) {
      const existingReferral = await this.prisma.referral.findFirst({
        where: {
          refereeEmail: dto.email,
          status: { not: ReferralStatus.EXPIRED },
        },
      });

      if (existingReferral) {
        throw new BadRequestException('This email has already been referred');
      }

      // Check if user already exists
      const existingUser = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });

      if (existingUser) {
        throw new BadRequestException('This person is already a Haven user');
      }
    }

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + REFERRAL_EXPIRY_DAYS);

    // Generate a unique referral code for this specific referral
    const referralCode = `${userCode}-${randomBytes(3).toString('hex').toUpperCase()}`;

    const referral = await this.prisma.referral.create({
      data: {
        referrerId: userId,
        referralCode,
        refereeEmail: dto.email,
        expiresAt,
      },
      include: {
        referee: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });

    return this.mapToResponse(referral);
  }

  /**
   * Get all referrals for a user
   */
  async getUserReferrals(userId: string): Promise<ReferralResponseDto[]> {
    const referrals = await this.prisma.referral.findMany({
      where: { referrerId: userId },
      include: {
        referee: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return referrals.map(this.mapToResponse);
  }

  /**
   * Get referral statistics for a user
   */
  async getUserReferralStats(userId: string): Promise<ReferralStatsDto> {
    const userCode = await this.getOrCreateUserReferralCode(userId);

    const referrals = await this.prisma.referral.findMany({
      where: { referrerId: userId },
    });

    const stats = {
      totalReferrals: referrals.length,
      pendingReferrals: referrals.filter((r) => r.status === ReferralStatus.PENDING).length,
      signedUpReferrals: referrals.filter((r) => r.status === ReferralStatus.SIGNED_UP).length,
      convertedReferrals: referrals.filter((r) => r.status === ReferralStatus.CONVERTED).length,
      totalEarnings: referrals
        .filter((r) => r.rewardEarned)
        .reduce((sum, r) => sum + (r.rewardAmount ? Number(r.rewardAmount) : 0), 0),
      pendingEarnings: referrals
        .filter((r) => r.status === ReferralStatus.CONVERTED && !r.rewardPaidAt)
        .reduce((sum, r) => sum + (r.rewardAmount ? Number(r.rewardAmount) : 0), 0),
      referralCode: userCode,
      shareUrl: `https://havenhome.dev/r/${userCode}`,
    };

    return stats;
  }

  /**
   * Apply a referral code when a new user signs up
   */
  async applyReferralCode(
    newUserId: string,
    referralCode: string,
  ): Promise<void> {
    // Find the referral or user with this code
    const referral = await this.prisma.referral.findUnique({
      where: { referralCode },
    });

    if (referral) {
      if (referral.status !== ReferralStatus.PENDING) {
        throw new BadRequestException('This referral code has already been used');
      }

      if (new Date() > referral.expiresAt) {
        await this.prisma.referral.update({
          where: { id: referral.id },
          data: { status: ReferralStatus.EXPIRED },
        });
        throw new BadRequestException('This referral code has expired');
      }

      await this.prisma.referral.update({
        where: { id: referral.id },
        data: {
          refereeId: newUserId,
          status: ReferralStatus.SIGNED_UP,
          signedUpAt: new Date(),
        },
      });
      return;
    }

    // Check if it's a user's base referral code
    const referrer = await this.prisma.user.findUnique({
      where: { referralCode },
    });

    if (!referrer) {
      throw new BadRequestException('Invalid referral code');
    }

    // Create a new referral record
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + REFERRAL_EXPIRY_DAYS);

    await this.prisma.referral.create({
      data: {
        referrerId: referrer.id,
        referralCode: `${referralCode}-${randomBytes(3).toString('hex').toUpperCase()}`,
        refereeId: newUserId,
        status: ReferralStatus.SIGNED_UP,
        signedUpAt: new Date(),
        expiresAt,
      },
    });
  }

  /**
   * Mark a referral as converted (when referee subscribes)
   */
  async markReferralConverted(refereeId: string): Promise<void> {
    const referral = await this.prisma.referral.findFirst({
      where: {
        refereeId,
        status: ReferralStatus.SIGNED_UP,
      },
    });

    if (!referral) return;

    await this.prisma.referral.update({
      where: { id: referral.id },
      data: {
        status: ReferralStatus.CONVERTED,
        convertedAt: new Date(),
        rewardEarned: true,
        rewardAmount: REFERRAL_REWARD_AMOUNT,
      },
    });
  }

  /**
   * Get a referral by code
   */
  async getReferralByCode(code: string): Promise<ReferralResponseDto | null> {
    // First check if it's a specific referral code
    const referral = await this.prisma.referral.findUnique({
      where: { referralCode: code },
      include: {
        referee: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });

    if (referral) {
      return this.mapToResponse(referral);
    }

    // Check if it's a user's base referral code
    const user = await this.prisma.user.findUnique({
      where: { referralCode: code },
      select: { id: true, firstName: true, lastName: true },
    });

    if (user) {
      return {
        id: 'base',
        referralCode: code,
        refereeEmail: null,
        status: ReferralStatus.PENDING,
        rewardEarned: false,
        rewardAmount: null,
        signedUpAt: null,
        convertedAt: null,
        expiresAt: new Date(Date.now() + REFERRAL_EXPIRY_DAYS * 24 * 60 * 60 * 1000),
        createdAt: new Date(),
        referee: undefined,
      };
    }

    return null;
  }

  private mapToResponse(referral: {
    id: string;
    referralCode: string;
    refereeEmail: string | null;
    status: ReferralStatus;
    rewardEarned: boolean;
    rewardAmount: Prisma.Decimal | null;
    signedUpAt: Date | null;
    convertedAt: Date | null;
    expiresAt: Date;
    createdAt: Date;
    referee?: { id: string; firstName: string | null; lastName: string | null } | null;
  }): ReferralResponseDto {
    return {
      id: referral.id,
      referralCode: referral.referralCode,
      refereeEmail: referral.refereeEmail,
      status: referral.status,
      rewardEarned: referral.rewardEarned,
      rewardAmount: referral.rewardAmount ? Number(referral.rewardAmount) : null,
      signedUpAt: referral.signedUpAt,
      convertedAt: referral.convertedAt,
      expiresAt: referral.expiresAt,
      createdAt: referral.createdAt,
      referee: referral.referee || undefined,
    };
  }
}
