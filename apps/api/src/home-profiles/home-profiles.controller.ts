import {
  Controller,
  Get,
  Put,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';

import { JwtAuthGuard } from '../auth';
import { HouseholdMemberGuard } from '../common';

import { HomeProfilesService } from './home-profiles.service';
import { UpsertHomeProfileDto, HomeProfileDto } from './dto';

@ApiTags('Home Profiles')
@ApiBearerAuth()
@Controller('households/:householdId/profile')
@UseGuards(JwtAuthGuard, HouseholdMemberGuard)
export class HomeProfilesController {
  constructor(private readonly homeProfilesService: HomeProfilesService) {}

  @Put()
  @ApiOperation({ summary: 'Create or update home profile' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Home profile updated', type: HomeProfileDto })
  @ApiResponse({ status: 201, description: 'Home profile created', type: HomeProfileDto })
  async upsert(
    @Param('householdId') householdId: string,
    @Body() dto: UpsertHomeProfileDto,
  ): Promise<HomeProfileDto> {
    return this.homeProfilesService.upsert(householdId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get home profile' })
  @ApiParam({ name: 'householdId', description: 'Household ID' })
  @ApiResponse({ status: 200, description: 'Home profile', type: HomeProfileDto })
  @ApiResponse({ status: 404, description: 'Profile not found' })
  async findOne(@Param('householdId') householdId: string): Promise<HomeProfileDto | null> {
    return this.homeProfilesService.findByHouseholdId(householdId);
  }
}
