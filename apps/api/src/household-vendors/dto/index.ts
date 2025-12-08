import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsEmail,
  IsUrl,
  MaxLength,
} from 'class-validator';
import { VendorCategory } from '@prisma/client';

export class CreateVendorDto {
  @ApiProperty({ description: 'Display name of the vendor' })
  @IsString()
  @MaxLength(255)
  displayName: string;

  @ApiProperty({ enum: VendorCategory, description: 'Category of the vendor' })
  @IsEnum(VendorCategory)
  category: VendorCategory;

  @ApiPropertyOptional({ description: 'Description of services provided' })
  @IsOptional()
  @IsString()
  serviceDescription?: string;

  @ApiPropertyOptional({ description: 'Is this a local vendor?' })
  @IsOptional()
  @IsBoolean()
  isLocal?: boolean;

  @ApiPropertyOptional({ description: 'Contact person name' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  contactName?: string;

  @ApiPropertyOptional({ description: 'Phone number' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  phone?: string;

  @ApiPropertyOptional({ description: 'Email address' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ description: 'Website URL' })
  @IsOptional()
  @IsUrl()
  websiteUrl?: string;

  @ApiPropertyOptional({ description: 'Address line 1' })
  @IsOptional()
  @IsString()
  addressLine1?: string;

  @ApiPropertyOptional({ description: 'Address line 2' })
  @IsOptional()
  @IsString()
  addressLine2?: string;

  @ApiPropertyOptional({ description: 'City' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ description: 'State' })
  @IsOptional()
  @IsString()
  state?: string;

  @ApiPropertyOptional({ description: 'Postal code' })
  @IsOptional()
  @IsString()
  postalCode?: string;

  @ApiPropertyOptional({ description: 'Notes about the vendor' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateVendorDto {
  @ApiPropertyOptional({ description: 'Display name of the vendor' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  displayName?: string;

  @ApiPropertyOptional({ enum: VendorCategory, description: 'Category of the vendor' })
  @IsOptional()
  @IsEnum(VendorCategory)
  category?: VendorCategory;

  @ApiPropertyOptional({ description: 'Description of services provided' })
  @IsOptional()
  @IsString()
  serviceDescription?: string;

  @ApiPropertyOptional({ description: 'Is this a local vendor?' })
  @IsOptional()
  @IsBoolean()
  isLocal?: boolean;

  @ApiPropertyOptional({ description: 'Contact person name' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  contactName?: string;

  @ApiPropertyOptional({ description: 'Phone number' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  phone?: string;

  @ApiPropertyOptional({ description: 'Email address' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ description: 'Website URL' })
  @IsOptional()
  @IsUrl()
  websiteUrl?: string;

  @ApiPropertyOptional({ description: 'Address line 1' })
  @IsOptional()
  @IsString()
  addressLine1?: string;

  @ApiPropertyOptional({ description: 'Address line 2' })
  @IsOptional()
  @IsString()
  addressLine2?: string;

  @ApiPropertyOptional({ description: 'City' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ description: 'State' })
  @IsOptional()
  @IsString()
  state?: string;

  @ApiPropertyOptional({ description: 'Postal code' })
  @IsOptional()
  @IsString()
  postalCode?: string;

  @ApiPropertyOptional({ description: 'Notes about the vendor' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ description: 'Is vendor active?' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class VendorResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty()
  displayName: string;

  @ApiProperty({ enum: VendorCategory })
  category: VendorCategory;

  @ApiPropertyOptional()
  serviceDescription?: string | null;

  @ApiProperty()
  isLocal: boolean;

  @ApiPropertyOptional()
  contactName?: string | null;

  @ApiPropertyOptional()
  phone?: string | null;

  @ApiPropertyOptional()
  email?: string | null;

  @ApiPropertyOptional()
  websiteUrl?: string | null;

  @ApiPropertyOptional()
  addressLine1?: string | null;

  @ApiPropertyOptional()
  addressLine2?: string | null;

  @ApiPropertyOptional()
  city?: string | null;

  @ApiPropertyOptional()
  state?: string | null;

  @ApiPropertyOptional()
  postalCode?: string | null;

  @ApiPropertyOptional()
  notes?: string | null;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

export class VendorQueryDto {
  @ApiPropertyOptional({ enum: VendorCategory, description: 'Filter by category' })
  @IsOptional()
  @IsEnum(VendorCategory)
  category?: VendorCategory;

  @ApiPropertyOptional({ description: 'Include inactive vendors' })
  @IsOptional()
  @IsBoolean()
  includeInactive?: boolean;
}
