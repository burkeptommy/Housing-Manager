# Haven: Maintenance Calendar

**Created:** December 28, 2024  
**Purpose:** Auto-generate maintenance tasks from ATTOM property data  
**Priority:** P0 - Highest impact feature for instant value  
**Depends On:** 008 (Approval System) - should be complete

---

## CRITICAL RULES

1. **DO NOT DELETE existing code** - Only add and refactor
2. **Use existing ATTOM data** - Property enrichment already captured during onboarding
3. **Generate tasks automatically** - No user input required

---

## Overview

When a user signs up and we get their property data from ATTOM, we automatically generate a maintenance calendar based on:
- Property systems (HVAC type, pool, septic, etc.)
- Property age (roof, water heater estimates)
- Geographic location (seasonal needs)
- Best practices (filter changes, inspections)

**User Impact:** Immediately sees "12 maintenance tasks identified for your home" - instant proof Haven is proactive.

---

## PHASE 1: Database Schema

### Task 1.1: Create MaintenanceTask Model

Add to `apps/api/prisma/schema.prisma`:

```prisma
model MaintenanceTask {
  id              String              @id @default(uuid())
  householdId     String
  household       Household           @relation(fields: [householdId], references: [id])
  
  // Task details
  title           String
  description     String?
  category        MaintenanceCategory
  
  // Scheduling
  frequency       MaintenanceFrequency
  seasonalTiming  SeasonalTiming?
  
  // Due date tracking  
  nextDueDate     DateTime?
  lastCompletedDate DateTime?
  
  // Source
  source          TaskSource          @default(SYSTEM_GENERATED)
  sourceSystem    String?             // e.g., "HVAC", "Pool", "Roof"
  
  // Status
  status          MaintenanceStatus   @default(UPCOMING)
  
  // Assignment
  assignedVendorId String?
  assignedVendor   Vendor?            @relation(fields: [assignedVendorId], references: [id])
  estimatedCost    Float?
  
  // Completion
  completedById    String?
  completedBy      User?              @relation(fields: [completedById], references: [id])
  completedAt      DateTime?
  completionNotes  String?
  
  // Metadata
  isRecurring      Boolean            @default(true)
  priority         TaskPriority       @default(NORMAL)
  
  createdAt        DateTime           @default(now())
  updatedAt        DateTime           @updatedAt
  
  @@index([householdId])
  @@index([nextDueDate])
  @@index([status])
}

enum MaintenanceCategory {
  HVAC
  PLUMBING
  ELECTRICAL
  ROOFING
  EXTERIOR
  INTERIOR
  POOL
  LANDSCAPING
  APPLIANCES
  SAFETY
  SEASONAL
  OTHER
}

enum MaintenanceFrequency {
  MONTHLY
  QUARTERLY
  SEMI_ANNUAL
  ANNUAL
  BIENNIAL
  TRIENNIAL
  ONE_TIME
  AS_NEEDED
}

enum SeasonalTiming {
  SPRING
  SUMMER
  FALL
  WINTER
  ANY
}

enum TaskSource {
  SYSTEM_GENERATED
  MANAGER_CREATED
  USER_CREATED
  VENDOR_RECOMMENDED
}

enum MaintenanceStatus {
  UPCOMING
  DUE_SOON
  OVERDUE
  SCHEDULED
  IN_PROGRESS
  COMPLETED
  SKIPPED
}

enum TaskPriority {
  LOW
  NORMAL
  HIGH
  URGENT
}
```

### Task 1.2: Update Household Model

Add relation:

```prisma
model Household {
  // ... existing fields
  maintenanceTasks MaintenanceTask[]
}
```

### Task 1.3: Run Migration

```bash
cd apps/api
pnpm prisma migrate dev --name add-maintenance-calendar
pnpm prisma generate
```

---

## PHASE 2: Task Generation Engine

### Task 2.1: Create Maintenance Generation Service

