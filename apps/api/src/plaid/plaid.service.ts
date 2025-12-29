import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  Configuration,
  PlaidApi,
  PlaidEnvironments,
  Products,
  CountryCode,
  TransactionsGetRequest,
} from 'plaid';
import { BillCategory, BillingFrequency } from '@prisma/client';

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
        user: { client_user_id: userId },
        client_name: 'Haven',
        products: [Products.Transactions],
        country_codes: [CountryCode.Us],
        language: 'en',
      });

      return response.data.link_token;
    } catch (error) {
      this.logger.error('Error creating link token:', error);
      throw new BadRequestException('Failed to create link token');
    }
  }

  /**
   * Exchange public token for access token and save connection
   */
  async exchangePublicToken(
    householdId: string,
    publicToken: string,
  ): Promise<{ connectionId: string; accountCount: number }> {
    try {
      // Exchange public token for access token
      const exchangeResponse = await this.plaidClient.itemPublicTokenExchange({
        public_token: publicToken,
      });

      const accessToken = exchangeResponse.data.access_token;
      const itemId = exchangeResponse.data.item_id;

      // Get institution info
      const itemResponse = await this.plaidClient.itemGet({
        access_token: accessToken,
      });
      const institutionId = itemResponse.data.item.institution_id;

      let institutionName = 'Unknown Institution';
      if (institutionId) {
        try {
          const instResponse = await this.plaidClient.institutionsGetById({
            institution_id: institutionId,
            country_codes: [CountryCode.Us],
          });
          institutionName = instResponse.data.institution.name;
        } catch (e) {
          this.logger.warn('Could not get institution name');
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
    } catch (error) {
      this.logger.error('Error exchanging public token:', error);
      throw new BadRequestException('Failed to connect bank account');
    }
  }

  /**
   * Sync transactions and detect recurring bills
   */
  async syncTransactions(connectionId: string): Promise<number> {
    const connection = await this.prisma.plaidConnection.findUnique({
      where: { id: connectionId },
      include: { accounts: true },
    });

    if (!connection) {
      throw new BadRequestException('Connection not found');
    }

    try {
      // Get last 90 days of transactions
      const endDate = new Date().toISOString().split('T')[0];
      const startDate = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
        .toISOString()
        .split('T')[0];

      const request: TransactionsGetRequest = {
        access_token: connection.accessToken,
        start_date: startDate,
        end_date: endDate,
        options: {
          include_personal_finance_category: true,
        },
      };

      const response = await this.plaidClient.transactionsGet(request);
      const transactions = response.data.transactions;

      // Update last synced
      await this.prisma.plaidConnection.update({
        where: { id: connectionId },
        data: { lastSyncedAt: new Date() },
      });

      // Analyze for recurring patterns
      const detectedBills = this.analyzeForRecurringBills(
        transactions,
        connection.householdId,
        connection.accounts,
      );

      // Save detected bills
      for (const bill of detectedBills) {
        // Check if already exists
        const existing = await this.prisma.detectedBill.findFirst({
          where: {
            householdId: connection.householdId,
            normalizedName: bill.normalizedName,
          },
        });

        if (!existing) {
          await this.prisma.detectedBill.create({ data: bill });
        } else {
          // Update existing
          await this.prisma.detectedBill.update({
            where: { id: existing.id },
            data: {
              lastAmount: bill.lastAmount,
              lastTransactionDate: bill.lastTransactionDate,
              transactionCount: bill.transactionCount,
              transactionIds: bill.transactionIds,
            },
          });
        }
      }

      this.logger.log(
        `Detected ${detectedBills.length} recurring bills for household ${connection.householdId}`,
      );

      return detectedBills.length;
    } catch (error: any) {
      this.logger.error('Error syncing transactions:', error);

      // Update connection status on error
      await this.prisma.plaidConnection.update({
        where: { id: connectionId },
        data: {
          status: 'ERROR',
          errorCode: error.error_code || 'UNKNOWN',
          errorMessage: error.error_message || error.message,
        },
      });

      throw new BadRequestException('Failed to sync transactions');
    }
  }

  /**
   * Analyze transactions for recurring patterns
   */
  private analyzeForRecurringBills(
    transactions: any[],
    householdId: string,
    accounts: any[],
  ): any[] {
    // Group transactions by normalized merchant name
    const merchantGroups = new Map<string, any[]>();

    for (const tx of transactions) {
      if (tx.amount <= 0) continue; // Skip credits/refunds

      const normalizedName = this.normalizeMerchantName(
        tx.merchant_name || tx.name,
      );

      if (!merchantGroups.has(normalizedName)) {
        merchantGroups.set(normalizedName, []);
      }
      merchantGroups.get(normalizedName)!.push(tx);
    }

    const detectedBills: any[] = [];

    for (const [normalizedName, txs] of merchantGroups) {
      // Need at least 2 transactions to detect a pattern
      if (txs.length < 2) continue;

      // Analyze frequency and amount consistency
      const amounts = txs.map((tx) => tx.amount);
      const avgAmount = amounts.reduce((a, b) => a + b, 0) / amounts.length;
      const amountVariance = this.calculateVariance(amounts);

      // If amounts are relatively consistent (within 20% variance), likely a bill
      const isConsistentAmount = amountVariance < avgAmount * 0.2;

      // Analyze timing
      const dates = txs
        .map((tx) => new Date(tx.date))
        .sort((a, b) => a.getTime() - b.getTime());
      const frequency = this.detectFrequency(dates);

      // Skip if irregular frequency and inconsistent amounts
      if (frequency === 'IRREGULAR' && !isConsistentAmount) continue;

      // Categorize based on Plaid category or merchant name
      const category = this.categorizeTransaction(txs[0], normalizedName);

      // Find the account
      const accountId = accounts.find(
        (a) => a.plaidAccountId === txs[0].account_id,
      )?.id;

      const sortedTxs = txs.sort(
        (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
      );

      detectedBills.push({
        householdId,
        accountId,
        merchantName: txs[0].merchant_name || txs[0].name,
        normalizedName,
        category,
        averageAmount: Math.round(avgAmount * 100) / 100,
        lastAmount: sortedTxs[0].amount,
        frequency,
        lastTransactionDate: new Date(sortedTxs[0].date),
        nextExpectedDate: this.predictNextDate(dates, frequency),
        dayOfMonth:
          frequency === 'MONTHLY' ? new Date(sortedTxs[0].date).getDate() : null,
        status: 'PENDING',
        transactionIds: txs.map((tx) => tx.transaction_id),
        transactionCount: txs.length,
      });
    }

    // Sort by amount (highest first)
    return detectedBills.sort((a, b) => b.averageAmount - a.averageAmount);
  }

  /**
   * Normalize merchant name for grouping
   */
  private normalizeMerchantName(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '')
      .replace(/\d+/g, '') // Remove numbers (often transaction IDs)
      .trim();
  }

  /**
   * Calculate variance of amounts
   */
  private calculateVariance(amounts: number[]): number {
    const avg = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const squareDiffs = amounts.map((a) => Math.pow(a - avg, 2));
    return Math.sqrt(squareDiffs.reduce((a, b) => a + b, 0) / amounts.length);
  }

  /**
   * Detect billing frequency from transaction dates
   */
  private detectFrequency(dates: Date[]): BillingFrequency {
    if (dates.length < 2) return 'IRREGULAR';

    const gaps: number[] = [];
    for (let i = 1; i < dates.length; i++) {
      const daysDiff = Math.round(
        (dates[i].getTime() - dates[i - 1].getTime()) / (1000 * 60 * 60 * 24),
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

  /**
   * Predict next expected transaction date
   */
  private predictNextDate(
    dates: Date[],
    frequency: BillingFrequency,
  ): Date | null {
    if (dates.length === 0) return null;

    const lastDate = dates[dates.length - 1];
    const nextDate = new Date(lastDate);

    switch (frequency) {
      case 'WEEKLY':
        nextDate.setDate(nextDate.getDate() + 7);
        break;
      case 'BIWEEKLY':
        nextDate.setDate(nextDate.getDate() + 14);
        break;
      case 'MONTHLY':
        nextDate.setMonth(nextDate.getMonth() + 1);
        break;
      case 'QUARTERLY':
        nextDate.setMonth(nextDate.getMonth() + 3);
        break;
      case 'SEMI_ANNUAL':
        nextDate.setMonth(nextDate.getMonth() + 6);
        break;
      case 'ANNUAL':
        nextDate.setFullYear(nextDate.getFullYear() + 1);
        break;
      default:
        return null;
    }

    return nextDate;
  }

  /**
   * Categorize transaction based on Plaid category and merchant name
   */
  private categorizeTransaction(tx: any, normalizedName: string): BillCategory {
    const category =
      tx.personal_finance_category?.primary?.toLowerCase() || '';
    const detailed =
      tx.personal_finance_category?.detailed?.toLowerCase() || '';
    const name = normalizedName.toLowerCase();

    // Check merchant name patterns - map to existing BillCategory values
    if (
      name.includes('netflix') ||
      name.includes('hulu') ||
      name.includes('disney') ||
      name.includes('hbo') ||
      name.includes('spotify') ||
      name.includes('apple')
    ) {
      return 'STREAMING_SERVICE';
    }
    if (name.includes('gym') || name.includes('fitness') || name.includes('planet')) {
      return 'GYM_FITNESS';
    }
    if (name.includes('verizon') || name.includes('att') || name.includes('tmobile')) {
      return 'CELL_PHONE';
    }
    if (
      name.includes('comcast') ||
      name.includes('spectrum') ||
      name.includes('xfinity')
    ) {
      return 'INTERNET';
    }
    if (
      name.includes('geico') ||
      name.includes('allstate') ||
      name.includes('statefarm')
    ) {
      return 'AUTO_INSURANCE';
    }
    if (name.includes('electric') || name.includes('power') || name.includes('energy')) {
      return 'ELECTRIC';
    }
    if (name.includes('water') || name.includes('sewer')) {
      return 'WATER_SEWER';
    }
    if (name.includes('gas') && !name.includes('gasoline')) {
      return 'GAS';
    }

    // Check Plaid category
    if (category === 'rent_and_utilities') {
      if (detailed.includes('electric')) return 'ELECTRIC';
      if (detailed.includes('gas')) return 'GAS';
      if (detailed.includes('water')) return 'WATER_SEWER';
      if (detailed.includes('internet')) return 'INTERNET';
      if (detailed.includes('phone')) return 'CELL_PHONE';
      return 'OTHER_BILL';
    }
    if (category === 'loan_payments') return 'PERSONAL_LOAN';
    if (category === 'insurance') return 'HOME_INSURANCE';
    if (detailed.includes('subscription')) return 'SOFTWARE_SUBSCRIPTION';

    return 'OTHER_BILL';
  }

  /**
   * Get all connections for a household
   */
  async getConnections(householdId: string) {
    return this.prisma.plaidConnection.findMany({
      where: { householdId },
      include: {
        accounts: true,
      },
    });
  }

  /**
   * Get detected bills for a household
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
              select: { institutionName: true },
            },
          },
        },
      },
      orderBy: { averageAmount: 'desc' },
    });
  }

  /**
   * Get summary of detected bills
   */
  async getDetectedBillsSummary(householdId: string) {
    const bills = await this.prisma.detectedBill.findMany({
      where: { householdId },
    });

    const pending = bills.filter((b) => b.status === 'PENDING');
    const confirmed = bills.filter((b) => b.status === 'CONFIRMED');

    // Calculate monthly total (normalize all frequencies to monthly)
    const monthlyTotal = pending.reduce((sum, bill) => {
      let multiplier = 1;
      switch (bill.frequency) {
        case 'WEEKLY':
          multiplier = 4.33;
          break;
        case 'BIWEEKLY':
          multiplier = 2.17;
          break;
        case 'QUARTERLY':
          multiplier = 0.33;
          break;
        case 'SEMI_ANNUAL':
          multiplier = 0.17;
          break;
        case 'ANNUAL':
          multiplier = 0.083;
          break;
      }
      return sum + bill.averageAmount * multiplier;
    }, 0);

    return {
      totalDetected: bills.length,
      pending: pending.length,
      confirmed: confirmed.length,
      estimatedMonthlyTotal: Math.round(monthlyTotal * 100) / 100,
    };
  }

  /**
   * Confirm a detected bill
   */
  async confirmBill(detectedBillId: string) {
    const bill = await this.prisma.detectedBill.update({
      where: { id: detectedBillId },
      data: { status: 'CONFIRMED' },
    });

    return bill;
  }

  /**
   * Dismiss a detected bill
   */
  async dismissBill(detectedBillId: string) {
    return this.prisma.detectedBill.update({
      where: { id: detectedBillId },
      data: { status: 'DISMISSED' },
    });
  }

  /**
   * Remove a bank connection
   */
  async removeConnection(connectionId: string, householdId: string) {
    const connection = await this.prisma.plaidConnection.findFirst({
      where: { id: connectionId, householdId },
    });

    if (!connection) {
      throw new BadRequestException('Connection not found');
    }

    // Remove from Plaid
    try {
      await this.plaidClient.itemRemove({
        access_token: connection.accessToken,
      });
    } catch (error) {
      this.logger.warn('Could not remove item from Plaid:', error);
    }

    // Delete from database (cascades to accounts and detected bills)
    await this.prisma.plaidConnection.delete({
      where: { id: connectionId },
    });

    return { success: true };
  }
}
