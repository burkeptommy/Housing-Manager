-- Add design_group to project_line_items to distinguish design picks from construction items.
-- Values: 'design' (finishes, fixtures, paint, etc.) or 'construction' (lumber, tools, etc.)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='project_line_items' AND column_name='design_group') THEN
    ALTER TABLE project_line_items ADD COLUMN design_group TEXT;
  END IF;
END $$;
