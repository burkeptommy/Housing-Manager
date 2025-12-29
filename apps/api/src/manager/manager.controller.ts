import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../firebase';
import { ManagerService } from './manager.service';
import { ActivityAction, ActivityCategory } from '@prisma/client';
import { BillsService } from '../bills/bills.service';

@ApiTags('Manager')
@ApiBearerAuth()
@Controller('manager')
@UseGuards(FirebaseAuthGuard)
export class ManagerController {
  constructor(
    private managerService: ManagerService,
    private billsService: BillsService,
  ) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get manager dashboard data' })
  async getDashboard(@Request() req: any) {
    return this.managerService.getDashboard(req.user.userId);
  }

  @Get('households')
  @ApiOperation({ summary: 'Get households assigned to this manager' })
  async getMyHouseholds(@Request() req: any) {
    return this.managerService.getMyHouseholds(req.user.userId);
  }

  @Get('households/:id')
  @ApiOperation({ summary: 'Get detailed household information' })
  async getHouseholdDetail(@Request() req: any, @Param('id') householdId: string) {
    return this.managerService.getHouseholdDetail(req.user.userId, householdId);
  }

  @Get('onboarding/queue')
  @ApiOperation({ summary: 'Get onboarding queue for this manager' })
  async getOnboardingQueue(@Request() req: any, @Query('status') status?: string) {
    return this.managerService.getOnboardingQueue(req.user.userId, status);
  }

  @Get('activity')
  @ApiOperation({ summary: 'Get activity across managed households' })
  async getMyActivity(@Request() req: any, @Query('limit') limit?: string) {
    return this.managerService.getMyActivity(req.user.userId, limit ? parseInt(limit) : undefined);
  }

  @Post('activity')
  @ApiOperation({ summary: 'Log an activity' })
  async logActivity(
    @Request() req: any,
    @Body()
    body: {
      householdId: string;
      action: ActivityAction;
      category: ActivityCategory;
      title: string;
      description?: string;
      amount?: number;
    },
  ) {
    return this.managerService.logActivity(
      req.user.userId,
      req.user.email || 'Home Manager',
      body,
    );
  }

  @Get('bills')
  @ApiOperation({ summary: 'Get bills pending setup or managed by Haven' })
  async getManagerBills(@Query('filter') filter: string = 'pending_setup') {
    return this.billsService.getManagerBills(filter);
  }
}
