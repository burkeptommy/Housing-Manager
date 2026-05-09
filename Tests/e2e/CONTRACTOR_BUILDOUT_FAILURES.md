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
| N-4 | Overview Recently Serviced Homes + Visit detail House context | 🟢 minor | OPEN | Pluralization mismatches: `Customer 6 home: 5 systems · 1 open tasks` (should be `1 open task`); `OPEN WORK: 1 items` (should be `1 item`). |
| N-5 | Overview "Need a response" list (Initial setup row) | 🟡 major | PARTIAL | Stamp number leak (`O'Brien-Müller 1778176425027`) is a fixture issue — household.name has the timestamp baked in by the seed runner. Out of iOS scope; flagged for the fixture owner. The `' . '` separator was actually `' • '` (middle bullet, U+2022) in some surfaces and `' · '` (middle dot, U+00B7) in others — `routeSummary` was normalized to `' · '`; remaining `'· '` and `'• '` mixed-use sites left as-is to keep this commit focused. |
| N-6 | Customer 4 home Systems sub-tab | 🟡 major | OPEN | Same systems duplicated: AC and Roof appear in both `GAP-FILL — 2 systems missing details` AND `SYSTEMS — Known systems`. Filter inconsistency — gap-fill should exclude systems already in known systems OR known systems should exclude incomplete ones. |
| N-7 | Visits list (cached after detail navigation) | 🟡 moderate | OPEN | After adding a tech note from inside a visit (count 2→3) and going back to the Visits list, the `2 notes` pill stays at 2 until the user navigates to a different tab and back. TIME ON-SITE counter on the list also shows the value from when the list was first loaded. Pull-to-refresh on the list also doesn't refresh — only full tab switch. |
| N-8 | Homes list | 🟢 minor | OPEN | Two cards show identical `999 Test Avenue` — cannot distinguish them. Either fixture issue or app fails to dedupe by household_id. |
| N-9 | Build quote sheet header | 🟢 minor | OPEN | Date renders as raw `2026-05-08` (ISO format) instead of localized `May 8, 2026`. Same bug pattern as N-1. |
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
