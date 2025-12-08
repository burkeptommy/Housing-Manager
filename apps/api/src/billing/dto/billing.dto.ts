import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsEnum, IsOptional } from 'class-validator';

export enum SubscriptionTier {
  FREE = 'FREE',
  BASIC = 'BASIC',
  PREMIUM = 'PREMIUM',
  ENTERPRISE = 'ENTERPRISE',
}

export enum SubscriptionStatus {
  ACTIVE = 'ACTIVE',
  PAST_DUE = 'PAST_DUE',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED',
}

export class CreateSubscriptionDto {
  @ApiProperty({ description: 'Subscription tier', enum: SubscriptionTier })
  @IsEnum(SubscriptionTier)
  tier: SubscriptionTier;

  @ApiProperty({ description: 'Stripe payment method ID' })
  @IsString()
  paymentMethodId: string;
}

export class SubscriptionDto {
  @ApiProperty({ description: 'Subscription ID' })
  id: string;

  @ApiProperty({ description: 'User ID' })
  userId: string;

  @ApiProperty({ description: 'Subscription tier', enum: SubscriptionTier })
  tier: SubscriptionTier;

  @ApiProperty({ description: 'Subscription status', enum: SubscriptionStatus })
  status: SubscriptionStatus;

  @ApiProperty({ description: 'Current billing period start' })
  currentPeriodStart: Date;

  @ApiProperty({ description: 'Current billing period end' })
  currentPeriodEnd: Date;

  @ApiPropertyOptional({ description: 'Stripe customer ID' })
  stripeCustomerId: string | null;

  @ApiPropertyOptional({ description: 'Stripe subscription ID' })
  stripeSubscriptionId: string | null;

  @ApiPropertyOptional({ description: 'When subscription was cancelled' })
  cancelledAt: Date | null;

  @ApiProperty({ description: 'Whether subscription will cancel at period end' })
  cancelAtPeriodEnd: boolean;

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  updatedAt: Date;
}

export class CancelSubscriptionDto {
  @ApiPropertyOptional({
    description: 'Whether to cancel immediately or at period end',
    default: true,
  })
  @IsOptional()
  cancelAtPeriodEnd?: boolean;
}
