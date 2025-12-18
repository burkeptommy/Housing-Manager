import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsOptional, IsString, IsArray, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ProjectCategory } from '@prisma/client';

export class ProjectSpecsDto {
  @ApiProperty({ description: 'Square footage of the project' })
  @IsNumber()
  @Min(1)
  @Type(() => Number)
  sqFt: number;

  @ApiPropertyOptional({ description: 'Material choice (e.g., "composite", "wood", "hardwood")' })
  @IsOptional()
  @IsString()
  material?: string;

  @ApiPropertyOptional({ description: 'Complexity factors to apply', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  complexity?: string[];
}

export class CalculateEstimateDto {
  @ApiPropertyOptional({ description: 'Template ID to base estimate on' })
  @IsOptional()
  @IsString()
  templateId?: string;

  @ApiProperty({ enum: ProjectCategory, description: 'Project category' })
  @IsEnum(ProjectCategory)
  category: ProjectCategory;

  @ApiProperty({ type: ProjectSpecsDto, description: 'Project specifications' })
  @Type(() => ProjectSpecsDto)
  specs: ProjectSpecsDto;
}

export class CostBreakdownDto {
  @ApiProperty()
  materials: number;

  @ApiProperty()
  labor: number;

  @ApiProperty()
  regionalAdjustment: number;

  @ApiProperty()
  complexityAdjustment: number;
}

export class SocialProofDto {
  @ApiProperty({ description: 'Number of neighbors who completed similar projects' })
  neighborProjectCount: number;

  @ApiPropertyOptional({ description: 'Average cost from neighbor projects' })
  averageCost?: number;

  @ApiProperty({ description: 'Human-readable social proof note' })
  note: string;
}

export class EstimateResultDto {
  @ApiProperty({ description: 'Minimum estimated cost' })
  estimatedMin: number;

  @ApiProperty({ description: 'Maximum estimated cost' })
  estimatedMax: number;

  @ApiProperty({ type: CostBreakdownDto, description: 'Cost breakdown' })
  breakdown: CostBreakdownDto;

  @ApiProperty({ description: 'Regional cost multiplier applied' })
  regionalMultiplier: number;

  @ApiProperty({ type: SocialProofDto, description: 'Social proof from neighbors' })
  socialProof: SocialProofDto;

  @ApiPropertyOptional({ description: 'Template used for estimate' })
  templateName?: string;

  @ApiPropertyOptional({ description: 'Estimated project duration in days' })
  estimatedDays?: { min: number; max: number };
}

export class RegionalMultiplierDto {
  @ApiProperty({ description: 'Regional cost multiplier' })
  multiplier: number;

  @ApiProperty({ description: 'Regional labor multiplier' })
  laborMultiplier: number;

  @ApiPropertyOptional({ description: 'Region name' })
  regionName?: string;

  @ApiPropertyOptional({ description: 'State code' })
  stateCode?: string;

  @ApiProperty({ description: 'H3 index used' })
  h3Index: string;
}
