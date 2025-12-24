// ============================================================================
// DEMO MANAGER DATA
// ============================================================================
// Manager profile and settings for the Haven Manager Portal demo
// Market: Fairfield County, CT and Westchester County, NY

import type { Manager, Handyman, Vendor, ScheduleEvent, ActivityItem } from './types';
import { daysAgo, hoursAgo, minutesAgo, daysFromNow, todayAt, parseDate } from './utils';

// ============================================================================
// DEMO MANAGER
// ============================================================================

export const DEMO_MANAGER: Manager = {
  id: 'manager-sarah-001',
  email: 'sarah@haven.app',
  firstName: 'Sarah',
  lastName: 'Chen',
  displayName: 'Sarah Chen',
  role: 'MANAGER',
  avatar: '/avatars/sarah-chen.jpg',
  phone: '(203) 555-0100',
  title: 'Home Manager',
  hireDate: parseDate('2023-01-15'),
  settings: {
    notificationsEnabled: true,
    emailDigest: 'daily',
    defaultView: 'dashboard',
    theme: 'light',
  },
  metrics: {
    householdsManaged: 6,
    avgResponseTime: 2.3,
    avgRating: 4.8,
    requestsThisMonth: 47,
    tasksCompletedThisMonth: 89,
  },
};

// ============================================================================
// DEMO HANDYMEN
// ============================================================================

export const DEMO_HANDYMEN: Handyman[] = [
  {
    id: 'handyman-mike-001',
    firstName: 'Mike',
    lastName: 'Castellano',
    displayName: 'Mike Castellano',
    phone: '(203) 555-0199',
    email: 'mike.c@haven.app',
    role: 'PRIMARY',
    serviceArea: 'Greenwich, Darien, New Canaan',
    status: 'ON_JOB',
    currentLocation: {
      householdId: 'household-morrison-001',
      checkedInAt: minutesAgo(35),
      taskDescription: 'Furnace filter replacement',
    },
    schedule: [
      { date: new Date(), householdId: 'household-morrison-001', time: '9:00 AM', task: 'Furnace maintenance', status: 'IN_PROGRESS' },
      { date: new Date(), householdId: 'household-chenwilliams-001', time: '11:00 AM', task: 'Storm door adjustment', status: 'SCHEDULED' },
      { date: new Date(), householdId: 'household-patel-001', time: '2:00 PM', task: 'Monthly maintenance round', status: 'SCHEDULED' },
    ],
    specialties: ['Plumbing', 'General repairs', 'Painting', 'Winterization'],
    rating: 4.9,
    jobsCompleted: 234,
  },
  {
    id: 'handyman-carlos-001',
    firstName: 'Carlos',
    lastName: 'Reyes',
    displayName: 'Carlos Reyes',
    phone: '(914) 555-0198',
    email: 'carlos.r@haven.app',
    role: 'BACKUP',
    serviceArea: 'Scarsdale, Rye, Larchmont',
    status: 'OFF_DUTY',
    nextAvailable: daysFromNow(1),
    schedule: [],
    specialties: ['Electrical', 'Smart Home', 'Generator Systems'],
    rating: 4.8,
    jobsCompleted: 156,
  },
];

// ============================================================================
// DEMO VENDORS
// ============================================================================

