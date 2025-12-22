import {
  PrismaClient,
  UserRole,
  MaintenanceCategory,
  VendorCategory,
  BillingFrequency,
  PaymentResponsibility,
  MaintenanceTaskStatus,
  TaskPriority,
  TransactionPayoutMethod,
  TransactionStatus,
  WorkOrderStatus,
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
    websiteUrl: 'https://firstnationalmortgage.example.com',
  },
  {
    displayName: 'Regional Electric Co.',
    category: VendorCategory.ELECTRIC,
    phone: '1-800-555-0101',
    email: 'service@regionalelectric.example.com',
    websiteUrl: 'https://regionalelectric.example.com',
  },
  {
    displayName: 'City Gas & Heating',
    category: VendorCategory.GAS,
    phone: '1-800-555-0102',
    email: 'support@citygas.example.com',
    websiteUrl: 'https://citygas.example.com',
  },
  {
    displayName: 'Municipal Water Authority',
    category: VendorCategory.WATER_SEWER,
    phone: '1-800-555-0103',
    email: 'billing@waterauthority.example.gov',
    websiteUrl: 'https://waterauthority.example.gov',
  },
  {
    displayName: 'Waste Management Services',
    category: VendorCategory.TRASH,
    phone: '1-800-555-0104',
    email: 'service@wastemanagement.example.com',
    websiteUrl: 'https://wastemanagement.example.com',
  },
  {
    displayName: 'FiberNet Internet',
    category: VendorCategory.INTERNET,
    phone: '1-800-555-0105',
    email: 'support@fibernet.example.com',
    websiteUrl: 'https://fibernet.example.com',
  },
  // Service vendors
  {
    displayName: 'Country Landscape Design',
    category: VendorCategory.LAWN_CARE,
    phone: '(203) 555-5296',
    email: 'service@countrylandscape.example.com',
    websiteUrl: 'https://countrylandscape.example.com',
  },
  {
    displayName: 'Terminix Northeast',
    category: VendorCategory.PEST_CONTROL,
    phone: '(203) 555-0111',
    email: 'schedule@terminix-ne.example.com',
    websiteUrl: 'https://terminix-ne.example.com',
  },
  {
    displayName: 'Molly Maid of Greenwich',
    category: VendorCategory.CLEANING,
    phone: '(203) 555-0112',
    email: 'book@mollymaid-greenwich.example.com',
    websiteUrl: 'https://mollymaid-greenwich.example.com',
  },
  {
    displayName: 'Fairfield County Snow Removal',
    category: VendorCategory.SNOW_REMOVAL,
    phone: '(203) 555-0113',
    email: 'service@fcsnow.example.com',
    websiteUrl: 'https://fcsnow.example.com',
  },
  {
    displayName: 'New England Chimney Sweeps',
    category: VendorCategory.CHIMNEY_SWEEP,
    phone: '(203) 555-0114',
    email: 'schedule@nechimney.example.com',
    websiteUrl: 'https://nechimney.example.com',
  },
  {
    displayName: 'Fairfield Septic Services',
    category: VendorCategory.SEPTIC_SERVICE,
    phone: '(203) 555-0115',
    email: 'service@fairfieldseptic.example.com',
    websiteUrl: 'https://fairfieldseptic.example.com',
  },
  {
    displayName: 'Pools Unlimited CT',
    category: VendorCategory.POOL_SERVICE,
    phone: '(203) 555-0116',
    email: 'schedule@poolsunlimitedct.example.com',
    websiteUrl: 'https://poolsunlimitedct.example.com',
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
      vendorAutopayEnabled: true,
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
      vendorAutopayEnabled: false,
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
      vendorAutopayEnabled: true,
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
      vendorAutopayEnabled: false,
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
      vendorAutopayEnabled: true,
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
      vendorAutopayEnabled: true,
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
      vendorAutopayEnabled: false,
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
      vendorAutopayEnabled: false,
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
      vendorAutopayEnabled: false,
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
      vendorAutopayEnabled: false,
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
      vendorAutopayEnabled: false,
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
  const adminPassword = await bcrypt.hash('Admin123!', 12);
  const managerPassword = await bcrypt.hash('Manager123!', 12);
  const homeownerPassword = await bcrypt.hash('Bob123!', 12);

  // Create Admin User (Platform Owner - You)
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@haven.app' },
    update: {},
    create: {
      email: 'admin@haven.app',
      passwordHash: adminPassword,
      firstName: 'Platform',
      lastName: 'Admin',
      displayName: 'Platform Admin',
      role: UserRole.ADMIN,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });
  console.log(`✅ Created admin user: ${adminUser.email} (Platform Owner)`);

  // Create Manager Steve (Haven Staff Member - Home Manager)
  const managerSteve = await prisma.user.upsert({
    where: { email: 'steve@haven.app' },
    update: {},
    create: {
      email: 'steve@haven.app',
      passwordHash: managerPassword,
      firstName: 'Steve',
      lastName: 'Manager',
      displayName: 'Manager Steve',
      role: UserRole.MANAGER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });
  console.log(`✅ Created staff user: ${managerSteve.email} (Home Manager)`);

  // Create Handyman Users (Internal Staff)
  const handymanPassword = await bcrypt.hash('Handy123!', 12);

  // Handyman #1 - Carlos (assigned to Westchester County, NY properties)
  const handymanCarlos = await prisma.user.upsert({
    where: { email: 'carlos@haven.app' },
    update: {},
    create: {
      email: 'carlos@haven.app',
      passwordHash: handymanPassword,
      firstName: 'Carlos',
      lastName: 'Reyes',
      displayName: 'Carlos Reyes',
      role: UserRole.HANDYMAN,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });
  console.log(`✅ Created handyman user: ${handymanCarlos.email}`);

  // Handyman #2 - Mike (assigned to Fairfield County, CT properties)
  const handymanDave = await prisma.user.upsert({
    where: { email: 'dave@haven.app' },
    update: {},
    create: {
      email: 'dave@haven.app',
      passwordHash: handymanPassword,
      firstName: 'Mike',
      lastName: 'Castellano',
      displayName: 'Mike Castellano',
      role: UserRole.HANDYMAN,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });
  console.log(`✅ Created handyman user: ${handymanDave.email}`);

  // Handyman #3 - Maria (floater - helps across all properties)
  const handymanMaria = await prisma.user.upsert({
    where: { email: 'maria@haven.app' },
    update: {},
    create: {
      email: 'maria@haven.app',
      passwordHash: handymanPassword,
      firstName: 'Maria',
      lastName: 'Santos',
      displayName: 'Maria Santos',
      role: UserRole.HANDYMAN,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });
  console.log(`✅ Created handyman user: ${handymanMaria.email}`);

  // Create Homeowner Bob (Client)
  const homeownerBob = await prisma.user.upsert({
    where: { email: 'bob@example.com' },
    update: {},
    create: {
      email: 'bob@example.com',
      passwordHash: homeownerPassword,
      firstName: 'Bob',
      lastName: 'Smith',
      displayName: 'Bob Smith',
      role: UserRole.HOMEOWNER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });
  console.log(`✅ Created homeowner user: ${homeownerBob.email} (Client)`);

  // Create Homeowner Alice (Client with 1 house, 4 family members)
  const alicePassword = await bcrypt.hash('Alice123!', 12);
  const homeownerAlice = await prisma.user.upsert({
    where: { email: 'alice@example.com' },
    update: {},
    create: {
      email: 'alice@example.com',
      passwordHash: alicePassword,
      firstName: 'Alice',
      lastName: 'Johnson',
      displayName: 'Alice Johnson',
      role: UserRole.HOMEOWNER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });
  console.log(`✅ Created homeowner user: ${homeownerAlice.email} (Client - 1 house, 4 family members)`);

  // Keep the original demo user for backward compatibility
  const demoUser = homeownerBob; // Alias for existing code

  // Create Bob's Villa - household with Manager Steve and Handyman Mike assigned
  const demoHousehold = await prisma.household.upsert({
    where: { id: 'demo-household-id' },
    update: {
      managerId: managerSteve.id,
      assignedHandymanId: handymanDave.id, // Mike handles Fairfield County CT properties
    },
    create: {
      id: 'demo-household-id',
      name: "Bob's Villa",
      description: 'A beautiful single-family home in Greenwich, CT managed by Haven',
      ownerId: homeownerBob.id,
      managerId: managerSteve.id,
      assignedHandymanId: handymanDave.id, // Mike handles Fairfield County CT properties
      stripeCustomerId: 'cus_household_demo_123',
      billingCycleDay: 1,
      billingSettings: {
        autoPayEnabled: true,
        autoPayLimit: 500, // Max auto-pay amount without approval
        preferredPaymentDay: 1,
        notifyBeforeDue: 3, // Days before due date to notify
      },
      members: {
        create: {
          userId: homeownerBob.id,
          role: 'OWNER',
          status: 'ACTIVE',
          joinedAt: new Date(),
        },
      },
      homeProfile: {
        create: {
          propertyType: 'SINGLE_FAMILY',
          addressLine1: '147 Round Hill Road',
          city: 'Greenwich',
          state: 'CT',
          postalCode: '06831',
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

  // Ensure Bob's membership exists (needed if household was previously created)
  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: demoHousehold.id,
        userId: homeownerBob.id,
      },
    },
    update: {
      role: 'OWNER',
      status: 'ACTIVE',
    },
    create: {
      householdId: demoHousehold.id,
      userId: homeownerBob.id,
      role: 'OWNER',
      status: 'ACTIVE',
      joinedAt: new Date(),
    },
  });
  console.log(`✅ Created household membership for Bob`);

  // ============================================================================
  // ALICE'S HOUSEHOLD - 1 house with 4 family members
  // ============================================================================

  const aliceHousehold = await prisma.household.upsert({
    where: { id: 'alice-household-id' },
    update: {
      managerId: managerSteve.id,
      assignedHandymanId: handymanCarlos.id, // Carlos handles Westchester County NY properties
    },
    create: {
      id: 'alice-household-id',
      name: "The Johnson Family Home",
      description: 'A cozy suburban family home in Scarsdale, NY with 4 family members',
      ownerId: homeownerAlice.id,
      managerId: managerSteve.id,
      assignedHandymanId: handymanCarlos.id, // Carlos handles Westchester County NY properties
      stripeCustomerId: 'cus_household_alice_123',
      billingCycleDay: 15,
      billingSettings: {
        autoPayEnabled: true,
        autoPayLimit: 300,
        preferredPaymentDay: 15,
        notifyBeforeDue: 5,
      },
      homeProfile: {
        create: {
          propertyType: 'SINGLE_FAMILY',
          addressLine1: '45 Fox Meadow Road',
          city: 'Scarsdale',
          state: 'NY',
          postalCode: '10583',
          country: 'US',
          squareFeet: 2200,
          yearBuilt: 1995,
          bedrooms: 4,
          bathrooms: 2.5,
          stories: 2,
          garageSpaces: 2,
          notes: JSON.stringify({
            systems: {
              hasPool: false,
              hasHotTub: true,
              septicOrSewer: 'sewer',
              hasFireplace: true,
              fireplaceType: 'gas',
              hasSprinklerSystem: true,
              hasSecuritySystem: true,
              hasSmartHome: true,
              hasSolarPanels: false,
              hasGenerator: true,
              hasSumpPump: true,
              hasWellWater: false,
              hasRadonMitigation: false,
            },
            features: {
              hasDeck: true,
              deckMaterial: 'wood',
              hasBasement: true,
              basementType: 'finished',
              hasAttic: true,
              roofType: 'asphalt shingles',
              roofAge: 5,
              hvacType: 'central air/forced air',
              hvacAge: 3,
              waterHeaterType: 'tankless',
              waterHeaterAge: 2,
            },
            notes: 'Well-maintained family home with recent upgrades. Smart home features throughout.',
          }),
        },
      },
    },
  });
  console.log(`✅ Created Alice's household: ${aliceHousehold.name}`);

  // Create Alice's membership as owner
  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: aliceHousehold.id,
        userId: homeownerAlice.id,
      },
    },
    update: {
      role: 'OWNER',
      status: 'ACTIVE',
    },
    create: {
      householdId: aliceHousehold.id,
      userId: homeownerAlice.id,
      role: 'OWNER',
      status: 'ACTIVE',
      joinedAt: new Date(),
      nickname: 'Alice (Owner)',
    },
  });

  // Create 3 additional family members for Alice's household (each needs a User account)
  const familyPassword = await bcrypt.hash('Family123!', 12);

  // Michael (Spouse)
  const michaelUser = await prisma.user.upsert({
    where: { email: 'michael.johnson@example.com' },
    update: {},
    create: {
      email: 'michael.johnson@example.com',
      passwordHash: familyPassword,
      firstName: 'Michael',
      lastName: 'Johnson',
      displayName: 'Michael Johnson',
      role: UserRole.HOMEOWNER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });

  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: aliceHousehold.id,
        userId: michaelUser.id,
      },
    },
    update: {},
    create: {
      householdId: aliceHousehold.id,
      userId: michaelUser.id,
      role: 'MEMBER',
      status: 'ACTIVE',
      joinedAt: new Date(),
      nickname: 'Michael (Spouse)',
      birthday: new Date('1982-03-15'),
    },
  });

  // Emma (Daughter - 14 years old)
  const emmaUser = await prisma.user.upsert({
    where: { email: 'emma.johnson@example.com' },
    update: {},
    create: {
      email: 'emma.johnson@example.com',
      passwordHash: familyPassword,
      firstName: 'Emma',
      lastName: 'Johnson',
      displayName: 'Emma Johnson',
      role: UserRole.HOMEOWNER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });

  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: aliceHousehold.id,
        userId: emmaUser.id,
      },
    },
    update: {},
    create: {
      householdId: aliceHousehold.id,
      userId: emmaUser.id,
      role: 'MEMBER',
      status: 'ACTIVE',
      joinedAt: new Date(),
      nickname: 'Emma (Daughter)',
      birthday: new Date('2010-06-22'),
      permissions: ['VIEW_CALENDAR', 'VIEW_MEMBERS'], // Limited permissions for minor
    },
  });

  // Jack (Son - 10 years old)
  const jackUser = await prisma.user.upsert({
    where: { email: 'jack.johnson@example.com' },
    update: {},
    create: {
      email: 'jack.johnson@example.com',
      passwordHash: familyPassword,
      firstName: 'Jack',
      lastName: 'Johnson',
      displayName: 'Jack Johnson',
      role: UserRole.HOMEOWNER,
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });

  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: aliceHousehold.id,
        userId: jackUser.id,
      },
    },
    update: {},
    create: {
      householdId: aliceHousehold.id,
      userId: jackUser.id,
      role: 'MEMBER',
      status: 'ACTIVE',
      joinedAt: new Date(),
      nickname: 'Jack (Son)',
      birthday: new Date('2014-11-08'),
      permissions: ['VIEW_CALENDAR'], // Very limited permissions for minor
    },
  });

  console.log(`✅ Created 4 family members for Alice's household`);

  // Create some service requests for Alice's household
  const generalCategory = categories.find((c) => c.name === 'General Handyman');
  const hvacCategoryAlice = categories.find((c) => c.name === 'HVAC');

  await prisma.serviceRequest.createMany({
    data: [
      {
        householdId: aliceHousehold.id,
        createdById: homeownerAlice.id,
        serviceCategoryId: generalCategory?.id,
        title: 'Fix squeaky door in master bedroom',
        description: 'The master bedroom door has been squeaking for a few weeks. Need to oil the hinges.',
        status: 'SUBMITTED',
        priority: 'LOW',
        preferredDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
      {
        householdId: aliceHousehold.id,
        createdById: homeownerAlice.id,
        serviceCategoryId: hvacCategoryAlice?.id,
        title: 'Smart thermostat installation',
        description: 'Want to upgrade to a Nest thermostat for better energy efficiency.',
        status: 'ASSIGNED',
        priority: 'MEDIUM',
        preferredDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
      },
    ],
    skipDuplicates: true,
  });
  console.log(`✅ Created service requests for Alice's household`);

  // Create a work order for Alice's household
  await prisma.workOrder.upsert({
    where: { id: 'wo-alice-hot-tub' },
    update: {},
    create: {
      id: 'wo-alice-hot-tub',
      householdId: aliceHousehold.id,
      createdByUserId: managerSteve.id,
      title: 'Hot Tub Annual Service',
      description: 'Annual maintenance for the backyard hot tub. Check filters, water chemistry, jets, and heater.',
      status: WorkOrderStatus.OPEN,
      estimatedCost: 275,
      scheduledStart: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      scheduledEnd: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      serviceArea: 'Springfield',
    },
  });
  console.log(`✅ Created work order for Alice's household`);

  // Create vendors for the household
  console.log('🏢 Creating vendors...');
  const vendorMap = new Map<VendorCategory, string>();

  for (const vendorData of demoVendors) {
    // Check if vendor exists first
    const existingVendor = await prisma.vendor.findFirst({
      where: {
        householdId: demoHousehold.id,
        displayName: vendorData.displayName,
      },
    });

    const vendor = existingVendor
      ? await prisma.vendor.update({
          where: { id: existingVendor.id },
          data: vendorData,
        })
      : await prisma.vendor.create({
          data: {
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
    // Check if bill account exists first
    const existingBill = await prisma.billAccount.findFirst({
      where: {
        householdId: billData.householdId,
        nickname: billData.nickname,
      },
    });

    if (existingBill) {
      await prisma.billAccount.update({
        where: { id: existingBill.id },
        data: billData,
      });
    } else {
      await prisma.billAccount.create({
        data: billData,
      });
    }
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
  const existingSubscription = await prisma.subscription.findFirst({
    where: { userId: demoUser.id },
  });

  const subscription = existingSubscription
    ? existingSubscription
    : await prisma.subscription.create({
        data: {
          userId: demoUser.id,
          tier: 'PREMIUM',
          status: 'ACTIVE',
          stripeSubscriptionId: 'sub_demo_test_123456',
          currentPeriodStart: new Date(),
          currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
      });
  console.log(`✅ Created demo subscription: ${subscription.tier}`);

  // Get the Plumbing and HVAC service categories for service requests
  const plumbingCategory = categories.find((c) => c.name === 'Plumbing');
  const hvacCategory = categories.find((c) => c.name === 'HVAC');

  // Create some sample service requests
  console.log('📝 Creating sample service requests...');
  await prisma.serviceRequest.createMany({
    data: [
      {
        householdId: demoHousehold.id,
        createdById: demoUser.id,
        serviceCategoryId: plumbingCategory?.id,
        title: 'Leaky faucet in master bathroom',
        description: 'The hot water faucet in the master bathroom has been dripping for about a week.',
        status: 'COMPLETED',
        priority: 'MEDIUM',
        preferredDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
      },
      {
        householdId: demoHousehold.id,
        createdById: demoUser.id,
        serviceCategoryId: hvacCategory?.id,
        title: 'Annual HVAC inspection',
        description: 'Need to schedule annual HVAC maintenance before summer.',
        status: 'ASSIGNED', // Changed from SCHEDULED which doesn't exist
        priority: 'LOW',
        preferredDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
      },
    ],
  });
  console.log('✅ Created sample service requests');

  // ============================================================================
  // FINANCIAL ENGINE - THE FLOAT
  // ============================================================================

  console.log('💰 Setting up Financial Engine...');

  // Create Company Wallet (singleton)
  const companyWallet = await prisma.companyWallet.upsert({
    where: { id: 'company-wallet-singleton' },
    update: {
      balance: 25000, // $25,000 operating balance
      outstandingFloat: 550, // Pool + Locksmith + Management Fee = $550
      monthlyCollections: 0,
      monthlyDisbursements: 450, // Pool + Locksmith already paid
    },
    create: {
      id: 'company-wallet-singleton',
      balance: 25000,
      outstandingFloat: 550,
      monthlyCollections: 0,
      monthlyDisbursements: 450,
    },
  });
  console.log(`✅ Created Company Wallet (Balance: $${companyWallet.balance})`);

  // Create Client Bank Account for Bob's Villa
  const clientBankAccount = await prisma.clientBankAccount.upsert({
    where: { id: 'demo-bank-account' },
    update: {},
    create: {
      id: 'demo-bank-account',
      householdId: demoHousehold.id,
      stripePaymentMethodId: 'pm_demo_bank_account',
      stripeBankAccountId: 'ba_demo_bank_account',
      bankName: 'Chase',
      accountType: 'checking',
      last4: '4242',
      routingLast4: '1234',
      isVerified: true,
      verifiedAt: new Date(),
      isDefault: true,
      isActive: true,
    },
  });
  console.log(`✅ Created Client Bank Account (${clientBankAccount.bankName} ****${clientBankAccount.last4})`);

  // Find pool service vendor for transactions
  const poolVendor = await prisma.vendor.findFirst({
    where: { householdId: demoHousehold.id, category: VendorCategory.POOL_SERVICE },
  });

  // Create demo transactions
  console.log('📊 Creating demo transactions...');
  const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const today = new Date();

  const demoTransactions = [
    // Pool Cleaning - Paid yesterday
    {
      id: 'tx-pool-cleaning',
      householdId: demoHousehold.id,
      vendorId: poolVendor?.id,
      managerId: managerSteve.id,
      description: 'Pool Cleaning',
      amount: 150,
      payoutMethod: TransactionPayoutMethod.COMPANY_CARD,
      status: TransactionStatus.PAID_TO_VENDOR,
      isReimbursable: true,
      paidAt: yesterday,
      notes: 'Monthly pool maintenance service',
    },
    // Emergency Locksmith - Paid today
    {
      id: 'tx-emergency-locksmith',
      householdId: demoHousehold.id,
      vendorId: null, // External vendor not in system
      managerId: managerSteve.id,
      description: 'Emergency Locksmith',
      amount: 300,
      payoutMethod: TransactionPayoutMethod.CASH,
      status: TransactionStatus.PAID_TO_VENDOR,
      isReimbursable: true,
      paidAt: today,
      notes: 'Client locked out - emergency service call',
    },
    // Management Fee - Accrued (pending)
    {
      id: 'tx-management-fee',
      householdId: demoHousehold.id,
      vendorId: null, // Haven internal
      managerId: managerSteve.id,
      description: 'Management Fee',
      amount: 100,
      payoutMethod: TransactionPayoutMethod.STRIPE,
      status: TransactionStatus.PENDING,
      isReimbursable: true,
      paidAt: null,
      notes: 'Monthly home management fee - December 2025',
    },
  ];

  for (const txData of demoTransactions) {
    await prisma.transaction.upsert({
      where: { id: txData.id },
      update: txData,
      create: txData,
    });
  }
  console.log(`✅ Created ${demoTransactions.length} demo transactions`);
  console.log('   - Pool Cleaning: $150 (Paid yesterday via Company Card)');
  console.log('   - Emergency Locksmith: $300 (Paid today via Cash)');
  console.log('   - Management Fee: $100 (Accrued - pending)');

  // ============================================================================
  // PAYMENT RAILS DEMO - Vendors with different payout methods
  // ============================================================================

  console.log('💳 Setting up Payment Rails demo...');

  // Create "Old School Landscaping" - has physical address for check mailing (no email)
  const oldSchoolLandscaping = await prisma.vendor.upsert({
    where: { id: 'vendor-old-school-landscaping' },
    update: {
      displayName: 'Old School Landscaping LLC',
      category: VendorCategory.LANDSCAPING,
      phone: '555-0120',
      email: null, // No email - they prefer physical checks
      websiteUrl: null,
      addressLine1: '123 Garden Way',
      addressLine2: 'Suite 5',
      city: 'Hartford',
      state: 'CT',
      postalCode: '06103',
      notes: 'Traditional landscaping company - prefers physical check payments',
    },
    create: {
      id: 'vendor-old-school-landscaping',
      householdId: demoHousehold.id,
      displayName: 'Old School Landscaping LLC',
      category: VendorCategory.LANDSCAPING,
      phone: '555-0120',
      email: null, // No email - they prefer physical checks
      websiteUrl: null,
      addressLine1: '123 Garden Way',
      addressLine2: 'Suite 5',
      city: 'Hartford',
      state: 'CT',
      postalCode: '06103',
      notes: 'Traditional landscaping company - prefers physical check payments',
    },
  });
  console.log(`✅ Created vendor: ${oldSchoolLandscaping.displayName} (Check-only)`);

  // Create "Tech Plumbers" - has Stripe Connect for instant payments
  const techPlumbers = await prisma.vendor.upsert({
    where: { id: 'vendor-tech-plumbers' },
    update: {
      displayName: 'Tech Plumbers Inc.',
      category: VendorCategory.OTHER, // No specific plumbing category
      phone: '555-0121',
      email: 'payments@techplumbers.example.com',
      websiteUrl: 'https://techplumbers.example.com',
      addressLine1: '456 Pipe Street',
      city: 'New Haven',
      state: 'CT',
      postalCode: '06510',
      notes: 'Modern plumbing company - accepts Stripe payments',
    },
    create: {
      id: 'vendor-tech-plumbers',
      householdId: demoHousehold.id,
      displayName: 'Tech Plumbers Inc.',
      category: VendorCategory.OTHER,
      phone: '555-0121',
      email: 'payments@techplumbers.example.com',
      websiteUrl: 'https://techplumbers.example.com',
      addressLine1: '456 Pipe Street',
      city: 'New Haven',
      state: 'CT',
      postalCode: '06510',
      notes: 'Modern plumbing company - accepts Stripe payments',
    },
  });
  console.log(`✅ Created vendor: ${techPlumbers.displayName} (Stripe Connect)`);

  // Create Stripe Connect payout account for Tech Plumbers
  await prisma.vendorPayoutAccount.upsert({
    where: { vendorId: techPlumbers.id },
    update: {
      stripeAccountId: 'acct_demo_techplumbers123',
      payoutMethod: 'STRIPE_CONNECT',
      stripeOnboardingComplete: true,
    },
    create: {
      vendorId: techPlumbers.id,
      stripeAccountId: 'acct_demo_techplumbers123',
      payoutMethod: 'STRIPE_CONNECT',
      stripeOnboardingComplete: true,
      notes: 'Demo Stripe Connect account for testing',
    },
  });
  console.log(`✅ Created Stripe Connect account for ${techPlumbers.displayName}`);

  // Create unpaid invoices (PENDING transactions) for Batch Pay demo
  const paymentRailsTransactions = [
    // Old School Landscaping - Fall cleanup
    {
      id: 'tx-landscaping-fall-cleanup',
      householdId: demoHousehold.id,
      vendorId: oldSchoolLandscaping.id,
      managerId: managerSteve.id,
      description: 'Fall Leaf Cleanup & Yard Work',
      amount: 450,
      payoutMethod: TransactionPayoutMethod.CHECKBOOK_IO,
      status: TransactionStatus.PENDING,
      isReimbursable: true,
      paidAt: null,
      notes: 'Full yard cleanup - rake leaves, trim bushes, prepare for winter',
    },
    // Old School Landscaping - Snow plow deposit
    {
      id: 'tx-landscaping-snow-deposit',
      householdId: demoHousehold.id,
      vendorId: oldSchoolLandscaping.id,
      managerId: managerSteve.id,
      description: 'Winter Snow Removal - Season Deposit',
      amount: 800,
      payoutMethod: TransactionPayoutMethod.CHECKBOOK_IO,
      status: TransactionStatus.PENDING,
      isReimbursable: true,
      paidAt: null,
      notes: 'Deposit for winter 2025-2026 snow removal contract',
    },
    // Tech Plumbers - Emergency repair
    {
      id: 'tx-plumber-emergency',
      householdId: demoHousehold.id,
      vendorId: techPlumbers.id,
      managerId: managerSteve.id,
      description: 'Emergency Water Heater Repair',
      amount: 375,
      payoutMethod: TransactionPayoutMethod.STRIPE,
      status: TransactionStatus.PENDING,
      isReimbursable: true,
      paidAt: null,
      notes: 'Emergency call - replaced thermostat and anode rod',
    },
    // Tech Plumbers - Inspection
    {
      id: 'tx-plumber-inspection',
      householdId: demoHousehold.id,
      vendorId: techPlumbers.id,
      managerId: managerSteve.id,
      description: 'Annual Plumbing Inspection',
      amount: 150,
      payoutMethod: TransactionPayoutMethod.STRIPE,
      status: TransactionStatus.PENDING,
      isReimbursable: true,
      paidAt: null,
      notes: 'Annual inspection of all plumbing systems',
    },
    // Chimney Masters - Check payment
    {
      id: 'tx-chimney-sweep',
      householdId: demoHousehold.id,
      vendorId: vendorMap.get(VendorCategory.CHIMNEY_SWEEP) || null,
      managerId: managerSteve.id,
      description: 'Annual Chimney Sweep & Inspection',
      amount: 275,
      payoutMethod: TransactionPayoutMethod.COMPANY_CARD,
      status: TransactionStatus.PENDING,
      isReimbursable: true,
      paidAt: null,
      notes: 'Annual chimney cleaning and safety inspection',
    },
  ];

  for (const txData of paymentRailsTransactions) {
    await prisma.transaction.upsert({
      where: { id: txData.id },
      update: txData,
      create: txData,
    });
  }
  console.log(`✅ Created ${paymentRailsTransactions.length} unpaid invoices for Batch Pay demo`);
  console.log('   - Old School Landscaping: $450 + $800 (Check mailing)');
  console.log('   - Tech Plumbers: $375 + $150 (Stripe Connect)');
  console.log('   - Chimney Masters: $275 (Company Card)');

  // ============================================================================
  // VENDOR PORTAL DEMO DATA
  // ============================================================================

  console.log('');
  console.log('🔧 Setting up Vendor Portal demo data...');

  // Create Ace Roofing user account
  const aceRoofingPassword = await bcrypt.hash('AceRoof123!', 12);
  const aceRoofingUser = await prisma.user.upsert({
    where: { email: 'vendor@aceroofing.example.com' },
    update: {},
    create: {
      email: 'vendor@aceroofing.example.com',
      passwordHash: aceRoofingPassword,
      firstName: 'Mike',
      lastName: 'Johnson',
      displayName: 'Mike Johnson',
      role: UserRole.HOMEOWNER, // Vendors use HOMEOWNER role but access vendor portal
      emailVerified: true,
      emailVerifiedAt: new Date(),
    },
  });
  console.log(`✅ Created vendor user: ${aceRoofingUser.email}`);

  // Create Malibu Mansion household (for demo work orders)
  const malibuMansion = await prisma.household.upsert({
    where: { id: 'malibu-mansion-id' },
    update: {
      assignedHandymanId: handymanCarlos.id, // Carlos handles CA properties
    },
    create: {
      id: 'malibu-mansion-id',
      name: 'Malibu Mansion',
      description: 'Beachfront luxury estate in Malibu',
      ownerId: homeownerBob.id, // Bob owns multiple properties
      managerId: managerSteve.id,
      assignedHandymanId: handymanCarlos.id, // Carlos handles CA properties
      stripeCustomerId: 'cus_malibu_mansion_demo',
      billingCycleDay: 1,
      homeProfile: {
        create: {
          propertyType: 'SINGLE_FAMILY',
          addressLine1: '27400 Pacific Coast Hwy',
          city: 'Malibu',
          state: 'CA',
          postalCode: '90265',
          country: 'US',
          squareFeet: 6500,
          yearBuilt: 2015,
          bedrooms: 5,
          bathrooms: 6,
          stories: 2,
          garageSpaces: 3,
          notes: 'Malibu Mansion coordinates: 34.0259, -118.7798',
        },
      },
    },
  });
  console.log(`✅ Created household: ${malibuMansion.name}`);

  // Ensure Bob's membership exists for Malibu Mansion
  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: malibuMansion.id,
        userId: homeownerBob.id,
      },
    },
    update: {
      role: 'OWNER',
      status: 'ACTIVE',
    },
    create: {
      householdId: malibuMansion.id,
      userId: homeownerBob.id,
      role: 'OWNER',
      status: 'ACTIVE',
      joinedAt: new Date(),
    },
  });

  // Create Beverly Hills Estate household
  const beverlyHillsEstate = await prisma.household.upsert({
    where: { id: 'beverly-hills-estate-id' },
    update: {
      assignedHandymanId: handymanCarlos.id, // Carlos handles CA properties
    },
    create: {
      id: 'beverly-hills-estate-id',
      name: 'Beverly Hills Estate',
      description: 'Classic Mediterranean estate in Beverly Hills',
      ownerId: homeownerBob.id,
      managerId: managerSteve.id,
      assignedHandymanId: handymanCarlos.id, // Carlos handles CA properties
      stripeCustomerId: 'cus_beverly_hills_demo',
      billingCycleDay: 1,
      homeProfile: {
        create: {
          propertyType: 'SINGLE_FAMILY',
          addressLine1: '1200 Sunset Blvd',
          city: 'Beverly Hills',
          state: 'CA',
          postalCode: '90210',
          country: 'US',
          squareFeet: 8200,
          yearBuilt: 1998,
          bedrooms: 6,
          bathrooms: 7,
          stories: 3,
          garageSpaces: 4,
          notes: 'Beverly Hills Estate coordinates: 34.0901, -118.4065',
        },
      },
    },
  });
  console.log(`✅ Created household: ${beverlyHillsEstate.name}`);

  // Ensure Bob's membership exists for Beverly Hills Estate
  await prisma.householdMember.upsert({
    where: {
      householdId_userId: {
        householdId: beverlyHillsEstate.id,
        userId: homeownerBob.id,
      },
    },
    update: {
      role: 'OWNER',
      status: 'ACTIVE',
    },
    create: {
      householdId: beverlyHillsEstate.id,
      userId: homeownerBob.id,
      role: 'OWNER',
      status: 'ACTIVE',
      joinedAt: new Date(),
    },
  });

  // Get roofing service category
  const roofingCategory = categories.find((c) => c.name === 'Roofing');

  // Create Ace Roofing vendor
  const aceRoofing = await prisma.vendor.upsert({
    where: { id: 'vendor-ace-roofing' },
    update: {
      userId: aceRoofingUser.id,
      serviceAreas: ['Malibu', 'Beverly Hills', 'Pacific Palisades', 'Santa Monica'],
    },
    create: {
      id: 'vendor-ace-roofing',
      householdId: malibuMansion.id,
      userId: aceRoofingUser.id,
      displayName: 'Ace Roofing Co.',
      category: VendorCategory.OTHER,
      phone: '310-555-ROOF',
      email: 'dispatch@aceroofing.example.com',
      websiteUrl: 'https://aceroofing.example.com',
      addressLine1: '15000 Sunset Blvd',
      city: 'Pacific Palisades',
      state: 'CA',
      postalCode: '90272',
      isVerified: true,
      serviceAreas: ['Malibu', 'Beverly Hills', 'Pacific Palisades', 'Santa Monica'],
      notes: 'Licensed roofing contractor - specializes in luxury residential properties',
    },
  });
  console.log(`✅ Created vendor: ${aceRoofing.displayName}`);

  // Create OPEN Work Order: "Fix Shingles" at Malibu Mansion
  const openWorkOrder = await prisma.workOrder.upsert({
    where: { id: 'wo-open-shingles' },
    update: {},
    create: {
      id: 'wo-open-shingles',
      householdId: malibuMansion.id,
      createdByUserId: managerSteve.id,
      title: 'Fix Shingles - Wind Damage',
      description: 'Several shingles were damaged during recent Santa Ana winds. Need to inspect and replace affected shingles on the south-facing roof section. Access via ladder on the west side of the property. Property gate code: 4521. Park in the circular driveway.',
      status: WorkOrderStatus.OPEN,
      estimatedCost: 850,
      scheduledStart: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
      scheduledEnd: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000 + 4 * 60 * 60 * 1000), // 4 hours later
      serviceArea: 'Malibu',
    },
  });
  console.log(`✅ Created OPEN work order: ${openWorkOrder.title}`);

  // Create COMPLETED Work Order awaiting Manager verification
  const completedWorkOrder = await prisma.workOrder.upsert({
    where: { id: 'wo-completed-gutter-repair' },
    update: {},
    create: {
      id: 'wo-completed-gutter-repair',
      householdId: beverlyHillsEstate.id,
      createdByUserId: managerSteve.id,
      vendorId: aceRoofing.id,
      title: 'Gutter Repair & Cleaning',
      description: 'Clean all gutters and repair loose section on north side of house. Replace damaged gutter guard on garage section. Found additional damage on garage gutter guard - replaced entire section. All gutters cleaned and flowing properly. Recommend full inspection in spring.',
      status: WorkOrderStatus.COMPLETED,
      estimatedCost: 425,
      actualCost: 475, // Slightly over estimate due to additional repairs
      scheduledStart: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
      scheduledEnd: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000 + 3 * 60 * 60 * 1000),
      completedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000 + 2.5 * 60 * 60 * 1000),
      checkInAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000 + 15 * 60 * 1000), // Checked in 15 min after start
      checkInLatitude: 34.0901,
      checkInLongitude: -118.4065,
      checkOutAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000 + 2.5 * 60 * 60 * 1000), // 2.5 hours later
      serviceArea: 'Beverly Hills',
      proofImages: [
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800', // Gutter after cleaning
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800', // House exterior
      ],
    },
  });
  console.log(`✅ Created COMPLETED work order awaiting verification: ${completedWorkOrder.title}`);

  // Create an IN_PROGRESS work order (vendor currently on-site)
  const inProgressWorkOrder = await prisma.workOrder.upsert({
    where: { id: 'wo-in-progress-pool' },
    update: {},
    create: {
      id: 'wo-in-progress-pool',
      householdId: beverlyHillsEstate.id,
      createdByUserId: managerSteve.id,
      vendorId: poolVendor?.id,
      title: 'Pool Pump Repair',
      description: 'Pool pump making unusual noise. May need bearing replacement or motor inspection. Pool equipment located behind the pool house.',
      status: WorkOrderStatus.IN_PROGRESS,
      estimatedCost: 325,
      scheduledStart: new Date(),
      scheduledEnd: new Date(Date.now() + 3 * 60 * 60 * 1000), // 3 hours from now
      checkInAt: new Date(Date.now() - 45 * 60 * 1000), // Checked in 45 min ago
      checkInLatitude: 34.0901,
      checkInLongitude: -118.4065,
      serviceArea: 'Beverly Hills',
    },
  });
  console.log(`✅ Created IN_PROGRESS work order: ${inProgressWorkOrder.title}`);

  // Create an ASSIGNED work order (vendor has accepted, not started)
  const assignedWorkOrder = await prisma.workOrder.upsert({
    where: { id: 'wo-assigned-hvac' },
    update: {},
    create: {
      id: 'wo-assigned-hvac',
      householdId: malibuMansion.id,
      createdByUserId: managerSteve.id,
      vendorId: aceRoofing.id, // Ace Roofing also does some general maintenance
      title: 'HVAC Annual Inspection',
      description: 'Annual maintenance and filter replacement for central HVAC system. Check all vents, inspect ductwork, and test thermostat. HVAC system is Carrier brand, installed 2019. Filters are 20x25x4.',
      status: WorkOrderStatus.ASSIGNED,
      estimatedCost: 450,
      scheduledStart: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // Tomorrow
      scheduledEnd: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000), // 2 hours
      serviceArea: 'Malibu',
    },
  });
  console.log(`✅ Created ASSIGNED work order: ${assignedWorkOrder.title}`);

  console.log('');
  console.log('🎉 Database seed completed successfully!');
  console.log('');
  console.log('═══════════════════════════════════════════════════');
  console.log('  USER CREDENTIALS');
  console.log('═══════════════════════════════════════════════════');
  console.log('');
  console.log('  👑 Admin (Platform Owner):');
  console.log('    Email:    admin@haven.app');
  console.log('    Password: Admin123!');
  console.log('    Role:     Can access ALL records');
  console.log('');
  console.log('  👔 Manager Steve (Haven Staff):');
  console.log('    Email:    steve@haven.app');
  console.log('    Password: Manager123!');
  console.log('    Role:     Can access households assigned to them');
  console.log('');
  console.log('  🏠 Homeowner Bob (Client - 3 properties):');
  console.log('    Email:    bob@example.com');
  console.log('    Password: Bob123!');
  console.log('    Properties: Bob\'s Villa (CT), Malibu Mansion (CA), Beverly Hills Estate (CA)');
  console.log('');
  console.log('  🏠 Homeowner Alice (Client - 1 property, 4 family members):');
  console.log('    Email:    alice@example.com');
  console.log('    Password: Alice123!');
  console.log('    Properties: The Johnson Family Home (IL)');
  console.log('    Family: Alice, Michael (spouse), Emma (daughter), Jack (son)');
  console.log('');
  console.log('  🔧 Vendor - Ace Roofing:');
  console.log('    Email:    vendor@aceroofing.example.com');
  console.log('    Password: AceRoof123!');
  console.log('    Portal:   /vendor (Vendor Portal)');
  console.log('');
  console.log('  🛠️  Handyman Carlos Reyes (Westchester County, NY):');
  console.log('    Email:    carlos@haven.app');
  console.log('    Password: Handy123!');
  console.log('    Assigned: The Johnson Family Home (Scarsdale)');
  console.log('    Portal:   /handyman');
  console.log('');
  console.log('  🛠️  Handyman Mike Castellano (Fairfield County, CT):');
  console.log('    Email:    dave@haven.app');
  console.log('    Password: Handy123!');
  console.log('    Assigned: Bob\'s Villa (Greenwich)');
  console.log('    Portal:   /handyman');
  console.log('');
  console.log('  🛠️  Handyman Maria Santos (Floater):');
  console.log('    Email:    maria@haven.app');
  console.log('    Password: Handy123!');
  console.log('    Assigned: Available for any property');
  console.log('    Portal:   /handyman');
  console.log('');
  console.log('═══════════════════════════════════════════════════');
  console.log('  HOUSEHOLD ASSIGNMENT');
  console.log('═══════════════════════════════════════════════════');
  console.log('');
  console.log("  Bob's Villa (Greenwich, CT):");
  console.log('    Owner:    Bob Smith (bob@example.com)');
  console.log('    Manager:  Steve Manager (steve@haven.app)');
  console.log('    Handyman: Mike Castellano (dave@haven.app)');
  console.log('  - 3 bed, 2.5 bath single family home on Round Hill Road');
  console.log('  - Features: pool, septic, chimney, lawn, snow removal');
  console.log(`  - ${billAccountsData.length} bill accounts configured`);
  console.log(`  - ${maintenanceTasks.length} maintenance tasks for 12 months`);
  console.log('');
  console.log('  Malibu Mansion (CA - Multi-property demo):');
  console.log('    Owner:    Bob Smith (bob@example.com)');
  console.log('    Manager:  Steve Manager (steve@haven.app)');
  console.log('    Handyman: Carlos Reyes (carlos@haven.app)');
  console.log('  - 5 bed, 6 bath beachfront estate');
  console.log('  - Work Orders: 1 OPEN (Fix Shingles), 1 ASSIGNED (HVAC)');
  console.log('');
  console.log('  Beverly Hills Estate (CA - Multi-property demo):');
  console.log('    Owner:    Bob Smith (bob@example.com)');
  console.log('    Manager:  Steve Manager (steve@haven.app)');
  console.log('    Handyman: Carlos Reyes (carlos@haven.app)');
  console.log('  - 6 bed, 7 bath Mediterranean estate');
  console.log('  - Work Orders: 1 COMPLETED (awaiting verification), 1 IN_PROGRESS');
  console.log('');
  console.log('  The Johnson Family Home (Scarsdale, NY):');
  console.log('    Owner:    Alice Johnson (alice@example.com)');
  console.log('    Manager:  Steve Manager (steve@haven.app)');
  console.log('    Handyman: Carlos Reyes (carlos@haven.app)');
  console.log('  - 4 bed, 2.5 bath suburban family home on Fox Meadow Road');
  console.log('  - Family Members: Alice, Michael (spouse), Emma (14), Jack (10)');
  console.log('  - Features: hot tub, gas fireplace, smart home, generator');
  console.log('  - Work Orders: 1 OPEN (Hot Tub Service)');
  console.log('');
  console.log('═══════════════════════════════════════════════════');
  console.log('  VENDOR PORTAL DEMO');
  console.log('═══════════════════════════════════════════════════');
  console.log('');
  console.log('  Ace Roofing Co. (vendor@aceroofing.example.com):');
  console.log('    Service Areas: Malibu, Beverly Hills, Pacific Palisades, Santa Monica');
  console.log('    Job Board: 1 OPEN job available to claim');
  console.log('    Schedule: 1 ASSIGNED job (tomorrow), 1 IN_PROGRESS job');
  console.log('');
  console.log('  Manager Verification Queue (/manager/verification):');
  console.log('    1 COMPLETED job awaiting verification (Gutter Repair)');
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
