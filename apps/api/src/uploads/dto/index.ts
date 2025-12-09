import { IsString, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FileAssetType } from '@prisma/client';

export class SignUploadDto {
  @ApiProperty({ description: 'Original filename' })
  @IsString()
  fileName!: string;

  @ApiProperty({ description: 'MIME type of the file' })
  @IsString()
  contentType!: string;

  @ApiProperty({ enum: FileAssetType, description: 'Type of file asset' })
  @IsEnum(FileAssetType)
  type!: FileAssetType;

  @ApiProperty({ description: 'Household ID the file belongs to' })
  @IsString()
  householdId!: string;
}

export class CompleteUploadDto {
  @ApiProperty({ description: 'FileAsset ID from sign response' })
  @IsString()
  fileAssetId!: string;

  @ApiPropertyOptional({ description: 'Final public URL if different' })
  @IsOptional()
  @IsString()
  finalUrl?: string;
}

export class SignUploadResponseDto {
  @ApiProperty()
  fileAssetId!: string;

  @ApiProperty({ description: 'Signed URL for PUT upload to GCS' })
  signedUrl!: string;

  @ApiProperty({ description: 'GCS path of the file' })
  gcsPath!: string;

  @ApiProperty({ description: 'Public URL of the file after upload' })
  publicUrl!: string;
}

export class CompleteUploadResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  url!: string;

  @ApiProperty()
  status!: string;
}

export class FileAssetResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  householdId!: string;

  @ApiProperty()
  uploaderUserId!: string;

  @ApiProperty({ enum: FileAssetType })
  type!: FileAssetType;

  @ApiProperty()
  status!: string;

  @ApiProperty()
  gcsPath!: string;

  @ApiPropertyOptional()
  url?: string | null;

  @ApiProperty()
  filename!: string;

  @ApiProperty()
  contentType!: string;

  @ApiPropertyOptional()
  size?: number | null;

  @ApiProperty()
  createdAt!: Date;
}
