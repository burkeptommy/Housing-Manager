# DEPLOY WEB CHANGES TO PRODUCTION

## CONTEXT
We just fixed the onboarding infinite loop bug on web, but the changes are only local. 
Users at havenhome.dev are still hitting the broken onboarding.
We need to commit and push to trigger Google Cloud Build deployment.

---

## STEP 1: Check Current Git Status

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Check what's changed
git status

# Show recent commits
git log --oneline -5

# Check if we're on the right branch
git branch --show-current
```

---

## STEP 2: Review the Critical Changes

Before committing, verify the onboarding fixes are in place:

```bash
# Check the web confirmation page fix
grep -A5 "handleStartEnteringInfo\|Start entering info" /Users/tomburke/Projects/Housing-Manager/apps/web/src/app/onboarding/schedule/confirmation/page.tsx 2>/dev/null | head -20

# Check the mobile onboarding fix
grep -A5 "onboardingComplete\|router.replace" /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/\(auth\)/onboarding/complete.tsx 2>/dev/null | head -20

# Check mobile auth context fix
grep -A10 "onboardingCompleted" /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/contexts/auth-context.tsx 2>/dev/null | head -20
```

---

## STEP 3: Commit All Changes

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Stage all changes
git add -A

# Create a descriptive commit
git commit -m "fix: resolve onboarding infinite loop on web and mobile

- Web: confirmation page now routes to /app instead of /onboarding/wizard
- Mobile: removed duplicate navigation in onboarding complete
- Mobile: auth context navigation guard handles routing properly
- Mobile: Build 20 submitted to TestFlight
- Fixed web api.ts to remove broken @haven/core import"
```

---

## STEP 4: Push to Trigger Cloud Build

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Push to main (or whatever branch triggers deployment)
git push origin main

# If on a different branch, push that branch
# git push origin $(git branch --show-current)
```

---

## STEP 5: Verify Cloud Build Triggered

```bash
# Check if there's a cloudbuild.yaml
cat /Users/tomburke/Projects/Housing-Manager/cloudbuild.yaml 2>/dev/null | head -30

# Or check for deployment config
ls -la /Users/tomburke/Projects/Housing-Manager/*.yaml /Users/tomburke/Projects/Housing-Manager/*.yml 2>/dev/null
```

After pushing, check Google Cloud Console:
https://console.cloud.google.com/cloud-build/builds

---

## STEP 6: Monitor Deployment

Tell Tom:
1. The commit hash that was pushed
2. Which branch was pushed
3. Link to check Cloud Build status
4. Estimated deployment time (usually 3-5 minutes)

---

## REPORT

After completing, provide:

1. **Git Status**: What files were committed?
2. **Commit Hash**: The SHA of the deployment commit
3. **Branch**: Which branch was pushed?
4. **Cloud Build**: Was cloudbuild.yaml found? What does it deploy?
5. **Next Steps**: How to verify the deployment worked

---

# END OF PROMPT
