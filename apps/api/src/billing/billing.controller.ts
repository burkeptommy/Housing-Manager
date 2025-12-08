import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';

import { JwtAuthGuard, CurrentUser, JwtPayload } from '../auth';

import { BillingService } from './billing.service';
import { CreateSubscriptionDto, SubscriptionDto, CancelSubscriptionDto } from './dto';

@ApiTags('Billing')
@ApiBearerAuth()
@Controller('billing')
@UseGuards(JwtAuthGuard)
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  @Post('subscribe')
  @ApiOperation({ summary: 'Create a new subscription' })
  @ApiResponse({ status: 201, description: 'Subscription created', type: SubscriptionDto })
  @ApiResponse({ status: 400, description: 'Invalid input or already subscribed' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async subscribe(
    @Body() dto: CreateSubscriptionDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<SubscriptionDto> {
    return this.billingService.createSubscription(dto, user);
  }

  @Get('subscription')
  @ApiOperation({ summary: 'Get current subscription' })
  @ApiResponse({ status: 200, description: 'Current subscription', type: SubscriptionDto })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getCurrentSubscription(
    @CurrentUser() user: JwtPayload,
  ): Promise<SubscriptionDto | null> {
    return this.billingService.getCurrentSubscription(user);
  }

  @Delete('subscription')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel subscription' })
  @ApiResponse({ status: 200, description: 'Subscription cancelled', type: SubscriptionDto })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'No active subscription found' })
  async cancelSubscription(
    @Body() dto: CancelSubscriptionDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<SubscriptionDto> {
    return this.billingService.cancelSubscription(user, dto.cancelAtPeriodEnd ?? true);
  }
}
