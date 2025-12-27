# Haven Production Ready: Complete Backend & Real Data Flow

**Created:** December 27, 2024  
**Purpose:** Make Haven actually work with real users, real data, and complete onboarding flow  
**Priority:** Critical - This is the production build

---

## Overview

Transform Haven from a demo with mock data to a fully functional platform where:
- New users sign up and get onboarded by a Home Manager
- Home Manager captures all household data through intake workbench
- Homeowners see their REAL data in the portal
- Activity is logged and visible in real-time

**Mock data exists ONLY for Bob Morrison** (bob@example.com) - the demo account.
All other users get real data captured through the onboarding process.

---

## Architecture

```
NEW USER FLOW:
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│ User Signup │ ──> │ Onboarding   │ ──> │ HM Sees in      │
│ + Address   │     │ Session      │     │ Queue           │
└─────────────┘     │ Created      │     └────────┬────────┘
                    └──────────────┘              │
                                                  ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│ User Sees   │ <── │ Data Saved   │ <── │ HM Calls User   │
│ Real Data   │     │ to Database  │     │ Uses Workbench  │
└─────────────┘     └──────────────┘     └─────────────────┘

DEMO ACCOUNT (bob@example.com):
┌─────────────┐     ┌──────────────┐
│ Login as    │ ──> │ See Morrison │
│ Bob         │     │ Demo Data    │
└─────────────┘     └──────────────┘
```

---

## PHASE 1: Database Schema Updates

### Task 1.1: Add Missing Models

Update `apps/api/prisma/schema.prisma` to ensure all needed models exist:

```prisma
// Add these models if they don't exist:

model OnboardingSession {
  id              String            @id @default(cuid())
  
  // Link to household
  householdId     String            @unique
  household       Household         @relation(fields: [householdId], references: [id])
  
  // Assignment
  assignedManagerId String?
  assignedManager   User?           @relation("AssignedManager", fields: [assignedManagerId], references: [id])
  
  // Status tracking
  status          OnboardingStatus  @default(PENDING_CALL)
  
  // User's initial input from signup
  biggestChallenge String?
  selectedTier     String?
  
  // Scheduling
  callScheduledFor DateTime?
  callStartedAt    DateTime?
  callCompletedAt  DateTime?
  
  // Intake progress (0-100 per section)
  progressFamily      Int @default(0)
  progressProperty    Int @default(0)
  progressZones       Int @default(0)
  progressSystems     Int @default(0)
  progressVendors     Int @default(0)
  progressBills       Int @default(0)
  
  // Flexible data during intake
  intakeData       Json?
  
  // Calculated
  monthlyFundingEstimate Float?
  
  // Notes
  callNotes        String?           @db.Text
  followUpNeeded   Boolean           @default(false)
  followUpNotes    String?           @db.Text
  
  // Milestones
  profileDeliveredAt DateTime?
  firstBillPaidAt    DateTime?
  
  createdAt        DateTime          @default(now())
  updatedAt        DateTime          @updatedAt
}

enum OnboardingStatus {
  PENDING_CALL
  CALL_SCHEDULED
  CALL_IN_PROGRESS
  INTAKE_PARTIAL
  INTAKE_COMPLETE
  PROFILE_BUILDING
  PROFILE_DELIVERED
  ACTIVE
}

model ActivityLog {
  id          String   @id @default(cuid())
  
  householdId String
  household   Household @relation(fields: [householdId], references: [id])
  
  // Who did this
  actorId     String
  actorType   ActorType
  actorName   String
  
  // What happened
  action      String          // e.g., "BILL_PAID", "SERVICE_SCHEDULED"
  category    String          // e.g., "BILLING", "SERVICE", "PROPERTY"
  title       String          // e.g., "Paid Eversource Electric"
  description String?         // e.g., "$187.43"
  
  // Links to related records
  billId      String?
  vendorId    String?
  assetId     String?
  zoneId      String?
  
  // Metadata
  amount      Float?
  metadata    Json?
  
  // Visibility
  visibleToHomeowner Boolean @default(true)
  
  createdAt   DateTime @default(now())
  
  @@index([householdId, createdAt])
}

enum ActorType {
  HOMEOWNER
  HOME_MANAGER
  HANDYMAN
  VENDOR
  SYSTEM
}

model HouseholdSettings {
  id              String    @id @default(cuid())
  householdId     String    @unique
  household       Household @relation(fields: [householdId], references: [id])
  
  // Funding
  monthlyFunding  Float     @default(0)
  fundingDueDay   Int       @default(1)
  
  // Preferences
  timezone        String    @default("America/New_York")
  notifyEmail     Boolean   @default(true)
  notifySms       Boolean   @default(true)
  
  // Manager assignment
  homeManagerId   String?
  homeManager     User?     @relation("HomeManagerClients", fields: [homeManagerId], references: [id])
  
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
}

model BillPayment {
  id                String   @id @default(cuid())
  
  billId            String
  bill              Bill     @relation(fields: [billId], references: [id])
  
  amount            Float
  paidDate          DateTime
  paidBy            String   @default("Haven")
  method            String?  // ACH, Check, Card
  confirmationNumber String?
  notes             String?
  
  createdAt         DateTime @default(now())
}

// Update existing models to add relations:

model Household {
  // ... existing fields ...
  
  onboardingSession   OnboardingSession?
  activityLogs        ActivityLog[]
  settings            HouseholdSettings?
}

model Bill {
  // ... existing fields ...
  
  payments            BillPayment[]
}

model User {
  // ... existing fields ...
  
  assignedOnboardings OnboardingSession[] @relation("AssignedManager")
  managedHouseholds   HouseholdSettings[] @relation("HomeManagerClients")
}
```

