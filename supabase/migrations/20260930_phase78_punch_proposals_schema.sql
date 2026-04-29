-- Phase 78: Homeowner ↔ Handyman coordination architecture (schema layer)
--
-- Promotes punch list items from "wishlist queue" + "frozen text bullets" to
-- first-class queryable rows that survive the full lifecycle (proposed →
-- accepted → assigned to visit → in-progress → done). Adds a uniform
-- proposal pattern to every cross-party row (tasks, punch items, visit
-- requests) so any party can suggest one and the other accepts/declines.
-- Adds a shared template library so both apps + the desktop pull from the
-- same canonical list.
--
-- See /Users/tomburke/.claude/plans/fix-this-error-havenfield-transient-garden.md
-- for the full architectural rationale and edge-case research.
--
-- Migrations bundled here (D first because A references it):
--   D — punch_list_templates table + seed
--   A — extend handyman_punch_items
--   B — extend maintenance_tasks
--   C — extend handyman_requests

-- ============================================================================
-- Migration D: punch_list_templates
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.punch_list_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  default_minutes int,
  default_priority text DEFAULT 'medium' CHECK (default_priority IN ('low','medium','high','urgent')),
  default_cost_basis text DEFAULT 'time_and_materials'
    CHECK (default_cost_basis IN ('time_and_materials','fixed','pass_through')),
  -- Canonical SystemCategoryRegistry key. When a homeowner adds this
  -- template to a property and a matching home_systems row exists, the
  -- punch item auto-links via system_id.
  system_category text,
  seasonal_timing text CHECK (seasonal_timing IN ('spring','summer','fall','winter','anytime')),
  -- Phase 78: when true, this template is also surfacable as a follow-up
  -- visit suggestion in the handyman field app's "Suggest a follow-up" UI.
  is_visit_suggestion boolean NOT NULL DEFAULT false,
  -- When the handyman flags this template as a task for the homeowner
  -- (different scope than punch list), this is the suggested vendor
  -- category that drives the FindLocalVendorSheet pre-filter.
  category_for_homeowner_task text,
  search_keywords text[] NOT NULL DEFAULT '{}'::text[],
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_punch_templates_category
  ON public.punch_list_templates (system_category) WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_punch_templates_seasonal
  ON public.punch_list_templates (seasonal_timing) WHERE archived_at IS NULL;

ALTER TABLE public.punch_list_templates ENABLE ROW LEVEL SECURITY;

-- Templates are global (read-only catalog). Anyone authenticated can read.
-- Writes are admin-only via service role (no RLS write policy).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'punch_list_templates'
      AND policyname = 'punch_list_templates_read'
  ) THEN
    CREATE POLICY punch_list_templates_read
      ON public.punch_list_templates
      FOR SELECT
      TO authenticated
      USING (archived_at IS NULL);
  END IF;
END $$;

-- Seed the canonical templates. Pulled from the existing
-- MaintenanceTemplates handyman bundles (Handyman:spring + Handyman:fall)
-- that the field app currently parses out of notes. Keeping titles
-- verbatim so the backfill can match by string equality.
INSERT INTO public.punch_list_templates
  (title, default_minutes, system_category, seasonal_timing, search_keywords)
