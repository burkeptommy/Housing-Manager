import SwiftUI

enum PropertyDetailTab: String, CaseIterable {
    case overview
    case maintenance
    case projects
    case contacts

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .maintenance: return "Maintenance"
        case .projects: return "Projects"
        case .contacts: return "Contacts"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .maintenance: return "calendar.badge.clock"
        case .projects: return "hammer.fill"
        case .contacts: return "person.2.fill"
        }
    }
}

/// Phase 56.1: Filter options for the Contacts sub-tab. Lives at the
/// top level so it stays stable across SwiftUI redraws and so the
/// picker chips can iterate `.allCases`.
enum ContactsFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case serviceBased = "Service-based"
    case routine = "Routines"
    case estate = "Estate professionals"
    case needsAttention = "Needs attention"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "person.2.fill"
        case .serviceBased: return "wrench.and.screwdriver.fill"
        case .routine: return "calendar.badge.clock"
        case .estate: return "building.columns.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        }
    }
}

struct PropertyDetailView: View {
    let propertyID: UUID
    @StateObject private var viewModel = PropertyDetailViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var activeTab: PropertyDetailTab = .maintenance
    @State private var showAddSystem = false
    @State private var showEditProperty = false
    @State private var showDeleteConfirmation = false
    @State private var showDocumentUpload = false
    @State private var showFullSchedule = false
    @State private var showAlfredChat = false
    @State private var selectedTaskForReminder: MaintenanceTaskDBRow?
    @State private var showReminderPicker = false
    @State private var showVendorAssignment = false
    @State private var seasonalFindVendorTask: MaintenanceTaskDBRow?
    @State private var selectedTaskForVendor: MaintenanceTaskDBRow?
    @State private var taskForDateEdit: MaintenanceTaskDBRow?
    @State private var taskForLastServiced: MaintenanceTaskDBRow?
    @State private var editedTaskDueDate = Date()
    @State private var selectedMaintenanceTask: MaintenanceTaskDBRow?
    @AppStorage("dismissedSeasonalOverview") private var dismissedSeasonalOverview = ""
    @State private var showSeasonCompletionBanner = false
    @State private var completedSeasonForNavigation: SeasonCompletionState?
    @State private var lastServicedTaskDate = Date()

    /// Phase 54B.3: Handyman punch-list row state. Count is loaded on
    /// appear + on `.maintenanceTaskChanged` notifications so the badge
    /// stays in sync when items are added from the task detail sheet
    /// or from the punch list itself.
    @State private var handymanPunchCount: Int = 0
    @State private var showHandymanPunchList = false

    /// Phase 54C.3: "Recommended for your home" entry-point state.
    @State private var showRecommendedServices = false

    /// Phase 55.3: Routines row state. Count loaded on appear so the
    /// row badge stays in sync. Bootstrap entry point — without this
    /// row, users have no way to reach RoutinesListView and create
    /// their first routine (the dashboard banner only surfaces
    /// already-configured routines). Retains the legacy variable names
    /// since the row is nested deep in PropertyDetailView and every
    /// call site already uses these names — internal naming only.
    @State private var weeklyCadenceCount: Int = 0
    @State private var showWeeklyCadences = false

    /// Phase 56.1: Direct presentation of AddVendorSheet from the
    /// Contacts sub-tab. Replaces the navigation-to-ContractorDirectoryView
    /// pattern that required two extra taps to reach the add form.
    @State private var showAddVendor = false

    /// Phase 56.1: Picker-mode presentation of ContractorDirectoryView
    /// from the task action menu's "Assign a Vendor" option. Keeps the
    /// directory view's picker behavior alive while killing standalone
    /// destinations of it.
    @State private var vendorAssignmentTask: MaintenanceTaskDBRow?

    /// Phase 56.1: BrowseSpecialtySystemsSheet presentation from the
    /// Contacts sub-tab "Add or discover" section. Distinct from
    /// `showAddSystem` (the freeform custom-system flow) because the
    /// two serve different discovery intents.
    @State private var showBrowseSpecialty = false

    /// Phase 56.1: Search + filter state for the Contacts sub-tab. Lives
    /// on the parent view so it persists across redraws but doesn't
    /// leak into other sub-tabs. Resets naturally on tab change because
    /// Contacts is re-rendered from scratch each time it's selected.
    @State private var contactsSearchText: String = ""
    @State private var contactsFilter: ContactsFilter = .all

