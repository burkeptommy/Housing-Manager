-- Phase 75: home system photos
--
-- Lets handymen capture / annotate photos of a home_system from the
-- web Operations Desk (and field PWA). Photo bytes live in a private
-- bucket; the home_systems row carries a small JSONB array of
-- { path, content_type, uploaded_by, uploaded_at, caption } so we
-- never have to fan-out a separate table for what is functionally a
-- per-row attachment list.

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'home_systems'
      AND column_name = 'photos'
  ) THEN
    ALTER TABLE public.home_systems
      ADD COLUMN photos JSONB NOT NULL DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Private bucket (handyman-provider edge function will sign URLs on
-- the read path). Upload + delete is gated server-side by the same
-- workspace-access check as update_home_system, so no public RLS on
-- the bucket itself.
INSERT INTO storage.buckets (id, name, public)
VALUES ('home-system-photos', 'home-system-photos', false)
ON CONFLICT (id) DO NOTHING;
