-- ============================================================================
-- Phase 86B — CRM hygiene layer
-- ============================================================================
-- The customer-service cockpit had no canned responses, no case tags, no
-- assignment, and no case merge. This migration lays down the schema for
-- all four so the edge function + iOS surfaces can wire them up.
--
-- Design decisions (per audit recommendations Tom approved):
--   • Canned responses are operator-personal by default with a
--     `shared_with_org` boolean. Keeps Tom unblocked today, doesn't
--     paint us into a corner when the team grows.
--   • Tags are admin-defined per-org via `chez_tag_definitions` (color +
--     label), applied via the `chez_request_tags` join table. Operators
--     do not invent tags inline — keeps the taxonomy tidy.
--   • Case assignment uses `chez_requests.assigned_to_user_id` (nullable).
--     The cockpit's existing "Mine" filter becomes meaningful once the
--     field is set; null = unassigned and surfaces in an Unassigned queue.
--   • Case merge uses a `merged_into_request_id` self-FK on chez_requests.
--     A row gets archived (status → resolved + audit message) and points
--     at the surviving case so the iOS thread can render a "Merged with X"
--     redirect link.
--   • Case linking uses `related_case_ids uuid[]` for "follow-up to" or
--     "this is the parent" relationships that aren't merges.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. chez_snippets — operator-personal canned responses
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chez_snippets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Owner of the snippet. NULL means "org-shared seed" (we ship a few
    -- starter rows out of the box).
    owner_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    -- Short key the operator types after "/" to insert it. Lowercase,
    -- unique per owner. e.g. "options-by-friday", "confirmed", "callback".
    slug TEXT NOT NULL,
    -- Display label shown in the picker.
    label TEXT NOT NULL,
    -- The body — supports `{homeowner_first_name}`, `{address_street}`,
    -- `{vendor_name}` token substitution at insert-time (rendered
    -- client-side in the cockpit composer).
    body TEXT NOT NULL,
    -- Optional category for grouping in the picker.
    category TEXT,
    -- Promote to the org-shared library. When true, other operators
    -- (future teammates) see this in their picker too.
    shared_with_org BOOLEAN NOT NULL DEFAULT FALSE,
    -- Usage counter so the picker can sort by frequently-used.
    use_count INTEGER NOT NULL DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- One slug per owner (operator-personal namespace).
    UNIQUE (owner_user_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_chez_snippets_owner_recent
    ON public.chez_snippets (owner_user_id, last_used_at DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_chez_snippets_shared
    ON public.chez_snippets (shared_with_org)
    WHERE shared_with_org = TRUE;

ALTER TABLE public.chez_snippets ENABLE ROW LEVEL SECURITY;

-- Only admin operators see / write snippets. RLS gate matches every other
-- chez_* admin table.
CREATE POLICY "Admin reads snippets"
    ON public.chez_snippets FOR SELECT
    USING (public.is_tom_admin());
CREATE POLICY "Admin writes own snippets"
    ON public.chez_snippets FOR INSERT
    WITH CHECK (public.is_tom_admin() AND owner_user_id = auth.uid());
CREATE POLICY "Admin updates own snippets"
    ON public.chez_snippets FOR UPDATE
    USING (public.is_tom_admin() AND owner_user_id = auth.uid());
CREATE POLICY "Admin deletes own snippets"
    ON public.chez_snippets FOR DELETE
    USING (public.is_tom_admin() AND owner_user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 2. chez_tag_definitions — admin-defined tag taxonomy
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chez_tag_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Short key: "vip", "winter-snow", "vendor-issue". Lowercase, hyphenated.
    slug TEXT UNIQUE NOT NULL,
    -- Display label shown on chips: "VIP", "Winter snow", "Vendor issue".
    label TEXT NOT NULL,
    -- Chip color from a small palette. The cockpit CSS maps these to
    -- background + text tones.
    color TEXT NOT NULL DEFAULT 'indigo'
        CHECK (color IN ('indigo', 'salmon', 'amber', 'green', 'red', 'muted')),
    -- Optional description for the picker.
    description TEXT,
    -- Soft-delete: hidden in the picker but rows already tagged keep
    -- their tag (avoids surprise re-tagging on definition drop).
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chez_tag_definitions_active
    ON public.chez_tag_definitions (slug)
    WHERE archived_at IS NULL;

ALTER TABLE public.chez_tag_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin reads tag definitions"
    ON public.chez_tag_definitions FOR SELECT
    USING (public.is_tom_admin());
CREATE POLICY "Admin writes tag definitions"
    ON public.chez_tag_definitions FOR INSERT
    WITH CHECK (public.is_tom_admin());
CREATE POLICY "Admin updates tag definitions"
    ON public.chez_tag_definitions FOR UPDATE
    USING (public.is_tom_admin());

-- Seed with a starter set so the cockpit has chips to render on day 1.
INSERT INTO public.chez_tag_definitions (slug, label, color, description) VALUES
    ('vip', 'VIP', 'salmon', 'Top-tier household. Bump priority on every touch.'),
    ('escalated', 'Escalated', 'red', 'Needs special handling or follow-up beyond the SLA window.'),
    ('vendor-issue', 'Vendor issue', 'amber', 'Vendor underperformed or no-showed — track for negotiation.'),
    ('winter-snow', 'Winter snow', 'indigo', 'Snow-event related; cluster with same-storm cases.'),
    ('renewal', 'Contract renewal', 'green', 'Annual or seasonal vendor contract renewal in progress.'),
    ('insurance', 'Insurance claim', 'indigo', 'Active or recent insurance claim driving this request.'),
    ('big-spend', 'Big spend', 'amber', 'Above the homeowner''s explicit-approval threshold; budget eyes needed.')
ON CONFLICT (slug) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. chez_request_tags — join table (case ↔ tag)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chez_request_tags (
    request_id UUID NOT NULL REFERENCES public.chez_requests(id) ON DELETE CASCADE,
    tag_definition_id UUID NOT NULL REFERENCES public.chez_tag_definitions(id) ON DELETE CASCADE,
    applied_by_user_id UUID REFERENCES auth.users(id),
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (request_id, tag_definition_id)
);

CREATE INDEX IF NOT EXISTS idx_chez_request_tags_tag
    ON public.chez_request_tags (tag_definition_id, applied_at DESC);

ALTER TABLE public.chez_request_tags ENABLE ROW LEVEL SECURITY;

-- Household members can READ tags on their own cases (so iOS can render
-- "VIP" / "Escalated" chips in the homeowner thread if we want to expose
-- a subset — TBD product call). Admin reads + writes everything.
CREATE POLICY "Members read own household request tags"
    ON public.chez_request_tags FOR SELECT
    USING (
        request_id IN (
            SELECT id FROM public.chez_requests
            WHERE household_id IN (SELECT household_id FROM public.users WHERE id = auth.uid())
        )
    );
CREATE POLICY "Admin reads all request tags"
    ON public.chez_request_tags FOR SELECT
    USING (public.is_tom_admin());
CREATE POLICY "Admin writes request tags"
    ON public.chez_request_tags FOR INSERT
    WITH CHECK (public.is_tom_admin());
CREATE POLICY "Admin deletes request tags"
    ON public.chez_request_tags FOR DELETE
    USING (public.is_tom_admin());

-- ----------------------------------------------------------------------------
-- 4. chez_requests extensions — assignment + merge + linking
-- ----------------------------------------------------------------------------
ALTER TABLE public.chez_requests
    ADD COLUMN IF NOT EXISTS assigned_to_user_id UUID REFERENCES auth.users(id),
    ADD COLUMN IF NOT EXISTS merged_into_request_id UUID REFERENCES public.chez_requests(id),
    ADD COLUMN IF NOT EXISTS related_case_ids UUID[] NOT NULL DEFAULT ARRAY[]::UUID[];

CREATE INDEX IF NOT EXISTS idx_chez_requests_assigned
    ON public.chez_requests (assigned_to_user_id, status)
    WHERE assigned_to_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_chez_requests_merged
    ON public.chez_requests (merged_into_request_id)
    WHERE merged_into_request_id IS NOT NULL;

-- A merged-into pointer means the row is archived. Status flips to
-- resolved on merge so it falls out of the open queue automatically.
-- Trigger enforces consistency: if merged_into_request_id is set,
-- status must be resolved.
CREATE OR REPLACE FUNCTION public.chez_requests_enforce_merge_status()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.merged_into_request_id IS NOT NULL AND NEW.status <> 'resolved' THEN
        NEW.status := 'resolved';
        NEW.resolved_at := COALESCE(NEW.resolved_at, now());
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS chez_requests_merge_status ON public.chez_requests;
CREATE TRIGGER chez_requests_merge_status
    BEFORE INSERT OR UPDATE ON public.chez_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.chez_requests_enforce_merge_status();

-- ----------------------------------------------------------------------------
-- 5. updated_at trigger for chez_snippets
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.chez_snippets_touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS chez_snippets_touch_updated ON public.chez_snippets;
CREATE TRIGGER chez_snippets_touch_updated
    BEFORE UPDATE ON public.chez_snippets
    FOR EACH ROW
    EXECUTE FUNCTION public.chez_snippets_touch_updated_at();

-- Seed Tom's starter snippets so the picker has rows on day 1. NULL
-- owner_user_id flags these as the org-shared seed set; the operator's
-- first edit promotes a personal copy via the edge function path.
INSERT INTO public.chez_snippets (owner_user_id, slug, label, body, category, shared_with_org) VALUES
    (NULL, 'options-by-friday',
     'Options by Friday',
     'Hi {homeowner_first_name} — I''ll have 3 vetted options for you by Friday EOD with quotes and availability. Sit tight.',
     'updates', TRUE),
    (NULL, 'confirmed',
     'Visit confirmed',
     'Confirmed: {vendor_name} on {visit_date}. You''ll get a reminder the day before. Anything they need to know ahead of time?',
     'confirmations', TRUE),
    (NULL, 'reaching-out-today',
     'Reaching out today',
     'I''m reaching out to {vendor_name} today and will report back tomorrow with what I find.',
     'updates', TRUE),
    (NULL, 'price-check',
     'Negotiating the price',
     'I''m pushing back on the quote — this looks ~$X above market for the scope. I''ll come back with a counter from them in 1-2 business days.',
     'negotiation', TRUE),
    (NULL, 'need-more-info',
     'Need a few details',
     'Quick clarifier so I get this right: {question}. Once I have that I can move forward today.',
     'clarifications', TRUE),
    (NULL, 'all-set',
     'All set',
     'All set on this one — marking it resolved. Let me know if anything else comes up.',
     'closures', TRUE)
ON CONFLICT (owner_user_id, slug) DO NOTHING;

-- ============================================================================
-- Notes
-- ============================================================================
-- • iOS does NOT need to read chez_snippets at all — they're operator-only.
-- • iOS MAY read chez_request_tags (RLS allows it) if we want to expose
--   "VIP" / "Escalated" pills in the homeowner thread later. Not surfaced
--   in iOS as of this migration.
-- • The merge flow is a soft archive: the original case stays in the DB
--   with `merged_into_request_id` set. iOS detail view should render a
--   redirect banner "This conversation was merged into …" pointing at the
--   surviving case. Edge function side: read paths that filter on status
--   already exclude merged rows since status = resolved.
