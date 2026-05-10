# Homeowner Complete Overnight E2E Report

Run date: 2026-05-10
Branch: `claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG`
Canonical matrix: `Tests/e2e/HOMEOWNER_COMPLETE_TEST_MATRIX.md`

## TL;DR

Round A is in progress. The login wall is no longer blocking simulator QA: a fresh backend fixture was seeded, the app was launched through a simulator-only e2e login bootstrap, and the UI landed on the authenticated homeowner Dashboard.

## Round A Status

| Batch | Matrix rows | Status | Evidence |
|---|---:|---|---|
| Prior locked evidence | See below | Prior PASS | Prior commits trusted unless regression surfaces |
| A1 - Section 1d chapter intro card | 1.19-1.23 | PARTIAL | `/tmp/codex-logs/a1-build-20260510150822.log`, `/tmp/codex-logs/a1-seed-20260510150822.log`; no UI screenshots before minute-25 stop |
| A2 - Section 2c mode fork waitlist path | 2.34-2.37 | FAIL | `/tmp/codex-logs/a2-xcodebuild.log`, `/tmp/codex-screenshots/a2/address-no-address-found.png` |
| A3 - Section 2i routines lifecycle | 2.96-2.115 | In progress | Initial A3.1 was PARTIAL due auth/login automation; authenticated Dashboard verified at `/tmp/codex-screenshots/auth-bootstrap-dashboard-2.png`; duplicate Landscaping bootstrap crash fixed and verified at `/tmp/codex-screenshots/day1-duplicate-routine-dashboard.png`; A3.1 rerun continues |
| A4 - Section 3 backend combinatorial | 3.1-3.36 | PASS | `/tmp/codex-logs/run-1778439978.log` |
| A5 - Section 14 settings subscreens | 14.1-14.19 | Static PARTIAL | Static scan complete; low-risk tint/copy/toggle/support fixes applied locally; simulator navigation/persistence pass pending |
| A6 - Section 19 dashboard interactions | 19.1-19.28 | Static PARTIAL | Static scan complete; low-risk route/count/snooze fixes applied locally; simulator interaction pass pending |

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

## Bugs Found And Fixed

- A4 backend runner coverage was extended and shipped in `97e16e86`. `node Tests/e2e/run.mjs` passed with 0 issues.
- Simulator QA was blocked at login/auth setup. The main session added a debug-simulator e2e fixture login bootstrap and made email/password sign-in update auth state immediately after Supabase returns. Build passed in `/tmp/codex-logs/build-auth-bootstrap-1778441799.log`; commit is pending the A3 rerun result.
- A3.1 rerun exposed a critical authenticated launch crash: duplicate `Landscaping` keys in Day1TaskCurator's routine category map. The main session patched duplicate-tolerant dictionary construction and verified the same fixture relaunches to Dashboard. Build log: `/tmp/codex-logs/build-day1-duplicate-routine-1778442503.log`.
- A5 static scan found authorized low-risk Settings fixes. Main-session patches replaced salmon decorative Chez delegation icons with navy styling, removed em dashes from security/access copy, switched Contact Support to `AppConfig.supportEmail`, and exposed the existing Visit Reminders notification preference.
- A6 static scan found authorized low-risk Dashboard fixes. Main-session patches route Needs Your Attention schedule links to the calendar, show up to seven Recent Activity events, and split the snooze button out of nested row navigation.

## Persistence Audit

Pending batch execution.

## UI Quality Audit

A1 has no UI quality evidence yet because the simulator worker stopped before active UI driving.

Authenticated Dashboard smoke evidence exists at `/tmp/codex-screenshots/auth-bootstrap-dashboard-2.png`. The screen uses Chez branding and confirms the simulator is no longer stuck on login before A3/A5/A6.

A5 static scan found Settings UI quality issues now patched locally: salmon decorative icons in Chez profile/delegations, em dashes in Security and Household Access copy, and the Tom support email link. Runtime visual confirmation is still pending.

A6 static scan found Dashboard issues now patched locally: schedule link routing, Recent Activity visible count, and nested snooze control behavior. Runtime interaction confirmation is still pending.

## Product Gaps

A2 found four deferred gaps in the mode-fork waitlist path:

- Row 2.34: out-of-coverage waitlist path is unreachable because coverage resolution currently returns true unconditionally.
- Row 2.35: waitlist storage exists, but homeowner insert appears blocked by RLS.
- Row 2.36: mode fork lacks a back affordance to return to foundational questions.
- Row 2.37: the optional decide-later path exists in the component but is not wired from production onboarding.

A5 static scan found deferred Settings/product gaps:

- Row 14.2: Profile currently edits full name only; email/phone/avatar require model/product support.
- Unknown Settings row: `RequestAssessmentView` appears unreachable from production Settings.
- Row 14.6: Alfred copy in a Settings-linked household email surface needs product confirmation before broad brand replacement.
- Row 19.14: Dashboard bottom-section composition appears to omit matrix-listed surfaces and needs product/spec confirmation.
- Row 19.18: global What If FAB was intentionally removed in code but remains in the matrix; restoring it needs product confirmation.

## Matrix Verification Summary

Control ledger: `/tmp/codex-results/round-a-ledger.jsonl`.

Section 1d chapter intro rows 1.19-1.23 are PARTIAL. The app build and fixture seed succeeded, but the worker did not reach simulator UI verification before the bounded stop.

Section 2c mode fork waitlist rows 2.34-2.37 failed. The failures are documented in `Tests/e2e/HOMEOWNER_GAPS.md`; coverage matching/RLS/lifecycle behavior are deferred under the Round A fix policy.

Section 2i A3.1 rows 2.96-2.105 were PARTIAL on the first attempt because the worker did not get past unauthenticated screens. Main-session auth unblocking is verified and the A3.1 rerun is in progress.

The first authenticated A3.1 rerun failed on a dashboard bootstrap crash before PropertyDetailView. The crash is fixed locally and verified by relaunch; A3.1 routine UI verification still needs rerun evidence.

A3.1 after the crash fix is PARTIAL. Rows 2.97-2.98 have partial pass evidence for weekly Wednesday trash persistence, but the evening-before reminder was not enabled before save. Rows 2.99-2.100 found a contractor-picker category bug for cleaning when no matching contractor exists; the picker now keeps strict category filtering and will show the add-contractor path instead of unrelated vendors. Rows 2.101-2.105 remain incomplete.

Section 3 backend combinatorial rows 3.1-3.36 passed through `Tests/e2e/run.mjs`. Some matrix labels are older than the current merged-question model, so the runner verifies the current persisted equivalents: Q3 includes the former Q3b HVAC subtype, Q11 includes the former Q11b lawn type payload, Q22 supports natural gas/propane/diesel generator fuel, Q25 includes EV charger payload, Q26 combines auto/home insurance, and the current chapter boundaries are Q22 to Q36 and Q19 to Q24.

Section 14 Settings rows 14.1-14.19 have static PARTIAL evidence. Simulator navigation, visual tint verification, and persistence checks remain pending.

Section 19 Dashboard rows 19.1-19.28 have static PARTIAL evidence. Low-risk issues are fixed locally; simulator quick-action, snooze, schedule, activity, and FAB verification remains pending.

## Backend Regression Status

PASS. `node Tests/e2e/run.mjs` completed with 0 issues after the A4 backend combinatorial extension.

## Open Questions

None from this Round A session yet.

## Next-Session Priority

Complete Round A signoff before starting Round C.
