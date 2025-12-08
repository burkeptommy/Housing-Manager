import {
  PrismaClient,
  UserRole,
  MaintenanceCategory,
  VendorCategory,
  BillingFrequency,
  PaymentResponsibility,
  MaintenanceTaskStatus,
  TaskPriority,
} from '@prisma/client';
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
    recommendedSeasonStartMonth: 3,
    recommendedSeasonEndMonth: 5,
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
    recommendedSeasonStartMonth: 9,
    recommendedSeasonEndMonth: 11,
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
    description: 'Clean gutters and downspouts of debris accumulated over winter.',
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
    description: 'Clean gutters and downspouts after leaves fall.',
    category: MaintenanceCategory.ROOF_GUTTER,
    recommendedFrequencyMonths: 6,
    recommendedSeasonStartMonth: 10,
    recommendedSeasonEndMonth: 11,
    defaultVendorCategory: VendorCategory.GUTTER_CLEANING,
    estimatedCostMin: 100,
    estimatedCostMax: 300,
    sortOrder: 11,
  },
  // Chimney
  {
    slug: 'chimney_sweep',
    title: 'Chimney Sweep & Inspection',
    description: 'Professional cleaning of chimney flue and inspection for creosote buildup.',
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
    description: 'Professional pumping and inspection of septic tank.',
    category: MaintenanceCategory.SEPTIC,
    recommendedFrequencyMonths: 36,
    propertyConditionsJson: { has_septic: true },
    defaultVendorCategory: VendorCategory.SEPTIC_SERVICE,
    estimatedCostMin: 250,
    estimatedCostMax: 500,
    sortOrder: 30,
  },
  // Pool
  {
    slug: 'pool_opening',
    title: 'Pool Opening (Spring)',
    description: 'Professional pool opening service including removing cover, equipment startup, and chemical balancing.',
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
    description: 'Professional pool winterization.',
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
    description: 'Quarterly inspection and preventive treatment.',
    category: MaintenanceCategory.PEST,
    recommendedFrequencyMonths: 3,
    defaultVendorCategory: VendorCategory.PEST_CONTROL,
    estimatedCostMin: 75,
    estimatedCostMax: 150,
    sortOrder: 50,
  },
  // Landscaping
  {
    slug: 'lawn_fertilization',
    title: 'Lawn Fertilization',
    description: 'Seasonal lawn fertilization program.',
    category: MaintenanceCategory.LANDSCAPING,
    recommendedFrequencyMonths: 3,
    recommendedSeasonStartMonth: 4,
    recommendedSeasonEndMonth: 10,
    defaultVendorCategory: VendorCategory.LAWN_CARE,
    estimatedCostMin: 50,
    estimatedCostMax: 150,
    sortOrder: 60,
  },
  // Safety
  {
    slug: 'smoke_detector_test',
    title: 'Smoke & CO Detector Test',
    description: 'Test all smoke and carbon monoxide detectors.',
    category: MaintenanceCategory.SAFETY,
    recommendedFrequencyMonths: 6,
    estimatedCostMin: 0,
    estimatedCostMax: 50,
    sortOrder: 70,
  },
  // Cleaning
  {
    slug: 'window_washing',
    title: 'Window Washing (Exterior)',
    description: 'Professional exterior window cleaning.',
    category: MaintenanceCategory.CLEANING,
    recommendedFrequencyMonths: 6,
    recommendedSeasonStartMonth: 4,
    recommendedSeasonEndMonth: 10,
    defaultVendorCategory: VendorCategory.WINDOW_WASHING,
    estimatedCostMin: 150,
    estimatedCostMax: 400,
    sortOrder: 80,
  },
  // Plumbing
  {
    slug: 'water_heater_flush',
    title: 'Water Heater Flush',
    description: 'Drain and flush water heater to remove sediment.',
    category: MaintenanceCategory.PLUMBING,
    recommendedFrequencyMonths: 12,
    estimatedCostMin: 100,
    estimatedCostMax: 200,
    sortOrder: 90,
  },
];

