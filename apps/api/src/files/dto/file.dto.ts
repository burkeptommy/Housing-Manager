import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FileCategory } from '@prisma/client';

export class FileDto {
  @ApiProperty({ description: 'File ID' })
  id: string;

  @ApiProperty({ description: 'Generated filename in storage' })
  filename: string;

  @ApiProperty({ description: 'Original filename uploaded by user' })
  originalName: string;

  @ApiProperty({ description: 'MIME type of the file' })
  mimeType: string;

  @ApiProperty({ description: 'File size in bytes' })
  size: number;

  @ApiPropertyOptional({ description: 'Signed URL for accessing the file' })
  url?: string;

  @ApiProperty({ description: 'File category', enum: FileCategory })
  category: FileCategory;

  @ApiPropertyOptional({ description: 'File description' })
  description?: string;

  @ApiPropertyOptional({ description: 'Household ID' })
  householdId?: string;

  @ApiPropertyOptional({ description: 'Service request ID' })
  serviceRequestId?: string;

  @ApiPropertyOptional({ description: 'Task ID' })
  taskId?: string;

  @ApiProperty({ description: 'Upload timestamp' })
  createdAt: Date;
}

export class FileWithUrlDto extends FileDto {
  @ApiProperty({ description: 'Signed URL for accessing the file (valid for 1 hour)' })
  url: string;
}

export class UploadResponseDto {
  @ApiProperty({ description: 'Upload success status' })
  success: boolean;

  @ApiProperty({ description: 'Uploaded file details', type: FileDto })
  file: FileDto;
}
