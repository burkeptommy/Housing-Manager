# Homeowner Round A Gaps

Source matrix: `Tests/e2e/HOMEOWNER_COMPLETE_TEST_MATRIX.md`
Run started: 2026-05-10
Branch: `claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG`

## Status Legend

- `open`: verified gap still needs a product or engineering decision.
- `fixed`: fixed, rebuilt or re-run, committed, and pushed.
- `deferred`: documented because the fix exceeds the Round A immediate-fix policy.
- `not_reproduced`: investigated and not observed in the current run.

## Section 1d - Chapter Intro Card

### Rows 1.19-1.23 - Chapter intro cards render once per chapter

- Category: `verification`
- Severity: `none`
- Evidence: The initial A1 worker stopped before active UI driving, but the coordinator reran A1 with fresh fixture `e2e-a1-chapter-intro-1778449061906@havenhome.test`. The app launched through the simulator e2e login bootstrap to Dashboard, opened the quiz card, showed the property recap, rendered Chapter 1 before Q1, rendered Chapter 2 from a saved DB resume state, suppressed the Chapter 2 intro on the next in-chapter question, and rendered Chapter 3 from a saved DB resume state. Screenshots: `/tmp/codex-screenshots/a1-direct/00-dashboard-start-quiz.png`, `/tmp/codex-screenshots/a1-direct/02-chapter-1-intro.png`, `/tmp/codex-screenshots/a1-direct/03-q1-after-ch1-intro.png`, `/tmp/codex-screenshots/a1-direct/04-chapter-2-intro-resume.png`, `/tmp/codex-screenshots/a1-direct/06-q11-no-repeat-ch2-intro.png`, `/tmp/codex-screenshots/a1-direct/07-chapter-3-intro-resume.png`.
- Reproduction: Seed a fresh incomplete homeowner property, launch with the simulator e2e login bootstrap, start the House Quiz from Dashboard, and then resume the same property with Chapter 1 and Chapter 1+2 answer maps to verify chapter-boundary behavior.
- Suggested fix: None.
- Status: `not_reproduced`

## Section 2c - Mode Fork Waitlist Path

### Row 2.34 - Out-of-coverage waitlist tile unreachable

- Category: `gap_found`
- Severity: `critical`
- Evidence: `OnboardingViewModel.resolveCoverageAvailability(propertyId:)` returns `true` unconditionally, while `OnboardingModeForkView` only renders `waitlistCard` when `coverageAvailable == false`. Simulator evidence at `/tmp/codex-screenshots/a2/address-no-address-found.png` also shows the requested Cheyenne address could not be selected during pre-auth address entry.
- Reproduction: Sign up with `100 N Federal Ave, Cheyenne, WY 82001` or any out-of-coverage state, complete foundational onboarding, and observe that the mode fork cannot naturally render the waitlist tile.
- Suggested fix: Wire coverage resolution to a real state/zip/provider workspace lookup and provide a deterministic manual/fallback address path for unsupported address search results.
- Status: `deferred`

### Row 2.35 - Waitlist insert appears blocked for homeowners

- Category: `persistence_finding`
- Severity: `major`
- Evidence: `DatabaseService.insertChezAssessmentWaitlist(...)` writes to `chez_assessment_waitlist`, but `supabase/migrations/20261210_chez_home_assessment.sql` defines homeowner `SELECT` and admin `FOR ALL` policies only. No authenticated homeowner `INSERT` or `UPSERT` policy is present.
- Reproduction: Force `coverageAvailable = false`, tap the waitlist tile as a normal homeowner, and inspect `chez_assessment_waitlist` for the property. The insert is expected to fail or silently fall through to DIY because RLS lacks homeowner write permission.
- Suggested fix: Add a constrained authenticated insert/upsert policy for the caller's own household/property/user.
- Status: `deferred`

### Row 2.36 - Mode fork has no back affordance

- Category: `gap_found`
- Severity: `major`
- Evidence: `OnboardingModeForkView` defines callbacks for quiz, handyman, waitlist, and optional decide-later, but no back callback or visible back control. The rendered body/footer contain no back affordance.
- Reproduction: Complete foundational questions and land on the mode fork. There is no user-visible control to return to the last foundational question.
- Suggested fix: Add a visible Back control that flips the onboarding state back to foundational questions while preserving the answers already entered.
- Status: `deferred`

