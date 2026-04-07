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
    @State private var isAcceptingMerge = false
    @State private var showMergeResolution = false
    @State private var mergePreviewResponse: MergePreviewResponse?
    @State private var showQuickProjectEntry = false
    @State private var quickProjectPrefill: String = ""
    @AppStorage("hasSeenEmailCallout") private var hasSeenEmailCallout = false
    @State private var showFamilyMemberForm = false
    @State private var selectedMemberForProfile: FamilyMemberRow?
    @State private var showAddressCompletion = false
    @State private var activeQuizProperty: PropertyRow?
    @State private var showQuizSkipDialog = false
    @AppStorage("hasSkippedHouseQuizForever") private var hasSkippedHouseQuizForever = false
    @AppStorage(PendingInviteKeys.needsPersonalQuiz) private var needsPersonalQuiz = false
    @State private var showPersonalQuiz = false

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
                        // 1. Greeting
                        greetingView

                        // 1.5 Incomplete address banner
                        if let property = viewModel.propertyNeedsAddress {
                            incompleteAddressBanner(property)
                        }

                        // 2. Pending merge request banner
                        if let merge = pendingMergeRequest {
                            mergeRequestBanner(merge)
                        }

                        // 3. Household strip
                        HouseholdStrip(
                            members: viewModel.familyMembers,
                            currentUserName: viewModel.userFirstName,
                            onMemberTapped: { member in
                                selectedMemberForProfile = member
                            },
                            onAddTapped: {
                                showFamilyMemberForm = true
                            },
                            onManageTapped: {
                                showSettings = true
                            }
                        )

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

                        // 6. Getting Started OR Recommendations
                        if viewModel.showGettingStarted {
                            gettingStartedCard
                        } else if !viewModel.recommendations.isEmpty {
                            recommendationsCard
                        }

                        // 7. (House Quiz hero card replaces the legacy "Tell Us More" enrichment cards.)

                        // 8. HOME MAINTENANCE hero card
                        homeMaintenanceCard

                        // 9. Unified "Needs Your Attention" list
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

                        // 10. Quick Actions
                        QuickActions(
                            onUploadDocument: { showUploadDocument = true },
                            onAddProperty: { showAddProperty = true },
                            onAskAI: {
                                showScenarioStudio = true
                            },
                            onViewOverdue: {
                                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                            },
                            onViewMaintenance: {
                                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                            },
                            overdueCount: viewModel.overdueMaintenanceTasks.count,
                            hasProperty: viewModel.hasProperty
                        )

                        // 11. Estate readiness (compact)
                        NavigationLink(value: "estate_readiness") {
                            compactEstateScorecard
                        }
                        .buttonStyle(.plain)

                        // 12. Scenario Planning (slim single-row)
                        compactScenarioCard

                        // 13. Security trust badge
                        if !hasSeenSecurityBadge {
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
                        Menu {
                            Button {
                                Haptics.light()
                                showUploadDocument = true
                            } label: {
                                Label("Upload Document", systemImage: "doc.badge.plus")
                            }
                            Button {
                                Haptics.light()
                                navigationPath.append("maintenance")
                            } label: {
                                Label("View Tasks", systemImage: "checklist")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(HavenColors.navy800)
                        }

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
                AddPropertyView(onComplete: {
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
            .sheet(isPresented: $showFamilyMemberForm) {
                NavigationStack {
                    FamilyMemberFormView(onSave: {
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
            }
            .onReceive(NotificationCenter.default.publisher(for: .popToRoot)) { notification in
                if let tab = notification.userInfo?["tab"] as? Int, tab == 0 {
                    navigationPath = NavigationPath()
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

    // MARK: - Home Maintenance Card

    private var homeMaintenanceCard: some View {
        NavigationLink(value: "maintenance") {
            VStack(spacing: HavenTheme.spacing16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOUR HOME")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Color.white.opacity(0.35))

                        if viewModel.overdueMaintenanceTasks.isEmpty && viewModel.allUpcomingTasks.isEmpty {
                            Text("All caught up!")
                                .font(Font.custom("Georgia-Bold", size: 20))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text("\(viewModel.dueThisMonthTasks.count) tasks this month")
                                .font(Font.custom("Georgia-Bold", size: 20))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        // Only show overdue pill when count > 0
                        if viewModel.overdueMaintenanceTasks.count > 0 {
                            maintenanceHeroPill(
                                count: viewModel.overdueMaintenanceTasks.count,
                                label: "Overdue",
                                color: Color.red.opacity(0.9)
                            )
                        }
                        // Total count as subtle pill
                        let totalCount = viewModel.allUpcomingTasks.count + viewModel.overdueMaintenanceTasks.count
                        if totalCount > 0 {
                            maintenanceHeroPill(
                                count: totalCount,
                                label: "Total",
                                color: Color.white.opacity(0.2)
                            )
                        }
                    }
                }

                if let next = viewModel.nextUpcomingTask {
                    Button {
                        selectedDashboardTask = next
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.6))
                            Text("Next: \(next.title.summarized(maxLength: 40))")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(Color.white.opacity(0.8))
                                .lineLimit(1)
                            Spacer()
                            HStack(spacing: 4) {
                                Text(next.nextDueDate.havenDateShort)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(Color.white.opacity(0.6))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.5))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(HavenTheme.spacing20)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.28, green: 0.42, blue: 0.35),
                            Color(red: 0.22, green: 0.35, blue: 0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "house.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 130, height: 130)
                        .foregroundStyle(Color.white.opacity(0.08))
                        .offset(x: 40, y: 15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        }
        .buttonStyle(.plain)
    }

    private func maintenanceHeroPill(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                            .font(Font.custom("Georgia-Bold", size: 18))
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
        if viewModel.hasProperty && !viewModel.hasDocuments {
            // House Quiz hero (replaces the old Alfred Scan-Will prompt) — one
            // card per property that hasn't completed the quiz yet.
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                gettingStartedHeader(completed: 1)
                houseQuizHeroCardStack
            }
        } else if viewModel.hasProperty && viewModel.hasDocuments && !viewModel.hasUsedAlfred {
            // Only Alfred left — simple nudge
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                gettingStartedHeader(completed: 2)
                HavenCard {
                    VStack(alignment: .leading, spacing: 12) {
                        gettingStartedRow(step: 3, title: "Ask Alfred a question", subtitle: "Try \"What documents am I missing?\"", icon: "sparkles", done: false, action: { NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 3]) })
                    }
                }
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
                                .font(Font.custom("Georgia-Bold", size: 15))
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
        }
        .havenShadow()
    }

    private func gettingStartedHeader(completed: Int) -> some View {
        HStack(spacing: 8) {
            Text("GETTING STARTED")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            Text("\(completed)/3")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(HavenColors.beige200)
                .clipShape(Capsule())
            Spacer()
        }
    }

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
                        .font(Font.custom("Georgia-Bold", size: 16))
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
