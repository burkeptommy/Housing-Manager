-- Add subtype column to home_systems for homeowner curation (turf vs lawn,
-- heat pump vs boiler, saltwater vs chlorine, tankless vs tank, etc.).
-- Stores comma-joined subtype tokens consumed by MaintenanceTemplates.activeSubtypes(...).

ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS subtype TEXT;

-- Backfill: existing Landscaping systems default to natural lawn (current behavior).
UPDATE home_systems
SET subtype = 'lawn'
WHERE LOWER(category) = 'landscaping' AND subtype IS NULL;

-- Tier 4: free-text custom category name (used when category = 'Other').
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS custom_category_name TEXT;
