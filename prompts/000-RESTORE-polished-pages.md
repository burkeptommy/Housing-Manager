# RESTORE: Polished Pages & Morrison Demo Data

**Created:** December 27, 2024  
**Priority:** CRITICAL - Run this first before any other work

---

## Overview

Recent commits overwrote polished demo pages with broken API-connected versions. This prompt restores everything to the correct state.

**What was broken:**
- Dashboard shows error "Failed to load dashboard"
- Your Home shows "Bob's Villa" at wrong address
- Family shows wrong names (Sarah Morrison, Maria Santos)
- Demo data inconsistent throughout

**What this restores:**
- Polished Dashboard with Morrison data and rich features
- Your Home with tabs (Overview, Maintenance, Systems, Vendors, Vehicles, Financial, Documents)
- Family with smart alerts, logistics, monthly costs breakdown
- Correct Morrison demo data everywhere

---

## PHASE 1: Git Restore Pages

### Task 1.1: Restore Dashboard Page

```bash
cd /Users/tomburke/Projects/Housing-Manager
git checkout 444f6a721cd339b3ef650da9a15366c873d531e8 -- apps/web/src/app/app/page.tsx
```

### Task 1.2: Restore Your Home Page

```bash
git checkout 444f6a721cd339b3ef650da9a15366c873d531e8 -- apps/web/src/app/app/home/page.tsx
```

### Task 1.3: Restore Family Page

```bash
git checkout 444f6a721cd339b3ef650da9a15366c873d531e8 -- apps/web/src/app/app/family/page.tsx
```

### Task 1.4: Verify Restorations

After restoring, read each file and confirm:
- Dashboard has mock data with "Bob" greeting
- Your Home has tabs and shows "38 Bedford Road"
- Family has Smart Alerts, Today's Logistics, Monthly Lifestyle Fixed Costs sections

---

## PHASE 2: Fix Any Demo Data Inconsistencies

After restoring, scan each page for demo data and ensure it matches this EXACT canonical data:

### Property
```
Name: Inspiration Farm
Address: 38 Bedford Road, Greenwich, CT 06831
Specs: 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres
Year Built: 1998
Home Health: 94/100 (Excellent)
```

### Adults
```
Bob Morrison
- Role: Head of Household
- Email: bob@example.com
- Phone: (203) 555-0101
- Employer: Morrison Capital Partners
- Vehicle: 2023 Tesla Model Y (Midnight Silver, GRN 1234)

Alice Morrison  
- Role: Spouse
- Email: alice@example.com
- Phone: (203) 555-0102
- Employer: Greenwich Hospital, Pediatric NP
- Vehicles: 2022 Toyota Highlander (Pearl White, XYZ 5678), 2024 Mercedes GLE 450 (Obsidian Black, EF-11111)
```

### Children
```
Emma Morrison
- Age: 12 years old
- Grade: 7th Grade
- School: Greenwich Country Day School ($4,500/mo)
- Allergies: Peanuts, Tree nuts
- Activities: Soccer (Tue/Thu), Piano (Wed)

Jack Morrison
- Age: 8 years old
- Grade: 3rd Grade  
- School: North Street School
- Activities: Little League, Piano, Art class
```

### Pet
```
Max
- Type: Golden Retriever
- Age: 4 years old
- Vet: Dr. Williams, Westlake Animal Hospital
- Food: Blue Buffalo (30 lbs/mo)
- Monthly cost: $150
- Microchip: 985141001234567
```

### Household Staff
```
Maria Garcia (NOT Maria Santos)
- Role: Nanny
- Agency: Greenwich Elite Nannies
- Phone: (203) 555-0199
- Weekly stipend: $1,500
- Schedule: Mon-Thu 7am-6pm, Fri 7am-3pm
- Since: Jun 2023
```

