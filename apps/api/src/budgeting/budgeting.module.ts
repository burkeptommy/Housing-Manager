import { Module } from '@nestjs/common';
import { BudgetingController } from './budgeting.controller';
import { BudgetingService } from './budgeting.service';
import { ForecastService } from './forecast.service';
import { InsightsService } from './insights.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [BudgetingController],
  providers: [BudgetingService, ForecastService, InsightsService],
  exports: [BudgetingService, ForecastService],
})
export class BudgetingModule {}
