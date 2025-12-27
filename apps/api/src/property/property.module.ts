import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';

import { FirebaseModule } from '../firebase';

import { PropertyController } from './property.controller';
import { PropertyService } from './property.service';
import { ChecklistGeneratorService } from './checklist-generator.service';

@Module({
  imports: [HttpModule, FirebaseModule],
  controllers: [PropertyController],
  providers: [PropertyService, ChecklistGeneratorService],
  exports: [PropertyService, ChecklistGeneratorService],
})
export class PropertyModule {}
