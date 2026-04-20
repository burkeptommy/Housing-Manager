# Phase 66 Test Plan — Post-Quiz User

Scope: verify the five-section Maintenance hub renders correctly for a user who has just completed the house quiz. Covers data model, rendering, action flows, preference-tier variants, idempotency, edge cases, and regression tests. Run through this in ~45 minutes of manual QA + 5 minutes of SQL spot checks.

Assumes migration `20260800_phase66_routines_first_class.sql` is live on the `jsucwnkntdrxhysojgri` Supabase project (already deployed as of ship).

---

## Prerequisites

- [ ] Build 95+ installed on a physical iPhone running iOS 17+ (simulator is fine for most checks but haptics won't fire)
- [ ] Fresh TestFlight account signed in (or delete + re-add an existing account via Settings → Delete Account)
- [ ] Supabase CLI linked to `jsucwnkntdrxhysojgri` so you can run `supabase db remote execute "..." --linked` for DB spot checks
- [ ] Know your `household_id` and `property_id` — grab from `SELECT id, household_id FROM properties ORDER BY created_at DESC LIMIT 1;`

Test accounts to create (name them so results stay distinct):
1. **Tier A — `.hireOut`:** picks Blue Fox (landscaping) + Tyler Heating (HVAC) + Paul's Plumbing at Q15b, picks "Hire it out" at Q36, adds one vehicle
2. **Tier B — `.mixed`:** picks Blue Fox only at Q15b, picks "Mix of both" at Q36, no vehicles
3. **Tier C — `.diy`:** picks zero contractors at Q15b, picks "I handle it" at Q36, no vehicles

Run every section against Tier A first; sanity-check Tier B + Tier C at the preference-tier section below.

---

## 1. Pre-flight DB state (before finishing the quiz)

Run these in `supabase db remote execute --linked` right before tapping the final Q36 answer. Expected: everything empty or near-empty.

```sql
-- No routines created yet for this property
SELECT COUNT(*) FROM routines
WHERE property_id = '<YOUR_PROPERTY_ID>' AND archived_at IS NULL;
-- Expected: 0 (or few if Q15b already auto-created some)

-- No parent_routine_id set on any tasks yet
SELECT COUNT(*) FROM maintenance_tasks
WHERE household_id = '<YOUR_HOUSEHOLD_ID>' AND parent_routine_id IS NOT NULL;
-- Expected: 0
```

If the curator gate already flipped (from a previous test), run in lldb or blow away the app container:
```
UserDefaults.standard.removeObject(forKey: "hasRunDay1Curator_<propertyId>_v1")
```

---

## 2. Quiz completion happy path

Complete the full quiz for Tier A. Watch closely at Q15b and at the Q36 answer.

- [ ] At Q15b, select each contractor chip AND attach a provider for that chip (Blue Fox, Tyler, Paul's). Confirm the chip feedback pill shows "We'll track visits from X" or equivalent.
- [ ] Continue through the quiz to Q36. Pick **"Hire it out."**
- [ ] On the completion cinematic, wait ~3-10 seconds for `finalReconcileTask` to finish in the background. Dashboard should post `.maintenanceTaskChanged` + `.routineChanged` when done.
- [ ] Navigate to the Maintenance tab (from Dashboard → "See full schedule" or Property → Maintenance row).

**What you should see on first tab load:**

- [ ] "YOUR SERVICES" section near the top with **Blue Fox · Landscaping · Weekly** + **Tyler Heating · HVAC · Semi-annually** (or similar) as active rows. Both have the vendor logo (or initial fallback).
- [ ] Under "PICK A PRO FOR THESE" inside Your Services, 2-5 pending-vendor cards with coral icons ("Pick a pro for snow removal", "Pick a pro for chimney sweep", etc.). The exact set depends on what templates exist for the property's systems.
- [ ] "NEXT HANDYMAN VISIT" section with a card. If no handyman vendor was captured, it reads "Next handyman visit · Add a handyman to get started" with an "Add handyman" pill CTA. If one WAS captured, it reads "[Name] · N items waiting" with a preview of the first 3 items.
- [ ] "VEHICLES" section (only if you added a vehicle). Shows a card per vehicle with "Set up shop →" since no vehicle routine exists yet.
- [ ] "THIS SEASON" section. Should have **≤3 items** for Tier A — typically 0-2 seasonal renewals (snow contract decision, etc.).
- [ ] "UPCOMING SCHEDULED" section. Empty — user hasn't confirmed a visit yet.

If This Season shows >3 items for Tier A, something is mis-routing. Likely culprits: preference tier not saved to `properties.attributes.vendor_preference_tier`, or the template's `routingOverride` is wrong, or the curator didn't run.

---

## 3. DB state after quiz (post-curator)

```sql
-- Verify routines were created
SELECT id, label, routine_kind, setup_state, scope, vendor_id IS NOT NULL AS has_vendor
FROM routines
WHERE property_id = '<YOUR_PROPERTY_ID>' AND archived_at IS NULL
ORDER BY setup_state, label;
```

Expected for Tier A:
- [ ] 3 rows with `setup_state='active'` + `has_vendor=true` (Blue Fox / Tyler / Paul's)
- [ ] 1 row with `routine_kind='handyman_recurring'` + `setup_state='active'` (lazily created by curator)
- [ ] N rows with `setup_state='pending_vendor'` (one per uncovered category — snow, chimney, pest, etc.)
- [ ] Every row has `scope='property'` and `vehicle_id IS NULL`

```sql
-- Verify curator routed tasks
SELECT
  COUNT(*) FILTER (WHERE parent_routine_id IS NOT NULL) AS parented,
  COUNT(*) FILTER (WHERE parent_routine_id IS NULL) AS unparented,
  COUNT(*) FILTER (WHERE parent_routine_id IS NOT NULL AND assignment_type = 'vendor') AS vendor_parented,
  COUNT(*) FILTER (WHERE parent_routine_id IS NOT NULL AND assignment_type = 'personal') AS personal_parented
FROM maintenance_tasks
WHERE household_id = '<YOUR_HOUSEHOLD_ID>'
  AND (is_archived IS NULL OR is_archived = false);
```

Expected for Tier A `.hireOut`:
- [ ] `parented` >> `unparented`. Ratio should be roughly 80/20 or better.
- [ ] `vendor_parented` is the bulk
- [ ] `personal_parented` > 0 (DIY-default tasks routed to handyman routine)

```sql
-- Verify handyman routine has children
SELECT
  r.label,
  COUNT(t.id) AS task_count,
  COUNT(t.id) FILTER (WHERE t.assigned_route = 'handyman') AS handyman_routed
FROM routines r
LEFT JOIN maintenance_tasks t ON t.parent_routine_id = r.id AND (t.is_archived IS NULL OR t.is_archived = false)
WHERE r.property_id = '<YOUR_PROPERTY_ID>'
  AND r.routine_kind = 'handyman_recurring'
  AND r.archived_at IS NULL
GROUP BY r.id, r.label;
```

Expected:
- [ ] 1 row returned
- [ ] `task_count` between 5 and 20
- [ ] `handyman_routed` should equal `task_count`

```sql
-- Verify curator flag was set
-- (UserDefaults is on-device; verify via analytics instead)
SELECT COUNT(*) FROM analytics_events
WHERE event_name = 'day1_curator_ran'
  AND (payload->>'property_id')::uuid = '<YOUR_PROPERTY_ID>';
-- Expected: exactly 1
```

---

## 4. Section-by-section rendering verification

### 4a. Your Services section

- [ ] Active services list with vendor logo on the left (or SF Symbol fallback with `beige200` background)
- [ ] Label format: "Landscaping · Blue Fox" or similar
- [ ] Subtitle format: "Blue Fox · Weekly" (vendor name + cadence)
- [ ] Chevron on the right
- [ ] Tap an active service → pushes `RoutineDetailView` with vendor card + upcoming visits + child task list
- [ ] "PICK A PRO FOR THESE" subsection appears when pending-vendor routines exist
- [ ] Pending row renders with coral icon background + "Haven helping find one" caption in coral
- [ ] Tap a pending row → `RoutineDetailView` opens showing "Haven is helping find one" with edit button
- [ ] "Add a service" button at the bottom of the section opens `RoutineEditSheet` with `existing: nil`

### 4b. Next Handyman Visit section

Tier A with preferred handyman captured:
- [ ] Vendor logo on left + "[Vendor Name] · N items waiting"
- [ ] Preview shows first 3 tasks with bullet points
- [ ] "+ N more" caption if task count > 3
- [ ] "Schedule visit" pill appears when `task_count >= 3`
- [ ] Tap card → `RoutineDetailView` for handyman routine

Tier A without preferred handyman captured (skip the handyman chip at Q15b to test):
- [ ] Card reads "Next handyman visit · Add a handyman to get started"
- [ ] "Add handyman" pill CTA shows at bottom
- [ ] Tap pill → Alfred chat opens with prefilled "Help me find a handyman" message

### 4c. Vehicles section

With no vehicles:
- [ ] Section hidden entirely

With 1 vehicle but no program:
- [ ] Vehicle card shows "[Year] [Make] [Model]" as title
- [ ] Status line: "N service items · no shop set"
- [ ] "Set up shop →" button at bottom
- [ ] Tap "Set up shop" → fires notification (handler TBD in future phase; should not crash)

With 1 vehicle AND a program (requires programmatic setup via RoutineEditSheet for now — vehicle setup UI is a follow-on):
- [ ] Status line: "[Shop Name] · manages N items" (if `shop_managed`)
- [ ] Status line: "Self-managed · N items" (if `self_managed`)
- [ ] Tap card → `RoutineDetailView`

### 4d. This Season section

For Tier A:
- [ ] Either empty-state "You're set" card OR ≤3 item rows
- [ ] Empty state shows green `checkmark.circle.fill` + "Nothing waiting on a decision"
- [ ] Populated rows have empty circle icon + title + "Due YYYY-MM-DD" caption
- [ ] Tap a task → fires `requestTaskDetail` notification (existing MaintenanceTaskDetailSheet handler)

### 4e. Upcoming Scheduled section

- [ ] Empty on Day 1 (no confirmed visits)
- [ ] After confirming a visit via RoutineDetailView's `scheduledDate` update: row appears with calendar badge icon + routine label + scheduled date
- [ ] Tap → opens RoutineDetailView

---

## 5. Core action flows

### 5a. Tap "See full year ↗"

- [ ] Header link above Your Services, styled as navy700 body label
- [ ] Tap → pushes `MaintenanceScheduleView(initialLayout: .calendar)` (Timeline mode)
- [ ] Timeline shows ONLY unparented tasks (`parent_routine_id IS NULL`) — tasks under routines should NOT appear in the flat timeline
- [ ] Fires `see_full_year_tapped` analytics event

### 5b. Tap an active vendor routine → RoutineDetailView

- [ ] Vendor card with logo + company name + cadence subtitle
- [ ] "Upcoming visits" section (empty initially — no visits scheduled)
- [ ] "What's included (N)" section with child tasks
- [ ] Each child task shows title + "Due YYYY-MM-DD"
- [ ] "Edit routine" button → opens `RoutineEditSheet`
- [ ] "Archive routine" (destructive) → calls `unlinkTasksFromRoutine` then archives
- [ ] Fires `routine_detail_opened` analytics event

### 5c. Edit routine → save → tasks re-link

- [ ] Open RoutineEditSheet for an active vendor routine
- [ ] Change the vendor to a different contractor
- [ ] Save
- [ ] Dismiss and return to Maintenance hub
- [ ] Service row should show the new vendor name + logo
- [ ] DB: `SELECT vendor_id FROM routines WHERE id='<routine_id>';` should return the new contractor's ID

### 5d. Archive an active routine → tasks resurface

- [ ] Open RoutineDetailView for Blue Fox landscaping
- [ ] Tap "Archive routine" → confirm
- [ ] Return to hub
- [ ] Blue Fox no longer appears in Your Services
- [ ] Previously-linked landscaping tasks appear in This Season OR in `MaintenanceScheduleView` buckets when viewed via "See full year"
- [ ] DB: `SELECT COUNT(*) FROM maintenance_tasks WHERE parent_routine_id = '<blue_fox_routine_id>';` should return 0

### 5e. "Add to handyman list" from a DIY task detail sheet

- [ ] From This Season, tap a DIY task (e.g. "Replace air filter")
- [ ] In the detail sheet, tap "Add to handyman list · Just this time" OR "From now on, reassign series"
- [ ] Expected: punch item created (existing Phase 54B behavior) + task's `parent_routine_id` set to the handyman routine
- [ ] DB: verify both — `SELECT COUNT(*) FROM handyman_punch_items WHERE source_task_id = '<task_id>';` returns 1 AND `SELECT parent_routine_id FROM maintenance_tasks WHERE id = '<task_id>';` returns the handyman routine id
- [ ] Return to hub. Task should NO LONGER appear in This Season. Next Handyman Visit's count should increment by 1.

### 5f. Find handyman via Alfred

- [ ] With no preferred handyman, tap "Add handyman" on the Next Handyman Visit card
- [ ] Alfred chat opens with prefilled message
- [ ] After Alfred recommends a handyman and user adds it → routine's `vendor_id` should update → Next Handyman Visit card now shows the vendor's logo + name

### 5g. Pull task back out of handyman routine

- [ ] Open the handyman RoutineDetailView
- [ ] Tap one of the child tasks
- [ ] (Detail sheet flow — explicit "pull out" UI is a follow-on; for now verify via DB)
- [ ] Manually clear `parent_routine_id` via SQL, reload hub → task reappears in This Season

---

## 6. Preference tier variants

### Tier A · `.hireOut` (already tested above)

- [ ] This Season ≤ 3 items
- [ ] Handyman routine has 5-20 items
- [ ] DIY-default tasks (air filters, weatherstripping) routed to handyman

### Tier B · `.mixed`

Run the full quiz with Tier B. After landing on the hub:
- [ ] Handyman routine has fewer items than Tier A (only those with `diyEffortMinutes <= 30`)
- [ ] This Season has more items than Tier A — `.diyCapable` templates with effort > 30 stay visible
- [ ] Tasks with `safetyFloor=true` NEVER appear in the handyman routine regardless of tier

### Tier C · `.diy`

Run the full quiz with Tier C. After landing on the hub:
- [ ] Handyman routine may not exist yet (curator skips DIY-routing for this tier)
- [ ] This Season has many items — every DIY template shows up as a task
- [ ] Service-based routines still get created (Blue Fox if captured), just don't hide DIY tasks

---

## 7. Idempotency tests

### 7a. Curator doesn't re-run on relaunch

- [ ] Force-quit the app
- [ ] Relaunch
- [ ] Tap Maintenance tab
- [ ] Verify hub renders identically (no task movement)
- [ ] DB: `analytics_events` count for `day1_curator_ran` should still be exactly 1

### 7b. Back-navigate and re-answer quiz

- [ ] Open the quiz from Settings → Retake quiz (or equivalent)
- [ ] Change the Q15b contractor for HVAC from Tyler to a new vendor (Groton)
- [ ] Advance through Q36 and re-complete
- [ ] Verify:
  - [ ] The existing HVAC routine's `vendor_id` UPDATES to Groton (not a new routine created)
  - [ ] HVAC tasks stay linked to the same routine
  - [ ] Curator does NOT re-run (UserDefaults flag still set)

### 7c. Re-completing quiz doesn't duplicate routines

- [ ] Save the count: `SELECT COUNT(*) FROM routines WHERE property_id = '<YOUR_PROPERTY_ID>' AND archived_at IS NULL;`
- [ ] Retake quiz + re-complete
- [ ] Re-query: count should be identical

---

## 8. Edge cases

### 8a. Fresh account with no property yet

- [ ] Sign up a fresh account, skip property creation
- [ ] Navigate to Dashboard → doesn't crash
- [ ] Maintenance tab shows empty state (no MaintenanceHubView since no property)

### 8b. Property created but quiz not started

- [ ] Create property without completing the quiz
- [ ] Open MaintenanceHubView
- [ ] Every section should be empty-state:
  - [ ] Your Services: "No services set up yet" card + "Add a service" button
  - [ ] Next Handyman Visit: "Add a handyman to get started"
  - [ ] Vehicles: hidden (no vehicles)
  - [ ] This Season: "You're set" empty state
  - [ ] Upcoming Scheduled: hidden

### 8c. Quiz partially completed

- [ ] Start the quiz, answer through Q20, save and exit
- [ ] Open MaintenanceHubView
- [ ] Should not crash; sections render based on whatever routines were created by the partial Q15b flow
- [ ] Curator has NOT run yet (quiz incomplete → `completedAt` still nil)
- [ ] Tasks created by partial reconciliation should all be in This Season (no parent_routine_id)

### 8d. Multi-property household

- [ ] Create a second property
- [ ] Complete its quiz
- [ ] Verify:
  - [ ] Each property has its own handyman routine
  - [ ] Each property has its own pending-vendor routines
  - [ ] Curator flag is per-property (`hasRunDay1Curator_<propertyId>_v1`) — runs independently
  - [ ] Hub for property A doesn't show property B's routines

### 8e. Vehicle with existing tasks but no program

- [ ] Add a vehicle via Property → Garage (VIN decode creates tasks)
- [ ] Open Maintenance hub
- [ ] Vehicles section shows the vehicle with "Set up shop →"
- [ ] Vehicle tasks should NOT appear in This Season (filtered by `vehicle_id IS NULL`)
- [ ] Timeline (via "See full year") should include vehicle tasks since they're unparented

---

## 9. Regression tests (things that should NOT have broken)

### 9a. Old Scheduled / To-Schedule buckets

- [ ] "See full year ↗" → MaintenanceScheduleView
- [ ] Scroll through the list — confirm:
  - [ ] Routines strip at the top renders
  - [ ] Tasks with `parent_routine_id IS NULL` appear in their buckets
  - [ ] Tasks with `parent_routine_id SET` do NOT appear (per our filter)
  - [ ] Stats pills at the top still work
  - [ ] Tapping tasks opens MaintenanceTaskDetailSheet
  - [ ] Completing a task from the detail sheet still works + updates the hub

### 9b. Handyman punch list

- [ ] Navigate to PropertyDetailView → Handyman Punch List (if visible)
- [ ] Verify existing punch items still show
- [ ] Add a new punch item from a DIY task — punch item + routine link happen together
- [ ] "Schedule visit" from punch list still works

### 9c. RoutinesListView

- [ ] Settings → Routines (or wherever the list is exposed)
- [ ] All routines visible including new setup_state-tagged ones
- [ ] Tap routine → RoutineEditSheet opens
- [ ] Save + delete still work

### 9d. Q15b back-navigation

- [ ] Navigate backward to Q15b mid-quiz
- [ ] Previously-selected chips still show as selected
- [ ] Hydration correctly reads from saved answer
- [ ] Re-saving doesn't create duplicate routines

### 9e. Dashboard

- [ ] MaintenanceReorganizedCard appears ONCE for users with `hasCompletedAnyQuiz = true`
- [ ] Tap "Got it" → card disappears permanently (UserDefaults flag)
- [ ] Kill + relaunch app → card stays dismissed
- [ ] Fresh accounts that haven't completed the quiz don't see the card

### 9f. Contractors directory

- [ ] PropertyDetailView → Contacts tab
- [ ] Blue Fox + Tyler + Paul's all show up
- [ ] Tap a contractor → detail view still works
- [ ] "Add vendor" flow still works

---

## 10. Analytics events to verify

Run at the end of all tests. Tier A full flow should fire:

```sql
SELECT event_name, COUNT(*) AS count
FROM analytics_events
WHERE (payload->>'property_id')::uuid = '<YOUR_PROPERTY_ID>'
  AND event_name IN (
    'quiz_completed',
    'day1_curator_ran',
    'day1_curator_task_routed_vendor',
    'day1_curator_task_routed_pending_vendor',
    'day1_curator_task_routed_handyman',
    'routine_activated',
    'pending_vendor_routine_created',
    'routine_vendor_tasks_linked',
    'routine_detail_opened',
    'see_full_year_tapped',
    'next_handyman_visit_opened',
    'your_services_opened'
  )
GROUP BY event_name
ORDER BY event_name;
```

Expected:
- [ ] `quiz_completed` = 1
- [ ] `day1_curator_ran` = 1
- [ ] `day1_curator_task_routed_*` events sum to > 10 (total tasks routed)
- [ ] `routine_activated` = number of Q15b contractors picked (3 for Tier A)
- [ ] `pending_vendor_routine_created` = number of auto-created pending routines
- [ ] Detail view opens increment on every tap

---

## 11. Visual / UX polish checks

- [ ] Sections render in the declared order: Your Services → Next Handyman Visit → Vehicles → This Season → Upcoming Scheduled
- [ ] Consistent padding (`HavenTheme.spacing20` horizontal, `HavenTheme.spacing32` between sections)
- [ ] Section headers use `HavenTypography.uiSectionHeader` + `tracking(1.5)` + `HavenColors.textTertiary`
- [ ] Active service rows have `HavenColors.creamLight` background
- [ ] Pending-vendor rows have `HavenColors.action.opacity(0.04)` background + coral icon
- [ ] Cards use `HavenTheme.radiusMedium` corner radius
- [ ] Vendor logos load via Brandfetch (no broken image icons)
- [ ] No em dashes in any user-facing copy (spot-check all new strings)
- [ ] Dark mode renders correctly (toggle via Settings → Display → Dark)
- [ ] Light haptic fires on row taps
- [ ] Success haptic fires on archive / save actions

---

## 12. Migration / backfill (existing TestFlight users)

If the user being tested is an EXISTING TestFlight user who had tasks before Phase 66 shipped:

- [ ] On first app launch post-update, watch for the `AppState.runDay1CuratorForExistingPropertiesOnceIfNeeded` backfill to fire
- [ ] Check analytics: `day1_curator_ran` event should fire once per property that had `completedAt != nil`
- [ ] DB: `SELECT COUNT(*) FROM maintenance_tasks WHERE parent_routine_id IS NOT NULL AND household_id = '<YOUR_HOUSEHOLD_ID>';` should increase from 0 to a positive number
- [ ] On Dashboard: `MaintenanceReorganizedCard` appears
- [ ] Tap "Learn more" → Property tab opens
- [ ] Tap "Got it" → card dismisses permanently
- [ ] Kill + relaunch app → backfill does NOT re-run (`hasRunDay1CuratorBackfillP66_v1` flag set)

---

## 13. Rollback plan (if this fails in TestFlight)

If a critical bug surfaces:

- [ ] **Option A (UI-only rollback):** revert `DashboardView.swift` + `PropertyDetailView.swift` to point back at `MaintenanceScheduleView()` instead of `MaintenanceHubView()`. Ship a hotfix build. New columns stay live; tasks stay parented but are invisible in the old UI (tasks in routines just disappear — not ideal but contained).
- [ ] **Option B (full data rollback):** run `UPDATE maintenance_tasks SET parent_routine_id = NULL, bundle_parent_task_id = NULL WHERE parent_routine_id IS NOT NULL OR bundle_parent_task_id IS NOT NULL;` to unparent every task. Old UI works fully. Hub still renders but with empty child lists.
- [ ] **Option C (nuclear):** drop columns via a new migration. Not recommended — partial data loss on any pending-vendor routines.

Prefer A. Only escalate to B if tasks go invisible and users complain.

---

## Sign-off

- [ ] All sections passed for Tier A (`.hireOut`)
- [ ] Core path verified for Tier B (`.mixed`)
- [ ] Core path verified for Tier C (`.diy`)
- [ ] No regressions on the old Scheduled / To-Schedule bucket view
- [ ] Analytics firing correctly
- [ ] TestFlight user reorganized card dismisses cleanly
- [ ] Ready to ship Build 95

Tester name + date: _____________________
