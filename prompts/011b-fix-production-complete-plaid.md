# Haven: Fix Production + Complete Plaid Integration

**Created:** December 28, 2024  
**Priority:** CRITICAL - Production is broken

---

## CRITICAL ISSUE: Production Pages Hanging

The homeowner portal pages (Documents, Bills, Banks) are hanging because Firebase authentication is failing with `auth/invalid-api-key` error.

### Root Cause
The Firebase API key may not be properly baked into the production build.

### Fix Required
Rebuild and redeploy the web app ensuring all environment variables are passed correctly.

---

## PHASE 1: Fix Production Build (CRITICAL)

### Task 1.1: Verify and Rebuild Web App

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Clean any cached builds
rm -rf apps/web/.next

# Verify cloudbuild-web.yaml has correct Firebase config
cat cloudbuild-web.yaml | grep FIREBASE

# The build args should include:
# --build-arg NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyDeJGjktaIHmcybrOV4LZyBHiRS0G_BUaA
# --build-arg NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=home-manager-480616.firebaseapp.com
# --build-arg NEXT_PUBLIC_FIREBASE_PROJECT_ID=home-manager-480616
# --build-arg NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=home-manager-480616.firebasestorage.app
# --build-arg NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=421884826038
# --build-arg NEXT_PUBLIC_FIREBASE_APP_ID=1:421884826038:web:3267d85f24adfc6a117117

# Rebuild and deploy
pnpm build
git add .
git commit -m "fix: rebuild with Firebase env vars"
git push origin main

gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

### Task 1.2: Add manifest.json

Create `apps/web/public/manifest.json`:

```json
{
  "name": "Haven",
  "short_name": "Haven",
  "description": "Stop managing your home. Start living in it.",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#102a43",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

---

## PHASE 2: Check Detection (Plaid Enhancement)

Update `apps/api/src/plaid/plaid.service.ts` to detect recurring checks.

### Task 2.1: Add Check Detection to Transaction Analysis

Find the `analyzeTransactions` method (or equivalent) and add check detection:

```typescript
/**
 * Detect if a transaction is a check payment
 */
