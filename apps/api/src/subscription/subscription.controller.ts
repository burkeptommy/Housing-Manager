import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { SubscriptionService } from './subscription.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('subscription')
@UseGuards(JwtAuthGuard)
export class SubscriptionController {
  constructor(private subscriptionService: SubscriptionService) {}

  @Get('current')
  async getCurrentSubscription(@Request() req) {
    const userId = req.user.sub || req.user.userId || req.user.id;
    return this.subscriptionService.getSubscription(userId);
  }
}