### Row 2.37 - Decide-later path is not wired in production onboarding

- Category: `gap_found`
- Severity: `major`
- Evidence: `OnboardingModeForkView` has optional `onDecideLater`, but `OnboardingView` instantiates the fork without passing it, so the decide-later link is not shown.
- Reproduction: Complete foundational questions and land on the mode fork. No dismiss/cancel/decide-later route is available.
- Suggested fix: Define product-safe lifecycle behavior for leaving onboarding incomplete, then pass a handler from `OnboardingView` and verify relaunch state.
- Status: `deferred`

## Section 2i - Routines Lifecycle

### A3.1 initial run - simulator login blocked routine UI verification

- Category: `verification`
- Severity: `major`
- Evidence: A3.1 reached only unauthenticated auth/welcome screens, so rows 2.96-2.99 and 2.101-2.105 were not exercised in UI. The ad hoc fixture script also used a stale anon key and failed signup with 401 in `/tmp/codex-logs/a3-fixture-20260510152550.log`.
- Reproduction: Launch the simulator without a pre-seeded authenticated homeowner fixture and attempt to drive PropertyDetailView/RoutineEditSheet from a fresh app state.
- Suggested fix: Use the debug-simulator e2e login bootstrap with a seeded `e2e-test-*` homeowner before running simulator QA. Main-session evidence: `/tmp/codex-screenshots/auth-bootstrap-dashboard-2.png`.
- Status: `fixed` by `5aa507fc` and verified by direct A3.1 simulator rerun.

### Row 2.96 - Authenticated dashboard crash on duplicate Landscaping routine categories

- Category: `gap_found`
- Severity: `critical`
- Evidence: A3.1 rerun launched with the seeded fixture and crashed before PropertyDetailView. `/tmp/codex-logs/a3-rerun-crash-summary.log` shows `Swift/NativeDictionary.swift:792: Fatal error: Duplicate values for key: 'Landscaping'`.
- Reproduction: Seed the A4 combinatorial homeowner fixture, launch the iOS app with the e2e login bootstrap, and wait for dashboard bootstrap. The fixture has multiple Landscaping-family routines, which previously trapped in `Day1TaskCurator`.
- Suggested fix: Use duplicate-tolerant dictionary construction for active/pending vendor routines keyed by primary category. Main-session patch applied in `Haven/Features/Property/Services/Day1TaskCurator.swift` and verified by relaunch screenshot `/tmp/codex-screenshots/day1-duplicate-routine-dashboard.png`.
- Status: `fixed` by `5aa507fc` and verified by direct A3.1 simulator rerun.

### Rows 2.97-2.98 - Weekly trash routine created, reminder not enabled in partial run

- Category: `persistence_finding`
- Severity: `major`
- Evidence: Initial A3.1 rerun created `A3 Trash Wed 1556` with `evening_before_reminder=false` because the worker did not reach the control before save. Direct rerun created `A3R Trash Wed 1617` with `routine_kind=trash`, `cadence_type=weekly`, `days_of_week=[4]`, and `evening_before_reminder=true`. DB evidence: `/tmp/codex-logs/a3-db-evidence-1778444632.json`.
- Reproduction: Add a weekly Wednesday trash routine from Property > Maintenance > Add routine and verify the evening-before reminder toggle before saving.
- Suggested fix: None remaining for this row.
- Status: `not_reproduced`

### Rows 2.99-2.100 - Contractor picker fell back to unrelated vendors for cleaning

