import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

import { JwtAuthGuard, RolesGuard, Roles } from '../auth';
import { FirebaseAuthGuard, AuthPayload, CurrentUser } from '../firebase';

import {
  UsersService,
  PaginatedUsers,
  MeResponse,
  InviteUserDto,
  AcceptInviteDto,
} from './users.service';
import { UserDto, UpdateUserDto, AdminUpdateUserDto, UserListQueryDto } from './dto';

/**
 * Me Controller - User profile and household management
 * Uses Firebase Auth
 */
@ApiTags('Me')
@ApiBearerAuth()
@Controller('me')
@UseGuards(FirebaseAuthGuard)
export class MeController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Get current user profile and household info
   */
  @Get()
  @ApiOperation({ summary: 'Get current user profile with household info' })
  @ApiResponse({ status: 200, description: 'User profile with household info' })
  async getMe(@CurrentUser() user: AuthPayload): Promise<MeResponse> {
    return this.usersService.getMe(user);
  }
}

/**
 * User/Me Controller - Alternative endpoint for backward compatibility
 * Uses Firebase Auth
 */
@ApiTags('User')
@ApiBearerAuth()
@Controller('user')
@UseGuards(FirebaseAuthGuard)
export class UserMeController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Get current user - alternative endpoint for /user/me calls
   */
  @Get('me')
  @ApiOperation({ summary: 'Get current user (alternative endpoint)' })
  @ApiResponse({ status: 200, description: 'User profile with household info' })
  async getUserMe(@CurrentUser() user: AuthPayload): Promise<MeResponse> {
    return this.usersService.getMe(user);
  }
}

/**
 * Me Features Controller - Additional user profile operations
 * Uses Firebase Auth
 */
@ApiTags('Me')
@ApiBearerAuth()
@Controller('me')
@UseGuards(FirebaseAuthGuard)
export class MeFeaturesController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Get pending invites for current user
   */
  @Get('invites')
  @ApiOperation({ summary: 'Get pending household invites for current user' })
  async getPendingInvites(@CurrentUser() user: AuthPayload) {
    return this.usersService.getPendingInvites(user.email);
  }

  /**
   * Update current user's profile
   */
  @Patch('profile')
  @ApiOperation({ summary: 'Update current user profile' })
  @ApiResponse({ status: 200, description: 'Profile updated successfully' })
  async updateMyProfile(
    @CurrentUser() user: AuthPayload,
    @Body() dto: UpdateUserDto,
  ): Promise<UserDto> {
    return this.usersService.updateProfile(user.userId, dto);
  }

  /**
   * Switch to a different household
   */
  @Post('switch-household/:householdId')
  @ApiOperation({ summary: 'Switch current household context' })
  async switchHousehold(
    @CurrentUser() user: AuthPayload,
    @Param('householdId') householdId: string,
  ) {
    return this.usersService.switchHousehold(user.userId, householdId);
  }
}

/**
 * Household Invites Controller
 * Uses Firebase Auth
 */
@ApiTags('Household Invites')
@ApiBearerAuth()
@Controller('household')
@UseGuards(FirebaseAuthGuard)
export class HouseholdInvitesController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Invite a user to a household
   */
  @Post(':householdId/invite')
  @ApiOperation({ summary: 'Invite a user to the household by email' })
  @ApiResponse({ status: 201, description: 'Invite sent successfully' })
  @ApiResponse({ status: 403, description: 'Not authorized to invite' })
  @ApiResponse({ status: 409, description: 'User already invited or member' })
  async inviteUser(
    @CurrentUser() user: AuthPayload,
    @Param('householdId') householdId: string,
    @Body() dto: InviteUserDto,
  ) {
    return this.usersService.inviteUser(user, householdId, dto);
  }

  /**
   * Accept a household invitation
   */
  @Post('accept-invite')
  @ApiOperation({ summary: 'Accept a household invitation' })
  @ApiResponse({ status: 200, description: 'Invite accepted successfully' })
  @ApiResponse({ status: 400, description: 'Invalid or expired invite' })
  async acceptInvite(
    @CurrentUser() user: AuthPayload,
    @Body() dto: AcceptInviteDto,
  ) {
    return this.usersService.acceptInvite(user, dto);
  }

  /**
   * Create a new household (for users without one)
   */
  @Post('create')
  @ApiOperation({ summary: 'Create a new household' })
  @ApiResponse({ status: 201, description: 'Household created successfully' })
  @ApiResponse({ status: 409, description: 'User already owns a household' })
  async createHousehold(
    @CurrentUser() user: AuthPayload,
    @Body() dto: { name: string; description?: string },
  ) {
    return this.usersService.createHousehold(user.userId, dto);
  }
}

/**
 * User Profile Controller - For authenticated users to update their own profile
 * Uses Firebase Auth
 */
@ApiTags('User Profile')
@ApiBearerAuth()
@Controller('users')
@UseGuards(FirebaseAuthGuard)
export class UserProfileController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Update current user's profile
   */
  @Patch('profile')
  @ApiOperation({ summary: 'Update current user profile' })
  @ApiResponse({ status: 200, description: 'Profile updated successfully' })
  async updateProfile(
    @CurrentUser() user: AuthPayload,
    @Body() dto: UpdateUserDto,
  ): Promise<UserDto> {
    return this.usersService.updateProfile(user.userId, dto);
  }
}

/**
 * Admin Users Controller - Existing admin functionality
 * Uses JWT Auth (legacy)
 */
@ApiTags('Admin Users')
@ApiBearerAuth()
@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Get a user by ID (Admin only)
   */
  @Get(':id')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Get user by ID (Admin only)' })
  async findOne(@Param('id') id: string): Promise<UserDto> {
    return this.usersService.findById(id);
  }

  /**
   * Get all users with pagination (Admin only)
   */
  @Get()
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'List all users with pagination (Admin only)' })
  async findAll(@Query() query: UserListQueryDto): Promise<PaginatedUsers> {
    return this.usersService.findMany(query);
  }

  /**
   * Update a user (Admin only)
   */
  @Patch(':id')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Update user (Admin only)' })
  async update(
    @Param('id') id: string,
    @Body() dto: AdminUpdateUserDto,
  ): Promise<UserDto> {
    return this.usersService.update(id, dto);
  }

  /**
   * Delete a user (Admin only)
   */
  @Delete(':id')
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete user (Admin only)' })
  async delete(@Param('id') id: string): Promise<void> {
    return this.usersService.delete(id);
  }
}
