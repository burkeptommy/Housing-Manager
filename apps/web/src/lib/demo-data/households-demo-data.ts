// ============================================================================
// DEMO HOUSEHOLDS DATA
// ============================================================================
// All 6 demo households managed by Sarah Harrison
// Smith Family is the primary demo household that matches homeowner portal

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
  // HOUSEHOLD 1: SMITH FAMILY (Primary - matches homeowner portal exactly)
  // =========================================================================
  {
    id: 'household-smith-001',
    name: 'Smith Family',
    address: {
      street: '456 Oak Lane',
      city: 'Austin',
      state: 'TX',
      zip: '78701',
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
      yearBuilt: 2018,
      sqft: 3200,
      bedrooms: 4,
      bathrooms: 3.5,
      lotSize: 0.25,
      hasPool: true,
      hasGarage: true,
      garageSpaces: 2,
    },
    accessCodes: {
      gate: '1247',
      alarm: '4521#',
      alarmDisarm: '4521*',
      wifi: { ssid: 'SmithFamily24', password: 'Oak$Lane2024!' },
      garage: '8472',
      lockbox: '1234',
    },
    havenEmail: 'haven+smith@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-mike-001',
    healthScore: 94,
    urgentItems: 2,
    pendingApprovals: 1,
    unreadMessages: 2,
    lastContact: new Date(),
  },

  // =========================================================================
  // HOUSEHOLD 2: JOHNSON FAMILY
  // =========================================================================
  {
    id: 'household-johnson-001',
    name: 'Johnson Family',
    address: {
      street: '789 Maple Drive',
      city: 'Austin',
      state: 'TX',
      zip: '78702',
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
      yearBuilt: 2015,
      sqft: 2800,
      bedrooms: 4,
      bathrooms: 3,
      hasPool: false,
      hasGarage: true,
      garageSpaces: 2,
    },
    accessCodes: {
      gate: null,
      alarm: '7890#',
      wifi: { ssid: 'JohnsonHome', password: 'Maple789!' },
      garage: '5566',
    },
    havenEmail: 'haven+johnson@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-mike-001',
    healthScore: 88,
    urgentItems: 0,
    pendingApprovals: 1,
    unreadMessages: 0,
    lastContact: daysAgo(1),
  },

  // =========================================================================
  // HOUSEHOLD 3: MILLER RESIDENCE
  // =========================================================================
  {
    id: 'household-miller-001',
    name: 'Miller Residence',
    address: {
      street: '123 Pine Street',
      city: 'Austin',
      state: 'TX',
      zip: '78703',
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
      yearBuilt: 2020,
      sqft: 2400,
      bedrooms: 3,
      bathrooms: 2.5,
      hasPool: false,
      hasGarage: true,
      garageSpaces: 2,
    },
    accessCodes: {
      alarm: '1122#',
      wifi: { ssid: 'MillerNet', password: 'Pine123!' },
      garage: '9988',
    },
    havenEmail: 'haven+miller@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-mike-001',
    healthScore: 76,
    urgentItems: 1,
    pendingApprovals: 0,
    unreadMessages: 1,
    lastContact: new Date(),
  },

  // =========================================================================
  // HOUSEHOLD 4: WILLIAMS ESTATE
  // =========================================================================
  {
    id: 'household-williams-001',
    name: 'Williams Estate',
    address: {
      street: '555 Beverly Drive',
      city: 'West Lake Hills',
      state: 'TX',
      zip: '78746',
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
      yearBuilt: 2010,
      sqft: 5500,
      bedrooms: 5,
      bathrooms: 5.5,
      lotSize: 1.2,
      hasPool: true,
      hasGarage: true,
      garageSpaces: 3,
    },
    accessCodes: {
      gate: '7788',
      alarm: '2468#',
      wifi: { ssid: 'WilliamsEstate', password: 'Beverly555!' },
      garage: '1357',
      poolHouse: '0000',
    },
    havenEmail: 'haven+williams@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-carlos-001',
    healthScore: 98,
    urgentItems: 0,
    pendingApprovals: 0,
    unreadMessages: 0,
    lastContact: daysAgo(3),
  },

  // =========================================================================
  // HOUSEHOLD 5: CHEN FAMILY
  // =========================================================================
  {
    id: 'household-chen-001',
    name: 'Chen Family',
    address: {
      street: '321 Elm Way',
      city: 'Austin',
      state: 'TX',
      zip: '78704',
    },
    plan: 'CONCIERGE',
    monthlyFee: 149,
    memberSince: parseDate('2024-01-15'),
    status: 'ACTIVE',
    autoPayEnabled: false,
    paymentMethod: { type: 'bank_account', last4: '3344', bank: 'USAA' },
    accountBalance: 0,
    property: {
      type: 'townhouse',
      yearBuilt: 2019,
      sqft: 2100,
      bedrooms: 3,
      bathrooms: 2.5,
      hasPool: false,
      hasGarage: true,
      garageSpaces: 1,
    },
    accessCodes: {
      alarm: '5599#',
      wifi: { ssid: 'ChenHome', password: 'Elm321Way!' },
      garage: '4477',
    },
    havenEmail: 'haven+chen@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-mike-001',
    healthScore: 91,
    urgentItems: 0,
    pendingApprovals: 1,
    unreadMessages: 3,
    lastContact: new Date(),
  },

  // =========================================================================
  // HOUSEHOLD 6: DAVIS HOME
  // =========================================================================
  {
    id: 'household-davis-001',
    name: 'Davis Home',
    address: {
      street: '987 Cedar Court',
      city: 'Austin',
      state: 'TX',
      zip: '78705',
    },
    plan: 'STANDARD',
    monthlyFee: 49,
    memberSince: parseDate('2024-06-01'),
    status: 'ACTIVE',
    autoPayEnabled: true,
    paymentMethod: { type: 'credit_card', last4: '9999', brand: 'Amex' },
    accountBalance: 0,
    property: {
      type: 'condo',
      yearBuilt: 2017,
      sqft: 1400,
      bedrooms: 2,
      bathrooms: 2,
      hasPool: false,
      hasGarage: false,
    },
    accessCodes: {
      buildingEntry: '1234#',
      alarm: null,
      wifi: { ssid: 'DavisWiFi', password: 'Cedar987!' },
    },
    havenEmail: 'haven+davis@mail.haven.app',
    managerId: 'manager-sarah-001',
    handymanId: 'handyman-mike-001',
    healthScore: 100,
    urgentItems: 0,
    pendingApprovals: 0,
    unreadMessages: 0,
    lastContact: daysAgo(7),
  },
];

