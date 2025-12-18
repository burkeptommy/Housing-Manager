import { Controller, Post, Get, Patch, Body, Param, Query, UseGuards, Headers, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { ConciergeService } from './concierge.service';
import {
  CreateConciergeRequestDto,
  HandymanCheckInDto,
  HandymanCheckOutDto,
  AssignHandymanDto,
  HouseholdProfitQueryDto,
  RejectRequestDto,
  EmailWebhookDto,
  SmsWebhookDto,
  SendChatMessageDto,
  TriageListQueryDto,
  ApproveTriageActionDto,
  RejectTriageRequestDto,
  ManualClassifyDto,
} from './dto';
import { FirebaseAuthGuard, AuthPayload } from '../firebase/firebase-auth.guard';
import { CurrentUser } from '../firebase/current-user.decorator';
import { TriageService } from './services/triage.service';
import { ExecutionPipelineService } from './services/execution-pipeline.service';

@ApiTags('Concierge')
@Controller('concierge')
export class ConciergeController {
  constructor(
    private readonly conciergeService: ConciergeService,
    private readonly triageService: TriageService,
    private readonly executionPipeline: ExecutionPipelineService,
  ) {}

  // =========================================================================
  // WEBHOOK ENDPOINTS (No Auth - Protected by API Key)
  // =========================================================================

  @Post('webhooks/email')
  @HttpCode(200)
  @ApiOperation({ summary: 'Email webhook endpoint (SendGrid/Mailgun)' })
  @ApiHeader({ name: 'x-webhook-secret', description: 'Webhook authentication secret' })
  async handleEmailWebhook(
    @Body() dto: EmailWebhookDto,
    @Headers('x-webhook-secret') webhookSecret: string,
  ) {
    // TODO: Validate webhook secret against environment variable
    const result = await this.triageService.processEmailWebhook(dto);
    return { success: true, requestId: result.id };
  }

  @Post('webhooks/sms')
  @HttpCode(200)
  @ApiOperation({ summary: 'SMS webhook endpoint (Twilio)' })
  async handleSmsWebhook(@Body() dto: SmsWebhookDto) {
    // Twilio sends form-urlencoded data
    // Parse media URLs from Twilio's format (MediaUrl0, MediaUrl1, etc.)
    const mediaUrls: string[] = [];
    const numMedia = parseInt(dto.NumMedia || '0', 10);
    for (let i = 0; i < numMedia; i++) {
      const mediaUrl = (dto as unknown as Record<string, string>)[`MediaUrl${i}`];
      if (mediaUrl) {
        mediaUrls.push(mediaUrl);
      }
    }
    dto.mediaUrls = mediaUrls;

    const result = await this.triageService.processSmsWebhook(dto);

    // Twilio expects TwiML response for SMS
    return `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Message>Got it! Your request has been received and is being processed.</Message>
</Response>`;
  }

  // =========================================================================
  // CHAT ENDPOINTS (Authenticated)
  // =========================================================================

  @Post('households/:householdId/chat')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Send a chat message to the AI concierge' })
  async sendChatMessage(
    @CurrentUser() user: AuthPayload,
    @Param('householdId') householdId: string,
    @Body() dto: SendChatMessageDto,
  ) {
    return this.triageService.processChatMessage(user.userId, householdId, dto);
  }

  // =========================================================================
  // TRIAGE MANAGEMENT ENDPOINTS (Manager/Admin)
  // =========================================================================

  @Get('triage')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List inbound requests for triage' })
  async listTriageRequests(@Query() query: TriageListQueryDto) {
    return this.triageService.listRequests(query);
  }

  @Get('triage/stats')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get triage statistics' })
  async getTriageStats() {
    return this.triageService.getStats();
  }

  @Get('triage/:id')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get a single inbound request' })
  async getTriageRequest(@Param('id') id: string) {
    return this.triageService.getRequest(id);
  }

  @Post('triage/approve')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Approve and execute a triage suggestion' })
  async approveTriageAction(
    @CurrentUser() user: AuthPayload,
    @Body() dto: ApproveTriageActionDto,
  ) {
    // Get the request and suggestion to build execution context
    const request = await this.triageService.getRequest(dto.requestId);
    const suggestion = request.suggestions.find((s) => s.id === dto.suggestionId);

    if (!suggestion) {
      throw new Error('Suggestion not found');
    }

    if (!request.householdId) {
      throw new Error('Request must be linked to a household before execution');
    }

    return this.executionPipeline.executeAction({
      requestId: dto.requestId,
      suggestionId: dto.suggestionId,
      userId: user.userId,
      householdId: request.householdId,
      actionType: suggestion.actionType,
      actionData: suggestion.actionData,
      overrideData: dto.overrideData,
    });
  }

  @Post('triage/reject')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Reject a triage request' })
  async rejectTriageRequest(
    @CurrentUser() user: AuthPayload,
    @Body() dto: RejectTriageRequestDto,
  ) {
    await this.executionPipeline.rejectRequest(dto.requestId, user.userId, dto.reason);
    return { success: true };
  }

  @Patch('triage/:id/classify')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Manually classify a request' })
  async manualClassify(
    @Param('id') id: string,
    @Body() dto: ManualClassifyDto,
  ) {
    return this.triageService.manualClassify(id, dto.category, dto.priority, dto.notes);
  }

  @Patch('triage/:id/link-household')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Link request to a household' })
  async linkToHousehold(
    @Param('id') id: string,
    @Body('householdId') householdId: string,
  ) {
    return this.triageService.linkToHousehold(id, householdId);
  }

  // =========================================================================
  // HOMEOWNER ENDPOINTS
  // =========================================================================

  @Post('households/:householdId/requests')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a concierge request (homeowner)' })
  async createConciergeRequest(
    @CurrentUser() user: AuthPayload,
    @Param('householdId') householdId: string,
    @Body() dto: CreateConciergeRequestDto,
  ) {
    return this.conciergeService.createConciergeRequest(user.userId, householdId, dto);
  }

  @Get('households/:householdId/requests')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get concierge requests for household' })
  async getHouseholdRequests(
    @CurrentUser() user: AuthPayload,
    @Param('householdId') householdId: string,
  ) {
    return this.conciergeService.getHouseholdConciergeRequests(user.userId, householdId);
  }

  // =========================================================================
  // HANDYMAN ENDPOINTS
  // =========================================================================

  @Get('handyman/dashboard')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get handyman dashboard' })
  async getHandymanDashboard(@CurrentUser() user: AuthPayload) {
    return this.conciergeService.getHandymanDashboard(user.userId);
  }

  @Post('handyman/check-in')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Handyman check-in with geolocation' })
  async handymanCheckIn(
    @CurrentUser() user: AuthPayload,
    @Body() dto: HandymanCheckInDto,
  ) {
    await this.conciergeService.handymanCheckIn(user.userId, dto);
    return { success: true };
  }

  @Post('handyman/check-out')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Handyman check-out with completion details' })
  async handymanCheckOut(
    @CurrentUser() user: AuthPayload,
    @Body() dto: HandymanCheckOutDto,
  ) {
    await this.conciergeService.handymanCheckOut(user.userId, dto);
    return { success: true };
  }

  @Post('handyman/reject')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Handyman rejects assigned task' })
  async handymanRejectRequest(
    @CurrentUser() user: AuthPayload,
    @Body() dto: RejectRequestDto,
  ) {
    await this.conciergeService.rejectRequest(user.userId, dto);
    return { success: true };
  }

  // =========================================================================
  // MANAGER ENDPOINTS
  // =========================================================================

  @Post('work-orders/assign')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Assign handyman to work order (manager)' })
  async assignHandyman(
    @CurrentUser() user: AuthPayload,
    @Body() dto: AssignHandymanDto,
  ) {
    await this.conciergeService.assignHandyman(user.userId, dto);
    return { success: true };
  }

  @Post('households/:householdId/assign-handyman/:handymanId')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Assign handyman to household (manager)' })
  async assignHandymanToHousehold(
    @CurrentUser() user: AuthPayload,
    @Param('householdId') householdId: string,
    @Param('handymanId') handymanId: string,
  ) {
    await this.conciergeService.assignHandymanToHousehold(user.userId, householdId, handymanId);
    return { success: true };
  }

  @Get('households/:householdId/profit')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get profit report for household (manager)' })
  async getHouseholdProfit(
    @Param('householdId') householdId: string,
    @Query() query: HouseholdProfitQueryDto,
  ) {
    return this.conciergeService.getHouseholdProfit(householdId, query);
  }

  @Get('handymen')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get list of all handymen (for assignment)' })
  async getHandymen() {
    return this.conciergeService.getHandymen();
  }
}
