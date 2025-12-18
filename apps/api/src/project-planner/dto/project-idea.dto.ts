import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import {
  IsEnum,
  IsOptional,
  IsString,
  IsArray,
  IsDateString,
  IsObject,
  MaxLength,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ProjectCategory, ProjectIdeaStatus } from '@prisma/client';

export class CreateProjectIdeaDto {
  @ApiPropertyOptional({ description: 'Template ID to base idea on' })
  @IsOptional()
  @IsString()
  templateId?: string;

  @ApiProperty({ description: 'Project title' })
  @IsString()
  @MaxLength(200)
  title: string;

  @ApiProperty({ enum: ProjectCategory, description: 'Project category' })
  @IsEnum(ProjectCategory)
  category: ProjectCategory;

  @ApiPropertyOptional({ description: 'Project description' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({ description: 'Project specifications (sqFt, material, etc.)' })
  @IsOptional()
  @IsObject()
  specs?: Record<string, unknown>;

  @ApiPropertyOptional({ description: 'Style preference (modern, rustic, etc.)' })
  @IsOptional()
  @IsString()
  style?: string;

  @ApiPropertyOptional({ description: 'Vibe notes and preferences' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  vibeNotes?: string;

  @ApiPropertyOptional({ description: 'Mood board image URLs', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  moodBoardImages?: string[];

  @ApiPropertyOptional({ description: 'Target start date' })
  @IsOptional()
  @IsDateString()
  targetStartDate?: string;

  @ApiPropertyOptional({ description: 'Target completion date' })
  @IsOptional()
  @IsDateString()
  targetCompletionDate?: string;

  @ApiPropertyOptional({
    description: 'Urgency level',
    enum: ['no_rush', 'soon', 'urgent'],
  })
  @IsOptional()
  @IsString()
  urgency?: string;

  @ApiPropertyOptional({ description: 'Pre-calculated estimate min' })
  @IsOptional()
  @Type(() => Number)
  estimatedCostMin?: number;

  @ApiPropertyOptional({ description: 'Pre-calculated estimate max' })
  @IsOptional()
  @Type(() => Number)
  estimatedCostMax?: number;

  @ApiPropertyOptional({ description: 'Social proof note from estimation' })
  @IsOptional()
  @IsString()
  socialProofNote?: string;

  @ApiPropertyOptional({ description: 'Neighbor project count from estimation' })
  @IsOptional()
  @Type(() => Number)
  neighborProjectCount?: number;
}

export class UpdateProjectIdeaDto extends PartialType(CreateProjectIdeaDto) {}

export class ProgressProjectIdeaDto {
  @ApiProperty({
    enum: ProjectIdeaStatus,
    description: 'New status to progress to',
  })
  @IsEnum(ProjectIdeaStatus)
  status: ProjectIdeaStatus;
}

export class ListProjectIdeasQueryDto {
  @ApiPropertyOptional({ enum: ProjectIdeaStatus })
  status?: ProjectIdeaStatus;

  @ApiPropertyOptional({ enum: ProjectCategory })
  category?: ProjectCategory;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  page?: number;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  limit?: number;
}

export class ProjectIdeaDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty()
  createdByUserId: string;

  @ApiPropertyOptional()
  templateId?: string;

  @ApiProperty()
  title: string;

  @ApiProperty({ enum: ProjectCategory })
  category: ProjectCategory;

  @ApiPropertyOptional()
  description?: string;

  @ApiPropertyOptional()
  specs?: Record<string, unknown>;

  @ApiPropertyOptional()
  style?: string;

  @ApiPropertyOptional()
  vibeNotes?: string;

  @ApiProperty({ type: [String] })
  moodBoardImages: string[];

  @ApiPropertyOptional()
  estimatedCostMin?: number;

  @ApiPropertyOptional()
  estimatedCostMax?: number;

  @ApiProperty()
  neighborProjectCount: number;

  @ApiPropertyOptional()
  socialProofNote?: string;

  @ApiProperty({ enum: ProjectIdeaStatus })
  status: ProjectIdeaStatus;

  @ApiPropertyOptional()
  targetStartDate?: Date;

  @ApiPropertyOptional()
  targetCompletionDate?: Date;

  @ApiPropertyOptional()
  urgency?: string;

  @ApiPropertyOptional()
  workOrderId?: string;

  @ApiPropertyOptional()
  projectPostId?: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;

  // Relations
  @ApiPropertyOptional()
  template?: {
    id: string;
    name: string;
    slug: string;
  };

  @ApiPropertyOptional()
  createdBy?: {
    id: string;
    displayName: string;
  };
}

export class ConvertToWorkOrderDto {
  @ApiPropertyOptional({ description: 'Override title for work order' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ description: 'Override description for work order' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Vendor ID to assign' })
  @IsOptional()
  @IsString()
  vendorId?: string;
}
