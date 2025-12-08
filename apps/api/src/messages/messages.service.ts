import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../prisma';
import { JwtPayload } from '../auth';

import {
  CreateMessageDto,
  MessageDto,
  MessageDetailDto,
  ChannelType,
  MessageType,
} from './dto';

@Injectable()
export class MessagesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    channelType: ChannelType,
    channelId: string,
    dto: CreateMessageDto,
    user: JwtPayload,
  ): Promise<MessageDetailDto> {
    // Verify access to channel
    await this.verifyChannelAccess(channelType, channelId, user);

    const data: Prisma.MessageCreateInput = {
      channelType,
      content: dto.content,
      messageType: dto.messageType || 'TEXT',
      sender: { connect: { id: user.sub } },
    };

    if (channelType === ChannelType.HOUSEHOLD) {
      data.household = { connect: { id: channelId } };
    } else {
      data.serviceRequest = { connect: { id: channelId } };
    }

    const message = await this.prisma.message.create({
      data,
      include: {
        sender: true,
        vendor: true,
      },
    });

    return this.mapToDetailDto(message);
  }

  async findByChannel(
    channelType: ChannelType,
    channelId: string,
    user: JwtPayload,
    limit = 50,
    before?: string,
  ): Promise<MessageDetailDto[]> {
    // Verify access to channel
    await this.verifyChannelAccess(channelType, channelId, user);

    const where: Prisma.MessageWhereInput = { channelType };

    if (channelType === ChannelType.HOUSEHOLD) {
      where.householdId = channelId;
    } else {
      where.serviceRequestId = channelId;
    }

    if (before) {
      where.createdAt = { lt: new Date(before) };
    }

    const messages = await this.prisma.message.findMany({
      where,
      include: {
        sender: true,
        vendor: true,
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    // Return in chronological order
    return messages.reverse().map((m) => this.mapToDetailDto(m));
  }

  async markAsRead(
    messageIds: string[],
    user: JwtPayload,
  ): Promise<{ count: number }> {
    // Only mark messages where user is NOT the sender
    const result = await this.prisma.message.updateMany({
      where: {
        id: { in: messageIds },
        senderId: { not: user.sub },
        isRead: false,
      },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });

    return { count: result.count };
  }

  async getUnreadCount(
    channelType: ChannelType,
    channelId: string,
    user: JwtPayload,
  ): Promise<number> {
    const where: Prisma.MessageWhereInput = {
      channelType,
      senderId: { not: user.sub },
      isRead: false,
    };

    if (channelType === ChannelType.HOUSEHOLD) {
      where.householdId = channelId;
    } else {
      where.serviceRequestId = channelId;
    }

    return this.prisma.message.count({ where });
  }

  private async verifyChannelAccess(
    channelType: ChannelType,
    channelId: string,
    user: JwtPayload,
  ): Promise<void> {
    if (user.role === 'ADMIN') return;

    if (channelType === ChannelType.HOUSEHOLD) {
      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: channelId,
            userId: user.sub,
          },
        },
      });

      if (!membership || membership.status !== 'ACTIVE') {
        throw new ForbiddenException('You are not a member of this household');
      }
    } else {
      // For request channels, verify user has access to the service request's household
      const serviceRequest = await this.prisma.serviceRequest.findUnique({
        where: { id: channelId },
        select: { householdId: true },
      });

      if (!serviceRequest) {
        throw new NotFoundException(`Service request with ID ${channelId} not found`);
      }

      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: serviceRequest.householdId,
            userId: user.sub,
          },
        },
      });

      if (!membership || membership.status !== 'ACTIVE') {
        throw new ForbiddenException('You do not have access to this service request');
      }
    }
  }

  private mapToDetailDto(
    message: Prisma.MessageGetPayload<{
      include: { sender: true; vendor: true };
    }>,
  ): MessageDetailDto {
    return {
      id: message.id,
      channelType: message.channelType as ChannelType,
      householdId: message.householdId,
      serviceRequestId: message.serviceRequestId,
      senderId: message.senderId,
      vendorId: message.vendorId,
      content: message.content,
      messageType: message.messageType as MessageType,
      isRead: message.isRead,
      readAt: message.readAt,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      sender: message.sender
        ? {
            id: message.sender.id,
            firstName: message.sender.firstName,
            lastName: message.sender.lastName,
            email: message.sender.email,
          }
        : null,
      vendor: message.vendor
        ? {
            id: message.vendor.id,
            companyName: message.vendor.companyName,
          }
        : null,
    };
  }
}
