# HAVEN HOME MANAGEMENT PLATFORM
## Claude Code Master Prompt

**Project Location:** `/Users/tomburke/Projects/Housing-Manager`

---

## IMMEDIATE PRIORITY: FIX FDIC MESSAGING

**File:** `apps/web/src/app/page.tsx`

Haven is NOT a bank and does NOT hold customer funds. All FDIC claims are false and must be removed.

### Search and Replace These Patterns:

```
FIND: "FDIC Insured" or "FDIC-Insured"
REPLACE: "Secure Payments"

FIND: "Fund Your Haven Wallet" 
REPLACE: "Link Your Payment Method"

FIND: "Haven Wallet"
REPLACE: "your linked payment method"

FIND: FAQ answer about "Is my money safe?" containing FDIC
REPLACE: "Haven never holds your funds. When we pay your bills, charges go directly to your linked bank account or credit card through Stripe. All transactions use bank-level 256-bit encryption and are PCI compliant."
```

After fixing, run: `pnpm build`

---

## PROJECT OVERVIEW

Haven is a **full-service home management platform**. Unlike apps that give homeowners software to organize their own chaos, Haven provides **actual humans who do the work**.

**Value Prop:** "Stop managing your home. Start living in it."
**Model:** One bill. One contact. Zero hassle. SERVICE, not software.

---

## TECH STACK

```
/Users/tomburke/Projects/Housing-Manager/
├── apps/
│   ├── api/          # NestJS backend (port 4000)
│   │   ├── prisma/   # Schema + migrations + seed
│   │   └── src/      # Modules organized by domain
│   ├── mobile/       # Expo React Native
│   └── web/          # Next.js 15 App Router (port 3000)
├── packages/
│   ├── config/       # Shared ESLint, TypeScript configs
│   ├── core/         # Shared types, schemas, constants
│   └── ui/           # Shared React components
```

### Key Technologies
- **Frontend:** Next.js 15, React 18, Tailwind CSS, Radix UI
- **Mobile:** Expo SDK 50+, React Native
- **Backend:** NestJS 10, Prisma ORM, PostgreSQL
- **Auth:** JWT with refresh token rotation
- **Payments:** Stripe (Issuing, Connect, Billing)
- **Storage:** Google Cloud Storage
- **Deploy:** Google Cloud Run

---

## COMMANDS

```bash
# Install dependencies
pnpm install

# Start PostgreSQL
docker-compose up -d postgres

# Development
pnpm dev:api      # Backend at localhost:4000
pnpm dev:web      # Frontend at localhost:3000
pnpm dev:mobile   # Expo dev server

# Database
cd apps/api
pnpm prisma:migrate:dev   # Run migrations
pnpm prisma:seed          # Seed demo data
pnpm prisma:studio        # Open Prisma Studio GUI

# Build & Test
pnpm build
pnpm test
pnpm lint
```

---

## USER ROLES & PORTALS

### 1. HOMEOWNER Portal (`/app/*`)
**Demo User:** `bob@example.com` / `Bob123!`

Routes:
- `/app` - Dashboard (home overview, upcoming, activity)
- `/app/home` - Property details, systems inventory
- `/app/billing` - Bill accounts, transactions, statements
- `/app/maintenance` - Tasks, work orders, schedules
- `/app/messages` - Chat with Home Manager
- `/app/calendar` - Unified household calendar
- `/app/travel` - Trip planning, itineraries
- `/app/family` - Family members, pets, vehicles
- `/app/settings` - Profile, payment methods, notifications

### 2. MANAGER Portal (`/manager/*`)
**Demo User:** `sarah@haven.app` / `Manager123!`

Routes:
- `/manager` - Dashboard (all households overview)
- `/manager/households` - List of managed households
- `/manager/households/[id]` - Individual household detail
- `/manager/work-orders` - All work orders across households
- `/manager/conversations` - Messaging hub
- `/manager/payables` - Pending vendor payments (Batch Pay)
- `/manager/verification` - Completed work awaiting approval
- `/manager/travel` - Trip management pipeline
- `/manager/vendors` - Vendor directory
- `/manager/handymen` - Internal handyman assignments
- `/manager/calendar` - Unified schedule view
- `/manager/reports` - Analytics & reporting
- `/manager/revenue` - Subscription revenue tracking

### 3. HANDYMAN Portal (`/handyman/*`)
**Demo Users:** 
- `mike@haven.app` / `Handy123!` (Fairfield County, CT)
- `carlos@haven.app` / `Handy123!` (Westchester County, NY)
- `maria@haven.app` / `Handy123!` (Floater)

