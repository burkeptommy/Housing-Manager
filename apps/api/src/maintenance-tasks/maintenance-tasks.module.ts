import { Module } from '@nestjs/common';

import { AuthModule } from '../auth';

import { MaintenanceTasksController } from './maintenance-tasks.controller';
import { MaintenanceTasksService } from './maintenance-tasks.service';

@Module({
  imports: [AuthModule],
  controllers: [MaintenanceTasksController],
  providers: [MaintenanceTasksService],
  exports: [MaintenanceTasksService],
})
export class MaintenanceTasksModule {}
