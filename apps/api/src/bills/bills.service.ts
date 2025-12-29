import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  Configuration,
  PlaidApi,
  PlaidEnvironments,
} from 'plaid';

@Injectable()
export class BillsService {
  private readonly logger = new Logger(BillsService.name);
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
   * Get bill detail with transaction history
   */
  async getBillDetail(billId: string, householdId: string) {
    const bill = await this.prisma.detectedBill.findFirst({
      where: { id: billId, householdId },
      include: {
        account: {
          include: {
            connection: true,
          },
        },
      },
    });

    if (!bill) {
      throw new NotFoundException('Bill not found');
    }

    // Get transaction history from Plaid if we have an active connection
    let transactions: any[] = [];
    if (bill.account?.connection?.accessToken) {
      try {
        const endDate = new Date().toISOString().split('T')[0];
        const startDate = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000)
          .toISOString()
          .split('T')[0];

        const response = await this.plaidClient.transactionsGet({
          access_token: bill.account.connection.accessToken,
          start_date: startDate,
          end_date: endDate,
        });

        // Filter transactions matching this bill's merchant
        const normalized = bill.normalizedName.toLowerCase();
        transactions = response.data.transactions
          .filter((tx) => {
            const txName = (tx.merchant_name || tx.name || '').toLowerCase().replace(/[^a-z0-9]/g, '');
            return txName.includes(normalized) || normalized.includes(txName);
          })
          .map((tx) => ({
            id: tx.transaction_id,
            date: tx.date,
            amount: Math.abs(tx.amount),
            description: tx.merchant_name || tx.name,
            pending: tx.pending,
          }));
      } catch (error) {
        this.logger.warn('Could not fetch transaction history:', error);
      }
    }

    // Get related documents
    const relatedDocuments = await this.prisma.document.findMany({
      where: {
        householdId,
        OR: [
          { title: { contains: bill.merchantName, mode: 'insensitive' } },
          { tags: { hasSome: [bill.category.toLowerCase(), bill.merchantName.toLowerCase()] } },
        ],
      },
      select: { id: true, title: true, category: true },
      take: 5,
    });

    return {
      ...bill,
      transactions,
      relatedDocuments,
    };
  }

  /**
   * Update bill management status
   */
  async updateBillManagement(billId: string, householdId: string, managementStatus: string) {
    const bill = await this.prisma.detectedBill.findFirst({
      where: { id: billId, householdId },
    });

    if (!bill) {
      throw new NotFoundException('Bill not found');
    }

    return this.prisma.detectedBill.update({
      where: { id: billId },
      data: { managementStatus },
    });
  }

  /**
   * Update bill notes
   */
  async updateBillNotes(billId: string, householdId: string, notes: string) {
    const bill = await this.prisma.detectedBill.findFirst({
      where: { id: billId, householdId },
    });

    if (!bill) {
      throw new NotFoundException('Bill not found');
    }

    return this.prisma.detectedBill.update({
      where: { id: billId },
      data: { notes },
    });
  }

  /**
   * Get all bills for manager view (pending setup and haven-managed)
   */
  async getManagerBills(filter: string) {
    const where: any = {};

    if (filter === 'pending_setup') {
      where.managementStatus = 'PENDING_SETUP';
    } else if (filter === 'haven_managed') {
      where.managementStatus = 'HAVEN_MANAGED';
    } else if (filter === 'all') {
      where.managementStatus = { in: ['PENDING_SETUP', 'HAVEN_MANAGED'] };
    }

    return this.prisma.detectedBill.findMany({
      where,
      include: {
        household: {
          select: { id: true, name: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
