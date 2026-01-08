/**
 * Seed Burke Household Demo Data - Essentials Tier
 *
 * Creates a fully populated demo household for:
 * - Testing Essentials tier features ($39/mo)
 * - Testing Alfred AI assistant
 * - Bypassing onboarding (data already exists)
 *
 * Run with: DATABASE_URL="postgresql://..." npx ts-node prisma/seed-burke.ts
 */

import {
  PrismaClient,
  FamilyMemberType,
  PetType,
  PetSize,
  HomeSystemType,
  VehicleType,
  VendorCategory,
  BillingFrequency,
  PaymentResponsibility,
  HouseholdSubscriptionPlan,
  HouseholdSubscriptionStatus,
  HouseholdRole,
  HouseholdMemberStatus,
} from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🏠 Seeding Burke Household Demo Data...\n');

  // ============================================================================
  // 1. CREATE OR UPDATE USERS
  // ============================================================================
  console.log('👤 Creating users...');

  // Create Tom Burke - Head of Household
  // Note: Firebase auth must be set up separately with tom@example.com / Tom123!
  const tom = await prisma.user.upsert({
    where: { email: 'tom@example.com' },
    update: {
      firstName: 'Tom',
      lastName: 'Burke',
      displayName: 'Tom Burke',
    },
    create: {
      email: 'tom@example.com',
      firstName: 'Tom',
      lastName: 'Burke',
      displayName: 'Tom Burke',
      role: 'HOMEOWNER',
      emailVerified: true,
    },
  });
  console.log(`✅ Created user: Tom Burke (${tom.id})`);

  // Create Mindy Burke - Spouse
  const mindy = await prisma.user.upsert({
    where: { email: 'mindy@example.com' },
    update: {
      firstName: 'Mindy',
      lastName: 'Burke',
      displayName: 'Mindy Burke',
    },
    create: {
      email: 'mindy@example.com',
      firstName: 'Mindy',
      lastName: 'Burke',
      displayName: 'Mindy Burke',
      role: 'HOMEOWNER',
      emailVerified: true,
    },
  });
  console.log(`✅ Created user: Mindy Burke (${mindy.id})`);

  // ============================================================================
  // 2. CREATE HOUSEHOLD
  // ============================================================================
  console.log('\n🏡 Creating household...');

  const household = await prisma.household.upsert({
    where: { id: 'burke-household-demo' },
    update: {
      name: 'The Burke Family',
      subscriptionPlan: HouseholdSubscriptionPlan.ESSENTIALS,
      subscriptionStatus: HouseholdSubscriptionStatus.ACTIVE,
    },
    create: {
      id: 'burke-household-demo',
      name: 'The Burke Family',
      description: 'Demo household for Essentials tier - AI-assisted home management',
      ownerId: tom.id,
      subscriptionPlan: HouseholdSubscriptionPlan.ESSENTIALS,
      subscriptionStatus: HouseholdSubscriptionStatus.ACTIVE,
    },
  });
  console.log(`✅ Created household: ${household.name} (${household.id})`);

  // ============================================================================
  // 3. CREATE HOUSEHOLD MEMBERSHIPS
  // ============================================================================
  console.log('\n👥 Creating household memberships...');

  // Tom as Owner
  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: household.id,
        userId: tom.id,
      },
    },
    update: { role: HouseholdRole.OWNER, status: HouseholdMemberStatus.ACTIVE },
    create: {
      householdId: household.id,
      userId: tom.id,
      role: HouseholdRole.OWNER,
      status: HouseholdMemberStatus.ACTIVE,
      nickname: 'Tom',
    },
  });

  // Mindy as Member
  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: household.id,
        userId: mindy.id,
      },
    },
    update: { role: HouseholdRole.MEMBER, status: HouseholdMemberStatus.ACTIVE },
    create: {
      householdId: household.id,
      userId: mindy.id,
      role: HouseholdRole.MEMBER,
      status: HouseholdMemberStatus.ACTIVE,
      nickname: 'Mindy',
    },
  });
  console.log('✅ Created household memberships for Tom and Mindy');

  // ============================================================================
  // 4. CREATE HOME PROFILE
  // ============================================================================
  console.log('\n🏠 Creating home profile...');

  await prisma.homeProfile.upsert({
    where: { householdId: household.id },
    update: {
      addressLine1: '146 Putnam Park Rd',
      city: 'Bethel',
      state: 'CT',
      postalCode: '06801',
    },
    create: {
      householdId: household.id,
      propertyType: 'SINGLE_FAMILY',
      addressLine1: '146 Putnam Park Rd',
      city: 'Bethel',
      state: 'CT',
      postalCode: '06801',
      country: 'US',
      bedrooms: 4,
      bathrooms: 3,
      yearBuilt: 1990,
    },
  });
  console.log('✅ Created home profile: 146 Putnam Park Rd, Bethel, CT 06801');

  // ============================================================================
  // 5. CREATE FAMILY MEMBERS (Non-User)
  // ============================================================================
  console.log('\n👨‍👩‍👧‍👦 Creating family members...');

  // Clear existing family members for this household
  await prisma.familyMember.deleteMany({ where: { householdId: household.id } });

  // Blake Burke - Daughter (3 years old)
  await prisma.familyMember.create({
    data: {
      householdId: household.id,
      firstName: 'Blake',
      lastName: 'Burke',
      type: FamilyMemberType.CHILD,
      relationship: 'Daughter',
      birthdate: new Date('2022-01-15'), // ~3 years old
    },
  });

  // Valerie Burke - Daughter (1 month old)
  await prisma.familyMember.create({
    data: {
      householdId: household.id,
      firstName: 'Valerie',
      lastName: 'Burke',
      type: FamilyMemberType.CHILD,
      relationship: 'Daughter',
      birthdate: new Date('2024-12-01'), // ~1 month old
      specialNeeds: 'Infant - requires frequent care',
    },
  });

  // Hevellyn Silva - Au Pair
  await prisma.familyMember.create({
    data: {
      householdId: household.id,
      firstName: 'Hevellyn',
      lastName: 'Silva',
      type: FamilyMemberType.STAFF,
      relationship: 'Au Pair',
      workSchedule: 'Live-in, flexible hours',
      responsibilities: 'Childcare, light housekeeping, meal prep for kids',
      startDate: new Date('2024-09-01'),
    },
  });

  console.log('✅ Created family members: Blake (3), Valerie (1 month), Hevellyn (Au Pair)');

  // ============================================================================
  // 6. CREATE PETS
  // ============================================================================
  console.log('\n🐕 Creating pets...');

  // Clear existing pets for this household
  await prisma.pet.deleteMany({ where: { householdId: household.id } });

  // Ryder - Australian Shepherd (9 years old)
  await prisma.pet.create({
    data: {
      householdId: household.id,
      name: 'Ryder',
      type: PetType.DOG,
      breed: 'Australian Shepherd',
      size: PetSize.MEDIUM,
      birthday: new Date('2016-03-15'), // ~9 years old
      gender: 'Male',
      isSpayedNeutered: true,
      feedingSchedule: '2x daily - morning and evening',
      careInstructions: 'High energy breed, needs daily exercise. Regular grooming for coat.',
    },
  });

  // Yoda - Black Lab Mix (5 years old)
  await prisma.pet.create({
    data: {
      householdId: household.id,
      name: 'Yoda',
      type: PetType.DOG,
      breed: 'Black Lab Mix',
      color: 'Black',
      size: PetSize.LARGE,
      birthday: new Date('2020-06-01'), // ~5 years old
      gender: 'Male',
      isSpayedNeutered: true,
      feedingSchedule: '2x daily - morning and evening',
      careInstructions: 'Friendly and energetic. Loves swimming and fetch.',
    },
  });

  console.log('✅ Created pets: Ryder (Australian Shepherd, 9), Yoda (Black Lab Mix, 5)');

  // ============================================================================
  // 7. CREATE VEHICLES
  // ============================================================================
  console.log('\n🚗 Creating vehicles...');

  // Clear existing vehicles for this household
  await prisma.vehicle.deleteMany({ where: { householdId: household.id } });

  // Mercedes GLS 2019
  await prisma.vehicle.create({
    data: {
      householdId: household.id,
      name: 'The Mercedes',
      make: 'Mercedes-Benz',
      model: 'GLS',
      year: 2019,
      vehicleType: VehicleType.SUV,
      color: 'Black',
      isOwned: true,
      isActive: true,
      hasLoan: false, // Paid off
      registrationState: 'CT',
    },
  });

  // Audi Q3 2016
  await prisma.vehicle.create({
    data: {
      householdId: household.id,
      name: 'The Audi',
      make: 'Audi',
      model: 'Q3',
      year: 2016,
      vehicleType: VehicleType.SUV,
      color: 'Silver',
      isOwned: true,
      isActive: true,
      hasLoan: false, // Paid off
      registrationState: 'CT',
    },
  });

  console.log('✅ Created vehicles: Mercedes GLS 2019, Audi Q3 2016 (both paid off)');

  // ============================================================================
  // 8. CREATE HOME SYSTEMS
  // ============================================================================
  console.log('\n🔧 Creating home systems...');

  // Clear existing home systems for this household
  await prisma.homeSystem.deleteMany({ where: { householdId: household.id } });

  // Oil Furnace
  await prisma.homeSystem.create({
    data: {
      householdId: household.id,
      name: 'Oil Furnace',
      type: HomeSystemType.FURNACE,
      location: 'Basement',
      notes: 'Oil heating system - requires annual service and oil deliveries. Fuel: Oil.',
      maintenanceIntervalMonths: 12,
    },
  });

  // Hot Water Tank
  await prisma.homeSystem.create({
    data: {
      householdId: household.id,
      name: 'Hot Water Tank',
      type: HomeSystemType.WATER_HEATER,
      location: 'Basement',
      notes: 'Standard tank water heater',
    },
  });

  // Backup Generator
  await prisma.homeSystem.create({
    data: {
      householdId: household.id,
      name: 'Backup Generator',
      type: HomeSystemType.GENERATOR,
      location: 'Exterior - side of house',
      notes: 'Propane-powered backup generator with propane tanks. Test monthly. Fuel: Propane.',
      maintenanceIntervalMonths: 12,
    },
  });

  // Chimney 1 - Living Room
  await prisma.homeSystem.create({
    data: {
      householdId: household.id,
      name: 'Chimney 1 - Living Room',
      type: HomeSystemType.FIREPLACE,
      location: 'Living Room',
      notes: 'Wood-burning fireplace. Annual chimney cleaning recommended.',
      maintenanceIntervalMonths: 12,
    },
  });

  // Chimney 2 - Family Room
  await prisma.homeSystem.create({
    data: {
      householdId: household.id,
      name: 'Chimney 2 - Family Room',
      type: HomeSystemType.FIREPLACE,
      location: 'Family Room',
      notes: 'Wood-burning fireplace. Annual chimney cleaning recommended.',
      maintenanceIntervalMonths: 12,
    },
  });

  console.log('✅ Created home systems: Oil Furnace, Hot Water Tank, Generator, 2 Chimneys');

  // ============================================================================
  // 9. CREATE VENDORS
  // ============================================================================
  console.log('\n🏪 Creating vendors...');

  // Clear existing vendors for this household (private vendors only)
  await prisma.vendor.deleteMany({ where: { householdId: household.id } });

  // Eversource (Electric)
  const eversource = await prisma.vendor.create({
    data: {
      householdId: household.id, // Private vendor for this household
      displayName: 'Eversource',
      category: VendorCategory.ELECTRIC,
      isLocal: false,
      phone: '800-286-2000',
      websiteUrl: 'https://www.eversource.com',
      serviceDescription: 'Electric utility provider',
    },
  });

  // Capital One (Mortgage)
  const capitalOne = await prisma.vendor.create({
    data: {
      householdId: household.id,
      displayName: 'Capital One',
      category: VendorCategory.MORTGAGE,
      isLocal: false,
      phone: '800-655-2265',
      websiteUrl: 'https://www.capitalone.com',
      serviceDescription: 'Primary mortgage lender',
    },
  });

  // Renata Cleaning Services
  const renata = await prisma.vendor.create({
    data: {
      householdId: household.id,
      displayName: 'Renata Cleaning Services',
      category: VendorCategory.CLEANING,
      isLocal: true,
      serviceDescription: 'House cleaning - only accepts cash or check',
    },
  });

  // Blue Fox Landscaping
  const blueFox = await prisma.vendor.create({
    data: {
      householdId: household.id,
      displayName: 'Blue Fox Landscaping',
      category: VendorCategory.LANDSCAPING,
      isLocal: true,
      serviceDescription: 'Lawn care and snow plowing services',
    },
  });

  console.log('✅ Created vendors: Eversource, Capital One, Renata Cleaning, Blue Fox Landscaping');

  // ============================================================================
  // 10. CREATE HOUSEHOLD-VENDOR RELATIONSHIPS
  // ============================================================================
  console.log('\n🔗 Creating vendor relationships...');

  // Clear existing household-vendor relationships
  await prisma.householdVendor.deleteMany({ where: { householdId: household.id } });

  for (const vendor of [eversource, capitalOne, renata, blueFox]) {
    await prisma.householdVendor.create({
      data: {
        householdId: household.id,
        vendorId: vendor.id,
        isFavorite: true,
      },
    });
  }
  console.log('✅ Linked all vendors to household');

  // ============================================================================
  // 11. CREATE BILL ACCOUNTS
  // ============================================================================
  console.log('\n💵 Creating bill accounts...');

  // Clear existing bill accounts for this household
  await prisma.billAccount.deleteMany({ where: { householdId: household.id } });

  // Electric Bill (Eversource)
  await prisma.billAccount.create({
    data: {
      householdId: household.id,
      vendorId: eversource.id,
      nickname: 'Electric Bill',
      category: VendorCategory.ELECTRIC,
      billingFrequency: BillingFrequency.MONTHLY,
      typicalAmount: 200,
      vendorAutopayEnabled: true,
      paymentResponsibility: PaymentResponsibility.VENDOR_AUTOPAY,
      isActive: true,
    },
  });

  // Mortgage (Capital One)
  await prisma.billAccount.create({
    data: {
      householdId: household.id,
      vendorId: capitalOne.id,
      nickname: 'Mortgage',
      category: VendorCategory.MORTGAGE,
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      isActive: true,
    },
  });

  // House Cleaning (Renata)
  await prisma.billAccount.create({
    data: {
      householdId: household.id,
      vendorId: renata.id,
      nickname: 'House Cleaning',
      category: VendorCategory.CLEANING,
      billingFrequency: BillingFrequency.BIWEEKLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      notes: 'Pay by check or cash - Renata does not accept credit cards',
      isActive: true,
    },
  });

  // Landscaping (Blue Fox)
  await prisma.billAccount.create({
    data: {
      householdId: household.id,
      vendorId: blueFox.id,
      nickname: 'Landscaping & Plowing',
      category: VendorCategory.LANDSCAPING,
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      notes: 'Includes lawn care (spring-fall) and snow plowing (winter)',
      isActive: true,
    },
  });

  console.log('✅ Created bill accounts for all vendors');

  // ============================================================================
  // 12. CREATE MAINTENANCE TASKS
  // ============================================================================
  console.log('\n📋 Creating maintenance tasks...');

  // Clear existing maintenance tasks
  await prisma.maintenanceTask.deleteMany({ where: { householdId: household.id } });

  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Annual Chimney Cleaning',
      description: 'Schedule chimney sweep for both chimneys before winter',
      category: 'CHIMNEY',
      status: 'PENDING',
      priority: 'MEDIUM',
      dueDate: new Date('2025-09-01'),
    },
  });

  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Oil Furnace Annual Service',
      description: 'Annual tune-up and inspection of oil furnace. Check oil levels.',
      category: 'HVAC',
      status: 'PENDING',
      priority: 'MEDIUM',
      dueDate: new Date('2025-10-01'),
    },
  });

  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Generator Test Run',
      description: 'Monthly test run of backup generator. Check propane levels.',
      category: 'GENERAL',
      status: 'PENDING',
      priority: 'LOW',
      dueDate: new Date('2025-02-01'),
    },
  });

  await prisma.maintenanceTask.create({
    data: {
      householdId: household.id,
      title: 'Schedule Oil Delivery',
      description: 'Need to find an oil delivery company and schedule first delivery',
      category: 'HVAC',
      status: 'PENDING',
      priority: 'HIGH',
      dueDate: new Date('2025-01-15'),
      notes: 'Ask Alfred for oil delivery recommendations in Bethel, CT area',
    },
  });

  console.log('✅ Created maintenance tasks');

  // ============================================================================
  // 13. CREATE HOUSEHOLD INTAKE (Mark onboarding as complete)
  // ============================================================================
  console.log('\n✅ Marking onboarding as complete...');

  await prisma.householdIntake.upsert({
    where: { householdId: household.id },
    update: {
      status: 'ACTIVE',
      progress: 100,
    },
    create: {
      householdId: household.id,
      status: 'ACTIVE',
      progress: 100,
      managerNotes: 'Demo household - data pre-populated',
    },
  });

  console.log('✅ Household intake marked as COMPLETED');

  // ============================================================================
  // SUMMARY
  // ============================================================================
  console.log('\n');
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('🎉 BURKE HOUSEHOLD DEMO DATA COMPLETE!');
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('');
  console.log('📧 Login Credentials:');
  console.log('   Email:    tom@example.com');
  console.log('   Password: Tom123!');
  console.log('');
  console.log('🏠 Household Details:');
  console.log(`   ID:       ${household.id}`);
  console.log('   Name:     The Burke Family');
  console.log('   Tier:     ESSENTIALS ($39/mo)');
  console.log('   Manager:  Alfred (AI)');
  console.log('   Address:  146 Putnam Park Rd, Bethel, CT 06801');
  console.log('');
  console.log('👨‍👩‍👧‍👦 Family:');
  console.log('   • Tom Burke (owner)');
  console.log('   • Mindy Burke (spouse)');
  console.log('   • Blake Burke (daughter, 3)');
  console.log('   • Valerie Burke (daughter, 1 month)');
  console.log('   • Hevellyn Silva (au pair)');
  console.log('');
  console.log('🐕 Pets:');
  console.log('   • Ryder (Australian Shepherd, 9)');
  console.log('   • Yoda (Black Lab Mix, 5)');
  console.log('');
  console.log('🚗 Vehicles:');
  console.log('   • Mercedes GLS 2019 (paid off)');
  console.log('   • Audi Q3 2016 (paid off)');
  console.log('');
  console.log('🔧 Systems:');
  console.log('   • Oil Furnace (needs oil delivery!)');
  console.log('   • Hot Water Tank');
  console.log('   • Backup Generator (propane)');
  console.log('   • 2 Chimneys (annual cleaning)');
  console.log('');
  console.log('💵 Vendors/Bills:');
  console.log('   • Eversource (electric, autopay)');
  console.log('   • Capital One (mortgage)');
  console.log('   • Renata Cleaning (biweekly, cash/check only)');
  console.log('   • Blue Fox Landscaping (lawn + plowing)');
  console.log('');
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('');
  console.log('💡 Test Alfred by asking:');
  console.log('   "What home systems do I have?"');
  console.log('   "Help me find an oil delivery company"');
  console.log('   "When is the chimney cleaning due?"');
  console.log('   "What pets do we have?"');
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
