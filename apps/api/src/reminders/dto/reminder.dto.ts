import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsEnum, IsOptional, IsDateString, IsBoolean } from 'class-validator';

export enum ReminderType {
  BILL_DUE = 'BILL_DUE',
  MAINTENANCE_TASK = 'MAINTENANCE_TASK',
}

export enum ReminderStatus {
  PENDING = 'PENDING',
  SENT = 'SENT',
  CANCELLED = 'CANCELLED',
  FAILED = 'FAILED',
}

export enum ReminderChannel {
  EMAIL = 'EMAIL',
  PUSH = 'PUSH',
  SMS = 'SMS',
  IN_APP = 'IN_APP',
}

export class ReminderDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty({ enum: ReminderType })
  type: ReminderType;

  @ApiPropertyOptional()
  billAccountId?: string;

  @ApiPropertyOptional()
  maintenanceTaskId?: string;

  @ApiProperty()
  scheduledAt: Date;

  @ApiPropertyOptional()
  sentAt?: Date;

  @ApiProperty({ enum: ReminderStatus })
  status: ReminderStatus;

  @ApiProperty({ enum: ReminderChannel })
  channel: ReminderChannel;

  @ApiPropertyOptional()
  payloadJson?: Record<string, unknown>;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

export class CreateReminderDto {
  @ApiProperty()
  @IsString()
  householdId: string;

  @ApiProperty({ enum: ReminderType })
  @IsEnum(ReminderType)
  type: ReminderType;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  billAccountId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  maintenanceTaskId?: string;

  @ApiProperty()
  @IsDateString()
  scheduledAt: string;

  @ApiProperty({ enum: ReminderChannel })
  @IsEnum(ReminderChannel)
  channel: ReminderChannel;

  @ApiPropertyOptional()
  @IsOptional()
  payloadJson?: Record<string, unknown>;
}

export class UpdateReminderDto {
  @ApiPropertyOptional({ enum: ReminderStatus })
  @IsEnum(ReminderStatus)
  @IsOptional()
  status?: ReminderStatus;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  scheduledAt?: string;
}

// Dashboard Response DTOs
export class UpcomingBillDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  nickname: string;

  @ApiProperty()
  vendorName: string;

  @ApiProperty()
  vendorId: string;

  @ApiProperty()
  category: string;

  @ApiPropertyOptional()
  typicalAmount?: number;

  @ApiProperty()
  nextDueDate: Date;

  @ApiProperty({ description: 'Days until due (negative if overdue)' })
  daysUntilDue: number;

  @ApiProperty({ description: 'Is the bill overdue' })
  isOverdue: boolean;

  @ApiProperty({ description: 'Payment responsibility' })
  paymentResponsibility: string;
}

export class UpcomingMaintenanceTaskDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiProperty()
  category: string;

  @ApiProperty()
  status: string;

  @ApiPropertyOptional()
  dueDate?: Date;

  @ApiPropertyOptional()
  scheduledDate?: Date;

  @ApiProperty({ description: 'Days until due (negative if overdue)' })
  daysUntilDue: number;

  @ApiProperty({ description: 'Is the task overdue' })
  isOverdue: boolean;

  @ApiPropertyOptional()
  assignedVendorId?: string;

  @ApiPropertyOptional()
  assignedVendorName?: string;

  @ApiPropertyOptional()
  estimatedCost?: number;
}

export class UpcomingItemsResponseDto {
  @ApiProperty({ type: [UpcomingBillDto] })
  upcomingBills: UpcomingBillDto[];

  @ApiProperty({ type: [UpcomingMaintenanceTaskDto] })
  upcomingMaintenanceTasks: UpcomingMaintenanceTaskDto[];
}

// Next up item - the most imminent bill or task
export class NextUpItemDto {
  @ApiProperty({ enum: ['bill', 'maintenance'] })
  type: 'bill' | 'maintenance';

  @ApiProperty()
  id: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  category: string;

  @ApiPropertyOptional()
  vendorName?: string;

  @ApiPropertyOptional()
  amount?: number;

  @ApiProperty()
  daysUntilDue: number;

  @ApiProperty()
  dueDate: Date;
}

// Today's tasks
export class TodayTaskDto {
  @ApiProperty({ enum: ['bill', 'maintenance'] })
  type: 'bill' | 'maintenance';

  @ApiProperty()
  id: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  category: string;

  @ApiPropertyOptional()
  vendorName?: string;

  @ApiPropertyOptional()
  amount?: number;

  @ApiPropertyOptional()
  scheduledTime?: string;
}

// Dashboard summary stats
export class DashboardSummaryDto {
  @ApiProperty({ description: 'Number of bills managed this month' })
  billsManagedThisMonth: number;

  @ApiProperty({ description: 'Number of tasks scheduled this month' })
  tasksScheduledThisMonth: number;

  @ApiProperty({ description: 'Number of tasks completed this month' })
  tasksCompletedThisMonth: number;

  @ApiPropertyOptional({ description: 'The next major upcoming item' })
  nextUp?: NextUpItemDto;

  @ApiProperty({ type: [TodayTaskDto], description: 'Tasks and appointments for today' })
  todaysTasks: TodayTaskDto[];
}

// Full dashboard response
export class DashboardResponseDto {
  @ApiProperty({ type: DashboardSummaryDto })
  summary: DashboardSummaryDto;

  @ApiProperty({ type: [UpcomingBillDto] })
  upcomingBills: UpcomingBillDto[];

  @ApiProperty({ type: [UpcomingMaintenanceTaskDto] })
  upcomingMaintenanceTasks: UpcomingMaintenanceTaskDto[];
}

// In-app notification DTOs
export class InAppNotificationDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  userId: string;

  @ApiPropertyOptional()
  householdId?: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  body: string;

  @ApiPropertyOptional()
  link?: string;

  @ApiProperty()
  isRead: boolean;

  @ApiPropertyOptional()
  readAt?: Date;

  @ApiProperty()
  createdAt: Date;
}

export class MarkNotificationReadDto {
  @ApiProperty()
  @IsBoolean()
  isRead: boolean;
}

// Cron job response
export class CronJobResultDto {
  @ApiProperty()
  success: boolean;

  @ApiProperty()
  billRemindersScheduled: number;

  @ApiProperty()
  maintenanceRemindersScheduled: number;

  @ApiProperty()
  remindersProcessed: number;

  @ApiPropertyOptional()
  error?: string;
}
