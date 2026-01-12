import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsEmail, MaxLength } from 'class-validator';
import { ReferralStatus } from '@prisma/client';

export class CreateReferralDto {
  @ApiPropertyOptional({ description: 'Email of the person being referred' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ description: 'Personal message to include' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}

export class ApplyReferralDto {
  @ApiProperty({ description: 'Referral code to apply' })
  @IsString()
  referralCode: string;
}

export class ReferralResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  referralCode: string;

  @ApiPropertyOptional()
  refereeEmail?: string | null;

  @ApiProperty({ enum: ReferralStatus })
  status: ReferralStatus;

  @ApiProperty()
  rewardEarned: boolean;

  @ApiPropertyOptional()
  rewardAmount?: number | null;

  @ApiPropertyOptional()
  signedUpAt?: Date | null;

  @ApiPropertyOptional()
  convertedAt?: Date | null;

  @ApiProperty()
  expiresAt: Date;

  @ApiProperty()
  createdAt: Date;

  @ApiPropertyOptional()
  referee?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  };
}

export class ReferralStatsDto {
  @ApiProperty()
  totalReferrals: number;

  @ApiProperty()
  pendingReferrals: number;

  @ApiProperty()
  signedUpReferrals: number;

  @ApiProperty()
  convertedReferrals: number;

  @ApiProperty()
  totalEarnings: number;

  @ApiProperty()
  pendingEarnings: number;

  @ApiProperty()
  referralCode: string;

  @ApiProperty()
  shareUrl: string;
}
