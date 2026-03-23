-- Fix infinite recursion in users RLS policy.
-- The "Users can view household members" policy on the users table was doing
-- SELECT household_id FROM users, which triggers the same RLS policies again.
-- Solution: SECURITY DEFINER function that bypasses RLS for the lookup.

CREATE OR REPLACE FUNCTION public.get_my_household_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT household_id FROM public.users WHERE id = auth.uid()
$$;

DROP POLICY IF EXISTS "Users can view household members" ON users;
CREATE POLICY "Users can view household members"
    ON users FOR SELECT
    USING (household_id = public.get_my_household_id());
