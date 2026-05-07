# Chez Contractor web — gaps log

Findings from the overnight E2E run that the matrix flagged as
"feature-absent" or "incomplete." Grouped by category, then severity,
then matrix section. Each row is meant to feed into product input —
the main thread is NOT auto-fixing these.

Schema additions / behavioral gaps that surfaced during fixture
seeding go in the **Schema gaps** section. Web UI gaps go in the
**Web UI gaps** section. Cross-app desync goes in the **Cross-app
gaps** section.

---

## Schema gaps (surfaced during Phase 0 fixture seeding)

### Major

- **`handyman_requests.source` CHECK constraint excludes `chez_admin`.** The constraint is `('homeowner', 'haven', 'vendor', 'field')`. Phase 80+ added Chez admin orchestration but didn't extend this constraint, so Chez-routed requests cannot self-identify their origin at the row level. Workaround: use `source='haven'` and stamp the flavor in the related message's `metadata`. **Recommendation:** add `chez_admin` to the CHECK list and a corresponding column-level enum / constant on the iOS + web sides.
- **`handyman_requests` has no `metadata` JSONB column.** Phase 80 Chez orchestration needs to stamp routing flavor + acknowledgment requirements at the request level, not just on a relayed message. Today the flavor only lives on the related `handyman_request_messages.metadata`. **Recommendation:** add `metadata JSONB DEFAULT '{}'::jsonb` to mirror the homeowner-side `inbox_items` pattern.

---

## Web UI gaps (filed during waves)

### Critical

- **Auth gate hung on "Loading your workspace…" forever for unauth'd visitors** (FIXED, commit `32c134f8`). `loadDashboard` early-returned on null session without flipping `isLoading` to false, so the App-level redirect to `/handyman.html` never fired. The SPA was completely unreachable without an existing session — every fresh visitor saw a blank loading screen with no way out.
- **`/operations/chez.css` returned the SPA's HTML fallback instead of CSS** (FIXED, commit `85874c1e`). Vite's `base: "/operations/"` rewrites `<link href="/chez.css">` in index.html to `/operations/chez.css`, but no such file existed. Result: every design token (`--indigo-900`, `--salmon`, `--pearl`, `--serif`, `--sans`) was undefined, sidebar bg fell back to transparent, white sidebar text rendered on white page bg = invisible left nav. Fixed via symlink `website/operations/public/chez.css → ../../chez.css`.

### Major

- **W1.5 Crew "+ Invite teammate" button is a no-op** (Section 1.5). `Crew.tsx:56` — button renders but has no `onClick` handler. No invite modal/sheet exists. The entire team-onboarding flow has no UI; `provider_workspace_members.invite_token` cannot be exercised from the web. Recommendation: wire the button to a sheet that captures email + role and calls a new `invite_team_member` Edge Function action.
- **W1.4 Workspace branding settings missing** (Section 1.4). No Settings screen exists in the SPA. `provider_workspaces` has columns for `headshot_url`, `service_state`, `service_city`, `service_zip_codes`, `license_number`, `display_blurb`, `categories` — all unwired. Workspace identity / brand config is not surfaceable from the web.
- **W1.10 Multi-workspace switcher is a stub** (Section 1.10). The sidebar workspace pill is wired but clicking produces no menu/dropdown. Per `// TODO multi-workspace` in `WorkspaceProvider`, owners with multiple workspaces cannot switch contexts.
- **B4 brand voice — `/handyman.html` auth page** (rebrand violations). 10 user-facing "handyman" mentions: page title "Chez Handyman", sidebar brand "chez handyman", eyebrow "FOR HANDYMAN BUSINESSES", body "operating system for handyman businesses", RHS title "Sign in to the full Chez Handyman desk", submit button "Sign in to Chez Handyman". Plus 3 em dashes. The Operations SPA itself (post-auth) is brand-clean. Marketing/auth page rebrand deferred — wider product call.

### Moderate

- **W2.7 Recent threads section renders 4 generic empty placeholders** ("Home / No messages yet. Start the thread.") even when threads exist with seeded messages. Either dashboard query isn't pulling thread message previews, or the fixture didn't seed messages onto threads that surface here. Worth investigating in Wave E (Messages tab).
- **W2.9–2.11 Recent activity feed + smart hero CTA + sort order** (Sections 2.9–2.11) — likely gaps; not surfaced in current SPA.

### Minor

- **W2.8 No `<h2>` headings on Overview** — section labels (NEEDS YOUR ATTENTION / TODAY · FIELD BOARD / QUOTE PIPELINE) are styled `<div>`s, not headings. Screen-reader users miss the document outline. (H1 only.)
- **W1.12 Sign-out `?next=` → routes to `/operations/` instead of `/operations/<route>`** — the next-link path is preserved on the auth page side but the redirect after sign-in lands at the Overview rather than the originally-requested deep link.

---

## Cross-app gaps (Section 21 round-trip findings)

### Critical (architectural)

- **`handyman_punch_items` is never read by the contractor SPA** (Wave C, Section 6.19). The DB has 146 rows of seeded punch items joined to `provider_visit_assignments` via `assigned_visit_task_id`. The `handyman-provider` edge function (line 2233) returns `punchItems[]` per visit. But `VisitDetail.tsx:44` calls `parsePunchList(visit.notes)` — parsing free-text out of `maintenance_tasks.notes` instead of consuming the structured list. The SPA's `VisitRow` type has no `punchItems` field. **Result: every fixture's 3-8 punch items are invisible on the contractor side.** The homeowner iOS app reads the proper `handyman_punch_items` rows, the contractor web reads parsed text from a different table — the two sides are not looking at the same data. This breaks the entire punch-list authoring story (Section 6.20–6.32 are all moot until this is wired). Recommendation: extend `VisitRow` with `punchItems: HandymanPunchItem[]`, rewrite `VisitDetail.tsx` punch-list rendering to consume it, add the authoring CRUD flow, and remove the `parsePunchList(visit.notes)` shim.
- **"Mark complete" inserts no audit-trail message** (Wave C). After flipping `handyman_requests.status = 'completed'`, no `handyman_request_messages` row is appended. The homeowner-side conversation history shows zero record of when the contractor completed the visit, what they did, or any after-action summary. Compare to `chez-concierge` `transition_status` pattern which auto-inserts a system message + fires push. Recommendation: extend `update_request_status` Edge Function action to append a system-role message ("Visit marked complete by [contractor]") + send a push notification to the homeowner.

### Major

- **`maintenance_tasks` rows updated by handyman do not propagate to the homeowner side** (Wave C corollary). When the handyman flips status of a task or adds a note, the homeowner needs to see this in their iOS Maintenance schedule. Verifying the round-trip is part of Wave K. Until punch items + completion summaries surface, the homeowner has no visibility into what the contractor did during the visit.
