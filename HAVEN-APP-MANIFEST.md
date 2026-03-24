# Haven — App Manifest (Last Updated: March 24, 2026)

> **Purpose:** This file is the single source of truth for what Haven is, what's built, and how the codebase is organized. Upload this to the Haven Claude Project as a reference file. Update it whenever significant changes are made.

---

## Identity

- **App Name:** Haven
- **Bundle ID:** `com.havenhome.app`
- **App Store Connect ID:** `6757167606`
- **Team ID:** `RW9CWCAWGQ`
- **Platform:** iOS only (SwiftUI, iOS 17+)
- **Backend:** Supabase (project: `jsucwnkntdrxhysojgri`)
- **AI:** Claude API via Supabase Edge Functions (API key server-side only, never in client)
- **Payments:** Stripe (test mode, publishable key in client)
- **Status:** TestFlight (public link: `https://testflight.apple.com/join/sw4xWsTA`)
- **Developer:** Tom Burke (solo developer, also works as Account Executive at Salesforce)

---

## Brand & Design

- **Palette:** Cream (`#F2EEE5`) background, Navy (`#1B2A4A`) primary, sage/forest green maintenance accents
- **Typography:** Georgia serif for headings, system font for body
- **Design language:** Spacious card layouts, haptic feedback on actions, skeleton loading states (not spinners), premium/private-bank aesthetic
- **Target audience:** High-net-worth families ($500K–$5M net worth) who manage their own estates and homes
- **AI personality:** "Alfred" — warm, professional, butler-like. Discreet, knowledgeable, never uses jargon when plain language works.

---

## Project Structure

