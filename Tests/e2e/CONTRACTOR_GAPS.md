# Chez Contractor web — gaps log

Findings from the overnight E2E run that the matrix flagged as
"feature-absent" or "incomplete." Grouped by category, then severity,
then matrix section. Each row is meant to feed into product input —
the main thread is NOT auto-fixing these.

Schema additions / behavioral gaps that surfaced during fixture
seeding go in the **Schema gaps** section. Web UI gaps go in the
**Web UI gaps** section. Cross-app desync goes in the **Cross-app
gaps** section.

---

## Schema gaps (surfaced during Phase 0 fixture seeding)

### Major

- **`handyman_requests.source` CHECK constraint excludes `chez_admin`.** The constraint is `('homeowner', 'haven', 'vendor', 'field')`. Phase 80+ added Chez admin orchestration but didn't extend this constraint, so Chez-routed requests cannot self-identify their origin at the row level. Workaround: use `source='haven'` and stamp the flavor in the related message's `metadata`. **Recommendation:** add `chez_admin` to the CHECK list and a corresponding column-level enum / constant on the iOS + web sides.
- **`handyman_requests` has no `metadata` JSONB column.** Phase 80 Chez orchestration needs to stamp routing flavor + acknowledgment requirements at the request level, not just on a relayed message. Today the flavor only lives on the related `handyman_request_messages.metadata`. **Recommendation:** add `metadata JSONB DEFAULT '{}'::jsonb` to mirror the homeowner-side `inbox_items` pattern.

---

## Web UI gaps (filed during waves)

### Critical

- **Auth gate hung on "Loading your workspace…" forever for unauth'd visitors** (FIXED, commit `32c134f8`). `loadDashboard` early-returned on null session without flipping `isLoading` to false, so the App-level redirect to `/handyman.html` never fired. The SPA was completely unreachable without an existing session — every fresh visitor saw a blank loading screen with no way out.
- **`/operations/chez.css` returned the SPA's HTML fallback instead of CSS** (FIXED, commit `85874c1e`). Vite's `base: "/operations/"` rewrites `<link href="/chez.css">` in index.html to `/operations/chez.css`, but no such file existed. Result: every design token (`--indigo-900`, `--salmon`, `--pearl`, `--serif`, `--sans`) was undefined, sidebar bg fell back to transparent, white sidebar text rendered on white page bg = invisible left nav. Fixed via symlink `website/operations/public/chez.css → ../../chez.css`.

### Major

- **W1.5 Crew "+ Invite teammate" button is a no-op** (Section 1.5). `Crew.tsx:56` — button renders but has no `onClick` handler. No invite modal/sheet exists. The entire team-onboarding flow has no UI; `provider_workspace_members.invite_token` cannot be exercised from the web. Recommendation: wire the button to a sheet that captures email + role and calls a new `invite_team_member` Edge Function action.
- **W1.4 Workspace branding settings missing** (Section 1.4). No Settings screen exists in the SPA. `provider_workspaces` has columns for `headshot_url`, `service_state`, `service_city`, `service_zip_codes`, `license_number`, `display_blurb`, `categories` — all unwired. Workspace identity / brand config is not surfaceable from the web.
- **W1.10 Multi-workspace switcher is a stub** (Section 1.10). The sidebar workspace pill is wired but clicking produces no menu/dropdown. Per `// TODO multi-workspace` in `WorkspaceProvider`, owners with multiple workspaces cannot switch contexts.
- **B4 brand voice — `/handyman.html` auth page** (rebrand violations). 10 user-facing "handyman" mentions: page title "Chez Handyman", sidebar brand "chez handyman", eyebrow "FOR HANDYMAN BUSINESSES", body "operating system for handyman businesses", RHS title "Sign in to the full Chez Handyman desk", submit button "Sign in to Chez Handyman". Plus 3 em dashes. The Operations SPA itself (post-auth) is brand-clean. Marketing/auth page rebrand deferred — wider product call.

### Moderate

