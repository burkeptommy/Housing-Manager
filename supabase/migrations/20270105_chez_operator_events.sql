-- Phase 100 — Chez Intelligence Foundation, part E: operator effort
-- signal.
--
-- The 100-homes-per-operator goal needs a denominator: minutes of
-- operator attention per case. The cockpit emits lightweight events
-- (case opened / closed, reply sent, call logged) and chez_case_effort
-- derives session minutes from open-interval gaps, capped so an
-- overnight tab does not poison the metric. The resolve form's
-- operator_minutes quick-pick is authoritative when present.
--
-- NOT chez_workbench_actions because that table is homeowner-readable
-- by design (it feeds the iOS activity feed) and its entity_type CHECK
-- has no fitting case. Operator telemetry is operator-only.

CREATE TABLE IF NOT EXISTS public.chez_operator_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.chez_requests(id) ON DELETE CASCADE,
    household_id UUID REFERENCES public.households(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'case_opened', 'case_closed', 'reply_sent', 'call_logged'
    )),
    operator_user_id UUID REFERENCES auth.users(id),
    client_session_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chez_operator_events_request
    ON public.chez_operator_events(request_id, created_at);
CREATE INDEX IF NOT EXISTS idx_chez_operator_events_created
    ON public.chez_operator_events(created_at DESC);

ALTER TABLE public.chez_operator_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin manages operator events" ON public.chez_operator_events;
CREATE POLICY "Admin manages operator events"
    ON public.chez_operator_events FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

-- Derived effort per case. Each case_opened interval is capped at 30
-- minutes; the explicit resolve-form quick-pick wins when present.
CREATE OR REPLACE VIEW public.chez_case_effort
WITH (security_invoker = true) AS
WITH sessions AS (
    SELECT request_id, event_type, created_at,
           lead(created_at) OVER (PARTITION BY request_id ORDER BY created_at) AS next_at
    FROM public.chez_operator_events
)
SELECT r.id AS request_id,
       COALESCE(
           o.operator_minutes::int,
           ceil(COALESCE(
               sum(LEAST(extract(epoch FROM (s.next_at - s.created_at)), 1800))
                   FILTER (WHERE s.event_type = 'case_opened' AND s.next_at IS NOT NULL),
               0
           ) / 60.0)::int
       ) AS effort_minutes,
       count(*) FILTER (WHERE s.event_type = 'case_opened') AS open_count,
       count(*) FILTER (WHERE s.event_type = 'reply_sent') AS replies_sent,
       count(*) FILTER (WHERE s.event_type = 'call_logged') AS calls_logged
FROM public.chez_requests r
LEFT JOIN sessions s ON s.request_id = r.id
LEFT JOIN public.chez_request_outcomes o ON o.request_id = r.id
GROUP BY r.id, o.operator_minutes;

GRANT SELECT ON public.chez_case_effort TO authenticated;
