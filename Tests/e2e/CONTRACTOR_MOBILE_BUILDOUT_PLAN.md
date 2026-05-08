# Chez Field PWA (mobile contractor) — full buildout plan

Comprehensive plan covering EVERY mobile-side gap identified during the overnight E2E pass. 13 waves of work organized so a future chat session can drop in and execute one wave at a time via subagent dispatch.

The PWA lives at `website/handyman-visit.html` (vanilla HTML/CSS/JS + service worker; ~2,760 lines total). It loads via `?token=<portal_token>` per visit, talks to the `handyman-portal` Edge Function, persists drafts to `localStorage`, and registers a service worker for offline.

This is a **complete spec** — no "skip this" gates. Each wave is dispatched independently. The final state ships every Section 22 mobile concern + the full Section 5/6/7/9/10 mobile parity story.

---

## Pre-flight (every subagent)

1. Read `/tmp/ui-test/CONTRACTOR_SETUP.md` (env, fixtures, JWT, test users)
2. `mcp__Claude_in_Chrome__list_connected_browsers` returns ≥ 1
3. Resize Chrome to **390×844** (iPhone 14 Pro mobile viewport)
4. Load `http://localhost:8000/handyman-visit.html?demo=1` (use port 8000 for Service Worker registration; `5173/handyman-visit.html` works for non-SW work)
5. Initial discipline check: `Text()`-style `handyman` + em-dash count = 0

After implementation:
- `cd /Users/tomburke/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8` and verify TS clean (no `tsc` for vanilla JS but check no console errors)
- Deploy edge function: `supabase functions deploy handyman-portal --no-verify-jwt` (or `handyman-provider` if reusing)
- Apply migration: `supabase db push --linked` if a migration shipped
- Take 1–3 screenshots in 390×844 viewport
- Cross-app DB cross-check via service-role JWT
- Commit + push to `claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG` (default branch — Vercel auto-deploys on push)

---

## Wave M1 — Visit lifecycle (clock-in/out + GPS + pause/resume)

**Why:** the field tech's accountability story — "show up at 9, leave at 11, here's the elapsed time + GPS proof." Drives operator billing accuracy and detects "I was on-site for 90 min" disputes.

**Schema (`supabase/migrations/20261301_visit_lifecycle.sql`):**
```sql
ALTER TABLE public.provider_visit_assignments
  ADD COLUMN IF NOT EXISTS clock_in_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS clock_out_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS paused_seconds INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS clock_in_lat NUMERIC(9,6),
  ADD COLUMN IF NOT EXISTS clock_in_lng NUMERIC(9,6),
  ADD COLUMN IF NOT EXISTS clock_in_accuracy_m INT;

CREATE TABLE IF NOT EXISTS public.provider_visit_pauses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  assignment_id UUID NOT NULL REFERENCES public.provider_visit_assignments(id) ON DELETE CASCADE,
  paused_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resumed_at TIMESTAMPTZ,
  reason TEXT,
  created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS provider_visit_pauses_assignment_idx ON public.provider_visit_pauses(assignment_id);
ALTER TABLE public.provider_visit_pauses ENABLE ROW LEVEL SECURITY;
-- Same RLS pattern as provider_visit_assignments — workspace members SELECT/INSERT/UPDATE.
```

**Edge Function actions (handyman-provider):**
- `start_visit` — accepts `{ requestId, latitude?, longitude?, accuracy? }`. Stamps `clock_in_at = now()` + GPS coords on the matching assignment row. Flips `handyman_requests.status` from `confirmed`/`scheduled` to `in_progress`. Inserts a `handyman_request_messages` audit row with `metadata.kind='status_change', status='in_progress', body='Visit started.'`
- `pause_visit` — accepts `{ requestId, reason }`. Inserts a `provider_visit_pauses` row with `paused_at = now()`. NO status change.
- `resume_visit` — accepts `{ requestId }`. Updates the open `provider_visit_pauses` row (where `resumed_at IS NULL`) with `resumed_at = now()`. Adds the elapsed seconds to the assignment's `paused_seconds`.
- `complete_visit` — extends existing `update_request_status` with `clock_out_at = now()` when transitioning to `completed`. Compute total = `clock_out_at - clock_in_at - paused_seconds`.

