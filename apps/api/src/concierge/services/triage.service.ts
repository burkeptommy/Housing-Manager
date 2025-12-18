import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AIClassifierService, ClassificationResult } from './ai-classifier.service';
import { InboundChannel, RequestCategory, TriageStatus, TriagePriority, Prisma } from '@prisma/client';
import {
  EmailWebhookDto,
  SmsWebhookDto,
  SendChatMessageDto,
  TriageListQueryDto,
  InboundRequestResponseDto,
  TriageStatsDto,
} from '../dto/triage.dto';

@Injectable()
export class TriageService {
  private readonly logger = new Logger(TriageService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly aiClassifier: AIClassifierService,
  ) {}

  // =========================================================================
  // INBOUND CHANNEL HANDLERS
  // =========================================================================

  /**
   * Process incoming email webhook
   */
  async processEmailWebhook(dto: EmailWebhookDto): Promise<InboundRequestResponseDto> {
    this.logger.log(`Processing email from ${dto.from}: ${dto.subject}`);

    // 1. Identify the sender and their household
    const senderInfo = await this.identifySender({ email: dto.from });

    // 2. Process attachments if any
    const attachmentSummaries: string[] = [];
    const attachmentData: Prisma.InboundAttachmentCreateWithoutInboundRequestInput[] = [];

    if (dto.attachments && dto.attachments.length > 0) {
      for (const attachment of dto.attachments) {
        const extracted = await this.aiClassifier.extractAttachmentContent({
          contentType: attachment.contentType,
          base64Content: attachment.content,
          url: attachment.url,
        });

        attachmentData.push({
          filename: attachment.filename,
          contentType: attachment.contentType,
          sizeBytes: attachment.size || null,
          storageUrl: attachment.url || null,
          extractedText: extracted.text || null,
          documentType: (extracted.analysis as Record<string, unknown>)?.documentType as string || null,
          extractedEntities: extracted.analysis as Prisma.InputJsonValue,
        });

        if (extracted.text) {
          attachmentSummaries.push(`[${attachment.filename}]: ${extracted.text.substring(0, 500)}`);
        }
      }
    }

    // 3. Classify the request
    const classification = await this.aiClassifier.classifyRequest({
      subject: dto.subject,
      body: dto.textBody,
      senderEmail: dto.from,
      senderName: dto.fromName,
      attachmentSummaries,
    });

    // 4. Create the inbound request
    const inboundRequest = await this.prisma.inboundRequest.create({
      data: {
        channel: InboundChannel.EMAIL,
        rawPayload: dto as unknown as Prisma.InputJsonValue,
        senderEmail: dto.from,
        senderName: dto.fromName,
        subject: dto.subject,
        body: dto.textBody,
        // Classification results
        category: classification.category,
        priority: classification.priority,
        summary: classification.summary,
        aiConfidence: classification.confidence,
        aiReasoning: classification.reasoning,
        extractedEntities: classification.extractedEntities as Prisma.InputJsonValue,
        // Sender identification
        householdId: senderInfo.householdId,
        userId: senderInfo.userId,
        // Status based on confidence
        status: this.determineInitialStatus(classification),
        // Attachments
        attachments: {
          create: attachmentData,
        },
        // Suggestions
        suggestions: {
          create: classification.suggestedActions.map((action) => ({
            actionType: action.actionType,
            title: action.title,
            description: action.description,
            confidence: action.confidence,
            actionData: action.actionData as Prisma.InputJsonValue,
          })),
        },
      },
      include: {
        household: { select: { id: true, name: true } },
        attachments: true,
        suggestions: true,
      },
    });

    this.logger.log(`Created inbound request ${inboundRequest.id} - Category: ${classification.category}, Priority: ${classification.priority}`);

    return this.mapToResponse(inboundRequest);
  }

