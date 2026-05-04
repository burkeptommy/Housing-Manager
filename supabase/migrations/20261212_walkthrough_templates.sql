-- Phase 85 — walkthrough_templates table + 15 seed templates.
--
-- The walk-through (Section 2 of the new onboarding) is dynamic: it
-- composes from intake answers rather than rendering a static form. A
-- homeowner with no pool doesn't see a Pool section; a homeowner with a
-- generator does. Each per-category template defines:
--   • What fields to capture (manufacturer, model, install year, etc.)
--   • Which intake answer triggers this template's inclusion
--   • Whether it's a core system (always considered) or a specialty
--     system (only included if intake confirmed it)
--
-- Same template drives both the iOS self-serve WalkthroughView AND the
-- operations SPA AssessmentWalkthrough.tsx so handyman + homeowner
-- capture the same shape.
--
-- v1: 15 templates seeded inline. Future Phase 86 admin editor will let
-- Tom curate fields without code changes.

-- ===========================================================================
-- Schema
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.walkthrough_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Category key — matches SystemCategoryRegistry on iOS. The walk-
    -- through composes templates by matching this against the home_systems
    -- created by the intake quiz.
    category TEXT NOT NULL,

    -- Display label shown to the homeowner / handyman.
    display_name TEXT NOT NULL,

    -- "core" = always shown if home_systems row exists for this category.
    -- "specialty" = only shown if the homeowner explicitly confirmed having
    -- one in the intake (pool, generator, solar, septic, well, etc.).
    tier TEXT NOT NULL CHECK (tier IN ('core', 'specialty')),

    -- SF Symbol name for the section header icon.
    icon TEXT,

    -- Fields to capture. JSONB array of:
    --   { key, label, type, required, source_hint?, options?, max_count? }
    -- type ∈ ('text', 'number', 'date_year', 'enum', 'photos', 'long_text')
    -- source_hint surfaces a "(from ATTOM)" / "(handyman observed)" caption
    fields JSONB NOT NULL DEFAULT '[]'::JSONB,

    -- Predicate for dynamic inclusion. Read by the walk-through composer
    -- to decide whether to render this template based on intake answers.
    --
    -- Shape (all optional, AND'd together):
    --   {
    --     "requires_home_system_category": "HVAC",   -- a home_systems row in this category exists
    --     "requires_attribute": "has_pool",          -- properties.attributes flag set
    --     "requires_quiz_answer": {                  -- specific quiz answer matches
    --        "question_id": "q22_generator",
    --        "answer_in": ["natural_gas", "propane"]
    --     }
    --   }
    --
    -- Composer treats `null` / empty as "always include if tier matches."
    applies_when JSONB,

    -- Order within the walk-through. Lower = earlier.
    sort_order INTEGER NOT NULL DEFAULT 100,

    -- Soft-delete; archived templates stop appearing in new walk-throughs
    -- but old captures keep their reference.
    archived_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS walkthrough_templates_category_idx
    ON public.walkthrough_templates (category)
    WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS walkthrough_templates_tier_idx
    ON public.walkthrough_templates (tier, sort_order)
    WHERE archived_at IS NULL;

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.touch_walkthrough_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS walkthrough_templates_updated_at ON public.walkthrough_templates;
CREATE TRIGGER walkthrough_templates_updated_at
    BEFORE UPDATE ON public.walkthrough_templates
    FOR EACH ROW EXECUTE FUNCTION public.touch_walkthrough_templates_updated_at();

-- RLS: read-only to everyone authenticated (templates are public catalog
-- data, not household-scoped). Writes restricted to admin via service
-- role (chez-concierge or direct SQL).
ALTER TABLE public.walkthrough_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "walkthrough_templates_read" ON public.walkthrough_templates;
CREATE POLICY "walkthrough_templates_read"
    ON public.walkthrough_templates FOR SELECT
    TO authenticated
    USING (archived_at IS NULL);

GRANT SELECT ON public.walkthrough_templates TO authenticated;

-- ===========================================================================
-- Seed: 15 starter templates
-- ===========================================================================

-- Core systems (always considered if the matching home_systems row exists)

INSERT INTO public.walkthrough_templates (category, display_name, tier, icon, fields, applies_when, sort_order)
VALUES
('HVAC', 'Heating & cooling', 'core', 'wind',
 '[
    {"key": "manufacturer", "label": "Manufacturer", "type": "text", "required": false},
    {"key": "model_number",  "label": "Model number", "type": "text", "required": false},
    {"key": "serial_number", "label": "Serial number", "type": "text", "required": false},
    {"key": "install_year",  "label": "Install year",  "type": "date_year", "required": false, "source_hint": "ATTOM estimate / homeowner / handyman observed"},
    {"key": "condition",     "label": "Condition",     "type": "enum",  "required": true,
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "filter_size",   "label": "Filter size",   "type": "text", "required": false},
    {"key": "photos",        "label": "Photos",        "type": "photos", "max_count": 6, "required": false},
    {"key": "notes",         "label": "Notes",         "type": "long_text", "required": false}
 ]'::JSONB,
 '{"requires_home_system_category": "HVAC"}'::JSONB,
 10),

