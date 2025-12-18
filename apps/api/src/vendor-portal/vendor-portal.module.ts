import { Module } from '@nestjs/common';
import { VendorPortalController } from './vendor-portal.controller';
import { VendorPortalService } from './vendor-portal.service';
import { AuthModule } from '../auth';

@Module({
  imports: [AuthModule],
  controllers: [VendorPortalController],
  providers: [VendorPortalService],
  exports: [VendorPortalService],
})
export class VendorPortalModule {}
