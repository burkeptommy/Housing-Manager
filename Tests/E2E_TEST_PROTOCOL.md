# Haven End-to-End Test Protocol

This document is the canonical playbook for exercising every major workflow in Haven. Each test is a self-contained scenario with an explicit goal, setup, steps, and expected outcomes. Run these manually during release candidacy, or drive them via the computer-use MCP in simulator.

Intended audience: Tom (author-led QA), future Claude Code agents running automated runs, and any contributor onboarding to the codebase.

---

## Pre-flight checklist

Before any test run, verify:

1. **Simulator booted + Haven installed.** `xcrun simctl list devices | grep Booted` returns a device. `xcrun simctl get_app_container booted com.havenhome.app` succeeds.
2. **Logged in.** Dashboard renders with the user's name in the greeting. If stuck at AddressHook, log in manually with a TestFlight account.
3. **At least one property exists.** Property tab shows at least one property row. If not, complete onboarding + quiz first.
4. **Supabase production migrations current.** `supabase db push --linked` is idempotent — run once to confirm no pending migrations.
5. **Edge functions deployed.** `supabase functions list` — `chat`, `process-invoice`, `simulate-scenario`, `extract-vendor`, and `property-lookup` should all show recent deploys.

---

## Workflow 1 — Dashboard surface renders correctly

**Goal:** Every dashboard card flows correctly and routes to a valid destination.

**Steps:**
1. Open app → Dashboard tab.
2. Verify greeting with user's first name + seasonal context tip.
3. Verify HomeCoverageHero shows "{N} of {M} systems covered", "{K} active vendors", "Next visit: {vendor} {date}" when applicable.
4. Verify QuickActionsRow: Alfred / Upload / Scenarios / Add Vendor icons all tappable.
5. Verify "Up Next" section shows tasks (or empty state "Nothing to schedule in the next 60 days").
6. Verify RecentActivityFeed shows recent events (task completions, vendor adds, document uploads).
7. Scroll to bottom — FoundationCard renders with trust signals.

**Pass if:**
- No tab transitions cause a crash.
- All cards render with real data (not skeletons stuck forever).
- Tap targets work (Alfred opens chat, Upload opens document picker, etc.).

---

## Workflow 2 — Scenario Studio: "What if I sold my house today?"

**Goal:** The Scenario Studio pre-fills the home value from the primary property and validates empty input.

**Preconditions:**
- Primary property has `current_estimated_value` set (ATTOM or manual override).

**Steps:**
1. Dashboard → Scenarios quick action OR FAB "What If?" button.
2. Accept disclaimer if first run.
3. Tap "Home & Property" category.
4. Tap "What if I sold my house today?"

**Expected (Bug B2 fix):**
- Scenario Details sheet opens.
- **Estimated sale price field is pre-populated** with the property's current estimated value (e.g. $955,623). NOT empty.
- Run Scenario button is enabled.

**Steps continued:**
5. Clear the pre-filled amount (select all, delete).
6. Tap "Run Scenario" with empty field.

**Expected (Bug B3 fix):**
- Alert fires: "Please fill in all fields — One of the scenario parameters is empty..."
- Sheet does NOT dismiss.
- Error haptic fires.

**Steps continued:**
7. Type a value (e.g. `950000`) via the keyboard.
8. Tap Run Scenario.

**Expected:**
- Submitted banner shows.
- Sheet dismisses.
- Push notification "Scenario Complete" fires within 30s.
- Opening the notification / re-opening the scenario studio → History tab → new entry.

**Pass if:** All 3 outcomes above are observed.

---

## Workflow 3 — Property Overview + value editing

**Goal:** Property overview renders, investment summary math is correct, value editing persists.

**Steps:**
1. Dashboard → Property tab → tap primary property.
2. Verify header: address, type (Single Family), zip code, estimated value.
3. Verify InvestmentSummaryCard:
   - Estimated value displayed as `$X` with range band beneath.
   - "Range based on comparable sales and public market data" caption.
   - Total invested row.
   - Horizontal bar split showing Purchase ${purchase_price} + Surplus ${surplus} components.
   - Net after sale (8% fees) row.
   - Unrealized gain row matches `estimated_value - total_invested`.
4. Tap Edit pencil next to "Estimated value."

**Expected:**
- Sheet opens with current value pre-filled.
- Save button enabled.

**Steps continued:**
5. Change value to `975000`. Tap Save.

**Expected:**
- Sheet dismisses.
- Overview re-renders with new value.
- Range band goes away OR flips to manual-override caption ("From your estimate").
- Refresh dashboard — HomeCoverageHero's value signal updates.

