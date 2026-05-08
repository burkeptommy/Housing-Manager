-- Wave M2 — Punch list capture depth
--
-- Field tech evidence-rich completion: per-item photos (camera + library),
-- voice notes, materials used (with cost basis), and per-item time tracking.
-- Drives billable accuracy + dispute resolution + AI invoice intelligence.
-- Cross-app: every field becomes visible on the contractor desk's
-- VisitDetail review section so the operator + homeowner share one truth.
--
-- Operates on the existing handyman_punch_items rows. Photos + voice land
-- in a new private bucket; materials + time live as JSONB / int columns
-- on the row itself so any read of the punch list returns everything in
-- one round-trip.

alter table public.handyman_punch_items
  add column if not exists materials_used jsonb not null default '[]'::jsonb,
  add column if not exists time_spent_seconds integer not null default 0,
  add column if not exists voice_note_path text;

-- Note: handyman_punch_items already has an `attachments jsonb` column
-- (see Wave O — see types.ts line 196 / mapPunchItemForClient line 295).
-- The column existed but was never written by the field surface; M2 makes
-- it the canonical home for { kind, path, signedUrl, caption, uploadedAt }
-- attachment records. No DDL needed for the column itself.

-- Private bucket. Read access is gated by the handyman-provider edge
-- function signing short-lived URLs after a workspace-membership check
-- (mirrors home-system-photos in 20260910_home_system_photos.sql). No
-- bucket-level RLS — the edge function uses the service role for both
-- upload and signed-URL fetches.
insert into storage.buckets (id, name, public)
values ('punch-item-attachments', 'punch-item-attachments', false)
on conflict (id) do nothing;
