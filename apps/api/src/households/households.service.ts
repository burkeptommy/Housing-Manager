import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { HouseholdRole, UserRole } from '@prisma/client';

import { PrismaService } from '../prisma';
import { UserContext, buildHouseholdAccessFilter } from '../common';

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

  /**
   * Find all households accessible to the user based on their role:
   * - ADMIN: All households
   * - MANAGER: Only households they manage
   * - HOMEOWNER: Households they own or are members of
   */
  async findAllByUserContext(userContext: UserContext): Promise<HouseholdListItemDto[]> {
    const accessFilter = buildHouseholdAccessFilter(userContext);

    // For MANAGER role, query households they manage directly
    if (userContext.role === UserRole.MANAGER) {
      const households = await this.prisma.household.findMany({
        where: accessFilter,
        include: {
          homeProfile: true,
          owner: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
              displayName: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      return households.map((household) => ({
        ...this.mapToDto(household),
        userRole: HouseholdRole.ADMIN, // Managers have admin-like access to their assigned households
        homeProfile: household.homeProfile
          ? this.mapHomeProfileSummary(household.homeProfile)
          : null,
      }));
    }

    // For ADMIN role, return all households
    if (userContext.role === UserRole.ADMIN) {
      const households = await this.prisma.household.findMany({
        include: {
          homeProfile: true,
          owner: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
              displayName: true,
            },
          },
          manager: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
              displayName: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      return households.map((household) => ({
        ...this.mapToDto(household),
        userRole: HouseholdRole.OWNER, // Admin has full access
        homeProfile: household.homeProfile
          ? this.mapHomeProfileSummary(household.homeProfile)
          : null,
      }));
    }

    // For HOMEOWNER, use the original membership-based query
    return this.findAllForUser(userContext.userId);
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

  /**
   * Update household using user context for permission checking
   * - ADMIN: Can update any household
   * - MANAGER: Can update households they manage
   * - HOMEOWNER: Can update households they own
   */
  async updateByContext(
    id: string,
    userContext: UserContext,
    dto: UpdateHouseholdDto,
  ): Promise<HouseholdDto> {
    const household = await this.prisma.household.findUnique({
      where: { id },
    });

    if (!household) {
      throw new NotFoundException(`Household with ID ${id} not found`);
    }

    // ADMIN can update any household
    if (userContext.role === UserRole.ADMIN) {
      const updated = await this.prisma.household.update({
        where: { id },
        data: {
          ...(dto.name && { name: dto.name }),
          ...(dto.description !== undefined && { description: dto.description }),
        },
      });
      return this.mapToDto(updated);
    }

    // MANAGER can update households they manage
    if (userContext.role === UserRole.MANAGER) {
      if (household.managerId !== userContext.userId) {
        throw new ForbiddenException('You are not the assigned manager of this household');
      }
      const updated = await this.prisma.household.update({
        where: { id },
        data: {
          ...(dto.name && { name: dto.name }),
          ...(dto.description !== undefined && { description: dto.description }),
        },
      });
      return this.mapToDto(updated);
    }

    // HOMEOWNER can only update if they're the owner
    if (household.ownerId !== userContext.userId) {
      throw new ForbiddenException('Only the household owner can update settings');
    }

    const updated = await this.prisma.household.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.description !== undefined && { description: dto.description }),
      },
    });

    return this.mapToDto(updated);
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

  // ===========================================================================
  // ZONE METHODS
  // ===========================================================================

  async getZones(householdId: string) {
    const zones = await this.prisma.zone.findMany({
      where: { householdId },
      include: {
        _count: {
          select: { assets: true },
        },
      },
      orderBy: { sortOrder: 'asc' },
    });

    return zones.map((zone) => ({
      id: zone.id,
      name: zone.name,
      type: zone.type,
      floor: zone.floor,
      photos: zone.photos,
      notes: zone.notes,
      procedures: zone.procedures,
      assetCount: zone._count.assets,
    }));
  }

  async createZone(
    householdId: string,
    data: { name: string; type: string; floor?: string },
  ) {
    // Get max sort order
    const maxOrder = await this.prisma.zone.aggregate({
      where: { householdId },
      _max: { sortOrder: true },
    });

    const zone = await this.prisma.zone.create({
      data: {
        householdId,
        name: data.name,
        type: data.type as any,
        floor: data.floor,
        sortOrder: (maxOrder._max.sortOrder || 0) + 1,
      },
      include: {
        _count: {
          select: { assets: true },
        },
      },
    });

    return {
      id: zone.id,
      name: zone.name,
      type: zone.type,
      floor: zone.floor,
      photos: zone.photos,
      notes: zone.notes,
      procedures: zone.procedures,
      assetCount: zone._count.assets,
    };
  }

  async updateZone(
    householdId: string,
    zoneId: string,
    data: { name?: string; floor?: string; notes?: string; procedures?: string },
  ) {
    const zone = await this.prisma.zone.update({
      where: { id: zoneId, householdId },
      data: {
        name: data.name,
        floor: data.floor,
        notes: data.notes,
        procedures: data.procedures,
      },
      include: {
        _count: {
          select: { assets: true },
        },
      },
    });

    return {
      id: zone.id,
      name: zone.name,
      type: zone.type,
      floor: zone.floor,
      photos: zone.photos,
      notes: zone.notes,
      procedures: zone.procedures,
      assetCount: zone._count.assets,
    };
  }

  async deleteZone(householdId: string, zoneId: string) {
    await this.prisma.zone.delete({
      where: { id: zoneId, householdId },
    });
  }

  // ===========================================================================
  // ASSET METHODS
  // ===========================================================================

  async getAssets(householdId: string) {
    const assets = await this.prisma.propertyAsset.findMany({
      where: { householdId, isActive: true },
      include: {
        zone: {
          select: { id: true, name: true, type: true },
        },
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return assets.map((asset) => ({
      id: asset.id,
      name: asset.name,
      category: asset.category,
      brand: asset.brand,
      model: asset.model,
      serialNumber: asset.serialNumber,
      condition: asset.condition,
      zoneId: asset.zoneId,
      zoneName: asset.zone?.name,
      serviceVendorId: asset.serviceVendorId,
      serviceVendorName: asset.serviceVendor?.displayName,
      lastServiceDate: asset.lastServiceDate?.toISOString(),
      nextServiceDate: asset.nextServiceDate?.toISOString(),
      photos: asset.photos,
      notes: asset.notes,
    }));
  }

  async createAsset(
    householdId: string,
    data: {
      name: string;
      category: string;
      zoneId?: string;
      brand?: string;
      model?: string;
      serialNumber?: string;
      condition?: string;
    },
  ) {
    const asset = await this.prisma.propertyAsset.create({
      data: {
        householdId,
        name: data.name,
        category: data.category as any,
        zoneId: data.zoneId,
        brand: data.brand,
        model: data.model,
        serialNumber: data.serialNumber,
        condition: data.condition,
      },
      include: {
        zone: {
          select: { id: true, name: true, type: true },
        },
      },
    });

    return {
      id: asset.id,
      name: asset.name,
      category: asset.category,
      brand: asset.brand,
      model: asset.model,
      serialNumber: asset.serialNumber,
      condition: asset.condition,
      zoneId: asset.zoneId,
      zoneName: asset.zone?.name,
    };
  }

  async updateAsset(
    householdId: string,
    assetId: string,
    data: {
      name?: string;
      brand?: string;
      model?: string;
      condition?: string;
      notes?: string;
      serviceVendorId?: string;
    },
  ) {
    const asset = await this.prisma.propertyAsset.update({
      where: { id: assetId, householdId },
      data: {
        name: data.name,
        brand: data.brand,
        model: data.model,
        condition: data.condition,
        notes: data.notes,
        serviceVendorId: data.serviceVendorId,
      },
      include: {
        zone: {
          select: { id: true, name: true, type: true },
        },
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
    });

    return {
      id: asset.id,
      name: asset.name,
      category: asset.category,
      brand: asset.brand,
      model: asset.model,
      condition: asset.condition,
      zoneId: asset.zoneId,
      zoneName: asset.zone?.name,
      serviceVendorId: asset.serviceVendorId,
      serviceVendorName: asset.serviceVendor?.displayName,
    };
  }

  async deleteAsset(householdId: string, assetId: string) {
    await this.prisma.propertyAsset.update({
      where: { id: assetId, householdId },
      data: { isActive: false },
    });
  }
}
