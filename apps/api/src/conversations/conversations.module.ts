import { Module } from '@nestjs/common';

import { AuthModule } from '../auth';
import { FirebaseModule } from '../firebase';

import {
  ConversationsController,
  InternalConversationsController,
} from './conversations.controller';
import { ConversationsService } from './conversations.service';

@Module({
  imports: [AuthModule, FirebaseModule.forRoot()],
  controllers: [ConversationsController, InternalConversationsController],
  providers: [ConversationsService],
  exports: [ConversationsService],
})
export class ConversationsModule {}
