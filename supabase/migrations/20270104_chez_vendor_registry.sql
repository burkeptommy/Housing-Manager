-- Phase 100 — Chez Intelligence Foundation, part D: the cross-household
-- vendor intelligence registry.
--
-- Every vendor Chez has ever touched, across all homes, with the
-- operational stats that make the next case cheaper: did they answer,
-- what did they quote, did they win the job, did they show up. Identity
-- is unified across five sources (household contractors, the call
-- ledger, vendor email outreach, self-serve applications, the Places
-- seed cache) via google_place_id first, normalized phone second,
-- name+town last.
--
-- Plain views, not materialized: at current scale every aggregate is
-- sub-millisecond on the supporting indexes. Revisit materialization
-- when chez_vendor_calls passes ~50k rows.
--
-- security_invoker=true so each base table's RLS applies to the caller:
-- the operator (is_tom_admin) sees everything; homeowners see only what
-- their own row-level grants already allow (which for the operator-only
-- tables is nothing).

-- Identity plumbing on contractors so proposal approvals can stamp the
-- Places identity at the moment a candidate becomes a household vendor.
ALTER TABLE public.contractors
    ADD COLUMN IF NOT EXISTS google_place_id TEXT;
COMMENT ON COLUMN public.contractors.google_place_id IS
    'Google Places identity for registry matching. Stamped by decide_proposal when a Chez-sourced vendor is approved, or by any import path that knows the place id.';
CREATE INDEX IF NOT EXISTS idx_contractors_google_place_id
    ON public.contractors(google_place_id)
    WHERE google_place_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.chez_normalize_phone(p TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS
$$ SELECT NULLIF(regexp_replace(coalesce(p, ''), '\D', '', 'g'), '') $$;

-- Unified identity key: place id beats phone beats name+town. The name
-- branch lowercases + trims so "Romano Plumbing" and "romano plumbing "
-- collapse.
CREATE OR REPLACE FUNCTION public.chez_vendor_key(place_id TEXT, phone TEXT, name TEXT, town TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
  SELECT COALESCE(
    'place:' || NULLIF(trim(coalesce(place_id, '')), ''),
    'phone:' || public.chez_normalize_phone(phone),
    'name:'  || NULLIF(lower(trim(coalesce(name, ''))), '') || '|' || lower(trim(coalesce(town, '')))
  )
$$;

-- One row per (source, source row): the identity spine.
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
