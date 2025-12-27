import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { OnboardingService, CompleteSignupDto } from './onboarding.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('onboarding')
@UseGuards(JwtAuthGuard)
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  /**
   * Complete the initial signup flow
   * Called after user enters their challenge and address
   */
  @Post('complete-signup')
  async completeSignup(
    @Request() req: any,
    @Body() data: CompleteSignupDto,
  ) {
    return this.onboardingService.completeSignup(req.user.userId, data);
  }

  /**
   * Schedule an intro call with a Home Manager
   */
  @Post('schedule-call')
  async scheduleCall(
    @Request() req: any,
    @Body() data: { scheduledAt: string },
  ) {
    return this.onboardingService.scheduleCall(
      req.user.userId,
      new Date(data.scheduledAt),
    );
  }

  /**
   * Get current onboarding status
   */
  @Get('status')
  async getStatus(@Request() req: any) {
    return this.onboardingService.getStatus(req.user.userId);
  }
}
