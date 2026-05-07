# Chez Contractor web operations desk — test matrix

Pragmatic plan for exercising every meaningful flow in the **Chez
Contractor** web Operations Desk (`website/operations/*`, served at
`/operations/*`) against the live `haven-dev` Supabase project.
Parallel to:

- [`Tests/e2e/TEST_MATRIX.md`](TEST_MATRIX.md) — homeowner iOS app
- [`Tests/e2e/HANDYMAN_TEST_MATRIX.md`](HANDYMAN_TEST_MATRIX.md) — Chez Field iOS app

> **Important framing:** this matrix is the **desired-state spec**, not
> an audit of what's currently built. Every row describes a behavior
> the Operations Desk *should* support to deliver the value
> proposition (multi-trade contractor company workspace, dispatch,
> live job board, quotes + invoices, pipeline + reporting, Chez
> coordination). Subagent runs discover whether the behavior exists,
> partially exists, or is a gap to feed back into product planning.
> Every gap is filed as a `gap_found` entry. Subagents do NOT skip a
> scenario just because the surface doesn't exist yet — log the gap,
> move on.

> **Brand voice rebrand check:** per the user's explicit instruction,
> the word "handyman" is being phased out of every user-facing
> surface. Subagents should flag any occurrence of "handyman" in
> visible UI copy (page titles, nav, button labels, empty-state
> copy, modal titles) as a `ui_quality_finding` with severity major.
> The replacement is **"Chez Contractor"** (or trade-specific labels
> like "HVAC technician", "plumber", "electrician", etc.). Internal
> code identifiers, table names, file names, and API actions can keep
> the legacy `handyman` token; only the strings the contractor sees.

Three test surfaces:

| Mark | Owner | Why |
|---|---|---|
| **`Web`** | Operations Desk SPA driven via `mcp__Claude_in_Chrome__*` | Behaviour requires the desktop layout + DOM. |
| **`E2E`** | `Tests/e2e/run-contractor.mjs` (Node, calls Edge Functions + PostgREST) | Behaviour is deterministic write-and-verify against the schema. |
| **`Fixture`** | Backend seed data step (run before any web run) | Setup of multi-workspace + multi-customer relationships. |

---

## 0. Test fixtures — backend setup

Three test workspaces (W1 solo / W2 6-person crew / W3 25-person
crew), each linked to N test customer households, exercise every
single-tenant + multi-tenant + multi-trade variation. Fixtures are
seeded by `run-contractor.mjs` directly via PostgREST + service-role
JWT. No UI required for setup.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 0.1 | Cleanup of prior runs | Fixture | `Tests/e2e/cleanup-contractor.sql`. Wipes everything matching `e2e-contractor-%@chezcontractor.test` and `e2e-customer-of-contractor-%@havenhome.test`. Idempotent. |
| 0.2 | Workspace W1 (solo) — `e2e-contractor-w1-owner-${TS}@chezcontractor.test` | Fixture | One owner, no crew. Serves as the sole-prop case. |
| 0.3 | Workspace W2 (6-person crew) — owner + dispatcher + 4 techs | Fixture | Tests crew-mode UX: dispatch column, route assignment, tech filtering. |
| 0.4 | Workspace W3 (25-person crew) — for performance + scale | Fixture | Tests pagination + load-time + scrolling under realistic large-shop volume. |
| 0.5 | 30 customer households, split 4/12/14 across W1/W2/W3 | Fixture | Each household has one property + 1-2 family members + the relationship row that links it to the workspace. |
| 0.6 | Customer lifecycle states (across the 30 households) | Fixture | At least one of each: Lead (pre-link), Prospect (pending invite), Active (linked + recurring), Dormant (no visit in 12+ months), Churned (relationship ended). |
| 0.7 | 5+ home_systems per customer (varied completeness) | Fixture | Mix of complete (brand+model+serial), partial, and bare-category rows so the "incomplete systems" view has something to show. |
| 0.8 | 20+ provider_quotes per workspace across all states | Fixture | At least 2 of each: draft, sent, viewed, approved, declined, withdrawn, countered_by_homeowner, superseded. Includes multi-line quotes, photo attachments, and at least one good/better/best variant per workspace. |
| 0.9 | 30+ provider_visit_assignments per workspace | Fixture | Mix of past 365 days + future 90 days: scheduled, in_progress, completed, cancelled, no_show. Cross-tech assignment (W2/W3). |
| 0.10 | 3-8 punch list items per visit (50% from quote line items, 25% from system templates, 15% from prior visit follow-ups, 10% manual) | Fixture | Tests the full origin-tracking story for punch items: which work came from a quote, which is recurring, which is opportunistic. |
| 0.11 | 15+ invoices per workspace, paid / partial / overdue | Fixture | Stripe-test-mode flag set. Tests A/R aging report scenarios. |
| 0.12 | Open + closed cases per customer | Fixture | "Case" = a multi-visit thread (e.g. "kitchen remodel" comprises 4 visits + 2 quotes + 1 invoice). |
| 0.13 | Message threads per customer | Fixture | Mix of unread, read, archived. At least one with a Chez-mediated message (`sender_role = 'chez'`). |
| 0.14 | 5 Chez-orchestrated inbound items to W2 | Fixture | One each: task-routing, visit-routing, quote-request-routing, standing-engagement-handoff, emergency-routing. Exercises the contractor's Chez Inbox surface. |
| 0.15 | Pipeline data (leads at every stage with lost-reason on declined) | Fixture | new_lead → contacted → qualified → quoted → won/lost. |
| 0.16 | Recurring maintenance plans on 30% of active customers | Fixture | `routines` rows with workspace context. |
| 0.17 | Verification — count rows, confirm relationships | Fixture | run-contractor.mjs phase summary asserts all the above. |

