# Haven: Document Vault

**Created:** December 28, 2024  
**Purpose:** Secure document storage for home-related files  
**Priority:** P0 - Expected feature for home management  
**Depends On:** 009 (Maintenance Calendar) - complete

---

## CRITICAL RULES

1. **DO NOT DELETE existing code** - Only add and refactor
2. **Use existing file upload patterns** if any exist in the codebase
3. **Google Cloud Storage** for file storage (we're on GCP)

---

## Overview

The Document Vault allows homeowners to store and organize important home documents:
- Deeds, surveys, title insurance
- Insurance policies
- Warranties and manuals
- Tax records
- Vendor contracts
- Receipts and invoices

**Key Features:**
- Drag-and-drop upload
- Category organization
- Expiration tracking (warranties, policies)
- Search functionality
- Manager access to view documents

---

## PHASE 1: Database Schema

### Task 1.1: Create Document Model

Add to `apps/api/prisma/schema.prisma`:

```prisma
model Document {
  id              String           @id @default(uuid())
  householdId     String
  household       Household        @relation(fields: [householdId], references: [id])
  
  // File info
  fileName        String
  originalName    String
  mimeType        String
  fileSize        Int              // bytes
  storageUrl      String           // GCS URL
  storagePath     String           // GCS path for deletion
  
  // Organization
  category        DocumentCategory
  subcategory     String?
  title           String?          // User-friendly title
  description     String?
  
  // Metadata
  tags            String[]         @default([])
  
  // Expiration tracking
  expiresAt       DateTime?
  expirationAlert Boolean          @default(false)
  
  // Related entities
  vendorId        String?
  vendor          Vendor?          @relation(fields: [vendorId], references: [id])
  applianceId     String?          // Future: link to appliance inventory
  
  // Access
  uploadedById    String
  uploadedBy      User             @relation(fields: [uploadedById], references: [id])
  
  // Audit
  createdAt       DateTime         @default(now())
  updatedAt       DateTime         @updatedAt
  
  @@index([householdId])
  @@index([category])
  @@index([expiresAt])
}

enum DocumentCategory {
  PROPERTY          // Deed, survey, title, HOA
  INSURANCE         // Homeowners, auto, umbrella, life
  WARRANTY          // Appliance and system warranties
  MANUAL            // User manuals, guides
  TAX               // Property tax, assessments
  CONTRACT          // Vendor contracts, service agreements
  RECEIPT           // Invoices, receipts
  PERMIT            // Building permits, certificates
  OTHER
}
```

### Task 1.2: Update Household Model

Add relation:

```prisma
model Household {
  // ... existing fields
  documents Document[]
}
```

### Task 1.3: Update User Model

Add relation:

```prisma
model User {
  // ... existing fields
  uploadedDocuments Document[]
}
```

### Task 1.4: Run Migration

```bash
cd apps/api
pnpm prisma migrate dev --name add-document-vault
pnpm prisma generate
```

---

## PHASE 2: File Storage Setup

### Task 2.1: Create Storage Service

Create `apps/api/src/storage/storage.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Storage } from '@google-cloud/storage';
import { v4 as uuid } from 'uuid';

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private storage: Storage;
  private bucketName: string;

  constructor() {
    this.storage = new Storage();
    this.bucketName = process.env.GCS_BUCKET_NAME || 'haven-documents';
  }

  /**
   * Upload a file to Google Cloud Storage
   */
  async uploadFile(
    file: Express.Multer.File,
    householdId: string,
    category: string
  ): Promise<{ url: string; path: string }> {
    const fileExtension = file.originalname.split('.').pop();
    const fileName = `${uuid()}.${fileExtension}`;
    const filePath = `households/${householdId}/${category}/${fileName}`;

    const bucket = this.storage.bucket(this.bucketName);
    const blob = bucket.file(filePath);

    await blob.save(file.buffer, {
      metadata: {
        contentType: file.mimetype,
        metadata: {
          originalName: file.originalname,
          householdId,
          category,
        },
      },
    });

    // Make the file accessible (or use signed URLs for private access)
    // For now, we'll generate signed URLs when retrieving
    const url = `https://storage.googleapis.com/${this.bucketName}/${filePath}`;

    this.logger.log(`Uploaded file to ${filePath}`);

    return { url, path: filePath };
  }

  /**
   * Get a signed URL for temporary access
   */
  async getSignedUrl(filePath: string, expiresInMinutes = 60): Promise<string> {
    const bucket = this.storage.bucket(this.bucketName);
    const blob = bucket.file(filePath);

    const [url] = await blob.getSignedUrl({
      version: 'v4',
      action: 'read',
      expires: Date.now() + expiresInMinutes * 60 * 1000,
    });

    return url;
  }

  /**
   * Delete a file from storage
   */
  async deleteFile(filePath: string): Promise<void> {
    const bucket = this.storage.bucket(this.bucketName);
    const blob = bucket.file(filePath);

    await blob.delete();
    this.logger.log(`Deleted file ${filePath}`);
  }
}
```

### Task 2.2: Create Storage Module

Create `apps/api/src/storage/storage.module.ts`:

```typescript
import { Module, Global } from '@nestjs/common';
import { StorageService } from './storage.service';

