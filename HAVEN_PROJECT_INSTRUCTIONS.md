# HAVEN HOME - PROJECT INSTRUCTIONS
## Master Context for All Development Conversations

**Last Updated:** January 14, 2026
**Project Location:** `/Users/tomburke/Projects/Housing-Manager/`

---

# SECTION 1: WHAT IS HAVEN?

Haven is a **full-service home management platform**. Unlike apps that give homeowners software to organize their chaos, Haven provides **dedicated Home Managers who actually do the work**—paying bills, coordinating vendors, scheduling maintenance, and handling the countless details of homeownership.

**Tagline:** "Stop managing your home. Start living in it."
**Model:** One bill. One contact. Zero hassle. SERVICE, not software.

### The Haven Difference
- **One payment** covers everything (mortgage, utilities, insurance, vendors)
- **One text** handles anything (text your manager, they make the calls)
- **Results**, not more to-do lists

### Service Tiers
| Tier | Price | Key Features | Target % of Users |
|------|-------|--------------|-------------------|
| **Essentials** | $39/mo | AI Home Manager (Alfred), bill tracking, reminders | 90-99% |
| Lite | $349/mo | + Human text-based manager, reactive support | |
| Haven | $749/mo | + Proactive manager, monthly handyman | |
| Haven+ | $1,499/mo | + Lifestyle services, errands | |
| Estate | $3,499/mo | + Multi-property, white-glove | |

**Strategic Note:** Essentials tier with Alfred (AI) is the primary offering. Human managers are positioned as premium upgrades.

---

# SECTION 2: ALFRED - THE AI HOME MANAGER

Alfred is Haven's AI-powered personal assistant. He's the core differentiator for the Essentials tier.

## Alfred's Capabilities

### 1. Email Processing (CC Alfred Feature)
**Email:** `{address}@alfred.havenhome.dev` (e.g., `38BedfordRoad@alfred.havenhome.dev`)

Users CC or forward any email to Alfred, and he:
- **Extracts calendar events** - camps, appointments, deadlines
- **Tracks bills** - invoices, due dates, amounts
- **Updates vendors** - contact info, quotes, warranties
- **Reads attachments** - PDFs, inspection reports, invoices
- **Asks clarifying questions** - "Which child is this camp for?"
- **Creates a Case** for every email (audit trail)

**Case System:**
- Every email creates a trackable case (ALF-2026-000001)
- Full activity log for audit trail
- Status: RECEIVED → PROCESSING → AWAITING_INPUT → COMPLETED
- Users can view all cases in the app

### 2. Chat Interface
- Natural conversation about home management
- Proactive setup questions for new users
- Quick actions via buttons
- Context-aware suggestions

### 3. Smart Prompts Throughout App
- Empty state suggestions when data is missing
- Setup checklist for new users
- Contextual help based on what's incomplete

---

# SECTION 3: TECH STACK

```
/Users/tomburke/Projects/Housing-Manager/
├── apps/
│   ├── api/          # NestJS backend (port 4000)
│   │   └── prisma/   # Schema + migrations + seed
│   ├── mobile/       # Expo React Native (iOS)
│   └── web/          # Next.js 15 App Router (port 3000)
├── packages/
│   ├── config/       # Shared ESLint, TypeScript configs
│   ├── core/         # Shared types, schemas, constants
│   └── ui/           # Shared React components
├── prompts/          # Claude Code implementation prompts
```

### Technologies
- **Frontend Web:** Next.js 15, React 18, Tailwind CSS, Radix UI
- **Mobile:** Expo/React Native, NativeWind, Firebase Auth
- **Backend:** NestJS 10, Prisma ORM, PostgreSQL
- **Auth:** Firebase Authentication (Apple, Google, Email)
- **Payments:** Stripe (Issuing, Connect, Billing), RevenueCat (mobile subscriptions)
- **AI:** Anthropic Claude API
- **Email:** SendGrid (inbound parse for Alfred)
- **Deploy:** Google Cloud Run (API), TestFlight (iOS)

