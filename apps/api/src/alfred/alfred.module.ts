import { Module } from '@nestjs/common';
import { AlfredService } from './alfred.service';
import { AlfredQuestionsService } from './alfred-questions.service';
import { AlfredController } from './alfred.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { HomeHealthModule } from '../home-health/home-health.module';
import { AlfredToolsModule } from './tools/tools.module';
import { MaintenanceModule } from '../maintenance/maintenance.module';

@Module({
  imports: [PrismaModule, HomeHealthModule, AlfredToolsModule, MaintenanceModule],
  controllers: [AlfredController],
  providers: [AlfredService, AlfredQuestionsService],
  exports: [AlfredService, AlfredQuestionsService],
})
export class AlfredModule {}
