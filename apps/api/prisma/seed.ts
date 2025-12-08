import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

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
  console.log('  Admin: admin@haven.app / Admin123!');
  console.log('  User:  demo@haven.app / Demo123!');
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
