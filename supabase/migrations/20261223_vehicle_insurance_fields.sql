-- Phase 95 (audit gap #78) — vehicle insurance backing fields.
--
-- Today the insurance card on VehicleDetailView is fully document-
-- driven: it shows "On file" or "Upload policy" based on whether
-- a documents.vehicle_id row exists with category Auto Insurance,
-- and the expiration date is read from the document's
-- expirationDate metadata. That's a worse UX than the registration
-- card (which has a dedicated `vehicles.registration_expiry`
-- column that the user can edit directly), and it means the
-- expiration / policy number / carrier signals can't be set
-- without uploading a document.
--
-- This migration adds three columns mirroring the registration
-- pattern. iOS surfaces them via a new "Edit policy details"
-- sheet on long-press of the insurance card.

ALTER TABLE public.vehicles
    ADD COLUMN IF NOT EXISTS insurance_expiry DATE,
    ADD COLUMN IF NOT EXISTS insurance_policy_num TEXT,
    ADD COLUMN IF NOT EXISTS insurance_carrier TEXT;

COMMENT ON COLUMN public.vehicles.insurance_expiry IS
    'Phase 95 / gap #78: policy expiration. ISO date string. Mirrors registration_expiry; populated by the EditInsuranceSheet on VehicleDetailView. Source-of-truth for the insurance card''s expiration display when set, falling back to the document''s expirationDate metadata when null.';

COMMENT ON COLUMN public.vehicles.insurance_policy_num IS
    'Phase 95 / gap #78: free-text policy number. Useful for the homeowner to reference quickly without opening the document, and for Chez to quote alongside vendor coordination.';

COMMENT ON COLUMN public.vehicles.insurance_carrier IS
    'Phase 95 / gap #78: free-text carrier name (e.g. "Chubb", "GEICO", "Travelers"). Optional — when nil the foundational answers Q26 carrier may apply, but explicit per-vehicle stamping wins.';
