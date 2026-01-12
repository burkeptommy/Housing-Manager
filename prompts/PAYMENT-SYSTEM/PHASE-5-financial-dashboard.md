# PHASE 5: Financial Dashboard (Haven Wallet)

## OVERVIEW
Create API endpoints for the financial dashboard that shows users their bills, payments, and overall financial picture for their home.

---

## STEP 1: Create Dashboard Service

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/dashboard.service.ts`:

```typescript
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
      include: { vendor: true },
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
        vendor: true,
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
        name: b.vendor.name,
        phone: b.vendor.phone,
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
            select: { name: true, category: true, vendor: { select: { name: true } } },
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
        vendorName: p.bill?.vendor?.name,
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
        percentage: Math.round((amount / total) * 100),
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
          select: { name: true, category: true, vendor: { select: { name: true } } },
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
      const vendorName = payment.bill?.vendor?.name || payment.bill?.name || 'Unknown';

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
      transactionCount: d.transactionCount,
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
```

---

## STEP 2: Create Dashboard Controller

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/dashboard.controller.ts`:

```typescript
import { Controller, Get, Query, UseGuards, Req } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

@Controller('payments/dashboard')
@UseGuards(FirebaseAuthGuard)
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  @Get()
  async getDashboard(@Req() req: any) {
    const { householdId } = req.user;
    return this.dashboardService.getDashboard(householdId);
  }

  @Get('bills')
  async getAllBills(@Req() req: any) {
    const { householdId } = req.user;
    return this.dashboardService.getAllBills(householdId);
  }

  @Get('history')
  async getPaymentHistory(
    @Req() req: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('status') status?: string,
    @Query('category') category?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const { householdId } = req.user;
    return this.dashboardService.getPaymentHistory(householdId, {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      status,
      category,
      limit: limit ? parseInt(limit) : undefined,
      offset: offset ? parseInt(offset) : undefined,
    });
  }

  @Get('monthly')
  async getMonthlyBreakdown(
    @Req() req: any,
    @Query('year') year?: string,
    @Query('month') month?: string,
  ) {
    const { householdId } = req.user;
    return this.dashboardService.getMonthlyBreakdown(
      householdId,
      year ? parseInt(year) : undefined,
      month ? parseInt(month) : undefined,
    );
  }

  @Get('annual')
  async getAnnualSummary(
    @Req() req: any,
    @Query('year') year?: string,
  ) {
    const { householdId } = req.user;
    return this.dashboardService.getAnnualSummary(
      householdId,
      year ? parseInt(year) : undefined,
    );
  }

  @Get('detected')
  async getDetectedBills(@Req() req: any) {
    const { householdId } = req.user;
    return this.dashboardService.getDetectedBills(householdId);
  }
}
```

---

## STEP 3: Update Payments Module

Update `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/payments.module.ts` to include the dashboard:

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from '../prisma/prisma.module';
import { FinancialsModule } from '../financials/financials.module';
import { PlaidModule } from '../plaid/plaid.module';
import { CardService } from './card.service';
import { CardController } from './card.controller';
import { BillService } from './bill.service';
import { BillController } from './bill.controller';
import { PaymentExecutionService } from './payment-execution.service';
import { OrchestrationService } from './orchestration.service';
import { OrchestrationController } from './orchestration.controller';
import { ApprovalController } from './approval.controller';
import { PaymentScheduler } from './payment.scheduler';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';

@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    FinancialsModule,
    PlaidModule,
    ScheduleModule.forRoot(),
  ],
  controllers: [
    CardController,
    BillController,
    ApprovalController,
    OrchestrationController,
    DashboardController,
  ],
  providers: [
    CardService,
    BillService,
    PaymentExecutionService,
    OrchestrationService,
    PaymentScheduler,
    DashboardService,
  ],
  exports: [
    CardService,
    BillService,
    PaymentExecutionService,
    OrchestrationService,
    DashboardService,
  ],
})
export class PaymentsModule {}
```

---

## STEP 4: Test Dashboard Endpoints

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm dev
```

Test the endpoints:

```bash
# Get main dashboard
curl http://localhost:4000/api/payments/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get all bills
curl http://localhost:4000/api/payments/dashboard/bills \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get payment history
curl http://localhost:4000/api/payments/dashboard/history \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get monthly breakdown
curl "http://localhost:4000/api/payments/dashboard/monthly?year=2026&month=1" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get annual summary
curl "http://localhost:4000/api/payments/dashboard/annual?year=2025" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get detected bills
curl http://localhost:4000/api/payments/dashboard/detected \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## API Response Examples

### Main Dashboard Response
```json
{
  "summary": {
    "monthlyTotal": 5234.50,
    "paidThisMonth": 2847.00,
    "dueThisMonth": 5234.50,
    "remainingThisMonth": 2387.50,
    "totalBills": 12,
    "pendingApprovalsCount": 1
  },
  "card": {
    "last4": "4242",
    "brand": "visa",
    "status": "active",
    "fundingStatus": "connected"
  },
  "upcomingBills": [
    {
      "id": "bill_123",
      "name": "Eversource Electric",
      "amount": 312.47,
      "dueDate": "2026-01-15",
      "paymentMethod": "card",
      "autopayEnabled": true,
      "status": "scheduled"
    }
  ],
  "recentPayments": [
    {
      "id": "pay_456",
      "billName": "State Farm Insurance",
      "category": "insurance",
      "amount": 187.50,
      "status": "completed",
      "date": "2026-01-05",
      "paymentMethod": "card"
    }
  ],
  "pendingApprovals": [
    {
      "id": "appr_789",
      "billName": "Chase Mortgage",
      "amount": 3200.00,
      "reason": "critical_bill",
      "expiresAt": "2026-01-18"
    }
  ],
  "alerts": [
    {
      "type": "info",
      "title": "Higher Than Usual",
      "message": "Electric bill is 34% higher than usual.",
      "billId": "bill_123"
    }
  ],
  "currentMonth": "January 2026"
}
```

---

## VERIFICATION CHECKLIST

- [ ] DashboardService created with all methods
- [ ] DashboardController created
- [ ] Payments module updated
- [ ] Main dashboard endpoint works
- [ ] Bills listing endpoint works
- [ ] Payment history endpoint works
- [ ] Monthly breakdown endpoint works
- [ ] Annual summary endpoint works
- [ ] Detected bills endpoint works

---

## NEXT STEP

Proceed to PHASE-6-deploy-test.md
