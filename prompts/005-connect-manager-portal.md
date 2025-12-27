# Haven Manager Portal: Connect to Real APIs

**Created:** December 27, 2024  
**Purpose:** Wire up the existing Manager Portal to real APIs from Prompt 003  
**Priority:** High - Sarah needs to actually use this

---

## Overview

The Manager Portal already has great UI at `/manager/*`. This prompt connects it to real APIs so Sarah can:
- See her actual assigned households
- Work the onboarding queue with real signups
- Save intake data that appears in homeowner portals
- Track real activity

**This is NOT a rebuild** - just connecting existing UI to backend APIs.

---

## What Already Exists

### Frontend (Manager Portal)
- `/manager` - Dashboard with schedule, tasks, households, activity
- `/manager/onboarding` - Queue page (already fetching from API)
- `/manager/onboarding/[sessionId]` - Intake workbench
- `/manager/households` - Households list
- `/manager/households/[id]` - Household detail
- `/manager/tasks` - Task management
- `/manager/payables` - Bills to pay
- `/manager/calendar` - Schedule view
- Comprehensive intake sections in `intake-sections.ts`

### Backend APIs (from Prompt 003)
- `GET /onboarding/queue` - Onboarding queue
- `GET /onboarding/:id` - Session details
- `PUT /onboarding/:id/intake` - Save intake data
- `POST /onboarding/:id/start-call` - Start call
- `POST /onboarding/:id/complete` - Complete intake
- `GET /dashboard/household/:id` - Dashboard data
- `GET /family/household/:id` - Family data
- `GET /property/household/:id` - Property data

---

## PHASE 1: Manager API Endpoints

### Task 1.1: Create Manager Service

Create `apps/api/src/manager/manager.service.ts`:

