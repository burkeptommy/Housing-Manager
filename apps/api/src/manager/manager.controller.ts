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

@ApiTags('Manager')
@ApiBearerAuth()
@Controller('manager')
@UseGuards(FirebaseAuthGuard)
export class ManagerController {
  constructor(private managerService: ManagerService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get manager dashboard data' })
  async getDashboard(@Request() req: any) {
    return this.managerService.getDashboard(req.user.id);
  }

  @Get('households')
  @ApiOperation({ summary: 'Get households assigned to this manager' })
  async getMyHouseholds(@Request() req: any) {
    return this.managerService.getMyHouseholds(req.user.id);
  }

  @Get('households/:id')
  @ApiOperation({ summary: 'Get detailed household information' })
  async getHouseholdDetail(@Request() req: any, @Param('id') householdId: string) {
    return this.managerService.getHouseholdDetail(req.user.id, householdId);
  }

  @Get('onboarding/queue')
  @ApiOperation({ summary: 'Get onboarding queue for this manager' })
  async getOnboardingQueue(@Request() req: any, @Query('status') status?: string) {
    return this.managerService.getOnboardingQueue(req.user.id, status);
  }

  @Get('activity')
  @ApiOperation({ summary: 'Get activity across managed households' })
  async getMyActivity(@Request() req: any, @Query('limit') limit?: string) {
    return this.managerService.getMyActivity(req.user.id, limit ? parseInt(limit) : undefined);
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
      req.user.id,
      req.user.displayName || req.user.firstName || 'Home Manager',
      body,
    );
  }
}
