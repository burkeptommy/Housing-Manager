# Homeowner complete test matrix

Canonical test plan for the **homeowner Chez iOS app**. Supersedes
[Tests/e2e/TEST_MATRIX.md](TEST_MATRIX.md) (which was onboarding-only)
by extending coverage to every user-facing surface and edge case.

> **What this adds vs the original V1 matrix:**
>
> 1. Bug re-verifications from the morning fix pass (5 bugs that need rigorous re-test)
> 2. Onboarding edge cases deferred / aborted overnight (9 subagents that didn't complete)
> 3. Round B backend combinatorial coverage (per-question variants for `run.mjs` extension)
> 4. Post-onboarding daily-use surfaces (15 feature areas not in V1)
> 5. Cross-app integration with Chez admin + contractor web (4-way round trips)
> 6. Per-scenario test discipline (UI quality + persistence + edge cases — mirror of handyman Section 21)
> 7. Gap discovery + finding categorization (4 buckets — mirror of handyman Section 19)

This is the **desired-state spec**. Every row describes a behavior the
app *should* support. Subagents discover whether each behavior exists
end-to-end, partially exists, or is a gap. Use the standard 4-category
finding tagging.

---

## ⚠️ MUST address — pending work from prior runs

**These items are NOT optional.** They were planned in the original overnight homeowner E2E run but did not complete. Each must be **(a) tested end-to-end on the simulator AND (b) any bugs found must be fixed before this matrix can be considered "done."**

### 9 deferred / aborted subagents (Section 2)

The original overnight run (see [`OVERNIGHT_E2E_REPORT.md`](../../OVERNIGHT_E2E_REPORT.md)) planned 17 subagents but only 9 completed. The 8 that were intentionally deferred + the 1 that aborted mid-run are listed below. Each maps to a subsection in Section 2 with detailed scenario rows.

| Original ID | Subsection in this matrix | What it tests | Status when this matrix was written |
|---|---|---|---|
| **W2S7** | 2b — Q28 household sub-flows | Couple-with-kids + expecting + nanny + home manager invite (Build 87) | **ABORTED** at 32MB ceiling at ~700 tool calls — never returned a result |
| **W2S8** | 2a — Save-for-later + back-nav hydration | Save mid-quiz, kill app, resume; back-nav state preservation per question kind; unresolved-saved review screen | Deferred |
| **W2S9** | 2c — Mode fork | DIY vs Chez handyman vs waitlist; `requestHomeAssessment` Edge Function; HomeAssessmentPendingCard | Deferred |
| **W3S10** | 2d — Vendor Coverage sweep | Auto-present when ≥2 systems uncovered; "Find a pro" / "I have one" routing | Deferred |
| **W3S11** | 2e — PostQuizVendorDelegationSheet | Flip `.either` tasks to vendor based on captured contractors | Deferred |
| **W3S12** | 2f — Add vendor | Manual + website import + clipboard URL/phone detection banner | Deferred |
| **W3S13** | 2g — Edit vendor + ContractorDetailView | Full CRUD + canonical-category re-stamping + ChezOwnsToggle | Deferred |
| **W4S14** | 2h — Chez task delegation | ChezEntryButton from 17 entry points; chez_request creation; smart category routing | Deferred |
| **W4S15** | 2i — Routines lifecycle | Create weekly / biweekly+vendor / seasonal-months; ActiveMonthsPicker; archive; ChezOwnsToggle | Deferred |

**Action required for each:** drive the simulator through the scenarios in subsection 2a-2i, log findings (verification / gap / UI-quality / persistence), fix any critical or major bugs surfaced, ship a commit per logical fix group, re-verify after rebuild.

### 5 bug re-verifications (Section 1)

Five fixes shipped in the morning pass after the original overnight run. They got only a 4-check smoke test and need rigorous end-to-end re-verification on the simulator.

| Bug | Subsection | Last known status |
|---|---|---|
| Bug A — Auth signup race (commit `f50d9ac8`) | 1a | Monotonic-true contract shipped; smoke test passed once. Need 5+ fresh signups to confirm intermittent bounce is gone. |
| Bug B — Coverage metric divergence (commit `f50d9ac8`) | 1b | MaintenanceHubView relabeled; quick smoke test confirmed. Need full DB cross-check + label review. |
| Bug D — Pool/Spa chemistry composition | 1c | Code path verified by inspection only; W2S6 saw `pool_inground` not `pool_inground_chlorine`. Drive UI through chemistry pick + verify subtype is composite in DB. |
| Bug E — Chapter intro card render | 1d | Defensive read consistency shipped; underlying issue may remain. Drive Ch1→Ch2→Ch3 boundaries on a fresh quiz. |
| Bug F — PropertyRecapCard data persistence (commit `f50d9ac8`) | 1e | Persistence shipped; fields now stamp from ATTOM into property.attributes. Drive a fresh signup, confirm bedrooms/bathrooms/lot all show on recap card. |

**Action required for each:** drive the verification scenarios in subsection 1a-1e, confirm each fix held end-to-end, file any regressions as critical-severity findings for immediate re-fix.

### 36 Round B backend combinatorial scenarios (Section 3)

Per the V1 matrix's "Round B" plan — exhaustive per-question variant coverage at the backend level. Cheap to run because it's pure `Tests/e2e/run.mjs` extension (no UI overhead). Originally specified, never executed.

**Action required:** extend `Tests/e2e/run.mjs` with all 36 scenarios from Section 3, run as a single `node Tests/e2e/run.mjs` invocation, capture per-scenario pass/fail in the report.

---

### Round A of the execution priority (Section 25) is built around addressing these.

If only one round of testing happens, **Round A must be it.** Sections 1, 2, and 3 collectively address every line item that was started-but-not-finished from prior planning. Treat them as commitments, not options.

For each row:

| Mark | Owner | Why |
|------|-------|-----|
| **`UI`** | iOS Simulator (computer-use driving Chez scheme) | Behaviour depends on tap order, animations, multi-step forms, live state |
| **`E2E`** | Backend test (`Tests/e2e/run.mjs` extension) | Deterministic write-and-verify against the schema; cheap to combinatorially expand |
| **`Cross`** | Two-app or app-plus-web verification | Requires homeowner sim + handyman sim or contractor web concurrently |
| **`Fixture`** | Backend seed data step | Setup of test users, properties, documents, etc. |

---

## 0. Test fixtures — backend setup

The previous overnight pass proved that the seed-user pattern (build a fully-onboarded test user via `E2E_KEEP_USER=1 node Tests/e2e/run.mjs`, then have UI subagents sign in to it) cuts each subagent's wall-clock from ~25 min to ~10 min by skipping the full onboarding walkthrough. Fixtures here build a richer baseline than the V1 matrix needed.

| # | Fixture | Owner | Notes |
|---|---|---|---|
| 0.1 | Cleanup script extension | Fixture | `Tests/e2e/cleanup.sql` already wipes `e2e-%@havenhome.test` — verify the cascade still catches new tables (chez_requests, routines, handyman_punch_items, etc.) |
| 0.2 | Backend seed runner | Fixture | `Tests/e2e/run.mjs` already exists. Add `E2E_FIXTURE_LIBRARY=1` flag that creates the matrix below in a single call so subagents can reference any pre-built state. |
| 0.3 | Seed `e2e-fresh-${TS}` — clean signup, foundational answered, quiz at Q1 | Fixture | For onboarding edge case tests. |
| 0.4 | Seed `e2e-mid-quiz-${TS}` — paused at Q15 with answers + 2 saved-for-later | Fixture | For save-for-later + resume tests. |
| 0.5 | Seed `e2e-completed-${TS}` — fully onboarded, 14 systems, 3 contractors, 2 family, 5 chez_requests | Fixture | The default seed for post-onboarding tests. |
| 0.6 | Seed `e2e-handyman-path-${TS}` — chose mode fork "Send a Chez handyman", assessment in scheduled state | Fixture | For mode fork + handyman path verifications. |
| 0.7 | Seed `e2e-with-vehicles-${TS}` — fully onboarded + 2 vehicles (one with recall, one without) | Fixture | For vehicle management tests. |
| 0.8 | Seed `e2e-with-documents-${TS}` — fully onboarded + 10 documents across categories (insurance, will, mortgage, invoice, photos) | Fixture | For document pipeline + viewer tests. |
| 0.9 | Seed `e2e-with-projects-${TS}` — fully onboarded + 1 planned project (with quotes) + 1 historical project | Fixture | For project tests. |
| 0.10 | Seed `e2e-with-routines-${TS}` — fully onboarded + 5 routines (3 active, 1 paused, 1 archived; mix of weekly/biweekly/seasonal) | Fixture | For routines lifecycle tests. |
| 0.11 | Seed `e2e-multi-property-${TS}` — fully onboarded + 2 properties (primary + vacation home) | Fixture | For multi-property tests. |
| 0.12 | Seed `e2e-with-family-${TS}` — fully onboarded + spouse (linked user) + 2 kids + 1 home manager + 1 staff | Fixture | For family member + Build 87 home manager tests. |
| 0.13 | Seed `e2e-with-trusted-${TS}` — fully onboarded + 3 trusted contacts with shared documents | Fixture | For trusted contacts tests. |
| 0.14 | Seed `e2e-chez-active-${TS}` — fully onboarded + Chez owns 5 routines + 3 tasks + 2 contractors + active concierge thread with 4 message rounds | Fixture | For Chez full concierge flow tests. |
| 0.15 | Seed `e2e-with-pending-recalls-${TS}` — vehicles + 2 active NHTSA recalls + 1 acknowledged | Fixture | For recall flow tests. |
| 0.16 | Seed `e2e-handyman-paired-${TS}` — fully onboarded + linked to a test handyman workspace (W2 from contractor matrix) | Fixture | For cross-app integration tests. |
| 0.17 | Test address library | Fixture | At least 5 ATTOM-rich addresses spanning CT/NY/MA + 1 ATTOM-empty (for fallback testing) + 1 out-of-coverage state. |
| 0.18 | Test attachments library | Fixture | Sample PDF (insurance), JPG (invoice), DOCX (will), HEIC (photo), .csv (unsupported), .zip (unsupported). For document upload + analyze-document tests. |
| 0.19 | Push notification helper | Fixture | Script to fire arbitrary push to the seed user's device token for deep-link testing. |
| 0.20 | DB inspection helpers | Fixture | curl wrappers for every table the matrix queries — copy-paste-ready snippets for each Section's verifications. |

---

## 1. Bug re-verifications (the morning fix pass)

Five fixes shipped this morning got only a 4-check smoke test. Each needs rigorous re-verification.

### 1a. Bug A — Auth signup race (commit `f50d9ac8`)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 1.1 | 5 fresh signups in a row, all land on FoundationalQuestionsForm Q1 (no bounce) | UI | Each with unique email; reset privacy + uninstall between. The original symptom was 50% bounce rate; need 5+ green to call it fixed. |
| 1.2 | Signup → kill app → relaunch → still authenticated (session keychain persists) | UI | Verifies the session actually persists, not just the in-memory flag. |
| 1.3 | Signup → background app → return → still on Q1 | UI | App lifecycle persistence. |
| 1.4 | Signup with weak password (rejected) → fix password (accepted) → land on Q1 | UI | Validates the failure path doesn't poison the success path. |
| 1.5 | Signup with already-registered email → friendly error → tap "I already have an account" → sign-in works | UI | Idempotency / clear error messaging. |
| 1.6 | Signup over 3G / slow network — auth state still flips correctly | UI | Slow-network race. |
| 1.7 | Signup, then immediately background mid-`auth.update(user:)` call → return → still authenticated | UI | Reproduces the original race window. |
| 1.8 | DB cross-check: `auth.users` + `public.users` both have rows after signup | E2E | The server side that we verified worked overnight. |

### 1b. Bug B — Coverage metric divergence (commit `f50d9ac8`)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 1.9 | Sign in as seed user. Dashboard HomeCoverageHero says "X of Y systems are covered" with X/Y reasonable. | UI | |
| 1.10 | Tap the hero → MaintenanceHubView opens → header now says "X of Y tasks scheduled" (NOT "covered") | UI | Verifies the relabel landed; users no longer see contradiction. |
| 1.11 | Numbers should match each computation source — dashboard X/Y is category coverage; hub X/Y is task scheduling. Different units, no contradiction. | UI | |
| 1.12 | If hub still says "covered" instead of "scheduled" → regression | UI | Catch in case of cherry-pick miss. |

### 1c. Bug D — Pool/Spa chemistry composition

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 1.13 | Fresh quiz, reach Q12, pick `in_ground` + `chlorine` chemistry, save | UI | |
| 1.14 | DB query `home_systems.subtype` → should be `pool_inground_chlorine` (composite) | E2E | If still `pool_inground` → Bug D not fixed; chemistry payload is being lost between `progressivePool` view and the answer mapper. |
| 1.15 | Same with `in_ground` + `salt` → `pool_inground_salt` | E2E | |
| 1.16 | Same with `above_ground` + `chlorine` → `pool_above_ground_chlorine` | E2E | |
| 1.17 | Same with `both` + chemistry — pool gets composite subtype, hot tub stays `hot_tub` | E2E | |
| 1.18 | Maintenance task templates that gate on chemistry (e.g. "Test salt cell" on salt only) seed correctly | E2E | Confirm reconciler picks up the chemistry token. |

### 1d. Bug E — Chapter intro card render path (defensive read shipped)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 1.19 | Fresh quiz. Q1 (q1_roof_material) lands. Confirm Chapter 1 intro card rendered BEFORE Q1 (Headspace pattern). | UI | |
| 1.20 | Complete Chapter 1, advance to Chapter 2 first question. Chapter 2 intro card renders before the question. | UI | |
| 1.21 | Complete Chapter 2, advance to Chapter 3 first question. Chapter 3 intro card renders. | UI | |
| 1.22 | Same chapter intros do NOT re-render on subsequent questions within the chapter | UI | Idempotency. |
| 1.23 | Resume a mid-quiz from save-for-later → chapter intro for the chapter you resume into renders once, then suppresses | UI | |

### 1e. Bug F — PropertyRecapCard data persistence

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 1.24 | Fresh signup with 146 Putnam Park Rd (ATTOM-rich). Walk through PropertyHookView page 2; bedrooms/bathrooms/lot all visible. | UI | |
| 1.25 | Land on quiz Q1; tap back to PropertyRecapCard. All fields populated (bedrooms/bathrooms/lot/year built/sqft). NO "Not on file" anywhere except for genuinely-absent fields. | UI | |
| 1.26 | DB query `properties.attributes` → should contain `bedrooms`, `bathrooms`, `lot_size` keys. | E2E | |
| 1.27 | Test ATTOM-empty address — recap card should gracefully say "Not on file" only for fields the lookup didn't return, not for everything | UI | |
| 1.28 | Manual override on recap (tap edit, change bedrooms to 5) persists to DB and renders on next visit | UI | |

---

## 2. Onboarding edge cases — the 9 deferred / aborted subagents from the original overnight run

> **What "skipped" / "deferred" means here:** the original overnight homeowner E2E run (documented in [`OVERNIGHT_E2E_REPORT.md`](../../OVERNIGHT_E2E_REPORT.md)) planned 17 subagents across 5 waves but only completed 9. The other 8 were intentionally deferred because each required redoing the full ~25-min onboarding walkthrough — and the auth-bounce + 32MB context ceiling made that wave prohibitively expensive at the time. One additional subagent (W2S7 — Q28 household sub-flows) ran but **aborted mid-run when it hit the 32MB ceiling inside its own context** at 700 tool calls.
>
> Total = 8 deferred + 1 aborted = **9 subagents** corresponding to subsections 2a–2i below.

### 2a. Save-for-later + back-nav hydration + unresolved-saved review (W2S8)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.1 | Mid-quiz at Q15, tap "Save for later" toolbar pill | UI | |
| 2.2 | Confirmation dialog renders, tap Save | UI | |
| 2.3 | Quiz dismisses to dashboard. DB `house_quiz_state.savedForLater` contains question_id | E2E | |
| 2.4 | Reopen quiz → resumes at first unanswered (or save-prompt screen) | UI | |
| 2.5 | Save 3 different questions for later, finish all other questions, reach unresolved-saved review screen | UI | |
| 2.6 | Review screen lists all 3 saved with "Edit" affordance | UI | |
| 2.7 | Tap saved question → routes back to it, hydrated with prior partial state | UI | |
| 2.8 | "Skip these and finish the quiz" footer button works with confirmation dialog | UI | |
| 2.9 | Trailing toolbar pill (count badge) updates as saved questions get resolved | UI | |
| 2.10 | Force-quit app mid-quiz, relaunch, lands at first unanswered (resume) | UI | |
| 2.11 | Back-nav hydration on every kind: singleChoice / multiSelect / currency / yesNoLender / vehicleAdd / providerSearch / caretakers / generatorAdd / householdContractors / progressivePool / progressiveLawn / trashWithDays / dualInsurance | UI | One row per kind. |
| 2.12 | Q28 caretakers back-nav re-hydrates with kids/expecting/home_manager state preserved | UI | The most complex hydration path. |
| 2.13 | Multi-select chip state preserved on back-nav (e.g. q9_basement with [unfinished + sump_pump] selected) | UI | |
| 2.14 | Currency input (Q4 purchase price) preserves on back-nav | UI | |
| 2.15 | Provider picker selected provider preserved on back-nav (the Phase 19h CURRENTLY SELECTED card) | UI | |

### 2b. Q28 household sub-flows (W2S7 — ABORTED last night)

The retry. Split into smaller subagents to stay under 32MB.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.16 | Q28 just_me → no family_member rows created → DB verified | UI |  |
| 2.17 | Q28 couple (no kids) → spouse invite inline form fires; submit → spouse row + invitation sent | UI | |
| 2.18 | Q28 couple_with_kids + 1 child added (name + DOB) → family_member row with member_type='family' | UI | |
| 2.19 | Q28 couple_with_kids + 2 children (test the multi-add flow + delete-one) | UI | |
| 2.20 | Q28 expecting toggle ON + due date → expecting member row | UI | |
| 2.21 | Q28 nanny caretaker added → family_member row with member_type='caretaker' | UI | |
| 2.22 | Q28 home manager step (Build 87): "Add home manager" → inline invite form (first/last name, optional email, personal message) → submit → family_member row with member_type='home_manager' + invitation sent | UI | |
| 2.23 | Q28 home manager Skip path → Q28 finalizes without home_manager_entry | UI | |
| 2.24 | Q28 multi_gen household type → Q28 sub-step copy reflects multi-generation context | UI | |
| 2.25 | Q28 something_else → free-form path; Q28 lets user retype | E2E | |
| 2.26 | After Q28 completes, summary card shows full chain ("A couple, 1 kid, expecting, nanny Maria, home manager Sam") | UI | |
| 2.27 | Back-nav from Q29 to Q28 re-hydrates ALL sub-step state (the Build 85 hydration coverage) | UI | |

### 2c. Mode fork (W2S9)

`OnboardingModeForkView` — three routes off the foundational form.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.28 | Mode fork renders with both DIY + Chez handyman cards (in-coverage state) | UI | |
| 2.29 | Pick "I'll finish setting up myself" → land on House Quiz Q1 | UI | |
| 2.30 | Pick "Send a Chez handyman" → confirmation overlay with booking details | UI | |
| 2.31 | Handyman path: `requestHomeAssessment` Edge Function fires successfully → home_assessments row created | E2E | Phase 95 fix `9941f43a` snake_case wire format. |
| 2.32 | Handyman path confirmation overlay auto-dismisses after 4s OR on "Got it" tap | UI | |
| 2.33 | Handyman path → dashboard renders HomeAssessmentPendingCard with countdown | UI | |
| 2.34 | Out-of-coverage state (test with a state outside service area) → handyman card replaced with waitlist tile | UI | |
| 2.35 | Waitlist tile submit captures email + state for follow-up | UI | |
| 2.36 | Mode fork "back" affordance → returns to last foundational question (NOT a no-op) | UI | |
| 2.37 | Mode fork dismiss / cancel → routes back to dashboard with onboarding still incomplete (lifecycle preserved) | UI | |

### 2d. Vendor Coverage sweep (W3S10)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.38 | Quiz completion with 2+ uncovered vendor categories → VendorCoverageSheet auto-presents BEFORE cinematic reveal | UI | |
| 2.39 | Quiz completion with 0-1 uncovered → sweep does NOT fire; reveal direct | UI | |
| 2.40 | Sweep shows each gap as a card with category icon + "Find a pro" + "I have one" + dismiss | UI | |
| 2.41 | Tap "Find a pro" on gap → routes to FindLocalVendorSheet pre-filtered to that category | UI | |
| 2.42 | Tap "I have one" → routes to AddVendorSheet with prefilledCategory propagated through ImportedVendorData | UI | |
| 2.43 | Dismiss a gap → "Not applicable, dismiss" affordance writes to dismissed_categories | UI | DB verify. |
| 2.44 | Complete sweep (all dismissed or filled) → reveal proceeds | UI | |
| 2.45 | After sweep dismisses, PostQuizVendorDelegationSheet considers firing (if any either-tasks) | UI | |
| 2.46 | All-categories-covered empty state celebrates ("All N systems have a vendor") with "Manage all your vendors →" link | UI | |

### 2e. PostQuizVendorDelegationSheet (W3S11)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.47 | Quiz complete with 1+ contractors that have matching .either tasks → sheet auto-fires | UI | |
| 2.48 | No matching either tasks → sheet does NOT fire | UI | |
| 2.49 | Sheet lists every vendor with collapsible DisclosureGroups showing affected task titles + frequencies | UI | |
| 2.50 | Default-all-selected with master Continue CTA | UI | |
| 2.51 | Tap Continue → matching .either tasks flip to .vendor with assigned_contractor_id | E2E | |
| 2.52 | Tap "Skip for now" → stamps `skipped_delegation_at` on property attributes | E2E | |
| 2.53 | Re-fires from Dashboard's `.contractorAdded` notification when a new contractor is added later | UI | |
| 2.54 | Per-vendor toggle off (don't delegate to this one) → those tasks stay personal | UI | |
| 2.55 | Per-task toggle off within a vendor → just that one stays personal | UI | |

### 2f. Add vendor (W3S12)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.56 | Tap "+ Add vendor" from Contacts sub-tab → AddVendorSheet renders 3 import options | UI | |
| 2.57 | Manual entry path: form for company name + category + phone + email + website + notes | UI | |
| 2.58 | Manual entry submit → contractors row with source='manual' + canonical category from SystemCategoryRegistry | E2E | |
| 2.59 | Website import: paste URL → extract-vendor Edge Function fetches + AI parses → confirmation screen with extracted fields | UI | |
| 2.60 | Website import accepts → contractors row with source='find_vendor', logo_url snapshot, brand_color | E2E | |
| 2.61 | Website import edit before save (correct extracted fields) | UI | |
| 2.62 | Clipboard URL detection: open AddVendorSheet with URL on clipboard → ClipboardSuggestion banner with "Use it" CTA | UI | The Phase 56 detection logic. |
| 2.63 | Clipboard phone detection: phone number on clipboard → banner with "Use it" → routes to manual form with phone prefilled | UI | |
| 2.64 | Clipboard unknown text on clipboard → banner shows preview without action assumption | UI | |
| 2.65 | AddVendorSheet pre-filled category (from VendorCoverageSheet "I have one") routes specialty picker pre-selected | UI | |
| 2.66 | Save → vendor appears in Contacts list with logo, canonical category, single-line label | UI | |
| 2.67 | Vendor coverage updates immediately (gap card disappears from VendorCoverageSheet) | UI | |

### 2g. Edit vendor + ContractorDetailView (W3S13)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.68 | Tap a vendor row from Contacts → ContractorDetailView opens with full layout | UI | |
| 2.69 | Tap Edit → form pre-populated with all fields | UI | |
| 2.70 | Edit company name → save → list reflects new name; DB row updated NOT duplicated | UI |  |
| 2.71 | Edit category → save → canonical category re-stamped via SystemCategoryRegistry; vendor coverage matching updates | E2E | |
| 2.72 | Edit phone → save → "Call" button uses new number | UI | |
| 2.73 | Edit website → save → logo re-fetched via brand-logo Edge Function | UI | |
| 2.74 | Add specialty → multi-specialty vendor (e.g. "Plumbing + Heating") | UI | |
| 2.75 | Add notes — long text saves cleanly | UI | |
| 2.76 | Delete vendor → confirmation dialog → vendor removed from list, archived in DB | UI | |
| 2.77 | View linked maintenance tasks (subtab on detail view) | UI | |
| 2.78 | View service history per vendor | UI | |
| 2.79 | View linked utility_account if mirrored | UI | |
| 2.80 | ChezOwnsToggle on vendor → contractor.chez_owned=true → standing engagement chez_request created | E2E | |
| 2.81 | Long-press on vendor row → context menu (edit / delete / share / chez delegate) | UI | |

### 2h. Chez task delegation (W4S14)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.82 | Open MaintenanceTaskDetailSheet on a no-vendor task → "Have Chez handle this task" affordance visible | UI | |
| 2.83 | Tap → ChezEntryButton routes to ChezRequestComposeSheet pre-filled with task context | UI | |
| 2.84 | Submit → chez_requests row with category='find_vendor' and reference to the task | E2E | |
| 2.85 | concierge_messages thread created with first message + system event row | E2E | |
| 2.86 | inbox_items row created with type='chez_status_change' | E2E | |
| 2.87 | Push notification fires to admin user IDs + SendGrid email backstop | E2E | |
| 2.88 | Open MaintenanceTaskDetailSheet on a with-vendor task → "Have Chez handle this task" → category='coordinate_task' | UI | Smart routing per Phase 80.2. |
| 2.89 | Open FindLocalVendorSheet → "Or have Chez source one" inline link → ChezEntryButton fires | UI | |
| 2.90 | Open ContractorDetailView → "Make Chez point of contact" → flips contractor.chez_owned=true | UI | |
| 2.91 | Open RoutineEditSheet → ChezOwnsToggle → routine.chez_owned=true | UI | |
| 2.92 | After delegation, task shows ChezOwnsBadge on its row | UI | |
| 2.93 | Settings → Your Chez profile → "View what Chez owns" → ChezDelegationsListView aggregates routines + vendors + tasks with quick-revoke pills | UI | |
| 2.94 | Revoke delegation on a task → chez_owned=false; task returns to user surface | UI | |
| 2.95 | Chez admin reply → inbox_items row → homeowner sees in Inbox under Needs Action OR Unread depending on acknowledgement_required | E2E | |

### 2i. Routines lifecycle (W4S15)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.96 | Tap "Add routine" from PropertyDetailView Maintenance tab + button → RoutineEditSheet | UI | |
| 2.97 | Add weekly cadence (trash day): kind=trash, weekly + days_of_week=[Wed], evening_before_reminder ON | UI | |
| 2.98 | Save → routines row with cadence_type=weekly, days_of_week=[4] (ISO), reminder flags | E2E | |
| 2.99 | Add biweekly with vendor (cleaning): kind=cleaning, biweekly + reference week, contractor picker, cost in cents | UI | |
| 2.100 | Vendor picker opens ContractorPickerSheet filtered to relevant categories | UI | |
| 2.101 | Add seasonal months routine (snow removal): kind=snow_removal, annual cadence, ActiveMonthsPicker Dec-Apr | UI | |
| 2.102 | ActiveMonthsPicker chip row with month-letter labels, contiguous-range summary ("Active December through April") | UI | |
| 2.103 | Quick presets (Year-round / Spring-Fall / etc.) work | UI | |
| 2.104 | Save with vacation pause months excluded (e.g. lawn care active April-Nov) | UI | |
| 2.105 | Edit existing routine → form pre-populated; save → row updated | UI | |
| 2.106 | Archive routine (swipe-to-delete) → archived_at set → routine disappears from active list | UI | |
| 2.107 | RoutinesListView from Settings → Routines OR PropertyDetailView Maintenance tab "Routines" row | UI | |
| 2.108 | Routines list shows vendor logo + cadence + active-months summary per row | UI | |
| 2.109 | PickupDayBanner on Dashboard fires evening-before for waste routines (after 6pm local) | UI | Time-windowed; manual time override may be needed. |
| 2.110 | PickupDayBanner fires morning-of for waste routines (before 10am local) | UI | |
| 2.111 | Routine occurrences render on MaintenanceScheduleView calendar layout (Phase 55.2 expander) | UI | |
| 2.112 | Routine occurrences render on Timeline view (collapsed pill in YEAR-AT-A-GLANCE per Phase 56.4) | UI | |
| 2.113 | ChezOwnsToggle on routine → chez_owned=true → standing engagement chez_request | UI | |
| 2.114 | Pause routine → setup_state='paused' → no future occurrences emit | UI | |
| 2.115 | Resume paused routine → setup_state='active' → occurrences resume | UI | |

---

## 3. Round B backend combinatorial coverage

Pure-backend extension to `Tests/e2e/run.mjs` — no UI overhead. Each scenario is a script-driven write + verify against the schema.

| # | Coverage | Owner | Notes |
|---|---|---|---|
| 3.1 | q1_roof × 7 materials (asphalt / metal / tile / slate / wood_shake / flat_membrane / not_sure) | E2E | Verify home_systems Roofing subtype matches each. |
| 3.2 | q3_heating × 8 fuel/system combos | E2E | Verify HVAC subtype + Q19 dynamicSkip behavior across all (skip when electric / geothermal / not_sure). |
| 3.3 | q3b_hvac_type × 9 subtypes (Phase 19b/c) | E2E | Verify HVAC subtype writes per option. |
| 3.4 | q6_water × {municipal / private_well / shared_well} | E2E | Well System home_systems row created on private/shared. |
| 3.5 | q7_sewer × {municipal_sewer / septic} | E2E | Septic system + reconciler-seeded "Septic pump-out (3-year)" task on septic. |
| 3.6 | q8_water_heater × 6 options | E2E | Water Heater subtype matches; Tankless skips "Anode rod" task. |
| 3.7 | q9_basement permutations (finished / unfinished / sump_pump / crawl_space / slab / multi-select) | E2E | Multi-select None-exclusion verified. |
| 3.8 | q9_basement = unfinished WITHOUT sump_pump → NO Sump Pump system (Bug H fix) | E2E | |
| 3.9 | q10_appliances × select-all + custom add | E2E | All ~8 appliance rows inserted; no duplicates. Custom name preserved. |
| 3.10 | q10 None-exclusion mutex (None deselects others; others deselect None) | E2E | |
| 3.11 | q11_lawn × {pro+provider catalog hit / pro+free-form / diy / no_lawn / garden / hardscape} | E2E | Each path's side effects (Landscaping system + Contractor mirror + utility_account + ACTIVE Routine for pro paths). |
| 3.12 | q11b_lawn_type × 4 (natural / synthetic / mixed / not_sure) | E2E | Subtype variants. Synthetic + has_pets adds "Sanitize pet areas" task. |
| 3.13 | q12_pool × {none / in_ground / above_ground / hot_tub / both} × chemistry × 2 (chlorine / salt) | E2E | 4×2 matrix per Bug D verification. Confirm composite subtype. |
| 3.14 | q12 hot_tub_only — only Hot Tub system, no pool umbrella, no children | E2E | |
| 3.15 | q12 both — both Pool + Hot Tub systems separately | E2E | |
| 3.16 | q13_pest × {recurring_pro_service+provider / termite_bond / diy / none} | E2E | |
| 3.17 | q14_irrigation × {yes_full+provider / drip_only / no} | E2E | |
| 3.18 | q15_security × {yes_monitored+provider / yes_self_monitored / cameras_only / none / prefer_not_to_answer} | E2E | |
| 3.19 | q15b_household_contractors × per-chip combinations + custom add per chip | E2E | Cover {handyman, plumber, electrician, hvac, septic, well, chimney, tree} with inline picker per chip. Verify per-chip Contractor row + canonical category + ACTIVE Routine (handyman exception — no routine). |
| 3.20 | q15b conditional chip visibility (septic only when q7=septic; well only when q6=well) | E2E | |
| 3.21 | q16_electric × {catalog pick / custom name} | E2E | utility_account with provider_id (catalog) vs provider_name only (custom). |
| 3.22 | q17_internet × {catalog pick / custom name} | E2E | Same shape. |
| 3.23 | q18_trash × {municipal+1day / municipal+2days / private+1day+hauler / not_sure} | E2E | Verify days serialize correctly as selectedIds. |
| 3.24 | q19_heating_provider × {catalog / custom / SKIPPED via dynamicSkip when q3=electric/geothermal} | E2E | |
| 3.25 | q20_other_fuels × {None / propane_fireplace / multi-select} | E2E | None-exclusion mutex. |
| 3.26 | q21_solar × {yes_owned / yes_leased / no / considering} | E2E | Solar Panels system created per subtype. |
| 3.27 | q22_generator × {none / whole_home + propane (heating ≠ propane) / whole_home + propane (heating = propane → same-supplier confirmation card) / portable + gasoline} | E2E | Same-supplier branch verified end-to-end. |
| 3.28 | q24_vehicle_add × {skip / type VIN with NHTSA decode + recall list} | E2E | |
| 3.29 | q25_garage × {attached / semi_attached / detached / carport / none} + q25b_ev_charger × {yes / no / hidden when garage=none} | E2E | Build 86 split confirmation. |
| 3.30 | q26_insurance × {both carriers / auto only / home only / skip / foundational pre-fill} | E2E | |
| 3.31 | q28_household × every combination (every household type × pets × kids × expecting × caretaker × home_manager) | E2E | Combinatorial — at least 12 representative rows. |
| 3.32 | q30_priorities × {financial / safety / aesthetic / minimal_effort / multi-select / foundational pre-fill} | E2E | |
| 3.33 | q36_diy_vs_vendor × {diy / mixed / hire_out / foundational pre-fill} | E2E | Verify reconciler reflows .either tasks per tier. |
| 3.34 | All `dynamicSkip` closures fire correctly across permutations | E2E | Skip-toast pendingSkipToast text appears on next visible question for each. |
| 3.35 | `firstUnresolvedIndex()` skips foundational-prefilled questions correctly | E2E | Quiz auto-advances past Q15/Q22/Q26/Q28/Q30 when foundational pre-filled them. |
| 3.36 | Chapter boundaries detect correctly (Q12→Q13 = ch1→ch2; Q23→Q24 = ch2→ch3) | E2E | |

---

## 4. Document pipeline

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 4.1 | DocumentVaultView empty state — "Upload your first document" | UI | |
| 4.2 | Upload from photo library (PHPickerViewController) | UI | |
| 4.3 | Upload from camera (live capture) | UI | |
| 4.4 | Upload from Files app (iCloud / local) | UI | |
| 4.5 | Upload PDF (insurance policy) → analyze-document AI categorization | UI | |
| 4.6 | Upload JPG (invoice) → invoice route triggers InvoiceChoiceSheet | UI | |
| 4.7 | Upload DOCX (warranty) → "unsupported file type" banner with metadata flag | UI | |
| 4.8 | Upload HEIC (photo) → handled correctly | UI | |
| 4.9 | Upload .csv → unsupported but stored | UI | |
| 4.10 | Upload .zip → unsupported but stored | UI | |
| 4.11 | Duplicate detection (SHA-256 hash) — second upload of same file → DuplicateResolutionSheet | UI | |
| 4.12 | Replace existing → old file storage deleted, new file uploaded, document row updated | UI | |
| 4.13 | Save both copies → both rows in DB | UI | |
| 4.14 | Delete this document → discard new upload | UI | |
| 4.15 | analyze-document AI suggests category → user confirms OR changes via DocumentCategoryPicker | UI | |
| 4.16 | analyze-document low-confidence → category picker opens by default | UI | |
| 4.17 | High-confidence → "Looks Good" with subtle "Change Category" | UI | |
| 4.18 | analyze-document also stamps `visible_to_home_managers` based on AI category (Build 87) | E2E | |
| 4.19 | Document categories include 88 across 15 groups in DocumentCategoryGroups.swift | UI | |
| 4.20 | DocumentDetailView opens with metadata + preview | UI | |
| 4.21 | view-document Edge Function generates signed URL (zero-access encryption model) | E2E | |
| 4.22 | DocumentDetailView Access row visible only when household has home managers (Build 87) | UI | |
| 4.23 | Tap Access row → DocumentAccessSheet → toggle visibility per home manager | UI | |
| 4.24 | DB updateDocumentHomeManagerVisibility writes correctly | E2E | |
| 4.25 | Home manager's view filters out documents with visible_to_home_managers=false | E2E | RLS verification. |
| 4.26 | Document detected_vins → matched_vehicle_ids → auto-link to vehicle | E2E | |
| 4.27 | Document linked to project (DocumentDetailView "Link to Project") | UI | |
| 4.28 | Document linked to family member via document_family_members table | UI | |
| 4.29 | Document scan via document scanner (camera multi-page) | UI | |
| 4.30 | Document delete (soft-delete with confirmation) | UI | |
| 4.31 | Document encryption (DocumentEncryption AES-256-GCM) at upload | E2E | Verify encryption applied. |
| 4.32 | Document gap analysis → gap-analysis Edge Function suggests missing categories | UI | |
| 4.33 | Document parties extraction (parties involved in legal documents) | E2E | |
| 4.34 | Document content searchable (analyze-document populates document_content) | E2E | |

---

## 5. Invoice processing

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.1 | Upload invoice document → analyze-document categorizes as invoice → InvoiceChoiceSheet | UI | |
| 5.2 | InvoiceChoiceSheet (home/vehicle toggle when both exist) | UI | |
| 5.3 | Pick property → process-invoice Edge Function fires | UI | |
| 5.4 | InvoiceReviewSheet renders with extracted line items + suggested tasks + suggested systems | UI | |
| 5.5 | Toggle individual tasks on/off | UI | |
| 5.6 | Toggle individual system additions on/off | UI | |
| 5.7 | Toggle individual follow-ups on/off | UI | Phase 50 follow-up extraction. |
| 5.8 | CadenceSuggestionCard surfaces on Dashboard when Phase 50 cadence detected | UI | |
| 5.9 | Accept cadence → home_systems.service_interval_days written; tasks rescheduled | E2E | |
| 5.10 | Dismiss cadence → no DB change | UI | |
| 5.11 | Parent system grouping (deterministic keyword table — well, HVAC, pool, electrical, septic, security, solar, irrigation, generator, garage door, fire protection, roofing) | E2E | |
| 5.12 | Unmatched system → user picker for parent assignment | UI | |
| 5.13 | Parent system auto-created if needed | E2E | |
| 5.14 | Duplicate detection (fuzzy matching on word overlap, model number, manufacturer+function) | E2E | |
| 5.15 | Last service date updated on referenced systems | E2E | |
| 5.16 | Vehicle invoice: process-invoice with vehicle_id → mileage updated, vehicle_service_records created | E2E | |
| 5.17 | Vehicle invoice marks matching tasks complete | E2E | |
| 5.18 | Specialty system inference (Phase 52b): "pool heater" mentioned but no Pool system → SpecialtySuggestionCard | UI | |
| 5.19 | "Yes, add it" → home_systems Pool created + reconciler fires | E2E | |
| 5.20 | "Not mine" → household_dismissed_suggestions row → category not re-suggested | E2E | |
| 5.21 | Retroactive "Scan for Maintenance & Systems" from DocumentDetailView | UI | |
| 5.22 | Vendor follow-up tasks stamped with assignmentType=vendor + assignedContractorId + needsVendor + notes prefix | E2E | |
| 5.23 | Phase 95 PR 43 vehicle mileage section on InvoiceReviewSheet | UI | |
| 5.24 | Process invoice → activity feed event created | E2E | |
| 5.25 | Invoice with no extractable text → graceful fallback (manual categorization) | UI | |

---

## 6. Email forwarding pipeline (alfred.getchez.com)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 6.1 | Forward email to user's `*@alfred.getchez.com` address | E2E | |
| 6.2 | Legacy forward to `*@alfred.havenhome.dev` still routes (transition period) | E2E | |
| 6.3 | receive-email Edge Function classifies into one of 9 types | E2E | |
| 6.4 | contractor_quote → inbox item with action_type=quote_action | E2E | |
| 6.5 | estate_document (Will) — Chez v1: routes through standard document flow with no estate-specific UI | E2E | |
| 6.6 | home_document → confirm category prompt | E2E | |
| 6.7 | vehicle_document (title/registration) → vehicle picker prompt | UI | |
| 6.8 | bill_invoice → InvoiceChoiceSheet via inbox | UI | |
| 6.9 | bill_invoice with vehicleContext=true → vehicle invoice path | UI | |
| 6.10 | insurance_claim → "Create Claim Project" / "Save as Document" prompt | UI | |
| 6.11 | vendor_contact → AddVendorSheet pre-filled from extracted data | UI | |
| 6.12 | family → tagged member identified | E2E | |
| 6.13 | other → manual categorization | UI | |
| 6.14 | Inbox empty state: "View Your Chez Email" + Ask Chez secondary | UI | The fix from morning pass — primary salmon, secondary navy. |
| 6.15 | Forwarding email caption on dashboard VendorScheduleStrip empty state with copy-to-clipboard | UI | |
| 6.16 | Utility bill detection (fuzzy match against utility_providers catalog) | E2E | |
| 6.17 | Utility match → AddUtilitySheet prefilled | UI | |
| 6.18 | High-confidence document → "Looks Good" with subtle change-category | UI | |
| 6.19 | Low-confidence document → picker-first | UI | |
| 6.20 | Unsupported file type (.docx/.xlsx/.csv/.zip/.heic) stored, analysis_skipped flag | E2E | |
| 6.21 | iOS shows info banner for unsupported | UI | |
| 6.22 | analyze-document stamps visible_to_home_managers based on category (cross-check from receive-email path) | E2E | |
| 6.23 | Inbox item card shows category picker for confirmation | UI | |
| 6.24 | InboxItemDetailView opens with full document preview | UI | |
| 6.25 | Tap action button → action processed via process-inbox-item Edge Function | UI | |
| 6.26 | Resolve duplicate from inbox (email path duplicate) → 3 options (replace/save_both/delete) | UI | |
| 6.27 | Inbox 4 sub-tabs: Needs Action / Unread / All / Chez | UI | |
| 6.28 | Chez sub-tab shows ChezRequestsListView (Phase 80) | UI | |
| 6.29 | Chez request detail with thread + reply composer | UI | |
| 6.30 | ProcessingBanner in MainTabView shows upload progress, tappable on complete | UI | |
| 6.31 | allowed_senders table prevents spoofed forwards | E2E | |
| 6.32 | First-time forward without account → email response with sign-up link | E2E | |

---

## 7. Maintenance task detail interactions

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 7.1 | Tap a task row → MaintenanceTaskDetailSheet opens | UI | |
| 7.2 | Detail shows: title, description, due date, system, vendor (if any), priority, effort, assignee | UI | |
| 7.3 | Mark complete → confirmation → task moves to history; system last_service_date updated | UI | |
| 7.4 | Mark complete with notes (multi-line text) | UI | |
| 7.5 | Reschedule → date picker → new due date saved | UI | |
| 7.6 | Snooze 7 days → due date += 7 | UI | |
| 7.7 | Snooze multiple times stacks correctly | UI | |
| 7.8 | "Have someone else do it" (personal task) → ContractorPickerSheet OR ChezEntryButton | UI | |
| 7.9 | Convert personal → vendor (with contractor) → MaintenanceViewModel.convertToVendorManaged | E2E | |
| 7.10 | Convert vendor → personal → restores canonical wording | E2E | |
| 7.11 | "Add to handyman list" (personal/either with diyEffortMinutes ≤ 60) → handyman_punch_items row | UI | |
| 7.12 | "Add to handyman" archives the source maintenance_task with archive_reason="moved_to_handyman_punch" (Phase 67E/F) | E2E | |
| 7.13 | "Have Chez handle this" (Section 2h verifications above) | UI | |
| 7.14 | ChezOwnsBadge renders on task row when chez_owned=true | UI | |
| 7.15 | "Edit task" → modify title/description/due | UI | |
| 7.16 | "Delete task" → soft-delete with confirmation | UI | |
| 7.17 | Frequency editor (FrequencyPickerSheet) → preset cadences (Weekly through Annually) + custom days/weeks/months | UI | |
| 7.18 | Frequency override warns when exceeding maxIntervalDays | UI | |
| 7.19 | Frequency override warns "may void warranty" for warrantyLinked templates | UI | |
| 7.20 | Apply frequency to existing tasks toggle | UI | |
| 7.21 | "I already did this" (recently completed) → completion with backdated date picker | UI | |
| 7.22 | Subtask checklist for bundled visits (Phase 19l "What's included:" notes) | UI | |
| 7.23 | Photo evidence on completion | UI | |
| 7.24 | Voice note on completion | UI | |
| 7.25 | Custom task creation via AddMaintenanceTaskSheet → TaskKind picker (maintenance / vendorAppointment / followUp) | UI | |

---

## 8. Family members + invites + home manager + staff

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 8.1 | Tap "+" on HouseholdStrip → AddFamilyMemberChooserSheet (Build 86) | UI | |
| 8.2 | Pick "Add a family member" → FamilyMemberFormView in regular mode | UI | |
| 8.3 | Pick "We're expecting" → form with due date | UI | |
| 8.4 | Add child (name + DOB) → family_members row | UI | |
| 8.5 | Add adult family member with email → invitation flow | UI | |
| 8.6 | Invitation email sends → recipient signs up → linked_user_id populates | Cross | |
| 8.7 | Avatar photo upload (PhotosPicker → AvatarPhotoService → 400px resize → Supabase storage `avatars` bucket) | UI | |
| 8.8 | Avatar 1-year signed URL renders | UI | |
| 8.9 | Edit family member → form pre-populated → save → row updated | UI | |
| 8.10 | Delete family member → confirmation → archived | UI | |
| 8.11 | FamilyMemberProfileView opens on tap from HouseholdStrip | UI | |
| 8.12 | Profile sections: hero / documents / vehicles (covered drivers) / assigned tasks / events | UI | |
| 8.13 | resolveUserId() matches by linkedUserId / email / full name / first name / Primary Client | E2E | |
| 8.14 | Add staff via AddHouseholdStaffSheet (Build 87) | UI | |
| 8.15 | Staff appears in HouseholdStaffStrip on Dashboard (separate from family) | UI | |
| 8.16 | Settings → Household Staff → list filtered to member_type='staff' | UI | |
| 8.17 | Add home manager via AddHouseholdStaffSheet → member_type='home_manager' | UI | |
| 8.18 | Home manager invitation routes through HouseholdInviteCoordinator with memberType:'home_manager' | E2E | |
| 8.19 | Home manager profile renders FirstLaunchWelcomeCard for the home manager (Build 87) | Cross | |
| 8.20 | Home manager destructive UI hidden (delete property, delete household) per Phase 95 PR 39 | UI | |
| 8.21 | Home manager assigned a task → MaintenanceViewModel.assignedUserName appends " · Home Manager" suffix | UI | |
| 8.22 | Home manager sees only documents with visible_to_home_managers=true (RLS) | E2E | |
| 8.23 | DocumentAccessSheet renders only when household has home managers | UI | |
| 8.24 | Toggle document visibility per home manager → updateDocumentHomeManagerVisibility | UI | |
| 8.25 | Family members sorted by age ([FamilyMemberRow].sortedByAge() — oldest first, no-DOB last alphabetically) | UI | |
| 8.26 | Expecting member with isExpecting flag + due date | UI | |
| 8.27 | School field captured for school-age children | UI | |
| 8.28 | Family member assigned to events via taggedMemberIds | UI | |
| 8.29 | Family member linked to vehicle as covered driver | UI | |
| 8.30 | Multi-add via Q28 caretakers flow (covered in 2b) | UI | |

---

## 9. Trusted contacts

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 9.1 | Settings → Trusted Contacts → empty state | UI | |
| 9.2 | "Add trusted contact" → form (name + relationship + contact info + access tier) | UI | |
| 9.3 | Save → trusted_contacts row | E2E | |
| 9.4 | Avatar photo upload | UI | |
| 9.5 | Share documents → link selected documents to trusted_contact_documents junction | UI | |
| 9.6 | Trusted contact gets notification of access (out of scope for this matrix to verify their inbox) | E2E | Verify outbound email sent via SendGrid. |
| 9.7 | Edit access tier → adjusts what they can see | UI | |
| 9.8 | Revoke access → trusted_contact_documents rows deleted; contact stays | UI | |
| 9.9 | Delete trusted contact → cascades to junction | UI | |
| 9.10 | Trusted contact list sorted by name | UI | |
| 9.11 | Cross-reference with FamilyMemberProfileView | UI | |

---

## 10. Vehicle management (full coverage)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 10.1 | Add vehicle via "+ Add" on Property tab (under "Your Garage") | UI | |
| 10.2 | Add vehicle via VIN scan (camera + OCR or manual entry) | UI | |
| 10.3 | Add vehicle via insurance card upload | UI | |
| 10.4 | Add vehicle via type VIN / details | UI | |
| 10.5 | NHTSA decode populates make/model/year/trim | E2E | |
| 10.6 | NHTSA recall list populated | E2E | |
| 10.7 | AI maintenance schedule generated → maintenance_tasks rows created | E2E | |
| 10.8 | VehicleDetailView renders brand hero (color gradient, logo, VIN, plate, color, year/model/trim, mileage pill) | UI | |
| 10.9 | Mileage quick-update (MileageUpdateSheet) | UI | |
| 10.10 | Covered Drivers (overlapping avatars; tap to edit; age 16+ filter) | UI | |
| 10.11 | CoveredDriverPickerSheet | UI | |
| 10.12 | Mechanic Card (linked contractor; one-tap call; "Add New" inline) | UI | |
| 10.13 | MechanicPickerSheet | UI | |
| 10.14 | Stats Row (Total Spent / Service Count / Last Service) | UI | |
| 10.15 | Unified Attention (recalls + reg/inspection alerts + overdue maintenance; green "All good" when empty) | UI | |
| 10.16 | Recall card with three-state acknowledgment (Phase 95 PR 29) — open / acknowledged / fixed | UI | |
| 10.17 | check-vehicle-recalls Edge Function fires periodically | E2E | |
| 10.18 | New recall detected → push notification + activity feed event | Cross | |
| 10.19 | Registration / Insurance / Ownership cards (3-card layout, tappable) | UI | |
| 10.20 | EditInsuranceSheet (Phase 95 PR 41) — vehicle insurance backing fields | UI | |
| 10.21 | Maintenance Grid (4-column labeled tiles, urgency color-coded) | UI | |
| 10.22 | Service History (mileage at service; total cost footer) | UI | |
| 10.23 | Documents (long-press to unlink/delete) | UI | |
| 10.24 | Document VIN auto-link (analyze-document detects VINs, matches to vehicle) | E2E | |
| 10.25 | Ask Alfred with vehicle context | UI | |
| 10.26 | EditVehicleSheet | UI | |
| 10.27 | PurchaseDatePickerSheet | UI | |
| 10.28 | Vehicle invoice processing (Section 5.16 cross-ref) | UI | |
| 10.29 | Soft-archive flow for sold/traded/totaled vehicles (Phase 95 PR 30) | UI | |
| 10.30 | proactive-scan checks NHTSA + sends push | E2E | |

---

## 11. Property detail sub-tabs

For each sub-tab: open → render → exercise primary interactions → close.

### 11a. Overview

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.1 | Overview hero — InvestmentSummaryCard with estimated value range, source, gain/loss | UI | |
| 11.2 | "Refresh from public records" (Build 84) → re-fires propertyLookup → updates persisted band | UI | |
| 11.3 | Stacked bar (purchase / projects / surplus or gap) | UI | |
| 11.4 | Bottom summary (net after sale, unrealized gain/loss) | UI | |
| 11.5 | Expand toggle → waterfall breakdown | UI | |
| 11.6 | equityUpsellCard (Build 84) — navy gradient sub-card with "Homes maintained well sell for ~7.4% more" | UI | |
| 11.7 | Sale simulator button → opens scenario | UI | |
| 11.8 | "PRIMARY RESIDENCE" eyebrow — should NOT be salmon (the morning fix) | UI | |
| 11.9 | "X Priorities" stat — should NOT be salmon (the morning fix) | UI | |

### 11b. Maintenance

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.10 | Maintenance tab order: overdue banner → upcoming vendor visits → your tasks → vendor follow-ups → routines row → handyman punch list row → recommended services → home systems → seasonal overview → view-full-schedule footer → service history | UI | |
| 11.11 | Stats-pill filter (Overdue / This Week / This Month / Later) — tap to toggle | UI | |
| 11.12 | "Showing {label}" caption with Clear button | UI | |
| 11.13 | Layout toggle (List / Timeline) per Phase 56.4 | UI | |
| 11.14 | Two-bucket UI: To Schedule + Scheduled (Phase 56.5 / Build 92) | UI | |
| 11.15 | DuplicateReviewBanner (Phase 56.5 / Build 92, patched Build 93) | UI | |
| 11.16 | Tap a duplicate match → MaintenanceDuplicateSheet → "Keep both" / "Merge into..." with progress indicator | UI | |
| 11.17 | Inline handyman quick-add per Phase 56.6 (Build 94) — "Or add to handyman list" link on findContractor card | UI | |
| 11.18 | Compact routines strip (Phase 56.6 / Build 94) — horizontal scroll of ~44pt pills | UI | |

### 11c. Systems

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.19 | "0 of 12 systems verified" SystemCoverageCard — progress bar should NOT be salmon (morning fix) | UI | |
| 11.20 | System category tiles (notification dots should be amber not salmon — morning fix) | UI | |
| 11.21 | Tap system category → list of systems in that category | UI | |
| 11.22 | Tap individual system → SystemDetailView with brand/model/serial + manual + service history | UI | |
| 11.23 | "Add details" → camera or manual entry | UI | |
| 11.24 | identify-equipment Edge Function decodes plate photo | E2E | |
| 11.25 | Service frequency editor (FrequencyPickerSheet) per Section 7 | UI | |
| 11.26 | "Recommended for your home" sparkles row → RecommendedServicesView | UI | |
| 11.27 | RecommendedServicesView lists templates not yet scheduled, filtered by household subtypes | UI | |
| 11.28 | Per-card CTAs: Schedule it / Add to handyman / Hide | UI | |
| 11.29 | Settings → Show all hidden recommendations | UI | |
| 11.30 | Sub-system hierarchy (parent_system_id) renders correctly | UI | |
| 11.31 | Add new system via AddSystemView → category picker → required-fields form | UI | |

### 11d. Contacts (Phase 56)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.32 | Contacts sub-tab structure: header + Add button + search + 4 filter chips | UI | |
| 11.33 | Filter chips: All / Service-based / Utilities & policies / Routines / Needs review | UI | |
| 11.34 | Search across companyName + contactName + specialties | UI | |
| 11.35 | Routine chip filter cross-references viewModel.routineVendorIds | UI | |
| 11.36 | Apple Contacts-style row layout (32pt logo + truncated name + primary specialty + chevron) | UI | |
| 11.37 | "ADD OR DISCOVER" section with 5 entries | UI | |
| 11.38 | Browse specialty systems → AddSystemView | UI | |
| 11.39 | Add a custom system | UI | |
| 11.40 | Add a routine → RoutineEditSheet | UI | |
| 11.41 | See recommended services → RecommendedServicesView | UI | |
| 11.42 | Vendor coverage gaps section | UI | |

### 11e. Documents (per-property subset)

Per Section 4 above. Sub-tab is filtered to documents linked to this property.

### 11f. Projects

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.43 | "Add Project" → confirmation dialog with "Plan New Project" / "Log Completed Project" | UI | |
| 11.44 | Plan New Project → AI research (research-project) → quotes + line items + planning scaffolding | UI | |
| 11.45 | project-feasibility Edge Function | E2E | |
| 11.46 | Active quote concept (active_quote_id) | UI | |
| 11.47 | First quote auto-activates | E2E | |
| 11.48 | Long-press to change active quote | UI | |
| 11.49 | Project quotes tab — comparison view | UI | |
| 11.50 | analyze-quote (Phase 95 PR 37) surfaces line items + DIY alternative | UI | |
| 11.51 | draft-negotiation-email (Phase 95 PR 42) iOS surface | UI | |
| 11.52 | Project documents linked via document.project_id | UI | |
| 11.53 | Project files via project_files table | UI | |
| 11.54 | Project contacts via project_contacts table | UI | |
| 11.55 | Project visualizations via visualize-room | UI | |
| 11.56 | Email forwarding to project (project-specific email address per ProjectEmailView) | Cross | |
| 11.57 | Email→Project matching multi-signal (sender + subject + category) | E2E | |
| 11.58 | Insurance claim sub-projects | UI | |
| 11.59 | Inline "Add new" sub-project on insurance claims (Phase 95 PR 34) | UI | |
| 11.60 | LogHistoricalProjectView → name + category + date + total spent + notes | UI | |
| 11.61 | Historical project (entry_type='historical') skips AI scaffolding | UI | |
| 11.62 | Historical project shows historicalHeader + projectDocumentsSection + notes | UI | |
| 11.63 | LinkDocumentToProjectSheet | UI | |
| 11.64 | InvestmentSummaryCard waterfall reflects in-flight project estimates (Phase 95 PR 40) | UI | |

### 11g. Equipment (catalog)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.65 | Browse equipment_catalog (219 brands × 2,818 models) | UI | |
| 11.66 | search-equipment Edge Function | E2E | |
| 11.67 | identify-equipment via photo | E2E | |
| 11.68 | lookup-manual fetches PDF from equipment-manuals bucket | E2E | |
| 11.69 | score-equipment | E2E | |
| 11.70 | enrich-catalog | E2E | |
| 11.71 | send-catalog-request when product not in catalog | E2E | |

### 11h. Utility Accounts

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.72 | Utility accounts list (electric / gas / water / internet / etc.) | UI | |
| 11.73 | AddUtilitySheet with provider catalog search | UI | |
| 11.74 | Provider logo (Brandfetch) renders | UI | |
| 11.75 | Account number captured | UI | |
| 11.76 | Cost tracking per month | UI | |
| 11.77 | Bill detection from receive-email mirrors here | E2E | |

---

## 12. Project creation deep dive

Covered in 11f above; consolidated here for reference.

---

## 13. Chez full concierge flow

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 13.1 | Tap any ChezEntryButton (17 entry points per CLAUDE.md) → ChezRequestComposeSheet | UI | |
| 13.2 | Compose sheet: category picker / summary / description / attachments / submit | UI | |
| 13.3 | Submit → chez-concierge submit action → chez_requests row + first concierge_messages | E2E | |
| 13.4 | Notification fires to admin user IDs + SendGrid email | E2E | |
| 13.5 | Inbox 4th sub-tab "Chez" lists user's requests | UI | |
| 13.6 | Tap a request → ChezRequestDetailView | UI | |
| 13.7 | Thread renders user/concierge/system bubbles (ChezMessageBubble) | UI | |
| 13.8 | Reply composer with attachment upload | UI | |
| 13.9 | Reply submit → reply action → message inserted | E2E | |
| 13.10 | Mark read → mark_read action | E2E | |
| 13.11 | Reopen a resolved request → transition_status action | UI | |
| 13.12 | Inline structured proposal cards (Phase 80.1) — ChezProposalCard with kind variants (vendor / date_slot / cost / quote) | UI | |
| 13.13 | Approve proposal → decide_proposal action with status='approved' | UI | |
| 13.14 | Counter proposal → composer with counter terms | UI | |
| 13.15 | Decline proposal → decide_proposal with status='declined' + reason | UI | |
| 13.16 | Settings → Your Chez profile → ChezProfileView | UI | |
| 13.17 | Profile sections: about_us / communication / vendor_preferences / logistics / spending_tiers (default 200/500/500) | UI | |
| 13.18 | Update profile → fetch_profile + update_profile actions | E2E | |
| 13.19 | Spending Authority section background should NOT be salmon (morning fix) | UI | |
| 13.20 | ChezOwnsToggle on routine → delegate_routine action | UI | |
| 13.21 | ChezOwnsToggle on contractor → delegate_contractor action | UI | |
| 13.22 | ChezOwnsToggle on task (Phase 80.2) → delegate_task with smart category routing | UI | |
| 13.23 | ChezOwnershipHeroCard on Dashboard (the morning fix - now navy) | UI | |
| 13.24 | "Hand off everything" CTA inside ChezOwnershipHeroCard (still salmon — actual primary CTA) | UI | |
| 13.25 | ChezDelegationsListView → aggregated routines + vendors + tasks with revoke pills | UI | |
| 13.26 | Quick-question Chez surface (Phase 95 PR 36) | UI | |

---

## 14. Settings sub-screens (exhaustive)

Settings list-row icons must all be NAVY (morning fix). Verify each sub-screen.

| # | Sub-screen | Owner | Notes |
|---|---|---|---|
| 14.1 | Your Chez profile | UI | Per Section 13. |
| 14.2 | Profile (ProfileView) | UI | Edit name / email / phone / avatar |
| 14.3 | Family Members | UI | Per Section 8 |
| 14.4 | Manage Household & Access | UI | Invite/remove members; manage primary |
| 14.5 | Household Staff (Build 87) | UI | Per Section 8 |
| 14.6 | Household Email (forwarding email + provisioning) | UI | |
| 14.7 | Security Dashboard (SecurityDashboardView) | UI | |
| 14.8 | Security Settings | UI | Biometric toggle / vault timeout / passcode |
| 14.9 | Trusted Contacts | UI | Per Section 9 |
| 14.10 | Notifications (NotificationsView) | UI | Per-event toggles |
| 14.11 | Home details (revise foundational answers per Phase 95 PR 33) | UI | |
| 14.12 | Maintenance Preferences (3-tier picker: I handle it / Mix / Hire it out) | UI | The reference-quality screen per W5S17 audit |
| 14.13 | Handyman Preference | UI | Sub-preference for handyman category |
| 14.14 | Task Routing | UI | Per-category routing overrides |
| 14.15 | Family Reference Binder | UI | |
| 14.16 | Privacy Policy / Terms / Contact Support | UI | Static or webview |
| 14.17 | Sign Out → confirmation → keychain cleared | UI | |
| 14.18 | Delete Account → cascading deletion | UI | Critical destructive action |
| 14.19 | Settings tint locally overridden to navy (morning fix `84bdc9be`) — verify NO salmon icons across all rows | UI | The whole-list verification |

---

## 15. Push notifications (deep-link verification)

For each: notification arrives → tap → deep-link routes correctly → badge updates.

| # | Event | Owner | Notes |
|---|---|---|---|
| 15.1 | Cadence reminder evening-before (waste pickup) | Cross | cadence-notifications Edge Function |
| 15.2 | Cadence reminder morning-of | Cross | |
| 15.3 | Recall alert (proactive-scan) | Cross | |
| 15.4 | Document processed (analyze-document complete) | Cross | |
| 15.5 | Inbox item received (new email) | Cross | |
| 15.6 | Family member joined (invitation accepted) | Cross | |
| 15.7 | Chez admin reply on a request | Cross | |
| 15.8 | Chez status change (request transitioned) | Cross | |
| 15.9 | Chez proposal received | Cross | |
| 15.10 | Vehicle recall (NHTSA) | Cross | |
| 15.11 | Maintenance task overdue | Cross | |
| 15.12 | Quote received from contractor | Cross | |
| 15.13 | Visit scheduled by Chez | Cross | |
| 15.14 | Visit completed (handyman finished) | Cross | |
| 15.15 | Tap notification with app cold → routes to deep destination | UI | |
| 15.16 | Tap notification with app already at destination → no double-push | UI | |
| 15.17 | Notification permission denied → in-app inbox is sole signal | UI | |

---

## 16. Calendar sync

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 16.1 | Settings → Notifications → Calendar Sync OAuth (Google) | UI | |
| 16.2 | OAuth round-trip → synced_calendars row | E2E | |
| 16.3 | Family events from Chez render in Google Calendar | Cross | |
| 16.4 | iOS calendar (expo-calendar style local) sync | UI | |
| 16.5 | family_events table populated | E2E | |
| 16.6 | Event tagging via taggedMemberIds | E2E | |
| 16.7 | CalendarSyncSheet | UI | |
| 16.8 | Multi-event email parsing (.ics support per upcoming feature) | E2E | If implemented |
| 16.9 | Disconnect calendar → tokens revoked | UI | |

---

## 17. Vault lock + biometric + security

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 17.1 | App launch → BiometricAuthView prompts (when biometric enabled) | UI | |
| 17.2 | Face ID / Touch ID success → lands on dashboard | UI | |
| 17.3 | Biometric fallback to passcode | UI | |
| 17.4 | Biometric denied → app stays locked | UI | |
| 17.5 | VaultLockService timeout → re-prompt after N minutes idle | UI | |
| 17.6 | Document encryption (DocumentEncryption AES-256-GCM) at upload (cross-ref Section 4) | E2E | |
| 17.7 | ScreenshotPrevention.install() at app launch | UI | Verify screen recording shows blank for sensitive views |
| 17.8 | JailbreakDetection warning (test with sim — should NOT trigger) | UI | |
| 17.9 | SecureLogger never logs PII | E2E | Code review check |
| 17.10 | view-document Edge Function returns signed URL with limited expiry | E2E | |
| 17.11 | Cascading account deletion | E2E | |
| 17.12 | TokenManager refresh + storage in keychain | E2E | |
| 17.13 | SecureStorageService | E2E | |
| 17.14 | Security Dashboard renders state of all the above | UI | |

---

## 18. Estate intelligence absence verification (Chez v1)

Chez v1 removed the Phase 48 estate intelligence module. Verify it's GONE from every surface.

| # | Verification | Owner | Notes |
|---|---|---|---|
| 18.1 | No Estate tab in any navigation | UI | |
| 18.2 | Dashboard does NOT render estateNudge / EstateIntakeDripCard / FoundationCard with estate language | UI | |
| 18.3 | No "Estate professionals" filter chip in Contacts | UI | |
| 18.4 | DocumentCategoryGroups.swift does not expose "Estate Planning" group | UI | |
| 18.5 | DocumentCategory.swift still declares Will/Trust/POA enum values for backward decode (verify by viewing an existing legacy estate document) | UI | |
| 18.6 | Q29 estate documents removed from quiz; legacy q29_estate_docs answer-id no-ops on saved-for-later | E2E | |
| 18.7 | DB tables `estate_state` + `estate_pdf_exports` do NOT exist (verify migration `20260901_chez_v1_estate_removal.sql` ran) | E2E | |
| 18.8 | Edge Function `verify-estate-export` does NOT exist | E2E | |
| 18.9 | analyze-document does NOT run estate-extraction branch | E2E | |
| 18.10 | gap-analysis / chat / simulate-scenario / proactive-scan do NOT read estate_state | E2E | |

---

## 19. Dashboard quick actions + interactions

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 19.1 | Compact greeting + seasonal context tip (per Phase 56.2) | UI | |
| 19.2 | HomeCoverageHero (per Bug B re-verification, Section 1b) | UI | |
| 19.3 | QuickActionsRow — 4 actions (Ask Alfred / Upload doc / Plan ahead / Add vendor) | UI | |
| 19.4 | Each Quick Action navigates correctly | UI | |
| 19.5 | UP NEXT section (60-day window, 5-item cap, user-assignment filter) | UI | |
| 19.6 | "View full schedule" → MaintenanceScheduleView calendar layout (the morning fix) | UI | |
| 19.7 | Inline snooze button (zzz icon) +7 days | UI | |
| 19.8 | UP NEXT empty state ("Nothing to schedule in the next 60 days") | UI | |
| 19.9 | "See all" navigates to MaintenanceScheduleView with .mine filter | UI | |
| 19.10 | CadenceSuggestionCard (event-driven, per Section 5.8) | UI | |
| 19.11 | PickupDayBanner (time-windowed, per Section 2i) | UI | |
| 19.12 | RecentActivityFeed (13 event types per Phase 52, 7 visible, "View all activity" → ActivityLogView) | UI | |
| 19.13 | Filtered Recent feed (vendorLinked + systemAdded events filtered after first 7 days, per Phase 56) | UI | |
| 19.14 | FoundationCard at bottom (per CLAUDE.md spec — verify whether it renders or not) | UI | |
| 19.15 | Forwarding email caption with copy-to-clipboard | UI | |
| 19.16 | HouseholdStrip with avatars sorted by age | UI | |
| 19.17 | HouseholdStaffStrip below HouseholdStrip when staff exist | UI | |
| 19.18 | "What If?" FAB (sparkles button) on every tab except Alfred | UI | |
| 19.19 | FAB → ScenarioStudioView (fullScreenCover) | UI | |
| 19.20 | FAB collapses to icon-only after first use | UI | |
| 19.21 | scenario simulate-scenario Edge Function | E2E | |
| 19.22 | ScenarioRunnerService persists scenarios to scenario_history | E2E | |
| 19.23 | Day 0 first-login Getting Started / Quiz hero (per sub-phase B gating) | UI | |
| 19.24 | Pre-quiz: dashboard collapsed, only quiz CTA visible | UI | |
| 19.25 | MaintenanceReorganizedCard NOT shown to new signups (the morning fix accountCreatedAt < phase66ReleaseDate) | UI | |
| 19.26 | DuplicateReviewBanner above stats pills on Maintenance tab when duplicates detected | UI | |
| 19.27 | Cross-tab pop-to-root via NotificationCenter | UI | |
| 19.28 | Tab tap resets navigation stack | UI | |

---

## 20. Find local vendors (Phase 19n)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 20.1 | FindLocalVendorSheet opens with category pre-filtered (from VendorCoverageSheet OR ContractorDirectoryView delegation) | UI | |
| 20.2 | find-local-vendors Edge Function fires with town + state + category | E2E | |
| 20.3 | Google Places Text Search results returned + cached in local_vendor_results (60-day TTL) | E2E | |
| 20.4 | Up to 4 vendors per (town, state, category) | UI | |
| 20.5 | Haven Certified badge on top 2 (4.7+ stars, 25+ reviews, non-chain) | UI | |
| 20.6 | Tap a vendor → details + Add to my contacts | UI | |
| 20.7 | "Or have Chez source one" inline link → ChezEntryButton | UI | |
| 20.8 | Cache hit returns instantly (next request within 60d) | E2E | |
| 20.9 | Empty state when no Google Places results | UI | |

---

## 21. Cross-app integration round trips

These need TWO surfaces driven simultaneously (homeowner sim + handyman sim or contractor web).

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 21.1 | Customer requests quote → Chez admin assigns to contractor → contractor quotes → Chez relays back → customer accepts → visit scheduled → completed → invoice → paid | Cross | The full happy path. |
| 21.2 | Customer flips ChezOwnsToggle on routine → Chez admin sees standing engagement → Chez schedules next visit → customer gets confirmation push | Cross | |
| 21.3 | Customer messages Chez via ChezRequestComposeSheet → admin replies via Concierge cockpit → customer's inbox shows reply with action_needed flag (or informational) | Cross | |
| 21.4 | Customer's task delegated to Chez → Chez routes to handyman → handyman accepts/declines → all three sides stay in sync | Cross | |
| 21.5 | Customer sends a handyman a quote request via app → handyman receives in Field app → quotes via Field app → quote arrives in customer's inbox | Cross | |
| 21.6 | Customer counters a quote → handyman receives counter notification → counters back → 4-round negotiation completes → customer accepts | Cross | |
| 21.7 | Handyman submits an on-behalf-of assessment → customer's dashboard populates with all systems / vendors / routines | Cross | |
| 21.8 | Handyman suggests a task via Field app → customer receives in their app → accepts → task appears on maintenance list | Cross | |
| 21.9 | Customer adds a punch item during a live visit → handyman sees it appear live in their punch list | Cross | |
| 21.10 | Handyman ends visit → summary auto-sent → customer reviews + signs off → handyman gets payment-ready signal | Cross | |
| 21.11 | Customer's quote rejected → Chez intercepts and offers an alternative vendor → original handyman gets "you weren't selected" notification | Cross | |
| 21.12 | Customer revokes Chez ownership mid-engagement → contractor's standing relationship returns to direct-customer-coordination | Cross | |

---

## 22. Per-scenario test discipline (apply to EVERY scenario above)

Mirror of [HANDYMAN_TEST_MATRIX.md](HANDYMAN_TEST_MATRIX.md) Section 21 — every subagent must apply the standard discipline below.

### A. Save / persistence checks (mandatory on every create / edit / delete)

| Check | What to verify |
|---|---|
| A1 Save → relaunch | Create entity, terminate app, relaunch, confirm entity persists with all fields |
| **A1+ ChezEntryButton context contract** (post-Round-A) | **Every ChezEntryButton tap MUST: (a) pass non-empty `context` dict at the call site, (b) the dict must include `source_entity_type` (task / routine / system / vendor / project / etc.) AND `source_entity_label` (human-readable display name), (c) the resulting ChezRequestComposeSheet's RE: section must render `source_entity_label` as primary header, not just generic category. Audit all 17 entry points from CLAUDE.md. Failures = `ui_quality_finding` severity `major` (Tom's support team can't source without context). Caught generic "Roofing" RE: from a routine context in the Round A audit.** |
| A2 Save → background → foreground | Create, background 30s, return, confirm persistence |
| A3 Save → DB cross-check | Curl PostgREST with service-role JWT, confirm row + shape |
| A4 Edit existing → no duplicate | Open existing, edit, save. Confirm UPDATED not duplicated |
| A5 Save partial → resume preserves draft | Multi-step form half-filled, kill app, relaunch, draft preserved |
| A6 Save offline → sync on reconnect | Airplane mode → save → reconnect → entity syncs within 30s |
| A7 Delete → confirmation OR undo | Soft-delete and hard-delete should have confirmation OR 5-second undo |
| A8 Concurrent edit | Two-app concurrent edit → confirm last-write-wins or conflict UI |

### B. UI quality checks (mandatory on every distinct screen)

| Check | What to verify |
|---|---|
| B1 Salmon discipline | CTAs only — never decoration / inactive icon / background wash |
| **B1+ CTA legibility (post-Round-A addition)** | **Every filled button / pill / chip MUST use one of these valid foreground/background pairs: `textOnAction` on `action` (white on salmon, primary CTA), `textOnNavy` on `navy` / `navy800` (white on navy, secondary), `textPrimary` on `creamLight` / `surface` (navy on white, outlined), or `textPrimary` on `beige200` / `cream` (navy on light gray, chip). Anything else (e.g. navy text on navy fill) fails — file a `ui_quality_finding` severity `major` because the user can't read the affordance. Caught the "Log visit and spend" purple-on-purple button on RoutineDetailView in the Round A audit.** |
| B2 Typography mix | New York serif 18pt+, SF Pro 16pt and below |
| B3 Em dashes (`—`) in user-facing copy | Hard rule — flag every one |
| B4 Brand voice | "Chez" never operator name |
| B5 Spacing + radii | Card 16pt, button 14pt, button height 50pt, page margin 20pt |
| B6 Touch targets ≥ 44pt | |
| B7 Shadows | Indigo-tinted, never pure black, disabled in dark mode |
| B8 Animation quality | Smooth, high-damping, ~0.35s response |
| B9 Empty / loading / error / populated states | Skeleton loading not spinners |
| B10 Layout under content extremes | Test 3 content lengths: short / typical / long |
| **B11 Information density / visual hierarchy (post-Round-A addition)** | **Every screen with 3+ distinct content sections (cards, lists, hero blocks) gets a "screen feels overwhelming?" assessment. If a screen has 4+ sections vying for attention OR feels visually dense, file `ui_quality_finding` severity `moderate` with tag `needs-simplification`. Don't propose a specific simplification — defer to product. Aggregates into a "screens needing simplification" list across the app. Caught the Dashboard UPCOMING + NEEDS YOUR ATTENTION + RECENT ACTIVITY overload in the Round A audit.** |

### C. Edge case input checks (mandatory on every form)

| Check | What to verify |
|---|---|
| C1 Empty / whitespace submit | Validation fires visibly, submission blocked |
| C2 Max length (500-char paste) | Cap or scroll, no layout break, no DB error |
| C3 Special characters | O'Brien, 🔧, é/ñ/中文, `<script>`, `'; DROP TABLE` — all save + display correctly |
| C4 Numeric edge cases | Negative, zero, very large, decimals where ints expected |
| C5 Date edge cases | Feb 29, DST transition, very past (1900), very future (2100) |
| C6 Pasting formatted text | Strips formatting cleanly |
| C7 Network failure mid-save | Clear error with retry / save-as-draft |
| C8 Server 500 mid-save | Graceful error, no crash, no silent fail |

### D. Async / network state checks (mandatory on every loading surface)

| Check | What to verify |
|---|---|
| D1 Loading skeleton (NEVER spinner on blank) |  |
| D2 Network failure on initial load → recoverable error |  |
| D3 Slow network (3G) → no hang, loading state visible |  |
| D4 Pull-to-refresh → re-fetches, not just animates |  |
| D5 Pagination / infinite scroll on large lists |  |
| D6 Optimistic UI | UI reflects change immediately, syncs to server, rolls back on failure |

### E. App lifecycle checks (mandatory once per major surface)

| Check | What to verify |
|---|---|
| E1 Background → foreground state preservation |  |
| E2 Kill → relaunch state preservation OR sensible reset |  |
| E3 Push deep link with app cold |  |
| E4 Push deep link with app at destination — no double-push |  |
| E5 Modal interruption | Backgroud while sheet up, return — sheet still present |  |
| E6 In-call interruption | Resume cleanly |  |

### F. Multi-device / concurrent (sampled — apply to ~25% of scenarios)

| F1 Two-device sync | Edit on phone, view on tablet — sync within 5s |
| F2 Two-device conflict | Both edit same entity simultaneously — verify resolution |
| F3 Offline + online merge | Phone offline edit, tablet online edit — merge sensibly |

### G. Performance / scale (sampled — lists + heavy surfaces only)

| G1 100+ items | Initial load < 3s, smooth scroll |
| G2 1000+ items | Pagination kicks in OR acceptable load |
| G3 Search performance | Debounced, < 1s response |
| G4 Photo upload at scale | Queue handles 20 photos in one assessment |

### H. Accessibility (sampled — ~20% of screens)

| H1 VoiceOver navigation | All actionable elements labeled and reachable |
| H2 Dynamic Type at "Larger Accessibility" | Layout doesn't break |
| H3 Dark mode | Every screen has dark variant |
| H4 Color contrast (WCAG AA) | Salmon-on-white borderline 3:1 — flag if used for body |
| H5 Reduced motion | Animations gracefully disabled |

### Required coverage per scenario — EXHAUSTIVE, NOT SAMPLED + per-section matrix

The discipline is built around the principle that **edge cases are mandatory, not optional**. Happy-path-only testing is a known anti-pattern; this matrix exists specifically because the V1 matrix sampled too lightly. Apply the FULL set of applicable categories to each scenario:

**For every scenario, run ALL applicable categories, not just a sample.** Determine applicability by what the scenario does:

| Scenario type | Mandatory categories (full sweep, not sampled) |
|---|---|
| **Creates / edits / deletes any entity** | A1-A8 (full persistence sweep) + B1-B11 + applicable C + D + E1-E2 |
| **Has any form input** | C1-C8 (full input edge case sweep — empty / whitespace / max length / special chars / numerics / dates / paste / network failure / server 500) + B + applicable A |
| **Loads data from network** | D1-D6 (full async/network state sweep — skeleton / failure / slow / refresh / pagination / optimistic) + B |
| **Visible screen** | B1-B11 (full UI quality sweep, including B1+ legibility and B11 density) on every distinct screen visited |
| **Multi-step flow** | E1-E5 (lifecycle: background / kill / push / modal / interruption) — at minimum E1 + E2 |
| **Read-only view** | B + sampled G (performance only if list is involved) |
| **Any ChezEntryButton tap** | **A1+ context contract MANDATORY — verify dict + RE: rendering at all 17 entry points** |

### Per-section discipline matrix (no judgment calls)

To eliminate the "did this category apply?" judgment ambiguity that produced gaps in Round A, each Round C section gets an explicit checklist:

| Section | Mandatory checks per scenario |
|---|---|
| 4 Document pipeline | A1-A8 + B1-B11 + C1-C8 + D1-D6 + E1-E2 |
| 5 Invoice processing | A1-A8 + B1-B11 + C1-C8 + D1-D6 |
| 6 Email forwarding pipeline | A1-A8 + B1-B11 + D1-D6 |
| 7 Maintenance task detail | A1-A8 + B1-B11 + C1-C8 + D1-D6 + **A1+ on every ChezEntryButton** |
| 8 Family + invites | A1-A8 + B1-B11 + C1-C8 |
| 9 Trusted contacts | A1-A8 + B1-B11 + C1-C8 |
| 10 Vehicle management | A1-A8 + B1-B11 + C1-C8 + D1-D6 |
| 11 Property detail sub-tabs | B1-B11 on every sub-tab + A/C/D where applicable |
| 13 Chez full concierge | A1-A8 + **A1+ MANDATORY** + B1-B11 + C1-C8 + D1-D6 + E1-E2 |
| 14 Settings | B1-B11 (all 19 sub-screens) + A on save paths |
| 15 Push notifications | E3-E4 (deep link with cold + at destination) on every event |
| 16 Calendar sync | A6 (offline sync) + D1-D6 |
| 17 Vault lock | E1-E5 + persistence |
| 18 Estate intelligence absence | B11 (verify NO estate UI surfaces) |
| 19 Dashboard | B1-B11 (especially B11 density given known overload) |
| 20 Find local vendors | A1+ (if it exposes ChezEntryButton) + B1-B11 |
| 21 Cross-app integration | F (concurrent / multi-device) on every round trip |

If a scenario in section X doesn't touch a category in the table (e.g. read-only view in Section 11 has no C inputs), say so explicitly in the result. Don't silently skip.

**Sampled (do NOT skip if applicable, but don't run on every scenario):**
- F (concurrent / multi-device) — sample on shared-state scenarios (~25% of applicable rows)
- G (performance / scale) — sample on lists + heavy surfaces only
- H (accessibility) — sample ~20% of screens

**Destructive testing mandate:** your job includes *trying to break the app*. For every form, attempt at least:
- Empty submission
- All-whitespace submission
- 500-character paste
- Special chars (emoji + unicode + apostrophe + HTML-like + SQL-like)
- Numeric overflow / negative values where applicable
- Date past/future/leap-year edges
- Network failure mid-save (toggle airplane mode)
- Server 500 mid-save (force via curl-modified payload)
- Rapid double-tap on submit
- Rapid back-nav during save

For every async load, attempt at least:
- Cold load with airplane mode on (recoverable error?)
- Slow network (3G via simulator status_bar override or Network Link Conditioner)
- Pull-to-refresh during slow load
- Rapid scroll on list with pagination

For every multi-step flow, attempt at least:
- Background mid-flow → return → state preserved
- Force-quit mid-flow → relaunch → resume or sensible cold-start
- Push notification during flow → modal handling

If a check doesn't apply, say so explicitly with reason in the result. Don't silently skip. Empty `discipline_coverage` arrays for applicable categories are a process bug.

---

## 23. Findings categorization (4 buckets)

Mirror of [HANDYMAN_TEST_MATRIX.md](HANDYMAN_TEST_MATRIX.md) Section 19. Every finding tagged by category:

1. **`verification`** — pass/fail of a functional check
2. **`gap_found`** — feature absent, should exist
3. **`ui_quality_finding`** — feature exists but UI broken / inconsistent / off-brand. Severity tagged.
4. **`persistence_finding`** — saves don't survive lifecycle. Auto-flag as ≥ major severity.

Subagent returns `findings: []` array with all 4 categories mixed + `discipline_coverage` field showing which checks ran.

Critical / major persistence findings = auto-fix candidates for the overnight run. UI quality batchable into per-wave commits. Gaps → `HOMEOWNER_GAPS.md`.

---

## 24. Reset between runs

```sh
# Wipe homeowner test artefacts
/opt/homebrew/opt/postgresql@16/bin/psql "postgresql://..." -c "SET ROLE postgres;" -f /Users/tomburke/Projects/Housing-Manager/Tests/e2e/cleanup.sql

# Reinstall app
xcrun simctl uninstall <UDID> com.havenhome.app
xcrun simctl install <UDID> /path/to/Chez.app
xcrun simctl privacy <UDID> reset all com.havenhome.app

# Optional — re-seed library if subagents reference seeds
E2E_FIXTURE_LIBRARY=1 node Tests/e2e/run.mjs
```

Test users follow `e2e-ui-{wave}-{scenario}-{timestamp}@havenhome.test`.
Seed library users follow `e2e-{purpose}-${TS}@havenhome.test`.

---

## 25. Execution priority

The matrix is large (~575 rows + Section 22 discipline applied to every row).

**Round A — MUST DO (the pending-from-prior-runs commitments, 6-8 hours):**

These are the items the "⚠️ MUST address" callout at the top of this matrix flags. None are optional. The 9 deferred subagents from the original overnight run + the 5 bug re-verifications + the 36 Round B combinatorial rows together represent ~3 prior commits worth of "we'll get to this later." Round A IS getting to it.

1. **Section 1 (all 5 bug re-verifications).** 1-2 subagents covering 1a-1e.
2. **Section 2 (all 9 deferred / aborted subagents).** 9 subagents — one per subsection 2a-2i. **Including the W2S7 retry that aborted at 32MB last time** (this time it gets a tighter scope per the lessons learned).
3. **Section 3 (36 Round B backend combinatorial rows).** 1 subagent (or main thread) extending `run.mjs`. Cheapest line items in the matrix.
4. **Section 14 (Settings sub-screens).** 1 subagent — verify the navy tint propagated everywhere.
5. **Section 19 (Dashboard quick actions + interactions).** 1 subagent.

Do not start Round B until Round A is signed off. Every Round A item that surfaces a bug must be fixed in-session and re-verified before moving on.

**Round B — backend combinatorial (1-2 hours):**

5. Section 3 — extend `run.mjs` with all per-question variants. 1 backend subagent (or main thread directly).

**Round C — high-coverage post-onboarding surfaces (8-12 hours):**

6. Section 4 — document pipeline. 2 subagents.
7. Section 5 — invoice processing. 1 subagent.
8. Section 6 — email forwarding pipeline. 2 subagents.
9. Section 7 — maintenance task detail. 1 subagent.
10. Section 8 — family members + home manager. 2 subagents.
11. Section 10 — vehicle management. 2 subagents.
12. Section 11 — property detail sub-tabs (each subsection 1 subagent). 8 subagents.
13. Section 13 — Chez full concierge flow. 2 subagents.

**Round D — secondary surfaces (2-4 hours):**

14. Section 2d-2i — vendor coverage sweep, delegation, add/edit vendor, Chez delegation, routines. 4 subagents.
15. Section 9 — trusted contacts. 1 subagent.
16. Section 16 — calendar sync. 1 subagent.
17. Section 17 — vault lock + biometric. 1 subagent.
18. Section 18 — estate intelligence absence. 1 subagent.
19. Section 20 — find local vendors. 1 subagent.

**Round E — cross-app integration (3-4 hours):**

20. Section 21 — 12 round trips. Best done after handyman + contractor passes have run so both sides are working. 4 subagents.

**Round F — design + accessibility audit (2 hours):**

21. Section 22 categories B + H sweep across every visited screen. 2 subagents.

**Total estimate**: 35-50 subagents over 20-30 hours wall-clock. Realistic split: 2-3 overnight runs of 8-10 hours each.

---

## 26. What's NOT in this matrix (deliberately deferred)

- **Stripe payment processing** — separate testing surface
- **Real Apple Sign In** — needs real Apple ID, manual QA only
- **Real camera tests** — VIN scan, document scanner, photo capture — manual QA only (mock with sample images for automated runs)
- **Production push notification delivery** — APNs requires real device, not sim
- **Real Google Calendar OAuth** — needs Google account interaction, manual QA
- **Real ATTOM API quota / failures** — out of scope; we trust ATTOM mock responses
- **Real-time multi-device sync verification at scale** — needs multiple physical devices
- **Performance benchmarking under real load** — needs actual user device, not sim
- **Localization beyond US English** — out of scope for v1
- **Watch / iPad layouts** — orientation-locked to portrait iPhone for now
- **Background sync / silent push** — out of scope; tested via foreground only

These all matter eventually but would dilute focused passes.

---

## 27. Kickoff prompt

Use the same template as the handyman + contractor matrices. The kickoff prompt should:

1. Read `Tests/e2e/HOMEOWNER_COMPLETE_TEST_MATRIX.md` first
2. Read `OVERNIGHT_E2E_REPORT.md` for the precedent
3. Set up infrastructure (SETUP.md template at `/tmp/ui-test/HOMEOWNER_COMPLETE_SETUP.md`)
4. Build seed library via `E2E_FIXTURE_LIBRARY=1 node Tests/e2e/run.mjs`
5. Spawn waves per Section 25
6. Aggregate findings into `HOMEOWNER_GAPS.md`
7. Final report at `HOMEOWNER_COMPLETE_OVERNIGHT_E2E_REPORT.md`

Apply the same per-scenario discipline (Section 22) and finding categorization (Section 23) as the handyman + contractor passes.
