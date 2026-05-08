-- Wave M6 — Field UX polish
--
-- Internal tech-to-tech notes scoped to a single visit. Distinct from the
-- customer-visible thread on `handyman_request_messages` so a tech can
-- jot "Customer pushed back on price, recommend follow-up" without it
-- ever surfacing on the homeowner's iOS app.
--
-- Authoring: any active workspace member can read + write notes for any
-- request linked to a contractor in their workspace. Auth is enforced by
-- the edge function via assertWorkspaceAccess(), AND by RLS via the
-- helper public.get_my_provider_workspace_ids() so PostgREST direct
-- reads (Operations Desk SPA) work without going through the function.

CREATE TABLE IF NOT EXISTS public.provider_visit_tech_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  request_id UUID NOT NULL REFERENCES public.handyman_requests(id) ON DELETE CASCADE,
  author_member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS provider_visit_tech_notes_request_idx
  ON public.provider_visit_tech_notes(request_id);

CREATE INDEX IF NOT EXISTS provider_visit_tech_notes_workspace_idx
  ON public.provider_visit_tech_notes(workspace_id);

ALTER TABLE public.provider_visit_tech_notes ENABLE ROW LEVEL SECURITY;

-- The plan called for a self-referential check via
-- provider_workspace_members. We have a precomputed helper
-- get_my_provider_workspace_ids() shipped with the workspace member
-- migrations; using it keeps the policy fast and matches the rest of
-- the provider_* table policies.
CREATE POLICY "workspace_members_can_rw"
  ON public.provider_visit_tech_notes
  FOR ALL
  USING (workspace_id IN (SELECT public.get_my_provider_workspace_ids()))
  WITH CHECK (workspace_id IN (SELECT public.get_my_provider_workspace_ids()));
