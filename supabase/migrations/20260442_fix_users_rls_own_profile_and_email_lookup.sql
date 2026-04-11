-- Fix invite flow "permission denied for table users" bug.
--
-- Two issues addressed:
--
-- 1. The "Users can view own profile" policy (id = auth.uid()) was defined in
--    schema.sql but never guaranteed by a migration. If the policy was
--    accidentally dropped or never created on the live DB, fetchCurrentUser()
--    fails when get_my_household_id() returns NULL (no household yet) because
--    NULL = NULL is FALSE in SQL. This migration ensures the policy exists.
--
-- 2. DatabaseService.checkExistingUser(email:) queries `from("users")` with an
--    email filter. Under current RLS the caller can only see users in their OWN
--    household, so looking up a user in a different household (or with no
--    household) always returns zero rows -- or throws "permission denied" if
--    table-level grants are tight. The fix: a SECURITY DEFINER function that
--    checks auth.users by email without exposing the full row.

-- ============================================================================
-- 1. Ensure "Users can view own profile" SELECT policy exists
-- ============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE policyname = 'Users can view own profile'
          AND tablename = 'users'
          AND schemaname = 'public'
    ) THEN
        CREATE POLICY "Users can view own profile"
            ON public.users FOR SELECT
            USING (id = auth.uid());
    END IF;
END $$;

-- ============================================================================
-- 2. SECURITY DEFINER function: check_user_exists_by_email
--    Returns { "exists": true, "user_id": "...", "household_id": "..." }
--    or     { "exists": false }
--    Queries auth.users so it works even when the target user has no row in
--    public.users yet (Apple Sign In creates the auth user before the public
--    row). Falls back to public.users if auth.users has no email match
--    (belt-and-suspenders for edge cases).
-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_user_exists_by_email(target_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    result jsonb;
    found_id uuid;
    found_household_id uuid;
BEGIN
    -- Try auth.users first (canonical email source)
    SELECT au.id INTO found_id
    FROM auth.users au
    WHERE au.email = lower(trim(target_email))
    LIMIT 1;

    IF found_id IS NOT NULL THEN
        -- Look up household_id from public.users
        SELECT u.household_id INTO found_household_id
        FROM public.users u
        WHERE u.id = found_id;

        RETURN jsonb_build_object(
            'exists', true,
            'user_id', found_id,
            'household_id', found_household_id
        );
    END IF;

    -- Fallback: check public.users directly
    SELECT u.id, u.household_id INTO found_id, found_household_id
    FROM public.users u
    WHERE u.email = lower(trim(target_email))
    LIMIT 1;

    IF found_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'exists', true,
            'user_id', found_id,
            'household_id', found_household_id
        );
    END IF;

    RETURN jsonb_build_object('exists', false);
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_user_exists_by_email(text) TO authenticated;
