import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsInt,
  Min,
  Max,
  MaxLength,
  IsBoolean,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';

export class SubmitVendorSuggestionDto {
  @ApiPropertyOptional({ description: 'Project idea ID to suggest vendor for' })
  @IsOptional()
  @IsString()
  projectIdeaId?: string;

  @ApiPropertyOptional({ description: 'Recommendation request ID to respond to' })
  @IsOptional()
  @IsString()
  recommendationRequestId?: string;

  @ApiProperty({ description: 'Vendor ID being suggested' })
  @IsString()
  vendorId: string;

  @ApiPropertyOptional({ description: 'Comment about the vendor' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  comment?: string;

  @ApiPropertyOptional({ description: 'Rating 1-5 stars', minimum: 1, maximum: 5 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  @Type(() => Number)
  rating?: number;

  @ApiPropertyOptional({ description: 'Reference to your project post with this vendor' })
  @IsOptional()
  @IsString()
  referenceProjectPostId?: string;
}

export class VendorSuggestionDto {
  @ApiProperty()
  id: string;

  @ApiPropertyOptional()
  projectIdeaId?: string;

  @ApiPropertyOptional()
  recommendationRequestId?: string;

  @ApiProperty()
  vendorId: string;

  @ApiPropertyOptional()
  suggestedByUserId?: string;

  @ApiPropertyOptional()
  comment?: string;

  @ApiPropertyOptional()
  rating?: number;

  @ApiProperty()
  isSystemSuggestion: boolean;

  @ApiPropertyOptional()
  systemNote?: string;

  @ApiPropertyOptional()
  referenceProjectPostId?: string;

  @ApiPropertyOptional()
  isHelpful?: boolean;

  @ApiProperty()
  createdAt: Date;

  // Relations
  @ApiPropertyOptional()
  vendor?: {
    id: string;
    companyName: string;
    contactName?: string;
    email?: string;
    phone?: string;
    specialty?: string[];
    averageRating?: number;
    completedJobsCount?: number;
  };

  @ApiPropertyOptional()
  suggestedBy?: {
    id: string;
    displayName: string;
  };

  @ApiPropertyOptional()
  referenceProjectPost?: {
    id: string;
    title: string;
    mediaUrls: string[];
  };
}

export class SuggestionFeedbackDto {
  @ApiProperty({ description: 'Was this suggestion helpful?' })
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isHelpful: boolean;
}

export class VendorWithSocialSignalsDto {
  @ApiProperty()
  vendor: {
    id: string;
    companyName: string;
    contactName?: string;
    specialty?: string[];
    averageRating?: number;
  };

  @ApiProperty({ description: 'Number of neighbors who used this vendor' })
  usedByNeighborsCount: number;

  @ApiProperty({ description: 'Number of friends who used this vendor' })
  usedByFriendsCount: number;

  @ApiProperty({
    description: 'Friend recommendations with their projects',
    type: 'array',
  })
  friendRecommendations: {
    userId: string;
    displayName: string;
    projectPostId?: string;
    projectTitle?: string;
  }[];
}
