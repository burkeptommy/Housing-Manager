-- Professional advisor directory: household-scoped advisor links
-- Parallel to utility_accounts but household-scoped (not property-scoped)
-- Advisors are either matched to a utility_providers catalog row or custom-entered

CREATE TABLE IF NOT EXISTS household_advisors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  advisor_type TEXT NOT NULL CHECK (advisor_type IN ('estate_attorney', 'cpa_tax', 'financial_advisor', 'life_insurance')),
  provider_name TEXT NOT NULL,
  provider_slug TEXT,
  provider_id UUID REFERENCES utility_providers(id) ON DELETE SET NULL,
  logo_url TEXT,
  brand_color TEXT,
  website TEXT,
  phone TEXT,
  email TEXT,
  contact_name TEXT,
  company_name TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_household_advisors_household ON household_advisors(household_id);
CREATE INDEX idx_household_advisors_type ON household_advisors(household_id, advisor_type);

-- RLS
ALTER TABLE household_advisors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their household advisors"
  ON household_advisors FOR SELECT
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can insert household advisors"
  ON household_advisors FOR INSERT
  WITH CHECK (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can update their household advisors"
  ON household_advisors FOR UPDATE
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can delete their household advisors"
  ON household_advisors FOR DELETE
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
