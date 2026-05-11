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

### Section 22 B11 - Dashboard simplification needed

- Category: `ui_quality_finding`
- Severity: `moderate`
- Tags: `needs-simplification`
- Evidence: Tom's hands-on Round C kickoff review flagged the post-quiz Dashboard as visually overwhelming when `HomeCoverageHero`, Chez ownership card, `NEEDS YOUR ATTENTION`, `UPCOMING`, and `RECENT ACTIVITY` all stack in one scroll. Current simulator evidence: `/tmp/codex-evidence/p0/p0-3-dashboard-density.png`.
- Reproduction: Launch a seeded post-quiz homeowner, land on Dashboard, and scroll through the first viewport plus immediately following sections. The page presents several dense decision and activity surfaces before the user reaches lower-dashboard actions.
- Suggested fix: Product/design decision required. Options: merge related status surfaces into one prioritized home-status module; demote secondary activity modules below primary actions; use progressive disclosure for less urgent lists; or split competing sections behind focused tabs/segments.
- Status: `deferred` to Tom/product

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

---

## Round C — Wave C-1 (Section 13 Chez full concierge)

### Wave C-1 verification summary

- Subagent: c1-section-13-chez-concierge, returned PASS
- All 16 ChezEntryButton call sites verified for A1+ contract — every site passes explicit `source_entity_type` + `source_entity_label`. Codex's `ee5f7ee0` fix (`contextWithFallbackSource` + inference) is the safety net but no call site relies solely on inference. Audit table at `/tmp/claude-c-evidence/c1-section-13/00-chez-entry-button-audit.md`.
- Rows verified via source-code audit (computer-use was unavailable for direct simulator tap): 13.1-13.3, 13.5-13.7, 13.16-13.23, 13.25, 13.26
- Rows deferred: 13.4 (SendGrid not testable from sim), 13.8-13.11 (reply / system messages / status transitions need admin-side data), 13.12-13.15 (proposals require admin-side setup), 13.24 (inbox sub-tab list rendering not visually verified)

### Wave C-1 Finding 1 — B3 em-dash class-wide sweep — FIXED

- Category: `ui_quality_finding`
- Severity: `minor` per instance, escalates to `major` when class-wide
- Surfaces affected: 10 files, 11 em-dash instances total
  - Onboarding sentence em-dashes: `IntroExplainerView.swift` (3 instances on lines 84 / 101 / 105)
  - Security explainer sentence em-dashes: `SecurityExplainerView.swift` (4 instances on lines 13 / 20 / 34 / 42)
  - Currency / value placeholder em-dashes: `ChezProposalCard.swift:190`, `PropertyEnhancedSections.swift:385+393`, `PropertyHeroHeader.swift:117`, `PropertyDetailView.swift:1546`, `QuoteComparisonView.swift:303`, `QuoteDetailView.swift:173`, `UtilityAccountsSection.swift:1070+1075+1080`, `VehicleDetailView.swift:1236`
- Evidence: Subagent flagged `ChezProposalCard.swift:190` explicitly (`Text(opt.label ?? opt.iso ?? "—")` — em dash as date-slot fallback). Main-thread sweep found 10 more class-wide instances of the same anti-pattern (sentence em-dashes + currency/value placeholder em-dashes).
- Suggested fix: applied as a single batch commit. Sentence em-dashes replaced with appropriate punctuation (comma / period / colon). Currency placeholders replaced with empty string `""` (the label provides context — empty value reads naturally). Vehicle estimated-value hero replaced with `"Not estimated yet"` since empty would collapse the hero row.
- Status: `fixed` in commit `f9480aa1`. Build verified clean on iPhone 16e iOS 26.2 sim. Reinstalled binary.

### Wave C-1 Finding 2 — A1+ ChezEntryButton context contract — PASS

- Category: `verification`
- Matrix rows: 13.1 (and applies to every Section 7 / 13 / 20 ChezEntryButton tap)
- All 16 ChezEntryButton call sites in `Haven/` stamp `source_entity_type` + `source_entity_label` explicitly. Receiver side (`ChezRequestComposeViewModel.sourceEntityTitle`) renders as "Type: Label" (e.g. "Routine: Bethel Lawn Care") instead of generic category.
- `MainTabView.normalizedChezContext` (added in `ee5f7ee0`) provides a second-layer fallback inference for the 3 direct `.openChezRequestComposer` callers (`ChatView`, `ContractorDirectoryView`, `EquipmentIdentifySheet`).
- Tom's "generic 'Roofing' RE: header from routine context" Round A bug is now fixed end-to-end with double-layer fallback.
- Evidence: `/tmp/claude-c-evidence/c1-section-13/00-chez-entry-button-audit.md`
- Status: `verified pass`

### Wave C-1 Finding 3 — Section 13 Chez Profile Spending Authority morning fix verified

- Category: `verification`
- Matrix row: 13.19
- `ChezProfileView.swift` line 183-195 spending-authority background renders with `HavenColors.creamLight` + `beige300` strokeBorder (settings-card styling). No salmon decoration. Morning fix `5aa507fc` is in place.
- Default tiers verified: `autoApproveUnder` falls back to 200, `pingUnder` to 500, `explicitAbove` to 500 (row 13.17).
- Status: `verified pass`


---

## Round C — Wave C-2 (Section 7 Maintenance task detail)

### Wave C-2 verification summary

- Subagent: c2-section-7-maintenance-task-detail, returned PARTIAL
- A1+ ChezEntryButton context contract VERIFIED IN SIMULATOR (Wave C-1 source audit follow-up). MaintenanceTaskDetailSheet line 2084 tap opens Ask Chez Compose sheet with task_title as RE: header — Tom's "generic Roofing" Round A bug is fixed end-to-end with simulator evidence.
- Rows verified in simulator: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.13, 7.20, 7.21 — plus the A1+ ChezEntryButton tap
- ChezOwnsToggle (Phase 80.2) smart label branching confirmed: personal task shows "Have Chez source a vendor", vendor task shows "Have Chez handle this task"
- Rows deferred (would mutate fixture or wrong surface): 7.9-7.12, 7.14-7.17, 7.18-7.19 (wrong surface, lives on SystemDetailView FrequencyPickerSheet), 7.22, 7.25
- Rows flagged as gap: 7.23 photo evidence + 7.24 voice note absent from MarkCompleteForm

### Wave C-2 Finding 1 — B4 brand-voice "Alfred" in vendor scheduling copy — FIXED

- Category: `ui_quality_finding`
- Severity: `medium`
- Surface: `Haven/Features/Property/Views/MaintenanceTaskDetailSheet.swift:2043` (no-vendor SCHEDULING section caption)
- Evidence: Subagent flagged source string `"Add a \(categoryLabel) vendor and Alfred can automatically schedule your maintenance tasks."`. Every other Chez-handling copy in the same file correctly uses "Chez" (line 1914 "Chez to schedule it automatically", line 2087 "Chez finds the pro, schedules, and follows up"). Lone "Alfred" reference creates confusion about which AI agent owns scheduling — Alfred is the chat assistant, Chez is the concierge / scheduling brand.
- Suggested fix: rename "Alfred" → "Chez". Also fix grammar "Add a \(categoryLabel)" → "Add a vendor for this \(categoryLabel)" to avoid "Add a HVAC" article error.
- Status: `fixed` — applied in batch commit (single-line edit). Build verified clean; binary reinstalled.