### Key Integrations
| Service | Purpose | Status |
|---------|---------|--------|
| Firebase Auth | Apple/Google/Email sign-in | ✅ Complete |
| Google Places API | Address autocomplete | ✅ Complete |
| ATTOM Data API | Property data enrichment | ✅ Complete |
| Plaid | Bank connection, bill detection | ✅ Complete |
| RevenueCat | Mobile subscription management | ✅ Complete |
| SendGrid Inbound Parse | Alfred email processing | ✅ Configured |
| Claude API | AI parsing and chat | ✅ Complete |
| Google Calendar API | Calendar sync | ✅ Complete |
| expo-calendar | iOS calendar access | ✅ Complete |

### Commands
```bash
pnpm dev:web          # Start web (localhost:3000)
pnpm dev:api          # Start API (localhost:4000)
pnpm dev:mobile       # Start Expo

cd apps/api
pnpm prisma migrate dev   # Run migrations
pnpm prisma db seed       # Seed demo data
pnpm prisma studio        # Database GUI

cd apps/mobile
npx expo start --clear    # Start Expo dev server
eas build --platform ios --profile production --auto-submit  # TestFlight build
```

---

# SECTION 4: MOBILE APP - COMPLETE FEATURE LIST

## Implemented Features (January 2026)

### Authentication & Onboarding
- ✅ Apple Sign-In (captures name on first sign-in)
- ✅ Google Sign-In
- ✅ Email/Password authentication
- ✅ Address autocomplete (Google Places)
- ✅ Property data enrichment (ATTOM API)
- ✅ Name capture from social auth
- ✅ Onboarding flow with property setup

### Home Dashboard
- ✅ Home Health Score (real calculation)
- ✅ Today's Notes (real data from calendar/bills/tasks)
- ✅ Setup Checklist for new users
- ✅ Empty states with helpful prompts
- ✅ Quick actions

### Family Management
- ✅ Family members list
- ✅ Add/edit family members
- ✅ Children with school, activities, allergies
- ✅ Pets with vet info
- ✅ Vehicles
- ✅ Staff (nanny, housekeeper, etc.)
- ✅ Permission-based editing (owner vs member)

### Property & Home
- ✅ Property details from ATTOM
- ✅ Zones (rooms/areas)
- ✅ Systems per zone (HVAC, appliances, etc.)
- ✅ Home profile editing

### Bills & Money
- ✅ Bills list (real data)
- ✅ Plaid bank connection
- ✅ Bill detection from transactions
- ✅ Payment tracking
- ✅ Empty states prompting setup

### Maintenance
- ✅ Maintenance tasks
- ✅ Systems tracking
- ✅ Service scheduling
- ✅ Empty states

### Vendors
- ✅ Vendor list
- ✅ Add/edit vendors
- ✅ Category organization
- ✅ Contact info

### Calendar
- ✅ Google Calendar sync (OAuth)
- ✅ iOS Calendar sync (device access)
- ✅ Calendar settings screen
- ✅ Calendar picker for iOS

### Alfred (AI Assistant)
- ✅ Chat interface
- ✅ Email processing (CC Alfred) - IN PROGRESS
- ✅ Cases tracking - IN PROGRESS
- ✅ Proactive questions

### Settings
- ✅ Profile editing
- ✅ Calendar sync settings
- ✅ Alfred email settings
- ✅ Authorized senders management
- ✅ Subscription management (RevenueCat)

### UI/UX
- ✅ Navy + Champagne color scheme
- ✅ Tab bar navigation
- ✅ Consistent headers
- ✅ Empty state components
- ✅ Loading states
- ✅ Pull to refresh

---

# SECTION 5: API ENDPOINTS

## Core Modules

### Authentication (`/auth`)
- POST `/auth/firebase` - Firebase token exchange
- POST `/auth/register` - Email registration
- GET `/auth/me` - Current user

### Households (`/households`)
- GET `/households/:id` - Get household
- PATCH `/households/:id` - Update household
- GET `/households/:id/vendors` - Household vendors

### Family (`/family`)
- GET `/family/household/:id` - Get family members
- POST `/family/household/:id/members` - Add member
- PATCH `/family/household/:id/member/:memberId` - Edit member
- DELETE `/family/household/:id/member/:memberId` - Remove member

