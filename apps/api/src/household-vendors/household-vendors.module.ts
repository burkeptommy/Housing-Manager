import { Module } from '@nestjs/common';

import { AuthModule } from '../auth';
import { ActivityModule } from '../activity';

import { HouseholdVendorsController, VendorsController } from './household-vendors.controller';
import { HouseholdVendorsService } from './household-vendors.service';

@Module({
  imports: [AuthModule, ActivityModule],
  controllers: [HouseholdVendorsController, VendorsController],
  providers: [HouseholdVendorsService],
  exports: [HouseholdVendorsService],
})
export class HouseholdVendorsModule {}
