import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { Decimal } from '@prisma/client/runtime/library';

import { PrismaService } from '../prisma/prisma.service';
import {
  HouseholdInvoiceDto,
  HouseholdInvoiceListItemDto,
  HouseholdInvoiceItemDto,
  HouseholdInvoiceStatus,
  BillingSummaryDto,
  GenerateInvoicesResultDto,
} from './dto';

@Injectable()
export class InvoicesService implements OnModuleInit {
  private stripe: Stripe | null = null;
  private readonly logger = new Logger(InvoicesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  onModuleInit() {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (secretKey) {
      this.stripe = new Stripe(secretKey, {
        apiVersion: '2024-11-20.acacia',
      });
      this.logger.log('Stripe initialized for household invoices');
    } else {
      this.logger.warn(
        'STRIPE_SECRET_KEY not configured - household invoice payments disabled',
      );
    }
  }

  /**
   * Generate consolidated invoices for all households due today
   * Run this daily via cron job
   */
  async generateConsolidatedInvoices(): Promise<GenerateInvoicesResultDto> {
    this.logger.log('Starting consolidated invoice generation...');
    const errors: string[] = [];
    let invoicesGenerated = 0;
    let householdsProcessed = 0;

    const today = new Date();
    const dayOfMonth = today.getDate();

    // Find households with consolidatedBillingDay = today
    // Also include households where billing day is 29/30/31 but today is the last day of month
    const households = await this.prisma.household.findMany({
      where: {
        consolidatedBillingDay: {
          not: null,
        },
        stripeCustomerId: {
          not: null,
        },
      },
      include: {
        owner: true,
        billAccounts: {
          where: {
            isActive: true,
            deletedAt: null,
            paymentResponsibility: 'HAVEN_PAYS_ON_BEHALF',
            includeInConsolidatedInvoice: true,
          },
          include: {
            vendor: true,
          },
        },
      },
    });

    for (const household of households) {
      // Check if this household's billing day matches today
      const billingDay = household.consolidatedBillingDay!;
      const lastDayOfMonth = new Date(
        today.getFullYear(),
        today.getMonth() + 1,
        0,
      ).getDate();

      // If billing day > last day of month, bill on last day
      const effectiveBillingDay = Math.min(billingDay, lastDayOfMonth);
      if (dayOfMonth !== effectiveBillingDay) {
        continue;
      }

      householdsProcessed++;

      // Skip if no bill accounts to invoice
      if (household.billAccounts.length === 0) {
        this.logger.log(
          `Household ${household.id} has no bill accounts for consolidated invoice`,
        );
        continue;
      }

      try {
        await this.createHouseholdInvoice(household.id);
        invoicesGenerated++;
      } catch (error) {
        const errorMsg =
          error instanceof Error ? error.message : 'Unknown error';
        this.logger.error(
          `Failed to create invoice for household ${household.id}: ${errorMsg}`,
        );
        errors.push(`Household ${household.id}: ${errorMsg}`);
      }
    }

    this.logger.log(
      `Invoice generation complete: ${invoicesGenerated} invoices, ${householdsProcessed} households`,
    );

    return {
      success: errors.length === 0,
      invoicesGenerated,
      householdsProcessed,
      errors: errors.length > 0 ? errors : undefined,
    };
  }

  /**
   * Create a consolidated invoice for a household
   */
  async createHouseholdInvoice(householdId: string): Promise<HouseholdInvoiceDto> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        owner: true,
        billAccounts: {
          where: {
            isActive: true,
            deletedAt: null,
            paymentResponsibility: 'HAVEN_PAYS_ON_BEHALF',
            includeInConsolidatedInvoice: true,
          },
          include: {
            vendor: true,
          },
        },
        paymentMethods: {
          where: {
            isDefaultForSubscription: true,
            isActive: true,
          },
        },
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    if (!household.stripeCustomerId) {
      throw new BadRequestException(
        'Household does not have Stripe customer setup',
      );
    }

    if (household.billAccounts.length === 0) {
      throw new BadRequestException(
        'No bill accounts configured for consolidated billing',
      );
    }

    // Calculate billing period (current month)
    const now = new Date();
    const billingPeriodStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const billingPeriodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    // Calculate subtotal from typical amounts
    let subtotal = new Decimal(0);
    const lineItems: Array<{
      billAccountId: string;
      description: string;
      amount: Decimal;
    }> = [];

    for (const bill of household.billAccounts) {
      // Use typicalAmount as estimate; in production this would come from actual invoices
      const amount = bill.typicalAmount || new Decimal(0);
      subtotal = subtotal.add(amount);

      lineItems.push({
        billAccountId: bill.id,
        description: `${bill.nickname} - ${bill.vendor.displayName}`,
        amount,
      });
    }

    // STUB: Platform fee calculation - currently 0, can be percentage or flat fee
    const platformFee = new Decimal(0);
    const total = subtotal.add(platformFee);

    // Generate invoice number
    const invoiceNumber = await this.generateInvoiceNumber(householdId);

    // Create invoice in database
    const invoice = await this.prisma.householdInvoice.create({
      data: {
        householdId,
        invoiceNumber,
        billingPeriodStart,
        billingPeriodEnd,
        subtotal,
        platformFee,
        total,
        status: 'PENDING',
        items: {
          create: lineItems.map((item) => ({
            billAccountId: item.billAccountId,
            description: item.description,
            amount: item.amount,
          })),
        },
      },
      include: {
        items: {
          include: {
            billAccount: {
              include: {
                vendor: true,
              },
            },
          },
        },
      },
    });

    // Create Stripe PaymentIntent
    if (this.stripe && total.toNumber() > 0) {
      try {
        const paymentIntent = await this.stripe.paymentIntents.create({
          amount: Math.round(total.toNumber() * 100), // Convert to cents
          currency: 'usd',
          customer: household.stripeCustomerId,
          // STUB: In production, would set confirm: true and use saved payment method
          // For now, create as manual confirmation to demonstrate the flow
          automatic_payment_methods: {
            enabled: true,
            allow_redirects: 'never',
          },
          metadata: {
            householdInvoiceId: invoice.id,
            householdId,
            invoiceNumber,
          },
          description: `Haven consolidated bill - ${invoiceNumber}`,
        });

        // Update invoice with Stripe IDs
        await this.prisma.householdInvoice.update({
          where: { id: invoice.id },
          data: {
            stripePaymentIntentId: paymentIntent.id,
            stripePaymentStatus: paymentIntent.status,
            status: 'PROCESSING',
          },
        });

        // STUB: In production with saved payment methods, would confirm immediately:
        // await this.stripe.paymentIntents.confirm(paymentIntent.id, {
        //   payment_method: household.paymentMethods[0]?.stripePaymentMethodId,
        // });

        this.logger.log(
          `Created PaymentIntent ${paymentIntent.id} for invoice ${invoice.id}`,
        );
      } catch (error) {
        this.logger.error('Failed to create Stripe PaymentIntent:', error);
        // Mark invoice as failed but don't throw - invoice is still created for manual handling
        await this.prisma.householdInvoice.update({
          where: { id: invoice.id },
          data: {
            status: 'FAILED',
            failureReason:
              error instanceof Error
                ? error.message
                : 'Failed to create payment',
            failedAt: new Date(),
          },
        });
      }
    }

    return this.mapToDto(invoice);
  }

