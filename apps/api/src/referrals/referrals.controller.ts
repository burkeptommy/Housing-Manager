import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../firebase';
import { ReferralsService } from './referrals.service';
import { CreateReferralDto, ApplyReferralDto } from './dto';

@ApiTags('referrals')
@Controller('referrals')
export class ReferralsController {
  constructor(private readonly referralsService: ReferralsService) {}

  /**
   * Get referral statistics for the current user
   */
  @Get('stats')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get referral statistics' })
  async getStats(@Request() req: any) {
    const userId = req.user.userId || req.user.id;
    return this.referralsService.getUserReferralStats(userId);
  }

  /**
   * Get all referrals sent by the current user
   */
  @Get()
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all referrals' })
  async getReferrals(@Request() req: any) {
    const userId = req.user.userId || req.user.id;
    return this.referralsService.getUserReferrals(userId);
  }

  /**
   * Get referral code for current user
   */
  @Get('code')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get or create referral code' })
  async getReferralCode(@Request() req: any) {
    const userId = req.user.userId || req.user.id;
    const code = await this.referralsService.getOrCreateUserReferralCode(userId);
    return {
      code,
      shareUrl: `https://havenhome.dev/r/${code}`,
    };
  }

  /**
   * Create a new referral (optionally with specific email)
   */
  @Post()
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new referral' })
  async createReferral(@Request() req: any, @Body() dto: CreateReferralDto) {
    const userId = req.user.userId || req.user.id;
    return this.referralsService.createReferral(userId, dto);
  }

  /**
   * Validate a referral code (public endpoint for signup page)
   */
  @Get('validate/:code')
  @ApiOperation({ summary: 'Validate a referral code' })
  async validateCode(@Param('code') code: string) {
    const referral = await this.referralsService.getReferralByCode(code);
    if (!referral) {
      return { valid: false };
    }
    return {
      valid: true,
      referralCode: code,
    };
  }

  /**
   * Apply a referral code to the current user's account
   */
  @Post('apply')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Apply a referral code' })
  async applyReferralCode(@Request() req: any, @Body() dto: ApplyReferralDto) {
    const userId = req.user.userId || req.user.id;
    await this.referralsService.applyReferralCode(userId, dto.referralCode);
    return { success: true };
  }
}