### Vehicles (with costs)
```
Bob's Tesla - 2023 Tesla Model Y
- Color: Midnight Silver
- Plate: GRN 1234
- Mileage: 24,500
- Monthly Cost: $895

Family Highlander - 2022 Toyota Highlander
- Color: Pearl White
- Plate: XYZ 5678
- Mileage: 35,200
- Primary Driver: Alice
- Monthly Cost: $775

Alice's Mercedes - 2024 Mercedes-Benz GLE 450
- Color: Obsidian Black Metallic
- Plate: EF-11111
- Mileage: 8,750
- Primary Driver: Alice
- Monthly Cost: $1,082
```

### Monthly Lifestyle Fixed Costs
```
Total: $17,422
- Club Memberships: $2,550
- Education & Activities: $5,475
- Childcare: $6,495
- Pet Care: $150
- Auto (Loans + Insurance): $2,752
```

### Haven Team
```
Home Manager: Sarah Chen (sarah@haven.app)
Primary Handyman: Mike Rodriguez (mike@haven.app)
```

### Task 2.1: Update Dashboard Mock Data

Open `apps/web/src/app/app/page.tsx` and verify/fix:
- Greeting shows "Bob" (not any other name)
- Property address shows "38 Bedford Road, Greenwich, CT 06831"
- Home Health is 94
- Sarah Chen is the manager
- Next service references real vendors

### Task 2.2: Update Your Home Mock Data

Open `apps/web/src/app/app/home/page.tsx` and verify/fix:
- Property name: "Inspiration Farm" (NOT "Bob's Villa")
- Address: "38 Bedford Road, Greenwich, CT 06831"
- Specs: 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres
- All systems use realistic Greenwich CT vendors

### Task 2.3: Update Family Mock Data

Open `apps/web/src/app/app/family/page.tsx` and verify/fix all the data above is correct:
- Adults: Bob Morrison, Alice Morrison (NOT Sarah Morrison)
- Children: Emma (12), Jack (8) - NOT Jake, NOT different ages
- Staff: Maria Garcia (NOT Maria Santos)
- Pet: Max, Golden Retriever, 4 years old
- All monthly costs match the breakdown above
- Vehicle costs match ($895, $775, $1,082)

---

## PHASE 3: Verify Your Home Has Tabs

The Your Home page should have these tabs in the header:
- Overview (default, with badge showing maintenance count)
- Maintenance (with number badge)
- Systems
- Vendors  
- Vehicles
- Financial
- Documents

If tabs are missing after restore, check if they were added in a commit after `444f6a721cd339b3ef650da9a15366c873d531e8` and restore from the correct commit, or add them.

The tabs should look like this in the UI:
```
[Overview] [Maintenance 4] [Systems] [Vendors] [Vehicles] [Financial] [Documents]
```

With the selected tab having a border-bottom or background highlight.

---

## PHASE 4: Update Seed Data

The database seed file should create the Morrison family. Update `apps/api/prisma/seed.ts`:

