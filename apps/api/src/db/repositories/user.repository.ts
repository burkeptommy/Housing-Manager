import { Injectable } from '@nestjs/common';
import { Prisma, User, UserRole } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type UserWithHouseholds = Prisma.UserGetPayload<{
  include: { householdMembers: { include: { household: true } } };
}>;

@Injectable()
export class UserRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({ data });
  }

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async findByIdWithHouseholds(id: string): Promise<UserWithHouseholds | null> {
    return this.prisma.user.findUnique({
      where: { id },
      include: {
        householdMembers: {
          include: { household: true },
          where: { status: 'ACTIVE' },
        },
      },
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email } });
  }

  async findMany(
    params: PaginationParams & {
      role?: UserRole;
      search?: string;
    }
  ): Promise<PaginatedResult<User>> {
    const { page, pageSize, role, search } = params;

    const where: Prisma.UserWhereInput = {};

    if (role) {
      where.role = role;
    }

    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
    return this.prisma.user.update({ where: { id }, data });
  }

  async updateLastLogin(id: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { lastLoginAt: new Date() },
    });
  }

  async delete(id: string): Promise<User> {
    return this.prisma.user.delete({ where: { id } });
  }

  async verifyEmail(id: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: {
        emailVerified: true,
        emailVerifiedAt: new Date(),
      },
    });
  }
}
