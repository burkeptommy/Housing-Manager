-- Add image_url and product_url to project_line_items for product photos.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='project_line_items' AND column_name='image_url') THEN
    ALTER TABLE project_line_items ADD COLUMN image_url TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='project_line_items' AND column_name='product_url') THEN
    ALTER TABLE project_line_items ADD COLUMN product_url TEXT;
  END IF;
END $$;