@Global()
@Module({
  providers: [StorageService],
  exports: [StorageService],
})
export class StorageModule {}
```

### Task 2.3: Add to App Module

```typescript
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    // ... existing
    StorageModule,
  ],
})
```

---

## PHASE 3: Document Service & Controller

### Task 3.1: Create Document Service

Create `apps/api/src/document/document.service.ts`:

```typescript
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
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
    }
  ) {
    // Upload file to storage
    const { url, path } = await this.storage.uploadFile(
      file,
      householdId,
      data.category
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
          select: { id: true, name: true, firstName: true },
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
    }
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
          select: { id: true, name: true, firstName: true },
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
    const grouped = documents.reduce((acc, doc) => {
      if (!acc[doc.category]) {
        acc[doc.category] = [];
      }
      acc[doc.category].push(doc);
      return acc;
    }, {} as Record<string, typeof documents>);

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
      byCategory: byCategory.reduce((acc, item) => {
        acc[item.category] = item._count;
        return acc;
      }, {} as Record<string, number>),
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
          select: { id: true, name: true, firstName: true },
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
    }
  ) {
    return this.prisma.document.update({
      where: { id: documentId },
      data: {
        ...data,
        expirationAlert: data.expiresAt !== undefined ? !!data.expiresAt : undefined,
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
```

### Task 3.2: Create Document Controller

Create `apps/api/src/document/document.controller.ts`:

```typescript
import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { DocumentService } from './document.service';
import { DocumentCategory } from '@prisma/client';

@Controller('documents')
@UseGuards(FirebaseAuthGuard)
export class DocumentController {
  constructor(private documentService: DocumentService) {}

  @Post('household/:householdId/upload')
  @UseInterceptors(FileInterceptor('file'))
  async uploadDocument(
    @Request() req: any,
    @Param('householdId') householdId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() body: {
      category: DocumentCategory;
      subcategory?: string;
      title?: string;
      description?: string;
      tags?: string;
      expiresAt?: string;
      vendorId?: string;
    }
  ) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Parse tags if provided as comma-separated string
    const tags = body.tags ? body.tags.split(',').map(t => t.trim()) : undefined;

    return this.documentService.uploadDocument(
      householdId,
      req.user.userId || req.user.id,
      file,
      {
        category: body.category,
        subcategory: body.subcategory,
        title: body.title,
        description: body.description,
        tags,
        expiresAt: body.expiresAt ? new Date(body.expiresAt) : undefined,
        vendorId: body.vendorId,
      }
    );
  }

  @Get('household/:householdId')
  async getHouseholdDocuments(
    @Param('householdId') householdId: string,
    @Query('category') category?: DocumentCategory,
    @Query('search') search?: string,
    @Query('expiringWithinDays') expiringWithinDays?: string,
  ) {
    return this.documentService.getHouseholdDocuments(householdId, {
      category,
      search,
      expiringWithinDays: expiringWithinDays ? parseInt(expiringWithinDays) : undefined,
    });
  }

  @Get('household/:householdId/grouped')
  async getDocumentsByCategory(@Param('householdId') householdId: string) {
    return this.documentService.getDocumentsByCategory(householdId);
  }

  @Get('household/:householdId/summary')
  async getDocumentSummary(@Param('householdId') householdId: string) {
    return this.documentService.getDocumentSummary(householdId);
  }

  @Get('household/:householdId/expiring')
  async getExpiringDocuments(
    @Param('householdId') householdId: string,
    @Query('days') days?: string,
  ) {
    return this.documentService.getExpiringDocuments(
      householdId,
      days ? parseInt(days) : 30
    );
  }

  @Get(':documentId')
  async getDocument(
    @Param('documentId') documentId: string,
    @Query('householdId') householdId: string,
  ) {
    return this.documentService.getDocument(documentId, householdId);
  }

  @Put(':documentId')
  async updateDocument(
    @Param('documentId') documentId: string,
    @Body() body: {
      title?: string;
      description?: string;
      subcategory?: string;
      tags?: string[];
      expiresAt?: string | null;
      vendorId?: string | null;
    }
  ) {
    return this.documentService.updateDocument(documentId, {
      ...body,
      expiresAt: body.expiresAt ? new Date(body.expiresAt) : body.expiresAt === null ? null : undefined,
    });
  }

  @Delete(':documentId')
  async deleteDocument(
    @Param('documentId') documentId: string,
    @Query('householdId') householdId: string,
  ) {
    return this.documentService.deleteDocument(documentId, householdId);
  }
}
```

### Task 3.3: Create Document Module

Create `apps/api/src/document/document.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { DocumentController } from './document.controller';
import { DocumentService } from './document.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [DocumentController],
  providers: [DocumentService],
  exports: [DocumentService],
})
export class DocumentModule {}
```

### Task 3.4: Register Module & Configure Multer

Add to `apps/api/src/app.module.ts`:

```typescript
import { DocumentModule } from './document/document.module';
import { MulterModule } from '@nestjs/platform-express';

@Module({
  imports: [
    // ... existing
    MulterModule.register({
      limits: {
        fileSize: 25 * 1024 * 1024, // 25MB limit
      },
    }),
    DocumentModule,
  ],
})
```

---

## PHASE 4: Homeowner UI

### Task 4.1: Create Document Vault Page

Create `apps/web/src/app/app/vault/page.tsx`:

```typescript
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  FileText,
  Upload,
  Search,
  Folder,
  File,
  Calendar,
  AlertTriangle,
  Download,
  Trash2,
  Plus,
  X,
  Loader2,
  Home,
  Shield,
  Receipt,
  BookOpen,
  FileCheck,
  FolderOpen,
} from 'lucide-react';