    /// Phase 56.1: Contractor IDs the user has dismissed from the
    /// "Needs attention" filter (e.g. they don't care that Orkin has
    /// no email, or this landscaper never gave them a phone). Persisted
    /// in UserDefaults so dismissals survive relaunch. Per-household
    /// key so switching households doesn't leak dismissals across.
    @State private var attentionDismissedIds: Set<UUID> = []

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.property == nil {
                ProgressView("Loading property...")
            } else if let property = viewModel.property {
                propertyContent(property)
            } else {
                ContentUnavailableView("Property not found", systemImage: "house")
            }
        }
        .navigationTitle(viewModel.property?.name ?? "Property")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Analytics.track(.propertyEdited, ["property_id": propertyID.uuidString, "source": "menu"])
                        showEditProperty = true
                    } label: {
                        Label("Edit Property", systemImage: "pencil")
                    }
                    Button {
                        Analytics.track(.systemCreated, ["property_id": propertyID.uuidString, "source": "menu"])
                        showAddSystem = true
                    } label: {
                        Label("Add System", systemImage: "plus.circle.fill")
                    }
                    Divider()
                    Button(role: .destructive) {
                        Analytics.track(.propertyDeleted, ["property_id": propertyID.uuidString])
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Property", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .trackScreen("PropertyDetailView", properties: ["property_id": propertyID.uuidString])
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPropertySection)) { notification in
            if let section = notification.userInfo?["section"] as? String {
                withAnimation {
                    switch section {
                    case "overview": activeTab = .overview
                    case "maintenance": activeTab = .maintenance
                    case "projects": activeTab = .projects
                    case "contacts": activeTab = .contacts
                    case "handyman_punch_list":
                        // Phase 56.4: "Schedule handyman visit" entry
                        // points (dashboard card, Maintenance "+" menu,
                        // Maintenance tab HandymanSuggestionCard) route
                        // here. Land on the maintenance tab and push
                        // the punch list destination.
                        activeTab = .maintenance
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showHandymanPunchList = true
                        }
                    default: break
                    }
                }
            }
        }
        .task {
            await viewModel.loadProperty(id: propertyID)
            loadAttentionDismissals()
            checkSeasonCompletionBanner()
        }
        .onChange(of: viewModel.property?.householdId) { _, _ in
            // Phase 56.1: refresh dismissals when household resolves
            // (loadProperty is async; the first render may run before
            // the household id is known).
            loadAttentionDismissals()
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task {
                await viewModel.loadProperty(id: propertyID)
                checkSeasonCompletionBanner()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .contractorChanged)) { _ in
            Task {
                await viewModel.loadProperty(id: propertyID)
                checkSeasonCompletionBanner()
            }
        }
        .onChange(of: viewModel.seasonCompletionState) { _, newState in
            if newState.isComplete && newState.totalVendorTasks > 0 {
                // First time this season completed — record the timestamp
                SeasonCompletionBannerState.recordCompletion(newState)
                if SeasonCompletionBannerState.shouldShow(newState) {
                    withAnimation(HavenTheme.animationCard) {
                        showSeasonCompletionBanner = true
                    }
                    Haptics.success()
                }
            } else {
                // Season is no longer complete (vendor unassigned?)
                withAnimation(HavenTheme.animationCard) {
                    showSeasonCompletionBanner = false
                }
            }
        }
        .navigationDestination(item: $completedSeasonForNavigation) { state in
            SeasonalTasksDetailView(
                season: state.season.displayName,
                tasks: viewModel.currentSeasonTasks,
                completedCount: state.assignedVendorTasks,
                nextSeason: viewModel.nextSeason,
                nextSeasonTasks: viewModel.nextSeasonTasks,
                systemNameLookup: { viewModel.systemName(for: $0) },
                contractorNameLookup: { viewModel.contractor(for: $0)?.companyName },
                onFindVendor: { task in seasonalFindVendorTask = task },
                propertyId: propertyID
            )
        }
        .onAppear {
            // Refresh when returning from detail views so edits reflect immediately
            if viewModel.property != nil {
                Task {
                    await viewModel.loadProperty(id: propertyID)
                    checkSeasonCompletionBanner()
                }
            }
        }
        .refreshable {
            Analytics.track(.propertyRefreshed, ["property_id": propertyID.uuidString])
            await viewModel.loadProperty(id: propertyID)
        }
        .sheet(isPresented: $showEditProperty) {
            if let property = viewModel.property {
                EditPropertyView(property: property) { updatedProperty in
                    viewModel.property = updatedProperty
                    NotificationCenter.default.post(name: .propertyChanged, object: nil,
                        userInfo: ["action": "updated", "id": propertyID.uuidString])
                    Task { await viewModel.loadProperty(id: propertyID) }
                }
            }
        }
        .sheet(isPresented: $showDocumentUpload) {
            DocumentUploadView(preselectedPropertyId: propertyID) {
                Task { await viewModel.loadProperty(id: propertyID) }
            }
        }
        .sheet(isPresented: $showAddSystem) {
            AddSystemView(propertyID: propertyID, onComplete: { newSystem in
                viewModel.systems.append(newSystem)
                Task { await viewModel.loadProperty(id: propertyID) }
            })
        }
        .sheet(isPresented: $showAlfredChat) {
            NavigationStack {
                ChatView(contextType: "property", contextId: propertyID)
            }
        }
        .sheet(isPresented: $showReminderPicker) {
            reminderSheet
        }
        .sheet(item: $taskForDateEdit) { task in
            NavigationStack {
                VStack(spacing: 16) {
                    Text("When is \(task.title) actually due?")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)

                    DatePicker("Due Date", selection: $editedTaskDueDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(HavenColors.navy)

                    Spacer()
                }
                .padding()
                .navigationTitle("Edit Due Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { taskForDateEdit = nil }
                            .foregroundStyle(HavenColors.navy)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                let f = DateFormatter()
                                f.dateFormat = "yyyy-MM-dd"
                                _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                    id: task.id,
                                    MaintenanceTaskUpdate(nextDueDate: f.string(from: editedTaskDueDate))
                                )
                                Task { await NotificationScheduler.shared.rescheduleAll() }
                                Haptics.success()
                                taskForDateEdit = nil
                                await viewModel.loadProperty(id: propertyID)
                            }
                        }
                        .foregroundStyle(HavenColors.navy)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $taskForLastServiced) { task in
            NavigationStack {
                VStack(spacing: 16) {
                    Text("When did you last do \(task.title)?")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("Haven will recalculate the next due date based on the task frequency (\(task.frequency)).")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .multilineTextAlignment(.center)

                    // Build 86: no date-range constraint. Users can backdate
                    // a completion to any past date (the day they actually
                    // did the work) or log a future date for scheduled work.
                    DatePicker("Date Completed", selection: $lastServicedTaskDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(HavenColors.navy)

                    Spacer()
                }
                .padding()
                .navigationTitle("Log Past Service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { taskForLastServiced = nil }
                            .foregroundStyle(HavenColors.navy)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                let f = DateFormatter()
                                f.dateFormat = "yyyy-MM-dd"
                                let completedStr = f.string(from: lastServicedTaskDate)
                                let nextDate = MaintenanceTaskDetailSheet.calculateNextDue(frequency: task.frequency, from: lastServicedTaskDate)
                                let nextDueStr = f.string(from: nextDate)

                                _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                    id: task.id,
                                    MaintenanceTaskUpdate(lastCompletedDate: completedStr, nextDueDate: nextDueStr)
                                )
                                if let systemId = task.systemId {
                                    _ = try? await DatabaseService.shared.updateHomeSystem(
                                        id: systemId,
                                        HomeSystemUpdate(lastServiceDate: completedStr, nextServiceDue: nextDueStr)
                                    )
                                }
                                Task { await NotificationScheduler.shared.rescheduleAll() }
                                Haptics.success()
                                taskForLastServiced = nil
                                await viewModel.loadProperty(id: propertyID)
                            }
                        }
                        .foregroundStyle(HavenColors.navy)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(isPresented: $showFullSchedule) {
            // Phase 66: the property-scoped Maintenance tab lands on the
            // new 5-section hub. Timeline is available via the "See full
            // year ↗" link inside the hub.
            MaintenanceHubView(filterPropertyId: propertyID)
        }
        .sheet(item: $selectedMaintenanceTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(task: task, onTaskCompleted: {
                    Task { await viewModel.loadProperty(id: propertyID) }
                })
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $seasonalFindVendorTask) { task in
            seasonalFindVendorContent(task: task)
        }
        .sheet(isPresented: $showAddVendor) {
            AddVendorSheet(onComplete: {
                Task { await viewModel.loadProperty(id: propertyID) }
            })
        }
        .sheet(item: $vendorAssignmentTask) { task in
            NavigationStack {
                ContractorDirectoryView(onSelect: { contractor in
                    Task {
                        await MaintenanceViewModel.shared.convertToVendorManaged(
                            taskId: task.id,
                            contractor: contractor
                        )
                        await viewModel.loadProperty(id: propertyID)
                        vendorAssignmentTask = nil
                    }
                })
            }
        }
        .sheet(isPresented: $showBrowseSpecialty) {
            // Phase 56.1: body-scope sheet so the "Browse specialty
            // systems" row on the Contacts tab works. The Maintenance
            // tab's own entry points reuse this same state.
            if let property = viewModel.property {
                BrowseSpecialtySystemsSheet(
                    propertyId: property.id,
                    householdId: property.householdId,
                    existingCategories: Set(viewModel.systems.map(\.category)),
                    onSystemAdded: {
                        Task { await viewModel.loadProperty(id: propertyID) }
                    }
                )
            }
        }
        .navigationDestination(isPresented: $showWeeklyCadences) {
            // Phase 56.1: hoisted from weeklyCadencesRow so the
            // Contacts tab's "Add a routine" discovery row can route
            // here too. The Maintenance tab's row view no longer
            // needs its own nav destination.
            if let householdId = viewModel.property?.householdId {
                RoutinesListView(
                    householdId: householdId,
                    propertyId: propertyID
                )
            }
        }
        .navigationDestination(isPresented: $showRecommendedServices) {
            // Phase 56.1: hoisted from recommendedServicesRow so the
            // Contacts tab's "See recommended services" discovery row
            // can route here too.
            if let householdId = viewModel.property?.householdId {
                RecommendedServicesView(
                    householdId: householdId,
                    propertyId: propertyID
                )
            }
        }
        .confirmationDialog("Delete Property?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await DatabaseService.shared.deleteProperty(id: propertyID)
                        Haptics.success()
                        dismiss()
                    } catch {
                        viewModel.error = "Failed to delete property: \(error.localizedDescription)"
                        Haptics.error()
                    }
                }
            }
        } message: {
            Text("This will delete the property and all associated systems, maintenance tasks, and service records.")
        }
    }

    // MARK: - Main Content

    @State private var heroIsVisible = true

    private func propertyContent(_ property: PropertyRow) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                propertyHeader(property)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .named("propertyScroll")).maxY) { _, newValue in
                                    let shouldShow = newValue > 60
                                    if heroIsVisible != shouldShow {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            heroIsVisible = shouldShow
                                        }
                                    }
                                }
                        }
                    )

                Section {
                    switch activeTab {
                    case .overview:
                    if let prop = viewModel.property {
                        InvestmentSummaryCard(
                            property: prop,
                            totalProjectSpend: viewModel.totalProjectSpend,
                            onValuesUpdated: { update in
                                await viewModel.applyPropertyUpdate(update)
                            },
                            onRefreshFromPublicRecords: {
                                await viewModel.refreshFromPublicRecords(appState: appState)
                            }
                        )
                    }
                    UtilityAccountsSection(
                        propertyId: property.id,
                        householdId: property.householdId,
                        accounts: $viewModel.utilityAccounts
                    )
                    propertyDocumentsSection
                    propertyMaintenanceCard
                    if !viewModel.serviceRecords.isEmpty { recentServiceHistoryCard }
                    if !viewModel.activeWarranties.isEmpty { warrantiesSection }

                case .maintenance:
                    // Build 90: Simplified layout. Lead with a compact
                    // maintenance summary card that links to the full
                    // schedule, then overdue, then DIY tasks, then
                    // systems, seasonal, and history.
                    maintenanceSummaryCard
                    if !viewModel.overdueTasks.isEmpty { overdueSection }
                    diyTasksSection
                    if !viewModel.vendorFollowUpTasks.isEmpty { vendorFollowUpsSection }
                    handymanPunchListRow
                    weeklyCadencesRow
                    recommendedServicesRow
                    systemsSection

                    // Season completion banner + overview card
                    if showSeasonCompletionBanner {
                        SeasonCompletionBanner(
                            season: viewModel.seasonCompletionState.season,
                            year: viewModel.seasonCompletionState.year,
                            vendorCount: viewModel.seasonCompletionState.vendorCount,
                            onSeeSummary: {
                                completedSeasonForNavigation = viewModel.seasonCompletionState
                            },
                            onDismiss: {
                                SeasonCompletionBannerState.dismiss(viewModel.seasonCompletionState)
                                withAnimation(HavenTheme.animationCard) {
                                    showSeasonCompletionBanner = false
                                }
                                Haptics.light()
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if (!viewModel.currentSeasonTasks.isEmpty || !viewModel.nextSeasonTasks.isEmpty),
                       !viewModel.seasonCompletionState.isComplete,
                       dismissedSeasonalOverview != "\(viewModel.currentSeason) \(Calendar.current.component(.year, from: Date()))" {
                        seasonalOverviewCard
                    }
                    if !viewModel.serviceRecords.isEmpty { serviceHistorySection }

                case .projects:
                    PropertyProjectsView(
                        propertyID: propertyID,
                        householdId: viewModel.property?.householdId,
                        propertyLocation: [viewModel.property?.city, viewModel.property?.state].compactMap { $0 }.joined(separator: ", ")
                    )

                case .contacts:
                    vendorsSection
                    if !viewModel.serviceRecords.isEmpty { serviceHistorySection }
                    }
                } header: {
                    VStack(spacing: 0) {
                        // Collapsed header bar — appears when full hero scrolls away
                        if !heroIsVisible {
                            HStack(spacing: 8) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(HavenColors.navy)
                                Text(property.street ?? property.name)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                if let value = property.currentEstimatedValue, value > 0 {
                                    Text(value.formattedCompactCurrency())
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                }
                            }
                            .padding(.horizontal, HavenTheme.spacing16)
                            .padding(.vertical, HavenTheme.spacing8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Tab selector — always visible, pins on scroll
                        HStack(spacing: 0) {
                            ForEach(PropertyDetailTab.allCases, id: \.self) { tab in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        activeTab = tab
                                    }
                                    Analytics.track(.propertyTabSelected, ["tab": tab.title, "property_id": propertyID.uuidString])
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: tab.icon)
                                            .font(.system(size: 16))
                                            .symbolRenderingMode(.hierarchical)
                                        Text(tab.title)
                                            .font(HavenTypography.uiCaption)
                                    }
                                    .foregroundStyle(activeTab == tab ? HavenColors.navy800 : HavenColors.textTertiary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        activeTab == tab
                                            ? HavenColors.navy.opacity(0.08)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .background(HavenColors.background)
                }
            }
            .padding()
        }
        .coordinateSpace(name: "propertyScroll")
        .background(HavenColors.background)
    }

    // MARK: - Header

    private func propertyHeader(_ property: PropertyRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.name)
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(property.propertyType)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "house.fill")
                        .font(.title)
                        .foregroundStyle(HavenColors.navy)
                }

                if let street = property.street {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(street)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        if let city = property.city, let state = property.state {
                            Text("\(city), \(state) \(property.zipCode ?? "")")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }

                HStack(spacing: 20) {
                    if let sqft = property.squareFootage {
                        propertyDetail(label: "Sq Ft", value: "\(sqft.formatted())")
                    }
                    if let year = property.yearBuilt {
                        propertyDetail(label: "Built", value: "\(year)")
                    }
                    if let value = property.currentEstimatedValue, value > 0 {
                        let formatter: NumberFormatter = {
                            let f = NumberFormatter()
                            f.numberStyle = .currency
                            f.maximumFractionDigits = 0
                            return f
                        }()
                        propertyDetail(label: "Est. Value", value: formatter.string(from: NSNumber(value: value)) ?? "")
                    }
                    if let entity = property.ownershipEntity, !entity.isEmpty {
                        propertyDetail(label: "Entity", value: entity)
                    }
                }

                // Ask Alfred — contextual chat
                Button {
                    showAlfredChat = true
                } label: {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(HavenColors.navy800)
                                .frame(width: 20, height: 20)
                            Text("A")
                                .font(HavenTypography.fraunces(size: 11, weight: 700))
                                .foregroundStyle(HavenColors.creamLight)
                        }
                        Text("Ask Alfred about this property")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(HavenTheme.spacing8)
                    .background(HavenColors.navy.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func propertyDetail(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            quickActionButton(icon: "bubble.left.fill", label: "Chat") {
                showAlfredChat = true
            }
            quickActionButton(icon: "clock.fill", label: "Service History") {
                showFullSchedule = true
            }
            quickActionButton(icon: "plus.circle.fill", label: "Add System") {
                showAddSystem = true
            }
        }
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(HavenColors.navy700)
                Text(label)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(HavenColors.cream)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Maintenance Summary

    private var propertyMaintenanceCard: some View {
        NavigationLink {
            // Phase 66: Land in the new 5-section hub from the property
            // detail. Timeline push from there.
            MaintenanceHubView(filterPropertyId: propertyID)
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundStyle(HavenColors.navy700)
                        Text("HOME MAINTENANCE")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    HStack(spacing: 16) {
                        maintenanceStat(
                            count: viewModel.overdueTasks.count,
                            label: "Overdue",
                            color: viewModel.overdueTasks.count > 0 ? HavenColors.critical : HavenColors.textPrimary
                        )
                        maintenanceStat(
                            count: viewModel.dueThisMonthTasks.count,
                            label: "This Month",
                            color: HavenColors.textPrimary
                        )
                        maintenanceStat(
                            count: viewModel.upcomingTasks.count,
                            label: "Upcoming",
                            color: HavenColors.textPrimary
                        )
                    }

                    if let next = viewModel.upcomingTasks.first {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("Next: \(next.title)")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Text(next.nextDueDate.havenDateShort)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    if viewModel.maintenanceTasks.isEmpty {
                        Text("Add home systems to start tracking maintenance.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func maintenanceStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(max(0, count))")
                .font(HavenTypography.title2)
                .foregroundStyle(color)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Seasonal Overview

    private var seasonalOverviewCard: some View {
        let season = viewModel.currentSeason

        return NavigationLink {
            SeasonalTasksDetailView(
                season: season,
                tasks: viewModel.currentSeasonTasks,
                completedCount: viewModel.currentSeasonCompletedCount,
                nextSeason: viewModel.nextSeason,
                nextSeasonTasks: viewModel.nextSeasonTasks,
                systemNameLookup: { viewModel.systemName(for: $0) },
                contractorNameLookup: { viewModel.contractor(for: $0)?.companyName },
                contractorLookup: { viewModel.contractor(for: $0) },
                onFindVendor: { task in
                    seasonalFindVendorTask = task
                },
                propertyId: propertyID,
                serviceRecords: viewModel.serviceRecords
            )
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: seasonIcon(season))
                        .foregroundStyle(HavenColors.navy800)
                    Text("Seasonal Overview")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    let groups = SeasonalTaskGrouper.group(viewModel.currentSeasonTasks, systemNameLookup: { viewModel.systemName(for: $0) })
                    let totalVendorTasks = groups.flatMap(\.vendorTasks).count
                    let assignedVendorTasks = groups.reduce(0) { $0 + $1.vendorAssignedCount }
                    HStack {
                        Text(season)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        if totalVendorTasks > 0 {
                            Text("\(assignedVendorTasks) of \(totalVendorTasks) vendors assigned")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    if totalVendorTasks > 0 {
                        ProgressView(
                            value: Double(assignedVendorTasks),
                            total: Double(totalVendorTasks)
                        )
                        .tint(HavenColors.action)
                    }
                }

                if !viewModel.nextSeasonTasks.isEmpty {
                    let nextGroups = SeasonalTaskGrouper.group(viewModel.nextSeasonTasks, systemNameLookup: { viewModel.systemName(for: $0) })
                    HStack(spacing: 6) {
                        Image(systemName: seasonIcon(viewModel.nextSeason))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("Coming up in \(viewModel.nextSeason): \(nextGroups.count) areas")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(HavenColors.beige200, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                dismissedSeasonalOverview = "\(season) \(Calendar.current.component(.year, from: Date()))"
            } label: {
                Label("Dismiss for \(season)", systemImage: "xmark.circle")
            }
        }
    }

    @ViewBuilder
    private func seasonalFindVendorContent(task: MaintenanceTaskDBRow) -> some View {
        if let property = viewModel.property,
           let system = viewModel.systems.first(where: { $0.id == task.systemId }) {
            FindLocalVendorSheet(
                task: task,
                householdId: property.householdId,
                town: property.city ?? "",
                state: property.state ?? "",
                systemCategory: system.category,
                categoryDisplayName: system.category.lowercased(),
                onComplete: {
                    Task { await viewModel.loadProperty(id: propertyID) }
                }
            )
        } else {
            AddVendorSheet(onComplete: {
                Task { await viewModel.loadProperty(id: propertyID) }
            })
        }
    }

    private func seasonColor(_ season: String) -> Color {
        switch season {
        case "Spring": return .green
        case "Summer": return .yellow
        case "Fall": return .orange
        case "Winter": return .blue
        default: return HavenColors.navy
        }
    }

    private func seasonIcon(_ season: String) -> String {
        Season(rawValue: season)?.icon ?? "calendar"
    }

    /// Check whether the season completion banner should be visible.
    /// Called after every data reload so the banner reacts to contractor
    /// assignments, task changes, and app foregrounding.
    private func checkSeasonCompletionBanner() {
        let state = viewModel.seasonCompletionState
        let shouldShow = SeasonCompletionBannerState.shouldShow(state)
        if shouldShow != showSeasonCompletionBanner {
            withAnimation(HavenTheme.animationCard) {
                showSeasonCompletionBanner = shouldShow
            }
        }
    }

    private func seasonBackgroundIcons(_ season: String) -> [String] {
        switch season {
        case "Spring": return ["leaf.fill", "cloud.rain.fill", "drop.fill"]
        case "Summer": return ["sun.max.fill", "cloud.sun.fill", "drop.fill"]
        case "Fall": return ["leaf.fill", "wind", "cloud.fill"]
        case "Winter": return ["snowflake", "wind", "cloud.snow.fill"]
        default: return ["leaf.fill"]
        }
    }

    // MARK: - Overdue

    private var overdueSection: some View {
        NavigationLink {
            OverdueTasksDetailView(
                tasks: viewModel.overdueTasks,
                systemNameLookup: { viewModel.systemName(for: $0) },
                propertyAddress: viewModel.property?.street ?? "my property"
            )
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HavenColors.critical)
                        Text("Overdue Maintenance")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Text("\(viewModel.overdueTasks.count)")
                            .font(HavenTypography.uiLabelSmall)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(HavenColors.critical.opacity(0.12))
                            .foregroundStyle(HavenColors.critical)
                            .clipShape(Capsule())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    ForEach(viewModel.overdueTasks.prefix(3)) { task in
                        Button {
                            selectedMaintenanceTask = task
                        } label: {
                            HStack {
                                Circle().fill(HavenColors.critical).frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(HavenTypography.bodySmall)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    if let systemName = viewModel.systemName(for: task.systemId) {
                                        Text(systemName)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.overdueTasks.count > 3 {
                        Text("+ \(viewModel.overdueTasks.count - 3) more")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Systems

    private var systemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Home Systems")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Button {
                    Haptics.light()
                    showAddSystem = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(HavenColors.navy700)
                            .imageScale(.medium)
                        Text("Add")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(Capsule())
                }
            }

            if viewModel.systems.isEmpty {
                HavenCard {
                    VStack(spacing: 10) {
                        Image(systemName: "gearshape.2")
                            .font(.title2)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("What systems does your home have?")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("Add your HVAC, plumbing, electrical and more — Haven will track maintenance for you.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .multilineTextAlignment(.center)

                        Button {
                            Haptics.light()
                            showAddSystem = true
                        } label: {
                            Text("Add a Home System")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy800)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                // Always show groups as group cards (no single-system shortcut),
                // so the user sees a clear category breakdown matching their mental model.
                let groups = SystemGroup.group(viewModel.systems).sorted { $0.systems.count > $1.systems.count }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(groups) { group in
                            NavigationLink {
                                SystemGroupListView(
                                    group: group,
                                    propertyId: propertyID,
                                    householdId: viewModel.property?.householdId ?? UUID()
                                )
                            } label: {
                                compactSystemChip(icon: group.icon, name: shortGroupName(group.name), count: group.systems.count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    // MARK: - Upcoming Maintenance (Next 30 Days)

    private var upcomingMaintenanceSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(HavenColors.warning)
                    Text("Upcoming Maintenance")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Text("Next 30 days")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                let upcomingSlice = Array(viewModel.upcomingTasks.prefix(5))
                ForEach(Array(upcomingSlice.enumerated()), id: \.element.id) { index, task in
                    Button {
                        selectedMaintenanceTask = task
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                HStack(spacing: 8) {
                                    Text("Due: \(task.nextDueDate.havenDateShort)")
                                        .font(HavenTypography.uiLabelSmall)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    if let systemName = viewModel.systemName(for: task.systemId) {
                                        Text(systemName)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                }
                            }
                            Spacer()
                            taskActionMenu(task)
                        }
                    }
                    .buttonStyle(.plain)

                    if index < upcomingSlice.count - 1 {
                        Divider().padding(.horizontal, 4)
                    }
                }

                if viewModel.upcomingTasks.count > 5 {
                    Button {
                        showFullSchedule = true
                    } label: {
                        Text("View All (\(viewModel.upcomingTasks.count))")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
        }
    }

    // MARK: - Phase 50: Upcoming Vendor Visits

    /// Stacked vendor visit cards (full-width). Shows the next 4-6
    /// vendor service visits with vendor name, logo, frequency, and
    /// last cost. Tapping a card opens the maintenance task detail
    /// sheet. The "See full schedule" link at the bottom routes to the
    /// MaintenanceScheduleView.
    /// Build 90: Compact summary card replacing the verbose "UPCOMING
    /// SERVICE VISITS" section. Shows task counts and links to the full
    /// MaintenanceScheduleView so tasks live in one place.
    private var maintenanceSummaryCard: some View {
        let vendorCount = viewModel.vendorVisitTasks.count
        let diyCount = viewModel.diyTasksForMaintenanceTab.count
        let overdueCount = viewModel.overdueTasks.count
        let totalCount = viewModel.maintenanceTasks.filter { $0.vehicleId == nil }.count

        return Button {
            showFullSchedule = true
        } label: {
            HavenCard {
                VStack(spacing: HavenTheme.spacing12) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(HavenColors.navy800)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Maintenance Schedule")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("\(totalCount) tasks on your plan")
                                .font(HavenTypography.uiLabelMedium)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    if vendorCount > 0 || diyCount > 0 || overdueCount > 0 {
                        HStack(spacing: HavenTheme.spacing8) {
                            if overdueCount > 0 {
                                statChip(count: overdueCount, label: "Overdue", color: HavenColors.critical)
                            }
                            if vendorCount > 0 {
                                statChip(count: vendorCount, label: "Vendor", color: HavenColors.navy800)
                            }
                            if diyCount > 0 {
                                statChip(count: diyCount, label: "DIY", color: HavenColors.navy800)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func statChip(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(HavenTypography.uiLabelSmall)
                .fontWeight(.bold)
            Text(label)
                .font(HavenTypography.uiLabelSmall)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Phase 50: DIY Task Section

    /// Compact list of personal/DIY tasks. Shows only templates with
    /// `routing == .diyDefault` (e.g. filter swap, weatherstripping,
    /// mini-split rinse, generator dipstick) plus any custom tasks the
    /// user added with personal assignment. Empty state shows a
    /// "You're all caught up" green check so even hire-out users see
    /// affirmative state instead of an empty card.
    private var diyTasksSection: some View {
        let tasks = Array(viewModel.diyTasksForMaintenanceTab.prefix(5))
        return VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("YOUR TASKS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                if !tasks.isEmpty {
                    Text("\(viewModel.diyTasksForMaintenanceTab.count)")
                        .font(HavenTypography.uiLabelSmall)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(HavenColors.navy.opacity(0.08))
                        .foregroundStyle(HavenColors.navy700)
                        .clipShape(Capsule())
                }
            }
            HavenCard {
                if tasks.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(HavenColors.success)
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("You're all caught up")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("No personal tasks on your plate right now.")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            Button {
                                selectedMaintenanceTask = task
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(HavenColors.navy700.opacity(0.4))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(HavenTypography.uiLabel)
                                            .foregroundStyle(HavenColors.textPrimary)
                                            .lineLimit(1)
                                        HStack(spacing: 6) {
                                            Text("Due \(task.nextDueDate.havenDateShort)")
                                                .font(HavenTypography.uiCaption)
                                                .foregroundStyle(HavenColors.textSecondary)
                                            if let systemName = viewModel.systemName(for: task.systemId) {
                                                Text("·")
                                                    .font(HavenTypography.uiCaption)
                                                    .foregroundStyle(HavenColors.textTertiary)
                                                Text(systemName)
                                                    .font(HavenTypography.uiCaption)
                                                    .foregroundStyle(HavenColors.textTertiary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)
                            if index < tasks.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            if viewModel.diyTasksForMaintenanceTab.count > 5 {
                Button {
                    showFullSchedule = true
                } label: {
                    HStack(spacing: 4) {
                        Text("View all \(viewModel.diyTasksForMaintenanceTab.count)")
                            .font(HavenTypography.uiLabelSmall)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Phase 50: Vendor Follow-ups

    /// Amber-tinted card listing vendor follow-up tasks created from
    /// invoices (e.g. "Retest water in 4 weeks per Andy's Plumbing").
    /// Hidden entirely when there are none — the section never shows an
    /// empty state because follow-ups are always exception items.
    private var vendorFollowUpsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(HavenColors.warning)
                Text("VENDOR FOLLOW-UPS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Text("\(viewModel.vendorFollowUpTasks.count)")
                    .font(HavenTypography.uiLabelSmall)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(HavenColors.warning.opacity(0.15))
                    .foregroundStyle(HavenColors.warning)
                    .clipShape(Capsule())
            }
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(viewModel.vendorFollowUpTasks) { task in
                    let contractor = viewModel.contractor(for: task.assignedContractorId)
                    VendorVisitCard(
                        task: task,
                        vendorName: contractor?.companyName,
                        vendorLogoURL: contractor?.logoUrl.flatMap { URL(string: $0) },
                        brandColorHex: contractor?.brandColor,
                        lastCost: nil,
                        isFollowUp: true,
                        style: .full,
                        onTap: { selectedMaintenanceTask = task }
                    )
                }
            }
        }
    }

    // MARK: - Phase 54B.3: Handyman Punch List Row

    /// Compact entry row for the handyman punch list. Shows pending
    /// count as a badge; tapping opens `HandymanPunchListView`. Always
    /// renders (even with zero items) because the row doubles as the
    /// primary "add something" entry point — the empty state lives
    /// inside the destination view.
    @ViewBuilder
    private var handymanPunchListRow: some View {
        if let householdId = viewModel.property?.householdId {
            Button {
                Haptics.light()
                showHandymanPunchList = true
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Handyman punch list")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(handymanPunchCount == 0
                             ? "Add things for your next handyman visit"
                             : "\(handymanPunchCount) item\(handymanPunchCount == 1 ? "" : "s") waiting")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    if handymanPunchCount > 0 {
                        Text("\(handymanPunchCount)")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(HavenColors.beige200)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .navigationDestination(isPresented: $showHandymanPunchList) {
                HandymanPunchListView(
                    householdId: householdId,
                    propertyId: propertyID
                )
            }
            .task {
                await loadHandymanPunchCount(householdId: householdId)
            }
            .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
                Task { await loadHandymanPunchCount(householdId: householdId) }
            }
        }
    }

    private func loadHandymanPunchCount(householdId: UUID) async {
        do {
            let items = try await DatabaseService.shared
                .fetchPendingHandymanPunchItems(householdId: householdId)
            handymanPunchCount = items.count
        } catch {
            handymanPunchCount = 0
        }
    }

    // MARK: - Phase 55.3: Routines Row

    /// Bootstrap entry point for household routines — trash day,
    /// biweekly cleaning with Renata, lawn care with Blue Fox, pool
    /// service, the full set. Destination is `RoutinesListView`.
    /// Mirrors the HandymanPunchListView row pattern: always renders,
    /// badge shows count when > 0, destination handles its own empty
    /// state.
    @ViewBuilder
    private var weeklyCadencesRow: some View {
        if let householdId = viewModel.property?.householdId {
            Button {
                Haptics.light()
                showWeeklyCadences = true
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Routines")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(weeklyCadenceCount == 0
                             ? "Trash day, cleaning, lawn care, pool service"
                             : "\(weeklyCadenceCount) routine\(weeklyCadenceCount == 1 ? "" : "s") configured")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    if weeklyCadenceCount > 0 {
                        Text("\(weeklyCadenceCount)")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(HavenColors.beige200)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .task {
                await loadWeeklyCadenceCount(householdId: householdId)
            }
            .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
                Task { await loadWeeklyCadenceCount(householdId: householdId) }
            }
        }
    }

    private func loadWeeklyCadenceCount(householdId: UUID) async {
        do {
            let routines = try await DatabaseService.shared
                .fetchRoutines(householdId: householdId)
            weeklyCadenceCount = routines.count
        } catch {
            weeklyCadenceCount = 0
        }
    }

    // MARK: - Phase 54C.3: Recommended for your home row

    /// Low-key entry point into the "Recommended for your home"
    /// browsing surface. Always visible (no badge count) because the
    /// destination's empty state handles the zero-recommendation
    /// case, and the value-preservation templates aren't a backlog
    /// that needs urgency framing — they're a library.
    @ViewBuilder
    private var recommendedServicesRow: some View {
        if viewModel.property?.householdId != nil {
            Button {
                Haptics.light()
                showRecommendedServices = true
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recommended for your home")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Value-preservation services to discover")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Phase 50: View Full Schedule Link

    /// Footer link below the maintenance sections that pushes the
    /// MaintenanceScheduleView pre-filtered to this property.
    private var viewFullScheduleLink: some View {
        Button {
            showFullSchedule = true
        } label: {
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 13, weight: .semibold))
                    Text("View full maintenance schedule")
                        .font(HavenTypography.uiLabel)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(HavenColors.navy700)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(HavenColors.navy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Warranties

    private var warrantiesSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(HavenColors.info)
                    Text("Active Warranties")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                ForEach(viewModel.activeWarranties) { warranty in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(warranty.provider)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Expires: \(warranty.endDate)")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        if let phone = warranty.claimPhone,
                           let url = sanitizedPhoneURL(phone) {
                            Link(destination: url) {
                                Image(systemName: "phone.fill")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Property Documents (moved higher in layout)

    private var propertyDocumentsSection: some View {
        VStack(spacing: HavenTheme.spacing8) {
        NavigationLink {
            PropertyDocumentsView(propertyId: propertyID, propertyName: viewModel.property?.name ?? "Property")
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(HavenColors.navy700)
                        Text("Property Documents")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()

                        Text("\(viewModel.linkedDocuments.count)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(HavenColors.beige200)
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    if viewModel.linkedDocuments.isEmpty {
                        Text("Upload deeds, insurance, blueprints, quotes, and more")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        // Show first 3 docs as preview
                        ForEach(viewModel.linkedDocuments.prefix(3)) { doc in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.havenSuccess)
                                    .font(.caption)
                                Text(doc.title)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text(doc.category)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }

                        if viewModel.linkedDocuments.count > 3 {
                            Text("+ \(viewModel.linkedDocuments.count - 3) more")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }

                    // Missing doc prompts
                    let missingCount = viewModel.missingPropertyDocTypes.count
                    if missingCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundStyle(HavenColors.warning)
                            Text("\(missingCount) suggested document\(missingCount == 1 ? "" : "s") to upload")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)

        // Quick upload button
        Button {
            showDocumentUpload = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.caption)
                Text("Upload Property Document")
                    .font(HavenTypography.uiLabel)
            }
            .foregroundStyle(HavenColors.navy700)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(HavenColors.navy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        } // end VStack wrapper
    }

    // MARK: - Vendors (Phase 56.1 — Contacts Hub)

    /// Apple Contacts / Linear-style contacts directory. Canonical home
    /// for vendor management. Add button routes directly to
    /// `AddVendorSheet` (one tap). Search + filter chips live at the top.
    /// "Add or discover" section at the bottom consolidates the
    /// discovery actions that used to sit in Vendor Coverage.
    private var vendorsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack {
                Text("Home & Estate Contacts")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                addContactButton
            }

            if !viewModel.contractors.isEmpty {
                searchField
                filterChipsRow
            }

            contactsList

            if !viewModel.contractors.isEmpty {
                addOrDiscoverSection
            }
        }
    }

    // MARK: Add button

    private var addContactButton: some View {
        Button {
            Haptics.light()
            showAddVendor = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy700)
                    .imageScale(.medium)
                Text("Add")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(HavenColors.navy.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Search + filter chips

    private var searchField: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.textTertiary)
            TextField("Search by name, company, or specialty", text: $contactsSearchText)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !contactsSearchText.isEmpty {
                Button {
                    Haptics.light()
                    contactsSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, 10)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ContactsFilter.allCases) { filter in
                    Button {
                        Haptics.selection()
                        contactsFilter = filter
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(filter.rawValue)
                                .font(HavenTypography.uiCaption)
                        }
                        .foregroundStyle(
                            contactsFilter == filter
                                ? HavenColors.textOnNavy
                                : HavenColors.navy700
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            contactsFilter == filter
                                ? HavenColors.navy
                                : HavenColors.navy.opacity(0.08)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Contacts list

    @ViewBuilder
    private var contactsList: some View {
        if viewModel.contractors.isEmpty {
            emptyContactsState
        } else if filteredContacts.isEmpty {
            noMatchesState
        } else {
            VStack(spacing: 6) {
                ForEach(filteredContacts) { contractor in
                    NavigationLink {
                        ContractorDetailView(contractor: contractor)
                    } label: {
                        contractorRow(
                            contractor,
                            showAttentionReason: contactsFilter == .needsAttention
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyContactsState: some View {
        HavenCard {
            VStack(spacing: 10) {
                Image(systemName: "person.2")
                    .font(.title2)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("Add your trusted contractors and service providers here.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        Haptics.light()
                        showAddVendor = true
                    } label: {
                        Text("Add a Vendor")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy800)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.light()
                        showAlfredChat = true
                    } label: {
                        Text("Ask Alfred to Find One")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(Capsule().stroke(HavenColors.navy.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var noMatchesState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(HavenColors.textTertiary)
            Text("No contacts match")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            if !contactsSearchText.isEmpty {
                Button {
                    Haptics.light()
                    contactsSearchText = ""
                } label: {
                    Text("Clear search")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: Row rendering

    /// Apple Contacts-style single-line row with logo, truncated display
    /// name, primary specialty, optional routine badge, and chevron.
    /// Replaces the card-chrome `contractorCardInline` for density.
    ///
    /// Phase 56.1: when `showAttentionReason` is true (the Needs
    /// Attention filter is active), the caption swaps from the
    /// specialty to an amber "Needs phone · email" line and a trailing
    /// dismiss button replaces part of the chevron track.
    private func contractorRow(
        _ contractor: ContractorRow,
        showAttentionReason: Bool = false
    ) -> some View {
        let reason = showAttentionReason ? attentionReason(for: contractor) : nil
        return HStack(spacing: HavenTheme.spacing12) {
            VendorLogoView(contractor: contractor, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(displayName(for: contractor))
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                if let reason {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(HavenColors.warning)
                        Text(reason)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.warning)
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: 6) {
                        if let specialty = primarySpecialty(for: contractor) {
                            Text(specialty)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(1)
                        }
                        if isRoutineServed(contractor) {
                            routineBadge
                        }
                    }
                    if let activity = vendorActivitySubtitle(for: contractor) {
                        Text(activity)
                            .font(.system(size: 11))
                            .foregroundStyle(HavenColors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            if showAttentionReason {
                // Inline dismiss: user marks this vendor's missing
                // fields as "I don't care" and the row drops from the
                // Needs Attention filter (persisted per household).
                Button {
                    dismissAttention(for: contractor)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(.horizontal, 2)
                }
                .buttonStyle(.plain)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, 10)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var routineBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 8, weight: .semibold))
            Text("Routine")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(HavenColors.navy700)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(HavenColors.navy.opacity(0.08))
        .clipShape(Capsule())
    }

    private func isRoutineServed(_ contractor: ContractorRow) -> Bool {
        viewModel.routineVendorIds.contains(contractor.id)
    }

    /// Phase 58: lightweight activity subtitle that brings Contacts rows
    /// to life. Priority: (1) next upcoming task within 60 days → "Next:
    /// {title} · {relative}", (2) most recent service record within 60
    /// days → "Last: {service type} · {relative}", (3) nil.
    private func vendorActivitySubtitle(for contractor: ContractorRow) -> String? {
        let todayStr: String = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let sixtyDaysOut = Calendar.current.date(byAdding: .day, value: 60, to: now) ?? now
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now) ?? now

        // Next upcoming task within 60 days
        let next = viewModel.maintenanceTasks
            .filter { $0.assignedContractorId == contractor.id }
            .filter { $0.nextDueDate >= todayStr }
            .compactMap { task -> (MaintenanceTaskDBRow, Date)? in
                guard let d = fmt.date(from: task.nextDueDate), d <= sixtyDaysOut else { return nil }
                return (task, d)
            }
            .min { $0.1 < $1.1 }
        if let (task, date) = next {
            return "Next: \(shortTitle(task.title)) · \(relativeLabel(for: date))"
        }

        // Most recent service record within 60 days
        let recent = viewModel.serviceRecords
            .filter { $0.contractorId == contractor.id }
            .compactMap { record -> (ServiceRecordRow, Date)? in
                guard let d = fmt.date(from: record.serviceDate), d >= sixtyDaysAgo else { return nil }
                return (record, d)
            }
            .max { $0.1 < $1.1 }
        if let (record, date) = recent {
            return "Last: \(shortTitle(record.description)) · \(relativeLabel(for: date))"
        }

        return nil
    }

    private func shortTitle(_ title: String) -> String {
        // Truncate titles over 24 chars at a natural break point.
        if title.count <= 24 { return title }
        let trimmed = String(title.prefix(24))
        if let lastSpace = trimmed.lastIndex(of: " ") {
            return String(trimmed[..<lastSpace]) + "…"
        }
        return trimmed + "…"
    }

    private func relativeLabel(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "tomorrow" }
        if days == -1 { return "yesterday" }
        if days > 0 {
            if days < 7 { return "in \(days) days" }
            if days < 14 { return "next week" }
            if days < 30 { return "in \(days / 7) weeks" }
            return "in \(days / 30) month\(days / 30 == 1 ? "" : "s")"
        }
        let ago = -days
        if ago < 7 { return "\(ago) days ago" }
        if ago < 14 { return "last week" }
        if ago < 30 { return "\(ago / 7) weeks ago" }
        return "\(ago / 30) month\(ago / 30 == 1 ? "" : "s") ago"
    }

    /// Phase 56.1: Display name handling for vendors with very long
    /// company names. "Tyler Heating, Air Conditioning, Refrigeration..."
    /// truncates badly in a row UI; show the short form (first
    /// comma-segment) in the list while `ContractorDetailView` still
    /// shows the full name.
    private func displayName(for contractor: ContractorRow) -> String {
        let full = contractor.companyName
        if full.count <= 28 && !full.contains(",") { return full }
        if let firstComma = full.firstIndex(of: ",") {
            return String(full[..<firstComma])
                .trimmingCharacters(in: .whitespaces)
        }
        return full
    }

    // MARK: Needs-attention helpers

    /// Phase 56.1: Returns the human-readable list of data-quality
    /// fields the vendor is missing, in the order we'd want a user to
    /// fill them in (most impactful first). Used to build the row
    /// caption when the Needs Attention filter is active.
    ///
    /// A non-empty return means the vendor qualifies for the Needs
    /// Attention filter. When the user dismisses a vendor, we suppress
    /// the row even though this still returns a non-empty list.
    private func missingFields(for contractor: ContractorRow) -> [String] {
        var missing: [String] = []

        let phoneRaw = contractor.phone
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if phoneRaw.isEmpty
            || phoneRaw.caseInsensitiveCompare("Not provided") == .orderedSame {
            missing.append("phone")
        }

        let email = contractor.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if email.isEmpty {
            missing.append("email")
        }

        let hasSpecialty = (contractor.specialties?.isEmpty == false)
        let hasCategory = (contractor.category?.isEmpty == false)
        if !hasSpecialty && !hasCategory {
            missing.append("category")
        }

        return missing
    }

    /// Phase 56.1: Amber caption like "Needs phone · email" that
    /// replaces the specialty line when the Needs Attention filter is
    /// active. Capitalizes the first word only to keep it readable.
    private func attentionReason(for contractor: ContractorRow) -> String? {
        let fields = missingFields(for: contractor)
        guard !fields.isEmpty else { return nil }
        let joined = fields.joined(separator: " \u{00B7} ")
        return "Needs \(joined)"
    }

    /// Phase 56.1: UserDefaults key for per-household attention
    /// dismissal persistence. Household-scoped so switching households
    /// doesn't leak dismissals across.
    private func attentionDismissalKey(householdId: UUID) -> String {
        "contacts_attention_dismissed_v1_\(householdId.uuidString)"
    }

    private func loadAttentionDismissals() {
        guard let householdId = viewModel.property?.householdId else {
            attentionDismissedIds = []
            return
        }
        let raw = UserDefaults.standard
            .stringArray(forKey: attentionDismissalKey(householdId: householdId)) ?? []
        attentionDismissedIds = Set(raw.compactMap { UUID(uuidString: $0) })
    }

    private func dismissAttention(for contractor: ContractorRow) {
        guard let householdId = viewModel.property?.householdId else { return }
        Haptics.light()
        attentionDismissedIds.insert(contractor.id)
        let ids = attentionDismissedIds.map(\.uuidString)
        UserDefaults.standard.setValue(
            ids,
            forKey: attentionDismissalKey(householdId: householdId)
        )
    }

    /// Phase 56.1: Render up to two non-estate specialties in the row
    /// caption so multi-category vendors (e.g. Orkin for Pest Control +
    /// Mosquito & Tick, a landscaper for Landscaping + Snow Removal)
    /// are visible at a glance. The data model already supports
    /// multi-category via `specialties: [String]?`; this just surfaces
    /// it. When more than two apply, suffix with "+N".
    private func primarySpecialty(for contractor: ContractorRow) -> String? {
        guard let specialties = contractor.specialties, !specialties.isEmpty else {
            return contractor.contactName
        }
        let estateLabels: Set<String> = [
            "Contractor / Service Provider", "Attorney",
            "Financial Advisor / CPA", "Insurance Agent",
            "Property Manager", "Other"
        ]
        let nonEstate = specialties.filter { !estateLabels.contains($0) }
        let pool = nonEstate.isEmpty ? specialties : nonEstate
        let visible = Array(pool.prefix(2))
        var caption = visible.joined(separator: " \u{00B7} ")
        let hidden = pool.count - visible.count
        if hidden > 0 { caption += " +\(hidden)" }
        return caption.isEmpty ? contractor.contactName : caption
    }

    // MARK: Filtered list

    /// Apply search + filter to the contractor roster. Search matches
    /// company name, contact name, or specialty. Filter chips:
    ///   - All:                  every contact
    ///   - Service-based:        contractors with vendor-coded specialties
    ///   - Routines:             vendors linked to an active routine
    ///   - Estate professionals: attorneys, advisors, insurance, property mgmt
    ///   - Needs attention:      contacts missing specialty or email
    private var filteredContacts: [ContractorRow] {
        var result = viewModel.contractors

        let trimmed = contactsSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let needle = trimmed.lowercased()
            result = result.filter { contractor in
                if contractor.companyName.lowercased().contains(needle) { return true }
                if let name = contractor.contactName?.lowercased(),
                   name.contains(needle) { return true }
                if let specialties = contractor.specialties,
                   specialties.contains(where: { $0.lowercased().contains(needle) }) {
                    return true
                }
                return false
            }
        }

        let estateLabels = Set([
            "Attorney", "Financial Advisor / CPA", "Insurance Agent",
            "Property Manager"
        ])

        switch contactsFilter {
        case .all:
            break
        case .serviceBased:
            result = result.filter { contractor in
                guard let specialties = contractor.specialties else { return false }
                return !specialties.contains(where: { estateLabels.contains($0) })
            }
        case .routine:
            let routineVendorIds = viewModel.routineVendorIds
            result = result.filter { routineVendorIds.contains($0.id) }
        case .estate:
            result = result.filter { contractor in
                guard let specialties = contractor.specialties else { return false }
                return specialties.contains(where: { estateLabels.contains($0) })
            }
        case .needsAttention:
            // Phase 56.1: flag vendors missing phone, email, or
            // category — each surfaced as a specific reason ("Needs
            // phone · email") via the row renderer so the user knows
            // exactly what to fix, plus a dismiss button for the "I
            // don't care about this one" case. Dismissals are stored
            // per-household in UserDefaults.
            result = result.filter { contractor in
                guard !attentionDismissedIds.contains(contractor.id) else {
                    return false
                }
                return !missingFields(for: contractor).isEmpty
            }
        }

        return result
    }

    // MARK: Add or discover

    /// Consolidates the vendor/system/routine/recommendation discovery
    /// actions that previously lived in Vendor Coverage. Section lives
    /// at the bottom of the Contacts sub-tab so the directory itself
    /// stays focused while discovery is one scroll away.
    private var addOrDiscoverSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("ADD OR DISCOVER")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.top, HavenTheme.spacing16)

            addOrDiscoverRow(
                icon: "person.crop.rectangle.badge.plus",
                title: "Add a vendor",
                subtitle: "Contractor, attorney, advisor",
                action: {
                    Haptics.light()
                    showAddVendor = true
                }
            )

            addOrDiscoverRow(
                icon: "magnifyingglass.circle.fill",
                title: "Browse specialty systems",
                subtitle: "Pool, spa, EV charger, wine cellar, elevator",
                action: {
                    Haptics.light()
                    showBrowseSpecialty = true
                }
            )

            addOrDiscoverRow(
                icon: "plus.square.on.square",
                title: "Add a custom system",
                subtitle: "Something the catalog doesn't cover",
                action: {
                    Haptics.light()
                    showAddSystem = true
                }
            )

            addOrDiscoverRow(
                icon: "calendar.badge.plus",
                title: "Add a routine",
                subtitle: "Cleaning, lawn care, pool service, trash day",
                action: {
                    Haptics.light()
                    showWeeklyCadences = true
                }
            )

            addOrDiscoverRow(
                icon: "sparkles",
                title: "See recommended services",
                subtitle: "Tree, window washing, power washing, more",
                action: {
                    Haptics.light()
                    showRecommendedServices = true
                }
            )
        }
    }

    private func addOrDiscoverRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 32, height: 32)
                    .background(HavenColors.navy.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
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
                    .stroke(HavenColors.beige200.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Service History

    /// Compact service history for the Overview tab — last 3 records.
    private var recentServiceHistoryCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(HavenColors.textSecondary)
                    Text("Recent Service")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                }

                let overviewServiceSlice = Array(viewModel.serviceRecords.prefix(3))
                ForEach(Array(overviewServiceSlice.enumerated()), id: \.element.id) { index, record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.description)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(1)
                            Text(record.serviceDate)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Spacer()
                        if let cost = record.cost {
                            Text("$\(cost, specifier: "%.0f")")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }

                    if index < overviewServiceSlice.count - 1 {
                        Divider().padding(.horizontal, 4)
                    }
                }

                if viewModel.serviceRecords.count > 3 {
                    NavigationLink {
                        ServiceHistoryView()
                    } label: {
                        Text("View All (\(viewModel.serviceRecords.count))")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
        }
    }

    private var serviceHistorySection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(HavenColors.textSecondary)
                    Text("Recent Service History")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    if viewModel.totalServiceCost > 0 {
                        Text("$\(viewModel.totalServiceCost, specifier: "%.0f") total")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                let serviceSlice = Array(viewModel.serviceRecords.prefix(5))
                ForEach(Array(serviceSlice.enumerated()), id: \.element.id) { index, record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.description)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(2)
                            Text(record.serviceDate)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        if let cost = record.cost {
                            Text("$\(cost, specifier: "%.0f")")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }

                    if index < serviceSlice.count - 1 {
                        Divider().padding(.horizontal, 4)
                    }
                }

                if viewModel.serviceRecords.count > 5 {
                    NavigationLink {
                        ServiceHistoryView()
                    } label: {
                        Text("View All (\(viewModel.serviceRecords.count))")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
        }
    }

    // MARK: - Task Action Menu

    private func taskActionMenu(_ task: MaintenanceTaskDBRow) -> some View {
        Menu {
            Button {
                Task { await viewModel.completeMaintenanceTask(task) }
            } label: {
                Label("Mark Complete", systemImage: "checkmark.circle")
            }

            if let vendorName = viewModel.vendorName(for: task.systemId),
               let vendorPhone = viewModel.vendorPhone(for: task.systemId) {
                Button {
                    if let url = sanitizedPhoneURL(vendorPhone) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Call \(vendorName)", systemImage: "phone")
                }

                if let vendorEmail = viewModel.vendorEmail(for: task.systemId) {
                    Button {
                        if let url = sanitizedEmailURL(vendorEmail) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Email \(vendorName)", systemImage: "envelope")
                    }
                }
            }

            if viewModel.vendorName(for: task.systemId) == nil {
                Button {
                    vendorAssignmentTask = task
                } label: {
                    Label("Assign a Vendor", systemImage: "person.badge.plus")
                }
            }

            Button {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                editedTaskDueDate = f.date(from: task.nextDueDate) ?? Date()
                taskForDateEdit = task
            } label: {
                Label("Edit Due Date", systemImage: "calendar.badge.clock")
            }

            Button {
                taskForLastServiced = task
            } label: {
                Label("I Already Did This", systemImage: "checkmark.circle.badge.questionmark")
            }

            Button {
                selectedTaskForReminder = task
                showReminderPicker = true
            } label: {
                Label("Set Reminder", systemImage: "bell")
            }

            Button {
                showAlfredChat = true
            } label: {
                Label("Ask Alfred for Help", systemImage: "bubble.left")
            }

            Divider()

            Menu("Snooze") {
                Button("1 Week") { Task { await viewModel.snoozeTask(task, days: 7) } }
                Button("2 Weeks") { Task { await viewModel.snoozeTask(task, days: 14) } }
                Button("1 Month") { Task { await viewModel.snoozeTask(task, days: 30) } }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
                .foregroundStyle(HavenColors.navy700)
        }
    }

    // MARK: - Reminder Sheet

    private var reminderSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("When should we remind you?")
                    .font(HavenTypography.headline)

                ForEach(["Tomorrow", "In 3 Days", "Next Week", "Next Month"], id: \.self) { option in
                    Button {
                        Task {
                            await viewModel.setReminder(for: selectedTaskForReminder, option: option)
                        }
                        showReminderPicker = false
                    } label: {
                        Text(option)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.creamLight)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .presentationDetents([.height(300)])
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showReminderPicker = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func compactSystemChip(icon: String, name: String, count: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(HavenColors.navy700)
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(HavenColors.navy800)
                .lineLimit(1)
            Text("\(count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(HavenColors.navy.opacity(0.06))
                .cornerRadius(8)
        }
        .frame(width: 80, height: 75)
        .background(HavenColors.surface)
        .cornerRadius(HavenTheme.radiusMedium)
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.border.opacity(0.5), lineWidth: 0.5)
        }
    }

    private func shortGroupName(_ name: String) -> String {
        switch name {
        case "Climate & Energy": return "Climate"
        case "Structure & Exterior": return "Exterior"
        case "Plumbing & Water": return "Plumbing"
        case "Smoke & Fire Protection": return "Safety"
        case "Other Systems": return "Other"
        default: return name
        }
    }

    private func systemGroupCard(_ group: SystemGroup) -> some View {
        VStack(spacing: 8) {
            Image(systemName: group.icon)
                .font(.system(size: 22))
                .foregroundStyle(HavenColors.navy700)

            Text(group.name)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.navy800)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text("\(group.systems.count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.navy)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(HavenColors.navy.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .padding(12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(HavenColors.beige300, lineWidth: 0.5)
        )
    }

    private func systemGridCard(_ system: HomeSystemRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(systemStatusColor(system.status))
                    .frame(width: 8, height: 8)
                Text(system.name)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
            }
            if let mfr = system.manufacturer {
                HStack(spacing: 4) {
                    Text(mfr)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                    if let model = system.modelNumber {
                        Text("·")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(model)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            if let nextDue = system.nextServiceDue {
                Text("Due: \(nextDue)")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(HavenColors.beige300, lineWidth: 0.5)
        )
    }

    private func systemStatusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "good": return HavenColors.success
        case "needs maintenance": return HavenColors.warning
        case "needs repair", "needs replacement": return HavenColors.critical
        case "under warranty": return HavenColors.info
        case "out of service": return HavenColors.textTertiary
        default: return HavenColors.success
        }
    }

    private func sanitizedPhoneURL(_ phone: String) -> URL? {
        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return URL(string: "tel:\(cleaned)")
    }

    private func sanitizedEmailURL(_ email: String) -> URL? {
        URL(string: "mailto:\(email.trimmingCharacters(in: .whitespaces))")
    }
}