VALUES
  -- Handyman:spring core
  ('Clean dryer vent duct', 45, 'Appliance', 'spring', ARRAY['dryer','vent','lint','laundry']),
  ('Fire extinguisher annual check', 15, 'Safety', 'spring', ARRAY['fire','extinguisher','safety']),
  ('Annual radon test', 20, 'Air Quality', 'spring', ARRAY['radon','air quality','basement']),
  ('Inspect weatherstripping on exterior doors', 15, 'Doors', 'spring', ARRAY['weatherstrip','door','seal']),
  ('Walk + clear gutters and downspouts', 60, 'Roofing', 'spring', ARRAY['gutter','downspout','roof']),
  ('Drain and store exterior hoses', 10, 'Plumbing', 'spring', ARRAY['hose','exterior','outdoor']),
  ('Verify radon mitigation fan', 10, 'Air Quality', 'spring', ARRAY['radon','mitigation','fan']),
  ('Test smart water leak detector', 10, 'Plumbing', 'spring', ARRAY['leak','detector','smart','water']),
  ('Service central vacuum system', 30, 'Appliance', 'fall', ARRAY['vacuum','central','filter']),
  ('Re-caulk bath and shower seams', 45, 'Plumbing', 'spring', ARRAY['caulk','bath','shower','seal']),
  -- Handyman:fall core
  ('Touch up exterior paint chips', 60, 'Siding/Exterior', 'fall', ARRAY['paint','exterior','chip']),
  ('Winterize outdoor faucets and hose bibs', 25, 'Plumbing', 'fall', ARRAY['winterize','faucet','hose bib','frost']),
  ('Inspect weatherstripping pre-heating season', 15, 'Doors', 'fall', ARRAY['weatherstrip','heating','seal']),
  ('Inspect exterior caulking around windows & doors', 30, 'Siding/Exterior', 'fall', ARRAY['caulk','window','door','exterior']),
  ('Top up joint sand in pavers', 30, 'Landscaping', 'spring', ARRAY['paver','joint sand','hardscape']),
  ('Treat weeds between pavers', 20, 'Landscaping', 'spring', ARRAY['weed','paver','hardscape']),
  ('Bleed radiators', 30, 'HVAC', 'fall', ARRAY['radiator','bleed','heating','boiler']),
  ('Check attic insulation coverage', 20, 'Insulation', 'fall', ARRAY['attic','insulation']),
  ('Winterize irrigation system', 45, 'Irrigation', 'fall', ARRAY['irrigation','sprinkler','winterize','blow out']),
  ('Replace HVAC filters', 10, 'HVAC', 'anytime', ARRAY['hvac','filter','furnace','air handler']),
  ('Test smoke + CO detectors', 15, 'Safety', 'anytime', ARRAY['smoke','co','carbon monoxide','detector']),
  ('Flush water heater', 45, 'Plumbing', 'fall', ARRAY['water heater','flush','sediment']),
  ('Service generator', 60, 'Generator', 'fall', ARRAY['generator','oil','service']),
  ('Mini-split filter clean', 20, 'HVAC', 'spring', ARRAY['mini split','filter','ductless']),
  ('Touch up interior paint chips', 45, 'General', 'anytime', ARRAY['paint','interior','chip','touch up']),
  ('Adjust cabinet hinges + handles', 20, 'General', 'anytime', ARRAY['cabinet','hinge','handle']),
  ('Re-grout bath tile', 90, 'Plumbing', 'anytime', ARRAY['grout','tile','bath']),
  ('Tighten loose railings', 15, 'General', 'anytime', ARRAY['railing','stair','tight']),
  ('Replace door weather seal', 25, 'Doors', 'fall', ARRAY['weather seal','door','threshold']),
  ('Lubricate garage door hinges + tracks', 20, 'Garage Door', 'anytime', ARRAY['garage','door','lubricate'])
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Migration A: extend handyman_punch_items
-- ============================================================================