**SPA UI (`website/handyman-visit.html` + `handyman-visit.js`):**
- "Start visit" CTA on hero (currently a checkin placeholder). On tap:
  - First run: request `navigator.geolocation.getCurrentPosition()` permission
  - Call `start_visit` action with coords
  - UI flips to "elapsed clock" state with running mm:ss counter
- Elapsed-time card: H:MM:SS counter + "Pause" + "Complete" buttons
- Pause modal: reason picker [Lunch / Customer answered for different reason / Issue / Other (free text)] + Confirm
- Resume button replaces Pause when paused
- Complete extends existing complete flow — surfaces total elapsed before send

**Cross-app parity:** the contractor desk's `VisitDetail.tsx` header gets a "TIME ON-SITE: 1h 23m" stat next to the existing time window. GPS pin renders on the address line as a "verified arrival" indicator.

**Effort:** 90 min. **Demo value:** very high — operational accountability.

---

## Wave M2 — Punch list capture depth (photos + voice + materials + per-item timing)

**Why:** the "AI creates intelligence" moat — every punch item becomes evidence-rich, billable, auditable.

**Schema (`supabase/migrations/20261302_punch_capture_depth.sql`):**
```sql
ALTER TABLE public.handyman_punch_items
  ADD COLUMN IF NOT EXISTS attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS materials_used JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS time_spent_seconds INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS voice_note_path TEXT;

-- Storage bucket
INSERT INTO storage.buckets (id, name, public)
  VALUES ('punch-item-attachments', 'punch-item-attachments', false)
  ON CONFLICT (id) DO NOTHING;

-- RLS: workspace members read attachments for items in their workspace
-- (mirror existing punch-items policies)
```

**Edge Function actions:**
- `attach_punch_photo` — accepts `{ itemId, base64, contentType, caption? }`. Resizes to 1600px max edge JPEG, uploads to bucket as `<household_id>/<item_id>/<random>.jpg`, returns signed URL. Appends `{ kind: 'photo', path, signedUrl, caption, uploadedAt }` to attachments array.
- `attach_punch_voice` — accepts `{ itemId, base64, mimeType }`. Uploads m4a/aac. Sets `voice_note_path`.
- `set_punch_materials` — accepts `{ itemId, materials: [{ sku?, name, qty, unit_cost }] }`. Replaces array.
- `set_punch_time_spent` — accepts `{ itemId, seconds }`. Sets column.

**SPA UI:**
- Each punch item row gains a horizontal action bar: 📷 / 🎤 / 📦 / ⏱
- 📷 → `<input type="file" accept="image/*" capture="environment">` → canvas resize → base64 → upload action
- 🎤 → `MediaRecorder` API → record button → playback inline → upload on stop. Service worker pre-caches a recorder polyfill for offline-capable recording.
- 📦 → modal with materials list (typed in or picked from inventory if W12 has shipped) + qty + unit_cost + Save
- ⏱ → toggle timer; running state shows mm:ss next to the item title; tap again to stop + save

Photos render as 80×80px thumbnails in a horizontal scroll under each item. Tap → lightbox. Long-press → "Delete photo".

**Cross-app parity:** the contractor desk's `VisitDetail.tsx` post-visit review section (Section 6.34) renders the same attachments grid + voice playback + materials list with cost + per-item time.

**Effort:** 120 min. **Demo value:** very high.

---

## Wave M3 — System inventory authoring (bulk-add + photo→AI + decommission + gap-fill + voice notes)