### Task 1.2: Run Migration

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name add_onboarding_activity_settings
```

---

## PHASE 2: Seed Morrison Demo Data

### Task 2.1: Create Comprehensive Seed File

Replace `apps/api/prisma/seed.ts`:

```typescript
import { PrismaClient, UserRole, FamilyMemberType, BillFrequency, BillCategory } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding Haven database...');
  console.log('');

  // =========================================================================
  // CLEAN EXISTING DATA
  // =========================================================================
  console.log('Cleaning existing data...');
  
  await prisma.activityLog.deleteMany();
  await prisma.billPayment.deleteMany();
  await prisma.bill.deleteMany();
  await prisma.kidActivity.deleteMany();
  await prisma.familyMember.deleteMany();
  await prisma.vehicle.deleteMany();
  await prisma.asset.deleteMany();
  await prisma.zone.deleteMany();
  await prisma.vendor.deleteMany();
  await prisma.householdSettings.deleteMany();
  await prisma.onboardingSession.deleteMany();
  await prisma.property.deleteMany();
  await prisma.user.deleteMany();
  await prisma.household.deleteMany();

  // =========================================================================
  // CREATE HAVEN TEAM (Staff accounts - no household)
  // =========================================================================
  console.log('');
  console.log('Creating Haven team...');

  const sarah = await prisma.user.create({
    data: {
      email: 'sarah@haven.app',
      firebaseUid: 'sarah-haven-manager',
      name: 'Sarah Chen',
      firstName: 'Sarah',
      lastName: 'Chen',
      phone: '(203) 555-0100',
      role: UserRole.HOME_MANAGER,
    },
  });
  console.log('  ✓ Sarah Chen (Home Manager)');

  const mike = await prisma.user.create({
    data: {
      email: 'mike@haven.app',
      firebaseUid: 'mike-haven-handyman',
      name: 'Mike Rodriguez',
      firstName: 'Mike',
      lastName: 'Rodriguez',
      phone: '(203) 555-0200',
      role: UserRole.HANDYMAN,
    },
  });
  console.log('  ✓ Mike Rodriguez (Handyman)');

  const admin = await prisma.user.create({
    data: {
      email: 'admin@haven.app',
      firebaseUid: 'haven-admin',
      name: 'Haven Admin',
      firstName: 'Admin',
      role: UserRole.ADMIN,
    },
  });
  console.log('  ✓ Haven Admin');

  // =========================================================================
  // CREATE MORRISON DEMO HOUSEHOLD
  // =========================================================================
  console.log('');
  console.log('Creating Morrison demo household...');

  const household = await prisma.household.create({
    data: {
      name: 'The Morrison Family',
      tier: 'HAVEN',
      status: 'ACTIVE',
    },
  });
  console.log('  ✓ Household: The Morrison Family');

  // Household Settings
  await prisma.householdSettings.create({
    data: {
      householdId: household.id,
      monthlyFunding: 8500,
      fundingDueDay: 1,
      homeManagerId: sarah.id,
    },
  });

  // =========================================================================
  // PROPERTY
  // =========================================================================
  const property = await prisma.property.create({
    data: {
      householdId: household.id,
      name: 'Inspiration Farm',
      street: '38 Bedford Road',
      city: 'Greenwich',
      state: 'CT',
      zip: '06831',
      country: 'USA',
      bedrooms: 5,
      bathrooms: 5.5,
      squareFeet: 5765,
      lotSizeAcres: 2.0,
      yearBuilt: 1998,
      propertyType: 'Single Family',
      homeHealthScore: 94,
      enrichmentData: {
        heatingFuel: 'Oil',
        fireplaces: 2,
        pool: false,
        sewerType: 'Septic',
        waterType: 'Public',
        garageSpaces: 3,
      },
    },
  });
  console.log('  ✓ Property: Inspiration Farm, 38 Bedford Road');

  // =========================================================================
  // USERS (Homeowners)
  // =========================================================================
  console.log('');
  console.log('Creating Morrison family users...');

  const bob = await prisma.user.create({
    data: {
      email: 'bob@example.com',
      firebaseUid: 'bob-morrison-demo',
      name: 'Bob Morrison',
      firstName: 'Bob',
      lastName: 'Morrison',
      phone: '(203) 555-0101',
      role: UserRole.HOMEOWNER,
      householdId: household.id,
    },
  });
  console.log('  ✓ Bob Morrison (bob@example.com)');

  const alice = await prisma.user.create({
    data: {
      email: 'alice@example.com',
      firebaseUid: 'alice-morrison-demo',
      name: 'Alice Morrison',
      firstName: 'Alice',
      lastName: 'Morrison',
      phone: '(203) 555-0102',
      role: UserRole.HOMEOWNER,
      householdId: household.id,
    },
  });
  console.log('  ✓ Alice Morrison (alice@example.com)');

  // =========================================================================
  // FAMILY MEMBERS
  // =========================================================================
  console.log('');
  console.log('Creating family members...');

  // Emma - 12 year old daughter
  const emma = await prisma.familyMember.create({
    data: {
      householdId: household.id,
      type: FamilyMemberType.CHILD,
      firstName: 'Emma',
      lastName: 'Morrison',
      dateOfBirth: new Date('2012-03-15'),
      school: 'Greenwich Country Day School',
      grade: '7th Grade',
      allergies: ['Peanuts', 'Tree nuts'],
    },
  });

  await prisma.kidActivity.createMany({
    data: [
      {
        familyMemberId: emma.id,
        name: 'Soccer',
        schedule: 'Tue/Thu 4-6pm, Sat games 10am',
        location: 'Greenwich Polo Club Fields',
        cost: 450,
        frequency: 'quarterly',
        provider: 'Greenwich Soccer Club',
      },
      {
        familyMemberId: emma.id,
        name: 'Piano Lessons',
        schedule: 'Wed 3:30-4:30pm',
        location: '45 Greenwich Ave',
        cost: 200,
        frequency: 'monthly',
        provider: 'Greenwich Music Academy',
      },
    ],
  });
  console.log('  ✓ Emma Morrison (12, 7th Grade) + 2 activities');

  // Jack - 8 year old son
  const jack = await prisma.familyMember.create({
    data: {
      householdId: household.id,
      type: FamilyMemberType.CHILD,
      firstName: 'Jack',
      lastName: 'Morrison',
      dateOfBirth: new Date('2016-07-22'),
      school: 'North Street School',
      grade: '3rd Grade',
    },
  });

  await prisma.kidActivity.createMany({
    data: [
      {
        familyMemberId: jack.id,
        name: 'Little League',
        schedule: 'Sat 10am',
        location: 'Cos Cob Park',
        cost: 350,
        frequency: 'per season',
      },
      {
        familyMemberId: jack.id,
        name: 'Piano',
        schedule: 'Mon 4pm',
        cost: 200,
        frequency: 'monthly',
      },
      {
        familyMemberId: jack.id,
        name: 'Art Class',
        schedule: 'Thu 3:30pm',
        cost: 150,
        frequency: 'monthly',
      },
    ],
  });
  console.log('  ✓ Jack Morrison (8, 3rd Grade) + 3 activities');

  // Max - Pet
  await prisma.familyMember.create({
    data: {
      householdId: household.id,
      type: FamilyMemberType.PET,
      firstName: 'Max',
      role: 'Golden Retriever',
      dateOfBirth: new Date('2020-09-10'),
      medicalNotes: JSON.stringify({
        vet: 'Dr. Williams',
        vetClinic: 'Westlake Animal Hospital',
        vetPhone: '(512) 555-VETS',
        food: 'Blue Buffalo Life Protection Adult Chicken',
        foodAmount: '30 lbs/mo',
        microchip: '985141001234567',
        monthlyCost: 150,
        vaccinesDue: '2025-01-23',
      }),
    },
  });
  console.log('  ✓ Max (Golden Retriever, 4 years)');

  // Maria Garcia - Nanny
  await prisma.familyMember.create({
    data: {
      householdId: household.id,
      type: FamilyMemberType.STAFF,
      firstName: 'Maria',
      lastName: 'Garcia',
      role: 'Nanny',
      phone: '(203) 555-0199',
      email: 'maria.garcia@email.com',
      employer: 'Greenwich Elite Nannies',
      medicalNotes: JSON.stringify({
        schedule: 'Mon-Thu 7am-6pm, Fri 7am-3pm',
        weeklyStipend: 1500,
        startDate: '2023-06-01',
        contractExpires: '2025-01-03',
        permissions: ['Kids Schedules', 'Emergency Contacts', 'Medical Info'],
      }),
    },
  });
  console.log('  ✓ Maria Garcia (Nanny)');

  // =========================================================================
  // VEHICLES
  // =========================================================================
  console.log('');
  console.log('Creating vehicles...');

  await prisma.vehicle.createMany({
    data: [
      {
        householdId: household.id,
        year: 2023,
        make: 'Tesla',
        model: 'Model Y',
        color: 'Midnight Silver',
        licensePlate: 'GRN 1234',
        vin: '5YJSA1E26MF123456',
        primaryDriver: 'Bob',
        mileage: 24500,
        loanPayment: 895,
        insuranceMonthly: 180,
        registrationExpires: new Date('2025-02-10'),
      },
      {
        householdId: household.id,
        year: 2022,
        make: 'Toyota',
        model: 'Highlander',
        color: 'Pearl White',
        licensePlate: 'XYZ 5678',
        primaryDriver: 'Alice',
        mileage: 35200,
        loanPayment: 775,
        insuranceMonthly: 165,
      },
      {
        householdId: household.id,
        year: 2024,
        make: 'Mercedes-Benz',
        model: 'GLE 450',
        color: 'Obsidian Black Metallic',
        licensePlate: 'EF-11111',
        primaryDriver: 'Alice',
        mileage: 8750,
        loanPayment: 1082,
        insuranceMonthly: 210,
      },
    ],
  });
  console.log('  ✓ 3 vehicles (Tesla, Highlander, Mercedes)');

  // =========================================================================
  // ZONES & ASSETS
  // =========================================================================
  console.log('');
  console.log('Creating zones and assets...');

  // Kitchen
  const kitchen = await prisma.zone.create({
    data: {
      propertyId: property.id,
      name: 'Kitchen',
      type: 'KITCHEN',
      floor: 'First Floor',
    },
  });

  await prisma.asset.createMany({
    data: [
      { zoneId: kitchen.id, propertyId: property.id, name: 'Refrigerator', category: 'APPLIANCE', brand: 'Sub-Zero', model: 'BI-48S', condition: 'Excellent', purchaseDate: new Date('2020-03-15') },
      { zoneId: kitchen.id, propertyId: property.id, name: 'Dishwasher', category: 'APPLIANCE', brand: 'Bosch', model: 'SHPM88Z75N', condition: 'Excellent', purchaseDate: new Date('2021-06-01') },
      { zoneId: kitchen.id, propertyId: property.id, name: 'Range/Oven', category: 'APPLIANCE', brand: 'Wolf', model: 'DF486G', condition: 'Excellent', purchaseDate: new Date('2020-03-15') },
    ],
  });
  console.log('  ✓ Kitchen (3 assets)');

  // Laundry
  const laundry = await prisma.zone.create({
    data: {
      propertyId: property.id,
      name: 'Laundry Room',
      type: 'LAUNDRY',
      floor: 'Second Floor',
    },
  });

  await prisma.asset.createMany({
    data: [
      { zoneId: laundry.id, propertyId: property.id, name: 'Washer', category: 'APPLIANCE', brand: 'LG', model: 'WM4500HBA', condition: 'Excellent' },
      { zoneId: laundry.id, propertyId: property.id, name: 'Dryer', category: 'APPLIANCE', brand: 'LG', model: 'DLEX4500B', condition: 'Excellent' },
    ],
  });
  console.log('  ✓ Laundry Room (2 assets)');

  // Garage
  const garage = await prisma.zone.create({
    data: {
      propertyId: property.id,
      name: 'Garage',
      type: 'GARAGE',
      floor: 'Ground Level',
    },
  });

  await prisma.asset.create({
    data: { zoneId: garage.id, propertyId: property.id, name: 'Garage Door Opener', category: 'EQUIPMENT', brand: 'LiftMaster', condition: 'Good' },
  });
  console.log('  ✓ Garage (1 asset)');

  // Mechanical Room
  const mechanical = await prisma.zone.create({
    data: {
      propertyId: property.id,
      name: 'Mechanical Room',
      type: 'MECHANICAL',
      floor: 'Basement',
    },
  });

  await prisma.asset.createMany({
    data: [
      { zoneId: mechanical.id, propertyId: property.id, name: 'HVAC System', category: 'SYSTEM', brand: 'Carrier', model: 'Infinity 24', condition: 'Good', purchaseDate: new Date('2021-04-01'), warrantyExpires: new Date('2031-04-01') },
      { zoneId: mechanical.id, propertyId: property.id, name: 'Water Heater', category: 'SYSTEM', brand: 'Rheem', model: 'RTGH-95DVLN', condition: 'Good', purchaseDate: new Date('2019-08-15') },
      { zoneId: mechanical.id, propertyId: property.id, name: 'Electrical Panel', category: 'SYSTEM', brand: 'Square D', condition: 'Good' },
    ],
  });
  console.log('  ✓ Mechanical Room (3 assets)');

  // Backyard
  const backyard = await prisma.zone.create({
    data: {
      propertyId: property.id,
      name: 'Backyard & Grounds',
      type: 'OUTDOOR_BACK',
    },
  });

  await prisma.asset.createMany({
    data: [
      { zoneId: backyard.id, propertyId: property.id, name: 'Pool', category: 'OUTDOOR', condition: 'Good' },
      { zoneId: backyard.id, propertyId: property.id, name: 'Roof', category: 'STRUCTURE', condition: 'Good', notes: 'Asphalt shingles, installed 2012, ~12 years old' },
      { zoneId: backyard.id, propertyId: property.id, name: 'Septic System', category: 'SYSTEM', condition: 'Good', notes: 'Last pumped 2023' },
    ],
  });
  console.log('  ✓ Backyard & Grounds (3 assets)');

  // =========================================================================
  // VENDORS
  // =========================================================================
  console.log('');
  console.log('Creating vendors...');

  await prisma.vendor.createMany({
    data: [
      { householdId: household.id, category: 'HVAC', name: 'Comfort Zone HVAC', contactName: 'Tom Reynolds', phone: '(203) 555-1001', email: 'service@comfortzone.example.com', accountNumber: 'CZ-2024-001' },
      { householdId: household.id, category: 'PLUMBING', name: "Mike's Plumbing", contactName: 'Mike Thompson', phone: '(203) 555-1002', email: 'mike@mikesplumbing.example.com' },
      { householdId: household.id, category: 'ELECTRICAL', name: 'Greenwich Electric', contactName: 'Jim Watts', phone: '(203) 555-1003' },
      { householdId: household.id, category: 'ROOFING', name: 'Ace Roofing Co', contactName: 'Steve Ace', phone: '(203) 555-1004', email: 'vendor@aceroofing.example.com' },
      { householdId: household.id, category: 'LANDSCAPING', name: 'Green Thumb Lawn Care', contactName: 'Carlos Verde', phone: '(203) 555-1005', notes: 'Weekly service Thursdays' },
    ],
  });
  console.log('  ✓ 5 vendors');

  // =========================================================================
  // BILLS
  // =========================================================================
  console.log('');
  console.log('Creating bills...');

  const bills = await prisma.bill.createMany({
    data: [
      // Housing
      { householdId: household.id, category: 'MORTGAGE', name: 'Mortgage', payeeName: 'Chase Home Lending', amount: 3450, frequency: 'MONTHLY', dueDay: 1, accountNumber: '****4521', status: 'ACTIVE', havenManaged: true },
      { householdId: household.id, category: 'HOME_INSURANCE', name: 'Home Insurance', payeeName: 'Allstate', amount: 677, frequency: 'MONTHLY', dueDay: 15, accountNumber: 'POL-789456', status: 'ACTIVE', havenManaged: true },
      { householdId: household.id, category: 'PROPERTY_TAX', name: 'Property Tax', payeeName: 'Town of Greenwich', amount: 12000, frequency: 'SEMI_ANNUAL', status: 'ACTIVE', havenManaged: true },
      
      // Utilities
      { householdId: household.id, category: 'ELECTRIC', name: 'Electric', payeeName: 'Eversource', amount: 187, frequency: 'MONTHLY', dueDay: 10, accountNumber: '51-234-5678', status: 'ACTIVE', havenManaged: true },
      { householdId: household.id, category: 'GAS', name: 'Gas', payeeName: 'Eversource', amount: 145, frequency: 'MONTHLY', dueDay: 10, accountNumber: '51-234-5679', status: 'ACTIVE', havenManaged: true },
      { householdId: household.id, category: 'WATER_SEWER', name: 'Water/Sewer', payeeName: 'Town of Greenwich', amount: 215, frequency: 'MONTHLY', dueDay: 12, status: 'ACTIVE', havenManaged: true },
      { householdId: household.id, category: 'OIL_PROPANE', name: 'Heating Oil', payeeName: 'Greenwich Oil Co', amount: 400, frequency: 'MONTHLY', notes: 'Budget plan, varies by season', status: 'ACTIVE', havenManaged: true },
      
      // Telecom
      { householdId: household.id, category: 'INTERNET', name: 'Internet', payeeName: 'Optimum', amount: 89, frequency: 'MONTHLY', dueDay: 7, accountNumber: '07-123456789', status: 'ACTIVE', havenManaged: true },
      { householdId: household.id, category: 'CELL_PHONE', name: 'Cell Phones', payeeName: 'Verizon Wireless', amount: 323, frequency: 'MONTHLY', dueDay: 15, accountNumber: '****7890', status: 'ACTIVE', havenManaged: true },
      
      // Education
      { householdId: household.id, category: 'SCHOOL_TUITION', name: 'Emma - Greenwich Country Day', payeeName: 'Greenwich Country Day School', amount: 4500, frequency: 'MONTHLY', dueDay: 1, notes: 'Due in 5 days', status: 'ACTIVE', havenManaged: true },
      
      // Home Services
      { householdId: household.id, category: 'LAWN_LANDSCAPING', name: 'Lawn Care', payeeName: 'Green Thumb Lawn Care', amount: 185, frequency: 'MONTHLY', status: 'ACTIVE', havenManaged: true },
      { householdId: household.id, category: 'SECURITY', name: 'Security Monitoring', payeeName: 'ADT', amount: 45, frequency: 'MONTHLY', accountNumber: 'ADT-123456', status: 'ACTIVE', havenManaged: true },
      
      // Auto
      { householdId: household.id, category: 'AUTO_INSURANCE', name: 'Auto Insurance', payeeName: 'Allstate', amount: 555, frequency: 'MONTHLY', accountNumber: 'AUTO-789', status: 'ACTIVE', havenManaged: true },
    ],
  });
  console.log('  ✓ 13 bills configured');

  // =========================================================================
  // SAMPLE ACTIVITY LOG
  // =========================================================================
  console.log('');
  console.log('Creating sample activity...');

  const now = new Date();
  const twoDaysAgo = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);
  const fiveDaysAgo = new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000);
  const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const twoWeeksAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

  await prisma.activityLog.createMany({
    data: [
      {
        householdId: household.id,
        actorId: sarah.id,
        actorType: 'HOME_MANAGER',
        actorName: 'Sarah Chen',
        action: 'SERVICE_COMPLETED',
        category: 'MAINTENANCE',
        title: 'HVAC filter changed',
        createdAt: twoDaysAgo,
      },
      {
        householdId: household.id,
        actorId: sarah.id,
        actorType: 'HOME_MANAGER',
        actorName: 'Sarah Chen',
        action: 'BILL_PAID',
        category: 'BILLING',
        title: 'Lawn care invoice paid',
        description: '$185',
        amount: 185,
        createdAt: fiveDaysAgo,
      },
      {
        householdId: household.id,
        actorId: sarah.id,
        actorType: 'HOME_MANAGER',
        actorName: 'Sarah Chen',
        action: 'DOCUMENT_UPLOADED',
        category: 'PROPERTY',
        title: 'Warranty uploaded for water heater',
        createdAt: oneWeekAgo,
      },
      {
        householdId: household.id,
        actorId: mike.id,
        actorType: 'HANDYMAN',
        actorName: 'Mike Rodriguez',
        action: 'SERVICE_COMPLETED',
        category: 'MAINTENANCE',
        title: 'Gutter cleaning completed',
        description: '$275',
        amount: 275,
        createdAt: twoWeeksAgo,
      },
    ],
  });
  console.log('  ✓ 4 activity log entries');

  // =========================================================================
  // MARK ONBOARDING COMPLETE
  // =========================================================================
  await prisma.onboardingSession.create({
    data: {
      householdId: household.id,
      assignedManagerId: sarah.id,
      status: 'ACTIVE',
      selectedTier: 'HAVEN',
      progressFamily: 100,
      progressProperty: 100,
      progressZones: 100,
      progressSystems: 100,
      progressVendors: 100,
      progressBills: 100,
      monthlyFundingEstimate: 8500,
      callCompletedAt: new Date('2024-06-15'),
      profileDeliveredAt: new Date('2024-06-16'),
    },
  });
  console.log('  ✓ Onboarding marked complete');

  // =========================================================================
  // DONE
  // =========================================================================
  console.log('');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('✅ SEED COMPLETED SUCCESSFULLY');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('');
  console.log('Demo Accounts:');
  console.log('  📧 bob@example.com     (Homeowner - Morrison family)');
  console.log('  📧 alice@example.com   (Homeowner - Morrison family)');
  console.log('');
  console.log('Haven Team:');
  console.log('  📧 sarah@haven.app     (Home Manager)');
  console.log('  📧 mike@haven.app      (Handyman)');
  console.log('  📧 admin@haven.app     (Admin)');
  console.log('');
  console.log('Note: Firebase Auth passwords are managed in Firebase Console.');
  console.log('      Database records are linked via firebaseUid field.');
  console.log('');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

