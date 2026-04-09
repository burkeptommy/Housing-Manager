-- Phase 19k: Task vendor assignment + contractor mirror
--
-- Adds the columns the reconciler needs to:
--   1. Tag every task as personal / vendor / either at creation time
--   2. Mark vendor-managed tasks that don't yet have a vendor on file
--      so the UI can render them as "Find a contractor for: X"
--   3. Mirror quiz-captured service vendors (lawn, pool, pest, etc.)
--      into the contractors table so they're addressable by maintenance
--      tasks AND show up in the existing Contractors CRUD UI
--
-- All columns are nullable / defaulted so existing rows stay valid.
-- Idempotent: re-running this migration is safe.

BEGIN;

-- =============================================================================
-- maintenance_tasks: assignment_type + needs_vendor
-- =============================================================================
-- assigned_contractor_id already exists. We just need:
--   - assignment_type: 'personal' | 'vendor' | 'either'
--     Tells the UI whether to render the task as a to-do (personal) or as
--     a vendor delegation (vendor). 'either' is a soft signal — defaults to
--     personal but can be flipped without re-running the reconciler.
--   - needs_vendor: TRUE when the template is vendor-managed but no
--     contractor was on file at creation time. UI renders these as
--     "Find a contractor for: X" with an orange CTA.

ALTER TABLE maintenance_tasks
  ADD COLUMN IF NOT EXISTS assignment_type TEXT
    CHECK (assignment_type IN ('personal', 'vendor', 'either'))
    DEFAULT 'personal';

ALTER TABLE maintenance_tasks
  ADD COLUMN IF NOT EXISTS needs_vendor BOOLEAN DEFAULT FALSE;

-- Index so the dashboard can quickly count "your to-dos vs vendor-managed"
-- per property without scanning every row.
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_assignment_type
  ON maintenance_tasks(property_id, assignment_type)
  WHERE is_archived IS NOT TRUE;

-- Backfill: any existing task with a non-null assigned_contractor_id is
-- already a vendor task. Set assignment_type accordingly so the UI groups
-- old data correctly without forcing users to re-run the quiz.
UPDATE maintenance_tasks
SET assignment_type = 'vendor'
WHERE assigned_contractor_id IS NOT NULL
  AND assignment_type IS NULL OR assignment_type = 'personal';

-- =============================================================================
-- contractors: category + utility_provider_id (the mirror columns)
-- =============================================================================
-- The contractors table already has `specialties` (text array) but the
-- reconciler needs a single canonical category for fast lookup ("does this
-- household have a contractor for HVAC?"). We add:
--   - category: matches home_systems.category for direct join
--   - utility_provider_id: FK back to the catalog row when the contractor
--     was sourced from a quiz answer (e.g., user picked "Hoffman Landscapes"
--     from the landscaping picker → contractor row gets created and points
--     back to the utility_providers row so logo + brand color stay in sync)

ALTER TABLE contractors
  ADD COLUMN IF NOT EXISTS category TEXT;

ALTER TABLE contractors
  ADD COLUMN IF NOT EXISTS utility_provider_id UUID
    REFERENCES utility_providers(id) ON DELETE SET NULL;

-- Cached fields from the catalog row so we don't have to JOIN on every
-- vendor render. These get refreshed when the source utility_provider
-- changes (rare) but are otherwise authoritative on the contractor row.
ALTER TABLE contractors
  ADD COLUMN IF NOT EXISTS logo_url TEXT;

ALTER TABLE contractors
  ADD COLUMN IF NOT EXISTS brand_color TEXT;

ALTER TABLE contractors
  ADD COLUMN IF NOT EXISTS website TEXT;

-- Source flag — distinguishes contractors created via:
--   'manual'      → user typed in the contractors UI
--   'quiz'        → mirrored from a quiz utility_account at quiz time
--   'find_vendor' → picked from the "find me a vendor" Google Places flow
--                   (Phase 19n — schema ready, code lands later)
ALTER TABLE contractors
  ADD COLUMN IF NOT EXISTS source TEXT
    CHECK (source IN ('manual', 'quiz', 'find_vendor'))
    DEFAULT 'manual';

-- Index for the reconciler's "find contractor for category X" lookup.
CREATE INDEX IF NOT EXISTS idx_contractors_household_category
  ON contractors(household_id, category)
  WHERE category IS NOT NULL;

-- =============================================================================
-- contractors backfill from existing data
-- =============================================================================
-- Any existing contractor row has its category inferred from specialties
-- (first element). Future rows will set category explicitly.

UPDATE contractors
SET category = specialties[1]
WHERE category IS NULL
  AND specialties IS NOT NULL
  AND array_length(specialties, 1) > 0;

COMMIT;
