# Homeowner Complete Overnight E2E Report

Run date: 2026-05-10
Branch: `claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG`
Canonical matrix: `Tests/e2e/HOMEOWNER_COMPLETE_TEST_MATRIX.md`

## TL;DR

Round A execution is complete and stopped before Round C. The login wall is no longer blocking simulator QA: fresh backend fixtures now launch through the simulator-only e2e login bootstrap and reach authenticated homeowner UI. A1 and A4 are PASS; A3 is PASS except the two time-windowed PickupDayBanner rows; A5 and A6 have runtime evidence with deferred product/spec gaps documented.

## Round A Status

| Batch | Matrix rows | Status | Evidence |
|---|---:|---|---|
| Prior locked evidence | See below | Prior PASS | Prior commits trusted unless regression surfaces |
| A1 - Section 1d chapter intro card | 1.19-1.23 | PASS | Direct simulator rerun with `e2e-a1-chapter-intro-1778449061906@havenhome.test`; screenshots in `/tmp/codex-screenshots/a1-direct/` verify Chapter 1, Chapter 2 resume, same-chapter suppression, and Chapter 3 resume |
| A2 - Section 2c mode fork waitlist path | 2.34-2.37 | FAIL | `/tmp/codex-logs/a2-xcodebuild.log`, `/tmp/codex-screenshots/a2/address-no-address-found.png` |
| A3 - Section 2i routines lifecycle | 2.96-2.115 | PASS except 2.109-2.110 DEFERRED | Create/edit rows 2.96-2.105 verified by direct simulator run; archive/Chez/pause/resume rows verified with DB and screenshots; PickupDayBanner rows deferred because the simulator was outside required time windows |
| A4 - Section 3 backend combinatorial | 3.1-3.36 | PASS | `/tmp/codex-logs/run-1778439978.log` |
| A5 - Section 14 settings subscreens | 14.1-14.19 | Runtime PARTIAL | Simulator navigation covered Settings subscreens and bottom confirmation popovers; low-risk fixes from `5aa507fc` verified; row 14.8 controls gap and row 14.2 profile-scope gap remain deferred |
| A6 - Section 19 dashboard interactions | 19.1-19.28 | Runtime PARTIAL | Runtime pass covered Dashboard order, coverage hero, schedule navigation, snooze persistence, quick actions, Recent Activity, hero destination, tab reset, and fresh-signup cleanup-card fix; global FAB/bottom-section product gaps remain deferred |

## Prior Locked Evidence

These Round A items are treated as prior-pass evidence per the run plan and are not re-run unless a related regression appears:

| Section | Evidence |
|---|---|
| Section 1a auth signup race | `dbcf2131` |
| Section 1b coverage metric divergence | `3f47fb6e` |
| Section 1c pool chemistry composition | Verified and Q&A closed |
| Section 1e PropertyRecapCard data | `e75a4ad9` |
| Section 2a save-for-later and back-nav | `30a35c3b`, `4ac1f2b4` |
| Section 2b Q28 sub-flows | `4d2c7f42` |
| Section 2d vendor coverage sweep | `b3cec3b4`, `8db9f3b7` |
| Section 2e PostQuizVendorDelegationSheet | `dc0d33ac` |
| Section 2f add vendor manual/website/clipboard | `2f66bc6e`, `71604c2b` |
| Section 2g edit vendor and ContractorDetailView | `e1c41a1a`, `dec45b5d`, `3a32f9b8` |
| Section 2h Chez task delegation | `5b057f98` |

## Commits Shipped

- `97e16e86 Fix: cover homeowner backend combinatorics`
- `5aa507fc Fix: unblock homeowner Round A simulator QA`
- `1524529d Fix: refresh paused routine lifecycle previews`
- `b0dbc64c Fix: hide legacy cleanup card for new homeowners`

## Bugs Found And Fixed

- A4 backend runner coverage was extended and shipped in `97e16e86`. `node Tests/e2e/run.mjs` passed with 0 issues.
- Simulator QA was blocked at login/auth setup. The main session added a debug-simulator e2e fixture login bootstrap and made email/password sign-in update auth state immediately after Supabase returns. This shipped in `5aa507fc`.
- A3.1 rerun exposed a critical authenticated launch crash: duplicate `Landscaping` keys in Day1TaskCurator's routine category map. The main session patched duplicate-tolerant dictionary construction and verified the same fixture relaunches to Dashboard. This shipped in `5aa507fc`.
- A3.1 rerun exposed a cleaning contractor picker category bug. After rebuilding and reinstalling the `5aa507fc` app, Cleaning correctly showed the empty/add-contractor state instead of unrelated vendors, and a Cleaning Service vendor-backed biweekly routine persisted.
- A5 static scan found authorized low-risk Settings fixes. Main-session patches replaced salmon decorative Chez delegation icons with navy styling, removed em dashes from security/access copy, switched Contact Support to `AppConfig.supportEmail`, and exposed the existing Visit Reminders notification preference. These shipped in `5aa507fc`.
- A6 static scan found authorized low-risk Dashboard fixes. Main-session patches route Needs Your Attention schedule links to the calendar, show up to seven Recent Activity events, and split the snooze button out of nested row navigation. These shipped in `5aa507fc`.
- A3.2 pause/resume exposed a lifecycle preview bug. Paused routines persisted correctly but still projected upcoming visits on Routine Detail, and the open detail screen kept stale status after edit saves. The main session suppressed previews for paused/archived routines and made Routine Detail refetch its routine row after reload. This shipped in `1524529d`.
- A6 runtime verification exposed a fresh-signup cleanup card regression. `LegacyTasksNotificationCard` used archived-task count only, while `MaintenanceReorganizedCard` already had an account-age gate. The main session applied the same Phase 66 account-created-before-release gate and verified the card disappears for the May 10 fixture. This shipped in `b0dbc64c`.

