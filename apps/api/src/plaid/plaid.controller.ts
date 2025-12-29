import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
import { PlaidService } from './plaid.service';

@Controller('plaid')
@UseGuards(FirebaseAuthGuard)
export class PlaidController {
  constructor(private plaidService: PlaidService) {}

  /**
   * Create a link token for Plaid Link
   */
  @Post('link-token')
  async createLinkToken(
    @Request() req: any,
    @Body() body: { householdId: string },
  ) {
    const linkToken = await this.plaidService.createLinkToken(
      req.user.userId || req.user.id,
      body.householdId,
    );
    return { linkToken };
  }

  /**
   * Exchange public token after user completes Plaid Link
   */
  @Post('exchange-token')
  async exchangeToken(
    @Body() body: { householdId: string; publicToken: string },
  ) {
    return this.plaidService.exchangePublicToken(
      body.householdId,
      body.publicToken,
    );
  }

  /**
   * Get all bank connections for a household
   */
  @Get('connections/:householdId')
  async getConnections(@Param('householdId') householdId: string) {
    return this.plaidService.getConnections(householdId);
  }

  /**
   * Sync transactions for a connection
   */
  @Post('connections/:connectionId/sync')
  async syncTransactions(@Param('connectionId') connectionId: string) {
    const billCount = await this.plaidService.syncTransactions(connectionId);
    return { billsDetected: billCount };
  }

  /**
   * Remove a bank connection
   */
  @Delete('connections/:connectionId')
  async removeConnection(
    @Param('connectionId') connectionId: string,
    @Query('householdId') householdId: string,
  ) {
    return this.plaidService.removeConnection(connectionId, householdId);
  }

  /**
   * Get detected bills for a household
   */
  @Get('bills/:householdId')
  async getDetectedBills(
    @Param('householdId') householdId: string,
    @Query('status') status?: string,
  ) {
    return this.plaidService.getDetectedBills(householdId, status);
  }

  /**
   * Get detected bills summary
   */
  @Get('bills/:householdId/summary')
  async getBillsSummary(@Param('householdId') householdId: string) {
    return this.plaidService.getDetectedBillsSummary(householdId);
  }

  /**
   * Confirm a detected bill
   */
  @Put('bills/:billId/confirm')
  async confirmBill(@Param('billId') billId: string) {
    return this.plaidService.confirmBill(billId);
  }

  /**
   * Dismiss a detected bill
   */
  @Put('bills/:billId/dismiss')
  async dismissBill(@Param('billId') billId: string) {
    return this.plaidService.dismissBill(billId);
  }
}
