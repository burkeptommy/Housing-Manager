import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

import { JwtAuthGuard, RolesGuard, Roles, CurrentUser as JwtCurrentUser, JwtPayload } from '../auth';
import { FirebaseAuthGuard, CurrentUser, AuthPayload } from '../firebase';

import { ConversationsService } from './conversations.service';
import {
  CreateConversationDto,
  SendMessageDto,
  ConversationListQueryDto,
  InternalConversationListQueryDto,
  AssignConversationDto,
  UpdateConversationStatusDto,
} from './dto';

/**
 * Conversations Controller - For homeowners
 * Uses Firebase Auth
 */
@ApiTags('Conversations')
@ApiBearerAuth()
@Controller('conversations')
@UseGuards(FirebaseAuthGuard)
export class ConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  /**
   * Create a new conversation
   */
  @Post()
  @ApiOperation({ summary: 'Create a new support conversation' })
  @ApiResponse({ status: 201, description: 'Conversation created' })
  async createConversation(
    @CurrentUser() user: AuthPayload,
    @Body() dto: CreateConversationDto,
  ) {
    if (!user.householdId) {
      throw new Error('No household associated with user');
    }
    return this.conversationsService.createConversation(
      user.userId,
      user.householdId,
      dto,
    );
  }

  /**
   * List conversations for current household
   */
  @Get()
  @ApiOperation({ summary: 'List conversations for current household' })
  @ApiResponse({ status: 200, description: 'List of conversations' })
  async listConversations(
    @CurrentUser() user: AuthPayload,
    @Query() query: ConversationListQueryDto,
  ) {
    if (!user.householdId) {
      return [];
    }
    return this.conversationsService.listConversations(
      user.userId,
      user.householdId,
      query,
    );
  }

  /**
   * Get a specific conversation with messages
   */
  @Get(':id')
  @ApiOperation({ summary: 'Get conversation details with messages' })
  @ApiResponse({ status: 200, description: 'Conversation details' })
  async getConversation(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
  ) {
    return this.conversationsService.getConversation(user.userId, id);
  }

  /**
   * Send a message in a conversation
   */
  @Post(':id/messages')
  @ApiOperation({ summary: 'Send a message in a conversation' })
  @ApiResponse({ status: 201, description: 'Message sent' })
  async sendMessage(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.conversationsService.sendMessage(user.userId, id, dto);
  }

  /**
   * Update conversation status
   */
  @Patch(':id/status')
  @ApiOperation({ summary: 'Update conversation status' })
  @ApiResponse({ status: 200, description: 'Status updated' })
  async updateStatus(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
    @Body() dto: UpdateConversationStatusDto,
  ) {
    return this.conversationsService.updateConversationStatus(
      user.userId,
      user.role as UserRole,
      id,
      dto.status,
    );
  }
}

/**
 * Internal Conversations Controller - For home managers and admins
 * Uses JWT Auth (legacy) or Firebase Auth
 */
@ApiTags('Internal Conversations')
@ApiBearerAuth()
@Controller('internal/conversations')
@UseGuards(FirebaseAuthGuard)
export class InternalConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  /**
   * List all conversations in queue (for home managers)
   */
  @Get('queue')
  @ApiOperation({ summary: 'List all open/pending conversations' })
  @ApiResponse({ status: 200, description: 'List of conversations' })
  async listQueue(
    @CurrentUser() user: AuthPayload,
    @Query() query: InternalConversationListQueryDto,
  ) {
    return this.conversationsService.listInternalConversations(
      user.userId,
      user.role as UserRole,
      query,
    );
  }

  /**
   * Get a specific conversation (internal view)
   */
  @Get(':id')
  @ApiOperation({ summary: 'Get conversation details (internal)' })
  @ApiResponse({ status: 200, description: 'Conversation details' })
  async getConversation(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
  ) {
    return this.conversationsService.getConversation(user.userId, id);
  }

  /**
   * Assign a home manager to a conversation
   */
  @Post(':id/assign')
  @ApiOperation({ summary: 'Assign a home manager to conversation' })
  @ApiResponse({ status: 200, description: 'Assignment created' })
  async assignConversation(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
    @Body() dto: AssignConversationDto,
  ) {
    return this.conversationsService.assignConversation(
      user.userId,
      user.role as UserRole,
      id,
      dto,
    );
  }

  /**
   * Send a message in a conversation (as home manager)
   */
  @Post(':id/messages')
  @ApiOperation({ summary: 'Send a message as home manager' })
  @ApiResponse({ status: 201, description: 'Message sent' })
  async sendMessage(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.conversationsService.sendMessage(user.userId, id, dto);
  }

  /**
   * Update conversation status
   */
  @Patch(':id/status')
  @ApiOperation({ summary: 'Update conversation status' })
  @ApiResponse({ status: 200, description: 'Status updated' })
  async updateStatus(
    @CurrentUser() user: AuthPayload,
    @Param('id') id: string,
    @Body() dto: UpdateConversationStatusDto,
  ) {
    return this.conversationsService.updateConversationStatus(
      user.userId,
      user.role as UserRole,
      id,
      dto.status,
    );
  }
}
