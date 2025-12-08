# Haven Home Manager

A SaaS home-management platform with web app, mobile app, and backend API.

## Tech Stack

- **Monorepo**: pnpm workspaces
- **Web**: Next.js 15 (App Router) + Tailwind CSS
- **Mobile**: Expo React Native
- **API**: NestJS
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
├── package.json
├── pnpm-workspace.yaml
└── tsconfig.json
```

## Prerequisites

- Node.js 20+
- pnpm 9+

## Getting Started

### 1. Install Dependencies

```bash
pnpm install
```

### 2. Build Shared Packages

```bash
pnpm -r --filter "@haven/core" --filter "@haven/ui" build
```

### 3. Run Applications

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
Health check: [http://localhost:4000/api/health](http://localhost:4000/api/health).

#### Mobile App (Expo)

```bash
pnpm dev:mobile
```

- Press `i` for iOS simulator
- Press `a` for Android emulator
- Scan QR code with Expo Go app on physical device

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
import { User, Home, Task } from '@haven/core';
import { createUserSchema, createHomeSchema } from '@haven/core';
import { createApiClient } from '@haven/core';
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

## Development Workflow

1. Make changes to shared packages in `packages/`
2. Run `pnpm -r build` to rebuild shared packages
3. Changes will be reflected in apps that depend on them

## License

Private - All rights reserved