Create `apps/api/src/maintenance/maintenance-generator.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MaintenanceCategory, MaintenanceFrequency, SeasonalTiming, TaskPriority } from '@prisma/client';

interface PropertyEnrichment {
  heatingType?: string;
  heatingFuel?: string;
  coolingType?: string;
  hasPool?: boolean;
  hasSeptic?: boolean;
  hasWellWater?: boolean;
  fireplaceCount?: number;
  yearBuilt?: number;
  roofType?: string;
  roofYear?: number;
  squareFeet?: number;
  stories?: number;
  garageType?: string;
  lotSizeAcres?: number;
}

interface TaskTemplate {
  title: string;
  description: string;
  category: MaintenanceCategory;
  frequency: MaintenanceFrequency;
  seasonalTiming?: SeasonalTiming;
  priority?: TaskPriority;
  estimatedCost?: number;
  sourceSystem: string;
  condition?: (enrichment: PropertyEnrichment) => boolean;
  dueDateCalculator?: (now: Date) => Date;
}

@Injectable()
export class MaintenanceGeneratorService {
  private readonly logger = new Logger(MaintenanceGeneratorService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Generate maintenance tasks for a household based on property data
   */
  async generateTasksForHousehold(
    householdId: string,
    enrichment: PropertyEnrichment,
    state?: string
  ): Promise<number> {
    const templates = this.getApplicableTemplates(enrichment, state);
    const now = new Date();
    
    let created = 0;

    for (const template of templates) {
      // Check if task already exists
      const existing = await this.prisma.maintenanceTask.findFirst({
        where: {
          householdId,
          title: template.title,
          sourceSystem: template.sourceSystem,
        },
      });

      if (existing) continue;

      // Calculate next due date
      const nextDueDate = template.dueDateCalculator 
        ? template.dueDateCalculator(now)
        : this.calculateNextDueDate(template.frequency, template.seasonalTiming, now);

      // Create the task
      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          title: template.title,
          description: template.description,
          category: template.category,
          frequency: template.frequency,
          seasonalTiming: template.seasonalTiming,
          nextDueDate,
          sourceSystem: template.sourceSystem,
          source: 'SYSTEM_GENERATED',
          priority: template.priority || 'NORMAL',
          estimatedCost: template.estimatedCost,
          isRecurring: template.frequency !== 'ONE_TIME',
        },
      });

      created++;
    }

    this.logger.log(`Generated ${created} maintenance tasks for household ${householdId}`);
    return created;
  }

  /**
   * Get task templates that apply to this property
   */
  private getApplicableTemplates(enrichment: PropertyEnrichment, state?: string): TaskTemplate[] {
    const allTemplates = this.getAllTemplates(state);
    return allTemplates.filter(t => !t.condition || t.condition(enrichment));
  }

  /**
   * All possible maintenance task templates
   */
  private getAllTemplates(state?: string): TaskTemplate[] {
    const isNortheast = ['CT', 'NY', 'NJ', 'MA', 'NH', 'VT', 'ME', 'RI', 'PA'].includes(state || '');
    
    return [
      // ========== HVAC ==========
      {
        title: 'HVAC Filter Change',
        description: 'Replace or clean HVAC air filters for optimal efficiency and air quality',
        category: 'HVAC',
        frequency: 'QUARTERLY',
        seasonalTiming: 'ANY',
        priority: 'NORMAL',
        estimatedCost: 30,
        sourceSystem: 'HVAC',
        condition: (e) => !!e.heatingType || !!e.coolingType,
      },
      {
        title: 'Furnace Annual Service',
        description: 'Professional inspection and tune-up of heating system before winter',
        category: 'HVAC',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 150,
        sourceSystem: 'HVAC',
        condition: (e) => e.heatingType?.toLowerCase().includes('forced') || 
                         e.heatingFuel?.toLowerCase().includes('gas') ||
                         e.heatingFuel?.toLowerCase().includes('oil'),
      },
      {
        title: 'AC Annual Service',
        description: 'Professional inspection and tune-up of cooling system before summer',
        category: 'HVAC',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'HIGH',
        estimatedCost: 150,
        sourceSystem: 'HVAC',
        condition: (e) => e.coolingType?.toLowerCase().includes('central'),
      },
      {
        title: 'Oil Tank Inspection',
        description: 'Annual inspection of oil tank for leaks and corrosion',
        category: 'HVAC',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 100,
        sourceSystem: 'HVAC',
        condition: (e) => e.heatingFuel?.toLowerCase().includes('oil'),
      },

      // ========== POOL ==========
      {
        title: 'Pool Opening',
        description: 'Remove cover, start filtration, balance chemicals, inspect equipment',
        category: 'POOL',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'HIGH',
        estimatedCost: 350,
        sourceSystem: 'Pool',
        condition: (e) => e.hasPool === true,
      },
      {
        title: 'Pool Closing',
        description: 'Winterize pool, add closing chemicals, install cover, drain equipment',
        category: 'POOL',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 350,
        sourceSystem: 'Pool',
        condition: (e) => e.hasPool === true && isNortheast,
      },
      {
        title: 'Pool Weekly Service',
        description: 'Test and balance chemicals, clean filter, skim debris',
        category: 'POOL',
        frequency: 'AS_NEEDED',
        seasonalTiming: 'SUMMER',
        priority: 'NORMAL',
        estimatedCost: 150,
        sourceSystem: 'Pool',
        condition: (e) => e.hasPool === true,
      },

      // ========== SEPTIC ==========
      {
        title: 'Septic Tank Pumping',
        description: 'Pump and inspect septic tank (recommended every 3-5 years)',
        category: 'PLUMBING',
        frequency: 'TRIENNIAL',
        seasonalTiming: 'ANY',
        priority: 'HIGH',
        estimatedCost: 400,
        sourceSystem: 'Septic',
        condition: (e) => e.hasSeptic === true,
      },
      {
        title: 'Septic System Inspection',
        description: 'Professional inspection of septic system components',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'NORMAL',
        estimatedCost: 150,
        sourceSystem: 'Septic',
        condition: (e) => e.hasSeptic === true,
      },

      // ========== WELL WATER ==========
      {
        title: 'Well Water Testing',
        description: 'Test well water for bacteria, nitrates, and contaminants',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'HIGH',
        estimatedCost: 150,
        sourceSystem: 'Well',
        condition: (e) => e.hasWellWater === true,
      },
      {
        title: 'Well Pump Inspection',
        description: 'Inspect well pump and pressure tank',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'NORMAL',
        estimatedCost: 200,
        sourceSystem: 'Well',
        condition: (e) => e.hasWellWater === true,
      },

      // ========== FIREPLACE ==========
      {
        title: 'Chimney Sweep & Inspection',
        description: 'Professional chimney cleaning and safety inspection',
        category: 'SAFETY',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 250,
        sourceSystem: 'Fireplace',
        condition: (e) => (e.fireplaceCount || 0) > 0,
      },

      // ========== ROOF ==========
      {
        title: 'Roof Inspection',
        description: 'Professional inspection for damage, wear, and potential issues',
        category: 'ROOFING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'NORMAL',
        estimatedCost: 200,
        sourceSystem: 'Roof',
        condition: (e) => {
          // Recommend if roof is 15+ years old
          if (!e.yearBuilt && !e.roofYear) return true;
          const roofAge = e.roofYear 
            ? new Date().getFullYear() - e.roofYear 
            : new Date().getFullYear() - (e.yearBuilt || 2000);
          return roofAge >= 15;
        },
      },

      // ========== EXTERIOR - ALWAYS APPLICABLE ==========
      {
        title: 'Gutter Cleaning',
        description: 'Clean gutters and downspouts, check for damage',
        category: 'EXTERIOR',
        frequency: 'SEMI_ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'NORMAL',
        estimatedCost: 150,
        sourceSystem: 'Exterior',
      },
      {
        title: 'Spring Gutter Check',
        description: 'Clean gutters after winter, check for ice damage',
        category: 'EXTERIOR',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'NORMAL',
        estimatedCost: 150,
        sourceSystem: 'Exterior',
        condition: () => isNortheast,
      },
      {
        title: 'Power Wash Exterior',
        description: 'Clean siding, walkways, and driveway',
        category: 'EXTERIOR',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'LOW',
        estimatedCost: 300,
        sourceSystem: 'Exterior',
      },

      // ========== LANDSCAPING ==========
      {
        title: 'Spring Lawn Treatment',
        description: 'Fertilization, weed control, and soil testing',
        category: 'LANDSCAPING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'NORMAL',
        estimatedCost: 200,
        sourceSystem: 'Landscaping',
        condition: (e) => (e.lotSizeAcres || 0) > 0.25,
      },
      {
        title: 'Fall Lawn Aeration',
        description: 'Aerate and overseed lawn for winter preparation',
        category: 'LANDSCAPING',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'LOW',
        estimatedCost: 200,
        sourceSystem: 'Landscaping',
        condition: (e) => (e.lotSizeAcres || 0) > 0.25,
      },
      {
        title: 'Tree & Shrub Trimming',
        description: 'Professional pruning of trees and landscaping',
        category: 'LANDSCAPING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'LOW',
        estimatedCost: 400,
        sourceSystem: 'Landscaping',
      },

      // ========== SAFETY ==========
      {
        title: 'Smoke & CO Detector Test',
        description: 'Test all smoke and carbon monoxide detectors, replace batteries',
        category: 'SAFETY',
        frequency: 'SEMI_ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'HIGH',
        estimatedCost: 0,
        sourceSystem: 'Safety',
      },
      {
        title: 'Fire Extinguisher Check',
        description: 'Inspect fire extinguishers, replace if needed',
        category: 'SAFETY',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'NORMAL',
        estimatedCost: 50,
        sourceSystem: 'Safety',
      },

      // ========== PLUMBING ==========
      {
        title: 'Water Heater Flush',
        description: 'Drain and flush water heater to remove sediment',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'NORMAL',
        estimatedCost: 100,
        sourceSystem: 'Plumbing',
      },
      {
        title: 'Water Heater Inspection',
        description: 'Check anode rod, inspect for leaks and corrosion',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'NORMAL',
        estimatedCost: 100,
        sourceSystem: 'Plumbing',
        condition: (e) => {
          // Especially important for older homes
          const age = e.yearBuilt ? new Date().getFullYear() - e.yearBuilt : 0;
          return age > 10;
        },
      },

      // ========== SEASONAL (NORTHEAST) ==========
      {
        title: 'Winterization Checklist',
        description: 'Disconnect hoses, insulate pipes, check weatherstripping, reverse ceiling fans',
        category: 'SEASONAL',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 0,
        sourceSystem: 'Seasonal',
        condition: () => isNortheast,
      },
      {
        title: 'Spring Home Checklist',
        description: 'Inspect roof after winter, check foundation, clean AC condenser, inspect deck/patio',
        category: 'SEASONAL',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'NORMAL',
        estimatedCost: 0,
        sourceSystem: 'Seasonal',
      },

      // ========== APPLIANCES ==========
      {
        title: 'Dryer Vent Cleaning',
        description: 'Clean dryer vent to prevent fire hazard and improve efficiency',
        category: 'APPLIANCES',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'HIGH',
        estimatedCost: 100,
        sourceSystem: 'Appliances',
      },
      {
        title: 'Refrigerator Coil Cleaning',
        description: 'Clean condenser coils for energy efficiency',
        category: 'APPLIANCES',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'LOW',
        estimatedCost: 0,
        sourceSystem: 'Appliances',
      },

      // ========== GARAGE ==========
      {
        title: 'Garage Door Service',
        description: 'Lubricate tracks and springs, test safety features',
        category: 'EXTERIOR',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'NORMAL',
        estimatedCost: 100,
        sourceSystem: 'Garage',
        condition: (e) => !!e.garageType && e.garageType !== 'None',
      },
    ];
  }

  /**
   * Calculate next due date based on frequency and seasonal timing
   */
  private calculateNextDueDate(
    frequency: MaintenanceFrequency,
    seasonalTiming: SeasonalTiming | undefined,
    from: Date
  ): Date {
    const now = new Date(from);
    
    // If seasonal, find the next occurrence of that season
    if (seasonalTiming && seasonalTiming !== 'ANY') {
      return this.getNextSeasonDate(seasonalTiming, now);
    }

    // Otherwise, calculate based on frequency
    switch (frequency) {
      case 'MONTHLY':
        now.setMonth(now.getMonth() + 1);
        break;
      case 'QUARTERLY':
        now.setMonth(now.getMonth() + 3);
        break;
      case 'SEMI_ANNUAL':
        now.setMonth(now.getMonth() + 6);
        break;
      case 'ANNUAL':
        now.setFullYear(now.getFullYear() + 1);
        break;
      case 'BIENNIAL':
        now.setFullYear(now.getFullYear() + 2);
        break;
      case 'TRIENNIAL':
        now.setFullYear(now.getFullYear() + 3);
        break;
      default:
        // ONE_TIME or AS_NEEDED - no specific due date
        break;
    }

    return now;
  }

  /**
   * Get the next date for a specific season
   */
  private getNextSeasonDate(season: SeasonalTiming, from: Date): Date {
    const year = from.getFullYear();
    const month = from.getMonth();

    // Season start months (approximate)
    const seasonMonths = {
      SPRING: 3,  // April
      SUMMER: 6,  // July
      FALL: 9,    // October
      WINTER: 0,  // January
    };

    let targetMonth = seasonMonths[season as keyof typeof seasonMonths];
    let targetYear = year;

    // If we're past this season, schedule for next year
    if (month >= targetMonth + 2) {
      targetYear++;
    }

    return new Date(targetYear, targetMonth, 15); // Mid-month
  }
}
```

