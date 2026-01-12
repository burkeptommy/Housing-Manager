# PHASE 3: Payment Orchestration Engine

## OVERVIEW
Create the orchestration engine that automatically processes bills, handles pre-flight checks, manages approvals, and schedules payments.

---

## STEP 1: Create Orchestration Service

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/orchestration.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BillService } from './bill.service';
import { PaymentExecutionService } from './payment-execution.service';
import { PlaidService } from '../plaid/plaid.service';

interface PreflightResult {
  canPay: boolean;
  reason?: string;
  details?: string;
  requiresApproval?: boolean;
  approvalReason?: string;
}

@Injectable()
export class OrchestrationService {
  private readonly logger = new Logger(OrchestrationService.name);

  constructor(
    private prisma: PrismaService,
    private billService: BillService,
    private paymentService: PaymentExecutionService,
    private plaidService: PlaidService,
  ) {}

  /**
   * Main orchestration loop - called by scheduler
   * Finds bills due and processes them
   */
  async processUpcomingBills(): Promise<{
    processed: number;
    succeeded: number;
    failed: number;
    needsApproval: number;
  }> {
    this.logger.log('Starting payment orchestration run...');

    const bills = await this.billService.getBillsDueForPayment();
    this.logger.log(`Found ${bills.length} bills due for payment`);

    let processed = 0;
    let succeeded = 0;
    let failed = 0;
    let needsApproval = 0;

    for (const bill of bills) {
      try {
        const result = await this.processBill(bill);
        processed++;

        if (result.status === 'paid') succeeded++;
        else if (result.status === 'failed') failed++;
        else if (result.status === 'needs_approval') needsApproval++;
      } catch (error) {
        this.logger.error(`Error processing bill ${bill.id}: ${error.message}`);
        failed++;
      }
    }

    this.logger.log(`Orchestration complete: ${processed} processed, ${succeeded} succeeded, ${failed} failed, ${needsApproval} need approval`);

    return { processed, succeeded, failed, needsApproval };
  }

  /**
   * Process a single bill
   */
  async processBill(bill: any): Promise<{ status: string; details?: string }> {
    this.logger.log(`Processing bill: ${bill.name} ($${bill.amount || bill.averageAmount})`);

    // 1. Pre-flight checks
    const preflight = await this.preflightCheck(bill);
    
    if (!preflight.canPay) {
      this.logger.warn(`Preflight failed for ${bill.name}: ${preflight.reason}`);
      await this.alertUser(bill, preflight.reason!, preflight.details);
      return { status: 'failed', details: preflight.reason };
    }

    // 2. Check if approval is needed
    if (preflight.requiresApproval) {
      await this.createApprovalRequest(bill, preflight.approvalReason!);
      return { status: 'needs_approval', details: preflight.approvalReason };
    }

    // 3. Execute payment
    const amount = bill.amount || bill.averageAmount || bill.lastKnownAmount;
    const result = await this.paymentService.executePayment(bill.id, amount);

    // 4. Notify user
    if (result.success) {
      await this.notifyPaymentSuccess(bill, result);
      return { status: 'paid' };
    } else {
      await this.notifyPaymentFailure(bill, result);
      return { status: 'failed', details: result.error };
    }
  }