```typescript
import { PrismaClient, UserRole, FamilyMemberType, BillFrequency, BillCategory, VehicleType } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database with Morrison family demo data...');

  // Clean existing data
  await prisma.activityLog.deleteMany();
  await prisma.billPayment.deleteMany();
  await prisma.bill.deleteMany();
  await prisma.kidActivity.deleteMany();
  await prisma.familyMember.deleteMany();
  await prisma.vehicle.deleteMany();
  await prisma.asset.deleteMany();
  await prisma.zone.deleteMany();
  await prisma.vendor.deleteMany();
  await prisma.property.deleteMany();
  await prisma.user.deleteMany();
  await prisma.household.deleteMany();

  // Create Morrison Household
  const household = await prisma.household.create({
    data: {
      name: 'The Morrison Family',
      tier: 'HAVEN',
      status: 'ACTIVE',
    },
  });
  console.log('✓ Created household:', household.name);

  // Create Property
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
    },
  });
  console.log('✓ Created property:', property.name);

  // Create Users
  const passwordHash = await bcrypt.hash('Bob123!', 10);
  
  const bob = await prisma.user.create({
    data: {
      email: 'bob@example.com',
      passwordHash,
      name: 'Bob Morrison',
      firstName: 'Bob',
      lastName: 'Morrison',
      phone: '(203) 555-0101',
      role: UserRole.HOMEOWNER,
      householdId: household.id,
    },
  });
  console.log('✓ Created user:', bob.name);

  const alice = await prisma.user.create({
    data: {
      email: 'alice@example.com',
      passwordHash: await bcrypt.hash('Alice123!', 10),
      name: 'Alice Morrison',
      firstName: 'Alice',
      lastName: 'Morrison', 
      phone: '(203) 555-0102',
      role: UserRole.HOMEOWNER,
      householdId: household.id,
    },
  });
  console.log('✓ Created user:', alice.name);

  // Create Home Manager - Sarah Chen
  const sarah = await prisma.user.create({
    data: {
      email: 'sarah@haven.app',
      passwordHash: await bcrypt.hash('Manager123!', 10),
      name: 'Sarah Chen',
      firstName: 'Sarah',
      lastName: 'Chen',
      role: UserRole.HOME_MANAGER,
    },
  });
  console.log('✓ Created manager:', sarah.name);

  // Create Handyman - Mike Rodriguez
  const mike = await prisma.user.create({
    data: {
      email: 'mike@haven.app',
      passwordHash: await bcrypt.hash('Handy123!', 10),
      name: 'Mike Rodriguez',
      firstName: 'Mike',
      lastName: 'Rodriguez',
      role: UserRole.HANDYMAN,
    },
  });
  console.log('✓ Created handyman:', mike.name);

  // Family Members - Children
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
        schedule: 'Tue/Thu 4-6pm',
        location: 'Greenwich Polo Club Fields',
        cost: 450,
        frequency: 'quarterly',
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
  console.log('✓ Created children: Emma, Jack');

  // Pet - Max
  const max = await prisma.familyMember.create({
    data: {
      householdId: household.id,
      type: FamilyMemberType.PET,
      firstName: 'Max',
      role: 'Golden Retriever',
      dateOfBirth: new Date('2020-09-10'),
      medicalNotes: 'Vet: Dr. Williams, Westlake Animal Hospital\nFood: Blue Buffalo (30 lbs/mo)\nMicrochip: 985141001234567',
    },
  });
  console.log('✓ Created pet:', max.firstName);

  // Staff - Maria Garcia
  const maria = await prisma.familyMember.create({
    data: {
      householdId: household.id,
      type: FamilyMemberType.STAFF,
      firstName: 'Maria',
      lastName: 'Garcia',
      role: 'Nanny',
      phone: '(203) 555-0199',
      employer: 'Greenwich Elite Nannies',
      medicalNotes: 'Schedule: Mon-Thu 7am-6pm, Fri 7am-3pm\nWeekly Stipend: $1,500\nSince: Jun 2023',
    },
  });
  console.log('✓ Created staff:', maria.firstName, maria.lastName);

  // Vehicles
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
      },
    ],
  });
  console.log('✓ Created 3 vehicles');

  // Zones
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
      { zoneId: kitchen.id, propertyId: property.id, name: 'Refrigerator', category: 'APPLIANCE', brand: 'Sub-Zero', condition: 'Excellent' },
      { zoneId: kitchen.id, propertyId: property.id, name: 'Dishwasher', category: 'APPLIANCE', brand: 'Bosch', condition: 'Excellent' },
      { zoneId: kitchen.id, propertyId: property.id, name: 'Range/Oven', category: 'APPLIANCE', brand: 'Wolf', condition: 'Excellent' },
    ],
  });

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
      { zoneId: laundry.id, propertyId: property.id, name: 'Washer', category: 'APPLIANCE', brand: 'LG', condition: 'Excellent' },
      { zoneId: laundry.id, propertyId: property.id, name: 'Dryer', category: 'APPLIANCE', brand: 'LG', condition: 'Excellent' },
    ],
  });

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
      { zoneId: mechanical.id, propertyId: property.id, name: 'HVAC System', category: 'SYSTEM', brand: 'Carrier', condition: 'Good' },
      { zoneId: mechanical.id, propertyId: property.id, name: 'Water Heater', category: 'SYSTEM', brand: 'Rheem', condition: 'Good' },
      { zoneId: mechanical.id, propertyId: property.id, name: 'Electrical Panel', category: 'SYSTEM', brand: 'Square D', condition: 'Good' },
    ],
  });

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
      { zoneId: backyard.id, propertyId: property.id, name: 'Roof', category: 'STRUCTURE', condition: 'Good' },
      { zoneId: backyard.id, propertyId: property.id, name: 'Septic System', category: 'SYSTEM', condition: 'Good' },
    ],
  });
  console.log('✓ Created 5 zones with assets');

  // Vendors
  await prisma.vendor.createMany({
    data: [
      { householdId: household.id, category: 'HVAC', name: 'Comfort Zone HVAC', phone: '(203) 555-1001', email: 'service@comfortzone.example.com' },
      { householdId: household.id, category: 'PLUMBING', name: "Mike's Plumbing", phone: '(203) 555-1002', email: 'mike@mikesplumbing.example.com' },
      { householdId: household.id, category: 'ELECTRICAL', name: 'Greenwich Electric', phone: '(203) 555-1003' },
      { householdId: household.id, category: 'ROOFING', name: 'Ace Roofing Co', phone: '(203) 555-1004', email: 'vendor@aceroofing.example.com' },
      { householdId: household.id, category: 'LANDSCAPING', name: 'Green Thumb Lawn Care', phone: '(203) 555-1005' },
    ],
  });
  console.log('✓ Created 5 vendors');

  // Bills
  await prisma.bill.createMany({
    data: [
      // Housing
      { householdId: household.id, category: BillCategory.MORTGAGE, name: 'Mortgage', payeeName: 'Chase Home Lending', amount: 3450, frequency: BillFrequency.MONTHLY, dueDay: 1, accountNumber: '****4521' },
      { householdId: household.id, category: BillCategory.HOME_INSURANCE, name: 'Home Insurance', payeeName: 'Allstate', amount: 8124, frequency: BillFrequency.ANNUAL, accountNumber: 'POL-789456' },
      { householdId: household.id, category: BillCategory.PROPERTY_TAX, name: 'Property Tax', payeeName: 'Town of Greenwich', amount: 24000, frequency: BillFrequency.SEMI_ANNUAL },
      
      // Utilities
      { householdId: household.id, category: BillCategory.ELECTRIC, name: 'Electric', payeeName: 'Eversource', amount: 187, frequency: BillFrequency.MONTHLY, accountNumber: '51-234-5678' },
      { householdId: household.id, category: BillCategory.GAS, name: 'Gas', payeeName: 'Eversource', amount: 145, frequency: BillFrequency.MONTHLY, accountNumber: '51-234-5679' },
      { householdId: household.id, category: BillCategory.WATER_SEWER, name: 'Water/Sewer', payeeName: 'Town of Greenwich', amount: 215, frequency: BillFrequency.MONTHLY },
      
      // Telecom
      { householdId: household.id, category: BillCategory.INTERNET, name: 'Internet', payeeName: 'Optimum', amount: 89, frequency: BillFrequency.MONTHLY, accountNumber: '07-123456789' },
      { householdId: household.id, category: BillCategory.CELL_PHONE, name: 'Cell Phones', payeeName: 'Verizon', amount: 323, frequency: BillFrequency.MONTHLY, accountNumber: '****7890' },
      
      // Education
      { householdId: household.id, category: BillCategory.SCHOOL_TUITION, name: 'Emma - Greenwich Country Day', payeeName: 'Greenwich Country Day School', amount: 4500, frequency: BillFrequency.MONTHLY },
      
      // Childcare
      { householdId: household.id, category: BillCategory.CHILDCARE, name: 'Nanny - Maria Garcia', payeeName: 'Maria Garcia', amount: 6000, frequency: BillFrequency.MONTHLY },
    ],
  });
  console.log('✓ Created bills');

  console.log('\n✅ Seed completed successfully!');
  console.log('\nDemo Credentials:');
  console.log('  Homeowner: bob@example.com / Bob123!');
  console.log('  Manager: sarah@haven.app / Manager123!');
  console.log('  Handyman: mike@haven.app / Handy123!');
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

---

## PHASE 5: Build and Deploy

### Task 5.1: Commit Restored Pages

```bash
cd /Users/tomburke/Projects/Housing-Manager
git add .
git commit -m "restore: polished demo pages and Morrison seed data"
```

### Task 5.2: Build and Verify

```bash
pnpm build
```

Fix any build errors before proceeding.

### Task 5.3: Push and Deploy

```bash
git push origin main

