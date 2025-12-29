# Haven: Plaid Integration (Complete)

**Created:** December 28, 2024  
**Updated:** December 28, 2024  
**Purpose:** Auto-detect bills AND checks from bank transactions  
**Priority:** P0 - The "magic" that eliminates manual bill entry

---

## CRITICAL RULES

1. **DO NOT DELETE existing code** - Only add and refactor
2. **Detect CHECKS too** - For checkbook.io integration (landscapers, housekeepers, etc.)
3. **Multiple touchpoints** - Onboarding + Settings + Money section

---

## Overview

Plaid integration allows users to:
1. Connect bank accounts during onboarding (optional but encouraged)
2. Manage connected banks from Settings
3. Auto-detect recurring charges AND checks
4. Review and confirm detected bills

**Check Detection is Critical:** Many household services (landscapers, housekeepers, some HOAs) only accept checks. We detect these patterns so checkbook.io can automate them later.

---

## PHASE 1: Database Schema

### Task 1.1: Create Plaid Models

Add to `apps/api/prisma/schema.prisma`:

```prisma
model PlaidConnection {
  id              String    @id @default(uuid())
  householdId     String
  household       Household @relation(fields: [householdId], references: [id])
  
  // Plaid tokens
  accessToken     String
  itemId          String
  
  // Institution info
  institutionId   String?
  institutionName String?
  institutionLogo String?
  
  // Connection status
  status          PlaidConnectionStatus @default(ACTIVE)
  lastSyncedAt    DateTime?
  lastSyncError   String?
  
  // Linked accounts
  accounts        PlaidAccount[]
  
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
  
  @@unique([householdId, itemId])
  @@index([householdId])
}

model PlaidAccount {
  id                String          @id @default(uuid())
  connectionId      String
  connection        PlaidConnection @relation(fields: [connectionId], references: [id], onDelete: Cascade)
  
  plaidAccountId    String
  name              String
  officialName      String?
  type              String          // checking, savings, credit
  subtype           String?
  mask              String?         // Last 4 digits
  
  currentBalance    Float?
  availableBalance  Float?
  
  detectedBills     DetectedBill[]
  
  createdAt         DateTime        @default(now())
  updatedAt         DateTime        @updatedAt
  
  @@unique([connectionId, plaidAccountId])
}

model DetectedBill {
  id              String        @id @default(uuid())
  householdId     String
  household       Household     @relation(fields: [householdId], references: [id])
  accountId       String?
  account         PlaidAccount? @relation(fields: [accountId], references: [id], onDelete: SetNull)
  
  // Detection source
  detectionType   DetectionType @default(RECURRING_CHARGE)
  
  // Bill details
  merchantName    String
  normalizedName  String
  category        BillCategory  @default(OTHER)
  
  // Amount pattern
  averageAmount   Float
  lastAmount      Float
  frequency       BillingFrequency @default(MONTHLY)
  
  // For checks - additional info
  checkNumber     String?       // If detected from check
  checkPayee      String?       // Payee name from check
  
  // Timing
  lastTransactionDate DateTime
  nextExpectedDate    DateTime?
  dayOfMonth          Int?
  
  // User actions
  status          DetectedBillStatus @default(PENDING)
  linkedBillId    String?
  
  // Evidence
  transactionIds  String[]
  transactionCount Int          @default(0)
  confidence      Float         @default(0.8)  // How confident we are this is a bill
  
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt
  
  @@index([householdId])
  @@index([status])
}

enum PlaidConnectionStatus {
  ACTIVE
  ERROR
  DISCONNECTED
  PENDING_REAUTH
}

enum DetectionType {
  RECURRING_CHARGE    // Regular merchant charge
  RECURRING_CHECK     // Check written to same payee
  RECURRING_ACH       // ACH/direct debit
  RECURRING_TRANSFER  // Transfer to same account
}

enum DetectedBillStatus {
  PENDING
  CONFIRMED
  DISMISSED
  IGNORED
}

enum BillCategory {
  MORTGAGE
  RENT
  HOA
  PROPERTY_TAX
  UTILITIES_ELECTRIC
  UTILITIES_GAS
  UTILITIES_WATER
  UTILITIES_TRASH
  INTERNET
  PHONE
  CABLE
  INSURANCE_HOME
  INSURANCE_AUTO
  INSURANCE_LIFE
  INSURANCE_UMBRELLA
  SUBSCRIPTION
  STREAMING
  GYM
  CHILDCARE
  TUITION
  LANDSCAPING
  HOUSEKEEPING
  POOL_SERVICE
  PEST_CONTROL
  SECURITY
  LOAN_AUTO
  LOAN_STUDENT
  LOAN_PERSONAL
  CREDIT_CARD
  OTHER
}

enum BillingFrequency {
  WEEKLY
  BIWEEKLY
  MONTHLY
  QUARTERLY
  SEMI_ANNUAL
  ANNUAL
  IRREGULAR
}
```

