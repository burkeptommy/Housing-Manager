import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { BillService, CreateBillDto } from './bill.service';
import { PaymentExecutionService } from './payment-execution.service';
import { FirebaseAuthGuard } from '../firebase';

@Controller('payments/bills')
@UseGuards(FirebaseAuthGuard)
export class BillController {
  constructor(
    private billService: BillService,
    private paymentService: PaymentExecutionService,
  ) {}

  @Post()
  async createBill(@Req() req: any, @Body() data: CreateBillDto) {
    const { householdId } = req.user;
    return this.billService.createBill(householdId, data);
  }

  @Post('from-detected/:detectedBillId')
  async createFromDetected(
    @Req() req: any,
    @Param('detectedBillId') detectedBillId: string,
    @Body() data: {
      paymentMethod: string;
      paymentEmail?: string;
      mailingAddress?: string;
      paymentPortalUrl?: string;
    },
  ) {
    const { householdId } = req.user;
    return this.billService.createBillFromDetected(
      householdId,
      detectedBillId,
      data.paymentMethod,
      data,
    );
  }

  @Get()
  async getBills(@Req() req: any, @Query('status') status?: string) {
    const { householdId } = req.user;
    return this.billService.getBills(householdId, status);
  }

  @Get('upcoming')
  async getUpcomingBills(@Req() req: any, @Query('days') days?: string) {
    const { householdId } = req.user;
    return this.billService.getUpcomingBills(householdId, days ? parseInt(days) : 7);
  }

  @Get('summary')
  async getBillSummary(@Req() req: any) {
    const { householdId } = req.user;
    return this.billService.getBillSummary(householdId);
  }

  @Put(':id')
  async updateBill(
    @Req() req: any,
    @Param('id') id: string,
    @Body() data: Partial<CreateBillDto>,
  ) {
    const { householdId } = req.user;
    return this.billService.updateBill(id, householdId, data);
  }

  @Post(':id/toggle-autopay')
  async toggleAutopay(
    @Req() req: any,
    @Param('id') id: string,
    @Body('enabled') enabled: boolean,
  ) {
    const { householdId } = req.user;
    return this.billService.toggleAutopay(id, householdId, enabled);
  }

  @Delete(':id')
  async cancelBill(@Req() req: any, @Param('id') id: string) {
    const { householdId } = req.user;
    return this.billService.cancelBill(id, householdId);
  }

  // Payment endpoints
  @Post(':id/pay')
  async payBill(
    @Req() req: any,
    @Param('id') id: string,
    @Body('amount') amount?: number,
  ) {
    return this.paymentService.executePayment(id, amount);
  }

  @Get(':id/payments')
  async getPaymentHistory(@Param('id') id: string) {
    return this.paymentService.getPaymentHistory(id);
  }

  @Post('payments/:paymentId/retry')
  async retryPayment(@Param('paymentId') paymentId: string) {
    return this.paymentService.retryPayment(paymentId);
  }

  @Get('payments/all')
  async getAllPayments(
    @Req() req: any,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
  ) {
    const { householdId } = req.user;
    return this.paymentService.getHouseholdPayments(householdId, {
      status,
      limit: limit ? parseInt(limit) : undefined,
    });
  }
}
