import { IsString, IsOptional, IsEnum, IsNumber, IsArray, IsBoolean, Min, Max } from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { PostVisibility, CostDisplay } from '@prisma/client';

// ========== Friendship DTOs ==========

export class SendFriendRequestDto {
  @IsString()
  addresseeId: string;
}

export class FriendRequestActionDto {
  @IsString()
  friendshipId: string;
}

// ========== Follow DTOs ==========

export class FollowUserDto {
  @IsString()
  userId: string;
}

// ========== Project Post DTOs ==========

export class CreateProjectPostDto {
  @IsString()
  householdId: string;

  @IsOptional()
  @IsString()
  workOrderId?: string;

  @IsOptional()
  @IsString()
  vendorId?: string;

  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  beforeImages?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  afterImages?: string[];

  @IsOptional()
  @IsEnum(PostVisibility)
  visibility?: PostVisibility;

  @IsOptional()
  @IsEnum(CostDisplay)
  costDisplay?: CostDisplay;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  actualCost?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  costRangeMin?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  costRangeMax?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  durationDays?: number;

  @IsOptional()
  @Type(() => Date)
  completedAt?: Date;
}

export class UpdateProjectPostDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  beforeImages?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  afterImages?: string[];

  @IsOptional()
  @IsEnum(PostVisibility)
  visibility?: PostVisibility;

  @IsOptional()
  @IsEnum(CostDisplay)
  costDisplay?: CostDisplay;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  actualCost?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  costRangeMin?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  costRangeMax?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  durationDays?: number;
}

export class AddCommentDto {
  @IsString()
  content: string;
}

// ========== Feed DTOs ==========

export class FeedQueryDto {
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(50)
  limit?: number;

  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @IsEnum(['neighbor', 'friend', 'following'])
  source?: 'neighbor' | 'friend' | 'following';
}

// ========== Social Vendor DTOs ==========

export class SocialVendorSearchDto {
  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsEnum(['friends', 'neighbors', 'influencers'])
  socialProof?: 'friends' | 'neighbors' | 'influencers';

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(50)
  limit?: number;

  @IsOptional()
  @IsString()
  cursor?: string;
}

// ========== Profile DTOs ==========

export class UpdateSocialProfileDto {
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === 'true' || value === true)
  isPublicProfile?: boolean;

  @IsOptional()
  @IsString()
  bio?: string;

  @IsOptional()
  @IsString()
  displayName?: string;
}

// ========== Pagination DTOs ==========

export class PaginationQueryDto {
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(50)
  limit?: number;

  @IsOptional()
  @IsString()
  cursor?: string;
}