**Pass if:** Value persists to DB (verify via Supabase Studio: `properties.current_estimated_value = 975000` for this property).

---

## Workflow 4 — Maintenance tab + handyman visit E2E

**Goal:** Phase 67 handyman visit flow works: children materialize, claim/unclaim, schedule, complete.

**Steps:**
1. Property detail → Maintenance tab.
2. Verify stats pills: Overdue / This Week / This Month / Later.
3. Verify buckets SCHEDULED + TO SCHEDULE both render.
4. Scroll to find "Spring Handyman Visit" OR "Fall Handyman Visit".
5. Tap the handyman visit task.

**Expected:**
- `HandymanVisitDetailView` opens (NOT the generic `MaintenanceTaskDetailSheet`).
- Header shows bundle title ("Fall Handyman Visit"), due date, contractor info (handyman name + phone), OR "Add a handyman" CTA.
- **"WHAT'S INCLUDED · N"** section with ≥5 rows, each with an "I'll do this" claim button.
- No "Nothing for the handyman this visit" empty state (unless literally no children apply to the property).

**Steps continued:**
6. Tap "I'll do this" on one item (e.g. "Drain and store exterior hoses").

**Expected:**
- Row moves to "YOU'LL HANDLE · 1" section.
- "WHAT'S INCLUDED · N" count decreases by 1.
- Toast / haptic feedback.

**Steps continued:**
7. Close the visit sheet. Return to Maintenance main list.

**Expected:**
- New "Drain and store exterior hoses" row appears in TO SCHEDULE as a standalone DIY task.
- The 24-ish TO SCHEDULE count increased by 1.

**Steps continued:**
8. Re-open the Fall Handyman Visit.
9. Tap "Give back" on the DIY claim.

**Expected:**
- Row returns to WHAT'S INCLUDED.
- Standalone task disappears from main list.

**Steps continued:**
10. With preferred handyman linked, tap "Schedule visit."

**Expected:**
- Date picker opens.
- Pick a date → Save → header updates to "Scheduled: {date}."

**Steps continued:**
11. Tap "Mark visit complete."

**Expected:**
- Confirmation dialog.
- Tap "Mark complete."
- Every child with `assigned_route = "handyman"` gets `last_completed_date` set + next-due advanced.
- DIY-claimed children are untouched.
- Sheet dismisses.

**DB verification (Supabase Studio):**
- `SELECT title, last_completed_date, next_due_date, assigned_route FROM maintenance_tasks WHERE template_id LIKE 'Handyman:fall%' ORDER BY title;`
- Confirm parent + all handyman-routed children have same `last_completed_date = today`.
- DIY-claimed children show NULL `last_completed_date` or old value.

**Pass if:** All 11 steps succeed end-to-end.

---

## Workflow 5 — Custom task creation + vendor assignment

**Goal:** User can add a custom maintenance task, route it to a vendor, and complete it.

**Steps:**
1. Property → Maintenance tab → tap `+` toolbar button.
2. Select "Add task" (vs Recurring service, Routine).
3. Form opens:
   - Task kind picker: Maintenance / Vendor visit / Follow-up.
   - Pick "Maintenance."
   - Title: type "Test custom task for E2E"
   - Target: Property (default) → select primary property.
   - System: leave as "None".
   - Frequency: "Annually"
   - Due date: pick 30 days from today.
   - Priority: "Medium"
4. Tap Save.

**Expected:**
- Sheet dismisses.
- Custom task appears in TO SCHEDULE with title + Medium priority.

**Steps continued:**
5. Tap the custom task.

**Expected:**
- Generic MaintenanceTaskDetailSheet opens (NOT handyman visit detail).
- Fields: title, frequency (Annually), priority (Medium), due date, Scheduling section.

**Steps continued:**
6. In Scheduling section, tap "Assign a vendor" / Find a Pro.
7. Contractor directory opens → pick Blue Fox Landscaping.

**Expected:**
- Task is now vendor-managed: title reframed to "Schedule Blue Fox Landscaping: test custom task for E2E" (or similar).
- `assigned_contractor_id` set in DB.
- Description prepended with "Blue Fox Landscaping will handle the work..."

**Steps continued:**
8. Tap "I already did this" → mark complete.

**Expected:**
- Toast confirms completion.
- Task's `last_completed_date = today`, next due advanced by frequency.

**Pass if:** Task persists, vendor reframing applied, completion advances due date.

---

## Workflow 6 — Contacts directory + vendor assignment

**Goal:** Contractor directory renders with logos, search + filter work, adding a vendor flows through.

