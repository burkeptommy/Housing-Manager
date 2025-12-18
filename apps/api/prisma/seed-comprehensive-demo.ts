/**
 * Comprehensive Demo Data Seed
 *
 * Run after main seed to add detailed demo data:
 * - Home profile with brands, models, serial numbers
 * - Social posts for Community page
 * - Demo projects in different stages
 * - Concierge requests
 * - Calendar events
 * - Invoices
 * - Dashboard data with proper dates
 */

import {
  PrismaClient,
  TransactionStatus,
  ServiceRequestStatus,
  ServiceRequestPriority,
  WorkOrderStatus,
  ProjectIdeaStatus,
  ProjectCategory,
  PostVisibility,
  HouseholdInvoiceStatus,
  FamilyEventCategory,
} from '@prisma/client';

const prisma = new PrismaClient();

// Helper to get dates relative to today
const daysFromNow = (days: number) => {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date;
};

const daysAgo = (days: number) => daysFromNow(-days);

async function main() {
  console.log('🌱 Starting comprehensive demo data seed...\n');

  // Get Bob's household
  const bobHousehold = await prisma.household.findFirst({
    where: { name: "Bob's Villa" },
    include: { homeProfile: true, owner: true },
  });

  if (!bobHousehold) {
    console.error('❌ Bob\'s Villa not found. Run main seed first.');
    return;
  }

  const bob = bobHousehold.owner;
  console.log(`Found Bob's Villa (${bobHousehold.id})`);

  // ============================================================================
  // 1. COMPREHENSIVE HOME PROFILE DATA
  // ============================================================================
  console.log('\n📋 Adding comprehensive home profile data...');

  const comprehensiveHomeData = {
    // Detailed systems with brands, models, service info
    systems: {
      heating: {
        id: 'heating-1',
        type: 'Gas Furnace',
        brand: 'Carrier',
        model: '59SC5A080E17--14',
        serialNumber: 'WCA9344729',
        installDate: '2019-10-15',
        warrantyExpires: '2029-10-15',
        vendor: 'Johnson HVAC Services',
        vendorPhone: '(203) 555-0147',
        lastServiceDate: '2024-09-15',
        nextMaintenanceDate: '2025-03-15',
        location: 'Basement utility room',
        fuelType: 'GAS',
        notes: '95% efficiency model. Filter size 20x25x4.',
      },
      hvac: {
        id: 'hvac-1',
        type: 'Central Air Conditioning',
        brand: 'Carrier',
        model: '24ACC636A003',
        serialNumber: 'WCA9344730',
        installDate: '2019-10-15',
        warrantyExpires: '2029-10-15',
        vendor: 'Johnson HVAC Services',
        vendorPhone: '(203) 555-0147',
        lastServiceDate: '2024-06-01',
        nextMaintenanceDate: '2025-05-01',
        location: 'Side of house',
        filterSize: '20x25x4',
        filterLastChanged: '2024-11-15',
        filterNextChange: '2025-02-15',
        notes: '3-ton unit. SEER 16.',
      },
      waterHeater: {
        id: 'wh-1',
        type: 'Tank Gas',
        brand: 'Rheem',
        model: 'XG50T09HE40U0',
        serialNumber: 'RH2219847362',
        installDate: '2021-03-20',
        warrantyExpires: '2033-03-20',
        vendor: 'Pleasantville Plumbing',
        vendorPhone: '(203) 555-0189',
        lastServiceDate: '2024-03-20',
        nextMaintenanceDate: '2025-03-20',
        location: 'Basement',
        notes: '50-gallon capacity. Set to 120°F.',
      },
      electrical: {
        id: 'elec-1',
        type: '200 Amp Panel',
        brand: 'Square D',
        model: 'HOM3040L200PGCVP',
        serialNumber: 'SD2847291034',
        installDate: '2005-06-01',
        vendor: 'Bright Electric Co',
        vendorPhone: '(203) 555-0156',
        lastServiceDate: '2023-08-15',
        nextMaintenanceDate: '2025-08-15',
        location: 'Garage wall',
        notes: 'Main panel. Whole house surge protector installed 2022.',
      },
      roof: {
        id: 'roof-1',
        type: 'Asphalt Shingles',
        brand: 'GAF',
        model: 'Timberline HDZ',
        installDate: '2018-07-01',
        warrantyExpires: '2043-07-01',
        vendor: 'CT Roofing Pros',
        vendorPhone: '(203) 555-0134',
        lastServiceDate: '2024-04-15',
        nextMaintenanceDate: '2025-04-15',
        notes: 'Charcoal color. 25-year warranty. Last inspection: no issues.',
        guttersCleaned: '2024-11-01',
        guttersNextCleaning: '2025-04-01',
      },
      septic: {
        id: 'septic-1',
        type: 'Conventional Septic',
        brand: 'Infiltrator',
        installDate: '2005-06-01',
        vendor: 'Valley Septic Services',
        vendorPhone: '(203) 555-0178',
        lastServiceDate: '2023-06-15',
        nextMaintenanceDate: '2025-06-15',
        tankSize: 1500,
        lastPumped: '2023-06-15',
        nextPumpDue: '2026-06-15',
        location: 'Backyard near tree line',
        notes: '1500-gallon tank. Pump every 3 years.',
      },
      pool: {
        id: 'pool-1',
        type: 'Inground Gunite',
        brand: 'Hayward',
        model: 'Various Equipment',
        installDate: '2015-05-01',
        vendor: 'Crystal Clear Pools',
        vendorPhone: '(203) 555-0145',
        lastServiceDate: '2024-11-15',
        nextMaintenanceDate: '2025-04-01',
        notes: '20x40 pool. Saltwater system. Heated. Weekly service included.',
      },
      garage: {
        id: 'garage-1',
        type: 'Automatic Garage Door',
        brand: 'LiftMaster',
        model: '8500W',
        serialNumber: 'LM8839421',
        installDate: '2020-08-10',
        warrantyExpires: '2025-08-10',
        vendor: 'Overhead Door Co',
        vendorPhone: '(203) 555-0167',
        lastServiceDate: '2024-02-15',
        nextMaintenanceDate: '2025-02-15',
        location: 'Attached 2-car garage',
        notes: 'Wall-mounted. Wi-Fi enabled. Battery backup.',
      },
      fireplace: {
        id: 'fp-1',
        type: 'Wood Burning',
        brand: 'Majestic',
        model: 'SB100',
        installDate: '2005-06-01',
        vendor: 'Chimney Masters',
        vendorPhone: '(203) 555-0112',
        lastServiceDate: '2024-09-01',
        nextMaintenanceDate: '2025-09-01',
        location: 'Living room',
        notes: 'Annual inspection and cleaning required.',
      },
      security: {
        id: 'sec-1',
        type: 'Monitored Security System',
        brand: 'ADT',
        model: 'Pulse System',
        installDate: '2021-01-15',
        vendor: 'ADT Security Services',
        vendorPhone: '(800) 555-0199',
        notes: 'Monthly monitoring. Mobile app access. 2 keypads, 8 door/window sensors.',
        cameras: 4,
        doorSensors: 6,
        motionSensors: 2,
      },
      lawnCare: {
        id: 'lawn-1',
        vendor: 'Green Thumb Landscaping',
        vendorPhone: '(203) 555-0123',
        serviceFrequency: 'Weekly (Apr-Nov)',
        lastServiceDate: '2024-11-15',
        nextMaintenanceDate: '2025-04-01',
        services: ['Mowing', 'Edging', 'Blowing', 'Spring/Fall cleanup'],
        notes: 'Service every Thursday. $65/visit.',
      },
      snowRemoval: {
        id: 'snow-1',
        vendor: 'CT Snow Pros',
        vendorPhone: '(203) 555-0190',
        serviceFrequency: 'Per event (2"+ trigger)',
        triggerDepth: '2 inches',
        includesSalting: true,
        includesSidewalk: true,
        includesDriveway: true,
        notes: 'Seasonal contract $450. Priority service.',
      },
      houseCleaning: {
        id: 'clean-1',
        vendor: 'Sparkle Clean Services',
        vendorPhone: '(203) 555-0134',
        serviceFrequency: 'Bi-weekly',
        serviceDay: 'Tuesdays',
        lastServiceDate: '2024-12-10',
        nextMaintenanceDate: '2024-12-24',
        services: ['Deep clean', 'Laundry', 'Kitchen', 'Bathrooms'],
        notes: '$180/visit. Team of 2.',
      },
      pestControl: {
        id: 'pest-1',
        vendor: 'Orkin',
        vendorPhone: '(800) 555-0167',
        serviceFrequency: 'Quarterly',
        lastServiceDate: '2024-10-15',
        nextMaintenanceDate: '2025-01-15',
        services: ['Interior/exterior spray', 'Rodent monitoring'],
        notes: 'Annual contract. $99/quarter.',
      },
    },
    // Appliances
    appliances: {
      refrigerator: {
        id: 'app-fridge',
        name: 'Refrigerator',
        brand: 'Samsung',
        model: 'RF28R7551SR',
        serialNumber: 'SAM892734921',
        installDate: '2022-01-15',
        warrantyExpires: '2025-01-15',
        location: 'Kitchen',
        notes: 'French door, 28 cu ft. Ice maker connected.',
      },
      dishwasher: {
        id: 'app-dw',
        name: 'Dishwasher',
        brand: 'Bosch',
        model: 'SHPM88Z75N',
        serialNumber: 'BSH294817362',
        installDate: '2021-06-01',
        warrantyExpires: '2024-06-01',
        location: 'Kitchen',
        notes: '800 series. Very quiet.',
      },
      oven: {
        id: 'app-oven',
        name: 'Range/Oven',
        brand: 'KitchenAid',
        model: 'KFGC500JSS',
        serialNumber: 'KA847291034',
        installDate: '2022-01-15',
        warrantyExpires: '2025-01-15',
        location: 'Kitchen',
        notes: 'Gas 6-burner. Convection oven.',
      },
      microwave: {
        id: 'app-mw',
        name: 'Microwave',
        brand: 'GE Profile',
        model: 'PVM9005SJSS',
        serialNumber: 'GE384729183',
        installDate: '2022-01-15',
        warrantyExpires: '2024-01-15',
        location: 'Kitchen - over range',
        notes: '2.1 cu ft. Sensor cooking.',
      },
      washer: {
        id: 'app-wash',
        name: 'Washer',
        brand: 'LG',
        model: 'WM4500HBA',
        serialNumber: 'LG927483921',
        installDate: '2023-03-01',
        warrantyExpires: '2026-03-01',
        location: 'Laundry room',
        notes: 'Front load. 5.0 cu ft. TurboWash.',
      },
      dryer: {
        id: 'app-dry',
        name: 'Dryer',
        brand: 'LG',
        model: 'DLEX4500B',
        serialNumber: 'LG927483922',
        installDate: '2023-03-01',
        warrantyExpires: '2026-03-01',
        location: 'Laundry room',
        notes: 'Electric. 7.4 cu ft. Steam cycle.',
      },
      garbageDisposal: {
        id: 'app-disp',
        name: 'Garbage Disposal',
        brand: 'InSinkErator',
        model: 'Evolution Excel',
        serialNumber: 'ISE837291',
        installDate: '2021-06-01',
        warrantyExpires: '2028-06-01',
        location: 'Kitchen sink',
        notes: '1 HP motor. Very quiet.',
      },
    },
    // Financial Accounts
    financialAccounts: {
      mortgage: {
        id: 'fin-mort',
        type: 'MORTGAGE',
        name: 'Home Mortgage',
        lender: 'Wells Fargo',
        accountNumber: '****4829',
        paymentAmount: 2847,
        interestRate: 3.25,
        dueDay: 1,
        autopay: true,
        balance: 342000,
        originalAmount: 450000,
        startDate: '2019-08-01',
        endDate: '2049-08-01',
        notes: '30-year fixed. Escrow included.',
      },
      carLoan1: {
        id: 'fin-car1',
        type: 'CAR_LOAN',
        name: 'Toyota Highlander Loan',
        lender: 'Toyota Financial',
        accountNumber: '****7234',
        paymentAmount: 589,
        interestRate: 4.9,
        dueDay: 15,
        autopay: true,
        balance: 18500,
        originalAmount: 38000,
        startDate: '2022-03-01',
        endDate: '2027-03-01',
        notes: '60-month term.',
      },
      creditCard: {
        id: 'fin-cc',
        type: 'CREDIT_CARD',
        name: 'Chase Sapphire Reserve',
        lender: 'Chase',
        accountNumber: '****9182',
        paymentAmount: 0,
        dueDay: 25,
        autopay: true,
        balance: 2340,
        notes: 'Paid in full monthly. Travel rewards.',
      },
    },
    // Utilities
    utilities: {
      electric: {
        id: 'util-elec',
        type: 'ELECTRIC',
        provider: 'Eversource Energy',
        accountNumber: '52-8472-9183',
        averageMonthlyBill: 185,
        dueDay: 20,
        autopay: true,
        customerServicePhone: '(800) 286-2000',
        portalUrl: 'https://www.eversource.com',
        notes: 'Time-of-use rate. Budget billing available.',
      },
      gas: {
        id: 'util-gas',
        type: 'GAS',
        provider: 'Southern CT Gas',
        accountNumber: 'SCG-847291-02',
        averageMonthlyBill: 120,
        dueDay: 15,
        autopay: true,
        customerServicePhone: '(800) 659-8299',
        portalUrl: 'https://www.soconngas.com',
        notes: 'Higher in winter for heating.',
      },
      water: {
        id: 'util-water',
        type: 'WATER_SEWER',
        provider: 'Pleasantville Water Co',
        accountNumber: 'PW-2847-001',
        averageMonthlyBill: 65,
        dueDay: 10,
        autopay: false,
        customerServicePhone: '(203) 555-0100',
        notes: 'Quarterly billing. No sewer - septic.',
      },
      internet: {
        id: 'util-inet',
        type: 'INTERNET',
        provider: 'Frontier FiOS',
        accountNumber: '203-555-0147-001',
        averageMonthlyBill: 89,
        dueDay: 5,
        autopay: true,
        customerServicePhone: '(800) 921-8101',
        portalUrl: 'https://www.frontier.com',
        notes: '1 Gbps fiber. Includes router.',
      },
      trash: {
        id: 'util-trash',
        type: 'TRASH',
        provider: 'Waste Management',
        accountNumber: 'WM-CT-847291',
        averageMonthlyBill: 45,
        dueDay: 1,
        autopay: true,
        customerServicePhone: '(866) 909-4458',
        notes: 'Pickup Thursdays. Recycling included.',
      },
    },
    // Vehicles
    vehicles: {
      car1: {
        id: 'veh-1',
        type: 'SUV',
        year: 2022,
        make: 'Toyota',
        model: 'Highlander XLE',
        color: 'Celestial Silver Metallic',
        vin: '5TDKZRFH4NS012345',
        licensePlate: 'CT 847-HJK',
        registrationExpires: '2025-03-15',
        insuranceCompany: 'State Farm',
        insurancePolicyNumber: 'SF-CT-9284710',
        insuranceExpires: '2025-06-01',
        insuranceAgent: 'Mike Thompson',
        insuranceAgentPhone: '(203) 555-0145',
        lastOilChange: '2024-10-15',
        nextOilChangeMiles: 52000,
        currentMileage: 47500,
        preferredMechanic: 'Toyota of Pleasantville',
        mechanicPhone: '(203) 555-0180',
        notes: 'AWD. Platinum coverage until 75k.',
      },
      car2: {
        id: 'veh-2',
        type: 'CAR',
        year: 2020,
        make: 'Tesla',
        model: 'Model 3 Long Range',
        color: 'Pearl White',
        vin: '5YJ3E1EA8LF012345',
        licensePlate: 'CT 293-EV',
        registrationExpires: '2025-07-01',
        insuranceCompany: 'State Farm',
        insurancePolicyNumber: 'SF-CT-9284711',
        insuranceExpires: '2025-06-01',
        insuranceAgent: 'Mike Thompson',
        insuranceAgentPhone: '(203) 555-0145',
        currentMileage: 32000,
        preferredMechanic: 'Tesla Service Center',
        mechanicPhone: '(203) 555-0199',
        notes: 'Home charger installed. Range ~350mi.',
      },
    },
    // Preferences
    preferences: {
      painPoints: ['SCHEDULING', 'VENDORS'],
      communicationChannels: ['EMAIL', 'TEXT'],
    },
    // Recent Services
    recentServices: [
      { service: 'HVAC Fall Tune-Up', date: '2024-09-15', vendor: 'Johnson HVAC Services', cost: 150 },
      { service: 'Gutter Cleaning', date: '2024-11-01', vendor: 'CT Roofing Pros', cost: 200 },
      { service: 'Pool Closing', date: '2024-10-15', vendor: 'Crystal Clear Pools', cost: 350 },
      { service: 'Chimney Sweep', date: '2024-09-01', vendor: 'Chimney Masters', cost: 250 },
    ],
    // Upcoming Maintenance
    upcomingMaintenance: [
      { service: 'House Cleaning', date: daysFromNow(3).toISOString().split('T')[0], vendor: 'Sparkle Clean Services', time: '9:00 AM' },
      { service: 'Pest Control', date: daysFromNow(21).toISOString().split('T')[0], vendor: 'Orkin' },
      { service: 'HVAC Filter Change', date: daysFromNow(45).toISOString().split('T')[0], vendor: 'Self or Handyman' },
      { service: 'Snow Removal Contract Start', date: '2024-12-01', vendor: 'CT Snow Pros' },
    ],
  };

  // Update Bob's home profile with comprehensive data
  if (bobHousehold.homeProfile) {
    await prisma.homeProfile.update({
      where: { id: bobHousehold.homeProfile.id },
      data: {
        notes: JSON.stringify(comprehensiveHomeData),
      },
    });
    console.log('✅ Updated home profile with comprehensive data');
  }

  // ============================================================================
  // 2. SERVICE REQUESTS (5+)
  // ============================================================================
  console.log('\n📝 Adding service requests...');

  const serviceRequests = [
    {
      title: 'Kitchen faucet dripping',
      description: 'The kitchen sink faucet has been dripping for about a week. Getting worse.',
      priority: ServiceRequestPriority.MEDIUM,
      status: ServiceRequestStatus.SUBMITTED,
      createdAt: daysAgo(2),
    },
    {
      title: 'Garage door making grinding noise',
      description: 'When opening and closing the garage door, there\'s a loud grinding noise. Started yesterday.',
      priority: ServiceRequestPriority.LOW,
      status: ServiceRequestStatus.ASSIGNED,
      createdAt: daysAgo(5),
    },
    {
      title: 'Replace smoke detector batteries',
      description: 'Need all smoke detectors checked and batteries replaced. One is chirping.',
      priority: ServiceRequestPriority.MEDIUM,
      status: ServiceRequestStatus.IN_PROGRESS,
      createdAt: daysAgo(3),
    },
    {
      title: 'Front door weatherstripping',
      description: 'Cold air coming in around the front door. Needs new weatherstripping.',
      priority: ServiceRequestPriority.LOW,
      status: ServiceRequestStatus.COMPLETED,
      completedDate: daysAgo(10),
      createdAt: daysAgo(14),
    },
    {
      title: 'Bathroom exhaust fan not working',
      description: 'Master bathroom exhaust fan stopped working. No power to it.',
      priority: ServiceRequestPriority.MEDIUM,
      status: ServiceRequestStatus.SUBMITTED,
      createdAt: daysAgo(1),
    },
    {
      title: 'Tree branch hanging over driveway',
      description: 'Large branch from oak tree is hanging low over the driveway. Concerned it might fall.',
      priority: ServiceRequestPriority.HIGH,
      status: ServiceRequestStatus.ASSIGNED,
      createdAt: daysAgo(4),
    },
  ];

  for (const request of serviceRequests) {
    await prisma.serviceRequest.create({
      data: {
        ...request,
        household: { connect: { id: bobHousehold.id } },
        createdBy: { connect: { id: bob.id } },
      },
    });
  }
  console.log(`✅ Created ${serviceRequests.length} service requests`);

  // ============================================================================
  // 3. DEMO PROJECTS (4 in different stages)
  // ============================================================================
  console.log('\n🏗️ Adding demo projects...');

  // First, get or create a manager
  const manager = await prisma.user.findFirst({
    where: { email: 'steve@haven.app' },
  });

  if (manager) {
    // Create project ideas with simpler structure
    await prisma.projectIdea.create({
      data: {
        household: { connect: { id: bobHousehold.id } },
        createdBy: { connect: { id: bob.id } },
        title: 'Kitchen Backsplash Installation',
        description: 'Install new subway tile backsplash in the kitchen behind the stove and counters.',
        status: ProjectIdeaStatus.PLANNING,
        category: ProjectCategory.KITCHEN_REMODEL,
        estimatedCostMin: 2200,
        estimatedCostMax: 2800,
        vibeNotes: 'White subway tile with gray grout for classic look',
        style: 'traditional',
      },
    });

    await prisma.projectIdea.create({
      data: {
        household: { connect: { id: bobHousehold.id } },
        createdBy: { connect: { id: bob.id } },
        title: 'Deck Refinishing',
        description: 'Sand and restain the composite deck. Clean and seal all surfaces.',
        status: ProjectIdeaStatus.PLANNING,
        category: ProjectCategory.DECK_PATIO,
        estimatedCostMin: 1500,
        estimatedCostMax: 2100,
        vibeNotes: 'UV protectant to preserve composite deck',
        urgency: 'this_year',
      },
    });

    await prisma.projectIdea.create({
      data: {
        household: { connect: { id: bobHousehold.id } },
        createdBy: { connect: { id: bob.id } },
        title: 'Bathroom Vent Fan Replacement',
        description: 'Replace the master bathroom exhaust fan with a quieter, more efficient model. Panasonic WhisperCeiling recommended.',
        status: ProjectIdeaStatus.ACTIVE,
        category: ProjectCategory.BATHROOM_REMODEL,
        estimatedCostMin: 350,
        estimatedCostMax: 500,
        urgency: 'soon',
      },
    });

    await prisma.projectIdea.create({
      data: {
        household: { connect: { id: bobHousehold.id } },
        createdBy: { connect: { id: bob.id } },
        title: 'Landscaping - Front Yard Refresh',
        description: 'Remove overgrown shrubs, plant new foundation plants, add fresh mulch. Completed by Green Thumb for $2,950.',
        status: ProjectIdeaStatus.COMPLETED,
        category: ProjectCategory.LANDSCAPING,
        estimatedCostMin: 2800,
        estimatedCostMax: 3500,
        socialProofNote: '3 neighbors completed similar landscaping projects',
      },
    });

    console.log('✅ Created 4 demo projects');
  }

  // ============================================================================
  // 4. SOCIAL POSTS FOR COMMUNITY PAGE (10+ posts)
  // ============================================================================
  console.log('\n📱 Adding social posts...');

  // Get Alice for posts
  const alice = await prisma.user.findFirst({
    where: { email: 'alice@example.com' },
  });

  // Clear existing posts first
  await prisma.projectPost.deleteMany({
    where: { householdId: bobHousehold.id },
  });

  if (bob && alice) {
    // Bob's project posts
    const bobPosts = [
      {
        title: 'Front Yard Landscaping Complete!',
        description: 'Finally finished the front yard refresh. New hydrangeas, boxwoods, and fresh mulch make such a difference! The landscaper was fantastic.',
        visibility: PostVisibility.NEIGHBORS_ONLY,
        beforeImages: ['https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800'],
        afterImages: ['https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800'],
        actualCost: 2950,
        durationDays: 3,
        isVerified: true,
        likesCount: 12,
        commentsCount: 3,
        savesCount: 4,
        completedAt: daysAgo(20),
      },
      {
        title: 'New Bathroom Exhaust Fan',
        description: 'Replaced the old noisy fan with a Panasonic WhisperCeiling. So much quieter! Highly recommend for anyone with an older fan.',
        visibility: PostVisibility.PUBLIC,
        afterImages: ['https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=800'],
        actualCost: 425,
        durationDays: 1,
        isVerified: false,
        likesCount: 5,
        commentsCount: 1,
        savesCount: 2,
        completedAt: daysAgo(5),
      },
      {
        title: 'Deck Power Wash & Seal',
        description: 'Gave the deck a thorough power wash and applied a fresh coat of sealant. Looks brand new again!',
        visibility: PostVisibility.PUBLIC,
        beforeImages: ['https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=800'],
        afterImages: ['https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800'],
        actualCost: 350,
        durationDays: 2,
        isVerified: true,
        likesCount: 18,
        commentsCount: 4,
        savesCount: 7,
        completedAt: daysAgo(45),
      },
      {
        title: 'Smart Thermostat Installation',
        description: 'Upgraded to an Ecobee smart thermostat. Already seeing energy savings and love the remote control!',
        visibility: PostVisibility.FRIENDS_ONLY,
        afterImages: ['https://images.unsplash.com/photo-1558002038-1055e2dae2d4?w=800'],
        actualCost: 280,
        durationDays: 1,
        isVerified: true,
        likesCount: 8,
        commentsCount: 2,
        savesCount: 3,
        completedAt: daysAgo(60),
      },
      {
        title: 'Garage Organization System',
        description: 'Installed wall-mounted storage and ceiling racks. Finally can fit both cars in the garage!',
        visibility: PostVisibility.NEIGHBORS_ONLY,
        beforeImages: ['https://images.unsplash.com/photo-1558618047-f4b511c253f4?w=800'],
        afterImages: ['https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800'],
        actualCost: 1200,
        durationDays: 2,
        isVerified: false,
        likesCount: 22,
        commentsCount: 6,
        savesCount: 11,
        completedAt: daysAgo(30),
      },
    ];

    for (const post of bobPosts) {
      await prisma.projectPost.create({
        data: {
          author: { connect: { id: bob.id } },
          household: { connect: { id: bobHousehold.id } },
          ...post,
        },
      });
    }

    // Add posts for Alice
    const aliceHousehold = await prisma.household.findFirst({
      where: { ownerId: alice.id },
    });

    if (aliceHousehold) {
      // Clear Alice's posts too
      await prisma.projectPost.deleteMany({
        where: { householdId: aliceHousehold.id },
      });

      const alicePosts = [
        {
          title: 'Kitchen Cabinet Refresh',
          description: 'Painted our oak cabinets white and added new brass hardware. Total transformation for under $1500!',
          visibility: PostVisibility.PUBLIC,
          beforeImages: ['https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800'],
          afterImages: ['https://images.unsplash.com/photo-1556909172-54557c7e4fb7?w=800'],
          actualCost: 1200,
          durationDays: 4,
          isVerified: true,
          likesCount: 28,
          commentsCount: 8,
          savesCount: 15,
          completedAt: daysAgo(7),
        },
        {
          title: 'Master Bathroom Tile Refresh',
          description: 'Replaced the dated floor tile with modern large-format porcelain. The grout color makes all the difference!',
          visibility: PostVisibility.PUBLIC,
          beforeImages: ['https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=800'],
          afterImages: ['https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800'],
          actualCost: 3200,
          durationDays: 5,
          isVerified: true,
          likesCount: 45,
          commentsCount: 12,
          savesCount: 23,
          completedAt: daysAgo(14),
        },
        {
          title: 'Front Porch Makeover',
          description: 'New porch lights, painted the door, added some planters. Curb appeal is through the roof!',
          visibility: PostVisibility.NEIGHBORS_ONLY,
          beforeImages: ['https://images.unsplash.com/photo-1449844908441-8829872d2607?w=800'],
          afterImages: ['https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800'],
          actualCost: 650,
          durationDays: 2,
          isVerified: false,
          likesCount: 31,
          commentsCount: 9,
          savesCount: 14,
          completedAt: daysAgo(25),
        },
        {
          title: 'Pantry Organization',
          description: 'Installed pull-out drawers and lazy susans. Container Store containers for everything. So satisfying!',
          visibility: PostVisibility.FRIENDS_ONLY,
          afterImages: ['https://images.unsplash.com/photo-1556909114-44e3e70034e2?w=800'],
          actualCost: 400,
          durationDays: 1,
          isVerified: false,
          likesCount: 19,
          commentsCount: 5,
          savesCount: 8,
          completedAt: daysAgo(40),
        },
        {
          title: 'Outdoor Fire Pit Area',
          description: 'Built a flagstone patio with a gas fire pit. Perfect for entertaining!',
          visibility: PostVisibility.PUBLIC,
          beforeImages: ['https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=800'],
          afterImages: ['https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800'],
          actualCost: 4500,
          durationDays: 6,
          isVerified: true,
          likesCount: 52,
          commentsCount: 15,
          savesCount: 28,
          completedAt: daysAgo(55),
        },
      ];

      for (const post of alicePosts) {
        await prisma.projectPost.create({
          data: {
            author: { connect: { id: alice.id } },
            household: { connect: { id: aliceHousehold.id } },
            ...post,
          },
        });
      }
    }

    console.log('✅ Created 10 social posts');
  }

  // ============================================================================
  // 5. HOUSEHOLD INVOICES FOR BILLING PAGE
  // ============================================================================
  console.log('\n💰 Adding household invoices...');

  // Clear existing invoices
  await prisma.householdInvoice.deleteMany({
    where: { householdId: bobHousehold.id },
  });

  // Create current invoice (December 2024)
  const currentInvoice = await prisma.householdInvoice.create({
    data: {
      householdId: bobHousehold.id,
      invoiceNumber: 'INV-2024-0012',
      billingPeriodStart: daysAgo(30),
      billingPeriodEnd: daysAgo(0),
      subtotal: 847.50,
      platformFee: 0,
      total: 847.50,
      status: HouseholdInvoiceStatus.PENDING,
      notes: 'December 2024 consolidated invoice',
    },
  });

  // Create past invoice (November 2024 - paid)
  const novInvoice = await prisma.householdInvoice.create({
    data: {
      householdId: bobHousehold.id,
      invoiceNumber: 'INV-2024-0011',
      billingPeriodStart: daysAgo(60),
      billingPeriodEnd: daysAgo(30),
      subtotal: 723.00,
      platformFee: 0,
      total: 723.00,
      status: HouseholdInvoiceStatus.PAID,
      paidAt: daysAgo(25),
      notes: 'November 2024 consolidated invoice',
    },
  });

  // Create older invoice (October 2024 - paid)
  await prisma.householdInvoice.create({
    data: {
      householdId: bobHousehold.id,
      invoiceNumber: 'INV-2024-0010',
      billingPeriodStart: daysAgo(90),
      billingPeriodEnd: daysAgo(60),
      subtotal: 658.50,
      platformFee: 0,
      total: 658.50,
      status: HouseholdInvoiceStatus.PAID,
      paidAt: daysAgo(55),
      notes: 'October 2024 consolidated invoice',
    },
  });

  // Get or create bill accounts for line items
  const billAccounts = await prisma.billAccount.findMany({
    where: { householdId: bobHousehold.id },
    take: 5,
  });

  // Create invoice line items if we have bill accounts
  if (billAccounts.length > 0) {
    const lineItemsData = [
      { description: 'Monthly Management Fee', amount: 299.00, billAccountId: billAccounts[0]?.id },
      { description: 'House Cleaning (2 visits)', amount: 360.00, billAccountId: billAccounts[1]?.id || billAccounts[0]?.id },
      { description: 'HVAC Filters (2)', amount: 48.50, billAccountId: billAccounts[2]?.id || billAccounts[0]?.id },
      { description: 'Pest Control - Quarterly', amount: 99.00, billAccountId: billAccounts[3]?.id || billAccounts[0]?.id },
      { description: 'Light Bulb Replacement', amount: 41.00, billAccountId: billAccounts[4]?.id || billAccounts[0]?.id },
    ];

    for (const item of lineItemsData) {
      if (item.billAccountId) {
        await prisma.householdInvoiceItem.create({
          data: {
            householdInvoiceId: currentInvoice.id,
            billAccountId: item.billAccountId,
            description: item.description,
            amount: item.amount,
          },
        });
      }
    }
  }

  console.log('✅ Created 3 household invoices with line items');

  // ============================================================================
  // 5b. WORK ORDERS
  // ============================================================================
  console.log('\n🔧 Adding work orders...');

  // Clear existing work orders
  await prisma.workOrder.deleteMany({
    where: { householdId: bobHousehold.id },
  });

  const workOrders = [
    {
      householdId: bobHousehold.id,
      requestedByUserId: bob.id,
      title: 'Smoke Detector Battery Replacement',
      description: 'Replace batteries in all 6 smoke detectors. One is chirping.',
      status: WorkOrderStatus.SCHEDULED,
      preferredDate: daysFromNow(1),
      scheduledStart: daysFromNow(1),
      estimatedCost: 45,
      billingType: 'INCLUSIVE',
      isConciergeRequest: true,
    },
    {
      householdId: bobHousehold.id,
      requestedByUserId: bob.id,
      title: 'Garage Door Inspection',
      description: 'Grinding noise when opening/closing. Needs inspection and lubrication.',
      status: WorkOrderStatus.REQUESTED,
      preferredDate: daysFromNow(3),
      estimatedCost: 150,
      billingType: 'BILLABLE_TO_CLIENT',
    },
    {
      householdId: bobHousehold.id,
      requestedByUserId: bob.id,
      title: 'Gutter Cleaning - Fall Cleanup',
      description: 'Annual fall gutter cleaning. Remove leaves and debris.',
      status: WorkOrderStatus.COMPLETED,
      preferredDate: daysAgo(7),
      scheduledStart: daysAgo(7),
      completedAt: daysAgo(7),
      estimatedCost: 200,
      actualCost: 200,
      billingType: 'BILLABLE_TO_CLIENT',
    },
    {
      householdId: bobHousehold.id,
      requestedByUserId: bob.id,
      title: 'Kitchen Faucet Repair',
      description: 'Dripping faucet in kitchen. May need cartridge replacement.',
      status: WorkOrderStatus.IN_PROGRESS,
      preferredDate: daysAgo(0),
      scheduledStart: daysAgo(0),
      estimatedCost: 175,
      billingType: 'BILLABLE_TO_CLIENT',
    },
  ];

  for (const wo of workOrders) {
    const { householdId, requestedByUserId, ...rest } = wo;
    await prisma.workOrder.create({
      data: {
        ...rest,
        household: { connect: { id: householdId } },
        createdBy: { connect: { id: requestedByUserId } },
      } as any,
    });
  }
  console.log(`✅ Created ${workOrders.length} work orders`);

  // ============================================================================
  // 5c. SUPPORT CONVERSATIONS (for unified concierge)
  // ============================================================================
  console.log('\n💬 Adding support conversations...');

  // Clear existing conversations
  await prisma.conversation.deleteMany({
    where: { householdId: bobHousehold.id },
  });

  // Conversation with Home Manager
  const managerConvo = await prisma.conversation.create({
    data: {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      subject: 'Kitchen Backsplash Project Help',
      status: 'OPEN',
    },
  });

  const managerMessages = [
    { role: 'HOMEOWNER', content: 'Hi! I\'m thinking about doing a kitchen backsplash. Can you help me find some vendors?', daysAgo: 3 },
    { role: 'HOME_MANAGER', content: 'Hi Bob! I\'d love to help with that. What style are you thinking - subway tile, mosaic, or something more modern?', daysAgo: 3 },
    { role: 'HOMEOWNER', content: 'Classic white subway tile with gray grout. We want a timeless look.', daysAgo: 3 },
    { role: 'HOME_MANAGER', content: 'Great choice! I have 2 vendors I\'d recommend. Tile Pro has done great work for other clients in your area - $22-28/sq ft installed. Home Depot Pro Services is also reliable at $18-24/sq ft. Want me to get quotes from both?', daysAgo: 2 },
    { role: 'HOMEOWNER', content: 'Yes please! That would be great.', daysAgo: 2 },
    { role: 'HOME_MANAGER', content: 'Perfect! I\'ve reached out to both. Should have quotes by end of week. I\'ll add this to your Projects so you can track everything.', daysAgo: 2 },
  ];

  for (const msg of managerMessages) {
    await prisma.supportMessage.create({
      data: {
        conversationId: managerConvo.id,
        senderUserId: msg.role === 'HOMEOWNER' ? bob.id : manager?.id,
        senderRole: msg.role as any,
        body: msg.content,
        createdAt: daysAgo(msg.daysAgo),
      },
    });
  }

  // Conversation with Handyman (Mike)
  const handymanConvo = await prisma.conversation.create({
    data: {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      subject: 'Scheduled Visit - Smoke Detectors',
      status: 'OPEN',
    },
  });

  const handymanMessages = [
    { role: 'HOME_MANAGER', content: 'Hi Bob, Mike (our handyman) is scheduled to come by tomorrow between 2-4pm for the smoke detector batteries. He\'ll also check all the detectors.', daysAgo: 1 },
    { role: 'HOMEOWNER', content: 'Perfect, I\'ll be home. Should I have anything ready?', daysAgo: 1 },
    { role: 'HOME_MANAGER', content: 'Nope! Mike will bring everything needed. He\'ll ring the doorbell when he arrives. You\'ll get a notification when he checks in.', daysAgo: 1 },
    { role: 'HOMEOWNER', content: 'Great, thanks!', daysAgo: 0 },
  ];

  for (const msg of handymanMessages) {
    await prisma.supportMessage.create({
      data: {
        conversationId: handymanConvo.id,
        senderUserId: msg.role === 'HOMEOWNER' ? bob.id : manager?.id,
        senderRole: msg.role as any,
        body: msg.content,
        createdAt: daysAgo(msg.daysAgo),
      },
    });
  }

  // Conversation with Vendor (Ace Roofing)
  const vendorConvo = await prisma.conversation.create({
    data: {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      subject: 'Roof Inspection Follow-up',
      status: 'PENDING',
    },
  });

  const vendorMessages = [
    { role: 'HOME_MANAGER', content: 'Hi Bob, I received the inspection report from Ace Roofing. Good news - your roof is in great shape! They found minor wear on a few shingles near the chimney but nothing urgent.', daysAgo: 10 },
    { role: 'HOMEOWNER', content: 'That\'s a relief! Do they recommend any maintenance?', daysAgo: 10 },
    { role: 'HOME_MANAGER', content: 'They suggest replacing those shingles in the next year or two. Estimated cost would be $300-400. I\'ve added it to your maintenance calendar for spring. They also cleaned the gutters while they were up there.', daysAgo: 9 },
    { role: 'HOMEOWNER', content: 'Perfect, thanks for coordinating all of this!', daysAgo: 9 },
  ];

  for (const msg of vendorMessages) {
    await prisma.supportMessage.create({
      data: {
        conversationId: vendorConvo.id,
        senderUserId: msg.role === 'HOMEOWNER' ? bob.id : manager?.id,
        senderRole: msg.role as any,
        body: msg.content,
        createdAt: daysAgo(msg.daysAgo),
      },
    });
  }

  console.log('✅ Created 3 support conversations with messages');

  // ============================================================================
  // 6. UPDATE MAINTENANCE TASKS - MIX OF OVERDUE AND UPCOMING
  // ============================================================================
  console.log('\n📅 Updating maintenance task dates...');

  // Get existing tasks
  const existingTasks = await prisma.maintenanceTask.findMany({
    where: { householdId: bobHousehold.id },
    take: 10,
  });

  // Update some to be upcoming, not all overdue
  const taskUpdates = [
    { dueDate: daysFromNow(5), status: 'SCHEDULED' },   // Upcoming
    { dueDate: daysFromNow(14), status: 'SCHEDULED' },  // Upcoming
    { dueDate: daysFromNow(30), status: 'PENDING' },    // Upcoming
    { dueDate: daysAgo(7), status: 'OVERDUE' },         // Overdue
    { dueDate: daysAgo(3), status: 'OVERDUE' },         // Overdue
    { dueDate: daysFromNow(45), status: 'PENDING' },    // Upcoming
    { dueDate: daysFromNow(60), status: 'PENDING' },    // Upcoming
    { dueDate: daysAgo(14), status: 'COMPLETED' },      // Completed
    { dueDate: daysFromNow(7), status: 'SCHEDULED' },   // Upcoming
    { dueDate: daysFromNow(21), status: 'SCHEDULED' },  // Upcoming
  ];

  for (let i = 0; i < Math.min(existingTasks.length, taskUpdates.length); i++) {
    await prisma.maintenanceTask.update({
      where: { id: existingTasks[i].id },
      data: {
        dueDate: taskUpdates[i].dueDate,
        status: taskUpdates[i].status as any,
      },
    });
  }
  console.log('✅ Updated maintenance task dates');

  // ============================================================================
  // 7. CALENDAR EVENTS (Family) - 12+ events
  // ============================================================================
  console.log('\n📆 Adding calendar events...');

  // Clear existing events
  await prisma.familyEvent.deleteMany({
    where: { householdId: bobHousehold.id },
  });

  const calendarEvents = [
    // This week
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Emma\'s Soccer Practice',
      description: 'Pickup at 5pm. Bring snacks for team.',
      location: 'Pleasantville Recreation Center',
      startDate: daysFromNow(1),
      endDate: daysFromNow(1),
      isAllDay: false,
      category: FamilyEventCategory.SPORTS,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Jake\'s Swim Lesson',
      description: 'Level 4 class',
      location: 'YMCA',
      startDate: daysFromNow(2),
      endDate: daysFromNow(2),
      isAllDay: false,
      category: FamilyEventCategory.SPORTS,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Dentist - Kids',
      description: 'Emma & Jake checkups',
      location: 'Pleasantville Family Dental',
      startDate: daysFromNow(3),
      endDate: daysFromNow(3),
      isAllDay: false,
      category: FamilyEventCategory.MEDICAL,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Family Dinner - Grandparents',
      description: 'Grandma and Grandpa coming for dinner. Making lasagna.',
      location: 'Home',
      startDate: daysFromNow(4),
      endDate: daysFromNow(4),
      isAllDay: false,
      category: FamilyEventCategory.SOCIAL,
    },
    // Next week
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Emma\'s Soccer Game',
      description: 'vs. Westfield Tigers. Bring chairs!',
      location: 'Memorial Field',
      startDate: daysFromNow(6),
      endDate: daysFromNow(6),
      isAllDay: false,
      category: FamilyEventCategory.SPORTS,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Holiday Party',
      description: 'Neighborhood holiday party at the Smiths. Bring dessert.',
      location: '45 Oak Lane',
      startDate: daysFromNow(8),
      endDate: daysFromNow(8),
      isAllDay: false,
      category: FamilyEventCategory.HOLIDAY,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Jake\'s Piano Recital',
      description: 'Winter concert at school auditorium',
      location: 'Pleasantville Elementary School',
      startDate: daysFromNow(10),
      endDate: daysFromNow(10),
      isAllDay: false,
      category: FamilyEventCategory.SCHOOL,
    },
    // Coming up
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Emma\'s Birthday',
      description: 'Emma turns 10! Party at 2pm.',
      startDate: daysFromNow(15),
      endDate: daysFromNow(15),
      isAllDay: true,
      category: FamilyEventCategory.BIRTHDAY,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Wedding Anniversary',
      description: '12 years! Dinner reservations at Fireside.',
      location: 'Fireside Restaurant',
      startDate: daysFromNow(18),
      endDate: daysFromNow(18),
      isAllDay: false,
      category: FamilyEventCategory.SOCIAL,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'School Winter Break Starts',
      description: 'Kids off until Jan 2nd',
      startDate: daysFromNow(20),
      endDate: daysFromNow(20),
      isAllDay: true,
      category: FamilyEventCategory.SCHOOL,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Summer Camp Registration Opens',
      description: 'Register early for Camp Wildwood!',
      startDate: daysFromNow(25),
      endDate: daysFromNow(25),
      isAllDay: true,
      category: FamilyEventCategory.SCHOOL,
    },
    // Maintenance
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'HVAC Spring Service',
      description: 'Annual AC tune-up with Johnson HVAC',
      startDate: daysFromNow(90),
      isAllDay: false,
      category: FamilyEventCategory.MAINTENANCE,
    },
    {
      householdId: bobHousehold.id,
      createdByUserId: bob.id,
      title: 'Pool Opening',
      description: 'Crystal Clear Pools - pool opening and startup',
      startDate: daysFromNow(120),
      isAllDay: false,
      category: FamilyEventCategory.MAINTENANCE,
    },
  ];

  for (const event of calendarEvents) {
    await prisma.familyEvent.create({
      data: event,
    });
  }
  console.log(`✅ Created ${calendarEvents.length} calendar events`);

  // ============================================================================
  // 8. CONCIERGE THREAD (Chat support with manager)
  // ============================================================================
  console.log('\n🛎️ Adding concierge thread...');

  // ConciergeThread has unique constraint on (householdId, userId), so only one thread per user
  // Create or update the thread with all messages
  const existingThread = await prisma.conciergeThread.findUnique({
    where: {
      householdId_userId: {
        householdId: bobHousehold.id,
        userId: bob.id,
      },
    },
  });

  let threadId: string;
  if (existingThread) {
    threadId = existingThread.id;
    // Delete existing messages to replace with demo data
    await prisma.conciergeMessage.deleteMany({
      where: { threadId: existingThread.id },
    });
  } else {
    const newThread = await prisma.conciergeThread.create({
      data: {
        householdId: bobHousehold.id,
        userId: bob.id,
        title: 'Haven Concierge',
        isActive: true,
        lastMessageAt: daysAgo(0),
      },
    });
    threadId = newThread.id;
  }

  // All concierge messages in one thread
  const conciergeMessages = [
    // HVAC Filter conversation
    { role: 'user', content: 'Hi, the HVAC filters need to be replaced. They\'re 20x25x4, MERV 11. Can someone swap them out?', daysAgo: 35 },
    { role: 'assistant', content: 'Hi Bob! I\'d be happy to help with that. I\'ll have our handyman pick up the filters and stop by this week. Does Thursday work for you?', daysAgo: 35 },
    { role: 'user', content: 'Thursday is perfect, thanks!', daysAgo: 35 },
    { role: 'assistant', content: 'Great! Mike will be there Thursday between 10am-12pm. The cost for the filters plus installation will be $48.50, added to your monthly bill.', daysAgo: 34 },
    { role: 'assistant', content: 'Update: Mike just finished replacing both filters. Everything looks good! You\'re all set for the next 3 months.', daysAgo: 30 },
    // Kitchen lights
    { role: 'user', content: 'A few of the recessed lights in the kitchen went out. Can someone replace them?', daysAgo: 18 },
    { role: 'assistant', content: 'Of course! I\'ll send Mike over with the right LED bulbs. Which lights specifically - the ones over the island or by the sink?', daysAgo: 18 },
    { role: 'user', content: 'Over the island - 4 of them went out.', daysAgo: 18 },
    { role: 'assistant', content: 'Got it. Mike will replace all 4 with matching LEDs. He can come by Tuesday afternoon. Sound good?', daysAgo: 17 },
    { role: 'assistant', content: 'Done! Mike replaced all 4 bulbs. We went with 3000K warm white LEDs to match the others. Added $41.00 to your bill.', daysAgo: 14 },
    // Smoke detectors
    { role: 'user', content: 'One of the smoke detectors is chirping. I think the battery is low. Can someone check them all?', daysAgo: 3 },
    { role: 'assistant', content: 'Definitely! It\'s actually a good time to replace batteries in all of them - we recommend doing this annually. Mike can come by tomorrow to replace them all. I count 6 smoke detectors in your home - is that right?', daysAgo: 3 },
    { role: 'user', content: 'Yes, 6 sounds right. Tomorrow works.', daysAgo: 3 },
    { role: 'assistant', content: 'Perfect! Mike is scheduled for today between 2-4pm. He\'ll test all 6 detectors after replacing the batteries.', daysAgo: 0 },
  ];

  for (const msg of conciergeMessages) {
    await prisma.conciergeMessage.create({
      data: {
        threadId,
        role: msg.role,
        content: msg.content,
        createdAt: daysAgo(msg.daysAgo),
      },
    });
  }
  console.log(`✅ Created concierge thread with ${conciergeMessages.length} messages`);

  console.log('\n🎉 Comprehensive demo data seed complete!\n');
}

main()
  .catch((e) => {
    console.error('Error seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
