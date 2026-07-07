# Chez Value Delivery Plan: Email Intelligence v2 + Pitch Deck Rectification

Date: 2026-06-10. Companion to `CHEZ_MISSION_GAPS.md` (strategy register) and `Tests/e2e/VERIFICATION_2026-06_GAPS.md` (verification log).
Sources: full static trace of receive-email → inbox → process-inbox-item → downstream (file:line verified), this week's live runtime sweep, and the 11-slide pitch deck.

---

## PART 1 — Email forwarding: what is true today

Tom's four requirements, audited:

### 1. Quote handling
| Requirement | Today | Evidence |
|---|---|---|
| Identify it is a quote | WORKS (live-verified: forwarded PDF classified contractor_quote, high confidence) | receive-email classification + sweep G |
| Prompt: make a new project | WORKS (`process_quote` creates property_projects) | process-inbox-item:186-339 |
| Prompt: add to an EXISTING project (picker) | WORKS — "Add to Project" presents a project picker; writes project_quotes + project_contacts + active_quote_id handling | InboxItemDetailView:158-193, 785-863; process-inbox-item:342-524 |
| Create vendor unless existing | WORKS — fuzzy ilike match on company_name, else INSERT with phone/email/address | receive-email:992-1031; process-inbox-item:226-257 |
| Quote on the vendor relationship profile page | **MISSING** — project_quotes carries contractor_id but no documents row is created from the quote path, and ContractorDetailView only lists documents via documents.contractor_id. Quotes are invisible on the vendor profile and in the Documents vault | ContractorDetailView:546/1702; process-inbox-item:300-310 |
| Assign similar quotes to a project automatically | **BUILT BUT DISABLED** — a 4-signal matcher (sender→project_contacts, subject threading Re:/Fwd:, category/name normalization, fallback) sits behind `if (false)` at receive-email:1041 with the note "Quotes now always prompt the user" | receive-email:1041-1230 |

### 2. Intent identification (warranty + other types)
9 classification types; 6 drive real actions (quote, bill, insurance_claim, vehicle, home_document, family-events). Three weak spots:
- **Warranty: MISSING end to end.** Warranty emails land as home_document; analyze-document extracts insurance_policy metadata but nothing ever creates a `warranties` row or links a system. Today warranties are manual-only (AddWarrantySheet).
- **vendor_contact: DEAD-END.** Claude extracts the contact's name/phone/email and then the pipeline discards it; no contractor created.
- estate_document / other: storage-only (acceptable for v1; estate by design).

### 3. Invoice with follow-up tasks
PARTIAL. process-invoice extracts follow_ups + cadence + systems beautifully, but the EMAIL path never auto-calls it: process-inbox-item's process_document runs analyze-document only. The homeowner reaches invoice intelligence only if they tap into InvoiceChoiceSheet from the right surface. Email-origin invoices deliver ~30% of their potential.

### 4. Systems on quote/invoice — add or replace
- ADD from invoices: WORKS user-confirmed (new_systems_discovered + specialty inference → iOS review sheet accept/dismiss).
- ADD from quotes: MISSING (no inference runs on the quote path).
- **REPLACE: MISSING flow, schema already exists.** home_systems has `archived_at`, `is_active`, `decommissioned_at` — no detection ("new Rheem replacing old water heater") and no UI to retire the old unit, migrate its tasks/warranty pointers.

## PART 2 — Email Intelligence v2 (the build plan)

Ranked by homeowner value; effort is focused dev-days. Server items are deployable independently of Tom's iOS WIP; iOS items are additive files/sheets that avoid WIP-modified code.

