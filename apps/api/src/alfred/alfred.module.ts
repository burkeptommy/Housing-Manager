import { Module } from '@nestjs/common';
import { AlfredService } from './alfred.service';
import { AlfredController } from './alfred.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { HomeHealthModule } from '../home-health/home-health.module';

@Module({
  imports: [PrismaModule, HomeHealthModule],
  controllers: [AlfredController],
  providers: [AlfredService],
  exports: [AlfredService],
})
export class AlfredModule {}