**Why:** the most-used UX during an assessment visit. The field tech walks the home, captures every system in <30 seconds via camera-first UX, and the homeowner's iOS app reflects everything when the assessment closes.

**Schema (`supabase/migrations/20261303_home_system_decommission.sql`):**
```sql
ALTER TABLE public.home_systems
  ADD COLUMN IF NOT EXISTS decommissioned_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS decommission_reason TEXT,
  ADD COLUMN IF NOT EXISTS marked_for_followup_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS followup_reason TEXT,
  ADD COLUMN IF NOT EXISTS voice_note_path TEXT;
```

**Edge Function actions:**
- Existing `identify-equipment` already handles photo→AI brand/model/serial extraction. Reuse.
- `decommission_system` — accepts `{ systemId, reason }`. Sets `decommissioned_at = now()`, `decommission_reason`, `status = 'decommissioned'`.
- `mark_system_followup` — accepts `{ systemId, reason }`. Sets `marked_for_followup_at`, `followup_reason`. Surfaces on next visit's prep checklist.
- `attach_system_voice` — uploads m4a, sets `voice_note_path`.

**SPA UI:**
- New "**System sweep mode**" full-screen flow (entry from visit detail "+ Add system" CTA):
  - Camera-first: tap "+" → camera opens → snap model plate → AI extracts brand/model/serial → confirmation card → save → camera reopens for next
  - Bulk-add session counter at top: "5 systems added in this visit"
- **"Incomplete systems" gap-fill list**: every `home_systems` row where brand/model/serial is null, sorted by category. Tap → camera opens → extract → save.
- **Decommission flow**: long-press existing system → action sheet → "Mark as removed" → reason picker (Replaced / Removed / Damaged beyond repair / Other) → save.
- **Mark for follow-up**: toggle on the system detail sheet. "Couldn't access this visit." Prompts for reason.
- **Voice notes**: 🎤 button on each system row. Same MediaRecorder pattern as M2.

**Cross-app parity:** every system add/edit/decommission writes to `home_systems` and is visible on:
- Contractor SPA `HomeDetail.tsx` (Customer 7 systems list)
- Homeowner iOS `Property` tab → systems
- Homeowner iOS dashboard if any new system has follow-up flag

**Effort:** 120 min. **Demo value:** very high — the moat.

---

## Wave M4 — In-person quote (kitchen-table close)

**Why:** field tech sits down with the customer, builds a quote on the spot from the punch list, presents 3 tiers (good/better/best), customer signs with finger, quote sent + DB row created.

**Edge Function:** `save_quote_bundle` + `send_quote_bundle` already exist (Wave V). Add:
- `sign_quote` — accepts `{ quoteId, signatureBase64, signedName, signerRole: 'homeowner'|'witness' }`. Saves PNG to a new `quote-signatures` bucket. Stamps `signed_at`, `signed_name`, `signature_path` on `provider_quotes`.

**Schema (`supabase/migrations/20261304_quote_signature.sql`):**
```sql
ALTER TABLE public.provider_quotes
  ADD COLUMN IF NOT EXISTS signature_path TEXT;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('quote-signatures', 'quote-signatures', false)
  ON CONFLICT (id) DO NOTHING;
```

**SPA UI:**
- New "**Build quote**" full-screen sheet from visit detail
- Pre-fills with completed punch list items as draft line items + materials → unit_cost. Editable.
- Multi-tier toggle: "+ Add good / better / best options" — same UX as Web Wave V
- Photo attach per line item (reuses M2 photo upload)
- Customer block pre-filled from visit's household
- "Send" button → calls `send_quote_bundle`
- "**Have customer sign here**" full-screen signature pad:
  - HTML5 `<canvas>` with touch + pointer events
  - Capture as PNG (`canvas.toDataURL`)
  - Upload to `quote-signatures` bucket via `sign_quote` action
  - Save signedName from a name input
  - Visual: "Signed by [Name] on [Date] — ✓"

