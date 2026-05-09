-- Wave M9 — Visit edge cases (co-tech + lockbox/access + mid-stream cancellation)
--
-- Adds:
--   * provider_visit_assignments.co_tech_member_ids — UUID array of additional
--     workspace members assigned alongside the primary tech. Enables shared
--     punch-item check-off on the same assignment without creating duplicate
--     visit-assignment rows.
--   * provider_visit_assignments.access_method — entry method captured before
--     the visit so the tech knows whether the customer will be present, the
--     lockbox / key location, or the door code.
--   * provider_visit_assignments.access_notes — free-form notes for the access
--     method (e.g. "Side gate code 1234", "Key under flowerpot on porch").
--   * handyman_requests.cancellation_reason — free-form reason captured on a
--     mid-stream cancellation so dispatch and the homeowner have context.
--   * handyman_requests.cancelled_at — timestamp of cancellation. Distinct from
--     status='cancelled' (which already exists) so we can render the moment of
--     cancellation in audit trails.
--   * handyman_requests.cancelled_by_member_id — workspace-member FK so we can
--     attribute who pulled the plug.

ALTER TABLE public.provider_visit_assignments
  ADD COLUMN IF NOT EXISTS co_tech_member_ids UUID[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS access_method TEXT,
  ADD COLUMN IF NOT EXISTS access_notes TEXT;

ALTER TABLE public.handyman_requests
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_by_member_id UUID REFERENCES public.provider_workspace_members(id) ON DELETE SET NULL;

-- GIN index lets us efficiently look up assignments where a given member is
-- listed as a co-tech (e.g. "show me every visit where I'm assisting").
CREATE INDEX IF NOT EXISTS provider_visit_assignments_co_tech_idx
  ON public.provider_visit_assignments USING GIN (co_tech_member_ids);

COMMENT ON COLUMN public.provider_visit_assignments.co_tech_member_ids IS
  'Wave M9 — workspace member IDs assigned alongside the primary tech (member_id). Both can check off punch items.';
COMMENT ON COLUMN public.provider_visit_assignments.access_method IS
  'Wave M9 — entry method: customer_present | lockbox | key_under_mat | door_code.';
COMMENT ON COLUMN public.provider_visit_assignments.access_notes IS
  'Wave M9 — free-form notes for the access method (lockbox code, key location, etc.).';
COMMENT ON COLUMN public.handyman_requests.cancellation_reason IS
  'Wave M9 — free-form or structured reason captured when a visit is cancelled mid-stream.';
COMMENT ON COLUMN public.handyman_requests.cancelled_at IS
  'Wave M9 — timestamp of mid-stream cancellation, distinct from status=cancelled.';
COMMENT ON COLUMN public.handyman_requests.cancelled_by_member_id IS
  'Wave M9 — workspace member who initiated the cancellation.';
