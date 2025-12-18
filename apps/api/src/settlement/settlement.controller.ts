import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  Res,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { Response } from 'express';

import { FirebaseAuthGuard, AuthPayload, CurrentUser } from '../firebase';
import { PrismaService } from '../prisma';
import { InvoiceGenerationService } from './invoice-generation.service';
import { CollectionService } from './collection.service';
import {
  GenerateInvoiceDto,
  GenerateInvoiceResponseDto,
  GenerateAllInvoicesResponseDto,
  CollectInvoiceDto,
  CollectionResultDto,
  BatchCollectionResultDto,
  MonthlyInvoiceDto,
  MonthlyInvoiceListItemDto,
  RevenueStatsDto,
  HouseholdRevenueDto,
} from './dto';
import { UserRole } from '@prisma/client';

@ApiTags('Settlement')
@ApiBearerAuth()
@Controller('settlement')
@UseGuards(FirebaseAuthGuard)
export class SettlementController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly invoiceService: InvoiceGenerationService,
    private readonly collectionService: CollectionService,
  ) {}

  // ============================================================================
  // INVOICE GENERATION ENDPOINTS
  // ============================================================================

  /**
   * Generate monthly invoice for a specific household
   */
  @Post('invoices/generate')
  @ApiOperation({ summary: 'Generate monthly invoice for a household' })
  @ApiResponse({ status: 200, type: GenerateInvoiceResponseDto })
  @HttpCode(HttpStatus.OK)
  async generateInvoice(
    @CurrentUser() user: AuthPayload,
    @Body() dto: GenerateInvoiceDto,
  ): Promise<GenerateInvoiceResponseDto> {
    // Only admins and managers can generate invoices
    if (user.role !== UserRole.ADMIN && user.role !== UserRole.MANAGER) {
      return { success: false, error: 'Unauthorized' };
    }

    return this.invoiceService.generateMonthlyInvoice(dto.householdId, {
      billingPeriodStart: dto.billingPeriodStart,
      billingPeriodEnd: dto.billingPeriodEnd,
      managementFee: dto.managementFee,
    });
  }

  /**
   * Generate monthly invoices for all households (cron job endpoint)
   */
  @Post('invoices/generate-all')
  @ApiOperation({ summary: 'Generate monthly invoices for all households' })
  @ApiResponse({ status: 200, type: GenerateAllInvoicesResponseDto })
  @HttpCode(HttpStatus.OK)
  async generateAllInvoices(
    @CurrentUser() user: AuthPayload,
  ): Promise<GenerateAllInvoicesResponseDto> {
    // Only admins can trigger batch invoice generation
    if (user.role !== UserRole.ADMIN) {
      return {
        success: false,
        totalHouseholds: 0,
        invoicesGenerated: 0,
        invoicesSkipped: 0,
        errors: ['Unauthorized'],
      };
    }

    return this.invoiceService.generateAllMonthlyInvoices();
  }

  /**
   * Get all invoices for the authenticated user's household
   */
  @Get('invoices')
  @ApiOperation({ summary: 'Get invoices (statements) for the household' })
  @ApiQuery({ name: 'householdId', required: false })
  @ApiResponse({ status: 200, type: [MonthlyInvoiceListItemDto] })
  async getInvoices(
    @CurrentUser() user: AuthPayload,
    @Query('householdId') householdId?: string,
  ): Promise<MonthlyInvoiceListItemDto[]> {
    // If householdId provided and user is admin/manager, use it
    // Otherwise, get household from user's membership
    let targetHouseholdId = householdId;

    if (!targetHouseholdId || (user.role !== UserRole.ADMIN && user.role !== UserRole.MANAGER)) {
      // Get user's household
      const membership = await this.prisma.householdMember.findFirst({
        where: { userId: user.userId, status: 'ACTIVE' },
        select: { householdId: true },
      });

      if (!membership) {
        return [];
      }

      targetHouseholdId = membership.householdId;
    }

    return this.invoiceService.getInvoices(targetHouseholdId);
  }

  /**
   * Get invoice details by ID
   */
  @Get('invoices/:invoiceId')
  @ApiOperation({ summary: 'Get invoice details' })
  @ApiResponse({ status: 200, type: MonthlyInvoiceDto })
  async getInvoiceById(
    @CurrentUser() user: AuthPayload,
    @Param('invoiceId') invoiceId: string,
  ): Promise<MonthlyInvoiceDto> {
    // Get user's household for authorization
    let householdId: string | undefined;

    if (user.role !== UserRole.ADMIN && user.role !== UserRole.MANAGER) {
      const membership = await this.prisma.householdMember.findFirst({
        where: { userId: user.userId, status: 'ACTIVE' },
        select: { householdId: true },
      });
      householdId = membership?.householdId;
    }

    return this.invoiceService.getInvoiceById(invoiceId, householdId);
  }

  /**
   * Get pending invoices (admin/manager only)
   */
  @Get('invoices/pending')
  @ApiOperation({ summary: 'Get all pending invoices' })
  @ApiResponse({ status: 200, type: [MonthlyInvoiceListItemDto] })
  async getPendingInvoices(
    @CurrentUser() user: AuthPayload,
  ): Promise<MonthlyInvoiceListItemDto[]> {
    if (user.role !== UserRole.ADMIN && user.role !== UserRole.MANAGER) {
      return [];
    }

    return this.invoiceService.getPendingInvoices();
  }

  // ============================================================================
  // COLLECTION ENDPOINTS
  // ============================================================================

  /**
   * Collect payment for a specific invoice (Force Collect)
   */
  @Post('collect')
  @ApiOperation({ summary: 'Collect payment for an invoice' })
  @ApiResponse({ status: 200, type: CollectionResultDto })
  @HttpCode(HttpStatus.OK)
  async collectPayment(
    @CurrentUser() user: AuthPayload,
    @Body() dto: CollectInvoiceDto,
  ): Promise<CollectionResultDto> {
    // Only admins and managers can force collect
    if (user.role !== UserRole.ADMIN && user.role !== UserRole.MANAGER) {
      return { success: false, invoiceId: dto.invoiceId, error: 'Unauthorized' };
    }

    return this.collectionService.collect(dto.invoiceId, dto.force);
  }

  /**
   * Collect payment for all pending invoices (batch collection)
   */
  @Post('collect-all')
  @ApiOperation({ summary: 'Collect payment for all pending invoices' })
  @ApiResponse({ status: 200, type: BatchCollectionResultDto })
  @HttpCode(HttpStatus.OK)
  async collectAll(
    @CurrentUser() user: AuthPayload,
  ): Promise<BatchCollectionResultDto> {
    // Only admins can trigger batch collection
    if (user.role !== UserRole.ADMIN) {
      return {
        success: false,
        totalInvoices: 0,
        successfulCollections: 0,
        failedCollections: 0,
        results: [],
      };
    }

    return this.collectionService.collectAll();
  }

  // ============================================================================
  // REVENUE / STATS ENDPOINTS (Manager Dashboard)
  // ============================================================================

  /**
   * Get revenue statistics
   */
  @Get('revenue/stats')
  @ApiOperation({ summary: 'Get revenue statistics' })
  @ApiResponse({ status: 200, type: RevenueStatsDto })
  async getRevenueStats(
    @CurrentUser() user: AuthPayload,
  ): Promise<RevenueStatsDto | { error: string }> {
    if (user.role !== UserRole.ADMIN && user.role !== UserRole.MANAGER) {
      return { error: 'Unauthorized' } as unknown as RevenueStatsDto;
    }

    return this.collectionService.getRevenueStats();
  }

  /**
   * Get revenue breakdown by household
   */
  @Get('revenue/households')
  @ApiOperation({ summary: 'Get revenue breakdown by household' })
  @ApiResponse({ status: 200, type: [HouseholdRevenueDto] })
  async getHouseholdRevenue(
    @CurrentUser() user: AuthPayload,
  ): Promise<HouseholdRevenueDto[]> {
    if (user.role !== UserRole.ADMIN && user.role !== UserRole.MANAGER) {
      return [];
    }

    return this.collectionService.getHouseholdRevenue();
  }

  // ============================================================================
  // PDF GENERATION ENDPOINT
  // ============================================================================

  /**
   * Generate PDF invoice (on the fly)
   */
  @Get('invoices/:invoiceId/pdf')
  @ApiOperation({ summary: 'Generate PDF invoice' })
  async generatePdf(
    @CurrentUser() user: AuthPayload,
    @Param('invoiceId') invoiceId: string,
    @Res() res: Response,
  ): Promise<void> {
    // Get user's household for authorization
    let householdId: string | undefined;

    if (user.role !== UserRole.ADMIN && user.role !== UserRole.MANAGER) {
      const membership = await this.prisma.householdMember.findFirst({
        where: { userId: user.userId, status: 'ACTIVE' },
        select: { householdId: true },
      });
      householdId = membership?.householdId;
    }

    const invoice = await this.invoiceService.getInvoiceById(invoiceId, householdId);

    // Generate simple HTML-based "PDF" (in production, use PDFKit or similar)
    const html = this.generateInvoiceHtml(invoice);

    res.setHeader('Content-Type', 'text/html');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="statement-${invoice.invoiceNumber}.html"`
    );
    res.send(html);
  }

  // ============================================================================
  // WEBHOOK HANDLERS (for Stripe events)
  // ============================================================================

  /**
   * Handle payment success webhook
   */
  async handlePaymentSuccess(invoiceId: string): Promise<void> {
    await this.collectionService.handlePaymentSuccess(invoiceId);
  }

  /**
   * Handle payment failure webhook
   */
  async handlePaymentFailure(invoiceId: string, reason: string): Promise<void> {
    await this.collectionService.handlePaymentFailure(invoiceId, reason);
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  private generateInvoiceHtml(invoice: MonthlyInvoiceDto): string {
    const formatDate = (date: Date) =>
      new Date(date).toLocaleDateString('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric',
      });

    const formatCurrency = (amount: number) =>
      new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
      }).format(amount);

    const statusColor = {
      PENDING: '#f59e0b',
      PROCESSING: '#3b82f6',
      PAID: '#10b981',
      FAILED: '#ef4444',
      PAST_DUE: '#dc2626',
    };

    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Statement ${invoice.invoiceNumber}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 40px; color: #1f2937; }
    .header { display: flex; justify-content: space-between; margin-bottom: 40px; }
    .logo { font-size: 28px; font-weight: bold; color: #10b981; }
    .invoice-info { text-align: right; }
    .invoice-number { font-size: 24px; font-weight: bold; color: #374151; }
    .status { display: inline-block; padding: 4px 12px; border-radius: 4px; font-size: 14px; font-weight: 600; color: white; background: ${statusColor[invoice.status]}; }
    .section { margin-bottom: 32px; }
    .section-title { font-size: 14px; font-weight: 600; text-transform: uppercase; color: #6b7280; margin-bottom: 8px; }
    .billing-period { font-size: 18px; color: #374151; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    th { text-align: left; padding: 12px; background: #f3f4f6; font-weight: 600; border-bottom: 2px solid #e5e7eb; }
    td { padding: 12px; border-bottom: 1px solid #e5e7eb; }
    .amount { text-align: right; font-family: monospace; }
    .total-row { font-weight: bold; font-size: 18px; background: #f9fafb; }
    .total-row td { padding: 16px 12px; }
    .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #e5e7eb; color: #6b7280; font-size: 14px; }
    .receipt-link { color: #10b981; text-decoration: none; }
    .receipt-link:hover { text-decoration: underline; }
    .manager-note { background: #fef3c7; padding: 12px; border-radius: 8px; margin-top: 8px; font-size: 14px; }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">Haven</div>
    <div class="invoice-info">
      <div class="invoice-number">${invoice.invoiceNumber}</div>
      <div class="status">${invoice.status}</div>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Billing Period</div>
    <div class="billing-period">
      ${formatDate(invoice.billingPeriodStart)} - ${formatDate(invoice.billingPeriodEnd)}
    </div>
  </div>

  <div class="section">
    <div class="section-title">Property</div>
    <div style="font-size: 18px;">${invoice.householdName}</div>
  </div>

  <div class="section">
    <div class="section-title">Line Items</div>
    <table>
      <thead>
        <tr>
          <th>Description</th>
          <th>Vendor</th>
          <th>Date</th>
          <th class="amount">Amount</th>
        </tr>
      </thead>
      <tbody>
        ${invoice.lineItems
          .map(
            (item) => `
        <tr>
          <td>
            ${item.description}
            ${item.receiptUrl ? `<br><a href="${item.receiptUrl}" class="receipt-link">View Receipt</a>` : ''}
            ${item.managerNote ? `<div class="manager-note">Note: ${item.managerNote}</div>` : ''}
          </td>
          <td>${item.vendorName || '-'}</td>
          <td>${item.paidAt ? formatDate(item.paidAt) : '-'}</td>
          <td class="amount">${formatCurrency(item.amount)}</td>
        </tr>
        `
          )
          .join('')}
        <tr class="total-row">
          <td colspan="3">Total</td>
          <td class="amount">${formatCurrency(invoice.total)}</td>
        </tr>
      </tbody>
    </table>
  </div>

  ${
    invoice.paidAt
      ? `
  <div class="section">
    <div class="section-title">Payment Information</div>
    <div style="color: #10b981; font-weight: 600;">
      Paid on ${formatDate(invoice.paidAt)}
    </div>
  </div>
  `
      : ''
  }

  ${
    invoice.failureReason
      ? `
  <div class="section">
    <div class="section-title">Payment Issue</div>
    <div style="color: #ef4444;">
      ${invoice.failureReason}
    </div>
  </div>
  `
      : ''
  }

  <div class="footer">
    <p>Haven Home Management</p>
    <p>Questions? Contact your home manager or email support@haven.app</p>
  </div>
</body>
</html>
    `;
  }
}
