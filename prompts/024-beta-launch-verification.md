# Haven Beta Launch Verification Checklist

**Created:** February 3, 2026
**Target Launch:** February 15, 2026
**Goal:** Verify all critical paths work end-to-end before onboarding test users

---

## PHASE 1: API Health Checks

### 1.1 Core Endpoints Responding

```bash
# Health check
curl https://api.havenhome.dev/api/health

# Auth endpoint exists
curl -X POST https://api.havenhome.dev/api/auth/firebase \
  -H "Content-Type: application/json" \
  -d '{"token": "test"}' 
# Should return 401, not 404
```

### 1.2 Database Connection
```bash
# SSH into Cloud Run or check logs
# Verify Prisma can connect to PostgreSQL
```

### 1.3 Environment Variables Set
Verify these are configured in Cloud Run:
- [ ] DATABASE_URL
- [ ] FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY
- [ ] ANTHROPIC_API_KEY
- [ ] PLAID_CLIENT_ID, PLAID_SECRET, PLAID_ENV (should be "sandbox" for beta, "production" when ready)
- [ ] SENDGRID_API_KEY
- [ ] ALFRED_EMAIL_DOMAIN
- [ ] GOOGLE_MAPS_API_KEY
- [ ] ATTOM_API_KEY
- [ ] CALENDAR_ENCRYPTION_KEY

---

## PHASE 2: Authentication Flows

### 2.1 Apple Sign-In
- [ ] Tap "Continue with Apple" 
- [ ] Apple auth sheet appears
- [ ] After auth, user created in database
- [ ] Name captured from Apple (first sign-in)
- [ ] Redirected to onboarding or dashboard

### 2.2 Google Sign-In
- [ ] Tap "Continue with Google"
- [ ] Google auth flow works
- [ ] User created in database
- [ ] Name captured from Google
- [ ] Redirected appropriately

### 2.3 Email/Password
- [ ] Can create account with email
- [ ] Can sign in with existing email
- [ ] Password reset works (if implemented)

---

## PHASE 3: Onboarding Flow

### 3.1 New User Experience
- [ ] Address autocomplete works (Google Places)
- [ ] Selecting address triggers ATTOM lookup
- [ ] Property data populated (beds, baths, sqft, year built)
- [ ] Household created in database
- [ ] User linked to household
- [ ] Redirected to dashboard after completion

### 3.2 Data Verification
```sql
-- Check user was created
SELECT * FROM "User" WHERE email = 'testuser@example.com';

-- Check household was created
SELECT * FROM "Household" WHERE id = '<household_id>';

-- Check home profile has ATTOM data
SELECT * FROM "HomeProfile" WHERE "householdId" = '<household_id>';
```

---

## PHASE 4: Core Features

### 4.1 Dashboard
- [ ] Home Health Score displays (or shows setup prompt)
- [ ] Today's Notes section loads
- [ ] Quick actions work
- [ ] No crashes or infinite spinners

### 4.2 Family Management
- [ ] View family members list
- [ ] Add new family member
- [ ] Edit existing member
- [ ] Add child with school, activities, allergies
- [ ] Add pet with vet info
- [ ] Add vehicle
- [ ] All changes persist to database

### 4.3 Home Profile
- [ ] View property details
- [ ] Edit home information
- [ ] Zones/rooms display (if any)
- [ ] Systems display (if any)

### 4.4 Vendors
- [ ] View vendors list
- [ ] Add new vendor
- [ ] Edit vendor
- [ ] Categories work correctly

### 4.5 Maintenance
- [ ] Maintenance tasks display
- [ ] Auto-generated tasks from ATTOM (if property data exists)
- [ ] Can mark task complete
- [ ] Empty state shows if no tasks

---

## PHASE 5: Plaid Integration

### 5.1 Bank Connection Flow
- [ ] Navigate to Money → Banks (or Connect Bank)
- [ ] "Connect Bank" button triggers Plaid Link
- [ ] Plaid modal opens
- [ ] Can select test bank (use sandbox credentials: user_good / pass_good)
- [ ] After connection, account appears in app
- [ ] Bank account saved to database

### 5.2 Transaction Sync
- [ ] Transactions pulled from Plaid
- [ ] Transactions saved to database
- [ ] Transactions display in app

### 5.3 Bill Detection
- [ ] Recurring transactions identified as bills
- [ ] Bills appear in Bills screen
- [ ] Bill details correct (amount, frequency, vendor)

### 5.4 Empty States
- [ ] If no bank connected, shows "Connect Your Bank" prompt
- [ ] No crashes when data is missing

---

## PHASE 6: Calendar Integration

### 6.1 Google Calendar Connection
- [ ] Navigate to Calendar settings
- [ ] "Connect Google Calendar" initiates OAuth
- [ ] Google consent screen appears
- [ ] After auth, calendar marked as connected
- [ ] Tokens saved (encrypted) to database

### 6.2 Event Sync
- [ ] Events from Google Calendar display in app
- [ ] Can view event details

### 6.3 Event Creation (via Alfred)
- [ ] When Alfred creates calendar event, it appears in Google Calendar
- [ ] Event has correct title, date, time, location

---

## PHASE 7: Alfred AI

### 7.1 Chat Interface
- [ ] Alfred chat loads
- [ ] Can send message
- [ ] Alfred responds (Claude API working)
- [ ] Conversation persists

### 7.2 Email Processing (Test Endpoint)
Using the test endpoint created in prompt 023:

```bash
# Get auth token first (login as test user)

# Test camp registration
curl -X POST https://api.havenhome.dev/api/alfred/test/simulate-email \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"scenario": "camp_registration"}'
```

