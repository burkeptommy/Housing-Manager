# Haven -- Development Progress

This file tracks session-by-session development history. Claude Code reads this at the start of each session to understand recent work and appends a summary at the end.

**Self-compaction rule:** If this file has more than 15 detailed entries, compress all entries older than the most recent 5 into single-line summaries at the top.

---

## Completed Phases (Compressed)

- **Phases 20-28:** App icon, UX audit (25 fixes), Sign in with Apple, background multi-file upload, smart vendor import (3 methods), pre-onboarding intro explainer, property color coding, maintenance/estate tab improvements, dashboard redesign, app icon fix, navigation consistency polish.
- **Phase 29-31:** Navigation consistency, Alfred AI guardrails (scoped system prompt), tab navigation pop-to-root fix.
- **Phase 32:** Major UX overhaul.
- **Phase 33:** Family member avatars with CRUD.
- **Phase 34:** Smart recommendations engine.
- **Phases 35-36:** Household sharing (invite flow + atomic merge across 15+ tables).
- **Phase 37:** Go-to-market strategy and execution plan (non-code). Attorney referral kit, GTM playbook.

---

## Phase 38: Invoice Intelligence (38a-38f iterations)

`process-invoice` Edge Function + iOS deterministic keyword table for sub-system grouping. Sub-systems use `parent_system_id` on `home_systems`. `InvoiceChoiceSheet` for bills; user can manually assign parent for unmatched systems. Key fix: `analyze-document` now guards against auto-creating systems for invoices. Fuzzy dedup (word overlap, model number, manufacturer+function, functional type matching). Parent systems auto-created if needed. Key files: `process-invoice/index.ts`, `InvoiceProcessingModels.swift`, `InvoiceProcessingViewModel.swift`, `InvoiceReviewSheet.swift`, `InvoiceChoiceSheet.swift`.

## Phase 39: Maintenance, Alfred System Context, Utilities

Tappable maintenance tasks on PropertyDetailView and DashboardView opening MaintenanceTaskDetailSheet. Alfred system context: "Ask Alfred" card on system detail views pre-loaded with make/model/serial/manuals/warranties via `system_context` param. Utility types expanded with `pest_control` and `landscaping`. SystemGroup reorg (Structure & Exterior = physical structures only, Safety = fire protection only). BrandFetch persistence to `utility_providers` table. 34 new utility providers seeded (propane, pest control, landscaping, water for Northeast US).

## Phase 40: Icon Caching, Task Migration, Dedup, Claims, Seasonal

`BrandLogoCache` actor for session-level Brandfetch caching. Equipment-specific task migration via `MaintenanceTemplate.equipmentKeywords` + `migrateMatchingTasks()`. Invoice systems no longer get generic templates. `resolveOrCreateParent()` with exact/fuzzy/DB-check chain. Insurance claim cost priority fixed: `actualSpend > estimatedBudget > aiEstimatedProCost`. Active quote system (`active_quote_id` on projects, auto-activates first, writes `quoteTotal` to `estimatedBudget`). Retroactive task migration `migrateExistingTaskAssignments()` runs once on auth (V1, UserDefaults gated). Seasonal overview with season-colored progress bar.

## Phase 41a: Vehicle Management Foundation

Household-scoped vehicles with VIN decode via NHTSA + Claude Vision. Tables: `vehicles`, `vehicle_service_records`, `vehicle_recalls`. `documents.vehicle_id` added. Edge Functions: `vehicle-lookup`, `check-vehicle-recalls`. iOS: `VehicleLookupService`, `VehicleDetailViewModel` (computed alerts engine), `AddVehicleView`, `VehicleDetailView`. Vehicles in `PropertyListView` under "Your Garage". Computed alerts for registration/inspection expiry, mileage/time-based maintenance, open recalls. Alfred and Scenario Studio vehicle-aware. Dashboard vehicle alerts card.

## Phase 41c: Unified Vehicle + Home Task System

Vehicle tasks stored in `maintenance_tasks` table (`vehicle_id` column, `property_id` nullable). AI-generated maintenance intervals auto-create task rows on vehicle add. Unified `MaintenanceTaskDetailSheet`. `MaintenanceTaskIcon.swift` for task-specific icons. Vehicle detail splits into ATTENTION + MAINTENANCE sections. One-time `migrateVehicleMaintenanceTasks` for existing vehicles.

## Phase 42: Dashboard Redesign + Household Strip + Member Profiles + Avatar Photos

**DB changes:** `avatar_url` on `family_members` and `trusted_contacts`. `avatars` storage bucket. `assignedToUserId` on `MaintenanceTaskInsert`. `MaintenanceTaskDBRow.synthetic()` factory.

