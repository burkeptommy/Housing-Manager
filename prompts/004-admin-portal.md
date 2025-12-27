# Haven Admin Portal: Complete Control Center

**Created:** December 27, 2024  
**Purpose:** Build a comprehensive admin portal for full platform control  
**Priority:** High - Needed for managing users, households, and operations

---

## Overview

Build an admin portal at `/admin/*` that gives Tom (and future admins) complete control over:
- All users across all roles
- All households and their status
- Onboarding pipeline
- Haven team (Home Managers, Handymen)
- Activity monitoring
- System settings

---

## PHASE 1: Admin Authentication & Guard

### Task 1.1: Create Admin Guard

Create `apps/api/src/auth/admin.guard.ts`:

```typescript
import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';

@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user || user.role !== 'ADMIN') {
      throw new ForbiddenException('Admin access required');
    }

    return true;
  }
}
```

### Task 1.2: Create Admin User in Firebase

Ensure there's an admin user. Add to seed or create manually:
- Email: `tom@haven.app` (or your email)
- Role: `ADMIN`
- Firebase UID: Link to your Firebase account

Update `apps/api/prisma/seed.ts` to include:

```typescript
// In the Haven Team section, add:
const tomAdmin = await prisma.user.create({
  data: {
    email: 'tom@haven.app', // Change to your actual email
    firebaseUid: 'YOUR_FIREBASE_UID', // Get from Firebase Console
    name: 'Tom Burke',
    firstName: 'Tom',
    lastName: 'Burke',
    role: UserRole.ADMIN,
  },
});
console.log('  ✓ Tom Burke (Admin)');
```

---

## PHASE 2: Admin API Endpoints

### Task 2.1: Create Admin Service

Create `apps/api/src/admin/admin.service.ts`:

