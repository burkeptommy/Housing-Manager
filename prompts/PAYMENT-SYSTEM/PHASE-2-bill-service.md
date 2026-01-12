# PHASE 2: Bill Service & Payment Execution

## OVERVIEW
Create the Bill service for managing bills and the Payment Execution service for actually sending payments via card or check.

---

## STEP 1: Create Bill Service

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/bill.service.ts`:

```typescript
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
        householdId,
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
        vendorId: data.vendorId,
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
```

---

## STEP 2: Create Payment Execution Service

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/payment-execution.service.ts`:

```typescript
import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CardService } from './card.service';
import { CheckbookService } from '../financials/checkbook.service';

export interface PaymentResult {
  success: boolean;
  paymentId: string;
  method: string;
  amount: number;
  reference?: string;
  error?: string;
}

@Injectable()
export class PaymentExecutionService {
  private readonly logger = new Logger(PaymentExecutionService.name);

  constructor(
    private prisma: PrismaService,
    private cardService: CardService,
    private checkbookService: CheckbookService,
  ) {}

  /**
   * Execute a payment for a bill
   */
  async executePayment(billId: string, amount?: number): Promise<PaymentResult> {
    const bill = await this.prisma.bill.findUnique({
      where: { id: billId },
      include: {
        household: { include: { card: true } },
        vendor: true,
      },
    });

    if (!bill) {
      throw new BadRequestException('Bill not found');
    }

    const paymentAmount = amount || bill.amount || bill.lastKnownAmount;
    if (!paymentAmount) {
      throw new BadRequestException('Payment amount required for variable bills');
    }

    this.logger.log(`Executing ${bill.paymentMethod} payment of $${paymentAmount} for bill ${bill.name}`);

    // Create payment record
    const payment = await this.prisma.billPayment.create({
      data: {
        billId,
        householdId: bill.householdId,
        amount: paymentAmount,
        status: 'processing',
        paymentMethod: bill.paymentMethod,
        scheduledDate: new Date(),
      },
    });

    try {
      let result: PaymentResult;

      switch (bill.paymentMethod) {
        case 'card':
          result = await this.executeCardPayment(bill, payment.id, paymentAmount);
          break;
        case 'check_digital':
          result = await this.executeDigitalCheck(bill, payment.id, paymentAmount);
          break;
        case 'check_physical':
          result = await this.executePhysicalCheck(bill, payment.id, paymentAmount);
          break;
        default:
          throw new BadRequestException(`Unsupported payment method: ${bill.paymentMethod}`);
      }

      // Update payment record
      await this.prisma.billPayment.update({
        where: { id: payment.id },
        data: {
          status: result.success ? 'completed' : 'failed',
          processedDate: new Date(),
          stripePaymentId: result.method === 'card' ? result.reference : undefined,
          checkbookCheckId: result.method.includes('check') ? result.reference : undefined,
          failureReason: result.error,
        },
      });

      // Update bill's last known amount and advance due date
      if (result.success) {
        await this.prisma.bill.update({
          where: { id: billId },
          data: { lastKnownAmount: paymentAmount },
        });

        // Import BillService and advance due date
        const nextDueDate = this.calculateNextDueDate(bill);
        if (nextDueDate) {
          await this.prisma.bill.update({
            where: { id: billId },
            data: { nextDueDate },
          });
        }
      }

      return result;
    } catch (error) {
      this.logger.error(`Payment failed for bill ${billId}: ${error.message}`);

      await this.prisma.billPayment.update({
        where: { id: payment.id },
        data: {
          status: 'failed',
          failureReason: error.message,
          retryCount: { increment: 1 },
        },
      });

      return {
        success: false,
        paymentId: payment.id,
        method: bill.paymentMethod,
        amount: paymentAmount,
        error: error.message,
      };
    }
  }

  /**
   * Execute card payment
   */
  private async executeCardPayment(
    bill: any,
    paymentId: string,
    amount: number,
  ): Promise<PaymentResult> {
    this.logger.log(`Processing card payment of $${amount} for ${bill.name}`);

    // In a real implementation, this would:
    // 1. Get card details from Stripe Issuing
    // 2. Use card to pay at vendor's payment portal
    // 3. For now, we simulate success in test mode

    const card = bill.household?.card;
    if (!card?.stripeCardId) {
      throw new BadRequestException('No card configured for household');
    }

    // Simulate card payment (in production, would interact with vendor portal)
    const simulatedPaymentId = `pi_test_${Date.now()}`;

    this.logger.log(`[TEST MODE] Card payment simulated: ${simulatedPaymentId}`);

    return {
      success: true,
      paymentId,
      method: 'card',
      amount,
      reference: simulatedPaymentId,
    };
  }

  /**
   * Execute digital check (via email)
   */
  private async executeDigitalCheck(
    bill: any,
    paymentId: string,
    amount: number,
  ): Promise<PaymentResult> {
    if (!bill.paymentEmail) {
      throw new BadRequestException('No email configured for digital check');
    }

    this.logger.log(`Sending digital check of $${amount} to ${bill.paymentEmail}`);

    // Use Checkbook.io to send digital check
    // Note: Checkbook digital checks send an email to the recipient
    // They click to deposit, which triggers ACH to their account

    const checkResult = await this.checkbookService.sendPhysicalCheck({
      vendorAddress: {
        name: bill.vendor?.name || bill.name,
        line1: bill.paymentEmail, // For digital, this is email
        city: 'Digital',
        state: 'NA',
        zip: '00000',
      },
      amount,
      memo: `Payment for ${bill.name}`,
      description: `Haven payment - ${bill.name}`,
    });

    return {
      success: true,
      paymentId,
      method: 'check_digital',
      amount,
      reference: checkResult.checkId,
    };
  }

  /**
   * Execute physical check (mailed)
   */
  private async executePhysicalCheck(
    bill: any,
    paymentId: string,
    amount: number,
  ): Promise<PaymentResult> {
    if (!bill.mailingAddress) {
      throw new BadRequestException('No mailing address configured for check');
    }

    this.logger.log(`Mailing physical check of $${amount} to ${bill.mailingAddress}`);

    // Parse address (assumes format: "Name, Street, City, State ZIP")
    const addressParts = bill.mailingAddress.split(',').map((p: string) => p.trim());
    
    let vendorAddress: any;
    if (addressParts.length >= 4) {
      const lastPart = addressParts[addressParts.length - 1];
      const stateZip = lastPart.split(' ');
      
      vendorAddress = {
        name: bill.vendor?.name || addressParts[0],
        line1: addressParts[1],
        city: addressParts[2],
        state: stateZip[0],
        zip: stateZip[1] || '00000',
      };
    } else {
      // Fallback for simple address
      vendorAddress = {
        name: bill.vendor?.name || bill.name,
        line1: bill.mailingAddress,
        city: 'Unknown',
        state: 'CT',
        zip: '06830',
      };
    }

    const checkResult = await this.checkbookService.sendPhysicalCheck({
      vendorAddress,
      amount,
      memo: `Payment for ${bill.name}`,
      description: `Haven payment - ${bill.name}`,
    });

    // Update payment with check details
    await this.prisma.billPayment.update({
      where: { id: paymentId },
      data: {
        checkNumber: checkResult.checkNumber,
        checkTrackingNumber: checkResult.trackingNumber,
      },
    });

    return {
      success: true,
      paymentId,
      method: 'check_physical',
      amount,
      reference: checkResult.checkId,
    };
  }

  /**
   * Calculate next due date (duplicated for isolation - could be shared)
   */
  private calculateNextDueDate(bill: any): Date | null {
    if (!bill.frequency || bill.frequency === 'one_time') return null;

    const current = bill.nextDueDate ? new Date(bill.nextDueDate) : new Date();
    const next = new Date(current);

    switch (bill.frequency.toLowerCase()) {
      case 'weekly':
        next.setDate(next.getDate() + 7);
        break;
      case 'biweekly':
        next.setDate(next.getDate() + 14);
        break;
      case 'monthly':
        next.setMonth(next.getMonth() + 1);
        break;
      case 'quarterly':
        next.setMonth(next.getMonth() + 3);
        break;
      case 'semi_annual':
        next.setMonth(next.getMonth() + 6);
        break;
      case 'annual':
        next.setFullYear(next.getFullYear() + 1);
        break;
    }

    return next;
  }

  /**
   * Retry a failed payment
   */
  async retryPayment(paymentId: string): Promise<PaymentResult> {
    const payment = await this.prisma.billPayment.findUnique({
      where: { id: paymentId },
      include: { bill: true },
    });

    if (!payment) {
      throw new BadRequestException('Payment not found');
    }

    if (payment.status !== 'failed') {
      throw new BadRequestException('Can only retry failed payments');
    }

    if (payment.retryCount >= payment.maxRetries) {
      throw new BadRequestException('Max retries exceeded');
    }

    return this.executePayment(payment.billId, payment.amount);
  }

  /**
   * Get payment history for a bill
   */
  async getPaymentHistory(billId: string, limit: number = 10) {
    return this.prisma.billPayment.findMany({
      where: { billId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  /**
   * Get all payments for a household
   */
  async getHouseholdPayments(householdId: string, options?: {
    status?: string;
    startDate?: Date;
    endDate?: Date;
    limit?: number;
  }) {
    const where: any = { householdId };
    
    if (options?.status) {
      where.status = options.status;
    }
    
    if (options?.startDate || options?.endDate) {
      where.processedDate = {};
      if (options.startDate) where.processedDate.gte = options.startDate;
      if (options.endDate) where.processedDate.lte = options.endDate;
    }

    return this.prisma.billPayment.findMany({
      where,
      include: {
        bill: {
          select: { name: true, category: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: options?.limit || 50,
    });
  }
}
```

