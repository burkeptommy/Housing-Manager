# Chez Mission Audit: the gaps between today and 100:1

Date: 2026-06-10. Branch: `claude/service-desk-today-redesign`.
Method: full-product verification (compile, e2e against prod, contract audits, deployed-state drift, claims-vs-reality review) followed by a deliberately skeptical read. Evidence lives in `Tests/e2e/VERIFICATION_2026-06_GAPS.md` and `~/chez-verification/20260609/`.

The mission being audited, in the founder's words: homeowners hand off work to a human at Chez (all in, or item by item); the business gets smarter with every task and every home so operator leverage goes from 20:1 to 100:1; vendors come onto the platform so coordination stops being phone calls.

Naming note: the **service portal** (service.html, service.getchez.com) is where customers are serviced. admin.html is back-of-house content tooling. Both load the same module; service mode filters to the action views (Today, Homes, Concierge, Upcoming, Audit, Vendor Apps). Every operator-facing item below refers to the service portal.

Scope boundary (founder, 2026-06-10): **Chez does not do dispatch or visit execution.** The business is vendor-relationship management on the customer's behalf (sourcing, scheduling, making sure vendors show up for routines and tasks) plus managing home maintenance schedules when delegated. Anything that puts a Chez person or a Chez-dispatched worker inside a home (assessment dispatch, field workspaces, visit-execution tooling) is out of scope permanently. Visit TRACKING of third-party vendors stays in scope: that is the relationship-management data.

---

## 1. The honest numbers (production, 2026-06-09)

