# Haven Homeowner Portal - Production Ready Build

**Created:** December 26, 2024  
**Purpose:** Make the homeowner portal display ALL data captured during onboarding  
**Priority:** Critical - Required for production launch

---

## Goal

Make the homeowner portal display ALL data captured during onboarding. Every field the Home Manager enters should be visible to the homeowner in a beautiful, useful way.

The homeowner should log in post-onboarding and think: "Wow, they know everything about my home. I never have to explain anything again."

---

## Context

We built a comprehensive onboarding system where Home Managers capture 175+ data points about a household:
- Property details (from ATTOM enrichment)
- Zones (Kitchen, Laundry, Garage, etc.)
- Assets/Appliances (brand, model, age, condition)
- Systems (HVAC, plumbing, electrical, roof)
- Family (adults, kids with schools/activities, pets, staff)
- Vehicles (make, model, payments, insurance)
- Vendors (name, contact, account numbers, service history)
- Bills (every payment with account numbers)

**The Problem:** This data is captured but doesn't flow to the homeowner portal. Homeowners would log in and see generic/mock content instead of their actual home data.

---

## PHASE 1: Activity Log System (The Foundation)

Every action in Haven should be logged so all parties have visibility.

### Task 1.1: Create ActivityLog Model

Update `apps/api/prisma/schema.prisma`:

```prisma
model ActivityLog {
  id          String   @id @default(cuid())
  householdId String
  household   Household @relation(fields: [householdId], references: [id])
  
  // Who did this
  actorId     String        // User ID
  actorType   ActorType     // HOMEOWNER, HOME_MANAGER, HANDYMAN, SYSTEM
  actorName   String        // "Sarah Chen", "Mike Rodriguez"
  
  // What happened
  action      ActivityAction
  category    ActivityCategory
  title       String        // "Paid Eversource Electric"
  description String?       // "December bill - $187.43"
  
  // Links to related records
  billId      String?
  vendorId    String?
  assetId     String?
  zoneId      String?
  taskId      String?
  
  // Metadata
  amount      Float?        // For financial activities
  metadata    Json?         // Any additional data
  
  // Visibility
  visibleToHomeowner Boolean @default(true)
  visibleToHandyman  Boolean @default(false)
  
  createdAt   DateTime @default(now())
}

enum ActorType {
  HOMEOWNER
  HOME_MANAGER
  HANDYMAN
  VENDOR
  SYSTEM
}

enum ActivityAction {
  // Bills
  BILL_PAID
  BILL_SCHEDULED
  BILL_ADDED
  
  // Service
  SERVICE_COMPLETED
  SERVICE_SCHEDULED
  SERVICE_REQUESTED
  
  // Property
  ASSET_ADDED
  ASSET_UPDATED
  ZONE_ADDED
  
  // Vendor
  VENDOR_ADDED
  VENDOR_CONTACTED
  
  // Approval
  APPROVAL_REQUESTED
  APPROVAL_GRANTED
  APPROVAL_DENIED
  
  // Communication
  MESSAGE_SENT
  NOTE_ADDED
  
  // System
  REMINDER_SENT
  DOCUMENT_UPLOADED
}

enum ActivityCategory {
  BILLING
  SERVICE
  MAINTENANCE
  COMMUNICATION
  PROPERTY
  FAMILY
  SYSTEM
}
```

### Task 1.2: Create Activity Service

Create `apps/api/src/activity/activity.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ActivityService {
  constructor(private prisma: PrismaService) {}

  async log(data: {
    householdId: string;
    actorId: string;
    actorType: ActorType;
    actorName: string;
    action: ActivityAction;
    category: ActivityCategory;
    title: string;
    description?: string;
    billId?: string;
    vendorId?: string;
    assetId?: string;
    amount?: number;
    metadata?: any;
    visibleToHomeowner?: boolean;
    visibleToHandyman?: boolean;
  }) {
    return this.prisma.activityLog.create({ data });
  }

  async getForHousehold(householdId: string, options?: {
    limit?: number;
    category?: ActivityCategory;
    startDate?: Date;
    endDate?: Date;
  }) {
    return this.prisma.activityLog.findMany({
      where: {
        householdId,
        visibleToHomeowner: true,
        category: options?.category,
        createdAt: {
          gte: options?.startDate,
          lte: options?.endDate,
        },
      },
      orderBy: { createdAt: 'desc' },
      take: options?.limit || 20,
    });
  }
}
```

### Task 1.3: Create Activity Module

Create `apps/api/src/activity/activity.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ActivityService } from './activity.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  providers: [ActivityService],
  exports: [ActivityService],
})
export class ActivityModule {}
```

### Task 1.4: Integrate Activity Logging

Every service that modifies data should log activities. Update BillService as example:

```typescript
// apps/api/src/bill/bill.service.ts

import { ActivityService } from '../activity/activity.service';

@Injectable()
export class BillService {
  constructor(
    private prisma: PrismaService,
    private activityService: ActivityService,
  ) {}

  // When Home Manager pays a bill
  async payBill(billId: string, paymentData: PaymentDto, actor: User) {
    const bill = await this.prisma.bill.findUnique({ 
      where: { id: billId },
      include: { vendor: true },
    });
    
    // Create payment record
    const payment = await this.prisma.billPayment.create({
      data: {
        billId,
        amount: paymentData.amount,
        paidDate: new Date(),
        paidBy: 'Haven',
        method: paymentData.method,
        confirmationNumber: paymentData.confirmationNumber,
      },
    });
    
    // Log activity
    await this.activityService.log({
      householdId: bill.householdId,
      actorId: actor.id,
      actorType: 'HOME_MANAGER',
      actorName: actor.name,
      action: 'BILL_PAID',
      category: 'BILLING',
      title: `Paid ${bill.name}`,
      description: `$${paymentData.amount.toFixed(2)}`,
      billId: bill.id,
      vendorId: bill.vendorId,
      amount: paymentData.amount,
    });
    
    return payment;
  }
}
```

---

## PHASE 2: Dashboard API & Frontend

### Task 2.1: Create Dashboard API Endpoint

Add to `apps/api/src/household/household.controller.ts`:

