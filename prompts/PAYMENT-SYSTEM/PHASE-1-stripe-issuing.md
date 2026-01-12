# PHASE 1: Stripe Issuing Integration (Virtual Cards)

## OVERVIEW
Implement Stripe Issuing to create virtual cards for households. These cards are used to pay vendors automatically.

**Business Logic:** When a user signs up, Haven creates a virtual VISA card linked to their bank account (via Plaid). When bills are due, Haven charges the virtual card, which pulls funds from the user's bank via ACH.

---

## STEP 1: Add Prisma Models

Edit `/Users/tomburke/Projects/Housing-Manager/apps/api/prisma/schema.prisma`

Add these models:

```prisma
// ============================================================================
// PAYMENT SYSTEM MODELS
// ============================================================================

model HouseholdCard {
  id                  String   @id @default(cuid())
  householdId         String   @unique
  household           Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  // Stripe Issuing
  stripeCardholderId  String?
  stripeCardId        String?  @unique
  last4               String?
  expMonth            Int?
  expYear             Int?
  brand               String   @default("visa")
  status              String   @default("pending") // pending, active, frozen, cancelled
  
  // Funding source (linked via Plaid)
  plaidAccountId      String?  // Primary funding source
  fundingStatus       String   @default("not_connected") // not_connected, connected, error
  
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt
}

model Bill {
  id                  String   @id @default(cuid())
  householdId         String
  household           Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  // Vendor link (optional - some bills aren't tied to vendors in our system)
  vendorId            String?
  vendor              HouseholdVendor? @relation(fields: [vendorId], references: [id])
  
  // Bill details
  name                String
  description         String?
  category            String   // utility, insurance, mortgage, service, subscription, tax, other
  
  // Amount handling
  amount              Float?   // Null if variable
  isVariableAmount    Boolean  @default(false)
  averageAmount       Float?   // For variable bills, historical average
  lastKnownAmount     Float?
  
  // Schedule
  frequency           String   // weekly, biweekly, monthly, quarterly, semi_annual, annual, one_time
  dueDay              Int?     // Day of month (1-31)
  seasonStart         Int?     // Month (1-12) if seasonal
  seasonEnd           Int?     // Month (1-12) if seasonal
  nextDueDate         DateTime?
  
  // Payment method
  paymentMethod       String   // card, check_digital, check_physical, manual
  paymentPortalUrl    String?  // URL to pay online (for card payments)
  paymentEmail        String?  // Vendor email (for digital checks)
  mailingAddress      String?  // Vendor address (for physical checks)
  accountNumber       String?  // User's account number WITH the vendor
  
  // Autopay settings
  autopayEnabled      Boolean  @default(true)
  requiresApproval    Boolean  @default(false)
  approvalThreshold   Float?   // Require approval if amount exceeds this
  daysBeforeDue       Int      @default(5) // Pay this many days before due date
  
  // Risk/Priority
  priority            String   @default("normal") // critical, high, normal, low
  
  // Status
  status              String   @default("active") // active, paused, cancelled
  
  // Source tracking
  sourceType          String   @default("manual") // manual, plaid_detected, alfred
  detectedBillId      String?  // Link to DetectedBill if created from detection
  
  // Relationships
  payments            BillPayment[]
  approvals           PaymentApproval[]
  
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt
  
  @@index([householdId, status])
  @@index([nextDueDate])
}

model BillPayment {
  id                  String   @id @default(cuid())
  billId              String
  bill                Bill     @relation(fields: [billId], references: [id], onDelete: Cascade)
  householdId         String
  
  // Payment details
  amount              Float
  status              String   @default("pending") // pending, processing, completed, failed, cancelled
  paymentMethod       String   // card, check_digital, check_physical
  
  // Stripe (for card payments)
  stripePaymentId     String?
  stripeAuthId        String?
  
  // Checkbook.io (for check payments)
  checkbookCheckId    String?
  checkNumber         String?
  checkTrackingNumber String?
  
  // Timing
  scheduledDate       DateTime
  processedDate       DateTime?
  confirmedDate       DateTime?
  
  // Error handling
  failureReason       String?
  retryCount          Int      @default(0)
  maxRetries          Int      @default(3)
  
  // Approval link
  approvalId          String?
  
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt
  
  @@index([householdId, status])
  @@index([scheduledDate])
}

model PaymentApproval {
  id                  String   @id @default(cuid())
  householdId         String
  household           Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  billId              String
  bill                Bill     @relation(fields: [billId], references: [id], onDelete: Cascade)
  
  // Approval details
  amount              Float
  reason              String   // high_amount, first_payment, anomaly, critical_bill, manual_request
  
  // Status
  status              String   @default("pending") // pending, approved, denied, expired, auto_approved
  
  // Timing
  requestedAt         DateTime @default(now())
  respondedAt         DateTime?
  expiresAt           DateTime
  
  // Who responded
  respondedBy         String?  // User ID
  responseNote        String?
  
  // Resulting payment
  paymentId           String?
  
  createdAt           DateTime @default(now())
  
  @@index([householdId, status])
  @@index([expiresAt])
}

model ServiceRequest {
  id                  String   @id @default(cuid())
  householdId         String
  household           Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  userId              String   // User who created the request
  
  // Request details
  type                String   // negotiate, dispute, research, setup, cancel, find_vendor, other
  title               String
  description         String
  
  // Related entities
  billId              String?
  vendorId            String?
  
  // Assignment (Haven team)
  assignedTo          String?
  
  // Status
  status              String   @default("new") // new, in_progress, waiting_user, waiting_vendor, resolved, cancelled
  priority            String   @default("normal") // low, normal, high, urgent
  
  // Outcome
  resolution          String?
  savingsAmount       Float?   // If negotiation resulted in savings
  
  // Timestamps
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt
  resolvedAt          DateTime?
  
  @@index([householdId, status])
}
```

