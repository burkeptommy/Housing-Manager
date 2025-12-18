import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { TransactionStatus } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import {
  CollectionResultDto,
  BatchCollectionResultDto,
  RevenueStatsDto,
  MonthlyRevenueDto,
  HouseholdRevenueDto,
} from './dto';

/**
 * CollectionService - Handles ACH debit collection from client bank accounts
 *
 * Flow:
 * 1. Invoice is created by InvoiceGenerationService
 * 2. collect() is called with the invoice ID
 * 3. Creates Stripe PaymentIntent with ACH debit
 * 4. Confirms payment against client's saved bank account
 * 5. Webhook updates invoice status on success/failure
 */
@Injectable()
export class CollectionService {
  private readonly logger = new Logger(CollectionService.name);
  private stripe: Stripe | null = null;
  private readonly isTestMode: boolean;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    this.isTestMode = !secretKey || secretKey.startsWith('sk_test_');

    if (secretKey) {
      this.stripe = new Stripe(secretKey, {
        apiVersion: '2025-02-24.acacia',
      });
      this.logger.log('Stripe initialized for ACH collections');
    } else {
      this.logger.warn('STRIPE_SECRET_KEY not configured - running in test mode');
    }
  }

  /**
   * Collect payment for a specific invoice via ACH debit
   */
  async collect(invoiceId: string, force = false): Promise<CollectionResultDto> {
    this.logger.log(`Collecting payment for invoice ${invoiceId}`);

    try {
      // Get invoice with household and bank account
      const invoice = await this.prisma.householdInvoice.findUnique({
        where: { id: invoiceId },
        include: {
          household: {
            include: {
              clientBankAccounts: {
                where: { isDefault: true, isActive: true },
              },
              owner: true,
            },
          },
        },
      });

      if (!invoice) {
        throw new NotFoundException('Invoice not found');
      }

      // Check if already paid
      if (invoice.status === 'PAID' && !force) {
        return {
          success: true,
          invoiceId,
          status: 'already_paid',
        };
      }

      // Check if payment is in progress
      if (invoice.status === 'PROCESSING' && !force) {
        return {
          success: false,
          invoiceId,
          error: 'Payment already in progress',
        };
      }

      // Check for bank account
      const bankAccount = invoice.household.clientBankAccounts[0];
      if (!bankAccount) {
        await this.markInvoiceFailed(invoiceId, 'No bank account configured');
        return {
          success: false,
          invoiceId,
          error: 'No bank account configured for this household',
        };
      }

      // In test mode, simulate the collection
      if (this.isTestMode || !this.stripe) {
        return this.simulateCollection(invoice, bankAccount);
      }

      // Create or update Stripe PaymentIntent
      let paymentIntentId = invoice.stripePaymentIntentId;

      if (!paymentIntentId) {
        // Get or create Stripe customer
        let stripeCustomerId = invoice.household.stripeCustomerId;

        if (!stripeCustomerId) {
          const customer = await this.stripe.customers.create({
            email: invoice.household.owner.email,
            name: invoice.household.name,
            metadata: {
              householdId: invoice.householdId,
            },
          });
          stripeCustomerId = customer.id;

          await this.prisma.household.update({
            where: { id: invoice.householdId },
            data: { stripeCustomerId },
          });
        }

        // Create PaymentIntent for ACH debit
        const paymentIntent = await this.stripe.paymentIntents.create({
          amount: Math.round(invoice.total.toNumber() * 100), // Convert to cents
          currency: 'usd',
          customer: stripeCustomerId,
          payment_method: bankAccount.stripePaymentMethodId,
          payment_method_types: ['us_bank_account'],
          confirm: true,
          mandate_data: {
            customer_acceptance: {
              type: 'offline',
            },
          },
          metadata: {
            householdInvoiceId: invoice.id,
            householdId: invoice.householdId,
            invoiceNumber: invoice.invoiceNumber,
          },
          description: `Haven Statement ${invoice.invoiceNumber}`,
        });

        paymentIntentId = paymentIntent.id;

        // Update invoice with payment intent
        await this.prisma.householdInvoice.update({
          where: { id: invoiceId },
          data: {
            stripePaymentIntentId: paymentIntentId,
            stripePaymentStatus: paymentIntent.status,
            status: paymentIntent.status === 'succeeded' ? 'PAID' : 'PROCESSING',
            paidAt: paymentIntent.status === 'succeeded' ? new Date() : null,
          },
        });

        // If payment succeeded immediately (rare for ACH)
        if (paymentIntent.status === 'succeeded') {
          await this.handlePaymentSuccess(invoice.id);
        }

        this.logger.log(
          `Created PaymentIntent ${paymentIntentId} for invoice ${invoiceId}: ${paymentIntent.status}`
        );

        return {
          success: true,
          invoiceId,
          paymentIntentId,
          status: paymentIntent.status,
        };
      } else {
        // Retry existing payment intent
        const paymentIntent = await this.stripe.paymentIntents.confirm(
          paymentIntentId,
          {
            payment_method: bankAccount.stripePaymentMethodId,
          }
        );

        await this.prisma.householdInvoice.update({
          where: { id: invoiceId },
          data: {
            stripePaymentStatus: paymentIntent.status,
            status: paymentIntent.status === 'succeeded' ? 'PAID' : 'PROCESSING',
            failedAt: null,
            failureReason: null,
          },
        });

        return {
          success: true,
          invoiceId,
          paymentIntentId,
          status: paymentIntent.status,
        };
      }
    } catch (error) {
      this.logger.error(`Collection failed for invoice ${invoiceId}: ${error}`);

      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      await this.markInvoiceFailed(invoiceId, errorMessage);

      return {
        success: false,
        invoiceId,
        error: errorMessage,
      };
    }
  }

  /**
   * Collect payment for all pending invoices
   */
  async collectAll(): Promise<BatchCollectionResultDto> {
    this.logger.log('Starting batch collection for all pending invoices...');

    const pendingInvoices = await this.prisma.householdInvoice.findMany({
      where: {
        status: { in: ['PENDING', 'FAILED'] },
      },
      select: { id: true },
    });

    const results: CollectionResultDto[] = [];
    let successfulCollections = 0;
    let failedCollections = 0;

    for (const invoice of pendingInvoices) {
      const result = await this.collect(invoice.id);
      results.push(result);

      if (result.success) {
        successfulCollections++;
      } else {
        failedCollections++;
      }
    }

    return {
      success: failedCollections === 0,
      totalInvoices: pendingInvoices.length,
      successfulCollections,
      failedCollections,
      results,
    };
  }

  /**
   * Handle successful payment webhook
   */
  async handlePaymentSuccess(invoiceId: string): Promise<void> {
    this.logger.log(`Processing payment success for invoice ${invoiceId}`);

    const invoice = await this.prisma.householdInvoice.findUnique({
      where: { id: invoiceId },
    });

    if (!invoice) {
      this.logger.warn(`Invoice ${invoiceId} not found`);
      return;
    }

    // Update invoice status
    await this.prisma.householdInvoice.update({
      where: { id: invoiceId },
      data: {
        status: 'PAID',
        stripePaymentStatus: 'succeeded',
        paidAt: new Date(),
        failedAt: null,
        failureReason: null,
      },
    });

    // Update all linked transactions to SETTLED
    await this.prisma.transaction.updateMany({
      where: { householdInvoiceId: invoiceId },
      data: {
        status: TransactionStatus.SETTLED,
        settledAt: new Date(),
      },
    });

    this.logger.log(`Invoice ${invoiceId} marked as PAID, transactions settled`);
  }

  /**
   * Handle failed payment webhook
   */
  async handlePaymentFailure(
    invoiceId: string,
    failureReason: string,
  ): Promise<void> {
    this.logger.warn(`Processing payment failure for invoice ${invoiceId}: ${failureReason}`);
    await this.markInvoiceFailed(invoiceId, failureReason);
  }

  /**
   * Get revenue statistics for the manager dashboard
   */
  async getRevenueStats(): Promise<RevenueStatsDto> {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Get pending amount
    const pendingInvoices = await this.prisma.householdInvoice.findMany({
      where: { status: 'PENDING' },
      select: { total: true },
    });
    const pendingAmount = pendingInvoices.reduce(
      (sum, inv) => sum + inv.total.toNumber(),
      0
    );

    // Get collected this month
    const paidThisMonth = await this.prisma.householdInvoice.findMany({
      where: {
        status: 'PAID',
        paidAt: { gte: startOfMonth },
      },
      select: { total: true },
    });
    const collectedThisMonth = paidThisMonth.reduce(
      (sum, inv) => sum + inv.total.toNumber(),
      0
    );

    // Get collected all time
    const paidAllTime = await this.prisma.householdInvoice.findMany({
      where: { status: 'PAID' },
      select: { total: true },
    });
    const collectedAllTime = paidAllTime.reduce(
      (sum, inv) => sum + inv.total.toNumber(),
      0
    );

    // Get failed amount
    const failedInvoices = await this.prisma.householdInvoice.findMany({
      where: { status: 'FAILED' },
      select: { total: true },
    });
    const failedAmount = failedInvoices.reduce(
      (sum, inv) => sum + inv.total.toNumber(),
      0
    );

    // Get counts
    const [pendingCount, paidThisMonthCount, failedCount] = await Promise.all([
      this.prisma.householdInvoice.count({ where: { status: 'PENDING' } }),
      this.prisma.householdInvoice.count({
        where: { status: 'PAID', paidAt: { gte: startOfMonth } },
      }),
      this.prisma.householdInvoice.count({ where: { status: 'FAILED' } }),
    ]);

    // Get monthly trend (last 6 months)
    const monthlyTrend = await this.getMonthlyTrend(6);

    return {
      pendingAmount,
      collectedThisMonth,
      collectedAllTime,
      failedAmount,
      pendingInvoices: pendingCount,
      paidInvoicesThisMonth: paidThisMonthCount,
      failedInvoices: failedCount,
      monthlyTrend,
    };
  }

  /**
   * Get revenue breakdown by household
   */
  async getHouseholdRevenue(): Promise<HouseholdRevenueDto[]> {
    const households = await this.prisma.household.findMany({
      include: {
        householdInvoices: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    return households.map((household) => {
      const invoices = household.householdInvoices;

      const pendingAmount = invoices
        .filter((i) => i.status === 'PENDING')
        .reduce((sum, i) => sum + i.total.toNumber(), 0);

      const collectedAmount = invoices
        .filter((i) => i.status === 'PAID')
        .reduce((sum, i) => sum + i.total.toNumber(), 0);

      const failedAmount = invoices
        .filter((i) => i.status === 'FAILED')
        .reduce((sum, i) => sum + i.total.toNumber(), 0);

      const latestInvoice = invoices[0];

      return {
        householdId: household.id,
        householdName: household.name,
        pendingAmount,
        collectedAmount,
        failedAmount,
        lastInvoiceStatus: latestInvoice?.status || 'N/A',
        lastInvoiceDate: latestInvoice?.createdAt || null,
      };
    });
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  private async markInvoiceFailed(
    invoiceId: string,
    reason: string,
  ): Promise<void> {
    await this.prisma.householdInvoice.update({
      where: { id: invoiceId },
      data: {
        status: 'FAILED',
        stripePaymentStatus: 'failed',
        failedAt: new Date(),
        failureReason: reason,
      },
    });
  }

  private async simulateCollection(
    invoice: {
      id: string;
      invoiceNumber: string;
      total: { toNumber: () => number };
      householdId: string;
    },
    bankAccount: { last4: string },
  ): Promise<CollectionResultDto> {
    this.logger.log(
      `[TEST MODE] Simulating ACH collection for invoice ${invoice.invoiceNumber}`
    );

    const simulatedPaymentIntentId = `pi_test_${Date.now()}_${invoice.id.substring(0, 8)}`;

    // Simulate processing status (ACH takes 3-5 days)
    await this.prisma.householdInvoice.update({
      where: { id: invoice.id },
      data: {
        stripePaymentIntentId: simulatedPaymentIntentId,
        stripePaymentStatus: 'processing',
        status: 'PROCESSING',
      },
    });

    this.logger.log(
      `[TEST MODE] Simulated PaymentIntent ${simulatedPaymentIntentId} - Processing ACH from ****${bankAccount.last4}`
    );

    return {
      success: true,
      invoiceId: invoice.id,
      paymentIntentId: simulatedPaymentIntentId,
      status: 'processing',
    };
  }

  private async getMonthlyTrend(months: number): Promise<MonthlyRevenueDto[]> {
    const trend: MonthlyRevenueDto[] = [];
    const now = new Date();

    for (let i = months - 1; i >= 0; i--) {
      const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0, 23, 59, 59, 999);
      const monthKey = `${monthStart.getFullYear()}-${String(monthStart.getMonth() + 1).padStart(2, '0')}`;

      // Get invoices for this month
      const invoices = await this.prisma.householdInvoice.findMany({
        where: {
          createdAt: {
            gte: monthStart,
            lte: monthEnd,
          },
        },
        select: { status: true, total: true },
      });

      const pending = invoices
        .filter((i) => i.status === 'PENDING' || i.status === 'PROCESSING')
        .reduce((sum, i) => sum + i.total.toNumber(), 0);

      const collected = invoices
        .filter((i) => i.status === 'PAID')
        .reduce((sum, i) => sum + i.total.toNumber(), 0);

      const failed = invoices
        .filter((i) => i.status === 'FAILED')
        .reduce((sum, i) => sum + i.total.toNumber(), 0);

      trend.push({ month: monthKey, pending, collected, failed });
    }

    return trend;
  }
}