export const DEMO_VENDORS: Vendor[] = [
  {
    id: 'vendor-hometown-001',
    name: 'Hometown Heating & Cooling',
    category: 'HVAC',
    contact: {
      name: 'Frank DiMaggio',
      phone: '(203) 555-4328',
      email: 'service@hometownhvac.com',
    },
    address: '287 Post Road, Darien, CT 06820',
    serviceArea: ['Greenwich', 'Darien', 'New Canaan', 'Stamford', 'Norwalk'],
    rating: 4.9,
    totalJobs: 112,
    totalBilled: 38500,
    priceRange: '$$',
    responseTime: 'Same day',
    services: [
      { name: 'Service call', price: 125 },
      { name: 'Annual maintenance', price: 225 },
      { name: 'Furnace repair', priceRange: '$150-800' },
      { name: 'Boiler service', priceRange: '$200-1200' },
    ],
    notes: 'Very reliable. Frank handles our complex boiler systems expertly.',
    documents: {
      insurance: { expiry: parseDate('2025-06-15') },
      license: 'CT-HVAC-28456',
      w9: true,
    },
  },
  {
    id: 'vendor-greenwichplumbing-001',
    name: 'Greenwich Plumbing & Heating',
    category: 'PLUMBING',
    contact: {
      name: 'Tony Russo',
      phone: '(203) 555-7562',
      email: 'tony@greenwichplumbing.com',
    },
    address: '156 Sound Beach Ave, Old Greenwich, CT 06870',
    rating: 4.9,
    totalJobs: 143,
    totalBilled: 58000,
    priceRange: '$$',
    responseTime: '2-4 hours',
    services: [
      { name: 'Service call', price: 95 },
      { name: 'Faucet replacement', priceRange: '$175-350' },
      { name: 'Water heater install', priceRange: '$1200-2400' },
      { name: 'Sump pump service', priceRange: '$250-600' },
    ],
    notes: "Family business since 1982. Fair quotes, doesn't upsell.",
  },
  {
    id: 'vendor-westchesterroofing-001',
    name: 'Westchester Roofing Co.',
    category: 'ROOFING',
    contact: {
      name: 'Michael Brennan',
      phone: '(914) 555-7663',
      email: 'mike@westchesterroofing.com',
    },
    address: '89 Mamaroneck Ave, White Plains, NY 10601',
    rating: 4.8,
    totalJobs: 31,
    totalBilled: 72000,
    priceRange: '$$',
    responseTime: '1-2 days',
    services: [
      { name: 'Inspection', price: 175 },
      { name: 'Slate repair', priceRange: '$500-2500' },
      { name: 'Ice dam removal', priceRange: '$400-1200' },
      { name: 'Full replacement', priceRange: '$15000-35000' },
    ],
    notes: 'Specializes in historic slate roofs. Used for Patel roof repair.',
  },
  {
    id: 'vendor-connecticutroofing-001',
    name: 'Connecticut Roofing Specialists',
    category: 'ROOFING',
    contact: {
      name: 'Dave Morrison',
      phone: '(203) 555-7667',
    },
    address: '445 Main St, Stamford, CT 06901',
    rating: 4.6,
    totalJobs: 18,
    totalBilled: 41000,
    priceRange: '$$$',
    responseTime: '2-3 days',
    notes: 'Premium option for complex roofing projects.',
  },
  {
    id: 'vendor-danburyelectric-001',
    name: 'Danbury Electric',
    category: 'ELECTRICAL',
    contact: {
      name: 'Kevin OConnor',
      phone: '(203) 555-3537',
      email: 'service@danburyelectric.com',
    },
    address: '78 Federal Road, Danbury, CT 06811',
    rating: 4.9,
    totalJobs: 67,
    totalBilled: 29500,
    priceRange: '$$',
    responseTime: 'Same day',
    services: [
      { name: 'Service call', price: 110 },
      { name: 'Panel inspection', price: 175 },
      { name: 'Generator install', priceRange: '$4500-12000' },
      { name: 'Panel upgrade', priceRange: '$2000-4500' },
    ],
    notes: 'Licensed master electrician. Generator specialist for storm season.',
    documents: {
      insurance: { expiry: parseDate('2025-08-20') },
      license: 'CT-E1-0028456',
      w9: true,
    },
  },
  {
    id: 'vendor-poolsunlimited-001',
    name: 'Pools Unlimited',
    category: 'POOL',
    contact: {
      name: 'Steve Ferraro',
      phone: '(203) 555-7665',
      email: 'steve@poolsunlimited.com',
    },
    address: '234 Tokeneke Road, Darien, CT 06820',
    rating: 4.8,
    totalJobs: 98,
    totalBilled: 42000,
    priceRange: '$$',
    responseTime: 'Next day',
    services: [
      { name: 'Weekly service', price: 175 },
      { name: 'Opening (spring)', price: 450 },
      { name: 'Closing (fall)', price: 425 },
      { name: 'Equipment repair', priceRange: '$150-750' },
    ],
    notes: 'Handles Morrison and Fitzgerald pool service. Winter cover specialist.',
  },
  {
    id: 'vendor-countrylandscape-001',
    name: 'Country Landscape Design',
    category: 'LANDSCAPING',
    contact: {
      name: 'Roberto Mendez',
      phone: '(203) 555-5296',
      email: 'info@countrylandscape.com',
    },
    address: '567 North Ave, New Canaan, CT 06840',
    rating: 4.7,
    totalJobs: 312,
    totalBilled: 78000,
    priceRange: '$$',
    responseTime: 'Weekly schedule',
    services: [
      { name: 'Weekly mowing', price: 125 },
      { name: 'Fall leaf cleanup', priceRange: '$400-800' },
      { name: 'Snow plowing (seasonal)', priceRange: '$2500-5000' },
      { name: 'Spring cleanup', price: 350 },
    ],
    notes: 'Full-service landscaping. Handles snow removal for most households.',
  },
  {
    id: 'vendor-petro-001',
    name: 'Petro Home Services',
    category: 'FUEL_OIL',
    contact: {
      name: 'Customer Service',
      phone: '(203) 555-7387',
    },
    address: '890 West Ave, Norwalk, CT 06851',
    rating: 4.5,
    totalJobs: 186,
    totalBilled: 125000,
    priceRange: '$$',
    responseTime: 'Same day delivery',
    services: [
      { name: 'Oil delivery', priceRange: 'Market rate' },
      { name: 'Tank inspection', price: 125 },
      { name: 'Burner tune-up', price: 225 },
    ],
    notes: 'Automatic delivery service. Handles 4 households.',
  },
  {
    id: 'vendor-terminix-001',
    name: 'Terminix',
    category: 'PEST_CONTROL',
    contact: {
      name: 'Customer Service',
      phone: '(203) 555-7378',
    },
    rating: 4.4,
    totalJobs: 52,
    totalBilled: 9800,
    priceRange: '$$',
    responseTime: '1-2 days',
    services: [
      { name: 'Quarterly treatment', price: 85 },
      { name: 'Termite inspection', price: 175 },
      { name: 'Tick & mosquito treatment', price: 125 },
    ],
    notes: 'Essential for Lyme disease prevention in this area.',
  },
];

