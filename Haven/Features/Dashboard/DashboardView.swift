import SwiftUI

/// Identifiable wrapper so sheet(item:) carries the system name atomically.
struct VendorActionItem: Identifiable {
    let id = UUID()
    let systemName: String
}

/// Dashboard noise audit (May 2026): Identifiable wrappers so
/// Recent Activity taps can present focused detail sheets via
/// `.sheet(item:)` against a raw UUID payload.
struct DashboardActivityDocumentRef: Identifiable {
    let id: UUID
}
struct DashboardActivityVehicleRef: Identifiable {
    let id: UUID
}

struct DashboardView: View {
    private static let phase66ReleaseDate = ISO8601DateFormatter().date(from: "2026-04-20T00:00:00Z") ?? Date.distantPast

    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showSettings = false
    @State private var showUploadDocument = false
    @State private var showAddProperty = false
    @State private var showSecurityDashboard = false
    /// BUG-022 fix: dashboard "Add Vendor" chip should open AddVendorSheet
    /// directly instead of silently switching to the Property tab.
    @State private var showDashboardAddVendor = false
    // Photo-to-case (2026-07-08)
    @State private var showChezHelpDialog = false
    @State private var showQuickCaptureCamera = false
    @State private var quickCaptureImageData: Data?
    @State private var showQuickCaptureCompose = false
    @State private var navigationPath = NavigationPath()
    @State private var showScenarioStudio = false
    @State private var hasAppeared = false
    @State private var selectedDashboardTask: MaintenanceTaskDBRow?
    @AppStorage("hasSeenSecurityBadge") private var hasSeenSecurityBadge = false
    // Dashboard noise audit (May 2026) — mirror each enrichment-nudge
    // card's @AppStorage dismissal so the priority resolver in this
    // view can pick the single highest-priority active card and skip
    // the rest. The cards themselves still own the writes; we only
    // read here to gate which one renders.
    @AppStorage("maintenanceReorganizedCardDismissed_v1") private var maintenanceReorganizedDismissed = false
    @AppStorage("hasSeenLegacyTasksCleanupP61") private var legacyTasksDismissed = false
    @AppStorage("hnwSubtypeReviewDismissed") private var hnwSubtypeReviewDismissedRaw: String = ""
    @AppStorage("whatsNewPhase57Dismissed") private var whatsNewPhase57Dismissed = false
    @State private var gettingStartedExpanded = false
    @State private var showServiceContractSheet = false
    @State private var serviceContractType: String = ""
    @State private var showApplianceSetup = false
    @State private var pendingMergeRequest: [String: Any]?
    @State private var showVendorCoverage = false

    // Phase 84.5 — Home Assessment dashboard sheet/alert state
    @State private var showAssessmentRescheduleSheet = false
    @State private var confirmAssessmentCancel = false
    /// Phase 95 (audit gap #9) — booking sheet for the dashboard re-book
    /// affordance. Shows when the homeowner taps the "Want Chez to handle
    /// setup instead?" card after they cancelled or originally chose DIY.
    @State private var showRebookHandymanSheet = false
    @State private var showAssessmentPrepNotesSheet = false
    @State private var showAssessmentPrepPhotosSheet = false
    @State private var showAssessmentPrepQuizSheet = false
    /// Round 5 — consolidated assessment detail sheet (visit info +
    /// prep checklist + actions). Opens when the user taps anywhere on
    /// the HomeAssessmentPendingCard.
    @State private var showAssessmentDetailSheet = false
    @State private var showAssessmentReview = false
    @State private var findVendorSystemName: String?
    @State private var findVendorItem: VendorActionItem?
    @State private var addVendorItem: VendorActionItem?
    @State private var isAcceptingMerge = false
    @State private var showMergeResolution = false
    @State private var mergePreviewResponse: MergePreviewResponse?
    @State private var showQuickProjectEntry = false
    @State private var quickProjectPrefill: String = ""
    @AppStorage("hasSeenEmailCallout") private var hasSeenEmailCallout = false
    /// Chez v1: family-member CRUD lives in Settings only post-Life-tab.
    /// `selectedMemberForProfile` stays for tapping a family-member-joined
    /// activity event in the recent feed; chooser + add form are gone.
    @State private var selectedMemberForProfile: FamilyMemberRow?
    // Dashboard noise audit (May 2026): Recent Activity taps land on
    // focused detail sheets instead of generic tab roots. Each entity
    // event sets its own state and a `.sheet(item:)` presents the
    // matching detail view. Same pattern as `selectedDashboardTask` /
    // `selectedMemberForProfile`.
    @State private var selectedActivityContractor: ContractorRow?
    @State private var selectedActivitySystem: HomeSystemRow?
    @State private var selectedActivityDocument: DashboardActivityDocumentRef?
    @State private var selectedActivityVehicle: DashboardActivityVehicleRef?
    @State private var showAddressCompletion = false
    @State private var activeQuizProperty: PropertyRow?
    @State private var showQuizSkipDialog = false
    @AppStorage("hasSkippedHouseQuizForever") private var hasSkippedHouseQuizForever = false
    @AppStorage(PendingInviteKeys.needsPersonalQuiz) private var needsPersonalQuiz = false
    @State private var showPersonalQuiz = false

    /// Phase 61: Presents the LegacyTasksView in a sheet. Opened from the
    /// "View details" button on LegacyTasksNotificationCard.
    @State private var showLegacyTasks = false

    /// Phase 19l — re-fire path for the post-quiz vendor delegation sheet.
    /// When a new contractor is added mid-app (via ContractorDirectoryView
    /// or any other path that posts `.contractorAdded`), the dashboard
    /// computes whether the new vendor's category has any 'either' tasks
    /// the household could delegate. Non-empty `dashboardDelegationCandidates`
    /// triggers the sheet automatically.
    @State private var dashboardDelegationCandidates: [VendorDelegationCandidate] = []
    @State private var showDashboardDelegationSheet: Bool = false

