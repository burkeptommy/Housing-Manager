-- ============================================================================
-- Phase 86C — Chez vendor outreach
-- ============================================================================
-- The cockpit had no outbound channel to vendors. Tom called vendors on
-- his phone, typed notes back in. This migration creates a server-side
-- outbound table so Chez can email vendors directly with replies routed
-- back into the case thread automatically.
--
-- Two ends of the pipe:
--   • OUTBOUND: cockpit composer → `send-chez-vendor-email` Edge Fn →
--     SendGrid → row recorded in chez_vendor_outreach, displayed in
--     case thread as a system message "📧 To Petro: …"
--   • INBOUND: vendor replies to reply-to `vendor+<token>@alfred.getchez.com`
--     → SendGrid Inbound Parse → `receive-email` Edge Fn → lookup the
--     outreach row by reply_token → insert a concierge_message
--     tagged `from_vendor` on the same case thread
--
-- Design decisions per audit:
--   • Same `alfred.getchez.com` domain w/ sub-addressing — saves SendGrid
--     auth/DKIM work for a separate domain.
--   • SMS deferred to Phase 86+ pending CT single-state consent review.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chez_vendor_outreach (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Which case the outreach belongs to. Outreach is always case-scoped:
    -- we email vendors AS Chez on behalf of a homeowner, never out-of-band.
    request_id UUID NOT NULL REFERENCES public.chez_requests(id) ON DELETE CASCADE,
    -- Convenience denormalization so the receive-email branch can apply
    -- RLS on inbound vendor messages without a JOIN every read.
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    -- Optional vendor record. NULL when reaching out to a candidate not
    -- yet in the homeowner's directory (Google Places lookups, cold
    -- outreach from the vendor sheet).
    contractor_id UUID REFERENCES public.contractors(id) ON DELETE SET NULL,

    direction TEXT NOT NULL CHECK (direction IN ('outbound', 'inbound')),
    channel TEXT NOT NULL DEFAULT 'email' CHECK (channel IN ('email', 'sms', 'call_log')),

    -- For outbound: who's the email going to.
    -- For inbound: who replied (parsed from email From).
    vendor_name TEXT,
    vendor_email TEXT,
    vendor_phone TEXT,

    subject TEXT,
    body TEXT NOT NULL,

    -- SendGrid attachment manifest (mirrors concierge_messages.attachments).
    attachments JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- Unique reply token used in the reply-to address
    -- `vendor+<reply_token>@alfred.getchez.com`. NULL on inbound rows.
    -- Stamped on outbound rows so the inbound side can look up the
    -- conversation in O(1).
    reply_token TEXT UNIQUE,

    -- Workflow state.
    status TEXT NOT NULL DEFAULT 'sent'
        CHECK (status IN ('draft', 'queued', 'sent', 'delivered', 'bounced', 'failed', 'received')),
    -- When status = 'draft', the operator hasn't sent it yet. Phase 86D
    -- playbooks may pre-draft outreach for the operator to review.
    is_pending_review BOOLEAN NOT NULL DEFAULT FALSE,

    sent_at TIMESTAMPTZ,
    received_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Optional metadata for negotiation context. When the outreach is a
    -- counter-offer, this captures the proposed price + scope so the
    -- iOS-side cost proposal (Phase 80.1) can decode it without re-
    -- parsing the email body.
    negotiation_payload JSONB,

    -- Who sent it (operator). Useful for multi-operator audit trail.
    sent_by_user_id UUID REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS chez_vendor_outreach_request_recent
    ON public.chez_vendor_outreach (request_id, created_at DESC);

CREATE INDEX IF NOT EXISTS chez_vendor_outreach_household
    ON public.chez_vendor_outreach (household_id, created_at DESC);

-- Reply-token lookup is the hot path on inbound vendor replies.
CREATE INDEX IF NOT EXISTS chez_vendor_outreach_reply_token
    ON public.chez_vendor_outreach (reply_token)
    WHERE reply_token IS NOT NULL;

CREATE INDEX IF NOT EXISTS chez_vendor_outreach_contractor
    ON public.chez_vendor_outreach (contractor_id, created_at DESC)
    WHERE contractor_id IS NOT NULL;

-- RLS: vendor outreach is operator-only. Homeowners do NOT see the raw
-- vendor email thread — they see Chez's polished system-message
-- ("Chez emailed Petro about the boiler; they offered Tuesday or
-- Thursday — which works for you?") in the case thread, not the verbatim
-- back-and-forth. This avoids overwhelming the homeowner with the
-- operational mechanics.
ALTER TABLE public.chez_vendor_outreach ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin reads vendor outreach"
    ON public.chez_vendor_outreach FOR SELECT
    USING (public.is_tom_admin());
CREATE POLICY "Admin writes vendor outreach"
    ON public.chez_vendor_outreach FOR INSERT
    WITH CHECK (public.is_tom_admin());
CREATE POLICY "Admin updates vendor outreach"
    ON public.chez_vendor_outreach FOR UPDATE
    USING (public.is_tom_admin());

-- Updated_at trigger.
CREATE OR REPLACE FUNCTION public.chez_vendor_outreach_touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS chez_vendor_outreach_touch_updated ON public.chez_vendor_outreach;
CREATE TRIGGER chez_vendor_outreach_touch_updated
    BEFORE UPDATE ON public.chez_vendor_outreach
    FOR EACH ROW
    EXECUTE FUNCTION public.chez_vendor_outreach_touch_updated_at();
