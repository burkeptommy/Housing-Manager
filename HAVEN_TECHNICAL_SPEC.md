# HAVEN TECHNICAL SPECIFICATION
## Full-Service Home Management Platform

**Last Updated:** December 24, 2025
**Version:** 1.0

---

## 1. SYSTEM ARCHITECTURE

### Overview

Haven is a monorepo-based application with three main entry points:
- **Web Application** (Next.js 15) — Primary interface for homeowners, managers, vendors
- **Mobile Application** (React Native/Expo) — On-the-go access for all users
- **API Server** (NestJS) — Backend services and business logic

### Repository Structure

```
/Users/tomburke/Projects/Housing-Manager/
├── apps/
│   ├── api/                    # NestJS backend
│   │   ├── prisma/             # Database schema, migrations, seed
│   │   │   ├── schema.prisma   # Prisma schema definition
│   │   │   ├── migrations/     # Database migrations
│   │   │   └── seed.ts         # Demo data seeding
│   │   └── src/
│   │       ├── auth/           # Authentication module
│   │       ├── users/          # User management
│   │       ├── households/     # Household/property management
│   │       ├── bills/          # Bill consolidation
│   │       ├── maintenance/    # Maintenance scheduling
│   │       ├── tasks/          # Task management
│   │       └── ...
│   │
│   ├── web/                    # Next.js frontend
│   │   └── src/
│   │       ├── app/            # App Router pages
│   │       │   ├── (marketing)/  # Public marketing pages
│   │       │   ├── app/          # Authenticated homeowner portal
│   │       │   ├── manager/      # Manager portal
│   │       │   ├── handyman/     # Handyman portal
│   │       │   └── vendor/       # Vendor portal
│   │       ├── components/     # React components
│   │       ├── lib/            # Utilities, API client
│   │       └── styles/         # Global styles
│   │
│   └── mobile/                 # Expo React Native
│       └── src/
│           ├── screens/        # Screen components
│           ├── components/     # Shared components
│           └── navigation/     # Navigation config
│
├── packages/
│   ├── config/                 # Shared ESLint, TypeScript configs
│   ├── core/                   # Shared types, schemas, constants
│   │   ├── types/              # TypeScript interfaces
│   │   ├── schemas/            # Zod validation schemas
│   │   └── constants/          # Shared constants
│   └── ui/                     # Shared React components
│       └── components/         # Design system components
│
├── scripts/                    # Build and deployment scripts
├── docker-compose.yml          # Local development services
├── pnpm-workspace.yaml         # Monorepo configuration
└── package.json                # Root package scripts
```

---

## 2. TECHNOLOGY STACK

### Frontend (Web)

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| Framework | Next.js | 15.x | React framework with App Router |
| UI Library | React | 18.x | Component library |
| Styling | Tailwind CSS | 3.x | Utility-first CSS |
| Components | Radix UI | Latest | Headless accessible components |
| Icons | Lucide React | Latest | Icon system |
| Forms | React Hook Form | 7.x | Form state management |
| Validation | Zod | 3.x | Schema validation |
| State | TanStack Query | 5.x | Server state management |
| Maps | Mapbox GL | 3.x | Interactive maps |
| Charts | Recharts | 2.x | Data visualization |
| Date Handling | date-fns | 3.x | Date utilities |

### Frontend (Mobile)

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| Framework | Expo | 50+ | React Native development |
| Navigation | Expo Router | 3.x | File-based routing |
| UI Components | Native Base / Tamagui | Latest | Cross-platform components |

### Backend

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| Framework | NestJS | 10.x | Node.js framework |
| ORM | Prisma | 5.x | Database ORM |
| Database | PostgreSQL | 15.x | Primary data store |
| Cache | Redis | 7.x | Caching, sessions |
| Queue | Bull | 4.x | Job queue |
| Auth | Passport/JWT | Latest | Authentication |
| Validation | class-validator | Latest | DTO validation |

### Infrastructure

| Service | Provider | Purpose |
|---------|----------|---------|
| Hosting | Google Cloud Run | Containerized deployments |
| Database | Cloud SQL (PostgreSQL) | Managed database |
| Storage | Google Cloud Storage | File/document storage |
| CDN | Cloudflare | Edge caching |
| Email | Resend / SendGrid | Transactional email |
| SMS | Twilio | SMS notifications |
| Payments | Stripe | Billing, card issuing |

---

## 3. USER ROLES & PORTALS

### Role Hierarchy

```
Platform Admin
    │
    ├── Home Manager (Sarah)
    │       │
    │       ├── Homeowner (Bob)
    │       │       └── Family Members (Alice, Emma, Jack)
    │       │
    │       └── Vendors (Ace Roofing)
    │
    └── Handyman (Mike, Carlos, Maria)
```

