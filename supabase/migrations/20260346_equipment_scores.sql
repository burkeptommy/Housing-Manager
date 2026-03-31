-- Equipment reliability scores — AI-generated from catalog data + Claude's knowledge
-- of industry sources (Consumer Reports, repair communities, owner forums).
-- Scores are cached with a 90-day TTL for periodic refreshing.

CREATE TABLE IF NOT EXISTS equipment_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Polymorphic target: score a specific model, a brand, or a brand+category combo
    catalog_entry_id UUID REFERENCES equipment_catalog(id) ON DELETE CASCADE,
    manufacturer_id UUID REFERENCES equipment_manufacturers(id) ON DELETE CASCADE,
    category_id UUID REFERENCES equipment_categories(id) ON DELETE SET NULL,

    -- Scores (1-100)
    overall_score INT CHECK (overall_score BETWEEN 1 AND 100),
    reliability_score INT CHECK (reliability_score BETWEEN 1 AND 100),
    value_score INT CHECK (value_score BETWEEN 1 AND 100),
    repairability_score INT CHECK (repairability_score BETWEEN 1 AND 100),
    longevity_score INT CHECK (longevity_score BETWEEN 1 AND 100),

    -- Human-readable context
    summary TEXT,
    pros TEXT[],
    cons TEXT[],

    -- Metadata
    data_sources TEXT[],
    generated_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + interval '90 days'),

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for fast lookups
CREATE INDEX idx_equipment_scores_catalog ON equipment_scores(catalog_entry_id) WHERE catalog_entry_id IS NOT NULL;
CREATE INDEX idx_equipment_scores_manufacturer ON equipment_scores(manufacturer_id) WHERE manufacturer_id IS NOT NULL;
CREATE INDEX idx_equipment_scores_mfg_category ON equipment_scores(manufacturer_id, category_id) WHERE manufacturer_id IS NOT NULL AND category_id IS NOT NULL;
CREATE INDEX idx_equipment_scores_expires ON equipment_scores(expires_at);

-- Brand-level quick score on manufacturers table
ALTER TABLE equipment_manufacturers
    ADD COLUMN IF NOT EXISTS reliability_score INT CHECK (reliability_score BETWEEN 1 AND 100),
    ADD COLUMN IF NOT EXISTS score_summary TEXT;

-- RLS: everyone can read scores (reference data)
ALTER TABLE equipment_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view equipment scores" ON equipment_scores FOR SELECT USING (true);

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_equipment_scores_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER equipment_scores_updated_at
    BEFORE UPDATE ON equipment_scores
    FOR EACH ROW EXECUTE FUNCTION update_equipment_scores_updated_at();