---

## STEP 3: Create Bill Controller

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/bill.controller.ts`:

```typescript
import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { BillService, CreateBillDto } from './bill.service';
import { PaymentExecutionService } from './payment-execution.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

@Controller('payments/bills')
@UseGuards(FirebaseAuthGuard)
export class BillController {
  constructor(
    private billService: BillService,
    private paymentService: PaymentExecutionService,
  ) {}

  @Post()
  async createBill(@Req() req: any, @Body() data: CreateBillDto) {
    const { householdId } = req.user;
    return this.billService.createBill(householdId, data);
  }

  @Post('from-detected/:detectedBillId')
  async createFromDetected(
    @Req() req: any,
    @Param('detectedBillId') detectedBillId: string,
    @Body() data: {
      paymentMethod: string;
      paymentEmail?: string;
      mailingAddress?: string;
      paymentPortalUrl?: string;
    },
  ) {
    const { householdId } = req.user;
    return this.billService.createBillFromDetected(
      householdId,
      detectedBillId,
      data.paymentMethod,
      data,
    );
  }

  @Get()
  async getBills(@Req() req: any, @Query('status') status?: string) {
    const { householdId } = req.user;
    return this.billService.getBills(householdId, status);
  }

  @Get('upcoming')
  async getUpcomingBills(@Req() req: any, @Query('days') days?: string) {
    const { householdId } = req.user;
    return this.billService.getUpcomingBills(householdId, days ? parseInt(days) : 7);
  }

