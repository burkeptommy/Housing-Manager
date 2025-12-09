import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { ConversationStatus, SenderRole, UserRole } from '@prisma/client';

import { PrismaService } from '../prisma';

import {
  CreateConversationDto,
  SendMessageDto,
  ConversationListQueryDto,
  InternalConversationListQueryDto,
  AssignConversationDto,
} from './dto';

// User select for includes
const userSelect = {
  id: true,
  firstName: true,
  lastName: true,
  email: true,
};

@Injectable()
export class ConversationsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new conversation for a household
   */
  async createConversation(
    userId: string,
    householdId: string,
    dto: CreateConversationDto,
  ) {
    // Verify user is a member of the household
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: { householdId, userId },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You are not a member of this household');
    }

    // Create conversation with initial message
    const conversation = await this.prisma.conversation.create({
      data: {
        householdId,
        createdByUserId: userId,
        subject: dto.subject,
        status: ConversationStatus.OPEN,
        homeManagerUnreadCount: 1, // New conversation has unread for manager
        messages: {
          create: {
            senderUserId: userId,
            senderRole: SenderRole.HOMEOWNER,
            body: dto.body,
            attachmentUrl: dto.attachmentUrl,
          },
        },
      },
      include: {
        createdBy: { select: userSelect },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: { sender: { select: userSelect } },
        },
      },
    });

    // Create notification for new conversation
    await this.createChatNotification(conversation.id, 'NEW_CONVERSATION');

    return this.formatConversation(conversation);
  }

  /**
   * List conversations for a household
   */
  async listConversations(
    userId: string,
    householdId: string,
    query: ConversationListQueryDto,
  ) {
    // Verify user is a member of the household
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: { householdId, userId },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You are not a member of this household');
    }

    const where: any = { householdId };

    if (query.status) {
      where.status = query.status;
    }

    if (query.updatedSince) {
      where.updatedAt = { gte: new Date(query.updatedSince) };
    }

    const conversations = await this.prisma.conversation.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
      include: {
        createdBy: { select: userSelect },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: { sender: { select: userSelect } },
        },
        assignments: {
          include: { homeManager: { select: userSelect } },
        },
      },
    });

    return conversations.map((c) => this.formatConversation(c));
  }

  /**
   * Get a single conversation with all messages
   */
  async getConversation(userId: string, conversationId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        createdBy: { select: userSelect },
        household: { select: { id: true, name: true } },
        messages: {
          orderBy: { createdAt: 'asc' },
          include: { sender: { select: userSelect } },
        },
        assignments: {
          include: { homeManager: { select: userSelect } },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    // Check if user has access
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const isAdmin = user?.role === UserRole.ADMIN;
    const isHomeManager = user?.role === UserRole.MANAGER;

    if (!isAdmin && !isHomeManager) {
      // Check if user is a member of the household
      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: conversation.householdId,
            userId,
          },
        },
      });

      if (!membership || membership.status !== 'ACTIVE') {
        throw new ForbiddenException('You do not have access to this conversation');
      }

      // Mark homeowner unread count as 0
      await this.prisma.conversation.update({
        where: { id: conversationId },
        data: { homeownerUnreadCount: 0 },
      });
    } else {
      // Mark home manager unread count as 0
      await this.prisma.conversation.update({
        where: { id: conversationId },
        data: { homeManagerUnreadCount: 0 },
      });
    }

    return this.formatConversationDetail(conversation);
  }

  /**
   * Send a message in a conversation
   */
  async sendMessage(
    userId: string,
    conversationId: string,
    dto: SendMessageDto,
  ) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    // Determine sender role
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const isAdmin = user?.role === UserRole.ADMIN;
    const isManager = user?.role === UserRole.MANAGER;

    let senderRole: SenderRole;
    let unreadUpdate: any;

    if (isAdmin || isManager) {
      senderRole = SenderRole.HOME_MANAGER;
      unreadUpdate = { homeownerUnreadCount: { increment: 1 } };
    } else {
      // Verify user is a member of the household
      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: conversation.householdId,
            userId,
          },
        },
      });

      if (!membership || membership.status !== 'ACTIVE') {
        throw new ForbiddenException('You do not have access to this conversation');
      }

      senderRole = SenderRole.HOMEOWNER;
      unreadUpdate = { homeManagerUnreadCount: { increment: 1 } };
    }

    // Create message and update conversation
    const [message] = await this.prisma.$transaction([
      this.prisma.supportMessage.create({
        data: {
          conversationId,
          senderUserId: userId,
          senderRole,
          body: dto.body,
          attachmentUrl: dto.attachmentUrl,
        },
        include: { sender: { select: userSelect } },
      }),
      this.prisma.conversation.update({
        where: { id: conversationId },
        data: {
          ...unreadUpdate,
          status: ConversationStatus.OPEN, // Reopen if closed
          updatedAt: new Date(),
        },
      }),
    ]);

    // Create notification
    await this.createChatNotification(conversationId, 'NEW_MESSAGE');

    return this.formatMessage(message);
  }

  /**
   * Internal: List all conversations across households (for home managers/admins)
   */
  async listInternalConversations(
    userId: string,
    userRole: UserRole,
    query: InternalConversationListQueryDto,
  ) {
    if (userRole !== UserRole.ADMIN && userRole !== UserRole.MANAGER) {
      throw new ForbiddenException('Access denied');
    }

    const where: any = {};

    if (query.status) {
      where.status = query.status;
    } else {
      // Default to open or pending
      where.status = { in: [ConversationStatus.OPEN, ConversationStatus.PENDING] };
    }

    if (query.assignedToMe) {
      where.assignments = {
        some: { homeManagerUserId: userId },
      };
    }

    if (query.unassigned) {
      where.assignments = { none: {} };
    }

    const conversations = await this.prisma.conversation.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
      include: {
        createdBy: { select: userSelect },
        household: { select: { id: true, name: true } },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: { sender: { select: userSelect } },
        },
        assignments: {
          include: { homeManager: { select: userSelect } },
        },
      },
    });

    return conversations.map((c) => this.formatConversationWithHousehold(c));
  }

  /**
   * Internal: Assign a home manager to a conversation
   */
  async assignConversation(
    assignedByUserId: string,
    userRole: UserRole,
    conversationId: string,
    dto: AssignConversationDto,
  ) {
    if (userRole !== UserRole.ADMIN && userRole !== UserRole.MANAGER) {
      throw new ForbiddenException('Access denied');
    }

    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    // Verify the home manager exists and has appropriate role
    const homeManager = await this.prisma.user.findUnique({
      where: { id: dto.homeManagerUserId },
    });

    if (!homeManager || (homeManager.role !== UserRole.MANAGER && homeManager.role !== UserRole.ADMIN)) {
      throw new NotFoundException('Home manager not found');
    }

    // Create or update assignment
    const assignment = await this.prisma.homeManagerAssignment.upsert({
      where: {
        conversationId_homeManagerUserId: {
          conversationId,
          homeManagerUserId: dto.homeManagerUserId,
        },
      },
      update: {
        assignedByUserId,
        assignedAt: new Date(),
      },
      create: {
        conversationId,
        homeManagerUserId: dto.homeManagerUserId,
        assignedByUserId,
      },
      include: {
        homeManager: { select: userSelect },
      },
    });

    // Add system message about assignment
    await this.prisma.supportMessage.create({
      data: {
        conversationId,
        senderRole: SenderRole.SYSTEM,
        body: `${homeManager.firstName || homeManager.email} has been assigned to this conversation.`,
      },
    });

    return {
      id: assignment.id,
      conversationId: assignment.conversationId,
      homeManagerUserId: assignment.homeManagerUserId,
      assignedAt: assignment.assignedAt.toISOString(),
      homeManager: assignment.homeManager,
    };
  }

  /**
   * Update conversation status
   */
  async updateConversationStatus(
    userId: string,
    userRole: UserRole,
    conversationId: string,
    status: ConversationStatus,
  ) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    // Check permissions
    const isAdmin = userRole === UserRole.ADMIN;
    const isManager = userRole === UserRole.MANAGER;

    if (!isAdmin && !isManager) {
      // Homeowners can only mark as pending or reopen
      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: conversation.householdId,
            userId,
          },
        },
      });

      if (!membership || membership.status !== 'ACTIVE') {
        throw new ForbiddenException('You do not have access to this conversation');
      }

      if (status === ConversationStatus.CLOSED) {
        throw new ForbiddenException('Only home managers can close conversations');
      }
    }

    const updated = await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { status },
      include: {
        createdBy: { select: userSelect },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: { sender: { select: userSelect } },
        },
      },
    });

    // Add system message about status change
    const statusMessages: Record<ConversationStatus, string> = {
      OPEN: 'Conversation reopened.',
      PENDING: 'Conversation marked as pending.',
      CLOSED: 'Conversation closed.',
    };

    await this.prisma.supportMessage.create({
      data: {
        conversationId,
        senderRole: SenderRole.SYSTEM,
        body: statusMessages[status],
      },
    });

    return this.formatConversation(updated);
  }

  /**
   * Create a notification for chat events
   */
  private async createChatNotification(
    conversationId: string,
    type: 'NEW_CONVERSATION' | 'NEW_MESSAGE',
  ) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        household: true,
        createdBy: { select: userSelect },
      },
    });

    if (!conversation) return;

    const title = type === 'NEW_CONVERSATION'
      ? 'New support conversation'
      : 'New message';

    const body = type === 'NEW_CONVERSATION'
      ? `${conversation.createdBy?.firstName || 'A homeowner'} started a conversation: ${conversation.subject || 'No subject'}`
      : `New message in conversation: ${conversation.subject || 'Support request'}`;

    // Find home managers assigned or admins to notify
    const homeManagers = await this.prisma.user.findMany({
      where: {
        role: { in: [UserRole.ADMIN, UserRole.MANAGER] },
      },
    });

    // Create in-app notifications
    for (const manager of homeManagers) {
      await this.prisma.inAppNotification.create({
        data: {
          userId: manager.id,
          householdId: conversation.householdId,
          title,
          body,
          link: `/internal/conversations/${conversationId}`,
        },
      });
    }
  }

  // Formatting helpers
  private formatConversation(conversation: any) {
    return {
      id: conversation.id,
      householdId: conversation.householdId,
      createdByUserId: conversation.createdByUserId,
      subject: conversation.subject,
      status: conversation.status,
      homeownerUnreadCount: conversation.homeownerUnreadCount,
      homeManagerUnreadCount: conversation.homeManagerUnreadCount,
      createdAt: conversation.createdAt.toISOString(),
      updatedAt: conversation.updatedAt.toISOString(),
      createdBy: conversation.createdBy,
      lastMessage: conversation.messages?.[0]
        ? this.formatMessage(conversation.messages[0])
        : undefined,
      assignments: conversation.assignments?.map((a: any) => ({
        id: a.id,
        conversationId: a.conversationId,
        homeManagerUserId: a.homeManagerUserId,
        assignedAt: a.assignedAt.toISOString(),
        homeManager: a.homeManager,
      })),
    };
  }

  private formatConversationWithHousehold(conversation: any) {
    return {
      ...this.formatConversation(conversation),
      household: conversation.household,
    };
  }

  private formatConversationDetail(conversation: any) {
    return {
      ...this.formatConversation(conversation),
      household: conversation.household,
      messages: conversation.messages.map((m: any) => this.formatMessage(m)),
    };
  }

  private formatMessage(message: any) {
    return {
      id: message.id,
      conversationId: message.conversationId,
      senderUserId: message.senderUserId,
      senderRole: message.senderRole,
      body: message.body,
      attachmentUrl: message.attachmentUrl,
      createdAt: message.createdAt.toISOString(),
      sender: message.sender,
    };
  }
}
