import { Injectable } from '@nestjs/common';
import { Prisma, Message, MessageType } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type MessageWithRelations = Prisma.MessageGetPayload<{
  include: { sender: true; vendor: true; serviceRequest: true };
}>;

@Injectable()
export class MessageRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.MessageCreateInput): Promise<Message> {
    return this.prisma.message.create({ data });
  }

  async findById(id: string): Promise<Message | null> {
    return this.prisma.message.findUnique({ where: { id } });
  }

  async findByIdWithRelations(id: string): Promise<MessageWithRelations | null> {
    return this.prisma.message.findUnique({
      where: { id },
      include: { sender: true, vendor: true, serviceRequest: true },
    });
  }

  async findByServiceRequest(
    serviceRequestId: string,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<MessageWithRelations>> {
    const { page, pageSize } = params;

    const where: Prisma.MessageWhereInput = { serviceRequestId };

    const [data, total] = await Promise.all([
      this.prisma.message.findMany({
        where,
        include: { sender: true, vendor: true, serviceRequest: true },
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: { createdAt: 'asc' },
      }),
      this.prisma.message.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async markAsRead(id: string): Promise<Message> {
    return this.prisma.message.update({
      where: { id },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async markManyAsRead(ids: string[]): Promise<Prisma.BatchPayload> {
    return this.prisma.message.updateMany({
      where: { id: { in: ids } },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async markAllAsReadForServiceRequest(serviceRequestId: string): Promise<Prisma.BatchPayload> {
    return this.prisma.message.updateMany({
      where: { serviceRequestId, isRead: false },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async countUnread(serviceRequestId: string): Promise<number> {
    return this.prisma.message.count({
      where: { serviceRequestId, isRead: false },
    });
  }

  async delete(id: string): Promise<Message> {
    return this.prisma.message.delete({ where: { id } });
  }

  async createSystemMessage(
    serviceRequestId: string,
    content: string
  ): Promise<Message> {
    return this.prisma.message.create({
      data: {
        serviceRequestId,
        content,
        messageType: 'SYSTEM',
      },
    });
  }
}