### Dashboard (`/dashboard`)
- GET `/dashboard/household/:id/today` - Today's notes
- GET `/dashboard/household/:id/health` - Health score
- GET `/dashboard/household/:id/setup-status` - Setup checklist

### Calendars (`/calendars`)
- GET `/calendars/connections` - List connected calendars
- POST `/calendars/connect/google` - Connect Google Calendar
- POST `/calendars/connect/apple` - Connect iOS Calendar
- DELETE `/calendars/disconnect/:provider` - Disconnect
- GET `/calendars/events` - Get events

### Alfred Email (`/alfred`)
- POST `/alfred/inbound-email` - SendGrid webhook (no auth)
- GET `/alfred/email-address` - Get household's Alfred email
- GET `/alfred/authorized-emails` - List authorized senders
- POST `/alfred/authorized-emails` - Add authorized sender
- DELETE `/alfred/authorized-emails/:id` - Remove sender
- GET `/alfred/cases` - List email cases
- GET `/alfred/cases/:id` - Case details
- POST `/alfred/cases/:id/respond` - Answer Alfred's question

### Bills & Plaid (`/plaid`, `/bills`)
- POST `/plaid/create-link-token` - Start Plaid Link
- POST `/plaid/exchange-token` - Complete connection
- GET `/bills/household/:id` - Get bills

### Users (`/users`)
- PATCH `/users/profile` - Update profile

---

# SECTION 6: CANONICAL DEMO DATA

## Primary Demo Family: THE MORRISONS

### Property
| Field | Value |
|-------|-------|
| **Home Name** | Inspiration Farm |
| **Address** | 38 Bedford Road, Greenwich, CT 06831 |
| **Alfred Email** | 38BedfordRoad@alfred.havenhome.dev |
| **Specs** | 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres |
| **Home Health** | 94/100 (Excellent) |

### Adults

**Bob Morrison** (Head of Household)
| Field | Value |
|-------|-------|
| Email | bob@example.com |
| Password | Bob123! |
| Phone | (203) 555-0101 |
| Occupation | Morrison Capital Partners |
| Vehicle | 2023 Tesla Model Y (GRN 1234) |

**Alice Morrison** (Spouse)
| Field | Value |
|-------|-------|
| Email | alice@example.com |
| Password | Alice123! |
| Phone | (203) 555-0102 |
| Occupation | Greenwich Hospital, Pediatric NP |
| Vehicles | 2022 Toyota Highlander, 2024 Mercedes GLE 450 |

### Children
- **Emma Morrison** - 12 years old, 7th Grade, Greenwich Country Day School, Soccer + Piano, Allergies: Peanuts/Tree nuts
- **Jack Morrison** - 8 years old, 3rd Grade, North Street School, Little League + Piano + Art

### Pet
- **Max** - Golden Retriever, 4 years old, Dr. Williams at Westlake Animal Hospital

### Staff
- **Maria Garcia** - Nanny, Greenwich Elite Nannies, $1,500/week

### Haven Team
| Role | Name | Email | Password |
|------|------|-------|----------|
| Home Manager | Sarah Chen | sarah@haven.app | Manager123! |
| Handyman | Mike Rodriguez | mike@haven.app | Handy123! |
| Admin | - | admin@haven.app | Admin123! |

---

# SECTION 7: DESIGN SYSTEM

## Color Palette

### ⚠️ CRITICAL: NO BRIGHT GREEN
Use Navy + Champagne + White only.

### Navy (Primary)
- navy-950: #0a1929 (backgrounds)
- navy-900: #102a43 (headings, buttons)
- navy-800: #243b53 (secondary)

### Champagne (Accent)
- champagne-500: #c4a574 (CTAs, accents)
- champagne-400: #d4c4a5 (hover)
- champagne-100: #faf6ed (subtle backgrounds)

---

# SECTION 8: ENVIRONMENT VARIABLES

