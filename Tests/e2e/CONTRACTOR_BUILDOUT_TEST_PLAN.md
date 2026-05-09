# Chez Contractor — overnight buildout test plan

Comprehensive E2E test plan that exercises every wave shipped from `CONTRACTOR_MOBILE_BUILDOUT_PLAN.md` (M1-M13) + `CONTRACTOR_WEB_BUILDOUT_PLAN.md` (W1-W20 + B1-B7).

11 verification waves (T1-T11). Each is dispatched independently as a subagent so screenshots stay out of the main thread context. Each wave verifies a coherent slice of functionality across **all three surfaces** — Operations Desk web, Chez Field PWA, iOS Haven app — and confirms cross-app parity via service-role JWT DB cross-check.

This plan is designed to run **overnight in parallel** — most waves are independent and can fire concurrently in their own subagent threads.

---

## Pre-flight (every test wave)

1. Read `/tmp/ui-test/CONTRACTOR_SETUP.md` (env, fixtures, JWT, test users)
2. Verify `Tests/e2e/cleanup-contractor.sql` has been applied to start with a clean DB slate
3. Run `Tests/e2e/run-contractor.mjs` to seed:
   - **W1**: solo workspace (1 owner, no crew)
   - **W2**: crew of 6 workspace
   - **W3**: crew of 25 workspace (stress test)
   - 11 customers (varied chez_profile depths), 21 quotes, 28 visits, 146 punch items, 5 chez admin inbound flavors
4. `mcp__Claude_in_Chrome__list_connected_browsers` returns ≥ 1 (for Chrome MCP)
5. iOS simulator booted: `xcrun simctl list devices | grep Booted` — boot one if needed
6. Three browser viewports prepared:
   - **1440×900** (Operations Desk default)
   - **390×844** (Chez Field PWA — iPhone 14 Pro)
   - **iOS Haven app** in iOS simulator at iPhone 16 Pro device

After every test wave:
- Cross-app DB cross-check via service-role JWT
- 1-3 screenshots per surface checked
- JSON output block in standard format
- If FAIL: log entry in `Tests/e2e/CONTRACTOR_BUILDOUT_FAILURES.md` with reproduction steps

---

## Test wave T1 — Visit lifecycle parity (M1 + B1)

**Verifies:** clock-in/out + GPS + pause/resume on mobile lands as billable seconds on web + as visible state changes on iOS homeowner thread.

**Steps:**

1. **Mobile (390×844):**
   - Sign in as W2 contractor (`e2e-contractor-w2@chezcontractor.test`) on Chez Field PWA
   - Tap visit assigned to Customer 4
   - Tap "Start visit" → grant geolocation permission → confirm clock-in
   - Verify UI shows running clock + GPS pin
   - Tap "Pause" → reason "Lunch" → confirm
   - Wait 30 sec → tap "Resume"
   - Tap "Complete visit"

2. **Web (1440×900):**
   - Sign in as W2 contractor on Operations Desk
   - Navigate to `/visits/<assignmentId>` → VisitDetail
   - Verify "TIME ON-SITE" stat shows clock-in to clock-out minus 30 sec pause
   - Verify GPS pin renders on address line as "verified arrival"
   - Verify pause history shows "Lunch (30 sec)"
   - Verify status badge progressed: scheduled → in_progress → completed

3. **iOS (homeowner side):**
   - Boot Haven sim, sign in as `e2e-customer-of-contractor-c04@havenhome.test`
   - Tasks tab → Contractor → tap thread for Customer 4 visit
   - Verify thread shows status-change system messages: "Visit started" → "Visit completed"
   - Verify no "handyman" in any user-facing string

4. **DB cross-check:**
   ```sql
   SELECT clock_in_at, clock_out_at, paused_seconds, clock_in_lat, clock_in_lng
   FROM provider_visit_assignments
   WHERE request_id = '<requestId>';

   SELECT count(*) FROM provider_visit_pauses WHERE assignment_id = '<assignmentId>';
   -- Expected: 1
   ```

**Pass criteria:** all three surfaces reflect the same lifecycle; total elapsed = clock_out - clock_in - paused_seconds; GPS coords stored; pause row created; status messages on iOS thread; no "handyman" string anywhere user-facing.

**Effort:** 30 min. **Subagent type:** general-purpose.

---

## Test wave T2 — Punch capture parity (M2)

**Verifies:** photos + voice + materials + per-item time captured on mobile lands on web post-visit review + on iOS homeowner thread as evidence.

