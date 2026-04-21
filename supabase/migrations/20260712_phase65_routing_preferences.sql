-- Phase 65: Sticky routing preferences per (household, property, category).
--
-- Layered on top of Q36's global `vendor_preference_tier` (diy/mixed/hireOut).
-- Tier provides the baseline default; per-category rows are overrides. First
-- pick per category creates a `scope_type = 'category'` row AND fires a
-- toast ("we'll remember this"). Subsequent picks that deviate create
-- `scope_type = 'template'` overrides for the specific template without
-- touching the category-level preference.
--
-- Task creation (reconciler + custom flow) reads preferences in this order:
--   1. template-level override (most specific)
--   2. category-level preference
--   3. active service contract auto-route
--   4. Q36 tier + handyman preference default

CREATE TABLE IF NOT EXISTS routing_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) ON DELETE CASCADE NOT NULL,
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE NOT NULL,
    task_category TEXT NOT NULL,

    scope_type TEXT NOT NULL DEFAULT 'category'
        CHECK (scope_type IN ('category', 'template')),

    preferred_route TEXT NOT NULL
        CHECK (preferred_route IN ('vendor', 'handyman', 'diy')),

    preferred_vendor_id UUID REFERENCES contractors(id) ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_confirmed_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (household_id, property_id, task_category, scope_type)
);

CREATE INDEX IF NOT EXISTS idx_routing_prefs_household_property
  ON routing_preferences (household_id, property_id);

ALTER TABLE routing_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their household routing preferences"
    ON routing_preferences FOR ALL
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- updated_at trigger. Reuses the existing `set_updated_at` function when
-- present; creates a local copy otherwise so this migration is self-contained.
CREATE OR REPLACE FUNCTION routing_preferences_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS routing_preferences_updated_at ON routing_preferences;
CREATE TRIGGER routing_preferences_updated_at
    BEFORE UPDATE ON routing_preferences
    FOR EACH ROW
    EXECUTE FUNCTION routing_preferences_set_updated_at();
