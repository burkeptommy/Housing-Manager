import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  UseGuards,
  Query,
  NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../../firebase';
import { RolesGuard, Roles } from '../../auth';
import { ManagerOnboardingService } from './onboarding.service';

@ApiTags('Manager Onboarding')
@ApiBearerAuth()
@Controller('manager/onboarding')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles('MANAGER', 'ADMIN')
export class ManagerOnboardingController {
  constructor(private readonly onboardingService: ManagerOnboardingService) {}

  /**
   * Get queue of households pending onboarding
   */
  @Get('queue')
  @ApiOperation({ summary: 'Get onboarding queue' })
  @ApiResponse({ status: 200, description: 'List of households pending onboarding' })
  async getQueue(@Query('status') status?: string) {
    return this.onboardingService.getQueue(status);
  }

  /**
   * Get single session with full details for intake
   */
  @Get(':id')
  @ApiOperation({ summary: 'Get onboarding session details' })
  @ApiResponse({ status: 200, description: 'Session details with household data' })
  @ApiResponse({ status: 404, description: 'Session not found' })
  async getSession(@Param('id') id: string) {
    const session = await this.onboardingService.getSession(id);
    if (!session) {
      throw new NotFoundException('Onboarding session not found');
    }
    return session;
  }

  /**
   * Update intake progress
   */
  @Put(':id/intake')
  @ApiOperation({ summary: 'Update intake data for a section' })
  async updateIntake(
    @Param('id') id: string,
    @Body() body: {
      section: string;
      data: any;
      progress?: number;
    },
  ) {
    return this.onboardingService.updateIntake(id, body);
  }

  /**
   * Start call
   */
  @Post(':id/start-call')
  @ApiOperation({ summary: 'Mark call as started' })
  async startCall(@Param('id') id: string) {
    return this.onboardingService.startCall(id);
  }

  /**
   * Complete intake
   */
  @Post(':id/complete')
  @ApiOperation({ summary: 'Complete the intake process' })
  async completeIntake(
    @Param('id') id: string,
    @Body() body: {
      callNotes?: string;
      followUpNeeded?: boolean;
      followUpNotes?: string;
    },
  ) {
    return this.onboardingService.completeIntake(id, body);
  }

  /**
   * Deliver profile to homeowner
   */
  @Post(':id/deliver-profile')
  @ApiOperation({ summary: 'Mark profile as delivered to homeowner' })
  async deliverProfile(@Param('id') id: string) {
    return this.onboardingService.deliverProfile(id);
  }
}
