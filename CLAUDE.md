# Haven -- Context for Claude Code

## Who You're Working With

Tom Burke. Solo founder/developer of Haven. Full-time AE at Salesforce, so bandwidth is the scarcest resource. Strong design eye, catches subtle UI and writing issues (e.g., em dashes reading as AI-generated). Reviews running app screenshots and gives specific, detailed feedback. Expects Claude to read actual file state before making changes -- never guess component names, design tokens, model strings, or architecture patterns.

## What Haven Is

A native iOS app (SwiftUI, iOS 17+) combining estate document intelligence with home property management. Backed by Supabase and Claude AI (via Edge Functions). No competitor offers this combination. Target audience: high-net-worth families ($500K-$5M net worth).

**The core insight:** Haven's AI creates intelligence, not just convenience. Documents get analyzed, gaps get identified, scenarios get simulated. The real competition is insecure alternatives (Google Drive, email attachments, filing cabinets) -- not enterprise vault solutions.

**Status:** TestFlight with public link (`https://testflight.apple.com/join/sw4xWsTA`). App Store Connect ID: `6757167606`. Version 1.0.2, build 74.

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

households, users, family_members (avatar_url, school), properties, home_systems (parent_system_id), maintenance_tasks (vehicle_id, property_id nullable, assigned_to_user_id), documents (vehicle_id, project_id), document_content, document_parties, document_family_members, warranties, contractors, service_records, service_contracts, chat_messages, concierge_messages, scenario_history, completion_scores, access_logs, dismissed_categories, trusted_contacts (avatar_url), trusted_contact_documents, household_invitations, household_email_addresses, inbox_items, inbox_attachments, property_projects (active_quote_id, entry_type), project_quotes, project_line_items, project_files, project_contacts, project_visualizations, family_events, synced_calendars, device_tokens, equipment_catalog, equipment_scores, utility_accounts, utility_providers, analytics_events, property_lookups_cache, allowed_senders, vehicles (covered_driver_ids), vehicle_service_records, vehicle_recalls

**RLS is on everything.** All tables scoped by `household_id`. Service role key is only used in Edge Functions.

**Sub-system hierarchy:** `home_systems.parent_system_id` (nullable FK to self, ON DELETE CASCADE). Parent/child relationships (e.g., Well System -> Acid Neutralizer, UV Filter). UI shows top-level systems in lists, children inside parent's detail as "Components".

**Unified task system:** `maintenance_tasks` table stores both home and vehicle tasks. `vehicle_id` column (nullable) links vehicle tasks; `property_id` is nullable. When vehicles are added via VIN, AI-generated maintenance intervals auto-create task rows.

## Edge Functions (supabase/functions/)

See `supabase/functions/CLAUDE.md` for detailed patterns and full inventory. Key groups:

**Core AI:** `analyze-document`, `chat`, `gap-analysis`, `simulate-scenario`, `proactive-scan`
**Invoice:** `process-invoice` (home + vehicle invoice intelligence)
**Property/Equipment:** `search-equipment`, `identify-equipment`, `lookup-manual`, `score-equipment`, `research-project`, `project-feasibility`, `property-lookup`, `visualize-room`
**Quotes:** `analyze-quote`, `draft-negotiation-email`
**Email Pipeline:** `receive-email` (with utility bill detection), `process-inbox-item`
**Vehicle:** `vehicle-lookup` (VIN decode + recalls + maintenance schedule), `check-vehicle-recalls`
**Brand:** `brand-logo` (Brandfetch wrapper for all logo fetching)
**Household:** `merge-households`, `delete-account`, `send-push-notification`
**Vendor/Document:** `extract-vendor`, `view-document`
**Catalog:** `enrich-catalog`, `expand-catalog`, `scrape-manuals`, `download-manuals`, `upload-manual`, `send-catalog-request`, `score-property`

All use `claude-sonnet-4-6`. All return JSON. All use CORS headers. All deployed with `--no-verify-jwt`.

## iOS Networking Pattern

All Edge Function calls go through `HavenSupabase.callEdgeFunction()` in `SupabaseClient.swift`: refreshes auth session, builds URL, attaches apikey + Authorization headers, encodes JSON body, returns raw Data. Typed convenience methods exist for each function.

## Dashboard Architecture

**Scroll order:** screenTitle("Haven") > greeting > merge banner > **HouseholdStrip** (horizontal avatar strip, age-sorted, "+" add, "Manage" link) > expecting members > Getting Started / Recommendations > inbox section > email forwarding callout > enrichment cards > **home maintenance hero card** ("YOUR HOME", tasks this month, overdue pill only when > 0) > **UnifiedAttentionList** (merged overdue tasks, vehicle alerts, expiring docs/warranties, upcoming maintenance; shows 3 with "See all") > Quick Actions (Maintenance left, Upload right) > **compact estate scorecard** (single-row navy card with progress bar) > **compact scenario card** (single-row, requires 3+ docs) > security badge > incomplete address banner (amber, for properties missing street/city)

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

**UnifiedTaskCard** (`Haven/Shared/Components/UnifiedTaskCard.swift`): Single reusable task card across all views. Left: category icon (32x32 tinted square). Center: title (2-line), location tag (house/car icon + name), system, assignee pill (avatar color), vendor pill. Right: priority capsule (color-coded), due date.

**Equipment task migration:** `MaintenanceTemplate.equipmentKeywords` field. When a child system is added, matching tasks migrate from parent to child via `migrateMatchingTasks()`. Invoice-discovered systems get tasks only via migration or AI follow-ups (not generic templates). Retroactive migration runs once on auth (V1, UserDefaults gated).

**Task deduplication:** `DatabaseService.createMaintenanceTask()` checks for existing tasks with same title (case-insensitive), household, property/vehicle, and system before inserting.

**Active quote system:** `active_quote_id` on projects. First quote auto-activates. `quoteTotal` writes to `estimatedBudget`. Long-press to change active quote.

**Seasonal tasks:** `SeasonalTaskGrouper` groups individual tasks into 4-5 homeowner-friendly categories (Landscaping, Exterior, Safety, HVAC, Water). Collapsible group cards with `CircularProgressView` progress rings.

## Family Members & Profiles

**FamilyMemberProfileView** opens from HouseholdStrip. Sections: hero, documents (junction table), vehicles (covered drivers only), assigned tasks (via `assignedToUserId`), events (tagged via `taggedMemberIds`), estate readiness.

**User resolution:** `resolveUserId()` matches by linkedUserId, email, full name, first name, or "Primary Client" relationship. Searches ALL household users.

**Avatar photos:** `AvatarPhotoService` (upload/delete to Supabase Storage `avatars` bucket, 400px resize, 1-year signed URLs). `FamilyAvatarView` shows `AsyncImage` with SF Symbol fallback. `PhotosPicker` in `FamilyMemberFormView`.

**Age sorting:** `[FamilyMemberRow].sortedByAge()` extension (oldest first, no-DOB at end alphabetically). Used in HouseholdStrip, Life tab avatar strip, "By Family Member" filter.

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
