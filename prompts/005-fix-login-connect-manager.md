# Haven: Fix Login + Connect Manager Portal

**Created:** December 27, 2024  
**Purpose:** Fix admin login issue + wire up Manager Portal to real APIs  
**Priority:** Critical

---

## CRITICAL RULES

1. **DO NOT DELETE existing code** - Only refactor and add
2. **DO NOT OVERWRITE polished pages** - Build on what exists
3. **All portals must continue working** - Homeowner, Manager, Handyman, Vendor

---

## ISSUE 1: Admin Login Stuck on Loading

### Symptoms
- Login as admin (tom@havenhome.dev)
- Page stays on loading spinner forever
- Never redirects to /admin dashboard

### Likely Causes
1. `/user/me` endpoint doesn't exist or doesn't return role
2. Admin layout auth check is failing silently
3. Firebase auth state not syncing with backend user

---

## PHASE 1: Fix User/Me Endpoint

### Task 1.1: Check if /user/me exists

Look for the user controller and ensure there's a `/me` endpoint that returns the current user with their role.

If it doesn't exist, create it in `apps/api/src/user/user.controller.ts`:

```typescript
import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { UserService } from './user.service';

@Controller('user')
export class UserController {
  constructor(private userService: UserService) {}

  @Get('me')
  @UseGuards(FirebaseAuthGuard)
  async getMe(@Request() req: any) {
    // req.user is set by FirebaseAuthGuard after validating token
    // It should contain the database user record
    return {
      id: req.user.id,
      email: req.user.email,
      name: req.user.name,
      firstName: req.user.firstName,
      lastName: req.user.lastName,
      phone: req.user.phone,
      role: req.user.role,
      householdId: req.user.householdId,
    };
  }
}
```

### Task 1.2: Verify FirebaseAuthGuard Sets User

Check `apps/api/src/auth/firebase-auth.guard.ts` - it should:
1. Validate the Firebase token
2. Look up the user in the database by firebaseUid
3. Attach the full user object (with role) to `request.user`

If the guard only validates the token but doesn't fetch the database user, update it:

```typescript
import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid authorization header');
    }

    const token = authHeader.split('Bearer ')[1];

    try {
      // Verify Firebase token
      const decodedToken = await admin.auth().verifyIdToken(token);
      
      // Fetch user from database
      const user = await this.prisma.user.findFirst({
        where: { firebaseUid: decodedToken.uid },
      });

      if (!user) {
        // User exists in Firebase but not in our DB
        // This can happen for new signups - create a basic record
        // Or throw if we require pre-existing users
        throw new UnauthorizedException('User not found in database');
      }

      // Attach full user object to request
      request.user = user;
      request.firebaseUser = decodedToken;

      return true;
    } catch (error) {
      console.error('Auth error:', error);
      throw new UnauthorizedException('Invalid token');
    }
  }
}
```

**Note:** If the guard doesn't have PrismaService injected, you'll need to update the AuthModule to provide it.

### Task 1.3: Fix Admin Layout Auth Check

Update `apps/web/src/app/admin/layout.tsx` to handle auth more robustly:

Find the `checkAdmin` function and update it:

