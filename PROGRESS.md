# Haven -- Development Progress

This file tracks session-by-session development history. Claude Code reads this at the start of each session to understand recent work and appends a summary at the end.

**Self-compaction rule:** If this file has more than 15 detailed entries, compress all entries older than the most recent 5 into single-line summaries at the top.

> _Compaction overdue — currently 20+ detailed entries. A future session should fold the older ones into the Completed Phases (Compressed) section at the bottom._

---

## Friend Feedback Rounds 1 + 2: 13 fixes from TestFlight walkthrough (2026-05-17)

Tom's friend walked through the latest TestFlight build and sent two rounds of feedback (5 + 9 items). Items 1 + 2 from Round 1 were already shipped — the rest landed in this session.

### Round 1 (4 items shipped)
- **Item 7 — Air filter ghost predicate.** [MaintenanceScheduleView.swift:1378-1397](Haven/Features/Property/Views/MaintenanceScheduleView.swift:1378) `personalBucketTasks` now hides recurring tasks with `lastCompletedDate != nil AND nextDueDate > today + 14d` (unless an explicit stats pill is active). Completed monthly tasks no longer reappear in "To Schedule" at their newly-scheduled future date.
- **Item 3 — Valuation provenance disclosure.** [InvestmentSummaryCard.swift](Haven/Features/Property/Components/InvestmentSummaryCard.swift) gained a `questionmark.circle` icon next to non-manual value sources. Tap → explainer sheet covering ATTOM (primary) + RentCast (fallback) + why Zillow/Redfin can differ.
- **Item 5 — Security reassurance card.** New [SecurityReassuranceCard.swift](Haven/Features/Onboarding/HouseQuiz/Components/SecurityReassuranceCard.swift), navy gradient hero mirroring `PropertyRecapCard`. Fires before the first upload tile tap in the quiz, gated by UserDefaults `hasSeenQuizSecurityReassurance`. On dismiss, the document upload sheet chains in via the existing `pendingUploadAfterSecurity` pattern.
- **Item 4 — "Why we ask" affordance.** Optional `whyAsked: String?` field on `HouseQuizQuestion`; renders an `info.circle` icon next to the title that opens a medium-detent sheet. Populated on 13 of ~28 questions where the purpose isn't already self-evident (q3 heating, q6 water, q7 sewer, q11 lawn, q12 pool, q15b contractors, q19 heating provider, q22 generator, q24 vehicle, q26 insurance, q28 household, q30 priorities, q36 vendor preference).

Round 1 Item 6 (dashboard density) deferred — friend said "let me think on it" and never sent specifics. Round 1 Items 1 + 2 already fixed before this session (commits `3a8a6307` + Build 86).