```typescript
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UserRole } from '@prisma/client';
import * as admin from 'firebase-admin';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  // =========================================================================
  // DASHBOARD STATS
  // =========================================================================
  
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
      householdsByTier,
      onboardingByStatus,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.household.count(),
      this.prisma.household.count({ where: { status: 'ACTIVE' } }),
      this.prisma.onboardingSession.count({
        where: { status: { in: ['PENDING_CALL', 'CALL_SCHEDULED', 'INTAKE_PARTIAL'] } },
      }),
      this.prisma.user.count({ where: { role: 'HOME_MANAGER' } }),
      this.prisma.user.count({ where: { role: 'HANDYMAN' } }),
      this.prisma.activityLog.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: { household: { select: { name: true } } },
      }),
      this.prisma.user.groupBy({
        by: ['role'],
        _count: true,
      }),
      this.prisma.household.groupBy({
        by: ['tier'],
        _count: true,
      }),
      this.prisma.onboardingSession.groupBy({
        by: ['status'],
        _count: true,
      }),
    ]);

    return {
      overview: {
        totalUsers,
        totalHouseholds,
        activeHouseholds,
        pendingOnboarding,
        homeManagers,
        handymen,
      },
      usersByRole: usersByRole.map((r) => ({ role: r.role, count: r._count })),
      householdsByTier: householdsByTier.map((t) => ({ tier: t.tier, count: t._count })),
      onboardingByStatus: onboardingByStatus.map((s) => ({ status: s.status, count: s._count })),
      recentActivity: recentActivity.map((a) => ({
        id: a.id,
        title: a.title,
        actorName: a.actorName,
        householdName: a.household?.name,
        createdAt: a.createdAt,
      })),
    };
  }

  // =========================================================================
  // USER MANAGEMENT
  // =========================================================================

  async getUsers(filters?: {
    role?: UserRole;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (filters?.role) {
      where.role = filters.role;
    }

    if (filters?.search) {
      where.OR = [
        { name: { contains: filters.search, mode: 'insensitive' } },
        { email: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          household: { select: { id: true, name: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      users: users.map((u) => ({
        id: u.id,
        email: u.email,
        name: u.name,
        firstName: u.firstName,
        lastName: u.lastName,
        phone: u.phone,
        role: u.role,
        householdId: u.householdId,
        householdName: u.household?.name,
        firebaseUid: u.firebaseUid,
        createdAt: u.createdAt,
        updatedAt: u.updatedAt,
      })),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        household: {
          include: {
            property: true,
            settings: true,
          },
        },
        assignedOnboardings: true,
        managedHouseholds: { include: { household: true } },
      },
    });

    if (!user) throw new NotFoundException('User not found');

    return user;
  }

  async updateUser(userId: string, data: {
    name?: string;
    firstName?: string;
    lastName?: string;
    phone?: string;
    role?: UserRole;
    householdId?: string | null;
  }) {
    return this.prisma.user.update({
      where: { id: userId },
      data,
    });
  }

  async deleteUser(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    // Delete from Firebase if exists
    if (user.firebaseUid) {
      try {
        await admin.auth().deleteUser(user.firebaseUid);
      } catch (e) {
        console.error('Failed to delete Firebase user:', e);
      }
    }

    // Delete from database
    return this.prisma.user.delete({ where: { id: userId } });
  }

  async resetUserPassword(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.email) throw new NotFoundException('User not found');

    // Send password reset email via Firebase
    const resetLink = await admin.auth().generatePasswordResetLink(user.email);
    
    // TODO: Send email with reset link
    // For now, return the link (in production, send via email service)
    
    return { 
      success: true, 
      message: `Password reset email sent to ${user.email}`,
      // Remove this in production:
      resetLink,
    };
  }

  async createUser(data: {
    email: string;
    name: string;
    firstName?: string;
    lastName?: string;
    phone?: string;
    role: UserRole;
    householdId?: string;
    password?: string;
  }) {
    // Check if email exists
    const existing = await this.prisma.user.findUnique({ where: { email: data.email } });
    if (existing) throw new BadRequestException('Email already exists');

    // Create in Firebase
    let firebaseUid: string | undefined;
    if (data.password) {
      const firebaseUser = await admin.auth().createUser({
        email: data.email,
        password: data.password,
        displayName: data.name,
      });
      firebaseUid = firebaseUser.uid;
    }

    // Create in database
    return this.prisma.user.create({
      data: {
        email: data.email,
        name: data.name,
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
        role: data.role,
        householdId: data.householdId,
        firebaseUid,
      },
    });
  }

  // =========================================================================
  // HOUSEHOLD MANAGEMENT
  // =========================================================================

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

    if (filters?.status) {
      where.status = filters.status;
    }

    if (filters?.tier) {
      where.tier = filters.tier;
    }

    if (filters?.search) {
      where.OR = [
        { name: { contains: filters.search, mode: 'insensitive' } },
        { property: { street: { contains: filters.search, mode: 'insensitive' } } },
      ];
    }

    const [households, total] = await Promise.all([
      this.prisma.household.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          property: { select: { street: true, city: true, state: true } },
          users: { where: { role: 'HOMEOWNER' }, take: 1, select: { name: true, email: true } },
          settings: { include: { homeManager: { select: { name: true } } } },
          onboardingSession: { select: { status: true } },
          _count: { select: { bills: true, familyMembers: true } },
        },
      }),
      this.prisma.household.count({ where }),
    ]);

    return {
      households: households.map((h) => ({
        id: h.id,
        name: h.name,
        tier: h.tier,
        status: h.status,
        address: h.property
          ? `${h.property.street}, ${h.property.city}, ${h.property.state}`
          : null,
        primaryContact: h.users[0] || null,
        homeManager: h.settings?.homeManager?.name || 'Unassigned',
        onboardingStatus: h.onboardingSession?.status || null,
        billCount: h._count.bills,
        memberCount: h._count.familyMembers,
        monthlyFunding: h.settings?.monthlyFunding || 0,
        createdAt: h.createdAt,
      })),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getHousehold(householdId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        property: true,
        users: true,
        familyMembers: { include: { activities: true } },
        vehicles: true,
        vendors: true,
        bills: true,
        settings: { include: { homeManager: true } },
        onboardingSession: true,
        activityLogs: { take: 20, orderBy: { createdAt: 'desc' } },
      },
    });

    if (!household) throw new NotFoundException('Household not found');

    return household;
  }

  async updateHousehold(householdId: string, data: {
    name?: string;
    tier?: string;
    status?: string;
  }) {
    return this.prisma.household.update({
      where: { id: householdId },
      data,
    });
  }

  async assignHomeManager(householdId: string, managerId: string) {
    // Update or create settings
    return this.prisma.householdSettings.upsert({
      where: { householdId },
      update: { homeManagerId: managerId },
      create: { householdId, homeManagerId: managerId },
    });
  }

  async updateHouseholdFunding(householdId: string, monthlyFunding: number) {
    return this.prisma.householdSettings.upsert({
      where: { householdId },
      update: { monthlyFunding },
      create: { householdId, monthlyFunding },
    });
  }

  // =========================================================================
  // ONBOARDING MANAGEMENT
  // =========================================================================

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

    if (filters?.status) {
      where.status = filters.status;
    }

    if (filters?.managerId) {
      where.assignedManagerId = filters.managerId;
    }

    const [sessions, total] = await Promise.all([
      this.prisma.onboardingSession.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          household: {
            include: {
              property: { select: { street: true, city: true, state: true } },
              users: { where: { role: 'HOMEOWNER' }, take: 1 },
            },
          },
          assignedManager: { select: { id: true, name: true } },
        },
      }),
      this.prisma.onboardingSession.count({ where }),
    ]);

    return {
      sessions: sessions.map((s) => ({
        id: s.id,
        householdId: s.householdId,
        householdName: s.household.name,
        status: s.status,
        homeownerName: s.household.users[0]?.name || 'Unknown',
        homeownerEmail: s.household.users[0]?.email,
        address: s.household.property
          ? `${s.household.property.street}, ${s.household.property.city}`
          : null,
        selectedTier: s.selectedTier,
        biggestChallenge: s.biggestChallenge,
        assignedManager: s.assignedManager,
        progress: Math.round(
          (s.progressFamily +
            s.progressProperty +
            s.progressZones +
            s.progressSystems +
            s.progressVendors +
            s.progressBills) /
            6
        ),
        monthlyFundingEstimate: s.monthlyFundingEstimate,
        createdAt: s.createdAt,
        callScheduledFor: s.callScheduledFor,
        callCompletedAt: s.callCompletedAt,
      })),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async reassignOnboarding(sessionId: string, managerId: string) {
    return this.prisma.onboardingSession.update({
      where: { id: sessionId },
      data: { assignedManagerId: managerId },
    });
  }

  async updateOnboardingStatus(sessionId: string, status: string) {
    return this.prisma.onboardingSession.update({
      where: { id: sessionId },
      data: { status: status as any },
    });
  }

  // =========================================================================
  // HAVEN TEAM MANAGEMENT
  // =========================================================================

  async getTeamMembers() {
    const team = await this.prisma.user.findMany({
      where: {
        role: { in: ['HOME_MANAGER', 'HANDYMAN', 'ADMIN'] },
      },
      include: {
        assignedOnboardings: {
          where: { status: { not: 'ACTIVE' } },
          select: { id: true },
        },
        managedHouseholds: {
          select: { householdId: true },
        },
      },
    });

    return team.map((t) => ({
      id: t.id,
      email: t.email,
      name: t.name,
      phone: t.phone,
      role: t.role,
      pendingOnboardings: t.assignedOnboardings.length,
      activeHouseholds: t.managedHouseholds.length,
      createdAt: t.createdAt,
    }));
  }

  async getManagerWorkload(managerId: string) {
    const [manager, onboardings, households] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: managerId } }),
      this.prisma.onboardingSession.findMany({
        where: { assignedManagerId: managerId },
        include: {
          household: { include: { users: { take: 1 } } },
        },
      }),
      this.prisma.householdSettings.findMany({
        where: { homeManagerId: managerId },
        include: {
          household: {
            include: {
              property: true,
              users: { take: 1 },
            },
          },
        },
      }),
    ]);

    return {
      manager,
      onboardings,
      households: households.map((h) => h.household),
    };
  }

  // =========================================================================
  // ACTIVITY LOG
  // =========================================================================

  async getActivityLog(filters?: {
    householdId?: string;
    actorId?: string;
    category?: string;
    startDate?: Date;
    endDate?: Date;
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
    if (filters?.startDate) where.createdAt = { gte: filters.startDate };
    if (filters?.endDate) {
      where.createdAt = { ...where.createdAt, lte: filters.endDate };
    }

    const [logs, total] = await Promise.all([
      this.prisma.activityLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          household: { select: { name: true } },
        },
      }),
      this.prisma.activityLog.count({ where }),
    ]);

    return {
      logs,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    };
  }
}
```

