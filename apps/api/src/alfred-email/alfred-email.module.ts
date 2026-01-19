import { Module } from '@nestjs/common';
import { AlfredEmailController } from './alfred-email.controller';
import { AlfredEmailService } from './alfred-email.service';
import { EmailParserService } from './email-parser.service';
import { EmailActionsService } from './email-actions.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AlfredEmailController],
  providers: [AlfredEmailService, EmailParserService, EmailActionsService],
  exports: [AlfredEmailService],
})
export class AlfredEmailModule {}
