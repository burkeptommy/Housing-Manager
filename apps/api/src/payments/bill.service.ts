import { Injectable, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface CreateBillDto {
  name: string;
  description?: string;
  category: string;
  amount?: number;
  isVariableAmount?: boolean;
  frequency: string;
  dueDay?: number;
  seasonStart?: number;
  seasonEnd?: number;
  paymentMethod: string;
  paymentPortalUrl?: string;
  paymentEmail?: string;
  mailingAddress?: string;
  accountNumber?: string;
  autopayEnabled?: boolean;
  requiresApproval?: boolean;
  approvalThreshold?: number;
  priority?: string;
  vendorId?: string;
}

@Injectable()
export class BillService {
  private readonly logger = new Logger(BillService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Create a new bill
   */
  async createBill(householdId: string, data: CreateBillDto) {
    this.logger.log(`Creating bill "${data.name}" for household ${householdId}`);

    // Calculate next due date
    const nextDueDate = this.calculateNextDueDate(data.dueDay, data.frequency);

    // Determine if approval is required based on priority
    const requiresApproval = data.requiresApproval ??
      (data.priority === 'critical' || (data.amount && data.amount > 2000));

    const bill = await this.prisma.bill.create({
      data: {
        household: { connect: { id: householdId } },
        name: data.name,
        description: data.description,
        category: data.category,
        amount: data.amount,
        isVariableAmount: data.isVariableAmount ?? !data.amount,
        averageAmount: data.amount,
        lastKnownAmount: data.amount,
        frequency: data.frequency,
        dueDay: data.dueDay,
        seasonStart: data.seasonStart,
        seasonEnd: data.seasonEnd,
        nextDueDate,
        paymentMethod: data.paymentMethod,
        paymentPortalUrl: data.paymentPortalUrl,
        paymentEmail: data.paymentEmail,
        mailingAddress: data.mailingAddress,
        accountNumber: data.accountNumber,
        autopayEnabled: data.autopayEnabled ?? true,
        requiresApproval,
        approvalThreshold: data.approvalThreshold,
        priority: data.priority ?? 'normal',
        vendor: data.vendorId ? { connect: { id: data.vendorId } } : undefined,
        sourceType: 'manual',
      },
      include: {
        vendor: true,
      },
    });

    this.logger.log(`Created bill ${bill.id} - ${bill.name}`);
    return bill;
  }

  /**
   * Create bill from detected bill (Plaid)
   */
  async createBillFromDetected(
    householdId: string,
    detectedBillId: string,
    paymentMethod: string,
    paymentDetails: {
      paymentEmail?: string;
      mailingAddress?: string;
      paymentPortalUrl?: string;
    },
  ) {
    const detected = await this.prisma.detectedBill.findUnique({
      where: { id: detectedBillId },
    });

    if (!detected) {
      throw new NotFoundException('Detected bill not found');
    }

    // Map DetectedBill category to Bill category
    const categoryMap: Record<string, string> = {
      'ELECTRIC': 'utility',
      'GAS': 'utility',
      'WATER_SEWER': 'utility',
      'INTERNET': 'utility',
      'CELL_PHONE': 'utility',
      'HOME_INSURANCE': 'insurance',
      'AUTO_INSURANCE': 'insurance',
      'MORTGAGE': 'mortgage',
      'STREAMING_SERVICE': 'subscription',
      'SOFTWARE_SUBSCRIPTION': 'subscription',
      'GYM_FITNESS': 'subscription',
      'HOA': 'other',
      'PROPERTY_TAX': 'tax',
      'OTHER_BILL': 'other',
    };

    const bill = await this.createBill(householdId, {
      name: detected.merchantName,
      category: categoryMap[detected.category] || 'other',
      amount: detected.averageAmount,
      isVariableAmount: true, // Assume variable since detected from transactions
      frequency: detected.frequency.toLowerCase(),
      dueDay: detected.dayOfMonth || undefined,
      paymentMethod,
      ...paymentDetails,
    });

    // Update detected bill status
    await this.prisma.detectedBill.update({
      where: { id: detectedBillId },
      data: { status: 'CONFIRMED' },
    });

    // Link the detected bill
    await this.prisma.bill.update({
      where: { id: bill.id },
      data: {
        sourceType: 'plaid_detected',
        detectedBillId,
      },
    });

    return bill;
  }

  /**
   * Get all bills for a household
   */
  async getBills(householdId: string, status?: string) {
    const where: any = { householdId };
    if (status) where.status = status;

    return this.prisma.bill.findMany({
      where,
      include: {
        vendor: true,
        payments: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
      orderBy: [
        { nextDueDate: 'asc' },
        { priority: 'desc' },
      ],
    });
  }

  /**
   * Get upcoming bills (due within N days)
   */
  async getUpcomingBills(householdId: string, days: number = 7) {
    const now = new Date();
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + days);

    return this.prisma.bill.findMany({
      where: {
        householdId,
        status: 'active',
        autopayEnabled: true,
        nextDueDate: {
          gte: now,
          lte: futureDate,
        },
      },
      include: {
        vendor: true,
      },
      orderBy: { nextDueDate: 'asc' },
    });
  }

  /**
   * Get bills due for payment (considering daysBeforeDue)
   */
  async getBillsDueForPayment() {
    const now = new Date();

    // Find bills where: nextDueDate - daysBeforeDue <= now
    // i.e., we should pay today or earlier
    const bills = await this.prisma.bill.findMany({
      where: {
        status: 'active',
        autopayEnabled: true,
        nextDueDate: { not: null },
      },
      include: {
        household: {
          include: { card: true },
        },
        vendor: true,
        payments: {
          where: {
            status: { in: ['pending', 'processing', 'completed'] },
            scheduledDate: {
              gte: new Date(now.getFullYear(), now.getMonth(), 1), // This month
            },
          },
        },
      },
    });

    // Filter to bills that need payment
    return bills.filter(bill => {
      // Skip if already has a payment this cycle
      if (bill.payments.length > 0) return false;

      // Check if it's time to pay
      const payDate = new Date(bill.nextDueDate!);
      payDate.setDate(payDate.getDate() - bill.daysBeforeDue);

      return payDate <= now;
    });
  }

  /**
   * Update a bill
   */
  async updateBill(billId: string, householdId: string, data: Partial<CreateBillDto>) {
    // Verify ownership
    const bill = await this.prisma.bill.findFirst({
      where: { id: billId, householdId },
    });

    if (!bill) {
      throw new NotFoundException('Bill not found');
    }

    // Recalculate next due date if frequency or dueDay changed
    let nextDueDate = bill.nextDueDate;
    if (data.frequency || data.dueDay) {
      nextDueDate = this.calculateNextDueDate(
        data.dueDay ?? bill.dueDay ?? undefined,
        data.frequency ?? bill.frequency,
      );
    }

    return this.prisma.bill.update({
      where: { id: billId },
      data: {
        ...data,
        nextDueDate,
      },
      include: { vendor: true },
    });
  }

  /**
   * Pause/resume bill autopay
   */
  async toggleAutopay(billId: string, householdId: string, enabled: boolean) {
    const bill = await this.prisma.bill.findFirst({
      where: { id: billId, householdId },
    });

    if (!bill) {
      throw new NotFoundException('Bill not found');
    }

    return this.prisma.bill.update({
      where: { id: billId },
      data: { autopayEnabled: enabled },
    });
  }

  /**
   * Cancel/delete a bill
   */
  async cancelBill(billId: string, householdId: string) {
    const bill = await this.prisma.bill.findFirst({
      where: { id: billId, householdId },
    });

    if (!bill) {
      throw new NotFoundException('Bill not found');
    }

    return this.prisma.bill.update({
      where: { id: billId },
      data: { status: 'cancelled' },
    });
  }

  /**
   * Get bill summary for dashboard
   */
  async getBillSummary(householdId: string) {
    const bills = await this.prisma.bill.findMany({
      where: { householdId, status: 'active' },
    });

    const now = new Date();
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    // Calculate monthly total
    let monthlyTotal = 0;
    let dueThisMonth = 0;

    for (const bill of bills) {
      const monthlyAmount = this.getMonthlyAmount(bill);
      monthlyTotal += monthlyAmount;

      if (bill.nextDueDate && bill.nextDueDate <= endOfMonth) {
        dueThisMonth += bill.amount || bill.averageAmount || 0;
      }
    }

    // Get payments this month
    const payments = await this.prisma.billPayment.findMany({
      where: {
        householdId,
        status: 'completed',
        processedDate: {
          gte: new Date(now.getFullYear(), now.getMonth(), 1),
        },
      },
    });

    const paidThisMonth = payments.reduce((sum, p) => sum + p.amount, 0);

    return {
      totalBills: bills.length,
      monthlyTotal: Math.round(monthlyTotal * 100) / 100,
      dueThisMonth: Math.round(dueThisMonth * 100) / 100,
      paidThisMonth: Math.round(paidThisMonth * 100) / 100,
      remainingThisMonth: Math.round((dueThisMonth - paidThisMonth) * 100) / 100,
    };
  }

  /**
   * Advance bill to next due date after payment
   */
  async advanceToNextDueDate(billId: string) {
    const bill = await this.prisma.bill.findUnique({
      where: { id: billId },
    });

    if (!bill) return;

    const nextDueDate = this.calculateNextDueDate(
      bill.dueDay ?? undefined,
      bill.frequency,
      bill.nextDueDate ?? undefined,
    );

    await this.prisma.bill.update({
      where: { id: billId },
      data: { nextDueDate },
    });
  }

  /**
   * Calculate next due date based on frequency
   */
  private calculateNextDueDate(
    dueDay?: number,
    frequency?: string,
    afterDate?: Date,
  ): Date | null {
    if (!frequency) return null;

    const baseDate = afterDate ? new Date(afterDate) : new Date();
    const result = new Date(baseDate);

    switch (frequency.toLowerCase()) {
      case 'weekly':
        result.setDate(result.getDate() + 7);
        break;
      case 'biweekly':
        result.setDate(result.getDate() + 14);
        break;
      case 'monthly':
        result.setMonth(result.getMonth() + 1);
        if (dueDay) {
          result.setDate(Math.min(dueDay, this.getDaysInMonth(result)));
        }
        break;
      case 'quarterly':
        result.setMonth(result.getMonth() + 3);
        if (dueDay) {
          result.setDate(Math.min(dueDay, this.getDaysInMonth(result)));
        }
        break;
      case 'semi_annual':
        result.setMonth(result.getMonth() + 6);
        if (dueDay) {
          result.setDate(Math.min(dueDay, this.getDaysInMonth(result)));
        }
        break;
      case 'annual':
        result.setFullYear(result.getFullYear() + 1);
        if (dueDay) {
          result.setDate(Math.min(dueDay, this.getDaysInMonth(result)));
        }
        break;
      case 'one_time':
        return null; // No next date for one-time bills
      default:
        return null;
    }

    // If result is in the past, advance it
    const now = new Date();
    while (result <= now) {
      if (frequency === 'monthly') {
        result.setMonth(result.getMonth() + 1);
      } else if (frequency === 'weekly') {
        result.setDate(result.getDate() + 7);
      }
      // Add more as needed
    }

    return result;
  }

  private getDaysInMonth(date: Date): number {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
  }

  private getMonthlyAmount(bill: any): number {
    const amount = bill.amount || bill.averageAmount || 0;

    switch (bill.frequency?.toLowerCase()) {
      case 'weekly':
        return amount * 4.33;
      case 'biweekly':
        return amount * 2.17;
      case 'monthly':
        return amount;
      case 'quarterly':
        return amount / 3;
      case 'semi_annual':
        return amount / 6;
      case 'annual':
        return amount / 12;
      default:
        return amount;
    }
  }
}
