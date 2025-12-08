import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { VendorCategory } from '@prisma/client';

import { PrismaService } from '../prisma';

import { CreateVendorDto, UpdateVendorDto, VendorResponseDto } from './dto';

@Injectable()
export class HouseholdVendorsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    householdId: string,
    userId: string,
    dto: CreateVendorDto,
  ): Promise<VendorResponseDto> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(householdId, userId);

    const vendor = await this.prisma.vendor.create({
      data: {
        householdId,
        displayName: dto.displayName,
        category: dto.category,
        serviceDescription: dto.serviceDescription,
        isLocal: dto.isLocal ?? true,
        contactName: dto.contactName,
        phone: dto.phone,
        email: dto.email,
        websiteUrl: dto.websiteUrl,
        addressLine1: dto.addressLine1,
        addressLine2: dto.addressLine2,
        city: dto.city,
        state: dto.state,
        postalCode: dto.postalCode,
        notes: dto.notes,
      },
    });

    return this.mapToResponse(vendor);
  }

  async findAll(
    householdId: string,
    userId: string,
    options?: {
      category?: VendorCategory;
      includeInactive?: boolean;
    },
  ): Promise<VendorResponseDto[]> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(householdId, userId);

    const vendors = await this.prisma.vendor.findMany({
      where: {
        householdId,
        ...(options?.category && { category: options.category }),
        ...(!options?.includeInactive && { isActive: true }),
      },
      orderBy: [
        { category: 'asc' },
        { displayName: 'asc' },
      ],
    });

    return vendors.map(this.mapToResponse);
  }

  async findOne(
    id: string,
    householdId: string,
    userId: string,
  ): Promise<VendorResponseDto> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(householdId, userId);

    const vendor = await this.prisma.vendor.findFirst({
      where: {
        id,
        householdId,
      },
    });

    if (!vendor) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    return this.mapToResponse(vendor);
  }

  async update(
    id: string,
    householdId: string,
    userId: string,
    dto: UpdateVendorDto,
  ): Promise<VendorResponseDto> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(householdId, userId);

    // Verify vendor exists and belongs to household
    const existing = await this.prisma.vendor.findFirst({
      where: {
        id,
        householdId,
      },
    });

    if (!existing) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    const vendor = await this.prisma.vendor.update({
      where: { id },
      data: {
        ...(dto.displayName !== undefined && { displayName: dto.displayName }),
        ...(dto.category !== undefined && { category: dto.category }),
        ...(dto.serviceDescription !== undefined && { serviceDescription: dto.serviceDescription }),
        ...(dto.isLocal !== undefined && { isLocal: dto.isLocal }),
        ...(dto.contactName !== undefined && { contactName: dto.contactName }),
        ...(dto.phone !== undefined && { phone: dto.phone }),
        ...(dto.email !== undefined && { email: dto.email }),
        ...(dto.websiteUrl !== undefined && { websiteUrl: dto.websiteUrl }),
        ...(dto.addressLine1 !== undefined && { addressLine1: dto.addressLine1 }),
        ...(dto.addressLine2 !== undefined && { addressLine2: dto.addressLine2 }),
        ...(dto.city !== undefined && { city: dto.city }),
        ...(dto.state !== undefined && { state: dto.state }),
        ...(dto.postalCode !== undefined && { postalCode: dto.postalCode }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });

    return this.mapToResponse(vendor);
  }

  async remove(
    id: string,
    householdId: string,
    userId: string,
  ): Promise<void> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(householdId, userId);

    // Verify vendor exists and belongs to household
    const existing = await this.prisma.vendor.findFirst({
      where: {
        id,
        householdId,
      },
    });

    if (!existing) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    // Soft delete - just mark as inactive
    await this.prisma.vendor.update({
      where: { id },
      data: { isActive: false },
    });
  }

  private async verifyHouseholdAccess(
    householdId: string,
    userId: string,
  ): Promise<void> {
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId,
          userId,
        },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You do not have access to this household');
    }
  }

  private mapToResponse(vendor: {
    id: string;
    householdId: string | null;
    displayName: string;
    category: VendorCategory;
    serviceDescription: string | null;
    isLocal: boolean;
    contactName: string | null;
    phone: string | null;
    email: string | null;
    websiteUrl: string | null;
    addressLine1: string | null;
    addressLine2: string | null;
    city: string | null;
    state: string | null;
    postalCode: string | null;
    notes: string | null;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): VendorResponseDto {
    return {
      id: vendor.id,
      householdId: vendor.householdId!,
      displayName: vendor.displayName,
      category: vendor.category,
      serviceDescription: vendor.serviceDescription,
      isLocal: vendor.isLocal,
      contactName: vendor.contactName,
      phone: vendor.phone,
      email: vendor.email,
      websiteUrl: vendor.websiteUrl,
      addressLine1: vendor.addressLine1,
      addressLine2: vendor.addressLine2,
      city: vendor.city,
      state: vendor.state,
      postalCode: vendor.postalCode,
      notes: vendor.notes,
      isActive: vendor.isActive,
      createdAt: vendor.createdAt,
      updatedAt: vendor.updatedAt,
    };
  }
}
