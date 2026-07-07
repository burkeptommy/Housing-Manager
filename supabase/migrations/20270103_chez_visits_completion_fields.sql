-- Phase 100 — Chez Intelligence Foundation, part C: structured visit
-- completion.
--
-- chez_visits.outcome stays as free text (operator color), but the
-- machine-readable facts move to dedicated columns so vendor
-- reliability (show rate, on-time rate, real prices) becomes queryable
-- in the registry instead of trapped in prose.

ALTER TABLE public.chez_visits
    ADD COLUMN IF NOT EXISTS completed_on_time BOOLEAN,
    ADD COLUMN IF NOT EXISTS no_show BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS final_cost_cents BIGINT
        CHECK (final_cost_cents IS NULL OR final_cost_cents >= 0);

COMMENT ON COLUMN public.chez_visits.completed_on_time IS
    'Stamped from the cockpit visit card when the visit is marked completed. Null for visits completed before Phase 100 or when the operator did not know.';
COMMENT ON COLUMN public.chez_visits.no_show IS
    'Vendor did not show for the scheduled window. Feeds the vendor registry no_shows count.';
COMMENT ON COLUMN public.chez_visits.final_cost_cents IS
    'Actual amount the homeowner paid for this visit when known. Quoted costs live on chez_vendor_calls; this is ground truth for quoted-vs-final pricing intelligence.';
