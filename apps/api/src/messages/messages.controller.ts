import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';

import { JwtAuthGuard, CurrentUser, JwtPayload } from '../auth';

import { MessagesService } from './messages.service';
import {
  CreateMessageDto,
  MessageDetailDto,
  MarkMessagesReadDto,
  ChannelType,
} from './dto';

@ApiTags('Messages')
@ApiBearerAuth()
@Controller('channels')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Get(':type/:id/messages')
  @ApiOperation({ summary: 'Get messages for a channel' })
  @ApiParam({ name: 'type', enum: ['household', 'request'], description: 'Channel type' })
  @ApiParam({ name: 'id', description: 'Channel ID (household or service request ID)' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Number of messages to return (default 50)' })
  @ApiQuery({ name: 'before', required: false, type: String, description: 'Get messages before this timestamp (ISO string)' })
  @ApiResponse({ status: 200, description: 'List of messages', type: [MessageDetailDto] })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not authorized to access channel' })
  async findByChannel(
    @Param('type') type: string,
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
    @Query('limit') limit?: string,
    @Query('before') before?: string,
  ): Promise<MessageDetailDto[]> {
    const channelType = this.parseChannelType(type);
    return this.messagesService.findByChannel(
      channelType,
      id,
      user,
      limit ? parseInt(limit, 10) : 50,
      before,
    );
  }

  @Post(':type/:id/messages')
  @ApiOperation({ summary: 'Send a message to a channel' })
  @ApiParam({ name: 'type', enum: ['household', 'request'], description: 'Channel type' })
  @ApiParam({ name: 'id', description: 'Channel ID (household or service request ID)' })
  @ApiResponse({ status: 201, description: 'Message sent', type: MessageDetailDto })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not authorized to access channel' })
  async create(
    @Param('type') type: string,
    @Param('id') id: string,
    @Body() dto: CreateMessageDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<MessageDetailDto> {
    const channelType = this.parseChannelType(type);
    return this.messagesService.create(channelType, id, dto, user);
  }

  @Post(':type/:id/messages/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark messages as read' })
  @ApiParam({ name: 'type', enum: ['household', 'request'], description: 'Channel type' })
  @ApiParam({ name: 'id', description: 'Channel ID (household or service request ID)' })
  @ApiResponse({ status: 200, description: 'Messages marked as read' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async markAsRead(
    @Param('type') type: string,
    @Param('id') id: string,
    @Body() dto: MarkMessagesReadDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<{ count: number }> {
    return this.messagesService.markAsRead(dto.messageIds, user);
  }

  @Get(':type/:id/messages/unread-count')
  @ApiOperation({ summary: 'Get unread message count for a channel' })
  @ApiParam({ name: 'type', enum: ['household', 'request'], description: 'Channel type' })
  @ApiParam({ name: 'id', description: 'Channel ID (household or service request ID)' })
  @ApiResponse({ status: 200, description: 'Unread count' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getUnreadCount(
    @Param('type') type: string,
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<{ count: number }> {
    const channelType = this.parseChannelType(type);
    const count = await this.messagesService.getUnreadCount(channelType, id, user);
    return { count };
  }

  private parseChannelType(type: string): ChannelType {
    const typeMap: Record<string, ChannelType> = {
      household: ChannelType.HOUSEHOLD,
      request: ChannelType.REQUEST,
    };

    const channelType = typeMap[type.toLowerCase()];
    if (!channelType) {
      throw new Error(`Invalid channel type: ${type}`);
    }
    return channelType;
  }
}
