import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth';
import { BillingModule } from './billing';
import { DbModule } from './db';
import { FilesModule } from './files';
import { HealthModule } from './health/health.module';
import { HomeProfilesModule } from './home-profiles';
import { HouseholdsModule } from './households';
import { MessagesModule } from './messages';
import { NotificationsModule } from './notifications';
import { PrismaModule } from './prisma';
import { ServiceCategoriesModule } from './service-categories';
import { ServiceRequestsModule } from './service-requests';
import { UsersModule } from './users';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    PrismaModule,
    DbModule,
    AuthModule,
    UsersModule,
    HouseholdsModule,
    HomeProfilesModule,
    ServiceCategoriesModule,
    ServiceRequestsModule,
    MessagesModule,
    NotificationsModule,
    BillingModule,
    FilesModule,
    HealthModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