  /**
   * Handle successful payment from Stripe webhook
   */
  async handlePaymentSuccess(paymentIntentId: string): Promise<void> {
    this.logger.log(`Processing payment success for ${paymentIntentId}`);

    const invoice = await this.prisma.householdInvoice.findFirst({
      where: { stripePaymentIntentId: paymentIntentId },
    });

    if (!invoice) {
      this.logger.warn(`No invoice found for PaymentIntent ${paymentIntentId}`);
      return;
    }

    await this.prisma.householdInvoice.update({
      where: { id: invoice.id },
      data: {
        status: 'PAID',
        stripePaymentStatus: 'succeeded',
        paidAt: new Date(),
      },
    });

    // STUB: In future, trigger vendor payouts here
    // await this.initiateVendorPayouts(invoice.id);

    this.logger.log(`Invoice ${invoice.id} marked as PAID`);
  }

  /**
   * Handle failed payment from Stripe webhook
   */
  async handlePaymentFailure(
    paymentIntentId: string,
    failureReason: string,
  ): Promise<void> {
    this.logger.warn(
      `Processing payment failure for ${paymentIntentId}: ${failureReason}`,
    );

    const invoice = await this.prisma.householdInvoice.findFirst({
      where: { stripePaymentIntentId: paymentIntentId },
    });

    if (!invoice) {
      this.logger.warn(`No invoice found for PaymentIntent ${paymentIntentId}`);
      return;
    }

    await this.prisma.householdInvoice.update({
      where: { id: invoice.id },
      data: {
        status: 'FAILED',
        stripePaymentStatus: 'failed',
        failedAt: new Date(),
        failureReason,
      },
    });

    // STUB: Send notification to household owner about failed payment

    this.logger.log(`Invoice ${invoice.id} marked as FAILED`);
  }

