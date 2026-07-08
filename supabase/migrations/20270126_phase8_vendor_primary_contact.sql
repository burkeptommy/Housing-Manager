-- Phase 8.1 (Vendor-Primary-Contact hardening) — the sender gate.
--
-- Decision (2026-07-08 interview): vendors emailing the household's
-- alfred@ address directly must NOT bounce off the allowlist. Every
-- contractor email auto-allowlists (trigger + backfill); unknown senders
-- quarantine with a one-tap allow; "Not them" blocks the sender.
--
-- Also adds contractors.alternate_emails (8.3 learning loop): the
-- confirm row's "Yes, it's them" persists new sender addresses so the
-- vendor-match ladder is tier-1 next time.

-- 1. Blocked senders: a quarantine rejection flips this on. The gate
--    silently drops blocked senders; the contractor sync trigger's
--    ON CONFLICT DO NOTHING never un-blocks a row.
ALTER TABLE public.household_allowed_senders
  ADD COLUMN IF NOT EXISTS blocked boolean NOT NULL DEFAULT false;

-- 2. Learning loop: additional known addresses for a contractor.
ALTER TABLE public.contractors
  ADD COLUMN IF NOT EXISTS alternate_emails text[];

-- 3. Contractor email → allowlist, at the DB choke point so every write
--    path (iOS sheets, quiz mapper, utility mirror, receive-email vendor
--    auto-create, future paths) is covered without app-code drift.
CREATE OR REPLACE FUNCTION public.sync_contractor_allowed_sender()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email IS NOT NULL
     AND position('@' IN NEW.email) > 1
     AND length(trim(NEW.email)) > 3 THEN
    INSERT INTO public.household_allowed_senders (household_id, email, label, is_auto_added)
    VALUES (NEW.household_id, lower(trim(NEW.email)), coalesce(NEW.company_name, 'Vendor'), true)
    ON CONFLICT (household_id, lower(email)) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_contractor_allowed_sender ON public.contractors;
CREATE TRIGGER trg_contractor_allowed_sender
  AFTER INSERT OR UPDATE OF email ON public.contractors
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_contractor_allowed_sender();

-- 4. Backfill: every existing contractor email joins the allowlist.
INSERT INTO public.household_allowed_senders (household_id, email, label, is_auto_added)
SELECT c.household_id, lower(trim(c.email)), coalesce(c.company_name, 'Vendor'), true
FROM public.contractors c
WHERE c.email IS NOT NULL
  AND position('@' IN c.email) > 1
  AND length(trim(c.email)) > 3
ON CONFLICT (household_id, lower(email)) DO NOTHING;
