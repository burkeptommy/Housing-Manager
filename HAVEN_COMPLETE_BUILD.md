# 🏠 HAVEN PLATFORM - COMPLETE BUILD MEGA-PROMPT

## HOW TO RUN THIS BUILD

```bash
# Navigate to project
cd /Users/tomburke/Projects/Housing-Manager

# Run Claude Code without permission prompts (auto-approve everything)
claude --dangerously-skip-permissions

# Then paste this entire prompt, or run with file:
claude --dangerously-skip-permissions -p "$(cat HAVEN_COMPLETE_BUILD.md)"
```

**⚠️ The `--dangerously-skip-permissions` flag auto-approves all file edits and commands. Only use in trusted projects.**

---

## MISSION STATEMENT

Build a complete, production-ready home management platform that democratizes luxury estate management services. Every wealthy family has a house manager who handles their bills, coordinates repairs, plans travel, and manages vendors. Haven brings this service to everyone.

**This build must result in:**
- ✅ Every page working with REAL data (no mock data in production)
- ✅ All 4 portals functional (Homeowner, Manager, Handyman, Vendor)
- ✅ Bidirectional messaging between all parties
- ✅ Complete travel planning workflow
- ✅ Full bill pay and financial management
- ✅ Work order lifecycle from request → completion → verification → payment
- ✅ Demo data that tells a cohesive story

---

## DEMO CREDENTIALS (After Seed)

| Role | Name | Email | Password | Portal |
|------|------|-------|----------|--------|
| Admin | Platform Admin | admin@haven.app | Admin123! | /admin |
| **Manager** | **Sarah Harrison** | **sarah@haven.app** | **Manager123!** | **/manager** |
| Homeowner | Bob Smith | bob@example.com | Bob123! | /app |
| Homeowner | Alice Johnson | alice@example.com | Alice123! | /app |
| **Handyman** | **Mike Rodriguez** | **mike@haven.app** | **Handy123!** | **/handyman** |
| Handyman | Carlos Reyes | carlos@haven.app | Handy123! | /handyman |
| Handyman | Maria Santos | maria@haven.app | Handy123! | /handyman |
| Vendor | Ace Roofing | vendor@aceroofing.example.com | AceRoof123! | /vendor |

---

## PHASE 0: CRITICAL FIXES (DO THESE FIRST)

### TASK 0.1: Fix Manager Portal Navigation

The manager layout links to `/manager/schedule` but the page is at `/manager/calendar`.

**File:** `apps/web/src/app/manager/layout.tsx`

**Find (around line 35):**
```typescript
{ label: 'Schedule', href: '/manager/schedule', icon: Calendar },
```

**Replace with:**
```typescript
{ label: 'Schedule', href: '/manager/calendar', icon: Calendar },
```

---

### TASK 0.2: Update Seed File - Replace Steve→Sarah, Dave→Mike

**File:** `apps/api/prisma/seed.ts`

This is a comprehensive find-and-replace task. Make these changes throughout the ENTIRE file:

**1. Manager User Creation (around line 609-625):**

Find:
```typescript
const managerSteve = await prisma.user.upsert({
  where: { email: 'steve@haven.app' },
  update: {},
  create: {
    email: 'steve@haven.app',
    passwordHash: managerPassword,
    firstName: 'Steve',
    lastName: 'Manager',
    displayName: 'Manager Steve',
```

Replace with:
```typescript
const managerSarah = await prisma.user.upsert({
  where: { email: 'sarah@haven.app' },
  update: {},
  create: {
    email: 'sarah@haven.app',
    passwordHash: managerPassword,
    firstName: 'Sarah',
    lastName: 'Harrison',
    displayName: 'Sarah Harrison',
```

**2. Handyman User Creation (around line 641-658):**

Find:
```typescript
const handymanDave = await prisma.user.upsert({
  where: { email: 'dave@haven.app' },
  update: {},
  create: {
    email: 'dave@haven.app',
    passwordHash: handymanPassword,
    firstName: 'Mike',
    lastName: 'Castellano',
    displayName: 'Mike Castellano',
```

