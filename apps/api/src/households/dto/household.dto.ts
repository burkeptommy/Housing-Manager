import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { HouseholdRole, HouseholdMemberStatus, PropertyType } from '@prisma/client';
import {
  IsString,
  IsOptional,
  IsNotEmpty,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateHouseholdDto {
  @ApiProperty({ description: 'Name of the household', example: 'Beach House' })
  @IsString()
  @IsNotEmpty()
  @MinLength(1)
  @MaxLength(100)
  name: string;

  @ApiPropertyOptional({ description: 'Description of the household' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}

export class UpdateHouseholdDto {
  @ApiPropertyOptional({ description: 'Name of the household' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name?: string;

  @ApiPropertyOptional({ description: 'Description of the household' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}

export class HouseholdMemberDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  userId: string;

  @ApiProperty()
  email: string;

  @ApiProperty()
  firstName: string;

  @ApiProperty()
  lastName: string;

  @ApiProperty({ enum: HouseholdRole })
  role: HouseholdRole;

  @ApiProperty({ enum: HouseholdMemberStatus })
  status: HouseholdMemberStatus;

  @ApiPropertyOptional()
  joinedAt: Date | null;
}

export class HomeProfileSummaryDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ enum: PropertyType })
  propertyType: PropertyType;

  @ApiProperty()
  addressLine1: string;

  @ApiPropertyOptional()
  city: string;

  @ApiPropertyOptional()
  state: string;

  @ApiPropertyOptional()
  postalCode: string;
}

export class VendorSummaryDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  name: string;

  @ApiPropertyOptional()
  phone: string | null;

  @ApiPropertyOptional()
  email: string | null;

  @ApiPropertyOptional()
  categoryName: string | null;

  @ApiProperty()
  isFavorite: boolean;
}

export class HouseholdDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  name: string;

  @ApiPropertyOptional()
  description: string | null;

  @ApiProperty()
  ownerId: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

export class HouseholdDetailDto extends HouseholdDto {
  @ApiPropertyOptional({ type: HomeProfileSummaryDto })
  homeProfile: HomeProfileSummaryDto | null;

  @ApiProperty({ type: [HouseholdMemberDto] })
  members: HouseholdMemberDto[];

  @ApiProperty({ type: [VendorSummaryDto] })
  preferredVendors: VendorSummaryDto[];
}

export class HouseholdListItemDto extends HouseholdDto {
  @ApiProperty({ enum: HouseholdRole })
  userRole: HouseholdRole;

  @ApiPropertyOptional({ type: HomeProfileSummaryDto })
  homeProfile: HomeProfileSummaryDto | null;
}
