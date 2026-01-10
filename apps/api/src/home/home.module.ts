import { Module } from '@nestjs/common';
import { HomeController } from './home.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { FirebaseModule } from '../firebase';

@Module({
  imports: [PrismaModule, FirebaseModule],
  controllers: [HomeController],
})
export class HomeModule {}
