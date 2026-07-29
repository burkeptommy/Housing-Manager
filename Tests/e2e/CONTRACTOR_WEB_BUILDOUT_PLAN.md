# Operations Desk (web contractor) — full buildout plan

Comprehensive plan covering EVERY web-side gap identified during the overnight E2E pass. 20 waves of work organized so a future chat session can drop in and execute one wave at a time via subagent dispatch. Plus 7 cross-app (B) waves that ship features touching both the mobile PWA and the desktop SPA.

The Operations Desk lives at `website/operations/` (React 18 + Vite 5 + TypeScript + React Router v6 SPA). It serves the desk-side workspace for Chez Contractor companies — dispatch, calendar, routes, crew, homes, quotes, messages — backed by `provider_*` Supabase tables + `handyman-provider` Edge Function.

This is a **complete spec** — no "skip this" gates. Each wave is dispatched independently. The final state ships every Section 22 desktop concern + the full Section 5 / 11 / 12 / 14 / 15a / 15b / 15c desktop parity story + every half-built feature from the overnight pass.

---

## Pre-flight (every subagent)

1. Read `/tmp/ui-test/CONTRACTOR_SETUP.md` (env, fixtures, JWT, test users)
2. `mcp__Claude_in_Chrome__list_connected_browsers` returns ≥ 1
3. Resize Chrome to **1440×900** (desktop standard); **1280×800** for compact-laptop checks; **1920×1080** for large-screen verification
4. `cd /Users/tomburke/Documents/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8/website/operations && npm install && npm run dev` — Vite at `localhost:5173/operations/`
5. In a second terminal: `cd /Users/tomburke/Documents/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8/website && python3 -m http.server 8000` — serves `handyman.html` so the auth flow + `?next=` deep-link round-trip works
6. Sign in as `e2e-contractor-w1@chezcontractor.test` (W1 solo) / `e2e-contractor-w2@chezcontractor.test` (W2 crew6) / `e2e-contractor-w3@chezcontractor.test` (W3 crew25) — each pre-seeded by `Tests/e2e/run-contractor.mjs`
7. Initial discipline check on every screen: `grep -i 'handyman'` in rendered DOM = 0; em-dash count = 0; salmon usage matches Section 22 B1 (only primary CTA / active queue / SLA pills / fit-meter success / homeowner-panel highlighted system row)

After implementation:
- TS clean: `cd website/operations && npx tsc --noEmit`
- Build clean: `npm run build` succeeds, `dist/` updated
- Apply migration: `supabase db push --linked`
- Edge Function deploy: `supabase functions deploy handyman-provider --no-verify-jwt` (or new fn name if introduced)
- Take 1–3 screenshots in 1440×900 viewport; one extra in 1280×800 if layout-sensitive
- Cross-app DB cross-check via service-role JWT — every contractor write must land on the homeowner iOS surface where applicable
- Commit + push to `claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG` (default branch — Vercel auto-deploys on push)

---

## Wave W1 — Crew admin completeness (timesheets + certifications + performance + payroll prep)

**Why:** the operator's accountability story for the crew. Solo workspaces skip; crew workspaces (W2 crew6, W3 crew25) need this for hours-of-the-week, certifications, payroll prep.

