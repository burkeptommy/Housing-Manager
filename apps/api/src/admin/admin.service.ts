import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UserRole } from '@prisma/client';
import * as admin from 'firebase-admin';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async getDashboardStats() {
    const [
      totalUsers,
      totalHouseholds,
      activeHouseholds,
      pendingOnboarding,
      homeManagers,
      handymen,
      recentActivity,
      usersByRole,
      householdsByPlan,
      onboardingByStatus,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.household.count(),
      this.prisma.household.count({ where: { subscriptionStatus: 'ACTIVE' } }),
      this.prisma.householdIntake.count({
        where: { status: { in: ['PENDING_CALL', 'CALL_SCHEDULED', 'INTAKE_PARTIAL'] } },
      }),
      this.prisma.user.count({ where: { role: 'MANAGER' } }),
      this.prisma.user.count({ where: { role: 'HANDYMAN' } }),
      this.prisma.activityLog.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: { household: { select: { name: true } } },
      }),
      this.prisma.user.groupBy({ by: ['role'], _count: true }),
      this.prisma.household.groupBy({ by: ['subscriptionPlan'], _count: true }),
      this.prisma.householdIntake.groupBy({ by: ['status'], _count: true }),
    ]);

    return {
      overview: { totalUsers, totalHouseholds, activeHouseholds, pendingOnboarding, homeManagers, handymen },
      usersByRole: usersByRole.map((r) => ({ role: r.role, count: r._count })),
      householdsByTier: householdsByPlan.map((t) => ({ tier: t.subscriptionPlan, count: t._count })),
      onboardingByStatus: onboardingByStatus.map((s) => ({ status: s.status, count: s._count })),
      recentActivity: recentActivity.map((a) => ({
        id: a.id, title: a.title, actorName: a.actorName, householdName: a.household?.name, createdAt: a.createdAt,
      })),
    };
  }

  async getUsers(filters?: { role?: UserRole; search?: string; page?: number; limit?: number }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const skip = (page - 1) * limit;
    const where: any = {};
    if (filters?.role) where.role = filters.role;
    if (filters?.search) {
      where.OR = [
        { displayName: { contains: filters.search, mode: 'insensitive' } },
        { email: { contains: filters.search, mode: 'insensitive' } },
      ];
    }
    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where, skip, take: limit, orderBy: { createdAt: 'desc' },
        include: { householdMembers: { include: { household: { select: { id: true, name: true } } }, take: 1 } },
      }),
      this.prisma.user.count({ where }),
    ]);
    return {
      users: users.map((u) => ({
        id: u.id,
        email: u.email,
        name: u.displayName || `${u.firstName || ''} ${u.lastName || ''}`.trim() || u.email,
        firstName: u.firstName,
        lastName: u.lastName,
        phone: u.phone,
        role: u.role,
        householdId: u.householdMembers[0]?.household?.id || null,
        householdName: u.householdMembers[0]?.household?.name || null,
        firebaseUid: u.firebaseUid,
        createdAt: u.createdAt,
        updatedAt: u.updatedAt,
      })),
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    };
  }

  async getUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        householdMembers: { include: { household: { include: { homeProfile: true } } } },
        ownedHouseholds: true,
        managedHouseholds: true,
        intakesManaged: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateUser(
    userId: string,
    data: { displayName?: string; firstName?: string; lastName?: string; phone?: string; role?: UserRole },
  ) {
    return this.prisma.user.update({ where: { id: userId }, data });
  }

  async deleteUser(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (user.firebaseUid) {
      try {
        await admin.auth().deleteUser(user.firebaseUid);
      } catch (e) {
        console.error('Failed to delete Firebase user:', e);
      }
    }
    return this.prisma.user.delete({ where: { id: userId } });
  }

  async resetUserPassword(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.email) throw new NotFoundException('User not found');
    const resetLink = await admin.auth().generatePasswordResetLink(user.email);
    return { success: true, message: `Password reset email sent to ${user.email}`, resetLink };
  }

  async createUser(data: {
    email: string;
    displayName: string;
    firstName?: string;
    lastName?: string;
    phone?: string;
    role: UserRole;
    password?: string;
  }) {
    const existing = await this.prisma.user.findUnique({ where: { email: data.email } });
    if (existing) throw new BadRequestException('Email already exists');
    let firebaseUid: string | undefined;
    if (data.password) {
      const firebaseUser = await admin.auth().createUser({
        email: data.email,
        password: data.password,
        displayName: data.displayName,
      });
      firebaseUid = firebaseUser.uid;
    }
    return this.prisma.user.create({
      data: {
        email: data.email,
        displayName: data.displayName,
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
        role: data.role,
        firebaseUid,
      },
    });
  }

  async getHouseholds(filters?: {
    status?: string;
    tier?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const skip = (page - 1) * limit;
    const where: any = {};
    if (filters?.status) where.subscriptionStatus = filters.status;
    if (filters?.tier) where.subscriptionPlan = filters.tier;
    if (filters?.search) where.OR = [{ name: { contains: filters.search, mode: 'insensitive' } }];
    const [households, total] = await Promise.all([
      this.prisma.household.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          homeProfile: { select: { addressLine1: true, city: true, state: true } },
          owner: { select: { displayName: true, email: true } },
          manager: { select: { displayName: true } },
          householdIntake: { select: { status: true } },
          _count: { select: { comprehensiveBills: true, familyMembers: true } },
        },
      }),
      this.prisma.household.count({ where }),
    ]);
    return {
      households: households.map((h) => ({
        id: h.id,
        name: h.name,
        tier: h.subscriptionPlan,
        status: h.subscriptionStatus,
        address: h.homeProfile
          ? `${h.homeProfile.addressLine1}, ${h.homeProfile.city}, ${h.homeProfile.state}`
          : null,
        primaryContact: h.owner ? { name: h.owner.displayName, email: h.owner.email } : null,
        homeManager: h.manager?.displayName || 'Unassigned',
        onboardingStatus: h.householdIntake?.status || null,
        billCount: h._count.comprehensiveBills,
        memberCount: h._count.familyMembers,
        monthlyFunding: 0,
        createdAt: h.createdAt,
      })),
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    };
  }

  async getHousehold(householdId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
        owner: true,
        manager: true,
        familyMembers: { include: { activities: true } },
        vehicles: true,
        vendors: true,
        comprehensiveBills: true,
        householdIntake: true,
        activityLogs: { take: 20, orderBy: { createdAt: 'desc' } },
      },
    });
    if (!household) throw new NotFoundException('Household not found');
    return household;
  }

  async updateHousehold(
    householdId: string,
    data: { name?: string; subscriptionPlan?: string; subscriptionStatus?: string },
  ) {
    return this.prisma.household.update({ where: { id: householdId }, data: data as any });
  }

  async assignHomeManager(householdId: string, managerId: string) {
    return this.prisma.household.update({ where: { id: householdId }, data: { managerId } });
  }

  async getOnboardingSessions(filters?: {
    status?: string;
    managerId?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const skip = (page - 1) * limit;
    const where: any = {};
    if (filters?.status) where.status = filters.status;
    if (filters?.managerId) where.managerId = filters.managerId;
    const [sessions, total] = await Promise.all([
      this.prisma.householdIntake.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          household: {
            include: {
              homeProfile: { select: { addressLine1: true, city: true, state: true } },
              owner: { select: { displayName: true, email: true } },
            },
          },
          manager: { select: { id: true, displayName: true } },
        },
      }),
      this.prisma.householdIntake.count({ where }),
    ]);
    return {
      sessions: sessions.map((s) => ({
        id: s.id,
        householdId: s.householdId,
        householdName: s.household.name,
        status: s.status,
        homeownerName: s.household.owner?.displayName || 'Unknown',
        homeownerEmail: s.household.owner?.email,
        address: s.household.homeProfile
          ? `${s.household.homeProfile.addressLine1}, ${s.household.homeProfile.city}`
          : null,
        selectedTier: s.selectedTier,
        biggestChallenge: s.biggestChallenge,
        assignedManager: s.manager ? { id: s.manager.id, name: s.manager.displayName } : null,
        progress: Math.round(
          (s.progressFamily +
            s.progressProperty +
            s.progressZones +
            s.progressSystems +
            s.progressVendors +
            s.progressBills) /
            6,
        ),
        monthlyFundingEstimate: s.calculatedMonthlyFunding,
        createdAt: s.createdAt,
        scheduledAt: s.scheduledAt,
        completedAt: s.completedAt,
      })),
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    };
  }

  async reassignOnboarding(sessionId: string, managerId: string) {
    return this.prisma.householdIntake.update({ where: { id: sessionId }, data: { managerId } });
  }

  async updateOnboardingStatus(sessionId: string, status: string) {
    return this.prisma.householdIntake.update({
      where: { id: sessionId },
      data: { status: status as any },
    });
  }

  async getTeamMembers() {
    const team = await this.prisma.user.findMany({
      where: { role: { in: ['MANAGER', 'HANDYMAN', 'ADMIN'] } },
      include: {
        intakesManaged: { where: { status: { not: 'ACTIVE' } }, select: { id: true } },
        managedHouseholds: { select: { id: true } },
      },
    });
    return team.map((t) => ({
      id: t.id,
      email: t.email,
      name: t.displayName || `${t.firstName || ''} ${t.lastName || ''}`.trim(),
      phone: t.phone,
      role: t.role,
      pendingOnboardings: t.intakesManaged.length,
      activeHouseholds: t.managedHouseholds.length,
      createdAt: t.createdAt,
    }));
  }

  async getManagerWorkload(managerId: string) {
    const [manager, onboardings, households] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: managerId } }),
      this.prisma.householdIntake.findMany({
        where: { managerId },
        include: { household: { include: { owner: true } } },
      }),
      this.prisma.household.findMany({
        where: { managerId },
        include: { homeProfile: true, owner: true },
      }),
    ]);
    return { manager, onboardings, households };
  }

  async getActivityLog(filters?: {
    householdId?: string;
    actorId?: string;
    category?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 100;
    const skip = (page - 1) * limit;
    const where: any = {};
    if (filters?.householdId) where.householdId = filters.householdId;
    if (filters?.actorId) where.actorId = filters.actorId;
    if (filters?.category) where.category = filters.category;
    const [logs, total] = await Promise.all([
      this.prisma.activityLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: { household: { select: { name: true } } },
      }),
      this.prisma.activityLog.count({ where }),
    ]);
    return { logs, pagination: { page, limit, total, pages: Math.ceil(total / limit) } };
  }
}
