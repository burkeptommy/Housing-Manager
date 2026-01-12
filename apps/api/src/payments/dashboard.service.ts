import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BillService } from './bill.service';
import { CardService } from './card.service';

@Injectable()
export class DashboardService {
  private readonly logger = new Logger(DashboardService.name);

  constructor(
    private prisma: PrismaService,
    private billService: BillService,
    private cardService: CardService,
  ) {}

  /**
   * Get the main dashboard data
   */
  async getDashboard(householdId: string) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    // Get all active bills
    const bills = await this.prisma.bill.findMany({
      where: { householdId, status: 'active' },
      include: {
        vendor: {
          include: { vendor: true },
        },
        household: {
          include: { card: true },
        },
      },
      orderBy: { nextDueDate: 'asc' },
    });

    // Get payments this month
    const payments = await this.prisma.billPayment.findMany({
      where: {
        householdId,
        createdAt: { gte: startOfMonth, lte: endOfMonth },
      },
      include: { bill: { select: { name: true, category: true } } },
      orderBy: { createdAt: 'desc' },
    });

    // Get pending approvals
    const pendingApprovals = await this.prisma.paymentApproval.findMany({
      where: {
        householdId,
        status: 'pending',
        expiresAt: { gt: now },
      },
      include: { bill: { select: { name: true, category: true } } },
    });

    // Get card info
    const card = await this.cardService.getHouseholdCard(householdId);

    // Calculate totals
    const monthlyTotal = this.calculateMonthlyTotal(bills);
    const paidThisMonth = payments
      .filter(p => p.status === 'completed')
      .reduce((sum, p) => sum + p.amount, 0);
    const dueThisMonth = bills
      .filter(b => b.nextDueDate && b.nextDueDate <= endOfMonth)
      .reduce((sum, b) => sum + (b.amount || b.averageAmount || 0), 0);

    // Upcoming bills (next 7 days)
    const sevenDaysFromNow = new Date();
    sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

    const upcomingBills = bills
      .filter(b => b.nextDueDate && b.nextDueDate <= sevenDaysFromNow)
      .map(b => ({
        id: b.id,
        name: b.name,
        amount: b.amount || b.averageAmount,
        dueDate: b.nextDueDate,
        paymentMethod: b.paymentMethod,
        autopayEnabled: b.autopayEnabled,
        status: this.getBillStatus(b, payments),
      }));

    // Recent payments
    const recentPayments = payments.slice(0, 10).map(p => ({
      id: p.id,
      billName: p.bill?.name || 'Unknown',
      category: p.bill?.category,
      amount: p.amount,
      status: p.status,
      date: p.processedDate || p.createdAt,
      paymentMethod: p.paymentMethod,
    }));

    // Issues/alerts
    const alerts = await this.getAlerts(householdId, bills, payments);