---

## 1. Account creation + workspace setup

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 1.1 | Sign up via `/handyman.html` (auth pitch) → redirect to `/operations/` | Web | The entry point. Verify the auth page does NOT contain "handyman" in user-facing strings (rebrand check). |
| 1.2 | Sign in with existing contractor credentials | Web | Verify session persists, `?next=` query param respected. |
| 1.3 | First-run workspace creation (no workspace yet) | Web | Should land on `needsWorkspace: true` flow — verify the SPA gates routes correctly. |
| 1.4 | Workspace branding (logo + business name + brand color + service area) | Web | Settings page (likely a gap — verify). |
| 1.5 | Invite a new crew member via email | Web | Crew screen → "Invite member" → email + role. Token-based email; verify the `provider_workspace_members.invite_token` is set. |
| 1.6 | Re-send invite | Web | If the invite expired or wasn't received. |
| 1.7 | Cancel pending invite | Web | Removes the row; email link no longer works. |
| 1.8 | Owner adjusts an existing member's role | Web | technician → dispatcher upgrade. |
| 1.9 | Owner removes a crew member | Web | Soft-archive (`status='disabled'`). Member loses access on next login. |
| 1.10 | Multi-workspace owner: switch between W1 and W2 | Web | Sidebar workspace switcher. Verify all data swaps to the new workspace. |
| 1.11 | Forgotten password reset (email flow) | Web | Standard supabase-auth path; verify the reset link routes back to `/handyman.html` and post-reset to `/operations/`. |
| 1.12 | Sign out | Web | Confirm session cleared, redirected to auth page. |
| 1.13 | Cookie/localStorage cleared between sessions | Web | Reload after sign-out → no session leak. |
| 1.14 | Mobile viewport <768px → "Use the field app" interstitial | Web | Resize browser; verify the interstitial renders with a link to `/handyman-visit.html`. |

---

