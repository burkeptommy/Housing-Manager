-- Analytics Events table
-- Tracks all user interactions for product analytics.
-- Additive migration — no existing tables modified.

CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    household_id UUID,
    event_name TEXT NOT NULL,
    screen_name TEXT,
    properties JSONB DEFAULT '{}',
    device_model TEXT,
    os_version TEXT,
    app_version TEXT,
    build_number TEXT,
    session_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for common queries
CREATE INDEX idx_analytics_events_user ON analytics_events(user_id, created_at DESC);
CREATE INDEX idx_analytics_events_household ON analytics_events(household_id, created_at DESC);
CREATE INDEX idx_analytics_events_name ON analytics_events(event_name, created_at DESC);
CREATE INDEX idx_analytics_events_screen ON analytics_events(screen_name, created_at DESC);
CREATE INDEX idx_analytics_events_session ON analytics_events(session_id);
CREATE INDEX idx_analytics_events_created ON analytics_events(created_at DESC);

-- RLS
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Users can insert their own events (the app writes analytics)
CREATE POLICY "Users can insert own analytics events"
    ON analytics_events FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Only admins/service role can read analytics (not regular users)
-- You'll query this from the Supabase dashboard SQL editor with service role
CREATE POLICY "Service role can read all analytics"
    ON analytics_events FOR SELECT
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Grant insert to authenticated users
GRANT INSERT ON analytics_events TO authenticated;
-- Grant full access to service_role for dashboard queries
GRANT ALL ON analytics_events TO service_role;
