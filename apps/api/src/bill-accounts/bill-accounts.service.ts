import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { VendorCategory, BillingFrequency, PaymentResponsibility, Prisma } from '@prisma/client';

import { PrismaService } from '../prisma';

import {
  CreateBillAccountDto,
  UpdateBillAccountDto,
  BillAccountResponseDto,
} from './dto';

@Injectable()
export class BillAccountsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    userId: string,
    dto: CreateBillAccountDto,
  ): Promise<BillAccountResponseDto> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(dto.householdId, userId);

    // Verify vendor exists
    const vendor = await this.prisma.vendor.findFirst({
      where: {
        id: dto.vendorId,
        OR: [
          { householdId: dto.householdId },
          { householdId: null },  // Global vendors
        ],
      },
    });

    if (!vendor) {
      throw new BadRequestException('Vendor not found or not accessible');
    }

    // Verify payment method if provided
    if (dto.paymentMethodId) {
      const paymentMethod = await this.prisma.paymentMethod.findFirst({
        where: {
          id: dto.paymentMethodId,
          householdId: dto.householdId,
        },
      });

      if (!paymentMethod) {
        throw new BadRequestException('Payment method not found');
      }
    }

    const billAccount = await this.prisma.billAccount.create({
      data: {
        householdId: dto.householdId,
        vendorId: dto.vendorId,
        paymentMethodId: dto.paymentMethodId,
        nickname: dto.nickname,
        category: dto.category,
        accountNumber: dto.accountNumber,
        billingFrequency: dto.billingFrequency ?? BillingFrequency.MONTHLY,
        paymentResponsibility: dto.paymentResponsibility ?? PaymentResponsibility.OWNER_PAYS_DIRECT,
        typicalAmount: dto.typicalAmount,
        nextDueDate: dto.nextDueDate ? new Date(dto.nextDueDate) : null,
        autopayEnabled: dto.autopayEnabled ?? false,
        portalUrl: dto.portalUrl,
        supportPhone: dto.supportPhone,
        notes: dto.notes,
      },
      include: {
        vendor: true,
      },
    });

    return this.mapToResponse(billAccount);
  }

  async findAll(
    userId: string,
    options: {
      householdId: string;
      category?: VendorCategory;
      upcomingDays?: number;
      includeInactive?: boolean;
    },
  ): Promise<BillAccountResponseDto[]> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(options.householdId, userId);

    const where: Prisma.BillAccountWhereInput = {
      householdId: options.householdId,
      deletedAt: null,  // Not soft-deleted
      ...(!options.includeInactive && { isActive: true }),
      ...(options.category && { category: options.category }),
    };

    // Filter by upcoming due date
    if (options.upcomingDays !== undefined) {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + options.upcomingDays);

      where.nextDueDate = {
        lte: futureDate,
        gte: new Date(),
      };
    }

    const billAccounts = await this.prisma.billAccount.findMany({
      where,
      include: {
        vendor: true,
      },
      orderBy: [
        { nextDueDate: 'asc' },
        { category: 'asc' },
        { nickname: 'asc' },
      ],
    });

    return billAccounts.map(this.mapToResponse);
  }

  async findOne(
    id: string,
    userId: string,
  ): Promise<BillAccountResponseDto> {
    const billAccount = await this.prisma.billAccount.findUnique({
      where: { id },
      include: {
        vendor: true,
      },
    });

    if (!billAccount || billAccount.deletedAt) {
      throw new NotFoundException(`Bill account with ID ${id} not found`);
    }

    // Verify user has access to this household
    await this.verifyHouseholdAccess(billAccount.householdId, userId);

    return this.mapToResponse(billAccount);
  }

  async update(
    id: string,
    userId: string,
    dto: UpdateBillAccountDto,
  ): Promise<BillAccountResponseDto> {
    const existing = await this.prisma.billAccount.findUnique({
      where: { id },
    });

    if (!existing || existing.deletedAt) {
      throw new NotFoundException(`Bill account with ID ${id} not found`);
    }

    // Verify user has access to this household
    await this.verifyHouseholdAccess(existing.householdId, userId);

    // Verify vendor if changing
    if (dto.vendorId) {
      const vendor = await this.prisma.vendor.findFirst({
        where: {
          id: dto.vendorId,
          OR: [
            { householdId: existing.householdId },
            { householdId: null },
          ],
        },
      });

      if (!vendor) {
        throw new BadRequestException('Vendor not found or not accessible');
      }
    }

    // Verify payment method if changing
    if (dto.paymentMethodId) {
      const paymentMethod = await this.prisma.paymentMethod.findFirst({
        where: {
          id: dto.paymentMethodId,
          householdId: existing.householdId,
        },
      });

      if (!paymentMethod) {
        throw new BadRequestException('Payment method not found');
      }
    }

    const billAccount = await this.prisma.billAccount.update({
      where: { id },
      data: {
        ...(dto.vendorId !== undefined && { vendorId: dto.vendorId }),
        ...(dto.paymentMethodId !== undefined && { paymentMethodId: dto.paymentMethodId }),
        ...(dto.nickname !== undefined && { nickname: dto.nickname }),
        ...(dto.category !== undefined && { category: dto.category }),
        ...(dto.accountNumber !== undefined && { accountNumber: dto.accountNumber }),
        ...(dto.billingFrequency !== undefined && { billingFrequency: dto.billingFrequency }),
        ...(dto.paymentResponsibility !== undefined && { paymentResponsibility: dto.paymentResponsibility }),
        ...(dto.typicalAmount !== undefined && { typicalAmount: dto.typicalAmount }),
        ...(dto.nextDueDate !== undefined && { nextDueDate: dto.nextDueDate ? new Date(dto.nextDueDate) : null }),
        ...(dto.autopayEnabled !== undefined && { autopayEnabled: dto.autopayEnabled }),
        ...(dto.portalUrl !== undefined && { portalUrl: dto.portalUrl }),
        ...(dto.supportPhone !== undefined && { supportPhone: dto.supportPhone }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
      include: {
        vendor: true,
      },
    });

    return this.mapToResponse(billAccount);
  }

  async remove(id: string, userId: string): Promise<void> {
    const existing = await this.prisma.billAccount.findUnique({
      where: { id },
    });

    if (!existing || existing.deletedAt) {
      throw new NotFoundException(`Bill account with ID ${id} not found`);
    }

    // Verify user has access to this household
    await this.verifyHouseholdAccess(existing.householdId, userId);

    // Soft delete
    await this.prisma.billAccount.update({
      where: { id },
      data: {
        deletedAt: new Date(),
        isActive: false,
      },
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

  private mapToResponse(billAccount: {
    id: string;
    householdId: string;
    vendorId: string;
    paymentMethodId: string | null;
    nickname: string;
    category: VendorCategory;
    accountNumber: string | null;
    billingFrequency: BillingFrequency;
    paymentResponsibility: PaymentResponsibility;
    typicalAmount: Prisma.Decimal | null;
    nextDueDate: Date | null;
    autopayEnabled: boolean;
    portalUrl: string | null;
    supportPhone: string | null;
    notes: string | null;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    vendor?: {
      id: string;
      displayName: string;
      category: VendorCategory;
    };
  }): BillAccountResponseDto {
    return {
      id: billAccount.id,
      householdId: billAccount.householdId,
      vendorId: billAccount.vendorId,
      paymentMethodId: billAccount.paymentMethodId,
      nickname: billAccount.nickname,
      category: billAccount.category,
      accountNumber: billAccount.accountNumber,
      billingFrequency: billAccount.billingFrequency,
      paymentResponsibility: billAccount.paymentResponsibility,
      typicalAmount: billAccount.typicalAmount ? Number(billAccount.typicalAmount) : null,
      nextDueDate: billAccount.nextDueDate,
      autopayEnabled: billAccount.autopayEnabled,
      portalUrl: billAccount.portalUrl,
      supportPhone: billAccount.supportPhone,
      notes: billAccount.notes,
      isActive: billAccount.isActive,
      createdAt: billAccount.createdAt,
      updatedAt: billAccount.updatedAt,
      vendor: billAccount.vendor ? {
        id: billAccount.vendor.id,
        displayName: billAccount.vendor.displayName,
        category: billAccount.vendor.category,
      } : undefined,
    };
  }
}
