import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam, ApiQuery } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../firebase';
import { ActivityService, GetActivityOptions } from './activity.service';
import { ActivityCategory } from '@prisma/client';

@ApiTags('Activity')
@ApiBearerAuth()
@Controller('activity')
@UseGuards(FirebaseAuthGuard)
export class ActivityController {
  constructor(private readonly activityService: ActivityService) {}

  @Get('household/:householdId')
  @ApiOperation({ summary: 'Get all activity for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiQuery({ name: 'limit', required: false, description: 'Max number of activities to return' })
  @ApiQuery({ name: 'category', required: false, description: 'Filter by category' })
  async getActivity(
    @Param('householdId') householdId: string,
    @Query('limit') limit?: string,
    @Query('category') category?: ActivityCategory,
  ) {
    const options: GetActivityOptions = {
      limit: limit ? parseInt(limit, 10) : 20,
      category,
      visibleToHomeowner: true,
    };
    return this.activityService.getForHousehold(householdId, options);
  }

  @Get('household/:householdId/recent')
  @ApiOperation({ summary: 'Get recent activity for a household (last 10)' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  async getRecentActivity(@Param('householdId') householdId: string) {
    return this.activityService.getRecentForHomeowner(householdId, 10);
  }

  @Get('household/:householdId/category/:category')
  @ApiOperation({ summary: 'Get activity by category' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'category', description: 'Activity category' })
  @ApiQuery({ name: 'limit', required: false, description: 'Max number of activities to return' })
  async getActivityByCategory(
    @Param('householdId') householdId: string,
    @Param('category') category: ActivityCategory,
    @Query('limit') limit?: string,
  ) {
    return this.activityService.getByCategory(
      householdId,
      category,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Get('household/:householdId/summary')
  @ApiOperation({ summary: 'Get activity summary by category for a date range' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiQuery({ name: 'startDate', required: true, description: 'Start date (ISO format)' })
  @ApiQuery({ name: 'endDate', required: true, description: 'End date (ISO format)' })
  async getActivitySummary(
    @Param('householdId') householdId: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.activityService.getActivitySummary(
      householdId,
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get('household/:householdId/bill/:billId')
  @ApiOperation({ summary: 'Get activity for a specific bill' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'billId', description: 'Bill ID' })
  async getActivityForBill(
    @Param('householdId') householdId: string,
    @Param('billId') billId: string,
  ) {
    return this.activityService.getForBill(householdId, billId);
  }

  @Get('household/:householdId/vendor/:vendorId')
  @ApiOperation({ summary: 'Get activity for a specific vendor' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  async getActivityForVendor(
    @Param('householdId') householdId: string,
    @Param('vendorId') vendorId: string,
  ) {
    return this.activityService.getForVendor(householdId, vendorId);
  }

  @Get('household/:householdId/asset/:assetId')
  @ApiOperation({ summary: 'Get activity for a specific asset' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'assetId', description: 'Asset ID' })
  async getActivityForAsset(
    @Param('householdId') householdId: string,
    @Param('assetId') assetId: string,
  ) {
    return this.activityService.getForAsset(householdId, assetId);
  }
}