### Task 1.2: Update Household Model

```prisma
model Household {
  // ... existing fields
  plaidConnections PlaidConnection[]
  detectedBills    DetectedBill[]
}
```

### Task 1.3: Run Migration

```bash
cd apps/api
pnpm prisma migrate dev --name add-plaid-integration
pnpm prisma generate
```

---

## PHASE 2: Plaid Service

### Task 2.1: Install Plaid SDK

```bash
cd apps/api
pnpm add plaid
```

### Task 2.2: Create Plaid Service

Create `apps/api/src/plaid/plaid.service.ts`:

```typescript
import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  Configuration,
  PlaidApi,
  PlaidEnvironments,
  Products,
  CountryCode,
} from 'plaid';
import { BillCategory, BillingFrequency, DetectionType } from '@prisma/client';

@Injectable()
export class PlaidService {
  private readonly logger = new Logger(PlaidService.name);
  private plaidClient: PlaidApi;

  constructor(private prisma: PrismaService) {
    const configuration = new Configuration({
      basePath: PlaidEnvironments[process.env.PLAID_ENV || 'sandbox'],
      baseOptions: {
        headers: {
          'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
          'PLAID-SECRET': process.env.PLAID_SECRET,
        },
      },
    });
    this.plaidClient = new PlaidApi(configuration);
  }

  /**
   * Create a link token for Plaid Link
   */
  async createLinkToken(userId: string, householdId: string): Promise<string> {
    try {
      const response = await this.plaidClient.linkTokenCreate({
        user: { client_user_id: `${householdId}-${userId}` },
        client_name: 'Haven',
        products: [Products.Transactions],
        country_codes: [CountryCode.Us],
        language: 'en',
      });

      return response.data.link_token;
    } catch (error: any) {
      this.logger.error('Error creating link token:', error?.response?.data || error);
      throw new BadRequestException('Failed to create link token');
    }
  }

  /**
   * Exchange public token for access token
   */
  async exchangePublicToken(
    householdId: string,
    publicToken: string
  ): Promise<{ connectionId: string; accountCount: number }> {
    try {
      // Exchange token
      const exchangeResponse = await this.plaidClient.itemPublicTokenExchange({
        public_token: publicToken,
      });

      const accessToken = exchangeResponse.data.access_token;
      const itemId = exchangeResponse.data.item_id;

      // Get institution info
      const itemResponse = await this.plaidClient.itemGet({ access_token: accessToken });
      const institutionId = itemResponse.data.item.institution_id;

      let institutionName = 'Unknown Bank';
      let institutionLogo = null;
      
      if (institutionId) {
        try {
          const instResponse = await this.plaidClient.institutionsGetById({
            institution_id: institutionId,
            country_codes: [CountryCode.Us],
            options: { include_optional_metadata: true },
          });
          institutionName = instResponse.data.institution.name;
          institutionLogo = instResponse.data.institution.logo || null;
        } catch (e) {
          this.logger.warn('Could not get institution details');
        }
      }

      // Get accounts
      const accountsResponse = await this.plaidClient.accountsGet({
        access_token: accessToken,
      });

      // Save connection
      const connection = await this.prisma.plaidConnection.create({
        data: {
          householdId,
          accessToken,
          itemId,
          institutionId,
          institutionName,
          institutionLogo,
          status: 'ACTIVE',
          accounts: {
            create: accountsResponse.data.accounts.map((account) => ({
              plaidAccountId: account.account_id,
              name: account.name,
              officialName: account.official_name || null,
              type: account.type,
              subtype: account.subtype || null,
              mask: account.mask || null,
              currentBalance: account.balances.current,
              availableBalance: account.balances.available,
            })),
          },
        },
        include: { accounts: true },
      });

      // Trigger initial transaction sync
      await this.syncTransactions(connection.id);

      return {
        connectionId: connection.id,
        accountCount: connection.accounts.length,
      };
    } catch (error: any) {
      this.logger.error('Error exchanging token:', error?.response?.data || error);
      throw new BadRequestException('Failed to connect bank account');
    }
  }

  /**
   * Sync transactions and detect recurring bills + checks
   */
  async syncTransactions(connectionId: string): Promise<{ bills: number; checks: number }> {
    const connection = await this.prisma.plaidConnection.findUnique({
      where: { id: connectionId },
      include: { accounts: true },
    });

    if (!connection) {
      throw new BadRequestException('Connection not found');
    }

    try {
      // Get 90 days of transactions
      const endDate = new Date().toISOString().split('T')[0];
      const startDate = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
        .toISOString()
        .split('T')[0];

      const response = await this.plaidClient.transactionsGet({
        access_token: connection.accessToken,
        start_date: startDate,
        end_date: endDate,
        options: { include_personal_finance_category: true },
      });

      const transactions = response.data.transactions;

      // Update sync time
      await this.prisma.plaidConnection.update({
        where: { id: connectionId },
        data: { lastSyncedAt: new Date(), lastSyncError: null, status: 'ACTIVE' },
      });

      // Analyze for recurring patterns
      const detectedItems = this.analyzeTransactions(
        transactions,
        connection.householdId,
        connection.accounts
      );

      // Save detected bills
      let billCount = 0;
      let checkCount = 0;

      for (const item of detectedItems) {
        const existing = await this.prisma.detectedBill.findFirst({
          where: {
            householdId: connection.householdId,
            normalizedName: item.normalizedName,
            detectionType: item.detectionType,
          },
        });

        if (!existing) {
          await this.prisma.detectedBill.create({ data: item });
          if (item.detectionType === 'RECURRING_CHECK') {
            checkCount++;
          } else {
            billCount++;
          }
        } else {
          await this.prisma.detectedBill.update({
            where: { id: existing.id },
            data: {
              lastAmount: item.lastAmount,
              lastTransactionDate: item.lastTransactionDate,
              transactionCount: item.transactionCount,
              transactionIds: item.transactionIds,
            },
          });
        }
      }

      this.logger.log(
        `Detected ${billCount} bills and ${checkCount} check patterns for household ${connection.householdId}`
      );

      return { bills: billCount, checks: checkCount };
    } catch (error: any) {
      this.logger.error('Error syncing transactions:', error);

      await this.prisma.plaidConnection.update({
        where: { id: connectionId },
        data: {
          status: 'ERROR',
          lastSyncError: error?.response?.data?.error_message || error.message,
        },
      });

      throw new BadRequestException('Failed to sync transactions');
    }
  }

  /**
   * Analyze transactions for recurring patterns (bills AND checks)
   */
  private analyzeTransactions(
    transactions: any[],
    householdId: string,
    accounts: any[]
  ): any[] {
    const detected: any[] = [];

    // Group by type: regular charges vs checks
    const regularCharges = new Map<string, any[]>();
    const checkPayments = new Map<string, any[]>();

    for (const tx of transactions) {
      if (tx.amount <= 0) continue; // Skip credits

      // Detect if this is a check
      const isCheck = this.isCheckTransaction(tx);

      if (isCheck) {
        const payee = this.extractCheckPayee(tx);
        const key = this.normalizePayeeName(payee);
        if (!checkPayments.has(key)) checkPayments.set(key, []);
        checkPayments.get(key)!.push({ ...tx, checkPayee: payee });
      } else {
        const key = this.normalizeMerchantName(tx.merchant_name || tx.name);
        if (!regularCharges.has(key)) regularCharges.set(key, []);
        regularCharges.get(key)!.push(tx);
      }
    }

    // Analyze regular charges
    for (const [normalizedName, txs] of regularCharges) {
      if (txs.length < 2) continue;

      const analysis = this.analyzeRecurrence(txs);
      if (!analysis) continue;

      const accountId = accounts.find(a => a.plaidAccountId === txs[0].account_id)?.id;

      detected.push({
        householdId,
        accountId,
        detectionType: 'RECURRING_CHARGE' as DetectionType,
        merchantName: txs[0].merchant_name || txs[0].name,
        normalizedName,
        category: this.categorizeTransaction(txs[0], normalizedName),
        averageAmount: analysis.averageAmount,
        lastAmount: analysis.lastAmount,
        frequency: analysis.frequency,
        lastTransactionDate: analysis.lastDate,
        nextExpectedDate: analysis.nextExpectedDate,
        dayOfMonth: analysis.dayOfMonth,
        status: 'PENDING',
        transactionIds: txs.map(t => t.transaction_id),
        transactionCount: txs.length,
        confidence: analysis.confidence,
      });
    }

    // Analyze check payments
    for (const [normalizedName, txs] of checkPayments) {
      if (txs.length < 2) continue;

      const analysis = this.analyzeRecurrence(txs);
      if (!analysis) continue;

      const accountId = accounts.find(a => a.plaidAccountId === txs[0].account_id)?.id;

      detected.push({
        householdId,
        accountId,
        detectionType: 'RECURRING_CHECK' as DetectionType,
        merchantName: txs[0].checkPayee || txs[0].name,
        normalizedName,
        category: this.categorizeCheckPayee(txs[0].checkPayee || ''),
        checkPayee: txs[0].checkPayee,
        averageAmount: analysis.averageAmount,
        lastAmount: analysis.lastAmount,
        frequency: analysis.frequency,
        lastTransactionDate: analysis.lastDate,
        nextExpectedDate: analysis.nextExpectedDate,
        dayOfMonth: analysis.dayOfMonth,
        status: 'PENDING',
        transactionIds: txs.map(t => t.transaction_id),
        transactionCount: txs.length,
        confidence: analysis.confidence * 0.9, // Slightly lower confidence for checks
      });
    }

    return detected.sort((a, b) => b.averageAmount - a.averageAmount);
  }

  /**
   * Detect if a transaction is a check
   */
  private isCheckTransaction(tx: any): boolean {
    const name = (tx.name || '').toLowerCase();
    const merchantName = (tx.merchant_name || '').toLowerCase();
    
    // Common check indicators
    if (name.includes('check') || name.includes('chk')) return true;
    if (name.match(/^check\s*#?\d+/i)) return true;
    if (tx.payment_channel === 'other' && !merchantName) return true;
    if (tx.transaction_type === 'special' && name.match(/^\d+$/)) return true;
    
    // Check number pattern
    if (name.match(/^#?\d{3,6}$/)) return true;
    
    return false;
  }

  /**
   * Extract payee name from check transaction
   */
  private extractCheckPayee(tx: any): string {
    // Try to get from memo or name
    const name = tx.name || '';
    
    // Remove check number prefix
    let payee = name.replace(/^(check\s*#?\d+\s*[-:]?\s*)/i, '');
    payee = payee.replace(/^#?\d+\s*[-:]?\s*/, '');
    
    // Clean up
    payee = payee.trim();
    
    return payee || 'Unknown Payee';
  }

  /**
   * Normalize payee name for grouping checks
   */
  private normalizePayeeName(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
  }

  /**
   * Normalize merchant name for grouping
   */
  private normalizeMerchantName(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '')
      .replace(/\d{4,}/g, '') // Remove long numbers (transaction IDs)
      .trim();
  }

  /**
   * Analyze recurrence pattern
   */
  private analyzeRecurrence(txs: any[]): any {
    const amounts = txs.map(t => t.amount);
    const avgAmount = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const variance = this.calculateVariance(amounts);
    
    // Amount should be somewhat consistent (within 30% for bills)
    const isConsistent = variance < avgAmount * 0.3;
    if (!isConsistent && txs.length < 3) return null;

    const dates = txs
      .map(t => new Date(t.date))
      .sort((a, b) => a.getTime() - b.getTime());
    
    const frequency = this.detectFrequency(dates);
    const sortedTxs = txs.sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
    );

    return {
      averageAmount: Math.round(avgAmount * 100) / 100,
      lastAmount: sortedTxs[0].amount,
      frequency,
      lastDate: new Date(sortedTxs[0].date),
      nextExpectedDate: this.predictNextDate(dates, frequency),
      dayOfMonth: frequency === 'MONTHLY' ? new Date(sortedTxs[0].date).getDate() : null,
      confidence: isConsistent ? 0.9 : 0.7,
    };
  }

  private calculateVariance(amounts: number[]): number {
    const avg = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const squareDiffs = amounts.map(a => Math.pow(a - avg, 2));
    return Math.sqrt(squareDiffs.reduce((a, b) => a + b, 0) / amounts.length);
  }

  private detectFrequency(dates: Date[]): BillingFrequency {
    if (dates.length < 2) return 'IRREGULAR';

    const gaps: number[] = [];
    for (let i = 1; i < dates.length; i++) {
      const daysDiff = Math.round(
        (dates[i].getTime() - dates[i - 1].getTime()) / (1000 * 60 * 60 * 24)
      );
      gaps.push(daysDiff);
    }

    const avgGap = gaps.reduce((a, b) => a + b, 0) / gaps.length;

    if (avgGap >= 5 && avgGap <= 9) return 'WEEKLY';
    if (avgGap >= 12 && avgGap <= 16) return 'BIWEEKLY';
    if (avgGap >= 25 && avgGap <= 35) return 'MONTHLY';
    if (avgGap >= 85 && avgGap <= 100) return 'QUARTERLY';
    if (avgGap >= 170 && avgGap <= 200) return 'SEMI_ANNUAL';
    if (avgGap >= 350 && avgGap <= 380) return 'ANNUAL';

    return 'IRREGULAR';
  }

  private predictNextDate(dates: Date[], frequency: BillingFrequency): Date | null {
    if (dates.length === 0) return null;
    const lastDate = new Date(dates[dates.length - 1]);

    switch (frequency) {
      case 'WEEKLY': lastDate.setDate(lastDate.getDate() + 7); break;
      case 'BIWEEKLY': lastDate.setDate(lastDate.getDate() + 14); break;
      case 'MONTHLY': lastDate.setMonth(lastDate.getMonth() + 1); break;
      case 'QUARTERLY': lastDate.setMonth(lastDate.getMonth() + 3); break;
      case 'SEMI_ANNUAL': lastDate.setMonth(lastDate.getMonth() + 6); break;
      case 'ANNUAL': lastDate.setFullYear(lastDate.getFullYear() + 1); break;
      default: return null;
    }

    return lastDate;
  }

  /**
   * Categorize regular merchant transaction
   */
  private categorizeTransaction(tx: any, normalizedName: string): BillCategory {
    const name = normalizedName.toLowerCase();
    const category = tx.personal_finance_category?.primary?.toLowerCase() || '';

    // Streaming services
    if (name.includes('netflix') || name.includes('hulu') || name.includes('disney') ||
        name.includes('hbo') || name.includes('spotify') || name.includes('apple')) {
      return 'STREAMING';
    }
    // Phone
    if (name.includes('verizon') || name.includes('att') || name.includes('tmobile') ||
        name.includes('sprint')) {
      return 'PHONE';
    }
    // Internet/Cable
    if (name.includes('comcast') || name.includes('spectrum') || name.includes('xfinity') ||
        name.includes('optimum') || name.includes('fios')) {
      return 'INTERNET';
    }
    // Insurance
    if (name.includes('geico') || name.includes('allstate') || name.includes('statefarm') ||
        name.includes('progressive') || name.includes('liberty')) {
      return 'INSURANCE_AUTO';
    }
    // Utilities
    if (name.includes('electric') || name.includes('power') || name.includes('energy') ||
        name.includes('eversource') || name.includes('conedison')) {
      return 'UTILITIES_ELECTRIC';
    }
    if (name.includes('water') || name.includes('sewer')) return 'UTILITIES_WATER';
    if (name.includes('gas') && !name.includes('gasoline')) return 'UTILITIES_GAS';
    // Gym
    if (name.includes('gym') || name.includes('fitness') || name.includes('planet') ||
        name.includes('equinox') || name.includes('lifetime')) {
      return 'GYM';
    }
    // Plaid category fallback
    if (category === 'rent_and_utilities') return 'OTHER';
    if (category === 'loan_payments') return 'LOAN_AUTO';
    if (category === 'insurance') return 'INSURANCE_HOME';

    return 'OTHER';
  }

  /**
   * Categorize check payee (common household services)
   */
  private categorizeCheckPayee(payee: string): BillCategory {
    const name = payee.toLowerCase();

    // Landscaping
    if (name.includes('landscap') || name.includes('lawn') || name.includes('garden') ||
        name.includes('yard') || name.includes('tree')) {
      return 'LANDSCAPING';
    }
    // Housekeeping
    if (name.includes('clean') || name.includes('maid') || name.includes('housekeep')) {
      return 'HOUSEKEEPING';
    }
    // Pool
    if (name.includes('pool')) return 'POOL_SERVICE';
    // Pest control
    if (name.includes('pest') || name.includes('exterminator')) return 'PEST_CONTROL';
    // HOA
    if (name.includes('hoa') || name.includes('homeowner') || name.includes('association')) {
      return 'HOA';
    }
    // Childcare
    if (name.includes('nanny') || name.includes('childcare') || name.includes('daycare') ||
        name.includes('babysit')) {
      return 'CHILDCARE';
    }
    // Tuition
    if (name.includes('school') || name.includes('tuition') || name.includes('academy')) {
      return 'TUITION';
    }

    return 'OTHER';
  }

  /**
   * Get connections for a household
   */
  async getConnections(householdId: string) {
    return this.prisma.plaidConnection.findMany({
      where: { householdId },
      include: { accounts: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get detected bills
   */
  async getDetectedBills(householdId: string, status?: string) {
    const where: any = { householdId };
    if (status) where.status = status;

    return this.prisma.detectedBill.findMany({
      where,
      include: {
        account: {
          include: {
            connection: {
              select: { institutionName: true, institutionLogo: true },
            },
          },
        },
      },
      orderBy: { averageAmount: 'desc' },
    });
  }

  /**
   * Get summary
   */
  async getDetectedBillsSummary(householdId: string) {
    const bills = await this.prisma.detectedBill.findMany({
      where: { householdId },
    });

    const pending = bills.filter(b => b.status === 'PENDING');
    const confirmed = bills.filter(b => b.status === 'CONFIRMED');
    const checks = bills.filter(b => b.detectionType === 'RECURRING_CHECK');

    const monthlyTotal = pending.reduce((sum, bill) => {
      let multiplier = 1;
      switch (bill.frequency) {
        case 'WEEKLY': multiplier = 4.33; break;
        case 'BIWEEKLY': multiplier = 2.17; break;
        case 'QUARTERLY': multiplier = 0.33; break;
        case 'SEMI_ANNUAL': multiplier = 0.17; break;
        case 'ANNUAL': multiplier = 0.083; break;
      }
      return sum + bill.averageAmount * multiplier;
    }, 0);

    return {
      totalDetected: bills.length,
      pending: pending.length,
      confirmed: confirmed.length,
      checksDetected: checks.length,
      estimatedMonthlyTotal: Math.round(monthlyTotal * 100) / 100,
    };
  }

  /**
   * Confirm a bill
   */
  async confirmBill(billId: string) {
    return this.prisma.detectedBill.update({
      where: { id: billId },
      data: { status: 'CONFIRMED' },
    });
  }

  /**
   * Dismiss a bill
   */
  async dismissBill(billId: string) {
    return this.prisma.detectedBill.update({
      where: { id: billId },
      data: { status: 'DISMISSED' },
    });
  }

  /**
   * Remove a connection
   */
  async removeConnection(connectionId: string, householdId: string) {
    const connection = await this.prisma.plaidConnection.findFirst({
      where: { id: connectionId, householdId },
    });

    if (!connection) throw new BadRequestException('Connection not found');

    try {
      await this.plaidClient.itemRemove({ access_token: connection.accessToken });
    } catch (e) {
      this.logger.warn('Could not remove Plaid item');
    }

    await this.prisma.plaidConnection.delete({ where: { id: connectionId } });
    return { success: true };
  }
}
```

