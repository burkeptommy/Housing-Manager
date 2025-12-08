import { ApiProperty, ApiPropertyOptional, PartialType, OmitType } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsEnum,
  IsDateString,
  IsNumber,
  MaxLength,
} from 'class-validator';

export enum ServiceRequestStatus {
  DRAFT = 'DRAFT',
  SUBMITTED = 'SUBMITTED',
  ASSIGNED = 'ASSIGNED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum ServiceRequestPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
}

export class CreateServiceRequestDto {
  @ApiProperty({ description: 'Household ID' })
  @IsString()
  householdId: string;

  @ApiPropertyOptional({ description: 'Service category ID' })
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiProperty({ description: 'Request title', example: 'Fix leaky faucet' })
  @IsString()
  @MaxLength(200)
  title: string;

  @ApiProperty({ description: 'Detailed description', example: 'Kitchen sink faucet is dripping constantly' })
  @IsString()
  @MaxLength(2000)
  description: string;

  @ApiPropertyOptional({
    description: 'Request priority',
    enum: ServiceRequestPriority,
    default: ServiceRequestPriority.MEDIUM,
  })
  @IsOptional()
  @IsEnum(ServiceRequestPriority)
  priority?: ServiceRequestPriority;

  @ApiPropertyOptional({ description: 'Preferred date for service' })
  @IsOptional()
  @IsDateString()
  preferredDate?: string;

  @ApiPropertyOptional({ description: 'Additional notes' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  // Placeholder for photo upload - will be implemented later
  @ApiPropertyOptional({ description: 'Photo URL (placeholder for future file upload)' })
  @IsOptional()
  @IsString()
  photoUrl?: string;
}

export class UpdateServiceRequestDto extends PartialType(
  OmitType(CreateServiceRequestDto, ['householdId'] as const),
) {
  @ApiPropertyOptional({
    description: 'Request status',
    enum: ServiceRequestStatus,
  })
  @IsOptional()
  @IsEnum(ServiceRequestStatus)
  status?: ServiceRequestStatus;

  @ApiPropertyOptional({ description: 'Assigned vendor ID' })
  @IsOptional()
  @IsString()
  vendorId?: string;

  @ApiPropertyOptional({ description: 'Scheduled date for service' })
  @IsOptional()
  @IsDateString()
  scheduledDate?: string;

  @ApiPropertyOptional({ description: 'Estimated cost' })
  @IsOptional()
  @IsNumber()
  estimatedCost?: number;

  @ApiPropertyOptional({ description: 'Actual cost (after completion)' })
  @IsOptional()
  @IsNumber()
  actualCost?: number;
}

export class ServiceRequestDto {
  @ApiProperty({ description: 'Request ID' })
  id: string;

  @ApiProperty({ description: 'Household ID' })
  householdId: string;

  @ApiPropertyOptional({ description: 'Service category ID' })
  serviceCategoryId: string | null;

  @ApiPropertyOptional({ description: 'Assigned vendor ID' })
  vendorId: string | null;

  @ApiProperty({ description: 'Created by user ID' })
  createdById: string;

  @ApiProperty({ description: 'Request title' })
  title: string;

  @ApiProperty({ description: 'Request description' })
  description: string;

  @ApiProperty({ description: 'Request status', enum: ServiceRequestStatus })
  status: ServiceRequestStatus;

  @ApiProperty({ description: 'Request priority', enum: ServiceRequestPriority })
  priority: ServiceRequestPriority;

  @ApiPropertyOptional({ description: 'Preferred date' })
  preferredDate: Date | null;

  @ApiPropertyOptional({ description: 'Scheduled date' })
  scheduledDate: Date | null;

  @ApiPropertyOptional({ description: 'Completion date' })
  completedDate: Date | null;

  @ApiPropertyOptional({ description: 'Estimated cost' })
  estimatedCost: number | null;

  @ApiPropertyOptional({ description: 'Actual cost' })
  actualCost: number | null;

  @ApiPropertyOptional({ description: 'Notes' })
  notes: string | null;

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  updatedAt: Date;
}

export class ServiceRequestDetailDto extends ServiceRequestDto {
  @ApiPropertyOptional({ description: 'Service category details' })
  serviceCategory?: {
    id: string;
    name: string;
    icon: string | null;
  } | null;

  @ApiPropertyOptional({ description: 'Vendor details' })
  vendor?: {
    id: string;
    companyName: string;
  } | null;

  @ApiPropertyOptional({ description: 'Created by user details' })
  createdBy?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };

  @ApiPropertyOptional({ description: 'Household details' })
  household?: {
    id: string;
    name: string;
  };
}
