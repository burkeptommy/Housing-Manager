-- Phase X+4 follow-up: collapse admin + admin and admin + google_places
-- exact-name duplicates that the prior migration (20261327) intentionally
-- left alone (which only deduped pure-google_places groups).
--
-- Issues remaining after 20261327:
--   • Pure admin dupes (e.g. "a1 exterminators" ×2, "geico" ×2) —
--     legacy seed bugs that inserted the same brand twice.
--   • Mixed admin + google_places overlaps (e.g. "allstate" ×2 where
--     find-a-pro discovered an Allstate row alongside the admin one) —
--     the admin row is the canonical national brand; the google_places
--     row is a regional store snapshot.
--
-- Algorithm: same as 20261327's exact-name pass, but
--   - operates across ALL sources (not just google_places),
--   - winner ranking prefers admin source first, then most regions,
--     then oldest created_at.
--   - winner's regions = union of ALL dupe rows' regions.

BEGIN;

WITH dupe_groups AS (
  SELECT lower(trim(name)) AS name_norm, provider_type
  FROM utility_providers
  GROUP BY lower(trim(name)), provider_type
  HAVING count(*) > 1
),
ranked AS (
  SELECT
    up.id,
    up.name,
    up.source,
    up.regions,
    up.created_at,
    lower(trim(up.name)) AS name_norm,
    up.provider_type,
    coalesce(array_length(up.regions, 1), 0) AS region_count,
    row_number() OVER (
      PARTITION BY lower(trim(up.name)), up.provider_type
      ORDER BY
        CASE up.source
          WHEN 'admin' THEN 0
          WHEN 'vendor_application' THEN 1
          WHEN 'user_verified' THEN 2
          WHEN 'google_places' THEN 3
          WHEN 'user_pending' THEN 4
          ELSE 5
        END ASC,
        coalesce(array_length(up.regions, 1), 0) DESC,
        up.created_at ASC
    ) AS rank
  FROM utility_providers up
  JOIN dupe_groups dg
    ON lower(trim(up.name)) = dg.name_norm
    AND up.provider_type = dg.provider_type
),
unions AS (
  SELECT
    name_norm,
    provider_type,
    (SELECT array_agg(DISTINCT r ORDER BY r)
       FROM (
         SELECT unnest(regions) AS r FROM ranked rr2
         WHERE rr2.name_norm = ranked.name_norm
           AND rr2.provider_type = ranked.provider_type
       ) sub) AS unioned_regions
  FROM ranked
  GROUP BY name_norm, provider_type
),
winners AS (
  SELECT id, name_norm, provider_type
  FROM ranked
  WHERE rank = 1
),
update_winners AS (
  UPDATE utility_providers up
  SET regions = u.unioned_regions
  FROM winners w
  JOIN unions u
    ON u.name_norm = w.name_norm
    AND u.provider_type = w.provider_type
  WHERE up.id = w.id
  RETURNING up.id
)
DELETE FROM utility_providers up
USING ranked rr
WHERE up.id = rr.id
  AND rr.rank > 1;

-- Post-migration sanity log
DO $$
DECLARE
  remaining_dupes int;
BEGIN
  SELECT count(*) INTO remaining_dupes FROM (
    SELECT lower(trim(name)), provider_type
    FROM utility_providers
    GROUP BY lower(trim(name)), provider_type
    HAVING count(*) > 1
  ) sub;
  RAISE NOTICE 'Remaining exact-name dupe groups after 20261328: %', remaining_dupes;
END $$;

COMMIT;