**Steps:**

1. **Mobile (390×844):**
   - Open active visit → punch list section
   - On 3 punch items, perform:
     - 📷 Tap → camera fixture image → resize → upload (verify thumbnail renders inline)
     - 🎤 Tap → record 5-sec voice note → playback → confirm save
     - 📦 Tap → add 2 materials with qty + unit_cost (verify materials list renders)
     - ⏱ Tap → start timer → wait 60s → stop (verify mm:ss saved on item)

2. **Web (1440×900):**
   - VisitDetail.tsx → Post-visit review section (W15)
   - Verify each item shows attachments grid + voice playback control + materials list with cost + per-item time
   - Verify cost roll-up at bottom of materials section

3. **iOS (homeowner side):**
   - Tasks tab → Contractor → thread → tap "View visit details"
   - Verify photos grid renders (read-only)
   - Verify materials with cost render
   - Verify per-item time renders

4. **DB cross-check:**
   ```sql
   SELECT id, jsonb_array_length(attachments) AS photo_count,
          jsonb_array_length(materials_used) AS materials_count,
          time_spent_seconds, voice_note_path
   FROM handyman_punch_items
   WHERE id IN (<item_ids>);
   ```

**Pass criteria:** ≥ 3 items have photo_count ≥ 1, materials_count ≥ 1, time_spent_seconds ≥ 60, voice_note_path NOT NULL.

**Effort:** 30 min.

---

## Test wave T3 — System inventory authoring parity (M3 + W17)

**Verifies:** mobile sweep mode + web authoring both write to `home_systems`; both visible on web HomeDetail Systems tab + iOS Property tab.

**Steps:**

1. **Mobile (390×844):**
   - Active visit → "+ Add system" → camera-first flow
   - Snap fixture model plate image (e.g. furnace nameplate)
   - Verify AI extracted brand/model/serial → confirm save
   - Add 2 more systems via bulk-add session counter ("3 systems added")
   - Long-press one system → "Mark as removed" reason "Replaced" → confirm
   - On a different system → toggle "Mark for follow-up" → reason "Couldn't access today"
   - Add a voice note to one system

2. **Web (1440×900):**
   - HomeDetail.tsx → Customer 4 → Systems sub-tab
   - Verify all 3 newly-added systems appear with brand/model/serial
   - Verify decommissioned system shows status="decommissioned" + reason
   - Verify follow-up flag system shows amber badge + reason
   - Verify voice note plays inline
   - Test web inline edit affordance: edit one system's serial → save → reload → persisted

3. **iOS (homeowner side):**
   - Property tab → tap home → Systems section
   - Verify 3 newly-added systems appear with category icons
   - Verify decommissioned system NOT in list (or shown as removed)
   - Verify follow-up system shows amber badge

4. **DB cross-check:**
   ```sql
   SELECT category, name, brand, model, serial_number, status, decommissioned_at,
          marked_for_followup_at, followup_reason, voice_note_path
   FROM home_systems
   WHERE household_id = '<customer_4_household_id>'
   ORDER BY created_at DESC LIMIT 10;
   ```

**Pass criteria:** all 3 systems present with brand/model/serial; decommission reason persisted; follow-up reason persisted; voice note path stored; cross-app parity confirmed.

**Effort:** 45 min.

---

## Test wave T4 — In-person sale parity (M4 + W9 + W20)

**Verifies:** mobile quote builder + e-Signature + web quote workflow + bundles all converge on a single quote that homeowner sees + signs.

**Steps:**

1. **Mobile (390×844):**
   - Visit → "Build quote" sheet
   - Pre-fill from punch list (verify line items pre-populated)
   - Add a 3-tier good/better/best toggle → enter prices for each
   - Attach a fixture photo to one line item
   - Tap "Send"
   - "Have customer sign here" → use trackpad to draw signature on canvas → enter name "Test Customer"
   - Confirm save → upload signature

2. **Web (1440×900):**
   - Quotes.tsx → list view → find new quote → tap to open detail
   - Verify 3 tiers render with prices
   - Verify line item photos render
   - Verify "Signed by Test Customer on <date>" caption visible
   - Verify signature image renders

3. **iOS (homeowner side):**
   - Inbox → quote bundle landed → tap to open
   - Verify 3 tiers render with prices
   - Verify line items + photos render
   - Verify Approve / Counter / Decline buttons visible (B-card-style)
   - Tap Approve → verify status flip
   - Verify signature visible on quote detail

