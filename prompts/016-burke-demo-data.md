# SETUP BURKE HOUSEHOLD DEMO DATA - ESSENTIALS TIER

## OVERVIEW

Create a fully populated demo household for the Essentials ($39) tier to:
1. Bypass onboarding (data already exists)
2. Test Alfred AI assistant
3. Test all CRUD operations (systems, vendors, bills, family, vehicles, pets)

---

## HOUSEHOLD DETAILS

| Field | Value |
|-------|-------|
| **Household Name** | The Burke Family |
| **Address** | 146 Putnam Park Rd, Bethel, CT 06801 |
| **Property Type** | SINGLE_FAMILY |
| **Subscription** | ESSENTIALS ($39/mo) |
| **Onboarding Status** | COMPLETED |

---

## FAMILY MEMBERS

### Primary User (Head of Household)
| Field | Value |
|-------|-------|
| Name | Tom Burke |
| Email | tom@example.com |
| Password | Tom123! |
| Role | OWNER |

### Spouse
| Field | Value |
|-------|-------|
| Name | Mindy Burke |
| Email | mindy@example.com |
| Role | MEMBER |

### Children
| Name | Age | Notes |
|------|-----|-------|
| Blake Burke | 3 years | Daughter |
| Valerie Burke | 1 month | Daughter, infant |

### Staff
| Name | Role | Notes |
|------|------|-------|
| Hevellyn Silva | Au Pair | Lives in house |

---

## PETS

### Dog 1: Ryder
| Field | Value |
|-------|-------|
| Name | Ryder |
| Type | DOG |
| Breed | Australian Shepherd |
| Age | 9 years |
| Size | MEDIUM |

### Dog 2: Yoda
| Field | Value |
|-------|-------|
| Name | Yoda |
| Type | DOG |
| Breed | Black Lab Mix |
| Age | 5 years |
| Size | LARGE |

---

## VEHICLES

### Vehicle 1: Mercedes
| Field | Value |
|-------|-------|
| Year | 2019 |
| Make | Mercedes-Benz |
| Model | GLS |
| Type | SUV |
| Nickname | The Mercedes |
| Loan | None (paid off) |

### Vehicle 2: Audi
| Field | Value |
|-------|-------|
| Year | 2016 |
| Make | Audi |
| Model | Q3 |
| Type | SUV |
| Nickname | The Audi |
| Loan | None (paid off) |

---

## HOME SYSTEMS

### Heating: Oil Furnace
| Field | Value |
|-------|-------|
| Type | FURNACE |
| Name | Oil Furnace |
| Fuel | Oil |
| Notes | Oil heating system |
| Service Interval | 12 months |

### Hot Water: Tank
| Field | Value |
|-------|-------|
| Type | WATER_HEATER |
| Name | Hot Water Tank |
| Notes | Standard tank water heater |

### Generator
| Field | Value |
|-------|-------|
| Type | GENERATOR |
| Name | Backup Generator |
| Fuel | Propane |
| Notes | Propane tanks for fuel |

### Chimneys (x2)
| Field | Value |
|-------|-------|
| Type | FIREPLACE |
| Name | Chimney 1 / Chimney 2 |
| Notes | Two chimneys, annual cleaning recommended |

### Pool
| Field | Value |
|-------|-------|
| Has Pool | NO |

---

## VENDORS & BILLS

### Utility: Eversource (Electric)
| Field | Value |
|-------|-------|
| Vendor Name | Eversource |
| Category | ELECTRIC |
| Billing Frequency | MONTHLY |
| Typical Amount | ~$200 |
| Autopay | Yes |

### Mortgage: Capital One
| Field | Value |
|-------|-------|
| Vendor Name | Capital One |
| Category | MORTGAGE |
| Billing Frequency | MONTHLY |
| Notes | Primary mortgage |

### Cleaning: Renata Cleaning Services
| Field | Value |
|-------|-------|
| Vendor Name | Renata Cleaning Services |
| Category | CLEANING |
| Billing Frequency | BIWEEKLY |
| Payment Method | Cash/Check ONLY |
| Notes | Comes every 2 weeks, only accepts cash or check |