- **W2.7 Recent threads section renders 4 generic empty placeholders** ("Home / No messages yet. Start the thread.") even when threads exist with seeded messages. Either dashboard query isn't pulling thread message previews, or the fixture didn't seed messages onto threads that surface here. Worth investigating in Wave E (Messages tab).
- **W2.9–2.11 Recent activity feed + smart hero CTA + sort order** (Sections 2.9–2.11) — likely gaps; not surfaced in current SPA.

### Minor

- **W2.8 No `<h2>` headings on Overview** — section labels (NEEDS YOUR ATTENTION / TODAY · FIELD BOARD / QUOTE PIPELINE) are styled `<div>`s, not headings. Screen-reader users miss the document outline. (H1 only.)
- **W1.12 Sign-out `?next=` → routes to `/operations/` instead of `/operations/<route>`** — the next-link path is preserved on the auth page side but the redirect after sign-in lands at the Overview rather than the originally-requested deep link.

---

## Cross-app gaps (Section 21 round-trip findings)

### Critical (architectural)

- **`handyman_punch_items` is never read by the contractor SPA** (Wave C, Section 6.19). The DB has 146 rows of seeded punch items joined to `provider_visit_assignments` via `assigned_visit_task_id`. The `handyman-provider` edge function (line 2233) returns `punchItems[]` per visit. But `VisitDetail.tsx:44` calls `parsePunchList(visit.notes)` — parsing free-text out of `maintenance_tasks.notes` instead of consuming the structured list. The SPA's `VisitRow` type has no `punchItems` field. **Result: every fixture's 3-8 punch items are invisible on the contractor side.** The homeowner iOS app reads the proper `handyman_punch_items` rows, the contractor web reads parsed text from a different table — the two sides are not looking at the same data. This breaks the entire punch-list authoring story (Section 6.20–6.32 are all moot until this is wired). Recommendation: extend `VisitRow` with `punchItems: HandymanPunchItem[]`, rewrite `VisitDetail.tsx` punch-list rendering to consume it, add the authoring CRUD flow, and remove the `parsePunchList(visit.notes)` shim.
- **"Mark complete" inserts no audit-trail message** (Wave C). After flipping `handyman_requests.status = 'completed'`, no `handyman_request_messages` row is appended. The homeowner-side conversation history shows zero record of when the contractor completed the visit, what they did, or any after-action summary. Compare to `chez-concierge` `transition_status` pattern which auto-inserts a system message + fires push. Recommendation: extend `update_request_status` Edge Function action to append a system-role message ("Visit marked complete by [contractor]") + send a push notification to the homeowner.

### Major

- **`maintenance_tasks` rows updated by handyman do not propagate to the homeowner side** (Wave C corollary). When the handyman flips status of a task or adds a note, the homeowner needs to see this in their iOS Maintenance schedule. Verifying the round-trip is part of Wave K. Until punch items + completion summaries surface, the homeowner has no visibility into what the contractor did during the visit.

## Wave D — Section 7 (Quotes) gaps

### Critical — wired inline this run
- **7a empty-state CTA dead button** — `Quotes.tsx` line 73 had `onClick: () => alert("New-quote flow ships next.")` despite the modal being live. Fixed: `onClick: () => newQuote.open()`.
- **7d "+ Add new" saved item button non-functional** — `Quotes.tsx` line 136 had no onClick handler. Wired up an inline form (name + unit + default price) that calls the existing `save_quote_item` action.
- **Brand voice — quote fallback title "Handyman quote"** — `handyman-provider/index.ts` line 4030 fallback was rendered prominently in the user-facing detail header. Changed to "Untitled quote".
- **Brand voice — multiple "handyman" user-facing strings** in edge function: line 215 status label "Sent to handyman", line 1327 push footer "your handyman", line 1722 visit title "Chez Handyman Visit", line 3901 share text "this handyman", line 4191 push body "from your handyman". All rebranded to "contractor". Server redeploy required.
- **Em-dash seed pollution** — `Tests/e2e/run-contractor.mjs` line 463 was seeding 12 quote titles like "Roof repair — Customer 7", and line 468 had a homeowner_message with " — ". Fixed; future fixture runs will be em-dash-clean.