## API (`apps/api/.env`)
```bash
DATABASE_URL=postgresql://...
JWT_SECRET=...
FIREBASE_PROJECT_ID=home-manager-480616
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
STRIPE_SECRET_KEY=sk_test_...
PLAID_CLIENT_ID=...
PLAID_SECRET=...
PLAID_ENV=sandbox
ANTHROPIC_API_KEY=sk-ant-api03-...
SENDGRID_API_KEY=SG....
ALFRED_EMAIL_DOMAIN=alfred.havenhome.dev
CALENDAR_ENCRYPTION_KEY=... (32 chars)
GOOGLE_MAPS_API_KEY=...
```

## Mobile (`apps/mobile/.env`)
```bash
EXPO_PUBLIC_API_URL=https://api.havenhome.dev/api
EXPO_PUBLIC_FIREBASE_API_KEY=...
EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID=...
EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID=...
EXPO_PUBLIC_REVENUECAT_API_KEY=...
```

---

# SECTION 9: PROMPTS DIRECTORY

All implementation prompts are in `/Users/tomburke/Projects/Housing-Manager/prompts/`

### Recent/Active Prompts
| Prompt | Purpose | Status |
|--------|---------|--------|
| `FIX-profile-family-editing.md` | Profile update bug, social auth name capture | ✅ Complete |
| `FIX-remove-hardcoded-data.md` | Real data, empty states, setup checklist | ✅ Complete |
| `IMPLEMENT-calendar-sync.md` | Google + iOS calendar sync | ✅ Complete |
| `IMPLEMENT-alfred-email.md` | Alfred email CC feature, case system | 🔄 Ready |

### Mobile Development Prompts (M01-M12)
Located in `prompts/mobile/` - comprehensive mobile app development from foundation to TestFlight.

---

# SECTION 10: CURRENT STATUS (January 2026)

## Completed This Session
- ✅ Profile & family editing fixes (API deployed)
- ✅ Remove hard-coded data from app
- ✅ Empty state components created
- ✅ Calendar sync (Google + iOS)
- ✅ Database migration reset and clean init
- ✅ SendGrid inbound parse configured
- ✅ Alfred email prompt created

## In Progress
- 🔄 Alfred email implementation (prompt ready, needs execution)

## Next Up
- Website repositioning (Alfred/Essentials front and center)
- Alfred email complete implementation
- TestFlight build with all new features

## Deployed Services
| Service | URL | Status |
|---------|-----|--------|
| API | https://api.havenhome.dev | ✅ Live |
| Web | https://havenhome.dev | ✅ Live |
| iOS App | TestFlight | ✅ Latest build |

---

# SECTION 11: KEY DECISIONS & PRINCIPLES

1. **Alfred First** - The AI assistant is the primary value proposition at $39/mo
2. **Real Data Only** - No hard-coded mock data in the app
3. **Never Drop** - Every user action (especially emails to Alfred) gets handled
4. **Address-Based Codes** - Alfred emails use address for memorability (38BedfordRoad@alfred.havenhome.dev)
5. **Case System** - Every Alfred email creates a trackable case with audit trail
6. **Essentials = 90%+ users** - Design and market for the $39 tier

---

# SECTION 12: QUICK REFERENCE

## When Starting a New Chat
1. Read this document first
2. Check `prompts/` for existing implementation prompts
3. Reference `SESSION_SUMMARY_*.md` files for recent work
4. Use canonical demo data (Morrisons, 38 Bedford Road)

## Key File Locations
- **API:** `apps/api/src/`
- **Mobile:** `apps/mobile/app/` (routes), `apps/mobile/src/` (components/lib)
- **Web:** `apps/web/src/app/`
- **Prompts:** `prompts/`
- **Schema:** `apps/api/prisma/schema.prisma`

## Common Commands
```bash
# Deploy API
cd apps/api && gcloud builds submit

# TestFlight build
cd apps/mobile && eas build --platform ios --profile production --auto-submit

# Run migrations
cd apps/api && pnpm prisma migrate dev --name <name>
```

---

**Haven — Stop managing your home. Start living in it.**

*Tom Burke, Founder/CTO*
*Claude, CIO & Co-founder*