Replace with:
```typescript
const handymanMike = await prisma.user.upsert({
  where: { email: 'mike@haven.app' },
  update: {},
  create: {
    email: 'mike@haven.app',
    passwordHash: handymanPassword,
    firstName: 'Mike',
    lastName: 'Rodriguez',
    displayName: 'Mike Rodriguez',
```

**3. Global Variable Replacements (entire file):**

Use find-and-replace for these patterns:
- `managerSteve` → `managerSarah` (all occurrences, ~20+)
- `handymanDave` → `handymanMike` (all occurrences, ~10+)
- `steve@haven.app` → `sarah@haven.app` (in strings)
- `dave@haven.app` → `mike@haven.app` (in strings)
- `Steve Manager` → `Sarah Harrison` (in strings)
- `Manager Steve` → `Sarah Harrison` (in strings)
- `Dave Wilson` → `Mike Rodriguez` (in strings)
- `Mike Castellano` → `Mike Rodriguez` (in strings)

**4. Update Console Output Section (end of file, ~line 1100+):**

Update all the credential output to show correct names and emails.

---

### TASK 0.3: Update Firebase Users Script

**File:** `apps/api/scripts/seed-firebase-users.ts`

Apply the same name/email changes if this file references Steve/Dave.

---

### TASK 0.4: Update Frontend Mock Data References

**Files to update:**

**`apps/web/src/app/app/messages/page.tsx`** - Find the mockParticipants or HOUSING_MANAGER and update:
```typescript
const HOUSING_MANAGER = {
  id: 'sarah-manager',
  name: 'Sarah Harrison',
  title: 'Home Manager',
  avatar: getDemoImage('avatar-female', 100, 100, 'sarah-manager'),
  phone: '+1 (203) 555-0100',
};
```

**`apps/web/src/app/app/requests/page.tsx`** - Same update for HOUSING_MANAGER constant.

Search for any other files containing "Steve" that should be "Sarah".

---

## PHASE 1: COMPREHENSIVE SEED DATA

Add this to `apps/api/prisma/seed.ts` AFTER the existing work orders section but BEFORE the final console.log output:

### TASK 1.1: Add Travel Concierge Demo Data

