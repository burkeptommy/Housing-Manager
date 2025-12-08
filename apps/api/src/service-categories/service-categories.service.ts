import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../prisma';

import {
  CreateServiceCategoryDto,
  UpdateServiceCategoryDto,
  ServiceCategoryDto,
} from './dto';

@Injectable()
export class ServiceCategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateServiceCategoryDto): Promise<ServiceCategoryDto> {
    try {
      const category = await this.prisma.serviceCategory.create({
        data: {
          name: dto.name,
          description: dto.description,
          icon: dto.icon,
          sortOrder: dto.sortOrder ?? 0,
          isActive: dto.isActive ?? true,
        },
      });

      return this.mapToDto(category);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2002') {
          throw new ConflictException(`Service category with name "${dto.name}" already exists`);
        }
      }
      throw error;
    }
  }

  async findAll(includeInactive = false): Promise<ServiceCategoryDto[]> {
    const where = includeInactive ? {} : { isActive: true };

    const categories = await this.prisma.serviceCategory.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });

    return categories.map((c) => this.mapToDto(c));
  }

  async findOne(id: string): Promise<ServiceCategoryDto> {
    const category = await this.prisma.serviceCategory.findUnique({
      where: { id },
    });

    if (!category) {
      throw new NotFoundException(`Service category with ID ${id} not found`);
    }

    return this.mapToDto(category);
  }

  async update(id: string, dto: UpdateServiceCategoryDto): Promise<ServiceCategoryDto> {
    // Check if category exists
    await this.findOne(id);

    try {
      const category = await this.prisma.serviceCategory.update({
        where: { id },
        data: {
          name: dto.name,
          description: dto.description,
          icon: dto.icon,
          sortOrder: dto.sortOrder,
          isActive: dto.isActive,
        },
      });

      return this.mapToDto(category);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2002') {
          throw new ConflictException(`Service category with name "${dto.name}" already exists`);
        }
      }
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    // Check if category exists
    await this.findOne(id);

    await this.prisma.serviceCategory.delete({
      where: { id },
    });
  }

  private mapToDto(category: Prisma.ServiceCategoryGetPayload<object>): ServiceCategoryDto {
    return {
      id: category.id,
      name: category.name,
      description: category.description,
      icon: category.icon,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    };
  }
}