  /**
   * Process incoming SMS webhook (Twilio format)
   */
  async processSmsWebhook(dto: SmsWebhookDto): Promise<InboundRequestResponseDto> {
    this.logger.log(`Processing SMS from ${dto.From}: ${dto.Body.substring(0, 50)}...`);

    // 1. Identify the sender
    const senderInfo = await this.identifySender({ phone: dto.From });

    // 2. Process media attachments if any
    const attachmentSummaries: string[] = [];
    const attachmentData: Prisma.InboundAttachmentCreateWithoutInboundRequestInput[] = [];

    const numMedia = parseInt(dto.NumMedia || '0', 10);
    if (numMedia > 0 && dto.mediaUrls) {
      for (let i = 0; i < dto.mediaUrls.length; i++) {
        const mediaUrl = dto.mediaUrls[i];
        const extracted = await this.aiClassifier.extractAttachmentContent({
          contentType: 'image/jpeg',
          url: mediaUrl,
        });

        attachmentData.push({
          filename: `media_${i}.jpg`,
          contentType: 'image/jpeg',
          storageUrl: mediaUrl,
          extractedText: extracted.text || null,
          documentType: (extracted.analysis as Record<string, unknown>)?.documentType as string || null,
          extractedEntities: extracted.analysis as Prisma.InputJsonValue,
        });

        if (extracted.text) {
          attachmentSummaries.push(`[Attachment ${i + 1}]: ${extracted.text.substring(0, 500)}`);
        }
      }
    }

    // 3. Classify the request
    const classification = await this.aiClassifier.classifyRequest({
      body: dto.Body,
      attachmentSummaries,
    });

    // 4. Create the inbound request
    const inboundRequest = await this.prisma.inboundRequest.create({
      data: {
        channel: InboundChannel.SMS,
        rawPayload: dto as unknown as Prisma.InputJsonValue,
        senderPhone: dto.From,
        body: dto.Body,
        category: classification.category,
        priority: classification.priority,
        summary: classification.summary,
        aiConfidence: classification.confidence,
        aiReasoning: classification.reasoning,
        extractedEntities: classification.extractedEntities as Prisma.InputJsonValue,
        householdId: senderInfo.householdId,
        userId: senderInfo.userId,
        status: this.determineInitialStatus(classification),
        attachments: { create: attachmentData },
        suggestions: {
          create: classification.suggestedActions.map((action) => ({
            actionType: action.actionType,
            title: action.title,
            description: action.description,
            confidence: action.confidence,
            actionData: action.actionData as Prisma.InputJsonValue,
          })),
        },
      },
      include: {
        household: { select: { id: true, name: true } },
        attachments: true,
        suggestions: true,
      },
    });

    this.logger.log(`Created inbound request ${inboundRequest.id} from SMS`);

    return this.mapToResponse(inboundRequest);
  }

