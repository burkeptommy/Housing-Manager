import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString, ValidateNested, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { TransactionPayoutMethod, TransactionStatus } from '@prisma/client';

// ============================================================================
// PAYOUT REQUEST DTOs
// ============================================================================

export class PayoutItemDto {
  @ApiProperty({ description: 'Transaction ID to pay' })
  @IsString()
  @IsNotEmpty()
  transactionId: string;

  @ApiProperty({ description: 'Payment method to use' })
  @IsEnum(TransactionPayoutMethod)
  payoutMethod: TransactionPayoutMethod;
}

export class ExecutePayoutDto {
  @ApiProperty({ description: 'List of transactions to pay', type: [PayoutItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PayoutItemDto)
  items: PayoutItemDto[];
}

export class SinglePayoutDto {
  @ApiProperty({ description: 'Transaction ID to pay' })
  @IsString()
  @IsNotEmpty()
  transactionId: string;

  @ApiProperty({ description: 'Payment method override' })
  @IsEnum(TransactionPayoutMethod)
  @IsOptional()
  payoutMethod?: TransactionPayoutMethod;
}

// ============================================================================
// VENDOR PAYABLE DTOs
// ============================================================================

export class VendorAddressDto {
  @ApiProperty()
  @IsString()
  name: string;

  @ApiProperty()
  @IsString()
  line1: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  line2?: string;

  @ApiProperty()
  @IsString()
  city: string;

  @ApiProperty()
  @IsString()
  state: string;

  @ApiProperty()
  @IsString()
  zip: string;
}

export class VendorPayableDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  transactionId: string;

  @ApiProperty()
  vendorId: string;

  @ApiProperty()
  vendorName: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty()
  householdName: string;

  @ApiProperty()
  description: string;

  @ApiProperty()
  amount: number;

  @ApiProperty({ enum: TransactionStatus })
  status: TransactionStatus;

  @ApiProperty()
  createdAt: string;

  @ApiPropertyOptional()
  vendorAddress?: VendorAddressDto;

  @ApiPropertyOptional()
  vendorStripeConnectId?: string;

  @ApiPropertyOptional()
  vendorEmail?: string;

  @ApiProperty({ description: 'Available payout methods for this vendor' })
  availablePayoutMethods: TransactionPayoutMethod[];

  @ApiProperty({ description: 'Recommended payout method' })
  recommendedPayoutMethod: TransactionPayoutMethod;
}

// ============================================================================
// PAYOUT RESPONSE DTOs
// ============================================================================

export class PayoutResultItemDto {
  @ApiProperty()
  transactionId: string;

  @ApiProperty()
  success: boolean;

  @ApiProperty({ enum: TransactionPayoutMethod })
  payoutMethod: TransactionPayoutMethod;

  @ApiPropertyOptional()
  referenceId?: string; // checkId or transferId

  @ApiPropertyOptional()
  error?: string;

  @ApiPropertyOptional()
  estimatedDelivery?: string;
}

export class ExecutePayoutResponseDto {
  @ApiProperty()
  success: boolean;

  @ApiProperty()
  totalAmount: number;

  @ApiProperty()
  totalItems: number;

  @ApiProperty()
  successfulItems: number;

  @ApiProperty()
  failedItems: number;

  @ApiProperty({ type: [PayoutResultItemDto] })
  results: PayoutResultItemDto[];

  @ApiPropertyOptional()
  summary?: {
    checksQueued: number;
    stripeTransfers: number;
    totalCheckAmount: number;
    totalStripeAmount: number;
  };
}

// ============================================================================
// BATCH PAY PREVIEW DTOs
// ============================================================================

export class BatchPayPreviewItemDto {
  @ApiProperty()
  transactionId: string;

  @ApiProperty()
  vendorName: string;

  @ApiProperty()
  amount: number;

  @ApiProperty({ enum: TransactionPayoutMethod })
  payoutMethod: TransactionPayoutMethod;

  @ApiProperty()
  methodLabel: string; // "Mail Check" or "Stripe Transfer"
}

export class BatchPayPreviewDto {
  @ApiProperty({ type: [BatchPayPreviewItemDto] })
  items: BatchPayPreviewItemDto[];

  @ApiProperty()
  totalAmount: number;

  @ApiProperty()
  checkCount: number;

  @ApiProperty()
  stripeCount: number;

  @ApiProperty()
  checkTotal: number;

  @ApiProperty()
  stripeTotal: number;
}
