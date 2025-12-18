import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { MaintenanceCategory, MaintenanceTaskStatus } from '@prisma/client';

import { FirebaseAuthGuard } from '../firebase';

import { MaintenanceTasksService } from './maintenance-tasks.service';
import {
  CreateMaintenanceTaskDto,
  UpdateMaintenanceTaskDto,
  GenerateFromTemplatesDto,
  MaintenanceTaskResponseDto,
  MaintenanceTemplateResponseDto,
} from './dto';

@ApiTags('Maintenance Tasks')
@ApiBearerAuth()
@Controller('maintenance-tasks')
@UseGuards(FirebaseAuthGuard)
export class MaintenanceTasksController {
  constructor(private readonly maintenanceTasksService: MaintenanceTasksService) {}

  @Post()
  @ApiOperation({ summary: 'Create a maintenance task' })
  @ApiResponse({ status: 201, description: 'Task created', type: MaintenanceTaskResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid template or vendor' })
  @ApiResponse({ status: 403, description: 'Forbidden - no access to household' })
  async create(
    @Body() createTaskDto: CreateMaintenanceTaskDto,
    @Request() req: { user: { userId: string } },
  ): Promise<MaintenanceTaskResponseDto> {
    return this.maintenanceTasksService.create(req.user.userId, createTaskDto);
  }

  @Post('generate-from-templates')
  @ApiOperation({ summary: 'Generate maintenance tasks from templates based on property features' })
  @ApiResponse({ status: 201, description: 'Tasks generated', type: [MaintenanceTaskResponseDto] })
  @ApiResponse({ status: 403, description: 'Forbidden - no access to household' })
  async generateFromTemplates(
    @Body() generateDto: GenerateFromTemplatesDto,
    @Request() req: { user: { userId: string } },
  ): Promise<MaintenanceTaskResponseDto[]> {
    return this.maintenanceTasksService.generateFromTemplates(req.user.userId, generateDto);
  }

  @Get('templates')
  @ApiOperation({ summary: 'Get all maintenance templates' })
  @ApiResponse({ status: 200, description: 'List of templates', type: [MaintenanceTemplateResponseDto] })
  async getTemplates(): Promise<MaintenanceTemplateResponseDto[]> {
    return this.maintenanceTasksService.getTemplates();
  }

  @Get()
  @ApiOperation({ summary: 'List maintenance tasks' })
  @ApiQuery({ name: 'householdId', required: true, description: 'Household ID' })
  @ApiQuery({ name: 'category', enum: MaintenanceCategory, required: false })
  @ApiQuery({ name: 'status', enum: MaintenanceTaskStatus, required: false })
  @ApiQuery({ name: 'dueDateFrom', type: String, required: false, description: 'Filter by due date (from, ISO 8601)' })
  @ApiQuery({ name: 'dueDateTo', type: String, required: false, description: 'Filter by due date (to, ISO 8601)' })
  @ApiQuery({ name: 'includeCompleted', type: Boolean, required: false })
  @ApiResponse({ status: 200, description: 'List of maintenance tasks', type: [MaintenanceTaskResponseDto] })
  async findAll(
    @Query('householdId') householdId: string,
    @Query('category') category?: MaintenanceCategory,
    @Query('status') status?: MaintenanceTaskStatus,
    @Query('dueDateFrom') dueDateFrom?: string,
    @Query('dueDateTo') dueDateTo?: string,
    @Query('includeCompleted') includeCompleted?: string,
    @Request() req?: { user: { userId: string } },
  ): Promise<MaintenanceTaskResponseDto[]> {
    return this.maintenanceTasksService.findAll(req!.user.userId, {
      householdId,
      category,
      status,
      dueDateFrom,
      dueDateTo,
      includeCompleted: includeCompleted === 'true',
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a maintenance task by ID' })
  @ApiResponse({ status: 200, description: 'Task details', type: MaintenanceTaskResponseDto })
  @ApiResponse({ status: 404, description: 'Task not found' })
  async findOne(
    @Param('id') id: string,
    @Request() req: { user: { userId: string } },
  ): Promise<MaintenanceTaskResponseDto> {
    return this.maintenanceTasksService.findOne(id, req.user.userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a maintenance task' })
  @ApiResponse({ status: 200, description: 'Task updated', type: MaintenanceTaskResponseDto })
  @ApiResponse({ status: 404, description: 'Task not found' })
  async update(
    @Param('id') id: string,
    @Body() updateTaskDto: UpdateMaintenanceTaskDto,
    @Request() req: { user: { userId: string } },
  ): Promise<MaintenanceTaskResponseDto> {
    return this.maintenanceTasksService.update(id, req.user.userId, updateTaskDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a maintenance task' })
  @ApiResponse({ status: 204, description: 'Task deleted' })
  @ApiResponse({ status: 404, description: 'Task not found' })
  async remove(
    @Param('id') id: string,
    @Request() req: { user: { userId: string } },
  ): Promise<void> {
    return this.maintenanceTasksService.remove(id, req.user.userId);
  }
}