# Deploy web only (pages are frontend)
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## PHASE 6: Verification Checklist

After deployment, manually verify each page at https://havenhome.dev:

### Dashboard (`/app`)
- [ ] Shows "Good afternoon, Bob" (or appropriate time greeting)
- [ ] Shows weather icon with temperature (68°)
- [ ] Shows Home Health 94% Excellent
- [ ] Shows "Items Handled: 4" and "Next Service: Jan 7"
- [ ] Shows Today's Notes section (3 items)
- [ ] Shows "Needs Your Decision" card for roof repair ($1,200)
- [ ] Shows "Respond When You Can" card for nanny contract
- [ ] Shows Sarah Chen card with "Currently Working On" tasks
- [ ] Shows Today's Logistics with family members (Bob, Alice, Emma, Jack, Max)
- [ ] Shows House Health 94% card with Sarah's current tasks
- [ ] Shows Quick Actions (Messages, Statement, Calendar)
- [ ] Shows Sarah Chen footer bar with Call/Chat buttons

### Your Home (`/app/home`)
- [ ] Shows "38 Bedford Road" in header (NOT "Bob's Villa")
- [ ] Shows "Greenwich, CT 06831"
- [ ] Shows 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres
- [ ] Shows tabs: Overview, Maintenance (4), Systems, Vendors, Vehicles, Financial, Documents
- [ ] Shows Home Health 94/100 donut chart with "Excellent" label
- [ ] Shows breakdown: Systems needing attention (3), Overdue maintenance (1), On track (12)
- [ ] Shows stats: 16 Systems Tracked, 5 Vendors, $3,400+ Saved, 37 Documents
- [ ] Shows Systems Status list with progress bars
- [ ] Shows Upcoming section with scheduled services
- [ ] Shows Recent Activity feed