**New files:** `AvatarPhotoService.swift`, `HouseholdStrip.swift`, `UnifiedAttentionList.swift`, `FamilyMemberProfileView.swift` + `FamilyMemberProfileViewModel`.

**Dashboard:** New scroll order with HouseholdStrip, home hero ("YOUR HOME", tasks this month), UnifiedAttentionList (merged overdue/vehicle/expiring/upcoming), compact estate scorecard (single-row navy), compact scenario card, incomplete address banner.

**UnifiedTaskCard** (`Shared/Components/UnifiedTaskCard.swift`): Reusable across all task displays. Category icon, title/location/system, assignee pill with avatar color, vendor pill, priority capsule, due date.

**Vehicle enhancements:** Brand logos via Brandfetch + `BrandLogoCache`. Brand hero card with gradient. Vehicle name tags on maintenance tasks. 4x4 icon grid. Registration/Inspection restyled. `MaintenanceViewModel` fetches vehicles for name resolution.

**Avatar photos:** `FamilyAvatarView` shows `AsyncImage` with SF Symbol fallback. `PhotosPicker` in form. 400px resize, signed URLs.

**Family profiles:** User resolution via linkedUserId/email/name/"Primary Client". Tasks via `assignedToUserId`. Events via `taggedMemberIds`. `sortedByAge()` extension used everywhere.

**Shared utilities:** `String.summarized(maxLength:)`, `UIImage.resizedToFit(maxDimension:)`, `BrandLogoCache` made internal.

**Analytics:** avatarPhotoUploaded/Removed, householdStripMember/Add/ManageTapped, memberProfileViewed, memberProfileDocumentTapped, unifiedAttentionItemTapped.

## Phase 42b: Vehicle Invoice Pipeline + Document VIN Detection + Unified Activity Feed

**`process-invoice`** extended for vehicle invoices (optional `vehicle_id`). Server auto-updates mileage, marks tasks complete, creates `vehicle_service_records`. **`analyze-document`** extracts 17-char VINs via regex, auto-links to vehicles, stores VIN metadata. **`InvoiceChoiceSheet`** has home/vehicle toggle + vehicle picker. Auto-detects vehicle invoices from title keywords. **Unified activity feed:** Every upload creates inbox item. Document type routing (invoices->process, quotes->project, insurance->VIN linking). SHA-256 content hash dedup. **Task dedup:** `createMaintenanceTask` checks existing before insert. **Vehicle detail final layout:** Brand Hero > Reg+Insurance cards > Alerts > Maintenance grid > Service History > Documents > Recalls > Covered Drivers. **New files:** `EditVehicleSheet.swift`, `CoveredDriverPickerSheet.swift`. **Family profiles final:** School field (migration), `covered_driver_ids UUID[]` on vehicles, `hasLoadedOnce` caching. **Many bug fixes** (see CLAUDE.md Phase 42 section of git history for full list).

## Phase 43: Vehicle Detail Overhaul

Scroll order restructured: Hero > Covered Drivers (inline) > Mechanic Card > Stats Row > Unified Attention > Reg/Insurance/Ownership > Maintenance Grid > Service History > Documents > Ask Alfred. Standalone RECALLS section merged into attention. **Mechanic card** with linked contractor, one-tap call, inline "Add New" flow. **Quick mileage update** via tappable pill + compact sheet (can only increase). **Cost tracking** stats row. **Ownership-aware document prompts** (title/lease/loan). **Urgency-colored** maintenance tiles. **Unified Needs Attention** merges recalls + alerts + overdue, green "All good" when empty. **Alert detail sheet** adapts by type. **Registration/Insurance/Ownership** 3-card layout. **Recurring recall checks** in proactive-scan, push notifications for new recalls. **Deep link** for vehicle_recall notifications. **New files:** `MechanicPickerSheet`, `MileageUpdateSheet`. **Analytics:** mechanicLinked/Removed, mileageUpdated, vehicleDocumentPromptTapped, askAlfredVehicleTapped. **Notification:** `.navigateToVehicle`.

## Phase 44: Auth Flow Fix

Race condition eliminated: `AuthService.hasResolvedInitialSession` flag replaces fragile 500ms sleep. Splash screen stays until `.initialSession` event fully processed. Unauthenticated routing simplified: AddressHookView is default landing. LoginView reached only by user action. Changes limited to: `AuthService.swift`, `AppState.swift`, `ContentView.swift`.

## Phase 42 (Email Pipeline): Full Audit, Critical Fixes, Vehicle Routing, Polish

