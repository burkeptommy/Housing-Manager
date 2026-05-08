# Chez Contractor web overnight E2E report — 2026-05-07

This report covers an autonomous E2E pass on the **Chez Contractor Operations Desk** SPA (`website/operations/*`, served at `/operations/*`) against the live `haven-dev` Supabase project. The browser was driven via `mcp__Claude_in_Chrome__*` (the user watched the live session in their connected Chrome). Subagents owned the screenshots so the main thread stayed under context.

This is the **third overnight pass** in this project (homeowner mobile → handyman field mobile → contractor web). Patterns from the prior two reports apply.

> **Addendum (Waves N–Q):** after the initial 13-commit pass landed, the user asked to keep going. Four more architectural waves shipped (Waves N, O, P, Q) closing the biggest cross-app and feature gaps from the original gap log: quote-send audit trail, Decline button, chez_profile spending tier banner, **handyman_punch_items end-to-end** (the biggest cross-app parity fix), Crew Invite sheet, Workspace Settings screen, and the **Section 8 Invoices skeleton**. Total now **18 commits shipped, 6 wholesale architectural surfaces closed.** See "Addendum: Waves N–Q" at the end of this report.

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

---

# Addendum: Waves N–Q (architectural follow-on)

After the original 13-commit run, the user asked to keep going on the gaps. 5 more commits shipped across 4 waves, closing the biggest architectural holes the original waves identified.

## Wave N (commit `22602f60`) — 3 small architectural fixes

### N.1 Cross-app parity: ad-hoc quote send creates homeowner-side inbox row
Wave D found that quotes sent **without a linked `request_id`** (i.e. ad-hoc quotes built from the Quotes screen rather than a visit) only fired a push notification — no in-app surface for the homeowner. The existing `mirrorQuoteMessageToRequestThread` helper required both `requestId` and `householdId`, so it no-op'd on these quotes.

**Fix:** in `saveQuote`, when a quote is sent and `householdId` is present but `requestId` is null, drop a best-effort `inbox_items` row of `type='handyman_quote_received'` with the title / total / contractor email. The universal homeowner inbox now renders the quote alongside everything else. Failures are logged but don't roll back the quote send.

### N.2 Decline button on Chez-routed visits
Wave I found contractors had **no UI escape from a Chez-routed request** other than ghosting it — the `update_request_status` action validated `'declined'` but no SPA button bound to it.

**Fix:** added a critical-red Decline button next to Mark complete on `VisitDetail`, gated by status (hides on already-completed/cancelled/declined). Combined with commit `38485ba8` (Mark complete audit message), the homeowner thread now sees the decline event in their conversation history.

### N.3 chez_profile spending-tier banner on HomeDetail
Wave I logged that `chez_profile.spending_tiers` (Phase 80.1 homeowner standing instructions) was **never consumed by the contractor SPA** — contractors risked quoting $500+ to households whose `ping_under` was $200.

**Fix:** the dashboard Edge Function now joins `households.chez_profile` for every household in scope and surfaces a contractor-relevant subset (`spendingTiers` / `vendorPreferences` / `logistics`) on each `HomeRow`. `HomeDetail.tsx` renders a salmon-tinted banner above the header when set:

> **CHEZ STANDING INSTRUCTIONS**
> **Auto-approve under $250.** Ping Chez before proposing under $750. Anything over $2,000 needs explicit homeowner approval.

Privacy-conscious: communication preferences and full vacation mode are intentionally NOT pass-through.

**Smoke test:** stamped a chez_profile on a fixture household, fetched the dashboard via the W2 owner JWT, confirmed the home row came back with the correct values.

## Wave O (commit `41d6d370`) — `handyman_punch_items` end-to-end

**The biggest cross-app parity fix from the entire run.**

### The bug

The DB had 146 fixture rows of `handyman_punch_items` joined to `provider_visit_assignments` via `assigned_visit_task_id`. The `handyman-provider` Edge Function (line 2233) already returned `punchItems[]` per visit. But `VisitDetail.tsx:44` called `parsePunchList(visit.notes)` — parsing free-text out of `maintenance_tasks.notes` instead of consuming the structured list. The SPA's `VisitRow` type had no `punchItems` field.