```
/Users/tomburke/Projects/Housing-Manager/
├── Haven/                          # iOS app (SwiftUI)
│   ├── App/                        # App entry, MainTabView, AppState, ContentView
│   ├── Config/                     # AppConfig.swift, entitlements, Info.plist
│   ├── Core/
│   │   ├── AI/                     # DocumentAnalysisService
│   │   ├── Auth/                   # AuthService, AuthViewModel, SessionManager, AppleSignInCoordinator
│   │   │   └── Views/             # LoginView, SignUpView, BiometricAuthView, IntroExplainerView
│   │   │       └── Onboarding/    # OnboardingView, OnboardingViewModel, OnboardingSteps
│   │   ├── Networking/
│   │   ├── Security/
│   │   ├── Services/              # AnalyticsService, DocumentUploadManager, DuplicateDetectionService,
│   │   │                            GooglePlacesService, ScenarioRunnerService
│   │   └── Storage/
│   ├── Features/
│   │   ├── Chat/                  # Alfred AI chat
│   │   │   ├── Components/        # ChatBubble, ChatDocumentCard
│   │   │   ├── ViewModels/        # ChatViewModel
│   │   │   └── Views/             # ChatView
│   │   ├── Dashboard/             # Main dashboard
│   │   │   ├── Components/        # CompletionScorecard, QuickActions, OverdueMaintenanceCard,
│   │   │   │                        UpcomingExpirations, RecentActivityFeed, EnrichmentCardView,
│   │   │   │                        ApplianceSetupSheet, ServiceContractSheet
│   │   │   ├── DashboardView.swift
│   │   │   ├── DashboardViewModel.swift
│   │   │   ├── SmartRecommendations.swift
│   │   │   ├── EnrichmentCardEngine.swift
│   │   │   ├── EnrichmentActions.swift
│   │   │   ├── EstateReadinessDetailView.swift
│   │   │   └── MergeResolutionView.swift
│   │   ├── Documents/             # "Life" tab — estate document vault
│   │   │   ├── Components/        # DocumentCard, CategoryProgress, ExpirationBadge, GapAlert
│   │   │   ├── Models/            # Document, DocumentCategory, DocumentStatus, FamilyMember
│   │   │   ├── ViewModels/        # DocumentVaultViewModel, DocumentDetailViewModel, DocumentUploadViewModel
│   │   │   └── Views/             # DocumentVaultView, DocumentDetailView, DocumentUploadView,
│   │   │                            DocumentScannerView, GapAnalysisView, MissingDocumentsView,
│   │   │                            FamilyReferenceBinder, DuplicateDocumentsView, EditDocumentDetailsView,
│   │   │                            CategoryPickerSheet, DocumentCategoryView
│   │   ├── Notifications/         # NotificationService, NotificationScheduler, NotificationPreferences,
│   │   │                            NotificationSettingsView
│   │   ├── Property/              # Home/property management
│   │   │   ├── Components/        # PropertyCard, MaintenanceTaskRow, SystemStatusIndicator,
│   │   │   │                        WarrantyExpirationAlert
│   │   │   ├── Models/            # Property, HomeSystem, MaintenanceTask, Contractor, Warranty,
│   │   │   │                        ServiceRecord, ProjectTypes
│   │   │   ├── Services/          # DefaultSystemsService, MaintenanceTemplates, ProjectResearchService
│   │   │   ├── ViewModels/        # PropertyListViewModel, PropertyDetailViewModel, MaintenanceViewModel,
│   │   │   │                        ContractorViewModel, ProjectsViewModel
│   │   │   └── Views/             # PropertyListView, PropertyDetailView, AddPropertyView, EditPropertyView,
│   │   │                            AddSystemView, SystemDetailView, MaintenanceScheduleView,
│   │   │                            MaintenanceTaskDetailSheet, OverdueTasksDetailView, SeasonalTasksDetailView,
│   │   │                            ContractorDirectoryView, AddVendorSheet, ContractorPickerSheet,
│   │   │                            WebsiteImportView, ContactPickerView, VendorReviewForm,
│   │   │                            WarrantyTrackerView, AddWarrantySheet, ServiceHistoryView,
│   │   │                            PropertyDocumentsView, HomeSystemsSetupView,
│   │   │                            PropertyProjectsView, ProjectDetailView, NewProjectView,
│   │   │                            QuoteAnalysisView, EditLineItemView
│   │   ├── Scenarios/             # "What If?" Scenario Studio
│   │   │   ├── ScenarioStudioView.swift
│   │   │   ├── ScenarioStudioViewModel.swift
│   │   │   ├── ScenarioDefinitions.swift   # 40+ pre-built scenarios
│   │   │   ├── ScenarioInputView.swift
│   │   │   ├── ScenarioLoadingView.swift
│   │   │   ├── ScenarioResult.swift
│   │   │   ├── ScenarioResultView.swift
│   │   │   ├── ScenarioResultContainerView.swift
│   │   │   └── ScenarioDisclaimerView.swift
│   │   ├── Security/              # SecurityDashboardView, SecurityDashboardViewModel, SecurityExplainerView
│   │   └── Settings/              # SettingsView, ProfileView, SubscriptionView, SecuritySettingsView,
│   │                                FamilyMembersView, FamilyMemberFormView, HouseholdAccessView,
│   │                                InviteToHavenSheet, TrustedContactsView, TrustedContactFormView,
│   │                                TrustedContactDetailView, NewArrivalChecklist
│   ├── Resources/                 # Assets, fonts, etc.
│   └── Shared/
│       ├── Components/            # HavenCard, HavenButton, HavenTextField, EmptyStateView, ErrorView,
│       │                            LoadingView, ProcessingBanner, FamilyAvatarView, AlfredLogoView,
│       │                            AddressAutocompleteField
│       ├── Extensions/            # Color+Haven, Font+Haven, Date+Extensions, String+Extensions,
│       │                            View+Extensions, UIView+Extensions
│       ├── Theme/                 # HavenColors, HavenTheme, HavenTypography
│       └── Utilities/             # Constants, Haptics, Logger, Validators, FlexibleValue
├── supabase/
│   └── functions/                 # Supabase Edge Functions (Deno/TypeScript)
│       ├── analyze-document/      # AI document analysis on upload (Claude API)
│       ├── analyze-quote/         # Quote/estimate analysis
│       ├── chat/                  # Alfred AI chat (Claude API with household context)
│       ├── extract-vendor/        # Website URL crawler for vendor import
│       ├── gap-analysis/          # Estate document gap analysis (Claude API)
│       ├── merge-households/      # Atomic household merge across 15+ tables (service_role)
│       ├── research-project/      # Project research assistance
│       ├── simulate-scenario/     # Scenario Studio simulations (Claude API)
│       ├── view-document/         # Secure document file preview
│       ├── proactive-scan/        # Background/cron document scanning
│       └── test-ai/              # Dev/test only
├── STRATEGY.md                    # Competitive analysis & go-to-market strategy
└── Haven.xcodeproj/
```

