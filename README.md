# Haven Home Management Platform

**Stop managing your home. Start living in it.**

Haven is a full-service home management platform that provides dedicated Home Managers who actually do the work—paying bills, coordinating vendors, scheduling maintenance, and handling the countless details of homeownership.

**Model:** One bill. One contact. Zero hassle. SERVICE, not software.

---

## Quick Links

| Resource | Location |
|----------|----------|
| **Project Root** | `/Users/tomburke/Projects/Housing-Manager/` |
| **Production Web** | https://havenhome.dev |
| **Production API** | https://api.havenhome.dev |
| **GCP Project** | home-manager-480616 |
| **Development Prompts** | `/prompts/` |
| **Project Instructions** | See "Haven Home - Project Instructions" in Claude Project |

---

## Current Status (December 26, 2024)

### ✅ Completed
- Firebase Auth (Email/Password + Google Sign-In)
- Cloud SQL database (haven-production-db)
- Cloud Run services (haven-api, haven-web)
- ATTOM Property API integration for property enrichment
- Google Places API autocomplete for addresses
- Basic user onboarding flow
- Design system (Navy + Champagne + White)
- Demo data specification (Morrison family)

### 🔄 In Progress
- **001-homeowner-portal-production-ready.md** - Dashboard, Your Home, Money, Family pages
- **002-home-manager-intake-workbench.md** - Sarah's tool for capturing household data

