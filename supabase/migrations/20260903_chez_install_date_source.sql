-- Chez v1: track HOW we know an install date.
--
-- Most homeowners don't know exact install dates for systems they
-- didn't replace themselves (roof from prior owner, original foundation,
-- septic tank from a 1990s install). The legacy schema treated the date
-- as binary — present or missing — so unknown systems sat in "Profile
-- to finish" forever, training users to ignore the warning.
--
-- This migration introduces three states:
--   exact      — user typed a year they're sure of
--   estimated  — user picked an approximate window (or ATTOM pre-fill)
--   unknown    — user explicitly said "I don't know"
--
-- Plus a 90-day cooldown timestamp so an "unknown" system stops nagging
-- the user but is re-surfaced after a meaningful pause (in case they
-- find old paperwork in the meantime).

ALTER TABLE public.home_systems
    ADD COLUMN IF NOT EXISTS install_date_source TEXT,
    ADD COLUMN IF NOT EXISTS install_date_unknown_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS install_date_attom_prefilled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS install_date_confirmed_at TIMESTAMPTZ;

-- Constrain source values so a typo can't slip in unnoticed. Null is
-- allowed (and means "no source recorded yet" — same as legacy rows).
ALTER TABLE public.home_systems
    DROP CONSTRAINT IF EXISTS home_systems_install_date_source_valid;
ALTER TABLE public.home_systems
    ADD CONSTRAINT home_systems_install_date_source_valid
    CHECK (
        install_date_source IS NULL
        OR install_date_source IN ('exact', 'estimated', 'unknown')
    );

-- Backfill: any existing row with an install_date but no source is
-- treated as 'exact' (the user typed it through the existing form,
-- which always meant they were confident enough to fill it in).
-- `install_date` is a DATE column, so a non-null value is sufficient
-- — no TRIM required.
UPDATE public.home_systems
SET install_date_source = 'exact'
WHERE install_date IS NOT NULL
  AND install_date_source IS NULL;
