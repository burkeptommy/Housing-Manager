import {
  Injectable,
  BadRequestException,
  NotFoundException,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

import { PrismaService } from '../prisma';
import { JwtPayload } from '../auth';

import { CreateSubscriptionDto, SubscriptionDto, SubscriptionTier, SubscriptionStatus } from './dto';

@Injectable()
export class BillingService implements OnModuleInit {
  private stripe: Stripe;
  private readonly logger = new Logger(BillingService.name);

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
      this.logger.log('Stripe initialized');
    } else {
      this.logger.warn('STRIPE_SECRET_KEY not configured - billing features disabled');
    }
  }

  async createSubscription(
    dto: CreateSubscriptionDto,
    user: JwtPayload,
  ): Promise<SubscriptionDto> {
    if (!this.stripe) {
      throw new BadRequestException('Stripe is not configured');
    }

    // Get user from database
    const dbUser = await this.prisma.user.findUnique({
      where: { id: user.sub },
      include: { subscriptions: { where: { status: 'ACTIVE' } } },
    });

    if (!dbUser) {
      throw new NotFoundException('User not found');
    }

    // Check if user already has an active subscription
    if (dbUser.subscriptions.length > 0) {
      throw new BadRequestException('User already has an active subscription');
    }

    // Free tier doesn't need Stripe
    if (dto.tier === SubscriptionTier.FREE) {
      return this.createFreeSubscription(user.sub);
    }

    // Get price ID for tier
    const priceId = this.getPriceIdForTier(dto.tier);
    if (!priceId) {
      throw new BadRequestException(`No price configured for tier: ${dto.tier}`);
    }

    try {
      // Create or retrieve Stripe customer
      let customerId: string;

      const existingCustomers = await this.stripe.customers.list({
        email: dbUser.email,
        limit: 1,
      });

      if (existingCustomers.data.length > 0) {
        customerId = existingCustomers.data[0].id;
      } else {
        const customer = await this.stripe.customers.create({
          email: dbUser.email,
          name: `${dbUser.firstName} ${dbUser.lastName}`,
          metadata: { userId: user.sub },
        });
        customerId = customer.id;
      }

      // Attach payment method to customer
      await this.stripe.paymentMethods.attach(dto.paymentMethodId, {
        customer: customerId,
      });

      // Set as default payment method
      await this.stripe.customers.update(customerId, {
        invoice_settings: {
          default_payment_method: dto.paymentMethodId,
        },
      });

      // Create subscription
      const stripeSubscription = await this.stripe.subscriptions.create({
        customer: customerId,
        items: [{ price: priceId }],
        payment_behavior: 'default_incomplete',
        payment_settings: {
          payment_method_types: ['card'],
          save_default_payment_method: 'on_subscription',
        },
        expand: ['latest_invoice.payment_intent'],
        metadata: { userId: user.sub, tier: dto.tier },
      });

      // Store subscription in database
      const subscription = await this.prisma.subscription.create({
        data: {
          user: { connect: { id: user.sub } },
          tier: dto.tier,
          status: this.mapStripeStatus(stripeSubscription.status),
          currentPeriodStart: new Date(stripeSubscription.current_period_start * 1000),
          currentPeriodEnd: new Date(stripeSubscription.current_period_end * 1000),
          stripeCustomerId: customerId,
          stripeSubscriptionId: stripeSubscription.id,
        },
      });

      return this.mapToDto(subscription);
    } catch (error) {
      this.logger.error('Failed to create subscription', error);
      if (error instanceof Stripe.errors.StripeError) {
        throw new BadRequestException(`Stripe error: ${error.message}`);
      }
      throw error;
    }
  }

  async getCurrentSubscription(user: JwtPayload): Promise<SubscriptionDto | null> {
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        userId: user.sub,
        status: { in: ['ACTIVE', 'PAST_DUE'] },
      },
      orderBy: { createdAt: 'desc' },
    });

    return subscription ? this.mapToDto(subscription) : null;
  }

  async cancelSubscription(
    user: JwtPayload,
    cancelAtPeriodEnd = true,
  ): Promise<SubscriptionDto> {
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        userId: user.sub,
        status: 'ACTIVE',
      },
    });

    if (!subscription) {
      throw new NotFoundException('No active subscription found');
    }

    if (subscription.stripeSubscriptionId && this.stripe) {
      await this.stripe.subscriptions.update(subscription.stripeSubscriptionId, {
        cancel_at_period_end: cancelAtPeriodEnd,
      });

      if (!cancelAtPeriodEnd) {
        await this.stripe.subscriptions.cancel(subscription.stripeSubscriptionId);
      }
    }

    const updated = await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        cancelAtPeriodEnd,
        cancelledAt: cancelAtPeriodEnd ? null : new Date(),
        status: cancelAtPeriodEnd ? 'ACTIVE' : 'CANCELLED',
      },
    });

    return this.mapToDto(updated);
  }

  // Webhook handlers
  async handleInvoicePaid(invoice: Stripe.Invoice): Promise<void> {
    this.logger.log(`Invoice paid: ${invoice.id}`);

    const subscriptionId = invoice.subscription as string;
    if (!subscriptionId) return;

    await this.prisma.subscription.updateMany({
      where: { stripeSubscriptionId: subscriptionId },
      data: { status: 'ACTIVE' },
    });
  }

  async handleInvoicePaymentFailed(invoice: Stripe.Invoice): Promise<void> {
    this.logger.warn(`Invoice payment failed: ${invoice.id}`);

    const subscriptionId = invoice.subscription as string;
    if (!subscriptionId) return;

    await this.prisma.subscription.updateMany({
      where: { stripeSubscriptionId: subscriptionId },
      data: { status: 'PAST_DUE' },
    });
  }

  async handleSubscriptionUpdated(subscription: Stripe.Subscription): Promise<void> {
    this.logger.log(`Subscription updated: ${subscription.id}`);

    const status = this.mapStripeStatus(subscription.status);
    const tierMetadata = subscription.metadata?.tier as SubscriptionTier | undefined;

    await this.prisma.subscription.updateMany({
      where: { stripeSubscriptionId: subscription.id },
      data: {
        status,
        tier: tierMetadata,
        currentPeriodStart: new Date(subscription.current_period_start * 1000),
        currentPeriodEnd: new Date(subscription.current_period_end * 1000),
        cancelAtPeriodEnd: subscription.cancel_at_period_end,
        cancelledAt: subscription.canceled_at
          ? new Date(subscription.canceled_at * 1000)
          : null,
      },
    });
  }

  async handleSubscriptionDeleted(subscription: Stripe.Subscription): Promise<void> {
    this.logger.log(`Subscription deleted: ${subscription.id}`);

    await this.prisma.subscription.updateMany({
      where: { stripeSubscriptionId: subscription.id },
      data: {
        status: 'CANCELLED',
        cancelledAt: new Date(),
      },
    });
  }

  // Helpers
  private async createFreeSubscription(userId: string): Promise<SubscriptionDto> {
    const now = new Date();
    const periodEnd = new Date(now);
    periodEnd.setFullYear(periodEnd.getFullYear() + 100); // Effectively never expires

    const subscription = await this.prisma.subscription.create({
      data: {
        user: { connect: { id: userId } },
        tier: 'FREE',
        status: 'ACTIVE',
        currentPeriodStart: now,
        currentPeriodEnd: periodEnd,
      },
    });

    return this.mapToDto(subscription);
  }

  private getPriceIdForTier(tier: SubscriptionTier): string | null {
    const priceIds: Record<SubscriptionTier, string | null> = {
      [SubscriptionTier.FREE]: null,
      [SubscriptionTier.BASIC]: this.configService.get<string>('STRIPE_PRICE_BASIC') || null,
      [SubscriptionTier.PREMIUM]: this.configService.get<string>('STRIPE_PRICE_PREMIUM') || null,
      [SubscriptionTier.ENTERPRISE]: this.configService.get<string>('STRIPE_PRICE_ENTERPRISE') || null,
    };

    return priceIds[tier];
  }

  private mapStripeStatus(status: Stripe.Subscription.Status): SubscriptionStatus {
    const statusMap: Record<string, SubscriptionStatus> = {
      active: SubscriptionStatus.ACTIVE,
      past_due: SubscriptionStatus.PAST_DUE,
      canceled: SubscriptionStatus.CANCELLED,
      unpaid: SubscriptionStatus.PAST_DUE,
      incomplete: SubscriptionStatus.ACTIVE, // Still attempting payment
      incomplete_expired: SubscriptionStatus.EXPIRED,
      trialing: SubscriptionStatus.ACTIVE,
      paused: SubscriptionStatus.CANCELLED,
    };

    return statusMap[status] || SubscriptionStatus.ACTIVE;
  }

  private mapToDto(subscription: {
    id: string;
    userId: string;
    tier: string;
    status: string;
    currentPeriodStart: Date;
    currentPeriodEnd: Date;
    stripeCustomerId: string | null;
    stripeSubscriptionId: string | null;
    cancelledAt: Date | null;
    cancelAtPeriodEnd: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): SubscriptionDto {
    return {
      id: subscription.id,
      userId: subscription.userId,
      tier: subscription.tier as SubscriptionTier,
      status: subscription.status as SubscriptionStatus,
      currentPeriodStart: subscription.currentPeriodStart,
      currentPeriodEnd: subscription.currentPeriodEnd,
      stripeCustomerId: subscription.stripeCustomerId,
      stripeSubscriptionId: subscription.stripeSubscriptionId,
      cancelledAt: subscription.cancelledAt,
      cancelAtPeriodEnd: subscription.cancelAtPeriodEnd,
      createdAt: subscription.createdAt,
      updatedAt: subscription.updatedAt,
    };
  }
}
