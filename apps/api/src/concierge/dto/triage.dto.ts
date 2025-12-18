import { IsString, IsOptional, IsEnum, IsArray, ValidateNested, IsBoolean, IsNumber } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { InboundChannel, RequestCategory, TriageStatus, TriagePriority } from '@prisma/client';

// =========================================================================
// WEBHOOK DTOs
// =========================================================================

export class EmailWebhookDto {
  @ApiProperty({ description: 'Email message ID from provider' })
  @IsString()
  messageId: string;

  @ApiProperty({ description: 'Sender email address' })
  @IsString()
  from: string;

  @ApiPropertyOptional({ description: 'Sender display name' })
  @IsOptional()
  @IsString()
  fromName?: string;

  @ApiProperty({ description: 'Recipient email address' })
  @IsString()
  to: string;

  @ApiPropertyOptional({ description: 'Email subject' })
  @IsOptional()
  @IsString()
  subject?: string;

  @ApiProperty({ description: 'Plain text body' })
  @IsString()
  textBody: string;

  @ApiPropertyOptional({ description: 'HTML body' })
  @IsOptional()
  @IsString()
  htmlBody?: string;

  @ApiPropertyOptional({ description: 'Attachments metadata' })
  @IsOptional()
  @IsArray()
  attachments?: EmailAttachmentDto[];

  @ApiPropertyOptional({ description: 'Raw headers' })
  @IsOptional()
  headers?: Record<string, string>;
}

export class EmailAttachmentDto {
  @ApiProperty({ description: 'Attachment filename' })
  @IsString()
  filename: string;

  @ApiProperty({ description: 'Content type (MIME)' })
  @IsString()
  contentType: string;

  @ApiPropertyOptional({ description: 'File size in bytes' })
  @IsOptional()
  @IsNumber()
  size?: number;

  @ApiPropertyOptional({ description: 'Base64 encoded content' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ description: 'URL to download attachment' })
  @IsOptional()
  @IsString()
  url?: string;
}

export class SmsWebhookDto {
  @ApiProperty({ description: 'SMS message SID from Twilio' })
  @IsString()
  MessageSid: string;

  @ApiProperty({ description: 'Sender phone number' })
  @IsString()
  From: string;

  @ApiProperty({ description: 'Recipient phone number' })
  @IsString()
  To: string;

  @ApiProperty({ description: 'Message body' })
  @IsString()
  Body: string;

  @ApiPropertyOptional({ description: 'Number of media attachments' })
  @IsOptional()
  @IsString()
  NumMedia?: string;

  @ApiPropertyOptional({ description: 'Media URLs (Twilio sends MediaUrl0, MediaUrl1, etc.)' })
  @IsOptional()
  mediaUrls?: string[];
}

// =========================================================================
// CHAT DTOs
// =========================================================================

export class SendChatMessageDto {
  @ApiPropertyOptional({ description: 'Thread ID (omit to start new thread)' })
  @IsOptional()
  @IsString()
  threadId?: string;

  @ApiProperty({ description: 'Message content' })
  @IsString()
  message: string;

  @ApiPropertyOptional({ description: 'Attachment URLs' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  attachments?: string[];
}

export class ChatMessageResponseDto {
  threadId: string;
  messageId: string;
  response: string;
  createdRequest?: {
    id: string;
    category: RequestCategory;
    title: string;
  };
}

// =========================================================================
// TRIAGE MANAGEMENT DTOs
// =========================================================================

export class TriageListQueryDto {
  @ApiPropertyOptional({ enum: TriageStatus, description: 'Filter by status' })
  @IsOptional()
  @IsEnum(TriageStatus)
  status?: TriageStatus;

  @ApiPropertyOptional({ enum: RequestCategory, description: 'Filter by category' })
  @IsOptional()
  @IsEnum(RequestCategory)
  category?: RequestCategory;

  @ApiPropertyOptional({ enum: TriagePriority, description: 'Filter by priority' })
  @IsOptional()
  @IsEnum(TriagePriority)
  priority?: TriagePriority;

  @ApiPropertyOptional({ description: 'Filter by household ID' })
  @IsOptional()
  @IsString()
  householdId?: string;

  @ApiPropertyOptional({ description: 'Include resolved requests', default: false })
  @IsOptional()
  @IsBoolean()
  includeResolved?: boolean;

  @ApiPropertyOptional({ description: 'Number of items per page', default: 20 })
  @IsOptional()
  @IsNumber()
  limit?: number;

  @ApiPropertyOptional({ description: 'Offset for pagination' })
  @IsOptional()
  @IsNumber()
  offset?: number;
}

export class ApproveTriageActionDto {
  @ApiProperty({ description: 'Inbound request ID' })
  @IsString()
  requestId: string;

  @ApiProperty({ description: 'Suggestion ID to execute' })
  @IsString()
  suggestionId: string;

  @ApiPropertyOptional({ description: 'Override data for the action' })
  @IsOptional()
  overrideData?: Record<string, unknown>;
}

export class RejectTriageRequestDto {
  @ApiProperty({ description: 'Inbound request ID' })
  @IsString()
  requestId: string;

  @ApiProperty({ description: 'Reason for rejection' })
  @IsString()
  reason: string;
}

export class ManualClassifyDto {
  @ApiProperty({ description: 'Inbound request ID' })
  @IsString()
  requestId: string;

  @ApiProperty({ enum: RequestCategory, description: 'Manual category assignment' })
  @IsEnum(RequestCategory)
  category: RequestCategory;

  @ApiProperty({ enum: TriagePriority, description: 'Manual priority assignment' })
  @IsEnum(TriagePriority)
  priority: TriagePriority;

  @ApiPropertyOptional({ description: 'Notes for manual classification' })
  @IsOptional()
  @IsString()
  notes?: string;
}

// =========================================================================
// RESPONSE DTOs
// =========================================================================

export class InboundRequestResponseDto {
  id: string;
  channel: InboundChannel;
  category: RequestCategory;
  priority: TriagePriority;
  status: TriageStatus;
  senderEmail: string | null;
  senderPhone: string | null;
  senderName: string | null;
  subject: string | null;
  body: string;
  summary: string | null;
  aiConfidence: number | null;
  aiReasoning: string | null;
  householdId: string | null;
  household: {
    id: string;
    name: string;
  } | null;
  suggestions: TriageSuggestionDto[];
  attachments: InboundAttachmentDto[];
  resolvedAction: string | null;
  resolvedEntityId: string | null;
  resolvedAt: Date | null;
  resolvedByUserId: string | null;
  createdAt: Date;
}

export class TriageSuggestionDto {
  id: string;
  actionType: string;
  title: string;
  description: string | null;
  confidence: number;
  actionData: Record<string, unknown>;
  isApproved: boolean;
  isRejected: boolean;
}

export class InboundAttachmentDto {
  id: string;
  filename: string;
  contentType: string;
  sizeBytes: number | null;
  extractedText: string | null;
  documentType: string | null;
}

export class TriageStatsDto {
  total: number;
  byStatus: Record<TriageStatus, number>;
  byCategory: Record<RequestCategory, number>;
  byPriority: Record<TriagePriority, number>;
  avgProcessingTime: number | null;
  todayCount: number;
  pendingReview: number;
}

// =========================================================================
// EXECUTION RESULT DTOs
// =========================================================================

export class ExecutionResultDto {
  success: boolean;
  actionType: string;
  entityType: string | null;
  entityId: string | null;
  message: string;
  error?: string;
}