```typescript
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ManagerService {
  constructor(private prisma: PrismaService) {}

  // =========================================================================
  // DASHBOARD
  // =========================================================================

  async getDashboard(managerId: string) {
    // Get manager's assigned households
    const householdSettings = await this.prisma.householdSettings.findMany({
      where: { homeManagerId: managerId },
      include: {
        household: {
          include: {
            property: true,
            users: { where: { role: 'HOMEOWNER' }, take: 1 },
            bills: { where: { status: 'ACTIVE' } },
            _count: { select: { activityLogs: true } },
          },
        },
      },
    });

    const households = householdSettings.map((hs) => hs.household);

    // Get pending onboarding sessions
    const pendingOnboarding = await this.prisma.onboardingSession.findMany({
      where: {
        assignedManagerId: managerId,
        status: { in: ['PENDING_CALL', 'CALL_SCHEDULED', 'INTAKE_PARTIAL'] },
      },
      include: {
        household: {
          include: {
            property: true,
            users: { where: { role: 'HOMEOWNER' }, take: 1 },
          },
        },
      },
    });

    // Get recent activity across all managed households
    const householdIds = households.map((h) => h.id);
    const recentActivity = await this.prisma.activityLog.findMany({
      where: { householdId: { in: householdIds } },
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: { household: { select: { name: true } } },
    });

    // Calculate stats
    const urgentCount = pendingOnboarding.filter(
      (s) => s.status === 'PENDING_CALL'
    ).length;

    const totalBillsDue = households.reduce((sum, h) => {
      const monthlyBills = h.bills.reduce((s, b) => s + (b.amount || 0), 0);
      return sum + monthlyBills;
    }, 0);

    // Get tasks (placeholder - would come from tasks table)
    const tasksToday = 5; // TODO: Implement tasks model

    return {
      stats: {
        householdsManaged: households.length,
        pendingOnboarding: pendingOnboarding.length,
        urgentItems: urgentCount,
        tasksToday,
        billsDueThisWeek: totalBillsDue,
      },
      households: households.map((h) => ({
        id: h.id,
        name: h.name,
        address: h.property
          ? `${h.property.street}, ${h.property.city}`
          : null,
        primaryContact: h.users[0]?.name || 'Unknown',
        status: 'good', // TODO: Calculate based on urgent items
        taskCount: 0,
        unreadMessages: 0,
      })),
      pendingOnboarding: pendingOnboarding.map((s) => ({
        id: s.id,
        householdId: s.householdId,
        status: s.status,
        homeownerName: s.household.users[0]?.name || 'Unknown',
        homeownerPhone: s.household.users[0]?.phone,
        address: s.household.property
          ? `${s.household.property.street}, ${s.household.property.city}`
          : null,
        createdAt: s.createdAt,
      })),
      recentActivity: recentActivity.map((a) => ({
        id: a.id,
        title: a.title,
        description: a.description,
        householdName: a.household.name,
        category: a.category,
        createdAt: a.createdAt,
      })),
    };
  }

  // =========================================================================
  // HOUSEHOLDS
  // =========================================================================

  async getMyHouseholds(managerId: string) {
    const settings = await this.prisma.householdSettings.findMany({
      where: { homeManagerId: managerId },
      include: {
        household: {
          include: {
            property: true,
            users: { where: { role: 'HOMEOWNER' } },
            familyMembers: true,
            vehicles: true,
            bills: { where: { status: 'ACTIVE' } },
            vendors: true,
            onboardingSession: true,
          },
        },
      },
    });

    return settings.map((s) => {
      const h = s.household;
      const totalMonthly = h.bills.reduce((sum, b) => sum + (b.amount || 0), 0);

      return {
        id: h.id,
        name: h.name,
        tier: h.tier,
        status: h.status,
        address: h.property
          ? {
              street: h.property.street,
              city: h.property.city,
              state: h.property.state,
              zip: h.property.zip,
              full: `${h.property.street}, ${h.property.city}, ${h.property.state} ${h.property.zip}`,
            }
          : null,
        propertyDetails: h.property
          ? {
              bedrooms: h.property.bedrooms,
              bathrooms: h.property.bathrooms,
              squareFeet: h.property.squareFeet,
              yearBuilt: h.property.yearBuilt,
            }
          : null,
        homeowners: h.users.map((u) => ({
          id: u.id,
          name: u.name,
          email: u.email,
          phone: u.phone,
        })),
        memberCount: h.familyMembers.length,
        vehicleCount: h.vehicles.length,
        billCount: h.bills.length,
        vendorCount: h.vendors.length,
        monthlyFunding: s.monthlyFunding,
        totalMonthlyBills: totalMonthly,
        onboardingStatus: h.onboardingSession?.status || 'ACTIVE',
        createdAt: h.createdAt,
      };
    });
  }

  async getHouseholdDetail(managerId: string, householdId: string) {
    // Verify manager has access
    const access = await this.prisma.householdSettings.findFirst({
      where: { homeManagerId: managerId, householdId },
    });

    if (!access) {
      throw new ForbiddenException('You do not manage this household');
    }

    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        property: {
          include: {
            zones: { include: { assets: true } },
          },
        },
        users: true,
        familyMembers: { include: { activities: true } },
        vehicles: true,
        vendors: true,
        bills: true,
        settings: true,
        onboardingSession: true,
        activityLogs: {
          take: 50,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    return household;
  }

  // =========================================================================
  // ONBOARDING QUEUE
  // =========================================================================

  async getOnboardingQueue(managerId: string, status?: string) {
    const where: any = {
      assignedManagerId: managerId,
    };

    if (status && status !== 'active') {
      where.status = status;
    } else {
      // Active = not yet fully completed
      where.status = {
        in: ['PENDING_CALL', 'CALL_SCHEDULED', 'CALL_IN_PROGRESS', 'INTAKE_PARTIAL', 'INTAKE_COMPLETE', 'PROFILE_BUILDING'],
      };
    }

    const sessions = await this.prisma.onboardingSession.findMany({
      where,
      orderBy: { createdAt: 'asc' },
      include: {
        household: {
          include: {
            property: true,
            users: { where: { role: 'HOMEOWNER' }, take: 1 },
          },
        },
      },
    });

    return sessions.map((s) => ({
      id: s.id,
      householdId: s.householdId,
      status: s.status,
      homeownerName: s.household.users[0]?.name || 'Unknown',
      homeownerEmail: s.household.users[0]?.email,
      homeownerPhone: s.household.users[0]?.phone,
      propertyAddress: s.household.property
        ? `${s.household.property.street}, ${s.household.property.city}, ${s.household.property.state}`
        : 'No address',
      biggestChallenge: s.biggestChallenge,
      selectedTier: s.selectedTier,
      callScheduledFor: s.callScheduledFor,
      assignedManager: null, // Already filtered to this manager
      progress: Math.round(
        (s.progressFamily +
          s.progressProperty +
          s.progressZones +
          s.progressSystems +
          s.progressVendors +
          s.progressBills) /
          6
      ),
      enrichmentHighlights: this.getEnrichmentHighlights(s.household.property),
      createdAt: s.createdAt,
    }));
  }

  private getEnrichmentHighlights(property: any): string[] {
    if (!property) return [];
    const highlights: string[] = [];
    
    const enrichment = property.enrichmentData as any;
    if (!enrichment) return highlights;

    if (enrichment.heatingFuel) highlights.push(`${enrichment.heatingFuel} heat`);
    if (enrichment.pool) highlights.push('Pool');
    if (enrichment.fireplaces > 0) highlights.push(`${enrichment.fireplaces} fireplace(s)`);
    if (enrichment.sewerType === 'Septic') highlights.push('Septic');
    
    return highlights;
  }

  // =========================================================================
  // ACTIVITY
  // =========================================================================

  async getMyActivity(managerId: string, limit = 50) {
    // Get all households this manager manages
    const settings = await this.prisma.householdSettings.findMany({
      where: { homeManagerId: managerId },
      select: { householdId: true },
    });

    const householdIds = settings.map((s) => s.householdId);

    return this.prisma.activityLog.findMany({
      where: { householdId: { in: householdIds } },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        household: { select: { name: true } },
      },
    });
  }

  async logActivity(
    managerId: string,
    managerName: string,
    data: {
      householdId: string;
      action: string;
      category: string;
      title: string;
      description?: string;
      amount?: number;
    }
  ) {
    return this.prisma.activityLog.create({
      data: {
        householdId: data.householdId,
        actorId: managerId,
        actorType: 'HOME_MANAGER',
        actorName: managerName,
        action: data.action,
        category: data.category,
        title: data.title,
        description: data.description,
        amount: data.amount,
        visibleToHomeowner: true,
      },
    });
  }
}
```

