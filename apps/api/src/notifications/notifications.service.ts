import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import {
  EmailNotificationDto,
  SmsNotificationDto,
  PushNotificationDto,
  NotificationResult,
} from './dto';

/**
 * NotificationsService - Abstraction for sending notifications
 *
 * Current implementation: Console logging (for development)
 * Future implementations:
 * - Email: SendGrid (@sendgrid/mail)
 * - SMS: Twilio (twilio)
 * - Push: Firebase Cloud Messaging (firebase-admin)
 *
 * To switch providers, either:
 * 1. Modify this service to use real providers
 * 2. Create separate provider services and inject them
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly configService: ConfigService) {}

  /**
   * Send an email notification
   *
   * Future implementation with SendGrid:
   * ```
   * import * as sgMail from '@sendgrid/mail';
   * sgMail.setApiKey(this.configService.get('SENDGRID_API_KEY'));
   * const msg = { to, from: 'noreply@haven.app', subject, html: body };
   * const [response] = await sgMail.send(msg);
   * return { success: true, messageId: response.headers['x-message-id'] };
   * ```
   */
  async sendEmail(dto: EmailNotificationDto): Promise<NotificationResult> {
    this.logger.log('=== EMAIL NOTIFICATION ===');
    this.logger.log(`To: ${dto.to}`);
    this.logger.log(`Subject: ${dto.subject}`);
    this.logger.log(`Body: ${dto.body.substring(0, 200)}${dto.body.length > 200 ? '...' : ''}`);
    if (dto.templateId) {
      this.logger.log(`Template ID: ${dto.templateId}`);
      this.logger.log(`Template Vars: ${JSON.stringify(dto.templateVars)}`);
    }
    this.logger.log('=========================');

    // Simulate async operation
    await this.simulateDelay();

    return {
      success: true,
      messageId: `email_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };
  }

  /**
   * Send an SMS notification
   *
   * Future implementation with Twilio:
   * ```
   * import { Twilio } from 'twilio';
   * const client = new Twilio(
   *   this.configService.get('TWILIO_ACCOUNT_SID'),
   *   this.configService.get('TWILIO_AUTH_TOKEN')
   * );
   * const message = await client.messages.create({
   *   body: dto.message,
   *   to: dto.to,
   *   from: this.configService.get('TWILIO_PHONE_NUMBER'),
   * });
   * return { success: true, messageId: message.sid };
   * ```
   */
  async sendSMS(dto: SmsNotificationDto): Promise<NotificationResult> {
    this.logger.log('=== SMS NOTIFICATION ===');
    this.logger.log(`To: ${dto.to}`);
    this.logger.log(`Message: ${dto.message}`);
    this.logger.log('========================');

    // Simulate async operation
    await this.simulateDelay();

    return {
      success: true,
      messageId: `sms_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };
  }

  /**
   * Send a push notification
   *
   * Future implementation with Firebase Cloud Messaging:
   * ```
   * import * as admin from 'firebase-admin';
   * // Get user's FCM tokens from database
   * const tokens = await this.getUserDeviceTokens(dto.userId);
   * const message = {
   *   notification: { title: dto.title, body: dto.body },
   *   data: dto.data,
   *   tokens,
   * };
   * const response = await admin.messaging().sendMulticast(message);
   * return { success: response.successCount > 0, messageId: response.responses[0]?.messageId };
   * ```
   */
  async sendPush(dto: PushNotificationDto): Promise<NotificationResult> {
    this.logger.log('=== PUSH NOTIFICATION ===');
    this.logger.log(`User ID: ${dto.userId}`);
    this.logger.log(`Title: ${dto.title}`);
    this.logger.log(`Body: ${dto.body}`);
    if (dto.data) {
      this.logger.log(`Data: ${JSON.stringify(dto.data)}`);
    }
    if (dto.link) {
      this.logger.log(`Link: ${dto.link}`);
    }
    this.logger.log('=========================');

    // Simulate async operation
    await this.simulateDelay();

    return {
      success: true,
      messageId: `push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };
  }

  /**
   * Send notification through multiple channels
   */
  async sendMultiChannel(params: {
    email?: EmailNotificationDto;
    sms?: SmsNotificationDto;
    push?: PushNotificationDto;
  }): Promise<{
    email?: NotificationResult;
    sms?: NotificationResult;
    push?: NotificationResult;
  }> {
    const results: {
      email?: NotificationResult;
      sms?: NotificationResult;
      push?: NotificationResult;
    } = {};

    const promises: Promise<void>[] = [];

    if (params.email) {
      promises.push(
        this.sendEmail(params.email).then((r) => {
          results.email = r;
        }),
      );
    }

    if (params.sms) {
      promises.push(
        this.sendSMS(params.sms).then((r) => {
          results.sms = r;
        }),
      );
    }

    if (params.push) {
      promises.push(
        this.sendPush(params.push).then((r) => {
          results.push = r;
        }),
      );
    }

    await Promise.all(promises);

    return results;
  }

  private simulateDelay(): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, 100));
  }
}