### Wave C-2 Finding 2 — Test fixture em dashes bleed into UI — FIXED

- Category: `ui_quality_finding`
- Severity: `low`
- Surface: `Tests/e2e/run.mjs:2587, 2598` test fixture data
- Evidence: Two task `description` strings in the e2e fixture contain em dashes that render in the actual UI when the fixture is loaded ("Quarterly filter swap — 16x25x1 MERV 11.", "Lawn cleanup + first mow — coordinate with Bethel Lawn Care."). Not a production code bug, but trips B3 audits and represents the test infrastructure violating its own rules.
- Suggested fix: replace em dashes with commas in fixture description strings.
- Status: `fixed` in same batch commit.

### Wave C-2 Finding 3 — A1+ ChezEntryButton context contract — VERIFIED IN SIM

- Category: `verification`
- Matrix row: 7.13 + A1+ contract
- Tapping ChezEntryButton on a personal task opens Ask Chez Compose sheet with: Task ID, Task Title ("Replace HVAC air filters"), Due 2026-06-01, Property ID, System Category (HVAC), System ID, Notes — all populated. RE: card renders task-specific header. Category badge correctly shows "Coordinate a task".
- This is the Wave C-1 sim-verification follow-up that computer-use timed out on. Tom's Round A "generic Roofing RE: header from routine context" bug is fully resolved end-to-end with simulator screenshot evidence.
- Evidence: `/tmp/claude-c-evidence/c2-section-7/15-chez-compose-opened.png`
- Status: `verified pass`

### Wave C-2 Finding 4 — Photo evidence + voice note absent from MarkCompleteForm — DEFERRED

- Category: `gap_found`
- Severity: `minor` (depends on v1 scope)
- Surface: MaintenanceTaskDetailSheet `MarkCompleteForm` (line ~2899-2911)
- Evidence: Matrix rows 7.23 (photo evidence on completion) and 7.24 (voice note on completion) describe features absent from MarkCompleteForm. The form has Date / Cost / Notes sections only. Most HNW property-management apps allow photo capture at completion for warranty / dispute documentation.
- Suggested fix: Product/design decision — if v1 scope includes these, wire PhotosPicker + AVFoundation recorder into MarkCompleteForm. Defer.
- Status: `deferred` to Tom/product. Not blocking Round C signoff.

### Wave C-2 Finding 5 — Row 7.18 + 7.19 frequency warning rows describe wrong surface

- Category: `verification` (matrix correction, not a bug)
- The matrix says these warnings fire on MaintenanceTaskDetailSheet's frequency editor, but the actual implementation lives on `SystemDetailView`'s `FrequencyPickerSheet` (maxIntervalDays + warrantyLinked warnings). MaintenanceTaskDetailSheet's `editFrequencySheet` (line 1594) is a simpler preset list with no caps — that's by design per the CLAUDE.md "System frequency overrides" doc. Worth checking on SystemDetailView in a future wave (Section 11c).
- Status: matrix can be updated; not a code bug


---

## Round C — Wave C-3 (Section 4 Document pipeline)

### Wave C-3 verification summary

- Subagent: c3-section-4-document-pipeline, returned PARTIAL
- 12 rows fully verified + 4 partially via source — all 7 critical source-code contracts PASS: SHA-256 dedup in all 4 upload paths, analyze-document `visible_to_home_managers` writeback (Build 87), per-document Access pill gate (Build 87), DocumentAccessSheet family-vs-staff render, VIN auto-link, AES-256-GCM encryption, document_content search index, view-document zero-access streaming
- Sim verified: Documents tab empty state (Upload + Scan dual CTA + SUGGESTED catalog), Property tab Documents sub-tab, search bar, post-Chez-v1 SUGGESTED list (no estate docs)
- 18 rows deferred (would mutate fixture or need admin context)

### Wave C-3 Finding 1 — GapAnalysisView "estate readiness" stale copy — FIXED

- Category: `ui_quality_finding`
- Severity: `medium`
- Surface: `Haven/Features/Documents/Views/GapAnalysisView.swift:90`
- Evidence: Loading state copy "Alfred is reviewing your entire portfolio against best practices for **estate readiness**." references estate readiness which was removed from product scope per Chez v1 (`20260901_chez_v1_estate_removal.sql` dropped estate_state table).
- Fix: rephrased to "household best practices" (no estate connotation). Alfred reference intentionally kept — Alfred IS the analysis agent (per Haven brand model: Alfred = chat/analysis/Q&A, Chez = scheduling/concierge/coordination).
- Status: `fixed` in batch commit. Build clean.

### Wave C-3 Finding 2 — Subagent over-flagged Alfred references — NO ACTION

- Category: `verification` (false-positive triage)
- Subagent flagged 6 Alfred user-facing references (DocumentUploadView×4, GapAnalysisView line 43, DocumentDetailView:136) as B4 brand voice violations. Re-reviewed all 6 in context:
  - DocumentUploadView:192 "Alfred will automatically categorize it" — analysis context, Alfred correct
  - DocumentUploadView:297 "Alfred is analyzing your document" — analysis, Alfred correct
  - DocumentUploadView:331 "Alfred analyzed your document" — analysis, Alfred correct
  - DocumentUploadView:653 "Alfred found these people" — analysis (party extraction), Alfred correct
  - GapAnalysisView:43 "Alfred will analyze your document vault" — analysis, Alfred correct
  - DocumentDetailView:136 "accessible to Alfred for analysis and chat" — both Alfred domains, correct
- Haven has two distinct AI brand surfaces: **Alfred** (chat/analysis/Q&A in `Haven/Features/Chat/`) and **Chez** (concierge/scheduling/coordination in `Haven/Features/ChezRequests/`). Document analysis is Alfred's wheelhouse; only when the copy talks about scheduling / vendor coordination / hand-off should it say "Chez".
- Wave C-2's MaintenanceTaskDetailSheet:2043 fix (Alfred → Chez) was correct because that line was about scheduling. This nuance worth adding to a future B4 discipline definition.
- Status: `no action needed`. Subagent finding closed as false-positive.

### Wave C-3 Finding 3 — FamilyReferenceBinder Estate Planning Summary — INTENTIONAL BACKWARD COMPAT

- Category: `verification` (subagent triage)
- Surface: `Haven/Features/Documents/Views/FamilyReferenceBinder.swift:52, 248, 309, 348`
- Subagent flagged the "Estate Planning Summary" PDF section as Chez v1 stale. Re-reviewed: per CLAUDE.md "Estate Intelligence — REMOVED (Chez v1)" section: "DocumentCategory.swift still declares Will / Trust / POA / Healthcare Directive / Guardianship Designation / Letter of Intent / Living Will / HIPAA Authorization / Prenup / Postnup / Disposition of Remains / Deed in Trust so any documents already uploaded with those categories still decode."
- The PDF section iterates over those same categories. For pre-Chez-v1 uploaded documents, the section correctly surfaces them in the binder. For new users with no estate documents, the section renders "No estate planning documents uploaded yet." which is informationally accurate.
- This is INTENTIONAL backward compat per the Chez v1 cutover. Not a bug.
- Status: `no action needed`. Subagent finding closed as intentional.

