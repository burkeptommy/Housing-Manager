import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { DocumentCategory } from '@prisma/client';

@Injectable()
export class DocumentService {
  constructor(
    private prisma: PrismaService,
    private storage: StorageService,
  ) {}

  /**
   * Upload a new document
   */
  async uploadDocument(
    householdId: string,
    userId: string,
    file: Express.Multer.File,
    data: {
      category: DocumentCategory;
      subcategory?: string;
      title?: string;
      description?: string;
      tags?: string[];
      expiresAt?: Date;
      vendorId?: string;
    },
  ) {
    // Upload file to storage
    const { url, path } = await this.storage.uploadFile(
      file,
      householdId,
      data.category,
    );

    // Create document record
    const document = await this.prisma.document.create({
      data: {
        householdId,
        uploadedById: userId,
        fileName: path.split('/').pop()!,
        originalName: file.originalname,
        mimeType: file.mimetype,
        fileSize: file.size,
        storageUrl: url,
        storagePath: path,
        category: data.category,
        subcategory: data.subcategory,
        title: data.title || file.originalname,
        description: data.description,
        tags: data.tags || [],
        expiresAt: data.expiresAt,
        expirationAlert: !!data.expiresAt,
        vendorId: data.vendorId,
      },
      include: {
        uploadedBy: {
          select: { id: true, displayName: true, firstName: true },
        },
        vendor: {
          select: { id: true, displayName: true },
        },
      },
    });

    return document;
  }

  /**
   * Get all documents for a household
   */
  async getHouseholdDocuments(
    householdId: string,
    filters?: {
      category?: DocumentCategory;
      search?: string;
      expiringWithinDays?: number;
    },
  ) {
    const where: any = { householdId };

    if (filters?.category) {
      where.category = filters.category;
    }

    if (filters?.search) {
      where.OR = [
        { title: { contains: filters.search, mode: 'insensitive' } },
        { originalName: { contains: filters.search, mode: 'insensitive' } },
        { description: { contains: filters.search, mode: 'insensitive' } },
        { tags: { has: filters.search } },
      ];
    }

    if (filters?.expiringWithinDays) {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + filters.expiringWithinDays);
      where.expiresAt = {
        lte: futureDate,
        gte: new Date(),
      };
    }

    const documents = await this.prisma.document.findMany({
      where,
      include: {
        uploadedBy: {
          select: { id: true, displayName: true, firstName: true },
        },
        vendor: {
          select: { id: true, displayName: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return documents;
  }

  /**
   * Get documents grouped by category
   */
  async getDocumentsByCategory(householdId: string) {
    const documents = await this.prisma.document.findMany({
      where: { householdId },
      orderBy: { createdAt: 'desc' },
    });

    // Group by category
    const grouped = documents.reduce(
      (acc, doc) => {
        if (!acc[doc.category]) {
          acc[doc.category] = [];
        }
        acc[doc.category].push(doc);
        return acc;
      },
      {} as Record<string, typeof documents>,
    );

    return grouped;
  }

  /**
   * Get document summary stats
   */
  async getDocumentSummary(householdId: string) {
    const now = new Date();
    const thirtyDays = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const [total, byCategory, expiringSoon, expired] = await Promise.all([
      this.prisma.document.count({ where: { householdId } }),
      this.prisma.document.groupBy({
        by: ['category'],
        where: { householdId },
        _count: true,
      }),
      this.prisma.document.count({
        where: {
          householdId,
          expiresAt: { gte: now, lte: thirtyDays },
        },
      }),
      this.prisma.document.count({
        where: {
          householdId,
          expiresAt: { lt: now },
        },
      }),
    ]);

    return {
      total,
      byCategory: byCategory.reduce(
        (acc, item) => {
          acc[item.category] = item._count;
          return acc;
        },
        {} as Record<string, number>,
      ),
      expiringSoon,
      expired,
    };
  }

  /**
   * Get a single document with signed URL
   */
  async getDocument(documentId: string, householdId: string) {
    const document = await this.prisma.document.findUnique({
      where: { id: documentId },
      include: {
        uploadedBy: {
          select: { id: true, displayName: true, firstName: true },
        },
        vendor: {
          select: { id: true, displayName: true },
        },
      },
    });

    if (!document) {
      throw new NotFoundException('Document not found');
    }

    if (document.householdId !== householdId) {
      throw new ForbiddenException('Access denied');
    }

    // Get signed URL for download
    const downloadUrl = await this.storage.getSignedUrl(document.storagePath);

    return { ...document, downloadUrl };
  }

  /**
   * Update document metadata
   */
  async updateDocument(
    documentId: string,
    data: {
      title?: string;
      description?: string;
      subcategory?: string;
      tags?: string[];
      expiresAt?: Date | null;
      vendorId?: string | null;
    },
  ) {
    return this.prisma.document.update({
      where: { id: documentId },
      data: {
        ...data,
        expirationAlert:
          data.expiresAt !== undefined ? !!data.expiresAt : undefined,
      },
    });
  }

  /**
   * Delete a document
   */
  async deleteDocument(documentId: string, householdId: string) {
    const document = await this.prisma.document.findUnique({
      where: { id: documentId },
    });

    if (!document) {
      throw new NotFoundException('Document not found');
    }

    if (document.householdId !== householdId) {
      throw new ForbiddenException('Access denied');
    }

    // Delete from storage
    await this.storage.deleteFile(document.storagePath);

    // Delete record
    await this.prisma.document.delete({ where: { id: documentId } });

    return { success: true };
  }

  /**
   * Get documents expiring soon (for alerts)
   */
  async getExpiringDocuments(householdId: string, withinDays = 30) {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + withinDays);

    return this.prisma.document.findMany({
      where: {
        householdId,
        expiresAt: {
          gte: new Date(),
          lte: futureDate,
        },
      },
      orderBy: { expiresAt: 'asc' },
    });
  }
}
