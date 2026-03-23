-- Concierge messages (human support chat)
CREATE TABLE concierge_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    user_id UUID REFERENCES users(id) NOT NULL,
    role TEXT NOT NULL,  -- 'user' or 'concierge'
    content TEXT NOT NULL,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE concierge_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own household concierge messages"
    ON concierge_messages FOR SELECT
    USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can insert concierge messages"
    ON concierge_messages FOR INSERT
    WITH CHECK (user_id = auth.uid() AND household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

-- Task reminders for maintenance
CREATE TABLE task_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    maintenance_task_id UUID REFERENCES maintenance_tasks(id) ON DELETE CASCADE NOT NULL,
    household_id UUID REFERENCES households(id) NOT NULL,
    reminder_offset TEXT NOT NULL,  -- '1_day', '3_days', '1_week', '2_weeks', '1_month', 'custom'
    custom_date DATE,
    is_enabled BOOLEAN DEFAULT true,
    notification_scheduled BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE task_reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own household task reminders"
    ON task_reminders FOR ALL
    USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
