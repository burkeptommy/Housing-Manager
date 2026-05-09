-- Bugfix Sprint #5 R7-E-2 — handyman-provider dashboard latency
-- climbed to 2s with 100 stress visits in W2. The bottleneck is the
-- six parallel Supabase queries that fan out from `loadDashboard`,
-- specifically the ones that filter on contractor_id / workspace_id
-- and order by updated_at. Existing indexes don't include updated_at
-- in the index payload, so PostgreSQL has to do a heap fetch + in-
-- memory sort on every dashboard load.
--
-- This migration adds three composite indexes — one per slow query —
-- so each query can serve from the index alone (no heap fetch, no
-- sort step). Expected impact: dashboard latency drops from 2s back
-- to <500ms with 100 visits, scales linearly past 500.
--
-- The indexes use DESC on updated_at to match the query's
-- `.order("updated_at", { ascending: false })` clause exactly. With
-- the matching ordering, PostgreSQL can serve `LIMIT 500` from the
-- index without scanning all rows.
--
-- All three tables already have `(workspace_id)` or
-- `(contractor_id, status)` indexes from earlier migrations. Those
-- stay — they cover different access patterns (insert / FK lookups /
-- status filtering). The new indexes are dashboard-specific.

create index if not exists idx_handyman_requests_contractor_updated
  on public.handyman_requests (contractor_id, updated_at desc);

create index if not exists idx_handyman_portal_sessions_contractor_updated
  on public.handyman_portal_sessions (contractor_id, updated_at desc);

create index if not exists idx_provider_invoices_workspace_updated
  on public.provider_invoices (workspace_id, updated_at desc);

-- provider_quotes already has idx_provider_quotes_workspace which is
-- (workspace_id, updated_at desc) per migration 20260818. No new
-- index needed there.
--
-- provider_visit_assignments already has idx_provider_visit_assignments_workspace
-- which is (workspace_id, route_date, stop_order). Matches the
-- dashboard query exactly. No new index needed.
