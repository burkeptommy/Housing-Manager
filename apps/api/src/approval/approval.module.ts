import { Module } from '@nestjs/common';
import { ApprovalService } from './approval.service';
import { ApprovalController } from './approval.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { ActivityModule } from '../activity/activity.module';

@Module({
  imports: [PrismaModule, FirebaseModule, ActivityModule],
  controllers: [ApprovalController],
  providers: [ApprovalService],
  exports: [ApprovalService],
})
export class ApprovalModule {}
