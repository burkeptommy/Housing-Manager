// ============================================================================
// DEMO HOUSEHOLDS DATA
// ============================================================================
// All 6 demo households managed by Sarah Harrison
// Market: Fairfield County, CT and Westchester County, NY
// Morrison Family is the primary demo household that matches homeowner portal

import type {
  Household,
  AdultMember,
  ChildMember,
  PetMember,
  StaffMember,
  Vehicle,
  ServiceRequest,
  WorkOrder,
  Task,
  Bill,
  Message,
} from './types';
import {
  daysAgo,
  hoursAgo,
  minutesAgo,
  daysFromNow,
  parseDate,
  nextFriday,
} from './utils';

// ============================================================================
// DEMO HOUSEHOLDS
// ============================================================================

export const DEMO_HOUSEHOLDS: Household[] = [
  // =========================================================================
  // HOUSEHOLD 1: MORRISON FAMILY (Primary - matches homeowner portal exactly)
  // =========================================================================
  {
    id: 'household-morrison-001',
    name: 'Morrison Family',
    address: {
      street: '47 Meadow Lane',
      city: 'Greenwich',
      state: 'CT',
      zip: '06830',
      country: 'USA',
    },
    plan: 'CONCIERGE',
    monthlyFee: 149,
    memberSince: parseDate('2023-03-15'),
    status: 'ACTIVE',
    autoPayEnabled: true,
    paymentMethod: {
      type: 'bank_account',
      last4: '9876',
      bank: 'Chase',
    },
    accountBalance: 847.23,
    property: {
      type: 'single_family',
      yearBuilt: 1998,
      sqft: 4800,
      bedrooms: 5,
      bathrooms: 4.5,
      lotSize: 1.2,
      hasPool: true,
      hasGarage: true,
      garageSpaces: 3,
    },
    accessCodes: {
      gate: '1892',
      alarm: '4521#',
      alarmDisarm: '4521*',
      wifi: { ssid: 'MorrisonNet', password: 'Meadow$Lane2024!' },
      garage: '8472',
      lockbox: '1234',
    },
    havenEmail: 'haven+morrison@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-mike-001',
    healthScore: 94,
    urgentItems: 2,
    pendingApprovals: 1,
    unreadMessages: 2,
    lastContact: new Date(),
  },

  // =========================================================================
  // HOUSEHOLD 2: CHEN-WILLIAMS FAMILY
  // =========================================================================
  {
    id: 'household-chenwilliams-001',
    name: 'Chen-Williams Family',
    address: {
      street: '892 Hollow Tree Ridge',
      city: 'Darien',
      state: 'CT',
      zip: '06820',
    },
    plan: 'CONCIERGE',
    monthlyFee: 149,
    memberSince: parseDate('2023-06-01'),
    status: 'ACTIVE',
    autoPayEnabled: true,
    paymentMethod: { type: 'bank_account', last4: '4521', bank: 'Wells Fargo' },
    accountBalance: 0,
    property: {
      type: 'single_family',
      yearBuilt: 2005,
      sqft: 4200,
      bedrooms: 5,
      bathrooms: 4,
      hasPool: false,
      hasGarage: true,
      garageSpaces: 2,
    },
    accessCodes: {
      gate: null,
      alarm: '7890#',
      wifi: { ssid: 'ChenWilliamsHome', password: 'Hollow789!' },
      garage: '5566',
    },
    havenEmail: 'haven+chenwilliams@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-mike-001',
    healthScore: 88,
    urgentItems: 0,
    pendingApprovals: 1,
    unreadMessages: 0,
    lastContact: daysAgo(1),
  },

  // =========================================================================
  // HOUSEHOLD 3: PATEL RESIDENCE
  // =========================================================================
  {
    id: 'household-patel-001',
    name: 'Patel Residence',
    address: {
      street: '156 Ponus Ridge',
      city: 'New Canaan',
      state: 'CT',
      zip: '06840',
    },
    plan: 'CONCIERGE',
    monthlyFee: 149,
    memberSince: parseDate('2023-09-01'),
    status: 'ACTIVE',
    autoPayEnabled: true,
    paymentMethod: { type: 'credit_card', last4: '1234', brand: 'Visa' },
    accountBalance: -247.5,
    property: {
      type: 'single_family',
      yearBuilt: 1985,
      sqft: 3800,
      bedrooms: 4,
      bathrooms: 3.5,
      hasPool: false,
      hasGarage: true,
      garageSpaces: 2,
    },
    accessCodes: {
      alarm: '1122#',
      wifi: { ssid: 'PatelNet', password: 'Ponus123!' },
      garage: '9988',
    },
    havenEmail: 'haven+patel@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-mike-001',
    healthScore: 76,
    urgentItems: 1,
    pendingApprovals: 0,
    unreadMessages: 1,
    lastContact: new Date(),
  },

  // =========================================================================
  // HOUSEHOLD 4: FITZGERALD ESTATE
  // =========================================================================
  {
    id: 'household-fitzgerald-001',
    name: 'Fitzgerald Estate',
    address: {
      street: '88 Round Hill Road',
      city: 'Greenwich',
      state: 'CT',
      zip: '06831',
    },
    plan: 'ESTATE',
    monthlyFee: 299,
    memberSince: parseDate('2022-11-01'),
    status: 'ACTIVE',
    autoPayEnabled: true,
    paymentMethod: { type: 'bank_account', last4: '8877', bank: 'Bank of America' },
    accountBalance: 1250.0,
    property: {
      type: 'single_family',
      yearBuilt: 1928,
      sqft: 7200,
      bedrooms: 6,
      bathrooms: 6.5,
      lotSize: 3.5,
      hasPool: true,
      hasGarage: true,
      garageSpaces: 4,
    },
    accessCodes: {
      gate: '7788',
      alarm: '2468#',
      wifi: { ssid: 'FitzgeraldEstate', password: 'RoundHill88!' },
      garage: '1357',
      poolHouse: '0000',
    },
    havenEmail: 'haven+fitzgerald@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-carlos-001',
    healthScore: 98,
    urgentItems: 0,
    pendingApprovals: 0,
    unreadMessages: 0,
    lastContact: daysAgo(3),
  },

  // =========================================================================
  // HOUSEHOLD 5: NAKAMURA FAMILY
  // =========================================================================
  {
    id: 'household-nakamura-001',
    name: 'Nakamura Family',
    address: {
      street: '234 Gedney Way',
      city: 'Scarsdale',
      state: 'NY',
      zip: '10583',
    },
    plan: 'CONCIERGE',
    monthlyFee: 149,
    memberSince: parseDate('2024-01-15'),
    status: 'ACTIVE',
    autoPayEnabled: false,
    paymentMethod: { type: 'bank_account', last4: '3344', bank: 'USAA' },
    accountBalance: 0,
    property: {
      type: 'single_family',
      yearBuilt: 2012,
      sqft: 3600,
      bedrooms: 4,
      bathrooms: 3.5,
      hasPool: false,
      hasGarage: true,
      garageSpaces: 2,
    },
    accessCodes: {
      alarm: '5599#',
      wifi: { ssid: 'NakamuraHome', password: 'Gedney234!' },
      garage: '4477',
    },
    havenEmail: 'haven+nakamura@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-carlos-001',
    healthScore: 91,
    urgentItems: 0,
    pendingApprovals: 1,
    unreadMessages: 3,
    lastContact: new Date(),
  },

  // =========================================================================
  // HOUSEHOLD 6: RUSSO HOME
  // =========================================================================
  {
    id: 'household-russo-001',
    name: 'Russo Home',
    address: {
      street: '45 Milton Road',
      city: 'Rye',
      state: 'NY',
      zip: '10580',
    },
    plan: 'STANDARD',
    monthlyFee: 49,
    memberSince: parseDate('2024-06-01'),
    status: 'ACTIVE',
    autoPayEnabled: true,
    paymentMethod: { type: 'credit_card', last4: '9999', brand: 'Amex' },
    accountBalance: 0,
    property: {
      type: 'single_family',
      yearBuilt: 1965,
      sqft: 2800,
      bedrooms: 4,
      bathrooms: 3,
      hasPool: false,
      hasGarage: true,
      garageSpaces: 2,
    },
    accessCodes: {
      alarm: '6677#',
      wifi: { ssid: 'RussoWiFi', password: 'Milton45!' },
      garage: '2233',
    },
    havenEmail: 'haven+russo@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-carlos-001',
    healthScore: 100,
    urgentItems: 0,
    pendingApprovals: 0,
    unreadMessages: 0,
    lastContact: daysAgo(7),
  },
];

