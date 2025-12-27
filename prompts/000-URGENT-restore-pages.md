# URGENT: Restore Original Polished Pages

**Created:** December 27, 2024  
**Priority:** CRITICAL - Must run immediately

---

## Problem

The pages were overwritten by commit `f4d8677afb2ea68650277300c1466e65a25bef29` with API-connected versions that:
1. Show errors (APIs don't exist yet)
2. Use wrong demo data ("Bob's Villa", wrong family, etc.)
3. Are missing rich features (tabs, smart alerts, logistics view)

## Solution

Restore pages from commit `444f6a721cd339b3ef650da9a15366c873d531e8` which had the polished demo-ready versions.

---

## Task 1: Restore Dashboard Page

Run this command:
```bash
cd /Users/tomburke/Projects/Housing-Manager
git checkout 444f6a721cd339b3ef650da9a15366c873d531e8 -- apps/web/src/app/app/page.tsx
```

## Task 2: Restore Your Home Page

Run this command:
```bash
git checkout 444f6a721cd339b3ef650da9a15366c873d531e8 -- apps/web/src/app/app/home/page.tsx
```

## Task 3: Restore Family Page

Run this command:
```bash
git checkout 444f6a721cd339b3ef650da9a15366c873d531e8 -- apps/web/src/app/app/family/page.tsx
```

## Task 4: Verify Demo Data

After restoring, verify these pages use the correct Morrison demo data:
- **Address:** 38 Bedford Road, Greenwich, CT 06831
- **Family:** Bob Morrison, Alice Morrison, Emma (12), Jack (8)
- **Pet:** Max (Golden Retriever)
- **Staff:** Maria Garcia (not Maria Santos)
- **Vehicles:** Tesla Model Y, Toyota Highlander, Mercedes GLE 450

If any mock data is wrong, update it to match the canonical data in the project instructions.

## Task 5: Keep Tabs on Your Home Page

The Your Home page should have these tabs:
- Overview
- Maintenance (with badge count)
- Systems
- Vendors
- Vehicles
- Financial
- Documents

If the restored version doesn't have tabs, the tabs were added in a later commit. Check if they exist and keep them.

## Task 6: Commit and Deploy

```bash
git add .
git commit -m "restore: polished demo pages before API overwrite"
git push origin main

# Deploy
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## DO NOT

- Do NOT replace these pages with API-connected versions until the APIs actually work
- Do NOT change the Morrison demo data
- Do NOT remove the tabs from Your Home page
- Do NOT simplify the rich features (smart alerts, logistics, monthly costs breakdown)

---

## Verification Checklist

After running, verify each page:

**Dashboard (`/app`):**
- [ ] Shows "Good afternoon, Bob" greeting
- [ ] Shows 68° weather
- [ ] Shows Home Health 94%
- [ ] Shows Today's Notes
- [ ] Shows "Needs Your Decision" approval cards
- [ ] Shows Sarah Chen card with "Currently Working On"
- [ ] Shows Today's Logistics with family locations
- [ ] Shows Quick Actions

**Your Home (`/app/home`):**
- [ ] Shows 38 Bedford Road address (NOT Bob's Villa)
- [ ] Shows tabs: Overview, Maintenance, Systems, Vendors, Vehicles, Financial, Documents
- [ ] Shows Home Health 94/100 donut chart
- [ ] Shows Systems Status list
- [ ] Shows Upcoming appointments
- [ ] Shows Recent Activity

**Family (`/app/family`):**
- [ ] Shows Smart Alerts (contract expiry, tuition due, vaccines, etc.)
- [ ] Shows Today's Logistics with pickups/drop-offs
- [ ] Shows Monthly Lifestyle Fixed Costs ($17,422 breakdown)
- [ ] Shows Bob & Alice Morrison (adults)
- [ ] Shows Emma (12) & Jack (8) with schools and activities
- [ ] Shows Max the Golden Retriever
- [ ] Shows Maria Garcia (nanny) with schedule
- [ ] Shows 3 vehicles with costs