| # | Workstream | Design | Effort | Layer |
|---|---|---|---|---|
| E1 | **Re-enable quote→project matching as SUGGEST, not auto-create** | Run the existing 4-signal matcher; never auto-create. On match, stamp inbox metadata `suggested_project_id` + confidence; iOS quote card pre-selects that project ("Looks like your Kitchen Reno — add this quote?") with one-tap confirm, picker behind it. Honors the original disable reason (no surprise projects) while killing 5 taps | 1-2d | server + small iOS |
| E2 | **Quotes land on the vendor profile + vault** | process_quote/add_to_project also create a documents row (category "Contractor Quote", contractor_id, project_id, file moved from inbox-attachments to documents bucket); link project_quotes.document_id. ContractorDetailView already lists by contractor_id — zero UI work for the profile; vault search gets quotes free | 1-2d | server (+1 col) |
| E3 | **Warranty intelligence** | analyze-document gains a `warranty` extraction block (provider, type, start/end, covered item hint). New inbox action card: "Warranty found: Rheem water heater through 2032 — attach to your Water Heater system?" with system fuzzy-match (category+manufacturer) and a picker fallback. Confirm writes WarrantyInsert + links the doc. Renewal pushes already exist once end_date is on file | 2-3d | server + small iOS card |
| E4 | **Email invoices auto-run invoice intelligence** | On bill_invoice confirm (or immediately at high confidence), process-inbox-item calls process-invoice with the stored attachment; results stamped into inbox metadata so InboxItemDetailView opens straight into InvoiceReviewSheet (tasks/systems/follow-ups/cadence toggles). One pipeline, both origins | 1-2d | server + routing |
| E5 | **System REPLACE flow** | process-invoice flags `replaces_existing` when a discovered system matches an active system's category+subtype with a newer install signal. InvoiceReviewSheet gains "Replace old unit" option: archives the old row (archived_at, is_active=false, decommissioned_at), repoints open tasks via the reconciler, prompts warranty carry/close. Schema already in place | 2-3d | server + iOS sheet |
| E6 | **Quote-side system inference** | Run the same specialty-inference on contractor_quote attachments; suggestion rides the project-creation flow ("This quote mentions a pool heater — add Pool system?") | 0.5-1d | server |
| E7 | **vendor_contact rescue** | Classified contact → upsert contractor (same fuzzy logic as quotes) + "Added Sweep Gutter Co to your vendors" informational item | 0.5d | server |
| E8 | **Inline fair-market hint on quote cards** | At classification time (attachment present), fire analyze-quote; cache `fair_market_low/high` into inbox metadata; quote card renders "Local range: $380-$470" before the homeowner even opens it. Doubles as C1 below | 1-2d | server + card line |

Sequence: E2 → E4 → E1 → E3 → E8 → E5 → E6 → E7 (E2/E4 are pure-server wins shippable this week; E1/E3 give the daily-wow; E5 closes the records-accuracy loop).

## PART 3 — Pitch deck claims vs reality

Slide-by-slide scorecard of every functional claim. ✓ = live + verified this week. ⚠ = partial. ✗ = not built.

### Slide 3-4: the 95% chain (the deck's core promise)
| Claim | Status | Notes / Action |
|---|---|---|
| Sources vetted pros | ✓ | find-local-vendors + playbook pre-analysis + cockpit bench + certification flow |
| Gets quotes / compares quotes | ⚠ | Operator gathers + email intake works; project-level QuoteComparisonView exists. The concierge quote PROPOSAL is single-vendor; the deck's implied in-thread comparison needs the multi-quote proposal (C2) |
| Sends one to approve | ✓ | Proposal cards; the approve→vendor-memory loop was dead in prod until this week's fixes (now verified live) |
| Books the visit | ✓ | date_slot approve → scheduled visit (live-verified) |
| **Verifies the price** | ⚠ | analyze-quote does AI fair-market on uploaded quotes; registry comparables now feed get_quote playbook. BUT the deck's hero card shows "Fair-market $380-$470" ON the proposal — ChezProposalCard has no fair-market band today (C1) |
| Tracks it to done | ✓ | Visit lifecycle + new completion facts (on-time/no-show/final cost) |
| **Files the invoice** | ⚠ | Email invoice → document works; the automatic invoice→tasks/service-record intelligence on the email path is E4; operator-side filing via workbench exists |
| Negotiates the price | ✓ | draft-negotiation-email + counter composer + vendor outreach loop |
| **Handles the billing** | ✗ | No payment rails (Stripe test mode). The single biggest claim/reality gap (C3) |
| Hand off TASKS/VENDORS/ROUTINES/SYSTEMS/PROJECTS | ✓ | All five entity delegations + go-all-in verified live this week |