// ============================================================================
// MORRISON FAMILY MEMBERS (Detailed)
// ============================================================================

export const MORRISON_ADULTS: AdultMember[] = [
  {
    id: 'member-james-morrison',
    householdId: 'household-morrison-001',
    type: 'ADULT',
    firstName: 'James',
    lastName: 'Morrison',
    displayName: 'James Morrison',
    email: 'james@morrison.family',
    phone: '(203) 555-0123',
    role: 'HEAD_OF_HOUSEHOLD',
    isAdmin: true,
    work: {
      employer: 'Goldman Sachs',
      title: 'Managing Director',
      address: '200 West Street, New York, NY 10282',
      schedule: 'Mon-Fri 6am-7pm',
      daysInOffice: 4,
    },
    primaryVehicleId: 'vehicle-porsche-001',
    health: {
      doctor: 'Dr. Michael Chen',
      doctorPhone: '(203) 555-3001',
      allergies: [],
      medications: [],
    },
    sizes: {
      shirt: 'L',
      pants: '32x32',
      shoe: '10',
    },
    clubs: [
      { name: 'Greenwich Country Club', type: 'Golf', memberId: 'GCC-4521', monthlyDues: 1850 },
      { name: 'Round Hill Club', type: 'Tennis', memberId: 'RHC-1122', monthlyDues: 750 },
    ],
    preferences: {
      contactMethod: 'text',
      bestTimeToReach: 'evenings after 8pm',
    },
  },
  {
    id: 'member-catherine-morrison',
    householdId: 'household-morrison-001',
    type: 'ADULT',
    firstName: 'Catherine',
    lastName: 'Morrison',
    displayName: 'Catherine Morrison',
    email: 'catherine@morrison.family',
    phone: '(203) 555-0124',
    role: 'SPOUSE',
    isAdmin: true,
    work: {
      employer: 'Greenwich Hospital',
      title: 'Pediatric Nurse Practitioner',
      address: '5 Perryridge Rd, Greenwich, CT 06830',
      schedule: 'Mon-Thu 9am-5pm',
      daysInOffice: 4,
    },
    primaryVehicleId: 'vehicle-rangerover-001',
    health: {
      doctor: 'Dr. Sarah Williams',
      doctorPhone: '(203) 555-3002',
      allergies: ['Penicillin'],
      medications: [],
    },
    sizes: {
      shirt: 'S',
      pants: '4',
      shoe: '7',
    },
    clubs: [
      { name: 'Junior League of Greenwich', type: 'Civic', memberId: 'JLG-2234', monthlyDues: 150 },
      { name: 'Greenwich Country Club', type: 'Golf', memberId: 'GCC-4522', monthlyDues: 0 },
    ],
    preferences: {
      contactMethod: 'either',
      handlesFinancialDecisions: true,
    },
  },
];

