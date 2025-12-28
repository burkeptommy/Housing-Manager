# Haven: Fix Demo User Login + Auto-Run Tests

**Created:** December 28, 2024  
**Purpose:** Fix Bob being redirected to onboarding + set up automatic test execution  
**Priority:** Critical

---

## CRITICAL RULES

1. **DO NOT DELETE existing code** - Only refactor and add
2. **Demo users should skip onboarding** - Bob, Sarah, Mike, vendors already have data
3. **Tests should run automatically** - No manual env var setup

---

## ISSUE 1: Bob Redirected to Onboarding

### Problem
When Bob (bob@example.com) logs in, he gets redirected to the onboarding "How would you like to get started?" page instead of going to /app dashboard.

### Root Cause
The auth flow is checking if user needs onboarding without considering:
1. User already has a household assigned
2. User's household already has complete data
3. User's onboarding session (if any) is already marked complete

### Solution
Fix the login redirect logic to check if user has a complete household before sending to onboarding.

---

## PHASE 1: Fix Auth Redirect Logic

### Task 1.1: Find the Login Redirect Logic

The redirect happens after login. Look in these files:
- `apps/web/src/app/login/page.tsx`
- `apps/web/src/contexts/auth-context.tsx`
- `apps/web/src/app/app/layout.tsx`
- `apps/web/src/middleware.ts` (if exists)

### Task 1.2: Update Login Page Redirect

In `apps/web/src/app/login/page.tsx`, find where it redirects after successful login.

The logic should be:

