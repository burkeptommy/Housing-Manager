# Haven Home Manager

A SaaS home-management platform with web app, mobile app, and backend API.

## Tech Stack

- **Monorepo**: pnpm workspaces
- **Web**: Next.js 15 (App Router) + Tailwind CSS
- **Mobile**: Expo React Native
- **API**: NestJS + Prisma ORM
- **Database**: PostgreSQL
- **Auth**: JWT with refresh token rotation
- **Storage**: Google Cloud Storage (file uploads)
- **Shared**: TypeScript strict mode, ESLint, Prettier, Vitest/Jest

## Project Structure

```
haven-home-manager/
├── apps/
│   ├── api/          # NestJS backend
│   ├── mobile/       # Expo React Native app
│   └── web/          # Next.js 15 web app
├── packages/
│   ├── config/       # Shared ESLint/TS/Jest configs
│   ├── core/         # Shared types, Zod schemas, API client
│   └── ui/           # Shared React UI components
├── docker-compose.yml
├── DEPLOYMENT.md     # GCP deployment guide
├── package.json
├── pnpm-workspace.yaml
└── tsconfig.json
```

## Quick Start

```bash
# 1. Install dependencies
pnpm install

# 2. Start PostgreSQL
docker-compose up -d postgres

# 3. Configure environment
cp apps/api/.env.example apps/api/.env

# 4. Run migrations and seed demo data
cd apps/api && pnpm prisma:migrate:dev && pnpm prisma:seed && cd ../..

# 5. Build shared packages
pnpm -r --filter "@haven/core" --filter "@haven/ui" build

# 6. Start all apps (in separate terminals)
pnpm dev:api    # Backend at http://localhost:4000
pnpm dev:web    # Web app at http://localhost:3000
pnpm dev:mobile # Mobile with Expo

# Login with: demo@haven.app / Demo123!
```

## Prerequisites

- Node.js 20+
- pnpm 9+
- PostgreSQL 15+ (or Docker)

## Getting Started

### 1. Install Dependencies

```bash
pnpm install
```

### 2. Set Up Environment Variables

#### API Backend

Copy the example environment file:

```bash
cp apps/api/.env.example apps/api/.env
```

Required environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:postgres@localhost:5432/haven_db` |
| `JWT_SECRET` | Secret key for JWT tokens (min 32 chars) | `your-super-secret-key-here` |
| `JWT_ACCESS_EXPIRES_IN` | Access token expiry in seconds | `900` (15 min) |
| `JWT_REFRESH_EXPIRES_DAYS` | Refresh token expiry in days | `7` |
| `PORT` | API server port | `4000` |
| `CORS_ORIGIN` | Allowed CORS origins | `http://localhost:3000` |

Optional variables (for file uploads):

| Variable | Description |
|----------|-------------|
| `GCP_PROJECT_ID` | Google Cloud Project ID |
| `GCS_BUCKET_NAME` | GCS bucket for file uploads |
| `STRIPE_SECRET_KEY` | Stripe API key for billing |

#### Web App

Create `apps/web/.env.local`:

```bash
NEXT_PUBLIC_API_URL=http://localhost:4000/api
```

#### Mobile App

Create `apps/mobile/.env`:

```bash
EXPO_PUBLIC_API_URL=http://localhost:4000/api
```

### 3. Set Up Database

Start PostgreSQL using Docker:

```bash
docker-compose up -d postgres
```

Or connect to an existing PostgreSQL instance by updating `DATABASE_URL` in `apps/api/.env`.

Run database migrations:

```bash
cd apps/api
pnpm prisma:migrate:dev
```

Seed the database with demo data:

```bash
cd apps/api
pnpm prisma:seed
```

This creates a complete demo environment:
- **14 maintenance templates** for seasonal home care
- **Demo users** with different roles (see credentials below)
- **Demo household** ("The Johnson Residence") with full property details
- **13 vendors** covering all home service categories
- **11 bill accounts** with realistic frequencies and amounts
- **17 maintenance tasks** across 12 months
- **Sample service requests** and subscription data

### 4. Build Shared Packages

```bash
pnpm -r --filter "@haven/core" --filter "@haven/ui" build
```

### 5. Run Applications

#### All Services (Recommended)

Using Docker Compose:

```bash
docker-compose up
```

This starts PostgreSQL, Redis, and MinIO (S3-compatible storage for local dev).

#### Web App (Next.js)