  /**
   * Pre-flight check before payment
   */
  async preflightCheck(bill: any): Promise<PreflightResult> {
    const amount = bill.amount || bill.averageAmount || bill.lastKnownAmount;

    // Check 1: Has payment method configured
    if (bill.paymentMethod === 'card' && !bill.household?.card?.stripeCardId) {
      return { canPay: false, reason: 'no_card', details: 'No card configured for household' };
    }

    if (bill.paymentMethod === 'check_digital' && !bill.paymentEmail) {
      return { canPay: false, reason: 'no_email', details: 'No email configured for digital check' };
    }

    if (bill.paymentMethod === 'check_physical' && !bill.mailingAddress) {
      return { canPay: false, reason: 'no_address', details: 'No mailing address configured' };
    }

    // Check 2: Has funding source connected
    if (bill.household?.card?.fundingStatus !== 'connected') {
      // In test mode, allow payments without real funding source
      const isTestMode = !bill.household?.card?.plaidAccountId?.startsWith('acc_');
      if (!isTestMode) {
        return { canPay: false, reason: 'no_funding', details: 'No bank account connected for funding' };
      }
    }

    // Check 3: Balance check (if Plaid connected)
    if (bill.household?.card?.plaidAccountId) {
      try {
        // Note: This would need Plaid Balance API call
        // For now, we'll skip in test mode
        // const balance = await this.plaidService.getBalance(bill.household.card.plaidAccountId);
        // if (balance < amount) {
        //   return { canPay: false, reason: 'insufficient_funds', details: `Balance $${balance} < $${amount}` };
        // }
      } catch (error) {
        this.logger.warn(`Could not check balance: ${error.message}`);
      }
    }

    // Check 4: Anomaly detection - amount significantly different from average
    if (bill.averageAmount && amount) {
      const variance = Math.abs(amount - bill.averageAmount) / bill.averageAmount;
      if (variance > 0.3) { // 30% variance
        return {
          canPay: true,
          requiresApproval: true,
          approvalReason: `amount_anomaly`,
          details: `Amount $${amount} is ${Math.round(variance * 100)}% different from average $${bill.averageAmount}`,
        };
      }
    }

    // Check 5: High amount threshold
    if (bill.approvalThreshold && amount > bill.approvalThreshold) {
      return {
        canPay: true,
        requiresApproval: true,
        approvalReason: 'high_amount',
        details: `Amount $${amount} exceeds threshold $${bill.approvalThreshold}`,
      };
    }

    // Check 6: Critical bill always requires approval
    if (bill.priority === 'critical' || bill.requiresApproval) {
      return {
        canPay: true,
        requiresApproval: true,
        approvalReason: 'critical_bill',
        details: `${bill.name} is marked as requiring approval`,
      };
    }

    // Check 7: First payment to this vendor/bill
    const previousPayments = await this.prisma.billPayment.count({
      where: { billId: bill.id, status: 'completed' },
    });

    if (previousPayments === 0) {
      return {
        canPay: true,
        requiresApproval: true,
        approvalReason: 'first_payment',
        details: `First payment for ${bill.name}`,
      };
    }

    return { canPay: true };
  }

  /**
   * Create an approval request
   */
  async createApprovalRequest(bill: any, reason: string) {
    const amount = bill.amount || bill.averageAmount || bill.lastKnownAmount;

    // Check if approval already exists
    const existing = await this.prisma.paymentApproval.findFirst({
      where: {
        billId: bill.id,
        status: 'pending',
      },
    });

    if (existing) {
      this.logger.log(`Approval already pending for bill ${bill.id}`);
      return existing;
    }

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 3); // Expires in 3 days

    const approval = await this.prisma.paymentApproval.create({
      data: {
        householdId: bill.householdId,
        billId: bill.id,
        amount,
        reason,
        expiresAt,
      },
    });

    this.logger.log(`Created approval request ${approval.id} for bill ${bill.name}`);

    // TODO: Send push notification
    await this.sendApprovalNotification(bill, approval);