### Portal Routes

| Role | Portal | Route Prefix | Access Level |
|------|--------|--------------|--------------|
| Homeowner | Homeowner App | `/app/*` | Own household data |
| Family Member | Homeowner App | `/app/*` | Limited household access |
| Home Manager | Manager Hub | `/manager/*` | Assigned households |
| Handyman | Handyman Portal | `/handyman/*` | Assigned households |
| Vendor | Vendor Portal | `/vendor/*` | Assigned projects |
| Admin | Admin Dashboard | `/admin/*` | Full platform access |

### Role Permissions Matrix

| Feature | Homeowner | Family | Manager | Handyman | Vendor | Admin |
|---------|-----------|--------|---------|----------|--------|-------|
| View Dashboard | ✅ Own | ✅ Own | ✅ Assigned | ✅ Assigned | ❌ | ✅ All |
| Edit Family | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ |
| Approve Bills | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Schedule Service | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ |
| Complete Tasks | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| View Financials | ✅ | ❌ | ✅ | ❌ | Own | ✅ |
| Manage Vendors | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |

---

## 4. DATA MODELS

### Core Entities

```prisma
// User - All authenticated users
model User {
  id            String    @id @default(cuid())
  email         String    @unique
  name          String
  role          UserRole  @default(HOMEOWNER)
  phone         String?
  avatarUrl     String?
  
  // Relations
  households    HouseholdMember[]
  managedHouseholds Household[] @relation("Manager")
  
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}

enum UserRole {
  ADMIN
  MANAGER
  HOMEOWNER
  HANDYMAN
  VENDOR
}

// Household - A managed property
model Household {
  id            String    @id @default(cuid())
  name          String
  address       String
  city          String
  state         String
  zip           String
  
  // Property details
  bedrooms      Int?
  bathrooms     Float?
  sqft          Int?
  acreage       Float?
  yearBuilt     Int?
  
  // Relations
  managerId     String?
  manager       User?     @relation("Manager", fields: [managerId], references: [id])
  handymanId    String?
  members       HouseholdMember[]
  systems       HomeSystem[]
  bills         Bill[]
  tasks         Task[]
  projects      Project[]
  vehicles      Vehicle[]
  pets          Pet[]
  
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}

// HouseholdMember - User-Household relationship
model HouseholdMember {
  id            String    @id @default(cuid())
  userId        String
  user          User      @relation(fields: [userId], references: [id])
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  role          MemberRole @default(MEMBER)
  
  @@unique([userId, householdId])
}

enum MemberRole {
  HEAD_OF_HOUSEHOLD
  SPOUSE
  CHILD
  STAFF
  MEMBER
}

// FamilyMember - Non-user household members (children, pets)
model FamilyMember {
  id            String    @id @default(cuid())
  householdId   String
  name          String
  type          FamilyMemberType
  
  // For children
  birthDate     DateTime?
  grade         String?
  school        String?
  
  // For pets
  species       String?
  breed         String?
  
  allergies     String[]
  notes         String?
}

enum FamilyMemberType {
  CHILD
  PET
  STAFF
}

// Bill - Consolidated billing
model Bill {
  id            String    @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  
  vendorName    String
  category      BillCategory
  amount        Decimal
  dueDate       DateTime
  paidDate      DateTime?
  status        BillStatus @default(PENDING)
  
  createdAt     DateTime  @default(now())
}

enum BillCategory {
  MORTGAGE
  UTILITIES
  INSURANCE
  MAINTENANCE
  SUBSCRIPTIONS
  CHILDCARE
  ACTIVITIES
  PET_CARE
  OTHER
}

enum BillStatus {
  PENDING
  SCHEDULED
  PAID
  OVERDUE
}

// HomeSystem - Tracked home systems
model HomeSystem {
  id            String    @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  
  name          String    // "Main HVAC System"
  type          SystemType
  make          String?   // "Carrier"
  model         String?   // "Infinity 26"
  installDate   DateTime?
  expectedLife  Int?      // Years
  
  // Service tracking
  lastServiceDate DateTime?
  lastServiceBy   String?
  nextServiceDate DateTime?
  
  status        SystemStatus @default(GOOD)
  warrantyExpires DateTime?
  
  documents     Document[]
  serviceHistory ServiceRecord[]
}

enum SystemType {
  HVAC
  PLUMBING
  ELECTRICAL
  ROOFING
  APPLIANCE
  POOL
  SECURITY
  IRRIGATION
  GENERATOR
  OTHER
}

enum SystemStatus {
  EXCELLENT
  GOOD
  DUE_SOON
  NEEDS_ATTENTION
  CRITICAL
}

// Task - Household tasks
model Task {
  id            String    @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  
  title         String
  description   String?
  assignedTo    String?   // User ID or family member name
  dueDate       DateTime?
  
  type          TaskType  @default(HOUSEHOLD)
  recurrence    String?   // "daily", "weekly", etc.
  
  status        TaskStatus @default(PENDING)
  completedAt   DateTime?
  completedBy   String?
  
  createdAt     DateTime  @default(now())
}

enum TaskType {
  HOUSEHOLD
  MANAGER
  MAINTENANCE
  ERRAND
}

enum TaskStatus {
  PENDING
  IN_PROGRESS
  COMPLETED
  CANCELLED
}
```

