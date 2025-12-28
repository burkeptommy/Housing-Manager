import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { DocumentController } from './document.controller';
import { DocumentService } from './document.service';
import { PrismaModule } from '../prisma/prisma.module';
import { FirebaseModule } from '../firebase';

@Module({
  imports: [
    PrismaModule,
    FirebaseModule,
    MulterModule.register({
      limits: {
        fileSize: 25 * 1024 * 1024, // 25MB limit
      },
    }),
  ],
  controllers: [DocumentController],
  providers: [DocumentService],
  exports: [DocumentService],
})
export class DocumentModule {}
