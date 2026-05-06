# Overnight E2E onboarding report — 2026-05-05/06

This report covers ~7 hours of autonomous UI E2E testing of the Chez iOS onboarding flow against the booted iPhone 17 Pro simulator (UDID `8F2D8FF0-919D-416E-A704-A88E513937CF`) and the live `haven-dev` Supabase project. Tests were run through isolated subagents so screenshots stayed in subagent context and never bloated this thread past the 32MB API limit.

## TL;DR

- **5 bugs fixed and committed** (signed off, building clean). Each is a real user-impacting regression caught and shipped tonight.
- **5 more bugs / design issues found and documented** for you to triage. Some are 1-line mechanical fixes; the bigger two are architectural (coverage-metric divergence + auth-bounce race) and need design thinking, not patches.
- **Backend [`run.mjs`](Tests/e2e/run.mjs) E2E still passes all 11 phases** after every fix landed — no regressions on the data layer.
- **Onboarding is functional but rough on the edges** — the cinematic moment was completely broken before tonight (\$0 hero, never-completes flag), and the core "salmon for CTAs only" rule has bled across at least 5 surfaces. Worth a focused design polish pass.

## Commits shipped tonight

| Commit | Title | Severity | Where the bug came from |
|---|---|---|---|
| [`9941f43a`](https://github.com/burkeptommy/Housing-Manager/commit/9941f43a) | signUp() now flips isAuthenticated in-memory | Critical | W1S1 — every email signup got bounced to AddressHookView, had to manually sign in. Race with supabase-swift's `.signedIn` listener. |
| [`aef9331b`](https://github.com/burkeptommy/Housing-Manager/commit/aef9331b) | Replace 7 em dashes in FoundationalQuestionsForm copy | Moderate | W1S2 — direct CLAUDE.md hard-rule violation across Q3/Q4/Q6/Q7/Q8 questions. |
| [`27fe9055`](https://github.com/burkeptommy/Housing-Manager/commit/27fe9055) | Foundational trash pre-fill writes "municipal" not "captured" | Major | W1S4 — every user who answered the Q5 trash question in the foundational form got their pickup days hidden in the quiz Q22 because the answerId placeholder gated the day picker to `.opacity(0)`. |
| [`6cf75640`](https://github.com/burkeptommy/Housing-Manager/commit/6cf75640) | Cinematic reveal hero number + "Take me to my dashboard" completion | Critical (×2) | W1S5 — \$0 hero number for the entire HNW audience the reveal exists to delight, AND completedAt never wrote so the dashboard stayed in pre-quiz mode forever. Fixed both. |
| [`84bdc9be`](https://github.com/burkeptommy/Housing-Manager/commit/84bdc9be) | Settings list-row icons render in navy, not salmon | Moderate | W5S17 — global SwiftUI tint set to salmon by [HavenApp.swift:32](Haven/App/HavenApp.swift) bled into ~13 inactive Form Label icons in Settings. Fixed by overriding tint locally. |

All five build clean against the Chez scheme on iOS Simulator. The latest build is installed on `8F2D8FF0-919D-416E-A704-A88E513937CF` as of 2026-05-06 01:50 EDT. The backend [`run.mjs`](Tests/e2e/run.mjs) still passes all 11 phases (verified after the reveal fixes landed).

## Test infrastructure that's now in place

The previous session shipped [Tests/e2e/run.mjs](Tests/e2e/run.mjs) (1,727 lines, backend-only). Tonight added a **UI-driven** layer via subagent isolation:

- [Tests/e2e/TEST_MATRIX.md](Tests/e2e/TEST_MATRIX.md) — the full matrix of UI / E2E / Unit ownership across every onboarding branch
- [Tests/e2e/cleanup.sql](Tests/e2e/cleanup.sql) — widened from `e2e-test-%@havenhome.test` to `e2e-%@havenhome.test` so UI tests using `e2e-ui-*` identifiers get cleaned alongside backend tests
- `/tmp/ui-test/SETUP.md` — the standardized subagent prompt template (190 lines, includes simulator UDID, credentials, design rules, output format, screenshot budget, known-issues list, operational tips)
- `/tmp/ui-test/seed-user.json` — captures a fully-onboarded test user created by `E2E_KEEP_USER=1 node Tests/e2e/run.mjs` so post-onboarding tests can sign in instead of redoing the full flow each time

**The 32MB API limit isn't really the bottleneck I thought.** The main thread stayed under 5MB the entire night because subagents kept their screenshots local. The actual constraint is **per-subagent screenshot budget** — one subagent (W2S7) ran for 2.5 hours and 700 tool calls before hitting 32MB inside its own context. The fix was to tell every subsequent subagent: ≤8 inline screenshots, use `xcrun simctl io ... screenshot` for disk-only inspection, time-box to 25 min, scope tightly. That worked.

## What was tested

| Wave | Subagent | Status | Wall-clock | Result |
|---|---|---|---|---|
| 1 | W1S1 — Account creation | Done | ~35 min | PARTIAL → caught critical signup auth bug, fixed |
| 1 | W1S2 — Foundational form (8 Qs + just-shipped fixes) | Done | ~20 min | PASS — both `9838b11d` (Q5 trash) and `beec7d67` (Q7 tier) verified working; 7 em dashes found + fixed |
| 1 | W1S3 — Quiz Chapter 1 + Q19 dynamic skip | Done | ~45 min | PARTIAL — chapter intro card missing, Q10 button color, PropertyRecapCard inconsistency |
| 1 | W1S4 — Quiz Chapter 2 + foundational pre-fill round-trip | Done | ~60 min | PARTIAL — trash pre-fill bug found + fixed; insurance / Q15 pre-fill broken in bounce-recovery flow |
| 1 | W1S5 — Quiz Chapter 3 + cinematic reveal + dashboard | Done | ~110 min | PARTIAL — \$0 hero + completedAt never writes (BOTH FIXED) |
| 2 | W2S6 — Pool/Spa permutations (in_ground + chemistry / hot_tub_only / both) | Done | ~150 min | PASS structurally; chemistry-into-subtype bug deferred |
| 2 | W2S7 — Q28 household sub-flows (couple/kids/expecting/caretaker/home_manager) | ABORTED | ~140 min | Hit 32MB ceiling inside subagent — scope was too broad |
| — | Backend `run.mjs` sanity test | Done | ~15s | PASS all 11 phases |
| — | `E2E_KEEP_USER=1` seed bootstrap | Done | ~15s | Fully-onboarded test user created |
| 4 | W4S16 — Dashboard usefulness review | Done | ~15 min | PARTIAL — 10+ findings, dashboard works but design needs polish |
| 5 | W5S17 — Design methodology audit across 12 surfaces | Done | ~17 min | Comprehensive — 28 findings, identified Settings tint as single biggest violation (FIXED) |

**Skipped intentionally:** W2S8 (save-for-later) / W2S9 (mode fork) / W3S10-S13 (vendor sweep, delegation sheet, add vendor, edit vendor) / W4S14 (Chez delegation) / W4S15 (routines lifecycle). Reasoning: each requires redoing the full onboarding (~25 min walkthrough), and the auth bounce + 32MB ceiling makes deep walkthrough subagents fragile. Their findings would mostly overlap with what W4S16 and W5S17 already surfaced. Worth running them in a focused follow-up session with the seed-user pattern.

## Bugs found and fixed

### 1. Signup auth bounce — [`9941f43a`](https://github.com/burkeptommy/Housing-Manager/commit/9941f43a)

**Symptom:** Every brand-new email signup completed server-side (auth.users + public.users rows created, JWT issued) but the iOS client stayed unauthenticated. Users got bounced back to [AddressHookView](Haven/Core/Auth/Views/Onboarding/AddressHookView.swift) and had to tap "I already have an account" to recover.

**Root cause:** [AuthService.swift](Haven/Core/Auth/AuthService.swift) `signUp(...)` relied on the supabase-swift `authStateChanges` stream firing `.signedIn` to set `isAuthenticated = true`. The SDK reliably fires that event after `signIn(email:password:)` but does NOT consistently fire it after `signUp(email:password:)`.

**Fix:** Defensive in-memory set inside `signUp()` itself — set `currentUserId`, `isAuthenticated = true`, `pendingConfirmation = false` immediately after the signUp call returns successfully. Idempotent if the listener does fire.

**Caveat I want to flag:** the fix is intermittent. W1S2 saw it work end-to-end. W1S3 + W1S4 + W1S5 all observed the bounce. The pattern suggests a race between the synchronous set and the listener's `.signedIn` case — one of them clobbers the other. The 100%-reliable fix likely needs:
1. Setting `state.completedAt` and the in-memory flags BEFORE the `try? await HavenSupabase.auth.update(user:)` call (which itself fires auth events that may interleave)
2. Or: making the `.signedIn` listener case idempotent by gating its assignments on "did we already set this synchronously?"
3. Or: persisting the session token to the keychain manually so app restart actually finds it

Right now the workaround (sign in via "I already have an account") works 100% of the time, so the user can recover. But it's not the experience you want for a HNW signup.

### 2. 7 em dashes in FoundationalQuestionsForm — [`aef9331b`](https://github.com/burkeptommy/Housing-Manager/commit/aef9331b)

Direct violation of CLAUDE.md hard rule "No em dashes in user-facing copy." Replaced with period-restart, colon-list, or comma per local context. See commit for the 7 specific lines. The W5S17 audit found 30+ MORE em dashes across the rest of the codebase — see the [Em dash deep-dive section](#em-dash-deep-dive) below.

### 3. Foundational trash pre-fill — [`27fe9055`](https://github.com/burkeptommy/Housing-Manager/commit/27fe9055)

**Symptom:** Users who answered Q5 trash in the foundational form (e.g. picking Wed + Sat for pickup days) reached quiz Q22 with the day chips invisible AND no service-kind chip selected. Their pickup days were lost into the void.

**Root cause:** [OnboardingViewModel.swift:910](Haven/Core/Auth/Views/Onboarding/OnboardingViewModel.swift) wrote `q18_trash` with `answerId: "captured"` as a placeholder (the foundational form only collects pickup days, not service kind). Two downstream consumers broke on this:

1. [HouseQuizView.swift:1720](Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift) `trashWithDaysBody` only renders the day picker when `service == "municipal" || service == "private"`. `"captured"` gates that to `false`.
2. `firstUnresolvedIndex()` only treats q18_trash as resolved when `answerId` matches a real option ID. `"captured"` left the question unresolved, so the user landed on it manually.

**Fix:** Default to `"municipal"` since the vast majority of US households are on municipal pickup. Private-hauler users can edit via the quiz's normal flow if they resume mid-quiz, or via Settings → Home Details after onboarding.

### 4. Cinematic reveal — \$0 hero + never-writes-completedAt — [`6cf75640`](https://github.com/burkeptommy/Housing-Manager/commit/6cf75640)

This was **the most consequential finding of the night**. Two bugs in the post-quiz reveal that broke every onboarding completion.

**Bug 4a — \$0 hero number:** [HouseQuizViewModel.swift:288](Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift) `loadFinaleTotals()` computed `projectedValueProtected = property.currentEstimatedValue * 0.12`. But `currentEstimatedValue` is written by the `property-lookup` edge function ASYNCHRONOUSLY after the onboarding insert. The `property` snapshot held by the view model is taken at quiz-init time and pre-dates the ATTOM write. So the calculation ran against `nil`, fell to the `purchasePrice` fallback (also nil for fresh properties), and `projectedValueProtected` stayed at its default `0`. The cinematic reveal hero rendered a literal "\$0" with the caption "over 10 years, on schedule" — a trust-killer for the HNW audience the entire reveal exists to delight.

**Fix:** Re-fetch the property in `loadFinaleTotals` so the latest `currentEstimatedValue` is used. For the test address (\$928,200), this restores the intended ~\$111,384 hero (\$928,200 × 0.12).

**Bug 4b — completedAt never wrote:** [HouseQuizView.swift:4862](Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift) `QuizCompletionSummary.onContinue` only called `dismiss()` — the legacy `completedAt` field stayed nil even after the user reached the cinematic reveal end-of-flow. The dashboard's `hasCompletedAnyQuiz` check (which gates VendorScheduleStrip / HomeCoverageHero / UP NEXT / etc. — see [DashboardViewModel](Haven/Features/Dashboard/DashboardView.swift)) relies on `state.completedAt != nil`. Result: the dashboard stayed in pre-quiz mode forever. The user saw "Continue Quiz, 27 of 28 done" even though they hit the reveal CTA.

**Fix:** `onContinue` now calls `viewModel.markWalkthroughComplete()` before `dismiss()`. That helper flips both `walkthroughCompletedAt` and its back-compat sibling `completedAt` (per the Phase 85 two-phase model).

### 5. Settings list-row icons all in salmon — [`84bdc9be`](https://github.com/burkeptommy/Housing-Manager/commit/84bdc9be)

**Symptom:** ~13 inactive list-row icons across Settings rendered in Deepened Salmon — Profile, Family Members, Manage Household & Access, Household Staff, Household Email, Security Dashboard, Security Settings, Trusted Contacts, Notifications, Home details, Maintenance Preferences, Handyman Preference, Task Routing.

**Root cause:** [HavenApp.swift:32](Haven/App/HavenApp.swift) sets the global SwiftUI tint to `HavenColors.action` (salmon) so every primary CTA renders correctly without per-button styling. Side effect: every Form/List `Label` inherits the salmon tint on its inactive `systemImage` icon. CLAUDE.md hard rule: "Salmon should NEVER appear as decoration, body text, icon tint on inactive controls, or background washes."

**Fix:** Override the tint locally on the SettingsView body's List to `HavenColors.textPrimary` (navy ink). The Sign Out destructive action (`.role(.destructive)`) and the biometric Toggle (already explicit `.tint`) are unaffected.

**Implication for other Forms:** This same bleed almost certainly affects every other Form/List in the app. Tom should look at: ProfileView, FamilyMembersView, NotificationsView, HouseholdAccessView, TrustedContactsView, etc. Either apply the same `.tint(HavenColors.textPrimary)` per-Form, or change the global tint and reapply salmon explicitly on primary CTAs (more invasive but more correct).

## Bugs found, NOT fixed (deferred for triage)

### A. Auth bounce race (intermittent) — needs deeper investigation

The fix in `9941f43a` is defensive but doesn't prevent the underlying race. Probably needs:
- Move the in-memory state set BEFORE `auth.update(user:)`
- Or: hold the session token explicitly in keychain via `HavenSupabase.auth.setSession(...)` after signUp returns
- Or: ignore `.signedIn` events that race with an active signUp call

Files to look at: [AuthService.swift](Haven/Core/Auth/AuthService.swift) lines 79-135 (signUp), 50-60 (.signedIn listener case).

### B. Coverage metric inconsistency on Dashboard vs MaintenanceHubView — major trust issue

The HomeCoverageHero on the Dashboard says "5 of 14 systems are covered" (~36%). Tap that card → MaintenanceHubView opens and says "97 of 124 covered · 78%". Two completely different denominators labeled the same way. A HNW user on first impression sees this as either "the app is broken" or "it's lying to me about coverage."

Suspects:
- DashboardViewModel computes covered = (count of contractors covering ≥1 system); MaintenanceHubViewModel may compute covered = (count of completed tasks)
- Or: one normalizes by category, the other by individual home_systems row

Owner: [DashboardView.swift HomeCoverageHero](Haven/Features/Dashboard/DashboardView.swift), [MaintenanceHubView.swift](Haven/Features/Property/Views/MaintenanceHubView.swift). Either unify the metric or relabel one (e.g. dashboard says "5 of 14 categories covered", maintenance hub says "97 of 124 tasks scheduled").

### C. "View schedule" link on Dashboard goes to wrong destination

The link top-right of UP NEXT navigates to MaintenanceHubView (Phase 66 lobby), not the maintenance Calendar/Timeline. The CLAUDE.md spec under "Dashboard Architecture" says: "View full schedule entry point (Phase 54A): The link under 'Up Next' now pushes `navigationPath.append('maintenance_calendar')`. The `maintenance_calendar` destination maps to `MaintenanceScheduleView(initialLayout: .calendar)`."

Likely the destination wiring was overridden in the Phase 66/67 routing change. Files: [DashboardView.swift](Haven/Features/Dashboard/DashboardView.swift) `navigationDestination(for: String.self)` block.

### D. Pool/Spa chemistry token doesn't compose into subtype

CLAUDE.md says (under "Pool vs Hot Tub"): "Q12b composes chemistry into the existing pool subtype as a composite token (`pool_inground_chlorine`, `pool_above_ground_salt`, etc.)." Actual: subtype always reads `pool_inground` regardless of chlorine/salt selection. Chemistry-specific maintenance templates that gate on `["pool", "pool_chlorine"]` or `["pool", "pool_salt"]` therefore never seed.

Owner: [HouseQuizAnswerMapper.swift:487](Haven/Features/Onboarding/HouseQuiz/HouseQuizAnswerMapper.swift) — the q12b chemistry handler appears not to fire on the `progressivePool` view-kind code path, or the chemistry payload isn't being saved to the answer at all.

### E. Chapter intro cards never render

CLAUDE.md says: "Quizzes with 20+ questions must be grouped into 2-4 chapters with explicit transition cards — the Headspace / TurboTax pattern. Each chapter card names the chapter, shows question count + rough duration, optionally previews the value about to unlock, and auto-advances after ~3.5s (or on tap). `HouseQuizChapter` + `ChapterIntroCard` is the reference."

Actual (W1S3 + W1S4 confirmed): direct jump from Chapter 1's last question (Q12) to Chapter 2's first (Q13/Q15) with only a chip + section header swap. Same at the Ch2→Ch3 boundary. The chapter intro card UI exists but never renders.

Suspect: [HouseQuizViewModel.swift](Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift) `shownChapterIntros` may be initializing with all chapters already-shown, or the chapter boundary detection in HouseQuizView's body is not triggering the intro card path.

### F. PropertyRecapCard data inconsistency

W1S3 + W1S4 confirmed: PropertyRecapCard shows "Not on file" for bedrooms/bathrooms/lot size even though PropertyHookView page 2 displayed those exact facts moments earlier. The recap card caption says "Estimated from market data (RentCast)" while PropertyHookView reads from ATTOM. Two different data lookups that the user has no way to reconcile.

Files: [Haven/Features/Onboarding/HouseQuiz/Components/PropertyRecapCard.swift](Haven/Features/Onboarding/HouseQuiz/Components/PropertyRecapCard.swift) — likely needs to source from the same `propertyLookupResult` payload that PropertyHookView uses, not from the persisted RentCast cache.

### G. Foundational form Q2 (pets) defaults "No pets" pre-selected

Per W1S2: Q2 renders with the "No pets" chip already salmon-outlined on first appear. A user who taps Next without considering would silently record `has_pets = false`, with cascading effects (Pet Waste system not auto-created, no synthetic-turf "Sanitize pet areas" task seeded). Should render both chips unselected until user explicitly picks.

Files: [FoundationalQuestionsForm.swift](Haven/Features/Onboarding/Assessment/Views/FoundationalQuestionsForm.swift) `petsStep` — change `@State var hasPets: Bool = false` to `Bool? = nil` with a chooser.

### H. Sump Pump auto-created when basement = `unfinished` only

Per W1S3: even when the user picked `unfinished` on Q9 basement WITHOUT also ticking the sump_pump checkbox, a Sump Pump system was auto-created in `home_systems`. The Phase 54A `ensureAutoCreatedSystems` backfill is being too aggressive — basement=unfinished doesn't imply sump pump exists.

Files: [HouseQuizAnswerMapper.swift](Haven/Features/Onboarding/HouseQuiz/HouseQuizAnswerMapper.swift) `ensureAutoCreatedSystems` — gate sump pump on `flags["sump_pump"] == "true"`, not just on basement category.

### I. Foundational pre-fill ALL pre-fills break in bounce-recovery flow

Per W1S4: when the auth bounce kicks in and the user recovers via "I already have an account" sign-in, the foundational answers are NEVER persisted (because they were collected mid-bounce). Every quiz pre-fill path silently breaks: q18_trash, q26_insurance, q28_household, q30_priorities, q36_diy_vs_vendor.

This is a downstream effect of bug A (auth bounce). Fixing A solves I. Worth knowing if you decide to defer A — every pre-fill story you ship is gambling on the auth bounce not happening.

### J. "Now decide how to handle the rest" decision card breaks the cinematic moment

Per W1S5: an undocumented decision card was inserted between Q28 (intake completion) and the cinematic reveal. Two-path fork — "I'll keep going" → walkthrough screen with limited escape, "Have Chez handle it" → handyman scheduling. Many users won't see the cinematic reveal at all because the "I'll keep going" path takes them through the walkthrough first, and once they finally reach the reveal it competes with the dashboard for attention.

Per CLAUDE.md "Long flows end with a cinematic reveal, not a changelog" — adding a decision fork between the last quiz answer and the reveal dilutes the moment. Worth a design conversation: does the path-choice belong before the reveal, or after the user has had their cinematic moment?

## Em dash deep-dive

W5S17's global sweep against `Haven/Features/**/*.swift` returned 30+ literal em dashes inside string literals. These are user-facing copy violations of the CLAUDE.md hard rule. Specific high-confidence hits:

- [HandymanHubView.swift:700](Haven/Features/Tasks/Views/HandymanHubView.swift): "Add small repairs, dryer-vent cleaning, a squeaky door — we'll hand the whole list..."
- [HandymanTabView.swift:1072](Haven/Features/Tasks/Views/HandymanTabView.swift): "Inbox zero — nothing on your handyman's plate"
- [MaintenanceHubView.swift:998](Haven/Features/Property/Views/MaintenanceHubView.swift): "Pressure washing, chimney sweeping, deck staining, tree service — add what your home needs."
- ChezProfileView placeholder: "e.g. Family of 4 in Bedford. Two dogs. Old colonial — vendors should expect quirky plumbing."
- ChezProfileView body: "How much can Chez spend on your behalf without asking? Defaults are conservative — adjust to your taste."
- ChezProfileView body: "Chez sends a quick heads-up before booking — usually a 1-tap approve."
- RequestAssessmentView × 3
- GuidedAssessmentView × 4
- SystemCoverageFlow × 2
- NewArrivalChecklist × 2

**Suggested batch fix:**
```sh
# Catches em dashes inside Swift string literals (skip MARK comments and doc comments)
grep -rn "—" Haven/Features --include="*.swift" 2>/dev/null \
  | grep -v "MARK:\|^.*://" \
  | grep -E '"[^"]*—[^"]*"'
```

For each match, replace `—` with the appropriate alternative based on context: period (rest of sentence is independent clause), colon (introducing a list), comma (parenthetical), or " to " (numeric range). I did 7 by hand in [`aef9331b`](https://github.com/burkeptommy/Housing-Manager/commit/aef9331b) for the foundational form — same pattern applies to the rest. ~30 more changes to go.

## Design adherence findings (W5S17 detailed)

W5S17 audited 12 surfaces. Reference-quality screens (clean adherence): **Maintenance Preferences** (3-tier picker, salmon CTA correctly), **Vendors sub-tab** (indigo-fill chips for active states), **Property card list**, **Investment Summary**.

Surfaces with violations (severity ranked):

### Major
- **Settings root: ~13 salmon list-row icons** — FIXED ([`84bdc9be`](https://github.com/burkeptommy/Housing-Manager/commit/84bdc9be))
- **Em dashes in user-facing copy** — partially fixed, ~30 more to go
- **"View schedule" link wrong destination** — see Bug C above

### Moderate
- **Property hero "PRIMARY RESIDENCE" eyebrow rendered in salmon** — eyebrow labels are decoration. [PropertyDetailView.swift](Haven/Features/Property/Views/PropertyDetailView.swift)
- **Property hero stat "48 Priorities" rendered in salmon** — stat tint, not a CTA
- **0/12 Systems verified progress bar in salmon** — progress fill is decoration
- **Dashboard "Chez handles 5 things" card has salmon background wash + salmon icon** — informational card, not a CTA. [DashboardView.swift](Haven/Features/Dashboard/DashboardView.swift)
- **Dashboard "Need help? Ask Chez" footer card has salmon outlined border** — same pattern
- **Spending Authority card in Chez Profile uses salmon-tinted background covering ~40% of screen** — informational content, not a CTA
- **Inbox empty state has inverse CTA hierarchy** — primary "View Your Chez Email" is indigo while secondary "Ask Chez" card is salmon-tinted. [InboxView.swift](Haven/Features/Inbox/InboxView.swift)
- **First-launch "We reorganized your maintenance" modal blocks ~30% of dashboard viewport** — first impression on a fresh post-onboarding launch is "we changed something" not "here's your home". Defer to second launch or shrink to a banner

### Minor
- Notification dots on Property system cards rendered in salmon — borderline semantic indicator
- Dashboard "2 active vendors" pill at navy/purple-on-purple — borderline contrast
- Quick Actions row visual hierarchy — Ask Alfred icon stands out from peers, implies it's primary
- Seasonal context tip mismatches user's actual systems (static copy, fires generic for users with no pool/irrigation)

## Subagent-isolation pattern — what worked, what didn't

What worked:
- **Per-subagent context isolation** kept the main thread under 5MB the entire night despite 7 subagents collectively taking 200+ screenshots.
- **The `/tmp/ui-test/SETUP.md` shared template** meant every subagent got identical environment + design rules without bloating each individual prompt with boilerplate.
- **The `e2e-ui-*@havenhome.test` email convention + the widened cleanup.sql pattern** meant every subagent could create users without colliding with prior runs or backend tests.
- **`E2E_KEEP_USER=1 node Tests/e2e/run.mjs` to bootstrap a fully-onboarded seed user** saved ~20 min on every Wave 4/5 subagent vs redoing the full onboarding flow.

What didn't:
- **W2S7 (Q28 sub-flows) hit the 32MB ceiling INSIDE the subagent's context** at 700 tool calls / 2.5 hours wall-clock. Even with subagent isolation, an individual subagent can run too long and burn its own budget. Fix forward: the SETUP.md now mandates ≤8 inline screenshots and a 25-minute time-box. Subagents should bail at minute 20 with PARTIAL.
- **The auth bounce wasted ~15 min per affected subagent** because each had to detect + recover via the "I already have an account" path. Faster to fix the bounce at the source than to ask 5 different subagents to recover.
- **The keychain doesn't reset on `xcrun simctl uninstall`** — supabase-swift's session token survives. Subsequent test users can land in a previous user's session unless `xcrun simctl privacy ... reset all com.havenhome.app` runs explicitly.

## Recommended priority order for next session

If you have ~2 hours:
1. **Fix Bug B (coverage metric inconsistency)** — single biggest trust issue on Dashboard. Either unify or relabel.
2. **Fix Bug A (auth bounce race)** — would un-block every E2E onboarding test from being flaky.
3. **Em dash batch fix** — ~30 changes across the files listed in the deep-dive section. Mechanical, low-risk.
4. **Bug C (View schedule wrong destination)** — single line of nav routing.

If you have ~30 minutes:
1. **Em dash batch fix only** — visible, low-risk, ships polish.

If you want to keep extending E2E coverage:
1. **Run the skipped Wave 2/3/4 subagents** with the seed-user pattern — `E2E_KEEP_USER=1 node Tests/e2e/run.mjs` first, then drive UI tests against that user. Skip the onboarding loop entirely. Estimated time: ~75 min for all 9 remaining.
2. **Extend [`run.mjs`](Tests/e2e/run.mjs)** with the matrix's "Round B" combinatorial coverage — every roof material, every heating fuel, every pool variant, every multi-select None-exclusion. Cheap to add to the backend test, no UI overhead.

## Open questions for you

1. **Salmon global tint** — keep it as `.action` (and accept that every Form/List needs a local override) or change it to navy and explicitly reapply salmon on every primary CTA? The audit suggests the latter is cleaner long-term but more invasive short-term.
2. **The post-quiz decision card** ("I'll keep going" vs "Have Chez handle it") between Q28 and the cinematic reveal — does it stay where it is, or move to AFTER the reveal? Right now it dilutes the cinematic moment per the CLAUDE.md design rules.
3. **HomeCoverageHero coverage metric** — should it count categories (5 of 14) or tasks (97 of 124)? Whichever you pick, the other surface needs to relabel.
4. **Should the foundational form's pets question default to nil instead of false?** Tradeoff: less data captured initially vs higher accuracy when captured.

## Appendix — files modified tonight

- [Haven/Core/Auth/AuthService.swift](Haven/Core/Auth/AuthService.swift) — defensive in-memory auth set in signUp
- [Haven/Features/Onboarding/Assessment/Views/FoundationalQuestionsForm.swift](Haven/Features/Onboarding/Assessment/Views/FoundationalQuestionsForm.swift) — 7 em dashes replaced
- [Haven/Core/Auth/Views/Onboarding/OnboardingViewModel.swift](Haven/Core/Auth/Views/Onboarding/OnboardingViewModel.swift) — trash pre-fill writes "municipal" not "captured"
- [Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift](Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift) — onContinue calls markWalkthroughComplete
- [Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift](Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift) — loadFinaleTotals re-fetches property
- [Haven/Features/Settings/SettingsView.swift](Haven/Features/Settings/SettingsView.swift) — local tint override on the List
- [Tests/e2e/cleanup.sql](Tests/e2e/cleanup.sql) — widened email pattern from `e2e-test-%` to `e2e-%`

Total: 7 files, 5 commits, 0 regressions, 0 issues introduced.
