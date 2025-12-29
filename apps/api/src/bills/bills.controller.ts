import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
import { BillsService } from './bills.service';

@Controller('bills')
@UseGuards(FirebaseAuthGuard)
export class BillsController {
  constructor(private billsService: BillsService) {}

  /**
   * Get bill detail with transaction history
   */
  @Get(':billId')
  async getBillDetail(
    @Param('billId') billId: string,
    @Query('householdId') householdId: string,
  ) {
    return this.billsService.getBillDetail(billId, householdId);
  }

  /**
   * Update bill management status
   */
  @Put(':billId/management')
  async updateManagementStatus(
    @Param('billId') billId: string,
    @Body() body: { householdId: string; managementStatus: string },
  ) {
    return this.billsService.updateBillManagement(
      billId,
      body.householdId,
      body.managementStatus,
    );
  }

  /**
   * Update bill notes
   */
  @Put(':billId/notes')
  async updateBillNotes(
    @Param('billId') billId: string,
    @Body() body: { householdId: string; notes: string },
  ) {
    return this.billsService.updateBillNotes(billId, body.householdId, body.notes);
  }
}
