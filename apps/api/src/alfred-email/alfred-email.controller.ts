import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Delete,
  Query,
  UseGuards,
  Logger,
  HttpCode,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
import { CurrentUser } from '../firebase/current-user.decorator';
import { AuthPayload } from '../firebase';
import { AlfredEmailService } from './alfred-email.service';

@Controller('alfred')
export class AlfredEmailController {
  private readonly logger = new Logger(AlfredEmailController.name);

  constructor(private readonly alfredEmailService: AlfredEmailService) {}

  /**
   * SendGrid Inbound Parse Webhook
   * This endpoint receives all emails sent to {code}@alfred.havenhome.dev
   * NO AUTH - SendGrid calls this directly
   */
  @Post('inbound-email')
  @HttpCode(200)
  async handleInboundEmail(@Body() payload: Record<string, unknown>) {
    this.logger.log('Received inbound email webhook');

    try {
      // Extract email data from SendGrid payload
      const emailData = {
        to: payload.to as string,
        from: payload.from as string,
        subject: payload.subject as string,
        text: payload.text as string | undefined,
        html: payload.html as string | undefined,
        envelope: JSON.parse((payload.envelope as string) || '{}'),
        attachments: payload.attachments
          ? JSON.parse(payload.attachments as string)
          : [],
        messageId:
          (payload['Message-Id'] as string) ||
          ((payload.headers as Record<string, string>)?.['Message-Id']),
      };

      // Process the email
      const result = await this.alfredEmailService.processInboundEmail(emailData);

      return { success: true, ...result };
    } catch (error) {
      this.logger.error(
        `Failed to process inbound email: ${error.message}`,
        error.stack,
      );
      // Return 200 anyway to prevent SendGrid retries for bad emails
      return { success: false, error: error.message };
    }
  }

  /**
   * Get household's Alfred email address
   */
  @Get('email-address')
  @UseGuards(FirebaseAuthGuard)
  async getAlfredEmailAddress(@CurrentUser() user: AuthPayload) {
    return this.alfredEmailService.getAlfredEmailAddress(user);
  }

  /**
   * Get authorized emails for household
   */
  @Get('authorized-emails')
  @UseGuards(FirebaseAuthGuard)
  async getAuthorizedEmails(@CurrentUser() user: AuthPayload) {
    return this.alfredEmailService.getAuthorizedEmails(user);
  }

  /**
   * Add an authorized email
   */
  @Post('authorized-emails')
  @UseGuards(FirebaseAuthGuard)
  async addAuthorizedEmail(
    @CurrentUser() user: AuthPayload,
    @Body() body: { email: string; label?: string },
  ) {
    return this.alfredEmailService.addAuthorizedEmail(
      user,
      body.email,
      body.label,
    );
  }

  /**
   * Remove an authorized email
   */
  @Delete('authorized-emails/:id')
  @UseGuards(FirebaseAuthGuard)
  async removeAuthorizedEmail(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
  ) {
    return this.alfredEmailService.removeAuthorizedEmail(user, id);
  }

  /**
   * Get email cases history
   */
  @Get('cases')
  @UseGuards(FirebaseAuthGuard)
  async getCases(
    @CurrentUser() user: AuthPayload,
    @Query('status') status?: string,
  ) {
    return this.alfredEmailService.getCases(user, status);
  }

  /**
   * Get single case with details
   */
  @Get('cases/:id')
  @UseGuards(FirebaseAuthGuard)
  async getCase(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
  ) {
    return this.alfredEmailService.getCase(user, id);
  }

  /**
   * Execute selected action(s) from email case suggestions.
   * Used in the "always ask intent" flow where Alfred suggests actions
   * and the user picks which ones to execute.
   */
  @Post('cases/:id/execute')
  @UseGuards(FirebaseAuthGuard)
  async executeAction(
    @CurrentUser() user: AuthPayload,
    @Param('id') caseId: string,
    @Body() body: { actionTypes: string[]; customRequest?: string },
  ) {
    return this.alfredEmailService.executeSelectedActions(user, caseId, body);
  }

  /**
   * Answer a pending question from Alfred
   */
  @Post('cases/:id/answer')
  @UseGuards(FirebaseAuthGuard)
  async answerQuestion(
    @CurrentUser() user: AuthPayload,
    @Param('id') caseId: string,
    @Body() body: { answer: string; selectedOption?: string },
  ) {
    return this.alfredEmailService.answerQuestion(user, caseId, body);
  }

  /**
   * Archive a case
   */
  @Post('cases/:id/archive')
  @UseGuards(FirebaseAuthGuard)
  async archiveCase(
    @CurrentUser() user: AuthPayload,
    @Param('id') caseId: string,
  ) {
    return this.alfredEmailService.archiveCase(user, caseId);
  }
}
