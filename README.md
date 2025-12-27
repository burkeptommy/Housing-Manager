# Haven Home Management Platform

**Stop managing your home. Start living in it.**

Haven is a full-service home management platform that provides dedicated Home Managers who actually do the work—paying bills, coordinating vendors, scheduling maintenance, and handling the countless details of homeownership.

---

## 🚀 Current Priority (December 27, 2024)

**Making Haven production-ready with real data flow.**

Run in Claude Code:
```
Read the prompt at prompts/003-production-ready-real-data.md and implement all phases in order.
```

This will:
1. Add database models for onboarding, activity logging, payments
2. Seed Morrison demo data (for bob@example.com only)
3. Build all API endpoints
4. Connect frontend to real APIs
5. Enable full signup → onboarding → usage flow

---

## Architecture

```
NEW USER FLOW:
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│ User Signup │ ──> │ Onboarding   │ ──> │ HM Sees in      │
│ + Address   │     │ Session      │     │ Queue           │
└─────────────┘     │ Created      │     └────────┬────────┘
                    └──────────────┘              │
                                                  ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│ User Sees   │ <── │ Data Saved   │ <── │ HM Calls User   │
│ Real Data   │     │ to Database  │     │ Uses Workbench  │
└─────────────┘     └──────────────┘     └─────────────────┘

DEMO ACCOUNT (bob@example.com):
┌─────────────┐     ┌──────────────┐
│ Login as    │ ──> │ See Morrison │
│ Bob         │     │ Demo Data    │
└─────────────┘     └──────────────┘
```

---

## Quick Links

| Resource | Location |
|----------|----------|
| **Project Root** | `/Users/tomburke/Projects/Housing-Manager/` |
| **Production Web** | https://havenhome.dev |
| **Production API** | https://api.havenhome.dev |
| **GCP Project** | home-manager-480616 |
| **Prompts** | `/prompts/` |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Next.js 15, React 18, Tailwind CSS |
| Backend | NestJS 10, Prisma ORM, PostgreSQL |
| Auth | Firebase Authentication |
| Payments | Stripe (planned) |
| Property Data | ATTOM API |
| Deploy | Google Cloud Run |

---

## Demo Account

**Bob Morrison (demo user with pre-populated data):**
- Email: `bob@example.com`
- Property: Inspiration Farm, 38 Bedford Road, Greenwich, CT 06831
- Family: Alice (spouse), Emma (12), Jack (8), Max (dog), Maria Garcia (nanny)
- Vehicles: Tesla Model Y, Toyota Highlander, Mercedes GLE 450
- Home Manager: Sarah Chen

**All other users** get real data captured through onboarding.

---

## Development Commands

```bash
# Start development
pnpm dev:web          # localhost:3000
pnpm dev:api          # localhost:4000

# Database
cd apps/api
pnpm prisma migrate dev    # Run migrations
pnpm prisma db seed        # Seed demo data
pnpm prisma studio         # Database GUI

# Build & Deploy
pnpm build
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## Service Tiers

| Tier | Price | Features |
|------|-------|----------|
| Essentials | $39/mo | Bill tracking |
| Lite | $349/mo | + Text-based manager |
| **Haven** | $749/mo | + Proactive manager, handyman |
| Haven+ | $1,499/mo | + Lifestyle services |
| Estate | $3,499/mo | + Multi-property |

---

## Project Structure

```
/apps
  /api              # NestJS backend
    /src
      /auth         # Firebase auth
      /dashboard    # Dashboard API
      /property     # Property + zones API
      /family       # Family members API  
      /onboarding   # Onboarding flow API
      /activity     # Activity logging
    /prisma         # Schema + migrations + seed
  /web              # Next.js frontend
    /src/app
      /app          # Homeowner portal
      /manager      # Home Manager portal
      /onboarding   # Signup flow
/prompts            # Claude Code implementation prompts
```

---

## API Endpoints

### Homeowner Portal
| Endpoint | Description |
|----------|-------------|
| `GET /dashboard/household/:id` | Dashboard summary |
| `GET /property/household/:id` | Property + zones + assets |
| `GET /family/household/:id` | Family members, vehicles |
| `GET /bills/household/:id` | Bills and payments |

### Onboarding
| Endpoint | Description |
|----------|-------------|
| `POST /onboarding` | Create session on signup |
| `GET /onboarding/queue` | HM queue of pending users |
| `GET /onboarding/:id` | Get session for intake |
| `PUT /onboarding/:id/intake` | Save intake data |
| `POST /onboarding/:id/complete` | Complete intake |

---

## Status

### ✅ Completed
- Firebase Auth (Email + Google)
- User signup flow with address capture
- ATTOM property enrichment
- Polished demo pages (Dashboard, Your Home, Family)
- Design system (Navy + Champagne)

### 🚀 In Progress (Prompt 003)
- Database schema for onboarding/activity
- Morrison seed data
- API endpoints for all pages
- Frontend ↔ API connection
- Onboarding queue and intake workbench

### ⏳ Next
- Approval system (HM requests → Homeowner approves)
- Handyman portal
- Messaging system
- Calendar integration

---

**Haven — Stop managing your home. Start living in it.**
