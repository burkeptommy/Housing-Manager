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
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { VendorCategory } from '@prisma/client';

import { FirebaseAuthGuard, CurrentUser, AuthPayload } from '../firebase';

import { HouseholdVendorsService } from './household-vendors.service';
import {
  CreateVendorDto,
  UpdateVendorDto,
  VendorResponseDto,
  CreateActivityDto,
  ActivityResponseDto,
} from './dto';

@ApiTags('Vendors')
@ApiBearerAuth()
@Controller('households/:householdId/vendors')
@UseGuards(FirebaseAuthGuard)
export class HouseholdVendorsController {
  constructor(private readonly vendorsService: HouseholdVendorsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a vendor for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiResponse({ status: 201, description: 'Vendor created', type: VendorResponseDto })
  @ApiResponse({ status: 403, description: 'Forbidden - no access to household' })
  async create(
    @Param('householdId') householdId: string,
    @Body() createVendorDto: CreateVendorDto,
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.create(householdId, user.userId, createVendorDto);
  }

  @Get()
  @ApiOperation({ summary: 'List vendors for a household' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiQuery({ name: 'category', enum: VendorCategory, required: false })
  @ApiQuery({ name: 'includeInactive', type: Boolean, required: false })
  @ApiResponse({ status: 200, description: 'List of vendors', type: [VendorResponseDto] })
  async findAll(
    @Param('householdId') householdId: string,
    @Query('category') category?: VendorCategory,
    @Query('includeInactive') includeInactive?: string,
    @CurrentUser() user?: AuthPayload,
  ): Promise<VendorResponseDto[]> {
    return this.vendorsService.findAll(householdId, user!.userId, {
      category,
      includeInactive: includeInactive === 'true',
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a vendor by ID' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'id', description: 'Vendor ID' })
  @ApiResponse({ status: 200, description: 'Vendor details', type: VendorResponseDto })
  @ApiResponse({ status: 404, description: 'Vendor not found' })
  async findOne(
    @Param('householdId') householdId: string,
    @Param('id') id: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.findOne(id, householdId, user.userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a vendor' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'id', description: 'Vendor ID' })
  @ApiResponse({ status: 200, description: 'Vendor updated', type: VendorResponseDto })
  @ApiResponse({ status: 404, description: 'Vendor not found' })
  async update(
    @Param('householdId') householdId: string,
    @Param('id') id: string,
    @Body() updateVendorDto: UpdateVendorDto,
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.update(id, householdId, user.userId, updateVendorDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a vendor (soft delete)' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'id', description: 'Vendor ID' })
  @ApiResponse({ status: 204, description: 'Vendor deleted' })
  @ApiResponse({ status: 404, description: 'Vendor not found' })
  async remove(
    @Param('householdId') householdId: string,
    @Param('id') id: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<void> {
    return this.vendorsService.remove(id, householdId, user.userId);
  }

  // ========== CRM ENDPOINTS ==========

  @Post(':id/toggle-favorite')
  @ApiOperation({ summary: 'Toggle favorite status for a vendor' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'id', description: 'Vendor ID' })
  @ApiResponse({ status: 200, description: 'Favorite toggled', type: VendorResponseDto })
  async toggleFavorite(
    @Param('householdId') householdId: string,
    @Param('id') id: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.toggleFavorite(id, householdId, user.userId);
  }

  @Patch(':id/rating')
  @ApiOperation({ summary: 'Set rating for a vendor (1-5 stars)' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'id', description: 'Vendor ID' })
  @ApiResponse({ status: 200, description: 'Rating updated', type: VendorResponseDto })
  async setRating(
    @Param('householdId') householdId: string,
    @Param('id') id: string,
    @Body() body: { rating: number },
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.setRating(id, householdId, user.userId, body.rating);
  }

  // ========== ACTIVITY ENDPOINTS ==========

  @Get(':id/activities')
  @ApiOperation({ summary: 'Get all activities for a vendor' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'id', description: 'Vendor ID' })
  @ApiResponse({ status: 200, description: 'List of activities', type: [ActivityResponseDto] })
  async getActivities(
    @Param('householdId') householdId: string,
    @Param('id') id: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<ActivityResponseDto[]> {
    return this.vendorsService.getActivities(id, householdId, user.userId);
  }

  @Post(':id/activities')
  @ApiOperation({ summary: 'Add an activity for a vendor' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'id', description: 'Vendor ID' })
  @ApiResponse({ status: 201, description: 'Activity created', type: ActivityResponseDto })
  async addActivity(
    @Param('householdId') householdId: string,
    @Param('id') id: string,
    @Body() dto: CreateActivityDto,
    @CurrentUser() user: AuthPayload,
  ): Promise<ActivityResponseDto> {
    return this.vendorsService.addActivity(id, householdId, user.userId, dto);
  }

  @Delete(':vendorId/activities/:activityId')
  @ApiOperation({ summary: 'Delete an activity' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  @ApiParam({ name: 'activityId', description: 'Activity ID' })
  @ApiResponse({ status: 204, description: 'Activity deleted' })
  async deleteActivity(
    @Param('householdId') householdId: string,
    @Param('vendorId') vendorId: string,
    @Param('activityId') activityId: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<void> {
    return this.vendorsService.deleteActivity(activityId, vendorId, householdId, user.userId);
  }
}

// Also create a top-level vendors controller for simpler access
@ApiTags('Vendors')
@ApiBearerAuth()
@Controller('vendors')
@UseGuards(FirebaseAuthGuard)
export class VendorsController {
  constructor(private readonly vendorsService: HouseholdVendorsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a vendor (householdId in body)' })
  @ApiResponse({ status: 201, description: 'Vendor created', type: VendorResponseDto })
  async create(
    @Body() createVendorDto: CreateVendorDto & { householdId: string },
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    const { householdId, ...vendorData } = createVendorDto;
    return this.vendorsService.create(householdId, user.userId, vendorData);
  }

  @Get()
  @ApiOperation({ summary: 'List vendors for a household' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiQuery({ name: 'category', enum: VendorCategory, required: false })
  @ApiQuery({ name: 'favorite', type: Boolean, required: false })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'includeInactive', type: Boolean, required: false })
  @ApiResponse({ status: 200, description: 'List of vendors', type: [VendorResponseDto] })
  async findAll(
    @Query('householdId') householdId: string,
    @Query('category') category?: VendorCategory,
    @Query('favorite') favorite?: string,
    @Query('search') search?: string,
    @Query('includeInactive') includeInactive?: string,
    @CurrentUser() user?: AuthPayload,
  ): Promise<VendorResponseDto[]> {
    return this.vendorsService.findAll(householdId, user!.userId, {
      category,
      favorite: favorite === 'true',
      search,
      includeInactive: includeInactive === 'true',
    });
  }

  @Get(':vendorId')
  @ApiOperation({ summary: 'Get a vendor with activities' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 200, description: 'Vendor details with activities', type: VendorResponseDto })
  async findOne(
    @Param('vendorId') vendorId: string,
    @Query('householdId') householdId: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.findOne(vendorId, householdId, user.userId);
  }

  @Post(':vendorId/toggle-favorite')
  @ApiOperation({ summary: 'Toggle favorite status' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 200, description: 'Favorite toggled', type: VendorResponseDto })
  async toggleFavorite(
    @Param('vendorId') vendorId: string,
    @Query('householdId') householdId: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.toggleFavorite(vendorId, householdId, user.userId);
  }

  @Patch(':vendorId/rating')
  @ApiOperation({ summary: 'Set rating (1-5 stars)' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 200, description: 'Rating updated', type: VendorResponseDto })
  async setRating(
    @Param('vendorId') vendorId: string,
    @Query('householdId') householdId: string,
    @Body() body: { rating: number },
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.setRating(vendorId, householdId, user.userId, body.rating);
  }

  @Patch(':vendorId')
  @ApiOperation({ summary: 'Update a vendor' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 200, description: 'Vendor updated', type: VendorResponseDto })
  @ApiResponse({ status: 404, description: 'Vendor not found' })
  async update(
    @Param('vendorId') vendorId: string,
    @Query('householdId') householdId: string,
    @Body() updateVendorDto: UpdateVendorDto,
    @CurrentUser() user: AuthPayload,
  ): Promise<VendorResponseDto> {
    return this.vendorsService.update(vendorId, householdId, user.userId, updateVendorDto);
  }

  @Get(':vendorId/activities')
  @ApiOperation({ summary: 'Get activities for a vendor' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 200, description: 'Activities list', type: [ActivityResponseDto] })
  async getActivities(
    @Param('vendorId') vendorId: string,
    @Query('householdId') householdId: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<ActivityResponseDto[]> {
    return this.vendorsService.getActivities(vendorId, householdId, user.userId);
  }

  @Post(':vendorId/activities')
  @ApiOperation({ summary: 'Add an activity' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 201, description: 'Activity created', type: ActivityResponseDto })
  async addActivity(
    @Param('vendorId') vendorId: string,
    @Query('householdId') householdId: string,
    @Body() dto: CreateActivityDto,
    @CurrentUser() user: AuthPayload,
  ): Promise<ActivityResponseDto> {
    return this.vendorsService.addActivity(vendorId, householdId, user.userId, dto);
  }

  @Delete(':vendorId/activities/:activityId')
  @ApiOperation({ summary: 'Delete an activity' })
  @ApiParam({ name: 'vendorId', description: 'Vendor ID' })
  @ApiParam({ name: 'activityId', description: 'Activity ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 204, description: 'Activity deleted' })
  async deleteActivity(
    @Param('vendorId') vendorId: string,
    @Param('activityId') activityId: string,
    @Query('householdId') householdId: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<void> {
    return this.vendorsService.deleteActivity(activityId, vendorId, householdId, user.userId);
  }

  // ========== MESSAGE ENDPOINTS ==========

  @Get(':householdVendorId/messages')
  @ApiOperation({ summary: 'Get messages for a vendor relationship' })
  @ApiParam({ name: 'householdVendorId', description: 'HouseholdVendor ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 200, description: 'Messages list' })
  async getMessages(
    @Param('householdVendorId') householdVendorId: string,
    @Query('householdId') householdId: string,
    @CurrentUser() user: AuthPayload,
  ) {
    return this.vendorsService.getMessages(householdVendorId, householdId, user.userId);
  }

  @Post(':householdVendorId/messages')
  @ApiOperation({ summary: 'Send a message to a vendor' })
  @ApiParam({ name: 'householdVendorId', description: 'HouseholdVendor ID' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 201, description: 'Message sent' })
  async sendMessage(
    @Param('householdVendorId') householdVendorId: string,
    @Query('householdId') householdId: string,
    @Body() body: { content: string },
    @CurrentUser() user: AuthPayload,
  ) {
    return this.vendorsService.sendMessage(householdVendorId, householdId, user.userId, body.content);
  }
}