  @Get('summary')
  async getBillSummary(@Req() req: any) {
    const { householdId } = req.user;
    return this.billService.getBillSummary(householdId);
  }

  @Put(':id')
  async updateBill(
    @Req() req: any,
    @Param('id') id: string,
    @Body() data: Partial<CreateBillDto>,
  ) {
    const { householdId } = req.user;
    return this.billService.updateBill(id, householdId, data);
  }

  @Post(':id/toggle-autopay')
  async toggleAutopay(
    @Req() req: any,
    @Param('id') id: string,
    @Body('enabled') enabled: boolean,
  ) {
    const { householdId } = req.user;
    return this.billService.toggleAutopay(id, householdId, enabled);
  }

  @Delete(':id')
  async cancelBill(@Req() req: any, @Param('id') id: string) {
    const { householdId } = req.user;
    return this.billService.cancelBill(id, householdId);
  }

  // Payment endpoints
  @Post(':id/pay')
  async payBill(
    @Req() req: any,
    @Param('id') id: string,
    @Body('amount') amount?: number,
  ) {
    return this.paymentService.executePayment(id, amount);
  }

  @Get(':id/payments')
  async getPaymentHistory(@Param('id') id: string) {
    return this.paymentService.getPaymentHistory(id);
  }

  @Post('payments/:paymentId/retry')
  async retryPayment(@Param('paymentId') paymentId: string) {
    return this.paymentService.retryPayment(paymentId);
  }

  @Get('payments/all')
  async getAllPayments(
    @Req() req: any,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
  ) {
    const { householdId } = req.user;
    return this.paymentService.getHouseholdPayments(householdId, {
      status,
      limit: limit ? parseInt(limit) : undefined,
    });
  }
}
```

---

## STEP 4: Update Payments Module

Update `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/payments.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { FinancialsModule } from '../financials/financials.module';
import { CardService } from './card.service';
import { CardController } from './card.controller';
import { BillService } from './bill.service';
import { BillController } from './bill.controller';
import { PaymentExecutionService } from './payment-execution.service';

@Module({
  imports: [PrismaModule, ConfigModule, FinancialsModule],
  controllers: [CardController, BillController],
  providers: [CardService, BillService, PaymentExecutionService],
  exports: [CardService, BillService, PaymentExecutionService],
})
export class PaymentsModule {}
```

---

## STEP 5: Ensure FinancialsModule Exports CheckbookService

Check `/Users/tomburke/Projects/Housing-Manager/apps/api/src/financials/financials.module.ts` and make sure it exports CheckbookService:

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CheckbookService } from './checkbook.service';
import { StripePayoutService } from './stripe-payout.service';

@Module({
  imports: [ConfigModule],
  providers: [CheckbookService, StripePayoutService],
  exports: [CheckbookService, StripePayoutService],
})
export class FinancialsModule {}
```

---

## STEP 6: Test the APIs

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm dev
```

Test creating a bill:
```bash
curl -X POST http://localhost:4000/api/payments/bills \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Eversource Electric",
    "category": "utility",
    "amount": 247.83,
    "frequency": "monthly",
    "dueDay": 15,
    "paymentMethod": "card"
  }'
```

---

## VERIFICATION CHECKLIST

- [ ] BillService created
- [ ] PaymentExecutionService created
- [ ] BillController created
- [ ] PaymentsModule updated
- [ ] FinancialsModule exports CheckbookService
- [ ] Can create bills via API
- [ ] Can trigger payment execution

---

## NEXT STEP

Proceed to PHASE-3-orchestration-engine.md
