-- Phase 83.3 — Chez memory: persist learnings to the contractor catalog
-- when a homeowner approves a vendor we sourced.
--
-- The cockpit's "Resolve this case" card needs a real "completed visit"
-- end-state: source vendors → call them → propose → homeowner picks →
-- visit happens → vendor lives in the household forever.
--
-- The picking step is where memory crosses from "case scratchpad" into
-- "household truth." Up until approval, vendor candidates live in
-- ephemeral state (analysis cache + chez_vendor_calls). Once the
-- homeowner approves, we write them to the canonical `contractors`
-- table so:
--   • iOS Contacts directory immediately shows "Sourced by Chez"
--   • Vendor Coverage closes the gap (system gets a vendor)
--   • Future Chez requests can match against this household's vendors
--   • The reconciler links matching tasks to the vendor automatically
--
-- This migration adds the provenance fields. The Edge Function update
-- in chez-concierge does the actual upsert on `decide_proposal`.

ALTER TABLE public.contractors
  ADD COLUMN IF NOT EXISTS chez_request_id UUID REFERENCES public.chez_requests(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS chez_recommended_at TIMESTAMPTZ;

COMMENT ON COLUMN public.contractors.chez_request_id IS
  'Chez Concierge case that sourced this vendor. Set when the homeowner approves a Chez vendor proposal. Null for vendors added by the homeowner directly.';
COMMENT ON COLUMN public.contractors.chez_recommended_at IS
  'When Chez first recommended this vendor and the homeowner approved. Drives the "Sourced by Chez" badge on the contact card.';

-- Phase 82's chez_visits already tracks the proposal message that spawned
-- the visit. Add a direct contractor FK so visit cards can deep-link to
-- the homeowner's saved contractor record without needing to chase the
-- proposal blob.
ALTER TABLE public.chez_visits
  ADD COLUMN IF NOT EXISTS contractor_id UUID REFERENCES public.contractors(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.chez_visits.contractor_id IS
  'The persisted contractor record for the vendor on this visit. Stamped when the homeowner approves a vendor proposal — the contractor is upserted at the same moment the visit is created.';

-- Fast filter: "vendors Chez sourced for this household, most recent first."
-- Drives a Phase 83.3 cockpit panel showing the homeowner's Chez-sourced
-- vendors at a glance.
CREATE INDEX IF NOT EXISTS idx_contractors_chez_recommended
  ON public.contractors(household_id, chez_recommended_at DESC)
  WHERE chez_recommended_at IS NOT NULL;
