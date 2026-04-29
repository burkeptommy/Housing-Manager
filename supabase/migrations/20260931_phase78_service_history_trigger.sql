-- Phase 78: service-history trigger
--
-- When a handyman_punch_items row transitions to status='done' AND it has
-- a system_id, automatically bump the linked home_systems row's
-- last_service_date. This closes the gap identified in research: today
-- completing handyman work doesn't update the homeowner's "your boiler
-- was last serviced X" view, which undercuts the value-protection
-- narrative ("Chez tracks every system").
--
-- Also stamps updated_at on the punch item itself so optimistic-UI
-- callers see a fresh version token.

CREATE OR REPLACE FUNCTION public.fn_punch_item_completion_bumps_system()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Always refresh updated_at on the punch item itself.
  NEW.updated_at = now();

  -- Only bump system service date on the pending → done transition.
  IF NEW.status = 'done'
     AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'done')
     AND NEW.system_id IS NOT NULL THEN

    -- Stamp completed_at if the caller forgot.
    IF NEW.completed_at IS NULL THEN
      NEW.completed_at = now();
    END IF;

    UPDATE public.home_systems
       SET last_service_date = COALESCE(NEW.completed_at::date, current_date),
           updated_at = now()
     WHERE id = NEW.system_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_punch_item_completion ON public.handyman_punch_items;
CREATE TRIGGER trg_punch_item_completion
  BEFORE UPDATE ON public.handyman_punch_items
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_punch_item_completion_bumps_system();
