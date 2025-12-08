import { Injectable } from '@nestjs/common';
import {
  Prisma,
  Household,
  HouseholdMember,
  HouseholdRole,
  HouseholdMemberStatus,
  HomeProfile,
} from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type HouseholdWithMembers = Prisma.HouseholdGetPayload<{
  include: { members: { include: { user: true } }; homeProfile: true };
}>;

export type HouseholdWithProfile = Prisma.HouseholdGetPayload<{
  include: { homeProfile: true };
}>;

@Injectable()
export class HouseholdRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.HouseholdCreateInput): Promise<Household> {
    return this.prisma.household.create({ data });
  }

  async createWithMember(
    data: Prisma.HouseholdCreateInput,
    userId: string
  ): Promise<HouseholdWithMembers> {
    return this.prisma.household.create({
      data: {
        ...data,
        members: {
          create: {
            userId,
            role: 'OWNER',
            status: 'ACTIVE',
            joinedAt: new Date(),
          },
        },
      },
      include: {
        members: { include: { user: true } },
        homeProfile: true,
      },
    });
  }

  async findById(id: string): Promise<Household | null> {
    return this.prisma.household.findUnique({ where: { id } });
  }

  async findByIdWithMembers(id: string): Promise<HouseholdWithMembers | null> {
    return this.prisma.household.findUnique({
      where: { id },
      include: {
        members: {
          include: { user: true },
          orderBy: { role: 'asc' },
        },
        homeProfile: true,
      },
    });
  }

  async findByUserId(
    userId: string,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<HouseholdWithProfile>> {
    const { page, pageSize } = params;

    const where: Prisma.HouseholdWhereInput = {
      members: {
        some: {
          userId,
          status: 'ACTIVE',
        },
      },
    };

    const [data, total] = await Promise.all([
      this.prisma.household.findMany({
        where,
        include: { homeProfile: true },
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.household.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async update(id: string, data: Prisma.HouseholdUpdateInput): Promise<Household> {
    return this.prisma.household.update({ where: { id }, data });
  }

  async delete(id: string): Promise<Household> {
    return this.prisma.household.delete({ where: { id } });
  }

  // Member operations
  async addMember(
    householdId: string,
    userId: string,
    role: HouseholdRole = 'MEMBER'
  ): Promise<HouseholdMember> {
    return this.prisma.householdMember.create({
      data: {
        householdId,
        userId,
        role,
        status: 'PENDING',
      },
    });
  }

  async updateMemberStatus(
    householdId: string,
    userId: string,
    status: HouseholdMemberStatus
  ): Promise<HouseholdMember> {
    return this.prisma.householdMember.update({
      where: {
        householdId_userId: { householdId, userId },
      },
      data: {
        status,
        joinedAt: status === 'ACTIVE' ? new Date() : undefined,
      },
    });
  }

  async updateMemberRole(
    householdId: string,
    userId: string,
    role: HouseholdRole
  ): Promise<HouseholdMember> {
    return this.prisma.householdMember.update({
      where: {
        householdId_userId: { householdId, userId },
      },
      data: { role },
    });
  }

  async removeMember(householdId: string, userId: string): Promise<HouseholdMember> {
    return this.prisma.householdMember.delete({
      where: {
        householdId_userId: { householdId, userId },
      },
    });
  }

  async isMember(householdId: string, userId: string): Promise<boolean> {
    const member = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: { householdId, userId },
      },
    });
    return member?.status === 'ACTIVE';
  }

  async getMemberRole(householdId: string, userId: string): Promise<HouseholdRole | null> {
    const member = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: { householdId, userId },
      },
    });
    return member?.role ?? null;
  }

  // Home Profile operations
  async createHomeProfile(data: Prisma.HomeProfileCreateInput): Promise<HomeProfile> {
    return this.prisma.homeProfile.create({ data });
  }

  async updateHomeProfile(
    householdId: string,
    data: Prisma.HomeProfileUpdateInput
  ): Promise<HomeProfile> {
    return this.prisma.homeProfile.update({
      where: { householdId },
      data,
    });
  }
}