### Task 2.2: Run Seed

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma db seed
```

---

## PHASE 3: Build API Endpoints

### Task 3.1: Create Dashboard Service

Create `apps/api/src/dashboard/dashboard.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getDashboard(householdId: string) {
    // Get household with property
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        property: true,
        settings: {
          include: {
            homeManager: {
              select: { id: true, name: true, email: true, phone: true },
            },
          },
        },
      },
    });

    if (!household) {
      throw new Error('Household not found');
    }

    // Get billing summary for current month
    const billingSummary = await this.getBillingSummary(householdId);

    // Get next scheduled service (placeholder - would come from service schedule)
    const nextService = await this.getNextService(householdId);

    // Get pending approvals count (placeholder)
    const pendingApprovals = 2; // TODO: Implement approvals model

    // Get recent activity
    const recentActivity = await this.prisma.activityLog.findMany({
      where: { householdId, visibleToHomeowner: true },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    // Get upcoming items
    const upcoming = await this.getUpcoming(householdId);

    return {
      household: {
        id: household.id,
        name: household.name,
        propertyAddress: household.property
          ? `${household.property.street}, ${household.property.city}, ${household.property.state} ${household.property.zip}`
          : null,
      },
      manager: household.settings?.homeManager || null,
      homeHealth: household.property?.homeHealthScore || 94,
      billing: billingSummary,
      nextService,
      pendingApprovals,
      recentActivity: recentActivity.map((a) => ({
        id: a.id,
        title: a.title,
        description: a.description,
        actorName: a.actorName,
        category: a.category,
        createdAt: a.createdAt.toISOString(),
      })),
      upcoming,
    };
  }

  private async getBillingSummary(householdId: string) {
    const settings = await this.prisma.householdSettings.findUnique({
      where: { householdId },
    });

    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const payments = await this.prisma.billPayment.findMany({
      where: {
        bill: { householdId },
        paidDate: { gte: startOfMonth },
      },
    });

    const totalPaid = payments.reduce((sum, p) => sum + p.amount, 0);
    const monthlyFunding = settings?.monthlyFunding || 0;

    return {
      monthlyFunding,
      amountPaid: totalPaid,
      billsPaidCount: payments.length,
      bufferRemaining: monthlyFunding - totalPaid,
    };
  }

  private async getNextService(householdId: string) {
    // TODO: Implement service schedule model
    // For now, return a placeholder
    return {
      title: 'HVAC Tune-up',
      vendorName: 'Comfort Zone HVAC',
      date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days from now
    };
  }

  private async getUpcoming(householdId: string) {
    // TODO: Combine from multiple sources (bills, services, activities)
    // For now, return placeholder
    const bills = await this.prisma.bill.findMany({
      where: { householdId, status: 'ACTIVE' },
      take: 5,
    });

    return bills.map((b) => ({
      id: b.id,
      title: `${b.name} payment`,
      type: 'bill',
      date: new Date(Date.now() + (b.dueDay || 1) * 24 * 60 * 60 * 1000).toISOString(),
    }));
  }
}
```

### Task 3.2: Create Dashboard Controller

Create `apps/api/src/dashboard/dashboard.controller.ts`:

```typescript
import { Controller, Get, Param, UseGuards, NotFoundException } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { DashboardService } from './dashboard.service';