## 2. "Today" view (Overview screen)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 2.1 | Hero banner reads correctly for sole mode | Web | Personal-language. |
| 2.2 | Hero banner reads correctly for crew mode | Web | Operational-language. |
| 2.3 | KPI strip: Today / This week / Quotes out / Open threads | Web | Numbers match a service-role JWT count of the same query. |
| 2.4 | Field board (Today's stops) renders the visits with assigned tech | Web | Each stop shows tech avatar + customer + ETA + address. Empty state is graceful. |
| 2.5 | Decision queue (visit requests + counter-offered quotes + customer-pending) | Web | Salmon-wash for high-priority items; navy for normal. |
| 2.6 | Pipeline summary (open quotes by stage) | Web | Click → drills to the Quotes screen with a stage filter. |
| 2.7 | Threads summary (open + unread count) | Web | Click → Messages screen. |
| 2.8 | Crew workload strip (crew mode only) | Web | Per-tech today's stops. Sole mode hides. |
| 2.9 | Recent activity feed (per Section 21 of homeowner matrix) | Web | Likely a gap; flag if absent. |
| 2.10 | Hero CTA respects context (e.g. "Resolve overdue invoices" when AR > $X) | Web | Smart contextual primary action. |
| 2.11 | "What needs your attention" sort order (overdue first, today second, this week third) | Web | Verify the ordering rule. |

---

## 3. Customer CRM (Homes screen)

### 3a. Customer list

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 3.1 | List loads all linked customer households for the workspace | Web | Verify count matches a service-role JWT count of the link table. |
| 3.2 | Search by name | Web | Debounced; results in <300ms. |
| 3.3 | Search by address | Web | Same. |
| 3.4 | Search by phone | Web | Same. Privacy-sensitive — flag if it leaks unauth'd matches. |
| 3.5 | Sort by next-visit / last-visit / lifetime-value / outstanding-$ | Web | Click each column header. |
| 3.6 | Filter by lifecycle stage (Lead / Prospect / Active / Dormant / Churned) | Web | Likely a gap. |
| 3.7 | Filter by trade (HVAC / Plumbing / Electrical / etc.) | Web | Workspace-level filter. |
| 3.8 | Filter by status (overdue / new / high-value) | Web | Composable filters. |
| 3.9 | Pagination at 100+ rows | Web | Tested via W3 fixture. |
| 3.10 | Empty state when no customers exist | Web | Should onboard, not just show zero. |
| 3.11 | "Add customer" CTA | Web | Routes to `AddClientModal`. |
| 3.12 | Bulk import CSV | Web | Likely a gap. |
| 3.13 | Click a row → HomeDetail screen | Web | Deep link `/homes/${propertyId}`. |
| 3.14 | Enrichment pill: open requests count, system count, last visit | Web | Per-card badges. |
| 3.15 | Map view of customer addresses | Web | Likely a gap. |

### 3b. Add customer (NewQuoteModal / AddClientModal)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 3.16 | Add a brand-new homeowner (not yet on Chez) | Web | Critical growth path. Household created with status="invited". |
| 3.17 | Add an existing Chez homeowner (search by address → request link) | Web | Two-step: search, then request. |
| 3.18 | Address autocomplete (Google Places) | Web | Address field debounces, suggestions appear. |
| 3.19 | Empty submit on the add-customer form | Web | C1 — validation fires. |
| 3.20 | Special-character names | Web | C3 — saves and renders correctly. |
| 3.21 | Validation: invalid email format | Web | Client-side validation; clear error message. |
| 3.22 | Duplicate-customer detection (same address already linked) | Web | Should warn instead of creating a duplicate. |
| 3.23 | Cancel / dismiss form | Web | Flag the design choice (preserve draft or discard). |
| 3.24 | Modal escape key closes | Web | A11y. |
| 3.25 | Modal click-outside closes | Web | Verify it's NOT destructive. |

### 3c. Customer detail (HomeDetail screen — 12 subtabs)

The HomeDetail screen is the per-customer canonical surface. Per the
user's spec it should have **12 subtabs** covering every aspect of
the customer relationship. Subagents should map each subtab to what's
actually rendered and flag missing tabs as gaps.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 3.26 | Header: customer name + photo + address + contact + tags | Web | |
| 3.27 | Subtab: Overview | Web | |
| 3.28 | Subtab: Systems | Web | Brand/model/serial; click → SystemDetail. |
| 3.29 | Subtab: Visits (past + upcoming) | Web | Tap a row → visit detail. |
| 3.30 | Subtab: Quotes | Web | Customer-scoped pipeline. |
| 3.31 | Subtab: Invoices + Payments | Web | A/R history. |
| 3.32 | Subtab: Tasks | Web | Mix of contractor-suggested and Chez-relayed. |
| 3.33 | Subtab: Messages | Web | Per-customer thread. |
| 3.34 | Subtab: Documents | Web | Insurance, warranties, manuals. |
| 3.35 | Subtab: Service plan / recurring routines | Web | |
| 3.36 | Subtab: Notes / tags | Web | Workspace-level annotations. |
| 3.37 | Subtab: Cases (multi-visit threads) | Web | |
| 3.38 | Subtab: Vendors | Web | Cross-vendor awareness for upsell. |

### 3d. System inventory authoring

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 3.39 | Add a new system on the customer (manual entry) | Web | Trade picker + brand + model + serial + install date. |
| 3.40 | Photo upload of a model plate → AI extracts data | Web | `identify-equipment` Edge Function. |
| 3.41 | Edit existing system (correct a typo in serial) | Web | A4 — UPDATE not duplicate. |
| 3.42 | Decommission a system | Web | `decommission_system` action; verify status flips. |
| 3.43 | "Incomplete systems" view — gap-fill list | Web | Likely a gap. |
| 3.44 | Suggested systems based on property type | Web | Likely a gap. |
| 3.45 | Bulk-add multiple systems in one session | Web | Performance: 10 systems in one batch. |

---

## 4. Deep-link graph

The customer relationship graph is heavily cross-linked. Verify deep
links survive reload + bookmarking.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 4.1 | `/homes/${propertyId}` reload preserves state | Web | A1. |
| 4.2 | `/visits/${requestId}` reload preserves state | Web | |
| 4.3 | Bookmark a customer URL, paste into new tab | Web | Auth gate fires, then deep links. |
| 4.4 | Browser back button works after Customer → Visit → Quote | Web | History stack is correct. |
| 4.5 | URL with bad UUID (`/homes/not-a-uuid`) | Web | Graceful 404, not a crash. |
| 4.6 | URL pointing to a customer of a DIFFERENT workspace | Web | Permission check fires. |
| 4.7 | Logged-out user pasting a deep link | Web | Auth gate stores `?next=`. |

---

## 5. Systems screen (cross-customer aggregate — likely a gap)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 5.1 | Aggregate list of all systems across the contractor's customers | Web | Likely a gap. |
| 5.2 | Filter by category | Web | |
| 5.3 | Filter by brand | Web | "Recall came out — who's affected?" |
| 5.4 | Filter by age | Web | |
| 5.5 | Filter by warranty status | Web | |
| 5.6 | Sort by last-service-date | Web | |
| 5.7 | Bulk-action (filter-change reminder to all HVAC customers) | Web | |
| 5.8 | Recall sweep view | Web | |

---

## 6. Visits + punch list authoring (Visits + VisitDetail screens)

### 6a. Visits list

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 6.1 | List of all visits across all customers | Web | |
| 6.2 | Filter: today / this week / this month / all | Web | |
| 6.3 | Filter by status (scheduled / in-progress / completed / cancelled / no-show) | Web | |
| 6.4 | Filter by tech | Web | Multi-select. |
| 6.5 | Filter by customer | Web | |
| 6.6 | Search by visit description / customer name | Web | |
| 6.7 | Sort: date asc / date desc / status / customer | Web | |
| 6.8 | Click row → VisitDetail | Web | |
| 6.9 | Empty state | Web | |
| 6.10 | Pagination at 100+ visits | Web | |

### 6b. VisitDetail — pre-visit prep

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 6.11 | Visit header: customer + address + scheduled time + assigned tech | Web | |
| 6.12 | Tap-to-call customer (`tel:` link) | Web | |
| 6.13 | Tap-to-navigate (Google Maps deep link) | Web | |
| 6.14 | Pre-visit prep checklist | Web | Likely a gap. |
| 6.15 | Customer's standing instructions (chez_profile excerpt) | Web | Likely a gap. |
| 6.16 | Reschedule / cancel buttons | Web | |
| 6.17 | Reassign to a different tech | Web | |
| 6.18 | Internal notes (tech-to-tech, NOT customer-visible) | Web | |

### 6c. VisitDetail — punch list authoring

This is one of the highest-value flows. The contractor builds the
punch list BEFORE the visit so the field tech (Chez Field iOS) shows
up with a complete checklist.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 6.19 | Visit detail shows current punch list (if any) | Web | |
| 6.20 | Add a new punch item (free text + estimated minutes + materials needed) | Web | |
| 6.21 | Add multiple punch items in one session | Web | |
| 6.22 | Edit an existing punch item | Web | A4. |
| 6.23 | Reorder punch items (drag-and-drop) | Web | |
| 6.24 | Delete a punch item with confirmation | Web | A7. |
| 6.25 | Pull punch items from a quote line item | Web | Likely a gap. |
| 6.26 | Pull punch items from a system template | Web | Likely a gap. |
| 6.27 | Pull punch items from a prior visit's follow-ups | Web | Likely a gap. |
| 6.28 | Materials list per punch item | Web | |
| 6.29 | Time estimate per punch item | Web | |
| 6.30 | Photos / diagrams per punch item | Web | |
| 6.31 | Standard punch list templates | Web | Likely a gap. |
| 6.32 | Punch list save persists to DB across reload | Web | A1 — critical persistence check. |

### 6d. VisitDetail — post-visit review

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 6.33 | View the field tech's completed punch list (with photo evidence, voice notes, time per item) | Web | |
| 6.34 | View the captured materials (with cost) | Web | |
| 6.35 | View the visit summary auto-generated from the punch list | Web | |
| 6.36 | Edit the summary before sending to customer | Web | |
| 6.37 | Convert visit summary → invoice | Web | |
| 6.38 | Convert visit observations → follow-up suggestions / quotes | Web | |
| 6.39 | Approve invoice → send to customer | Web | |
| 6.40 | Mark visit "needs follow-up" → schedules a placeholder | Web | |

---

## 7. Quotes (Quotes screen + NewQuoteModal)

### 7a. Quote list

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 7.1 | List of all quotes across all customers | Web | |
| 7.2 | Filter by status | Web | |
| 7.3 | Filter by customer | Web | |
| 7.4 | Filter by tech | Web | |
| 7.5 | Filter by total range | Web | |
| 7.6 | Search by quote title / customer / job description | Web | |
| 7.7 | Sort: date / total / status | Web | |
| 7.8 | Click row → quote detail (or modal) | Web | |
| 7.9 | Empty state | Web | |
| 7.10 | Pagination at 100+ quotes | Web | |

### 7b. Quote authoring (NewQuoteModal)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 7.11 | Single-line quote | Web | |
| 7.12 | Multi-line quote (labor + materials + tax) | Web | |
| 7.13 | Materials markup % | Web | Workspace setting. |
| 7.14 | Discount line | Web | |
| 7.15 | Quote with photos attached | Web | |
| 7.16 | Scope notes / methodology field | Web | |
| 7.17 | Save as draft | Web | A5. |
| 7.18 | Send to customer (push + inbox + email) | Web | All 3 channels fire. |
| 7.19 | Empty quote submit (no line items) | Web | C1. |
| 7.20 | Quote with very long description (1000+ chars) | Web | C2. |
| 7.21 | Quote with $0 total | Web | C4. |
| 7.22 | Quote with massive total ($9,999,999) | Web | C4. |
| 7.23 | Decimal pricing | Web | C4. |
| 7.24 | Pasting formatted text | Web | C6. |
| 7.25 | Network failure mid-save | Web | C7. |
| 7.26 | Server 500 mid-save | Web | C8. |
| 7.27 | Quote-with-options (good / better / best) | Web | Likely a gap. |
| 7.28 | Multi-trade quote | Web | |
| 7.29 | Quote template (save + reuse) | Web | Likely a gap. |
| 7.30 | Quote duplication | Web | Likely a gap. |
| 7.31 | Quote PDF export | Web | |
| 7.32 | Quote signing (e-signature) | Web | Likely a gap on web. |
| 7.33 | Quote conversion to invoice | Web | |

### 7c. Quote negotiation depth (the make-or-break section)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 7.34 | Customer counters with a different price | Web | Contractor-side notification + UI badge. |
| 7.35 | Multi-round counter (3+ rounds) | Web | History view. |
| 7.36 | Scope counter (line item changes, not just total) | Web | |
| 7.37 | Quote-with-options counter | Web | Customer picks "good" tier. |
| 7.38 | Contractor accepts customer's counter | Web | |
| 7.39 | Contractor declines customer's counter | Web | |
| 7.40 | Contractor counters back with different price | Web | |
| 7.41 | Contractor counters with revised scope | Web | |
| 7.42 | Walk-away point: after N counters, system suggests "ready to move on?" | Web | Likely a gap. |
| 7.43 | Auto-expiration of quotes | E2E | |
| 7.44 | Negotiation history view (timeline) | Web | |
| 7.45 | Chez-mediated negotiation | Web | When `chez_owned = true`. |
| 7.46 | Quote comments / questions per line item | Web | `provider_quote_comments` table. |
| 7.47 | Quote approval signature capture | Web | |

### 7d. Saved line item library

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 7.48 | Workspace-level saved line items | Web | `provider_saved_quote_items`. |
| 7.49 | Drag-and-drop saved item into quote builder | Web | |
| 7.50 | Save current line item as new template | Web | |
| 7.51 | Edit / delete saved items | Web | |
| 7.52 | Reorder saved items | Web | |
| 7.53 | Search saved items | Web | |

---

## 8. Invoices (likely a gap surface)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 8.1 | Invoice list | Web | |
| 8.2 | Invoice detail | Web | |
| 8.3 | Convert quote → invoice | Web | |
| 8.4 | Convert visit summary → invoice | Web | |
| 8.5 | Itemized invoice (labor + materials + parts + tax) | Web | |
| 8.6 | Invoice send (email + customer-side inbox) | Web | |
| 8.7 | Customer pays online (Stripe test-mode) | Web | |
| 8.8 | Partial payment | Web | |
| 8.9 | Refund | Web | |
| 8.10 | Auto-reminder for overdue invoices | E2E | |
| 8.11 | A/R aging report | Web | |
| 8.12 | Per-customer invoice history | Web | |
| 8.13 | Tax computation (workspace rate) | Web | |
| 8.14 | Invoice PDF export | Web | |
| 8.15 | Late fee accrual | Web | |

---

## 9. Tasks + visit suggestions (likely a gap surface)

### 9a. Task list

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 9.1 | Aggregate task list across customers | Web | |
| 9.2 | Filter by status (open / completed / suggested / declined) | Web | |
| 9.3 | Filter by customer | Web | |
| 9.4 | Click a task → opens the customer's task detail | Web | |
| 9.5 | Mark task complete | Web | |
| 9.6 | Suggest a task to a customer | Web | |
| 9.7 | Bulk suggest 5 tasks at once after a visit | Web | |
| 9.8 | Task suggestion → customer accepts | Web | Cross-app. |
| 9.9 | Task suggestion expiration | E2E | |

### 9b. Visit suggestions (proactive scheduling)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 9.10 | Propose a visit with 3 candidate slots | Web | |
| 9.11 | Propose a recurring visit | Web | |
| 9.12 | Proposed visit tied to a system | Web | |
| 9.13 | Customer accepts → visit on calendar | Web | |
| 9.14 | Customer requests different time | Web | |
| 9.15 | Pre-filled punch list for the proposed visit | Web | |
| 9.16 | Visit-suggestion templates | Web | |
| 9.17 | Climate-driven suggestion | E2E | |
| 9.18 | Calendar-driven suggestion ("12mo since last visit") | Web | |

---

## 10. Messages (Messages screen)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 10.1 | Inbox column shows all customer threads | Web | |
| 10.2 | Unread badges | Web | |
| 10.3 | Click thread → open it | Web | |
| 10.4 | Send text message | Web | |
| 10.5 | Send photo attachment | Web | |
| 10.6 | Send a quote inline | Web | |
| 10.7 | Send a visit suggestion inline | Web | |
| 10.8 | Read receipts | Web | |
| 10.9 | Typing indicator | Web | |
| 10.10 | Message search across all threads | Web | |
| 10.11 | Archive a thread | Web | |
| 10.12 | Right rail: customer summary | Web | |
| 10.13 | Suggestion chips composer | Web | |
| 10.14 | Alfred suggestion card | Web | Likely a gap. |
| 10.15 | Group thread (customer + Chez admin + contractor) | Web | "Chez" never operator's name. |

---

## 11. Cases (multi-visit threads — likely a gap)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 11.1 | Case list per customer | Web | |
| 11.2 | Case detail (timeline of visits + quotes + invoices + messages) | Web | |
| 11.3 | Open a new case | Web | |
| 11.4 | Close a case | Web | |
| 11.5 | Reopen a closed case | Web | |
| 11.6 | Move a visit / quote / invoice to a different case | Web | |
| 11.7 | Case profitability | Web | |
| 11.8 | Case templates | Web | |

---

## 12. Email integration (likely a gap surface)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 12.1 | OAuth-connect Gmail / Outlook | Web | |
| 12.2 | Inbound emails routed to the right customer | Web | |
| 12.3 | Outbound emails through Chez | Web | |
| 12.4 | Forward to alfred@chezcontractor.com → AI parses | E2E | |
| 12.5 | Email templates | Web | |
| 12.6 | Per-customer email signature | Web | |

---

## 13. Calendar (Calendar screen)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 13.1 | Day / Week / Month toggle | Web | |
| 13.2 | Click a day → see all visits | Web | |
| 13.3 | Drag visit to reschedule | Web | |
| 13.4 | Click empty slot → "create visit" form | Web | |
| 13.5 | Filter by tech | Web | |
| 13.6 | iCal/ICS feed export per workspace | Web | |
| 13.7 | Bidirectional Google Calendar sync | Web | |
| 13.8 | Visit conflict warning when overlapping | Web | |
| 13.9 | "Today" pill on current date | Web | |
| 13.10 | Color-coded per-tech | Web | |

---

## 14. Forecasting + reporting (likely a gap surface)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 14.1 | Revenue this month vs last month | Web | |
| 14.2 | Quote conversion rate | Web | |
| 14.3 | Average ticket size | Web | |
| 14.4 | Top customers by revenue | Web | |
| 14.5 | Per-tech utilization | Web | |
| 14.6 | A/R aging | Web | |
| 14.7 | Job profitability report | Web | |
| 14.8 | Recurring revenue forecast | Web | |
| 14.9 | Pipeline value (sum of open quotes) | Web | |
| 14.10 | Year-over-year comparison | Web | |
| 14.11 | Export reports to CSV / PDF | Web | |
| 14.12 | Custom date range selector | Web | |

---

## 15. Marketing + pipeline + inventory (likely a gap surface)

### 15a. Marketing

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 15.1 | Customer-facing landing page per workspace | Web | |
| 15.2 | Lead capture form | Web | |
| 15.3 | Workspace SEO basics | Web | |
| 15.4 | Reviews integration | Web | |

### 15b. Pipeline

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 15.5 | Pipeline view: leads at each stage | Web | |
| 15.6 | Drag-and-drop lead between stages | Web | |
| 15.7 | Lost-reason capture on declined leads | Web | |
| 15.8 | Lead source tracking | Web | |
| 15.9 | Per-stage conversion rates | Web | |
| 15.10 | Auto-followup reminders for stale leads | Web | |

### 15c. Inventory

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 15.11 | Parts inventory list | Web | |
| 15.12 | Per-truck inventory | Web | |
| 15.13 | Reorder alerts | Web | |
| 15.14 | Materials cost reconciliation | Web | |

---

## 16. Crew screen

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 16.1 | Roster with avatars + roles + status | Web | |
| 16.2 | Per-tech profile drawer | Web | |
| 16.3 | Per-tech permissions toggles | Web | |
| 16.4 | Per-tech activity timeline | Web | |
| 16.5 | Invite a new tech | Web | |
| 16.6 | Reassign visits when a tech is OOO | Web | |
| 16.7 | Tech search | Web | |

---

## 17. Routes screen

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 17.1 | Per-tech route card (today's stops in order) | Web | |
| 17.2 | Mini-map preview | Web | |
| 17.3 | Drag-to-reorder stops | Web | |
| 17.4 | Optimize route ("best driving order") | Web | |
| 17.5 | Send route to tech's phone | Web | |
| 17.6 | Route summary (total miles + estimated drive time) | Web | |

---

## 18. Settings + integrations (likely a gap surface)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 18.1 | Workspace branding (logo, color, business name) | Web | |
| 18.2 | Tax/business info (EIN, sales tax rate) | Web | |
| 18.3 | Payment integration (Stripe Connect) | Web | |
| 18.4 | Notification preferences | Web | |
| 18.5 | QuickBooks / Xero integration | Web | |
| 18.6 | Calendar integrations | Web | |
| 18.7 | Email integration | Web | |
| 18.8 | API tokens for custom integrations | Web | |
| 18.9 | Audit log (who did what when) | Web | |

---

## 19. Chez admin coordination (the differentiating layer)

This is the section that differentiates Chez Contractor from
QuickBooks Self-Employed / Jobber / Housecall Pro. The Chez admin
sits in the middle and orchestrates work between homeowner ↔
contractor.

### 19a. Inbound from Chez (5 flavors)

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 19.1 | **Task routing**: Chez routes a homeowner-delegated task | Web | Inbox item with full context. Accept / decline / counter. |
| 19.2 | **Visit routing**: Chez schedules a visit on behalf of customer | Web | Lands on calendar with Chez metadata. |
| 19.3 | **Quote-request routing**: Chez asks contractor for a quote | Web | "Customer wants to replace their roof." |
| 19.4 | **Standing-engagement handoff**: customer says "have Chez own scheduling" | Web | "Chez now coordinates this customer." |
| 19.5 | **Emergency routing**: Chez escalates an urgent request | Web | High-priority + auto-pings the contractor's phone. |

### 19b. Accept / decline / counter

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 19.6 | Accept a Chez-routed task | Web | |
| 19.7 | Decline a Chez-routed task with reason | Web | |
| 19.8 | Counter a Chez-routed task | Web | Goes back to Chez. |
| 19.9 | Accept a Chez-routed visit | Web | |
| 19.10 | Counter a Chez-routed visit (different time) | Web | |
| 19.11 | Accept a Chez quote-request → build quote → forward | Web | |

### 19c. Comms with Chez

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 19.12 | Open a Chez chat thread | Web | |
| 19.13 | Send a question to Chez | Web | |
| 19.14 | Receive a reply from Chez | Web | Always rendered as "Chez". |
| 19.15 | Group thread (contractor + Chez + customer) | Web | |
| 19.16 | Chez auto-summary of customer's standing instructions | Web | |

### 19d. Standing relationships

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 19.17 | Customer turned on `chez_owned = true` for this contractor | Web | Banner explaining Chez-owned scheduling. |
| 19.18 | Customer turned off `chez_owned` later | Web | Relationship reverted. |
| 19.19 | View list of all Chez-owned customers | Web | |
| 19.20 | View list of all standing engagements | Web | |
| 19.21 | Spending tier transparency (contractor sees `chez_profile.spending_tiers`) | Web | |

---

## 20. Settings + integrations + branding

(Folded into Section 18 above.)

---

## 21. Cross-app round trips (homeowner ↔ contractor ↔ Chez)

These verify the three sides agree on the same source of truth.

| # | Scenario | Owner | Notes |
|---|---|---|---|
| 21.1 | Contractor sends quote → homeowner sees in iOS inbox | Web + iOS | |
| 21.2 | Homeowner counters quote on iOS → contractor sees on web | Web + iOS | |
| 21.3 | Contractor schedules visit → homeowner sees on iOS | Web + iOS | |
| 21.4 | Homeowner reschedules → contractor sees on web | Web + iOS | |
| 21.5 | Field tech completes punch list on iOS → web Operations Desk reflects | Web + iOS | |
| 21.6 | Customer adds a punch item DURING a visit on iOS → web reflects within 5s | Web + iOS | |
| 21.7 | Contractor approves invoice on web → homeowner sees on iOS | Web + iOS | |
| 21.8 | Customer pays invoice on iOS → contractor sees within 30s | Web + iOS | |
| 21.9 | Customer turns on `chez_owned` → contractor sees the banner | Web + iOS | |
| 21.10 | Chez admin routes a task → contractor sees in inbox | Web + Admin | |

---

## 22. Per-scenario test discipline (apply to EVERY scenario above)

The matrix lists ~570 scenarios. For each one a subagent touches, it
must apply the standard discipline below. Same shape as Section 21
of the handyman matrix, adapted for the web surface.

Each subagent picks AT LEAST ONE check from each of the categories
A-D for every scenario. Categories E-H are sampled.

### A. Save / persistence checks (mandatory on every create / edit / delete)

| Check | What to verify |
|---|---|
| **A1 Save → reload** | Create the entity, hard-refresh (Cmd+Shift+R), confirm the entity persists. |
| **A2 Save → close tab → reopen** | Open in fresh tab via deep link. |
| **A3 Save → DB cross-check** | Curl PostgREST with service-role JWT and confirm the row. |
| **A4 Edit existing → no duplicate** | Edit + save, verify UPDATE not INSERT. |
| **A5 Save partial → resume preserves draft** | Half-fill, navigate away, return — draft preserved or discarded explicitly. |
| **A6 Save offline → sync on reconnect** | DevTools offline, save, reconnect. |
| **A7 Delete → confirmation OR undo** | Confirmation dialog or 5s undo. |
| **A8 Concurrent edit handling** | Two browser sessions; verify last-write-wins or conflict UI. |

### B. UI quality checks (mandatory on every distinct screen)

| Check | What to verify |
|---|---|
| **B1 Salmon discipline** | Salmon (`#ED6955` / `--accent`) only on primary CTAs, active queue case accent, salmon-50 wash on selected rows, fit-meter at success tier, SLA-critical pills. Never on decoration / inactive cards / body text / icon tints on inactive list rows. |
| **B2 Typography mix** | `ui-serif` for 18pt+ display. System sans for 16pt and below. |
| **B3 Em dashes (`—`) in user-facing copy** | Hard rule. Replace with periods, colons, "to", or "and". |
| **B4 Brand voice + rebrand check** | Every user-facing string says "Chez", never an operator's name. **No "handyman" in user-facing copy** — replace with "Chez Contractor" or trade-specific. |
| **B5 Spacing + radii** | Card radius matches `--radius-card`, button radius matches `--radius-btn`. |
| **B6 Touch targets** | ≥ 32px min dimension; buttons ≥ 40px. |
| **B7 Shadows** | Indigo-tinted, never pure black. |
| **B8 Animation quality** | High damping, ~0.2s. |
| **B9 Empty / loading / error / populated states** | All 4 states render gracefully. |
| **B10 Layout under content extremes** | Short / medium / long content; no break, truncate, or push CTAs off-screen. |

### C. Edge case input checks (mandatory on every form)

| Check | What to verify |
|---|---|
| **C1 Empty / whitespace submit** | Validation fires; no submission. |
| **C2 Max length** | 500-char paste; cap or scroll, no break, no DB error. |
| **C3 Special characters** | Apostrophes, emoji, foreign chars, HTML-like, SQL-like. All save. |
| **C4 Numeric edge cases** | Negative, zero, very large, decimals. |
| **C5 Date edge cases** | Feb 29, DST, very past, very future. |
| **C6 Pasting formatted text** | Strip formatting cleanly. |
| **C7 Network failure mid-save** | Clear error + actionable recovery. |
| **C8 Server 500 mid-save** | Graceful error, no crash. |

### D. Async / network state checks (mandatory on every loading surface)

| Check | What to verify |
|---|---|
| **D1 Loading skeleton** | Skeleton, not spinner on blank. |
| **D2 Network failure on initial load** | Recoverable error. |
| **D3 Slow network (Slow 3G)** | UI doesn't hang; loading state visible. |
| **D4 Refresh affordance** | Refresh re-fetches. |
| **D5 Pagination / infinite scroll** | At 100 items: smooth scroll. |
| **D6 Optimistic UI** | Reflect change immediately, rollback on error. |

### E. Browser lifecycle (sampled — once per major surface)

| Check | What to verify |
|---|---|
| **E1 Tab close → reopen via deep link** | State reachable. |
| **E2 Browser refresh mid-modal** | Auto-reopen or graceful redirect. |
| **E3 History back / forward** | URL + UI in sync. |
| **E4 Multiple tabs of same workspace** | Edit on one, refresh another, change visible. |
| **E5 Session timeout** | Refresh silently or redirect to sign-in. |

### F. Concurrent / multi-user (sampled — ~25% of scenarios)

| Check | What to verify |
|---|---|
| **F1 Two-user sync** | Two crew members in parallel; edit propagates. |
| **F2 Two-user conflict** | Last-write-wins or clear error. |

### G. Performance / scale (sampled — lists + heavy surfaces)

| Check | What to verify |
|---|---|
| **G1 100+ items** | Initial load <3s, smooth scroll. |
| **G2 1000+ items** | Pagination kicks in or load stays acceptable. |
| **G3 Search performance** | Debounced; <1s. |
| **G4 Initial JS bundle size** | Warn if >500KB gzipped. |

### H. Accessibility (sampled — ~20% of screens)

| Check | What to verify |
|---|---|
| **H1 Keyboard navigation** | Tab order logical; no traps. |
| **H2 Screen reader (VoiceOver)** | Labels on every actionable element. |
| **H3 Color contrast (WCAG AA)** | Body text ≥ 4.5:1; salmon flagged if used for body. |
| **H4 Reduced motion** | Animations disabled per OS pref. |
| **H5 Zoom 200%** | No layout break or horizontal scroll on body. |

### Required minimum per subagent run

For every scenario the subagent exercises:
- **Always:** A1, B1-B4, C1
- **At least one of:** A2-A8, B5-B10, C2-C8, D1-D6
- **Sample (one or two scenarios per subagent):** E, F, G, H

If a category is non-applicable (e.g. read-only view has no C inputs),
the subagent says so explicitly.

---

## 23. Cross-browser

Sampled. The matrix is primarily authored against Chrome/Chromium via
Chrome MCP. Sample 5-10 critical flows in:

| Browser | Coverage |
|---|---|
| Chrome 124+ | All flows (canonical) |
| Safari 17+ | Auth + Overview + one quote-authoring flow + one customer-detail flow |
| Firefox 120+ | Auth + Overview + Calendar + Messages |
| Edge 124+ | Auth + Overview |

---

## 24. What's NOT in this matrix (deliberately deferred)

- **Native mobile apps** for the contractor side.
- **Subcontractor management** (contractor A subs to contractor B).
- **Marketplace / lead-buying integrations**.
- **Tax filing / 1099 generation**.
- **In-person card readers / hardware**.

---

## 25. Wave grouping (for overnight execution)

| Wave | Sections | Subagents | Notes |
|---|---|---|---|
| **A** | 0 + 1 + 2 | 3-4 | Auth, workspace, today view |
| **B** | 3 + 4 | 4-5 | Customer CRM (12 subtabs) + deep-link graph |
| **C** | 5 + 6 | 4 | Systems screen + visits + punch lists |
| **D** | 7 | 4-5 | Quotes (esp. negotiation depth) |
| **E** | 8 + 9 + 10 + 11 | 4 | Invoices + tasks + chats + cases |
| **F** | 12 | 2 | Email integration |
| **G** | 14 | 2 | Reporting |
| **H** | 15 | 3 | Marketing + pipeline + inventory |
| **I** | 19 | 3 | Chez admin coordination |
| **J** | 20 | 2 | Settings + integrations |
| **K** | 21 | 3 | Cross-app round trips |
| **L** | 23 | 2 | Cross-browser |
| **M** | 22 (B + H) | 1-2 | Comprehensive design + a11y audit |

Between waves: triage. Critical persistence + UI findings → fix
immediately. Major UI → batch into end-of-wave commits. Gaps → log to
`Tests/e2e/CONTRACTOR_GAPS.md`.

---

## 26. Findings categorization

Subagent's return JSON includes a `findings: []` array. Each entry is
one of FOUR categories:

```json
{
  "category": "verification" | "gap_found" | "ui_quality_finding" | "persistence_finding",
  "matrix_row": "3.16 Add a brand-new homeowner",
  "passed": true | false,
  "severity": "critical" | "major" | "moderate" | "minor",
  "evidence": "concrete details (DOM refs, computed styles, network responses)"
}
```

- `verification` — pass / fail of a row.
- `gap_found` — feature absent.
- `ui_quality_finding` — feature exists but broken / off-brand.
- `persistence_finding` — saves don't survive reload. **Always ≥ major.**

Critical persistence + critical UI quality findings → auto-fix
overnight. Major UI batched. Gaps → `CONTRACTOR_GAPS.md`.

---

## 27. Required output structure

```json
{
  "scenario_batch": "wave-A-section-1-auth",
  "result": "PASS | PARTIAL | FAIL",
  "actions_summary": "1-3 sentence narrative",
  "findings": [
    { "category": "verification", "matrix_row": "1.1", "passed": true, "evidence": "..." },
    { "category": "gap_found", "matrix_row": "1.4", "evidence": "..." },
    { "category": "ui_quality_finding", "matrix_row": "1.0", "severity": "major", "evidence": "..." },
    { "category": "persistence_finding", "matrix_row": "1.7", "severity": "critical", "evidence": "..." }
  ],
  "discipline_coverage": {
    "A_persistence": ["A1", "A3"],
    "B_ui_quality": ["B1", "B2", "B3", "B4", "B9"],
    "C_input_edge_cases": ["C1"],
    "D_async_state": ["D1"],
    "E_lifecycle": [],
    "F_concurrent": [],
    "G_performance": [],
    "H_accessibility": []
  },
  "screenshot_paths": [],
  "needs_engineer_attention": true | false
}
```

The `discipline_coverage` field is how the main thread audits whether
each subagent ran the required checks.
