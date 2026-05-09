# Chez Contractor buildout — failure / bug log

## Verification pass — 2026-05-08

Source: comprehensive Chez Field iOS app verification subagent (sweep of every tab + every M-wave surface). Result: **PARTIAL** — core flows work, but 3 critical bugs surface and 10 polish bugs queued.

## Bugfix pass — 2026-05-08

3 criticals + 5 polish bugs landed. Edge fn handyman-provider redeployed v79; iOS build clean. Outstanding work batched below in updated severity.

### Critical bugs (all fixed)

| ID | Surface | Severity | Status | Fix |
|---|---|---|---|---|
| **C-1** | M1 `complete_visit` action — visit detail (`HavenFieldVisitWorkspaceView`) | 🔴 blocker | ✅ FIXED | Restructured `completeVisitForProvider` to (1) close any open pause first, (2) ALWAYS stamp `clock_out_at` (we coalesce with the existing value so retries are idempotent at the semantic level but the field is never left null), (3) run a single atomic UPDATE with the full desired final state, (4) re-read the row to verify `clock_out_at` actually landed before doing anything else, (5) flip request status via `updateRequestStatusForProvider`, (6) re-read the request row to verify status flipped to `completed`. Throws specific errors at every step so audit messages never insert when the canonical writes failed. Backfilled the existing busted assignment `aab4c2d0` + request `6c9c9b5c` via SQL UPDATE. Edge fn handyman-provider redeployed v79. |
| **C-2** | Auth / navigation — sign-out flow | 🔴 blocker | ✅ FIXED | Promoted `HavenSimulatorAuthStorage` to a shared singleton (so the SDK reads + writes against the same instance the sign-out path can wipe). Added `clearAll()` method that removes every `supabase.auth.*` UserDefaults key. Wired it into the `.signedOut` case in `AuthService.startListening` (under `#if targetEnvironment(simulator)`) AND into `forceLocalSignOut` for symmetry. Device + TestFlight + App Store builds keep using the Keychain path which the SDK's own `signOut` already wipes via delete-class queries. |
| **C-3** | M3 Flag-for-follow-up sheet | 🟡 major (Section 22 C1 violation) | ✅ FIXED | `HavenFieldFollowupSheet` now validates the reason field on submit. Empty (after trim) → inline `validationError` renders below the TextField in `HavenColors.critical` with copy "Tell us why so the next visit knows what to do." — sheet stays open + onConfirm is NOT called + the DB row never gets stamped. Mirrors the M1 pause modal "Other branch validation" pattern. `onChange(of: reason)` clears the error when the user starts typing. |

### Non-critical / polish bugs

