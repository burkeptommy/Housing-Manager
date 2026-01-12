import { Controller, Get, Query, UseGuards, Req } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { FirebaseAuthGuard } from '../firebase';

@Controller('payments/dashboard')
@UseGuards(FirebaseAuthGuard)
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  @Get()
  async getDashboard(@Req() req: any) {
    const { householdId } = req.user;
    return this.dashboardService.getDashboard(householdId);
  }

  @Get('bills')
  async getAllBills(@Req() req: any) {
    const { householdId } = req.user;
    return this.dashboardService.getAllBills(householdId);
  }

  @Get('history')
  async getPaymentHistory(
    @Req() req: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('status') status?: string,
    @Query('category') category?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const { householdId } = req.user;
    return this.dashboardService.getPaymentHistory(householdId, {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      status,
      category,
      limit: limit ? parseInt(limit) : undefined,
      offset: offset ? parseInt(offset) : undefined,
    });
  }

  @Get('monthly')
  async getMonthlyBreakdown(
    @Req() req: any,
    @Query('year') year?: string,
    @Query('month') month?: string,
  ) {
    const { householdId } = req.user;
    return this.dashboardService.getMonthlyBreakdown(
      householdId,
      year ? parseInt(year) : undefined,
      month ? parseInt(month) : undefined,
    );
  }

  @Get('annual')
  async getAnnualSummary(
    @Req() req: any,
    @Query('year') year?: string,
  ) {
    const { householdId } = req.user;
    return this.dashboardService.getAnnualSummary(
      householdId,
      year ? parseInt(year) : undefined,
    );
  }

  @Get('detected')
  async getDetectedBills(@Req() req: any) {
    const { householdId } = req.user;
    return this.dashboardService.getDetectedBills(householdId);
  }
}
