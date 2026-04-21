-- Phase 56 / Build 94: homeowner-initiated "Remove access" action.
--
-- Problem: the base RLS policy on `public.users` is
-- `FOR UPDATE USING (id = auth.uid())`, which means a client-side
-- `UPDATE users SET household_id = NULL WHERE id = <other_user_id>`
-- silently affects 0 rows. No error, no write — just a no-op that
-- leaves the invited user still attached to the household.
--
-- Fix: expose a SECURITY DEFINER RPC the authenticated client can
-- call. The function verifies the caller and the target are in the
-- same household, then performs both writes atomically:
--   1. `family_members.linked_user_id = NULL` for any row pointing
--      at the target — keeps the member card in the household so
--      the homeowner can re-invite from the same profile later.
--   2. `users.household_id = NULL` for the target — revokes their
--      household-scoped RLS access immediately.
--
-- Self-removal is blocked here on purpose. Account deletion runs
-- through the existing `delete-account` Edge Function which handles
-- chat cleanup, sole-member household teardown, and auth.users
-- deletion — this RPC is for a homeowner ejecting a co-member, not
-- self-destruct.

CREATE OR REPLACE FUNCTION public.remove_household_access(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    caller_id uuid;
    caller_household_id uuid;
    target_household_id uuid;
BEGIN
    caller_id := auth.uid();
    IF caller_id IS NULL THEN
        RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
    END IF;

    IF target_user_id = caller_id THEN
        RAISE EXCEPTION 'cannot remove yourself — use account deletion instead'
            USING ERRCODE = '22023';
    END IF;

    SELECT household_id INTO caller_household_id
    FROM public.users
    WHERE id = caller_id;

    IF caller_household_id IS NULL THEN
        RAISE EXCEPTION 'caller is not in any household' USING ERRCODE = '42501';
    END IF;

    SELECT household_id INTO target_household_id
    FROM public.users
    WHERE id = target_user_id;

    IF target_household_id IS NULL OR target_household_id <> caller_household_id THEN
        RAISE EXCEPTION 'target user is not in your household' USING ERRCODE = '42501';
    END IF;

    UPDATE public.family_members
    SET linked_user_id = NULL
    WHERE linked_user_id = target_user_id
      AND household_id = caller_household_id;

    UPDATE public.users
    SET household_id = NULL
    WHERE id = target_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.remove_household_access(uuid) TO authenticated;
