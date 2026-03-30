-- ============================================================================
-- Equipment Reference Catalog
-- Global knowledge base of home equipment: manufacturers, models, manuals,
-- common issues, and typical service data. NOT household-scoped — this is
-- shared reference data that powers autocomplete, photo ID, and manual lookup.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Manufacturers
-- ----------------------------------------------------------------------------
CREATE TABLE equipment_manufacturers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,               -- url-safe: "sub-zero", "ge-profile"
    parent_company TEXT,                      -- e.g. "Whirlpool" for Amana, Maytag, KitchenAid, JennAir
    country_of_origin TEXT,
    website_url TEXT,
    support_phone TEXT,
    support_url TEXT,
    tier TEXT NOT NULL CHECK (tier IN ('budget', 'mainstream', 'premium', 'luxury', 'ultra-luxury')),
    description TEXT,
    logo_path TEXT,                           -- storage bucket path
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- Appliance Categories
-- ----------------------------------------------------------------------------
CREATE TABLE equipment_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,               -- "Refrigerator", "Dishwasher", etc.
    slug TEXT NOT NULL UNIQUE,               -- "refrigerator", "dishwasher"
    parent_category_id UUID REFERENCES equipment_categories(id),  -- for sub-categories
    icon_name TEXT,                           -- SF Symbol or icon reference
    room TEXT NOT NULL DEFAULT 'kitchen',     -- future: "laundry", "hvac", "outdoor"
    description TEXT,
    typical_lifespan_years INT,              -- average across all brands
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- Equipment Catalog (the main product reference table)
-- ----------------------------------------------------------------------------
CREATE TABLE equipment_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    manufacturer_id UUID REFERENCES equipment_manufacturers(id) NOT NULL,
    category_id UUID REFERENCES equipment_categories(id) NOT NULL,
    model_number TEXT NOT NULL,
    model_name TEXT,                          -- marketing name, e.g. "Family Hub"
    series TEXT,                              -- e.g. "Profile", "Café", "800 Series"
    fuel_type TEXT,                           -- "gas", "electric", "dual-fuel", "induction", null
    color_finish TEXT,                        -- "stainless steel", "matte white", "custom panel"
    width_inches DECIMAL,
    height_inches DECIMAL,
    depth_inches DECIMAL,
    capacity TEXT,                            -- "25.6 cu ft", "44 dBA", etc. (varies by category)
    capacity_value DECIMAL,                   -- numeric for filtering/sorting
    capacity_unit TEXT,                        -- "cu_ft", "dba", "btu", etc.
    energy_star BOOLEAN DEFAULT false,
    wifi_enabled BOOLEAN DEFAULT false,
    installation_type TEXT,                   -- "freestanding", "built-in", "slide-in", "under-counter", "wall-mount", "over-the-range"
    msrp_usd DECIMAL,                        -- manufacturer suggested retail
    year_introduced INT,
    year_discontinued INT,                    -- NULL if still current
    is_current_model BOOLEAN DEFAULT true,
    expected_lifespan_years INT,
    typical_repair_cost_low DECIMAL,
    typical_repair_cost_high DECIMAL,
    key_features TEXT[],                      -- array of notable features
    specs JSONB DEFAULT '{}',                 -- overflow specs (voltage, amps, BTU, etc.)
    image_url TEXT,                           -- product photo URL
    product_url TEXT,                         -- manufacturer product page
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(manufacturer_id, model_number)
);

-- ----------------------------------------------------------------------------
-- Equipment Manuals (PDFs, guides, spec sheets per model)
-- ----------------------------------------------------------------------------
CREATE TABLE equipment_manuals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    catalog_entry_id UUID REFERENCES equipment_catalog(id) ON DELETE CASCADE NOT NULL,
    manual_type TEXT NOT NULL CHECK (manual_type IN (
        'owners_manual', 'installation_guide', 'service_manual',
        'spec_sheet', 'quick_start_guide', 'warranty_info',
        'parts_diagram', 'troubleshooting_guide', 'energy_guide'
    )),
    title TEXT NOT NULL,
    file_path TEXT,                           -- supabase storage path: manuals/{slug}/{model}/file.pdf
    source_url TEXT,                          -- original URL from manufacturer
    file_size_bytes BIGINT,
    page_count INT,
    language TEXT DEFAULT 'en',
    last_verified_at TIMESTAMPTZ,            -- last time we confirmed source_url still works
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- Common Issues & Fixes (crowd-sourced knowledge per model or category)
-- ----------------------------------------------------------------------------
CREATE TABLE equipment_common_issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    catalog_entry_id UUID REFERENCES equipment_catalog(id) ON DELETE CASCADE,  -- specific model (nullable)
    category_id UUID REFERENCES equipment_categories(id),                       -- or whole category
    manufacturer_id UUID REFERENCES equipment_manufacturers(id),                -- or whole brand
    issue_title TEXT NOT NULL,
    description TEXT NOT NULL,
    symptoms TEXT[],                          -- ["leaking water", "loud humming", "not cooling"]
    typical_fix TEXT,
    diy_difficulty TEXT CHECK (diy_difficulty IN ('easy', 'moderate', 'hard', 'professional_only')),
    estimated_repair_cost_low DECIMAL,
    estimated_repair_cost_high DECIMAL,
    typical_occurrence_years INT,             -- how many years in, this issue typically appears
    parts_needed TEXT[],                      -- ["water inlet valve", "door gasket"]
    repair_time_minutes INT,
    source TEXT,                              -- where this info came from
    created_at TIMESTAMPTZ DEFAULT now(),
    CHECK (catalog_entry_id IS NOT NULL OR category_id IS NOT NULL)  -- must relate to something
);

