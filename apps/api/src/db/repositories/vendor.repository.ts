import { Injectable } from '@nestjs/common';
import { Prisma, Vendor, HouseholdVendor, ServiceCategory } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type VendorWithCategory = Prisma.VendorGetPayload<{
  include: { serviceCategory: true };
}>;

export interface VendorFilters {
  serviceCategoryId?: string;
  isVerified?: boolean;
  isActive?: boolean;
  search?: string;
  city?: string;
  state?: string;
}

@Injectable()
export class VendorRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.VendorCreateInput): Promise<Vendor> {
    return this.prisma.vendor.create({ data });
  }

  async findById(id: string): Promise<Vendor | null> {
    return this.prisma.vendor.findUnique({ where: { id } });
  }

  async findByIdWithCategory(id: string): Promise<VendorWithCategory | null> {
    return this.prisma.vendor.findUnique({
      where: { id },
      include: { serviceCategory: true },
    });
  }

  async findMany(
    filters: VendorFilters,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<VendorWithCategory>> {
    const { page, pageSize } = params;
    const { serviceCategoryId, isVerified, isActive, search, city, state } = filters;

    const where: Prisma.VendorWhereInput = {};

    if (serviceCategoryId) where.serviceCategoryId = serviceCategoryId;
    if (typeof isVerified === 'boolean') where.isVerified = isVerified;
    if (typeof isActive === 'boolean') where.isActive = isActive;
    if (city) where.city = { equals: city, mode: 'insensitive' };
    if (state) where.state = { equals: state, mode: 'insensitive' };

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.vendor.findMany({
        where,
        include: { serviceCategory: true },
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }, { name: 'asc' }],
      }),
      this.prisma.vendor.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async update(id: string, data: Prisma.VendorUpdateInput): Promise<Vendor> {
    return this.prisma.vendor.update({ where: { id }, data });
  }

  async delete(id: string): Promise<Vendor> {
    return this.prisma.vendor.delete({ where: { id } });
  }

  async updateRating(id: string, rating: number, reviewCount: number): Promise<Vendor> {
    return this.prisma.vendor.update({
      where: { id },
      data: { rating, reviewCount },
    });
  }

  // Household Vendor associations
  async addToHousehold(
    householdId: string,
    vendorId: string,
    notes?: string
  ): Promise<HouseholdVendor> {
    return this.prisma.householdVendor.create({
      data: { householdId, vendorId, notes },
    });
  }

  async removeFromHousehold(householdId: string, vendorId: string): Promise<HouseholdVendor> {
    return this.prisma.householdVendor.delete({
      where: {
        householdId_vendorId: { householdId, vendorId },
      },
    });
  }

  async findByHousehold(
    householdId: string,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<VendorWithCategory>> {
    const { page, pageSize } = params;

    const householdVendors = await this.prisma.householdVendor.findMany({
      where: { householdId },
      include: {
        vendor: { include: { serviceCategory: true } },
      },
      ...this.getPaginationParams({ page, pageSize }),
    });

    const total = await this.prisma.householdVendor.count({ where: { householdId } });
    const data = householdVendors.map((hv) => hv.vendor);

    return this.paginate(data, total, { page, pageSize });
  }

  async toggleFavorite(householdId: string, vendorId: string): Promise<HouseholdVendor> {
    const existing = await this.prisma.householdVendor.findUnique({
      where: {
        householdId_vendorId: { householdId, vendorId },
      },
    });

    if (!existing) {
      throw new Error('Vendor not associated with household');
    }

    return this.prisma.householdVendor.update({
      where: {
        householdId_vendorId: { householdId, vendorId },
      },
      data: { isFavorite: !existing.isFavorite },
    });
  }

  // Service Categories
  async findAllCategories(): Promise<ServiceCategory[]> {
    return this.prisma.serviceCategory.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async createCategory(data: Prisma.ServiceCategoryCreateInput): Promise<ServiceCategory> {
    return this.prisma.serviceCategory.create({ data });
  }

  async updateCategory(
    id: string,
    data: Prisma.ServiceCategoryUpdateInput
  ): Promise<ServiceCategory> {
    return this.prisma.serviceCategory.update({ where: { id }, data });
  }
}
