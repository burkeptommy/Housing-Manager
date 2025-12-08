import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';

import { JwtAuthGuard, CurrentUser, JwtPayload } from '../auth';
import { HouseholdMemberGuard } from '../common';

import { HouseholdsService } from './households.service';
import {
  CreateHouseholdDto,
  UpdateHouseholdDto,
  HouseholdDto,
  HouseholdDetailDto,
  HouseholdListItemDto,
} from './dto';

@ApiTags('Households')
@ApiBearerAuth()
@Controller('households')
@UseGuards(JwtAuthGuard)
export class HouseholdsController {
  constructor(private readonly householdsService: HouseholdsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new household' })
  @ApiResponse({ status: 201, description: 'Household created', type: HouseholdDto })
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateHouseholdDto,
  ): Promise<HouseholdDto> {
    return this.householdsService.create(user.sub, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List households for current user' })
  @ApiResponse({ status: 200, description: 'List of households', type: [HouseholdListItemDto] })
  async findAll(@CurrentUser() user: JwtPayload): Promise<HouseholdListItemDto[]> {
    return this.householdsService.findAllForUser(user.sub);
  }

  @Get(':id')
  @UseGuards(HouseholdMemberGuard)
  @ApiOperation({ summary: 'Get household details' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Household details', type: HouseholdDetailDto })
  @ApiResponse({ status: 404, description: 'Household not found' })
  async findOne(@Param('id') id: string): Promise<HouseholdDetailDto> {
    return this.householdsService.findById(id);
  }

  @Patch(':id')
  @UseGuards(HouseholdMemberGuard)
  @ApiOperation({ summary: 'Update household settings' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Household updated', type: HouseholdDto })
  @ApiResponse({ status: 403, description: 'Only owners can update' })
  async update(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateHouseholdDto,
  ): Promise<HouseholdDto> {
    return this.householdsService.update(id, user.sub, dto);
  }

  @Delete(':id')
  @UseGuards(HouseholdMemberGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a household' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 204, description: 'Household deleted' })
  @ApiResponse({ status: 403, description: 'Only owners can delete' })
  async delete(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ): Promise<void> {
    return this.householdsService.delete(id, user.sub);
  }
}