**Steps:**
1. Property → Contacts tab.
2. Verify contractors listed with brand logos (via Brandfetch):
   - ADT (Security System)
   - Blue Fox Landscaping (Landscaping, Routine tag)
   - DoodyCalls (Pet Waste, Routine tag)
   - Flying Colors Roofing
   - Handyman Express LLC
3. Search bar: type "fox" — list filters to Blue Fox.
4. Clear search. Tap "Routines" filter chip — only routine-served vendors show.
5. Tap "All" chip.
6. Tap "+Add" top-right.

**Expected:**
- `AddVendorSheet` opens with options: Paste URL / Contacts / Manual.
7. Tap "Manual".
8. Fill: Company name "Test Vendor E2E" · Phone "5551234" · Category "HVAC" · Specialties "HVAC".
9. Tap Save.

**Expected:**
- Contractor row appears in list with manual-source indicator.
- `contractors` DB row created with `source = "manual"`.

**Pass if:** Vendor lifecycle works (add → list → remove via swipe).

---

## Workflow 7 — Alfred chat

**Goal:** Alfred sends user message to edge function, receives response, renders nicely.

**Pre-fix (pre-Bug-B4):** If post-reinstall, chat shows many bubbles of "🔒 This message was encrypted..." messages. **Post-fix:** only ONE bubble.

**Steps:**
1. Dashboard → Alfred tab (bottom-right, "A" icon).
2. Verify message list:
   - If fresh install: single "encrypted" placeholder sentinel OR empty state.
   - If primary device: historical messages visible and decrypted.
3. Input field at bottom: "Ask Alfred..." placeholder.
4. Type: "What maintenance is coming up?" → Send.

**Expected:**
- User message bubble appears (salmon, right-aligned).
- Typing indicator appears.
- Within 10s, Alfred's response bubble renders (cream, left-aligned, with avatar).
- Response references the user's actual data (e.g. "Your Fall Handyman Visit is due Oct 1").

**Pass if:** Alfred responds coherently within 10s AND references real household context.

---

## Workflow 8 — Projects: view detail, upload quote

**Goal:** Project surfaces ROI, quote analysis, vendor linking.

**Steps:**
1. Property → Projects tab.
2. Verify existing project ("Oil-Fired Furnace Replacement...") shows with "In Progress" / "Pro" badges.
3. Tap the project.

**Expected:**
- Project detail:
  - Title + badges.
  - ROI ESTIMATE card: "70-85% typical return", High ROI tag, description, Pro Cost range, DIY Cost range, Value Increase %, Time to Recoup.
  - Tip banner.
  - QUOTES · 1 section: Tyler Heating $18,882 (Fair: $17,700, Overpriced tag).
  - "Upload Another Quote" row.

**Steps continued:**
4. Tap the existing quote row.

**Expected:**
- Quote detail opens with line items, market analysis, overall rating.

**Pass if:** Project detail renders fully with ROI + quotes.

---

## Workflow 9 — Life tab: documents + estate readiness

**Goal:** Life tab shows family avatars, estate readiness card, advisors directory, document list.

**Steps:**
1. Bottom nav → Life.
2. Verify Documents / Family segmented picker.
3. Family avatars row: All / {each family member by name}.
4. Estate readiness card:
   - Percentage complete (e.g. "20%")
   - Progress ring visualization.
   - "Prepare Summary" CTA OR "Upload documents first" alternative.
5. YOUR ADVISORS section: Cohen and Wolf P.C. (Estate Attorney), EY (Ernst & Young) (CPA/Tax Advisor), Edward Jones, MetLife — each with logo tile.
6. Scroll down — documents list (categories like Bills, Insurance, Real Estate).
7. Tap Family picker → family-scoped view.

**Pass if:** All sections render; tapping any family avatar filters documents.

---

## Workflow 10 — Settings: TOS/Privacy links + preferences

**Goal:** Settings preferences save correctly and legal links point to the right domain.

**Steps:**
1. Dashboard → ⚙️ Settings top-right.
2. Scroll to ABOUT section.
3. Tap "Terms of Service."

**Expected (Bug fix verified):**
- Safari opens to `https://havenhome.dev/terms` (NOT `havenhome.app`).
- Page shows "Haven Terms of Service" with "Last updated" date.
- Domain indicator in Safari bar reads `havenhome.dev`.

**Steps continued:**
4. Return to app. Tap Privacy Policy.

**Expected:** Same — opens `havenhome.dev/privacy`.

**Steps continued:**
5. Return to app. Tap Contact Support.

**Expected:** Mail composer opens with `tom@havenhome.dev` in the To field.