### Task 2.2: Create Maintenance Service

Create `apps/api/src/maintenance/maintenance.service.ts`:

```typescript
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MaintenanceStatus, MaintenanceCategory } from '@prisma/client';

@Injectable()
export class MaintenanceService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get all maintenance tasks for a household
   */
  async getHouseholdTasks(householdId: string, filters?: {
    status?: MaintenanceStatus;
    category?: MaintenanceCategory;
    dueBefore?: Date;
  }) {
    const where: any = { householdId };
    
    if (filters?.status) where.status = filters.status;
    if (filters?.category) where.category = filters.category;
    if (filters?.dueBefore) {
      where.nextDueDate = { lte: filters.dueBefore };
    }

    return this.prisma.maintenanceTask.findMany({
      where,
      include: {
        assignedVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
      orderBy: [
        { nextDueDate: 'asc' },
        { priority: 'desc' },
      ],
    });
  }

  /**
   * Get tasks grouped by season/month for calendar view
   */
  async getTaskCalendar(householdId: string) {
    const tasks = await this.prisma.maintenanceTask.findMany({
      where: { householdId },
      orderBy: { nextDueDate: 'asc' },
    });

    // Group by season
    const calendar = {
      overdue: tasks.filter(t => t.nextDueDate && t.nextDueDate < new Date() && t.status !== 'COMPLETED'),
      thisMonth: tasks.filter(t => {
        if (!t.nextDueDate) return false;
        const now = new Date();
        return t.nextDueDate.getMonth() === now.getMonth() && 
               t.nextDueDate.getFullYear() === now.getFullYear();
      }),
      upcoming: tasks.filter(t => {
        if (!t.nextDueDate) return false;
        const now = new Date();
        const threeMonths = new Date(now.getFullYear(), now.getMonth() + 3, 1);
        return t.nextDueDate > now && t.nextDueDate < threeMonths;
      }),
      spring: tasks.filter(t => t.seasonalTiming === 'SPRING'),
      summer: tasks.filter(t => t.seasonalTiming === 'SUMMER'),
      fall: tasks.filter(t => t.seasonalTiming === 'FALL'),
      winter: tasks.filter(t => t.seasonalTiming === 'WINTER'),
    };

    return calendar;
  }

  /**
   * Get summary stats for dashboard
   */
  async getTaskSummary(householdId: string) {
    const now = new Date();
    const thirtyDays = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const [total, overdue, dueSoon, completed] = await Promise.all([
      this.prisma.maintenanceTask.count({ where: { householdId } }),
      this.prisma.maintenanceTask.count({
        where: {
          householdId,
          nextDueDate: { lt: now },
          status: { not: 'COMPLETED' },
        },
      }),
      this.prisma.maintenanceTask.count({
        where: {
          householdId,
          nextDueDate: { gte: now, lte: thirtyDays },
          status: { not: 'COMPLETED' },
        },
      }),
      this.prisma.maintenanceTask.count({
        where: { householdId, status: 'COMPLETED' },
      }),
    ]);

    return { total, overdue, dueSoon, completed };
  }

  /**
   * Mark a task as complete
   */
  async completeTask(
    taskId: string,
    userId: string,
    data: { notes?: string; actualCost?: number }
  ) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    const updated = await this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        status: 'COMPLETED',
        completedById: userId,
        completedAt: new Date(),
        lastCompletedDate: new Date(),
        completionNotes: data.notes,
        // If recurring, set next due date
        nextDueDate: task.isRecurring 
          ? this.calculateNextDueDate(task.frequency as any, task.nextDueDate)
          : null,
      },
    });

    // Log activity
    await this.prisma.activityLog.create({
      data: {
        householdId: task.householdId,
        actorId: userId,
        actorType: 'HOME_MANAGER',
        actorName: 'Home Manager',
        action: 'MAINTENANCE_COMPLETED',
        category: 'SERVICE',
        title: `Completed: ${task.title}`,
        description: data.notes,
        amount: data.actualCost,
        visibleToHomeowner: true,
      },
    });

    return updated;
  }

  /**
   * Schedule a task (assign vendor, set date)
   */
  async scheduleTask(
    taskId: string,
    data: { vendorId?: string; scheduledDate?: Date; notes?: string }
  ) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    return this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        status: 'SCHEDULED',
        assignedVendorId: data.vendorId,
        nextDueDate: data.scheduledDate || task.nextDueDate,
      },
    });
  }

  /**
   * Skip a task (postpone to next cycle)
   */
  async skipTask(taskId: string, reason?: string) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    return this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        status: 'SKIPPED',
        completionNotes: reason,
        nextDueDate: task.isRecurring
          ? this.calculateNextDueDate(task.frequency as any, task.nextDueDate)
          : null,
      },
    });
  }

  private calculateNextDueDate(frequency: string, fromDate: Date | null): Date {
    const date = fromDate ? new Date(fromDate) : new Date();
    
    switch (frequency) {
      case 'MONTHLY': date.setMonth(date.getMonth() + 1); break;
      case 'QUARTERLY': date.setMonth(date.getMonth() + 3); break;
      case 'SEMI_ANNUAL': date.setMonth(date.getMonth() + 6); break;
      case 'ANNUAL': date.setFullYear(date.getFullYear() + 1); break;
      case 'BIENNIAL': date.setFullYear(date.getFullYear() + 2); break;
      case 'TRIENNIAL': date.setFullYear(date.getFullYear() + 3); break;
    }
    
    return date;
  }
}
```