### Task 1.2: Create Manager Controller

Create `apps/api/src/manager/manager.controller.ts`:

```typescript
import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { ManagerService } from './manager.service';

@Controller('manager')
@UseGuards(FirebaseAuthGuard)
export class ManagerController {
  constructor(private managerService: ManagerService) {}

  @Get('dashboard')
  async getDashboard(@Request() req: any) {
    return this.managerService.getDashboard(req.user.id);
  }

  @Get('households')
  async getMyHouseholds(@Request() req: any) {
    return this.managerService.getMyHouseholds(req.user.id);
  }

  @Get('households/:id')
  async getHouseholdDetail(
    @Request() req: any,
    @Param('id') householdId: string
  ) {
    return this.managerService.getHouseholdDetail(req.user.id, householdId);
  }

  @Get('onboarding/queue')
  async getOnboardingQueue(
    @Request() req: any,
    @Query('status') status?: string
  ) {
    return this.managerService.getOnboardingQueue(req.user.id, status);
  }

  @Get('activity')
  async getMyActivity(
    @Request() req: any,
    @Query('limit') limit?: string
  ) {
    return this.managerService.getMyActivity(
      req.user.id,
      limit ? parseInt(limit) : undefined
    );
  }

  @Post('activity')
  async logActivity(
    @Request() req: any,
    @Body()
    body: {
      householdId: string;
      action: string;
      category: string;
      title: string;
      description?: string;
      amount?: number;
    }
  ) {
    return this.managerService.logActivity(
      req.user.id,
      req.user.name || 'Home Manager',
      body
    );
  }
}
```