### Landscaping & Plowing: Blue Fox Landscaping
| Field | Value |
|-------|-------|
| Vendor Name | Blue Fox Landscaping |
| Category | LANDSCAPING |
| Services | Lawn care, Snow plowing |
| Billing Frequency | MONTHLY (seasonal) |

### Oil Delivery (TBD)
| Field | Value |
|-------|-------|
| Vendor Name | (To be added via Alfred) |
| Category | GAS (oil) |
| Notes | User can ask Alfred to help find oil delivery |

---

## STEP 1: Create Database Seed Script

Create or update `/Users/tomburke/Projects/Housing-Manager/apps/api/prisma/seed-burke.ts`:

```typescript
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function seedBurkeHousehold() {
  console.log('🏠 Seeding Burke Household Demo Data...');

  // Hash passwords
  const passwordHash = await bcrypt.hash('Tom123!', 10);
  const mindyPasswordHash = await bcrypt.hash('Mindy123!', 10);

  // ==========================================================================
  // 1. CREATE USERS
  // ==========================================================================
  
  const tom = await prisma.user.upsert({
    where: { email: 'tom@example.com' },
    update: {},
    create: {
      email: 'tom@example.com',
      passwordHash,
      firstName: 'Tom',
      lastName: 'Burke',
      role: 'HOMEOWNER',
      isActive: true,
      emailVerified: true,
    },
  });
  console.log('✅ Created user: Tom Burke');

  const mindy = await prisma.user.upsert({
    where: { email: 'mindy@example.com' },
    update: {},
    create: {
      email: 'mindy@example.com',
      passwordHash: mindyPasswordHash,
      firstName: 'Mindy',
      lastName: 'Burke',
      role: 'HOMEOWNER',
      isActive: true,
      emailVerified: true,
    },
  });
  console.log('✅ Created user: Mindy Burke');

  // ==========================================================================
  // 2. CREATE HOUSEHOLD
  // ==========================================================================
  
  const household = await prisma.household.upsert({
    where: { id: 'burke-household-demo' },
    update: {
      name: 'The Burke Family',
      subscriptionPlan: 'ESSENTIALS',
      subscriptionStatus: 'ACTIVE',
    },
    create: {
      id: 'burke-household-demo',
      name: 'The Burke Family',
      description: 'Demo household for Essentials tier',
      ownerId: tom.id,
      subscriptionPlan: 'ESSENTIALS',
      subscriptionStatus: 'ACTIVE',
    },
  });
  console.log('✅ Created household: The Burke Family');

  // ==========================================================================
  // 3. CREATE HOUSEHOLD MEMBERSHIPS
  // ==========================================================================
  
  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: household.id,
        userId: tom.id,
      },
    },
    update: { role: 'OWNER', status: 'ACTIVE' },
    create: {
      householdId: household.id,
      userId: tom.id,
      role: 'OWNER',
      status: 'ACTIVE',
    },
  });

  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: household.id,
        userId: mindy.id,
      },
    },
    update: { role: 'MEMBER', status: 'ACTIVE' },
    create: {
      householdId: household.id,
      userId: mindy.id,
      role: 'MEMBER',
      status: 'ACTIVE',
    },
  });
  console.log('✅ Created household memberships');

  // ==========================================================================
  // 4. CREATE HOME PROFILE
  // ==========================================================================
  
  await prisma.homeProfile.upsert({
    where: { householdId: household.id },
    update: {},
    create: {
      householdId: household.id,
      propertyType: 'SINGLE_FAMILY',
      addressLine1: '146 Putnam Park Rd',
      city: 'Bethel',
      state: 'CT',
      postalCode: '06801',
      country: 'USA',
      // Add more details as available
      bedrooms: 4,
      bathrooms: 3,
      yearBuilt: 1990,
    },
  });
  console.log('✅ Created home profile');

  // ==========================================================================
  // 5. CREATE FAMILY MEMBERS (Non-User)
  // ==========================================================================
  
  // Note: FamilyMember model may need to be created if it doesn't exist
  // For now, we'll use a JSON field or create the model
  
  const familyMembers = [
    { displayName: 'Blake Burke', role: 'child', profile: { birthday: '2022-01-15', notes: 'Daughter, 3 years old' } },
    { displayName: 'Valerie Burke', role: 'child', profile: { birthday: '2024-12-01', notes: 'Daughter, infant (1 month)' } },
    { displayName: 'Hevellyn Silva', role: 'staff', profile: { notes: 'Au Pair, lives in house' } },
  ];

  for (const member of familyMembers) {
    await prisma.familyMember.upsert({
      where: {
        householdId_displayName: {
          householdId: household.id,
          displayName: member.displayName,
        },
      },
      update: {},
      create: {
        householdId: household.id,
        displayName: member.displayName,
        role: member.role,
        profile: member.profile,
        isActive: true,
      },
    });
  }
  console.log('✅ Created family members: Blake, Valerie, Hevellyn');

  // ==========================================================================
  // 6. CREATE PETS
  // ==========================================================================
  
  await prisma.pet.upsert({
    where: {
      householdId_name: {
        householdId: household.id,
        name: 'Ryder',
      },
    },
    update: {},
    create: {
      householdId: household.id,
      name: 'Ryder',
      type: 'DOG',
      breed: 'Australian Shepherd',
      size: 'MEDIUM',
      birthday: new Date('2016-01-01'), // ~9 years old
      isActive: true,
    },
  });

  await prisma.pet.upsert({
    where: {
      householdId_name: {
        householdId: household.id,
        name: 'Yoda',
      },
    },
    update: {},
    create: {
      householdId: household.id,
      name: 'Yoda',
      type: 'DOG',
      breed: 'Black Lab Mix',
      size: 'LARGE',
      birthday: new Date('2020-01-01'), // ~5 years old
      isActive: true,
    },
  });
  console.log('✅ Created pets: Ryder, Yoda');

  // ==========================================================================
  // 7. CREATE VEHICLES
  // ==========================================================================
  
  await prisma.vehicle.upsert({
    where: {
      householdId_nickname: {
        householdId: household.id,
        nickname: 'The Mercedes',
      },
    },
    update: {},
    create: {
      householdId: household.id,
      type: 'SUV',
      year: 2019,
      make: 'Mercedes-Benz',
      model: 'GLS',
      nickname: 'The Mercedes',
      isActive: true,
    },
  });

  await prisma.vehicle.upsert({
    where: {
      householdId_nickname: {
        householdId: household.id,
        nickname: 'The Audi',
      },
    },
    update: {},
    create: {
      householdId: household.id,
      type: 'SUV',
      year: 2016,
      make: 'Audi',
      model: 'Q3',
      nickname: 'The Audi',
      isActive: true,
    },
  });
  console.log('✅ Created vehicles: Mercedes GLS, Audi Q3');

  // ==========================================================================
  // 8. CREATE HOME SYSTEMS
  // ==========================================================================
  
  const systems = [
    {
      systemType: 'FURNACE',
      name: 'Oil Furnace',
      notes: 'Oil heating system - requires annual service and oil deliveries',
      serviceIntervalMonths: 12,
    },
    {
      systemType: 'WATER_HEATER',
      name: 'Hot Water Tank',
      notes: 'Standard tank water heater',
    },
    {
      systemType: 'GENERATOR',
      name: 'Backup Generator',
      notes: 'Propane-powered backup generator with propane tanks',
    },
    {
      systemType: 'FIREPLACE',
      name: 'Chimney 1 - Living Room',
      notes: 'Annual chimney cleaning recommended',
      serviceIntervalMonths: 12,
    },
    {
      systemType: 'FIREPLACE',
      name: 'Chimney 2 - Family Room',
      notes: 'Annual chimney cleaning recommended',
      serviceIntervalMonths: 12,
    },
  ];

  for (const system of systems) {
    await prisma.homeSystem.create({
      data: {
        householdId: household.id,
        ...system,
        isActive: true,
      },
    });
  }
  console.log('✅ Created home systems: Oil Furnace, Water Heater, Generator, 2 Chimneys');

  // ==========================================================================
  // 9. CREATE VENDORS
  // ==========================================================================
  
  const eversource = await prisma.householdVendor.create({
    data: {
      householdId: household.id,
      displayName: 'Eversource',
      category: 'ELECTRIC',
      isLocal: false,
      phone: '800-286-2000',
      websiteUrl: 'https://www.eversource.com',
    },
  });

  const capitalOne = await prisma.householdVendor.create({
    data: {
      householdId: household.id,
      displayName: 'Capital One',
      category: 'MORTGAGE',
      isLocal: false,
      phone: '800-655-2265',
      websiteUrl: 'https://www.capitalone.com',
    },
  });

  const renata = await prisma.householdVendor.create({
    data: {
      householdId: household.id,
      displayName: 'Renata Cleaning Services',
      category: 'CLEANING',
      isLocal: true,
      notes: 'Only accepts cash or check - no credit cards',
    },
  });

  const blueFox = await prisma.householdVendor.create({
    data: {
      householdId: household.id,
      displayName: 'Blue Fox Landscaping',
      category: 'LANDSCAPING',
      isLocal: true,
      serviceDescription: 'Lawn care and snow plowing',
    },
  });
  console.log('✅ Created vendors: Eversource, Capital One, Renata Cleaning, Blue Fox Landscaping');

  // ==========================================================================
  // 10. CREATE BILL ACCOUNTS
  // ==========================================================================
  
  await prisma.billAccount.create({
    data: {
      householdId: household.id,
      vendorId: eversource.id,
      nickname: 'Electric Bill',
      category: 'ELECTRIC',
      billingFrequency: 'MONTHLY',
      typicalAmount: 200,
      autopayEnabled: true,
      paymentResponsibility: 'OWNER_PAYS_DIRECT',
      isActive: true,
    },
  });

  await prisma.billAccount.create({
    data: {
      householdId: household.id,
      vendorId: capitalOne.id,
      nickname: 'Mortgage',
      category: 'MORTGAGE',
      billingFrequency: 'MONTHLY',
      paymentResponsibility: 'OWNER_PAYS_DIRECT',
      isActive: true,
    },
  });

  await prisma.billAccount.create({
    data: {
      householdId: household.id,
      vendorId: renata.id,
      nickname: 'House Cleaning',
      category: 'CLEANING',
      billingFrequency: 'BIWEEKLY',
      paymentResponsibility: 'OWNER_PAYS_DIRECT',
      notes: 'Pay by check - Renata only accepts cash/check',
      isActive: true,
    },
  });

  await prisma.billAccount.create({
    data: {
      householdId: household.id,
      vendorId: blueFox.id,
      nickname: 'Landscaping',
      category: 'LANDSCAPING',
      billingFrequency: 'MONTHLY',
      paymentResponsibility: 'OWNER_PAYS_DIRECT',
      notes: 'Includes lawn care (spring-fall) and snow plowing (winter)',
      isActive: true,
    },
  });
  console.log('✅ Created bill accounts');

  // ==========================================================================
  // 11. CREATE SOME MAINTENANCE TASKS
  // ==========================================================================
  
  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Annual Chimney Cleaning',
      description: 'Schedule chimney sweep for both chimneys before winter',
      category: 'CHIMNEY',
      status: 'PENDING',
      priority: 'MEDIUM',
      dueDate: new Date('2025-09-01'),
      createdFromTemplate: false,
    },
  });

  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Oil Furnace Annual Service',
      description: 'Annual tune-up and inspection of oil furnace',
      category: 'HVAC',
      status: 'PENDING',
      priority: 'MEDIUM',
      dueDate: new Date('2025-10-01'),
      createdFromTemplate: false,
    },
  });

  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Generator Test Run',
      description: 'Monthly test run of backup generator',
      category: 'GENERAL',
      status: 'PENDING',
      priority: 'LOW',
      dueDate: new Date('2025-02-01'),
      createdFromTemplate: false,
    },
  });
  console.log('✅ Created maintenance tasks');

  console.log('');
  console.log('🎉 Burke Household Demo Data Complete!');
  console.log('');
  console.log('Login credentials:');
  console.log('  Email: tom@example.com');
  console.log('  Password: Tom123!');
  console.log('');
  console.log('Household ID:', household.id);
}

async function main() {
  try {
    await seedBurkeHousehold();
  } catch (error) {
    console.error('❌ Seed failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

main();
```

