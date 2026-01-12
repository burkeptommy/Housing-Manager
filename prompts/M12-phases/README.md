# M12 PROMPTS - MOBILE APP COMPREHENSIVE FIXES

## Overview

These 8 prompts fix critical issues and add new features to the Haven mobile app. Run them **one at a time** and verify each works before proceeding.

## The Prompts

| # | File | What It Does |
|---|------|--------------|
| 1 | `M12-1-plaid-bank-connection.md` | Adds "Connect Your Bank" card to billing screen |
| 2 | `M12-2-fix-family-screen.md` | Fixes duplicate Tom, adds doctors/schools/etc |
| 3 | `M12-3-fix-navigation.md` | Fixes back button, makes family icons clickable |
| 4 | `M12-4-fix-ask-alfred.md` | All "Ask Alfred" buttons use main Alfred tab |
| 5 | `M12-5-vendors-crm.md` | Full vendor CRM with activity tracking |
| 6 | `M12-6-activity-feed.md` | Emoji-categorized activity feed on home |
| 7 | `M12-7-profile-pictures.md` | Photo uploads for family, pets, staff |
| 8 | `M12-8-final-deployment.md` | Verify everything, deploy to TestFlight |

## How to Run Each Prompt

### Step 1: Run Prompt 1
```
In Claude Code:

Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/M12-phases/M12-1-plaid-bank-connection.md

IMPORTANT:
- Actually build the UI, don't just verify things exist
- Test in iOS simulator before marking complete
- Show me a screenshot of the Connect Bank card on billing screen
```

Wait for completion. Verify in simulator. Then proceed to Step 2.

### Step 2: Run Prompt 2
```
In Claude Code:

Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/M12-phases/M12-2-fix-family-screen.md

IMPORTANT:
- Tom should only appear ONCE in the family list
- Family member detail must have editable medical/school sections
- Test in iOS simulator before marking complete
```

Wait for completion. Verify in simulator. Then proceed to Step 3.

### Step 3-7: Continue Similarly
Run each prompt, verify in simulator, then proceed.

### Step 8: Final Deployment
```
In Claude Code:

Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/M12-phases/M12-8-final-deployment.md

This will:
- Verify all features
- Run tests
- Deploy API
- Submit to TestFlight
```

## If Claude Code Says "Already Implemented"

Add this to your prompt:
```
DO NOT say "already implemented". I need you to:
1. Actually check if the UI exists by reading the code
2. Run the app in simulator to verify
3. If the feature is missing or broken, BUILD IT

The previous attempt skipped actual implementation. This time, write the code.
```

## Verification Commands

After each prompt, run these to verify:

```bash
# Start app in simulator
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear --ios

# Check for TypeScript errors
npx tsc --noEmit

# Check for build errors
pnpm build
```

## Total Time Estimate

- M12-1 (Plaid): 30-45 min
- M12-2 (Family): 30-40 min
- M12-3 (Navigation): 15-20 min
- M12-4 (Alfred): 15-20 min
- M12-5 (Vendors): 45-60 min
- M12-6 (Activity): 25-30 min
- M12-7 (Photos): 30-40 min
- M12-8 (Deploy): 20-30 min

**Total: 3.5-5 hours**

## What Each Prompt Fixes

### M12-1: Plaid Bank Connection
- **Problem:** Billing screen says "No bills yet" with no bank connection option
- **Solution:** Add prominent "Connect Your Bank" card that opens Plaid

### M12-2: Family Screen
- **Problem:** Tom appears twice (owner + head of household)
- **Problem:** No way to add doctors, schools, activities
- **Solution:** Deduplicate + add enhanced detail screen with all fields

### M12-3: Navigation
- **Problem:** Back button goes to home instead of previous screen
- **Problem:** Family icons on home screen not tappable
- **Solution:** Fix navigation stack + make icons clickable

### M12-4: Ask Alfred
- **Problem:** "Ask Alfred" from property page opens broken different screen
- **Solution:** All Ask Alfred buttons navigate to main Alfred tab

### M12-5: Vendors CRM
- **Problem:** No way to track vendors and interactions
- **Solution:** Full CRM with vendor list, detail, activity timeline

### M12-6: Activity Feed
- **Problem:** No visibility into what's happening
- **Solution:** Emoji-categorized feed on home screen

### M12-7: Profile Pictures
- **Problem:** Can't upload photos for family members
- **Solution:** Camera + library picker with upload

### M12-8: Deployment
- **Purpose:** Verify everything works, deploy to TestFlight
