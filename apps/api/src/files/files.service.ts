import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { FileCategory } from '@prisma/client';

import { PrismaService } from '../prisma';
import { JwtPayload } from '../auth';

import { StorageService } from './storage.service';
import { UploadFileDto, FileDto, FileWithUrlDto } from './dto';

const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
];

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

@Injectable()
export class FilesService {
  private readonly logger = new Logger(FilesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
  ) {}

  /**
   * Upload a file to GCS and store metadata in the database
   */
  async upload(
    file: Express.Multer.File,
    dto: UploadFileDto,
    user: JwtPayload,
  ): Promise<FileDto> {
    // Validate storage is ready
    if (!this.storageService.isReady()) {
      throw new BadRequestException('File storage is not configured');
    }

    // Validate file
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `File type not allowed. Allowed types: ${ALLOWED_MIME_TYPES.join(', ')}`,
      );
    }

    if (file.size > MAX_FILE_SIZE) {
      throw new BadRequestException(
        `File too large. Maximum size: ${MAX_FILE_SIZE / 1024 / 1024} MB`,
      );
    }

    // Verify user has access to household
    await this.verifyHouseholdAccess(dto.householdId, user);

    // If service request ID provided, verify it belongs to household
    if (dto.serviceRequestId) {
      const request = await this.prisma.serviceRequest.findFirst({
        where: {
          id: dto.serviceRequestId,
          householdId: dto.householdId,
        },
      });
      if (!request) {
        throw new NotFoundException('Service request not found in household');
      }
    }

    // If task ID provided, verify it belongs to household
    if (dto.taskId) {
      const task = await this.prisma.task.findFirst({
        where: {
          id: dto.taskId,
          householdId: dto.householdId,
        },
      });
      if (!task) {
        throw new NotFoundException('Task not found in household');
      }
    }

    // Determine folder based on category
    const category = dto.category || FileCategory.IMAGE;
    const folder = `households/${dto.householdId}/${category.toLowerCase()}`;

    // Upload to GCS
    const uploadResult = await this.storageService.uploadBuffer(file.buffer, {
      filename: file.originalname,
      mimeType: file.mimetype,
      folder,
    });

    // Store metadata in database
    const fileRecord = await this.prisma.file.create({
      data: {
        filename: uploadResult.filename,
        originalName: file.originalname,
        mimeType: file.mimetype,
        size: file.size,
        gcsUri: uploadResult.gcsUri,
        category,
        description: dto.description,
        userId: user.sub,
        householdId: dto.householdId,
        serviceRequestId: dto.serviceRequestId,
        taskId: dto.taskId,
      },
    });

    this.logger.log(`File uploaded: ${fileRecord.id} for household ${dto.householdId}`);

    return this.toFileDto(fileRecord);
  }

  /**
   * Get file by ID with signed URL
   */
  async getFile(id: string, user: JwtPayload): Promise<FileWithUrlDto> {
    const file = await this.prisma.file.findUnique({
      where: { id },
    });

    if (!file) {
      throw new NotFoundException('File not found');
    }

    // Verify access
    if (file.householdId) {
      await this.verifyHouseholdAccess(file.householdId, user);
    } else if (file.userId !== user.sub) {
      throw new ForbiddenException('Not authorized to access this file');
    }

    // Generate signed URL
    let signedUrl: string | undefined;
    if (file.gcsUri && this.storageService.isReady()) {
      signedUrl = await this.storageService.getSignedUrl(file.gcsUri, 60);
    }

    return {
      ...this.toFileDto(file),
      url: signedUrl || file.url || '',
    };
  }

  /**
   * Get signed URL for a file
   */
  async getSignedUrl(id: string, user: JwtPayload): Promise<string> {
    const file = await this.getFile(id, user);
    return file.url;
  }

  /**
   * Get files for a household
   */
  async getHouseholdFiles(
    householdId: string,
    user: JwtPayload,
    category?: FileCategory,
  ): Promise<FileDto[]> {
    await this.verifyHouseholdAccess(householdId, user);

    const files = await this.prisma.file.findMany({
      where: {
        householdId,
        ...(category && { category }),
      },
      orderBy: { createdAt: 'desc' },
    });

    return files.map((f) => this.toFileDto(f));
  }

  /**
   * Get files for a service request
   */
  async getServiceRequestFiles(
    serviceRequestId: string,
    user: JwtPayload,
  ): Promise<FileWithUrlDto[]> {
    const request = await this.prisma.serviceRequest.findUnique({
      where: { id: serviceRequestId },
    });

    if (!request) {
      throw new NotFoundException('Service request not found');
    }

    await this.verifyHouseholdAccess(request.householdId, user);

    const files = await this.prisma.file.findMany({
      where: { serviceRequestId },
      orderBy: { createdAt: 'desc' },
    });

    // Generate signed URLs for all files
    const filesWithUrls = await Promise.all(
      files.map(async (f) => {
        let signedUrl: string | undefined;
        if (f.gcsUri && this.storageService.isReady()) {
          signedUrl = await this.storageService.getSignedUrl(f.gcsUri, 60);
        }
        return {
          ...this.toFileDto(f),
          url: signedUrl || f.url || '',
        };
      }),
    );

    return filesWithUrls;
  }

  /**
   * Delete a file
   */
  async deleteFile(id: string, user: JwtPayload): Promise<void> {
    const file = await this.prisma.file.findUnique({
      where: { id },
    });

    if (!file) {
      throw new NotFoundException('File not found');
    }

    // Verify access
    if (file.householdId) {
      await this.verifyHouseholdAccess(file.householdId, user);
    } else if (file.userId !== user.sub) {
      throw new ForbiddenException('Not authorized to delete this file');
    }

    // Delete from GCS
    if (file.gcsUri && this.storageService.isReady()) {
      await this.storageService.deleteFile(file.gcsUri);
    }

    // Delete from database
    await this.prisma.file.delete({
      where: { id },
    });

    this.logger.log(`File deleted: ${id}`);
  }

  /**
   * Verify user has access to household
   */
  private async verifyHouseholdAccess(
    householdId: string,
    user: JwtPayload,
  ): Promise<void> {
    // Admins and managers have full access
    if (user.role === 'ADMIN' || user.role === 'MANAGER') {
      return;
    }

    const membership = await this.prisma.householdMember.findFirst({
      where: {
        householdId,
        userId: user.sub,
        status: 'ACTIVE',
      },
    });

    if (!membership) {
      throw new ForbiddenException('Not a member of this household');
    }
  }

  private toFileDto(file: any): FileDto {
    return {
      id: file.id,
      filename: file.filename,
      originalName: file.originalName,
      mimeType: file.mimeType,
      size: file.size,
      url: file.url,
      category: file.category,
      description: file.description,
      householdId: file.householdId,
      serviceRequestId: file.serviceRequestId,
      taskId: file.taskId,
      createdAt: file.createdAt,
    };
  }
}
