import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';

import { FirebaseModule } from '../firebase';
import { PrismaModule } from '../prisma/prisma.module';

import { PropertyController } from './property.controller';
import { PropertyService } from './property.service';
import { ChecklistGeneratorService } from './checklist-generator.service';
import { PropertyEnrichmentService } from './property-enrichment.service';

@Module({
  imports: [HttpModule, FirebaseModule, PrismaModule],
  controllers: [PropertyController],
  providers: [PropertyService, ChecklistGeneratorService, PropertyEnrichmentService],
  exports: [PropertyService, ChecklistGeneratorService, PropertyEnrichmentService],
})
export class PropertyModule {}
