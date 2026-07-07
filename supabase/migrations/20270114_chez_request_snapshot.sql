-- Wave 1 (Chez service rebuild) — server-assembled delegation snapshot.
--
-- iOS sends entity IDs; the server assembles the full household truth
-- (system details, warranties, service history, routine cadence, vendor
-- history, cost references) into a versioned JSONB blob on the request.
-- `context` stays a flat string map for shipped clients; `snapshot` is
-- the operator/AI-facing rich payload. NULL = pre-snapshot legacy row;
-- every reader must fall back gracefully.
ALTER TABLE public.chez_requests
    ADD COLUMN IF NOT EXISTS snapshot JSONB;

COMMENT ON COLUMN public.chez_requests.snapshot IS
    'Server-assembled delegation context (versioned via _v key inside the blob). iOS sends IDs + homeowner intake only; buildDelegationSnapshot in chez-concierge assembles the rest. NULL on legacy rows.';

-- Wave 6 provenance (cheap to add now): resolved Chez work writes back
-- into service_records so every delegation enriches the next snapshot.
-- The chez_request_id also serves as the idempotency key for that
-- write-back.
ALTER TABLE public.service_records
    ADD COLUMN IF NOT EXISTS chez_request_id UUID REFERENCES public.chez_requests(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_service_records_chez_request
    ON public.service_records(chez_request_id)
    WHERE chez_request_id IS NOT NULL;
