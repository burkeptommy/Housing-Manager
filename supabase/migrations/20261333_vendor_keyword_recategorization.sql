-- Phase X+7 follow-up: heuristic recategorization of self-evident
-- specialty vendors based on business name keywords.
--
-- Google Places routes vendors into our category buckets via search
-- relevance, not business reality. A company literally named "Rick's
-- Pump and Water Service" ended up classified as `plumbing` because
-- it surfaced first in a plumbing search. The user looking for a
-- well water pro never sees them.
--
-- Fix: for each strong name-keyword pattern, add the implied category
-- to `secondary_provider_types` if it isn't already there. Conservative
-- — only fire on unambiguous patterns. Idempotent (re-running adds
-- nothing new).

BEGIN;

-- Helper: union a category into secondary_provider_types unless
-- already present (and not equal to primary).
CREATE OR REPLACE FUNCTION pg_temp.add_secondary(p_id uuid, p_cat text)
RETURNS void AS $$
DECLARE
  current_primary text;
  current_sec text[];
BEGIN
  SELECT provider_type, coalesce(secondary_provider_types, ARRAY[]::text[])
    INTO current_primary, current_sec
    FROM utility_providers WHERE id = p_id;
  IF current_primary = p_cat THEN RETURN; END IF;
  IF p_cat = ANY(current_sec) THEN RETURN; END IF;
  UPDATE utility_providers
  SET secondary_provider_types = (
    SELECT array_agg(t ORDER BY t)
    FROM unnest(current_sec || ARRAY[p_cat]) AS t
  )
  WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- Well water service: "pump" + ("water"|"well") OR "well" + "drill"
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND (
        (lower(name) ~ 'pump' AND lower(name) ~ '(water|well)')
        OR (lower(name) ~ 'well' AND lower(name) ~ '(drill|service)')
      )
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'well_water_service');
  END LOOP;
END $$;

-- Chimney sweep: "chimney" + ("sweep"|"clean"|"service")
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND lower(name) ~ 'chimney'
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'chimney_sweep');
  END LOOP;
END $$;

-- Septic pumper: "septic" + ("pump"|"service"|"tank"|"clean")
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND lower(name) ~ 'septic'
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'septic_pumper');
  END LOOP;
END $$;

-- Tree service: name contains "tree" (broad, but specific enough)
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND lower(name) ~ '\mtree\M'  -- word boundary, avoids matching "boutique"
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'tree_service');
  END LOOP;
END $$;

-- Garage door: "garage" + "door"
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND lower(name) ~ 'garage' AND lower(name) ~ 'door'
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'garage_door');
  END LOOP;
END $$;

-- Roofing: "roof"
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND lower(name) ~ 'roof'
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'roofing');
  END LOOP;
END $$;

-- Plumbing: "plumb"
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND lower(name) ~ 'plumb'
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'plumbing');
  END LOOP;
END $$;

-- Electrical: "electric" (broader — also covers "electrical contractor",
-- "electricians"), excluding obvious utility-only matches.
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND lower(name) ~ 'electric'
      AND lower(name) !~ 'utility|cooperative|power company'
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'electrical');
  END LOOP;
END $$;

-- HVAC: "heating" + "cooling"|"air" OR "hvac" OR "air conditioning"
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND (
        lower(name) ~ 'hvac'
        OR lower(name) ~ 'air conditioning'
        OR (lower(name) ~ 'heating' AND lower(name) ~ '(cool|air)')
      )
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'hvac');
  END LOOP;
END $$;

-- Pool service: "pool" + ("service"|"care"|"maintenance")
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND lower(name) ~ 'pool'
      AND lower(name) !~ 'pool table|pool hall|pool party'
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'pool_service');
  END LOOP;
END $$;

-- Waterproofing: "waterproof" OR "basement"
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND (lower(name) ~ 'waterproof' OR lower(name) ~ 'basement')
  LOOP
    PERFORM pg_temp.add_secondary(r.id, 'waterproofing');
  END LOOP;
END $$;

-- Sanity check
DO $$
DECLARE
  multi_cat_count int;
  ricks_secondary text[];
BEGIN
  SELECT count(*) INTO multi_cat_count
  FROM utility_providers
  WHERE array_length(secondary_provider_types, 1) > 0;
  SELECT secondary_provider_types INTO ricks_secondary
  FROM utility_providers
  WHERE name ILIKE 'rick%pump%water%' LIMIT 1;
  RAISE NOTICE 'After keyword recategorization: % multi-cat rows. Ricks Pump secondaries: %',
    multi_cat_count, ricks_secondary;
END $$;

COMMIT;