- Category: `ui_quality_finding`
- Severity: `major`
- Evidence: A3.1 rerun opened `ContractorPickerSheet` for a cleaning routine and saw mixed categories including Chimney, Electrical, Landscaping, HVAC, Pest, Plumbing, and Trash & Recycling. Direct rerun after rebuilding and reinstalling the `5aa507fc` app showed `No Matching Contractors` for Cleaning Service, then the add-contractor path created `A3R Cleaning Co 1629` and saved `A3R Cleaning Biweekly 1631` with `cadence_type=biweekly` and a Cleaning Service vendor. Screenshots: `/tmp/codex-screenshots/a3-direct/03-cleaning-picker-strict-empty.png`, `/tmp/codex-screenshots/a3-direct/04-cleaning-biweekly-saved.png`. DB evidence: `/tmp/codex-logs/a3-db-evidence-cleaning-1778445249.json`.
- Reproduction: Add a biweekly cleaning routine and open the contractor picker when the household has no Cleaning Service contractor.
- Suggested fix: Keep category filtering strict and show the empty/add-contractor state when no category match exists. Main-session patch applied in `Haven/Features/Property/Views/ContractorPickerSheet.swift`.
- Status: `fixed` by `5aa507fc` and verified by direct A3.1 simulator rerun.

### Rows 2.101-2.105 - A3.1 seasonal/edit rows incomplete

- Category: `verification`
- Severity: `major`
- Evidence: Initial A3.1 rerun reached snow routine annual cadence and active-month chip editing but cancelled the unsaved draft at stop time. Direct rerun saved `A3R Snow Dec Apr 1636` with `cadence_type=annual` and `active_months=[1,2,3,4,12]`, verified the chip summary `Active December through April`, and edited the same row to `A3R Snow Dec Apr Edited 1641` without creating a duplicate. Screenshots: `/tmp/codex-screenshots/a3-direct/05-snow-dec-apr-summary.png`, `/tmp/codex-screenshots/a3-direct/06-snow-saved-active-programs.png`. DB evidence: `/tmp/codex-logs/a3-db-evidence-snow-1778445540.json`, `/tmp/codex-logs/a3-db-evidence-edit-1778445758.json`.
- Reproduction: Continue A3.1/A3.2 after current fixes, saving snow Dec-Apr, quick presets, active month exclusion, and edit-without-duplicate behavior.
- Suggested fix: None remaining for A3.1.
- Status: `not_reproduced`

### Rows 2.109-2.110 - PickupDayBanner evening/morning windows not live-verifiable in current simulator window

- Category: `verification`
- Severity: `none`
- Evidence: A3.2 was driven between 16:56 and 17:24 EDT on 2026-05-10. `PickupDayBanner` gates evening-before display at `hour >= 18` and morning-of display at `hour < 10` using live `Date()`, with no debug test-clock override. The waste routine reminder persistence itself is verified in `/tmp/codex-logs/a3-db-evidence-1778444632.json`.
- Reproduction: Launch the same fixture after 18:00 local time for evening-before behavior or before 10:00 local time on pickup morning for morning-of behavior, or add an explicit DEBUG-only clock override for `PickupDayBanner`.
- Suggested fix: No product fix is indicated from this run. Add test-clock plumbing if these rows need deterministic simulator verification outside the natural time windows.
- Status: `deferred`

### Rows 2.114-2.115 - Paused routines still projected upcoming visits until the detail view refreshed

- Category: `persistence_finding`
- Severity: `major`
- Evidence: Before the fix, `A3R Cleaning Biweekly 1631` persisted `setup_state='paused'` and `is_paused=true` in `/tmp/codex-logs/a3-db-evidence-routine-paused-1778446734.json`, but Routine Detail still showed projected upcoming visits (`/tmp/codex-screenshots/a3-direct/13-paused-detail-still-shows-upcoming.png`). After `1524529d`, pause immediately renders `Paused` with `No visits projected yet` (`/tmp/codex-screenshots/a3-direct/17-pause-save-refreshes-detail-immediately.png`), and resume immediately renders `Active` with projected visits (`/tmp/codex-screenshots/a3-direct/18-resume-save-refreshes-detail-immediately.png`). DB evidence: `/tmp/codex-logs/a3-db-evidence-refresh-pause-1778448072.json`, `/tmp/codex-logs/a3-db-evidence-refresh-resume-1778448311.json`.
- Reproduction: Open `A3R Cleaning Biweekly 1631`, edit the routine, toggle Pause on, save, then observe the open detail screen. Repeat by toggling Pause off and saving.
- Suggested fix: Suppress upcoming previews for paused/archived routines and refetch the routine row when Routine Detail reloads after an edit save. Main-session patch applied in `Haven/Features/Property/Models/Routine.swift` and `Haven/Features/Property/Views/RoutineDetailView.swift`.
- Status: `fixed` by `1524529d`