### Task 1.3: Create Manager Module

Create `apps/api/src/manager/manager.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ManagerController } from './manager.controller';
import { ManagerService } from './manager.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ManagerController],
  providers: [ManagerService],
})
export class ManagerModule {}
```

### Task 1.4: Register Manager Module

Update `apps/api/src/app.module.ts` to include:

```typescript
import { ManagerModule } from './manager/manager.module';

@Module({
  imports: [
    // ... existing imports
    ManagerModule,
  ],
})
export class AppModule {}
```

---

## PHASE 2: Update Manager Dashboard

### Task 2.1: Connect Dashboard to Real API

Update `apps/web/src/app/manager/page.tsx`:

Find the `loadData` function and update it to fetch from the new manager dashboard endpoint:

```typescript
const loadData = useCallback(async () => {
  try {
    const token = await getIdToken();
    if (!token) {
      setError('Not authenticated');
      setIsLoading(false);
      return;
    }

    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    const response = await fetch(`${apiUrl}/manager/dashboard`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (response.ok) {
      const data = await response.json();
      
      // Map API data to component state
      setHouseholds(data.households || []);
      
      // Update stats from real data, fallback to existing mock structure
      // The component already handles this via the stats useMemo
    } else {
      console.error('Failed to load dashboard:', response.status);
    }
  } catch (err: unknown) {
    const message =
      err && typeof err === 'object' && 'message' in err
        ? (err as { message: string }).message
        : 'Failed to load data';
    setError(message);
  } finally {
    setIsLoading(false);
  }
}, []);
```

Also update the stats calculation to use real data when available:

```typescript
const [dashboardData, setDashboardData] = useState<any>(null);

// In loadData, after successful fetch:
setDashboardData(data);

// Update stats useMemo:
const stats = useMemo(() => {
  if (dashboardData?.stats) {
    return {
      householdsManaged: dashboardData.stats.householdsManaged,
      urgentItems: dashboardData.stats.urgentItems,
      tasksToday: dashboardData.stats.tasksToday,
      pendingApprovals: dashboardData.stats.pendingOnboarding,
      billsDueThisWeek: dashboardData.stats.billsDueThisWeek,
    };
  }
  
  // Fallback to mock data
  return {
    householdsManaged: mockHouseholds.length,
    urgentItems: mockUrgentItems.length,
    tasksToday: mockTasks.fromHomeowners.length + mockTasks.systemGenerated.length,
    pendingApprovals: 4,
    billsDueThisWeek: 12847.23,
  };
}, [dashboardData]);
```

### Task 2.2: Update Households Section

Update the Households section to use real data when available:

```typescript
// In the component:
const displayHouseholds = useMemo(() => {
  if (dashboardData?.households?.length > 0) {
    return dashboardData.households.map((h: any) => ({
      id: h.id,
      name: h.name,
      address: h.address || 'No address',
      status: h.status || 'good',
      urgentCount: h.urgentCount || 0,
      taskCount: h.taskCount || 0,
      unreadMessages: h.unreadMessages || 0,
      lastContact: h.lastContact || 'Recently',
    }));
  }
  return mockHouseholds;
}, [dashboardData]);

// Then in the JSX, replace mockHouseholds with displayHouseholds:
{displayHouseholds.map((household) => (
  <HouseholdCard key={household.id} household={household} />
))}
```

### Task 2.3: Update Activity Feed

