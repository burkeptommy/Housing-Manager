import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateTravelProfileDto } from '../dto';

@Injectable()
export class TravelProfileService {
  private readonly logger = new Logger(TravelProfileService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get travel profile for a household member
   */
  async findByMemberId(memberId: string, householdId: string) {
    // Verify member belongs to household
    const member = await this.prisma.householdMember.findFirst({
      where: { id: memberId, householdId },
    });

    if (!member) {
      throw new NotFoundException('Member not found');
    }

    return this.prisma.travelProfile.findUnique({
      where: { householdMemberId: memberId },
    });
  }

  /**
   * Get or create travel profile for a member
   */
  async getOrCreate(memberId: string, householdId: string) {
    const member = await this.prisma.householdMember.findFirst({
      where: { id: memberId, householdId },
    });

    if (!member) {
      throw new NotFoundException('Member not found');
    }

    let profile = await this.prisma.travelProfile.findUnique({
      where: { householdMemberId: memberId },
    });

    if (!profile) {
      profile = await this.prisma.travelProfile.create({
        data: {
          householdMemberId: memberId,
        },
      });
    }

    return profile;
  }

  /**
   * Update travel profile
   */
  async update(memberId: string, householdId: string, dto: UpdateTravelProfileDto) {
    // Verify member belongs to household
    const member = await this.prisma.householdMember.findFirst({
      where: { id: memberId, householdId },
    });

    if (!member) {
      throw new NotFoundException('Member not found');
    }

    // Get or create profile
    let profile = await this.prisma.travelProfile.findUnique({
      where: { householdMemberId: memberId },
    });

    if (!profile) {
      profile = await this.prisma.travelProfile.create({
        data: {
          householdMemberId: memberId,
          ...dto,
        },
      });
    } else {
      profile = await this.prisma.travelProfile.update({
        where: { householdMemberId: memberId },
        data: dto,
      });
    }

    return profile;
  }

  /**
   * Get all travel profiles for a household (for trip planning)
   */
  async findAllByHousehold(householdId: string) {
    const members = await this.prisma.householdMember.findMany({
      where: { householdId, isActive: true },
      include: {
        travelProfile: true,
        user: {
          select: { id: true, displayName: true, email: true },
        },
      },
    });

    return members.map(m => ({
      memberId: m.id,
      displayName: m.displayName,
      nickname: m.nickname,
      user: m.user,
      travelProfile: m.travelProfile,
    }));
  }

  /**
   * Get my travel profile (current user's member profile in household)
   */
  async getMyProfile(userId: string, householdId: string) {
    const member = await this.prisma.householdMember.findFirst({
      where: { userId, householdId },
      include: {
        travelProfile: true,
      },
    });

    if (!member) {
      throw new NotFoundException('You are not a member of this household');
    }

    return {
      memberId: member.id,
      displayName: member.displayName,
      travelProfile: member.travelProfile,
    };
  }

  /**
   * Update my travel profile
   */
  async updateMyProfile(userId: string, householdId: string, dto: UpdateTravelProfileDto) {
    const member = await this.prisma.householdMember.findFirst({
      where: { userId, householdId },
    });

    if (!member) {
      throw new NotFoundException('You are not a member of this household');
    }

    return this.update(member.id, householdId, dto);
  }
}
