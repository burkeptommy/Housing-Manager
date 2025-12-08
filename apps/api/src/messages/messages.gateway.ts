import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

import { PrismaService } from '../prisma';

import { MessagesService } from './messages.service';
import { JoinChannelDto, SendMessageDto, ChannelType, MessageDetailDto } from './dto';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  userRole?: string;
}

@WebSocketGateway({
  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
    credentials: true,
  },
  namespace: '/messages',
})
export class MessagesGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(MessagesGateway.name);

  constructor(
    private readonly messagesService: MessagesService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(client: AuthenticatedSocket) {
    try {
      const token = this.extractToken(client);
      if (!token) {
        this.logger.warn(`Client ${client.id} connection rejected: no token`);
        client.disconnect();
        return;
      }

      const payload = await this.jwtService.verifyAsync(token, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });

      client.userId = payload.sub;
      client.userRole = payload.role;
      this.logger.log(`Client ${client.id} connected as user ${payload.sub}`);
    } catch (error) {
      this.logger.warn(`Client ${client.id} connection rejected: invalid token`);
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthenticatedSocket) {
    this.logger.log(`Client ${client.id} disconnected`);
  }

  @SubscribeMessage('join_channel')
  async handleJoinChannel(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() dto: JoinChannelDto,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      if (!client.userId) {
        return { success: false, error: 'Not authenticated' };
      }

      // Verify access to channel
      const hasAccess = await this.verifyChannelAccess(
        dto.channelType,
        dto.channelId,
        client.userId,
        client.userRole,
      );

      if (!hasAccess) {
        return { success: false, error: 'Not authorized to access this channel' };
      }

      const roomName = this.getRoomName(dto.channelType, dto.channelId);
      await client.join(roomName);
      this.logger.log(`Client ${client.id} joined room ${roomName}`);

      return { success: true };
    } catch (error) {
      this.logger.error(`Error joining channel: ${error}`);
      return { success: false, error: 'Failed to join channel' };
    }
  }

  @SubscribeMessage('leave_channel')
  async handleLeaveChannel(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() dto: JoinChannelDto,
  ): Promise<{ success: boolean }> {
    const roomName = this.getRoomName(dto.channelType, dto.channelId);
    await client.leave(roomName);
    this.logger.log(`Client ${client.id} left room ${roomName}`);
    return { success: true };
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() dto: SendMessageDto,
  ): Promise<{ success: boolean; message?: MessageDetailDto; error?: string }> {
    try {
      if (!client.userId) {
        return { success: false, error: 'Not authenticated' };
      }

      const message = await this.messagesService.create(
        dto.channelType,
        dto.channelId,
        { content: dto.content, messageType: dto.messageType },
        { sub: client.userId, role: client.userRole as string, email: '' },
      );

      // Broadcast to all clients in the room (including sender)
      const roomName = this.getRoomName(dto.channelType, dto.channelId);
      this.server.to(roomName).emit('new_message', message);

      return { success: true, message };
    } catch (error) {
      this.logger.error(`Error sending message: ${error}`);
      return { success: false, error: 'Failed to send message' };
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() dto: JoinChannelDto,
  ): void {
    if (!client.userId) return;

    const roomName = this.getRoomName(dto.channelType, dto.channelId);
    client.to(roomName).emit('user_typing', {
      userId: client.userId,
      channelType: dto.channelType,
      channelId: dto.channelId,
    });
  }

  @SubscribeMessage('stop_typing')
  handleStopTyping(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() dto: JoinChannelDto,
  ): void {
    if (!client.userId) return;

    const roomName = this.getRoomName(dto.channelType, dto.channelId);
    client.to(roomName).emit('user_stop_typing', {
      userId: client.userId,
      channelType: dto.channelType,
      channelId: dto.channelId,
    });
  }

  // Helper method to broadcast messages from other services
  broadcastMessage(
    channelType: ChannelType,
    channelId: string,
    message: MessageDetailDto,
  ): void {
    const roomName = this.getRoomName(channelType, channelId);
    this.server.to(roomName).emit('new_message', message);
  }

  private extractToken(client: Socket): string | null {
    // Try to get token from handshake auth
    const authToken = client.handshake.auth?.token;
    if (authToken) return authToken;

    // Try to get token from query params
    const queryToken = client.handshake.query?.token;
    if (queryToken && typeof queryToken === 'string') return queryToken;

    // Try to get token from headers
    const authHeader = client.handshake.headers?.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    return null;
  }

  private getRoomName(channelType: ChannelType, channelId: string): string {
    return `${channelType.toLowerCase()}:${channelId}`;
  }

  private async verifyChannelAccess(
    channelType: ChannelType,
    channelId: string,
    userId: string,
    userRole?: string,
  ): Promise<boolean> {
    if (userRole === 'ADMIN') return true;

    if (channelType === ChannelType.HOUSEHOLD) {
      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: channelId,
            userId,
          },
        },
      });
      return membership?.status === 'ACTIVE';
    } else {
      const serviceRequest = await this.prisma.serviceRequest.findUnique({
        where: { id: channelId },
        select: { householdId: true },
      });

      if (!serviceRequest) return false;

      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: serviceRequest.householdId,
            userId,
          },
        },
      });
      return membership?.status === 'ACTIVE';
    }
  }
}