| ID | Surface | Severity | Status | Description |
|---|---|---|---|---|
| N-1 | Overview hero, Visit detail, Visits list, route table | 🟡 major | ✅ FIXED | Added `String.fieldShortTime` extension that parses `HH:mm:ss` / `HH:mm` and renders via `DateFormatter` with `timeStyle = .short` so "10:00:00" → "10:00 AM" device-locale. Wired into every visible call site (heroSubtitle, previewLine, timeLabel, durationLabel, routeWindow, routeSummary). The sort comparator at line 11666 was deliberately left raw because lexicographic order matches chronological order on `HH:mm:ss`. |
| N-2 | Overview, Visits list, Visit detail, Build quote sheet | 🟡 major | ✅ FIXED | Added `String.fieldDisplayTitle` extension that strips the `<kind>:` prefix when it matches a known visit-type token (`standard visit` / `standard_visit` / `repair` / `install` / `quote` / `assembly` / `question` / `setup`). Wired into every `Text(visit.title)` site (10 surfaces). Untouched titles pass through unchanged so non-prefixed names still render. |
| N-3 | Overview greeting subtitle | 🟡 major | ✅ FIXED | `heroSubtitle` rewritten: instead of the raw `?? "next up"` fallback string, the "first at X" segment is now conditional on a non-nil window-start-time. Subtitle is built as `parts.joined(separator: " · ")` so the segment drops out cleanly when no time is on file. Time also now uses the new `fieldShortTime` formatter. |
| N-4 | Overview Recently Serviced Homes + Visit detail House context | 🟢 minor | ✅ FIXED | Pluralization fixed inline at both surfaces (`FieldHomeRow.summary` and the Visit detail's "Open work" FieldKeyValueRow). "1 systems" → "1 system", "1 open tasks" → "1 open task", "1 items" → "1 item". |
| N-5 | Overview "Need a response" list (Initial setup row) | 🟡 major | PARTIAL | Stamp number leak (`O'Brien-Müller 1778176425027`) is a fixture issue — household.name has the timestamp baked in by the seed runner. Out of iOS scope; flagged for the fixture owner. The `' . '` separator was actually `' • '` (middle bullet, U+2022) in some surfaces and `' · '` (middle dot, U+00B7) in others — `routeSummary` was normalized to `' · '`; remaining `'· '` and `'• '` mixed-use sites left as-is to keep this commit focused. |
| N-6 | Customer 4 home Systems sub-tab | 🟡 major | OPEN | Same systems duplicated: AC and Roof appear in both `GAP-FILL — 2 systems missing details` AND `SYSTEMS — Known systems`. Filter inconsistency — gap-fill should exclude systems already in known systems OR known systems should exclude incomplete ones. |
| N-7 | Visits list (cached after detail navigation) | 🟡 moderate | PARTIAL | `submitTechNote` now posts `.havenFieldVisitChanged` on success so the dashboard's denormalized `techNotesCount` + the list pill refresh on tab back-nav. The TIME ON-SITE counter staleness on the list and the pull-to-refresh-doesn't-refresh issues are still open — they need a `.refreshable` hook on `HavenFieldVisitsTab` or a `.task(id:)` reload pattern. Tracking for a follow-up wave. |
| N-8 | Homes list | 🟢 minor | OPEN | Two cards show identical `999 Test Avenue` — cannot distinguish them. Either fixture issue or app fails to dedupe by household_id. |
| N-9 | Build quote sheet header | 🟢 minor | ✅ FIXED | `visitDateLabel` (FieldBuildQuoteSheet) was attempting ISO8601 parsing which can't handle date-only "2026-05-08" strings (Postgres date column). Added a yyyy-MM-dd parser branch FIRST so date-only strings render as "Fri May 8". The ISO 8601 fallback stays for full timestamps. |
| N-10 | Settings sheet | 🟢 minor | OPEN | Workspace name displayed as raw fixture stamp `E2E Contractor crew6 1778170662764` — including the unix-millis suffix. Likely a fixture issue but the iOS Settings sheet could also clean it up at render time. |

### Section 22 discipline violations

| Code | Surface | Evidence | Status |
|---|---|---|---|
| **B1** | Customer 4 home → Systems → AC + Roof rows + Gap-fill cards | Caption text `Missing model plate details` renders in salmon. B1: salmon is for primary CTA / active queue accent / salmon-50 wash on selected / fit-meter at success tier / SLA-critical pills only — NOT inline caption text on inactive list rows. | ✅ FIXED — both `Missing model plate details` and `Voice memo on file` captions changed from `HavenColors.action` to `HavenColors.textSecondary`. |
| **C1** | M3 Flag-for-follow-up sheet | Empty submit silently accepted (= C-3). | ✅ FIXED via C-3. |
| **B9** | Visit detail page | STATUS pill shows `In progress` while VISIT LIFECYCLE shows `Visit complete` on the same page after a Complete tap. Two surfaces inconsistent (= C-1 manifestation). | ✅ FIXED via C-1. |
| **B9** | Visits list cache | List shows `2 notes` even after note count is 3 in DB. List shows TIME ON-SITE: 5h 14m even after the actual lifecycle counter is at 5h 30m+. | OPEN (= N-7). |

### Untested due to time / blocker

- M2 punch item Photo upload through PhotosPicker — no active visit had open punch items to attach to (only verified via DB cross-check that pre-existing punch items have populated attachments + materials + voice + time_spent fields)
- M2 voice recording AVAudioRecorder flow — same as above
- M3 Decommission flow — only tested follow-up, not "Mark as removed"
- M3 Voice notes on systems — saw the affordance but didn't exercise it
- M6 reschedule flow — didn't reach the in-truck reschedule sheet
- M6 tap-to-call phone link — no customer phone visible on any visit detail (deferred per progress doc)
- Sign-in as W2 crew1 (technician) for owner-vs-tech permission gating — risky given C-2
- Sign-in as W1 owner (sole) for shell variance — same risk

### Recommendation

Hold demo readiness pending **C-1** + **C-2** + **C-3**. Mobile foundation IS shippable post-fix; current state PARTIAL. Polish bugs (N-1 through N-10) can ship in a separate clean-up pass after the next Pass 2 batch lands.

## Bugfix Sprint #2 — 2026-05-09

Verification Sweep #2 surfaced 2 new criticals + several discipline + polish carry-overs. All addressed in this pass.

### Critical bugs (both fixed)

| ID | Surface | Severity | Status | Fix |
|---|---|---|---|---|
| **C-4** | Visit detail header status pill stale after M8 auto-complete | 🔴 blocker | ✅ FIXED | The header card's "Status" row + actionRow CTA branch read `viewModel.statusLabel` / `viewModel.requestStatus`, both of which read from `payload?.request?.statusLabel` — the portal payload that's NEVER refreshed after a Phase 78 lifecycle action (M1 complete_visit / M8 wizard implicit complete). Introduced view-level `displayedStatusLabel` + `displayedRequestStatus` computed properties that derive from the same `lifecycleState` source-of-truth as the lifecycle section card. When `lifecycleState == .completed`, both override to `HandymanRequestStatus.completed.{displayLabel, rawValue}` so the header pill flips to "Completed" and the actionRow renders an `EmptyView()` instead of the dead "Sync now / Complete visit" duo. |
| **C-5** | M7 crew chat alignment heuristic broken | 🟡 major | ✅ FIXED | The `inferredCurrentMemberId` heuristic falsely identified the OTHER user's messages as "mine" when no self-sent messages existed yet (the Owner's read_by stamp at insert time made `readBy.count == 1` match the heuristic). Edge fn ALREADY served `currentUser.memberId` and the iOS struct ALREADY decoded it — the chat tab just wasn't using it. Plumbed `viewModel.dashboard?.currentUser?.memberId` through `HavenFieldCrewChatThreadView.currentMemberId` (new optional init param). `isMine(_:)` now prefers the authoritative id; the heuristic is preserved as a fallback for forward-compat. |

