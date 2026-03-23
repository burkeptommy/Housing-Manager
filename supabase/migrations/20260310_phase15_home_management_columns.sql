-- Phase 15: Home Management Deep Overhaul — New columns and tables

-- 7.1 — New fields on home_systems
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS preferred_contractor_id UUID REFERENCES contractors(id);
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS last_service_date DATE;
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS next_service_due DATE;
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS total_spent DECIMAL DEFAULT 0;

-- 7.2 — New fields on maintenance_tasks
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS is_template_based BOOLEAN DEFAULT false;
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS template_id TEXT;
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS seasonal_timing TEXT;
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS is_diy BOOLEAN DEFAULT false;
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS professional_required BOOLEAN DEFAULT false;
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS cost_range TEXT;
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS last_email_sent_at TIMESTAMPTZ;
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS recurrence_rule TEXT;

-- 7.3 — New table: Service Email Log
CREATE TABLE IF NOT EXISTS service_emails (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    maintenance_task_id UUID REFERENCES maintenance_tasks(id),
    contractor_id UUID REFERENCES contractors(id),
    property_id UUID REFERENCES properties(id),
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT now(),
    status TEXT DEFAULT 'sent'
);

ALTER TABLE service_emails ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their household service emails"
    ON service_emails FOR ALL
    USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

-- RLS for new home_systems columns is inherited from existing policies
-- RLS for new maintenance_tasks columns is inherited from existing policies
