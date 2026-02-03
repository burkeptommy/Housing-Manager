import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
import { CurrentUser } from '../firebase/current-user.decorator';
import { AuthPayload } from '../firebase';
import { BudgetingService } from './budgeting.service';
import { ForecastService } from './forecast.service';
import { InsightsService } from './insights.service';

@Controller('budgeting')
@UseGuards(FirebaseAuthGuard)
export class BudgetingController {
  constructor(
    private readonly budgetingService: BudgetingService,
    private readonly forecastService: ForecastService,
    private readonly insightsService: InsightsService,
  ) {}

  // === BUDGET SETUP ===

  @Get('budget')
  async getBudget(@CurrentUser() user: AuthPayload) {
    return this.budgetingService.getBudget(user);
  }

  @Post('budget')
  async createOrUpdateBudget(
    @CurrentUser() user: AuthPayload,
    @Body() body: { monthlyIncome?: number; categories: Array<{ categoryId: string; groupId: string; budgetedAmount: number }> },
  ) {
    return this.budgetingService.createOrUpdateBudget(user, body);
  }

  @Put('budget/category/:categoryId')
  async updateCategoryBudget(
    @CurrentUser() user: AuthPayload,
    @Param('categoryId') categoryId: string,
    @Body() body: { budgetedAmount: number },
  ) {
    return this.budgetingService.updateCategoryBudget(user, categoryId, body.budgetedAmount);
  }

  // === SPENDING ANALYSIS ===

  @Get('spending/summary')
  async getSpendingSummary(
    @CurrentUser() user: AuthPayload,
    @Query('month') month?: string,
  ) {
    return this.budgetingService.getSpendingSummary(user, month);
  }

  @Get('spending/by-category')
  async getSpendingByCategory(
    @CurrentUser() user: AuthPayload,
    @Query('month') month?: string,
  ) {
    return this.budgetingService.getSpendingByCategory(user, month);
  }

  @Get('spending/trends')
  async getSpendingTrends(
    @CurrentUser() user: AuthPayload,
    @Query('months') months?: string,
  ) {
    return this.budgetingService.getSpendingTrends(user, months ? parseInt(months) : 6);
  }

  @Get('spending/comparisons')
  async getLocalComparisons(@CurrentUser() user: AuthPayload) {
    return this.budgetingService.getLocalComparisons(user);
  }

  // === TRANSACTIONS ===

  @Get('transactions')
  async getTransactions(
    @CurrentUser() user: AuthPayload,
    @Query('month') month?: string,
    @Query('category') category?: string,
    @Query('limit') limit?: string,
  ) {
    return this.budgetingService.getTransactions(user, {
      month,
      category,
      limit: limit ? parseInt(limit) : undefined,
    });
  }

  @Put('transactions/:id/categorize')
  async categorizeTransaction(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
    @Body() body: { categoryId: string; groupId: string },
  ) {
    return this.budgetingService.categorizeTransaction(user, id, body);
  }

  @Post('transactions/manual')
  async addManualTransaction(
    @CurrentUser() user: AuthPayload,
    @Body() body: { date: string; amount: number; name: string; categoryId?: string; groupId?: string; notes?: string },
  ) {
    return this.budgetingService.addManualTransaction(user, body);
  }

  // === HOME FORECASTING ===

  @Get('forecast')
  async getHomeForecasts(@CurrentUser() user: AuthPayload) {
    return this.forecastService.getHomeForecasts(user);
  }

  @Get('forecast/timeline')
  async getForecastTimeline(
    @CurrentUser() user: AuthPayload,
    @Query('years') years?: string,
  ) {
    return this.forecastService.getForecastTimeline(user, years ? parseInt(years) : 10);
  }

  @Get('forecast/system-types')
  getSystemTypes() {
    return this.forecastService.getSystemTypes();
  }

  @Post('forecast/system')
  async addSystemForecast(
    @CurrentUser() user: AuthPayload,
    @Body() body: { systemType: string; systemName: string; installYear?: number; estimatedReplacementCost?: number; notes?: string },
  ) {
    return this.forecastService.addSystemForecast(user, body);
  }

  @Put('forecast/system/:id')
  async updateSystemForecast(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
    @Body() body: { systemName?: string; installYear?: number; estimatedReplacementCost?: number; notes?: string },
  ) {
    return this.forecastService.updateSystemForecast(user, id, body);
  }

  @Post('forecast/system/:id/alfred-research')
  async requestAlfredResearch(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
  ) {
    return this.forecastService.requestAlfredResearch(user, id);
  }

  // === INSIGHTS ===

  @Get('insights')
  async getBudgetInsights(@CurrentUser() user: AuthPayload) {
    return this.insightsService.getBudgetInsights(user);
  }
}
