import { PrismaClient, UserRole, MaintenanceCategory, VendorCategory } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

// Maintenance templates data
const maintenanceTemplates = [
  // HVAC
  {
    slug: 'hvac_tuneup_spring',
    title: 'HVAC Spring Tune-Up',
    description: 'Professional inspection and maintenance of cooling system before summer. Includes cleaning coils, checking refrigerant levels, and inspecting electrical connections.',
    category: MaintenanceCategory.HVAC,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 3, // March
    recommendedSeasonEndMonth: 5, // May
    defaultVendorCategory: VendorCategory.HVAC_SERVICE,
    estimatedCostMin: 75,
    estimatedCostMax: 200,
    sortOrder: 1,
  },
  {
    slug: 'hvac_tuneup_fall',
    title: 'HVAC Fall Tune-Up',
    description: 'Professional inspection and maintenance of heating system before winter. Includes checking heat exchanger, cleaning burners, and testing safety controls.',
    category: MaintenanceCategory.HVAC,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 9, // September
    recommendedSeasonEndMonth: 11, // November
    defaultVendorCategory: VendorCategory.HVAC_SERVICE,
    estimatedCostMin: 75,
    estimatedCostMax: 200,
    sortOrder: 2,
  },
  {
    slug: 'filter_replacement',
    title: 'HVAC Filter Replacement',
    description: 'Replace all HVAC air filters throughout the home. Use appropriate MERV rating for your system.',
    category: MaintenanceCategory.HVAC,
    recommendedFrequencyMonths: 3,
    defaultVendorCategory: VendorCategory.FILTER_SERVICE,
    estimatedCostMin: 20,
    estimatedCostMax: 100,
    sortOrder: 3,
  },

  // Roof & Gutters
  {
    slug: 'gutter_cleaning_spring',
    title: 'Gutter Cleaning (Spring)',
    description: 'Clean gutters and downspouts of debris accumulated over winter. Check for damage and ensure proper drainage.',
    category: MaintenanceCategory.ROOF_GUTTER,
    recommendedFrequencyMonths: 6,
    recommendedSeasonStartMonth: 3,
    recommendedSeasonEndMonth: 5,
    defaultVendorCategory: VendorCategory.GUTTER_CLEANING,
    estimatedCostMin: 100,
    estimatedCostMax: 300,
    sortOrder: 10,
  },
  {
    slug: 'gutter_cleaning_fall',
    title: 'Gutter Cleaning (Fall)',
    description: 'Clean gutters and downspouts after leaves fall. Critical to prevent ice dams and water damage during winter.',
    category: MaintenanceCategory.ROOF_GUTTER,
    recommendedFrequencyMonths: 6,
    recommendedSeasonStartMonth: 10,
    recommendedSeasonEndMonth: 11,
    defaultVendorCategory: VendorCategory.GUTTER_CLEANING,
    estimatedCostMin: 100,
    estimatedCostMax: 300,
    sortOrder: 11,
  },
  {
    slug: 'roof_inspection',
    title: 'Roof Inspection',
    description: 'Professional inspection of roof condition including shingles, flashing, vents, and potential leak points.',
    category: MaintenanceCategory.ROOF_GUTTER,
    recommendedFrequencyMonths: 24,
    recommendedSeasonStartMonth: 4,
    recommendedSeasonEndMonth: 10,
    estimatedCostMin: 150,
    estimatedCostMax: 400,
    sortOrder: 12,
  },

  // Chimney
  {
    slug: 'chimney_sweep',
    title: 'Chimney Sweep & Inspection',
    description: 'Professional cleaning of chimney flue and inspection for creosote buildup, cracks, and structural issues. Required for safe fireplace operation.',
    category: MaintenanceCategory.CHIMNEY,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 9,
    recommendedSeasonEndMonth: 10,
    propertyConditionsJson: { has_fireplace: true },
    defaultVendorCategory: VendorCategory.CHIMNEY_SWEEP,
    estimatedCostMin: 150,
    estimatedCostMax: 350,
    sortOrder: 20,
  },

  // Septic
  {
    slug: 'septic_pumping',
    title: 'Septic Tank Pumping',
    description: 'Professional pumping and inspection of septic tank. Prevents backups and extends system life.',
    category: MaintenanceCategory.SEPTIC,
    recommendedFrequencyMonths: 36,
    propertyConditionsJson: { has_septic: true },
    defaultVendorCategory: VendorCategory.SEPTIC_SERVICE,
    estimatedCostMin: 250,
    estimatedCostMax: 500,
    sortOrder: 30,
  },
  {
    slug: 'septic_inspection',
    title: 'Septic System Inspection',
    description: 'Comprehensive inspection of septic system including tank, distribution box, and drain field.',
    category: MaintenanceCategory.SEPTIC,
    recommendedFrequencyMonths: 12,
    propertyConditionsJson: { has_septic: true },
    defaultVendorCategory: VendorCategory.SEPTIC_SERVICE,
    estimatedCostMin: 100,
    estimatedCostMax: 200,
    sortOrder: 31,
  },

  // Pool
  {
    slug: 'pool_opening',
    title: 'Pool Opening (Spring)',
    description: 'Professional pool opening service including removing cover, equipment startup, chemical balancing, and cleaning.',
    category: MaintenanceCategory.POOL,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 4,
    recommendedSeasonEndMonth: 5,
    propertyConditionsJson: { has_pool: true },
    defaultVendorCategory: VendorCategory.POOL_SERVICE,
    estimatedCostMin: 200,
    estimatedCostMax: 400,
    sortOrder: 40,
  },
  {
    slug: 'pool_closing',
    title: 'Pool Closing (Fall)',
    description: 'Professional pool winterization including chemical treatment, equipment shutdown, and cover installation.',
    category: MaintenanceCategory.POOL,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 9,
    recommendedSeasonEndMonth: 10,
    propertyConditionsJson: { has_pool: true },
    defaultVendorCategory: VendorCategory.POOL_SERVICE,
    estimatedCostMin: 200,
    estimatedCostMax: 400,
    sortOrder: 41,
  },

  // Pest Control
  {
    slug: 'pest_inspection',
    title: 'Pest Inspection & Treatment',
    description: 'Quarterly inspection and preventive treatment for common household pests including ants, spiders, and rodents.',
    category: MaintenanceCategory.PEST,
    recommendedFrequencyMonths: 3,
    defaultVendorCategory: VendorCategory.PEST_CONTROL,
    estimatedCostMin: 75,
    estimatedCostMax: 150,
    sortOrder: 50,
  },
  {
    slug: 'termite_inspection',
    title: 'Termite Inspection',
    description: 'Annual professional termite inspection to detect and prevent wood-destroying insect damage.',
    category: MaintenanceCategory.PEST,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 3,
    recommendedSeasonEndMonth: 6,
    defaultVendorCategory: VendorCategory.PEST_CONTROL,
    estimatedCostMin: 75,
    estimatedCostMax: 150,
    sortOrder: 51,
  },

  // Landscaping
  {
    slug: 'lawn_fertilization',
    title: 'Lawn Fertilization',
    description: 'Seasonal lawn fertilization program for healthy grass. Timing varies by grass type and climate.',
    category: MaintenanceCategory.LANDSCAPING,
    recommendedFrequencyMonths: 3,
    recommendedSeasonStartMonth: 4,
    recommendedSeasonEndMonth: 10,
    defaultVendorCategory: VendorCategory.LAWN_CARE,
    estimatedCostMin: 50,
    estimatedCostMax: 150,
    sortOrder: 60,
  },
  {
    slug: 'tree_trimming',
    title: 'Tree Trimming',
    description: 'Professional tree trimming to maintain health, shape, and prevent hazards from overhanging branches.',
    category: MaintenanceCategory.LANDSCAPING,
    recommendedFrequencyMonths: 24,
    recommendedSeasonStartMonth: 11,
    recommendedSeasonEndMonth: 3,
    defaultVendorCategory: VendorCategory.LANDSCAPING,
    estimatedCostMin: 200,
    estimatedCostMax: 1000,
    sortOrder: 61,
  },
  {
    slug: 'sprinkler_blowout',
    title: 'Irrigation System Winterization',
    description: 'Blow out sprinkler system lines before freeze to prevent pipe damage. Critical in cold climates.',
    category: MaintenanceCategory.LANDSCAPING,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 10,
    recommendedSeasonEndMonth: 11,
    propertyConditionsJson: { has_sprinkler_system: true, climate_zone: 'cold' },
    defaultVendorCategory: VendorCategory.LANDSCAPING,
    estimatedCostMin: 50,
    estimatedCostMax: 150,
    sortOrder: 62,
  },

  // Safety
  {
    slug: 'smoke_detector_test',
    title: 'Smoke & CO Detector Test',
    description: 'Test all smoke and carbon monoxide detectors throughout the home. Replace batteries if needed.',
    category: MaintenanceCategory.SAFETY,
    recommendedFrequencyMonths: 6,
    estimatedCostMin: 0,
    estimatedCostMax: 50,
    sortOrder: 70,
  },
  {
    slug: 'fire_extinguisher_check',
    title: 'Fire Extinguisher Inspection',
    description: 'Check fire extinguisher pressure gauges, accessibility, and expiration dates. Replace or recharge as needed.',
    category: MaintenanceCategory.SAFETY,
    recommendedFrequencyMonths: 12,
    estimatedCostMin: 0,
    estimatedCostMax: 100,
    sortOrder: 71,
  },
  {
    slug: 'dryer_vent_cleaning',
    title: 'Dryer Vent Cleaning',
    description: 'Professional cleaning of dryer vent duct to prevent fire hazards and improve efficiency.',
    category: MaintenanceCategory.SAFETY,
    recommendedFrequencyMonths: 12,
    estimatedCostMin: 100,
    estimatedCostMax: 200,
    sortOrder: 72,
  },

  // Cleaning
  {
    slug: 'window_washing',
    title: 'Window Washing (Exterior)',
    description: 'Professional exterior window cleaning for all accessible windows.',
    category: MaintenanceCategory.CLEANING,
    recommendedFrequencyMonths: 6,
    recommendedSeasonStartMonth: 4,
    recommendedSeasonEndMonth: 10,
    defaultVendorCategory: VendorCategory.WINDOW_WASHING,
    estimatedCostMin: 150,
    estimatedCostMax: 400,
    sortOrder: 80,
  },
  {
    slug: 'power_washing',
    title: 'Power Washing (Exterior)',
    description: 'Power wash driveway, walkways, deck, and/or siding to remove dirt, mold, and mildew buildup.',
    category: MaintenanceCategory.CLEANING,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 4,
    recommendedSeasonEndMonth: 9,
    estimatedCostMin: 200,
    estimatedCostMax: 500,
    sortOrder: 81,
  },
  {
    slug: 'carpet_cleaning',
    title: 'Professional Carpet Cleaning',
    description: 'Deep cleaning of carpets to remove stains, allergens, and extend carpet life.',
    category: MaintenanceCategory.CLEANING,
    recommendedFrequencyMonths: 12,
    defaultVendorCategory: VendorCategory.CLEANING,
    estimatedCostMin: 150,
    estimatedCostMax: 400,
    sortOrder: 82,
  },

  // Plumbing
  {
    slug: 'water_heater_flush',
    title: 'Water Heater Flush',
    description: 'Drain and flush water heater to remove sediment buildup. Extends life and improves efficiency.',
    category: MaintenanceCategory.PLUMBING,
    recommendedFrequencyMonths: 12,
    estimatedCostMin: 100,
    estimatedCostMax: 200,
    sortOrder: 90,
  },
  {
    slug: 'sump_pump_test',
    title: 'Sump Pump Test',
    description: 'Test sump pump operation before wet season. Clean pit and check discharge line.',
    category: MaintenanceCategory.PLUMBING,
    recommendedFrequencyMonths: 6,
    recommendedSeasonStartMonth: 3,
    recommendedSeasonEndMonth: 4,
    propertyConditionsJson: { has_sump_pump: true },
    estimatedCostMin: 0,
    estimatedCostMax: 100,
    sortOrder: 91,
  },

  // Appliances
  {
    slug: 'refrigerator_coils',
    title: 'Refrigerator Coil Cleaning',
    description: 'Clean refrigerator condenser coils to maintain efficiency and prevent premature compressor failure.',
    category: MaintenanceCategory.APPLIANCES,
    recommendedFrequencyMonths: 12,
    estimatedCostMin: 0,
    estimatedCostMax: 75,
    sortOrder: 100,
  },
  {
    slug: 'garbage_disposal_cleaning',
    title: 'Garbage Disposal Cleaning',
    description: 'Deep clean garbage disposal to remove buildup and eliminate odors.',
    category: MaintenanceCategory.APPLIANCES,
    recommendedFrequencyMonths: 3,
    estimatedCostMin: 0,
    estimatedCostMax: 25,
    sortOrder: 101,
  },

  // Exterior
  {
    slug: 'deck_staining',
    title: 'Deck Staining/Sealing',
    description: 'Apply stain or sealant to wood deck to protect from weather damage and extend life.',
    category: MaintenanceCategory.EXTERIOR,
    recommendedFrequencyMonths: 24,
    recommendedSeasonStartMonth: 5,
    recommendedSeasonEndMonth: 9,
    propertyConditionsJson: { has_deck: true },
    estimatedCostMin: 200,
    estimatedCostMax: 800,
    sortOrder: 110,
  },
  {
    slug: 'exterior_caulking',
    title: 'Exterior Caulking Inspection',
    description: 'Inspect and repair caulking around windows, doors, and other exterior penetrations.',
    category: MaintenanceCategory.EXTERIOR,
    recommendedFrequencyMonths: 24,
    recommendedSeasonStartMonth: 4,
    recommendedSeasonEndMonth: 10,
    estimatedCostMin: 50,
    estimatedCostMax: 300,
    sortOrder: 111,
  },

  // General
  {
    slug: 'home_warranty_renewal',
    title: 'Review Home Warranty Coverage',
    description: 'Review home warranty coverage and renewal options. Assess if current coverage meets your needs.',
    category: MaintenanceCategory.GENERAL,
    recommendedFrequencyMonths: 12,
    defaultVendorCategory: VendorCategory.HOME_WARRANTY,
    estimatedCostMin: 0,
    estimatedCostMax: 0,
    sortOrder: 120,
  },
  {
    slug: 'emergency_kit_check',
    title: 'Emergency Kit Inspection',
    description: 'Check emergency supplies including flashlights, batteries, first aid kit, and non-perishable food items.',
    category: MaintenanceCategory.GENERAL,
    recommendedFrequencyMonths: 6,
    estimatedCostMin: 0,
    estimatedCostMax: 100,
    sortOrder: 121,
  },
];