### Major — gaps not yet implemented
- **7.27 Quote-with-options (good/better/best)** — no UI; line items are flat. Real selling tool for HNW Westchester scope tradeoffs.
- **7.29 Quote templates** — no save-as-template or load-from-template flow. Saved line items help, but a full template (multi-line preset) doesn't exist.
- **7.30 Quote duplication** — no "Duplicate this quote" action. Contractor must rebuild every recurring scope.
- **7.31 Quote PDF export** — no `Download PDF` button. Public share URL exists but no offline artifact for filing/email-attach.
- **7.32 Quote eSignature** — no inline signature capture for approval. Homeowner approval flow exists DB-side via `status='approved'` but no signature surface.
- **7.33 Quote → invoice conversion** — no path. Once approved, the contractor must rebuild as a new entity.
- **7.34 Counter visualization** — Status badge says "Homeowner countered" but the contractor sees the SAME line items as the original quote. There's no "the homeowner countered with these specific changes" diff/redline panel. Edit Quote opens the full builder with no markers indicating what the homeowner changed.
- **7.35 Multi-round counter history** — no version chain UI. `parent_quote_id` schema exists (migration 20260907_phase73b_quote_negotiation.sql) but Quotes.tsx doesn't render the chain.
- **7.42 Walk-away point detection** — no "ready to move on?" prompt after N counter rounds.
- **7.43 Auto-expiration** — no `expires_at` on `provider_quotes`, no "this quote expires in X days" surface, no auto-status-flip from `sent` to `expired`.
- **7.44 Negotiation history (timeline view)** — no chronological view of who-said-what across the negotiation. Comments panel shows individual questions but no narrative timeline.

