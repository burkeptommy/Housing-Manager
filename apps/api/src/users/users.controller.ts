import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';

import { JwtAuthGuard, RolesGuard, Roles } from '../auth';

import { UsersService, PaginatedUsers } from './users.service';
import { UserDto, AdminUpdateUserDto, UserListQueryDto } from './dto';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Get a user by ID (Admin only)
   */
  @Get(':id')
  @Roles(UserRole.ADMIN)
  async findOne(@Param('id') id: string): Promise<UserDto> {
    return this.usersService.findById(id);
  }

  /**
   * Get all users with pagination (Admin only)
   */
  @Get()
  @Roles(UserRole.ADMIN)
  async findAll(@Query() query: UserListQueryDto): Promise<PaginatedUsers> {
    return this.usersService.findMany(query);
  }

  /**
   * Update a user (Admin only)
   */
  @Patch(':id')
  @Roles(UserRole.ADMIN)
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
  async delete(@Param('id') id: string): Promise<void> {
    return this.usersService.delete(id);
  }
}
