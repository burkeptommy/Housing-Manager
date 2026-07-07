-- Phase 100 — Chez Intelligence Foundation, part I: ops metrics views.
--
-- The numbers that prove (or disprove) the 20-homes-per-operator to
-- 100-homes trajectory: response and resolution speed, SLA hit rate,
-- operator touches per case, automation rate, and per-category playbook
-- conversion. Plain views over existing rows; fetch_ops_metrics reads
-- them for the cockpit Insights strip. Pre-foundation cases simply have
-- null outcome fields (LEFT JOIN), no backfill.

CREATE OR REPLACE VIEW public.chez_case_metrics
WITH (security_invoker = true) AS
SELECT r.id, r.household_id, r.category, r.status,
       r.created_at, r.resolved_at, r.sla_due_at,
       fr.first_human_response_at,
       (fr.first_human_response_at IS NOT NULL
        AND r.sla_due_at IS NOT NULL
        AND fr.first_human_response_at <= r.sla_due_at) AS sla_hit,
       CASE WHEN fr.first_human_response_at IS NOT NULL
            THEN extract(epoch FROM (fr.first_human_response_at - r.created_at)) / 60.0 END AS first_response_minutes,
       CASE WHEN r.resolved_at IS NOT NULL
            THEN extract(epoch FROM (r.resolved_at - r.created_at)) / 3600.0 END AS resolution_hours,
       cm.concierge_msg_count,
       (r.status = 'resolved' AND cm.concierge_msg_count <= 1) AS automation_proxy,
       (cm.concierge_msg_count
        + wb.workbench_count
        + vc.calls_logged
        + vo.outbound_emails) AS operator_touches,
       o.resolution_type, o.final_cost_cents, o.operator_minutes,
       o.automation_candidate, o.friction_tags
FROM public.chez_requests r
LEFT JOIN LATERAL (
    SELECT min(created_at) AS first_human_response_at
    FROM public.concierge_messages
    WHERE request_id = r.id AND role = 'concierge'
) fr ON true
LEFT JOIN LATERAL (
    SELECT count(*) AS concierge_msg_count
    FROM public.concierge_messages
    WHERE request_id = r.id AND role = 'concierge'
) cm ON true
LEFT JOIN LATERAL (
    SELECT count(*) AS workbench_count
    FROM public.chez_workbench_actions
    WHERE request_id = r.id
) wb ON true
LEFT JOIN LATERAL (
    SELECT count(*) FILTER (WHERE outcome IS NOT NULL) AS calls_logged
    FROM public.chez_vendor_calls
    WHERE request_id = r.id
) vc ON true
LEFT JOIN LATERAL (
    SELECT count(*) FILTER (WHERE direction = 'outbound') AS outbound_emails
    FROM public.chez_vendor_outreach
    WHERE request_id = r.id
) vo ON true
LEFT JOIN public.chez_request_outcomes o ON o.request_id = r.id
WHERE r.merged_into_request_id IS NULL;

CREATE OR REPLACE VIEW public.chez_weekly_ops
WITH (security_invoker = true) AS
SELECT date_trunc('week', created_at) AS week,
       category,
       count(*) AS opened,
       count(*) FILTER (WHERE status = 'resolved') AS resolved,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY first_response_minutes) AS median_first_response_minutes,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY resolution_hours) AS median_resolution_hours,
       avg(CASE WHEN sla_hit THEN 1.0 ELSE 0.0 END) AS sla_hit_rate,
       avg(operator_touches) AS avg_touches,
       avg(CASE WHEN automation_proxy THEN 1.0 ELSE 0.0 END) AS automation_rate,
       avg(final_cost_cents) FILTER (WHERE final_cost_cents IS NOT NULL) AS avg_final_cost_cents
FROM public.chez_case_metrics
GROUP BY 1, 2;

-- Per-category playbook funnel: submitted → pre-analyzed (playbook ran)
-- → proposal sent → proposal approved → visit completed → resolved with
-- a structured outcome. The conversion deltas tell us which playbooks
-- earn their automation and which categories still leak operator time.
CREATE OR REPLACE VIEW public.chez_playbook_funnel
WITH (security_invoker = true) AS
SELECT r.category,
       count(*) AS submitted,
       count(*) FILTER (WHERE r.analysis_cache_at IS NOT NULL) AS pre_analyzed,
       count(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM public.concierge_messages m
           WHERE m.request_id = r.id AND m.proposal_kind IS NOT NULL
       )) AS proposal_sent,
       count(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM public.concierge_messages m
           WHERE m.request_id = r.id AND m.proposal->>'status' = 'approved'
       )) AS proposal_approved,
       count(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM public.chez_visits v
           WHERE v.request_id = r.id AND v.state = 'completed'
       )) AS visit_completed,
       count(*) FILTER (WHERE o.id IS NOT NULL) AS resolved_with_outcome
FROM public.chez_requests r
LEFT JOIN public.chez_request_outcomes o ON o.request_id = r.id
WHERE r.merged_into_request_id IS NULL
GROUP BY r.category;

GRANT SELECT ON public.chez_case_metrics, public.chez_weekly_ops, public.chez_playbook_funnel TO authenticated;
