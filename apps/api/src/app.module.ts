import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AdminModule } from './admin';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth';
import { BillingModule } from './billing';
import { ConversationsModule } from './conversations';
import { DbModule } from './db';
import { InternalModule } from './internal';
import { WorkOrdersModule } from './work-orders';
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
import { HouseholdVendorsModule } from './household-vendors';
import { BillAccountsModule } from './bill-accounts';
import { MaintenanceTasksModule } from './maintenance-tasks';
import { RemindersModule } from './reminders';
import { InvoicesModule } from './invoices';
import { UploadsModule } from './uploads';

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
    AdminModule,
    HouseholdVendorsModule,
    BillAccountsModule,
    MaintenanceTasksModule,
    RemindersModule,
    InvoicesModule,
    ConversationsModule,
    WorkOrdersModule,
    InternalModule,
    UploadsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
