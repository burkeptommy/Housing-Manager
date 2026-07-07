-- 20270120_security_sweep_rls_hardening.sql
--
-- July 2026 security sweep (PRODUCT_AUDIT_2026-07.md) — RLS layer fixes.
-- Companion to the edge-function auth sweep (shared _shared/require-household.ts).
--
-- H1: log_chez_activity() was an open SECURITY DEFINER RPC — default EXECUTE
--     grants let any anon/authenticated caller forge "Chez did this" rows
--     (including cost_cents feeding spend rollups) into ANY household.
-- H2: the homeowner UPDATE policy on chez_requests was column-unrestricted —
--     clients could self-resolve (skipping the outcome form), tamper SLA
--     stamps/due dates, and edit analysis_cache. All homeowner writes go
--     through the chez-concierge edge function (verified: iOS has zero
--     direct PostgREST writes to this table), so the policy is dropped
--     outright rather than column-restricted.
-- H4: concierge_messages INSERT let homeowners forge role='concierge' /
--     role='system' rows (rendering as Chez in iOS) and proposal JSONB with
--     fabricated approvals — poisoning SLA + funnel metrics.
-- M1: chez_reminders (operator follow-up intent: "chase A&A Tuesday for
--     their counter-offer") was homeowner-readable. Admin-only now, matching
--     the chez_vendor_calls precedent.
-- M5: local_vendor_results had RLS disabled with default table grants —
--     authenticated clients could poison the Chez Certified cache that
--     find-local-vendors serves to other households (and that feeds the
--     vendor registry). Deny-all RLS; the edge function (service role) is
--     the only reader/writer.
-- H3b: chez_requests.analysis_cache / analysis_cache_at existed only in prod
--     (hand-applied era) — no migration created them, so a fresh environment
--     fails at 20270107 (chez_playbook_funnel reads analysis_cache_at).
--     Codified here. (Relocating the cache off the homeowner-readable table
--     is tracked separately — the homeowner UPDATE drop above already stops
--     tampering.)

-- H3b — codify the hand-applied columns so fresh environments build.
ALTER TABLE public.chez_requests
  ADD COLUMN IF NOT EXISTS analysis_cache jsonb,
  ADD COLUMN IF NOT EXISTS analysis_cache_at timestamptz;

-- H1 — close the open RPC. Service role bypasses grants, so the edge
-- functions that legitimately call log_chez_activity are unaffected.
REVOKE EXECUTE ON FUNCTION public.log_chez_activity FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.log_chez_activity FROM anon;
REVOKE EXECUTE ON FUNCTION public.log_chez_activity FROM authenticated;

-- H2 — homeowner direct UPDATE path removed. The admin UPDATE policy and
-- service-role writes (chez-concierge) are untouched.
DROP POLICY IF EXISTS "Members update own household chez requests" ON public.chez_requests;

-- H4 — homeowners can only insert plain user-voice messages, never
-- concierge/system rows or proposal payloads. (iOS sends replies through
-- the chez-concierge `reply` action, which uses the service role, so this
-- is purely a hardening of the direct PostgREST surface.)
DROP POLICY IF EXISTS "Users can insert concierge messages" ON public.concierge_messages;
CREATE POLICY "Users can insert concierge messages" ON public.concierge_messages
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND household_id = public.get_my_household_id()
    AND role = 'user'
    AND proposal IS NULL
  );

-- M1 — operator-private reminders.
DROP POLICY IF EXISTS "Members read own household reminders" ON public.chez_reminders;

-- M5 — deny-all RLS on the shared vendor-results cache.
ALTER TABLE public.local_vendor_results ENABLE ROW LEVEL SECURITY;
