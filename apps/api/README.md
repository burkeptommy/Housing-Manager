# Haven Home Manager API

NestJS backend API for the Haven Home Manager platform.

## Tech Stack

- **Framework**: NestJS 10
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT (access + refresh tokens) with Passport
- **Validation**: class-validator + class-transformer
- **Password Hashing**: bcrypt

## Getting Started

### Prerequisites

- Node.js 20+
- pnpm 9+
- PostgreSQL 14+

### 1. Install Dependencies

```bash
# From monorepo root
pnpm install
```

### 2. Set Up Environment

```bash
cd apps/api
cp .env.example .env
# Edit .env with your configuration
```

### 3. Start PostgreSQL

```bash
# Using Docker
docker run --name haven-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=haven_db \
  -p 5432:5432 \
  -d postgres:16-alpine
```

### 4. Run Migrations

```bash
# Generate Prisma client
pnpm prisma:generate

# Run migrations
pnpm prisma:migrate:dev --name init

# (Optional) Seed database
pnpm prisma:seed
```

### 5. Start the Server

```bash
pnpm dev
```

The API will be available at `http://localhost:4000/api`

## Authentication Flow

### Overview

The API uses a dual-token authentication system:

1. **Access Token**: Short-lived JWT (15 minutes) used for API authentication
2. **Refresh Token**: Long-lived opaque token (7 days) stored in database, used to obtain new access tokens

### Token Flow Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Client    │         │    API      │         │  Database   │
└─────────────┘         └─────────────┘         └─────────────┘
       │                       │                       │
       │  POST /auth/register  │                       │
       │──────────────────────>│                       │
       │                       │   Create User         │
       │                       │──────────────────────>│
       │                       │   Create Household    │
       │                       │──────────────────────>│
       │                       │   Store RefreshToken  │
       │                       │──────────────────────>│
       │  { accessToken,       │                       │
       │    refreshToken }     │                       │
       │<──────────────────────│                       │
       │                       │                       │
       │  GET /auth/me         │                       │
       │  Authorization: Bearer│                       │
       │──────────────────────>│                       │
       │                       │  Validate JWT         │
       │  { user, households } │                       │
       │<──────────────────────│                       │
       │                       │                       │
       │  POST /auth/refresh   │                       │
       │  { refreshToken }     │                       │
       │──────────────────────>│                       │
       │                       │   Validate Token      │
       │                       │──────────────────────>│
       │                       │   Revoke Old Token    │
       │                       │──────────────────────>│
       │  { accessToken }      │                       │
       │<──────────────────────│                       │
       │                       │                       │
```

### JWT Payload Structure

```typescript
interface JwtPayload {
  sub: string;      // User ID
  email: string;    // User email
  role: UserRole;   // ADMIN | HOMEOWNER | MANAGER | VENDOR
  iat: number;      // Issued at
  exp: number;      // Expiration
}
```

### Security Features

- **Password Hashing**: bcrypt with 12 salt rounds
- **Token Rotation**: Refresh tokens are invalidated after use
- **Refresh Token Reuse Detection**: If a revoked token is used, all user tokens are revoked
- **Request Metadata**: IP address and user agent stored with refresh tokens

## API Endpoints

### Authentication

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/auth/register` | Register new user | No |
| POST | `/api/auth/login` | Login with credentials | No |
| POST | `/api/auth/refresh` | Get new access token | No |
| POST | `/api/auth/logout` | Invalidate tokens | Yes |
| GET | `/api/auth/me` | Get current user | Yes |

### Users (Admin Only)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/users` | List all users | Admin |
| GET | `/api/users/:id` | Get user by ID | Admin |
| PATCH | `/api/users/:id` | Update user | Admin |
| DELETE | `/api/users/:id` | Delete user | Admin |

### Health Check

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/health` | Health check | No |

## Request/Response Examples

### Register

```bash
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+15551234567"
  }'
```

Response:
```json
{
  "user": {
    "id": "clx1234567890",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+15551234567",
    "avatarUrl": null,
    "role": "HOMEOWNER",
    "emailVerified": false,
    "createdAt": "2024-01-15T10:30:00.000Z"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "a1b2c3d4e5f6...",
  "expiresIn": 900
}
```

### Login

```bash
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }'
```

### Refresh Token

```bash
curl -X POST http://localhost:4000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "a1b2c3d4e5f6..."
  }'
```

Response:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 900
}
```

### Get Current User

```bash
curl http://localhost:4000/api/auth/me \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

Response:
```json
{
  "user": {
    "id": "clx1234567890",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "HOMEOWNER",
    ...
  },
  "households": [
    {
      "id": "clx0987654321",
      "name": "John's Home",
      "description": null,
      "role": "OWNER"
    }
  ]
}
```

## Role-Based Access Control

### Roles

| Role | Description |
|------|-------------|
| `ADMIN` | Full system access |
| `HOMEOWNER` | Default role for registered users |
| `MANAGER` | Property manager role |
| `VENDOR` | Service provider role |

### Using Roles in Controllers

```typescript
import { Controller, Get, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminController {
  @Get('dashboard')
  @Roles(UserRole.ADMIN)
  getDashboard() {
    return { message: 'Admin only' };
  }

  @Get('reports')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  getReports() {
    return { message: 'Admin or Manager' };
  }
}
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `PORT` | Server port | `4000` |
| `NODE_ENV` | Environment | `development` |
| `CORS_ORIGIN` | Allowed CORS origins | `http://localhost:3000` |
| `JWT_SECRET` | JWT signing secret | Required |
| `JWT_ACCESS_EXPIRES_IN` | Access token TTL (seconds) | `900` |
| `JWT_REFRESH_EXPIRES_DAYS` | Refresh token TTL (days) | `7` |

## Available Scripts

| Script | Description |
|--------|-------------|
| `pnpm dev` | Start in development mode |
| `pnpm build` | Build for production |
| `pnpm start:prod` | Start production server |
| `pnpm test` | Run unit tests |
| `pnpm test:cov` | Run tests with coverage |
| `pnpm lint` | Run ESLint |
| `pnpm prisma:generate` | Generate Prisma client |
| `pnpm prisma:migrate:dev` | Run migrations (dev) |
| `pnpm prisma:studio` | Open Prisma Studio |

## Testing

```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run tests with coverage
pnpm test:cov
```

## Project Structure

```
apps/api/
├── prisma/
│   ├── schema.prisma       # Database schema
│   └── seed.ts             # Database seeder
├── src/
│   ├── auth/               # Authentication module
│   │   ├── decorators/     # @CurrentUser, @Roles, @Public
│   │   ├── dto/            # Request/Response DTOs
│   │   ├── guards/         # JwtAuthGuard, RolesGuard
│   │   ├── strategies/     # JWT Passport strategy
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   └── auth.module.ts
│   ├── db/                 # Database repositories
│   ├── health/             # Health check module
│   ├── prisma/             # Prisma module
│   ├── users/              # Users module
│   ├── app.module.ts
│   └── main.ts
├── .env.example
├── package.json
└── README.md
```

## License

Private - All rights reserved
