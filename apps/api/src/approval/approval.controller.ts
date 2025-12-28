import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam, ApiQuery } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../firebase';
import { ApprovalService, CreateApprovalDto, UpdateApprovalDto, AddCommentDto } from './approval.service';
import { ApprovalStatus } from '@prisma/client';

@ApiTags('Approvals')
@ApiBearerAuth()
@Controller('approvals')
@UseGuards(FirebaseAuthGuard)
export class ApprovalController {
  constructor(private readonly approvalService: ApprovalService) {}

  // =========================================================================
  // HOMEOWNER ENDPOINTS
  // =========================================================================

  @Get('household/:householdId')
  @ApiOperation({ summary: 'Get all approval requests for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiQuery({ name: 'status', required: false, description: 'Filter by status' })
  async getForHousehold(
    @Param('householdId') householdId: string,
    @Query('status') status?: ApprovalStatus,
  ) {
    return this.approvalService.getForHousehold(householdId, status);
  }

  @Get('household/:householdId/pending-count')
  @ApiOperation({ summary: 'Get count of pending approvals for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  async getPendingCount(@Param('householdId') householdId: string) {
    const count = await this.approvalService.getPendingCount(householdId);
    return { count };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single approval request by ID' })
  @ApiParam({ name: 'id', description: 'Approval request ID' })
  async getById(@Param('id') id: string) {
    return this.approvalService.getById(id);
  }

  @Patch(':id/decide')
  @ApiOperation({ summary: 'Approve or reject an approval request (homeowner only)' })
  @ApiParam({ name: 'id', description: 'Approval request ID' })
  async decide(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: UpdateApprovalDto,
  ) {
    const deciderName = req.user.name || req.user.email || 'Homeowner';
    return this.approvalService.decide(id, req.user.userId, deciderName, body);
  }

  // =========================================================================
  // MANAGER ENDPOINTS
  // =========================================================================

  @Post()
  @ApiOperation({ summary: 'Create a new approval request (manager only)' })
  async create(@Request() req: any, @Body() body: CreateApprovalDto) {
    const requesterName = req.user.name || req.user.email || 'Home Manager';
    return this.approvalService.create(req.user.userId, requesterName, body);
  }

  @Get('manager/my-requests')
  @ApiOperation({ summary: 'Get all approval requests created by the current manager' })
  @ApiQuery({ name: 'status', required: false, description: 'Filter by status' })
  async getMyRequests(@Request() req: any, @Query('status') status?: ApprovalStatus) {
    return this.approvalService.getByManager(req.user.userId, status);
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel an approval request (manager only)' })
  @ApiParam({ name: 'id', description: 'Approval request ID' })
  async cancel(@Request() req: any, @Param('id') id: string) {
    const managerName = req.user.name || req.user.email || 'Home Manager';
    return this.approvalService.cancel(id, req.user.userId, managerName);
  }

  // =========================================================================
  // COMMENTS
  // =========================================================================

  @Get(':id/comments')
  @ApiOperation({ summary: 'Get comments for an approval request' })
  @ApiParam({ name: 'id', description: 'Approval request ID' })
  async getComments(@Param('id') id: string) {
    return this.approvalService.getComments(id);
  }

  @Post(':id/comments')
  @ApiOperation({ summary: 'Add a comment to an approval request' })
  @ApiParam({ name: 'id', description: 'Approval request ID' })
  async addComment(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: AddCommentDto,
  ) {
    const authorName = req.user.name || req.user.email || 'User';
    return this.approvalService.addComment(id, req.user.userId, authorName, body);
  }
}
