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

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

import { HouseholdVendorsService } from './household-vendors.service';
import {
  CreateVendorDto,
  UpdateVendorDto,
  VendorResponseDto,
} from './dto';

@ApiTags('Vendors')
@ApiBearerAuth()
@Controller('households/:householdId/vendors')
@UseGuards(JwtAuthGuard)
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
    @Request() req: { user: { sub: string } },
  ): Promise<VendorResponseDto> {
    return this.vendorsService.create(householdId, req.user.sub, createVendorDto);
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
    @Request() req?: { user: { sub: string } },
  ): Promise<VendorResponseDto[]> {
    return this.vendorsService.findAll(householdId, req!.user.sub, {
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
    @Request() req: { user: { sub: string } },
  ): Promise<VendorResponseDto> {
    return this.vendorsService.findOne(id, householdId, req.user.sub);
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
    @Request() req: { user: { sub: string } },
  ): Promise<VendorResponseDto> {
    return this.vendorsService.update(id, householdId, req.user.sub, updateVendorDto);
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
    @Request() req: { user: { sub: string } },
  ): Promise<void> {
    return this.vendorsService.remove(id, householdId, req.user.sub);
  }
}

// Also create a top-level vendors controller for simpler access
@ApiTags('Vendors')
@ApiBearerAuth()
@Controller('vendors')
@UseGuards(JwtAuthGuard)
export class VendorsController {
  constructor(private readonly vendorsService: HouseholdVendorsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a vendor (householdId in body)' })
  @ApiResponse({ status: 201, description: 'Vendor created', type: VendorResponseDto })
  async create(
    @Body() createVendorDto: CreateVendorDto & { householdId: string },
    @Request() req: { user: { sub: string } },
  ): Promise<VendorResponseDto> {
    const { householdId, ...vendorData } = createVendorDto;
    return this.vendorsService.create(householdId, req.user.sub, vendorData);
  }

  @Get()
  @ApiOperation({ summary: 'List vendors for a household' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiQuery({ name: 'category', enum: VendorCategory, required: false })
  @ApiQuery({ name: 'includeInactive', type: Boolean, required: false })
  @ApiResponse({ status: 200, description: 'List of vendors', type: [VendorResponseDto] })
  async findAll(
    @Query('householdId') householdId: string,
    @Query('category') category?: VendorCategory,
    @Query('includeInactive') includeInactive?: string,
    @Request() req?: { user: { sub: string } },
  ): Promise<VendorResponseDto[]> {
    return this.vendorsService.findAll(householdId, req!.user.sub, {
      category,
      includeInactive: includeInactive === 'true',
    });
  }
}
