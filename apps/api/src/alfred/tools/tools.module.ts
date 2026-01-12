import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { PaymentsModule } from '../../payments/payments.module';
import { BillToolsService, billToolDefinitions } from './bill-tools';

@Module({
  imports: [PrismaModule, PaymentsModule],
  providers: [BillToolsService],
  exports: [BillToolsService],
})
export class AlfredToolsModule {}

export { BillToolsService, billToolDefinitions };