ALTER TABLE public.handyman_punch_items
  -- Lifecycle: which visit owns this item (before completion).
  -- Replaces the old "freeze into notes" handoff. Once a visit is
  -- assigned, the item belongs to that visit until the visit completes
  -- (then completed_visit_task_id captures the historical record).
  ADD COLUMN IF NOT EXISTS assigned_visit_task_id uuid REFERENCES public.maintenance_tasks(id) ON DELETE SET NULL,
  -- Provenance: when a homeowner converts a maintenance_task into a punch
  -- item via "Have my handyman do this →", this points back at the source
  -- task. Lets us hide the source task from the primary list without
  -- losing the audit trail.
  ADD COLUMN IF NOT EXISTS delegated_from_task_id uuid REFERENCES public.maintenance_tasks(id) ON DELETE SET NULL,
  -- System linkage: when the punch item is "Replace HVAC filter" on a
  -- specific furnace, this is the FK that lets completion bump the
  -- system's last_service_date (via trg_punch_item_completion).
  ADD COLUMN IF NOT EXISTS system_id uuid REFERENCES public.home_systems(id) ON DELETE SET NULL,
  -- Frozen label snapshot at link time so an archived/renamed system
  -- still displays a sensible label (per research recommendation —
  -- "(archived: Furnace)").
  ADD COLUMN IF NOT EXISTS system_label_snapshot text,
  ADD COLUMN IF NOT EXISTS template_id uuid REFERENCES public.punch_list_templates(id) ON DELETE SET NULL,
  -- Explicit status enum. Today completed_at + archived_at do double duty;
  -- this is cleaner for UI logic and lets us model "in_progress" cleanly.
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','assigned','in_progress','done','cancelled')),
  ADD COLUMN IF NOT EXISTS priority text DEFAULT 'medium'
    CHECK (priority IN ('low','medium','high','urgent')),
  -- Edge case: visit was confirmed (visit_locked_at set), then someone
  -- adds an item. Flag it so the handyman gets a "needs your confirmation"
  -- badge until they touch the visit.
  ADD COLUMN IF NOT EXISTS added_after_lock boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS material_required boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS cost_basis text DEFAULT 'time_and_materials'
    CHECK (cost_basis IN ('time_and_materials','fixed','pass_through')),
  ADD COLUMN IF NOT EXISTS attachments jsonb NOT NULL DEFAULT '[]'::jsonb,
  -- Proposal pattern (uniform across tasks/punch items/requests):
  ADD COLUMN IF NOT EXISTS proposed_by_user_id uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS proposed_by_role text
    CHECK (proposed_by_role IN ('homeowner','handyman','home_manager','staff')),
  ADD COLUMN IF NOT EXISTS proposed_at timestamptz,
  ADD COLUMN IF NOT EXISTS proposal_message text,
  ADD COLUMN IF NOT EXISTS proposal_status text DEFAULT 'none'
    CHECK (proposal_status IN ('none','pending','accepted','declined','cancelled','expired')),
  ADD COLUMN IF NOT EXISTS proposal_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS accepted_by_user_id uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS declined_by_user_id uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS declined_at timestamptz,
  ADD COLUMN IF NOT EXISTS declined_reason text,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- Race protection: only one accepted proposal per item (DB-enforced)
CREATE UNIQUE INDEX IF NOT EXISTS uniq_punch_item_proposal_accepted
  ON public.handyman_punch_items (id) WHERE proposal_status = 'accepted';

CREATE INDEX IF NOT EXISTS idx_punch_items_visit
  ON public.handyman_punch_items (assigned_visit_task_id)
  WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_punch_items_system
  ON public.handyman_punch_items (system_id)
  WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_punch_items_proposal_pending
  ON public.handyman_punch_items (household_id, proposal_status)
  WHERE proposal_status = 'pending';

CREATE INDEX IF NOT EXISTS idx_punch_items_status
  ON public.handyman_punch_items (household_id, status)
  WHERE archived_at IS NULL;

-- Backfill status from existing completed_at / archived_at signals so
-- existing rows fit the new state machine.
UPDATE public.handyman_punch_items
   SET status = 'done'
 WHERE completed_at IS NOT NULL AND status = 'pending';

UPDATE public.handyman_punch_items
   SET status = 'cancelled'
 WHERE archived_at IS NOT NULL AND completed_at IS NULL AND status = 'pending';

-- ============================================================================
-- Migration B: extend maintenance_tasks
-- ============================================================================