interface Document {
  id: string;
  fileName: string;
  originalName: string;
  mimeType: string;
  fileSize: number;
  category: string;
  title: string;
  description: string;
  tags: string[];
  expiresAt: string | null;
  createdAt: string;
  downloadUrl?: string;
  uploadedBy: { id: string; name: string; firstName: string };
}

interface DocumentSummary {
  total: number;
  byCategory: Record<string, number>;
  expiringSoon: number;
  expired: number;
}

const categoryConfig: Record<string, { icon: any; label: string; color: string }> = {
  PROPERTY: { icon: Home, label: 'Property', color: 'bg-blue-100 text-blue-700' },
  INSURANCE: { icon: Shield, label: 'Insurance', color: 'bg-green-100 text-green-700' },
  WARRANTY: { icon: FileCheck, label: 'Warranty', color: 'bg-purple-100 text-purple-700' },
  MANUAL: { icon: BookOpen, label: 'Manual', color: 'bg-orange-100 text-orange-700' },
  TAX: { icon: Receipt, label: 'Tax', color: 'bg-red-100 text-red-700' },
  CONTRACT: { icon: FileText, label: 'Contract', color: 'bg-indigo-100 text-indigo-700' },
  RECEIPT: { icon: Receipt, label: 'Receipt', color: 'bg-yellow-100 text-yellow-700' },
  PERMIT: { icon: FileCheck, label: 'Permit', color: 'bg-cyan-100 text-cyan-700' },
  OTHER: { icon: File, label: 'Other', color: 'bg-gray-100 text-gray-700' },
};

