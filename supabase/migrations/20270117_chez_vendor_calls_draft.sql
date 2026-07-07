-- Wave 3 Phase B (Chez service rebuild) — server-side drafts for the
-- vendor call ledger.
--
-- The cockpit's call form previously relied on a fragile client-side
-- debounce + flush-on-visibilitychange to avoid persisting half-typed
-- notes. Drafts move that to the server: the portal saves per-row on
-- blur with draft=true (no call-history stamping), and flips the row to
-- final when an outcome is logged. Aggregate views ignore drafts so
-- half-typed candidates never pollute answer_rate / households_touched /
-- identity resolution.
ALTER TABLE public.chez_vendor_calls
    ADD COLUMN IF NOT EXISTS is_draft BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS draft_updated_at TIMESTAMPTZ;

COMMENT ON COLUMN public.chez_vendor_calls.is_draft IS
    'True while the operator is still typing (portal saves on blur). Finalized (false) when an outcome is logged. Draft rows are excluded from chez_vendor_identities / chez_vendor_registry.';

-- ---------------------------------------------------------------------------
-- Redefine the identity spine: draft rows are not identities yet.
-- (Full definition from 20270104 with the guard added to the calls branch.)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.chez_vendor_identities
WITH (security_invoker = true) AS
SELECT public.chez_vendor_key(c.google_place_id, c.phone, c.company_name, NULL) AS vendor_key,
       'contractor' AS source, c.id AS source_id, c.household_id,
       c.company_name AS name, c.phone, c.category,
       NULL::text AS town, NULL::text AS state_code,
       c.chez_recommended_at IS NOT NULL AS chez_sourced, c.created_at
FROM public.contractors c
UNION ALL
SELECT public.chez_vendor_key(v.google_place_id, v.vendor_phone, v.vendor_name, v.town),
       'call', v.id, v.household_id, v.vendor_name, v.vendor_phone, v.category,
       v.town, v.state, false, v.created_at
FROM public.chez_vendor_calls v
WHERE (NOT v.is_draft OR v.outcome IS NOT NULL)
UNION ALL
SELECT public.chez_vendor_key(NULL, o.vendor_phone, o.vendor_name, NULL),
       'outreach', o.id, o.household_id, o.vendor_name, o.vendor_phone, NULL,
       NULL, NULL, false, o.created_at
FROM public.chez_vendor_outreach o
UNION ALL
SELECT public.chez_vendor_key(a.linked_google_place_id, a.phone, a.business_name, NULL),
       'application', a.id, NULL, a.business_name, a.phone, a.category,
       NULL, NULL, false, a.created_at
FROM public.vendor_applications a
UNION ALL
SELECT public.chez_vendor_key(l.google_place_id, l.phone, l.vendor_name, l.town),
       'places_cache', l.id, NULL, l.vendor_name, l.phone, l.category,
       l.town, l.state, false, l.fetched_at
FROM public.local_vendor_results l;

-- ---------------------------------------------------------------------------
-- Redefine the registry: the calls CTE ignores drafts so households_touched
-- and avg_quoted_cost_cents never count half-typed rows. All other CTEs
-- unchanged from 20270104.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.chez_vendor_registry
WITH (security_invoker = true) AS
WITH calls AS (
    SELECT public.chez_vendor_key(google_place_id, vendor_phone, vendor_name, town) AS vendor_key,
           count(*) FILTER (WHERE outcome IS NOT NULL) AS times_called,
           count(*) FILTER (WHERE outcome = 'answered') AS times_answered,
           count(*) FILTER (WHERE outcome = 'not_a_fit') AS times_not_a_fit,
           count(*) FILTER (WHERE recommended) AS times_recommended,
           avg(quoted_cost_cents) FILTER (WHERE quoted_cost_cents IS NOT NULL) AS avg_quoted_cost_cents,
           max(last_called_at) AS last_called_at,
           count(DISTINCT household_id) AS households_touched
    FROM public.chez_vendor_calls
    WHERE (NOT is_draft OR outcome IS NOT NULL)
    GROUP BY 1
), wins AS (
    SELECT public.chez_vendor_key(c.google_place_id, c.phone, c.company_name, NULL) AS vendor_key,
           count(*) AS jobs_won
    FROM public.contractors c
    WHERE c.chez_recommended_at IS NOT NULL
    GROUP BY 1
), visit_stats AS (
    SELECT public.chez_vendor_key(NULL, v.vendor_phone, v.vendor_name, NULL) AS vendor_key,
           count(*) FILTER (WHERE v.state = 'completed') AS visits_completed,
           count(*) FILTER (WHERE v.no_show) AS no_shows,
           count(*) FILTER (WHERE v.state = 'completed' AND v.completed_on_time) AS on_time_completions,
           avg(v.final_cost_cents) FILTER (WHERE v.final_cost_cents IS NOT NULL) AS avg_final_cost_cents
    FROM public.chez_visits v
    GROUP BY 1
), outreach AS (
    SELECT public.chez_vendor_key(NULL, o.vendor_phone, o.vendor_name, NULL) AS vendor_key,
           count(*) FILTER (WHERE o.direction = 'outbound') AS emails_sent,
           count(*) FILTER (WHERE o.direction = 'inbound') AS emails_received,
           max(o.created_at) AS last_outreach_at
    FROM public.chez_vendor_outreach o
    GROUP BY 1
), ident AS (
    SELECT vendor_key,
           (array_agg(name ORDER BY created_at DESC) FILTER (WHERE name IS NOT NULL))[1] AS display_name,
           (array_agg(phone ORDER BY created_at DESC) FILTER (WHERE phone IS NOT NULL))[1] AS phone,
           array_remove(array_agg(DISTINCT lower(category)), NULL) AS categories,
           array_remove(array_agg(DISTINCT town), NULL) AS towns,
           bool_or(chez_sourced) AS chez_sourced,
           bool_or(source = 'application') AS has_applied,
           min(created_at) AS first_seen_at
    FROM public.chez_vendor_identities
    WHERE vendor_key IS NOT NULL
    GROUP BY vendor_key
)
SELECT i.vendor_key, i.display_name, i.phone, i.categories, i.towns,
       i.chez_sourced, i.has_applied, i.first_seen_at,
       COALESCE(c.times_called, 0) AS times_called,
       CASE WHEN COALESCE(c.times_called, 0) > 0
            THEN round(c.times_answered::numeric / c.times_called, 2) END AS answer_rate,
       COALESCE(c.times_not_a_fit, 0) AS times_not_a_fit,
       COALESCE(c.times_recommended, 0) AS times_recommended,
       c.avg_quoted_cost_cents,
       COALESCE(w.jobs_won, 0) AS jobs_won,
       COALESCE(vs.visits_completed, 0) AS visits_completed,
       COALESCE(vs.no_shows, 0) AS no_shows,
       COALESCE(vs.on_time_completions, 0) AS on_time_completions,
       vs.avg_final_cost_cents,
       COALESCE(o.emails_sent, 0) AS emails_sent,
       COALESCE(o.emails_received, 0) AS emails_received,
       GREATEST(c.last_called_at, o.last_outreach_at) AS last_contacted_at,
       COALESCE(c.households_touched, 0) AS households_touched
FROM ident i
LEFT JOIN calls c USING (vendor_key)
LEFT JOIN wins w USING (vendor_key)
LEFT JOIN visit_stats vs USING (vendor_key)
LEFT JOIN outreach o USING (vendor_key);

GRANT SELECT ON public.chez_vendor_identities, public.chez_vendor_registry TO authenticated;
