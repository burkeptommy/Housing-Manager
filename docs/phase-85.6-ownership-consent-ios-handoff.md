# Phase 85.6 — Ownership Consent Flow (iOS handoff)

**Server + admin portal: shipped (2026-05-14). iOS work: pending in a separate chat.**

## What landed server-side

A new proposal kind `ownership_request` flows through the existing
`concierge_messages.proposal` JSONB column, decided through the existing
`decide_proposal` action. iOS already renders proposal cards via
`ChezProposalCard.swift` — this is an additive `kind`, not a new
infrastructure path.

### Schema (`supabase/migrations/20261317_chez_ownership_consent.sql`)

1. `chez_requests.category` CHECK extended to include `'ownership_request'`
2. New table `chez_dismissed_ownership_proposals`:
   - `household_id`, `entity_type`, `entity_id`, `proposal_request_id`,
     `note`, `declined_at`, `expires_at` (defaults to now + 60d)
   - When a homeowner declines, one row per declined entity is inserted.
     The admin portal won't let an operator re-propose ownership of an
     entity until `expires_at` passes.
3. `pending_ownership_request_id UUID` column added to 8 entity tables:
   `maintenance_tasks`, `routines`, `contractors`, `home_systems`,
   `property_projects`, `documents`, `utility_accounts`, `vehicles`
   - Points at the `chez_requests` row that holds the open proposal.
     Cleared on approve (chez_owned flips true via the existing
     `delegate_*` flow) or decline (cooldown row inserted).

### Edge Function — `chez-concierge`

1. **New action `propose_ownership`** (admin only):
   - Payload: `{ household_id, entities: [{entity_type, entity_id, label?, property_id?}], preface?, request_id? }`
   - Creates a `chez_requests` row with `category=ownership_request` (or
     reuses one if `request_id` is provided — for bulk batched proposals)
   - Inserts a concierge message with `proposal_kind=ownership_request`
     and a `proposal` JSONB containing the entity list
   - Stamps `pending_ownership_request_id` on each entity row
   - Sends push to the homeowner ("Chez wants to help — Approve Chez to take over X?")
   - Skips entities on active cooldown and reports them in the response
   - Max 50 entities per proposal (server-enforced)

2. **`decide_proposal` extended** to handle `kind=ownership_request`:
   - On `approved` → walks the proposal's `entities[]` array; for each
     entity, flips `chez_owned=true` and clears `pending_ownership_request_id`
   - On `declined` → inserts a row into `chez_dismissed_ownership_proposals`
     per entity (60-day cooldown by default), clears pointer
   - On `countered` → just clears pointer (admin re-pitches manually)
   - Insurance entities special-cased (lives on `properties.chez_owned_insurance` JSONB)

## What the iOS side needs to build

### 1. New `ChezProposal` Codable variant

The existing `ChezProposal` (in `Haven/Features/ChezRequests/Models/ChezMessage.swift`)
has a `kind` enum: `vendor | date_slot | cost | quote`. Add a fifth case
`ownership_request`.

The payload shape on the wire is:

```jsonc
{
  "kind": "ownership_request",
  "status": "pending" | "approved" | "declined" | "countered",
  "decided_at": "2026-05-14T18:00:00Z",   // optional, set on decide
  "entities": [
    {
      "entity_type": "system",
      "entity_id": "uuid-of-the-home-system",
      "label": "Hybrid Water Heater",
      "property_id": "uuid"  // present only when entity_type == "insurance"
    },
    { "entity_type": "routine", "entity_id": "uuid", "label": "Blue Fox Landscaping" },
    ...
  ]
}
```

Add a Swift struct `ChezOwnershipRequestProposal`:

```swift
struct ChezOwnershipRequestProposal: Codable, Hashable {
    let kind: String              // always "ownership_request"
    let status: String            // "pending" | "approved" | "declined" | "countered"
    let decided_at: String?
    let entities: [ChezOwnershipRequestEntity]

    // Resilient init — every nested field wrapped in try? c.decodeIfPresent
    // per the codebase rule (CLAUDE.md "resilient decoders for every
    // externally-fed struct").
}

struct ChezOwnershipRequestEntity: Codable, Hashable {
    let entity_type: String       // "task" | "routine" | "contractor" | "system" | "project" | "document" | "utility" | "vehicle" | "insurance"
    let entity_id: String
    let label: String
    let property_id: String?
}
```

