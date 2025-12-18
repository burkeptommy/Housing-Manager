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

import { FirebaseAuthGuard, CurrentUser, AuthPayload } from '../firebase';
import {
  HouseholdMemberGuard,
  HouseholdAccessGuard,
  AllowOwner,
  AllowManager,
  HouseholdAccessParam,
  CurrentUserContext,
  UserContext,
} from '../common';

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
@UseGuards(FirebaseAuthGuard)
export class HouseholdsController {
  constructor(private readonly householdsService: HouseholdsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new household' })
  @ApiResponse({ status: 201, description: 'Household created', type: HouseholdDto })
  async create(
    @CurrentUser() user: AuthPayload,
    @Body() dto: CreateHouseholdDto,
  ): Promise<HouseholdDto> {
    return this.householdsService.create(user.userId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List households accessible to current user based on role' })
  @ApiResponse({ status: 200, description: 'List of households', type: [HouseholdListItemDto] })
  async findAll(@CurrentUserContext() userContext: UserContext): Promise<HouseholdListItemDto[]> {
    return this.householdsService.findAllByUserContext(userContext);
  }

  @Get(':id')
  @UseGuards(HouseholdAccessGuard)
  @HouseholdAccessParam('id')
  @AllowOwner()
  @AllowManager()
  @ApiOperation({ summary: 'Get household details' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Household details', type: HouseholdDetailDto })
  @ApiResponse({ status: 404, description: 'Household not found' })
  async findOne(@Param('id') id: string): Promise<HouseholdDetailDto> {
    return this.householdsService.findById(id);
  }

  @Patch(':id')
  @UseGuards(HouseholdAccessGuard)
  @HouseholdAccessParam('id')
  @AllowOwner()
  @AllowManager()
  @ApiOperation({ summary: 'Update household settings' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Household updated', type: HouseholdDto })
  @ApiResponse({ status: 403, description: 'Only owners or managers can update' })
  async update(
    @Param('id') id: string,
    @CurrentUserContext() userContext: UserContext,
    @Body() dto: UpdateHouseholdDto,
  ): Promise<HouseholdDto> {
    return this.householdsService.updateByContext(id, userContext, dto);
  }

  @Delete(':id')
  @UseGuards(HouseholdAccessGuard)
  @HouseholdAccessParam('id')
  @AllowOwner()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a household' })
  @ApiParam({ name: 'id', description: 'Household ID' })
  @ApiResponse({ status: 204, description: 'Household deleted' })
  @ApiResponse({ status: 403, description: 'Only owners can delete' })
  async delete(
    @Param('id') id: string,
    @CurrentUser() user: AuthPayload,
  ): Promise<void> {
    return this.householdsService.delete(id, user.userId);
  }
}
