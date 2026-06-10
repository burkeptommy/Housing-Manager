# Full-product verification — June 2026

Run started: 2026-06-09
Branch: `claude/service-desk-today-redesign` (Tom's iOS Tasks-tab WIP present and untouched; snapshot at `~/chez-verification/20260609/`)
Scope: Chez handoff pipeline, deployed-state drift, cockpit, alignment, intelligence-foundation prerequisites.

## Status Legend

- `open`: verified gap still needs a product or engineering decision.
- `fixed`: fixed, verified, committed.
- `deferred`: documented; fix exceeds this round's policy.
- `not_reproduced`: investigated and not observed.

---

## Section A — Deployed-state drift (the "old model built it, never shipped it" class)

### A1. Migration history wedged: 13 stranded files, 3 version collisions

- Category: `drift`
- Severity: `critical`
- Evidence: `supabase migration list --linked` showed pending: 20261212(telemetry twin), 20261233(telemetry twin), 20261313, 20261314, 20261318(archive twin), 20261320, 20261321..20261326, 20261334. Version collisions: 20261212 (`chez_ai_usage_telemetry` vs `walkthrough_templates`), 20261233 (`chez_ai_usage` vs `chez_ai_usage_telemetry`, byte-identical to the 20261212 twin), 20261318 (`dismissed_categories_snooze` vs `household_archive_empty_test_data`). Every `db push` since late May has required `--include-all` and would have failed mid-sequence on unguarded `CREATE POLICY`/`ADD CONSTRAINT`, so late-May work was hand-applied to prod outside history.
- Verification performed: per-version prod object checks. ALL effects confirmed live (tables chez_vendor_outreach/chez_snippets/chez_request_tags/chez_tag_definitions/dismissed_templates/walkthrough_templates; chez_requests CRM columns; merge trigger; outreach policies x3; households.archived_at with 248 archived; redding-sanitation row; fabricated-vendor purge confirmed: 0 `ma-%` templated rows remain; utility_providers source/contribution_count/visible view; google_place_id UNIQUE constraint) EXCEPT `home_assessments.preferred_dates` (A2).
- Fix applied (Tom-approved): deleted both byte-duplicate telemetry files; renamed archive twin to `20261319_household_archive_empty_test_data.sql`; `supabase migration repair --status applied 20261313 20261314 20261319 20261321 20261322 20261323 20261324 20261325 20261326 20261334`; `supabase db push --include-all` (ran exactly one statement). Post-state: zero pending migrations, history 1:1 with files.
- Status: `fixed`

### A2. LIVE BUG: assessment reschedule 500s in prod (preferred_dates column missing)

- Category: `verification`
- Severity: `critical`
- Evidence: repo chez-concierge writes `preferred_dates` since commit b2efe9cf (2026-05-19); function deployed v31 on 2026-05-25; column absent from prod (migration 20261320 stranded by A1). Any homeowner submitting the Reschedule sheet with preferred dates hit a PostgREST column-not-found error.
- Fix applied: `20261320` pushed via A1 remediation; column verified present (`information_schema.columns` count = 1).
- Status: `fixed`

### A3. Stale function deploys (repo ahead of prod)

- Category: `drift`
- Severity: `major`
- Evidence (`supabase functions list` vs `git log -1` per dir):
  - `chez-concierge` deployed v31 2026-05-25; repo changed 2026-05-26 (d15ded93 "service desk: Today redesign + scroll fixes", 4ddf1626 operations scrub). The live service desk Today view runs against a server missing the Today-redesign delta.
  - `receive-email` deployed v74 2026-05-13; repo changed 2026-05-19 (e9c24395 "Phase 86C: vendor outbound + negotiation wired") — inbound vendor-reply routing improvements not live.
  - `chat` deployed v44 2026-05-18; repo changed 2026-05-19 (26358263 friend-feedback fixes).
  - `submit-vendor-application` deployed v1 2026-05-01; repo changed 2026-05-22 + 2026-05-26.
- Suggested fix: redeploy all four in the rollout batch (chez-concierge is redeployed by the foundation work anyway).
- Status: `open` (queued for rollout batch)

### A4. Reachability under waitlist lock

- Category: `verification`
- Severity: `none` (intentional)
- Evidence: service.getchez.com, www/.../service.html, vendor-apply.html all 307 to waitlist; root 200; admin.getchez.com no response (no DNS). Matches the June 2 intentional lock; operator access is local-only.
- Status: `not_reproduced` (as-designed; revert path documented in memory)

## Section B — Baselines

- iOS build (Chez scheme, Debug, generic iOS Simulator): **BUILD SUCCEEDED**, 0 errors, 2 warnings. Tom's WIP compiles. Log: `~/chez-verification/20260609/xcodebuild.log`.
- Website JS: 6/6 modules pass `node --input-type=module --check`.
- Deno type-check baseline (63 functions, first-ever run): pre-existing diagnostics recorded in `~/chez-verification/20260609/deno-baseline.txt` (notable: handyman-provider 781, chez-concierge 237, chat 46, find-local-vendors 38, crew-chat 30, handyman-portal 46). These are baseline noise (functions run in prod); gate is differential: no NEW errors in touched files.
- Chez scheme has empty `<Testables>` — `xcodebuild test` runs zero tests despite 7 HavenTests files. Status: `deferred` — the scheme file is inside Tom's uncommitted WIP and the founder redirected this session exclusively to service-portal capabilities (2026-06-10); wiring testables belongs in the next iOS-focused session, ideally via project.yml + xcodegen once the WIP lands.

## Section C — Cockpit

### C1. Today-view Snooze button always 400s

- Category: `verification`
- Severity: `major`
- Evidence: website/admin.js:19603 sends `{ action: "transition_status", status: "waiting_customer" }`; server reads `payload.to_status` (chez-concierge/index.ts:826) and 400s on missing value. Every other transition site sends `to_status` correctly.
- Suggested fix: rename key to `to_status`.
- Status: `open` (fix wave)

### C2. Vendor call ledger is browser-memory only

- Category: `persistence_finding`
- Severity: `critical` (data-moat: highest-value operational data evaporates)
- Evidence: `state.chezVendorCallsByRequest` (admin.js 6442/7022/7983/10340-10520/11864-11960) holds per-candidate outcome/notes/recommended/availability_slots/cost; never persisted; lost on refresh; deleted after package-send (12379). Reaches server only as prose in `suggest_vendor_framing` prompts and packaged proposal JSONB.
- Suggested fix: intelligence foundation A (chez_vendor_calls table + save/fetch actions + debounced persist + hydration).
- Status: `open` (foundation)

## Section D — Server

### D1. SLA computed but never watched
- Severity: `major`. sla_due_at only read by fetch_upcoming/fetch_today_brief; no proactive alerting; warn/breach stamps absent. Fix: foundation F (chez-sla-watch + pg_cron). Status: `open` (foundation)

### D2. Playbook stubs
- Severity: `minor` (documented Phase 86D v1 scope). coordinate_task/schedule_visit/get_quote are first-touch-only no-ops (index.ts:544-565). Fix: foundation G. Status: `open` (foundation)

### D3. assign_case / merge_cases / link_case have zero UI callers
- Severity: `minor`. Server handlers complete (6603/6632/6696); cockpit never calls them. Fix: foundation H (header overflow menu). Status: `open` (foundation)

### D4. dismissed_templates sister backfill missing
- Severity: `minor`. 20261334 comments reference sister `20261335_migrate_dismissed_categories.sql`; no such file exists in repo; table + policy live in prod. Verify iOS reads/writes against it and whether the category→template backfill ever ran. Status: `open`

## Section E — Phase 1 contract findings

### E1. Full e2e suite PASSED (runtime verification of the Chez pipeline)
- Evidence: `~/chez-verification/20260609/e2e-run2.log` — all phases green, 0 issues: signup → property-lookup → onboarding → intake → mode fork → full quiz (36 questions) → combinatorial matrix rows 3.1-3.36 → quiz completion (7 tasks) → 5 tasks delegated via chez-concierge delegate_task → smart routing (find_vendor vs coordinate_task split) + chez_owned stamping verified. One stale fixture name fixed first (Q17 "Optimum Fairfield CT" → fallback to consolidated "Optimum" row, run.mjs:1482, mirrors existing fallback at 2168 — fallout of the 20261323 brand-shard dedup).
- Status: `fixed` (test) / pipeline `verified`

### E2. cadence-notifications never scheduled — pickup-day pushes have never fired
- Category: `gap` | Severity: `major`
- Evidence: `cron.job` has only 4 jobs (auto-resume-standing-appointments, catalog-expand-nightly, haven_send_invite_reminders_daily, roll-forward-standing-visits). No job posts to cadence-notifications, so Phase 54D evening-before / morning-of push reminders never fire. In-app PickupDayBanner unaffected.
- Suggested fix: add two pg_cron entries (evening_before, morning_of) in the SLA-watch cron migration.
- Status: `open` (fix wave)

### E3. cleanup-stale-vendor-applications never scheduled
- Severity: `minor`. Deployed v1, zero cron entry, zero callers. Stale `pending_email_confirm` applications accumulate forever. Fix alongside E2. Status: `open`

### E4. Push types with generic-only handling (tap lands on default tab, no deep link)
- Severity: `minor`. `cadence`, `calendar_invite`, `inbox_processing`, `inbox_ready` (receive-email), `part_request_blocking` (handyman-provider) fall through to the default branch in HavenApp push routing. Not crashes; UX polish. Status: `deferred`

### E5. Inbox types `vendor_added` / `project_created` render via fallback card only
- Severity: `minor`. receive-email writes these types (lines ~2100/~2129); InboxItemCard has no explicit branch — verify visually that the fallback presentation is acceptable. Status: `deferred` (simulator pass)

### E6. handyman-provider still links to removed handyman.html / handyman-quote.html
- Severity: `minor` (transition state). PROVIDER_SITE_URL/QUOTE_SITE_URL (handyman-provider/index.ts:19,26) point at pages deleted May 26 and waitlist-locked besides — portal invite links are dead pending the offline-visit-surface direction. Per founder decision 2026-06-09: NO contractor portal; contractors get verified via vendor_applications only. Status: `open` (documented in CLAUDE.md refresh; product direction, not a code fix)

### E7. Quiz triple-implementation diff: NO breaking drift
- iOS (source of truth) vs _shared/quiz-mapper-shared.ts vs admin-simulator.js: aligned on every contract-bearing vocabulary; differences are intentional subsets/coarsenings (simulator models gating only: tank vs tank_gas split, salt vs saltwater, 13 of 21 Q15b chips by design). Status: `not_reproduced`

## Section F — Rollout verification (2026-06-10)

All 10 foundation migrations applied (zero pending); chez-sla-watch + chez-concierge + receive-email + chat + submit-vendor-application deployed; 3 tables + 6 views + 4 cron jobs verified in prod; SLA watcher caught 12 genuinely-breached cases on its first automatic tick and the manual tick correctly found 0 new (stamp idempotency proven); deployed dispatcher smoke-tested (`fetch_vendor_registry` → "admin only").

## Section G — Homeowner functionality sweep (2026-06-10, as the fixture homeowner via prod APIs)

Method: authenticated as the e2e fixture homeowner (JWT) against the exact endpoints/tables iOS calls; operator side fabricated via service-role SQL where a second party was required.

| Area | Result | Evidence |
|---|---|---|
| Pass-off: per-routine delegation | PASS | create routine → delegate_routine → chez_owned stamped + standing-engagement case |
| Pass-off: go-all-in | PASS | set_ownership_group all_vendors → 17 contractors backfilled + group recorded |
| Pass-off: per-task | PASS (prior e2e) | 5 tasks delegated with correct find_vendor/coordinate_task smart routing |
| Collaboration thread | PASS | homeowner reply → message + unread_for_admin; mark_read clears |
| Vendor proposal approve | **PASS after 2 prod fixes (G1, G2)** | contractor persists w/ chez_recommendation source, numeric rating, google_place_id, provenance; visit auto-created awaiting_date |
| Vendor scheduling (date_slot) | PASS | approve → oldest awaiting visit flips to scheduled with picked ISO |
| Find vendors | PASS | find-local-vendors Bethel/CT/electrician → 19 ranked results |
| Assign tasks | PASS | PATCH assigned_to_user_id round-trips under RLS |
| Add home members | PASS | family_members insert; invitation row gets the new 30-day expiry default; invite email sends |
| Add systems | PASS | home_systems insert + read-back (Water Heater / tank_gas) |
| Scan systems | PASS (note) | identify-equipment returns graceful structured no-match on a JPEG; PNG input is 400ed because media type is hardcoded image/jpeg — iOS always re-encodes JPEG so in-app flow unaffected. `deferred` server robustness note |
| Add warranties | PASS | warranties insert linked to new system |
| Forward documents/quotes | **PASS after prod fix (G3)** | accepted → Claude classified contractor_quote (high) → actionable inbox item; dedup guard works; rejection path produces a graceful explainer item |
| Inbox actions | PASS | process-inbox-item dismiss contract verified; quote docs materialize on save/project actions by design |
| Saving/persistence | PASS | every write re-read under homeowner RLS |

### G1. FIXED LIVE BUG: "Chez remembers" never persisted approved vendors (source CHECK)
- Severity: `critical` (feature dead since Phase 83.3 shipped)
- contractors_source_check allowed only manual/quiz/find_vendor/chez_field; decide_proposal inserts source='chez_recommendation' → constraint violation, swallowed by try/catch; zero rows ever created. Visits being created masked it.
- Fix: migration 20270110 extends the CHECK. Status: `fixed` (verified live)

### G2. FIXED LIVE BUG: contractors.rating was INTEGER, proposals carry floats
- Severity: `critical` (second independent killer of the same write)
- Every Places rating (4.6, 4.8) failed text→integer cast via PostgREST (22P02), swallowed. Fix: migration 20270111, rating → numeric(2,1). iOS follow-up: ContractorRow.rating is Int? (resilient decode → fractional ratings show as nil until the model moves to Double). Status: `fixed` (verified live: 4.7 persisted)

### G3. FIXED LIVE BUG: email forwarding rejected every homeowner (empty whitelist)
- Severity: `critical` (flagship pipeline dead for all households)
- Phase 86C (May 19 commit) added the household_allowed_senders gate with no seeding and no member auto-allow; the table had ZERO rows. Latent in repo; ACTIVATED by this session's stale-deploy catch-up of receive-email on 06-09. Caught within a day by this sweep.
- Fix: receive-email now auto-allows household members (and self-heals them onto the list); migration 20270112 backfills all household users (6 seeded). Status: `fixed` (verified live: full classify→inbox flow green)

Sweep artifacts: fixture household keeps the created entities (contractor "Sweep Final Electric", 3 visits incl. one scheduled, system, warranty, member, invitation) for cockpit/simulator inspection; all sweep-opened chez cases resolved.
