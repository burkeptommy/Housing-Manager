import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsNumber, IsBoolean, IsArray, IsEnum } from 'class-validator';

// ============================================================================
// MONTHLY INVOICE DTOs
// ============================================================================

export enum MonthlyInvoiceStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  PAID = 'PAID',
  FAILED = 'FAILED',
  PAST_DUE = 'PAST_DUE',
}

export class TransactionLineItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  transactionId: string;

  @ApiProperty()
  description: string;

  @ApiProperty()
  vendorName: string | null;

  @ApiProperty()
  amount: number;

  @ApiProperty()
  paidAt: Date | null;

  @ApiPropertyOptional()
  receiptUrl?: string;

  @ApiPropertyOptional()
  managerNote?: string;
}

export class MonthlyInvoiceDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  invoiceNumber: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty()
  householdName: string;

  @ApiProperty()
  billingPeriodStart: Date;

  @ApiProperty()
  billingPeriodEnd: Date;

  @ApiProperty()
  transactionsSubtotal: number;

  @ApiProperty()
  managementFee: number;

  @ApiProperty()
  total: number;

  @ApiProperty({ enum: MonthlyInvoiceStatus })
  status: MonthlyInvoiceStatus;

  @ApiPropertyOptional()
  stripePaymentIntentId?: string;

  @ApiPropertyOptional()
  dueDate?: Date;

  @ApiPropertyOptional()
  paidAt?: Date;

  @ApiPropertyOptional()
  failedAt?: Date;

  @ApiPropertyOptional()
  failureReason?: string;

  @ApiProperty({ type: [TransactionLineItemDto] })
  lineItems: TransactionLineItemDto[];

  @ApiProperty()
  createdAt: Date;
}

export class MonthlyInvoiceListItemDto {
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

  @ApiProperty({ enum: MonthlyInvoiceStatus })
  status: MonthlyInvoiceStatus;

  @ApiProperty()
  itemCount: number;

  @ApiPropertyOptional()
  paidAt?: Date;

  @ApiProperty()
  createdAt: Date;
}

// ============================================================================
// GENERATE INVOICE DTOs
// ============================================================================

export class GenerateInvoiceDto {
  @ApiProperty({ description: 'Household ID to generate invoice for' })
  @IsString()
  householdId: string;

  @ApiPropertyOptional({ description: 'Override billing period start (defaults to 1st of last month)' })
  @IsOptional()
  billingPeriodStart?: Date;

  @ApiPropertyOptional({ description: 'Override billing period end (defaults to last day of last month)' })
  @IsOptional()
  billingPeriodEnd?: Date;

  @ApiPropertyOptional({ description: 'Override management fee (defaults to household setting or $100)' })
  @IsNumber()
  @IsOptional()
  managementFee?: number;
}

export class GenerateInvoiceResponseDto {
  @ApiProperty()
  success: boolean;

  @ApiPropertyOptional()
  invoice?: MonthlyInvoiceDto;

  @ApiPropertyOptional()
  error?: string;
}

export class GenerateAllInvoicesResponseDto {
  @ApiProperty()
  success: boolean;

  @ApiProperty()
  totalHouseholds: number;

  @ApiProperty()
  invoicesGenerated: number;

  @ApiProperty()
  invoicesSkipped: number;

  @ApiProperty({ type: [String] })
  errors: string[];
}

// ============================================================================
// COLLECTION DTOs
// ============================================================================

export class CollectInvoiceDto {
  @ApiProperty({ description: 'Invoice ID to collect payment for' })
  @IsString()
  invoiceId: string;

  @ApiPropertyOptional({ description: 'Force collection even if already attempted' })
  @IsBoolean()
  @IsOptional()
  force?: boolean;
}

export class CollectionResultDto {
  @ApiProperty()
  success: boolean;

  @ApiProperty()
  invoiceId: string;

  @ApiPropertyOptional()
  paymentIntentId?: string;

  @ApiPropertyOptional()
  status?: string;

  @ApiPropertyOptional()
  error?: string;
}

export class BatchCollectionResultDto {
  @ApiProperty()
  success: boolean;

  @ApiProperty()
  totalInvoices: number;

  @ApiProperty()
  successfulCollections: number;

  @ApiProperty()
  failedCollections: number;

  @ApiProperty({ type: [CollectionResultDto] })
  results: CollectionResultDto[];
}

// ============================================================================
// REVENUE / STATS DTOs
// ============================================================================

export class RevenueStatsDto {
  @ApiProperty({ description: 'Total reimbursements pending collection' })
  pendingAmount: number;

  @ApiProperty({ description: 'Total collected this month' })
  collectedThisMonth: number;

  @ApiProperty({ description: 'Total collected all time' })
  collectedAllTime: number;

  @ApiProperty({ description: 'Total failed/past due' })
  failedAmount: number;

  @ApiProperty({ description: 'Number of pending invoices' })
  pendingInvoices: number;

  @ApiProperty({ description: 'Number of paid invoices this month' })
  paidInvoicesThisMonth: number;

  @ApiProperty({ description: 'Number of failed invoices' })
  failedInvoices: number;

  @ApiProperty({ description: 'Monthly trend data' })
  monthlyTrend: MonthlyRevenueDto[];
}

export class MonthlyRevenueDto {
  @ApiProperty()
  month: string; // YYYY-MM format

  @ApiProperty()
  pending: number;

  @ApiProperty()
  collected: number;

  @ApiProperty()
  failed: number;
}

export class HouseholdRevenueDto {
  @ApiProperty()
  householdId: string;

  @ApiProperty()
  householdName: string;

  @ApiProperty()
  pendingAmount: number;

  @ApiProperty()
  collectedAmount: number;

  @ApiProperty()
  failedAmount: number;

  @ApiProperty()
  lastInvoiceStatus: string;

  @ApiProperty()
  lastInvoiceDate: Date | null;
}
