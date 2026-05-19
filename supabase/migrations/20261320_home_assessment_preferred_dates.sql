-- Phase 96 — Persist the preferred_dates array the homeowner submits via
-- the Reschedule sheet (Round 2 added the picker but the chez-concierge
-- handler only used the dates to populate a push notification, then
-- threw them away). Operations / Concierge cockpit needs to see them
-- later when assigning a handyman, and the homeowner needs to see what
-- preferences are on file from their own dashboard.
--
-- Initial-booking window (preferred_window_start + preferred_time_of_day,
-- added by 20261224) is kept as-is — those capture a single start-date +
-- general time-of-day for the FIRST visit request. The new column is the
-- ordered list of specific dates the homeowner proposes when they ask
-- for a reschedule. Both columns may be set at the same time and the
-- admin uses whichever is more specific.

ALTER TABLE public.home_assessments
    ADD COLUMN IF NOT EXISTS preferred_dates TEXT[];

COMMENT ON COLUMN public.home_assessments.preferred_dates IS
    'Phase 96 — Ordered list of YYYY-MM-DD strings the homeowner proposed for the assessment visit. Populated by AssessmentRescheduleSheet (primary + optional backup) or any future picker on the pending card. Operations Desk reads this when assigning a handyman so the dispatched visit lands on one of the homeowner''s preferred days. Null = no specific dates proposed; admin falls back to preferred_window_start + preferred_time_of_day for the initial booking, or schedules at their discretion when both are null.';
