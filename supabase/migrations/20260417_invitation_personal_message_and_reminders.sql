-- Phase 2 (Onboarding Revamp): extend household_invitations to support
-- personal welcome messages and reminder cron tracking.
--
-- Idempotent: every column add and index uses IF NOT EXISTS so this can
-- safely run multiple times.

ALTER TABLE public.household_invitations
    ADD COLUMN IF NOT EXISTS personal_message TEXT;

COMMENT ON COLUMN public.household_invitations.personal_message IS
    'Optional warm note from the inviter, surfaced in both the invite email and the in-app preview card.';

ALTER TABLE public.household_invitations
    ADD COLUMN IF NOT EXISTS reminder_sent_at TIMESTAMPTZ;

COMMENT ON COLUMN public.household_invitations.reminder_sent_at IS
    'Last time send-reminder-batch fired a reminder for this invitation. NULL means no reminder has been sent yet.';

ALTER TABLE public.household_invitations
    ADD COLUMN IF NOT EXISTS reminder_count INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.household_invitations.reminder_count IS
    'Number of reminder emails the cron has sent for this invitation. Cap is 3 (24h, 3d, 7d).';

-- Speed up the daily reminder batch query: pending, not yet expired, with
-- a created_at older than 24h. We filter on status + created_at + reminder_sent_at.
CREATE INDEX IF NOT EXISTS household_invitations_pending_reminder_idx
    ON public.household_invitations (status, created_at)
    WHERE status = 'pending';