**Cross-app parity:** quote lands as `provider_quotes` row visible on Operations Desk web + as inbox row on homeowner iOS (Wave Y2 path). Signature path → renders on contractor's web Quote Detail under "Signed by [Name]".

**Effort:** 120 min. **Demo value:** very high.

---

## Wave M5 — On-site invoice (visit → invoice in one tap)

**Why:** end of visit, tap to convert completed punch list + materials into an invoice. Customer pays right there OR receives email immediately.

**Edge Function:** `save_invoice` + `send_invoice` already exist (Wave Q). Add:
- `convert_visit_to_invoice` — accepts `{ requestId }`. Pulls all completed punch items + their materials, builds a draft invoice with line items: each completed punch item becomes "Labor: <title> (<minutes> min × $<rate>) + Materials: <qty>×<sku> @ $<unit>". Returns the new invoice id.

**SPA UI:**
- New "**Build invoice**" sheet on visit-complete screen (post-clock-out)
- "Pre-fill from this visit" CTA → calls `convert_visit_to_invoice` → fills the form
- Edit any line item before send
- Tax row pulled from workspace settings
- Actions: "Save as draft" / "Send to customer" / "Print here" (Wave V print-friendly route shared)

**Cross-app parity:** invoice lands as `provider_invoices` row visible on web Operations Desk + as inbox row on homeowner iOS.

**Effort:** 75 min. **Demo value:** high.

---

## Wave M6 — Field UX polish (tap-to-call + tap-to-navigate + route summary + in-truck reschedule + internal notes)

**Why:** small but field-critical affordances that compound. Section 6.12, 6.13, 6.16, 6.18, 17.6.