  /**
   * Handle in-app chat message
   */
  async processChatMessage(
    userId: string,
    householdId: string,
    dto: SendChatMessageDto,
  ): Promise<{ response: string; threadId: string; createdRequest?: InboundRequestResponseDto }> {
    // Get or create thread
    let thread: { id: string; messages: { role: string; content: string }[] };

    if (dto.threadId) {
      const existingThread = await this.prisma.conciergeThread.findFirst({
        where: { id: dto.threadId, userId, householdId },
        include: {
          messages: {
            orderBy: { createdAt: 'asc' },
            select: { role: true, content: true },
          },
        },
      });

      if (!existingThread) {
        throw new NotFoundException('Thread not found');
      }
      thread = existingThread;
    } else {
      const newThread = await this.prisma.conciergeThread.create({
        data: { userId, householdId },
        include: { messages: { select: { role: true, content: true } } },
      });
      thread = newThread;
    }

    // Add user message to thread
    await this.prisma.conciergeMessage.create({
      data: {
        threadId: thread.id,
        role: 'user',
        content: dto.message,
      },
    });

    // Get household context for the AI
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
        workOrders: {
          where: { status: { in: ['OPEN', 'ASSIGNED', 'IN_PROGRESS'] } },
          take: 5,
          orderBy: { createdAt: 'desc' },
          select: { title: true, status: true, createdAt: true },
        },
      },
    });

    const conversationHistory = [
      ...thread.messages.map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      { role: 'user' as const, content: dto.message },
    ];

    // Generate AI response
    const aiResponse = await this.aiClassifier.generateChatResponse({
      conversationHistory,
      householdContext: {
        householdName: household?.name,
        address: household?.homeProfile?.addressLine1,
        city: household?.homeProfile?.city,
        activeWorkOrders: household?.workOrders?.length || 0,
      },
    });

    // Save assistant response
    await this.prisma.conciergeMessage.create({
      data: {
        threadId: thread.id,
        role: 'assistant',
        content: aiResponse.response,
      },
    });

    // If AI suggests creating a request, do so
    let createdRequest: InboundRequestResponseDto | undefined;
    if (aiResponse.shouldCreateRequest && aiResponse.requestData) {
      const requestData = aiResponse.requestData as {
        category?: string;
        title?: string;
        description?: string;
        priority?: string;
      };

      const inboundRequest = await this.prisma.inboundRequest.create({
        data: {
          channel: InboundChannel.CHAT,
          rawPayload: { threadId: thread.id, message: dto.message } as Prisma.InputJsonValue,
          body: dto.message,
          category: (requestData.category as RequestCategory) || RequestCategory.INQUIRY,
          priority: (requestData.priority as TriagePriority) || TriagePriority.MEDIUM,
          summary: requestData.title || dto.message.substring(0, 100),
          aiConfidence: 0.8,
          aiReasoning: 'Created from chat conversation',
          householdId,
          userId,
          status: TriageStatus.PENDING_REVIEW,
          conciergeThreadId: thread.id,
          suggestions: {
            create: [{
              actionType: this.getDefaultActionType(requestData.category as RequestCategory),
              title: requestData.title || 'Create request',
              description: requestData.description || dto.message,
              confidence: 0.8,
              actionData: requestData as Prisma.InputJsonValue,
            }],
          },
        },
        include: {
          household: { select: { id: true, name: true } },
          attachments: true,
          suggestions: true,
        },
      });

      createdRequest = this.mapToResponse(inboundRequest);
    }

    return {
      response: aiResponse.response,
      threadId: thread.id,
      createdRequest,
    };
  }

  // =========================================================================
  // TRIAGE MANAGEMENT
  // =========================================================================

  /**
   * List inbound requests with filtering
   */
  async listRequests(query: TriageListQueryDto): Promise<{
    items: InboundRequestResponseDto[];
    total: number;
  }> {
    const where: Prisma.InboundRequestWhereInput = {};

    if (query.status) {
      where.status = query.status;
    } else if (!query.includeResolved) {
      where.status = { not: TriageStatus.RESOLVED };
    }

    if (query.category) {
      where.category = query.category;
    }

    if (query.priority) {
      where.priority = query.priority;
    }

    if (query.householdId) {
      where.householdId = query.householdId;
    }

    const [items, total] = await Promise.all([
      this.prisma.inboundRequest.findMany({
        where,
        include: {
          household: { select: { id: true, name: true } },
          attachments: true,
          suggestions: true,
        },
        orderBy: [
          { priority: 'desc' },
          { createdAt: 'desc' },
        ],
        take: query.limit || 20,
        skip: query.offset || 0,
      }),
      this.prisma.inboundRequest.count({ where }),
    ]);

    return {
      items: items.map((item) => this.mapToResponse(item)),
      total,
    };
  }

  /**
   * Get a single request by ID
   */
  async getRequest(id: string): Promise<InboundRequestResponseDto> {
    const request = await this.prisma.inboundRequest.findUnique({
      where: { id },
      include: {
        household: { select: { id: true, name: true } },
        attachments: true,
        suggestions: true,
        resolvedBy: { select: { id: true, displayName: true } },
      },
    });

    if (!request) {
      throw new NotFoundException('Inbound request not found');
    }

    return this.mapToResponse(request);
  }

  /**
   * Get triage statistics
   */
  async getStats(): Promise<TriageStatsDto> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      total,
      byStatus,
      byCategory,
      byPriority,
      todayCount,
      pendingReview,
    ] = await Promise.all([
      this.prisma.inboundRequest.count(),
      this.prisma.inboundRequest.groupBy({
        by: ['status'],
        _count: true,
      }),
      this.prisma.inboundRequest.groupBy({
        by: ['category'],
        _count: true,
      }),
      this.prisma.inboundRequest.groupBy({
        by: ['priority'],
        _count: true,
      }),
      this.prisma.inboundRequest.count({
        where: { createdAt: { gte: today } },
      }),
      this.prisma.inboundRequest.count({
        where: { status: TriageStatus.PENDING_REVIEW },
      }),
    ]);

    // Convert arrays to records
    const statusRecord: Record<string, number> = {};
    for (const s of byStatus) {
      statusRecord[s.status] = s._count;
    }

    const categoryRecord: Record<string, number> = {};
    for (const c of byCategory) {
      categoryRecord[c.category] = c._count;
    }

    const priorityRecord: Record<string, number> = {};
    for (const p of byPriority) {
      priorityRecord[p.priority] = p._count;
    }

    return {
      total,
      byStatus: statusRecord as Record<TriageStatus, number>,
      byCategory: categoryRecord as Record<RequestCategory, number>,
      byPriority: priorityRecord as Record<TriagePriority, number>,
      avgProcessingTime: null,
      todayCount,
      pendingReview,
    };
  }

  /**
   * Manually classify a request
   */
  async manualClassify(
    requestId: string,
    category: RequestCategory,
    priority: TriagePriority,
    notes?: string,
  ): Promise<InboundRequestResponseDto> {
    const request = await this.prisma.inboundRequest.update({
      where: { id: requestId },
      data: {
        category,
        priority,
        status: TriageStatus.PENDING_REVIEW,
        aiReasoning: notes ? `Manual: ${notes}` : 'Manually classified',
      },
      include: {
        household: { select: { id: true, name: true } },
        attachments: true,
        suggestions: true,
      },
    });

    return this.mapToResponse(request);
  }

  /**
   * Link request to a household
   */
  async linkToHousehold(requestId: string, householdId: string): Promise<InboundRequestResponseDto> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    const request = await this.prisma.inboundRequest.update({
      where: { id: requestId },
      data: { householdId },
      include: {
        household: { select: { id: true, name: true } },
        attachments: true,
        suggestions: true,
      },
    });

    return this.mapToResponse(request);
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  /**
   * Identify sender by email or phone
   */
  private async identifySender(params: {
    email?: string;
    phone?: string;
  }): Promise<{ userId: string | null; householdId: string | null }> {
    let user = null;

    if (params.email) {
      user = await this.prisma.user.findUnique({
        where: { email: params.email },
        include: {
          householdMembers: {
            where: { status: 'ACTIVE' },
            orderBy: { joinedAt: 'desc' },
            take: 1,
            select: { householdId: true },
          },
        },
      });
    } else if (params.phone) {
      user = await this.prisma.user.findFirst({
        where: { phone: params.phone },
        include: {
          householdMembers: {
            where: { status: 'ACTIVE' },
            orderBy: { joinedAt: 'desc' },
            take: 1,
            select: { householdId: true },
          },
        },
      });
    }

    if (user) {
      return {
        userId: user.id,
        householdId: user.householdMembers[0]?.householdId || null,
      };
    }

    return { userId: null, householdId: null };
  }

  /**
   * Determine initial status based on classification confidence
   */
  private determineInitialStatus(classification: ClassificationResult): TriageStatus {
    if (classification.confidence >= 0.9 && classification.suggestedActions.length > 0) {
      return TriageStatus.AUTO_APPROVED;
    }

    if (classification.confidence >= 0.5) {
      return TriageStatus.PENDING_REVIEW;
    }

    if (classification.category === RequestCategory.UNKNOWN) {
      return TriageStatus.NEEDS_ATTENTION;
    }

    return TriageStatus.PENDING_REVIEW;
  }

  /**
   * Get default action type for a category
   */
  private getDefaultActionType(category: RequestCategory): string {
    const mapping: Record<RequestCategory, string> = {
      BILL: 'PAY_BILL',
      FIX: 'CREATE_WORK_ORDER',
      PROJECT: 'CREATE_PROJECT',
      CALENDAR: 'CREATE_EVENT',
      TRIP: 'CREATE_TRIP',
      INQUIRY: 'RESPOND_INQUIRY',
      UNKNOWN: 'RESPOND_INQUIRY',
    };
    return mapping[category] || 'RESPOND_INQUIRY';
  }

  /**
   * Map database record to response DTO
   */
  private mapToResponse(request: {
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
    household: { id: string; name: string } | null;
    suggestions: Array<{
      id: string;
      actionType: string;
      title: string;
      description: string | null;
      confidence: number;
      actionData: unknown;
      isApproved: boolean;
      isRejected: boolean;
    }>;
    attachments: Array<{
      id: string;
      filename: string;
      contentType: string;
      sizeBytes: number | null;
      extractedText: string | null;
      documentType: string | null;
    }>;
    resolvedAction?: string | null;
    resolvedEntityId?: string | null;
    resolvedAt?: Date | null;
    resolvedByUserId?: string | null;
    createdAt: Date;
  }): InboundRequestResponseDto {
    return {
      id: request.id,
      channel: request.channel,
      category: request.category,
      priority: request.priority,
      status: request.status,
      senderEmail: request.senderEmail,
      senderPhone: request.senderPhone,
      senderName: request.senderName,
      subject: request.subject,
      body: request.body,
      summary: request.summary,
      aiConfidence: request.aiConfidence,
      aiReasoning: request.aiReasoning,
      householdId: request.householdId,
      household: request.household,
      suggestions: request.suggestions.map((s) => ({
        id: s.id,
        actionType: s.actionType,
        title: s.title,
        description: s.description,
        confidence: s.confidence,
        actionData: s.actionData as Record<string, unknown>,
        isApproved: s.isApproved,
        isRejected: s.isRejected,
      })),
      attachments: request.attachments.map((a) => ({
        id: a.id,
        filename: a.filename,
        contentType: a.contentType,
        sizeBytes: a.sizeBytes,
        extractedText: a.extractedText,
        documentType: a.documentType,
      })),
      resolvedAction: request.resolvedAction || null,
      resolvedEntityId: request.resolvedEntityId || null,
      resolvedAt: request.resolvedAt || null,
      resolvedByUserId: request.resolvedByUserId || null,
      createdAt: request.createdAt,
    };
  }
}
