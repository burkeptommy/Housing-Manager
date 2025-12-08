import { Injectable } from '@nestjs/common';
import { Prisma, Invoice, InvoiceStatus } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type InvoiceWithHousehold = Prisma.InvoiceGetPayload<{
  include: { household: true; files: true };
}>;

export interface InvoiceFilters {
  householdId?: string;
  status?: InvoiceStatus;
  issuedAfter?: Date;
  issuedBefore?: Date;
}

@Injectable()
export class InvoiceRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.InvoiceCreateInput): Promise<Invoice> {
    return this.prisma.invoice.create({ data });
  }

  async findById(id: string): Promise<Invoice | null> {
    return this.prisma.invoice.findUnique({ where: { id } });
  }

  async findByIdWithRelations(id: string): Promise<InvoiceWithHousehold | null> {
    return this.prisma.invoice.findUnique({
      where: { id },
      include: { household: true, files: true },
    });
  }

  async findByInvoiceNumber(invoiceNumber: string): Promise<Invoice | null> {
    return this.prisma.invoice.findUnique({ where: { invoiceNumber } });
  }

  async findMany(
    filters: InvoiceFilters,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<InvoiceWithHousehold>> {
    const { page, pageSize } = params;
    const { householdId, status, issuedAfter, issuedBefore } = filters;

    const where: Prisma.InvoiceWhereInput = {};

    if (householdId) where.householdId = householdId;
    if (status) where.status = status;

    if (issuedAfter || issuedBefore) {
      where.issuedAt = {};
      if (issuedAfter) where.issuedAt.gte = issuedAfter;
      if (issuedBefore) where.issuedAt.lte = issuedBefore;
    }

    const [data, total] = await Promise.all([
      this.prisma.invoice.findMany({
        where,
        include: { household: true, files: true },
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.invoice.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async findByHousehold(
    householdId: string,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<InvoiceWithHousehold>> {
    return this.findMany({ householdId }, params);
  }

  async findOverdue(): Promise<Invoice[]> {
    return this.prisma.invoice.findMany({
      where: {
        status: 'SENT',
        dueDate: { lt: new Date() },
      },
      orderBy: { dueDate: 'asc' },
    });
  }

  async update(id: string, data: Prisma.InvoiceUpdateInput): Promise<Invoice> {
    return this.prisma.invoice.update({ where: { id }, data });
  }

  async updateStatus(id: string, status: InvoiceStatus): Promise<Invoice> {
    const data: Prisma.InvoiceUpdateInput = { status };

    if (status === 'SENT') {
      data.issuedAt = new Date();
    } else if (status === 'PAID') {
      data.paidAt = new Date();
    }

    return this.prisma.invoice.update({ where: { id }, data });
  }

  async delete(id: string): Promise<Invoice> {
    return this.prisma.invoice.delete({ where: { id } });
  }

  async generateInvoiceNumber(): Promise<string> {
    const year = new Date().getFullYear();
    const prefix = `INV-${year}-`;

    const lastInvoice = await this.prisma.invoice.findFirst({
      where: {
        invoiceNumber: { startsWith: prefix },
      },
      orderBy: { invoiceNumber: 'desc' },
    });

    let nextNumber = 1;
    if (lastInvoice) {
      const lastNumber = parseInt(lastInvoice.invoiceNumber.replace(prefix, ''), 10);
      nextNumber = lastNumber + 1;
    }

    return `${prefix}${String(nextNumber).padStart(5, '0')}`;
  }

  async getTotalByStatus(householdId: string): Promise<Record<InvoiceStatus, number>> {
    const results = await this.prisma.invoice.groupBy({
      by: ['status'],
      where: { householdId },
      _sum: { total: true },
    });

    const totals: Record<InvoiceStatus, number> = {
      DRAFT: 0,
      SENT: 0,
      PAID: 0,
      OVERDUE: 0,
      CANCELLED: 0,
      REFUNDED: 0,
    };

    for (const result of results) {
      totals[result.status] = Number(result._sum.total) || 0;
    }

    return totals;
  }
}
