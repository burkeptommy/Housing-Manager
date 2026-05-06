# Handyman field-app test matrix

Pragmatic plan for exercising every meaningful flow in the **Chez Field**
iOS app (handyman / provider side) against the booted iPhone simulator
+ the live `haven-dev` Supabase project. Parallel to
[Tests/e2e/TEST_MATRIX.md](TEST_MATRIX.md) which covers homeowner
onboarding.

> **Important framing:** this matrix is the **desired-state spec**, not
> an audit of what's currently built. Every row describes a behavior
> the Field app *should* support to deliver the value proposition
> (CRM-grade customer management, live visit execution, on-behalf-of
> onboarding, proactive selling). Subagent runs discover whether the
> behavior exists, partially exists, or is a gap to feed back into
> product planning. Each subagent should explicitly file a `gap_found`
> entry whenever an expected affordance is missing.
>
> Subagents should NOT skip a scenario just because the surface doesn't
> exist yet — log the gap, move on.

Two surfaces:

  - **Field app** (Chez Field scheme, separate from homeowner Chez).
    Bundle id and login flow may be shared or separate; either way the
    in-app experience is handyman-specific.
  - **Operations / admin web portal** (`/operations/*` SPA at
    `website/operations/`) — Tom's desk for routing requests + crewing
    visits + reviewing analytics. Some test scenarios cross both
    surfaces.

For each row:

  | Mark | Owner | Why |
  |------|-------|-----|
  | **`UI`** | iOS Simulator (computer-use driving Chez Field scheme) | Behaviour depends on tap order, on-device camera/photos, multi-step forms, live state. |
  | **`E2E`** | `Tests/e2e/run-handyman.mjs` (new — Node, calls Edge Functions + PostgREST + admin endpoints) | Behaviour is deterministic write-and-verify against the schema; cheap to combinatorially expand. |
  | **`Web`** | Admin operations desk SPA driven via `mcp__claude-in-chrome__*` | Behaviour requires the desktop layout (Concierge cockpit, queue rail, Alfred sidebar). |
  | **`Fixture`** | Backend seed data step (run before any UI/E2E run) | Setup of multi-household relationships, test crew, sample quotes, etc. |

---

## 0. Test fixtures — backend setup