export const MORRISON_CHILDREN: ChildMember[] = [
  {
    id: 'member-olivia-morrison',
    householdId: 'household-morrison-001',
    type: 'CHILD',
    firstName: 'Olivia',
    lastName: 'Morrison',
    displayName: 'Olivia Morrison',
    age: 12,
    birthDate: parseDate('2012-04-15'),
    grade: '7th Grade',
    school: {
      name: 'Brunswick School',
      address: '100 Maher Ave, Greenwich, CT 06830',
      phone: '(203) 625-5800',
      tuitionMonthly: 4200,
      tuitionDueDay: 1,
    },
    activities: [
      {
        name: 'Travel Soccer',
        organization: 'FC Westchester',
        coach: 'Coach Martinez',
        schedule: 'Tue/Thu 5-7pm, Sat 9am',
        monthlyFee: 450,
        contact: '(914) 555-5425',
      },
      {
        name: 'Piano Lessons',
        organization: 'Greenwich Music Academy',
        teacher: 'Mrs. Johnson',
        schedule: 'Wed 4pm',
        monthlyFee: 280,
        contact: '(203) 555-5397',
      },
    ],
    health: {
      pediatrician: 'Dr. Sarah Chen',
      pediatricianPhone: '(203) 555-7337',
      allergies: ['Peanuts', 'Tree nuts'],
      medications: ['EpiPen (emergency)'],
      epiPenLocation: 'Kitchen drawer + backpack',
    },
    sizes: {
      shirt: 'Youth M',
      pants: '12',
      shoe: '6',
      lastUpdated: parseDate('2024-06-15'),
    },
    careProviderId: 'member-elena-rodriguez',
  },
  {
    id: 'member-william-morrison',
    householdId: 'household-morrison-001',
    type: 'CHILD',
    firstName: 'William',
    lastName: 'Morrison',
    displayName: 'William Morrison',
    age: 8,
    birthDate: parseDate('2016-09-22'),
    grade: '3rd Grade',
    school: {
      name: 'Greenwich Country Day School',
      address: '401 Old Church Rd, Greenwich, CT 06830',
      phone: '(203) 863-5600',
      tuitionMonthly: 3800,
      tuitionDueDay: 1,
    },
    activities: [
      {
        name: 'Little League',
        organization: 'Greenwich Little League',
        coach: 'Coach Thompson',
        schedule: 'Mon/Wed 5pm',
        monthlyFee: 125,
        contact: '(203) 555-2255',
      },
      {
        name: 'Ice Hockey',
        organization: 'Greenwich Blues Youth Hockey',
        coach: 'Coach Brennan',
        schedule: 'Sat 7am, Sun 8am',
        monthlyFee: 450,
        contact: '(203) 555-4253',
      },
    ],
    health: {
      pediatrician: 'Dr. Sarah Chen',
      pediatricianPhone: '(203) 555-7337',
      allergies: [],
      medications: [],
    },
    sizes: {
      shirt: 'Youth S',
      pants: '8',
      shoe: '3',
      lastUpdated: parseDate('2024-11-01'),
    },
    careProviderId: 'member-elena-rodriguez',
  },
];

export const MORRISON_PETS: PetMember[] = [
  {
    id: 'pet-winston-morrison',
    householdId: 'household-morrison-001',
    name: 'Winston',
    type: 'DOG',
    breed: 'Golden Retriever',
    age: 4,
    birthDate: parseDate('2020-03-10'),
    color: 'Golden',
    weight: 70,
    vet: {
      name: 'Dr. Williams',
      clinic: 'Greenwich Animal Hospital',
      phone: '(203) 869-0534',
      address: '230 East Putnam Ave, Greenwich, CT 06830',
    },
    vaccinesDue: daysFromNow(30),
    lastVetVisit: parseDate('2024-09-15'),
    microchipId: '985141001234567',
    food: {
      brand: 'Blue Buffalo',
      type: 'Life Protection Adult Chicken',
      amountPerMonth: '30 lbs',
      autoReorder: true,
    },
    monthlyExpenses: 175,
    notes: 'Friendly, loves people. Jumps when excited. Knows basic commands.',
  },
];

export const MORRISON_STAFF: StaffMember[] = [
  {
    id: 'member-elena-rodriguez',
    householdId: 'household-morrison-001',
    type: 'STAFF',
    firstName: 'Elena',
    lastName: 'Rodriguez',
    displayName: 'Elena Rodriguez',
    role: 'Au Pair',
    email: 'elena.r@culturalcare.com',
    phone: '(203) 555-0199',
    agency: 'Cultural Care Au Pair',
    agencyPhone: '(800) 333-6056',
    schedule: [
      { day: 'Monday', hours: '7am - 6pm' },
      { day: 'Tuesday', hours: '7am - 6pm' },
      { day: 'Wednesday', hours: '7am - 6pm' },
      { day: 'Thursday', hours: '7am - 6pm' },
      { day: 'Friday', hours: '7am - 3pm' },
    ],
    weeklyStipend: 1500,
    paymentMethod: 'direct_deposit',
    permissions: ['Kids Schedules', 'Emergency Contacts', 'Medical Info'],
    startDate: parseDate('2023-06-15'),
    contractEndDate: daysFromNow(7), // EXPIRING SOON
    emergencyContact: {
      name: 'Maria Rodriguez',
      relationship: 'Mother (Spain)',
      phone: '+34 612 345 678',
    },
    notes: 'From Barcelona. Excellent with kids. CPR certified. Has CT license.',
  },
];