---

## 5. API ENDPOINTS

### Authentication

```
POST   /auth/login           # Login with email/password
POST   /auth/register        # Create new account
POST   /auth/refresh         # Refresh access token
POST   /auth/logout          # Invalidate tokens
POST   /auth/forgot-password # Request password reset
POST   /auth/reset-password  # Reset password with token
```

### Users

```
GET    /users/me             # Get current user profile
PATCH  /users/me             # Update current user
GET    /users/:id            # Get user by ID (admin)
```

### Households

```
GET    /households           # List user's households
POST   /households           # Create household
GET    /households/:id       # Get household details
PATCH  /households/:id       # Update household
DELETE /households/:id       # Delete household

GET    /households/:id/members    # List household members
POST   /households/:id/members    # Add member
DELETE /households/:id/members/:memberId  # Remove member

GET    /households/:id/family     # Get family data (children, pets, staff)
```

### Bills

```
GET    /households/:id/bills      # List bills
POST   /households/:id/bills      # Create bill
GET    /households/:id/bills/:billId  # Get bill details
PATCH  /households/:id/bills/:billId  # Update bill
POST   /households/:id/bills/:billId/pay  # Mark as paid

GET    /households/:id/statements # Get monthly statements
```

### Maintenance

```
GET    /households/:id/systems    # List home systems
POST   /households/:id/systems    # Add system
PATCH  /households/:id/systems/:systemId  # Update system

GET    /households/:id/maintenance/schedule  # Get maintenance schedule
POST   /households/:id/maintenance/service   # Schedule service

GET    /households/:id/maintenance/health    # Get home health score
```

### Tasks

```
GET    /households/:id/tasks      # List tasks
POST   /households/:id/tasks      # Create task
PATCH  /households/:id/tasks/:taskId  # Update task
POST   /households/:id/tasks/:taskId/complete  # Mark complete
```

### Manager-Specific

```
GET    /manager/households        # List managed households
GET    /manager/queue             # Get manager queue items
POST   /manager/queue/:id/complete  # Complete queue item
GET    /manager/activity          # Get manager activity feed
```

---

## 6. AUTHENTICATION & SECURITY

### JWT Token Structure

```typescript
// Access Token (15 min expiry)
{
  sub: "user_id",
  email: "user@example.com",
  role: "HOMEOWNER",
  households: ["household_id_1", "household_id_2"],
  iat: timestamp,
  exp: timestamp
}

// Refresh Token (7 day expiry)
{
  sub: "user_id",
  type: "refresh",
  jti: "unique_token_id",
  iat: timestamp,
  exp: timestamp
}
```

### Security Measures

- **Password Hashing:** bcrypt with salt rounds
- **Token Rotation:** Refresh tokens rotated on use
- **HTTPS Only:** All traffic encrypted
- **CORS:** Configured for specific origins
- **Rate Limiting:** API rate limits per endpoint
- **Input Validation:** All inputs validated with Zod/class-validator
- **SQL Injection:** Prevented via Prisma parameterized queries
- **XSS Prevention:** Content Security Policy headers

---

## 7. FRONTEND ARCHITECTURE

### Page Structure (App Router)

```
app/
├── (marketing)/              # Public pages
│   ├── page.tsx              # Homepage
│   ├── pricing/page.tsx      # Pricing
│   ├── how-it-works/page.tsx
│   └── login/page.tsx
│
├── app/                      # Homeowner portal (authenticated)
│   ├── layout.tsx            # App shell with sidebar
│   ├── page.tsx              # Dashboard
│   ├── sarah/page.tsx        # Manager hub
│   ├── messages/page.tsx     # Messages
│   ├── calendar/page.tsx     # Calendar
│   ├── home/page.tsx         # Your Home
│   ├── family/page.tsx       # Family management
│   ├── projects/page.tsx     # Projects
│   ├── maintenance/page.tsx  # Maintenance
│   ├── find-pros/page.tsx    # Contractor search
│   ├── money/page.tsx        # Financials
│   ├── tasks/page.tsx        # Tasks
│   ├── inventory/page.tsx    # Inventory/Shopping
│   ├── profile/page.tsx      # My Profile
│   └── settings/page.tsx     # Settings
│
├── manager/                  # Manager portal
│   ├── layout.tsx
│   ├── page.tsx              # Manager dashboard
│   ├── households/page.tsx   # Managed households
│   └── queue/page.tsx        # Work queue
│
├── handyman/                 # Handyman portal
│   ├── layout.tsx
│   ├── page.tsx              # Handyman dashboard
│   └── visits/page.tsx       # Scheduled visits
│
└── vendor/                   # Vendor portal
    ├── layout.tsx
    ├── page.tsx              # Vendor dashboard
    └── projects/page.tsx     # Active projects
```