---

## STEP 2: Check if Required Models Exist

First, verify these models exist in the Prisma schema:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Check for FamilyMember, Pet, Vehicle, HomeSystem models
grep -E "^model (FamilyMember|Pet|Vehicle|HomeSystem|HouseholdVendor|BillAccount)" prisma/schema.prisma
```

If models are missing, we need to add them. Check the schema and report what exists.

---

## STEP 3: Run the Seed Script

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Generate Prisma client if needed
pnpm prisma generate

# Run the Burke seed
npx ts-node prisma/seed-burke.ts
```

---

## STEP 4: Verify Alfred Endpoint Exists

Check that the Alfred chat endpoint is working:

```bash
# Check if Alfred controller exists
cat /Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/alfred.controller.ts | head -50

# Check if route is registered
grep -rn "alfred" /Users/tomburke/Projects/Housing-Manager/apps/api/src/app.module.ts
```

---

## STEP 5: Test Alfred Chat Locally

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Start the API
cd apps/api && pnpm dev &

# Wait for it to start, then test Alfred
sleep 5

# Test the Alfred endpoint (adjust auth as needed)
curl -X POST http://localhost:4000/api/alfred/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What home systems do I have?",
    "householdId": "burke-household-demo"
  }'
```

---

## STEP 6: Commit and Deploy

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Add the seed file
git add apps/api/prisma/seed-burke.ts

# Commit
git commit -m "feat: add Burke household demo data for Essentials tier

- Tom & Mindy Burke with 2 daughters (Blake, Valerie) and Au Pair (Hevellyn)
- 2 dogs: Ryder (Australian Shepherd) and Yoda (Black Lab Mix)  
- 2 vehicles: Mercedes GLS 2019, Audi Q3 2016
- Home systems: Oil furnace, hot water tank, generator, 2 chimneys
- Vendors: Eversource, Capital One, Renata Cleaning, Blue Fox Landscaping
- Address: 146 Putnam Park Rd, Bethel, CT 06801
- Ready for Alfred AI testing"

# Push to trigger deployment
git push origin main
```

