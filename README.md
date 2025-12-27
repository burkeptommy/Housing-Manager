# Haven Home Management Platform

**Stop managing your home. Start living in it.**

Haven is a full-service home management platform that provides dedicated Home Managers who actually do the work—paying bills, coordinating vendors, scheduling maintenance, and handling the countless details of homeownership.

---

## ⚠️ Current Priority (December 27, 2024)

**RUN THIS FIRST in Claude Code:**
```
Read the prompt at prompts/000-RESTORE-polished-pages.md and execute all phases in order.
```

This restores the polished Dashboard, Your Home, and Family pages that were accidentally overwritten.

---

## Quick Links

| Resource | Location |
|----------|----------|
| **Project Root** | `/Users/tomburke/Projects/Housing-Manager/` |
| **Production Web** | https://havenhome.dev |
| **Production API** | https://api.havenhome.dev |
| **GCP Project** | home-manager-480616 |
| **Development Prompts** | `/prompts/` |

---

## Current Status

### 🚨 Needs Immediate Fix
- Dashboard, Your Home, Family pages were overwritten - **Run prompt 000 to restore**

### ✅ Completed
- Firebase Auth (Email/Password + Google Sign-In)
- Cloud SQL database
- Cloud Run services
- ATTOM Property API integration
- Google Places autocomplete
- Design system (Navy + Champagne)
- Polished demo pages (need restore)

### ⏳ After Restore
- Home Manager intake workbench (prompt 002)
- Approval system
- Handyman portal
- Messaging

---

## Canonical Demo Data (Morrison Family)

**ALL pages and seed data MUST use this exact data:**

### Property
```
Name: Inspiration Farm
Address: 38 Bedford Road, Greenwich, CT 06831
Specs: 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres
Year Built: 1998
Home Health: 94/100 (Excellent)
```

### Family
| Person | Role | Key Details |
|--------|------|-------------|
| Bob Morrison | Head of Household | bob@example.com, (203) 555-0101 |
| Alice Morrison | Spouse | alice@example.com, (203) 555-0102 |
| Emma Morrison | Daughter, 12 | 7th Grade, Greenwich Country Day, Allergies: Peanuts/Tree nuts |
| Jack Morrison | Son, 8 | 3rd Grade, North Street School |
| Max | Golden Retriever | 4 years, Vet: Dr. Williams |
| Maria Garcia | Nanny | $1,500/week, Mon-Fri |

### Vehicles
| Vehicle | Driver | Monthly Cost |
|---------|--------|--------------|
| 2023 Tesla Model Y | Bob | $895 |
| 2022 Toyota Highlander | Alice | $775 |
| 2024 Mercedes GLE 450 | Alice | $1,082 |

### Haven Team
| Role | Name | Email |
|------|------|-------|
| Home Manager | Sarah Chen | sarah@haven.app |
| Handyman | Mike Rodriguez | mike@haven.app |

---

## Development Commands

```bash
# Start development
pnpm dev:web          # localhost:3000
pnpm dev:api          # localhost:4000

# Database
cd apps/api
pnpm prisma:migrate:dev
pnpm prisma:seed
pnpm prisma:studio

# Build & Deploy
pnpm build
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
```

---

## Architecture

```
/apps
  /api          # NestJS backend
  /web          # Next.js frontend
  /mobile       # Expo (future)
/packages
  /config       # Shared configs
  /core         # Shared types
  /ui           # Shared components
/prompts        # Claude Code implementation prompts
```

---

## Design System

**Colors (NO BRIGHT GREEN):**
- Navy: #0a1929 (sidebar), #102a43 (headings)
- Champagne: #c4a574 (accents, CTAs)
- White/Gray: backgrounds, cards

---

## Service Tiers

| Tier | Price | Features |
|------|-------|----------|
| Essentials | $39/mo | Bill tracking |
| Lite | $349/mo | + Text-based manager |
| Haven | $749/mo | + Proactive manager, handyman |
| Haven+ | $1,499/mo | + Lifestyle services |
| Estate | $3,499/mo | + Multi-property |

---

## Next Session Checklist

1. Run `prompts/000-RESTORE-polished-pages.md` first
2. Verify pages show correct Morrison data
3. Continue with `prompts/002-home-manager-intake-workbench.md`
4. Then build approval system, handyman portal

---

**Haven — Stop managing your home. Start living in it.**