```typescript
// ============================================================================
// TRAVEL CONCIERGE DEMO DATA
// ============================================================================

console.log('');
console.log('✈️  Setting up Travel Concierge demo data...');

// Helper functions for dates
const daysFromNow = (days: number) => new Date(Date.now() + days * 24 * 60 * 60 * 1000);
const daysAgo = (days: number) => new Date(Date.now() - days * 24 * 60 * 60 * 1000);

// Create travel profile for Bob
await prisma.travelProfile.upsert({
  where: { id: 'travel-profile-bob' },
  update: {},
  create: {
    id: 'travel-profile-bob',
    memberId: homeownerBob.id,
    householdMemberId: demoHousehold.id,
    tsaPrecheck: '123456789',
    globalEntry: 'GE987654321',
    passportNumber: 'P12345678',
    passportExpiry: new Date('2028-06-15'),
    passportCountry: 'US',
    seatPreference: 'AISLE',
    mealPreference: 'No preference',
    frequentFlyerPrograms: JSON.stringify([
      { airline: 'United', number: 'MP123456789', tier: 'Premier Gold' },
      { airline: 'Delta', number: 'DL987654321', tier: 'Silver Medallion' },
    ]),
    hotelLoyaltyPrograms: JSON.stringify([
      { chain: 'Marriott Bonvoy', number: 'MB111222333', tier: 'Gold' },
      { chain: 'Hilton Honors', number: 'HH444555666', tier: 'Silver' },
    ]),
    travelStyle: 'Luxury',
    specialRequests: 'Prefer high floors, quiet rooms away from elevator',
  },
});
console.log('  ✓ Created travel profile for Bob');

// Trip 1: BOOKED - Ski trip departing in 30 days
const skiTrip = await prisma.trip.create({
  data: {
    householdId: demoHousehold.id,
    createdByUserId: homeownerBob.id,
    assignedManagerId: managerSarah.id,
    destination: 'Aspen, Colorado',
    startDate: daysFromNow(30),
    endDate: daysFromNow(37),
    travelerCount: 2,
    travelerDetails: JSON.stringify([
      { name: 'Bob Smith', type: 'adult' },
      { name: 'Alice Smith', type: 'adult' },
    ]),
    purpose: 'Ski vacation - 10th anniversary trip',
    budgetMin: 8000,
    budgetMax: 15000,
    flexibility: 'Dates are fixed (anniversary)',
    flightPreferences: JSON.stringify({
      cabin: 'Business',
      directOnly: true,
      preferredAirlines: ['United', 'American'],
    }),
    stayPreferences: JSON.stringify({
      type: 'Hotel',
      starRating: 5,
      amenities: ['Ski-in/Ski-out', 'Spa', 'Fine Dining'],
    }),
    notes: 'This is our 10th anniversary trip. Would love a room with mountain views. We are intermediate skiers.',
    status: 'BOOKED',
  },
});

// Itinerary items for ski trip
await prisma.itineraryItem.createMany({
  data: [
    {
      tripId: skiTrip.id,
      type: 'FLIGHT',
      title: 'Outbound Flight - EWR to ASE',
      date: daysFromNow(30),
      startTime: '08:30',
      endTime: '12:45',
      location: 'Newark Liberty International Airport',
      confirmationNumber: 'UA789456',
      details: JSON.stringify({
        airline: 'United Airlines',
        flightNumber: 'UA 1847',
        class: 'Business',
        seats: '2A, 2B',
        terminal: 'C',
        gate: 'C88',
      }),
      cost: 2400,
      sortOrder: 1,
    },
    {
      tripId: skiTrip.id,
      type: 'TRANSFER',
      title: 'Airport Transfer - ASE to Hotel',
      date: daysFromNow(30),
      startTime: '13:00',
      endTime: '13:30',
      location: 'Aspen/Pitkin County Airport',
      confirmationNumber: 'ASPEN-TR-001',
      details: JSON.stringify({
        provider: 'Little Nell Car Service',
        vehicleType: 'Luxury SUV',
        driverContact: '+1 970-555-0100',
      }),
      cost: 150,
      sortOrder: 2,
    },
    {
      tripId: skiTrip.id,
      type: 'STAY',
      title: 'The Little Nell - 7 Nights',
      date: daysFromNow(30),
      location: '675 E Durant Ave, Aspen, CO 81611',
      confirmationNumber: 'LN-2024-78945',
      details: JSON.stringify({
        roomType: 'Premier King Room - Mountain View',
        checkIn: '3:00 PM',
        checkOut: '11:00 AM',
        amenities: ['Ski Valet', 'Spa Access', 'Restaurant Reservations', 'Fireplace'],
        specialNotes: 'Anniversary package - champagne and chocolates on arrival',
      }),
      cost: 8500,
      sortOrder: 3,
    },
    {
      tripId: skiTrip.id,
      type: 'ACTIVITY',
      title: 'Private Ski Lesson',
      date: daysFromNow(31),
      startTime: '09:00',
      endTime: '12:00',
      location: 'Aspen Mountain Ski School',
      confirmationNumber: 'SKI-LESSON-001',
      details: JSON.stringify({
        instructor: 'TBD - Advanced certified',
        level: 'Intermediate refresher',
        equipment: 'Included',
      }),
      cost: 600,
      sortOrder: 4,
    },
    {
      tripId: skiTrip.id,
      type: 'ACTIVITY',
      title: 'Anniversary Dinner - Element 47',
      date: daysFromNow(33),
      startTime: '19:00',
      endTime: '22:00',
      location: 'Element 47 at The Little Nell',
      confirmationNumber: 'E47-RES-2024',
      details: JSON.stringify({
        partySize: 2,
        tableRequest: 'Window with mountain view',
        specialOccasion: '10th Anniversary',
      }),
      cost: 500,
      sortOrder: 5,
    },
    {
      tripId: skiTrip.id,
      type: 'FLIGHT',
      title: 'Return Flight - ASE to EWR',
      date: daysFromNow(37),
      startTime: '14:00',
      endTime: '20:30',
      location: 'Aspen/Pitkin County Airport',
      confirmationNumber: 'UA789457',
      details: JSON.stringify({
        airline: 'United Airlines',
        flightNumber: 'UA 1848',
        class: 'Business',
        seats: '3A, 3B',
      }),
      cost: 2200,
      sortOrder: 10,
    },
  ],
});
console.log('  ✓ Created ski trip to Aspen (BOOKED) with full itinerary');

// Trip 2: INQUIRY - Spring break (unassigned, needs manager attention)
const springBreakTrip = await prisma.trip.create({
  data: {
    householdId: demoHousehold.id,
    createdByUserId: homeownerBob.id,
    destination: 'Turks and Caicos',
    startDate: daysFromNow(90),
    endDate: daysFromNow(97),
    travelerCount: 4,
    travelerDetails: JSON.stringify([
      { name: 'Bob Smith', type: 'adult' },
      { name: 'Alice Smith', type: 'adult' },
      { name: 'Emma Smith', type: 'child', age: 14 },
      { name: 'Jack Smith', type: 'child', age: 10 },
    ]),
    purpose: 'Spring break family vacation',
    budgetMin: 15000,
    budgetMax: 25000,
    flexibility: 'Flexible by a few days either direction',
    flightPreferences: JSON.stringify({
      cabin: 'First',
      directOnly: false,
      preferredAirlines: ['JetBlue', 'American'],
    }),
    stayPreferences: JSON.stringify({
      type: 'Villa',
      bedrooms: 3,
      amenities: ['Private Pool', 'Beach Access', 'Full Kitchen', 'Kid-Friendly'],
    }),
    notes: 'Kids want snorkeling and beach time. Adults want spa and fine dining options. Emma is certified PADI Open Water diver.',
    status: 'INQUIRY',
  },
});
console.log('  ✓ Created spring break inquiry (INQUIRY - unassigned)');

// Trip 3: PROPOSAL_SENT - Business trip awaiting selection
const businessTrip = await prisma.trip.create({
  data: {
    householdId: demoHousehold.id,
    createdByUserId: homeownerBob.id,
    assignedManagerId: managerSarah.id,
    destination: 'San Francisco, CA',
    startDate: daysFromNow(14),
    endDate: daysFromNow(16),
    travelerCount: 1,
    travelerDetails: JSON.stringify([
      { name: 'Bob Smith', type: 'adult' },
    ]),
    purpose: 'Business meetings with tech partners',
    budgetMin: 2000,
    budgetMax: 4000,
    flexibility: 'None - meetings are confirmed',
    flightPreferences: JSON.stringify({
      cabin: 'Business',
      directOnly: true,
      preferredAirlines: ['United'],
    }),
    stayPreferences: JSON.stringify({
      type: 'Hotel',
      starRating: 4,
      location: 'Downtown/Financial District',
      amenities: ['Fitness Center', 'Business Center'],
    }),
    notes: 'Meetings at 10am and 3pm on day 2. Need reliable wifi.',
    status: 'PROPOSAL_SENT',
  },
});

// Create proposal for SF trip
await prisma.tripProposal.create({
  data: {
    tripId: businessTrip.id,
    createdByUserId: managerSarah.id,
    type: 'FLIGHT',
    title: 'Flight Options - EWR to SFO',
    description: 'Here are the best direct flight options for your business trip. I recommend the morning flight to give you time to settle in before dinner.',
    options: JSON.stringify([
      {
        name: 'United UA 2045 - Morning Departure',
        details: 'Depart 7:00 AM, Arrive 10:30 AM PST (Business Class)',
        price: 1200,
        recommended: true,
        pros: ['Direct flight', 'Early arrival - full day available', 'Lie-flat seats for rest'],
        cons: ['Requires early wake-up (leave home by 5am)'],
      },
      {
        name: 'United UA 2089 - Midday Departure',
        details: 'Depart 12:00 PM, Arrive 3:30 PM PST (Business Class)',
        price: 1350,
        recommended: false,
        pros: ['More relaxed morning', 'Direct flight'],
        cons: ['Arrives late afternoon - tight for dinner plans'],
      },
    ]),
    status: 'PENDING',
    sentAt: new Date(),
  },
});

await prisma.tripProposal.create({
  data: {
    tripId: businessTrip.id,
    createdByUserId: managerSarah.id,
    type: 'STAY',
    title: 'Hotel Options - San Francisco',
    description: 'All options are in the Financial District, walking distance to your meeting locations.',
    options: JSON.stringify([
      {
        name: 'Four Seasons San Francisco',
        details: '2 nights, Deluxe King Room, Club Level Access',
        price: 1100,
        recommended: true,
        pros: ['Exceptional service', 'Club lounge for quiet work', 'Best location'],
        cons: ['Slightly over mid-budget'],
      },
      {
        name: 'St. Regis San Francisco',
        details: '2 nights, Superior King Room',
        price: 950,
        recommended: false,
        pros: ['Modern amenities', 'Good fitness center', 'Butler service'],
        cons: ['Slightly further from meeting locations'],
      },
    ]),
    status: 'PENDING',
    sentAt: new Date(),
  },
});
console.log('  ✓ Created SF business trip with proposals (PROPOSAL_SENT)');

// Trip 4: COMPLETED - Past trip for history
await prisma.trip.create({
  data: {
    householdId: demoHousehold.id,
    createdByUserId: homeownerBob.id,
    assignedManagerId: managerSarah.id,
    destination: 'Napa Valley, CA',
    startDate: daysAgo(30),
    endDate: daysAgo(26),
    travelerCount: 2,
    travelerDetails: JSON.stringify([
      { name: 'Bob Smith', type: 'adult' },
      { name: 'Alice Smith', type: 'adult' },
    ]),
    purpose: 'Wine tasting weekend getaway',
    budgetMin: 5000,
    budgetMax: 8000,
    status: 'COMPLETED',
  },
});
console.log('  ✓ Created Napa Valley trip (COMPLETED - history)');

// House protocol for ski trip (departure checklist)
const skiProtocol = await prisma.houseProtocol.create({
  data: {
    tripId: skiTrip.id,
    householdId: demoHousehold.id,
    type: 'DEPARTURE',
    status: 'PENDING',
    assignedToUserId: handymanMike.id,
  },
});

await prisma.houseProtocolItem.createMany({
  data: [
    {
      protocolId: skiProtocol.id,
      category: 'SECURITY',
      title: 'Set alarm system to Away mode',
      description: 'Ensure all zones are armed. Motion sensors should be active.',
      sortOrder: 1,
      status: 'PENDING',
    },
    {
      protocolId: skiProtocol.id,
      category: 'SECURITY',
      title: 'Lock all doors and windows',
      description: 'Check front, back, garage, all first-floor windows, basement',
      sortOrder: 2,
      status: 'PENDING',
    },
    {
      protocolId: skiProtocol.id,
      category: 'UTILITIES',
      title: 'Set thermostat to vacation mode (60°F)',
      description: 'Lower heating to save energy but prevent pipe freezing',
      sortOrder: 3,
      status: 'PENDING',
    },
    {
      protocolId: skiProtocol.id,
      category: 'MAIL',
      title: 'Hold mail delivery',
      description: 'USPS hold request submitted',
      sortOrder: 4,
      status: 'COMPLETED',
      completedAt: new Date(),
      completedByUserId: managerSarah.id,
    },
    {
      protocolId: skiProtocol.id,
      category: 'OUTDOOR',
      title: 'Notify landscaper of absence',
      description: 'Snow removal as needed during trip',
      sortOrder: 5,
      status: 'COMPLETED',
      completedAt: new Date(),
      completedByUserId: managerSarah.id,
    },
    {
      protocolId: skiProtocol.id,
      category: 'PETS',
      title: 'Confirm pet boarding',
      description: 'Max to Paws & Claws on departure morning',
      sortOrder: 6,
      status: 'PENDING',
    },
  ],
});
console.log('  ✓ Created house departure protocol for ski trip');
```

