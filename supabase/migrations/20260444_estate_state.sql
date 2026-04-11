-- Phase 48: Estate Intelligence
-- One row per household storing estate planning state, fiduciaries,
-- concerns, wishes, assets summary, intake progress, and computed fields.

CREATE TABLE IF NOT EXISTS estate_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL UNIQUE REFERENCES households(id) ON DELETE CASCADE,

  -- Presence flags (typed columns for fast queries)
  has_will BOOLEAN NOT NULL DEFAULT FALSE,
  has_revocable_trust BOOLEAN NOT NULL DEFAULT FALSE,
  has_irrevocable_trust BOOLEAN NOT NULL DEFAULT FALSE,
  has_poa BOOLEAN NOT NULL DEFAULT FALSE,
  has_health_proxy BOOLEAN NOT NULL DEFAULT FALSE,
  has_living_will BOOLEAN NOT NULL DEFAULT FALSE,
  has_hipaa_auth BOOLEAN NOT NULL DEFAULT FALSE,
  has_prenup BOOLEAN NOT NULL DEFAULT FALSE,
  has_business_agreement BOOLEAN NOT NULL DEFAULT FALSE,
  has_disposition_of_remains BOOLEAN NOT NULL DEFAULT FALSE,

  -- Execution dates per doc type (for staleness computation)
  will_date DATE,
  trust_date DATE,
  poa_date DATE,
  health_proxy_date DATE,

  -- Estate attorney (derived from most recent/frequent across estate docs)
  estate_attorney_contact_id UUID REFERENCES trusted_contacts(id) ON DELETE SET NULL,
  last_estate_review_date DATE,

  -- JSONB fields for nested/variable data
  fiduciaries JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Array of: {name, role, is_alternate, source, trusted_contact_id?, family_member_id?}
  -- Roles: executor, trustee, guardian, health_proxy, poa_agent, disposition_agent, successor_trustee

  concerns JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Array of: {concern_id, rating: "high"|"some"|"low"|"na", rated_at}

  wishes JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Array of: {wish_id, value, noted_at}

  assets_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- {real_estate_count, vehicle_count, business_count, financial_accounts_count,
  --  life_insurance_count, net_worth_bucket}

  intake_state JSONB,
  -- Mirrors house_quiz_state pattern: {started_at, completed_at, current_section,
  --   answers: {section_id: {value, selected_ids?, answered_at}}, skipped: []}

  -- Fiduciary nominations (separate from extracted fiduciaries)
  nominations JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- {executor: {primary: {name, contact_id?}, alternate: {name, contact_id?}},
  --  trustee: {...}, guardian: {...}, health_proxy: {...}, poa_agent: {...}, disposition_agent: {...}}

  -- Computed fields (written on recompute)
  estate_readiness_score INTEGER NOT NULL DEFAULT 0,
  staleness_tier TEXT NOT NULL DEFAULT 'none', -- none|info|amber|critical
  staleness_reasons JSONB NOT NULL DEFAULT '[]'::jsonb,
  household_snapshot JSONB, -- composition at last recompute (member count, property count, vehicle count)

  -- Timestamps
  last_recomputed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_estate_state_household ON estate_state(household_id);

-- updated_at trigger (follows existing project pattern)
CREATE OR REPLACE FUNCTION update_estate_state_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER estate_state_updated_at
    BEFORE UPDATE ON estate_state
    FOR EACH ROW EXECUTE FUNCTION update_estate_state_updated_at();

-- RLS
ALTER TABLE estate_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own household estate state"
  ON estate_state FOR SELECT
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert own household estate state"
  ON estate_state FOR INSERT
  WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update own household estate state"
  ON estate_state FOR UPDATE
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete own household estate state"
  ON estate_state FOR DELETE
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Service role full access to estate state"
  ON estate_state FOR ALL
  USING (auth.role() = 'service_role');