### Task 2.2: Create Admin Controller

Create `apps/api/src/admin/admin.controller.ts`:

```typescript
import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { AdminService } from './admin.service';
import { UserRole } from '@prisma/client';

@Controller('admin')
@UseGuards(FirebaseAuthGuard, AdminGuard)
export class AdminController {
  constructor(private adminService: AdminService) {}

  // =========================================================================
  // DASHBOARD
  // =========================================================================

  @Get('dashboard')
  async getDashboard() {
    return this.adminService.getDashboardStats();
  }

  // =========================================================================
  // USERS
  // =========================================================================

  @Get('users')
  async getUsers(
    @Query('role') role?: UserRole,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.adminService.getUsers({
      role,
      search,
      page: page ? parseInt(page) : undefined,
      limit: limit ? parseInt(limit) : undefined,
    });
  }

  @Get('users/:id')
  async getUser(@Param('id') id: string) {
    return this.adminService.getUser(id);
  }

  @Post('users')
  async createUser(
    @Body()
    body: {
      email: string;
      name: string;
      firstName?: string;
      lastName?: string;
      phone?: string;
      role: UserRole;
      householdId?: string;
      password?: string;
    }
  ) {
    return this.adminService.createUser(body);
  }

  @Put('users/:id')
  async updateUser(
    @Param('id') id: string,
    @Body()
    body: {
      name?: string;
      firstName?: string;
      lastName?: string;
      phone?: string;
      role?: UserRole;
      householdId?: string | null;
    }
  ) {
    return this.adminService.updateUser(id, body);
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') id: string) {
    return this.adminService.deleteUser(id);
  }

  @Post('users/:id/reset-password')
  async resetPassword(@Param('id') id: string) {
    return this.adminService.resetUserPassword(id);
  }

  // =========================================================================
  // HOUSEHOLDS
  // =========================================================================

  @Get('households')
  async getHouseholds(
    @Query('status') status?: string,
    @Query('tier') tier?: string,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.adminService.getHouseholds({
      status,
      tier,
      search,
      page: page ? parseInt(page) : undefined,
      limit: limit ? parseInt(limit) : undefined,
    });
  }

  @Get('households/:id')
  async getHousehold(@Param('id') id: string) {
    return this.adminService.getHousehold(id);
  }

  @Put('households/:id')
  async updateHousehold(
    @Param('id') id: string,
    @Body() body: { name?: string; tier?: string; status?: string }
  ) {
    return this.adminService.updateHousehold(id, body);
  }

  @Post('households/:id/assign-manager')
  async assignManager(
    @Param('id') id: string,
    @Body() body: { managerId: string }
  ) {
    return this.adminService.assignHomeManager(id, body.managerId);
  }

  @Put('households/:id/funding')
  async updateFunding(
    @Param('id') id: string,
    @Body() body: { monthlyFunding: number }
  ) {
    return this.adminService.updateHouseholdFunding(id, body.monthlyFunding);
  }

  // =========================================================================
  // ONBOARDING
  // =========================================================================

  @Get('onboarding')
  async getOnboardingSessions(
    @Query('status') status?: string,
    @Query('managerId') managerId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.adminService.getOnboardingSessions({
      status,
      managerId,
      page: page ? parseInt(page) : undefined,
      limit: limit ? parseInt(limit) : undefined,
    });
  }

  @Post('onboarding/:id/reassign')
  async reassignOnboarding(
    @Param('id') id: string,
    @Body() body: { managerId: string }
  ) {
    return this.adminService.reassignOnboarding(id, body.managerId);
  }

  @Put('onboarding/:id/status')
  async updateOnboardingStatus(
    @Param('id') id: string,
    @Body() body: { status: string }
  ) {
    return this.adminService.updateOnboardingStatus(id, body.status);
  }

  // =========================================================================
  // TEAM
  // =========================================================================

  @Get('team')
  async getTeam() {
    return this.adminService.getTeamMembers();
  }

  @Get('team/:id/workload')
  async getManagerWorkload(@Param('id') id: string) {
    return this.adminService.getManagerWorkload(id);
  }

  // =========================================================================
  // ACTIVITY
  // =========================================================================

  @Get('activity')
  async getActivity(
    @Query('householdId') householdId?: string,
    @Query('actorId') actorId?: string,
    @Query('category') category?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.adminService.getActivityLog({
      householdId,
      actorId,
      category,
      page: page ? parseInt(page) : undefined,
      limit: limit ? parseInt(limit) : undefined,
    });
  }
}
```