Before any UI test can exercise multi-household behavior, we need a
test handyman workspace linked to N test homeowner households. All
fixture work happens via service-role JWT against PostgREST + Edge
Functions; no UI required.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 0.1 | Create test workspace `e2e-handyman-w1-${TS}@havenhome.test` | Fixture | Provider workspace + admin member row. Use `provider_workspaces` table or whatever the schema calls it. Workspace name like "E2E Handyman Co". |
| 0.2 | Create test crew member (`e2e-handyman-crew-${TS}@havenhome.test`) | Fixture | Different role than the admin so we can test admin-vs-crew permissions. |
| 0.3 | Create 5 test customer households linked to W1 | Fixture | `e2e-customer-w1-${i}-${TS}@havenhome.test`. Different states: (a) clean linked-yesterday, (b) populated with 3+ systems, (c) pre-quiz (haven't done the homeowner quiz), (d) post-handyman-assessment (their app shows everything Chez set up), (e) overdue for service. |
| 0.4 | Link customer 1 to W1 as "active" customer | Fixture | The relationship row that lets the handyman see this customer. May be `provider_workspace_household_links`, `households.preferred_handyman_workspace_id`, or something else — whatever the schema chooses, every test customer needs this stamped. |
| 0.5 | Customer 2: link request pending (handyman invited, homeowner hasn't accepted) | Fixture | Tests the "accepted vs invited" state. |
| 0.6 | Customer 3: link declined | Fixture | Tests rejection / removal. |
| 0.7 | Multi-workspace handyman (W1 admin is also crew at W2) | Fixture | Tests workspace-switching at the top of the field app. |
| 0.8 | Sample quote drafts on each customer (`provider_quotes` rows) | Fixture | At least 1 draft, 1 sent, 1 accepted, 1 expired per customer who's expected to see them. |
| 0.9 | Sample scheduled visits across the 5 customers | Fixture | Mix of scheduled / in-progress / completed / cancelled / no-show. Cover today / this week / next month. |
| 0.10 | Sample messages thread per customer | Fixture | At least 1 message thread per customer, one with unread inbound, one with read-all, one with system-events only. |
| 0.11 | Cleanup script: `Tests/e2e/cleanup-handyman.sql` | Fixture | Wipes every `e2e-handyman-*` and `e2e-customer-of-handyman-*` user, their workspace, links, quotes, visits, messages. Idempotent. |
| 0.12 | Backend runner: `Tests/e2e/run-handyman.mjs` | Fixture | Mirrors `run.mjs` for the handyman side. Sets up + verifies fixtures, exercises Edge Functions directly, returns the same per-phase pass/fail summary. Used as a sanity check before any UI run + as the canonical regression test. |

---

## 1. Account creation + workspace setup

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 1.1 | Brand-new handyman signup (email/password) | UI | Should land on a workspace-creation flow, NOT the homeowner foundational form. If it lands on the homeowner side, that's a routing gap. |
| 1.2 | Handyman signup via Apple Sign In | UI (skip — needs real Apple ID) | Manual QA only. |
| 1.3 | Workspace creation: business name + logo + service area + trades | UI | First-run wizard for the workspace owner. Service area = ZIP codes or radius. Trades = HVAC / Plumbing / Electrical / General / etc. |
| 1.4 | Workspace customization: brand color + hourly rate + business hours | UI | Per the Operations Desk design language — workspace branding propagates to quotes + customer-facing emails. |
| 1.5 | Joining an existing workspace (invited via email link) | UI | Email contains a tokenised link; opening it on a fresh install routes through invite-acceptance instead of signup. Verify the role assigned (admin / crew / view-only). |
| 1.6 | Joining an existing workspace via invite code (typed in) | UI | Manual entry path for crew who got a code via SMS / verbal. |
| 1.7 | Multi-workspace handyman: switch between W1 and W2 | UI | Top-of-app workspace switcher. Confirm customer list, calendar, messages all swap to the new workspace's data. |
| 1.8 | Decline a workspace invite | UI | Invite link → see workspace name → tap Decline → workspace not joined. |
| 1.9 | Leave a workspace (crew member resigns) | UI | Settings → Leave workspace → confirmation → on next app launch the user is back to "no workspace" state. |
| 1.10 | Owner removes a crew member | UI / Web | Operations desk action from the Crew screen — confirm the crew member's app loses access on next launch. |
| 1.11 | Forgotten password / reset flow | UI | Standard supabase-auth password reset, but verify the reset link routes back to the field app (not the homeowner app). |

---

## 2. CRM capabilities

### 2a. Adding accounts (= linking customer households)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.1 | Add a customer who's already in Chez (search by address) | UI | Type an address → Chez finds the household → handyman sends link request → homeowner gets a notification → accepts. Both sides see the relationship. |
| 2.2 | Add a customer who's already in Chez (search by homeowner name + phone) | UI | Alternate path. Phone lookup is privacy-sensitive — verify it requires the homeowner to confirm. |
| 2.3 | Add a brand-new homeowner who isn't in Chez yet | UI | Handyman fills out the homeowner's basic info (name + email + phone + address) → Chez emails the homeowner an invite → homeowner creates account + property gets auto-linked to W1. **Critical "growth" path** — every customer the handyman adds is potential Chez revenue. |
| 2.4 | Add a customer via referral code | UI | Handyman gives the homeowner a 6-char code; homeowner types it during their own onboarding. Both sides converge. |
| 2.5 | Add a customer via QR code | UI | Handyman shows a QR code on screen → homeowner scans during onboarding. (Camera-only path; manual QA.) |
| 2.6 | Bulk import customers from contacts | UI (skip — privacy) | Defer; potential gap. |
| 2.7 | Bulk import customers from a CSV | Web | Operations desk only — handyman uploads a CSV of (name, address, phone). Each row creates a pending link request. |
| 2.8 | Customer accepts the link request from the homeowner side | UI | Homeowner sees a notification "E2E Handyman Co wants to add you as a customer" → tap Accept → relationship established. Both sides update. |
| 2.9 | Customer declines the link request | UI | Tap Decline → relationship rejected. Handyman sees "Declined" status; cannot re-invite for 24h (rate limit). |
| 2.10 | Customer revokes after accepting | UI | Months later, homeowner removes E2E Handyman Co from their household — handyman's app removes the customer from the list. |
| 2.11 | Pre-existing handyman (legacy contractor row) auto-claim | UI | If the homeowner already has a contractor row with the handyman's phone or website, prompt to "claim this contact as your Chez account." Reduces duplicate data. |

### 2b. Building quotes

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.12 | Single-line quote ("Replace water heater — $4,500") | UI | Most basic quote. Send → customer receives in their inbox. |
| 2.13 | Multi-line quote with separate labor + materials + tax | UI | Verify line items + automatic subtotals + total. |
| 2.14 | Quote with materials markup % applied | UI | Workspace-level setting (e.g. 30% on parts). Verify the markup line is visible to the homeowner OR rolled into materials cost (your call — flag as design decision). |
| 2.15 | Quote with discount line | UI | Negative line item or % discount. |
| 2.16 | Quote with photos attached (the equipment + the issue) | UI | Camera roll + new captures. Photos appear in the customer's view of the quote. |
| 2.17 | Quote with scope notes / methodology | UI | Free-text section explaining HOW the work will be done. Important for HNW customers. |
| 2.18 | Quote draft saved for later | UI | Half-built quote → tap Save → reopen later → all line items + photos preserved. |
| 2.19 | Quote send → customer receives notification | UI | Push + inbox item on the homeowner side. |
| 2.20 | Quote send → email fallback if homeowner hasn't opened the app in 7d | E2E | Edge Function `send-quote-email` should fire as a backstop. |
| 2.21 | Quote-with-options (good / better / best) | UI | Single quote with 3 alternative tiers. Customer picks one. |
| 2.22 | Multi-trade quote (one project, both plumbing + electrical) | UI | Single quote bundles multiple trades. Each trade has its own line items. |
| 2.23 | Quote template saving | UI | After sending a quote, save as template "Bathroom remodel — standard." Reuse on the next customer. |
| 2.24 | Quote template library | UI | Pre-loaded templates per trade ("Annual HVAC tune-up", "Water heater replacement", "Whole-home repipe"). Edit + save as workspace template. |
| 2.25 | Quote duplication | UI | "Duplicate this quote" for a similar customer next door. |
| 2.26 | Quote PDF export | UI | One-tap PDF for in-person presentation or email send. |
| 2.27 | Quote signing (customer signs in-app at end of visit) | UI | In-person path: handyman builds a quote at the kitchen table, customer signs on the handyman's iPad. Captured signature image saved on the quote row. |
| 2.28 | Quote conversion to invoice | UI | "Mark complete" on a quote → generate invoice with the same line items + adjustments for actual materials used. |

### 2c. Scheduling visits

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.29 | Schedule a one-off visit (date + time + duration + customer) | UI | Calendar picker → save → customer notified. |
| 2.30 | Schedule a recurring visit (every Tuesday at 2pm for 8 weeks) | UI | Recurrence rules. Each occurrence is a separate row but linked to the parent series. |
| 2.31 | Reschedule a visit (tap & drag or tap to edit) | UI | Customer notified of the change. |
| 2.32 | Cancel a visit | UI | Confirmation dialog. Customer notified. Reason captured. |
| 2.33 | Mark a visit as "no-show" (customer wasn't home) | UI | Different state than cancelled. Tracked for billing / pattern detection. |
| 2.34 | Schedule with conflict detection | UI | Try to book overlapping with an existing visit → warning. |
| 2.35 | Schedule across crew (assign to a specific tech) | UI | Multi-tech workspace; visit shows up only on the assigned tech's calendar. |
| 2.36 | Visit week view (Mon-Fri grid) | UI | All visits across crew, color-coded per tech. |
| 2.37 | Visit month view | UI | Calendar with dot density per day. |
| 2.38 | Visit list view (chronological) | UI | Today / This Week / Next Week / All Upcoming. |
| 2.39 | Visit search by address / customer / job description | UI | Quick lookup. |
| 2.40 | Drag-to-reschedule on the calendar | UI | Pure-UI affordance. Confirm drop fires the same reschedule path as tap-to-edit. |
| 2.41 | Customer-initiated reschedule (homeowner asks via app) | UI | Homeowner picks new time → handyman notified → confirms or counters. Round-trip. |
| 2.42 | Calendar sync to Google / Apple Calendar (read-only feed) | UI | iCal / ICS feed URL per workspace. Test consumption. |
| 2.43 | Calendar sync write-back (block off times from external calendar) | UI / E2E | Bidirectional sync — visits added in Google should NOT block app calendar (one-way) OR should (two-way). Flag the design choice. |

### 2d. Selling more — upsell + cross-sell

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.44 | After a completed visit, suggest related work ("you should also seal the deck") | UI | Visit detail → "Suggest follow-up" → templated suggestions OR free-form. |
| 2.45 | Suggest a recurring routine the customer doesn't have ("biweekly cleaning") | UI | Handyman picks a routine from a library → sends to customer with proposed cadence + price. |
| 2.46 | Suggest a system upgrade ("your water heater is 18 years old, here's a quote") | UI | Tied to a system on the customer's home. Auto-includes the system facts in the quote. |
| 2.47 | Handyman view of the customer's vendor coverage gaps | UI | "These 4 categories don't have a vendor — want to fill them?" Handyman can offer themselves OR refer a partner. |
| 2.48 | Track conversion: suggested → accepted | UI | Per-suggestion status. Workspace-level analytics: "$X in suggestions sent, $Y accepted, Z% conversion." |
| 2.49 | Bundled offer ("3 visits for the price of 2") | UI | Multi-visit discount package. |
| 2.50 | Year-end maintenance plan offer | UI | Annual subscription pitched in late Q4 for next year's recurring care. |
| 2.51 | Cross-sell to neighboring customers ("I'm doing a roof at your neighbor's; want to bundle?") | UI | Privacy-sensitive — verify the suggestion doesn't leak the neighbor's identity. |
| 2.52 | Referral incentive: "refer a friend, both get $50 off" | UI | Customer-facing referral codes that route back to the handyman's workspace. |

---

## 3. Coordination + messaging (live with homeowners)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 3.1 | Open a chat thread with a customer | UI | Per-customer thread accessible from the customer detail view. |
| 3.2 | Send text message | UI | Simple text → push to homeowner. |
| 3.3 | Send photo (camera roll) | UI | Photo attaches as inline thumbnail. |
| 3.4 | Send photo (live capture) | UI | Camera path; verify permissions prompt + capture flow. |
| 3.5 | Send voice note | UI | Hold-to-record. Playback inline. |
| 3.6 | Send a quote inline in chat | UI | Tap "+" → "Send quote" → quote builder → quote arrives as a chat card. Customer can Accept / Counter / View Details from the card. |
| 3.7 | Send a visit suggestion inline | UI | Same pattern — visit slot card with Accept / Suggest different time. |
| 3.8 | Read receipts | UI | Verify the "seen at" timestamp updates on both sides. |
| 3.9 | Typing indicator | UI | Shows "typing…" on the other side. |
| 3.10 | Push notification for new inbound message | UI | Handyman gets a push → tap → opens the right thread. |
| 3.11 | Per-thread mute (during a visit, mute notifications) | UI | Mute toggle on the thread. |
| 3.12 | Quick replies / templated responses ("On my way", "Running 15 min late") | UI | Workspace-curated library + per-handyman favorites. |
| 3.13 | Group chat: handyman + Chez + homeowner | UI | Three-way thread when Chez is mediating (per the concierge layer). Verify each side sees the full thread; Chez messages render as "Chez" not "Tom" (per CLAUDE.md brand rule). |
| 3.14 | Chez relays a message: handyman never sees Chez op's name | UI | Per CLAUDE.md "Every user-facing string says 'Chez' — never 'Tom' or any operator's name." Handyman sees "Chez asked: …", not "Tom Burke asked: …". |
| 3.15 | Message search across all threads | UI | Find that one message about a part number from 6 months ago. |
| 3.16 | Message archive (mark resolved) | UI | Different from delete — archived threads still searchable but out of the unread list. |
| 3.17 | Customer blocks handyman (escalation) | UI | Customer-side action that severs the chat + relationship. Handyman sees "this customer has ended the relationship." |

---

## 4. Negotiation through the app

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 4.1 | Customer counters a quote with a different price | UI | Customer types "$3,000 instead of $4,500" → handyman receives notification. |
| 4.2 | Counter-offer round trip (handyman → customer → handyman) | UI | Multiple rounds preserved as a quote history. |
| 4.3 | Handyman accepts the customer's counter | UI | One-tap accept → quote updates → goes to "Accepted" state. |
| 4.4 | Handyman declines the customer's counter | UI | "Sorry, can't do that price" → customer notified. Original quote stays as "Declined." |
| 4.5 | Handyman counters back with a different price | UI | "I can do $3,800." Customer sees the new price. |
| 4.6 | Handyman counters with revised scope ("$3,000 if we skip step 3") | UI | Counter modifies the line items, not just the total. |
| 4.7 | Quote-with-options counter ("good tier instead of best") | UI | Customer picks a different option from the original quote. |
| 4.8 | Auto-expiration after N days without acceptance | E2E | `provider_quotes.expires_at` — verify the cron / Edge Function flips status to "expired" on schedule. |
| 4.9 | Negotiation history view | UI | Per-quote timeline: "Sent at 2pm, customer countered at 3pm, you countered at 4pm, accepted at 5pm." |
| 4.10 | Walk-away point: handyman declines after 3 counters | UI | Optional escalation rule — after N counters, the system suggests "ready to move on?" |
| 4.11 | Chez mediates the negotiation | UI | If the customer has handed scheduling off to Chez (`chez_owned`), Chez negotiates on the customer's behalf. Handyman sees "Chez asked for $200 off" — Chez acts as a buffer. |

---

## 5. On-behalf-of onboarding (homeowner skips quiz, handyman does it)

This is the **biggest section** and the one most likely to surface
gaps. The homeowner picked "Send a Chez handyman to set up" on the
mode fork → assessment request created → handyman receives it →
performs an in-person walk-through → submits a complete property
record → Chez central manages everything from there.

### 5a. Assessment intake (handyman side)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.1 | New assessment request push notification | UI | Handyman gets a push when a customer is assigned. Tap → assessment detail screen. |
| 5.2 | Assessment list (assigned to me / unassigned / completed) | UI | Per-handyman queue. Crew leader can reassign to a different tech. |
| 5.3 | Assessment detail pre-visit | UI | Shows: address, ATTOM facts (year built, sqft, bed/bath, lot), foundational answers the homeowner DID provide (priorities, household composition, will-be-home toggle), customer name + phone, special access notes. |
| 5.4 | Tap-to-call the customer | UI | One-tap phone call from assessment screen. |
| 5.5 | Tap-to-navigate (open Maps with address) | UI | Native Maps deep link. |
| 5.6 | "Start visit" check-in (geolocation + timestamp) | UI | Captures the actual on-site arrival. Optional GPS check (within X miles of the address). |
| 5.7 | Pre-visit prep checklist | UI | Templated reminders ("Bring extension cord", "Confirm pet status", "Verify HVAC access"). |

### 5b. System capture (the heart of the assessment)

For each system the handyman finds in the home, they need to capture it to a `home_systems` row that Chez central can manage.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.8 | Capture HVAC system: photo of model plate → AI extracts make/model/serial | UI | Tap "Add system" → category HVAC → camera → AI fills brand, model, serial → confirmation screen → save. Single most important UX. |
| 5.9 | Capture water heater: same flow | UI | Different category, same UX. |
| 5.10 | Capture generator: same flow + fuel type | UI | Generator has fuel-type sub-attribute (gas/propane/diesel). |
| 5.11 | Capture pool/spa equipment | UI | Pool pump + filter + heater = 3 separate systems OR one parent + 3 children depending on schema. Verify parent_system_id wiring. |
| 5.12 | Capture irrigation system | UI | Sprinkler controller + zones + valves. |
| 5.13 | Capture solar panels | UI | Inverter + panel array. Subtype = owned/leased. |
| 5.14 | Capture appliances (fridge / dishwasher / washer / dryer / range) | UI | Multi-add: sweep through the kitchen + laundry, capture each in <30 seconds. |
| 5.15 | Manual entry fallback (no model plate visible / unreadable) | UI | Type brand + model manually. |
| 5.16 | Photo without AI extraction (just capture, leave fields blank) | UI | Sometimes the handyman is in a hurry; capture now, fill later. |
| 5.17 | Multiple photos per system (front, label, serial, install date) | UI | Photo gallery on the system row. |
| 5.18 | Notes per system ("water heater leaking from base", "ductwork has asbestos") | UI | Free-text observations. |
| 5.19 | Replace existing detected system | UI | Homeowner's `home_systems` already has "HVAC" with subtype "central_ac" but no model — handyman taps existing row, fills in details, save. Verify the existing row is updated, not duplicated. |
| 5.20 | Decommission a system | UI | Customer just removed the old water heater. Handyman marks it "decommissioned at 2026-05-06". Phase 84/95 already has `decommission_system` action — verify wire format. |
| 5.21 | Add a NEW system Chez doesn't know about | UI | Wine cellar, EV charger, central vacuum — full add flow. |
| 5.22 | Voice notes on a system ("this furnace is from the 80s, plan replacement in 2 years") | UI | Audio attached to the system row. |
| 5.23 | "Mark for follow-up" (inspect later, can't access now) | UI | Flag the system for a future visit. |
| 5.24 | Bulk-add multiple systems in one session (10+ systems in 30 min) | UI | Performance test — does the app stay responsive? Are uploads queued? |

### 5c. Vendor capture (existing relationships the homeowner already has)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.25 | Capture an existing vendor: name + phone + category | UI | Tap "Add vendor" → trade picker → name → phone. Optional website + email. |
| 5.26 | Photo of a vendor's business card → AI extracts name + phone + website | UI | Snap → confirmation → save. |
| 5.27 | Photo of a vendor sticker on equipment ("Joe's HVAC, 555-1212") | UI | Same as 5.26 but the source is a sticker on the furnace. |
| 5.28 | Confirm vendor with homeowner during the visit | UI | "Is Joe's HVAC who installed this?" → toggle confirms. |
| 5.29 | Multiple vendors in the same category | UI | Some homes use 2 plumbers (e.g. one for emergencies, one for routine). Verify the schema supports multiple per category. |
| 5.30 | Vendor with rating / notes ("only call him for emergencies, slow on routine work") | UI | Homeowner-provided context captured by the handyman. |

### 5d. Routine capture (recurring services)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.31 | Capture lawn care routine: vendor + cadence (every Wed) + cost ($200/visit) + active months (Apr-Nov) | UI | Multi-step form. Verify the routine ends up as a `routines` row, not as a `home_systems` row. |
| 5.32 | Capture cleaning routine: biweekly + cost + access notes | UI | |
| 5.33 | Capture pool service routine: weekly May-Sep + chemical care notes | UI | |
| 5.34 | Capture snow removal routine: seasonal Dec-Apr + per-storm cost | UI | |
| 5.35 | Capture pest control routine: quarterly + termite bond notes | UI | |
| 5.36 | Capture trash + recycling pickup days (NOT a paid vendor, just a cadence) | UI | Day-of-week + bin-out reminder. |
| 5.37 | Multiple cadence per routine (e.g. lawn = mow weekly + fertilize quarterly) | UI | Single vendor, multiple sub-cadences. |
| 5.38 | Routine with hand-off to Chez ("tell Chez to schedule this") | UI | `chez_owned = true` — Chez central handles all scheduling going forward. |

### 5e. Observations + concerns (the value-add the handyman brings)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.39 | Capture an observation ("roof needs replacement in 2 years") | UI | Free-text + optional photo. Tied to a system OR free-floating. |
| 5.40 | Capture a safety concern ("no CO detector in basement") | UI | Higher-priority observation. Generates a follow-up task immediately. |
| 5.41 | Capture a code violation ("electrical panel is overloaded") | UI | Surfaced to the homeowner with a recommended remediation quote. |
| 5.42 | Capture a recommendation ("install whole-house surge protector") | UI | Lower-priority than safety/code. Becomes an upsell opportunity. |
| 5.43 | Photo + voice note + tags on observations | UI | Same multi-media affordances as systems. |

### 5f. Assessment submit + handoff to Chez central

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.44 | Submit assessment → homeowner gets "your home is set up" notification | UI | All systems / vendors / routines / observations land on the homeowner's dashboard. |
| 5.45 | Homeowner opens app → sees populated dashboard | UI | Cross-app verification: homeowner sim sign-in, confirm everything is there. |
| 5.46 | Chez central can manage all of it (admin portal, ChezOwnsToggle on routines) | Web | Operations desk — confirm the new household appears in the queue, all routines are markable as Chez-owned. |
| 5.47 | Handyman receives "homeowner has reviewed your assessment" notification | UI | Acknowledgement loop. |
| 5.48 | Homeowner edits something the handyman captured (e.g. corrects a model number) | UI | Both sides see the edit. Handyman can see history of edits. |
| 5.49 | Homeowner deletes something the handyman added (e.g. removes a system that doesn't actually exist) | UI | Soft-delete with reason. Handyman notified so they can correct their notes. |
| 5.50 | Assessment incomplete — saved as draft for next visit | UI | "I got 70% of the home; coming back Friday for the basement." Reopen draft → continue. |
| 5.51 | Multi-day assessment (3 visits to fully capture a 10,000sqft estate) | UI | Series of linked visits, single assessment. |

### 5g. Edge cases

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.52 | Customer not home for the visit | UI | Per `home_assessments` — homeowner_present flag. Handyman captures what they can, flags rest for follow-up. |
| 5.53 | Camera permission denied mid-flow | UI | Graceful fallback to manual entry; no crash. |
| 5.54 | No internet during the visit (rural property) | UI | Offline capture queued; sync when back online. **Critical for HNW estates often in low-coverage areas.** |
| 5.55 | App killed mid-assessment | UI | Resume on relaunch with all captured data preserved. |
| 5.56 | Photo upload fails (bad connection) | UI | Retry queue with visible status. |

---

## 6. Review homes they work on (multi-household + per-household)

### 6a. Multi-household aggregate views

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 6.1 | Customer list — all linked homes | UI | Address + name + last visit + next visit + outstanding $. Sortable. |
| 6.2 | Filter by trade ("all my HVAC customers") | UI | When the workspace covers multiple trades. |
| 6.3 | Filter by status ("overdue for service", "new in last 30 days", "high-value") | UI | |
| 6.4 | Search by address / name / phone | UI | Single search bar. |
| 6.5 | Sort by next visit / last visit / outstanding $ / lifetime value | UI | |
| 6.6 | "Today" view — every visit + open thread + open quote across all customers | UI | The handyman's daily dashboard. |
| 6.7 | "This week" view — same shape | UI | |
| 6.8 | "Outstanding" view — unpaid invoices + expired quotes + open punch items + un-acknowledged messages | UI | The "things needing attention" list. |
| 6.9 | Map view of all customer addresses | UI | Visual coverage map. Pins colored by status (active / overdue / new). |
| 6.10 | Route optimization: "I'm doing 4 visits today; what's the best order?" | UI | Driving distance + time-of-day windows. |

### 6b. Per-household detail view

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 6.11 | Customer detail header (name, address, contact, photo of home) | UI | Quick-glance card. |
| 6.12 | All systems the home has | UI | Complete inventory with brand/model/serial/last service. |
| 6.13 | All routines + cadence | UI | |
| 6.14 | All vendors the homeowner uses (whether or not the handyman set them up) | UI | Awareness of the ecosystem. |
| 6.15 | All open tasks | UI | Tasks Chez surfaces to the homeowner — handyman should see them so they don't suggest a duplicate. |
| 6.16 | All scheduled visits (this handyman's only) | UI | Future + past. |
| 6.17 | Service history (every past visit by this handyman + summary + invoice) | UI | Searchable per-customer log. |
| 6.18 | Outstanding payments | UI | Sum + per-invoice list. |
| 6.19 | Notes / tags per household ("difficult driveway, park on street", "pet-friendly only", "owner is hard of hearing") | UI | Workspace-level annotations. |
| 6.20 | Year-over-year revenue per customer | UI | Lifetime value tracking. |
| 6.21 | Customer's vendor coverage map (who else they use) | UI | Cross-vendor awareness — useful for cross-sell ("I see you don't have a chimney sweep — want me to recommend one?"). |
| 6.22 | Linked household's `chez_profile` (standing instructions) — read-only | UI | Per CLAUDE.md the homeowner gives Chez standing instructions like spending tiers. The handyman should see relevant subset (e.g. "this customer doesn't approve work over $500 without prior call"). |

### 6c. Systems the handyman could set up (the gap-filling view)

This is what Tom called out specifically: "the handyman should be able
to see from their app all the systems that home has setup currently,
but also all the systems that the handyman could setup for them
immediately ie. This home has a furnace as a sytem, but no model/brand/etc.
the handyman should be able to input that or snap a picture to identify
the model".

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 6.23 | "Incomplete systems" view — every system on this home that's missing brand/model/serial/install date | UI | Sorted by category. Tap → photo capture or manual entry → save → row updates. |
| 6.24 | "Suggested systems" view — common systems for this property type the home doesn't have | UI | E.g. "1939 colonial, no chimney system on file — does the home have a fireplace?" Handyman confirms → adds. |
| 6.25 | "Suggested vendors" view — categories the home has no vendor for | UI | Mirror of the homeowner's VendorCoverageSheet, but from the handyman side: handyman can offer themselves OR refer a partner. |
| 6.26 | "Stale data" view — systems whose last_service_date is > N years ago | UI | Recurring service opportunity. |
| 6.27 | "Missing routines" view — common routines the home doesn't have ("no snow plow but you're in CT") | UI | Climate / region-aware. |
| 6.28 | One-tap "Capture all" sweep mode — walk through the home, photo each thing | UI | Camera-first UX optimized for fast capture during an initial visit. |

---

## 7. Suggest tasks to homeowners (proactive)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 7.1 | Suggest a task from a system row ("replace HVAC filter every 90 days") | UI | Tap system → "Suggest task" → templated wording → send. Customer sees it as a suggested task in their app. |
| 7.2 | Suggest a task from an observation ("clean dryer vent — fire hazard") | UI | Higher priority. |
| 7.3 | Suggest a task with photo evidence ("here's the corrosion") | UI | Photo travels with the suggestion. |
| 7.4 | Suggest a vendor for the task (themselves OR a partner) | UI | Optional — sometimes the handyman wants to refer instead of doing it themselves. |
| 7.5 | Bulk suggest 5 tasks at once after a visit | UI | At end of visit, wizard surfaces "here's what we noticed; suggest these to the customer?" — checkbox each, send batch. |
| 7.6 | Customer accepts a suggestion → task lands on their maintenance list | UI | Cross-app verification. |
| 7.7 | Customer declines a suggestion → handyman notified | UI | "Not interested" state on the suggestion. |
| 7.8 | Customer pushes back ("can we wait 6 months?") | UI | Suggestion → counter-proposal → round trip. |
| 7.9 | Track conversion: tasks suggested vs accepted | UI | Workspace-level analytics. |
| 7.10 | Suggestion expiration (no response after 30d) | E2E | Auto-archive. |
| 7.11 | "Suggest a task to ALL customers in your portfolio" — bulk announcement | UI | "Filter change reminder for all 47 of you HVAC customers" — broadcast with per-customer personalization. |
| 7.12 | Chez can intercept and queue a suggestion for the homeowner instead of pushing immediately | Web | Operations desk path — Chez triages handyman suggestions before they hit the homeowner, to avoid spam. |

---

## 8. Suggest visits to homeowners (proactive scheduling)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 8.1 | Propose a visit ("come back next month for X") with 3 candidate slots | UI | Slot picker pre-filled from handyman's calendar. Customer picks one → confirmed. |
| 8.2 | Propose a recurring visit ("every quarter for the next year") | UI | Recurring slot pattern. |
| 8.3 | Propose a visit tied to a specific system ("annual furnace tune-up") | UI | Visit pre-fills with the system's standard punch list (filter change, blower clean, gas pressure check). |
| 8.4 | Propose a visit tied to a routine ("you said quarterly pest; want to schedule the next one?") | UI | |
| 8.5 | Customer accepts → visit on calendar | UI | |
| 8.6 | Customer requests different time → handyman counters | UI | Same negotiation pattern as quotes. |
| 8.7 | Customer accepts but with conditions ("I'll be home but kids will be napping, please be quiet") | UI | Special instructions captured on the visit. |
| 8.8 | Pre-filled punch list for the proposed visit | UI | Handyman sees the suggested checklist while building the proposal. Customer sees it at acceptance. |
| 8.9 | Visit-suggestion templates | UI | "Annual HVAC service" template = duration 90min + 6-item punch list + $250 base price. |
| 8.10 | Climate-driven suggestion ("first hard frost coming, schedule winterization?") | UI / E2E | Weather API drives proactive suggestions. |
| 8.11 | Calendar-driven suggestion ("you haven't visited this customer in 12mo, schedule a check-in?") | UI | Workspace-level reminder. |

---

## 9. Live visit tracking (the moment the handyman is on-site)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 9.1 | Start visit (clock in + GPS check-in) | UI | Captures actual on-site arrival time. Optional GPS verification within X miles. |
| 9.2 | Open punch list during the visit | UI | Tap-to-check items live. Each check captures a timestamp + tech who did it. |
| 9.3 | Add a new punch item mid-visit ("found a leaky valve, add to today's work") | UI | Real-time. |
| 9.4 | Photo evidence on each completed item | UI | "Before / after" pair attached. |
| 9.5 | Voice note on each item ("filter was completely caked, recommend more frequent changes") | UI | |
| 9.6 | Materials used on each item (with cost) | UI | Inventory drawdown + cost capture for invoicing. |
| 9.7 | Time tracking per item OR per visit | UI | Workspace setting. |
| 9.8 | "Need part" → marketplace integration / supplier app handoff | UI | Optional integration. |
| 9.9 | Pause visit (customer answered the door for a different reason; resume later) | UI | Time tracking pauses. |
| 9.10 | End visit (clock out) | UI | Captures finish time + total duration. |
| 9.11 | Auto-generate visit summary | UI | Templated summary from the punch list + materials + time. |
| 9.12 | Summary review screen — handyman edits before sending | UI | "Tweak the wording before customer sees it." |
| 9.13 | Send summary to homeowner | UI | Push + inbox item + email. |
| 9.14 | Customer reviews / approves / requests revisions | UI | Round-trip until customer confirms. |
| 9.15 | Customer-initiated punch item additions DURING the visit | UI | "Hey while you're here, can you also look at X?" — homeowner adds an item via THEIR app, handyman sees it appear live in their punch list. |
| 9.16 | Homeowner-not-home visit (handyman has key / lockbox access) | UI | No customer interaction; full punch list still tracked. Photos required for accountability. |
| 9.17 | Co-tech visit (2 crew members on same visit) | UI | Both can check off items; both timestamps captured. |
| 9.18 | Visit cancellation due to weather / emergency mid-stream | UI | Save partial state, reschedule. |

---

## 10. System identification (the photo → AI workflow)

This is one of the most important UX moments for the handyman.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 10.1 | Tap a system → see "Add details" if data is incomplete | UI | Verify the affordance is obvious. |
| 10.2 | Camera opens → snap photo of model plate | UI | Camera permission flow. |
| 10.3 | AI extracts brand + model + serial in <5 seconds | E2E | `identify-equipment` Edge Function — verify the round-trip latency + accuracy. |
| 10.4 | Confirmation screen: "Is this right?" with editable fields | UI | Always allow override. |
| 10.5 | Save → system row updated, not duplicated | UI | Verify the existing system gets enriched, no new row created. |
| 10.6 | Multiple photos for one system (front, label, serial number) | UI | All attached, primary image flagged. |
| 10.7 | Photo of an unreadable / damaged label → AI says "couldn't extract" → manual entry path | UI | Graceful fallback. |
| 10.8 | Photo of a non-equipment object → AI says "not a system" | UI | Defensive — handyman accidentally photographed a plant; don't crash. |
| 10.9 | Pull up manual / spec sheet from the model number | UI | Tap "Manual" → opens PDF from the equipment-manuals bucket. |
| 10.10 | Manual entry path with brand auto-complete | UI | Type "Lennox" → list of common Lennox models. |
| 10.11 | Decommission a system (replace with new one) | UI | "Old water heater removed, here's the new one" — old row marked decommissioned, new row created, photos migrated where relevant. |
| 10.12 | System-level tags ("warranty active", "customer extended warranty", "recall pending") | UI | Inventory-style metadata. |
| 10.13 | Recall check on saved systems | E2E | When a recall lands on a brand+model, every linked system gets flagged. Handyman sees recall alert across all customers. |

---

## 11. Crew / workspace management

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.1 | Owner adds a crew member (email invite) | UI | Email link → crew member signs up → joins workspace. |
| 11.2 | Owner sets crew member role (admin / dispatcher / tech / view-only) | UI | Per-role permissions. |
| 11.3 | Owner removes a crew member | UI | Confirmation; crew member loses access on next launch. |
| 11.4 | Crew member view = only their assigned visits + customers | UI | Permission scoping. |
| 11.5 | Owner / dispatcher view = all crew, all visits | UI | |
| 11.6 | Reassign a visit from tech A to tech B | UI | Both notified; calendar updates on both. |
| 11.7 | Crew chat (intra-workspace messaging) | UI | Tech-to-tech notes. |
| 11.8 | Time-off request | UI | Tech requests a vacation block; dispatcher approves. |
| 11.9 | Crew location view (live-on-the-clock map) | UI | Optional GPS feed for dispatchers. |
| 11.10 | Per-tech revenue / utilization analytics | UI | |

---

## 12. Profile + workspace settings

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 12.1 | Edit handyman profile (name + photo + bio + certifications) | UI | |
| 12.2 | Add certifications (HVAC license, plumbing license) with expiry dates | UI | |
| 12.3 | Service area edits (ZIP codes / radius from base) | UI | |
| 12.4 | Specialties / trades edits | UI | |
| 12.5 | Hourly rate + service-call rate + emergency rate | UI | |
| 12.6 | Default availability schedule (Mon-Fri 8a-6p, Sat 9a-2p) | UI | |
| 12.7 | Vacation mode | UI | Block off a date range; auto-decline new visit requests during. |
| 12.8 | Workspace branding (logo + brand color + business name + tagline) | UI | |
| 12.9 | Workspace tax / business info | UI | EIN, sales tax rate, etc. — used on invoices. |
| 12.10 | Notifications preferences (which events push, which email) | UI | |
| 12.11 | Sign out | UI | Confirm session ends, keychain cleared. Re-launching app routes to sign-in. |
| 12.12 | Delete account / leave Chez | UI | Hard delete or soft archive — flag the design choice. |

---

## 13. Push notifications (handyman-side)

For each: the notification arrives, tapping deep-links into the right
screen, the badge count updates correctly.

| # | Event | Owner | Notes |
|---|---|---|---|
| 13.1 | New customer linked / accepted | UI | Deep link to customer detail. |
| 13.2 | Customer declined link request | UI | Deep link to customer list. |
| 13.3 | Quote accepted | UI | Deep link to quote. |
| 13.4 | Quote countered | UI | Deep link to negotiation thread. |
| 13.5 | Quote declined | UI | Deep link to quote (now "Declined" state). |
| 13.6 | Visit scheduled (customer accepted a suggestion) | UI | Deep link to visit detail. |
| 13.7 | Visit rescheduled by customer | UI | Deep link to visit detail. |
| 13.8 | Visit cancelled by customer | UI | Deep link to visit detail. |
| 13.9 | New message from customer | UI | Deep link to thread. |
| 13.10 | Visit starting in 30 min reminder | UI | Per-handyman setting — defaults to 30 min, configurable. |
| 13.11 | Punch item added by customer (during a live visit) | UI | Deep link to the open punch list. |
| 13.12 | Payment received | UI | Deep link to invoice. |
| 13.13 | Customer left a review | UI | Deep link to reviews. |
| 13.14 | Chez asked for clarification on an assessment | UI | Deep link to the assessment + Chez thread. |
| 13.15 | Recall alert on a system this handyman serviced | UI | Deep link to system list filtered by the recalled brand/model. |

---

## 14. Cross-cutting edge cases

| # | Case | Owner | Notes |
|---|---|---|---|
| 14.1 | Offline mode (rural property, no signal during visit) | UI | All capture actions queue locally; sync when back online. |
| 14.2 | App crash mid-visit | UI | State preserved; relaunch resumes. |
| 14.3 | App backgrounded mid-visit (phone call interrupted) | UI | Resume cleanly. |
| 14.4 | Photo upload failure (large file, poor signal) | UI | Visible retry queue; never silently drop a photo. |
| 14.5 | Location permission denied | UI | GPS check-in falls back to manual timestamp. |
| 14.6 | Camera permission denied | UI | Photo workflows fall back to camera-roll picker only. |
| 14.7 | Notification permission denied | UI | App still works; in-app inbox is the only signal. |
| 14.8 | iPad layout (handyman uses an iPad on customer site) | UI | Should adapt. |
| 14.9 | Dark mode | UI | Full coverage. |
| 14.10 | VoiceOver / accessibility | UI | All actionable elements labeled. |
| 14.11 | Multi-device session (handyman has phone + tablet) | UI | State syncs across devices in real time. |
| 14.12 | Slow simulator / slow network behavior | UI | Skeleton loading vs spinners; never a frozen screen. |
| 14.13 | Foreign-character handling in customer names / addresses | UI | UTF-8 throughout. |
| 14.14 | Very long customer names / addresses | UI | Truncation + tooltip on hover. |

---

## 15. Cross-app integration tests (handyman <-> homeowner round-trips)

These need the simulator to drive BOTH the homeowner and the handyman
app — likely two separate sim devices, or sequential subagent runs
that swap which app is in the foreground.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 15.1 | Handyman sends a quote → homeowner sees it in their inbox | UI | Two-app verification. |
| 15.2 | Homeowner counters the quote → handyman sees the counter | UI | |
| 15.3 | Handyman submits an assessment → homeowner sees populated dashboard | UI | The full on-behalf-of flow end-to-end. |
| 15.4 | Homeowner asks Chez to schedule a visit → Chez asks handyman → handyman confirms → both sides see the booking | UI / Web | Three-party flow involving the operations desk. |
| 15.5 | Handyman suggests a task → homeowner accepts → task appears on their list → handyman gets confirmation | UI | |
| 15.6 | Homeowner adds a punch item during a live visit → handyman sees it live | UI | |
| 15.7 | Handyman ends visit → summary sent → homeowner reviews + signs off → handyman gets payment-ready signal | UI | |
| 15.8 | Handyman's quote is declined → Chez intercepts and offers an alternative vendor → handyman gets "you weren't selected" notification | Web | |

---

## 16. Operations desk (Web) — handyman-facing flows

The Concierge Cockpit at `/operations/*` is Tom's desk. Some handyman
test scenarios cross into the web side.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 16.1 | Tom assigns an inbound homeowner request to a handyman | Web | Queue rail → drag to handyman card → push fires to handyman. |
| 16.2 | Tom routes a quote through the handyman | Web | Customer asks for X; Tom relays to handyman; handyman quotes; quote returns through Tom. |
| 16.3 | Tom dispatches a 4-stop route across crew | Web | Routes screen — drop visits onto crew cards. |
| 16.4 | Tom messages a handyman on behalf of a customer | Web | Three-way thread mediation. |
| 16.5 | Tom flags a handyman's assessment as needing revision | Web | Concierge cockpit action; handyman receives the revision request. |
| 16.6 | Tom approves / rejects a handyman's vendor recommendation | Web | Quality gate — Chez vets handyman recommendations before pushing to the homeowner. |
| 16.7 | Tom views handyman's per-customer revenue / utilization | Web | Analytics deep-dive. |

---

## 17. Reset between runs

Each iteration starts clean:

```sh
# Wipe every handyman test artefact (workspace, members, customers, quotes, visits, messages)
supabase db query --linked --file Tests/e2e/cleanup-handyman.sql

# Reinstall both apps
xcrun simctl uninstall <SIM_ID> com.havenhome.app
xcrun simctl install <SIM_ID> ./build/.../Chez.app
xcrun simctl uninstall <SIM_ID> com.havenhome.field   # field bundle id, confirm during fixture setup
xcrun simctl install <SIM_ID> ./build/.../Chez\ Field.app

# Launch — usually homeowner first to set up the relationship state, then field
xcrun simctl launch <SIM_ID> com.havenhome.field
```

Test users follow:
- Workspace owner: `e2e-handyman-w1-owner-${TS}@havenhome.test`
- Crew: `e2e-handyman-w1-crew-${TS}@havenhome.test`
- Customers: `e2e-customer-of-handyman-w1-{1..5}-${TS}@havenhome.test`

The cleanup script wipes by these patterns + cascades.

---

## 18. Execution priority for the first session

The matrix is large (~250 rows). The first overnight run executes the
highest-value subset:

**Round A — UI happy paths (must work end-to-end):**

1. Workspace creation (1.3-1.4) + customer linking (2.1-2.3) — without this, nothing else can run.
2. Schedule a one-off visit (2.29) and complete it (9.1, 9.10) — proves the basic field workflow.
3. Build + send a quote (2.12, 2.19) and verify customer receives it (15.1).
4. On-behalf-of assessment end-to-end (5.1-5.51) — the biggest single value-prop.
5. Photo → AI system identification (10.1-10.6) — the hero UX moment.

**Round B — Backend (combinatorially expand via `run-handyman.mjs`):**

1. Workspace + member CRUD permutations.
2. Quote lifecycle states (draft / sent / accepted / countered / declined / expired).
3. Visit lifecycle states (scheduled / in-progress / completed / no-show / cancelled).
4. Multi-customer aggregate queries (6.1, 6.6, 6.8) for performance verification at 10+ customers.

**Round C — Cross-app round-trips (slow but high-confidence):**

1. Handyman quote → homeowner inbox → counter → handyman re-quote → accept (15.1, 15.2).
2. Handyman assessment submit → homeowner dashboard populated (15.3).
3. Live visit with customer-added punch item mid-stream (15.6).

**Round D — Edge cases + design audit:**

1. Offline / failure-recovery paths (14.1-14.4).
2. Field-app design adherence (mirror of Wave 5 on the homeowner side — em dashes, salmon discipline, typography).
3. Multi-device sync (14.11) — likely the most likely place to find sync bugs.

**Round E — Defer to manual QA:**

- Camera-driven flows (system photo capture, business-card capture) — mock with sample images for automated runs, exercise the real camera in manual.
- Apple Sign In paths.
- Map / route optimization — needs a real device with location services.
- Multi-device live sync (needs 2 sims or a sim + a real device).

---

## 19. Finding-discovery protocol (4 categories)

Every subagent run produces findings tagged by category. The four
categories cover what we care about: missing features, broken UI,
broken persistence, and outright crashes. Aggregate all four into
`HANDYMAN_GAPS.md` (gaps + UI + persistence) and into the report's
"bugs found" section (functional). Below: the schema for each.

### `gap_found` — feature is absent and should exist

```json
{
  "category": "gap_found",
  "matrix_row": "5.8 Capture HVAC system: photo of model plate → AI extracts make/model/serial",
  "what_exists": "Tapping 'Add system' opens a manual entry form only — no camera affordance.",
  "what_should_exist": "Camera button visible alongside 'manual entry' option; tapping camera opens photo-capture flow that calls identify-equipment Edge Function.",
  "estimated_effort": "small | medium | large",
  "tied_to_value_prop": "On-behalf-of assessment can't deliver its full speed promise without this — every system requires manual entry which adds 90s/system × 15 systems = 22 min of typing.",
  "suggested_fix": "Add cameraButton overlay on AddSystemView; reuse the existing identify-equipment edge function (already wired for the homeowner-side equipment catalog)."
}
```

### `ui_quality_finding` — feature exists but UI is broken / inconsistent / off-brand

This is the bucket for design rule violations, layout issues, missing
empty states, accessibility failures, and visual inconsistencies. Use
the discipline checks from Section 21 categories B + H.

```json
{
  "category": "ui_quality_finding",
  "matrix_row": "2.36 Visit week view (Mon-Fri grid)",
  "screen": "VisitWeekView",
  "discipline_check": "B1 salmon discipline",
  "what_observed": "The 'Today' column header has a salmon background fill spanning the full column header row, which is a decorative use of salmon (not a primary CTA).",
  "what_expected": "Salmon should be reserved for CTAs only. Today's column should be highlighted via subtle navy background tint or a bottom border, not a salmon fill.",
  "severity": "minor | moderate | major | critical",
  "screenshot_path": "/tmp/ui-test/screenshots/visit-week-salmon-header.png",
  "suggested_fix": "Replace HavenColors.action background with HavenColors.navy800.opacity(0.06) or a 2pt salmon underline."
}
```

Severity guide:
- **`critical`** = unusable, blocks completing the scenario. (Example: text is white-on-white and unreadable.)
- **`major`** = clearly wrong, embarrassing for a HNW audience. (Example: em dashes in customer-facing copy on a quote.)
- **`moderate`** = noticeably off but the feature still works. (Example: salmon decoration on a card border.)
- **`minor`** = polish issue or subtle inconsistency. (Example: 16pt vs 14pt mismatch in spacing on one screen.)

### `persistence_finding` — saves don't survive lifecycle

The most user-trust-breaking class of bug. Use the discipline checks
from Section 21 category A.

```json
{
  "category": "persistence_finding",
  "matrix_row": "2.18 Quote draft saved for later",
  "discipline_check": "A1 save → relaunch",
  "scenario_executed": "Built a 5-line quote, tapped 'Save draft', force-quit the app, relaunched.",
  "what_observed": "Draft did not appear in the drafts list. DB shows no provider_quotes row was created. The 'Save draft' button apparently only updates in-memory state, not persisted state.",
  "what_expected": "Tapping Save draft should create a provider_quotes row with status='draft' that survives app restart.",
  "severity": "critical | major | moderate | minor",
  "screenshot_path": "/tmp/ui-test/screenshots/quote-draft-lost.png",
  "suggested_fix": "Audit QuoteBuilderViewModel.saveDraft() — the action handler may be calling local state mutation only, not the DB write through DatabaseService.createProviderQuote()."
}
```

Persistence findings are almost ALWAYS at least `major` severity
because silent data loss erodes trust faster than any other bug class.

### `verification` — functional pass / fail (the original schema)

Per Section 21 category requirements. Same shape as the homeowner
matrix subagents used.

```json
{
  "category": "verification",
  "matrix_row": "1.3 Workspace creation: business name + logo + service area + trades",
  "passed": true,
  "evidence": "Tapped through the 4-step workspace wizard. business_name='E2E Handyman Co', logo uploaded (PNG, 240KB), service_area='06801, 06811, 06812' (Bethel + Brookfield), trades=['HVAC','Plumbing']. After tap-finish, provider_workspaces row was inserted with all 4 fields. Workspace appeared in the top-of-app switcher within 2s."
}
```

### Required output structure

Subagent's return JSON includes a `findings: []` array where every
entry has a `category` field. The fenced JSON block at the end of the
subagent reply looks like:

```json
{
  "scenario_batch": "wave1-section2-crm",
  "result": "PASS | PARTIAL | FAIL",
  "actions_summary": "1-3 sentence narrative",
  "findings": [
    { "category": "verification", ... },
    { "category": "verification", ... },
    { "category": "gap_found", ... },
    { "category": "ui_quality_finding", ... },
    { "category": "persistence_finding", ... }
  ],
  "discipline_coverage": {
    "A_persistence": ["A1", "A3", "A6"],
    "B_ui_quality": ["B1", "B2", "B3", "B4", "B9"],
    "C_input_edge_cases": ["C1", "C3"],
    "D_async_state": ["D1", "D4"],
    "E_lifecycle": ["E1"],
    "F_concurrent": [],
    "G_performance": [],
    "H_accessibility": []
  },
  "screenshot_paths": ["..."],
  "needs_engineer_attention": true | false
}
```

The `discipline_coverage` field is how the main thread audits whether
each subagent ran the required checks. If it's empty or skips category
A or B entirely, the main thread reruns the subagent with explicit
scope.

### Aggregation

After every wave, the main thread appends new findings to
`HANDYMAN_GAPS.md` grouped:

1. By category (gaps / UI / persistence)
2. Within each, by severity (critical → minor)
3. Within each, by matrix section (1, 2, 3...)

`verification` failures with `severity == critical` become commits
overnight (the autonomous fix loop). Everything else lands in the
gaps doc for product input.

---

## 20. What's NOT in this matrix (deliberately deferred)

- **Payment processing** (Stripe in / out flows) — separate testing surface, financial infrastructure has its own validation regime.
- **Tax filing / 1099 generation** — annual concern, not first-launch.
- **CRM imports from QuickBooks / Jobber / Housecall Pro** — competitor-migration story, separate phase.
- **API / webhook integrations** (Zapier etc.) — third-party surface.
- **In-person card readers** — hardware integration.
- **Subcontractor management** (handyman A subs out to handyman B) — out of scope until the basic flows are solid.
- **Insurance claim workflows** — handyman side of homeowner's insurance claim, separate phase.
- **Marketplace / lead-buying integrations** — out of scope.

These all matter eventually but would dilute the first overnight pass.

---

## 21. Per-scenario test discipline (apply to EVERY scenario above)

The matrix lists ~250 scenarios. For each one a subagent touches, it
must apply the standard discipline below. This is what turns "did the
button work" testing into "does this actually work for end users"
testing.

Each subagent picks AT LEAST ONE check from each of the categories
A-E for every scenario it exercises. Categories F-H are sampled (not
applied to every scenario) because they're more expensive.

Findings get tagged in the result JSON by category — see Section 19
for the updated schema.

### A. Save / persistence checks (mandatory on every create / edit / delete)

For every entity the user creates or edits in a scenario, verify it
actually persists across the lifecycle. A "save" that doesn't survive
a kill-and-relaunch is a **silent data loss bug** and must be flagged.

| Check | What to verify |
|---|---|
| **A1 Save → relaunch** | Create the entity, terminate the app (`xcrun simctl terminate`), relaunch, confirm the entity is present with all fields intact. |
| **A2 Save → background → foreground** | Create the entity, send the app to background (Cmd+Shift+H equivalent in sim), wait 30s, return, confirm the entity is still there and the UI hasn't reset to a stale state. |
| **A3 Save → DB cross-check** | Curl the corresponding table via service-role JWT and confirm the row exists with the expected shape. Catches "UI says saved, DB says no" bugs. |
| **A4 Edit existing → no duplicate** | Open an existing entity, edit a field, save. Confirm the row was UPDATED (not a new row inserted). |
| **A5 Save partial → resume preserves draft** | Fill a multi-step form halfway, kill the app, relaunch, confirm the draft state is preserved (or, if the design intentionally discards drafts, confirm that's communicated to the user before they lose work). |
| **A6 Save offline → sync on reconnect** | Toggle airplane mode, save the entity, toggle back online, confirm the entity syncs to the server within 30s. |
| **A7 Delete → confirmation OR undo** | Soft-delete and hard-delete should both have either a confirmation dialog or a 5-second undo affordance. Silent deletes are bugs. |
| **A8 Concurrent edit handling** | Edit on the field app, simultaneously edit the same entity via PostgREST or the homeowner app, confirm the conflict resolution (last-write-wins / merge / conflict UI). |

### B. UI quality checks (mandatory on every distinct screen visited)

Every visually distinct screen the subagent visits gets the design
adherence pass. CLAUDE.md's hard rules are the gate; subagent's job
is to surface violations.

| Check | What to verify |
|---|---|
| **B1 Salmon discipline** | Salmon (`HavenColors.action`) appears only on primary CTAs, active tab, progress bars at completion, and the FAB. Never on decorative backgrounds, borders on inactive cards, body text, or icon tints on inactive list rows. |
| **B2 Typography mix** | New York serif for 18pt+ display (page titles, hero numbers). SF Pro for 16pt and below. Mixing them backwards is a bug. |
| **B3 Em dashes (`—`) in user-facing copy** | Hard rule. Replace with periods, colons, "to", or "and" depending on context. Comment-level em dashes (`// MARK:`, `///`) are fine. |
| **B4 Brand voice** | Every user-facing string says "Chez", never "Tom" or any operator name. Internal admin labels can say "Chez (you)" but the field app shouldn't have those. |
| **B5 Spacing + radii** | Card radius 16pt, button radius 14pt, button height 50pt, page margin 20pt, 4pt grid for spacing. Eyeball check; flag obvious deviations. |
| **B6 Touch targets** | Every tappable affordance ≥ 44pt min dimension. Use `xcrun simctl io ... screenshot` and visually measure suspicious cases. |
| **B7 Shadows** | Indigo-tinted shadows, never pure black. Disabled in dark mode. |
| **B8 Animation quality** | "Luxury watch" feel — high damping, smooth, ~0.35s response. Bouncy / wobbly animations are bugs. |
| **B9 Empty / loading / error / populated states** | Every list and every async surface should render gracefully in all 4 states. Skeleton loading (NOT spinners) per CLAUDE.md. |
| **B10 Layout under content extremes** | Test 3 content lengths: short (1 word name), medium (typical), long (50-char name + multi-line address). Layout should not break, truncate without ellipsis, or push CTAs off-screen. |

### C. Edge case input checks (mandatory on every form)

| Check | What to verify |
|---|---|
| **C1 Empty / whitespace submit** | Submit form with all fields empty or whitespace-only. Validation should fire visibly; submission should not proceed. |
| **C2 Max length** | Paste a 500-char string into every text field. App should cap at a sensible limit OR scroll the input. No layout breaks; no DB errors on save. |
| **C3 Special characters** | Names with apostrophes (O'Brien), emoji (🔧 in a job title), foreign characters (é, ñ, 中文), HTML-like strings (`<script>`), SQL-like strings (`'; DROP TABLE`). All save and display correctly without injection or crash. |
| **C4 Numeric edge cases** | Negative numbers in price fields, zero values, very large numbers (overflow), decimals where ints expected. Validation fires; saved values match input. |
| **C5 Date edge cases** | Feb 29 on non-leap year, DST transition days, very past dates (1900), very future dates (2100). Date pickers handle all without crash. |
| **C6 Pasting formatted text** | Paste from another app (Notes, Mail) with formatting attached. Form should strip formatting cleanly. |
| **C7 Network failure mid-save** | Toggle airplane mode mid-save. App should show a clear error with actionable recovery (retry / save-as-draft). |
| **C8 Server 500 mid-save** | Force a server error (e.g. via curl-modified payload). App should show graceful error, NOT crash, NOT silently fail. |

### D. Async / network state checks (mandatory on every loading surface)

| Check | What to verify |
|---|---|
| **D1 Loading skeleton** | Per CLAUDE.md, loading uses skeleton cards. NEVER a generic spinner on a blank screen. |
| **D2 Network failure on initial load** | Toggle airplane mode before opening the screen. Should show a recoverable error, not an empty/blank state with no explanation. |
| **D3 Slow network (3G simulator)** | Use `xcrun simctl status_bar override` with cellular bars, or use Network Link Conditioner. Confirm UI doesn't hang; loading state visible throughout. |
| **D4 Pull-to-refresh** | Every list with refreshable data should support pull-to-refresh. Refresh should re-fetch from server, not just animate. |
| **D5 Pagination / infinite scroll** | Any list that could grow large should paginate. Test at 100 items: smooth scroll, no jank, pagination indicator visible. |
| **D6 Optimistic UI** | When the user creates / edits / deletes, the UI should reflect the change immediately, then sync to server. If sync fails, the UI rolls back with a clear error. |

### E. App lifecycle checks (mandatory once per major surface)

| Check | What to verify |
|---|---|
| **E1 Background → foreground state preservation** | Send app to background mid-flow, return after 30s. Should resume on the same screen with form state intact. |
| **E2 Kill → relaunch state preservation OR sensible reset** | Force-quit the app mid-flow. Either resume on the same screen (preferred for long flows like assessments) OR cold-start to dashboard with no data loss. Document which the app does for this surface. |
| **E3 Push notification deep link** | Trigger the relevant push (e.g. quote accepted), tap the notification with app cold, confirm it deep-links to the right screen with the right entity loaded. |
| **E4 Push deep link with app already at destination** | If the app is already on the screen the push points to, tapping the notification should NOT push a duplicate copy of that screen onto the nav stack. |
| **E5 Modal interruption** | While a modal sheet is up, send the app to background, return. Modal should still be present in the same state. |
| **E6 In-call interruption** | While on a screen, simulate an incoming call (press Lock + Volume in sim). After the call, the app should resume cleanly. |

### F. Concurrent / multi-device (sampled — apply to ~25% of scenarios)

| Check | What to verify |
|---|---|
| **F1 Two-device sync** | Open the same customer on two simulator devices (or sim + extra installed instance). Edit on device 1, confirm device 2 reflects the change within 5s. |
| **F2 Two-device conflict** | Both devices edit the same entity simultaneously. Verify which side wins (typically last-write-wins) and that the losing side gets a clear error. |
| **F3 Offline edit + online edit merge** | Device 1 edits offline, device 2 edits same entity online. Device 1 reconnects. Confirm merge behavior is sensible (typically: device 2's edit wins, device 1 sees a "newer version" message). |

### G. Performance / scale (sampled — apply to lists + heavy surfaces only)

| Check | What to verify |
|---|---|
| **G1 100+ items** | Seed the customer list / visit list / message thread with 100+ items. Confirm initial load < 3s, smooth scroll, no jank. |
| **G2 1000+ items** | Push to 1000+. Confirm pagination kicks in OR loading time stays acceptable. |
| **G3 Search performance** | With 1000+ items, search debounces correctly (no DB hit per keystroke) and returns results in < 1s. |
| **G4 Photo upload at scale** | Upload 20 photos in one assessment. Confirm queue handles them, no UI freeze, retry on failure. |

### H. Accessibility (sampled — apply to ~20% of screens)

| Check | What to verify |
|---|---|
| **H1 VoiceOver navigation** | Enable VoiceOver in sim (`xcrun simctl ui ... voiceover on`). Navigate the screen using VoiceOver gestures. Every actionable element should be labeled and reachable. |
| **H2 Dynamic Type** | Set sim text size to "Larger Accessibility" (`xcrun simctl ui ... appearance large`). Confirm layout doesn't break — text wraps, doesn't truncate, doesn't push CTAs off-screen. |
| **H3 Dark mode** | Toggle dark mode (`xcrun simctl ui ... appearance dark`). Every screen should have a dark variant; never a light card on a black bg or vice versa. |
| **H4 Color contrast (WCAG AA)** | Spot-check text on backgrounds. Salmon text on white (`#ED6955` on `#F8F9FA`) is borderline 3:1 — flag if used for body text. Navy on white is fine. |
| **H5 Reduced motion** | Toggle reduced motion in sim settings. Verify animations are gracefully disabled. |

### Required minimum per subagent run

For every scenario the subagent exercises:
- **Always:** A1 (save → relaunch), B1-B4 (salmon, typography, em dashes, brand voice), C1 (empty submit)
- **At least one of:** A2-A8 (additional persistence)
- **At least one of:** B5-B10 (additional UI quality)
- **At least one of:** C2-C8 (additional input edge case)
- **At least one of:** D1-D6 (async / network state)
- **Sample (one or two scenarios per subagent):** E (lifecycle), F (multi-device), G (performance), H (accessibility)

If the scenario doesn't have an applicable check (e.g. a read-only
view doesn't have C inputs to test), the subagent says so explicitly
in the result.

