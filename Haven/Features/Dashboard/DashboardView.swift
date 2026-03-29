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
                        // Greeting
                        greetingView

                        // Inbox items from forwarded emails
                        if !viewModel.inboxItems.isEmpty {
                            inboxSection
                        }

                        // Email forwarding callout
                        if !hasSeenEmailCallout {
                            emailForwardingCallout
                        }

                        // Pending merge request banner
                        if let merge = pendingMergeRequest {
                            mergeRequestBanner(merge)
                        }

                        // Expecting members — preparation cards
                        ForEach(viewModel.expectingMembers) { member in
                            NavigationLink(value: "expecting_\(member.id.uuidString)") {
                                expectingCard(member: member)
                            }
                            .buttonStyle(.plain)
                        }

                        // Getting Started Guide — shows when user is new
                        if viewModel.showGettingStarted {
                            gettingStartedCard
                        } else if !viewModel.recommendations.isEmpty {
                            recommendationsCard
                        }

                        // Home profile enrichment cards
                        enrichmentCardsSection

                        // HOME MAINTENANCE — hero card, first priority
                        homeMaintenanceCard

                        // "What If?" Scenario Card — high visibility
                        whatIfCard

                        // REQUIRES ATTENTION — unified, max 3 items, all tappable
                        RequiresAttentionSection(
                            expirations: viewModel.upcomingExpirations,
                            upcomingTasks: viewModel.allUpcomingTasks
                        )

                        // Quick Actions
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

                        // ESTATE READINESS (uses shared vault view model for consistent levels)
                        NavigationLink(value: "estate_readiness") {
                            CompletionScorecard(vaultViewModel: vaultViewModel)
                        }
                        .buttonStyle(.plain)

                        // Security trust badge — dismissible
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
                } else if destination.hasPrefix("inbox_item_"),
                          let itemId = UUID(uuidString: String(destination.dropFirst("inbox_item_".count))),
                          let item = viewModel.inboxItems.first(where: { $0.id == itemId }) {
                    InboxItemDetailView(
                        item: item,
                        properties: viewModel.properties,
                        onProcess: { propertyId, action, category in
                            Task {
                                await viewModel.processInboxItem(item, propertyId: propertyId, action: action, category: category)
                            }
                        },
                        onDismiss: {
                            viewModel.dismissInboxItem(item)
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
                    onComplete: {
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
            .fullScreenCover(isPresented: $showScenarioStudio) {
                ScenarioStudioView()
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
                HStack(spacing: HavenTheme.spacing24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROPERTY")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Color.white.opacity(0.35))

                        Text("TO DO")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(Color.white.opacity(0.7))

                        if viewModel.overdueMaintenanceTasks.isEmpty && viewModel.allUpcomingTasks.isEmpty {
                            Text("All caught up!")
                                .font(Font.custom("Georgia-Bold", size: 20))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else if !viewModel.overdueMaintenanceTasks.isEmpty {
                            Text("\(viewModel.overdueMaintenanceTasks.count) overdue")
                                .font(Font.custom("Georgia-Bold", size: 20))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text("\(viewModel.allUpcomingTasks.count) upcoming")
                                .font(Font.custom("Georgia-Bold", size: 20))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        maintenanceHeroPill(
                            count: viewModel.overdueMaintenanceTasks.count,
                            label: "Overdue",
                            color: viewModel.overdueMaintenanceTasks.count > 0 ? Color.red.opacity(0.9) : Color.white.opacity(0.2)
                        )
                        maintenanceHeroPill(
                            count: viewModel.dueThisMonthTasks.count,
                            label: "This Month",
                            color: Color.white.opacity(0.2)
                        )
                    }
                }

                if let next = viewModel.nextUpcomingTask {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.6))
                        Text("Next: \(next.title)")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(Color.white.opacity(0.8))
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
                    // House silhouette — branded property motif
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

    // MARK: - Getting Started

    private var gettingStartedCard: some View {
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
                    if !viewModel.hasProperty {
                        gettingStartedRow(step: 1, title: "Add your home", subtitle: "We'll set up maintenance tracking automatically", icon: "house.fill", done: false, action: { showAddProperty = true })
                    } else if !viewModel.hasDocuments {
                        gettingStartedRow(step: 2, title: "Upload your first document", subtitle: "A deed, insurance policy, or will — Alfred analyzes it instantly", icon: "doc.badge.plus", done: false, action: { showUploadDocument = true })
                    } else if !viewModel.hasUsedAlfred {
                        gettingStartedRow(step: 3, title: "Ask Alfred a question", subtitle: "Try \"What documents am I missing?\"", icon: "sparkles", done: false, action: { NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 3]) })
                    }
                }
            }
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

    // MARK: - Enrichment Cards

    @ViewBuilder
    private var enrichmentCardsSection: some View {
        let questions = viewModel.enrichmentQuestions
        if !questions.isEmpty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("TELL US MORE")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                ForEach(questions) { question in
                    EnrichmentCardView(
                        question: question,
                        onAnswer: { answer in
                            handleEnrichmentAnswer(questionId: question.id, answer: answer, attributeKey: question.attributeKey)
                        },
                        onDismiss: {
                            viewModel.dismissEnrichmentCard(question.id)
                        },
                        onServiceSetup: { serviceType in
                            Analytics.track(.dashboardEnrichmentCardTapped, ["card_id": question.id, "action": "service_setup", "service_type": serviceType])
                            serviceContractType = serviceType
                            showServiceContractSheet = true
                        },
                        onApplianceSetup: {
                            Analytics.track(.dashboardEnrichmentCardTapped, ["card_id": question.id, "action": "appliance_setup"])
                            showApplianceSetup = true
                        },
                        onProjectExplore: { title in
                            quickProjectPrefill = title
                            showQuickProjectEntry = true
                        }
                    )
                }
            }
        }
    }

    private func handleEnrichmentAnswer(questionId: String, answer: String, attributeKey: String?) {
        Analytics.track(.dashboardEnrichmentCardSubmitted, ["question_id": questionId, "answer": answer])
        guard let propertyId = viewModel.primaryPropertyId else { return }
        let key = attributeKey ?? questionId

        // "not_sure" and "none" values still get saved so the question doesn't reappear
        let value: FlexibleValue = (answer == "true" || answer == "false")
            ? .bool(answer == "true")
            : .string(answer)

        Task {
            do {
                _ = try await DatabaseService.shared.updatePropertyAttribute(
                    propertyId: propertyId,
                    key: key,
                    value: value
                )
                // Apply post-answer maintenance adjustments
                await EnrichmentActions.applyEnrichment(
                    questionId: questionId,
                    answer: answer,
                    propertyId: propertyId,
                    householdId: viewModel.primaryHouseholdId ?? propertyId,
                    homeSystems: viewModel.homeSystems
                )
                // Delay refresh so card dismiss animation completes before view recreation
                try? await Task.sleep(for: .seconds(0.5))
                await viewModel.refresh()
            } catch {
                print("[Enrichment] Failed to save \(key): \(error)")
            }
        }
    }

    private func handleRecommendationAction(_ action: RecommendationAction) {
        switch action {
        case .navigate(let tab):
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": tab])
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
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
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