// ============================================================================
// DEMO SCHEDULE (Today's Events)
// ============================================================================

export const DEMO_SCHEDULE: ScheduleEvent[] = [
  {
    id: 'event-001',
    type: 'BLOCK',
    title: 'Start of Day Review',
    description: 'Check overnight messages, prioritize tasks',
    startTime: todayAt(8, 0).getTime(),
    duration: 30,
  },
  {
    id: 'event-002',
    type: 'SITE_VISIT',
    title: 'Morrison - Furnace Service',
    householdId: 'household-morrison-001',
    workOrderId: 'wo-morrison-001',
    vendorName: 'Hometown Heating & Cooling',
    startTime: todayAt(9, 0).getTime(),
    duration: 120,
    address: '47 Meadow Lane, Greenwich, CT',
    accessNotes: 'Gate code: 1892, Dog Winston is friendly',
  },
  {
    id: 'event-003',
    type: 'CALL_BLOCK',
    title: 'Call Block - Follow-ups',
    description: 'Patel: driveway quote, Fitzgerald: ski trip planning, Nakamura: au pair visa',
    startTime: todayAt(11, 0).getTime(),
    duration: 60,
    calls: [
      { householdId: 'household-patel-001', topic: 'Driveway sealing quote decision' },
      { householdId: 'household-fitzgerald-001', topic: 'Stowe ski trip research update' },
      { householdId: 'household-nakamura-001', topic: 'Au pair visa renewal paperwork' },
    ],
  },
  {
    id: 'event-004',
    type: 'BILL_PAY',
    title: 'Bill Pay Block',
    description: '14 bills due this week across households ($18,450 total)',
    startTime: todayAt(13, 0).getTime(),
    duration: 60,
  },
  {
    id: 'event-005',
    type: 'SITE_VISIT',
    title: 'Chen-Williams - Handyman Monthly Check',
    householdId: 'household-chenwilliams-001',
    handymanId: 'handyman-mike-001',
    startTime: todayAt(14, 0).getTime(),
    duration: 90,
    address: '892 Hollow Tree Ridge, Darien, CT',
    tasks: ['Furnace filter change', 'Smoke detectors', 'Generator test run'],
  },
];

