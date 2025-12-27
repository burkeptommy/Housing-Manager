# Haven Home Manager Intake Workbench

**Created:** December 26, 2024  
**Purpose:** Build the interface where Home Managers capture all household data during onboarding calls  
**Priority:** Critical - This is the data entry point for the entire system

---

## Goal

Create the Home Manager's intake workbench - the tool Sarah uses during the intro call to capture everything about a household. This is zone-based (like Nines Living), with smart suggestions based on ATTOM property data, and captures all bills/accounts needed for Haven's bill consolidation.

Without this tool, no data enters the system. The homeowner portal will be empty.

---

## Context

When a homeowner signs up:
1. They enter address, select tier, pay
2. They see "Sarah will call within 24 hours"
3. Sarah sees them in her queue
4. Sarah calls, uses THIS WORKBENCH to capture everything
5. Data flows to homeowner portal

---

## PHASE 1: Onboarding Queue & Dashboard

### Task 1.1: Create Onboarding Models

Add to `apps/api/prisma/schema.prisma`:

```prisma
model OnboardingSession {
  id              String            @id @default(cuid())
  householdId     String            @unique
  household       Household         @relation(fields: [householdId], references: [id])
  
  // Assignment
  assignedManagerId String?
  assignedManager   User?           @relation("AssignedManager", fields: [assignedManagerId], references: [id])
  
  // Status tracking
  status          OnboardingStatus  @default(PENDING_CALL)
  
  // User's initial input
  biggestChallenge String?
  selectedTier     String?
  
  // Scheduling
  callScheduledFor DateTime?
  callStartedAt    DateTime?
  callCompletedAt  DateTime?
  
  // Progress (percentage complete per section)
  progressFamily      Int @default(0)
  progressProperty    Int @default(0)
  progressZones       Int @default(0)
  progressSystems     Int @default(0)
  progressVendors     Int @default(0)
  progressBills       Int @default(0)
  
  // Captured data (JSON for flexibility during intake)
  intakeData       Json?
  
  // Calculated outputs
  monthlyFundingEstimate Float?
  
  // Notes
  callNotes        String?
  followUpNeeded   Boolean @default(false)
  followUpNotes    String?
  
  // Milestones
  profileDeliveredAt DateTime?
  firstBillPaidAt    DateTime?
  
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt
}

enum OnboardingStatus {
  PENDING_CALL      // Just signed up, waiting for call
  CALL_SCHEDULED    // Call scheduled
  CALL_IN_PROGRESS  // Currently on the phone
  INTAKE_PARTIAL    // Call done but need follow-up
  INTAKE_COMPLETE   // All data captured
  PROFILE_BUILDING  // Manager finalizing profile
  PROFILE_DELIVERED // Sent welcome email to homeowner
  ACTIVE            // Fully onboarded, normal operations
}
```

### Task 1.2: Run Migration

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name add_onboarding_session
```

### Task 1.3: Create Onboarding Queue API

Create `apps/api/src/manager/onboarding/onboarding.controller.ts`:

```typescript
import { Controller, Get, Post, Put, Param, Body, UseGuards, Query } from '@nestjs/common';
import { FirebaseAuthGuard } from '../../auth/firebase-auth.guard';
import { RolesGuard, Roles } from '../../auth/roles.guard';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('manager/onboarding')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles('HOME_MANAGER', 'ADMIN')
export class OnboardingController {
  constructor(private prisma: PrismaService) {}