```typescript
import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { HouseholdService } from './household.service';
import { BillService } from '../bill/bill.service';
import { ActivityService } from '../activity/activity.service';
import { PropertyService } from '../property/property.service';

@Controller('household')
export class HouseholdController {
  constructor(
    private householdService: HouseholdService,
    private billService: BillService,
    private activityService: ActivityService,
    private propertyService: PropertyService,
  ) {}

  @Get(':id/dashboard')
  @UseGuards(FirebaseAuthGuard)
  async getDashboard(@Param('id') householdId: string) {
    const household = await this.householdService.findById(householdId);
    
    // Get this month's billing summary
    const billingSummary = await this.billService.getMonthlySummary(householdId);
    
    // Get next scheduled service
    const nextService = await this.propertyService.getNextScheduledService(householdId);
    
    // Get pending approvals count
    const pendingApprovals = await this.householdService.getPendingApprovalsCount(householdId);
    
    // Get recent activity (last 10)
    const recentActivity = await this.activityService.getForHousehold(householdId, { limit: 10 });
    
    // Get upcoming items (next 7 days)
    const upcoming = await this.householdService.getUpcomingItems(householdId, 7);
    
    // Calculate home health score
    const homeHealth = await this.propertyService.calculateHealthScore(householdId);
    
    return {
      household: {
        id: household.id,
        name: household.name,
        propertyAddress: household.property?.fullAddress,
      },
      homeHealth,
      billing: {
        monthlyFunding: billingSummary.funding,
        amountPaid: billingSummary.totalPaid,
        billsPaidCount: billingSummary.billsPaidCount,
        bufferRemaining: billingSummary.funding - billingSummary.totalPaid,
      },
      nextService: nextService ? {
        title: nextService.title,
        vendorName: nextService.vendor?.name,
        date: nextService.scheduledDate,
      } : null,
      pendingApprovals,
      recentActivity: recentActivity.map(a => ({
        id: a.id,
        title: a.title,
        description: a.description,
        actorName: a.actorName,
        category: a.category,
        createdAt: a.createdAt,
      })),
      upcoming: upcoming.map(u => ({
        id: u.id,
        title: u.title,
        type: u.type,
        date: u.date,
      })),
    };
  }
}
```

### Task 2.2: Add Bill Service Methods

Add to `apps/api/src/bill/bill.service.ts`:

```typescript
async getMonthlySummary(householdId: string) {
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);
  
  const endOfMonth = new Date(startOfMonth);
  endOfMonth.setMonth(endOfMonth.getMonth() + 1);
  
  // Get household settings for funding amount
  const settings = await this.prisma.householdSettings.findUnique({
    where: { householdId },
  });
  
  // Get payments this month
  const payments = await this.prisma.billPayment.findMany({
    where: {
      bill: { householdId },
      paidDate: {
        gte: startOfMonth,
        lt: endOfMonth,
      },
    },
  });
  
  const totalPaid = payments.reduce((sum, p) => sum + p.amount, 0);
  
  return {
    funding: settings?.monthlyFunding || 0,
    totalPaid,
    billsPaidCount: payments.length,
  };
}
```

### Task 2.3: Rebuild Dashboard Frontend

