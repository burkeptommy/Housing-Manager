-- Phase 95 (audit gap #93) — scrub deleted family members from
-- `vehicles.covered_driver_ids` UUID arrays.
--
-- `vehicles.primary_driver_id` is a FK with `ON DELETE SET NULL`, so
-- the primary-driver path already cascades correctly. The covered-driver
-- list is a UUID[] column (PostgreSQL arrays can't carry per-element
-- foreign keys), so deleting a family_member leaves their UUID stranded
-- in every vehicle that listed them — the picker shows a phantom row,
-- the count is wrong, and any future "who can drive this car" lookup
-- treats the orphan as live.
--
-- This migration adds a BEFORE DELETE trigger that walks the deleted
-- member's household and removes their id from every vehicle's
-- covered_driver_ids using `array_remove`. We also run a one-shot
-- backfill at the bottom to scrub orphans created before this trigger
-- existed.

CREATE OR REPLACE FUNCTION public.scrub_deleted_family_member_from_vehicles()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Skip if the deleted member never had a household_id (shouldn't
    -- happen in practice, but bail safely if it does).
    IF OLD.household_id IS NULL THEN
        RETURN OLD;
    END IF;

    UPDATE public.vehicles
    SET covered_driver_ids = array_remove(covered_driver_ids, OLD.id)
    WHERE household_id = OLD.household_id
      AND OLD.id = ANY(covered_driver_ids);

    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS family_member_cascade_to_covered_drivers ON public.family_members;

CREATE TRIGGER family_member_cascade_to_covered_drivers
    BEFORE DELETE ON public.family_members
    FOR EACH ROW
    EXECUTE FUNCTION public.scrub_deleted_family_member_from_vehicles();

-- One-time backfill: scrub orphans created before this trigger
-- existed. For each vehicle we compute (a) the orphan UUIDs (in the
-- array but no longer in family_members) for filtering, and (b) the
-- still-valid UUIDs (in the array AND in family_members) as the new
-- column value. Both expressions short-circuit cleanly once the
-- arrays are clean, so re-running this migration is cheap.
WITH vehicle_orphans AS (
    SELECT
        v.id AS vehicle_id,
        ARRAY(
            SELECT unnest(v.covered_driver_ids)
            EXCEPT
            SELECT id FROM public.family_members
        ) AS orphan_ids,
        ARRAY(
            SELECT unnest(v.covered_driver_ids)
            INTERSECT
            SELECT id FROM public.family_members
        ) AS valid_ids
    FROM public.vehicles v
    WHERE array_length(v.covered_driver_ids, 1) IS NOT NULL
)
UPDATE public.vehicles v
SET covered_driver_ids = o.valid_ids
FROM vehicle_orphans o
WHERE v.id = o.vehicle_id
  AND array_length(o.orphan_ids, 1) IS NOT NULL;

COMMENT ON FUNCTION public.scrub_deleted_family_member_from_vehicles() IS
    'Phase 95 / gap #93: removes the deleted family member''s UUID from every vehicle.covered_driver_ids in their household before the row goes away. Compensates for the fact that array elements cannot carry FK constraints.';
