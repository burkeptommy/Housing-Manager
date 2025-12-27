import { Module } from '@nestjs/common';
import { IntakeController } from './intake.controller';
import { IntakeService } from './intake.service';
import { IntakeGeneratorService } from './intake-generator.service';
import { PrismaModule } from '../prisma/prisma.module';
import { PropertyModule } from '../property/property.module';

@Module({
  imports: [PrismaModule, PropertyModule],
  controllers: [IntakeController],
  providers: [IntakeService, IntakeGeneratorService],
  exports: [IntakeService, IntakeGeneratorService],
})
export class IntakeModule {}
