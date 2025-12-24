# HAVEN HOME - PROJECT INSTRUCTIONS
## Master Context for All Development Conversations

**Last Updated:** December 24, 2025
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
| Tier | Price | Key Features |
|------|-------|--------------|
| Essentials | $39/mo | Bill consolidation, tracking, reminders |
| Lite | $349/mo | + Text-based manager, reactive support |
| Haven | $749/mo | + Proactive manager, monthly handyman |
| Haven+ | $1,499/mo | + Lifestyle services, errands |
| Estate | $3,499/mo | + Multi-property, white-glove |

---

# SECTION 2: TECH STACK

```
/Users/tomburke/Projects/Housing-Manager/
├── apps/
│   ├── api/          # NestJS backend (port 4000)
│   │   └── prisma/   # Schema + migrations + seed
│   ├── mobile/       # Expo React Native
│   └── web/          # Next.js 15 App Router (port 3000)
├── packages/
│   ├── config/       # Shared ESLint, TypeScript configs
│   ├── core/         # Shared types, schemas, constants
│   └── ui/           # Shared React components
```

### Technologies
- **Frontend:** Next.js 15, React 18, Tailwind CSS, Radix UI
- **Mobile:** Expo/React Native
- **Backend:** NestJS 10, Prisma ORM, PostgreSQL
- **Auth:** JWT with refresh token rotation
- **Payments:** Stripe (Issuing, Connect, Billing)
- **Deploy:** Google Cloud Run

### Commands
```bash
pnpm dev:web          # Start web (localhost:3000)
pnpm dev:api          # Start API (localhost:4000)
pnpm dev:mobile       # Start Expo

cd apps/api
pnpm prisma:migrate:dev   # Run migrations
pnpm prisma:seed          # Seed demo data
pnpm prisma:studio        # Database GUI

pnpm build            # Build all
pnpm test             # Run tests
pnpm lint             # Lint code
```

---

# SECTION 3: CANONICAL DEMO DATA ⭐ CRITICAL

**This is the single source of truth. All mock data must match this exactly.**

## Primary Demo Family: THE MORRISONS

### Property
| Field | Value |
|-------|-------|
| **Home Name** | Inspiration Farm |
| **Address** | 38 Bedford Road, Greenwich, CT 06831 |
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

**Emma Morrison**
- Age: 12 years old, 7th Grade
- School: Greenwich Country Day School ($4,500/mo)
- Allergies: Peanuts, Tree nuts
- Activities: Soccer, Piano

**Jack Morrison**
- Age: 8 years old, 3rd Grade
- School: North Street School
- Activities: Little League, Piano, Art class

### Pet

**Max** - Golden Retriever, 4 years old
- Vet: Dr. Williams, Westlake Animal Hospital
- Food: Blue Buffalo (30 lbs/mo)
- Monthly cost: $150

### Staff

**Maria Garcia** - Nanny
- Agency: Greenwich Elite Nannies
- Phone: (203) 555-0199
- Weekly stipend: $1,500
- Schedule: Mon-Thu 7am-6pm, Fri 7am-3pm

---

## Haven Team Credentials

### Home Manager
| Field | Value |
|-------|-------|
| **Name** | Sarah Chen |
| **Email** | sarah@haven.app |
| **Password** | Manager123! |
| **Title** | Your Home Manager |

### Handymen
| Name | Email | Password | Region |
|------|-------|----------|--------|
| Mike Rodriguez | mike@haven.app | Handy123! | Connecticut (Primary) |
| Carlos Reyes | carlos@haven.app | Handy123! | NY/CA |
| Maria Santos | maria@haven.app | Handy123! | Floater |

### Vendor
| Field | Value |
|-------|-------|
| **Company** | Ace Roofing Co. |
| **Email** | vendor@aceroofing.example.com |
| **Password** | AceRoof123! |

### Admin
| Field | Value |
|-------|-------|
| **Email** | admin@haven.app |
| **Password** | Admin123! |

---

## Secondary Properties (Multi-Property Demo)

| Property | Address | Owner |
|----------|---------|-------|
| Johnson Family Home | 45 Fox Meadow Road, Scarsdale, NY 10583 | Alice Johnson |
| Malibu Mansion | 27400 Pacific Coast Hwy, Malibu, CA 90265 | Bob Morrison |
| Beverly Hills Estate | 1200 Sunset Blvd, Beverly Hills, CA 90210 | Bob Morrison |

---

# SECTION 4: DESIGN SYSTEM

## Color Palette

### ⚠️ CRITICAL: NO BRIGHT GREEN
The old brand used bright/lime green. This is **DEPRECATED**. Use Navy + Champagne + White only.

### Navy (Primary Brand Color)
```
navy-950: #0a1929  ← Sidebar background
navy-900: #102a43  ← Primary headings, buttons
navy-800: #243b53  ← Secondary buttons, emphasis
navy-700: #334e68  ← Hover states
navy-600: #486581  ← Tertiary elements
navy-100-300: Light backgrounds, borders
```

### Champagne (Accent Color)
```
champagne-500: #c4a574  ← Primary accent, CTAs
champagne-400: #d4c4a5  ← Hover states
champagne-300: #e9dcc4  ← Light accents
champagne-100: #faf6ed  ← Subtle backgrounds
```