```typescript
// After successful Firebase login, check where to redirect
const checkRedirect = async (token: string) => {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
  
  try {
    const response = await fetch(`${apiUrl}/user/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    
    if (!response.ok) {
      // New user, needs onboarding
      router.push('/onboarding');
      return;
    }
    
    const user = await response.json();
    
    // Route based on role
    switch (user.role) {
      case 'ADMIN':
        router.push('/admin');
        return;
      case 'HOME_MANAGER':
      case 'MANAGER':
        router.push('/manager');
        return;
      case 'HANDYMAN':
        router.push('/handyman');
        return;
      case 'VENDOR':
        router.push('/vendor');
        return;
      case 'HOMEOWNER':
      default:
        // Check if homeowner has household
        if (user.householdId) {
          // Has household = go to dashboard
          router.push('/app');
        } else {
          // No household = needs onboarding
          router.push('/onboarding');
        }
        return;
    }
  } catch (error) {
    console.error('Redirect check failed:', error);
    // Default to onboarding on error
    router.push('/onboarding');
  }
};
```

### Task 1.3: Update App Layout Guard

In `apps/web/src/app/app/layout.tsx`, the auth guard may also redirect to onboarding.

Find the auth check and update it:

```typescript
useEffect(() => {
  const checkAuth = async () => {
    if (user === undefined) return; // Still loading
    
    if (user === null) {
      router.push('/login');
      return;
    }
    
    try {
      const token = await user.getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const response = await fetch(`${apiUrl}/user/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      if (!response.ok) {
        router.push('/onboarding');
        return;
      }
      
      const userData = await response.json();
      
      // IMPORTANT: Only redirect to onboarding if NO household
      if (userData.role === 'HOMEOWNER' && !userData.householdId) {
        router.push('/onboarding');
        return;
      }
      
      // User is authorized for /app
      setAuthorized(true);
    } catch (error) {
      console.error('Auth check failed:', error);
      router.push('/login');
    } finally {
      setLoading(false);
    }
  };
  
  checkAuth();
}, [user, router]);
```

### Task 1.4: Check Onboarding Page Guard

In `apps/web/src/app/onboarding/page.tsx` or layout, there may be logic that ALWAYS shows onboarding.

If onboarding page checks for incomplete onboarding sessions, it should also check:
- If user already has householdId → redirect to /app
- If user's onboarding status is 'ACTIVE' or 'PROFILE_DELIVERED' → redirect to /app

```typescript
// At the start of onboarding page
useEffect(() => {
  const checkIfNeeded = async () => {
    if (!user) return;
    
    const token = await user.getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
    
    const response = await fetch(`${apiUrl}/user/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    
    if (response.ok) {
      const userData = await response.json();
      
      // If user already has a household, skip onboarding
      if (userData.householdId) {
        router.push('/app');
        return;
      }
    }
    
    // Otherwise, show onboarding
    setReady(true);
  };
  
  checkIfNeeded();
}, [user, router]);
```

### Task 1.5: Verify /user/me Returns householdId

Make sure the `/user/me` endpoint returns the user's householdId. Check `apps/api/src/user/user.controller.ts` or wherever the /me endpoint is defined:

```typescript
@Get('me')
@UseGuards(FirebaseAuthGuard)
async getMe(@Request() req: any) {
  return {
    id: req.user.id,
    email: req.user.email,
    name: req.user.name,
    firstName: req.user.firstName,
    lastName: req.user.lastName,
    phone: req.user.phone,
    role: req.user.role,
    householdId: req.user.householdId,  // <-- MUST include this
  };
}
```

---

## PHASE 2: Update Seed Data (Ensure Demo Users Are Complete)

### Task 2.1: Verify Bob's Household Assignment

In the seed file, ensure Bob is properly linked to his household:

```typescript
// In seed.ts, after creating household and bob:
const bob = await prisma.user.upsert({
  where: { email: 'bob@example.com' },
  update: {
    householdId: household.id,  // <-- MUST be set
  },
  create: {
    email: 'bob@example.com',
    firebaseUid: 'bob-demo-uid',
    name: 'Bob Morrison',
    firstName: 'Bob',
    lastName: 'Morrison',
    phone: '(203) 555-0101',
    role: 'HOMEOWNER',
    householdId: household.id,  // <-- MUST be set
  },
});
```

### Task 2.2: Mark Demo Onboarding Sessions as Complete

If Bob has an OnboardingSession, it should be marked ACTIVE or PROFILE_DELIVERED:

```typescript
// In seed.ts
await prisma.onboardingSession.upsert({
  where: { householdId: household.id },
  update: {
    status: 'ACTIVE',  // <-- Complete status
  },
  create: {
    householdId: household.id,
    status: 'ACTIVE',
    selectedTier: 'HAVEN',
    // ... other fields
  },
});
```

---

## PHASE 3: Set Up Automatic Test Execution

### Task 3.1: Get Firebase API Key from Project

The Firebase API Key is in the web app's environment. Find it:

```bash
# Check web app env file
cat apps/web/.env.local 2>/dev/null || cat apps/web/.env

# Or check for NEXT_PUBLIC_FIREBASE_API_KEY
grep -r "FIREBASE_API_KEY\|apiKey" apps/web/.env* apps/web/src/lib/firebase*
```

The key format is: `AIzaSy...` (39 characters)

### Task 3.2: Update Test Script with Hardcoded Key

Once you find the Firebase API Key, update `scripts/test-haven.ts`:

```typescript
// At the top of the file, replace:
const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY || '';

// With the actual key (or read from .env):
const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY || 'AIzaSy...actual-key-here...';
```

**OR** create a .env file in the project root:

```bash
# Create scripts/.env or use project root .env
echo "FIREBASE_API_KEY=AIzaSy...actual-key..." > .env
```

### Task 3.3: Update Test Script to Read .env

Update `scripts/test-haven.ts` to read from .env:

```typescript
// At the very top, before other imports
import * as fs from 'fs';
import * as path from 'path';

// Read .env file
function loadEnv() {
  const envPaths = [
    path.join(process.cwd(), '.env'),
    path.join(process.cwd(), '.env.local'),
    path.join(process.cwd(), 'apps/web/.env.local'),
    path.join(process.cwd(), 'apps/web/.env'),
  ];
  
  for (const envPath of envPaths) {
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf-8');
      for (const line of content.split('\n')) {
        const match = line.match(/^([^=]+)=(.*)$/);
        if (match) {
          const key = match[1].trim();
          const value = match[2].trim().replace(/^["']|["']$/g, '');
          if (!process.env[key]) {
            process.env[key] = value;
          }
        }
      }
    }
  }
}

loadEnv();

// Then use the key
const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY || 
                         process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '';
```

### Task 3.4: Run the Tests

After fixing the login issue and setting up the API key:

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm install
pnpm test:e2e
```

---

## PHASE 4: Build and Deploy

### Task 4.1: Build

```bash
pnpm build
```

### Task 4.2: Deploy

```bash
git add .
git commit -m "fix: demo users skip onboarding, auto-run tests"
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

### Task 4.3: Re-run Seed (if needed)

If Bob's data needs updating:

```bash
# Connect to production database and run seed
# Or use Prisma Studio to verify Bob has householdId set
```

---

## PHASE 5: Run Tests and Report Results

After deployment, run the test suite:

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm test:e2e
```

Report the results showing:
- All test pass/fail status
- Any errors encountered
- Final pass rate

---

## Verification Checklist

### Demo User Login
- [ ] Bob (bob@example.com) → Goes to /app dashboard (NOT onboarding)
- [ ] Sarah (sarah@haven.app) → Goes to /manager dashboard
- [ ] Tom (tom@havenhome.dev) → Goes to /admin dashboard

### Test Suite
- [ ] Tests run without manual env var setup
- [ ] Firebase authentication works
- [ ] All endpoints return expected data

### No Regressions
- [ ] New user signup still goes to onboarding
- [ ] Onboarding flow still works for new users
- [ ] All existing portals work

---

## Summary

This prompt:
1. ✅ Fixes login redirect to check householdId before onboarding
2. ✅ Ensures demo users (Bob, Sarah, etc.) go to their dashboards
3. ✅ Sets up test scripts to auto-load Firebase API key
4. ✅ Runs tests against production (havenhome.dev)
5. ✅ Reports test results
