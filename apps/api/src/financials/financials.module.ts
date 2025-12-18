import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from '../auth';

import { CheckbookService } from './checkbook.service';
import { StripePayoutService } from './stripe-payout.service';
import { PayoutController } from './payout.controller';

@Module({
  imports: [AuthModule, ConfigModule],
  controllers: [PayoutController],
  providers: [CheckbookService, StripePayoutService],
  exports: [CheckbookService, StripePayoutService],
})
export class FinancialsModule {}