4. **DB cross-check:**
   ```sql
   SELECT pq.id, pq.signature_path, pq.signed_name, pq.signed_at,
          (SELECT count(*) FROM provider_quote_line_items WHERE quote_id = pq.id) AS line_item_count,
          jsonb_array_length(pq.metadata->'tiers') AS tier_count
   FROM provider_quotes pq
   WHERE pq.id = '<quote_id>';
   ```

**Pass criteria:** signature_path NOT NULL; signed_name stored; line items count ≥ punch item count; 3 tiers stored; homeowner sees same on iOS; cross-app parity confirmed.

**Effort:** 45 min.

---

## Test wave T5 — On-site invoice parity (M5 + W15)

**Verifies:** visit completion → invoice conversion → operator QC → send to homeowner → render on iOS inbox.

**Steps:**

1. **Mobile (390×844):**
   - Visit completion screen (post clock-out)
   - Tap "Build invoice" → "Pre-fill from this visit"
   - Verify line items: each completed punch item with labor + materials
   - Tap "Send to customer"

2. **Web (1440×900):**
   - VisitDetail → "Awaiting QC" pill
   - Operator reviews photos + materials + time
   - Tap "Approve for billing"
   - Verify invoice send path unblocked
   - Verify "Approved by [Operator] at [Time]" annotation

3. **iOS (homeowner side):**
   - Inbox → "Invoice received: <Workspace>" inbox row
   - Tap to view → verify invoice line items + total + tax
   - Verify Pay button (or "Mark paid" if Stripe deferred)

4. **DB cross-check:**
   ```sql
   SELECT pi.id, pi.total_cents, pi.tax_cents, pi.sent_at,
          pva.reviewed_for_billing_at, pva.reviewed_by_user_id
   FROM provider_invoices pi
   JOIN provider_visit_assignments pva ON pi.related_visit_id = pva.id
   WHERE pi.id = '<invoice_id>';
   ```

**Pass criteria:** invoice exists; QC stamp present; iOS inbox row landed; line items match completed punch items.

**Effort:** 30 min.

---

## Test wave T6 — Web settings + admin verify (W1 + W2)

**Verifies:** workspace settings save/persist/propagate; crew admin shows full timesheets/certifications/performance.

**Steps:**

1. **Web (1440×900) — Settings (W2):**
   - `/settings` → upload logo → set brand color → save
   - Reload → verify logo + color persisted
   - Set business hours (Sat closed, Mon-Fri 8-5)
   - Set tax rate 8.875% + materials markup 25%
   - Add 2 holidays (Memorial Day, July 4)
   - Save → reload → verify all persisted
   - Open new quote → verify tax rate auto-applied to total

2. **Web (1440×900) — Crew (W1):**
   - `/crew` → tap a tech → Profile → Timesheets sub-section
   - Verify week-by-week breakdown (driven by M1 clock-in data from T1)
   - Tap Approve → verify approved_at stamped
   - Certifications sub-section → "+ Add" → upload fixture cert PDF → save
   - Verify cert appears with expiry date pill (amber if within 30d, red if expired)
   - Performance sub-section → verify last 50 visits with star ratings

3. **DB cross-check:**
   ```sql
   SELECT logo_path, brand_color, tax_rate, materials_markup_pct,
          business_hours, holidays
   FROM provider_workspaces
   WHERE id = '<W2_workspace_id>';

   SELECT count(*) FROM provider_member_timesheets
   WHERE workspace_id = '<W2_workspace_id>'
     AND approved_at IS NOT NULL;
   ```

**Pass criteria:** settings persist across reload; logo renders on quote PDF; tax rate auto-applies; timesheet approved; certification uploaded.

**Effort:** 45 min.

---

## Test wave T7 — Web reporting accuracy (W4)

**Verifies:** revenue, jobs, utilization, marketing dashboards compute correctly from underlying data.

**Steps:**

1. **Web (1440×900):**
   - `/reports` → Revenue sub-tab → range "Month"
   - Verify gross + paid + outstanding totals match sum of `provider_invoices` for the month
   - Manually compute via SQL: `SELECT sum(total_cents) FROM provider_invoices WHERE workspace_id = ? AND sent_at >= date_trunc('month', now())`
   - Cross-check the chart line endpoints against series data

2. Jobs sub-tab:
   - Verify funnel chart 5 stages match counts of `handyman_requests` by status
   - Verify cancel rate = cancelled / total

3. Utilization sub-tab:
   - Per-tech billable hours match `sum(EXTRACT(EPOCH FROM clock_out - clock_in) - paused_seconds)` from `provider_visit_assignments`