## Section 3 - Backend Combinatorial Coverage

No current-run findings yet.

## Section 14 - Settings Subscreens

### Row 14.1 - Chez delegation/profile icons used salmon decoration

- Category: `ui_quality_finding`
- Severity: `moderate`
- Evidence: Static scan found custom icon circles in `ChezProfileView` and `ChezDelegationsListView` using `HavenColors.action` salmon for non-CTA decorative Settings-style icons.
- Reproduction: Open Settings > Your Chez profile / View what Chez owns and inspect the icon tint/background on the hero, list rows, and empty state.
- Suggested fix: Use navy icons with the indigo wash for non-CTA icon compositions. Main-session patch applied in `Haven/Features/ChezRequests/Views/ChezProfileView.swift` and `Haven/Features/ChezRequests/Views/ChezDelegationsListView.swift`.
- Status: `fixed` by `5aa507fc`; runtime A5 verification captured in `/tmp/codex-screenshots/a5-settings/01-chez-profile.png` and `/tmp/codex-screenshots/a5-settings/02-profile-view.png`.

### Row 14.2 - Profile edit scope exceeds current model

- Category: `gap_found`
- Severity: `major`
- Evidence: Matrix expects edit name/email/phone/avatar, but `ProfileView` only edits full name. `UserRow` / `UserUpdate` do not expose phone or avatar fields. Runtime A5 verified the supported full-name edit persisted to `users.full_name='A1 ChapterIntro QA'`; evidence: `/tmp/codex-logs/a5-profile-db-evidence-admin-1778451562.json`.
- Reproduction: Open Settings > Profile. Email and role render read-only; no phone/avatar edit controls exist.
- Suggested fix: Either narrow row 14.2 to name-only or add supported user profile fields plus edit UI/persistence for email, phone, and avatar.
- Status: `deferred`

### Row 14.4 - Household access copy contained an em dash

- Category: `ui_quality_finding`
- Severity: `minor`
- Evidence: `HouseholdAccessView` sharing explainer used `\u{2014}` in user-facing copy.
- Reproduction: Open Settings > Household & Access and inspect Linked accounts explainer copy.
- Suggested fix: Rephrase without em dash. Main-session patch applied in `Haven/Features/Settings/HouseholdAccessView.swift`.
- Status: `fixed` by `5aa507fc`; runtime A5 verification captured in `/tmp/codex-screenshots/a5-settings/04-household-access.png`.

### Row 14.7 - Security dashboard copy contained em dashes

- Category: `ui_quality_finding`
- Severity: `moderate`
- Evidence: `SecurityDashboardView` had four user-facing `\u{2014}` strings in security and Vault Lock copy.
- Reproduction: Open Settings > Security and inspect the security dashboard and Vault Lock explanatory sections.
- Suggested fix: Rephrase without em dashes. Main-session patch applied in `Haven/Features/Security/SecurityDashboardView.swift`.
- Status: `fixed` by `5aa507fc`; runtime A5 verification captured in `/tmp/codex-screenshots/a5-settings/07-security-dashboard.png`.

### Row 14.8 - Security Settings missing expected controls

- Category: `gap_found`
- Severity: `moderate`
- Evidence: Runtime A5 navigation reached Settings > Security Settings, but the screen only exposed `Change Password`. The matrix expects biometric toggle, vault timeout, and passcode controls. Screenshot: `/tmp/codex-screenshots/a5-settings/09-security-settings.png`.
- Reproduction: Open Settings > Security Settings on an authenticated homeowner account.
- Suggested fix: Add and wire the biometric, vault timeout, and passcode controls if still required, or update row 14.8 if those controls moved or were intentionally removed.
- Status: `deferred`

### Row 14.10 - Visit reminders preference was hidden from Settings