// Demo vendors for the household
const demoVendors = [
  // Bills
  {
    displayName: 'First National Mortgage',
    category: VendorCategory.MORTGAGE,
    phone: '1-800-555-0100',
    email: 'support@firstnationalmortgage.example.com',
    website: 'https://firstnationalmortgage.example.com',
  },
  {
    displayName: 'Regional Electric Co.',
    category: VendorCategory.ELECTRIC,
    phone: '1-800-555-0101',
    email: 'service@regionalelectric.example.com',
    website: 'https://regionalelectric.example.com',
  },
  {
    displayName: 'City Gas & Heating',
    category: VendorCategory.GAS,
    phone: '1-800-555-0102',
    email: 'support@citygas.example.com',
    website: 'https://citygas.example.com',
  },
  {
    displayName: 'Municipal Water Authority',
    category: VendorCategory.WATER_SEWER,
    phone: '1-800-555-0103',
    email: 'billing@waterauthority.example.gov',
    website: 'https://waterauthority.example.gov',
  },
  {
    displayName: 'Waste Management Services',
    category: VendorCategory.TRASH,
    phone: '1-800-555-0104',
    email: 'service@wastemanagement.example.com',
    website: 'https://wastemanagement.example.com',
  },
  {
    displayName: 'FiberNet Internet',
    category: VendorCategory.INTERNET,
    phone: '1-800-555-0105',
    email: 'support@fibernet.example.com',
    website: 'https://fibernet.example.com',
  },
  // Service vendors
  {
    displayName: 'Green Thumb Lawn Care',
    category: VendorCategory.LAWN_CARE,
    phone: '555-0110',
    email: 'service@greenthumb.example.com',
    website: 'https://greenthumb.example.com',
  },
  {
    displayName: 'Bug-Free Pest Control',
    category: VendorCategory.PEST_CONTROL,
    phone: '555-0111',
    email: 'schedule@bugfree.example.com',
    website: 'https://bugfree.example.com',
  },
  {
    displayName: 'Sparkle Clean Services',
    category: VendorCategory.CLEANING,
    phone: '555-0112',
    email: 'book@sparkleclean.example.com',
    website: 'https://sparkleclean.example.com',
  },
  {
    displayName: 'Snow Away Removal',
    category: VendorCategory.SNOW_REMOVAL,
    phone: '555-0113',
    email: 'service@snowaway.example.com',
    website: 'https://snowaway.example.com',
  },
  {
    displayName: 'Chimney Masters',
    category: VendorCategory.CHIMNEY_SWEEP,
    phone: '555-0114',
    email: 'schedule@chimneymasters.example.com',
    website: 'https://chimneymasters.example.com',
  },
  {
    displayName: 'Reliable Septic Services',
    category: VendorCategory.SEPTIC_SERVICE,
    phone: '555-0115',
    email: 'service@reliableseptic.example.com',
    website: 'https://reliableseptic.example.com',
  },
  {
    displayName: 'Crystal Clear Pool Service',
    category: VendorCategory.POOL_SERVICE,
    phone: '555-0116',
    email: 'schedule@crystalclearpool.example.com',
    website: 'https://crystalclearpool.example.com',
  },
];

