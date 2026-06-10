-- Phase 101 — E2 + C5.
--
-- E2: quotes become real documents (vendor profile + project + vault);
-- project_quotes.document_id links the structured quote row to the
-- persisted PDF so either side can reach the other.
--
-- C5: the deck's "key metrics we run on" become queries. Coordinated
-- GMV derives from structured outcomes (final_cost_cents, captured by
-- the required resolve form) plus completed-visit costs; homes per
-- operator derives from active households over distinct operators seen
-- in effort telemetry. Blended take-rate lands with billing rails (C3).

ALTER TABLE public.project_quotes
    ADD COLUMN IF NOT EXISTS document_id UUID REFERENCES public.documents(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.project_quotes.document_id IS
    'The persisted quote document (documents row) this structured quote was parsed from. Set by process-inbox-item when a forwarded quote is filed to a project.';

CREATE OR REPLACE VIEW public.chez_business_metrics
WITH (security_invoker = true) AS
WITH active_homes AS (
    SELECT count(*) AS n FROM public.households
    WHERE archived_at IS NULL
), operators AS (
    SELECT greatest(count(DISTINCT operator_user_id), 1) AS n
    FROM public.chez_operator_events
    WHERE created_at > now() - interval '90 days'
), gmv AS (
    SELECT
        COALESCE(sum(final_cost_cents), 0) AS all_time_cents,
        COALESCE(sum(final_cost_cents) FILTER (WHERE created_at > now() - interval '30 days'), 0) AS last_30d_cents
    FROM public.chez_request_outcomes
    WHERE final_cost_cents IS NOT NULL
), visit_gmv AS (
    SELECT COALESCE(sum(final_cost_cents), 0) AS all_time_cents
    FROM public.chez_visits
    WHERE final_cost_cents IS NOT NULL AND state = 'completed'
), cases AS (
    SELECT
        count(*) FILTER (WHERE created_at > now() - interval '30 days') AS opened_30d,
        count(*) FILTER (WHERE status = 'resolved' AND resolved_at > now() - interval '30 days') AS resolved_30d
    FROM public.chez_requests
    WHERE merged_into_request_id IS NULL
)
SELECT
    active_homes.n AS active_households,
    operators.n AS operators_90d,
    round(active_homes.n::numeric / operators.n, 1) AS homes_per_operator,
    cases.opened_30d,
    cases.resolved_30d,
    gmv.all_time_cents AS coordinated_gmv_cents,
    gmv.last_30d_cents AS coordinated_gmv_30d_cents,
    visit_gmv.all_time_cents AS completed_visit_gmv_cents
FROM active_homes, operators, gmv, visit_gmv, cases;

GRANT SELECT ON public.chez_business_metrics TO authenticated;