  // Get queue of households pending onboarding
  @Get('queue')
  async getQueue(@Query('status') status?: string) {
    const where = status ? { status: status as any } : {
      status: { in: ['PENDING_CALL', 'CALL_SCHEDULED', 'INTAKE_PARTIAL'] }
    };

    const sessions = await this.prisma.onboardingSession.findMany({
      where,
      include: {
        household: {
          include: {
            property: true,
            users: { where: { role: 'HOMEOWNER' }, take: 1 },
          },
        },
        assignedManager: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    return sessions.map(s => ({
      id: s.id,
      householdId: s.householdId,
      status: s.status,
      homeownerName: s.household.users[0]?.name || 'Unknown',
      homeownerEmail: s.household.users[0]?.email,
      homeownerPhone: s.household.users[0]?.phone,
      propertyAddress: s.household.property?.street 
        ? `${s.household.property.street}, ${s.household.property.city}, ${s.household.property.state}`
        : 'No address',
      biggestChallenge: s.biggestChallenge,
      selectedTier: s.selectedTier,
      callScheduledFor: s.callScheduledFor,
      assignedManager: s.assignedManager?.name,
      progress: this.calculateOverallProgress(s),
      enrichmentHighlights: this.getEnrichmentHighlights(s.household.property?.enrichmentData),
      createdAt: s.createdAt,
    }));
  }

  // Get single session with full details for intake
  @Get(':id')
  async getSession(@Param('id') id: string) {
    const session = await this.prisma.onboardingSession.findUnique({
      where: { id },
      include: {
        household: {
          include: {
            property: true,
            users: true,
            zones: { include: { assets: true } },
            familyMembers: { include: { activities: true } },
            vehicles: true,
            vendors: true,
            bills: true,
          },
        },
      },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    return {
      session: {
        id: session.id,
        status: session.status,
        biggestChallenge: session.biggestChallenge,
        selectedTier: session.selectedTier,
        progress: {
          family: session.progressFamily,
          property: session.progressProperty,
          zones: session.progressZones,
          systems: session.progressSystems,
          vendors: session.progressVendors,
          bills: session.progressBills,
          overall: this.calculateOverallProgress(session),
        },
        intakeData: session.intakeData || {},
        monthlyFundingEstimate: session.monthlyFundingEstimate,
        callNotes: session.callNotes,
      },
      household: session.household,
      property: session.household.property,
      enrichment: session.household.property?.enrichmentData,
      existingData: {
        zones: session.household.zones,
        familyMembers: session.household.familyMembers,
        vehicles: session.household.vehicles,
        vendors: session.household.vendors,
        bills: session.household.bills,
      },
    };
  }

  // Update intake progress
  @Put(':id/intake')
  async updateIntake(
    @Param('id') id: string,
    @Body() body: {
      section: string;
      data: any;
      progress?: number;
    }
  ) {
    const session = await this.prisma.onboardingSession.findUnique({
      where: { id },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    // Merge new data with existing
    const existingData = (session.intakeData as any) || {};
    const updatedData = {
      ...existingData,
      [body.section]: {
        ...existingData[body.section],
        ...body.data,
        lastUpdated: new Date().toISOString(),
      },
    };

    // Update progress for section
    const progressField = `progress${body.section.charAt(0).toUpperCase() + body.section.slice(1)}`;
    const updateData: any = {
      intakeData: updatedData,
      status: 'CALL_IN_PROGRESS',
    };

    if (body.progress !== undefined && progressField in session) {
      updateData[progressField] = body.progress;
    }

    return this.prisma.onboardingSession.update({
      where: { id },
      data: updateData,
    });
  }

  // Start call
  @Post(':id/start-call')
  async startCall(@Param('id') id: string) {
    return this.prisma.onboardingSession.update({
      where: { id },
      data: {
        status: 'CALL_IN_PROGRESS',
        callStartedAt: new Date(),
      },
    });
  }

  // Complete intake
  @Post(':id/complete')
  async completeIntake(
    @Param('id') id: string,
    @Body() body: { callNotes?: string; followUpNeeded?: boolean; followUpNotes?: string }
  ) {
    const session = await this.prisma.onboardingSession.findUnique({
      where: { id },
      include: { household: true },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    // Process intake data into actual records
    await this.processIntakeData(session);

    // Calculate monthly funding
    const monthlyFunding = await this.calculateMonthlyFunding(session.householdId);

    return this.prisma.onboardingSession.update({
      where: { id },
      data: {
        status: body.followUpNeeded ? 'INTAKE_PARTIAL' : 'INTAKE_COMPLETE',
        callCompletedAt: new Date(),
        callNotes: body.callNotes,
        followUpNeeded: body.followUpNeeded || false,
        followUpNotes: body.followUpNotes,
        monthlyFundingEstimate: monthlyFunding,
        progressFamily: 100,
        progressProperty: 100,
        progressZones: 100,
        progressSystems: 100,
        progressVendors: 100,
        progressBills: 100,
      },
    });
  }

  // Deliver profile to homeowner
  @Post(':id/deliver-profile')
  async deliverProfile(@Param('id') id: string) {
    // TODO: Send welcome email with profile summary
    
    return this.prisma.onboardingSession.update({
      where: { id },
      data: {
        status: 'PROFILE_DELIVERED',
        profileDeliveredAt: new Date(),
      },
    });
  }

  private calculateOverallProgress(session: any): number {
    const weights = {
      family: 15,
      property: 10,
      zones: 20,
      systems: 15,
      vendors: 15,
      bills: 25,
    };

    const weighted = 
      (session.progressFamily * weights.family +
       session.progressProperty * weights.property +
       session.progressZones * weights.zones +
       session.progressSystems * weights.systems +
       session.progressVendors * weights.vendors +
       session.progressBills * weights.bills) / 100;

    return Math.round(weighted);
  }

  private getEnrichmentHighlights(enrichment: any): string[] {
    if (!enrichment) return [];
    
    const highlights: string[] = [];
    
    if (enrichment.heatingFuel?.toLowerCase().includes('oil')) {
      highlights.push('Oil heat');
    }
    if (enrichment.fireplaces > 0) {
      highlights.push(`${enrichment.fireplaces} fireplace${enrichment.fireplaces > 1 ? 's' : ''}`);
    }
    if (enrichment.pool) {
      highlights.push('Pool');
    }
    if (enrichment.sewerType?.toLowerCase().includes('septic')) {
      highlights.push('Septic');
    }
    if (enrichment.waterType?.toLowerCase().includes('well')) {
      highlights.push('Well water');
    }
    
    return highlights;
  }

  private async processIntakeData(session: any) {
    const data = session.intakeData || {};
    const householdId = session.householdId;

    // Process each section and create records
    // This converts the flexible JSON intake data into proper database records

    // Family members
    if (data.family?.members) {
      for (const member of data.family.members) {
        await this.prisma.familyMember.create({
          data: {
            householdId,
            type: member.type,
            firstName: member.firstName,
            lastName: member.lastName,
            email: member.email,
            phone: member.phone,
            role: member.role,
            dateOfBirth: member.dateOfBirth ? new Date(member.dateOfBirth) : null,
            school: member.school,
            grade: member.grade,
            allergies: member.allergies || [],
            medicalNotes: member.medicalNotes,
          },
        });
      }
    }

    // Zones and assets
    if (data.zones) {
      for (const zone of Object.values(data.zones) as any[]) {
        const createdZone = await this.prisma.zone.create({
          data: {
            propertyId: session.household.property.id,
            name: zone.name,
            type: zone.type,
            floor: zone.floor,
          },
        });

        if (zone.assets) {
          for (const asset of zone.assets) {
            await this.prisma.asset.create({
              data: {
                zoneId: createdZone.id,
                propertyId: session.household.property.id,
                name: asset.name,
                category: asset.category,
                brand: asset.brand,
                model: asset.model,
                serialNumber: asset.serialNumber,
                condition: asset.condition,
                purchaseDate: asset.purchaseDate ? new Date(asset.purchaseDate) : null,
                warrantyExpires: asset.warrantyExpires ? new Date(asset.warrantyExpires) : null,
              },
            });
          }
        }
      }
    }

    // Vendors
    if (data.vendors) {
      for (const vendor of Object.values(data.vendors) as any[]) {
        await this.prisma.vendor.create({
          data: {
            householdId,
            category: vendor.category,
            name: vendor.name,
            contactName: vendor.contactName,
            phone: vendor.phone,
            email: vendor.email,
            accountNumber: vendor.accountNumber,
            notes: vendor.notes,
          },
        });
      }
    }

    // Bills
    if (data.bills) {
      for (const bill of Object.values(data.bills) as any[]) {
        await this.prisma.bill.create({
          data: {
            householdId,
            category: bill.category,
            name: bill.name,
            payeeName: bill.payeeName,
            accountNumber: bill.accountNumber,
            amount: parseFloat(bill.amount) || 0,
            frequency: bill.frequency || 'MONTHLY',
            dueDay: bill.dueDay ? parseInt(bill.dueDay) : null,
            isLoan: bill.isLoan || false,
            principalBalance: bill.principalBalance ? parseFloat(bill.principalBalance) : null,
            interestRate: bill.interestRate ? parseFloat(bill.interestRate) : null,
            portalUrl: bill.portalUrl,
            status: 'ACTIVE',
          },
        });
      }
    }

    // Vehicles
    if (data.vehicles) {
      for (const vehicle of Object.values(data.vehicles) as any[]) {
        await this.prisma.vehicle.create({
          data: {
            householdId,
            year: vehicle.year ? parseInt(vehicle.year) : null,
            make: vehicle.make,
            model: vehicle.model,
            color: vehicle.color,
            licensePlate: vehicle.licensePlate,
            primaryDriver: vehicle.primaryDriver,
            loanPayment: vehicle.loanPayment ? parseFloat(vehicle.loanPayment) : null,
          },
        });
      }
    }
  }

  private async calculateMonthlyFunding(householdId: string): Promise<number> {
    const bills = await this.prisma.bill.findMany({
      where: { householdId, status: 'ACTIVE' },
    });

    let monthly = 0;

    for (const bill of bills) {
      const amount = bill.amount || 0;
      switch (bill.frequency) {
        case 'WEEKLY': monthly += amount * 4.33; break;
        case 'BIWEEKLY': monthly += amount * 2.17; break;
        case 'TWICE_MONTHLY': monthly += amount * 2; break;
        case 'MONTHLY': monthly += amount; break;
        case 'QUARTERLY': monthly += amount / 3; break;
        case 'SEMI_ANNUAL': monthly += amount / 6; break;
        case 'ANNUAL': monthly += amount / 12; break;
        default: monthly += amount;
      }
    }

    // Add 10% buffer
    monthly *= 1.10;

    return Math.round(monthly * 100) / 100;
  }
}
```

### Task 1.4: Create Module

Create `apps/api/src/manager/onboarding/onboarding.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { OnboardingController } from './onboarding.controller';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [OnboardingController],
})
export class ManagerOnboardingModule {}
```

Register in `apps/api/src/app.module.ts`.

---

## PHASE 2: Manager Queue UI

### Task 2.1: Create Queue Page

Create `apps/web/src/app/manager/onboarding/page.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { 
  Phone, Clock, AlertCircle, CheckCircle, 
  ChevronRight, User, Home, Calendar
} from 'lucide-react';

interface QueueItem {
  id: string;
  householdId: string;
  status: string;
  homeownerName: string;
  homeownerEmail: string;
  homeownerPhone: string;
  propertyAddress: string;
  biggestChallenge: string;
  selectedTier: string;
  callScheduledFor: string | null;
  assignedManager: string | null;
  progress: number;
  enrichmentHighlights: string[];
  createdAt: string;
}

const statusConfig: Record<string, { label: string; color: string; icon: any }> = {
  PENDING_CALL: { label: 'Needs Call', color: 'orange', icon: Phone },
  CALL_SCHEDULED: { label: 'Scheduled', color: 'blue', icon: Calendar },
  CALL_IN_PROGRESS: { label: 'On Call', color: 'green', icon: Phone },
  INTAKE_PARTIAL: { label: 'Follow-up Needed', color: 'yellow', icon: AlertCircle },
  INTAKE_COMPLETE: { label: 'Complete', color: 'green', icon: CheckCircle },
};

const challengeLabels: Record<string, string> = {
  bills: '💳 Bills & Payments',
  maintenance: '🔧 Home Maintenance',
  vendors: '👷 Vendor Coordination',
  family: '👨‍👩‍👧‍👦 Family Logistics',
  everything: '🌟 Everything',
};

export default function OnboardingQueuePage() {
  const { user } = useAuth();
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>('active');

  useEffect(() => {
    fetchQueue();
  }, [filter]);

  const fetchQueue = async () => {
    try {
      const token = await user?.getIdToken();
      const statusParam = filter === 'active' ? '' : `?status=${filter}`;
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/manager/onboarding/queue${statusParam}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        setQueue(await response.json());
      }
    } catch (error) {
      console.error('Failed to load queue:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const config = statusConfig[status] || { label: status, color: 'gray', icon: Clock };
    const Icon = config.icon;
    
    return (
      <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium
        ${config.color === 'orange' ? 'bg-orange-100 text-orange-700' : ''}
        ${config.color === 'blue' ? 'bg-blue-100 text-blue-700' : ''}
        ${config.color === 'green' ? 'bg-green-100 text-green-700' : ''}
        ${config.color === 'yellow' ? 'bg-yellow-100 text-yellow-700' : ''}
        ${config.color === 'gray' ? 'bg-gray-100 text-gray-700' : ''}
      `}>
        <Icon className="w-3 h-3" />
        {config.label}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="p-6 animate-pulse">
        <div className="h-8 bg-gray-200 rounded w-48 mb-6" />
        {[1,2,3].map(i => <div key={i} className="h-24 bg-gray-200 rounded-xl mb-4" />)}
      </div>
    );
  }

  return (
    <div className="p-6 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-haven-navy-900">
            Onboarding Queue
          </h1>
          <p className="text-gray-500">
            {queue.length} household{queue.length !== 1 ? 's' : ''} waiting
          </p>
        </div>
        
        {/* Filter */}
        <div className="flex gap-2">
          {['active', 'PENDING_CALL', 'INTAKE_PARTIAL', 'INTAKE_COMPLETE'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1.5 rounded-lg text-sm transition ${
                filter === f 
                  ? 'bg-haven-navy-900 text-white' 
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {f === 'active' ? 'Active' : statusConfig[f]?.label || f}
            </button>
          ))}
        </div>
      </div>

      {/* Queue List */}
      <div className="space-y-4">
        {queue.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            No households in queue
          </div>
        ) : (
          queue.map((item) => (
            <Link
              key={item.id}
              href={`/manager/onboarding/${item.id}`}
              className="block bg-white rounded-xl border border-gray-100 p-5 hover:shadow-md transition"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  {/* Header Row */}
                  <div className="flex items-center gap-3 mb-2">
                    <div className="w-10 h-10 bg-haven-champagne-100 rounded-full flex items-center justify-center">
                      <User className="w-5 h-5 text-haven-champagne-600" />
                    </div>
                    <div>
                      <div className="font-semibold text-haven-navy-900">
                        {item.homeownerName}
                      </div>
                      <div className="text-sm text-gray-500">
                        {item.homeownerEmail} • {item.homeownerPhone}
                      </div>
                    </div>
                    {getStatusBadge(item.status)}
                  </div>

                  {/* Property */}
                  <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
                    <Home className="w-4 h-4" />
                    {item.propertyAddress}
                  </div>

                  {/* Details Row */}
                  <div className="flex items-center gap-4 text-sm">
                    {item.biggestChallenge && (
                      <span className="text-gray-500">
                        {challengeLabels[item.biggestChallenge] || item.biggestChallenge}
                      </span>
                    )}
                    {item.selectedTier && (
                      <span className="px-2 py-0.5 bg-haven-champagne-100 text-haven-champagne-700 rounded">
                        {item.selectedTier}
                      </span>
                    )}
                    {item.enrichmentHighlights.length > 0 && (
                      <span className="text-gray-400">
                        {item.enrichmentHighlights.join(' • ')}
                      </span>
                    )}
                  </div>

                  {/* Progress Bar */}
                  {item.progress > 0 && (
                    <div className="mt-3">
                      <div className="flex justify-between text-xs text-gray-500 mb-1">
                        <span>Intake Progress</span>
                        <span>{item.progress}%</span>
                      </div>
                      <div className="w-full bg-gray-100 rounded-full h-1.5">
                        <div 
                          className="bg-haven-champagne-500 h-1.5 rounded-full transition-all"
                          style={{ width: `${item.progress}%` }}
                        />
                      </div>
                    </div>
                  )}
                </div>

                <ChevronRight className="w-5 h-5 text-gray-300" />
              </div>
            </Link>
          ))
        )}
      </div>
    </div>
  );
}
```

---

## PHASE 3: Intake Workbench UI

### Task 3.1: Create Intake Sections Configuration

Create `apps/web/src/app/manager/onboarding/intake-sections.ts`:

```typescript
export interface IntakeQuestion {
  id: string;
  question: string;
  type: 'text' | 'number' | 'currency' | 'phone' | 'email' | 'date' | 'select' | 'yesno' | 'textarea' | 'repeater';
  options?: string[];
  placeholder?: string;
  required?: boolean;
  helpText?: string;
  conditionalOn?: { field: string; value: any };
  fields?: IntakeQuestion[]; // For repeater type
}

export interface IntakeSection {
  id: string;
  title: string;
  icon: string;
  description: string;
  questions: IntakeQuestion[];
  contextFromEnrichment?: (enrichment: any) => string | null;
}

export const intakeSections: IntakeSection[] = [
  {
    id: 'quickStart',
    title: 'Quick Start',
    icon: '🎯',
    description: 'Confirm pain points and set expectations',
    questions: [
      {
        id: 'confirmedChallenge',
        question: 'Confirm their biggest challenge',
        type: 'select',
        options: ['Bills & Payments', 'Home Maintenance', 'Vendor Coordination', 'Family Logistics', 'All of the above'],
      },
      {
        id: 'urgentIssues',
        question: 'Any urgent issues to address first?',
        type: 'textarea',
        placeholder: 'Leaking pipe, overdue bill, etc.',
      },
      {
        id: 'expectations',
        question: 'What would success look like in 30 days?',
        type: 'textarea',
      },
    ],
  },
  {
    id: 'family',
    title: 'Family & Household',
    icon: '👨‍👩‍👧‍👦',
    description: 'Adults, children, pets, staff',
    questions: [
      {
        id: 'adults',
        question: 'Adults in household',
        type: 'repeater',
        fields: [
          { id: 'firstName', question: 'First Name', type: 'text', required: true },
          { id: 'lastName', question: 'Last Name', type: 'text' },
          { id: 'role', question: 'Role', type: 'select', options: ['Head of Household', 'Spouse/Partner', 'Parent', 'Other'] },
          { id: 'email', question: 'Email', type: 'email' },
          { id: 'phone', question: 'Phone', type: 'phone' },
          { id: 'employer', question: 'Employer', type: 'text' },
        ],
      },
      {
        id: 'hasKids',
        question: 'Any children in the household?',
        type: 'yesno',
      },
      {
        id: 'children',
        question: 'Children',
        type: 'repeater',
        conditionalOn: { field: 'hasKids', value: true },
        fields: [
          { id: 'firstName', question: 'First Name', type: 'text', required: true },
          { id: 'age', question: 'Age', type: 'number' },
          { id: 'school', question: 'School', type: 'text' },
          { id: 'grade', question: 'Grade', type: 'text' },
          { id: 'allergies', question: 'Allergies', type: 'text', placeholder: 'Separate with commas' },
        ],
      },
      {
        id: 'hasPets',
        question: 'Any pets?',
        type: 'yesno',
      },
      {
        id: 'pets',
        question: 'Pets',
        type: 'repeater',
        conditionalOn: { field: 'hasPets', value: true },
        fields: [
          { id: 'name', question: 'Name', type: 'text', required: true },
          { id: 'type', question: 'Type/Breed', type: 'text', placeholder: 'Golden Retriever, Tabby Cat, etc.' },
          { id: 'vetName', question: 'Vet Name', type: 'text' },
          { id: 'vetPhone', question: 'Vet Phone', type: 'phone' },
        ],
      },
      {
        id: 'hasStaff',
        question: 'Any household staff (nanny, housekeeper, etc.)?',
        type: 'yesno',
      },
      {
        id: 'staff',
        question: 'Household Staff',
        type: 'repeater',
        conditionalOn: { field: 'hasStaff', value: true },
        fields: [
          { id: 'firstName', question: 'Name', type: 'text', required: true },
          { id: 'role', question: 'Role', type: 'text', placeholder: 'Nanny, Housekeeper, etc.' },
          { id: 'phone', question: 'Phone', type: 'phone' },
          { id: 'schedule', question: 'Schedule', type: 'text', placeholder: 'Mon-Fri 8am-5pm' },
          { id: 'weeklyPay', question: 'Weekly Pay', type: 'currency' },
        ],
      },
    ],
  },
  {
    id: 'zones',
    title: 'Home Zones',
    icon: '🏠',
    description: 'Kitchen, laundry, garage, etc.',
    questions: [
      {
        id: 'kitchen',
        question: 'Kitchen Appliances',
        type: 'repeater',
        helpText: 'Capture brand, model, age for each major appliance',
        fields: [
          { id: 'name', question: 'Appliance', type: 'select', options: ['Refrigerator', 'Dishwasher', 'Oven/Range', 'Microwave', 'Garbage Disposal', 'Wine Fridge', 'Ice Maker', 'Other'] },
          { id: 'brand', question: 'Brand', type: 'text' },
          { id: 'model', question: 'Model', type: 'text' },
          { id: 'age', question: 'Age (years)', type: 'number' },
          { id: 'condition', question: 'Condition', type: 'select', options: ['Excellent', 'Good', 'Fair', 'Poor'] },
          { id: 'issues', question: 'Any issues?', type: 'text' },
        ],
      },
      {
        id: 'laundry',
        question: 'Laundry',
        type: 'repeater',
        fields: [
          { id: 'name', question: 'Appliance', type: 'select', options: ['Washer', 'Dryer', 'Other'] },
          { id: 'brand', question: 'Brand', type: 'text' },
          { id: 'dryerType', question: 'Dryer Type', type: 'select', options: ['Gas', 'Electric'], conditionalOn: { field: 'name', value: 'Dryer' } },
          { id: 'lastVentCleaning', question: 'Last vent cleaning?', type: 'date' },
        ],
      },
      {
        id: 'garage',
        question: 'Garage',
        type: 'repeater',
        fields: [
          { id: 'hasOpener', question: 'Garage door opener?', type: 'yesno' },
          { id: 'openerBrand', question: 'Brand', type: 'text', conditionalOn: { field: 'hasOpener', value: true } },
          { id: 'evCharger', question: 'EV Charger?', type: 'yesno' },
        ],
      },
    ],
  },
  {
    id: 'systems',
    title: 'Home Systems',
    icon: '⚙️',
    description: 'HVAC, plumbing, electrical',
    contextFromEnrichment: (e) => {
      if (!e) return null;
      const items = [];
      if (e.heatingFuel) items.push(`Heat: ${e.heatingFuel}`);
      if (e.fireplaces) items.push(`${e.fireplaces} fireplace(s)`);
      if (e.sewerType) items.push(`Sewer: ${e.sewerType}`);
      if (e.waterType) items.push(`Water: ${e.waterType}`);
      return items.length ? `ATTOM shows: ${items.join(' • ')}` : null;
    },
    questions: [
      {
        id: 'hvacBrand',
        question: 'HVAC System Brand',
        type: 'text',
      },
      {
        id: 'hvacAge',
        question: 'HVAC Age (years)',
        type: 'number',
      },
      {
        id: 'hvacVendor',
        question: 'Who services your HVAC?',
        type: 'text',
        helpText: 'We\'ll add them to your vendors',
      },
      {
        id: 'hvacLastService',
        question: 'Last HVAC service date',
        type: 'date',
      },
      {
        id: 'heatingFuel',
        question: 'Heating fuel type',
        type: 'select',
        options: ['Natural Gas', 'Oil', 'Propane', 'Electric', 'Heat Pump'],
      },
      {
        id: 'oilVendor',
        question: 'Oil delivery company',
        type: 'text',
        conditionalOn: { field: 'heatingFuel', value: 'Oil' },
      },
      {
        id: 'propaneVendor',
        question: 'Propane delivery company',
        type: 'text',
        conditionalOn: { field: 'heatingFuel', value: 'Propane' },
      },
      {
        id: 'waterHeaterType',
        question: 'Water heater type',
        type: 'select',
        options: ['Tank (Gas)', 'Tank (Electric)', 'Tankless (Gas)', 'Tankless (Electric)'],
      },
      {
        id: 'waterHeaterAge',
        question: 'Water heater age (years)',
        type: 'number',
      },
      {
        id: 'hasFireplaces',
        question: 'Do you have fireplaces?',
        type: 'yesno',
      },
      {
        id: 'chimneyVendor',
        question: 'Chimney sweep company',
        type: 'text',
        conditionalOn: { field: 'hasFireplaces', value: true },
        helpText: 'Annual cleaning recommended',
      },
      {
        id: 'hasSeptic',
        question: 'Septic system?',
        type: 'yesno',
      },
      {
        id: 'septicVendor',
        question: 'Septic service company',
        type: 'text',
        conditionalOn: { field: 'hasSeptic', value: true },
      },
      {
        id: 'septicLastPumped',
        question: 'Last pumped date',
        type: 'date',
        conditionalOn: { field: 'hasSeptic', value: true },
        helpText: 'Recommended every 3-5 years',
      },
      {
        id: 'hasWell',
        question: 'Well water?',
        type: 'yesno',
      },
      {
        id: 'wellVendor',
        question: 'Well service company',
        type: 'text',
        conditionalOn: { field: 'hasWell', value: true },
      },
      {
        id: 'hasGenerator',
        question: 'Generator?',
        type: 'yesno',
      },
      {
        id: 'generatorBrand',
        question: 'Generator brand',
        type: 'text',
        conditionalOn: { field: 'hasGenerator', value: true },
      },
      {
        id: 'hasSecuritySystem',
        question: 'Security system?',
        type: 'yesno',
      },
      {
        id: 'securityVendor',
        question: 'Security company',
        type: 'text',
        conditionalOn: { field: 'hasSecuritySystem', value: true },
      },
    ],
  },
  {
    id: 'exterior',
    title: 'Exterior & Grounds',
    icon: '🏡',
    description: 'Lawn, pool, roof, gutters',
    questions: [
      {
        id: 'hasLawnService',
        question: 'Lawn/landscape service?',
        type: 'yesno',
      },
      {
        id: 'lawnVendor',
        question: 'Lawn service company',
        type: 'text',
        conditionalOn: { field: 'hasLawnService', value: true },
      },
      {
        id: 'lawnCost',
        question: 'Monthly lawn cost',
        type: 'currency',
        conditionalOn: { field: 'hasLawnService', value: true },
      },
      {
        id: 'hasPool',
        question: 'Pool?',
        type: 'yesno',
      },
      {
        id: 'poolVendor',
        question: 'Pool service company',
        type: 'text',
        conditionalOn: { field: 'hasPool', value: true },
      },
      {
        id: 'poolCost',
        question: 'Monthly pool cost',
        type: 'currency',
        conditionalOn: { field: 'hasPool', value: true },
      },
      {
        id: 'hasSnowRemoval',
        question: 'Snow removal service?',
        type: 'yesno',
      },
      {
        id: 'snowVendor',
        question: 'Snow removal company',
        type: 'text',
        conditionalOn: { field: 'hasSnowRemoval', value: true },
      },
      {
        id: 'roofAge',
        question: 'Roof age (years)',
        type: 'number',
      },
      {
        id: 'rooferVendor',
        question: 'Roofer (if known)',
        type: 'text',
      },
      {
        id: 'gutterVendor',
        question: 'Gutter cleaning company',
        type: 'text',
      },
      {
        id: 'pestVendor',
        question: 'Pest control company',
        type: 'text',
      },
    ],
  },
  {
    id: 'vehicles',
    title: 'Vehicles',
    icon: '🚗',
    description: 'Cars, payments, insurance',
    questions: [
      {
        id: 'vehicles',
        question: 'Vehicles',
        type: 'repeater',
        fields: [
          { id: 'year', question: 'Year', type: 'number' },
          { id: 'make', question: 'Make', type: 'text', placeholder: 'Toyota, Honda, Tesla...' },
          { id: 'model', question: 'Model', type: 'text' },
          { id: 'color', question: 'Color', type: 'text' },
          { id: 'licensePlate', question: 'License Plate', type: 'text' },
          { id: 'primaryDriver', question: 'Primary Driver', type: 'text' },
          { id: 'hasPayment', question: 'Has car payment?', type: 'yesno' },
          { id: 'paymentLender', question: 'Lender', type: 'text', conditionalOn: { field: 'hasPayment', value: true } },
          { id: 'paymentAmount', question: 'Monthly Payment', type: 'currency', conditionalOn: { field: 'hasPayment', value: true } },
          { id: 'paymentAccount', question: 'Account #', type: 'text', conditionalOn: { field: 'hasPayment', value: true } },
        ],
      },
      {
        id: 'autoInsurance',
        question: 'Auto Insurance Provider',
        type: 'text',
      },
      {
        id: 'autoInsurancePolicy',
        question: 'Policy Number',
        type: 'text',
      },
      {
        id: 'autoInsuranceCost',
        question: 'Premium (monthly or 6-mo)',
        type: 'currency',
      },
      {
        id: 'autoInsuranceFrequency',
        question: 'Payment Frequency',
        type: 'select',
        options: ['Monthly', 'Semi-Annual', 'Annual'],
      },
    ],
  },
  {
    id: 'bills',
    title: 'Bills & Accounts',
    icon: '💳',
    description: 'All recurring payments',
    questions: [
      // Housing
      {
        id: 'mortgageLender',
        question: 'Mortgage Lender',
        type: 'text',
        placeholder: 'Chase, Wells Fargo, etc.',
      },
      {
        id: 'mortgageAccount',
        question: 'Mortgage Account #',
        type: 'text',
      },
      {
        id: 'mortgagePayment',
        question: 'Monthly Payment',
        type: 'currency',
      },
      {
        id: 'mortgageDueDay',
        question: 'Due Date (day of month)',
        type: 'number',
      },
      {
        id: 'mortgageEscrow',
        question: 'Includes escrow (taxes/insurance)?',
        type: 'yesno',
      },
      {
        id: 'homeInsuranceProvider',
        question: 'Home Insurance Provider',
        type: 'text',
        conditionalOn: { field: 'mortgageEscrow', value: false },
      },
      {
        id: 'homeInsurancePolicy',
        question: 'Policy Number',
        type: 'text',
        conditionalOn: { field: 'mortgageEscrow', value: false },
      },
      {
        id: 'homeInsuranceAnnual',
        question: 'Annual Premium',
        type: 'currency',
        conditionalOn: { field: 'mortgageEscrow', value: false },
      },
      {
        id: 'hasHoa',
        question: 'HOA?',
        type: 'yesno',
      },
      {
        id: 'hoaAmount',
        question: 'HOA Amount',
        type: 'currency',
        conditionalOn: { field: 'hasHoa', value: true },
      },
      {
        id: 'hoaFrequency',
        question: 'HOA Frequency',
        type: 'select',
        options: ['Monthly', 'Quarterly', 'Annual'],
        conditionalOn: { field: 'hasHoa', value: true },
      },
      // Utilities
      {
        id: 'electricProvider',
        question: 'Electric Provider',
        type: 'text',
      },
      {
        id: 'electricAccount',
        question: 'Electric Account #',
        type: 'text',
      },
      {
        id: 'electricAvgBill',
        question: 'Average Monthly Bill',
        type: 'currency',
      },
      {
        id: 'hasGas',
        question: 'Natural gas service?',
        type: 'yesno',
      },
      {
        id: 'gasProvider',
        question: 'Gas Provider',
        type: 'text',
        conditionalOn: { field: 'hasGas', value: true },
      },
      {
        id: 'gasAccount',
        question: 'Gas Account #',
        type: 'text',
        conditionalOn: { field: 'hasGas', value: true },
      },
      {
        id: 'waterProvider',
        question: 'Water/Sewer Provider',
        type: 'text',
      },
      {
        id: 'waterAccount',
        question: 'Water Account #',
        type: 'text',
      },
      // Telecom
      {
        id: 'internetProvider',
        question: 'Internet Provider',
        type: 'text',
      },
      {
        id: 'internetAccount',
        question: 'Internet Account #',
        type: 'text',
      },
      {
        id: 'internetCost',
        question: 'Monthly Cost',
        type: 'currency',
      },
      {
        id: 'cellProvider',
        question: 'Cell Phone Provider',
        type: 'text',
      },
      {
        id: 'cellAccount',
        question: 'Cell Account #',
        type: 'text',
      },
      {
        id: 'cellCost',
        question: 'Monthly Cost',
        type: 'currency',
      },
      // Kids
      {
        id: 'hasSchoolTuition',
        question: 'Any school tuition payments?',
        type: 'yesno',
      },
      {
        id: 'schoolTuitions',
        question: 'School Tuitions',
        type: 'repeater',
        conditionalOn: { field: 'hasSchoolTuition', value: true },
        fields: [
          { id: 'school', question: 'School Name', type: 'text' },
          { id: 'student', question: 'Student Name', type: 'text' },
          { id: 'amount', question: 'Amount', type: 'currency' },
          { id: 'frequency', question: 'Frequency', type: 'select', options: ['Monthly', 'Quarterly', 'Semi-Annual', 'Annual'] },
        ],
      },
      {
        id: 'kidsActivities',
        question: 'Kids Activities (with costs)',
        type: 'repeater',
        fields: [
          { id: 'activity', question: 'Activity', type: 'text', placeholder: 'Soccer, Piano, etc.' },
          { id: 'child', question: 'Which child?', type: 'text' },
          { id: 'cost', question: 'Cost', type: 'currency' },
          { id: 'frequency', question: 'Frequency', type: 'select', options: ['Weekly', 'Monthly', 'Quarterly', 'Per Season'] },
        ],
      },
      // Loans
      {
        id: 'hasStudentLoans',
        question: 'Student loan payments?',
        type: 'yesno',
      },
      {
        id: 'studentLoans',
        question: 'Student Loans',
        type: 'repeater',
        conditionalOn: { field: 'hasStudentLoans', value: true },
        fields: [
          { id: 'servicer', question: 'Servicer', type: 'text' },
          { id: 'account', question: 'Account #', type: 'text' },
          { id: 'payment', question: 'Monthly Payment', type: 'currency' },
          { id: 'balance', question: 'Balance', type: 'currency' },
        ],
      },
      // Insurance
      {
        id: 'hasLifeInsurance',
        question: 'Life insurance?',
        type: 'yesno',
      },
      {
        id: 'lifeInsuranceProvider',
        question: 'Life Insurance Provider',
        type: 'text',
        conditionalOn: { field: 'hasLifeInsurance', value: true },
      },
      {
        id: 'lifeInsuranceCost',
        question: 'Annual Premium',
        type: 'currency',
        conditionalOn: { field: 'hasLifeInsurance', value: true },
      },
      {
        id: 'hasUmbrella',
        question: 'Umbrella insurance?',
        type: 'yesno',
      },
      {
        id: 'umbrellaCost',
        question: 'Annual Premium',
        type: 'currency',
        conditionalOn: { field: 'hasUmbrella', value: true },
      },
      // Subscriptions
      {
        id: 'subscriptions',
        question: 'Streaming/Subscriptions',
        type: 'repeater',
        helpText: 'Netflix, Spotify, gym, etc.',
        fields: [
          { id: 'name', question: 'Service', type: 'text' },
          { id: 'cost', question: 'Monthly Cost', type: 'currency' },
        ],
      },
      // Other
      {
        id: 'otherBills',
        question: 'Other Recurring Bills',
        type: 'repeater',
        helpText: 'Anything we missed',
        fields: [
          { id: 'name', question: 'What is it?', type: 'text' },
          { id: 'payee', question: 'Who do you pay?', type: 'text' },
          { id: 'account', question: 'Account #', type: 'text' },
          { id: 'amount', question: 'Amount', type: 'currency' },
          { id: 'frequency', question: 'Frequency', type: 'select', options: ['Weekly', 'Monthly', 'Quarterly', 'Annual'] },
        ],
      },
    ],
  },
];
```

### Task 3.2: Create Intake Workbench Page

Create `apps/web/src/app/manager/onboarding/[sessionId]/page.tsx`:

```typescript
'use client';

import { useEffect, useState, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { 
  Phone, Save, CheckCircle, ChevronDown, ChevronRight,
  ArrowLeft, AlertCircle, Calculator
} from 'lucide-react';
import { intakeSections, IntakeSection, IntakeQuestion } from '../intake-sections';

interface SessionData {
  session: {
    id: string;
    status: string;
    biggestChallenge: string;
    selectedTier: string;
    progress: Record<string, number>;
    intakeData: Record<string, any>;
    monthlyFundingEstimate: number | null;
  };
  household: any;
  property: any;
  enrichment: any;
}

export default function IntakeWorkbenchPage() {
  const params = useParams();
  const router = useRouter();
  const { user } = useAuth();
  
  const [data, setData] = useState<SessionData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set(['quickStart']));
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [monthlyEstimate, setMonthlyEstimate] = useState<number | null>(null);

  useEffect(() => {
    fetchSession();
  }, [params.sessionId]);

  const fetchSession = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/manager/onboarding/${params.sessionId}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (response.ok) {
        const result = await response.json();
        setData(result);
        setFormData(result.session.intakeData || {});
        setMonthlyEstimate(result.session.monthlyFundingEstimate);
      }
    } catch (error) {
      console.error('Failed to load session:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveSection = useCallback(async (sectionId: string) => {
    if (!data) return;
    
    setSaving(true);
    try {
      const token = await user?.getIdToken();
      await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/manager/onboarding/${params.sessionId}/intake`,
        {
          method: 'PUT',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            section: sectionId,
            data: formData[sectionId] || {},
            progress: calculateSectionProgress(sectionId),
          }),
        }
      );
    } catch (error) {
      console.error('Failed to save:', error);
    } finally {
      setSaving(false);
    }
  }, [data, formData, params.sessionId, user]);

  const startCall = async () => {
    const token = await user?.getIdToken();
    await fetch(
      `${process.env.NEXT_PUBLIC_API_URL}/manager/onboarding/${params.sessionId}/start-call`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      }
    );
    fetchSession();
  };

  const completeIntake = async () => {
    const token = await user?.getIdToken();
    await fetch(
      `${process.env.NEXT_PUBLIC_API_URL}/manager/onboarding/${params.sessionId}/complete`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          callNotes: formData.callNotes,
          followUpNeeded: false,
        }),
      }
    );
    router.push('/manager/onboarding');
  };

