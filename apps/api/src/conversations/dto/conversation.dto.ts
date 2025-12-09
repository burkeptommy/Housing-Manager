import { IsString, IsOptional, IsEnum, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ConversationStatus } from '@prisma/client';

export class CreateConversationDto {
  @ApiPropertyOptional({ description: 'Short subject/topic of the conversation' })
  @IsOptional()
  @IsString()
  subject?: string;

  @ApiProperty({ description: 'Initial message body' })
  @IsString()
  body: string;

  @ApiPropertyOptional({ description: 'URL to an attachment' })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;
}

export class SendMessageDto {
  @ApiProperty({ description: 'Message body' })
  @IsString()
  body: string;

  @ApiPropertyOptional({ description: 'URL to an attachment' })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;
}

export class ConversationListQueryDto {
  @ApiPropertyOptional({ enum: ConversationStatus })
  @IsOptional()
  @IsEnum(ConversationStatus)
  status?: ConversationStatus;

  @ApiPropertyOptional({ description: 'Filter by updated since ISO date' })
  @IsOptional()
  @IsString()
  updatedSince?: string;
}

export class InternalConversationListQueryDto {
  @ApiPropertyOptional({ enum: ConversationStatus })
  @IsOptional()
  @IsEnum(ConversationStatus)
  status?: ConversationStatus;

  @ApiPropertyOptional({ description: 'Filter by assigned to current user' })
  @IsOptional()
  @IsBoolean()
  assignedToMe?: boolean;

  @ApiPropertyOptional({ description: 'Filter by unassigned only' })
  @IsOptional()
  @IsBoolean()
  unassigned?: boolean;
}

export class AssignConversationDto {
  @ApiProperty({ description: 'User ID of the home manager to assign' })
  @IsString()
  homeManagerUserId: string;
}

export class UpdateConversationStatusDto {
  @ApiProperty({ enum: ConversationStatus })
  @IsEnum(ConversationStatus)
  status: ConversationStatus;
}
