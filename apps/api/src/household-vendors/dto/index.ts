import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsEmail,
  IsUrl,
  MaxLength,
  IsNumber,
  IsDateString,
  Min,
  Max,
  IsArray,
} from 'class-validator';
import { VendorCategory, VendorActivityType } from '@prisma/client';

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

  @ApiPropertyOptional({ description: 'Logo URL (auto-fetched from website if not provided)' })
  @IsOptional()
  @IsUrl()
  logoUrl?: string;

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

  @ApiPropertyOptional({ description: 'Logo URL (auto-fetched from website if not provided)' })
  @IsOptional()
  @IsUrl()
  logoUrl?: string;

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

  @ApiPropertyOptional({ description: 'Logo URL (auto-fetched from website)' })
  logoUrl?: string | null;

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

// ========== CRM Activity DTOs ==========

export class CreateActivityDto {
  @ApiProperty({ enum: VendorActivityType, description: 'Type of activity' })
  @IsEnum(VendorActivityType)
  type: VendorActivityType;

  @ApiProperty({ description: 'Title of the activity' })
  @IsString()
  @MaxLength(255)
  title: string;

  @ApiPropertyOptional({ description: 'Description or notes' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Amount (for payments, quotes, etc.)' })
  @IsOptional()
  @IsNumber()
  amount?: number;

  @ApiPropertyOptional({ description: 'Is this paid?' })
  @IsOptional()
  @IsBoolean()
  isPaid?: boolean;

  @ApiProperty({ description: 'Date of the activity' })
  @IsDateString()
  date: string;

  @ApiPropertyOptional({ description: 'Duration in minutes' })
  @IsOptional()
  @IsNumber()
  duration?: number;

  @ApiPropertyOptional({ description: 'Invoice URL' })
  @IsOptional()
  @IsUrl()
  invoiceUrl?: string;

  @ApiPropertyOptional({ description: 'Receipt URL' })
  @IsOptional()
  @IsUrl()
  receiptUrl?: string;

  @ApiPropertyOptional({ description: 'Related maintenance task ID' })
  @IsOptional()
  @IsString()
  maintenanceTaskId?: string;

  @ApiPropertyOptional({ description: 'Related service request ID' })
  @IsOptional()
  @IsString()
  serviceRequestId?: string;
}

export class ActivityResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdVendorId: string;

  @ApiProperty({ enum: VendorActivityType })
  type: VendorActivityType;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional()
  description?: string | null;

  @ApiPropertyOptional()
  amount?: number | null;

  @ApiProperty()
  isPaid: boolean;

  @ApiProperty()
  date: Date;

  @ApiPropertyOptional()
  duration?: number | null;

  @ApiPropertyOptional()
  invoiceUrl?: string | null;

  @ApiPropertyOptional()
  receiptUrl?: string | null;

  @ApiPropertyOptional()
  maintenanceTaskId?: string | null;

  @ApiPropertyOptional()
  serviceRequestId?: string | null;

  @ApiPropertyOptional()
  createdBy?: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

// ========== Extended Vendor Response with CRM data ==========

export class VendorWithCrmDto extends VendorResponseDto {
  @ApiPropertyOptional({ description: 'Is this vendor a favorite?' })
  isFavorite?: boolean;

  @ApiPropertyOptional({ description: 'Household rating (1-5)' })
  rating?: number | null;

  @ApiPropertyOptional({ description: 'Custom tags' })
  tags?: string[];

  @ApiPropertyOptional({ description: 'Source of vendor (manual, plaid, alfred, referral)' })
  source?: string | null;

  @ApiPropertyOptional({ description: 'Last contact date' })
  lastContactDate?: Date | null;

  @ApiPropertyOptional({ description: 'HouseholdVendor ID' })
  householdVendorId?: string;

  @ApiPropertyOptional({ description: 'Recent activities (up to 3)' })
  activities?: ActivityResponseDto[];

  @ApiPropertyOptional({ description: 'Total activity count' })
  activityCount?: number;
}