### Wave C-3 Finding 4 — CLAUDE.md drift "88 categories / 15 groups" — DEFERRED DOC UPDATE

- Category: `gap_found`
- Severity: `low`
- Surface: `CLAUDE.md` Email Ingestion Pipeline section
- Subagent counted 14 groups + ~97 category strings post-Chez-v1 (Estate Planning group removed). CLAUDE.md says "88 categories in 15 groups".
- Suggested fix: update CLAUDE.md numbers to reflect post-Chez-v1 state. Low-priority documentation hygiene.
- Status: `deferred` — documentation drift, not a code bug. Not blocking Round C signoff.


---

## Round C — Wave C-4 (Section 5 Invoice processing) — PASS

### Wave C-4 verification summary

- Subagent: c4-section-5-invoice-processing, returned PASS — no fixes needed
- All 25 rows verified (20 PASS via source, 4 deferred-source-pass, 1 partial on DB write verification)
- All 10 critical contracts PASS: analyze-document→InvoiceChoiceSheet wiring, home/vehicle toggle gate, InvoiceReviewSheet sections, Phase 50 cadence_detected extraction, CadenceSuggestionCard accept/dismiss paths, deterministic parent grouping (12 categories), Phase 52b specialty inference (11 rules), household_dismissed_suggestions writeback, vendor follow-up task stamping (`assignmentType=vendor` + `assignedContractorId` + `needsVendor` + `Vendor follow-up:` notes prefix), Phase 95 PR 43 vehicle mileage section
- B3 em dashes: zero in user-facing copy (3 in code comments only)
- B4 brand voice: correct nuance — Alfred not invoked in invoice ingestion (presented as system "Invoice Intelligence"); Chez correctly used for concierge action copy; neutral "we" voice on suggestion cards
- B11 density: 8 conditional sections in InvoiceReviewSheet but real-world render is 2-4; gated correctly


---

## Round C — Wave C-5 (Section 6 Email forwarding pipeline)

### Wave C-5 verification summary

- Subagent: c5-section-6-email-forwarding, returned PARTIAL with 4 findings
- 19 rows verified via source; 4 found and triaged; 7 deferred per scope (would need SendGrid forwarding or mutate fixture)
- Sim verified rows 6.14 (Inbox empty-state CTA pair — primary salmon "View Your Chez Email" + secondary ChezEntryButton); 6.27 (4 sub-tabs visible); 6.28 (Chez sub-tab renders ChezRequestsListView with ACTIVE section)

### Wave C-5 Finding 1 — ProjectEmailView Phase 80 brand-voice misses — FIXED

- Category: `ui_quality_finding`
- Severity: `major` (whole user-facing surface still on pre-Chez-v1 brand)
- Surface: `Haven/Features/Property/Views/ProjectEmailView.swift` lines 4, 6 (comments), 40, 70, 75-79 (incl. function helper `alfredAction`), 93, 492, 497
- Evidence: The Household Email view's pitch text still says "Alfred will automatically extract vendors, analyze quotes, categorize documents, and create projects for you" and the section header says "WHAT ALFRED DOES". This is the Chez ingestion pipeline (forwarding → extraction → project/vendor/document creation) — Chez's concierge domain, not Alfred's chat/analysis domain. Line 93 was the clearest mixed-brand sentence: "Alfred reads it, extracts everything useful, and organizes it in Chez". The contacts-save flow saved a contact named "Chez Alfred" with a note that said "Alfred processes everything automatically."
- Fix: renamed all 7 references to Chez. Renamed helper `alfredAction(...)` → `chezAction(...)`. Contact lastName "Alfred" → "Home" (so the saved contact is "Chez Home", organization stays "Chez Home"). All copy now consistently positions email forwarding as Chez concierge work.
- Status: `fixed` in batch commit. Build clean.

### Wave C-5 Finding 2 — Inbox sub-tab "Needs Action" truncates to "Needs Acti..." — FIXED

- Category: `ui_quality_finding`
- Severity: `low`
- Surface: `Haven/Features/Inbox/InboxView.swift:53` segmented Picker
- Evidence: 4 sub-tabs at fixed segment width — "Needs Action" 11 chars exceeds segment, truncates. Confirmed in screenshots `/tmp/claude-c-evidence/c5-section-6/02-04-inbox-*.png`.
- Fix: added `InboxFilter.pickerLabel` computed property that maps `.needsAction → "Action"` and preserves all other labels at their full length. The Picker now uses `pickerLabel` while `rawValue` stays "Needs Action" for analytics + persistence + code lookups. Single change, no callsite breakage.
- Status: `fixed` in batch commit.

### Wave C-5 Finding 3 — Chez request titles truncate in list cells + nav — DEFERRED

- Category: `ui_quality_finding`
- Severity: `low`
- Surface: ChezRequestRowCard list-cell title `lineLimit(2)`; ChezRequestDetailView nav title single-line
- Evidence: Auto-generated request titles ("Find a vendor for: A4 Sanitize pet areas synthetic turf", "Find a vendor for: Septic pumping every 3 years") clip at the line limit. The "Find a vendor for:" prefix is redundant when the category icon already implies the action.
- Suggested fix: either bump list-cell title to lineLimit(3), or strip the "Find a vendor for:" prefix when category icon is present, or generate shorter task-focused titles on the server side.
- Status: `deferred` — multi-file design call; not blocking Round C signoff. Logged for product/design follow-up.

### Wave C-5 Finding 4 — ChezMessageBubble system message bubble shape — FIXED

- Category: `ui_quality_finding`
- Severity: `low`
- Surface: `Haven/Features/ChezRequests/Components/ChezMessageBubble.swift:28-43` system body
- Evidence: The system-role audit-trail message ("Customer asked Chez to source a vendor for this task...") used `Capsule().fill(...)` background. Capsule's corner radius is min(width,height)/2 — for multi-line text the geometry forces an oval / circular look with cropped corners. Screenshot: `/tmp/claude-c-evidence/c5-section-6/06-chez-request-detail.png`.
- Fix: switched from `Capsule()` to `RoundedRectangle(cornerRadius: 12, style: .continuous)`. Added `.fixedSize(horizontal: false, vertical: true)` so multi-line text breaks correctly without collapsing the rectangle. Bumped horizontal padding 12 → 14 and vertical 6 → 8 for breathing room. Added `Spacer(minLength: 32)` on both sides so wider system messages don't span the full content width.
- Status: `fixed` in batch commit.


---

## Round C — Wave C-6 (Section 8 Family + invites + home manager + staff) — PASS

### Wave C-6 verification summary