```typescript
useEffect(() => {
  const checkAdmin = async () => {
    // Wait for auth to be ready
    if (user === undefined) {
      // Still loading auth state
      return;
    }
    
    if (user === null) {
      // Not logged in
      router.push('/login?redirect=/admin');
      return;
    }

    try {
      const token = await user.getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const response = await fetch(`${apiUrl}/user/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      if (!response.ok) {
        console.error('Failed to fetch user:', response.status);
        router.push('/login?redirect=/admin');
        return;
      }
      
      const userData = await response.json();
      console.log('User data:', userData); // Debug log
      
      if (userData.role === 'ADMIN') {
        setAuthorized(true);
      } else {
        console.log('User is not admin, role:', userData.role);
        router.push('/app');
      }
    } catch (e) {
      console.error('Auth check failed:', e);
      router.push('/login?redirect=/admin');
    } finally {
      setLoading(false);
    }
  };

  checkAdmin();
}, [user, router]);
```

### Task 1.4: Fix Auth Context User State

Check `apps/web/src/contexts/auth-context.tsx` - ensure the `user` state has three possible values:
- `undefined` = still loading
- `null` = not logged in
- `User` = logged in

The admin layout should wait for auth to finish loading before making decisions.

---

## PHASE 2: Create Manager API Endpoints

### Task 2.1: Create Manager Service

Create `apps/api/src/manager/manager.service.ts` (if it doesn't exist):

```typescript
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ManagerService {
  constructor(private prisma: PrismaService) {}

  async getDashboard(managerId: string) {
    // Get manager's assigned households via HouseholdSettings
    const settings = await this.prisma.householdSettings.findMany({
      where: { homeManagerId: managerId },
      include: {
        household: {
          include: {
            property: true,
            users: { where: { role: 'HOMEOWNER' }, take: 1 },
            bills: { where: { status: 'ACTIVE' } },
          },
        },
      },
    });

    const households = settings.map((s) => s.household);
    const householdIds = households.map((h) => h.id);

    // Get pending onboarding sessions assigned to this manager
    const pendingOnboarding = await this.prisma.onboardingSession.count({
      where: {
        assignedManagerId: managerId,
        status: { in: ['PENDING_CALL', 'CALL_SCHEDULED', 'INTAKE_PARTIAL'] },
      },
    });

    // Get recent activity across managed households
    const recentActivity = await this.prisma.activityLog.findMany({
      where: { householdId: { in: householdIds } },
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: { household: { select: { name: true } } },
    });

    // Calculate bills due
    const billsDue = households.reduce((sum, h) => {
      return sum + h.bills.reduce((s, b) => s + (b.amount || 0), 0);
    }, 0);

    return {
      stats: {
        householdsManaged: households.length,
        pendingOnboarding,
        urgentItems: pendingOnboarding, // Simplified
        tasksToday: 0, // TODO: Implement tasks
        billsDueThisWeek: billsDue,
      },
      households: households.map((h) => ({
        id: h.id,
        name: h.name,
        address: h.property
          ? `${h.property.street}, ${h.property.city}`
          : null,
        primaryContact: h.users[0]?.name || 'Unknown',
        status: 'good',
        taskCount: 0,
        unreadMessages: 0,
        lastContact: 'Recently',
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

  async getOnboardingQueue(managerId: string, status?: string) {
    const where: any = {
      assignedManagerId: managerId,
    };

    if (status && status !== 'active') {
      where.status = status;
    } else {
      where.status = {
        in: ['PENDING_CALL', 'CALL_SCHEDULED', 'CALL_IN_PROGRESS', 'INTAKE_PARTIAL', 'INTAKE_COMPLETE', 'PROFILE_BUILDING', 'SIGNUP_COMPLETE'],
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
      assignedManager: null,
      progress: Math.round(
        (s.progressFamily + s.progressProperty + s.progressZones + 
         s.progressSystems + s.progressVendors + s.progressBills) / 6
      ),
      enrichmentHighlights: [],
      createdAt: s.createdAt,
    }));
  }

  async getMyActivity(managerId: string, limit = 50) {
    const settings = await this.prisma.householdSettings.findMany({
      where: { homeManagerId: managerId },
      select: { householdId: true },
    });

    const householdIds = settings.map((s) => s.householdId);

    if (householdIds.length === 0) {
      return [];
    }

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

### Task 2.2: Create Manager Controller

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
    @Body() body: {
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

### Task 2.3: Create Manager Module

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

### Task 2.4: Register Manager Module

Add to `apps/api/src/app.module.ts`:

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

## PHASE 3: Update Manager Dashboard (Add, Don't Delete)

### Task 3.1: Add API Fetching to Dashboard

In `apps/web/src/app/manager/page.tsx`, find the `loadData` function and **enhance** it (don't replace):

Add these imports at the top if not present:
```typescript
import { getIdToken } from '@/lib/firebase';
```

Add state for API data:
```typescript
const [dashboardData, setDashboardData] = useState<any>(null);
```

Update or add the loadData function:
```typescript
const loadData = useCallback(async () => {
  try {
    const token = await getIdToken();
    if (!token) {
      setIsLoading(false);
      return;
    }

    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    // Fetch dashboard data from API
    const response = await fetch(`${apiUrl}/manager/dashboard`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (response.ok) {
      const data = await response.json();
      setDashboardData(data);
      
      // Also update households state if the component uses it
      if (data.households) {
        setHouseholds(data.households);
      }
    } else {
      console.error('Dashboard fetch failed:', response.status);
    }
    
    // Keep existing API calls if they exist
    try {
      const [requestsData, householdsData] = await Promise.all([
        api.getManagerRequests?.() || Promise.resolve([]),
        api.getHouseholds?.() || Promise.resolve([]),
      ]);
      if (requestsData) setRequests(requestsData);
      if (householdsData && householdsData.length > 0) setHouseholds(householdsData);
    } catch (innerErr) {
      // Existing API might not exist, that's okay
      console.log('Legacy API not available, using new endpoints');
    }
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to load data';
    setError(message);
  } finally {
    setIsLoading(false);
  }
}, [api]);
```

Update the stats calculation to prefer API data:
```typescript
const stats = useMemo(() => {
  // Prefer real API data
  if (dashboardData?.stats) {
    return {
      householdsManaged: dashboardData.stats.householdsManaged,
      urgentItems: dashboardData.stats.urgentItems,
      tasksToday: dashboardData.stats.tasksToday,
      pendingApprovals: dashboardData.stats.pendingOnboarding,
      billsDueThisWeek: dashboardData.stats.billsDueThisWeek,
    };
  }
  
  // Fallback to calculated/mock data
  const realHouseholds = households.length || mockHouseholds.length;
  const urgentFromRequests = requests.filter((r) => r.priority === 'URGENT' && r.status !== 'COMPLETED').length;
  return {
    householdsManaged: realHouseholds,
    urgentItems: Math.max(urgentFromRequests, mockUrgentItems.length),
    tasksToday: mockTasks.fromHomeowners.length + mockTasks.systemGenerated.length,
    pendingApprovals: 4,
    billsDueThisWeek: 12847.23,
  };
}, [dashboardData, requests, households]);
```

### Task 3.2: Add Real Households Display

Add computed value for display households:
```typescript
const displayHouseholds = useMemo(() => {
  // Prefer API data
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
  // Fallback to mock
  return mockHouseholds;
}, [dashboardData]);
```

Then in the JSX where households are rendered, use `displayHouseholds` instead of `mockHouseholds`.

### Task 3.3: Add Real Activity Display

```typescript
const displayActivity = useMemo(() => {
  if (dashboardData?.recentActivity?.length > 0) {
    return dashboardData.recentActivity.map((a: any) => ({
      id: a.id,
      timeAgo: formatTimeAgo(new Date(a.createdAt)),
      household: a.householdName?.split(' ')[0] || 'Unknown',
      action: a.title,
      detail: a.description || '',
      type: mapCategoryToType(a.category),
    }));
  }
  return mockActivities;
}, [dashboardData]);

// Helper functions (add if not present):
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

function mapCategoryToType(category: string): 'request' | 'approval' | 'message' | 'payment' {
  const map: Record<string, 'request' | 'approval' | 'message' | 'payment'> = {
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

## PHASE 4: Enhance Intake Workbench (Add Save Functionality)

### Task 4.1: Add Auto-Save to Intake Workbench

In `apps/web/src/app/manager/onboarding/[sessionId]/page.tsx`, add saving functionality.

Add imports:
```typescript
import { getIdToken } from '@/lib/firebase';
```

Add state:
```typescript
const [saving, setSaving] = useState(false);
const [lastSaved, setLastSaved] = useState<Date | null>(null);
```

Add save function:
```typescript
const saveSection = async (sectionId: string, sectionData: any) => {
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
        data: sectionData,
      }),
    });

    if (response.ok) {
      setLastSaved(new Date());
    } else {
      console.error('Failed to save section:', response.status);
    }
  } catch (error) {
    console.error('Save error:', error);
  } finally {
    setSaving(false);
  }
};
```

Add auto-save effect:
```typescript
// Debounced auto-save when form data changes
useEffect(() => {
  if (!activeSection || !formData[activeSection]) return;
  
  const timer = setTimeout(() => {
    saveSection(activeSection, formData[activeSection]);
  }, 2000); // Save 2 seconds after last change
  
  return () => clearTimeout(timer);
}, [formData, activeSection]);
```

Add save indicator to UI (find the header area and add):
```typescript
{/* Save Status Indicator */}
<div className="flex items-center gap-2 text-sm">
  {saving ? (
    <span className="text-gray-500 flex items-center gap-1">
      <Loader2 className="w-3 h-3 animate-spin" />
      Saving...
    </span>
  ) : lastSaved ? (
    <span className="text-green-600 flex items-center gap-1">
      <CheckCircle className="w-3 h-3" />
      Saved
    </span>
  ) : null}
</div>
```

### Task 4.2: Load Existing Intake Data

In the session fetch function, load existing intake data into form:
```typescript
const fetchSession = async () => {
  try {
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    const response = await fetch(`${apiUrl}/onboarding/${sessionId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (response.ok) {
      const data = await response.json();
      setSession(data);
      
      // Load existing intake data if present
      if (data.intakeData && typeof data.intakeData === 'object') {
        setFormData(data.intakeData);
      }
    }
  } catch (error) {
    console.error('Failed to load session:', error);
  } finally {
    setLoading(false);
  }
};
```

---

## PHASE 5: Setup Sarah's Firebase Login

### Task 5.1: Create Setup Script

Create `apps/api/scripts/setup-sarah.ts`:

```typescript
import * as admin from 'firebase-admin';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Setting up Sarah Chen...');
  
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
      console.log('✓ Firebase user exists:', firebaseUser.uid);
    } catch (e: any) {
      if (e.code === 'auth/user-not-found') {
        firebaseUser = await admin.auth().createUser({
          email,
          password,
          displayName: 'Sarah Chen',
        });
        console.log('✓ Created Firebase user:', firebaseUser.uid);
      } else {
        throw e;
      }
    }

    // Update database user with Firebase UID
    const updated = await prisma.user.update({
      where: { email },
      data: { firebaseUid: firebaseUser.uid },
    });
    
    console.log('✓ Updated database user:', updated.id);
    console.log('');
    console.log('═══════════════════════════════════════');
    console.log('Sarah Chen is ready to login!');
    console.log('───────────────────────────────────────');
    console.log('Email:    ', email);
    console.log('Password: ', password);
    console.log('Portal:    /manager');
    console.log('═══════════════════════════════════════');
  } catch (error) {
    console.error('Failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
```

Add to `apps/api/package.json` scripts:
```json
"setup-sarah": "ts-node scripts/setup-sarah.ts"
```

Run it:
```bash
cd apps/api
pnpm setup-sarah
```

---

## PHASE 6: Ensure Onboarding API Endpoints Work

### Task 6.1: Verify Onboarding Endpoints Exist

Check that these endpoints exist in `apps/api/src/onboarding/onboarding.controller.ts`:

- `GET /onboarding/queue` - Get queue (for managers)
- `GET /onboarding/:id` - Get session details
- `PUT /onboarding/:id/intake` - Update intake data
- `POST /onboarding/:id/start-call` - Start call
- `POST /onboarding/:id/complete` - Complete intake

If any are missing, add them based on the OnboardingService from Prompt 003.

### Task 6.2: Fix Queue Endpoint Route

The manager portal fetches from `/manager/onboarding/queue` but the onboarding controller might be at `/onboarding/queue`. Either:

**Option A:** Update frontend to use `/onboarding/queue`

OR

**Option B:** Add route in ManagerController:
```typescript
@Get('onboarding/queue')
async getOnboardingQueue(@Request() req: any, @Query('status') status?: string) {
  return this.managerService.getOnboardingQueue(req.user.id, status);
}
```

The Manager service already has `getOnboardingQueue` so Option B is cleaner.

---

## PHASE 7: Build and Test

### Task 7.1: Build

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

Fix any TypeScript errors.

### Task 7.2: Test Locally

```bash
# Terminal 1
pnpm dev:api

# Terminal 2
pnpm dev:web
```

### Task 7.3: Test Admin Login

1. Go to http://localhost:3000/login
2. Login as tom@havenhome.dev
3. Navigate to /admin
4. Should see dashboard (not infinite loading)

### Task 7.4: Test Manager Login

1. Go to http://localhost:3000/login
2. Login as sarah@haven.app
3. Navigate to /manager
4. Should see dashboard with Morrison household

### Task 7.5: Commit

```bash
git add .
git commit -m "fix: admin login + connect manager portal to real APIs"
```

### Task 7.6: Deploy

```bash
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## Verification Checklist

### Admin Login
- [ ] Can login as tom@havenhome.dev
- [ ] Redirects to /admin (not stuck on loading)
- [ ] Dashboard shows stats

### Manager Login
- [ ] Can login as sarah@haven.app
- [ ] Dashboard loads with real data
- [ ] Morrison household appears in list
- [ ] Activity feed shows real activity

### Manager Features
- [ ] /manager/onboarding shows queue
- [ ] Can click into onboarding session
- [ ] Intake workbench saves data (see "Saved" indicator)
- [ ] /manager/households shows assigned households

### No Deletions
- [ ] Homeowner portal still works (/app)
- [ ] Existing manager pages still render
- [ ] Handyman/Vendor portals untouched

---

## Summary

This prompt:
1. ✅ Fixes the `/user/me` endpoint to return role
2. ✅ Fixes FirebaseAuthGuard to attach full user
3. ✅ Fixes admin layout auth check
4. ✅ Adds Manager API endpoints
5. ✅ Enhances Manager Dashboard with real data (keeps mock fallback)
6. ✅ Adds auto-save to Intake Workbench
7. ✅ Sets up Sarah's login credentials
8. ✅ Does NOT delete any existing code