### Component Organization

```
components/
├── layout/
│   ├── Sidebar.tsx
│   ├── Header.tsx
│   ├── MobileNav.tsx
│   └── Footer.tsx
│
├── ui/                       # Design system components
│   ├── Button.tsx
│   ├── Card.tsx
│   ├── Dialog.tsx
│   ├── Input.tsx
│   └── ...
│
├── dashboard/
│   ├── DashboardHeader.tsx
│   ├── TodaysLogistics.tsx
│   ├── HomeHealthCard.tsx
│   └── QuickActions.tsx
│
├── family/
│   ├── AdultCard.tsx
│   ├── ChildCard.tsx
│   ├── PetCard.tsx
│   ├── VehicleCard.tsx
│   └── StaffCard.tsx
│
├── maintenance/
│   ├── SystemCard.tsx
│   ├── ServiceSchedule.tsx
│   └── HandymanVisit.tsx
│
└── money/
    ├── StatementCard.tsx
    ├── BillsList.tsx
    └── ApprovalCard.tsx
```

---

## 8. DEVELOPMENT WORKFLOW

### Local Development

```bash
# Clone and install
git clone [repository]
cd Housing-Manager
pnpm install

# Start services
docker-compose up -d postgres redis

# Setup database
cd apps/api
pnpm prisma:migrate:dev
pnpm prisma:seed

# Start development servers
pnpm dev:api      # localhost:4000
pnpm dev:web      # localhost:3000
pnpm dev:mobile   # Expo dev server
```

### Environment Variables

```env
# apps/api/.env
DATABASE_URL="postgresql://haven:haven@localhost:5432/haven"
JWT_SECRET="your-jwt-secret"
JWT_REFRESH_SECRET="your-refresh-secret"
REDIS_URL="redis://localhost:6379"

# apps/web/.env.local
NEXT_PUBLIC_API_URL="http://localhost:4000"
NEXT_PUBLIC_MAPBOX_TOKEN="your-mapbox-token"
```

### Testing

```bash
# Unit tests
pnpm test

# E2E tests
pnpm test:e2e

# Type checking
pnpm typecheck

# Linting
pnpm lint
```

### Deployment

```bash
# Build all apps
pnpm build

# Deploy API
gcloud run deploy haven-api --source apps/api

# Deploy Web
gcloud run deploy haven-web --source apps/web
```

---

## 9. INTEGRATIONS

### Stripe (Payments)

- **Billing:** Subscription management
- **Connect:** Vendor payouts
- **Issuing:** Haven corporate cards for bill payment

### Communication

- **Resend/SendGrid:** Transactional email
- **Twilio:** SMS notifications, voice calls

### Maps & Location

- **Mapbox:** Interactive maps, contractor locations
- **Google Maps API:** Address autocomplete, geocoding

### Storage

- **Google Cloud Storage:** Document storage, photos
- **Cloudflare Images:** Image optimization and CDN

### Calendar

- **Google Calendar API:** Calendar sync
- **Apple Calendar:** CalDAV integration

---

## 10. MONITORING & OBSERVABILITY

### Logging

- **Structured Logging:** JSON format with Winston
- **Log Levels:** error, warn, info, debug
- **Log Aggregation:** Google Cloud Logging

### Metrics

- **Application Metrics:** Custom business metrics
- **Infrastructure Metrics:** Cloud Monitoring
- **Performance Metrics:** Web Vitals, API response times

### Alerting

- **Error Alerts:** Sentry integration
- **Uptime Monitoring:** Uptime Robot / Better Stack
- **SLA Monitoring:** Response time alerts

---

## 11. FUTURE CONSIDERATIONS

### Scalability

- **Horizontal Scaling:** Stateless API design
- **Database Sharding:** By geographic region
- **Caching Strategy:** Redis for hot data
- **CDN:** Static assets and images

### Features Roadmap

- [ ] AI-powered maintenance predictions
- [ ] Smart home integrations (Ring, Nest, etc.)
- [ ] Voice assistant support (Alexa, Google)
- [ ] Native mobile apps (beyond Expo)
- [ ] Multi-language support
- [ ] White-label platform for property managers

---

*Last updated: December 24, 2025*
