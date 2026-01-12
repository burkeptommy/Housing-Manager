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
        household: { connect: { id: bill.householdId } },
        bill: { connect: { id: bill.id } },
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
