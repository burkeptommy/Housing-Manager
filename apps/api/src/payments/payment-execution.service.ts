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
        bill: { connect: { id: billId } },
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
