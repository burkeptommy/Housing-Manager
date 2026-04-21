-- Phase 58: Documents ↔ Contractors direct link.
-- Today, invoice-to-contractor association is implicit via
-- service_records.invoice_document_id + service_records.contractor_id.
-- This adds a nullable FK on documents so non-service-record documents
-- (quotes, warranties, estimates, contracts) can also be vendor-scoped.
--
-- The vendor detail view's "Recent Activity" timeline reads from this
-- column to surface ALL vendor-related documents, not just invoices
-- tied to service records.

ALTER TABLE public.documents
  ADD COLUMN IF NOT EXISTS contractor_id uuid
    REFERENCES public.contractors(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_documents_contractor
  ON public.documents(contractor_id)
  WHERE contractor_id IS NOT NULL;

COMMENT ON COLUMN public.documents.contractor_id IS
  'Optional direct link to the vendor this document relates to. Set by the user when uploading from a vendor context, or auto-populated by process-invoice and receive-email when the extracted/sender vendor matches an existing contractor.';

-- Optional one-time backfill (commented out — run manually if useful):
-- UPDATE documents d
--    SET contractor_id = sr.contractor_id
--   FROM service_records sr
--  WHERE sr.invoice_document_id = d.id
--    AND d.contractor_id IS NULL
--    AND sr.contractor_id IS NOT NULL;
