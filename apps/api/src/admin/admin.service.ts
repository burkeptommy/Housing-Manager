import { Injectable, NotFoundException } from '@nestjs/common';
import { UserRole } from '@prisma/client';

import { DbService } from '../db';

@Injectable()
export class AdminService {
  constructor(private db: DbService) {}

  /**
   * Get all users with optional role filter
   */
  async getUsers(role?: UserRole) {
    return this.db.user.findMany({
      where: role ? { role } : undefined,
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        phone: true,
        isActive: true,
        emailVerified: true,
        lastLoginAt: true,
        createdAt: true,
        updatedAt: true,
        _count: {
          select: {
            householdMembers: true,
            ownedHouseholds: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get user by ID with details
   */
  async getUserById(id: string) {
    const user = await this.db.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        phone: true,
        isActive: true,
        emailVerified: true,
        lastLoginAt: true,
        createdAt: true,
        updatedAt: true,
        householdMembers: {
          select: {
            id: true,
            role: true,
            status: true,
            household: {
              select: {
                id: true,
                name: true,
              },
            },
          },
        },
        ownedHouseholds: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  /**
   * Update user role
   */
  async updateUserRole(id: string, role: UserRole) {
    return this.db.user.update({
      where: { id },
      data: { role },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
      },
    });
  }

  /**
   * Toggle user active status
   */
  async toggleUserActive(id: string) {
    const user = await this.db.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.db.user.update({
      where: { id },
      data: { isActive: !user.isActive },
      select: {
        id: true,
        email: true,
        isActive: true,
      },
    });
  }

  /**
   * Get all households
   */
  async getHouseholds() {
    return this.db.household.findMany({
      select: {
        id: true,
        name: true,
        description: true,
        createdAt: true,
        updatedAt: true,
        owner: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
          },
        },
        homeProfile: {
          select: {
            id: true,
            propertyType: true,
            addressLine1: true,
            city: true,
            state: true,
            postalCode: true,
          },
        },
        _count: {
          select: {
            members: true,
            serviceRequests: true,
            tasks: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get household by ID with details
   */
  async getHouseholdById(id: string) {
    const household = await this.db.household.findUnique({
      where: { id },
      include: {
        owner: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
          },
        },
        members: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                firstName: true,
                lastName: true,
              },
            },
          },
        },
        homeProfile: true,
        _count: {
          select: {
            serviceRequests: true,
            tasks: true,
            files: true,
          },
        },
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    return household;
  }

  /**
   * Get all service categories
   */
  async getServiceCategories() {
    return this.db.serviceCategory.findMany({
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        name: true,
        description: true,
        icon: true,
        sortOrder: true,
        isActive: true,
        createdAt: true,
        _count: {
          select: {
            serviceRequests: true,
            vendors: true,
          },
        },
      },
    });
  }

  /**
   * Create service category
   */
  async createServiceCategory(data: {
    name: string;
    description?: string;
    icon?: string;
    sortOrder?: number;
  }) {
    return this.db.serviceCategory.create({
      data: {
        name: data.name,
        description: data.description,
        icon: data.icon,
        sortOrder: data.sortOrder ?? 0,
        isActive: true,
      },
    });
  }

  /**
   * Update service category
   */
  async updateServiceCategory(
    id: string,
    data: {
      name?: string;
      description?: string;
      icon?: string;
      sortOrder?: number;
      isActive?: boolean;
    },
  ) {
    return this.db.serviceCategory.update({
      where: { id },
      data,
    });
  }

  /**
   * Get dashboard stats
   */
  async getDashboardStats() {
    const [
      totalUsers,
      activeUsers,
      totalHouseholds,
      totalRequests,
      pendingRequests,
      completedRequests,
    ] = await Promise.all([
      this.db.user.count(),
      this.db.user.count({ where: { isActive: true } }),
      this.db.household.count(),
      this.db.serviceRequest.count(),
      this.db.serviceRequest.count({
        where: { status: { in: ['SUBMITTED', 'ASSIGNED', 'IN_PROGRESS'] } },
      }),
      this.db.serviceRequest.count({ where: { status: 'COMPLETED' } }),
    ]);

    return {
      users: {
        total: totalUsers,
        active: activeUsers,
      },
      households: {
        total: totalHouseholds,
      },
      serviceRequests: {
        total: totalRequests,
        pending: pendingRequests,
        completed: completedRequests,
      },
    };
  }
}