- Category: `gap_found`
- Severity: `moderate`
- Evidence: `NotificationPreferences` includes `visitReminders` and `NotificationScheduler` honors it, but `NotificationSettingsView` did not expose a toggle.
- Reproduction: Open Settings > Notifications. Document, property, and digest toggles are visible, but Visit Reminders is absent.
- Suggested fix: Add a Visit Reminders toggle bound to `prefs.visitReminders`. Main-session patch applied in `Haven/Features/Notifications/NotificationSettingsView.swift`.
- Status: `fixed` by `5aa507fc`; runtime A5 verification captured in `/tmp/codex-screenshots/a5-settings/11-notifications-visit-reminders.png`.

### Row 14.16 - Contact Support used Tom address

- Category: `ui_quality_finding`
- Severity: `minor`
- Evidence: `SettingsView` linked Contact Support to `tom@getchez.com` while `AppConfig.supportEmail` is `support@getchez.com`.
- Reproduction: Open Settings > About > Contact Support and inspect the mailto destination.
- Suggested fix: Use `AppConfig.supportEmail`. Main-session patch applied in `Haven/Features/Settings/SettingsView.swift`.
- Status: `fixed` by `5aa507fc`; runtime A5 bottom-section verification captured in `/tmp/codex-screenshots/a5-settings/17-settings-about-actions.png`, `/tmp/codex-screenshots/a5-settings/18-sign-out-confirmation.png`, and `/tmp/codex-screenshots/a5-settings/19-delete-account-confirmation.png`.

### Unknown Settings row - RequestAssessmentView appears unreachable

- Category: `gap_found`
- Severity: `moderate`
- Evidence: `RequestAssessmentView` is documented as a Settings entry, but static scan found no production constructor or Settings route.
- Reproduction: Search Settings navigation entries for Request a Chez visit; no route appears wired to `RequestAssessmentView`.
- Suggested fix: Add a Settings route with property/household wiring if this remains a product requirement, or remove/rename the dead entry if it moved elsewhere.
- Status: `deferred`

### Row 14.6 - Alfred copy may be stale brand naming

- Category: `ui_quality_finding`
- Severity: `minor`
- Evidence: Settings-linked Household Email / ProjectEmail surfaces still show ALFRED/Alfred copy. This may be deliberate because the main tab still includes Alfred, so it needs product confirmation before broad replacement.
- Reproduction: Open Settings-linked household email flow and inspect visible labels.
- Suggested fix: Confirm whether Alfred remains a deliberate homeowner-facing brand; if not, replace visible Alfred labels with Chez while preserving internal identifiers.
- Status: `deferred`

## Section 19 - Dashboard Quick Actions And Interactions

### Row 19.6 - Needs Your Attention See all route landed on hub, not calendar

- Category: `gap_found`
- Severity: `moderate`
- Evidence: Static scan found the live `ThisWeekSection` See all action appended `maintenance`, while `maintenance_calendar` is the route that opens `MaintenanceScheduleView(initialLayout: .calendar)`.
- Reproduction: On Dashboard, tap Needs Your Attention > See all and observe it routes to the maintenance hub instead of the calendar layout.
- Suggested fix: Route both full-schedule affordances to `maintenance_calendar`. Main-session patch applied in `Haven/Features/Dashboard/DashboardView.swift`.
- Status: `fixed` by `5aa507fc`; runtime A6 verified `View schedule` lands on `MaintenanceScheduleView` calendar layout in `/tmp/codex-screenshots/a6-dashboard/01-view-schedule-calendar.png`.

### Row 19.7 - Snooze button nested inside row navigation

- Category: `persistence_finding`
- Severity: `moderate`
- Evidence: Static scan found `ThisWeekSection` wrapped the full row in a `Button`, then placed the snooze `Button` inside that row label. The persistence path itself exists in `DashboardViewModel.snoozeTask`.
- Reproduction: On Dashboard Needs Your Attention, tap the zzz affordance and verify whether it snoozes or opens task detail.
- Suggested fix: Split the row tap target and snooze button into sibling controls. Main-session patch applied in `Haven/Features/Dashboard/Components/ThisWeekSection.swift`.
- Status: `fixed` by `5aa507fc`; runtime A6 verified snooze persisted `Spring cleanup` from 2026-05-15 to 2026-05-22 in `/tmp/codex-logs/a6-snooze-db-evidence-1778451950.json`.

