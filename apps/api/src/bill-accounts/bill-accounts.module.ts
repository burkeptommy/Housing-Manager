import { Module } from '@nestjs/common';

import { AuthModule } from '../auth';

import { BillAccountsController } from './bill-accounts.controller';
import { BillAccountsService } from './bill-accounts.service';

@Module({
  imports: [AuthModule],
  controllers: [BillAccountsController],
  providers: [BillAccountsService],
  exports: [BillAccountsService],
})
export class BillAccountsModule {}
