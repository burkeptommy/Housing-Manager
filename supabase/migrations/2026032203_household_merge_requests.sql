-- Household merge requests for combining two households
CREATE TABLE IF NOT EXISTS household_merge_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_household_id UUID REFERENCES households(id) NOT NULL,
    target_household_id UUID REFERENCES households(id) NOT NULL,
    requested_by UUID REFERENCES users(id) NOT NULL,
    requested_for_email TEXT,
    target_user_id UUID REFERENCES users(id),
    source_household_name TEXT,
    target_household_name TEXT,
    requester_name TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'declined'
    preview_data JSONB,          -- cached diff preview from preview_merge action
    resolution_choices JSONB,    -- user's per-item merge decisions
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE household_merge_requests ENABLE ROW LEVEL SECURITY;

-- Users can view merge requests they're involved in
CREATE POLICY "Users can view their merge requests"
ON household_merge_requests FOR SELECT
USING (
    target_user_id = auth.uid()
    OR requested_by = auth.uid()
    OR requested_for_email = (SELECT email FROM auth.users WHERE id = auth.uid())
);

-- Users can update merge requests targeted at them (accept/decline)
CREATE POLICY "Users can update their merge requests"
ON household_merge_requests FOR UPDATE
USING (
    target_user_id = auth.uid()
    OR requested_for_email = (SELECT email FROM auth.users WHERE id = auth.uid())
);

CREATE INDEX idx_merge_requests_target_user ON household_merge_requests(target_user_id, status);
CREATE INDEX idx_merge_requests_email ON household_merge_requests(requested_for_email, status);

-- Add deactivated_at to households for soft-delete after merge
ALTER TABLE households ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMPTZ;

-- Add user assignment to maintenance tasks for collaborative task management
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS assigned_to_user_id UUID REFERENCES users(id);

-- Service role insert policy for merge requests (edge function uses service role)
CREATE POLICY "Service role can insert merge requests"
ON household_merge_requests FOR INSERT
WITH CHECK (true);

-- Prevent duplicate home systems on the same property
CREATE UNIQUE INDEX IF NOT EXISTS idx_home_systems_property_name
ON home_systems (property_id, lower(name));