Wire the new variant into `ChezProposal.init(from: Decoder)` so it
decodes alongside the existing kinds.

### 2. New variant on `ChezProposalCard.swift`

Add a renderer for the `ownership_request` kind:

- **Header:** "Chez wants to handle this for you" (or for batched: "Chez wants to handle N items for you")
- **Body:** List one row per entity with the appropriate SF Symbol per
  type + label. For batched (≥2 entities), make the list scrollable.
- **Three action buttons:**
  - **Approve all** (salmon primary) → calls `decide_proposal` with
    `decision: "approved"`. On success, the existing card-decided flow
    refreshes the inbox + the affected entities flip `chez_owned: true`.
  - **Decline** (navy outline) → opens a small "Why?" sheet capturing
    optional note text, then calls `decide_proposal` with
    `decision: "declined"`. Server inserts cooldown rows.
  - **Counter** (ghost link) → opens a "Just some of these" sheet that
    lets the homeowner check a subset of entities to approve. The
    selected subset becomes a new approved proposal; the unchecked
    subset is treated as declined (with cooldown). Server-side: this
    is currently NOT implemented as a partial approval — for v1 we
    just have approve-all / decline-all. **Optional ship target —
    can defer to a later phase.**

### 3. Activity-feed entry on approve

After approval, the existing `delegate_*` flow inserts the same
"Standing engagement" parent-request system message it always has.
The homeowner's `ChezActivityFeedView` (if/when it ships) will pick
this up via the existing `chez_workbench_actions` table observer.

No new push types — the existing `chez_request_reply` push from
`propose_ownership` lands the homeowner on the case detail where the
proposal card lives.

## How to verify end-to-end

1. **From admin**: open any Households workbench focused panel. The
   "Propose Chez ownership" button is salmon, not navy. Click → modal
   asks for optional preface → click "Send proposal".
2. **From server**: confirm a row lands in `chez_requests` with
   `category='ownership_request'` and a message in `concierge_messages`
   with `proposal_kind='ownership_request'`.
3. **From admin** (re-open the panel): the same button now reads
   "Awaiting homeowner approval" in muted style. Tapping it jumps to
   the cockpit case thread.
4. **From iOS**: homeowner sees the new proposal card in their inbox
   for the case. Tap Approve → server fires `decide_proposal` →
   `chez_owned=true` on the entity → admin badge appears + pending
   pointer clears.
5. **Decline path**: tap Decline → server inserts cooldown row →
   admin attempt to re-propose within 60d → 409 response with the
   cooldown explanation.

## Files touched

**Migrations:**
- `supabase/migrations/20261317_chez_ownership_consent.sql`

**Edge Function:**
- `supabase/functions/chez-concierge/index.ts`
  - New: `handleProposeOwnership`, `ProposeOwnershipPayload` interface
  - Extended: `handleDecideProposal` (new branch on `kind === "ownership_request"`)
  - Wired into dispatcher: `case "propose_ownership":`

**Admin portal:**
- `website/admin.js`
  - New: `renderOwnershipPill(entity)`, `openProposeOwnershipModal(...)`
  - Rewrote: focused-panel toggle-owned click handler — three-state
    dispatcher (owned / pending / propose)
  - All 8 focused renderers (Task / System / Routine / Vendor /
    Project / Document / Bill / Vehicle) now call
    `renderOwnershipPill()` instead of the inline ternary

**iOS:** TBD in a separate chat (see "What the iOS side needs to build"
above).

## What's deliberately NOT in this phase

- **Bulk-batched propose from admin UI** — server supports up to 50
  entities in one proposal, but the admin portal currently only proposes
  one at a time (per focused-panel button click). A future PR adds a
  "Propose ownership of all 16 systems" button on the workbench tab
  header that batches per tab.
- **Group-toggle integration** — `set_ownership_group` (the "Chez
  handles all my X" action) still flips ownership directly. Should be
  refactored to route through `propose_ownership` in a follow-up.
- **Partial-approval (counter)** — homeowner can't selectively approve
  some entities from a batched proposal. Approve-all / decline-all only.
- **Re-pitch UX after cooldown expires** — once the 60d cooldown ends,
  the admin button becomes proposable again, but there's no nudge to
  re-pitch. Could surface as a workbench banner ("3 entities are
  re-proposable").