### Task 2.3: Create Admin Module

Create `apps/api/src/admin/admin.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
```

### Task 2.4: Register Admin Module

Update `apps/api/src/app.module.ts`:

```typescript
import { AdminModule } from './admin/admin.module';

@Module({
  imports: [
    // ... existing imports
    AdminModule,
  ],
})
export class AppModule {}
```

---

## PHASE 3: Admin Frontend - Layout & Navigation

### Task 3.1: Create Admin Layout

Create `apps/web/src/app/admin/layout.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  LayoutDashboard,
  Users,
  Home,
  ClipboardList,
  UserCog,
  Activity,
  Settings,
  LogOut,
  Menu,
  X,
  Shield,
} from 'lucide-react';

const navigation = [
  { name: 'Dashboard', href: '/admin', icon: LayoutDashboard },
  { name: 'Users', href: '/admin/users', icon: Users },
  { name: 'Households', href: '/admin/households', icon: Home },
  { name: 'Onboarding', href: '/admin/onboarding', icon: ClipboardList },
  { name: 'Haven Team', href: '/admin/team', icon: UserCog },
  { name: 'Activity', href: '/admin/activity', icon: Activity },
  { name: 'Settings', href: '/admin/settings', icon: Settings },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { user, logout } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [authorized, setAuthorized] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is admin
    const checkAdmin = async () => {
      if (!user) {
        router.push('/login?redirect=/admin');
        return;
      }

      // Fetch user role from API
      try {
        const token = await user.getIdToken();
        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/user/me`,
          { headers: { Authorization: `Bearer ${token}` } }
        );
        
        if (response.ok) {
          const userData = await response.json();
          if (userData.role === 'ADMIN') {
            setAuthorized(true);
          } else {
            router.push('/app');
          }
        } else {
          router.push('/login');
        }
      } catch (e) {
        console.error('Auth check failed:', e);
        router.push('/login');
      } finally {
        setLoading(false);
      }
    };

    checkAdmin();
  }, [user, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-haven-navy-900" />
      </div>
    );
  }

  if (!authorized) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Mobile sidebar backdrop */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div
        className={`fixed inset-y-0 left-0 z-50 w-64 bg-haven-navy-950 transform transition-transform lg:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex items-center gap-3 px-6 py-5 border-b border-haven-navy-800">
            <div className="w-10 h-10 bg-haven-champagne-500 rounded-xl flex items-center justify-center">
              <Shield className="w-6 h-6 text-haven-navy-950" />
            </div>
            <div>
              <span className="text-white font-bold text-lg">Haven</span>
              <span className="text-haven-champagne-300 text-sm block">Admin</span>
            </div>
            <button
              className="ml-auto lg:hidden text-gray-400 hover:text-white"
              onClick={() => setSidebarOpen(false)}
            >
              <X className="w-6 h-6" />
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
            {navigation.map((item) => {
              const isActive = pathname === item.href || 
                (item.href !== '/admin' && pathname.startsWith(item.href));
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition ${
                    isActive
                      ? 'bg-haven-champagne-500 text-haven-navy-950'
                      : 'text-gray-300 hover:bg-haven-navy-800 hover:text-white'
                  }`}
                  onClick={() => setSidebarOpen(false)}
                >
                  <item.icon className="w-5 h-5" />
                  {item.name}
                </Link>
              );
            })}
          </nav>

          {/* User */}
          <div className="p-4 border-t border-haven-navy-800">
            <div className="flex items-center gap-3 px-4 py-3">
              <div className="w-10 h-10 bg-haven-navy-700 rounded-full flex items-center justify-center">
                <span className="text-white font-medium">
                  {user?.displayName?.[0] || 'A'}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-sm font-medium truncate">
                  {user?.displayName || 'Admin'}
                </p>
                <p className="text-gray-400 text-xs truncate">{user?.email}</p>
              </div>
              <button
                onClick={() => logout()}
                className="text-gray-400 hover:text-white"
              >
                <LogOut className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Mobile header */}
        <div className="sticky top-0 z-30 lg:hidden bg-white border-b border-gray-200 px-4 py-3">
          <button
            onClick={() => setSidebarOpen(true)}
            className="text-gray-600 hover:text-gray-900"
          >
            <Menu className="w-6 h-6" />
          </button>
        </div>

        {/* Page content */}
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
```

---

## PHASE 4: Admin Dashboard Page

### Task 4.1: Create Dashboard Page

Create `apps/web/src/app/admin/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  Users,
  Home,
  ClipboardList,
  UserCog,
  TrendingUp,
  Clock,
  CheckCircle,
  AlertCircle,
} from 'lucide-react';