  /**
   * Get all invoices for a household
   */
  async getInvoices(householdId: string): Promise<HouseholdInvoiceListItemDto[]> {
    const invoices = await this.prisma.householdInvoice.findMany({
      where: { householdId },
      include: {
        _count: {
          select: { items: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return invoices.map((invoice) => ({
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      billingPeriodStart: invoice.billingPeriodStart,
      billingPeriodEnd: invoice.billingPeriodEnd,
      total: invoice.total.toNumber(),
      status: invoice.status as HouseholdInvoiceStatus,
      itemCount: invoice._count.items,
      createdAt: invoice.createdAt,
    }));
  }

  /**
   * Get invoice details by ID
   */
  async getInvoiceById(
    invoiceId: string,
    householdId: string,
  ): Promise<HouseholdInvoiceDto> {
    const invoice = await this.prisma.householdInvoice.findFirst({
      where: {
        id: invoiceId,
        householdId,
      },
      include: {
        items: {
          include: {
            billAccount: {
              include: {
                vendor: true,
              },
            },
          },
        },
      },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    return this.mapToDto(invoice);
  }

  /**
   * Get billing summary for dashboard
   */
  async getBillingSummary(
    householdId: string,
    userId: string,
  ): Promise<BillingSummaryDto> {
    // Get subscription info
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        userId,
        status: { in: ['ACTIVE', 'PAST_DUE'] },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Get latest consolidated invoice
    const latestInvoice = await this.prisma.householdInvoice.findFirst({
      where: { householdId },
      include: {
        _count: { select: { items: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Get bill accounts managed by Haven
    const billAccounts = await this.prisma.billAccount.findMany({
      where: {
        householdId,
        isActive: true,
        deletedAt: null,
        paymentResponsibility: 'HAVEN_PAYS_ON_BEHALF',
      },
      include: {
        vendor: true,
      },
    });

    // Calculate monthly estimate
    const monthlyEstimate = billAccounts.reduce((sum, bill) => {
      return sum + (bill.typicalAmount?.toNumber() || 0);
    }, 0);

    // STUB: Subscription pricing - would come from Stripe price data
    const subscriptionPricing: Record<string, number> = {
      FREE: 0,
      BASIC: 9.99,
      PREMIUM: 19.99,
      ENTERPRISE: 49.99,
    };

    return {
      subscriptionTier: subscription?.tier || 'FREE',
      subscriptionAmount:
        subscriptionPricing[subscription?.tier || 'FREE'] || 0,
      subscriptionStatus: subscription?.status,
      latestInvoice: latestInvoice
        ? {
            id: latestInvoice.id,
            invoiceNumber: latestInvoice.invoiceNumber,
            billingPeriodStart: latestInvoice.billingPeriodStart,
            billingPeriodEnd: latestInvoice.billingPeriodEnd,
            total: latestInvoice.total.toNumber(),
            status: latestInvoice.status as HouseholdInvoiceStatus,
            itemCount: latestInvoice._count.items,
            createdAt: latestInvoice.createdAt,
          }
        : undefined,
      totalBillsManaged: billAccounts.length,
      monthlyBillEstimate: monthlyEstimate,
      billAccountsIncluded: billAccounts.map((bill) => ({
        id: bill.id,
        nickname: bill.nickname,
        vendorName: bill.vendor.displayName,
        category: bill.category,
        typicalAmount: bill.typicalAmount?.toNumber() || null,
      })),
    };
  }

  /**
   * Setup Stripe customer for a household
   * STUB: In production, this would be more comprehensive
   */
  async setupHouseholdStripe(
    householdId: string,
    paymentMethodId: string,
  ): Promise<{ stripeCustomerId: string }> {
    if (!this.stripe) {
      throw new BadRequestException('Stripe is not configured');
    }

    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: { owner: true },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    let stripeCustomerId = household.stripeCustomerId;

    // Create Stripe customer if doesn't exist
    if (!stripeCustomerId) {
      const customer = await this.stripe.customers.create({
        email: household.owner.email,
        name: household.name,
        metadata: {
          householdId,
          ownerId: household.ownerId,
        },
      });
      stripeCustomerId = customer.id;
    }

    // Attach payment method
    await this.stripe.paymentMethods.attach(paymentMethodId, {
      customer: stripeCustomerId,
    });

    // Set as default
    await this.stripe.customers.update(stripeCustomerId, {
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    });

    // Update household
    await this.prisma.household.update({
      where: { id: householdId },
      data: { stripeCustomerId },
    });

    return { stripeCustomerId };
  }

  /**
   * Update billing preferences for a household
   */
  async updateBillingPreferences(
    householdId: string,
    consolidatedBillingDay?: number,
  ): Promise<void> {
    if (
      consolidatedBillingDay !== undefined &&
      (consolidatedBillingDay < 1 || consolidatedBillingDay > 28)
    ) {
      throw new BadRequestException(
        'Billing day must be between 1 and 28',
      );
    }

    await this.prisma.household.update({
      where: { id: householdId },
      data: {
        consolidatedBillingDay,
      },
    });
  }

  // ============================================================================
  // STUB: Vendor Payout Methods (for future implementation)
  // ============================================================================

  /**
   * STUB: Initiate vendor payouts after invoice is paid
   * In production, this would:
   * 1. For each line item, look up the vendor's payout account
   * 2. For STRIPE_CONNECT vendors: create a Transfer to their connected account
   * 3. For CHECK vendors: queue a check to be mailed
   * 4. For MANUAL vendors: create a task for manual processing
   */
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  private async initiateVendorPayouts(_invoiceId: string): Promise<void> {
    // STUB: This is where vendor payout logic would go
    // Example flow:
    //
    // const invoice = await this.prisma.householdInvoice.findUnique({
    //   where: { id: invoiceId },
    //   include: {
    //     items: {
    //       include: {
    //         billAccount: {
    //           include: {
    //             vendor: {
    //               include: { vendorPayoutAccount: true }
    //             }
    //           }
    //         }
    //       }
    //     }
    //   }
    // });
    //
    // for (const item of invoice.items) {
    //   const payoutAccount = item.billAccount.vendor.vendorPayoutAccount;
    //   if (!payoutAccount) continue;
    //
    //   switch (payoutAccount.payoutMethod) {
    //     case 'STRIPE_CONNECT':
    //       await this.stripe.transfers.create({
    //         amount: Math.round(item.amount.toNumber() * 100),
    //         currency: 'usd',
    //         destination: payoutAccount.stripeAccountId!,
    //         metadata: { invoiceItemId: item.id }
    //       });
    //       break;
    //     case 'CHECK':
    //       // Queue check for mailing via check printing service
    //       break;
    //     case 'MANUAL':
    //       // Create task for manual processing
    //       break;
    //   }
    // }
    this.logger.log('STUB: Vendor payouts would be initiated here');
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  private async generateInvoiceNumber(householdId: string): Promise<string> {
    const count = await this.prisma.householdInvoice.count({
      where: { householdId },
    });

    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');

    // Format: INV-YYYYMM-XXXX (sequential per household)
    return `INV-${year}${month}-${String(count + 1).padStart(4, '0')}`;
  }

  private mapToDto(invoice: {
    id: string;
    householdId: string;
    invoiceNumber: string;
    billingPeriodStart: Date;
    billingPeriodEnd: Date;
    subtotal: Decimal;
    platformFee: Decimal;
    total: Decimal;
    status: string;
    stripePaymentIntentId: string | null;
    stripePaymentStatus: string | null;
    paidAt: Date | null;
    failedAt: Date | null;
    failureReason: string | null;
    createdAt: Date;
    updatedAt: Date;
    items: Array<{
      id: string;
      billAccountId: string;
      description: string;
      amount: Decimal;
      billAccount: {
        nickname: string;
        category: string;
        vendor: {
          displayName: string;
        };
      };
    }>;
  }): HouseholdInvoiceDto {
    return {
      id: invoice.id,
      householdId: invoice.householdId,
      invoiceNumber: invoice.invoiceNumber,
      billingPeriodStart: invoice.billingPeriodStart,
      billingPeriodEnd: invoice.billingPeriodEnd,
      subtotal: invoice.subtotal.toNumber(),
      platformFee: invoice.platformFee.toNumber(),
      total: invoice.total.toNumber(),
      status: invoice.status as HouseholdInvoiceStatus,
      stripePaymentIntentId: invoice.stripePaymentIntentId ?? undefined,
      stripePaymentStatus: invoice.stripePaymentStatus ?? undefined,
      paidAt: invoice.paidAt ?? undefined,
      failedAt: invoice.failedAt ?? undefined,
      failureReason: invoice.failureReason ?? undefined,
      items: invoice.items.map((item) => ({
        id: item.id,
        billAccountId: item.billAccountId,
        description: item.description,
        amount: item.amount.toNumber(),
        billNickname: item.billAccount.nickname,
        vendorName: item.billAccount.vendor.displayName,
        category: item.billAccount.category,
      })),
      createdAt: invoice.createdAt,
      updatedAt: invoice.updatedAt,
    };
  }
}
