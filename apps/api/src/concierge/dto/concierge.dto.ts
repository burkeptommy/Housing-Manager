import { IsString, IsOptional, IsEnum, IsBoolean, IsNumber, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

// Request types for concierge tasks
export enum ConciergeTaskType {
  FILTER_CHANGE = 'FILTER_CHANGE',
  LIGHT_BULB = 'LIGHT_BULB',
  LOOSE_HINGE = 'LOOSE_HINGE',
  CAULKING = 'CAULKING',
  MINOR_REPAIR = 'MINOR_REPAIR',
  SMOKE_DETECTOR_BATTERY = 'SMOKE_DETECTOR_BATTERY',
  GENERAL_INSPECTION = 'GENERAL_INSPECTION',
  OTHER = 'OTHER',
}

export class CreateConciergeRequestDto {
  @ApiProperty({ description: 'Type of concierge task' })
  @IsEnum(ConciergeTaskType)
  taskType: ConciergeTaskType;

  @ApiProperty({ description: 'Title/summary of the request' })
  @IsString()
  title: string;

  @ApiPropertyOptional({ description: 'Detailed description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Preferred date for the visit' })
  @IsOptional()
  @IsString()
  preferredDate?: string;

  @ApiPropertyOptional({ description: 'Preferred time window start (e.g., "09:00")' })
  @IsOptional()
  @IsString()
  preferredTimeStart?: string;

  @ApiPropertyOptional({ description: 'Preferred time window end (e.g., "12:00")' })
  @IsOptional()
  @IsString()
  preferredTimeEnd?: string;

  @ApiPropertyOptional({ description: 'Additional notes for the handyman' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ description: 'Add to next monthly visit instead of separate appointment' })
  @IsOptional()
  @IsBoolean()
  addToMonthlyVisit?: boolean;
}

export class HandymanCheckInDto {
  @ApiProperty({ description: 'Work order ID' })
  @IsString()
  workOrderId: string;

  @ApiProperty({ description: 'Check-in latitude' })
  @IsNumber()
  latitude: number;

  @ApiProperty({ description: 'Check-in longitude' })
  @IsNumber()
  longitude: number;
}

export class HandymanCheckOutDto {
  @ApiProperty({ description: 'Work order ID' })
  @IsString()
  workOrderId: string;

  @ApiPropertyOptional({ description: 'Hours worked on this task' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(24)
  hoursWorked?: number;

  @ApiPropertyOptional({ description: 'Proof images (URLs)' })
  @IsOptional()
  @IsString({ each: true })
  proofImages?: string[];

  @ApiPropertyOptional({ description: 'Completion notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class AssignHandymanDto {
  @ApiProperty({ description: 'Work order ID' })
  @IsString()
  workOrderId: string;

  @ApiProperty({ description: 'Handyman user ID to assign' })
  @IsString()
  handymanId: string;
}

export class RejectRequestDto {
  @ApiProperty({ description: 'Work order ID' })
  @IsString()
  workOrderId: string;

  @ApiProperty({ description: 'Reason for rejection' })
  @IsString()
  reason: string;
}

export class HouseholdProfitQueryDto {
  @ApiPropertyOptional({ description: 'Start date for profit calculation' })
  @IsOptional()
  @IsString()
  startDate?: string;

  @ApiPropertyOptional({ description: 'End date for profit calculation' })
  @IsOptional()
  @IsString()
  endDate?: string;
}

// Response DTOs
export class ConciergeRequestResponseDto {
  id: string;
  title: string;
  description: string | null;
  status: string;
  billingType: string;
  isConciergeRequest: boolean;
  scheduledStart: Date | null;
  scheduledEnd: Date | null;
  handyman: {
    id: string;
    displayName: string | null;
    phone: string | null;
  } | null;
  createdAt: Date;
}

export class HouseholdProfitResponseDto {
  householdId: string;
  householdName: string;
  subscriptionPlan: string;
  period: {
    startDate: string;
    endDate: string;
  };
  subscriptionRevenue: number;
  inclusiveCosts: number;
  billableRevenue: number;
  netProfit: number;
  inclusiveTaskCount: number;
  billableTaskCount: number;
}

export class HandymanDashboardDto {
  handymanId: string;
  handymanName: string;
  todaysTasks: {
    id: string;
    title: string;
    householdName: string;
    scheduledStart: Date | null;
    status: string;
    address: string | null;
  }[];
  upcomingTasks: {
    id: string;
    title: string;
    householdName: string;
    scheduledStart: Date | null;
    status: string;
  }[];
  assignedHouseholds: {
    id: string;
    name: string;
    address: string | null;
    monthlyVisitDay: number | null;
    conciergeEnabled: boolean;
  }[];
  stats: {
    completedThisMonth: number;
    hoursThisMonth: number;
    pendingTasks: number;
  };
}
