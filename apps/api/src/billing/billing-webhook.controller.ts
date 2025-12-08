import {
  Controller,
  Post,
  Headers,
  Req,
  HttpCode,
  HttpStatus,
  BadRequestException,
  Logger,
  RawBodyRequest,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiExcludeEndpoint } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import Stripe from 'stripe';

import { BillingService } from './billing.service';

/**
 * Stripe Webhook Controller
 *
 * This controller handles webhook events from Stripe.
 * Make sure to configure your webhook endpoint in Stripe Dashboard:
 * https://dashboard.stripe.com/webhooks
 *
 * Required events to configure:
 * - invoice.paid
 * - invoice.payment_failed
 * - customer.subscription.updated
 * - customer.subscription.deleted
 *
 * IMPORTANT: This endpoint requires the raw body for signature verification.
 * Make sure to configure Express to preserve raw body:
 *
 * In main.ts, add before other middleware:
 * ```
 * app.use('/api/billing/webhook', express.raw({ type: 'application/json' }));
 * ```
 */
@ApiTags('Billing')
@Controller('billing')
export class BillingWebhookController {
  private stripe: Stripe | null = null;
  private webhookSecret: string | null = null;
  private readonly logger = new Logger(BillingWebhookController.name);

  constructor(
    private readonly billingService: BillingService,
    private readonly configService: ConfigService,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    this.webhookSecret = this.configService.get<string>('STRIPE_WEBHOOK_SECRET') || null;

    if (secretKey) {
      this.stripe = new Stripe(secretKey, {
        apiVersion: '2024-11-20.acacia',
      });
    }
  }

  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Stripe webhook endpoint' })
  @ApiResponse({ status: 200, description: 'Webhook processed' })
  @ApiResponse({ status: 400, description: 'Invalid webhook signature' })
  @ApiExcludeEndpoint() // Hide from Swagger docs for security
  async handleWebhook(
    @Headers('stripe-signature') signature: string,
    @Req() request: RawBodyRequest<Request>,
  ): Promise<{ received: boolean }> {
    if (!this.stripe) {
      this.logger.warn('Stripe not configured, ignoring webhook');
      return { received: true };
    }

    if (!signature) {
      throw new BadRequestException('Missing stripe-signature header');
    }

    let event: Stripe.Event;

    try {
      // Get raw body for signature verification
      const rawBody = request.rawBody;

      if (!rawBody) {
        throw new BadRequestException(
          'Raw body not available. Make sure to configure raw body parsing for this endpoint.',
        );
      }

      if (this.webhookSecret) {
        // Verify webhook signature
        event = this.stripe.webhooks.constructEvent(
          rawBody,
          signature,
          this.webhookSecret,
        );
      } else {
        // If no webhook secret configured, parse the event without verification (dev only)
        this.logger.warn('STRIPE_WEBHOOK_SECRET not configured - skipping signature verification');
        event = JSON.parse(rawBody.toString()) as Stripe.Event;
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      this.logger.error(`Webhook signature verification failed: ${message}`);
      throw new BadRequestException(`Webhook Error: ${message}`);
    }

    this.logger.log(`Received Stripe webhook: ${event.type}`);

    // Handle the event
    try {
      switch (event.type) {
        case 'invoice.paid':
          await this.billingService.handleInvoicePaid(event.data.object as Stripe.Invoice);
          break;

        case 'invoice.payment_failed':
          await this.billingService.handleInvoicePaymentFailed(
            event.data.object as Stripe.Invoice,
          );
          break;

        case 'customer.subscription.updated':
          await this.billingService.handleSubscriptionUpdated(
            event.data.object as Stripe.Subscription,
          );
          break;

        case 'customer.subscription.deleted':
          await this.billingService.handleSubscriptionDeleted(
            event.data.object as Stripe.Subscription,
          );
          break;

        default:
          this.logger.log(`Unhandled event type: ${event.type}`);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Error handling webhook ${event.type}: ${message}`);
      // Don't throw - we want to return 200 to Stripe to prevent retries
      // Log the error and investigate manually
    }

    return { received: true };
  }
}