// Bill accounts with realistic frequencies and amounts
function getBillAccounts(householdId: string, vendorMap: Map<VendorCategory, string>) {
  const today = new Date();

  return [
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.MORTGAGE)!,
      nickname: 'Home Mortgage',
      category: VendorCategory.MORTGAGE,
      accountNumber: 'MTG-12345678',
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 2450.00,
      nextDueDate: new Date(today.getFullYear(), today.getMonth(), 1), // 1st of month
      autopayEnabled: true,
      portalUrl: 'https://firstnationalmortgage.example.com/portal',
      supportPhone: '1-800-555-0100',
      notes: '30-year fixed @ 6.25%',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.ELECTRIC)!,
      nickname: 'Electric',
      category: VendorCategory.ELECTRIC,
      accountNumber: 'ELEC-98765',
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 185.00,
      nextDueDate: new Date(today.getFullYear(), today.getMonth(), 15),
      autopayEnabled: false,
      portalUrl: 'https://regionalelectric.example.com/mybill',
      supportPhone: '1-800-555-0101',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.GAS)!,
      nickname: 'Natural Gas',
      category: VendorCategory.GAS,
      accountNumber: 'GAS-456789',
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 95.00,
      nextDueDate: new Date(today.getFullYear(), today.getMonth(), 20),
      autopayEnabled: true,
      portalUrl: 'https://citygas.example.com/account',
      supportPhone: '1-800-555-0102',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.WATER_SEWER)!,
      nickname: 'Water & Sewer',
      category: VendorCategory.WATER_SEWER,
      accountNumber: 'WTR-123456',
      billingFrequency: BillingFrequency.QUARTERLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 180.00,
      nextDueDate: new Date(today.getFullYear(), Math.floor(today.getMonth() / 3) * 3 + 2, 1),
      autopayEnabled: false,
      portalUrl: 'https://waterauthority.example.gov/pay',
      supportPhone: '1-800-555-0103',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.TRASH)!,
      nickname: 'Trash & Recycling',
      category: VendorCategory.TRASH,
      accountNumber: 'WM-789012',
      billingFrequency: BillingFrequency.QUARTERLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 95.00,
      nextDueDate: new Date(today.getFullYear(), Math.floor(today.getMonth() / 3) * 3 + 2, 15),
      autopayEnabled: true,
      portalUrl: 'https://wastemanagement.example.com/mybill',
      supportPhone: '1-800-555-0104',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.INTERNET)!,
      nickname: 'Internet',
      category: VendorCategory.INTERNET,
      accountNumber: 'FNET-345678',
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 79.99,
      nextDueDate: new Date(today.getFullYear(), today.getMonth(), 5),
      autopayEnabled: true,
      portalUrl: 'https://fibernet.example.com/account',
      supportPhone: '1-800-555-0105',
      notes: '500 Mbps plan',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.LAWN_CARE)!,
      nickname: 'Lawn Care Service',
      category: VendorCategory.LAWN_CARE,
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.HAVEN_PAYS_ON_BEHALF,
      typicalAmount: 175.00,
      nextDueDate: new Date(today.getFullYear(), today.getMonth(), 28),
      autopayEnabled: false,
      notes: 'Weekly mowing, April-October. Includes edging and blowing.',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.PEST_CONTROL)!,
      nickname: 'Pest Control',
      category: VendorCategory.PEST_CONTROL,
      billingFrequency: BillingFrequency.QUARTERLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 125.00,
      nextDueDate: new Date(today.getFullYear(), Math.floor(today.getMonth() / 3) * 3 + 2, 10),
      autopayEnabled: false,
      notes: 'Quarterly treatment - interior/exterior',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.CLEANING)!,
      nickname: 'House Cleaning',
      category: VendorCategory.CLEANING,
      billingFrequency: BillingFrequency.BIWEEKLY,
      paymentResponsibility: PaymentResponsibility.HAVEN_PAYS_ON_BEHALF,
      typicalAmount: 180.00,
      nextDueDate: new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7),
      autopayEnabled: false,
      notes: 'Bi-weekly deep cleaning',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.SNOW_REMOVAL)!,
      nickname: 'Snow Removal',
      category: VendorCategory.SNOW_REMOVAL,
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 150.00,
      nextDueDate: new Date(today.getFullYear(), 11, 1), // December
      autopayEnabled: false,
      notes: 'November-March, per occurrence',
    },
    {
      householdId,
      vendorId: vendorMap.get(VendorCategory.POOL_SERVICE)!,
      nickname: 'Pool Service',
      category: VendorCategory.POOL_SERVICE,
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.HAVEN_PAYS_ON_BEHALF,
      typicalAmount: 225.00,
      nextDueDate: new Date(today.getFullYear(), today.getMonth(), 25),
      autopayEnabled: false,
      notes: 'Weekly service May-September',
    },
  ];
}

