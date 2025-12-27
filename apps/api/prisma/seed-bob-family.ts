/**
 * Seed Bob Morrison's demo household with complete family data
 *
 * Run with: DATABASE_URL="postgresql://..." npx ts-node prisma/seed-bob-family.ts
 */

import { PrismaClient, FamilyMemberType, PetType, PetSize, ZoneType, AssetCategory, BillCategory, PaymentFrequency, VehicleType } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding Morrison family demo data...\n');

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

  // Bob Morrison - Head of Household
  const bob = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Bob',
      lastName: 'Morrison',
      type: FamilyMemberType.ADULT,
      relationship: 'Head of Household',
      email: 'bob@example.com',
      phone: '(203) 555-0101',
      birthdate: new Date('1982-03-15'),
    },
  });

  // Alice Morrison - Spouse
  const alice = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Alice',
      lastName: 'Morrison',
      type: FamilyMemberType.ADULT,
      relationship: 'Spouse',
      email: 'alice@example.com',
      phone: '(203) 555-0102',
      birthdate: new Date('1984-07-22'),
    },
  });

  // Emma Morrison - Daughter (12, 7th Grade)
  const emma = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Emma',
      lastName: 'Morrison',
      type: FamilyMemberType.CHILD,
      relationship: 'Daughter',
      birthdate: new Date('2012-03-15'), // 12 years old
      school: 'Greenwich Country Day School',
      schoolGrade: '7th',
      schoolPickup: 'Bus',
      schoolDropoff: 'Bus',
    },
  });

  // Jack Morrison - Son (8, 3rd Grade)
  const jack = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Jack',
      lastName: 'Morrison',
      type: FamilyMemberType.CHILD,
      relationship: 'Son',
      birthdate: new Date('2016-07-22'), // 8 years old
      school: 'North Street School',
      schoolGrade: '3rd',
      schoolPickup: 'Maria',
      schoolDropoff: 'Parent',
    },
  });

  // Maria Garcia - Nanny
  const maria = await prisma.familyMember.create({
    data: {
      householdId,
      firstName: 'Maria',
      lastName: 'Garcia',
      type: FamilyMemberType.STAFF,
      relationship: 'Nanny',
      phone: '(203) 555-0199',
      birthdate: new Date('1990-12-10'),
      workSchedule: 'Mon-Thu 7am-6pm, Fri 7am-3pm',
      responsibilities: 'Morning routine, school pickups, afternoon activities, dinner prep',
      startDate: new Date('2023-06-01'),
    },
  });

  console.log('✅ Created 5 family members: Bob, Alice, Emma, Jack, Maria Garcia');

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
      organization: 'FC Greenwich',
      location: 'Greenwich Polo Club Fields',
      schedule: 'Tue/Thu 5-7pm, Sat 9am',
      cost: 450,
      costFrequency: 'QUARTERLY',
      coachName: 'Coach Martinez',
      contactPhone: '(203) 555-KICK',
      notes: 'Travel Soccer team',
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
      schedule: 'Wed 4pm',
      cost: 250,
      costFrequency: 'MONTHLY',
      contactPhone: '(203) 555-KEYS',
    },
  });

  // Jack's activities
  await prisma.kidActivity.create({
    data: {
      householdId,
      familyMemberId: jack.id,
      name: 'Little League',
      type: 'SPORTS',
      organization: 'Greenwich Little League',
      location: 'Cos Cob Park',
      schedule: 'Mon/Wed 5pm',
      cost: 100,
      costFrequency: 'MONTHLY',
      coachName: 'Coach Johnson',
      contactPhone: '(203) 555-BALL',
    },
  });

  await prisma.kidActivity.create({
    data: {
      householdId,
      familyMemberId: jack.id,
      name: 'Art Class',
      type: 'ARTS',
      organization: 'Bruce Museum Art Studio',
      location: 'Bruce Museum',
      schedule: 'Sat 10am',
      cost: 175,
      costFrequency: 'MONTHLY',
      contactPhone: '(203) 555-ARTS',
    },
  });

  await prisma.kidActivity.create({
    data: {
      householdId,
      familyMemberId: jack.id,
      name: 'Piano',
      type: 'MUSIC',
      organization: 'Greenwich Music Academy',
      location: '45 Greenwich Ave',
      schedule: 'Mon 4pm',
      cost: 200,
      costFrequency: 'MONTHLY',
    },
  });

  console.log('✅ Created 5 kid activities');

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
      birthday: new Date('2020-09-10'), // 4 years old
      gender: 'Male',
      isSpayedNeutered: true,
      microchipId: '985141001234567',
      allergies: [],
      medications: [],
      vetClinicName: 'Westlake Animal Hospital',
      vetClinicPhone: '(203) 555-VETS',
      feedingSchedule: '2x daily - 8am and 6pm, Blue Buffalo 30 lbs/mo',
      careInstructions: 'Dr. Williams is vet. Monthly expenses: $150',
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
      vetClinic: 'Westlake Animal Hospital',
      vetName: 'Dr. Williams',
    },
  });

  console.log('✅ Created 1 pet (Max the Golden Retriever, 4 years old)');

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
    },
  });

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
      },
      {
        householdId,
        zoneId: kitchen.id,
        name: 'Dishwasher',
        category: AssetCategory.APPLIANCE,
        brand: 'Bosch',
        model: '800 Series',
        condition: 'Excellent',
      },
      {
        householdId,
        zoneId: kitchen.id,
        name: 'Range/Oven',
        category: AssetCategory.APPLIANCE,
        brand: 'Wolf',
        model: 'GR486G',
        condition: 'Excellent',
      },
    ],
  });

  // Mechanical Room
  const mechanical = await prisma.zone.create({
    data: {
      householdId,
      name: 'Mechanical Room',
      type: ZoneType.MECHANICAL,
      floor: 'Basement',
      sortOrder: 10,
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId,
        zoneId: mechanical.id,
        name: 'HVAC System',
        category: AssetCategory.HVAC,
        brand: 'Carrier',
        model: 'Infinity 26',
        condition: 'Good',
        lastServiceDate: new Date('2024-09-15'),
        nextServiceDate: new Date('2025-03-15'),
      },
      {
        householdId,
        zoneId: mechanical.id,
        name: 'Water Heater',
        category: AssetCategory.PLUMBING,
        brand: 'Rheem',
        model: 'XG50T12HE40U0',
        condition: 'Good',
      },
      {
        householdId,
        zoneId: mechanical.id,
        name: 'Electrical Panel',
        category: AssetCategory.ELECTRICAL,
        brand: 'Square D',
        condition: 'Good',
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
        condition: 'Excellent',
      },
      {
        householdId,
        zoneId: laundry.id,
        name: 'Dryer',
        category: AssetCategory.APPLIANCE,
        brand: 'LG',
        condition: 'Excellent',
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
      notes: '2-car attached',
    },
  });

  await prisma.propertyAsset.create({
    data: {
      householdId,
      zoneId: garage.id,
      name: 'Garage Door Opener',
      category: AssetCategory.OTHER,
      brand: 'LiftMaster',
      condition: 'Good',
    },
  });

  // Backyard
  const backyard = await prisma.zone.create({
    data: {
      householdId,
      name: 'Backyard & Grounds',
      type: ZoneType.OUTDOOR_BACK,
      sortOrder: 11,
      notes: '2.0 acre property',
    },
  });

  await prisma.propertyAsset.createMany({
    data: [
      {
        householdId,
        zoneId: backyard.id,
        name: 'Pool',
        category: AssetCategory.OTHER,
        condition: 'Good',
      },
      {
        householdId,
        zoneId: backyard.id,
        name: 'Roof',
        category: AssetCategory.OTHER,
        condition: 'Good',
      },
      {
        householdId,
        zoneId: backyard.id,
        name: 'Septic System',
        category: AssetCategory.PLUMBING,
        condition: 'Good',
      },
    ],
  });

  const zoneCount = await prisma.zone.count({ where: { householdId } });
  const assetCount = await prisma.propertyAsset.count({ where: { householdId } });
  console.log(`✅ Created ${zoneCount} zones with ${assetCount} assets`);

  // ============================================================================
  // VEHICLES (matching canonical Morrison data)
  // ============================================================================
  console.log('\n🚗 Creating vehicles...');

  await prisma.vehicle.createMany({
    data: [
      {
        householdId,
        name: "Bob's Tesla",
        make: 'Tesla',
        model: 'Model Y',
        year: 2023,
        vehicleType: VehicleType.ELECTRIC,
        color: 'Midnight Silver',
        licensePlate: 'GRN 1234',
        vin: '5YJSA1E26MF123456',
        isOwned: true,
        isActive: true,
        currentMileage: 24500,
        registrationExpiry: new Date('2025-03-15'),
        registrationState: 'CT',
        insuranceProvider: 'State Farm',
        insuranceExpiry: new Date('2025-06-01'),
        insuranceMonthly: 145,
        hasLoan: true,
        lender: 'Tesla Finance',
        monthlyPayment: 895,
        preferredServiceShop: 'Tesla Service Center - Greenwich',
      },
      {
        householdId,
        name: 'Family Highlander',
        make: 'Toyota',
        model: 'Highlander',
        year: 2022,
        vehicleType: VehicleType.SUV,
        color: 'Pearl White',
        licensePlate: 'XYZ 5678',
        isOwned: true,
        isActive: true,
        currentMileage: 35200,
        registrationExpiry: new Date('2025-07-01'),
        registrationState: 'CT',
        insuranceProvider: 'State Farm',
        insuranceExpiry: new Date('2025-06-01'),
        insuranceMonthly: 125,
        hasLoan: true,
        lender: 'Toyota Financial',
        monthlyPayment: 775,
        preferredServiceShop: 'Toyota of Greenwich',
        lastOilChange: new Date('2024-10-15'),
        nextServiceDue: new Date('2025-04-15'),
      },
      {
        householdId,
        name: "Alice's Mercedes",
        make: 'Mercedes-Benz',
        model: 'GLE 450',
        year: 2024,
        vehicleType: VehicleType.SUV,
        color: 'Obsidian Black Metallic',
        licensePlate: 'EF-11111',
        isOwned: true,
        isActive: true,
        currentMileage: 8750,
        registrationExpiry: new Date('2025-09-01'),
        registrationState: 'CT',
        insuranceProvider: 'State Farm',
        insuranceExpiry: new Date('2025-06-01'),
        insuranceMonthly: 183,
        hasLoan: true,
        lender: 'Mercedes-Benz Financial',
        monthlyPayment: 1082,
        preferredServiceShop: 'Mercedes-Benz of Greenwich',
      },
    ],
  });

  console.log('✅ Created 3 vehicles');

  // ============================================================================
  // BILLS (matching canonical Morrison costs)
  // ============================================================================
  console.log('\n💵 Creating bills...');

  await prisma.comprehensiveBill.createMany({
    data: [
      // Utilities
      {
        householdId,
        category: BillCategory.ELECTRIC,
        name: 'Eversource Electric',
        payeeName: 'Eversource',
        accountNumber: '51-234-5678',
        amount: 187,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 20,
        havenManaged: true,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.GAS,
        name: 'Eversource Gas',
        payeeName: 'Eversource',
        accountNumber: '51-234-5679',
        amount: 145,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 15,
        havenManaged: true,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.WATER_SEWER,
        name: 'Water/Sewer',
        payeeName: 'Town of Greenwich',
        amount: 215,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 10,
        havenManaged: true,
        status: 'ACTIVE',
      },
      // Telecom
      {
        householdId,
        category: BillCategory.INTERNET,
        name: 'Internet',
        payeeName: 'Optimum',
        accountNumber: '07-123456789',
        amount: 89,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 5,
        havenManaged: true,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.CELL_PHONE,
        name: 'Cell Phones',
        payeeName: 'Verizon',
        accountNumber: '****7890',
        amount: 323,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 15,
        havenManaged: false,
        status: 'ACTIVE',
      },
      // Housing
      {
        householdId,
        category: BillCategory.MORTGAGE,
        name: 'Mortgage',
        payeeName: 'Chase Home Lending',
        accountNumber: '****4521',
        amount: 3450,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 1,
        havenManaged: false,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.HOME_INSURANCE,
        name: 'Home Insurance',
        payeeName: 'Allstate',
        accountNumber: 'POL-789456',
        amount: 677, // $8124/12
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 1,
        havenManaged: false,
        status: 'ACTIVE',
      },
      // Childcare/Education
      {
        householdId,
        category: BillCategory.SCHOOL_TUITION,
        name: 'Emma - Greenwich Country Day',
        payeeName: 'Greenwich Country Day School',
        amount: 4500,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 1,
        havenManaged: false,
        status: 'ACTIVE',
      },
      {
        householdId,
        category: BillCategory.CHILDCARE,
        name: 'Nanny - Maria Garcia',
        payeeName: 'Maria Garcia',
        amount: 6000,
        frequency: PaymentFrequency.MONTHLY,
        dueDay: 1,
        havenManaged: false,
        status: 'ACTIVE',
        notes: 'Weekly stipend: $1,500',
      },
    ],
  });

  const billCount = await prisma.comprehensiveBill.count({ where: { householdId } });
  console.log(`✅ Created ${billCount} bills`);

  // ============================================================================
  // UPDATE HOUSEHOLD DATA
  // ============================================================================
  console.log('\n📋 Updating household data...');

  // Update household name and enrichment data
  await prisma.household.update({
    where: { id: householdId },
    data: {
      name: 'The Morrison Family',
      enrichmentData: {
        bedrooms: 5,
        bathrooms: 5.5,
        squareFeet: 5765,
        yearBuilt: 1998,
        lotSizeAcres: 2.0,
        heatingType: 'Gas Forced Air',
        coolingType: 'Central Air',
        waterType: 'Public',
        roofType: 'Asphalt Shingles',
        pool: true,
        garage: '2-car attached',
        stories: 2,
        homeHealthScore: 94,
      },
    },
  });

  // Update home profile with correct address
  await prisma.homeProfile.upsert({
    where: { householdId },
    update: {
      addressLine1: '38 Bedford Road',
      city: 'Greenwich',
      state: 'CT',
      postalCode: '06831',
      propertyType: 'SINGLE_FAMILY',
    },
    create: {
      householdId,
      addressLine1: '38 Bedford Road',
      city: 'Greenwich',
      state: 'CT',
      postalCode: '06831',
      propertyType: 'SINGLE_FAMILY',
    },
  });

  // Update monthly funding
  await prisma.householdIntake.upsert({
    where: { householdId },
    update: {
      calculatedMonthlyFunding: 17422, // Total monthly lifestyle fixed costs
    },
    create: {
      householdId,
      calculatedMonthlyFunding: 17422,
    },
  });

  console.log('✅ Updated household to "The Morrison Family" at 38 Bedford Road');
  console.log('✅ Set Home Health Score to 94');

  console.log('\n🎉 Morrison family demo data seeded successfully!\n');
  console.log('Family: Bob, Alice (spouse), Emma (12), Jack (8), Maria Garcia (nanny)');
  console.log('Pets: Max (Golden Retriever, 4 years old)');
  console.log(`Zones: ${zoneCount} with ${assetCount} assets`);
  console.log('Vehicles: 3 (Tesla Model Y $895/mo, Toyota Highlander $775/mo, Mercedes GLE $1,082/mo)');
  console.log(`Bills: ${billCount}`);
  console.log('\nProperty: Inspiration Farm, 38 Bedford Road, Greenwich, CT 06831');
  console.log('Specs: 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres, built 1998');
}

main()
  .catch((e) => {
    console.error('Error seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