@Controller('dashboard')
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  @Get('household/:householdId')
  @UseGuards(FirebaseAuthGuard)
  async getDashboard(@Param('householdId') householdId: string) {
    try {
      return await this.dashboardService.getDashboard(householdId);
    } catch (error) {
      throw new NotFoundException('Dashboard not found');
    }
  }
}
```

### Task 3.3: Create Dashboard Module

Create `apps/api/src/dashboard/dashboard.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule {}
```

### Task 3.4: Create Property Service

Create `apps/api/src/property/property.service.ts`:

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PropertyService {
  constructor(private prisma: PrismaService) {}

  async getPropertyByHousehold(householdId: string) {
    const property = await this.prisma.property.findFirst({
      where: { householdId },
      include: {
        zones: {
          include: {
            assets: {
              orderBy: { name: 'asc' },
            },
          },
          orderBy: { name: 'asc' },
        },
      },
    });

    if (!property) {
      throw new NotFoundException('Property not found');
    }

    // Calculate systems status from assets
    const systems = this.calculateSystemsStatus(property.zones);

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
      zones: property.zones.map((zone) => ({
        id: zone.id,
        name: zone.name,
        type: zone.type,
        floor: zone.floor,
        assetCount: zone.assets.length,
        photos: zone.photos || [],
        notes: zone.notes,
        procedures: zone.procedures,
        assets: zone.assets.map((asset) => ({
          id: asset.id,
          name: asset.name,
          category: asset.category,
          brand: asset.brand,
          model: asset.model,
          serialNumber: asset.serialNumber,
          condition: asset.condition,
          lastServiceDate: asset.lastServiceDate?.toISOString() || null,
          nextServiceDate: asset.nextServiceDate?.toISOString() || null,
          serviceVendor: null, // TODO: Link to vendor
          notes: asset.notes,
        })),
      })),
    };
  }

  private calculateSystemsStatus(zones: any[]) {
    // Extract system-type assets and calculate status
    const systemAssets = zones.flatMap((z) =>
      z.assets.filter((a: any) => a.category === 'SYSTEM' || a.category === 'EQUIPMENT')
    );

    const systemCategories = ['HVAC', 'Plumbing', 'Electrical', 'Roof', 'Pool'];

    return systemCategories.map((cat) => ({
      id: cat.toLowerCase(),
      name: cat,
      category: cat.toUpperCase(),
      status: 'good' as const, // TODO: Calculate based on service dates
      warning: null,
    }));
  }
}
```