Routes:
- `/handyman` - Today's schedule, current task
- `/handyman/schedule` - Weekly schedule view

### 4. VENDOR Portal (`/vendor/*`)
**Demo User:** `vendor@aceroofing.example.com` / `AceRoof123!`

Routes:
- `/vendor` - Dashboard, stats
- `/vendor/jobs` - Available jobs to claim
- `/vendor/schedule` - Assigned & upcoming jobs
- `/vendor/history` - Completed work history

### 5. ADMIN Portal (`/admin/*`)
**Demo User:** `admin@haven.app` / `Admin123!`

Routes:
- `/admin` - Platform overview
- `/admin/users` - All users management
- `/admin/households` - All households
- `/admin/categories` - Service categories

---

## DEMO DATA REFERENCE

**CRITICAL: Keep demo data consistent across all portals and features.**

### Demo Households

| Property | Owner | Manager | Handyman | Location |
|----------|-------|---------|----------|----------|
| Inspiration Farm | Bob Burke | Sarah Chen | Mike Rodriguez | 38 Bedford Rd, Greenwich, CT 06831 |
| Johnson Family Home | Alice Johnson | Sarah Chen | Carlos Reyes | 45 Fox Meadow Rd, Scarsdale, NY 10583 |
| Malibu Mansion | Bob Burke | Sarah Chen | Carlos Reyes | 27400 Pacific Coast Hwy, Malibu, CA 90265 |
| Beverly Hills Estate | Bob Burke | Sarah Chen | Carlos Reyes | 1200 Sunset Blvd, Beverly Hills, CA 90210 |

### Demo Users

| Role | Name | Email | Password |
|------|------|-------|----------|
| Admin | Platform Admin | admin@haven.app | Admin123! |
| Manager | Sarah Chen | sarah@haven.app | Manager123! |
| Homeowner | Bob Burke | bob@example.com | Bob123! |
| Homeowner | Alice Johnson | alice@example.com | Alice123! |
| Handyman | Mike Rodriguez | mike@haven.app | Handy123! |
| Handyman | Carlos Reyes | carlos@haven.app | Handy123! |
| Handyman | Maria Santos | maria@haven.app | Handy123! |
| Vendor | Ace Roofing | vendor@aceroofing.example.com | AceRoof123! |

### Burke Family (Inspiration Farm)
- **Bob Burke** - Owner (bob@example.com)
- **Alice Burke** - Spouse (alice.burke@example.com)
- **Emma Burke** - Daughter, age 14 (emma.burke@example.com)
- **Jack Burke** - Son, age 10 (jack.burke@example.com)
- **Max** - Golden Retriever, 4 years old

### Johnson Family (Scarsdale)
- **Alice Johnson** - Owner (alice@example.com)
- **Michael Johnson** - Spouse (michael.johnson@example.com)
- **Emma Johnson** - Daughter, age 14 (emma.johnson@example.com)
- **Jack Johnson** - Son, age 10 (jack.johnson@example.com)

### Demo Vendors (Inspiration Farm)

| Vendor | Category | Payment |
|--------|----------|---------|
| First National Mortgage | MORTGAGE | Owner pays direct |
| Regional Electric Co. | ELECTRIC | Owner pays direct |
| City Gas & Heating | GAS | Owner pays direct |
| Municipal Water Authority | WATER_SEWER | Owner pays direct |
| Waste Management Services | TRASH | Owner pays direct |
| FiberNet Internet | INTERNET | Owner pays direct |
| Country Landscape Design | LAWN_CARE | Haven pays on behalf |
| Terminix Northeast | PEST_CONTROL | Owner pays direct |
| Molly Maid of Greenwich | CLEANING | Haven pays on behalf |
| Fairfield County Snow Removal | SNOW_REMOVAL | Owner pays direct |
| New England Chimney Sweeps | CHIMNEY_SWEEP | Owner pays direct |
| Fairfield Septic Services | SEPTIC_SERVICE | Owner pays direct |
| Pools Unlimited CT | POOL_SERVICE | Haven pays on behalf |

### Demo Work Orders

**For Mike (Handyman - Greenwich):**
| Task | Status | Property |
|------|--------|----------|
| Smoke detector batteries | ASSIGNED (today) | Inspiration Farm |
| Squeaky door fix | ASSIGNED (today) | Inspiration Farm |
| Cabinet handles | IN_PROGRESS (now) | Inspiration Farm |
| HVAC filter | COMPLETED (yesterday) | Inspiration Farm |
| Weatherstripping | ASSIGNED (next week) | Inspiration Farm |