4. Marketing sub-tab:
   - Lead source breakdown matches `count(*) GROUP BY lead_source` on `handyman_requests`

5. **DB cross-check:** materialized views recomputed:
   ```sql
   SELECT * FROM provider_revenue_daily WHERE workspace_id = '<W2>' AND day = current_date;
   SELECT * FROM provider_jobs_daily WHERE workspace_id = '<W2>' AND day = current_date;
   SELECT * FROM provider_tech_utilization_daily WHERE workspace_id = '<W2>' AND day = current_date;
   ```

**Pass criteria:** every chart number ties out to underlying SQL aggregates; no off-by-one errors; period-over-period delta correct.

**Effort:** 45 min.

---

## Test wave T8 — Web pipeline + cases (W5 + W6)

**Verifies:** Kanban drag-and-drop + lead source attribution + case management.

**Steps:**

1. **Web (1440×900) — Pipeline (W5):**
   - `/quotes` → Kanban view toggle
   - Drag a "Sent" quote card to "Negotiating"
   - Reload → verify pipeline_stage = 'negotiating' persisted
   - Drag to "Lost" → reason modal → "Price too high" → confirm
   - Verify lost_reason + lost_at stamped
   - Verify won/lost rate updates in summary tiles
   - Set lead_source on a quote ("Google Ads") → save → verify in Marketing report (W4)

2. **Web (1440×900) — Cases (W6):**
   - `/cases` → "+ New case" → type "Warranty" → title "Leak came back" → link to existing visit
   - Verify case_number auto-generated (CC-2026-001)
   - Open case → reply with "Scheduled return visit for May 14"
   - Status → "Waiting Customer"
   - Verify status pill updates
   - Tap "Resolved" → resolution notes "Sealed valve" → confirm

3. **iOS (homeowner side):**
   - Inbox → case thread appears (system row "Case opened: Leak came back")
   - Reply: "Thanks!" → verify lands on web side

4. **DB cross-check:**
   ```sql
   SELECT pipeline_stage, lost_reason, lost_at, lead_source
   FROM provider_quotes WHERE id = '<quote_id>';

   SELECT case_number, status, resolution_notes, resolved_at
   FROM provider_cases WHERE id = '<case_id>';

   SELECT count(*) FROM provider_case_messages WHERE case_id = '<case_id>';
   -- Expected: ≥ 3 (initial + reply + resolution)
   ```

**Pass criteria:** drag-reorder persists; lost reason captured; case lifecycle full coverage; iOS thread visible.

**Effort:** 60 min.

---

## Test wave T9 — Web systems aggregate + quote workflow + dispatch (W7 + W8 + W9)

**Verifies:** workspace-wide systems list + drag-reorder routes + optimize-route + quote templates + change orders.

**Steps:**

1. **Web (1440×900) — Systems (W7):**
   - `/systems` → filter "Plumbing" → search "boiler"
   - Verify list shows boilers across all serviced households
   - Bulk select 3 → "Schedule visits for selected" → quick-create routine → confirm
   - Verify routine row created in `routines` for each household

2. **Web (1440×900) — Routes (W8):**
   - `/routes` → today's view → select tech with 5 stops
   - Drag stop 5 to position 1 → confirm reorder
   - Reload → verify stop_order array updated
   - Click "Optimize route" → verify drive time decreased + reorder happened
   - Click "Send to tech" → mock SMS confirmation → verify sent_to_tech_at stamped

3. **Web (1440×900) — Quotes (W9):**
   - Open existing quote → "Save as template"
   - New quote on different customer → "Apply template" → verify line items pre-filled
   - On approved quote → "+ Create change order" → add 2 line items → send
   - Verify change order row created + status pill on parent quote

4. **iOS (homeowner side):**
   - Inbox → change order proposal → tap to view → Approve/Decline
   - Tap Approve → verify status flip + DB update

5. **DB cross-check:**
   ```sql
   SELECT * FROM provider_routes WHERE member_id = '<tech_id>' AND route_date = current_date;
   SELECT * FROM provider_quote_templates WHERE workspace_id = '<W2>';
   SELECT * FROM provider_quote_change_orders WHERE parent_quote_id = '<quote_id>';
   ```

**Pass criteria:** all flows persist; route optimization computes; template saves + applies; change orders flow end-to-end.

**Effort:** 60 min.

---

## Test wave T10 — Cross-app B-wave parity (B1 + B2 + B3 + B4 + B5 + B6 + B7)

