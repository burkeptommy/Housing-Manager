-- Phase 100 — make two security.html claims true at the database layer.
--
-- 1. "Immutable access audit log": access_log was append-only by app
--    behavior, not by enforcement. Revoke UPDATE/DELETE from every
--    client-facing role so the claim is architectural. Service role
--    retains full access (Supabase service role bypasses grants/RLS).
-- 2. "Invite codes expire after 30 days": household_invitations.expires_at
--    existed and RLS honored it, but nothing ever set it — iOS inserts
--    omit the field, so invites never expired. A column default makes the
--    claimed 30-day window real without touching any client.

REVOKE UPDATE, DELETE ON public.access_log FROM authenticated;
REVOKE UPDATE, DELETE ON public.access_log FROM anon;

ALTER TABLE public.household_invitations
    ALTER COLUMN expires_at SET DEFAULT (now() + interval '30 days');

-- Backfill: pending invites with no expiry get the 30-day window from
-- now (not from creation — some are months old and still legitimately
-- outstanding; expiring them retroactively would strand invitees).
UPDATE public.household_invitations
SET expires_at = now() + interval '30 days'
WHERE expires_at IS NULL
  AND status = 'pending';
