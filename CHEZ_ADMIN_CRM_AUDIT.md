# Chez Admin Panel — CRM / Customer-Service Operations Audit

**Date:** 2026-05-12
**Reviewer:** Claude (Opus 4.7)
**Scope:** Everything an operator (Tom) needs to actually run Chez as a customer-service org — discover homes, drill in, coordinate, negotiate, and have the work reflected back to the homeowner in real time.
**Verdict:** ~60% of the surface area is built. The backbone (cockpit, workbench, edge function, schema) is solid. The customer-service "ergonomics" layer is mostly missing — and that's the part Tom touches every hour of every day.

---

## TL;DR — The 7 things that are missing

| # | Gap | Severity | Current state | What's needed |
|---|---|---|---|---|
| 1 | **Home is not the top-level surface.** Default landing is Quiz Builder. Concierge cockpit is case-centric (one case at a time). Households tab exists but is buried at slot 3. | **Critical** | `state.view = "quiz"` (`admin.js:554`); Households is a sibling tab in the Action section, not the front door. | Make Households the default. Sort by next-event urgency, not alphabetical. Drill-in flow should land on the **Home overview** (address as masthead) → then 8 entity tabs the workbench already has. |
| 2 | **No outbound channel to vendors.** Tom calls vendors on his phone, then types notes into the cockpit. | **Critical** | No "Email vendor" / "Text vendor" button anywhere. `draft_negotiation` action returns `{ drafted: false, reason: "claude_draft_not_yet_wired" }` (`chez-concierge/index.ts:3227`). Only outbound function is `send-vendor-inquiry` which is homeowner→vendor with `alfred.getchez.com` reply-to, **not Chez→vendor**. | New `chez_vendor_outreach` table + outbound email function (`send-chez-vendor-email`) with reply-to `alfred-vendor@getchez.com` that routes vendor replies back into the case thread. SMS later (legal review needed). |
| 3 | **"Have Chez handle this" sets a flag but doesn't auto-spin work.** | **Critical** | Flipping `chez_owned` writes the bool + creates a "Standing engagement" parent request. That's it. No category-specific playbook fires. | Per-category playbooks ("find_vendor" → kick off `analyze_request` automatically + draft outreach email + populate vendor call queue; "schedule_visit" → check existing contractor → propose 3 dates; etc.) |
| 4 | **Negotiation is schema-only.** | **High** | `project_quotes.negotiation_history` JSONB column exists (migration `20261208`). `add_project_negotiation_turn` action exists but the `draft_negotiation` companion is a NO-OP. No UI to compose a counter-offer message and send it. | Wire `draft_negotiation` to Claude (model: sonnet-4-6, prompt: counter-offer email body using homeowner's standing instructions). Add the counter-offer composer + send-to-vendor flow in the cockpit Project Workbench. |
| 5 | **Operator work doesn't always reflect on homeowner side.** | **High** | Replies, proposals, status changes, and `chez_visits` all push to iOS. But `chez_workbench_actions` (the audit table for "Tom scheduled a visit", "Tom logged service", "Tom audited a bill") is NOT read by iOS. The migration comment literally says *"Recent Chez activity feed (post-Phase 84.1)"* — not built. | iOS `ChezActivityFeed` component on Dashboard + per-entity activity row (e.g. on a System's detail screen, show "Chez logged service on Apr 22"). Server-side: also auto-create a system-role `concierge_message` for high-signal actions ("Chez scheduled Petro for Apr 30 at 2pm") so the case thread reflects it. |
| 6 | **No CRM hygiene layer.** | **Medium** | Tom is sole admin; no assignment, no tags, no canned responses, no case merge, no priority overrides beyond SLA, no "snooze until customer responds with X". | Even at solo scale: case tags (`property`, `vehicle`, `urgent`, `vip`), saved-reply snippets ("We'll have 3 options for you by Friday"), and one-button case-merge (when the homeowner sends two emails about the same thing) cover ~80% of friction. |
| 7 | **Conversation window can't execute** — operator has to leave the thread to do work. | **Medium** | Reply composer is a textarea. Proposal builder is a separate modal. To schedule a task, you click out of the case into the workbench. To add a vendor on behalf of the homeowner, no inline path exists. | Slash-command composer ("/schedule visit Petro 4/30 2pm" → posts proposal + creates chez_visits row; "/add-vendor Tyler Heating" → adds to contractors + sends introduction message). |