// ============================================================================
// SMITH FAMILY MEMBERS (Detailed)
// ============================================================================

export const SMITH_ADULTS: AdultMember[] = [
  {
    id: 'member-bob-smith',
    householdId: 'household-smith-001',
    type: 'ADULT',
    firstName: 'Bob',
    lastName: 'Smith',
    displayName: 'Bob Smith',
    email: 'bob@smith.family',
    phone: '(512) 555-0123',
    role: 'HEAD_OF_HOUSEHOLD',
    isAdmin: true,
    work: {
      employer: 'TechCorp Austin',
      title: 'VP of Engineering',
      address: '100 Congress Ave, Suite 400, Austin, TX',
      schedule: 'Mon-Fri 8am-5pm',
      daysInOffice: 3,
    },
    primaryVehicleId: 'vehicle-tesla-001',
    health: {
      doctor: 'Dr. Michael Chen',
      doctorPhone: '(512) 555-3001',
      allergies: [],
      medications: [],
    },
    sizes: {
      shirt: 'L',
      pants: '32x32',
      shoe: '10',
    },
    clubs: [
      { name: 'Austin Country Club', type: 'Golf', memberId: 'ACC-4521', monthlyDues: 750 },
      { name: 'Capital City Club', type: 'Social', memberId: 'CCC-1122', monthlyDues: 250 },
    ],
    preferences: {
      contactMethod: 'text',
      bestTimeToReach: 'evenings',
    },
  },
  {
    id: 'member-alice-smith',
    householdId: 'household-smith-001',
    type: 'ADULT',
    firstName: 'Alice',
    lastName: 'Smith',
    displayName: 'Alice Smith',
    email: 'alice@smith.family',
    phone: '(512) 555-0124',
    role: 'SPOUSE',
    isAdmin: true,
    work: {
      employer: 'Austin Medical Center',
      title: 'Pediatric Nurse Practitioner',
      address: '1234 Medical Pkwy, Austin, TX',
      schedule: 'Mon-Fri 9am-6pm, WFH Fridays',
      daysInOffice: 4,
    },
    primaryVehicleId: 'vehicle-highlander-001',
    health: {
      doctor: 'Dr. Sarah Williams',
      doctorPhone: '(512) 555-3002',
      allergies: ['Penicillin'],
      medications: [],
    },
    sizes: {
      shirt: 'S',
      pants: '4',
      shoe: '7',
    },
    clubs: [
      { name: 'Junior League of Austin', type: 'Civic', memberId: 'JLA-2234', monthlyDues: 100 },
    ],
    preferences: {
      contactMethod: 'either',
      handlesFinancialDecisions: true,
    },
  },
];

