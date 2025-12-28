import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AdminModule } from './admin';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ApprovalModule } from './approval';
import { MaintenanceModule } from './maintenance';
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
import { FinancialsModule } from './financials';
import { SettlementModule } from './settlement';
import { VendorPortalModule } from './vendor-portal';
import { ConciergeModule } from './concierge';
import { SocialModule } from './social/social.module';
import { ProjectPlannerModule } from './project-planner/project-planner.module';
import { FamilyModule } from './family/family.module';
import { TravelModule } from './travel/travel.module';
import { PropertyModule } from './property';
import { IntakeModule } from './intake';
import { OnboardingModule } from './onboarding/onboarding.module';
import { ManagerModule } from './manager';
import { ManagerOnboardingModule } from './manager/onboarding';
import { ActivityModule } from './activity';
import { DashboardModule } from './dashboard';

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
    ApprovalModule,
    MaintenanceModule,
    HouseholdVendorsModule,
    BillAccountsModule,
    MaintenanceTasksModule,
    RemindersModule,
    InvoicesModule,
    ConversationsModule,
    WorkOrdersModule,
    InternalModule,
    UploadsModule,
    FinancialsModule,
    SettlementModule,
    VendorPortalModule,
    ConciergeModule,
    SocialModule,
    ProjectPlannerModule,
    FamilyModule,
    TravelModule,
    PropertyModule,
    IntakeModule,
    OnboardingModule,
    ManagerModule,
    ManagerOnboardingModule,
    ActivityModule,
    DashboardModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
