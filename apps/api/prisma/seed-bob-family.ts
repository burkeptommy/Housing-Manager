/**
 * Seed Bob's demo household with complete family data
 *
 * Run with: DATABASE_URL="postgresql://..." npx ts-node prisma/seed-bob-family.ts
 */

import { PrismaClient, FamilyMemberType, PetType, PetSize, ZoneType, AssetCategory, BillCategory, PaymentFrequency, VehicleType } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding Bob\'s family data...\n');

  const householdId = 'demo-household-id';

  // Verify household exists
  const household = await prisma.household.findUnique({
    where: { id: householdId },
  });

  if (!household) {
    throw new Error('Demo household not found');
  }

  console.log(`Found household: ${household.name}`);

  // Clear existing data for fresh seed
  await prisma.kidActivity.deleteMany({ where: { householdId } });
  await prisma.familyMember.deleteMany({ where: { householdId } });
  await prisma.pet.deleteMany({ where: { householdId } });
  await prisma.propertyAsset.deleteMany({ where: { householdId } });
  await prisma.zone.deleteMany({ where: { householdId } });
  await prisma.vehicle.deleteMany({ where: { householdId } });
  await prisma.comprehensiveBill.deleteMany({ where: { householdId } });

  console.log('✅ Cleared existing data');

  // ============================================================================
  // FAMILY MEMBERS
  // ============================================================================
  console.log('\n👨‍👩‍👧‍👦 Creating family members...');

  // Bob - Father
  const bob = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Bob',
      lastName: 'Morrison',
      type: FamilyMemberType.ADULT,
      relationship: 'Owner',
      email: 'bob@example.com',
      phone: '(203) 555-0147',
      birthdate: new Date('1982-03-15'),
    },
  });

  // Sarah - Wife
  const sarah = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Sarah',
      lastName: 'Morrison',
      type: FamilyMemberType.ADULT,
      relationship: 'Spouse',
      email: 'sarah.morrison@example.com',
      phone: '(203) 555-0148',
      birthdate: new Date('1984-07-22'),
    },
  });

  // Emma - Daughter (14)
  const emma = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Emma',
      lastName: 'Morrison',
      nickname: 'Em',
      type: FamilyMemberType.CHILD,
      relationship: 'Daughter',
      birthdate: new Date('2010-06-15'),
      school: 'Greenwich Academy',
      schoolGrade: '9th',
      teacher: 'Mrs. Patterson',
      schoolPickup: 'Bus',
      schoolDropoff: 'Bus',
    },
  });

  // Jake - Son (10)
  const jake = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Jake',
      lastName: 'Morrison',
      type: FamilyMemberType.CHILD,
      relationship: 'Son',
      birthdate: new Date('2014-09-03'),
      school: 'North Street School',
      schoolGrade: '5th',
      teacher: 'Mr. Chen',
      schoolPickup: 'Carpool',
      schoolDropoff: 'Parent',
    },
  });

  // Maria - Nanny
  const maria = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Maria',
      lastName: 'Santos',
      type: FamilyMemberType.STAFF,
      relationship: 'Nanny',
      email: 'maria.santos@example.com',
      phone: '(203) 555-0150',
      birthdate: new Date('1990-12-10'),
      workSchedule: 'Mon-Fri 7am-6pm',
      responsibilities: 'Morning routine, school pickups, afternoon activities, dinner prep',
      startDate: new Date('2021-09-01'),
    },
  });

  console.log('✅ Created 5 family members: Bob, Sarah, Emma, Jake, Maria');

  // ============================================================================
  // KID ACTIVITIES
  // ============================================================================
  console.log('\n⚽ Creating kid activities...');

  // Emma's activities
  await prisma.kidActivity.create({
    data: {
      householdId,
      familyMemberId: emma.id,
      name: 'Soccer',
      type: 'SPORTS',
      organization: 'Greenwich Soccer Club',
      location: 'Greenwich High School Fields',
      schedule: 'Tues/Thurs 4-6pm, Sat games 10am',
      cost: 450,
      costFrequency: 'QUARTERLY',
      coachName: 'Coach Williams',
      contactPhone: '(203) 555-0200',
      notes: 'U14 Girls Team',
    },
  });

  await prisma.kidActivity.create({
    data: {
      householdId,
      familyMemberId: emma.id,
      name: 'Piano Lessons',
      type: 'MUSIC',
      organization: 'Greenwich Music Academy',
      location: '45 Greenwich Ave',
      schedule: 'Wed 3:30-4:30pm',
      cost: 200,
      costFrequency: 'MONTHLY',
      coachName: 'Ms. Chen',
      contactPhone: '(203) 555-0201',
    },
  });

  // Jake's activities
  await prisma.kidActivity.create({
    data: {
      householdId,
      familyMemberId: jake.id,
      name: 'Swim Team',
      type: 'SPORTS',
      organization: 'YMCA',
      location: 'Greenwich YMCA',
      schedule: 'Mon/Wed/Fri 4-5:30pm',
      cost: 350,
      costFrequency: 'QUARTERLY',
      coachName: 'Coach Davis',
      contactPhone: '(203) 555-0202',
      notes: 'Level 5 swimmer',
    },
  });

  await prisma.kidActivity.create({
    data: {
      householdId,
      familyMemberId: jake.id,
      name: 'Coding Club',
      type: 'ACADEMIC',
      organization: 'Code Ninjas',
      location: 'Greenwich Plaza',
      schedule: 'Sat 10am-12pm',
      cost: 150,
      costFrequency: 'MONTHLY',
      notes: 'Working on Scratch projects',
    },
  });

  console.log('✅ Created 4 kid activities');

  // ============================================================================
  // PETS
  // ============================================================================
  console.log('\n🐕 Creating pets...');

  const max = await prisma.pet.create({
    data: {
      householdId,
      name: 'Max',
      type: PetType.DOG,
      breed: 'Golden Retriever',
      color: 'Golden',
      size: PetSize.LARGE,
      weight: 75,
      birthday: new Date('2019-04-15'),
      gender: 'Male',
      isSpayedNeutered: true,
      microchipId: '985112000589234',
      allergies: ['Chicken'],
      medications: [],
      vetClinicName: 'Greenwich Veterinary Hospital',
      vetClinicPhone: '(203) 869-0534',
      vetClinicAddress: '1225 E Putnam Ave, Greenwich, CT 06870',
      feedingSchedule: '2x daily - 8am and 6pm, 2 cups each',
      careInstructions: 'Loves belly rubs! Gets anxious during thunderstorms.',
    },
  });

  // Add vet records
  await prisma.petVetRecord.create({
    data: {
      petId: max.id,
      visitDate: new Date('2024-09-15'),
      visitType: 'Checkup',
      description: 'Annual wellness exam',
      weight: 75,
      vaccinationsGiven: ['Rabies', 'DHPP'],
      nextVaccinationDate: new Date('2025-09-15'),
      cost: 185,
      vetClinic: 'Greenwich Veterinary Hospital',
      vetName: 'Dr. Martinez',
    },
  });

  console.log('✅ Created 1 pet (Max the Golden Retriever)');

  // ============================================================================
  // ZONES & PROPERTY ASSETS
  // ============================================================================
  console.log('\n🏠 Creating zones and assets...');

  // Kitchen
  const kitchen = await prisma.zone.create({
    data: {
      householdId,
      name: 'Kitchen',
      type: ZoneType.KITCHEN,
      floor: 'First Floor',
      sortOrder: 1,
      notes: 'Recently renovated in 2022',
    },
  });

  // Kitchen appliances
  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId,
        zoneId: kitchen.id,
        name: 'Refrigerator',
        category: AssetCategory.APPLIANCE,
        brand: 'Sub-Zero',
        model: 'BI-48SID/S',
        serialNumber: 'SZ2847291034',
        purchaseDate: new Date('2022-01-15'),
        warrantyExpires: new Date('2027-01-15'),
        condition: 'Excellent',
        notes: '48" side-by-side with ice maker',
      },
      {
        householdId,
        zoneId: kitchen.id,
        name: 'Range/Oven',
        category: AssetCategory.APPLIANCE,
        brand: 'Wolf',
        model: 'GR486G',
        serialNumber: 'WLF8472910',
        purchaseDate: new Date('2022-01-15'),
        warrantyExpires: new Date('2025-01-15'),
        condition: 'Excellent',
        notes: '48" gas range with 6 burners and griddle',
      },
      {
        householdId,
        zoneId: kitchen.id,
        name: 'Dishwasher',
        category: AssetCategory.APPLIANCE,
        brand: 'Miele',
        model: 'G7366SCViSF',
        serialNumber: 'ML928471023',
        purchaseDate: new Date('2022-01-15'),
        warrantyExpires: new Date('2024-01-15'),
        condition: 'Excellent',
        notes: 'Panel-ready integrated',
      },
    ],
  });

  // Mechanical Room / Utility
  const utility = await prisma.zone.create({
    data: {
      householdId,
      name: 'Mechanical Room',
      type: ZoneType.MECHANICAL,
      floor: 'Basement',
      sortOrder: 10,
      notes: 'Contains main HVAC, water heater, electrical panel',
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId,
        zoneId: utility.id,
        name: 'HVAC System',
        category: AssetCategory.HVAC,
        brand: 'Carrier',
        model: '24ACC648A003',
        serialNumber: 'CAR8472910',
        purchaseDate: new Date('2019-10-15'),
        warrantyExpires: new Date('2029-10-15'),
        lastServiceDate: new Date('2024-09-15'),
        nextServiceDate: new Date('2025-03-15'),
        condition: 'Good',
        notes: '4-ton central air with gas furnace',
      },
      {
        householdId,
        zoneId: utility.id,
        name: 'Water Heater',
        category: AssetCategory.PLUMBING,
        brand: 'Rheem',
        model: 'XG50T12HE40U0',
        serialNumber: 'RH928471034',
        purchaseDate: new Date('2021-03-20'),
        warrantyExpires: new Date('2033-03-20'),
        lastServiceDate: new Date('2024-03-20'),
        nextServiceDate: new Date('2025-03-20'),
        condition: 'Good',
        notes: '50-gallon gas, set to 120F',
      },
      {
        householdId,
        zoneId: utility.id,
        name: 'Electrical Panel',
        category: AssetCategory.ELECTRICAL,
        brand: 'Square D',
        model: 'HOM3040L200PGCVP',
        serialNumber: 'SD8472910',
        purchaseDate: new Date('2015-06-01'),
        condition: 'Good',
        notes: '200 amp main panel with whole-house surge protector',
      },
    ],
  });

  // Laundry
  const laundry = await prisma.zone.create({
    data: {
      householdId,
      name: 'Laundry Room',
      type: ZoneType.LAUNDRY,
      floor: 'Second Floor',
      sortOrder: 8,
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId,
        zoneId: laundry.id,
        name: 'Washer',
        category: AssetCategory.APPLIANCE,
        brand: 'LG',
        model: 'WM4500HBA',
        serialNumber: 'LG927483921',
        purchaseDate: new Date('2023-03-01'),
        warrantyExpires: new Date('2026-03-01'),
        condition: 'Excellent',
        notes: 'Front load, 5.0 cu ft, TurboWash',
      },
      {
        householdId,
        zoneId: laundry.id,
        name: 'Dryer',
        category: AssetCategory.APPLIANCE,
        brand: 'LG',
        model: 'DLEX4500B',
        serialNumber: 'LG927483922',
        purchaseDate: new Date('2023-03-01'),
        warrantyExpires: new Date('2026-03-01'),
        condition: 'Excellent',
        notes: 'Electric, 7.4 cu ft, steam cycle',
      },
    ],
  });

  // Garage
  const garage = await prisma.zone.create({
    data: {
      householdId,
      name: 'Garage',
      type: ZoneType.GARAGE,
      floor: 'Ground Level',
      sortOrder: 9,
      notes: '3-car attached garage',
    },
  });

  await prisma.propertyAsset.create({
    data: {
      householdId,
      zoneId: garage.id,
      name: 'Garage Door Opener',
      category: AssetCategory.OTHER,
      brand: 'LiftMaster',
      model: '8500W',
      serialNumber: 'LM8839421',
      purchaseDate: new Date('2020-08-10'),
      warrantyExpires: new Date('2025-08-10'),
      lastServiceDate: new Date('2024-02-15'),
      nextServiceDate: new Date('2025-02-15'),
      condition: 'Good',
      notes: 'Wall-mounted, WiFi enabled, battery backup',
    },
  });

  // Exterior - Back yard
  const exterior = await prisma.zone.create({
    data: {
      householdId,
      name: 'Backyard & Grounds',
      type: ZoneType.OUTDOOR_BACK,
      sortOrder: 11,
      notes: '2.5 acre property with pool',
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId,
        zoneId: exterior.id,
        name: 'Pool',
        category: AssetCategory.OTHER,
        brand: 'Hayward',
        model: 'Variable equipment',
        purchaseDate: new Date('2015-05-01'),
        lastServiceDate: new Date('2024-10-15'),
        nextServiceDate: new Date('2025-04-01'),
        condition: 'Good',
        notes: '20x40 gunite pool, saltwater system, heated',
      },
      {
        householdId,
        zoneId: exterior.id,
        name: 'Roof',
        category: AssetCategory.OTHER,
        brand: 'GAF',
        model: 'Timberline HDZ',
        purchaseDate: new Date('2018-07-01'),
        warrantyExpires: new Date('2043-07-01'),
        lastServiceDate: new Date('2024-04-15'),
        nextServiceDate: new Date('2025-04-15'),
        condition: 'Good',
        notes: 'Charcoal color asphalt shingles, 25-year warranty',
      },
      {
        householdId,
        zoneId: exterior.id,
        name: 'Septic System',
        category: AssetCategory.PLUMBING,
        brand: 'Infiltrator',
        purchaseDate: new Date('2005-06-01'),
        lastServiceDate: new Date('2023-06-15'),
        nextServiceDate: new Date('2026-06-15'),
        condition: 'Good',
        notes: '1500-gallon tank, pump every 3 years',
      },
    ],
  });

  const zoneCount = await prisma.zone.count({ where: { householdId } });
  const assetCount = await prisma.propertyAsset.count({ where: { householdId } });
  console.log(`✅ Created ${zoneCount} zones with ${assetCount} assets`);

  // ============================================================================
  // VEHICLES
  // ============================================================================
  console.log('\n🚗 Creating vehicles...');

  await prisma.vehicle.createMany({
    data: [
      {
        householdId,
        name: "Bob's Tesla",
        make: 'Tesla',
        model: 'Model X',
        year: 2023,
        vehicleType: VehicleType.ELECTRIC,
        color: 'Pearl White',
        licensePlate: 'CT EV-2847',
        vin: '5YJXCBE20PF123456',
        isOwned: true,
        isActive: true,
        currentMileage: 18500,
        registrationExpiry: new Date('2025-03-15'),
        registrationState: 'CT',
        insuranceProvider: 'State Farm',
        insurancePolicyNum: 'SF-CT-8472910',
        insuranceExpiry: new Date('2025-06-01'),
        insuranceMonthly: 185,
        hasLoan: true,
        lender: 'Tesla Finance',
        monthlyPayment: 950,
        loanBalance: 52000,
        preferredServiceShop: 'Tesla Service Center - Greenwich',
      },
      {
        householdId,
        name: 'Family Range Rover',
        make: 'Land Rover',
        model: 'Range Rover Sport',
        year: 2022,
        vehicleType: VehicleType.SUV,
        color: 'Santorini Black',
        licensePlate: 'CT 847-HJK',
        vin: 'SALGS2RU4NA123456',
        isOwned: true,
        isActive: true,
        currentMileage: 28500,
        registrationExpiry: new Date('2025-07-01'),
        registrationState: 'CT',
        insuranceProvider: 'State Farm',
        insurancePolicyNum: 'SF-CT-8472911',
        insuranceExpiry: new Date('2025-06-01'),
        insuranceMonthly: 165,
        hasLoan: false,
        preferredServiceShop: 'Land Rover Greenwich',
        lastOilChange: new Date('2024-10-15'),
        nextServiceDue: new Date('2025-04-15'),
      },
    ],
  });

  console.log('✅ Created 2 vehicles');

  // ============================================================================
  // BILLS
  // ============================================================================
  console.log('\n💵 Creating bills...');

  await prisma.comprehensiveBill.createMany({
    data: [
      {
        householdId,
        category: BillCategory.ELECTRIC,
        name: 'Eversource Electric',
        payeeName: 'Eversource Energy',
        accountNumber: '52-8472-9183',
        amount: 285,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 20,
        havenManaged: true,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.GAS,
        name: 'Southern CT Gas',
        payeeName: 'SCG',
        accountNumber: 'SCG-847291-02',
        amount: 180,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 15,
        havenManaged: true,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.WATER_SEWER,
        name: 'Aquarion Water',
        payeeName: 'Aquarion Water Company',
        accountNumber: 'AQ-2847-001',
        amount: 95,
        frequency: PaymentFrequency.QUARTERLY,
        dueDay: 10,
        havenManaged: true,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.INTERNET,
        name: 'Frontier FiOS',
        payeeName: 'Frontier Communications',
        accountNumber: '203-555-0147-001',
        amount: 129,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 5,
        havenManaged: true,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.HOUSE_CLEANING,
        name: 'House Cleaning',
        payeeName: 'Sparkle Clean Services',
        amount: 350,
        frequency: PaymentFrequency.BIWEEKLY,
        dueDay: 1,
        havenManaged: true,
        status: 'ACTIVE',
        notes: 'Deep clean every other Tuesday',
      },
      {
        householdId,
        category: BillCategory.LAWN_LANDSCAPE,
        name: 'Lawn Care',
        payeeName: 'Green Thumb Landscaping',
        amount: 195,
        frequency: PaymentFrequency.WEEKLY,
        dueDay: 1,
        havenManaged: true,
        status: 'ACTIVE',
        notes: 'Weekly service Apr-Nov, $65/visit',
      },
      {
        householdId,
        category: BillCategory.POOL_SERVICE,
        name: 'Pool Service',
        payeeName: 'Crystal Clear Pools',
        amount: 350,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 1,
        havenManaged: true,
        status: 'ACTIVE',
        notes: 'Weekly service May-Sep, opening/closing included',
      },
      {
        householdId,
        category: BillCategory.HOME_INSURANCE,
        name: 'Home Insurance',
        payeeName: 'Chubb',
        accountNumber: 'CHB-8472910-HO',
        amount: 1850,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 1,
        havenManaged: false,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.AUTO_INSURANCE,
        name: 'Auto Insurance',
        payeeName: 'State Farm',
        accountNumber: 'SF-CT-8472910',
        amount: 350,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 15,
        havenManaged: false,
        status: 'ACTIVE',
        notes: 'Covers both vehicles',
      },
      {
        householdId,
        category: BillCategory.SECURITY_MONITORING,
        name: 'ADT Security',
        payeeName: 'ADT',
        accountNumber: 'ADT-847291',
        amount: 45,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 5,
        havenManaged: true,
        status: 'ACTIVE',
      },
    ],
  });

  const billCount = await prisma.comprehensiveBill.count({ where: { householdId } });
  console.log(`✅ Created ${billCount} bills`);

  // ============================================================================
  // HOUSEHOLD INTAKE (for monthly funding)
  // ============================================================================
  console.log('\n📋 Updating household intake...');

  await prisma.householdIntake.upsert({
    where: { householdId },
    update: {
      calculatedMonthlyFunding: 4500,
    },
    create: {
      householdId,
      calculatedMonthlyFunding: 4500,
    },
  });

  console.log('✅ Set monthly funding to $4,500');

  console.log('\n🎉 Bob\'s demo data seeded successfully!\n');
  console.log('Family: Bob, Sarah (spouse), Emma (14), Jake (10), Maria (nanny)');
  console.log('Pets: Max (Golden Retriever)');
  console.log(`Zones: ${zoneCount} with ${assetCount} assets`);
  console.log('Vehicles: 2 (Tesla Model X, Range Rover Sport)');
  console.log(`Bills: ${billCount}`);
}

main()
  .catch((e) => {
    console.error('Error seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