export const SMITH_CHILDREN: ChildMember[] = [
  {
    id: 'member-emma-smith',
    householdId: 'household-smith-001',
    type: 'CHILD',
    firstName: 'Emma',
    lastName: 'Smith',
    displayName: 'Emma Smith',
    age: 12,
    birthDate: parseDate('2012-04-15'),
    grade: '7th Grade',
    school: {
      name: 'Westlake Middle School',
      address: '4100 Westbank Dr, Austin, TX',
      phone: '(512) 555-7890',
      tuitionMonthly: 2200,
      tuitionDueDay: 26,
    },
    activities: [
      {
        name: 'Travel Soccer',
        organization: 'Lonestar SC',
        coach: 'Coach Martinez',
        schedule: 'Tue/Thu 5-7pm, Sat 9am',
        monthlyFee: 350,
        contact: '(512) 555-KICK',
      },
      {
        name: 'Piano Lessons',
        organization: 'Austin Music Academy',
        teacher: 'Mrs. Johnson',
        schedule: 'Wed 4pm',
        monthlyFee: 200,
        contact: '(512) 555-KEYS',
      },
    ],
    health: {
      pediatrician: 'Dr. Sarah Chen',
      pediatricianPhone: '(512) 555-PEDS',
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
    careProviderId: 'member-maria-santos',
  },
  {
    id: 'member-jake-smith',
    householdId: 'household-smith-001',
    type: 'CHILD',
    firstName: 'Jake',
    lastName: 'Smith',
    displayName: 'Jake Smith',
    age: 8,
    birthDate: parseDate('2016-09-22'),
    grade: '3rd Grade',
    school: {
      name: 'Eanes Elementary',
      address: '4101 Bee Cave Rd, Austin, TX',
      phone: '(512) 555-7891',
      tuitionMonthly: 0,
    },
    activities: [
      {
        name: 'Little League',
        organization: 'West Austin Little League',
        coach: 'Coach Johnson',
        schedule: 'Mon/Wed 5pm',
        monthlyFee: 75,
        contact: '(512) 555-BALL',
      },
      {
        name: 'Art Class',
        organization: 'Creative Kids Studio',
        schedule: 'Sat 10am',
        monthlyFee: 150,
        contact: '(512) 555-ARTS',
      },
    ],
    health: {
      pediatrician: 'Dr. Sarah Chen',
      pediatricianPhone: '(512) 555-PEDS',
      allergies: [],
      medications: [],
    },
    sizes: {
      shirt: 'Youth S',
      pants: '8',
      shoe: '3',
      lastUpdated: parseDate('2024-11-01'),
    },
    careProviderId: 'member-maria-santos',
  },
];

export const SMITH_PETS: PetMember[] = [
  {
    id: 'pet-max-smith',
    householdId: 'household-smith-001',
    name: 'Max',
    type: 'DOG',
    breed: 'Golden Retriever',
    age: 4,
    birthDate: parseDate('2020-03-10'),
    color: 'Golden',
    weight: 70,
    vet: {
      name: 'Dr. Williams',
      clinic: 'Westlake Animal Hospital',
      phone: '(512) 555-VETS',
      address: '2001 Westlake Dr, Austin, TX',
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
    monthlyExpenses: 150,
    notes: 'Friendly, loves people. Jumps when excited. Knows basic commands.',
  },
];

export const SMITH_STAFF: StaffMember[] = [
  {
    id: 'member-maria-santos',
    householdId: 'household-smith-001',
    type: 'STAFF',
    firstName: 'Maria',
    lastName: 'Santos',
    displayName: 'Maria Santos',
    role: 'Nanny',
    email: 'maria.s@austinnannies.com',
    phone: '(512) 555-0199',
    agency: 'Austin Elite Nannies',
    agencyPhone: '(512) 555-NANY',
    schedule: [
      { day: 'Monday', hours: '7am - 6pm' },
      { day: 'Tuesday', hours: '7am - 6pm' },
      { day: 'Wednesday', hours: '7am - 6pm' },
      { day: 'Thursday', hours: '7am - 6pm' },
      { day: 'Friday', hours: '7am - 3pm' },
    ],
    weeklyStipend: 1200,
    paymentMethod: 'direct_deposit',
    permissions: ['Kids Schedules', 'Emergency Contacts', 'Medical Info'],
    startDate: parseDate('2023-06-15'),
    contractEndDate: daysFromNow(7), // EXPIRING SOON
    emergencyContact: {
      name: 'Rosa Santos',
      relationship: 'Sister',
      phone: '(512) 555-0198',
    },
    notes: 'Excellent with kids. CPR certified. Has own car for pickups.',
  },
];

export const SMITH_VEHICLES: Vehicle[] = [
  {
    id: 'vehicle-tesla-001',
    householdId: 'household-smith-001',
    name: "Bob's Tesla",
    make: 'Tesla',
    model: 'Model Y',
    year: 2023,
    trim: 'Long Range AWD',
    color: 'Midnight Silver',
    vin: '5YJYGDEE9MF123456',
    licensePlate: 'ABC 1234',
    primaryDriverId: 'member-bob-smith',
    mileage: {
      current: 24500,
      updatedAt: daysAgo(7),
      annualEstimate: 12000,
    },
    registration: {
      state: 'TX',
      expiresAt: daysFromNow(45),
    },
    insurance: {
      provider: 'State Farm',
      policyNumber: 'SF-8847291',
      expiresAt: daysFromNow(180),
      monthlyPremium: 145,
    },
    loan: {
      hasLoan: true,
      lender: 'Tesla Finance',
      monthlyPayment: 750,
      balance: 38500,
      maturityDate: parseDate('2028-06-15'),
    },
    service: {
      lastServiceDate: parseDate('2024-08-15'),
      lastServiceMileage: 22000,
      nextServiceDue: daysFromNow(60),
      nextServiceMileage: 30000,
      preferredShop: 'Tesla Service Center - Austin',
    },
    serviceHistory: [
      { date: parseDate('2024-08-15'), type: 'Tire Rotation', mileage: 22000, cost: 75, shop: 'Tesla Service Center' },
      { date: parseDate('2024-02-10'), type: 'Cabin Air Filter', mileage: 18000, cost: 95, shop: 'Tesla Service Center' },
    ],
  },
  {
    id: 'vehicle-highlander-001',
    householdId: 'household-smith-001',
    name: 'Family Highlander',
    make: 'Toyota',
    model: 'Highlander',
    year: 2022,
    trim: 'XLE',
    color: 'Pearl White',
    vin: '5TDGZRBH8NS123456',
    licensePlate: 'XYZ 5678',
    primaryDriverId: 'member-alice-smith',
    mileage: {
      current: 35200,
      updatedAt: daysAgo(3),
      annualEstimate: 15000,
    },
    registration: {
      state: 'TX',
      expiresAt: daysFromNow(120),
    },
    insurance: {
      provider: 'State Farm',
      policyNumber: 'SF-8847292',
      expiresAt: daysFromNow(180),
      monthlyPremium: 125,
    },
    loan: {
      hasLoan: true,
      lender: 'Toyota Financial',
      monthlyPayment: 650,
      balance: 28000,
      maturityDate: parseDate('2027-09-01'),
    },
    service: {
      lastServiceDate: parseDate('2024-11-01'),
      lastServiceMileage: 32500,
      lastOilChange: parseDate('2024-11-01'),
      oilChangeMileage: 32500,
      nextServiceDue: daysFromNow(45),
      nextServiceMileage: 37500,
      preferredShop: 'Charles Maund Toyota',
    },
    serviceHistory: [
      { date: parseDate('2024-11-01'), type: 'Oil Change', mileage: 32500, cost: 85, shop: 'Charles Maund Toyota' },
      { date: parseDate('2024-11-01'), type: 'Tire Rotation', mileage: 32500, cost: 0, shop: 'Charles Maund Toyota' },
      { date: parseDate('2024-08-15'), type: 'Brake Inspection', mileage: 30000, cost: 0, shop: 'Charles Maund Toyota' },
    ],
  },
];

// ============================================================================
// DEMO REQUESTS
// ============================================================================

export const DEMO_REQUESTS: ServiceRequest[] = [
  // SMITH FAMILY
  {
    id: 'req-smith-001',
    visibleId: 'REQ-2847',
    householdId: 'household-smith-001',
    submittedBy: 'member-bob-smith',
    submittedAt: minutesAgo(2),
    title: 'Kitchen faucet dripping',
    description: 'Faucet in main kitchen has been dripping for 2 days. Getting worse.',
    category: 'PLUMBING',
    location: 'Kitchen',
    priority: 'MEDIUM',
    status: 'NEW',
    photos: [
      { id: 'photo-1', url: '/demo/faucet-1.jpg', caption: 'Dripping faucet' },
      { id: 'photo-2', url: '/demo/faucet-2.jpg', caption: 'Under sink' },
    ],
    aiTriageSuggestion: {
      category: 'Plumbing - Minor Repair',
      recommendedAction: 'Assign to handyman - likely cartridge replacement',
      estimatedCost: { min: 50, max: 150 },
      suggestedVendor: 'Handyman Mike',
      confidence: 0.92,
    },
  },
  {
    id: 'req-smith-002',
    visibleId: 'REQ-2831',
    householdId: 'household-smith-001',
    submittedBy: 'member-alice-smith',
    submittedAt: daysAgo(3),
    title: 'Annual HVAC inspection',
    description: 'Time for annual HVAC service',
    category: 'HVAC',
    priority: 'LOW',
    status: 'SCHEDULED',
    workOrderId: 'wo-smith-001',
    scheduledDate: daysFromNow(1),
    scheduledTime: '9:00 AM - 11:00 AM',
    assignedVendor: 'AirFlow HVAC',
  },

  // JOHNSON FAMILY
  {
    id: 'req-johnson-001',
    visibleId: 'REQ-2840',
    householdId: 'household-johnson-001',
    submittedAt: daysAgo(5),
    title: 'Garage door making grinding noise',
    description: 'Garage door started making a grinding noise when opening. Sounds like metal on metal.',
    category: 'GARAGE_DOOR',
    priority: 'MEDIUM',
    status: 'AWAITING_APPROVAL',
    workOrderId: 'wo-johnson-001',
    quotedAmount: 1200,
    quoteSentAt: daysAgo(2),
    approvalDeadline: daysFromNow(2),
    photos: [
      { id: 'photo-3', url: '/demo/garage-1.jpg', caption: 'Garage door' },
    ],
  },

  // MILLER FAMILY
  {
    id: 'req-miller-001',
    visibleId: 'REQ-2815',
    householdId: 'household-miller-001',
    submittedAt: daysAgo(14),
    title: 'HVAC making strange noise',
    description: 'AC unit making clicking sound',
    category: 'HVAC',
    priority: 'MEDIUM',
    status: 'IN_PROGRESS',
    managerNotes: 'Called AirFlow HVAC, waiting for callback to schedule',
  },

  // CHEN FAMILY
  {
    id: 'req-chen-001',
    visibleId: 'REQ-2843',
    householdId: 'household-chen-001',
    submittedAt: daysAgo(1),
    title: 'Help book spring break trip',
    description: 'Looking to go to Maui for spring break. Family of 4, March 15-22. Budget ~$8000.',
    category: 'TRAVEL',
    priority: 'LOW',
    status: 'IN_PROGRESS',
  },

  // WILLIAMS FAMILY
  {
    id: 'req-williams-001',
    visibleId: 'REQ-2835',
    householdId: 'household-williams-001',
    submittedAt: daysAgo(7),
    title: 'Pool heater not working',
    description: 'Pool heater stopped working last week. Water is getting cold.',
    category: 'POOL',
    priority: 'LOW',
    status: 'COMPLETED',
    workOrderId: 'wo-williams-001',
  },

  // DAVIS FAMILY
  {
    id: 'req-davis-001',
    visibleId: 'REQ-2820',
    householdId: 'household-davis-001',
    submittedAt: daysAgo(10),
    title: 'Garbage disposal jammed',
    description: 'Garbage disposal is stuck and making humming noise.',
    category: 'PLUMBING',
    priority: 'MEDIUM',
    status: 'COMPLETED',
    workOrderId: 'wo-davis-001',
  },
];

// ============================================================================
// DEMO WORK ORDERS
// ============================================================================

export const DEMO_WORK_ORDERS: WorkOrder[] = [
  // SMITH - HVAC Tomorrow
  {
    id: 'wo-smith-001',
    visibleId: 'WO-1892',
    householdId: 'household-smith-001',
    requestId: 'req-smith-002',
    title: 'HVAC Annual Service',
    description: 'Annual maintenance and inspection of HVAC system. Check filters, coils, refrigerant levels.',
    category: 'HVAC',
    priority: 'LOW',
    status: 'SCHEDULED',
    assignedTo: {
      type: 'vendor',
      vendorId: 'vendor-airflow-001',
      vendorName: 'AirFlow HVAC',
      technicianName: 'John Davis',
      technicianPhone: '(512) 555-HVAC',
    },
    scheduledDate: daysFromNow(1),
    scheduledTime: '9:00 AM',
    estimatedDuration: 2,
    estimatedCost: 150,
    requiresApproval: false,
    accessInstructions: 'Gate code 1247. Dog Max is friendly. HVAC in garage.',
    createdAt: daysAgo(3),
    createdBy: 'manager-sarah-001',
  },

  // SMITH - Faucet (if triaged)
  {
    id: 'wo-smith-002',
    visibleId: 'WO-1893',
    householdId: 'household-smith-001',
    requestId: 'req-smith-001',
    title: 'Kitchen faucet repair',
    description: 'Kitchen faucet dripping. Likely needs cartridge replacement.',
    category: 'PLUMBING',
    priority: 'MEDIUM',
    status: 'SCHEDULED',
    assignedTo: {
      type: 'handyman',
      handymanId: 'handyman-mike-001',
      handymanName: 'Mike Rodriguez',
      handymanPhone: '(512) 555-0199',
    },
    scheduledDate: daysFromNow(1),
    scheduledTime: '9:00 AM',
    estimatedDuration: 0.5,
    estimatedCost: 0,
    requiresApproval: false,
    createdAt: new Date(),
    createdBy: 'manager-sarah-001',
  },

  // JOHNSON - Pending approval
  {
    id: 'wo-johnson-001',
    visibleId: 'WO-1887',
    householdId: 'household-johnson-001',
    requestId: 'req-johnson-001',
    title: 'Roof shingle replacement',
    description: 'Replace damaged shingles on north side of roof. Approximately 50 sq ft area.',
    category: 'ROOFING',
    priority: 'MEDIUM',
    status: 'AWAITING_APPROVAL',
    assignedTo: {
      type: 'vendor',
      vendorId: 'vendor-aceroofing-001',
      vendorName: 'Ace Roofing',
    },
    quotes: [
      { vendorId: 'vendor-aceroofing-001', vendorName: 'Ace Roofing', amount: 1200, submittedAt: daysAgo(2) },
      { vendorId: 'vendor-topnotch-001', vendorName: 'TopNotch Roofing', amount: 1450, submittedAt: daysAgo(2) },
      { vendorId: 'vendor-reliable-001', vendorName: 'Reliable Roof Co', amount: 1350, submittedAt: daysAgo(3) },
    ],
    selectedQuote: 1200,
    requiresApproval: true,
    approvalSentAt: daysAgo(2),
    approvalReminders: 1,
    managerNote: "Ace Roofing has best price and we've used them before with good results.",
    createdAt: daysAgo(5),
    createdBy: 'manager-sarah-001',
  },

  // WILLIAMS - Completed
  {
    id: 'wo-williams-001',
    visibleId: 'WO-1885',
    householdId: 'household-williams-001',
    requestId: 'req-williams-001',
    title: 'Pool heater repair',
    description: 'Diagnose and repair pool heater not heating.',
    category: 'POOL',
    priority: 'LOW',
    status: 'COMPLETED',
    assignedTo: {
      type: 'vendor',
      vendorId: 'vendor-crystalclear-001',
      vendorName: 'Crystal Clear Pools',
      technicianName: 'Maria Garcia',
    },
    estimatedCost: 350,
    requiresApproval: false,
    createdAt: daysAgo(7),
    createdBy: 'manager-sarah-001',
  },

  // DAVIS - Completed
  {
    id: 'wo-davis-001',
    visibleId: 'WO-1880',
    householdId: 'household-davis-001',
    requestId: 'req-davis-001',
    title: 'Garbage disposal repair',
    description: 'Unjam and repair garbage disposal.',
    category: 'PLUMBING',
    priority: 'MEDIUM',
    status: 'COMPLETED',
    assignedTo: {
      type: 'handyman',
      handymanId: 'handyman-mike-001',
      handymanName: 'Mike Rodriguez',
    },
    estimatedCost: 0,
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
    householdId: 'household-smith-001',
    title: 'Research summer camps for Emma',
    description: 'Looking for STEM camps, budget $2k/week, Austin area',
    source: 'HOMEOWNER',
    requestedBy: 'member-alice-smith',
    requestedAt: daysAgo(2),
    dueDate: daysFromNow(5),
    priority: 'MEDIUM',
    status: 'IN_PROGRESS',
    progress: [
      { note: 'Found Camp Invention ($1,800/week) - STEM focus', addedAt: daysAgo(1), completed: true },
      { note: 'Found iD Tech Camp ($2,100/week) - coding focus', addedAt: hoursAgo(12), completed: true },
      { note: 'Need to check availability for July', addedAt: hoursAgo(1), completed: false },
    ],
    notifyOnComplete: true,
  },
  {
    id: 'task-002',
    householdId: 'household-johnson-001',
    title: 'Get quotes for driveway reseal',
    description: 'Driveway needs resealing. Get 3 quotes.',
    source: 'HOMEOWNER',
    requestedAt: daysAgo(5),
    dueDate: daysFromNow(7),
    priority: 'LOW',
    status: 'IN_PROGRESS',
    progress: [
      { note: 'Quote from ABC Paving: $850', addedAt: daysAgo(3), completed: true },
      { note: 'Quote from SealMaster: $920', addedAt: daysAgo(1), completed: true },
    ],
    notifyOnComplete: true,
  },
  {
    id: 'task-003',
    householdId: 'household-williams-001',
    title: 'Book anniversary dinner',
    description: 'Upscale Italian, Dec 28, party of 4, 7pm preferred',
    source: 'HOMEOWNER',
    requestedAt: daysAgo(1),
    dueDate: daysFromNow(3),
    priority: 'MEDIUM',
    status: 'NOT_STARTED',
    notifyOnComplete: true,
  },
  {
    id: 'task-004',
    householdId: 'household-chen-001',
    title: 'Renew gym membership',
    description: 'Equinox Downtown - confirm if auto-renew or cancel',
    source: 'HOMEOWNER',
    requestedAt: daysAgo(3),
    dueDate: daysFromNow(9),
    priority: 'LOW',
    status: 'NOT_STARTED',
    notifyOnComplete: true,
  },
  {
    id: 'task-005',
    householdId: 'household-davis-001',
    title: 'Find new landscaper',
    description: 'Current one is unreliable. Need recommendations.',
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
    householdId: 'household-miller-001',
    title: 'Schedule HVAC service',
    description: '14 days overdue - auto-generated from maintenance schedule',
    source: 'SYSTEM',
    generatedFrom: 'maintenance_schedule',
    dueDate: daysAgo(2),
    priority: 'HIGH',
    status: 'OVERDUE',
    linkedAssetId: 'asset-hvac-miller',
  },
  {
    id: 'task-007',
    householdId: 'household-smith-001',
    title: 'Pay tuition - Westlake Middle School',
    description: "Emma's January tuition",
    source: 'SYSTEM',
    generatedFrom: 'bill_schedule',
    dueDate: daysFromNow(3),
    priority: 'MEDIUM',
    status: 'NOT_STARTED',
    linkedBillAccountId: 'bill-westlake-smith',
    amount: 2200,
  },
  {
    id: 'task-008',
    householdId: 'household-smith-001',
    title: 'Vehicle registration renewal',
    description: 'Toyota Highlander - TX registration expires in 45 days',
    source: 'SYSTEM',
    generatedFrom: 'vehicle_tracking',
    dueDate: daysFromNow(23),
    priority: 'LOW',
    status: 'NOT_STARTED',
    linkedVehicleId: 'vehicle-highlander-001',
  },
  {
    id: 'task-009',
    householdId: 'household-smith-001',
    title: 'Nanny contract renewal',
    description: 'Maria Santos contract expires in 7 days',
    source: 'SYSTEM',
    generatedFrom: 'staff_tracking',
    dueDate: daysFromNow(5),
    priority: 'HIGH',
    status: 'NOT_STARTED',
    linkedStaffId: 'member-maria-santos',
  },
];

// ============================================================================
// DEMO BILLS
// ============================================================================

export const DEMO_BILLS: Bill[] = [
  // SMITH FAMILY
  {
    id: 'bill-mortgage-smith',
    householdId: 'household-smith-001',
    vendor: 'First National Bank',
    category: 'MORTGAGE',
    accountNumber: '****7744',
    amount: 2850,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: true,
    lastPaid: {
      amount: 2850,
      paidAt: daysAgo(22),
      confirmationNumber: 'FNB-2024120101',
    },
    nextDue: {
      amount: 2850,
      dueDate: parseDate('2025-01-01'),
    },
  },
  {
    id: 'bill-electric-smith',
    householdId: 'household-smith-001',
    vendor: 'ConEd',
    category: 'UTILITIES',
    accountNumber: '****4521',
    amount: 187.43,
    frequency: 'MONTHLY',
    dueDay: 28,
    autoPayEnabled: false,
    nextDue: {
      amount: 187.43,
      dueDate: daysFromNow(5),
    },
    lastPaid: {
      amount: 165.2,
      paidAt: daysAgo(25),
    },
  },
  {
    id: 'bill-gas-smith',
    householdId: 'household-smith-001',
    vendor: 'National Grid',
    category: 'UTILITIES',
    accountNumber: '****8832',
    amount: 94.5,
    frequency: 'MONTHLY',
    dueDay: 28,
    autoPayEnabled: false,
    nextDue: {
      amount: 94.5,
      dueDate: daysFromNow(5),
    },
  },
  {
    id: 'bill-westlake-smith',
    householdId: 'household-smith-001',
    vendor: 'Westlake Middle School',
    category: 'EDUCATION',
    linkedMemberId: 'member-emma-smith',
    amount: 2200,
    frequency: 'MONTHLY',
    dueDay: 26,
    autoPayEnabled: false,
    nextDue: {
      amount: 2200,
      dueDate: daysFromNow(3),
    },
  },
  {
    id: 'bill-nanny-smith',
    householdId: 'household-smith-001',
    vendor: 'Maria Santos',
    category: 'CHILDCARE',
    linkedStaffId: 'member-maria-santos',
    amount: 1200,
    frequency: 'WEEKLY',
    dueDay: 5,
    autoPayEnabled: true,
    paymentMethod: 'direct_deposit',
    nextDue: {
      amount: 1200,
      dueDate: nextFriday(),
    },
  },
  {
    id: 'bill-internet-smith',
    householdId: 'household-smith-001',
    vendor: 'Verizon',
    category: 'UTILITIES',
    amount: 187.5,
    frequency: 'MONTHLY',
    autoPayEnabled: false,
    nextDue: {
      amount: 187.5,
      dueDate: daysAgo(3),
    },
    status: 'OVERDUE',
  },

  // JOHNSON FAMILY
  {
    id: 'bill-mortgage-johnson',
    householdId: 'household-johnson-001',
    vendor: 'Wells Fargo',
    category: 'MORTGAGE',
    amount: 2450,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: true,
    nextDue: {
      amount: 2450,
      dueDate: parseDate('2025-01-01'),
    },
  },

  // MILLER FAMILY
  {
    id: 'bill-mortgage-miller',
    householdId: 'household-miller-001',
    vendor: 'Bank of America',
    category: 'MORTGAGE',
    amount: 1950,
    frequency: 'MONTHLY',
    dueDay: 15,
    autoPayEnabled: true,
    nextDue: {
      amount: 1950,
      dueDate: daysFromNow(22),
    },
  },

  // WILLIAMS FAMILY
  {
    id: 'bill-mortgage-williams',
    householdId: 'household-williams-001',
    vendor: 'Chase',
    category: 'MORTGAGE',
    amount: 4500,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: true,
    nextDue: {
      amount: 4500,
      dueDate: parseDate('2025-01-01'),
    },
  },

  // CHEN FAMILY
  {
    id: 'bill-hoa-chen',
    householdId: 'household-chen-001',
    vendor: 'Elm Way HOA',
    category: 'SERVICES',
    amount: 350,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: false,
    nextDue: {
      amount: 350,
      dueDate: parseDate('2025-01-01'),
    },
  },

  // DAVIS FAMILY
  {
    id: 'bill-hoa-davis',
    householdId: 'household-davis-001',
    vendor: 'Cedar Court HOA',
    category: 'SERVICES',
    amount: 425,
    frequency: 'MONTHLY',
    dueDay: 1,
    autoPayEnabled: true,
    nextDue: {
      amount: 425,
      dueDate: parseDate('2025-01-01'),
    },
  },
];

// ============================================================================
// DEMO MESSAGES
// ============================================================================

export const DEMO_MESSAGES: Message[] = [
  // Smith family conversation
  {
    id: 'msg-001',
    conversationId: 'conv-smith-001',
    householdId: 'household-smith-001',
    senderId: 'member-bob-smith',
    senderType: 'HOMEOWNER',
    senderName: 'Bob Smith',
    content: 'Kitchen faucet started dripping again. Can someone take a look?',
    attachments: [{ type: 'image', url: '/demo/faucet.jpg' }],
    sentAt: hoursAgo(4),
    readAt: hoursAgo(3.5),
  },
  {
    id: 'msg-002',
    conversationId: 'conv-smith-001',
    householdId: 'household-smith-001',
    senderId: 'manager-sarah-001',
    senderType: 'MANAGER',
    senderName: 'Sarah Harrison',
    content: "I see it! I'll have Mike (our handyman) swing by tomorrow morning. He's great with faucets. Does 9am work?",
    sentAt: hoursAgo(3.5),
    readAt: hoursAgo(3),
  },
  {
    id: 'msg-003',
    conversationId: 'conv-smith-001',
    householdId: 'household-smith-001',
    senderId: 'member-bob-smith',
    senderType: 'HOMEOWNER',
    senderName: 'Bob Smith',
    content: 'Perfect, Maria will be here. Thanks!',
    sentAt: hoursAgo(3),
    readAt: hoursAgo(2.5),
  },
  {
    id: 'msg-004',
    conversationId: 'conv-smith-001',
    householdId: 'household-smith-001',
    senderId: 'manager-sarah-001',
    senderType: 'MANAGER',
    senderName: 'Sarah Harrison',
    content: "Great! I've scheduled Mike for tomorrow 9am-12pm. I'll send you a confirmation once he's on his way.",
    metadata: { linkedWorkOrder: 'WO-1893' },
    sentAt: hoursAgo(2.5),
    readAt: hoursAgo(2),
  },
  {
    id: 'msg-005',
    conversationId: 'conv-smith-001',
    householdId: 'household-smith-001',
    senderId: 'member-bob-smith',
    senderType: 'HOMEOWNER',
    senderName: 'Bob Smith',
    content: 'Thanks! What time will the HVAC tech arrive tomorrow?',
    sentAt: hoursAgo(2),
    readAt: null,
  },

  // Chen family conversation
  {
    id: 'msg-006',
    conversationId: 'conv-chen-001',
    householdId: 'household-chen-001',
    senderId: 'member-david-chen',
    senderType: 'HOMEOWNER',
    senderName: 'David Chen',
    content: "Hi Sarah, we're thinking about a trip to Maui for spring break. Can you help with planning?",
    sentAt: daysAgo(1),
    readAt: daysAgo(1),
  },
  {
    id: 'msg-007',
    conversationId: 'conv-chen-001',
    householdId: 'household-chen-001',
    senderId: 'manager-sarah-001',
    senderType: 'MANAGER',
    senderName: 'Sarah Harrison',
    content: "Absolutely! I'd love to help plan your Maui trip. What dates are you thinking, and how many travelers?",
    sentAt: hoursAgo(20),
    readAt: hoursAgo(18),
  },
  {
    id: 'msg-008',
    conversationId: 'conv-chen-001',
    householdId: 'household-chen-001',
    senderId: 'member-david-chen',
    senderType: 'HOMEOWNER',
    senderName: 'David Chen',
    content: 'March 15-22, family of 4. Budget around $8000. Looking for a nice resort with kid-friendly activities.',
    sentAt: hoursAgo(18),
    readAt: null,
  },

  // Miller conversation
  {
    id: 'msg-009',
    conversationId: 'conv-miller-001',
    householdId: 'household-miller-001',
    senderId: 'member-lisa-miller',
    senderType: 'HOMEOWNER',
    senderName: 'Lisa Miller',
    content: 'Any update on the HVAC service? The clicking noise is getting worse.',
    sentAt: daysAgo(2),
    readAt: daysAgo(2),
  },
  {
    id: 'msg-010',
    conversationId: 'conv-miller-001',
    householdId: 'household-miller-001',
    senderId: 'manager-sarah-001',
    senderType: 'MANAGER',
    senderName: 'Sarah Harrison',
    content: "I'm so sorry for the delay! AirFlow HVAC is fully booked but promised to fit you in this week. I'll call them first thing tomorrow and confirm a time.",
    sentAt: daysAgo(2),
    readAt: null,
  },
];

// ============================================================================
// AGGREGATE FAMILY DATA
// ============================================================================

export const SMITH_FAMILY = {
  household: DEMO_HOUSEHOLDS.find(h => h.id === 'household-smith-001')!,
  adults: SMITH_ADULTS,
  children: SMITH_CHILDREN,
  pets: SMITH_PETS,
  staff: SMITH_STAFF,
  vehicles: SMITH_VEHICLES,
};

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
