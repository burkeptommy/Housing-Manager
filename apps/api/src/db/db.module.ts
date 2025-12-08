import { Module } from '@nestjs/common';

import {
  UserRepository,
  HouseholdRepository,
  ServiceRequestRepository,
  TaskRepository,
  VendorRepository,
  MaintenancePlanRepository,
  InvoiceRepository,
  FileRepository,
  SubscriptionRepository,
  MessageRepository,
} from './repositories';

const repositories = [
  UserRepository,
  HouseholdRepository,
  ServiceRequestRepository,
  TaskRepository,
  VendorRepository,
  MaintenancePlanRepository,
  InvoiceRepository,
  FileRepository,
  SubscriptionRepository,
  MessageRepository,
];

@Module({
  providers: [...repositories],
  exports: [...repositories],
})
export class DbModule {}