// ============================================================================
// DEMO ACTIVITY FEED
// ============================================================================

export const DEMO_ACTIVITY: ActivityItem[] = [
  {
    id: 'activity-001',
    type: 'REQUEST_SUBMITTED',
    householdId: 'household-morrison-001',
    householdName: 'Morrison',
    description: 'James submitted new request "Furnace making noise"',
    timestamp: minutesAgo(2),
    read: false,
  },
  {
    id: 'activity-002',
    type: 'APPROVAL_RECEIVED',
    householdId: 'household-patel-001',
    householdName: 'Patel',
    description: 'Approved slate roof repair ($2,400)',
    timestamp: minutesAgo(15),
    read: false,
  },
  {
    id: 'activity-003',
    type: 'HANDYMAN_CHECKIN',
    householdId: 'household-morrison-001',
    householdName: 'Morrison',
    description: 'Handyman Mike checked in at property',
    timestamp: hoursAgo(1),
    read: true,
  },
  {
    id: 'activity-004',
    type: 'EMAIL_FORWARDED',
    householdId: 'household-nakamura-001',
    householdName: 'Nakamura',
    description: 'Forwarded email - "Utility bill from Eversource"',
    timestamp: hoursAgo(2),
    read: true,
  },
  {
    id: 'activity-005',
    type: 'WORK_ORDER_COMPLETED',
    householdId: 'household-russo-001',
    householdName: 'Russo',
    description: 'Work order completed - Generator maintenance',
    timestamp: daysAgo(1),
    read: true,
  },
  {
    id: 'activity-006',
    type: 'PAYMENT_PROCESSED',
    householdId: 'household-fitzgerald-001',
    householdName: 'Fitzgerald',
    description: 'December statement paid - $6,250.00',
    timestamp: daysAgo(2),
    read: true,
  },
  {
    id: 'activity-007',
    type: 'MESSAGE_RECEIVED',
    householdId: 'household-chenwilliams-001',
    householdName: 'Chen-Williams',
    description: 'New message from Amanda Chen',
    timestamp: daysAgo(2),
    read: true,
  },
];

// ============================================================================
// DEMO LOGIN ACCOUNTS
// ============================================================================

export const DEMO_ACCOUNTS = [
  {
    type: 'homeowner' as const,
    label: 'Demo Homeowner',
    email: 'james@morrison.family',
    password: 'demo1234',
    description: 'Experience the homeowner portal as James Morrison',
  },
  {
    type: 'manager' as const,
    label: 'Demo Manager',
    email: 'sarah@haven.app',
    password: 'demo1234',
    description: 'Experience the manager portal as Sarah Chen',
  },
];

// ============================================================================
// PERFORMANCE DATA (for reports)
// ============================================================================

export const DEMO_PERFORMANCE = {
  // Monthly request volume
  requestsOverTime: [
    { month: 'Jul', value: 85 },
    { month: 'Aug', value: 92 },
    { month: 'Sep', value: 78 },
    { month: 'Oct', value: 110 },
    { month: 'Nov', value: 118 },
    { month: 'Dec', value: 127 },
  ],

  // Response time trend (hours)
  responseTimeTrend: [
    { month: 'October', value: 3.2 },
    { month: 'November', value: 2.8 },
    { month: 'December', value: 2.3 },
  ],

  // Bills by category (percentage)
  billsByCategory: [
    { category: 'Housing', value: 42, color: 'bg-indigo-500' },
    { category: 'Utilities', value: 18, color: 'bg-blue-500' },
    { category: 'Insurance', value: 12, color: 'bg-emerald-500' },
    { category: 'Auto', value: 15, color: 'bg-amber-500' },
    { category: 'Services', value: 13, color: 'bg-purple-500' },
  ],

  // Task completion
  taskCompletion: {
    completed: 108,
    inProgress: 12,
    pending: 7,
    percentage: 85,
  },

  // Satisfaction ratings
  satisfactionRatings: [
    { household: 'Morrison', rating: 4.9 },
    { household: 'Chen-Williams', rating: 4.8 },
    { household: 'Patel', rating: 4.7 },
    { household: 'Fitzgerald', rating: 5.0 },
    { household: 'Nakamura', rating: 4.8 },
    { household: 'Russo', rating: 4.9 },
  ],
};
