-- Phase 100 sweep fix #3 — email forwarding was rejecting every
-- homeowner.
--
-- The May 19 receive-email hardening (Phase 86C) added a sender
-- whitelist check against household_allowed_senders, but nothing ever
-- seeded the table: zero rows existed in prod, so once that commit
-- deployed, every forwarded email from every homeowner bounced with
-- sender_not_whitelisted. The companion fix in receive-email also
-- auto-allows any email belonging to a household USER at check time;
-- this backfill makes the standing list visible/manageable in Settings
-- and covers the lookup without the fallback query.
--
-- Idempotent: skips emails already present for the household.

INSERT INTO public.household_allowed_senders (household_id, email, label, is_auto_added)
SELECT u.household_id, lower(u.email), 'Household member', true
FROM public.users u
WHERE u.household_id IS NOT NULL
  AND u.email IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.household_allowed_senders s
    WHERE s.household_id = u.household_id
      AND lower(s.email) = lower(u.email)
  );