Replace `apps/web/src/app/app/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/auth-context';
import Link from 'next/link';
import { 
  CreditCard, Wrench, CheckCircle, Clock, ChevronRight,
  Activity, Calendar, AlertCircle
} from 'lucide-react';

interface DashboardData {
  household: { id: string; name: string; propertyAddress: string };
  homeHealth: number;
  billing: {
    monthlyFunding: number;
    amountPaid: number;
    billsPaidCount: number;
    bufferRemaining: number;
  };
  nextService: { title: string; vendorName: string; date: string } | null;
  pendingApprovals: number;
  recentActivity: Array<{
    id: string;
    title: string;
    description?: string;
    actorName: string;
    category: string;
    createdAt: string;
  }>;
  upcoming: Array<{
    id: string;
    title: string;
    type: string;
    date: string;
  }>;
}

function getGreeting() {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

function formatRelativeTime(dateString: string) {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString();
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

function HomeHealthBadge({ score }: { score: number }) {
  const color = score >= 90 ? 'green' : score >= 70 ? 'yellow' : 'red';
  const label = score >= 90 ? 'Excellent' : score >= 70 ? 'Good' : 'Needs Attention';
  
  return (
    <div className={`px-4 py-2 rounded-xl ${
      color === 'green' ? 'bg-green-100 text-green-800' :
      color === 'yellow' ? 'bg-yellow-100 text-yellow-800' :
      'bg-red-100 text-red-800'
    }`}>
      <div className="text-2xl font-bold">{score}</div>
      <div className="text-xs">{label}</div>
    </div>
  );
}

function getItemIcon(type: string) {
  switch (type) {
    case 'service': return <Wrench className="w-5 h-5 text-blue-600" />;
    case 'bill': return <CreditCard className="w-5 h-5 text-green-600" />;
    case 'activity': return <Activity className="w-5 h-5 text-purple-600" />;
    default: return <Calendar className="w-5 h-5 text-gray-600" />;
  }
}

function DashboardSkeleton() {
  return (
    <div className="p-6 max-w-6xl mx-auto animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-64 mb-2" />
      <div className="h-4 bg-gray-200 rounded w-48 mb-8" />
      <div className="grid grid-cols-3 gap-4 mb-8">
        {[1, 2, 3].map(i => (
          <div key={i} className="h-32 bg-gray-200 rounded-xl" />
        ))}
      </div>
    </div>
  );
}

export default function DashboardPage() {
  const { user } = useAuth();
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchDashboard();
  }, []);

  const fetchDashboard = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/household/${user?.householdId}/dashboard`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      if (!response.ok) throw new Error('Failed to load dashboard');
      
      const result = await response.json();
      setData(result);
    } catch (err) {
      console.error('Dashboard error:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <DashboardSkeleton />;
  if (error) return <div className="p-6 text-red-600">Error: {error}</div>;
  if (!data) return <div className="p-6">No data available</div>;

  const greeting = getGreeting();
  const firstName = user?.displayName?.split(' ')[0] || 'there';

  return (
    <div className="p-6 max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-haven-navy-900">
            {greeting}, {firstName}! 👋
          </h1>
          <p className="text-gray-500">{data.household.propertyAddress}</p>
        </div>
        <HomeHealthBadge score={data.homeHealth} />
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        {/* This Month */}
        <div className="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <CreditCard className="w-5 h-5 text-green-600" />
            </div>
            <span className="font-medium text-gray-600">This Month</span>
          </div>
          <div className="text-2xl font-bold text-haven-navy-900">
            ${data.billing.amountPaid.toLocaleString()}
          </div>
          <div className="text-sm text-gray-500">
            {data.billing.billsPaidCount} bills paid ✓
          </div>
          <div className="mt-2 w-full bg-gray-100 rounded-full h-2">
            <div 
              className="bg-green-500 h-2 rounded-full transition-all"
              style={{ width: `${Math.min((data.billing.amountPaid / data.billing.monthlyFunding) * 100, 100)}%` }}
            />
          </div>
          <div className="text-xs text-gray-400 mt-1">
            ${data.billing.bufferRemaining.toFixed(0)} buffer remaining
          </div>
        </div>

        {/* Next Service */}
        <div className="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <Wrench className="w-5 h-5 text-blue-600" />
            </div>
            <span className="font-medium text-gray-600">Next Service</span>
          </div>
          {data.nextService ? (
            <>
              <div className="text-lg font-semibold text-haven-navy-900">
                {data.nextService.title}
              </div>
              <div className="text-sm text-gray-500">
                {data.nextService.vendorName}
              </div>
              <div className="text-sm text-haven-champagne-600 mt-1">
                {formatDate(data.nextService.date)}
              </div>
            </>
          ) : (
            <div className="text-gray-400">No services scheduled</div>
          )}
        </div>

        {/* Action Items */}
        <div className="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-3">
            <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
              data.pendingApprovals > 0 ? 'bg-orange-100' : 'bg-gray-100'
            }`}>
              {data.pendingApprovals > 0 ? (
                <AlertCircle className="w-5 h-5 text-orange-600" />
              ) : (
                <CheckCircle className="w-5 h-5 text-gray-400" />
              )}
            </div>
            <span className="font-medium text-gray-600">Action Items</span>
          </div>
          {data.pendingApprovals > 0 ? (
            <>
              <div className="text-2xl font-bold text-haven-navy-900">
                {data.pendingApprovals}
              </div>
              <div className="text-sm text-orange-600">
                approval{data.pendingApprovals > 1 ? 's' : ''} needed
              </div>
              <Link 
                href="/app/sarah"
                className="inline-block mt-2 text-sm text-haven-champagne-600 hover:underline"
              >
                Review now →
              </Link>
            </>
          ) : (
            <div className="text-gray-400">All caught up! ✓</div>
          )}
        </div>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Activity */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100">
          <div className="p-5 border-b border-gray-100 flex items-center justify-between">
            <h2 className="font-semibold text-haven-navy-900 flex items-center gap-2">
              <Activity className="w-5 h-5" />
              Recent Activity
            </h2>
            <Link href="/app/activity" className="text-sm text-haven-champagne-600 hover:underline">
              See all
            </Link>
          </div>
          <div className="divide-y divide-gray-50">
            {data.recentActivity.length > 0 ? (
              data.recentActivity.map((activity) => (
                <div key={activity.id} className="p-4 hover:bg-gray-50 transition">
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="font-medium text-haven-navy-900">
                        {activity.title}
                      </div>
                      {activity.description && (
                        <div className="text-sm text-gray-500">{activity.description}</div>
                      )}
                      <div className="text-xs text-gray-400 mt-1">
                        {activity.actorName}
                      </div>
                    </div>
                    <div className="text-xs text-gray-400">
                      {formatRelativeTime(activity.createdAt)}
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="p-8 text-center text-gray-400">
                No recent activity yet
              </div>
            )}
          </div>
        </div>

        {/* Upcoming */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100">
          <div className="p-5 border-b border-gray-100 flex items-center justify-between">
            <h2 className="font-semibold text-haven-navy-900 flex items-center gap-2">
              <Calendar className="w-5 h-5" />
              Upcoming
            </h2>
            <Link href="/app/calendar" className="text-sm text-haven-champagne-600 hover:underline">
              View calendar
            </Link>
          </div>
          <div className="divide-y divide-gray-50">
            {data.upcoming.length > 0 ? (
              data.upcoming.map((item) => (
                <div key={item.id} className="p-4 flex items-center gap-4">
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                    item.type === 'service' ? 'bg-blue-100' :
                    item.type === 'bill' ? 'bg-green-100' :
                    item.type === 'activity' ? 'bg-purple-100' : 'bg-gray-100'
                  }`}>
                    {getItemIcon(item.type)}
                  </div>
                  <div className="flex-1">
                    <div className="font-medium text-haven-navy-900">{item.title}</div>
                    <div className="text-sm text-gray-500">{formatDate(item.date)}</div>
                  </div>
                </div>
              ))
            ) : (
              <div className="p-8 text-center text-gray-400">
                Nothing scheduled yet
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

## PHASE 3: Your Home Page with Zones

### Task 3.1: Create Property API with Zones

Add to `apps/api/src/property/property.controller.ts`:

```typescript
@Get('household/:householdId')
@UseGuards(FirebaseAuthGuard)
async getPropertyWithZones(@Param('householdId') householdId: string) {
  const property = await this.prisma.property.findFirst({
    where: { householdId },
    include: {
      zones: {
        include: {
          assets: {
            include: {
              serviceVendor: true,
              serviceHistory: {
                orderBy: { serviceDate: 'desc' },
                take: 1,
              },
            },
          },
        },
        orderBy: { name: 'asc' },
      },
    },
  });

  if (!property) {
    throw new NotFoundException('Property not found');
  }

  // Calculate systems status
  const systems = await this.propertyService.getSystemsStatus(property.id);

  return {
    property: {
      id: property.id,
      name: property.name,
      address: {
        street: property.street,
        city: property.city,
        state: property.state,
        zip: property.zip,
        full: `${property.street}, ${property.city}, ${property.state} ${property.zip}`,
      },
      details: {
        bedrooms: property.bedrooms,
        bathrooms: property.bathrooms,
        squareFeet: property.squareFeet,
        yearBuilt: property.yearBuilt,
        lotSize: property.lotSizeAcres,
        propertyType: property.propertyType,
      },
      enrichment: property.enrichmentData,
    },
    systems,
    zones: property.zones.map(zone => ({
      id: zone.id,
      name: zone.name,
      type: zone.type,
      floor: zone.floor,
      assetCount: zone.assets.length,
      photos: zone.photos,
      assets: zone.assets.map(asset => ({
        id: asset.id,
        name: asset.name,
        category: asset.category,
        brand: asset.brand,
        model: asset.model,
        condition: asset.condition,
        lastServiceDate: asset.serviceHistory[0]?.serviceDate,
        nextServiceDate: asset.nextServiceDate,
        serviceVendor: asset.serviceVendor?.name,
      })),
    })),
  };
}
```

### Task 3.2: Create Your Home Page

Create `apps/web/src/app/app/home/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { 
  Thermometer, Droplets, Zap, Shield, Home,
  ChevronRight, FileText
} from 'lucide-react';

const zoneIcons: Record<string, string> = {
  KITCHEN: '🍳',
  LIVING_ROOM: '🛋️',
  DINING_ROOM: '🍽️',
  BEDROOM: '🛏️',
  BATHROOM: '🛁',
  GARAGE: '🚗',
  BASEMENT: '🏚️',
  ATTIC: '📦',
  LAUNDRY: '🧺',
  OFFICE: '💼',
  OUTDOOR_FRONT: '🌳',
  OUTDOOR_BACK: '🏡',
  POOL_AREA: '🏊',
  MECHANICAL: '⚙️',
  OTHER: '🏠',
};

interface PropertyData {
  property: {
    id: string;
    name: string;
    address: { full: string };
    details: {
      bedrooms: number;
      bathrooms: number;
      squareFeet: number;
      yearBuilt: number;
    };
  };
  systems: Array<{
    id: string;
    name: string;
    category: string;
    status: 'good' | 'warning' | 'attention';
    warning?: string;
  }>;
  zones: Array<{
    id: string;
    name: string;
    type: string;
    assetCount: number;
    photos: string[];
  }>;
}

function getSystemIcon(category: string) {
  switch (category) {
    case 'HVAC': return <Thermometer className="w-4 h-4" />;
    case 'PLUMBING': return <Droplets className="w-4 h-4" />;
    case 'ELECTRICAL': return <Zap className="w-4 h-4" />;
    case 'SECURITY': return <Shield className="w-4 h-4" />;
    default: return <Home className="w-4 h-4" />;
  }
}

function HomeHealthBadge({ score, size = 'normal' }: { score: number; size?: 'normal' | 'large' }) {
  const color = score >= 90 ? 'green' : score >= 70 ? 'yellow' : 'red';
  const label = score >= 90 ? 'Excellent' : score >= 70 ? 'Good' : 'Needs Attention';
  
  return (
    <div className={`rounded-xl text-center ${
      size === 'large' ? 'px-6 py-3' : 'px-4 py-2'
    } ${
      color === 'green' ? 'bg-green-100 text-green-800' :
      color === 'yellow' ? 'bg-yellow-100 text-yellow-800' :
      'bg-red-100 text-red-800'
    }`}>
      <div className={`font-bold ${size === 'large' ? 'text-3xl' : 'text-2xl'}`}>{score}</div>
      <div className="text-xs">{label}</div>
    </div>
  );
}

export default function YourHomePage() {
  const { user } = useAuth();
  const [data, setData] = useState<PropertyData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProperty();
  }, []);

  const fetchProperty = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/property/household/${user?.householdId}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setData(await response.json());
      }
    } catch (error) {
      console.error('Failed to load property:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="p-6 max-w-6xl mx-auto animate-pulse">
        <div className="h-32 bg-gray-200 rounded-2xl mb-6" />
        <div className="h-24 bg-gray-200 rounded-xl mb-6" />
        <div className="grid grid-cols-4 gap-4">
          {[1,2,3,4].map(i => <div key={i} className="h-40 bg-gray-200 rounded-xl" />)}
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="p-6 text-center">
        <p className="text-gray-500">Property data not available yet.</p>
        <p className="text-sm text-gray-400 mt-2">Your Home Manager will set this up during your intro call.</p>
      </div>
    );
  }

  const totalAssets = data.zones.reduce((sum, z) => sum + z.assetCount, 0);

  return (
    <div className="p-6 max-w-6xl mx-auto">
      {/* Property Header */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-haven-navy-900">
              {data.property.name || 'Your Home'}
            </h1>
            <p className="text-gray-500">{data.property.address.full}</p>
            <div className="flex items-center gap-4 mt-3 text-sm text-gray-600">
              <span>{data.property.details.bedrooms} bed</span>
              <span>•</span>
              <span>{data.property.details.bathrooms} bath</span>
              <span>•</span>
              <span>{data.property.details.squareFeet?.toLocaleString()} sqft</span>
              {data.property.details.yearBuilt && (
                <>
                  <span>•</span>
                  <span>Built {data.property.details.yearBuilt}</span>
                </>
              )}
            </div>
          </div>
          <HomeHealthBadge score={94} size="large" />
        </div>
      </div>

      {/* Systems Overview */}
      <div className="mb-6">
        <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">
          Systems Overview
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          {data.systems.map((system) => (
            <Link
              key={system.id}
              href={`/app/home/systems/${system.id}`}
              className="bg-white rounded-xl p-4 border border-gray-100 hover:shadow-md transition"
            >
              <div className="flex items-center gap-2 mb-2">
                {getSystemIcon(system.category)}
                <span className="font-medium text-sm">{system.name}</span>
              </div>
              <div className={`text-xs font-medium ${
                system.status === 'good' ? 'text-green-600' :
                system.status === 'warning' ? 'text-yellow-600' : 'text-red-600'
              }`}>
                {system.status === 'good' ? '✓ Good' :
                 system.status === 'warning' ? `⚠️ ${system.warning}` : '⚠️ Attention'}
              </div>
            </Link>
          ))}
        </div>
      </div>

      {/* Zones Grid */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-haven-navy-900">
            Zones
          </h2>
          <span className="text-sm text-gray-500">
            {data.zones.length} zones • {totalAssets} items
          </span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {data.zones.map((zone) => (
            <Link
              key={zone.id}
              href={`/app/home/zones/${zone.id}`}
              className="bg-white rounded-xl border border-gray-100 overflow-hidden hover:shadow-md transition group"
            >
              {zone.photos?.[0] ? (
                <div className="aspect-video bg-gray-100">
                  <img 
                    src={zone.photos[0]} 
                    alt={zone.name}
                    className="w-full h-full object-cover"
                  />
                </div>
              ) : (
                <div className="aspect-video bg-gray-50 flex items-center justify-center text-4xl">
                  {zoneIcons[zone.type] || '🏠'}
                </div>
              )}
              <div className="p-4">
                <div className="font-medium text-haven-navy-900 group-hover:text-haven-champagne-600 transition">
                  {zone.name}
                </div>
                <div className="text-sm text-gray-500">
                  {zone.assetCount} item{zone.assetCount !== 1 ? 's' : ''}
                </div>
              </div>
            </Link>
          ))}
        </div>
      </div>

      {/* Quick Access Documents */}
      <div>
        <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">
          Quick Access
        </h2>
        <div className="flex flex-wrap gap-3">
          <button className="flex items-center gap-2 px-4 py-2 bg-gray-100 rounded-lg text-sm hover:bg-gray-200 transition">
            <FileText className="w-4 h-4" />
            Home Insurance Policy
          </button>
          <button className="flex items-center gap-2 px-4 py-2 bg-gray-100 rounded-lg text-sm hover:bg-gray-200 transition">
            <FileText className="w-4 h-4" />
            Appliance Warranties
          </button>
          <button className="flex items-center gap-2 px-4 py-2 bg-gray-100 rounded-lg text-sm hover:bg-gray-200 transition">
            <FileText className="w-4 h-4" />
            Vendor Contacts
          </button>
        </div>
      </div>
    </div>
  );
}
```

### Task 3.3: Create Zone Detail Page

Create `apps/web/src/app/app/home/zones/[zoneId]/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { ChevronRight } from 'lucide-react';

const zoneIcons: Record<string, string> = {
  KITCHEN: '🍳',
  LIVING_ROOM: '🛋️',
  BATHROOM: '🛁',
  GARAGE: '🚗',
  LAUNDRY: '🧺',
  MECHANICAL: '⚙️',
};

interface ZoneData {
  id: string;
  name: string;
  type: string;
  floor?: string;
  photos: string[];
  procedures?: string;
  assets: Array<{
    id: string;
    name: string;
    brand?: string;
    model?: string;
    condition?: string;
    lastServiceDate?: string;
  }>;
}

function AssetStatusBadge({ condition }: { condition?: string }) {
  const color = condition === 'Excellent' || condition === 'Good' ? 'green' :
                condition === 'Fair' ? 'yellow' : 'red';
  
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${
      color === 'green' ? 'bg-green-100 text-green-700' :
      color === 'yellow' ? 'bg-yellow-100 text-yellow-700' :
      'bg-red-100 text-red-700'
    }`}>
      {condition || 'Unknown'}
    </span>
  );
}