---

## What IS built (so we don't accidentally rebuild it)

### Concierge cockpit (Phase 83) — 4-pane case workspace
- `website/admin.js:5012` `renderConciergeCockpit()`
- Layout: Queue rail (304px) · Homeowner panel (320px) · Case workspace (flex) · Alfred sidebar (360px)
- **Queue rail** has filter tabs (All / Mine / Urgent), search, master-detail mode (`queueMode === "case"` → rail becomes chat panel)
- **Case workspace** has sub-panes: Brief (AI analysis), Vendor sheet (Google Places + existing network), Visits (lifecycle), Conversation
- **Alfred sidebar** has 3 tabs: Actions (7-10 suggested next steps), Chat (single-shot Q&A via `ask_alfred`), Similar (past cases)
- **41 action handlers** wired in `handleConciergeAction()` at `admin.js:7611`
- State persists `ui` (aiOpen, density) to localStorage; everything else session-only

### Households workbench (Phases 84/85) — per-household entity hub
- `admin.js:17265` `renderHouseholdsView()`
- 8 entity tabs: Routines / Systems / Vendors / Tasks / Projects / Documents / Bills / Vehicles + a Cases tab
- Per-row actions: schedule, log_service, log_call, send_message (local note), audit_bill, etc.
- Search + owned-only filter per tab
- All actions route through `workbench_action` edge action → real DB write + audit row in `chez_workbench_actions`
- **This is the closest thing today to what you want as the front door.** The bones are right; it just needs to be promoted, restructured, and connected to the cockpit.

### Edge function — 44 actions
- Single discriminator function `chez-concierge/index.ts`
- Auth: JWT + email allowlist via `CHEZ_ADMIN_EMAILS`
- Universal delegation: `delegate_routine` / `delegate_contractor` / `delegate_task` / `delegate_entity` / `set_ownership_group`
- Proposals: `propose` (vendor / date_slot / cost / quote kinds) + `decide_proposal`
- AI: `analyze_request` (research pipeline), `suggest_vendor_framing`, `ask_alfred`
- Visits: `fetch_visits` / `update_visit`
- Dossier: `fetch_dossier` (full household snapshot)
- Households: `fetch_households_list` / `fetch_household_workbench`
- Negotiation: `add_project_negotiation_turn` (turn-append works; `draft_negotiation` is NO-OP)
- Workbench: `workbench_action` (audits + executes side effect)
- Reminders: `create_reminder` / `complete_reminder`
- Assessments: 8 actions for Phase 84.5 handyman home assessment
- Admin-initiated cases: `admin_submit` ("Chez started this for you")

### Schema — homeowner-facing entities Chez can manipulate
- `chez_requests` (6 categories, 3 statuses, SLA via `chez_business_hours_due()`)
- `concierge_messages` (extended with `request_id`, `attachments`, `proposal` + `proposal_kind`)
- `chez_visits` (visit lifecycle: awaiting_date → scheduled → completed)
- `chez_workbench_actions` (audit trail — written but not read on iOS yet)
- `chez_activity_log` (Phase 85 PR 5c — exists, undermined: needs an iOS reader)
- `households.chez_profile` (standing instructions JSONB: about_us / communication / vendor_preferences / logistics / spending_tiers)
- `routines.chez_owned`, `contractors.chez_owned`, `maintenance_tasks.chez_owned` + `chez_request_id`
- `inbox_items.related_chez_request_id` (links Chez activity to iOS Inbox)
- `contractors.chez_request_id` + `chez_recommended_at` ("Sourced by Chez" badge)

### iOS side
- 18 verified `ChezEntryButton` callsites — every major surface has a "Have Chez handle this"
- `ChezRequestDetailView.swift` renders thread + proposal cards + composer + reopen
- `ChezProposalCard` renders Approve / Counter / Decline for all 4 proposal kinds
- `inbox_items` typed `chez_reply_action_needed` (action) / `chez_reply_informational` (FYI) / `chez_status_change`

---

## The 7 gaps — detailed

### Gap 1 — Information architecture is case-first, not home-first

**What you said:** "top level should be the 'Home' like the address itself, then its systems, vendors, tasks, routines, etc."

