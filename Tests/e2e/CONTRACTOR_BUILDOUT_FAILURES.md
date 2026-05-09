# Chez Contractor buildout — failure / bug log

## Verification pass — 2026-05-08

Source: comprehensive Chez Field iOS app verification subagent (sweep of every tab + every M-wave surface). Result: **PARTIAL** — core flows work, but 3 critical bugs surface and 10 polish bugs queued.

### Critical bugs

| ID | Surface | Severity | Repro |
|---|---|---|---|
| **C-1** | M1 `complete_visit` action — visit detail (`HavenFieldVisitWorkspaceView`) | 🔴 blocker | Tap Complete on a clock-in'd visit. UI flips to "Visit complete" with green check + total time. DB cross-check: `provider_visit_assignments.clock_out_at` remains NULL, `handyman_requests.status` remains `in_progress`. The status pill on the same screen still reads "In progress" while the lifecycle card reads "Visit complete". `handyman_request_messages` got the audit row but the canonical state didn't update. Two surfaces inconsistent on the same page. **Data integrity issue.** Likely cause: the `complete_visit` action inserts the audit message but doesn't run the UPDATE on `provider_visit_assignments.clock_out_at` and the request `status` flip. |
| **C-2** | Auth / navigation — sign-out flow | 🔴 blocker | Sign Out from Settings → welcome screen → tap "Sign in to Chez Field" → empty form renders → long-press email field → instead of summoning paste menu, app dismisses sign-in form and re-enters previous view stack. Subsequent taps trigger destructive actions (verification subagent's session: a Complete Visit fired without intent on visit `aab4c2d0`). Either Sign Out doesn't clear the `HavenSimulatorAuthStorage` UserDefaults entry, the nav stack isn't reset on sign-out, OR long-press in iOS Sim has unintended stack-pop side effects. Likely needs to add `defaults.removeObject` calls for the supabase.auth.* keys on sign-out + a nav-stack reset. |
| **C-3** | M3 Flag-for-follow-up sheet | 🟡 major (Section 22 C1 violation) | Open any system → Field actions → Flag for follow-up → leave the "Why couldn't you finish today?" input empty → tap Flag in toolbar. Sheet dismisses silently, DB row gets `marked_for_followup_at = now()` but `followup_reason = NULL`. The reason is the entire point of this flow — silently accepting NULL produces useless "flag for follow-up: <unknown>" rows. Add validation: empty body → red inline error "Tell us why so the next visit knows what to do." |

### Non-critical / polish bugs

| ID | Surface | Severity | Description |
|---|---|---|---|
| N-1 | Overview hero, Visit detail, Visits list, route table | 🟡 major | Time fields render as raw `HH:MM:SS` (e.g. `10:00:00 to 12:00:00`, `first at 10:00:00`, `Connected home · 10:00:00`). Should be `10:00 AM` or device-locale formatted. Pattern: Postgres time column stringified directly without a Date formatter. |
| N-2 | Overview, Visits list, Visit detail, Build quote sheet | 🟡 major | Visit type enum leaks: `standard visit: Customer 4`, `repair: Customer 4`, `install: Customer 4`, `quote: Customer 7`. Lowercase + colon-prefix. Should be `Standard visit · Customer 4` or just `Customer 4` with the type as a chip/pill. |
| N-3 | Overview greeting subtitle | 🟡 major | After completing a visit, dashboard greeting reads `1 stop today · first at next up · 8 requests waiting`. The literal text `next up` appears where a time should — fallback string when `nextUpTime` is empty/null. |
| N-4 | Overview Recently Serviced Homes + Visit detail House context | 🟢 minor | Pluralization mismatches: `Customer 6 home: 5 systems · 1 open tasks` (should be `1 open task`); `OPEN WORK: 1 items` (should be `1 item`). |
| N-5 | Overview "Need a response" list (Initial setup row) | 🟡 major | Title shows `Initial setup . O'Brien-Müller 1778176425027` — literal full-stop instead of middle dot for separator AND raw test-stamp number leaks into customer name. (B3 violation: `' . '` instead of `' · '`.) |
| N-6 | Customer 4 home Systems sub-tab | 🟡 major | Same systems duplicated: AC and Roof appear in both `GAP-FILL — 2 systems missing details` AND `SYSTEMS — Known systems`. Filter inconsistency — gap-fill should exclude systems already in known systems OR known systems should exclude incomplete ones. |
| N-7 | Visits list (cached after detail navigation) | 🟡 moderate | After adding a tech note from inside a visit (count 2→3) and going back to the Visits list, the `2 notes` pill stays at 2 until the user navigates to a different tab and back. TIME ON-SITE counter on the list also shows the value from when the list was first loaded. Pull-to-refresh on the list also doesn't refresh — only full tab switch. |
| N-8 | Homes list | 🟢 minor | Two cards show identical `999 Test Avenue` — cannot distinguish them. Either fixture issue or app fails to dedupe by household_id. |
| N-9 | Build quote sheet header | 🟢 minor | Date renders as raw `2026-05-08` (ISO format) instead of localized `May 8, 2026`. Same bug pattern as N-1. |
| N-10 | Settings sheet | 🟢 minor | Workspace name displayed as raw fixture stamp `E2E Contractor crew6 1778170662764` — including the unix-millis suffix. |

### Section 22 discipline violations

| Code | Surface | Evidence |
|---|---|---|
| **B1** | Customer 4 home → Systems → AC + Roof rows + Gap-fill cards | Caption text `Missing model plate details` renders in salmon. B1: salmon is for primary CTA / active queue accent / salmon-50 wash on selected / fit-meter at success tier / SLA-critical pills only — NOT inline caption text on inactive list rows. |
| **C1** | M3 Flag-for-follow-up sheet | Empty submit silently accepted (= C-3). |
| **B9** | Visit detail page | STATUS pill shows `In progress` while VISIT LIFECYCLE shows `Visit complete` on the same page after a Complete tap. Two surfaces inconsistent (= C-1 manifestation). |
| **B9** | Visits list cache | List shows `2 notes` even after note count is 3 in DB. List shows TIME ON-SITE: 5h 14m even after the actual lifecycle counter is at 5h 30m+. |

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
