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
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { VendorCategory } from '@prisma/client';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

import { BillAccountsService } from './bill-accounts.service';
import {
  CreateBillAccountDto,
  UpdateBillAccountDto,
  BillAccountResponseDto,
} from './dto';

@ApiTags('Bill Accounts')
@ApiBearerAuth()
@Controller('bill-accounts')
@UseGuards(JwtAuthGuard)
export class BillAccountsController {
  constructor(private readonly billAccountsService: BillAccountsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a bill account' })
  @ApiResponse({ status: 201, description: 'Bill account created', type: BillAccountResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid vendor or payment method' })
  @ApiResponse({ status: 403, description: 'Forbidden - no access to household' })
  async create(
    @Body() createBillAccountDto: CreateBillAccountDto,
    @Request() req: { user: { sub: string } },
  ): Promise<BillAccountResponseDto> {
    return this.billAccountsService.create(req.user.sub, createBillAccountDto);
  }

  @Get()
  @ApiOperation({ summary: 'List bill accounts' })
  @ApiQuery({ name: 'householdId', required: true, description: 'Household ID' })
  @ApiQuery({ name: 'category', enum: VendorCategory, required: false })
  @ApiQuery({ name: 'upcomingDays', type: Number, required: false, description: 'Filter bills due within N days' })
  @ApiQuery({ name: 'includeInactive', type: Boolean, required: false })
  @ApiResponse({ status: 200, description: 'List of bill accounts', type: [BillAccountResponseDto] })
  async findAll(
    @Query('householdId') householdId: string,
    @Query('category') category?: VendorCategory,
    @Query('upcomingDays') upcomingDays?: string,
    @Query('includeInactive') includeInactive?: string,
    @Request() req?: { user: { sub: string } },
  ): Promise<BillAccountResponseDto[]> {
    return this.billAccountsService.findAll(req!.user.sub, {
      householdId,
      category,
      upcomingDays: upcomingDays ? parseInt(upcomingDays, 10) : undefined,
      includeInactive: includeInactive === 'true',
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a bill account by ID' })
  @ApiResponse({ status: 200, description: 'Bill account details', type: BillAccountResponseDto })
  @ApiResponse({ status: 404, description: 'Bill account not found' })
  async findOne(
    @Param('id') id: string,
    @Request() req: { user: { sub: string } },
  ): Promise<BillAccountResponseDto> {
    return this.billAccountsService.findOne(id, req.user.sub);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a bill account' })
  @ApiResponse({ status: 200, description: 'Bill account updated', type: BillAccountResponseDto })
  @ApiResponse({ status: 404, description: 'Bill account not found' })
  async update(
    @Param('id') id: string,
    @Body() updateBillAccountDto: UpdateBillAccountDto,
    @Request() req: { user: { sub: string } },
  ): Promise<BillAccountResponseDto> {
    return this.billAccountsService.update(id, req.user.sub, updateBillAccountDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a bill account (soft delete)' })
  @ApiResponse({ status: 204, description: 'Bill account deleted' })
  @ApiResponse({ status: 404, description: 'Bill account not found' })
  async remove(
    @Param('id') id: string,
    @Request() req: { user: { sub: string } },
  ): Promise<void> {
    return this.billAccountsService.remove(id, req.user.sub);
  }
}
