-- Enhance inbox_items to support user actions and raw attachment storage.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='needs_action') THEN
    ALTER TABLE inbox_items ADD COLUMN needs_action BOOLEAN DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='action_type') THEN
    ALTER TABLE inbox_items ADD COLUMN action_type TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='action_completed') THEN
    ALTER TABLE inbox_items ADD COLUMN action_completed BOOLEAN DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='attachment_path') THEN
    ALTER TABLE inbox_items ADD COLUMN attachment_path TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='attachment_content_type') THEN
    ALTER TABLE inbox_items ADD COLUMN attachment_content_type TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='attachment_filename') THEN
    ALTER TABLE inbox_items ADD COLUMN attachment_filename TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='metadata') THEN
    ALTER TABLE inbox_items ADD COLUMN metadata JSONB DEFAULT '{}';
  END IF;
END $$;

-- Storage bucket for inbox attachments
INSERT INTO storage.buckets (id, name, public) VALUES ('inbox-attachments', 'inbox-attachments', false) ON CONFLICT DO NOTHING;

-- Index for items needing action
CREATE INDEX IF NOT EXISTS idx_inbox_items_needs_action ON inbox_items(household_id, needs_action) WHERE needs_action = true AND action_completed = false;
