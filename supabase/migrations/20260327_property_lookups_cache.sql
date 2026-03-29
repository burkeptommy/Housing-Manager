-- IDEMPOTENT: safe to re-run
-- Cache for RentCast property lookups to avoid redundant API calls.
-- Each unique address is stored once. TTL managed by application logic.

CREATE TABLE IF NOT EXISTS property_lookups (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    address_hash text NOT NULL UNIQUE,
    lookup_data jsonb NOT NULL,
    created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_lookups_hash ON property_lookups(address_hash);

-- Allow edge functions (service role) full access; no RLS needed since this is server-only cache.
ALTER TABLE property_lookups ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS, so no policies needed for edge functions.
-- But add a read policy for authenticated users so they can see cached data for their lookups.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can read property lookups' AND tablename = 'property_lookups'
    ) THEN
        CREATE POLICY "Anyone can read property lookups" ON property_lookups FOR SELECT USING (true);
    END IF;
END $$;
