-- Phase 4 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
--
-- Equipment catalog admin queue. When a homeowner photographs a label and
-- Claude Vision extracts brand + model but our catalog doesn't have that
-- exact SKU, we no longer dead-end with "Partially Identified." Instead the
-- iOS app submits a request here, the admin portal surfaces it as a "System
-- request," Tom researches and adds it to equipment_catalog within the
-- 3-4 hour SLA, and the homeowner gets a push notification: "Your AO Smith
-- HPTS-80 is ready in your home dashboard."
--
-- Same pattern can be triggered from the text-search "Don't see your
-- system?" escape hatch (existing CatalogRequestSheet path) so both photo
-- and text fallbacks land in one queue.

BEGIN;

CREATE TABLE IF NOT EXISTS equipment_catalog_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Customer scope
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    -- Optional link to the home_systems row that prompted this request, so
    -- admin can backfill catalog_entry_id on the same row after adding it.
    home_system_id UUID REFERENCES home_systems(id) ON DELETE SET NULL,
    -- What the homeowner / Claude Vision submitted (any subset; admin uses
    -- whatever was captured to research the model)
    submitted_brand TEXT,
    submitted_model_number TEXT,
    submitted_serial TEXT,
    submitted_product_type TEXT,
    -- Photo of the label (Storage path — bucket: equipment-label-photos)
    image_path TEXT,
    -- Free-text notes the user typed (from the catalog-request sheet)
    notes TEXT,
    -- Status lifecycle
    status TEXT NOT NULL DEFAULT 'pending' CHECK (
        status IN ('pending', 'researching', 'added', 'cant_find', 'duplicate')
    ),
    -- Source channel — photo (identify-equipment fallback) or text (search-equipment escape)
    source TEXT NOT NULL DEFAULT 'unknown' CHECK (
        source IN ('photo_label', 'text_search', 'manual', 'unknown')
    ),
    -- Once admin adds the catalog row, link it here for audit + backfill
    assigned_catalog_entry_id UUID REFERENCES equipment_catalog(id) ON DELETE SET NULL,
    -- Admin notes / why it can't be found
    admin_notes TEXT,
    -- Lifecycle timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    homeowner_notified_at TIMESTAMPTZ,
    -- 3-4 hour business-hours SLA — stamped at insert by trigger or app
    sla_due_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '4 hours')
);

CREATE INDEX IF NOT EXISTS idx_equipment_catalog_requests_household
    ON equipment_catalog_requests(household_id);

CREATE INDEX IF NOT EXISTS idx_equipment_catalog_requests_status_created
    ON equipment_catalog_requests(status, created_at DESC)
    WHERE status IN ('pending', 'researching');

CREATE INDEX IF NOT EXISTS idx_equipment_catalog_requests_sla
    ON equipment_catalog_requests(sla_due_at)
    WHERE status IN ('pending', 'researching');

ALTER TABLE equipment_catalog_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Households read own catalog requests"
    ON equipment_catalog_requests;
CREATE POLICY "Households read own catalog requests"
    ON equipment_catalog_requests FOR SELECT
    USING (household_id = public.get_my_household_id());

DROP POLICY IF EXISTS "Households insert own catalog requests"
    ON equipment_catalog_requests;
CREATE POLICY "Households insert own catalog requests"
    ON equipment_catalog_requests FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

-- No UPDATE/DELETE policy for end users — admin (service_role) only.
-- The send-catalog-request edge function uses service_role to write, and
-- the admin portal uses service_role to update status + assign catalog entries.

COMMENT ON TABLE equipment_catalog_requests IS
  'Phase 4 admin queue. Surfaces homeowners requests for missing catalog entries (photo-ID partial-match fallback OR text-search escape hatch). Tom or admin staff resolves within 3-4 hour SLA. iOS app polls this table to surface "Researching..." status; resolution fires push notification.';
COMMENT ON COLUMN equipment_catalog_requests.image_path IS
  'Storage bucket path for the label photo (bucket: equipment-label-photos). NULL if request originated from text search.';
COMMENT ON COLUMN equipment_catalog_requests.assigned_catalog_entry_id IS
  'Set once admin adds the model to equipment_catalog. iOS uses this to link home_system.catalog_entry_id and surface the equipment in the homeowner''s dashboard.';

COMMIT;