### Task 2.3: Create Controller

Create `apps/api/src/plaid/plaid.controller.ts`:

```typescript
import {
  Controller, Get, Post, Put, Delete, Param, Body, Query, UseGuards, Request,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PlaidService } from './plaid.service';

@Controller('plaid')
@UseGuards(FirebaseAuthGuard)
export class PlaidController {
  constructor(private plaidService: PlaidService) {}

  @Post('link-token')
  async createLinkToken(@Request() req: any, @Body() body: { householdId: string }) {
    const linkToken = await this.plaidService.createLinkToken(
      req.user.userId || req.user.id,
      body.householdId
    );
    return { linkToken };
  }

  @Post('exchange-token')
  async exchangeToken(@Body() body: { householdId: string; publicToken: string }) {
    return this.plaidService.exchangePublicToken(body.householdId, body.publicToken);
  }

  @Get('connections/:householdId')
  async getConnections(@Param('householdId') householdId: string) {
    return this.plaidService.getConnections(householdId);
  }

  @Post('connections/:connectionId/sync')
  async syncTransactions(@Param('connectionId') connectionId: string) {
    return this.plaidService.syncTransactions(connectionId);
  }

  @Delete('connections/:connectionId')
  async removeConnection(
    @Param('connectionId') connectionId: string,
    @Query('householdId') householdId: string
  ) {
    return this.plaidService.removeConnection(connectionId, householdId);
  }

  @Get('bills/:householdId')
  async getDetectedBills(
    @Param('householdId') householdId: string,
    @Query('status') status?: string
  ) {
    return this.plaidService.getDetectedBills(householdId, status);
  }

  @Get('bills/:householdId/summary')
  async getBillsSummary(@Param('householdId') householdId: string) {
    return this.plaidService.getDetectedBillsSummary(householdId);
  }

  @Put('bills/:billId/confirm')
  async confirmBill(@Param('billId') billId: string) {
    return this.plaidService.confirmBill(billId);
  }

  @Put('bills/:billId/dismiss')
  async dismissBill(@Param('billId') billId: string) {
    return this.plaidService.dismissBill(billId);
  }
}
```