```typescript
const displayActivity = useMemo(() => {
  if (dashboardData?.recentActivity?.length > 0) {
    return dashboardData.recentActivity.map((a: any) => ({
      id: a.id,
      timeAgo: formatTimeAgo(new Date(a.createdAt)),
      household: a.householdName,
      action: a.title,
      detail: a.description || '',
      type: mapCategoryToType(a.category),
    }));
  }
  return mockActivities;
}, [dashboardData]);

// Helper functions:
function formatTimeAgo(date: Date): string {
  const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);
  if (seconds < 60) return 'Just now';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hr ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function mapCategoryToType(category: string): string {
  const map: Record<string, string> = {
    BILLING: 'payment',
    SERVICE: 'request',
    MAINTENANCE: 'request',
    PROPERTY: 'request',
    COMMUNICATION: 'message',
  };
  return map[category] || 'request';
}
```

---

## PHASE 3: Update Onboarding Queue

### Task 3.1: Verify Queue API Connection

The onboarding queue page already fetches from `/manager/onboarding/queue`. Update to ensure it uses the correct endpoint:

In `apps/web/src/app/manager/onboarding/page.tsx`, verify the fetch URL:

```typescript
const fetchQueue = async () => {
  try {
    setLoading(true);
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    // Build query params
    const params = new URLSearchParams();
    if (filter && filter !== 'active') {
      params.set('status', filter);
    }
    
    const url = `${apiUrl}/manager/onboarding/queue${params.toString() ? '?' + params.toString() : ''}`;
    
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (response.ok) {
      const data = await response.json();
      setQueue(data);
    } else {
      console.error('Queue fetch failed:', response.status);
      setQueue([]);
    }
  } catch (error) {
    console.error('Failed to load queue:', error);
    setQueue([]);
  } finally {
    setLoading(false);
  }
};
```

---

## PHASE 4: Update Intake Workbench

### Task 4.1: Add Save Functionality

Update `apps/web/src/app/manager/onboarding/[sessionId]/page.tsx` to save intake data:

Add these functions to the component:

```typescript
import { getIdToken } from '@/lib/firebase';

// State for saving
const [saving, setSaving] = useState(false);
const [lastSaved, setLastSaved] = useState<Date | null>(null);

// Auto-save function
const saveSection = async (sectionId: string, data: any) => {
  try {
    setSaving(true);
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    const response = await fetch(`${apiUrl}/onboarding/${sessionId}/intake`, {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        section: sectionId,
        data,
        progress: calculateSectionProgress(sectionId, { ...formData, [sectionId]: data }),
      }),
    });

    if (response.ok) {
      setLastSaved(new Date());
    } else {
      console.error('Failed to save:', response.status);
    }
  } catch (error) {
    console.error('Save error:', error);
  } finally {
    setSaving(false);
  }
};

// Debounced auto-save on form changes
useEffect(() => {
  if (!activeSection || !formData[activeSection]) return;
  
  const timer = setTimeout(() => {
    saveSection(activeSection, formData[activeSection]);
  }, 2000); // Save 2 seconds after last change
  
  return () => clearTimeout(timer);
}, [formData, activeSection]);

// Start call function
const handleStartCall = async () => {
  try {
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    await fetch(`${apiUrl}/onboarding/${sessionId}/start-call`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    });
    
    // Refresh session data
    fetchSession();
  } catch (error) {
    console.error('Failed to start call:', error);
  }
};

// Complete intake function
const handleCompleteIntake = async () => {
  if (!confirm('Mark intake as complete? This will finalize all data.')) return;
  
  try {
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    const response = await fetch(`${apiUrl}/onboarding/${sessionId}/complete`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        notes: formData.callNotes,
        followUpNeeded: formData.followUpNeeded || false,
      }),
    });

    if (response.ok) {
      // Redirect to queue
      router.push('/manager/onboarding');
    }
  } catch (error) {
    console.error('Failed to complete intake:', error);
  }
};
```

### Task 4.2: Add Save Indicator UI

Add a save status indicator to the intake workbench header:

