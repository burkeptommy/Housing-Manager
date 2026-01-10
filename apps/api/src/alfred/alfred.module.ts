import { Module } from '@nestjs/common';
import { AlfredService } from './alfred.service';
import { AlfredQuestionsService } from './alfred-questions.service';
import { AlfredController } from './alfred.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { HomeHealthModule } from '../home-health/home-health.module';

@Module({
  imports: [PrismaModule, HomeHealthModule],
  controllers: [AlfredController],
  providers: [AlfredService, AlfredQuestionsService],
  exports: [AlfredService, AlfredQuestionsService],
})
export class AlfredModule {}
