# Chez Product Audit — Personas, Functions, Gaps, Bugs, User Stories
**Date:** July 7, 2026 · **Method:** 7 parallel code-audit agents over the full repo (iOS app, chez-concierge + 60 edge functions, migrations/RLS, admin.js cockpit, service/admin portals, deployment config). Every bug below was verified by reading the actual code, with file:line evidence.

**Coverage note:** Two areas got lighter passes and deserve a follow-up sweep: (1) the Tasks tab V5 views themselves (`MaintenanceTabView`/`HandymanTabView` — the in-flight uncommitted work) plus House Quiz and Dashboard internals, and (2) the new `website/service/` portal views (Waves 1-5). Everything else — maintenance engine + views, vendors, projects, docs/inbox, vehicles, family/settings, Chez iOS, chez-concierge data layer, admin cockpit, backend functions, cron — got full-depth audits.

---

## 1. Personas — what you listed vs. what actually exists

Your three personas are right, but the codebase supports **five more** that need their own stories:

| Persona | Status | Why it's distinct |
|---|---|---|
| **Homeowner** | ✅ listed | Primary account holder |
| **CS / Concierge Operator** | ✅ listed | Service portal + cockpit + chez-concierge |
| **Admin (founder)** | ✅ listed | Catalog/content/templates back-office |
| **Home Manager / Staff** | ❌ missing | Real first-class role (`member_type = home_manager/staff`): own login, full task/system/vendor/project editing, **restricted document visibility** with per-doc override, role-gated destructive actions. Distinct onboarding (Q28 sub-step, Settings → Household Staff). |
| **Family member (spouse / linked user)** | ❌ missing | Invited via share code; receives task assignments and pushes; merge-household flows; not the same stories as the primary. |
| **Vendor (third-party)** | ❌ missing | No portal by decision, but real digital touchpoints: apply → confirm → chez_certified ranking, email outreach with reply tokens, SMS drafts, reliability tracking (no-shows, answer rate). |
| **Trusted contact** | ❌ missing (minor) | Read access to designated documents only. |
| **Prospect / waitlist** | ❌ missing (minor) | getchez.com waitlist (Viral Loops), referral terms; currently the ONLY public web surface. |

## 2. Function inventory — what was missing from your persona descriptions

### Homeowner — you listed: profile building (systems/tasks/routines/vendors/projects), handyman scheduling, internal task assignment. **Missing from your list:**
- **Document vault + email forwarding pipeline** (forward invoice → parse → tasks/systems/vendors) — arguably the biggest moat feature
- **Invoice intelligence** (process-invoice, cadence detection, follow-up extraction)
- **Inbox / needs-action triage** (category confirmation, duplicate resolution, quote→project routing)
- **Vehicles/garage** (VIN decode, recalls, mechanic, service records, shop-managed programs)
- **Chez delegation layer** (per-task / per-routine / per-vendor ownership, proposals approve/counter/decline, standing-instructions profile, spending tiers)
- **Alfred AI chat** (incl. handoff to Chez via tool call)
- **Scenario Studio** ("What If" FAB)
- **Property intelligence** (ATTOM value band, investment summary, sale simulator, refresh from public records)
- **Family & household management** (invites, staff/home-manager roles, trusted contacts, merge households)
- **Utility accounts & providers**; **equipment catalog / manuals**; **security features** (vault lock, biometrics, encryption); **quiz onboarding itself**; **notifications & reminders**

### CS/Support — you listed: onboarding, taking ownership, general support. **Missing from your list:**
- **SLA management** (24 business-hour computation, */15 watcher, warn/breach pushes)
- **Structured proposals** (vendor/date/cost/quote) + homeowner decisions
- **Vendor sourcing intelligence** (analyze_request playbooks per category, Places candidates, deterministic fit score, cross-household vendor registry)
- **Call ledger + structured outcomes + visit tracking** (the Phase 100 data moat: answer rates, quoted costs, no-shows)
- **Ops metrics** (median response/resolution, SLA hit rate, effort/case, playbook funnel)
- **Case CRM hygiene** (assign/link/merge, tags, snippets, snooze)
- **Case-scoped Alfred** (`ask_alfred`)
- **Vendor application review pipeline** (certify/reject)
- **Vendor outreach email loop** (send-chez-vendor-email + reply tokens through receive-email)
- **Payments** (Stripe card-on-file — server actions exist, **no UI**)
- **Quiz-sourced intake** (batch Chez requests from onboarding quiz)