**For Ace Roofing (Vendor):**
| Task | Status | Property |
|------|--------|----------|
| Fix Shingles | OPEN (claimable) | Malibu Mansion |
| HVAC Inspection | ASSIGNED (tomorrow) | Malibu Mansion |
| Gutter Repair | COMPLETED (verify) | Beverly Hills Estate |
| Pool Pump Repair | IN_PROGRESS | Beverly Hills Estate |

### Demo Transactions (The Float)

| Description | Amount | Status | Method |
|-------------|--------|--------|--------|
| Pool Cleaning | $150 | PAID | Company Card |
| Emergency Locksmith | $300 | PAID | Cash |
| Management Fee | $100 | PENDING | Stripe |
| Fall Leaf Cleanup | $450 | PENDING | Check (Checkbook.io) |
| Snow Removal Deposit | $800 | PENDING | Check (Checkbook.io) |
| Water Heater Repair | $375 | PENDING | Stripe Connect |
| Plumbing Inspection | $150 | PENDING | Stripe Connect |
| Chimney Sweep | $275 | PENDING | Company Card |

### Demo Travel

| Trip | Status | Details |
|------|--------|---------|
| Aspen Ski Trip | BOOKED | 30 days out, full itinerary, house protocol |
| Spring Break Turks | INQUIRY | Needs manager assignment |
| SF Business | PROPOSAL_SENT | Flight options ready |
| Napa Weekend | COMPLETED | In history |

### Demo Conversations

| Subject | Messages | Status |
|---------|----------|--------|
| Park City Trip Planning | 8 | OPEN |
| Kitchen Faucet Issue | 11 | OPEN |
| Pool Cover Question | 3 | CLOSED |

---

## API MODULES

The NestJS API is organized by domain:

| Module | Purpose |
|--------|---------|
| auth | JWT auth, login, register, refresh tokens |
| users | User CRUD, profile management |
| households | Household CRUD, member management |
| home-profiles | Property details, systems inventory |
| bill-accounts | Bill tracking, vendor accounts |
| maintenance-tasks | Seasonal maintenance schedules |
| work-orders | Work order lifecycle management |
| service-requests | Homeowner request intake |
| conversations | Messaging between roles |
| messages | Real-time chat (WebSocket gateway) |
| travel | Trip planning, itineraries, proposals |
| invoices | Invoice generation, payment tracking |
| billing | Stripe subscription management |
| settlement | Monthly settlement, ACH collection |
| financials | Vendor payouts (Stripe, Checkbook.io) |
| vendor-portal | Vendor-specific endpoints |
| concierge | AI request triage |
| notifications | Push notifications |
| files/uploads | Document management, GCS storage |

---

## DATABASE SCHEMA HIGHLIGHTS

**Key Models:**
- `User` - All users (role: ADMIN, HOMEOWNER, MANAGER, VENDOR, HANDYMAN)
- `Household` - A managed property
- `HouseholdMember` - User-household relationship with role
- `HomeProfile` - Property details (sqft, beds, baths, systems)
- `Vendor` - Service providers and billers
- `BillAccount` - Recurring bill configuration
- `WorkOrder` - Vendor/handyman work assignments
- `MaintenanceTask` - Scheduled maintenance items
- `Transaction` - Financial transactions (The Float)
- `Conversation` / `SupportMessage` - Messaging
- `Trip` / `ItineraryItem` / `TripProposal` - Travel
- `TravelProfile` - TSA, loyalty programs, preferences

**Key Enums:**
- `UserRole`: ADMIN, HOMEOWNER, MANAGER, VENDOR, HANDYMAN
- `WorkOrderStatus`: OPEN, ASSIGNED, IN_PROGRESS, COMPLETED, VERIFIED, CANCELLED
- `TransactionStatus`: PENDING, PAID_TO_VENDOR, COLLECTED, SETTLED
- `TransactionPayoutMethod`: STRIPE, CHECKBOOK_IO, COMPANY_CARD, CASH

---

## DESIGN SYSTEM

### Colors
```css
/* Primary - Haven Green */
--haven-700: #0d4f4f;
--haven-800: #0a3d3d;

/* Accent - Champagne */
--champagne-200: #f5e6c8;
--champagne-300: #e8d4a8;

/* Neutral - Warm */
--warm-50: #faf9f7;
--warm-900: #1a1a1a;
```

### Typography
- Headings: `font-serif` (elegant, approachable)
- Body: `font-sans` (system stack)

