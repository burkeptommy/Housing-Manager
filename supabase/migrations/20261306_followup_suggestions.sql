-- Wave M8 — End-of-visit suggestion authoring
--
-- After a tech completes a visit on the Chez Field iOS app, the
-- end-of-visit wizard lets them propose follow-up work that drives
-- recurring revenue:
--   • a follow-up maintenance task for the homeowner's task list
--   • a draft quote (opened from the originating visit) that the tech
--     finishes building via the M4 quote builder
--   • a new visit slot they'd like to come back for
--
-- Each artifact is tagged with the originating handyman_request id so
-- the homeowner-side surfaces (and the Operations Desk) can render a
-- "Suggested by visit" badge and so the audit trail can connect the
-- new row back to the visit it came from.
--
-- We don't constrain the new `source` column on maintenance_tasks with
-- a check, because the existing column on the table doesn't exist yet
-- and other downstream writers (curator, reconciler, Day1 router) will
-- want to stamp their own values without a migration ping-pong. Soft
-- text matches the codebase pattern.

-- 1. maintenance_tasks: provenance + cross-link.
ALTER TABLE public.maintenance_tasks
  ADD COLUMN IF NOT EXISTS source TEXT,
  ADD COLUMN IF NOT EXISTS suggested_by_request_id UUID REFERENCES public.handyman_requests(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS suggested_by_workspace_id UUID REFERENCES public.provider_workspaces(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS suggested_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS maintenance_tasks_suggested_by_request_idx
  ON public.maintenance_tasks(suggested_by_request_id)
  WHERE suggested_by_request_id IS NOT NULL;

-- 2. provider_quotes: cross-link from a visit-originated quote draft.
--    `request_id` already exists for "this quote is FOR a request"; the
--    new column is "this quote was SUGGESTED at the end of THIS visit's
--    request" so the operator UI can surface the badge even when the
--    homeowner-facing request_id is the same row (the suggesting tech
--    might be quoting work for the same visit they just completed).
ALTER TABLE public.provider_quotes
  ADD COLUMN IF NOT EXISTS suggested_by_request_id UUID REFERENCES public.handyman_requests(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS suggested_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS provider_quotes_suggested_by_request_idx
  ON public.provider_quotes(suggested_by_request_id)
  WHERE suggested_by_request_id IS NOT NULL;

-- 3. handyman_requests: cross-link from a tech-suggested follow-up
--    visit. parent_request_id already exists for hierarchical
--    proposal flows (M9 follow-up visits with approval); the new
--    suggested_by_request_id is the lighter "tech suggested another
--    visit to handle the boiler relief valve" link without spinning up
--    the full proposal/expiration/approval ceremony.
ALTER TABLE public.handyman_requests
  ADD COLUMN IF NOT EXISTS suggested_by_request_id UUID REFERENCES public.handyman_requests(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS suggested_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS handyman_requests_suggested_by_request_idx
  ON public.handyman_requests(suggested_by_request_id)
  WHERE suggested_by_request_id IS NOT NULL;
