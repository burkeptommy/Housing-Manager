-- Phase X+5 follow-up: Strip catalog rows whose formatted address
-- contradicts their assigned regions.
--
-- Bug: Google Places Text Search returns name-relevant results that
-- don't always live in the queried region. A query for "trash and
-- recycling pickup service near Redding, CT" returned Redding,
-- California businesses because Places matched on the town name
-- regardless of state. The find-local-vendors edge function
-- snapshotted those into utility_providers with regions=['Redding',
-- 'CT'], so a CT user searching "Redding" in the trash category sees
-- California businesses.

BEGIN;

-- 1) DELETE rows whose address state is outside the 10-state northeast
--    launch footprint. Those are unambiguously wrong-region snapshots.
DELETE FROM utility_providers up
WHERE up.source = 'google_places'
  AND up.address IS NOT NULL
  AND up.address <> ''
  AND upper(substring(up.address FROM ', ([A-Z]{2}) [0-9]{5}')) IS NOT NULL
  AND upper(substring(up.address FROM ', ([A-Z]{2}) [0-9]{5}'))
      NOT IN ('CT','NY','MA','RI','MI','NH','VT','ME','NJ','PA');

-- 2) For surviving rows whose address state IS in the footprint but
--    isn't in the row's regions array, restrict regions to only that
--    state (drop the wrongly-tagged adjacent state codes — but keep
--    town names since they may still be relevant if the vendor
--    services across borders).
WITH parsed AS (
  SELECT
    id, address, regions,
    upper(substring(address FROM ', ([A-Z]{2}) [0-9]{5}')) AS addr_state
  FROM utility_providers
  WHERE source = 'google_places'
    AND address IS NOT NULL
),
ne_set AS (
  SELECT unnest(ARRAY['CT','NY','MA','RI','MI','NH','VT','ME','NJ','PA']) AS code
),
mismatched AS (
  SELECT p.id, p.addr_state, p.regions
  FROM parsed p
  WHERE p.addr_state IS NOT NULL
    AND p.addr_state IN (SELECT code FROM ne_set)
    AND NOT (p.addr_state = ANY(p.regions))
),
expanded AS (
  -- One row per (id, region-token), kept only if the token is NOT a
  -- mismatched-state code (i.e. keep towns + the correct state).
  SELECT
    m.id,
    m.addr_state,
    r AS region_token
  FROM mismatched m,
       LATERAL unnest(m.regions) AS r
  WHERE r NOT IN (SELECT code FROM ne_set)  -- drop ALL state codes
     OR r = m.addr_state                     -- but keep the right one
),
rebuilt AS (
  SELECT
    id,
    addr_state,
    array_agg(DISTINCT region_token ORDER BY region_token) AS kept_regions
  FROM expanded
  GROUP BY id, addr_state
)
UPDATE utility_providers up
SET regions = (
  -- Union kept_regions with the correct address state, in case the
  -- address state wasn't already in the kept set.
  SELECT array_agg(DISTINCT r ORDER BY r)
  FROM (
    SELECT unnest(rb.kept_regions) AS r
    UNION
    SELECT rb.addr_state
  ) sub
)
FROM rebuilt rb
WHERE up.id = rb.id;

DO $$
DECLARE
  remaining int;
BEGIN
  SELECT count(*) INTO remaining
  FROM utility_providers
  WHERE source = 'google_places'
    AND address IS NOT NULL
    AND upper(substring(address FROM ', ([A-Z]{2}) [0-9]{5}')) NOT IN
        ('CT','NY','MA','RI','MI','NH','VT','ME','NJ','PA')
    AND upper(substring(address FROM ', ([A-Z]{2}) [0-9]{5}')) IS NOT NULL;
  RAISE NOTICE 'Rows with non-NE address remaining: %', remaining;
END $$;

COMMIT;
