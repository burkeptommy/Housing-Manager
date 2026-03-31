-- Add unique partial indexes for upsert support on equipment_scores
CREATE UNIQUE INDEX IF NOT EXISTS idx_equipment_scores_unique_brand
    ON equipment_scores(manufacturer_id) WHERE catalog_entry_id IS NULL AND category_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_equipment_scores_unique_model
    ON equipment_scores(catalog_entry_id) WHERE catalog_entry_id IS NOT NULL;
