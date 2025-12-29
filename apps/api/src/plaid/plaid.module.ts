import { Module } from '@nestjs/common';
import { PlaidController } from './plaid.controller';
import { PlaidService } from './plaid.service';
import { BillSuggestionsService } from './bill-suggestions.service';
import { MerchantIntelligenceService } from './merchant-intelligence.service';
import { PrismaModule } from '../prisma/prisma.module';
import { FirebaseModule } from '../firebase';

@Module({
  imports: [PrismaModule, FirebaseModule],
  controllers: [PlaidController],
  providers: [PlaidService, BillSuggestionsService, MerchantIntelligenceService],
  exports: [PlaidService, BillSuggestionsService, MerchantIntelligenceService],
})
export class PlaidModule {}
