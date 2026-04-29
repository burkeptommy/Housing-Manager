-- Chez v1: soft-delete for home_systems.
--
-- Mirrors the routines table's `archived_at` pattern. Drives:
--   1. The new "I don't have this" affordance in SystemCoverageFlow —
--      stamps archived_at when the user removes a system that doesn't
--      apply to their property (no irrigation, no pool, etc.).
--   2. The one-time backfill that retires service-shaped home_systems
--      rows (Pet Waste, Cleaning Service, Trash & Recycling, Snow
--      Removal, Mosquito & Tick, Handyman) so those categories live
--      only as routines going forward.
--
-- Idempotent: column added with IF NOT EXISTS. Index is partial so
-- only active rows pay the cost — every read path filters on it.

ALTER TABLE public.home_systems
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

-- Partial index keeps fetch performance flat as the archived count
-- grows over time. Every property-level read filters
-- `archived_at IS NULL` so this is the hot path.
CREATE INDEX IF NOT EXISTS idx_home_systems_active
    ON public.home_systems (property_id)
    WHERE archived_at IS NULL;