export const MORRISON_VEHICLES: Vehicle[] = [
  {
    id: 'vehicle-porsche-001',
    householdId: 'household-morrison-001',
    name: "James's Porsche",
    make: 'Porsche',
    model: 'Cayenne',
    year: 2023,
    trim: 'S E-Hybrid',
    color: 'Carrara White',
    vin: 'WP1AE2A58PLA12345',
    licensePlate: 'CT AB1234',
    primaryDriverId: 'member-james-morrison',
    mileage: {
      current: 18500,
      updatedAt: daysAgo(7),
      annualEstimate: 12000,
    },
    registration: {
      state: 'CT',
      expiresAt: daysFromNow(45),
    },
    insurance: {
      provider: 'Chubb',
      policyNumber: 'CH-8847291',
      expiresAt: daysFromNow(180),
      monthlyPremium: 285,
    },
    loan: {
      hasLoan: true,
      lender: 'Porsche Financial',
      monthlyPayment: 1450,
      balance: 68500,
      maturityDate: parseDate('2028-06-15'),
    },
    service: {
      lastServiceDate: parseDate('2024-08-15'),
      lastServiceMileage: 15000,
      nextServiceDue: daysFromNow(60),
      nextServiceMileage: 20000,
      preferredShop: 'Porsche of Greenwich',
    },
    serviceHistory: [
      { date: parseDate('2024-08-15'), type: 'Annual Service', mileage: 15000, cost: 450, shop: 'Porsche of Greenwich' },
      { date: parseDate('2024-02-10'), type: 'Tire Rotation', mileage: 10000, cost: 95, shop: 'Porsche of Greenwich' },
    ],
  },
  {
    id: 'vehicle-rangerover-001',
    householdId: 'household-morrison-001',
    name: 'Family Range Rover',
    make: 'Land Rover',
    model: 'Range Rover Sport',
    year: 2023,
    trim: 'HSE Dynamic',
    color: 'Santorini Black',
    vin: 'SALWR2RK5PA123456',
    licensePlate: 'CT XY5678',
    primaryDriverId: 'member-catherine-morrison',
    mileage: {
      current: 28200,
      updatedAt: daysAgo(3),
      annualEstimate: 15000,
    },
    registration: {
      state: 'CT',
      expiresAt: daysFromNow(120),
    },
    insurance: {
      provider: 'Chubb',
      policyNumber: 'CH-8847292',
      expiresAt: daysFromNow(180),
      monthlyPremium: 245,
    },
    loan: {
      hasLoan: true,
      lender: 'Land Rover Financial',
      monthlyPayment: 1150,
      balance: 52000,
      maturityDate: parseDate('2027-09-01'),
    },
    service: {
      lastServiceDate: parseDate('2024-11-01'),
      lastServiceMileage: 25000,
      lastOilChange: parseDate('2024-11-01'),
      oilChangeMileage: 25000,
      nextServiceDue: daysFromNow(45),
      nextServiceMileage: 30000,
      preferredShop: 'Land Rover Darien',
    },
    serviceHistory: [
      { date: parseDate('2024-11-01'), type: 'Oil Change', mileage: 25000, cost: 185, shop: 'Land Rover Darien' },
      { date: parseDate('2024-11-01'), type: 'Tire Rotation', mileage: 25000, cost: 0, shop: 'Land Rover Darien' },
      { date: parseDate('2024-08-15'), type: 'Brake Inspection', mileage: 22000, cost: 0, shop: 'Land Rover Darien' },
    ],
  },
];

// ============================================================================
// DEMO REQUESTS
// ============================================================================

export const DEMO_REQUESTS: ServiceRequest[] = [
  // MORRISON FAMILY
  {
    id: 'req-morrison-001',
    visibleId: 'REQ-2847',
    householdId: 'household-morrison-001',
    submittedBy: 'member-james-morrison',
    submittedAt: minutesAgo(2),
    title: 'Furnace making noise',
    description: 'Furnace in basement making a clicking noise when it starts up. Getting louder.',
    category: 'HVAC',
    location: 'Basement',
    priority: 'MEDIUM',
    status: 'NEW',
    photos: [
      { id: 'photo-1', url: '/demo/furnace-1.jpg', caption: 'Furnace unit' },
      { id: 'photo-2', url: '/demo/furnace-2.jpg', caption: 'Control panel' },
    ],
    aiTriageSuggestion: {
      category: 'HVAC - Furnace Repair',
      recommendedAction: 'Schedule vendor visit - likely igniter or inducer motor',
      estimatedCost: { min: 150, max: 450 },
      suggestedVendor: 'Hometown Heating & Cooling',
      confidence: 0.89,
    },
  },
  {
    id: 'req-morrison-002',
    visibleId: 'REQ-2831',
    householdId: 'household-morrison-001',
    submittedBy: 'member-catherine-morrison',
    submittedAt: daysAgo(3),
    title: 'Annual furnace service',
    description: 'Time for annual furnace and boiler maintenance before winter',
    category: 'HVAC',
    priority: 'LOW',
    status: 'SCHEDULED',
    workOrderId: 'wo-morrison-001',
    scheduledDate: daysFromNow(1),
    scheduledTime: '9:00 AM - 11:00 AM',
    assignedVendor: 'Hometown Heating & Cooling',
  },

  // CHEN-WILLIAMS FAMILY
  {
    id: 'req-chenwilliams-001',
    visibleId: 'REQ-2840',
    householdId: 'household-chenwilliams-001',
    submittedAt: daysAgo(5),
    title: 'Storm door not closing properly',
    description: 'Front storm door not latching. Cold air coming in.',
    category: 'DOOR',
    priority: 'MEDIUM',
    status: 'AWAITING_APPROVAL',
    workOrderId: 'wo-chenwilliams-001',
    quotedAmount: 350,
    quoteSentAt: daysAgo(2),
    approvalDeadline: daysFromNow(2),
    photos: [
      { id: 'photo-3', url: '/demo/door-1.jpg', caption: 'Storm door' },
    ],
  },

  // PATEL FAMILY
  {
    id: 'req-patel-001',
    visibleId: 'REQ-2815',
    householdId: 'household-patel-001',
    submittedAt: daysAgo(14),
    title: 'Slate roof missing tiles',
    description: 'Several slate tiles came loose after last storm. Need inspection.',
    category: 'ROOFING',
    priority: 'MEDIUM',
    status: 'IN_PROGRESS',
    managerNotes: 'Called Westchester Roofing, scheduled inspection for this week',
  },

  // NAKAMURA FAMILY
  {
    id: 'req-nakamura-001',
    visibleId: 'REQ-2843',
    householdId: 'household-nakamura-001',
    submittedAt: daysAgo(1),
    title: 'Help book ski trip to Stowe',
    description: 'Looking to go to Stowe, VT for February break. Family of 4, Feb 15-22. Budget ~$6000.',
    category: 'TRAVEL',
    priority: 'LOW',
    status: 'IN_PROGRESS',
  },

  // FITZGERALD FAMILY
  {
    id: 'req-fitzgerald-001',
    visibleId: 'REQ-2835',
    householdId: 'household-fitzgerald-001',
    submittedAt: daysAgo(7),
    title: 'Pool house heater not working',
    description: 'Pool house heater stopped working. Need it fixed before winter entertaining.',
    category: 'HVAC',
    priority: 'LOW',
    status: 'COMPLETED',
    workOrderId: 'wo-fitzgerald-001',
  },

  // RUSSO FAMILY
  {
    id: 'req-russo-001',
    visibleId: 'REQ-2820',
    householdId: 'household-russo-001',
    submittedAt: daysAgo(10),
    title: 'Generator not starting',
    description: 'Whole-house generator failed to start during last power outage.',
    category: 'ELECTRICAL',
    priority: 'MEDIUM',
    status: 'COMPLETED',
    workOrderId: 'wo-russo-001',
  },
];

