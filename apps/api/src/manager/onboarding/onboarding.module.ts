import { Module } from '@nestjs/common';
import { ManagerOnboardingController } from './onboarding.controller';
import { ManagerOnboardingService } from './onboarding.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ManagerOnboardingController],
  providers: [ManagerOnboardingService],
  exports: [ManagerOnboardingService],
})
export class ManagerOnboardingModule {}
