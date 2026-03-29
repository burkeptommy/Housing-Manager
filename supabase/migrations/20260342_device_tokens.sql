-- Device tokens for push notifications (APNs)
CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'ios',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, token)
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage their own device tokens
CREATE POLICY "Users can view own device tokens"
    ON device_tokens FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own device tokens"
    ON device_tokens FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own device tokens"
    ON device_tokens FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete own device tokens"
    ON device_tokens FOR DELETE
    USING (user_id = auth.uid());

-- Service role can read all tokens (for sending push from edge functions)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.device_tokens TO authenticated;
