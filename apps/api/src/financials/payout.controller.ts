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
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

import { FirebaseAuthGuard, AuthPayload, CurrentUser } from '../firebase';
import { PrismaService } from '../prisma';
import { CheckbookService, VendorAddress } from './checkbook.service';
import { StripePayoutService } from './stripe-payout.service';
import {
  ExecutePayoutDto,
  ExecutePayoutResponseDto,
  PayoutResultItemDto,
  VendorPayableDto,
  BatchPayPreviewDto,
} from './dto';
import { TransactionPayoutMethod, TransactionStatus, UserRole } from '@prisma/client';

@ApiTags('Financials')
@ApiBearerAuth()
@Controller('financials')
@UseGuards(FirebaseAuthGuard)
export class PayoutController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly checkbookService: CheckbookService,
    private readonly stripePayoutService: StripePayoutService,
  ) {}

  /**
   * Get list of unpaid vendor payables (transactions pending payment)
   */
  @Get('payables')
  @ApiOperation({ summary: 'Get unpaid vendor payables' })
  @ApiQuery({ name: 'householdId', required: false })
  @ApiResponse({ status: 200, type: [VendorPayableDto] })
  async getPayables(
    @CurrentUser() user: AuthPayload,
    @Query('householdId') householdId?: string,
  ): Promise<VendorPayableDto[]> {
    // Build where clause based on user role
    const whereClause: any = {
      status: { in: [TransactionStatus.PENDING, TransactionStatus.PAID_TO_VENDOR] },
      isReimbursable: true,
    };

    // Managers can only see their assigned households
    if (user.role === UserRole.MANAGER) {
      whereClause.household = { managerId: user.userId };
    }

    if (householdId) {
      whereClause.householdId = householdId;
    }

    const transactions = await this.prisma.transaction.findMany({
      where: whereClause,
      include: {
        vendor: {
          include: {
            vendorPayoutAccount: true,
          },
        },
        household: true,
        manager: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return transactions.map((tx) => {
      const vendor = tx.vendor;
      const hasStripeConnect = !!vendor?.vendorPayoutAccount?.stripeAccountId;
      const hasAddress = !!(vendor?.addressLine1 && vendor?.city && vendor?.state && vendor?.postalCode);

      // Determine available payout methods
      const availablePayoutMethods: TransactionPayoutMethod[] = [];
      if (hasStripeConnect) {
        availablePayoutMethods.push(TransactionPayoutMethod.STRIPE);
      }
      if (hasAddress) {
        availablePayoutMethods.push(TransactionPayoutMethod.CHECKBOOK_IO);
      }
      availablePayoutMethods.push(TransactionPayoutMethod.COMPANY_CARD, TransactionPayoutMethod.CASH);

      // Recommend Stripe if available, otherwise check
      const recommendedPayoutMethod = hasStripeConnect
        ? TransactionPayoutMethod.STRIPE
        : hasAddress
        ? TransactionPayoutMethod.CHECKBOOK_IO
        : TransactionPayoutMethod.COMPANY_CARD;

      return {
        id: tx.id,
        transactionId: tx.id,
        vendorId: tx.vendorId || '',
        vendorName: vendor?.displayName || 'Unknown Vendor',
        householdId: tx.householdId,
        householdName: tx.household.name,
        description: tx.description,
        amount: Number(tx.amount),
        status: tx.status,
        createdAt: tx.createdAt.toISOString(),
        vendorAddress: hasAddress && vendor ? {
          name: vendor.displayName,
          line1: vendor.addressLine1!,
          line2: vendor.addressLine2 || undefined,
          city: vendor.city!,
          state: vendor.state!,
          zip: vendor.postalCode!,
        } : undefined,
        vendorStripeConnectId: vendor?.vendorPayoutAccount?.stripeAccountId || undefined,
        vendorEmail: vendor?.email || undefined,
        availablePayoutMethods,
        recommendedPayoutMethod,
      };
    });
  }

  /**
   * Preview a batch payment before execution
   */
  @Post('payout/preview')
  @ApiOperation({ summary: 'Preview batch payout' })
  @ApiResponse({ status: 200, type: BatchPayPreviewDto })
  @HttpCode(HttpStatus.OK)
  async previewPayout(
    @Body() dto: ExecutePayoutDto,
  ): Promise<BatchPayPreviewDto> {
    const transactionIds = dto.items.map((i) => i.transactionId);

    const transactions = await this.prisma.transaction.findMany({
      where: { id: { in: transactionIds } },
      include: {
        vendor: true,
      },
    });

    const items = dto.items.map((item) => {
      const tx = transactions.find((t) => t.id === item.transactionId);
      const methodLabels: Record<TransactionPayoutMethod, string> = {
        CHECKBOOK_IO: 'Mail Check',
        STRIPE: 'Stripe Transfer',
        CASH: 'Cash Payment',
        COMPANY_CARD: 'Company Card',
        BANK_TRANSFER: 'Bank Transfer',
      };

      return {
        transactionId: item.transactionId,
        vendorName: tx?.vendor?.displayName || 'Unknown',
        amount: tx ? Number(tx.amount) : 0,
        payoutMethod: item.payoutMethod,
        methodLabel: methodLabels[item.payoutMethod],
      };
    });

    const checkItems = items.filter((i) => i.payoutMethod === TransactionPayoutMethod.CHECKBOOK_IO);
    const stripeItems = items.filter((i) => i.payoutMethod === TransactionPayoutMethod.STRIPE);

    return {
      items,
      totalAmount: items.reduce((sum, i) => sum + i.amount, 0),
      checkCount: checkItems.length,
      stripeCount: stripeItems.length,
      checkTotal: checkItems.reduce((sum, i) => sum + i.amount, 0),
      stripeTotal: stripeItems.reduce((sum, i) => sum + i.amount, 0),
    };
  }

  /**
   * Execute batch payout to vendors
   *
   * Logic:
   * - For CHECKBOOK_IO: Calls CheckbookService.sendPhysicalCheck
   * - For STRIPE: Calls StripePayoutService.transferFunds
   * - Updates Transaction status to PAID_TO_VENDOR
   */
  @Post('payout')
  @ApiOperation({ summary: 'Execute batch payout to vendors' })
  @ApiResponse({ status: 200, type: ExecutePayoutResponseDto })
  @HttpCode(HttpStatus.OK)
  async executePayout(
    @CurrentUser() user: AuthPayload,
    @Body() dto: ExecutePayoutDto,
  ): Promise<ExecutePayoutResponseDto> {
    const results: PayoutResultItemDto[] = [];
    let totalAmount = 0;
    let checksQueued = 0;
    let stripeTransfers = 0;
    let totalCheckAmount = 0;
    let totalStripeAmount = 0;

    for (const item of dto.items) {
      const transaction = await this.prisma.transaction.findUnique({
        where: { id: item.transactionId },
        include: {
          vendor: {
            include: {
              vendorPayoutAccount: true,
            },
          },
          household: true,
        },
      });

      if (!transaction) {
        results.push({
          transactionId: item.transactionId,
          success: false,
          payoutMethod: item.payoutMethod,
          error: 'Transaction not found',
        });
        continue;
      }

      const amount = Number(transaction.amount);
      totalAmount += amount;

      try {
        let referenceId: string | undefined;
        let estimatedDelivery: string | undefined;

        switch (item.payoutMethod) {
          case TransactionPayoutMethod.CHECKBOOK_IO:
            // Send physical check via Checkbook.io
            if (!transaction.vendor?.addressLine1) {
              throw new Error('Vendor address required for check');
            }

            const vendorAddress: VendorAddress = {
              name: transaction.vendor.displayName,
              line1: transaction.vendor.addressLine1,
              line2: transaction.vendor.addressLine2 || undefined,
              city: transaction.vendor.city!,
              state: transaction.vendor.state!,
              zip: transaction.vendor.postalCode!,
            };

            const checkResult = await this.checkbookService.sendPhysicalCheck({
              vendorAddress,
              amount,
              description: transaction.description,
              memo: `Haven Payment - ${transaction.household?.name || ''}`.trim(),
            });

            referenceId = checkResult.checkId;
            estimatedDelivery = checkResult.estimatedDelivery;
            checksQueued++;
            totalCheckAmount += amount;
            break;

          case TransactionPayoutMethod.STRIPE:
            // Transfer via Stripe Connect
            const stripeAccountId = transaction.vendor?.vendorPayoutAccount?.stripeAccountId;
            if (!stripeAccountId) {
              throw new Error('Vendor Stripe Connect account required');
            }

            const transferResult = await this.stripePayoutService.transferFunds({
              stripeConnectId: stripeAccountId,
              amount,
              description: transaction.description,
              metadata: {
                transactionId: transaction.id,
                householdId: transaction.householdId,
              },
            });

            referenceId = transferResult.transferId;
            stripeTransfers++;
            totalStripeAmount += amount;
            break;

          case TransactionPayoutMethod.COMPANY_CARD:
          case TransactionPayoutMethod.CASH:
          case TransactionPayoutMethod.BANK_TRANSFER:
            // Manual payment methods - just mark as paid
            referenceId = `manual_${Date.now()}`;
            break;
        }

        // Update transaction status
        await this.prisma.transaction.update({
          where: { id: transaction.id },
          data: {
            status: TransactionStatus.PAID_TO_VENDOR,
            payoutMethod: item.payoutMethod,
            paidAt: new Date(),
            notes: transaction.notes
              ? `${transaction.notes}\nPaid via ${item.payoutMethod}: ${referenceId}`
              : `Paid via ${item.payoutMethod}: ${referenceId}`,
          },
        });

        results.push({
          transactionId: item.transactionId,
          success: true,
          payoutMethod: item.payoutMethod,
          referenceId,
          estimatedDelivery,
        });
      } catch (error) {
        results.push({
          transactionId: item.transactionId,
          success: false,
          payoutMethod: item.payoutMethod,
          error: error instanceof Error ? error.message : 'Unknown error',
        });
      }
    }

    const successfulItems = results.filter((r) => r.success).length;
    const failedItems = results.filter((r) => !r.success).length;

    return {
      success: failedItems === 0,
      totalAmount,
      totalItems: dto.items.length,
      successfulItems,
      failedItems,
      results,
      summary: {
        checksQueued,
        stripeTransfers,
        totalCheckAmount,
        totalStripeAmount,
      },
    };
  }

  /**
   * Get status of a specific payout
   */
  @Get('payout/:transactionId/status')
  @ApiOperation({ summary: 'Get payout status for a transaction' })
  async getPayoutStatus(
    @Param('transactionId') transactionId: string,
  ): Promise<{ status: string; details?: any }> {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });

    if (!transaction) {
      return { status: 'NOT_FOUND' };
    }

    // If it was a check, we could call checkbookService.getCheckStatus
    // For now, return transaction status
    return {
      status: transaction.status,
      details: {
        paidAt: transaction.paidAt,
        payoutMethod: transaction.payoutMethod,
      },
    };
  }
}
