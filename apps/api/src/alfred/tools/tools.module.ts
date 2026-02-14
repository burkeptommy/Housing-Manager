import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { PaymentsModule } from '../../payments/payments.module';
import { BudgetingModule } from '../../budgeting/budgeting.module';
import { BillToolsService, billToolDefinitions } from './bill-tools';

@Module({
  imports: [PrismaModule, PaymentsModule, BudgetingModule],
  providers: [BillToolsService],
  exports: [BillToolsService],
})
export class AlfredToolsModule {}

export { BillToolsService, billToolDefinitions };