  const calculateSectionProgress = (sectionId: string): number => {
    const section = intakeSections.find(s => s.id === sectionId);
    if (!section) return 0;
    
    const sectionData = formData[sectionId] || {};
    const requiredFields = section.questions.filter(q => q.required);
    if (requiredFields.length === 0) return 100;
    
    const filledRequired = requiredFields.filter(q => sectionData[q.id]).length;
    return Math.round((filledRequired / requiredFields.length) * 100);
  };

  const calculateMonthlyFunding = (): number => {
    let total = 0;
    const billsData = formData.bills || {};
    
    // Add mortgage
    if (billsData.mortgagePayment) {
      total += parseFloat(billsData.mortgagePayment) || 0;
    }
    
    // Add utilities
    if (billsData.electricAvgBill) total += parseFloat(billsData.electricAvgBill) || 0;
    if (billsData.internetCost) total += parseFloat(billsData.internetCost) || 0;
    if (billsData.cellCost) total += parseFloat(billsData.cellCost) || 0;
    
    // Add car payments from vehicles section
    const vehiclesData = formData.vehicles || {};
    if (vehiclesData.vehicles) {
      for (const v of vehiclesData.vehicles) {
        if (v.paymentAmount) total += parseFloat(v.paymentAmount) || 0;
      }
    }
    
    // Add insurance (convert annual to monthly)
    if (vehiclesData.autoInsuranceCost) {
      const freq = vehiclesData.autoInsuranceFrequency;
      const cost = parseFloat(vehiclesData.autoInsuranceCost) || 0;
      if (freq === 'Annual') total += cost / 12;
      else if (freq === 'Semi-Annual') total += cost / 6;
      else total += cost;
    }
    
    // Add tuitions
    if (billsData.schoolTuitions) {
      for (const t of billsData.schoolTuitions) {
        const amt = parseFloat(t.amount) || 0;
        if (t.frequency === 'Monthly') total += amt;
        else if (t.frequency === 'Quarterly') total += amt / 3;
        else if (t.frequency === 'Annual') total += amt / 12;
      }
    }
    
    // Add activities
    if (billsData.kidsActivities) {
      for (const a of billsData.kidsActivities) {
        const amt = parseFloat(a.cost) || 0;
        if (a.frequency === 'Weekly') total += amt * 4.33;
        else if (a.frequency === 'Monthly') total += amt;
        else if (a.frequency === 'Quarterly') total += amt / 3;
      }
    }
    
    // Add student loans
    if (billsData.studentLoans) {
      for (const l of billsData.studentLoans) {
        total += parseFloat(l.payment) || 0;
      }
    }
    
    // Add subscriptions
    if (billsData.subscriptions) {
      for (const s of billsData.subscriptions) {
        total += parseFloat(s.cost) || 0;
      }
    }
    
    // Add other bills
    if (billsData.otherBills) {
      for (const b of billsData.otherBills) {
        const amt = parseFloat(b.amount) || 0;
        if (b.frequency === 'Weekly') total += amt * 4.33;
        else if (b.frequency === 'Monthly') total += amt;
        else if (b.frequency === 'Quarterly') total += amt / 3;
        else if (b.frequency === 'Annual') total += amt / 12;
      }
    }
    
    // Add 10% buffer
    total *= 1.10;
    
    return Math.round(total * 100) / 100;
  };

