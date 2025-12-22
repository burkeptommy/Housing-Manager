// ============================================================================
// DEMO MANAGER DATA
// ============================================================================
// Manager profile and settings for the Haven Manager Portal demo

import type { Manager, Handyman, Vendor, ScheduleEvent, ActivityItem } from './types';
import { daysAgo, hoursAgo, minutesAgo, daysFromNow, todayAt, parseDate } from './utils';

// ============================================================================
// DEMO MANAGER
// ============================================================================

export const DEMO_MANAGER: Manager = {
  id: 'manager-sarah-001',
  email: 'sarah@haven.app',
  firstName: 'Sarah',
  lastName: 'Harrison',
  displayName: 'Sarah Harrison',
  role: 'MANAGER',
  avatar: '/avatars/sarah-harrison.jpg',
  phone: '(512) 555-0100',
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
    lastName: 'Rodriguez',
    displayName: 'Mike Rodriguez',
    phone: '(512) 555-0199',
    email: 'mike.r@haven.app',
    role: 'PRIMARY',
    serviceArea: 'Austin Metro',
    status: 'ON_JOB',
    currentLocation: {
      householdId: 'household-smith-001',
      checkedInAt: minutesAgo(35),
      taskDescription: 'Kitchen faucet repair',
    },
    schedule: [
      { date: new Date(), householdId: 'household-smith-001', time: '9:00 AM', task: 'Faucet repair', status: 'IN_PROGRESS' },
      { date: new Date(), householdId: 'household-johnson-001', time: '11:00 AM', task: 'Garage door lubrication', status: 'SCHEDULED' },
      { date: new Date(), householdId: 'household-miller-001', time: '2:00 PM', task: 'Monthly maintenance round', status: 'SCHEDULED' },
    ],
    specialties: ['Plumbing', 'General repairs', 'Painting', 'Drywall'],
    rating: 4.9,
    jobsCompleted: 234,
  },
  {
    id: 'handyman-carlos-001',
    firstName: 'Carlos',
    lastName: 'Martinez',
    displayName: 'Carlos Martinez',
    phone: '(512) 555-0198',
    email: 'carlos.m@haven.app',
    role: 'BACKUP',
    serviceArea: 'North Austin',
    status: 'OFF_DUTY',
    nextAvailable: daysFromNow(1),
    schedule: [],
    specialties: ['Electrical', 'Smart Home', 'Security Systems'],
    rating: 4.8,
    jobsCompleted: 156,
  },
];

// ============================================================================
// DEMO VENDORS
// ============================================================================

