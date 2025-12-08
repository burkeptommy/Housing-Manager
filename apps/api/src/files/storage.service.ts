import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Storage, Bucket, GetSignedUrlConfig } from '@google-cloud/storage';
import { Readable } from 'stream';

export interface UploadOptions {
  filename: string;
  mimeType: string;
  folder?: string;
}

export interface UploadResult {
  gcsUri: string;
  publicUrl?: string;
  filename: string;
}

@Injectable()
export class StorageService implements OnModuleInit {
  private readonly logger = new Logger(StorageService.name);
  private storage: Storage;
  private bucket: Bucket;
  private bucketName: string;
  private isConfigured = false;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    this.bucketName = this.configService.get<string>('GCS_BUCKET_NAME', '');

    if (!this.bucketName) {
      this.logger.warn(
        'GCS_BUCKET_NAME not configured. File uploads will fail.',
      );
      return;
    }

    try {
      // Check for credentials file or use Application Default Credentials
      const keyFilename = this.configService.get<string>('GCS_KEY_FILE');
      const projectId = this.configService.get<string>('GCP_PROJECT_ID');

      const storageConfig: { projectId?: string; keyFilename?: string } = {};
      if (projectId) storageConfig.projectId = projectId;
      if (keyFilename) storageConfig.keyFilename = keyFilename;

      this.storage = new Storage(storageConfig);
      this.bucket = this.storage.bucket(this.bucketName);

      // Verify bucket exists
      const [exists] = await this.bucket.exists();
      if (!exists) {
        this.logger.warn(`GCS bucket "${this.bucketName}" does not exist.`);
        return;
      }

      this.isConfigured = true;
      this.logger.log(`GCS storage configured with bucket: ${this.bucketName}`);
    } catch (error) {
      this.logger.error('Failed to initialize GCS storage', error);
    }
  }

  isReady(): boolean {
    return this.isConfigured;
  }

  /**
   * Upload a file buffer to GCS
   */
  async uploadBuffer(
    buffer: Buffer,
    options: UploadOptions,
  ): Promise<UploadResult> {
    if (!this.isConfigured) {
      throw new Error('GCS storage is not configured');
    }

    const folder = options.folder || 'uploads';
    const timestamp = Date.now();
    const safeName = options.filename.replace(/[^a-zA-Z0-9.-]/g, '_');
    const gcsFilename = `${folder}/${timestamp}-${safeName}`;

    const file = this.bucket.file(gcsFilename);

    await new Promise<void>((resolve, reject) => {
      const stream = file.createWriteStream({
        metadata: {
          contentType: options.mimeType,
        },
        resumable: false,
      });

      stream.on('error', reject);
      stream.on('finish', resolve);

      const readable = Readable.from(buffer);
      readable.pipe(stream);
    });

    const gcsUri = `gs://${this.bucketName}/${gcsFilename}`;

    this.logger.log(`File uploaded to ${gcsUri}`);

    return {
      gcsUri,
      filename: gcsFilename,
    };
  }

  /**
   * Upload a file from a stream to GCS
   */
  async uploadStream(
    stream: Readable,
    options: UploadOptions,
  ): Promise<UploadResult> {
    if (!this.isConfigured) {
      throw new Error('GCS storage is not configured');
    }

    const folder = options.folder || 'uploads';
    const timestamp = Date.now();
    const safeName = options.filename.replace(/[^a-zA-Z0-9.-]/g, '_');
    const gcsFilename = `${folder}/${timestamp}-${safeName}`;

    const file = this.bucket.file(gcsFilename);

    await new Promise<void>((resolve, reject) => {
      const writeStream = file.createWriteStream({
        metadata: {
          contentType: options.mimeType,
        },
        resumable: false,
      });

      writeStream.on('error', reject);
      writeStream.on('finish', resolve);

      stream.pipe(writeStream);
    });

    const gcsUri = `gs://${this.bucketName}/${gcsFilename}`;

    this.logger.log(`File uploaded to ${gcsUri}`);

    return {
      gcsUri,
      filename: gcsFilename,
    };
  }

  /**
   * Generate a signed URL for secure, time-limited access
   */
  async getSignedUrl(
    gcsUri: string,
    expiresInMinutes: number = 60,
  ): Promise<string> {
    if (!this.isConfigured) {
      throw new Error('GCS storage is not configured');
    }

    // Parse gs://bucket/path format
    const match = gcsUri.match(/^gs:\/\/([^/]+)\/(.+)$/);
    if (!match) {
      throw new Error(`Invalid GCS URI: ${gcsUri}`);
    }

    const [, bucketName, filename] = match;

    if (bucketName !== this.bucketName) {
      throw new Error(`Bucket mismatch: expected ${this.bucketName}, got ${bucketName}`);
    }

    const file = this.bucket.file(filename);

    const options: GetSignedUrlConfig = {
      version: 'v4',
      action: 'read',
      expires: Date.now() + expiresInMinutes * 60 * 1000,
    };

    const [signedUrl] = await file.getSignedUrl(options);

    return signedUrl;
  }

  /**
   * Delete a file from GCS
   */
  async deleteFile(gcsUri: string): Promise<void> {
    if (!this.isConfigured) {
      throw new Error('GCS storage is not configured');
    }

    const match = gcsUri.match(/^gs:\/\/([^/]+)\/(.+)$/);
    if (!match) {
      throw new Error(`Invalid GCS URI: ${gcsUri}`);
    }

    const [, , filename] = match;
    const file = this.bucket.file(filename);

    await file.delete({ ignoreNotFound: true });
    this.logger.log(`File deleted: ${gcsUri}`);
  }

  /**
   * Check if a file exists in GCS
   */
  async fileExists(gcsUri: string): Promise<boolean> {
    if (!this.isConfigured) {
      return false;
    }

    const match = gcsUri.match(/^gs:\/\/([^/]+)\/(.+)$/);
    if (!match) {
      return false;
    }

    const [, , filename] = match;
    const file = this.bucket.file(filename);
    const [exists] = await file.exists();

    return exists;
  }
}