**Steps continued:**
6. Back to Settings. Tap Maintenance Preferences.
7. Verify 3 tiers: DIY / Mix of both / Hire it out.
8. Select a different tier and Save.
9. Dialog: "This will rebalance your maintenance tasks. Continue?" → Save and rebalance.

**Expected:**
- Toast "Saved. Updated N tasks." (or "No task changes needed" if already in that tier's state).

**Steps continued:**
10. Back. Tap Handyman Preference.
11. If household has a Handyman contractor AND attribute is unset: verify default is "I have one I use regularly" (Bug B5 fix).
12. Change to "I prefer to handle things myself." Save.

**Expected:**
- Toast "Saved."
- Sheet dismisses.

**Steps continued:**
13. Back. Tap Task Routing.
14. Verify empty state "No per-category preferences yet" with explanatory copy about Q36 tier.

**Pass if:** All settings save; legal links resolve to `havenhome.dev`.

---

## Workflow 11 — Legacy Tasks view

**Goal:** Dashboard "We Tidied Your List" card opens a grouped list of archived tasks.

**Steps:**
1. Dashboard — scroll to find "WE TIDIED YOUR LIST" card with count.
2. Tap "View details."

**Expected:**
- `LegacyTasksView` opens with sections grouped by archive reason:
  - "DOESN'T APPLY TO YOUR HOME" (subtype mismatch)
  - "ROLLED INTO A SERVICE VISIT" (bundle consolidation)
  - "RETIRED FROM HAVEN'S LIBRARY" (Phase 61)
  - "TIDIED UP" (general)
3. Tap any row.

**Expected:**
- Detail sheet with title, description, reason, archived-on date.

**Pass if:** Archived tasks render grouped, detail sheet shows reason.

---

## Workflow 12 — Invoice upload → task auto-complete

**Goal:** Forward a vendor invoice → Haven auto-matches tasks, discovers systems, extracts follow-ups.

**Preconditions:**
- Have a test invoice PDF (any home-services invoice works).
- User has the household forwarding email copied.

**Steps:**
1. Email the invoice PDF to `{user-slug}@alfred.havenhome.dev`.
2. Wait ~30-60s.
3. Push notification "Processing invoice..." arrives.
4. Open Dashboard → Inbox (top-right icon).
5. Verify invoice appears as an Inbox item with extracted fields.
6. Tap the item → `InboxItemDetailView` opens.
7. Verify AI extraction:
   - Vendor name + phone auto-populated.
   - Line items listed.
   - Matched tasks highlighted.
   - Follow-ups proposed.
8. Tap "Apply changes."

**Expected:**
- Tasks marked complete.
- If new systems discovered: specialty suggestion card offers to add.
- Follow-up tasks created (e.g. "Return visit in 4 weeks").

**Pass if:** Invoice processes end-to-end, tasks advance, vendor row created/updated.

---

## Workflow 13 — Add vehicle + VIN decode

**Goal:** Add a vehicle via VIN, verify NHTSA decode, recalls fetch, maintenance schedule generation.

**Steps:**
1. Property tab → scroll to Your Garage → "Add your first vehicle" CTA.
2. Vehicle add sheet opens.
3. Enter VIN: `1HGBH41JXMN109186` (sample Honda Accord VIN).
4. Tap Decode.

**Expected:**
- Year / make / model / trim auto-populated.
- AI maintenance schedule generated.
- NHTSA recalls checked (may return empty for sample VIN).

**Steps continued:**
5. Enter mileage: 50000. Save.

**Expected:**
- Vehicle appears in garage section.
- Tasks created: oil change, tire rotation, inspection based on mileage.

**Pass if:** VIN decodes within 15s, tasks created, vehicle shows in garage.

---

## Workflow 14 — Routine (recurring vendor visit) creation

**Goal:** Add a routine (e.g. weekly trash pickup) and verify occurrence expansion.

**Steps:**
1. Property → scroll to Routines row (or nav to "routines" destination).
2. Tap "+" to add routine.
3. Select kind: "Trash" / or any waste type.
4. Configure: Day of week + time-of-day + reminder toggles.
5. Save.

**Expected:**
- Routine appears in Routines list.
- Dashboard PickupDayBanner surfaces evening before / morning of.
- Maintenance tab's "ONGOING ROUTINES" pill strip shows the new routine.

**Pass if:** Routine renders across surfaces.

---

## Workflow 15 — Document upload → analyze

**Goal:** Upload a document → AI categorization → estate metadata extraction.

**Steps:**
1. Life tab → tap `+` to upload (or Dashboard → Upload quick action).
2. Pick a PDF from Files.
3. Select category (or let AI suggest).
4. Wait for AI analysis (banner: "Analyzing document...").

**Expected:**
- Banner shows progress.
- Push notification: "Document analyzed."
- Inbox item created with AI summary, extracted parties, key dates.
- For estate docs (Will, POA): estate_state upserts.

**Pass if:** Document processes, categorization applied, estate state updates for estate categories.

---

## Workflow 16 — Multi-property flow

**Goal:** Adding a second property preserves handyman preference, creates separate visit bundles.

**Steps:**
1. Property tab → toolbar `+`.
2. Add property (new address).
3. Complete onboarding quiz for it.

**Expected:**
- New property has its own Spring + Fall handyman visit bundles.
- Dashboard aggregates across both properties.
- Property filter pill appears in Maintenance tab.

**Pass if:** Per-property visits materialize; global vs property-filtered views work.

---

## Regression tests (cover shipped bugs)

Run after any reconciler / template / routing change:

### R1 — Bundle children don't leak to main list
- Query DB: `SELECT COUNT(*) FROM maintenance_tasks WHERE template_id LIKE 'Handyman:%_spring' OR template_id LIKE 'Handyman:%_fall';`
- Count matches # of bundle children visible in the visit detail (not in main list).
- Main Maintenance TO SCHEDULE count does NOT include bundle children.

### R2 — Phase 61 orphan archive idempotent
- Run reconcile pass twice. Second run archives 0 tasks.

### R3 — Q36 tier vs routing preferences precedence
- Set Maintenance Preferences to "Hire it out."
- Create a plumbing task. Route to DIY via task detail.
- Create another plumbing task → verify it routes to DIY (category preference overrode tier).

### R4 — Quiz resumability
- Start quiz Chapter 2 → background app mid-question.
- Resume → lands on same question, previous answers intact.

### R5 — Scenario params persist
- Run "What if I sold my house" with a custom value (not the default).
- Go back, re-open → custom value should NOT be remembered (each run is fresh).
- But History tab should show the completed run with its parameters recorded.

---

## DB-level verification queries

Useful SQL snippets for Supabase Studio:

```sql
-- Count bundle parents + children for a property
SELECT
  COUNT(*) FILTER (WHERE template_id = 'Handyman:spring') AS spring_parents,
  COUNT(*) FILTER (WHERE template_id LIKE 'Handyman:%_spring') AS spring_children,
  COUNT(*) FILTER (WHERE template_id = 'Handyman:fall') AS fall_parents,
  COUNT(*) FILTER (WHERE template_id LIKE 'Handyman:%_fall') AS fall_children
FROM maintenance_tasks
WHERE property_id = '{PROPERTY_ID}' AND is_archived = false;

-- Expected: 1 parent, ~10 children per season.

-- Handyman preference distribution across properties
SELECT attributes->>'handyman_preference' AS pref, COUNT(*)
FROM properties
GROUP BY attributes->>'handyman_preference';

-- Legacy archived task count per reason
SELECT archived_reason, COUNT(*)
FROM maintenance_tasks
WHERE is_archived = true
GROUP BY archived_reason
ORDER BY COUNT(*) DESC;

-- Routing preferences per household
SELECT household_id, scope_type, COUNT(*)
FROM routing_preferences
GROUP BY household_id, scope_type;

-- Tasks with null assigned_route (should be rare post-Phase-64 backfill)
SELECT COUNT(*) FROM maintenance_tasks
WHERE is_archived = false AND assigned_route IS NULL;
```

---

## Execution modes

### Mode A: Manual QA (Tom)
Go through each workflow in order. Check off passes. File tickets for failures.

### Mode B: Claude Code agent run
Agent has computer-use access to Simulator. Scripts a simctl boot + install + launch, then uses `mcp__computer-use__*` tools to tap through each workflow. Compare screenshots at key checkpoints.

### Mode C: XCUITest (future)
Convert each workflow into `XCUITest` test function. CI-friendly. Blocked on: adding a UI test target (requires XcodeGen update — see `project.yml`).

---

## Known limitations

- **Simulator keyboard:** The macOS Simulator's hardware keyboard sometimes produces accent-picker artifacts when an iOS text field gets focus. Use `xcrun simctl ui booted keyboard` configuration to disable, OR tap through flows that don't require heavy typing.
- **Auth:** The app requires Sign in with Apple. Agents running headless need a TestFlight user's credentials or shared test account.
- **Edge function cold starts:** First call after a deploy can take 5-10s. Second call is fast.
- **Push notifications:** Require device token registration. Simulator supports, but ensure "Allow notifications" was granted on first launch.

---

*Last updated: 2026-04-19 — covers Phases 61–67.*