### Task 2.3: Create Maintenance Controller

Create `apps/api/src/maintenance/maintenance.controller.ts`:

```typescript
import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { MaintenanceService } from './maintenance.service';
import { MaintenanceGeneratorService } from './maintenance-generator.service';
import { MaintenanceStatus, MaintenanceCategory } from '@prisma/client';

@Controller('maintenance')
@UseGuards(FirebaseAuthGuard)
export class MaintenanceController {
  constructor(
    private maintenanceService: MaintenanceService,
    private generatorService: MaintenanceGeneratorService,
  ) {}

  @Get('household/:householdId')
  async getHouseholdTasks(
    @Param('householdId') householdId: string,
    @Query('status') status?: MaintenanceStatus,
    @Query('category') category?: MaintenanceCategory,
  ) {
    return this.maintenanceService.getHouseholdTasks(householdId, {
      status,
      category,
    });
  }

  @Get('household/:householdId/calendar')
  async getTaskCalendar(@Param('householdId') householdId: string) {
    return this.maintenanceService.getTaskCalendar(householdId);
  }

  @Get('household/:householdId/summary')
  async getTaskSummary(@Param('householdId') householdId: string) {
    return this.maintenanceService.getTaskSummary(householdId);
  }

  @Post('household/:householdId/generate')
  async generateTasks(
    @Param('householdId') householdId: string,
    @Body() body: { enrichment: any; state?: string },
  ) {
    const count = await this.generatorService.generateTasksForHousehold(
      householdId,
      body.enrichment,
      body.state,
    );
    return { generated: count };
  }

  @Put(':taskId/complete')
  async completeTask(
    @Request() req: any,
    @Param('taskId') taskId: string,
    @Body() body: { notes?: string; actualCost?: number },
  ) {
    return this.maintenanceService.completeTask(
      taskId,
      req.user.userId || req.user.id,
      body,
    );
  }

  @Put(':taskId/schedule')
  async scheduleTask(
    @Param('taskId') taskId: string,
    @Body() body: { vendorId?: string; scheduledDate?: string; notes?: string },
  ) {
    return this.maintenanceService.scheduleTask(taskId, {
      ...body,
      scheduledDate: body.scheduledDate ? new Date(body.scheduledDate) : undefined,
    });
  }

  @Put(':taskId/skip')
  async skipTask(
    @Param('taskId') taskId: string,
    @Body() body: { reason?: string },
  ) {
    return this.maintenanceService.skipTask(taskId, body.reason);
  }
}
```

