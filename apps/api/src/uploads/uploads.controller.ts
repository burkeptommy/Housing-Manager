import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';

import { JwtAuthGuard, CurrentUser } from '../auth';
import { UploadsService } from './uploads.service';
import {
  SignUploadDto,
  CompleteUploadDto,
  SignUploadResponseDto,
  CompleteUploadResponseDto,
  FileAssetResponseDto,
} from './dto';

@ApiTags('Uploads')
@ApiBearerAuth()
@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post('sign')
  @ApiOperation({ summary: 'Get a signed URL for uploading a file to GCS' })
  @ApiResponse({
    status: 200,
    description: 'Signed URL and file asset created',
    type: SignUploadResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid content type' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async signUpload(
    @Body() dto: SignUploadDto,
    @CurrentUser('id') userId: string,
  ): Promise<SignUploadResponseDto> {
    return this.uploadsService.signUpload(
      {
        fileName: dto.fileName,
        contentType: dto.contentType,
        type: dto.type,
        householdId: dto.householdId,
      },
      userId,
    );
  }

  @Post('complete')
  @ApiOperation({ summary: 'Mark a file upload as complete' })
  @ApiResponse({
    status: 200,
    description: 'Upload marked as complete',
    type: CompleteUploadResponseDto,
  })
  @ApiResponse({ status: 400, description: 'File not found in storage' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Cannot complete another user upload' })
  @ApiResponse({ status: 404, description: 'FileAsset not found' })
  async completeUpload(
    @Body() dto: CompleteUploadDto,
    @CurrentUser('id') userId: string,
  ): Promise<CompleteUploadResponseDto> {
    return this.uploadsService.completeUpload(
      dto.fileAssetId,
      userId,
      dto.finalUrl,
    );
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a file asset by ID' })
  @ApiParam({ name: 'id', description: 'FileAsset ID' })
  @ApiResponse({
    status: 200,
    description: 'File asset details',
    type: FileAssetResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'No access to this file' })
  @ApiResponse({ status: 404, description: 'FileAsset not found' })
  async getFileAsset(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ): Promise<FileAssetResponseDto> {
    const asset = await this.uploadsService.getFileAsset(id, userId);
    return {
      id: asset.id,
      householdId: asset.householdId,
      uploaderUserId: asset.uploaderUserId,
      type: asset.type,
      status: asset.status,
      gcsPath: asset.gcsPath,
      url: asset.url,
      filename: asset.filename,
      contentType: asset.contentType,
      size: asset.size,
      createdAt: asset.createdAt,
    };
  }

  @Get(':id/url')
  @ApiOperation({ summary: 'Get a signed read URL for a file' })
  @ApiParam({ name: 'id', description: 'FileAsset ID' })
  @ApiResponse({
    status: 200,
    description: 'Signed read URL',
  })
  @ApiResponse({ status: 400, description: 'File not available' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'No access to this file' })
  @ApiResponse({ status: 404, description: 'FileAsset not found' })
  async getSignedReadUrl(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ): Promise<{ url: string }> {
    const url = await this.uploadsService.getSignedReadUrl(id, userId);
    return { url };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a file asset' })
  @ApiParam({ name: 'id', description: 'FileAsset ID' })
  @ApiResponse({ status: 200, description: 'File deleted' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Cannot delete this file' })
  @ApiResponse({ status: 404, description: 'FileAsset not found' })
  async deleteFileAsset(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ): Promise<{ success: boolean }> {
    await this.uploadsService.deleteFileAsset(id, userId);
    return { success: true };
  }

  // ========== PROFILE IMAGE ENDPOINTS ==========

  @Post('profile-image')
  @ApiOperation({ summary: 'Upload a profile image for an entity' })
  @ApiResponse({ status: 200, description: 'Image uploaded', schema: { properties: { imageUrl: { type: 'string' } } } })
  @ApiResponse({ status: 400, description: 'Invalid entity type' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async uploadProfileImage(
    @Body()
    body: {
      entityType: 'family-member' | 'pet' | 'household';
      entityId: string;
      image: string; // base64
      mimeType: string;
    },
    @CurrentUser('id') userId: string,
  ): Promise<{ imageUrl: string }> {
    return this.uploadsService.uploadProfileImage(
      body.entityType,
      body.entityId,
      body.image,
      body.mimeType,
      userId,
    );
  }

  @Delete('profile-image')
  @ApiOperation({ summary: 'Remove a profile image from an entity' })
  @ApiResponse({ status: 200, description: 'Image removed' })
  @ApiResponse({ status: 400, description: 'Invalid entity type' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async removeProfileImage(
    @Body()
    body: {
      entityType: 'family-member' | 'pet' | 'household';
      entityId: string;
    },
    @CurrentUser('id') userId: string,
  ): Promise<{ success: boolean }> {
    return this.uploadsService.removeProfileImage(
      body.entityType,
      body.entityId,
      userId,
    );
  }
}
