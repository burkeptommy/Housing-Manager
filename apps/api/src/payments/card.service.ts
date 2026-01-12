import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import Stripe from 'stripe';

@Injectable()
export class CardService {
  private readonly logger = new Logger(CardService.name);
  private stripe: Stripe;
  private isTestMode: boolean;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    this.isTestMode = !secretKey || secretKey.startsWith('sk_test_');

    if (secretKey) {
      this.stripe = new Stripe(secretKey, {
        apiVersion: '2025-02-24.acacia',
      });
    }
  }

  /**
   * Create a virtual card for a household
   */
  async createHouseholdCard(householdId: string, userId: string): Promise<any> {
    this.logger.log(`Creating household card for ${householdId}`);

    // Check if card already exists
    const existing = await this.prisma.householdCard.findUnique({
      where: { householdId },
    });

    if (existing?.stripeCardId) {
      throw new BadRequestException('Household already has a card');
    }

    // Get user details for cardholder
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Get household with home profile for address
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: { homeProfile: true },
    });

    // In test mode without full Stripe Issuing, simulate card creation
    if (this.isTestMode) {
      return this.createTestCard(householdId, user);
    }

    try {
      // 1. Create cardholder in Stripe
      const cardholder = await this.stripe.issuing.cardholders.create({
        type: 'individual',
        name: `${user.firstName} ${user.lastName}`,
        email: user.email,
        phone_number: user.phone || undefined,
        billing: {
          address: {
            line1: household?.homeProfile?.addressLine1 || '123 Main St',
            city: household?.homeProfile?.city || 'New York',
            state: household?.homeProfile?.state || 'NY',
            postal_code: household?.homeProfile?.postalCode || '10001',
            country: 'US',
          },
        },
      });

      // 2. Create virtual card
      const card = await this.stripe.issuing.cards.create({
        cardholder: cardholder.id,
        type: 'virtual',
        currency: 'usd',
        status: 'active',
      });

      // 3. Save to database
      const householdCard = await this.prisma.householdCard.upsert({
        where: { householdId },
        update: {
          stripeCardholderId: cardholder.id,
          stripeCardId: card.id,
          last4: card.last4,
          expMonth: card.exp_month,
          expYear: card.exp_year,
          status: 'active',
        },
        create: {
          householdId,
          stripeCardholderId: cardholder.id,
          stripeCardId: card.id,
          last4: card.last4,
          expMonth: card.exp_month,
          expYear: card.exp_year,
          status: 'active',
        },
      });

      this.logger.log(`Created card ${card.last4} for household ${householdId}`);

      return {
        id: householdCard.id,
        last4: householdCard.last4,
        expMonth: householdCard.expMonth,
        expYear: householdCard.expYear,
        brand: householdCard.brand,
        status: householdCard.status,
      };
    } catch (error) {
      this.logger.error(`Failed to create card: ${error.message}`);
      throw new BadRequestException(`Failed to create card: ${error.message}`);
    }
  }

  /**
   * Create a test card (for sandbox mode)
   */
  private async createTestCard(householdId: string, user: any) {
    const testLast4 = Math.floor(1000 + Math.random() * 9000).toString();
    const testCardId = `ic_test_${Date.now()}`;
    const testCardholderId = `ich_test_${Date.now()}`;

    const householdCard = await this.prisma.householdCard.upsert({
      where: { householdId },
      update: {
        stripeCardholderId: testCardholderId,
        stripeCardId: testCardId,
        last4: testLast4,
        expMonth: 12,
        expYear: 2028,
        status: 'active',
      },
      create: {
        householdId,
        stripeCardholderId: testCardholderId,
        stripeCardId: testCardId,
        last4: testLast4,
        expMonth: 12,
        expYear: 2028,
        status: 'active',
      },
    });

    this.logger.log(`[TEST MODE] Created test card ${testLast4} for household ${householdId}`);

    return {
      id: householdCard.id,
      last4: householdCard.last4,
      expMonth: householdCard.expMonth,
      expYear: householdCard.expYear,
      brand: householdCard.brand,
      status: householdCard.status,
      isTestMode: true,
    };
  }

  /**
   * Get card details for a household
   */
  async getHouseholdCard(householdId: string) {
    const card = await this.prisma.householdCard.findUnique({
      where: { householdId },
    });

    if (!card) {
      return null;
    }

    return {
      id: card.id,
      last4: card.last4,
      expMonth: card.expMonth,
      expYear: card.expYear,
      brand: card.brand,
      status: card.status,
      fundingStatus: card.fundingStatus,
      hasCard: !!card.stripeCardId,
    };
  }

  /**
   * Get full card details (for making payments) - SECURE
   */
  async getCardDetailsForPayment(householdId: string) {
    const card = await this.prisma.householdCard.findUnique({
      where: { householdId },
    });

    if (!card?.stripeCardId) {
      throw new BadRequestException('No card found for household');
    }

    if (this.isTestMode) {
      // Return test card details
      return {
        number: '4242424242424242',
        cvc: '123',
        expMonth: card.expMonth,
        expYear: card.expYear,
        isTestMode: true,
      };
    }

    // Get real card details from Stripe
    const stripeCard = await this.stripe.issuing.cards.retrieve(
      card.stripeCardId,
      { expand: ['number', 'cvc'] }
    );

    return {
      number: (stripeCard as any).number,
      cvc: (stripeCard as any).cvc,
      expMonth: stripeCard.exp_month,
      expYear: stripeCard.exp_year,
    };
  }

  /**
   * Link funding source (Plaid account) to card
   */
  async linkFundingSource(householdId: string, plaidAccountId: string) {
    const card = await this.prisma.householdCard.update({
      where: { householdId },
      data: {
        plaidAccountId,
        fundingStatus: 'connected',
      },
    });

    this.logger.log(`Linked funding source ${plaidAccountId} to card for ${householdId}`);

    return card;
  }

  /**
   * Freeze a card (for security)
   */
  async freezeCard(householdId: string) {
    const card = await this.prisma.householdCard.findUnique({
      where: { householdId },
    });

    if (!card?.stripeCardId) {
      throw new BadRequestException('No card found');
    }

    if (!this.isTestMode && this.stripe) {
      await this.stripe.issuing.cards.update(card.stripeCardId, {
        status: 'inactive',
      });
    }

    return this.prisma.householdCard.update({
      where: { householdId },
      data: { status: 'frozen' },
    });
  }

  /**
   * Unfreeze a card
   */
  async unfreezeCard(householdId: string) {
    const card = await this.prisma.householdCard.findUnique({
      where: { householdId },
    });

    if (!card?.stripeCardId) {
      throw new BadRequestException('No card found');
    }

    if (!this.isTestMode && this.stripe) {
      await this.stripe.issuing.cards.update(card.stripeCardId, {
        status: 'active',
      });
    }

    return this.prisma.householdCard.update({
      where: { householdId },
      data: { status: 'active' },
    });
  }
}
