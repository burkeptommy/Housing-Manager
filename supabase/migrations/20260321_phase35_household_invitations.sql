-- Household invitations for multi-user sharing
CREATE TABLE household_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) ON DELETE CASCADE NOT NULL,
    invited_by UUID REFERENCES users(id) NOT NULL,
    invited_email TEXT NOT NULL,
    invite_code TEXT NOT NULL UNIQUE, -- 6-character alphanumeric code
    role TEXT NOT NULL DEFAULT 'member', -- 'member', 'admin'
    family_member_id UUID REFERENCES family_members(id), -- links to existing family member record
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'expired', 'revoked'
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days'),
    accepted_at TIMESTAMPTZ,
    accepted_by UUID REFERENCES users(id)
);

ALTER TABLE household_invitations ENABLE ROW LEVEL SECURITY;

-- Users can view invitations for their household
CREATE POLICY "Users can view household invitations"
ON household_invitations FOR SELECT
USING (household_id = public.get_my_household_id());

-- Users can create invitations for their household
CREATE POLICY "Users can create household invitations"
ON household_invitations FOR INSERT
WITH CHECK (household_id = public.get_my_household_id());

-- Users can update invitations for their household (revoke)
CREATE POLICY "Users can update household invitations"
ON household_invitations FOR UPDATE
USING (household_id = public.get_my_household_id());

-- New users can view invitations by email (for onboarding lookup)
CREATE POLICY "Anyone can look up invitations by email"
ON household_invitations FOR SELECT
USING (invited_email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Add linked_user_id to family_members to track which family members have app logins
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS linked_user_id UUID REFERENCES users(id);

CREATE INDEX idx_invitations_email ON household_invitations(invited_email, status);
CREATE INDEX idx_invitations_code ON household_invitations(invite_code);
CREATE INDEX idx_invitations_household ON household_invitations(household_id);