### Row 19.12 - Recent Activity visible count and source coverage incomplete

- Category: `gap_found`
- Severity: `moderate`
- Evidence: `DashboardView` passed only the first 3 events to `RecentActivityFeed`, and static scan found TODOs for scenario, recall, and gap-analysis event sources.
- Reproduction: On a post-quiz Dashboard with many events, inspect Recent Activity visible count and event types.
- Suggested fix: Pass up to 7 events from Dashboard; add missing sources in a later product-backed pass. Main-session patch applied for the visible count in `Haven/Features/Dashboard/DashboardView.swift`; missing event sources remain deferred.
- Status: `fixed` by `5aa507fc` for visible count; runtime A6 verified seven visible events and `View all` activity navigation in `/tmp/codex-screenshots/a6-dashboard/09-recent-activity-log.png`. Missing event sources remain `deferred`.

### Row 19.14 - Dashboard bottom sections appear unrendered

- Category: `gap_found`
- Severity: `moderate`
- Evidence: Static scan found `FoundationCard`, forwarding email callout, `HouseholdStrip`, and `HouseholdStaffStrip` definitions/data but no `DashboardView` call sites.
- Reproduction: Scroll the post-quiz Dashboard bottom sections and compare to the Section 19 expected surfaces.
- Suggested fix: Render the expected bottom surfaces in the dashboard stack or update the matrix/spec if intentionally removed.
- Status: `deferred`

### Row 19.18 - Global What If FAB removed

- Category: `gap_found`
- Severity: `major`
- Evidence: `MainTabView` comments indicate the floating What If FAB was removed. Scenario Studio still opens from other entry points, but the matrix expects a global FAB on every tab except Alfred with collapse-after-first-use behavior.
- Reproduction: Open non-Alfred tabs and inspect for the global sparkles FAB.
- Suggested fix: Restore the global FAB using the existing `.openScenarioStudio` full-screen route if this remains the product requirement.
- Status: `deferred`

### Row 19.25 - Legacy cleanup card shown to new signup

- Category: `ui_quality_finding`
- Severity: `moderate`
- Evidence: Runtime A6 showed the `WE TIDIED YOUR LIST` legacy cleanup card on a fresh fixture created 2026-05-10, even though the account was created after the Phase 66 release gate. Before-fix screenshot: `/tmp/codex-screenshots/a6-dashboard/02-dashboard-needs-upcoming.png`. After `b0dbc64c`, the same fixture relaunch no longer shows the card; evidence: `/tmp/codex-screenshots/a6-dashboard/12-dashboard-after-legacy-card-fix.png`.
- Reproduction: Launch post-quiz fixture `e2e-test-1778441875084@havenhome.test` and scroll below the quick actions.
- Suggested fix: Apply the same `accountCreatedAt < phase66ReleaseDate` gate used by `MaintenanceReorganizedCard` to `LegacyTasksNotificationCard`.
- Status: `fixed` by `b0dbc64c`

## Other Round A Notes

### Follow-up - Tasks season counts inflated by admin catalog seeding

- Category: `ui_quality_finding`
- Severity: `major`
- Evidence: Runtime A6 fixture `e2e-test-1778441875084@havenhome.test` showed the Tasks season ribbon at Spring 144, Summer 27, Fall 26, Winter 18. DB evidence in `/tmp/codex-logs/a6-season-rest-dump-1778453468.json` reproduced the app arithmetic: Spring = 121 unparented active tasks + 23 routines. Of the active tasks, 132 were due in `2027-05`, and 106 had `Admin:` template ids. Admin catalog evidence in `/tmp/codex-logs/admin-catalog-task-breakdown-1778453706.json` showed 142 active admin task rows, most without explicit system metadata or essential flags.
- Reproduction: Complete homeowner onboarding with the A6 fixture, open the Tasks tab, and inspect the seasonal count ribbon.
- Suggested fix: Make admin-authored task catalog rows opt in to Day 1 essential task seeding instead of defaulting every active admin task to essential.
- Status: `fixed` by follow-up patch in `Haven/Core/Services/AdminCatalogService.swift`; build verified in `/tmp/codex-logs/build-admin-essential-default-1778453862.log`.
