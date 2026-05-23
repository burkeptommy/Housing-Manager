-- Phase X+4 — vendor catalog quality cleanup (post-launch-seed sweep).
--
-- After the May 2026 full-launch-footprint seed (CT/NY/MA/RI/MI Oakland,
-- ~14,972 catalog rows), an audit surfaced four classes of integrity
-- issues we want resolved before the catalog goes user-facing.
--
-- Issue 1 — broken regions: 47 admin rows had `regions = []` (empty
-- array, not NULL) so they were invisible to find-a-pro despite being
-- legitimate national brands (Ring, SimpliSafe, Vivint, TruGreen,
-- Terminix, Orkin, Starlink, Google Fiber, etc.). Fix: stamp
-- `regions = ARRAY['US']` so they surface as national fallbacks
-- everywhere — the per-state region-overlap query already prefers
-- local matches.
--
-- Issue 2 — exact-name duplicates inside `google_places`: 50 groups
-- where multi-location brands (Verizon ×6, AL Prime ×4, "Chimney
-- Experts" ×4, Top-Notch Construction ×4) accumulated multiple rows
-- because each physical store has its own google_place_id. The
-- in-flight upsert dedup only collapsed by root domain — these rows
-- have NO website, so domain dedup couldn't fire. Fix: collapse by
-- (lower(name), provider_type), keep the row with the most regions
-- (most-relevant), union all dupes' regions into it, delete the
-- losers.
--
-- Issue 3 — phone duplicates: 30 groups where the same phone digits
-- appear under multiple rows in the same provider_type — same business
-- listed with slightly different names (e.g. "RI BestTree Service"
-- and "Sepe Tree Service" at the same number, or "A-Tec Chimney
-- Sweep" and "A-Tec Chimney Sweep, Repair & Restoration"). Same
-- collapse algorithm as Issue 2 keyed by phone.
--
-- Issue 4 — cross-state contamination: 20 google_places rows tagged
-- with all 5 states because the in-flight root-domain dedup unioned
-- regions across cross-state searches even though the underlying
-- business is genuinely local (e.g. "Arrive Electrical Contractor
-- LLC", phone 203, surfaced incorrectly in MI searches because of
-- name-relevance bleed). Fix: derive the row's real home state from
-- the phone area code; collapse regions to ONLY that state. National
-- brands without a usable phone (toll-free 800/888) → regions=['US'].
--
-- Idempotency: every change is gated on the same conditions that
-- defined the issue. Re-running the migration produces no further
-- changes once the catalog is clean.

BEGIN;

-- ============================================================
-- 1. REPAIR BROKEN REGIONS — admin rows with empty arrays
-- ============================================================
UPDATE utility_providers
SET regions = ARRAY['US']
WHERE source = 'admin'
  AND (regions IS NULL OR array_length(regions, 1) IS NULL OR array_length(regions, 1) = 0);

-- ============================================================
-- 2. COLLAPSE EXACT-NAME DUPES inside google_places
--    For each (lower(name), provider_type) with > 1 row:
--      winner = row with most regions (tiebreak: oldest created_at)
--      winner.regions = union of all dupes' regions
--      delete the losers
-- ============================================================
WITH dupe_groups AS (
  SELECT
    lower(trim(name)) AS name_norm,
    provider_type,
    count(*) AS dupe_count
  FROM utility_providers
  WHERE source = 'google_places'
  GROUP BY lower(trim(name)), provider_type
  HAVING count(*) > 1
),
ranked_rows AS (
  SELECT
    up.id,
    up.name,
    up.regions,
    up.created_at,
    lower(trim(up.name)) AS name_norm,
    up.provider_type,
    coalesce(array_length(up.regions, 1), 0) AS region_count,
    row_number() OVER (
      PARTITION BY lower(trim(up.name)), up.provider_type
      ORDER BY coalesce(array_length(up.regions, 1), 0) DESC, up.created_at ASC
    ) AS rank
  FROM utility_providers up
  JOIN dupe_groups dg
    ON lower(trim(up.name)) = dg.name_norm
    AND up.provider_type = dg.provider_type
  WHERE up.source = 'google_places'
),
unions AS (
  SELECT
    name_norm,
    provider_type,
    -- Union of all distinct region tokens across all rows in the group
    (SELECT array_agg(DISTINCT r ORDER BY r)
       FROM (
         SELECT unnest(regions) AS r FROM ranked_rows rr2
         WHERE rr2.name_norm = ranked_rows.name_norm
           AND rr2.provider_type = ranked_rows.provider_type
       ) sub) AS unioned_regions
  FROM ranked_rows
  GROUP BY name_norm, provider_type
),
winners AS (
  SELECT id, name_norm, provider_type
  FROM ranked_rows
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
USING ranked_rows rr
WHERE up.id = rr.id
  AND rr.rank > 1;

-- ============================================================
-- 3. COLLAPSE PHONE DUPES (same digits + same provider_type)
-- ============================================================
WITH normalized AS (
  SELECT
    id, name, provider_type, regions, created_at,
    regexp_replace(coalesce(phone, ''), '\D', '', 'g') AS digits
  FROM utility_providers
),
dupe_groups AS (
  SELECT digits, provider_type
  FROM normalized
  WHERE length(digits) >= 10
  GROUP BY digits, provider_type
  HAVING count(*) > 1
),
ranked_rows AS (
  SELECT
    n.id, n.name, n.regions, n.created_at, n.digits, n.provider_type,
    row_number() OVER (
      PARTITION BY n.digits, n.provider_type
      ORDER BY coalesce(array_length(n.regions, 1), 0) DESC, n.created_at ASC
    ) AS rank
  FROM normalized n
  JOIN dupe_groups dg
    ON n.digits = dg.digits AND n.provider_type = dg.provider_type
),
unions AS (
  SELECT
    digits, provider_type,
    (SELECT array_agg(DISTINCT r ORDER BY r)
       FROM (
         SELECT unnest(regions) AS r FROM ranked_rows rr2
         WHERE rr2.digits = ranked_rows.digits
           AND rr2.provider_type = ranked_rows.provider_type
       ) sub) AS unioned_regions
  FROM ranked_rows
  GROUP BY digits, provider_type
),
winners AS (
  SELECT id, digits, provider_type
  FROM ranked_rows
  WHERE rank = 1
),
update_winners AS (
  UPDATE utility_providers up
  SET regions = u.unioned_regions
  FROM winners w
  JOIN unions u
    ON u.digits = w.digits
    AND u.provider_type = w.provider_type
  WHERE up.id = w.id
  RETURNING up.id
)
DELETE FROM utility_providers up
USING ranked_rows rr
WHERE up.id = rr.id
  AND rr.rank > 1;

-- ============================================================
-- 4. STRIP CROSS-STATE CONTAMINATION
--    Rows in source='google_places' tagged with > 1 northeast state.
--    Derive home state from phone area code; collapse regions to
--    just that state. Toll-free phones (800/833/844/855/866/877/888)
--    or missing phones → regions = ['US'] (national/multi-state).
-- ============================================================
WITH area_to_state(area, code) AS (
  VALUES
    -- CT
    ('203','CT'),('475','CT'),('860','CT'),('959','CT'),
    -- NY
    ('212','NY'),('315','NY'),('332','NY'),('347','NY'),('516','NY'),('518','NY'),
    ('585','NY'),('607','NY'),('631','NY'),('646','NY'),('680','NY'),('716','NY'),
    ('718','NY'),('838','NY'),('845','NY'),('914','NY'),('917','NY'),('929','NY'),('934','NY'),
    -- MA
    ('339','MA'),('351','MA'),('413','MA'),('508','MA'),('617','MA'),('774','MA'),
    ('781','MA'),('857','MA'),('978','MA'),
    -- RI
    ('401','RI'),
    -- MI
    ('231','MI'),('248','MI'),('269','MI'),('313','MI'),('517','MI'),('586','MI'),
    ('616','MI'),('679','MI'),('734','MI'),('810','MI'),('906','MI'),('947','MI'),('989','MI'),
    -- Neighboring states (so we don't mis-tag rows that come from neighbors)
    ('603','NH'),('802','VT'),('207','ME'),('201','NJ'),('732','NJ'),('551','NJ'),
    ('215','PA'),('484','PA'),('610','PA'),('717','PA')
),
contaminated AS (
  SELECT
    id, name, phone, regions,
    regexp_replace(coalesce(phone, ''), '\D', '', 'g') AS digits,
    array(
      SELECT unnest(regions) INTERSECT
      SELECT unnest(ARRAY['CT','NY','MA','RI','MI','NH','VT','ME','NJ','PA'])
    ) AS state_codes
  FROM utility_providers
  WHERE source = 'google_places'
),
derived AS (
  SELECT
    c.id,
    c.name,
    CASE
      WHEN length(c.digits) = 10 THEN substring(c.digits FROM 1 FOR 3)
      WHEN length(c.digits) = 11 AND substring(c.digits FROM 1 FOR 1) = '1'
        THEN substring(c.digits FROM 2 FOR 3)
      ELSE NULL
    END AS area_code,
    c.state_codes
  FROM contaminated c
  WHERE array_length(c.state_codes, 1) > 1
)
UPDATE utility_providers up
SET regions = CASE
  WHEN ats.code IS NOT NULL THEN ARRAY[ats.code]
  ELSE ARRAY['US']
END
FROM derived d
LEFT JOIN area_to_state ats ON ats.area = d.area_code
WHERE up.id = d.id;

-- ============================================================
-- POST-MIGRATION SANITY: log final counts so we can verify in
-- the supabase output stream.
-- ============================================================
DO $$
DECLARE
  total_rows int;
  google_rows int;
  admin_rows int;
  empty_regions int;
  cross_state int;
BEGIN
  SELECT count(*) INTO total_rows FROM utility_providers;
  SELECT count(*) INTO google_rows FROM utility_providers WHERE source = 'google_places';
  SELECT count(*) INTO admin_rows FROM utility_providers WHERE source = 'admin';
  SELECT count(*) INTO empty_regions FROM utility_providers
    WHERE regions IS NULL OR array_length(regions, 1) IS NULL OR array_length(regions, 1) = 0;
  SELECT count(*) INTO cross_state FROM (
    SELECT id FROM utility_providers
    WHERE source = 'google_places'
      AND (SELECT count(*) FROM (
        SELECT unnest(regions) INTERSECT
        SELECT unnest(ARRAY['CT','NY','MA','RI','MI','NH','VT','ME','NJ','PA'])
      ) s) > 1
  ) sub;
  RAISE NOTICE 'utility_providers cleanup: total=%, google=%, admin=%, empty_regions=%, cross_state_rows=%',
    total_rows, google_rows, admin_rows, empty_regions, cross_state;
END $$;

COMMIT;
