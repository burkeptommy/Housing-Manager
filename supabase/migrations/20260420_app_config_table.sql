-- Phase 13 (Onboarding Revamp Phase 2): remote app configuration table.
-- The iOS client reads this on every launch and compares the running build's
-- marketing version + build number to the minimum_required and latest fields.
--
-- One row per platform (today only `ios`). Tom updates the row by hand from
-- the Supabase SQL editor whenever he ships a new TestFlight build:
--
--   UPDATE app_config
--      SET minimum_required_version = '1.0.4',
--          minimum_required_build   = 80,
--          latest_version           = '1.0.4',
--          latest_build             = 80,
--          updated_at               = now()
--    WHERE id = 'ios';
--
-- Comparison logic on the client:
--   force_update if  current_marketing < minimum_marketing
--                OR  current_marketing == minimum_marketing AND current_build < minimum_build
--   else optional_update if  current_marketing < latest_marketing
--                       OR  current_marketing == latest_marketing AND current_build < latest_build
--   else up_to_date

CREATE TABLE IF NOT EXISTS public.app_config (
    id TEXT PRIMARY KEY DEFAULT 'ios',
    minimum_required_version TEXT NOT NULL,
    minimum_required_build INTEGER NOT NULL,
    latest_version TEXT NOT NULL,
    latest_build INTEGER NOT NULL,
    force_update_message TEXT,
    optional_update_message TEXT,
    app_store_url TEXT NOT NULL DEFAULT 'https://apps.apple.com/app/id6757167606',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Public read, no write. Writes happen via the Supabase dashboard / SQL editor.
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_config is publicly readable" ON public.app_config;
CREATE POLICY "app_config is publicly readable"
    ON public.app_config
    FOR SELECT
    USING (true);

-- Seed the initial row using the marketing version + build number this very
-- migration ships with. project.yml currently sets MARKETING_VERSION="1.0.2"
-- and CURRENT_PROJECT_VERSION="74", so the running build is exactly at the
-- minimum. No one is force-updated by this migration; future bumps must be
-- applied manually after a new TestFlight upload exists.
INSERT INTO public.app_config (
    id,
    minimum_required_version, minimum_required_build,
    latest_version, latest_build,
    force_update_message, optional_update_message
) VALUES (
    'ios',
    '1.0.2', 74,
    '1.0.2', 74,
    'We made important updates to keep your household data safe and your experience smooth. Please update Haven to continue.',
    'A new version of Haven is available. Update anytime to get the latest features.'
) ON CONFLICT (id) DO NOTHING;

COMMENT ON TABLE public.app_config IS
    'Remote app version gate. Read by the iOS client on every launch via fetchAppConfig().';
