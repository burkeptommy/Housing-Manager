# HAVEN PROJECT CONTEXT
## Master Reference for All Development Conversations

**Last Updated:** December 24, 2025
**For:** AI Assistants, Developers, Stakeholders

---

## QUICK REFERENCE

### What is Haven?
Haven is a **full-service home management platform**. Unlike apps that give homeowners software to organize their chaos, Haven provides **dedicated Home Managers who actually do the work**—paying bills, coordinating vendors, scheduling maintenance, and handling the countless details of homeownership.

**Tagline:** "Stop managing your home. Start living in it."
**Model:** One bill. One contact. Zero hassle.

### Tech Stack
- **Frontend:** Next.js 15, React 18, Tailwind CSS, Radix UI
- **Mobile:** Expo/React Native
- **Backend:** NestJS 10, Prisma, PostgreSQL
- **Deploy:** Google Cloud Run
- **Payments:** Stripe

### Project Location
```
/Users/tomburke/Projects/Housing-Manager/
```

---

## DEMO CREDENTIALS

### Primary Demo User (Homeowner)
| Field | Value |
|-------|-------|
| **Name** | Bob Morrison |
| **Email** | bob@example.com |
| **Password** | Bob123! |
| **Property** | 38 Bedford Road, Greenwich, CT 06831 |

### Home Manager
| Field | Value |
|-------|-------|
| **Name** | Sarah Chen |
| **Email** | sarah@haven.app |
| **Password** | Manager123! |

### Handymen
| Name | Email | Password |
|------|-------|----------|
| Mike Rodriguez | mike@haven.app | Handy123! |
| Carlos Reyes | carlos@haven.app | Handy123! |
| Maria Santos | maria@haven.app | Handy123! |

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

## DEMO FAMILY: THE MORRISONS

### Family Members
| Name | Role | Age/Grade | Details |
|------|------|-----------|---------|
| Bob Morrison | Head of Household | Adult | Morrison Capital Partners |
| Alice Morrison | Spouse | Adult | Greenwich Hospital NP |
| Emma Morrison | Daughter | 12 / 7th Grade | Greenwich Country Day School |
| Jack Morrison | Son | 8 / 3rd Grade | North Street School |
| Max | Pet (Dog) | 4 years | Golden Retriever |

### Staff
| Name | Role | Agency |
|------|------|--------|
| Maria Garcia | Nanny | Greenwich Elite Nannies |

### Vehicles
| Name | Vehicle | Plate | Driver |
|------|---------|-------|--------|
| Bob's Tesla | 2023 Tesla Model Y | GRN 1234 | Bob |
| Family Highlander | 2022 Toyota Highlander | XYZ 5678 | Alice |
| Alice's Mercedes | 2024 Mercedes GLE 450 | EF-11111 | Alice |

---

## DESIGN SYSTEM

### Color Palette
- **Navy** (Primary): `#0a1929` to `#f0f4f8` — Sidebar, headings, buttons
- **Champagne** (Accent): `#c4a574` — CTAs, highlights, badges
- **White/Gray** (Neutral): `#ffffff` to `#111827` — Backgrounds, text
- **⚠️ NO BRIGHT GREEN** — Old branding, deprecated

