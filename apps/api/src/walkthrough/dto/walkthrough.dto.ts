import { IsString, IsOptional, IsDateString } from 'class-validator';

export class RequestWalkthroughDto {
  @IsString()
  householdId: string;

  @IsDateString()
  @IsOptional()
  preferredDate?: string;

  @IsString()
  @IsOptional()
  preferredTimeSlot?: string; // 'morning' | 'afternoon' | 'evening'

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  contactPhone?: string;
}

export class WalkthroughEligibilityResponse {
  eligible: boolean;
  reason: string;
  hasScheduled: boolean;
  scheduledDate?: string;
}

export class WalkthroughRequestResponse {
  success: boolean;
  requestId: string;
  message: string;
  estimatedResponseTime: string;
}
