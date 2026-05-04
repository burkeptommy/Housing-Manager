-- Phase 95 (audit gaps #29 / #68) — track when a fallback email
-- was last sent for a handyman request so the cron / fallback
-- function can rate-limit per-thread emails to once per day.
--
-- The homeowner's message lands in `handyman_request_messages` and
-- the field PWA picks it up if the handyman is active. When the
-- handyman hasn't opened the portal in 24h, we want to email them
-- the latest pending message — but we don't want to spam: one
-- email per request per 24h is plenty.

ALTER TABLE public.handyman_requests
    ADD COLUMN IF NOT EXISTS last_email_fallback_sent_at TIMESTAMPTZ;

COMMENT ON COLUMN public.handyman_requests.last_email_fallback_sent_at IS
    'Phase 95 / gap #29: last time the email-fallback Edge Function fired a SendGrid notification for this request. Rate-limits the fallback to once per 24h per thread so multiple homeowner messages within a day collapse into one digest email.';