**Schema (`supabase/migrations/20261305_visit_tech_notes.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.provider_visit_tech_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  request_id UUID NOT NULL REFERENCES public.handyman_requests(id) ON DELETE CASCADE,
  author_member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.provider_visit_tech_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "workspace_members_can_rw" ON public.provider_visit_tech_notes
  FOR ALL USING (workspace_id IN (
    SELECT workspace_id FROM public.provider_workspace_members
    WHERE user_id = auth.uid() AND status = 'active'
  ));
```

**Edge Function actions:**
- `add_tech_note` — accepts `{ requestId, body }`. Inserts a row.
- `propose_visit_time` already exists for reschedule — reuse.

**SPA UI:**
1. **Tap-to-call**: visit detail customer phone renders as `<a href="tel:...">` with phone icon
2. **Tap-to-navigate**: address renders as `<a href="https://maps.apple.com/?q=<urlencoded address>">` with pin icon (iOS Safari opens Apple Maps; Chrome opens Google Maps fallback)
3. **Route summary card** on Today screen: pulls today's stops, sums `clock_in_at → expected_drive_time`, surfaces "8 stops · 47 miles · 3h 45m drive time"
4. **In-truck reschedule**: visit detail "Reschedule" button → modal with 3 next-available slot picker (next 14 days × tech's open windows) → confirm → calls `propose_visit_time`
5. **Internal tech-to-tech notes** section on visit detail: separate from customer thread, only visible to workspace members. New row with "Add internal note" composer + list of past notes. Hidden from customer-visible chat.

**Cross-app parity:**
- Internal notes visible on web Operations Desk's `VisitDetail.tsx` in a new "Internal Notes (workspace only)" section
- Reschedule writes to `provider_visit_assignments.route_date` AND inserts audit message (Wave Z.1 pattern)

**Effort:** 90 min. **Demo value:** medium-high.

---

## Wave M7 — Crew chat (intra-workspace messaging)

**Why:** tech-to-tech / tech-to-dispatch coordination. Separate from customer threads. "Bob just called in sick, anyone available to take 4pm at the Smiths?"

**Schema (`supabase/migrations/20261306_crew_chat.sql`):**
```sql
CREATE TABLE IF NOT EXISTS public.crew_chat_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  name TEXT,
  kind TEXT NOT NULL DEFAULT 'general' CHECK (kind IN ('general', 'route_day', 'tech_pair')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.crew_chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES public.crew_chat_threads(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL,
  sender_member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  read_by JSONB NOT NULL DEFAULT '[]'::jsonb,  -- array of member_ids who've read
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.crew_chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_chat_messages ENABLE ROW LEVEL SECURITY;
-- Workspace member RW policies, mirror existing patterns
```

**Edge Function (new `crew-chat/index.ts`):**
- `list_threads` — returns workspace's threads with last-message previews + unread counts
- `send` — accepts `{ threadId, body, attachments? }`. Inserts message. Returns the row.
- `mark_read` — accepts `{ threadId }`. Stamps the caller's member_id into `read_by` for all messages in thread.
- `create_thread` — accepts `{ name?, kind, memberIds }`. For ad-hoc tech-pair threads.

**SPA UI:**
- New "**Crew**" tab in the bottom nav (between current tabs)
- Inbox column listing threads with previews
- Thread view: bubbles left-aligned (others) / right-aligned (self), with sender avatar
- Composer: text + photo attach (reuses M2 photo upload bucket if applicable)
- Realtime via Supabase Realtime channel

**Cross-app parity:** web Operations Desk's `Crew.tsx` gets a new "Chat" sub-tab with the same message list, same composer.

**Effort:** 120 min (new schema + new edge fn + new tab on both surfaces). **Demo value:** medium.

---

## Wave M8 — End-of-visit suggestion authoring

**Why:** at end of visit, the tech proposes follow-up work. Drives recurring revenue. Section 9b mobile path + 6.40.

**Edge Function actions:**
- `suggest_followup_task` — accepts `{ requestId, propertyId, householdId, title, description?, dueDate? }`. Creates a `maintenance_tasks` row tagged `assignment_type = 'either'`, `source = 'contractor_suggestion'`. Inserts a `handyman_request_messages` audit row tagged `metadata.kind='task_suggested'` so the homeowner sees the suggestion in their thread.
- `suggest_followup_quote` — accepts `{ requestId, propertyId, householdId, title, scopeNotes }`. Opens M4's quote builder pre-filled.
- `schedule_followup_visit` — accepts `{ requestId, proposedDate, durationMinutes }`. Same pattern as Wave Z.1 reschedule.

**SPA UI:**
- New "**Anything to follow up on?**" wizard on the visit-complete screen (post-clock-out, post-summary):
  - Free-text: "Anything you noticed?" — saves to visit notes
  - "+ Suggest a task" → templated picker (filter change in 90 days / valve seal in 6 months / annual furnace tune-up / etc.) or free-form input
  - "+ Suggest a quote" → opens M4 quote builder pre-filled with scope from observation
  - "+ Schedule next visit" → opens M6 reschedule modal but for a NEW visit slot
- Each adds a row to a "Suggestions queue" the homeowner sees in their iOS Tasks tab

**Cross-app parity:**
- Suggestions land as `maintenance_tasks` rows visible on homeowner iOS Tasks tab
- Suggestion creates a `handyman_request_messages` row with `metadata.kind='task_suggested'` so the homeowner thread shows it
- Web Operations Desk's Tasks aggregate (Wave Z.2) populates with the new tasks

**Effort:** 90 min. **Demo value:** medium-high — closes the recurring-revenue story.

---

## Wave M9 — Co-tech + lockbox + mid-stream cancellation

**Why:** edge cases that field techs hit constantly but no demo path captures.

**Schema (`supabase/migrations/20261307_visit_edge_cases.sql`):**
```sql
ALTER TABLE public.provider_visit_assignments
  ADD COLUMN IF NOT EXISTS co_tech_member_ids UUID[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS access_method TEXT,    -- 'customer_present' | 'lockbox' | 'key_under_mat' | 'door_code'
  ADD COLUMN IF NOT EXISTS access_notes TEXT;
```

**Edge Function actions:**
- `add_co_tech` — accepts `{ requestId, memberId }`. Appends to array.
- `set_access_method` — accepts `{ requestId, method, notes? }`.
- `cancel_visit_mid_stream` — accepts `{ requestId, reason, partialState? }`. Saves whatever the tech captured so far, schedules a placeholder follow-up, marks request `cancelled` with `metadata.cancellation_reason`.

**SPA UI:**
- **Co-tech mode**: visit detail → "+ Add co-tech" → picker from active workspace members → both can check off items, both timestamps captured per check-off.
- **Lockbox / no-customer access flow**: pre-visit prep checklist asks "Will the customer be home?" → if no, surfaces access method + photo evidence requirement (every punch item must have at least 1 photo before complete is allowed).
- **Mid-stream cancellation**: red "End visit early" button on running-clock state → modal: reason picker [Weather / Customer cancelled / Tech emergency / Other] → "Save partial state, schedule follow-up" → submits.

**Cross-app parity:** these states surface on web Operations Desk visit detail with "Co-tech: [Bob, Alice]" header, "Access: lockbox (code 1234, side gate)" badge, and "Cancelled mid-visit at 10:42, follow-up scheduled May 14" annotation.

**Effort:** 90 min. **Demo value:** medium — "real-world toolset" story.

---

## Wave M10 — "Closest customer to me" + business card AI

**Why:** location-aware UX (mobile-only natural lens) + capturing existing-vendor relationships during assessment.

**Edge Function actions:**
- `nearest_customers` — accepts `{ workspaceId, latitude, longitude, limit }`. Returns workspace's customers sorted by Haversine distance. Reuses existing `provider_contractor_links` join.
- `extract_business_card` — accepts `{ imageBase64 }`. Calls `identify-equipment` Edge Function (or `chat` with vision) with a prompt: "Extract company name, contact name, phone, email, website, trade category from this business card." Returns structured JSON.

**SPA UI:**
- **"Closest customer to me"** map view (new screen): geolocate → call `nearest_customers` → render mapbox-like static map (use OpenStreetMap or Apple MapKit JS) with pins + a sortable nearest list.
- **Business card capture** (existing system-add flow, new entry point): "Add existing vendor" → camera → snap business card → AI extracts → confirmation card → save as `contractors` row on the household.

**Cross-app parity:** vendors captured via business card flow appear on web Operations Desk's Contacts tab + on homeowner iOS Property tab.

**Effort:** 90 min. **Demo value:** medium — captures growth signal.

---

## Wave M11 — End-of-day summary + day completion

**Why:** the field tech wants to close out their day with a clean summary — total hours, total revenue, tomorrow's preview.

**Edge Function action:**
- `today_summary` — accepts `{ workspaceId }`. Returns today's stops + clock-in/out totals + materials cost + revenue (sum of invoices sent today) + tomorrow's stops preview.

**SPA UI:**
- New "**End of Day**" screen accessible from Today after the last visit completes
- Hero: "Day complete · 4 stops · 6h 12m on the clock · $1,247 invoiced"
- Per-stop summary card with elapsed time + invoice link
- Tomorrow's preview: "8 stops scheduled · first at 9am with Customer 4 · weather: 47°F clear"
- "Sign off" CTA (just clears the running state; could integrate with timekeeping later)

**Cross-app parity:** web Operations Desk's Crew screen shows per-tech today's sign-off state in the workload strip.

**Effort:** 60 min. **Demo value:** medium — operational closure.

---

## Wave M12 — "Need part" flow

**Why:** mid-visit, tech realizes they need a part. Tap to flag → operator sees it in real time → operator orders / dispatches another tech with the part.

**Schema:** reuses `provider_visit_assignments` + a new `provider_part_requests` table:
```sql
CREATE TABLE IF NOT EXISTS public.provider_part_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  request_id UUID REFERENCES public.handyman_requests(id) ON DELETE SET NULL,
  punch_item_id UUID REFERENCES public.handyman_punch_items(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  urgency TEXT NOT NULL DEFAULT 'next_visit' CHECK (urgency IN ('blocking_now', 'next_visit', 'order_for_stock')),
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'ordered', 'in_truck', 'fulfilled', 'cancelled')),
  requested_by_member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.provider_part_requests ENABLE ROW LEVEL SECURITY;
-- Workspace RW
```

**Edge Function actions:** `create_part_request` / `update_part_status`.

**SPA UI:**
- "**Need part**" button on visit detail and per punch item
- Modal: description + urgency + photo (reuses M2 photo flow)
- Submits → notification to operator (push via existing notify path)
- Surfaces on tech's Today screen as a "1 part request open" pill

**Cross-app parity:** web Operations Desk gets a new **"Part Requests"** sub-section on the Routes screen (or dedicated page) showing all open part requests across techs. Operator can: dispatch another tech with the part, mark ordered with supplier ETA, mark fulfilled.

**Effort:** 90 min. **Demo value:** medium.

---

## Wave M13 — Quote duplication mobile path

**Why:** "Same as the Smith house yesterday" — kitchen-table efficiency.

**Edge Function action:**
- `duplicate_quote` — accepts `{ sourceQuoteId, targetHouseholdId, targetPropertyId, targetRequestId? }`. Creates a new draft quote with the source's line items + scope notes + tier structure. Returns new quote id.

**SPA UI:**
- M4's quote builder gains a "Duplicate from another quote" entry: dropdown of recent quotes (workspace-scoped, sorted by recency) → pick → form pre-fills.

**Cross-app parity:** same `duplicate_quote` action used from the web Operations Desk Quotes screen (W9).

**Effort:** 45 min. **Demo value:** medium.

---

## Wave order + dependencies

```
M1 (visit lifecycle)            ← foundation; everything depends on clock-in
M2 (punch capture depth)        ← needs M1 (clock-in to anchor time tracking)
M3 (system authoring)           ← independent, parallel-safe
M6 (UX polish)                  ← independent
M7 (crew chat)                  ← independent
M4 (in-person quote)            ← needs M2 (punch list as line item source)
M5 (on-site invoice)            ← needs M2 + M4
M8 (end-of-visit suggestions)   ← needs M1 (post-complete screen)
M9 (edge cases)                 ← needs M1
M10 (closest customer + business card) ← independent
M11 (end-of-day summary)        ← needs M1
M12 (need part flow)            ← needs M2 (link to punch item)
M13 (quote duplication)         ← needs M4
```

**Recommended ordering across overnight passes:**

**Pass 1 (8h):** M1 → M2 → M6 → M3 (core field flows + UX polish)

**Pass 2 (7h):** M4 → M5 → M8 → M11 (sales + close-of-day)

**Pass 3 (6h):** M9 → M10 → M12 → M13 (edge cases + helper flows)

**Pass 4 (4h):** M7 (crew chat)

---

## Per-wave subagent invocation template

In a fresh chat:

```
Read /Users/tomburke/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8/Tests/e2e/CONTRACTOR_MOBILE_BUILDOUT_PLAN.md

Execute Wave M{N} via a general-purpose subagent. Use the wave's spec verbatim from the plan doc.

Each subagent:
1. Reads /tmp/ui-test/CONTRACTOR_SETUP.md first
2. Resizes Chrome to 390×844, loads the PWA at port 8000
3. Implements the schema migration (if any) + edge fn actions + SPA UI per the plan
4. Verifies the new flow works at 390×844 viewport (1-3 screenshots)
5. Cross-app DB cross-check via service-role JWT
6. Commits + pushes to the default branch (claude/setup-monorepo-structure-...)
7. Returns the standard JSON block (Section 27 of the matrix)
8. Confirms Vercel deploy of the SPA + Supabase deploy of the edge fn

Time-box: per the wave's stated effort + 25% buffer. If the wave is too large, scope to a viable skeleton + log the deferred portions in CONTRACTOR_GAPS.md.
```

---

## Schema migrations introduced by this plan

1. `20261301_visit_lifecycle.sql` — Wave M1
2. `20261302_punch_capture_depth.sql` — Wave M2
3. `20261303_home_system_decommission.sql` — Wave M3
4. `20261304_quote_signature.sql` — Wave M4
5. `20261305_visit_tech_notes.sql` — Wave M6
6. `20261306_crew_chat.sql` — Wave M7
7. `20261307_visit_edge_cases.sql` — Wave M9
8. `20261308_part_requests.sql` — Wave M12

All additive (new columns / new tables). No data migration. Apply via `supabase db push --linked`.

---

## Storage buckets introduced

1. `punch-item-attachments` — Wave M2
2. `quote-signatures` — Wave M4

All private; per-household-scoped RLS via `documents_storage_bucket_policy` pattern.

---

## Edge Function deploys per wave

Every wave touches `handyman-provider/index.ts` to add 1–4 actions. Wave M7 adds a NEW edge function `crew-chat/index.ts`. Each wave deploys via:

```bash
cd /Users/tomburke/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8
supabase functions deploy handyman-provider --no-verify-jwt
# or for M7:
supabase functions deploy crew-chat --no-verify-jwt
```

---

## Quality discipline (Section 22 — applies to every wave)

- A1 save → reload persistence
- A3 DB cross-check via service-role JWT
- B1 salmon discipline (only primary CTAs / active states / SLA pills)
- B3 no em dashes in user-facing copy
- B4 no "handyman" in user-facing copy (rebrand to "Chez Contractor" / trade-specific)
- B6 touch targets ≥ 44pt on every primary CTA
- B9 empty / loading / error / populated states for every async surface
- D1 skeleton loaders, never spinners on blank screens
- C1 empty submit on every form fires validation visibly
- C7 network failure mid-save → clear error + retry
- E1 background → foreground state preservation
- Service Worker continues to work — test offline path before commit

---

## Output format per wave

End every subagent invocation with:

```json
{
  "wave": "M{N}",
  "title": "...",
  "result": "PASS | PARTIAL | FAIL",
  "actions_summary": "...",
  "files_changed": [...],
  "schema_migrations": [...],
  "edge_function_deploys": [...],
  "screenshots": [...],
  "cross_app_parity_verified": true | false,
  "deferred_to_next_wave": [...],
  "commit_hash": "..."
}
```

---

## Closing — what this plan delivers

After running all 13 waves, the Chez Field PWA covers every Section 22 mobile concern + every mobile-side gap from the overnight E2E findings:

- ✅ Visit lifecycle accountability (clock-in/out + GPS + pause/resume)
- ✅ Punch list capture depth (photos + voice + materials + per-item time)
- ✅ System inventory authoring (the moat)
- ✅ In-person quote with bundles + e-Signature
- ✅ On-site invoice with one-tap conversion
- ✅ Field UX polish (tap-to-call/navigate, route summary, in-truck reschedule, internal notes)
- ✅ Crew chat (intra-workspace coordination)
- ✅ End-of-visit suggestions (drives recurring revenue)
- ✅ Edge cases (co-tech, lockbox, mid-stream cancel)
- ✅ Closest customer + business card AI (existing-vendor capture)
- ✅ End-of-day summary (close-out)
- ✅ Need part flow (operator coordination)
- ✅ Quote duplication

Cross-app parity verified after every wave. Brand voice + salmon discipline + em-dash discipline maintained throughout.

The mobile contractor surface goes from "demo skeleton" to "field-ready depth."
