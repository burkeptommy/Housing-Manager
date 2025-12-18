import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

export interface StripeTransferRequest {
  stripeConnectId: string;
  amount: number; // Amount in dollars
  description?: string;
  metadata?: Record<string, string>;
}

export interface StripeTransferResponse {
  transferId: string;
  status: 'pending' | 'paid' | 'failed' | 'canceled';
  amount: number;
  currency: string;
  destinationAccountId: string;
  created: Date;
}

/**
 * StripePayoutService - Handles Stripe Connect transfers to vendor accounts
 *
 * Business Model: Haven pays vendors immediately ("The Float").
 * For vendors with Stripe Connect accounts, we transfer funds instantly.
 *
 * Flow:
 * 1. Vendor onboards via Stripe Connect Express
 * 2. Haven stores their Stripe Connect Account ID
 * 3. When paying, we create a Transfer from our platform to their account
 */
@Injectable()
export class StripePayoutService {
  private readonly logger = new Logger(StripePayoutService.name);
  private stripe: Stripe | null = null;
  private readonly isTestMode: boolean;

  constructor(private readonly configService: ConfigService) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    this.isTestMode = !secretKey || secretKey.startsWith('sk_test_');

    if (secretKey) {
      this.stripe = new Stripe(secretKey, {
        apiVersion: '2025-02-24.acacia',
      });
    }
  }

  /**
   * Transfer funds to a vendor's Stripe Connect account
   *
   * @param request - Transfer request with Connect account ID and amount
   * @returns Transfer response with status
   */
  async transferFunds(request: StripeTransferRequest): Promise<StripeTransferResponse> {
    this.logger.log(
      `Transferring $${request.amount} to Stripe Connect account ${request.stripeConnectId}`
    );

    // Simulate if no Stripe client or in test mode without real keys
    if (!this.stripe) {
      return this.simulateTransfer(request);
    }

    try {
      // Convert dollars to cents for Stripe
      const amountInCents = Math.round(request.amount * 100);

      const transfer = await this.stripe.transfers.create({
        amount: amountInCents,
        currency: 'usd',
        destination: request.stripeConnectId,
        description: request.description || 'Payment from Haven Home Management',
        metadata: {
          source: 'haven_payment_rails',
          ...request.metadata,
        },
      });

      return {
        transferId: transfer.id,
        status: this.mapStripeStatus(transfer),
        amount: transfer.amount / 100, // Convert back to dollars
        currency: transfer.currency,
        destinationAccountId: transfer.destination as string,
        created: new Date(transfer.created * 1000),
      };
    } catch (error) {
      this.logger.error(`Stripe transfer failed: ${error}`);

      if (error instanceof Stripe.errors.StripeError) {
        throw new Error(`Stripe error: ${error.message}`);
      }

      throw error;
    }
  }

  /**
   * Get the status of a transfer
   */
  async getTransferStatus(transferId: string): Promise<StripeTransferResponse> {
    if (!this.stripe) {
      return {
        transferId,
        status: 'paid',
        amount: 0,
        currency: 'usd',
        destinationAccountId: 'acct_test',
        created: new Date(),
      };
    }

    const transfer = await this.stripe.transfers.retrieve(transferId);

    return {
      transferId: transfer.id,
      status: this.mapStripeStatus(transfer),
      amount: transfer.amount / 100,
      currency: transfer.currency,
      destinationAccountId: transfer.destination as string,
      created: new Date(transfer.created * 1000),
    };
  }

  /**
   * Reverse a transfer (for refunds/corrections)
   */
  async reverseTransfer(
    transferId: string,
    amount?: number
  ): Promise<{ reversalId: string; status: string }> {
    if (!this.stripe) {
      return {
        reversalId: `trr_test_${Date.now()}`,
        status: 'succeeded',
      };
    }

    const reversal = await this.stripe.transfers.createReversal(transferId, {
      amount: amount ? Math.round(amount * 100) : undefined,
    });

    return {
      reversalId: reversal.id,
      status: 'succeeded',
    };
  }

  /**
   * Check if a Stripe Connect account can receive transfers
   */
  async verifyConnectAccount(accountId: string): Promise<{
    isValid: boolean;
    canReceivePayments: boolean;
    accountType: string;
    displayName?: string;
  }> {
    if (!this.stripe) {
      return {
        isValid: true,
        canReceivePayments: true,
        accountType: 'express',
        displayName: 'Test Account',
      };
    }

    try {
      const account = await this.stripe.accounts.retrieve(accountId);

      return {
        isValid: true,
        canReceivePayments: account.payouts_enabled || false,
        accountType: account.type || 'unknown',
        displayName: account.business_profile?.name || account.email || undefined,
      };
    } catch {
      return {
        isValid: false,
        canReceivePayments: false,
        accountType: 'unknown',
      };
    }
  }

  /**
   * Create a Stripe Connect onboarding link for a vendor
   */
  async createOnboardingLink(
    accountId: string,
    returnUrl: string,
    refreshUrl: string
  ): Promise<string> {
    if (!this.stripe) {
      return 'https://connect.stripe.com/test/onboarding';
    }

    const accountLink = await this.stripe.accountLinks.create({
      account: accountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: 'account_onboarding',
    });

    return accountLink.url;
  }

  /**
   * Create a new Stripe Connect Express account for a vendor
   */
  async createConnectAccount(
    email: string,
    businessName?: string
  ): Promise<{ accountId: string; onboardingUrl?: string }> {
    if (!this.stripe) {
      const testAccountId = `acct_test_${Date.now()}`;
      return {
        accountId: testAccountId,
        onboardingUrl: 'https://connect.stripe.com/test/onboarding',
      };
    }

    const account = await this.stripe.accounts.create({
      type: 'express',
      email,
      business_profile: businessName ? { name: businessName } : undefined,
      capabilities: {
        transfers: { requested: true },
      },
    });

    return {
      accountId: account.id,
    };
  }

  private mapStripeStatus(transfer: Stripe.Transfer): StripeTransferResponse['status'] {
    // Stripe transfers don't have a simple status - we infer from reversed flag
    if (transfer.reversed) {
      return 'canceled';
    }
    // If transfer exists and not reversed, it's essentially complete
    return 'paid';
  }

  /**
   * Simulate transfer for test mode
   */
  private simulateTransfer(request: StripeTransferRequest): StripeTransferResponse {
    const transferId = `tr_test_${Date.now()}_${Math.random().toString(36).substring(7)}`;

    this.logger.log(
      `[TEST MODE] Simulated transfer ${transferId} for $${request.amount} to ${request.stripeConnectId}`
    );

    return {
      transferId,
      status: 'paid',
      amount: request.amount,
      currency: 'usd',
      destinationAccountId: request.stripeConnectId,
      created: new Date(),
    };
  }
}
