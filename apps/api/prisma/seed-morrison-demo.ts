/**
 * Morrison Demo Seed
 *
 * Seeds the complete Morrison family demo data for bob@example.com
 * This creates a fully populated household with:
 * - Haven team (Sarah Chen - Home Manager, Mike Rodriguez - Handyman)
 * - Morrison family (Bob, Alice, Emma, Jack, Max, Maria)
 * - Property: 38 Bedford Road, Greenwich CT
 * - Vehicles, Zones, Assets, Bills, Activity Log
 */

import {
  PrismaClient,
  UserRole,
  FamilyMemberType,
  BillCategory,
  PaymentFrequency,
  BillStatus,
  BillPaymentMethod,
  OnboardingStatus,
  ActivityAction,
  ActivityCategory,
  ActorType,
  ZoneType,
  AssetCategory,
  VendorCategory,
  PropertyType,
  VehicleType,
  ActivityType,
  PetType,
  ApprovalType,
  ApprovalStatus,
  ApprovalPriority,
  MaintenanceCategory,
  MaintenanceFrequency,
  SeasonalTiming,
  TaskSource,
  MaintenanceTaskStatus,
  TaskPriority,
} from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding Haven database with Morrison demo data...');
  console.log('');

  // =========================================================================
  // CLEAN EXISTING DEMO DATA
  // =========================================================================
  console.log('Cleaning existing demo data...');

  // Find demo households (may be multiple)
  const existingHouseholds = await prisma.household.findMany({
    where: {
      OR: [
        { name: 'The Morrison Family' },
        { owner: { email: 'bob@example.com' } },
      ],
    },
  });

  for (const household of existingHouseholds) {
    // Delete related data (order matters due to foreign keys)
    await prisma.approvalComment.deleteMany({
      where: { approval: { householdId: household.id } },
    });
    await prisma.approvalRequest.deleteMany({ where: { householdId: household.id } });
    await prisma.maintenanceTask.deleteMany({ where: { householdId: household.id } });
    await prisma.activityLog.deleteMany({ where: { householdId: household.id } });
    await prisma.billPaymentRecord.deleteMany({
      where: { bill: { householdId: household.id } },
    });
    await prisma.comprehensiveBill.deleteMany({ where: { householdId: household.id } });
    await prisma.kidActivity.deleteMany({ where: { householdId: household.id } });
    await prisma.familyMember.deleteMany({ where: { householdId: household.id } });
    await prisma.vehicle.deleteMany({ where: { householdId: household.id } });
    await prisma.propertyAsset.deleteMany({ where: { householdId: household.id } });
    await prisma.zone.deleteMany({ where: { householdId: household.id } });
    await prisma.vendor.deleteMany({ where: { householdId: household.id } });
    await prisma.householdIntake.deleteMany({ where: { householdId: household.id } });
    await prisma.homeProfile.deleteMany({ where: { householdId: household.id } });
    await prisma.pet.deleteMany({ where: { householdId: household.id } });
    await prisma.householdMember.deleteMany({ where: { householdId: household.id } });
    await prisma.household.delete({ where: { id: household.id } });
  }

  // Delete demo users (if they exist and are not attached to households)
  await prisma.user.deleteMany({
    where: {
      email: {
        in: [
          'bob@example.com',
          'alice@example.com',
          'sarah@haven.app',
          'mike@haven.app',
          'admin@haven.app',
        ],
      },
    },
  });

  console.log('  ✓ Cleaned existing demo data');

  // =========================================================================
  // CREATE HAVEN TEAM (Staff accounts)
  // =========================================================================
  console.log('');
  console.log('Creating Haven team...');

  const sarah = await prisma.user.create({
    data: {
      email: 'sarah@haven.app',
      firebaseUid: 'sarah-haven-manager',
      displayName: 'Sarah Chen',
      firstName: 'Sarah',
      lastName: 'Chen',
      phone: '(203) 555-0100',
      role: UserRole.MANAGER,
    },
  });
  console.log('  ✓ Sarah Chen (Home Manager)');

  const mike = await prisma.user.create({
    data: {
      email: 'mike@haven.app',
      firebaseUid: 'mike-haven-handyman',
      displayName: 'Mike Rodriguez',
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
      displayName: 'Haven Admin',
      firstName: 'Admin',
      role: UserRole.ADMIN,
    },
  });
  console.log('  ✓ Haven Admin');

  // =========================================================================
  // CREATE BOB (HOMEOWNER) FIRST
  // =========================================================================
  console.log('');
  console.log('Creating Bob Morrison (homeowner)...');

  const bob = await prisma.user.create({
    data: {
      email: 'bob@example.com',
      firebaseUid: 'F2l9RyJ9vyNjLZPfO1lPNYyxVrh2', // From Firebase
      displayName: 'Bob Morrison',
      firstName: 'Bob',
      lastName: 'Morrison',
      phone: '(203) 555-0101',
      role: UserRole.HOMEOWNER,
    },
  });
  console.log('  ✓ Bob Morrison (bob@example.com)');

  // =========================================================================
  // CREATE MORRISON DEMO HOUSEHOLD
  // =========================================================================
  console.log('');
  console.log('Creating Morrison household...');

  const household = await prisma.household.create({
    data: {
      name: 'The Morrison Family',
      ownerId: bob.id,
      managerId: sarah.id,
      assignedHandymanId: mike.id,
      subscriptionPlan: 'PREMIUM',
      subscriptionStatus: 'ACTIVE',
      conciergeEnabled: true,
      monthlyVisitDay: 15,
      billingCycleDay: 1,
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
  console.log('  ✓ Household: The Morrison Family');

  // Link Bob to household
  await prisma.householdMember.create({
    data: {
      householdId: household.id,
      userId: bob.id,
      role: 'OWNER',
      status: 'ACTIVE',
    },
  });

  // =========================================================================
  // CREATE ALICE (Second homeowner)
  // =========================================================================
  const alice = await prisma.user.create({
    data: {
      email: 'alice@example.com',
      firebaseUid: 'alice-morrison-demo',
      displayName: 'Alice Morrison',
      firstName: 'Alice',
      lastName: 'Morrison',
      phone: '(203) 555-0102',
      role: UserRole.HOMEOWNER,
    },
  });

  await prisma.householdMember.create({
    data: {
      householdId: household.id,
      userId: alice.id,
      role: 'MEMBER',
      status: 'ACTIVE',
    },
  });
  console.log('  ✓ Alice Morrison (alice@example.com)');

  // =========================================================================
  // PROPERTY (HomeProfile)
  // =========================================================================
  console.log('');
  console.log('Creating property...');

  const property = await prisma.homeProfile.create({
    data: {
      householdId: household.id,
      propertyType: PropertyType.SINGLE_FAMILY,
      addressLine1: '38 Bedford Road',
      city: 'Greenwich',
      state: 'CT',
      postalCode: '06831',
      country: 'US',
      bedrooms: 5,
      bathrooms: 5.5,
      squareFeet: 5765,
      lotSize: 2.0,
      yearBuilt: 1998,
      garageSpaces: 3,
    },
  });
  console.log('  ✓ Property: 38 Bedford Road, Greenwich CT');

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
      birthdate: new Date('2012-03-15'),
      relationship: 'Daughter',
      school: 'Greenwich Country Day School',
      schoolGrade: '7th Grade',
      allergies: ['Peanuts', 'Tree nuts'],
    },
  });

  await prisma.kidActivity.createMany({
    data: [
      {
        familyMemberId: emma.id,
        householdId: household.id,
        name: 'Soccer',
        type: ActivityType.SPORTS,
        schedule: 'Tue/Thu 4-6pm, Sat games 10am',
        location: 'Greenwich Polo Club Fields',
        cost: 450,
        costFrequency: PaymentFrequency.QUARTERLY,
        organization: 'Greenwich Soccer Club',
      },
      {
        familyMemberId: emma.id,
        householdId: household.id,
        name: 'Piano Lessons',
        type: ActivityType.MUSIC,
        schedule: 'Wed 3:30-4:30pm',
        location: '45 Greenwich Ave',
        cost: 200,
        costFrequency: PaymentFrequency.MONTHLY,
        organization: 'Greenwich Music Academy',
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
      birthdate: new Date('2016-07-22'),
      relationship: 'Son',
      school: 'North Street School',
      schoolGrade: '3rd Grade',
    },
  });

  await prisma.kidActivity.createMany({
    data: [
      {
        familyMemberId: jack.id,
        householdId: household.id,
        name: 'Little League',
        type: ActivityType.SPORTS,
        schedule: 'Sat 10am',
        location: 'Cos Cob Park',
        cost: 350,
        costFrequency: PaymentFrequency.QUARTERLY,
      },
      {
        familyMemberId: jack.id,
        householdId: household.id,
        name: 'Piano',
        type: ActivityType.MUSIC,
        schedule: 'Mon 4pm',
        cost: 200,
        costFrequency: PaymentFrequency.MONTHLY,
      },
      {
        familyMemberId: jack.id,
        householdId: household.id,
        name: 'Art Class',
        type: ActivityType.ARTS,
        schedule: 'Thu 3:30pm',
        cost: 150,
        costFrequency: PaymentFrequency.MONTHLY,
      },
    ],
  });
  console.log('  ✓ Jack Morrison (8, 3rd Grade) + 3 activities');

  // Max - Pet (using Pet model)
  await prisma.pet.create({
    data: {
      householdId: household.id,
      name: 'Max',
      type: PetType.DOG,
      breed: 'Golden Retriever',
      birthday: new Date('2020-09-10'),
      primaryVetName: 'Dr. Williams',
      vetClinicName: 'Westlake Animal Hospital',
      vetClinicPhone: '(203) 555-8387',
      microchipId: '985141001234567',
      specialNeeds: 'Food: Blue Buffalo Life Protection Adult Chicken, 30 lbs/mo',
    },
  });
  console.log('  ✓ Max (Golden Retriever, 4 years)');

  // Maria Garcia - Nanny (Staff member)
  await prisma.familyMember.create({
    data: {
      householdId: household.id,
      type: FamilyMemberType.STAFF,
      firstName: 'Maria',
      lastName: 'Garcia',
      relationship: 'Nanny',
      phone: '(203) 555-0199',
      email: 'maria.garcia@email.com',
      workSchedule: 'Mon-Thu 7am-6pm, Fri 7am-3pm',
      startDate: new Date('2023-06-01'),
      responsibilities: 'Kids schedules, school pickup/dropoff, meal prep, homework help',
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
        name: "Bob's Tesla",
        vehicleType: VehicleType.CAR,
        year: 2023,
        make: 'Tesla',
        model: 'Model Y',
        color: 'Midnight Silver',
        licensePlate: 'GRN 1234',
        vin: '5YJSA1E26MF123456',
        currentMileage: 24500,
        hasLoan: true,
        monthlyPayment: 895,
        registrationState: 'CT',
        registrationExpiry: new Date('2025-02-10'),
      },
      {
        householdId: household.id,
        name: 'Family Highlander',
        vehicleType: VehicleType.SUV,
        year: 2022,
        make: 'Toyota',
        model: 'Highlander',
        color: 'Pearl White',
        licensePlate: 'XYZ 5678',
        currentMileage: 35200,
        hasLoan: true,
        monthlyPayment: 775,
        registrationState: 'CT',
      },
      {
        householdId: household.id,
        name: "Alice's Mercedes",
        vehicleType: VehicleType.SUV,
        year: 2024,
        make: 'Mercedes-Benz',
        model: 'GLE 450',
        color: 'Obsidian Black Metallic',
        licensePlate: 'EF-11111',
        currentMileage: 8750,
        hasLoan: true,
        monthlyPayment: 1082,
        registrationState: 'CT',
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
      householdId: household.id,
      name: 'Kitchen',
      type: ZoneType.KITCHEN,
      floor: 'First Floor',
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId: household.id,
        zoneId: kitchen.id,
        name: 'Refrigerator',
        category: AssetCategory.APPLIANCE,
        brand: 'Sub-Zero',
        model: 'BI-48S',
        condition: 'EXCELLENT',
        purchaseDate: new Date('2020-03-15'),
      },
      {
        householdId: household.id,
        zoneId: kitchen.id,
        name: 'Dishwasher',
        category: AssetCategory.APPLIANCE,
        brand: 'Bosch',
        model: 'SHPM88Z75N',
        condition: 'EXCELLENT',
        purchaseDate: new Date('2021-06-01'),
      },
      {
        householdId: household.id,
        zoneId: kitchen.id,
        name: 'Range/Oven',
        category: AssetCategory.APPLIANCE,
        brand: 'Wolf',
        model: 'DF486G',
        condition: 'EXCELLENT',
        purchaseDate: new Date('2020-03-15'),
      },
    ],
  });
  console.log('  ✓ Kitchen (3 assets)');

  // Laundry
  const laundry = await prisma.zone.create({
    data: {
      householdId: household.id,
      name: 'Laundry Room',
      type: ZoneType.LAUNDRY,
      floor: 'Second Floor',
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId: household.id,
        zoneId: laundry.id,
        name: 'Washer',
        category: AssetCategory.APPLIANCE,
        brand: 'LG',
        model: 'WM4500HBA',
        condition: 'EXCELLENT',
      },
      {
        householdId: household.id,
        zoneId: laundry.id,
        name: 'Dryer',
        category: AssetCategory.APPLIANCE,
        brand: 'LG',
        model: 'DLEX4500B',
        condition: 'EXCELLENT',
      },
    ],
  });
  console.log('  ✓ Laundry Room (2 assets)');

  // Garage
  const garage = await prisma.zone.create({
    data: {
      householdId: household.id,
      name: 'Garage',
      type: ZoneType.GARAGE,
      floor: 'Ground Level',
    },
  });

  await prisma.propertyAsset.create({
    data: {
      householdId: household.id,
      zoneId: garage.id,
      name: 'Garage Door Opener',
      category: AssetCategory.OTHER,
      brand: 'LiftMaster',
      condition: 'GOOD',
    },
  });
  console.log('  ✓ Garage (1 asset)');

  // Mechanical Room
  const mechanical = await prisma.zone.create({
    data: {
      householdId: household.id,
      name: 'Mechanical Room',
      type: ZoneType.MECHANICAL,
      floor: 'Basement',
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId: household.id,
        zoneId: mechanical.id,
        name: 'HVAC System',
        category: AssetCategory.HVAC,
        brand: 'Carrier',
        model: 'Infinity 24',
        condition: 'GOOD',
        purchaseDate: new Date('2021-04-01'),
        warrantyExpires: new Date('2031-04-01'),
      },
      {
        householdId: household.id,
        zoneId: mechanical.id,
        name: 'Water Heater',
        category: AssetCategory.PLUMBING,
        brand: 'Rheem',
        model: 'RTGH-95DVLN',
        condition: 'GOOD',
        purchaseDate: new Date('2019-08-15'),
      },
      {
        householdId: household.id,
        zoneId: mechanical.id,
        name: 'Electrical Panel',
        category: AssetCategory.ELECTRICAL,
        brand: 'Square D',
        condition: 'GOOD',
      },
    ],
  });
  console.log('  ✓ Mechanical Room (3 assets)');

  // Backyard
  const backyard = await prisma.zone.create({
    data: {
      householdId: household.id,
      name: 'Backyard & Grounds',
      type: ZoneType.OUTDOOR_BACK,
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId: household.id,
        zoneId: backyard.id,
        name: 'Pool',
        category: AssetCategory.OUTDOOR,
        condition: 'GOOD',
      },
      {
        householdId: household.id,
        zoneId: backyard.id,
        name: 'Roof',
        category: AssetCategory.STRUCTURAL,
        condition: 'GOOD',
        notes: 'Asphalt shingles, installed 2012, ~12 years old',
      },
      {
        householdId: household.id,
        zoneId: backyard.id,
        name: 'Septic System',
        category: AssetCategory.PLUMBING,
        condition: 'GOOD',
        notes: 'Last pumped 2023',
      },
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
      {
        householdId: household.id,
        category: VendorCategory.HVAC_SERVICE,
        displayName: 'Comfort Zone HVAC',
        contactName: 'Tom Reynolds',
        phone: '(203) 555-1001',
        email: 'service@comfortzone.example.com',
      },
      {
        householdId: household.id,
        category: VendorCategory.WATER_SEWER,
        displayName: "Mike's Plumbing",
        contactName: 'Mike Thompson',
        phone: '(203) 555-1002',
        email: 'mike@mikesplumbing.example.com',
      },
      {
        householdId: household.id,
        category: VendorCategory.ELECTRIC,
        displayName: 'Greenwich Electric',
        contactName: 'Jim Watts',
        phone: '(203) 555-1003',
      },
      {
        householdId: household.id,
        category: VendorCategory.OTHER,
        displayName: 'Ace Roofing Co',
        contactName: 'Steve Ace',
        phone: '(203) 555-1004',
        email: 'vendor@aceroofing.example.com',
        serviceDescription: 'Roofing contractor',
      },
      {
        householdId: household.id,
        category: VendorCategory.LANDSCAPING,
        displayName: 'Green Thumb Lawn Care',
        contactName: 'Carlos Verde',
        phone: '(203) 555-1005',
        notes: 'Weekly service Thursdays',
      },
    ],
  });
  console.log('  ✓ 5 vendors');

  // =========================================================================
  // COMPREHENSIVE BILLS
  // =========================================================================
  console.log('');
  console.log('Creating bills...');

  await prisma.comprehensiveBill.createMany({
    data: [
      // Housing
      {
        householdId: household.id,
        category: BillCategory.MORTGAGE,
        name: 'Mortgage',
        payeeName: 'Chase Home Lending',
        amount: 3450,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 1,
        accountNumber: '****4521',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
        isLoan: true,
      },
      {
        householdId: household.id,
        category: BillCategory.HOME_INSURANCE,
        name: 'Home Insurance',
        payeeName: 'Allstate',
        amount: 677,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 15,
        accountNumber: 'POL-789456',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },
      {
        householdId: household.id,
        category: BillCategory.PROPERTY_TAX,
        name: 'Property Tax',
        payeeName: 'Town of Greenwich',
        amount: 12000,
        frequency: PaymentFrequency.SEMI_ANNUAL,
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },

      // Utilities
      {
        householdId: household.id,
        category: BillCategory.ELECTRIC,
        name: 'Electric',
        payeeName: 'Eversource',
        amount: 187,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 10,
        accountNumber: '51-234-5678',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },
      {
        householdId: household.id,
        category: BillCategory.GAS,
        name: 'Gas',
        payeeName: 'Eversource',
        amount: 145,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 10,
        accountNumber: '51-234-5679',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },
      {
        householdId: household.id,
        category: BillCategory.WATER_SEWER,
        name: 'Water/Sewer',
        payeeName: 'Town of Greenwich',
        amount: 215,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 12,
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },
      {
        householdId: household.id,
        category: BillCategory.OIL_PROPANE,
        name: 'Heating Oil',
        payeeName: 'Greenwich Oil Co',
        amount: 400,
        frequency: PaymentFrequency.MONTHLY,
        description: 'Budget plan, varies by season',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },

      // Telecom
      {
        householdId: household.id,
        category: BillCategory.INTERNET,
        name: 'Internet',
        payeeName: 'Optimum',
        amount: 89,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 7,
        accountNumber: '07-123456789',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },
      {
        householdId: household.id,
        category: BillCategory.CELL_PHONE,
        name: 'Cell Phones',
        payeeName: 'Verizon Wireless',
        amount: 323,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 15,
        accountNumber: '****7890',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },

      // Education
      {
        householdId: household.id,
        category: BillCategory.SCHOOL_TUITION,
        name: 'Emma - Greenwich Country Day',
        payeeName: 'Greenwich Country Day School',
        amount: 4500,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 1,
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },

      // Home Services
      {
        householdId: household.id,
        category: BillCategory.LAWN_LANDSCAPE,
        name: 'Lawn Care',
        payeeName: 'Green Thumb Lawn Care',
        amount: 185,
        frequency: PaymentFrequency.MONTHLY,
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },
      {
        householdId: household.id,
        category: BillCategory.SECURITY_MONITORING,
        name: 'Security Monitoring',
        payeeName: 'ADT',
        amount: 45,
        frequency: PaymentFrequency.MONTHLY,
        accountNumber: 'ADT-123456',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },

      // Auto
      {
        householdId: household.id,
        category: BillCategory.AUTO_INSURANCE,
        name: 'Auto Insurance',
        payeeName: 'Allstate',
        amount: 555,
        frequency: PaymentFrequency.MONTHLY,
        accountNumber: 'AUTO-789',
        status: BillStatus.ACTIVE,
        paymentMethod: BillPaymentMethod.HAVEN_PAYS,
      },
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
        actorType: ActorType.HOME_MANAGER,
        actorName: 'Sarah Chen',
        action: ActivityAction.SERVICE_COMPLETED,
        category: ActivityCategory.MAINTENANCE,
        title: 'HVAC filter changed',
        visibleToHomeowner: true,
        createdAt: twoDaysAgo,
      },
      {
        householdId: household.id,
        actorId: sarah.id,
        actorType: ActorType.HOME_MANAGER,
        actorName: 'Sarah Chen',
        action: ActivityAction.BILL_PAID,
        category: ActivityCategory.BILLING,
        title: 'Lawn care invoice paid',
        description: '$185',
        amount: 185,
        visibleToHomeowner: true,
        createdAt: fiveDaysAgo,
      },
      {
        householdId: household.id,
        actorId: sarah.id,
        actorType: ActorType.HOME_MANAGER,
        actorName: 'Sarah Chen',
        action: ActivityAction.DOCUMENT_UPLOADED,
        category: ActivityCategory.PROPERTY,
        title: 'Warranty uploaded for water heater',
        visibleToHomeowner: true,
        createdAt: oneWeekAgo,
      },
      {
        householdId: household.id,
        actorId: mike.id,
        actorType: ActorType.HANDYMAN,
        actorName: 'Mike Rodriguez',
        action: ActivityAction.SERVICE_COMPLETED,
        category: ActivityCategory.MAINTENANCE,
        title: 'Gutter cleaning completed',
        description: '$275',
        amount: 275,
        visibleToHomeowner: true,
        createdAt: twoWeeksAgo,
      },
    ],
  });
  console.log('  ✓ 4 activity log entries');

  // =========================================================================
  // APPROVAL REQUESTS (Demo for homeowner portal)
  // =========================================================================
  console.log('');
  console.log('Creating approval requests...');

  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  // Note: twoDaysAgo already defined above for activity logs
  const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);

  // Pending urgent approval - pipe repair
  await prisma.approvalRequest.create({
    data: {
      householdId: household.id,
      requesterId: sarah.id,
      type: ApprovalType.EXPENSE,
      priority: ApprovalPriority.URGENT,
      status: ApprovalStatus.PENDING,
      title: 'Emergency pipe burst repair - Kitchen',
      description:
        'Urgent - Pipe burst in kitchen. Vendor is on-site and waiting for approval. I recommend approving immediately to prevent water damage to cabinets.',
      amount: 450,
      vendorName: 'Emergency Plumbing Co.',
      createdAt: new Date(now.getTime() - 2 * 60 * 60 * 1000), // 2 hours ago
    },
  });

  // Pending normal approval - roof inspection
  const roofApproval = await prisma.approvalRequest.create({
    data: {
      householdId: household.id,
      requesterId: sarah.id,
      type: ApprovalType.EXPENSE,
      priority: ApprovalPriority.MEDIUM,
      status: ApprovalStatus.PENDING,
      title: 'Roof inspection and shingle replacement',
      description:
        'Recommended after last storm. I obtained 3 quotes - this is the best value ($875 vs $1,200 and $950). Happy to discuss alternatives.',
      amount: 875,
      vendorName: 'Ace Roofing Co.',
      createdAt: yesterday,
    },
  });

  // Add a comment to the roof approval
  await prisma.approvalComment.create({
    data: {
      approvalId: roofApproval.id,
      authorId: sarah.id,
      content:
        'I had their team do an initial inspection today. Found 12 damaged shingles on the north side. Photos attached to the work order.',
      createdAt: new Date(yesterday.getTime() + 4 * 60 * 60 * 1000),
    },
  });

  // Pending vendor selection
  await prisma.approvalRequest.create({
    data: {
      householdId: household.id,
      requesterId: sarah.id,
      type: ApprovalType.VENDOR_SELECTION,
      priority: ApprovalPriority.LOW,
      status: ApprovalStatus.PENDING,
      title: 'Annual HVAC maintenance vendor',
      description:
        "Time to schedule your annual HVAC tune-up. I'm recommending AirFlow Pros based on their excellent reviews and competitive pricing. Let me know if you'd prefer one of the other quotes.",
      vendorName: 'AirFlow Pros',
      amount: 189,
      createdAt: twoDaysAgo,
    },
  });

  // Already approved - garbage disposal
  await prisma.approvalRequest.create({
    data: {
      householdId: household.id,
      requesterId: sarah.id,
      deciderId: bob.id,
      type: ApprovalType.EXPENSE,
      priority: ApprovalPriority.MEDIUM,
      status: ApprovalStatus.APPROVED,
      title: 'Garbage disposal replacement',
      description: 'Current disposal is making grinding noises and leaking slightly. Replacement recommended.',
      amount: 275,
      vendorName: 'HandyPro Services',
      createdAt: threeDaysAgo,
      decidedAt: twoDaysAgo,
      decisionNote: 'Approved. Thanks for the quick quote!',
    },
  });

  // Already rejected - hot tub upgrade
  await prisma.approvalRequest.create({
    data: {
      householdId: household.id,
      requesterId: sarah.id,
      deciderId: bob.id,
      type: ApprovalType.PROJECT,
      priority: ApprovalPriority.LOW,
      status: ApprovalStatus.REJECTED,
      title: 'Hot tub heater upgrade to energy efficient model',
      description:
        "The current heater works fine but uses more energy than newer models. Upgrade would save about $40/month in energy costs.",
      amount: 2400,
      vendorName: 'Spa Specialists',
      createdAt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
      decidedAt: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000),
      decisionNote: "Let's wait until spring to consider this. The current heater is working fine.",
    },
  });

  console.log('  ✓ 5 approval requests (3 pending, 1 approved, 1 rejected)');

  // =========================================================================
  // MAINTENANCE TASKS (Auto-generated from ATTOM property enrichment)
  // Morrison enrichment: Forced Air Gas, Central AC, Pool, 2 fireplaces,
  // 1985 build, 2.0 acres, Attached garage, CT (northeast)
  // =========================================================================
  console.log('');
  console.log('Creating maintenance tasks from property enrichment...');

  // Helper function to get next seasonal date
  const getNextSeasonDate = (season: 'SPRING' | 'SUMMER' | 'FALL' | 'WINTER'): Date => {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth();
    const seasonMonths = { SPRING: 3, SUMMER: 6, FALL: 9, WINTER: 0 };
    let targetMonth = seasonMonths[season];
    let targetYear = year;
    if (month >= targetMonth + 2) targetYear++;
    return new Date(targetYear, targetMonth, 15);
  };

  // HVAC Tasks
  await prisma.maintenanceTask.createMany({
    data: [
      {
        householdId: household.id,
        title: 'HVAC Filter Change',
        description: 'Replace or clean HVAC air filters for optimal efficiency and air quality',
        category: MaintenanceCategory.HVAC,
        frequency: MaintenanceFrequency.QUARTERLY,
        seasonalTiming: SeasonalTiming.ANY,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'HVAC',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 30,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000),
      },
      {
        householdId: household.id,
        title: 'Furnace Annual Service',
        description: 'Professional inspection and tune-up of heating system before winter',
        category: MaintenanceCategory.HVAC,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.FALL,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'HVAC',
        priority: TaskPriority.HIGH,
        estimatedCost: 150,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('FALL'),
      },
      {
        householdId: household.id,
        title: 'AC Annual Service',
        description: 'Professional inspection and tune-up of cooling system before summer',
        category: MaintenanceCategory.HVAC,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.SPRING,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'HVAC',
        priority: TaskPriority.HIGH,
        estimatedCost: 150,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('SPRING'),
      },
    ],
  });

  // Pool Tasks (hasPool = true, CT = northeast so include closing)
  await prisma.maintenanceTask.createMany({
    data: [
      {
        householdId: household.id,
        title: 'Pool Opening',
        description: 'Remove cover, start filtration, balance chemicals, inspect equipment',
        category: MaintenanceCategory.POOL,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.SPRING,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Pool',
        priority: TaskPriority.HIGH,
        estimatedCost: 350,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('SPRING'),
      },
      {
        householdId: household.id,
        title: 'Pool Closing',
        description: 'Winterize pool, add closing chemicals, install cover, drain equipment',
        category: MaintenanceCategory.POOL,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.FALL,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Pool',
        priority: TaskPriority.HIGH,
        estimatedCost: 350,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('FALL'),
      },
    ],
  });

  // Chimney (fireplaceCount = 2)
  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Chimney Sweep & Inspection',
      description: 'Professional chimney cleaning and safety inspection (2 fireplaces)',
      category: MaintenanceCategory.CHIMNEY,
      frequency: MaintenanceFrequency.ANNUAL,
      seasonalTiming: SeasonalTiming.FALL,
      source: TaskSource.SYSTEM_GENERATED,
      sourceSystem: 'Fireplace',
      priority: TaskPriority.HIGH,
      estimatedCost: 400,
      isRecurring: true,
      status: MaintenanceTaskStatus.UPCOMING,
      nextDueDate: getNextSeasonDate('FALL'),
    },
  });

  // Roof (yearBuilt 1985 = 40 years old)
  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Roof Inspection',
      description: 'Professional inspection for damage, wear, and potential issues (40-year-old roof)',
      category: MaintenanceCategory.ROOFING,
      frequency: MaintenanceFrequency.ANNUAL,
      seasonalTiming: SeasonalTiming.SPRING,
      source: TaskSource.SYSTEM_GENERATED,
      sourceSystem: 'Roof',
      priority: TaskPriority.HIGH,
      estimatedCost: 200,
      isRecurring: true,
      status: MaintenanceTaskStatus.UPCOMING,
      nextDueDate: getNextSeasonDate('SPRING'),
    },
  });

  // Exterior Tasks
  await prisma.maintenanceTask.createMany({
    data: [
      {
        householdId: household.id,
        title: 'Gutter Cleaning',
        description: 'Clean gutters and downspouts, check for damage',
        category: MaintenanceCategory.EXTERIOR,
        frequency: MaintenanceFrequency.SEMI_ANNUAL,
        seasonalTiming: SeasonalTiming.FALL,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Exterior',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 150,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('FALL'),
      },
      {
        householdId: household.id,
        title: 'Spring Gutter Check',
        description: 'Clean gutters after winter, check for ice damage',
        category: MaintenanceCategory.EXTERIOR,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.SPRING,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Exterior',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 150,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('SPRING'),
      },
      {
        householdId: household.id,
        title: 'Garage Door Service',
        description: 'Lubricate tracks and springs, test safety features',
        category: MaintenanceCategory.EXTERIOR,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.ANY,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Garage',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 100,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: new Date(now.getTime() + 180 * 24 * 60 * 60 * 1000),
      },
    ],
  });

  // Landscaping Tasks (lotSizeAcres = 2.0)
  await prisma.maintenanceTask.createMany({
    data: [
      {
        householdId: household.id,
        title: 'Spring Lawn Treatment',
        description: 'Fertilization, weed control, and soil testing (2.0 acres)',
        category: MaintenanceCategory.LANDSCAPING,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.SPRING,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Landscaping',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 400,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('SPRING'),
      },
      {
        householdId: household.id,
        title: 'Fall Lawn Aeration',
        description: 'Aerate and overseed lawn for winter preparation',
        category: MaintenanceCategory.LANDSCAPING,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.FALL,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Landscaping',
        priority: TaskPriority.LOW,
        estimatedCost: 350,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('FALL'),
      },
    ],
  });

  // Safety Tasks
  await prisma.maintenanceTask.createMany({
    data: [
      {
        householdId: household.id,
        title: 'Smoke & CO Detector Test',
        description: 'Test all smoke and carbon monoxide detectors, replace batteries',
        category: MaintenanceCategory.SAFETY,
        frequency: MaintenanceFrequency.SEMI_ANNUAL,
        seasonalTiming: SeasonalTiming.ANY,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Safety',
        priority: TaskPriority.HIGH,
        estimatedCost: 0,
        isRecurring: true,
        status: MaintenanceTaskStatus.DUE_SOON,
        nextDueDate: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000),
      },
      {
        householdId: household.id,
        title: 'Fire Extinguisher Check',
        description: 'Inspect fire extinguishers, replace if needed',
        category: MaintenanceCategory.SAFETY,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.ANY,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Safety',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 50,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: new Date(now.getTime() + 60 * 24 * 60 * 60 * 1000),
      },
    ],
  });

  // Plumbing Tasks
  await prisma.maintenanceTask.createMany({
    data: [
      {
        householdId: household.id,
        title: 'Water Heater Flush',
        description: 'Drain and flush water heater to remove sediment',
        category: MaintenanceCategory.PLUMBING,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.ANY,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Plumbing',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 100,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000),
      },
      {
        householdId: household.id,
        title: 'Water Heater Inspection',
        description: 'Check anode rod, inspect for leaks and corrosion (40-year-old home)',
        category: MaintenanceCategory.PLUMBING,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.ANY,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Plumbing',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 100,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000),
      },
    ],
  });

  // Seasonal & Appliance Tasks
  await prisma.maintenanceTask.createMany({
    data: [
      {
        householdId: household.id,
        title: 'Winterization Checklist',
        description: 'Disconnect hoses, insulate pipes, check weatherstripping, reverse ceiling fans',
        category: MaintenanceCategory.SEASONAL,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.FALL,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Seasonal',
        priority: TaskPriority.HIGH,
        estimatedCost: 0,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('FALL'),
      },
      {
        householdId: household.id,
        title: 'Spring Home Checklist',
        description: 'Inspect roof after winter, check foundation, clean AC condenser, inspect deck/patio',
        category: MaintenanceCategory.SEASONAL,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.SPRING,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Seasonal',
        priority: TaskPriority.MEDIUM,
        estimatedCost: 0,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: getNextSeasonDate('SPRING'),
      },
      {
        householdId: household.id,
        title: 'Dryer Vent Cleaning',
        description: 'Clean dryer vent to prevent fire hazard and improve efficiency',
        category: MaintenanceCategory.APPLIANCES,
        frequency: MaintenanceFrequency.ANNUAL,
        seasonalTiming: SeasonalTiming.ANY,
        source: TaskSource.SYSTEM_GENERATED,
        sourceSystem: 'Appliances',
        priority: TaskPriority.HIGH,
        estimatedCost: 100,
        isRecurring: true,
        status: MaintenanceTaskStatus.UPCOMING,
        nextDueDate: new Date(now.getTime() + 120 * 24 * 60 * 60 * 1000),
      },
    ],
  });

  // Count total created
  const maintenanceCount = await prisma.maintenanceTask.count({
    where: { householdId: household.id },
  });
  console.log(`  ✓ ${maintenanceCount} maintenance tasks auto-generated from property data`);
  console.log('  ✓ Onboarding marked complete');

  // =========================================================================
  // MARK ONBOARDING COMPLETE
  // =========================================================================
  await prisma.householdIntake.create({
    data: {
      householdId: household.id,
      managerId: sarah.id,
      status: OnboardingStatus.ACTIVE,
      selectedTier: 'HAVEN',
      progressFamily: 100,
      progressProperty: 100,
      progressZones: 100,
      progressSystems: 100,
      progressVendors: 100,
      progressBills: 100,
      progress: 100,
      calculatedMonthlyFunding: 8500,
      completedAt: new Date('2024-06-15'),
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
  console.log('Property: 38 Bedford Road, Greenwich CT 06831');
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
