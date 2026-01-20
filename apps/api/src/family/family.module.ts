import { Module } from '@nestjs/common';
import { FamilyController } from './family.controller';
import { VehicleService, PetService, HomeSystemService, CalendarService, VehicleMaintenanceResearchService } from './services';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [FamilyController],
  providers: [VehicleService, PetService, HomeSystemService, CalendarService, VehicleMaintenanceResearchService],
  exports: [VehicleService, PetService, HomeSystemService, CalendarService, VehicleMaintenanceResearchService],
})
export class FamilyModule {}