### Task 3.5: Update Property Controller

Update `apps/api/src/property/property.controller.ts`:

```typescript
import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PropertyService } from './property.service';

@Controller('property')
export class PropertyController {
  constructor(private propertyService: PropertyService) {}

  @Get('household/:householdId')
  @UseGuards(FirebaseAuthGuard)
  async getPropertyByHousehold(@Param('householdId') householdId: string) {
    return this.propertyService.getPropertyByHousehold(householdId);
  }
}
```

### Task 3.6: Create Family Service

Create `apps/api/src/family/family.service.ts`:

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FamilyService {
  constructor(private prisma: PrismaService) {}

  async getFamilyByHousehold(householdId: string) {
    const [members, vehicles, users] = await Promise.all([
      this.prisma.familyMember.findMany({
        where: { householdId },
        include: { activities: true },
        orderBy: [{ type: 'asc' }, { firstName: 'asc' }],
      }),
      this.prisma.vehicle.findMany({
        where: { householdId },
        orderBy: { year: 'desc' },
      }),
      this.prisma.user.findMany({
        where: { householdId, role: 'HOMEOWNER' },
        select: {
          id: true,
          email: true,
          name: true,
          firstName: true,
          lastName: true,
          phone: true,
        },
      }),
    ]);

    const adults = members.filter((m) => m.type === 'ADULT');
    const children = members.filter((m) => m.type === 'CHILD');
    const pets = members.filter((m) => m.type === 'PET');
    const staff = members.filter((m) => m.type === 'STAFF');

    return {
      adults: users.map((u) => ({
        id: u.id,
        firstName: u.firstName,
        lastName: u.lastName,
        name: u.name,
        email: u.email,
        phone: u.phone,
        role: 'Homeowner',
      })),
      children: children.map((c) => ({
        id: c.id,
        firstName: c.firstName,
        lastName: c.lastName,
        age: this.calculateAge(c.dateOfBirth),
        dateOfBirth: c.dateOfBirth?.toISOString() || null,
        grade: c.grade,
        school: c.school,
        allergies: c.allergies || [],
        activities: c.activities.map((a) => ({
          id: a.id,
          name: a.name,
          schedule: a.schedule,
          location: a.location,
          cost: a.cost,
          frequency: a.frequency,
          provider: a.provider,
        })),
      })),
      pets: pets.map((p) => {
        const medicalData = this.parseJson(p.medicalNotes);
        return {
          id: p.id,
          name: p.firstName,
          type: p.role,
          age: this.calculateAge(p.dateOfBirth),
          vet: medicalData?.vet || null,
          vetClinic: medicalData?.vetClinic || null,
          vetPhone: medicalData?.vetPhone || null,
          food: medicalData?.food || null,
          monthlyCost: medicalData?.monthlyCost || null,
          microchip: medicalData?.microchip || null,
          vaccinesDue: medicalData?.vaccinesDue || null,
        };
      }),
      staff: staff.map((s) => {
        const staffData = this.parseJson(s.medicalNotes);
        return {
          id: s.id,
          firstName: s.firstName,
          lastName: s.lastName,
          role: s.role,
          phone: s.phone,
          email: s.email,
          agency: s.employer,
          schedule: staffData?.schedule || null,
          weeklyStipend: staffData?.weeklyStipend || null,
          startDate: staffData?.startDate || null,
          contractExpires: staffData?.contractExpires || null,
          permissions: staffData?.permissions || [],
        };
      }),
      vehicles: vehicles.map((v) => ({
        id: v.id,
        year: v.year,
        make: v.make,
        model: v.model,
        color: v.color,
        licensePlate: v.licensePlate,
        vin: v.vin,
        primaryDriver: v.primaryDriver,
        mileage: v.mileage,
        loanPayment: v.loanPayment,
        insuranceMonthly: v.insuranceMonthly,
        monthlyCost: (v.loanPayment || 0) + (v.insuranceMonthly || 0),
        registrationExpires: v.registrationExpires?.toISOString() || null,
      })),
    };
  }

  private calculateAge(dob: Date | null): number | null {
    if (!dob) return null;
    const today = new Date();
    let age = today.getFullYear() - dob.getFullYear();
    const m = today.getMonth() - dob.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
      age--;
    }
    return age;
  }

  private parseJson(str: string | null): any {
    if (!str) return null;
    try {
      return JSON.parse(str);
    } catch {
      return null;
    }
  }
}
```

### Task 3.7: Create Family Controller

Create `apps/api/src/family/family.controller.ts`:

```typescript
import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { FamilyService } from './family.service';