**Phase 42 Audit:** Comprehensive audit of the entire email ingestion pipeline (receive-email > process-inbox-item > analyze-document > iOS inbox views). Documented every classification type, every handler, every gap. Built gap analysis matrix covering 100+ document types across 10 categories.

**Phase 42a -- Critical Fixes:** (1) Expanded iOS category picker from 16 to 88 categories with searchable `DocumentCategoryPicker` sheet. (2) All documents now require user confirmation (high-confidence: "Looks Good" + "Change Category"; low-confidence: picker-first). (3) Insurance claims no longer auto-create projects -- user chooses "Create Claim Project" / "Save as Document". (4) Fixed "Different project" button to show project picker with `move_to_project` action. (5) Projects load across all properties.

**Phase 42b -- Vehicle Routing:** Added `vehicle_document` classification type. `vehicleContext` flag on `bill_invoice` for vehicle service invoices. Vehicle picker in `InboxItemCard`. `process_vehicle_document` action in `process-inbox-item`. 8 new VALID_CATEGORIES (Flood Insurance, Vehicle Registration, Vehicle Purchase/Lease Agreement, Emissions Inspection, Vehicle Loan Statement, K-1 Partnership Return, Appraisal Report, Home Inspection Report). Vehicle section in `DocumentCategoryGroups`.

**Phase 42c -- Polish:** Unsupported file types (.docx/.xlsx/.csv/.zip/.heic) gracefully handled -- stored but analysis skipped with info banner. Improved analyze-document media type detection (GIF/WebP). Family member auto-linking from `key_parties` in analyze-document. Vendor notification "Remove" button. "Saved as [Category]" confirmations for completed items.

**Phase 42d -- Pipeline Unification & Button Standardization:** Processing banner made tappable -- navigates to inbox item via `.navigateToInboxItem` notification. Inbox notification persistence fixed (markInboxItemsSeen now clears needs_action). All action buttons standardized to equal-size HavenButton (primary/secondary) across insurance claims, quotes, and generic documents.

**Phase 42e -- Historical Projects & Document-Project Linking:** `property_projects.entry_type` (planned/historical). `documents.project_id` FK. `LogHistoricalProjectView` (name, category, date, spend, notes). `ProjectDetailView` historical variant (header + documents + notes, no AI scaffolding). `LinkDocumentToProjectSheet` for linking vault docs. `DocumentUploadView`/`DocumentUploadManager` accept `projectId`. InboxItemDetailView "Link to Project" button. `PropertyProjectsView` confirmation dialog for Plan New / Log Completed.

**Misc fixes during Phase 42:** Seasonal tasks expansion (stable ID fix from UUID to name-based). Seasonal subtask rows tappable with MaintenanceTaskDetailSheet. Project $0 display bug (actualSpend=0 winning over estimatedBudget; fixed with >0 checks). Quote budget backfill in loadSubProjects. Vehicle ownership card "Owned for X yr Y mo" instead of "Expired Xd ago".

**Phase 42f -- Unified Duplicate Detection:** Complete overhaul of document duplicate detection across all upload paths. (1) `DocumentUploadManager`: resolveReplace() now deletes old storage file before soft-deleting DB record. `DuplicateResolutionSheet` with 3 equal-size buttons: "Replace Existing" / "Save Both Copies" / "Delete This Document". (2) `DocumentUploadViewModel`: upload now BLOCKED on duplicate detection (was continuing and showing alert after). 3-button alert matching same labels. `discardDuplicate()` added. (3) `receive-email`: `computeContentHash()` helper computes SHA-256 from attachment bytes. `checkDocumentDuplicate()` queries `documents.content_hash` before inserting. All 3 document insert paths (estate/home, vehicle, bill) now set `content_hash` and check for duplicates. Duplicates get `action_type: "resolve_duplicate"` on inbox item. (4) `process-inbox-item`: new `resolve_duplicate` action with replace/save_both/delete sub-actions including storage file cleanup. (5) `analyze-document`: removed redundant content_hash computation (now set at creation time). (6) `InboxItemCard` + `InboxItemDetailView`: `resolve_duplicate` action area with 3 HavenButtons. (7) `ChatView`: 3-button alert. Cross-path dedup verified: same PDF forwarded twice produces `resolve_duplicate` inbox item.

## Phase 45: Bug Fixes, Vehicle UX, Seasonal Simplification, Utility Bill Detection

**Bug fixes:** Project ROI caching (single shared `feasibility` -> `feasibilityByProject: [UUID: ProjectFeasibility]` dictionary). Insurance claim $0 linked projects (`loadSubProjects()` now fetches fresh from DB). Covered driver age filter (under 16 excluded).

