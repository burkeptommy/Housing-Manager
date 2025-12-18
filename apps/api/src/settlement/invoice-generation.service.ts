import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { Decimal } from '@prisma/client/runtime/library';
import { TransactionStatus } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import {
  MonthlyInvoiceDto,
  MonthlyInvoiceListItemDto,
  MonthlyInvoiceStatus,
  TransactionLineItemDto,
  GenerateInvoiceResponseDto,
  GenerateAllInvoicesResponseDto,
} from './dto';

/**
 * InvoiceGenerationService - Generates monthly invoices from reimbursable transactions
 *
 * The Settlement Engine flow:
 * 1. Haven pays vendors throughout the month (The Float)
 * 2. Transactions are logged with isReimbursable = true
 * 3. On the 1st of the month, generateMonthlyInvoice() is called
 * 4. All PAID_TO_VENDOR transactions are summed
 * 5. Management fee is added
 * 6. HouseholdInvoice is created with line items
 * 7. CollectionService triggers ACH debit
 */
@Injectable()
export class InvoiceGenerationService {
  private readonly logger = new Logger(InvoiceGenerationService.name);

  // Default management fee if not set on household
  private readonly DEFAULT_MANAGEMENT_FEE = 100;

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generate monthly invoice for a specific household
   * Sums all reimbursable transactions that are PAID_TO_VENDOR
   * Adds management fee
   * Creates consolidated invoice
   */
  async generateMonthlyInvoice(
    householdId: string,
    options?: {
      billingPeriodStart?: Date;
      billingPeriodEnd?: Date;
      managementFee?: number;
    },
  ): Promise<GenerateInvoiceResponseDto> {
    this.logger.log(`Generating monthly invoice for household ${householdId}`);

    try {
      // Get household with billing settings
      const household = await this.prisma.household.findUnique({
        where: { id: householdId },
        include: {
          owner: true,
          clientBankAccounts: {
            where: { isDefault: true, isActive: true },
          },
        },
      });

      if (!household) {
        throw new NotFoundException('Household not found');
      }

      // Calculate billing period (previous month by default)
      const now = new Date();
      const billingPeriodStart = options?.billingPeriodStart ||
        new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const billingPeriodEnd = options?.billingPeriodEnd ||
        new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);

      // Check for existing invoice for this period
      const existingInvoice = await this.prisma.householdInvoice.findFirst({
        where: {
          householdId,
          billingPeriodStart: { gte: billingPeriodStart },
          billingPeriodEnd: { lte: new Date(billingPeriodEnd.getTime() + 24 * 60 * 60 * 1000) },
        },
      });

      if (existingInvoice) {
        this.logger.warn(`Invoice already exists for household ${householdId} for this period`);
        return {
          success: false,
          error: `Invoice already exists for this billing period: ${existingInvoice.invoiceNumber}`,
        };
      }

      // Get all reimbursable transactions that are PAID_TO_VENDOR and not yet billed
      const transactions = await this.prisma.transaction.findMany({
        where: {
          householdId,
          isReimbursable: true,
          status: TransactionStatus.PAID_TO_VENDOR,
          householdInvoiceId: null, // Not yet billed
          paidAt: {
            gte: billingPeriodStart,
            lte: billingPeriodEnd,
          },
        },
        include: {
          vendor: true,
          manager: true,
          receiptFile: true,
        },
        orderBy: { paidAt: 'asc' },
      });

      if (transactions.length === 0) {
        this.logger.log(`No reimbursable transactions for household ${householdId}`);
        return {
          success: false,
          error: 'No reimbursable transactions found for this billing period',
        };
      }

      // Calculate subtotal from transactions
      let transactionsSubtotal = new Decimal(0);
      for (const tx of transactions) {
        transactionsSubtotal = transactionsSubtotal.add(tx.amount);
      }

      // Get management fee (from options, household settings, or default)
      const managementFee = new Decimal(
        options?.managementFee ??
        (household.billingSettings as Record<string, number>)?.managementFee ??
        this.DEFAULT_MANAGEMENT_FEE
      );

      const total = transactionsSubtotal.add(managementFee);

      // Generate invoice number
      const invoiceNumber = await this.generateInvoiceNumber(householdId);

      // Calculate due date (15 days from now)
      const dueDate = new Date();
      dueDate.setDate(dueDate.getDate() + 15);

      // Create invoice with line items
      const invoice = await this.prisma.householdInvoice.create({
        data: {
          householdId,
          invoiceNumber,
          billingPeriodStart,
          billingPeriodEnd,
          subtotal: transactionsSubtotal,
          platformFee: managementFee,
          total,
          status: 'PENDING',
          notes: `Monthly settlement invoice. Includes ${transactions.length} transaction(s) plus management fee.`,
          items: {
            create: [
              // Transaction line items
              ...transactions.map((tx) => ({
                billAccountId: tx.vendorId || 'system', // Use vendorId or a system placeholder
                description: tx.description,
                amount: tx.amount,
              })),
            ],
          },
        },
        include: {
          household: true,
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

      // Update transactions to link to this invoice and mark as BILLED
      await this.prisma.transaction.updateMany({
        where: {
          id: { in: transactions.map((t) => t.id) },
        },
        data: {
          householdInvoiceId: invoice.id,
          status: TransactionStatus.BILLED_TO_CLIENT,
          billedAt: new Date(),
        },
      });

      this.logger.log(
        `Created invoice ${invoiceNumber} for household ${householdId}: $${total.toNumber()}`
      );

      // Map to DTO
      const invoiceDto = await this.mapInvoiceToDto(invoice.id);

      return {
        success: true,
        invoice: invoiceDto,
      };
    } catch (error) {
      this.logger.error(`Failed to generate invoice: ${error}`);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Generate invoices for all households due for billing
   * Called by cron job on the 1st of each month
   */
  async generateAllMonthlyInvoices(): Promise<GenerateAllInvoicesResponseDto> {
    this.logger.log('Starting monthly invoice generation for all households...');

    const errors: string[] = [];
    let invoicesGenerated = 0;
    let invoicesSkipped = 0;

    // Get all active households
    const households = await this.prisma.household.findMany({
      where: {
        // Only households with bank accounts set up
        clientBankAccounts: {
          some: {
            isActive: true,
            isDefault: true,
          },
        },
      },
      select: { id: true, name: true },
    });

    for (const household of households) {
      const result = await this.generateMonthlyInvoice(household.id);

      if (result.success) {
        invoicesGenerated++;
      } else {
        if (result.error?.includes('No reimbursable transactions') ||
            result.error?.includes('already exists')) {
          invoicesSkipped++;
        } else {
          errors.push(`${household.name}: ${result.error}`);
        }
      }
    }

    this.logger.log(
      `Invoice generation complete: ${invoicesGenerated} generated, ${invoicesSkipped} skipped`
    );

    return {
      success: errors.length === 0,
      totalHouseholds: households.length,
      invoicesGenerated,
      invoicesSkipped,
      errors,
    };
  }

  /**
   * Get all invoices for a household
   */
  async getInvoices(householdId: string): Promise<MonthlyInvoiceListItemDto[]> {
    const invoices = await this.prisma.householdInvoice.findMany({
      where: { householdId },
      include: {
        transactions: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return invoices.map((invoice) => ({
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      billingPeriodStart: invoice.billingPeriodStart,
      billingPeriodEnd: invoice.billingPeriodEnd,
      total: invoice.total.toNumber(),
      status: this.mapStatus(invoice.status, invoice.failedAt),
      itemCount: invoice.transactions.length,
      paidAt: invoice.paidAt ?? undefined,
      createdAt: invoice.createdAt,
    }));
  }

  /**
   * Get invoice details by ID
   */
  async getInvoiceById(
    invoiceId: string,
    householdId?: string,
  ): Promise<MonthlyInvoiceDto> {
    return this.mapInvoiceToDto(invoiceId, householdId);
  }

  /**
   * Get pending invoices for collection
   */
  async getPendingInvoices(): Promise<MonthlyInvoiceListItemDto[]> {
    const invoices = await this.prisma.householdInvoice.findMany({
      where: {
        status: { in: ['PENDING', 'FAILED'] },
      },
      include: {
        household: true,
        transactions: true,
      },
      orderBy: { createdAt: 'asc' },
    });

    return invoices.map((invoice) => ({
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      billingPeriodStart: invoice.billingPeriodStart,
      billingPeriodEnd: invoice.billingPeriodEnd,
      total: invoice.total.toNumber(),
      status: this.mapStatus(invoice.status, invoice.failedAt),
      itemCount: invoice.transactions.length,
      paidAt: invoice.paidAt ?? undefined,
      createdAt: invoice.createdAt,
    }));
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

    // Format: STMT-YYYYMM-XXXX (sequential per household)
    return `STMT-${year}${month}-${String(count + 1).padStart(4, '0')}`;
  }

  private mapStatus(
    dbStatus: string,
    failedAt: Date | null,
  ): MonthlyInvoiceStatus {
    // Check if past due (failed more than 7 days ago)
    if (dbStatus === 'FAILED' && failedAt) {
      const daysSinceFailure = Math.floor(
        (Date.now() - failedAt.getTime()) / (1000 * 60 * 60 * 24)
      );
      if (daysSinceFailure > 7) {
        return MonthlyInvoiceStatus.PAST_DUE;
      }
    }

    return dbStatus as MonthlyInvoiceStatus;
  }

  private async mapInvoiceToDto(
    invoiceId: string,
    householdId?: string,
  ): Promise<MonthlyInvoiceDto> {
    const whereClause: { id: string; householdId?: string } = { id: invoiceId };
    if (householdId) {
      whereClause.householdId = householdId;
    }

    const invoice = await this.prisma.householdInvoice.findFirst({
      where: whereClause,
      include: {
        household: true,
        transactions: {
          include: {
            vendor: true,
            manager: true,
            receiptFile: true,
          },
        },
      },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    // Build line items from transactions
    const lineItems: TransactionLineItemDto[] = invoice.transactions.map((tx) => ({
      id: `item-${tx.id}`,
      transactionId: tx.id,
      description: tx.description,
      vendorName: tx.vendor?.displayName ?? null,
      amount: tx.amount.toNumber(),
      paidAt: tx.paidAt,
      receiptUrl: tx.receiptFile?.url ?? tx.receiptUrl ?? undefined,
      managerNote: tx.notes ?? undefined,
    }));

    // Add management fee as a line item if present
    if (invoice.platformFee.toNumber() > 0) {
      lineItems.push({
        id: 'management-fee',
        transactionId: 'fee',
        description: 'Monthly Management Fee',
        vendorName: 'Haven',
        amount: invoice.platformFee.toNumber(),
        paidAt: null,
      });
    }

    return {
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      householdId: invoice.householdId,
      householdName: invoice.household.name,
      billingPeriodStart: invoice.billingPeriodStart,
      billingPeriodEnd: invoice.billingPeriodEnd,
      transactionsSubtotal: invoice.subtotal.toNumber(),
      managementFee: invoice.platformFee.toNumber(),
      total: invoice.total.toNumber(),
      status: this.mapStatus(invoice.status, invoice.failedAt),
      stripePaymentIntentId: invoice.stripePaymentIntentId ?? undefined,
      paidAt: invoice.paidAt ?? undefined,
      failedAt: invoice.failedAt ?? undefined,
      failureReason: invoice.failureReason ?? undefined,
      lineItems,
      createdAt: invoice.createdAt,
    };
  }
}