### TASK 1.2: Add Conversation Demo Data

```typescript
// ============================================================================
// CONVERSATION DEMO DATA
// ============================================================================

console.log('');
console.log('💬 Setting up Conversation demo data...');

// Clear existing for clean state
await prisma.supportMessage.deleteMany({
  where: { conversation: { householdId: demoHousehold.id } },
});
await prisma.conversation.deleteMany({
  where: { householdId: demoHousehold.id },
});

// Conversation 1: Trip planning (OPEN)
const tripConvo = await prisma.conversation.create({
  data: {
    householdId: demoHousehold.id,
    createdByUserId: homeownerBob.id,
    subject: 'Aspen Ski Trip Planning',
    status: 'OPEN',
    homeManagerUnreadCount: 0,
    homeownerUnreadCount: 1,
  },
});

await prisma.supportMessage.createMany({
  data: [
    {
      conversationId: tripConvo.id,
      senderUserId: homeownerBob.id,
      senderRole: 'HOMEOWNER',
      body: 'Hi Sarah! We are so excited about the Aspen trip. Is the Little Nell reservation confirmed?',
      createdAt: daysAgo(2),
    },
    {
      conversationId: tripConvo.id,
      senderUserId: managerSarah.id,
      senderRole: 'HOME_MANAGER',
      body: 'Hi Bob! Yes, everything is confirmed! Your room upgrade to Mountain View went through. I\'ll send confirmation documents shortly.',
      createdAt: new Date(daysAgo(2).getTime() + 32 * 60 * 1000),
    },
    {
      conversationId: tripConvo.id,
      senderUserId: managerSarah.id,
      senderRole: 'HOME_MANAGER',
      body: 'I\'ve also arranged ski rentals at Four Mountain Sports. Would you like me to book any restaurant reservations?',
      createdAt: daysAgo(1),
    },
  ],
});
console.log('  ✓ Created trip planning conversation');

// Conversation 2: Maintenance (RESOLVED)
const maintenanceConvo = await prisma.conversation.create({
  data: {
    householdId: demoHousehold.id,
    createdByUserId: homeownerBob.id,
    subject: 'Kitchen Faucet Dripping',
    status: 'RESOLVED',
    homeManagerUnreadCount: 0,
    homeownerUnreadCount: 0,
  },
});

await prisma.supportMessage.createMany({
  data: [
    {
      conversationId: maintenanceConvo.id,
      senderUserId: homeownerBob.id,
      senderRole: 'HOMEOWNER',
      body: 'Hey Sarah, the kitchen faucet is dripping again. Can Mike take a look?',
      createdAt: daysAgo(5),
    },
    {
      conversationId: maintenanceConvo.id,
      senderUserId: managerSarah.id,
      senderRole: 'HOME_MANAGER',
      body: 'Of course! Added to Mike\'s Thursday list. Probably just needs a new cartridge.',
      createdAt: new Date(daysAgo(5).getTime() + 45 * 60 * 1000),
    },
    {
      conversationId: maintenanceConvo.id,
      senderUserId: managerSarah.id,
      senderRole: 'HOME_MANAGER',
      body: '✅ All fixed! Mike replaced the cartridge. No charge - covered under monthly visit.',
      createdAt: daysAgo(3),
    },
    {
      conversationId: maintenanceConvo.id,
      senderUserId: homeownerBob.id,
      senderRole: 'HOMEOWNER',
      body: 'You guys are the best! Thanks so much.',
      createdAt: new Date(daysAgo(3).getTime() + 2 * 60 * 60 * 1000),
    },
  ],
});
console.log('  ✓ Created maintenance conversation');

// Conversation 3: Bill question (OPEN - unread for Sarah)
const billConvo = await prisma.conversation.create({
  data: {
    householdId: demoHousehold.id,
    createdByUserId: homeownerBob.id,
    subject: 'Question about December electric bill',
    status: 'OPEN',
    homeManagerUnreadCount: 1,
    homeownerUnreadCount: 0,
  },
});

await prisma.supportMessage.createMany({
  data: [
    {
      conversationId: billConvo.id,
      senderUserId: homeownerBob.id,
      senderRole: 'HOMEOWNER',
      body: 'Sarah, the electric bill seems $150 higher than last December. Is that normal?',
      createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    },
  ],
});
console.log('  ✓ Created bill question conversation');
```

