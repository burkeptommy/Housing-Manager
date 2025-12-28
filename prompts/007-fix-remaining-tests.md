# Haven: Fix Remaining Test Failures

**Created:** December 28, 2024  
**Purpose:** Fix the 4 failing API tests  
**Priority:** High

---

## CRITICAL RULES

1. **DO NOT DELETE existing code** - Only refactor and add
2. **Fix the specific issues identified**

---

## Failing Tests

| Endpoint | Error | Root Cause |
|----------|-------|------------|
| GET /manager/dashboard | HTTP 500 | Sarah has no households assigned |
| GET /manager/households | HTTP 500 | Sarah has no households assigned |
| GET /dashboard/household/:id | HTTP 500 | Query error in dashboard endpoint |
| GET /family/household/:id | HTTP 404 | Endpoint path doesn't exist |

---

## PHASE 1: Assign Sarah to Morrison Household

### Task 1.1: Check HouseholdSettings Table

Sarah needs to be assigned as the Home Manager for the Morrison household in the `HouseholdSettings` table.

Run this SQL or use Prisma to verify/fix:

```sql
-- Check if Sarah is assigned
SELECT hs.*, u.name as manager_name, h.name as household_name
FROM "HouseholdSettings" hs
LEFT JOIN "User" u ON hs."homeManagerId" = u.id
LEFT JOIN "Household" h ON hs."householdId" = h.id;

-- Find Sarah's user ID
SELECT id, name, email, role FROM "User" WHERE email = 'sarah@haven.app';

-- Find Morrison household ID  
SELECT id, name FROM "Household" WHERE name ILIKE '%Morrison%';

-- If HouseholdSettings doesn't exist or homeManagerId is null, create/update it
```

### Task 1.2: Update Seed to Assign Sarah

In `apps/api/prisma/seed.ts`, ensure Sarah is assigned to the Morrison household:

```typescript
// After creating sarah and household...

// Create or update HouseholdSettings with Sarah as manager
await prisma.householdSettings.upsert({
  where: { householdId: household.id },
  update: {
    homeManagerId: sarah.id,
  },
  create: {
    householdId: household.id,
    homeManagerId: sarah.id,
    monthlyFunding: 8500,
    fundingDueDay: 1,
  },
});

console.log('✓ Assigned Sarah as Home Manager for Morrison household');
```

### Task 1.3: Fix Production Data

Since this is production, we need to run a migration or direct SQL to fix Sarah's assignment:

```bash
# Option 1: Run seed against production
cd apps/api
DATABASE_URL="production-connection-string" pnpm prisma:seed

# Option 2: Direct SQL fix
# Connect to production DB and run:
```

```sql
-- Get IDs
WITH sarah AS (
  SELECT id FROM "User" WHERE email = 'sarah@haven.app'
),
morrison AS (
  SELECT id FROM "Household" WHERE name ILIKE '%Morrison%'
)
-- Update or insert HouseholdSettings
INSERT INTO "HouseholdSettings" ("id", "householdId", "homeManagerId", "monthlyFunding", "fundingDueDay", "createdAt", "updatedAt")
SELECT 
  gen_random_uuid(),
  morrison.id,
  sarah.id,
  8500,
  1,
  NOW(),
  NOW()
FROM sarah, morrison
ON CONFLICT ("householdId") 
DO UPDATE SET "homeManagerId" = EXCLUDED."homeManagerId", "updatedAt" = NOW();
```

---

## PHASE 2: Fix Dashboard Endpoint Query

### Task 2.1: Find Dashboard Service

Look at `apps/api/src/dashboard/dashboard.service.ts` for the `getHouseholdDashboard` method.

### Task 2.2: Fix Query Issues

The HTTP 500 suggests a query error. Common issues:
- Trying to access a relation that doesn't exist
- Null pointer on optional fields
- Missing includes in Prisma query

Add error handling and fix the query:

```typescript
async getHouseholdDashboard(householdId: string) {
  try {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        property: true,
        users: {
          where: { role: 'HOMEOWNER' },
          select: { id: true, name: true, email: true },
        },
        bills: {
          where: { status: 'ACTIVE' },
          take: 10,
          orderBy: { dueDate: 'asc' },
        },
        settings: true,
        // Be careful with relations that might not exist
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    // Safely access optional relations
    const property = household.property;
    const settings = household.settings;

    return {
      household: {
        id: household.id,
        name: household.name,
        tier: household.tier,
        status: household.status,
      },
      property: property ? {
        street: property.street,
        city: property.city,
        state: property.state,
        zip: property.zip,
        bedrooms: property.bedrooms,
        bathrooms: property.bathrooms,
        squareFeet: property.squareFeet,
      } : null,
      homeHealth: 94, // Default or calculate
      upcomingBills: household.bills || [],
      // ... other fields
    };
  } catch (error) {
    console.error('Dashboard error:', error);
    throw error;
  }
}
```

---

## PHASE 3: Fix or Create Family Endpoint

### Task 3.1: Check if Family Endpoint Exists

```bash
# Search for family controller/routes
grep -r "family" apps/api/src --include="*.ts" | grep -i "controller\|route\|@Get\|@Post"
```