**Verifies:** pre-visit prep + chez_profile + chez-owned banner + read receipts + typing + archive + Alfred reply + schema cleanups.

**Steps:**

1. **B1 + B2 — Pre-visit prep on mobile + web:**
   - **Mobile:** Today screen → tap "Show prep" on first stop → verify chez_profile (logistics, vendor preferences, communication, spending tiers) + last visit notes + open punch items count + last 3 messages + safety flags
   - **Web:** VisitDetail → collapsible "Prep" section at top → same data structured

2. **B3 — Chez-owned banner:**
   - Open admin portal as Tom (`burkepthomas@gmail.com`)
   - Pick a customer → flip a routine to chez_owned
   - Reload contractor web (different W2 workspace assigned to that customer) — Homes list → row shows "Chez-managed" pill
   - Open HomeDetail → header shows banner: "Chez-managed customer — coordinate via Chez admin"
   - Verify mobile (visit detail) also shows banner

3. **B4 — Read receipts + typing:**
   - **Web:** open thread on Messages
   - **Mobile:** open same thread on PWA
   - On web, start typing in composer → verify "is typing..." pulse appears on mobile
   - On mobile, send a message → verify on web
   - Read on web → verify "Seen 2:14pm" caption appears on mobile sender side

4. **B5 — Archive + search:**
   - Archive a thread on web → confirm hidden from default list
   - Search "leak" in global search → verify message snippets with `<mark>` highlights
   - Restore archived thread → verify reappears

5. **B6 — Alfred reply suggestions:**
   - Open thread → tap "✨ Suggest reply" → verify 3 tone variants (warm/direct/formal)
   - Tap warm → inserts into composer

6. **B7 — Schema sanity:**
   - Issue a chez admin reply via admin portal → verify `sender_role='chez'` row inserted (no constraint violation)
   - Insert metadata on a `provider_visit_assignments` row → verify column exists
   - Insert a `chez_admin` source punch item → verify CHECK passes

**DB cross-check:**
```sql
SELECT id, sender_role FROM handyman_request_messages WHERE sender_role = 'chez';
SELECT count(*) FROM handyman_request_typing;
SELECT count(*) FROM handyman_request_messages WHERE read_by_recipients_at IS NOT NULL;
SELECT count(*) FROM handyman_punch_items WHERE source = 'chez_admin';
```

**Pass criteria:** all 7 B-waves visibly working across surfaces; schema cleanups confirmed; cross-app parity intact.

**Effort:** 75 min.

---

## Test wave T11 — Final demo dry-run (end-to-end)

**Verifies:** full demo script runs without breakage. This is the final sanity check before any demo.

**Demo script (run literally):**

1. **Sign in flow:** open `/handyman.html` → sign in as W1 solo workspace owner → redirect to `/operations/` → workspace switcher visible.

2. **Overview tab:** hero + KPI strip + Field board + Decision queue + Pipeline + Threads — verify content, no white-on-white, no "handyman" string.

3. **Dispatch:** unassigned column → drag a job to a tech's lane → verify assigned + persisted on reload.

4. **Calendar (Timeline):** today view → drag a visit to tomorrow → verify scheduled_date persisted.

5. **Routes:** today's tech → route mini-map renders → optimize → send-to-tech.

6. **Crew:** tap Bob → Profile → Timesheets / Certifications / Performance all populated.

7. **Homes:** Customer 4 → HomeDetail 12 sub-tabs → Systems / Services / Quotes / Invoices / Visits / Documents / Notes / Members / Vendors / Photos / Activity all render.

8. **Quotes:** Kanban view → drag Sent quote to Won → verify won_at stamped.

9. **Reports:** Revenue / Jobs / Utilization / Marketing all render with non-zero charts.

10. **Cases:** new case → reply → resolve.

11. **Marketing:** campaign with $500 spend → 4 leads → 2 won → ROI 240% computed.

12. **Inventory:** part SKU "PVC-1IN" → low stock alert → create PO → send.

13. **Mobile (Chez Field iOS app):** open Chez Field on the iOS Simulator (`com.havenhome.field`, scheme "Chez Field") → assigned visits appear → start visit → punch list capture → in-person quote → on-site invoice.

14. **iOS Haven app:** open as customer → verify all the above lands on Tasks tab → Contractor → thread.

15. **Voice / typography / discipline final sweep:** every screen = 0 "handyman" strings, 0 em dashes, 0 white-on-white, 0 missing nav active state.

