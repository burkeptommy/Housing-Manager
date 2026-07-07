-- Wave 5 (Chez service rebuild) — Stripe card-on-file foundation.
--
-- The customer adds a card once at delegation time; Chez charges per job
-- within the household's approved spending tiers. This migration is the
-- data layer only: the actual charge flow lives in chez-concierge's
-- payments.ts module and stays inert until STRIPE_SECRET_KEY is set as
-- an edge-function secret. All additive, no behavior change on deploy.

-- One Stripe Customer per household.
ALTER TABLE public.households
    ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;

-- Saved cards (via SetupIntent). Client never writes these — the edge
-- function confirms with Stripe and upserts server-side.
CREATE TABLE IF NOT EXISTS public.chez_payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    stripe_payment_method_id TEXT NOT NULL UNIQUE,
    brand TEXT,
    last4 TEXT,
    exp_month INT,
    exp_year INT,
    is_default BOOLEAN NOT NULL DEFAULT true,
    detached_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_chez_payment_methods_household
    ON public.chez_payment_methods(household_id)
    WHERE detached_at IS NULL;

ALTER TABLE public.chez_payment_methods ENABLE ROW LEVEL SECURITY;

-- Members see their own household's cards (to show "Visa ending 4242");
-- admins see all. NO client INSERT/UPDATE/DELETE — writes go through the
-- edge function with the service role.
CREATE POLICY chez_payment_methods_select ON public.chez_payment_methods
    FOR SELECT
    USING (
        household_id = public.get_my_household_id()
        OR public.is_tom_admin()
    );

-- Charges. One row per job billed. A charge links to the request and
-- (when known) the visit + outcome that justified it.
CREATE TABLE IF NOT EXISTS public.chez_charges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    request_id UUID REFERENCES public.chez_requests(id) ON DELETE SET NULL,
    visit_id UUID REFERENCES public.chez_visits(id) ON DELETE SET NULL,
    outcome_id UUID REFERENCES public.chez_request_outcomes(id) ON DELETE SET NULL,
    approval_message_id UUID REFERENCES public.concierge_messages(id) ON DELETE SET NULL,
    stripe_payment_intent_id TEXT UNIQUE,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    currency TEXT NOT NULL DEFAULT 'usd',
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'requires_approval', 'succeeded', 'failed', 'refunded', 'canceled')),
    description TEXT,
    initiated_by TEXT NOT NULL DEFAULT 'admin'
        CHECK (initiated_by IN ('auto_tier', 'homeowner_approval', 'admin')),
    receipt_url TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_chez_charges_household ON public.chez_charges(household_id);
CREATE INDEX IF NOT EXISTS idx_chez_charges_request ON public.chez_charges(request_id);

ALTER TABLE public.chez_charges ENABLE ROW LEVEL SECURITY;

-- Members see their own household's charges (receipts); admins see all.
-- Writes via service role only.
CREATE POLICY chez_charges_select ON public.chez_charges
    FOR SELECT
    USING (
        household_id = public.get_my_household_id()
        OR public.is_tom_admin()
    );

COMMENT ON TABLE public.chez_payment_methods IS
    'Cards on file per household (Stripe SetupIntent). Client-readable, edge-function-writable only.';
COMMENT ON TABLE public.chez_charges IS
    'Per-job charges. Chez charges within spending tiers; above tier lands as requires_approval + a cost proposal. Inert until STRIPE_SECRET_KEY is set.';
