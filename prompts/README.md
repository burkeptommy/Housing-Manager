# Haven Development Prompts

This folder contains implementation prompts for Claude Code.

---

## ⚠️ CRITICAL: Read Before Running Any Prompt

1. **Always run `000-RESTORE-polished-pages.md` first** if pages are broken
2. **Never overwrite polished frontend pages** with API-connected versions until APIs work
3. **Always use Morrison demo data** - see canonical data below

---

## Prompt Index

| # | File | Description | Status |
|---|------|-------------|--------|
| **000** | `000-RESTORE-polished-pages.md` | **RUN FIRST** - Restores Dashboard, Your Home, Family pages | 🚨 Run if pages broken |
| 001 | `001-homeowner-portal-production-ready.md` | Backend APIs only (ignore frontend sections) | ⚠️ Backend Only |
| 002 | `002-home-manager-intake-workbench.md` | Home Manager intake tool | ⏳ After 000 |

---

## How to Run in Claude Code

```
Read the prompt at prompts/000-RESTORE-polished-pages.md and execute all phases in order.
```

---

## Canonical Morrison Demo Data

**ALWAYS use this exact data in all pages and seed files:**

### Property
- **Name:** Inspiration Farm
- **Address:** 38 Bedford Road, Greenwich, CT 06831
- **Specs:** 5 bed, 5.5 bath, 5,765 sqft, 2.0 acres, Built 1998
- **Home Health:** 94/100 (Excellent)

### Family
| Person | Role | Details |
|--------|------|---------|
| Bob Morrison | Head of Household | bob@example.com, (203) 555-0101 |
| Alice Morrison | Spouse | alice@example.com, (203) 555-0102 |
| Emma Morrison | Daughter, 12 | 7th Grade, Greenwich Country Day, Allergies: Peanuts/Tree nuts |
| Jack Morrison | Son, 8 | 3rd Grade, North Street School |
| Max | Pet | Golden Retriever, 4 years, Dr. Williams vet |
| Maria Garcia | Nanny | (203) 555-0199, $1,500/week |

### Vehicles
| Vehicle | Driver | Monthly Cost |
|---------|--------|--------------|
| 2023 Tesla Model Y (GRN 1234) | Bob | $895 |
| 2022 Toyota Highlander (XYZ 5678) | Alice | $775 |
| 2024 Mercedes GLE 450 (EF-11111) | Alice | $1,082 |

### Haven Team
| Role | Name | Email |
|------|------|-------|
| Home Manager | Sarah Chen | sarah@haven.app |
| Handyman | Mike Rodriguez | mike@haven.app |

### Monthly Lifestyle Costs: $17,422
- Club Memberships: $2,550
- Education & Activities: $5,475
- Childcare: $6,495
- Pet Care: $150
- Auto: $2,752

---

## What Each Page Should Show

### Dashboard (`/app`)
- Greeting with Bob's name
- Weather (68°)
- Home Health 94%
- Today's Notes (3 items)
- Approval cards (roof repair, nanny contract)
- Sarah Chen card with current tasks
- Today's Logistics (family locations)
- Quick Actions

### Your Home (`/app/home`)
- Header: "38 Bedford Road" (NOT "Bob's Villa")
- Tabs: Overview, Maintenance, Systems, Vendors, Vehicles, Financial, Documents
- Home Health donut chart (94/100)
- Systems Status list
- Upcoming services
- Recent Activity

### Family (`/app/family`)
- Smart Alerts (5 items)
- Today's Logistics
- Monthly Lifestyle Costs ($17,422)
- Adults, Children, Pets, Staff, Vehicles sections
- All data matches canonical above

---

## Project Location

```
/Users/tomburke/Projects/Housing-Manager/
```