### Slide 5: business model lines (forward-looking — needs rails before "network revenue on" at month 18-24)
- Coordination take-rate ✗ (needs billing rails C3) · Membership ✗ (subscription unbuilt) · Verified partner network ⚠ (verification live; pay-to-join unbuilt) · Qualified leads ✗ · Advertising ✗ · **Market intelligence ⚠ (the foundation shipped this week: registry, outcomes, pricing capture — anonymized export layer unbuilt)** · White-label ✗. Deck-appropriate as model slides; C3+C4 sequence them.

### Slide 7 (four-quadrant winner): ✓ all four quadrants genuinely covered. Defensible.
### Slide 8 (one operator, AI does the prep): ✓ and now MEASURABLE (playbooks pre-warm 100% of categories; effort/case + homes/operator land in ops views). Investor-ready metric feed exists as of this week.
### Slide 10 ("built and running today"): all four bullets true (verified). Two diligence-hardening notes: "35+ AI edge functions" → actually 64 (undersell, fine); "live pilot... coordinated jobs" → start counting jobs through the case system NOW (the views exist; the history is thin: 5 homes, first tracked visits created this week). Same integrity thread as CHEZ_MISSION_GAPS X1.

## PART 4 — Deck rectification builds

| # | Gap | Build | Effort |
|---|---|---|---|
| C1 | Fair-market band on proposals (deck hero card) | Proposal payload gains `fair_market_low/high_cents` + source; cockpit composer prefills from analyze-quote (when a quote doc exists) or registry comparables (avg quoted/final for category+town); ChezProposalCard renders "Quoted $420 · Fair-market $380-$470" with the existing salmon-free discipline. Server+cockpit first, iOS band second | 2-3d |
| C2 | Multi-quote comparison in-thread | Quote proposal kind gains `alternatives[]` (vendor, total, note); iOS card renders a compact "1 of 3 quotes" strip. Defer iOS until Tasks-tab WIP lands; cockpit + payload can ship dark | 2-3d |
| C3 | **Billing rails** (take-rate + membership) | Stripe live keys; per-job coordination fee on case resolution (final_cost_cents × rate, invoice via Stripe); membership subscription product; GMV ledger view (coordinated GMV = sum of final_cost_cents — already capturable since this week). This is its own phase; schedule before any paid-conversion milestone | 1-2wk |
| C4 | Market-intelligence export layer | Anonymized aggregates over registry + outcomes (category × region pricing, reliability). Build AFTER volume exists; schema already produces the inputs | later |
| C5 | Metrics for diligence | Stand up the "key metrics we run on" (slide 9: coordinated GMV, blended take-rate, homes/operator, NRR) as saved SQL views; first two depend on C3, homes/operator ships now from chez_case_effort + households | 1d now, rest w/ C3 |

## PART 5 — Sequencing recommendation

1. **This week (server-only, no iOS risk):** E2, E4, E7, E1-server, C5-now. Every forwarded quote/invoice starts compounding records immediately.
2. **Next iOS window (post Tasks-tab WIP):** E1-card, E3, E8/C1 band, E5 replace flow.
3. **Pre-revenue milestone:** C3 billing rails, then C2, then slide-5 lines in order of take-rate → membership → partner-pay.
4. **Standing rule the deck now depends on:** every coordinated job flows through a case with an outcome (this week's required resolve form) — that is what makes "coordinated GMV" and "homes per operator" real numbers instead of deck numbers.