```typescript
// In the header section of the intake workbench:
<div className="flex items-center gap-2 text-sm text-gray-500">
  {saving ? (
    <>
      <Loader2 className="w-4 h-4 animate-spin" />
      <span>Saving...</span>
    </>
  ) : lastSaved ? (
    <>
      <CheckCircle className="w-4 h-4 text-green-500" />
      <span>Saved {formatTimeAgo(lastSaved)}</span>
    </>
  ) : null}
</div>
```

### Task 4.3: Load Existing Intake Data

When loading a session, populate the form with any existing intake data:

```typescript
const fetchSession = async () => {
  try {
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    const response = await fetch(`${apiUrl}/onboarding/${sessionId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (response.ok) {
      const session = await response.json();
      setSession(session);
      
      // Load existing intake data into form
      if (session.intakeData) {
        setFormData(session.intakeData);
      }
    }
  } catch (error) {
    console.error('Failed to load session:', error);
  }
};
```

---

## PHASE 5: Update Households List

### Task 5.1: Connect to Real API

Update `apps/web/src/app/manager/households/page.tsx`:

```typescript
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { getIdToken } from '@/lib/firebase';
import {
  Home,
  Search,
  ChevronRight,
  Users,
  FileText,
  Wrench,
  Loader2,
} from 'lucide-react';

interface Household {
  id: string;
  name: string;
  tier: string;
  status: string;
  address: {
    full: string;
  } | null;
  homeowners: Array<{ name: string; email: string; phone: string }>;
  memberCount: number;
  billCount: number;
  vendorCount: number;
  monthlyFunding: number;
  totalMonthlyBills: number;
}