// Generate maintenance tasks for 12 months
function generateMaintenanceTasks(
  householdId: string,
  vendorMap: Map<VendorCategory, string>,
  templates: { id: string; slug: string; title: string; category: MaintenanceCategory; estimatedCostMin: { toNumber: () => number } | null }[],
) {
  const tasks: {
    householdId: string;
    templateId?: string;
    assignedVendorId?: string;
    title: string;
    description?: string;
    category: MaintenanceCategory;
    status: MaintenanceTaskStatus;
    dueDate: Date;
    estimatedCost?: number;
    priority: TaskPriority;
    createdFromTemplate: boolean;
  }[] = [];

  const now = new Date();
  const currentYear = now.getFullYear();

  // Specific tasks based on property features (septic, chimney, lawn, snow, pool)
  const propertyTasks = [
    // HVAC - Spring and Fall tune-ups
    {
      title: 'HVAC Spring Tune-Up',
      category: MaintenanceCategory.HVAC,
      dueDate: new Date(currentYear, 3, 15), // April
      estimatedCost: 150,
      vendorCategory: VendorCategory.HVAC_SERVICE,
      status: now.getMonth() > 3 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'HVAC Fall Tune-Up',
      category: MaintenanceCategory.HVAC,
      dueDate: new Date(currentYear, 9, 15), // October
      estimatedCost: 150,
      vendorCategory: VendorCategory.HVAC_SERVICE,
      status: now.getMonth() > 9 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    // Gutter cleaning
    {
      title: 'Gutter Cleaning (Spring)',
      category: MaintenanceCategory.ROOF_GUTTER,
      dueDate: new Date(currentYear, 3, 1),
      estimatedCost: 175,
      vendorCategory: VendorCategory.GUTTER_CLEANING,
      status: now.getMonth() > 3 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'Gutter Cleaning (Fall)',
      category: MaintenanceCategory.ROOF_GUTTER,
      dueDate: new Date(currentYear, 10, 1),
      estimatedCost: 175,
      vendorCategory: VendorCategory.GUTTER_CLEANING,
      status: now.getMonth() > 10 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    // Chimney sweep
    {
      title: 'Chimney Sweep & Inspection',
      category: MaintenanceCategory.CHIMNEY,
      dueDate: new Date(currentYear, 8, 15), // September
      estimatedCost: 250,
      vendorCategory: VendorCategory.CHIMNEY_SWEEP,
      status: now.getMonth() > 8 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    // Pool opening/closing
    {
      title: 'Pool Opening',
      category: MaintenanceCategory.POOL,
      dueDate: new Date(currentYear, 4, 1), // May
      estimatedCost: 300,
      vendorCategory: VendorCategory.POOL_SERVICE,
      status: now.getMonth() > 4 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'Pool Closing & Winterization',
      category: MaintenanceCategory.POOL,
      dueDate: new Date(currentYear, 9, 1), // October
      estimatedCost: 350,
      vendorCategory: VendorCategory.POOL_SERVICE,
      status: now.getMonth() > 9 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    // Septic
    {
      title: 'Septic System Inspection',
      category: MaintenanceCategory.SEPTIC,
      dueDate: new Date(currentYear, 5, 15), // June
      estimatedCost: 150,
      vendorCategory: VendorCategory.SEPTIC_SERVICE,
      status: now.getMonth() > 5 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    // Lawn fertilization (quarterly)
    {
      title: 'Lawn Fertilization - Spring',
      category: MaintenanceCategory.LANDSCAPING,
      dueDate: new Date(currentYear, 3, 10),
      estimatedCost: 100,
      vendorCategory: VendorCategory.LAWN_CARE,
      status: now.getMonth() > 3 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'Lawn Fertilization - Summer',
      category: MaintenanceCategory.LANDSCAPING,
      dueDate: new Date(currentYear, 6, 10),
      estimatedCost: 100,
      vendorCategory: VendorCategory.LAWN_CARE,
      status: now.getMonth() > 6 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'Lawn Fertilization - Fall',
      category: MaintenanceCategory.LANDSCAPING,
      dueDate: new Date(currentYear, 9, 10),
      estimatedCost: 100,
      vendorCategory: VendorCategory.LAWN_CARE,
      status: now.getMonth() > 9 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    // Safety
    {
      title: 'Smoke & CO Detector Test - Spring',
      category: MaintenanceCategory.SAFETY,
      dueDate: new Date(currentYear, 2, 10),
      estimatedCost: 0,
      status: now.getMonth() > 2 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'Smoke & CO Detector Test - Fall',
      category: MaintenanceCategory.SAFETY,
      dueDate: new Date(currentYear, 10, 3),
      estimatedCost: 0,
      status: now.getMonth() > 10 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    // Pest control (quarterly)
    {
      title: 'Pest Control Treatment - Q1',
      category: MaintenanceCategory.PEST,
      dueDate: new Date(currentYear, 2, 15),
      estimatedCost: 125,
      vendorCategory: VendorCategory.PEST_CONTROL,
      status: now.getMonth() > 2 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'Pest Control Treatment - Q2',
      category: MaintenanceCategory.PEST,
      dueDate: new Date(currentYear, 5, 15),
      estimatedCost: 125,
      vendorCategory: VendorCategory.PEST_CONTROL,
      status: now.getMonth() > 5 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'Pest Control Treatment - Q3',
      category: MaintenanceCategory.PEST,
      dueDate: new Date(currentYear, 8, 15),
      estimatedCost: 125,
      vendorCategory: VendorCategory.PEST_CONTROL,
      status: now.getMonth() > 8 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
    {
      title: 'Pest Control Treatment - Q4',
      category: MaintenanceCategory.PEST,
      dueDate: new Date(currentYear, 11, 15),
      estimatedCost: 125,
      vendorCategory: VendorCategory.PEST_CONTROL,
      status: now.getMonth() > 11 ? MaintenanceTaskStatus.COMPLETED : MaintenanceTaskStatus.PENDING,
    },
  ];

  for (const task of propertyTasks) {
    // Find matching template
    const template = templates.find((t) => t.title.toLowerCase().includes(task.title.split(' - ')[0].toLowerCase().substring(0, 10)));

    tasks.push({
      householdId,
      templateId: template?.id,
      assignedVendorId: task.vendorCategory ? vendorMap.get(task.vendorCategory) : undefined,
      title: task.title,
      category: task.category,
      status: task.status,
      dueDate: task.dueDate,
      estimatedCost: task.estimatedCost,
      priority: TaskPriority.MEDIUM,
      createdFromTemplate: !!template,
    });
  }

  return tasks;
}

async function main() {
  console.log('🌱 Starting database seed...');

  // Create service categories
  const categories = await Promise.all([
    prisma.serviceCategory.upsert({
      where: { name: 'Plumbing' },
      update: {},
      create: { name: 'Plumbing', description: 'Water pipes, fixtures, drains', icon: 'wrench', sortOrder: 1 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Electrical' },
      update: {},
      create: { name: 'Electrical', description: 'Wiring, outlets, panels', icon: 'zap', sortOrder: 2 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'HVAC' },
      update: {},
      create: { name: 'HVAC', description: 'Heating and air conditioning', icon: 'thermometer', sortOrder: 3 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Roofing' },
      update: {},
      create: { name: 'Roofing', description: 'Roof repairs and inspections', icon: 'home', sortOrder: 4 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Landscaping' },
      update: {},
      create: { name: 'Landscaping', description: 'Lawn care and outdoor', icon: 'tree', sortOrder: 5 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Cleaning' },
      update: {},
      create: { name: 'Cleaning', description: 'House cleaning services', icon: 'sparkles', sortOrder: 6 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Pest Control' },
      update: {},
      create: { name: 'Pest Control', description: 'Insect and rodent control', icon: 'bug', sortOrder: 7 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Appliance Repair' },
      update: {},
      create: { name: 'Appliance Repair', description: 'Home appliance repair', icon: 'settings', sortOrder: 8 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'Painting' },
      update: {},
      create: { name: 'Painting', description: 'Interior and exterior painting', icon: 'paintbrush', sortOrder: 9 },
    }),
    prisma.serviceCategory.upsert({
      where: { name: 'General Handyman' },
      update: {},
      create: { name: 'General Handyman', description: 'General repairs', icon: 'hammer', sortOrder: 10 },
    }),
  ]);

  console.log(`✅ Created ${categories.length} service categories`);

  // Hash passwords
  const demoPassword = await bcrypt.hash('Demo123!', 12);
  const adminPassword = await bcrypt.hash('Admin123!', 12);
  const managerPassword = await bcrypt.hash('Manager123!', 12);

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

  // Create manager user
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

  // Create demo user with Stripe customer ID
  const demoUser = await prisma.user.upsert({
    where: { email: 'demo@haven.app' },
    update: {
      stripeCustomerId: 'cus_demo_test_123456',
    },
    create: {
      email: 'demo@haven.app',
      passwordHash: demoPassword,
      firstName: 'Sarah',
      lastName: 'Johnson',
      role: UserRole.HOMEOWNER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
      stripeCustomerId: 'cus_demo_test_123456',
    },
  });
  console.log(`✅ Created demo user: ${demoUser.email}`);

  // Create demo household with comprehensive home profile
  const demoHousehold = await prisma.household.upsert({
    where: { id: 'demo-household-id' },
    update: {},
    create: {
      id: 'demo-household-id',
      name: 'The Johnson Residence',
      description: 'A beautiful single-family home in a quiet neighborhood',
      ownerId: demoUser.id,
      stripeCustomerId: 'cus_household_demo_123',
      consolidatedBillingDay: 1,
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
          addressLine1: '456 Oak Lane',
          city: 'Pleasantville',
          state: 'CT',
          postalCode: '06001',
          country: 'US',
          squareFeet: 2800,
          yearBuilt: 2005,
          bedrooms: 3,
          bathrooms: 2.5,
          stories: 2,
          garageSpaces: 2,
          notes: JSON.stringify({
            systems: {
              hasPool: true,
              poolType: 'inground',
              hasHotTub: false,
              septicOrSewer: 'septic',
              hasFireplace: true,
              fireplaceType: 'wood-burning',
              hasSprinklerSystem: true,
              hasSecuritySystem: true,
              hasSmartHome: false,
              hasSolarPanels: false,
              hasGenerator: false,
              hasSumpPump: true,
              hasWellWater: false,
              hasRadonMitigation: false,
            },
            features: {
              hasDeck: true,
              deckMaterial: 'composite',
              hasBasement: true,
              basementType: 'finished',
              hasAttic: true,
              roofType: 'asphalt shingles',
              roofAge: 8,
              hvacType: 'central air/forced air',
              hvacAge: 5,
              waterHeaterType: 'tank',
              waterHeaterAge: 6,
            },
            notes: 'Beautiful property with mature landscaping. Pool was renovated in 2020.',
          }),
        },
      },
    },
  });
  console.log(`✅ Created demo household: ${demoHousehold.name}`);

  // Create vendors for the household
  console.log('🏢 Creating vendors...');
  const vendorMap = new Map<VendorCategory, string>();

  for (const vendorData of demoVendors) {
    const vendor = await prisma.vendor.upsert({
      where: {
        householdId_displayName: {
          householdId: demoHousehold.id,
          displayName: vendorData.displayName,
        },
      },
      update: vendorData,
      create: {
        ...vendorData,
        householdId: demoHousehold.id,
      },
    });
    vendorMap.set(vendorData.category, vendor.id);
  }
  console.log(`✅ Created ${demoVendors.length} vendors`);

  // Create bill accounts
  console.log('💰 Creating bill accounts...');
  const billAccountsData = getBillAccounts(demoHousehold.id, vendorMap);

  for (const billData of billAccountsData) {
    await prisma.billAccount.upsert({
      where: {
        householdId_nickname: {
          householdId: billData.householdId,
          nickname: billData.nickname,
        },
      },
      update: billData,
      create: billData,
    });
  }
  console.log(`✅ Created ${billAccountsData.length} bill accounts`);

  // Seed maintenance templates
  console.log('🔧 Seeding maintenance templates...');
  const createdTemplates: { id: string; slug: string; title: string; category: MaintenanceCategory; estimatedCostMin: { toNumber: () => number } | null }[] = [];

  for (const template of maintenanceTemplates) {
    const created = await prisma.maintenanceTemplate.upsert({
      where: { slug: template.slug },
      update: template,
      create: template,
    });
    createdTemplates.push({
      id: created.id,
      slug: created.slug,
      title: created.title,
      category: created.category,
      estimatedCostMin: created.estimatedCostMin ? { toNumber: () => Number(created.estimatedCostMin) } : null,
    });
  }
  console.log(`✅ Seeded ${maintenanceTemplates.length} maintenance templates`);

  // Generate maintenance tasks for 12 months
  console.log('📋 Generating maintenance tasks...');
  const maintenanceTasks = generateMaintenanceTasks(demoHousehold.id, vendorMap, createdTemplates);

  for (const taskData of maintenanceTasks) {
    await prisma.maintenanceTask.create({
      data: taskData,
    });
  }
  console.log(`✅ Created ${maintenanceTasks.length} maintenance tasks`);

  // Create a demo subscription
  const subscription = await prisma.subscription.upsert({
    where: { userId: demoUser.id },
    update: {},
    create: {
      userId: demoUser.id,
      tier: 'PREMIUM',
      status: 'ACTIVE',
      stripeSubscriptionId: 'sub_demo_test_123456',
      currentPeriodStart: new Date(),
      currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
  });
  console.log(`✅ Created demo subscription: ${subscription.tier}`);

  // Create some sample service requests
  console.log('📝 Creating sample service requests...');
  await prisma.serviceRequest.createMany({
    data: [
      {
        householdId: demoHousehold.id,
        createdById: demoUser.id,
        title: 'Leaky faucet in master bathroom',
        description: 'The hot water faucet in the master bathroom has been dripping for about a week.',
        category: 'Plumbing',
        status: 'COMPLETED',
        priority: 'MEDIUM',
        preferredDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
      },
      {
        householdId: demoHousehold.id,
        createdById: demoUser.id,
        title: 'Annual HVAC inspection',
        description: 'Need to schedule annual HVAC maintenance before summer.',
        category: 'HVAC',
        status: 'SCHEDULED',
        priority: 'LOW',
        preferredDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
      },
    ],
  });
  console.log('✅ Created sample service requests');

  console.log('');
  console.log('🎉 Database seed completed successfully!');
  console.log('');
  console.log('═══════════════════════════════════════════════════');
  console.log('  DEMO CREDENTIALS');
  console.log('═══════════════════════════════════════════════════');
  console.log('');
  console.log('  Admin User:');
  console.log('    Email:    admin@haven.app');
  console.log('    Password: Admin123!');
  console.log('');
  console.log('  Manager User:');
  console.log('    Email:    manager@haven.app');
  console.log('    Password: Manager123!');
  console.log('');
  console.log('  Demo Homeowner:');
  console.log('    Email:    demo@haven.app');
  console.log('    Password: Demo123!');
  console.log('');
  console.log('═══════════════════════════════════════════════════');
  console.log('');
  console.log('  Demo Household: The Johnson Residence');
  console.log('  - 3 bed, 2.5 bath single family home');
  console.log('  - Features: pool, septic, chimney, lawn, snow removal');
  console.log(`  - ${billAccountsData.length} bill accounts configured`);
  console.log(`  - ${maintenanceTasks.length} maintenance tasks for 12 months`);
  console.log('  - Premium subscription with Stripe integration');
  console.log('');
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