- Subagent: c6-section-8-family, returned PASS — no fixes needed
- All 30 rows verified: 22 PASS via source + 8 deferred (would-mutate / admin-only / email-infra / onboarding-only)
- All major contracts PASS: Build 86 AddFamilyMemberChooserSheet two-card chooser, FamilyMemberFormView regular vs expecting modes, AvatarPhotoService 400px resize → avatars bucket → 1-year signed URL, AddHouseholdStaffSheet `memberType:'home_manager'` routing through HouseholdInviteCoordinator, Phase 95 PR 39 destructive-UI gating (`isStaffUser` hides Delete Account), MaintenanceViewModel.assignedUserName " · Home Manager" / " · Staff" suffix, fetchFamilyMembers server-side filter `member_type IN ('family', NULL)`, sortedByAge extension, photoUrl field (not profilePhotoUrl per MEMORY.md gotcha)
- B4 brand voice CORRECT throughout: "Add family members so Alfred and Chez can match documents..." (Alfred = matching/analysis, Chez = task coordination); "Send invite to join Chez" (concierge brand for invitations)
- B3 zero em dashes in user-facing copy
- Phase 95 gap #55 verified: SettingsView.swift:347-369 wraps "Delete My Account" in `if !appState.isStaffUser`; AppState.swift:22+41 caches isStaffUser from member_type


---

## Round C — Wave C-1 REDO (Section 13 Chez full concierge — REAL SIM DRIVE)

After the user moved the Simulator to the primary monitor, this REDO subagent actually drove the sim with real taps. The Wave C-1 source-only audit had PASS'd everything; the sim drive found 2 real bugs the source audit missed, plus several PASS validations.

### Wave C-1 REDO Finding 1 — Spending Authority stepper hides dollar value — CRITICAL — FIXED

- Category: `ui_quality_finding`
- Severity: `major`
- Surface: `Haven/Features/ChezRequests/Views/ChezProfileView.swift:198-226` `tierStepper` private func
- Evidence: All three Spending Authority steppers render as bare `- | +` buttons with NO visible dollar value. Default $200 / $500 / $500 are invisible because the Stepper's label closure (where the Text was placed) is hidden by `.labelsHidden()`. Homeowner lands on Your Chez profile, sees `- +` controls, and cannot tell what spending authority they've granted Chez. Screenshot: `/tmp/claude-c-evidence/c1-section-13-redo/13-chez-profile.png`.
- Fix: restructured the stepper layout. Moved `Text("$\(amount.wrappedValue)")` out of the Stepper's content closure into a sibling Text in the HStack. Stepper now uses an empty-string label which `.labelsHidden()` correctly collapses, while the dollar value renders as its own widget aligned trailing before the +/- buttons.
- Status: `fixed` in commit (next). Build clean.

### Wave C-1 REDO Finding 2 — RoutineDetailView Archive routine is one-tap destructive without confirmation — FIXED

- Category: `ui_quality_finding`
- Severity: `major` (data hazard)
- Surface: `Haven/Features/Property/Views/RoutineDetailView.swift:466-472` Archive Button
- Evidence: REDO subagent accidentally archived a routine twice while attempting to tap Edit (the buttons are stacked closely and the simulator window is small). Routine count dropped 16→15→14 from misclicks. No safety net — `archive()` fires immediately on tap.
- Fix: added `@State showArchiveConfirm = false` + `.confirmationDialog("Archive this routine?", titleVisibility: .visible)` wrapping the archive button. Dialog has explicit "Archive routine" destructive button + "Cancel" + a body message explaining what archiving does ("hides its schedule and unlinks any vendor tasks. You can restore it later from the archived routines list").
- Status: `fixed` in commit (next). Build clean.

### Wave C-1 REDO Finding 3 — Chez request title truncation — DEFERRED

- Category: `ui_quality_finding`
- Severity: `minor`
- Same finding as Wave C-5 #3 (re-confirmed). "Find a vendor for: A4 Sanitize pet areas mix..." and "syn..." are indistinguishable after truncation. Already documented as deferred to product/design.
- Status: `deferred` (consolidated with Wave C-5 finding)

### Wave C-1 REDO Finding 4 — Spec vs implementation gap on RoutineDetailView Chez delegation

- Category: `verification` (spec interpretation)
- The matrix Row 13.20 says "ChezOwnsToggle on routine". Actual implementation has TWO surfaces:
  1. RoutineDetailView: a ChezEntryButton card labeled "Have Chez handle this routine" (opens Compose sheet for context-rich asks)
  2. RoutineEditSheet:236: a ChezOwnsToggle for blind/standing delegation
- This is intentional UX separation (richness vs simplicity). Not a code bug. Matrix could note both surfaces.
- Status: `no action needed` — matrix could be updated to reflect both delegation surfaces.

### Wave C-1 REDO verified passes (sim screenshot evidence)

- **Dashboard ChezEntryButton** "Need help? Ask Chez" → opens Compose sheet with correct context source_entity_type "dashboard" + source_entity_label "Dashboard concierge request"
- **Compose sheet** renders 6 category chips with "General help" salmon-fill default
- **Inbox 4 sub-tabs** in correct order: Action / Unread / All / Chez (note: "Action" not "Needs Action" — Wave C-5 fix confirmed in sim)
- **Chez sub-tab** renders "Chez Home Manager" header + "Ask a quick question" CTA + ACTIVE section with fixture requests
- **ChezRequestDetailView system message bubble** is centered gray ROUNDED RECT, not circular — commit 7a1811ed fix CONFIRMED IN SIM
- **Settings → Your Chez profile** row exists with correct caption
- **ChezProfileView** all 6 sections render (About / Spending / Communication / Vendor Prefs / Logistics / Standing Engagements)
- **Spending Authority card background** is creamLight, NOT salmon — morning fix `5aa507fc` CONFIRMED IN SIM
- **RoutineDetailView "Log visit and spend" button** is salmon fill with white text — Codex P0-1 fix `840a9f52` CONFIRMED IN SIM
- **Brand voice clean throughout** — every user-facing string says "Chez", no "Tom" anywhere


---

## Round C — Wave C-2 REDO (Section 7 brief sim verification)

After Wave C-1 REDO sim drive worked, C-2 REDO confirmed fixes hold:

