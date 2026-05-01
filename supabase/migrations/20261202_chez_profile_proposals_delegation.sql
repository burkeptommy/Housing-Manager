-- Phase 80.1: Chez Concierge depth — household profile, structured
-- proposals, and recurring delegation. Builds on top of the Phase 80
-- (20261201) foundation so the concierge service feels like an actual
-- relationship rather than a request-by-request triage queue.
--
-- New shapes:
--   • households.chez_profile      — JSONB blob of standing instructions,
--                                    spending tiers, vendor preferences,
--                                    household logistics. Single source
--                                    of truth Chez reads on every request.
--   • concierge_messages.proposal  — JSONB structured proposal payload
--                                    (vendor / date / cost / quote variants)
--                                    with status pending/approved/declined.
--   • concierge_messages.proposal_kind — denormalized for filtering.
--   • routines.chez_owned          — when true, Chez owns scheduling for
--                                    this routine (vendor visits land on
--                                    the calendar without per-visit asks).
--   • contractors.chez_owned       — when true, Chez is the homeowner's
--                                    point of contact for this vendor.

-- ============================================================================
-- 1. households.chez_profile
-- ============================================================================

ALTER TABLE public.households
    ADD COLUMN IF NOT EXISTS chez_profile JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Shape (illustrative — schema is intentionally flexible JSONB):
--
-- {
--   "about_us": "Free-form 'About this household' text. The HNW family,
--                their pets, their access notes, their preferences. Chez
--                reads this on every request.",
--   "communication": {
--     "preferred_channel": "email" | "sms" | "either",   -- default "either"
--     "no_calls_before": "09:00",                          -- 24h string
--     "no_calls_after": "20:00",
--     "vacation_mode": false,
--     "vacation_notes": "Out of town Aug 1-15, full latitude during window"
--   },
--   "vendor_preferences": {
--     "budget_orientation": "budget" | "standard" | "premium",
--     "prefer_local_owned": false,
--     "avoid_chains": false,
--     "notes": "Free-form vendor preferences (gender of contractor,
--              language, license requirements, etc.)"
--   },
--   "logistics": {
--     "has_pets": true,
--     "pet_notes": "Friendly dog. Lock back gate when leaving.",
--     "entry_instructions": "Side gate, key code 1234. Front door is for
--                            family only — vendors use side entrance.",
--     "vendor_access_notes": "Free-form additional access info"
--   },
--   "spending_tiers": {
--     "auto_approve_under": 200,    -- USD whole dollars
--     "ping_under": 500,            -- ping me before booking
--     "explicit_above": 500,        -- explicit approval required
--     "currency": "USD"
--   },
--   "_completion": {
--     "filled_at": "2026-05-01T...",  -- first complete fill timestamp
--     "last_edited_at": "..."
--   }
-- }

CREATE INDEX IF NOT EXISTS idx_households_chez_profile_filled
    ON public.households((chez_profile->'_completion'->>'filled_at'))
    WHERE chez_profile->'_completion'->>'filled_at' IS NOT NULL;

-- ============================================================================
-- 2. concierge_messages.proposal — structured Chez-side proposals
-- ============================================================================

ALTER TABLE public.concierge_messages
    ADD COLUMN IF NOT EXISTS proposal JSONB;

-- Optional discriminator denormalized for query/filter ergonomics. iOS
-- inspects this column directly to decide whether to render the
-- `ChezProposalCard` inline. Server-side enforcement is via the
-- Edge Function only — no DB CHECK so future kinds add cheaply.
ALTER TABLE public.concierge_messages
    ADD COLUMN IF NOT EXISTS proposal_kind TEXT;

CREATE INDEX IF NOT EXISTS idx_concierge_messages_proposal_kind
    ON public.concierge_messages(proposal_kind)
    WHERE proposal_kind IS NOT NULL;

-- Proposal shape (illustrative):
--
-- {
--   "kind": "vendor" | "date_slot" | "cost" | "quote",
--   "status": "pending" | "approved" | "declined" | "countered",
--   "decided_at": "..."   -- stamped when status flips off pending
--   "vendor": {           -- for kind="vendor"
--     "name": "Smith Plumbing",
--     "phone": "555-1234",
--     "rating": 4.7,
--     "review_count": 142,
--     "estimated_cost": 400,
--     "estimated_window": "Tue 2pm-4pm",
--     "rationale": "Same-day availability, A+ BBB, no chain"
--   },
--   "date_slot": {        -- for kind="date_slot"
--     "options": [
--       {"label": "Tue 2pm", "iso": "2026-..."},
--       {"label": "Wed 9am", "iso": "2026-..."}
--     ]
--   },
--   "cost": {             -- for kind="cost"
--     "amount": 400,
--     "currency": "USD",
--     "scope": "Replace kitchen faucet",
--     "vendor_name": "Smith Plumbing"
--   },
--   "quote": {            -- for kind="quote" (multi-line bid)
--     "vendor_name": "Smith Plumbing",
--     "total": 1200,
--     "line_items": [{"label": "Labor", "amount": 800}, ...],
--     "valid_until": "..."
--   }
-- }

-- ============================================================================
-- 3. routines.chez_owned + contractors.chez_owned — recurring delegation
-- ============================================================================

ALTER TABLE public.routines
    ADD COLUMN IF NOT EXISTS chez_owned BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.routines
    ADD COLUMN IF NOT EXISTS chez_owned_at TIMESTAMPTZ;

ALTER TABLE public.contractors
    ADD COLUMN IF NOT EXISTS chez_owned BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.contractors
    ADD COLUMN IF NOT EXISTS chez_owned_at TIMESTAMPTZ;

-- Indexes for the admin portal's "Standing engagements" filter.
CREATE INDEX IF NOT EXISTS idx_routines_chez_owned
    ON public.routines(household_id, chez_owned)
    WHERE chez_owned = true;

CREATE INDEX IF NOT EXISTS idx_contractors_chez_owned
    ON public.contractors(household_id, chez_owned)
    WHERE chez_owned = true;

-- ============================================================================
-- 4. chez_requests.proposal_count — denormalized for the list view
-- ============================================================================
-- The list view wants to show "1 proposal awaiting your decision" without
-- fanning out a query per row. A simple counter that the Edge Function
-- maintains keeps the list paint cheap.

ALTER TABLE public.chez_requests
    ADD COLUMN IF NOT EXISTS pending_proposal_count INTEGER NOT NULL DEFAULT 0;
