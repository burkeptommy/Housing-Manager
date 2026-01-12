# M12-8: FINAL VERIFICATION & DEPLOYMENT

## CRITICAL INSTRUCTIONS

Before deploying, you MUST:
1. Run the app in iOS simulator
2. Test EVERY feature from M12-1 through M12-7
3. Fix any issues found
4. Only then build and deploy

**DO NOT** deploy without manual testing in simulator.

---

## PRE-DEPLOYMENT CHECKLIST

### Test Each Feature

Open the app in iOS simulator and test each item:

#### M12-1: Plaid Bank Connection
- [ ] Go to Billing tab
- [ ] "Connect Your Bank" card is visible
- [ ] Tapping it attempts to open Plaid

#### M12-2: Family Screen
- [ ] Go to Family tab
- [ ] Tom appears only ONCE (not duplicated)
- [ ] Tap into a family member detail
- [ ] Medical info section visible
- [ ] Edit mode works

#### M12-3: Navigation
- [ ] Navigate: Home → Family → Member Detail
- [ ] Press back → Returns to Family (not Home)
- [ ] Family icons on Home screen are tappable
- [ ] Tapping navigates to member detail

#### M12-4: Ask Alfred
- [ ] Go to Property page
- [ ] Tap "Ask Alfred"
- [ ] Opens main Alfred tab (not broken screen)
- [ ] Alfred chat is functional

#### M12-5: Vendors CRM
- [ ] Go to Your Home → Vendors
- [ ] Can add a vendor
- [ ] Can view vendor detail
- [ ] Activity timeline section exists
- [ ] Can add an activity to a vendor

#### M12-6: Activity Feed
- [ ] Go to Home screen
- [ ] "Recent Activity" section visible
- [ ] Shows emoji-categorized items
- [ ] "See All" link works

#### M12-7: Profile Pictures
- [ ] Go to Family → Member detail
- [ ] Tap profile photo area
- [ ] Camera/Library options appear
- [ ] Can select a photo
- [ ] Photo uploads and displays

---

## FIX ANY ISSUES

If any test fails, fix it before proceeding:

```bash
# Run TypeScript check
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx tsc --noEmit

# Fix any type errors

# Run linter
pnpm lint

# Fix any lint errors
```

---

## BUILD VERIFICATION

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Clear all caches
rm -rf node_modules/.cache
rm -rf .expo
npx expo start --clear

# Verify app runs in simulator without crashes
```

---

## DEPLOY API (IF CHANGES MADE)

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Deploy API to Cloud Run
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Wait for deployment
sleep 60

# Verify API is running
curl https://haven-api-[hash]-ue.a.run.app/health
```

---

## TESTFLIGHT BUILD

Only after ALL tests pass:

1. **Update version in app.json:**
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check current version
cat app.json | grep -A 5 '"ios"'

# Update buildNumber to next number (e.g., 26, 27, etc.)
```

2. **Build for TestFlight:**
```bash
eas build --platform ios --profile production --auto-submit
```

3. **Monitor build:**
   - Check EAS dashboard for build status
   - Wait for Apple processing (can take 15-30 min)

4. **Test in TestFlight:**
   - Open TestFlight app
   - Install new build
   - Run through all tests again on real device

---

## FINAL REPORT

After deployment, report:

### Features Implemented
- [ ] M12-1: Plaid Bank Connection - Connect bank card on billing screen
- [ ] M12-2: Family Screen Fixes - No duplicate, enhanced details
- [ ] M12-3: Navigation Fixes - Proper back button, clickable family icons
- [ ] M12-4: Ask Alfred - Uses main Alfred tab everywhere
- [ ] M12-5: Vendors CRM - Full vendor management with activity tracking
- [ ] M12-6: Activity Feed - Emoji-categorized feed on home screen
- [ ] M12-7: Profile Pictures - Upload for all entity types
- [ ] M12-8: Deployment - Clean build, deployed to TestFlight

### Known Issues
(List any issues that couldn't be resolved)

### Build Information
- Build Number: ___
- TestFlight Version: ___
- API Revision: ___

---

## SUCCESS CRITERIA

- [ ] All M12-1 through M12-7 features verified working
- [ ] No TypeScript errors
- [ ] No crashes in simulator
- [ ] API deployed and healthy
- [ ] TestFlight build submitted
- [ ] Build appears in TestFlight app
