import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var vaultViewModel = DocumentVaultViewModel()
    @State private var showSettings = false
    @State private var showUploadDocument = false
    @State private var showAddProperty = false
    @State private var showSecurityDashboard = false
    @State private var navigationPath = NavigationPath()
    @State private var showScenarioStudio = false
    @State private var hasAppeared = false
    @State private var selectedDashboardTask: MaintenanceTaskDBRow?
    @AppStorage("hasSeenSecurityBadge") private var hasSeenSecurityBadge = false
    @State private var gettingStartedExpanded = false
    @State private var showServiceContractSheet = false
    @State private var serviceContractType: String = ""
    @State private var showApplianceSetup = false
    @State private var pendingMergeRequest: [String: Any]?
    @State private var showEstateIntake = false
    @State private var isAcceptingMerge = false
    @State private var showMergeResolution = false
    @State private var mergePreviewResponse: MergePreviewResponse?
    @State private var showQuickProjectEntry = false
    @State private var quickProjectPrefill: String = ""
    @AppStorage("hasSeenEmailCallout") private var hasSeenEmailCallout = false
    @State private var showFamilyMemberChooser = false
    @State private var familyMemberFormMode: AddFamilyMemberMode?
    @State private var selectedMemberForProfile: FamilyMemberRow?
    @State private var showAddressCompletion = false
    @State private var activeQuizProperty: PropertyRow?
    @State private var showQuizSkipDialog = false
    @AppStorage("hasSkippedHouseQuizForever") private var hasSkippedHouseQuizForever = false
    @AppStorage(PendingInviteKeys.needsPersonalQuiz) private var needsPersonalQuiz = false
    @State private var showPersonalQuiz = false

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
            ScrollView {
                VStack(spacing: HavenTheme.spacing16) {
                    // Page title — rendered in content for stability
                    screenTitle("Haven")

                    if viewModel.isLoading && !hasAppeared {
                        SkeletonScorecard()
                        SkeletonCard(lineCount: 2)
                        SkeletonCard(lineCount: 3)
                    } else {
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

                        // 1. Greeting
                        greetingView

                        // 2. Getting Started / Quiz hero — Day 0 focal point.
                        // Phase 50 (sub-phase B first-login): only renders
                        // when no property exists OR no property's quiz is
                        // complete. Once any quiz finishes, this disappears
                        // entirely and the YOUR HOME section below takes
                        // over as the primary CTA.
                        if viewModel.showGettingStarted {
                            gettingStartedCard
                        } else if !viewModel.recommendations.isEmpty {
                            recommendationsCard
                        }

                        // 2.5 Incomplete address banner
                        if let property = viewModel.propertyNeedsAddress {
                            incompleteAddressBanner(property)
                        }

                        // 2.6 Pending merge request banner
                        if let merge = pendingMergeRequest {
                            mergeRequestBanner(merge)
                        }

                        // 2.7 Phase 50 (sub-phase B first-login): YOUR HOME
                        // vendor schedule section. Gated on quiz completion
                        // so Day 0 stays focused on the Quiz CTA above.
                        // Post-quiz, this is the primary action surface and
                        // sits above the household strip — it absorbs the
                        // role of the old Getting Started Step 2 ("Upload
                        // your first document"). Once the user has at least
                        // one vendor visit, the empty state collapses and
                        // the horizontal scroll of `VendorVisitCard`s
                        // takes over.
                        if viewModel.hasCompletedAnyQuiz {
                            vendorScheduleSection
                        }

                        // 3. Household strip
                        HouseholdStrip(
                            members: viewModel.familyMembers,
                            currentUserName: viewModel.userFirstName,
                            onMemberTapped: { member in
                                selectedMemberForProfile = member
                            },
                            onAddTapped: {
                                showFamilyMemberChooser = true
                            },
                            onManageTapped: {
                                showSettings = true
                            }
                        )

                        // Build 87 — paid household staff strip. Hidden
                        // entirely when the household has no staff. The
                        // "+" button routes to the Settings → Household
                        // Staff add flow rather than the family chooser
                        // so the two entry points stay clearly separated.
                        if !viewModel.householdStaff.isEmpty {
                            HouseholdStaffStrip(
                                staff: viewModel.householdStaff,
                                onMemberTapped: { member in
                                    selectedMemberForProfile = member
                                },
                                onAddTapped: {
                                    showSettings = true
                                }
                            )
                        }

                        // 3.5 "Make it Yours" hero card for invitees who joined an
                        // existing household. Disappears once the personal quiz
                        // completes (or the user dismisses with "Not now").
                        if needsPersonalQuiz {
                            makeItYoursHeroCard
                        }

                        // 4. Expecting members
                        ForEach(viewModel.expectingMembers) { member in
                            NavigationLink(value: "expecting_\(member.id.uuidString)") {
                                expectingCard(member: member)
                            }
                            .buttonStyle(.plain)
                        }

                        // 5. Incoming items (inbox banners)
                        if !viewModel.inboxItems.isEmpty {
                            inboxSection
                        }

                        // Email forwarding callout
                        if !hasSeenEmailCallout {
                            emailForwardingCallout
                        }

                        // 7b. Estate Drip Card (Phase 48)
                        // Only shows after all house quizzes are complete.
                        // Empty state redirects to Life tab; stale/partial opens intake directly.
                        if viewModel.shouldShowEstateDripCard {
                            EstateIntakeDripCard(
                                estateState: viewModel.estateState,
                                onStart: {
                                    let hasStartedIntake = viewModel.estateState?.intakeState?.startedAt != nil
                                    let isStale = viewModel.estateState?.stalenessTier == "critical" || viewModel.estateState?.stalenessTier == "amber"
                                    if hasStartedIntake || isStale {
                                        // Stale or partial: open intake directly
                                        showEstateIntake = true
                                    } else {
                                        // Empty/first-time: navigate to Life tab
                                        NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
                                    }
                                },
                                onDismiss: { tier in viewModel.dismissEstateDrip(tier: tier) }
                            )
                        }

                        // (vendorScheduleSection moved above HouseholdStrip
                        // in Phase 50 sub-phase B first-login fixes — see
                        // section 2.7 above. The hasCompletedAnyQuiz gate
                        // lives there, so Day 0 stays focused on the Quiz
                        // CTA and the strip never renders mid-scroll.)

                        // 9. Unified "Needs Your Attention" list — hidden on
                        // Day 0 until any property's house quiz is complete.
                        if viewModel.hasCompletedAnyQuiz {
                            UnifiedAttentionList(
                                items: viewModel.unifiedAttentionItems,
                                onItemTapped: { item in
                                    if case .vehicleAlert = item.kind {
                                        navigationPath.append("vehicles")
                                    }
                                },
                                onSeeAll: {
                                    navigationPath.append("maintenance")
                                },
                                onDeleteTask: { task in
                                    Task {
                                        try? await DatabaseService.shared.deleteMaintenanceTask(id: task.id)
                                        Haptics.success()
                                        await viewModel.refresh()
                                    }
                                }
                            )
                        }

                        // (Standalone Upload button removed — uploads still
                        // reachable via the VendorScheduleStrip "Upload
                        // invoice" button and the email forwarding flow.)

                        // 11. Estate readiness (compact) — hidden on Day 0
                        // until any property's house quiz is complete.
                        if viewModel.hasCompletedAnyQuiz {
                            NavigationLink(value: "estate_readiness") {
                                compactEstateScorecard
                            }
                            .buttonStyle(.plain)
                        }

                        // 12. Scenario Planning (slim single-row) — hidden
                        // on Day 0. Scenarios are also folded into Alfred's
                        // toolbar so the AI surface area lives in one place.
                        if viewModel.hasCompletedAnyQuiz {
                            compactScenarioCard
                        }

                        // 13. Security trust badge — hidden on Day 0 to keep
                        // the empty-state dashboard focused on onboarding.
                        if !hasSeenSecurityBadge && viewModel.hasCompletedAnyQuiz {
                            securityBadge
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        hasSeenSecurityBadge = true
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption2)
                                            .foregroundStyle(HavenColors.textTertiary)
                                            .padding(8)
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.top, HavenTheme.spacing4)
                .padding(.bottom, 100)
            }
            .background(HavenColors.background)
            .navigationTitle("Haven")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear.frame(height: 0)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.light()
                        Analytics.track(.dashboardSecurityTapped)
                        navigationPath.append("security")
                    } label: {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy800)
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
                                    .foregroundStyle(HavenColors.navy800)

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
                                .foregroundStyle(HavenColors.navy800)
                        }
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Open app settings")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showUploadDocument) {
                DocumentUploadView(onComplete: {
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
                if destination == "inbox" {
                    InboxView()
                } else if destination == "security" {
                    SecurityDashboardView()
                } else if destination == "maintenance" {
                    MaintenanceScheduleView()
                } else if destination == "estate_readiness" {
                    ReadinessDetailView()
                        .environmentObject(vaultViewModel)
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
                } else if destination.hasPrefix("expecting_"),
                          let memberId = UUID(uuidString: String(destination.dropFirst("expecting_".count))),
                          let member = viewModel.expectingMembers.first(where: { $0.id == memberId }) {
                    NewArrivalChecklistView(member: member, documents: viewModel.allDocuments)
                } else {
                    EmptyView()
                }
            }
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
            .sheet(isPresented: $showFamilyMemberChooser) {
                AddFamilyMemberChooserSheet { mode in
                    familyMemberFormMode = mode
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $familyMemberFormMode) { mode in
                NavigationStack {
                    FamilyMemberFormView(initialMode: mode, onSave: {
                        Task { await viewModel.refresh() }
                    })
                }
            }
            .sheet(item: $selectedMemberForProfile) { member in
                NavigationStack {
                    FamilyMemberProfileView(member: member)
                }
                .presentationDetents([.large])
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
            .sheet(isPresented: $showEstateIntake) {
                if let hid = viewModel.primaryHouseholdId ?? viewModel.properties.first?.householdId {
                    EstateIntakeFormView(householdId: hid)
                }
            }
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
                await vaultViewModel.loadData()
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
                            if let item = viewModel.inboxItems.first(where: { $0.relatedDocumentId == documentId }) {
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
    }

    // MARK: - Greeting

    // MARK: - Inbox Section

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
                        .foregroundStyle(HavenColors.navy)
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
                        .foregroundStyle(HavenColors.navy800)
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

    /// Phase 50: Vendor schedule strip + cadence suggestion card. Pulled
    /// out of `body` so the dashboard's main scroll view stays under
    /// SwiftUI's expression type-check budget.
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
                    .foregroundStyle(HavenColors.navy)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("You have a forwarding email")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy800)
                    Text("Forward quotes, documents, school emails & more to Haven")
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
                            .foregroundStyle(HavenColors.navy800)
                        Text("Explore what-if questions with your real data — estate, taxes, home, wealth")
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
                        .foregroundStyle(HavenColors.navy)
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
                                .foregroundStyle(HavenColors.navy800)

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
                        gettingStartedRow(step: 2, title: "Upload your first document", subtitle: "A deed, insurance policy, or will — Alfred analyzes it instantly", icon: "doc.badge.plus", done: viewModel.hasDocuments, action: { showUploadDocument = true })
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
        let answered = state.answers.count
        let saved = state.savedForLater.count
        let completion = total > 0 ? Double(answered) / Double(total) : 0
        let isResume = answered > 0
        let title = "Start Quiz for \(property.name)"
        let progressLabel = isResume
            ? "\(answered) of \(total) done · \(saved) saved for later"
            : "30 quick questions, about 4 minutes."

        return HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: 8) {
                    AlfredLogoView(size: 24)
                    Text(title)
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.navy800)
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
                            .fill(HavenColors.navy800)
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

    // MARK: - Compact Estate Scorecard

    private var compactEstateScorecard: some View {
        let level = vaultViewModel.currentLevel
        let progress = vaultViewModel.levelProgress
        let levelColor: Color = level.id == 1 ? HavenColors.beige300 : level.color.color

        return HStack(spacing: 12) {
            Image(systemName: level.icon)
                .font(.system(size: 18))
                .foregroundStyle(levelColor)
                .frame(width: 36, height: 36)
                .background(levelColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(level.name)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textOnNavy)
                if let next = vaultViewModel.nextLevel {
                    Text("\(Int(progress * 100))% to \(next.name)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.beige300)
                } else {
                    Text("Max Level!")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.beige300)
                }
            }

            Spacer()

            // Compact progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(levelColor)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(width: 60, height: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.beige300)
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.vertical, 14)
        .background(HavenColors.navy)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    // MARK: - Compact Scenario Card

    private var compactScenarioCard: some View {
        Button {
            Haptics.light()
            Analytics.track(.scenarioStudioOpened, ["source": "dashboard_compact_card"])
            showScenarioStudio = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 32, height: 32)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Scenario Planning")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    if viewModel.documentCount < 3 {
                        Text("Upload more documents to unlock simulations")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    } else {
                        Text("Explore what-if questions with your real data")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.vertical, 12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige200, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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
