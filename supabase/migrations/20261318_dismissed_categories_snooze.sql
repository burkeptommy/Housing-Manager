-- Round 2 (May 2026): "Circle back" / Remind-me-later on the Vendor
-- Coverage Sheet. The friend on the latest TestFlight build reported
-- needing a middle option between "Find a pro" and "Not applicable" for
-- vendors they might want in the future (3+ years out, e.g. a roofer)
-- but not now.
--
-- Schema: extend `dismissed_categories` with an optional
-- `snoozed_until` timestamp. Existing rows have nil snooze =
-- permanent dismissal (current behavior). New snooze rows store
-- `now() + interval` and resurface in the coverage sheet when the
-- timestamp passes. One column, one behavior, zero new tables —
-- keeps the schema lean and the iOS gap filter only has to read one
-- source.

ALTER TABLE public.dismissed_categories
    ADD COLUMN IF NOT EXISTS snoozed_until TIMESTAMPTZ;

-- Active-snooze lookups happen on every dashboard load. Index supports
-- the typical query: WHERE household_id = ? AND (snoozed_until IS NULL
-- OR snoozed_until > now()).
CREATE INDEX IF NOT EXISTS idx_dismissed_categories_snooze
    ON public.dismissed_categories (household_id, snoozed_until)
    WHERE snoozed_until IS NOT NULL;

COMMENT ON COLUMN public.dismissed_categories.snoozed_until IS
    'When set, the row is a temporary snooze rather than a permanent dismissal. Resurfaces in the Vendor Coverage sheet once now() > snoozed_until. NULL = permanent dismissal (legacy behavior).';