export default function VaultPage() {
  const { user } = useAuth();
  const [documents, setDocuments] = useState<Document[]>([]);
  const [summary, setSummary] = useState<DocumentSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');
  const [showUpload, setShowUpload] = useState(false);
  const [uploading, setUploading] = useState(false);

  // Upload form state
  const [uploadFile, setUploadFile] = useState<File | null>(null);
  const [uploadCategory, setUploadCategory] = useState<string>('OTHER');
  const [uploadTitle, setUploadTitle] = useState('');
  const [uploadDescription, setUploadDescription] = useState('');
  const [uploadExpires, setUploadExpires] = useState('');

  const householdId = user?.householdId;

  useEffect(() => {
    if (householdId) {
      loadData();
    }
  }, [householdId, selectedCategory, searchQuery]);

  const loadData = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const params = new URLSearchParams();
      if (selectedCategory) params.append('category', selectedCategory);
      if (searchQuery) params.append('search', searchQuery);

      const [docsRes, summaryRes] = await Promise.all([
        fetch(`${apiUrl}/documents/household/${householdId}?${params}`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${apiUrl}/documents/household/${householdId}/summary`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (docsRes.ok) setDocuments(await docsRes.json());
      if (summaryRes.ok) setSummary(await summaryRes.json());
    } catch (error) {
      console.error('Failed to load documents:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleUpload = async () => {
    if (!uploadFile || !householdId) return;

    try {
      setUploading(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const formData = new FormData();
      formData.append('file', uploadFile);
      formData.append('category', uploadCategory);
      if (uploadTitle) formData.append('title', uploadTitle);
      if (uploadDescription) formData.append('description', uploadDescription);
      if (uploadExpires) formData.append('expiresAt', uploadExpires);

      const response = await fetch(`${apiUrl}/documents/household/${householdId}/upload`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: formData,
      });

      if (response.ok) {
        setShowUpload(false);
        setUploadFile(null);
        setUploadTitle('');
        setUploadDescription('');
        setUploadExpires('');
        loadData();
      }
    } catch (error) {
      console.error('Upload failed:', error);
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (documentId: string) => {
    if (!confirm('Are you sure you want to delete this document?')) return;

    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/documents/${documentId}?householdId=${householdId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });

      loadData();
    } catch (error) {
      console.error('Delete failed:', error);
    }
  };

  const handleDownload = async (doc: Document) => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/documents/${doc.id}?householdId=${householdId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        const data = await response.json();
        window.open(data.downloadUrl, '_blank');
      }
    } catch (error) {
      console.error('Download failed:', error);
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const isExpiringSoon = (expiresAt: string | null) => {
    if (!expiresAt) return false;
    const expires = new Date(expiresAt);
    const thirtyDays = new Date();
    thirtyDays.setDate(thirtyDays.getDate() + 30);
    return expires <= thirtyDays && expires > new Date();
  };

  const isExpired = (expiresAt: string | null) => {
    if (!expiresAt) return false;
    return new Date(expiresAt) < new Date();
  };

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file) {
      setUploadFile(file);
      setUploadTitle(file.name.replace(/\.[^/.]+$/, ''));
      setShowUpload(true);
    }
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Document Vault</h1>
          <p className="text-gray-500">Securely store your home documents</p>
        </div>
        <button
          onClick={() => setShowUpload(true)}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
        >
          <Plus className="w-4 h-4" />
          Upload
        </button>
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                <FileText className="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{summary.total}</p>
                <p className="text-sm text-gray-500">Total Documents</p>
              </div>
            </div>
          </div>

          {summary.expiringSoon > 0 && (
            <div className="bg-white rounded-xl border border-amber-200 p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
                  <Calendar className="w-5 h-5 text-amber-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">{summary.expiringSoon}</p>
                  <p className="text-sm text-gray-500">Expiring Soon</p>
                </div>
              </div>
            </div>
          )}

          {summary.expired > 0 && (
            <div className="bg-white rounded-xl border border-red-200 p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
                  <AlertTriangle className="w-5 h-5 text-red-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">{summary.expired}</p>
                  <p className="text-sm text-gray-500">Expired</p>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-4">
        <div className="flex-1 min-w-[200px]">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search documents..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
        </div>
        <select
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          className="px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="">All Categories</option>
          {Object.entries(categoryConfig).map(([key, config]) => (
            <option key={key} value={key}>{config.label}</option>
          ))}
        </select>
      </div>

      {/* Drop Zone */}
      <div
        onDrop={handleDrop}
        onDragOver={(e) => e.preventDefault()}
        className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center hover:border-indigo-400 transition-colors cursor-pointer"
        onClick={() => setShowUpload(true)}
      >
        <Upload className="w-10 h-10 text-gray-400 mx-auto mb-2" />
        <p className="text-gray-600">Drag and drop files here, or click to upload</p>
        <p className="text-sm text-gray-400 mt-1">Supports PDF, images, and documents up to 25MB</p>
      </div>

      {/* Document List */}
      {documents.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <FolderOpen className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900">No documents yet</h3>
          <p className="text-gray-500">Upload your first document to get started</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="divide-y divide-gray-100">
            {documents.map((doc) => {
              const config = categoryConfig[doc.category] || categoryConfig.OTHER;
              const Icon = config.icon;
              const expiringSoon = isExpiringSoon(doc.expiresAt);
              const expired = isExpired(doc.expiresAt);

              return (
                <div
                  key={doc.id}
                  className="p-4 hover:bg-gray-50 flex items-center gap-4"
                >
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${config.color}`}>
                    <Icon className="w-5 h-5" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h3 className="font-medium text-gray-900 truncate">{doc.title}</h3>
                      {expired && (
                        <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded">
                          Expired
                        </span>
                      )}
                      {expiringSoon && !expired && (
                        <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded">
                          Expiring Soon
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-3 mt-1 text-sm text-gray-500">
                      <span>{config.label}</span>
                      <span>•</span>
                      <span>{formatFileSize(doc.fileSize)}</span>
                      <span>•</span>
                      <span>{formatDate(doc.createdAt)}</span>
                      {doc.expiresAt && (
                        <>
                          <span>•</span>
                          <span>Expires: {formatDate(doc.expiresAt)}</span>
                        </>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleDownload(doc)}
                      className="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
                      title="Download"
                    >
                      <Download className="w-5 h-5" />
                    </button>
                    <button
                      onClick={() => handleDelete(doc.id)}
                      className="p-2 text-gray-400 hover:text-red-600 rounded-lg hover:bg-red-50"
                      title="Delete"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Upload Modal */}
      {showUpload && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-md">
            <div className="flex items-center justify-between p-4 border-b border-gray-200">
              <h2 className="text-lg font-semibold">Upload Document</h2>
              <button
                onClick={() => setShowUpload(false)}
                className="p-1 hover:bg-gray-100 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-4 space-y-4">
              {/* File Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  File
                </label>
                <input
                  type="file"
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (file) {
                      setUploadFile(file);
                      if (!uploadTitle) {
                        setUploadTitle(file.name.replace(/\.[^/.]+$/, ''));
                      }
                    }
                  }}
                  className="w-full"
                />
                {uploadFile && (
                  <p className="text-sm text-gray-500 mt-1">
                    {uploadFile.name} ({formatFileSize(uploadFile.size)})
                  </p>
                )}
              </div>

              {/* Category */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Category
                </label>
                <select
                  value={uploadCategory}
                  onChange={(e) => setUploadCategory(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg"
                >
                  {Object.entries(categoryConfig).map(([key, config]) => (
                    <option key={key} value={key}>{config.label}</option>
                  ))}
                </select>
              </div>

              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Title
                </label>
                <input
                  type="text"
                  value={uploadTitle}
                  onChange={(e) => setUploadTitle(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg"
                  placeholder="Document title"
                />
              </div>

              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description (optional)
                </label>
                <textarea
                  value={uploadDescription}
                  onChange={(e) => setUploadDescription(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg"
                  rows={2}
                  placeholder="Brief description"
                />
              </div>

              {/* Expiration */}
              {['WARRANTY', 'INSURANCE', 'CONTRACT', 'PERMIT'].includes(uploadCategory) && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Expiration Date (optional)
                  </label>
                  <input
                    type="date"
                    value={uploadExpires}
                    onChange={(e) => setUploadExpires(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-lg"
                  />
                </div>
              )}
            </div>

            <div className="flex gap-3 p-4 border-t border-gray-200">
              <button
                onClick={() => setShowUpload(false)}
                className="flex-1 px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleUpload}
                disabled={!uploadFile || uploading}
                className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50"
              >
                {uploading ? 'Uploading...' : 'Upload'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

### Task 4.2: Add to Navigation

Update homeowner sidebar to include "Document Vault" link to `/app/vault`.

---

## PHASE 5: GCS Bucket Setup

### Task 5.1: Create GCS Bucket (if not exists)

```bash
# Create bucket
gsutil mb -l us-east1 gs://haven-documents

# Set CORS for web uploads
gsutil cors set cors.json gs://haven-documents

# Enable uniform bucket-level access
gsutil uniformbucketlevelaccess set on gs://haven-documents
```

### Task 5.2: Add Environment Variable

Add to `.env` and Cloud Run:

```
GCS_BUCKET_NAME=haven-documents
```

---

## PHASE 6: Update Tests

Add document endpoint tests to test suite:

```typescript
async function testDocumentVault(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  const homeownerToken = await getFirebaseToken(CREDENTIALS.homeowner.email, CREDENTIALS.homeowner.password);
  
  if (!homeownerToken) {
    tests.push({ name: 'Document vault', passed: false, skipped: true, error: 'No token' });
    return { name: 'Document Vault', tests };
  }

  // Get household ID
  let response = await apiRequest('GET', '/user/me', homeownerToken);
  const householdId = response.data?.householdId;

  if (!householdId) {
    tests.push({ name: 'Document vault', passed: false, skipped: true, error: 'No household' });
    return { name: 'Document Vault', tests };
  }

  // GET /documents/household/:id
  let start = Date.now();
  response = await apiRequest('GET', `/documents/household/${householdId}`, homeownerToken);
  tests.push({
    name: 'GET /documents/household/:id',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // GET /documents/household/:id/summary
  start = Date.now();
  response = await apiRequest('GET', `/documents/household/${householdId}/summary`, homeownerToken);
  tests.push({
    name: 'GET /documents/household/:id/summary',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Document Vault', tests };
}
```

---

## PHASE 7: Build, Deploy, Test

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Install GCS SDK if needed
cd apps/api
pnpm add @google-cloud/storage

# Migration
pnpm prisma migrate dev --name add-document-vault
pnpm prisma generate

# Build
cd ../..
pnpm build

# Deploy
git add .
git commit -m "feat: document vault for secure file storage"
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616

# Test
pnpm test:e2e
```

---

## Summary

After this prompt:
1. ✅ Document model with categories and expiration tracking
2. ✅ Google Cloud Storage integration
3. ✅ API endpoints for upload, download, list, delete
4. ✅ Homeowner UI at /app/vault
5. ✅ Drag-and-drop upload
6. ✅ Category organization
7. ✅ Expiration alerts

**User can now:** Upload deeds, warranties, insurance policies, receipts - all organized and with expiration tracking.
