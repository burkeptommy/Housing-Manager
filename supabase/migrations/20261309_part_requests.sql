-- Wave M12 — "Need part" flow (mid-visit operator coordination)
--
-- Field tech realizes mid-visit they need a part: a 1/2-inch copper
-- compression fitting, a specific gas valve, a thermostat their truck
-- doesn't carry. They tap "Need part" on the visit (or on a specific
-- punch item) → the request lands here → operator sees it on the Routes
-- screen in real time → operator dispatches another tech with the part
-- OR orders it with a supplier ETA OR marks it fulfilled.
--
-- Two scopes per request:
--   - Visit-level: request_id non-null, punch_item_id null. Tech needs
--     the part for "this whole visit" (e.g. came to do a leak repair,
--     turns out they need a part to finish).
--   - Punch-item-level: request_id null, punch_item_id non-null. Tech
--     identified the specific punch item that's blocked. Operator can
--     trace exactly which line item the part unblocks.
--
-- Either is set, never both empty. Server validates this in
-- create_part_request — DB constraint left out so a row can also exist
-- with both set (a punch item that lives on a specific request) without
-- needing a CHECK to permit it.

CREATE TABLE IF NOT EXISTS public.provider_part_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  request_id UUID REFERENCES public.handyman_requests(id) ON DELETE SET NULL,
  punch_item_id UUID REFERENCES public.handyman_punch_items(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  urgency TEXT NOT NULL DEFAULT 'next_visit'
    CHECK (urgency IN ('blocking_now', 'next_visit', 'order_for_stock')),
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'ordered', 'in_truck', 'fulfilled', 'cancelled')),
  supplier TEXT,
  supplier_eta TIMESTAMPTZ,
  fulfilled_at TIMESTAMPTZ,
  requested_by_member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS provider_part_requests_workspace_idx
  ON public.provider_part_requests(workspace_id);

CREATE INDEX IF NOT EXISTS provider_part_requests_request_idx
  ON public.provider_part_requests(request_id);

-- Partial index for the hot path: "open part requests for this
-- workspace." Drives the Today-screen pill on iOS + the Routes-screen
-- "Part Requests" sub-section on Operations Desk.
CREATE INDEX IF NOT EXISTS provider_part_requests_open_idx
  ON public.provider_part_requests(workspace_id, status)
  WHERE status = 'open';

ALTER TABLE public.provider_part_requests ENABLE ROW LEVEL SECURITY;

-- Mirrors the workspace-RW pattern from
-- `provider_visit_pauses` / `provider_visit_tech_notes` / `crew_chat_*`.
-- A workspace member sees rows when their workspace shows up in
-- public.get_my_provider_workspace_ids() and writes are gated the same
-- way. The handyman-provider edge function double-gates via
-- assertWorkspaceAccess so direct PostgREST writes (which we don't ship
-- today) would still carry the workspace check.
DROP POLICY IF EXISTS "workspace_members_can_rw" ON public.provider_part_requests;
CREATE POLICY "workspace_members_can_rw"
  ON public.provider_part_requests
  FOR ALL
  USING (workspace_id IN (SELECT public.get_my_provider_workspace_ids()))
  WITH CHECK (workspace_id IN (SELECT public.get_my_provider_workspace_ids()));
