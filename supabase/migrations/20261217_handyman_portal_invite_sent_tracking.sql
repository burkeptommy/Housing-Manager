-- Phase 95 (audit gap #67) — invite-sent tracking on handyman portal
-- sessions.
--
-- The homeowner sends the field-PWA invite via the iOS Messages
-- composer — that's a regular SMS sent through their carrier, so we
-- have no delivery callback. Today the only timestamp we keep is
-- `last_opened_at`, set when the handyman first lands on the portal.
-- If the handyman never opens the link there's no way to distinguish
-- "homeowner forgot to send" from "tech ignored it" because we don't
-- record the send moment.
--
-- Adding `last_invite_sent_at` lets iOS stamp the column on every
-- successful MFMessageComposeViewController `.sent` event so the
-- homeowner can see "Invite sent 6h ago, no opens yet" and take a
-- follow-up action (re-send, switch to email, escalate to Chez).
ALTER TABLE public.handyman_portal_sessions
    ADD COLUMN IF NOT EXISTS last_invite_sent_at TIMESTAMPTZ;

COMMENT ON COLUMN public.handyman_portal_sessions.last_invite_sent_at IS
    'Phase 95 / gap #67: stamped by iOS whenever the homeowner finishes a Messages-composer invite send. Used by the visit detail view to surface "sent X hours ago, no opens" status when last_opened_at is null but this column is set.';
