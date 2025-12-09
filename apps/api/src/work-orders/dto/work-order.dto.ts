import {
  IsString,
  IsOptional,
  IsDateString,
  IsNumber,
  IsEnum,
  IsBoolean,
} from 'class-validator';
import { WorkOrderStatus } from '@prisma/client';

export class CreateWorkOrderDto {
  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  maintenanceTaskId?: string;

  @IsString()
  @IsOptional()
  vendorId?: string;

  @IsDateString()
  @IsOptional()
  preferredDate?: string;

  @IsString()
  @IsOptional()
  preferredTimeWindowStart?: string;

  @IsString()
  @IsOptional()
  preferredTimeWindowEnd?: string;
}

export class UpdateWorkOrderDto {
  @IsString()
  @IsOptional()
  title?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  vendorId?: string;

  @IsEnum(WorkOrderStatus)
  @IsOptional()
  status?: WorkOrderStatus;

  @IsDateString()
  @IsOptional()
  scheduledStart?: string;

  @IsDateString()
  @IsOptional()
  scheduledEnd?: string;

  @IsNumber()
  @IsOptional()
  estimatedCost?: number;

  @IsNumber()
  @IsOptional()
  actualCost?: number;
}

export class CreateWorkOrderNoteDto {
  @IsString()
  body: string;
}

export class WorkOrderQueryDto {
  @IsEnum(WorkOrderStatus)
  @IsOptional()
  status?: WorkOrderStatus;

  @IsBoolean()
  @IsOptional()
  includeCompleted?: boolean;
}

export class InternalWorkOrderQueryDto {
  @IsEnum(WorkOrderStatus)
  @IsOptional()
  status?: WorkOrderStatus;

  @IsBoolean()
  @IsOptional()
  unassigned?: boolean;

  @IsBoolean()
  @IsOptional()
  upcoming?: boolean;
}
