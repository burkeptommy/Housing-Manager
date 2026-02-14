import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Storage } from '@google-cloud/storage';
import { v4 as uuidv4 } from 'uuid';

export interface SignedUrlResult {
  signedUrl: string;
  gcsPath: string;
  publicUrl: string;
}

@Injectable()
export class GcsStorageService {
  private readonly logger = new Logger(GcsStorageService.name);
  private readonly storage: Storage;
  private readonly bucketName: string;

  constructor(private readonly configService: ConfigService) {
    this.bucketName = this.configService.get<string>('GCS_BUCKET') || 'haven-uploads';

    // Initialize GCS client
    // In production, this will use Application Default Credentials
    // For local dev, you may need GOOGLE_APPLICATION_CREDENTIALS env var
    this.storage = new Storage();
  }

  /**
   * Generate a unique GCS path for a file
   */
  generateGcsPath(householdId: string, filename: string): string {
    const ext = filename.split('.').pop() || '';
    const uniqueId = uuidv4();
    const safeName = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
    return `uploads/${householdId}/${uniqueId}-${safeName}`;
  }

  /**
   * Generate a signed URL for uploading a file directly to GCS
   */
  async generateSignedUploadUrl(
    gcsPath: string,
    contentType: string,
    expiresInMinutes: number = 15,
  ): Promise<SignedUrlResult> {
    const bucket = this.storage.bucket(this.bucketName);
    const file = bucket.file(gcsPath);

    try {
      const [signedUrl] = await file.getSignedUrl({
        version: 'v4',
        action: 'write',
        expires: Date.now() + expiresInMinutes * 60 * 1000,
        contentType,
      });

      // Public URL (if bucket is configured for public access) or use signed URL for reads
      const publicUrl = `https://storage.googleapis.com/${this.bucketName}/${gcsPath}`;

      return {
        signedUrl,
        gcsPath,
        publicUrl,
      };
    } catch (error) {
      this.logger.error(`Failed to generate signed URL: ${error}`);
      throw error;
    }
  }

  /**
   * Generate a signed URL for reading a file from GCS
   */
  async generateSignedReadUrl(
    gcsPath: string,
    expiresInMinutes: number = 60,
  ): Promise<string> {
    const bucket = this.storage.bucket(this.bucketName);
    const file = bucket.file(gcsPath);

    try {
      const [signedUrl] = await file.getSignedUrl({
        version: 'v4',
        action: 'read',
        expires: Date.now() + expiresInMinutes * 60 * 1000,
      });

      return signedUrl;
    } catch (error) {
      this.logger.error(`Failed to generate read URL: ${error}`);
      throw error;
    }
  }

  /**
   * Check if a file exists in GCS
   */
  async fileExists(gcsPath: string): Promise<boolean> {
    const bucket = this.storage.bucket(this.bucketName);
    const file = bucket.file(gcsPath);

    try {
      const [exists] = await file.exists();
      return exists;
    } catch (error) {
      this.logger.error(`Failed to check file existence: ${error}`);
      return false;
    }
  }

  /**
   * Get file metadata from GCS
   */
  async getFileMetadata(gcsPath: string): Promise<{
    size: number;
    contentType: string;
  } | null> {
    const bucket = this.storage.bucket(this.bucketName);
    const file = bucket.file(gcsPath);

    try {
      const [metadata] = await file.getMetadata();
      return {
        size: parseInt(metadata.size as string, 10),
        contentType: metadata.contentType as string,
      };
    } catch (error) {
      this.logger.error(`Failed to get file metadata: ${error}`);
      return null;
    }
  }

  /**
   * Delete a file from GCS
   */
  async deleteFile(gcsPath: string): Promise<boolean> {
    const bucket = this.storage.bucket(this.bucketName);
    const file = bucket.file(gcsPath);

    try {
      await file.delete();
      return true;
    } catch (error) {
      this.logger.error(`Failed to delete file: ${error}`);
      return false;
    }
  }

  /**
   * Upload a buffer directly to GCS and return the public URL
   */
  async uploadBuffer(
    gcsPath: string,
    buffer: Buffer,
    contentType: string,
    makePublic: boolean = true,
  ): Promise<string> {
    const bucket = this.storage.bucket(this.bucketName);
    const file = bucket.file(gcsPath);

    try {
      await file.save(buffer, {
        contentType,
        public: makePublic,
        metadata: {
          cacheControl: 'public, max-age=31536000',
        },
      });

      if (makePublic) {
        return `https://storage.googleapis.com/${this.bucketName}/${gcsPath}`;
      }

      // Return signed URL if not public
      return this.generateSignedReadUrl(gcsPath, 60 * 24 * 7); // 7 days
    } catch (error) {
      this.logger.error(`Failed to upload buffer: ${error}`);
      throw error;
    }
  }

  /**
   * Generate a profile photo path
   */
  generateProfilePhotoPath(
    entityType: 'family-member' | 'pet' | 'household' | 'user' | 'vehicle',
    entityId: string,
  ): string {
    const uniqueId = uuidv4().slice(0, 8);
    return `profiles/${entityType}/${entityId}-${uniqueId}.jpg`;
  }
}
