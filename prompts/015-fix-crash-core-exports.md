# FIX iOS CRASH - ROOT CAUSE: @haven/core Missing Exports

## THE PROBLEM

The iOS app crashes because `@haven/core` package doesn't export the types that the mobile app imports.

**packages/core/src/index.ts currently has:**
```typescript
export * from './schemas';
export * from './api';
// MISSING: types are not exported!
```

**But apps/mobile/src/contexts/auth-context.tsx imports:**
```typescript
import type { User, Household, HouseholdDetail } from '@haven/core';
```

These types EXIST in `packages/core/src/types/index.ts` but are NOT exported from the package index.

---

## STEP 1: Fix @haven/core exports

Edit `/Users/tomburke/Projects/Housing-Manager/packages/core/src/index.ts`:

```typescript
// @haven/core - Shared types and utilities for Haven
export * from './schemas';
export * from './api';
export * from './types';  // ADD THIS LINE
```

---

## STEP 2: Rebuild the core package

```bash
cd /Users/tomburke/Projects/Housing-Manager/packages/core
pnpm build

# Verify the types are now exported
grep -E "User|Household|HouseholdDetail" dist/index.d.ts | head -5
```

---

## STEP 3: Fix the ApiClient interface mismatch

The mobile app uses a different ApiClient interface than what @haven/core provides.

**Option A: Update @haven/core's ApiClient** (recommended)

Edit `/Users/tomburke/Projects/Housing-Manager/packages/core/src/api/index.ts`:

```typescript
// Shared API client utilities for Haven

export interface ApiClientConfig {
  baseUrl: string;
  getAccessToken: () => string | null;
  getRefreshToken?: () => string | null;
  onTokenRefresh?: (tokens: { accessToken: string; refreshToken: string }) => Promise<void>;
  onUnauthorized?: () => void;
}

export class ApiClient {
  constructor(private config: ApiClientConfig) {}

  private async getHeaders(): Promise<HeadersInit> {
    const token = this.config.getAccessToken();
    return {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    };
  }

  async fetch<T>(path: string, options?: RequestInit): Promise<T> {
    const headers = await this.getHeaders();
    const response = await fetch(`${this.config.baseUrl}${path}`, {
      ...options,
      headers: {
        ...headers,
        ...options?.headers,
      },
    });

    if (response.status === 401 && this.config.onUnauthorized) {
      this.config.onUnauthorized();
      throw new Error('Unauthorized');
    }

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }

    return response.json();
  }

  async get<T>(path: string): Promise<T> {
    return this.fetch<T>(path, { method: 'GET' });
  }

  async post<T>(path: string, body?: unknown): Promise<T> {
    return this.fetch<T>(path, {
      method: 'POST',
      body: body ? JSON.stringify(body) : undefined,
    });
  }

  async put<T>(path: string, body: unknown): Promise<T> {
    return this.fetch<T>(path, {
      method: 'PUT',
      body: JSON.stringify(body),
    });
  }

  async delete<T>(path: string): Promise<T> {
    return this.fetch<T>(path, { method: 'DELETE' });
  }

  // Household methods used by mobile app
  async getHousehold(id: string): Promise<any> {
    return this.get(`/households/${id}`);
  }

  async getHouseholds(): Promise<any[]> {
    return this.get('/households');
  }
}
```

---

## STEP 4: Rebuild core package again

```bash
cd /Users/tomburke/Projects/Housing-Manager/packages/core
pnpm build

# Verify exports
echo "=== Checking exports ==="
node -e "const pkg = require('./dist/index.js'); console.log('Exports:', Object.keys(pkg).join(', '))"
```

---

## STEP 5: Reinstall dependencies in mobile

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Clear caches
rm -rf node_modules/.cache .expo

# Reinstall to pick up rebuilt core package
pnpm install
```

---

## STEP 6: TEST LOCALLY FIRST (CRITICAL!)

DO NOT submit to TestFlight until the app runs locally.

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Clear Metro cache
npx expo start --clear

# In another terminal, or press 'i' in Expo to run iOS simulator
```

**Wait for the app to fully load in simulator.** If it crashes, check the Metro console for the error.

---

## STEP 7: Only if local works, increment build and submit

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Get current build and increment
CURRENT=$(grep -o '"buildNumber": "[0-9]*"' app.json | grep -o '[0-9]*')
NEW=$((CURRENT + 1))
sed -i '' "s/\"buildNumber\": \"$CURRENT\"/\"buildNumber\": \"$NEW\"/" app.json
echo "Build number: $CURRENT -> $NEW"

# Build and submit
eas build --platform ios --profile production --auto-submit
```

---

## VERIFICATION CHECKLIST

Before submitting, confirm:

1. [ ] `packages/core/src/index.ts` exports `./types`
2. [ ] `packages/core/dist/index.d.ts` contains `User`, `Household`, `HouseholdDetail`
3. [ ] App runs in iOS Simulator without crash
4. [ ] App shows login screen (or dashboard if already logged in)
5. [ ] No red error screen appears

---

## REPORT

After completing, provide:

1. **Core package exports**: List of types now exported
2. **Local test result**: Did app run in simulator? Screenshot or description
3. **Error if any**: Exact error message from Metro console
4. **Build number**: New build number if submitted
5. **TestFlight status**: Submitted or not

---

# END OF PROMPT
