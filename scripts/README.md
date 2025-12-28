# Haven Test Scripts

## Quick Start

### 1. Set your Firebase API Key

Get it from: Firebase Console → Project Settings → Web API Key

```bash
export FIREBASE_API_KEY="AIzaSy..."
```

### 2. Run the tests

**Test Production:**
```bash
npx ts-node scripts/test-haven.ts
```

**Test Local:**
```bash
npx ts-node scripts/test-haven.ts --local
```

**Or use the bash script:**
```bash
chmod +x scripts/test-all.sh
./scripts/test-all.sh
./scripts/test-all.sh --local
```

---

## What Gets Tested

### Web Pages
- Homepage loads (200)
- Login page loads (200)
- Onboarding page loads (200)
- App page accessible (200/302/307)

### API Health
- API is reachable

### Admin Portal (tom@havenhome.dev)
- Firebase authentication
- GET /user/me returns ADMIN role
- GET /admin/dashboard
- GET /admin/users
- GET /admin/households
- GET /admin/onboarding

### Manager Portal (sarah@haven.app)
- Firebase authentication
- GET /user/me returns MANAGER role
- GET /manager/dashboard
- GET /manager/households
- GET /manager/onboarding/queue
- GET /manager/activity

### Homeowner Portal (bob@example.com)
- Firebase authentication
- GET /user/me returns HOMEOWNER role
- Household assignment check
- GET /dashboard/household/:id
- GET /property/household/:id
- GET /family/household/:id

### Data Integrity
- Morrison demo household exists
- 38 Bedford Road property exists
- Sarah Chen exists as manager

---

## Expected Output

```
╔════════════════════════════════════════════════════════════╗
║           HAVEN END-TO-END TEST SUITE                      ║
╚════════════════════════════════════════════════════════════╝

Environment: PRODUCTION
API URL: https://api.havenhome.dev/api
Web URL: https://havenhome.dev
Firebase API Key: ✓ Set

══════════════════════════════════════════════════════════════
  Web Pages
══════════════════════════════════════════════════════════════
  ✓ Homepage loads (245ms)
  ✓ Login page loads (198ms)
  ✓ Onboarding page loads (211ms)
  ✓ App page accessible (187ms)

... more tests ...

══════════════════════════════════════════════════════════════
  Test Summary
══════════════════════════════════════════════════════════════

  Passed:  20
  Failed:  0
  Skipped: 0

  Pass Rate: 100%

All tests passed!
```

---

## Troubleshooting

### "FIREBASE_API_KEY not set"
Set the environment variable:
```bash
export FIREBASE_API_KEY="your-key-here"
```

### "Could not get token"
- Check the email/password is correct
- Verify the user exists in Firebase Auth
- Check Firebase project is correct

### "HTTP 401"
- Token may have expired
- User may not exist in database
- FirebaseAuthGuard may not be attaching user

### "HTTP 403"
- User exists but doesn't have permission
- Check user role in database

### "Connection failed"
- API/Web may be down
- Check deployment status
- Try with `--local` flag