### TASK 1.3: Add Work Orders for All Portals

```typescript
// ============================================================================
// WORK ORDERS FOR ALL PORTALS
// ============================================================================

console.log('');
console.log('🔧 Setting up Work Order demo data...');

const today = new Date();
today.setHours(0, 0, 0, 0);

// Mike's work orders
const mikeWorkOrders = [
  {
    householdId: demoHousehold.id,
    createdByUserId: managerSarah.id,
    handymanId: handymanMike.id,
    title: 'Replace smoke detector batteries',
    description: 'Replace batteries in all 6 smoke detectors.',
    status: 'ASSIGNED',
    isConciergeRequest: true,
    billingType: 'INCLUSIVE',
    scheduledStart: new Date(today.getTime() + 9 * 60 * 60 * 1000),
    scheduledEnd: new Date(today.getTime() + 10 * 60 * 60 * 1000),
    estimatedCost: 0,
    serviceArea: 'Greenwich',
  },
  {
    householdId: demoHousehold.id,
    createdByUserId: managerSarah.id,
    handymanId: handymanMike.id,
    title: 'Fix squeaky door - master bedroom',
    description: 'Door squeaks when opening. Try WD-40 first.',
    status: 'ASSIGNED',
    isConciergeRequest: true,
    billingType: 'INCLUSIVE',
    scheduledStart: new Date(today.getTime() + 10.5 * 60 * 60 * 1000),
    scheduledEnd: new Date(today.getTime() + 11 * 60 * 60 * 1000),
    estimatedCost: 0,
    serviceArea: 'Greenwich',
  },
  {
    householdId: demoHousehold.id,
    createdByUserId: managerSarah.id,
    handymanId: handymanMike.id,
    title: 'Cabinet handles - kitchen',
    description: 'Several handles are loose. Tighten all.',
    status: 'IN_PROGRESS',
    isConciergeRequest: true,
    billingType: 'INCLUSIVE',
    scheduledStart: new Date(today.getTime() + 11.5 * 60 * 60 * 1000),
    scheduledEnd: new Date(today.getTime() + 12.5 * 60 * 60 * 1000),
    checkInAt: new Date(today.getTime() + 11.5 * 60 * 60 * 1000),
    checkInLatitude: 41.0534,
    checkInLongitude: -73.5387,
    estimatedCost: 0,
    serviceArea: 'Greenwich',
  },
];

for (const wo of mikeWorkOrders) {
  await prisma.workOrder.create({ data: wo as any });
}
console.log(`  ✓ Created ${mikeWorkOrders.length} work orders for Mike`);

// Vendor work orders
let aceRoofingVendor = await prisma.vendor.findFirst({
  where: { displayName: { contains: 'Ace' } },
});

if (!aceRoofingVendor) {
  aceRoofingVendor = await prisma.vendor.create({
    data: {
      displayName: 'Ace Roofing & Repair',
      contactEmail: 'jobs@aceroofing.example.com',
      contactPhone: '(310) 555-1234',
      category: 'ROOFING',
      isActive: true,
      serviceAreas: ['Malibu', 'Beverly Hills', 'Pacific Palisades'],
    },
  });
}

const vendorWorkOrders = [
  {
    householdId: malibuMansion.id,
    createdByUserId: managerSarah.id,
    vendorId: aceRoofingVendor.id,
    title: 'Roof tile repair - storm damage',
    description: 'Clay tiles damaged in windstorm. South-facing section.',
    status: 'OPEN',
    estimatedCost: 850,
    serviceArea: 'Malibu',
    preferredDate: daysFromNow(3),
  },
  {
    householdId: beverlyHillsEstate.id,
    createdByUserId: managerSarah.id,
    vendorId: aceRoofingVendor.id,
    title: 'Annual roof inspection',
    description: 'Yearly comprehensive inspection.',
    status: 'SCHEDULED',
    scheduledStart: new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000 + 9 * 60 * 60 * 1000),
    estimatedCost: 350,
    serviceArea: 'Beverly Hills',
  },
  {
    householdId: beverlyHillsEstate.id,
    createdByUserId: managerSarah.id,
    vendorId: aceRoofingVendor.id,
    title: 'Gutter repair and cleaning',
    description: 'Fixed loose section, cleaned all gutters.',
    status: 'COMPLETED',
    scheduledStart: daysAgo(2),
    completedAt: new Date(daysAgo(2).getTime() + 3.5 * 60 * 60 * 1000),
    checkInAt: new Date(daysAgo(2).getTime() + 15 * 60 * 1000),
    checkOutAt: new Date(daysAgo(2).getTime() + 3.5 * 60 * 60 * 1000),
    estimatedCost: 425,
    actualCost: 475,
    serviceArea: 'Beverly Hills',
  },
];

for (const wo of vendorWorkOrders) {
  await prisma.workOrder.create({ data: wo as any });
}
console.log(`  ✓ Created ${vendorWorkOrders.length} work orders for Ace Roofing`);
```

