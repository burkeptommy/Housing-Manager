import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsNumber,
  IsDateString,
  IsUrl,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
  VendorCategory,
  BillingFrequency,
  PaymentResponsibility,
} from '@prisma/client';

export class CreateBillAccountDto {
  @ApiProperty({ description: 'Household ID' })
  @IsString()
  householdId: string;

  @ApiProperty({ description: 'Vendor ID' })
  @IsString()
  vendorId: string;

  @ApiProperty({ description: 'Nickname for the account (e.g., "Primary Mortgage")' })
  @IsString()
  @MaxLength(255)
  nickname: string;

  @ApiProperty({ enum: VendorCategory, description: 'Bill category' })
  @IsEnum(VendorCategory)
  category: VendorCategory;

  @ApiPropertyOptional({ description: 'Account number' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  accountNumber?: string;

  @ApiPropertyOptional({ enum: BillingFrequency, description: 'Billing frequency' })
  @IsOptional()
  @IsEnum(BillingFrequency)
  billingFrequency?: BillingFrequency;

  @ApiPropertyOptional({ enum: PaymentResponsibility, description: 'Who pays the bill' })
  @IsOptional()
  @IsEnum(PaymentResponsibility)
  paymentResponsibility?: PaymentResponsibility;

  @ApiPropertyOptional({ description: 'Typical bill amount' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  typicalAmount?: number;

  @ApiPropertyOptional({ description: 'Next due date (ISO 8601)' })
  @IsOptional()
  @IsDateString()
  nextDueDate?: string;

  @ApiPropertyOptional({ description: 'Is autopay enabled?' })
  @IsOptional()
  @IsBoolean()
  autopayEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Payment method ID for autopay' })
  @IsOptional()
  @IsString()
  paymentMethodId?: string;

  @ApiPropertyOptional({ description: 'URL to pay/manage the account' })
  @IsOptional()
  @IsUrl()
  portalUrl?: string;

  @ApiPropertyOptional({ description: 'Support phone number' })
  @IsOptional()
  @IsString()
  supportPhone?: string;

  @ApiPropertyOptional({ description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateBillAccountDto {
  @ApiPropertyOptional({ description: 'Vendor ID' })
  @IsOptional()
  @IsString()
  vendorId?: string;

  @ApiPropertyOptional({ description: 'Nickname for the account' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  nickname?: string;

  @ApiPropertyOptional({ enum: VendorCategory, description: 'Bill category' })
  @IsOptional()
  @IsEnum(VendorCategory)
  category?: VendorCategory;

  @ApiPropertyOptional({ description: 'Account number' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  accountNumber?: string;

  @ApiPropertyOptional({ enum: BillingFrequency, description: 'Billing frequency' })
  @IsOptional()
  @IsEnum(BillingFrequency)
  billingFrequency?: BillingFrequency;

  @ApiPropertyOptional({ enum: PaymentResponsibility, description: 'Who pays the bill' })
  @IsOptional()
  @IsEnum(PaymentResponsibility)
  paymentResponsibility?: PaymentResponsibility;

  @ApiPropertyOptional({ description: 'Typical bill amount' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  typicalAmount?: number;

  @ApiPropertyOptional({ description: 'Next due date (ISO 8601)' })
  @IsOptional()
  @IsDateString()
  nextDueDate?: string;

  @ApiPropertyOptional({ description: 'Is autopay enabled?' })
  @IsOptional()
  @IsBoolean()
  autopayEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Payment method ID for autopay' })
  @IsOptional()
  @IsString()
  paymentMethodId?: string;

  @ApiPropertyOptional({ description: 'URL to pay/manage the account' })
  @IsOptional()
  @IsUrl()
  portalUrl?: string;

  @ApiPropertyOptional({ description: 'Support phone number' })
  @IsOptional()
  @IsString()
  supportPhone?: string;

  @ApiPropertyOptional({ description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ description: 'Is account active?' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class BillAccountResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty()
  vendorId: string;

  @ApiPropertyOptional()
  paymentMethodId?: string | null;

  @ApiProperty()
  nickname: string;

  @ApiProperty({ enum: VendorCategory })
  category: VendorCategory;

  @ApiPropertyOptional()
  accountNumber?: string | null;

  @ApiProperty({ enum: BillingFrequency })
  billingFrequency: BillingFrequency;

  @ApiProperty({ enum: PaymentResponsibility })
  paymentResponsibility: PaymentResponsibility;

  @ApiPropertyOptional()
  typicalAmount?: number | null;

  @ApiPropertyOptional()
  nextDueDate?: Date | null;

  @ApiProperty()
  autopayEnabled: boolean;

  @ApiPropertyOptional()
  portalUrl?: string | null;

  @ApiPropertyOptional()
  supportPhone?: string | null;

  @ApiPropertyOptional()
  notes?: string | null;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;

  // Included relations
  @ApiPropertyOptional()
  vendor?: {
    id: string;
    displayName: string;
    category: VendorCategory;
  };
}

export class BillAccountQueryDto {
  @ApiPropertyOptional({ description: 'Household ID' })
  @IsOptional()
  @IsString()
  householdId?: string;

  @ApiPropertyOptional({ enum: VendorCategory, description: 'Filter by category' })
  @IsOptional()
  @IsEnum(VendorCategory)
  category?: VendorCategory;

  @ApiPropertyOptional({ description: 'Filter by upcoming due date (days)' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  upcomingDays?: number;

  @ApiPropertyOptional({ description: 'Include inactive accounts' })
  @IsOptional()
  @IsBoolean()
  includeInactive?: boolean;
}
