import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsEmail, IsEnum, IsOptional, MaxLength } from 'class-validator';
import { HouseholdRole } from '@prisma/client';

export class CreateInvitationDto {
  @ApiProperty({ description: 'Email of the person to invite' })
  @IsEmail()
  email: string;

  @ApiPropertyOptional({ description: 'Household ID (defaults to user primary household)' })
  @IsOptional()
  @IsString()
  householdId?: string;

  @ApiPropertyOptional({
    enum: HouseholdRole,
    description: 'Role to assign to the invitee',
    default: HouseholdRole.MEMBER,
  })
  @IsOptional()
  @IsEnum(HouseholdRole)
  role?: HouseholdRole;

  @ApiPropertyOptional({ description: 'Personal message to include in the invitation' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}

export class AcceptInvitationDto {
  @ApiProperty({ description: 'Invitation token' })
  @IsString()
  token: string;
}

export class ResendInvitationDto {
  @ApiProperty({ description: 'Invitation ID to resend' })
  @IsString()
  invitationId: string;
}

export class InvitationResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  householdId: string;

  @ApiProperty()
  email: string;

  @ApiProperty({ enum: HouseholdRole })
  role: HouseholdRole;

  @ApiProperty()
  token: string;

  @ApiPropertyOptional()
  acceptedAt?: Date | null;

  @ApiProperty()
  expiresAt: Date;

  @ApiProperty()
  createdAt: Date;

  @ApiPropertyOptional()
  household?: {
    id: string;
    name: string;
  };

  @ApiPropertyOptional()
  invitedBy?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  };

  @ApiProperty()
  isExpired: boolean;

  @ApiProperty()
  isAccepted: boolean;
}

export class PendingInvitationsDto {
  @ApiProperty({ type: [InvitationResponseDto] })
  sent: InvitationResponseDto[];

  @ApiProperty({ type: [InvitationResponseDto] })
  received: InvitationResponseDto[];
}