  const updateField = (sectionId: string, fieldId: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [sectionId]: {
        ...prev[sectionId],
        [fieldId]: value,
      },
    }));
  };

  const toggleSection = (sectionId: string) => {
    const newSet = new Set(expandedSections);
    if (newSet.has(sectionId)) {
      newSet.delete(sectionId);
    } else {
      newSet.add(sectionId);
    }
    setExpandedSections(newSet);
  };

  if (loading) {
    return <div className="p-6 animate-pulse"><div className="h-96 bg-gray-200 rounded-xl" /></div>;
  }

  if (!data) {
    return <div className="p-6 text-center text-gray-500">Session not found</div>;
  }

  const homeowner = data.household.users?.[0];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sticky Header */}
      <div className="sticky top-0 z-10 bg-white border-b border-gray-200 shadow-sm">
        <div className="max-w-6xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button 
                onClick={() => router.push('/manager/onboarding')}
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <ArrowLeft className="w-5 h-5" />
              </button>
              <div>
                <h1 className="text-xl font-bold text-haven-navy-900">
                  {homeowner?.name || 'Unknown'}
                </h1>
                <p className="text-sm text-gray-500">
                  {data.property?.street}, {data.property?.city}
                </p>
              </div>
            </div>
            
            <div className="flex items-center gap-3">
              {data.session.status === 'PENDING_CALL' && (
                <button
                  onClick={startCall}
                  className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                >
                  <Phone className="w-4 h-4" />
                  Start Call
                </button>
              )}
              
              <button
                onClick={() => {
                  for (const section of intakeSections) {
                    saveSection(section.id);
                  }
                }}
                disabled={saving}
                className="flex items-center gap-2 px-4 py-2 bg-haven-navy-900 text-white rounded-lg hover:bg-haven-navy-800 transition disabled:opacity-50"
              >
                <Save className="w-4 h-4" />
                {saving ? 'Saving...' : 'Save Progress'}
              </button>
              
              <button
                onClick={completeIntake}
                className="flex items-center gap-2 px-4 py-2 bg-haven-champagne-500 text-haven-navy-900 rounded-lg hover:bg-haven-champagne-400 transition"
              >
                <CheckCircle className="w-4 h-4" />
                Complete
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-6 py-6">
        <div className="grid grid-cols-3 gap-6">
          {/* Left Column - Sections */}
          <div className="col-span-2 space-y-4">
            {/* ATTOM Context Banner */}
            {data.enrichment && (
              <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
                <div className="flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5" />
                  <div>
                    <div className="font-medium text-blue-900">Property Insights (ATTOM)</div>
                    <div className="text-sm text-blue-700 mt-1">
                      {data.enrichment.bedrooms} bed • {data.enrichment.bathrooms} bath • {data.enrichment.squareFeet?.toLocaleString()} sqft
                      {data.enrichment.heatingFuel && ` • ${data.enrichment.heatingFuel} heat`}
                      {data.enrichment.fireplaces > 0 && ` • ${data.enrichment.fireplaces} fireplace(s)`}
                      {data.enrichment.pool && ' • Pool'}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Intake Sections */}
            {intakeSections.map((section) => (
              <div key={section.id} className="bg-white rounded-xl border border-gray-200 overflow-hidden">
                <button
                  onClick={() => toggleSection(section.id)}
                  className="w-full px-5 py-4 flex items-center justify-between hover:bg-gray-50 transition"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">{section.icon}</span>
                    <div className="text-left">
                      <div className="font-semibold text-haven-navy-900">{section.title}</div>
                      <div className="text-sm text-gray-500">{section.description}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="text-sm text-gray-400">
                      {calculateSectionProgress(section.id)}%
                    </div>
                    {expandedSections.has(section.id) ? (
                      <ChevronDown className="w-5 h-5 text-gray-400" />
                    ) : (
                      <ChevronRight className="w-5 h-5 text-gray-400" />
                    )}
                  </div>
                </button>
                
                {expandedSections.has(section.id) && (
                  <div className="px-5 pb-5 border-t border-gray-100">
                    {/* Context from enrichment */}
                    {section.contextFromEnrichment && (
                      <div className="mt-4 p-3 bg-yellow-50 rounded-lg text-sm text-yellow-800">
                        💡 {section.contextFromEnrichment(data.enrichment)}
                      </div>
                    )}
                    
                    {/* Questions */}
                    <div className="mt-4 space-y-4">
                      {section.questions.map((question) => (
                        <QuestionField
                          key={question.id}
                          question={question}
                          value={formData[section.id]?.[question.id]}
                          onChange={(value) => updateField(section.id, question.id, value)}
                          sectionData={formData[section.id] || {}}
                        />
                      ))}
                    </div>
                    
                    {/* Save section button */}
                    <div className="mt-4 pt-4 border-t border-gray-100">
                      <button
                        onClick={() => saveSection(section.id)}
                        className="text-sm text-haven-champagne-600 hover:underline"
                      >
                        Save {section.title}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Right Column - Summary */}
          <div className="space-y-4">
            {/* Progress */}
            <div className="bg-white rounded-xl border border-gray-200 p-5">
              <h3 className="font-semibold text-haven-navy-900 mb-4">Progress</h3>
              <div className="space-y-3">
                {intakeSections.map((section) => (
                  <div key={section.id}>
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-gray-600">{section.title}</span>
                      <span className="text-gray-400">{calculateSectionProgress(section.id)}%</span>
                    </div>
                    <div className="w-full bg-gray-100 rounded-full h-1.5">
                      <div 
                        className="bg-haven-champagne-500 h-1.5 rounded-full transition-all"
                        style={{ width: `${calculateSectionProgress(section.id)}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Monthly Funding Calculator */}
            <div className="bg-haven-navy-900 rounded-xl p-5 text-white">
              <div className="flex items-center gap-2 mb-4">
                <Calculator className="w-5 h-5 text-haven-champagne-300" />
                <h3 className="font-semibold">Monthly Haven Funding</h3>
              </div>
              <div className="text-3xl font-bold mb-2">
                ${calculateMonthlyFunding().toLocaleString()}
              </div>
              <p className="text-sm text-haven-champagne-300">
                Includes 10% buffer for variable bills
              </p>
              <button
                onClick={() => setMonthlyEstimate(calculateMonthlyFunding())}
                className="mt-4 w-full py-2 bg-haven-champagne-500 text-haven-navy-900 rounded-lg text-sm font-medium hover:bg-haven-champagne-400 transition"
              >
                Lock in Estimate
              </button>
            </div>

            {/* Homeowner Info */}
            <div className="bg-white rounded-xl border border-gray-200 p-5">
              <h3 className="font-semibold text-haven-navy-900 mb-4">Contact</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">Name</span>
                  <span className="font-medium">{homeowner?.name}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Email</span>
                  <span className="font-medium">{homeowner?.email}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Phone</span>
                  <span className="font-medium">{homeowner?.phone}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Tier</span>
                  <span className="font-medium">{data.session.selectedTier}</span>
                </div>
              </div>
            </div>

            {/* Call Notes */}
            <div className="bg-white rounded-xl border border-gray-200 p-5">
              <h3 className="font-semibold text-haven-navy-900 mb-4">Call Notes</h3>
              <textarea
                value={formData.callNotes || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, callNotes: e.target.value }))}
                className="w-full h-32 p-3 border border-gray-200 rounded-lg text-sm resize-none focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
                placeholder="Notes from the call..."
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Question Field Component
function QuestionField({ 
  question, 
  value, 
  onChange, 
  sectionData 
}: { 
  question: IntakeQuestion; 
  value: any; 
  onChange: (value: any) => void;
  sectionData: Record<string, any>;
}) {
  // Check conditional
  if (question.conditionalOn) {
    const conditionMet = sectionData[question.conditionalOn.field] === question.conditionalOn.value;
    if (!conditionMet) return null;
  }

  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {question.question}
        {question.required && <span className="text-red-500 ml-1">*</span>}
      </label>
      
      {question.helpText && (
        <p className="text-xs text-gray-500 mb-2">{question.helpText}</p>
      )}
      
      {question.type === 'text' && (
        <input
          type="text"
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          placeholder={question.placeholder}
          className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
        />
      )}
      
      {question.type === 'number' && (
        <input
          type="number"
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
        />
      )}
      
      {question.type === 'currency' && (
        <div className="relative">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">$</span>
          <input
            type="number"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            className="w-full pl-7 pr-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
          />
        </div>
      )}
      
      {question.type === 'phone' && (
        <input
          type="tel"
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          placeholder="(555) 555-5555"
          className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
        />
      )}
      
      {question.type === 'email' && (
        <input
          type="email"
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
        />
      )}
      
      {question.type === 'date' && (
        <input
          type="date"
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
        />
      )}
      
      {question.type === 'select' && (
        <select
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
        >
          <option value="">Select...</option>
          {question.options?.map((opt) => (
            <option key={opt} value={opt}>{opt}</option>
          ))}
        </select>
      )}
      
      {question.type === 'yesno' && (
        <div className="flex gap-3">
          <button
            type="button"
            onClick={() => onChange(true)}
            className={`flex-1 py-2 rounded-lg border transition ${
              value === true 
                ? 'bg-haven-champagne-500 border-haven-champagne-500 text-haven-navy-900' 
                : 'border-gray-200 hover:bg-gray-50'
            }`}
          >
            Yes
          </button>
          <button
            type="button"
            onClick={() => onChange(false)}
            className={`flex-1 py-2 rounded-lg border transition ${
              value === false 
                ? 'bg-gray-200 border-gray-200' 
                : 'border-gray-200 hover:bg-gray-50'
            }`}
          >
            No
          </button>
        </div>
      )}
      
      {question.type === 'textarea' && (
        <textarea
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          placeholder={question.placeholder}
          className="w-full px-3 py-2 border border-gray-200 rounded-lg h-24 resize-none focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
        />
      )}
      
      {question.type === 'repeater' && (
        <RepeaterField
          fields={question.fields || []}
          value={value || []}
          onChange={onChange}
        />
      )}
    </div>
  );
}

// Repeater Field Component
function RepeaterField({
  fields,
  value,
  onChange,
}: {
  fields: IntakeQuestion[];
  value: any[];
  onChange: (value: any[]) => void;
}) {
  const addItem = () => {
    onChange([...value, {}]);
  };

  const removeItem = (index: number) => {
    onChange(value.filter((_, i) => i !== index));
  };

  const updateItem = (index: number, fieldId: string, fieldValue: any) => {
    const newValue = [...value];
    newValue[index] = { ...newValue[index], [fieldId]: fieldValue };
    onChange(newValue);
  };

  return (
    <div className="space-y-3">
      {value.map((item, index) => (
        <div key={index} className="p-4 bg-gray-50 rounded-lg relative">
          <button
            type="button"
            onClick={() => removeItem(index)}
            className="absolute top-2 right-2 text-gray-400 hover:text-red-500"
          >
            ×
          </button>
          <div className="grid grid-cols-2 gap-3">
            {fields.map((field) => (
              <div key={field.id} className={field.type === 'textarea' ? 'col-span-2' : ''}>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  {field.question}
                </label>
                {field.type === 'select' ? (
                  <select
                    value={item[field.id] || ''}
                    onChange={(e) => updateItem(index, field.id, e.target.value)}
                    className="w-full px-2 py-1.5 text-sm border border-gray-200 rounded focus:outline-none focus:ring-1 focus:ring-haven-champagne-500"
                  >
                    <option value="">Select...</option>
                    {field.options?.map((opt) => (
                      <option key={opt} value={opt}>{opt}</option>
                    ))}
                  </select>
                ) : field.type === 'yesno' ? (
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={() => updateItem(index, field.id, true)}
                      className={`flex-1 py-1 text-sm rounded border ${
                        item[field.id] === true ? 'bg-haven-champagne-500 border-haven-champagne-500' : 'border-gray-200'
                      }`}
                    >
                      Yes
                    </button>
                    <button
                      type="button"
                      onClick={() => updateItem(index, field.id, false)}
                      className={`flex-1 py-1 text-sm rounded border ${
                        item[field.id] === false ? 'bg-gray-200 border-gray-200' : 'border-gray-200'
                      }`}
                    >
                      No
                    </button>
                  </div>
                ) : field.type === 'currency' ? (
                  <div className="relative">
                    <span className="absolute left-2 top-1/2 -translate-y-1/2 text-gray-500 text-sm">$</span>
                    <input
                      type="number"
                      value={item[field.id] || ''}
                      onChange={(e) => updateItem(index, field.id, e.target.value)}
                      className="w-full pl-6 pr-2 py-1.5 text-sm border border-gray-200 rounded focus:outline-none focus:ring-1 focus:ring-haven-champagne-500"
                    />
                  </div>
                ) : (
                  <input
                    type={field.type === 'number' ? 'number' : field.type === 'date' ? 'date' : 'text'}
                    value={item[field.id] || ''}
                    onChange={(e) => updateItem(index, field.id, e.target.value)}
                    placeholder={field.placeholder}
                    className="w-full px-2 py-1.5 text-sm border border-gray-200 rounded focus:outline-none focus:ring-1 focus:ring-haven-champagne-500"
                  />
                )}
              </div>
            ))}
          </div>
        </div>
      ))}
      <button
        type="button"
        onClick={addItem}
        className="w-full py-2 border-2 border-dashed border-gray-200 rounded-lg text-sm text-gray-500 hover:border-haven-champagne-500 hover:text-haven-champagne-600 transition"
      >
        + Add Another
      </button>
    </div>
  );
}
```

---

## PHASE 4: Build and Deploy

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Run migrations
cd apps/api
pnpm prisma migrate dev --name add_onboarding_session

# Build
cd ../..
pnpm build

# Commit
git add .
git commit -m "Add Home Manager intake workbench for onboarding"
git push origin main

# Deploy
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## Testing Checklist

**Queue Page (/manager/onboarding):**
- [ ] Shows list of pending households
- [ ] Filter by status works
- [ ] Shows homeowner name, address
- [ ] Shows biggest challenge and tier
- [ ] Shows ATTOM highlights
- [ ] Progress bar displays
- [ ] Clicking opens workbench

**Intake Workbench (/manager/onboarding/[id]):**
- [ ] Loads household data
- [ ] Shows ATTOM context banner
- [ ] Sections expand/collapse
- [ ] All field types work (text, select, yesno, repeater, etc.)
- [ ] Conditional fields show/hide correctly
- [ ] Save progress works
- [ ] Progress calculation updates
- [ ] Monthly funding calculator works
- [ ] Complete button creates records
- [ ] Redirects back to queue

**Data Flow:**
- [ ] Intake data saves to OnboardingSession.intakeData
- [ ] Complete creates FamilyMember records
- [ ] Complete creates Zone records
- [ ] Complete creates Asset records
- [ ] Complete creates Vehicle records
- [ ] Complete creates Vendor records
- [ ] Complete creates Bill records
- [ ] Data appears in homeowner portal
