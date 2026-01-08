import { Module } from '@nestjs/common';
import { HomeHealthService } from './home-health.service';
import { HomeHealthController } from './home-health.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [HomeHealthController],
  providers: [HomeHealthService],
  exports: [HomeHealthService],
})
export class HomeHealthModule {}