### Admin — you listed: "me in the admin panel." **Actual functions:**
- Content/catalog/template management (Quiz Builder, MaintenanceTemplates, Routine Kinds, System Categories, EF prompts) via the notes → Claude round-trip
- Reconciler simulator + quiz phone-frame preview + coverage audit + usage stats
- Vendor application review; white-glove onboarding capture (onboard.html)
- Catalog batch tooling (enrich/expand/scrape/download manuals — edge functions + CLI, mostly no UI)
- **Notably absent** (see Gaps): customer/household admin, billing, error monitoring, push composer, waitlist tooling — and the admin portal is currently unreachable in production.

---

## 3. What's working well

- **The canonical-category discipline where it was built**: `VendorReviewForm` and `ContractorPickerSheet` are reference implementations; the in-flight `InvoiceProcessingViewModel` canonicalization fix is correct — ship it.
- **Resilient decoders on the flagship structs** (`PropertyRow`, `VehicleRow`, `PropertyProjectRow`, all ~25 Chez snapshot structs) — the discipline holds where it was applied.
- **receive-email resilience choreography**: placeholder lifecycle, SHA-256 cross-path dedup, chunked encoding, self-healing allowlist.
- **`_shared/ai-cost-discipline.ts`**: haiku-first ladder, daily budget, kill-switch, bounded tool loops, telemetry.
- **CACHE_VERSION discipline** in property-lookup exactly as CLAUDE.md mandates.
- **The Phase 100 operator-data core doesn't leak**: chez_vendor_calls, chez_request_outcomes, chez_operator_events, chez_vendor_outreach, onboarding_sessions, chez_ai_usage are genuinely admin-/service-only; all six ops views correctly use `security_invoker`.
- **Cockpit architecture discipline held**: single render entry, central action dispatcher, every admin.js action string verified to exist server-side; brand voice clean (zero user-facing "Tom").
- **`HouseholdInviteCoordinator`**, **optimistic-mutation rollback in ProjectsViewModel**, **cancellation-aware loading in HandymanPunchListViewModel**, **`view-document`'s auth pattern** (the model the rest of the fleet should copy).
- **Operations-desk teardown was clean**; lockdown reversal was surgical; migration version-collision incident fully repaired.

---

## 4. Bugs — consolidated and ranked

### 4A. P0 — Security (fix before anything else)

| # | Bug | Where |
|---|---|---|
| S1 | **Cross-household access class**: ~9 functions run service-role with body-trusted IDs; chat/gap-analysis/simulate-scenario *silently fall back to service role on failed JWT* then trust `body.household_id`. Full household context incl. private docs with just a UUID. No membership check even with valid JWT. | `chat/index.ts:238-268`, `gap-analysis:88-125`, `simulate-scenario:72-90`, `check-vehicle-recalls:29-77`, `process-invoice:61-66,474-518`, `analyze-document:372-388`, `process-inbox-item` (no auth at all; `remove_vendor` hard-deletes contractors `:1155`), `merge-households` preview `:239-284`, plus lookup-manual / score-property / research-project / visualize-room |
| S2 | **send-push-notification only checks the Authorization header exists** — push-spam/phishing to arbitrary user ids | `send-push-notification/index.ts:122-159` |
| S3 | **receive-email webhook unauthenticated + allowlist skippable** (`if (senderEmail)` wrapper; no SendGrid signature). Forwarding address = inject docs/vendors/projects into a household | `receive-email/index.ts:548` |
| S4 | **`log_chez_activity()` is an open SECURITY DEFINER RPC** — anyone with the anon key can forge "Chez wrapped this up — $X" into any household's feed | `20261213_chez_activity_log.sql:99-128`; fix = REVOKE EXECUTE |
| S5 | **Homeowner UPDATE on `chez_requests` is column-unrestricted** — client can self-resolve (skipping the outcome form), tamper SLA stamps/due dates, edit `analysis_cache`, corrupt ops metrics | `20261201:82-88` |
| S6 | **Homeowner can forge Chez-voice messages/proposals**: `concierge_messages` INSERT doesn't constrain `role`/`proposal` — fabricated approvals, poisoned SLA metrics | `20260469...:113-115` |
| S7 | **`analysis_cache` leaks operator strategy to the homeowner** (call script, negotiation angle, cross-household cost comparables live on a homeowner-readable table) — AND the column has **no migration** (fresh env breaks at `20270107`) | `chez-concierge/index.ts:3014` |
| S8 | **Stored XSS into the operator's admin session**: spending tiers render unescaped from homeowner-writable `chez_profile` JSONB (`update_profile` does no type validation) | `admin.js:6054-6120, 11738-11815`; `index.ts:1284-1349` |
| S9 | **Unauthenticated admin-utility functions deployed**: upload-manual (arbitrary PDF + service-role writes), scrape/download-manuals, enrich/expand-catalog, and `test-ai` (returns env presence + first 10 chars of the Anthropic key) | live in prod, `verify_jwt:false` |
| S10 | Operator-private intel homeowner-readable: `chez_reminders` ("chase A&A Tuesday"), `chez_visits.notes`, `chez_request_tags` ("VIP", "Big spend") | `20261206:190`, `20261204:41-70`, `20261313:148` |
| S11 | `local_vendor_results` has RLS disabled and is client-writable → Chez Certified cache + vendor registry poisoning | `20260436:18-22` |
| S12 | Cron endpoints carry no shared secret; cadence-notifications has no send-stamp → spammable re-pushes | `20270108:41-87` |
| S13 | Prompt-injection → write path: hostile invoice/email text can mark arbitrary listed tasks complete and seed junk vendors/systems | `process-invoice:493-501`, `analyze-document:394-590`, `chat:283-285` |