## Persistence Audit

A3.1 persistence is verified:

- `A3R Trash Wed 1617`: `routine_kind=trash`, `cadence_type=weekly`, `days_of_week=[4]`, `evening_before_reminder=true`.
- `A3R Cleaning Biweekly 1631`: `routine_kind=cleaning`, `cadence_type=biweekly`, Cleaning Service vendor linked.
- `A3R Snow Dec Apr Edited 1641`: single existing row updated, `cadence_type=annual`, `active_months=[1,2,3,4,12]`.

DB evidence: `/tmp/codex-logs/a3-db-evidence-1778444632.json`, `/tmp/codex-logs/a3-db-evidence-cleaning-1778445249.json`, `/tmp/codex-logs/a3-db-evidence-snow-1778445540.json`, `/tmp/codex-logs/a3-db-evidence-edit-1778445758.json`.

A3.2 persistence is verified:

- Archive: `A3R Snow Dec Apr Edited 1641` persisted `archived_at` in `/tmp/codex-logs/a3-db-evidence-archive-1778446204.json` and disappeared from Active Programs after route refresh.
- Chez handoff: `A3R Cleaning Biweekly 1631` persisted `chez_owned=true` and created `chez_requests` row `f2437ca1-f14e-4434-ad5a-2222baac5b72` with summary `Standing engagement: A3R Cleaning Biweekly 1631`.
- Pause/resume: pause persisted `setup_state='paused'`, `is_paused=true`; resume persisted `setup_state='active'`, `is_paused=false`. Evidence: `/tmp/codex-logs/a3-db-evidence-refresh-pause-1778448072.json`, `/tmp/codex-logs/a3-db-evidence-refresh-resume-1778448311.json`.

## UI Quality Audit

A1 UI quality evidence now exists from direct simulator screenshots. Dashboard, property recap, and chapter intro/question screens use Chez branding, and the chapter intro controls render with stable full-width touch targets. Screenshot set: `/tmp/codex-screenshots/a1-direct/00-dashboard-start-quiz.png` through `/tmp/codex-screenshots/a1-direct/08-q24-after-ch3-intro.png`.

Authenticated Dashboard smoke evidence also exists at `/tmp/codex-screenshots/auth-bootstrap-dashboard-2.png`. The screen uses Chez branding and confirms the simulator is no longer stuck on login before A3/A5/A6.

A5 runtime verification confirmed Settings navigation and local navy list-row icon styling across the visited rows. Evidence set: `/tmp/codex-screenshots/a5-settings/00-settings-top.png` through `/tmp/codex-screenshots/a5-settings/19-delete-account-confirmation.png`. The fixed Chez profile/delegation icons, Household Access copy, Security Dashboard copy, Visit Reminders toggle, and Contact Support area were all revisited after `5aa507fc`.

A6 Dashboard issues shipped in `5aa507fc` and were verified at runtime: schedule link routing, Recent Activity visible count, and nested snooze control behavior.

A3.2 visual behavior is verified after `1524529d`: the same open Routine Detail screen switches to `Paused` with `No visits projected yet` after pause, then back to `Active` with projected visits after resume. Screenshots: `/tmp/codex-screenshots/a3-direct/17-pause-save-refreshes-detail-immediately.png`, `/tmp/codex-screenshots/a3-direct/18-resume-save-refreshes-detail-immediately.png`.

A6 runtime evidence now covers the Dashboard top and mid-scroll order, coverage hero, Needs Your Attention, Upcoming, quick actions, activity feed, and post-fix cleanup-card absence. Key screenshots: `/tmp/codex-screenshots/a6-dashboard/00-dashboard-top-loaded.png`, `/tmp/codex-screenshots/a6-dashboard/02-dashboard-needs-upcoming.png`, `/tmp/codex-screenshots/a6-dashboard/09-recent-activity-log.png`, and `/tmp/codex-screenshots/a6-dashboard/12-dashboard-after-legacy-card-fix.png`.

## Product Gaps

A2 found four deferred gaps in the mode-fork waitlist path:

- Row 2.34: out-of-coverage waitlist path is unreachable because coverage resolution currently returns true unconditionally.
- Row 2.35: waitlist storage exists, but homeowner insert appears blocked by RLS.
- Row 2.36: mode fork lacks a back affordance to return to foundational questions.
- Row 2.37: the optional decide-later path exists in the component but is not wired from production onboarding.

