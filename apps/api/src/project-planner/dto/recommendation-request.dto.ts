import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsOptional,
  IsString,
  IsBoolean,
  IsDateString,
  MaxLength,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { RecommendationRequestStatus } from '@prisma/client';

export class CreateRecommendationRequestDto {
  @ApiProperty({ description: 'Project idea ID to create request for' })
  @IsString()
  projectIdeaId: string;

  @ApiProperty({ description: 'Request title' })
  @IsString()
  @MaxLength(200)
  title: string;

  @ApiPropertyOptional({ description: 'Request description' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({
    description: 'Budget range',
    enum: ['under_5k', '5k_15k', '15k_30k', '30k_plus'],
  })
  @IsOptional()
  @IsString()
  budget?: string;

  @ApiPropertyOptional({
    description: 'Timeline preference',
    enum: ['flexible', '1_month', '3_months', '6_months', 'urgent'],
  })
  @IsOptional()
  @IsString()
  timeline?: string;

  @ApiPropertyOptional({ description: 'Make request visible to neighbors', default: true })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isPublic?: boolean;

  @ApiPropertyOptional({ description: 'Request expiration date' })
  @IsOptional()
  @IsDateString()
  expiresAt?: string;
}

export class ListRecommendationRequestsQueryDto {
  @ApiPropertyOptional({ enum: RecommendationRequestStatus })
  status?: RecommendationRequestStatus;

  @ApiPropertyOptional({ description: 'Filter nearby requests by H3 index' })
  @IsOptional()
  @IsString()
  h3Index?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  page?: number;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  limit?: number;
}

export class RecommendationRequestDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  projectIdeaId: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty()
  createdByUserId: string;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiPropertyOptional()
  budget?: string;

  @ApiPropertyOptional()
  timeline?: string;

  @ApiPropertyOptional()
  h3Index?: string;

  @ApiProperty()
  isPublic: boolean;

  @ApiProperty({ enum: RecommendationRequestStatus })
  status: RecommendationRequestStatus;

  @ApiProperty()
  viewCount: number;

  @ApiProperty()
  suggestionCount: number;

  @ApiPropertyOptional()
  expiresAt?: Date;

  @ApiPropertyOptional()
  closedAt?: Date;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;

  // Relations
  @ApiPropertyOptional()
  projectIdea?: {
    id: string;
    title: string;
    category: string;
    estimatedCostMin?: number;
    estimatedCostMax?: number;
  };

  @ApiPropertyOptional()
  createdBy?: {
    id: string;
    displayName: string;
  };

  @ApiPropertyOptional()
  household?: {
    id: string;
    name: string;
  };
}

export class UpdateRecommendationRequestStatusDto {
  @ApiProperty({ enum: RecommendationRequestStatus })
  @IsEnum(RecommendationRequestStatus)
  status: RecommendationRequestStatus;
}
