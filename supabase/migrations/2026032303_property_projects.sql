-- Phase 38: Property Project Planning
-- Additive migration — no existing tables modified.

-- ============================================================================
-- Project planning table
-- ============================================================================
CREATE TABLE IF NOT EXISTS property_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,

    -- Core fields
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'planning',
    project_type TEXT NOT NULL DEFAULT 'diy',
    priority TEXT DEFAULT 'medium',

    -- Budget
    estimated_budget DECIMAL(12,2),
    actual_spend DECIMAL(12,2) DEFAULT 0,
    ai_estimated_diy_cost DECIMAL(12,2),
    ai_estimated_pro_cost DECIMAL(12,2),

    -- Dates
    target_start_date DATE,
    target_end_date DATE,
    actual_start_date DATE,
    actual_end_date DATE,

    -- AI research results
    ai_research JSONB,
    ai_research_updated_at TIMESTAMPTZ,

    -- Notes
    notes TEXT,

    -- Meta
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

-- ============================================================================
-- Line items for project budgets
-- ============================================================================
CREATE TABLE IF NOT EXISTS project_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES property_projects(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    category TEXT,
    quantity DECIMAL(10,2) DEFAULT 1,
    unit TEXT,
    estimated_unit_price DECIMAL(10,2),
    actual_unit_price DECIMAL(10,2),

    suggested_store TEXT,
    suggested_url TEXT,
    is_purchased BOOLEAN DEFAULT false,
    is_ai_suggested BOOLEAN DEFAULT false,

    notes TEXT,
    sort_order INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- Indexes
-- ============================================================================
CREATE INDEX idx_property_projects_household ON property_projects(household_id);
CREATE INDEX idx_property_projects_property ON property_projects(property_id);
CREATE INDEX idx_property_projects_status ON property_projects(status);
CREATE INDEX idx_project_line_items_project ON project_line_items(project_id);
CREATE INDEX idx_project_line_items_household ON project_line_items(household_id);

-- ============================================================================
-- RLS (uses get_my_household_id() — same pattern as all other Haven tables)
-- ============================================================================
ALTER TABLE property_projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view projects in their household"
    ON property_projects FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert projects in their household"
    ON property_projects FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update projects in their household"
    ON property_projects FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete projects in their household"
    ON property_projects FOR DELETE
    USING (household_id = public.get_my_household_id());

ALTER TABLE project_line_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view line items in their household"
    ON project_line_items FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert line items in their household"
    ON project_line_items FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update line items in their household"
    ON project_line_items FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete line items in their household"
    ON project_line_items FOR DELETE
    USING (household_id = public.get_my_household_id());
