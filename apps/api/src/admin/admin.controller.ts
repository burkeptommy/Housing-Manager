import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
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
import { UserRole } from '@prisma/client';

import { FirebaseAuthGuard } from '../firebase';
import { AdminGuard } from '../auth/guards';

import { AdminService } from './admin.service';

@ApiTags('Admin')
@ApiBearerAuth()
@Controller('admin')
@UseGuards(FirebaseAuthGuard, AdminGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ============================================================================
  // DASHBOARD
  // ============================================================================

  @Get('dashboard')
  @ApiOperation({ summary: 'Get admin dashboard statistics' })
  @ApiResponse({ status: 200, description: 'Dashboard stats' })
  async getDashboard() {
    return this.adminService.getDashboardStats();
  }

  // ============================================================================
  // USERS
  // ============================================================================

  @Get('users')
  @ApiOperation({ summary: 'Get all users with filters' })
  @ApiQuery({ name: 'role', required: false, enum: UserRole })
  @ApiQuery({ name: 'search', required: false, description: 'Search by name or email' })
  @ApiQuery({ name: 'page', required: false, description: 'Page number' })
  @ApiQuery({ name: 'limit', required: false, description: 'Items per page' })
  @ApiResponse({ status: 200, description: 'List of users with pagination' })
  async getUsers(
    @Query('role') role?: UserRole,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getUsers({
      role,
      search,
      page: page ? parseInt(page, 10) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }

  @Get('users/:id')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'User details' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async getUser(@Param('id') id: string) {
    return this.adminService.getUser(id);
  }

  @Post('users')
  @ApiOperation({ summary: 'Create a new user' })
  @ApiResponse({ status: 201, description: 'User created' })
  @ApiResponse({ status: 400, description: 'Email already exists' })
  async createUser(
    @Body()
    body: {
      email: string;
      displayName: string;
      firstName?: string;
      lastName?: string;
      phone?: string;
      role: UserRole;
      password?: string;
    },
  ) {
    return this.adminService.createUser(body);
  }

  @Put('users/:id')
  @ApiOperation({ summary: 'Update user' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'User updated' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async updateUser(
    @Param('id') id: string,
    @Body()
    body: {
      displayName?: string;
      firstName?: string;
      lastName?: string;
      phone?: string;
      role?: UserRole;
    },
  ) {
    return this.adminService.updateUser(id, body);
  }

  @Delete('users/:id')
  @ApiOperation({ summary: 'Delete user' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'User deleted' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async deleteUser(@Param('id') id: string) {
    return this.adminService.deleteUser(id);
  }

  @Post('users/:id/reset-password')
  @ApiOperation({ summary: 'Send password reset email' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'Password reset email sent' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async resetPassword(@Param('id') id: string) {
    return this.adminService.resetUserPassword(id);
  }

  // ============================================================================
  // HOUSEHOLDS
  // ============================================================================

  @Get('households')
  @ApiOperation({ summary: 'Get all households with filters' })
  @ApiQuery({ name: 'status', required: false, description: 'Filter by status' })
  @ApiQuery({ name: 'tier', required: false, description: 'Filter by tier' })
  @ApiQuery({ name: 'search', required: false, description: 'Search by name' })
  @ApiQuery({ name: 'page', required: false, description: 'Page number' })
  @ApiQuery({ name: 'limit', required: false, description: 'Items per page' })
  @ApiResponse({ status: 200, description: 'List of households with pagination' })
  async getHouseholds(
    @Query('status') status?: string,
    @Query('tier') tier?: string,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getHouseholds({
      status,
      tier,
      search,
      page: page ? parseInt(page, 10) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }

  @Get('households/:id')
  @ApiOperation({ summary: 'Get household by ID' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Household details' })
  @ApiResponse({ status: 404, description: 'Household not found' })
  async getHousehold(@Param('id') id: string) {
    return this.adminService.getHousehold(id);
  }

  @Put('households/:id')
  @ApiOperation({ summary: 'Update household' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Household updated' })
  async updateHousehold(
    @Param('id') id: string,
    @Body() body: { name?: string; subscriptionPlan?: string; subscriptionStatus?: string },
  ) {
    return this.adminService.updateHousehold(id, body);
  }

  @Post('households/:id/assign-manager')
  @ApiOperation({ summary: 'Assign home manager to household' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Manager assigned' })
  async assignManager(
    @Param('id') id: string,
    @Body() body: { managerId: string },
  ) {
    return this.adminService.assignHomeManager(id, body.managerId);
  }

  // ============================================================================
  // ONBOARDING
  // ============================================================================

  @Get('onboarding')
  @ApiOperation({ summary: 'Get onboarding sessions with filters' })
  @ApiQuery({ name: 'status', required: false, description: 'Filter by status' })
  @ApiQuery({ name: 'managerId', required: false, description: 'Filter by manager' })
  @ApiQuery({ name: 'page', required: false, description: 'Page number' })
  @ApiQuery({ name: 'limit', required: false, description: 'Items per page' })
  @ApiResponse({ status: 200, description: 'List of onboarding sessions' })
  async getOnboardingSessions(
    @Query('status') status?: string,
    @Query('managerId') managerId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getOnboardingSessions({
      status,
      managerId,
      page: page ? parseInt(page, 10) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }

  @Post('onboarding/:id/reassign')
  @ApiOperation({ summary: 'Reassign onboarding to different manager' })
  @ApiParam({ name: 'id', description: 'Session ID' })
  @ApiResponse({ status: 200, description: 'Onboarding reassigned' })
  async reassignOnboarding(
    @Param('id') id: string,
    @Body() body: { managerId: string },
  ) {
    return this.adminService.reassignOnboarding(id, body.managerId);
  }

  @Put('onboarding/:id/status')
  @ApiOperation({ summary: 'Update onboarding status' })
  @ApiParam({ name: 'id', description: 'Session ID' })
  @ApiResponse({ status: 200, description: 'Status updated' })
  async updateOnboardingStatus(
    @Param('id') id: string,
    @Body() body: { status: string },
  ) {
    return this.adminService.updateOnboardingStatus(id, body.status);
  }

  // ============================================================================
  // TEAM
  // ============================================================================

  @Get('team')
  @ApiOperation({ summary: 'Get Haven team members' })
  @ApiResponse({ status: 200, description: 'List of team members' })
  async getTeam() {
    return this.adminService.getTeamMembers();
  }

  @Get('team/:id/workload')
  @ApiOperation({ summary: 'Get manager workload' })
  @ApiParam({ name: 'id', description: 'Manager ID' })
  @ApiResponse({ status: 200, description: 'Manager workload details' })
  async getManagerWorkload(@Param('id') id: string) {
    return this.adminService.getManagerWorkload(id);
  }

  // ============================================================================
  // ACTIVITY
  // ============================================================================

  @Get('activity')
  @ApiOperation({ summary: 'Get activity log' })
  @ApiQuery({ name: 'householdId', required: false, description: 'Filter by household' })
  @ApiQuery({ name: 'actorId', required: false, description: 'Filter by actor' })
  @ApiQuery({ name: 'category', required: false, description: 'Filter by category' })
  @ApiQuery({ name: 'page', required: false, description: 'Page number' })
  @ApiQuery({ name: 'limit', required: false, description: 'Items per page' })
  @ApiResponse({ status: 200, description: 'Activity log entries' })
  async getActivity(
    @Query('householdId') householdId?: string,
    @Query('actorId') actorId?: string,
    @Query('category') category?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getActivityLog({
      householdId,
      actorId,
      category,
      page: page ? parseInt(page, 10) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }
}