**Root cause for most of S1-S2**: no shared `requireHousehold(req)` helper in `_shared/`. One helper + a sweep closes the class. `view-document/index.ts:54-119` is the in-repo model.

### 4B. P0 — Broken features (things that just don't work)

| # | Bug | Where |
|---|---|---|
| F1 | **cadence-notifications reads the dead `household_cadences` table** — pickup-day pushes (scheduled "for the first time" in Phase 100) fire against stale pre-Phase-55 rows; routines never notify. Also TZ design flaw: Pacific households can never receive evening-before pushes | `cadence-notifications/index.ts:84,142-147` |
| F2 | **proactive-scan is never scheduled and never called** — the advertised recall-detection/document-expiry moat does not run | no cron, no call sites |
| F3 | **Revoking a pending invitation hard-deletes the existing family member** (spouse's whole profile gone) | `PendingInvitationsSection.swift:169-171` |
| F4 | **Nil-omission class — "clear a field" never persists anywhere**: RoutineUpdate (Remove vendor / clear time/notes/cost silently no-ops), VehicleUpdate, ContractorUpdate, FamilyMemberUpdate, Profile, TrustedContact | `RoutineEditSheet.swift:836-853`, `DatabaseModels.swift:4974`, etc. |
| F5 | **Creating a Weekly/Biweekly routine from AddMaintenanceTaskSheet always fails** the `weekly_has_days_of_week` DB CHECK (no weekday picker in routine mode); user gets only an error haptic | `AddMaintenanceTaskSheet.swift:656-683` |
| F6 | **Routine archive strands child tasks invisibly** in 2 of 3 paths (swipe-delete, edit-sheet delete don't unlink; `parent_routine_id` is the universal hiding signal → tasks vanish from every surface) | `RoutinesListView.swift:207`, `RoutineEditSheet.swift:741` |
| F7 | **"Delete Task" is a silent no-op from 4 presenters** (dashboard cards, push deep-link sheet) — fires analytics, deletes nothing | `MaintenanceTaskDetailSheet.swift:2917` + 4 call sites |
| F8 | **Vehicle detail: every mutation refresh swallowed by a 60s freshness window** — update mileage, hero still shows old value | `VehicleDetailViewModel.swift:69-73` |
| F9 | **Completing an overdue vehicle-maintenance alert never completes the task** — reappears forever | `VehicleDetailView.swift:828-839, 2472-2485` |
| F10 | **Quote analysis uses synthesized decoders on Claude JSONB** — one drifted field silently vanishes every quote on a project (exact Phase 60.1 bug class); same for VehicleLookupResponse (one `"5000"` string fails the whole VIN lookup) | `DatabaseModels.swift:3763-3893`, `VehicleLookupService.swift:7-113` |
| F11 | **Cockpit: Today-view "Resolve" always fails** (sends `status` instead of `to_status`) and bypasses the required outcome modal | `admin.js:20358-20364` |
| F12 | **Cockpit: admin unread flag never cleared** (`mark_read` never called from admin.js) — cases sort in the "needs reply" tier forever, badge counts drift | server clears only via handleMarkRead |
| F13 | **Call-ledger data loss**: hydration clobbers whole slots ("local wins" at slot not field granularity → next flush persists nulls over server data); `fair_low/fair_high` never persisted or hydrated; tab-close flush has no keepalive | `admin.js:10071, 10100-10118, 10156` |
| F14 | **send-catalog-request emails a 4-hour SLA + links to `admin.getchez.com/system-requests/{id}`** — host and route never existed; no admin view reads `equipment_catalog_requests` at all | `send-catalog-request/index.ts:130-132` |
| F15 | **Chat-upload bypasses `InboxItemFromDocument`** — quote attached in Alfred never produces the project prompt (third insert path, violating the documented hard rule) | `ChatViewModel.swift:269` |
| F16 | **Vendor adoption stamps non-canonical categories + raw-equality task sweep** (FindLocalVendorSheet, ChezDirectoryService, task-detail fallback `"home service"`) — the Phase 60.6 Groton bug class re-introduced; adopted vendors locked out of coverage | `FindLocalVendorSheet.swift:1503,1552`, `ChezDirectoryService.swift:57,83` |
| F17 | **"Processing complete" push deep-links to a deleted inbox item** (placeholder id sent after placeholder deletion) | `receive-email:2248-2350` |
| F18 | **`service.getchez.com/` serves the waitlist** (host rule not restored post-lockdown); if `OPERATOR_PORTAL_URL` is set, every admin deep-link lands on the waitlist | vercel.json |
| F19 | **process-invoice stack-overflows on multi-MB PDFs** (unchunked btoa) and **email-forwarded invoices never reach Claude as PDFs** (extension-based media detection vs extensionless storage paths) | `process-invoice:333-336` |
| F20 | **analyze-document's post-response writes race the runtime** (never awaited, no waitUntil) — includes the `visible_to_home_managers` rewrite: a "Will" can silently keep permissive visibility | `analyze-document:372-610` |

### 4C. High/Medium — UX and data-integrity (selected; full lists in agent reports)

- **Save & Send Invite for a new family member always fails** (nil member handed to InviteToHavenSheet) — `FamilyMemberFormView.swift:365,605`
- **Trusted-contact "Send Invite" sends nothing** (flips a status flag; no send function exists) — `TrustedContactDetailView.swift:144`
- **Editing an insurance-claim project silently destroys claim mode**, orphaning sub-projects — `EditProjectSheet.swift:21,150`
- **Inert `.swipeActions` outside List** remove sole affordances (can't unlink sub-project from a claim at all) — `ProjectDetailView.swift:693,1763`
- **Shared ProjectsViewModel corrupts parent state after sub-project push** — `ProjectDetailView.swift:686`
- **`.projectChanged` has no project-surface observer** — projects created from inbox/dashboard don't appear in Property → Projects; **vendor adoption never posts `.contractorChanged`** — new vendor invisible until manual refresh
- **Duplicate `.contextMenu` on punch-item cards** — one whole menu unreachable — `HandymanPunchListView.swift:294,315`
- **"Show all hidden recommendations" changes nothing on screen** (never reloads) — `RecommendedServicesView.swift:88`
- **"I already did this" / frequency edits bypass the system service-interval override** (documented precedence violated) — `MaintenanceTaskDetailSheet.swift:1595,1686`
- **Licensed teen children can never be covered drivers** (`relationship == "child"` hard-excluded before DOB check) — `CoveredDriverPickerSheet.swift:48`
- **Vehicle photo dead end-to-end** (`photo_url` column doesn't exist; error swallowed; nothing renders it)
- **Places vendor adoption fails silently** (catch prints, no error surfaced) — `FindLocalVendorSheet.swift:1519`
- **Cockpit vendor-pipeline buttons are no-ops** (`data-pipeline-vendor-key` never read; "Mark locked" always dead-ends) — `admin.js:6665,6647`
- **Cockpit reclassification is in-memory only** (evaporates on reload); **failed dossier fetch bricks the homeowner panel for the session** with error copy that lies
- **`chez_business_hours_due()`**: weekend submits due at midnight (comment says 9am); UTC weekend boundaries disagree with the watcher's America/New_York guard by 4-5h; no holidays
- **`pending_proposal_count` drifts** on merge (not transferred) and on resolve-with-undecided-proposals
- **Data moat cascades away on churn**: chez_vendor_calls/visits/outreach/outcomes all `ON DELETE CASCADE` from households — account deletion erases cross-household vendor intel (chez_ai_usage got it right with SET NULL)
- **Vendor registry identity fragmentation**: same vendor keys differently across calls (place_id) vs visits/outreach (phone/name) → stats split across registry rows — `20270104:38-105`
- **merge_cases is irreversible and drops merged cases' calls/touches/costs from all ops metrics**
- **Standing-appointment crons likely failing nightly** (built on `current_setting()` GUCs hosted Supabase doesn't set) — check `cron.job_run_details`
- **AI brief fabricates its source count** (`existing + places + 5 // rough`) — violates the "numbers must be real" house rule — `admin.js:6844`
- **simulate-scenario still queries the dropped `estate_state` table** every run

### 4D. In-flight work assessment (your uncommitted diffs)
All safe to commit: em-dash copy cleanup across 5 files; `InvoiceProcessingViewModel` canonical-category fix (genuine improvement); `find-local-vendors` +9 canonical search terms (correct per the Q15b rule); the `MaintenanceTabView` search work (covered lightly — worth a self-review pass on the 390-line diff before commit).

---

## 5. Gaps — missing or half-built capabilities

### Homeowner
- **Expecting → born conversion doesn't exist** (baby shows "Born N days ago" forever)
- **Vehicle insurance renewal reminders promised in UI, unimplemented** (no NotificationScheduler branch; pref consumed by nothing)
- **Negotiation-email feature fully unreachable** (QuoteAnalysisView has zero callsites — whole draft-negotiation-email round-trip dead)
- **Upload quote → start project path dead** (only attach-to-existing reachable)
- **Vendor inquiry history invisible** (sheet promises status in vendor detail; fetch has zero callers)
- **Vehicle doc uploads not linked to the vehicle** (rely entirely on VIN OCR)
- **Specialty-system suggestion not wired into inbox detail** (documented deferral, still open)
- **3 of the "13" activity-feed event types are TODO stubs** (scenarioRun, recallDetected, gapAnalysisRun)
- **Deep-link scroll not wired** (highlight ring without scroll) — `MaintenanceTabView.swift:2189`
- **SubscriptionView is a placeholder** — no billing wiring at all on iOS
- Single-property assumption in maintenance/handyman/home-details preferences

### CS / Operator
- **No billing UI** — Wave 5 Stripe server actions have zero portal callers; card-on-file can't actually be used
- **Can't open a first-ever case for a quiet household** (new-case picker only lists households with existing requests)
- **No multi-turn case Alfred** (single-shot by design, deferred)
- **Onboarding**: onboard.html captures well, but there's no post-capture checklist/pipeline view (who's mid-onboarding, what's unfinished)
- **No support-inquiry surface distinct from categorized requests** — "general" category absorbs support, but there's no triage for billing/bug/how-to vs. concierge work
- **No customer health/engagement view** (who's active, who's gone quiet, whose quiz stalled)
- **Reclassification, snooze resurfacing, density toggle**: all half-built (in-memory / no timer / no UI)

### Admin
- **Admin portal unreachable in production** (and service.html links to the dead page) — all catalog/notes work requires localhost
- **No customer/household admin tooling** (lookup, merge, delete, password assist)
- **No catalog-request queue** (F14)
- **No error/observability surface** — edge-function failures reach only console logs; the operator learns about a broken email pipeline from a homeowner
- **No push-notification composer**; **no waitlist tooling**; **no feature flags**; **no build/TestFlight surface**
- **Two-admin problem**: DB policies hardcode `tom@getchez.com` while EFs use `CHEZ_ADMIN_EMAILS` — a second operator gets cases but no notes/content/portal

### Backend
- **No shared auth helper** (root cause of the S1 class)
- **No retry/dead-letter in the email pipeline** (failed classification = email gone; raw email not persisted on failure)
- **No aggregated push-failure or function-failure telemetry**

---

## 6. User stories (status: ✅ works · 🟡 partial · 🔴 broken · ⬜ missing)

### Homeowner
**Onboarding & profile**
- ✅ As a homeowner, I complete a guided quiz that builds my systems, tasks, routines, and vendors automatically, with a value meter and cinematic reveal
- ✅ I can correct my property facts up front (recap card) and trust an honest value range
- 🟡 I can review HNW subtype toggles later (works; single-property assumption)

**Tasks & routines**
- ✅ I see a seasonal task feed with year-ribbon filtering and bundle cards (search improving in-flight)
- ✅ I can delegate any task to a vendor, my handyman list, DIY, or Chez from one routing sheet
- 🔴 I can delete a task from wherever I see it (F7 — silent no-op from dashboard/push surfaces)
- 🔴 I can create a weekly routine from the add sheet (F5 — always fails)
- 🔴 I can remove a vendor from a routine or clear its time/notes (F4 — never persists)
- 🔴 I can archive a routine without my tasks silently vanishing (F6)
- 🔴 Completing a task respects my custom service interval (bypassed)
- 🔴 I get trash/recycling pickup reminders (F1 — cron reads a dead table)

**Vendors**
- ✅ I can find vetted local pros (Chez Certified) and adopt one in a tap
- ✅ I can import a vendor from a website, my contacts, or clipboard
- 🔴 My adopted vendor counts toward coverage and appears immediately (F16 + missing notification)
- 🔴 If adoption fails, I find out (silent catch)
- ⬜ I can see the status of a question I sent a vendor (inquiry history unbuilt)

**Documents & inbox**
- ✅ I forward an invoice by email and it becomes tasks, systems, and vendors
- ✅ Duplicates are detected across upload paths and I choose how to resolve
- 🔴 Tapping "Alfred finished reviewing" lands me on the item (F17 — deleted id)
- 🔴 A quote I attach in Alfred chat gets the project prompt (F15 — bypass)
- 🔴 Large scanned invoices process reliably (F19)
- 🔴 Documents I email in get analyzed as PDFs, not degraded text (F19)
- 🔴 My will stays private from my home manager even if the rewrite races (F20)

**Vehicles**
- ✅ I add a car by VIN (typed or camera) and get recalls + an AI maintenance schedule
- 🔴 I update mileage and see it reflected (F8)
- 🔴 I complete an overdue alert and it stays done (F9)
- 🔴 My 17-year-old can be a covered driver (hard-excluded)
- ⬜ I get insurance renewal reminders (promised, unbuilt)
- ⬜ My vehicle photo shows anywhere (dead end-to-end)

**Family & household**
- ✅ I invite my spouse and manage household access; staff see a restricted app
- 🔴 I can revoke a pending invite without deleting my spouse's profile (F3 — data loss)
- 🔴 "Save & Send Invite" works for a brand-new member (always fails)
- 🔴 Trusted-contact invites actually send (status-flip only)
- ⬜ My "expecting" entry converts to a child after birth

**Chez concierge**
- ✅ I delegate a task/routine/vendor to Chez and see structured Approve/Counter/Decline proposals
- ✅ I set standing instructions and spending tiers once
- ✅ 17+ entry points hand context to Chez; Alfred can escalate for me
- 🔴 My household data is protected from anyone holding a UUID (S1 class)
- 🔴 What I see as "Chez did this" can't be forged by another member or client (S4/S6)

**Projects & quotes**
- ✅ I track projects with AI feasibility/ROI, files, contacts, and quote comparison
- 🔴 I can unlink a sub-project from an insurance claim (inert swipe — impossible)
- 🔴 I can edit a claim project without destroying claim mode
- ⬜ I can turn an uploaded quote into a new project (dead path)
- ⬜ I can send an AI-drafted negotiation email (unreachable feature)

### Home Manager / Staff (missing persona)
- ✅ I manage tasks/systems/vendors/projects with my own login; private docs are hidden; the owner can grant per-document access
- 🟡 My role shows on assignment pills (works; staff edit form can't represent staff roles, re-add duplicates rows)
- 🔴 Documents defaulted private stay private if the AI rewrite races (F20)

### CS / Concierge Operator
**Case work**
- ✅ I work a queue with SLA sorting, archetype plans, AI briefs, playbooks, snippets, tags, and case-scoped Alfred
- ✅ I log vendor calls to a persistent ledger, package recommendations, send structured proposals, and record structured outcomes on resolve
- ✅ I track visits through completion/no-show — vendor reliability ground truth
- 🔴 "Needs reply" state clears when I reply (F12 — never)
- 🔴 I can resolve from the Today view (F11 — always fails, and would skip the outcome form)
- 🔴 My call-ledger edits survive hydration and tab close (F13)
- 🟡 My reclassification of a case sticks (in-memory only)
- 🔴 Pipeline-board quick actions work (no-op buttons)
- ⬜ I can start a case for a household that's never contacted us
- ⬜ I can charge the card on file (server-only, no UI)

**SLA & ops**
- ✅ I get warned before breach and see ops metrics (median response, SLA hit rate, effort/case)
- 🟡 Weekend/holiday SLA math matches expectations (midnight due-times, TZ disagreement, no holidays)
- 🔴 Merged cases keep their effort/cost in my metrics (silently dropped)
- 🔴 The homeowner can't tamper with SLA stamps or self-resolve (S5)

**Onboarding & support**
- 🟡 I onboard a new customer white-glove via onboard.html (capture works; no pipeline/checklist view afterward)
- ⬜ I can distinguish support inquiries (billing/bug/how-to) from concierge work
- ⬜ I can see customer health (quiz stalled, gone quiet)
- ⬜ I know when the email pipeline or an edge function is failing (no observability)

### Admin (founder)
- 🔴 I can reach my admin portal in production (dark since June; service.html links to the dead page)
- ✅ I manage quiz/templates/categories via the notes round-trip, with a simulator and preview (localhost only right now)
- ✅ I review and certify vendor applications
- ⬜ I can see and fulfill customer catalog requests (F14 — queue doesn't exist, emails promise 4h SLA)
- ⬜ I can look up/manage a customer household (nothing exists)
- ⬜ I can monitor system health, compose pushes, view the waitlist, manage feature flags
- 🟡 I can add a second operator (env-var allowlist works for cases; DB policies hardcode my email)

### Vendor (missing persona)
- ✅ I apply and get verified/certified, which boosts my ranking in homeowner searches
- ✅ I reply to Chez outreach by email and it threads back to the case (reply tokens)
- 🟡 My track record follows me across households (registry works; identity keys fragment across call/visit/outreach sources)

---

## 7. Recommended priority order

1. **Security sweep (S1-S13)** — one shared `requireHousehold` helper + function-by-function sweep; REVOKE on `log_chez_activity`; restrict the two homeowner RLS policies; escape the cockpit tier render; pull `test-ai`/`test-vehicle-flow`; add the SendGrid webhook secret; commit the `analysis_cache` migration and move it off the homeowner-readable table.
2. **Silent-data-loss fixes (F3, F4, F6, F13)** — invitation revoke, nil-omission clears (one `Update`-encoder pattern fix), routine-archive unlink, call-ledger merge.
3. **Broken-daily-loop fixes (F1, F7, F8, F11, F12, F5, F9)** — cadence cron repoint to `routines`, task delete wiring, vehicle refresh force, cockpit resolve/mark_read.
4. **Decide proactive-scan** (schedule it or delete it) and **restore admin portal access** (plus the service-subdomain host rule).
5. **Resilient-decoder sweep** on quote/feasibility/vehicle-lookup structs (F10) — the exact bug class that already bit you once.
6. **Close the loop features**: Stripe UI for the operator, catalog-request queue, negotiation email reachability or deletion, expecting→born.
7. **Dead-code deletion pass** — QuoteAnalysisView, HandymanHubView, MaintenanceHubSections dead sections, render-assessment-pdf, handyman-portal/crew-chat, admin PORTAL_MODE, `MarkCompleteForm`, plus the CLAUDE.md drift cleanup (MaintenanceScheduleView is gone; 60- vs 30-day vendor cache TTL; "13 event types"; functions CLAUDE.md inventory).

**Full agent reports** with every finding (including ~40 medium/low bugs not repeated here) are preserved in the session transcripts; this doc carries everything P0-P2 plus representative medium findings.