// ============================================================================
// DEMO WORK ORDERS
// ============================================================================

export const DEMO_WORK_ORDERS: WorkOrder[] = [
  // MORRISON - Furnace Tomorrow
  {
    id: 'wo-morrison-001',
    visibleId: 'WO-1892',
    householdId: 'household-morrison-001',
    requestId: 'req-morrison-002',
    title: 'Furnace Annual Service',
    description: 'Annual maintenance and inspection of furnace and boiler. Check filters, burner, heat exchanger.',
    category: 'HVAC',
    priority: 'LOW',
    status: 'SCHEDULED',
    assignedTo: {
      type: 'vendor',
      vendorId: 'vendor-hometown-001',
      vendorName: 'Hometown Heating & Cooling',
      technicianName: 'Frank DiMaggio',
      technicianPhone: '(203) 555-4328',
    },
    scheduledDate: daysFromNow(1),
    scheduledTime: '9:00 AM',
    estimatedDuration: 2,
    estimatedCost: 225,
    requiresApproval: false,
    accessInstructions: 'Gate code 1892. Dog Winston is friendly. Furnace in basement.',
    createdAt: daysAgo(3),
    createdBy: 'manager-sarah-001',
  },

  // MORRISON - Furnace noise (if triaged)
  {
    id: 'wo-morrison-002',
    visibleId: 'WO-1893',
    householdId: 'household-morrison-001',
    requestId: 'req-morrison-001',
    title: 'Furnace noise diagnosis',
    description: 'Furnace making clicking noise on startup. Check igniter and inducer motor.',
    category: 'HVAC',
    priority: 'MEDIUM',
    status: 'SCHEDULED',
    assignedTo: {
      type: 'vendor',
      vendorId: 'vendor-hometown-001',
      vendorName: 'Hometown Heating & Cooling',
      technicianName: 'Frank DiMaggio',
      technicianPhone: '(203) 555-4328',
    },
    scheduledDate: daysFromNow(1),
    scheduledTime: '9:00 AM',
    estimatedDuration: 1,
    estimatedCost: 125,
    requiresApproval: false,
    createdAt: new Date(),
    createdBy: 'manager-sarah-001',
  },

  // CHEN-WILLIAMS - Pending approval
  {
    id: 'wo-chenwilliams-001',
    visibleId: 'WO-1887',
    householdId: 'household-chenwilliams-001',
    requestId: 'req-chenwilliams-001',
    title: 'Storm door repair',
    description: 'Repair or replace storm door latch mechanism and adjust door frame.',
    category: 'DOOR',
    priority: 'MEDIUM',
    status: 'AWAITING_APPROVAL',
    assignedTo: {
      type: 'handyman',
      handymanId: 'handyman-mike-001',
      handymanName: 'Mike Castellano',
    },
    quotes: [
      { vendorId: 'handyman-mike-001', vendorName: 'Handyman Mike', amount: 350, submittedAt: daysAgo(2) },
    ],
    selectedQuote: 350,
    requiresApproval: true,
    approvalSentAt: daysAgo(2),
    approvalReminders: 1,
    managerNote: 'Mike can handle this quickly. Parts included in estimate.',
    createdAt: daysAgo(5),
    createdBy: 'manager-sarah-001',
  },

  // FITZGERALD - Completed
  {
    id: 'wo-fitzgerald-001',
    visibleId: 'WO-1885',
    householdId: 'household-fitzgerald-001',
    requestId: 'req-fitzgerald-001',
    title: 'Pool house heater repair',
    description: 'Diagnose and repair pool house HVAC unit not heating.',
    category: 'HVAC',
    priority: 'LOW',
    status: 'COMPLETED',
    assignedTo: {
      type: 'vendor',
      vendorId: 'vendor-hometown-001',
      vendorName: 'Hometown Heating & Cooling',
      technicianName: 'Frank DiMaggio',
    },
    estimatedCost: 450,
    requiresApproval: false,
    createdAt: daysAgo(7),
    createdBy: 'manager-sarah-001',
  },

  // RUSSO - Completed
  {
    id: 'wo-russo-001',
    visibleId: 'WO-1880',
    householdId: 'household-russo-001',
    requestId: 'req-russo-001',
    title: 'Generator maintenance',
    description: 'Diagnose generator startup failure and perform annual maintenance.',
    category: 'ELECTRICAL',
    priority: 'MEDIUM',
    status: 'COMPLETED',
    assignedTo: {
      type: 'vendor',
      vendorId: 'vendor-danburyelectric-001',
      vendorName: 'Danbury Electric',
      technicianName: 'Kevin OConnor',
    },
    estimatedCost: 375,
    requiresApproval: false,
    createdAt: daysAgo(10),
    createdBy: 'manager-sarah-001',
  },
];

// ============================================================================
// DEMO TASKS
// ============================================================================

