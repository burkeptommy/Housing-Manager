-- Fix "permission denied for table users" during onboarding invitation lookup.
--
-- When a new user signs in via Apple, their public.users row doesn't exist yet.
-- PostgREST's request context resolution touches the users table before the
-- actual household_invitations query runs, causing a 42501 error. This
-- SECURITY DEFINER function bypasses the issue entirely.

CREATE OR REPLACE FUNCTION public.check_pending_invitation_by_email(target_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    inv record;
BEGIN
    SELECT *
    INTO inv
    FROM public.household_invitations
    WHERE invited_email = lower(trim(target_email))
      AND status = 'pending'
      AND (expires_at IS NULL OR expires_at > now())
    ORDER BY created_at DESC
    LIMIT 1;

    IF inv IS NULL THEN
        RETURN '{"found": false}'::jsonb;
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'id', inv.id,
        'household_id', inv.household_id,
        'invited_by', inv.invited_by,
        'invited_email', inv.invited_email,
        'invite_code', inv.invite_code,
        'role', inv.role,
        'family_member_id', inv.family_member_id,
        'status', inv.status,
        'created_at', inv.created_at,
        'expires_at', inv.expires_at,
        'accepted_at', inv.accepted_at,
        'accepted_by', inv.accepted_by,
        'personal_message', inv.personal_message,
        'reminder_sent_at', inv.reminder_sent_at,
        'reminder_count', inv.reminder_count
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_pending_invitation_by_email(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_pending_invitation_by_email(text) TO anon;
