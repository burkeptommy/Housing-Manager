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

(populated by Wave K)