export const DEMO_TASKS: Task[] = [
  // FROM HOMEOWNERS
  {
    id: 'task-001',
    householdId: 'household-morrison-001',
    title: 'Research summer camps for Olivia',
    description: 'Looking for STEM camps, budget $3k/week, Fairfield County or Westchester area',
    source: 'HOMEOWNER',
    requestedBy: 'member-catherine-morrison',
    requestedAt: daysAgo(2),
    dueDate: daysFromNow(5),
    priority: 'MEDIUM',
    status: 'IN_PROGRESS',
    progress: [
      { note: 'Found Camp Invention at Whitby ($2,500/week) - STEM focus', addedAt: daysAgo(1), completed: true },
      { note: 'Found iD Tech Camp at Yale ($3,200/week) - coding focus', addedAt: hoursAgo(12), completed: true },
      { note: 'Need to check availability for July', addedAt: hoursAgo(1), completed: false },
    ],
    notifyOnComplete: true,
  },
  {
    id: 'task-002',
    householdId: 'household-chenwilliams-001',
    title: 'Get quotes for driveway sealing',
    description: 'Belgian block driveway needs repointing. Get 3 quotes.',
    source: 'HOMEOWNER',
    requestedAt: daysAgo(5),
    dueDate: daysFromNow(7),
    priority: 'LOW',
    status: 'IN_PROGRESS',
    progress: [
      { note: 'Quote from Darien Masonry: $2,850', addedAt: daysAgo(3), completed: true },
      { note: 'Quote from CT Stoneworks: $3,120', addedAt: daysAgo(1), completed: true },
    ],
    notifyOnComplete: true,
  },
  {
    id: 'task-003',
    householdId: 'household-fitzgerald-001',
    title: 'Book anniversary dinner',
    description: 'Upscale, Rebeccas or LHostellerie du Bois, Dec 28, party of 4, 7pm preferred',
    source: 'HOMEOWNER',
    requestedAt: daysAgo(1),
    dueDate: daysFromNow(3),
    priority: 'MEDIUM',
    status: 'NOT_STARTED',
    notifyOnComplete: true,
  },
  {
    id: 'task-004',
    householdId: 'household-nakamura-001',
    title: 'Renew gym membership',
    description: 'Equinox Greenwich - confirm if auto-renew or cancel',
    source: 'HOMEOWNER',
    requestedAt: daysAgo(3),
    dueDate: daysFromNow(9),
    priority: 'LOW',
    status: 'NOT_STARTED',
    notifyOnComplete: true,
  },
  {
    id: 'task-005',
    householdId: 'household-russo-001',
    title: 'Find new snow removal service',
    description: 'Current one is unreliable. Need recommendations for Rye area.',
    source: 'HOMEOWNER',
    requestedAt: daysAgo(7),
    dueDate: daysFromNow(13),
    priority: 'LOW',
    status: 'NOT_STARTED',
    notifyOnComplete: true,
  },

  // SYSTEM GENERATED
  {
    id: 'task-006',
    householdId: 'household-patel-001',
    title: 'Schedule furnace service',
    description: '14 days overdue - auto-generated from maintenance schedule',
    source: 'SYSTEM',
    generatedFrom: 'maintenance_schedule',
    dueDate: daysAgo(2),
    priority: 'HIGH',
    status: 'OVERDUE',
    linkedAssetId: 'asset-hvac-patel',
  },
  {
    id: 'task-007',
    householdId: 'household-morrison-001',
    title: 'Pay tuition - Brunswick School',
    description: "Olivia's January tuition",
    source: 'SYSTEM',
    generatedFrom: 'bill_schedule',
    dueDate: daysFromNow(3),
    priority: 'MEDIUM',
    status: 'NOT_STARTED',
    linkedBillAccountId: 'bill-brunswick-morrison',
    amount: 4200,
  },
  {
    id: 'task-008',
    householdId: 'household-morrison-001',
    title: 'Vehicle registration renewal',
    description: 'Range Rover Sport - CT registration expires in 45 days',
    source: 'SYSTEM',
    generatedFrom: 'vehicle_tracking',
    dueDate: daysFromNow(23),
    priority: 'LOW',
    status: 'NOT_STARTED',
    linkedVehicleId: 'vehicle-rangerover-001',
  },
  {
    id: 'task-009',
    householdId: 'household-morrison-001',
    title: 'Au pair visa renewal',
    description: 'Elena Rodriguez J-1 visa expires in 7 days',
    source: 'SYSTEM',
    generatedFrom: 'staff_tracking',
    dueDate: daysFromNow(5),
    priority: 'HIGH',
    status: 'NOT_STARTED',
    linkedStaffId: 'member-elena-rodriguez',
  },
];

// ============================================================================
// DEMO BILLS
// ============================================================================