interface DashboardStats {
  overview: {
    totalUsers: number;
    totalHouseholds: number;
    activeHouseholds: number;
    pendingOnboarding: number;
    homeManagers: number;
    handymen: number;
  };
  usersByRole: Array<{ role: string; count: number }>;
  householdsByTier: Array<{ tier: string; count: number }>;
  onboardingByStatus: Array<{ status: string; count: number }>;
  recentActivity: Array<{
    id: string;
    title: string;
    actorName: string;
    householdName: string;
    createdAt: string;
  }>;
}

const tierColors: Record<string, string> = {
  ESSENTIALS: 'bg-gray-100 text-gray-700',
  LITE: 'bg-blue-100 text-blue-700',
  HAVEN: 'bg-haven-champagne-100 text-haven-champagne-700',
  'HAVEN+': 'bg-purple-100 text-purple-700',
  ESTATE: 'bg-amber-100 text-amber-700',
};

const statusLabels: Record<string, string> = {
  PENDING_CALL: 'Pending Call',
  CALL_SCHEDULED: 'Scheduled',
  CALL_IN_PROGRESS: 'In Progress',
  INTAKE_PARTIAL: 'Partial',
  INTAKE_COMPLETE: 'Complete',
  PROFILE_DELIVERED: 'Delivered',
  ACTIVE: 'Active',
};

export default function AdminDashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/dashboard`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setStats(await response.json());
      }
    } catch (e) {
      console.error('Failed to load stats:', e);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="animate-pulse space-y-6">
        <div className="h-8 bg-gray-200 rounded w-48" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-32 bg-gray-200 rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  if (!stats) {
    return <div className="text-center text-gray-500">Failed to load dashboard</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
        <p className="text-gray-500">Haven platform overview</p>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Link href="/admin/users" className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{stats.overview.totalUsers}</p>
              <p className="text-sm text-gray-500">Total Users</p>
            </div>
          </div>
        </Link>

        <Link href="/admin/households" className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
              <Home className="w-6 h-6 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {stats.overview.activeHouseholds}
                <span className="text-sm text-gray-400 font-normal">
                  /{stats.overview.totalHouseholds}
                </span>
              </p>
              <p className="text-sm text-gray-500">Active Households</p>
            </div>
          </div>
        </Link>

        <Link href="/admin/onboarding" className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
              <ClipboardList className="w-6 h-6 text-orange-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{stats.overview.pendingOnboarding}</p>
              <p className="text-sm text-gray-500">Pending Onboarding</p>
            </div>
          </div>
        </Link>

        <Link href="/admin/team" className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
              <UserCog className="w-6 h-6 text-purple-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {stats.overview.homeManagers + stats.overview.handymen}
              </p>
              <p className="text-sm text-gray-500">Team Members</p>
            </div>
          </div>
        </Link>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Households by Tier */}
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h2 className="font-semibold text-gray-900 mb-4">Households by Tier</h2>
          <div className="space-y-3">
            {stats.householdsByTier.map((t) => (
              <div key={t.tier} className="flex items-center justify-between">
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${tierColors[t.tier] || 'bg-gray-100'}`}>
                  {t.tier}
                </span>
                <span className="font-semibold text-gray-900">{t.count}</span>
              </div>
            ))}
            {stats.householdsByTier.length === 0 && (
              <p className="text-gray-400 text-sm">No households yet</p>
            )}
          </div>
        </div>

        {/* Onboarding Pipeline */}
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h2 className="font-semibold text-gray-900 mb-4">Onboarding Pipeline</h2>
          <div className="space-y-3">
            {stats.onboardingByStatus.map((s) => (
              <div key={s.status} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  {s.status === 'ACTIVE' ? (
                    <CheckCircle className="w-4 h-4 text-green-500" />
                  ) : s.status === 'PENDING_CALL' ? (
                    <AlertCircle className="w-4 h-4 text-orange-500" />
                  ) : (
                    <Clock className="w-4 h-4 text-blue-500" />
                  )}
                  <span className="text-gray-700">{statusLabels[s.status] || s.status}</span>
                </div>
                <span className="font-semibold text-gray-900">{s.count}</span>
              </div>
            ))}
            {stats.onboardingByStatus.length === 0 && (
              <p className="text-gray-400 text-sm">No onboarding sessions</p>
            )}
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl p-6 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold text-gray-900">Recent Activity</h2>
          <Link href="/admin/activity" className="text-sm text-haven-champagne-600 hover:underline">
            View all
          </Link>
        </div>
        <div className="divide-y divide-gray-100">
          {stats.recentActivity.map((activity) => (
            <div key={activity.id} className="py-3 flex items-center justify-between">
              <div>
                <p className="font-medium text-gray-900">{activity.title}</p>
                <p className="text-sm text-gray-500">
                  {activity.actorName} • {activity.householdName}
                </p>
              </div>
              <span className="text-xs text-gray-400">
                {new Date(activity.createdAt).toLocaleDateString()}
              </span>
            </div>
          ))}
          {stats.recentActivity.length === 0 && (
            <p className="py-4 text-gray-400 text-sm text-center">No recent activity</p>
          )}
        </div>
      </div>
    </div>
  );
}
```

---

## PHASE 5: Users Management Page

### Task 5.1: Create Users List Page

Create `apps/web/src/app/admin/users/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  Search,
  Plus,
  MoreVertical,
  Mail,
  Key,
  Trash2,
  Edit,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';

interface User {
  id: string;
  email: string;
  name: string;
  firstName: string;
  lastName: string;
  phone: string;
  role: string;
  householdId: string | null;
  householdName: string | null;
  createdAt: string;
}

