-- Phase 85 PR 5 — Default-assignee backfill for existing workspaces.
--
-- Migration 20261214 added is_default_assignee BOOLEAN with a partial
-- unique index. Existing rows defaulted to false, which leaves every
-- pre-Phase-85 workspace with NO default assignee — meaning the admin
-- "Assign handyman" CTA can't auto-suggest anyone. This migration
-- backfills the flag so:
--
--   • Single-member workspaces: that one member becomes the default.
--   • Multi-member workspaces: the owner with the earliest created_at
--     becomes the default (mirrors the "signup user" rule the new
--     bootstrap path uses going forward).
--
-- The partial unique index guarantees idempotency — re-running this
-- migration is a no-op because rows already flipped to true won't be
-- touched (the WHERE clause filters them out).

-- Single-member workspaces: flip the lone member to default.
UPDATE public.provider_workspace_members AS pwm
SET is_default_assignee = true,
    updated_at = now()
WHERE pwm.is_default_assignee = false
  AND pwm.status IN ('active', 'invited')
  AND NOT EXISTS (
    SELECT 1
    FROM public.provider_workspace_members peer
    WHERE peer.workspace_id = pwm.workspace_id
      AND peer.id <> pwm.id
  )
  AND NOT EXISTS (
    SELECT 1
    FROM public.provider_workspace_members existing_default
    WHERE existing_default.workspace_id = pwm.workspace_id
      AND existing_default.is_default_assignee = true
  );

-- Multi-member workspaces with no default yet: pick the earliest
-- owner. Falls back to earliest active member if no owner exists.
WITH workspaces_needing_default AS (
    SELECT DISTINCT pwm.workspace_id
    FROM public.provider_workspace_members pwm
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.provider_workspace_members existing_default
        WHERE existing_default.workspace_id = pwm.workspace_id
          AND existing_default.is_default_assignee = true
    )
),
chosen AS (
    SELECT DISTINCT ON (pwm.workspace_id)
        pwm.id,
        pwm.workspace_id
    FROM public.provider_workspace_members pwm
    JOIN workspaces_needing_default w
      ON w.workspace_id = pwm.workspace_id
    WHERE pwm.status IN ('active', 'invited')
    ORDER BY
        pwm.workspace_id,
        CASE
            WHEN pwm.role = 'owner' THEN 0
            WHEN pwm.role = 'admin' THEN 1
            ELSE 2
        END,
        pwm.created_at ASC
)
UPDATE public.provider_workspace_members AS target
SET is_default_assignee = true,
    updated_at = now()
FROM chosen
WHERE target.id = chosen.id;
