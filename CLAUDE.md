# Haven -- Context for Claude Code

## Who You're Working With

Tom Burke. Solo founder/developer of Haven. Full-time AE at Salesforce, so bandwidth is the scarcest resource. Strong design eye, catches subtle UI and writing issues (e.g., em dashes reading as AI-generated). Reviews running app screenshots and gives specific, detailed feedback. Expects Claude to read actual file state before making changes -- never guess component names, design tokens, model strings, or architecture patterns.

## What Haven Is

A native iOS app (SwiftUI, iOS 17+) combining estate document intelligence with home property management. Backed by Supabase and Claude AI (via Edge Functions). No competitor offers this combination. Target audience: high-net-worth families ($500K-$5M net worth).

**The core insight:** Haven's AI creates intelligence, not just convenience. Documents get analyzed, gaps get identified, scenarios get simulated. The real competition is insecure alternatives (Google Drive, email attachments, filing cabinets) -- not enterprise vault solutions.

**Status:** TestFlight with public link (`https://testflight.apple.com/join/sw4xWsTA`). App Store Connect ID: `6757167606`. Version 1.0.2, build 85.

## Hard Rules

- **Pure iOS.** No web components, no React, no HTML, no Node.js server code in the app.
- **100% SwiftUI targeting iOS 17+.** The only backend is Supabase (hosted).
- **Claude API key is NEVER in iOS client code.** All AI calls go through Supabase Edge Functions.
- **No pure white anywhere.** The cream canvas (#F2EEE5) is the background for everything.
- **No em dashes in user-facing copy.** They read as AI-generated to Tom's audience.
- **Deploy Edge Functions with:** `supabase functions deploy [name] --no-verify-jwt`
- **Supabase CLI must be linked first:** `supabase link --project-ref jsucwnkntdrxhysojgri`
- **Read before writing.** Always read the actual file before modifying it. Never approximate.

## Identity & Config

- **Bundle ID:** `com.havenhome.app`
- **Team ID:** `RW9CWCAWGQ`
- **Supabase project:** `jsucwnkntdrxhysojgri` (`https://jsucwnkntdrxhysojgri.supabase.co`)
- **Supabase anon key:** In `AppConfig.swift`
- **Website:** havenhome.dev (static site in `website/` directory, Docker/nginx)
- **Email domain:** alfred.havenhome.dev (SendGrid Inbound Parse)
- **Developer email:** tom@havenhome.dev

## Third-Party APIs

- **Claude API** -- All AI features, server-side from Edge Functions only
- **Google Places API** -- Address autocomplete (`GooglePlacesService.swift`)
- **ATTOM Data Solutions** -- Primary property data provider. AVM with confidence score, tax assessment, sales history, owner info. Env var: `ATTOM_API_KEY`.
- **RentCast** -- Fallback property data (when ATTOM returns no results). Env var: `RENTCAST_API_KEY`.
- **Brandfetch API** -- Brand logos for vendors, contractors, manufacturers, utility providers. `BrandLogoCache` actor provides session-level caching (both URL and full response with brand color/domain). Logos display in system detail, contractor cards, utility accounts, vehicle hero, etc.
- **SendGrid** -- Inbound Parse for email pipeline (alfred.havenhome.dev), transactional email
- **Stripe** -- Payment infrastructure (test mode, publishable key in client)
- **Apple Sign In** -- Primary auth method
- **NHTSA APIs** -- Vehicle VIN decode and recall checking

## Brand & Design System

### Colors (see `Haven/Shared/Theme/HavenColors.swift`)
- **Cream canvas:** `#F2EEE5` (background everywhere)
- **Cream light:** `#F8F6F1` (cards, elevated surfaces, tab bar)
- **Cream white:** `#FAF7F2` (sheets, modals)
- **Navy primary:** `#1B2A4A` (text, buttons, icons, FAB -- this is "the ink")
- **Navy 700:** `#243660` (pressed states, active tab icons)
- **Beige 200:** `#F0EBE1` (subtle borders, input backgrounds)
- **Beige 300:** `#E3D9C6` (stronger borders, dividers)
- Semantic: success (green), warning (amber), critical (red), info (blue)
- Full dark mode support with adaptive color assets

### Typography (see `Haven/Shared/Theme/HavenTypography.swift`)
- **Georgia serif** for content people READ: headings, body, descriptions, chat
- **SF Pro (system)** for UI chrome people SCAN: labels, metadata, buttons, tabs
- Nav titles: Georgia Bold. Body/chat: Georgia 14pt. Section headers: System 10pt semibold ALL CAPS.

### Spacing & Layout (see `Haven/Shared/Theme/HavenTheme.swift`)
- 4pt grid. Page margin: 20pt. Card radius: 16pt. Button radius: 14pt.
- Shadows: warm navy-tinted (never pure black), disabled in dark mode
- Animation: "luxury watch" not "bouncing ball" -- high damping, smooth (0.35s response, 0.85 damping)
- Min touch target: 44pt. Button height: 50pt.

### Shared Components (see `Haven/Shared/Components/`)
`HavenCard`, `HavenButton`, `HavenTextField`, `EmptyStateView`, `ErrorView`, `LoadingView`, `ProcessingBanner`, `FamilyAvatarView`, `AlfredLogoView`, `AddressAutocompleteField`, `UnifiedTaskCard`

## Tab Architecture (MainTabView.swift)

| Tab | Index | Label | Icon | Root View |
|-----|-------|-------|------|-----------|
| Dashboard | 0 | Dashboard | `square.grid.2x2.fill` | `DashboardView` |
| Property | 1 | Property | `building.columns.fill` | `PropertyListView` |
| Life | 2 | Life | `heart.text.square.fill` | `DocumentVaultView` |
| Alfred | 3 | Alfred | Serif "A" monogram circle | `ChatView` |

**Floating Action Button:** "What If?" sparkles button on every tab except Alfred. Opens `ScenarioStudioView` as fullScreenCover. Collapses to icon-only after first use.

**Cross-tab notifications:** `.switchToTab`, `.popToRoot`, `.openScenarioStudio`, `.openAlfredWithContext`, `.navigateToVehicle`, plus data sync notifications for maintenance, systems, contractors, documents, properties, projects.

**Navigation:** Custom tab bar with pop-to-root via NotificationCenter. Tab taps reset navigation stack.

## Project Structure

```
/Users/tomburke/Projects/Housing-Manager/
├── Haven/                          # iOS app (SwiftUI)
│   ├── App/                        # HavenApp, AppState, MainTabView, ContentView
│   ├── Config/                     # AppConfig, Info.plist, entitlements
│   ├── Core/
│   │   ├── AI/                     # DocumentAnalysisService
│   │   ├── Auth/                   # AuthService, AuthViewModel, SessionManager, AppleSignInCoordinator
│   │   │   └── Views/Onboarding/  # OnboardingView/ViewModel, AddressHookView
│   │   ├── Networking/            # APIClient, DatabaseModels, DatabaseService, SupabaseClient, TokenManager
│   │   ├── Security/             # DocumentEncryption, JailbreakDetection, ScreenshotPrevention, VaultLockService, SecureLogger
│   │   ├── Services/             # AnalyticsService, AvatarPhotoService, CalendarSyncService, DocumentUploadManager, DuplicateDetectionService, GooglePlacesService, ScenarioRunnerService
│   │   └── Storage/              # CacheManager, EncryptionService, SecureStorageService
│   ├── Features/
│   │   ├── Chat/                  # Alfred AI chat
│   │   ├── Dashboard/             # DashboardView, HouseholdStrip, UnifiedAttentionList, FamilyMemberProfileView, SmartRecommendations, EnrichmentCardEngine
│   │   ├── Documents/             # DocumentVaultView, upload, scan, detail, gap analysis, invoice processing
│   │   ├── Family/               # FamilyInboxView, CalendarSyncSheet
│   │   ├── Inbox/                # InboxView, InboxItemCard, InboxItemDetailView
│   │   ├── Notifications/        # NotificationService, PushNotificationService, NotificationScheduler
│   │   ├── Property/             # PropertyList/Detail, maintenance, systems, warranties, vendors, projects, quotes, equipment, utility accounts, vehicles, seasonal tasks
│   │   ├── Scenarios/            # ScenarioStudioView/ViewModel
│   │   ├── Security/             # SecurityDashboardView
│   │   └── Settings/             # Profile, family members, household access, invitations, trusted contacts
│   └── Shared/                    # Components (incl. UnifiedTaskCard), Extensions, Theme, Utilities
├── supabase/
│   ├── functions/                 # 35+ Edge Functions (see supabase/functions/CLAUDE.md)
│   ├── migrations/                # 70+ migration files
│   ├── schema.sql
│   └── config.toml
├── website/                       # havenhome.dev (index.html, security.html, Docker/nginx)
├── catalog-data/                  # 34 SQL seed files for equipment catalog
├── scripts/
├── preserved/                     # Legacy assets, credentials, branding
└── project.yml                    # XcodeGen project spec
```

## Supabase Database (Key Tables)

households, users, family_members (avatar_url, school, member_type), properties, home_systems (parent_system_id), maintenance_tasks (vehicle_id, property_id nullable, assigned_to_user_id, assigned_contractor_id, assignment_type, needs_vendor), documents (vehicle_id, project_id, visible_to_home_managers), document_content, document_parties, document_family_members, warranties, contractors (category, utility_provider_id, logo_url, brand_color, website, source), service_records, service_contracts, chat_messages, concierge_messages, scenario_history, completion_scores, access_logs, dismissed_categories, trusted_contacts (avatar_url), trusted_contact_documents, household_invitations, household_email_addresses, inbox_items, inbox_attachments, property_projects (active_quote_id, entry_type), project_quotes, project_line_items, project_files, project_contacts, project_visualizations, family_events, synced_calendars, device_tokens, equipment_catalog, equipment_scores, utility_accounts, utility_providers, local_vendor_results, analytics_events, property_lookups_cache, allowed_senders, vehicles (covered_driver_ids), vehicle_service_records, vehicle_recalls

**RLS is on everything.** All tables scoped by `household_id`. Service role key is only used in Edge Functions.

**Documents have a per-row home manager visibility flag (Build 87).** `documents.visible_to_home_managers` (default true) gates the SELECT policy `household_documents_select` so callers whose `family_members.linked_user_id` has `member_type IN ('home_manager', 'staff')` only see rows with the flag true. Family members and the homeowner see every document. INSERT, UPDATE, and DELETE policies are unchanged. Categories that default to private are listed in `Haven/Features/Documents/DocumentAccessDefaults.swift` (Swift) and `PRIVATE_FROM_HOME_MANAGERS` (TypeScript) at the top of `receive-email`, `process-inbox-item`, and `analyze-document` Edge Functions. See "Home Manager Role" section under Family Members & Profiles for the full enforcement story.

**Sub-system hierarchy:** `home_systems.parent_system_id` (nullable FK to self, ON DELETE CASCADE). Parent/child relationships (e.g., Well System -> Acid Neutralizer, UV Filter). UI shows top-level systems in lists, children inside parent's detail as "Components".

**Unified task system:** `maintenance_tasks` table stores both home and vehicle tasks. `vehicle_id` column (nullable) links vehicle tasks; `property_id` is nullable. When vehicles are added via VIN, AI-generated maintenance intervals auto-create task rows.

**Vendor-aware task assignment (Phase 19k+):** Every maintenance task has an `assignment_type` of `personal` (DIY), `vendor` (pro-managed), or `either` (defaults to personal but can be flipped). Vendor tasks with a matching contractor on file get `assigned_contractor_id` linked + title reframed to "Schedule [Vendor]: [task]". Vendor tasks with no contractor get `needs_vendor: true` and the title becomes "Find a contractor for: [task]". The `contractors` table now has `category` for fast reconciler lookup, `utility_provider_id` to mirror back to the catalog when sourced from the quiz, snapshotted brand identity (`logo_url`, `brand_color`, `website`), and a `source` discriminator (`manual` / `quiz` / `find_vendor`). The `local_vendor_results` cache table stores Google Places lookups for the find-a-contractor flow with a 60-day TTL keyed by `(town, state, category)`.

## Edge Functions (supabase/functions/)

See `supabase/functions/CLAUDE.md` for detailed patterns and full inventory. Key groups:

**Core AI:** `analyze-document` (also rewrites `documents.visible_to_home_managers` based on the AI-suggested category — manual upload paths set placeholder categories at insert time, this is the place that stamps the real value), `chat`, `gap-analysis`, `simulate-scenario`, `proactive-scan`
**Invoice:** `process-invoice` (home + vehicle invoice intelligence)
**Property/Equipment:** `search-equipment`, `identify-equipment`, `lookup-manual`, `score-equipment`, `research-project`, `project-feasibility`, `property-lookup`, `visualize-room`
**Quotes:** `analyze-quote`, `draft-negotiation-email`
**Email Pipeline:** `receive-email` (with utility bill detection; sets `visible_to_home_managers` on every document insert via the local `PRIVATE_FROM_HOME_MANAGERS` set), `process-inbox-item` (same)
**Vehicle:** `vehicle-lookup` (VIN decode + recalls + maintenance schedule), `check-vehicle-recalls`
**Brand:** `brand-logo` (Brandfetch wrapper for all logo fetching)
**Household:** `merge-households`, `delete-account`, `send-push-notification`
**Vendor/Document:** `extract-vendor`, `view-document`
**Catalog:** `enrich-catalog`, `expand-catalog`, `scrape-manuals`, `download-manuals`, `upload-manual`, `send-catalog-request`, `score-property`
**Local Vendors (Phase 19n):** `find-local-vendors` (Google Places Text Search + 60-day cache via `local_vendor_results` table; returns up to 4 vendors per (town, state, category) with Haven Certified badge on top 2 that meet 4.7+ stars + 25+ reviews + non-chain heuristic)

All use `claude-sonnet-4-6`. All return JSON. All use CORS headers. All deployed with `--no-verify-jwt`.

## iOS Networking Pattern

All Edge Function calls go through `HavenSupabase.callEdgeFunction()` in `SupabaseClient.swift`: refreshes auth session, builds URL, attaches apikey + Authorization headers, encodes JSON body, returns raw Data. Typed convenience methods exist for each function.

## Dashboard Architecture

**Scroll order:** screenTitle("Haven") > greeting > merge banner > **HouseholdStrip** (horizontal avatar strip, age-sorted, "+" add, "Manage" link) > **HouseholdStaffStrip** (Build 87 — paid staff strip, hidden when household has no staff, separate "+" routes to Settings) > expecting members > Getting Started / Recommendations > inbox section > email forwarding callout > enrichment cards > **home maintenance hero card** ("YOUR HOME", **dual count: "X to do · Y vendor-managed"** since Phase 19l, overdue pill only when > 0, listens for `.contractorAdded` to re-fire post-quiz vendor delegation sheet) > **UnifiedAttentionList** (merged overdue tasks, vehicle alerts, expiring docs/warranties, upcoming maintenance; shows 3 with "See all") > Quick Actions (Maintenance left, Upload right) > **compact estate scorecard** (single-row navy card with progress bar) > **compact scenario card** (single-row, requires 3+ docs) > security badge > incomplete address banner (amber, for properties missing street/city)

## Property Overview (Build 84)

**`InvestmentSummaryCard` layout:** hero (estimated value, range, source caption, gain/loss vs invested) > stacked bar (purchase / projects / surplus or gap) > bottom summary (net after sale, unrealized gain/loss) > expand toggle > waterfall breakdown (when expanded) > **`equityUpsellCard`** (Build 84 — navy gradient sub-card, only when `hasEstimatedValue == true`, anchors `HookContent.Page1.equityHeadline` "Homes maintained well sell for ~7.4% more." to the user's actual `estimatedValue * 0.074` formatted via `formatCurrencyCompact`) > sale simulator button.

**Empty state when no estimated value:** "Add estimated value" CTA + Build 84 secondary "Refresh from public records" button. The refresh button calls `PropertyDetailViewModel.refreshFromPublicRecords(appState:)` which re-fires `HavenSupabase.propertyLookup` and walks the Build 84 ATTOM fallback ladder (canonical → midpoint of range → high → low → tax assessment) before persisting via one `PropertyUpdate`.

**ATTOM fallback ladder (Build 84):** Both `OnboardingViewModel.runComplete` and `PropertyDetailViewModel.refreshFromPublicRecords` use the same ladder so persistence is consistent across creation and retroactive refresh: `propertyLookupResult.estimatedValue` → `(low + high) / 2` → `estimatedValueHigh` → `estimatedValueLow` → `taxAssessment.assessedValue`. Diagnostic logging captures every signal considered so trust failures are traceable from a screenshot. Fixes the case where ATTOM returned a range without a canonical value and the user saw empty pills on the dashboard despite seeing a value in `PropertyHookView`.

## Vehicle Management

Household-scoped (not property-scoped). Tables: `vehicles`, `vehicle_service_records`, `vehicle_recalls`. Edge Functions: `vehicle-lookup` (NHTSA + Claude Vision VIN decode, recalls, AI maintenance schedule), `check-vehicle-recalls`. iOS files: `VehicleLookupService`, `VehicleDetailViewModel`, `AddVehicleView`, `VehicleDetailView` (with `EditVehicleSheet`, `MechanicPickerSheet`, `MileageUpdateSheet`, `CoveredDriverPickerSheet`, `PurchaseDatePickerSheet`). Vehicles appear in `PropertyListView` under "Your Garage".

**Vehicle detail layout:** Brand Hero (brand color gradient, logo, full VIN monospaced, license plate, color, year/model/trim, mileage pill with quick-update, ownership, primary driver, website) > Covered Drivers (inline overlapping avatars, tap to edit, age 16+ filter) > Mechanic Card (linked contractor, one-tap call, inline "Add New" flow) > Stats Row (Total Spent / Service Count / Last Service) > Unified Attention (recalls + reg/inspection alerts + overdue maintenance, green "All good" when empty) > Registration/Insurance/Ownership cards (3-card layout, tappable) > Maintenance Grid (4-column labeled tiles, urgency color-coded, "View All" toggle) > Service History (mileage at service, total cost footer) > Documents (long-press to unlink/delete) > Ask Alfred (vehicle context) > Recalls (DisclosureGroup, always shown)

**Document VIN detection:** `analyze-document` extracts 17-char VINs via regex, matches against household vehicles, auto-links documents. Stores `detected_vins`, `matched_vehicle_ids`, `unmatched_vins` in metadata.

**Alfred and Scenario Studio are vehicle-aware.** `proactive-scan` checks NHTSA for new recalls, sends push notifications.

## Invoice Processing

User-initiated flow: document analysis categorizes upload as invoice type -> `InvoiceChoiceSheet` (home/vehicle toggle when both exist) -> user picks property or vehicle -> `process-invoice` Edge Function -> `InvoiceReviewSheet` (toggle tasks/systems/follow-ups). Can be triggered retroactively from `DocumentDetailView` via "Scan for Maintenance & Systems".

**Parent system grouping is deterministic** (not AI): keyword table in `InvoiceProcessingViewModel` maps components to parents across 12 groups (well, HVAC, pool, electrical, septic, security, solar, irrigation, generator, garage door, fire protection, roofing). Unmatched systems show picker for user assignment. Duplicate detection uses fuzzy matching (word overlap, model number, manufacturer+function, functional type with qualifier awareness). Parent systems auto-created if needed. All referenced systems get `last_service_date` updated.

**Vehicle invoice mode:** `process-invoice` accepts optional `vehicle_id`. Server auto-updates mileage, marks matched tasks complete, creates `vehicle_service_records`.

**Unified Activity Feed:** Every document upload creates an inbox item. Document types route to appropriate flows: invoices -> process-invoice, quotes/estimates -> project linking, auto insurance -> VIN linking. `DocumentUploadManager` computes SHA-256 content hash for duplicate detection.

Key files: `process-invoice/index.ts`, `InvoiceProcessingModels.swift`, `InvoiceProcessingViewModel.swift`, `InvoiceReviewSheet.swift`, `InvoiceChoiceSheet.swift`.

## Equipment & Task Management

**Equipment catalog:** 34 SQL seed files in `catalog-data/`. Edge Functions for search, photo ID, manual lookup, scoring, enrichment.

**Task-specific icons:** `MaintenanceTaskIcon.swift` maps task types to SF Symbols (oil_change="drop.fill", tire_rotation="tire", brake="pedal.brake.fill", etc.) with `shortLabel(for:)` and `intervalLabel(for:)`.

**UnifiedTaskCard** (`Haven/Shared/Components/UnifiedTaskCard.swift`): Single reusable task card across all views. Three render variants gated on `assignmentType` + `needsVendor` + `assignedContractorId` (Phase 19l): (1) **personal** — existing layout with 32x32 category icon, title, location tag, system, assignee pill, priority capsule, due date, plus an effort badge ("5 min", "1 hr 30 min") and an optional `diyEffortLabel` caption underneath, plus a "Have someone else do it →" footer link that opens the contractor picker. (2) **vendor-managed** — vendor logo (or branded initial fallback) on the left, reframed title ("Schedule Petro: annual boiler service"), vendor name + cost subtitle, no effort badge, no assignee pill. (3) **find-a-contractor** (Build 88 redesign) — navy `calendar.badge.clock` icon, action-first title ("It's time to clean the gutters"), "Would you like Haven to find you a vetted local pro?" subtitle, dual CTA buttons: "Find a Pro" (primary navy fill, opens `FindLocalVendorSheet`) and "Add Your Own" (outlined, opens `ContractorDirectoryView` for manual entry / contacts import). Bundled tasks show a sub-item count ("This covers 7 items."). `onAddOwnVendor` callback added alongside the existing `onFindVendor`.

**TaskAssignmentType pattern (Phase 19k+):** Every `MaintenanceTemplate` is classified at definition time as `personal` (DIY-only — replace HVAC filter, brush turf, test smoke detectors), `vendor` (always pro — annual boiler service, chimney sweep, septic pump, well water lab test), or `either` (could go either way — defaults to personal but flippable). Personal templates carry `diyEffortMinutes` and an optional `diyEffortLabel`. Vendor templates always create with `assignment_type: "vendor"` — if a matching contractor exists in the household, the task gets `assigned_contractor_id` linked + title reframed, otherwise it lands as a "Find a contractor for: X" task with `needs_vendor: true`. Either templates default to personal but the `PostQuizVendorDelegationSheet` and the per-task "Have someone else do it" toggle can flip them to vendor in bulk or one at a time. The audit covers all 132 templates (~60% personal, 22% vendor, 18% either).

**Reframing voice for vendor-managed tasks:** Title format is `"Schedule [Vendor]: [original title lowercased]"` (e.g. "Schedule Petro: annual boiler service"). Description prepends `"Your job: book the appointment and be home for it. [Vendor] will handle the work.\n\nWhat they'll do:\n[original]"`. For find-a-contractor placeholders the title is `"Find a contractor for: [task lowercased]"` and the description prepends `"We'll find you a vetted local pro for this. In the meantime, here's what they'll do:"`. Verbs are intentionally action-first to match how HNW Westchester users think about delegation.

**Two-bucket maintenance UI (Phase 19l):** `MaintenanceScheduleView` groups tasks into two collapsible buckets — **YOUR TO-DOS** (personal + either) and **VENDOR-MANAGED** (vendor + needs_vendor) — when no filter is active. Per-property collapsed state persists in UserDefaults. The dashboard hero card shows the dual count `"X to do · Y vendor-managed"` and tapping navigates to the maintenance list. The `PostQuizVendorDelegationSheet` fires once at quiz completion when any contractor in the household has matching `either`-tagged tasks they could take over, and re-fires from the dashboard whenever a new contractor is added (via the `.contractorAdded` notification).

**Bidirectional task switching:** `MaintenanceViewModel.convertToVendorManaged(taskId:contractor:)` reframes the title and description in place, sets `assigned_contractor_id`, flips `assignment_type` to vendor. `convertToPersonal(taskId:)` looks up the original template by `templateId` (the stable `templateKey` = `"category:title"` set at definition time, never changed) and restores the canonical wording. The reconciler dedups by `templateId` instead of title so reframing never creates duplicates.

**Vendor Preference Tiers (Build 88):** Replaces the old 1-10 slider with 3 clear tiers: `.diy` ("I handle it"), `.mixed` ("Mix of both"), `.hireOut` ("Hire it out"). Stored as `properties.attributes["vendor_preference_tier"]` (string: "diy", "mixed", "hire_out"). Backward-compatible: reads legacy `vendor_preference_level` int and maps 1-3 → diy, 4-7 → mixed, 8-10 → hireOut. `VendorPreferenceTier` enum in `MaintenanceTaskReconciler.swift` owns the mapping and labels. Captured at the end of the House Quiz via Q36 (now `.singleChoice` with 3 options) and editable later via `Settings → Maintenance Preferences` (`MaintenancePreferencesView` -- 3-chip picker, navy fill on selected). `MaintenanceTaskReconciler.resolveAssignment(template:preferenceTier:)` is the deterministic threshold: `.diy` → all personal, `.mixed` → effort > 30 min goes to vendor, `.hireOut` → all vendor. `flipEitherTasksForPreference` strictly preserves user-touched tasks and tasks with explicit contractor links. The old `VendorPreferenceSlider` component and `.slider` question kind are deleted.

**Bundled Service Visits (Build 88):** Related vendor templates are grouped into seasonal service visits via `MaintenanceTemplate.bundleId` (e.g. "Landscaping:spring") and `bundleTitle` (e.g. "Spring Landscaping Service"). The reconciler creates ONE `maintenance_tasks` row per bundle instead of one per template, with the individual items listed as a "What's included:" checklist in the `notes` field. The task's `templateId` is set to the `bundleId` for dedup. 13 bundles across Landscaping, HVAC, Roofing, Security, Generator, Crawl Space, Siding/Exterior, Water Heater, Well System, and Plumbing. Standalone vendor tasks (septic pump, termite inspection, etc.) keep their individual rows. Custom user tasks are never bundled. When a vendor is linked, the bundle title is reframed via Phase 19l's "Schedule [Vendor]: [bundleTitle]" voice.

**Maintenance segmented filter (Build 87):** `MaintenanceScheduleView` adds a top-of-list All / Mine / Vendor segmented Picker (`MaintenanceViewFilter` enum) above the four stats chips. `.all` is the default and renders both personal and vendor buckets stacked (existing behavior). `.mine` and `.vendor` collapse to a single bucket fully expanded — the bucket header drops its chevron because there's only one section visible. The four stats chips (Overdue / This Week / This Month / Later) recompute via the centralized `tasksMatchingViewFilter` predicate so the header counts always match what's on screen. Per-property persistence via UserDefaults under `maintenance_view_filter_<propertyId>` mirrors the existing bucket-collapse storage pattern.

**Pool vs Hot Tub (Build 87):** Q12 creates DIFFERENT systems based on the answer instead of forcing every Pool/Spa answer through a single parent + 3 pool children. `hot_tub` → "Hot Tub" system with subtype `"hot_tub"`, no children, hot-tub-only templates. `in_ground` / `above_ground` → "Pool" system with the matching pool-type subtype + 3 pool children, full pool template suite. `both` → BOTH systems created separately. The Pool ensureHomeSystem call uses the new `excludeSubtype: "hot_tub"` parameter so the matchByCategory lookup never collapses into the Hot Tub row. Q12b (`q12b_pool_chemistry`) composes chemistry into the existing pool subtype as a composite token (`"pool_inground_chlorine"`, `"pool_above_ground_salt"`, etc.). `MaintenanceTemplates.activeSubtypes` for `"pool/spa"` short-circuits on `"hot_tub"` (emits ONLY `"hot_tub"` — never the pool umbrella), and parses pool composites via substring matching to emit the umbrella `"pool"` token plus pool-type and chemistry facets. Pool templates gate on `["pool"]`, chemistry-specific templates gate on `["pool", "pool_chlorine"]` or `["pool", "pool_salt"]`. Four new hot tub templates (`"Test and sanitize hot tub water"` weekly personal, `"Clean hot tub filter"` monthly personal, `"Drain and refill hot tub"` quarterly either, `"Inspect hot tub cover and jets"` annually either) are gated on `["hot_tub"]`. One-time migration `migrateHotTubSystemsOnceIfNeeded` (UserDefaults `hasMigratedHotTubSystems_v1`) converges legacy build 86 hot-tub-only households to the new model: deletes the three legacy pool children, archives orphaned pool tasks, renames the parent to "Hot Tub", and re-runs the reconciler. `pool_type == "both"` is intentionally out of scope for V1.

**Vendor discovery delegation flow (Build 87):** When the user taps "Have someone else do it" on a personal task, `ContractorDirectoryView` now renders a "FIND A PRO" section above the YOUR CONTRACTORS list with two cards: "Find vetted local pros" (opens `FindLocalVendorSheet` with the task's town/state/category via the parent's `onFindLocalVendors` callback) and "Ask Alfred" (posts `.openAlfredWithContext` with a prefilled "Help me find someone to handle this task" message and dismisses the picker). Driven by an opt-in `delegationContext: DelegationContext?` init param so non-delegation entry points (Settings → Contacts) keep their original layout. The contractor selection path also fires the delegation context's `onVendorSelected` callback so the existing `convertToVendorManaged` flow keeps working. `ChatView.openAlfredWithContext` was loosened to accept message-only payloads (contextType / contextId are now optional) so the delegation flow's free-form task description lands in the composer without a known context type.

**Contractor mirror (Phase 19k):** When the quiz captures a service-category vendor via `createUtilityAccount(from:fallbackType:)` or `createUtilityAccount(name:type:)`, `mirrorContractorIfNeeded` ALSO creates a matching `contractors` row with `source: "quiz"`, `category` set (HVAC / Plumbing / Landscaping / etc.), and the catalog row's `logo_url` + `brand_color` + `website` snapshotted. The reconciler picks up these mirrored rows by category match at task-creation time. Service categories that mirror: landscaping, pool_service, pest_control, irrigation, security, solar, hvac, plumbing, roofing, electrical. Utility-bill types (electric, internet, oil, gas, water, propane, trash) are intentionally excluded — they're not contractors.

**Equipment task migration:** `MaintenanceTemplate.equipmentKeywords` field. When a child system is added, matching tasks migrate from parent to child via `migrateMatchingTasks()`. Invoice-discovered systems get tasks only via migration or AI follow-ups (not generic templates). Retroactive migration runs once on auth (V1, UserDefaults gated).

**Task deduplication:** `DatabaseService.createMaintenanceTask()` checks for existing tasks with same title (case-insensitive), household, property/vehicle, and system before inserting. The reconciler additionally dedups by `templateId` (Phase 19k).

**Template state interpolation (Phase 19j):** `MaintenanceTemplate.interpolated(city:state:)` substitutes `{city}` and `{state}` placeholder tokens in title / description / notes. The reconciler fetches the property once and runs every template through interpolation before building task inserts so users see "Time it to soil temps in the low 50s in NY" instead of the raw token.

**Active quote system:** `active_quote_id` on projects. First quote auto-activates. `quoteTotal` writes to `estimatedBudget`. Long-press to change active quote.

**Seasonal tasks:** `SeasonalTaskGrouper` groups individual tasks into 4-5 homeowner-friendly categories (Landscaping, Exterior, Safety, HVAC, Water). Collapsible group cards with `CircularProgressView` progress rings.

## House Quiz

**37 questions across 6 sections.** Quiz state persists to `properties.house_quiz_state` JSONB after every answer. `firstUnresolvedIndex()` resumes at the next unanswered question on reopen. Section milestones (`milestoneIndices = [5, 10, 18, 23, 29, 36]`) trigger fun-fact cards between sections.

**Question kinds (`HouseQuizQuestionKind`):** `singleChoice`, `multiSelect`, `currency`, `yesNoLender`, `vehicleCount`, `vehicleAdd`, `providerSearch`, `caretakers`, **`generatorAdd`** (Phase 19i — Q22 progressive 3-step generator type/fuel/provider form), **`householdContractors`** (Phase 19m — Q15b multi-select contractor chips with inline pickers). The legacy `.slider` case is kept for backward-compatible decode but renders as `singleChoiceBody` at runtime (Build 88).

**Phase 19+ question additions:** **q3b_hvac_type** (Phase 19b/c — dedicated HVAC type with 9 subtypes including "Not sure"), **q11b_lawn_type** (Phase 19j — natural / synthetic turf / mixed / not sure, drives 20 turf and natural-lawn templates), **q15b_household_contractors** (Phase 19m — HVAC service / plumber / electrician / roofer / septic / well / chimney / tree / handyman chips), **q22 (now `.generatorAdd`)** (Phase 19i — captures generator type, fuel, and optional provider in one screen), **q28b_pets** (Phase 19j — drives the synthetic-turf "Sanitize pet areas" template via `has_pets` flag).

**Q28 home manager sub-step (Build 87):** After the existing spouse / kids / caretaker sub-steps complete, `caretakersBody` transitions into `homeManagerStepBody` instead of recording the answer immediately. The body shows either a prompt card ("Anyone else helping run your home?" with "Add home manager" / "Skip" buttons) or the inline `QuizHomeManagerInviteInlineForm`. Both the Skip path and the form's onComplete funnel through `finalizeQ28Caretakers(answerId:homeManagerEntry:)` which records the final Q28 answer with the optional `HomeManagerEntry` breadcrumb attached to `HouseQuizAnswer.homeManagerEntry`. Hydration on back-nav restores the entry; the summary card shows "A couple, 2 kids, home manager Maria". The form mirrors `QuizSpouseInviteInlineForm` but captures last name (required), defaults the personal message to "You'll help me keep everything running.", routes through `HouseholdInviteCoordinator.addPersonToHousehold` with `memberType: "home_manager"`, and tags analytics with `InviteSource.quizHomeManagerStep`. See "Home Manager Role" section under Family Members & Profiles for the full enforcement story.

**Dynamic skip closures:** Questions can declare a `dynamicSkip: ((HouseQuizState) -> Bool)?` closure that the view model checks at advance time. Used to hide Q11b when the user has no lawn (Q11 = no_lawn / garden / **hardscape** as of Build 84), hide Q14 (irrigation) when Q11 = no_lawn, and skip Q19 (heating fuel provider) entirely when Q3 = electric / geothermal / not_sure. Conditional chip visibility (e.g. septic pumper chip in Q15b only appears when Q7 = septic) is rendered inline rather than via dynamicSkip.

**Q11 hardscape branch (Build 84):** A 5th Q11 lawn answer "Mostly hardscape (patio, gravel, pavers)" creates an "Outdoor Hardscape" `home_systems` row (category Landscaping, subtype `hardscape`) and 4 personal/DIY maintenance tasks via `HouseQuizAnswerMapper.createHardscapeMaintenanceTasks`: pressure-wash patio (annual, spring), top-up joint sand (every 2 years, summer), treat weeds between pavers (quarterly, spring), check hardscape drainage and grading (annual, fall). Tasks use stable `templateId` keys (`landscaping:hardscape_*`) and DIY effort labels in `notes`. Q11b is auto-skipped on hardscape via dynamicSkip.

**Q25 garage + Q25b EV charger split (Build 86):** Q25 used to ask "Garage type? EV charger?" with the EV charger as one of six mutually-exclusive answers, AND used arbitrary "Attached 1-car" / "Attached 2-car" granularity that broke down for users with 5+ car garages. Build 86 collapses Q25 to five icon-bearing options (`attached`, `semi_attached`, `detached`, `carport`, `none`) and splits the EV charger into a new dedicated `q25b_ev_charger` yes/no question with a `dynamicSkip` closure that hides Q25b entirely when Q25 = `none`. Legacy build 85 answer ids (`attached_1`, `attached_2`, `ev_l2`) normalize to `attached` at both write time (`HouseQuizAnswerMapper.q25_garage_ev`) and read time (`HouseQuizView.normalizeLegacyAnswerId`). Q25b creates an "EV Charger (L2)" `home_system` row only on the explicit "yes" answer; the legacy `ev_l2` branch in Q25's mapper still creates the EV charger system for users who answered the question on build 85.

**Q22 generator same-supplier confirmation (Build 86):** Build 85's `needsGeneratorProviderFollowUp` helper silently skipped the picker when the generator's fuel matched Q3's heating fuel — Tom flagged that propane heat + propane generator was still rendering an empty picker because the silent skip wasn't visible enough. Build 86 replaces the skip with an explicit "We already know [Provider] supplies your [fuel]. Is your generator on the same account?" confirmation card (`HouseQuizView.providerConfirmationCard`) with two buttons: Yes-same-supplier (captures Q19's provider verbatim) and Different supplier (reveals the picker). New states `q22MatchedHeatingProvider` and `q22UseSameProvider` drive the three-branch render in `generatorAddBody`. The mapper drops the `q3Fuel != fuel` guard and relies on `createUtilityAccount`'s name-based dedup to make Yes-same a no-op against the existing Q19 utility_account row.

**Q10 appliances reframe (Build 86):** Q10's title is now "Which major appliances do you have?" with a "Select all" / "Deselect all" pill at the top of `multiSelectBody`. The pill is gated on a new opt-in `supportsSelectAll: Bool = false` flag on `HouseQuizQuestion` so other multi-select questions (Q20 fuels, Q15b contractors, etc.) keep the chip-by-chip flow. The pill skips "Other" (custom input) and "None of these" (mutual-exclusion) options. The persisted attribute name `appliances_under_5_years` is unchanged for backward compat.

**Family member chooser (Build 86):** Adding a family member from the dashboard HouseholdStrip "+" button or the Settings → Family Members "+" toolbar now goes through `AddFamilyMemberChooserSheet` first, which presents two cards: "Add a family member" and "We're expecting". The chosen mode flows into `FamilyMemberFormView(initialMode:)` via a new `AddFamilyMemberMode` enum (`.regular` / `.expecting`). The PLANNING toggle that used to live at the top of the form is gone; expecting mode shows due date + helper context as its own EXPECTING section. Editing an existing member skips the chooser and opens the form directly with the persisted `isExpecting` flag driving layout.

**Q36 Vendor Preference Tier (Build 88):** Converted from `.slider` (Build 87) to `.singleChoice` with 3 options: "I handle it" (diy), "Mix of both" (mixed), "Hire it out" (hire_out). The answer mapper persists `vendor_preference_tier` as a string and triggers `MaintenanceTaskReconciler.reconcileAllForHousehold`. Settings → Maintenance Preferences shows the same 3-chip picker. The old `VendorPreferenceSlider` component and `recordSliderAnswer` method are deleted. See "Vendor Preference Tiers" section under Maintenance.

**Q12 Pool vs Hot Tub split (Build 87):** Build 86 collapsed every Q12 answer into a single "Pool/Spa" parent system with three pool-specific children (Pool Pump / Filter / Heater) and an empty-default chemistry leak in `activeSubtypes`. Build 87 splits the model: `hot_tub` creates a single "Hot Tub" system with subtype `"hot_tub"` and no children; `in_ground` / `above_ground` create a "Pool" system with the matching pool-type subtype + 3 children; `both` creates BOTH systems separately. The Pool ensureHomeSystem call uses a new `excludeSubtype: "hot_tub"` parameter so the Pool lookup never collapses into the Hot Tub row in mixed households. Q12b composes chemistry into the existing pool subtype (e.g. `"pool_inground"` → `"pool_inground_chlorine"`) so both pool-type and chemistry survive in one subtype field. `MaintenanceTemplates.activeSubtypes` for `"pool/spa"` parses the composite via substring matching to emit the umbrella `"pool"` token plus pool-type and chemistry facets, and short-circuits to `"hot_tub"`-only for hot-tub subtypes. See "Pool vs Hot Tub" section under Property for the full template gating story.

**Q17 forwarding-email milestone (Build 84):** The milestone interstitial that fires after `currentIndex == 17` (q15b_household_contractors) is now a variant card that reveals the user's `*@alfred.havenhome.dev` forwarding inbox address. `HouseQuizViewModel.cachedHouseholdEmail` is loaded via `loadForwardingEmailIfNeeded()` from the view's `.task` block on first appear (uses existing `DatabaseService.fetchHouseholdEmailAddress()`). `HouseQuizView.milestoneCard` is `@ViewBuilder` and switches between `forwardingEmailMilestoneCard(email:)` and `genericMilestoneCard`. The variant card includes an inline copy-to-clipboard button (mirrors `ProjectEmailView.swift:159-175`) with a 2-second "Copied" badge flash. Other milestones (Q5, Q10, Q22, Q27, Q33) keep the generic variant.

**Resume + back-navigation hydration (Build 85):** Every quiz question kind now has hydration coverage in `HouseQuizView.hydrateEntryState`. `.multiSelect` and `.currency` were already wired; Build 85 adds `.caretakers` (reads `prior.answerId` / `kids` / `expectingEntries`, sets `householdShowCaretakerStep = true` so the user lands on the final sub-step), `.generatorAdd` (reads `prior.answerId` / `generatorFuelType` / `generatorProviderId`), and `.householdContractors` (reads `prior.selectedIds` plus reverse-parses `customEntries` via the now-internal `HouseQuizAnswerMapper.parseContractorChipEntry` helper). Q28 also gets an "ALREADY ANSWERED" summary card at the top of `caretakersBody` with an Edit button that resets local state to walk the flow fresh. `.providerSearch` questions (Q16/Q17/Q19/Q26/Q27) get a pinned "CURRENTLY SELECTED" card on `UtilityProviderSearchPicker` via the new `preSelectedProviderId` + `onDeselect` props; tap-to-clear fires `viewModel.clearAnswer(for:)`.

**Saved-for-later review flow (Build 85):** `HouseQuizViewModel` exposes `showSavedReviewScreen: Bool`, `hasUnresolvedSavedQuestions: Bool`, `unresolvedSavedQuestions: [HouseQuizQuestion]`, `firstUnresolvedFreshIndex: Int?`, plus `jumpToSavedQuestion(_:)` (fires `.quizSavedResumed`) and `skipAllSavedAndFinish()` (fires `.quizSavedSkippedAll`). Completion gating in `persistStateThrowing` requires `!hasUnresolvedSaved` so `state.completedAt` never flips while saved items remain. `advance()` auto-routes to `savedReviewView` when `currentQuestion == nil && hasUnresolvedSavedQuestions`. The view body has a routing branch + dead-end fallback. A persistent trailing toolbar pill (navy bookmark + count) opens the review list whenever there are unresolved saved questions, and swaps to a "Done" pill while on the review screen. The review list itself has tappable cards per saved question, a "Skip these and finish the quiz" footer (with confirmation dialog), and an optional "Keep going forward instead" escape when fresh questions remain.

**Quiz progress label (Build 85):** `HouseQuizViewModel.progressLabel` clamps `position = min(max(1, currentIndex + 1), total)` so the label can never read "Question 35 of 34" on completion. The toolbar `HouseQuizProgressBar` is also wrapped in `if !viewModel.isComplete && !viewModel.showSavedReviewScreen` so it disappears entirely on those screens.

**Provider picker (`UtilityProviderSearchPicker`):** Region-aware ranking (Phase 19h) — sorts by relevance score (3 = town match, 2 = state or US national, 0 = no match) before applying the visible-list cap. Uses `viewModel.property.city` and `viewModel.property.state` to rank. Lazy logo enrichment via Brandfetch. Custom-add path creates a new `utility_providers` row with logo lookup. Phase 18b's `dynamicProviderTypes` closure narrows the picker for Q19 based on Q3's heating fuel.

**Post-quiz vendor delegation sheet (Phase 19l):** Fires once at quiz completion when any contractor in the household has matching `either`-tagged tasks. Single consolidated sheet listing every vendor with collapsible DisclosureGroups showing affected task titles and frequencies. Default-all-selected with a master Continue CTA. Skip-for-now stamps `skipped_delegation_at` on property attributes. Re-fires from the dashboard's `.contractorAdded` observer when a new contractor is added later.

Key files: `HouseQuizQuestionLibrary.swift` (questions), `HouseQuizModels.swift` (`HouseQuizQuestion`, `HouseQuizAnswer`, `HouseQuizQuestionKind`), `HouseQuizViewModel.swift` (state machine + persistence), `HouseQuizView.swift` (rendering per kind), `HouseQuizAnswerMapper.swift` (DB side effects per question), `HouseQuizFeedbackLibrary.swift` (per-answer insight cards), `Components/UtilityProviderSearchPicker.swift`, `Components/PostQuizVendorDelegationSheet.swift`, `Components/QuizContractorMultiSelect.swift`.

## Family Members & Profiles

**FamilyMemberProfileView** opens from HouseholdStrip. Sections: hero, documents (junction table), vehicles (covered drivers only), assigned tasks (via `assignedToUserId`), events (tagged via `taggedMemberIds`), estate readiness.

**User resolution:** `resolveUserId()` matches by linkedUserId, email, full name, first name, or "Primary Client" relationship. Searches ALL household users.

**Avatar photos:** `AvatarPhotoService` (upload/delete to Supabase Storage `avatars` bucket, 400px resize, 1-year signed URLs). `FamilyAvatarView` shows `AsyncImage` with SF Symbol fallback. `PhotosPicker` in `FamilyMemberFormView`.

**Age sorting:** `[FamilyMemberRow].sortedByAge()` extension (oldest first, no-DOB at end alphabetically). Used in HouseholdStrip, Life tab avatar strip, "By Family Member" filter.

**Staff & Home Managers (Build 87):** New `family_members.member_type` column (migration `20260437_add_family_member_type.sql`) discriminates between real family members and paid household staff. Values: `'family'` (default), `'home_manager'`, `'staff'`. Backfilled to `'family'` for every existing row so build 86 installs round-trip cleanly. `DatabaseService.fetchFamilyMembers` filters server-side by `member_type IN ('family', NULL)` so paid staff never leak into the family card list. New `DatabaseService.fetchHouseholdStaff` returns the inverse set. Dashboard renders a separate `HouseholdStaffStrip` (`Haven/Features/Dashboard/Components/HouseholdStaffStrip.swift`) below the existing `HouseholdStrip`, gated on `viewModel.householdStaff.isEmpty == false`. The strip's "+" button routes to Settings → Household Staff rather than the family chooser, keeping the entry points clearly separated. Settings adds two new entries: `HouseholdStaffView` (list scoped to staff) and `AddHouseholdStaffSheet` (form with first/last name, optional contact, "Send Invite" toggle, avatar upload via `AvatarPhotoService`). The add sheet routes through `HouseholdInviteCoordinator.addPersonToHousehold` with the new `memberType: "home_manager"` parameter on `AddPersonRequest`. `FamilyMemberProfileView` is generic enough to render staff rows without changes — tapping a staff avatar opens the same profile sheet as a family member. The chooser sheet from build 86 (`AddFamilyMemberChooserSheet`) intentionally stays family-only.

## Home Manager Role (Build 87)

Home managers (`family_members.member_type = 'home_manager'`) are linked household users with full editing permissions across tasks, systems, contractors, projects, and vehicles, EXCEPT for restricted document access and destructive operations. The role exists so HNW families can give their property manager / executive assistant their own Haven login that lets them manage the home but never exposes estate, financial, or medical documents the homeowner hasn't explicitly shared.

### Capabilities

**CAN:**
- View all household tasks (personal, vendor-managed, custom) on Maintenance, Dashboard, and any task surface
- Receive task assignments via `assigned_to_user_id` from any other linked household user
- Create / edit / complete tasks (including custom tasks via `AddMaintenanceTaskSheet`)
- Manage home systems (add, edit, mark serviced, attach manuals)
- Manage contractors in the household directory
- Manage projects: quotes, line items, contacts, files, active quote selection
- Upload documents — visibility defaults are stamped at insert time per `DocumentAccessDefaults.swift`
- View documents where `documents.visible_to_home_managers = true`
- Use Alfred chat (scoped to the docs they can see; the chat function builds context server-side using their JWT, so RLS naturally filters their visible documents)
- See Family, Property, Life, and Alfred tabs identically to the homeowner

**CANNOT:**
- See documents where `visible_to_home_managers = false` unless the homeowner explicitly flips the Access pill
- Delete properties, family members, the household, or the home manager role itself (V1 enforces this in the iOS view models — no DB-level enforcement)
- Change household ownership
- Invite other linked users
- Access estate, legal, financial, or medical document categories unless specifically shared

### Document access enforcement

- **Schema:** `documents.visible_to_home_managers boolean not null default true` added by migration `20260438_document_home_manager_access.sql`. Backfilled with category-driven defaults; the corrective backfill in `20260440_document_home_manager_access_backfill.sql` uses lowercased comparison so Title Case categories like "Power of Attorney" actually match.
- **RLS:** Migration `20260439_document_home_manager_rls.sql` replaces the `"Users can view household documents"` SELECT policy with `"household_documents_select"`. The new policy keeps household scoping but ALSO requires `visible_to_home_managers = true` when the caller is a linked user with `family_members.member_type IN ('home_manager', 'staff')`. INSERT, UPDATE, and DELETE policies are unchanged — home managers can still upload, edit, and delete documents. Only SELECT is restricted.
- **Category defaults source of truth:** `Haven/Features/Documents/DocumentAccessDefaults.swift`. Stores both Title Case (matching `DocumentCategory` raw values like "Will", "Power of Attorney", "Brokerage Account") and legacy snake_case keys, all lowercased. The lookup function lowercases input and checks the set. Mirror constants live at the top of `receive-email/index.ts`, `process-inbox-item/index.ts`, and `analyze-document/index.ts`. Keep all four lists in sync when categories are added or removed.
- **iOS insert paths:** All four `DocumentInsert(...)` callsites (`DocumentUploadManager`, `DocumentUploadViewModel` x2, `ChatViewModel`) stamp `visibleToHomeManagers` from the placeholder category at insert time. The real category gets rewritten by `analyze-document` afterward, which is the place that ALSO rewrites `visible_to_home_managers` based on the AI-suggested category — without that, manual uploads with placeholder "Unknown" / "Will" categories would always default to visible.
- **Per-document override UI:** `DocumentDetailView.metadataCard` adds an "Access" row, rendered ONLY when `viewModel.householdHomeManagers.isEmpty == false` (zero UI noise for family-only households). Tapping opens `DocumentAccessSheet` — a new ~210 line sheet that shows family members with always-visible checkmarks and home managers with single toggles. The whole sheet is wrapped in a `HomeManagerAccessSheetModifier` so it doesn't push `DocumentDetailView.body` past SwiftUI's type-check complexity limit. `DatabaseService.updateDocumentHomeManagerVisibility(documentId:visible:)` is the single update path.

### Task assignment labels

- `MaintenanceViewModel.familyMembers` is the merged family + staff list (loaded via `fetchFamilyMembers` + `fetchHouseholdStaff` then concatenated). The previous `fetchFamilyMembers` query filters out staff server-side, so the concat is necessary so the existing `linkedUserId` lookups in `assignedUserName` and `assignedUserAvatarColor` can resolve home manager rows.
- `MaintenanceViewModel.assignedUserName(for:)` looks up the matching family_member by `linkedUserId` and appends " · Home Manager" or " · Staff" when `member_type` matches. Plain family members render without a suffix to keep the assignee pill compact.
- `MaintenanceTaskDetailSheet.assignToSection` loads `householdFamilyMembersForRoles` alongside `householdUsers` and renders the role suffix as a separate Text in `textTertiary` next to the bold first name.
- `AddMaintenanceTaskSheet` accepts a `householdFamilyMembers: [FamilyMemberRow]` prop and uses the new `personLabel(for:)` helper to build the picker option string ("Maria · Home Manager"). Wired through from `MaintenanceScheduleView` via `viewModel.familyMembers`.

### Quiz onboarding

Q28's caretakers flow has a fourth sub-step: after the spouse / kids / caretaker sub-steps complete, `homeManagerStepBody` renders either a prompt card ("Anyone else helping run your home?") with "Add home manager" / "Skip" buttons or the `QuizHomeManagerInviteInlineForm`. The form mirrors `QuizSpouseInviteInlineForm` but captures last name (required), passes `memberType: "home_manager"` to `HouseholdInviteCoordinator.addPersonToHousehold`, and uses the new `InviteSource.quizHomeManagerStep` for analytics. On completion, both the Skip and Submit paths funnel through `finalizeQ28Caretakers(answerId:homeManagerEntry:)` which stores the `HomeManagerEntry` breadcrumb on `HouseQuizAnswer.homeManagerEntry` for back-nav hydration and records the final Q28 answer.

### Settings entry

Settings → Household Staff → AddHouseholdStaffSheet remains the manual entry point (independent of the quiz). Both quiz and settings paths converge on the same `HouseholdInviteCoordinator.addPersonToHousehold` call with `memberType: "home_manager"`. Family-only households continue to use `AddFamilyMemberChooserSheet` which is intentionally never extended with a third "Home Manager" chip — keeping the entry points clearly separated.

## Email Ingestion Pipeline

**Flow:** User forwards email to `[anything]@alfred.havenhome.dev` > SendGrid Inbound Parse > `receive-email` Edge Function > Claude classification > type-specific handling > inbox item created > user reviews in `InboxItemDetailView`.

**Classification types (9):** `contractor_quote`, `estate_document`, `home_document`, `vehicle_document`, `bill_invoice`, `insurance_claim`, `vendor_contact`, `family`, `other`. Vehicle invoices are `bill_invoice` with `vehicleContext: true`.

**User confirmation:** ALL documents get `needs_action: true` with `action_type: "confirm_document_category"`. High-confidence docs show "Looks Good" with subtle "Change Category"; low-confidence show picker-first. Insurance claims prompt "Create Claim Project" / "Save as Document" (no auto-project-creation). Quotes prompt "New Project" / "Add to Project" / "Just Save Document".

**Vehicle routing:** `vehicle_document` type for titles/registrations. `vehicleContext` flag on bill_invoice for service invoices. Vehicle picker in `InboxItemCard` for vehicle-related items. `process_vehicle_document` action in `process-inbox-item`.

**Unsupported file types:** .docx/.xlsx/.csv/.zip/.heic stored but analysis skipped. Metadata flag `analysis_skipped: true` with reason. iOS shows info banner.

**Category picker:** `DocumentCategoryPicker` (searchable sheet with 88 categories in 15 groups). Used in both `InboxItemCard` and `InboxItemDetailView`. Shared data in `DocumentCategoryGroups.swift`.

**Processing banner:** `ProcessingBanner` in `MainTabView` shows upload progress. Tappable when complete -- navigates to inbox item via `.navigateToInboxItem` notification.

**Key files:** `receive-email/index.ts`, `process-inbox-item/index.ts`, `analyze-document/index.ts`, `InboxView.swift`, `InboxItemCard.swift`, `InboxItemDetailView.swift`, `DocumentCategoryPicker.swift`, `DocumentCategoryGroups.swift`.

## Duplicate Document Detection

**Hash:** SHA-256 of raw file bytes. Stored in `documents.content_hash`. Computed at document creation time in all paths.

**Manual upload (DocumentUploadManager):** Hash computed at Step 0 before file upload. `DuplicateDetectionService.checkForDuplicate()` queries DB. If match found, upload STOPS and `DuplicateResolutionSheet` presents 3 choices: "Replace Existing" (deletes old storage file + soft-deletes record, uploads new), "Save Both Copies" (uploads new alongside existing), "Delete This Document" (discards new upload). Sheet wired via `MainTabView`.

**Manual upload (DocumentUploadViewModel):** Same hash + check. Upload BLOCKED on duplicate. Alert with same 3 buttons. `replaceDuplicate()` cleans up old storage file via `HavenSupabase.storage.from("documents").remove()`.

**Email pipeline (receive-email):** `computeContentHash()` computes SHA-256 from attachment base64. `checkDocumentDuplicate()` queries `documents.content_hash` before insert. All 3 document insert paths (estate/home, vehicle, bill) set `content_hash` and check for duplicates. If duplicate found, document is still created but inbox item gets `action_type: "resolve_duplicate"`.

**Email resolution (process-inbox-item):** `resolve_duplicate` action with sub-actions via `document_category` param: `"replace"` (delete existing + storage), `"save_both"` (keep both), `"delete"` (delete new + storage).

**iOS UI:** `InboxItemCard` and `InboxItemDetailView` both handle `resolve_duplicate` action type with 3 equal-size HavenButtons.

**Cross-path dedup:** Works because all paths use the same SHA-256 hash of raw file bytes. Spouse 1 uploads manually, Spouse 2 forwards same PDF via email -- duplicate detected.

**Key files:** `DuplicateDetectionService.swift`, `DocumentUploadManager.swift`, `DocumentUploadViewModel.swift`, `DuplicateResolutionSheet.swift`, `receive-email/index.ts`, `process-inbox-item/index.ts`.

## Utility Bill Detection

`receive-email` fuzzy-matches `billVendor` against `utility_providers` catalog. For matches, embeds provider info in inbox metadata with `add_utility_provider` action type. `InboxItemDetailView` shows branded prompt card. `AddUtilitySheet` accepts prefill parameters (name, slug, type, account number, cost, phone, website).

## Historical Projects & Document-Project Linking

**`property_projects.entry_type`:** `"planned"` (default) or `"historical"`. Historical projects skip AI research, line items, planning scaffolding. Created via `LogHistoricalProjectView` (name, category grid, approximate/exact completion date, total spent, notes). Saved with `status: "completed"`, `entryType: "historical"`.

**`documents.project_id`:** Nullable FK to `property_projects`. Links any document to a specific project. Methods: `linkDocumentToProject()`, `unlinkDocumentFromProject()`, `fetchDocuments(projectId:)` in DatabaseService.

**ProjectDetailView historical variant:** Shows `historicalHeader` (completed badge, date, total spent) + `projectDocumentsSection` (linked docs with add/link/unlink) + notes. Hides ROI, quotes, line items, AI research.

**Document upload with project context:** `DocumentUploadView` accepts `preselectedProjectId`. Flows through `DocumentUploadManager.enqueueFiles(projectId:)`. Document auto-linked after creation.

**Inbox "Link to Project":** `InboxItemDetailView` shows "Link to Project" button for saved documents. Project picker sheet.

**PropertyProjectsView:** "Add Project" button opens confirmation dialog with "Plan New Project" / "Log Completed Project". Historical project cards show spend + year instead of status badge.

**Key files:** `LogHistoricalProjectView.swift`, `LinkDocumentToProjectSheet.swift`, `ProjectDetailView.swift`, `PropertyProjectsView.swift`.

## Auth Flow

`AuthService.hasResolvedInitialSession` flag ensures splash screen stays until `.initialSession` event is fully processed. `AddressHookView` is the default unauthenticated landing screen. `LoginView` reached only by user action ("I already have an account" or "Create Free Account to Save").

## Security Features

AES-256-GCM document encryption, biometric auth, vault lock, screenshot prevention, jailbreak detection, secure logging, server-side document viewing (zero-access model), cascading account deletion. Certificate pinning deferred (operational risk at solo-dev stage).

## Key Patterns

**MVVM:** View -> ViewModel (@MainActor, ObservableObject) -> DatabaseService -> Supabase. ViewModels own state.
**DB Models:** Row/Insert/Update types in `DatabaseModels.swift`. CodingKeys for snake_case. Resilient `try?` for optional fields.
**Analytics:** `Analytics.track(.eventName, ["key": value])`
**Haptics:** `Haptics.selection()`, `.light()`, `.medium()`, `.success()`, `.error()`
**Edge Functions:** Validate inputs first (400), wrap Claude calls in try/catch, log with `[function-name]`, return JSON only.

## Strategic Context

**Five moats:** (1) Only app combining estate intelligence + home management, (2) AI that creates intelligence not convenience, (3) Scenario Studio (no equivalent), (4) Free in a paid market, (5) Premium design for premium audience.

**Competitors:** Homer (freemium, Apple-featured), Trustworthy ($120-240/yr), HomeZada ($59-149/yr), Nines Living (enterprise/$1K+), Everplans ($99/yr), Centriq, Dib.

**Key decisions:** No Android/hardware (validate with iPad first). True E2E encryption ruled out (incompatible with server-side AI). SOC 2 deferred. Security messaging must be precise -- no "bank-level" or "end-to-end" overclaims.

## GTM Status

TestFlight active (~10 couples, ~7 active). Estate attorney referral kit in progress. havenhome.dev live with security page. SendGrid email pipeline configured. Push notifications wired end-to-end.

## Progress Tracking

See `PROGRESS.md` for session-by-session development history. After each session:
1. Update the relevant sections of THIS file with any new architecture (tables, Edge Functions, files, patterns)
2. Append a summary of what you did to `PROGRESS.md`
3. If `PROGRESS.md` has more than 15 detailed entries, compress all entries older than the most recent 5 into single-line summaries at the top of the file