('Water Heater', 'Water heater', 'core', 'drop.fill',
 '[
    {"key": "manufacturer",    "label": "Manufacturer", "type": "text"},
    {"key": "model_number",    "label": "Model number", "type": "text"},
    {"key": "serial_number",   "label": "Serial number", "type": "text"},
    {"key": "install_year",    "label": "Install year",  "type": "date_year"},
    {"key": "tank_size_gal",   "label": "Tank size (gallons)", "type": "number"},
    {"key": "fuel_type",       "label": "Fuel type",     "type": "enum",
     "options": ["electric", "natural_gas", "propane", "oil", "tankless_gas", "tankless_electric", "heat_pump"]},
    {"key": "anode_last_replaced", "label": "Anode rod last replaced", "type": "date_year"},
    {"key": "condition",       "label": "Condition",     "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "photos",          "label": "Photos",        "type": "photos", "max_count": 4},
    {"key": "notes",           "label": "Notes",         "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Water Heater"}'::JSONB,
 20),

('Electrical', 'Electrical panel', 'core', 'bolt.fill',
 '[
    {"key": "panel_brand",      "label": "Panel brand",  "type": "text"},
    {"key": "panel_amperage",   "label": "Service amperage", "type": "number"},
    {"key": "install_year",     "label": "Install year",  "type": "date_year"},
    {"key": "has_surge_protection", "label": "Whole-home surge protection", "type": "enum", "options": ["yes", "no", "unsure"]},
    {"key": "condition",        "label": "Condition",     "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "photos",           "label": "Photos",        "type": "photos", "max_count": 6},
    {"key": "notes",            "label": "Notes",         "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Electrical"}'::JSONB,
 30),

('Plumbing', 'Plumbing', 'core', 'wrench.adjustable.fill',
 '[
    {"key": "main_shutoff_location", "label": "Main shutoff location", "type": "text"},
    {"key": "supply_pipe_material",  "label": "Supply pipe material", "type": "enum",
     "options": ["copper", "pex", "galvanized", "polybutylene", "mixed", "unsure"]},
    {"key": "drain_pipe_material",   "label": "Drain pipe material", "type": "enum",
     "options": ["pvc", "abs", "cast_iron", "galvanized", "mixed", "unsure"]},
    {"key": "condition",             "label": "Condition", "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "photos",                "label": "Photos",    "type": "photos", "max_count": 4},
    {"key": "notes",                 "label": "Notes",     "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Plumbing"}'::JSONB,
 40),

('Roofing', 'Roof', 'core', 'house.fill',
 '[
    {"key": "material",     "label": "Material",     "type": "enum",
     "options": ["asphalt_shingle", "metal", "slate", "tile", "wood_shake", "membrane", "other"], "source_hint": "ATTOM often pre-fills"},
    {"key": "install_year", "label": "Install year",  "type": "date_year"},
    {"key": "condition",    "label": "Condition",     "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "has_warranty", "label": "Active warranty", "type": "enum", "options": ["yes", "no", "unsure"]},
    {"key": "photos",       "label": "Photos (all four sides if possible)", "type": "photos", "max_count": 8},
    {"key": "notes",        "label": "Notes",         "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Roofing"}'::JSONB,
 50),

('Water Source', 'Water source', 'core', 'drop.degreesign',
 '[
    {"key": "source_type",      "label": "Source",      "type": "enum",
     "options": ["municipal", "well_private", "well_shared", "spring", "other"]},
    {"key": "treatment_systems", "label": "Treatment systems on site", "type": "text"},
    {"key": "last_water_test",   "label": "Last water test (year)", "type": "date_year"},
    {"key": "photos",            "label": "Photos",     "type": "photos", "max_count": 4},
    {"key": "notes",             "label": "Notes",      "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Water Source"}'::JSONB,
 60),

('Sewer', 'Sewer / septic', 'core', 'arrow.down.to.line',
 '[
    {"key": "system_type",       "label": "System",     "type": "enum",
     "options": ["municipal_sewer", "septic_conventional", "septic_aerobic", "cesspool", "other"]},
    {"key": "tank_size_gal",     "label": "Septic tank size (gallons)", "type": "number"},
    {"key": "last_pump_year",    "label": "Last pump (year)", "type": "date_year"},
    {"key": "leach_field_condition", "label": "Leach field condition", "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent", "n/a"]},
    {"key": "photos",            "label": "Photos",     "type": "photos", "max_count": 4},
    {"key": "notes",             "label": "Notes",      "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Sewer"}'::JSONB,
 70),

-- Specialty systems (only included if intake confirmed)

('Solar', 'Solar', 'specialty', 'sun.max.fill',
 '[
    {"key": "panel_count",      "label": "Number of panels", "type": "number"},
    {"key": "system_size_kw",   "label": "System size (kW)", "type": "number"},
    {"key": "inverter_brand",   "label": "Inverter brand",   "type": "text"},
    {"key": "install_year",     "label": "Install year",     "type": "date_year"},
    {"key": "ownership",        "label": "Ownership",        "type": "enum",
     "options": ["owned_outright", "loan", "lease", "ppa", "unsure"]},
    {"key": "battery_storage",  "label": "Battery storage",  "type": "enum", "options": ["yes", "no"]},
    {"key": "monitoring_url",   "label": "Monitoring URL",   "type": "text"},
    {"key": "photos",           "label": "Photos",           "type": "photos", "max_count": 6},
    {"key": "notes",            "label": "Notes",            "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Solar"}'::JSONB,
 80),

('Generator', 'Generator', 'specialty', 'bolt.batteryblock.fill',
 '[
    {"key": "manufacturer",     "label": "Manufacturer", "type": "text"},
    {"key": "model_number",     "label": "Model number", "type": "text"},
    {"key": "size_kw",          "label": "Size (kW)",    "type": "number"},
    {"key": "fuel_type",        "label": "Fuel type",    "type": "enum",
     "options": ["natural_gas", "propane", "diesel", "gasoline"]},
    {"key": "install_year",     "label": "Install year",  "type": "date_year"},
    {"key": "transfer_switch",  "label": "Transfer switch type", "type": "enum",
     "options": ["automatic", "manual", "unsure"]},
    {"key": "last_serviced",    "label": "Last service (year)", "type": "date_year"},
    {"key": "condition",        "label": "Condition",     "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "photos",           "label": "Photos",        "type": "photos", "max_count": 4},
    {"key": "notes",            "label": "Notes",         "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Generator"}'::JSONB,
 90),

('Pool/Spa', 'Pool / spa', 'specialty', 'figure.pool.swim',
 '[
    {"key": "type",             "label": "Type",        "type": "enum",
     "options": ["in_ground", "above_ground", "hot_tub_only", "in_ground_with_spa"]},
    {"key": "chemistry",        "label": "Chemistry",   "type": "enum",
     "options": ["chlorine", "salt", "bromine", "mineral", "other"]},
    {"key": "pump_brand_model", "label": "Pump brand / model", "type": "text"},
    {"key": "filter_brand_model", "label": "Filter brand / model", "type": "text"},
    {"key": "heater_brand_model", "label": "Heater brand / model", "type": "text"},
    {"key": "cover_type",       "label": "Cover type",   "type": "enum",
     "options": ["automatic", "safety", "winter", "none"]},
    {"key": "install_year",     "label": "Install year",  "type": "date_year"},
    {"key": "condition",        "label": "Condition",     "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "photos",           "label": "Photos",        "type": "photos", "max_count": 6},
    {"key": "notes",            "label": "Notes",         "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Pool/Spa"}'::JSONB,
 100),

('Hot Tub', 'Hot tub', 'specialty', 'figure.pool.swim',
 '[
    {"key": "manufacturer",     "label": "Manufacturer", "type": "text"},
    {"key": "model_number",     "label": "Model number", "type": "text"},
    {"key": "install_year",     "label": "Install year",  "type": "date_year"},
    {"key": "condition",        "label": "Condition",     "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "photos",           "label": "Photos",        "type": "photos", "max_count": 4},
    {"key": "notes",            "label": "Notes",         "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Hot Tub"}'::JSONB,
 110),

('Irrigation', 'Irrigation', 'specialty', 'drop.triangle',
 '[
    {"key": "controller_brand", "label": "Controller brand", "type": "text"},
    {"key": "zone_count",       "label": "Number of zones",  "type": "number"},
    {"key": "smart_controller", "label": "Smart / weather-based", "type": "enum", "options": ["yes", "no"]},
    {"key": "rain_sensor",      "label": "Rain sensor installed", "type": "enum", "options": ["yes", "no", "unsure"]},
    {"key": "backflow_year",    "label": "Backflow tested (year)", "type": "date_year"},
    {"key": "photos",           "label": "Photos",        "type": "photos", "max_count": 4},
    {"key": "notes",            "label": "Notes",         "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Irrigation"}'::JSONB,
 120),

('Security', 'Security system', 'specialty', 'shield.lefthalf.filled',
 '[
    {"key": "monitoring_company", "label": "Monitoring company", "type": "text"},
    {"key": "panel_brand",       "label": "Panel brand",  "type": "text"},
    {"key": "has_cameras",       "label": "Cameras installed", "type": "enum", "options": ["yes", "no"]},
    {"key": "has_smart_locks",   "label": "Smart locks",  "type": "enum", "options": ["yes", "no"]},
    {"key": "photos",            "label": "Photos",       "type": "photos", "max_count": 4},
    {"key": "notes",             "label": "Notes",        "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "Security System"}'::JSONB,
 130),

('EV Charger', 'EV charger', 'specialty', 'bolt.car.fill',
 '[
    {"key": "manufacturer",     "label": "Manufacturer", "type": "text"},
    {"key": "model_number",     "label": "Model",       "type": "text"},
    {"key": "amperage",         "label": "Amperage",    "type": "number"},
    {"key": "install_year",     "label": "Install year", "type": "date_year"},
    {"key": "condition",        "label": "Condition",    "type": "enum",
     "options": ["good", "fair", "needs_attention", "urgent"]},
    {"key": "photos",           "label": "Photos",       "type": "photos", "max_count": 3},
    {"key": "notes",            "label": "Notes",        "type": "long_text"}
 ]'::JSONB,
 '{"requires_home_system_category": "EV Charger"}'::JSONB,
 140),

-- Catch-all section ALWAYS included as the last walk-through step
('Outstanding', 'Anything else', 'core', 'doc.text.fill',
 '[
    {"key": "notes", "label": "Anything we missed?", "type": "long_text", "required": false},
    {"key": "photos", "label": "Photos", "type": "photos", "max_count": 8, "required": false}
 ]'::JSONB,
 NULL,
 9999);

COMMENT ON TABLE public.walkthrough_templates IS
    'Phase 85: per-category capture form templates that drive the dynamic walk-through view (iOS self-serve + operations SPA handyman mode). Composer reads applies_when to decide which templates to render based on the homeowner''s intake answers.';
