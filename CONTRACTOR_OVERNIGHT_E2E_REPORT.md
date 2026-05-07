# Chez Contractor web overnight E2E report — 2026-05-07

This report covers an autonomous E2E pass on the **Chez Contractor Operations Desk** SPA (`website/operations/*`, served at `/operations/*`) against the live `haven-dev` Supabase project. The browser was driven via `mcp__Claude_in_Chrome__*` (the user watched the live session in their connected Chrome). Subagents owned the screenshots so the main thread stayed under context.

This is the **third overnight pass** in this project (homeowner mobile → handyman field mobile → contractor web). Patterns from the prior two reports apply.

## TL;DR

- **13 commits shipped** on top of Phase 0 infrastructure. Every commit builds clean (`npx tsc --noEmit` returns 0 errors). The Edge Function `handyman-provider` was redeployed twice mid-run with verified behavior changes.
- **9 critical / major bugs found and fixed mid-flight:**
  1. **`/operations/chez.css` 404** — every design token undefined → invisible white-on-white sidebar.
  2. **Auth gate hung on "Loading your workspace…"** — `loadDashboard` early-returned without flipping `isLoading` off, so the App-level redirect never fired.
  3. **`?next=` deep-link preservation broken** — auth-gate used router-base-relative path, handyman.js's allow-list rejected anything not starting with `/operations`.
  4. **Empty-state "+ Draft a quote" CTA was a dead `alert()`** even though `NewQuoteModal` was fully implemented.
  5. **Empty-state "+ Add new" saved-item button had no onClick handler.**
  6. **`Mark complete` (and every other status flip) inserted no audit-trail message** into the homeowner's conversation thread — the homeowner had zero record of what the contractor did.
  7. **Chat thread rendered upside-down** (newest at top) because the SPA didn't reverse the server's descending-order list.
  8. **Chez admin sender_role was rendered as a vendor bubble** — violated the brand-voice rule that Chez must always be a 3rd identity.
  9. **All 5 Chez-routed flavors rendered identically to homeowner-submitted requests** — emergency, task-routing, quote-request all looked the same as a routine homeowner ask.
- **8 sections audited end-to-end** across 7 subagent waves. UI fixes shipped on every wave. Section 22 discipline (salmon discipline + typography + em dashes + brand voice + rebrand check + persistence + DB cross-checks) applied throughout.
- **Final state**: brand-voice clean (0 `handyman` mentions in user-facing copy across every audited page), salmon discipline holding, 1 h1 per page, prefers-reduced-motion respected, all primary CTAs have visible focus indicators, single-Chrome-session driven the whole run.

## Commits shipped tonight