    return {
      summary: {
        monthlyTotal: Math.round(monthlyTotal * 100) / 100,
        paidThisMonth: Math.round(paidThisMonth * 100) / 100,
        dueThisMonth: Math.round(dueThisMonth * 100) / 100,
        remainingThisMonth: Math.round((dueThisMonth - paidThisMonth) * 100) / 100,
        totalBills: bills.length,
        pendingApprovalsCount: pendingApprovals.length,
      },
      card: card ? {
        last4: card.last4,
        brand: card.brand,
        status: card.status,
        fundingStatus: card.fundingStatus,
      } : null,
      upcomingBills,
      recentPayments,
      pendingApprovals: pendingApprovals.map(a => ({
        id: a.id,
        billName: a.bill?.name,
        amount: a.amount,
        reason: a.reason,
        expiresAt: a.expiresAt,
      })),
      alerts,
      currentMonth: now.toLocaleString('default', { month: 'long', year: 'numeric' }),
    };
  }

  /**
   * Get all bills with detailed info
   */
  async getAllBills(householdId: string) {
    const bills = await this.prisma.bill.findMany({
      where: { householdId },
      include: {
        vendor: {
          include: { vendor: true },
        },
        payments: {
          orderBy: { createdAt: 'desc' },
          take: 3,
        },
      },
      orderBy: [
        { status: 'asc' }, // Active first
        { nextDueDate: 'asc' },
      ],
    });

    return bills.map(b => ({
      id: b.id,
      name: b.name,
      description: b.description,
      category: b.category,
      amount: b.amount,
      isVariableAmount: b.isVariableAmount,
      averageAmount: b.averageAmount,
      frequency: b.frequency,
      dueDay: b.dueDay,
      nextDueDate: b.nextDueDate,
      paymentMethod: b.paymentMethod,
      autopayEnabled: b.autopayEnabled,
      requiresApproval: b.requiresApproval,
      priority: b.priority,
      status: b.status,
      vendor: b.vendor ? {
        id: b.vendor.id,
        name: b.vendor.vendor?.displayName,
        phone: b.vendor.vendor?.phone,
      } : null,
      recentPayments: b.payments.map(p => ({
        amount: p.amount,
        status: p.status,
        date: p.processedDate || p.createdAt,
      })),
      lastPaymentDate: b.payments[0]?.processedDate,
      lastPaymentAmount: b.payments[0]?.amount,
    }));
  }

  /**
   * Get payment history with filtering
   */
  async getPaymentHistory(
    householdId: string,
    options: {
      startDate?: Date;
      endDate?: Date;
      status?: string;
      category?: string;
      limit?: number;
      offset?: number;
    } = {},
  ) {
    const where: any = { householdId };

    if (options.startDate || options.endDate) {
      where.createdAt = {};
      if (options.startDate) where.createdAt.gte = options.startDate;
      if (options.endDate) where.createdAt.lte = options.endDate;
    }

    if (options.status) {
      where.status = options.status;
    }

    if (options.category) {
      where.bill = { category: options.category };
    }

    const [payments, total] = await Promise.all([
      this.prisma.billPayment.findMany({
        where,
        include: {
          bill: {
            select: {
              name: true,
              category: true,
              vendor: {
                include: { vendor: { select: { displayName: true } } },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: options.limit || 50,
        skip: options.offset || 0,
      }),
      this.prisma.billPayment.count({ where }),
    ]);

    return {
      payments: payments.map(p => ({
        id: p.id,
        billName: p.bill?.name,
        vendorName: p.bill?.vendor?.vendor?.displayName,
        category: p.bill?.category,
        amount: p.amount,
        status: p.status,
        paymentMethod: p.paymentMethod,
        checkNumber: p.checkNumber,
        scheduledDate: p.scheduledDate,
        processedDate: p.processedDate,
        failureReason: p.failureReason,
      })),
      total,
      hasMore: (options.offset || 0) + payments.length < total,
    };
  }

  /**
   * Get monthly spending breakdown
   */
  async getMonthlyBreakdown(householdId: string, year?: number, month?: number) {
    const targetYear = year || new Date().getFullYear();
    const targetMonth = month || new Date().getMonth() + 1;

    const startDate = new Date(targetYear, targetMonth - 1, 1);
    const endDate = new Date(targetYear, targetMonth, 0);

    const payments = await this.prisma.billPayment.findMany({
      where: {
        householdId,
        status: 'completed',
        processedDate: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        bill: { select: { category: true } },
      },
    });

    // Group by category
    const byCategory: Record<string, number> = {};
    let total = 0;

    for (const payment of payments) {
      const category = payment.bill?.category || 'other';
      byCategory[category] = (byCategory[category] || 0) + payment.amount;
      total += payment.amount;
    }

    const categoryBreakdown = Object.entries(byCategory)
      .map(([category, amount]) => ({
        category,
        amount: Math.round(amount * 100) / 100,
        percentage: total > 0 ? Math.round((amount / total) * 100) : 0,
      }))
      .sort((a, b) => b.amount - a.amount);

    return {
      month: startDate.toLocaleString('default', { month: 'long', year: 'numeric' }),
      total: Math.round(total * 100) / 100,
      paymentCount: payments.length,
      breakdown: categoryBreakdown,
    };
  }

  /**
   * Get annual summary for tax purposes
   */
  async getAnnualSummary(householdId: string, year?: number) {
    const targetYear = year || new Date().getFullYear();
    const startDate = new Date(targetYear, 0, 1);
    const endDate = new Date(targetYear, 11, 31);

    const payments = await this.prisma.billPayment.findMany({
      where: {
        householdId,
        status: 'completed',
        processedDate: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        bill: {
          select: {
            name: true,
            category: true,
            vendor: {
              include: { vendor: { select: { displayName: true } } },
            },
          },
        },
      },
      orderBy: { processedDate: 'asc' },
    });

    // Group by month
    const byMonth: Record<string, number> = {};
    for (let i = 0; i < 12; i++) {
      byMonth[i.toString()] = 0;
    }

    // Group by category
    const byCategory: Record<string, number> = {};

    // Group by vendor
    const byVendor: Record<string, { name: string; amount: number; count: number }> = {};

    let total = 0;

    for (const payment of payments) {
      const month = payment.processedDate!.getMonth();
      const category = payment.bill?.category || 'other';
      const vendorName = payment.bill?.vendor?.vendor?.displayName || payment.bill?.name || 'Unknown';

      byMonth[month.toString()] += payment.amount;
      byCategory[category] = (byCategory[category] || 0) + payment.amount;

      if (!byVendor[vendorName]) {
        byVendor[vendorName] = { name: vendorName, amount: 0, count: 0 };
      }
      byVendor[vendorName].amount += payment.amount;
      byVendor[vendorName].count++;

      total += payment.amount;
    }

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return {
      year: targetYear,
      total: Math.round(total * 100) / 100,
      paymentCount: payments.length,
      monthlyTotals: monthNames.map((name, i) => ({
        month: name,
        amount: Math.round(byMonth[i.toString()] * 100) / 100,
      })),
      categoryBreakdown: Object.entries(byCategory)
        .map(([category, amount]) => ({
          category,
          amount: Math.round(amount * 100) / 100,
        }))
        .sort((a, b) => b.amount - a.amount),
      topVendors: Object.values(byVendor)
        .sort((a, b) => b.amount - a.amount)
        .slice(0, 10)
        .map(v => ({
          name: v.name,
          amount: Math.round(v.amount * 100) / 100,
          count: v.count,
        })),
    };
  }

  /**
   * Get detected bills awaiting confirmation
   */
  async getDetectedBills(householdId: string) {
    const detected = await this.prisma.detectedBill.findMany({
      where: {
        householdId,
        status: 'PENDING',
      },
      orderBy: { averageAmount: 'desc' },
    });

    return detected.map(d => ({
      id: d.id,
      merchantName: d.merchantName,
      category: d.category,
      averageAmount: d.averageAmount,
      lastAmount: d.lastAmount,
      frequency: d.frequency,
      lastTransactionDate: d.lastTransactionDate,
      transactionCount: d.dayOfMonth, // Using dayOfMonth as proxy for transaction count
    }));
  }

  // Helper methods

  private calculateMonthlyTotal(bills: any[]): number {
    return bills.reduce((sum, bill) => {
      const amount = bill.amount || bill.averageAmount || 0;
      return sum + this.toMonthlyAmount(amount, bill.frequency);
    }, 0);
  }

  private toMonthlyAmount(amount: number, frequency: string): number {
    switch (frequency?.toLowerCase()) {
      case 'weekly': return amount * 4.33;
      case 'biweekly': return amount * 2.17;
      case 'monthly': return amount;
      case 'quarterly': return amount / 3;
      case 'semi_annual': return amount / 6;
      case 'annual': return amount / 12;
      default: return amount;
    }
  }

  private getBillStatus(bill: any, payments: any[]): string {
    const billPayments = payments.filter(p => p.billId === bill.id);

    if (billPayments.some(p => p.status === 'processing')) return 'processing';
    if (billPayments.some(p => p.status === 'completed')) return 'paid';
    if (billPayments.some(p => p.status === 'failed')) return 'failed';

    return 'scheduled';
  }

  private async getAlerts(householdId: string, bills: any[], payments: any[]) {
    const alerts: Array<{ type: string; title: string; message: string; billId?: string }> = [];

    // Check for failed payments
    const failedPayments = payments.filter(p => p.status === 'failed');
    for (const payment of failedPayments) {
      alerts.push({
        type: 'error',
        title: 'Payment Failed',
        message: `Payment for ${payment.bill?.name || 'a bill'} failed: ${payment.failureReason || 'Unknown error'}`,
        billId: payment.billId,
      });
    }

    // Check for bills without payment method
    for (const bill of bills) {
      if (bill.paymentMethod === 'card' && !bill.household?.card?.stripeCardId) {
        alerts.push({
          type: 'warning',
          title: 'Card Not Set Up',
          message: `${bill.name} needs a card to pay. Set up your Haven card to enable autopay.`,
          billId: bill.id,
        });
      }
    }

    // Check for high amount bills coming up
    for (const bill of bills) {
      if (bill.amount && bill.averageAmount && bill.amount > bill.averageAmount * 1.3) {
        alerts.push({
          type: 'info',
          title: 'Higher Than Usual',
          message: `${bill.name} is ${Math.round((bill.amount / bill.averageAmount - 1) * 100)}% higher than usual.`,
          billId: bill.id,
        });
      }
    }

    return alerts;
  }
}
