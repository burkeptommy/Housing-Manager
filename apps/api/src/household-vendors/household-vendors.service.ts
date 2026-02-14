import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { VendorCategory, VendorActivityType, ActorType, ActivityAction, ActivityCategory } from '@prisma/client';

import { PrismaService } from '../prisma';
import { ActivityService } from '../activity/activity.service';
import { getLogoUrlFromWebsite } from '../utils/logo-fetcher';

import {
  CreateVendorDto,
  UpdateVendorDto,
  VendorResponseDto,
  CreateActivityDto,
  ActivityResponseDto,
} from './dto';

@Injectable()
export class HouseholdVendorsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activityService: ActivityService,
  ) {}

  async create(
    householdId: string,
    userId: string,
    dto: CreateVendorDto,
  ): Promise<VendorResponseDto> {
    await this.verifyHouseholdAccess(householdId, userId);

    // Auto-fetch logo from website URL if not provided
    let logoUrl = dto.logoUrl;
    if (!logoUrl && dto.websiteUrl) {
      logoUrl = getLogoUrlFromWebsite(dto.websiteUrl);
    }

    // Create the vendor
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
        logoUrl,
        addressLine1: dto.addressLine1,
        addressLine2: dto.addressLine2,
        city: dto.city,
        state: dto.state,
        postalCode: dto.postalCode,
        notes: dto.notes,
      },
    });

    // Create the HouseholdVendor entry for CRM tracking
    const householdVendor = await this.prisma.householdVendor.create({
      data: {
        householdId,
        vendorId: vendor.id,
        source: 'manual',
      },
    });

    // Log activity
    try {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      await this.activityService.log({
        householdId,
        actorId: userId,
        actorType: ActorType.HOMEOWNER,
        actorName: user?.firstName || 'User',
        action: ActivityAction.VENDOR_ADDED,
        category: ActivityCategory.SERVICE,
        title: `New vendor added: ${dto.displayName}`,
        description: dto.category ? `Category: ${dto.category}` : undefined,
        vendorId: vendor.id,
        visibleToHomeowner: true,
      });
    } catch (error) {
      // Don't fail vendor creation if activity logging fails
      console.error('Failed to log vendor activity:', error);
    }

    return this.mapToResponseWithCrm(vendor, householdVendor);
  }

  async findAll(
    householdId: string,
    userId: string,
    options?: {
      category?: VendorCategory;
      favorite?: boolean;
      search?: string;
      includeInactive?: boolean;
    },
  ): Promise<VendorResponseDto[]> {
    await this.verifyHouseholdAccess(householdId, userId);

    // First get HouseholdVendor entries to filter by CRM fields
    const householdVendorWhere: any = { householdId };
    if (options?.favorite) {
      householdVendorWhere.isFavorite = true;
    }

    const householdVendors = await this.prisma.householdVendor.findMany({
      where: householdVendorWhere,
      include: {
        vendor: true,
        activities: {
          orderBy: { date: 'desc' },
          take: 3,
        },
      },
      orderBy: [
        { isFavorite: 'desc' },
        { lastContactDate: 'desc' },
      ],
    });

    // Filter by vendor properties
    let results = householdVendors.filter(hv => {
      if (!options?.includeInactive && !hv.vendor.isActive) return false;
      if (options?.category && hv.vendor.category !== options.category) return false;
      if (options?.search) {
        const searchLower = options.search.toLowerCase();
        return (
          hv.vendor.displayName.toLowerCase().includes(searchLower) ||
          hv.vendor.contactName?.toLowerCase().includes(searchLower) ||
          hv.vendor.notes?.toLowerCase().includes(searchLower)
        );
      }
      return true;
    });

    return results.map(hv => this.mapToResponseWithCrm(hv.vendor, hv, hv.activities));
  }

  async findOne(
    id: string,
    householdId: string,
    userId: string,
  ): Promise<VendorResponseDto> {
    await this.verifyHouseholdAccess(householdId, userId);

    const vendor = await this.prisma.vendor.findFirst({
      where: { id, householdId },
    });

    if (!vendor) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    // Get or create HouseholdVendor entry
    let householdVendor = await this.prisma.householdVendor.findUnique({
      where: {
        householdId_vendorId: { householdId, vendorId: id },
      },
      include: {
        activities: {
          orderBy: { date: 'desc' },
        },
      },
    });

    if (!householdVendor) {
      householdVendor = await this.prisma.householdVendor.create({
        data: {
          householdId,
          vendorId: id,
          source: 'legacy',
        },
        include: {
          activities: true,
        },
      });
    }

    // Get related bill accounts for this vendor
    const billAccounts = await this.prisma.billAccount.findMany({
      where: {
        householdId,
        vendorId: id,
        isActive: true,
      },
      orderBy: { nextDueDate: 'asc' },
      take: 10,
    });

    return this.mapToResponseWithCrm(vendor, householdVendor, householdVendor.activities, billAccounts);
  }

  async update(
    id: string,
    householdId: string,
    userId: string,
    dto: UpdateVendorDto,
  ): Promise<VendorResponseDto> {
    await this.verifyHouseholdAccess(householdId, userId);

    const existing = await this.prisma.vendor.findFirst({
      where: { id, householdId },
    });

    if (!existing) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    // Auto-fetch logo when websiteUrl changes (and logoUrl not explicitly set)
    let logoUrl: string | null | undefined = dto.logoUrl;
    if (logoUrl === undefined && dto.websiteUrl !== undefined && dto.websiteUrl !== existing.websiteUrl) {
      // Website URL changed, auto-fetch new logo
      logoUrl = getLogoUrlFromWebsite(dto.websiteUrl);
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
        ...(logoUrl !== undefined && { logoUrl }),
        ...(dto.addressLine1 !== undefined && { addressLine1: dto.addressLine1 }),
        ...(dto.addressLine2 !== undefined && { addressLine2: dto.addressLine2 }),
        ...(dto.city !== undefined && { city: dto.city }),
        ...(dto.state !== undefined && { state: dto.state }),
        ...(dto.postalCode !== undefined && { postalCode: dto.postalCode }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });

    const householdVendor = await this.getOrCreateHouseholdVendor(householdId, id);
    return this.mapToResponseWithCrm(vendor, householdVendor);
  }

  async remove(
    id: string,
    householdId: string,
    userId: string,
  ): Promise<void> {
    await this.verifyHouseholdAccess(householdId, userId);

    const existing = await this.prisma.vendor.findFirst({
      where: { id, householdId },
    });

    if (!existing) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    // Soft delete
    await this.prisma.vendor.update({
      where: { id },
      data: { isActive: false },
    });
  }

  // ========== CRM METHODS ==========

  async toggleFavorite(
    vendorId: string,
    householdId: string,
    userId: string,
  ): Promise<VendorResponseDto> {
    await this.verifyHouseholdAccess(householdId, userId);

    const vendor = await this.prisma.vendor.findFirst({
      where: { id: vendorId, householdId },
    });

    if (!vendor) {
      throw new NotFoundException(`Vendor with ID ${vendorId} not found`);
    }

    const householdVendor = await this.getOrCreateHouseholdVendor(householdId, vendorId);

    const updated = await this.prisma.householdVendor.update({
      where: { id: householdVendor.id },
      data: { isFavorite: !householdVendor.isFavorite },
      include: { activities: { orderBy: { date: 'desc' }, take: 3 } },
    });

    return this.mapToResponseWithCrm(vendor, updated, updated.activities);
  }

  async setRating(
    vendorId: string,
    householdId: string,
    userId: string,
    rating: number,
  ): Promise<VendorResponseDto> {
    await this.verifyHouseholdAccess(householdId, userId);

    if (rating < 1 || rating > 5) {
      throw new BadRequestException('Rating must be between 1 and 5');
    }

    const vendor = await this.prisma.vendor.findFirst({
      where: { id: vendorId, householdId },
    });

    if (!vendor) {
      throw new NotFoundException(`Vendor with ID ${vendorId} not found`);
    }

    const householdVendor = await this.getOrCreateHouseholdVendor(householdId, vendorId);

    const updated = await this.prisma.householdVendor.update({
      where: { id: householdVendor.id },
      data: { rating },
      include: { activities: { orderBy: { date: 'desc' }, take: 3 } },
    });

    return this.mapToResponseWithCrm(vendor, updated, updated.activities);
  }

  // ========== ACTIVITY METHODS ==========

  async getActivities(
    vendorId: string,
    householdId: string,
    userId: string,
  ): Promise<ActivityResponseDto[]> {
    await this.verifyHouseholdAccess(householdId, userId);

    const householdVendor = await this.prisma.householdVendor.findUnique({
      where: {
        householdId_vendorId: { householdId, vendorId },
      },
    });

    if (!householdVendor) {
      return [];
    }

    const activities = await this.prisma.vendorActivity.findMany({
      where: { householdVendorId: householdVendor.id },
      orderBy: { date: 'desc' },
    });

    return activities.map(this.mapActivity);
  }

  async addActivity(
    vendorId: string,
    householdId: string,
    userId: string,
    dto: CreateActivityDto,
  ): Promise<ActivityResponseDto> {
    await this.verifyHouseholdAccess(householdId, userId);

    const vendor = await this.prisma.vendor.findFirst({
      where: { id: vendorId, householdId },
    });

    if (!vendor) {
      throw new NotFoundException(`Vendor with ID ${vendorId} not found`);
    }

    const householdVendor = await this.getOrCreateHouseholdVendor(householdId, vendorId);

    // Create the activity
    const activity = await this.prisma.vendorActivity.create({
      data: {
        householdVendorId: householdVendor.id,
        type: dto.type,
        title: dto.title,
        description: dto.description,
        amount: dto.amount,
        isPaid: dto.isPaid ?? false,
        date: new Date(dto.date),
        duration: dto.duration,
        invoiceUrl: dto.invoiceUrl,
        receiptUrl: dto.receiptUrl,
        maintenanceTaskId: dto.maintenanceTaskId,
        serviceRequestId: dto.serviceRequestId,
        createdBy: userId,
      },
    });

    // Update lastContactDate on HouseholdVendor
    await this.prisma.householdVendor.update({
      where: { id: householdVendor.id },
      data: { lastContactDate: new Date() },
    });

    return this.mapActivity(activity);
  }

  async deleteActivity(
    activityId: string,
    vendorId: string,
    householdId: string,
    userId: string,
  ): Promise<void> {
    await this.verifyHouseholdAccess(householdId, userId);

    const householdVendor = await this.prisma.householdVendor.findUnique({
      where: {
        householdId_vendorId: { householdId, vendorId },
      },
    });

    if (!householdVendor) {
      throw new NotFoundException('Vendor not found');
    }

    const activity = await this.prisma.vendorActivity.findFirst({
      where: {
        id: activityId,
        householdVendorId: householdVendor.id,
      },
    });

    if (!activity) {
      throw new NotFoundException('Activity not found');
    }

    await this.prisma.vendorActivity.delete({
      where: { id: activityId },
    });
  }

  // ========== MESSAGE METHODS ==========

  async getMessages(
    householdVendorId: string,
    householdId: string,
    userId: string,
  ) {
    await this.verifyHouseholdAccess(householdId, userId);

    const messages = await this.prisma.vendorMessage.findMany({
      where: { householdVendorId },
      orderBy: { createdAt: 'asc' },
    });

    return messages;
  }

  async sendMessage(
    householdVendorId: string,
    householdId: string,
    userId: string,
    content: string,
  ) {
    await this.verifyHouseholdAccess(householdId, userId);

    // Update lastContactDate
    await this.prisma.householdVendor.update({
      where: { id: householdVendorId },
      data: { lastContactDate: new Date() },
    });

    // Create the message
    const message = await this.prisma.vendorMessage.create({
      data: {
        householdVendorId,
        direction: 'outgoing',
        content,
        status: 'sent',
      },
    });

    return message;
  }

  // ========== SEARCH/DIRECTORY ==========

  /**
   * Search for vendors in the directory (both household-specific and global).
   * Returns vendors the household already has, plus any global/shared vendors matching.
   */
  async searchDirectory(
    query?: string,
    category?: VendorCategory,
    householdId?: string,
    userId?: string,
  ) {
    if (householdId && userId) {
      await this.verifyHouseholdAccess(householdId, userId);
    }

    const where: any = {
      isActive: true,
    };

    if (category) {
      where.category = category;
    }

    if (query) {
      where.OR = [
        { displayName: { contains: query, mode: 'insensitive' } },
        { contactName: { contains: query, mode: 'insensitive' } },
        { serviceDescription: { contains: query, mode: 'insensitive' } },
      ];
    }

    // Search all vendors (both household-specific and global)
    const vendors = await this.prisma.vendor.findMany({
      where: {
        AND: [
          where,
          {
            OR: [
              // Vendors belonging to this household
              ...(householdId ? [{ householdId }] : []),
              // Global/shared vendors (no household)
              { householdId: null },
            ],
          },
        ],
      },
      take: 50,
      orderBy: { displayName: 'asc' },
    });

    // Check which are already linked to the household
    let linkedVendorIds: Set<string> = new Set();
    if (householdId) {
      const links = await this.prisma.householdVendor.findMany({
        where: { householdId },
        select: { vendorId: true },
      });
      linkedVendorIds = new Set(links.map(l => l.vendorId));
    }

    return vendors.map(v => ({
      ...this.mapToResponse(v),
      isLinked: linkedVendorIds.has(v.id),
    }));
  }

  // ========== HELPER METHODS ==========

  private async getOrCreateHouseholdVendor(householdId: string, vendorId: string) {
    let householdVendor = await this.prisma.householdVendor.findUnique({
      where: {
        householdId_vendorId: { householdId, vendorId },
      },
    });

    if (!householdVendor) {
      householdVendor = await this.prisma.householdVendor.create({
        data: {
          householdId,
          vendorId,
          source: 'legacy',
        },
      });
    }

    return householdVendor;
  }

  private async verifyHouseholdAccess(
    householdId: string,
    userId: string,
  ): Promise<void> {
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: { householdId, userId },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You do not have access to this household');
    }
  }

  private mapToResponse(vendor: any): VendorResponseDto {
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
      logoUrl: vendor.logoUrl,
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

  private mapToResponseWithCrm(
    vendor: any,
    householdVendor?: any,
    activities?: any[],
    billAccounts?: any[],
  ): VendorResponseDto {
    const base = this.mapToResponse(vendor);

    return {
      ...base,
      // CRM fields from HouseholdVendor
      isFavorite: householdVendor?.isFavorite ?? false,
      rating: householdVendor?.rating ?? null,
      tags: householdVendor?.tags ?? [],
      source: householdVendor?.source ?? null,
      lastContactDate: householdVendor?.lastContactDate ?? null,
      householdVendorId: householdVendor?.id,
      // Activities
      activities: activities?.map(this.mapActivity) ?? [],
      activityCount: activities?.length ?? 0,
      // Bill Accounts
      billAccounts: billAccounts?.map(this.mapBillAccount) ?? [],
    } as any;
  }

  private mapBillAccount(billAccount: any) {
    return {
      id: billAccount.id,
      nickname: billAccount.nickname,
      category: billAccount.category,
      accountNumber: billAccount.accountNumber,
      billingFrequency: billAccount.billingFrequency,
      typicalAmount: billAccount.typicalAmount ? Number(billAccount.typicalAmount) : null,
      nextDueDate: billAccount.nextDueDate,
      lastPaidDate: billAccount.lastPaidDate,
      lastPaidAmount: billAccount.lastPaidAmount ? Number(billAccount.lastPaidAmount) : null,
      paymentResponsibility: billAccount.paymentResponsibility,
    };
  }

  private mapActivity(activity: any): ActivityResponseDto {
    return {
      id: activity.id,
      householdVendorId: activity.householdVendorId,
      type: activity.type,
      title: activity.title,
      description: activity.description,
      amount: activity.amount,
      isPaid: activity.isPaid,
      date: activity.date,
      duration: activity.duration,
      invoiceUrl: activity.invoiceUrl,
      receiptUrl: activity.receiptUrl,
      maintenanceTaskId: activity.maintenanceTaskId,
      serviceRequestId: activity.serviceRequestId,
      createdBy: activity.createdBy,
      createdAt: activity.createdAt,
      updatedAt: activity.updatedAt,
    };
  }
}