### CRITICAL — Cross-app parity
- **Quote send creates NO homeowner-side audit trail.** Verified via service-role queries:
  - `inbox_items?household_id=X` — no row created on quote send (cross-app gap)
  - `handyman_request_messages?household_id=X` — no audit-trail message inserted (gap; visit completion DOES insert one per commit 38485ba8 but quote send does not)
  - Only path is push notification via `notifyHomeownersForRequest`. Homeowners without iOS push will only discover quotes via the public share URL (which they only learn about from the push they didn't get).
  - Recommendation: mirror the visit-completion pattern. On quote send, insert a `vendor`-role message into `handyman_request_messages` with `metadata.kind = "quote_sent"` so the iOS chat thread shows it.

### Moderate
- **C1 validation uses native `alert()`** — `NewQuoteModal.tsx:183` uses `alert("Pick a home, add a title, and include at least one line item.")`. Functional but jarring vs. the rest of the premium UI; should be inline error states under each field.

---

## Section 19 (Chez admin coordination) — Wave I findings

### Critical — wired inline this run
- **19a.1-5 — Chez routing flavors had ZERO visual differentiation** (FIXED, commit `75eea466`). All 5 Chez-routed inbound flavors (`task_routing`, `visit_routing`, `quote_request`, `standing_engagement`, `emergency_routing`) rendered identically to a direct homeowner request — same grey "Requested" pill, no urgency badge, no Chez attribution, "WHAT THE HOMEOWNER IS ASKING FOR" framing despite the request never coming from the homeowner. Fixed by surfacing `request.source` + `request.urgency` in the dashboard payload, then rendering `Emergency` (red) + `Routed by Chez` (indigo) pills on Overview DecisionRow, VisitDetail header, and Messages thread header. VisitDetail also reframes the "asking for" card as "WHAT CHEZ IS ASKING FOR" with an explainer banner ("Routed by Chez. Replies on this thread go to the Chez admin, who relays back to the homeowner.") and the reply composer placeholder ("Reply to Chez. They'll relay to the homeowner."). Decision queue sort: emergency first, Chez-routed second, routine last.

### Critical — gaps not fixed
- **19c.16 Chez auto-summary of customer's standing instructions** — `households.chez_profile` JSONB exists DB-side (Phase 80.1) with `about_us`, `vendor_preferences`, `logistics`, `spending_tiers`. Not consumed anywhere in `website/operations/src/`. Contractor has zero visibility into the spending authority threshold (`auto_approve_under` / `ping_under` / `explicit_above`) at quote-build time — risks a $500 quote to a household whose `explicit_above` is $200. Recommendation: surface a "Customer profile" pane on VisitDetail right rail when the household's `chez_profile` is non-empty, including a salmon spending-tier pill ("Ping Chez before quoting over $500").
- **19d.17/18 chez_owned banner / state changes** — `routines.chez_owned` and `contractors.chez_owned` columns exist (Phase 80.1 / 80.2). Contractor SPA never reads or surfaces these. When a homeowner toggles `chez_owned=true` for a contractor, the contractor side has no banner explaining "Chez now coordinates this customer" — they continue to attempt direct outreach. Recommendation: handyman-provider should denormalize `chez_owned` into the contractor record + workspace dashboard, then HomeDetail / Homes screens render a salmon banner on the customer card.
- **19d.19/20 list of Chez-owned customers / standing engagements** — no filter or list view. Recommendation: Crew or Homes screen needs a filter chip "Chez-coordinated" that walks `contractors.chez_owned=true` for any contractor in this workspace.
- **19c.15 group thread (contractor + Chez + customer)** — Messages renders the homeowner thread with optional Chez bubbles, but there's no surface where the contractor can see the parallel Chez ↔ homeowner thread (which is the whole point of Chez orchestration — the contractor sometimes needs to see what the homeowner originally asked Chez vs. what Chez is asking the contractor for). Recommendation: VisitDetail right rail "Original homeowner request" expandable card.

### Major — gaps not fixed
- **Section 19a contextual chrome** — Even with the Routed by Chez pill (this run's fix), there's no Chez-specific affordance for the 5 flavors. Current state treats all 5 as identical "Routed by Chez" items. A Quote Request Routing flavor should auto-link to Build a Quote with a salmon CTA ("Chez is asking for a quote — build one"). A Standing Engagement should land on a different surface entirely (a dedicated Chez Standing Engagements screen). An Emergency Routing should fire a desktop notification + add a phone number link. None of this exists.
- **19b.7 Decline with reason** — `update_request_status` accepts `declined` server-side, but the SPA has no Decline button. There's no surface to decline a Chez-routed request without ghosting it (or going through Mark Complete, which is wrong).
- **19b.8 Counter** — `propose_visit_time` exists for time changes, but there's no path to counter scope or pricing back to Chez ("Can we re-scope this to drain-cleaning only?"). Counter would be how the contractor pushes back without dropping the request.

### Cross-app parity gap (verified via DB query)
- **Chez routing creates NO homeowner-side audit trail.** When Chez admin routes a request to a contractor, the homeowner has no `inbox_items` row, no `chez_requests` row, no `handyman_request_messages` event. The homeowner literally doesn't know Chez did anything on their behalf. Verified by querying the 5 seeded fixtures: `inbox_items?household_id=in.(...)` returned 0 rows; `chez_requests?household_id=in.(...)` returned 0 rows. Recommendation: the chez-concierge Edge Function (which owns Chez admin actions) should mirror every routing decision into BOTH `chez_requests` (with `admin_initiated=true`) AND `inbox_items` (type=`chez_status_change`) so the homeowner has a record. Alternatively, the seeded fixture path needs fixing to create those rows alongside the `handyman_requests` row.
- **Pre-existing seed data: em-dashes in 3 "Initial setup" titles** — `handyman_requests` rows like "Initial setup — O'Brien-Müller 1778176425027" rendered with em-dashes. The current code (`handyman-provider/index.ts:3077`) uses `Initial setup: ${clientName}` (colon, no em-dash), so this is legacy data from an earlier version. Future fixture re-seeds will be clean; existing test rows are tombstones.

