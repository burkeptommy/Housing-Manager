import { IsString, IsNumber, IsOptional, IsArray, IsEnum } from 'class-validator';
import { WorkOrderStatus } from '@prisma/client';

export class AcceptJobDto {
  @IsString()
  workOrderId: string;
}

export class CheckInDto {
  @IsString()
  workOrderId: string;

  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;
}

export class CheckOutDto {
  @IsString()
  workOrderId: string;

  @IsArray()
  @IsString({ each: true })
  proofImages: string[];

  @IsString()
  @IsOptional()
  notes?: string;
}

export class JobBoardQueryDto {
  @IsString()
  @IsOptional()
  serviceArea?: string;

  @IsEnum(WorkOrderStatus)
  @IsOptional()
  status?: WorkOrderStatus;
}

export class VerifyJobDto {
  @IsString()
  workOrderId: string;

  @IsString()
  @IsOptional()
  notes?: string;
}

export class RequestRevisionDto {
  @IsString()
  workOrderId: string;

  @IsString()
  reason: string;
}

// Response DTOs
export class JobBoardItemDto {
  id: string;
  title: string;
  description: string | null;
  status: WorkOrderStatus;
  scheduledStart: Date | null;
  scheduledEnd: Date | null;
  estimatedCost: number | null;
  serviceArea: string | null;
  household: {
    id: string;
    name: string;
  };
  createdAt: Date;
}

export class VendorScheduleItemDto {
  id: string;
  title: string;
  description: string | null;
  status: WorkOrderStatus;
  scheduledStart: Date | null;
  scheduledEnd: Date | null;
  estimatedCost: number | null;
  serviceArea: string | null;
  checkInAt: Date | null;
  checkOutAt: Date | null;
  household: {
    id: string;
    name: string;
    homeProfile?: {
      address: string;
      latitude: number | null;
      longitude: number | null;
    };
  };
}

export class VerificationQueueItemDto {
  id: string;
  title: string;
  description: string | null;
  status: WorkOrderStatus;
  completedAt: Date | null;
  proofImages: string[];
  actualCost: number | null;
  vendor: {
    id: string;
    displayName: string;
  } | null;
  household: {
    id: string;
    name: string;
  };
}
