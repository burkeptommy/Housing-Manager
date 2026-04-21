-- Phase 59: Structured invoice metadata on documents.
-- Phase 58 added `documents.contractor_id` so bills could be linked to vendors,
-- but without amount/date/number we can't answer "How much did I pay Tyler
-- Heating this year?" — the vendor detail's spend hero stays hollow.
--
-- This migration adds the missing fields. `process-invoice` extracts them
-- from the AI response (already does) and writes them to the document row
-- so every vendor-scoped query can roll up spend without re-parsing.

ALTER TABLE public.documents
  ADD COLUMN IF NOT EXISTS invoice_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS invoice_date DATE,
  ADD COLUMN IF NOT EXISTS invoice_number TEXT,
  ADD COLUMN IF NOT EXISTS invoice_line_items JSONB,
  ADD COLUMN IF NOT EXISTS vendor_match_confidence TEXT
    CHECK (vendor_match_confidence IS NULL OR vendor_match_confidence IN ('high','medium','low','ambiguous'));

-- Composite index scoped to invoice lookups: vendor detail's "recent activity"
-- section sorts by invoice_date desc for a given contractor.
CREATE INDEX IF NOT EXISTS idx_documents_contractor_invoice_date
  ON public.documents(contractor_id, invoice_date DESC)
  WHERE contractor_id IS NOT NULL;

COMMENT ON COLUMN public.documents.invoice_amount IS
  'Total amount extracted by process-invoice for invoice-category documents. Used for vendor spend roll-up.';
COMMENT ON COLUMN public.documents.invoice_date IS
  'Date of service or bill issuance extracted by process-invoice. Drives vendor activity timeline ordering.';
COMMENT ON COLUMN public.documents.invoice_number IS
  'Invoice number extracted from the bill header/footer. Useful for disambiguating duplicate uploads.';
COMMENT ON COLUMN public.documents.invoice_line_items IS
  'JSON array of extracted line items: [{description, quantity?, unit_price?, total}]. Drill-in detail on the vendor timeline.';
COMMENT ON COLUMN public.documents.vendor_match_confidence IS
  'process-invoice vendor match confidence. high=auto-file silent, medium/low/ambiguous=inbox fallback.';