- [ ] Case created in database
- [ ] Case appears in Alfred → Cases screen
- [ ] Alfred's message is conversational
- [ ] Action buttons display (Add to Calendar, Track Fee, etc.)
- [ ] "Something else..." option present

### 7.3 Action Execution
- [ ] Select "Add to Calendar" → event created in Google Calendar
- [ ] Select "Track as Bill" → bill created
- [ ] Select "Something else..." → can type custom request
- [ ] Case marked complete after action

### 7.4 All Test Scenarios
Run each scenario and verify case creation:
- [ ] camp_registration
- [ ] utility_bill
- [ ] vendor_quote
- [ ] appointment
- [ ] school_event
- [ ] home_inspection

---

## PHASE 8: Budgeting (New Feature)

### 8.1 Money Overview
- [ ] Money tab loads without crash
- [ ] Monthly summary displays
- [ ] Quick navigation buttons work

### 8.2 Budget Setup
- [ ] Can set monthly income
- [ ] Can set budget per category
- [ ] Categories match Monarch structure
- [ ] Budget saved to database

### 8.3 Transactions
- [ ] Transaction list displays
- [ ] Can categorize transaction
- [ ] Can add manual transaction
- [ ] Categorization persists

### 8.4 Forecasts (with empty state)
- [ ] If no bank: shows "Connect Your Bank" (no crash)
- [ ] If bank connected: shows forecast timeline
- [ ] Systems display with replacement estimates
- [ ] "Ask Alfred to Research" button works (if implemented)

### 8.5 Insights/Comparisons
- [ ] If data exists, comparisons display
- [ ] "X% above local average" messaging works
- [ ] Recommendations display

---

## PHASE 9: Settings & Profile

### 9.1 Profile
- [ ] Can view profile
- [ ] Can edit name, phone, etc.
- [ ] Changes persist

### 9.2 Settings
- [ ] Calendar settings accessible
- [ ] Alfred email settings show address
- [ ] Authorized senders management works
- [ ] Can add/remove authorized email

### 9.3 Subscription (RevenueCat)
- [ ] Subscription status displays
- [ ] Can access subscription management
- [ ] RevenueCat integration working

---

## PHASE 10: Error Handling & Edge Cases

### 10.1 No Data States
- [ ] New user with no family → shows add prompt
- [ ] No vendors → shows empty state
- [ ] No bills → shows connect bank prompt
- [ ] No maintenance → shows empty state
- [ ] No calendar → shows connect prompt

### 10.2 Network Errors
- [ ] Graceful handling when API unavailable
- [ ] Pull-to-refresh works
- [ ] Error messages are user-friendly

### 10.3 Auth Expiration
- [ ] Token refresh works
- [ ] User not randomly logged out
- [ ] Expired token shows login screen

---

## PHASE 11: Production Readiness

### 11.1 Performance
- [ ] App launches in < 3 seconds
- [ ] Screens load in < 2 seconds
- [ ] No memory leaks (test extended use)

### 11.2 Crash-Free
- [ ] Test all navigation paths
- [ ] No crashes on any screen
- [ ] Console shows no critical errors

### 11.3 Data Integrity
- [ ] All CRUD operations work
- [ ] Data persists after app restart
- [ ] No duplicate records created

---

## PHASE 12: Real Email Testing (Optional - After SendGrid Verified)

### 12.1 Actual Email Send
- Forward a real email to `<address>@alfred.havenhome.dev`
- [ ] SendGrid receives email
- [ ] Webhook triggers API endpoint
- [ ] Case created
- [ ] User can respond

---

## AUTOMATED TEST SCRIPT

Create a script that Claude Code can run to verify API endpoints:

```typescript
// apps/api/src/scripts/beta-verification.ts

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function verifyBetaReadiness() {
  console.log('🔍 Haven Beta Verification Starting...\n');
  
  const checks: { name: string; pass: boolean; error?: string }[] = [];
  
  // 1. Database connection
  try {
    await prisma.$queryRaw`SELECT 1`;
    checks.push({ name: 'Database Connection', pass: true });
  } catch (e) {
    checks.push({ name: 'Database Connection', pass: false, error: e.message });
  }
  
  // 2. Users exist
  const userCount = await prisma.user.count();
  checks.push({ 
    name: 'Users in Database', 
    pass: userCount > 0,
    error: userCount === 0 ? 'No users found' : undefined
  });
  
  // 3. Households exist
  const householdCount = await prisma.household.count();
  checks.push({ 
    name: 'Households in Database', 
    pass: householdCount > 0,
    error: householdCount === 0 ? 'No households found' : undefined
  });
  
  // 4. Budget categories seeded
  // ... add more checks
  
  // Print results
  console.log('📋 VERIFICATION RESULTS:\n');
  for (const check of checks) {
    const icon = check.pass ? '✅' : '❌';
    console.log(`${icon} ${check.name}`);
    if (check.error) console.log(`   └─ ${check.error}`);
  }
  
  const passed = checks.filter(c => c.pass).length;
  console.log(`\n📊 ${passed}/${checks.length} checks passed`);
  
  await prisma.$disconnect();
}

verifyBetaReadiness();
```

Run with:
```bash
cd apps/api
npx ts-node src/scripts/beta-verification.ts
```

---

## SIGN-OFF CHECKLIST

Before inviting beta users:

- [ ] All Phase 1-11 checks pass
- [ ] TestFlight build is latest
- [ ] API is deployed with latest code
- [ ] Test user can complete full flow: signup → onboarding → dashboard → connect bank → use Alfred
- [ ] No critical console errors
- [ ] Tom has personally tested on device

**Ready for beta:** _______ (date)
**Signed off by:** _______ (Tom Burke)