private isCheckTransaction(tx: any): boolean {
  const name = (tx.name || '').toLowerCase();
  const merchantName = (tx.merchant_name || '').toLowerCase();
  
  // Common check indicators
  if (name.includes('check') || name.includes('chk')) return true;
  if (name.match(/check\s*#?\d+/i)) return true;
  if (name.match(/^#?\d{3,6}$/)) return true; // Check number only
  if (tx.payment_channel === 'other' && !merchantName) return true;
  
  return false;
}

/**
 * Extract payee name from check transaction
 */
private extractCheckPayee(tx: any): string {
  const name = tx.name || '';
  
  // Remove check number prefix
  let payee = name.replace(/^(check\s*#?\d+\s*[-:]?\s*)/i, '');
  payee = payee.replace(/^#?\d+\s*[-:]?\s*/, '');
  
  return payee.trim() || 'Unknown Payee';
}

/**
 * Categorize check payee for checkbook.io integration
 */
private categorizeCheckPayee(payee: string): string {
  const name = payee.toLowerCase();

  // Landscaping
  if (name.includes('landscap') || name.includes('lawn') || name.includes('garden') ||
      name.includes('yard') || name.includes('tree') || name.includes('mowing')) {
    return 'LANDSCAPING';
  }
  // Housekeeping
  if (name.includes('clean') || name.includes('maid') || name.includes('housekeep')) {
    return 'HOUSEKEEPING';
  }
  // Pool service
  if (name.includes('pool')) return 'POOL_SERVICE';
  // Pest control
  if (name.includes('pest') || name.includes('exterminator')) return 'PEST_CONTROL';
  // HOA
  if (name.includes('hoa') || name.includes('homeowner') || name.includes('association')) {
    return 'HOA';
  }
  // Childcare
  if (name.includes('nanny') || name.includes('childcare') || name.includes('daycare') ||
      name.includes('babysit')) {
    return 'CHILDCARE';
  }
  // Tuition
  if (name.includes('school') || name.includes('tuition') || name.includes('academy')) {
    return 'TUITION';
  }

  return 'OTHER';
}
```

### Task 2.2: Update Database Schema (if needed)

Ensure the DetectedBill model has these fields for checks:

```prisma
model DetectedBill {
  // ... existing fields
  
  detectionType   String    @default("RECURRING_CHARGE")  // or RECURRING_CHECK
  checkPayee      String?   // Payee name from check
  checkNumber     String?   // Check number if available
}
```

Run migration if schema was updated:
```bash
cd apps/api
pnpm prisma migrate dev --name add-check-detection-fields
pnpm prisma generate
```

---

## PHASE 3: Onboarding Bank Connection

### Task 3.1: Add Bank Step to Onboarding Wizard

Find the onboarding wizard at `apps/web/src/app/onboarding/wizard/page.tsx` (or similar) and add an optional bank connection step.

After the property confirmation step, before the welcome/complete step:

```typescript
// Add to step types
type OnboardingStep = 
  | 'welcome' 
  | 'address' 
  | 'property' 
  | 'connect-bank'  // NEW
  | 'complete';

// Add state for bank connection
const [linkToken, setLinkToken] = useState<string | null>(null);
const [connectedBanks, setConnectedBanks] = useState<number>(0);
const [detectedBillCount, setDetectedBillCount] = useState<number>(0);

// Create link token when entering bank step
useEffect(() => {
  if (step === 'connect-bank' && householdId) {
    createLinkToken();
  }
}, [step, householdId]);

const createLinkToken = async () => {
  try {
    const token = await getIdToken();
    const response = await fetch(`${apiUrl}/plaid/link-token`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ householdId }),
    });
    if (response.ok) {
      const data = await response.json();
      setLinkToken(data.linkToken);
    }
  } catch (error) {
    console.error('Failed to create link token:', error);
  }
};

// Plaid Link callback
const onPlaidSuccess = async (publicToken: string) => {
  try {
    const token = await getIdToken();
    const response = await fetch(`${apiUrl}/plaid/exchange-token`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ householdId, publicToken }),
    });
    
    if (response.ok) {
      setConnectedBanks(prev => prev + 1);
      
      // Get detected bills count
      const summaryRes = await fetch(`${apiUrl}/plaid/bills/${householdId}/summary`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (summaryRes.ok) {
        const summary = await summaryRes.json();
        setDetectedBillCount(summary.totalDetected);
      }
    }
  } catch (error) {
    console.error('Failed to exchange token:', error);
  }
};

const { open, ready } = usePlaidLink({
  token: linkToken,
  onSuccess: onPlaidSuccess,
});
```

### Task 3.2: Bank Step UI

```tsx
{step === 'connect-bank' && (
  <div className="bg-white rounded-2xl p-8 shadow-2xl max-w-md mx-auto">
    <div className="text-center mb-6">
      <div className="w-16 h-16 bg-indigo-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
        <Building2 className="w-8 h-8 text-indigo-600" />
      </div>
      <h1 className="text-2xl font-bold text-haven-navy-900">
        Connect your bank
      </h1>
      <p className="text-gray-500 mt-2">
        We'll automatically detect your recurring bills so you don't have to enter them manually.
      </p>
      <p className="text-sm text-gray-400 mt-1">
        Optional - you can skip and add later
      </p>
    </div>

    {/* Connect Button */}
    <button
      onClick={() => open()}
      disabled={!ready}
      className="w-full p-4 border-2 border-dashed border-gray-300 rounded-xl hover:border-indigo-400 hover:bg-indigo-50 transition flex items-center justify-center gap-3"
    >
      <Plus className="w-5 h-5 text-gray-400" />
      <span className="text-gray-600 font-medium">Connect Bank Account</span>
    </button>

    {/* Success State */}
    {connectedBanks > 0 && (
      <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-xl">
        <div className="flex items-center gap-2 text-green-700">
          <CheckCircle className="w-5 h-5" />
          <span className="font-medium">
            {connectedBanks} bank{connectedBanks > 1 ? 's' : ''} connected!
          </span>
        </div>
        {detectedBillCount > 0 && (
          <p className="text-green-600 text-sm mt-1">
            Found {detectedBillCount} recurring charges
          </p>
        )}
      </div>
    )}

    {/* Continue/Skip Button */}
    <button
      onClick={() => setStep('complete')}
      className="w-full mt-6 bg-haven-navy-900 text-white py-3 rounded-xl font-medium hover:bg-haven-navy-800 transition"
    >
      {connectedBanks > 0 ? 'Continue' : 'Skip for now'}
    </button>
  </div>
)}
```

---

## PHASE 4: Settings Bank Management

### Task 4.1: Add Banks Link to Settings Page

Update `apps/web/src/app/app/settings/page.tsx` to include a link to bank management:

```tsx
// Add to settings sections
<div className="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
  {/* ... existing settings ... */}
  
  <Link href="/app/money/connect" className="flex items-center justify-between p-4 hover:bg-gray-50">
    <div className="flex items-center gap-3">
      <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
        <Building2 className="w-5 h-5 text-indigo-600" />
      </div>
      <div>
        <p className="font-medium text-gray-900">Connected Banks</p>
        <p className="text-sm text-gray-500">Manage bank connections for bill detection</p>
      </div>
    </div>
    <ChevronRight className="w-5 h-5 text-gray-400" />
  </Link>
</div>
```

---

## PHASE 5: Test Everything

### Task 5.1: Test Login and Pages

1. Go to https://havenhome.dev
2. Log in as Bob: `bob@example.com` / `Bob123!`
3. Verify these pages load (not hang):
   - Dashboard (`/app`)
   - Documents (`/app/vault`)
   - Banks (`/app/money/connect`)
   - Bills (`/app/money/bills`)

### Task 5.2: Test Bank Connection

1. Go to `/app/money/connect`
2. Click "Connect a Bank Account"
3. Use sandbox credentials:
   - Username: `user_good`
   - Password: `pass_good`
4. Verify bills are detected
5. Go to `/app/money/bills` to review

### Task 5.3: Run E2E Tests

```bash
pnpm test:e2e
```

---

## PHASE 6: Deploy

```bash
cd /Users/tomburke/Projects/Housing-Manager

pnpm build

git add .
git commit -m "fix: production build + check detection + onboarding bank step"
git push origin main

# Deploy API (if schema changed)
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Deploy Web (CRITICAL - this fixes the Firebase issue)
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616

# Run tests
pnpm test:e2e
```

---

## Summary

After this prompt:
1. ✅ Production Firebase auth fixed
2. ✅ All pages load (Documents, Banks, Bills)
3. ✅ Check detection for checkbook.io integration
4. ✅ Bank connection step in onboarding
5. ✅ Bank management link in Settings

**Test Credentials:**
- Homeowner: `bob@example.com` / `Bob123!`
- Plaid Sandbox: `user_good` / `pass_good`