**Vehicle detail UX:** Hero card VIN/plate rows converted to centered VStack layout. "View All Tasks" now toggles. Registration card opens doc upload (Vehicle Title category). Insurance card opens Auto Insurance upload. Ownership card opens compact `PurchaseDatePickerSheet` (month/year wheel, adapts label by ownership type). Registration/Inspection fields removed from EditVehicleSheet. MechanicPickerSheet inline "Add New" with shop name + phone.

**Seasonal simplification:** `SeasonalTaskGrouper` groups 14+ tasks into 4-5 categories (Landscaping, Exterior, Safety, HVAC, Water). `SeasonalTaskGroup` model. Collapsible group cards with `CircularProgressView`. Next season shows group-level cards. PropertyDetailView overview card shows group completion.

**Utility bill detection (45b):** `receive-email` fuzzy-matches `billVendor` against `utility_providers`. Embeds provider info or suggestion in inbox metadata. `add_utility_provider` action type. `InboxItemDetailView` branded prompt card. `AddUtilitySheet` extended with prefill parameters. All backward compatible.

## Phase 46: Onboarding Revamp Phase 2 — Force Update Gate + Unified Property Add Flow

**Phase 13 — Force-update gate:** New `app_config` table (migration `20260420_app_config_table.sql`) with `minimum_required_version`/`minimum_required_build` plus `latest_version`/`latest_build`, public read RLS, seeded with the current 1.0.2 / 74 build. New `Bundle+Version` extension with `appVersion`, `buildNumber`, and `isCurrentBuildBelow(marketing:build:)` helper that handles tie-breaking via build number. New `VersionCheckService` actor returns `.upToDate`, `.optionalUpdate`, `.forceUpdate`, or `.checkFailed` (failures never block). `DatabaseService.fetchAppConfig()` + `AppConfigRow` model. `AppState` runs `checkAppVersion()` from `initialize()` in parallel with auth resolution; exposes `requiresUpdate`, `forceUpdateMessage`, `forceUpdateAppStoreURL`, `optionalUpdateLatestVersion`, `optionalUpdateMessage`, and a session-only `optionalUpdateDismissedThisSession` flag (resets on relaunch by design). New `ForceUpdateView` (no dismiss, "Update Now" opens App Store, current version shown for support) wired into `ContentView` ahead of every other route. New `OptionalUpdateBanner` component rendered at the top of the dashboard scroll content with Update / Later actions. `AppConfig.version` switched from a hardcoded `"1.0.0"` to `Bundle.main.appVersion`. Tom bumps the gate by hand from the Supabase SQL editor on each future TestFlight upload.

**Phase 12 — Unified address-first property add flow:** New `PropertyCreationService` actor — single source of truth for ATTOM enrichment, home-system auto-creation, and 12-month maintenance task generation. Takes an `AddressInput` + `householdId` + `propertyType` (and an optional pre-fetched `PropertyLookupResult`); returns a `PropertyCreationResult` with the new `PropertyRow` plus systems/tasks counts and a `lookupSucceeded` flag. New `AddPropertyFlow` view (3 steps: address → ATTOM preview → confirmation) replaces the old multi-field form. Confirmation step offers a primary "Take House Quiz" button and a secondary "Later, just add it"; tapping the quiz button posts a new `.startHouseQuiz` notification with the new `PropertyRow`. Reuses `OnboardingSchedulePreviewStep` for the preview UI so brand-new and authenticated users see identical chrome. `AddressConfirmationIntercept` refactored to delegate to `PropertyCreationService` (its old inline `submit()` and `systemsFromFeatures()` are gone). Routed `PropertyListView` toolbar +, `PropertyListView` empty state, and `DashboardView` Quick Actions / "Add your home" Getting Started step to `AddPropertyFlow`. Dashboard listens for `.startHouseQuiz` and assigns to `activeQuizProperty` so its existing `fullScreenCover(item:)` opens `HouseQuizView` for the new property. **Deleted:** `AddPropertyView.swift` (~160 lines) and `HomeSystemsSetupView.swift` (the manual checklist screen, ~1200 lines) — the latter is no longer needed because systems auto-create from ATTOM and the new House Quiz handles any gaps. Verified zero remaining references via grep.

## Phase 47: Trust-First Refinements (Phase 14 — TestFlight Bug Fixes)

Four targeted fixes after Tom's TestFlight testing of the new property-add flow exposed places where the system broke user trust the first time they ran it.

