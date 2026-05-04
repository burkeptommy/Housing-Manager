-- Phase 95 (audit gap #86) — intermediate "scheduled with dealer"
-- state on vehicle_recalls.
--
-- Today the recall acknowledgment UI is binary: open or resolved.
-- HNW homeowners often book the dealer appointment days or weeks
-- before the part actually gets installed; in that window the
-- recall isn't "open" (they've taken action) but it's not
-- "resolved" either. Without a third state the homeowner either
-- pretends the recall is still open (badge keeps surfacing) or
-- marks it resolved prematurely (defeats the safety reminder).
--
-- This migration adds `scheduled_with_dealer_at`. iOS surfaces a
-- "Schedule with dealer" CTA next to "Mark completed"; setting
-- this stamp puts the recall into the intermediate state but
-- leaves `is_resolved = false` so the safety system still
-- escalates if the visit never happens.

ALTER TABLE public.vehicle_recalls
    ADD COLUMN IF NOT EXISTS scheduled_with_dealer_at TIMESTAMPTZ;

COMMENT ON COLUMN public.vehicle_recalls.scheduled_with_dealer_at IS
    'Phase 95 / gap #86: stamped when the homeowner books the dealer appointment but hasn''t completed the work yet. UI shows a "Scheduled" pill while this is non-null AND is_resolved is false. Setting is_resolved = true does not clear this column, since the schedule timestamp is useful audit history.';