### Discipline + polish (all fixed)

| ID | Surface | Status | Fix |
|---|---|---|---|
| **B3** | em-dash + en-dash in user-facing copy | ✅ FIXED | Three sites: `HavenFieldView.swift:12423` `\(inAt) – \(outAt)` → `\(inAt) to \(outAt)` (M11 per-stop time range). `12499` `Weather: —` → `Weather: …` (M11 TOMORROW card). `17184` `Done — send suggestions` → `Done. Send suggestions` (M8 wizard CTA). Grep for user-facing dashes now returns 0 results. |
| **D1** | M10 Closest customer uses spinner instead of skeleton | ✅ FIXED | Added `FieldNearbyCustomerSkeletonRow` (3 ghost rows in listPane during loading stages). Map placeholder swaps `ProgressView` → beige skeleton bar. Uses `redacted(reason: .placeholder)` + `accessibilityHidden(true)`. |
| **D7** | Homes list pill wrap + tab bar double-render | ✅ FIXED | Pill wrap: `.lineLimit(1)` + `.minimumScaleFactor(0.85)` + `.fixedSize(horizontal: true, vertical: false)` on `FieldClientBadge`. Tab bar: added `init()` to `HavenFieldRootView` configuring `UITabBar.appearance().standardAppearance = .transparent` + `.isHidden = true` as belt-and-suspenders alongside the existing `.toolbar(.hidden, for: .tabBar)` modifier. |
| **N-permission-gating** | W2 Crew 2 sees "Owner tools" section in Settings | ✅ FIXED | Added `role: String?` parameter to `FieldWorkspaceSettingsSheet`. Section title flips to "Account" for non-owners; the desktop-command-center link gates on `isOwner`. Sign Out stays universal. |
| **N-2** | "chez_routed:" prefix not stripped | ✅ FIXED | Added `chez_routed` and `chez routed` to `String.fieldDisplayTitle`'s known-prefix set. |
| **N-validation-stale-render** | Validation message persists after typing | ✅ FIXED | Three sites: Pause modal Other branch, Access method Lockbox notes (converted `errorMessage` from `let String?` to `@Binding var String?`), Build quote / wizard Add task title (extended to newQuoteTitle + newVisitTitle for symmetry). All use the M1 pause-segment `.onChange(of:)` pattern. |
| **N-6** | Customer 4 home Systems sub-tab gap-fill / known-systems duplication | ✅ FIXED | Introduced `knownSystems` computed property = `visibleSystems` minus `incompleteSystems` (matched by id). Known systems list renders `knownSystems`; gap-fill keeps rendering `incompleteSystems`. Added "Every system needs details" empty-state copy for the all-incomplete edge case. |
| **N-customer-phone** | Phone never surfaces in Visit detail | ✅ FIXED | Edge fn `loadDashboard` now fetches `family_members` for every household in scope, indexed by household_id, primary client preferred (non-staff fallback). Each visit row's `property` JSON now carries `customerPhone: string \| null`. iOS `HavenFieldPropertySummary` extended with optional `customerPhone` (resilient decoder). Visit detail header renders the existing `FieldTappablePhoneRow` (M6 component) when non-nil. Fixtures don't seed phones yet — infrastructure works; production / manual-test households with phones will see the row. |

### Verification

- `xcodebuild -scheme "Chez Field" -sdk iphonesimulator build`: BUILD SUCCEEDED, zero warnings.
- `supabase functions deploy handyman-provider --no-verify-jwt`: deployed.
- W2 owner GET `/handyman-provider`: returns `currentUser.memberId: 8bc028f2-...`, `currentUser.role: 'owner'`, every visit's `property` includes `customerPhone` key.
- W2 Crew 2 GET `/handyman-provider`: returns different `memberId: 3198750f-...` and `currentUser.role: 'technician'` — confirms C-5 + N-permission-gating wiring will land correctly.
- Sim sanity launched + Overview tab rendered cleanly with single tab bar, no double-render visible.

