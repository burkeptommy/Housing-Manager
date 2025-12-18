import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from '../auth';

import { InvoiceGenerationService } from './invoice-generation.service';
import { CollectionService } from './collection.service';
import { SettlementController } from './settlement.controller';

@Module({
  imports: [AuthModule, ConfigModule],
  controllers: [SettlementController],
  providers: [InvoiceGenerationService, CollectionService],
  exports: [InvoiceGenerationService, CollectionService],
})
export class SettlementModule {}
