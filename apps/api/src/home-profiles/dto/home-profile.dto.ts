import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PropertyType } from '@prisma/client';
import {
  IsString,
  IsOptional,
  IsNotEmpty,
  IsEnum,
  IsInt,
  IsNumber,
  IsPositive,
  Min,
  Max,
  MaxLength,
  IsDateString,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpsertHomeProfileDto {
  @ApiProperty({ enum: PropertyType, default: PropertyType.SINGLE_FAMILY })
  @IsEnum(PropertyType)
  propertyType: PropertyType;

  // Address
  @ApiProperty({ example: '123 Main Street' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  addressLine1: string;

  @ApiPropertyOptional({ example: 'Apt 4B' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  addressLine2?: string;

  @ApiProperty({ example: 'San Francisco' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  city: string;

  @ApiProperty({ example: 'CA' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  state: string;

  @ApiProperty({ example: '94102' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  postalCode: string;

  @ApiPropertyOptional({ example: 'US', default: 'US' })
  @IsOptional()
  @IsString()
  @MaxLength(2)
  country?: string;

  // Property Details
  @ApiPropertyOptional({ example: 2000 })
  @IsOptional()
  @IsInt()
  @IsPositive()
  @Type(() => Number)
  squareFeet?: number;

  @ApiPropertyOptional({ example: 0.25, description: 'Lot size in acres' })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  @Type(() => Number)
  lotSize?: number;

  @ApiPropertyOptional({ example: 2010 })
  @IsOptional()
  @IsInt()
  @Min(1800)
  @Max(new Date().getFullYear() + 1)
  @Type(() => Number)
  yearBuilt?: number;

  @ApiPropertyOptional({ example: 3 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  bedrooms?: number;

  @ApiPropertyOptional({ example: 2.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  bathrooms?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  stories?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  garageSpaces?: number;

  // Financial Info
  @ApiPropertyOptional({ example: '2020-06-15' })
  @IsOptional()
  @IsDateString()
  purchaseDate?: string;

  @ApiPropertyOptional({ example: 750000 })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  @Type(() => Number)
  purchasePrice?: number;

  @ApiPropertyOptional({ example: 850000 })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  @Type(() => Number)
  currentValue?: number;

  // Notes
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}

export class HomeProfileDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty({ enum: PropertyType })
  propertyType: PropertyType;

  // Address
  @ApiProperty()
  addressLine1: string;

  @ApiPropertyOptional()
  addressLine2: string | null;

  @ApiProperty()
  city: string;

  @ApiProperty()
  state: string;

  @ApiProperty()
  postalCode: string;

  @ApiProperty()
  country: string;

  // Property Details
  @ApiPropertyOptional()
  squareFeet: number | null;

  @ApiPropertyOptional()
  lotSize: number | null;

  @ApiPropertyOptional()
  yearBuilt: number | null;

  @ApiPropertyOptional()
  bedrooms: number | null;

  @ApiPropertyOptional()
  bathrooms: number | null;

  @ApiPropertyOptional()
  stories: number | null;

  @ApiPropertyOptional()
  garageSpaces: number | null;

  // Financial
  @ApiPropertyOptional()
  purchaseDate: Date | null;

  @ApiPropertyOptional()
  purchasePrice: number | null;

  @ApiPropertyOptional()
  currentValue: number | null;

  @ApiPropertyOptional()
  notes: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