### TASK 1.4: Update Console Output

Update the final console output at the end of seed.ts to show all the new data.

---

## PHASE 2: HOMEOWNER PORTAL

### TASK 2.1: Refactor Community to Vendor Discovery

**File:** `apps/web/src/app/app/community/page.tsx`

Replace with vendor discovery featuring:
- Map view with vendor markers
- Grid view option  
- Trade filter pills
- Sort by rating/neighbors/distance
- Connect to: `api.searchSocialVendors()`

### TASK 2.2: Connect Messages to Real API

**File:** `apps/web/src/app/app/messages/page.tsx`

Replace mock data with:
```typescript
const conversations = await api.getConversations();
await api.sendConversationMessage(id, { body });
```

### TASK 2.3: Update Navigation

Change "Community" to "Find Pros" in sidebar.

---

## PHASE 3: MANAGER PORTAL

### TASK 3.1: Enhance Dashboard
Connect to real APIs, show stats, today's schedule, pending items.

### TASK 3.2: Build Calendar Page  
Unified calendar with work orders, trips, bills.

### TASK 3.3: Build Payables Page
Full bill pay workflow with batch payments.

### TASK 3.4: Build Conversations Page
Two-way messaging with homeowners.

### TASK 3.5: Enhance Travel Page
Connect to real API, full trip management.

---

## PHASE 4: HANDYMAN PORTAL

### TASK 4.1: Build Dashboard
Today's tasks, route, check-in/out.

### TASK 4.2: Build Job Detail Page
Full completion workflow with photos.

### TASK 4.3: Build Schedule Page
Week view of tasks.

---

## PHASE 5: VENDOR PORTAL

### TASK 5.1: Build Dashboard
Stats, available jobs, schedule.

### TASK 5.2: Build Jobs Page
Job board with claim functionality.

### TASK 5.3: Build Job Detail Page
Claim, check-in, complete with photos.

---

## VERIFICATION

```bash
cd apps/api
pnpm prisma db push --force-reset
pnpm prisma db seed
pnpm dev

# In another terminal
cd apps/web
pnpm dev
```

Test all portals with credentials above.

---

## FEATURE CHECKLIST

- [x] Property Management
- [x] Maintenance Coordination  
- [x] Financial Administration
- [x] Staff Management
- [x] Travel Coordination
- [x] Family Operations
- [x] Communication

All features must work with REAL data.

Good luck! 🏠✨