### UI Patterns
- Rounded corners: `rounded-xl`, `rounded-2xl`
- Subtle shadows: `shadow-sm`, `shadow-lg`
- Warm, approachable tone
- Professional but not corporate

### Voice Guidelines

**DO SAY:**
- "We've got it covered"
- "Text us, we'll handle it"
- "One less thing to worry about"
- "Your home, handled"

**DON'T SAY:**
- "Our platform enables..."
- "Leverage our solution..."
- "Streamline your workflow..."
- "FDIC Insured" (we're not a bank!)

---

## PAYMENT MODEL (CRITICAL)

Haven uses **Just-in-Time Virtual Card** via Stripe Issuing:

```
1. User signs up → Stripe issues Virtual Card
2. Virtual Card linked to → User's bank/credit card
3. Manager pays bills → Charges Virtual Card
4. Charges clear → Directly to user's payment method
5. User sees → One monthly statement
```

**HAVEN NEVER HOLDS CUSTOMER FUNDS**

This is why all FDIC claims must be removed.

---

## PRICING TIERS

| Tier | Price | Target | What's Included |
|------|-------|--------|-----------------|
| Essentials | $39/mo | DIY homeowners | Bill dashboard, payment tracking |
| Lite | $349/mo | Busy professionals | + Text-based Home Manager |
| Haven | $749/mo | Families | + Proactive manager, 2hr handyman/mo |
| Haven+ | $1,499/mo | High earners | + Personal assistant, errands |
| Estate | $3,499/mo | Multi-property | + White glove, dedicated team |

---

## BUILD PRIORITIES

### Phase 1: Launch Critical
1. ✅ Fix FDIC messaging
2. Stripe payment method linking
3. Homeowner onboarding flow
4. Manager work queue UI
5. Monthly invoice generation

### Phase 2: Operational
1. Vendor onboarding & verification
2. Handyman scheduling calendar
3. Real-time messaging (WebSockets)
4. Push notifications
5. Email secretary feature

### Phase 3: Scale
1. Mobile app polish
2. AI concierge (NLP triage)
3. Multi-property dashboard
4. Analytics & reporting
5. Referral program

---

## KEY FILE LOCATIONS

| Purpose | Path |
|---------|------|
| Homepage (FIX FDIC!) | `apps/web/src/app/page.tsx` |
| Database Schema | `apps/api/prisma/schema.prisma` |
| Seed Script | `apps/api/prisma/seed.ts` |
| Homeowner Dashboard | `apps/web/src/app/app/` |
| Manager Portal | `apps/web/src/app/manager/` |
| Handyman Portal | `apps/web/src/app/handyman/` |
| Vendor Portal | `apps/web/src/app/vendor/` |
| Admin Portal | `apps/web/src/app/admin/` |
| Mobile App | `apps/mobile/app/` |
| Shared Types | `packages/core/src/types/` |
| API Modules | `apps/api/src/` |

---

## ENVIRONMENT VARIABLES

Required in `apps/api/.env`:
```
DATABASE_URL=postgresql://...
JWT_SECRET=...
JWT_REFRESH_SECRET=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
GCS_BUCKET=...
GCS_PROJECT_ID=...
```

Required in `apps/web/.env.local`:
```
NEXT_PUBLIC_API_URL=http://localhost:4000
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=...
```

---

## TESTING CREDENTIALS

After running `pnpm prisma:seed`:

| Portal | Email | Password |
|--------|-------|----------|
| Admin | admin@haven.app | Admin123! |
| Manager | sarah@haven.app | Manager123! |
| Homeowner (Bob) | bob@example.com | Bob123! |
| Homeowner (Alice) | alice@example.com | Alice123! |
| Handyman (Mike) | mike@haven.app | Handy123! |
| Handyman (Carlos) | carlos@haven.app | Handy123! |
| Vendor | vendor@aceroofing.example.com | AceRoof123! |

---

## COMPETITIVE POSITION

**Haven vs. Nines (Main Competitor)**

| Aspect | Nines | Haven |
|--------|-------|-------|
| Model | Software (you manage) | Service (we manage) |
| Pricing | Hidden, requires demo | Transparent on website |
| Contracts | 12-month annual | Month-to-month |
| Bills | You pay vendors separately | One bill, we pay all |
| Maintenance | Tracking/reminders only | Actual handyman visits |
| Target | UHNW, family offices | All homeowners |
| Setup Fee | $3-5K | $0 |

**Key Messages:**
1. "We do the work, not just track it"
2. "One bill, not one more app"  
3. "Humans, not just software"
4. "Transparent, flexible pricing"
5. "For everyone, not just estates"
