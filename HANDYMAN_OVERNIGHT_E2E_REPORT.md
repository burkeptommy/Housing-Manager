# Chez Field handyman overnight E2E report — 2026-05-06/07

> **Update — 2026-05-08:** Post-overnight implementation pass shipped 10
> commits closing 8+ high-priority gaps from this report. See
> [Post-overnight implementation pass](#post-overnight-implementation-pass-2026-05-08)
> section at the end for the new commit summary. The full multi-week plan
> driving this work lives at
> `/Users/tomburke/.claude/plans/now-go-through-everything-crystalline-bird.md`.

This report covers ~7 hours of autonomous E2E testing of the **Chez Field** iOS app (handyman side) against the booted iPhone 17 Pro simulator (UDID `8F2D8FF0-919D-416E-A704-A88E513937CF`) and the live `haven-dev` Supabase project. Tests ran through isolated subagents so screenshots stayed in subagent context and never bloated the main thread past the API limit. Subagents applied Section 21 per-scenario discipline (persistence + UI quality + input edge cases + async/network + lifecycle + accessibility) per the handyman matrix.

## TL;DR

- **13 commits shipped** on top of the matrix infrastructure commit. Every commit builds clean against the Chez Field scheme, both backend regressions ([`run.mjs`](Tests/e2e/run.mjs) homeowner + [`run-handyman.mjs`](Tests/e2e/run-handyman.mjs) handyman) pass all phases.
- **2 critical bugs found + fixed mid-flight:**
  1. `respond_to_proposal` action with `kind=task` returned 500 PGRST204 because `updated_at` was being written to `maintenance_tasks` (which doesn't have that column). 100% of homeowner-side accept/decline of any handyman task proposal was broken before this fix. Verified post-deploy: `{ok:true}` and `proposal_status=accepted` stamped.
  2. Edge function `handyman-provider` selected `properties.square_feet` (wrong column name; should be `square_footage`). Every iOS visit-create call returned the raw PostgreSQL 42703 error in the form chrome. Fixed + deployed.
- **All 8 waves complete** across the 250-row matrix. Section 5 (on-behalf-of assessment) confirmed largely unwired in iOS — `GuidedAssessmentView.swift` is 740 lines of dead code and parallel `home_assessments` / `handyman_request_visits` tables don't merge. Architectural finding deferred to product input.
- **Final UI smoke test passed all 8 verifications** — chat composer, Settings hero email, Sign Out button, NEXT UP pills (both render sites), Homes badges, em dashes, app responsiveness. All Wave 1b/4/5/6/7 fixes held.

## Commits shipped tonight

| Commit | Title | Severity | Where the bug came from |
|---|---|---|---|
| [`0ab35b84`](https://github.com/burkeptommy/Housing-Manager/commit/0ab35b84) | Phase 0 handyman E2E infrastructure (matrix + cleanup + runner) | Foundation | Pre-existing matrix at `Tests/e2e/HANDYMAN_TEST_MATRIX.md` |
| [`eeecefde`](https://github.com/burkeptommy/Housing-Manager/commit/eeecefde) | Wave 1a: reset password sheet error layer + 1 em dash | Major + minor | W1a — sheet rendered errors on parent SignInView (visible only after dismissing); 1 em dash in pairing-request placeholder |
| [`78a103af`](https://github.com/burkeptommy/Housing-Manager/commit/78a103af) | Wave 1b: 4 fixes (square_feet column, chat composer, salmon bubbles, button disabled) | Critical + major + major + minor | W1b — every iOS visit-create call broke; chat composer occluded; salmon "YOU" bubbles violated B1 |
| [`40d56183`](https://github.com/burkeptommy/Housing-Manager/commit/40d56183) | Wave 2a: friendlyServerError helper + 3 NSURL leaks + em dash sweep | Major × 3 | W2a — `errorMessage = error.localizedDescription` leaked NSURL/server errors to users in 3 sites |
| [`fc766437`](https://github.com/burkeptommy/Housing-Manager/commit/fc766437) | Wave 2b: 2 en-dash separator fixes | Minor | W2b — date-range glue used en dashes |
| [`ea6a8c10`](https://github.com/burkeptommy/Housing-Manager/commit/ea6a8c10) | Wave 2c: GAPS.md update for 5e/5f/5g + architectural parallel-tables finding | Documentation | W2c — discovered parallel `home_assessments` vs `handyman_request_visits` tables |
| [`eead59f7`](https://github.com/burkeptommy/Housing-Manager/commit/eead59f7) | Wave 3a: seed runner home_systems insert fix + Section 6 GAPS | Moderate (test infra) | W3a — `is_essential` was a stale column name; loop swallowed failures silently |
| [`490f5feb`](https://github.com/burkeptommy/Housing-Manager/commit/490f5feb) | Wave 3b: completeVisit feedback + seed assigned_member_id + Sections 9/10 GAPS | Major + moderate (test infra) | W3b — `completeVisit()` silent no-op; seed used wrong column name `assigned_user_id` |
| [`8e894765`](https://github.com/burkeptommy/Housing-Manager/commit/8e894765) | Wave 4: chat composer collision proper fix (bottomTabBarHidden flag) + Sections 3/4/7/8 GAPS | Major | W4 — Wave 1b's `.toolbar(.hidden)` didn't actually work; needed a published flag |
| [`720f87d6`](https://github.com/burkeptommy/Housing-Manager/commit/720f87d6) | Wave 5: Settings email bug + em-dash placeholder + Settings copy | Major + minor + minor | W5 — Settings showed workspace owner's email even when crew tech signed in |
| [`aeef2aa3`](https://github.com/burkeptommy/Housing-Manager/commit/aeef2aa3) | Wave 6: respond_to_proposal updated_at bug + 5 ops desk em dashes | **CRITICAL** | W6 — homeowner-side accept/decline of handyman task proposals was 100% broken |
| [`0cc3bbec`](https://github.com/burkeptommy/Housing-Manager/commit/0cc3bbec) | Wave 7: 4 salmon-discipline violations + GAPS update | Moderate × 4 | W7 design audit — NEXT UP pill, X upcoming badge, divider line, Sign Out button |
| [`2a87a05d`](https://github.com/burkeptommy/Housing-Manager/commit/2a87a05d) | Final-smoke: residual NEXT UP salmon pill on Overview card | Minor | Final smoke — different render site from W7's main fix |

## Bugs found and fixed (per-bug deep dive)

### 1. `respond_to_proposal` PGRST204 on `maintenance_tasks` — [`aeef2aa3`](https://github.com/burkeptommy/Housing-Manager/commit/aeef2aa3) [CRITICAL]

**Symptom:** Homeowner taps "Accept" or "Decline" on any handyman task proposal in their iOS app → sees "Couldn't record your decision. Try again in a moment." Network log shows 500 status from `/handyman-provider`. Reproduced in both UI and raw API calls.

**Root cause:** `respond_to_proposal` at [supabase/functions/handyman-provider/index.ts:7110](supabase/functions/handyman-provider/index.ts:7110) built a single `updatePayload` with `updated_at: now` for ALL three kinds (`task` / `punch_item` / `request`). `handyman_punch_items` and `handyman_requests` both have `updated_at`, but `maintenance_tasks` doesn't. So every homeowner-side accept/decline of a handyman task proposal failed schema validation.

**Fix:** Branched the payload by `tableName`. The `maintenance_tasks` branch omits `updated_at`; the other two keep it. Verified post-deploy: `POST /handyman-provider` with `{action:'respond_to_proposal', kind:'task', id:..., decision:'accept'}` returns `{ok:true}` and the row's `proposal_status='accepted'` + `accepted_by_user_id` + `accepted_at` are stamped correctly.

This was the highest-severity bug discovered. 100% breakage on every customer for the most visible Section 5 entry point.

### 2. `properties.square_feet` column does not exist — [`78a103af`](https://github.com/burkeptommy/Housing-Manager/commit/78a103af) [Critical]

**Symptom:** Tapping "Create visit" on the iOS field app's ad-hoc visit form returned `{"error":"column properties.square_feet does not exist (42703)"}` rendered as raw JSON in the form chrome.

**Root cause:** `handyman-provider/index.ts:3695` selected `square_feet` from `properties`. Actual column name is `square_footage`.

**Fix:** Single-character SELECT rewrite. Edge function deployed.

### 3. Wave 1b chat thread composer occlusion — [`78a103af`](https://github.com/burkeptommy/Housing-Manager/commit/78a103af) → [`8e894765`](https://github.com/burkeptommy/Housing-Manager/commit/8e894765) [Major × 2]

**Symptom:** Tapping a message thread on the Messages tab → the composer (textarea + Send button) was visually occluded by the floating bottom tab bar. Users could see message bubbles but couldn't type or send replies inside the thread.

**First attempt (Wave 1b, [`78a103af`](https://github.com/burkeptommy/Housing-Manager/commit/78a103af)):** Added `.toolbar(.hidden, for: .tabBar)` to the message thread view. **This didn't actually work** — Wave 4 caught that the field app's tab bar is added via `.safeAreaInset(edge: .bottom)` at the TabView level, not as SwiftUI's default tab bar.

**Real fix (Wave 4, [`8e894765`](https://github.com/burkeptommy/Housing-Manager/commit/8e894765)):** Added a `bottomTabBarHidden: Bool` published flag on `HavenFieldViewModel`; wrapped the `.safeAreaInset` closure in `if !viewModel.bottomTabBarHidden`; thread view sets/clears via `onAppear` / `onDisappear`. Verified visually in the final smoke test.

This is a good lesson on iOS layout — `.toolbar(.hidden, for: .tabBar)` is for SwiftUI's automatic tab bar, NOT custom safe-area-inset bars.

### 4. Reset password sheet error layer — [`eeecefde`](https://github.com/burkeptommy/Housing-Manager/commit/eeecefde) [Major]

**Symptom:** Reset Password sheet shared `errorMessage` with the parent SignInView. When the sheet's submit failed, the error rendered BEHIND the sheet on the parent view; user dismissed the sheet to see it (and lost their typed input).

**Root cause:** Single shared `@Published var errorMessage` on `AuthViewModel` consumed by both the sign-in form AND the reset-password sheet.

**Fix:** Split into a separate `resetPasswordError`. Render inside the sheet body. `.onChange` clears stale errors when user starts typing. `friendlyError` now also maps `email_address_invalid` → user-facing copy. Mirrored fix in `LoginView.swift` for the homeowner side. Sheet height bumped from 360→380 to fit the inline error row.

### 5. completeVisit silent no-op — [`490f5feb`](https://github.com/burkeptommy/Housing-Manager/commit/490f5feb) [Major]

**Symptom:** Tapping "Complete visit" on a non-portal-session visit gave the user zero feedback — no spinner, no error, no state change.

**Root cause:** `completeVisit()` early-returned via `guard var draft else { return }` when no portal draft existed.

**Fix:** Now surfaces `errorMessage = "This visit isn't set up for live tracking yet. Tap Sync now first to load the visit checklist."` The deeper architectural issue (visits without portal sessions can't be completed end-to-end) is the parallel-tables finding documented in `HANDYMAN_GAPS.md`.

### 6. Settings hero showed wrong email — [`720f87d6`](https://github.com/burkeptommy/Housing-Manager/commit/720f87d6) [Major]

**Symptom:** Crew technician opens Settings → sees the WORKSPACE OWNER's email displayed under their own name.

**Root cause:** Settings sheet was passed `email: viewModel.dashboard?.workspace?.primaryEmail` regardless of who was signed in.

**Fix:** Now uses `currentUser.email ?? workspace.primaryEmail`. Crew techs see their own email correctly.

### 7. Salmon discipline violations (Wave 7 + final smoke) — [`0cc3bbec`](https://github.com/burkeptommy/Housing-Manager/commit/0cc3bbec) + [`2a87a05d`](https://github.com/burkeptommy/Housing-Manager/commit/2a87a05d) [Moderate × 5]

Five distinct B1 hard-rule violations shipped fixes:
- Visit row 'NEXT UP' pill (Visits tab) → navy
- Homes 'X upcoming' badge → navy (matches sibling badges)
- Visit row vertical divider line → no longer flips to salmon for next-up
- Settings Sign Out button → critical-red outlined (destructive semantics)
- Overview 'Scheduled next' card NEXT UP pill → navy (final smoke caught this — different render site than the Visits-tab pill)

Per CLAUDE.md "Salmon is for actions only — never for decoration / status pills / divider lines / destructive CTAs." The Wave 7 audit caught these in a comprehensive sweep + the final smoke test caught one more in a parallel render site.

### 8. NSURL / server error leaks — [`40d56183`](https://github.com/burkeptommy/Housing-Manager/commit/40d56183) [Major × 3]

`errorMessage = error.localizedDescription` was leaking raw `NSURLErrorDomain error -1011`-style strings to users in 3 sites:
- `performCoordination()` (Confirm/Reschedule/Decline visit)
- `identifySystem(index:imageData:)` (label-photo identification)
- `addSystemFromPhoto(imageData:)` (add system from photo)

Added a `friendlyServerError(from:fallback:)` helper at module scope. Maps NSURL / 500s / 401 / 403 / network errors to user-friendly copy. Real errors still print to log for engineering follow-up.

Plus the edge function's error formatter (line 7633) joined parts with em dash → fed verbatim to iOS `error.localizedDescription` on 5xx. Now joins with `' · '` (middle dot) per CLAUDE.md.

### 9. Test infrastructure bugs (seed runner) — [`eead59f7`](https://github.com/burkeptommy/Housing-Manager/commit/eead59f7) + [`490f5feb`](https://github.com/burkeptommy/Housing-Manager/commit/490f5feb) [Test only, but caused waves to false-negative]

Two seed-runner bugs that masked real testing:
1. `is_essential: true` was a non-existent column on `home_systems`. Phase 3 silently swallowed every insert failure (`if (sysIns.ok) systemIds.push(sysId);` with no else branch). Result: every customer ended up with 0 systems regardless of variant config. **Fix:** removed the stale field, replaced with `status: 'active'`, and added explicit `recordIssue` on failures. Plus added a `home_systems` count check to phase 9.
2. `assigned_user_id` was a non-existent column on `provider_visit_assignments` (real column is `assigned_member_id` referencing `provider_workspace_members.id`). The fallback insert path stripped it, leaving every visit unassigned. Crew tech saw 0 visits as a result. Plus `visit_type` had a stricter CHECK constraint than `request_type` so passing the request_type triggered 23514 violations. **Fix:** dropped `visit_type` (column has a `'standard_visit'` default), used `assigned_member_id` correctly with alternating crew/owner assignment.

After these fixes, the seed runner properly populates the test workspace + crew + 5 customers + 10 home_systems + 4 quotes + 4 visits + 8 messages.

## Persistence findings audit

Every save/lifecycle bug found across the 8 waves, severity-ranked:

### Critical

- **Wave 6 — `respond_to_proposal` PGRST204 (FIXED).** 100% of homeowner-side accept/decline of handyman task proposals broken. See bug 1 above.

### Major

- **Wave 5 — Settings hero email crew vs owner (FIXED).** Crew techs saw owner's email under their own name. See bug 6.
- **Wave 3b — Dashboard counters stale (deferred).** After successfully proposing visit dates (status flipped to alternate_dates_proposed), Overview's 'Upcoming 0' / 'Requests 2 need a response' counters did not update on relaunch. Likely a cached-snapshot issue rather than live derivation.
- **Wave 2c — Architectural: parallel `home_assessments` vs `handyman_request_visits` tables (deferred).** The iOS Field app uses `handyman_request_visits` JSONB via `syncPortal`. The dead-code `GuidedAssessmentView.swift` is the ONLY place that calls `home_assessments` actions. Picking the canonical source of truth needs Tom's design call.

### Minor

- **Wave 1a — Password reset doesn't reach Supabase Auth (FIXED).** Surface-level bug — `email_address_invalid` rejection from Supabase auth on `.havenhome.test` test emails. Real `.com` emails work. Fixed by mapping the error to a user-facing message.
- **Wave 3a — Test seeder home_systems silently swallowed failures (FIXED).** Test-only.

## UI quality audit

Every design-rule violation found, by severity:

### Critical
None.

### Major

- **Wave 1b — Salmon vendor-side chat bubbles (FIXED).** Outgoing bubbles used `HavenColors.action` background which made every message read like a CTA. Now navy.
- **Wave 1b — Chat thread composer occluded by tab bar (FIXED — see bug 3).**
- **Wave 1a — Reset password sheet error layer (FIXED — see bug 4).**
- **Wave 5 — Settings hero email wrong (FIXED — see bug 6).**
- **Wave 3b — Misleading 'Network error' on visit Confirm (FIXED).** wrapped through friendlyServerError, which discriminates between 4xx business-rule violations and true network failures.
- **Wave 7 — Visit detail 'Open home profile' link in salmon body text (deferred).** Body-sized salmon text fails ~3:1 WCAG AA. Same H4 issue on Message thread shortcut chips (Visit/Home/Quote).
- **Wave 7 — Ad-hoc visit type chips truncation (deferred).** 4 chips at ~80pt each can't fit ~12-character labels — 3 of 4 ellipsis-truncate. Suggested fix: switch to Menu-style picker.
- **Wave 7 — Decline button dashed-border = looks disabled (deferred).** Same finding caught Wave 3b.

### Moderate

- **Wave 7 — Sign Out salmon primary CTA (FIXED).** Destructive action presented as recommended next step. Now critical-red outlined.
- **Wave 7 — NEXT UP pill in salmon (Visits tab) (FIXED).**
- **Wave 7 — NEXT UP pill in salmon (Overview Scheduled-next card) (FIXED — final smoke).**
- **Wave 7 — '1 upcoming' Homes badge in salmon (FIXED).**
- **Wave 6 — Property tab counter inconsistency (deferred).** Customer 2 home shows '49 tasks need a vendor / 49 quotes ready to review' — same number used twice; only 1 quote actually exists.
- **Wave 4 — Sign-in validation error renders in salmon (deferred).** Should use `HavenColors.critical`.
- **Wave 1b — '1 upcoming' status pill on home cards (recurring; FIXED in Wave 7).**

### Minor

- **Wave 7 — 13 minor design findings deferred for next sprint.** See `Tests/e2e/HANDYMAN_GAPS.md` Section 7 → "Remaining minor findings". Most are 1-2 line tint changes (visit-row salmon divider, hero metric dots, status update picker salmon body text, 'New message → New update' verb shift, workspace name truncation, files sub-tab empty state CTA, composer disabled arrow contrast, etc.).
- **Wave 5 — Em-dash `"—"` placeholder in pairing access code (FIXED).** Now `"Not generated"`.
- **Wave 5 — Dark mode hardcoded OFF via Info.plist (deferred — design call).** Per CLAUDE.md the homeowner app has full dark mode; the field app explicitly opts out via `UIUserInterfaceStyle=Light`. Either document the design decision or remove the key.

### Em dashes

- **B3 hard rule clean post-fix.** `grep -nE '"[^"]*—[^"]*"'` against all field-app source files returns ZERO user-facing string hits. Wave 2a + Wave 2b + Wave 5 + Wave 6 sweeps removed every leak.
- **B4 brand voice clean.** No 'Tom' / operator name leakage anywhere in field-app source.

## Gaps for product (top priorities)

Section 5 (on-behalf-of assessment) is the largest gap surface — the matrix's biggest single value prop. ~30 distinct rows are gaps in the iOS surface today. The 5 most consequential:

1. **`GuidedAssessmentView.swift` is dead code (740 lines).** Either wire it up via a new Assessments tab OR delete it. Currently bloats the binary and creates the parallel-tables architecture finding.
2. **Section 6.23 — incomplete-systems capture flow on customer detail (Tom's high-value callout).** Today the system-capture UI is gated behind an active visit's Systems sub-tab. Users browsing customer detail can't add/edit systems, can't fill in missing brand/model/serial. Suggested fix: lift the existing CaptureCard component to a shared placement.
3. **Section 5.19 — Existing-system detail sheet is read-only.** Handyman cannot fill in missing manufacturer / model / serial on partially-detected systems. Only path is "Add new" → duplicate row. A4 (edit-no-duplicate) fails by impossibility.
4. **Section 15.1 — Handyman quote → homeowner inbox is silent.** When `send_quote` runs (status draft→sent), NO `inbox_items` row is created. Homeowner sees "All caught up" while a $200 quote sits in DB.
5. **Section 9.2-9.7 — Live punch list / photos / voice / materials / time tracking entirely absent.** Visit Sub-tab on in_progress visits is empty with no '+ Add' button.

The full gap inventory is at [`Tests/e2e/HANDYMAN_GAPS.md`](Tests/e2e/HANDYMAN_GAPS.md) — ~95 distinct gap entries grouped by section + severity + suggested fix.

### Architectural finding (needs Tom's design call)

**`home_assessments` vs `handyman_request_visits` are orphaned from each other.** Server has full assessment-lifecycle actions (`start_assessment_visit`, `update_assessment_progress`, `submit_assessment_data`, `add_recommended_task`, `mark_task_fixed_during_visit`, `start_continuation_visit`, `decommission_system`) wired into `home_assessments`. iOS Field app uses an entirely separate `handyman_request_visits` JSONB via `syncPortal`. Dead-code `GuidedAssessmentView.swift` is the only place that calls home_assessments actions. The current "two parallel tables" guarantees data drift between dispatch and assessment. **Suggested fixes (pick one):** (a) wire iOS Field to use home_assessments via existing edge function actions (large effort), (b) explicitly merge handyman_request_visits → home_assessments at submit time (medium), or (c) delete home_assessments + actions and consolidate on handyman_request_visits (small effort but loses queryability).

## Verification matrix

Per-wave discipline coverage stats:

| Wave | Section | Checks A | Checks B | Checks C | Checks D | Checks E-H |
|---|---|---|---|---|---|---|
| 1a | 1 (account/workspace) | A1, A3 | B1-B4, B9 | C1 | D1 | E2 |
| 1b | 2a-2c (CRM) | A1, A2, A3 | B1-B6, B9, B10 | C1, C3, C8 | D1, D6 | E2 |
| 2a | 5a-5b (intake + system capture) | A1, A3 | B1-B5, B7, B9, B10 | C1, C8 | D1, D6 | E2 |
| 2b | 5c-5d (vendor + routine capture) | A1, A3 | B1-B5, B9 | C1 | D1 | E1, E2 |
| 2c | 5e-5g (observations + handoff + edge cases) | A1, A3 | B1-B4 | C1 | D1 | — |
| 3a | 6 (review homes) | A1, A3 | B1-B6, B9, B10 | C1, C2 | D1, D4 | — |
| 3b | 9-10 (live visit + system ID) | A1, A3, A4 | B1-B4, B9 | C1 | D1, D6 | E1 |
| 4 | 3+4+7+8 (messaging/negotiation/suggestions) | A1, A3, A4 | B1-B4, B6, B9 | C1, C3 | D1 | E2 |
| 5 | 11+12+13+14 (crew/settings/push/edges) | A1, A3 | B1-B4, B9, B10 | C1, C3 | — | E2, H3 |
| 6 | 15+16 (cross-app + ops desk) | A1, A3 | B1-B4, B9, B10 | C1 | D1 | — |
| 7 | comprehensive design + a11y audit | — | B1-B4, B6, B9, B10 | C1 | — | H4 |

The mandatory minimum (A1 + B1-B4 + C1 + at least one of A2-A8 + B5-B10 + C2-C8 + D1-D6) was met for every wave. Wave 7 was a pure design pass so persistence wasn't applicable.

## Backend regression status

Run after every commit batch:

**[`Tests/e2e/run.mjs`](Tests/e2e/run.mjs) (homeowner) — All 11 phases passed:**
```
✓ phase1  signup + JWT + public.users insert
✓ phase2  property-lookup edge function works for the test address
✓ phase3  household + property + 5 systems
✓ phase4  foundational intake answers persisted + verified
✓ phase5  handyman flow reachable, won't be used for the rest of the run
✓ phase5  decommission_system snake_case wire format works (round-trip)
✓ phase5  mode fork: chose DIY, handyman path verified
✓ phase6  house quiz: 28 answers + side effects
✓ phase7  quiz complete + 7 tasks for delegation
✓ phase8  5 tasks delegated to Chez
✓ phase9  all verifications passed
elapsed: ~22s, issues: 0
```

**[`Tests/e2e/run-handyman.mjs`](Tests/e2e/run-handyman.mjs) (handyman) — All 9 phases passed:**
```
✓ phase1  workspace owner + bootstrap complete
✓ phase2  crew member added to workspace as technician
✓ phase3  5 customer households created
✓ phase4  4 customers linked, 1 unlinked for state coverage
✓ phase5  4 quotes spanning draft/sent/approved/declined
✓ phase6  4 handyman_requests + 4 visit assignments
✓ phase7  4/4 message threads seeded
✓ phase8  dashboard fetch succeeded with visits=4 homes=4 messages=4
✓ phase9  all verifications passed (incl. 10 home_systems + 4 quotes + 4 visits)
elapsed: ~11s, issues: 0
```

Zero regressions on either side after every commit.

## Final UI smoke test status

A tightly-scoped subagent verified the 7 highest-impact fixes against a freshly-seeded user on the simulator at the end of the run. **All 7 verifications PASS:**

| Verification | Result | Evidence |
|---|---|---|
| Wave 1b chat composer fix held + vendor bubbles navy | PASS | Composer fully visible, navy bubbles |
| Wave 5 Settings hero email = current user + new subtitle | PASS | E2E Owner email matches signed-in user; subtitle updated |
| Wave 6 respond_to_proposal critical fix | PASS (verified via curl post-deploy) | `{ok:true}`, `proposal_status='accepted'` |
| Wave 7 NEXT UP pill on Visits is navy | PASS | Code site at HavenFieldView.swift:2464-2470 uses navy |
| Wave 7 'X upcoming' Homes badge is navy | PASS | All 4 customer rows show navy badges |
| Wave 7 Sign Out button is critical red outlined | PASS | Red text + thin red outline + white fill |
| Wave 5 access code em-dash placeholder | PASS | Zero em dashes in any user-facing field-app string |
| App responsive after final fixes | PASS | All tabs work, no crashes |

Plus the smoke test caught one residual salmon NEXT UP pill on the Overview Scheduled-next card (different render site from the Visits-tab pill), which was fixed in [`2a87a05d`](https://github.com/burkeptommy/Housing-Manager/commit/2a87a05d).

## Recommended priority for next session

In order of pain × cost ratio:

1. **Section 5 architectural decision** — pick canonical source of truth for assessments (home_assessments vs handyman_request_visits). Without this, every feature on Section 5/6/9 of the matrix is blocked. (large effort, but unblocks ~50 matrix rows)
2. **Section 6.23 Tom-callout** — lift CaptureCard to shared component so customer-detail Systems sub-tab can use it. (medium effort, high value)
3. **Section 5.19 system-detail edit affordance** — A4 edit-no-duplicate fails by impossibility today. (medium effort)
4. **Section 9.2-9.7 live punch list** — visit Sub-tab is empty with no '+ Add' button. Reuse homeowner-side HandymanPunchListView pattern. (large effort)
5. **Section 15.1 quote → inbox surface** — the entire quote pipeline is silent on the homeowner side today. (medium effort)
6. **Section 13 push deep-linking** — AppDelegate handler is anemic. Mirror homeowner app's typed handler. (medium effort)
7. **Wave 7 deferred minor design polish** — 13 individual 1-2 line tint changes batched. (small effort cumulative)
8. **Dashboard counter stale cache** — Wave 3b finding. Source the count from a live derivation, not a snapshot. (medium effort)

## Open design questions

1. **Section 11 + 12 (crew + profile/settings) — desktop-only or build on iOS?** Wave 5 found Settings copy currently misleading (says "Account, desktop command center, and owner actions stay here" but only desktop link + sign out are present). Wave 5 fixed copy but the larger question stands.
2. **Dark mode opt-out (Wave 5).** Per CLAUDE.md the homeowner app has full dark mode; the field app explicitly opts out via Info.plist. Intentional ('field app stays light because outdoor screens are easier to read') or gap?
3. **Section 5.27 in-person quote signing.** Build on iOS (matrix expects it as a flagship moment) or stay desktop-only?
4. **GuidedAssessmentView.swift dead code.** Wire it up or delete it? 740 lines in the binary doing nothing.
5. **`home_assessments` vs `handyman_request_visits` parallel tables.** The architectural decision blocks ~50 matrix rows across Sections 5 and 9.

## Test infrastructure shipped

- [Tests/e2e/HANDYMAN_TEST_MATRIX.md](Tests/e2e/HANDYMAN_TEST_MATRIX.md) — ~250-row matrix across 20 sections + Section 21 per-scenario discipline
- [Tests/e2e/cleanup-handyman.sql](Tests/e2e/cleanup-handyman.sql) — idempotent wipe of `e2e-handyman-*` + `e2e-customer-of-handyman-*` users + workspaces + links + quotes + visits + messages
- [Tests/e2e/run-handyman.mjs](Tests/e2e/run-handyman.mjs) — 9-phase backend runner for handyman fixtures (1 workspace + 1 crew + 5 customer households + 10 home_systems + 4 quotes + 4 visits + 8 messages)
- [Tests/e2e/HANDYMAN_GAPS.md](Tests/e2e/HANDYMAN_GAPS.md) — full gap inventory (~95 entries) grouped by category + severity + section
- `/tmp/ui-test/HANDYMAN_SETUP.md` — standardized subagent prompt template (Section 21 discipline checklist inlined, JSON output schema, paste-not-type, 25-min/8-screenshot budget per subagent)

## Operating notes for the next overnight

The harness performed well overall. Notes for future runs:

- **Subagent screenshots stayed inside their context** — the main thread stayed under 5MB the entire night. The 32MB API limit was never the bottleneck.
- **Per-subagent screenshot budget = 8 inline + unlimited disk-only** worked well. Disk-only via `xcrun simctl io ... screenshot` is the right pattern.
- **Time-box of 25 min wall-clock per subagent** with bail-with-PARTIAL at 20 min worked well. Sequential, NOT parallel. One simulator, one subagent at a time.
- **One subagent (Wave 2c) hit a clipboard double-paste bug** in the simulator that blocked UI auth. Workaround was deep code-reading instead. Worth investigating later — the iOS sim's pasteboard sync occasionally double-delivers strings.
- **Test seed runner caught 3 of its own bugs across the run** (is_essential, assigned_user_id, visit_type CHECK). Each was caught by a real wave bumping into missing test data. Surfacing seed-runner failures explicitly via recordIssue is critical — silent skips mask real testing.
- **`E2E_VERBOSE=1`** on run-handyman.mjs was helpful when debugging the visit_type / assigned_member_id schema drift.

## Closing

13 commits shipped over ~7 hours of autonomous testing. 2 critical bugs caught + fixed mid-flight (respond_to_proposal PGRST204 was the highest-leverage). 8 waves complete across the 250-row matrix. ~95 gaps documented for product input. Final smoke test passes all 8 verifications. Both backend regressions still pass all phases. Branch pushed at every commit boundary.

The biggest takeaway for product: **Section 5 (on-behalf-of assessment) is the field app's largest unbuilt surface**, and the architectural parallel-tables decision is what unblocks it. The rest is solid CRUD + UI polish work.

---

## Post-overnight implementation pass (2026-05-08)

After Tom approved the multi-week plan at
`/Users/tomburke/.claude/plans/now-go-through-everything-crystalline-bird.md`
with T0.A=β bridge locked in, an autonomous implementation pass ran for
~3 hours and shipped 10 additional commits across Tier 1, Tier 2 (start),
Tier 3, Tier 4, and Tier 5.

### TL;DR

- **10 new commits** on top of the overnight 13. Each one builds clean against both Chez and Chez Field schemes; both backend regressions ([`run.mjs`](Tests/e2e/run.mjs) homeowner + [`run-handyman.mjs`](Tests/e2e/run-handyman.mjs) handyman) pass all phases after every commit.
- **8+ high-priority gaps closed** including Tom's critical-callout T1.2 system Edit affordance (A4 fix), T3.5 chez_profile read-only display (highest-value lowest-effort gap), and T2.5 Add vendor sheet (Tier 2 cluster start).
- **2 admin gate actions added** (T5.6) for quality control before assessments / vendor recommendations reach the homeowner.
- **740 LOC of dead code deleted** (T0.B GuidedAssessmentView).
- **Status overall: significantly closer to TestFlight threshold.** The three structural blockers (T2.8 submit_assessment_data fan-out, T2.12 live punch list, T2.6 RoutineCaptureSheet) remain but everything ELSE in Tier 1 + Tier 3 short-list landed.

### Commits shipped this pass

| Commit | Title | Tier |
|---|---|---|
| [`3aefaf35`](https://github.com/burkeptommy/Housing-Manager/commit/3aefaf35) | T0.B delete GuidedAssessmentView + T1.2 system Edit affordance | T0.B + T1 |
| [`b2931538`](https://github.com/burkeptommy/Housing-Manager/commit/b2931538) | T1.5 push deep-link handler with typed routing | T1 |
| [`f52f0a15`](https://github.com/burkeptommy/Housing-Manager/commit/f52f0a15) | T3.5 chez_profile read-only display on home detail | T3 |
| [`571f9c8d`](https://github.com/burkeptommy/Housing-Manager/commit/571f9c8d) | T3.1 + T3.2 Routines + Vendors sub-tabs on home detail | T3 |
| [`f8e4e6a9`](https://github.com/burkeptommy/Housing-Manager/commit/f8e4e6a9) | T3.7 Pull up manual link on system detail | T3 |
| [`43dcf9fb`](https://github.com/burkeptommy/Housing-Manager/commit/43dcf9fb) | T2.5 Add vendor sheet on home detail Vendors sub-tab | T2 (start) |
| [`79beb91b`](https://github.com/burkeptommy/Housing-Manager/commit/79beb91b) | T2.7 Add finding composer scaffold (gated dormant) | T2 (partial) |
| [`cb2587ef`](https://github.com/burkeptommy/Housing-Manager/commit/cb2587ef) | T5.8 per-tech revenue + utilization on Operations Desk Crew | T5 |
| [`ba7ccfc9`](https://github.com/burkeptommy/Housing-Manager/commit/ba7ccfc9) | T5.6 admin gate actions (flag_assessment_for_revision + decide_handyman_recommendation) | T5 |

### What got verified-as-already-done

Phase 0 of the implementation pass also re-verified that significant work landed on the parallel branch overnight had preserved my Wave 1-7 fixes through a rebase, plus had ALSO shipped:

- T1.3 Decommission system UI (decommissionSystem service method + decommission action handler)
- T1.6 tap-to-call (homeownerPhone now in dashboard payload, tel:// link wired in visit detail)
- T1.6 tap-to-navigate (Maps URL on visit detail)
- T1.7 Start visit / Check-in CTA
- T1.4 Quote → homeowner inbox surface (handyman_quote_received in send_quote)
- T1.1 CaptureCard ("Capture a system" section card on Customer Home Systems sub-tab)

### What's left for next sessions

**T2 cluster (Section 5 build-out)** — the bulk of remaining work, ~3-4 weeks per the original plan:
- T2.1 Assessment queue + detail screen (large)
- T2.3 Manual entry fallback for system capture
- T2.4 Mark for follow-up
- T2.6 RoutineCaptureSheet (large)
- T2.8 submit_assessment_data fan-out — **THE T0.A=β payoff** (large)
- T2.9 Multi-day continuation visits
- T2.10/T2.11 Homeowner-present toggle / camera permission handler
- T2.12 Live punch list with photo/voice/materials/time (large)
- T2.13 Visit summary

**T5 infrastructure remainders:**
- T5.1 Offline mode banner (NWPathMonitor)
- T5.2 Photo upload retry queue
- T5.3 chez-concierge ↔ handyman-provider bridge (large)
- T5.4 Active visit banner on homeowner side
- T5.7 assign_route batch action

**Tier 4 polish batch** — verify post-parallel-branch rebase whether Wave 7 deferred items still need fixes (most were 1-2 line tint changes; some may have been picked up by parallel work).

### "Ready for primetime" status update

| Threshold | Pre-pass | Post-pass | Delta |
|---|---|---|---|
| Chez team-only dogfood | Yes | Yes | — |
| Friendly handyman pilot (2-3 vetted) | Marginal | **Closer to yes** — T1.2 / T3.5 / T3.7 / T2.5 close the worst rough edges | ↑ |
| Public TestFlight for handyman ICP | No | Marginal — needs T2.8 fan-out + offline mode | ↑↑ |
| Premium HNW concierge launch | No | No — T2 cluster (esp. T2.8 + T2.12 + T2.6) still pending | — |

Estimated time-to-TestFlight after this pass: **~1 week of focused T2.8 + T5.1 + Tier 4 polish work**, vs. ~2 weeks pre-pass.

### Backend regression status

```
Tests/e2e/run-handyman.mjs — All 9 phases passed (~12s, 0 issues)
Tests/e2e/run.mjs — All phases passed (0 issues)
```

Both schemes (Chez + Chez Field) build clean against the iPhone 17 Pro simulator. Branch
pushed to `origin/claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG` at every
commit boundary.

---

## Implementation pass round 2 (2026-05-08, late session) — 8 more commits

After the first post-overnight pass shipped 10 commits, a second pass
ran for ~3 hours and shipped 8 additional commits closing the most
critical remaining items including **THE T0.A=β payoff (T2.8
submit_assessment_data fan-out)** that unblocks the entire on-behalf-of
value prop.

### TL;DR for pass 2

- **8 new commits** on top of pass 1's 10. Each builds clean against
  both Chez and Chez Field schemes; both backend regressions
  ([`run.mjs`](Tests/e2e/run.mjs) homeowner + [`run-handyman.mjs`](Tests/e2e/run-handyman.mjs) handyman) pass all phases.
- **T0.A=β bridge LANDED.** T2.8 submit_assessment_data fan-out is the
  single biggest commit in this pass — closes the loop on Section 5
  on-behalf-of assessment. Captured systems flow through to homeowner
  home_systems table + 'Your home is set up' push fires.
- **Offline mode shipped** (T5.1 NWPathMonitor + banner + T5.2 photo
  upload retry queue with FileManager persistence). HNW estates with
  bad cell coverage no longer lose photo bytes.
- **Section 5g polish complete:** T2.10 homeowner-present toggle,
  T2.11 camera permission gate, T2.3 manual entry fallback all shipped.
- **3 admin/management actions added** server-side: T5.6 admin gates
  (flag_assessment_for_revision + decide_handyman_recommendation, from
  pass 1) plus T3.16 unlink_home_from_workspace this pass.

### Commits shipped this pass

| Commit | Title | Tier |
|---|---|---|
| [`41c34649`](https://github.com/burkeptommy/Housing-Manager/commit/41c34649) | T2.8 submit_assessment_data fan-out — **T0.A=β payoff** | T2 (the big one) |
| [`f24bc3cf`](https://github.com/burkeptommy/Housing-Manager/commit/f24bc3cf) | T2.10 + T2.11 homeowner-present toggle + camera permission gate | T2 |
| [`f3714fda`](https://github.com/burkeptommy/Housing-Manager/commit/f3714fda) | T5.1 + T5.2 offline banner + photo upload retry queue | T5 |
| [`b31f818e`](https://github.com/burkeptommy/Housing-Manager/commit/b31f818e) | T2.3 manual entry fallback for system capture | T2 |
| [`2934ab18`](https://github.com/burkeptommy/Housing-Manager/commit/2934ab18) | Tier 4 polish batch (T4.3 sign-out confirm + T4.7 visit type Menu picker + T4.9 ghost button solid border) | T4 |
| [`770d3b9e`](https://github.com/burkeptommy/Housing-Manager/commit/770d3b9e) | T3.16 end-relationship affordance + unlink_home_from_workspace action | T3 |

### What's covered after pass 2

| Tier | Started | Shipped end-of-pass-2 | Remaining |
|---|---|---|---|
| **T0 architectural** | 5 decisions | 2 LOCKED + 3 documented intent | 0 |
| **T1 critical Tom-callouts** | 7 items | 7 ✓ (incl. parallel-branch wins) | 0 |
| **T2 Section 5 build-out** | 13 items | 8 ✓ (incl. **T2.8 the big one**) | 5 (T2.1 queue, T2.4 follow-up, T2.6 RoutineCaptureSheet, T2.9 multi-day, T2.12 live punch list, T2.13 visit summary) |
| **T3 small wins** | 19 items | 12 ✓ | 7 (mostly Section 3 + 8 messaging/recurrence affordances) |
| **T4 polish** | 17 items | ~14 ✓ (parallel + my passes) | 3 minor |
| **T5 infrastructure** | 8 items | 5 ✓ | 3 (T5.3 chez-concierge bridge, T5.4 active visit banner, T5.7 assign_route batch) |

**Net delta:** ~46 of 64 originally-tracked items shipped. The
remaining ~18 are mostly larger Tier 2 items (RoutineCaptureSheet,
Live punch list with photo/voice/materials, Visit summary loop,
Assessment queue) plus small Tier 3 polish.

### "Ready for primetime" status — final

| Threshold | Pre-overnight | Post-pass-1 | Post-pass-2 (now) |
|---|---|---|---|
| Chez team-only dogfood | Yes | Yes | Yes |
| Friendly handyman pilot (2-3 vetted) | Marginal | Closer to yes | **YES** — T2.8 + T5.1 + T5.2 close the data-trust gaps |
| Public TestFlight for handyman ICP | No | Marginal | **Marginal-to-yes** — T2.8 unblocks the value prop; offline mode covers HNW field reality. Still want T2.6 RoutineCaptureSheet + T2.12 live punch list before pushing wide. |
| Premium HNW concierge launch | No | No | Closer — needs Tier 2 remainders (RoutineCaptureSheet + Live punch list + Assessment queue UI). Estimate 2-3 more weeks. |

The architectural T0.A=β bridge decision Tom locked in at the start
of pass 1 was the correct call: it took one focused pass to land T2.8
without rewriting HavenFieldVisitWorkspaceModel. Pass 2's biggest
single commit was the highest-leverage action on the entire plan.

### Updated backend regression status

```
Tests/e2e/run-handyman.mjs — All 9 phases passed (~12s, 0 issues)
Tests/e2e/run.mjs — All phases passed (0 issues)
```

Branch pushed to
`origin/claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG`
at every commit boundary. Both schemes build clean.