### Quick Color Reference
| Element | Color |
|---------|-------|
| Sidebar | navy-950 (#0a1929) |
| Page background | gray-50 |
| Cards | white |
| Primary text | navy-900 |
| Accent/CTA | champagne-500 (#c4a574) |

---

## APP STRUCTURE

### User Portals
| Portal | Route | Users |
|--------|-------|-------|
| Homeowner | `/app/*` | Bob, Alice |
| Manager | `/manager/*` | Sarah |
| Handyman | `/handyman/*` | Mike, Carlos, Maria |
| Vendor | `/vendor/*` | Ace Roofing |
| Admin | `/admin/*` | Platform Admin |

### Homeowner Navigation
```
Dashboard          → /app
Sarah (Manager)    → /app/sarah
Messages           → /app/messages
Calendar           → /app/calendar
Your Home          → /app/home
Family             → /app/family
Projects           → /app/projects
Maintenance        → /app/maintenance
Find Pros          → /app/find-pros
Money              → /app/money
Tasks              → /app/tasks
Inventory          → /app/inventory
My Profile         → /app/profile
Settings           → /app/settings
```

---

## KEY FEATURES

### For Homeowners
- **Dashboard** — Daily overview, logistics, action items
- **Sarah** — Direct line to Home Manager, approvals
- **Money** — Consolidated billing, one monthly statement
- **Maintenance** — Home systems tracking, service scheduling
- **Tasks** — Family task management, leaderboard
- **Family** — Member profiles, vehicles, staff, logistics

### For Managers
- **Household Management** — Oversee multiple homes
- **Vendor Coordination** — Schedule, supervise, negotiate
- **Bill Processing** — Handle all household payments
- **Task Queue** — Items needing manager attention

### For Handymen
- **Visit Schedule** — Monthly preventive visits
- **Work Orders** — Assigned repairs and maintenance
- **Notes/Photos** — Document work completed

---

## PRICING TIERS

| Tier | Price | Key Features |
|------|-------|--------------|
| Essentials | $39/mo | Bill consolidation, tracking, reminders |
| Lite | $349/mo | + Text-based manager, reactive support |
| Haven | $749/mo | + Proactive manager, monthly handyman |
| Haven+ | $1,499/mo | + Lifestyle services, errands |
| Estate | $3,499/mo | + Multi-property, white-glove |

---

## COMMON COMMANDS

```bash
# Development
pnpm dev:web          # Start web app (localhost:3000)
pnpm dev:api          # Start API (localhost:4000)
pnpm dev:mobile       # Start Expo

# Database
cd apps/api
pnpm prisma:migrate:dev   # Run migrations
pnpm prisma:seed          # Seed demo data
pnpm prisma:studio        # GUI for database

# Build & Deploy
pnpm build
pnpm test
pnpm lint
```

---

## DOCUMENTATION INDEX

| Document | Purpose |
|----------|---------|
| `HAVEN_BUSINESS_PLAN.md` | Full business plan, market analysis, pricing |
| `HAVEN_TECHNICAL_SPEC.md` | Architecture, data models, API endpoints |
| `HAVEN_DEMO_DATA.md` | Canonical demo data (single source of truth) |
| `HAVEN_DESIGN_SYSTEM_V2.md` | Colors, typography, components |
| `README.md` | Project setup and overview |

---

## IMPORTANT REMINDERS

### Data Consistency
- Always use **Morrison** family name (not Burke, Smith, Miller)
- Property is **38 Bedford Road, Greenwich, CT**
- Manager is **Sarah Chen**
- Children are **Emma (12)** and **Jack (8)**

### Design Consistency
- **Navy + Champagne + White** color scheme
- **No bright green** — it's deprecated
- Use champagne for accents, not green

### Before Making Changes
1. Check `HAVEN_DEMO_DATA.md` for correct data
2. Check `HAVEN_DESIGN_SYSTEM_V2.md` for colors
3. Verify changes match existing screenshots

---

## CURRENT STATUS

**Phase:** Pre-Launch / Demo Ready
**Focus:** Data consistency, design polish, demo preparation
**Next:** Fix remaining inconsistencies, finalize demo flow

### Known Issues to Fix
1. My Profile page shows "Bob Smith" instead of "Bob Morrison"
2. Settings page shows "The Miller Residence" instead of "Inspiration Farm"
3. Some green accents remain from old branding
4. Frontend mock data uses Morrison but seed.ts uses Burke

---

## CONTACT

**Project Owner:** Tom Burke
**Repository:** `/Users/tomburke/Projects/Housing-Manager`

---

*This context document should be included in all Haven development conversations.*