### ⏳ Pending
- Approval system (HM requests → Homeowner approves)
- Handyman portal (Mike's task view)
- Messaging system (Homeowner ↔ Home Manager)
- Calendar integration
- Seed data update (Morrison family with new models)

---

## Architecture

```
/Users/tomburke/Projects/Housing-Manager/
├── apps/
│   ├── api/                    # NestJS backend (port 4000)
│   │   ├── prisma/             # Schema + migrations + seed
│   │   └── src/
│   │       ├── auth/           # Firebase auth
│   │       ├── property/       # ATTOM integration
│   │       ├── household/      # Household management
│   │       ├── bill/           # Bill tracking
│   │       ├── activity/       # Activity logging
│   │       └── manager/        # Home Manager features
│   ├── mobile/                 # Expo React Native (future)
│   └── web/                    # Next.js 15 App Router (port 3000)
│       └── src/
│           ├── app/
│           │   ├── app/        # Homeowner portal
│           │   ├── manager/    # Home Manager portal
│           │   ├── handyman/   # Handyman portal
│           │   └── onboarding/ # User signup flow
│           ├── components/
│           └── contexts/
├── packages/
│   ├── config/                 # Shared ESLint, TypeScript configs
│   ├── core/                   # Shared types, schemas, constants
│   └── ui/                     # Shared React components
└── prompts/                    # Claude Code implementation prompts
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Next.js 15, React 18, Tailwind CSS, Radix UI |
| Mobile | Expo/React Native (planned) |
| Backend | NestJS 10, Prisma ORM, PostgreSQL |
| Auth | Firebase Authentication |
| Payments | Stripe (Issuing, Connect, Billing) |
| Property Data | ATTOM Property API |
| Address Autocomplete | Google Places API |
| Deploy | Google Cloud Run |
| Database | Google Cloud SQL (PostgreSQL) |

---

## Service Tiers

| Tier | Price | Key Features |
|------|-------|--------------|
| Essentials | $39/mo | Bill consolidation, tracking, reminders |
| Lite | $349/mo | + Text-based manager, reactive support |
| Haven | $749/mo | + Proactive manager, monthly handyman |
| Haven+ | $1,499/mo | + Lifestyle services, errands |
| Estate | $3,499/mo | + Multi-property, white-glove |

---

## User Portals

| Portal | Route | Users | Purpose |
|--------|-------|-------|---------|
| Homeowner | `/app/*` | Bob, Alice Morrison | View home, bills, family, communicate with Sarah |
| Manager | `/manager/*` | Sarah Chen | Onboard households, manage bills, coordinate service |
| Handyman | `/handyman/*` | Mike Rodriguez | View/complete assigned tasks |
| Vendor | `/vendor/*` | Ace Roofing, etc. | (Future) View jobs, submit invoices |
| Admin | `/admin/*` | Platform Admin | (Future) System management |

---

## Key Data Models

### Core Entities
- **Household** - A customer account (the Morrisons)
- **Property** - Physical address with ATTOM enrichment
- **User** - Login credentials, linked to household

### Property Structure (Zone-Based)
- **Zone** - Room/area (Kitchen, Garage, etc.)
- **Asset** - Item in a zone (Refrigerator, Water Heater)
- **ServiceLog** - History of work done on assets

### People
- **FamilyMember** - Adults, children, pets, staff
- **KidActivity** - Emma's soccer, Jack's piano

### Financial
- **Bill** - Recurring payment with account numbers
- **BillPayment** - Record of payment made
- **Vendor** - Service provider with contact info

### Operations
- **OnboardingSession** - Tracks intake progress
- **ActivityLog** - All actions (HM paid bill, etc.)
- **Approval** - Requests needing homeowner approval (future)

---

## API Keys & Secrets

| Service | Location | Notes |
|---------|----------|-------|
| Firebase | GCP Secret Manager | `firebase-service-account` |
| ATTOM API | Environment variable | `ATTOM_API_KEY=c4065c54cf3df7c4260115d2445bf0ef` |
| Google Places | Environment variable | Restricted to havenhome.dev |
| Stripe | GCP Secret Manager | (To be configured) |

---

## Development Commands

```bash
# Start development
pnpm dev:web          # Web app at localhost:3000
pnpm dev:api          # API at localhost:4000

# Database
cd apps/api
pnpm prisma:migrate:dev   # Run migrations
pnpm prisma:seed          # Seed demo data
pnpm prisma:studio        # Database GUI

# Build & Deploy
pnpm build
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## Canonical Demo Data

### Primary Demo Family: THE MORRISONS

**Property:** Inspiration Farm  
**Address:** 38 Bedford Road, Greenwich, CT 06831  
**Specs:** 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres

**Adults:**
- Bob Morrison (bob@example.com) - Head of Household, Morrison Capital Partners
- Alice Morrison (alice@example.com) - Spouse, Greenwich Hospital NP

**Children:**
- Emma (12) - 7th Grade, Greenwich Country Day, Soccer, Piano, Allergies: Peanuts/Tree nuts
- Jack (8) - 3rd Grade, North Street School, Little League, Piano, Art

**Pet:** Max - Golden Retriever, 4 years

**Staff:** Maria Garcia - Nanny, Mon-Thu 7am-6pm

**Vehicles:**
- 2023 Tesla Model Y (Bob)
- 2022 Toyota Highlander (Alice)
- 2024 Mercedes GLE 450 (Alice)

### Haven Team

**Home Manager:** Sarah Chen (sarah@haven.app)  
**Handyman:** Mike Rodriguez (mike@haven.app)  
**Admin:** admin@haven.app

---

## Design System

### Colors (NO BRIGHT GREEN!)

**Navy (Primary):**
- navy-950: #0a1929 (Sidebar background)
- navy-900: #102a43 (Headings, buttons)
- navy-800: #243b53 (Secondary)

**Champagne (Accent):**
- champagne-500: #c4a574 (CTAs, highlights)
- champagne-300: #e9dcc4 (Light accents)
- champagne-100: #faf6ed (Backgrounds)

**Usage:**
- Sidebar: navy-950 background, light text
- Page background: gray-50
- Cards: white
- Primary buttons: navy-900
- Accent buttons: champagne-500
- Success only: muted green (sparingly)

---

## Implementation Prompts

Prompts are stored in `/prompts/` and executed by Claude Code.

| # | File | Description | Status |
|---|------|-------------|--------|
| 001 | `001-homeowner-portal-production-ready.md` | Activity logging, Dashboard, Your Home, Money, Family | 🔄 Running |
| 002 | `002-home-manager-intake-workbench.md` | Onboarding queue, intake workbench for Home Managers | ⏳ Next |

### Running a Prompt

In Claude Code:
```
Read the prompt at prompts/001-homeowner-portal-production-ready.md and implement it phase by phase.
```

Or for a specific phase:
```
Read prompts/002-home-manager-intake-workbench.md and implement Phase 2: Manager Queue UI.
```

---

## Key Decisions Made

1. **Service-First Onboarding:** User enters address (2 min) → Home Manager does comprehensive intake during intro call. User never fills out forms.

2. **Zone-Based Structure:** Property organized by zones (like Nines Living) - Kitchen → Assets → Service History. Natural for phone conversations.

3. **Activity Logging:** Every action by HM/Handyman creates ActivityLog entry. Homeowner sees what's happening in real-time.

4. **Bill Consolidation:** Haven captures ALL recurring payments (mortgage, utilities, loans, tuition, activities, subscriptions). One monthly funding amount covers everything.

5. **Connections Model:** Everything linked - Vendor → Assets → Service History → Bills → Documents. Find anything from anywhere.

---

## Inspiration

Haven is bringing estate management (like Nines Living) to mass affluent homeowners ($300K-$3M income). Key principles borrowed:

- **Expert-led onboarding** - Dedicated specialist captures everything
- **Zone-based organization** - Property → Zones → Assets
- **Living household manual** - Always current, mobile accessible
- **Proactive service** - Notice issues before homeowner does
- **Easy handoffs** - Everything documented, anyone can pick up

---

## Contact

**CIO:** Tom Burke  
**Project:** Haven Home (Claude Project)

---

## Next Session Checklist

If starting a new chat, reference this README and:

1. Check current status section above
2. Review which prompts are completed vs in-progress
3. Look at `/prompts/` folder for implementation details
4. Continue with next pending prompt

The goal is seamless continuity across chat sessions.