ALTER TABLE public.maintenance_tasks
  -- When a task is delegated to the handyman via "Have my handyman do
  -- this →", this points at the spawned punch item. The task is hidden
  -- from primary lists (UI filter) but kept for service history.
  ADD COLUMN IF NOT EXISTS delegated_to_punch_item_id uuid REFERENCES public.handyman_punch_items(id) ON DELETE SET NULL,
  -- Suggested vendor category when handyman flags a task to the homeowner
  -- ("you need a roofer"). Drives the FindLocalVendorSheet pre-filter.
  ADD COLUMN IF NOT EXISTS suggested_category text,
  -- Pre-resolved {town, state, category} blob for one-tap "Find a roofer"
  -- on accepted handyman-flagged tasks.
  ADD COLUMN IF NOT EXISTS suggested_vendor_search jsonb,
  -- Proposal pattern (same shape as punch items):
  ADD COLUMN IF NOT EXISTS proposed_by_user_id uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS proposed_by_role text
    CHECK (proposed_by_role IN ('homeowner','handyman','home_manager','staff')),
  ADD COLUMN IF NOT EXISTS proposed_at timestamptz,
  ADD COLUMN IF NOT EXISTS proposal_message text,
  ADD COLUMN IF NOT EXISTS proposal_status text DEFAULT 'none'
    CHECK (proposal_status IN ('none','pending','accepted','declined','cancelled','expired')),
  ADD COLUMN IF NOT EXISTS proposal_expires_at timestamptz,
  -- Evidence photos when handyman flags a task ("here's the cracked flashing").
  ADD COLUMN IF NOT EXISTS proposal_attachments jsonb NOT NULL DEFAULT '[]'::jsonb,
  -- The visit task this proposal originated from. Lets the homeowner trace
  -- "Burke flagged this during the May 11 visit."
  ADD COLUMN IF NOT EXISTS proposal_origin_visit_task_id uuid REFERENCES public.maintenance_tasks(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS accepted_by_user_id uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS declined_by_user_id uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS declined_at timestamptz,
  ADD COLUMN IF NOT EXISTS declined_reason text,
  -- Home manager authority gate. Server stamps true automatically when
  -- proposal cost ≥ household threshold OR the proposal mutates an
  -- asset (recommends a vendor).
  ADD COLUMN IF NOT EXISTS requires_homeowner_approval boolean NOT NULL DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_task_proposal_accepted
  ON public.maintenance_tasks (id) WHERE proposal_status = 'accepted';

CREATE INDEX IF NOT EXISTS idx_tasks_proposal_pending
  ON public.maintenance_tasks (household_id, proposal_status)
  WHERE proposal_status = 'pending';

CREATE INDEX IF NOT EXISTS idx_tasks_delegated_to_punch
  ON public.maintenance_tasks (delegated_to_punch_item_id)
  WHERE delegated_to_punch_item_id IS NOT NULL;

-- ============================================================================
-- Migration C: extend handyman_requests
-- ============================================================================

ALTER TABLE public.handyman_requests
  -- Set when status flips to 'confirmed'. Used by the visit-lock edge
  -- case: punch items added after this timestamp get added_after_lock=true.
  ADD COLUMN IF NOT EXISTS visit_locked_at timestamptz,
  -- Request-level proposal status. Distinct from existing visit-time
  -- proposals (proposed_visit_at / propose_visit_time RPC). This tracks
  -- "Burke suggests a whole follow-up visit" pending homeowner accept.
  ADD COLUMN IF NOT EXISTS proposal_status text DEFAULT 'none'
    CHECK (proposal_status IN ('none','pending','accepted','declined','cancelled','expired')),
  ADD COLUMN IF NOT EXISTS proposal_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS proposal_message text,
  -- Follow-up chain: a request born from another visit references its
  -- parent. Lets the homeowner trace "this came from the May 11 visit."
  ADD COLUMN IF NOT EXISTS parent_request_id uuid REFERENCES public.handyman_requests(id) ON DELETE SET NULL,
  -- Cost estimate trio: handyman can propose with no estimate, a
  -- ballpark range, or a firm quote. UI must visually distinguish so a
  -- homeowner doesn't conflate "we'll figure it out" with binding numbers.
  ADD COLUMN IF NOT EXISTS cost_estimate_low numeric(10,2),
  ADD COLUMN IF NOT EXISTS cost_estimate_high numeric(10,2),
  ADD COLUMN IF NOT EXISTS cost_estimate_kind text
    CHECK (cost_estimate_kind IN ('none','ballpark','firm_quote')),
  ADD COLUMN IF NOT EXISTS requires_homeowner_approval boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS cancelled_at timestamptz,
  ADD COLUMN IF NOT EXISTS cancelled_by_user_id uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS cancelled_by_role text
    CHECK (cancelled_by_role IN ('homeowner','handyman','home_manager','staff'));

CREATE UNIQUE INDEX IF NOT EXISTS uniq_request_proposal_accepted
  ON public.handyman_requests (id) WHERE proposal_status = 'accepted';

CREATE INDEX IF NOT EXISTS idx_requests_proposal_pending
  ON public.handyman_requests (household_id, proposal_status)
  WHERE proposal_status = 'pending';

CREATE INDEX IF NOT EXISTS idx_requests_parent
  ON public.handyman_requests (parent_request_id)
  WHERE parent_request_id IS NOT NULL;

-- Backfill visit_locked_at for existing confirmed requests so the
-- visit-lock semantics apply uniformly going forward.
UPDATE public.handyman_requests
   SET visit_locked_at = updated_at
 WHERE status = 'confirmed' AND visit_locked_at IS NULL;
