-- Phase 95 (audit gap #90) — vehicle archive (soft-delete) flow.
--
-- Today the only way to remove a vehicle is the destructive delete
-- helper, which also cascades-cleans every service record, recall,
-- linked document, and maintenance task. That's correct for "I
-- never owned this car," but wrong for the common HNW case ("I
-- sold the M5, traded it for the new one"). The homeowner wants
-- the vehicle off their dashboard but the service history
-- preserved as audit + future-buyer disclosure material.
--
-- This migration adds soft-delete columns. iOS surfaces a
-- "Mark as sold / traded / archive" sheet in `VehicleDetailView`
-- and `fetchVehicles()` filters archived rows out of the active
-- garage list. Direct fetches by id (for service history reads on
-- existing maintenance records) still return the row.

ALTER TABLE public.vehicles
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS archive_reason TEXT;

-- Helpful index for the active-garage filter — the partial index
-- skips archived rows entirely so list queries scan a smaller set.
CREATE INDEX IF NOT EXISTS idx_vehicles_active
    ON public.vehicles (household_id, name)
    WHERE archived_at IS NULL;

COMMENT ON COLUMN public.vehicles.archived_at IS
    'Phase 95 / gap #90: soft-delete timestamp. Non-null = vehicle has been sold / traded / totaled / archived. fetchVehicles() filters these out by default. Service records, recalls, documents, and maintenance_tasks linked via vehicle_id stay accessible via direct lookup so the history persists for the buyer / insurance / Carfax export.';

COMMENT ON COLUMN public.vehicles.archive_reason IS
    'Phase 95 / gap #90: free-text reason ("sold", "traded", "totaled", "other"). UI presents a fixed enum picker but the column accepts any string for future flexibility.';
