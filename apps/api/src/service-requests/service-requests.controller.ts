import {
  Controller,
  Get,
  Post,
  Patch,
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

import { JwtAuthGuard, CurrentUser, JwtPayload } from '../auth';

import { ServiceRequestsService } from './service-requests.service';
import {
  CreateServiceRequestDto,
  UpdateServiceRequestDto,
  ServiceRequestDto,
  ServiceRequestDetailDto,
} from './dto';

@ApiTags('Service Requests')
@ApiBearerAuth()
@Controller()
@UseGuards(JwtAuthGuard)
export class ServiceRequestsController {
  constructor(private readonly serviceRequestsService: ServiceRequestsService) {}

  @Post('requests')
  @ApiOperation({ summary: 'Create a new service request' })
  @ApiResponse({ status: 201, description: 'Request created', type: ServiceRequestDetailDto })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not a household member' })
  async create(
    @Body() dto: CreateServiceRequestDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<ServiceRequestDetailDto> {
    return this.serviceRequestsService.create(dto, user);
  }

  @Get('requests')
  @ApiOperation({ summary: 'Get service requests by household' })
  @ApiQuery({ name: 'householdId', required: true, description: 'Filter by household ID' })
  @ApiResponse({ status: 200, description: 'List of requests', type: [ServiceRequestDto] })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not a household member' })
  async findByHousehold(
    @Query('householdId') householdId: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<ServiceRequestDto[]> {
    return this.serviceRequestsService.findByHousehold(householdId, user);
  }

  @Get('manager/requests')
  @ApiOperation({ summary: 'Get service requests for manager (assigned households)' })
  @ApiResponse({ status: 200, description: 'List of requests', type: [ServiceRequestDetailDto] })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async findManagerRequests(
    @CurrentUser() user: JwtPayload,
  ): Promise<ServiceRequestDetailDto[]> {
    return this.serviceRequestsService.findManagerRequests(user);
  }

  @Get('requests/:id')
  @ApiOperation({ summary: 'Get a service request by ID' })
  @ApiParam({ name: 'id', description: 'Request ID' })
  @ApiResponse({ status: 200, description: 'Request details', type: ServiceRequestDetailDto })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not a household member' })
  @ApiResponse({ status: 404, description: 'Request not found' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<ServiceRequestDetailDto> {
    return this.serviceRequestsService.findOne(id, user);
  }

  @Patch('requests/:id')
  @ApiOperation({ summary: 'Update a service request' })
  @ApiParam({ name: 'id', description: 'Request ID' })
  @ApiResponse({ status: 200, description: 'Request updated', type: ServiceRequestDetailDto })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Not authorized to update' })
  @ApiResponse({ status: 404, description: 'Request not found' })
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateServiceRequestDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<ServiceRequestDetailDto> {
    return this.serviceRequestsService.update(id, dto, user);
  }
}
