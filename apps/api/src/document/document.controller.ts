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
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
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
    @Body()
    body: {
      category: DocumentCategory;
      subcategory?: string;
      title?: string;
      description?: string;
      tags?: string;
      expiresAt?: string;
      vendorId?: string;
    },
  ) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Parse tags if provided as comma-separated string
    const tags = body.tags ? body.tags.split(',').map((t) => t.trim()) : undefined;

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
      },
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
      expiringWithinDays: expiringWithinDays
        ? parseInt(expiringWithinDays)
        : undefined,
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
      days ? parseInt(days) : 30,
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
    @Body()
    body: {
      title?: string;
      description?: string;
      subcategory?: string;
      tags?: string[];
      expiresAt?: string | null;
      vendorId?: string | null;
    },
  ) {
    return this.documentService.updateDocument(documentId, {
      ...body,
      expiresAt: body.expiresAt
        ? new Date(body.expiresAt)
        : body.expiresAt === null
          ? null
          : undefined,
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
