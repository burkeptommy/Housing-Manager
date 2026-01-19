import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../firebase';
import { DashboardService } from './dashboard.service';

class CreateBillDto {
  name: string;
  category: string;
  amount: number;
  frequency: string;
  dueDay?: number | null;
}

@ApiTags('Dashboard')
@ApiBearerAuth()
@Controller('dashboard')
@UseGuards(FirebaseAuthGuard)
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('household/:householdId')
  @ApiOperation({ summary: 'Get dashboard data for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Dashboard data' })
  @ApiResponse({ status: 404, description: 'Household not found' })
  async getDashboard(@Param('householdId') householdId: string) {
    return this.dashboardService.getDashboard(householdId);
  }

  @Get('household/:householdId/billing')
  @ApiOperation({ summary: 'Get billing summary for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  async getBillingSummary(@Param('householdId') householdId: string) {
    return this.dashboardService.getMonthlySummary(householdId);
  }

  @Get('household/:householdId/health')
  @ApiOperation({ summary: 'Get home health score for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  async getHomeHealth(@Param('householdId') householdId: string) {
    return this.dashboardService.getFullHealthScore(householdId);
  }

  @Get('household/:householdId/today')
  @ApiOperation({ summary: 'Get today\'s notes and reminders for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Today\'s notes aggregated from various sources' })
  async getTodaysNotes(@Param('householdId') householdId: string) {
    return this.dashboardService.getTodaysNotes(householdId);
  }

  @Get('household/:householdId/setup-status')
  @ApiOperation({ summary: 'Get setup/onboarding status for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Setup checklist status' })
  async getSetupStatus(@Param('householdId') householdId: string) {
    return this.dashboardService.getSetupStatus(householdId);
  }

  @Get('household/:householdId/upcoming')
  @ApiOperation({ summary: 'Get upcoming items for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  async getUpcoming(@Param('householdId') householdId: string) {
    return this.dashboardService.getUpcomingItems(householdId, 14);
  }

  @Get('household/:householdId/bills')
  @ApiOperation({ summary: 'Get all bills for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  async getBills(@Param('householdId') householdId: string) {
    return this.dashboardService.getBills(householdId);
  }

  @Post('household/:householdId/bills')
  @ApiOperation({ summary: 'Create a new bill for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  async createBill(
    @Param('householdId') householdId: string,
    @Body() dto: CreateBillDto,
  ) {
    return this.dashboardService.createBill(householdId, dto);
  }

  @Get('household/:householdId/family')
  @ApiOperation({ summary: 'Get family data for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  async getFamily(@Param('householdId') householdId: string) {
    return this.dashboardService.getFamily(householdId);
  }

  @Get('household/:householdId/onboarding')
  @ApiOperation({ summary: 'Get onboarding checklist status for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Onboarding checklist status' })
  async getOnboardingChecklist(@Param('householdId') householdId: string) {
    return this.dashboardService.getOnboardingChecklist(householdId);
  }
}
