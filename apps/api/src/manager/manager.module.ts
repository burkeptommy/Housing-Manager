import { Module } from '@nestjs/common';
import { ManagerController } from './manager.controller';
import { ManagerService } from './manager.service';
import { PrismaModule } from '../prisma/prisma.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { ManagerOnboardingModule } from './onboarding/onboarding.module';
import { BillsModule } from '../bills/bills.module';

@Module({
  imports: [PrismaModule, FirebaseModule, ManagerOnboardingModule, BillsModule],
  controllers: [ManagerController],
  providers: [ManagerService],
  exports: [ManagerService],
})
export class ManagerModule {}