    /// Phase 50 — Cadence suggestion coordinator. Holds the most recent
    /// invoice cadence suggestion until the user accepts or dismisses it.
    /// Lives at app scope so the suggestion survives the InvoiceReviewSheet
    /// dismissal that publishes it. Using @ObservedObject on the singleton
    /// (not @StateObject) so the dashboard observes the shared instance
    /// rather than owning a fresh copy.
    @ObservedObject private var cadenceCoordinator = InvoiceCadenceCoordinator.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            // Phase 95.3 (CI fix): the modifier chain that used to live
            // here (~35 chained modifiers — toolbar, sheets, navigation
            // destination, lifecycle, dialogs) is split across multiple
            // `<V: View>(to content: V) -> some View` methods so each
            // is an independently-type-checkable opaque-return unit.
            // Without this, the macos-15 runner times out walking the
            // chain at body line 83. See extract_dashboard_modifiers.py.
            applyAssessmentModifiers(
                to: applyDialogsAndLifecycle(
                    to: applyVendorContextSheets(
                        to: applyPrimarySheets(to: scrollViewBase)
                    )
                )
            )
        }
    }

    /// Phase 95.3 — extracted from body so the modifier chain can be
    /// composed via `apply*` methods without bloating body's expression.
    @ViewBuilder
    private var scrollViewBase: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                // Phase 56.2: the 32pt in-content "Chez" title was
                // removed so the hero/greeting sit higher in the
                // viewport. Brand identity lives in the nav bar's
                // principal toolbar item below.

                if viewModel.isLoading && !hasAppeared {
                    SkeletonScorecard()
                    SkeletonCard(lineCount: 2)
                    SkeletonCard(lineCount: 3)
                } else {
                    dashboardContent
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing4)
            .padding(.bottom, 100)
        }
        .background(HavenColors.background)
        .navigationTitle("Chez")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { dashboardToolbar }
        // Force an opaque pearl-white nav bar background regardless of
        // scroll content. Without this, the translucent material picks
        // up the navy tint from `HomeCoverageHero` / "Spring readiness"
        // as those scroll under, and the dark-indigo "Chez" wordmark
        // becomes near-invisible against the navy backdrop.
        .toolbarBackground(HavenColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        // `.toolbarBackground` sets the bar color but iOS 17 still picks
        // status-bar text + toolbar tint from the brightness of content
        // scrolled underneath. Lock to light scheme so the shield / Chez
        // wordmark / inbox / settings stay dark on pearl-white at every
        // scroll position.
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    /// Phase 95.3 — toolbar content moved out of the body's modifier
    /// chain and into a `@ToolbarContentBuilder` property.
    @ToolbarContentBuilder
    private var dashboardToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            // Phase 56.2: small brand wordmark in the nav bar
            // replaces the 32pt in-content title. Serif, navy,
            // never competing with the hero for vertical space.
            Text("Chez")
                .font(HavenTypography.fraunces(size: 18, weight: 700))
                .foregroundStyle(HavenColors.textPrimary)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                Haptics.light()
                Analytics.track(.dashboardSecurityTapped)
                navigationPath.append("security")
            } label: {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .accessibilityLabel("Security")
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 12) {
                // (Quick-add "+" menu removed — Upload Document was a
                // duplicate entry point, View Tasks is reachable from
                // the Needs Your Attention list and the Maintenance
                // tab. Trailing toolbar collapses to Inbox + Settings.)

                NavigationLink(value: "inbox") {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.textPrimary)

                        let pendingCount = viewModel.inboxItems.filter { $0.isPending }.count
                        if pendingCount > 0 {
                            Text("\(pendingCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(HavenColors.warning)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .accessibilityLabel("Inbox")
                .accessibilityHint("View forwarded emails")

                Button {
                    Haptics.light()
                    Analytics.track(.settingsViewed)
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Open app settings")
            }
        }
    }

    /// Phase 95.3 — navigation destination's switch lifted out of
    /// the body's modifier chain into its own method so it is
    /// independently type-checked.
    @ViewBuilder
    private func dashboardDestinationView(for destination: String) -> some View {
        if destination == "inbox" {
            InboxView()
        } else if destination == "security" {
            SecurityDashboardView()
        } else if destination == "chez_ownership" {
            // Phase 84 — homeowner-facing primary surface for
            // picking what Chez handles. Reachable from the
            // Dashboard hero card AND from Settings.
            ChezOwnershipView()
        } else if destination == "chez_activity" {
            // Phase 85 — full chronological list of Chez actions
            // for the household. Reached from the Dashboard's
            // "This week with Chez" card.
            if let householdId = viewModel.primaryHouseholdId {
                ChezActivityView(householdId: householdId)
            }
        } else if destination == "maintenance" {
            // Phase 66: Default Maintenance tab lands on the new
            // 5-section hub (Your Services / Handyman / Vehicles /
            // This Season / Upcoming Scheduled). The older
            // MaintenanceScheduleView is the Timeline push
            // destination accessed via "See full year ↗" inside
            // the hub.
            MaintenanceHubView()
        } else if destination == "coverage" {
            // Round 3 (May 2026): focused vendor-coverage view.
            // Replaces the Spring readiness card's old route to
            // MaintenanceHubView. Sections: Covered / Needs a Vendor /
            // Snoozed or Dismissed / Not Counted. Solves the
            // "3 of 3 systems covered" vs "22 systems" labeling
            // mismatch by surfacing every category in one of the
            // four sections.
            CoverageView()
                .environmentObject(viewModel)
        } else if destination == "maintenance_calendar" {
            // Phase H — "View full schedule" now routes to the Tasks v2
            // TasksTimelineSheet (18-month linear scrub) instead of the
            // retired MaintenanceScheduleView. Switch to Tasks tab and
            // post the open notification; an EmptyView fires the chain
            // on appear, then pops back so the navigation stack is clean.
            EmptyView()
                .onAppear {
                    NotificationCenter.default.post(
                        name: .switchToTab,
                        object: nil,
                        userInfo: ["tab": 2]
                    )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        NotificationCenter.default.post(
                            name: .openTasksYearOverview,
                            object: nil
                        )
                    }
                }
        } else if destination == "recommended_services" {
            // Phase 54C.3: Dashboard "Discover more" link.
            if let property = viewModel.properties.first {
                RecommendedServicesView(
                    householdId: property.householdId,
                    propertyId: property.id
                )
            }
        } else if destination == "routines" {
            // Phase 55.3: Pickup day banner tap / edit opens
            // the unified routines list. Replaces the
            // Phase 54D.3 "household_cadences" destination.
            if let householdId = viewModel.primaryHouseholdId {
                RoutinesListView(
                    householdId: householdId,
                    propertyId: viewModel.properties.first?.id
                )
            }
        } else if destination == "email_forwarding" {
            ProjectEmailView()
        } else if destination == "vehicles" {
            if let firstVehicle = viewModel.vehicles.first {
                VehicleDetailView(vehicleID: firstVehicle.id)
            } else {
                PropertyListView()
            }
        } else if destination.hasPrefix("inbox_item_"),
                  let itemId = UUID(uuidString: String(destination.dropFirst("inbox_item_".count))),
                  let item = viewModel.inboxItems.first(where: { $0.id == itemId }) {
            InboxItemDetailView(
                item: item,
                properties: viewModel.properties,
                onProcess: { propertyId, action, category, vehicleId in
                    Task {
                        await viewModel.processInboxItem(item, propertyId: propertyId, action: action, category: category)
                    }
                },
                onDismiss: {
                    viewModel.dismissInboxItem(item)
                },
                onDelete: {
                    viewModel.inboxItems.removeAll { $0.id == item.id }
                    Haptics.success()
                    Task {
                        try? await DatabaseService.shared.deleteInboxItem(id: item.id)
                    }
                }
            )
        } else if destination == "activity_log" {
            ActivityLogView(
                events: viewModel.allActivityEvents,
                onTap: { event in
                    handleActivityTap(event)
                }
            )
        } else if destination.hasPrefix("expecting_"),
                  let memberId = UUID(uuidString: String(destination.dropFirst("expecting_".count))),
                  let member = viewModel.expectingMembers.first(where: { $0.id == memberId }) {
            NewArrivalChecklistView(member: member, documents: viewModel.allDocuments)
        } else {
            EmptyView()
        }
    }

    /// Phase 95.3 — primary sheets (settings, legacy tasks, upload, add vendor, add property, task detail) + the navigation-destination dispatcher.
    @ViewBuilder
    private func applyPrimarySheets<V: View>(to content: V) -> some View {
        content
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showLegacyTasks) {
                NavigationStack {
                    LegacyTasksView()
                }
            }
            .sheet(isPresented: $showUploadDocument) {
                DocumentUploadView(onComplete: {
                    Task { await viewModel.refresh() }
                })
            }
            .sheet(isPresented: $showDashboardAddVendor) {
                AddVendorSheet(onComplete: {
                    Task { await viewModel.refresh() }
                })
            }
            .sheet(isPresented: $showAddProperty) {
                AddPropertyFlow(onComplete: { _ in
                    // Immediately mark property as existing to avoid stale UI
                    viewModel.hasProperty = true
                    Task { await viewModel.refresh() }
                })
            }
            .sheet(item: $selectedDashboardTask) { task in
                NavigationStack {
                    MaintenanceTaskDetailSheet(task: task, onTaskCompleted: {
                        Task { await viewModel.refresh() }
                    })
                }
                .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "chez_cases" {
                    ChezRequestsListView()
                } else {
                    dashboardDestinationView(for: destination)
                }
            }
    }

    /// Phase 95.3 — vendor / project / quiz related sheets and full-screen covers.
    @ViewBuilder
    private func applyVendorContextSheets<V: View>(to content: V) -> some View {
        content
            .sheet(isPresented: $showVendorCoverage) {
                vendorCoverageSheetContent
            }
            .sheet(item: $findVendorItem) { item in
                // Phase 56.1: Find-a-Pro must always open the local vendor
                // recommender, even when there's no "Find a contractor for:"
                // task row yet (common for covered-but-gap-flagged systems
                // or Tier 1 gaps that don't have a DB system row).
                // FindLocalVendorSheet now accepts an optional task + an
                // explicit household id so it can render and adopt without
                // a triggering task.
                if let property = viewModel.properties.first,
                   let context = resolveFindVendorContext(for: item.systemName, property: property) {
                    FindLocalVendorSheet(
                        task: context.task,
                        householdId: property.householdId,
                        town: property.city ?? "",
                        state: property.state ?? "",
                        systemCategory: context.category,
                        categoryDisplayName: context.category.lowercased(),
                        onComplete: {
                            Task { await viewModel.refresh() }
                        }
                    )
                } else {
                    // No property or household available — defensive
                    // fallback so the sheet never dead-ends. Forward
                    // the triggering system's canonical category when
                    // possible so the manual add path still picks up
                    // pre-selection.
                    AddVendorSheet(
                        onComplete: { Task { await viewModel.refresh() } },
                        prefilledCategory: SystemCategoryRegistry.canonical(category: item.systemName)
                    )
                }
            }
            .sheet(item: $addVendorItem) { action in
                // Tapping "I have one" on a Vendor Coverage gap card
                // opens the pick-or-add picker so the user can link an
                // existing vendor (e.g. the water softener shares a
                // provider with water & well services) or add a new
                // one. Both paths link the contractor to the system
                // via `preferredContractorId`.
                if let coverageItem = viewModel.uncoveredCoverageItems.first(where: { $0.systemName == action.systemName || $0.id == action.systemName }),
                   let householdId = viewModel.primaryHouseholdId {
                    VendorCoveragePickerSheet(
                        coverageItem: coverageItem,
                        householdId: householdId,
                        propertyId: viewModel.primaryPropertyId,
                        onComplete: {
                            Task { await viewModel.refresh() }
                        }
                    )
                } else {
                    // Fallback when the coverage item isn't available
                    // (coverage data refreshed between tap and sheet
                    // presentation, or no household resolved yet).
                    // Best-effort canonicalize the action's system
                    // name — if it's already a registry key (which
                    // is the common case since gap card taps stash
                    // the canonical id) we forward it as prefill;
                    // otherwise the prefill is nil and no auto-stamp
                    // happens.
                    AddVendorSheet(
                        onComplete: { Task { await viewModel.refresh() } },
                        prefilledCategory: SystemCategoryRegistry.canonical(category: action.systemName)
                    )
                }
            }
            // Phase 56.1: BrowseSpecialty / AddRecurringService /
            // AddSystemFromCoverage / AddCustomVendorFromCoverage sheets
            // were removed with the Vendor Coverage discovery footer —
            // those entry points now live on Property → Contacts.
            .sheet(isPresented: $showServiceContractSheet) {
                ServiceContractSheet(
                    serviceType: serviceContractType,
                    propertyId: viewModel.primaryPropertyId ?? UUID(),
                    householdId: viewModel.primaryHouseholdId ?? UUID(),
                    onComplete: {
                        Task { await viewModel.refresh() }
                    }
                )
            }
            .sheet(isPresented: $showApplianceSetup) {
                ApplianceSetupSheet(
                    propertyId: viewModel.primaryPropertyId ?? UUID(),
                    householdId: viewModel.primaryHouseholdId ?? UUID(),
                    existingSystems: viewModel.homeSystems,
                    onComplete: { newSystems in
                        viewModel.homeSystems.append(contentsOf: newSystems)
                        Task { await viewModel.refresh() }
                    }
                )
            }
            .sheet(isPresented: $showQuickProjectEntry) {
                if let propId = viewModel.primaryPropertyId,
                   let hhId = viewModel.primaryHouseholdId {
                    NewProjectView(
                        propertyID: propId,
                        householdId: hhId,
                        viewModel: ProjectsViewModel()
                    )
                }
            }
            // Chez v1: family chooser + add-form sheets moved to Settings.
            // Profile-from-activity sheet stays so tapping a "Family member
            // joined" event in Recent Activity still opens the profile.
            .sheet(item: $selectedMemberForProfile) { member in
                NavigationStack {
                    FamilyMemberProfileView(member: member)
                }
                .presentationDetents([.large])
            }
            // Dashboard noise audit (May 2026): Recent Activity rows
            // present focused detail sheets so taps land on the specific
            // contractor / system / document / vehicle instead of a
            // generic tab root.
            .sheet(item: $selectedActivityContractor) { contractor in
                NavigationStack {
                    ContractorDetailView(contractor: contractor)
                }
            }
            .sheet(item: $selectedActivitySystem) { system in
                NavigationStack {
                    SystemDetailRowView(system: system)
                }
            }
            .sheet(item: $selectedActivityDocument) { ref in
                NavigationStack {
                    DocumentDetailView(documentID: ref.id)
                }
            }
            .sheet(item: $selectedActivityVehicle) { ref in
                NavigationStack {
                    VehicleDetailView(vehicleID: ref.id)
                }
            }
            .fullScreenCover(isPresented: $showScenarioStudio) {
                ScenarioStudioView()
            }
            .fullScreenCover(item: $activeQuizProperty) { property in
                HouseQuizView(property: property)
            }
            .sheet(isPresented: $showPersonalQuiz) {
                PersonalQuizView()
            }
    }

    /// Phase 95.3 — skip-quiz dialog + screen tracking + lifecycle (refreshable, task, onReceive×5) + delegation sheet.
    @ViewBuilder
    private func applyDialogsAndLifecycle<V: View>(to content: V) -> some View {
        content
            .confirmationDialog("Skip the House Quiz?", isPresented: $showQuizSkipDialog, titleVisibility: .visible) {
                Button("Skip for now") {
                    // Just dismisses the card for this session — re-shows next launch.
                }
                Button("Skip forever", role: .destructive) {
                    hasSkippedHouseQuizForever = true
                    Analytics.track(.quizDismissed, ["scope": "forever"])
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Skip for now will resurface the quiz on next launch. Skip forever means you'll add this data manually.")
            }
            .trackScreen("Dashboard")
            .refreshable {
                Haptics.light()
                Analytics.track(.dashboardRefreshed)
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
                hasAppeared = true
                // Check for pending merge requests
                do {
                    let data = try await HavenSupabase.mergeHouseholds(action: "check_pending_merges")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let hasPending = json["has_pending"] as? Bool, hasPending,
                       let request = json["merge_request"] as? [String: Any] {
                        pendingMergeRequest = request
                    }
                } catch {
                    print("[Dashboard] Failed to check merge requests: \(error)")
                }

                // Phase 20b — when a brand-new user just finished
                // AccountCreationStep, OnboardingViewModel.complete() stamps
                // the freshly-created property on appState. Pick it up here
                // and auto-launch HouseQuizView. Cleared after consumption
                // so it never re-fires on subsequent dashboard appearances.
                if let pending = appState.pendingQuizProperty {
                    activeQuizProperty = pending
                    appState.pendingQuizProperty = nil
                    Analytics.track(.quizStarted, [
                        "source": "post_account_creation_auto",
                        "property_id": pending.id.uuidString
                    ])
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .popToRoot)) { notification in
                if let tab = notification.userInfo?["tab"] as? Int, tab == 0 {
                    navigationPath = NavigationPath()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .startHouseQuiz)) { notification in
                // AddPropertyFlow's confirmation step posts this with the
                // freshly created PropertyRow when the user taps "Take House
                // Quiz". Refresh first so the new property is in the list,
                // then open HouseQuizView for it.
                if let property = notification.object as? PropertyRow {
                    Task {
                        await viewModel.refresh()
                        activeQuizProperty = property
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToInboxItem)) { notification in
                if let documentId = notification.userInfo?["documentId"] as? UUID {
                    // Find the inbox item for this document
                    if let item = viewModel.inboxItems.first(where: { $0.relatedDocumentId == documentId }) {
                        navigationPath.append("inbox_item_\(item.id.uuidString)")
                    } else {
                        // Item may not be loaded yet -- reload and retry
                        Task {
                            await viewModel.loadInboxItems()
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            let matchedItem = viewModel.inboxItems.first(where: { $0.relatedDocumentId == documentId })
                            if let item = matchedItem {
                                navigationPath.append("inbox_item_\(item.id.uuidString)")
                            }
                        }
                    }
                }
            }
            // Phase 19l — when a new contractor is added mid-app, recompute
            // delegation candidates limited to that one vendor and surface
            // the same sheet the post-quiz path uses. The userInfo carries
            // the new contractor's UUID so we don't fire for unrelated
            // contractors that happened to already exist.
            .onReceive(NotificationCenter.default.publisher(for: .contractorAdded)) { notification in
                guard
                    let idString = notification.userInfo?["contractorId"] as? String,
                    let contractorId = UUID(uuidString: idString)
                else { return }
                Task {
                    await loadDelegationCandidatesForContractor(contractorId)
                }
            }
            // Phase 95 audit fix — refresh the family + staff strips
            // when a member is added/removed via Settings or the quiz.
            // viewModel.refresh() already loads both lists.
            .onReceive(NotificationCenter.default.publisher(for: .householdMemberChanged)) { _ in
                Task { await viewModel.refresh() }
            }
            // Dashboard noise audit Round 3 (May 2026): the Chez
            // ownership view now stages toggles and commits on Save.
            // When that commit fires `.chezOwnershipGroupsChanged`, the
            // Chez at-a-glance row at the top of this view needs to
            // re-read `chezActiveGroupCount` so the headline updates
            // without the user having to pull-to-refresh.
            .onReceive(NotificationCenter.default.publisher(for: .chezOwnershipGroupsChanged)) { _ in
                Task { await viewModel.refresh() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .chezDelegationChanged)) { _ in
                Task { await viewModel.refresh() }
            }
            // Phase 70.A1 follow-on F1 dropped in the merge — base's
            // Round 3 friend-feedback pass took the same route via
            // `activeChezVendorRequests` fed into the registry
            // (loadVendorVisits handles the .chezRequestChanged sink
            // server-side now).
            .sheet(isPresented: $showDashboardDelegationSheet) {
                PostQuizVendorDelegationSheet(
                    candidates: dashboardDelegationCandidates,
                    onApply: { selected in
                        for candidate in selected {
                            for task in candidate.tasks {
                                await MaintenanceViewModel.shared.convertToVendorManaged(
                                    taskId: task.id,
                                    contractor: candidate.contractor
                                )
                            }
                        }
                        Haptics.success()
                        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        await viewModel.refresh()
                    },
                    onSkip: {
                        // No persistence needed on the re-fire path — the
                        // sheet only resurfaces when a brand-new contractor
                        // is added, which is already user-initiated.
                    }
                )
                .presentationDetents([.large])
            }
            // Phase 84.5 — Home assessment dashboard sheets/dialogs
    }

    /// Phase 95.3 — assessment cancel dialog + 6 assessment sheets + 2 onReceive + merge-resolution full-screen cover.
    @ViewBuilder
    private func applyAssessmentModifiers<V: View>(to content: V) -> some View {
        content
            .confirmationDialog(
                "Switch to managing it yourself?",
                isPresented: $confirmAssessmentCancel,
                titleVisibility: .visible
            ) {
                Button("Yes, take it back", role: .destructive) {
                    Task { await cancelHomeAssessment() }
                }
                Button("Keep my visit", role: .cancel) {}
            } message: {
                Text("We'll cancel your free assessment and bring back the quiz so you can set things up yourself. You can switch back anytime.")
            }
            // Phase 95 (audit gap #9) — re-book Chez handyman from the
            // dashboard. Reuses the BookHandymanWindowSheet from
            // onboarding so the booking experience is identical no
            // matter which entry point the homeowner used. On submit,
            // fires requestHomeAssessment + schedules the local
            // confirmation reminder; the dashboard's
            // HomeAssessmentPendingCard then takes over as the
            // status surface.
            .sheet(isPresented: $showRebookHandymanSheet) {
                BookHandymanWindowSheet(
                    onSubmit: { windowStart, timeOfDay in
                        showRebookHandymanSheet = false
                        Task { await rebookHomeAssessment(
                            preferredWindowStart: windowStart,
                            preferredTimeOfDay: timeOfDay
                        ) }
                    },
                    onCancel: {
                        showRebookHandymanSheet = false
                    }
                )
            }
            .sheet(isPresented: $showAssessmentRescheduleSheet) {
                if let assessment = viewModel.homeAssessment {
                    AssessmentRescheduleSheet(
                        assessment: assessment,
                        onSubmit: { notes, preferredDates in
                            try? await HavenSupabase.requestAssessmentReschedule(
                                assessmentId: assessment.id,
                                notes: notes,
                                preferredDates: preferredDates
                            )
                            Analytics.track(.homeAssessmentRescheduleRequested, [
                                "has_preferred_dates": (preferredDates?.isEmpty == false)
                            ])
                            await viewModel.loadHomeAssessment()
                        }
                    )
                    .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showAssessmentPrepNotesSheet) {
                if let assessment = viewModel.homeAssessment {
                    AssessmentPrepNotesSheet(
                        assessment: assessment,
                        onSave: { notes in
                            try? await HavenSupabase.updatePreVisitData(
                                assessmentId: assessment.id, notes: notes,
                                photos: nil, attributes: nil)
                            Analytics.track(.homeAssessmentPreVisitDataUpdated, ["field": "notes"])
                            await viewModel.loadHomeAssessment()
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showAssessmentPrepPhotosSheet) {
                if let assessment = viewModel.homeAssessment {
                    AssessmentPrepPhotosSheet(
                        assessment: assessment,
                        onComplete: {
                            Analytics.track(.homeAssessmentPreVisitDataUpdated, ["field": "photos"])
                            await viewModel.loadHomeAssessment()
                        }
                    )
                    .presentationDetents([.large])
                }
            }
            .sheet(isPresented: $showAssessmentPrepQuizSheet) {
                if let assessment = viewModel.homeAssessment {
                    AssessmentPrepQuizSheet(
                        assessment: assessment,
                        // Round 4: pass the primary property so year-built
                        // and square-footage prefill from the ATTOM data
                        // captured at signup instead of asking the user to
                        // re-enter it.
                        property: viewModel.properties.first(where: { $0.id == viewModel.primaryPropertyId })
                            ?? viewModel.properties.first,
                        onSave: { attributes in
                            try? await HavenSupabase.updatePreVisitData(
                                assessmentId: assessment.id,
                                notes: nil,
                                photos: nil,
                                attributes: attributes
                            )
                            Analytics.track(.homeAssessmentPreVisitDataUpdated, ["field": "quiz"])
                            await viewModel.loadHomeAssessment()
                        }
                    )
                    .presentationDetents([.large])
                }
            }
            // Round 5 (May 2026): consolidated assessment detail sheet.
            // Opens when the user taps the HomeAssessmentPendingCard.
            // Reuses the existing prep state vars + reschedule/cancel
            // flow — this sheet is pure presentation, no DB writes.
            .sheet(isPresented: $showAssessmentDetailSheet) {
                if let assessment = viewModel.homeAssessment {
                    AssessmentDetailSheet(
                        assessment: assessment,
                        handymanFirstName: nil,
                        onReschedule: { showAssessmentRescheduleSheet = true },
                        onSwitchToDIY: { confirmAssessmentCancel = true },
                        onOpenNotes: { showAssessmentPrepNotesSheet = true },
                        onOpenPhotos: { showAssessmentPrepPhotosSheet = true },
                        onOpenPrepQuiz: { showAssessmentPrepQuizSheet = true }
                    )
                    .presentationDetents([.large])
                }
            }
            .sheet(isPresented: $showAssessmentReview) {
                if let assessment = viewModel.homeAssessment {
                    AssessmentReviewView(
                        assessment: assessment,
                        onApproved: {
                            Analytics.track(.homeAssessmentReviewSubmitted, [:])
                            await viewModel.loadHomeAssessment()
                        },
                        onCorrectionsRequested: { items in
                            try? await HavenSupabase.requestAssessmentCorrections(
                                assessmentId: assessment.id, items: items)
                            Analytics.track(.homeAssessmentCorrectionsRequested,
                                ["count": String(items.count)])
                            await viewModel.loadHomeAssessment()
                        }
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openChezAssessmentReview)) { _ in
                showAssessmentReview = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .chezHomeAssessmentChanged)) { _ in
                Task { await viewModel.loadHomeAssessment() }
            }
            // Round 3: CoverageView's "Find a pro" / "I have one" buttons
            // post these notifications so we can reuse DashboardView's
            // existing FindLocalVendorSheet / AddVendorSheet plumbing
            // without duplicating sheet hosting on the pushed view.
            .onReceive(NotificationCenter.default.publisher(for: .openCoverageFindVendor)) { note in
                guard let systemName = note.userInfo?["system_name"] as? String else { return }
                navigationPath = NavigationPath()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    findVendorItem = VendorActionItem(systemName: systemName)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openCoverageAddVendor)) { note in
                guard let systemName = note.userInfo?["system_name"] as? String else { return }
                navigationPath = NavigationPath()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    addVendorItem = VendorActionItem(systemName: systemName)
                }
            }
            .fullScreenCover(isPresented: $showMergeResolution) {
                if let preview = mergePreviewResponse,
                   let requestId = pendingMergeRequest?["id"] as? String {
                    MergeResolutionView(
                        preview: preview.preview,
                        summary: preview.summary,
                        mergeRequestId: requestId,
                        sourceHouseholdName: preview.sourceHouseholdName,
                        targetHouseholdName: preview.targetHouseholdName
                    ) {
                        pendingMergeRequest = nil
                        mergePreviewResponse = nil
                        Task { await viewModel.refresh() }
                    }
                }
            }
    }


    // MARK: - Greeting

    // MARK: - Inbox Section

    /// Phase 95.1 — Admin Apply Validate fix.
    ///
    /// The dashboard body used to be a single ~400-line expression
    /// (skeleton placeholders + ~30 conditional branches). Apple-silicon
    /// Xcode could type-check it, but the macos-15 CI runner blew the
    /// type-checker timeout ("unable to type-check this expression in
    /// reasonable time" at DashboardView.swift:83). Splitting the post-
    /// loading content into its own `@ViewBuilder` property halves the
    /// type-checker's largest expression — body becomes a small
    /// skeleton-vs-content gate; this property holds the actual feed.
    @ViewBuilder
    private var dashboardContent: some View {
        // Phase 95.2 (CI fix): the dashboard content is split into
        // three sub-properties so the macos-15 type-checker doesn't
        // walk through one large @ViewBuilder expression and trip
        // the "unable to type-check in reasonable time" timeout.
        // See split_dashboard_content.py for the rationale.
        dashboardSetupBanners
        dashboardCoverageStack
        dashboardActivityStack
    }

    /// Phase 95.2 — banners + greeting + assessment + Day-0 quiz hero.
    @ViewBuilder
    private var dashboardSetupBanners: some View {
        // 0. Optional update banner (Phase 13). Session-only
        // dismissal so it reappears on next launch until the
        // user actually updates.
        if !appState.optionalUpdateDismissedThisSession,
           let latest = appState.optionalUpdateLatestVersion,
           let message = appState.optionalUpdateMessage {
            OptionalUpdateBanner(
                latestVersion: latest,
                message: message,
                appStoreURL: appState.forceUpdateAppStoreURL
                    ?? URL(string: "https://apps.apple.com/app/id6757167606")!,
                onDismiss: {
                    appState.optionalUpdateDismissedThisSession = true
                }
            )
        }

        // Phase 56.2: compact greeting — single line
        // + optional seasonal context tip. Replaces
        // the two-line "Good evening" / weekday-date
        // view. Saves ~32pt vertical.
        compactGreeting

        // Phase 80 weather card — Tom's design ask: surface a
        // calm-state reassurance ("No severe weather alerts in
        // your area") OR an alert ("Hard Freeze tonight · tap for
        // a quick prep checklist") with one-tap access to a per-
        // event prep sheet. Severity-gated to Severe / Extreme +
        // Immediate / Expected via `WeatherAlertFilter` so the
        // homeowner doesn't get nagged for every advisory.
        WeatherCard(property: viewModel.properties.first)

        // Phase 95 (gap #56) — first-launch welcome
        // for users signed in as a home manager.
        // Renders only for staff member_types and
        // self-dismisses via @AppStorage keyed per
        // user, so the homeowner / spouse / family
        // members never see it.
        if viewModel.isHomeManagerUser, let userId = viewModel.signedInUserId {
            // Household-name source isn't published
            // on DashboardViewModel today; passing
            // nil falls back to a generic "Welcome
            // to Chez" headline. Wiring in the real
            // household label is future work.
            HomeManagerWelcomeCard(
                userId: userId,
                householdName: nil
            )
        }

        // Phase 84.5 — Assessment pending card (the
        // homeowner picked "Have Chez handle it" at
        // signup). Renders status-specific copy across
        // pending → scheduled → en_route → in_progress →
        // submitted → awaiting_review. Suppresses the
        // quiz prompt + Coverage Hero while active.
        // Dashboard noise audit (May 2026): HomeAssessmentPendingCard
        // moved out of the setup-banner stack. The handyman assessment
        // is conceptually an upcoming visit (one in the process of
        // being booked), so it now renders as the topmost row inside
        // upcomingScheduledSection — same shape as a vendor-visit row
        // with a state pill in place of the date. Reschedule and
        // switch-to-DIY actions live inside AssessmentDetailSheet,
        // which the row taps into.

        // Dashboard noise audit (May 2026): MaintenanceReorganizedCard
        // moved into `enrichmentNudgeSlot` so the one-time TestFlight
        // notice is priority-ranked alongside HNW review / Phase 57 /
        // Legacy tasks instead of competing with the quiz hero.

        // 2. Getting Started / Quiz hero — Day 0 focal point.
        // Phase 50 (sub-phase B first-login): only renders
        // when no property exists OR no property's quiz is
        // complete. Once any quiz finishes, this disappears
        // entirely and the YOUR HOME section below takes
        // over as the primary CTA.
        if viewModel.showGettingStarted {
            gettingStartedCard
        }

        // Phase 95 (audit gap #9) — re-book affordance
        // for the homeowner who cancelled their Chez
        // handyman visit OR originally chose the DIY
        // path and has changed their mind. Lives right
        // under the quiz hero so it's the natural
        // "actually, can someone else do this?" exit.
        // Hidden once an assessment is active (the
        // pending card above absorbs the slot).
        if viewModel.hasProperty
            && viewModel.homeAssessment == nil
            && !viewModel.hasCompletedAnyQuiz {
            ReBookChezHandymanCard {
                showRebookHandymanSheet = true
            }
        }

        // 2.5 Incomplete address banner
        if let property = viewModel.propertyNeedsAddress {
            incompleteAddressBanner(property)
        }

        // 2.6 Pending merge request banner
        if let merge = pendingMergeRequest {
            mergeRequestBanner(merge)
        }
    }

    /// Phase 95.2 — Chez ownership hero, monthly summary, weekly tally, Home Coverage Hero, seasonal reminder, this week + upcoming + quick actions.
    @ViewBuilder
    private var dashboardCoverageStack: some View {
        // Phase 84 — Chez ownership hero card. Surfaces
        // "what % of your house Chez is running" and
        // routes to the new What Chez Handles page where
        // the homeowner can flip group toggles or browse
        // their inventory of delegated entities.
        // Dashboard noise audit (May 2026): collapsed the Chez
        // ownership hero from a card-with-CTA to a single tappable row.
        // The row stays as the at-a-glance entry; ChezOwnershipView
        // itself owns the Full Mode toggle + explainer copy.
        if viewModel.hasCompletedAnyQuiz {
            ChezOwnershipHeroCard(
                activeGroupCount: viewModel.chezActiveGroupCount,
                delegatedItemCount: viewModel.chezDelegatedItemCount,
                onTap: {
                    Haptics.light()
                    navigationPath.append("chez_ownership")
                }
            )
        }

        // Phase 85 — Monthly summary card. Renders when
        // an unviewed summary exists (1st of each month
        // for the previous month, generated by the
        // chez-monthly-summary scheduled fn). Auto-
        // dismisses on tap (mark-viewed) or via the
        // explicit dismiss X.
        if let summary = viewModel.unviewedMonthlySummary {
            MonthlySummaryCard(
                summary: summary,
                onTap: {
                    Task { await viewModel.dismissMonthlySummary() }
                    navigationPath.append("chez_activity")
                },
                onDismiss: {
                    Task { await viewModel.dismissMonthlySummary() }
                }
            )
        }

        // Phase 70.A1 follow-on L2 — K2's ChezInFlightCard was removed.
        // Tom's call: the Inbox → Chez sub-tab is the canonical chat
        // surface, and K1's auto-route-after-submit lands users there
        // directly without needing a Dashboard preview card. The
        // ChezOwnershipHeroCard (above) + ChezActivityCard (below) still
        // cover the "what's Chez doing" surface from different angles.

        // Phase 85 — "This week with Chez" digest. Renders
        // only when there's been Chez activity in the
        // last 7 days; DIY-default users see nothing.
        if viewModel.chezActivityWeeklyTally.hasAnything {
            ChezActivityCard(
                tally: viewModel.chezActivityWeeklyTally,
                recentItems: viewModel.recentChezActivity
            ) {
                Haptics.light()
                navigationPath.append("chez_activity")
            }
        }

        if viewModel.hasCompletedAnyQuiz {
            HomeCoverageHero(
                propertyName: viewModel.properties.first(where: { $0.id == viewModel.primaryPropertyId })?.name
                    ?? viewModel.properties.first?.name,
                coveredCount: viewModel.coveredCoverageItems.count,
                totalCount: viewModel.coveredCoverageItems.count + viewModel.uncoveredCoverageItems.count,
                activeVendorCount: viewModel.activeVendorCount,
                nextVisit: viewModel.nextScheduledService,
                uncoveredSystemNames: viewModel.uncoveredCoverageItems.map(\.systemName),
                dismissedCount: viewModel.dismissedCoverageCategories.count,
                onTap: {
                    Haptics.light()
                    // Round 3 (May 2026): route to the focused coverage view
                    // instead of the property-scoped MaintenanceHubView. The
                    // user's mental model when tapping "Your home is covered"
                    // is "show me what's covered" — not the task queue.
                    navigationPath.append("coverage")
                },
                onFindVendor: {
                    Haptics.medium()
                    showVendorCoverage = true
                }
            )
        }

        // Phase 67 (G1): seasonal "Time to book your handyman"
        // reminder. Computed from the singleton handyman_recurring
        // routine + pending punch items + ±14 days of the
        // April / October anchor. Placed above Up Next so the
        // homeowner sees the seasonal nudge before they wade
        // into the task list.
        if viewModel.hasCompletedAnyQuiz,
           let reminder = viewModel.handymanSeasonalReminder {
            HandymanSeasonalReminderCard(reminder: reminder) {
                NotificationCenter.default.post(
                    name: .switchToTab, object: nil, userInfo: ["tab": 2]
                )
                NotificationCenter.default.post(
                    name: .handymanModeRequested, object: nil
                )
            }
            .padding(.horizontal, HavenTheme.spacing20)
        }

        if viewModel.hasCompletedAnyQuiz {
            thisWeekSection
        }

        if viewModel.hasCompletedAnyQuiz,
           (viewModel.homeAssessment != nil
             || !viewModel.upcomingVendorVisits.isEmpty
             || viewModel.nextStandingVisit != nil) {
            upcomingScheduledSection
        }

        // Chez v1: HandymanSuggestionCard moved to Tasks → Handyman.
        // Punch list is the single source of truth there.

        if viewModel.hasCompletedAnyQuiz {
            QuickActionsRow(
                onAskAlfred: {
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 3])
                },
                onUploadDoc: {
                    showUploadDocument = true
                },
                onAskChez: {
                    // Photo-to-case (2026-07-08): the Chez slot now asks
                    // HOW — "snap it" (camera-first, the fallen-branch
                    // flow) or "describe it" (the classic composer).
                    Haptics.light()
                    showChezHelpDialog = true
                },
                onAddVendor: {
                    showDashboardAddVendor = true
                }
            )
            .confirmationDialog("How can Chez help?", isPresented: $showChezHelpDialog, titleVisibility: .visible) {
                if CameraCaptureView.isAvailable {
                    Button("Snap a photo of the problem") {
                        Analytics.track(.quickCaptureOpened, ["source": "dashboard"])
                        showQuickCaptureCamera = true
                    }
                }
                Button("Describe it instead") {
                    NotificationCenter.default.post(
                        name: .openChezRequestComposer,
                        object: nil,
                        userInfo: [
                            "category": ChezCategory.general.rawValue,
                            "context": [
                                "_source": "dashboard_quick_action",
                                "source_entity_type": "dashboard",
                                "source_entity_label": "Dashboard quick action",
                            ],
                        ]
                    )
                }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showQuickCaptureCamera) {
                CameraCaptureView { image in
                    quickCaptureImageData = image.jpegData(compressionQuality: 0.8)
                }
                .ignoresSafeArea()
            }
            .onChange(of: quickCaptureImageData) { _, data in
                if data != nil { showQuickCaptureCompose = true }
            }
            .sheet(isPresented: $showQuickCaptureCompose, onDismiss: { quickCaptureImageData = nil }) {
                ChezRequestComposeSheet(
                    category: .general,
                    contextHints: [
                        "_source": "quick_capture",
                        "source_entity_type": "dashboard",
                        "source_entity_label": "Photo capture",
                    ],
                    isCategoryFixed: false,
                    initialImageData: quickCaptureImageData
                )
            }
        }

        // Photo-to-case (2026-07-08): open cases at a glance — cases
        // otherwise only live behind Inbox → Chez.
        if viewModel.openChezCaseCount > 0 {
            Button {
                Haptics.light()
                navigationPath.append("chez_cases")
            } label: {
                HStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "person.crop.circle.badge.clock")
                        .font(.system(size: 15))
                        .foregroundStyle(HavenColors.navy800)
                    Text(viewModel.openChezCaseCount == 1
                         ? "Chez is working 1 open case"
                         : "Chez is working \(viewModel.openChezCaseCount) open cases")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .buttonStyle(.plain)
        }
    }

    /// Phase 95.2 — What's New, legacy tasks, cadence suggestion, pickup banner, recent activity, Chez entry pill, make-it-yours, expecting members.
    @ViewBuilder
    private var dashboardActivityStack: some View {
        // Dashboard noise audit (May 2026): single enrichment-nudge
        // slot. Renders only the highest-priority active card so
        // pre-release users + new-property users don't see stacked
        // "Review your home" prompts. Priority: Maintenance Reorganized
        // (one-time cleanup) > Legacy Tasks (TestFlight cleanup) >
        // HNW Subtype Review (new property, 14-day window) > What's
        // New Phase 57 (existing pre-release users). Each card's own
        // dismissal @AppStorage still gates the writes; we mirror
        // the reads here.
        enrichmentNudgeSlot

        // Chez v1: FindHandymanCard moved to Tasks → Handyman
        // hero ("Find a handyman" CTA). One canonical entry
        // point so users always know where the handyman lives.

        // 3.5 Cadence suggestion (inline, event-driven)
        if let suggestion = cadenceCoordinator.current {
            CadenceSuggestionCard(
                suggestion: suggestion,
                onAccept: {
                    Task {
                        let ok = await cadenceCoordinator.apply(suggestion)
                        if ok {
                            Haptics.success()
                            await viewModel.refresh()
                        } else {
                            Haptics.error()
                        }
                    }
                },
                onDismiss: {
                    cadenceCoordinator.dismiss()
                    Haptics.light()
                }
            )
        }

        // 3.4 Phase 54D.3: Pickup day banner (trash /
        // recycling / school dropoff). Renders only
        // inside the banner's own surfacing window
        // (after 6pm for tomorrow, before 10am for
        // today) so the dashboard stays quiet the
        // rest of the day.
        if viewModel.hasCompletedAnyQuiz,
           let householdId = viewModel.primaryHouseholdId {
            PickupDayBanner(
                householdId: householdId,
                onTap: {
                    navigationPath.append("routines")
                },
                onEdit: {
                    navigationPath.append("routines")
                }
            )
        }

        // 5. Recent Activity feed — Phase 56.2: feed
        // uses `dashboardActivityEvents`, which filters
        // onboarding "X added" noise after Day 7 so the
        // card stays useful beyond the setup week. The
        // full unfiltered list is still reachable via
        // "View all activity" → ActivityLogView.
        if viewModel.hasCompletedAnyQuiz && !viewModel.dashboardActivityEvents.isEmpty {
            RecentActivityFeed(
                events: Array(viewModel.dashboardActivityEvents.prefix(5)),
                totalEventCount: viewModel.allActivityEvents.count,
                onTap: { event in
                    handleActivityTap(event)
                },
                onViewAll: {
                    navigationPath.append("activity_log")
                }
            )
        }

        // Phase 56.2: "Discover more services for your
        // home" orphan link removed. Accessible from
        // Property → Maintenance → Recommended row and
        // from Contacts → Add or discover, so three
        // entry points remain without the dashboard
        // clutter.

        // Phase 80 bottom "Need help? Ask Chez" pill removed in the
        // dashboard noise audit (May 2026). Chez compose is promoted to
        // a primary Quick Actions tile; the Ownership row above and 17
        // in-context entry points across the app keep delegation
        // reachable.

        // ── Conditional sections ──

        // "Make it Yours" hero card for invitees
        if needsPersonalQuiz {
            makeItYoursHeroCard
        }

        // Expecting members
        ForEach(viewModel.expectingMembers) { member in
            NavigationLink(value: "expecting_\(member.id.uuidString)") {
                expectingCard(member: member)
            }
            .buttonStyle(.plain)
        }
    }


    private var vehicleAlertsCard: some View {
        NavigationLink(value: "vehicles") {
            HavenCard {
                HStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.unresolvedVehicleRecalls > 0 ? HavenColors.critical : HavenColors.warning)
                        .frame(width: 36, height: 36)
                        .background((viewModel.unresolvedVehicleRecalls > 0 ? HavenColors.critical : HavenColors.warning).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        if viewModel.unresolvedVehicleRecalls > 0 {
                            Text("\(viewModel.unresolvedVehicleRecalls) Open Vehicle Recall\(viewModel.unresolvedVehicleRecalls == 1 ? "" : "s")")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                        } else {
                            Text("Vehicle Attention Needed")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        Text("Tap to view details")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var inboxSection: some View {
        VStack(spacing: HavenTheme.spacing8) {
            // Section header with "View All" link
            HStack {
                let pendingCount = viewModel.inboxItems.filter { $0.isPending }.count
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 12))
                    Text("INBOX")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                    if pendingCount > 0 {
                        Text("\(pendingCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(HavenColors.warning)
                            .clipShape(Circle())
                    }
                }
                .foregroundStyle(HavenColors.textTertiary)

                Spacer()

                NavigationLink(value: "inbox") {
                    Text("View All")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }

            ForEach(viewModel.inboxItems.prefix(5)) { item in
                NavigationLink(value: "inbox_item_\(item.id.uuidString)") {
                    inboxBanner(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func inboxBanner(_ item: DatabaseService.InboxItemRow) -> some View {
        HStack(spacing: 12) {
            Group {
                if item.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: item.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 30, height: 30)
            .background(item.isProcessing ? HavenColors.navy500 : item.isPending ? HavenColors.warning : HavenColors.success)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    if item.isProcessing {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Processing")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(HavenColors.navy500)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    } else if item.isPending {
                        Text("Action needed")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(HavenColors.warning)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(HavenColors.warning.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if let summary = item.summary {
                    Text(summary)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if !item.isPending {
                Button {
                    withAnimation { viewModel.dismissInboxItem(item) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(6)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(item.isProcessing ? HavenColors.navy.opacity(0.04) : item.isPending ? HavenColors.warning.opacity(0.06) : HavenColors.success.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke((item.isProcessing ? HavenColors.navy : item.isPending ? HavenColors.warning : HavenColors.success).opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var greetingView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greetingText)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Phase 56.2 / Addendum Fix 4: Bold greeting + lighter date + icon-
    /// anchored seasonal tip. "**Good evening, Tom**  ·  Wednesday,
    /// April 15" reads as two semantically distinct items via weight
    /// contrast. The seasonal tip gains a month-driven icon (leaf, sun,
    /// wind, snowflake) so it doesn't float as a footnote.
    private var compactGreeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(greetingText)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("  \u{00B7}  ")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if let subtitle = viewModel.greetingSubtitle {
                let tint: Color = {
                    switch subtitle.tone {
                    case .urgent:    return HavenColors.warning
                    case .scheduled: return HavenColors.navy700
                    case .ambient:   return HavenColors.textTertiary
                    }
                }()
                HStack(spacing: 6) {
                    Image(systemName: subtitle.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(tint)
                    Text(subtitle.text)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(tint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Dashboard noise audit (May 2026): the single enrichment-nudge
    /// slot. Priority order (high → low): Maintenance Reorganized
    /// (one-time TestFlight notice) → Legacy Tasks → HNW Subtype Review
    /// → What's New Phase 57. Only the highest-priority active card
    /// renders. Each card's own @AppStorage dismissal flag is still
    /// the source of truth — we read the same key here so the resolver
    /// stays in sync.
    @ViewBuilder
    private var enrichmentNudgeSlot: some View {
        if shouldShowMaintenanceReorganizedNudge {
            MaintenanceReorganizedCard(
                onLearnMore: {
                    // Dashboard noise audit (May 2026): the card
                    // announces "we reorganized your maintenance into
                    // a single hub" — that hub now lives on the Tasks
                    // tab (Phase 67 V5 TasksHubView), not the Property
                    // tab. Route there so "Learn more" lands the user
                    // on the new surface the card is explaining.
                    NotificationCenter.default.post(
                        name: .switchToTab,
                        object: nil,
                        userInfo: ["tab": 2]
                    )
                },
                onDismiss: {}
            )
        } else if shouldShowLegacyTasksNudge {
            LegacyTasksNotificationCard(
                legacyCount: viewModel.legacyTaskCount,
                onViewDetails: { showLegacyTasks = true }
            )
        } else if shouldShowHNWReviewNudge,
                  let primaryProperty = viewModel.properties.first(where: { $0.id == viewModel.primaryPropertyId }) {
            HNWSubtypeReviewCard(
                property: primaryProperty,
                onReviewComplete: {
                    Task { await viewModel.refresh() }
                }
            )
        } else if shouldShowPhase57Nudge,
                  let primaryProperty = viewModel.properties.first(where: { $0.id == viewModel.primaryPropertyId }) {
            WhatsNewPhase57Card(
                property: primaryProperty,
                onReviewComplete: {
                    Task { await viewModel.refresh() }
                }
            )
        }
    }

    private var shouldShowMaintenanceReorganizedNudge: Bool {
        guard viewModel.hasCompletedAnyQuiz,
              !maintenanceReorganizedDismissed,
              let accountCreated = viewModel.accountCreatedAt else {
            return false
        }
        return accountCreated < Self.phase66ReleaseDate
    }

    private var shouldShowLegacyTasksNudge: Bool {
        guard viewModel.hasCompletedAnyQuiz,
              !legacyTasksDismissed,
              viewModel.legacyTaskCount > 0,
              let accountCreated = viewModel.accountCreatedAt else {
            return false
        }
        return accountCreated < Self.phase66ReleaseDate
    }

    private var shouldShowHNWReviewNudge: Bool {
        guard viewModel.hasCompletedAnyQuiz,
              let primaryProperty = viewModel.properties.first(where: { $0.id == viewModel.primaryPropertyId }),
              let createdAt = primaryProperty.createdAt else {
            return false
        }
        // Mirror HNWSubtypeReviewCard.dismissedIds parsing — comma-joined
        // UUID list keyed on property id so multi-property households
        // dismiss per-property.
        let dismissed = Set(
            hnwSubtypeReviewDismissedRaw
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
        if dismissed.contains(primaryProperty.id.uuidString) { return false }
        let interval = Date().timeIntervalSince(createdAt)
        let windowSeconds = Double(HNWSubtypeReviewCard.visibilityWindowDays) * 24 * 60 * 60
        return interval >= 0 && interval <= windowSeconds
    }

    private var shouldShowPhase57Nudge: Bool {
        guard viewModel.hasCompletedAnyQuiz,
              !whatsNewPhase57Dismissed,
              let primaryProperty = viewModel.properties.first(where: { $0.id == viewModel.primaryPropertyId }),
              let createdAt = primaryProperty.createdAt else {
            return false
        }
        return createdAt < WhatsNewPhase57Card.phase57ReleaseDate
    }

    @ViewBuilder
    private var upcomingScheduledSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(alignment: .firstTextBaseline) {
                Text("UPCOMING")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                Spacer()

                Button(action: {
                    Haptics.light()
                    // Phase 95.1 fix: 'View schedule' should land on the
                    // calendar / timeline (MaintenanceScheduleView with
                    // initialLayout: .calendar), not the categorized
                    // maintenance hub. CLAUDE.md "Dashboard Architecture"
                    // explicitly says: 'View full schedule entry point
                    // (Phase 54A): The link under "Up Next" now pushes
                    // navigationPath.append("maintenance_calendar")'. The
                    // destination handler at line ~227 already wires
                    // "maintenance_calendar" to MaintenanceScheduleView
                    // (initialLayout: .calendar). Caught by overnight E2E
                    // (W4S16 Dashboard usefulness review).
                    navigationPath.append("maintenance_calendar")
                }) {
                    Text("View schedule")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                .buttonStyle(.plain)
            }

            HavenCard {
                VStack(spacing: 0) {
                    // Dashboard noise audit (May 2026): handyman
                    // assessment renders as the topmost row of the
                    // Upcoming list when active. Same row family as a
                    // vendor visit — only the state pill marks it as
                    // in-flight rather than booked.
                    let visits = Array(viewModel.upcomingVendorVisits.prefix(3))
                    let visitRowsCount: Int = {
                        if !visits.isEmpty { return visits.count }
                        return viewModel.nextStandingVisit != nil ? 1 : 0
                    }()

                    if let assessment = viewModel.homeAssessment {
                        Button {
                            Haptics.light()
                            showAssessmentDetailSheet = true
                        } label: {
                            assessmentUpcomingRow(assessment)
                        }
                        .buttonStyle(.plain)

                        if visitRowsCount > 0 {
                            Divider()
                                .background(HavenColors.beige200)
                                .padding(.leading, 44)
                        }
                    }

                    if !visits.isEmpty {
                        ForEach(Array(visits.enumerated()), id: \.element.id) { index, visit in
                            Button {
                                selectedDashboardTask = visit.task
                            } label: {
                                upcomingVisitRow(
                                    title: visit.task.title,
                                    vendor: visit.vendorName ?? "Vendor",
                                    date: visit.task.nextDueDate.havenDateShort
                                )
                            }
                            .buttonStyle(.plain)

                            if index < visits.count - 1 {
                                Divider()
                                    .background(HavenColors.beige200)
                                    .padding(.leading, 44)
                            }
                        }
                    } else if let nextStandingVisit = viewModel.nextStandingVisit {
                        Button {
                            // Dashboard noise audit (May 2026): standing
                            // visits are routine-based recurring visits
                            // without a dedicated detail view. The
                            // Calendar layout of MaintenanceScheduleView
                            // is the canonical "see all my upcoming
                            // visits in context" surface — closer to
                            // what the tapper wants than the generic
                            // MaintenanceHub. Surface the visit on the
                            // calendar where it lives.
                            navigationPath.append("maintenance_calendar")
                        } label: {
                            upcomingVisitRow(
                                title: nextStandingVisit.title,
                                vendor: nextStandingVisit.vendor,
                                date: nextStandingVisit.date.havenDateShort
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// Dashboard noise audit (May 2026): the handyman assessment lives
    /// inside the Upcoming list as a single row. Same visual family as
    /// `upcomingVisitRow` — purple-tinted Chez icon, headline copy
    /// reflecting the assessment lifecycle, optional state pill on the
    /// right. Tap routes to AssessmentDetailSheet where reschedule +
    /// switch-to-DIY actions live.
    private func assessmentUpcomingRow(_ assessment: HomeAssessmentRow) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 32, height: 32)
                .background(HavenColors.action.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(assessmentRowTitle(for: assessment))
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("Chez handyman · Free")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            assessmentStatePill(for: assessment.status)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, HavenTheme.spacing12)
    }

    private func assessmentRowTitle(for assessment: HomeAssessmentRow) -> String {
        switch assessment.status {
        case .pending:
            return "Home assessment"
        case .scheduled:
            return "Home assessment"
        case .enRoute:
            return "Home assessment · Heading your way"
        case .inProgress:
            return "Home assessment · Visit in progress"
        case .submitted, .awaitingReview:
            return "Home assessment · Review needed"
        case .correctionsRequested:
            return "Home assessment · Corrections in progress"
        case .ingestionFailed:
            return "Home assessment · Action needed"
        case .completed, .cancelled:
            return "Home assessment"
        }
    }

    private func assessmentStatePill(for status: HomeAssessmentStatus) -> some View {
        let (label, tint): (String, Color) = {
            switch status {
            case .pending:
                return ("Being assigned", HavenColors.action)
            case .scheduled:
                return ("Scheduled", HavenColors.navy700)
            case .enRoute:
                return ("En route", HavenColors.action)
            case .inProgress:
                return ("In progress", HavenColors.action)
            case .submitted, .awaitingReview:
                return ("Review", HavenColors.warning)
            case .correctionsRequested:
                return ("In progress", HavenColors.action)
            case .ingestionFailed:
                return ("Action", HavenColors.warning)
            case .completed:
                return ("Complete", Color.green)
            case .cancelled:
                return ("Cancelled", HavenColors.textTertiary)
            }
        }()

        return Text(label)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func upcomingVisitRow(title: String, vendor: String, date: String) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 32, height: 32)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(date) · \(title)")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(vendor)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, HavenTheme.spacing12)
    }

    /// Phase 56.2: trailing "View full schedule →" link. Extracted from
    /// the inline block inside `body` so the 0/1/2+ conditional UP NEXT
    /// branches can all reuse it.
    ///
    /// NAV-001 fix: routes to MaintenanceHubView (destination "maintenance")
    /// instead of MaintenanceScheduleView so the primary Phase 66 surface
    /// is one tap from Dashboard. The hub's "See full year ↗" link pushes
    /// to Timeline for users who want the flat month-by-month view.
    private var viewFullScheduleLink: some View {
        Button {
            Haptics.light()
            navigationPath.append("maintenance_calendar")
        } label: {
            HStack(spacing: 4) {
                Text("View full schedule")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.navy700)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.plain)
    }

    /// Phase 56.2: Type-aware caption for the single-item strip so the
    /// label reflects what the row actually is. Keeps the strip clearly
    /// distinct from the hero's "Next visit:" vendor schedule.
    private func singleStripCaption(for item: ThisWeekItem) -> String {
        switch item.kind {
        case .overdue:
            return "Overdue"
        case .vendorVisit:
            return "Also coming up"
        case .diyTask:
            return "Your to-do"
        case .inboxReview:
            return "To review"
        }
    }

    /// Phase 56.2: Compact one-row strip for when UP NEXT has exactly
    /// one item. Reads as hero context, not as a titled section.
    @ViewBuilder
    private var singleUpNextStrip: some View {
        if let item = viewModel.thisWeekItems.first {
            Button {
                Haptics.light()
                if case .inboxReview = item.kind {
                    navigationPath.append("inbox")
                } else if let task = item.task {
                    selectedDashboardTask = task
                }
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    // Addendum Fix 7: lighter icon so the strip reads
                    // as ambient context beneath the bolder quick actions.
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 28, height: 28)
                        .background(HavenColors.beige200.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    VStack(alignment: .leading, spacing: 1) {
                        // Phase 56.2: "Your to-do" distinguishes a
                        // personal action item from the hero's
                        // "Next visit:" vendor-schedule label above.
                        Text(singleStripCaption(for: item))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(item.title)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// Build 90: Up Next section extracted to stay under SwiftUI's
    /// expression type-check budget.
    @ViewBuilder
    private var thisWeekSection: some View {
        ThisWeekSection(
            items: viewModel.thisWeekItems,
            totalTaskCount: viewModel.overdueMaintenanceTasks.count + viewModel.dueThisWeekTasks.count,
            onItemTapped: { item in
                Haptics.light()
                if case .inboxReview = item.kind {
                    navigationPath.append("inbox")
                } else if let task = item.task {
                    selectedDashboardTask = task
                }
            },
            onSeeAll: {
                navigationPath.append("maintenance_calendar")
            },
            onSnooze: { item in
                Task {
                    await viewModel.snoozeTask(item)
                }
            }
        )
    }

    /// Phase 56.1: Resolves the context FindLocalVendorSheet needs when
    /// entered from the dashboard Vendor Coverage sheet. Uses the
    /// matching coverage item's category key (stable across
    /// system-backed and Tier 1 gap rows) so "Find a Pro" works even
    /// when no `needs_vendor` task exists yet. When a task does exist,
    /// we pass it through so the adoption pass has a concrete anchor.
    private func resolveFindVendorContext(
        for systemNameOrCategory: String,
        property: PropertyRow
    ) -> (task: MaintenanceTaskDBRow?, category: String)? {
        let candidate = (viewModel.uncoveredCoverageItems + viewModel.coveredCoverageItems)
            .first(where: { $0.systemName == systemNameOrCategory || $0.id == systemNameOrCategory })

        // Prefer the category key from the coverage item — it's the
        // canonical token used across the registry + reconciler.
        let category: String? = {
            if let c = candidate, !c.id.isEmpty { return c.id }
            return viewModel.homeSystems
                .first(where: { $0.name == systemNameOrCategory || $0.category == systemNameOrCategory })?.category
        }()

        guard let resolvedCategory = category else { return nil }

        let task: MaintenanceTaskDBRow? = {
            // Exact match by systemId first (strongest signal).
            if let systemId = candidate?.systemId ?? viewModel.homeSystems
                .first(where: { $0.name == systemNameOrCategory || $0.category == systemNameOrCategory })?.id {
                if let t = MaintenanceViewModel.shared.tasks.first(where: {
                    $0.systemId == systemId && $0.needsVendor == true
                }) {
                    return t
                }
            }
            // Otherwise fall through — no triggering task, but the sheet
            // will still render because `task` is optional and the
            // adoption pass walks matching category tasks.
            return nil
        }()

        return (task: task, category: resolvedCategory)
    }

    private var vendorCoverageSheetContent: some View {
        // Phase 56.1: Vendor Coverage is now a focused gap-resolution
        // surface. Discovery actions (add vendor / browse specialty /
        // add routine / see recommended) moved to Property → Contacts.
        let uncovered = viewModel.uncoveredCoverageItems
        let total = uncovered.count + viewModel.coveredCoverageItems.count
        return VendorCoverageSheet(
            uncoveredItems: uncovered,
            totalSystemCount: total,
            onFindVendor: { systemName in
                showVendorCoverage = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    findVendorItem = VendorActionItem(systemName: systemName)
                }
            },
            onAddVendor: { systemName in
                showVendorCoverage = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    addVendorItem = VendorActionItem(systemName: systemName)
                }
            },
            onDismissItem: { item in
                guard let householdId = viewModel.primaryHouseholdId else { return }
                Task {
                    try? await DatabaseService.shared.dismissCategory(
                        householdId: householdId,
                        category: item.id
                    )
                    Analytics.track(.coverageItemDismissed, ["category": item.id])
                    await viewModel.refresh()
                }
            },
            onSnoozeItem: { item, months in
                guard let householdId = viewModel.primaryHouseholdId else { return }
                let until = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
                Task {
                    try? await DatabaseService.shared.snoozeCategory(
                        householdId: householdId,
                        category: item.id,
                        until: until
                    )
                    Analytics.track(.coverageItemSnoozed, [
                        "category": item.id,
                        "months": months
                    ])
                    await viewModel.refresh()
                }
            },
            onManageVendors: {
                // Phase 56.1: dismiss the sheet, switch to the Property
                // tab, and land on the Contacts sub-tab. Matches the
                // rest of the app's cross-tab navigation pattern
                // (switchToTab + navigateToPropertySection).
                showVendorCoverage = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    NotificationCenter.default.post(
                        name: .switchToTab,
                        object: nil,
                        userInfo: ["tab": 1]
                    )
                    NotificationCenter.default.post(
                        name: .navigateToPropertySection,
                        object: nil,
                        userInfo: ["section": "vendors"]
                    )
                }
            }
        )
    }

    /// Phase 50: Vendor schedule strip (kept for reference, no longer
    /// rendered on the dashboard body as of Build 90).
    @ViewBuilder
    private var vendorScheduleSection: some View {
        VendorScheduleStrip(
            visits: viewModel.upcomingVendorVisits,
            overdueCount: viewModel.overdueMaintenanceTasks.count,
            dueThisWeekCount: viewModel.dueThisWeekTaskCount,
            forwardingEmail: viewModel.householdForwardingEmail,
            onTapVisit: { task in
                selectedDashboardTask = task
            },
            onSeeAll: {
                navigationPath.append("maintenance")
            },
            onUploadInvoice: {
                showUploadDocument = true
            },
            onAddVendor: {
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
            }
        )

        if let suggestion = cadenceCoordinator.current {
            CadenceSuggestionCard(
                suggestion: suggestion,
                onAccept: {
                    Task {
                        let ok = await cadenceCoordinator.apply(suggestion)
                        if ok {
                            Haptics.success()
                            await viewModel.refresh()
                        } else {
                            Haptics.error()
                        }
                    }
                },
                onDismiss: {
                    cadenceCoordinator.dismiss()
                    Haptics.light()
                }
            )
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        if hour < 12 { timeOfDay = "Good morning" }
        else if hour < 17 { timeOfDay = "Good afternoon" }
        else { timeOfDay = "Good evening" }

        if let firstName = viewModel.userFirstName, !firstName.isEmpty {
            return "\(timeOfDay), \(firstName)"
        }
        return timeOfDay
    }

    // MARK: - What If Card

    // MARK: - Email Forwarding Callout

    private var emailForwardingCallout: some View {
        NavigationLink(value: "email_forwarding") {
            HStack(spacing: 12) {
                Image(systemName: "envelope.arrow.triangle.branch.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("You have a forwarding email")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Forward quotes, documents, school emails & more to Chez")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.navy.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button {
                hasSeenEmailCallout = true
                Haptics.light()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(6)
                    .background(HavenColors.surface)
                    .clipShape(Circle())
            }
            .offset(x: 4, y: -4)
        }
    }

    private var whatIfCard: some View {
        Button {
            Haptics.light()
            Analytics.track(.scenarioStudioOpened, ["source": "dashboard_what_if_card"])
            showScenarioStudio = true
        } label: {
            HavenCard {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [HavenColors.navy.opacity(0.08), HavenColors.navy.opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scenario Planning")
                            .font(HavenTypography.fraunces(size: 18, weight: 700))
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Explore what-if questions with your real data: taxes, home, projects, wealth")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Make it Yours (personal quiz hero for invitees)

    private var makeItYoursHeroCard: some View {
        Button {
            Haptics.medium()
            showPersonalQuiz = true
        } label: {
            HavenCard {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MAKE IT YOURS")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.2)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("Add your profile (optional)")
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("5 quick questions about you and your vehicles. Takes about 2 minutes.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }

                HStack(spacing: HavenTheme.spacing8) {
                    HavenButton(title: "Start", action: {
                        Haptics.medium()
                        showPersonalQuiz = true
                    })
                    HavenButton(
                        title: "Not now",
                        action: {
                            UserDefaults.standard.set(false, forKey: PendingInviteKeys.needsPersonalQuiz)
                            needsPersonalQuiz = false
                        },
                        style: .secondary
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Getting Started

    @ViewBuilder
    private var gettingStartedCard: some View {
        // Phase 50 (sub-phase B first-login): `showGettingStarted` collapses
        // to (!hasProperty || !hasCompletedAnyQuiz), so this view only ever
        // renders when the user is on Day 0 OR mid-onboarding without a
        // completed quiz. The Quiz hero is the singular CTA in that state —
        // the legacy "Upload your first document" / "Ask Alfred" branches
        // are now handled post-quiz by `VendorScheduleStrip` (which absorbs
        // Step 2) and the Alfred tab toolbar (which absorbs Step 3).
        if viewModel.hasProperty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(spacing: 8) {
                    Text("GETTING STARTED")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                }
                houseQuizHeroCardStack
            }
        } else {
            // Full getting started checklist (no property yet)
            HavenCard {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { gettingStartedExpanded.toggle() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(HavenColors.navy700)
                            Text("Getting Started")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)

                            let completed = [viewModel.hasProperty, viewModel.hasDocuments, viewModel.hasUsedAlfred].filter { $0 }.count
                            Text("\(completed)/3")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(HavenColors.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(HavenColors.beige200)
                                .clipShape(Capsule())

                            Spacer()

                            Image(systemName: gettingStartedExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if gettingStartedExpanded {
                        gettingStartedRow(step: 1, title: "Add your home", subtitle: "We'll set up maintenance tracking automatically", icon: "house.fill", done: viewModel.hasProperty, action: { showAddProperty = true })
                        gettingStartedRow(step: 2, title: "Upload your first document", subtitle: "A deed, insurance policy, or will. Alfred analyzes it instantly", icon: "doc.badge.plus", done: viewModel.hasDocuments, action: { showUploadDocument = true })
                        gettingStartedRow(step: 3, title: "Ask Alfred a question", subtitle: "Try \"What documents am I missing?\"", icon: "sparkles", done: viewModel.hasUsedAlfred, action: { NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 3]) })
                    } else {
                        gettingStartedRow(step: 1, title: "Add your home", subtitle: "We'll set up maintenance tracking automatically", icon: "house.fill", done: false, action: { showAddProperty = true })
                    }
                }
            }
        }
    }

    /// One House Quiz hero card per property that hasn't completed the quiz.
    /// Cards stack vertically; each property's progress is tracked independently.
    @ViewBuilder
    private var houseQuizHeroCardStack: some View {
        let incomplete = viewModel.properties.filter { property in
            (property.houseQuizState?.completedAt) == nil
        }
        ForEach(incomplete) { property in
            houseQuizHeroCard(for: property)
        }
    }

    private func houseQuizHeroCard(for property: PropertyRow) -> some View {
        let state = property.houseQuizState ?? HouseQuizState()
        let total = HouseQuizQuestionLibrary.allQuestions.count
        // Round 2 feedback (May 2026): saved-for-later questions live in
        // `state.answers` too, so `state.answers.count` includes them and
        // the label would read "28 of 28 done · 1 saved for later" with a
        // Continue Quiz CTA — mathematically contradictory. Subtract the
        // saved set so "done" only means "answered for real." Matches the
        // HouseQuizViewModel.progressLabel logic from Build 85.
        let saved = state.savedForLater.count
        let answered = max(0, state.answers.count - saved)
        let completion = total > 0 ? Double(answered) / Double(total) : 0
        let isResume = answered > 0 || saved > 0
        let title = "Start Quiz for \(property.name)"
        let progressLabel: String
        if isResume {
            if saved > 0 {
                progressLabel = "\(answered) of \(total) answered · \(saved) saved for later"
            } else {
                progressLabel = "\(answered) of \(total) answered"
            }
        } else {
            progressLabel = "\(total) quick questions, about 5 minutes."
        }

        return HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: 8) {
                    AlfredLogoView(size: 24)
                    Text(title)
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                }

                Text("Help us tailor your maintenance plan, systems, and recommendations to your home.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                Text(progressLabel)
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textTertiary)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HavenColors.beige200)
                        .frame(height: 6)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(HavenColors.action)
                            .frame(width: max(0, geo.size.width * completion), height: 6)
                    }
                    .frame(height: 6)
                }

                HavenButton(title: isResume ? "Continue Quiz" : "Start Quiz") {
                    activeQuizProperty = property
                }

                Button("Skip for now") {
                    showQuizSkipDialog = true
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)
                .frame(maxWidth: .infinity)
            }
            // Apr 7, 2026 (build 80): make the entire card body tappable,
            // not just the "Start Quiz" / "Continue Quiz" button. The
            // inner HavenButton and "Skip for now" Button still consume
            // their own taps (SwiftUI suppresses the outer tap gesture
            // when an inner Button receives it), so the explicit CTAs
            // keep their distinct touch targets — this just adds the
            // empty card space + title + progress bar as additional
            // tap surface.
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.light()
                activeQuizProperty = property
            }
        }
        .havenShadow()
    }

    // Phase 50 (sub-phase B first-login): `gettingStartedHeader` was used by
    // the legacy "Step 1/2/3" Quiz hero + Alfred prompt branches and the
    // expanded checklist. With the simplified two-state model (Quiz hero
    // when hasProperty, full checklist when !hasProperty) those branches
    // are gone, and the Quiz section header is now inline in
    // `gettingStartedCard`. The expanded checklist still has its own
    // header rendered inline below.

    private func gettingStartedRow(step: Int, title: String, subtitle: String, icon: String, done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.light()
            Analytics.track(.dashboardGettingStartedItemTapped, ["step": step, "title": title])
            action()
        }) {
            HStack(spacing: 12) {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.success)
                } else {
                    Text("\(step)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(HavenColors.navy800))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(done ? HavenColors.textTertiary : HavenColors.textPrimary)
                        .strikethrough(done)
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Spacer()

                if !done {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(done)
    }

    // MARK: - Expecting Card

    private func expectingCard(member: FamilyMemberRow) -> some View {
        let progress = viewModel.checklistProgress(for: member)
        let progressPct = progress.total > 0 ? Double(progress.completed) / Double(progress.total) : 0

        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                FamilyAvatarView(member: member, size: 48, showName: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preparing for \(member.firstName)")
                        .font(HavenTypography.title3)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let expectedDate = member.expectedDate {
                            let f = DateFormatter()
                            let _ = f.dateFormat = "yyyy-MM-dd"
                            if let date = f.date(from: expectedDate) {
                                let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                                if days > 0 {
                                    Text("\(days) days to go")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(Color.white.opacity(0.8))
                                } else if days == 0 {
                                    Text("Due today!")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(Color.white.opacity(0.9))
                                } else {
                                    Text("Born \(abs(days)) days ago")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(Color.white.opacity(0.8))
                                }
                            }
                        }

                        Text("\(progress.completed)/\(progress.total) ready")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }

                Spacer()

                // Mini progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: progressPct)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progressPct * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(HavenTheme.spacing16)
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        AvatarColor.rose.color,
                        AvatarColor.rose.color.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .offset(x: 50, y: -20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    // MARK: - Smart Recommendations

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("RECOMMENDED")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, rec in
                    Button {
                        Haptics.light()
                        Analytics.track(.dashboardRecommendationTapped, ["recommendation_id": rec.id, "title": rec.title])
                        handleRecommendationAction(rec.action)
                    } label: {
                        HStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: rec.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(rec.iconColor)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.title)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Text(rec.subtitle)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Button {
                                Haptics.light()
                                Analytics.track(.dashboardRecommendationDismissed, ["recommendation_id": rec.id])
                                withAnimation { viewModel.dismissRecommendation(rec.id) }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .padding(6)
                            }
                            .buttonStyle(.plain)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, HavenTheme.spacing12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < viewModel.recommendations.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                            .overlay(HavenColors.beige200)
                    }
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
    }

    // (Enrichment cards section removed — replaced by the House Quiz hero card.)

    // MARK: - Activity Tap Handler

    /// Dashboard noise audit (May 2026): tapping a Recent Activity row
    /// lands on the SPECIFIC entity's detail view, not the generic tab
    /// root. Each branch looks up the entity by `event.entityId` against
    /// the loaded view-model collections; if the lookup fails (entity
    /// archived, household swapped, etc.) we fall back to the closest
    /// focused destination rather than dumping the user on the tab.
    private func handleActivityTap(_ event: RecentActivityEvent) {
        switch event.eventType {
        case .taskCompleted:
            if let id = event.entityId,
               let task = viewModel.allUpcomingTasks.first(where: { $0.id == id })
                  ?? viewModel.overdueMaintenanceTasks.first(where: { $0.id == id })
                  ?? viewModel.recentlyCompletedTasks.first(where: { $0.id == id }) {
                selectedDashboardTask = task
            }
        case .documentProcessed, .invoiceProcessed:
            // Land on the specific document (or its parent inbox item
            // if we haven't loaded it). DocumentDetailView fetches its
            // own data from the document ID so we don't need the row.
            if let id = event.entityId {
                selectedActivityDocument = DashboardActivityDocumentRef(id: id)
            } else {
                navigationPath.append("inbox")
            }
        case .vendorLinked:
            if let id = event.entityId,
               let contractor = viewModel.dashboardContractors.first(where: { $0.id == id }) {
                selectedActivityContractor = contractor
            } else {
                // Fall back to the Contacts section of the property
                // tab — closer than the bare property landing.
                routeToPropertySection("contacts")
            }
        case .systemAdded:
            if let id = event.entityId,
               let system = viewModel.homeSystems.first(where: { $0.id == id }) {
                selectedActivitySystem = system
            } else {
                routeToPropertySection("overview")
            }
        case .propertyAdded:
            // Single-property households land directly on the property
            // detail when switchToTab fires (PropertyListView auto-
            // navigates). Multi-property households see the list and
            // pick — both better than nothing.
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
        case .projectCreated:
            // ProjectDetailView requires a ProjectsViewModel that lives
            // inside PropertyDetailView, so route to the Projects
            // section there instead of presenting the detail as a sheet.
            routeToPropertySection("projects")
        case .vehicleAdded:
            if let id = event.entityId {
                selectedActivityVehicle = DashboardActivityVehicleRef(id: id)
            } else {
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
            }
        case .familyMemberJoined:
            if let id = event.entityId,
               let member = viewModel.familyMembers.first(where: { $0.id == id }) {
                selectedMemberForProfile = member
            }
        case .inboxItemReceived:
            if let id = event.entityId {
                navigationPath.append("inbox_item_\(id.uuidString)")
            } else {
                navigationPath.append("inbox")
            }
        case .recallDetected:
            // Land on the specific vehicle so the recall is in context.
            if let id = event.entityId {
                selectedActivityVehicle = DashboardActivityVehicleRef(id: id)
            } else {
                navigationPath.append("vehicles")
            }
        case .scenarioRun:
            NotificationCenter.default.post(name: .openScenarioStudio, object: nil)
        case .gapAnalysisRun:
            // Gap analysis output IS the maintenance task list, so
            // landing on the Tasks tab is correct here.
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        }
    }

    /// Shared helper: switch to Property tab and tell PropertyDetailView
    /// which section to open. Mirrors the pattern in
    /// `handleRecommendationAction(.navigateToProperty)`.
    private func routeToPropertySection(_ section: String) {
        NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(
                name: .navigateToPropertySection,
                object: nil,
                userInfo: ["section": section]
            )
        }
    }

    private func handleRecommendationAction(_ action: RecommendationAction) {
        switch action {
        case .navigate(let tab):
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": tab])
        case .navigateToProperty(let section):
            // Switch to Property tab and tell PropertyDetailView which section to open
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .navigateToPropertySection, object: nil, userInfo: ["section": section])
            }
        case .addProperty:
            showAddProperty = true
        case .uploadDocument:
            showUploadDocument = true
        case .addVendor:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
        case .addFamilyMember:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        case .runGapAnalysis:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        case .setReminders:
            showSettings = true
        case .runScenario:
            showScenarioStudio = true
        case .openSettings:
            showSettings = true
        }
    }

    // MARK: - Phase 19l: Re-fire delegation sheet for new contractors

    /// Phase 84.5 — Homeowner switches from Chez-handles-it back to DIY.
    /// Cancels the in-flight assessment, releases assessment_mode, brings
    /// back the quiz card.
    private func cancelHomeAssessment() async {
        guard let assessment = viewModel.homeAssessment else { return }
        do {
            try await HavenSupabase.cancelHomeAssessment(
                assessmentId: assessment.id, reason: "homeowner_self_serve")
            Analytics.track(.homeAssessmentCancelled, [:])
            await viewModel.refresh()
            Haptics.success()
        } catch {
            print("[Dashboard] cancelHomeAssessment failed: \(error)")
            Haptics.error()
        }
    }

    /// Phase 95 (audit gap #9) — re-book a Chez handyman onboarding
    /// visit from the dashboard. Same Edge Function call as the
    /// onboarding fork, plus the local-notification scheduler that
    /// pairs with the SendGrid email backstop. After success,
    /// loadHomeAssessment refreshes the view model so
    /// HomeAssessmentPendingCard takes over the slot.
    private func rebookHomeAssessment(
        preferredWindowStart: String?,
        preferredTimeOfDay: String?
    ) async {
        guard let property = viewModel.properties.first else {
            Haptics.error()
            return
        }
        let householdId = property.householdId
        do {
            _ = try await HavenSupabase.requestHomeAssessment(
                propertyId: property.id.uuidString,
                householdId: householdId.uuidString,
                homeownerConcerns: nil,
                homeownerPresent: true,
                homeownerAccessNotes: nil,
                isExistingUserSupplement: false,
                preferredWindowStart: preferredWindowStart,
                preferredTimeOfDay: preferredTimeOfDay
            )
            Analytics.track(.homeAssessmentRequested, ["source": "dashboard_rebook"])
            NotificationScheduler.scheduleHomeAssessmentBookingConfirmation(
                preferredWindowStart: preferredWindowStart,
                preferredTimeOfDay: preferredTimeOfDay
            )
            await viewModel.refresh()
            Haptics.success()
        } catch {
            print("[Dashboard] rebookHomeAssessment failed: \(error)")
            Haptics.error()
        }
    }

    /// Compute delegation candidates filtered to a single newly-added
    /// contractor. Mirrors the post-quiz loader in HouseQuizView but only
    /// considers tasks whose system category matches the new vendor — that
    /// way the sheet only fires when there's actually something to delegate.
    private func loadDelegationCandidatesForContractor(_ contractorId: UUID) async {
        let db = DatabaseService.shared
        do {
            let contractors = try await db.fetchContractors()
            guard let contractor = contractors.first(where: { $0.id == contractorId }) else { return }

            // Walk every property the household owns so a contractor added
            // for one home gets considered against tasks on every home.
            let properties = try await db.fetchProperties()
            var matchingTasks: [MaintenanceTaskDBRow] = []

            for property in properties {
                let tasks = (try? await db.fetchMaintenanceTasks(propertyId: property.id)) ?? []
                let systems = (try? await db.fetchHomeSystems(propertyId: property.id)) ?? []
                let systemsById = Dictionary(uniqueKeysWithValues: systems.map { ($0.id, $0) })

                for task in tasks {
                    guard task.vehicleId == nil else { continue }
                    guard task.assignmentType?.lowercased() == "either" else { continue }
                    guard let systemId = task.systemId, let system = systemsById[systemId] else { continue }
                    let category = system.category.lowercased()
                    let matchesCategory = (contractor.category?.lowercased() == category)
                        || (contractor.specialties?.contains(where: { $0.lowercased() == category }) ?? false)
                    if matchesCategory {
                        matchingTasks.append(task)
                    }
                }
            }

            guard !matchingTasks.isEmpty else { return }

            await MainActor.run {
                self.dashboardDelegationCandidates = [
                    VendorDelegationCandidate(contractor: contractor, tasks: matchingTasks)
                ]
                // Brief delay so the contractor add sheet has time to dismiss
                // before the delegation sheet slides up over the dashboard.
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    showDashboardDelegationSheet = true
                }
            }
        } catch {
            print("[Phase19l] Failed to load delegation candidates for new contractor: \(error)")
        }
    }

    // MARK: - Merge Request Banner

    private func mergeRequestBanner(_ request: [String: Any]) -> some View {
        let requesterName = request["requester_name"] as? String ?? "Someone"
        let householdName = request["target_household_name"] as? String ?? "their household"
        let requestId = request["id"] as? String ?? ""

        return HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy700)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(requesterName) wants to share a household")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Join \"\(householdName)\" to share documents, properties, and maintenance.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await acceptMerge(requestId: requestId) }
                    } label: {
                        Text(isAcceptingMerge ? "Joining..." : "Accept & Join")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnNavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(HavenColors.navy)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .disabled(isAcceptingMerge)

                    Button {
                        Task { await declineMerge(requestId: requestId) }
                    } label: {
                        Text("Decline")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                }
            }
        }
    }

    private func acceptMerge(requestId: String) async {
        isAcceptingMerge = true
        do {
            let data = try await HavenSupabase.mergeHouseholds(
                action: "preview_merge",
                mergeRequestId: requestId
            )

            let decoder = JSONDecoder()
            let previewResponse = try decoder.decode(MergePreviewResponse.self, from: data)
            mergePreviewResponse = previewResponse
            showMergeResolution = true
        } catch {
            print("[Dashboard] Preview merge failed: \(error)")
            Haptics.error()
        }
        isAcceptingMerge = false
    }

    private func declineMerge(requestId: String) async {
        do {
            _ = try await HavenSupabase.mergeHouseholds(
                action: "decline_merge",
                mergeRequestId: requestId
            )
            pendingMergeRequest = nil
        } catch {
            print("[Dashboard] Decline failed: \(error)")
        }
    }

    // MARK: - Incomplete Address Banner

    private func incompleteAddressBanner(_ property: PropertyRow) -> some View {
        Button {
            Haptics.light()
            showAddressCompletion = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.warning)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Complete your address")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("\(property.name) needs a street address for property data and maintenance tracking.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.warning.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.warning.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAddressCompletion) {
            NavigationStack {
                AddressCompletionSheet(property: property, onComplete: {
                    Task { await viewModel.refresh() }
                })
            }
        }
    }

    // MARK: - Security Trust Badge

    private var securityBadge: some View {
        Button {
            Analytics.track(.dashboardSecurityTapped, ["source": "trust_badge"])
            navigationPath.append("security")
        } label: {
            HStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy700)

                Text("Your documents are encrypted and protected")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textSecondary)

                Spacer()

                Text("Learn more")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.navy500)
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.vertical, 12)
            .background(HavenColors.creamLight)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
