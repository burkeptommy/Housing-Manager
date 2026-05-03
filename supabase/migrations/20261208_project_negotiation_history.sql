-- Phase 84 PR 4 — project quote negotiation history.
--
-- When a project is Chez-owned, the cockpit/workbench supports
-- per-vendor counter-offer tracking. Each entry on the array is a
-- back-and-forth turn between Chez (operator) and the vendor.
-- Minimal shape so we can iterate; expand as patterns emerge.
--
-- Example value:
-- [
--   { "from": "chez", "message": "Can you do better than $12,400?",
--     "price_cents": 1240000, "sent_at": "2026-05-01T14:22:00Z" },
--   { "from": "vendor", "message": "Best I can do is $11,800 if you sign by Friday.",
--     "price_cents": 1180000, "sent_at": "2026-05-02T09:14:00Z" },
--   { "from": "chez", "message": "Sold. Sending the deposit today.",
--     "price_cents": 1180000, "sent_at": "2026-05-02T11:03:00Z" }
-- ]
ALTER TABLE public.project_quotes
  ADD COLUMN IF NOT EXISTS negotiation_history JSONB
    NOT NULL DEFAULT '[]'::jsonb;

-- For the Households workbench / Project negotiation pane to render
-- a counter-offer feed quickly, index by quote_id with the most
-- recent message first. Postgres can use this to satisfy the
-- "show me the latest counter on every active quote" query.
CREATE INDEX IF NOT EXISTS idx_project_quotes_negotiation_active
  ON public.project_quotes(project_id, updated_at DESC)
  WHERE jsonb_array_length(negotiation_history) > 0;