A5 found deferred Settings/product gaps:

- Row 14.2: Profile currently edits full name only; email/phone/avatar require model/product support.
- Row 14.8: Security Settings only exposes Change Password; biometric toggle, vault timeout, and passcode controls expected by the matrix are absent or moved.
- Unknown Settings row: `RequestAssessmentView` appears unreachable from production Settings.
- Row 14.6: Alfred copy in a Settings-linked household email surface needs product confirmation before broad brand replacement.

A6 found deferred Dashboard product/spec gaps:

- Row 19.14: Dashboard bottom-section composition appears to omit matrix-listed surfaces and needs product/spec confirmation.
- Row 19.18: global What If FAB was intentionally removed in code but remains in the matrix; restoring it needs product confirmation.

A3.2 verification constraint:

- Rows 2.109-2.110: `PickupDayBanner` uses live `Date()` and gates evening-before at 18:00+ and morning-of before 10:00. The A3.2 simulator run happened outside both windows, so these rows are deferred rather than guessed.

## Matrix Verification Summary

Control ledger: `/tmp/codex-results/round-a-ledger.jsonl`.

Section 1d chapter intro rows 1.19-1.23 are PASS. The first bounded worker stopped before UI driving, so the coordinator reran with a fresh fixture. Evidence covers Dashboard quiz launch, property recap, Chapter 1 intro before Q1, Chapter 2 intro on resume, no repeat intro on the next Chapter 2 question, and Chapter 3 intro on resume.

Section 2c mode fork waitlist rows 2.34-2.37 failed. The failures are documented in `Tests/e2e/HOMEOWNER_GAPS.md`; coverage matching/RLS/lifecycle behavior are deferred under the Round A fix policy.

Section 2i A3.1 rows 2.96-2.105 were PARTIAL on the first attempt because the worker did not get past unauthenticated screens. Main-session auth unblocking was verified, then the coordinator reran the batch directly.

The first authenticated A3.1 rerun failed on a dashboard bootstrap crash before PropertyDetailView. The crash was fixed and verified by relaunch before the successful direct A3.1 pass.

A3.1 after the crash fix is now PASS by direct simulator verification. Rows 2.96-2.105 covered Add routine, weekly trash with reminder persistence, strict cleaning vendor filtering plus add-contractor path, biweekly cleaning persistence, snow Dec-Apr active months via preset plus Apr chip, and edit-without-duplicate persistence.

A3.2 rows 2.106-2.108 and 2.111-2.115 are PASS by direct simulator and DB verification. Archive persisted and removed the snow routine from Active Programs after refresh; routine occurrences rendered on Maintenance and Routine Detail; Chez ownership created a standing request; pause suppressed future projections; resume restored active projections. Rows 2.109-2.110 are DEFERRED to a valid PickupDayBanner clock window or DEBUG test-clock hook.

Section 3 backend combinatorial rows 3.1-3.36 passed through `Tests/e2e/run.mjs`. Some matrix labels are older than the current merged-question model, so the runner verifies the current persisted equivalents: Q3 includes the former Q3b HVAC subtype, Q11 includes the former Q11b lawn type payload, Q22 supports natural gas/propane/diesel generator fuel, Q25 includes EV charger payload, Q26 combines auto/home insurance, and the current chapter boundaries are Q22 to Q36 and Q19 to Q24.

Section 14 Settings rows 14.1-14.19 have runtime PARTIAL evidence. A5 covered Your Chez Profile, Profile, Family Members, Household & Access, Household Staff, Household Email, Security Dashboard, Security Settings, Trusted Contacts, Notifications, Home Details, Maintenance Preferences, Handyman Preference, Task Routing, Family Reference Binder, About rows, Sign Out confirmation, Delete Account first warning, and whole-list navy icon tint. Full-name profile edit persistence was confirmed in `/tmp/codex-logs/a5-profile-db-evidence-admin-1778451562.json`. Deferred gaps remain for profile edit scope, Security Settings expected controls, unreachable RequestAssessmentView, and Alfred naming confirmation.

Section 19 Dashboard rows 19.1-19.28 have runtime PARTIAL evidence. PASS evidence covers compact greeting and seasonal tip, HomeCoverageHero numbers and destination navigation, QuickActionsRow and all four quick-action destinations, 60-day Needs Your Attention/Upcoming surfaces, `View schedule` to Maintenance calendar, snooze persistence to 2026-05-22, Recent Activity visible count plus activity log route, and tab-tap reset to Dashboard root. Row 19.25 is fixed by `b0dbc64c`. Deferred product/spec gaps remain for bottom-section composition and the removed global What If FAB.

## Backend Regression Status

PASS. `node Tests/e2e/run.mjs` completed with 0 issues after the A4 backend combinatorial extension.

## Open Questions

None from this Round A session yet.

## Next-Session Priority

Round A is signed off for this bounded run. Next session priority is Round C, only if explicitly instructed to continue.