-- ----------------------------------------------------------------------------
-- Typical Service Schedule (recommended maintenance per model or category)
-- ----------------------------------------------------------------------------
CREATE TABLE equipment_service_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    catalog_entry_id UUID REFERENCES equipment_catalog(id) ON DELETE CASCADE,
    category_id UUID REFERENCES equipment_categories(id),
    manufacturer_id UUID REFERENCES equipment_manufacturers(id),
    task_name TEXT NOT NULL,                  -- "Clean condenser coils", "Replace water filter"
    description TEXT,
    frequency_months INT NOT NULL,            -- every N months
    estimated_cost DECIMAL,
    diy_possible BOOLEAN DEFAULT true,
    professional_recommended BOOLEAN DEFAULT false,
    parts_needed TEXT[],
    created_at TIMESTAMPTZ DEFAULT now(),
    CHECK (catalog_entry_id IS NOT NULL OR category_id IS NOT NULL)
);

-- ----------------------------------------------------------------------------
-- Link existing home_systems to catalog
-- ----------------------------------------------------------------------------
ALTER TABLE home_systems
    ADD COLUMN IF NOT EXISTS catalog_entry_id UUID REFERENCES equipment_catalog(id);

-- ----------------------------------------------------------------------------
-- Indexes
-- ----------------------------------------------------------------------------
CREATE INDEX idx_equipment_catalog_manufacturer ON equipment_catalog(manufacturer_id);
CREATE INDEX idx_equipment_catalog_category ON equipment_catalog(category_id);
CREATE INDEX idx_equipment_catalog_model ON equipment_catalog(model_number);
CREATE INDEX idx_equipment_catalog_current ON equipment_catalog(is_current_model) WHERE is_current_model = true;
CREATE INDEX idx_equipment_catalog_search ON equipment_catalog USING gin(to_tsvector('english', coalesce(model_number, '') || ' ' || coalesce(model_name, '') || ' ' || coalesce(series, '')));
CREATE INDEX idx_equipment_manuals_catalog ON equipment_manuals(catalog_entry_id);
CREATE INDEX idx_equipment_manuals_type ON equipment_manuals(manual_type);
CREATE INDEX idx_equipment_common_issues_catalog ON equipment_common_issues(catalog_entry_id);
CREATE INDEX idx_equipment_common_issues_category ON equipment_common_issues(category_id);
CREATE INDEX idx_equipment_service_schedules_catalog ON equipment_service_schedules(catalog_entry_id);
CREATE INDEX idx_equipment_service_schedules_category ON equipment_service_schedules(category_id);
CREATE INDEX idx_home_systems_catalog ON home_systems(catalog_entry_id);

-- Full-text search index for autocomplete
CREATE INDEX idx_equipment_manufacturers_search ON equipment_manufacturers USING gin(to_tsvector('english', name));

-- ----------------------------------------------------------------------------
-- RLS — catalog tables are publicly readable, admin-writable
-- ----------------------------------------------------------------------------
ALTER TABLE equipment_manufacturers ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_manuals ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_common_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_service_schedules ENABLE ROW LEVEL SECURITY;

-- Everyone can read catalog data (it's reference data, not user data)
CREATE POLICY "Anyone can view manufacturers" ON equipment_manufacturers FOR SELECT USING (true);
CREATE POLICY "Anyone can view categories" ON equipment_categories FOR SELECT USING (true);
CREATE POLICY "Anyone can view catalog" ON equipment_catalog FOR SELECT USING (true);
CREATE POLICY "Anyone can view manuals" ON equipment_manuals FOR SELECT USING (true);
CREATE POLICY "Anyone can view common issues" ON equipment_common_issues FOR SELECT USING (true);
CREATE POLICY "Anyone can view service schedules" ON equipment_service_schedules FOR SELECT USING (true);

-- Only service role (admin/edge functions) can write catalog data
-- No INSERT/UPDATE/DELETE policies for authenticated users — writes happen
-- via edge functions or direct admin access with service_role key.

-- ----------------------------------------------------------------------------
-- Updated_at trigger
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_equipment_manufacturers_updated_at
    BEFORE UPDATE ON equipment_manufacturers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_equipment_catalog_updated_at
    BEFORE UPDATE ON equipment_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_equipment_manuals_updated_at
    BEFORE UPDATE ON equipment_manuals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
