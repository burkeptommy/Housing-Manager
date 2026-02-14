import { IsEmail, IsString, IsOptional, ValidateNested, IsNumber, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

class AddressDto {
  @IsString()
  addressLine1: string;

  @IsOptional()
  @IsString()
  addressLine2?: string;

  @IsString()
  city: string;

  @IsString()
  state: string;

  @IsString()
  zipCode: string;
}

/**
 * Property details captured during onboarding
 * Accepts all fields returned by property data API
 */
class PropertyDetailsDto {
  @IsOptional()
  @IsNumber()
  bedrooms?: number | null;

  @IsOptional()
  @IsNumber()
  bathrooms?: number | null;

  @IsOptional()
  @IsNumber()
  bathsFull?: number | null;

  @IsOptional()
  @IsNumber()
  bathsHalf?: number | null;

  @IsOptional()
  @IsNumber()
  squareFeet?: number | null;

  @IsOptional()
  @IsNumber()
  yearBuilt?: number | null;

  @IsOptional()
  @IsNumber()
  lotSizeAcres?: number | null;

  @IsOptional()
  @IsNumber()
  lotSizeSquareFeet?: number | null;

  @IsOptional()
  @IsNumber()
  stories?: number | null;

  @IsOptional()
  @IsString()
  heatingType?: string | null;

  @IsOptional()
  @IsString()
  heatingFuel?: string | null;

  @IsOptional()
  @IsString()
  coolingType?: string | null;

  @IsOptional()
  @IsString()
  waterType?: string | null;

  @IsOptional()
  @IsString()
  sewerType?: string | null;

  @IsOptional()
  @IsNumber()
  garageSpaces?: number | null;

  @IsOptional()
  @IsBoolean()
  pool?: boolean | null;

  @IsOptional()
  @IsString()
  propertyType?: string | null;

  @IsOptional()
  @IsString()
  propertySubType?: string | null;

  @IsOptional()
  @IsString()
  constructionType?: string | null;

  @IsOptional()
  @IsString()
  foundationType?: string | null;

  @IsOptional()
  @IsString()
  roofType?: string | null;

  @IsOptional()
  @IsString()
  roofMaterial?: string | null;

  @IsOptional()
  @IsString()
  exteriorWalls?: string | null;

  @IsOptional()
  @IsNumber()
  fireplaces?: number | null;

  @IsOptional()
  @IsString()
  garage?: string | null;

  @IsOptional()
  @IsString()
  poolType?: string | null;

  @IsOptional()
  @IsNumber()
  totalRooms?: number | null;

  @IsOptional()
  @IsString()
  basementType?: string | null;

  @IsOptional()
  @IsNumber()
  assessedValue?: number | null;

  @IsOptional()
  @IsNumber()
  marketValue?: number | null;

  @IsOptional()
  @IsNumber()
  taxAmount?: number | null;

  @IsOptional()
  @IsNumber()
  lastSalePrice?: number | null;

  @IsOptional()
  @IsString()
  lastSaleDate?: string | null;

  @IsOptional()
  @IsString()
  verifiedAddress?: string | null;

  @IsOptional()
  @IsNumber()
  latitude?: number | null;

  @IsOptional()
  @IsNumber()
  longitude?: number | null;
}

/**
 * DTO for social sign-in registration (Apple/Google)
 * No password required - Firebase handles authentication
 */
export class RegisterSocialDto {
  @IsEmail()
  email: string;

  @IsString()
  firstName: string;

  @IsString()
  lastName: string;

  @IsString()
  @IsOptional()
  firebaseUid?: string;

  @ValidateNested()
  @Type(() => AddressDto)
  address: AddressDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => PropertyDetailsDto)
  propertyDetails?: PropertyDetailsDto | null;
}