export const DEMO_BILLS: Bill[] = [
  // MORRISON FAMILY
  {
    id: 'bill-mortgage-morrison',
    householdId: 'household-morrison-001',
    vendor: 'Chase Private Client',
    category: 'MORTGAGE',
    accountNumber: '****7744',
    amount: 8500,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: true,
    lastPaid: {
      amount: 8500,
      paidAt: daysAgo(22),
      confirmationNumber: 'CPC-2024120101',
    },
    nextDue: {
      amount: 8500,
      dueDate: parseDate('2025-01-01'),
    },
  },
  {
    id: 'bill-electric-morrison',
    householdId: 'household-morrison-001',
    vendor: 'Eversource',
    category: 'UTILITIES',
    accountNumber: '****4521',
    amount: 287.43,
    frequency: 'MONTHLY',
    dueDay: 28,
    autoPayEnabled: false,
    nextDue: {
      amount: 287.43,
      dueDate: daysFromNow(5),
    },
    lastPaid: {
      amount: 245.20,
      paidAt: daysAgo(25),
    },
  },
  {
    id: 'bill-oil-morrison',
    householdId: 'household-morrison-001',
    vendor: 'Petro Home Services',
    category: 'UTILITIES',
    accountNumber: '****8832',
    amount: 485.00,
    frequency: 'MONTHLY',
    dueDay: 15,
    autoPayEnabled: true,
    nextDue: {
      amount: 485.00,
      dueDate: daysFromNow(12),
    },
  },
  {
    id: 'bill-brunswick-morrison',
    householdId: 'household-morrison-001',
    vendor: 'Brunswick School',
    category: 'EDUCATION',
    linkedMemberId: 'member-olivia-morrison',
    amount: 4200,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: false,
    nextDue: {
      amount: 4200,
      dueDate: daysFromNow(3),
    },
  },
  {
    id: 'bill-gcds-morrison',
    householdId: 'household-morrison-001',
    vendor: 'Greenwich Country Day School',
    category: 'EDUCATION',
    linkedMemberId: 'member-william-morrison',
    amount: 3800,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: false,
    nextDue: {
      amount: 3800,
      dueDate: daysFromNow(3),
    },
  },
  {
    id: 'bill-aupair-morrison',
    householdId: 'household-morrison-001',
    vendor: 'Elena Rodriguez',
    category: 'CHILDCARE',
    linkedStaffId: 'member-elena-rodriguez',
    amount: 1500,
    frequency: 'WEEKLY',
    dueDay: 5,
    autoPayEnabled: true,
    paymentMethod: 'direct_deposit',
    nextDue: {
      amount: 1500,
      dueDate: nextFriday(),
    },
  },
  {
    id: 'bill-internet-morrison',
    householdId: 'household-morrison-001',
    vendor: 'Optimum',
    category: 'UTILITIES',
    amount: 225.00,
    frequency: 'MONTHLY',
    autoPayEnabled: false,
    nextDue: {
      amount: 225.00,
      dueDate: daysAgo(3),
    },
    status: 'OVERDUE',
  },
  {
    id: 'bill-gcc-morrison',
    householdId: 'household-morrison-001',
    vendor: 'Greenwich Country Club',
    category: 'SERVICES',
    amount: 1850,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: true,
    nextDue: {
      amount: 1850,
      dueDate: parseDate('2025-01-01'),
    },
  },

  // CHEN-WILLIAMS FAMILY
  {
    id: 'bill-mortgage-chenwilliams',
    householdId: 'household-chenwilliams-001',
    vendor: 'Wells Fargo',
    category: 'MORTGAGE',
    amount: 6800,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: true,
    nextDue: {
      amount: 6800,
      dueDate: parseDate('2025-01-01'),
    },
  },

  // PATEL FAMILY
  {
    id: 'bill-mortgage-patel',
    householdId: 'household-patel-001',
    vendor: 'Bank of America',
    category: 'MORTGAGE',
    amount: 5200,
    frequency: 'MONTHLY',
    dueDay: 15,
    autoPayEnabled: true,
    nextDue: {
      amount: 5200,
      dueDate: daysFromNow(22),
    },
  },

  // FITZGERALD FAMILY
  {
    id: 'bill-mortgage-fitzgerald',
    householdId: 'household-fitzgerald-001',
    vendor: 'J.P. Morgan Private Bank',
    category: 'MORTGAGE',
    amount: 12500,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: true,
    nextDue: {
      amount: 12500,
      dueDate: parseDate('2025-01-01'),
    },
  },

  // NAKAMURA FAMILY
  {
    id: 'bill-property-tax-nakamura',
    householdId: 'household-nakamura-001',
    vendor: 'Town of Scarsdale',
    category: 'SERVICES',
    amount: 8500,
    frequency: 'QUARTERLY',
    dueDay: 1,
    autoPayEnabled: false,
    nextDue: {
      amount: 8500,
      dueDate: parseDate('2025-01-01'),
    },
  },

  // RUSSO FAMILY
  {
    id: 'bill-property-tax-russo',
    householdId: 'household-russo-001',
    vendor: 'City of Rye',
    category: 'SERVICES',
    amount: 5200,
    frequency: 'QUARTERLY',
    dueDay: 1,
    autoPayEnabled: true,
    nextDue: {
      amount: 5200,
      dueDate: parseDate('2025-01-01'),
    },
  },
];

// ============================================================================
// DEMO MESSAGES
// ============================================================================