### Task 2.4: Create Maintenance Module

Create `apps/api/src/maintenance/maintenance.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { MaintenanceController } from './maintenance.controller';
import { MaintenanceService } from './maintenance.service';
import { MaintenanceGeneratorService } from './maintenance-generator.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [MaintenanceController],
  providers: [MaintenanceService, MaintenanceGeneratorService],
  exports: [MaintenanceService, MaintenanceGeneratorService],
})
export class MaintenanceModule {}
```

### Task 2.5: Register Module

Add to `apps/api/src/app.module.ts`:

```typescript
import { MaintenanceModule } from './maintenance/maintenance.module';

@Module({
  imports: [
    // ... existing
    MaintenanceModule,
  ],
})
```

---

## PHASE 3: Auto-Generate on Signup

### Task 3.1: Trigger Generation in Onboarding

In the onboarding completion endpoint (wherever `/onboarding/complete-signup` is handled), add:

```typescript
// After creating household and saving property data...

// Generate maintenance tasks from enrichment data
if (enrichmentData) {
  await this.maintenanceGeneratorService.generateTasksForHousehold(
    household.id,
    enrichmentData,
    property.state
  );
}
```

### Task 3.2: Add to Seed Data

In `apps/api/prisma/seed.ts`, generate tasks for Morrison household:

```typescript
// After creating Morrison household...
const enrichment = {
  heatingType: 'Forced Air',
  heatingFuel: 'Gas',
  coolingType: 'Central',
  hasPool: true,
  hasSeptic: false,
  fireplaceCount: 2,
  yearBuilt: 1985,
  lotSizeAcres: 2.0,
  garageType: 'Attached',
};

await maintenanceGeneratorService.generateTasksForHousehold(
  household.id,
  enrichment,
  'CT'
);
```

---

## PHASE 4: Homeowner UI

### Task 4.1: Create Maintenance Page

Create `apps/web/src/app/app/maintenance/page.tsx`:

```typescript
'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  Calendar,
  CheckCircle,
  Clock,
  AlertTriangle,
  Wrench,
  Droplets,
  Flame,
  Leaf,
  Shield,
  Home,
  Filter,
  ChevronRight,
  Loader2,
} from 'lucide-react';

interface MaintenanceTask {
  id: string;
  title: string;
  description: string;
  category: string;
  frequency: string;
  seasonalTiming: string;
  nextDueDate: string;
  status: string;
  priority: string;
  estimatedCost: number;
  sourceSystem: string;
}

interface TaskSummary {
  total: number;
  overdue: number;
  dueSoon: number;
  completed: number;
}

const categoryIcons: Record<string, any> = {
  HVAC: Flame,
  PLUMBING: Droplets,
  ELECTRICAL: Wrench,
  ROOFING: Home,
  EXTERIOR: Home,
  INTERIOR: Home,
  POOL: Droplets,
  LANDSCAPING: Leaf,
  APPLIANCES: Wrench,
  SAFETY: Shield,
  SEASONAL: Calendar,
  OTHER: Wrench,
};

const categoryColors: Record<string, string> = {
  HVAC: 'bg-orange-100 text-orange-700',
  PLUMBING: 'bg-blue-100 text-blue-700',
  ELECTRICAL: 'bg-yellow-100 text-yellow-700',
  ROOFING: 'bg-gray-100 text-gray-700',
  EXTERIOR: 'bg-green-100 text-green-700',
  POOL: 'bg-cyan-100 text-cyan-700',
  LANDSCAPING: 'bg-emerald-100 text-emerald-700',
  SAFETY: 'bg-red-100 text-red-700',
  SEASONAL: 'bg-purple-100 text-purple-700',
};

export default function MaintenancePage() {
  const { user } = useAuth();
  const [tasks, setTasks] = useState<MaintenanceTask[]>([]);
  const [summary, setSummary] = useState<TaskSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'upcoming' | 'overdue'>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('');

  useEffect(() => {
    if (user?.householdId) {
      loadData();
    }
  }, [user?.householdId]);

  const loadData = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const [tasksRes, summaryRes] = await Promise.all([
        fetch(`${apiUrl}/maintenance/household/${user?.householdId}`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${apiUrl}/maintenance/household/${user?.householdId}/summary`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (tasksRes.ok) setTasks(await tasksRes.json());
      if (summaryRes.ok) setSummary(await summaryRes.json());
    } catch (error) {
      console.error('Failed to load maintenance data:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredTasks = tasks.filter(task => {
    // Status filter
    if (filter === 'overdue') {
      return task.status !== 'COMPLETED' && 
             new Date(task.nextDueDate) < new Date();
    }
    if (filter === 'upcoming') {
      const thirtyDays = new Date();
      thirtyDays.setDate(thirtyDays.getDate() + 30);
      return new Date(task.nextDueDate) <= thirtyDays && 
             new Date(task.nextDueDate) >= new Date();
    }
    // Category filter
    if (selectedCategory && task.category !== selectedCategory) {
      return false;
    }
    return true;
  });

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const isOverdue = (dateString: string) => new Date(dateString) < new Date();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Home Maintenance</h1>
        <p className="text-gray-500">Stay ahead of your home's needs</p>
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                <Calendar className="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{summary.total}</p>
                <p className="text-sm text-gray-500">Total Tasks</p>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
                <AlertTriangle className="w-5 h-5 text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{summary.overdue}</p>
                <p className="text-sm text-gray-500">Overdue</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
                <Clock className="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{summary.dueSoon}</p>
                <p className="text-sm text-gray-500">Due Soon</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{summary.completed}</p>
                <p className="text-sm text-gray-500">Completed</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-2">
        {['all', 'upcoming', 'overdue'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f as any)}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === f
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
        <div className="flex-1" />
        <select
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          className="px-4 py-2 bg-gray-100 rounded-lg text-sm"
        >
          <option value="">All Categories</option>
          {Array.from(new Set(tasks.map(t => t.category))).map(cat => (
            <option key={cat} value={cat}>{cat}</option>
          ))}
        </select>
      </div>

      {/* Task List */}
      <div className="space-y-3">
        {filteredTasks.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
            <CheckCircle className="w-12 h-12 text-green-500 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900">All caught up!</h3>
            <p className="text-gray-500">No tasks match your current filters.</p>
          </div>
        ) : (
          filteredTasks.map((task) => {
            const Icon = categoryIcons[task.category] || Wrench;
            const colorClass = categoryColors[task.category] || 'bg-gray-100 text-gray-700';
            const overdue = isOverdue(task.nextDueDate) && task.status !== 'COMPLETED';

            return (
              <div
                key={task.id}
                className={`bg-white rounded-xl border ${
                  overdue ? 'border-red-200' : 'border-gray-200'
                } p-4 hover:shadow-md transition-shadow cursor-pointer`}
              >
                <div className="flex items-start gap-4">
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${colorClass}`}>
                    <Icon className="w-5 h-5" />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h3 className="font-medium text-gray-900">{task.title}</h3>
                      {overdue && (
                        <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded">
                          Overdue
                        </span>
                      )}
                      {task.priority === 'HIGH' && !overdue && (
                        <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded">
                          High Priority
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-gray-500 mt-1">{task.description}</p>
                    <div className="flex items-center gap-4 mt-2 text-sm text-gray-400">
                      <span className="flex items-center gap-1">
                        <Calendar className="w-4 h-4" />
                        {formatDate(task.nextDueDate)}
                      </span>
                      <span>{task.frequency.replace('_', ' ')}</span>
                      {task.estimatedCost > 0 && (
                        <span>~${task.estimatedCost}</span>
                      )}
                    </div>
                  </div>

                  <ChevronRight className="w-5 h-5 text-gray-400" />
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
```

### Task 4.2: Add to Navigation

Update homeowner layout to include Maintenance in navigation.

### Task 4.3: Add Summary to Dashboard

Show maintenance summary on main dashboard with link to full list.

---

## PHASE 5: Update Tests

Add maintenance endpoint tests to test suite.

---

## PHASE 6: Build, Deploy, Test

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Migration
cd apps/api
pnpm prisma migrate dev --name add-maintenance-calendar
pnpm prisma generate

# Build
cd ../..
pnpm build

# Deploy
git add .
git commit -m "feat: auto-generated maintenance calendar from ATTOM data"
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616

# Test
pnpm test:e2e
```

---

## Summary

After this prompt:
1. ✅ MaintenanceTask database model
2. ✅ Task generation engine with 25+ task templates
3. ✅ Auto-generation from ATTOM enrichment data
4. ✅ API endpoints for CRUD operations
5. ✅ Homeowner UI at /app/maintenance
6. ✅ Dashboard integration

**User sees immediately:** "12 maintenance tasks identified for your home"

This is the #1 instant value feature that shows Haven is proactive.
