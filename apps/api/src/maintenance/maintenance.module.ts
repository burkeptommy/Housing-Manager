import { Module } from '@nestjs/common';
import { MaintenanceController } from './maintenance.controller';
import { MaintenanceService } from './maintenance.service';
import { MaintenanceGeneratorService } from './maintenance-generator.service';
import { MaintenanceResearchService } from './maintenance-research.service';
import { PrismaModule } from '../prisma/prisma.module';
import { FirebaseModule } from '../firebase/firebase.module';

@Module({
  imports: [PrismaModule, FirebaseModule],
  controllers: [MaintenanceController],
  providers: [MaintenanceService, MaintenanceGeneratorService, MaintenanceResearchService],
  exports: [MaintenanceService, MaintenanceGeneratorService, MaintenanceResearchService],
})
export class MaintenanceModule {}