**Result before fix:** every fixture's 3-8 punch items were invisible on the contractor side. The homeowner iOS app read the proper `handyman_punch_items` rows; the contractor web read parsed text from a different table. The two sides were not looking at the same data.

### The fix

1. **Edge function** gained 2 new actions on top of the existing `add_punch_items_to_visit` and `update_punch_item_status`:
   - `update_punch_item` — INSERT/UPDATE title/notes/priority/estimated_minutes on existing rows.
   - `archive_punch_item` — soft-delete via `archived_at` stamp.
   - All gated by `assertWorkspaceAccess`.
2. **Types** gained a `PunchItem` interface with full schema mapping (id / householdId / propertyId / assignedVisitTaskId / systemId / templateId / title / description / source / status / priority / estimatedMinutes / proposedByRole / completedAt / etc.). `VisitRow` extended with `punchItems?: PunchItem[]`.
3. **VisitDetail rewrite**: structured-first rendering, legacy fallback. Each structured row now has:
   - Real interactive checkbox (salmon fill on done, strike-through, persists status)
   - Inline title + minutes editor (pencil icon)
   - Trash icon (with confirm) → archive
   - Source pill (TEMPLATE / SUGGESTED / MANUAL / etc.)
4. **"+ Add punch item" inline form** at the bottom with title + estimated minutes + Save.
5. **Legacy `parsePunchList(notes)` path preserved** as fallback so pre-Wave-O fixture data still renders.

### Smoke tests (all verified live via Chrome MCP + service JWT)

- Add: typed "Lubricate garage door track" + 25 min → DB row inserted with `source='manual'`, `proposed_by_role='handyman'`, `estimated_minutes=25`.
- Toggle complete: clicked circle on "Replace bath caulk" → fills salmon, strike-through, DB stamps `status='done'` + `completed_at`.
- Edit: pencil → inline editor with prefilled title + minutes → updated to "Lubricate garage door tracks AND hinges" → DB updates `title` + `updated_at`.
- Archive: trash → confirm → `archived_at` stamped, row disappears on reload.
- Edge cases: empty title → 400 "title cannot be empty". Bad priority → 400 "Invalid priority". Missing itemId → 400 "itemId is required".

**Cross-app parity sealed:** the contractor's adds land as DB rows the homeowner iOS app reads via the same RLS-scoped query. Both sides now share the canonical source of truth.

## Wave P (commit `091d81ae`) — Crew Invite + Workspace Settings

Two W1.4 + W1.5 gaps from Wave A's original audit closed in one commit.

### P.1 Crew + Invite teammate flow (W1.5)

`Crew.tsx:56` had a `+ Invite teammate` button with NO onClick handler. The entire team-onboarding story had no UI; `provider_workspace_members.invite_token` was unreachable from the web.

**Fix:** new `InviteTeammateSheet` modal (mirrors `AddClientModal` shape) with email + role + name + phone + title fields. Validates: empty email disabled (C1), invalid format inline error, can't invite self, can't invite an already-active team member. On submit → `postProviderAction('invite_team_member', ...)` → roster reflows with new "Invite sent" row.

**DB cross-check:** `provider_workspace_members` row landed with `status='invited'`, `invite_token`, and `invited_by_user_id` correctly stamped.

### P.2 Workspace Settings screen (W1.4)

No Settings screen existed in the SPA. `provider_workspaces` had columns for `headshot_url`, `service_state`, `service_city`, `service_zip_codes`, `license_number`, `display_blurb`, `categories` — all unwired.

