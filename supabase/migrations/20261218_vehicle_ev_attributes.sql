-- Phase 95 (audit gap #91) — EV-specific vehicle attributes.
--
-- The HNW Westchester market is heavily EV-leaning (Tesla, Rivian,
-- Lucid, Mercedes EQ, BMW iX). Today VehicleRow has no way to mark a
-- vehicle as electric or capture battery / charger context, so:
--
--   • The AI maintenance schedule emits ICE-style intervals (oil
--     changes, transmission flushes, fuel filter swaps) for EVs that
--     don't apply.
--   • The "EV charger inspection" Phase 57 template can't gate on the
--     actual vehicle being electric — only on the property having
--     `has_ev_charger`. A household with the charger but no EV gets
--     the inspection seeded; a household with an EV but no charger
--     doesn't.
--   • Garage / charger-station coordination has no signal to drive
--     it from.
--
-- This migration adds three nullable columns. Future Phase 96+ work
-- (or vehicle-lookup vision pass enrichment) can backfill them
-- automatically from VIN + AI inference.

ALTER TABLE public.vehicles
    ADD COLUMN IF NOT EXISTS is_ev BOOLEAN,
    ADD COLUMN IF NOT EXISTS battery_capacity_kwh NUMERIC,
    ADD COLUMN IF NOT EXISTS charger_type TEXT;

COMMENT ON COLUMN public.vehicles.is_ev IS
    'Phase 95 / gap #91: nullable boolean. True for fully-electric, false for ICE/hybrid (no oil + transmission concerns), null when unknown. Used to filter ICE-only AI maintenance templates and gate EV-only routines.';

COMMENT ON COLUMN public.vehicles.battery_capacity_kwh IS
    'Phase 95 / gap #91: usable battery capacity in kWh (e.g. 75.0 for a Tesla Model 3 Long Range). Used for charge-cost estimation and range-anxiety surfacing.';

COMMENT ON COLUMN public.vehicles.charger_type IS
    'Phase 95 / gap #91: connector standard the vehicle expects. One of: "tesla", "ccs", "chademo", "j1772", "nacs". Drives "your home charger is compatible" sanity checks against `properties.attributes.has_ev_charger` + future charger-type capture.';