### Family (`/app/family`)
- [ ] Shows "Family" header with "Emergency Card" and "Add Member" buttons
- [ ] Shows Smart Alerts section (5 alerts):
  - Maria Garcia contract expires
  - Emma's tuition due
  - Max's vaccines due
  - Bob's Tesla registration expires
  - Emma's sizes outdated
- [ ] Shows Today's Logistics with pickups/drop-offs
- [ ] Shows Monthly Lifestyle Fixed Costs: $17,422 breakdown
- [ ] Shows Adults (2): Bob Morrison, Alice Morrison
- [ ] Shows Children (2): Emma (12, 7th Grade), Jack (8, 3rd Grade)
- [ ] Shows Emma's allergies highlighted (Peanuts, Tree nuts)
- [ ] Shows Emma's school: Greenwich Country Day ($4,500/mo)
- [ ] Shows Pets (1): Max, Golden Retriever, 4 years
- [ ] Shows Vehicles (3) with monthly costs
- [ ] Shows Household Staff (1): Maria Garcia with schedule grid

---

## Summary

This prompt restores:
1. ✅ Dashboard page to polished version with rich features
2. ✅ Your Home page with tabs and correct address
3. ✅ Family page with smart alerts and logistics
4. ✅ Seed data with complete Morrison family
5. ✅ Consistent demo data throughout

After running this, the app will be back to demo-ready state with all the polished features intact.