```bash
pnpm dev:web
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

#### API Server (NestJS)

```bash
pnpm dev:api
```

API runs at [http://localhost:4000/api](http://localhost:4000/api).
Swagger docs: [http://localhost:4000/api/docs](http://localhost:4000/api/docs).

#### Mobile App (Expo)

```bash
pnpm dev:mobile
```

- Press `i` for iOS simulator
- Press `a` for Android emulator
- Scan QR code with Expo Go app on physical device

## Demo Credentials

After running the seed script, these demo accounts are available:

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@haven.app | Admin123! |
| Manager | manager@haven.app | Manager123! |
| Homeowner | demo@haven.app | Demo123! |

### Stripe Test Cards

For testing payments and subscriptions in development:

| Card Number | Description |
|-------------|-------------|
| `4242 4242 4242 4242` | Successful payment |
| `4000 0000 0000 3220` | 3D Secure authentication required |
| `4000 0000 0000 9995` | Payment declined |

Use any future expiry date (e.g., 12/34) and any 3-digit CVC.

### Demo Household Details

The homeowner account (`demo@haven.app`) comes with a pre-configured household:

**Property: The Johnson Residence**
- Single family home, 2,800 sq ft, built 2015
- 3 bedrooms, 2.5 bathrooms
- Features: Pool, septic system, chimney, sprinkler system, lawn

**Vendors (13 configured):**
- Mortgage: First National Bank ($2,450/mo)
- Utilities: PowerGrid Electric, Metro Gas, CityWater, TrashAway
- Services: FastNet Internet, GreenLawn Care, BugGuard Pest Control
- Seasonal: SnowClear, Chimney Masters, Septic Solutions, AquaPool

**Bill Accounts** with realistic amounts and billing frequencies

**Maintenance Tasks** for 12 months covering:
- HVAC filter changes, gutter cleaning, smoke detector testing
- Seasonal tasks: lawn aeration, pool winterization, chimney inspection
- Appliance maintenance: water heater flush, refrigerator coils

## Running Tests

### Backend Tests (Jest)

```bash
cd apps/api
pnpm test           # Run all tests
pnpm test:watch     # Watch mode
pnpm test:cov       # With coverage
```

### Frontend Tests (Vitest)

```bash
cd apps/web
pnpm test           # Run all tests
pnpm test:watch     # Watch mode
pnpm test:coverage  # With coverage
```

### Run All Tests

```bash
pnpm test
```

## Database Management

### Prisma Commands

```bash
cd apps/api

# Generate Prisma client after schema changes
pnpm prisma:generate

# Create a new migration
pnpm prisma:migrate:dev

# Apply migrations in production
pnpm prisma:migrate:deploy

# Open Prisma Studio (database GUI)
pnpm prisma:studio

# Reset database (drops all data)
pnpm db:reset

# Run seed script
pnpm prisma:seed
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `pnpm dev:web` | Start web app in development mode |
| `pnpm dev:api` | Start API server in development mode |
| `pnpm dev:mobile` | Start Expo development server |
| `pnpm build` | Build all packages and apps |
| `pnpm lint` | Run ESLint across all packages |
| `pnpm test` | Run tests across all packages |
| `pnpm format` | Format code with Prettier |
| `pnpm typecheck` | Run TypeScript type checking |
| `pnpm clean` | Remove all build artifacts |

## Shared Packages

### @haven/core

Contains shared TypeScript types, Zod validation schemas, and API client wrapper.

```typescript
import { User, Household, ServiceRequest } from '@haven/core';
import { createApiClient, ApiClient } from '@haven/core';
```

### @haven/ui

Shared React UI components using Tailwind CSS.

```typescript
import { Button, Card, Input } from '@haven/ui';
```

### @haven/config

Shared configuration for ESLint, TypeScript, and Jest.

```javascript
// .eslintrc.js
module.exports = {
  extends: [require.resolve('@haven/config/eslint/react')],
};
```

## User Roles

| Role | Description | Access |
|------|-------------|--------|
| `ADMIN` | System administrator | Full access, admin panel |
| `MANAGER` | Property manager | Manage households, requests |
| `HOMEOWNER` | Home owner | Own households, requests |
| `VENDOR` | Service provider | Assigned requests |

## API Endpoints

Key API routes:

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Current user profile
- `GET /api/households` - List user's households
- `POST /api/households` - Create household
- `GET /api/requests` - List service requests
- `POST /api/requests` - Create service request
- `GET /api/admin/*` - Admin endpoints (admin only)

Full API documentation available at `/api/docs` when running the API server.

## Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed Google Cloud Run deployment instructions.

## Development Workflow

1. Make changes to shared packages in `packages/`
2. Run `pnpm -r build` to rebuild shared packages
3. Changes will be reflected in apps that depend on them

## License

Private - All rights reserved
