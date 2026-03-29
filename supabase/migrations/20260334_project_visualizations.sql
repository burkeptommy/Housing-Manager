-- Project visualizations: stores Decor8 AI room renders per project.
-- Users can visualize their room with chosen styles, paint colors, and finishes.
CREATE TABLE IF NOT EXISTS project_visualizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES property_projects(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id),
    visualization_type TEXT NOT NULL, -- room_design, wall_color, inspiration, kitchen, bathroom, landscaping
    input_image_path TEXT,            -- User's original room photo in storage
    output_image_url TEXT NOT NULL,   -- Decor8 CDN URL of rendered image
    stored_path TEXT,                 -- Copy in Supabase storage
    design_style TEXT,
    color_hex TEXT,                   -- For wall_color type
    user_prompt TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE project_visualizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view household visualizations"
    ON project_visualizations FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Members can create household visualizations"
    ON project_visualizations FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Members can delete household visualizations"
    ON project_visualizations FOR DELETE
    USING (household_id = public.get_my_household_id());

CREATE INDEX idx_project_visualizations_project ON project_visualizations(project_id, created_at DESC);

-- Monthly visualization usage tracking on users table
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='viz_generations_used') THEN
        ALTER TABLE users ADD COLUMN viz_generations_used INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='viz_generations_reset_at') THEN
        ALTER TABLE users ADD COLUMN viz_generations_reset_at TIMESTAMPTZ DEFAULT now();
    END IF;
END $$;

-- Storage bucket for room visualization images
INSERT INTO storage.buckets (id, name, public) VALUES ('room-visualizations', 'room-visualizations', false) ON CONFLICT DO NOTHING;