interface UsersResponse {
  users: User[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

const roleColors: Record<string, string> = {
  ADMIN: 'bg-red-100 text-red-700',
  HOME_MANAGER: 'bg-purple-100 text-purple-700',
  HANDYMAN: 'bg-blue-100 text-blue-700',
  HOMEOWNER: 'bg-green-100 text-green-700',
  VENDOR: 'bg-orange-100 text-orange-700',
};

export default function AdminUsersPage() {
  const { user } = useAuth();
  const [data, setData] = useState<UsersResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [page, setPage] = useState(1);
  const [selectedUser, setSelectedUser] = useState<string | null>(null);

  useEffect(() => {
    fetchUsers();
  }, [page, roleFilter]);

  const fetchUsers = async (searchQuery?: string) => {
    try {
      const token = await user?.getIdToken();
      const params = new URLSearchParams();
      params.set('page', page.toString());
      params.set('limit', '20');
      if (roleFilter) params.set('role', roleFilter);
      if (searchQuery || search) params.set('search', searchQuery || search);

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/users?${params}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setData(await response.json());
      }
    } catch (e) {
      console.error('Failed to load users:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchUsers(search);
  };

  const resetPassword = async (userId: string) => {
    if (!confirm('Send password reset email to this user?')) return;

    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/users/${userId}/reset-password`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      if (response.ok) {
        alert('Password reset email sent!');
      } else {
        alert('Failed to send reset email');
      }
    } catch (e) {
      alert('Error sending reset email');
    }
    setSelectedUser(null);
  };

  const deleteUser = async (userId: string) => {
    if (!confirm('Are you sure you want to delete this user? This cannot be undone.')) return;

    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/users/${userId}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      if (response.ok) {
        fetchUsers();
      } else {
        alert('Failed to delete user');
      }
    } catch (e) {
      alert('Error deleting user');
    }
    setSelectedUser(null);
  };

  if (loading) {
    return <div className="animate-pulse h-96 bg-gray-200 rounded-xl" />;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <p className="text-gray-500">{data?.pagination.total || 0} total users</p>
        </div>
        <Link
          href="/admin/users/new"
          className="flex items-center gap-2 px-4 py-2 bg-haven-navy-900 text-white rounded-lg hover:bg-haven-navy-800 transition"
        >
          <Plus className="w-4 h-4" />
          Add User
        </Link>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl p-4 shadow-sm flex flex-wrap gap-4">
        <form onSubmit={handleSearch} className="flex-1 min-w-[200px]">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name or email..."
              className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
            />
          </div>
        </form>

        <select
          value={roleFilter}
          onChange={(e) => {
            setRoleFilter(e.target.value);
            setPage(1);
          }}
          className="px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
        >
          <option value="">All Roles</option>
          <option value="ADMIN">Admin</option>
          <option value="HOME_MANAGER">Home Manager</option>
          <option value="HANDYMAN">Handyman</option>
          <option value="HOMEOWNER">Homeowner</option>
          <option value="VENDOR">Vendor</option>
        </select>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">User</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Role</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Household</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Created</th>
              <th className="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {data?.users.map((u) => (
              <tr key={u.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div>
                    <p className="font-medium text-gray-900">{u.name}</p>
                    <p className="text-sm text-gray-500">{u.email}</p>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${roleColors[u.role] || 'bg-gray-100'}`}>
                    {u.role.replace('_', ' ')}
                  </span>
                </td>
                <td className="px-6 py-4">
                  {u.householdName ? (
                    <Link
                      href={`/admin/households/${u.householdId}`}
                      className="text-haven-champagne-600 hover:underline"
                    >
                      {u.householdName}
                    </Link>
                  ) : (
                    <span className="text-gray-400">—</span>
                  )}
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {new Date(u.createdAt).toLocaleDateString()}
                </td>
                <td className="px-6 py-4">
                  <div className="relative">
                    <button
                      onClick={() => setSelectedUser(selectedUser === u.id ? null : u.id)}
                      className="p-2 hover:bg-gray-100 rounded-lg"
                    >
                      <MoreVertical className="w-4 h-4 text-gray-400" />
                    </button>

                    {selectedUser === u.id && (
                      <div className="absolute right-0 top-full mt-1 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-10">
                        <Link
                          href={`/admin/users/${u.id}`}
                          className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                        >
                          <Edit className="w-4 h-4" />
                          Edit User
                        </Link>
                        <button
                          onClick={() => resetPassword(u.id)}
                          className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 w-full text-left"
                        >
                          <Key className="w-4 h-4" />
                          Reset Password
                        </button>
                        <button
                          onClick={() => deleteUser(u.id)}
                          className="flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 w-full text-left"
                        >
                          <Trash2 className="w-4 h-4" />
                          Delete User
                        </button>
                      </div>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {data?.users.length === 0 && (
          <div className="py-12 text-center text-gray-500">No users found</div>
        )}

        {/* Pagination */}
        {data && data.pagination.pages > 1 && (
          <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
            <p className="text-sm text-gray-500">
              Showing {(page - 1) * 20 + 1} to {Math.min(page * 20, data.pagination.total)} of{' '}
              {data.pagination.total}
            </p>
            <div className="flex gap-2">
              <button
                onClick={() => setPage(page - 1)}
                disabled={page === 1}
                className="p-2 border border-gray-200 rounded-lg disabled:opacity-50 hover:bg-gray-50"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button
                onClick={() => setPage(page + 1)}
                disabled={page >= data.pagination.pages}
                className="p-2 border border-gray-200 rounded-lg disabled:opacity-50 hover:bg-gray-50"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
```

### Task 5.2: Create User Edit Page

Create `apps/web/src/app/admin/users/[id]/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { ArrowLeft, Save, Loader2 } from 'lucide-react';

interface UserData {
  id: string;
  email: string;
  name: string;
  firstName: string;
  lastName: string;
  phone: string;
  role: string;
  householdId: string | null;
  firebaseUid: string;
}

export default function EditUserPage() {
  const params = useParams();
  const router = useRouter();
  const { user } = useAuth();
  const [userData, setUserData] = useState<UserData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    name: '',
    firstName: '',
    lastName: '',
    phone: '',
    role: '',
  });

  useEffect(() => {
    fetchUser();
  }, [params.id]);

  const fetchUser = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/users/${params.id}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        const data = await response.json();
        setUserData(data);
        setForm({
          name: data.name || '',
          firstName: data.firstName || '',
          lastName: data.lastName || '',
          phone: data.phone || '',
          role: data.role || '',
        });
      }
    } catch (e) {
      console.error('Failed to load user:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);

    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/users/${params.id}`,
        {
          method: 'PUT',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(form),
        }
      );

      if (response.ok) {
        router.push('/admin/users');
      } else {
        alert('Failed to save user');
      }
    } catch (e) {
      alert('Error saving user');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="animate-pulse h-96 bg-gray-200 rounded-xl" />;
  }

  if (!userData) {
    return <div className="text-center text-gray-500">User not found</div>;
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/admin/users" className="p-2 hover:bg-gray-100 rounded-lg">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Edit User</h1>
          <p className="text-gray-500">{userData.email}</p>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSave} className="bg-white rounded-xl p-6 shadow-sm space-y-6">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">First Name</label>
            <input
              type="text"
              value={form.firstName}
              onChange={(e) => setForm({ ...form, firstName: e.target.value })}
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
            <input
              type="text"
              value={form.lastName}
              onChange={(e) => setForm({ ...form, lastName: e.target.value })}
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Display Name</label>
          <input
            type="text"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
          <input
            type="tel"
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
            className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
          <select
            value={form.role}
            onChange={(e) => setForm({ ...form, role: e.target.value })}
            className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
          >
            <option value="HOMEOWNER">Homeowner</option>
            <option value="HOME_MANAGER">Home Manager</option>
            <option value="HANDYMAN">Handyman</option>
            <option value="VENDOR">Vendor</option>
            <option value="ADMIN">Admin</option>
          </select>
        </div>

        <div className="flex gap-4 pt-4">
          <button
            type="submit"
            disabled={saving}
            className="flex items-center gap-2 px-6 py-2 bg-haven-navy-900 text-white rounded-lg hover:bg-haven-navy-800 transition disabled:opacity-50"
          >
            {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
            Save Changes
          </button>
          <Link
            href="/admin/users"
            className="px-6 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition"
          >
            Cancel
          </Link>
        </div>
      </form>

      {/* Info Card */}
      <div className="bg-gray-50 rounded-xl p-6">
        <h3 className="font-medium text-gray-700 mb-3">Account Info</h3>
        <dl className="space-y-2 text-sm">
          <div className="flex justify-between">
            <dt className="text-gray-500">User ID</dt>
            <dd className="font-mono text-gray-700">{userData.id}</dd>
          </div>
          <div className="flex justify-between">
            <dt className="text-gray-500">Firebase UID</dt>
            <dd className="font-mono text-gray-700">{userData.firebaseUid || '—'}</dd>
          </div>
          {userData.householdId && (
            <div className="flex justify-between">
              <dt className="text-gray-500">Household</dt>
              <dd>
                <Link href={`/admin/households/${userData.householdId}`} className="text-haven-champagne-600 hover:underline">
                  View Household
                </Link>
              </dd>
            </div>
          )}
        </dl>
      </div>
    </div>
  );
}
```

---

## PHASE 6: Households Management Page

### Task 6.1: Create Households List Page

Create `apps/web/src/app/admin/households/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  Search,
  MoreVertical,
  Users,
  CreditCard,
  ChevronRight,
  Home,
} from 'lucide-react';

interface Household {
  id: string;
  name: string;
  tier: string;
  status: string;
  address: string | null;
  primaryContact: { name: string; email: string } | null;
  homeManager: string;
  onboardingStatus: string | null;
  billCount: number;
  memberCount: number;
  monthlyFunding: number;
  createdAt: string;
}

const tierColors: Record<string, string> = {
  ESSENTIALS: 'bg-gray-100 text-gray-700',
  LITE: 'bg-blue-100 text-blue-700',
  HAVEN: 'bg-haven-champagne-100 text-haven-champagne-700',
  'HAVEN+': 'bg-purple-100 text-purple-700',
  ESTATE: 'bg-amber-100 text-amber-700',
};

const statusColors: Record<string, string> = {
  ACTIVE: 'bg-green-100 text-green-700',
  PENDING: 'bg-yellow-100 text-yellow-700',
  INACTIVE: 'bg-gray-100 text-gray-700',
  CANCELLED: 'bg-red-100 text-red-700',
};

export default function AdminHouseholdsPage() {
  const { user } = useAuth();
  const [data, setData] = useState<{ households: Household[]; pagination: any } | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [tierFilter, setTierFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  useEffect(() => {
    fetchHouseholds();
  }, [tierFilter, statusFilter]);

  const fetchHouseholds = async (searchQuery?: string) => {
    try {
      const token = await user?.getIdToken();
      const params = new URLSearchParams();
      if (tierFilter) params.set('tier', tierFilter);
      if (statusFilter) params.set('status', statusFilter);
      if (searchQuery || search) params.set('search', searchQuery || search);

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/admin/households?${params}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setData(await response.json());
      }
    } catch (e) {
      console.error('Failed to load households:', e);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="animate-pulse h-96 bg-gray-200 rounded-xl" />;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Households</h1>
        <p className="text-gray-500">{data?.pagination.total || 0} total households</p>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl p-4 shadow-sm flex flex-wrap gap-4">
        <form onSubmit={(e) => { e.preventDefault(); fetchHouseholds(search); }} className="flex-1 min-w-[200px]">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name or address..."
              className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
            />
          </div>
        </form>

        <select
          value={tierFilter}
          onChange={(e) => setTierFilter(e.target.value)}
          className="px-4 py-2 border border-gray-200 rounded-lg"
        >
          <option value="">All Tiers</option>
          <option value="ESSENTIALS">Essentials</option>
          <option value="LITE">Lite</option>
          <option value="HAVEN">Haven</option>
          <option value="HAVEN+">Haven+</option>
          <option value="ESTATE">Estate</option>
        </select>

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-4 py-2 border border-gray-200 rounded-lg"
        >
          <option value="">All Status</option>
          <option value="ACTIVE">Active</option>
          <option value="PENDING">Pending</option>
          <option value="INACTIVE">Inactive</option>
        </select>
      </div>

      {/* Households Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {data?.households.map((h) => (
          <Link
            key={h.id}
            href={`/admin/households/${h.id}`}
            className="bg-white rounded-xl p-5 shadow-sm hover:shadow-md transition"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-haven-champagne-100 rounded-lg flex items-center justify-center">
                  <Home className="w-5 h-5 text-haven-champagne-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">{h.name}</h3>
                  <p className="text-sm text-gray-500">{h.address || 'No address'}</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-gray-300" />
            </div>

            <div className="flex flex-wrap gap-2 mb-4">
              <span className={`px-2 py-0.5 rounded text-xs font-medium ${tierColors[h.tier] || 'bg-gray-100'}`}>
                {h.tier}
              </span>
              <span className={`px-2 py-0.5 rounded text-xs font-medium ${statusColors[h.status] || 'bg-gray-100'}`}>
                {h.status}
              </span>
            </div>

            <div className="grid grid-cols-3 gap-3 text-center text-sm">
              <div>
                <p className="font-semibold text-gray-900">{h.memberCount}</p>
                <p className="text-gray-500 text-xs">Members</p>
              </div>
              <div>
                <p className="font-semibold text-gray-900">{h.billCount}</p>
                <p className="text-gray-500 text-xs">Bills</p>
              </div>
              <div>
                <p className="font-semibold text-gray-900">${h.monthlyFunding.toLocaleString()}</p>
                <p className="text-gray-500 text-xs">Monthly</p>
              </div>
            </div>

            <div className="mt-4 pt-4 border-t border-gray-100 flex items-center justify-between text-sm">
              <span className="text-gray-500">Manager: {h.homeManager}</span>
              <span className="text-gray-400">{h.primaryContact?.name}</span>
            </div>
          </Link>
        ))}
      </div>

      {data?.households.length === 0 && (
        <div className="text-center py-12 text-gray-500">No households found</div>
      )}
    </div>
  );
}
```

---

## PHASE 7: Build and Deploy

### Task 7.1: Build

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

### Task 7.2: Commit

```bash
git add .
git commit -m "feat: comprehensive admin portal for platform management"
```

### Task 7.3: Deploy

```bash
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## PHASE 8: Setup Your Admin Account

### Task 8.1: Create Your Admin User

After deployment, you need to link your Firebase account to an Admin user:

1. Log into Firebase Console → Authentication → Users
2. Find your user (or create one with your email)
3. Copy the UID

Then run this SQL or use Prisma Studio:

```sql
-- Update your user to be admin
UPDATE "User" 
SET role = 'ADMIN' 
WHERE email = 'YOUR_EMAIL@example.com';

-- Or if you need to create:
INSERT INTO "User" (id, email, "firebaseUid", name, "firstName", "lastName", role, "createdAt", "updatedAt")
VALUES (
  gen_random_uuid()::text,
  'YOUR_EMAIL@example.com',
  'YOUR_FIREBASE_UID',
  'Tom Burke',
  'Tom',
  'Burke',
  'ADMIN',
  NOW(),
  NOW()
);
```

Or via seed update (Task 1.2 above).

---

## Verification Checklist

### Admin Access
- [ ] Can login with your email
- [ ] Redirects non-admins away from /admin
- [ ] Sidebar navigation works

### Dashboard
- [ ] Shows overview stats (users, households, pending)
- [ ] Shows households by tier
- [ ] Shows onboarding pipeline
- [ ] Shows recent activity

### Users
- [ ] Lists all users with pagination
- [ ] Can filter by role
- [ ] Can search by name/email
- [ ] Can edit user details
- [ ] Can reset password
- [ ] Can delete user

### Households
- [ ] Lists all households
- [ ] Can filter by tier/status
- [ ] Can view household details
- [ ] Can assign Home Manager
- [ ] Can update monthly funding

### Team
- [ ] Shows all Haven team members
- [ ] Shows workload per manager

---

## Summary

After running this prompt, you'll have:

1. ✅ `/admin` dashboard with platform overview
2. ✅ `/admin/users` - full user management with CRUD
3. ✅ `/admin/households` - household management
4. ✅ `/admin/onboarding` - onboarding pipeline view
5. ✅ `/admin/team` - Haven team management
6. ✅ `/admin/activity` - system-wide activity log
7. ✅ Password reset functionality
8. ✅ Role-based access control (Admin only)