### Task 2.4: Create Module

Create `apps/api/src/plaid/plaid.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { PlaidController } from './plaid.controller';
import { PlaidService } from './plaid.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [PlaidController],
  providers: [PlaidService],
  exports: [PlaidService],
})
export class PlaidModule {}
```

### Task 2.5: Create index.ts

Create `apps/api/src/plaid/index.ts`:

```typescript
export * from './plaid.module';
export * from './plaid.service';
export * from './plaid.controller';
```

### Task 2.6: Register in App Module

Add to `apps/api/src/app.module.ts`:

```typescript
import { PlaidModule } from './plaid';
// Add PlaidModule to imports array
```

---

## PHASE 3: Frontend - Install Plaid Link

```bash
cd apps/web
pnpm add react-plaid-link
```

---

## PHASE 4: Bank Connection Pages

### Task 4.1: Create Connected Banks Page

Create `apps/web/src/app/app/settings/banks/page.tsx`:

This page allows users to:
- See connected banks
- Add new bank connections
- Remove existing connections
- Trigger manual sync

(Full implementation in prompt - similar to previous but with settings layout)

### Task 4.2: Create Detected Bills Review Page

Create `apps/web/src/app/app/money/detected/page.tsx`:

This page shows:
- All detected recurring charges
- Detected check payments (highlighted)
- Confirm/dismiss actions
- Category and frequency info

