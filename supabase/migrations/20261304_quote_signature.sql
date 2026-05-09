-- Wave M4 — In-person quote builder (kitchen-table close)
--
-- Extends provider_quotes with the kitchen-table signature artifact +
-- captures who signed (homeowner / witness) and stores a private PNG
-- of the actual finger-drawn signature. The pre-existing signed_at /
-- signed_name columns from Phase 73b cover the "homeowner approves a
-- web-delivered quote by typing their name" path; this wave adds the
-- "field tech sat down at the kitchen table and the homeowner signed
-- on a tablet" path. Both paths converge on signed_at + signed_name
-- so the homeowner-side display logic doesn't have to care which
-- channel produced the signature; signature_path is the visual
-- evidence the field technician needs to defend the deal at audit
-- time, and signer_role distinguishes a witness signature (e.g. a
-- spouse who's not the named contract holder) from the principal.
--
-- Workspace-scoped private bucket. Read access is gated by the
-- handyman-provider edge function signing short-lived URLs after a
-- workspace-membership check (mirrors the punch-item-attachments
-- pattern from M2). No bucket-level RLS — the edge function uses the
-- service role for both upload and signed-URL fetches.
--
-- Operations Desk (web) renders signed_name + signed_at + the inline
-- signature image on the quote detail panel via the same signed-URL
-- path the field app uses; cross-app parity is automatic.

alter table public.provider_quotes
  add column if not exists signature_path text,
  add column if not exists signer_role text;

-- Note: signed_at + signed_name were added by 20260907_phase73b_quote_negotiation.sql
-- so this wave does NOT re-create them. We just lean on the existing columns
-- and stamp them via the new contractor-side sign_quote action.

-- Wave M4.b — workspace-level default labor rate so the
-- build_quote_from_visit pre-fill produces a usable cost on first tap.
-- Stored as cents to keep arithmetic integer. Default $125/hr (12500
-- cents) — a reasonable HNW handyman rate. Workspaces can edit later
-- via the Operations Desk Settings screen (deferred — when Settings
-- ships an editor for this column, the default still keeps existing
-- rows useful).
alter table public.provider_workspaces
  add column if not exists default_hourly_rate_cents integer not null default 12500;

-- Private bucket. Read access via service-role signed URLs. Mirrors
-- punch-item-attachments + home-system-photos.
insert into storage.buckets (id, name, public)
values ('quote-signatures', 'quote-signatures', false)
on conflict (id) do nothing;