### Task 3.2: Create Family Controller if Missing

If `/family/household/:id` doesn't exist, create it:

Create `apps/api/src/family/family.controller.ts`:

```typescript
import { Controller, Get, Param, UseGuards, Request } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { FamilyService } from './family.service';

@Controller('family')
@UseGuards(FirebaseAuthGuard)
export class FamilyController {
  constructor(private familyService: FamilyService) {}

  @Get('household/:id')
  async getHouseholdFamily(
    @Param('id') householdId: string,
    @Request() req: any
  ) {
    return this.familyService.getHouseholdFamily(householdId, req.user.id);
  }
}
```

Create `apps/api/src/family/family.service.ts`:

```typescript
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FamilyService {
  constructor(private prisma: PrismaService) {}

  async getHouseholdFamily(householdId: string, userId: string) {
    // Verify user has access to this household
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { householdId: true, role: true },
    });

    // Allow if user belongs to household or is admin/manager
    const hasAccess = 
      user?.householdId === householdId ||
      user?.role === 'ADMIN' ||
      user?.role === 'HOME_MANAGER' ||
      user?.role === 'MANAGER';

    if (!hasAccess) {
      throw new ForbiddenException('Access denied to this household');
    }

    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        users: {
          where: { role: 'HOMEOWNER' },
          select: {
            id: true,
            name: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
        familyMembers: {
          include: {
            activities: true,
          },
        },
        vehicles: true,
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    // Organize family data
    const adults = household.users.map(u => ({
      id: u.id,
      name: u.name,
      firstName: u.firstName,
      lastName: u.lastName,
      email: u.email,
      phone: u.phone,
      role: 'Head of Household',
    }));

    const children = household.familyMembers
      .filter(m => m.type === 'CHILD')
      .map(c => ({
        id: c.id,
        name: c.name,
        age: c.age,
        school: c.school,
        grade: c.grade,
        activities: c.activities,
      }));

    const pets = household.familyMembers
      .filter(m => m.type === 'PET')
      .map(p => ({
        id: p.id,
        name: p.name,
        type: p.breed,
        age: p.age,
      }));

    const vehicles = household.vehicles.map(v => ({
      id: v.id,
      year: v.year,
      make: v.make,
      model: v.model,
      color: v.color,
      licensePlate: v.licensePlate,
    }));

    return {
      adults,
      children,
      pets,
      vehicles,
      staff: [], // TODO: Add staff from familyMembers
    };
  }
}
```

Create `apps/api/src/family/family.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { FamilyController } from './family.controller';
import { FamilyService } from './family.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [FamilyController],
  providers: [FamilyService],
})
export class FamilyModule {}
```

### Task 3.3: Register Family Module

Add to `apps/api/src/app.module.ts`:

```typescript
import { FamilyModule } from './family/family.module';

@Module({
  imports: [
    // ... existing imports
    FamilyModule,
  ],
})
export class AppModule {}
```

---

## PHASE 4: Build, Deploy, and Test

### Task 4.1: Build

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

### Task 4.2: Deploy

```bash
git add .
git commit -m "fix: assign Sarah to Morrison, fix dashboard/family endpoints"
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

### Task 4.3: Fix Production Data (Sarah Assignment)

After deploy, run SQL to assign Sarah to Morrison household in production:

```bash
# Use Cloud SQL proxy or your DB connection method
psql $DATABASE_URL -c "
UPDATE \"HouseholdSettings\" 
SET \"homeManagerId\" = (SELECT id FROM \"User\" WHERE email = 'sarah@haven.app')
WHERE \"householdId\" = (SELECT id FROM \"Household\" WHERE name ILIKE '%Morrison%');
"
```

Or if no HouseholdSettings exists:

```bash
psql $DATABASE_URL -c "
INSERT INTO \"HouseholdSettings\" (\"id\", \"householdId\", \"homeManagerId\", \"monthlyFunding\", \"fundingDueDay\", \"createdAt\", \"updatedAt\")
SELECT 
  gen_random_uuid(),
  (SELECT id FROM \"Household\" WHERE name ILIKE '%Morrison%'),
  (SELECT id FROM \"User\" WHERE email = 'sarah@haven.app'),
  8500,
  1,
  NOW(),
  NOW()
ON CONFLICT (\"householdId\") DO UPDATE 
SET \"homeManagerId\" = EXCLUDED.\"homeManagerId\";
"
```

### Task 4.4: Run Tests

```bash
pnpm test:e2e
```

---

## Expected Results After Fix

| Test | Expected |
|------|----------|
| GET /manager/dashboard | ✅ 200 - Sarah sees Morrison household |
| GET /manager/households | ✅ 200 - Returns Morrison household |
| GET /dashboard/household/:id | ✅ 200 - Bob's dashboard loads |
| GET /family/household/:id | ✅ 200 - Family data returns |

**Target: 100% pass rate (26/26 tests)**

---

## Summary

1. ✅ Assign Sarah as Home Manager for Morrison household
2. ✅ Fix dashboard endpoint query issues
3. ✅ Create/fix family endpoint
4. ✅ Deploy and test
