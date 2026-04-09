-- Phase 19n: Local vendor results cache for the find-local-vendors flow.
--
-- When a user taps a "Find a contractor for: X" task, the iOS client calls
-- the find-local-vendors edge function with (town, state, category). The
-- function checks this table first; on a cache hit it returns the rows
-- directly without spending Google Places API quota. On a cache miss it
-- calls Google Places Text Search + Place Details, ranks the results into
-- "Haven Certified" (top 2) and "Suggested" (next 2), writes them here,
-- and returns the same data to the client.
--
-- TTL is enforced in code (30 days) rather than as a partial index, so we
-- can serve a slightly stale result on a cold start when Google Places is
-- temporarily down. The fetched_at column gives the edge function the data
-- it needs to make that call. 30 days catches business closures, phone
-- number changes, rating drift, and new entrants while staying within
-- Google Maps Platform ToS guidance for cached Places data.
--
-- This is a global cache, not household-scoped: every household in the
-- same town benefits from the first user who triggered the lookup. RLS is
-- not enabled because the data is non-PII (public business information).
-- The edge function is the only writer; clients read via the function
-- response, not directly from the table.

BEGIN;

CREATE TABLE IF NOT EXISTS local_vendor_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    town TEXT NOT NULL,
    state TEXT NOT NULL,
    category TEXT NOT NULL,
    vendor_name TEXT NOT NULL,
    google_place_id TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    website TEXT,
    rating NUMERIC,
    review_count INTEGER,
    is_haven_certified BOOLEAN DEFAULT FALSE,
    rank_position INTEGER,
    fetched_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (town, state, category, google_place_id)
);

-- Hot path is "look up cache for (town, state, category) sorted by
-- fetched_at DESC". This index covers it without scanning the whole table.
CREATE INDEX IF NOT EXISTS idx_local_vendors_lookup
    ON local_vendor_results (town, state, category, fetched_at DESC);

COMMIT;
