import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { HouseholdRole } from '@prisma/client';

import { PrismaService } from '../prisma';

import {
  CreateHouseholdDto,
  UpdateHouseholdDto,
  HouseholdDto,
  HouseholdDetailDto,
  HouseholdListItemDto,
  HouseholdMemberDto,
  HomeProfileSummaryDto,
  VendorSummaryDto,
} from './dto';

@Injectable()
export class HouseholdsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateHouseholdDto): Promise<HouseholdDto> {
    const household = await this.prisma.household.create({
      data: {
        name: dto.name,
        description: dto.description,
        ownerId: userId,
        members: {
          create: {
            userId,
            role: HouseholdRole.OWNER,
            status: 'ACTIVE',
            joinedAt: new Date(),
          },
        },
      },
    });

    return this.mapToDto(household);
  }

  async findAllForUser(userId: string): Promise<HouseholdListItemDto[]> {
    const memberships = await this.prisma.householdMember.findMany({
      where: {
        userId,
        status: 'ACTIVE',
      },
      include: {
        household: {
          include: {
            homeProfile: true,
          },
        },
      },
      orderBy: {
        household: { createdAt: 'desc' },
      },
    });

    return memberships.map((membership) => ({
      ...this.mapToDto(membership.household),
      userRole: membership.role,
      homeProfile: membership.household.homeProfile
        ? this.mapHomeProfileSummary(membership.household.homeProfile)
        : null,
    }));
  }

  async findById(id: string): Promise<HouseholdDetailDto> {
    const household = await this.prisma.household.findUnique({
      where: { id },
      include: {
        homeProfile: true,
        members: {
          where: { status: 'ACTIVE' },
          include: {
            user: true,
          },
          orderBy: { role: 'asc' },
        },
        vendors: {
          include: {
            vendor: {
              include: { serviceCategory: true },
            },
          },
          orderBy: { isFavorite: 'desc' },
        },
      },
    });

    if (!household) {
      throw new NotFoundException(`Household with ID ${id} not found`);
    }

    return {
      ...this.mapToDto(household),
      homeProfile: household.homeProfile
        ? this.mapHomeProfileSummary(household.homeProfile)
        : null,
      members: household.members.map((m) => this.mapMemberDto(m)),
      preferredVendors: household.vendors.map((v) => this.mapVendorSummary(v)),
    };
  }

  async update(
    id: string,
    userId: string,
    dto: UpdateHouseholdDto,
  ): Promise<HouseholdDto> {
    // Check if user has permission to update (owner or admin role in household)
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: { householdId: id, userId },
      },
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this household');
    }

    if (membership.role !== 'OWNER') {
      throw new ForbiddenException('Only household owners can update settings');
    }

    const household = await this.prisma.household.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.description !== undefined && { description: dto.description }),
      },
    });

    return this.mapToDto(household);
  }

  async delete(id: string, userId: string): Promise<void> {
    const household = await this.prisma.household.findUnique({
      where: { id },
    });

    if (!household) {
      throw new NotFoundException(`Household with ID ${id} not found`);
    }

    if (household.ownerId !== userId) {
      throw new ForbiddenException('Only the owner can delete a household');
    }

    await this.prisma.household.delete({ where: { id } });
  }

  // Helper methods
  private mapToDto(household: {
    id: string;
    name: string;
    description: string | null;
    ownerId: string;
    createdAt: Date;
    updatedAt: Date;
  }): HouseholdDto {
    return {
      id: household.id,
      name: household.name,
      description: household.description,
      ownerId: household.ownerId,
      createdAt: household.createdAt,
      updatedAt: household.updatedAt,
    };
  }

  private mapHomeProfileSummary(profile: {
    id: string;
    propertyType: string;
    addressLine1: string;
    city: string;
    state: string;
    postalCode: string;
  }): HomeProfileSummaryDto {
    return {
      id: profile.id,
      propertyType: profile.propertyType as HomeProfileSummaryDto['propertyType'],
      addressLine1: profile.addressLine1,
      city: profile.city,
      state: profile.state,
      postalCode: profile.postalCode,
    };
  }

  private mapMemberDto(membership: {
    id: string;
    userId: string;
    role: HouseholdRole;
    status: string;
    joinedAt: Date | null;
    user: {
      email: string;
      firstName: string;
      lastName: string;
    };
  }): HouseholdMemberDto {
    return {
      id: membership.id,
      userId: membership.userId,
      email: membership.user.email,
      firstName: membership.user.firstName,
      lastName: membership.user.lastName,
      role: membership.role,
      status: membership.status as HouseholdMemberDto['status'],
      joinedAt: membership.joinedAt,
    };
  }

  private mapVendorSummary(householdVendor: {
    isFavorite: boolean;
    vendor: {
      id: string;
      name: string;
      phone: string | null;
      email: string | null;
      serviceCategory: { name: string } | null;
    };
  }): VendorSummaryDto {
    return {
      id: householdVendor.vendor.id,
      name: householdVendor.vendor.name,
      phone: householdVendor.vendor.phone,
      email: householdVendor.vendor.email,
      categoryName: householdVendor.vendor.serviceCategory?.name ?? null,
      isFavorite: householdVendor.isFavorite,
    };
  }
}