### Task 4.3: Add Bank Connection to Onboarding

Update `/onboarding/wizard/page.tsx` to add an optional step after property confirmation:

```typescript
// Add step after property confirm, before welcome
{step === 'connect-bank' && (
  <div className="bg-white rounded-2xl p-8 shadow-2xl">
    <div className="text-center mb-6">
      <div className="w-16 h-16 bg-indigo-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
        <Building2 className="w-8 h-8 text-indigo-600" />
      </div>
      <h1 className="text-2xl font-bold text-haven-navy-900">
        Connect your bank (optional)
      </h1>
      <p className="text-gray-500 mt-2">
        We'll automatically detect your recurring bills and subscriptions
      </p>
    </div>

    {/* Plaid Link Button */}
    <button
      onClick={() => open()}
      disabled={!ready}
      className="w-full p-4 border-2 border-dashed border-gray-300 rounded-xl hover:border-indigo-400 hover:bg-indigo-50 transition flex items-center justify-center gap-3"
    >
      <Plus className="w-5 h-5 text-gray-400" />
      <span className="text-gray-600 font-medium">Connect Bank Account</span>
    </button>

    {/* Show connected banks */}
    {connectedBanks.length > 0 && (
      <div className="mt-4 p-4 bg-green-50 rounded-xl">
        <p className="text-green-700 font-medium">
          ✓ {connectedBanks.length} bank(s) connected
        </p>
        {detectedBillCount > 0 && (
          <p className="text-green-600 text-sm mt-1">
            Found {detectedBillCount} recurring charges!
          </p>
        )}
      </div>
    )}

    {/* Continue button */}
    <button
      onClick={() => setStep('welcome')}
      className="w-full mt-6 bg-haven-navy-900 text-white py-3 rounded-xl font-medium"
    >
      {connectedBanks.length > 0 ? 'Continue' : 'Skip for now'}
    </button>
  </div>
)}
```

