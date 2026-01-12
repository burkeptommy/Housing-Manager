import { Type } from 'class-transformer';
import {
  IsString,
  IsOptional,
  IsInt,
  IsNumber,
  IsBoolean,
  IsArray,
  IsDate,
  IsEnum,
  Min,
} from 'class-validator';
import { ZoneType, AssetCategory } from '@prisma/client';

// ============================================================================
// ZONE DTOs
// ============================================================================

export class CreateZoneDto {
  @IsString()
  name: string;

  @IsEnum(ZoneType)
  type: ZoneType;

  @IsOptional()
  @IsString()
  floor?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photos?: string[];

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  procedures?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

export class UpdateZoneDto extends CreateZoneDto {}

// ============================================================================
// PROPERTY ASSET DTOs
// ============================================================================

export class CreateAssetDto {
  @IsString()
  name: string;

  @IsEnum(AssetCategory)
  category: AssetCategory;

  @IsOptional()
  @IsString()
  zoneId?: string;

  @IsOptional()
  @IsString()
  brand?: string;

  @IsOptional()
  @IsString()
  model?: string;

  @IsOptional()
  @IsString()
  serialNumber?: string;

  @IsOptional()
  @IsString()
  color?: string;

  // Purchase/Warranty
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  purchaseDate?: Date;

  @IsOptional()
  @IsNumber()
  purchasePrice?: number;

  @IsOptional()
  @IsString()
  purchaseVendor?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  warrantyExpires?: Date;

  @IsOptional()
  @IsString()
  warrantyNotes?: string;

  // Condition
  @IsOptional()
  @IsString()
  condition?: string;

  @IsOptional()
  @IsString()
  conditionNotes?: string;

  // Service
  @IsOptional()
  @IsString()
  serviceVendorId?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastServiceDate?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  nextServiceDate?: Date;

  @IsOptional()
  @IsString()
  serviceInterval?: string;

  // Documents/Photos
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photos?: string[];

  @IsOptional()
  @IsString()
  manualUrl?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateAssetDto extends CreateAssetDto {
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