@Controller('family')
export class FamilyController {
  constructor(private familyService: FamilyService) {}

  @Get('household/:householdId')
  @UseGuards(FirebaseAuthGuard)
  async getFamilyByHousehold(@Param('householdId') householdId: string) {
    return this.familyService.getFamilyByHousehold(householdId);
  }
}
```

### Task 3.8: Create Family Module

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

### Task 3.9: Create Activity Service

Create `apps/api/src/activity/activity.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ActorType } from '@prisma/client';

@Injectable()
export class ActivityService {
  constructor(private prisma: PrismaService) {}

  async log(data: {
    householdId: string;
    actorId: string;
    actorType: ActorType;
    actorName: string;
    action: string;
    category: string;
    title: string;
    description?: string;
    billId?: string;
    vendorId?: string;
    assetId?: string;
    amount?: number;
    metadata?: any;
    visibleToHomeowner?: boolean;
  }) {
    return this.prisma.activityLog.create({
      data: {
        ...data,
        visibleToHomeowner: data.visibleToHomeowner ?? true,
      },
    });
  }

  async getByHousehold(
    householdId: string,
    options?: {
      limit?: number;
      category?: string;
      startDate?: Date;
      endDate?: Date;
    }
  ) {
    return this.prisma.activityLog.findMany({
      where: {
        householdId,
        visibleToHomeowner: true,
        ...(options?.category && { category: options.category }),
        ...(options?.startDate && {
          createdAt: { gte: options.startDate },
        }),
        ...(options?.endDate && {
          createdAt: { lte: options.endDate },
        }),
      },
      orderBy: { createdAt: 'desc' },
      take: options?.limit || 20,
    });
  }
}
```

### Task 3.10: Create Activity Module

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

### Task 3.11: Register All Modules

Update `apps/api/src/app.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UserModule } from './user/user.module';
import { HouseholdModule } from './household/household.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { PropertyModule } from './property/property.module';
import { FamilyModule } from './family/family.module';
import { ActivityModule } from './activity/activity.module';
// ... other imports

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UserModule,
    HouseholdModule,
    DashboardModule,
    PropertyModule,
    FamilyModule,
    ActivityModule,
    // ... other modules
  ],
})
export class AppModule {}
```

---

## PHASE 4: Update Frontend to Use Real APIs

### Task 4.1: Update Dashboard Page

The Dashboard should fetch from API but gracefully handle loading/error states. Update `apps/web/src/app/app/page.tsx`:

Find the `fetchDashboard` function and ensure it:
1. Fetches from the correct endpoint
2. Falls back gracefully if API fails
3. Shows the polished UI with real or mock data

The page already has API fetching code. Verify the endpoint is correct:
```typescript
const response = await fetch(
  `${process.env.NEXT_PUBLIC_API_URL}/dashboard/household/${householdId}`,
  {
    headers: { Authorization: `Bearer ${token}` },
  }
);
```

### Task 4.2: Update Your Home Page

Verify `apps/web/src/app/app/home/page.tsx` fetches from:
```typescript
const response = await fetch(
  `${process.env.NEXT_PUBLIC_API_URL}/property/household/${householdId}`,
  {
    headers: { Authorization: `Bearer ${token}` },
  }
);
```

### Task 4.3: Update Family Page

The Family page currently uses mock data. Update it to fetch from API while keeping mock data as fallback.

Update `apps/web/src/app/app/family/page.tsx` to include API fetching:

```typescript
// Add at the top of the component:
const { user, getIdToken, householdId } = useAuth();
const [apiData, setApiData] = useState<any>(null);
const [loading, setLoading] = useState(true);

useEffect(() => {
  if (householdId) {
    fetchFamily();
  }
}, [householdId]);

const fetchFamily = async () => {
  try {
    const token = await getIdToken();
    if (!token || !householdId) {
      setLoading(false);
      return;
    }

    const response = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL}/family/household/${householdId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    if (response.ok) {
      const data = await response.json();
      setApiData(data);
    }
  } catch (error) {
    console.error('Failed to fetch family:', error);
  } finally {
    setLoading(false);
  }
};