Also add the relations to the existing Household model:

```prisma
model Household {
  // ... existing fields ...
  
  // Add these relations
  card                HouseholdCard?
  bills               Bill[]
  paymentApprovals    PaymentApproval[]
  serviceRequests     ServiceRequest[]
}
```

And add to HouseholdVendor:

```prisma
model HouseholdVendor {
  // ... existing fields ...
  
  // Add this relation
  bills               Bill[]
}
```

---

## STEP 2: Run Migration

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name payment_system_models
pnpm prisma generate
```

---

## STEP 3: Create Card Service

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/card.service.ts`:

```typescript
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
        apiVersion: '2024-12-18.acacia',
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
      include: { household: true },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

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
            line1: user.household?.address || '123 Main St',
            city: user.household?.city || 'New York',
            state: user.household?.state || 'NY',
            postal_code: user.household?.zipCode || '10001',
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
```

---

## STEP 4: Create Card Controller

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/card.controller.ts`:

```typescript
import { Controller, Post, Get, Param, UseGuards, Req } from '@nestjs/common';
import { CardService } from './card.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

@Controller('payments/card')
@UseGuards(FirebaseAuthGuard)
export class CardController {
  constructor(private cardService: CardService) {}

  @Post('create')
  async createCard(@Req() req: any) {
    const { householdId, id: userId } = req.user;
    return this.cardService.createHouseholdCard(householdId, userId);
  }

  @Get()
  async getCard(@Req() req: any) {
    const { householdId } = req.user;
    return this.cardService.getHouseholdCard(householdId);
  }

  @Post('freeze')
  async freezeCard(@Req() req: any) {
    const { householdId } = req.user;
    return this.cardService.freezeCard(householdId);
  }

  @Post('unfreeze')
  async unfreezeCard(@Req() req: any) {
    const { householdId } = req.user;
    return this.cardService.unfreezeCard(householdId);
  }

  @Post('link-funding/:plaidAccountId')
  async linkFunding(@Req() req: any, @Param('plaidAccountId') plaidAccountId: string) {
    const { householdId } = req.user;
    return this.cardService.linkFundingSource(householdId, plaidAccountId);
  }
}
```

---

## STEP 5: Create Payments Module

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/payments/payments.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { CardService } from './card.service';
import { CardController } from './card.controller';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [CardController],
  providers: [CardService],
  exports: [CardService],
})
export class PaymentsModule {}
```

---

## STEP 6: Register Module in App

Edit `/Users/tomburke/Projects/Housing-Manager/apps/api/src/app.module.ts`:

Add the PaymentsModule to imports:

```typescript
import { PaymentsModule } from './payments/payments.module';

@Module({
  imports: [
    // ... existing imports ...
    PaymentsModule,
  ],
})
export class AppModule {}
```

---

## STEP 7: Test Locally

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm dev
```

Test the endpoints:
```bash
# Create a card (need auth token)
curl -X POST http://localhost:4000/api/payments/card/create \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get card details
curl http://localhost:4000/api/payments/card \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## VERIFICATION CHECKLIST

- [ ] Prisma models added and migrated
- [ ] CardService created with test mode support
- [ ] CardController created
- [ ] PaymentsModule registered in AppModule
- [ ] API starts without errors
- [ ] Can create test card via API

---

## NEXT STEP

Proceed to PHASE-2-bill-service.md