**Pass criteria:** every step completes without error; every cross-app verification ties out; UI discipline checklist passes on every screen.

**Effort:** 60 min.

---

## Test wave order + parallelization

**Sequential (run first):** T1 (visit lifecycle is the foundation — many other waves depend on its data shape)

**Parallel batch A (after T1):** T2 + T3 + T4 — all build on T1's visit, can run concurrently in 3 separate subagents

**Parallel batch B (after batch A):** T5 + T6 + T9 — invoice/settings/dispatch are independent

**Parallel batch C (after batch B):** T7 + T8 + T10 — reporting/pipeline/B-waves independent

**Sequential (run last):** T11 (final dry-run)

**Recommended overnight schedule:**

```
Hour 0:00 — T1 dispatched (single subagent, ~30min)
Hour 0:30 — T2 + T3 + T4 dispatched in parallel (3 subagents, ~30/45/45min)
Hour 1:30 — T5 + T6 + T9 dispatched in parallel (3 subagents, ~30/45/60min)
Hour 2:30 — T7 + T8 + T10 dispatched in parallel (3 subagents, ~45/60/75min)
Hour 3:45 — T11 dispatched (single subagent, ~60min)
Hour 4:45 — Aggregate results, write CONTRACTOR_BUILDOUT_TEST_REPORT.md
```

Total: ~5 hours overnight. With 25% buffer: 6.25 hours. Comfortably fits an 8-hour overnight window.

---

## Per-wave subagent invocation template

In a fresh chat:

```
Read /Users/tomburke/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8/Tests/e2e/CONTRACTOR_BUILDOUT_TEST_PLAN.md

Execute Test wave T{N} via a general-purpose subagent. Use the wave's spec verbatim from the plan doc.

Each subagent:
1. Reads /tmp/ui-test/CONTRACTOR_SETUP.md first
2. Verifies prerequisites: cleanup applied, fixtures seeded, browsers/sim available
3. Runs the wave's exact step-by-step against all three surfaces (web 1440×900, mobile 390×844, iOS sim)
4. Performs the DB cross-check via service-role JWT
5. Captures 1-3 screenshots per surface
6. Returns the standard JSON block

If a step fails:
- Log full reproduction in Tests/e2e/CONTRACTOR_BUILDOUT_FAILURES.md
- Continue with remaining steps
- Mark wave as PARTIAL or FAIL

Time-box: per the wave's stated effort + 25% buffer.
```

---

## Output format per test wave

End every subagent invocation with:

```json
{
  "test_wave": "T{N}",
  "title": "...",
  "result": "PASS | PARTIAL | FAIL",
  "steps_executed": N,
  "steps_passed": N,
  "steps_failed": N,
  "step_results": [
    { "step": "1.1", "result": "PASS", "notes": "..." },
    ...
  ],
  "cross_app_parity_verified": true | false,
  "screenshots": [...],
  "db_check_queries_run": N,
  "db_check_results": "all match | mismatches: [...]",
  "regressions_detected": [...],
  "ui_discipline_violations": [...]   // 0 expected on PASS
}
```

---

## Aggregate report

After all 11 test waves complete, generate `Tests/e2e/CONTRACTOR_BUILDOUT_TEST_REPORT.md` with:

1. **Top-line summary**: X/11 waves PASS, Y FAIL, Z PARTIAL
2. **Per-wave result block** (the JSON output)
3. **Cross-app parity matrix**: 16 cells (8 mobile waves × 2 verification points + 20 web waves × ...) → red/green pixels
4. **Regression list**: any fail traced back to a known wave
5. **Demo readiness**: explicit GO / NO-GO with reasons

Tom reads this report at 7am over coffee. Demo is GO if every PASS box is green AND there are zero regressions in the demo path (T11).

---

## Closing — what this test plan covers

After running all 11 test waves, every shipped feature from the mobile + web + B-wave plans is verified:

- ✅ All 13 mobile waves (M1-M13) verified on Chez Field PWA
- ✅ All 20 web waves (W1-W20) verified on Operations Desk
- ✅ All 7 cross-app B-waves (B1-B7) verified across surfaces
- ✅ Every contractor write traced to homeowner iOS read
- ✅ Every UI discipline rule (Section 22) confirmed per surface
- ✅ Every DB schema migration verified via service-role JWT
- ✅ Demo path (T11) end-to-end clean
- ✅ Salmon discipline + em-dash discipline + brand voice intact

The contractor system goes from "untested mosaic" to "demo-grade verified."
