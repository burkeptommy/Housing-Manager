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
    this.bucketName = process.env.GCS_BUCKET_NAME || 'haven-documents-480616';
  }

  /**
   * Upload a file to Google Cloud Storage
   */
  async uploadFile(
    file: Express.Multer.File,
    householdId: string,
    category: string,
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
  async getSignedUrl(
    filePath: string,
    expiresInMinutes = 60,
  ): Promise<string> {
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

    try {
      await blob.delete();
      this.logger.log(`Deleted file ${filePath}`);
    } catch (error) {
      this.logger.warn(`Failed to delete file ${filePath}: ${error}`);
      // Don't throw - file may already be deleted
    }
  }
}
