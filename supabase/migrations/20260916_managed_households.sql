-- Phase 75g: managed households (provider-created clients).
--
-- A handyman business can use the operations desk to add a client
-- without waiting for the homeowner to install the Chez app. The
-- household row gets created with no auth user; we stamp two
-- columns so the homeowner can later claim it on signup:
--
--   - claim_email: the email the provider gave us — when a new
--     account signs up with this email, AppState's claim flow
--     transfers the household to the new auth user.
--   - managed_by_provider_workspace_id: the workspace operating
--     on the household's behalf. Used by the homes view to filter,
--     and to show a "Managed by X" badge to the eventual homeowner.

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'households'
      AND column_name = 'claim_email'
  ) THEN
    ALTER TABLE public.households ADD COLUMN claim_email TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'households'
      AND column_name = 'managed_by_provider_workspace_id'
  ) THEN
    ALTER TABLE public.households
      ADD COLUMN managed_by_provider_workspace_id UUID
      REFERENCES public.provider_workspaces(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_households_claim_email
  ON public.households (lower(claim_email))
  WHERE claim_email IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_households_managed_by_provider
  ON public.households (managed_by_provider_workspace_id)
  WHERE managed_by_provider_workspace_id IS NOT NULL;