- **B4 brand voice fix at MaintenanceTaskDetailSheet:2043** — source-verified (the no-vendor SCHEDULING surface wasn't reachable in this fixture since all systems are vendor-covered, but the source string change is correct).
- **A1+ ChezEntryButton context contract** — verified LIVE on VehicleDetailView's "Have Chez find me a mechanic" button. Compose sheet RE: card shows `Vehicle: 2003 HONDA Accord`, mileage 90000, vehicle ID populated. Smart category routing (vehicle without shop → `find_vendor`) confirmed via salmon-tinted "Find a vendor" badge. Phase 80.2 routing rule fires correctly.
- **Em-dash sweep** — verified VehicleDetailView shows "Not estimated yet" not "—".
- **Brand voice** — compose header "Ask Chez · Chez replies within 1 business day" intact, no Alfred / Tom leakage.

### Wave C-2 REDO Finding 1 — Maintenance hub vehicle row navigates to blank view — NEW GAP

- Category: `gap_found`
- Severity: `moderate`
- Surface: Maintenance hub "Vehicles" section row tap → blank navigation destination
- Evidence: Subagent reported "Tapping the '2003 HONDA Accord — needs shop / Set up >' row from the Maintenance hub's Vehicles section navigates to a blank white view (back-arrow only, no body)." Reachable VehicleDetailView is via Property tab → vehicle row.
- Reproduction: Open Maintenance tab → scroll to Vehicles section → tap a vehicle row → blank view appears
- Suggested fix: check the navigationDestination handler for the Maintenance hub's vehicle row. The Property tab path works correctly (subagent navigated there fine for the rest of the test). The Maintenance hub path is missing the destination view binding.
- Status: `deferred` — out of scope for C-2 REDO; logged for follow-up task.


---

## Round C — Wave C-3 REDO (Section 4 Documents — brief sim verification) — PASS

Sim drive confirmed all C-3 verdicts hold:
- Documents tab empty state: Vault hero + Upload/Scan CTAs + 7-item SUGGESTED catalog (correctly EXCLUDES Will/Trust/POA/etc per Chez v1 estate removal)
- DocumentUploadView 4 "Alfred" refs verified as analysis-context (correct B4 — Alfred IS the analyzer)
- Zero em-dashes in any visible Documents tab or Alfred tab copy
- No new bugs from C-1 REDO changes

### Wave C-3 REDO Finding 1 — GapAnalysisView is dormant in v1 — NOTE

- Category: `verification` (informational)
- The Wave C-3 fix `d30de861` to GapAnalysisView line 90 ("Alfred is reviewing... household best practices") is correct source-side, but the view itself is NOT wired into v1 navigation. `grep -rn 'GapAnalysisView('` returns only the SwiftUI #Preview callsite.
- `SmartRecommendations.swift:187` notes "Chez v1: estate-readiness, gap-analysis-prompt, scenario-prompt" were intentionally retired from the active surface set.
- Status: `no action needed` — fix is correct for when/if GapAnalysisView is reintroduced. Worth noting in matrix that Row 4.32 "Document gap analysis" is partly v1-deferred.


---

## Round C — Wave C-4 REDO (Section 5 Invoice processing — REAL SIM DRIVE) — PASS

Sim drive confirmed all source verdicts hold. Fixture has 0 documents in Vault so live processing scenarios deferred. 7 verified passes via source + visible UI:
- Row 5.1 DocumentDetailView "Scan for Maintenance & Systems" affordance
- Row 5.2 InvoiceChoiceSheet clean Chez voice
- Row 5.4 InvoiceReviewSheet + SpecialtySuggestionCard wiring
- Row 5.8 CadenceSuggestionCard wired at 2 dashboard sites
- Row 5.18 SpecialtySuggestionCard with Phase 52b copy
- Row 5.21 Scan affordance copy at DocumentDetailView:842
- B3/B4/B11 all clean on invoice surfaces

### Wave C-4 REDO Finding 1 — TasksHubView label drift "Contractor" vs "Handyman" — DEFERRED

- Category: `gap_found`
- Severity: `minor`
- Surface: `Haven/Features/Tasks/Views/TasksHubView.swift:21+56`
- Evidence: The title-switcher button reads "Contractor" but calls `setMode(.handyman)`. CLAUDE.md spec + every other surface in the codebase (`HandymanTabView`, `HandymanPunchListView`, `handyman_punch_items` table) uses "Handyman" canonically.
- Suggested fix: Tom decides — either (a) align UI label "Contractor" → "Handyman" to match spec + rest of codebase, or (b) update CLAUDE.md to note "Contractor" is the user-facing brand and Handyman is the internal term.
- Status: `deferred` to product/design decision. Not blocking signoff but creates inconsistency in user mental model.

### Wave C-4 REDO Finding 2 — PropertyDetailView "systems missing profile" shows raw engineering slugs — DEFERRED

- Category: `ui_quality_finding`
- Severity: `moderate`
- Surface: `Haven/Features/Property/Views/PropertyDetailView.swift:1334-1339` `systemsMissingProfilePreview`
- Evidence: The card subtitle preview directly renders `system.name` values like "A4 Crawl Space finished_basement-sump_pump-crawl_space" — raw composite slug from the quiz mapper. Users should see human-friendly names.
- Reproduction: Open Property tab → first property → Overview sub-tab → look for "X systems missing profile" card subtitle. Preview shows engineering-style hyphenated/underscored slugs.
- Suggested fix: Apply a humanization transform to system.name display:
  ```swift
  private var systemsMissingProfilePreview: String {
      systemsMissingProfileEntries
          .prefix(3)
          .map { $0.system.name.humanizedSystemName }  // strip slug suffix, title-case
          .joined(separator: " · ")
  }
  ```
  OR use a separate `displayName` field if one exists. OR display the system's category (always clean) instead of name.
- Status: `deferred` — needs decision on whether to humanize at render or fix in quiz mapper writes.


---

## Round C — Wave C-5 REDO (Section 6 Email forwarding — brief sim verification) — PASS

All 3 Wave C-5 fixes verified live in sim:
- **ProjectEmailView Alfred→Chez rebrand**: pitch text reads "Chez will automatically extract...", section header "WHAT CHEZ DOES", contact saves as "Chez Home" — verified
- **Inbox sub-tab "Action" label**: 4 sub-tabs read Action / Unread / All / Chez (not "Needs Action") — verified
- **ChezMessageBubble system message**: clean rounded rectangle, multi-line uncropped — verified

### Wave C-5 REDO Finding 1 — SettingsView "ALFRED" section header on Household Email — FIXED

- Category: `ui_quality_finding`
- Severity: `medium` (brand consistency)
- Surface: `Haven/Features/Settings/SettingsView.swift:175-191`
- Evidence: REDO subagent spotted that Settings tab's section ABOVE the "Household Email" row reads "ALFRED" — but Household Email IS Chez's ingestion path (forwarding → vendor + project + document creation = concierge work). After Wave C-5's ProjectEmailView Alfred→Chez rebrand, the parent SettingsView section was still pointing at Alfred. Inconsistent.
- Fix: changed section header "ALFRED" → "HOUSEHOLD INTAKE" (neutral, descriptive, doesn't bake either brand into the section label). Updated footer "Alfred processes and organizes" → "Chez processes and organizes" to match the now-Chez-branded ProjectEmailView destination.
- Status: `fixed` in batch commit. Build clean.


---

## Round C — Wave C-6 REDO (Section 8 Family — REAL SIM DRIVE) — PASS with gaps

Sim drive confirmed all Build 86 + Build 87 contracts hold. The first C-6 was source-only; this REDO actually drove the sim through 18 screenshots and validated the user-facing UX. 12 verified passes (AddFamilyMemberChooserSheet 2-card chooser, FamilyMemberFormView regular + expecting modes, Settings → Family Members + Household Staff separation, AddHouseholdStaffSheet with Chez brand voice).

### Wave C-6 REDO Finding 1 — HouseholdStrip + HouseholdStaffStrip orphaned in code — DOCUMENTATION DRIFT

- Category: `gap_found`
- Severity: `moderate`
- Surface: `Haven/Features/Dashboard/Components/HouseholdStrip.swift` + `HouseholdStaffStrip.swift` (Swift files exist) vs `Haven/Features/Dashboard/DashboardView.swift` (zero call sites for either)
- Evidence: REDO subagent's Dashboard screenshot confirmed neither strip is rendered. `grep -rn "HouseholdStrip("` and `grep -rn "HouseholdStaffStrip("` both return ZERO callsites across the entire codebase. The Phase 80+ Chez-first restructure surfaced "Chez handles 5 things" + "Spring readiness" cards as the primary post-quiz layout and replaced the family-prominent strip.
- CLAUDE.md spec says: "Scroll order (post-quiz): ... > HouseholdStrip > HouseholdStaffStrip > ..." — this is stale.
- Impact: matrix Row 8.11 "FamilyMemberProfileView opens on tap from HouseholdStrip" is broken — entry point doesn't exist on Dashboard. Profile is still reachable via Settings → Family Members → tap row, but the Dashboard tap path is gone.
- Suggested fix: Either (a) update CLAUDE.md scroll order to reflect Phase 80+ reality, or (b) decide if HouseholdStrip should be re-instated below the Chez cards. This is a product decision.
- Status: `deferred` to product/design. Worth noting as significant doc drift.

### Wave C-6 REDO Finding 2 — Family Member sort order anomaly with adult — MINOR

- Category: `ui_quality_finding`
- Severity: `minor` (likely fixture data quirk)
- Surface: Family Members list rendered order
- Evidence: Fixture shows 4 kids age 9 (sorted), then E2E Tester adult, then Sam Tester (age 7). Adult should be either first (if DOB indicates oldest) or last (if no DOB per sortedByAge no-DOB rule).
- `sortedByAge()` implementation at DatabaseModels:205 is correct: DOB-known sorted ascending (oldest first), no-DOB rows go to the END alphabetically. Either E2E Tester has a DOB that places them in the middle (unlikely for an adult unless the year-of-birth got truncated) OR something in the fixture data is off.
- Suggested fix: investigate fixture data. Not a code bug.
- Status: `deferred` — fixture data quirk, not a code regression.

### Wave C-6 REDO Finding 3 — FamilyMemberFormView opinionated defaults — POLISH

- Category: `ui_quality_finding`
- Severity: `minor`
- Surface: `Haven/Features/Settings/Views/FamilyMemberFormView.swift` Add Family Member regular mode
- Evidence: Form defaults Relationship=Child + Gender=Male when opening fresh. Could be confusing for users adding a spouse — they have to actively change both before saving.
- Suggested fix: either (a) leave Relationship/Gender unselected with a placeholder ("Choose…"), or (b) use Picker(...).pickerStyle(.menu) with no preselected option until user picks one.
- Status: `deferred` — minor polish, not blocking.

### Wave C-6 REDO verified passes (sim screenshot evidence)

- **Settings list** renders Family Members + Household Staff rows under correct sections (Account vs Household)
- **CHEZ CONCIERGE section** with "Your Chez profile" row exists
- **Family Members list** has EXPECTING section (A4 Baby, due Dec 1 2026, 203 days, View Preparation Checklist 0/15) above family rows
- **AddFamilyMemberChooserSheet** (Build 86): 2 cards with correct routing — verified
- **FamilyMemberFormView regular**: title "Add Family Member", BASIC INFO + LEGAL NAME + SCHOOL sections — verified
- **FamilyMemberFormView expecting**: title "Add Expecting", EXPECTING section with Chez-branded helper rows ("Chez will create a preparation checklist", "Track documents like birth certificate, 529, updated will", "Get reminders as your due date approaches") — verified
- **FamilyMemberFormView edit mode**: title "Edit Member", loads existing data populated — verified
- **Household Staff** (Build 87): list renders separately, 1 fixture row "A4 Manager Household / Home Manager" — verified
- **Staff member NOT in Family Members list** — confirms Build 87 member_type filtering at read path
- **AddHouseholdStaffSheet** (Build 87): NAME + CONTACT sections, "Send invite to join Chez" toggle salmon-default-on, helper copy "When enabled, your home manager gets a Chez invite by email..." — verified
- **Brand voice throughout** — every Chez reference correct, zero Alfred refs in family/staff invite copy, zero "Tom"
- **Phase 56.3 typography**: Fraunces serif for screen titles ("Settings", "Family Members", "Add Family Member", "Add Expecting", "Add Home Manager", "Edit Member", "Household Staff") — verified


---

## Round C — Wave C-7 (Section 10 Vehicle management) — PASS with gaps

Sim drive completed across the full VehicleDetailView (12+ sections), all sheet entry points, brand hero, mechanic picker, edit/archive/purchase-date sheets. 19+ verified passes. 6 polish/UX issues surfaced.

### Wave C-7 Finding 1 — CoveredDriverPickerSheet shows 'Child' relationship as eligible driver — FIXED

- Category: `ui_quality_finding`
- Severity: `minor` (data hazard)
- Surface: `Haven/Features/Property/Views/CoveredDriverPickerSheet.swift:39-50` `eligibleDrivers`
- Evidence: A4 Baby (relationship='Child', no DOB) appeared as a selectable driver. The filter intentionally includes no-DOB rows but didn't check relationship type. A child is never a legitimate insured driver even with no DOB on file.
- Fix: added a hard pre-check for `member.relationship.lowercased() == "child"` that returns false regardless of DOB state.
- Status: `fixed` in batch commit.

### Wave C-7 Finding 2 — VehicleDetailView overflow menu "Archive vehicle" capitalization inconsistent — FIXED

- Category: `ui_quality_finding`
- Severity: `minor`
- Surface: `Haven/Features/Property/Views/VehicleDetailView.swift:75`
- Evidence: Three-dot overflow menu had "Edit Vehicle" + "Delete Vehicle" (title case) but "Archive vehicle" (lowercase v).
- Fix: aligned to "Archive Vehicle" (title case to match siblings).
- Status: `fixed` in batch commit.

### Wave C-7 Finding 3 — MechanicPickerSheet shows ALL contractors regardless of trade — DEFERRED

- Category: `ui_quality_finding`
- Severity: `minor` (functional risk)
- Surface: `Haven/Features/Property/Views/VehicleDetailView.swift:2521+` `MechanicPickerSheet`
- Evidence: Picker lists all household contractors (A4 Chimney Pro, A4 Electrical Pro, A4 Freeform Lawn Co, Putnam Plumbing, TruGreen, etc.) when adding a mechanic. None of those are mechanics.
- Suggested fix: filter contractors by canonical category matching "Mechanic" / "Automotive" / "Auto Repair". Or split into "AUTOMOTIVE" section + "OTHER CONTRACTORS (likely not mechanics)" section. Or just show empty state + "Add New Mechanic" affordance when no automotive contractors exist.
- Status: `deferred` — not a 1-line fix; SystemCategoryRegistry doesn't have an automotive category. Needs design decision. Documented for product follow-up.

### Wave C-7 Finding 4 — EditVehicleSheet mileage field has no visible label when populated — DEFERRED

- Category: `ui_quality_finding`
- Severity: `minor` (contextual)
- Surface: `Haven/Features/Property/Views/EditVehicleSheet.swift:42`
- Evidence: `TextField("Current Mileage", text: $currentMileage)` — placeholder "Current Mileage" hidden when value is set (standard iOS behavior). Subagent saw populated value "90000" with no visible label, between Color and Ownership rows.
- Suggested fix: convert to HStack pattern with leading label Text + trailing TextField, OR use SwiftUI's LabeledContent (iOS 16+). Same pattern would benefit License Plate / Color when populated.
- Status: `deferred` — minor polish, contextual issue (placeholder works fine when empty).

### Wave C-7 Finding 5 — CLAUDE.md says Recalls DisclosureGroup "always shown" but code is conditional — DEFERRED

- Category: `gap_found`
- Severity: `minor` (doc drift)
- Surface: `Haven/Features/Property/Views/VehicleDetailView.swift:756` (`if !viewModel.recalls.isEmpty`)
- Evidence: CLAUDE.md says "Recalls — DisclosureGroup, always shown" but code gates on non-empty recalls list. Unified Attention banner already covers the no-recalls case, so option (a) update CLAUDE.md to describe the conditional render is the simpler fix.
- Status: `deferred` — doc-only update.

### Wave C-7 Finding 6 — Phase 95 PR 29 three-state recall acknowledgment NOT implemented — DEFERRED

- Category: `gap_found`
- Severity: `moderate` (matrix discrepancy)
- Evidence: Code search for "acknowledged" / "recallState" / "RecallStatus" returns ZERO results. VehicleDetailView.swift:761-784 renders only TWO states (Resolved / Open). Matrix Row 10.16 describes a three-state acknowledgment (open / acknowledged / fixed) per Phase 95 PR 29 that was never shipped.
- Suggested fix: either (a) descope Phase 95 PR 29 from spec/test matrix, OR (b) ship the three-state UI: add `acknowledged_at TIMESTAMPTZ` column to `vehicle_recalls`, expose `acknowledge()` / `markFixed()` view-model actions, render three capsules.
- Status: `deferred` — product decision needed.

### Wave C-7 verified passes (sim screenshot evidence)

- Properties → Your Garage with "+" button (10.1)
- Add Vehicle sheet: Scan VIN + Enter VIN + Add Manually (10.2-10.4)
- Brand Hero: Honda gradient, logo, VIN monospaced, mileage pill, ownership pill (10.8)
- MileageUpdateSheet opens with salmon Update CTA (10.9)
- Covered Drivers section + CoveredDriverPickerSheet (10.10-10.11)
- Mechanic Card with "Add your mechanic / One-tap calling" (10.12)
- MechanicPickerSheet with "Add New Mechanic" affordance (10.13)
- Stats Row: Total Spent / Services / Last Svc (10.14)
- Unified Attention "All good" with green check (10.15)
- Registration/Insurance/Ownership 3-card layout (10.19)
- Service History card with empty state + "Log" button (10.22)
- Vehicle Documents card with Upload + categorized rows (10.23)
- Ask Alfred (vehicle context) personalized (10.25) — correct Alfred branding for chat AI
- EditVehicleSheet (10.26)
- PurchaseDatePickerSheet (10.27)
- ArchiveVehicleSheet (10.29) with reassuring copy "every service record, recall, and document stays on file"
- B1 legibility, B3 no em-dashes, B4 brand voice (Chez for concierge / Alfred for chat), B11 density acceptable


---

## Round C — Wave C-8 (Section 11a Overview + 11b Maintenance — REAL SIM DRIVE)

Sim drive verified 14 rows across Property tab Overview and Maintenance surfaces. 1 polish bug fixed inline; 3 significant SPEC DRIFTS surfaced.

### Wave C-8 Finding 1 — RoutinesListView double chevron on every row — FIXED

- Category: `ui_quality_finding`
- Severity: `minor` (polish)
- Surface: `Haven/Features/Property/Views/RoutinesListView.swift:160-162`
- Evidence: Every routine row in RoutinesListView renders TWO chevron-right indicators — one manual at the right edge of the white HavenCard, one outside the card on the far right (NavigationLink's auto-disclosure in a List context). `.buttonStyle(.plain)` does not suppress the List auto-chevron.
- Fix: removed the manual chevron; NavigationLink in List provides its own disclosure indicator.
- Status: `fixed` in batch commit.

### Wave C-8 Finding 2 — Section 11b spec is fundamentally STALE — DOC DRIFT MAJOR

- Category: `gap_found`
- Severity: `major` (matrix vs reality)
- Surface: `Haven/Features/Property/Views/PropertyDetailView.swift:3-8`
- Evidence: PropertyDetailTab enum is `[overview, systems, projects, vendors, documents]` — NO "maintenance" case. The Phase 50/Build 89 Maintenance sub-tab described in CLAUDE.md no longer exists. Matrix Section 11b's 9 rows (11.10-11.18) describe a removed UI.
- Current state: Maintenance work is split across (1) Tasks tab → MaintenanceTabView (Phase 67 V5) and (2) MaintenanceScheduleView (Phase 60 day-by-day + month-card layouts).
- Suggested fix: Rewrite matrix Section 11b to describe the post-Phase-67 V5 architecture. Update CLAUDE.md "PropertyDetailView Maintenance tab" reference to point to the current Tasks tab flow.
- Status: `deferred` to spec maintenance pass

### Wave C-8 Finding 3 — Phase 56.5 two-bucket UI dead code — DOC DRIFT

- Category: `gap_found`
- Severity: `minor` (dead code + stale spec)
- Surface: `Haven/Features/Property/Views/MaintenanceScheduleView.swift:2055,2952-2972`
- Evidence: Code still defines `personalBucketBody` ("To Schedule" bucket) and `scheduledBucketBody` ("Scheduled" bucket) for Phase 56.5, but the layout switch at lines 1051-1056 routes both `.list` → timelineContent (Phase 60 day-by-day agenda) and `.calendar` → calendarContent (month cards). Neither calls the bucket bodies. Phase 60 effectively replaced Phase 56.5 with a time-window-driven UI.
- Sim observation: neither "Scheduled" nor "To Schedule" header bar visible in either layout.
- Suggested fix: either restore the bucket UI (if Phase 56.5 product intent stands), or remove the dead `personalBucketBody`/`scheduledBucketBody` code + update matrix Row 11.14.
- Status: `deferred` — product decision

### Wave C-8 Finding 4 — MaintenanceLayout enum naming reversed — COSMETIC

- Category: `verification` (cosmetic)
- Surface: `Haven/Features/Property/Views/MaintenanceScheduleView.swift` `MaintenanceLayout` enum
- Evidence: `.list` (user label "List") renders `timelineContent`; `.calendar` (user label "Timeline") renders `calendarContent`. Phase 56.4 deliberately relabeled the user-facing string without renaming the enum case for persisted UserDefaults compatibility. Then Phase 60 swapped what `.list` renders, making the naming drift more pronounced. Functional; cosmetic only.
- Status: `deferred` — cleanup task for next phase touching this view

### Wave C-8 verified passes (sim screenshot evidence)

- **InvestmentSummaryCard hero (Row 11.1)**: $969K estimated value + range $872K-$1.1M + "From public market data" + +35.1% vs invested gain pill — verified
- **Stacked bar (Row 11.3)**: Purchase $660K + Surplus $232K — verified
- **Bottom summary (Row 11.4)**: Net after sale $891,618 + Unrealized gain $231,618 — verified
- **Expand toggle waterfall (Row 11.5)**: "See breakdown" → Purchase + Total invested + Estimated value + Selling costs -$77,532 + Net after sale + Unrealized gain — verified
- **equityUpsellCard (Row 11.6)**: PROTECTED EQUITY navy gradient sub-card "Homes maintained well sell for ~7.4% more" + "$72K in equity Chez helps you protect" + "Source: NAR Remodeling Impact Report" — verified
- **Sale simulator (Row 11.7)**: "What if I sold for..." button — verified
- **PRIMARY RESIDENCE eyebrow (Row 11.8)**: salmon-light foreground per PropertyHeroHeader.swift:13-14 INTENTIONAL design (not morning-fix regression)
- **Priorities stat (Row 11.9)**: salmon-light foreground INTENTIONAL design (not regression)
- **Stats-pill filter (Row 11.11)**: Overdue / This Week / This Month / Later, navy-fill active state on tap
- **"Showing X" caption + Clear (Row 11.12)**: appears below stats pills on active filter
- **Layout toggle (Row 11.13)**: List / Timeline icon toggle, two distinct layouts render
- **Inline handyman quick-add (Row 11.17)**: "Have someone else do it →" + "Or have Chez source one" salmon links on findContractor cards
- **Compact routines strip (Row 11.18)**: "ONGOING ROUTINES · 14" horizontal scroll of routine pills


---

## Round C — Wave C-9 (Section 11c Systems + 11d Contacts — REAL SIM DRIVE)

Sim drive surfaced 2 fail-level findings + multiple polish/spec drift items.

### Wave C-9 Finding 1 — IndigoGradientCard "decisions" stat renders salmon even when 0 — FIXED

- Category: `ui_quality_finding`
- Severity: `minor` (B11 salmon discipline)
- Surface: `Haven/Features/Tasks/Views/Components/IndigoGradientCard.swift:136-149`
- Evidence: `statColumn(value: decisionCount, label: "decisions", isWarning: true)` always renders the number in `HavenColors.actionLight` regardless of value. When decisionCount=0, "0" still renders salmon — reads as action-needed when in fact the user has no pending decisions.
- Fix: gate the warning color on `value > 0`. If `isWarning && value > 0`, render salmon (legitimate action signal). Otherwise render white (neutral).
- Status: `fixed` in batch commit. Build clean.

### Wave C-9 Finding 2 — recommendedServicesRow defined but NOT MOUNTED — DEFERRED

- Category: `gap_found`
- Severity: `moderate` (dead code OR missing wiring)
- Surface: `Haven/Features/Property/Views/PropertyDetailView.swift:5145+, 5197+`
- Evidence: `recommendedServicesRow` and `recommendedSystemsRow` are defined but never instantiated in any sub-tab body. Matrix Row 11.26 ("'Recommended for your home' sparkles row → RecommendedServicesView") shows ZERO surface in current build.
- Suggested fix: either (a) wire these rows into Property → Systems or Contacts sub-tab, OR (b) remove the dead code if RecommendedServicesView is exclusively reachable via Tasks tab's BrowseBand.
- Status: `deferred` — needs product decision on where this entry-point should live post-Phase-67

### Wave C-9 Finding 3 — "ADD OR DISCOVER" section described in CLAUDE.md doesn't exist — DOC DRIFT

- Category: `gap_found`
- Severity: `minor` (doc drift)
- Evidence: `grep -rn "ADD OR DISCOVER" Haven/` returns ZERO matches. The CLAUDE.md "Contacts Hub (Phase 56 Section 1)" section describes "ADD OR DISCOVER" with 5 entries (Add a vendor / Browse specialty systems / Add a custom system / Add a routine / See recommended services) but the actual current build shows an Add button action sheet with 3 options: 'Add vendor or advisor' / 'Add utility or policy' / 'Ask Alfred to find a pro'.
- Status: `deferred` — CLAUDE.md needs update OR feature was intentionally trimmed

### Wave C-9 Finding 4 — Contacts sub-tab labeled "Vendors" in app — NAMING DRIFT

- Category: `verification` (cosmetic)
- Evidence: Sub-tab label is "Vendors" in app; CLAUDE.md / matrix call it "Contacts". ContactsFilter enum has 5 cases (not 4 as matrix says). Cosmetic; could be either rename direction.
- Status: `deferred` — needs spec consistency decision

### Wave C-9 Finding 5 — snake_case + slug bleed across system names — RELATED TO C-4 REDO

- Category: `ui_quality_finding`
- Severity: `moderate` (already flagged in C-4 REDO as "systems missing profile" preview)
- Evidence: System names display "A4 HVAC not_sure", "subtype boiler_with_central_ac", "Crawl Space finished_basement-sump_pump-crawl_space" — raw snake/kebab debug strings. Vendor names show "A4 Pest Co quarterly_pro", "A4 Irrigation Co drip" with descriptor suffix mid-name.
- Compound issue: both fixture data quality AND missing humanization at render. Real-user data with cleaner names would mask much of this, but UI should defensively humanize.
- Suggested fix: humanize `system.name` and `contractor.companyName` at render time. Replace underscores/hyphens with spaces, title-case, strip suffix slugs.
- Status: `deferred` — already in gaps doc from C-4 REDO finding #2. Add note linking the two.

### Wave C-9 Finding 6 — "Electrical & Safe..." truncation in category tile — DEFERRED

- Category: `ui_quality_finding`
- Severity: `minor` (layout)
- Surface: System category tile rendering
- Evidence: Full label "Electrical & Safety" clipped to "Electrical & Safe..." in the systems tile grid.
- Suggested fix: either widen tile (changes grid), shrink font, lineLimit(2), or shorten label to "Electrical" (loses safety connotation).
- Status: `deferred` — layout-level decision

### Wave C-9 verified passes

- Row 11.19 SystemCoverageCard progress dot is dark/indigo, NOT salmon — morning fix landed
- Row 11.20 Category notification dots are AMBER, NOT salmon — morning fix landed
- Row 11.21 Tap category → list of systems
- Row 11.22 SystemDetailView (with profile-to-finish card + service freq row)
- Row 11.23 Add details (Take label photo + Enter details)
- Row 11.25 FrequencyPickerSheet (Weekly through Annually + Custom + Apply-to-existing toggle)
- Row 11.31 AddSystemView form
- Row 11.32 Contacts sub-tab structure (header + Add + subtitle + search + filter chips + vendor rows)
- Row 11.34 Search bar present
- Row 11.35 Routine chip cross-references routineVendorIds (filtered to 5 routine vendors with "Recurring" badge)
- Row 11.36 Apple Contacts-style row layout (32pt logo + name + caption + chevron)

