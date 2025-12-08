import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsEnum, IsOptional, MaxLength, IsBoolean } from 'class-validator';

export enum ChannelType {
  HOUSEHOLD = 'HOUSEHOLD',
  REQUEST = 'REQUEST',
}

export enum MessageType {
  TEXT = 'TEXT',
  SYSTEM = 'SYSTEM',
  SERVICE_UPDATE = 'SERVICE_UPDATE',
}

export class CreateMessageDto {
  @ApiProperty({ description: 'Message content' })
  @IsString()
  @MaxLength(5000)
  content: string;

  @ApiPropertyOptional({ description: 'Message type', enum: MessageType, default: MessageType.TEXT })
  @IsOptional()
  @IsEnum(MessageType)
  messageType?: MessageType;
}

export class MessageDto {
  @ApiProperty({ description: 'Message ID' })
  id: string;

  @ApiProperty({ description: 'Channel type', enum: ChannelType })
  channelType: ChannelType;

  @ApiPropertyOptional({ description: 'Household ID (for household channels)' })
  householdId: string | null;

  @ApiPropertyOptional({ description: 'Service request ID (for request channels)' })
  serviceRequestId: string | null;

  @ApiPropertyOptional({ description: 'Sender user ID' })
  senderId: string | null;

  @ApiPropertyOptional({ description: 'Vendor ID (if sent by vendor)' })
  vendorId: string | null;

  @ApiProperty({ description: 'Message content' })
  content: string;

  @ApiProperty({ description: 'Message type', enum: MessageType })
  messageType: MessageType;

  @ApiProperty({ description: 'Whether message has been read' })
  isRead: boolean;

  @ApiPropertyOptional({ description: 'When message was read' })
  readAt: Date | null;

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  updatedAt: Date;
}

export class MessageDetailDto extends MessageDto {
  @ApiPropertyOptional({ description: 'Sender details' })
  sender?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  } | null;

  @ApiPropertyOptional({ description: 'Vendor details' })
  vendor?: {
    id: string;
    companyName: string;
  } | null;
}

export class MarkMessagesReadDto {
  @ApiProperty({ description: 'Message IDs to mark as read', type: [String] })
  @IsString({ each: true })
  messageIds: string[];
}

// WebSocket event DTOs
export class JoinChannelDto {
  @ApiProperty({ description: 'Channel type', enum: ChannelType })
  @IsEnum(ChannelType)
  channelType: ChannelType;

  @ApiProperty({ description: 'Channel ID (household or service request ID)' })
  @IsString()
  channelId: string;
}

export class SendMessageDto extends CreateMessageDto {
  @ApiProperty({ description: 'Channel type', enum: ChannelType })
  @IsEnum(ChannelType)
  channelType: ChannelType;

  @ApiProperty({ description: 'Channel ID (household or service request ID)' })
  @IsString()
  channelId: string;
}