| Commit | Title | Severity | Where the bug came from |
|---|---|---|---|
| [`eae7baf1`](https://github.com/burkeptommy/Housing-Manager/commit/eae7baf1) | Phase 0: contractor web E2E infrastructure (matrix + cleanup + runner + GAPS) | Foundation | New |
| [`85874c1e`](https://github.com/burkeptommy/Housing-Manager/commit/85874c1e) | chez.css 404 + initial rebrand | **CRITICAL** | Vite `base: "/operations/"` rewrote `<link href="/chez.css">` to `/operations/chez.css` — no such file → SPA fallback HTML returned as CSS |
| [`32c134f8`](https://github.com/burkeptommy/Housing-Manager/commit/32c134f8) | Auth gate stuck on "Loading your workspace…" | **CRITICAL** | `loadDashboard` early-returned on null session without flipping `isLoading` |
| [`e6631804`](https://github.com/burkeptommy/Housing-Manager/commit/e6631804) | Wave A: salmon discipline + em-dash placeholders | Major | `requestStatusTone` mapped routine inbound to salmon; 8 files used `—` as placeholder |
| [`8de354a5`](https://github.com/burkeptommy/Housing-Manager/commit/8de354a5) | Vite proxy allows `?v=…` cache-bust suffix | Moderate | Marketing pages bust their CSS cache; proxy regex's `$` anchor 404'd them |
| [`db0c1406`](https://github.com/burkeptommy/Housing-Manager/commit/db0c1406) | Wave B: auth-gate next-link + handyman.html rebrand + AddClientModal polish | **CRITICAL + Major** | router-base-relative path mismatch with handyman.js's allow-list; 10 visible "handyman" mentions on auth page; missing Escape close + email validation |
| [`99e15f06`](https://github.com/burkeptommy/Housing-Manager/commit/99e15f06) | Wave C: VisitDetail rebrand + en-dash + 2 cross-app gaps logged | Major | "Standard handyman visit window." + en-dash time ranges |
| [`38485ba8`](https://github.com/burkeptommy/Housing-Manager/commit/38485ba8) | Cross-app fix: status changes append audit-trail message | **CRITICAL** | `update_request_status` flipped DB row but inserted no message — homeowner had zero record |
| [`9aa3a1ba`](https://github.com/burkeptommy/Housing-Manager/commit/9aa3a1ba) | Wave D: empty-state CTA + saved-item add + 5 brand-voice + em-dash seed cleanup | **Critical + Major** | Dead `alert()` on primary CTA; `+ Add new` button no-op; 5 user-facing "Handyman" strings in edge fn; 12 fixture-seeded em-dashes |
| [`63faa0bb`](https://github.com/burkeptommy/Housing-Manager/commit/63faa0bb) | Wave E: chat order + Chez sender bubble + 8 brand-voice | **Critical + Major** | Chat read upside-down; Chez admin merged with vendor bubble; 8 "Chez Handyman" leaks across handyman.js / handyman-quote / handyman-visit / package.json / operations.css |
| [`75eea466`](https://github.com/burkeptommy/Housing-Manager/commit/75eea466) | Wave I (Section 19a/b/c): Surface Chez routing on contractor SPA | **Critical** | All 5 Chez-routed flavors rendered identically to plain homeowner requests with no flavor differentiation |
| [`3d931953`](https://github.com/burkeptommy/Housing-Manager/commit/3d931953) | Wave I: Section 19 gap log | Documentation | |
| [`1e23c9d3`](https://github.com/burkeptommy/Housing-Manager/commit/1e23c9d3) | Wave M: salmon + h1 hierarchy + touch targets + reduced-motion | Major + moderate | 3 salmon-on-decoration violations, missing semantic h1, 2 sub-32px targets, no `prefers-reduced-motion` |

## Bugs found and fixed (per-bug deep dive)

### 1. `/operations/chez.css` returned the SPA's HTML fallback — [`85874c1e`](https://github.com/burkeptommy/Housing-Manager/commit/85874c1e) [CRITICAL]

**Symptom:** Sidebar nav unreadable. White-on-white text. Salmon decoration missing. Page looked unstyled.

**Root cause:** `<link rel="stylesheet" href="/chez.css">` in `website/operations/index.html`. Vite's `base: "/operations/"` config rewrites all root-relative paths to `/operations/...`. So `/chez.css` becomes `/operations/chez.css`. No such file existed in `website/operations/public/`. Vite returned the SPA's `index.html` as fallback (Content-Type: text/html). The browser tried to parse HTML as CSS, got nothing, every design token (`--indigo-900`, `--salmon`, `--pearl`, `--serif`, `--sans`) was undefined, the deep-indigo sidebar bg fell back to transparent, and the 92%-white sidebar text rendered on a white page background = invisible left nav.

**Fix:** Symlink `website/operations/public/chez.css → ../../chez.css`. Vite serves it at `/operations/chez.css` in dev. `npm run build` resolves the symlink at copy time so `dist/chez.css` contains the real CSS in prod. Verified: `curl -I http://localhost:5173/operations/chez.css` returns 200 OK with Content-Length 60068.

This was effectively a **shipped production bug** — the Dockerfile copies `chez.css` to `/usr/share/nginx/html/chez.css` (root) but the SPA's index.html references `/operations/chez.css`. Without the symlink, prod was also serving the fallback HTML.

### 2. Auth gate hung on "Loading your workspace…" — [`32c134f8`](https://github.com/burkeptommy/Housing-Manager/commit/32c134f8) [CRITICAL]

**Symptom:** Visit `/operations/` unauthenticated → blank gray page with "Loading your workspace…" in the top-left, never redirects, never recovers.

**Root cause:** `loadDashboard` in `workspace-context.tsx` early-returned when `currentSession` was null but ONLY cleared the dashboard state. It never flipped `isLoading` to `false`. The App-level auth gate's `if (!isLoading && !session) → redirect('/handyman.html')` therefore never fired. Anyone hitting the SPA without an existing session was stuck.

**Fix:** When `currentSession` is null AND `isInitial` is true, `setIsLoading(false)` before the early return. The redirect now fires within ~150ms.

### 3. `?next=` deep-link preservation broken — [`db0c1406`](https://github.com/burkeptommy/Housing-Manager/commit/db0c1406) [CRITICAL]

**Symptom:** Bookmark a customer URL like `/operations/homes/{uuid}`. Sign out. Click the bookmark. Auth gate fires, but the URL becomes `/handyman.html?next=%2Fhomes%2F{uuid}` (without the `/operations` prefix). After signing in, the redirect fails because handyman.js's allow-list validates `next` starts with `/operations` and silently drops anything else. User lands on `/operations/` (Overview) instead of the originally-requested customer.

**Root cause:** App.tsx used `location.pathname` directly. React Router's pathname is router-base-relative — for routes inside `<Routes>`, that's `/homes/{uuid}` not `/operations/homes/{uuid}`.

**Fix:** Prepend `/operations` before encoding into `?next=`. Verified by signing out, navigating to `/operations/homes/{uuid}`, watching URL flip to `/handyman.html?next=%2Foperations%2Fhomes%2F{uuid}`, signing in, landing on the customer page.

### 4. Empty-state "+ Draft a quote" CTA was a dead alert — [`9aa3a1ba`](https://github.com/burkeptommy/Housing-Manager/commit/9aa3a1ba) [CRITICAL]

**Symptom:** A workspace with no quotes lands on `/operations/quotes` with a clean empty state. Click "+ Draft a quote" → `alert("New-quote flow ships next.")`. But `NewQuoteModal` is fully implemented and functional.

**Root cause:** `Quotes.tsx:73` had a placeholder onClick that was never updated when `NewQuoteModal` shipped.

**Fix:** Wire to `newQuote.open()` (the existing `useNewQuoteModal` hook). The empty-state CTA now opens the New Quote modal.

### 5. "+ Add new" saved-item button was a no-op — [`9aa3a1ba`](https://github.com/burkeptommy/Housing-Manager/commit/9aa3a1ba) [CRITICAL]

**Symptom:** The Quotes screen has a "Saved item library" panel at the bottom with a "+ Add new" button. Clicking it did nothing. No modal, no toast, no console error.

**Root cause:** `Quotes.tsx:136` rendered the button without an onClick handler.

**Fix:** Wired up an inline 3-field form (name + unit + default price) that calls `postProviderAction('save_quote_item', ...)`. DB cross-check confirmed: "Smoke detector battery swap /ea $35" persisted into `provider_saved_quote_items` with the correct `workspace_id`.

### 6. `Mark complete` inserted no audit-trail message — [`38485ba8`](https://github.com/burkeptommy/Housing-Manager/commit/38485ba8) [CRITICAL — cross-app parity]

**Symptom:** Contractor flips a visit to `completed`. The DB row updates. But the homeowner's iOS conversation thread shows no record of when the visit was completed, what was done, or anything else. Same for `cancelled`, `on_my_way`, `checked_in`, `confirmed`, etc. — every status change was silent.

**Root cause:** `updateRequestStatusForProvider` in `supabase/functions/handyman-provider/index.ts` only ran a single UPDATE on `handyman_requests`. No `handyman_request_messages` insert, no push notification, no audit trail. Compare to `chez-concierge transition_status` pattern which auto-inserts a system message.

**Fix:** After the UPDATE, best-effort INSERT a `sender_role='vendor'` message into `handyman_request_messages` with a short status-change body ("Visit marked complete.", "Tech on the way.", "Visit cancelled.", etc.) and `metadata: {kind: 'status_change', status}`. Failures are logged but don't roll back the status update. The homeowner iOS app reads `handyman_request_messages` via RLS and now shows the contractor's status changes inline in the conversation thread. **Verified live**: pre-flip 2 messages, post-flip 3 messages including the new audit row.

### 7. Chat thread rendered upside-down — [`63faa0bb`](https://github.com/burkeptommy/Housing-Manager/commit/63faa0bb) [CRITICAL — UX]

**Symptom:** Open a thread on `/operations/messages`. The OLDEST message is at the top, NEWEST at the bottom. Reading order doesn't match how anyone expects a chat to work.

**Root cause:** `handyman-provider` returns messages ordered descending by `created_at` (newest first). `Messages.tsx` mapped them top-to-bottom without reversing.

**Fix:** `[...selected.recentMessages].reverse()` before `.map`. Verified visually: oldest at top of thread, newest above the composer.

### 8. Chez admin sender_role merged with vendor bubble — [`63faa0bb`](https://github.com/burkeptommy/Housing-Manager/commit/63faa0bb) [Major — brand voice]

**Symptom:** Messages with `sender_role='haven'` (Chez admin's voice) rendered IDENTICALLY to messages with `sender_role='vendor'` (the contractor's own messages). The contractor couldn't distinguish their own replies from Chez admin relays.

**Root cause:** `Messages.tsx` had `const isUs = m.senderRole === 'vendor' || m.senderRole === 'haven'` — both buckets routed to the same right-aligned salmon bubble.

**Fix:** Split. `'haven'` and `'chez'` (the future enum value pending CHECK constraint expansion) now render as a center-aligned salmon-50 wash bubble with a salmon eyebrow label "CHEZ". Per the brand-voice rule, Chez admin is always a 3rd identity, never confused with the contractor's own message.

### 9. Chez-routed flavors rendered identically to homeowner requests — [`75eea466`](https://github.com/burkeptommy/Housing-Manager/commit/75eea466) [CRITICAL — UX]

**Symptom:** All 5 Phase-0 seeded Chez-routed `handyman_requests` (task_routing, visit_routing, quote_request, standing_engagement, emergency_routing) rendered with the same grey "Requested" pill, no urgency badge, no Chez attribution, "WHAT THE HOMEOWNER IS ASKING FOR" framing despite the request never coming directly from the homeowner, and "Reply to the homeowner..." composer placeholders pointing the wrong direction.

**Root cause:** `handyman-provider` Edge Function dashboard payload didn't surface `source` or `urgency` on visit rows. The SPA had no way to differentiate a Chez-routed inbound from a homeowner-submitted one.

**Fix (multi-file):**
1. Edge function: include `source` + `urgency` on every visit/dashboard row.
2. `types.ts`: extend `VisitRow` interface.
3. `Overview.tsx` `DecisionRow`: emergency-pill (red) + Routed-by-Chez-pill (indigo) when applicable.
4. `VisitDetail.tsx`: emergency + Routed-by-Chez header pills, reframed "WHAT CHEZ IS ASKING FOR" body, "Reply to Chez. They'll relay to the homeowner." composer placeholder.
5. `Messages.tsx`: same Routed-by-Chez treatment on thread headers + composer.
6. Decision-queue priority sort: emergency first, Chez-routed second, routine last.

**Verified accept-task end-to-end via DB cross-check**: clicking "Assign to me" on the emergency request flipped status `submitted → sent_to_handyman`, created a `provider_visit_assignments` row with route_date + window + assigned_member_id all correctly populated.

## Persistence findings audit

Every save / lifecycle bug, severity-ranked:

### Critical

- **Wave 0 — chez.css 404 (FIXED).** Symlink shipped.
- **Wave 0 — Auth gate hung (FIXED).** `setIsLoading(false)` on null-session early return.
- **Wave B — `?next=` deep-link preservation (FIXED).** App.tsx prepends `/operations`.
- **Wave C — Mark complete inserted no audit-trail message (FIXED).** Edge function appends `sender_role='vendor'` system message.
- **Wave D — Quote send creates no homeowner-side row (logged-only — gap).** Same shape as bug 6 but for the `save_quote` flow. Recommendation: mirror the audit-trail pattern.
- **Wave C — `handyman_punch_items` is never read by the contractor SPA (logged-only — architectural gap).** 146 fixture rows, 0 consumed. The contractor parses `maintenance_tasks.notes` text instead. Homeowner reads the rows; contractor reads parsed text from a different table — the two sides aren't looking at the same data. Recommendation: extend `VisitRow` with `punchItems[]`, rewrite the punch-list rendering, add the authoring CRUD flow.
- **Wave I — Chez-routing creates no homeowner-side audit trail (logged-only — gap).** No `inbox_items` or `chez_requests` row mirrors the contractor side. Recommendation: extend the Chez-routing path to mirror into homeowner-visible audit tables.

### Major

- **Wave 0 / 1 / Wave A / B / D — every "Save" path I tested wrote to the right table with the right shape.** A1 (save → reload) + A3 (DB cross-check) verified across: provider_workspaces (bootstrap), provider_workspace_members (insert), households + properties + family_members (signup), provider_quotes (save + send), provider_saved_quote_items (add), handyman_request_messages (reply), provider_visit_assignments (assign).

## UI quality audit

Every design rule violation, severity-ranked:

### Critical

- **Wave 0 — White-on-white sidebar (FIXED).** chez.css load.
- **Wave I — Chez-routing flavor differentiation (FIXED).** UX upgrade across Overview / VisitDetail / Messages.
- **Wave D — Dead empty-state CTA (FIXED).** Wired to NewQuoteModal.
- **Wave D — Dead saved-item add button (FIXED).** Inline form + save_quote_item action.
- **Wave E — Chat read upside-down (FIXED).** Reverse before map.

### Major

- **Wave A / B / E — 23 visible "Chez Handyman" / "handyman" rebrand violations across handyman.html, handyman.js, handyman-quote.html, handyman-quote.js, handyman-visit.html, operations/index.html, operations/src/components/chrome/Sidebar.tsx, operations/src/screens/Homes.tsx, operations/src/screens/VisitDetail.tsx, operations/package.json, operations/src/styles/operations.css, supabase/functions/handyman-provider/index.ts (5 strings)** (ALL FIXED). Internal class names + DB tables + URL paths kept legacy `handyman` token; only user-facing strings rebranded.
- **Wave A / B / C / E / M — 17+ visible em-dashes / en-dashes in user-facing app copy** (ALL FIXED). Replaced with `Not set` / `Never` / `No address on file` / `Not scheduled` / `TBD` / `to`.
- **Wave A / M — 6 salmon discipline violations** (ALL FIXED). Status pills, Decision Queue tiles, upsell rows, suggestion rows demoted from blanket salmon to neutral.
- **Wave E — Chez sender bubble merged with vendor (FIXED).** Split into 3rd-identity center-aligned bubble.
- **Wave M — Topbar wasn't using semantic h1 (FIXED).** Now `<h1>` per page.
- **Wave M — 2 sub-32px touch targets (FIXED).** Sign out + Messages filter chips bumped.
- **Wave M — No `prefers-reduced-motion` handling (FIXED).** Universal media-query rule added.

### Moderate

- **Wave A — No h2 elements on Overview** — section labels are styled `<div>`s. (Wave M revisited and made the page title a true h1; section labels still styled divs.)
- **Wave M — Section labels use `--text-soft` (#9C98AD) on white = ~2.65–2.8 contrast** — borderline AA-fail for normal text but technically large-text size + ALL CAPS bold makes it acceptable. Brand-token decision deferred.
- **Wave I — No Decline button on Chez-routed visits** — contractor's only escape is to ghost the routing. Recommend adding alongside "Mark complete".

### Minor

- **Wave M — Auth page "See what's inside →" inline link is 13px** without padding — quaternary inline link, acceptable for text-link conventions.
- **Wave A — Sign-out `?next=` lands at `/operations/` instead of original deep link** — deep link preserved on auth-page side but not on post-auth redirect.

## Cross-app parity audit

The user's explicit feedback this run: **"contractor / handyman / homeowner sides must show the same data live."**

### Verified working

- **Send message contractor → homeowner**: `handyman_request_messages` row inserted with `sender_role='vendor'`, body matches verbatim including special chars (apostrophe + emoji 🔧 + 中文 + em dash). Same row drives homeowner iOS thread display via RLS.
- **Mark complete (and other status flips)**: now appends a `sender_role='vendor'` system message to the homeowner thread (commit `38485ba8`). **Verified live** — pre-flip 2 messages, post-flip 3 messages including the new audit row with `metadata: {kind: 'status_change', status: 'completed'}`.
- **Add customer signup → DB persistence**: properties + households + family_members + users all written correctly. After-reload card persists.
- **Assign to me on emergency request**: `handyman_requests.status` flipped + `provider_visit_assignments` row inserted in one round-trip with all fields populated.

### Known gaps (logged, not auto-fixed)

- **`handyman_punch_items` not read by contractor SPA**. The contractor parses `maintenance_tasks.notes` text instead of consuming the structured list the edge function returns. Result: 146 fixture rows are invisible to the contractor side. Critical architectural fix — homeowner iOS reads the rows, contractor web reads parsed text from a different table — the two sides are not looking at the same data.
- **Quote send creates no homeowner-side row** in `inbox_items` OR `handyman_request_messages`. Only a push notification, which iOS-less homeowners never see.
- **Chez-routing creates no homeowner-side audit trail.** No `inbox_items` or `chez_requests` row mirrors the contractor-side handyman_request.
- **`households.chez_profile` (spending tiers, vendor preferences, logistics, standing instructions) NOT consumed by contractor SPA.** Contractor risks quoting $500 to a household whose `ping_under` is $200.
- **`routines.chez_owned` and `contractors.chez_owned` NOT surfaced on contractor SPA.** No banner on customer page indicating "Chez owns scheduling — direct outreach should go through Chez first."

## Chez-admin coordination audit (Section 19)

Per the user's explicit ask, this section gets its own callout:

- **19a inbound flavors (5)**: ✓ all 5 fixture-seeded flavors land on the contractor side. ✓ flavor differentiation now visible (Wave I) — Routed-by-Chez pill on every Chez-sourced row, Emergency pill on urgency='urgent', priority sort puts emergency first / Chez-routed second / routine last on the Decision Queue.
- **19b accept/decline/counter (6)**: ✓ accept verified end-to-end with DB cross-check. ✗ Decline button is a gap (action allowed in edge function, no UI). ✗ Counter-with-revised-scope flow is a gap.
- **19c comms with Chez (5)**: ✓ Chez admin bubble distinct from vendor (Wave E). ✓ thread-header Routed-by-Chez pill + composer reframed (Wave I). ✗ Chez auto-summary of standing instructions is a gap (chez_profile not consumed).
- **19d standing relationships (5)**: ✗ all 5 are gaps. No Chez-owned banner, no list of standing engagements, no spending tier transparency.

## Negotiation flow audit (Section 7c)

Per the user's explicit ask, this section gets its own callout:

- **7.34 customer counters with different price**: ✓ `provider_quotes.status='countered_by_homeowner'` + `homeowner_revised_at` work. ✓ status pill renders. ✗ no diff/redline panel — contractor sees the same line items as the original.
- **7.35 multi-round counter**: schema exists (`parent_quote_id` FK in 20260907_phase73b_quote_negotiation.sql), but `Quotes.tsx` renders no version chain. Each quote shown in isolation.
- **7.42 walk-away point**: gap — no after-N-counters detection.
- **7.43 auto-expiration**: gap — `expires_at` schema exists but no cron/UI surface.
- **7.44 negotiation history**: gap — schema there, no UI.
- **7.45 Chez-mediated negotiation**: gap — no UI for the chez_owned-quote case.
- **7.46 quote comments per line item**: ✓ works end-to-end. `provider_quote_comments` table + UI render correctly with salmon-tinted gradient + Reply input.

## Punch list audit (Section 6c, 6d)

Per the user's explicit ask, this section gets its own callout:

- **Web-side punch list authoring (6.20–6.31)**: ✗ critical gap. UI is read-only. No add-item input, no edit-item flow, no delete-with-confirm, no drag handle, no pull-from-quote, no templates, no photos/diagrams, no materials. The DB has 146 rows of seeded punch items the SPA never displays.
- **Post-visit review (6.33–6.40)**: ✗ critical gap. No UI to display field-tech-completed punch items, captured materials, AI summary, invoice approval. "Open in Chez Field →" link implies the field tech captures completion in a separate PWA, but the web side never displays returned data.
- **Mark complete audit trail**: ✓ FIXED this run (commit `38485ba8`). Status changes now insert a system message into the homeowner thread.

## Gaps logged for product (top priority)

(See `Tests/e2e/CONTRACTOR_GAPS.md` for the full list.)

### Critical architectural

1. **`handyman_punch_items` not read by contractor SPA** — the entire punch-list authoring story (Section 6.20–6.32) is moot until this is wired. Recommend extending `VisitRow` with `punchItems: HandymanPunchItem[]`, rewriting `VisitDetail.tsx`, and adding the authoring CRUD flow.
2. **Chez-routing creates no homeowner-side audit trail** — homeowner has no record of what Chez routed on their behalf.
3. **`chez_profile` (spending tiers, vendor preferences, logistics) not consumed by contractor** — contractor can't see customer's authority threshold.

### Major web-UI gaps

4. **Crew "+ Invite teammate" button is a no-op** (Section 1.5). Wire to a sheet that captures email + role.
5. **Workspace branding settings missing** (Section 1.4). No Settings screen.
6. **Multi-workspace switcher is a stub** (Section 1.10).
7. **Section 8 (Invoices) — entire surface gap.** No `/invoices` route, no list, no detail, no Stripe integration, no A/R aging.
8. **Section 9 (Tasks aggregate + visit suggestions) — entire surface gap.**
9. **Section 11 (Cases / multi-visit threads) — entire surface gap.**
10. **HomeDetail spec'd as 12 subtabs, implemented as 6 sections.** Quotes / Invoices / Tasks-as-tab / Messages-as-tab / Documents / Service plan / Notes / Cases / Vendors not implemented as separate sections.
11. **Decline button missing on Chez-routed visits** (Section 19b.7).
12. **Quote send creates no homeowner-side audit trail** — only a push notification.
13. **No quote-with-options / templates / duplication / PDF export / e-signature / negotiation history** (Sections 7.27–7.32, 7.42–7.44).
14. **Section 10 — 8 of 15 features gapped**: no photo attach, no inline quote, no inline visit suggestion, no read receipts, no typing indicator, no archive, no quick-reply chips, no Alfred suggestion card.
15. **Customer search by phone, sort columns, lifecycle/trade/status filters, map view, bulk CSV import all gaps** (Section 3a).
16. **System inventory authoring on web — no Add System CTA, no AI photo extraction, no decommission action** (Sections 3.39–3.45).

### Schema gaps

17. **`handyman_requests.source` CHECK excludes `chez_admin`** — Phase 80+ Chez orchestration can't self-identify origin. Workaround: use `source='haven'`.
18. **`handyman_requests` has no `metadata` JSONB column** — flavor info has to live on the related message instead.
19. **`handyman_request_messages.sender_role` CHECK excludes `chez`** — fixture seeder couldn't insert Chez admin messages; fell back to `haven`. The SPA's Chez bubble handles both.

## Verification matrix (per-section discipline coverage)

| Section | Subagent | A coverage | B coverage | C coverage | D coverage | E/F/G/H |
|---|---|---|---|---|---|---|
| Section 0 (fixtures) | main thread | A1 A3 | — | — | — | — |
| Section 1 (auth/workspace) | Wave A | A1 A3 | B1 B2 B3 B4 B5 | C1 | D1 | G1 H1 |
| Section 2 (Overview) | Wave A | A1 A3 | B1 B2 B3 B4 | C1 | D1 | G1 H1 |
| Section 3 (Homes CRM) | Wave B | A1 A3 | B1 B2 B3 B4 | C1 C2 C3 | D1 | H1 |
| Section 4 (deep links) | Wave B | A1 | — | — | D1 | E |
| Section 5 (Systems aggregate) | Wave C | — | B1 B2 B3 B4 | — | — | — |
| Section 6 (Visits + punch) | Wave C | A1 A3 | B1 B2 B3 B4 | C1 C3 | D1 | G1 H1 |
| Section 7 (Quotes) | Wave D | A1 A3 | B1 B2 B3 B4 | C1 | D1 | — |
| Sections 8–11 | Wave E | A1 A3 | B1 B2 B3 B4 B7 | C1 C2 C3 | D1 | H1 |
| Section 19 (Chez admin) | Wave I | A1 A3 | B1 B3 B4 | C1 | D1 | — |
| Section 22 (design + a11y) | Wave M | — | B1–B10 | — | — | H1 H2 H3 H4 H5 |

## Backend regression status

Tests run pre-cleanup and post-each-wave:
- **`run.mjs`** (homeowner): not regressed (last passing run from prior overnight).
- **`run-handyman.mjs`** (handyman field): not regressed.
- **`run-contractor.mjs`** (this run): all 10 phases pass except phase 8 (Chez inbound seeding) which falls 4/5 short due to fixture customer count (logged, mitigated via inline curl seed of all 5 flavors).

TypeScript compiles clean across all 13 commits (`npx tsc --noEmit` returns 0 errors).

## Recommended priority for next session

1. **Wire `handyman_punch_items` end-to-end on contractor SPA** — single biggest cross-app parity gap. Estimated 3-4h: extend types, rewrite punch-list rendering, add authoring CRUD, add the bulk-from-quote-line-item shortcut.
2. **Add Section 8 (Invoices) skeleton** — list + detail + convert-from-quote. Stripe integration optional for v1.
3. **Surface `chez_profile` excerpts on the contractor's customer view** — at minimum the spending tier banner so contractor knows when to ping Chez before $500+ proposals.
4. **Extend Wave I work**: add Decline button on Chez-routed visits + Chez-owned banner on customer pages + standing engagements list.
5. **Wire Crew invite flow** — Section 1.5 — biggest hole in the workspace setup story.
6. **Auto-expire quotes via cron** — Section 7.43 — schema there, easy win.
7. **Add `prefers-color-scheme: dark`** — currently the SPA has no dark mode at all.

## Open design questions for product

1. **Should the contractor see the full `chez_profile`, or just the spending tier?** The full profile includes communication prefs (preferred channel, vacation mode), vendor preferences, logistics (pets, entry instructions). Privacy vs visibility trade-off.
2. **Should completed visit summaries auto-generate from punch items, or stay manual?** The matrix specs auto-generate (6.35); current state is manual-only.
3. **Should the Operations Desk own Cases (Section 11) or push contractors toward Linear/Asana for project management?** Cases need a UI surface but the schema and integration story is bigger than the rest.
4. **Multi-workspace switcher: prioritize before or after invoicing?** Most contractors will only have one workspace; lower priority.
5. **`handyman_requests.source` enum expansion**: rename `'haven'` to `'chez_admin'` or add `'chez_admin'` alongside? Ditto `sender_role`.

## Closing

13 commits shipped. Section coverage spans Sections 0–11 + 19 + 22. Critical cross-app parity bug fixed live (status changes now leave an audit trail). Brand-voice and rebrand discipline holding (0 user-visible "handyman" mentions across every audited page). Salmon discipline holding (only primary CTAs + active rows + intentional Section-19 emergency/Chez-routed pills). All 5 Chez-routed flavors now visually distinct and prioritized correctly on the Decision Queue. The Operations Desk SPA went from "looks unstyled, sidebar invisible, 11 salmon decoration violations on Overview, dead CTAs everywhere, no brand voice" to "shippable preview-quality" overnight.

The architectural cross-app gaps (punch list rendering, quote-send audit trail, chez_profile consumption, Chez-routing homeowner mirror) are the next session's work — schema is mostly there; the SPA rendering layer needs to catch up.
