-- 20270121_invitation_created_member.sql
--
-- July 2026 hardening plan, Phase 2 (audit F3): revoking a pending
-- invitation hard-deleted the linked family_members row — but invitations
-- created via inviteExistingMember point at a PRE-EXISTING member (your
-- spouse's whole profile: DOB, school, document links), so revoke was a
-- data-loss trap. The row now records whether the invite flow CREATED the
-- member placeholder; revoke only cleans up rows it created. Legacy
-- invitations default false → revoke never deletes for them (a pending
-- placeholder lingering in the family list is visible and removable; a
-- silently deleted spouse profile is not recoverable).
ALTER TABLE public.household_invitations
  ADD COLUMN IF NOT EXISTS created_member boolean NOT NULL DEFAULT false;
