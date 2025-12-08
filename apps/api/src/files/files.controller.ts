import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { FileCategory } from '@prisma/client';

import { JwtAuthGuard, CurrentUser, JwtPayload } from '../auth';

import { FilesService } from './files.service';
import { UploadFileDto, FileDto, FileWithUrlDto, UploadResponseDto } from './dto';

@ApiTags('Files')
@ApiBearerAuth()
@Controller('files')
@UseGuards(JwtAuthGuard)
export class FilesController {
  constructor(private readonly filesService: FilesService) {}

  @Post('upload')
  @ApiOperation({ summary: 'Upload a file to cloud storage' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file', 'householdId'],
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'The file to upload',
        },
        householdId: {
          type: 'string',
          description: 'Household ID that owns this file',
        },
        category: {
          type: 'string',
          enum: Object.values(FileCategory),
          description: 'File category',
        },
        description: {
          type: 'string',
          description: 'Optional description',
        },
        serviceRequestId: {
          type: 'string',
          description: 'Service request ID to attach file to',
        },
        taskId: {
          type: 'string',
          description: 'Task ID to attach file to',
        },
      },
    },
  })
  @ApiResponse({ status: 201, description: 'File uploaded successfully', type: UploadResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid file or parameters' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not a household member' })
  @UseInterceptors(FileInterceptor('file'))
  async upload(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 10 * 1024 * 1024 }), // 10MB
          new FileTypeValidator({
            fileType: /(jpeg|jpg|png|gif|webp|pdf|doc|docx)$/,
          }),
        ],
        fileIsRequired: true,
      }),
    )
    file: Express.Multer.File,
    @Body() dto: UploadFileDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<UploadResponseDto> {
    const uploadedFile = await this.filesService.upload(file, dto, user);
    return {
      success: true,
      file: uploadedFile,
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get file details with signed URL' })
  @ApiParam({ name: 'id', description: 'File ID' })
  @ApiResponse({ status: 200, description: 'File details', type: FileWithUrlDto })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not authorized to access this file' })
  @ApiResponse({ status: 404, description: 'File not found' })
  async getFile(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<FileWithUrlDto> {
    return this.filesService.getFile(id, user);
  }

  @Get(':id/url')
  @ApiOperation({ summary: 'Get signed URL for file download' })
  @ApiParam({ name: 'id', description: 'File ID' })
  @ApiResponse({ status: 200, description: 'Signed URL', schema: { type: 'object', properties: { url: { type: 'string' } } } })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not authorized to access this file' })
  @ApiResponse({ status: 404, description: 'File not found' })
  async getSignedUrl(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<{ url: string }> {
    const url = await this.filesService.getSignedUrl(id, user);
    return { url };
  }

  @Get()
  @ApiOperation({ summary: 'Get files for a household' })
  @ApiQuery({ name: 'householdId', required: true, description: 'Household ID' })
  @ApiQuery({ name: 'category', required: false, enum: FileCategory, description: 'Filter by category' })
  @ApiResponse({ status: 200, description: 'List of files', type: [FileDto] })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not a household member' })
  async getHouseholdFiles(
    @Query('householdId') householdId: string,
    @Query('category') category: FileCategory | undefined,
    @CurrentUser() user: JwtPayload,
  ): Promise<FileDto[]> {
    return this.filesService.getHouseholdFiles(householdId, user, category);
  }

  @Get('request/:requestId')
  @ApiOperation({ summary: 'Get files for a service request' })
  @ApiParam({ name: 'requestId', description: 'Service request ID' })
  @ApiResponse({ status: 200, description: 'List of files with signed URLs', type: [FileWithUrlDto] })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not a household member' })
  @ApiResponse({ status: 404, description: 'Service request not found' })
  async getServiceRequestFiles(
    @Param('requestId') requestId: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<FileWithUrlDto[]> {
    return this.filesService.getServiceRequestFiles(requestId, user);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a file' })
  @ApiParam({ name: 'id', description: 'File ID' })
  @ApiResponse({ status: 200, description: 'File deleted' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not authorized to delete this file' })
  @ApiResponse({ status: 404, description: 'File not found' })
  async deleteFile(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<{ success: boolean }> {
    await this.filesService.deleteFile(id, user);
    return { success: true };
  }
}
