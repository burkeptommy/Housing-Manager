import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { FileAssetType, FileAssetStatus } from '@prisma/client';

import { PrismaService } from '../prisma';
import { GcsStorageService } from './gcs-storage.service';

export interface SignUploadRequest {
  fileName: string;
  contentType: string;
  type: FileAssetType;
  householdId: string;
}

export interface SignUploadResponse {
  fileAssetId: string;
  signedUrl: string;
  gcsPath: string;
  publicUrl: string;
}

@Injectable()
export class UploadsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly gcsStorage: GcsStorageService,
  ) {}

  /**
   * Generate a signed URL for uploading a file and create a pending FileAsset
   */
  async signUpload(
    data: SignUploadRequest,
    userId: string,
  ): Promise<SignUploadResponse> {
    // Validate content type
    const allowedTypes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    ];

    if (!allowedTypes.includes(data.contentType)) {
      throw new BadRequestException(
        `Content type ${data.contentType} is not allowed`,
      );
    }

    // Generate GCS path
    const gcsPath = this.gcsStorage.generateGcsPath(
      data.householdId,
      data.fileName,
    );

    // Generate signed URL
    const signedResult = await this.gcsStorage.generateSignedUploadUrl(
      gcsPath,
      data.contentType,
    );

    // Create pending FileAsset
    const fileAsset = await this.prisma.fileAsset.create({
      data: {
        householdId: data.householdId,
        uploaderUserId: userId,
        type: data.type,
        status: FileAssetStatus.PENDING,
        gcsPath: signedResult.gcsPath,
        url: signedResult.publicUrl,
        filename: data.fileName,
        contentType: data.contentType,
      },
    });

    return {
      fileAssetId: fileAsset.id,
      signedUrl: signedResult.signedUrl,
      gcsPath: signedResult.gcsPath,
      publicUrl: signedResult.publicUrl,
    };
  }

  /**
   * Mark a file upload as complete after the client has uploaded to GCS
   */
  async completeUpload(
    fileAssetId: string,
    userId: string,
    finalUrl?: string,
  ): Promise<{ id: string; url: string; status: FileAssetStatus }> {
    const fileAsset = await this.prisma.fileAsset.findUnique({
      where: { id: fileAssetId },
    });

    if (!fileAsset) {
      throw new NotFoundException('FileAsset not found');
    }

    if (fileAsset.uploaderUserId !== userId) {
      throw new ForbiddenException(
        'You can only complete uploads you started',
      );
    }

    if (fileAsset.status !== FileAssetStatus.PENDING) {
      throw new BadRequestException('Upload already completed or failed');
    }

    // Check if file exists in GCS
    const exists = await this.gcsStorage.fileExists(fileAsset.gcsPath);
    if (!exists) {
      // Mark as failed
      await this.prisma.fileAsset.update({
        where: { id: fileAssetId },
        data: { status: FileAssetStatus.FAILED },
      });
      throw new BadRequestException(
        'File was not uploaded to storage. Please try again.',
      );
    }

    // Get file metadata to update size
    const metadata = await this.gcsStorage.getFileMetadata(fileAsset.gcsPath);

    // Update FileAsset to uploaded status
    const updated = await this.prisma.fileAsset.update({
      where: { id: fileAssetId },
      data: {
        status: FileAssetStatus.UPLOADED,
        url: finalUrl || fileAsset.url,
        size: metadata?.size || null,
      },
    });

    return {
      id: updated.id,
      url: updated.url || '',
      status: updated.status,
    };
  }

  /**
   * Get a FileAsset by ID
   */
  async getFileAsset(fileAssetId: string, userId: string) {
    const fileAsset = await this.prisma.fileAsset.findUnique({
      where: { id: fileAssetId },
      include: {
        household: {
          include: {
            members: {
              where: { userId },
              select: { id: true },
            },
          },
        },
      },
    });

    if (!fileAsset) {
      throw new NotFoundException('FileAsset not found');
    }

    // Check access: uploader, household member, manager, or admin
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    const isUploader = fileAsset.uploaderUserId === userId;
    const isHouseholdMember = fileAsset.household.members.length > 0;
    const isStaff = user?.role === 'MANAGER' || user?.role === 'ADMIN';

    if (!isUploader && !isHouseholdMember && !isStaff) {
      throw new ForbiddenException('You do not have access to this file');
    }

    return fileAsset;
  }

  /**
   * Get a signed read URL for a file
   */
  async getSignedReadUrl(
    fileAssetId: string,
    userId: string,
  ): Promise<string> {
    const fileAsset = await this.getFileAsset(fileAssetId, userId);

    if (fileAsset.status !== FileAssetStatus.UPLOADED) {
      throw new BadRequestException('File is not available');
    }

    return this.gcsStorage.generateSignedReadUrl(fileAsset.gcsPath);
  }

  /**
   * Delete a FileAsset and its GCS file
   */
  async deleteFileAsset(fileAssetId: string, userId: string): Promise<void> {
    const fileAsset = await this.getFileAsset(fileAssetId, userId);

    // Only uploader or staff can delete
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    const isUploader = fileAsset.uploaderUserId === userId;
    const isStaff = user?.role === 'MANAGER' || user?.role === 'ADMIN';

    if (!isUploader && !isStaff) {
      throw new ForbiddenException('You cannot delete this file');
    }

    // Delete from GCS
    await this.gcsStorage.deleteFile(fileAsset.gcsPath);

    // Delete from database
    await this.prisma.fileAsset.delete({
      where: { id: fileAssetId },
    });
  }

  /**
   * Upload a profile image for an entity (family member, pet, or household)
   */
  async uploadProfileImage(
    entityType: 'family-member' | 'pet' | 'household',
    entityId: string,
    base64Image: string,
    mimeType: string,
    userId: string,
  ): Promise<{ imageUrl: string }> {
    // Convert base64 to buffer
    const buffer = Buffer.from(base64Image, 'base64');

    // Generate GCS path
    const gcsPath = this.gcsStorage.generateProfilePhotoPath(entityType, entityId);

    // Upload to GCS
    let imageUrl: string;
    try {
      imageUrl = await this.gcsStorage.uploadBuffer(gcsPath, buffer, mimeType);
    } catch {
      // Fallback: use UI Avatars if GCS is not configured
      imageUrl = `https://ui-avatars.com/api/?name=${entityId.slice(0, 2)}&background=c4a574&color=fff&size=256`;
    }

    // Update the entity with the new image URL
    switch (entityType) {
      case 'family-member':
        await this.prisma.familyMember.update({
          where: { id: entityId },
          data: { profilePhotoUrl: imageUrl },
        });
        break;
      case 'pet':
        // Pet uses photoUrls array - prepend the new photo
        const pet = await this.prisma.pet.findUnique({
          where: { id: entityId },
          select: { photoUrls: true },
        });
        const existingPhotos = pet?.photoUrls || [];
        await this.prisma.pet.update({
          where: { id: entityId },
          data: { photoUrls: [imageUrl, ...existingPhotos.slice(0, 9)] }, // Keep max 10 photos
        });
        break;
      case 'household':
        await this.prisma.household.update({
          where: { id: entityId },
          data: { propertyPhotoUrl: imageUrl },
        });
        break;
    }

    return { imageUrl };
  }

  /**
   * Remove a profile image from an entity
   */
  async removeProfileImage(
    entityType: 'family-member' | 'pet' | 'household',
    entityId: string,
    userId: string,
  ): Promise<{ success: boolean }> {
    // Update the entity to remove the image URL
    switch (entityType) {
      case 'family-member':
        await this.prisma.familyMember.update({
          where: { id: entityId },
          data: { profilePhotoUrl: null },
        });
        break;
      case 'pet':
        // For pets, we clear the first photo (profile photo)
        const pet = await this.prisma.pet.findUnique({
          where: { id: entityId },
          select: { photoUrls: true },
        });
        if (pet?.photoUrls && pet.photoUrls.length > 0) {
          await this.prisma.pet.update({
            where: { id: entityId },
            data: { photoUrls: pet.photoUrls.slice(1) }, // Remove first photo
          });
        }
        break;
      case 'household':
        await this.prisma.household.update({
          where: { id: entityId },
          data: { propertyPhotoUrl: null },
        });
        break;
    }

    return { success: true };
  }
}