export default function ZoneDetailPage() {
  const params = useParams();
  const { user } = useAuth();
  const [zone, setZone] = useState<ZoneData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchZone();
  }, [params.zoneId]);

  const fetchZone = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/zones/${params.zoneId}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setZone(await response.json());
      }
    } catch (error) {
      console.error('Failed to load zone:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="p-6 animate-pulse"><div className="h-64 bg-gray-200 rounded-xl" /></div>;
  }

  if (!zone) {
    return <div className="p-6 text-center text-gray-500">Zone not found</div>;
  }

  return (
    <div className="p-6 max-w-4xl mx-auto">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
        <Link href="/app/home" className="hover:text-haven-champagne-600">Your Home</Link>
        <ChevronRight className="w-4 h-4" />
        <span className="text-haven-navy-900">{zone.name}</span>
      </div>

      {/* Zone Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-haven-navy-900 flex items-center gap-3">
          <span className="text-3xl">{zoneIcons[zone.type] || '🏠'}</span>
          {zone.name}
        </h1>
        {zone.floor && (
          <p className="text-gray-500 mt-1">{zone.floor}</p>
        )}
      </div>

      {/* Zone Photos */}
      {zone.photos?.length > 0 && (
        <div className="mb-6">
          <div className="grid grid-cols-3 gap-2 rounded-xl overflow-hidden">
            {zone.photos.slice(0, 3).map((photo, idx) => (
              <img 
                key={idx}
                src={photo} 
                alt={`${zone.name} ${idx + 1}`}
                className="aspect-video object-cover"
              />
            ))}
          </div>
        </div>
      )}

      {/* Assets */}
      <div>
        <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">
          Items in {zone.name}
        </h2>
        {zone.assets.length > 0 ? (
          <div className="space-y-3">
            {zone.assets.map((asset) => (
              <Link
                key={asset.id}
                href={`/app/home/assets/${asset.id}`}
                className="block bg-white rounded-xl p-4 border border-gray-100 hover:shadow-md transition"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="font-medium text-haven-navy-900">
                      {asset.name}
                    </div>
                    {(asset.brand || asset.model) && (
                      <div className="text-sm text-gray-500">
                        {[asset.brand, asset.model].filter(Boolean).join(' ')}
                      </div>
                    )}
                    {asset.lastServiceDate && (
                      <div className="text-xs text-gray-400 mt-1">
                        Last serviced: {new Date(asset.lastServiceDate).toLocaleDateString()}
                      </div>
                    )}
                  </div>
                  <div className="flex items-center gap-3">
                    <AssetStatusBadge condition={asset.condition} />
                    <ChevronRight className="w-5 h-5 text-gray-300" />
                  </div>
                </div>
              </Link>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-400">
            No items recorded yet
          </div>
        )}
      </div>

      {/* Procedures */}
      {zone.procedures && (
        <div className="mt-6 p-4 bg-gray-50 rounded-xl">
          <h3 className="font-medium text-haven-navy-900 mb-2">Care Instructions</h3>
          <p className="text-sm text-gray-600">{zone.procedures}</p>
        </div>
      )}
    </div>
  );
}
```

---

## PHASE 4: Money/Bills Page

### Task 4.1: Create Bills Summary API

Add to `apps/api/src/bill/bill.controller.ts`:

```typescript
@Get('household/:householdId/summary')
@UseGuards(FirebaseAuthGuard)
async getBillsSummary(
  @Param('householdId') householdId: string,
  @Query('month') month?: string,
) {
  const targetDate = month ? new Date(month) : new Date();
  const startOfMonth = new Date(targetDate.getFullYear(), targetDate.getMonth(), 1);
  const endOfMonth = new Date(targetDate.getFullYear(), targetDate.getMonth() + 1, 0, 23, 59, 59);

  // Get household settings for funding amount
  const settings = await this.prisma.householdSettings.findUnique({
    where: { householdId },
  });

  // Get all active bills with payments
  const bills = await this.prisma.bill.findMany({
    where: { householdId, status: 'ACTIVE' },
    include: {
      vendor: true,
      paymentHistory: {
        where: {
          paidDate: {
            gte: startOfMonth,
            lte: endOfMonth,
          },
        },
      },
    },
  });

  // Group by category
  const byCategory = bills.reduce((acc, bill) => {
    const cat = bill.category;
    if (!acc[cat]) acc[cat] = [];
    acc[cat].push(bill);
    return acc;
  }, {} as Record<string, typeof bills>);

  const categories = Object.entries(byCategory).map(([category, categoryBills]) => {
    const totalPaid = categoryBills.reduce((sum, b) => 
      sum + b.paymentHistory.reduce((s, p) => s + p.amount, 0), 0);
    
    return {
      category,
      label: this.formatCategory(category),
      icon: this.getCategoryIcon(category),
      billCount: categoryBills.length,
      totalPaid,
      bills: categoryBills.map(bill => ({
        id: bill.id,
        name: bill.name,
        amount: bill.amount,
        frequency: bill.frequency,
        dueDay: bill.dueDay,
        isPaid: bill.paymentHistory.length > 0,
        paidDate: bill.paymentHistory[0]?.paidDate,
        paidAmount: bill.paymentHistory[0]?.amount,
        vendorName: bill.vendor?.name,
      })),
    };
  });

  // Get vendors
  const vendors = await this.prisma.vendor.findMany({
    where: { householdId, bills: { some: {} } },
    select: { id: true, name: true, category: true },
  });

  const totalPaid = categories.reduce((sum, c) => sum + c.totalPaid, 0);
  const paidCount = bills.filter(b => b.paymentHistory.length > 0).length;

  return {
    month: startOfMonth.toISOString(),
    monthlyFunding: settings?.monthlyFunding || 0,
    totalPaid,
    billsPaidCount: paidCount,
    totalBillsCount: bills.length,
    bufferRemaining: (settings?.monthlyFunding || 0) - totalPaid,
    categories: categories.sort((a, b) => b.totalPaid - a.totalPaid),
    vendors,
  };
}

private formatCategory(cat: string): string {
  const map: Record<string, string> = {
    'MORTGAGE': 'Housing',
    'RENT': 'Housing',
    'PROPERTY_TAX': 'Housing',
    'HOME_INSURANCE': 'Housing',
    'HOA': 'Housing',
    'ELECTRIC': 'Utilities',
    'GAS': 'Utilities',
    'WATER_SEWER': 'Utilities',
    'OIL_PROPANE': 'Utilities',
    'TRASH': 'Utilities',
    'INTERNET': 'Telecom',
    'CABLE_TV': 'Telecom',
    'CELL_PHONE': 'Telecom',
    'CAR_PAYMENT': 'Vehicles',
    'AUTO_INSURANCE': 'Vehicles',
    'SCHOOL_TUITION': 'Family',
    'CHILDCARE': 'Family',
    'KIDS_ACTIVITY': 'Family',
  };
  return map[cat] || cat.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, l => l.toUpperCase());
}

private getCategoryIcon(cat: string): string {
  const map: Record<string, string> = {
    'MORTGAGE': '🏠', 'RENT': '🏠', 'PROPERTY_TAX': '🏠', 'HOME_INSURANCE': '🏠', 'HOA': '🏠',
    'ELECTRIC': '⚡', 'GAS': '🔥', 'WATER_SEWER': '💧', 'OIL_PROPANE': '🛢️', 'TRASH': '🗑️',
    'INTERNET': '📶', 'CABLE_TV': '📺', 'CELL_PHONE': '📱',
    'CAR_PAYMENT': '🚗', 'AUTO_INSURANCE': '🚗',
    'SCHOOL_TUITION': '🎓', 'CHILDCARE': '👶', 'KIDS_ACTIVITY': '⚽',
  };
  return map[cat] || '💳';
}
```

### Task 4.2: Create Money Page

Create `apps/web/src/app/app/money/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { ChevronLeft, ChevronRight, Download, FileText } from 'lucide-react';

interface BillsSummary {
  month: string;
  monthlyFunding: number;
  totalPaid: number;
  billsPaidCount: number;
  totalBillsCount: number;
  bufferRemaining: number;
  categories: Array<{
    category: string;
    label: string;
    icon: string;
    billCount: number;
    totalPaid: number;
    bills: Array<{
      id: string;
      name: string;
      amount: number;
      isPaid: boolean;
      paidDate?: string;
      paidAmount?: number;
      vendorName?: string;
      dueDay?: number;
    }>;
  }>;
  vendors: Array<{ id: string; name: string }>;
}

function formatMonth(date: Date): string {
  return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
}

function getOrdinal(n: number): string {
  const s = ['th', 'st', 'nd', 'rd'];
  const v = n % 100;
  return s[(v - 20) % 10] || s[v] || s[0];
}

export default function MoneyPage() {
  const { user } = useAuth();
  const [data, setData] = useState<BillsSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedMonth, setSelectedMonth] = useState(new Date());
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set());

  useEffect(() => {
    fetchBills();
  }, [selectedMonth]);

  const fetchBills = async () => {
    try {
      const token = await user?.getIdToken();
      const monthStr = selectedMonth.toISOString().slice(0, 7);
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/bills/household/${user?.householdId}/summary?month=${monthStr}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setData(await response.json());
      }
    } catch (error) {
      console.error('Failed to load bills:', error);
    } finally {
      setLoading(false);
    }
  };

  const changeMonth = (delta: number) => {
    const newDate = new Date(selectedMonth);
    newDate.setMonth(newDate.getMonth() + delta);
    setSelectedMonth(newDate);
  };

  const toggleCategory = (category: string) => {
    const newSet = new Set(expandedCategories);
    if (newSet.has(category)) {
      newSet.delete(category);
    } else {
      newSet.add(category);
    }
    setExpandedCategories(newSet);
  };

  if (loading) {
    return (
      <div className="p-6 max-w-4xl mx-auto animate-pulse">
        <div className="h-48 bg-gray-200 rounded-2xl mb-6" />
        <div className="space-y-4">
          {[1,2,3].map(i => <div key={i} className="h-24 bg-gray-200 rounded-xl" />)}
        </div>
      </div>
    );
  }

  if (!data) {
    return <div className="p-6 text-center text-gray-500">No billing data available</div>;
  }

  const progressPercent = data.monthlyFunding > 0 
    ? Math.min((data.totalPaid / data.monthlyFunding) * 100, 100) 
    : 0;

  return (
    <div className="p-6 max-w-4xl mx-auto">
      {/* Header with Month Selector */}
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-haven-navy-900">
          💳 {formatMonth(selectedMonth)}
        </h1>
        <div className="flex items-center gap-2">
          <button 
            onClick={() => changeMonth(-1)}
            className="p-2 hover:bg-gray-100 rounded-lg transition"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button 
            onClick={() => changeMonth(1)}
            className="p-2 hover:bg-gray-100 rounded-lg transition"
            disabled={selectedMonth >= new Date()}
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Summary Card */}
      <div className="bg-gradient-to-br from-haven-navy-900 to-haven-navy-800 rounded-2xl p-6 text-white mb-6">
        <div className="grid grid-cols-2 gap-6 mb-4">
          <div>
            <div className="text-haven-champagne-300 text-sm mb-1">Haven Funding</div>
            <div className="text-3xl font-bold">${data.monthlyFunding.toLocaleString()}</div>
          </div>
          <div>
            <div className="text-haven-champagne-300 text-sm mb-1">Bills Paid</div>
            <div className="text-3xl font-bold">${data.totalPaid.toLocaleString()}</div>
          </div>
        </div>
        
        {/* Progress Bar */}
        <div>
          <div className="flex justify-between text-sm text-haven-champagne-300 mb-1">
            <span>{data.billsPaidCount} of {data.totalBillsCount} bills paid</span>
            <span>${data.bufferRemaining.toFixed(0)} buffer</span>
          </div>
          <div className="w-full bg-haven-navy-700 rounded-full h-3">
            <div 
              className="bg-haven-champagne-500 h-3 rounded-full transition-all"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        </div>
      </div>

      {/* Bills by Category */}
      <div className="space-y-3 mb-8">
        {data.categories.map((category) => (
          <div key={category.category} className="bg-white rounded-xl border border-gray-100 overflow-hidden">
            <button
              onClick={() => toggleCategory(category.category)}
              className="w-full p-4 flex items-center justify-between hover:bg-gray-50 transition"
            >
              <div className="flex items-center gap-3">
                <span className="text-xl">{category.icon}</span>
                <span className="font-medium text-haven-navy-900">{category.label}</span>
                <span className="text-sm text-gray-400">({category.billCount})</span>
              </div>
              <div className="flex items-center gap-3">
                <span className="font-semibold text-haven-navy-900">
                  ${category.totalPaid.toLocaleString()}
                </span>
                <ChevronRight className={`w-5 h-5 text-gray-400 transition-transform ${
                  expandedCategories.has(category.category) ? 'rotate-90' : ''
                }`} />
              </div>
            </button>
            
            {expandedCategories.has(category.category) && (
              <div className="border-t border-gray-100 divide-y divide-gray-50">
                {category.bills.map((bill) => (
                  <div key={bill.id} className="px-4 py-3 flex items-center justify-between">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{bill.name}</div>
                      {bill.vendorName && (
                        <div className="text-xs text-gray-400">{bill.vendorName}</div>
                      )}
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-medium">
                        ${(bill.paidAmount || bill.amount).toLocaleString()}
                      </div>
                      {bill.isPaid ? (
                        <div className="text-xs text-green-600">
                          ✓ Paid {bill.paidDate ? new Date(bill.paidDate).toLocaleDateString() : ''}
                        </div>
                      ) : (
                        <div className="text-xs text-gray-400">
                          Due {bill.dueDay ? `on the ${bill.dueDay}${getOrdinal(bill.dueDay)}` : 'soon'}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Vendors */}
      <div className="mb-8">
        <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">
          Your Vendors
        </h2>
        <div className="flex flex-wrap gap-2">
          {data.vendors.map((vendor) => (
            <Link
              key={vendor.id}
              href={`/app/vendors/${vendor.id}`}
              className="px-3 py-1.5 bg-gray-100 rounded-full text-sm text-gray-700 hover:bg-haven-champagne-100 transition"
            >
              {vendor.name}
            </Link>
          ))}
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-3">
        <button className="flex-1 py-3 border border-gray-200 rounded-xl text-gray-600 hover:bg-gray-50 transition flex items-center justify-center gap-2">
          <FileText className="w-4 h-4" />
          Annual Summary
        </button>
        <button className="flex-1 py-3 border border-gray-200 rounded-xl text-gray-600 hover:bg-gray-50 transition flex items-center justify-center gap-2">
          <Download className="w-4 h-4" />
          Download Statements
        </button>
      </div>
    </div>
  );
}
```

---

## PHASE 5: Family Page

### Task 5.1: Create Family API

Add to `apps/api/src/family/family.controller.ts`:

```typescript
@Get('household/:householdId')
@UseGuards(FirebaseAuthGuard)
async getFamily(@Param('householdId') householdId: string) {
  const [members, vehicles] = await Promise.all([
    this.prisma.familyMember.findMany({
      where: { householdId },
      include: { activities: true },
      orderBy: [{ type: 'asc' }, { createdAt: 'asc' }],
    }),
    this.prisma.vehicle.findMany({
      where: { householdId },
    }),
  ]);

  const adults = members.filter(m => m.type === 'ADULT');
  const children = members.filter(m => m.type === 'CHILD');
  const pets = members.filter(m => m.type === 'PET');
  const staff = members.filter(m => m.type === 'STAFF');

  const calculateAge = (dob?: Date) => {
    if (!dob) return null;
    const today = new Date();
    const birthDate = new Date(dob);
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
  };

  return {
    adults: adults.map(a => ({
      id: a.id,
      firstName: a.firstName,
      lastName: a.lastName,
      role: a.role,
      email: a.email,
      phone: a.phone,
    })),
    children: children.map(c => ({
      id: c.id,
      firstName: c.firstName,
      age: calculateAge(c.dateOfBirth),
      grade: c.grade,
      school: c.school,
      allergies: c.allergies,
      activities: c.activities.map(a => ({
        id: a.id,
        name: a.name,
        schedule: a.schedule,
        cost: a.cost,
      })),
    })),
    pets: pets.map(p => ({
      id: p.id,
      name: p.firstName,
      type: p.role,
      notes: p.medicalNotes,
    })),
    staff: staff.map(s => ({
      id: s.id,
      firstName: s.firstName,
      lastName: s.lastName,
      role: s.role,
      phone: s.phone,
      schedule: s.employer, // Reusing field
    })),
    vehicles: vehicles.map(v => ({
      id: v.id,
      name: `${v.year} ${v.make} ${v.model}`,
      color: v.color,
      licensePlate: v.licensePlate,
      primaryDriver: v.primaryDriver,
      hasPayment: !!v.loanPayment,
    })),
  };
}
```

### Task 5.2: Create Family Page

Create `apps/web/src/app/app/family/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/auth-context';

interface FamilyData {
  adults: Array<{
    id: string;
    firstName: string;
    lastName?: string;
    role?: string;
    email?: string;
    phone?: string;
  }>;
  children: Array<{
    id: string;
    firstName: string;
    age?: number;
    grade?: string;
    school?: string;
    allergies?: string[];
    activities: Array<{ id: string; name: string; schedule?: string }>;
  }>;
  pets: Array<{
    id: string;
    name: string;
    type?: string;
    notes?: string;
  }>;
  staff: Array<{
    id: string;
    firstName: string;
    lastName?: string;
    role?: string;
    phone?: string;
    schedule?: string;
  }>;
  vehicles: Array<{
    id: string;
    name: string;
    color?: string;
    licensePlate?: string;
    primaryDriver?: string;
    hasPayment: boolean;
  }>;
}

function formatPhone(phone?: string): string {
  if (!phone) return '';
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.length === 10) {
    return `(${cleaned.slice(0,3)}) ${cleaned.slice(3,6)}-${cleaned.slice(6)}`;
  }
  return phone;
}

export default function FamilyPage() {
  const { user } = useAuth();
  const [data, setData] = useState<FamilyData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchFamily();
  }, []);

  const fetchFamily = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/family/household/${user?.householdId}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setData(await response.json());
      }
    } catch (error) {
      console.error('Failed to load family:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="p-6 max-w-4xl mx-auto animate-pulse">
        <div className="h-8 bg-gray-200 rounded w-48 mb-6" />
        <div className="grid grid-cols-2 gap-4 mb-8">
          {[1,2].map(i => <div key={i} className="h-32 bg-gray-200 rounded-xl" />)}
        </div>
      </div>
    );
  }

  if (!data) {
    return <div className="p-6 text-center text-gray-500">Family data not available</div>;
  }

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold text-haven-navy-900 mb-6">
        👨‍👩‍👧‍👦 Your Family
      </h1>

      {/* Adults */}
      {data.adults.length > 0 && (
        <section className="mb-8">
          <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">Adults</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {data.adults.map((adult) => (
              <div key={adult.id} className="bg-white rounded-xl p-4 border border-gray-100">
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-12 h-12 bg-haven-champagne-100 rounded-full flex items-center justify-center text-xl">
                    👤
                  </div>
                  <div>
                    <div className="font-medium text-haven-navy-900">
                      {adult.firstName} {adult.lastName}
                    </div>
                    {adult.role && <div className="text-sm text-gray-500">{adult.role}</div>}
                  </div>
                </div>
                <div className="space-y-1 text-sm text-gray-600">
                  {adult.phone && <div>📱 {formatPhone(adult.phone)}</div>}
                  {adult.email && <div>✉️ {adult.email}</div>}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Children */}
      {data.children.length > 0 && (
        <section className="mb-8">
          <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">Children</h2>
          <div className="space-y-4">
            {data.children.map((child) => (
              <div key={child.id} className="bg-white rounded-xl p-4 border border-gray-100">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-xl">
                      {(child.age || 0) < 10 ? '👦' : '👧'}
                    </div>
                    <div>
                      <div className="font-medium text-haven-navy-900">
                        {child.firstName} {child.age ? `(${child.age})` : ''}
                      </div>
                      <div className="text-sm text-gray-500">
                        {[child.grade, child.school].filter(Boolean).join(' • ')}
                      </div>
                    </div>
                  </div>
                  {child.allergies && child.allergies.length > 0 && (
                    <div className="px-2 py-1 bg-red-100 text-red-700 text-xs rounded-full">
                      ⚠️ Allergies
                    </div>
                  )}
                </div>
                
                {child.allergies && child.allergies.length > 0 && (
                  <div className="mb-3 p-2 bg-red-50 rounded-lg text-sm text-red-700">
                    Allergies: {child.allergies.join(', ')}
                  </div>
                )}

                {child.activities.length > 0 && (
                  <div>
                    <div className="text-xs font-medium text-gray-500 mb-2">ACTIVITIES</div>
                    <div className="flex flex-wrap gap-2">
                      {child.activities.map((activity) => (
                        <span 
                          key={activity.id}
                          className="px-3 py-1 bg-gray-100 rounded-full text-sm"
                        >
                          {activity.name}
                          {activity.schedule && (
                            <span className="text-gray-400 ml-1">({activity.schedule})</span>
                          )}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Pets */}
      {data.pets.length > 0 && (
        <section className="mb-8">
          <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">Pets</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {data.pets.map((pet) => (
              <div key={pet.id} className="bg-white rounded-xl p-4 border border-gray-100 flex items-center gap-3">
                <div className="text-3xl">🐕</div>
                <div>
                  <div className="font-medium text-haven-navy-900">{pet.name}</div>
                  {pet.type && <div className="text-sm text-gray-500">{pet.type}</div>}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Staff */}
      {data.staff.length > 0 && (
        <section className="mb-8">
          <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">Household Staff</h2>
          <div className="space-y-3">
            {data.staff.map((person) => (
              <div key={person.id} className="bg-white rounded-xl p-4 border border-gray-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                    👩
                  </div>
                  <div>
                    <div className="font-medium text-haven-navy-900">
                      {person.firstName} {person.lastName}
                    </div>
                    {person.role && <div className="text-sm text-gray-500">{person.role}</div>}
                  </div>
                </div>
                {person.schedule && (
                  <div className="text-sm text-gray-500">{person.schedule}</div>
                )}
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Vehicles */}
      {data.vehicles.length > 0 && (
        <section>
          <h2 className="text-lg font-semibold text-haven-navy-900 mb-4">Vehicles</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {data.vehicles.map((vehicle) => (
              <div key={vehicle.id} className="bg-white rounded-xl p-4 border border-gray-100">
                <div className="flex items-center gap-3">
                  <div className="text-2xl">🚗</div>
                  <div>
                    <div className="font-medium text-haven-navy-900">{vehicle.name}</div>
                    <div className="text-sm text-gray-500">
                      {vehicle.primaryDriver && `${vehicle.primaryDriver}'s car`}
                      {vehicle.licensePlate && ` • ${vehicle.licensePlate}`}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
```

---

## PHASE 6: Build and Deploy

### Task 6.1: Run Database Migration

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name add_activity_log_and_portal_enhancements
```

### Task 6.2: Build the Project

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

### Task 6.3: Commit and Push

```bash
git add .
git commit -m "Production-ready homeowner portal with full data display"
git push origin main
```

### Task 6.4: Deploy to Production

```bash
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## Testing Checklist

After deployment, verify each page shows real data from onboarding:

### Dashboard
- [ ] Correct greeting with user's first name
- [ ] Property address displayed
- [ ] Home Health Score shows
- [ ] This month billing shows real numbers
- [ ] Bills paid count is accurate
- [ ] Next service shows if scheduled
- [ ] Pending approvals count is correct
- [ ] Recent activity shows Home Manager actions
- [ ] Upcoming items are populated

### Your Home
- [ ] Property name/address from onboarding
- [ ] Bed/bath/sqft from ATTOM enrichment
- [ ] Systems overview shows all captured systems
- [ ] All zones from intake are visible
- [ ] Zone cards show correct asset counts
- [ ] Clicking zone shows assets
- [ ] Asset details show brand, model, condition
- [ ] Service history is visible

### Sarah (HM Hub)
- [ ] Home Manager profile displayed
- [ ] Pending approvals listed with details
- [ ] Can approve/deny actions
- [ ] Recent updates from HM visible
- [ ] Can send message to HM

### Money
- [ ] Monthly funding amount is correct
- [ ] Total bills paid is accurate
- [ ] Progress bar shows correct percentage
- [ ] All bill categories displayed
- [ ] Expanding category shows individual bills
- [ ] Payment status (paid/due) is accurate
- [ ] Paid dates are correct
- [ ] Vendors list populated

### Family
- [ ] All adults displayed with roles
- [ ] Children show ages, schools
- [ ] Children's allergies highlighted
- [ ] Activities listed per child
- [ ] Pets displayed with types
- [ ] Staff shown with schedules
- [ ] Vehicles displayed
- [ ] Primary drivers assigned

### Calendar
- [ ] Service appointments visible
- [ ] Bill due dates shown
- [ ] Family activities displayed
- [ ] Can navigate months
- [ ] Day view shows details

---

## Success Metrics

**Technical Success:**
- All API endpoints return real data
- No 500 errors in production logs
- Page load times < 2 seconds
- Mobile responsive on all pages

**User Experience Success:**
- Homeowner sees their actual home data
- Data matches what Home Manager entered
- No "mock" or placeholder content visible
- Activity feed shows real HM actions

**Business Success:**
- Homeowner feels "wow, they know everything"
- No repeat information requests
- Trust established immediately
- Value demonstrated on first login
