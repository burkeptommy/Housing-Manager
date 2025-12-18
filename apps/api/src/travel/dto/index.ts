import { Type, Transform } from 'class-transformer';
import {
  IsString,
  IsOptional,
  IsInt,
  IsNumber,
  IsBoolean,
  IsArray,
  IsDate,
  IsEnum,
  Min,
  ValidateNested,
} from 'class-validator';
import {
  TripStatus,
  ItineraryItemType,
  SeatingPreference,
  HouseProtocolStatus,
  ProtocolItemStatus,
} from '@prisma/client';

// ============================================================================
// TRAVEL PROFILE DTOs
// ============================================================================

export class LoyaltyProgramDto {
  @IsString()
  provider: string;

  @IsString()
  number: string;

  @IsOptional()
  @IsString()
  tier?: string;
}

export class UpdateTravelProfileDto {
  @IsOptional()
  @IsString()
  passportNumber?: string;

  @IsOptional()
  @IsString()
  passportCountry?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  passportExpiry?: Date;

  @IsOptional()
  @IsString()
  tsaPreCheck?: string;

  @IsOptional()
  @IsString()
  globalEntry?: string;

  @IsOptional()
  @IsEnum(SeatingPreference)
  seatingPreference?: SeatingPreference;

  @IsOptional()
  @IsString()
  mealPreference?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LoyaltyProgramDto)
  airlineLoyalty?: LoyaltyProgramDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LoyaltyProgramDto)
  hotelLoyalty?: LoyaltyProgramDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LoyaltyProgramDto)
  carRentalLoyalty?: LoyaltyProgramDto[];

  @IsOptional()
  @IsString()
  emergencyContactName?: string;

  @IsOptional()
  @IsString()
  emergencyContactPhone?: string;
}

// ============================================================================
// TRIP DTOs
// ============================================================================

export class TravelerDto {
  @IsString()
  memberId: string;

  @IsString()
  role: string; // "adult", "child", "infant"
}

export class CreateTripDto {
  @IsString()
  title: string;

  @IsString()
  destination: string;

  @IsOptional()
  @IsString()
  destinationCountry?: string;

  @IsOptional()
  @IsString()
  departureCity?: string;

  @IsDate()
  @Type(() => Date)
  startDate: Date;

  @IsDate()
  @Type(() => Date)
  endDate: Date;

  @IsOptional()
  @IsBoolean()
  isFlexibleDates?: boolean;

  @IsOptional()
  @IsNumber()
  budgetMin?: number;

  @IsOptional()
  @IsNumber()
  budgetMax?: number;

  @IsOptional()
  @IsString()
  budgetNotes?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  travelerCount?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TravelerDto)
  travelers?: TravelerDto[];

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateTripDto extends CreateTripDto {
  @IsOptional()
  @IsEnum(TripStatus)
  status?: TripStatus;
}

export class TripQueryDto {
  @IsOptional()
  @IsArray()
  @IsEnum(TripStatus, { each: true })
  status?: TripStatus[];

  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  @IsInt()
  limit?: number;
}

export class AssignTripDto {
  @IsOptional()
  @IsString()
  managerId?: string; // If not provided, assigns to current user
}

// ============================================================================
// PROPOSAL DTOs
// ============================================================================

export class ProposalOptionDto {
  @IsInt()
  @Min(0)
  index: number;

  @IsString()
  title: string;

  @IsString()
  details: string;

  @IsNumber()
  price: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  pros?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  cons?: string[];

  @IsOptional()
  @IsString()
  bookingReference?: string;

  @IsOptional()
  @IsString()
  expiresAt?: string;
}

export class CreateProposalDto {
  @IsString()
  title: string;

  @IsEnum(ItineraryItemType)
  category: ItineraryItemType;

  @IsOptional()
  @IsString()
  description?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ProposalOptionDto)
  options: ProposalOptionDto[];

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  expiresAt?: Date;
}

export class UpdateProposalDto extends CreateProposalDto {}

export class SelectProposalOptionDto {
  @IsInt()
  @Min(0)
  optionIndex: number;
}

// ============================================================================
// ITINERARY DTOs
// ============================================================================

export class ItemDocumentDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  fileAssetId?: string;

  @IsOptional()
  @IsString()
  url?: string;
}

export class CreateItineraryItemDto {
  @IsEnum(ItineraryItemType)
  type: ItineraryItemType;

  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsDate()
  @Type(() => Date)
  startDateTime: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  endDateTime?: Date;

  @IsOptional()
  @IsString()
  timezone?: string;

  @IsOptional()
  @IsString()
  startLocation?: string;

  @IsOptional()
  @IsString()
  endLocation?: string;

  @IsOptional()
  @IsString()
  confirmationNumber?: string;

  @IsOptional()
  @IsString()
  bookingReference?: string;

  @IsOptional()
  @IsString()
  providerName?: string;

  @IsNumber()
  cost: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsBoolean()
  paidByHaven?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ItemDocumentDto)
  documents?: ItemDocumentDto[];

  @IsOptional()
  @IsInt()
  sortOrder?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateItineraryItemDto extends CreateItineraryItemDto {}

export class LinkTransactionDto {
  @IsString()
  transactionId: string;
}

export class AttachDocumentDto {
  @IsString()
  name: string;

  @IsString()
  fileAssetId: string;
}

// ============================================================================
// HOUSE PROTOCOL DTOs
// ============================================================================

export class CreateProtocolItemDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsInt()
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isRequired?: boolean;
}

export class CompleteProtocolItemDto {
  @IsOptional()
  @IsString()
  proofPhotoUrl?: string;

  @IsOptional()
  @IsString()
  proofFileAssetId?: string;

  @IsOptional()
  @IsString()
  proofNotes?: string;
}

export class AssignProtocolDto {
  @IsOptional()
  @IsString()
  assignedToUserId?: string; // If not provided, assigns to current user
}

export class ProtocolQueryDto {
  @IsOptional()
  @IsArray()
  @IsEnum(HouseProtocolStatus, { each: true })
  status?: HouseProtocolStatus[];

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  scheduledBefore?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  scheduledAfter?: Date;
}
