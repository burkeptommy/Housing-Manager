import { Module } from '@nestjs/common';
import { WalkthroughController } from './walkthrough.controller';
import { WalkthroughService } from './walkthrough.service';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [PrismaModule, NotificationsModule],
  controllers: [WalkthroughController],
  providers: [WalkthroughService],
  exports: [WalkthroughService],
})
export class WalkthroughModule {}
