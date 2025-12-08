import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth';
import { DbModule } from './db';
import { HealthModule } from './health/health.module';
import { HomeProfilesModule } from './home-profiles';
import { HouseholdsModule } from './households';
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
    HealthModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
