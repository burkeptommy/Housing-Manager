import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDateString,
  IsBoolean,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
  MaintenanceCategory,
  MaintenanceTaskStatus,
  TaskPriority,
  VendorCategory,
} from '@prisma/client';

export class CreateMaintenanceTaskDto {
  @ApiProperty({ description: 'Household ID' })
  @IsString()
  householdId: string;

  @ApiPropertyOptional({ description: 'Template ID if creating from template' })
  @IsOptional()
  @IsString()
  templateId?: string;

  @ApiProperty({ description: 'Task title' })
  @IsString()
  @MaxLength(255)
  title: string;

  @ApiPropertyOptional({ description: 'Task description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ enum: MaintenanceCategory, description: 'Category' })
  @IsOptional()
  @IsEnum(MaintenanceCategory)
  category?: MaintenanceCategory;

  @ApiPropertyOptional({ description: 'Due date (ISO 8601)' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({ description: 'Scheduled date (ISO 8601)' })
  @IsOptional()
  @IsDateString()
  scheduledDate?: string;

  @ApiPropertyOptional({ description: 'Assigned vendor ID' })
  @IsOptional()
  @IsString()
  assignedVendorId?: string;

  @ApiPropertyOptional({ description: 'Estimated cost' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  estimatedCost?: number;

  @ApiPropertyOptional({ enum: TaskPriority, description: 'Priority' })
  @IsOptional()
  @IsEnum(TaskPriority)
  priority?: TaskPriority;

  @ApiPropertyOptional({ description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateMaintenanceTaskDto {
  @ApiPropertyOptional({ description: 'Task title' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  title?: string;

  @ApiPropertyOptional({ description: 'Task description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ enum: MaintenanceCategory, description: 'Category' })
  @IsOptional()
  @IsEnum(MaintenanceCategory)
  category?: MaintenanceCategory;

  @ApiPropertyOptional({ enum: MaintenanceTaskStatus, description: 'Status' })
  @IsOptional()
  @IsEnum(MaintenanceTaskStatus)
  status?: MaintenanceTaskStatus;

  @ApiPropertyOptional({ description: 'Due date (ISO 8601)' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({ description: 'Scheduled date (ISO 8601)' })
  @IsOptional()
  @IsDateString()
  scheduledDate?: string;

  @ApiPropertyOptional({ description: 'Assigned vendor ID' })
  @IsOptional()
  @IsString()
  assignedVendorId?: string;

  @ApiPropertyOptional({ description: 'Estimated cost' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  estimatedCost?: number;

  @ApiPropertyOptional({ description: 'Actual cost' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  actualCost?: number;

  @ApiPropertyOptional({ enum: TaskPriority, description: 'Priority' })
  @IsOptional()
  @IsEnum(TaskPriority)
  priority?: TaskPriority;

  @ApiPropertyOptional({ description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class GenerateFromTemplatesDto {
  @ApiProperty({ description: 'Household ID to generate tasks for' })
  @IsString()
  householdId: string;

  @ApiPropertyOptional({ description: 'Property features to consider (e.g., has_pool, has_septic)' })
  @IsOptional()
  propertyFeatures?: Record<string, boolean | string | number>;
}

export class MaintenanceTaskResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdId: string;

  @ApiPropertyOptional()
  templateId?: string | null;

  @ApiPropertyOptional()
  assignedVendorId?: string | null;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional()
  description?: string | null;

  @ApiProperty({ enum: MaintenanceCategory })
  category: MaintenanceCategory;

  @ApiProperty({ enum: MaintenanceTaskStatus })
  status: MaintenanceTaskStatus;

  @ApiPropertyOptional()
  dueDate?: Date | null;

  @ApiPropertyOptional()
  nextDueDate?: Date | null;

  @ApiPropertyOptional()
  scheduledDate?: Date | null;

  @ApiPropertyOptional()
  completedAt?: Date | null;

  @ApiPropertyOptional()
  estimatedCost?: number | null;

  @ApiPropertyOptional()
  actualCost?: number | null;

  @ApiProperty()
  createdFromTemplate: boolean;

  @ApiPropertyOptional()
  notes?: string | null;

  @ApiProperty({ enum: TaskPriority })
  priority: TaskPriority;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;

  // Checklist steps
  @ApiPropertyOptional({ description: 'Checklist steps for this task' })
  checklistSteps?: { id: string; completed: boolean }[];

  // Included relations
  @ApiPropertyOptional()
  template?: {
    id: string;
    slug: string;
    title: string;
  };

  @ApiPropertyOptional()
  assignedVendor?: {
    id: string;
    displayName: string;
    category: VendorCategory;
  };
}

export class MaintenanceTemplateResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  slug: string;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional()
  description?: string | null;

  @ApiProperty({ enum: MaintenanceCategory })
  category: MaintenanceCategory;

  @ApiPropertyOptional()
  recommendedFrequencyMonths?: number | null;

  @ApiPropertyOptional()
  recommendedSeasonStartMonth?: number | null;

  @ApiPropertyOptional()
  recommendedSeasonEndMonth?: number | null;

  @ApiPropertyOptional()
  propertyConditionsJson?: Record<string, unknown> | null;

  @ApiPropertyOptional({ enum: VendorCategory })
  defaultVendorCategory?: VendorCategory | null;

  @ApiPropertyOptional()
  estimatedCostMin?: number | null;

  @ApiPropertyOptional()
  estimatedCostMax?: number | null;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  sortOrder: number;
}

export class MaintenanceTaskQueryDto {
  @ApiPropertyOptional({ description: 'Household ID' })
  @IsOptional()
  @IsString()
  householdId?: string;

  @ApiPropertyOptional({ enum: MaintenanceCategory, description: 'Filter by category' })
  @IsOptional()
  @IsEnum(MaintenanceCategory)
  category?: MaintenanceCategory;

  @ApiPropertyOptional({ enum: MaintenanceTaskStatus, description: 'Filter by status' })
  @IsOptional()
  @IsEnum(MaintenanceTaskStatus)
  status?: MaintenanceTaskStatus;

  @ApiPropertyOptional({ description: 'Filter by due date (from)' })
  @IsOptional()
  @IsDateString()
  dueDateFrom?: string;

  @ApiPropertyOptional({ description: 'Filter by due date (to)' })
  @IsOptional()
  @IsDateString()
  dueDateTo?: string;

  @ApiPropertyOptional({ description: 'Include completed tasks' })
  @IsOptional()
  @IsBoolean()
  includeCompleted?: boolean;
}
