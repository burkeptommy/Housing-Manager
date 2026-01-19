# HAVEN HOME - PROJECT INSTRUCTIONS

**Last Updated:** January 16, 2026  
**Project Location:** `/Users/tomburke/Projects/Housing-Manager/`

---

## WHAT IS HAVEN?

Haven is a **full-service home management platform**. Unlike apps that give homeowners software to organize their chaos, Haven provides a combination of **AI assistance (Alfred)** and **dedicated Home Managers** who actually do the work.

**Tagline:** "Stop managing your home. Start living in it."  
**Model:** One bill. One contact. Zero hassle.

### Service Tiers

| Tier | Price | Key Features | Target Users |
|------|-------|--------------|--------------|
| **Essentials** | $39/mo | Alfred AI, bill tracking, reminders, one consolidated bill | 90%+ of users |
| Lite | $349/mo | + Human text-based manager, reactive support | |
| Haven | $749/mo | + Proactive manager, monthly handyman included | |
| Haven+ | $1,499/mo | + Lifestyle services, errands | |
| Estate | $3,499/mo | + Multi-property, white-glove | |

**Strategic Focus:** Essentials tier with Alfred is the primary offering. Human managers are positioned as premium upgrades.

---

## ALFRED - THE AI HOME MANAGER

Alfred is Haven's AI-powered personal assistant and the core value proposition at $39/mo.

### Alfred's Capabilities

**Email Processing (CC Alfred):**  
- Email: `{address}@alfred.havenhome.dev` (e.g., `38BedfordRoad@alfred.havenhome.dev`)
- Extracts calendar events, tracks bills, updates vendors, reads attachments
- Every email creates a trackable Case with full audit trail

**Core Features:**
- Bill tracking and reminders
- Maintenance scheduling
- Savings identification
- Home manual / documentation
- One consolidated monthly bill
- Chat interface for questions

### Important Principles

1. **Alfred First** - The AI assistant is the primary value proposition at $39/mo
2. **Never Drop** - Every user action (especially emails to Alfred) gets handled
3. **Real Data Only** - No hard-coded mock data in the app
4. **Case System** - Every Alfred email creates a trackable case

---

## DESIGN SYSTEM - SAGE GREEN

**Vibe:** Natural, grounded, calm. A well-organized home with a garden. Modern without being cold.

### Official Color Palette

| Role | Color | Hex |
|------|-------|-----|
| **Primary** | Navy | `#0a1929` |
| **Accent** | Sage | `#7D8E74` |
| **Soft Accent** | Light Sage | `#A4B494` |
| **Light BG** | Soft Green | `#F4F6F2` |
| **Card BG** | Cream | `#FAFAF7` |

### ⚠️ CRITICAL: NO BRIGHT GREEN, NO CHAMPAGNE

The old brand used bright green and champagne. These are **DEPRECATED**. Use Navy + Sage only.

### Tailwind Sage Colors

```typescript
sage: {
  50: '#F4F6F2',   // Light BG
  100: '#E8EDE4',  // Subtle backgrounds
  200: '#D1DBC9',  // Borders, dividers
  300: '#A4B494',  // Light Sage / soft accent
  400: '#8FA37F',  // Medium accent
  500: '#7D8E74',  // Primary Sage accent
  600: '#6B7A63',  // Darker accent / hover
  700: '#5A6853',  // Dark accent
  800: '#4A5544',  // Very dark
  900: '#3B4536',  // Darkest
}
```

### Color Usage Rules

- **White buttons** on dark (navy) backgrounds
- **Navy buttons** on light backgrounds
- **Sage** for accents, badges, checkmarks, icons - NOT for primary CTAs
- **Soft Green** (`#F4F6F2`) for alternating section backgrounds
- **Cream** (`#FAFAF7`) for card backgrounds

---

## TECH STACK

```
/Users/tomburke/Projects/Housing-Manager/
├── apps/
│   ├── api/          # NestJS backend (port 4000)
│   ├── mobile/       # Expo React Native (iOS)
│   └── web/          # Next.js 15 App Router (port 3000)
├── packages/
│   ├── core/         # Shared types, schemas, constants
│   └── ui/           # Shared React components
├── prompts/          # Claude Code implementation prompts
```

### Technologies
- **Frontend Web:** Next.js 15, React 18, Tailwind CSS, Radix UI
- **Mobile:** Expo/React Native, NativeWind, Firebase Auth
- **Backend:** NestJS 10, Prisma ORM, PostgreSQL
- **Auth:** Firebase Authentication (Apple, Google, Email)
- **AI:** Anthropic Claude API
- **Email:** SendGrid (inbound parse for Alfred)
- **Deploy:** Google Cloud Run (API), TestFlight (iOS)

### Commands

```bash
pnpm dev:web          # Start web (localhost:3000)
pnpm dev:api          # Start API (localhost:4000)
pnpm dev:mobile       # Start Expo

cd apps/api
pnpm prisma migrate dev   # Run migrations
pnpm prisma db seed       # Seed demo data

cd apps/mobile
eas build --platform ios --profile production --auto-submit  # TestFlight build
```

---

## CANONICAL DEMO DATA

### Primary Demo Family: THE MORRISONS

| Field | Value |
|-------|-------|
| **Home Name** | Inspiration Farm |
| **Address** | 38 Bedford Road, Greenwich, CT 06831 |
| **Alfred Email** | 38BedfordRoad@alfred.havenhome.dev |
| **Specs** | 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres |

### Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| Homeowner | bob@example.com | Bob123! |
| Spouse | alice@example.com | Alice123! |
| Manager | sarah@haven.app | Manager123! |
| Handyman | mike@haven.app | Handy123! |
| Admin | admin@haven.app | Admin123! |

### Family Members
- **Bob Morrison** - Head of Household, Morrison Capital Partners
- **Alice Morrison** - Spouse, Greenwich Hospital
- **Emma** - 12 years old, 7th Grade, Soccer + Piano
- **Jack** - 8 years old, 3rd Grade, Little League + Piano
- **Max** - Golden Retriever, 4 years old

---

## KEY REMINDERS

1. **Family name is MORRISON** (not Burke, Smith, or Miller)
2. **Property is 38 Bedford Road, Greenwich, CT**
3. **Manager is Sarah Chen** (sarah@haven.app)
4. **Colors are Navy + Sage** (NO GREEN, NO CHAMPAGNE)
5. **Alfred is the primary value** - $39 Essentials tier

---

## FILE LOCATIONS

- **Homepage:** `apps/web/src/app/page.tsx`
- **Tailwind config:** `apps/web/tailwind.config.ts`
- **Prompts:** `prompts/`
- **Schema:** `apps/api/prisma/schema.prisma`

---

## CURRENT STATUS (January 2026)

### Completed
- ✅ Alfred email processing (CC feature)
- ✅ Calendar sync (Google + iOS)
- ✅ Mobile app on TestFlight
- ✅ Plaid integration for bill detection
- ✅ Sage Green color palette migration
- ✅ Homepage repositioning (Alfred-first)

### In Progress
- 🔄 Website design elevation (prompt 012)
- 🔄 Mobile app polish

### Deployed Services

| Service | URL | Status |
|---------|-----|--------|
| API | https://api.havenhome.dev | ✅ Live |
| Web | https://havenhome.dev | ✅ Live |
| iOS App | TestFlight | ✅ Latest build |

---

**Haven — Stop managing your home. Start living in it.**
