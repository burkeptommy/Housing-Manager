-- Phase 100 sweep fix — the "Chez remembers" loop never worked in prod.
--
-- decide_proposal (Phase 83.3) inserts contractors with
-- source='chez_recommendation' when a homeowner approves a vendor
-- proposal, but the contractors_source CHECK only allowed
-- manual / quiz / find_vendor / chez_field. The insert failed on the
-- constraint, the handler's try/catch swallowed it, and the visit
-- creation succeeding made the flow look fine. Zero
-- source='chez_recommendation' rows have ever existed: approved vendors
-- were never saved to the household directory (no "Sourced by Chez"
-- badge, coverage gaps never closed, no future-case matching, registry
-- jobs_won could never accrue).
--
-- Same shape as 20260905_contractors_source_chez_field.sql which added
-- 'chez_field'.

ALTER TABLE public.contractors DROP CONSTRAINT IF EXISTS contractors_source_check;
ALTER TABLE public.contractors
    ADD CONSTRAINT contractors_source_check
    CHECK (source = ANY (ARRAY[
        'manual'::text,
        'quiz'::text,
        'find_vendor'::text,
        'chez_field'::text,
        'chez_recommendation'::text
    ]));