### Quick Reference
| Element | Color |
|---------|-------|
| Sidebar background | navy-950 (#0a1929) |
| Sidebar text | gray-300, white on active |
| Page background | gray-50 |
| Card background | white |
| Primary text | navy-900 |
| Secondary text | gray-500 |
| Primary button | navy-900 |
| Accent/CTA button | champagne-500 |
| Success indicator | Muted green (sparingly) |

### Color Replacement Map (Green → Haven)
| Old | New |
|-----|-----|
| bg-green-500 | bg-haven-champagne-500 |
| bg-green-600 | bg-haven-navy-800 |
| bg-emerald-500 | bg-haven-champagne-500 |
| text-green-600 | text-haven-champagne-600 |
| #10b981 | #c4a574 |
| #22c55e | #c4a574 |

**Exception:** Keep muted green ONLY for explicit success states (checkmarks, "Paid", "Confirmed").

---

# SECTION 5: APP STRUCTURE

## User Portals & Routes

| Portal | Route | Users |
|--------|-------|-------|
| Homeowner | `/app/*` | Bob, Alice, family |
| Manager | `/manager/*` | Sarah Chen |
| Handyman | `/handyman/*` | Mike, Carlos, Maria |
| Vendor | `/vendor/*` | Ace Roofing |
| Admin | `/admin/*` | Platform Admin |

## Homeowner Navigation
```
Dashboard          → /app           (Daily overview, action items)
Sarah              → /app/sarah     (Manager hub, approvals)
Messages           → /app/messages  (Unified inbox)
Calendar           → /app/calendar  (Family schedule)
Your Home          → /app/home      (Property details)
Family             → /app/family    (Members, vehicles, staff)
Projects           → /app/projects  (Home improvements)
Maintenance        → /app/maintenance (Systems, service)
Find Pros          → /app/find-pros (Contractor directory)
Money              → /app/money     (Bills, statements)
Tasks              → /app/tasks     (Household tasks)
Inventory          → /app/inventory (Shopping lists)
My Profile         → /app/profile   (User settings)
Settings           → /app/settings  (App preferences)
```

---

# SECTION 6: KNOWN ISSUES TO FIX

### Data Inconsistencies
1. **seed.ts** uses Burke family, **frontend mock** uses Morrison → Standardize to MORRISON
2. **My Profile** shows "Bob Smith" and "The Chen Family" → Should be Bob Morrison, The Morrison Family
3. **Settings** shows "The Miller Residence" → Should be Inspiration Farm
4. **Tasks page** shows "Jake" → Should be "Jack" (or use consistently as nickname)

### Design Inconsistencies
1. Some pages still have bright green accents → Replace with champagne
2. Some dark sections have dark text → Ensure light text on dark backgrounds

### Audit Commands
```bash
# Find remaining green
grep -rn --include="*.tsx" -E "(bg-green|text-green|bg-emerald|text-emerald)" apps/web/src/

# Find dark-on-dark contrast issues
grep -rn --include="*.tsx" -A5 "bg-haven-navy-950\|bg-haven-navy-900" apps/web/src/ | grep "text-gray-[5-9]"
```

---

# SECTION 7: KEY REMINDERS

## Always Remember
1. **Family name is MORRISON** (not Burke, Smith, or Miller)
2. **Property is 38 Bedford Road, Greenwich, CT**
3. **Manager is Sarah Chen** (sarah@haven.app)
4. **Primary Handyman is Mike Rodriguez** (mike@haven.app)
5. **Colors are Navy + Champagne + White** (NO GREEN)
6. **Children are Emma (12) and Jack (8)**

## Before Making Changes
1. Check this document for correct demo data
2. Verify color changes match the palette
3. Ensure text contrast on dark backgrounds
4. Run `pnpm build` to verify no errors

## File Locations for Common Fixes
- **Sidebar:** `apps/web/src/app/app/layout.tsx`
- **Homepage:** `apps/web/src/app/page.tsx`
- **Dashboard:** `apps/web/src/app/app/page.tsx`
- **Family page:** `apps/web/src/app/app/family/page.tsx`
- **Tailwind config:** `apps/web/tailwind.config.ts`
- **Global styles:** `apps/web/src/app/globals.css`
- **Seed data:** `apps/api/prisma/seed.ts`

---

# SECTION 8: DOCUMENTATION INDEX

These detailed documents are available in the project root:

| Document | Purpose |
|----------|---------|
| `HAVEN_BUSINESS_PLAN.md` | Full business plan, market analysis, financials |
| `HAVEN_TECHNICAL_SPEC.md` | Architecture, data models, API endpoints |
| `HAVEN_DEMO_DATA.md` | Complete canonical demo data |
| `HAVEN_DESIGN_SYSTEM_V2.md` | Full color palette, typography, components |
| `HAVEN_PROJECT_CONTEXT.md` | Quick reference for conversations |
| `CLAUDE_CODE_COLOR_MIGRATION.md` | Green → Navy/Champagne migration guide |
| `CLAUDE_CODE_CONTRAST_AUDIT.md` | Dark text on dark background fixes |

---

# SECTION 9: CURRENT STATUS

**Phase:** Pre-Launch / Demo Ready
**Focus:** Data consistency, design polish, demo preparation

### Completed
- ✅ Business plan documented
- ✅ Technical spec documented
- ✅ Demo data canonicalized
- ✅ Design system documented
- ✅ Color migration guide created
- ✅ Contrast audit guide created

### Pending
- ⏳ Fix family name inconsistencies (Morrison everywhere)
- ⏳ Remove remaining green accents
- ⏳ Fix dark-on-dark contrast issues
- ⏳ Update seed.ts to match Morrison data
- ⏳ Verify all demo credentials work

---

*This document is the master reference for all Haven development.*
*When in doubt, check here first.*

**Haven — Stop managing your home. Start living in it.**
