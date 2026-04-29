-- Chez v1: Estate management removed.
--
-- Drops the Phase 48 estate intake / export tables and the document
-- → attorney FK. Keeps:
--   - documents.visible_to_home_managers (Build 87 home-manager gate;
--     not estate-specific — financial / medical / legal categories
--     also depend on it)
--   - trusted_contacts (UI still references it from HouseholdAccessView,
--     TrustedContactsView, etc.; will be reconsidered in a follow-up
--     sweep once those surfaces are reviewed)
--
-- This migration is destructive. Audit `estate_state` /
-- `estate_pdf_exports` in your environment before applying — Phase 48
-- shipped to dev/staging only, so production should have zero rows.

BEGIN;

-- The cleanest way to drop a column referenced by SELECT policies is
-- to drop the column with CASCADE, which also drops any policies that
-- mention it. The household_documents_select policy added by Build 87
-- doesn't reference linked_attorney_contact_id, so this should only
-- drop the foreign-key constraint.
ALTER TABLE public.documents
    DROP COLUMN IF EXISTS linked_attorney_contact_id;

-- Estate intake answers + computed readiness/staleness state.
DROP TABLE IF EXISTS public.estate_state CASCADE;

-- Encrypted PDF exports + verification-token records consumed by the
-- public verify-estate-export Edge Function. The Edge Function itself
-- is being deleted from supabase/functions/verify-estate-export/.
DROP TABLE IF EXISTS public.estate_pdf_exports CASCADE;

COMMIT;
