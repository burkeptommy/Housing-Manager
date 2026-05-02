-- Phase 71: rename `is_haven_certified` to `is_top_rated`.
--
-- The existing column flags vendors via a Google Places-derived heuristic
-- (rating + review count + non-chain). It was never a real verification —
-- the name "Haven Certified" overclaimed what the badge means.
--
-- The phrase "Chez Certified" is intentionally being reserved for an
-- upcoming human-verified vendor pipeline (Phase 72+). Keeping the legacy
-- heuristic under "Top-Rated" prevents the badge from meaning two
-- different things across vendor sources.
--
-- Atomic rename, no data migration needed. Edge functions + iOS app must
-- redeploy promptly after this migration runs (sub-minute window of
-- mismatch acceptable for TestFlight scale).

ALTER TABLE local_vendor_results
    RENAME COLUMN is_haven_certified TO is_top_rated;
