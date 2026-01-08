import { Module } from '@nestjs/common';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';
import { ActivityModule } from '../activity';
import { HomeHealthModule } from '../home-health/home-health.module';

@Module({
  imports: [ActivityModule, HomeHealthModule],
  controllers: [DashboardController],
  providers: [DashboardService],
  exports: [DashboardService],
})
export class DashboardModule {}