    return approval;
  }

  /**
   * Process an approval response
   */
  async processApproval(approvalId: string, approved: boolean, userId: string, note?: string) {
    const approval = await this.prisma.paymentApproval.findUnique({
      where: { id: approvalId },
      include: { bill: true },
    });

    if (!approval) {
      throw new Error('Approval not found');
    }

    if (approval.status !== 'pending') {
      throw new Error('Approval already processed');
    }

    if (new Date() > approval.expiresAt) {
      await this.prisma.paymentApproval.update({
        where: { id: approvalId },
        data: { status: 'expired' },
      });
      throw new Error('Approval has expired');
    }

    // Update approval status
    await this.prisma.paymentApproval.update({
      where: { id: approvalId },
      data: {
        status: approved ? 'approved' : 'denied',
        respondedAt: new Date(),
        respondedBy: userId,
        responseNote: note,
      },
    });

    // If approved, execute payment
    if (approved) {
      const result = await this.paymentService.executePayment(approval.billId, approval.amount);
      
      // Link payment to approval
      if (result.paymentId) {
        await this.prisma.paymentApproval.update({
          where: { id: approvalId },
          data: { paymentId: result.paymentId },
        });
      }

      return result;
    }

    return { success: true, status: 'denied' };
  }

  /**
   * Get pending approvals for a household
   */
  async getPendingApprovals(householdId: string) {
    return this.prisma.paymentApproval.findMany({
      where: {
        householdId,
        status: 'pending',
        expiresAt: { gt: new Date() },
      },
      include: {
        bill: {
          select: { name: true, category: true, paymentMethod: true },
        },
      },
      orderBy: { expiresAt: 'asc' },
    });
  }

  /**
   * Expire old approvals
   */
  async expireOldApprovals() {
    const result = await this.prisma.paymentApproval.updateMany({
      where: {
        status: 'pending',
        expiresAt: { lt: new Date() },
      },
      data: { status: 'expired' },
    });

    if (result.count > 0) {
      this.logger.log(`Expired ${result.count} old approval requests`);
    }

    return result.count;
  }

  /**
   * Alert user about payment issue
   */
  private async alertUser(bill: any, reason: string, details?: string) {
    this.logger.log(`Alerting user about ${bill.name}: ${reason} - ${details}`);

    // TODO: Implement push notification / email
    // For now, we'll create an activity record
    // This would integrate with the Activity Feed from M12
  }

  /**
   * Send approval notification
   */
  private async sendApprovalNotification(bill: any, approval: any) {
    this.logger.log(`Sending approval notification for ${bill.name}`);

    // TODO: Implement push notification
    // Example payload:
    // {
    //   title: `Approve ${bill.name} payment?`,
    //   body: `$${approval.amount} due ${bill.nextDueDate}`,
    //   data: { type: 'payment_approval', approvalId: approval.id },
    //   actions: [
    //     { id: 'approve', title: 'Approve' },
    //     { id: 'review', title: 'Review' },
    //   ]
    // }
  }

  /**
   * Notify user of successful payment
   */
  private async notifyPaymentSuccess(bill: any, result: any) {
    this.logger.log(`Payment successful for ${bill.name}: $${result.amount}`);

    // TODO: Push notification
    // "✅ Paid Eversource Electric $247.83"
  }

  /**
   * Notify user of failed payment
   */
  private async notifyPaymentFailure(bill: any, result: any) {
    this.logger.log(`Payment failed for ${bill.name}: ${result.error}`);

    // TODO: Push notification
    // "❌ Payment failed for Eversource Electric - tap to retry"
  }
}
```

---

## STEP 2: Create Approval Controller

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/approval.controller.ts`:

```typescript
import { Controller, Get, Post, Param, Body, UseGuards, Req } from '@nestjs/common';
import { OrchestrationService } from './orchestration.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

@Controller('payments/approvals')
@UseGuards(FirebaseAuthGuard)
export class ApprovalController {
  constructor(private orchestrationService: OrchestrationService) {}

  @Get()
  async getPendingApprovals(@Req() req: any) {
    const { householdId } = req.user;
    return this.orchestrationService.getPendingApprovals(householdId);
  }

  @Post(':id/approve')
  async approvePayment(
    @Req() req: any,
    @Param('id') id: string,
    @Body('note') note?: string,
  ) {
    const { id: userId } = req.user;
    return this.orchestrationService.processApproval(id, true, userId, note);
  }

  @Post(':id/deny')
  async denyPayment(
    @Req() req: any,
    @Param('id') id: string,
    @Body('note') note?: string,
  ) {
    const { id: userId } = req.user;
    return this.orchestrationService.processApproval(id, false, userId, note);
  }
}
```

---

## STEP 3: Create Payment Scheduler

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/payment.scheduler.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { OrchestrationService } from './orchestration.service';

@Injectable()
export class PaymentScheduler {
  private readonly logger = new Logger(PaymentScheduler.name);

