import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from '../prisma/prisma.module';
import { FinancialsModule } from '../financials/financials.module';
import { PlaidModule } from '../plaid/plaid.module';
import { CardService } from './card.service';
import { CardController } from './card.controller';
import { BillService } from './bill.service';
import { BillController } from './bill.controller';
import { PaymentExecutionService } from './payment-execution.service';
import { OrchestrationService } from './orchestration.service';
import { OrchestrationController } from './orchestration.controller';
import { ApprovalController } from './approval.controller';
import { PaymentScheduler } from './payment.scheduler';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';

@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    FinancialsModule,
    PlaidModule,
    ScheduleModule.forRoot(),
  ],
  controllers: [
    CardController,
    BillController,
    ApprovalController,
    OrchestrationController,
    DashboardController,
  ],
  providers: [
    CardService,
    BillService,
    PaymentExecutionService,
    OrchestrationService,
    PaymentScheduler,
    DashboardService,
  ],
  exports: [
    CardService,
    BillService,
    PaymentExecutionService,
    OrchestrationService,
    DashboardService,
  ],
})
export class PaymentsModule {}
