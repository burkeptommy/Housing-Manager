import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { WalkthroughService } from './walkthrough.service';
import { RequestWalkthroughDto } from './dto/walkthrough.dto';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

@Controller('walkthrough')
export class WalkthroughController {
  constructor(private readonly walkthroughService: WalkthroughService) {}

  /**
   * Check if a household is eligible for a free walkthrough
   */
  @Get('eligibility/:householdId')
  @UseGuards(FirebaseAuthGuard)
  async checkEligibility(@Param('householdId') householdId: string) {
    return this.walkthroughService.checkEligibility(householdId);
  }

  /**
   * Request a free home walkthrough
   */
  @Post('request')
  @UseGuards(FirebaseAuthGuard)
  async requestWalkthrough(
    @Request() req,
    @Body() dto: RequestWalkthroughDto,
  ) {
    const userId = req.user.uid;
    return this.walkthroughService.requestWalkthrough(userId, dto);
  }

  /**
   * Get all walkthrough requests (admin)
   */
  @Get('requests')
  @UseGuards(FirebaseAuthGuard)
  async getWalkthroughRequests(@Query('status') status?: string) {
    return this.walkthroughService.getWalkthroughRequests(status);
  }
}