export const DEMO_MESSAGES: Message[] = [
  // Morrison family conversation
  {
    id: 'msg-001',
    conversationId: 'conv-morrison-001',
    householdId: 'household-morrison-001',
    senderId: 'member-james-morrison',
    senderType: 'HOMEOWNER',
    senderName: 'James Morrison',
    content: 'The furnace has been making a clicking noise when it starts up. Getting louder.',
    attachments: [{ type: 'image', url: '/demo/furnace.jpg' }],
    sentAt: hoursAgo(4),
    readAt: hoursAgo(3.5),
  },
  {
    id: 'msg-002',
    conversationId: 'conv-morrison-001',
    householdId: 'household-morrison-001',
    senderId: 'manager-sarah-001',
    senderType: 'MANAGER',
    senderName: 'Sarah Harrison',
    content: "Thanks for letting me know! I'll have Frank from Hometown Heating come out tomorrow. He's excellent with boiler systems. Does 9am work?",
    sentAt: hoursAgo(3.5),
    readAt: hoursAgo(3),
  },
  {
    id: 'msg-003',
    conversationId: 'conv-morrison-001',
    householdId: 'household-morrison-001',
    senderId: 'member-james-morrison',
    senderType: 'HOMEOWNER',
    senderName: 'James Morrison',
    content: 'Perfect, Elena will be here. Thanks!',
    sentAt: hoursAgo(3),
    readAt: hoursAgo(2.5),
  },
  {
    id: 'msg-004',
    conversationId: 'conv-morrison-001',
    householdId: 'household-morrison-001',
    senderId: 'manager-sarah-001',
    senderType: 'MANAGER',
    senderName: 'Sarah Harrison',
    content: "Great! I've scheduled Frank for tomorrow 9am-11am. I'll send you a confirmation once he's on his way. Gate code 1892, right?",
    metadata: { linkedWorkOrder: 'WO-1893' },
    sentAt: hoursAgo(2.5),
    readAt: hoursAgo(2),
  },
  {
    id: 'msg-005',
    conversationId: 'conv-morrison-001',
    householdId: 'household-morrison-001',
    senderId: 'member-james-morrison',
    senderType: 'HOMEOWNER',
    senderName: 'James Morrison',
    content: 'Yes, 1892. Also - any update on the ski trip to Stowe for February break?',
    sentAt: hoursAgo(2),
    readAt: null,
  },

  // Nakamura family conversation
  {
    id: 'msg-006',
    conversationId: 'conv-nakamura-001',
    householdId: 'household-nakamura-001',
    senderId: 'member-ken-nakamura',
    senderType: 'HOMEOWNER',
    senderName: 'Ken Nakamura',
    content: "Hi Sarah, we're thinking about a ski trip to Stowe for February break. Can you help with planning?",
    sentAt: daysAgo(1),
    readAt: daysAgo(1),
  },
  {
    id: 'msg-007',
    conversationId: 'conv-nakamura-001',
    householdId: 'household-nakamura-001',
    senderId: 'manager-sarah-001',
    senderType: 'MANAGER',
    senderName: 'Sarah Harrison',
    content: "Absolutely! Stowe is beautiful that time of year. What dates are you thinking, and how many travelers? Do you need ski lessons for the kids?",
    sentAt: hoursAgo(20),
    readAt: hoursAgo(18),
  },
  {
    id: 'msg-008',
    conversationId: 'conv-nakamura-001',
    householdId: 'household-nakamura-001',
    senderId: 'member-ken-nakamura',
    senderType: 'HOMEOWNER',
    senderName: 'Ken Nakamura',
    content: 'Feb 15-22, family of 4. Budget around $6000. Looking for ski-in/ski-out if possible. Yes, lessons for the kids would be great!',
    sentAt: hoursAgo(18),
    readAt: null,
  },

  // Patel conversation
  {
    id: 'msg-009',
    conversationId: 'conv-patel-001',
    householdId: 'household-patel-001',
    senderId: 'member-priya-patel',
    senderType: 'HOMEOWNER',
    senderName: 'Priya Patel',
    content: 'Any update on the roof inspection? A few more tiles came loose in yesterdays wind.',
    sentAt: daysAgo(2),
    readAt: daysAgo(2),
  },
  {
    id: 'msg-010',
    conversationId: 'conv-patel-001',
    householdId: 'household-patel-001',
    senderId: 'manager-sarah-001',
    senderType: 'MANAGER',
    senderName: 'Sarah Harrison',
    content: "I'm on it! Westchester Roofing is sending their slate specialist this Thursday. They're the best with historic homes. I'll confirm the exact time tomorrow.",
    sentAt: daysAgo(2),
    readAt: null,
  },
];

// ============================================================================
// AGGREGATE FAMILY DATA
// ============================================================================

export const MORRISON_FAMILY = {
  household: DEMO_HOUSEHOLDS.find(h => h.id === 'household-morrison-001')!,
  adults: MORRISON_ADULTS,
  children: MORRISON_CHILDREN,
  pets: MORRISON_PETS,
  staff: MORRISON_STAFF,
  vehicles: MORRISON_VEHICLES,
};

// Backwards compatibility aliases
export const SMITH_ADULTS = MORRISON_ADULTS;
export const SMITH_CHILDREN = MORRISON_CHILDREN;
export const SMITH_PETS = MORRISON_PETS;
export const SMITH_STAFF = MORRISON_STAFF;
export const SMITH_VEHICLES = MORRISON_VEHICLES;
export const SMITH_FAMILY = MORRISON_FAMILY;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Get a household by ID
 */
export const getHouseholdById = (id: string): Household | undefined => {
  return DEMO_HOUSEHOLDS.find(h => h.id === id);
};

/**
 * Get requests for a household
 */
export const getRequestsByHousehold = (householdId: string): ServiceRequest[] => {
  return DEMO_REQUESTS.filter(r => r.householdId === householdId);
};

/**
 * Get work orders for a household
 */
export const getWorkOrdersByHousehold = (householdId: string): WorkOrder[] => {
  return DEMO_WORK_ORDERS.filter(wo => wo.householdId === householdId);
};

/**
 * Get tasks for a household
 */
export const getTasksByHousehold = (householdId: string): Task[] => {
  return DEMO_TASKS.filter(t => t.householdId === householdId);
};

/**
 * Get bills for a household
 */
export const getBillsByHousehold = (householdId: string): Bill[] => {
  return DEMO_BILLS.filter(b => b.householdId === householdId);
};

/**
 * Get messages for a household
 */
export const getMessagesByHousehold = (householdId: string): Message[] => {
  return DEMO_MESSAGES.filter(m => m.householdId === householdId);
};

/**
 * Get all pending approvals across households
 */
export const getPendingApprovals = (): WorkOrder[] => {
  return DEMO_WORK_ORDERS.filter(wo => wo.status === 'AWAITING_APPROVAL');
};

/**
 * Get all overdue tasks
 */
export const getOverdueTasks = (): Task[] => {
  return DEMO_TASKS.filter(t => t.status === 'OVERDUE');
};

/**
 * Get unread messages count
 */
export const getUnreadMessagesCount = (): number => {
  return DEMO_MESSAGES.filter(m => m.readAt === null).length;
};

/**
 * Get total amount due across all bills this week
 */
export const getBillsDueThisWeek = (): { count: number; total: number } => {
  const weekFromNow = daysFromNow(7);
  const dueBills = DEMO_BILLS.filter(
    b => b.nextDue.dueDate <= weekFromNow && b.nextDue.dueDate >= new Date()
  );
  return {
    count: dueBills.length,
    total: dueBills.reduce((sum, b) => sum + b.nextDue.amount, 0),
  };
};