**What's there today:**
- Default view on load is **Quiz Builder** (`state.view = "quiz"` — admin.js:554). That's a catalog-building tool, not a customer-service surface.
- The 5 Action-section tabs are: **chez / upcoming / households / audit / vendor_apps**. Concierge is first, Households is third.
- The cockpit's homeowner panel is a 320px sidebar of summary text, not a home-rooted page. The address shows as one line in the homeowner panel; the home's systems / vendors / etc. only appear if you switch tabs out of the cockpit.
- Households workbench, when you do find it, lists by household name not address, and lands you on the Routines tab by default — no "Home overview" page.

**What needs to happen:**
1. Default landing → Households view (or a new "Today" command center that shows cases needing attention + upcoming visits across all households)
2. New top-level layout inside a household: **Home overview** (address as h1, photo, key family contacts, standing instructions card, "Chez handles" coverage summary, "Today" feed) → then the existing 8 entity tabs below
3. Concierge cockpit becomes a slide-over from within a home, not a parallel tab. When you click a case from the Home's "Open cases" section, the cockpit opens over the home — but the home stays as context anchor.
4. Top nav becomes: **Homes** (default) · **Inbox** (cross-home unread) · **Today** (upcoming visits + SLA-due cases across all homes) · **Reports** (catalog quality, AI usage, response time) · **Catalog** (collapse Quiz/Walkthrough/Tasks/Routines/Systems/Vendors/Vehicles into one dropdown — those are admin tools, not daily-use)

**Build cost:** Medium. The render functions exist; this is mostly a routing + composition change. ~2 days of work to land the inversion cleanly.

---

### Gap 2 — No outbound channel to vendors

**What you said:** "do all of the coordination and coorespondence as well for them."

**What's there today:**
- The `send-vendor-inquiry` edge function (`supabase/functions/send-vendor-inquiry/index.ts`) sends email **from homeowner persona to vendor** with reply-to set to homeowner's `*@alfred.getchez.com` forwarding address. That routes vendor replies back through receive-email into the homeowner's inbox.
- That's **NOT what we need.** When Chez is acting on behalf of the homeowner, the email should come **from Chez** with reply-to going to a **Chez-controlled address** so the conversation lives in the case thread, not in the homeowner's inbox.
- The cockpit `send_message` button on a contractor row writes a local note to that contractor's record. It does NOT email/text the vendor.
- `draft_negotiation` action in chez-concierge returns `{ drafted: false, reason: "claude_draft_not_yet_wired" }`. No counter-offer email generation.
- No SMS to vendors anywhere. Per the audit comment in send-vendor-inquiry: "in-app first + email fallback only (NO SMS) for handyman messaging."