**Schema (`supabase/migrations/20261309_crew_admin.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_member_timesheets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  total_seconds INT NOT NULL DEFAULT 0,
  visit_seconds INT NOT NULL DEFAULT 0,
  drive_seconds INT NOT NULL DEFAULT 0,
  paused_seconds INT NOT NULL DEFAULT 0,
  approved_at TIMESTAMPTZ,
  approved_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, member_id, week_start)
);

CREATE TABLE IF NOT EXISTS public.provider_member_certifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  cert_type TEXT NOT NULL,                -- e.g. 'EPA 608', 'Master Plumber', 'OSHA 10'
  cert_number TEXT,
  issued_at DATE,
  expires_at DATE,
  doc_path TEXT,                           -- storage path for uploaded copy
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked', 'pending'))
);

CREATE TABLE IF NOT EXISTS public.provider_member_performance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  request_id UUID NOT NULL REFERENCES public.handyman_requests(id) ON DELETE CASCADE,
  customer_rating INT CHECK (customer_rating BETWEEN 1 AND 5),
  on_time_rating BOOLEAN,                  -- did they arrive in window?
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS provider_member_timesheets_member_idx ON public.provider_member_timesheets(member_id);
CREATE INDEX IF NOT EXISTS provider_member_certifications_member_idx ON public.provider_member_certifications(member_id);
CREATE INDEX IF NOT EXISTS provider_member_performance_member_idx ON public.provider_member_performance(member_id);

ALTER TABLE public.provider_member_timesheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_member_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_member_performance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace_members_can_rw_timesheets" ON public.provider_member_timesheets
  FOR ALL USING (workspace_id IN (
    SELECT workspace_id FROM public.provider_workspace_members
    WHERE user_id = auth.uid() AND status = 'active'
  ));
-- Mirror policy for certifications + performance
```

**Edge Function actions (handyman-provider):**
- `compute_timesheet` — accepts `{ workspaceId, memberId, weekStart }`. Aggregates `provider_visit_assignments` for the member where `clock_in_at` falls in the week. Sums `clock_out_at - clock_in_at - paused_seconds` per assignment → totals → upserts `provider_member_timesheets` row.
- `approve_timesheet` — accepts `{ timesheetId }`. Stamps `approved_at`, `approved_by_user_id`. Insert audit message? No — internal; log via `analytics_events` instead.
- `add_certification` — accepts `{ memberId, certType, certNumber?, issuedAt?, expiresAt?, base64Doc? }`. Uploads doc to `crew-certifications` bucket. Returns row.
- `record_performance` — accepts `{ memberId, requestId, customerRating?, onTimeRating? }`. Auto-fired post-visit-complete from the customer's reply. Manual override available.

**SPA UI (`website/operations/src/screens/Crew.tsx` — extend):**
- New Profile sub-section "**Timesheets**" — week selector, line per day with visit/drive/pause split, weekly total in `26pt` serif, Approve button (Tom-only / admin-only based on workspace role).
- New Profile sub-section "**Certifications**" — list with name, issuer, expiry date, "View doc" link, "+ Add" CTA. Expiring-within-30-days rows render `pill-warning` (amber); expired rows render `pill-critical` (red).
- New Profile sub-section "**Performance**" — last 50 visits with customer rating star + on-time-or-not pill. Aggregate at top: average rating, on-time %, total visits this quarter.
- New top-of-page **"Crew at a glance"** strip (already in Crew mode hero) extended: per-tech this-week hours / on-time % / open part requests.

**Cross-app parity:** none direct (operator-facing surface). Customer rating data feeds homeowner iOS in W15.

**Effort:** 120 min. **Demo value:** medium-high.

---

## Wave W2 — Workspace settings depth (branding + hours + service area + tax/markup + payment + cancellation policy)

**Why:** every contractor company has business defaults that propagate everywhere — logo on quotes, tax rate baked into invoices, service area cap on dispatch radius, business hours gate auto-dispatch, default markup on materials feeds quote builder.

**Schema (`supabase/migrations/20261310_workspace_settings_depth.sql`):**
```sql
ALTER TABLE public.provider_workspaces
  ADD COLUMN IF NOT EXISTS logo_path TEXT,
  ADD COLUMN IF NOT EXISTS brand_color TEXT,
  ADD COLUMN IF NOT EXISTS business_hours JSONB NOT NULL DEFAULT '{
    "monday": {"open": "08:00", "close": "17:00", "closed": false},
    "tuesday": {"open": "08:00", "close": "17:00", "closed": false},
    "wednesday": {"open": "08:00", "close": "17:00", "closed": false},
    "thursday": {"open": "08:00", "close": "17:00", "closed": false},
    "friday": {"open": "08:00", "close": "17:00", "closed": false},
    "saturday": {"open": "09:00", "close": "13:00", "closed": false},
    "sunday": {"open": "00:00", "close": "00:00", "closed": true}
  }'::jsonb,
  ADD COLUMN IF NOT EXISTS holidays JSONB NOT NULL DEFAULT '[]'::jsonb,           -- array of {date, name}
  ADD COLUMN IF NOT EXISTS service_area JSONB NOT NULL DEFAULT '{}'::jsonb,       -- {center_lat, center_lng, radius_miles, zip_codes[]}
  ADD COLUMN IF NOT EXISTS tax_rate NUMERIC(5,4) NOT NULL DEFAULT 0,              -- 0.0875 = 8.75%
  ADD COLUMN IF NOT EXISTS materials_markup_pct NUMERIC(5,4) NOT NULL DEFAULT 0,  -- 0.20 = 20%
  ADD COLUMN IF NOT EXISTS labor_default_rate_cents INT,                          -- $/hr in cents
  ADD COLUMN IF NOT EXISTS payment_methods JSONB NOT NULL DEFAULT '["cash", "check", "venmo", "zelle"]'::jsonb,
  ADD COLUMN IF NOT EXISTS cancellation_policy_text TEXT,
  ADD COLUMN IF NOT EXISTS quote_terms_text TEXT,
  ADD COLUMN IF NOT EXISTS invoice_footer_text TEXT,
  ADD COLUMN IF NOT EXISTS auto_dispatch_radius_miles INT;
```

**Storage:**
```sql
INSERT INTO storage.buckets (id, name, public)
  VALUES ('workspace-branding', 'workspace-branding', false)
  ON CONFLICT (id) DO NOTHING;
```

**Edge Function actions:**
- `update_workspace_settings` — accepts a partial workspace object; deep-merges JSONB fields; writes scalar columns; returns updated row.
- `upload_workspace_logo` — accepts `{ base64, contentType }`. Uploads to `workspace-branding` bucket as `<workspace_id>/logo.png`. Sets `logo_path`.
- `compute_quote_total_with_settings` — already exists in quote builder; extend to read `tax_rate` + `materials_markup_pct` from workspace.
- `is_workspace_open_now` — utility for the auto-dispatch gate; returns `{ open, nextOpen }`.

**SPA UI (new `website/operations/src/screens/Settings.tsx`):**
Sidebar adds "**Settings**" entry routing to `/settings`. Page is a 2-column layout with sub-tabs:
- **General**: company name, brand color, logo upload (drag-drop), display name on quotes
- **Business hours**: 7-row grid (Mon-Sun) with open/close time + closed toggle; "+ Add holiday" list with date + name
- **Service area**: ZIP-code pill input + center point picker (Mapbox/Google Static Map) + radius slider
- **Pricing**: tax rate, materials markup %, labor default $/hr (cents), payment methods (multi-checkbox)
- **Quotes/Invoices**: rich-text editors for quote terms, invoice footer, cancellation policy

Each section has explicit "**Save**" CTA (salmon primary) + "Cancel" (ghost). Unsaved-changes badge in top bar.

**Cross-app parity:** logo + brand color render on homeowner iOS quote/invoice views (already wired to read these columns when present). Workspace hours gate the homeowner's "Request a visit" calendar slot picker.

**Effort:** 120 min. **Demo value:** very high — every operator-touched surface depends on these defaults.

---

## Wave W3 — HomeDetail 12-subtab promotion

**Why:** the existing `Homes.tsx` shows 3-up cards but tapping into a home opens a thin detail. The plan was always 12 sub-tabs (Overview / Systems / Services / Quotes / Invoices / Visits / Documents / Notes / Members / Vendors / Photos / Activity) — promote to a full Apple-Notes-style left-rail drawer with all 12.

**Schema:** none. Pulls from existing tables.

**Edge Function actions:**
- `fetch_home_detail` — accepts `{ workspaceId, householdId }`. Returns full bundle: customer + property + systems[] + services[] + quotes[] + invoices[] + visits[] + documents[] + notes[] + members[] + vendors[] + photos[] + activity_log[].

**SPA UI (`website/operations/src/screens/HomeDetail.tsx` — replace stub):**
Routes from `/homes/:householdId`. Layout: left-rail drawer (240px wide) with 12 sub-tab nav + main content area.
- **Overview**: hero card with home address + value + 4-up KPI strip (systems on file / open services / open quotes / total revenue)
- **Systems**: full inventory list with category filter chips, per-system row (name, brand/model/serial, last serviced, next due), `+ Add system` CTA opens W17 authoring sheet
- **Services**: routines/maintenance plans with on/off pill + monthly cost
- **Quotes**: pipeline view (draft / sent / approved / declined) + each row clickable into Quote Detail
- **Invoices**: paid / outstanding / overdue + each row clickable into Invoice Detail
- **Visits**: chronological history with status badges + drilldown
- **Documents**: list + `+ Upload` (uploads to `documents` table, household-scoped)
- **Notes**: free-text notes log (think Apple Notes per-customer)
- **Members**: family members + linked users
- **Vendors**: 3rd-party vendors on file (HVAC vendor's vendor, etc.)
- **Photos**: aggregated photos from punch items + system inventory + documents
- **Activity**: full audit trail (every status change, every message, every quote/invoice action)

**Cross-app parity:** Documents tab uploads land on homeowner iOS via `documents` table with `visible_to_home_managers = true` (default) or per-document override.

**Effort:** 150 min. **Demo value:** very high — the operator's primary surface for every customer.

---

## Wave W4 — Section 14 Reporting & Analytics

**Why:** the operator needs revenue / jobs / utilization / marketing-attribution dashboards to actually run the business. Currently the SPA has a Routes screen but no analytics surface.

**Schema (`supabase/migrations/20261311_reporting_views.sql`):** materialized views recomputed nightly via `pg_cron` or on-demand:
```sql
CREATE OR REPLACE VIEW public.provider_revenue_daily AS
SELECT
  workspace_id,
  date_trunc('day', sent_at)::date AS day,
  count(*) AS invoices_sent,
  sum(total_cents) AS gross_cents,
  sum(CASE WHEN paid_at IS NOT NULL THEN total_cents ELSE 0 END) AS paid_cents
FROM public.provider_invoices
WHERE sent_at IS NOT NULL
GROUP BY workspace_id, date_trunc('day', sent_at);

CREATE OR REPLACE VIEW public.provider_jobs_daily AS
SELECT
  workspace_id,
  date_trunc('day', created_at)::date AS day,
  count(*) FILTER (WHERE status = 'new') AS new_jobs,
  count(*) FILTER (WHERE status = 'completed') AS completed_jobs,
  count(*) FILTER (WHERE status = 'cancelled') AS cancelled_jobs
FROM public.handyman_requests
GROUP BY workspace_id, date_trunc('day', created_at);

CREATE OR REPLACE VIEW public.provider_tech_utilization_daily AS
SELECT
  pva.workspace_id,
  pva.assigned_member_id,
  date_trunc('day', pva.clock_in_at)::date AS day,
  sum(EXTRACT(EPOCH FROM (pva.clock_out_at - pva.clock_in_at)) - pva.paused_seconds)::int AS billable_seconds,
  count(*) AS visits_completed
FROM public.provider_visit_assignments pva
WHERE pva.clock_in_at IS NOT NULL AND pva.clock_out_at IS NOT NULL
GROUP BY pva.workspace_id, pva.assigned_member_id, date_trunc('day', pva.clock_in_at);
```

**Edge Function actions:**
- `fetch_revenue_report` — accepts `{ workspaceId, range: 'week'|'month'|'quarter'|'year', from?, to? }`. Returns daily series + totals + period-over-period delta.
- `fetch_jobs_report` — same shape. Returns funnel: new → confirmed → in_progress → completed → invoiced → paid.
- `fetch_utilization_report` — per-tech billable hours + utilization % (billable / scheduled).
- `fetch_marketing_attribution` — leads grouped by `lead_source` (column on `handyman_requests`, set when ingested) with conversion rate to invoice paid.

**SPA UI (new `website/operations/src/screens/Reports.tsx`):**
Sidebar adds "**Reports**" entry routing to `/reports`. Layout: sub-tab nav (Revenue / Jobs / Utilization / Marketing) + range picker (Week / Month / Quarter / Year / Custom).
- **Revenue**: line chart (gross + paid) + KPI tiles (gross, paid, outstanding, AVG ticket) + weekday breakdown bar chart
- **Jobs**: funnel chart (5 stages) + cancel-rate pill + AVG cycle time
- **Utilization**: per-tech bar chart with billable / paused / drive split + utilization % aggregate
- **Marketing**: lead source breakdown pie + per-source conversion table

Use `recharts` (npm install) — the only new dep. No CSS-in-JS; styled with `chez.css` tokens.

**Cross-app parity:** none direct.

**Effort:** 150 min. **Demo value:** very high — operator-facing P&L story.

---

## Wave W5 — Section 15b Pipeline (full Kanban with drag-and-drop + lead source attribution + conversion funnel)

**Why:** Currently quotes appear as a list. Pipeline view is a Kanban (Lead → Quoted → Negotiating → Won → Lost) where the operator can drag cards between stages. Drives recurring sales motion.

**Schema (`supabase/migrations/20261312_pipeline_stages.sql`):**
```sql
ALTER TABLE public.provider_quotes
  ADD COLUMN IF NOT EXISTS pipeline_stage TEXT NOT NULL DEFAULT 'draft' CHECK (pipeline_stage IN (
    'draft', 'sent', 'viewed', 'negotiating', 'won', 'lost'
  )),
  ADD COLUMN IF NOT EXISTS lead_source TEXT,                  -- 'referral', 'google_ads', 'website', 'walkby', 'repeat_customer', 'other'
  ADD COLUMN IF NOT EXISTS lost_reason TEXT,
  ADD COLUMN IF NOT EXISTS won_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS lost_at TIMESTAMPTZ;

ALTER TABLE public.handyman_requests
  ADD COLUMN IF NOT EXISTS lead_source TEXT;

CREATE INDEX IF NOT EXISTS provider_quotes_pipeline_idx
  ON public.provider_quotes(workspace_id, pipeline_stage);
```

**Edge Function actions:**
- `move_quote_stage` — accepts `{ quoteId, toStage, reason? }`. Updates `pipeline_stage`. Stamps `won_at` / `lost_at`. Inserts audit message in the linked thread (if any).
- `set_lead_source` — accepts `{ quoteId | requestId, source }`. Sets column.

**SPA UI (`website/operations/src/screens/Quotes.tsx` — extend):**
Add a new layout toggle: List view (existing) vs **Kanban view**.
- 6 columns (Draft / Sent / Viewed / Negotiating / Won / Lost) with quote cards stacked
- Drag handle on each card; HTML5 drag-and-drop OR `react-dnd` (npm install)
- Drop into a new column → calls `move_quote_stage`. If "Lost," opens a reason modal: [Price too high / Went with someone else / Project cancelled / No response / Other]
- Top of page: pipeline summary tiles ($ in pipeline, win rate, AVG cycle time)

**Lead source UI:** new field on the create-quote / create-request flow. Dropdown with the 6 enum values + "Other (text)". Reports surface attribution in W4.

**Cross-app parity:** quote stage transitions write audit messages to the linked thread; homeowner iOS sees "Quote moved to Won" notification.

**Effort:** 120 min. **Demo value:** very high — the operator's daily focus surface.

---

## Wave W6 — Section 11 Cases (issue/complaint/warranty management)

**Why:** field work generates exceptions — "this leak came back," "warranty repair," "callback for the same issue." Cases are first-class objects separate from visits/quotes; they tie back to a customer + a triggering event + a resolution.

**Schema (`supabase/migrations/20261313_cases.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  case_number TEXT NOT NULL,                   -- auto-generated CC-2026-001 etc.
  case_type TEXT NOT NULL CHECK (case_type IN ('warranty', 'callback', 'complaint', 'damage_claim', 'billing_dispute', 'other')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'waiting_customer', 'resolved', 'closed', 'escalated')),
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'critical')),
  title TEXT NOT NULL,
  description TEXT,
  related_request_id UUID REFERENCES public.handyman_requests(id) ON DELETE SET NULL,
  related_quote_id UUID REFERENCES public.provider_quotes(id) ON DELETE SET NULL,
  related_invoice_id UUID REFERENCES public.provider_invoices(id) ON DELETE SET NULL,
  assigned_to_member_id UUID REFERENCES public.provider_workspace_members(id) ON DELETE SET NULL,
  resolution_notes TEXT,
  resolved_at TIMESTAMPTZ,
  created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, case_number)
);

CREATE TABLE IF NOT EXISTS public.provider_case_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID NOT NULL REFERENCES public.provider_cases(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL,
  sender_role TEXT NOT NULL CHECK (sender_role IN ('contractor', 'customer', 'system')),
  body TEXT NOT NULL,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS provider_cases_workspace_status_idx
  ON public.provider_cases(workspace_id, status);
CREATE INDEX IF NOT EXISTS provider_case_messages_case_idx
  ON public.provider_case_messages(case_id);

ALTER TABLE public.provider_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_case_messages ENABLE ROW LEVEL SECURITY;
-- Workspace member RW + customer RO via household_id
```

**Edge Function actions (handyman-provider):**
- `create_case` — accepts `{ workspaceId, householdId, caseType, title, description?, relatedRequestId?, relatedQuoteId?, priority? }`. Auto-generates `case_number`. Inserts row. Inserts initial system message.
- `update_case` — accepts `{ caseId, updates }`. Status / priority / assignee updates. Inserts audit message.
- `reply_case` — accepts `{ caseId, body, attachments? }`. Inserts message.
- `resolve_case` — accepts `{ caseId, resolutionNotes }`. Stamps `resolved_at`, status='resolved'.
- `close_case` — final transition; locks the case from further messages.

**SPA UI (new `website/operations/src/screens/Cases.tsx`):**
Sidebar adds "**Cases**" entry routing to `/cases`. Layout: 3-col (List 320 / Detail 1fr / Customer rail 320).
- List: filter chips (All / Open / In Progress / Waiting Customer / Resolved / Closed) + sort (Newest / Priority / Customer)
- Detail: header (case #, type pill, status pill, priority pill) + thread + composer + sidebar with related request/quote/invoice links + assign-to picker
- Customer rail: customer card + last 3 visits + 3 most recent quotes/invoices

**Cross-app parity:** cases create a `chez_requests`-style thread on the homeowner iOS — the homeowner sees the case in their inbox + can reply. Resolution closes the loop.

**Effort:** 150 min. **Demo value:** high — service quality / warranty story.

---

## Wave W7 — Section 5 Systems aggregate (workspace-wide systems list + service intervals)

**Why:** the operator wants "show me every boiler we service across all customers" or "who's overdue on annual furnace service?" — system-centric workforce planning.

**Schema:** none new. Pulls from `home_systems` joined to `households` joined to `provider_contractor_links` (workspace ↔ household).

**Edge Function actions:**
- `fetch_workspace_systems` — accepts `{ workspaceId, filters: { category?, status?, overdue?, search? } }`. Returns flat list of systems across all serviced households + last/next service date computed from `service_records`.
- `bulk_assign_systems_to_routine` — accepts `{ systemIds, routineId }`. Bulk-action for "schedule annual visits across these 47 boilers."

**SPA UI (extend `website/operations/src/screens/HomeDetail.tsx` Systems sub-tab + new top-level `Systems.tsx`):**
- Sidebar adds **"Systems"** entry routing to `/systems`
- Filters: category multi-select, status (active / decommissioned / needs follow-up), overdue toggle, free-text search
- Each row: home address (clickable into HomeDetail W3) + system category icon + brand/model + last serviced + next due (overdue rows render salmon background per Section 22 B1)
- Bulk select → "Schedule visits for selected" → quick-create routine

**Cross-app parity:** none direct.

**Effort:** 90 min. **Demo value:** medium-high.

---

## Wave W8 — Calendar + Routes operator depth (drag-reorder + optimize-route + send-route-to-tech SMS + territory map)

**Why:** the operator's daily dispatch surface. Calendar.tsx and Routes.tsx exist as fixture-backed shells — promote both to full operator depth.

**Schema (`supabase/migrations/20261314_routes_optimize.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  route_date DATE NOT NULL,
  stop_order UUID[] NOT NULL DEFAULT '{}',          -- array of provider_visit_assignments.id in driving order
  optimized_at TIMESTAMPTZ,
  total_drive_seconds INT,
  total_drive_miles NUMERIC(8,2),
  sent_to_tech_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, member_id, route_date)
);

CREATE TABLE IF NOT EXISTS public.provider_territories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  zip_codes TEXT[] NOT NULL DEFAULT '{}',
  assigned_member_ids UUID[] NOT NULL DEFAULT '{}',
  color TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.provider_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_territories ENABLE ROW LEVEL SECURITY;
-- Workspace RW
```

**Edge Function actions:**
- `optimize_route` — accepts `{ workspaceId, memberId, routeDate }`. Pulls assignments for date. Calls Mapbox Optimization API (or simpler: nearest-neighbor heuristic on lat/lng). Returns reordered array + total drive time/miles. Persists to `provider_routes`.
- `reorder_route_stop` — accepts `{ routeId, fromIndex, toIndex }`. Mutates `stop_order` array. (Drag-reorder client side, persist on drop.)
- `send_route_to_tech` — accepts `{ routeId }`. Looks up tech's phone from `provider_workspace_members.phone`. Sends SMS via Twilio (env `TWILIO_*`) with route summary + first 3 stops + "Open in Maps" link to multi-stop Google Maps URL.
- `bulk_assign_visits` — accepts `{ assignmentIds, memberId }`. Updates assignments in one batch.

**SPA UI:**
- **`Calendar.tsx`**: Day/Week/Month toggle promoted to functional. Drag visit cards across day cells (week/month). Colors per tech (territory-driven via W8). Tech filter chips at top.
- **`Routes.tsx`**: 3-col grid → per-tech route card. Drag handles on each stop → reorder. "Optimize route" button → calls optimize action → animation re-orders stops. "Send to tech" button → calls SMS action → toast "Route sent to Bob's phone."
- **Territory map** sub-screen: SVG rendering of territory polygons (or zip-code overlays from a public dataset). Assign techs to territories. Territory colors propagate to Calendar/Routes.
- **Mini-map per route card**: SVG with gradient bg + dashed indigo path + numbered salmon stop circles (already in fixtures; promote to real lat/lng path)

**Cross-app parity:** none direct (operator-side dispatch).

**Effort:** 150 min. **Demo value:** very high — daily operational beat.

---

## Wave W9 — Quote workflow depth (templates + duplicate + change orders + bundle send web + signature web)

**Why:** Wave V shipped basic save_quote_bundle / send_quote_bundle / decide_quote_bundle. Promote to full quote-workflow with templates, duplicate flow, change orders, and signature capture web-side.

**Schema (`supabase/migrations/20261315_quote_workflow.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_quote_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,                                   -- 'plumbing', 'electrical', etc.
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,   -- [{description, qty, unit_price_cents, type}]
  default_terms TEXT,
  use_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.provider_quote_change_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_quote_id UUID NOT NULL REFERENCES public.provider_quotes(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL,
  delta_line_items JSONB NOT NULL,                 -- additions/removals
  reason TEXT,
  total_delta_cents INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'approved', 'declined')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.provider_quotes
  ADD COLUMN IF NOT EXISTS signature_path TEXT,    -- mirrors mobile M4
  ADD COLUMN IF NOT EXISTS signed_name TEXT,
  ADD COLUMN IF NOT EXISTS signed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS recalled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS valid_until DATE;

ALTER TABLE public.provider_quote_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_quote_change_orders ENABLE ROW LEVEL SECURITY;
-- Workspace RW

INSERT INTO storage.buckets (id, name, public)
  VALUES ('quote-signatures', 'quote-signatures', false)
  ON CONFLICT (id) DO NOTHING;
```

**Edge Function actions:**
- `save_quote_template` — accepts `{ workspaceId, name, lineItems, ... }`.
- `apply_quote_template` — accepts `{ templateId, quoteId }`. Pre-fills the quote builder.
- `duplicate_quote` — already speced in Wave M13; web shares it.
- `recall_quote` — accepts `{ quoteId, reason }`. Sets `recalled_at`. Inserts audit message in homeowner thread.
- `create_change_order` — accepts `{ parentQuoteId, deltaLineItems, reason }`. Inserts row.
- `send_change_order` — sends to homeowner inbox like a quote bundle.
- `decide_change_order` — homeowner approves/declines.
- `sign_quote_web` — accepts `{ quoteId, signatureBase64, signedName }`. Uploads PNG to `quote-signatures` bucket. Stamps signature columns.
- `generate_quote_pdf` — server-side: renders the quote into a PDF (use `pdfkit` or `puppeteer`). Stores in `quote-pdfs` bucket. Returns signed URL.

**SPA UI (`website/operations/src/screens/Quotes.tsx` — extend):**
- **Quote builder** gains "Apply template" dropdown (lists workspace templates) + "Save as template" CTA after build
- **Duplicate quote** action in row hover menu
- **Change orders** sub-tab on the open quote detail: "+ Create change order" → modal builder → send → tracks status
- **Signature pad** on the operator-side quote view: HTML5 canvas with mouse + touch events. Uploads via `sign_quote_web`. Renders "Signed by [Name] on [Date]" once signed.
- **PDF preview** button → calls `generate_quote_pdf` → opens in new tab
- **Quote validity**: "Expires Jun 1" badge on sent quotes; auto-recall after expiry via cron job

**Cross-app parity:** signature path renders on homeowner iOS quote detail. Change orders surface as a separate proposal type in homeowner inbox.

**Effort:** 150 min. **Demo value:** very high — sales motion polish.

---

## Wave W10 — CRM depth (custom fields + segments + follow-up scheduler + retention scoring)

**Why:** the operator needs to slice + dice their customer list. "Show me everyone overdue on a roof inspection" or "high-value customers who haven't booked in 90 days."

**Schema (`supabase/migrations/20261316_crm_depth.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_custom_fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('household', 'visit', 'quote', 'invoice')),
  field_name TEXT NOT NULL,
  field_type TEXT NOT NULL CHECK (field_type IN ('text', 'number', 'date', 'checkbox', 'select')),
  options JSONB,                       -- for 'select' type
  required BOOLEAN NOT NULL DEFAULT false,
  display_order INT NOT NULL DEFAULT 0,
  UNIQUE (workspace_id, entity_type, field_name)
);

CREATE TABLE IF NOT EXISTS public.provider_custom_field_values (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  custom_field_id UUID NOT NULL REFERENCES public.provider_custom_fields(id) ON DELETE CASCADE,
  entity_id UUID NOT NULL,             -- household/visit/quote/invoice id
  value JSONB,
  UNIQUE (custom_field_id, entity_id)
);

CREATE TABLE IF NOT EXISTS public.provider_customer_segments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  filter_dsl JSONB NOT NULL,           -- e.g. {"all": [{"field": "lifetime_value_cents", "op": ">", "value": 500000}]}
  member_count INT NOT NULL DEFAULT 0,
  computed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.provider_follow_up_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  due_date DATE NOT NULL,
  assigned_to_member_id UUID REFERENCES public.provider_workspace_members(id) ON DELETE SET NULL,
  source TEXT,                        -- 'visit_completed', 'quote_sent', 'manual', 'segment_rule'
  source_ref UUID,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.provider_custom_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_custom_field_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_customer_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_follow_up_tasks ENABLE ROW LEVEL SECURITY;
-- Workspace RW
```

**Edge Function actions:**
- `define_custom_field` / `set_custom_field_value` / `compute_segment` / `create_follow_up_task` / `complete_follow_up_task` / `compute_retention_scores`.
- `compute_retention_scores`: nightly job. Per household: `score = (recency_score × 0.4) + (frequency_score × 0.3) + (monetary_score × 0.3)`. RFM model.

**SPA UI:**
- **Settings → Custom fields** sub-tab (extends W2): define per-entity fields, ordering, required toggle
- **HomeDetail Members tab + Custom fields rendered inline** on the customer rail
- **Segments**: new top-level Sidebar entry "Segments" → list view with filter builder UI (visual rule editor)
- **Follow-up scheduler**: bell icon on every customer card → "Schedule follow-up" → date + assignee → row in `provider_follow_up_tasks`. Surfaces on Today screen as "3 follow-ups due today."
- **Retention score** column on Homes list + per-customer card

**Cross-app parity:** none direct (operator-only).

**Effort:** 180 min. **Demo value:** medium-high — pro-grade CRM.

---

## Wave W11 — Section 15a Marketing (campaigns + lead source tracking + referral tracking + review automation)

**Why:** the growth motion. Operator runs Google Ads, asks for referrals, automates review-request texts post-visit.

**Schema (`supabase/migrations/20261317_marketing_campaigns.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_marketing_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  channel TEXT NOT NULL CHECK (channel IN ('google_ads', 'facebook_ads', 'mailer', 'door_hanger', 'referral', 'website', 'organic_search')),
  spend_cents INT NOT NULL DEFAULT 0,
  spend_period_start DATE,
  spend_period_end DATE,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.provider_referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  referrer_household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  referee_household_id UUID REFERENCES public.households(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'contacted', 'converted', 'rejected')),
  reward_offered_cents INT,
  reward_paid_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.provider_review_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  request_id UUID NOT NULL REFERENCES public.handyman_requests(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('sms', 'email')),
  sent_at TIMESTAMPTZ,
  rating_received INT CHECK (rating_received BETWEEN 1 AND 5),
  review_text TEXT,
  platform TEXT,                              -- 'google', 'yelp', 'facebook', 'internal'
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.provider_marketing_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_review_requests ENABLE ROW LEVEL SECURITY;
-- Workspace RW
```

**Edge Function actions:**
- `create_campaign` / `record_campaign_spend` / `attribute_lead`.
- `create_referral` / `convert_referral` / `pay_referral_reward`.
- `auto_send_review_request` — cron job 24h after `complete_visit`. Sends SMS via Twilio with workspace's review platform link.
- `record_review` — webhook (or manual) updating rating + text.

**SPA UI (new `website/operations/src/screens/Marketing.tsx`):**
Sidebar adds "**Marketing**" entry routing to `/marketing`. Layout: 4 sub-tabs:
- **Campaigns**: list + create + spend tracking + attribution panel ("This month: Google Ads spent $1,200 → 14 leads → 6 won → ROI 312%")
- **Referrals**: list with status pills + manual reward payment workflow
- **Reviews**: review-request log + aggregate (avg rating, response rate, platform breakdown)
- **Auto-send rules**: workspace-level toggle "Auto-send review request 24h after visit complete" + delay slider + template editor

**Cross-app parity:** review request SMS includes a deep-link back to the homeowner iOS app's review surface (or external review link).

**Effort:** 150 min. **Demo value:** high — growth + retention story.

---

## Wave W12 — Section 15c Inventory (parts catalog + stock tracking + vendor relationships + purchase orders)

**Why:** the operator manages parts inventory across the truck, the shop, and reorder thresholds. Supports the M2 + M12 mobile flows.

**Schema (`supabase/migrations/20261318_inventory.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  sku TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  unit TEXT NOT NULL DEFAULT 'each',
  unit_cost_cents INT,
  default_markup_pct NUMERIC(5,4),
  reorder_threshold INT,
  active BOOLEAN NOT NULL DEFAULT true,
  preferred_supplier_id UUID REFERENCES public.provider_suppliers(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, sku)
);

CREATE TABLE IF NOT EXISTS public.provider_suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  contact_name TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  account_number TEXT,
  payment_terms TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.provider_stock_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  part_id UUID NOT NULL REFERENCES public.provider_parts(id) ON DELETE CASCADE,
  location TEXT NOT NULL DEFAULT 'shop',           -- 'shop', 'truck-001', 'truck-002', etc.
  qty INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (part_id, location)
);

CREATE TABLE IF NOT EXISTS public.provider_purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  supplier_id UUID NOT NULL REFERENCES public.provider_suppliers(id) ON DELETE CASCADE,
  po_number TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'received', 'cancelled')),
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  subtotal_cents INT NOT NULL DEFAULT 0,
  total_cents INT NOT NULL DEFAULT 0,
  ordered_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  notes TEXT,
  UNIQUE (workspace_id, po_number)
);

ALTER TABLE public.provider_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_stock_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_purchase_orders ENABLE ROW LEVEL SECURITY;
-- Workspace RW
```

**Edge Function actions:**
- `create_part` / `update_part` / `bulk_import_parts_csv`
- `update_stock_level` / `transfer_stock` (shop → truck) / `consume_stock` (when punch item materials reference SKU)
- `create_supplier` / `create_purchase_order` / `send_purchase_order` / `receive_purchase_order`
- `low_stock_alert` — cron job; surfaces parts below reorder threshold

**SPA UI (new `website/operations/src/screens/Inventory.tsx`):**
Sidebar adds "**Inventory**" entry routing to `/inventory`. 4 sub-tabs:
- **Parts**: searchable table with stock columns per location, low-stock badge, "+ Add" CTA
- **Suppliers**: list + detail view with PO history
- **Purchase Orders**: list + builder + send + receive workflow
- **Locations**: shop + per-tech-truck inventory transfers

**Cross-app parity:** when a punch item references an SKU (M2 mobile materials capture), `consume_stock` decrements the tech's truck inventory. If below threshold, low-stock alert fires for operator.

**Effort:** 150 min. **Demo value:** medium — operational depth.

---

## Wave W13 — Section 12 Email integration (inbound parsing + drafts + templates + threading)

**Why:** customers send emails; the operator's email lives in a separate Gmail tab. Bring it into the Operations Desk so threads + customer context co-locate.

**Schema (`supabase/migrations/20261319_email_integration.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_email_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  household_id UUID REFERENCES public.households(id) ON DELETE SET NULL,
  subject TEXT NOT NULL,
  participant_emails TEXT[] NOT NULL DEFAULT '{}',
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  unread_count INT NOT NULL DEFAULT 0,
  archived_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.provider_email_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES public.provider_email_threads(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL,
  sender_email TEXT NOT NULL,
  sender_name TEXT,
  recipient_emails TEXT[] NOT NULL,
  subject TEXT NOT NULL,
  body_html TEXT,
  body_text TEXT,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound', 'draft')),
  message_id_external TEXT,
  in_reply_to_external TEXT,
  sent_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.provider_email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  body_html TEXT NOT NULL,
  category TEXT,                  -- 'quote_followup', 'visit_reminder', 'review_request', etc.
  use_count INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS provider_email_messages_thread_idx ON public.provider_email_messages(thread_id);
ALTER TABLE public.provider_email_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_email_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_email_templates ENABLE ROW LEVEL SECURITY;
-- Workspace RW
```

**Edge Function:** new `provider-email/index.ts`:
- `inbound_email_webhook` — SendGrid Inbound Parse hits this. Parses, classifies, finds household via sender email, creates/updates thread + message.
- `send_email` — accepts `{ threadId?, to, subject, bodyHtml, attachments? }`. Sends via SendGrid API. Stores outbound message.
- `save_draft` / `apply_template` / `archive_thread` / `mark_thread_read`.

**Inbound forwarding address:** Each workspace gets `<workspace_slug>@desk.alfred.getchez.com`. Configured in SendGrid Inbound Parse routing.

**SPA UI (extend `website/operations/src/screens/Messages.tsx`):**
Add a top-of-page sub-tab toggle: **In-app threads** (existing) vs **Email**. Email view: same 3-col layout — Inbox / Thread / Customer rail. Compose with rich-text editor (use `@tiptap/react`).

**Cross-app parity:** none direct — this is workspace's external email, separate from homeowner iOS in-app threads.

**Effort:** 180 min. **Demo value:** high — operational consolidation.

---

## Wave W14 — Visit suggestions operator-side (review/approve mobile-suggested follow-ups)

**Why:** mobile M8 ships end-of-visit suggestions. Operator needs a queue to review/approve/edit before they ship to homeowner.

**Schema:** none new. Reuses `maintenance_tasks.source = 'contractor_suggestion'` + a new column `suggestion_status`:
```sql
ALTER TABLE public.maintenance_tasks
  ADD COLUMN IF NOT EXISTS suggestion_status TEXT
    CHECK (suggestion_status IN ('pending', 'approved', 'edited', 'rejected', 'sent'));
```

**Edge Function actions:**
- `list_pending_suggestions` — workspace-scoped, all `source='contractor_suggestion'` AND `suggestion_status IN ('pending', 'edited')`.
- `approve_suggestion` — flips to 'approved', notifies homeowner.
- `edit_suggestion` — accepts new title/description, flips to 'edited'.
- `reject_suggestion` — flips to 'rejected', removes from homeowner-visible queue.

**SPA UI:** new screen `Suggestions.tsx` accessible from sidebar or as a sub-tab on the new HomeDetail Activity feed:
- List of pending suggestions per customer
- Edit-in-place / Approve / Reject buttons
- Bulk approve

**Cross-app parity:** approved suggestions surface on homeowner iOS Tasks tab.

**Effort:** 60 min. **Demo value:** medium — closes the M8 loop.

---

## Wave W15 — Post-visit review depth (operator review of tech work + customer rating capture + photos audit)

**Why:** the operator needs to QC every visit before it's billed — see all photos, materials, time, then approve/edit/contest.

**Schema:** none new. Reuses `provider_visit_assignments` + `handyman_punch_items` + W1 performance table.

**Edge Function actions:**
- `list_visits_for_review` — completed visits not yet operator-reviewed.
- `approve_visit_for_billing` — flips a `reviewed_for_billing_at` timestamp; unblocks invoice send.
- `flag_visit_for_followup` — operator can flag a visit for re-work without auto-creating a callback case.

**Schema column:**
```sql
ALTER TABLE public.provider_visit_assignments
  ADD COLUMN IF NOT EXISTS reviewed_for_billing_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reviewed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS billing_review_notes TEXT;
```

**SPA UI:** extend `VisitDetail.tsx` (new file `website/operations/src/screens/VisitDetail.tsx`):
- Top status bar: "Awaiting QC" / "Approved for billing" / "Flagged"
- Photos grid (from M2 punch capture)
- Materials with cost breakdown
- Per-item time stamps + total elapsed
- Customer rating (from W1 performance)
- Operator action bar: Approve / Flag / Edit punch items / Send invoice (chains to existing flow)
- "Internal QC notes" composer (separate from M6 tech notes)

**Cross-app parity:** customer-facing rating flow on homeowner iOS — post-visit "Rate your visit" prompt feeds into `provider_member_performance`.

**Effort:** 90 min. **Demo value:** high.

---

## Wave W16 — Visit list operator features (filter + sort + pagination + bulk actions)

**Why:** when a workspace has hundreds of visits per month, the list needs operator-grade table affordances.

**Schema:** none new.

**Edge Function actions:** existing `fetch_visits` extended to accept `{ filters: { status?, dateRange?, memberId?, customerSearch? }, sort, page, perPage }`. Returns paginated.

**SPA UI:** extend `Calendar.tsx` and a new top-level `Visits.tsx`:
- Sortable column headers (date, customer, tech, status, total)
- Filter bar with chips
- Bulk select → bulk actions (Reassign / Cancel / Mark complete / Send invoices)
- Pagination (20/50/100 per page)
- Saved views (per-user localStorage): "My open visits this week"

**Cross-app parity:** none direct.

**Effort:** 75 min. **Demo value:** medium-high.

---

## Wave W17 — System inventory authoring on web

**Why:** mobile M3 builds the camera-first system authoring flow. Web mirrors it for desk-side authoring (when the customer calls in details, when the operator imports from a doc upload, when correcting field errors).

**Schema:** none new (reuses `home_systems` + W3 decommission columns).

**Edge Function actions:** existing `create_home_system` / `update_home_system` / `decommission_system` / `mark_system_followup`.

**SPA UI:** add to HomeDetail W3 Systems sub-tab:
- "+ Add system" CTA → modal with full form (category, brand, model, serial, install date, warranty docs)
- "Bulk import from doc upload" → drag-drop manual PDF → existing `lookup-manual` Edge Function extracts brand/model/serial → preview + edit → save
- Each row inline-editable with hover-edit affordance
- Decommission action sheet
- Mark for follow-up toggle

**Cross-app parity:** writes to `home_systems` visible on homeowner iOS Property tab.

**Effort:** 75 min. **Demo value:** medium-high.

---

## Wave W18 — Recent threads fix + global search

**Why:** the Messages.tsx Inbox column is fixture-backed; promote to live data + add global search across all entities.

**Schema:** none. Optional: `pg_trgm` extension + GIN indexes for fuzzy search.

**Edge Function actions:**
- `list_recent_threads` — workspace-scoped, sorted by `last_message_at DESC`. Joins customer + last message preview + unread count.
- `global_search` — accepts `{ workspaceId, query }`. Searches across `households` (customer name + address), `provider_quotes` (customer + line item descriptions), `provider_invoices`, `handyman_requests`, `provider_cases`, `home_systems`. Returns categorized results.

**SPA UI:**
- `Messages.tsx` Inbox: replace fixture with real query
- Topbar global search input: opens dropdown with category headers (Customers / Quotes / Invoices / Visits / Cases / Systems) + top 5 results per category. Keyboard shortcut: ⌘K
- "View all results" → routes to `/search?q=...` with full results

**Cross-app parity:** none direct.

**Effort:** 90 min. **Demo value:** high — table-stakes search.

---

## Wave W19 — Calendar/Maps integrations (Google Calendar OAuth + route optimization API + 2-way sync)

**Why:** the operator wants their workspace calendar synced with Google Calendar so jobs appear there + their phone calendar.

**Schema (`supabase/migrations/20261320_calendar_integrations.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_calendar_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  member_id UUID REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('google', 'outlook', 'apple')),
  refresh_token_encrypted TEXT NOT NULL,
  access_token_encrypted TEXT,
  expires_at TIMESTAMPTZ,
  external_calendar_id TEXT NOT NULL,
  sync_direction TEXT NOT NULL DEFAULT 'two_way' CHECK (sync_direction IN ('two_way', 'push_only', 'pull_only')),
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.provider_calendar_event_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_id UUID NOT NULL REFERENCES public.provider_calendar_integrations(id) ON DELETE CASCADE,
  visit_assignment_id UUID NOT NULL REFERENCES public.provider_visit_assignments(id) ON DELETE CASCADE,
  external_event_id TEXT NOT NULL,
  last_synced_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (integration_id, visit_assignment_id)
);
```

**Edge Function:** new `provider-calendar-sync/index.ts`:
- `oauth_start` / `oauth_callback` — Google Calendar OAuth flow
- `sync_visit_to_calendar` — push a visit to Google Calendar
- `sync_calendar_to_visits` — pull external events
- `nightly_sync_cron` — 15-min interval re-sync

**SPA UI:** Settings → "Integrations" sub-tab:
- "Connect Google Calendar" CTA → opens OAuth in new tab → callback writes refresh token (encrypted with workspace secret)
- Per-tech connection (each tech connects their own calendar)
- Sync direction toggle
- Last-synced timestamp

**Cross-app parity:** the homeowner iOS already has a calendar sync feature for family events; this is a separate operator-only flow.

**Effort:** 180 min. **Demo value:** high.

---

## Wave W20 — Quote signature capture web (mirror of mobile M4)

**Why:** when the operator presents a quote on a tablet at the customer's kitchen table or remotely on a Zoom screen-share, they need the signature pad on the web side too.

**Schema:** already shipped in W9. Reuse `signature_path` + `signed_name` + `signed_at` columns.

**Edge Function actions:** existing `sign_quote_web` from W9.

**SPA UI:** open quote detail → "Have customer sign here" → full-screen signature pad with mouse + touch/pointer events. After capture: name input + Save → uploads to `quote-signatures` bucket → renders "Signed by [Name] on [Date]".

**Cross-app parity:** signed quotes appear on homeowner iOS quote detail with the signature image rendered + the signed-name caption.

**Effort:** 45 min (W9 already lays the groundwork). **Demo value:** high.

---

## Cross-app waves (B series — touches both mobile + web)

These are not strictly "web" or "mobile" — they ship features that require coordinated changes on both surfaces. Run them between mobile + web waves.

---

## Wave B1 — Pre-visit prep checklist (chez_profile + previous-visit notes)

**Why:** the field tech needs a "what to know before you walk in" briefing — chez_profile standing instructions + last visit's notes + open punch items + safety flags.

**Schema:** none new (reuses `households.chez_profile` + previous visit data).

**Edge Function actions:**
- `fetch_visit_prep` — accepts `{ workspaceId, visitAssignmentId }`. Returns: customer chez_profile (logistics, vendor preferences, communication, spending tiers), last visit's tech notes, open punch items count, last 3 messages, any case links, system-level safety flags (e.g. "respirator required for furnace room").

**SPA UI:**
- Mobile (`handyman-visit.html`): pre-visit prep card on Today screen for each upcoming stop. "Show prep" expand → renders structured info.
- Web (`VisitDetail.tsx`): collapsible "Prep" section at the top of the visit detail.

**Cross-app parity:** mobile + web read same data; mobile prioritizes brevity, web shows full structured.

**Effort:** 75 min. **Demo value:** very high — "premium ops" voice.

---

## Wave B2 — chez_profile auto-summary on visit detail

**Why:** Tom-the-operator already maintains chez_profile on the homeowner side; surface it on every contractor surface that needs it.

**Schema:** none new.

**Edge Function actions:** extend `fetch_visit_prep` from B1.

**SPA UI:**
- Mobile: bottom-sheet "Customer notes" pull-up on visit detail with chez_profile summary
- Web: customer rail on Cases / Quotes / Visits all render chez_profile preferences as a structured pill list ("Pets: 2 dogs · Entry: side gate code 1234 · Vendor preference: prefer-local · Spending: auto-approve under $200")

**Cross-app parity:** all surfaces read same source; updates from homeowner iOS or admin portal propagate.

**Effort:** 60 min. **Demo value:** high.

---

## Wave B3 — chez-owned banner + customers list

**Why:** when a household has flipped routines/contractors/tasks to "Chez-owned" (Phase 80.1/80.2 toggles), the contractor company doing the work for Chez should see "This is a Chez-managed customer" banner so they communicate appropriately.

**Schema:** none new (reuses `routines.chez_owned`, `contractors.chez_owned`, `maintenance_tasks.chez_owned`).

**Edge Function actions:**
- `is_chez_managed_household` — returns aggregate signal: any chez_owned routine/contractor/task on this household.

**SPA UI:**
- Mobile: salmon-thin banner above customer card on visit detail: "Chez-managed customer — coordinate scheduling via Chez admin"
- Web: same banner on Homes list rows + HomeDetail header
- Customers list new filter chip: "Chez-managed only"

**Cross-app parity:** read-only — the actual chez_owned writes happen on homeowner iOS.

**Effort:** 45 min. **Demo value:** medium-high — premium-tier signaling.

---

## Wave B4 — Read receipts + typing indicator (cross-thread)

**Why:** the in-app threads (`handyman_request_messages`) lack read receipts and typing indicators — table stakes for chat UX.

**Schema (`supabase/migrations/20261321_message_presence.sql`):**
```sql
ALTER TABLE public.handyman_request_messages
  ADD COLUMN IF NOT EXISTS read_by_recipients_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS read_by_recipient_ids JSONB NOT NULL DEFAULT '[]'::jsonb;

CREATE TABLE IF NOT EXISTS public.handyman_request_typing (
  request_id UUID NOT NULL REFERENCES public.handyman_requests(id) ON DELETE CASCADE,
  actor_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  actor_role TEXT NOT NULL CHECK (actor_role IN ('contractor', 'customer', 'chez')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (request_id, actor_user_id)
);
ALTER TABLE public.handyman_request_typing ENABLE ROW LEVEL SECURITY;
-- Same RLS as messages
```

**Edge Function actions:**
- `mark_thread_read` — accepts `{ requestId }`. Stamps `read_by_recipients_at` + appends caller's user_id.
- `set_typing` — upserts row in `handyman_request_typing`. TTL 30 sec via cron cleanup.

**SPA UI (mobile + web):**
- Read receipts: subtle "Seen 2:14pm" caption below sent messages
- Typing indicator: "[Customer] is typing..." pulse below the thread, fed by Supabase Realtime channel on `handyman_request_typing`

**Cross-app parity:** homeowner iOS subscribes to same channel for typing; sees same read receipts.

**Effort:** 90 min. **Demo value:** medium — chat polish.

---

## Wave B5 — Message archive + search

**Why:** with hundreds of threads per workspace, "where did that conversation about the burst pipe go?" becomes a real problem.

**Schema:** add GIN index on `handyman_request_messages.body` for trigram fuzzy search:
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS handyman_request_messages_body_trgm_idx
  ON public.handyman_request_messages USING gin (body gin_trgm_ops);

ALTER TABLE public.handyman_requests
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;
```

**Edge Function actions:**
- `search_messages` — accepts `{ workspaceId, query, dateRange?, customerFilter? }`. Returns thread + matching message snippets with `<mark>` highlights.
- `archive_thread` — stamps `archived_at`. Hides from default list. Restorable.

**SPA UI:**
- Web: Messages.tsx top bar gains search input + filter chips + "Archived" toggle
- Mobile: search icon in top-right of inbox view

**Cross-app parity:** archive flag respected on homeowner iOS too.

**Effort:** 60 min. **Demo value:** medium-high.

---

## Wave B6 — Alfred reply suggestions (cross-thread)

**Why:** the Operations Desk Concierge cockpit (admin portal) already has Alfred suggestion via `ask_alfred` action. Bring same intelligence to the workspace's contractor↔homeowner threads — quick "Suggest reply" button.

**Schema:** none.

**Edge Function:** new action on `handyman-provider`:
- `suggest_thread_reply` — accepts `{ requestId, tone?: 'warm'|'direct'|'formal' }`. Loads thread + customer chez_profile + visit context. Asks Claude sonnet 4.6 to draft 3 reply variants. Returns `{ suggestions: [{ tone, body }] }`.

**SPA UI:**
- Mobile + Web: "✨ Suggest reply" button next to thread composer. Tap → bottom sheet with 3 variants → tap to insert into composer.

**Cross-app parity:** none direct — this is operator-only.

**Effort:** 60 min. **Demo value:** medium-high — Alfred parity.

---

## Wave B7 — Schema cleanups (chez_admin source CHECK + metadata column on more tables + sender_role chez)

**Why:** during overnight pass, several edge cases revealed silent constraint failures (Phase 80 admin sender_role missing, `metadata` column missing on `provider_visit_assignments`, etc.). Bundle the cleanups.

**Schema (`supabase/migrations/20261322_schema_cleanups.sql`):**
```sql
-- 1. Add 'chez' as valid sender_role + actor_role across messaging tables
ALTER TABLE public.handyman_request_messages
  DROP CONSTRAINT IF EXISTS handyman_request_messages_sender_role_check;
ALTER TABLE public.handyman_request_messages
  ADD CONSTRAINT handyman_request_messages_sender_role_check
    CHECK (sender_role IN ('contractor', 'customer', 'system', 'chez'));

-- 2. Ensure metadata column on every dispatch table (for arbitrary audit info)
ALTER TABLE public.provider_visit_assignments
  ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.provider_quotes
  ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.provider_invoices
  ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

-- 3. Add 'chez_admin' as valid source on punch items + maintenance_tasks (for items injected by Chez admin on behalf of homeowner)
ALTER TABLE public.handyman_punch_items
  DROP CONSTRAINT IF EXISTS handyman_punch_items_source_check;
ALTER TABLE public.handyman_punch_items
  ADD CONSTRAINT handyman_punch_items_source_check
    CHECK (source IN ('manual', 'recommended', 'maintenance_task', 'auto_seed_handyman_tier',
                       'promoted_from_task', 'migrated_from_task', 'chez_admin'));

ALTER TABLE public.maintenance_tasks
  ADD COLUMN IF NOT EXISTS source TEXT;
```

**Edge Function:** none changed (cleanups unblock previously-failing inserts).

**SPA UI:** none direct — surfaces enabled by these cleanups depend on other waves.

**Cross-app parity:** unblocks Wave M8 contractor_suggestion writes; unblocks Phase 80 chez admin reply path.

**Effort:** 30 min. **Demo value:** low directly, foundational for everything else.

---

## Wave order + dependencies

```
W2 (settings depth)              ← foundation; logo + tax + markup feed quotes/invoices everywhere
W3 (HomeDetail subtabs)           ← foundation; primary operator surface
B7 (schema cleanups)              ← foundation; unblocks several actions

W1 (crew admin)                   ← independent; depends on M1 clock-in for timesheet data
W4 (reporting)                    ← needs W1 + W2 + W3 data
W5 (pipeline kanban)              ← needs W3 (drilldown into quote detail)
W6 (cases)                        ← independent
W7 (systems aggregate)            ← needs W3 (HomeDetail Systems sub-tab uses same data)
W8 (calendar+routes operator)     ← independent; depends on M1 for clock-in data
W9 (quote workflow depth)         ← needs W2 (tax/markup) + W3 (quote drilldown)
W10 (CRM depth)                   ← needs W3 (Custom fields + retention render in HomeDetail)
W11 (marketing)                   ← needs W4 (attribution surface) + W5 (lead source on quotes)
W12 (inventory)                   ← independent; ties into M2 materials capture
W13 (email integration)           ← independent
W14 (visit suggestions operator)  ← needs M8 mobile suggestion writes
W15 (post-visit review)           ← needs M1 + M2 capture data
W16 (visit list features)         ← independent
W17 (system authoring web)        ← needs W3 (HomeDetail Systems sub-tab)
W18 (recent threads + global search) ← independent
W19 (calendar/maps integrations)  ← needs W8 (route data to push to external)
W20 (quote signature web)         ← needs W9 (signature_path schema)

B1 (pre-visit prep)               ← needs W3 (web prep section) + mobile equivalent
B2 (chez_profile auto-summary)    ← needs B1
B3 (chez-owned banner)            ← independent
B4 (read receipts + typing)       ← independent
B5 (message archive + search)     ← independent
B6 (Alfred reply suggestions)     ← independent
```

**Recommended ordering across overnight passes:**

**Pass 1 (8h):** B7 → W2 → W3 → W18 (foundation: schema cleanup, settings, primary surface, search/threads)

**Pass 2 (8h):** W1 → W5 → W8 → W9 (operator daily beat: crew, pipeline, dispatch, quotes)

**Pass 3 (8h):** W4 → W6 → W10 → W14 → W15 (analytics, cases, CRM, suggestion review, visit QC)

**Pass 4 (6h):** W7 → W11 → W12 → W16 → W17 → W20 (systems aggregate, marketing, inventory, list features, web authoring, signature)

**Pass 5 (5h):** W13 → W19 → B1 → B2 → B3 (email, calendar integration, prep checklist, profile summary, banner)

**Pass 6 (4h):** B4 → B5 → B6 (chat polish, search, Alfred suggestions)

---

## Per-wave subagent invocation template

In a fresh chat:

```
Read /Users/tomburke/Documents/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8/Tests/e2e/CONTRACTOR_WEB_BUILDOUT_PLAN.md

Execute Wave W{N} (or B{N}) via a general-purpose subagent. Use the wave's spec verbatim from the plan doc.

Each subagent:
1. Reads /tmp/ui-test/CONTRACTOR_SETUP.md first
2. Sign in as the appropriate test user (W2 crew6 for crew flows; W1 solo for sole-mode flows)
3. Resizes Chrome to 1440×900 (with 1280×800 spot-check)
4. Loads localhost:5173/operations/ via Vite (and localhost:8000/handyman.html for auth round-trip)
5. Implements the schema migration (if any) + edge fn actions + SPA UI per the plan
6. Verifies the new flow works at 1440×900 viewport (1-3 screenshots)
7. Cross-app DB cross-check via service-role JWT
8. Commits + pushes to the default branch (claude/setup-monorepo-structure-...)
9. Returns the standard JSON block (Section 27 of the matrix)
10. Confirms Vercel deploy of the SPA + Supabase deploy of the edge fn

Time-box: per the wave's stated effort + 25% buffer. If the wave is too large, scope to a viable skeleton + log the deferred portions in CONTRACTOR_GAPS.md.
```

---

## Schema migrations introduced by this plan

1. `20261309_crew_admin.sql` — Wave W1
2. `20261310_workspace_settings_depth.sql` — Wave W2
3. `20261311_reporting_views.sql` — Wave W4
4. `20261312_pipeline_stages.sql` — Wave W5
5. `20261313_cases.sql` — Wave W6
6. `20261314_routes_optimize.sql` — Wave W8
7. `20261315_quote_workflow.sql` — Wave W9
8. `20261316_crm_depth.sql` — Wave W10
9. `20261317_marketing_campaigns.sql` — Wave W11
10. `20261318_inventory.sql` — Wave W12
11. `20261319_email_integration.sql` — Wave W13
12. `20261320_calendar_integrations.sql` — Wave W19
13. `20261321_message_presence.sql` — Wave B4
14. `20261322_schema_cleanups.sql` — Wave B7
15. (W15 + W14 + W7 each add a single column inline — no separate migration file)

Plus a shared visit-billing-review column added inline in W15.

All additive. Apply via `supabase db push --linked`.

---

## Storage buckets introduced

1. `workspace-branding` — Wave W2 (logos)
2. `crew-certifications` — Wave W1
3. `quote-signatures` — Wave W9 (shared with mobile M4)
4. `quote-pdfs` — Wave W9 (server-rendered PDFs)

All private; per-workspace-scoped RLS.

---

## NPM dependencies introduced

`recharts` (W4 — charts), `react-dnd` + `react-dnd-html5-backend` (W5 — Kanban drag), `@tiptap/react` + `@tiptap/starter-kit` (W13 — email rich-text), `@mapbox/mapbox-sdk` or fallback to OpenStreetMap (W8/W19 — route optimize + maps).

---

## Edge Function deploys per wave

Most waves extend `handyman-provider/index.ts`. New edge functions introduced:
- `provider-email/index.ts` — Wave W13
- `provider-calendar-sync/index.ts` — Wave W19

Each wave deploys via:
```bash
cd /Users/tomburke/Documents/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8
supabase functions deploy handyman-provider --no-verify-jwt
# or for new fns:
supabase functions deploy provider-email --no-verify-jwt
supabase functions deploy provider-calendar-sync --no-verify-jwt
```

---

## Quality discipline (Section 22 — applies to every wave)

- A1 save → reload persistence
- A3 DB cross-check via service-role JWT
- B1 salmon discipline (only primary CTA / active queue case accent / SLA pills / fit-meter success / homeowner-panel highlighted system row)
- B3 no em dashes in user-facing copy
- B4 no "handyman" in user-facing copy (rebrand to "Chez Contractor" / trade-specific)
- B6 click targets ≥ 44px on every primary CTA
- B9 empty / loading / error / populated states for every async surface
- C1 empty submit on every form fires validation visibly
- C7 network failure mid-save → clear error + retry
- D1 skeleton loaders, never spinners on blank screens
- D2 nav active state visible (left rail)
- D7 white-space discipline — no white-on-white, no overlapping text, no clipped descenders

---

## Output format per wave

End every subagent invocation with:

```json
{
  "wave": "W{N} or B{N}",
  "title": "...",
  "result": "PASS | PARTIAL | FAIL",
  "actions_summary": "...",
  "files_changed": [...],
  "schema_migrations": [...],
  "edge_function_deploys": [...],
  "npm_deps_added": [...],
  "screenshots": [...],
  "cross_app_parity_verified": true | false,
  "deferred_to_next_wave": [...],
  "commit_hash": "..."
}
```

---

## Closing — what this plan delivers

After running all 20 web waves + 7 cross-app waves, the Operations Desk SPA covers every Section 22 desktop concern + every web-side gap from the overnight E2E findings:

- ✅ Crew admin (timesheets, certifications, performance) — W1
- ✅ Workspace settings depth (branding, hours, service area, tax, markup, payment, terms) — W2
- ✅ HomeDetail 12-subtab promotion — W3
- ✅ Reporting & analytics (revenue, jobs, utilization, marketing) — W4
- ✅ Pipeline Kanban with drag-and-drop + lead source attribution — W5
- ✅ Case management (warranty, callback, complaint, billing dispute) — W6
- ✅ Workspace-wide systems aggregate — W7
- ✅ Calendar + routes operator depth (drag, optimize, send-to-tech) — W8
- ✅ Quote workflow depth (templates, duplicate, change orders, signature, PDF) — W9
- ✅ CRM depth (custom fields, segments, follow-up scheduler, retention) — W10
- ✅ Marketing (campaigns, referrals, reviews) — W11
- ✅ Inventory (parts, suppliers, POs, stock levels) — W12
- ✅ Email integration (inbound parsing, drafts, templates) — W13
- ✅ Visit suggestions operator-side QC — W14
- ✅ Post-visit billing review — W15
- ✅ Visit list operator features (filter, sort, paginate, bulk) — W16
- ✅ System authoring on web — W17
- ✅ Recent threads + global search — W18
- ✅ Calendar/maps integrations (Google Calendar OAuth) — W19
- ✅ Quote signature on web — W20
- ✅ Pre-visit prep + chez_profile summary + chez-owned banner — B1/B2/B3
- ✅ Read receipts + typing — B4
- ✅ Message archive + search — B5
- ✅ Alfred reply suggestions on threads — B6
- ✅ Schema cleanups (chez sender_role, metadata columns, source values) — B7

Cross-app parity verified after every wave. Brand voice + salmon discipline + em-dash discipline maintained throughout.

The Operations Desk SPA goes from "demo-grade dispatch shell" to "enterprise-grade pro-services back office."