---

## Tab Architecture (MainTabView.swift)

| Tab | Index | Label | Icon | Root View |
|-----|-------|-------|------|-----------|
| Dashboard | 0 | Dashboard | `house.fill` | `DashboardView` |
| Property | 1 | Home | `wrench.and.screwdriver.fill` | `PropertyListView` |
| Life | 2 | Life | `heart.fill` | `DocumentVaultView` |
| Alfred | 3 | Alfred | `person.crop.circle` | `ChatView` |

**Floating Action Button:** "What If?" / Scenario Studio sparkles button on every tab (except Alfred). Opens `ScenarioStudioView` as fullScreenCover. Shows "Scenarios" label on first appearance, then collapses to icon only after first use (`@AppStorage("hasUsedScenarioStudio")`).

**ProcessingBanner:** Visible across all tabs at top, shows progress during background multi-file document uploads.

**Navigation:** Custom tab bar with pop-to-root via `NavigationPath`. Tab taps reset navigation stack. Cross-tab deep linking via `Notification.Name.switchToTab`.

---

## Feature Inventory

### Dashboard
- Estate readiness scoring (percentage) with detail drill-down
- "Getting Started" checklist — collapses to show only next incomplete step
- "Requires Attention" section — tappable items deep-link to specific documents/flags
- Smart Recommendations engine (activates after Getting Started is complete)
- Enrichment cards (ApplianceSetupSheet, ServiceContractSheet)
- Overdue maintenance card (sage/forest green hero card)
- Quick actions (Upload Document, Add Property, etc.)
- Recent activity feed
- Upcoming expirations

### Life (Documents)
- Document vault organized by section groups (Estate Planning, Insurance, Financial Accounts, Entity Documents, etc.)
- Family member avatars at top with horizontal scroll — tap to scope documents by person
- Per-person readiness scores (mini ring/percentage)
- AI-powered document analysis on every upload via `analyze-document` Edge Function
- Gap analysis engine via `gap-analysis` Edge Function
- Document scanner (VisionKit), photo library, file picker upload
- Background multi-file upload with `DocumentUploadManager` singleton
- Duplicate detection service
- Family Reference Binder PDF export
- Document flags with severity levels and actionable next steps
- Category picker, edit details, expiration badges

### Property
- Multi-property management with color-coded maintenance schedules (8 muted earthy colors)
- 150+ maintenance task template library (HVAC, plumbing, roofing, appliances, etc.)
- Vendor/contractor directory with 3 import methods:
  1. Native iOS `CNContactPickerViewController` (phone contacts, no permission prompt)
  2. Website URL crawler via `extract-vendor` Edge Function
  3. Manual entry
- Warranty tracking with expiration timelines
- Service history logging
- Home systems setup with default systems and expandable "and X more" link
- System detail views with linked maintenance tasks
- Projects management with quote analysis
- Property documents view (linked from document vault)
- Seasonal tasks detail view
- Overdue tasks detail view
- Vendor review form

### Alfred (AI Chat)
- Full conversational AI via `chat` Edge Function
- System prompt includes household context: family members, properties, document inventory, active flags, maintenance status
- Context-aware: can be opened from a specific document or property with that context prepended
- Alfred personality: warm, professional, butler-like
- Guardrails: scoped to home/family/estate topics, deflects homework/coding/unrelated requests
- Two tabs: "Alfred" (AI) and "Concierge" (human support — messages stored in `concierge_messages` table)
- Chat document cards for sharing document context in chat

### Scenario Studio ("What If?")
- 40+ pre-built scenarios in `ScenarioDefinitions.swift`
- Freeform query input
- Uses real uploaded data: family members, properties, documents, financial accounts
- Simulations via `simulate-scenario` Edge Function (Claude API)
- Results displayed in formatted view with sections
- Scenario history persisted in `scenario_history` Supabase table
- Disclaimer view for legal/financial advice boundaries
- Loading view with progress states

