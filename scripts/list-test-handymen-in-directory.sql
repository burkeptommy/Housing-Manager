-- Opts every existing provider_workspace into the homeowner-facing
-- directory so they appear in the iOS find-a-handyman flow.
--
-- Run this AFTER you've created test workspaces via the Chez Field app.
-- The Field-app UI for the directory toggle is not built yet, so this
-- SQL is the manual override until the toggle ships.
--
-- What it does:
--   1. is_listed_in_directory = true            (the opt-in gate)
--   2. categories includes 'handyman'           (the find-handymen filter)
--   3. service_state set to 'NY' if missing     (so state-level filter passes)
--
-- Edit the WHERE clause (or remove it) to scope which workspaces get
-- flipped. Right now it touches every workspace.
--
-- Run with:
--   supabase db query --linked --file scripts/list-test-handymen-in-directory.sql
-- or paste into Supabase Studio → SQL editor.

UPDATE public.provider_workspaces
SET
    is_listed_in_directory = true,
    categories = CASE
        WHEN array_length(categories, 1) IS NULL THEN ARRAY['handyman']
        WHEN NOT ('handyman' = ANY(categories)) THEN array_append(categories, 'handyman')
        ELSE categories
    END,
    service_state = COALESCE(service_state, 'NY'),
    updated_at = NOW()
WHERE id IS NOT NULL;  -- edit to limit which workspaces flip

-- Verify the result:
SELECT
    id,
    company_name,
    is_listed_in_directory,
    categories,
    service_state,
    service_city,
    aggregate_rating
FROM public.provider_workspaces
ORDER BY created_at DESC;
