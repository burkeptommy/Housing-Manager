import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { UserRole, ConversationStatus, WorkOrderStatus } from '@prisma/client';
import { IsOptional, IsString, IsEnum, IsDateString } from 'class-validator';

import { JwtAuthGuard, RolesGuard, Roles, CurrentUser } from '../auth';
import { InternalService } from './internal.service';

class ConversationFiltersDto {
  @IsOptional()
  @IsString()
  status?: 'all' | 'unassigned' | 'assigned' | 'closed';
}

class AssignConversationDto {
  @IsOptional()
  @IsString()
  assignedToId?: string | null;
}

class UpdateConversationStatusDto {
  @IsEnum(ConversationStatus)
  status!: ConversationStatus;
}

class WorkOrderFiltersDto {
  @IsOptional()
  @IsString()
  status?: WorkOrderStatus | 'all';

  @IsOptional()
  @IsDateString()
  dateFrom?: string;

  @IsOptional()
  @IsDateString()
  dateTo?: string;
}

@ApiTags('Internal')
@ApiBearerAuth()
@Controller('internal')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.MANAGER, UserRole.ADMIN)
export class InternalController {
  constructor(private readonly internalService: InternalService) {}

  // ============================================================================
  // DASHBOARD
  // ============================================================================

  @Get('stats')
  @ApiOperation({ summary: 'Get internal dashboard statistics' })
  @ApiResponse({ status: 200, description: 'Dashboard stats' })
  async getDashboardStats() {
    return this.internalService.getDashboardStats();
  }

  // ============================================================================
  // HOUSEHOLDS
  // ============================================================================

  @Get('households')
  @ApiOperation({ summary: 'Get all households for internal view' })
  @ApiResponse({ status: 200, description: 'List of households' })
  async getHouseholds() {
    return this.internalService.getHouseholds();
  }

  @Get('households/:id')
  @ApiOperation({ summary: 'Get household detail for internal view' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Household details' })
  @ApiResponse({ status: 404, description: 'Household not found' })
  async getHouseholdById(@Param('id') id: string) {
    return this.internalService.getHouseholdById(id);
  }

  // ============================================================================
  // SUPPORT QUEUE
  // ============================================================================

  @Get('conversations')
  @ApiOperation({ summary: 'Get support conversation queue' })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['all', 'unassigned', 'assigned', 'closed'],
  })
  @ApiResponse({ status: 200, description: 'List of conversations' })
  async getConversations(
    @Query() filters: ConversationFiltersDto,
    @CurrentUser('id') userId: string,
  ) {
    return this.internalService.getConversations({
      status: filters.status,
      assignedToId: filters.status === 'assigned' ? userId : undefined,
    });
  }

  @Patch('conversations/:id/assign')
  @ApiOperation({ summary: 'Assign conversation to a manager' })
  @ApiParam({ name: 'id', description: 'Conversation ID' })
  @ApiResponse({ status: 200, description: 'Conversation assigned' })
  async assignConversation(
    @Param('id') id: string,
    @Body() dto: AssignConversationDto,
    @CurrentUser('id') userId: string,
  ) {
    // If no assignedToId provided, assign to self
    const assignTo =
      dto.assignedToId === undefined ? userId : dto.assignedToId;
    return this.internalService.assignConversation(id, assignTo);
  }

  @Patch('conversations/:id/status')
  @ApiOperation({ summary: 'Update conversation status' })
  @ApiParam({ name: 'id', description: 'Conversation ID' })
  @ApiResponse({ status: 200, description: 'Status updated' })
  async updateConversationStatus(
    @Param('id') id: string,
    @Body() dto: UpdateConversationStatusDto,
  ) {
    return this.internalService.updateConversationStatus(id, dto.status);
  }

  // ============================================================================
  // WORK ORDERS QUEUE
  // ============================================================================

  @Get('work-orders')
  @ApiOperation({ summary: 'Get work orders queue' })
  @ApiQuery({ name: 'status', required: false, enum: WorkOrderStatus })
  @ApiQuery({ name: 'dateFrom', required: false, type: String })
  @ApiQuery({ name: 'dateTo', required: false, type: String })
  @ApiResponse({ status: 200, description: 'List of work orders' })
  async getWorkOrders(@Query() filters: WorkOrderFiltersDto) {
    return this.internalService.getWorkOrders({
      status: filters.status,
      dateFrom: filters.dateFrom ? new Date(filters.dateFrom) : undefined,
      dateTo: filters.dateTo ? new Date(filters.dateTo) : undefined,
    });
  }

  @Get('appointments')
  @ApiOperation({ summary: 'Get upcoming appointments' })
  @ApiQuery({ name: 'days', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'List of upcoming appointments' })
  async getUpcomingAppointments(@Query('days') days?: string) {
    return this.internalService.getUpcomingAppointments(
      days ? parseInt(days, 10) : 7,
    );
  }
}