export default function ManagerHouseholdsPage() {
  const [households, setHouseholds] = useState<Household[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchHouseholds();
  }, []);

  const fetchHouseholds = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const response = await fetch(`${apiUrl}/manager/households`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setHouseholds(await response.json());
      }
    } catch (error) {
      console.error('Failed to load households:', error);
    } finally {
      setLoading(false);
    }
  };

  const filtered = households.filter((h) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      h.name.toLowerCase().includes(q) ||
      h.address?.full.toLowerCase().includes(q) ||
      h.homeowners.some((o) => o.name.toLowerCase().includes(q))
    );
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">My Households</h1>
          <p className="text-gray-500">{households.length} households assigned</p>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search households..."
          className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
        />
      </div>

      {/* Households Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map((h) => (
          <Link
            key={h.id}
            href={`/manager/households/${h.id}`}
            className="bg-white rounded-xl p-5 shadow-sm hover:shadow-md transition border border-gray-100"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                  <Home className="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">{h.name}</h3>
                  <p className="text-sm text-gray-500">{h.address?.full || 'No address'}</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-gray-300" />
            </div>

            <div className="flex flex-wrap gap-2 mb-4">
              <span className="px-2 py-0.5 bg-indigo-100 text-indigo-700 rounded text-xs font-medium">
                {h.tier}
              </span>
              <span className="px-2 py-0.5 bg-green-100 text-green-700 rounded text-xs font-medium">
                {h.status}
              </span>
            </div>

            <div className="grid grid-cols-3 gap-2 text-center text-sm mb-4">
              <div className="flex items-center justify-center gap-1 text-gray-600">
                <Users className="w-3 h-3" />
                <span>{h.memberCount}</span>
              </div>
              <div className="flex items-center justify-center gap-1 text-gray-600">
                <FileText className="w-3 h-3" />
                <span>{h.billCount}</span>
              </div>
              <div className="flex items-center justify-center gap-1 text-gray-600">
                <Wrench className="w-3 h-3" />
                <span>{h.vendorCount}</span>
              </div>
            </div>

            <div className="pt-3 border-t border-gray-100 flex justify-between text-sm">
              <span className="text-gray-500">Monthly</span>
              <span className="font-semibold text-gray-900">
                ${h.totalMonthlyBills.toLocaleString()}
              </span>
            </div>
          </Link>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          {search ? 'No households match your search' : 'No households assigned yet'}
        </div>
      )}
    </div>
  );
}
```

---

## PHASE 6: Sarah's Login & Assignment

### Task 6.1: Ensure Sarah Can Login

Sarah was created in the seed with `firebaseUid: 'sarah-haven-manager'`. She needs a Firebase Auth account.

Create a script to set up Sarah's Firebase account at `apps/api/scripts/setup-sarah.ts`:

```typescript
import * as admin from 'firebase-admin';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Initialize Firebase Admin if not already
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }

  const email = 'sarah@haven.app';
  const password = 'SarahManager2024!';

  try {
    // Check if Firebase user exists
    let firebaseUser;
    try {
      firebaseUser = await admin.auth().getUserByEmail(email);
      console.log('Firebase user already exists:', firebaseUser.uid);
    } catch (e: any) {
      if (e.code === 'auth/user-not-found') {
        // Create Firebase user
        firebaseUser = await admin.auth().createUser({
          email,
          password,
          displayName: 'Sarah Chen',
        });
        console.log('Created Firebase user:', firebaseUser.uid);
      } else {
        throw e;
      }
    }

    // Update database user with Firebase UID
    await prisma.user.update({
      where: { email },
      data: { firebaseUid: firebaseUser.uid },
    });

    console.log('');
    console.log('✅ Sarah Chen is ready to login!');
    console.log('   Email:', email);
    console.log('   Password:', password);
    console.log('   Portal: https://havenhome.dev/manager');
  } catch (error) {
    console.error('Failed to setup Sarah:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
```

Add to `apps/api/package.json`:

```json
{
  "scripts": {
    "setup-sarah": "ts-node scripts/setup-sarah.ts"
  }
}
```

### Task 6.2: Assign Sarah to Morrison Household

The seed already assigns Sarah as the Home Manager for the Morrison family. Verify this exists in the seed:

```typescript
// In seed.ts, after creating HouseholdSettings:
await prisma.householdSettings.create({
  data: {
    householdId: household.id,
    monthlyFunding: 8500,
    fundingDueDay: 1,
    homeManagerId: sarah.id,  // <-- This assigns Sarah
  },
});
```

---

## PHASE 7: Build and Deploy

### Task 7.1: Build

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

### Task 7.2: Run Sarah Setup

```bash
cd apps/api
pnpm setup-sarah
```

### Task 7.3: Commit

```bash
git add .
git commit -m "feat: connect manager portal to real APIs"
```

### Task 7.4: Deploy

```bash
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## PHASE 8: Verification

### Test Sarah's Login
- [ ] Go to https://havenhome.dev/login
- [ ] Login as sarah@haven.app / SarahManager2024!
- [ ] Should redirect to /manager dashboard

### Test Manager Dashboard
- [ ] Shows "Good morning/afternoon, Sarah"
- [ ] Stats show real numbers (1 household, etc.)
- [ ] Households section shows Morrison family
- [ ] Activity feed shows real activity

### Test Onboarding Queue
- [ ] Navigate to /manager/onboarding
- [ ] See any pending onboarding sessions
- [ ] Can click into a session

### Test Intake Workbench
- [ ] Can open a session
- [ ] Fill in some fields
- [ ] Data auto-saves (see "Saved" indicator)
- [ ] Refresh page - data persists

### Test Households
- [ ] Navigate to /manager/households
- [ ] See Morrison family listed
- [ ] Can click into household detail

---

## Summary

After running this prompt:

1. ✅ Manager API endpoints serve real data
2. ✅ Dashboard fetches from API (with fallback to mock)
3. ✅ Onboarding queue shows real sessions
4. ✅ Intake workbench saves data to database
5. ✅ Households list shows assigned households
6. ✅ Sarah has Firebase credentials to login
7. ✅ Activity feeds are real

Sarah can now actually do her job!