---

## REPORT

After completing, provide:

1. **Schema Status**: Do all required models exist? (FamilyMember, Pet, Vehicle, HomeSystem, etc.)
2. **Seed Result**: Did the seed script run successfully?
3. **Data Created**: List of records created
4. **Alfred Status**: Is the /alfred/chat endpoint working?
5. **Test Login**: Can you authenticate as tom@example.com?
6. **Missing Models**: If any models are missing, list them

---

## DEMO USER SUMMARY

| Field | Value |
|-------|-------|
| **Email** | tom@example.com |
| **Password** | Tom123! |
| **Household** | The Burke Family |
| **Tier** | Essentials ($39/mo) |
| **Manager** | Alfred (AI) |
| **Address** | 146 Putnam Park Rd, Bethel, CT 06801 |

### Family
- Tom Burke (owner)
- Mindy Burke (spouse)
- Blake Burke (daughter, 3)
- Valerie Burke (daughter, 1 month)
- Hevellyn Silva (au pair)

### Pets
- Ryder (Australian Shepherd, 9)
- Yoda (Black Lab Mix, 5)

### Vehicles
- Mercedes GLS 2019
- Audi Q3 2016

### Systems
- Oil Furnace
- Hot Water Tank
- Generator (propane)
- 2 Chimneys

### Vendors/Bills
- Eversource (electric)
- Capital One (mortgage)
- Renata Cleaning (biweekly, cash/check only)
- Blue Fox Landscaping (lawn + plowing)

---

# END OF PROMPT
