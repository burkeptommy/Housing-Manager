import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  Headers,
  UseGuards,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiHeader,
} from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';

import { JwtAuthGuard, CurrentUser, JwtPayload } from '../auth';
import { InvoicesService } from './invoices.service';
import {
  HouseholdInvoiceDto,
  HouseholdInvoiceListItemDto,
  BillingSummaryDto,
  GenerateInvoicesResultDto,
  SetupHouseholdStripeDto,
  UpdateBillingPreferencesDto,
} from './dto';

@ApiTags('Invoices')
@Controller()
export class InvoicesController {
  constructor(
    private readonly invoicesService: InvoicesService,
    private readonly configService: ConfigService,
  ) {}

  // ============================================================================
  // Public Invoice Endpoints
  // ============================================================================

  @Get('invoices')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List consolidated invoices for a household' })
  @ApiResponse({ status: 200, type: [HouseholdInvoiceListItemDto] })
  async getInvoices(
    @Query('householdId') householdId: string,
    @CurrentUser() _user: JwtPayload,
  ): Promise<HouseholdInvoiceListItemDto[]> {
    // TODO: Verify user has access to this household
    return this.invoicesService.getInvoices(householdId);
  }

  @Get('invoices/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get invoice details' })
  @ApiResponse({ status: 200, type: HouseholdInvoiceDto })
  async getInvoiceById(
    @Param('id') invoiceId: string,
    @Query('householdId') householdId: string,
    @CurrentUser() _user: JwtPayload,
  ): Promise<HouseholdInvoiceDto> {
    // TODO: Verify user has access to this household
    return this.invoicesService.getInvoiceById(invoiceId, householdId);
  }

  @Get('billing/summary')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get billing summary for dashboard' })
  @ApiResponse({ status: 200, type: BillingSummaryDto })
  async getBillingSummary(
    @Query('householdId') householdId: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<BillingSummaryDto> {
    // TODO: Verify user has access to this household
    return this.invoicesService.getBillingSummary(householdId, user.sub);
  }

  // ============================================================================
  // Household Stripe Setup
  // ============================================================================

  @Post('billing/setup-stripe')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Setup Stripe customer for household billing' })
  @ApiResponse({ status: 201 })
  async setupHouseholdStripe(
    @Query('householdId') householdId: string,
    @Body() dto: SetupHouseholdStripeDto,
    @CurrentUser() _user: JwtPayload,
  ): Promise<{ stripeCustomerId: string }> {
    // TODO: Verify user is owner of this household
    return this.invoicesService.setupHouseholdStripe(
      householdId,
      dto.paymentMethodId,
    );
  }

  @Patch('billing/preferences')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update billing preferences' })
  @ApiResponse({ status: 200 })
  async updateBillingPreferences(
    @Query('householdId') householdId: string,
    @Body() dto: UpdateBillingPreferencesDto,
    @CurrentUser() _user: JwtPayload,
  ): Promise<{ success: boolean }> {
    // TODO: Verify user is owner of this household
    await this.invoicesService.updateBillingPreferences(
      householdId,
      dto.consolidatedBillingDay,
    );
    return { success: true };
  }

  // ============================================================================
  // Internal Cron Endpoint (for GCP Cloud Scheduler)
  // ============================================================================

  @Post('internal/cron/generate-invoices')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Generate consolidated invoices (cron job)' })
  @ApiHeader({
    name: 'x-cron-secret',
    description: 'Shared secret for cron authentication',
    required: true,
  })
  @ApiResponse({ status: 200, type: GenerateInvoicesResultDto })
  async generateInvoices(
    @Headers('x-cron-secret') cronSecret: string,
  ): Promise<GenerateInvoicesResultDto> {
    // Validate cron secret
    const expectedSecret = this.configService.get<string>('CRON_SECRET');
    if (!expectedSecret || cronSecret !== expectedSecret) {
      throw new UnauthorizedException('Invalid cron secret');
    }

    return this.invoicesService.generateConsolidatedInvoices();
  }

  // ============================================================================
  // Stripe Webhook Handlers (called from billing-webhook.controller.ts)
  // Note: These would typically be called from the existing webhook controller
  // ============================================================================

  /**
   * Handle payment_intent.succeeded webhook
   * Called from billing-webhook.controller.ts or can be called directly
   */
  async handlePaymentSuccess(paymentIntentId: string): Promise<void> {
    return this.invoicesService.handlePaymentSuccess(paymentIntentId);
  }

  /**
   * Handle payment_intent.payment_failed webhook
   * Called from billing-webhook.controller.ts or can be called directly
   */
  async handlePaymentFailure(
    paymentIntentId: string,
    failureReason: string,
  ): Promise<void> {
    return this.invoicesService.handlePaymentFailure(
      paymentIntentId,
      failureReason,
    );
  }
}