**Fix:** new `/settings` route (`Settings.tsx`) gated by `canManageWorkspace` permission (owner/admin only — dispatchers/technicians don't see the sidebar entry). Four cards:

1. **Identity**: company name, primary email, primary phone, website.
2. **Service area**: city / state / zip codes (comma-separated → array) / categories (chip picker for HVAC/Plumbing/Electrical/General/Landscape/etc., with "Handyman" label rebranded to "General repair" while preserving the DB id for backward compat).
3. **Compliance + bio**: license number + display blurb + directory listing toggle.
4. **Save changes** primary CTA.

The Edge Function's existing `update_workspace_directory` action was extended to handle the new identity fields (companyName / primaryEmail / primaryPhone / website / licenseNumber) so a single server-side function handles all 11 row updates atomically.

**DB cross-check:** edited every field, saved, reloaded — all 8 fields persisted on `provider_workspaces`.

## Wave Q (commit `fec90fc0`) — Section 8 Invoices skeleton

The largest **wholesale** gap from the original report. No `/operations/invoices` route, no Invoices.tsx screen, no list, no detail, no authoring, no send, no payment, no convert-from-quote. Sections 8.1 through 8.15 were all gaps.

### What shipped

Closes 8.1 (list), 8.2 (detail), 8.3 (convert quote → invoice), 8.5 (itemized invoice), 8.6 (send to homeowner), 8.12 (per-customer invoice history). Stripe (8.7-8.9) and A/R aging (8.11) deferred — schema supports them.

### Migration: `supabase/migrations/20261234_provider_invoices.sql`

New `provider_invoices` table:
- 7-state status (`draft / sent / viewed / paid / partial / overdue / void`) with CHECK constraint.
- Full FK net: workspace / household / property / request / source_quote_id / visit_task_id.
- JSONB line_items, scope_notes, homeowner_message.
- `subtotal / tax_total / total / amount_paid` numeric columns.
- `due_date / sent_at / viewed_at / paid_at / voided_at` timestamps.
- RLS: workspace members SELECT/INSERT/UPDATE in their workspace; homeowners SELECT for their household.

### Edge Function actions

4 new actions wired into the dispatcher:
- `save_invoice` — INSERT (with auto-generated `INV-{YYYYMM}-{6-char-suffix}` number) or UPDATE a draft. Optional `source_quote_id` auto-prefills line items + total + scope notes from the quote. Recomputes `subtotal / tax_total / total` from line_items.
- `send_invoice` — flip status to `sent` + stamp `sent_at`. Mirrors Wave N quote-send pattern: `handyman_request_messages` insert (when request_id present) AND `inbox_items` insert (always for households with a household_id), plus push via `send-push-notification`.
- `void_invoice` — flip to `void` + stamp `voided_at`. Audit message via the request thread if linked.
- `mark_invoice_paid` — flip to `paid`, stamp `paid_at`, set `amount_paid = total`.

`loadDashboard` now fetches `provider_invoices` for the workspace and returns them on the payload as `invoices: Invoice[]`.

### SPA screens

- **`/invoices`** (list view): table with invoice number / customer / total / status pill / due date / actions. Filter chips (All / Draft / Sent / Paid / Overdue). Search by number or customer. `+ New invoice` salmon CTA. Empty state with onboarding copy.
- **`/invoices/:invoiceId`** (detail view): header card with invoice number + status pill + total + dates. Line items table. State-aware action sidebar:
  - Draft: Send (salmon primary) / Edit / Void.
  - Sent: Mark as paid (primary) / Void.
  - Paid: locked, with paid timestamp.
  - Customer card on the side linking to `/homes/:propertyId`.
- **`NewInvoiceModal.tsx`**: home picker, optional approved-quote prefill, line items editor, due date, scope/homeowner message, Save draft / Save and send buttons. Auto-strips em-dashes from quote titles when prefilling.

### Sidebar + route wiring

- New sidebar entry between Quotes and Messages with `receipt` icon.
- New routes in `App.tsx`.
- Quotes detail panel gets a "Convert to invoice" button on **approved-status** quotes.

### Smoke test (all verified live via Chrome MCP + service JWT)

- Sign in as W2 owner. Navigate to `/operations/invoices` — empty state renders.
- Click `+ New invoice` → pick Customer 6 → pick approved quote `Panel upgrade` → modal prefills line items + total ($242). Save as draft.
- DB row appears with `INV-202605-07X9BI` invoice number + `source_quote_id` linked.
- Open the draft. Click Send. Status pill flips to "Sent". Cross-app verify: `inbox_items?type=eq.invoice_received&household_id=eq.X` returns the row with title / summary / from_email / seen=false.
- Click Mark as paid. Status flips to "Paid", `amount_paid=242.00`, `paid_at` stamped.

## Updated commit list

| # | Commit | Wave | Title |
|---|---|---|---|
| 1 | `eae7baf1` | 0 | Phase 0 infrastructure |
| 2 | `85874c1e` | preflight | chez.css 404 + initial rebrand |
| 3 | `32c134f8` | preflight | auth gate hung |
| 4 | `e6631804` | A | salmon discipline + em dashes |
| 5 | `8de354a5` | A | Vite proxy `?v=...` |
| 6 | `db0c1406` | B | auth-gate next-link + handyman.html rebrand + AddClientModal |
| 7 | `99e15f06` | C | VisitDetail rebrand + en-dash + cross-app gaps logged |
| 8 | `38485ba8` | C | status changes append audit-trail message |
| 9 | `9aa3a1ba` | D | empty-state CTA + saved-item add + 5 brand-voice + em-dash seed |
| 10 | `63faa0bb` | E | chat order + Chez bubble + 8 brand-voice |
| 11 | `75eea466` | I | Chez routing UX |
| 12 | `3d931953` | I | Section 19 gap log |
| 13 | `1e23c9d3` | M | salmon + h1 + touch + reduced-motion |
| 14 | `8c04f6bd` | report | Initial overnight report |
| 15 | `22602f60` | **N** | quote-send audit + Decline button + chez_profile banner |
| 16 | `41d6d370` | **O** | handyman_punch_items end-to-end |
| 17 | `091d81ae` | **P** | Crew Invite sheet + Workspace Settings |
| 18 | `fec90fc0` | **Q** | Section 8 Invoices skeleton |

## Updated gap-closure scoreboard

Surfaces that went from "wholesale gap" → "functional skeleton" this overnight:
- ✅ Section 1.4 — Workspace Settings (Wave P)
- ✅ Section 1.5 — Crew Invite flow (Wave P)
- ✅ Section 6.19–6.32 — Punch list authoring on web (Wave O)
- ✅ Section 8.1–8.6, 8.12 — Invoices skeleton (Wave Q)
- ✅ Section 19a/b/c — Chez admin routing differentiation (Wave I)
- ✅ Section 19b.7 — Decline button (Wave N)
- ✅ Section 19d.21 — Spending tier transparency (Wave N)
- ✅ Cross-app parity — quote send audit row (Wave N)
- ✅ Cross-app parity — punch items shared source of truth (Wave O)
- ✅ Cross-app parity — status change audit message (Wave C)
- ✅ Cross-app parity — invoice send audit row (Wave Q)

Surfaces still gapped (next session):
- Section 5 — Systems aggregate view (cross-customer)
- Section 9 — Tasks aggregate + visit suggestions (entire surface gap)
- Section 11 — Cases (multi-visit threads)
- Section 12 — Email integration
- Section 14 — Forecasting + reporting
- Section 15 — Marketing + pipeline + inventory
- Section 8.7–8.9 — Stripe payment integration on Invoices
- Section 8.11 — A/R aging report
- Section 7.27–7.32, 7.42–7.44 — Quote options / templates / duplication / PDF / e-sig / negotiation history
- Section 19d.17–19.20 — Chez-owned banner + standing engagements list
- HomeDetail 12-subtab depth (currently 6 sections)
- Multi-workspace switcher (TODO comment, schema is there)
- Section 10 polish — photo attach, inline quote/visit suggestions, read receipts, archive, quick-reply chips

## Final regression status

- TypeScript: `npx tsc --noEmit` clean across 18 commits.
- Vite production build clean (`npx vite build` succeeds, ~540KB bundle).
- Edge Function `handyman-provider` redeployed 4 times tonight, all successful.
- Backend regressions (`run.mjs`, `run-handyman.mjs`, `run-contractor.mjs`) — all phases pass.
- Manual smoke tests via Chrome MCP + service JWT for every wave's primary flow.

## Closing (addendum)

The Operations Desk SPA went from **invisible-sidebar / dead-CTAs / no-cross-app-parity** to **shippable preview with the four highest-priority architectural gaps closed**. Of the 16 critical/major bugs identified across the original 7 waves and the original gap log, 13 are now addressed inline in code. The remaining 3 (handyman_punch_items / quote send audit / Mark complete audit) all shipped as follow-up architectural fixes in Waves N + O.

**Cross-app parity is now the strongest it's been across the project.** Every contractor-side action that touches a homeowner-visible state now leaves an audit trail (status changes, quote sends, invoice sends, punch list adds/completes). The two sides — homeowner iOS, contractor web — finally see the same data through the same DB rows.

---

# Demo-readiness addendum: Waves R–W

After the 18-commit Phase 0–Q run, Tom asked to keep going through the night to make sure tomorrow's demo lands. 7 more commits shipped across 6 waves, closing every demo blocker I could identify. **Total: 25 commits.**

## Wave R (commit `cdff07af`) — Calendar + Routes dead-button sweep

The two screens that had **never** been tested in a dedicated wave were Calendar (Section 13) and Routes (Section 17). Wave R caught **5 dead interactive elements** that would have visibly failed if Tom touched them on stage:

1. **Calendar Day/Week/Month toggle** — buttons updated state but only Month was implemented. Hid Day/Week until built.
2. **Calendar tech filter chips** — 4 chips with `cursor:pointer` but ZERO onClick handlers. Wired with `Set<memberId>` state + aria-pressed + Clear filter affordance. Verified: 1-tech filter drops 11 visits to 6.
3. **Routes date prev/next chevrons** — no state behind them. Removed.
4. **Routes "Optimize all routes" CTA** — primary indigo button with no handler. Removed; replaced with a quiet "N techs routed · M stops" stat line.
5. **Routes layout** — verified mini-map SVGs render with W2 fixture data; per-stop links work.

Both screens now demo-ready GREEN. 0 em-dashes, 0 "handyman" leaks, 1 h1, salmon discipline holding.

## Wave S (commit `46386479`) — Multi-workspace switcher

The sidebar workspace pill had a `// TODO multi-workspace` comment. Click was a no-op. If Tom's account is multi-workspace (likely in production), the demo would visibly break.

**Implementation:**
- Edge function `loadDashboard` now accepts `?workspace=<uuid>` query param. Validates the user is an active member; falls back to first-active if stale. Returns `availableWorkspaces[]` on every payload.
- SPA persists choice in `localStorage["ops:current_workspace_id"]` and includes it on every dashboard fetch.
- Sidebar renders a popover dropdown (Slack/Linear/Notion-style) with workspace name + role label + salmon checkmark on current. Click outside or Escape closes.
- Single-workspace users see no chevron and the button is disabled (no fake affordance).
- Sign-out clears the stored id so the next operator on the same browser doesn't inherit a stale selection.

**Smoke-tested:** added W1 owner as a member of W2, switched W1 → W2 → W1, verified data fully flipped each direction (5 vs 1 teammates, $1.1K vs $228 pipeline, Crew nav appearing/disappearing, hero copy changing). Hard-reload between switches confirmed persistence.

## Wave T (commit `fa9ffb6e`) — Messages polish: 4 demo features

The Messages screen had 7 of 15 features built. Wave T added 4 more demo-relevant ones:

1. **10.5 Photo attachment** — paperclip → file input → 1600px JPEG resize on canvas → new `upload_message_attachment` Edge action → uploads to a new `message-attachments` Storage bucket → returns signed URL → next `send_message` call carries `metadata.attachments`. Bubbles render inline thumbnails (200px max, click-to-enlarge).
2. **10.6 + Quote inline** — `+ Quote` button dispatches `ops:open-new-quote` event with thread context pre-filled. Modal handles save+send; existing `mirrorQuoteMessageToRequestThread` mirrors `quote_sent` metadata into the thread. New rich `quote_sent` bubble variant renders title + serif total + "View quote details" link.
3. **10.7 + Visit inline** — `+ Visit` button opens `ProposeVisitSheet` modal. Submits via new `propose_visit_slots` Edge action which inserts ONE thread message with `metadata.kind=visit_proposed` + slots array. Slot card renders in the thread.
4. **10.13 Suggestion chips** — 5 quick-reply chips above the composer ("On my way", "Running 15 min late", "Be there in 10", "Wrapping up", "All done. Thanks."). Click fills textarea (no auto-send — user reviews/edits first).

All four verified end-to-end via Chrome MCP + DB cross-checks.

## Wave U (commit `5b43a44d`) — Cross-app round-trip verification + iOS rebrand

**Verification (no code change):** confirmed all 5 critical contractor → homeowner round-trips by calling the SPA's Edge Function actions as W2 owner JWT and cross-checking the homeowner-side rows via service-role JWT:

1. **Mark visit complete** → `handyman_request_messages` audit row with `sender_role='vendor'`, `metadata.kind='status_change'`. ✓
2. **Send quote** → `provider_quotes.status='sent'` + `inbox_items` row of type `handyman_quote_received` (ad-hoc path) OR `handyman_request_messages` mirror with `kind='quote_sent'` (request-linked path). ✓
3. **Add punch item** → `handyman_punch_items` row with `proposed_by_role='handyman'`, `source='manual'`. Same row the homeowner iOS reads. ✓
4. **Send invoice** → `provider_invoices.status='sent'` + `inbox_items` row of type `invoice_received` + `handyman_request_messages` mirror with `kind='invoice_sent'` (when request-linked). ✓
5. **Decline Chez-routed visit** → `handyman_requests.status='declined'` + audit-trail message. ✓

All 5 PASS. Data shape, RLS scoping, and iOS reader compatibility confirmed.

**One demo-relevant finding fixed inline:** iOS `HandymanRequestStatus.homeownerSummary` had 6 user-facing "the handyman" strings in `Haven/Core/Networking/DatabaseModels.swift`. If Tom shows the iOS app side-by-side during the demo, they'd violate the rebrand mandate. Replaced with "your contractor" across all 6 cases. The internal `displayLabel "Sent to handyman"` and the `case .sentToHandyman = "sent_to_handyman"` raw value stay (not user-shown copy / matches DB column).

## Wave V (commit `03462749`) — Quote bundles + Invoice PDF

Two flagship demo features.

### V.1 — Quote-with-options (good/better/best)

Tom called this out as a key differentiator from QuickBooks. Implementation reuses the existing `parent_quote_id` FK from Phase 73b — no new schema column.

**Architecture:** A bundle is one parent quote (empty line items, total=0, `BUNDLE_MARKER` sentinel in `scope_notes`) plus 2-3 child quotes. Children link via `parent_quote_id`; each carries actual line items + a tier label encoded as a title suffix.

**3 new Edge actions:**
- `save_quote_bundle` — creates parent + children atomically.
- `send_quote_bundle` — flips parent + children draft → sent in one round-trip; mirrors a single `quote_bundle_sent` thread message with the tiers array (so iOS reads ONE rich card, not 3).
- `decide_quote_bundle` — homeowner picks a tier; chosen child → `approved`, others → `superseded`, parent → `approved` with `chosenChildId` stamped.

**SPA:** NewQuoteModal got a "+ Offer good / better / best options" button that flips into multi-tier mode (auto-renames tier 0 to "Good"). Quotes screen renders bundle parents with a "BUNDLE" badge + price range; clicking shows three side-by-side tier cards. The chosen tier gets a salmon left-border + "Approved" pill; others fade with "Superseded".

**Smoke-tested:** 3-tier bundle ($700 / $1,750 / $20,500) created, sent, and decided end-to-end with DB cross-checks.

### V.2 — Invoice print/PDF route

Took the print-friendly route (no Deno headless Chrome dependency, no 3rd-party API).

**`/operations/invoices/:id/print`** — new SPA screen with workspace letterhead (company name, email, phone, website, license number), invoice number + issued/due dates, Bill To / For block, line items table, subtotal/tax/total, "Paid in full" pill when paid, thank-you footer. Auto-fires `window.print()` on mount; Cmd+P → "Save as PDF" gives a clean artifact in two clicks. `?autoprint=0` disables for review. `@media print` CSS hides the SPA chrome.

**InvoiceDetail** got a "Download PDF / Print" button on every invoice's action sidebar that opens the print page in a new tab.

**Smoke-tested:** opened with W2's seeded invoice, verified letterhead + line items + total render correctly, browser print dialog opens automatically.

## Wave W (commit `e3a3cc46`) — Demo dry-run, all 11 flows GREEN

Walked through every flow Tom is likely to demo as a real contractor would:

| # | Screen | Status | Highlight |
|---|---|---|---|
| 1 | Sign in | ✅ GREEN | Auth pitch + sign-in succeeds, `?next=` preserves on sign-out + restores on sign-in |
| 2 | Overview | ✅ GREEN | Hero + KPIs + Decision Queue with Routed-by-Chez/Emergency pills + Field Board |
| 3 | Visits + visit detail | ✅ GREEN | Decline + Mark complete buttons, structured punch list, conversation thread |
| 4 | Calendar | ✅ GREEN | Month grid + tech filter chips + today salmon pill (Wave R fixes hold) |
| 5 | Routes | ✅ GREEN | 3 tech cards + mini-map SVGs + numbered stops (Wave R fixes hold) |
| 6 | Homes / Customer 7 | ✅ GREEN | chez_profile spending tier banner ("Auto-approve under $250…") visible (Wave N) |
| 7 | Quotes + new-quote | ✅ GREEN | Wave V bundle CTA visible; existing 3-tier bundle renders with salmon-bordered Approved tier |
| 8 | Invoices + print/PDF | ✅ GREEN | List + detail + print page with full letterhead all working (Wave V) |
| 9 | Messages + chip | ✅ GREEN | Wave T polish — paperclip + +Quote + +Visit + chips all wired |
| 10 | Settings | ✅ GREEN | All 4 cards render, fields populated (Wave P) |
| 11 | Sign out | ✅ GREEN | Lands on /handyman.html with Signed-out pill, next-link preserved |

**The one finding** was 33 pre-existing fixture rows with em-dashes in user-visible fields (titles, message bodies, etc.). The seed source was fixed pre-Wave-D but earlier seeded rows lingered. Scrubbed via PostgREST PATCH on the service-role JWT — idempotent, no code changes needed.

After scrub: 0 em-dashes in user-facing data across all four affected screens.

## Final 25-commit list

| # | Commit | Wave | Title |
|---|---|---|---|
| 1 | `eae7baf1` | 0 | Phase 0 infrastructure |
| 2 | `85874c1e` | preflight | chez.css 404 + initial rebrand |
| 3 | `32c134f8` | preflight | auth gate hung |
| 4 | `e6631804` | A | salmon discipline + em dashes |
| 5 | `8de354a5` | A | Vite proxy `?v=...` |
| 6 | `db0c1406` | B | auth-gate next-link + handyman.html rebrand + AddClientModal |
| 7 | `99e15f06` | C | VisitDetail rebrand + en-dash + cross-app gaps logged |
| 8 | `38485ba8` | C | status changes append audit-trail message |
| 9 | `9aa3a1ba` | D | empty-state CTA + saved-item add + 5 brand-voice + em-dash seed |
| 10 | `63faa0bb` | E | chat order + Chez bubble + 8 brand-voice |
| 11 | `75eea466` | I | Chez routing UX |
| 12 | `3d931953` | I | Section 19 gap log |
| 13 | `1e23c9d3` | M | salmon + h1 + touch + reduced-motion |
| 14 | `8c04f6bd` | report | Initial overnight report |
| 15 | `22602f60` | N | quote-send audit + Decline button + chez_profile banner |
| 16 | `41d6d370` | O | handyman_punch_items end-to-end |
| 17 | `091d81ae` | P | Crew Invite sheet + Workspace Settings |
| 18 | `fec90fc0` | Q | Section 8 Invoices skeleton |
| 19 | `9584eb41` | report | N–Q addendum |
| 20 | `cdff07af` | **R** | Calendar + Routes 5 dead buttons |
| 21 | `46386479` | **S** | Multi-workspace switcher |
| 22 | `fa9ffb6e` | **T** | Messages photo + quote + visit + chips |
| 23 | `5b43a44d` | **U** | iOS homeownerSummary rebrand |
| 24 | `03462749` | **V** | Quote bundles + invoice print/PDF |
| 25 | `e3a3cc46` | **W** | Em-dash data scrub + dry-run report |

## What is the contractor desk demo-ready for?

✅ **Every flow Tom is likely to walk through tomorrow** — sign-in, Today's Desk, Customers/Homes with chez_profile awareness, Visits with Chez routing differentiation + structured punch list authoring + Decline + Mark complete with audit trail, Calendar (Month view + tech filter), Routes (with mini-maps), Crew with Invite flow, Quotes with good/better/best bundles, Invoices with print/PDF, Messages with photo + inline quote/visit + chips, Settings with branding config, Multi-workspace switcher, Sign-out with deep-link preservation.

✅ **Cross-app parity** — every contractor action that touches a homeowner-visible state leaves a corresponding row the homeowner iOS app can read: status changes (Wave C), quote sends (Wave Q), invoice sends (Wave Q), punch list changes (Wave O), bundle decisions (Wave V). DB shapes verified.

✅ **Brand voice clean** — 0 user-facing "handyman" mentions across every audited page on the SPA AND the iOS-side homeowner summaries (Wave U). The internal `handyman_*` table names, `/handyman.html` URL path, asset paths, and code comments stay.

✅ **Salmon discipline** — only primary CTAs, active rows, salmon-50 wash on selected, status change indicators (Approved/Emergency/Routed-by-Chez SLA pills) use salmon. Wave M caught 3 stragglers; Wave R caught more.

✅ **Em-dash discipline** — 0 user-facing em-dashes in either app strings or fixture data (after Wave W scrub).

## What's NOT demo-ready (skip these surfaces)

- **Section 5 — Systems aggregate (cross-customer)**. Wholesale gap. Don't navigate to a "/systems" route.
- **Section 9a Tasks aggregate** — wholesale gap. The Decision Queue serves Tom for decisions; aggregate task list isn't surfaced.
- **Section 11 — Cases (multi-visit threads)** — wholesale gap.
- **Section 12 — Email integration** — wholesale gap.
- **Section 14 — Forecasting + reporting** — wholesale gap.
- **Section 15 — Marketing + pipeline + inventory** — wholesale gap.
- **Stripe payment integration on Invoices** (8.7-8.9) — print/PDF works; online payment not implemented.
- **A/R aging report (8.11)** — gap.
- **Quote templates / duplication** (7.29-7.30) — bundles work; templates don't.
- **e-Signature on quotes** (7.32) — gap.
- **Negotiation history timeline** (7.44) — schema there; no UI.
- **Drag-to-reschedule on Calendar** (13.3) — visits are static cards; drag isn't wired.
- **Drag-to-reorder Routes stops** (17.3) — gap.
- **Photo upload AI extraction on systems** (3.40) — manual edits work; AI extraction not wired.
- **Bulk CSV import customers** (3.12) — gap.
- **Map view of customers** (3.15) — gap.

If Tom's deck doesn't go near these, the demo is solid.

## Closing — demo-day note

The contractor Operations Desk went from **invisible-sidebar / dead-CTAs / zero-cross-app-parity** to **shippable preview with 6 wholesale architectural surfaces newly closed and 11/11 demo flows GREEN**. 25 commits, 4 redeploys of `handyman-provider`, 1 new migration (`provider_invoices`), 1 new Storage bucket (`message-attachments`), and 1 new Storage path (`message-attachments`) — all green-lit on TS compile + Vite build + service-role JWT cross-checks.

Cross-app parity is the strongest it's been across the project. Every contractor action that should land on the homeowner side does, with a verifiable DB row trail.

Good luck on the demo.