export const DEMO_VENDORS: Vendor[] = [
  {
    id: 'vendor-airflow-001',
    name: 'AirFlow HVAC',
    category: 'HVAC',
    contact: {
      name: 'John Davis',
      phone: '(512) 555-HVAC',
      email: 'service@airflowhvac.com',
    },
    address: '5678 Industrial Blvd, Austin, TX',
    serviceArea: ['Austin', 'Round Rock', 'Cedar Park', 'West Lake Hills'],
    rating: 4.8,
    totalJobs: 89,
    totalBilled: 24500,
    priceRange: '$$',
    responseTime: 'Same day',
    services: [
      { name: 'Service call', price: 75 },
      { name: 'Annual maintenance', price: 150 },
      { name: 'AC repair', priceRange: '$100-500' },
    ],
    notes: 'Very reliable. John is our go-to tech.',
    documents: {
      insurance: { expiry: parseDate('2025-06-15') },
      license: 'HVAC-12345',
      w9: true,
    },
  },
  {
    id: 'vendor-mikesplumbing-001',
    name: "Mike's Plumbing Pro",
    category: 'PLUMBING',
    contact: {
      name: 'Mike Chen',
      phone: '(512) 555-PLMB',
      email: 'mike@mikesplumbing.com',
    },
    rating: 4.9,
    totalJobs: 127,
    totalBilled: 42000,
    priceRange: '$$',
    responseTime: '2-4 hours',
    services: [
      { name: 'Service call', price: 75 },
      { name: 'Faucet replacement', priceRange: '$150-300' },
      { name: 'Water heater install', priceRange: '$800-1200' },
    ],
    notes: "Fair quotes, doesn't upsell. Prefers morning appointments.",
  },
  {
    id: 'vendor-aceroofing-001',
    name: 'Ace Roofing',
    category: 'ROOFING',
    contact: {
      name: 'Tom Wilson',
      phone: '(512) 555-ROOF',
    },
    rating: 4.7,
    totalJobs: 23,
    totalBilled: 45000,
    priceRange: '$$',
    responseTime: '1-2 days',
    services: [
      { name: 'Inspection', price: 150 },
      { name: 'Shingle repair', priceRange: '$300-1500' },
      { name: 'Full replacement', priceRange: '$8000-15000' },
    ],
    notes: 'Quality work, competitive pricing. Used for Johnson roof repair.',
  },
  {
    id: 'vendor-topnotch-001',
    name: 'TopNotch Roofing',
    category: 'ROOFING',
    contact: {
      name: 'Dave Brown',
      phone: '(512) 555-TOPS',
    },
    rating: 4.5,
    totalJobs: 12,
    totalBilled: 28000,
    priceRange: '$$$',
    responseTime: '2-3 days',
  },
  {
    id: 'vendor-sparkelectric-001',
    name: 'Spark Electric',
    category: 'ELECTRICAL',
    contact: {
      name: 'Tom Anderson',
      phone: '(512) 555-ZAPS',
      email: 'service@sparkelectric.com',
    },
    rating: 4.9,
    totalJobs: 45,
    totalBilled: 18500,
    priceRange: '$$',
    responseTime: 'Same day',
    services: [
      { name: 'Service call', price: 85 },
      { name: 'Panel inspection', price: 150 },
      { name: 'Panel upgrade', priceRange: '$1500-3500' },
    ],
    notes: 'Licensed master electrician. Fast and professional.',
  },
  {
    id: 'vendor-crystalclear-001',
    name: 'Crystal Clear Pools',
    category: 'POOL',
    contact: {
      name: 'Maria Garcia',
      phone: '(512) 555-POOL',
    },
    rating: 4.8,
    totalJobs: 156,
    totalBilled: 35000,
    priceRange: '$$',
    responseTime: 'Next day',
    services: [
      { name: 'Weekly service', price: 125 },
      { name: 'Equipment repair', priceRange: '$100-500' },
      { name: 'Acid wash', price: 450 },
    ],
    notes: 'Handles Smith and Williams pool service.',
  },
  {
    id: 'vendor-greenthumb-001',
    name: 'Green Thumb Landscaping',
    category: 'LANDSCAPING',
    contact: {
      name: 'Jose Martinez',
      phone: '(512) 555-LAWN',
    },
    rating: 4.6,
    totalJobs: 234,
    totalBilled: 52000,
    priceRange: '$',
    responseTime: 'Weekly schedule',
    services: [
      { name: 'Weekly mowing', price: 75 },
      { name: 'Tree trimming', priceRange: '$150-500' },
      { name: 'Seasonal cleanup', price: 250 },
    ],
  },
  {
    id: 'vendor-terminix-001',
    name: 'Terminix',
    category: 'PEST_CONTROL',
    contact: {
      name: 'Customer Service',
      phone: '(512) 555-PEST',
    },
    rating: 4.4,
    totalJobs: 48,
    totalBilled: 8500,
    priceRange: '$$',
    responseTime: '1-2 days',
    services: [
      { name: 'Quarterly treatment', price: 65 },
      { name: 'Termite inspection', price: 150 },
    ],
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
    title: 'Smith - HVAC Tech Visit',
    householdId: 'household-smith-001',
    workOrderId: 'wo-smith-001',
    vendorName: 'AirFlow HVAC',
    startTime: todayAt(9, 0).getTime(),
    duration: 120,
    address: '456 Oak Lane',
    accessNotes: 'Gate: 1247, Dog Max is friendly',
  },
  {
    id: 'event-003',
    type: 'CALL_BLOCK',
    title: 'Call Block - Follow-ups',
    description: 'Johnson: driveway quote, Williams: camp research, Chen: travel',
    startTime: todayAt(11, 0).getTime(),
    duration: 60,
    calls: [
      { householdId: 'household-johnson-001', topic: 'Driveway quote decision' },
      { householdId: 'household-williams-001', topic: 'Summer camp research update' },
      { householdId: 'household-chen-001', topic: 'Travel itinerary approval' },
    ],
  },
  {
    id: 'event-004',
    type: 'BILL_PAY',
    title: 'Bill Pay Block',
    description: '12 bills due this week across households ($12,847 total)',
    startTime: todayAt(13, 0).getTime(),
    duration: 60,
  },
  {
    id: 'event-005',
    type: 'SITE_VISIT',
    title: 'Miller - Handyman Monthly Check',
    householdId: 'household-miller-001',
    handymanId: 'handyman-mike-001',
    startTime: todayAt(14, 0).getTime(),
    duration: 90,
    address: '123 Pine Street',
    tasks: ['Filter change', 'Smoke detectors', 'Deck inspection'],
  },
];