  constructor(private orchestrationService: OrchestrationService) {}

  /**
   * Process bills daily at 6 AM ET
   */
  @Cron('0 6 * * *', { timeZone: 'America/New_York' })
  async processUpcomingBills() {
    this.logger.log('Running scheduled payment processing...');
    
    try {
      const result = await this.orchestrationService.processUpcomingBills();
      this.logger.log(`Scheduled run complete: ${JSON.stringify(result)}`);
    } catch (error) {
      this.logger.error(`Scheduled payment processing failed: ${error.message}`);
    }
  }

  /**
   * Send payment reminders at 9 AM ET
   */
  @Cron('0 9 * * *', { timeZone: 'America/New_York' })
  async sendPaymentReminders() {
    this.logger.log('Sending payment reminders...');
    // TODO: Implement reminder notifications for upcoming bills
  }

  /**
   * Expire old approvals at midnight
   */
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async expireApprovals() {
    this.logger.log('Expiring old approval requests...');
    
    try {
      const count = await this.orchestrationService.expireOldApprovals();
      this.logger.log(`Expired ${count} approval requests`);
    } catch (error) {
      this.logger.error(`Failed to expire approvals: ${error.message}`);
    }
  }

  /**
   * Reconcile payments at noon
   * Check that completed payments actually went through
   */
  @Cron('0 12 * * *', { timeZone: 'America/New_York' })
  async reconcilePayments() {
    this.logger.log('Reconciling payments...');
    // TODO: Check Checkbook.io status for pending checks
    // TODO: Verify Stripe payments cleared
  }
}
```

---

## STEP 4: Create Internal Orchestration Controller

For manual triggering and testing:

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/orchestration.controller.ts`:

```typescript
import { Controller, Post, Get, UseGuards, Headers, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OrchestrationService } from './orchestration.service';

@Controller('internal/payments')
export class OrchestrationController {
  constructor(
    private orchestrationService: OrchestrationService,
    private configService: ConfigService,
  ) {}

  /**
   * Manually trigger payment processing
   * Protected by cron secret
   */
  @Post('process')
  async triggerProcessing(@Headers('x-cron-secret') cronSecret: string) {
    const expectedSecret = this.configService.get<string>('CRON_SECRET');
    
    if (!expectedSecret || cronSecret !== expectedSecret) {
      throw new UnauthorizedException('Invalid cron secret');
    }

    return this.orchestrationService.processUpcomingBills();
  }

  /**
   * Get orchestration status
   */
  @Get('status')
  async getStatus(@Headers('x-cron-secret') cronSecret: string) {
    const expectedSecret = this.configService.get<string>('CRON_SECRET');
    
    if (!expectedSecret || cronSecret !== expectedSecret) {
      throw new UnauthorizedException('Invalid cron secret');
    }

    // Return basic stats
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
    };
  }
}
```

---

## STEP 5: Update Payments Module

Update `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/payments.module.ts`:

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
  ],
  providers: [
    CardService,
    BillService,
    PaymentExecutionService,
    OrchestrationService,
    PaymentScheduler,
  ],
  exports: [CardService, BillService, PaymentExecutionService, OrchestrationService],
})
export class PaymentsModule {}
```

---

## STEP 6: Ensure Schedule Module is Available

Make sure `@nestjs/schedule` is installed:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm add @nestjs/schedule
```

---

## STEP 7: Test Orchestration

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm dev
```

Test manual trigger:
```bash
curl -X POST http://localhost:4000/api/internal/payments/process \
  -H "x-cron-secret: YOUR_CRON_SECRET"
```

---

## VERIFICATION CHECKLIST

- [ ] OrchestrationService created with preflight checks
- [ ] ApprovalController created
- [ ] PaymentScheduler created with cron jobs
- [ ] OrchestrationController for manual triggers
- [ ] PaymentsModule updated
- [ ] @nestjs/schedule installed
- [ ] Can manually trigger orchestration
- [ ] Approval flow works

---

## NEXT STEP

Proceed to PHASE-4-alfred-tools.md