| Metric | Value | Read |
|---|---|---|
| Active households | 5 (248 archived test rows) | The pilot is 4 to 5 real homes, not 10, not 50 |
| chez_requests, all time | 17 (10 of them created by this session's e2e runs) | ~7 organic concierge cases EVER |
| concierge_messages, all time | 17 | Essentially first-touch only; near zero operator threads |
| chez_visits / completed | 0 / 0 | No tracked visit has ever run through the case pipeline |
| Vendors sourced by Chez (contractors.chez_recommended_at) | 0 | The proposal-to-vendor loop has never fired organically |
| chez_vendor_outreach emails | 0 | The vendor email channel has never been used |
| vendor_applications / chez_certified | 0 / 0 | The vendor supply side is empty |
| Households with ownership groups on | 2 | Go-all-in has been used twice |

**The skeptical topline: the machine is real and now verified end to end, but the business has near-zero operational history.** The 20:1 ceiling is a projection; nobody has operated even 5:1 through this system yet. The data moat was, until this session, a warehouse with the doors open: the highest-value data (vendor call outcomes) evaporated on every browser refresh, and every metric needed for the 100:1 claim (operator minutes, outcomes, final costs, vendor reliability) was uncaptured. That is now fixed at the schema and capture layer, but the dataset starts at approximately zero. The moat compounds only if (a) capture discipline holds and (b) the GTM engine produces case volume.

## 2. Pillar scorecard

| Pillar | Plumbing | Operations reality |
|---|---|---|
| 1. Handoff to a human | VERIFIED WORKING (e2e green: submit, delegate, smart routing, go-all-in, 17 iOS entry points, entity toggles for routine/contractor/task/system/project/document/utility/vehicle) | Barely exercised; single operator; quality signal absent |
| 2. Data moat / 100:1 | Foundation BUILT THIS SESSION (call ledger, outcomes, visit facts, registry, effort telemetry, ops metrics, SLA watcher), pending deploy | Dataset ~zero; discipline untested; scale math demands case volume the GTM hasn't produced |
| 3. Vendor digitization | Email loop + application/verification flow exist | Zero vendors, zero outreach sent, SMS blocked on consent review, no vendor-facing scheduling primitive |

## 3. Gap register

Severity = how hard it blocks the mission. Effort: S < 1 day, M = days, L = weeks+.

### Pillar 1: the handoff

| # | Gap | Evidence | Why it blocks 100:1 | Close | Effort |
|---|---|---|---|---|---|
| H1 | **Operator quality has no feedback signal.** No homeowner rating, no satisfaction capture, no structured reopen reason. | No schema or UI for it anywhere | At 100 homes you cannot detect service slippage until churn. Reopen rate is the only proxy and it is noisy | 1-tap rating on resolved cases in the iOS thread (server: rating column on chez_request_outcomes; iOS: small addition to ChezRequestDetailView) | M |
| H2 | **Spending tiers are decorative.** Profile promises auto-approve under $X; nothing enforces or even references tiers at decision time | chez_profile.spending_tiers read only for display in dossier | Every approval is a homeowner round trip; the single biggest latency+effort multiplier per case | Tier check in propose/decide flow: auto-approve proposals under tier with system message "within your standing approval" | M |
| H3 | **The "5 free concierge requests" waitlist promise has no ledger.** Live on the only public page, repeated twice | No entitlement/counter anywhere (alignment row #1) | You cannot honor, meter, or expire the headline acquisition promise; manual bookkeeping at launch scale | Perk counter on households.chez_profile stamped at onboarding from the Viral Loops export + service portal visibility | S/M |
| H4 | **Onboarding capture is self-serve only.** DECIDED 2026-06-10: Chez does NOT do dispatch or visit execution, period. The home-assessment dispatch machinery (workspaces, assignment, field lifecycle, dead handyman.html links) is out of scope and should be decommissioned, not finished | Founder direction; E6 in findings | "Every home onboarded" feeds the moat only if capture happens; the quiz + operator-guided capture (phone/video walkthrough recorded into the service portal) is the whole funnel now | Decommission plan: stop surfacing assessment booking in iOS, retire assignment actions after an iOS release stops calling them, scrub dead URLs. Invest instead in quiz depth + operator-guided capture | M (sequenced) |
| H5 | **Single operator, bus factor 1.** assign_case existed with no UI (being wired); no runbook; no second-operator drill | This session wires Mine/assign; the rest is organizational | 100:1 still means multiple operators at scale; nothing about the playbooks is written down outside Tom's head | Operator runbook doc + case assignment discipline once a second person exists | M |
| H6 | **Proposal declines lose their why.** Decline is a bare status | ChezProposalCard has no reason capture | Decline reasons are the cheapest labeled data for improving sourcing; all discarded | Structured decline reasons (too expensive / timing / chose another / changed mind) on decide_proposal + iOS sheet | M |
| H7 | SLA was promised and unwatched | Built this session (chez-sla-watch + cron), pending deploy | A 24h promise nobody enforces becomes a 3-day reality at volume | Deploy + verify | S |
| H8 | Reopen/status history is system-messages-only, not queryable | No status_transitions log | Cannot compute reopen rate cleanly (quality metric) | Derive from system messages short-term; add transitions table later | S/M |

### Pillar 2: the data moat

| # | Gap | Evidence | Why it blocks 100:1 | Close | Effort |
|---|---|---|---|---|---|
| D1 | **All operational history to date is gone.** Call ledger was browser memory; outcomes never existed | C2 in findings | The moat clock starts now, not at founding. Every week pre-deploy is compounding data lost | Deploy the foundation (built); operate through it religiously | S |
| D2 | **Scale math.** ~5 homes producing ~7 organic cases means the "model" will be heuristics + playbooks for a long time. "Immense data" needs thousands of cases | Section 1 numbers | A data moat with no data is a schema. Distribution IS the moat strategy for the next year | Be honest internally: moat = capture discipline + GTM volume. The foundation makes every future case count; it cannot conjure history | n/a |
| D3 | **Capture discipline is a human risk.** The resolve mini-form, visit facts, and call outcomes only accrue if the operator fills them every time | Required-form decision made; still behavioral | Sparse labels poison every downstream metric (effort, automation candidates, vendor scores) | Form is required in UI + prefilled to ~2 taps; monthly audit query: % resolved cases with outcomes | S (ongoing) |
| D4 | **Vendor identity dedup is heuristic.** place_id, then phone, then name+town; no merge tooling for vendor identities | chez_vendor_key design | Duplicate identities split a vendor's history and quietly corrupt the registry stats the operator will trust | Acceptable at current scale; add identity-merge tooling before ~1k registry rows | M (later) |
| D5 | **No model evaluation loop.** analyze/playbook output quality is unmeasured; prompt changes ship blind | chez_ai_usage tracks cost only | "Model gets smarter" requires knowing when it got dumber. Funnels (built) measure conversion, not answer quality | Lightweight eval set: 20 real cases with expected categories/vendors; run on prompt changes | M |
| D6 | Operator effort signal is new and approximate (30-min capped sessions + optional quick-pick) | Built this session | Effort-per-case is THE denominator of 100:1; garbage in = fictional leverage claims | Honest usage + monthly sanity check vs calendar reality | S |
| D7 | **Pricing ground truth is empty.** Fair-market claims on the site outrun any data; quoted vs final capture starts now | Alignment #5, #20 | Pricing intelligence is a moat pillar; today it is operator judgment | Accrues from quoted_cost_cents + final_cost_cents; revisit copy until then | n/a |
| D8 | **Pipeline reliability is a process gap.** Migration history silently wedged for 2+ weeks (3 version collisions); late-May work hand-applied to prod; deployed functions drifted days behind repo; a live 500 (preferred_dates) shipped unnoticed | Section A of findings, all fixed/unwedged this session | For a data business, silent schema drift IS data loss. The cause (no CI, no drift alarm, single prod env, no staging) remains | Pre-push drift check in a session checklist or CI; weekly `supabase migration list` + functions-list diff; decide on staging project | M |
| D9 | **Nothing watches the system.** Edge function failures are console.warn into the void; no error alerting; backup script exists but scheduling unverified | grep: no Sentry/alerting anywhere | An unnoticed week of failed writes = a hole in the dataset and broken promises | Minimal: SLA watcher pattern extended to a daily "system pulse" email (function error rates from logs, table row deltas) | M |
| D10 | Docs drift starves the AI workforce. CLAUDE.md documents Phase 83; code is at ~100. This session's drift archaeology cost hours because docs lied | CLAUDE.md vs repo | Tom's leverage is AI sessions; stale docs tax every one of them | CLAUDE.md refresh (queued this session) + keep the progress rule | S |

### Pillar 3: vendor digitization

| # | Gap | Evidence | Why it blocks 100:1 | Close | Effort |
|---|---|---|---|---|---|
| V1 | **Vendor supply is zero and acquisition is OFF.** vendor-apply.html 307s to the waitlist; zero applications, zero certified | Reachability check; DB counts | The whole pillar is theoretical until vendors exist. Every Chez-sourced job is a missed enrollment opportunity | Unlock vendor-apply from the waitlist redirect (one vercel.json carve-out); enroll every vendor Chez touches on a case ("you just got hired through Chez, claim your profile") | S |
| V2 | **Email is the only digital channel and it has never been used** (0 outreach rows). SMS reserved pending a consent review nobody owns | chez_vendor_outreach empty; channel enum | Phone-tag is the single biggest operator time sink per case | Use the email loop on real cases; assign the SMS consent question a deadline; log calls in the ledger (now persistent) | S |
| V3 | **No vendor-facing scheduling primitive.** "Everything digital in-app" currently means vendors reply to emails. No portal (by decision), but also no tokenized one-shot pages | Founder decision: no portal | A vendor cannot confirm a slot, send a quote, or update arrival without a human translating | The wedge that fits "no portal": per-case tokenized vendor pages (pick-a-slot, attach-a-quote) reusing the reply_token pattern already in chez_vendor_outreach. One page, no login, mobile-friendly | M/L |
| V4 | Chez Certified ranking exists but ranks an empty set; vendor incentives are weak while homeowner volume is small | find-local-vendors merge logic; 0 certified | Classic chicken-and-egg; certification means nothing until it routes real jobs | Seed certification from vendors who complete Chez jobs well (registry data now exists to justify the badge) | S (process) |
| V5 | The 6,650-cell Places seeding sweep builds coverage, not relationships (418 cells done) | scripts/seed-progress.json | Candidate lists shorten search, not coordination | Fine as-is; finish the sweep; the registry layers relationship data on top | S (running) |
| V6 | Old handyman/field surfaces half-decommissioned: dead URLs in handyman-provider, stale capability claims | E6, alignment #14/#15 | Confuses the vendor story; mails broken links if the flow fires | DECIDED: no dispatch/execution ever. Scrub the URLs, cut the capability copy, and fold the decommission into H4's sequence | S |

### Cross-cutting business gaps

| # | Gap | Why it matters | Close |
|---|---|---|---|
| X1 | **Marketing integrity debt.** Live page: "5 free requests" (no ledger), "50+ homeowners" (internal record: ~10 couples; prod: 5 active), hero mockup showing 3 nonexistent dashboard features, unhedged testimonials (one describes a cost-basis ledger that does not exist). At-unlock: fabricated founder persona "Will Hartley" on capabilities.html, "architecturally inaccessible to anyone but you" (false by design: the concierge requires operator access; violates your own no-overclaim rule), removed-but-claimed contractor app | A trust-positioned brand making provably false claims is existential, and several are live NOW. The Will Hartley persona is indefensible if ever noticed | Copy pass before any unlock; each alignment row has a binary fix-product/fix-copy action (full table in the alignment review) |
| X2 | **Password reset is dead for pilot users.** The waitlist lock 307s reset-password.html; Supabase auth emails link there | Live harm to the ~5 real households today | One vercel.json carve-out for /reset-password.html | 
| X3 | **No revenue machinery.** Stripe test mode; free pilot; "price built into your subscription" claimed with no billing shipped | 100:1 efficiency of a $0 product is still $0; pricing also shapes which homes you want | Decide pricing; ship billing before unlock |
| X4 | **Unit economics are unmodeled.** No target for operator minutes/case, cost/case (AI spend is capped and tracked, the rest is not), or revenue/home | "Great business" needs the spreadsheet; the new ops metrics provide the inputs | Set targets once 30 days of foundation data exists |
| X5 | e2e + fixtures run in the production project; only fixture hygiene separates test from customer data | One bad cleanup edit away from a mess | Keep the e2e-% discipline; consider a staging project when there is real customer volume |
| X6 | The service portal is local-only today (intentional waitlist lock) and OPERATOR_PORTAL_URL deep links in pushes/emails 307 until unlock or env override | SLA pushes will link to the waitlist | Set OPERATOR_PORTAL_URL secret to the locally-reachable origin, or carve out service.html for Tom's IP/basic auth |
| X7 | Operator surfaces have no tests at all (the iOS side has 801 matrix rows; admin.js has node --check) | The cockpit is the business-critical surface with the thinnest safety net | Smallest useful step: a Tests/e2e/run-service-desk.mjs that exercises the new actions with an admin JWT |

## 4. What was verified working (so nobody re-audits it)

Full e2e suite green against prod (signup, lookup, onboarding, full quiz, combinatorial matrix, quiz completion, 5-task delegation with correct find_vendor/coordinate_task smart routing, chez_owned stamping). iOS builds clean (0 errors). All 48 chez-concierge actions contract-match their callers. Go-all-in (8 ownership groups, staged with workload preview) works. 16 of 17 documented iOS entry points wired (MaintenanceScheduleView's documented one does not exist; superseded surface). Inbox + push routing for chez types correct. Quiz triple-implementation aligned. Brand voice clean (no "Tom" leaks to homeowners).

## 5. Fixed or built in this session (pending deploy where marked)

1. Migration history unwedged: 3 version collisions resolved, 10 verified-live versions repaired into history, `preferred_dates` pushed. LIVE BUG FIXED: assessment reschedules no longer 500 (was live since ~May 25).
2. Pickup-day push reminders scheduled for the first time (cadence-notifications was never cron'd); stale-vendor-app cleanup scheduled. (cron migration, pending push)
3. Today-view Snooze button fixed (sent `status:` instead of `to_status:`; 400'd every time). (pending site deploy)
4. Duplicate "Homes" nav entry removed from the service portal nav. (pending site deploy)
5. **Intelligence foundation, server side complete** (pending `db push` + chez-concierge redeploy): persistent vendor call ledger (chez_vendor_calls + save/fetch actions), structured case outcomes (chez_request_outcomes + required resolve form contract), structured visit completion (on-time/no-show/final cost), cross-household vendor registry (identity spine + scorecard views + fetch action + analyze_request annotation), operator effort telemetry (chez_operator_events + effort view), SLA watcher (chez-sla-watch + 15-min cron + idempotent stamps), all four category playbooks live (coordinate_task/schedule_visit/get_quote now pre-warm briefs with mode-specific prompts + cost references), ops metrics views + fetch_ops_metrics.
6. Security claims hardened: access_log made immutable at the grant layer; invite codes now actually default to 30-day expiry. (pending push)
7. e2e fixture fix (stale Optimum reference). Findings log: `Tests/e2e/VERIFICATION_2026-06_GAPS.md`.

Still in flight from this session: service-portal UI wiring for the foundation (ledger persist/hydrate, resolve mini-form modal, visit completion inputs, Network tab, merge/link/assign menu, Insights strip, operator events), CLAUDE.md refresh, PROGRESS.md, deploy batch + rollout verification.

## 6. How the moat actually compounds (the architecture now in place)

Every case now leaves four artifacts: the call ledger (including losing candidates), the structured outcome (resolution, winner, final cost, effort, automation flag, friction tags), visit ground truth (showed, on time, real price), and effort telemetry. These feed three compounding loops:
- **Vendor graph**: chez_vendor_registry unifies contractors, calls, outreach, applications, and the Places seed under one identity; analyze_request already consumes it, so the second case in a category+town starts from "you called these 4, two answered, one won" instead of zero.
- **Playbook funnels**: chez_playbook_funnel measures submitted to pre-analyzed to proposed to approved to completed per category; the deltas say which categories to automate next, and automation_candidate labels say which cases software could have closed.
- **Per-home state**: quiz + assessments + owned entities mean zero context rebuild per case (already strong; the genuinely differentiated asset today).

The automation ladder, each rung gated by the metrics below it: suggest (registry-ranked candidates, drafted scripts: LIVE once deployed) → prefill (outcome + proposal prefills: LIVE) → auto-with-approval (drafted vendor outreach pending one click; tier-gated auto-approve, H2) → auto (standing routines scheduled inside spending tiers with no touch). The 100:1 proof metrics: median effort minutes/case trending down, automation_rate (resolved with ≤1 operator message) trending up, SLA hit rate stable while volume grows, cost/case under a ceiling. All of these are now queryable; none of them have data yet. That is the moat in one sentence: **the instruments exist as of today; the flying hours do not.**

## 7. Recommended order of attack

1. Now: deploy the foundation (migrations + chez-concierge + chez-sla-watch + site), finish the service-portal wiring, and start operating EVERY case through it. (D1, D3, H7)
2. This week: vercel carve-outs for reset-password + vendor-apply (X2, V1); set OPERATOR_PORTAL_URL (X6); copy pass on index.html live claims (X1); send the first real vendor email through the outreach loop (V2).
3. This month: homeowner rating on resolve (H1); decline reasons (H6); spending-tier auto-approve (H2); the waitlist perk ledger (H3); SMS consent decision (V2); drift-check ritual (D8).
4. Next quarter: tokenized vendor scheduling pages (V3); assessment/field-visit direction (H4); eval set for the AI layer (D5); billing (X3); unit-economics targets from the first 90 days of foundation data (X4).