// ============================================================================
// DEMO ACTIVITY FEED
// ============================================================================

export const DEMO_ACTIVITY: ActivityItem[] = [
  {
    id: 'activity-001',
    type: 'REQUEST_SUBMITTED',
    householdId: 'household-smith-001',
    householdName: 'Smith',
    description: 'Bob submitted new request "Kitchen faucet drip"',
    timestamp: minutesAgo(2),
    read: false,
  },
  {
    id: 'activity-002',
    type: 'APPROVAL_RECEIVED',
    householdId: 'household-johnson-001',
    householdName: 'Johnson',
    description: 'Approved roof repair ($1,200)',
    timestamp: minutesAgo(15),
    read: false,
  },
  {
    id: 'activity-003',
    type: 'HANDYMAN_CHECKIN',
    householdId: 'household-smith-001',
    householdName: 'Smith',
    description: 'Handyman Mike checked in at property',
    timestamp: hoursAgo(1),
    read: true,
  },
  {
    id: 'activity-004',
    type: 'EMAIL_FORWARDED',
    householdId: 'household-chen-001',
    householdName: 'Chen',
    description: 'Forwarded email - "Utility bill from ConEd"',
    timestamp: hoursAgo(2),
    read: true,
  },
  {
    id: 'activity-005',
    type: 'WORK_ORDER_COMPLETED',
    householdId: 'household-davis-001',
    householdName: 'Davis',
    description: 'Work order completed - Garage door repair',
    timestamp: daysAgo(1),
    read: true,
  },
  {
    id: 'activity-006',
    type: 'PAYMENT_PROCESSED',
    householdId: 'household-williams-001',
    householdName: 'Williams',
    description: 'December statement paid - $4,850.00',
    timestamp: daysAgo(2),
    read: true,
  },
  {
    id: 'activity-007',
    type: 'MESSAGE_RECEIVED',
    householdId: 'household-miller-001',
    householdName: 'Miller',
    description: 'New message from Lisa Miller',
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
    email: 'bob@smith.family',
    password: 'demo1234',
    description: 'Experience the homeowner portal as Bob Smith',
  },
  {
    type: 'manager' as const,
    label: 'Demo Manager',
    email: 'sarah@haven.app',
    password: 'demo1234',
    description: 'Experience the manager portal as Sarah Harrison',
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
    { household: 'Smith', rating: 4.9 },
    { household: 'Johnson', rating: 4.7 },
    { household: 'Miller', rating: 4.5 },
    { household: 'Williams', rating: 5.0 },
    { household: 'Chen', rating: 4.8 },
    { household: 'Davis', rating: 4.9 },
  ],
};
