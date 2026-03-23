-- Phase 18b: Scenario History table for "What If?" Scenario Studio

CREATE TABLE scenario_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    user_id UUID,
    scenario_id TEXT,
    custom_query TEXT,
    result_json JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE scenario_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own scenarios" ON scenario_history
    FOR SELECT USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can insert own scenarios" ON scenario_history
    FOR INSERT WITH CHECK (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE INDEX idx_scenario_history_household ON scenario_history(household_id);
CREATE INDEX idx_scenario_history_created ON scenario_history(created_at DESC);
