-- Phase 95 (audit gap #47) — direct-message lane for service vendors
-- (HVAC, plumber, electrician, roofer, septic, well, chimney, tree…).
--
-- Until today, only handyman contractors had a direct-message channel
-- (`handyman_requests` + the field PWA queue). Other vendor categories
-- had to be reached out to via Chez or by the homeowner picking up
-- the phone — the audit flagged this as gap #47.
--
-- Service vendors don't have an app yet (and likely won't for v1),
-- so the design is "in-app first + email fallback":
--   • Homeowner taps "Ask a question" on a non-handyman vendor's
--     contact card → opens the inquiry composer.
--   • Composer writes a row here AND fires a SendGrid email to the
--     contractor's contact email so the message actually reaches them.
--   • If the contractor replies via email, the existing
--     receive-email pipeline picks it up and surfaces it in Inbox.
--
-- This table is the homeowner-facing log of those outreaches so the
-- contractor detail view can show "you've messaged them N times" /
-- "last reply received: …" without reaching into the email
-- pipeline.

CREATE TABLE IF NOT EXISTS public.service_vendor_inquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    contractor_id UUID NOT NULL REFERENCES public.contractors(id) ON DELETE CASCADE,
    sender_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    delivery_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (delivery_status IN ('pending', 'sent', 'failed', 'no_email')),
    delivery_error TEXT,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_service_vendor_inquiries_household
    ON public.service_vendor_inquiries (household_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_service_vendor_inquiries_contractor
    ON public.service_vendor_inquiries (contractor_id, created_at DESC);

ALTER TABLE public.service_vendor_inquiries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_vendor_inquiries_select"
    ON public.service_vendor_inquiries
    FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "service_vendor_inquiries_insert"
    ON public.service_vendor_inquiries
    FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id()
                AND sender_user_id = auth.uid());

CREATE POLICY "service_vendor_inquiries_update"
    ON public.service_vendor_inquiries
    FOR UPDATE
    USING (household_id = public.get_my_household_id());

COMMENT ON TABLE public.service_vendor_inquiries IS
    'Phase 95 / gap #47: outbound inquiries from a homeowner to a service-vendor contractor (HVAC, plumber, electrician, roofer, etc.). One row per send. SendGrid is the delivery layer; this table is the homeowner-side log so the contractor detail view can show outreach history without poking the email pipeline directly.';
