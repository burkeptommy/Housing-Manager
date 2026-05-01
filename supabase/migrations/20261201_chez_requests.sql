-- Phase 80: Chez Concierge — homeowner submits request, Tom (admin) handles
-- it from the admin portal, replies / asks follow-ups / proposes vendors,
-- and the homeowner tracks progress in the iOS app.
--
-- Architecture:
--   - chez_requests        — one row per request (status, category, SLA, unread flags)
--   - concierge_messages   — extended with request_id FK; per-request thread
--   - inbox_items          — admin replies create rows here (smart routing into
--                            Needs Action / Unread tabs based on
--                            metadata.acknowledgement_required)
--   - documents bucket     — attachments stored via existing DocumentUploadManager;
--                            paths recorded as JSONB on concierge_messages.attachments
--
-- Tom's scope clarification (plan): MVP + photo/PDF attachments + visual SLA
-- badge only. Smart inbox routing for admin replies. No structured proposal
-- cards yet (plain text for v1).

-- ============================================================================
-- 1. chez_requests — the parent request entity
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chez_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN (
        'find_vendor',
        'get_quote',
        'schedule_visit',
        'coordinate_task',
        'find_handyman',
        'general'
    )),
    summary TEXT NOT NULL,
    -- Entry-point payload: system_id, task_id, contractor_category,
    -- current_vendors_on_file, project_id, quote_id, etc. Also stores
    -- prefilled "Details you sent" content the homeowner sees in the
    -- detail view's collapsible card.
    context JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN (
        'open',              -- waiting on Tom
        'waiting_customer',  -- Tom asked a follow-up; ball in homeowner's court
        'resolved'           -- Tom marked done
    )),
    sla_due_at TIMESTAMPTZ NOT NULL,
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    unread_for_user BOOLEAN NOT NULL DEFAULT false,
    unread_for_admin BOOLEAN NOT NULL DEFAULT true,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chez_requests_household
    ON public.chez_requests(household_id, status, last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_chez_requests_user
    ON public.chez_requests(user_id, last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_chez_requests_admin_open
    ON public.chez_requests(status, sla_due_at)
    WHERE status != 'resolved';

ALTER TABLE public.chez_requests ENABLE ROW LEVEL SECURITY;

-- Household members read/insert their own household's requests.
CREATE POLICY "Members read own household chez requests"
    ON public.chez_requests FOR SELECT
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Members insert own household chez requests"
    ON public.chez_requests FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Members update own household chez requests"
    ON public.chez_requests FOR UPDATE
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

-- Tom (admin) reads ALL chez_requests via the admin portal's user JWT
-- (the portal logs in as tom@getchez.com using Supabase Auth, then queries
-- chez_requests directly via PostgREST). The `public.is_tom_admin()`
-- helper from `20261001_admin_onboarding_lab.sql` checks the JWT email
-- against the allowlist; reuse it here so we don't drift the rule.
-- Writes still flow through the chez-concierge Edge Function (atomic
-- side effects + push notifications), but the SELECT policy needs to
-- exist for the admin list view to work.
CREATE POLICY "Admin reads all chez requests"
    ON public.chez_requests FOR SELECT
    USING ( public.is_tom_admin() );

CREATE POLICY "Admin updates all chez requests"
    ON public.chez_requests FOR UPDATE
    USING ( public.is_tom_admin() );

-- ============================================================================
-- 2. concierge_messages — extend the existing table
-- ============================================================================

-- Add request_id FK so messages thread under a parent request.
ALTER TABLE public.concierge_messages
    ADD COLUMN IF NOT EXISTS request_id UUID REFERENCES public.chez_requests(id) ON DELETE CASCADE;

-- Add attachments JSONB so messages can carry photo / PDF metadata.
-- Shape: [{ "path": "documents/chez-requests/{user_id}/{filename}",
--           "filename": "leak.jpg",
--           "mime_type": "image/jpeg",
--           "size_bytes": 2048576,
--           "uploaded_at": "..." }]
ALTER TABLE public.concierge_messages
    ADD COLUMN IF NOT EXISTS attachments JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Allow 'system' role for status-change rows ("Tom marked this resolved").
-- Existing CHECK (if any) is implicit via column comment; relax via column edit
-- if a constraint exists. Most installs only had application-side validation.
DO $$
BEGIN
    -- If a check constraint exists, drop + recreate to include 'system'.
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'concierge_messages_role_check'
    ) THEN
        ALTER TABLE public.concierge_messages
            DROP CONSTRAINT concierge_messages_role_check;
    END IF;
END$$;

ALTER TABLE public.concierge_messages
    ADD CONSTRAINT concierge_messages_role_check
    CHECK (role IN ('user', 'concierge', 'system'));

CREATE INDEX IF NOT EXISTS idx_concierge_messages_request
    ON public.concierge_messages(request_id, created_at);

-- Admin SELECT for concierge_messages (so the admin portal's request
-- detail panel can render the thread). Writes still funnel through the
-- chez-concierge Edge Function. Existing household-scoped policies on
-- concierge_messages remain in place — this is additive.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'concierge_messages'
          AND policyname = 'Admin reads all concierge messages'
    ) THEN
        EXECUTE 'CREATE POLICY "Admin reads all concierge messages"
            ON public.concierge_messages FOR SELECT
            USING ( public.is_tom_admin() )';
    END IF;