### Settings & Profile
- Profile management
- Family members CRUD with avatar system (age/gender-based SF Symbols, color customization)
- Household access management
- Invite to Haven (household sharing)
- Merge resolution view (when existing user joins a household)
- Trusted contacts management
- Security settings
- Notification preferences
- Subscription management (Stripe integration)
- New arrival checklist

### Security
- Security dashboard with status overview
- AES-256 encryption at rest for documents
- Biometric authentication (Face ID / Touch ID)
- Keychain storage for tokens (never UserDefaults)
- Auto-lock after configurable timeout
- Row Level Security on every Supabase table
- Screenshot prevention on sensitive screens
- Security explainer view

### Auth & Onboarding
- Email/password authentication via Supabase Auth
- Sign in with Apple (`ASAuthorizationController` + `signInWithIdToken`)
- Pre-onboarding intro explainer (3 swipeable pages, shown once via `@AppStorage("hasSeenIntro")`)
- 5-step onboarding: household name → primary member → spouse → additional members → module intro
- Biometric auth prompt on return from background

### Notifications
- Push notifications for: document expirations (90/60/30/7 days), insurance renewals, warranty expirations, maintenance tasks due, overdue items
- Configurable preferences per category
- Real notification scheduling (not just UI toggles)

---

## Supabase Edge Functions

| Function | Trigger | What It Does |
|----------|---------|--------------|
| `analyze-document` | Every document upload | Sends document text/image to Claude → returns summary, flags, category, metadata, family member links |
| `chat` | Alfred chat messages | Builds system prompt with full household context → Claude API → returns response |
| `gap-analysis` | On-demand or after upload batch | Analyzes full document inventory → returns missing docs, inconsistencies, recommendations |
| `extract-vendor` | "Import from Website" in Add Vendor | Fetches URL HTML → Claude extracts structured vendor data |
| `simulate-scenario` | Scenario Studio | Builds scenario prompt with real household data → Claude API → returns formatted simulation |
| `view-document` | Document detail preview | Secure document file retrieval |
| `merge-households` | Household sharing invite accepted | Atomic migration of all data across 15+ tables using service_role |
| `analyze-quote` | Project quote analysis | Analyzes contractor quotes |
| `research-project` | Project research | Researches project details |
| `proactive-scan` | Background/cron | Scans for proactive alerts |

**Deployment:** All functions deployed with `--no-verify-jwt` flag. Supabase CLI must be linked with `supabase link --project-ref jsucwnkntdrxhysojgri` before deploying.

---

## Key Technical Details

- **Supabase Project URL:** `https://jsucwnkntdrxhysojgri.supabase.co`
- **Google Places API Key:** Configured in `AppConfig.swift` for address autocomplete
- **Stripe:** Test mode publishable key in client; no secret keys in iOS
- **Claude API Key:** Server-side only in Edge Functions. NEVER in iOS client.
- **Analytics:** `AnalyticsService.swift` with `Analytics.track()` calls throughout
- **Haptics:** `Haptics.swift` utility with `.light()`, `.medium()`, `.heavy()`, `.success()`, `.error()`
- **All phase prompts:** `~/Downloads/haven-rebuild-phases/phase-XX-*.md` (phases 20–37)

---

## Development Completed (Phases 20–37)

| Phase | What Was Done |
|-------|---------------|
| 20 | App icon (thin serif "H" on cream), home systems setup streamlined |
| 21 | UX audit — 25 fixes including onboarding reduction, Getting Started card, tab renames |
| 22 | Sign in with Apple, UX improvements |
| 23 | Background multi-file upload, chat clear bug fix, TestFlight readiness |
| 24 | Smart vendor import (3 methods), final polish |
| 25 | Pre-onboarding intro explainer, property color coding |
| 26 | Maintenance/estate tab improvements |
| 27 | Dashboard redesign |
| 28 | App icon fix |
| 29 | Navigation consistency polish |
| 30 | Alfred AI guardrails (scoped system prompt) |
| 31 | Tab navigation pop-to-root fix |
| 32 | Major UX overhaul |
| 33 | Family member avatars with CRUD |
| 34 | Smart recommendations engine |
| 35–36 | Household sharing (invite flow + atomic merge) |
| 37 | Go-to-market strategy and execution plan (non-code) |
