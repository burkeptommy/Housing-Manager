-- Phase 9 (Onboarding Revamp): track whether a newly-joined invitee should
-- be offered the 5-question personal onboarding quiz on the dashboard.
--
-- Set to true when a user accepts an invitation, cleared when the personal
-- quiz completes (or the user dismisses with "Not now"). The iOS client
-- mirrors this in UserDefaults under PendingInviteKeys.needsPersonalQuiz so
-- the dashboard can read the flag without a round trip on launch.
--
-- Idempotent: ADD COLUMN IF NOT EXISTS handles re-runs.

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS needs_personal_quiz BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.users.needs_personal_quiz IS
    'True when this user joined an existing household via invitation and has not yet completed (or dismissed) the personal onboarding quiz.';