### Task 4.4: Update Navigation

Add to homeowner sidebar:
- Settings → "Connected Banks" link to `/app/settings/banks`
- Money → "Detected Bills" link to `/app/money/detected`

---

## PHASE 5: Update Tests

Add Plaid tests to test suite.

---

## PHASE 6: Deploy

```bash
# Add Plaid env vars to Cloud Run
gcloud run services update haven-api \
  --region=us-east1 \
  --update-env-vars="PLAID_CLIENT_ID=6951feb3168aa50020a8b7f3,PLAID_SECRET=d29c10fb56ddcf610a0762f581af56,PLAID_ENV=sandbox" \
  --project=home-manager-480616

# Deploy
pnpm build
git add . && git commit -m "feat: plaid integration with check detection"
git push origin main
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616

pnpm test:e2e
```

---

## Summary

After this prompt:
1. ✅ Plaid SDK integration
2. ✅ Detect recurring charges AND checks
3. ✅ Check payee categorization (landscaper, housekeeper, etc.)
4. ✅ Bank connection in onboarding (optional step)
5. ✅ Bank management in Settings
6. ✅ Detected bills review page

**Check Detection Categories:**
- Landscaping
- Housekeeping  
- Pool Service
- Pest Control
- HOA
- Childcare
- Tuition
- Other

These can later be automated via checkbook.io!