**What needs to happen:**
1. **New table:** `chez_vendor_outreach` — every outbound vendor communication with `request_id` FK, `vendor_id` FK, `direction` (outbound/inbound), `channel` (email/sms/call_log), `subject`, `body`, `attachments`, `sent_at`, `reply_to_token`.
2. **New edge function:** `send-chez-vendor-email` — uses SendGrid, FROM "Chez Concierge <hello@getchez.com>", reply-to `vendor+<reply_token>@alfred.getchez.com`. Drafts available via Claude using homeowner's standing instructions + case context.
3. **Extend receive-email:** new regex branch for `vendor+<token>@alfred.getchez.com` → look up the outreach row → post the vendor's reply as a `system`-role concierge_message tagged `from_vendor` in the case thread.
4. **Wire `draft_negotiation`** to actually call Claude with a counter-offer prompt (homeowner's spending tiers + the current quote + standing instructions for negotiation tone).
5. **Cockpit UI:** in the Vendor sheet, every vendor row gets an "Email vendor" button → opens a slide-over composer pre-filled by AI → click send → goes through `send-chez-vendor-email` → outreach row appears in case thread as a "system" message labeled "📧 To Petro: ..." with reply hooked up.

**Build cost:** Medium-large. Net new table + edge function + receive-email branch + cockpit composer. ~3-4 days. Legal note for SMS: stays deferred until you've done the consent flow work.

---

### Gap 3 — "Have Chez handle this" sets a flag but doesn't auto-spin work

**What you said:** "when someone clicks on have chez handle this for any task, routine, vendor, handyman, system, etc. we can actually do all of the work we need to."

**What's there today (per category):**

| Entry point | What fires today | What's missing |
|---|---|---|
| **Task** (`delegate_task` action) | Sets `maintenance_tasks.chez_owned = true`. Creates a `chez_request` with category routed to `find_vendor` (if no contractor) or `coordinate_task` (if contractor exists). System message + push + admin email. | No automatic vendor sourcing kicks off. No "draft outreach to assigned contractor" run. No vendor call-script pre-population. Operator has to manually click "Run analysis" to get the vendor brief. |
| **Routine** (`delegate_routine`) | Sets `routines.chez_owned = true` + creates "Standing engagement" parent request + system message + push + admin email. | No "I'll be handling all your snow removal" intake checklist (preferred plow time? early start when forecast says >4"? cleanup zones?). No automatic vendor confirmation cycle (annual contract renewal in October). |
| **Vendor / Contractor** (`delegate_contractor`) | Sets `contractors.chez_owned = true` + parent request + system message + push + email. | No "I'll handle Petro for you" intake (preferred service window? auto-approve up to $X? notify before scheduling vs auto-book?). No vendor introduction email ("Hi Petro, I'm Chez, I'll be coordinating Tom's HVAC service from now on; please send invoices to..."). |
| **Handyman (find a)** | `category: find_handyman` request created. | Should auto-trigger home assessment workflow + check existing handyman workspace eligibility. Some of this exists in Phase 84.5 / 85 but isn't wired into the delegation flow. |
| **System** (Phase 84 `delegate_entity`) | Sets `home_systems` ownership flag. | Should auto-pull manufacturer manual (we have `lookup-manual` edge function), set up annual service reminder, identify the matching vendor in the homeowner's directory or surface a "we need a pro for this" prompt. |

**What needs to happen — "playbooks" per delegation:**

Create `chez_playbooks` data model (could be code-defined, not table-driven for v1). Each playbook has:
- `entity_type` (task/routine/contractor/system/...)
- `category` (find_vendor / coordinate_task / etc.)
- `steps`: ordered list of automation steps that fire on delegation
  - `analyze_request` (call existing action; pre-populate vendor brief)
  - `draft_intro_email` (Claude generates intro to existing vendor)
  - `draft_vendor_search` (Claude pre-populates outreach to 3 Google Places candidates)
  - `set_followup_reminder` (auto-create a reminder for 24h from now to check status)
  - `post_to_thread` (post a system message: "Chez is on it. We're sourcing 3 candidates and will have options by tomorrow EOD.")

Playbook runs server-side at delegation time. The operator can review what auto-fired in the case thread as system messages + can intervene before any outbound message goes out (drafts saved to `chez_vendor_outreach` with `status: "draft_pending_review"`).

**Build cost:** Large. This is the "automation layer" that makes Chez feel magical. ~5-7 days for the v1 with 3-4 playbooks. But each playbook unlocks compound value — every "Have Chez handle this" tap from then on does meaningful work without operator click-through.

---

### Gap 4 — Negotiation is schema-only

**What you said:** "and we can negotiate for them."

**What's there today:**
- Schema: `project_quotes.negotiation_history JSONB` (migration `20261208_project_negotiation_history.sql`). Shape: `[{ "from": "chez" | "vendor", "message": string, "price_cents": int, "sent_at": ISO }]`.
- Edge action: `add_project_negotiation_turn` appends a turn. Works.
- Edge action: `draft_negotiation` returns `{ drafted: false, reason: "claude_draft_not_yet_wired" }` (chez-concierge/index.ts:3227-3229). NO-OP.
- Admin UI: "Open negotiation pane" button on a project row in the workbench (admin.js:18193) — but the pane itself doesn't have a counter-offer composer.

**What needs to happen:**
1. **Wire `draft_negotiation`** to Claude sonnet-4-6 with a structured prompt:
   - Input: current quote (line items, total, vendor info), homeowner spending tiers, standing instructions, target reduction %, optional operator notes
   - Output: counter-offer email body in homeowner-preferred tone, suggested counter price, rationale
2. **Counter-offer composer in Project Workbench:**
   - Side-by-side: original quote line items + the operator-editable counter (which lines to push back on, whether to ask for swap vs. discount)
   - "✨ Draft counter" button calls `draft_negotiation` and prefills the email
   - "Send to vendor" button writes to `chez_vendor_outreach` + appends turn to `negotiation_history`
   - When vendor replies (via receive-email branch), the reply gets parsed for new price/terms and surfaces as a "vendor counter received" turn in the negotiation_history
3. **iOS surface:** when vendor accepts or counters meaningfully, post structured `proposal` (kind=`cost` or `quote`) to the case thread → homeowner sees Approve / Decline.

**Build cost:** Medium. ~2 days. Most of the surface area is wiring existing pieces together; the Claude prompt + reply-parsing are the new bits.

---

### Gap 5 — Operator work doesn't fully reflect on homeowner side

**What you said:** "ensure any work we accomplish for that customer is reflected in their app also."

**What's there today (works fine):**
- ✅ Admin replies → iOS sees `inbox_items` row (action_needed or informational) + push
- ✅ Status transitions → iOS system message + inbox item + push
- ✅ Proposals (vendor/date/cost/quote) → iOS Approve/Counter/Decline cards in thread
- ✅ `chez_visits` rows → iOS shows visit cards in case detail
- ✅ Vendors sourced by Chez → `contractors.chez_recommended_at` → "Sourced by Chez" badge on Contacts card

**What's broken or missing:**

| Operator action | Today's homeowner-side reflection | What's missing |
|---|---|---|
| Tom uses workbench to **complete a task on behalf** | Task is marked complete in DB. Audit row in `chez_workbench_actions`. | iOS doesn't render a "Chez completed this task" event. No notification. The homeowner sees the task disappear from their list but no attribution. Need: auto-post a system message to the case thread ("Chez marked 'Schedule chimney sweep' complete on May 12") + Dashboard "Recent Chez activity" feed reading from `chez_workbench_actions`. |
| Tom uses workbench to **log a service record** on a system | service_records row inserted. Audit row written. | Same as above — no notification, no system message, no activity feed entry on iOS. |
| Tom uses workbench to **schedule a routine visit** | routine_visits row inserted with scheduled_for. Audit row written. | iOS already shows routine_visits in the routine detail, but no notification fires and no case thread message. |
| Tom adds a vendor to the homeowner's directory **outside a case** (e.g. during proactive outreach) | contractors row inserted. | No iOS reflection that "Chez added Tyler Heating to your network on May 12". |
| Tom **audits a bill** and finds savings | workbench action fires. | No structured "Chez found you $X/yr by switching to Y" surfacing on iOS — should be a proposal card (kind=`cost`?) or its own kind. |

**What needs to happen:**
1. **iOS `ChezActivityFeed` component** that reads `chez_workbench_actions` (already RLS-scoped to household_id), renders on Dashboard between Hero and Recent Activity. Per-action verb-first copy: "Chez completed: Schedule chimney sweep", "Chez logged service: HVAC tune-up by Petro on Apr 22, $245".
2. **Auto-system-message hooks** in `runWorkbenchSideEffect`: for the high-signal action types (complete_on_behalf, schedule_visit, log_service, schedule_maintenance, audit_bill), insert a `system`-role `concierge_message` on the linked `chez_request` (when `request_id` is present in the workbench action payload) so the case thread reflects it.
3. **Push notification rules** for workbench actions tied to a request: same channel as `reply` notifications, copy = "Chez completed something for you" + body = action description.
4. **Per-entity activity timeline**: on the iOS System / Routine / Vendor detail screens, show the most recent `chez_workbench_actions` for that entity (filtered by `entity_id`). "Chez logged service" / "Chez confirmed appointment with Petro" / "Chez audited your last 6 bills — saved $312/yr."

**Build cost:** Medium. Schema is already there. ~2-3 days for the iOS surfaces + the auto-message hooks in the edge function.

---

### Gap 6 — No CRM hygiene layer

**What's there today:**
- ✅ Case search across summary/category/household_id
- ✅ Queue filter (All / Mine / Urgent)
- ✅ Status (open / waiting_customer / resolved)
- ✅ SLA pill (overdue / critical / due-soon)
- ❌ No teammate assignment (Tom is sole admin; multi-operator deferred but should be designed-in now)
- ❌ No case tags (e.g. `vip`, `escalated`, `winter-snow`, `vendor-issue`)
- ❌ No canned responses / saved snippets
- ❌ No case merge (when same household sends 2 emails about same thing)
- ❌ No case linking ("this is a follow-up to case #423")
- ❌ No priority override beyond SLA
- ❌ No "snooze until X happens" (only snooze for N hours)

**What needs to happen (priority-ordered for solo-operator scale):**

1. **Canned responses** (highest leverage; ~half a day) — `chez_snippets` table (operator-personal, not per-household). Composer has `/` slash trigger that opens a picker. Snippets support variables (`{homeowner_first_name}`, `{address_street}`, `{vendor_name}`). First 10 snippets seeded: "We'll have options by Friday EOD", "Confirmed for [date]", "Reaching out to vendor today, will report back tomorrow", etc.

2. **Case tags** (~half a day) — `chez_request_tags` join table. Tags applied via cockpit tag chip in case header. Queue rail gains a tag filter. Tags color-coded.

3. **Case merge** (~1 day) — merges thread B into thread A: copies messages, transfers proposals, transfers visits, closes B with `archived_reason = "merged_into:<A>"`. iOS thread for B shows "This conversation was merged with X".

4. **Case linking** (`related_case_ids` array) (~half a day) — operator can link parent/child cases. Cockpit header shows "Related cases (2)" with deep-links.

5. **Multi-operator** — design it now, don't ship it now. The `chez_workbench_actions.performed_by_user_id` column already exists. The queue's `Mine` filter already implies a per-operator concept. Just need: `chez_request.assigned_to_user_id`, an "Assign" action, and an "Unassigned" queue filter. ~1 day when you have your first operator.

**Build cost:** ~3 days for items 1-4, design item 5.

---

### Gap 7 — Conversation window can't execute

**What you said:** "do everything within our conversation window with that customer."

**What's there today:**
- Reply composer is a textarea. Send button.
- Tone selector (warm / direct / formal).
- Attachment buttons (photo / file).
- Separate side-panel actions: Snooze / Resolve / Reopen / Rerun Analysis / New Case.
- Proposal builder is a separate flow that opens above the composer.
- To schedule a task / add a vendor / log a service → operator has to leave the case and go to the Households workbench.

**What needs to happen — slash-command composer:**

Composer becomes a power tool. Type `/` and a picker appears:

| Command | Effect |
|---|---|
| `/schedule visit <vendor> <date> <window>` | Creates `chez_visits` row + posts proposal_kind=date_slot to thread |
| `/add-vendor <name> <category>` | Opens inline form pre-populated with Places lookup → confirm → inserts into contractors + posts "Chez added X to your directory" system message |
| `/log-service <system> <date> <vendor> <cost>` | Inserts service_records + audit row + posts system message |
| `/complete <task-title>` | Marks task complete on behalf + audit + system message |
| `/propose-cost <amount> <scope>` | Quick proposal_kind=cost card |
| `/propose-vendor <vendor-name>` | Opens vendor proposal picker prefilled |
| `/counter <quote-id>` | Opens negotiation counter composer for that quote |
| `/draft-email <vendor>` | AI drafts vendor outreach email; review → send |
| `/snippet <key>` | Inserts canned snippet (gap 6) |
| `/escalate` | Marks case escalated + adds tag |

The picker is keyboard-navigable. Sending a slash command executes the action + posts the message (or just executes silently for read-only ones).

**Build cost:** ~3-4 days for v1 with the top 6 commands. Each additional command is ~half a day.

---

## What Tom is asking for vs. what exists — capability matrix

| Capability you named | Exists? | Where | Gap |
|---|---|---|---|
| Top-level = Home (address) | ❌ | Households tab is buried; default is Quiz Builder | Gap 1 |
| Drill: Home → Systems / Vendors / Tasks / Routines | ⚠️ Partial | Households workbench has 8 entity tabs, but no Home overview anchor | Gap 1 |
| Full CRM capabilities | ❌ Partial | Search + status filter exist; no tags, snippets, merge, assignment | Gap 6 |
| "Have Chez handle this" → flag flips | ✅ | `delegate_*` actions | — |
| "Have Chez handle this" → real work fires | ❌ | Sets flag, creates parent request, that's it | Gap 3 |
| Auto research on intake | ⚠️ Partial | `analyze_request` exists (Claude + Places) but only fires on operator click, not auto on delegation | Gap 3 |
| Vendor email outbound | ❌ | No code path | Gap 2 |
| Vendor SMS outbound | ❌ | Explicitly out of v1 scope | Gap 2 (deferred) |
| Negotiate on quotes | ❌ | Schema only; UI NO-OP | Gap 4 |
| Operator work shows on iOS Dashboard | ⚠️ Partial | Replies, proposals, status, visits flow; workbench actions don't | Gap 5 |
| Operator can schedule vendor visit | ✅ | `update_visit` + proposal flow | — |
| Homeowner can confirm/follow up on a scheduled visit | ✅ | Proposal cards + thread + case detail visit cards | — |
| All coordination + correspondence inside conversation window | ❌ | Most actions require leaving the thread | Gap 7 |

---

## Recommended phasing

I'd build this in 4 phases. Each is releasable independently and compounds.

### Phase 86A — Home-first information architecture (3 days)
- Make Households the default landing
- New "Home overview" page (address as masthead, key family contacts card, standing instructions card, "Chez handles" coverage card, "Today" feed of upcoming visits / due tasks / open cases)
- Concierge cockpit becomes a slide-over from within a home
- Top nav rationalized: Homes · Today · Inbox · Reports · Catalog (collapsed dropdown)

**Unlocks:** Tom can finally use the panel as a customer-service tool, not a catalog editor. Visible win.

### Phase 86B — CRM hygiene + slash composer (4 days)
- Canned responses (snippets table + picker)
- Case tags
- Case merge + linking
- Slash-command composer with top 6 commands (`/schedule`, `/add-vendor`, `/log-service`, `/complete`, `/snippet`, `/escalate`)
- Two-way sync: `ChezActivityFeed` on iOS + auto-system-message hooks for high-signal workbench actions

**Unlocks:** 10x speed on routine ops. Every homeowner sees Chez activity reflected daily.

### Phase 86C — Vendor outbound + negotiation (5 days)
- `chez_vendor_outreach` table
- `send-chez-vendor-email` edge function with reply-routing via `vendor+<token>@alfred.getchez.com`
- receive-email branch for vendor replies → posts to case thread as `from_vendor` system message
- Wire `draft_negotiation` to Claude sonnet-4-6
- Counter-offer composer in Project Workbench
- Auto-parse vendor reply for new price/terms → updates `negotiation_history` + posts cost proposal to homeowner

**Unlocks:** Chez can negotiate. This is the moat moment — homeowner sees Chez emailing vendors on their behalf, getting concessions, surfacing the win as a structured proposal.

### Phase 86D — Playbooks (5-7 days)
- `chez_playbooks` (code-defined for v1, not DB-driven)
- 4 v1 playbooks: `find_vendor`, `coordinate_task`, `schedule_visit`, `audit_bill`
- Each playbook auto-fires `analyze_request` + drafts outreach + sets follow-up reminder + posts intent message
- Operator approves drafts in the case thread before they go out (`draft_pending_review` status)

**Unlocks:** Every "Have Chez handle this" tap from then on does meaningful work without operator click-through. Scale moment.

**Total: ~17-19 days** for the full build. Phase 86A alone is shippable in 3 days and delivers most of the felt-quality improvement.

---

## Open questions I'd want your call on

1. **Do you want a "Today" command-center page across all households**, or is "Homes" the right top-level?
   - Recommendation: BOTH. Today is the default at peak (upcoming visits + SLA-due cases). Homes is the default when nothing urgent.

2. **For canned responses — operator-personal or shared?**
   - Recommendation: Operator-personal, with an "Add to org library" button for promotion. Solo today; multi-operator later.

3. **For vendor email — same reply-to domain (`alfred.getchez.com`) or new dedicated one (`vendors.chez.com`)?**
   - Recommendation: same domain to avoid SendGrid auth work. Use sub-addressing (`vendor+<token>@alfred.getchez.com`).

4. **Negotiation — do you want Claude to fully draft + auto-send, or always require operator review?**
   - Recommendation: ALWAYS operator review for v1. Claude drafts, operator skims, operator hits send. This is the highest-stakes outbound; brand voice and price negotiation deserve eyes-on.

5. **For multi-operator design — assign on create or assign on claim?**
   - Recommendation: Both. Round-robin auto-assign on create (when team grows), but anyone can "claim" any unassigned case.

6. **Should iOS show a Chez activity feed inline or as a dedicated tab?**
   - Recommendation: Dashboard card section (`Recent Chez activity`) for the last 7 days; deep-link to a full timeline view for everything older. Reuses Phase 52's RecentActivityFeed pattern.
