import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum } from 'class-validator';
import { FileCategory } from '@prisma/client';

export class UploadFileDto {
  @ApiProperty({ description: 'Household ID that owns this file' })
  @IsString()
  householdId: string;

  @ApiPropertyOptional({
    description: 'File category',
    enum: FileCategory,
    default: FileCategory.IMAGE,
  })
  @IsOptional()
  @IsEnum(FileCategory)
  category?: FileCategory;

  @ApiPropertyOptional({ description: 'Optional description of the file' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Service request ID to attach file to' })
  @IsOptional()
  @IsString()
  serviceRequestId?: string;

  @ApiPropertyOptional({ description: 'Task ID to attach file to' })
  @IsOptional()
  @IsString()
  taskId?: string;
}