END$$;

-- ============================================================================
-- 3. inbox_items — extend with FK to chez_requests for smart routing
-- ============================================================================

ALTER TABLE public.inbox_items
    ADD COLUMN IF NOT EXISTS related_chez_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_inbox_items_chez_request
    ON public.inbox_items(related_chez_request_id)
    WHERE related_chez_request_id IS NOT NULL;

-- ============================================================================
-- 4. updated_at auto-stamp trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_chez_requests_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS chez_requests_updated_at ON public.chez_requests;
CREATE TRIGGER chez_requests_updated_at
    BEFORE UPDATE ON public.chez_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.set_chez_requests_updated_at();

-- ============================================================================
-- 5. Backfill: wrap legacy concierge_messages rows in synthetic requests
-- ============================================================================
-- Group by (household_id, calendar day) and create one synthetic request
-- per group so the admin portal can still surface the history in context.

DO $$
DECLARE
    grp RECORD;
    new_request_id UUID;
BEGIN
    FOR grp IN
        SELECT
            household_id,
            user_id,
            DATE(created_at) AS day,
            MIN(created_at) AS first_at,
            MAX(created_at) AS last_at
        FROM public.concierge_messages
        WHERE request_id IS NULL
        GROUP BY household_id, user_id, DATE(created_at)
    LOOP
        INSERT INTO public.chez_requests (
            household_id, user_id, category, summary, context,
            status, sla_due_at, last_message_at, unread_for_user,
            unread_for_admin, resolved_at, created_at, updated_at
        ) VALUES (
            grp.household_id, grp.user_id, 'general',
            'Legacy concierge thread (' || grp.day || ')',
            jsonb_build_object('legacy_concierge', true, 'backfilled_at', now()),
            'resolved',
            grp.first_at + INTERVAL '24 hours',  -- synthetic SLA, irrelevant since resolved
            grp.last_at,
            false, false,
            grp.last_at,
            grp.first_at, grp.last_at
        )
        RETURNING id INTO new_request_id;

        UPDATE public.concierge_messages
        SET request_id = new_request_id
        WHERE household_id = grp.household_id
          AND user_id = grp.user_id
          AND DATE(created_at) = grp.day
          AND request_id IS NULL;
    END LOOP;
END$$;

-- Once backfill has run, request_id should be NOT NULL going forward.
-- We don't add NOT NULL yet (in case of edge-case rows we missed), but new
-- inserts via the chez-concierge Edge Function always supply it.

-- ============================================================================
-- 6. Helper: compute business-hours-aware SLA due timestamp
-- ============================================================================
-- Given a start timestamp, returns start + 24 business hours skipping
-- weekends. Used by the chez-concierge Edge Function on submit.

CREATE OR REPLACE FUNCTION public.chez_business_hours_due(start_at TIMESTAMPTZ)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    cursor_at TIMESTAMPTZ := start_at;
    remaining_hours INT := 24;
    dow INT;
BEGIN
    WHILE remaining_hours > 0 LOOP
        dow := EXTRACT(DOW FROM cursor_at);
        -- 0 = Sunday, 6 = Saturday in Postgres EXTRACT(DOW)
        IF dow = 0 OR dow = 6 THEN
            -- Skip the rest of this weekend day, jump to next 9am
            cursor_at := DATE_TRUNC('day', cursor_at) + INTERVAL '1 day';
            CONTINUE;
        END IF;
        -- Add 1 hour at a time so the result lands on a weekday.
        cursor_at := cursor_at + INTERVAL '1 hour';
        remaining_hours := remaining_hours - 1;
    END LOOP;
    -- If we landed on a weekend, walk forward to Monday.
    WHILE EXTRACT(DOW FROM cursor_at) IN (0, 6) LOOP
        cursor_at := cursor_at + INTERVAL '1 day';
    END LOOP;
    RETURN cursor_at;
END;
$$;

-- ============================================================================
-- 7. Add to realtime publication (homeowner subscribes to message inserts)
-- ============================================================================
-- Phase 80 v1 doesn't subscribe yet (window-focus refresh suffices), but
-- adding the tables to the publication now means a future subscribe-on-open
-- works without a schema migration.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'chez_requests'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chez_requests;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'concierge_messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.concierge_messages;
    END IF;
EXCEPTION
    WHEN undefined_object THEN
        -- Publication doesn't exist (local dev without realtime); ignore.
        RAISE NOTICE 'supabase_realtime publication not found; skipping realtime add';
END$$;
