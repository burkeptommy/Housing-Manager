import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsDateString,
  Min,
} from 'class-validator';

// Mirror the Prisma enum
export enum HouseholdInvoiceStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  PAID = 'PAID',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
}

export class HouseholdInvoiceItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  billAccountId: string;

  @ApiProperty()
  description: string;

  @ApiProperty()
  amount: number;

  @ApiPropertyOptional()
  billNickname?: string;

  @ApiPropertyOptional()
  vendorName?: string;

  @ApiPropertyOptional()
  category?: string;
}

export class HouseholdInvoiceDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty()
  invoiceNumber: string;

  @ApiProperty()
  billingPeriodStart: Date;

  @ApiProperty()
  billingPeriodEnd: Date;

  @ApiProperty()
  subtotal: number;

  @ApiProperty()
  platformFee: number;

  @ApiProperty()
  total: number;

  @ApiProperty({ enum: HouseholdInvoiceStatus })
  status: HouseholdInvoiceStatus;

  @ApiPropertyOptional()
  stripePaymentIntentId?: string;

  @ApiPropertyOptional()
  stripePaymentStatus?: string;

  @ApiPropertyOptional()
  paidAt?: Date;

  @ApiPropertyOptional()
  failedAt?: Date;

  @ApiPropertyOptional()
  failureReason?: string;

  @ApiProperty({ type: [HouseholdInvoiceItemDto] })
  items: HouseholdInvoiceItemDto[];

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

export class HouseholdInvoiceListItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  invoiceNumber: string;

  @ApiProperty()
  billingPeriodStart: Date;

  @ApiProperty()
  billingPeriodEnd: Date;

  @ApiProperty()
  total: number;

  @ApiProperty({ enum: HouseholdInvoiceStatus })
  status: HouseholdInvoiceStatus;

  @ApiProperty()
  itemCount: number;

  @ApiProperty()
  createdAt: Date;
}

// DTO for billing summary shown on dashboard
export class BillingSummaryDto {
  @ApiProperty({ description: 'Current subscription tier' })
  subscriptionTier: string;

  @ApiProperty({ description: 'Monthly subscription amount' })
  subscriptionAmount: number;

  @ApiPropertyOptional({ description: 'Current subscription status' })
  subscriptionStatus?: string;

  @ApiPropertyOptional({ description: 'Latest consolidated invoice' })
  latestInvoice?: HouseholdInvoiceListItemDto;

  @ApiProperty({ description: 'Total bills managed by Haven' })
  totalBillsManaged: number;

  @ApiProperty({ description: 'Monthly estimated bill total' })
  monthlyBillEstimate: number;

  @ApiProperty({ description: 'Bill accounts included in consolidated billing' })
  billAccountsIncluded: Array<{
    id: string;
    nickname: string;
    vendorName: string;
    category: string;
    typicalAmount: number | null;
  }>;
}

// DTO for cron job to generate invoices
export class GenerateInvoicesResultDto {
  @ApiProperty()
  success: boolean;

  @ApiProperty()
  invoicesGenerated: number;

  @ApiProperty()
  householdsProcessed: number;

  @ApiPropertyOptional()
  errors?: string[];
}

// Request DTO for setting up household Stripe customer
export class SetupHouseholdStripeDto {
  @ApiProperty({ description: 'Stripe Payment Method ID' })
  @IsString()
  paymentMethodId: string;
}

// Request DTO for updating billing preferences
export class UpdateBillingPreferencesDto {
  @ApiPropertyOptional({ description: 'Day of month for consolidated billing (1-28)' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  consolidatedBillingDay?: number;
}
