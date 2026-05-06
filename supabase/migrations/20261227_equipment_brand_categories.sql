-- Phase 2 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
--
-- Adds two pieces of scaffolding the multi-category brand sweep needs:
--
-- 1. equipment_brand_categories — a lookup table populated by the
--    expand-brand-categories edge function. One row per (manufacturer,
--    category) combination Claude identifies the brand as making products
--    in. The Phase 3 expand-catalog driver iterates this table to know
--    which (brand, category) pairs to generate models for.
--
-- 2. equipment_manufacturers.parent_brand_family — a soft grouping for
--    sibling brands (Whirlpool family: Whirlpool / Maytag / KitchenAid /
--    Amana / Jenn-Air; BSH: Bosch / Thermador / Gaggenau; Rheem family:
--    Rheem / Ruud / Richmond; etc). Phase 3's prompt warns Claude not to
--    duplicate the same SKU across siblings — primary brand owns it.
--
-- RLS: catalog tables are public-read, service-role-write. Same pattern
-- as equipment_manufacturers / equipment_categories.

BEGIN;

-- ----------------------------------------------------------------------------
-- equipment_brand_categories — Phase 2 sweep output
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS equipment_brand_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    manufacturer_id UUID NOT NULL REFERENCES equipment_manufacturers(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES equipment_categories(id) ON DELETE CASCADE,
    confidence INT NOT NULL CHECK (confidence BETWEEN 0 AND 100),
    -- "current" / "discontinued" / "regional" — flags for Phase 3 prompt context
    market_status TEXT NOT NULL DEFAULT 'current' CHECK (
        market_status IN ('current', 'discontinued', 'regional', 'historical')
    ),
    -- Free-text notes from Claude about coverage (e.g. "LG only sells heat
    -- pumps in EU/AU markets, not US"). Used by Phase 3 prompt context.
    notes TEXT,
    -- Track when Claude generated this so we can refresh quarterly
    sourced_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (manufacturer_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_equipment_brand_categories_manufacturer
    ON equipment_brand_categories(manufacturer_id);

CREATE INDEX IF NOT EXISTS idx_equipment_brand_categories_category
    ON equipment_brand_categories(category_id);

CREATE INDEX IF NOT EXISTS idx_equipment_brand_categories_confidence
    ON equipment_brand_categories(confidence)
    WHERE confidence >= 70;

ALTER TABLE equipment_brand_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on equipment_brand_categories"
    ON equipment_brand_categories;

CREATE POLICY "Public read access on equipment_brand_categories"
    ON equipment_brand_categories FOR SELECT
    USING (true);

-- No INSERT/UPDATE/DELETE policy — service_role only via edge functions.

COMMENT ON TABLE equipment_brand_categories IS
  'Lookup of which categories each manufacturer makes products in. Populated by expand-brand-categories edge function. Phase 3 driver iterates rows where confidence >= 70.';
COMMENT ON COLUMN equipment_brand_categories.market_status IS
  'current / discontinued / regional / historical — flags Phase 3 prompt context.';

-- ----------------------------------------------------------------------------
-- equipment_manufacturers.parent_brand_family
-- ----------------------------------------------------------------------------

ALTER TABLE equipment_manufacturers
    ADD COLUMN IF NOT EXISTS parent_brand_family TEXT;

CREATE INDEX IF NOT EXISTS idx_equipment_manufacturers_brand_family
    ON equipment_manufacturers(parent_brand_family)
    WHERE parent_brand_family IS NOT NULL;

COMMENT ON COLUMN equipment_manufacturers.parent_brand_family IS
  'Soft brand-family grouping for sibling-aware dedup in Phase 3. Each brand belongs to at most one family. Examples: whirlpool (Whirlpool / Maytag / KitchenAid / Amana / Jenn-Air / Roper), bsh (Bosch / Thermador / Gaggenau), ge-appliances (GE / GE Profile / Cafe / Monogram / Hotpoint / Haier), rheem (Rheem / Ruud / Richmond / EcoSmart), ao-smith (AO Smith / State / American / Reliance), trane-tech (Trane / American Standard HVAC / Ameristar / Runtru), carrier (Carrier / Bryant / Payne / Heil / Ducane), fluidra (Jandy / Polaris / Zodiac), pentair (Pentair / Sta-Rite / Paramount / Berkeley), hht-hearth (Heatilator / Heat & Glo / Majestic / Quadrafire / Harman), travis (Travis Industries / Lopi).';

-- Pre-fill the well-known families. Each brand maps to exactly one family
-- (no double-assignment). Brands not listed here can be filled in by Phase 2
-- sweep or admin curation later.

UPDATE equipment_manufacturers SET parent_brand_family = 'whirlpool'
    WHERE slug IN ('whirlpool', 'maytag', 'kitchenaid', 'amana', 'jennair', 'roper');

UPDATE equipment_manufacturers SET parent_brand_family = 'bsh'
    WHERE slug IN ('bosch', 'thermador', 'gaggenau');

UPDATE equipment_manufacturers SET parent_brand_family = 'ge-appliances'
    WHERE slug IN ('ge-appliances', 'ge-profile', 'cafe', 'monogram', 'hotpoint', 'haier');

UPDATE equipment_manufacturers SET parent_brand_family = 'rheem'
    WHERE slug IN ('rheem', 'ruud', 'richmond', 'ecosmart');

UPDATE equipment_manufacturers SET parent_brand_family = 'ao-smith'
    WHERE slug IN ('ao-smith', 'state-water-heaters', 'american-water-heaters', 'reliance');

UPDATE equipment_manufacturers SET parent_brand_family = 'trane-tech'
    WHERE slug IN ('trane', 'american-standard-hvac', 'ameristar', 'runtru');

UPDATE equipment_manufacturers SET parent_brand_family = 'carrier'
    WHERE slug IN ('carrier', 'bryant', 'payne', 'heil', 'ducane');

UPDATE equipment_manufacturers SET parent_brand_family = 'electrolux'
    WHERE slug IN ('electrolux', 'frigidaire', 'electrolux-central');

UPDATE equipment_manufacturers SET parent_brand_family = 'masco'
    WHERE slug IN ('delta-faucet', 'brizo', 'peerless-faucet', 'kichler');

UPDATE equipment_manufacturers SET parent_brand_family = 'fortune-brands'
    WHERE slug IN ('therma-tru', 'moen');

UPDATE equipment_manufacturers SET parent_brand_family = 'kohler'
    WHERE slug IN ('kohler', 'kohler-generators', 'sterling', 'kallista');

UPDATE equipment_manufacturers SET parent_brand_family = 'lixil'
    WHERE slug IN ('american-standard', 'dxv', 'grohe');

UPDATE equipment_manufacturers SET parent_brand_family = 'sub-zero-group'
    WHERE slug IN ('wolf', 'sub-zero', 'cove');

UPDATE equipment_manufacturers SET parent_brand_family = 'hht-hearth'
    WHERE slug IN ('heatilator', 'heat-and-glo', 'majestic', 'quadrafire', 'harman-stoves');

UPDATE equipment_manufacturers SET parent_brand_family = 'travis'
    WHERE slug IN ('travis-industries', 'lopi');

UPDATE equipment_manufacturers SET parent_brand_family = 'amazon'
    WHERE slug IN ('ring', 'blink');

UPDATE equipment_manufacturers SET parent_brand_family = 'anker'
    WHERE slug IN ('eufy', 'anker-solix');

UPDATE equipment_manufacturers SET parent_brand_family = 'google'
    WHERE slug IN ('nest', 'google-nest');

UPDATE equipment_manufacturers SET parent_brand_family = 'sound-united'
    WHERE slug IN ('denon', 'marantz', 'polk-audio', 'definitive-technology', 'bowers-wilkins');

UPDATE equipment_manufacturers SET parent_brand_family = 'enphase'
    WHERE slug IN ('enphase', 'clippercreek');

UPDATE equipment_manufacturers SET parent_brand_family = 'enel-x'
    WHERE slug IN ('enel-x', 'juicebox');

UPDATE equipment_manufacturers SET parent_brand_family = 'wallbox'
    WHERE slug IN ('wallbox', 'pulsar-plus');

UPDATE equipment_manufacturers SET parent_brand_family = 'tesla'
    WHERE slug IN ('tesla', 'tesla-solar');

UPDATE equipment_manufacturers SET parent_brand_family = 'middleby'
    WHERE slug IN ('viking', 'lynx');

UPDATE equipment_manufacturers SET parent_brand_family = 'fisher-paykel-group'
    WHERE slug IN ('fisher-paykel', 'dcs');

UPDATE equipment_manufacturers SET parent_brand_family = 'ariens-co'
    WHERE slug IN ('ariens', 'gravely');

UPDATE equipment_manufacturers SET parent_brand_family = 'toro-co'
    WHERE slug IN ('toro', 'exmark');

UPDATE equipment_manufacturers SET parent_brand_family = 'mtd'
    WHERE slug IN ('cub-cadet', 'troy-bilt', 'robomow');

UPDATE equipment_manufacturers SET parent_brand_family = 'briggs-co'
    WHERE slug IN ('briggs-stratton', 'snapper');

UPDATE equipment_manufacturers SET parent_brand_family = 'husqvarna-group'
    WHERE slug IN ('husqvarna', 'husqvarna-automower');

UPDATE equipment_manufacturers SET parent_brand_family = 'pentair'
    WHERE slug IN ('pentair', 'sta-rite', 'paramount', 'berkeley');

UPDATE equipment_manufacturers SET parent_brand_family = 'hayward'
    WHERE slug IN ('hayward', 'aquabot');

UPDATE equipment_manufacturers SET parent_brand_family = 'fluidra'
    WHERE slug IN ('jandy', 'polaris-pool', 'zodiac-pool');

UPDATE equipment_manufacturers SET parent_brand_family = 'assa-abloy'
    WHERE slug IN ('august-locks', 'yale-locks');

-- Verify the prefills landed
DO $$
DECLARE
    family_count INT;
BEGIN
    SELECT COUNT(*) INTO family_count
    FROM equipment_manufacturers
    WHERE parent_brand_family IS NOT NULL;
    RAISE NOTICE 'Pre-filled parent_brand_family on % manufacturers', family_count;
END $$;

COMMIT;