### Round 2 (9 items shipped)
1. **Vehicle Skip on the 8-step foundational form.** [FoundationalQuestionsForm.swift](Haven/Features/Onboarding/Assessment/Views/FoundationalQuestionsForm.swift) renders a tertiary Skip button under "Add a vehicle" when the vehicle list is empty. New `vehiclesSkipped: Bool?` field on `FoundationalAnswers` records the explicit intent; new `foundationalVehiclesSkipped` analytics event captures drop-off.
2. **Quiz auto-advance speed.** Split [HouseQuizViewModel.persist](Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift) into a synchronous Phase A (local state update) + a detached Phase B (`applyAnswerBackgroundWork` — mapper + JSONB persist + completion reconciler). Caller returns instantly; the network write runs in parallel. Visual-feedback sleeps dropped from 350ms → 150ms. Threading note: `Task {}` (not `.detached`) so the @MainActor view model's state mutations stay serialized.
3. **Termite bond removed from Q13.** [HouseQuizQuestionLibrary.swift](Haven/Features/Onboarding/HouseQuiz/HouseQuizQuestionLibrary.swift) Q13 — dropped the chip + `providerFollowUpAnswerIds` entry. Mapper's defensive clause stays so legacy `termite_bond` saved-for-later state round-trips.
4. **Handyman card date + calendar reschedule.** [HomeAssessmentPendingCard.swift](Haven/Features/Dashboard/Components/HomeAssessmentPendingCard.swift) renders `assessment.scheduledAt` when present ("Scheduled for Saturday, May 24."). When `.pending` with no scheduledAt, the subtitle now reads "Usually within 3 business days." instead of silently leaving the user wondering. [AssessmentRescheduleSheet](Haven/Features/Dashboard/Components/HomeAssessmentSheets.swift) replaced its text-only body with a primary date picker + optional backup date picker + notes field; submits `preferredDates: [String]` to the existing endpoint.
5. **"28 of 28 done · 1 saved for later" math.** [DashboardView.swift](Haven/Features/Dashboard/DashboardView.swift) `houseQuizHeroCard` — `answered = max(0, state.answers.count - saved)` so the label can't read "28 of 28 done" while a saved-for-later question is still parked. Now shows "27 of 28 answered · 1 saved for later."
6. **Vendor Coverage "Circle back" snooze.** New migration [20261318_dismissed_categories_snooze.sql](supabase/migrations/20261318_dismissed_categories_snooze.sql) adds `snoozed_until TIMESTAMPTZ`. [DismissedCategoryRow](Haven/Core/Networking/DatabaseModels.swift) gained the field + a resilient decoder + `isActiveSnooze(now:)` helper. New `DatabaseService.snoozeCategory(until:)` (delete-then-insert to avoid duplicates). [VendorCoverageSheet](Haven/Features/Dashboard/Components/VendorCoverageSheet.swift) added a "Remind me later" button alongside "Not applicable"; tap opens a confirmation dialog with 3/6/12/36-month options. [DashboardViewModel](Haven/Features/Dashboard/DashboardViewModel.swift) filters expired snoozes from the gap-suppression set so categories resurface automatically.
7. **Dynamic seasonal tip.** [DashboardViewModel.seasonalContextTip](Haven/Features/Dashboard/DashboardViewModel.swift:135) restructured from raw strings into `(category, copy)` tuples per month, filtered against `homeSystems`. Pool/Irrigation/HVAC/Snow/etc. lines only show when the user has the matching system. Returns nil when every line is filtered.
8. **Document upload pipeline gap.** New shared helper [InboxItemFromDocument.swift](Haven/Core/Services/InboxItemFromDocument.swift) — single source of truth for the category → inbox-item mapping (Contractor Quote / Repair Estimate / Auto Insurance / Vehicle Title / invoices). Both [DocumentUploadViewModel.swift](Haven/Features/Documents/ViewModels/DocumentUploadViewModel.swift) (foreground sheet — single + batch) and [DocumentUploadManager.swift](Haven/Core/Services/DocumentUploadManager.swift) (background batch) now route through the helper. Silent `try?` dropped — failures log to console. Property → Documents tab uploads finally surface needs-action prompts in the inbox the way email forwards always have.
9. **Alfred concierge tool.** **Phase 9a:** [chat/index.ts](supabase/functions/chat/index.ts) system prompt updated so Alfred no longer hallucinates "I'll create a case." **Phase 9b:** [ai-cost-discipline.ts](supabase/functions/_shared/ai-cost-discipline.ts) extended with optional `tools` + returns `content_blocks` + `stop_reason`. [chat/index.ts](supabase/functions/chat/index.ts) defines a single `submit_concierge_request` tool and runs a 3-iteration agentic loop: text → tool_use → execute (POST to `chez-concierge` with the user's JWT) → tool_result → final text. Forward auth preserves every existing side effect (admin push, SendGrid backstop, RLS, inbox routing).

### Infrastructure changes
- **PRODUCT_NAME** is `Chez` on the Haven target (already in place). HavenTests' `@testable import Haven` requires `PRODUCT_MODULE_NAME = Haven` to compile under the renamed product — pre-existing breakage in the test target surfaces if you wire `test` action on the Chez scheme. Pinning PRODUCT_MODULE_NAME would fix all existing test imports; not done in this session because the existing tests also have unrelated compile errors that would need cleanup. The new [FriendFeedbackRound2Tests.swift](HavenTests/FriendFeedbackRound2Tests.swift) is staged for the inevitable test-infra cleanup pass.

### What's still open
- Round 1 Item 6 (dashboard density) — waiting on friend's specifics.
- Round 1 Item 4 — `whyAsked` populated on 13 of ~28 questions; remaining ~15 are mostly self-explanatory but could be done iteratively.
- HavenTests target-wide compile cleanup so the test action runs (existing tests have nil-context and missing-argument errors unrelated to my changes).
- Alfred Phase 9b TestFlight verification — only exercise will reveal whether the tool_use round-trips correctly under real Anthropic + chez-concierge auth.

## CI Fix: DashboardView type-checker timeout (2026-05-05)

The `Admin Apply Validate` workflow had been failing on every push to `claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG` (latest run [25410326911](https://github.com/burkeptommy/Housing-Manager/actions/runs/25410326911), exit code 65). Root cause: `DashboardView.swift:83` triggered Swift's "the compiler is unable to type-check this expression in reasonable time" error. The dashboard's `body` was a single ~400-line expression with skeleton placeholders + ~30 conditional branches. Apple-silicon Xcode chewed through it; the macos-15 GitHub runner blew the type-checker's budget.

**Fix:** extracted the body's `else` branch (the post-loading content) into a `@ViewBuilder private var dashboardContent: some View` computed property. The body is now a small `if isLoading { skeletons } else { dashboardContent }` gate, and the type-checker has two smaller expressions to chew on instead of one giant one.

Mechanics in [scripts/extract_dashboard_content.py](scripts/extract_dashboard_content.py) — idempotent, bails if `dashboardContent` already exists. Verified locally with the same xcodebuild invocation CI uses: `xcodebuild -scheme Chez -destination "generic/platform=iOS Simulator" -configuration Debug build`. Diff is +409/-394 (extracted 394 lines, added a 410-line property with docstring + closing brace).

Pattern for next time the runner trips this: SwiftUI bodies that exceed ~300 lines of `if`/`ForEach` branches inside a single `VStack` should be split into one or more `@ViewBuilder` properties. The runner's type-checker timeout is noticeably tighter than Apple silicon's.

Side observations from the run logs (not failing today, worth tracking):
- Node 20 deprecation warning on `actions/checkout@v4` + `actions/setup-node@v4` (forced to Node 24 from June 2nd, 2026 — bump action versions when a maintenance window opens).
- `SUPABASE_SERVICE_ROLE_KEY` secret unset → "Post validation status to Supabase" step skips the post-back to flag `admin_codex_notes` rows. Workflow handles this gracefully via `exit 0` warning.

## Phase 83: Concierge Cockpit — 4-pane customer service desktop (2026-05-01)

Tom asked us to turn the "Chez Requests" admin tab into a real customer-service cockpit per a fresh design handoff. The deliverable: not just UI — every button, click, and step has to be wired end-to-end.

The replacement is a fixed-viewport desktop workspace:

```
┌─ TopBar (52px) — brand wordmark · search · vendor + Alfred toggles · agent
├─ Queue (304px) — tabs (All/Mine/Urgent), 4 stat tiles, case list w/ SLA pills, Alfred queue tip
├─ Homeowner (320px) — profile card, family, systems w/ active-case highlight, vendors, routines, notes
├─ Case workspace (flex:1) — case header, AI brief (5 tabs in indigo gradient hero), stage tracker, active visits, vendor sheet, conversation, composer
└─ Alfred sidebar (360px) — 3 tabs (Suggested actions / Ask Alfred / Similar cases), pill composer
```

**Tab rename:** "Chez Requests" → **"Concierge"** in the sidebar. Internal route id stays `"chez"` (referenced in dozens of places), so legacy callers keep working.

**Reactive shell:** legacy `renderChezRequestsView` and `renderFocusedChezDetail` are now thin shims that delegate to `renderConciergeCockpit`. Every existing callback (proposal builder, analysis cache, visits cache, dossier drawer, package & send, status transitions) keeps working without modification — they all end up triggering a re-render of the cockpit, which idempotently re-paints the entire 4-pane shell.

**State:** `state.concierge.{ ui, queueFilter, searchQuery, briefTab, composer, alfred }`. Alfred on/off + density persist to localStorage; everything per-case is keyed by `request_id` so switching between cases preserves the operator's draft + sidebar tab + brief tab.

**Wiring (every button has real plumbing):**
- Top bar — search filters queue live, vendor/Alfred toggles persist, refresh re-runs `loadAdminData`
- Queue — All/Mine/Urgent tabs, case row click loads thread + visits, queue tip click swaps active case
- Homeowner panel — profile chips and dossier rows route through the existing `openDossierDrawer`
- Case header — Reassign (single-agent v1, alerts), Snooze (prompts hours, transitions to waiting_customer with system message), Mark resolved / Reopen (existing transition)
- AI brief — 5 tabs (Analysis / Considerations / Recommended approach / Questions / Call script), Re-run forces fresh analysis
- Vendor sheet — expandable call forms, slot inputs, cost combobox + custom row, ✨ Summarize from notes (existing `suggest_vendor_framing`), Recommend toggle drives the proposal preview, "Send to homeowner" → `packageAndSendRecommendedVendors`, Find more → `find-local-vendors` merged into cache
- Conversation — Summarize thread → `analyze_request`, composer Draft from brief seeds tone-aware template, tone toggle (warm/direct/formal) re-renders critique + draft, Send · keep open / Send · waiting on customer use the existing reply path with optional `to_status`
- Quick actions row — Manual proposal opens the existing builder, status transitions are direct
- Alfred sidebar — Resolve this case (adapts plan to case state: open builder if recommendations exist, expand top vendor's call form if candidates exist, run analysis if not), Quick Actions list, Context I'm using card; Ask Alfred chat backed by new `ask_alfred` Edge Function action; Similar cases uses `past_requests` from the dossier with a pattern card; suggested prompts set the input and immediately send
- Visit cards — carry over from Phase 82, Confirm scheduled / Mark completed / Cancel, slot adoption chips, optional reply text

**New Edge Function action:** `ask_alfred` (Phase 83). Single-shot, case-scoped Q&A. Loads request + dossier + thread + recent messages + past requests on the server, asks Claude sonnet 4.6 with a system prompt that constrains voice and rules (concise, reference specific facts, defer to licensed pros on legal/code/insurance, never invent data). Multi-turn deferred until usage shows the shape of useful follow-ups.

**Deterministic AI fit score** (no extra Claude call): `computeChezVendorFit(v)` combines existing-network bonus (+25), top-rated badge (+18), 4.8★+ (+18), 4.5★+ (+12), 4.0★+ (+6), review volume tiers, phone availability — capped 15-99. Rendered as the meter + reasoning sentence on every vendor row.

**Tone QA** is heuristic, not AI: `assessConciergeReplyTone(draft, tone)` checks for warm cues / direct verbs / formal salutations + length sanity, hints inline below the textarea. No round-trip latency.

**Voice capture** is rendered but disabled with a tooltip explaining the single-state CT consent requirement called out in the design handoff. Type-into-form path works fully; the ✨ Summarize button polishes raw notes into homeowner-facing copy.

**Responsive:** desktop-first per the spec. <1280px collapses the Alfred sidebar; <1024px collapses the homeowner panel. Minimum useful viewport is 1280×800.

**CSS:** ~1900 lines of cockpit-scoped styles in `admin.css` using the existing tokens (Cosmic Indigo / Deepened Salmon / Pearl White). Indigo-gradient AI brief hero, salmon CTAs only (per the spec's strict salmon usage rule), indigo-tinted shadows, soft mesh-gradient overlay on the brief + Alfred header.

**Files:** `website/admin.html` (host element), `website/admin.js` (~2300 lines added — cockpit shell + 4-pane renderers + handler attachment + 3 helper passes), `website/admin.css` (~1900 lines), `supabase/functions/chez-concierge/index.ts` (+ `ask_alfred` action ~170 lines).

**Verification:** `node --check website/admin.js` clean; chez-concierge function deployed; admin.html boot in preview shows zero console errors, host element present + correctly hidden until login.

---

## Phase 82: Case lifecycle tracking — stage tracker + active visits panel (2026-05-01)

Every prior Chez phase made it easier to TAKE a request. Phase 82 makes it easier to FINISH one. Once the homeowner approves a vendor proposal, the case stops being "research and propose" and becomes "coordinate this visit through completion." Tom flagged this exactly: "I sent 2 recommendations to the homeowner and they accepted 2, so this case should just turn into tracking those 2 new visits right throughout the duration of this case."

**Schema (`20261204_chez_visits.sql`):**
- `chez_visits` table — one row per approved vendor with state machine `awaiting_date` → `scheduled` → `completed` (plus `cancelled` escape)
- Snapshots vendor identity at approval time (`vendor_name`, `vendor_phone`, `vendor_payload JSONB`) so future proposal edits don't drift the visit row
- `proposal_message_id` FK back to the originating proposal so the visit card can deep-link to the conversation
- `scheduled_for` / `scheduled_window` / `notes` / `outcome` cover everything Tom needs to write down across calls
- Partial index on `(household_id, state)` for active-visit queries; full index on `(request_id, created_at)` for thread rendering
- RLS mirrors `chez_requests` (household members read; admin reads + updates everything)

**Edge Function:**
- `handleDecideProposal` extended — when the decision is `approved` AND the proposal kind is `vendor`, idempotent insert into `chez_visits` keyed by `proposal_message_id` so re-approvals don't duplicate
- `handleFetchVisits` action — returns active + completed visits AND self-heals: scans approved vendor proposals on the request, creates a visit row for any without one. Catches every pre-Phase-82 approval that already happened in production
- `handleUpdateVisit` action — transitions state, optionally fires a homeowner reply in the same call (creates a `concierge_messages` + `inbox_items` row via the existing reply path), and writes a system-message audit trail describing the transition. Visits don't carry a `user_id`, so the system message uses `request.user_id` from the parent.

**Admin portal (`website/admin.js`):**
- `renderStageTrackerHtml` — 7-stage horizontal pill rail at the top of the focused panel: Submitted → Research → Sent → Picked → Booked → Visit → Done. Computed from existing signals (`chez_messages` proposal kinds + statuses + `chez_visits` state + `request.status`). Done states are green; current is salmon-filled; future is muted. No new schema needed for the computation — it's a pure derivation.
- `renderVisitsPanelHtml` + `renderVisitCardHtml` — Active Visits panel between the tracker and the analysis panel. Each card has phone tap-to-call, slot-adoption chips that copy the vendor's offered times into the `scheduled_window` field with one click, datetime-local picker, notes textarea, and three transition buttons (Mark scheduled / Mark completed / Cancel) each with optional reply text.
- `renderChezAnalysisPanelHtml` gains an `opts.collapsed` mode — when there are active visits, the analysis collapses to a one-line summary with an "Expand" button. Shifts Tom's attention to the coordination work without losing access to the research.
- New action handlers: `expand-analysis`, `mark-resolved-from-visits`, `adopt-slot`, `visit-mark-scheduled`, `visit-mark-completed`, `visit-cancel`, `visit-save-notes`. State caches: `state.chezVisitsByRequest` + in-flight Set guard `state.chezVisitsInFlight`.
- `loadChezMessages` invalidates the visits cache on every reload so newly approved proposals trigger the self-heal on next render.

**Verification:** Migration applied to remote (`20261204_chez_visits.sql`); chez-concierge Edge Function v5 deployed; `node --check website/admin.js` clean; `xcodebuild BUILD SUCCEEDED` on Chez scheme. The two visits Tom flagged ("I sent 2 recommendations and they accepted 2") will materialize on the next admin portal hard-refresh — `fetch_visits` will see the approved proposals without visit rows and create them in line.

---

## Phase 80.2: Per-task Chez delegation (2026-05-01)

Closed the obvious gap in 80.1 — the homeowner could delegate routines + contractors but not individual tasks. Most "I want help with this" moments are a single specific task without a vendor, so the per-task layer is where the offload-feeling actually lands.

**Schema (`20261203_chez_task_delegation.sql`):**
- `maintenance_tasks.chez_owned BOOLEAN DEFAULT false`
- `maintenance_tasks.chez_owned_at TIMESTAMPTZ`
- `maintenance_tasks.chez_request_id UUID REFERENCES chez_requests(id) ON DELETE SET NULL` — bidirectional link so Chez can post task-state updates from inside the parent thread
- Partial indexes for the admin's standing-engagements filter

**Edge Function — new `delegate_task` action:** Smart category routing on the no-vendor case. Reads `assigned_contractor_id` + `needs_vendor`; tasks without a vendor route through `category=find_vendor`, tasks with one through `coordinate_task`. Builds a parent `chez_requests` row + system message that reads explicit + actionable to the operator ("Customer asked Chez to source a vendor for this task and own coordination end-to-end. Find a vetted local pro, propose them, and handle scheduling once approved."). Stamps `task.chez_request_id` back so the conversation thread owns subsequent task changes. Push + admin email fire on every delegation. Revoke path clears the flags + posts a follow-up system message in the existing thread (audit preserved).

**iOS:**
- `MaintenanceTaskDBRow` gains `chezOwned`, `chezOwnedAt`, `chezRequestId` + `isChezOwned` helper. Both `synthetic` factories updated to seed nil so memberwise init still compiles.
- `ChezOwnsToggle.Target` gains `.task(id, title, hasVendor)`. Copy forks: vendor-on-file says "Chez coordinates with your vendor"; no-vendor says "Chez finds a vetted local pro and proposes them".
- `HavenSupabase.delegateTaskToChez` wrapper around the new action.
- `MaintenanceTaskDetailSheet` renders the toggle right under the header for any non-vehicle task — gates on `task.vehicleId == nil` because vehicles run their own coordination flow.
- `UnifiedTaskCard.findContractor` variant gains "Or have Chez source one" inline link below the salmon Find-a-pro CTA (one tap fires `delegate_task` directly, no composer detour). Personal + vendor variants gain a compact `ChezOwnsBadge` next to the title when the task is delegated.
- `ChezDelegationsListView` (new): single screen aggregating delegated routines + contractors + tasks with quick-revoke pills. Reachable from Settings → Your Chez profile → "View what Chez owns" (replaces the 80.1 placeholder).
- Profile view's standing-engagements section now opens this list via NavigationLink.

**Verification:** `xcodebuild BUILD SUCCEEDED` on iPhone 17; migration `20261203` applied; chez-concierge function v4 deployed; `node --check website/admin.js` clean.

---

## Phase 80.1: Chez profile, spending tiers, structured proposals, recurring delegation + Tom→Chez rebrand (2026-05-01)

Four big depth additions on top of the Phase 80 foundation. Plus a full user-facing rebrand: every "Tom" string in iOS + Edge Function copy is now "Chez" so homeowners see the brand, not the operator.

### 1. Household profile / standing instructions

- New `households.chez_profile JSONB` with about_us text, communication prefs, vendor prefs, logistics, spending tiers, completion timestamps.
- iOS: `ChezProfile` model + `ChezProfileViewModel` (debounced save) + 6-section `ChezProfileView` (settings-style scrollable form).
- Settings hub gains a top "Your Chez profile" entry above Account.
- Edge Function: `fetch_profile` + `update_profile` actions with server-side deep-merge so partial updates work.
- Admin portal renders the customer's profile + spending-tier pill above the reply composer so Chez sees standing instructions before drafting.

### 2. Spending tiers

- Lives inside `chez_profile.spending_tiers` — three integer USD thresholds: auto_approve_under, ping_under, explicit_above. Defaults `(200, 500, 500)`.
- Stepper UI in the profile screen with one-line captions per tier explaining what Chez will do at that threshold.

### 3. Structured proposals — Approve / Counter / Decline

- New `concierge_messages.proposal JSONB` + `proposal_kind` text. Four kinds: vendor / date_slot / cost / quote.
- iOS: `ChezProposalCard` renders inline in `ChezMessageBubble` when a proposal is attached. Optimistic update on tap.
- Edge Function: `propose` (admin-only, sends a structured message) + `decide_proposal` (homeowner approve/decline/counter). Counter prefills the reply composer with a kind-aware template.
- Admin portal: "Propose vendor / date / cost" quick-action runs a stepwise prompt flow that sends a structured message instead of plain text.

### 4. Recurring delegation — Chez owns scheduling

- New `routines.chez_owned` + `contractors.chez_owned` BOOLEANs (with timestamp columns). Indexes for the admin's standing-engagements filter.
- iOS: `ChezOwnsToggle` reusable component with `.routine` / `.contractor` targets. Wired into `RoutineEditSheet` (after Notes, before Delete) and `ContractorDetailView` (top of the detail page).
- Compact `ChezOwnsBadge` for list rows.
- Edge Function: `delegate_routine` + `delegate_contractor` actions create a "Standing engagement" parent `chez_request` with system message + push + admin email.

### Rebrand

- All entry-point captions, SLA captions, system messages, compose hero copy, push notification titles, inbox row titles, admin-portal homeowner-facing strings — every "Tom" → "Chez". Concierge avatar changed from "T" to "C". Internal admin labels say "Chez (you)" so the operator can tell their side from the homeowner's.
- Hard rule going forward: user-facing copy says "Chez" only.

**Verification:** `xcodebuild BUILD SUCCEEDED` on iPhone 17; `node --check website/admin.js` parses; migration `20261202` applied; chez-concierge function redeployed.

---

## Phase 80: Chez Concierge — "Have a Chez Home Manager handle this" (2026-05-01)

Universal escape hatch that lets homeowners delegate any vendor / quote / scheduling / coordination task to Tom. Renders as a salmon-tinted "Have a Chez Home Manager handle this" pill anywhere it makes sense in the app. Tap → composer sheet (auto-fills category + context from the entry point) → submit → request lands in Tom's admin portal with a 24-hour business-day SLA badge. Tom replies with vendors / dates / quotes / follow-ups; replies that need confirmation land in the homeowner's existing **Needs Action** inbox tab, informational replies land in **Unread**, and the full request thread lives in a new **Chez** sub-tab on the Inbox so the homeowner has a dedicated browse surface.

### Architecture decisions

- **Smart inbox routing** (Tom's clarification): admin replies create `inbox_items` rows so they flow through the homeowner's existing Needs Action / Unread / All sorting. Discriminator is an "Acknowledgement required?" checkbox in the admin portal that swaps the type between `chez_reply_action_needed` (lands in Needs Action) and `chez_reply_informational` (lands in Unread). Persistent thread browse lives in the new `Chez` sub-tab on Inbox.
- **Single Edge Function + action discriminator** mirroring `process-inbox-item`: `submit` / `reply` / `mark_read` / `transition_status`. Admin replies can transition status in one call via optional `to_status` so Tom doesn't have to click twice.
- **Storage reuse, not a new bucket.** Attachments upload to the existing `documents` bucket under `chez-requests/{user_id}/{filename}` via the standard storage API. Metadata (path / filename / mime / size / uploaded_at) lands as JSONB on `concierge_messages.attachments`. No new bucket policy needed.
- **Email backstop for admin push.** Tom doesn't have the iOS app installed in the admin context, so silent push delivery isn't enough. Edge Function pushes to `CHEZ_ADMIN_USER_IDS` AND emails `CHEZ_ADMIN_EMAILS` via SendGrid (default `tom@getchez.com`). Email is the primary signal.
- **24-hour business-day SLA** computed server-side via `chez_business_hours_due` PL/pgSQL function; visual badge only (green / amber / red), no cron, Tom self-monitors.

### Database (`supabase/migrations/20261201_chez_requests.sql`)

- New `chez_requests` table — `category` (`find_vendor` / `get_quote` / `schedule_visit` / `coordinate_task` / `find_handyman` / `general`), `status` (`open` / `waiting_customer` / `resolved`), `summary`, `context jsonb`, `sla_due_at`, `last_message_at`, `unread_for_user`, `unread_for_admin`, `resolved_at`. RLS scoped to household for homeowners + `is_tom_admin()`-gated SELECT/UPDATE for the admin portal (reuses the helper from `20261001_admin_onboarding_lab.sql`).
- Extended `concierge_messages` with `request_id` FK + `attachments` JSONB + `'system'` role for status-change audit-trail rows. Index on `(request_id, created_at)`.
- Added `inbox_items.related_chez_request_id` FK so deep-linking from inbox → request thread is a foreign-key follow.
- `chez_business_hours_due(now())` function walks 24 weekday-hours skipping weekends.
- `set_chez_requests_updated_at` trigger.
- Backfill DO block wraps legacy `concierge_messages` rows in synthetic resolved `chez_requests` (one per household per calendar day) so the admin portal's history surface has parents to thread under.
- Realtime publication membership for `chez_requests` + `concierge_messages`.

### Edge Function (`supabase/functions/chez-concierge/index.ts`)

Single function with action discriminator. Highlights:

- **Auth:** `getAuthenticatedUser` decodes the JWT; `isAdminUser` checks email against `CHEZ_ADMIN_EMAILS` env var. Homeowner-side actions verify `auth.uid()` owns the request.
- **`submit`:** insert request + first message, compute `sla_due_at`, fire push to admin user IDs + email backstop. Creates the parent + opening user message in one shot.
- **`reply`:** inserts message, updates `last_message_at` + unread flags, optional status transition via `to_status` (admin-only convenience). Admin replies create an `inbox_items` row + push + insert a system-role audit message in the thread when the same call also transitions status. Homeowner replies on resolved/waiting requests bump the parent back to open.
- **`mark_read`:** clears unread flag for the caller's side, stamps `read_at` on the other party's messages.
- **`transition_status`:** centralized status flip with system-message audit trail + push + (when resolved) informational inbox_items row.

### iOS (`Haven/Features/ChezRequests/`)

```
Models/
├── ChezRequest.swift               # ChezCategory + ChezStatus enums + ChezRequestRow (resilient init) + payload structs
└── ChezMessage.swift               # ChezMessageRole + ChezAttachmentMeta (Hashable) + ChezMessageRow
ViewModels/
├── ChezRequestsViewModel.swift     # @MainActor; active/past/unread aggregations
├── ChezRequestComposeViewModel.swift # photos+file ingest into documents bucket; submit
└── ChezRequestDetailViewModel.swift  # thread + reply composer + reopen + signed-URL resolver
Views/
├── ChezRequestComposeSheet.swift   # serif "Ask Chez" hero, prefilled context card, category grid (locked when entry-point-fixed), summary + description fields, attachment tray (PhotosPicker + file importer), salmon submit
├── ChezRequestsListView.swift      # 4th Inbox sub-tab — Active section + collapsible Resolved section, empty state
└── ChezRequestDetailView.swift     # header + collapsible context + chat-style thread (system rows centered) + sticky reply composer (text + attachments) OR reopen bar when resolved
Components/
├── ChezEntryButton.swift           # Universal pill — posts .openChezRequestComposer with category + context
├── ChezStatusBadge.swift           # Open / Waiting / Resolved pill, three tones
├── ChezMessageBubble.swift         # User right (salmon) / Concierge left ("T" avatar, cream) / System (centered grey)
└── ChezRequestRowCard.swift        # List row: category icon w/ unread dot, summary, status badge, SLA caption, relative timestamp
```

`Haven/Features/ChezRequests/Services/ChezConciergeService.swift` extends `DatabaseService` (`fetchChezRequests` / `fetchChezMessages` / `fetchChezRequest`) and `HavenSupabase` (`submitChezRequest` / `replyToChezRequest` / `markChezRequestRead` / `reopenChezRequest`) — all writes funnel through a private `callConciergeEdgeFunction` helper that mirrors the existing `callEdgeFunction` URLRequest pattern (bypasses supabase-swift's `invoke` for parsing reasons).

### iOS modifications

- `Haven/App/MainTabView.swift` — three new `Notification.Name` extensions (`.chezRequestChanged` / `.openChezRequest` / `.openChezRequestComposer`); global `ChezRequestComposeSheet` host listening on `.openChezRequestComposer` with `ChezComposerInput` Identifiable wrapper so any entry point fires the sheet without owning state.
- `Haven/App/HavenApp.swift` push handler — new `case let t where t.hasPrefix("chez_") && t != "chez_admin_request"` switches to Dashboard tab + posts `.openChezRequest` with `request_id`.
- `Haven/Features/Inbox/InboxView.swift` — added 4th `case chez = "Chez"` to `InboxFilter`. Body splits: when `filter == .chez` renders `ChezRequestsListView()` under the picker; otherwise renders the standard items list. Subscribes to `.openChezRequest` notification and switches `filter = .chez` so push deep links land on the right sub-tab.
- `Haven/Features/Inbox/InboxItemDetailView.swift` — split body into `mainBody`. When `item.isChezReply == true` and a `relatedChezRequestId` resolves (column or metadata fallback), renders `ChezRequestDetailView(requestId:)` directly.
- `Haven/Core/Networking/DatabaseService.swift` — `InboxItemRow` gained `relatedChezRequestId: UUID?` + `iconName` cases for `chez_reply_*` / `chez_status_change` + `isChezReply` helper. `InboxMetadata` gained `chezRequestIdString: String?` + `chezRequestIdAsUUID` computed.
- `Haven/Core/Services/AnalyticsService.swift` — six new events (`.chezEntryButtonTapped`, `.chezRequestSubmitted`, `.chezRequestReplied`, `.chezRequestOpened`, `.chezRequestReopened`, `.chezRequestMarkedRead`).

### Five entry points wired

| File | Where | Pre-fills |
|---|---|---|
| `FindLocalVendorSheet.swift` | Below `addMyOwnButton` | category=`find_vendor`, contractor_category, town, state, task_id, task_title |
| `MaintenanceTaskDetailSheet.swift` | "No vendor" branch of `vendorSection`, after handyman batch CTA | category=`coordinate_task`, task_id, task_title, system_category, system_id, property_id, due, notes |
| `HandymanPunchListView.swift` | `bottomActionBar` | category=`find_handyman`, punch_item_count, property_id, punch_list_preview (top 20 titles) |
| `QuoteAnalysisView.swift` | After analysis-results block | category=`get_quote`, project_id, project_name, vendor, quoted_total, fair_market_estimate, assessment |
| `DashboardView.swift` | Subtle pill below Recent Activity | category=`general`, gated on `hasCompletedAnyQuiz` |

Total iOS edit footprint across the five entry-point files: ~120 LOC of additive code (no existing logic changed).

### Admin portal (`website/admin.js` + `website/admin.css`)

- New `chez` view in the `action` group at the top of `VIEWS` array (above Audit). `state.view === "chez"` routes to `renderChezRequestsView`.
- State additions: `chezRequests`, `chezMessages` (keyed by request_id), `selectedChezRequest`. Cleared on tab navigation alongside `selectedDecision` / `selectedAudit`.
- `loadAdminData` fetches `chez_requests` in parallel with admin items + notes. New `loadChezMessages(requestId)` lazy-loads the thread per-request.
- `renderChezRequestsView` — stats tiles (open / awaiting reply / waiting on customer / resolved this week), urgency-sorted list (overdue first, then unread-for-admin, then most-recent), search filter, click-to-focus.
- `renderFocusedChezDetail` reuses the audit panel's right-rail container. Inside: header (category + status select + SLA pill), context recap grid, conversation thread (user / concierge / system bubbles), reply composer with **Acknowledgement required?** checkbox + status select for one-click reply+transition, quick-action buttons ("Mark waiting on customer", "Mark resolved", "Reopen" when resolved).
- `callChezConcierge` wraps the Edge Function with the admin's JWT; status select changes fire immediately, reply form submits + refreshes list/thread/focus.
- `chezSlaPill` computes green / amber / red / muted bands client-side and re-evaluates each render.
- `admin.css` appended ~200 LOC of Phase 80 styles (chez__row, chez__msg, chez__composer, chez__resolved-bar, chez__quick-actions, plus tone variants for the SLA pill).

### Verification

- `xcodegen` regenerated `Haven.xcodeproj` (auto-includes the new `Haven/Features/ChezRequests/` tree).
- `xcodebuild -scheme Chez -destination "platform=iOS Simulator,name=iPhone 17" build` → **`** BUILD SUCCEEDED **`**.
- `node --check website/admin.js` → parse OK.

### Deploy steps

1. `supabase migration up --linked` (applies `20261201_chez_requests.sql`).
2. `supabase functions deploy chez-concierge --no-verify-jwt`.
3. Set Edge Function env vars: `CHEZ_ADMIN_EMAILS=tom@getchez.com` (comma-separated for multi-admin), optional `CHEZ_ADMIN_USER_IDS`, optional `SENDGRID_API_KEY` (already set for other functions).
4. iOS ships in next TestFlight build — no additional config needed.

### What's intentionally NOT in v1 (deferred)

- Structured vendor proposal cards (Tom proposes vendors as plain text + manual handoff to existing AddVendorSheet)
- Date-slot proposal cards (Tom suggests dates in plain text)
- Quote summary cards (Tom describes quotes in plain text + attaches the PDF)
- Approve / Decline / Request-more buttons on the homeowner side
- Real-time Supabase subscription on iOS (window-focus refresh suffices for v1)
- Server-side SLA enforcement (cron + email at 22h)
- Saved proposal templates on Tom's side
- Audit-trail event-history table (status transitions live on the row only)
- Alfred awareness of open requests (chat function doesn't pre-fetch Chez state)
- 10+ entry points (only the 5 highest-leverage wired in v1)

Each is a clean future addition once Tom sees how the conversation pattern actually plays out in TestFlight.

---

## Phase 67: Tasks Tab V5 (iOS) + Chez Handyman Operations Desk (Web) (2026-04-27)

Two parallel deliverables landed together against the high-fidelity design handoffs in `~/Downloads/Tasks-Maintenance UIUX-2.zip` and `~/Downloads/Handyman Website.zip`.

### iOS — Tasks Tab redesign (`Haven/Features/Tasks/`)

Replaces the Phase 66 `MaintenanceHubView` lobby (8 sections) with a focused 6-section narrative behind a serif title-switcher. `TasksHubView` becomes a thin mode-switch shell. The legacy `MaintenanceHubView` + `HandymanHubView` stay alive — `PropertyDetailView` still pushes `MaintenanceHubView(filterPropertyId:)` for the property-scoped lobby; only the Tasks tab itself adopts V5. `MaintenanceScheduleView` (Phase 56.4–56.6 workshop) is preserved as the "See all" deep-dive — every V5 ArrowLink routes into it with the right initial state, so zero functionality is lost.

**Files added** (`Haven/Features/Tasks/Views/`):
- `MaintenanceTabView.swift` (V5 Maintenance screen + `MaintenanceTabViewModel` aggregator)
- `HandymanTabView.swift` (V5 Handyman screen — wraps `HandymanPunchListViewModel`, `MaintenanceViewModel.shared`)
- `Components/TasksV5Tokens.swift` (V5-specific season tints, hero/band gradients, shadow recipes)
- `Components/IconTile.swift` (36×36 / 44×44 rounded square; `indigo` / `salmon` tones)
- `Components/SectionLabel.swift` (eyebrow + sub + ArrowLink action slot)
- `Components/HeaderSwitcher.swift` (serif title chevron + 40×40 white "+" button)
- `Components/IndigoGradientCard.swift` (.hero + .band variants; also `MiniHeroContent`, `VisitHeroContent`, `BrowseBand`, `WhatWeHandleBand`)
- `Components/YearRibbon.swift` (4 season tiles, active 50% wider, NOW chip on current)
- `Components/MaintenanceRows.swift` (`DecisionRow` salmon-wash + `ProgramRow` ON pill + `VehicleProgramRow` "Set up →")
- `Components/HandymanComponents.swift` (`VendorCard` linked/empty + `PunchListCard` w/ green-fill checkbox + `RecommendedRow` salmon "+" + `VisitHistoryEmptyCard`)

`TasksHubView.swift` rewritten to a 70-line shell — `@AppStorage("tasksHubMode")` persists last-used mode, `confirmationDialog` sheet swaps modes via the title-switcher chevron, both child views own their own `HeaderSwitcher`. `Season.months` extension added in `TasksV5Tokens.swift` so the YearRibbon's filter pipeline aggregates `routines.activeMonths` against the active season.

Decision-row "Choose vendor →" wires through a `DecisionVendorPicker` wrapper around the existing `ContractorPickerSheet(systemCategory:onSelect:)` — selection sets `RoutineUpdate.vendorId` + flips `setupState` to `.active` via `DatabaseService.updateRoutine(id:_:)`. Recommended-row "+" creates a `HandymanPunchItemInsert(source: "recommended")` and reloads the punch list. Punch-list checkbox tap optimistically green-fills + line-throughs the row, then archives via `HandymanPunchListViewModel.archive(entry:)` after 500ms.

CLAUDE.md typography section corrected (Phase 56.3 system font migration was already done — `New York` serif + `SF Pro` sans, not Fraunces + Inter as the previous text claimed). Tab table updated: index 2 is now `Tasks` (was misdocumented as `Life`). `xcodebuild ... build` succeeds.

### Web — Operations Desk SPA (`website/operations/`)

Brand-new React + Vite + TypeScript app. Replaces `handyman.html`'s embedded 9 workspace tabs with a properly-designed 8-screen SPA at `/operations/*`. `handyman.html` keeps the auth pitch + sign-in/sign-up form and redirects to `/operations/` post-auth (preserving `?next=` deep links). Vanilla pages, the field PWA (`handyman-visit.html`), and the homeowner quote view (`handyman-quote.html`) are all untouched.

**Stack:** React 18 + TypeScript + Vite 5 + React Router v6 + `@supabase/supabase-js` v2. Reuses `chez.css` tokens via `<link>`. Inline SVG icon library — no Lucide, no icon font, no Google Fonts.

**Files added:**
- `package.json`, `vite.config.ts` (`base: '/operations/'`), `tsconfig.json`, `index.html`
- `src/main.tsx` + `src/App.tsx` (auth gate + `<Sidebar>` + `<Topbar>` + 8-route `<Outlet>`)
- `src/lib/supabase.ts`, `src/lib/types.ts`, `src/lib/workspace-context.tsx` (`WorkspaceProvider` + `useWorkspace`), `src/lib/fixtures.ts` (verbatim port of the design handoff's `data.jsx`)
- `src/styles/operations.css` (sidebar, topbar, card, pill, hero, KPI strip, dispatch lanes, mobile interstitial)
- `src/components/chrome/`: `Sidebar`, `Topbar`, `Pill`, `Card`, `Avatar` + `initialsFor()`, `StatTile`, `EmptyState`, `Icon`
- `src/screens/`: `Overview`, `Dispatch`, `Calendar`, `Routes`, `Crew`, `Homes`, `Quotes`, `Messages`

**Mode awareness:** `WorkspaceProvider` reads `provider_workspace_members.where { user_id == auth.uid }`, loads workspace + roster in parallel. `mode = members.length > 1 ? "crew" : "sole"`, overridable via `?mode=sole|crew`. Sole mode hides the Crew nav item, swaps "Crew today" → "Today (you)", uses personal hero copy ("Four stops today, finished by 3:30"). Crew mode adds the Crew workload strip + operational hero ("Own the queue, route the field team").

**Data wiring:** v1 fixture-backed (`lib/fixtures.ts` mirrors the design's CREW / HOMES / VISITS / QUOTES / MESSAGES). Real Supabase queries plug in by extending `WorkspaceProvider` or adding a `lib/api.ts` layer — RLS already gates per-workspace via the Phase 71/72 tables (`provider_workspaces`, `provider_workspace_members`, `provider_visit_assignments`, `provider_quotes`, `provider_saved_quote_items`, `handyman_requests`, `handyman_request_messages`).

**Files modified:**
- `website/handyman.js`: `refreshWorkspace()` post-auth redirects to `/operations/` (or `?next=` if set) instead of rendering the embedded workspace. Legacy `renderWorkspace()` call kept as unreachable fallback for safety.
- `website/nginx.conf`: added `location /operations/` block with SPA-fallback rewrite (`try_files $uri $uri/ /operations/index.html`) before the existing catch-all. Added long-cache rule for `/operations/assets/`.
- `website/Dockerfile`: now multi-stage — `node:20-alpine` build stage compiles `operations/dist/`, `nginx:alpine` serves both vanilla pages and the SPA. Fixed pre-existing missing-asset bug by COPY'ing `chez.css` and `favicon.svg` into the image (both were referenced by vanilla pages but never copied).

**Deployment:** `npm install && npm run build` succeeds (436 KB JS / 11.5 KB CSS gzipped). Local dev: `cd website/operations && npm run dev` at `localhost:5173/operations/`. Production: docker build runs end-to-end (Docker not available in current sandbox, will be verified in CI).

**Acceptance:** All 8 routes render in `mode=sole` and `mode=crew` (toggle via `?mode=`). Empty states use the shared `EmptyState` component. Sidebar `is-active` state has the salmon-glow border + bg per spec. No Google Fonts requested. Max 2 salmon CTAs per screen (DESIGN_RULES rule #12).

### What's left for follow-ups

- Drag-to-reschedule on Calendar (V5 spec mentions; deferred to v2)
- "Optimize all routes" actually computing optimal routes (would need a routing API; v1 stubs the button)
- Live Supabase data wiring on Operations Desk screens (fixtures shape matches `lib/types.ts` row contracts; swap-in is mechanical)
- Strip the embedded workspace tab DOM from `handyman.html` (kept as unreachable fallback for now to de-risk rollout)
- Push notifications for handyman company events (assignment notifications, message replies)

---

## Phase 66: Routines as First-Class Services (2026-04-20)

Ships the five-section Maintenance hub ("Services", "Next Handyman Visit", "Vehicles", "This Season", "Upcoming Scheduled") entirely on top of the existing `routines` (Phase 55.1) + `routine_visits` tables rather than creating the proposed `household_services` + `service_visits` + `vehicle_service_programs` tables that would have duplicated ~85% of the routines model. Zero new tables; five additive columns + two partial unique indexes + one CHECK constraint. Evaluation in `/Users/tomburke/.claude/plans/users-tomburke-downloads-files-2-phase-logical-robin.md` documents why.

**Schema (migration `20260800_phase66_routines_first_class.sql`):**
- `routines.setup_state` (`draft` | `pending_vendor` | `active` | `paused` | `archived`) defaulting to `active` so legacy rows auto-migrate
- `routines.service_contract_id` FK for optional formal contracts
- `routines.scope` (`property` | `vehicle`) + `routines.vehicle_id` + `routines.program_mode` (`shop_managed` | `self_managed`)
- `routine_visits.visit_state` (planned/scheduled/in_progress/completed/cancelled/skipped) + `target_window_start` + `target_window_end`
- `maintenance_tasks.parent_routine_id` + `maintenance_tasks.bundle_parent_task_id`
- `routines_vehicle_scope_valid` CHECK + partial unique indexes for one-active-per-vehicle and one-active-handyman-per-property

**iOS structure:**
- `RoutineRow`, `RoutineInsert`, `RoutineUpdate` extended with the new columns + typed getters (`typedSetupState`, `typedScope`, `typedProgramMode`, `isVisible`, `hidesChildTasks`)
- `RoutineSetupState` + `RoutineScope` + `RoutineProgramMode` + `RoutineVisitState` enums added
- `RoutineVisitInsert` + `RoutineVisitUpdate` added (Phase 55.1 only had the Row)
- `MaintenanceTaskDBRow` / Insert / Update gain `parentRoutineId` + `bundleParentTaskId`
- `DatabaseService` adds: `fetchRoutinesByScope`, `fetchHandymanRoutine`, `fetchOrCreateHandymanRoutine`, `fetchPendingVendorRoutines`, `fetchVehicleRoutine`, `fetchVehicleRoutines`, `createVehicleRoutine`, `createRoutineVisit`, `updateRoutineVisit`, `fetchActiveRoutineVisits`, `fetchScheduledVisitsForHousehold`, `fetchTasksForRoutine`, `assignTaskToHandymanRoutine`

**New files:**
- `Haven/Features/Property/Services/RoutineGroupingEngine.swift` — runtime `linkVendorTasksToRoutine` + `linkVehicleTasksToRoutine` + `unlinkTasksFromRoutine`, plus RoutineKind ↔ home_systems.category mapping
- `Haven/Features/Property/Services/Day1TaskCurator.swift` — post-quiz four-way router gated on `hasRunDay1Curator_<propertyId>_v1`; routes vendor/pending-vendor/handyman/This Season based on preference tier + effort cap + safety floor
- `Haven/Features/Property/Views/MaintenanceHubView.swift` — the new top-level Maintenance tab with loader `MaintenanceHubViewModel`
- `Haven/Features/Property/Views/RoutineDetailView.swift` — unified service + vehicle program detail view
- `Haven/Features/Property/Views/Components/MaintenanceHubSections.swift` — `YourServicesSection`, `NextHandymanVisitSection`, `VehiclesSection`, `ThisSeasonSection`, `UpcomingScheduledSection`
- `Haven/Features/Dashboard/Components/MaintenanceReorganizedCard.swift` — one-time @AppStorage-gated reorganization card

**Integration points:**
- `HouseQuizAnswerMapper.ensureVendorRoutineForCategory` creates `setup_state='active'` routines at Q15b when contractors are captured, with category-appropriate cadence + active_months (landscaping weekly Apr-Nov, snow removal annual Dec-Apr, pool weekly May-Sep, etc.). Runs `RoutineGroupingEngine.linkVendorTasksToRoutine` after creation so pre-existing vendor tasks link.
- `HouseQuizViewModel.finalReconcileTask` calls `Day1TaskCurator.runIfNeeded` right after `reconcileAll` so fresh template tasks land in their correct home.
- `MaintenanceTaskDetailSheet.addToPunchListJustThisTime` + `addToPunchListReassignSeries` call `db.assignTaskToHandymanRoutine` alongside the existing `createHandymanPunchItem` — the punch-list UI + parent_routine_id linking are a single action.
- `RoutineEditSheet.save` derives `setup_state` from the vendor picker state (service-based + vendor set = active, service-based + no vendor = pending_vendor), runs `linkVendorTasksToRoutine` when active and property-scoped, and calls `unlinkTasksFromRoutine` when the routine leaves the active state.
- `MaintenanceScheduleView.personalBucketTasks` + `vendorBucketTasks` filter `parent_routine_id != nil` so tasks live under exactly one surface (the routine).
- `AppState.runDay1CuratorForExistingPropertiesOnceIfNeeded` backfills the curator for quiz-completed properties pre-Phase-66, gated on `hasRunDay1CuratorBackfillP66_v1`, runs after `materializeHandymanBundleChildrenOnceIfNeeded`.
- DashboardView and PropertyDetailView navigation destinations rewired from `MaintenanceScheduleView()` to `MaintenanceHubView()`; MaintenanceScheduleView is now the Timeline push destination via a "See full year ↗" link inside the hub.
- `MaintenanceReorganizedCard` renders once on Dashboard above `compactGreeting` for users where `viewModel.hasCompletedAnyQuiz == true`, dismisses via `@AppStorage("maintenanceReorganizedCardDismissed_v1")`.

**Analytics:** 16 new events — `routineVendorTasksLinked`, `vehicleRoutineTasksLinked`, `routineActivated`, `routineArchivedFromServices`, `pendingVendorRoutineCreated`, `day1CuratorRan`, `day1CuratorTaskRoutedHandyman`, `day1CuratorTaskRoutedVendor`, `day1CuratorTaskRoutedPendingVendor`, `maintenanceReorganizedCardViewed`, `maintenanceReorganizedCardDismissed`, `yourServicesOpened`, `nextHandymanVisitOpened`, `vehicleRoutineOpened`, `routineDetailOpened`, `seeFullYearTapped`.

**What Day 1 looks like for `.hireOut` HNW users who pick Blue Fox + Tyler at Q15b:** Your Services renders 2 active routines + 3-5 pending-vendor cards. Next Handyman Visit renders 8-15 low-effort items with `assigned_route='handyman'`. Vehicles renders summary cards with "Set up shop →" prompts. This Season contains ≤3 rows (genuine decisions only). Upcoming Scheduled is empty until the user confirms a visit date.

**What NOT to do (per plan):** No `household_services` / `service_visits` / `vehicle_service_programs` tables. No `is_hidden_by_service` column. No post-quiz "Set up 3 services" screen (Q15b does the work). No auto-migration for existing users (opt-in via card only). No Timeline removal (kept as push destination). No mixed-mode vehicle programs.

---

## Phase 60.6: Vendor Coverage Matching + Q15b Gap Closure + Post-Quiz Sweep (2026-04-20)

Fixes the "13 of 18 systems need a vendor" state Tom flagged on Build 93 after completing the quiz on 236 Sarles Street. Three root causes, addressed in one shot:

**Root cause 1 — exact-string category match.** `SystemCategoryRegistry.vendorCoverageItems` was matching `contractor.category == system.category` as a case-sensitive equality. Groton Plumbing & Heating (category: `"Plumbing"`) should have covered the Plumbing system — but the contractor insert path in `VendorReviewForm.save()` left `category = nil` when the user added a vendor manually without detected services, so the match silently skipped every manually-added contractor. The few that *did* have a category stamped were exposed to case/label drift ("Plumbing & Heating" / "Fire Protection" vs. registry keys).

**Fix 1a:** New `SystemCategoryRegistry.canonical(category: String?) -> String?` normalizes verbose labels through a 5-step resolution order (exact key → case-insensitive key → variant map → prefix split on " & " / " / " / ", " / " and " → trimmed original). Handles 40+ aliases: `"Plumbing & Heating"` → `"Plumbing"`, `"Heating & Cooling"` → `"HVAC"`, `"Fire Protection"` → `"Chimney"`, `"Security"` → `"Security System"`, `"General Handyman"` → `"Handyman"`, `"Painting/Exterior"` → `"Painting"`, `"Trash"` → `"Trash & Recycling"`, etc. `categoriesMatch(_:_:)` is the canonical-equality helper. `vendorCoverageItems` rewritten to canonicalize BOTH sides (contractor pre-pass via dictionary, system at read time) before checking `relatedCategories` expansion.

**Fix 1b:** `VendorReviewForm` adds a "Primary specialty" picker in the Type section, visible only for `"Contractor / Service Provider"` contactType. Picker list pulls from `SystemCategoryRegistry` (Tier 1 + Tier 2 + 9 vendor-relevant specialty categories). On appear, auto-seeds from `vendor.prefilledCategory` → `detectedServices` → company-name keyword match, all routed through `canonical(category:)`. Save path: `pickedCategory ?? autoCategory` → canonical → `insert.category` AND mirrored into `specialties` so the Contacts row subtitle renders correctly. Post-system-assignment update also canonicalizes.

**Fix 1c:** `AppState.canonicalizeContractorCategoriesOnceIfNeeded()` one-time backfill walks every household contractor and rewrites `category` + `specialties` to their canonical forms. Gated on `hasRunContractorCategoryCanonicalizationP60_6_v1`. Runs after `backfillUtilityContractorMirrorOnceIfNeeded` in the initialize() chain. Estate labels (Attorney, Financial Advisor / CPA, etc.) pass through untouched via a `byCategoryKey[canonical] != nil` guard.

**Root cause 2 — Q15b coverage gaps.** The chimney_sweep chip mapped to `"Fire Protection"` (a sub-system category with `showInVendorCoverage: false`), so every chimney pro captured at Q15b was invisible. Hardscape contractors (Q11 = hardscape) and backup generator service vendors had no chip at all.

**Fix 2a:** `HouseQuizAnswerMapper.householdContractorCategoryFor` remaps `chimney_sweep` → `"Chimney"` (Tier 2, visible), `tree_service` → `"Tree Service"` (dedicated Tier 2 instead of collapsing into Landscaping). `QuizLocalContractorPicker.categoryParam` mirrored so find-local-vendors filters Google Places by the right trade.

**Fix 2b:** Two new Q15b chips. `hardscape` ("Hardscape / masonry") visible only when `q11_lawn.answerId == "hardscape"`, maps to `"Landscaping"` category because masonry pros usually ARE landscapers. `generator_service` ("Generator service") visible only when Q22 captured a non-"none" generator, maps to `"Generator"` so the annual load-test vendor shows up on its own coverage row instead of orphaning on Electrical. `HouseQuizView.visibleContractorChips` extended.

**Root cause 3 — post-quiz coverage surface.** Nothing surfaced the gap to the user before landing on the dashboard. The user completed Q36, saw the cinematic reveal, and discovered the 13/18 state only when they opened Vendor Coverage from the Property tab.

**Fix 3:** `HouseQuizView.completionView` loads the coverage gap list on `.task` alongside `finaleTotals`. When 2+ categories are uncovered, the existing `VendorCoverageSheet` (same one PropertyDetailView's button opens) auto-presents BEFORE the Phase 19l delegation sheet. Two per-gap actions:
- **"Find a pro"** opens `FindLocalVendorSheet` with the gap category pre-filled; Google Places results filtered by trade.
- **"I have one"** opens `AddVendorSheet(prefilledCategory:)` — new param that propagates through `ImportedVendorData.prefilledCategory` so the picker opens pre-selected on the right specialty.

Sheet dismissal chain: coverage sweep → onDismiss triggers `refreshCoverageGaps()` + conditional delegation sheet. If gaps resolve below 2 during the sweep, delegation fires after dismiss. Single gap skips the sweep entirely (surfaces via Dashboard's existing routes). `SweepSheetTarget` enum routes find/add through a single `.sheet(item:)` binding to avoid colliding sheet presentations.

### Files touched
- `Haven/Features/Property/Services/SystemCategoryRegistry.swift` — added `canonical(category:)`, `categoriesMatch(_:_:)`, canonicalized `vendorCoverageItems` (related-categories expansion runs on canonical keys).
- `Haven/Features/Property/Views/VendorReviewForm.swift` — specialty picker, onAppear prefill chain, save path canonicalization.
- `Haven/Features/Property/Views/AddVendorSheet.swift` — `prefilledCategory` param, `ImportedVendorData.prefilledCategory` field, seeded in onAppear.
- `Haven/App/AppState.swift` — `canonicalizeContractorCategoriesOnceIfNeeded()` backfill + wired into initialize().
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizAnswerMapper.swift` — chimney_sweep → Chimney, tree_service → Tree Service, hardscape + generator_service cases.
- `Haven/Features/Onboarding/HouseQuiz/Components/QuizLocalContractorPicker.swift` — mirrored category param remapping.
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizQuestionLibrary.swift` — two new Q15b chips (hardscape, generator_service).
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift` — coverage sweep state, `.task` coverage load, sheet wiring, `refreshCoverageGaps()` / `loadCoverageGaps()`, conditional Q11-hardscape / Q22 gating in `visibleContractorChips`.

### Schema
No migrations. Every fix ships in Swift — canonical DB values are written by the iOS layer.

---

## Phases 61–66: Post-audit Routing Overhaul (2026-04-19)

Three-build sprint implementing revised Phases 61 through 66 per the [master plan](/Users/tomburke/.claude/plans/users-tomburke-downloads-readme-master-compressed-stardust.md). The original prompts were drafted against an imagined library state — this re-implementation lands on top of actually-shipped Phases 55, 56.4–56.6, 57, 58, 60, 60.3.

### Build A: Phases 61 + 62 + 63

**Phase 61 — Library audit + legacy infrastructure.** Audit confirmed Phase 58 already dissolved every chore-tracker template the original plan wanted to delete (dishwasher filter monthly, washing machine monthly, garbage disposal, fridge seals, camera lenses, solar output monitor, inverter check, outdoor lighting, faucet aerators, irrigation heads). All 4 smoke/CO Electrical duplicates already consolidated to Fire Protection → Chimney via Phase 60. Frequency outliers (HVAC filter monthly, generator oil quarterly, solar visual quarterly, range hood quarterly) already retired or folded into Handyman bundles. Net: zero template deletions needed.

Infrastructure still shipped: `LegacyTasksNotificationCard` dashboard component (gated on `legacyTaskCount > 0`, dismissible via `@AppStorage("hasSeenLegacyTasksCleanupP61")`); `LegacyTasksView` + `LegacyTaskDetailView` read-only list of archived tasks grouped by archive reason (subtype mismatch / bundle consolidation / library retirement / tidied up); `DashboardViewModel.legacyTaskCount` loaded via `fetchAllMaintenanceTasks(includeArchived: true)`; `MaintenanceTaskDBRow.archivedReason` field added to model + CodingKeys so the reason surfaces in the new view. Analytics: `legacyTasksCleanupCardViewed/Dismissed/Opened`.

**Phase 62 — 6 new templates + 4 enrichment flags.** Radon dropped (Phase 57 covers NE vendor-grade radon in Air Quality category). Six new templates wired into MaintenanceTemplates.swift: `Inspect attic ventilation and insulation` (Roofing, every 2 years, vendor, universal, isEssential); `Test sump pump battery backup` (Plumbing, semi-annual, DIY, gated on `sump_pump` + `has_sump_battery_backup`); `Replace refrigerator water filter` (Appliance, semi-annual, DIY, gated on `has_fridge_water_dispenser`); `Driveway seal coat` (Siding/Exterior, every 2-3 years, DIY-capable, gated on `driveway_asphalt`); `Arborist tree health inspection` (Landscaping, annual, vendor, `safetyFloor: true`, gated on `mature_trees`); `Backflow preventer test` (Irrigation, annual, vendor, universal).

Subtype plumbing: `has_sump_battery_backup` / `has_mature_trees` / `has_fridge_water_dispenser` / `driveway_asphalt` added to `MaintenanceTemplates.activeSubtypes`; reconciler's property-flag merger extended to the three new yes/no keys plus a string-to-bool translation for `driveway_material == "asphalt"`. Four new enrichment questions added to `EnrichmentCardEngine`: mature trees (priority 42), driveway material (43, single-choice), fridge water dispenser (44), sump battery backup (46, conditional on sump pump system). `EnrichmentActions.applyEnrichment` gains four cases that call `reconcileAll` — no inline task creation per CLAUDE.md "template library is truth" rule.

**Phase 63 — Handyman preference captured at Q15b.** Migration `20260710_phase63_preferred_handyman.sql` adds `households.preferred_handyman_contractor_id` FK + `idx_properties_handyman_preference` JSONB index. `HouseholdRow` / `HouseholdUpdate` extended with `preferredHandymanContractorId` + resilient decoder. `HouseQuizAnswerMapper` Q15b handler derives 3-way preference from chip state: handyman selected + provider captured → `has_one`; handyman selected without provider → `needs_help`; handyman not selected → `does_diy`. Writes to `properties.attributes.handyman_preference`. Handyman contractor creation now also sets `households.preferred_handyman_contractor_id`.

`FindHandymanCard` dashboard component with 30-day snooze — renders when `handyman_preference == "needs_help"` AND no handyman-category contractor exists. Tap opens Alfred with pre-filled vetting prompt. `HandymanPreferenceView` Settings screen with 3-chip picker (matches `MaintenancePreferencesView` Phase 88 pattern). Switching away from `has_one` clears the household FK but preserves the contractor row. Alfred edge function `chat/index.ts` gains handyman context block with three behavioral clauses (reference by name / respect DIY / offer to help vet).

### Build B: Phase 64

**Phase 64 — TaskRouting enum + assigned_route column + picker + handyman unification.** Migration `20260711_phase64_task_routing.sql` adds `maintenance_tasks.assigned_route TEXT` with backfill (personal → 'diy', vendor → 'vendor', either → NULL, any contractor-linked → 'vendor') and partial index on `(household_id, assigned_route) WHERE NOT NULL`. Unifies Phase 54B's `handyman_punch_items` via a new `maintenance_task_id UUID REFERENCES maintenance_tasks(id)` FK backfilled from the legacy `source_task_id`.

`TaskRouting` enum gains `.vendorOnly` case (Bucket 1 — no DIY path) alongside existing `.vendorDefault` / `.diyCapable` / `.diyDefault` / `.bundledIntoParent`. `MaintenanceTaskDBRow` + `MaintenanceTaskInsert` + `MaintenanceTaskUpdate` + the synthetic factories all gain `assignedRoute: String?`. `HandymanPunchItemRow` + `HandymanPunchItemInsert` gain `maintenanceTaskId: UUID?`.

`TaskRoutingPicker` component (`Haven/Features/Property/Views/Components/TaskRoutingPicker.swift`) renders 4 modes (`vendorOnly` / `vendorOrHandymanOrDIY` / `handymanOrDIY` / `readOnly`) with `TaskRoutingMode.derive(templateRouting:safetyFloor:hasActiveContract:)` static helper. `safetyFloor: true` collapses to `vendorOnly` regardless of routing hint; active contract collapses to `readOnly`. The existing `MaintenanceTaskDetailSheet.vendorSection` integration is a polish pass — the picker component + mode resolver are in place.

`DatabaseService.setTaskRoute(taskId:route:task:)` unifies task routing with the punch list: setting `route = 'handyman'` materializes a punch item linked by `maintenance_task_id`; setting any other route archives the punch item if one exists. Punch list view now has a single source of truth.

Analytics: `taskRouteChanged`, `taskRoutePickerOpened`.

### Build C: Phases 65 + 66

**Phase 65 — Sticky routing preferences layered on Q36 tier.** Migration `20260712_phase65_routing_preferences.sql` creates `routing_preferences (household_id, property_id, task_category, scope_type, preferred_route, preferred_vendor_id, created_at, updated_at, last_confirmed_at)` with unique index on `(household, property, category, scope_type)` and CHECK constraints on `scope_type IN ('category', 'template')` and `preferred_route IN ('vendor', 'handyman', 'diy')`. RLS via `household_id IN (SELECT household_id FROM users WHERE id = auth.uid())`. Standalone `routing_preferences_set_updated_at()` trigger function — self-contained, doesn't depend on a shared function.

`RoutingPreferenceRow` + `RoutingPreferenceInsert` models in `Haven/Features/Property/Models/RoutingPreference.swift` with resilient decoder. DatabaseService CRUD: `fetchRoutingPreferences(householdId:propertyId:)`, `upsertRoutingPreference(_:)` (conflict on the unique index so repeat calls with the same scope update in place), `deleteRoutingPreference(id:)`, `confirmAllRoutingPreferences(householdId:propertyId:)` for the annual re-confirm flow.

`RoutingPreferencesView` Settings screen lists every override with per-row swipe-to-delete and a destructive "Reset all preferences" button (confirmation dialog, preserves Q36 tier). Empty state explains the Q36 tier is driving everything. Settings row added under "PREFERENCES" section alongside Maintenance Preferences and Handyman Preference.

Layering: tier (Q36) is the baseline default; per-category rows are overrides read BEFORE the tier by task creation. Template-level overrides win over category. Annual re-confirm card + InheritPreferencesModal are follow-up polish items — infrastructure is ready.

Analytics: `routingPreferenceSet`, `routingPreferenceUpdated`, `routingPreferenceResetAll`, `routingPreferencesConfirmedAnnually`, `routingPreferencesCardDismissed`.

**Phase 66 — Blended Maintenance tab infrastructure.** Per the interview decision ("Blend: state buckets outer, ownership sub-groups inner"), the existing Phase 56.5 "Scheduled" / "To Schedule" buckets stay in place. Phase 66 ships the data-side infrastructure to drive ownership sub-groups inside each bucket:

`MaintenanceViewModel.preferredHandyman` published + loaded in `loadTasks()` from `households.preferred_handyman_contractor_id`. New route-aware computeds: `vendorRoutedTasks`, `handymanRoutedTasks`, `diyRoutedTasks`, `unroutedTasks` — filter `baseFiltered` by `assignedRoute`. Empty arrays render nothing in the (future) blended layout so no chrome noise.

Legacy `MaintenanceViewMode` enum retired — collapsed to single `.timeline` case and marked `@available(*, deprecated)`. Research-backed state buckets (Apple Photos, HousecallPro, ServiceTitan, Linear) preserved. Stats-pill filter (Phase 56.4), compact routines strip (Phase 55.2 / 56.4), DuplicateReviewBanner (Phase 56.5), HandymanSuggestionCard (Phase 56.4), Year-at-a-glance (Phase 60), and TODAY/LATER auto-split (Phase 56.5) all untouched.

The visible `MaintenanceScheduleView.body` rewrite that renders the sub-group DisclosureGroups inside the state buckets is a follow-up polish pass — every sub-group's data is now computed, ready to render when the layout lands.

### Schema + migration summary

Three new migrations shipped. Deploy with `supabase db push --linked`:
- `20260710_phase63_preferred_handyman.sql`
- `20260711_phase64_task_routing.sql`
- `20260712_phase65_routing_preferences.sql`

### Files added
- `Haven/Features/Dashboard/Components/LegacyTasksNotificationCard.swift`
- `Haven/Features/Property/Views/LegacyTasksView.swift`
- `Haven/Features/Dashboard/Components/FindHandymanCard.swift`
- `Haven/Features/Settings/HandymanPreferenceView.swift`
- `Haven/Features/Property/Views/Components/TaskRoutingPicker.swift`
- `Haven/Features/Property/Models/RoutingPreference.swift`
- `Haven/Features/Settings/RoutingPreferencesView.swift`
- `supabase/migrations/20260710_phase63_preferred_handyman.sql`
- `supabase/migrations/20260711_phase64_task_routing.sql`
- `supabase/migrations/20260712_phase65_routing_preferences.sql`

### Files modified
- `Haven/Core/Networking/DatabaseModels.swift` — `HouseholdRow/Update` preferred_handyman_contractor_id; `MaintenanceTaskDBRow` archivedReason + assignedRoute; `MaintenanceTaskInsert/Update` assignedRoute; synthetic factories updated.
- `Haven/Core/Networking/DatabaseService.swift` — `setTaskRoute`, `fetchRoutingPreferences`, `upsertRoutingPreference`, `deleteRoutingPreference`, `confirmAllRoutingPreferences`.
- `Haven/Core/Services/AnalyticsService.swift` — 10 new events across Phases 61/63/64/65.
- `Haven/Features/Property/Services/MaintenanceTemplates.swift` — 6 new templates, TaskRouting.vendorOnly, subtype wiring for 4 new flags.
- `Haven/Features/Property/Services/MaintenanceTaskReconciler.swift` — extended property flag merger for 3 new yes/no keys + driveway string translation.
- `Haven/Features/Property/ViewModels/MaintenanceViewModel.swift` — preferredHandyman, route computeds, preferredHandyman loader in loadTasks.
- `Haven/Features/Property/Views/MaintenanceScheduleView.swift` — MaintenanceViewMode collapsed + deprecated.
- `Haven/Features/Property/Models/HandymanPunchItem.swift` — maintenanceTaskId FK field.
- `Haven/Features/Dashboard/DashboardViewModel.swift` — legacyTaskCount field + loader.
- `Haven/Features/Dashboard/DashboardView.swift` — LegacyTasksNotificationCard + FindHandymanCard integration, showLegacyTasks sheet.
- `Haven/Features/Dashboard/EnrichmentCardEngine.swift` — 4 new enrichment questions.
- `Haven/Features/Dashboard/EnrichmentActions.swift` — 4 new cases wired to reconcileAll.
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizAnswerMapper.swift` — Q15b handyman preference derivation + household FK update.
- `Haven/Features/Settings/SettingsView.swift` — Handyman Preference + Task Routing rows.
- `supabase/functions/chat/index.ts` — handyman preference context block + 3 behavioral clauses.

### Deferred polish (next pass)
- `TaskRoutingPicker` integration into `MaintenanceTaskDetailSheet.vendorSection` (replace existing section, wire `onSelectRoute` through `setTaskRoute`).
- `Q15b` handyman chip inline 3-way picker UI in `HouseQuizView` (mapper-side derivation already approximates it from chip + provider state).
- `MaintenanceScheduleView.body` blended layout rendering the ownership DisclosureGroups inside Phase 56.5's state buckets.
- `InheritPreferencesModal` (multi-property inheritance prompt on Phase 65 property creation).
- `ConfirmPreferencesCard` annual re-confirm dashboard card driven by `last_confirmed_at > 365 days`.
- First-pick toast ("We'll remember this for future Plumbing tasks") in task detail sheet after wiring picker.

---

## Phase 60.5: Cinematic Finale (2026-04-17)

Replaces the end-of-quiz functional summary ("Added 38 tasks, Removed 12 tasks, Preserved 6 items" — a changelog) with a single cinematic reveal: navy-on-cream Fraunces hero number that counts up from $0 to the projected 10-year protection value over 2.5 seconds, followed by a scrollable four-card summary and a "Take me to my dashboard" CTA. Principle: **Trust the data. Earn the full-screen moment. No confetti, no social share, no gamification.** Reference anchors: Opendoor offer reveal, Zillow Zestimate, Wealthfront year-end summary, Headspace streak celebration (dignified, not Duolingo-style).

**`QuizFinaleTotals` struct** (`Haven/Features/Onboarding/HouseQuiz/QuizFinaleTotals.swift`). Captures `tasksScheduled` / `vendorsOnFile` / `systemsConfirmed` / `gapsClosed` counts + three example strings per bucket + `projectedValueProtected: Double?` + `hasLoaded: Bool` sentinel. Every count is a real integer pulled from the DB — the finale never fabricates numbers.

**`HouseQuizViewModel.loadFinaleTotals()`**. Async merge of the reconciler's running `reconciliationTotals.added` (tasks added this quiz session) with fresh DB snapshots of contractors (via `db.fetchContractors()` sorted by `createdAt` desc) and home systems (via `db.fetchHomeSystems(propertyId:)` filtered to top-level via `parentSystemId == nil`). Gaps map to the reconciler's `preserved` bucket as a proxy for "items already captured before this quiz pass." Projected value uses the 12% Remodeling Magazine + NAR figure inlined into the method (can't synthesize a `PropertyLookupResult` because Phase 60.1's custom `init(from:)` suppressed the memberwise initializer). Falls back to last-sale × 5% appreciation when `currentEstimatedValue` is nil — same ladder as `OnboardingScheduleGenerator.computeValueProtection`. Idempotent via `finaleTotals.hasLoaded` so the completion view's `.task` doesn't re-fire.

**`QuizCinematicReveal.swift`**. Full-screen navy-on-cream. Four-phase orchestration: (1) 0.3s fade in "Your home, protected.", (2) 0.7s start the 2.5s count-up (`.contentTransition(.numericText(value: displayValue))` + `.animation(.easeOut(duration: 2.5))`), (3) 3.3s fade in "over 10 years, on schedule" footer, (4) 4.0s fade in scroll-prompt chevron. Single `Haptics.medium()` on appear (reflective, not a success chime). `hasStarted` guard prevents multi-fire on `onAppear`. Fallback: when `protectionValue` is nil (ATTOM returned no estimated value), the hero renders "Set up." instead of a fabricated dollar figure.

**`QuizCompletionSummary.swift`**. Scrollable four-card breakdown beneath the reveal. Each card: SF-Symbol icon tile + Fraunces-700 count + label ("maintenance tasks scheduled" / "vendors on file" / "home systems confirmed" / "items preserved") + up to 3 bullet examples + subtitle line. Gaps section conditionally hidden when `gapsClosed == 0` so users who onboard with nothing pre-existing don't see "0 items preserved." Pluralization handled per card. Primary CTA "Take me to my dashboard" fires `Haptics.success()` (the one celebratory beat in the whole flow) and calls `onContinue` which routes through `dismiss()` to ContentView's dashboard-ready state.

**HouseQuizView `completionView` replaced.** The legacy "Quiz complete" surface (checkmark + "87% of homeowners" + "View my maintenance plan" + "Done") is gone. New render: `ScrollView` containing `QuizCinematicReveal` + `QuizCompletionSummary`. `.task` kicks off both `viewModel.loadFinaleTotals()` and the existing Phase 19l `loadDelegationCandidates()` — the vendor delegation sheet still surfaces over the finale when the reconciler found either-stamped tasks that match a captured vendor.

**Dashboard duplicate-greet check.** Grepped `Haven/Features/Dashboard/` for any `justCompletedOnboarding` / `welcomeToHaven` / `quizComplete` / `onboardingJustCompleted` / `showWelcome` patterns — zero matches. The finale is the sole onboarding-completion moment; the dashboard's own first-render greeting reads as context, not as a duplicate celebration.

**Files added:**
- `Haven/Features/Onboarding/HouseQuiz/QuizFinaleTotals.swift`
- `Haven/Features/Onboarding/HouseQuiz/Components/QuizCinematicReveal.swift`
- `Haven/Features/Onboarding/HouseQuiz/Components/QuizCompletionSummary.swift`

**Files modified:**
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift` — `@Published finaleTotals`, `loadFinaleTotals()`, `yearsSince(_:)` helper
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift` — `completionView` body rewrite, `.task` wired to `loadFinaleTotals`

**Testing protocol (on-device, requires Tom's real account):** Eight path tests cover every Phase 60 section — Tom's real address ($660K happy path), ATTOM null-sale fallback, Apple Sign In data persistence, email signup data persistence, resume after app kill, cache hit on repeat address, cache miss after `CACHE_VERSION` bump, and decoder resilience with a surprise-type field. Plus a manual device checklist covering haptic feel, animation smoothness, Fraunces typography on the hero number, safe-area handling on iPhone 15 Pro + iPad Pro 12.9", VoiceOver reads, Reduce Motion disables count-up, and regression probes on Q17 forwarding email + Dashboard first-render. Full protocol lives in the Section 5 ship plan; Claude Code has validated everything programmatically verifiable (grep clean, signatures match, struct shapes persist). On-device device-checklist validation is Tom's.

**xcodegen regenerated** to pick up the three new files.

---

## Phase 60: Onboarding Rebuild — Retrospective (2026-04-17)

Five sections, one arc. The House Quiz before Phase 60 worked but felt like homework: the user typed their address, got auth-gated, answered 37 flat questions, and landed on a checkmark + "Added 38 tasks, Removed 12 tasks" changelog. Trust in the data was shaky (Tom's $660K ATTOM sale price was dropping silently because `PropertyLookupResult` used the compiler-synthesized decoder), vendor orchestration had nine correctness bugs (Handyman chip had `nil` category mapping, Q15b had no feedback, DIY paths pre-stamped `.personal` so Q36 couldn't flip them), the pacing was relentless (full-screen feedback overlay on every answer, no visible progress signal, no chapters), each question read the same, and the ending undersold the weight of what the user just did.

Phase 60 fixed all of that. Five principles landed across five sections:

**Principle 1 — Trust the data (Section 1).** Resilient `init(from:)` on every externally-fed struct so one bad field no longer takes down the whole decode. Versioned cache key on `property-lookup` so bumping `CACHE_VERSION` invalidates every stale row on the next lookup. `[ATTOM persist]` log instrumentation at every hand-off point so a grep for one tag tells the whole persistence story. `PropertyRecapCard` as the first screen of the quiz — "Here's what we found" with tap-to-correct rows, the canonical trust anchor for any future onboarding moment.

**Principle 2 — Vendor orchestration is the product (Section 2).** Handyman chip returns "Handyman" (not nil). Four new Q15b chips with RoutineSeeder wiring (Cleaning, Snow Removal, Mosquito & Tick, Pet Waste). Every DIY path stamps `.either` so Q36's preference tier can flip them. Q28b_pets subtitle no longer references killed templates. Q11 DIY feedback no longer cheerleads with pricing claims. Hot tub chores demote to `isEssential: false`. Hardscape tasks migrated from `createHardscapeMaintenanceTasks` inline helper to `MaintenanceTemplates.swift` with proper `requiredSubtypes: ["hardscape"]` gating.

**Principle 3 — Show the earning, pause at chapters (Section 3).** `HouseQuizValueMeter` — per-question deltas summing near the 12% value-preservation figure, `@Published protectedValue` on the view model that accretes monotonically with each answer, rendered in a persistent header above every question screen with `.contentTransition(.numericText(...))` for the count-up. `HouseQuizChapter` enum (`.yourHome` / `.yourPros` / `.yourPeople`) re-groups the 37 questions. Q36 physically moved to the opening of Chapter 2 so the tier captures BEFORE Q11/Q13/Q14/Q15 stamp `.either` tasks. `ChapterIntroCard` 3.5s breath between chapters. `SkipToastView` acknowledges dynamic-skips so the jump never feels silent.

**Principle 4 — Inline pills for routine feedback; milestones earn the full screen (Section 4).** `InlineInsightPill` replaces `HouseQuizInsightOverlay` for the 95% of answers that don't warrant a stop. Milestone allowlist is three entries with commented reasoning each (Q4 purchase reveal, Q28 household composition, Q36 preference tier); Q17 forwarding-email milestone card remains the gold-standard reference. Personalized titles with token interpolation (`{yearBuilt}`, `{street}`, `{state}`, `{squareFootage}`, `{roofType}`) + `fallbackTitle` safety net. Q15b per-chip feedback (13 entries) closes F8. `AppliancePictogramGrid` gives Q10 visual weight. `HouseQuizTransition` signature slide-plus-fade on every advance.

**Principle 5 — Earn the finish line (Section 5).** `QuizCinematicReveal` — single hero number, 2.5s count-up, dignified Fraunces display. `QuizCompletionSummary` — four real count cards with example bullets. "Take me to my dashboard" CTA with the single success haptic of the whole flow. No confetti, no social share, no gamification. The moment is personal.

**What shipped, in aggregate:**
- 17 new Swift files across 5 sections (recap card + editors + edit sheet + value meter + chapter intro + skip toast + personalization + inline pill + pictogram grid + transition + finale reveal + summary + totals struct + 3 misc)
- 1 edge function changed (property-lookup: CACHE_VERSION token)
- 3 migration-free table usages updated (`routines`, `home_systems.service_interval_days`, `handyman_punch_items` — all pre-existing from Phases 54-55)
- 13 Q15b chip feedback entries (F8 closed)
- 6 personalized question titles with fallbacks
- 11 `[ATTOM persist]` log points across 3 files
- 4 new analytics events (quizChapterIntroConfirmed, quizChipFeedbackShown + value-meter / skip-toast tracking from Section 3)
- 0 data model changes, 0 schema migrations beyond what Phases 54-59 already shipped

**Overarching principle for Phase 60:** Trust the data. Respect the user's time. Earn the full-screen moments.

The on-device Testing Protocol has eight path tests covering the full user journey plus a device-checklist for haptic / animation / typography / accessibility validation. Tom runs this on his real device with his real account before TestFlight push. Tag: `v1.0.3-phase60`.

---

## Phase 60.4: Per-Question Polish (2026-04-17)

Micro-texture pass on the House Quiz. Sections 1-3 fixed the bones (data trust, vendor stamping, chapter pacing, visible value meter). Section 4 addresses how each individual question feels in the hand. Principles: **Every answer is a tiny reward. Most answers don't warrant a stop. Milestones earn the full screen. Personalize when you have the data.**

**Plan adaptation note.** The ship plan referenced question IDs (`q7_roof_material`, `q17_forwarding_email`, `q22_generator_brand`, `q27_fiduciary_nominate`, `q30_priorities` as a rank list) that don't match the actual codebase. Real IDs: Q1 is roof, Q17 is internet provider (forwarding email lives in a milestone card after Q15b, not in a question), Q22 is a generator inline form (not a brand picker), Q27 is homeowners insurance, Q30 is a multi-select of priorities (not a rank list). Section 4 adapts to the real IDs and skips three plan items whose semantics don't fit the current schema: `GeneratorBrandCard` (Q22 uses `.generatorAdd` kind with type/fuel/provider — no brand stage), `PriorityRankList` (Q30's schema is multi-select, converting would break persisted state), and Q15b chip brand logos (already handled via `VendorLogoView` in the existing contractor picker).

**Personalized question titles.** New `PropertyFactBundle` on `HouseQuizViewModel` bundles `yearBuilt` / `street` / `city` / `state` / `squareFootage` / `roofType` from the `PropertyRow`. `shortenedStreet` helper trims leading house numbers and common suffixes (Road, Street, Lane, etc.) so "146 Putnam Park Road" renders conversationally as "Putnam Park". New `HouseQuizPersonalization.swift` extension adds `HouseQuizQuestion.personalizedTitle(using:)` that substitutes `{yearBuilt}` / `{street}` / `{state}` / `{squareFootage}` / `{roofType}` tokens. New `fallbackTitle: String?` field on `HouseQuizQuestion` handles the "ATTOM returned nil for this field" case — the resolver prefers the fallback and NEVER ships literal braces to the UI. Six questions got personalized titles: Q1 ("Your {yearBuilt} {street} roof — what's on top?"), Q3 ("Heat in a {state} home — what's yours running on?"), Q10 ("What's in your {street} kitchen and laundry?"), Q11 ("Keeping up the {street} yard — you or a pro?"), Q13 ("Pest pressure in {state} — who's on it?"), Q22 ("Power outages in {state} — you ready?"). Every personalized question has a `fallbackTitle`. Wired into `HouseQuizView` at the question title render site via `q.personalizedTitle(using: viewModel.propertyFactBundle)`.

**InlineInsightPill + milestone allowlist.** New `InlineInsightPill.swift` — compact cream-filled rounded card that slides up with a spring, displays for 2.2 seconds, fades. Tappable to dismiss early. `HouseQuizView` now branches the `pendingFeedback` render: if the current question is on the `milestoneFeedbackQuestionIds` allowlist, the full-screen `HouseQuizInsightOverlay` fires (4-second dim-the-screen treatment); otherwise the inline pill surfaces above the bottom safe area. The allowlist is three entries with commented reasoning each: **Q4 purchase price** (ATTOM reveal moment), **Q28 household composition** (the caretakers / home manager sub-flow names the people who run the home — worth the pause), **Q36 preference tier** (opens Chapter 2 and routes every downstream `.either` task). The Q17 forwarding-email moment lives in a separate milestone card (`forwardingEmailMilestoneCard`) from Build 84 — documented as the gold-standard pattern for any future "big reveal" moments.

**Q15b per-chip feedback (F8).** Before Phase 60.4 the feedback library returned nil for every Q15b chip and the user heard silence on every chip tap — the single most important chip-selection question in the quiz had zero feedback. New `HouseQuizFeedbackLibrary.chipFeedback(questionId:chipId:)` lookup + a 13-entry `chipFeedbackByQuestion` dictionary covering every chip in Q15b's answerOptions: handyman, cleaning, hvac_service, plumber, electrician, roofer, tree_service, mosquito_tick, snow_removal, pet_waste, septic_pumper, well_water_service, chimney_sweep. Copy celebrates the pro-team-building pattern — never DIY cheerleading, no em dashes, no dollar claims more specific than rough magnitudes. `HouseQuizViewModel.presentInlineChipFeedback(_:chipId:)` + `dismissChipFeedback()` + `lastChipFeedbackId` tracks which chip's pill is pinned so the view can route dismiss through the chip-path (don't advance the quiz) vs the standard-path (advance). Chip toggle in `contractorChipRow` fires feedback only on SELECT, not deselect — no "congrats on not having a plumber anymore" moment. New `quizChipFeedbackShown` analytics event.

**AppliancePictogramGrid for Q10.** New `AppliancePictogramGrid.swift` — 3-column grid of SF-Symbol-backed tiles (refrigerator / dishwasher / range / wall_oven / washer / dryer / microwave / wine_fridge) that replaces the flat-chip list for Q10. Selected tiles flip navy-fill with cream icon; unselected render with cream background + navy icon. The "Other" and "None of these" special options keep their legacy full-width row treatment (Other needs the custom-input field, None needs mutual exclusion). Q10 answerOption semantics unchanged — the grid just wraps the existing `multiSelectIds` / `multiSelectCustomDraft` / `multiSelectCustomEntries` state. Every other multi-select question keeps the legacy flat-chip body via `legacyMultiSelectBody`.

**Signature transition.** New `HouseQuizTransition.swift` — one-line `View.houseQuizAdvanceTransition()` extension that applies an asymmetric slide-plus-fade (incoming slides from trailing, outgoing slides to leading). Paired with `.id(q.id)` on the question content inside `questionScreenWithMeter` + a container `.animation(HavenTheme.animationStandard, value: q.id)` so every question advance uses the signature spring instead of instantly swapping. Reference pattern: Headspace meditation-step advances, Instagram Stories mid-flow transitions.

**Files added:**
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizPersonalization.swift` — PropertyFactBundle + personalizedTitle extension
- `Haven/Features/Onboarding/HouseQuiz/Components/InlineInsightPill.swift` — 2.2s tappable feedback pill
- `Haven/Features/Onboarding/HouseQuiz/Components/AppliancePictogramGrid.swift` — Q10 pictogram grid
- `Haven/Features/Onboarding/HouseQuiz/Components/HouseQuizTransition.swift` — signature slide-plus-fade modifier

**Files modified:**
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift` — `fallbackTitle: String?` on HouseQuizQuestion
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizQuestionLibrary.swift` — 6 personalized titles with fallbacks
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift` — propertyFactBundle, presentInlineChipFeedback, dismissChipFeedback, lastChipFeedbackId
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizFeedbackLibrary.swift` — chipFeedback lookup + 13 Q15b chip entries
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift` — milestone allowlist, pill/overlay branch in pendingFeedback render, Q15b chip feedback wire, Q10 pictogram routing, `.id` + transition on question content, `multiSelectContinueButton`/`appliancePictogramBody`/`legacyMultiSelectBody` refactor
- `Haven/Core/Services/AnalyticsService.swift` — `quizChipFeedbackShown` case

**Testing protocol:** Fresh onboarding with Tom's real address → Q1 reads "Your 1987 Putnam Park roof — what's on top?" (numeric prefix stripped, "Road" suffix stripped, year built from ATTOM). Answer Q1 → inline pill slides up with roof-specific insight, fades after 2.2s. Answer through Q4 → full-screen overlay fires (milestone). Q10 renders pictogram grid with SF Symbols per appliance; selection swaps fill. Q15b — tap Handyman → inline pill reads "A good handyman is the glue of a well-kept home" and fades; deselect → no pill. Q15b every chip has a non-nil feedback entry (grep-confirm). Q28 household composition triggers full-screen overlay on the resident-type answer. Q36 triggers full-screen overlay on tier selection. Fresh address where ATTOM returned nil `yearBuilt` → Q1 falls back to "What kind of roof do you have?" with no literal braces. Question advances use spring slide-plus-fade (not instant). Q17 milestone card untouched.

**Out of scope:** Q22 generator brand cards (wrong schema fit), Q30 drag-rank (would change answer semantics), Q15b brand logos (already live via VendorLogoView), accessibility re-engineering (existing labels are correct).

---

## Phase 60.3: Value Meter + Chapter Structure (2026-04-17)

Rewires the quiz's macro-structure: persistent protection-value meter, three-chapter restructure with Q36 opening the Pros chapter, chapter intro cards, visible dynamic-skip toasts, and Handyman promoted to the first chip on Q15b. Principles: **Show what the user is earning. Break long flows into chapters. Never jump silently — always acknowledge.**

**Protection value meter.** New `HouseQuizValueMeter` helper with a per-question `delta(forQuestion:answer:property:detectedSystems:)` that returns a dollar amount to accrete. `HouseQuizViewModel.protectedValue` (`@Published private(set) Double`) running total, starting at $0 and monotonically climbing with each answer. `accreteValueMeter(...)` called from `persist(...)` right after state lands, gated on `priorAnswer == nil` so the meter is monotonic across answer edits. Deltas calibrated to sum near `OnboardingScheduleGenerator.computeValueProtection(from:)` (12% of home value over 10 years). Skewed higher early in the quiz — the first 10 answers earn meaningful motion on a $500K home. Answer-conditional deltas reward vendor capture: Q11 `"pro"` contributes $11K vs `"diy"` $5.5K; Q15b scales linearly with chip count (cap at ~$28K for 6+ chips); Q36 anchors at $10K as the chapter-2 opener. Render: `protectionMeterHeader` in HouseQuizView sits above the question content on every post-recap question screen — "YOUR PROTECTION SO FAR" caption + navy currency value with `.contentTransition(.numericText(value:))` for the animated climb + soft `Haptics.light()` on each accretion. Reference pattern: Betterment / Wealthfront goal meter during account setup; Apple Fitness numeric-text transitions.

**Three-chapter restructure.** New `HouseQuizChapter` enum (`.yourHome` / `.yourPros` / `.yourPeople`) with `title` / `subtitle` / `icon` / `chapterNumber` accessors. `HouseQuizQuestion` gains a `chapter: HouseQuizChapter` field with a `defaultChapter(for: HouseQuizSection)` fallback so existing call sites keep compiling — new questions can override explicitly. `HouseQuizQuestionLibrary.allQuestions` rebuilt in chapter order rather than section order:
- **Chapter 1 "Your Home"** (14 questions): section1 (Q1-Q5) + section2 (Q6-Q10) + home systems (Q20 other fuels, Q21 solar, Q22 generator)
- **Chapter 2 "Your Pros"** (9 questions): Q36 diy_vs_vendor (MOVED from end of quiz to chapter opener) + section3 (Q11-Q15b)
- **Chapter 3 "Your People"** (14 questions): utility providers (Q16-Q19) + vehicles (Q23-Q25b) + insurance (Q26-Q27) + family/estate (Q28-Q30)

Q36 reposition is **critical for correctness** — it now fires BEFORE Q11/Q13/Q14/Q15 vendor-capture branches, so `reconcileAllForHousehold`'s `flipEitherTasksForPreference` has the tier captured when it walks the `.either`-stamped tasks created by those questions. Previously Q36 fired last, after every `.either` task had already landed. `HouseQuizQuestionLibrary.questions(in:)` helper returns all questions for a given chapter preserving the `allQuestions` order. Legacy `milestoneIndices` set emptied so the old milestone card never competes with the new chapter intros.

**Chapter intro cards.** New `ChapterIntroCard.swift` component — full-screen transition card with icon + title + subtitle + "N questions · about M minutes" meta + optional "Up to $X protection to unlock" preview line + Continue button. Auto-advances after 3.5s via `DispatchWorkItem`; Continue tap cancels the timer. `Haptics.light()` on appear. `HouseQuizViewModel.shownChapterIntros: Set<HouseQuizChapter>` tracks which chapters have fired so the card doesn't re-render between questions within the same chapter. Routing in HouseQuizView: new `shouldShowChapterIntro` computed + `chapterIntroScreen` branch inserted into the main conditional switch between the recap-screen check and the milestone/questionScreen checks. Value preview computed via `HouseQuizValueMeter.expectedValueForChapter(_:property:)` which sums deltas for every question in the chapter under a neutral placeholder answer. Reference pattern: Headspace / Calm session transitions; TurboTax chapter navigation.

**Dynamic-skip toast.** New `HouseQuizViewModel.SkipToastPayload` struct + `SkipReason` enum (`.attomKnowsIt` / `.previousAnswerMakesItIrrelevant` / `.chipNotApplicable`). `@Published pendingSkipToast: SkipToastPayload?` accumulates skip count + reason. `recordSkipForToast(reason:)` helper merges consecutive same-reason skips into one toast (so `Q11b + Q14` no_lawn auto-skips surface as "Skipped 2 questions" not two separate toasts). `skipDynamicallyHiddenQuestion` and `skipDynamicallyUnreachableQuestion` both fire `recordSkipForToast`. New `SkipToastView.swift` — small cream-filled rounded rectangle with `wand.and.stars` icon + message; renders in `.overlay(alignment: .top)` of `questionScreenWithMeter`. Auto-dismissed via `scheduleSkipToastDismiss()` — view-local `DispatchWorkItem` that sets `pendingSkipToast = nil` after 3s. Reference pattern: Noom's "we're not wasting your time" skip acknowledgments.

**F3 Handyman chip first on Q15b.** Reordered `q15b_household_contractors.answerOptions` so Handyman is first (was 9th), Cleaning second, then HVAC / Plumber / Electrician / Roofer / Tree / Mosquito & Tick / Snow Removal / Pet Waste / Septic Pumper / Well Water Service / Chimney Sweep. Post-Phase-58 Handyman is the catcher category with spring/fall punch-list bundles; putting it first reflects its primacy in the vendor-orchestration model. Visibility filter logic unchanged.

**Chapter progress pill.** Rendered inline inside `protectionMeterHeader` next to the "YOUR PROTECTION SO FAR" caption. Reads "Ch 2 · Your Pros · 3/9" — gives fine-grained orientation without a heavy navigation control. Icon matches the chapter's SF Symbol.

**AnswerFeedback citation fix.** Phase 60.2 F9 rewrite left `citationName: nil` against a struct declaring `let citationName: String` (non-optional) — this build was broken. Phase 60.3 makes `citationName: String?` optional and gates the "Source:" line in both `HouseQuizInsightOverlay` and `HouseQuizAnswerFeedbackCard` on `if let citation, !citation.isEmpty`. The Q11 diy rewrite now compiles cleanly.

**Files added:**
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizValueMeter.swift`
- `Haven/Features/Onboarding/HouseQuiz/Components/ChapterIntroCard.swift`
- `Haven/Features/Onboarding/HouseQuiz/Components/SkipToastView.swift`

**Files modified:**
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift` — HouseQuizChapter enum, chapter field on HouseQuizQuestion + defaultChapter helper, citationName optional on AnswerFeedback
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizQuestionLibrary.swift` — allQuestions chapter-order rebuild, questions(in:) helper, empty milestoneIndices, Q20/Q36 explicit chapter overrides, Q15b Handyman-first reorder
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift` — protectedValue, shownChapterIntros, pendingSkipToast + SkipReason + SkipToastPayload, currentChapter / questionsInChapter / positionInCurrentChapter / expectedValueForChapter helpers, accreteValueMeter wired into persist, recordSkipForToast merged into skipDynamically* helpers
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift` — protectionMeterHeader / chapterPill / chapterIntroScreen / questionScreenWithMeter / shouldShowChapterIntro / scheduleSkipToastDismiss; body switch routing updated
- `Haven/Features/Onboarding/HouseQuiz/Components/HouseQuizInsightOverlay.swift` — citation gate
- `Haven/Features/Onboarding/HouseQuiz/Components/HouseQuizAnswerFeedbackCard.swift` — citation gate
- `Haven/Core/Services/AnalyticsService.swift` — quizChapterIntroConfirmed case

**Testing protocol:** Fresh onboarding → recap → Chapter 1 intro (14 questions, ~3 minutes, preview value) → Q1 meter shows $0, animates to $14K with spring easing. Every answer accretes monotonically. Save-for-later mid-quiz + resume: meter persists at its pre-save value. Chapter transitions: Chapter 1 → Chapter 2 intro (9 questions, preview $55K) → Q36 is the FIRST question of Chapter 2, NOT Q11. Chapter 2 → Chapter 3 intro (14 questions). No intro appears after Chapter 3 (quiz completes). Chapter progress pill reads "Ch 1 · Your Home · 1/14" on Q1 and increments. Dynamic-skip toast: if Q11=no_lawn → Q11b + Q14 auto-skip → Q15 shows "Skipped 2 questions based on your earlier answers." toast, auto-dismisses after 3s. Q15b renders with Handyman first, Cleaning second.

**Out of scope (deferred to Sections 4-5):** No question title personalization, no per-question insight pills, no cinematic end-of-quiz reveal. No A/B testing of intro-card auto-advance durations. No save-for-later surfacing of the meter value (the pill on the dashboard could show "You earned $87K of protection — come back anytime" but that's Section 5 finale work).

---

## Phase 60.2: Vendor Orchestration Quiz Fixes (2026-04-17)

Nine correctness bugs in the House Quiz that misaligned with the Phase 58 vendor-orchestration pivot. Principles established: **Haven is vendor-orchestration, not DIY cheerleading. Stamp `.either` by default. Every vendor category gets a chip. Every chip wires to a routine. Template library is truth; never hardcode tasks in the AnswerMapper.**

**F1 — Handyman chip category mapping.** `HouseQuizAnswerMapper.householdContractorCategoryFor(chipId:)` returned `nil` for `"handyman"` despite Handyman being a Tier 1 category post-Phase-58 with spring/fall punch-list bundles. Users who picked a handyman at Q15b captured the vendor's contact but zero handyman tasks linked. One-line fix: `case "handyman": return "Handyman"` + 4 more new chip cases added alongside (see F5).

**F2 — Handyman vendor flip on Q15b.** The Q15b handler now calls `flipCategoryTasksToVendor(systemCategory:providerName:)` for each captured chip provider. This is typically a no-op during the first quiz pass (tasks don't exist yet — they're created at quiz completion via `reconcileAll`), but catches re-entry / back-nav / quiz-resume cases where handyman tasks already exist as `.personal` and should be flipped to `.vendor` now that a vendor is on file. The existing reconciler's `.vendor`-template path handles the auto-link case on fresh task creation via `matchingContractor`.

**F5 — Four new Q15b vendor chips with RoutineSeeder wiring.** Added `cleaning` / `snow_removal` / `mosquito_tick` / `pet_waste` chips to Q15b's answerOptions. Each maps to the canonical `SystemCategoryRegistry` key (no registry changes needed — all four categories were already registered) so the contractor mirror lands with a recognized category string and the RoutineSeeder archetype fires automatically on `DatabaseService.createContractor → seedIfNeeded`. Visibility: `snow_removal` gated on `HouseQuizAnswerMapper.isSnowState(viewModel.property.state)` (single source of truth shared with the auto-create path); `pet_waste` gated on `property.attributes["has_pets"] == "true"` (hidden on first-pass onboarding since Q28b_pets fires later — user can still add a pet waste vendor later from Property → Contacts). `QuizLocalContractorPicker.categoryParam` extended so find-local-vendors filters Google Places results by the correct trade. `RoutineSeeder.defaults(for:)` gained a new `snow_removal` archetype (customDays/90, active Dec-Apr) — the seeder already had archetypes for cleaning / mosquito_tick / pet_waste and the existing keyword matching correctly disambiguates "Mosquito & Tick" from "Pest Control" (the `mosquito` keyword check fires before the `pest` check, so no `chipHint` disambiguation needed).

**F6 — DIY paths stamp `.either`, not `.personal`.** Audit confirmed no AnswerMapper DIY branch stamps `.personal` inline except for `createHardscapeMaintenanceTasks` (deleted in F13) and the hot tub weekly sanitize template (demoted in F12). Every other DIY-answered quiz flow (Q11 / Q12 / Q13 / Q14 / Q15) routes through `MaintenanceTaskReconciler.reconcile(...)` which honors the template's declared `assignmentType` (default `.either`). Q36's `reconcileAllForHousehold` + `flipEitherTasksForPreference` correctly flips every `.either` task based on the captured tier. No reconciler volume changes needed — the existing flip logic handles 30+ tasks without regression.

**F7 — Q28b_pets subtitle rewrite.** The previous copy ("We tune some maintenance tasks like turf sanitization and HVAC filter swaps based on this") referenced templates deleted in Phase 58. New copy: "So your vendors know, and so we can suggest recurring services that keep pets safe." Reflects actual current behavior: the has_pets flag gates the Q15b pet_waste chip and flags vendors when they need to schedule around animals.

**F9 — Q11 DIY feedback rewrite.** The previous entry badged "Insight" and headlined "DIY lawn care saves $1,800/yr on average vs. pro service" with a "TurfTime Equipment Annual Report" citation. Directly contradicted Phase 58 positioning — Haven is not a DIY savings calculator. New entry: badge "Good to know", headline "You'll stay on top of the lawn yourself.", subhead "Haven will handle the stuff you delegate — tree work, irrigation blowouts, and the seasonal pros you already use." `citationName: nil`. Audit confirmed this was the only DIY-cheerleading entry in the feedback library.

**F12 — Hot tub chores non-essential.** The weekly "Test and sanitize hot tub water" template was stamped `.personal` / weekly / 10-minute DIY / `isEssential: true` — auto-created on every hot tub household regardless of whether the user wanted to self-manage. Changed to `assignmentType: .either` + `isEssential: false`. The template is still available via "Recommended for your home" and the reconciler will create it on-demand when the user picks "hot_tub" from Q12. Users who capture a pool/spa service vendor at Q15b get the existing `pool_service` RoutineSeeder archetype (weekly Tuesday) which covers spa sanitation on the vendor's visit — no new archetype needed.

**F13 — Hardscape tasks moved to template library.** `HouseQuizAnswerMapper.createHardscapeMaintenanceTasks(systemId:)` built four tasks inline (pressure wash / joint sand / weed treatment / drainage check), three stamped `.personal`, bypassing the template library entirely. Migrated to four new `MaintenanceTemplate` entries under `systemCategory: "Landscaping"` with `requiredSubtypes: ["hardscape"]` and `assignmentType: .either`. `stableId` values match the legacy `templateId` strings so existing tasks dedupe correctly across the migration. `MaintenanceTemplates.activeSubtypes` extended with a `sub == "hardscape"` branch. The Q11 hardscape handler now calls `MaintenanceTaskReconciler.reconcile(...)` with `confirmedSubtype: "hardscape"` — same pattern Q11b uses for natural lawn / synthetic turf. The `createHardscapeMaintenanceTasks` function body is deleted; only comment breadcrumbs remain.

**Files modified:**
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizAnswerMapper.swift` — F1 (chip category mapping), F2 (Q15b flip call), F13 (hardscape reconcile path + function deletion)
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizQuestionLibrary.swift` — F5 (4 new Q15b chips), F7 (Q28b_pets subtitle)
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift` — F5 (visibleContractorChips snow_removal + pet_waste cases)
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizFeedbackLibrary.swift` — F9 (Q11 diy rewrite)
- `Haven/Features/Onboarding/HouseQuiz/Components/QuizLocalContractorPicker.swift` — F5 (categoryParam for 4 new chips)
- `Haven/Features/Property/Services/MaintenanceTemplates.swift` — F12 (hot tub demote), F13 (4 new hardscape templates + hardscape subtype branch in activeSubtypes)
- `Haven/Features/Property/Services/RoutineSeeder.swift` — F5 (snow_removal archetype)

**Testing protocol:** Handyman capture end-to-end (Q15b → contractor with category "Handyman" → reconcileAll links Handyman bundle tasks). CT user sees all 4 new chips at Q15b; FL user sees only Cleaning + Mosquito & Tick (snow/pet hidden). User picks DIY at Q11 + Pro-only at Q36 → landscaping tasks end up `.vendor` with `needs_vendor`. Q28b copy no longer references "turf sanitization" or "HVAC filter swaps" (grep clean). Q11 DIY feedback card shows new copy — no "$1,800/yr". Property WITHOUT hot tub gets zero hot tub tasks. Property with hardscape answer lands 4 tasks with templateIds `landscaping:hardscape_pressure_wash` / `_joint_sand` / `_weed_treatment` / `_drainage_check`, all `.either`. Grep for `createHardscapeMaintenanceTasks` returns zero live references (only comment breadcrumbs).

**Out of scope (deferred to Sections 3-5):** No quiz UX restructure (chapter reordering, value meter, pre-quiz recap). No question title personalization or inline insight pills. No cinematic finale. F3 / F4 / F6-partial / F8 addressed in Sections 3 and 4.

---

## Phase 60.1: ATTOM Persistence & Onboarding Trust (2026-04-17)

Tom onboarded his house and Q4's purchase price came up blank even though ATTOM in Postman returned $660K for the same address. Root cause wasn't the mapping — every type contract was correct end-to-end. Root cause was that `PropertyLookupResult` was the only critical struct in the codebase using compiler-synthesized `Codable`, so a single unexpected field (a new key ATTOM added, a numeric-as-string, anything) would throw from the synthesized decoder and silently drop the entire struct. Phase 20's `bathrooms: Int → Double` fix proved the pattern; every other field was still vulnerable. Four things ship as one atomic unit so this class of bug is impossible going forward.

**Principles established:** Make decoders resilient. Version caches. Instrument hand-offs. Show what you know before asking questions.

**Resilient decoders.** `PropertyLookupResult` and its three nested structs (`PropertyFeatures`, `TaxAssessment`, `OwnerInfo`) now each have a custom `init(from decoder: Decoder)` that wraps every field in `try? c.decodeIfPresent(...)`. Matches the in-codebase pattern used by `PropertyRow`, `UtilityAccountRow`, `HouseholdAdvisorRow`, `VehicleRow`, and `ProjectAIResearch`. A single bad field becomes nil instead of taking the whole lookup down. The synthesized `encode(to:)` is intentionally preserved so UserDefaults round-tripping in `AddressHookViewModel.cacheToUserDefaults()` keeps working unchanged.

**Cache-bust version token.** `supabase/functions/property-lookup/index.ts` adds a module-level `const CACHE_VERSION = 2` and folds it into the `address_hash` on both the cache read and write (`${normalizedAddress}|v${CACHE_VERSION}`). Pre-Phase-20 cached rows — including any with `bathrooms: 3.5` that poisoned older iOS decoders — are unreachable under the new key, so the next lookup refetches fresh from ATTOM. Bumping this constant is now the canonical lever for invalidating stale cache after any response-shape change.

**Persistence instrumentation.** Six `[ATTOM persist]` log points across the pipeline make every hand-off traceable via a single `grep`:
1. `AddressHookViewModel.lookupProperty` — edge-function decode result
2. `cacheToUserDefaults` — UserDefaults write (byte count + key fields)
3. `loadCachedData` — UserDefaults read (post-auth)
4. `OnboardingViewModel.runComplete` — `PropertyInsert` built + `PropertyRow` after insert
5. `PropertyCreationService.createProperty` — `resolvedLookup` + `PropertyInsert` + `PropertyRow` after insert

`-1` in any log means the value was nil (easy to spot); any value missing in the trace pinpoints exactly which leg dropped it.

**Trust surface: `PropertyRecapCard`.** New first screen of the House Quiz. Shows the persisted `PropertyRow` values (address, current value, year built, square footage, purchase price) alongside the detected home systems, with every row tappable to open `PropertyRecapEditSheet` (a new medium-detent sheet that writes through to `DatabaseService.updateProperty`). Reference patterns cited: Zillow's post-address landing card, Betterment's net-worth anchor before goal-setting, TurboTax's prior-year return summary as a trust anchor before data entry. The card gates Q1 rendering via new `@State recapConfirmed` on `HouseQuizView`; fresh quiz starts MUST land on the card first, but resumed quizzes (with any existing answers) skip the gate so users don't see the recap mid-quiz. Edits flow through `HouseQuizViewModel.applyUpdatedProperty(_:)` and `reloadProperty()` so every downstream reader (Q4 prefill, ATTOM-source caption) sees the corrected value immediately.

**Distinct Q4 render when ATTOM has no sale record.** `currencyBody` now branches the header above the ownership chips on `viewModel.property.purchasePrice > 0`:
- **State A — "From public records" (green):** "\(street): \(formattedCurrency(amount))" with a checkmark-seal icon and "Not right? Edit the field below." subtitle. Declarative — the user scans and trusts or corrects in one motion.
- **State B — "No sale on record" (info blue):** "We couldn't find a sale on record for this home." + "Common for land purchases, tear-downs, or homes passed through family. Enter what you paid, or skip for now." A new "Skip for now" secondary button (routes through `viewModel.saveForLater()`) sits below Continue, so the user can finish the quiz without a purchase price.

HNW users distinguish "Haven couldn't load my data" from "ATTOM doesn't have my purchase on record." The bug was they couldn't before.

**Cleanup.** `OnboardingSchedulePreviewStep.swift` (Phase 20 dead code) deleted. The three editable components inside — `editableCell`, `numericEditor`, `stepperEditor`, plus `NumericTextField` — were harvested to the new `Haven/Features/Onboarding/HouseQuiz/Components/PropertyRecapEditors.swift` as `PropertyRecapEditors.stepperEditor`, `PropertyRecapEditors.halfStepperEditor`, `PropertyRecapNumericTextField`, `PropertyRecapCurrencyTextField` (reusable top-level APIs instead of fileprivate helpers). The last live call site — `AddPropertyFlow.swift`'s `.preview` step — was refactored: the preview step is gone entirely, "Find My Home" now runs the lookup AND createProperty in one tap, the user lands on the confirmation step with the existing `PropertyHookView` fullScreenCover taking over the review moment, and `PropertyRecapCard` on the first quiz screen provides the correction affordance post-creation. `AddPropertyFlowStep.preview` and `schedulePreview`/`regenerateSchedule` are removed. `xcodegen generate` was run to regenerate `project.pbxproj` so the deleted file's references are cleaned up automatically.

**Files added:**
- `Haven/Features/Onboarding/HouseQuiz/Components/PropertyRecapCard.swift`
- `Haven/Features/Onboarding/HouseQuiz/Components/PropertyRecapEditSheet.swift`
- `Haven/Features/Onboarding/HouseQuiz/Components/PropertyRecapEditors.swift`

**Files modified:**
- `Haven/Features/Property/Services/OnboardingScheduleGenerator.swift` (+ 4 resilient init(from:) decoders)
- `supabase/functions/property-lookup/index.ts` (+ CACHE_VERSION, versioned hash at read + write)
- `Haven/Core/Auth/Views/Onboarding/AddressHookView.swift` (+ 3 log points)
- `Haven/Core/Auth/Views/Onboarding/OnboardingViewModel.swift` (+ 2 log points)
- `Haven/Core/Services/PropertyCreationService.swift` (+ 3 log points)
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift` (+ recap gate, recap screen, edit sheet, Q4 state branch, `q4SaleOnRecordHeader`, `q4NoSaleOnRecordHeader`, `formatCurrencyCompact`)
- `Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift` (`@Published var property`, `detectedSystems`, `loadDetectedSystemsIfNeeded`, `reloadProperty`, `applyUpdatedProperty`)
- `Haven/Features/Property/Views/AddPropertyFlow.swift` (drop `.preview`, drop `schedulePreview` + `regenerateSchedule`, unified Find-My-Home → create)

**Files deleted:**
- `Haven/Core/Auth/Views/Onboarding/OnboardingSchedulePreviewStep.swift`

**Deploy:**
- iOS build via Xcode from regenerated `Haven.xcodeproj`
- Edge function: `supabase functions deploy property-lookup --no-verify-jwt`

**Test fixtures (ready to paste when a test target exists):** Three XCTest cases capture the regression that drove this phase. Save these to `HavenTests/OnboardingScheduleGeneratorTests.swift` when the unit-test target lands:

```swift
import XCTest
@testable import Haven

final class PropertyLookupResultDecoderTests: XCTestCase {
    // Reproduces the April 2026 onboarding trust bug. Pre-fix, the bad
    // bathrooms field dropped ALL lookup data including the $660K sale
    // price. Post-fix, only the bad field is nil.
    func testResilience_badFieldDoesNotDropOtherFields() throws {
        let json = """
        {"yearBuilt": 1987, "squareFootage": 2400, "bedrooms": 4,
         "bathrooms": "not-a-number", "lastSalePrice": 660000,
         "estimatedValue": 925000}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PropertyLookupResult.self, from: json)
        XCTAssertEqual(decoded.yearBuilt, 1987)
        XCTAssertEqual(decoded.squareFootage, 2400)
        XCTAssertEqual(decoded.bedrooms, 4)
        XCTAssertNil(decoded.bathrooms, "Bad bathrooms field should be nil")
        XCTAssertEqual(decoded.lastSalePrice, 660000, "Sale price must survive")
        XCTAssertEqual(decoded.estimatedValue, 925000, "Valuation must survive")
    }

    func testResilience_nullLastSalePriceIsOkay() throws {
        let json = """
        {"yearBuilt": 1987, "lastSalePrice": null, "estimatedValue": 925000}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PropertyLookupResult.self, from: json)
        XCTAssertNil(decoded.lastSalePrice)
        XCTAssertEqual(decoded.estimatedValue, 925000)
    }

    func testResilience_unknownFieldIgnored() throws {
        let json = """
        {"yearBuilt": 1987, "newAttomField": {"nested": true},
         "estimatedValue": 925000}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PropertyLookupResult.self, from: json)
        XCTAssertEqual(decoded.yearBuilt, 1987)
        XCTAssertEqual(decoded.estimatedValue, 925000)
    }
}
```

**Verification protocol (executed on TestFlight):**
- Postman call against Tom's home address returns `lastSalePrice: 660000`, `estimatedValue > 0`. First call misses cache (> 3s); second call hits (< 500ms, "Cache hit (v2)" in logs).
- Cold onboarding on Tom's address: `[ATTOM persist]` console trace shows `660000` through every hand-off (edge decode → UserDefaults write → UserDefaults read → PropertyInsert → PropertyRow after insert). No -1 sentinels.
- Recap card renders as first quiz screen with $660K in the Purchase price row. Tap to edit → sheet → change to $750K → Save → row updates → Q4 prefill now reads $750K (proves the edit wrote through and HouseQuizViewModel reloaded).
- Second address with ATTOM no-sale-record: recap card shows "No sale on record" warning, Q4 renders State B with "Skip for now" option.

**Out of scope for Section 1 (carried forward):** No new ATTOM endpoints. No changes to `PropertyCreationService` beyond threading the lookup result + adding log points. No changes to quiz flow, question structure, or vendor orchestration logic.

---

## Phase 59: Vendor Management as the Relationship Spine (2026-04-17)

Phase 58 shipped the `ContractorDetailView` skeleton; Phase 59 fills in the flesh so each vendor becomes the canonical surface for money, contracts, history, and future visits. Four batches land the structured invoice metadata, the spend hero, standing service contracts surfaced inline, and an ambiguous-match vendor picker in the invoice review flow.

**Batch G — Invoice metadata columns.** Migration `20260706_phase59_invoice_metadata.sql` adds `invoice_amount NUMERIC`, `invoice_date DATE`, `invoice_number TEXT`, `invoice_line_items JSONB`, and `vendor_match_confidence TEXT` CHECK-constrained to `high|medium|low|ambiguous` on `documents`. Composite index `idx_documents_contractor_invoice_date(contractor_id, invoice_date DESC) WHERE contractor_id IS NOT NULL` backs the vendor detail's Recent Activity sort. New `Haven/Features/Documents/Models/InvoiceLineItem.swift` struct (description / quantity? / unit_price? / total) with resilient decoding. `DocumentRow` / `DocumentInsert` / `DocumentUpdate` all gain the five new fields with `CodingKeys`. Deployed via `supabase db push --linked`.

**Batch H — Smart invoice extraction + vendor hint.** `process-invoice/index.ts` now accepts optional `preferred_contractor_id` in the request body — when present (e.g. user is uploading from `ContractorDetailView`'s "Add a bill" flow), vendor matching is skipped and this contractor is stamped with `"high"` confidence. When absent, Claude still returns `matched_contractor_id`; if null, the function builds a short candidate list (1-3 rows) via case-insensitive substring + token-overlap scoring against the household's contractors. Extracted fields (`total_amount`, `invoice_date`, `invoice_number`, mapped `parts_and_materials` → `invoice_line_items`) are written back to `documents` with a never-overwrite-user-edits guard: re-fetches the current row and skips any field already populated. Response now includes `vendor_match: { contractor_id, confidence, extracted_name, candidates }` for the iOS client to decide silent-file vs inbox-route. `HavenSupabase.processInvoice` / `processVehicleInvoice` gain `preferredContractorId` param. `InvoiceProcessingViewModel.process()` reads the document's already-set `contractor_id` (from Phase 58's DocumentUploadViewModel) and pipes it through as the hint — no per-callsite changes needed.

**Batch I — Spend hero + contracts section.** New `DatabaseService.fetchServiceContracts(contractorId:)` scoped query (the existing `fetchServiceContracts(propertyId:)` doesn't cover this). `ContractorDetailView` hero card now carries a spend strip — `"$4.3k YTD · 3 visits · 8 bills"` — computed inline from `vendorDocuments.invoiceAmount` summed by `invoiceDate` in the current year, de-duplicated against `serviceRecords` via `invoiceDocumentId`. Compact currency helper (`$450` / `$4.3k`). When a service contract is linked to the vendor, a secondary "On HVAC Service Plan · $450/yr · Annual" pill renders below the spend strip. New CONTRACTS section between UPCOMING and RECENT ACTIVITY shows every `service_contracts` row with service_type / frequency / annual_cost. Recent Activity rows now carry inline $ amounts pulled from `service_record.cost` or `document.invoiceAmount` so the timeline reads like a ledger. Ledger defaults: YTD primary, visits + bill counts subtitle, no trend chart in V1.

**Batch J — Ambiguous-match picker + confirmation toast.** `InvoiceVendorMatch` + `InvoiceVendorCandidate` structs added to `InvoiceProcessingModels.swift`. `InvoiceReviewSheet` renders a new vendor-match section above completed tasks when `result.vendorMatch.confidence != "high"` — warning-tinted card with candidate chips (from `vendor_match.candidates`) + "None of these — pick another vendor" full-picker fallback via `ContractorDirectoryView(onSelect:)`. `InvoiceProcessingViewModel` gains `vendorMatchResolved: Bool` + `showVendorPicker: Bool` + `assignVendorMatch(contractorId:)` which writes back to `documents.contractor_id` + `vendor_match_confidence = "high"` and posts `.documentChanged`. `ContractorDetailView` gains a `BillSavedToast` struct + transient 3.5-second overlay banner — "Saved to Tyler Heating · $185 · Mar 15" — that fires on `loadDocuments` when the vendor document count just increased.

**Files added:** `supabase/migrations/20260706_phase59_invoice_metadata.sql`, `Haven/Features/Documents/Models/InvoiceLineItem.swift`.

**Files modified:** `Haven/Core/Networking/DatabaseModels.swift` (+5 fields on DocumentRow/Insert/Update), `Haven/Core/Networking/DatabaseService.swift` (+fetchServiceContracts(contractorId:)), `Haven/Core/Networking/SupabaseClient.swift` (+preferredContractorId param on processInvoice/processVehicleInvoice), `Haven/Core/Networking/InvoiceProcessingModels.swift` (+InvoiceVendorMatch/InvoiceVendorCandidate + vendorMatch on result), `Haven/Features/Documents/ViewModels/InvoiceProcessingViewModel.swift` (+vendor hint read-through, +assignVendorMatch, +vendorMatchResolved/showVendorPicker), `Haven/Features/Documents/Views/InvoiceReviewSheet.swift` (+vendorMatchSection + picker sheet), `Haven/Features/Property/Views/ContractorDirectoryView.swift` (+heroSpendStrip, +contractSnapshotPill, +contractsSection/contractRow, +activityAmount, +billSavedToast overlay, +loadDocuments toast trigger, +serviceContracts state + fetch), `supabase/functions/process-invoice/index.ts` (preferred_contractor_id input + metadata writeback + vendor_match response).

**Verification:** `supabase db push --linked` applied migration. `supabase functions deploy process-invoice --no-verify-jwt` deployed updated edge function. `xcodebuild` succeeds against iOS Simulator after every batch. Template count unchanged from Phase 58 (93).

**Out of scope (deferred per plan):** No `AddContractSheet` (V1 read-only; manual inserts via Supabase for TestFlight). No spend trend chart. No contract renewal → task creation (amber badge only when implemented). No `contractor_activity` SQL view — Swift-side aggregation sufficient at this scale. No auto-create vendor from email sender (user explicitly picks via candidate picker). No per-vendor subject-line email tagging (universal forwarding address only).

## Phase 58: Vendor Orchestration + Task Library Purge (2026-04-17)

Reframes Haven as a vendor orchestration product (not a chore tracker) via six ordered batches. Template library drops from ~150 to ~93 (−38%), 3 sprawling bundles dissolve into handyman defaults, 7 recurring-service templates convert to routines seeded automatically when matching contractors are added, and `ContractorDetailView` becomes the muscle-memory surface with a unified activity timeline + one-tap bill upload.

**Batch A — Template kills/demotes/reframes.** Removed ~25 chore-tracker templates entirely (Check thermostat calibration, Flush AC condensate line, Heat pump defrost cycle check, Clean window AC filters, Test water pressure, Test GFCI outlets, Verify smoke detectors x2, Verify CO detectors, Inspect firebox and damper, Check window locks, Inspect retaining walls, Spot-treat broadleaf weeds, Sharpen mower blades, Edge walkways, Rinse turf with hose, Clear leaves from turf, Inspect turf after heat, Sanitize pet areas, Check irrigation heads, Clean salt cell, Shock pool, Inspect foundation for pest entry, Verify generator test cycle, Test water after filter replacement, Check cellar temperature). Demoted ~23 others into the expanded Handyman bundle default notes (Replace air filters, Rinse mini-split filters, Store window AC, Inspect/repair caulking, Inspect/repair driveway cracks, Check drain field wet spots, Inspect well cap, Check pressure tank, Inspect weatherstripping x2, Lubricate door hinges, Grade check, Inspect turf drainage/seams, Vacuum fridge coils, Dishwasher cleanout, Replace ice maker filter, Seal gaps around pipes, Check generator oil, Inspect water softener brine, Replace whole-house filter, Replace smoke detector batteries, Check fire extinguishers, Confirm camera clarity). Reframed vendor templates with `isDIY: true` inconsistency (Roofing check shingles/clean gutters/flashing, Siding power wash + deck/patio, Water Heater flush + T&P, Garage Door auto-reverse + lubricate, Crawl Space vapor barrier + mold + cracks). Moved `Trim tree branches away from roof` from Roofing to Tree Service. Dissolved 3 bundles (`Plumbing:annual`, `Well System:annual`, `Crawl Space:quarterly`) — their members fold into Handyman:spring defaults. `Security System:annual` simplified to one walk-test task. `Water Treatment`, `Cleaning Service`, `Pet Waste`, `Doors` categories emptied entirely; tasks converted to routines (7 templates) or demoted to handyman defaults.

**Batch B — Expanded Handyman notes.** `Spring handyman visit` + `Fall handyman visit` bundle parents now carry structured multi-section "What's typically covered" checklists in their `notes` field (20+ items each, grouped by HVAC / Plumbing / Exterior / Safety / Appliances / Other). Users see one vendor moment that absorbs everything previously scattered across 20+ chore reminders.

**Batch C — Documents ↔ Contractors FK.** Migration `20260705_document_contractor_link.sql` adds `documents.contractor_id` (nullable FK, `ON DELETE SET NULL`) with index. `DocumentRow` / `DocumentInsert` / `DocumentUpdate` gain `contractorId: UUID?` with `contract_id` CodingKey. `process-invoice` edge function writes `contractor_id` to the document row when its vendor-match is non-null. `receive-email` stamps `contractor_id` on every document insert path (home, vehicle, bill, additional attachments) using `createdContractorId` from STEP 1's sender-match. Both edge functions redeployed with `--no-verify-jwt`.

**Batch D — Vendor detail redesign.** `ContractorDetailView` (still in `ContractorDirectoryView.swift`) now renders: hero card (64pt `VendorLogoView`, company name, category, insurance/rating badges) > 4-button quick actions row (Call / Email / Text / Web) > UPCOMING section (next 3 upcoming tasks assigned to this vendor) > RECENT ACTIVITY section (unified 90-day timeline merging `service_records`, `documents`, and task completions, sorted desc, max 8 rows with icon/title/subtitle/relative-date) > ADD A BILL section (3 cards: Scan, Upload, Forward) > ASSIGNED SYSTEMS > existing Phase 51 standing appointment block > DETAILS card > optional NOTES card. New `ContractorActivityEvent` enum encapsulates the 3 activity types. Scan/Upload route to `DocumentUploadView(preselectedContractorId:)` — new init param passed through to `DocumentUploadViewModel.selectedContractorId` so the insert stamps `contractor_id`. Forward opens a medium-detent sheet showing the household's `*@alfred.havenhome.dev` address with a copy-to-clipboard button (2s checkmark flash via `forwardingCopied` state). New `DatabaseService.fetchMaintenanceTasksByContractor(_:)` and `fetchDocumentsByContractor(_:)` back the data loads. Service history section dropped — now part of the unified timeline. The Details card moved below the activity so vendor interaction, not contact metadata, is the first thing you see.

**Batch E — RoutineSeeder.** New file `Haven/Features/Property/Services/RoutineSeeder.swift` — `@MainActor` singleton with `seedIfNeeded(for: ContractorRow)` and `backfillAllContractors(householdId:)`. Category-string matcher (case-insensitive keyword substring) maps to `RoutineKind` + defaults: cleaning → biweekly Wed 9am year-round morning reminder, landscaping → weekly Wed 8am Apr-Nov, pool service → weekly Tue 10am May-Sep, pest control → customDays(90) year-round, pet waste → weekly Wed 8am year-round morning reminder, mosquito & tick → triweekly Tue Apr-Oct. Dedup: skips when a routine of the same kind already exists for the household (vendor-linked or not). Hooked into `DatabaseService.createContractor` as a fire-and-forget `Task { @MainActor in ... }` so every existing call site (AddVendorSheet, quiz mapper, invoice processing, FindLocalVendor, VendorReviewForm, QuoteAnalysisView) auto-seeds routines without per-site changes. Matches the 7 templates deleted in Batch A (cleaning service, pool chemistry, pool filter, pet waste weekly, pest control quarterly, mosquito seasonal). 5 new `AnalyticsEvent` cases: `vendorDetailOpened`, `vendorBillScanStarted`, `vendorBillUploaded`, `vendorForwardEmailCopied`, `routineSeededFromContractor`.

**Batch F — Contacts hub row polish.** `PropertyDetailView.contractorRow(_:)` gained a third-line activity caption below the specialty row. `vendorActivitySubtitle(for:)` helper returns `"Next: {task title} · in 2 weeks"` when an upcoming task within 60 days is assigned to the contractor, or `"Last: {service type} · 3 days ago"` when a recent service record exists within 60 days. Priority: upcoming > recent service > nil. `shortTitle(_:)` truncates long titles at natural word break. `relativeLabel(for:)` produces human-readable date deltas (today / tomorrow / in 3 days / in 2 weeks / 1 month ago etc). Reads from existing `viewModel.maintenanceTasks` + `viewModel.serviceRecords` — no new data fetches, zero performance impact. Vendor detail also now has a working Website quick-action button (4th position, routes through `urlFromWebsite(_:)` helper that prepends `https://` when missing).

**Files added:** `supabase/migrations/20260705_document_contractor_link.sql`, `Haven/Features/Property/Services/RoutineSeeder.swift`.

**Files modified (major):** `Haven/Features/Property/Services/MaintenanceTemplates.swift` (~800 lines churn — Batch A+B), `Haven/Core/Networking/DatabaseModels.swift` (+contractorId on DocumentRow/Insert/Update), `Haven/Core/Networking/DatabaseService.swift` (+fetchMaintenanceTasksByContractor, +fetchDocumentsByContractor, createContractor seeds routine), `Haven/Features/Property/Views/ContractorDirectoryView.swift` (~400 lines added to ContractorDetailView — Batch D), `Haven/Features/Property/Views/PropertyDetailView.swift` (+activity subtitle helpers — Batch F), `Haven/Features/Documents/Views/DocumentUploadView.swift` (+preselectedContractorId param), `Haven/Features/Documents/ViewModels/DocumentUploadViewModel.swift` (+selectedContractorId, wired to both upload paths), `Haven/Core/Services/AnalyticsService.swift` (+5 events), `supabase/functions/process-invoice/index.ts` (+auto-link documents.contractor_id), `supabase/functions/receive-email/index.ts` (+stamp contractor_id on 4 document insert paths).

**Verification:** `xcodebuild` succeeds against iOS Simulator after every batch. Template count dropped from ~150 to ~93 (`Grep 'MaintenanceTemplate(' MaintenanceTemplates.swift -c`). Migrations pushed via `supabase db push --linked`. Both edge functions redeployed via `supabase functions deploy X --no-verify-jwt`. New TestFlight build targets this as the vendor orchestration re-anchor.

**Out of scope (deferred):** One-time backfill for existing households not written (Tom's call — TestFlight is still testing, no legacy burden). Dedicated Vendors tab at the top level not added (kept in Property → Contacts per Tom's call). Alarm/security routine not added. Hot tub routine not added (hot tub sanitation kept as personal task).

## Phase 57: HNW Additive Expansion (2026-04-17)

Additive layer on top of Phase 19k/50/52/54B architecture — zero breaking changes, zero existing templates modified, zero task rows marked legacy. Three things added: formal `regional_pack` on properties, 11 new HNW-focused templates, and an opt-in review sheet that lets existing users discover the new routines without getting spammed.

**What's new in the DB:** One migration (`20260704_phase57_regional_pack.sql`) adds `properties.regional_pack TEXT` with an index, backfills every existing property from `state` via five regional buckets (northeast/southeast/midwest/southwest/west), and leaves `regional_pack = NULL` for properties without a state. No changes to `maintenanceilder_tasks`, `home_systems`, or any other table.

**What's new in Swift:** `RegionalPack` enum in `Haven/Features/Property/Models/RegionalPack.swift` (String Codable with `init?(state:)` + `displayLabel`). `PropertyRow` / `PropertyInsert` / `PropertyUpdate` gain `regionalPack: String?` with `regional_pack` CodingKey. `MaintenanceTemplate` gains `regionalPack: RegionalPack?` field with default nil (universal); trailing param so every existing call site keeps compiling. `MaintenanceTemplates.templates(for:activeSubtypes:regionalPack:)` adds a regional filter — templates pass when their `regionalPack` is nil OR matches the property. Pre-Phase-57 templates are all nil, so the filter is a no-op for existing tasks.

**Reconciler wiring:** `MaintenanceTaskReconciler.reconcile(propertyId:householdId:...)` reads `property.regionalPack` (falling back to `RegionalPack(state:)` for pre-migration rows), merges `properties.attributes` HNW flag values into the `flags` dict (has_humidifier, has_ev_charger, has_leak_detector, has_central_vacuum, has_built_in_grill, has_outdoor_lighting, has_whole_house_filter, has_radon_mitigation, has_pool_safety_fence, has_pets), and passes both through to `essentialTemplates(for:activeSubtypes:regionalPack:)`. `MaintenanceTemplates.activeSubtypes(category:subtype:fuelType:flags:)` extended to propagate HNW flags into subtype sets for HVAC / Electrical / Landscaping / Appliance / Plumbing / Pool/Spa / Water Treatment / Air Quality / Handyman categories — Handyman is the pickup point for bundle-child templates that live under `systemCategory: "Handyman"` but gate on property-wide HNW flags.

**11 new templates (action-first titles, reframing still applies at render time):**
- HVAC: "Air duct cleaning" (every 3-5yr, ducted), "Whole-home humidifier service" (annual, has_humidifier, NE-only)
- Electrical: "EV charger inspection" (annual, has_ev_charger, safetyFloor)
- Landscaping: "Outdoor lighting service" (annual, has_outdoor_lighting)
- Appliance: "Built-in grill service" (annual, has_built_in_grill, safetyFloor)
- Pool/Spa: "Pool safety fence inspection" (annual, pool + has_pool_safety_fence, .either)
- Siding/Exterior: "Exterior painting refresh" (10yr cycle, universal)
- Handyman bundle children: "Test smart water leak system" (Handyman:spring, has_leak_detector), "Service central vacuum system" (Handyman:fall, has_central_vacuum), "Verify radon mitigation fan" (Handyman:fall, has_radon_mitigation, NE-only)
- Air Quality: "Annual radon test" (every 2yr, NE-only — lives in new `Air Quality` category registered in `SystemCategoryRegistry` as Tier 2 conditional priority 140 with `wind` icon)

**"Insurance review" + "valuables appraisal" intentionally deferred** to Phase 58 estate-lane expansion. Both overlap Phase 48 Estate Intelligence scoring and belong as `routines` / `SmartRecommendations` entries, not maintenance templates.

**Air Quality auto-create:** `HouseQuizAnswerMapper.ensureAutoCreatedSystems` gains a new rule — create `Air Quality` home_system when `RegionalPack(state: property.state) == .northeast`. Runs alongside the existing Handyman / Mosquito & Tick / Pet Waste / Chimney / Snow Removal auto-creates. No retroactive backfill for existing NE users — they pick up Air Quality via the "What's New" flow (see below) or by enabling radon mitigation via `UpdateHomeDetailsSheet`.

**`UpdateHomeDetailsSheet.swift`:** New sheet renders 10 HNW subtype toggles (grouped into Systems + Valuables cards) with a "Recommended for Northeast homes" card that only appears when `property.regionalPack == .northeast` — contains radon mitigation + humidifier toggles with context copy. Reads current flag values from `property.attributes` on `.task`, diffs against initial state on Save. If the diff is non-empty, presents `SubtypeReviewDiffSheet` with a bulk Additions list (preview of tasks that will be created per flag) and per-row Archive/Keep segmented picker for Removals. Default is Archive, which lets the reconciler's existing `.full` mode orphan pass clean up; Keep is advisory in V1 since reconciler always runs `.full` (a future iteration can wire per-subtype `.addOnly` mode). Pattern mirrors the Phase 56.5 `MaintenanceDuplicateSheet` single-confirmation moment. On commit: `updatePropertyAttribute` per changed flag → `MaintenanceTaskReconciler.reconcileAll(propertyId:householdId:)` → `.maintenanceTaskChanged` + `.homeSystemChanged` notifications → confirmation toast with added/archived counts ("Added 2, archived 1") → 1.5s delay → dismiss. Pool safety fence toggle is disabled and captioned when no pool exists on the property (reads `property.attributes["pool_type"]`).

**`WhatsNewPhase57Card.swift`:** Dashboard surfaces the review sheet to existing users. Render gate: `!dismissed && property.createdAt < phase57ReleaseDate` where the release date is hardcoded `2026-04-20` (pin to actual ship day). Post-release signups fail the cutoff and never see the card. `@AppStorage("whatsNewPhase57Dismissed")` persists dismissal across launches. Copy adapts based on regional pack — NE-region properties see the "including Northeast-specific routines like radon testing and humidifier service" qualifier. Inserted on DashboardView above the "Up Next" / "This Week" section. Tapping the navy "Review your home" capsule button opens `UpdateHomeDetailsSheet`; card auto-dismisses once the user completes a review via `onSaved` callback. Analytics: `whatsNewPhase57Opened`, `whatsNewPhase57Dismissed` added to `AnalyticsEvent` enum.

**Files added:** `supabase/migrations/20260704_phase57_regional_pack.sql`, `Haven/Features/Property/Models/RegionalPack.swift`, `Haven/Features/Property/Views/UpdateHomeDetailsSheet.swift`, `Haven/Features/Dashboard/Components/WhatsNewPhase57Card.swift`.

**Files modified:** `Haven/Core/Networking/DatabaseModels.swift` (PropertyRow/Insert/Update + regional_pack CodingKey + decoder), `Haven/Features/Property/Services/SystemCategoryRegistry.swift` (+Air Quality conditional entry), `Haven/Features/Onboarding/HouseQuiz/HouseQuizAnswerMapper.swift` (+Air Quality auto-create for NE), `Haven/Features/Property/Services/MaintenanceTemplates.swift` (+regionalPack field + regional filter + 11 new templates + Air Quality section + HNW flag cases in activeSubtypes), `Haven/Features/Property/Services/MaintenanceTaskReconciler.swift` (+regional pack resolution + property.attributes merge into flags), `Haven/Features/Dashboard/DashboardView.swift` (+WhatsNewPhase57Card insertion above Up Next), `Haven/Core/Services/AnalyticsService.swift` (+2 events).

**Verified:** `xcodebuild ... build` succeeds against iOS Simulator. No existing templates modified; existing `templateId` values preserved; every existing call site of `templates(for:activeSubtypes:)` continues to compile because `regionalPack` is a trailing param with a default. Zero impact on households whose state doesn't map to a regional pack (regionalPack stays nil, regional templates filter out, universal templates continue to surface normally).

---

## Phase 56 Section 6: Timeline Density, Handyman Quick Action, Priority Recalibration (Build 94 — 2026-04-16)

Three visual-density problems undermined the Maintenance tab's premium feel: 7 full-height ONGOING ROUTINES rows consuming the entire Timeline viewport before the first actionable task; "Find a pro →" as the only CTA on sub-60-min handyman-appropriate tasks (forcing three taps + a detail-sheet context switch to reach the punch list); and priority pills on ~70% of cards because "High" is the template default. Plus two paper cuts: vendor names wrapping to 3 lines ("Tyler Heating, Air Conditioning, Refrigeration LLC") and duplicate punch items from double-tapping the card + detail-sheet adds. Five companion changes, roughly 250 lines across four files, zero schema work.

**Timeline routines strip (56.6.1):** `timelineRoutinesPinnedSection` rewritten with a `routineStripExpanded: Bool` session-only toggle. Default state is a horizontal scroll of ~44pt `routineStripPill(_:)` capsules — icon + label + vendor-initial circle + tap to edit. The section header doubles as the expand toggle with a `chevron.down` / `chevron.up` that swaps back to the 56.4 full-row treatment. Reclaims ~380pt of viewport. Pattern borrowed from Apple Calendar's all-day event strip + Google Calendar Schedule view — recurring items universally get compressed treatment in chronological views. Pills use `routine.resolvedIcon` (same as `RoutineOccurrenceRow`) + `HavenColors.navy700` for a consistent treatment; no per-category color wash because Apple's color-by-calendar pattern reads as branding, not density.

**Handyman inline CTA (56.6.2):** `UnifiedTaskCard` gained `onAddToHandyman: (() -> Void)?`. When the parent passes a non-nil closure, the `findContractorCard` variant renders a muted "Or add to handyman list" secondary link with a `hammer` SF Symbol below the coral "Find a pro" pill. Eligibility is gated in `MaintenanceScheduleView.isHandymanEligible(_:)`: matched template exists, `template.diyEffortMinutes ≤ 60`, no contractor assigned, not a vehicle task. The quick-add helper `addTaskToHandymanPunchList(_:)` inserts a `HandymanPunchItemInsert` with `source: "maintenance_task"` + `sourceTaskId: task.id`, fires a dedicated `handymanPunchToast` overlay (hammer icon + message, single-line — distinct from `viewModel.completionToast` which has a "Next due:" second line that would read wrong here), and bumps `handymanPunchItemCount` so the dashboard/tab `HandymanSuggestionCard` gate stays in sync. Doesn't complete the task — the user hasn't committed to the handyman handling it yet.

**Punch list dedup (56.6.3):** Three places where duplicates could enter (and one place where they were already on the table from pre-56.6 testing):
- `MaintenanceScheduleView.addTaskToHandymanPunchList` fetches existing pending items first and fires "Already on handyman list" instead of inserting when one matches `sourceTaskId`.
- `MaintenanceTaskDetailSheet.addToPunchListJustThisTime` runs the same pre-check before `createHandymanPunchItem`, still fires the success toast (user gets acknowledgement) but skips the insert.
- `MaintenanceTaskDetailSheet.addToPunchListReassignSeries` also pre-checks; still runs the series reassignment + instance completion even when the punch item exists, because those are independent user decisions.
- `HandymanPunchListViewModel.load` routes raw items through the new `Self.deduplicated(_:)` static — sorted by `createdAt` desc, kept first-seen per `sourceTaskId`, items without a source id (manual entries, recommendation adds) always kept. Belt-and-suspenders for any rows that slipped through the create-time checks.

**Priority pill recalibration (56.6.4):** `UnifiedTaskCard.shouldShowPriorityPill` tightened to render only for overdue (any priority) OR explicit `critical` / `urgent`. Template-seeded `high` no longer renders a pill because ~70% of a mature household's tasks inherit `priority: "High"` from `MaintenanceTemplates` and the pill had stopped signaling anything. Linear's P0/P1-only rule + GitHub Issues' no-auto-labels policy are the references. The long-term fix is a `prioritySource` column on `maintenance_tasks` so user-set vs template-default can be distinguished without the proxy — deferred.

**Vendor name truncation (56.6.5):** Added `truncatedVendorName` computed property on `UnifiedTaskCard` that routes both `contractor?.companyName` and the denormalized `contractorName` prop through `MaintenanceViewModel.vendorDisplayName` (which strips ` LLC` / ` Inc.` / ` Corp.` / etc. suffixes then truncates at the first comma when still over 25 chars). The pre-existing `vendorDisplayName` computed now delegates to `truncatedVendorName ?? "Your vendor"`, which cascades the truncation through every existing render site: vendor-managed card vendor row, needsScheduling "X assigned" label, `VendorLogoView` fallback initial resolution, personal-card vendor chip. `contractor?.companyName` is no longer read directly anywhere outside the helper.

**Files touched:** `Haven/Features/Property/Views/MaintenanceScheduleView.swift` (routine strip rewrite + pill helper + `routineStripExpanded` state + `isHandymanEligible` + `addTaskToHandymanPunchList` + `handymanPunchToast` state + overlay), `Haven/Shared/Components/UnifiedTaskCard.swift` (`onAddToHandyman` callback + secondary CTA render + `shouldShowPriorityPill` recalibration + `truncatedVendorName` helper + `vendorDisplayName` delegation + personal-card chip routing), `Haven/Features/Property/Views/HandymanPunchListView.swift` (`deduplicated(_:)` static + load-time dedup), `Haven/Features/Property/Views/MaintenanceTaskDetailSheet.swift` (pre-check guards in both addToPunchList paths).

**Verified cases:**
- Timeline view opens with `ONGOING ROUTINES · 7 ˅` compact strip; first actionable task is visible without scrolling
- Tap strip header → chevron flips, routines expand to full cards; tap again → collapse
- "Clean dryer vent duct" card shows "Find a pro" + "Or add to handyman list"; "Annual generator service" shows only "Find a pro" (specialist work)
- Vendor-assigned card (Tyler Heating on "Schedule annual tune-up") shows neither CTA because `findContractor` variant doesn't apply
- Double-tap "Add to handyman list" → second attempt shows "Already on handyman list" toast, no duplicate inserted
- Priority pill renders on overdue tasks + explicit critical; template-default High no longer renders
- "Tyler Heating, Air Conditioning, Refrigeration LLC" renders as "Tyler Heating" across card variants

**Out of scope (deferred):** No `prioritySource` column on `maintenance_tasks` (long-term fix for the template-default priority proxy), no changes to list-view routine rendering (Phase 55 This Week routines section unchanged), no data model changes.

---

## Completed Phases (Compressed)

- **Phases 20-28:** App icon, UX audit (25 fixes), Sign in with Apple, background multi-file upload, smart vendor import, pre-onboarding intro explainer, property color coding, maintenance/estate tab improvements, dashboard redesign, navigation consistency polish.
- **Phases 29-31:** Alfred AI guardrails (scoped system prompt), tab navigation pop-to-root fix.
- **Phases 32-34:** Major UX overhaul; family member avatars with CRUD; smart recommendations engine.
- **Phases 35-36:** Household sharing (invite flow + atomic merge across 15+ tables).
- **Phase 37:** GTM strategy doc (non-code); attorney referral kit, playbook.
- **Phase 38:** Invoice Intelligence (38a-38f). `process-invoice` + iOS deterministic sub-system grouping under `parent_system_id`. `InvoiceChoiceSheet`. Fuzzy dedup.
- **Phase 39:** Tappable maintenance tasks; Alfred system context; utility types expanded; SystemGroup reorg; BrandFetch persistence; 34 utility providers seeded.
- **Phase 40:** `BrandLogoCache` actor; equipment-specific task migration via `equipmentKeywords`; active quote system; seasonal overview with progress ring.
- **Phase 41a/c:** Vehicle Management Foundation — household-scoped vehicles, NHTSA + Claude Vision VIN decode, tables `vehicles` / `vehicle_service_records` / `vehicle_recalls`, unified vehicle+home task system in `maintenance_tasks`.
- **Phase 42/42b/43/44:** Dashboard redesign + HouseholdStrip; vehicle invoice pipeline; VIN detection in documents; SHA-256 content hash dedup; vehicle detail overhaul with mechanic card + cost stats; auth flow fix (`hasResolvedInitialSession`).
- **Phase 42 email pipeline (42a-42f):** 88 document categories; user confirmation on all docs; insurance claims no longer auto-create projects; vehicle routing via `vehicle_document` type; unsupported file types gracefully handled; cross-path duplicate detection via `content_hash`; `LogHistoricalProjectView` + `documents.project_id`.
- **Phase 45:** Project ROI cache fix; insurance claim $0 fix; covered driver age filter ≥16; seasonal simplification via `SeasonalTaskGrouper`; utility bill detection.
- **Phase 46 (Onboarding Revamp Phase 2):** Force-update gate via `app_config` table + `VersionCheckService` + `ForceUpdateView` + `OptionalUpdateBanner`. Unified `PropertyCreationService` actor as single source of truth for ATTOM enrichment + system auto-create + task generation. New `AddPropertyFlow` 3-step (since collapsed to 2 in Phase 60.1). Deleted `AddPropertyView.swift` and `HomeSystemsSetupView.swift`.
- **Phase 47 (Phase 14 TestFlight Bug Fixes):** Universal HVAC/Roof/Water Heater/Electrical creation regardless of ATTOM coverage; pre-quiz task filter + post-quiz subtype migration via `MaintenanceTaskMigrator`; auto-create primary `family_member` in `PropertyCreationService.ensurePrimaryFamilyMember`; quiz X button Save-and-exit dialog.
- **Phase 48 (Phase 15 TestFlight Bug Fixes):** Quiz trust refinements — utility-search persistence, multi-select preservation, other edge cases.
- **Phase 49 (Phase 16):** Insurance databases seeded, carrier bundle flags, family composition capture, ATTOM tax-assessment enrichment.
- **Phase 50 (Phase 17):** Life tab scrollability; post-quiz task reconciliation.
- **Phase 51 (Phase 18):** Quiz personalization, data quality, provider snapshots.
- **Phase 52 (Phase 19):** Bulletproof quiz state persistence and resume.
- **Phase 53:** TestFlight database reset (users start fresh for new schema).
- **Phase 53b (Phase 19b/c):** Dedicated HVAC type question (Q3b).
- **Phase 54 (Phase 19d):** `EditSystemSheet` reconciler integration.
- **Phase 55 (Phases 19i-19n):** Vendor-aware maintenance system — `assignment_type`, `needs_vendor`, `assigned_contractor_id`, reframed task voice, two-bucket UI, contractor mirror from quiz.
- **Phase 56 (Build 83):** Quiz UX trust pass + polish — region-aware provider ranking, Q4 prefill ladder, per-question placeholders.
- **Phase 50 Build 84:** Quiz UX + Property Overview polish — hardscape branch (Q11 5th answer), ATTOM fallback ladder for retroactive refresh, Q17 forwarding-email milestone reveal, `equityUpsellCard`.
- **Phase 51 Build 85:** Quiz resume + review polish — saved-for-later review flow, toolbar bookmark pill, progressLabel clamp, full hydration coverage.
- **Phase 52 Build 86:** Quiz + family member feedback pass — Q22 same-supplier confirmation, Q10 select-all pill, Q25 garage + Q25b EV split, Family member chooser.
- **Phase 53 Build 87 Batch 2:** Pool vs Hot Tub split, vendor discovery delegation flow, home manager role + document access.
- **Phase 54 Build 87 Home Manager Expansion:** Home manager `member_type` + RLS + per-document `visible_to_home_managers` toggle + `HouseholdStaffStrip` + Q28 home manager sub-step.
- **Phase 50 Build 89 Vendor-First Redesign:** Template metadata layer (`routingOverride`, `safetyFloor`, `maxIntervalDays`, `warrantyLinked`), system frequency overrides, PropertyDetailView maintenance tab reshape, `MaintenanceScheduleView` vendor-first bucket order.
- **Phase 50 Sub-phase B First-Login:** Day 0 gating — dashboard collapses to Quiz-only CTA until any quiz completes. `VendorScheduleStrip` empty-state "forward invoices to" caption with copy-to-clipboard.
- **Phase 50 Advisor Picker:** Three-bucket sort (national / closest / alphabetical) via `utility_providers.prominence_rank`.
- **Phase 52 Vendor Orchestration:** Bundled service visits expansion (5 new bundles), 3 new system categories (Handyman / Pet Waste / Mosquito & Tick), "Professional" title cleanup.
- **Phase 52b:** Alfred-driven specialty system discovery — keyword-based inference in `process-invoice` + `analyze-document` surfaces `specialty_system_suggestion`.
- **Phase 54A Maintenance Orchestration Foundation:** Seasonal seeding via `MaintenanceTaskReconciler.initialDueDate`, `reseedSeasonalTasksOnceIfNeeded`, `backfillBundlesOnceIfNeeded`, `cleanupTaskTitlesP54A`, missing-system auto-create via `HouseQuizAnswerMapper.ensureAutoCreatedSystems`, maintenance layout toggle.
- **Phase 54B Vendor Features:** Handyman punch list (`handyman_punch_items` table), wave view (4 season cards with vendor groupings + "Draft SMS" via `MessageComposeView`), seasonal-contract templates (snow plowing, mosquito & tick).
- **Phase 54C Value-Preservation Library:** Non-essential templates (`isEssential: false`) + `RecommendedServicesView` with Schedule/Add-to-handyman/Hide CTAs + `dismissed_recommendations` table.
- **Phase 54D Household Cadences:** `household_cadences` table + `HouseholdCadencesView` + `PickupDayBanner` with evening-before / morning-of reminders + `cadence-notifications` edge function.
- **Phase 54E Cadences in the Schedule:** Virtual occurrences via `CadenceOccurrenceExpander` + pinned weekly cadences section + calendar-layout inline occurrences + cross-surface sync.
- **Phase 54E.2 Biweekly/Monthly Cadences + Vendor Linking:** `weeks_interval`, `anchor_date`, `contractor_id` on `household_cadences`; cleaning/lawn_care/pool_service/pest_control cadence types; vendor logo rendering on banner + row.
- **Phase 54E.3 Trash & Recycling Category:** Utility-to-contractor mirror, trash/recycling surfaces as vendor-contractor.
- **Phase 54E.4 Duplicate Cleanup + Uniqueness Guards:** Comprehensive dedup passes across tasks + cadences + routines.
- **Phase 55.1 Routines Unification (Data Migration):** `routines` + `routine_visits` tables; backfill from `household_cadences` + `standing_appointments`; invariant CHECKs; resilient Swift model with `RoutineKind` / `RoutineCadenceType` enums.
- **Phase 55.2 Routines Rendering:** `MaintenanceScheduleView` reads routines via `fetchRoutines`; `RoutineOccurrenceRow` with 3 display modes; `RoutineOccurrenceExpander` (stateless); collapsed-row pattern; hard DIY-default floor in `resolveAssignment`; `fixAirFilterAssignmentP55` migration.
- **Phase 55.2.9 Cadence→Routine Write Bridge:** Dual-write from legacy cadence sheet into routines table; retired in 55.3.
- **Phase 55.3 Routines Native Config + Legacy Retirement:** `ActiveMonthsPicker`, `RoutineEditSheet`, `RoutinesListView`; `CadenceEditSheet` / `HouseholdCadencesView` / `HouseholdCadence.swift` / `CadenceOccurrenceExpander.swift` deleted; legacy CRUD + bridge removed.
- **Phase 56 Section 1 Contacts Hub:** `PropertyDetailView` Contacts sub-tab as canonical vendor/advisor directory. `ContactsFilter` enum, Apple Contacts-style density, `AddVendorSheet` clipboard detection, task-action-menu "Assign a Vendor" picker wire, gap-only `VendorCoverageSheet`.
- **Phase 56 Section 2 Dashboard + Property List + Garage Polish:** ATTOM value band persisted (`current_estimated_value_low/high` on `properties` + `ValuationRange.compute(for:)` prefers band); dashboard scroll tightened (nav-bar brand, compact greeting, seasonal context, conditional UP NEXT, filtered Recent feed); enriched `PropertyCardRow` with coverage pill + next-visit; garage empty state rewrite.
- **Phase 56 Section 4 (Build 91) Maintenance Tab Refinement:** Stats pills as filters (All/Mine/Vendor deleted); timeline label; card hygiene (effort-badge gate, priority-pill gate, `findContractorCard` redesign); handyman flow (confirmation dialog, `HandymanSuggestionCard`, "Schedule handyman visit" menu entry); task-detail polish (single-line next action); action-item triage (split when 5+ tasks).
- **Phase 56 Section 5 (Build 92) Empty State + Bucket Naming + Duplicate Management:** Bucket collapse state session-only; "Vendor-Managed"→"Scheduled", "Your Action Items"→"To Schedule"; `DuplicateDetector` + `DuplicateDismissalStore` + `DuplicateReviewBanner` + `MaintenanceDuplicateSheet` + creation-time `preventionCheck`; 3 new analytics events.
- **Phase 56 Section 5 Patch (Build 93) Duplicate Detection Refinements:** Title-similarity gate via Jaccard on normalized tokens; parent-driven `MaintenanceDuplicateSheet` lifecycle for auto-advance through queue; word-form normalization before stop-word removal; trade-specific content words intentionally preserved.

