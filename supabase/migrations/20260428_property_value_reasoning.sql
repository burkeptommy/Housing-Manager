-- Phase 18g: Store the reasoning behind a Claude-derived property value
-- estimate so the iOS Investment Summary card can show the user how the
-- number was derived ("Estimated by AI from 12 recent comps within 0.5
-- miles of your address...").
--
-- Only populated when estimated_value_source = 'ai_comps'. NULL for ATTOM,
-- RentCast, computed, and estimated rows where the source caption alone
-- carries enough trust signal.

ALTER TABLE public.properties
    ADD COLUMN IF NOT EXISTS estimated_value_reasoning TEXT;
