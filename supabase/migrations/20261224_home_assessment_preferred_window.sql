-- Phase 95 (audit gap #4) — preferred-window fields on home_assessments.
--
-- Today the homeowner taps "Send a Chez handyman" and the request is
-- fire-and-forget — server-side dispatch picks the slot, homeowner has
-- zero scheduling input. For HNW users with property managers /
-- assistants / kids' schedules, that's the wrong default.
--
-- This migration adds two nullable columns the iOS booking sheet
-- writes before the request is created. Operations Desk / Concierge
-- cockpit reads them when assigning a handyman so the dispatched
-- visit lands inside the homeowner's window.

ALTER TABLE public.home_assessments
    ADD COLUMN IF NOT EXISTS preferred_window_start DATE,
    ADD COLUMN IF NOT EXISTS preferred_time_of_day TEXT;

COMMENT ON COLUMN public.home_assessments.preferred_window_start IS
    'Phase 95 / gap #4: earliest date the homeowner is OK with a visit. ISO date string. Null = "as soon as possible," which the dispatcher treats as same-week. Cockpit shows this on the queue card so the operator schedules within range.';

COMMENT ON COLUMN public.home_assessments.preferred_time_of_day IS
    'Phase 95 / gap #4: free-text time-of-day window — typically "morning" / "afternoon" / "flexible" from the iOS picker, but the column accepts any string for future flexibility (e.g. "after school pickup").';