**FIX 2 — Universal home systems:** `PropertyCreationService.systemsFromFeatures()` now *always* creates HVAC, Roof, Water Heater, and Electrical Panel regardless of whether ATTOM returned feature data. The `systemsFromFeatures` call moved outside the `if let features` guard so it runs on every creation, and the feature argument is now `Optional`. HVAC no longer requires a non-nil `heatingType`/`coolingType`, and Roof no longer requires `roofType` (falls back to "Roof" when ATTOM is silent). Foundation, Crawl Space, and Basement systems are now feature-gated on `features.foundationType`. Pool/Garage/Fireplace remain gated on their respective ATTOM flags. The Maintenance tab is never empty for a new property, even when ATTOM/RentCast returned no record.

**FIX 3 — Pre-quiz task filter + post-quiz subtype migration:** `MaintenanceTemplates.templates(for:activeSubtypes:)` no longer short-circuits on empty `activeSubtypes` — the `requiredSubtypes.isSubset(of:)` filter now runs unconditionally, so pre-quiz only universal templates (empty `requiredSubtypes`) pass. "Descale tankless heater" no longer appears for users who haven't confirmed a tankless heater. The HVAC `default:` case in `activeSubtypes` no longer preemptively inserts `ducted`+`has_ac`+`has_furnace` — it returns an empty set so "Inspect ductwork for leaks" and similar ducted-specific tasks stay hidden until the user confirms their HVAC type. New `MaintenanceTaskMigrator.addSubtypeTasks(propertyId:householdId:systemCategory:systemId:previousSubtype:newSubtype:fuelType:flags:)` helper computes the delta between old and new `activeSubtypes`, filters `essentialTemplates` for newly-unlocked tasks, and creates them via the existing `DatabaseService.createMaintenanceTask` dedup path. `HouseQuizAnswerMapper` is now wired into the migrator from `q1_roof_material`, `q3_heating_fuel`, `q8_water_heater`, and `q11_lawn`. Includes two static helpers `roofingSubtype(forQuizAnswer:)` (maps asphalt→asphalt_shingle, flat_membrane→flat_membrane, wood_shake→wood_shake) and `hvacSubtype(forFuel:)` (natural_gas/propane→central_ducted, oil→boiler_radiant, electric→heat_pump, geothermal→geothermal). `ensureHomeSystem` gained `subtype:` and `matchByCategory:` parameters — singleton categories (HVAC/Roofing/Water Heater/Landscaping) now update the `PropertyCreationService`-created row in place instead of creating a duplicate, and subtype is persisted to `home_systems.subtype` so future `activeSubtypes` reads pick it up. New file: `Haven/Features/Property/Services/MaintenanceTaskMigrator.swift`.

**FIX 1 — Auto-create primary family_member on property creation:** `PropertyCreationService.ensurePrimaryFamilyMember(householdId:)` runs after the property row is created. Resolves first/last name from the auth session in the same order `OnboardingViewModel.prefillFromAuth()` uses: `first_name`/`last_name` metadata → Apple's `given_name`/`family_name` → parsed `full_name`/`name` string → email local part → "Me". Dedup is defensive — skips when a `family_members` row already has `linked_user_id == currentUserId` OR when an unlinked "Primary Client" row's email matches the current user. Creates with `relationship: "Primary Client"`, `avatarColor: "navy"`, and the current `session.user.id` as `linkedUserId`. Call wrapped in `try?` so a failure never blocks property creation. Required adding `linkedUserId: UUID?` to `FamilyMemberInsert` (with the `linked_user_id` CodingKey) and a new `DatabaseService.fetchFamilyMembers(householdId:)` scoped query. Fixes the trust-breaking case where a soft-purged user who added their first property via `AddPropertyFlow` / `AddressConfirmationIntercept` ended up with zero family_members and an empty dashboard HouseholdStrip.

**FIX 4 — Quiz X button saves and exits, milestone gets Save for later:** `HouseQuizView` toolbar X button now shows a "Save and exit?" confirmation dialog with "Save and exit" / "Cancel" buttons instead of the old "Skip for now" / "Skip forever" menu. Dismissing is safe because `HouseQuizViewModel.persist()` already writes state after every answered question and `firstUnresolvedIndex()` resumes at the next unanswered question on reopen, so no new `saveCurrentState()` or `start()` helpers were needed. The "Skip forever" affordance moved into a new `Menu` with an ellipsis icon sitting next to the per-question "Save for later" link, with its own confirmation dialog so accidental taps don't permanently skip questions. The section-complete milestone card now shows a secondary "Save for later" text button beneath the primary "Keep Going" button; tapping it dismisses the quiz and the user resumes at the first unanswered question of the next section on reopen (milestone card itself is skipped because it only triggers after recording an answer).