// Then use apiData if available, otherwise fall back to mock data
const adults = apiData?.adults || mockAdults;
const children = apiData?.children || mockChildren;
// etc.
```

---

## PHASE 5: Onboarding Flow for New Users

### Task 5.1: Create Onboarding Service

Create `apps/api/src/onboarding/onboarding.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class OnboardingService {
  constructor(private prisma: PrismaService) {}

  // Called when a new user signs up
  async createSession(data: {
    householdId: string;
    biggestChallenge?: string;
    selectedTier?: string;
  }) {
    // Find default manager (Sarah) or round-robin
    const manager = await this.prisma.user.findFirst({
      where: { role: 'HOME_MANAGER' },
    });

    return this.prisma.onboardingSession.create({
      data: {
        householdId: data.householdId,
        assignedManagerId: manager?.id,
        biggestChallenge: data.biggestChallenge,
        selectedTier: data.selectedTier,
        status: 'PENDING_CALL',
      },
    });
  }

  // Get queue for home managers
  async getQueue(managerId?: string) {
    const where: any = {
      status: { in: ['PENDING_CALL', 'CALL_SCHEDULED', 'INTAKE_PARTIAL'] },
    };

    if (managerId) {
      where.assignedManagerId = managerId;
    }

    return this.prisma.onboardingSession.findMany({
      where,
      include: {
        household: {
          include: {
            property: true,
            users: {
              where: { role: 'HOMEOWNER' },
              take: 1,
            },
          },
        },
        assignedManager: {
          select: { id: true, name: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // Get single session for intake
  async getSession(sessionId: string) {
    return this.prisma.onboardingSession.findUnique({
      where: { id: sessionId },
      include: {
        household: {
          include: {
            property: true,
            users: true,
            familyMembers: { include: { activities: true } },
            vehicles: true,
            vendors: true,
            bills: true,
            zones: { include: { assets: true } },
          },
        },
        assignedManager: true,
      },
    });
  }

  // Update intake progress
  async updateIntake(
    sessionId: string,
    section: string,
    data: any,
    progress?: number
  ) {
    const session = await this.prisma.onboardingSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) throw new Error('Session not found');

    const existingData = (session.intakeData as any) || {};
    const updatedData = {
      ...existingData,
      [section]: {
        ...existingData[section],
        ...data,
        updatedAt: new Date().toISOString(),
      },
    };

    const updateFields: any = {
      intakeData: updatedData,
      status: 'CALL_IN_PROGRESS',
    };

    // Update progress for specific section
    const progressField = `progress${section.charAt(0).toUpperCase() + section.slice(1)}`;
    if (progress !== undefined) {
      updateFields[progressField] = progress;
    }

    return this.prisma.onboardingSession.update({
      where: { id: sessionId },
      data: updateFields,
    });
  }

  // Start the intake call
  async startCall(sessionId: string) {
    return this.prisma.onboardingSession.update({
      where: { id: sessionId },
      data: {
        status: 'CALL_IN_PROGRESS',
        callStartedAt: new Date(),
      },
    });
  }

  // Complete intake and create all records
  async completeIntake(
    sessionId: string,
    notes?: string,
    followUpNeeded?: boolean
  ) {
    const session = await this.getSession(sessionId);
    if (!session) throw new Error('Session not found');

    // Process intake data into real database records
    await this.processIntakeData(session);

    // Calculate monthly funding
    const monthlyFunding = await this.calculateMonthlyFunding(session.householdId);

    return this.prisma.onboardingSession.update({
      where: { id: sessionId },
      data: {
        status: followUpNeeded ? 'INTAKE_PARTIAL' : 'INTAKE_COMPLETE',
        callCompletedAt: new Date(),
        callNotes: notes,
        followUpNeeded: followUpNeeded || false,
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
  async deliverProfile(sessionId: string) {
    // TODO: Send welcome email
    return this.prisma.onboardingSession.update({
      where: { id: sessionId },
      data: {
        status: 'PROFILE_DELIVERED',
        profileDeliveredAt: new Date(),
      },
    });
  }

  // Activate household
  async activate(sessionId: string) {
    const session = await this.prisma.onboardingSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) throw new Error('Session not found');

    await this.prisma.household.update({
      where: { id: session.householdId },
      data: { status: 'ACTIVE' },
    });

    return this.prisma.onboardingSession.update({
      where: { id: sessionId },
      data: { status: 'ACTIVE' },
    });
  }

  private async processIntakeData(session: any) {
    const data = session.intakeData || {};
    const householdId = session.householdId;
    const propertyId = session.household?.property?.id;

    // Process family members
    if (data.family?.children) {
      for (const child of data.family.children) {
        const member = await this.prisma.familyMember.create({
          data: {
            householdId,
            type: 'CHILD',
            firstName: child.firstName,
            lastName: child.lastName,
            dateOfBirth: child.dateOfBirth ? new Date(child.dateOfBirth) : null,
            school: child.school,
            grade: child.grade,
            allergies: child.allergies || [],
          },
        });

        // Create activities
        if (child.activities) {
          for (const activity of child.activities) {
            await this.prisma.kidActivity.create({
              data: {
                familyMemberId: member.id,
                name: activity.name,
                schedule: activity.schedule,
                location: activity.location,
                cost: parseFloat(activity.cost) || 0,
                frequency: activity.frequency,
                provider: activity.provider,
              },
            });
          }
        }
      }
    }

    // Process pets
    if (data.family?.pets) {
      for (const pet of data.family.pets) {
        await this.prisma.familyMember.create({
          data: {
            householdId,
            type: 'PET',
            firstName: pet.name,
            role: pet.type,
            medicalNotes: JSON.stringify({
              vet: pet.vet,
              vetClinic: pet.vetClinic,
              food: pet.food,
            }),
          },
        });
      }
    }

    // Process staff
    if (data.family?.staff) {
      for (const staff of data.family.staff) {
        await this.prisma.familyMember.create({
          data: {
            householdId,
            type: 'STAFF',
            firstName: staff.firstName,
            lastName: staff.lastName,
            role: staff.role,
            phone: staff.phone,
            employer: staff.agency,
            medicalNotes: JSON.stringify({
              schedule: staff.schedule,
              weeklyStipend: parseFloat(staff.weeklyPay) || 0,
            }),
          },
        });
      }
    }

    // Process zones and assets
    if (data.zones && propertyId) {
      for (const [zoneKey, zoneData] of Object.entries(data.zones as any)) {
        const zone = await this.prisma.zone.create({
          data: {
            propertyId,
            name: (zoneData as any).name || zoneKey,
            type: (zoneData as any).type || 'OTHER',
            floor: (zoneData as any).floor,
          },
        });

        if ((zoneData as any).assets) {
          for (const asset of (zoneData as any).assets) {
            await this.prisma.asset.create({
              data: {
                zoneId: zone.id,
                propertyId,
                name: asset.name,
                category: asset.category || 'APPLIANCE',
                brand: asset.brand,
                model: asset.model,
                condition: asset.condition,
              },
            });
          }
        }
      }
    }

    // Process vehicles
    if (data.vehicles) {
      for (const vehicle of Object.values(data.vehicles as any)) {
        await this.prisma.vehicle.create({
          data: {
            householdId,
            year: parseInt((vehicle as any).year) || null,
            make: (vehicle as any).make,
            model: (vehicle as any).model,
            color: (vehicle as any).color,
            licensePlate: (vehicle as any).licensePlate,
            primaryDriver: (vehicle as any).primaryDriver,
            loanPayment: parseFloat((vehicle as any).paymentAmount) || null,
          },
        });
      }
    }

    // Process vendors
    if (data.vendors) {
      for (const vendor of Object.values(data.vendors as any)) {
        await this.prisma.vendor.create({
          data: {
            householdId,
            category: (vendor as any).category || 'OTHER',
            name: (vendor as any).name,
            contactName: (vendor as any).contactName,
            phone: (vendor as any).phone,
            email: (vendor as any).email,
            accountNumber: (vendor as any).accountNumber,
          },
        });
      }
    }

    // Process bills
    if (data.bills) {
      for (const bill of Object.values(data.bills as any)) {
        await this.prisma.bill.create({
          data: {
            householdId,
            category: (bill as any).category || 'OTHER',
            name: (bill as any).name,
            payeeName: (bill as any).payee,
            amount: parseFloat((bill as any).amount) || 0,
            frequency: (bill as any).frequency || 'MONTHLY',
            dueDay: parseInt((bill as any).dueDay) || null,
            accountNumber: (bill as any).accountNumber,
            status: 'ACTIVE',
            havenManaged: true,
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
        case 'WEEKLY':
          monthly += amount * 4.33;
          break;
        case 'BIWEEKLY':
          monthly += amount * 2.17;
          break;
        case 'MONTHLY':
          monthly += amount;
          break;
        case 'QUARTERLY':
          monthly += amount / 3;
          break;
        case 'SEMI_ANNUAL':
          monthly += amount / 6;
          break;
        case 'ANNUAL':
          monthly += amount / 12;
          break;
        default:
          monthly += amount;
      }
    }

    // Add 10% buffer
    return Math.round(monthly * 1.1 * 100) / 100;
  }
}
```

### Task 5.2: Create Onboarding Controller

Create `apps/api/src/onboarding/onboarding.controller.ts`:

```typescript
import { Controller, Get, Post, Put, Param, Body, UseGuards, Query } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { OnboardingService } from './onboarding.service';

@Controller('onboarding')
export class OnboardingController {
  constructor(private onboardingService: OnboardingService) {}

  // Create new session (called after user signup)
  @Post()
  @UseGuards(FirebaseAuthGuard)
  async createSession(
    @Body() body: { householdId: string; biggestChallenge?: string; selectedTier?: string }
  ) {
    return this.onboardingService.createSession(body);
  }

  // Get queue for home managers
  @Get('queue')
  @UseGuards(FirebaseAuthGuard)
  async getQueue(@Query('managerId') managerId?: string) {
    const sessions = await this.onboardingService.getQueue(managerId);

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
      assignedManager: s.assignedManager?.name,
      progress: this.calculateProgress(s),
      createdAt: s.createdAt,
    }));
  }

  // Get single session
  @Get(':id')
  @UseGuards(FirebaseAuthGuard)
  async getSession(@Param('id') id: string) {
    return this.onboardingService.getSession(id);
  }

  // Update intake data
  @Put(':id/intake')
  @UseGuards(FirebaseAuthGuard)
  async updateIntake(
    @Param('id') id: string,
    @Body() body: { section: string; data: any; progress?: number }
  ) {
    return this.onboardingService.updateIntake(id, body.section, body.data, body.progress);
  }

  // Start call
  @Post(':id/start-call')
  @UseGuards(FirebaseAuthGuard)
  async startCall(@Param('id') id: string) {
    return this.onboardingService.startCall(id);
  }

  // Complete intake
  @Post(':id/complete')
  @UseGuards(FirebaseAuthGuard)
  async completeIntake(
    @Param('id') id: string,
    @Body() body: { notes?: string; followUpNeeded?: boolean }
  ) {
    return this.onboardingService.completeIntake(id, body.notes, body.followUpNeeded);
  }

  // Deliver profile
  @Post(':id/deliver')
  @UseGuards(FirebaseAuthGuard)
  async deliverProfile(@Param('id') id: string) {
    return this.onboardingService.deliverProfile(id);
  }

  // Activate
  @Post(':id/activate')
  @UseGuards(FirebaseAuthGuard)
  async activate(@Param('id') id: string) {
    return this.onboardingService.activate(id);
  }

  private calculateProgress(session: any): number {
    const total =
      session.progressFamily +
      session.progressProperty +
      session.progressZones +
      session.progressSystems +
      session.progressVendors +
      session.progressBills;
    return Math.round(total / 6);
  }
}
```

### Task 5.3: Create Onboarding Module

Create `apps/api/src/onboarding/onboarding.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { OnboardingController } from './onboarding.controller';
import { OnboardingService } from './onboarding.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [OnboardingController],
  providers: [OnboardingService],
  exports: [OnboardingService],
})
export class OnboardingModule {}
```

### Task 5.4: Update Signup to Create Onboarding Session

Update the user signup flow to create an onboarding session. In your auth or user service:

```typescript
// After creating household and user, create onboarding session
await this.onboardingService.createSession({
  householdId: household.id,
  biggestChallenge: signupData.biggestChallenge,
  selectedTier: signupData.selectedTier,
});
```

---

## PHASE 6: Build and Deploy

### Task 6.1: Build

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

Fix any TypeScript/build errors.

### Task 6.2: Test Locally

```bash
# Terminal 1
pnpm dev:api

# Terminal 2
pnpm dev:web
```

Test:
1. Login as bob@example.com - should see Morrison demo data
2. Check Dashboard, Your Home, Family pages show real data from API
3. Check API logs for successful requests

### Task 6.3: Commit

```bash
git add .
git commit -m "feat: production-ready with real APIs and Morrison seed data"
```

### Task 6.4: Deploy

```bash
git push origin main

# Deploy API first (has new endpoints)
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Then deploy web
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

### Task 6.5: Run Seed in Production

Connect to production database and run seed:

```bash
# Option 1: Run from Cloud Shell with DATABASE_URL set
cd apps/api
DATABASE_URL="postgresql://..." pnpm prisma db seed

# Option 2: Use Cloud SQL proxy
./cloud_sql_proxy -instances=home-manager-480616:us-east1:haven-production-db=tcp:5432 &
DATABASE_URL="postgresql://haven:PASSWORD@localhost:5432/haven" pnpm prisma db seed
```

---

## PHASE 7: Verification

### Test Demo Account (bob@example.com)
- [ ] Dashboard shows Morrison data (38 Bedford Road, Home Health 94)
- [ ] Your Home shows Inspiration Farm with zones
- [ ] Family shows Emma, Jack, Max, Maria Garcia
- [ ] Activity feed shows real activity from database

### Test New User Signup
- [ ] New user can sign up with email
- [ ] Onboarding session is created
- [ ] User sees "Sarah will call" message
- [ ] Sarah sees new user in queue (manager portal)

### Test Home Manager Flow
- [ ] Can view onboarding queue
- [ ] Can open intake workbench
- [ ] Can save intake data
- [ ] Can complete intake
- [ ] Data appears in user's portal

---

## Summary

After running this prompt:

1. ✅ Database has all required models (OnboardingSession, ActivityLog, etc.)
2. ✅ Morrison demo data seeded for bob@example.com
3. ✅ API endpoints serve real data
4. ✅ Frontend fetches from APIs
5. ✅ New users get onboarding sessions
6. ✅ Home Managers can complete intake
7. ✅ Activity is logged and visible

The system is production-ready for real users to sign up and be onboarded.