async function main() {
  console.log('🌱 Starting database seed...');

  // Create service categories
  const categories = await Promise.all([
    prisma.serviceCategory.upsert({
      where: { name: 'Plumbing' },
      update: {},
      create: {
        name: 'Plumbing',
        description: 'Water pipes, fixtures, drains, and water heaters',
        icon: 'wrench',
        sortOrder: 1,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Electrical' },
      update: {},
      create: {
        name: 'Electrical',
        description: 'Wiring, outlets, panels, and electrical repairs',
        icon: 'zap',
        sortOrder: 2,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'HVAC' },
      update: {},
      create: {
        name: 'HVAC',
        description: 'Heating, ventilation, and air conditioning',
        icon: 'thermometer',
        sortOrder: 3,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Roofing' },
      update: {},
      create: {
        name: 'Roofing',
        description: 'Roof repairs, replacements, and inspections',
        icon: 'home',
        sortOrder: 4,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Landscaping' },
      update: {},
      create: {
        name: 'Landscaping',
        description: 'Lawn care, gardening, and outdoor maintenance',
        icon: 'tree',
        sortOrder: 5,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Cleaning' },
      update: {},
      create: {
        name: 'Cleaning',
        description: 'House cleaning and janitorial services',
        icon: 'sparkles',
        sortOrder: 6,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Pest Control' },
      update: {},
      create: {
        name: 'Pest Control',
        description: 'Insect and rodent control services',
        icon: 'bug',
        sortOrder: 7,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Appliance Repair' },
      update: {},
      create: {
        name: 'Appliance Repair',
        description: 'Repair and maintenance of home appliances',
        icon: 'settings',
        sortOrder: 8,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Painting' },
      update: {},
      create: {
        name: 'Painting',
        description: 'Interior and exterior painting services',
        icon: 'paintbrush',
        sortOrder: 9,
      },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'General Handyman' },
      update: {},
      create: {
        name: 'General Handyman',
        description: 'General repairs and maintenance tasks',
        icon: 'hammer',
        sortOrder: 10,
      },
    }),
  ]);

  console.log(`✅ Created ${categories.length} service categories`);

  // Hash passwords
  const demoPassword = await bcrypt.hash('Demo123!', 12);
  const adminPassword = await bcrypt.hash('Admin123!', 12);

  // Create admin user
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@haven.app' },
    update: {},
    create: {
      email: 'admin@haven.app',
      passwordHash: adminPassword,
      firstName: 'Admin',
      lastName: 'User',
      role: UserRole.ADMIN,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });

  console.log(`✅ Created admin user: ${adminUser.email}`);

  // Create a demo user
  const demoUser = await prisma.user.upsert({
    where: { email: 'demo@haven.app' },
    update: {},
    create: {
      email: 'demo@haven.app',
      passwordHash: demoPassword,
      firstName: 'Demo',
      lastName: 'User',
      role: UserRole.HOMEOWNER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });

  console.log(`✅ Created demo user: ${demoUser.email}`);

  // Create a manager user
  const managerPassword = await bcrypt.hash('Manager123!', 12);
  const managerUser = await prisma.user.upsert({
    where: { email: 'manager@haven.app' },
    update: {},
    create: {
      email: 'manager@haven.app',
      passwordHash: managerPassword,
      firstName: 'Property',
      lastName: 'Manager',
      role: UserRole.MANAGER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });

  console.log(`✅ Created manager user: ${managerUser.email}`);

  // Create a demo household with home profile
  const demoHousehold = await prisma.household.upsert({
    where: { id: 'demo-household-id' },
    update: {},
    create: {
      id: 'demo-household-id',
      name: 'Demo Home',
      description: 'A sample home for demonstration',
      ownerId: demoUser.id,
      members: {
        create: {
          userId: demoUser.id,
          role: 'OWNER',
          status: 'ACTIVE',
          joinedAt: new Date(),
        },
      },
      homeProfile: {
        create: {
          propertyType: 'SINGLE_FAMILY',
          addressLine1: '123 Demo Street',
          city: 'San Francisco',
          state: 'CA',
          postalCode: '94102',
          country: 'US',
          squareFeet: 2000,
          yearBuilt: 2010,
          bedrooms: 3,
          bathrooms: 2.5,
          stories: 2,
          garageSpaces: 2,
        },
      },
    },
  });

  console.log(`✅ Created demo household: ${demoHousehold.name}`);

  // Create some demo tasks
  const tasks = await Promise.all([
    prisma.task.create({
      data: {
        householdId: demoHousehold.id,
        createdById: demoUser.id,
        title: 'Change HVAC filters',
        description: 'Replace air filters in all HVAC units',
        status: 'PENDING',
        priority: 'MEDIUM',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        recurrence: 'MONTHLY',
      },
    }),
    prisma.task.create({
      data: {
        householdId: demoHousehold.id,
        createdById: demoUser.id,
        title: 'Test smoke detectors',
        description: 'Test all smoke and CO detectors in the house',
        status: 'PENDING',
        priority: 'HIGH',
        dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        recurrence: 'MONTHLY',
      },
    }),
    prisma.task.create({
      data: {
        householdId: demoHousehold.id,
        createdById: demoUser.id,
        title: 'Clean gutters',
        description: 'Remove debris from all gutters and downspouts',
        status: 'PENDING',
        priority: 'LOW',
        dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        recurrence: 'QUARTERLY',
      },
    }),
  ]);

  console.log(`✅ Created ${tasks.length} demo tasks`);

  // Create demo maintenance plans
  const maintenancePlans = await Promise.all([
    prisma.maintenancePlan.create({
      data: {
        householdId: demoHousehold.id,
        serviceCategoryId: categories.find((c) => c.name === 'HVAC')?.id,
        name: 'HVAC Annual Service',
        description: 'Annual inspection and maintenance of heating and cooling systems',
        frequency: 'ANNUALLY',
        nextDueDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
        estimatedCost: 150,
      },
    }),
    prisma.maintenancePlan.create({
      data: {
        householdId: demoHousehold.id,
        serviceCategoryId: categories.find((c) => c.name === 'Pest Control')?.id,
        name: 'Quarterly Pest Control',
        description: 'Regular pest prevention treatment',
        frequency: 'QUARTERLY',
        nextDueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        estimatedCost: 75,
      },
    }),
  ]);

  console.log(`✅ Created ${maintenancePlans.length} demo maintenance plans`);

  // Seed maintenance templates
  console.log('🔧 Seeding maintenance templates...');

  for (const template of maintenanceTemplates) {
    await prisma.maintenanceTemplate.upsert({
      where: { slug: template.slug },
      update: {
        title: template.title,
        description: template.description,
        category: template.category,
        recommendedFrequencyMonths: template.recommendedFrequencyMonths,
        recommendedSeasonStartMonth: template.recommendedSeasonStartMonth,
        recommendedSeasonEndMonth: template.recommendedSeasonEndMonth,
        propertyConditionsJson: template.propertyConditionsJson,
        defaultVendorCategory: template.defaultVendorCategory,
        estimatedCostMin: template.estimatedCostMin,
        estimatedCostMax: template.estimatedCostMax,
        sortOrder: template.sortOrder,
      },
      create: {
        slug: template.slug,
        title: template.title,
        description: template.description,
        category: template.category,
        recommendedFrequencyMonths: template.recommendedFrequencyMonths,
        recommendedSeasonStartMonth: template.recommendedSeasonStartMonth,
        recommendedSeasonEndMonth: template.recommendedSeasonEndMonth,
        propertyConditionsJson: template.propertyConditionsJson,
        defaultVendorCategory: template.defaultVendorCategory,
        estimatedCostMin: template.estimatedCostMin,
        estimatedCostMax: template.estimatedCostMax,
        sortOrder: template.sortOrder,
      },
    });
  }

  console.log(`✅ Seeded ${maintenanceTemplates.length} maintenance templates`);

  // Create a demo subscription
  const subscription = await prisma.subscription.create({
    data: {
      userId: demoUser.id,
      tier: 'BASIC',
      status: 'ACTIVE',
      currentPeriodStart: new Date(),
      currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
  });

  console.log(`✅ Created demo subscription: ${subscription.tier}`);

  console.log('');
  console.log('🎉 Database seed completed successfully!');
  console.log('');
  console.log('Demo credentials:');
  console.log('  Admin:   admin@haven.app / Admin123!');
  console.log('  Manager: manager@haven.app / Manager123!');
  console.log('  User:    demo@haven.app / Demo123!');
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error('❌ Seed failed:', e);
    await prisma.$disconnect();
    process.exit(1);
  });
