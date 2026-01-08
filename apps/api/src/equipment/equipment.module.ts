import { Module } from '@nestjs/common';
import { EquipmentService } from './equipment.service';
import { EquipmentController } from './equipment.controller';
import { EquipmentResearchService } from './equipment-research.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [EquipmentController],
  providers: [EquipmentService, EquipmentResearchService],
  exports: [EquipmentService, EquipmentResearchService],
})
export class EquipmentModule {}
