-- Phase 57: Regional maintenance pack on properties.
-- Purely additive. Does not touch maintenance_tasks or home_systems.

ALTER TABLE properties
  ADD COLUMN IF NOT EXISTS regional_pack TEXT;

COMMENT ON COLUMN properties.regional_pack IS
  'Regional maintenance pack derived from state (northeast, southeast, midwest, southwest, west). NULL when state is unknown.';

-- Backfill from state. Case-insensitive via UPPER() guard not needed because
-- `state` is already persisted as two-letter ISO codes.

UPDATE properties SET regional_pack = 'northeast'
WHERE regional_pack IS NULL
  AND state IN ('CT', 'ME', 'MA', 'NH', 'NJ', 'NY', 'PA', 'RI', 'VT');

UPDATE properties SET regional_pack = 'southeast'
WHERE regional_pack IS NULL
  AND state IN ('AL', 'AR', 'DE', 'FL', 'GA', 'KY', 'LA', 'MD', 'MS', 'NC', 'SC', 'TN', 'VA', 'WV', 'DC');

UPDATE properties SET regional_pack = 'midwest'
WHERE regional_pack IS NULL
  AND state IN ('IL', 'IN', 'IA', 'KS', 'MI', 'MN', 'MO', 'NE', 'ND', 'OH', 'SD', 'WI');

UPDATE properties SET regional_pack = 'southwest'
WHERE regional_pack IS NULL
  AND state IN ('AZ', 'NM', 'OK', 'TX');

UPDATE properties SET regional_pack = 'west'
WHERE regional_pack IS NULL
  AND state IN ('AK', 'CA', 'CO', 'HI', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY');

CREATE INDEX IF NOT EXISTS idx_properties_regional_pack
  ON properties(regional_pack)
  WHERE regional_pack IS NOT NULL;
