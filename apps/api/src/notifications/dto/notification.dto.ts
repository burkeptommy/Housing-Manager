import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class EmailNotificationDto {
  @ApiProperty({ description: 'Recipient email address' })
  to: string;

  @ApiProperty({ description: 'Email subject' })
  subject: string;

  @ApiProperty({ description: 'Email body (HTML or plain text)' })
  body: string;

  @ApiPropertyOptional({ description: 'Whether body is HTML', default: false })
  isHtml?: boolean;

  @ApiPropertyOptional({ description: 'Template ID for email service' })
  templateId?: string;

  @ApiPropertyOptional({ description: 'Template variables' })
  templateVars?: Record<string, unknown>;
}

export class SmsNotificationDto {
  @ApiProperty({ description: 'Recipient phone number (E.164 format)' })
  to: string;

  @ApiProperty({ description: 'SMS message content' })
  message: string;
}

export class PushNotificationDto {
  @ApiProperty({ description: 'User ID to send notification to' })
  userId: string;

  @ApiProperty({ description: 'Notification title' })
  title: string;

  @ApiProperty({ description: 'Notification body' })
  body: string;

  @ApiPropertyOptional({ description: 'Additional data payload' })
  data?: Record<string, unknown>;

  @ApiPropertyOptional({ description: 'Deep link URL' })
  link?: string;

  @ApiPropertyOptional({ description: 'Badge count' })
  badge?: number;
}

export class NotificationResult {
  @ApiProperty({ description: 'Whether notification was sent successfully' })
  success: boolean;

  @ApiPropertyOptional({ description: 'Message ID from provider' })
  messageId?: string;

  @ApiPropertyOptional({ description: 'Error message if failed' })
  error?: string;
}
