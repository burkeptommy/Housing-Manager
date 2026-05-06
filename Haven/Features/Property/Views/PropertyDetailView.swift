import SwiftUI

enum PropertyDetailTab: String, CaseIterable {
    case overview
    case systems
    case projects
    case vendors
    case documents

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .systems: return "Systems"
        case .projects: return "Projects"
        case .vendors: return "Vendors"
        case .documents: return "Documents"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .systems: return "square.stack.3d.up.fill"
        case .projects: return "hammer.fill"
        case .vendors: return "person.2.fill"
        case .documents: return "doc.text.fill"
        }
    }
}

/// Phase 56.1: Filter options for the Contacts sub-tab. Lives at the
/// top level so it stays stable across SwiftUI redraws and so the
/// picker chips can iterate `.allCases`.
enum ContactsFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case serviceBased = "Home services"
    case utilitiesPolicies = "Utilities & policies"
    case routine = "Recurring"
    case needsAttention = "Needs review"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "person.2.fill"
        case .serviceBased: return "wrench.and.screwdriver.fill"
        case .utilitiesPolicies: return "bolt.horizontal.circle.fill"
        case .routine: return "calendar.badge.clock"
        case .needsAttention: return "exclamationmark.triangle.fill"
        }
    }
}

struct PropertyDetailView: View {
    private struct CoverageGapItem: Identifiable {
        let system: HomeSystemRow
        let task: MaintenanceTaskDBRow?

        var id: UUID { system.id }
    }

    private enum PropertyRelationshipItem: Identifiable {
        case contractor(ContractorRow)
        case utility(UtilityAccountRow)

        var id: String {
            switch self {
            case .contractor(let contractor):
                return "contractor-\(contractor.id.uuidString)"
            case .utility(let account):
                return "utility-\(account.id.uuidString)"
            }
        }
    }

    let propertyID: UUID
    @StateObject private var viewModel = PropertyDetailViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var activeTab: PropertyDetailTab = .overview
    @State private var showAddSystem = false
    @State private var showEditProperty = false
    @State private var showDeleteConfirmation = false
    @State private var showDocumentUpload = false
    /// Chez v1: surfaced from the Property → Projects "Import from email"
    /// starter card so the user lands on their `*@alfred.havenhome.dev`
    /// forwarding address without a tab switch.
    @State private var showProjectEmail = false
    /// Chez v1: Services row taps land here for editing; "+ Add service"
    /// fires `showAddService`. Both present `RoutineEditSheet` —
    /// services are routines under the hood (no separate `home_systems`
    /// row required), so creating a new service writes a routine.
    @State private var editingServiceRoutine: RoutineRow?
    @State private var showAddService = false
    /// Camera FAB on the Systems sub-tab. The first time the user taps
    /// it we surface a brief explainer ("Take a photo of any model
    /// number..."); subsequent taps go straight into the identify sheet.
    @State private var showSystemPhotoIdentify = false
    @State private var showSystemPhotoOnboarding = false
    @State private var systemPhotoToast: String?
    /// Overview "Needs your decision" cards now open lists, not single
    /// task drills. The user previously got dropped into the FIRST
    /// vendor-needing task's detail with no path to the other 49.
    @State private var showNeedsVendorTasks = false
    @State private var showSystemsMissingProfile = false
    /// Set when the user taps a row inside `SystemsMissingProfileSheet`.
    /// We dismiss the sheet and present `SystemDetailRowView` for the
    /// chosen row via a NavigationLink-style sheet so the user lands on
    /// the editable detail page in one tap.
    @State private var systemForProfileSetup: HomeSystemRow?
    /// Gamified install-date capture flow. Opened from
    /// `SystemCoverageCard` on the Systems sub-tab.
    @State private var showSystemCoverageFlow = false
    /// Chez v1: Tasks-needing-vendor sheet now groups by canonical
    /// vendor category. Tapping a category fires the find-a-pro flow
    /// for the WHOLE bucket — these three pieces hold the in-flight
    /// category between the sheet dismiss and FindLocalVendorSheet's
    /// presentation.
    @State private var showFindProForGroup = false
    @State private var findProGroupCategory: String?
    @State private var findProGroupDisplayName: String?
    @State private var showPropertyDocuments = false
    @State private var showFullSchedule = false
    @State private var showServiceHistory = false
    @State private var showAlfredChat = false
    @State private var showValueDetails = false
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
    /// Phase 95 audit (Wave 5d) — drives navigation into the new
    /// HouseholdSpendView, opened from the InvestmentSummaryCard.
    @State private var showHouseholdSpend = false
    /// Phase 95 (gap #40) — drives the systems-browse surface that
    /// fronts AddSystemView with category-tier groupings of
    /// SystemCategoryRegistry's universal / conditional / specialty
    /// entries. Distinct from `showRecommendedServices` which is
    /// the value-preservation maintenance-templates picker.
    @State private var showRecommendedSystems = false

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
    @State private var showAddUtility = false
    @State private var addUtilityType: String?
    @State private var systemsSearchText: String = ""
    @State private var showPrioritySystemsSheet = false
    @State private var selectedSystemForDetail: HomeSystemRow?
    @State private var selectedSystemGroup: SystemGroup?
    @State private var showCoverageReview = false

    /// Phase 56.1: Contractor IDs the user has dismissed from the
    /// "Needs attention" filter (e.g. they don't care that Orkin has
    /// no email, or this landscaper never gave them a phone). Persisted
    /// in UserDefaults so dismissals survive relaunch. Per-household
    /// key so switching households doesn't leak dismissals across.
    @State private var attentionDismissedIds: Set<UUID> = []

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        propertyDetailBody
    }

    private var propertyDetailBody: some View {
        propertyDetailModalContent
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

    private var propertyDetailModalContent: some View {
        propertyDetailRoutingContent
            .sheet(item: $selectedMaintenanceTask) { task in
                maintenanceTaskSheetContent(task)
            }
            .sheet(isPresented: $showCoverageReview) {
                coverageReviewSheetContent
            }
            .sheet(item: $seasonalFindVendorTask) { task in
                seasonalFindVendorContent(task: task)
            }
            .sheet(isPresented: $showAddVendor) {
                addVendorSheetContent
            }
            .sheet(isPresented: $showAddUtility) {
                addUtilitySheetContent
            }
            .sheet(item: $vendorAssignmentTask) { task in
                vendorAssignmentSheetContent(task)
            }
            .sheet(isPresented: $showBrowseSpecialty) {
                browseSpecialtySheetContent
            }
    }

    private var propertyDetailRoutingContent: some View {
        propertyDetailCoreContent
            .sheet(item: $taskForDateEdit) { task in
                editDueDateSheetContent(task)
            }
            .sheet(item: $taskForLastServiced) { task in
                logPastServiceSheetContent(task)
            }
            .navigationDestination(isPresented: $showFullSchedule) {
                MaintenanceHubView(filterPropertyId: propertyID)
            }
            .navigationDestination(isPresented: $showHandymanPunchList) {
                if let householdId = viewModel.property?.householdId {
                    HandymanPunchListView(
                        householdId: householdId,
                        propertyId: propertyID
                    )
                }
            }
            .navigationDestination(isPresented: $showServiceHistory) {
                ServiceHistoryView()
            }
            .navigationDestination(isPresented: $showPropertyDocuments) {
                PropertyDocumentsView(propertyId: propertyID, propertyName: viewModel.property?.name ?? "Property")
            }
            .navigationDestination(isPresented: $showWeeklyCadences) {
                weeklyCadencesDestination
            }
            .navigationDestination(isPresented: $showRecommendedServices) {
                recommendedServicesDestination
            }
            // Phase 95 audit (Wave 5d) — household-level spend rollup
            // pushed from the InvestmentSummaryCard's "View home spend →"
            // link.
            .navigationDestination(isPresented: $showHouseholdSpend) {
                HouseholdSpendView()
            }
            // Phase 95 (gap #40) — sheet for the systems browse
            // surface. Sheet rather than nav destination because
            // the user typically taps once, adds a system, and
            // lands back on Property Detail with the new system
            // reflected.
            .sheet(isPresented: $showRecommendedSystems) {
                if let propId = viewModel.property?.id {
                    RecommendedSystemsView(propertyId: propId) {
                        Task { await viewModel.loadProperty(id: propId) }
                    }
                }
            }
    }

    private var propertyDetailCoreContent: some View {
        rootContent
            .navigationTitle(viewModel.property?.name ?? "Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    propertyToolbarMenu
                }
            }
            .trackScreen("PropertyDetailView", properties: ["property_id": propertyID.uuidString])
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPropertySection)) { notification in
                if let section = notification.userInfo?["section"] as? String {
                    handlePropertySectionNavigation(section)
                }
            }
            .task {
                await viewModel.loadProperty(id: propertyID)
                loadAttentionDismissals()
                checkSeasonCompletionBanner()
            }
            .onChange(of: viewModel.property?.householdId) { _, _ in
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
            .onReceive(NotificationCenter.default.publisher(for: .propertyChanged)) { _ in
                Task {
                    await viewModel.loadProperty(id: propertyID)
                    checkSeasonCompletionBanner()
                }
            }
            .onChange(of: viewModel.seasonCompletionState) { _, newState in
                if newState.isComplete && newState.totalVendorTasks > 0 {
                    SeasonCompletionBannerState.recordCompletion(newState)
                    if SeasonCompletionBannerState.shouldShow(newState) {
                        withAnimation(HavenTheme.animationCard) {
                            showSeasonCompletionBanner = true
                        }
                        Haptics.success()
                    }
                } else {
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
            .navigationDestination(item: $selectedSystemForDetail) { system in
                SystemDetailRowView(system: system)
            }
            .navigationDestination(item: $selectedSystemGroup) { group in
                SystemGroupListView(
                    group: group,
                    propertyId: propertyID,
                    householdId: viewModel.property?.householdId ?? UUID()
                )
            }
            .onAppear {
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
                editPropertySheetContent
            }
            .sheet(isPresented: $showDocumentUpload) {
                documentUploadSheetContent
            }
            .sheet(isPresented: $showProjectEmail) {
                NavigationStack {
                    ProjectEmailView()
                }
            }
            .sheet(item: $editingServiceRoutine) { routine in
                if let householdId = viewModel.property?.householdId {
                    NavigationStack {
                        RoutineEditSheet(
                            householdId: householdId,
                            propertyId: propertyID,
                            existing: routine,
                            onSaved: {
                                Task { await viewModel.loadProperty(id: propertyID) }
                            }
                        )
                    }
                }
            }
            .sheet(isPresented: $showAddService) {
                if let householdId = viewModel.property?.householdId {
                    NavigationStack {
                        RoutineEditSheet(
                            householdId: householdId,
                            propertyId: propertyID,
                            onSaved: {
                                Task { await viewModel.loadProperty(id: propertyID) }
                            }
                        )
                    }
                }
            }
            .sheet(isPresented: $showAddSystem) {
                addSystemSheetContent
            }
            .sheet(isPresented: $showAlfredChat) {
                alfredChatSheetContent
            }
            .sheet(isPresented: $showPrioritySystemsSheet) {
                prioritySystemsSheetContent
            }
            .sheet(isPresented: $showValueDetails) {
                valueDetailsSheetContent
            }
            .sheet(isPresented: $showReminderPicker) {
                reminderSheet
            }
    }

    @ViewBuilder
    private var editPropertySheetContent: some View {
        if let property = viewModel.property {
            EditPropertyView(property: property) { updatedProperty in
                viewModel.property = updatedProperty
                NotificationCenter.default.post(
                    name: .propertyChanged,
                    object: nil,
                    userInfo: ["action": "updated", "id": propertyID.uuidString]
                )
                Task { await viewModel.loadProperty(id: propertyID) }
            }
        }
    }

    private var documentUploadSheetContent: some View {
        DocumentUploadView(preselectedPropertyId: propertyID) {
            Task { await viewModel.loadProperty(id: propertyID) }
        }
    }

    private var addSystemSheetContent: some View {
        AddSystemView(propertyID: propertyID, onComplete: { newSystem in
            viewModel.systems.append(newSystem)
            Task { await viewModel.loadProperty(id: propertyID) }
        })
    }

    private var alfredChatSheetContent: some View {
        NavigationStack {
            ChatView(contextType: "property", contextId: propertyID)
        }
    }

    private var prioritySystemsSheetContent: some View {
        NavigationStack {
            prioritySystemsSheet
        }
    }

    @ViewBuilder
    private var valueDetailsSheetContent: some View {
        if let property = viewModel.property {
            NavigationStack {
                ScrollView {
                    InvestmentSummaryCard(
                        property: property,
                        totalProjectSpend: viewModel.totalProjectSpend,
                        inFlightProjectSpend: viewModel.inFlightProjectSpend,
                        onValuesUpdated: { update in
                            await viewModel.applyPropertyUpdate(update)
                        },
                        onRefreshFromPublicRecords: {
                            await viewModel.refreshFromPublicRecords(appState: appState)
                        }
                    )
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.vertical, HavenTheme.spacing16)
                }
                .background(HavenColors.background)
                .navigationTitle("Value & Equity")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showValueDetails = false }
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
            }
        }
    }

    private func editDueDateSheetContent(_ task: MaintenanceTaskDBRow) -> some View {
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
                        .foregroundStyle(HavenColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                id: task.id,
                                MaintenanceTaskUpdate(nextDueDate: formatter.string(from: editedTaskDueDate))
                            )
                            Task { await NotificationScheduler.shared.rescheduleAll() }
                            Haptics.success()
                            taskForDateEdit = nil
                            await viewModel.loadProperty(id: propertyID)
                        }
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func logPastServiceSheetContent(_ task: MaintenanceTaskDBRow) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("When did you last do \(task.title)?")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("Chez will recalculate the next due date based on the task frequency (\(task.frequency)).")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .multilineTextAlignment(.center)

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
                        .foregroundStyle(HavenColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let completedString = formatter.string(from: lastServicedTaskDate)
                            let nextDate = MaintenanceTaskDetailSheet.calculateNextDue(
                                frequency: task.frequency,
                                from: lastServicedTaskDate
                            )
                            let nextDueString = formatter.string(from: nextDate)

                            _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                id: task.id,
                                MaintenanceTaskUpdate(lastCompletedDate: completedString, nextDueDate: nextDueString)
                            )
                            if let systemId = task.systemId {
                                _ = try? await DatabaseService.shared.updateHomeSystem(
                                    id: systemId,
                                    HomeSystemUpdate(lastServiceDate: completedString, nextServiceDue: nextDueString)
                                )
                            }
                            Task { await NotificationScheduler.shared.rescheduleAll() }
                            Haptics.success()
                            taskForLastServiced = nil
                            await viewModel.loadProperty(id: propertyID)
                        }
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func maintenanceTaskSheetContent(_ task: MaintenanceTaskDBRow) -> some View {
        NavigationStack {
            MaintenanceTaskDetailSheet(task: task, onTaskCompleted: {
                Task { await viewModel.loadProperty(id: propertyID) }
            })
        }
        .presentationDetents([.medium, .large])
    }

    private var addVendorSheetContent: some View {
        AddVendorSheet(onComplete: {
            Task { await viewModel.loadProperty(id: propertyID) }
        })
    }

    @ViewBuilder
    private var addUtilitySheetContent: some View {
        if let property = viewModel.property {
            AddUtilitySheet(
                propertyId: property.id,
                householdId: property.householdId,
                preselectedType: addUtilityType
            ) { newAccount in
                viewModel.utilityAccounts.append(newAccount)
                Task { await viewModel.loadProperty(id: propertyID) }
            }
        }
    }

    private var coverageReviewSheetContent: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set service coverage")
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("\(maintenanceCoverageGapItems.count) system\(maintenanceCoverageGapItems.count == 1 ? "" : "s") need a preferred service path before Chez can coordinate the work.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(maintenanceCoverageGapItems) { item in
                        HavenCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: systemRecordIcon(item.system))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(HavenColors.navy700)
                                        .frame(width: 34, height: 34)
                                        .background(HavenColors.navy.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.system.displayName)
                                            .font(HavenTypography.body.weight(.semibold))
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Text(coverageGapSubtitle(for: item))
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(coverageGapReason(for: item))
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 0)
                                }

                                HStack(spacing: 8) {
                                    Menu {
                                        Button("Use existing vendor") {
                                            presentCoverageVendorPicker(for: item)
                                        }
                                        Button("Add vendor I already use") {
                                            presentCoverageVendorAdd(for: item)
                                        }
                                        if item.task != nil {
                                            Button("Ask Chez to source options") {
                                                presentCoverageSourceFlow(for: item)
                                            }
                                            Button("Move to handyman list") {
                                                moveCoverageGapToHandyman(item)
                                            }
                                        }
                                        Button("Open system") {
                                            openCoverageSystem(item)
                                        }
                                    } label: {
                                        Text("Review options")
                                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                            .foregroundStyle(HavenColors.textOnNavy)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(HavenColors.action)
                                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                                    }
                                    .buttonStyle(.plain)

                                    if let task = item.task {
                                        Button("View task") {
                                            showCoverageReview = false
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                selectedMaintenanceTask = task
                                            }
                                        }
                                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                        .foregroundStyle(HavenColors.navy700)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.vertical, HavenTheme.spacing16)
            }
            .background(HavenColors.background)
            .navigationTitle("Coverage gaps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showCoverageReview = false
                    }
                    .foregroundStyle(HavenColors.navy700)
                }
            }
        }
    }

    private func vendorAssignmentSheetContent(_ task: MaintenanceTaskDBRow) -> some View {
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

    @ViewBuilder
    private var browseSpecialtySheetContent: some View {
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

    @ViewBuilder
    private var weeklyCadencesDestination: some View {
        if let householdId = viewModel.property?.householdId {
            RoutinesListView(
                householdId: householdId,
                propertyId: propertyID
            )
        }
    }

    @ViewBuilder
    private var recommendedServicesDestination: some View {
        if let householdId = viewModel.property?.householdId {
            RecommendedServicesView(
                householdId: householdId,
                propertyId: propertyID
            )
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if viewModel.isLoading && viewModel.property == nil {
            ProgressView("Loading property...")
        } else if let property = viewModel.property {
            propertyContent(property)
        } else {
            ContentUnavailableView("Property not found", systemImage: "house")
        }
    }

    private var propertyToolbarMenu: some View {
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
            // Phase 95 (gap #55) — Delete Property hidden from
            // home managers and staff. RLS would block them
            // server-side, but suppressing the affordance up
            // front matches the role boundary documented in
            // CLAUDE.md and avoids an error-toast experience.
            if !appState.isStaffUser {
                Divider()
                Button(role: .destructive) {
                    Analytics.track(.propertyDeleted, ["property_id": propertyID.uuidString])
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Property", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    // MARK: - Main Content

    @State private var heroIsVisible = true

    private func propertyContent(_ property: PropertyRow) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                // Chez v1 enhanced hero — single indigo gradient header
                // shared by every sub-tab. Replaces the duplicate
                // address-row + compact-banner pattern from the previous
                // build.
                propertyHeroSection(property: property)

                Section {
                    switch activeTab {
                    case .overview:
                        overviewEnhancedDecisionsSection
                        overviewEnhancedValueSection(property: property)
                        overviewEnhancedComingUpSection(property: property)
                        // Phase 80 — Chez Concierge anchor on the Overview tab.
                        // Lives at the bottom of the overview after the upcoming
                        // timeline so it reads as "and if any of this is on your
                        // plate and you'd rather not — Chez handles it."
                        overviewChezConciergeAnchor(property: property)
                            .padding(.horizontal, HavenTheme.pageMargin)

                    case .systems:
                        systemCoverageSection
                        systemsBrowseGridSection
                        servicesSection

                    case .projects:
                        if viewModel.allProjects.isEmpty {
                            // Starter cards replace the legacy empty state.
                            projectsEnhancedEmptyState
                        }
                        // PropertyProjectsView ALWAYS renders so its
                        // `.onReceive(propertyProjectsRequestAdd)` listener
                        // and the new/log/options sheets stay attached.
                        // `hideEmptyState: true` suppresses its duplicate
                        // "No projects yet" + Add Project block when the
                        // starter cards are showing.
                        PropertyProjectsView(
                            propertyID: propertyID,
                            householdId: viewModel.property?.householdId,
                            propertyLocation: [viewModel.property?.city, viewModel.property?.state].compactMap { $0 }.joined(separator: ", "),
                            hideEmptyState: viewModel.allProjects.isEmpty
                        )
                        .padding(.horizontal, viewModel.allProjects.isEmpty ? 0 : HavenTheme.pageMargin)

                    case .vendors:
                        vendorsEnhancedSpendStrip
                        vendorsSection
                            .padding(.horizontal, HavenTheme.pageMargin)
                        if !viewModel.serviceRecords.isEmpty {
                            serviceHistorySection
                                .padding(.horizontal, HavenTheme.pageMargin)
                        }

                    case .documents:
                        documentsEnhancedVaultHero
                        PropertyDocumentsView(
                            propertyId: propertyID,
                            propertyName: viewModel.property?.name ?? "Property"
                        )
                        .padding(.horizontal, HavenTheme.pageMargin)
                    }
                } header: {
                    propertyTabBar
                        .background(HavenColors.background)
                }
            }
            .padding(.bottom, 120)
        }
        .coordinateSpace(name: "propertyScroll")
        .background(HavenColors.background)
        .overlay(alignment: .bottomTrailing) {
            // Camera FAB on the Systems sub-tab. Tapping launches the
            // existing EquipmentIdentifySheet (catalog search + Claude
            // Vision label-photo path); on identify we create a new
            // `home_systems` row directly with brand/model/serial
            // already populated, so the user goes from "no system on
            // file" to "identified system" in one step.
            if activeTab == .systems {
                systemPhotoFAB
                    .padding(.trailing, HavenTheme.spacing20)
                    .padding(.bottom, HavenTheme.spacing24)
            }
        }
        .overlay(alignment: .top) {
            if let toast = systemPhotoToast {
                Text(toast)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(.white)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.navy800)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
                    .padding(.top, HavenTheme.spacing24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSystemPhotoIdentify) {
            // No category constraint — the FAB is the catch-all path.
            // The identify response carries a catalog category which we
            // map onto a SystemCategory in `quickCreateSystemFromCatalog`.
            EquipmentIdentifySheet(systemCategory: nil) { result, detectedSerial in
                Task { await quickCreateSystemFromCatalog(result, detectedSerial: detectedSerial) }
            }
        }
        .sheet(isPresented: $showSystemPhotoOnboarding) {
            systemPhotoOnboardingSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showNeedsVendorTasks) {
            NeedsVendorTasksSheet(
                tasks: needsVendorTasksForDecisionCard,
                systems: viewModel.systems,
                onSelectTask: { task in
                    showNeedsVendorTasks = false
                    // Defer presentation so the parent's sheet dismiss
                    // animation completes before the task detail sheet
                    // pushes — otherwise SwiftUI silently drops it.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        selectedMaintenanceTask = task
                    }
                },
                onFindProForCategory: { group in
                    // Stash the category so the next sheet presentation
                    // (FindLocalVendorSheet) opens with the right
                    // systemCategory — adopting a vendor there auto-
                    // converts every needs_vendor task in this category
                    // via FindLocalVendorSheet's existing systemCategory
                    // matching pass.
                    showNeedsVendorTasks = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        seasonalFindVendorTask = nil
                        findProGroupCategory = group.categoryKey
                        findProGroupDisplayName = group.displayName
                        showFindProForGroup = true
                    }
                }
            )
        }
        .sheet(isPresented: $showSystemsMissingProfile) {
            SystemsMissingProfileSheet(
                entries: systemsMissingProfileEntries,
                onSelect: { system in
                    showSystemsMissingProfile = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        systemForProfileSetup = system
                    }
                }
            )
        }
        .sheet(item: $systemForProfileSetup) { system in
            NavigationStack {
                SystemDetailRowView(system: system)
            }
        }
        .sheet(isPresented: $showFindProForGroup) {
            // Category-level find-a-pro from the grouped vendor sheet.
            // FindLocalVendorSheet's adoption pass auto-converts every
            // needs_vendor task in the household whose system.category
            // matches `systemCategory`, so a single tap here turns
            // "5 HVAC tasks need a pro" into "5 HVAC tasks scheduled
            // with [Vendor]" — no per-task drill needed.
            if let property = viewModel.property,
               let category = findProGroupCategory,
               let displayName = findProGroupDisplayName {
                FindLocalVendorSheet(
                    task: nil,
                    householdId: property.householdId,
                    town: property.city ?? "",
                    state: property.state ?? "",
                    systemCategory: category,
                    categoryDisplayName: displayName,
                    onComplete: {
                        Task {
                            await MaintenanceViewModel.shared.loadTasks()
                            await viewModel.loadProperty(id: propertyID)
                        }
                        findProGroupCategory = nil
                        findProGroupDisplayName = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showSystemCoverageFlow) {
            if let property = viewModel.property {
                let unverified = SystemCoverageSummary.from(systems: viewModel.systems).unverifiedSystems
                SystemCoverageFlow(
                    systems: unverified,
                    property: property,
                    onComplete: {
                        Task { await viewModel.loadProperty(id: propertyID) }
                    }
                )
            }
        }
    }

    // MARK: - Camera FAB (Chez v1)

    private var systemPhotoFAB: some View {
        Button {
            Haptics.medium()
            // First-tap explainer (UserDefaults-gated). Re-entry skips
            // straight into the identify flow.
            let key = "systemPhotoFABOnboardingShown_v1"
            if UserDefaults.standard.bool(forKey: key) {
                showSystemPhotoIdentify = true
            } else {
                UserDefaults.standard.set(true, forKey: key)
                showSystemPhotoOnboarding = true
            }
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(HavenColors.textOnAction)
                .frame(width: 56, height: 56)
                .background(HavenColors.action)
                .clipShape(Circle())
                .shadow(color: HavenColors.action.opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Identify a system from a photo")
    }

    private var systemPhotoOnboardingSheet: some View {
        VStack(spacing: HavenTheme.spacing20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(HavenColors.action)
                .padding(.top, HavenTheme.spacing24)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Snap a model number")
                    .font(HavenTypography.fraunces(size: 22, weight: 700))
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Take a photo of the label on any system. Appliance, furnace, water heater, generator. Chez reads the model number and adds the system with brand, model, and serial filled in.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.spacing24)
            }

            Spacer()

            HavenButton(
                title: "Open camera",
                action: {
                    showSystemPhotoOnboarding = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showSystemPhotoIdentify = true
                    }
                },
                icon: "camera.fill",
                isFullWidth: true
            )
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, HavenTheme.spacing24)
        }
        .background(HavenColors.background)
    }

    /// Maps a catalog `EquipmentSearchResult` straight onto a new
    /// `home_systems` row. The catalog category name (e.g. "Dishwasher",
    /// "Furnace", "Water Heater") becomes the system subtype, and we
    /// roll up to the canonical `SystemCategory` for the row category.
    /// Falls back to "Other" with the catalog name as `customCategoryName`
    /// when no roll-up exists, so nothing is silently dropped.
    private func quickCreateSystemFromCatalog(
        _ result: EquipmentSearchResult,
        detectedSerial: String?
    ) async {
        guard let property = viewModel.property else { return }
        let resolved = resolveSystemCategory(forCatalogCategoryName: result.category.name)

        var insert = HomeSystemInsert(
            propertyId: property.id,
            householdId: property.householdId,
            name: result.displayName,
            category: resolved.category
        )
        insert.manufacturer = result.manufacturer.name
        insert.modelNumber = result.modelNumber
        insert.serialNumber = detectedSerial
        insert.expectedLifespanYears = result.specs.expectedLifespanYears
        insert.catalogEntryId = result.id
        insert.subtype = result.category.name
        insert.customCategoryName = resolved.customCategoryName

        do {
            _ = try await DatabaseService.shared.createHomeSystem(insert)
            await viewModel.loadProperty(id: propertyID)
            await MainActor.run {
                Haptics.success()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    systemPhotoToast = "Added \(result.displayName)"
                }
            }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation { systemPhotoToast = nil }
            }
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        } catch {
            await MainActor.run {
                Haptics.error()
                systemPhotoToast = "Couldn't add: \(error.localizedDescription)"
            }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run { systemPhotoToast = nil }
        }
    }

    /// Maps a catalog category name (open-ended — comes from the
    /// equipment catalog, can be anything) onto a canonical
    /// `SystemCategory` raw value plus an optional `customCategoryName`
    /// override. Order matters: more specific keywords first.
    private func resolveSystemCategory(forCatalogCategoryName name: String) -> (category: String, customCategoryName: String?) {
        let lower = name.lowercased()
        // Appliance roll-up — the catalog has a long list of these.
        let applianceKeywords = [
            "dishwasher", "refrigerator", "fridge", "oven", "range",
            "cooktop", "microwave", "washer", "dryer", "freezer",
            "wine cooler", "wine fridge", "ice maker", "garbage disposal",
            "hood", "rangehood", "vent hood", "wall oven", "double oven",
            "stove",
        ]
        if applianceKeywords.contains(where: { lower.contains($0) }) {
            return ("Appliance", nil)
        }
        // Climate / HVAC roll-up.
        if lower.contains("furnace") || lower.contains("boiler")
            || lower.contains("heat pump") || lower.contains("mini-split")
            || lower.contains("mini split") || lower.contains("air handler")
            || lower.contains("thermostat") || lower.contains("ductwork") {
            return ("HVAC", nil)
        }
        if lower.contains("air condition") || lower.contains("a/c")
            || lower.contains("central air") {
            return ("Air Conditioning", nil)
        }
        if lower.contains("water heater") || lower.contains("tankless") {
            return ("Water Heater", nil)
        }
        if lower.contains("generator") { return ("Generator", nil) }
        if lower.contains("solar") { return ("Solar", nil) }
        if lower.contains("sump") || lower.contains("septic") {
            return ("Plumbing", nil)
        }
        if lower.contains("garage") { return ("Garage Door", nil) }
        if lower.contains("ev charger") || lower.contains("evse") {
            return ("Electrical", nil)
        }
        // Falls through to the "Other" bucket so the row still lands;
        // the user can re-categorize from the system detail page.
        return ("Other", name)
    }

    // MARK: - Chez v1 enhanced hero

    private func propertyHeroSection(property: PropertyRow) -> some View {
        PropertyHeroHeader(
            eyebrow: heroEyebrow(for: property),
            title: heroTitle(for: property),
            subtitle: heroSubtitle(for: property),
            estimatedValue: property.currentEstimatedValue,
            systemsCount: viewModel.systems.count,
            prioritiesCount: prioritiesCount
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func heroEyebrow(for property: PropertyRow) -> String {
        if appState.primaryProperty?.id == property.id {
            return "Primary residence"
        }
        return property.propertyType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func heroTitle(for property: PropertyRow) -> String {
        property.street ?? property.name
    }

    private func heroSubtitle(for property: PropertyRow) -> String {
        let typeLabel = property.propertyType
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        let location = [property.city, property.state]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        if location.isEmpty { return typeLabel }
        return "\(typeLabel) · \(location)"
    }

    /// Tasks that genuinely need a separate vendor decision. Excludes:
    ///   - bundle children (`bundle_parent_task_id != nil`) — handled
    ///     by the bundle parent task
    ///   - routine-parented tasks (`parent_routine_id != nil`) — the
    ///     routine itself owns vendor capture
    ///   - handyman-category tasks (Spring/Fall Handyman Visit + the
    ///     bundle children that resolve to "Handyman") — the Handyman
    ///     tab in Tasks is the canonical front door for handyman
    ///     vendor capture, surfacing them here is duplication
    /// Used by both the "Priorities" hero count and the decision-card
    /// list so the number always matches what the user sees on tap.
    private var needsVendorTasksForDecisionCard: [MaintenanceTaskDBRow] {
        let systemsLookup = Dictionary(uniqueKeysWithValues: viewModel.systems.map { ($0.id, $0) })
        return viewModel.maintenanceTasks.filter { task in
            guard task.needsVendor == true else { return false }
            guard task.bundleParentTaskId == nil else { return false }
            guard task.parentRoutineId == nil else { return false }
            // Resolve to canonical category and skip handyman work —
            // those flow through the dedicated Handyman tab.
            let category = VendorTaskGrouping.resolveCanonicalCategory(
                for: task,
                systemsLookup: systemsLookup
            )
            if category == "Handyman" { return false }
            return true
        }
    }

    /// "Priorities" count rendered in the hero's third stat. Counts:
    ///   - tasks needing a vendor decision (`needs_vendor == true`)
    ///   - overdue tasks not already counted
    ///   - systems missing a primary vendor (a proxy for "needs profile")
    private var prioritiesCount: Int {
        let needsVendorTasks = needsVendorTasksForDecisionCard
        let overdueIds = Set(viewModel.overdueTasks.map { $0.id })
        let needsVendorIds = Set(needsVendorTasks.map { $0.id })
        let extraOverdue = overdueIds.subtracting(needsVendorIds).count
        let systemsMissing = viewModel.systems.filter {
            $0.preferredContractorId == nil
        }.count
        return needsVendorTasks.count + extraOverdue + systemsMissing
    }

    /// Systems whose `SystemProfileAudit` checklist is non-empty AND
    /// aren't service-shaped rows (services live in routines now).
    /// Cached as a computed property so the count, preview, and the
    /// "Set up" sheet entries all read from the same list.
    private var systemsMissingProfileEntries: [SystemsMissingProfileSheet.Entry] {
        viewModel.systems
            .filter { !SystemGroup.isServiceCategory($0.category) }
            .filter { $0.parentSystemId == nil }
            .compactMap { system -> SystemsMissingProfileSheet.Entry? in
                let warrantiesForSystem = viewModel.warranties.filter { $0.systemId == system.id }
                let recordsForSystem = viewModel.serviceRecords.filter { $0.systemId == system.id }
                let missing = SystemProfileAudit.missingItems(
                    for: system,
                    warranties: warrantiesForSystem,
                    serviceRecords: recordsForSystem
                )
                guard !missing.isEmpty else { return nil }
                return SystemsMissingProfileSheet.Entry(
                    system: system,
                    missingTitles: missing.map { $0.title }
                )
            }
    }

    private var systemsMissingProfileCount: Int {
        systemsMissingProfileEntries.count
    }

    private var systemsMissingProfilePreview: String {
        systemsMissingProfileEntries
            .prefix(3)
            .map { $0.system.name }
            .joined(separator: " · ")
    }

    // MARK: - Chez v1 Overview — Needs your decision

    @ViewBuilder
    private var overviewEnhancedDecisionsSection: some View {
        // Use the same filtered list everywhere so the count on the
        // card always matches what the user sees when they tap in.
        let needsVendor = needsVendorTasksForDecisionCard
        let missingProfile = systemsMissingProfileCount

        // Hide the section entirely when nothing needs a decision —
        // an empty "Needs your decision" card would read as confusing.
        if !needsVendor.isEmpty || missingProfile > 0 {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                PropertyEnhancedSectionHeader(title: "Needs your decision", sub: "What needs you")

                VStack(spacing: HavenTheme.spacing8) {
                    if let firstNeedsVendor = needsVendor.first {
                        PropertyDecisionCard(
                            title: needsVendor.count == 1
                                ? "Pick a vendor for \(firstNeedsVendor.title.lowercased())"
                                : "\(needsVendor.count) tasks need a vendor",
                            subtitle: decisionVendorSubtitle(for: firstNeedsVendor, total: needsVendor.count),
                            cta: needsVendor.count == 1 ? "Find a pro" : "Review",
                            subdued: false,
                            onTap: {
                                if needsVendor.count == 1 {
                                    // Single task — drill straight in
                                    // (preserves existing behavior).
                                    selectedMaintenanceTask = firstNeedsVendor
                                } else {
                                    // Multi-task — show the full list so
                                    // the user doesn't have to repeat the
                                    // tap N times.
                                    showNeedsVendorTasks = true
                                }
                            }
                        )
                    }

                    if missingProfile > 0 {
                        PropertyDecisionCard(
                            title: "\(missingProfile) system\(missingProfile == 1 ? "" : "s") missing profile",
                            subtitle: systemsMissingProfilePreview.isEmpty
                                ? "Add a vendor and basic details so Chez can plan service"
                                : systemsMissingProfilePreview,
                            cta: "Set up",
                            subdued: !needsVendor.isEmpty,
                            onTap: {
                                showSystemsMissingProfile = true
                            }
                        )
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }
            .padding(.top, HavenTheme.spacing8)
        }
    }

    private func decisionVendorSubtitle(for task: MaintenanceTaskDBRow, total: Int) -> String {
        let label = MaintenanceDateFormatting.dueLabel(for: task.scheduledDate ?? task.nextDueDate)
        if total > 1 {
            return "\(label) · \(total) quotes ready to review"
        }
        return "\(label) · find a vetted pro"
    }

    // MARK: - Chez v1 Overview — Value & Equity

    /// Surfaces the existing `InvestmentSummaryCard` directly in the
    /// Overview scroll (instead of behind a "Value & Equity" sheet). Shows
    /// the home's estimated value, gain/loss vs purchase, project spend
    /// stacked bar, net-after-sale, equity upsell, and the sale simulator
    /// CTA — same data as before, just one tap closer.
    @ViewBuilder
    private func overviewEnhancedValueSection(property: PropertyRow) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            PropertyEnhancedSectionHeader(
                title: "Value & equity",
                sub: property.currentEstimatedValue == nil
                    ? "Add an estimate"
                    : "Track returns + capital gains"
            )

            InvestmentSummaryCard(
                property: property,
                totalProjectSpend: viewModel.totalProjectSpend,
                inFlightProjectSpend: viewModel.inFlightProjectSpend,
                onValuesUpdated: { update in
                    await viewModel.applyPropertyUpdate(update)
                },
                onRefreshFromPublicRecords: {
                    await viewModel.refreshFromPublicRecords(appState: appState)
                }
            )
            .padding(.horizontal, HavenTheme.pageMargin)

            // Phase 95 audit (Wave 5d) — household-level spend rollup.
            // Aggregates invoices + service records across every vendor
            // so the homeowner can see "what did I spend on home this
            // year" by vendor or by category. Per-vendor breakdown only
            // existed on ContractorDetailView pre-Phase-95.
            Button {
                Haptics.light()
                showHouseholdSpend = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 14, weight: .semibold))
                    Text("View home spend this year")
                        .font(HavenTypography.uiButton)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .foregroundStyle(HavenColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                        .stroke(HavenColors.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, HavenTheme.pageMargin)
        }
    }

    // MARK: - Chez v1 Overview — Coming up

    /// Phase 80 — Chez Concierge anchor on the Overview tab. Universal
    /// "anything on your plate? Chez handles it" surface. Context dict
    /// names the property + its town/state so Tom has the geography
    /// without opening another tab.
    private func overviewChezConciergeAnchor(property: PropertyRow) -> some View {
        var ctx: [String: String] = [
            "property_id": property.id.uuidString,
            "property_name": property.name,
        ]
        if let town = property.city, !town.isEmpty { ctx["town"] = town }
        if let state = property.state, !state.isEmpty { ctx["state"] = state }
        return ChezEntryButton(
            category: .general,
            label: "Have Chez handle anything for you",
            caption: "Vendor finds, scheduling, quotes, follow-ups. Chez owns it.",
            context: ctx
        )
    }

    @ViewBuilder
    private func overviewEnhancedComingUpSection(property: PropertyRow) -> some View {
        let upcoming = viewModel.upcomingTasks.prefix(4)
        if upcoming.isEmpty == false {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                PropertyEnhancedSectionHeader(
                    title: "Coming up",
                    sub: comingUpMonthLabel,
                    actionLabel: "View plan",
                    onAction: {
                        NotificationCenter.default.post(
                            name: .switchToTab,
                            object: nil,
                            userInfo: ["tab": 2]
                        )
                    }
                )

                PropertyTimelineCard {
                    let rows = Array(upcoming.enumerated())
                    ForEach(rows, id: \.element.id) { idx, task in
                        PropertyTimelineRow(
                            dayNumber: timelineDay(for: task),
                            monthLabel: timelineMonth(for: task),
                            title: task.title,
                            meta: timelineMeta(for: task),
                            metaIsSalmon: task.needsVendor == true,
                            onTap: {
                                selectedMaintenanceTask = task
                            }
                        )
                        if idx < rows.count - 1 {
                            PropertyTimelineDivider()
                        }
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }
        }
    }

    private var comingUpMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private func timelineDay(for task: MaintenanceTaskDBRow) -> String {
        guard let date = MaintenanceDateFormatting.date(from: task.scheduledDate ?? task.nextDueDate) else {
            return "—"
        }
        return String(Calendar.current.component(.day, from: date))
    }

    private func timelineMonth(for task: MaintenanceTaskDBRow) -> String {
        guard let date = MaintenanceDateFormatting.date(from: task.scheduledDate ?? task.nextDueDate) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private func timelineMeta(for task: MaintenanceTaskDBRow) -> String {
        if task.needsVendor == true {
            return "Needs vendor"
        }
        if let contractorId = task.assignedContractorId,
           let contractor = viewModel.contractors.first(where: { $0.id == contractorId }) {
            return contractor.companyName
        }
        if task.assignmentType?.lowercased() == "vendor" {
            return "Vendor task"
        }
        return "You"
    }

    // MARK: - Chez v1 Projects — Editorial empty state + 3 starter rows

    private var projectsEnhancedEmptyState: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            PropertyEditorialBlurb(
                title: "Big work, kept together.",
                copy: "Quotes, contractors, photos, warranties. Chez files them under one project so you can find them when it matters."
            )

            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                PropertyEnhancedSectionHeader(title: "Start a project")

                VStack(spacing: HavenTheme.spacing8) {
                    PropertyProjectStarterRow(
                        title: "Plan something new",
                        subtitle: "Renovation, addition, replacement",
                        cta: "Start",
                        tone: .hero,
                        onTap: {
                            NotificationCenter.default.post(
                                name: .propertyProjectsRequestAdd,
                                object: nil,
                                userInfo: ["mode": "plan"]
                            )
                        }
                    )
                    PropertyProjectStarterRow(
                        title: "Log past project",
                        subtitle: "Bring history forward",
                        cta: "Upload",
                        tone: .standard,
                        onTap: {
                            // Past-project logging is document-driven: the
                            // user uploads receipts / quotes / photos and
                            // Chez stitches them into a project record.
                            // DocumentUploadView is pre-scoped to this
                            // property so anything they add lands on the
                            // right home.
                            showDocumentUpload = true
                        }
                    )
                    PropertyProjectStarterRow(
                        title: "Import from email",
                        subtitle: "We'll pull contractor threads",
                        cta: "Connect",
                        tone: .standard,
                        onTap: {
                            // Land on the household's forwarding address
                            // (`*@alfred.havenhome.dev`) so the user can
                            // copy it and start forwarding contractor
                            // threads. Email-driven import is the existing
                            // flow; this is the discovery hop.
                            showProjectEmail = true
                        }
                    )
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }
        }
    }

    // MARK: - Chez v1 Vendors — Spend strip

    @ViewBuilder
    private var vendorsEnhancedSpendStrip: some View {
        let recurring = recurringMonthlySpend
        let yearTotal = yearToDateSpend
        // Hide entirely when there's nothing to display — empty stats
        // would read as broken data.
        if recurring != nil || yearTotal != nil {
            PropertyVendorSpendStrip(
                recurringMonthly: recurring,
                yearToDate: yearTotal
            )
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, HavenTheme.spacing4)
        }
    }

    /// Year-to-date sum of `service_records.cost` rows whose
    /// `service_date` falls in the current calendar year. Returns nil
    /// when zero so the spend strip can hide the column.
    private var yearToDateSpend: Double? {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let total = viewModel.serviceRecords.reduce(0.0) { running, record in
            guard let cost = record.cost else { return running }
            guard let date = formatter.date(from: record.serviceDate) else { return running }
            guard cal.component(.year, from: date) == currentYear else { return running }
            return running + cost
        }
        return total > 0 ? total : nil
    }

    /// Rough recurring-monthly estimate. Sums `service_records.cost`
    /// for the trailing 12 months, then divides by 12. Not perfect —
    /// future iteration: read recurring cost off active routines.
    private var recurringMonthlySpend: Double? {
        let cal = Calendar.current
        let now = Date()
        guard let twelveMonthsAgo = cal.date(byAdding: .month, value: -12, to: now) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let total = viewModel.serviceRecords.reduce(0.0) { running, record in
            guard let cost = record.cost else { return running }
            guard let date = formatter.date(from: record.serviceDate) else { return running }
            guard date >= twelveMonthsAgo else { return running }
            return running + cost
        }
        guard total > 0 else { return nil }
        return total / 12
    }

    // MARK: - Chez v1 Documents — Vault hero + suggested rows

    @ViewBuilder
    private var documentsEnhancedVaultHero: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            PropertyDocumentVaultHero(
                uploadedCount: viewModel.linkedDocuments.count,
                suggestedCount: enhancedSuggestedDocuments.count,
                accessRolesCount: 0,
                onUpload: {
                    showDocumentUpload = true
                },
                onScan: {
                    // Standard upload sheet covers scan via the system
                    // photo picker; future: route directly to a document
                    // scanner sheet.
                    showDocumentUpload = true
                }
            )
            .padding(.horizontal, HavenTheme.pageMargin)

            if !enhancedSuggestedDocuments.isEmpty {
                PropertyEnhancedSectionHeader(
                    title: "Suggested",
                    sub: "One tap to start"
                )
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(enhancedSuggestedDocuments) { suggestion in
                        PropertyDocumentSuggestedRow(
                            iconSystemName: suggestion.icon,
                            title: suggestion.title,
                            subtitle: suggestion.subtitle,
                            onAdd: {
                                showDocumentUpload = true
                            }
                        )
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }
        }
    }

    /// A small, curated set of documents we suggest the user upload
    /// when their vault is empty or sparse. Filtered against linked
    /// documents so we don't suggest something they already have.
    private var enhancedSuggestedDocuments: [PropertyDocumentSuggestion] {
        let existing = Set(viewModel.linkedDocuments.map { $0.category.lowercased() })
        return PropertyDocumentSuggestion.curated.filter { suggestion in
            !existing.contains(where: { $0.contains(suggestion.matchKey) })
        }
    }

    // MARK: - Chez v1 Systems — Browse grid

    /// Chez v1: gamified install-date coverage card. Renders at the
    /// top of the Systems sub-tab when at least one system is missing
    /// an install_date_source. Hidden once every system is verified —
    /// no point in nagging the user when they're done.
    @ViewBuilder
    private var systemCoverageSection: some View {
        let summary = SystemCoverageSummary.from(systems: viewModel.systems)
        if summary.totalCount > 0, summary.percentComplete < 100 {
            SystemCoverageCard(summary: summary) {
                showSystemCoverageFlow = true
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing8)
        }
    }

    @ViewBuilder
    private var systemsBrowseGridSection: some View {
        // Filter out service-typed rows (pet waste, snow removal, pest
        // control, etc.) — those live in the Services section. The Systems
        // grid is for physical equipment with brand/model/serial only.
        let physicalSystems = viewModel.systems.filter {
            !SystemGroup.isServiceCategory($0.category)
        }
        let totalSystems = physicalSystems.count
        let needsProfile = physicalSystems.filter { $0.preferredContractorId == nil }.count
        // Use the canonical `SystemGroup` model so tapping a tile lands on
        // the existing `SystemGroupListView` via the `selectedSystemGroup`
        // navigationDestination (defined ~line 319). `SystemGroup.group`
        // emits only non-empty buckets so the grid auto-shrinks for sparse
        // properties.
        let groups = SystemGroup.group(physicalSystems)

        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            PropertyEnhancedSectionHeader(
                title: "Browse",
                sub: "\(totalSystems) systems\(needsProfile > 0 ? " · \(needsProfile) need profile" : "")",
                actionLabel: "Add system",
                onAction: {
                    showAddSystem = true
                }
            )

            if groups.isEmpty {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text("No systems on this property yet.")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary)
                        HavenButton(
                            title: "Add your first system",
                            action: { showAddSystem = true },
                            icon: "plus",
                            isFullWidth: true
                        )
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(groups) { group in
                        let needsAttention = group.systems.contains { $0.preferredContractorId == nil }
                        PropertySystemsCategoryTile(
                            icon: group.icon,
                            title: group.name,
                            systemCount: group.systems.count,
                            needsAttention: needsAttention,
                            onTap: {
                                selectedSystemGroup = group
                            }
                        )
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }
        }
    }

    // MARK: - Chez v1 Services section (vendor-managed recurring services)

    /// `RoutineKind` cases that are always services (recurring vendor
    /// visits) regardless of whether the user has linked a vendor yet.
    /// These read as services even when in pending-vendor state because
    /// the user shouldn't have to think "is pest control a service?".
    private static let serviceRoutineKindRawValues: Set<String> = [
        "cleaning",
        "landscaping",
        "pool_service",
        "pest_control",
        "pet_waste",
        "mosquito_tick",
        "snow_removal",
        "gutter_cleaning",
        "window_cleaning",
        "tree_service",
        "handyman_recurring",
        "other_service",
    ]

    /// `RoutineKind` cases that CAN be vendor-backed (a private trash
    /// hauler, a recurring delivery driver) but often aren't (municipal
    /// trash pickup with no vendor). When a vendor is linked, treat them
    /// as services so they surface here. Without a vendor they remain
    /// pure household cadences and live on the Tasks tab routines list.
    private static let vendorOptionalRoutineKindRawValues: Set<String> = [
        "trash",
        "recycling",
        "compost",
        "yard_waste",
        "recurring_delivery",
    ]

    private var serviceRoutines: [RoutineRow] {
        let active = viewModel.routines
            .filter { $0.archivedAt == nil }
            .filter { routine in
                if Self.serviceRoutineKindRawValues.contains(routine.routineKind) {
                    return true
                }
                // Vendor-backed cadence (e.g. private trash hauler with a
                // contractor row attached) reads as a service.
                if Self.vendorOptionalRoutineKindRawValues.contains(routine.routineKind),
                   routine.vendorId != nil {
                    return true
                }
                return false
            }

        // Dedupe by `routineKind`: when the user has a real routine with a
        // vendor linked (e.g. Village Exterminating · Pest control), hide
        // any "Pick a pro for X" placeholder of the same kind. Day1Curator
        // creates pending-vendor placeholders to make recommended services
        // discoverable, but they read as duplicates once the user has
        // captured the actual service provider.
        var byKind: [String: RoutineRow] = [:]
        for routine in active {
            let key = routine.routineKind
            guard let existing = byKind[key] else {
                byKind[key] = routine
                continue
            }
            if rank(routine) > rank(existing) {
                byKind[key] = routine
            }
        }

        return byKind.values.sorted { lhs, rhs in
            // Sort by display label so the user reads the same order
            // every visit.
            let lhsLabel = lhs.label.isEmpty ? lhs.routineKind : lhs.label
            let rhsLabel = rhs.label.isEmpty ? rhs.routineKind : rhs.label
            return lhsLabel.localizedCaseInsensitiveCompare(rhsLabel) == .orderedAscending
        }
    }

    /// Higher rank wins when two routines share a `routineKind`.
    /// Active + vendor > active > pending_vendor + vendor > pending_vendor / draft.
    private func rank(_ routine: RoutineRow) -> Int {
        let hasVendor = routine.vendorId != nil
        switch (routine.setupState, hasVendor) {
        case ("active", true):          return 4
        case ("active", false):         return 3
        case ("pending_vendor", true):  return 2
        case ("pending_vendor", false): return 1
        default:                        return 0
        }
    }

    @ViewBuilder
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            PropertyEnhancedSectionHeader(
                title: "Services",
                sub: "Recurring vendor visits",
                actionLabel: "Add service",
                onAction: {
                    showAddService = true
                }
            )

            if serviceRoutines.isEmpty {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text("No services on this property yet.")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("Lawn care, cleaning, pest control, snow removal, pool service. Anything that comes on a schedule with a vendor.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSoft)
                        HavenButton(
                            title: "Add your first service",
                            action: { showAddService = true },
                            icon: "plus",
                            isFullWidth: true
                        )
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            } else {
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(serviceRoutines) { routine in
                        serviceRoutineRow(routine)
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }
        }
        .padding(.top, HavenTheme.spacing8)
    }

    private func serviceRoutineRow(_ routine: RoutineRow) -> some View {
        let kindLabel = RoutineKind(rawValue: routine.routineKind)?.displayLabel ?? routine.routineKind
        let displayTitle = routine.label.isEmpty ? kindLabel : routine.label
        let vendor = viewModel.contractors.first { $0.id == routine.vendorId }
        return Button {
            Haptics.light()
            editingServiceRoutine = routine
        } label: {
            HavenCard(padding: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing12) {
                    if let vendor {
                        VendorLogoView(contractor: vendor, size: 36)
                    } else {
                        Image(systemName: serviceRoutineIcon(routine.routineKind))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(HavenColors.navy)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .fill(HavenColors.indigo50)
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayTitle)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Text(serviceRoutineSubtitle(routine: routine, vendor: vendor, kindLabel: kindLabel))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textSoft)
                }
            }
        }
        .buttonStyle(HavenButtonPressStyle())
    }

    private func serviceRoutineSubtitle(routine: RoutineRow, vendor: ContractorRow?, kindLabel: String) -> String {
        var parts: [String] = []
        if vendor == nil {
            parts.append(kindLabel)
        } else {
            parts.append(kindLabel)
        }
        let cadence = serviceRoutineCadence(routine)
        if !cadence.isEmpty {
            parts.append(cadence)
        }
        return parts.joined(separator: " · ")
    }

    private func serviceRoutineCadence(_ routine: RoutineRow) -> String {
        switch routine.cadenceType.lowercased() {
        case "weekly": return "Weekly"
        case "biweekly": return "Biweekly"
        case "triweekly": return "Every 3 weeks"
        case "monthly": return "Monthly"
        case "quarterly": return "Quarterly"
        case "annual", "annually": return "Annually"
        case "custom_days":
            if let interval = routine.cadenceIntervalDays, interval > 0 {
                return "Every \(interval) days"
            }
            return "Custom cadence"
        default:
            return routine.cadenceType.capitalized
        }
    }

    private func serviceRoutineIcon(_ kind: String) -> String {
        switch kind {
        case "cleaning": return "sparkles"
        case "landscaping": return "leaf.fill"
        case "pool_service": return "drop.fill"
        case "pest_control": return "ant.fill"
        case "pet_waste": return "pawprint.fill"
        case "mosquito_tick": return "ladybug.fill"
        case "snow_removal": return "snowflake"
        case "gutter_cleaning": return "drop.degreesign"
        case "window_cleaning": return "rectangle.split.2x2.fill"
        case "tree_service": return "tree.fill"
        case "handyman_recurring": return "hammer.fill"
        default: return "calendar.badge.clock"
        }
    }

    // MARK: - Header

    private func propertyHeader(_ property: PropertyRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.street ?? property.name)
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(propertyHeroSubtitle(property))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    if let value = property.currentEstimatedValue, value > 0 {
                        Text(value.formattedCompactCurrency())
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                    } else {
                        Image(systemName: "house.fill")
                            .font(.title)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }

                Button {
                    showAlfredChat = true
                } label: {
                    HStack(spacing: 6) {
                        AlfredLogoView(size: 20)
                        Text("Ask Alfred about this property")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(.horizontal, HavenTheme.spacing8)
                    .padding(.vertical, 7)
                        .background(HavenColors.navy.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                }
                .buttonStyle(.plain)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        propertyPromptChip(
                            overviewAttentionAreaCount > 0 ? "Review \(overviewAttentionAreaCount) priorities" : "What needs attention?",
                            accent: overviewAttentionAreaCount > 0 ? HavenColors.action : HavenColors.navy700,
                            highlighted: overviewAttentionAreaCount > 0
                        )
                        propertyPromptChip("Missing coverage")
                        propertyPromptChip("Upload checklist")
                    }
                }
            }
        }
    }

    private func propertyPromptChip(
        _ prompt: String,
        accent: Color = HavenColors.navy700,
        highlighted: Bool = false
    ) -> some View {
        Button {
            showAlfredChat = true
        } label: {
            Text(prompt)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(highlighted ? accent.opacity(0.12) : HavenColors.navy.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

    private var propertyTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(PropertyDetailTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeTab = tab
                        }
                        Analytics.track(.propertyTabSelected, ["tab": tab.title, "property_id": propertyID.uuidString])
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab.title)
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(activeTab == tab ? HavenColors.navy800 : HavenColors.textTertiary)
                            Capsule()
                                .fill(activeTab == tab ? HavenColors.navy800 : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            // Page margin so the first tab ("Overview") aligns with the
            // section content underneath instead of hugging the screen edge.
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, 2)
        }
    }

    private var topLevelSystems: [HomeSystemRow] {
        viewModel.systems.filter { $0.parentSystemId == nil }
    }

    private var activeProjects: [PropertyProjectRow] {
        viewModel.allProjects.filter { $0.status == "planning" || $0.status == "in_progress" }
    }

    private var vendorCoverageCounts: (covered: Int, uncovered: Int) {
        let coverage = SystemCategoryRegistry.vendorCoverageItems(
            existingSystems: viewModel.systems,
            contractors: viewModel.contractors,
            vendorTasks: viewModel.maintenanceTasks.filter {
                $0.vehicleId == nil && $0.assignmentType?.lowercased() == "vendor"
            }
        )
        return (coverage.covered.count, coverage.uncovered.count)
    }

    private var identifiedSystemCount: Int {
        topLevelSystems.filter(isSystemIdentified).count
    }

    private var systemsMissingInfoCount: Int {
        topLevelSystems.filter(systemNeedsInfo).count
    }

    private var overviewUpcomingItems: [MaintenanceTaskDBRow] {
        viewModel.maintenanceTasks
            .filter { task in
                guard task.vehicleId == nil else { return false }
                guard let date = isoDateFormatter.date(from: task.nextDueDate) else { return false }
                return date >= Calendar.current.startOfDay(for: Date())
            }
            .sorted { $0.nextDueDate < $1.nextDueDate }
            .prefix(3)
            .map { $0 }
    }

    private var propertyUpcomingVisits: [MaintenanceTaskDBRow] {
        viewModel.vendorVisitTasks.prefix(3).map { $0 }
    }

    private var nextMeaningfulVisit: MaintenanceTaskDBRow? {
        overviewUpcomingItems.first
    }

    private var groupedSystems: [SystemGroup] {
        SystemGroup.group(viewModel.systems)
    }

    private var systemAttentionItems: [HomeSystemRow] {
        topLevelSystems
            .filter(systemNeedsAttention)
            .sorted { systemPriorityScore($0) > systemPriorityScore($1) }
    }

    private var systemsNeedingVendorCount: Int {
        vendorCoverageCounts.uncovered
    }

    private var highPrioritySystemsToIdentify: [HomeSystemRow] {
        topLevelSystems
            .filter(systemNeedsInfo)
            .sorted { systemPriorityScore($0) > systemPriorityScore($1) }
            .prefix(6)
            .map { $0 }
    }

    private var completeSystemProfileCount: Int {
        topLevelSystems.filter(isSystemProfileComplete).count
    }

    private var maintenanceLinkedSystemCount: Int {
        topLevelSystems.filter(isSystemLinkedToMaintenance).count
    }

    private var maintenanceCoverageGapItems: [CoverageGapItem] {
        let unresolvedVendorTasks = viewModel.maintenanceTasks
            .filter { task in
                guard task.vehicleId == nil else { return false }
                let isVendorTask = task.assignmentType?.lowercased() == "vendor" || task.assignedRoute == "vendor" || task.needsVendor == true
                guard isVendorTask else { return false }
                return task.assignedContractorId == nil
            }
            .sorted { ($0.scheduledDate ?? $0.nextDueDate) < ($1.scheduledDate ?? $1.nextDueDate) }

        return topLevelSystems
            .filter(systemNeedsVendor)
            .sorted { systemPriorityScore($0) > systemPriorityScore($1) }
            .map { system in
                CoverageGapItem(
                    system: system,
                    task: unresolvedVendorTasks.first(where: { $0.systemId == system.id })
                )
            }
    }

    private var maintenanceUpcomingItems: [MaintenanceTaskDBRow] {
        viewModel.maintenanceTasks
            .filter { task in
                guard task.vehicleId == nil else { return false }
                guard let date = isoDateFormatter.date(from: task.scheduledDate ?? task.nextDueDate) else { return false }
                return date >= Calendar.current.startOfDay(for: Date())
            }
            .sorted { ($0.scheduledDate ?? $0.nextDueDate) < ($1.scheduledDate ?? $1.nextDueDate) }
            .prefix(3)
            .map { $0 }
    }

    private var maintenanceTasksForYouCount: Int {
        viewModel.diyTasksForMaintenanceTab.count
    }

    private var maintenanceServicePlanCount: Int {
        vendorCoverageCounts.covered
    }

    private var maintenancePriorityCoverageItems: [CoverageGapItem] {
        Array(maintenanceCoverageGapItems.prefix(3))
    }

    private var maintenanceBriefHeadline: String {
        if maintenanceCoverageGapItems.isEmpty {
            return "Maintenance is on track"
        }
        let count = maintenancePriorityCoverageItems.count
        return "\(count) priority system\(count == 1 ? "" : "s") need review"
    }

    private var maintenanceBriefSummary: String {
        if maintenanceCoverageGapItems.isEmpty {
            return "Chez is handling recurring services, upcoming work, and recent service history for this property."
        }
        let names = maintenancePriorityCoverageItems.map(\.system.displayName)
        if names.isEmpty {
            return "\(maintenanceCoverageGapItems.count) systems still need a service path before Chez can fully manage this property."
        }
        return "\(maintenanceCoverageGapItems.count) systems still need a service path. Start with \(names.joined(separator: " · "))."
    }

    private var maintenanceBriefNextTask: MaintenanceTaskDBRow? {
        maintenanceUpcomingItems.first
    }

    private var maintenanceBriefMetaLine: String {
        "\(maintenanceUpcomingItems.count) upcoming · \(maintenanceTasksForYouCount) task\(maintenanceTasksForYouCount == 1 ? "" : "s") for you · \(maintenanceServicePlanCount) systems on plan"
    }

    private var maintenanceBriefStatusChipTitle: String {
        maintenanceCoverageGapItems.isEmpty ? "Chez handling" : "Needs review"
    }

    private var maintenanceRecentServicesSubtitle: String {
        guard let recent = viewModel.serviceRecords.first else {
            return "Service history builds as work is completed"
        }

        let parts = [
            "\(viewModel.serviceRecords.count) completed",
            recent.description,
            recent.serviceDate.havenDateShort,
        ]

        return parts.joined(separator: " · ")
    }

    private var systemsSearchResults: [HomeSystemRow] {
        let query = systemsSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return topLevelSystems
            .filter { systemMatchesSearch($0, query: query) }
            .sorted { systemPriorityScore($0) > systemPriorityScore($1) }
    }

    private var linkedEssentialServiceLabels: [String] {
        let essentialTypes = ["internet_cable", "electric", "trash", "security"]
        return essentialTypes.compactMap { type in
            guard viewModel.utilityAccounts.contains(where: { $0.providerType == type }) else { return nil }
            return UtilityTypeMeta(type).label
        }
    }

    private var missingEssentialServiceLabels: [String] {
        let essentialTypes = ["internet_cable", "electric", "trash", "security"]
        return essentialTypes.compactMap { type in
            guard !viewModel.utilityAccounts.contains(where: { $0.providerType == type }) else { return nil }
            return UtilityTypeMeta(type).label
        }
    }

    private var missingCoverageSystemLabels: [String] {
        var ordered: [String] = []
        for system in topLevelSystems.filter(systemNeedsVendor).sorted(by: { systemPriorityScore($0) > systemPriorityScore($1) }) {
            if !ordered.contains(system.displayName) {
                ordered.append(system.displayName)
            }
        }
        return ordered
    }

    private var upcomingItemsNeedingReviewCount: Int {
        overviewUpcomingItems.filter(overviewItemNeedsReview).count
    }

    private var overviewAttentionAreaCount: Int {
        var count = 0
        if systemsNeedingVendorCount > 0 { count += 1 }
        if !highPrioritySystemsToIdentify.isEmpty { count += 1 }
        if !viewModel.missingPropertyDocTypes.isEmpty { count += 1 }
        if upcomingItemsNeedingReviewCount > 0 { count += 1 }
        return count
    }

    private func isSystemIdentified(_ system: HomeSystemRow) -> Bool {
        system.catalogEntryId != nil
            || !(system.manufacturer?.isEmpty ?? true)
            || !(system.modelNumber?.isEmpty ?? true)
            || !(system.serialNumber?.isEmpty ?? true)
    }

    private func systemNeedsInfo(_ system: HomeSystemRow) -> Bool {
        !isSystemIdentified(system) || (system.modelNumber?.isEmpty ?? true)
    }

    private func systemNeedsAttention(_ system: HomeSystemRow) -> Bool {
        systemNeedsInfo(system) || isNearReplacement(system) || systemNeedsVendor(system)
    }

    private func systemNeedsVendor(_ system: HomeSystemRow) -> Bool {
        !isSystemCovered(system)
    }

    private func isSystemCovered(_ system: HomeSystemRow) -> Bool {
        if system.preferredContractorId != nil {
            return true
        }
        if viewModel.maintenanceTasks.contains(where: {
            $0.systemId == system.id
                && $0.vehicleId == nil
                && $0.assignmentType?.lowercased() == "vendor"
                && $0.assignedContractorId != nil
        }) {
            return true
        }
        return viewModel.contractors.contains(where: {
            ($0.category ?? "").localizedCaseInsensitiveContains(system.category)
        })
    }

    private func isSystemLinkedToMaintenance(_ system: HomeSystemRow) -> Bool {
        if viewModel.maintenanceTasks.contains(where: { $0.systemId == system.id && $0.vehicleId == nil }) {
            return true
        }
        if system.serviceIntervalDays != nil {
            return true
        }
        if !(system.lastServiceDate?.isEmpty ?? true) || !(system.nextServiceDue?.isEmpty ?? true) {
            return true
        }
        return false
    }

    private func isSystemProfileComplete(_ system: HomeSystemRow) -> Bool {
        let hasIdentity = isSystemIdentified(system)
        let hasInstallContext = !(system.installDate?.isEmpty ?? true) || system.expectedLifespanYears != nil
        let hasSupportMaterial = !(system.serialNumber?.isEmpty ?? true)
            || !(system.cachedManualLinks?.isEmpty ?? true)
            || system.catalogEntryId != nil
        let hasConnectedHistory = isSystemLinkedToMaintenance(system)
            || system.preferredContractorId != nil
            || !(system.lastServiceDate?.isEmpty ?? true)

        return [hasIdentity, hasInstallContext, hasSupportMaterial, hasConnectedHistory]
            .filter { $0 }
            .count >= 3
    }

    private func isNearReplacement(_ system: HomeSystemRow) -> Bool {
        guard let lifespan = system.expectedLifespanYears,
              let installDate = system.installDate,
              let install = isoDateFormatter.date(from: installDate) else { return false }
        let years = Calendar.current.dateComponents([.year], from: install, to: Date()).year ?? 0
        return years >= max(lifespan - 2, 1)
    }

    private var isoDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private func systemAttentionHeadline(_ system: HomeSystemRow) -> String {
        if systemNeedsInfo(system) {
            return "Missing details"
        }
        if isNearReplacement(system) {
            return "Near expected lifespan"
        }
        if systemNeedsVendor(system) {
            return "Coverage needed"
        }
        return "No open issues"
    }

    private func systemFacts(_ system: HomeSystemRow) -> String {
        var parts: [String] = []
        if let manufacturer = system.manufacturer, !manufacturer.isEmpty {
            parts.append(manufacturer)
        }
        if let model = system.modelNumber, !model.isEmpty {
            parts.append(model)
        }
        if parts.isEmpty {
            parts.append(system.category)
        }
        return parts.joined(separator: " · ")
    }

    private func systemPriorityScore(_ system: HomeSystemRow) -> Int {
        let key = "\(system.category) \(system.displayName)".lowercased()
        var score = 10
        if key.contains("boiler") || key.contains("hvac") || key.contains("furnace") || key.contains("heat pump") {
            score += 120
        }
        if key.contains("water heater") { score += 115 }
        if key.contains("generator") { score += 110 }
        if key.contains("electrical") || key.contains("panel") { score += 108 }
        if key.contains("roof") { score += 105 }
        if key.contains("well") || key.contains("sump") || key.contains("septic") { score += 95 }
        if key.contains("security") || key.contains("fire") { score += 80 }
        if key.contains("appliance") || key.contains("dishwasher") || key.contains("refrigerator") || key.contains("washer") || key.contains("dryer") {
            score += 55
        }
        if systemNeedsVendor(system) { score += 15 }
        if isNearReplacement(system) { score += 10 }
        return score
    }

    private func systemPriorityDetail(_ system: HomeSystemRow) -> String {
        let key = "\(system.category) \(system.displayName)".lowercased()
        if systemNeedsInfo(system) {
            if key.contains("roof") {
                return "Add age, material, and warranty"
            }
            if key.contains("generator") {
                return "Add brand, model, serial, and fuel type"
            }
            if key.contains("water heater") {
                return "Add brand, model, and install date"
            }
            if key.contains("electrical") || key.contains("panel") {
                return "Add panel brand, amperage, and breaker details"
            }
            if key.contains("boiler") || key.contains("hvac") || key.contains("furnace") || key.contains("heat pump") {
                return "Add model, filter size, and service history"
            }
            if key.contains("well") || key.contains("sump") {
                return "Add brand, install date, and maintenance history"
            }
            if key.contains("refrigerator") {
                return "Add model, serial, and filter type"
            }
            if key.contains("appliance") || key.contains("dishwasher") || key.contains("refrigerator") || key.contains("washer") || key.contains("dryer") || key.contains("oven") {
                return "Add model, serial, and install date"
            }
            return "Add brand, model, and key details"
        }
        if systemNeedsVendor(system) {
            return "Coverage needed before Chez can coordinate service"
        }
        if isNearReplacement(system) {
            return "Nearing expected lifespan"
        }
        return "No open issues"
    }

    private func systemMatchesSearch(_ system: HomeSystemRow, query: String) -> Bool {
        let normalizedQuery = query.lowercased()
        let searchableValues = [
            system.displayName,
            system.displayCategory,
            system.manufacturer,
            system.modelNumber,
            system.serialNumber,
            system.subtype,
            system.catalogModelName,
            system.catalogSeries,
            system.catalogFuelType,
            system.notes,
        ]
            .compactMap { $0?.lowercased() }

        if searchableValues.contains(where: { $0.contains(normalizedQuery) }) {
            return true
        }

        let manualValues = (system.cachedManualLinks ?? []).flatMap { link in
            [
                link.type.lowercased(),
                link.url.lowercased(),
            ]
        }
        if manualValues.contains(where: { $0.contains(normalizedQuery) }) {
            return true
        }

        if normalizedQuery.contains("manual"), system.cachedManualLinks?.isEmpty == false {
            return true
        }
        if normalizedQuery.contains("warranty"), !(system.installDate?.isEmpty ?? true) {
            return true
        }
        if normalizedQuery.contains("filter"), systemPriorityDetail(system).lowercased().contains("filter") {
            return true
        }

        return false
    }

    private func overviewTaskStatus(_ task: MaintenanceTaskDBRow) -> (label: String, color: Color) {
        if task.assignmentType?.lowercased() == "vendor" && task.assignedContractorId == nil {
            return ("Coverage needed", HavenColors.action)
        }
        if task.assignedContractorId != nil {
            return ("Chez handling", HavenColors.textSecondary)
        }
        if task.assignedRoute == "handyman" {
            return ("Handyman", HavenColors.textSecondary)
        }
        if task.assignmentType?.lowercased() == "vendor" {
            return ("Waiting", HavenColors.textSecondary)
        }
        return ("You", HavenColors.navy700)
    }

    private func overviewItemNeedsReview(_ task: MaintenanceTaskDBRow) -> Bool {
        task.assignmentType?.lowercased() == "vendor" && task.assignedContractorId == nil
    }

    private func maintenanceTaskStatus(_ task: MaintenanceTaskDBRow) -> (label: String, color: Color, detail: String?) {
        let vendorName = viewModel.contractor(for: task.assignedContractorId)?.companyName
        let scheduledDate = task.scheduledDate?.trimmingCharacters(in: .whitespacesAndNewlines)

        if task.assignedRoute == "handyman" {
            return ("Handyman", HavenColors.navy700, "Bundled for a handyman visit")
        }

        if task.assignmentType?.lowercased() == "vendor" || task.assignedRoute == "vendor" || task.needsVendor == true {
            if task.assignedContractorId == nil {
                return ("Coverage needed", HavenColors.action, "Chez is blocked until a service path is chosen")
            }
            if let scheduledDate, !scheduledDate.isEmpty {
                return ("Scheduled", HavenColors.success, vendorName ?? "Vendor scheduled")
            }
            return ("Chez handling", HavenColors.navy700, vendorName ?? "Vendor on file")
        }

        if task.assignedRoute == "diy"
            || task.assignmentType?.lowercased() == "personal"
            || task.isDiy == true
        {
            return ("You", HavenColors.warning, "This stays on your list until it is done")
        }

        return ("Chez handling", HavenColors.textSecondary, vendorName)
    }

    private func maintenanceTaskDateLabel(_ task: MaintenanceTaskDBRow) -> String {
        overviewDateLabel(task.scheduledDate ?? task.nextDueDate)
    }

    private func coverageGapSubtitle(for item: CoverageGapItem) -> String {
        if let task = item.task {
            let dateLabel = maintenanceTaskDateLabel(task)
            return "Blocked soon: \(task.title) · \(dateLabel)"
        }
        return "Choose a service path so Chez can coordinate future work."
    }

    private func coverageGapReason(for item: CoverageGapItem) -> String {
        systemPriorityDetail(item.system)
    }

    private func presentCoverageVendorPicker(for item: CoverageGapItem) {
        guard let task = item.task else {
            withAnimation { activeTab = .vendors }
            return
        }
        showCoverageReview = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            vendorAssignmentTask = task
        }
    }

    private func presentCoverageVendorAdd(for item: CoverageGapItem) {
        showCoverageReview = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showAddVendor = true
        }
    }

    private func presentCoverageSourceFlow(for item: CoverageGapItem) {
        guard let task = item.task else {
            withAnimation { activeTab = .vendors }
            return
        }
        showCoverageReview = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            seasonalFindVendorTask = task
        }
    }

    private func openCoverageSystem(_ item: CoverageGapItem) {
        showCoverageReview = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            selectedSystemForDetail = item.system
        }
    }

    private func moveCoverageGapToHandyman(_ item: CoverageGapItem) {
        guard let task = item.task else { return }
        Task {
            try? await ServiceOrchestrator.routeService(
                task: task,
                route: "handyman",
                category: item.system.category
            )
            await viewModel.loadProperty(id: propertyID)
        }
    }

    private func handleOverviewAttention() {
        if systemsNeedingVendorCount > 0 {
            withAnimation { activeTab = .vendors }
        } else if !highPrioritySystemsToIdentify.isEmpty {
            showEquipmentPrompt()
        } else if !viewModel.missingPropertyDocTypes.isEmpty {
            showDocumentUpload = true
        } else {
            // Chez v1: maintenance moved to the top-level Tasks tab.
            NotificationCenter.default.post(
                name: .switchToTab,
                object: nil,
                userInfo: ["tab": 2]
            )
        }
    }

    private func handlePropertySectionNavigation(_ section: String) {
        // Chez v1: maintenance + handyman moved to the top-level Tasks tab.
        // Anything that used to deep-link to Property → Maintenance now
        // switches to tab 2 instead.
        if section == "maintenance" || section == "handyman_punch_list" {
            NotificationCenter.default.post(
                name: .switchToTab,
                object: nil,
                userInfo: ["tab": 2]
            )
            return
        }

        var targetTab: PropertyDetailTab?
        switch section {
        case "overview":
            targetTab = .overview
        case "systems":
            targetTab = .systems
        case "projects":
            targetTab = .projects
        case "vendors", "contacts":
            targetTab = .vendors
        case "documents":
            targetTab = .documents
        default:
            break
        }

        if let targetTab {
            withAnimation {
                activeTab = targetTab
            }
        }
    }

    private func propertyHeroSubtitle(_ property: PropertyRow) -> String {
        let type = formattedPropertyType(property.propertyType)
        let location = [property.city, property.state].compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }.joined(separator: ", ")
        if location.isEmpty {
            return type
        }
        return "\(type) · \(location)"
    }

    private func friendlyDocumentLabel(_ raw: String) -> String {
        switch raw {
        case "Homeowners Insurance":
            return "Homeowners insurance policy"
        case "Mortgage":
            return "Mortgage statement"
        case "Title Insurance":
            return "Title insurance"
        default:
            return raw
        }
    }

    private func formattedPropertyType(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var serviceRelationshipCount: Int {
        viewModel.contractors.count + viewModel.utilityAccounts.count
    }

    private var propertyStatusHeadline: String {
        if overviewAttentionAreaCount == 0 {
            return "Property is in good shape."
        }
        if identifiedSystemCount == 0 || vendorCoverageCounts.covered == 0 {
            return "Setup in progress"
        }
        return "Property actively managed"
    }

    private var propertyStatusSummary: String {
        if overviewAttentionAreaCount == 0 {
            return "Chez is tracking \(serviceRelationshipCount) service relationship\(serviceRelationshipCount == 1 ? "" : "s") and \(topLevelSystems.count) home system\(topLevelSystems.count == 1 ? "" : "s")."
        }
        return "\(overviewAttentionAreaCount) priorit\(overviewAttentionAreaCount == 1 ? "y needs" : "ies need") review before Chez can fully manage this property."
    }

    private func propertyFactsSummary(_ property: PropertyRow) -> String? {
        var parts: [String] = [formattedPropertyType(property.propertyType)]
        if let year = property.yearBuilt {
            parts.append("Built \(year)")
        }
        if let sqft = property.squareFootage {
            parts.append("\(sqft.formatted()) sq ft")
        }
        if serviceRelationshipCount > 0 {
            parts.append("\(serviceRelationshipCount) linked services")
        }
        let summary = parts.filter { !$0.isEmpty }
        guard summary.count >= 2 else { return nil }
        return summary.joined(separator: " · ")
    }

    private func overviewDateLabel(_ raw: String) -> String {
        guard let date = isoDateFormatter.date(from: raw) else { return raw.havenDateShort }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func serviceCoverageLabel(for group: SystemGroup) -> String {
        let systems = group.systems.filter { $0.parentSystemId == nil }
        let covered = systems.filter(isSystemCovered).count
        guard !systems.isEmpty else { return "No systems" }
        if covered == 0 {
            return "Coverage gaps"
        }
        if covered == systems.count {
            return "On service plan"
        }
        return "\(covered) of \(systems.count) on plan"
    }

    private var systemsRecordStateLabel: String {
        if topLevelSystems.isEmpty {
            return "Start here"
        }
        if !highPrioritySystemsToIdentify.isEmpty {
            return "Setup in progress"
        }
        if maintenanceLinkedSystemCount > 0 || completeSystemProfileCount > 0 {
            return "Record ready"
        }
        return "Home inventory"
    }

    private var systemsRecordSummary: String {
        if topLevelSystems.isEmpty {
            return "Build the home's equipment record"
        }
        if !highPrioritySystemsToIdentify.isEmpty {
            return "\(topLevelSystems.count) systems mapped"
        }
        return "\(topLevelSystems.count) systems mapped · \(completeSystemProfileCount) profile\(completeSystemProfileCount == 1 ? "" : "s") complete"
    }

    private var systemsRecordSupportingSummary: String {
        if topLevelSystems.isEmpty {
            return "Identify key equipment once, and Chez can keep manuals, recalls, parts, warranties, service history, and maintenance connected."
        }
        if !highPrioritySystemsToIdentify.isEmpty {
            return "\(highPrioritySystemsToIdentify.count) priority profile\(highPrioritySystemsToIdentify.count == 1 ? "" : "s") need setup"
        }
        if maintenanceLinkedSystemCount > 0 {
            return "\(maintenanceLinkedSystemCount) linked to maintenance"
        }
        return "Profiles are ready for manuals, parts, warranties, and buyer-ready records."
    }

    private func prioritySystemReason(_ system: HomeSystemRow) -> String {
        let key = "\(system.category) \(system.displayName)".lowercased()
        if key.contains("water heater") {
            return "Important for replacement planning and emergency service."
        }
        if key.contains("generator") {
            return "Important for annual service and storm readiness."
        }
        if key.contains("electrical") || key.contains("panel") {
            return "Important for safety, projects, and emergency troubleshooting."
        }
        if key.contains("roof") {
            return "Important for long-term capital planning and buyer-ready records."
        }
        if key.contains("boiler") || key.contains("hvac") || key.contains("furnace") || key.contains("heat pump") {
            return "Important for seasonal tune-ups, filters, and emergency repairs."
        }
        if key.contains("refrigerator") || key.contains("appliance") {
            return "Important for manuals, parts, and warranty lookups."
        }
        return "Important for service history, parts, and buyer-ready documentation."
    }

    private func groupRecordSummary(for group: SystemGroup) -> String {
        let systems = group.systems.filter { $0.parentSystemId == nil }
        let count = systems.count
        let complete = systems.filter(isSystemProfileComplete).count
        let linked = systems.filter(isSystemLinkedToMaintenance).count
        let missing = systems.filter(systemNeedsInfo).count

        if let highlight = groupRecordHighlight(for: group) {
            return "\(count) system\(count == 1 ? "" : "s") · \(highlight)"
        }
        if linked > 0 {
            return "\(count) system\(count == 1 ? "" : "s") · \(linked) linked to maintenance"
        }
        if complete > 0 || missing == count {
            return "\(count) system\(count == 1 ? "" : "s") · \(complete) profile\(complete == 1 ? "" : "s") complete"
        }
        return "\(count) system\(count == 1 ? "" : "s")"
    }

    private func groupRecordHighlight(for group: SystemGroup) -> String? {
        let systems = group.systems
            .filter { $0.parentSystemId == nil && systemNeedsInfo($0) }
            .sorted { systemPriorityScore($0) > systemPriorityScore($1) }

        guard let system = systems.first else { return nil }
        let key = "\(system.category) \(system.displayName)".lowercased()
        if key.contains("roof") {
            return "roof details missing"
        }
        if key.contains("electrical") || key.contains("panel") {
            return "panel details missing"
        }
        if key.contains("generator") {
            return "generator profile to finish"
        }
        if key.contains("water heater") {
            return "water heater profile to finish"
        }
        return nil
    }

    private func ownerBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(HavenTypography.uiCaption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func statusMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func maintenanceUpcomingRow(_ task: MaintenanceTaskDBRow) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 32, height: 32)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(task.nextDueDate.havenDateShort) · \(task.title)")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                Text(viewModel.contractor(for: task.assignedContractorId)?.companyName ?? "Vendor")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
                ownerBadge(title: "Scheduled", color: HavenColors.success)
            }

            Spacer()
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }

    private var systemsSearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)

            TextField("Search systems, manuals, model numbers, parts...", text: $systemsSearchText)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !systemsSearchText.isEmpty {
                Button {
                    systemsSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }

    private func systemsSummaryChip(_ title: String, color: Color, tint: Color) -> some View {
        Text(title)
            .font(HavenTypography.uiCaption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint)
            .clipShape(Capsule())
    }

    private func systemRecordRow(
        _ system: HomeSystemRow,
        subtitle: String,
        status: (title: String, color: Color)
    ) -> some View {
        Button {
            Haptics.light()
            selectedSystemForDetail = system
        } label: {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: systemRecordIcon(system))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 34, height: 34)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 5) {
                    Text(system.displayName)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                    ownerBadge(title: status.title, color: status.color)
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

    private func systemRecordIcon(_ system: HomeSystemRow) -> String {
        if let meta = SystemCategoryRegistry.metaForCategory(system.category) {
            return meta.icon
        }
        switch SystemGroup.groupId(for: system.category) {
        case "climate": return "thermometer.sun.fill"
        case "structure": return "house.fill"
        case "plumbing": return "drop.fill"
        case "electrical": return "bolt.fill"
        case "outdoor": return "leaf.fill"
        case "security": return "shield.lefthalf.filled"
        case "appliances": return "refrigerator.fill"
        default: return "sparkles"
        }
    }

    private func systemRecordSummary(_ system: HomeSystemRow) -> String {
        if systemNeedsInfo(system) {
            return systemPriorityDetail(system)
        }

        var parts: [String] = []
        if let manufacturer = system.manufacturer, !manufacturer.isEmpty {
            parts.append(manufacturer)
        }
        if let model = system.modelNumber, !model.isEmpty {
            parts.append(model)
        }
        if parts.isEmpty {
            parts.append(system.displayCategory)
        }
        if system.cachedManualLinks?.isEmpty == false {
            parts.append("Manual found")
        } else if !(system.serialNumber?.isEmpty ?? true) {
            parts.append("Serial on file")
        } else if isSystemLinkedToMaintenance(system) {
            parts.append("Linked to maintenance")
        }
        return parts.prefix(2).joined(separator: " · ")
    }

    private func systemRecordStatus(_ system: HomeSystemRow) -> (title: String, color: Color) {
        if systemNeedsInfo(system) {
            return ("Priority setup", HavenColors.warning)
        }
        if isNearReplacement(system) {
            return ("Near expected lifespan", HavenColors.warning)
        }
        if systemNeedsVendor(system) && isSystemLinkedToMaintenance(system) {
            return ("Coverage needed", HavenColors.action)
        }
        if isSystemProfileComplete(system) {
            return ("Profile complete", HavenColors.success)
        }
        if isSystemLinkedToMaintenance(system) {
            return ("Linked to maintenance", HavenColors.navy700)
        }
        return ("Tracked", HavenColors.textSecondary)
    }

    private func systemCategoryRow(_ group: SystemGroup) -> some View {
        NavigationLink {
            SystemGroupListView(
                group: group,
                propertyId: propertyID,
                householdId: viewModel.property?.householdId ?? UUID()
            )
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: group.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 34, height: 34)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(groupRecordSummary(for: group))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Spacer()

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

    private func overviewCard<Content: View>(
        title: String,
        icon: String,
        accent: Color = HavenColors.navy700,
        tint: Color = HavenColors.surface,
        showsAccentRail: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .fill(tint)
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.border, lineWidth: 1)
            if showsAccentRail {
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .fill(accent)
                    .frame(width: 4)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                content()
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
    }

    private func overviewProgressBar(progress: Double, color: Color) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(HavenColors.beige200)
                .frame(height: 8)
            GeometryReader { geo in
                Capsule()
                    .fill(color)
                    .frame(
                        width: progress <= 0 ? 0 : max(12, geo.size.width * min(max(progress, 0), 1)),
                        height: 8
                    )
            }
        }
        .frame(height: 8)
    }

    private func overviewListRow(title: String, subtitle: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var propertyStatusHeroCard: some View {
        overviewCard(
            title: "Chez brief",
            icon: "house.fill",
            accent: overviewAttentionAreaCount > 0 ? HavenColors.action : HavenColors.navy700,
            tint: overviewAttentionAreaCount > 0 ? HavenColors.action.opacity(0.06) : HavenColors.surface,
            showsAccentRail: overviewAttentionAreaCount > 0
        ) {
            VStack(alignment: .leading, spacing: 10) {
                let totalSystems = vendorCoverageCounts.covered + vendorCoverageCounts.uncovered

                Text(propertyStatusHeadline)
                    .font(HavenTypography.body.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)

                Text(propertyStatusSummary)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if totalSystems > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(vendorCoverageCounts.covered) of \(totalSystems) systems covered")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                        overviewProgressBar(
                            progress: Double(vendorCoverageCounts.covered) / Double(totalSystems),
                            color: overviewAttentionAreaCount > 0 ? HavenColors.action : HavenColors.navy700
                        )
                    }
                }

                if let nextMeaningfulVisit {
                    let status = overviewTaskStatus(nextMeaningfulVisit)
                    overviewListRow(
                        title: "Next: \(nextMeaningfulVisit.title)",
                        subtitle: "\(overviewDateLabel(nextMeaningfulVisit.nextDueDate)) · \(status.label)",
                        color: status.color
                    )
                }

                if !missingCoverageSystemLabels.isEmpty {
                    overviewListRow(
                        title: "Coverage gaps",
                        subtitle: Array(missingCoverageSystemLabels.prefix(3)).joined(separator: " · "),
                        color: HavenColors.action
                    )
                } else if !missingEssentialServiceLabels.isEmpty {
                    overviewListRow(
                        title: "Coverage gaps",
                        subtitle: Array(missingEssentialServiceLabels.prefix(3)).joined(separator: " · "),
                        color: HavenColors.action
                    )
                }

                Button {
                    if overviewAttentionAreaCount > 0 {
                        handleOverviewAttention()
                    } else {
                        showFullSchedule = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(overviewAttentionAreaCount > 0 ? "Review priorities" : "View maintenance plan")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(overviewAttentionAreaCount > 0 ? HavenColors.action : HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var propertyUpcomingCard: some View {
        overviewCard(
            title: "This month",
            icon: "calendar",
            accent: HavenColors.navy700,
            tint: HavenColors.surface
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if overviewUpcomingItems.isEmpty {
                    Text("No upcoming maintenance work is scheduled yet.")
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Review maintenance to decide what Chez should schedule next.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach(Array(overviewUpcomingItems), id: \.id) { task in
                        let status = overviewTaskStatus(task)
                        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
                            Text(overviewDateLabel(task.nextDueDate))
                                .font(HavenTypography.uiCaption.weight(.semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                                .frame(width: 48, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Text(status.label)
                                .font(HavenTypography.uiCaption.weight(.semibold))
                                .foregroundStyle(status.color)
                                .multilineTextAlignment(.trailing)
                        }
                        if task.id != overviewUpcomingItems.last?.id {
                            Divider()
                                .overlay(HavenColors.border)
                        }
                    }
                }

                Button {
                    showFullSchedule = true
                } label: {
                    Text(overviewUpcomingItems.isEmpty ? "Review maintenance" : "View maintenance plan")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var propertySystemsSnapshotCard: some View {
        overviewCard(
            title: "Systems snapshot",
            icon: "square.stack.3d.up.fill",
            accent: HavenColors.warning,
            tint: HavenColors.warning.opacity(0.05)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if topLevelSystems.isEmpty {
                    Text("No systems are tracked yet.")
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Start with HVAC, water, safety, and the major equipment Chez needs to remember for this property.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(topLevelSystems.count) systems tracked")
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(
                            !highPrioritySystemsToIdentify.isEmpty
                                ? "\(highPrioritySystemsToIdentify.count) high-priority systems need identification"
                                : "\(identifiedSystemCount) identified · \(systemsMissingInfoCount) still need details"
                        )
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        overviewProgressBar(
                            progress: Double(identifiedSystemCount) / Double(max(topLevelSystems.count, 1)),
                            color: HavenColors.warning
                        )
                    }

                    if !highPrioritySystemsToIdentify.isEmpty {
                        Text("Start with the expensive or safety-critical systems first.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(Array(highPrioritySystemsToIdentify.prefix(3)).map(\.displayName).joined(separator: " · "))
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if let system = systemAttentionItems.first {
                        overviewListRow(
                            title: system.displayName,
                            subtitle: systemAttentionHeadline(system),
                            color: systemNeedsVendor(system) ? HavenColors.action : HavenColors.warning
                        )
                    } else {
                        Text("Chez has enough system detail to keep this property moving.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Button {
                    showEquipmentPrompt()
                } label: {
                    Text(topLevelSystems.isEmpty ? "Add systems" : (!highPrioritySystemsToIdentify.isEmpty ? "Identify priority systems" : "View systems"))
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var propertyVendorsSnapshotCard: some View {
        overviewCard(
            title: "Vendors & utilities",
            icon: "person.2.fill",
            accent: HavenColors.info,
            tint: HavenColors.surface
        ) {
            VStack(alignment: .leading, spacing: 10) {
                let totalLinks = viewModel.contractors.count + viewModel.utilityAccounts.count
                if totalLinks == 0 {
                    Text("No vendors or utilities are linked yet.")
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Add the companies that service this property so Chez can track the home with more context.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    Text("\(totalLinks) active service relationship\(totalLinks == 1 ? "" : "s")")
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)

                    Text("\(viewModel.contractors.count) home service\(viewModel.contractors.count == 1 ? "" : "s") · \(viewModel.utilityAccounts.count) utilit\(viewModel.utilityAccounts.count == 1 ? "y" : "ies") and policies")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !linkedEssentialServiceLabels.isEmpty {
                        overviewListRow(
                            title: "Essential coverage",
                            subtitle: linkedEssentialServiceLabels.joined(separator: " · "),
                            color: HavenColors.success
                        )
                    }

                    if !missingCoverageSystemLabels.isEmpty || !missingEssentialServiceLabels.isEmpty {
                        let missing = Array((missingCoverageSystemLabels + missingEssentialServiceLabels).prefix(3))
                        overviewListRow(
                            title: "Missing coverage",
                            subtitle: missing.joined(separator: " · "),
                            color: HavenColors.action
                        )
                    }
                }

                Button {
                    withAnimation { activeTab = .vendors }
                } label: {
                    Text("View vendors & utilities")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var propertyProjectsSnapshotCard: some View {
        overviewCard(
            title: "Projects",
            icon: "hammer.fill",
            accent: HavenColors.navy700,
            tint: HavenColors.navy.opacity(0.025)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(activeProjects.count) active project\(activeProjects.count == 1 ? "" : "s")")
                    .font(HavenTypography.body.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)

                ForEach(Array(activeProjects.prefix(2))) { project in
                    let status = ProjectStatus(rawValue: project.status) ?? .planning
                    overviewListRow(
                        title: project.name,
                        subtitle: status.displayName,
                        color: status.color
                    )
                }

                Button {
                    withAnimation { activeTab = .projects }
                } label: {
                    Text("View projects")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func propertyFactsCard(_ property: PropertyRow) -> some View {
        overviewCard(
            title: "Property facts",
            icon: "house.fill",
            accent: HavenColors.textSecondary,
            tint: HavenColors.surface
        ) {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Text(propertyFactsSummary(property) ?? formattedPropertyType(property.propertyType))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button {
                    showEditProperty = true
                } label: {
                    Text("Edit")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func propertyValueSnapshotCard(_ property: PropertyRow) -> some View {
        overviewCard(
            title: "Value & equity",
            icon: "chart.line.uptrend.xyaxis",
            accent: HavenColors.navy800,
            tint: HavenColors.navy.opacity(0.03)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if let value = property.currentEstimatedValue, value > 0 {
                    Text("\(value.formattedCompactCurrency()) estimated value")
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    if let low = property.currentEstimatedValueLow,
                       let high = property.currentEstimatedValueHigh,
                       low > 0, high > 0 {
                        Text("Range: \(low.formattedCompactCurrency())–\(high.formattedCompactCurrency())")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Text("Maintenance records help keep this home buyer-ready.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    Text("Add purchase and value details to build the property story.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Button {
                    showValueDetails = true
                } label: {
                    Text("See value breakdown")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func propertyRecordSection(_ property: PropertyRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Property record")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .padding(.bottom, 8)

                propertyRecordRow(
                    title: "Systems",
                    summary: propertySystemsRecordSummary,
                    icon: "square.stack.3d.up.fill"
                ) {
                    withAnimation { activeTab = .systems }
                }

                propertyRecordDivider

                propertyRecordRow(
                    title: "Coverage",
                    summary: propertyCoverageRecordSummary,
                    icon: "person.2.fill"
                ) {
                    withAnimation { activeTab = .vendors }
                }

                propertyRecordDivider

                propertyRecordRow(
                    title: "Documents",
                    summary: propertyDocumentsRecordSummary,
                    icon: "doc.fill"
                ) {
                    showPropertyDocuments = true
                }

                propertyRecordDivider

                propertyRecordRow(
                    title: "Projects",
                    summary: propertyProjectsRecordSummary,
                    icon: "hammer.fill"
                ) {
                    withAnimation { activeTab = .projects }
                }

                propertyRecordDivider

                propertyRecordRow(
                    title: "Value",
                    summary: propertyValueRecordSummary(property),
                    icon: "chart.line.uptrend.xyaxis"
                ) {
                    showValueDetails = true
                }

                propertyRecordDivider

                propertyRecordRow(
                    title: "Facts",
                    summary: propertyFactsSummary(property) ?? propertyHeroSubtitle(property),
                    icon: "house.fill"
                ) {
                    showEditProperty = true
                }
            }
        }
    }

    private var propertySystemsRecordSummary: String {
        if topLevelSystems.isEmpty {
            return "No systems tracked yet"
        }
        if !highPrioritySystemsToIdentify.isEmpty {
            return "\(topLevelSystems.count) tracked · \(highPrioritySystemsToIdentify.count) priority system\(highPrioritySystemsToIdentify.count == 1 ? "" : "s") need ID"
        }
        return "\(topLevelSystems.count) tracked · \(identifiedSystemCount) identified"
    }

    private var propertyCoverageRecordSummary: String {
        let gapCount = systemsNeedingVendorCount + missingEssentialServiceLabels.count
        if gapCount > 0 {
            return "\(serviceRelationshipCount) relationships · \(gapCount) gap\(gapCount == 1 ? "" : "s")"
        }
        return "\(serviceRelationshipCount) relationships · Fully covered"
    }

    private var propertyDocumentsRecordSummary: String {
        if viewModel.missingPropertyDocTypes.isEmpty {
            return "\(viewModel.linkedDocuments.count) uploaded"
        }
        return "\(viewModel.linkedDocuments.count) uploaded · \(viewModel.missingPropertyDocTypes.count) suggested"
    }

    private var propertyProjectsRecordSummary: String {
        if activeProjects.isEmpty {
            return "No active projects"
        }
        if let first = activeProjects.first {
            let status = ProjectStatus(rawValue: first.status)?.displayName ?? "Active"
            return activeProjects.count == 1 ? "\(first.name) · \(status)" : "\(activeProjects.count) active · \(first.name)"
        }
        return "\(activeProjects.count) active"
    }

    private func propertyValueRecordSummary(_ property: PropertyRow) -> String {
        guard let value = property.currentEstimatedValue, value > 0 else {
            return "Add value details"
        }
        return "\(value.formattedCompactCurrency()) estimated"
    }

    private var propertyRecordDivider: some View {
        Divider()
            .overlay(HavenColors.border)
            .padding(.leading, 34)
    }

    private func propertyRecordRow(
        title: String,
        summary: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 18)

                Text(title)
                    .font(HavenTypography.uiLabel.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(width: 82, alignment: .leading)

                Text(summary)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var systemsHubSection: some View {
        PropertySystemsInventoryView(
            topLevelSystems: topLevelSystems,
            highPrioritySystems: highPrioritySystemsToIdentify,
            groupedSystems: groupedSystems,
            completeProfileCount: completeSystemProfileCount,
            maintenanceLinkedCount: maintenanceLinkedSystemCount,
            recordStateLabel: systemsRecordStateLabel,
            recordSummary: systemsRecordSummary,
            recordSupportingSummary: systemsRecordSupportingSummary,
            searchText: $systemsSearchText,
            searchResults: systemsSearchResults,
            groupSummary: groupRecordSummary(for:),
            priorityDetail: systemPriorityDetail(_:),
            systemSummary: systemRecordSummary(_:),
            systemStatus: systemRecordStatus(_:),
            iconForSystem: systemRecordIcon(_:),
            onAddSystem: {
                showAddSystem = true
            },
            onIdentifyPrioritySystems: {
                showPrioritySystemsSheet = true
            },
            onSelectSystem: { system in
                selectedSystemForDetail = system
            },
            onSelectGroup: { group in
                selectedSystemGroup = group
            }
        )
    }

    private func showEquipmentPrompt() {
        if viewModel.systems.isEmpty {
            showAddSystem = true
        } else {
            withAnimation { activeTab = .systems }
            systemsSearchText = ""
            if !highPrioritySystemsToIdentify.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showPrioritySystemsSheet = true
                }
            }
        }
    }

    private var prioritySystemsSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                Text("\(highPrioritySystemsToIdentify.count) priority system\(highPrioritySystemsToIdentify.count == 1 ? "" : "s")")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)

                Text("Start with these because they are expensive, safety-critical, or tied to upcoming maintenance.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                ForEach(highPrioritySystemsToIdentify) { system in
                    Button {
                        showPrioritySystemsSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            selectedSystemForDetail = system
                        }
                    } label: {
                        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                            Image(systemName: systemRecordIcon(system))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 34, height: 34)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(system.displayName)
                                    .font(HavenTypography.body.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(2)
                                Text(systemPriorityDetail(system))
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .lineLimit(2)
                                Text(prioritySystemReason(system))
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
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
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing16)
        }
        .background(HavenColors.background)
        .navigationTitle("Priority systems")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    showPrioritySystemsSheet = false
                }
                .foregroundStyle(HavenColors.navy700)
            }
        }
    }

    private var maintenanceBriefCard: some View {
        overviewCard(
            title: "Maintenance",
            icon: "wrench.and.screwdriver.fill",
            accent: maintenanceCoverageGapItems.isEmpty ? HavenColors.navy700 : HavenColors.action,
            tint: maintenanceCoverageGapItems.isEmpty ? HavenColors.surface : HavenColors.action.opacity(0.06)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Text(maintenanceBriefHeadline)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    ownerBadge(
                        title: maintenanceBriefStatusChipTitle,
                        color: maintenanceCoverageGapItems.isEmpty ? HavenColors.navy700 : HavenColors.action
                    )
                }

                Text(maintenanceBriefSummary)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(maintenanceBriefMetaLine)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                if let nextTask = maintenanceBriefNextTask {
                    let status = maintenanceTaskStatus(nextTask)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next")
                            .font(HavenTypography.uiCaption.weight(.semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(nextTask.title) · \(maintenanceTaskDateLabel(nextTask))")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let detail = status.detail {
                                    Text(detail)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer()
                            ownerBadge(title: status.label, color: status.color)
                        }
                    }
                }

                HStack(spacing: HavenTheme.spacing12) {
                    if !maintenanceCoverageGapItems.isEmpty {
                        Button {
                            showCoverageReview = true
                        } label: {
                            Text("Review priorities")
                                .font(HavenTypography.uiLabel.weight(.semibold))
                                .foregroundStyle(HavenColors.textOnNavy)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(HavenColors.action)
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showFullSchedule = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(!maintenanceCoverageGapItems.isEmpty ? "View plan" : "View schedule")
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(HavenColors.navy700)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var maintenanceUpcomingSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Upcoming")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)

            HavenCard {
                if maintenanceUpcomingItems.isEmpty {
                    Text("No maintenance is on deck yet.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(maintenanceUpcomingItems.enumerated()), id: \.element.id) { index, task in
                            Button {
                                selectedMaintenanceTask = task
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Text(maintenanceTaskDateLabel(task))
                                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .frame(width: 48, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(HavenTypography.uiLabel)
                                            .foregroundStyle(HavenColors.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if let detail = maintenanceTaskStatus(task).detail {
                                            Text(detail)
                                                .font(HavenTypography.uiCaption)
                                                .foregroundStyle(HavenColors.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }

                                    Spacer(minLength: 0)

                                    ownerBadge(title: maintenanceTaskStatus(task).label, color: maintenanceTaskStatus(task).color)
                                }
                            }
                            .buttonStyle(.plain)

                            if index < maintenanceUpcomingItems.count - 1 {
                                Divider()
                            }
                        }

                        Button {
                            showFullSchedule = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("View maintenance plan")
                                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(HavenColors.navy700)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var maintenanceRecordSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Maintenance record")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)

            HavenCard {
                VStack(spacing: 0) {
                    if !viewModel.vendorFollowUpTasks.isEmpty {
                        maintenanceRecordRow(
                            icon: "clock.badge.exclamationmark",
                            title: "Vendor follow-ups",
                            subtitle: viewModel.vendorFollowUpTasks.count == 1
                                ? "1 follow-up is waiting on vendor coordination"
                                : "\(viewModel.vendorFollowUpTasks.count) follow-ups are waiting on vendor coordination",
                            badgeTitle: "\(viewModel.vendorFollowUpTasks.count)",
                            badgeColor: HavenColors.warning
                        ) {
                            if viewModel.vendorFollowUpTasks.count == 1, let task = viewModel.vendorFollowUpTasks.first {
                                selectedMaintenanceTask = task
                            } else {
                                showFullSchedule = true
                            }
                        }
                        maintenanceRecordDivider
                    }

                    maintenanceRecordRow(
                        icon: "hammer.fill",
                        title: "Handyman punch list",
                        subtitle: handymanPunchCount == 0
                            ? "Add things for your next handyman visit"
                            : handymanPunchCount == 1
                                ? "1 small job waiting"
                                : "\(handymanPunchCount) small jobs ready to bundle",
                        badgeTitle: handymanPunchCount > 0 ? "\(handymanPunchCount)" : nil
                    ) {
                        showHandymanPunchList = true
                    }

                    maintenanceRecordDivider

                    maintenanceRecordRow(
                        icon: "calendar.badge.clock",
                        title: "Recurring services",
                        subtitle: weeklyCadenceCount == 0
                            ? "Trash, cleaning, landscaping, pest control, pool, and more"
                            : "\(weeklyCadenceCount) active recurring service\(weeklyCadenceCount == 1 ? "" : "s")",
                        badgeTitle: weeklyCadenceCount > 0 ? "\(weeklyCadenceCount)" : nil
                    ) {
                        showWeeklyCadences = true
                    }

                    maintenanceRecordDivider

                    maintenanceRecordRow(
                        icon: "wrench.and.screwdriver.fill",
                        title: "Service coverage",
                        subtitle: maintenanceCoverageGapItems.isEmpty
                            ? "\(maintenanceServicePlanCount) systems are on a service plan"
                            : "\(maintenanceCoverageGapItems.count) systems still need a service path",
                        badgeTitle: maintenanceCoverageGapItems.isEmpty
                            ? "On track"
                            : "\(maintenanceCoverageGapItems.count) gaps",
                        badgeColor: maintenanceCoverageGapItems.isEmpty ? HavenColors.success : HavenColors.action
                    ) {
                        if maintenanceCoverageGapItems.isEmpty {
                            withAnimation { activeTab = .systems }
                        } else {
                            showCoverageReview = true
                        }
                    }

                    if !viewModel.serviceRecords.isEmpty {
                        maintenanceRecordDivider

                        maintenanceRecordRow(
                            icon: "clock.fill",
                            title: "Recent services",
                            subtitle: maintenanceRecentServicesSubtitle,
                            badgeTitle: "\(viewModel.serviceRecords.count)"
                        ) {
                            showServiceHistory = true
                        }
                    }

                    if !viewModel.diyTasksForMaintenanceTab.isEmpty {
                        maintenanceRecordDivider

                        maintenanceRecordRow(
                            icon: "person.fill.checkmark",
                            title: "Your tasks",
                            subtitle: "\(viewModel.diyTasksForMaintenanceTab.count) personal task\(viewModel.diyTasksForMaintenanceTab.count == 1 ? "" : "s") waiting on you",
                            badgeTitle: "\(viewModel.diyTasksForMaintenanceTab.count)",
                            badgeColor: HavenColors.warning
                        ) {
                            if viewModel.diyTasksForMaintenanceTab.count == 1,
                               let task = viewModel.diyTasksForMaintenanceTab.first {
                                selectedMaintenanceTask = task
                            } else {
                                showFullSchedule = true
                            }
                        }
                    }
                }
            }
        }
    }

    private var maintenanceMoreSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("More")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)

            HavenCard {
                VStack(spacing: 0) {
                    if (!viewModel.currentSeasonTasks.isEmpty || !viewModel.nextSeasonTasks.isEmpty),
                       !viewModel.seasonCompletionState.isComplete,
                       dismissedSeasonalOverview != "\(viewModel.currentSeason) \(Calendar.current.component(.year, from: Date()))" {
                        seasonalPlanRow
                        maintenanceRecordDivider
                    }

                    maintenanceRecordRow(
                        icon: "sparkles",
                        title: "Recommended services",
                        subtitle: "Ways to protect the home and avoid surprises"
                    ) {
                        showRecommendedServices = true
                    }
                    maintenanceRecordDivider
                    // Phase 95 (gap #40) — companion entry to the
                    // services row. Routes to RecommendedSystemsView
                    // so users can opt into specialty system
                    // categories the quiz didn't capture.
                    maintenanceRecordRow(
                        icon: "rectangle.stack.fill.badge.plus",
                        title: "Add what we missed",
                        subtitle: "Browse systems by tier and add anything we don't have on file"
                    ) {
                        showRecommendedSystems = true
                    }
                }
            }
        }
    }

    private var maintenanceRecordDivider: some View {
        Divider()
            .padding(.leading, 52)
    }

    private func maintenanceRecordRow(
        icon: String,
        title: String,
        subtitle: String,
        badgeTitle: String? = nil,
        badgeColor: Color = HavenColors.navy700,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if let badgeTitle {
                    Text(badgeTitle)
                        .font(HavenTypography.uiCaption.weight(.semibold))
                        .foregroundStyle(badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badgeColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.vertical, HavenTheme.spacing8)
        }
        .buttonStyle(.plain)
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
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("\(season) plan")
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
                            Text("\(assignedVendorTasks) of \(totalVendorTasks) items covered")
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
                        Text("Coming up in \(viewModel.nextSeason): \(nextGroups.count) areas to review")
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

    private var seasonalPlanRow: some View {
        let season = viewModel.currentSeason
        let nextSeason = viewModel.nextSeason
        let currentCount = viewModel.currentSeasonTasks.count
        let readyCount = viewModel.currentSeasonCompletedCount
        let nextAreas = SeasonalTaskGrouper
            .group(viewModel.nextSeasonTasks, systemNameLookup: { viewModel.systemName(for: $0) })
            .count

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
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: seasonIcon(season))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Seasonal plan")
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(currentCount > 0 ? "\(season) · \(readyCount) of \(currentCount) ready" : "\(season) · Planning ahead")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    if !viewModel.nextSeasonTasks.isEmpty {
                        Text("\(nextSeason) · \(nextAreas) area\(nextAreas == 1 ? "" : "s") to review")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.vertical, HavenTheme.spacing8)
        }
        .buttonStyle(.plain)
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
                        Text("Add your HVAC, plumbing, electrical and more. Chez will track maintenance for you.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .multilineTextAlignment(.center)

                        Button {
                            Haptics.light()
                            showAddSystem = true
                        } label: {
                            Text("Add a Home System")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
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
                            .foregroundStyle(HavenColors.textPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Maintenance")
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
                Text("Your tasks")
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
                             : handymanPunchCount == 1
                                ? "1 small job waiting"
                                : "\(handymanPunchCount) small jobs ready to bundle")
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
                        Text("Recurring services")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(weeklyCadenceCount == 0
                             ? "Trash, cleaning, landscaping, pest control, pool, and more"
                             : "\(weeklyCadenceCount) active recurring service\(weeklyCadenceCount == 1 ? "" : "s")")
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

    /// Phase 95 (gap #40) — recommended-SYSTEMS row. Sits below the
    /// recommended-services row; same low-key chrome but routes to
    /// `RecommendedSystemsView`. Renders a sheet because the entry
    /// is purely additive — users typically tap, add a system,
    /// land back on Property Detail with the new system reflected.
    @ViewBuilder
    private var recommendedSystemsRow: some View {
        if viewModel.property?.id != nil {
            Button {
                Haptics.light()
                showRecommendedSystems = true
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: "rectangle.stack.fill.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add what we missed")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Browse systems by tier and add what we don't have on file yet")
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
            .sheet(isPresented: $showRecommendedSystems) {
                if let propId = viewModel.property?.id {
                    RecommendedSystemsView(propertyId: propId) {
                        Task { await viewModel.loadProperty(id: propId) }
                    }
                }
            }
        }
    }

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
                        Text("Recommended services")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Ways to protect the home and avoid surprises")
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
        overviewCard(
            title: "Documents",
            icon: "doc.fill",
            accent: viewModel.missingPropertyDocTypes.isEmpty ? HavenColors.success : HavenColors.warning,
            tint: viewModel.missingPropertyDocTypes.isEmpty ? HavenColors.surface : HavenColors.warning.opacity(0.05)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(viewModel.linkedDocuments.count) uploaded · \(viewModel.missingPropertyDocTypes.count) suggested")
                    .font(HavenTypography.body.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)

                if !viewModel.missingPropertyDocTypes.isEmpty {
                    Text(viewModel.missingPropertyDocTypes.prefix(4).map { friendlyDocumentLabel($0.0) }.joined(separator: " · "))
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if !viewModel.linkedDocuments.isEmpty {
                    Text(viewModel.linkedDocuments.prefix(2).map(\.title).joined(separator: " · "))
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Keep deeds, insurance, inspections, and warranties attached to this property record.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                HStack(spacing: HavenTheme.spacing12) {
                    Button {
                        showDocumentUpload = true
                    } label: {
                        Text(viewModel.missingPropertyDocTypes.isEmpty ? "Upload document" : "Upload checklist")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(HavenColors.navy700)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        PropertyDocumentsView(propertyId: propertyID, propertyName: viewModel.property?.name ?? "Property")
                    } label: {
                        Text("View documents")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Vendors

    private var vendorsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            directoryHeader

            if !directoryRelationships.isEmpty {
                searchField
                filterChipsRow
            }

            relationshipList
        }
    }

    private var directoryHeader: some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Directory")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(directorySummaryLine)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Menu {
                Button {
                    Haptics.light()
                    showAddVendor = true
                } label: {
                    Label("Add vendor or advisor", systemImage: "person.crop.rectangle.badge.plus")
                }

                Button {
                    Haptics.light()
                    addUtilityType = nil
                    showAddUtility = true
                } label: {
                    Label("Add utility or policy", systemImage: "bolt.horizontal.circle")
                }

                Button {
                    Haptics.light()
                    showAlfredChat = true
                } label: {
                    Label("Ask Alfred to find a pro", systemImage: "sparkles")
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(HavenColors.navy700)
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
    }

    // MARK: Search + filter chips

    private var searchField: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.textTertiary)
            TextField("Search by name, company, service, or policy", text: $contactsSearchText)
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

    // MARK: Relationships list

    @ViewBuilder
    private var relationshipList: some View {
        if directoryRelationships.isEmpty {
            emptyRelationshipsState
        } else if filteredContacts.isEmpty {
            noMatchesState
        } else {
            VStack(spacing: 6) {
                ForEach(filteredContacts) { relationship in
                    switch relationship {
                    case .contractor(let contractor):
                        NavigationLink {
                            ContractorDetailView(contractor: contractor)
                        } label: {
                            contractorRow(
                                contractor,
                                showAttentionReason: contactsFilter == .needsAttention
                            )
                        }
                        .buttonStyle(.plain)

                    case .utility(let account):
                        NavigationLink {
                            UtilityRelationshipDetailView(
                                account: account,
                                property: viewModel.property
                            )
                        } label: {
                            utilityRow(
                                account,
                                showAttentionReason: contactsFilter == .needsAttention
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyRelationshipsState: some View {
        HavenCard {
            VStack(spacing: 10) {
                Image(systemName: "person.2")
                    .font(.title2)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("Add the people, services, utilities, and policies that help run this property.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    Button {
                        Haptics.light()
                        showAddVendor = true
                    } label: {
                        Text("Add a vendor or advisor")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.light()
                        addUtilityType = nil
                        showAddUtility = true
                    } label: {
                        Text("Add a utility or policy")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textPrimary)
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
                        Text("Ask Alfred to find a pro")
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
            Text("No relationships match")
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

    private func contractorRow(
        _ contractor: ContractorRow,
        showAttentionReason: Bool = false
    ) -> some View {
        let reason = showAttentionReason ? attentionReason(for: contractor) : nil
        return HStack(spacing: HavenTheme.spacing12) {
            VendorLogoView(contractor: contractor, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(displayName(for: contractor))
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    // Phase 85 — surface "Chez owns this contact" inline so
                    // the homeowner can scan their contact list and see at a
                    // glance which vendors Chez is the point of contact for.
                    if contractor.isChezOwned {
                        ChezOwnsBadge(compact: true)
                    }
                }
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
                            recurringBadge
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

    private func utilityRow(
        _ account: UtilityAccountRow,
        showAttentionReason: Bool = false
    ) -> some View {
        let reason = showAttentionReason ? utilityAttentionReason(for: account) : nil

        return HStack(spacing: HavenTheme.spacing12) {
            VendorLogoView(
                logoUrl: account.logoUrl,
                category: utilityCategory(for: account),
                vendorName: account.providerName,
                size: 32
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(account.providerName)
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
                        Text(utilityRoleLabel(for: account))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                        if isRecurringUtilityAccount(account) {
                            recurringBadge
                        }
                    }
                    if let subtitle = utilityActivitySubtitle(for: account) {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(HavenColors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, 10)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var recurringBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 8, weight: .semibold))
            Text("Recurring")
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
        let genericLabels: Set<String> = [
            "Contractor / Service Provider", "Attorney",
            "Financial Advisor / CPA", "Insurance Agent",
            "Property Manager", "Other"
        ]
        let specific = specialties.filter { !genericLabels.contains($0) }
        let pool = specific.isEmpty ? specialties : specific
        let visible = Array(pool.prefix(2))
        var caption = visible.joined(separator: " \u{00B7} ")
        let hidden = pool.count - visible.count
        if hidden > 0 { caption += " +\(hidden)" }
        return caption.isEmpty ? contractor.contactName : caption
    }

    // MARK: Directory model

    private var directoryRelationships: [PropertyRelationshipItem] {
        let visibleUtilities = viewModel.utilityAccounts
            .filter(shouldShowUtilityAccount)
            .map(PropertyRelationshipItem.utility)
        let serviceRelationships = viewModel.contractors.map(PropertyRelationshipItem.contractor)

        return (serviceRelationships + visibleUtilities)
            .sorted {
                relationshipDisplayName(for: $0)
                    .localizedCaseInsensitiveCompare(relationshipDisplayName(for: $1)) == .orderedAscending
            }
    }

    private var filteredContacts: [PropertyRelationshipItem] {
        var result = directoryRelationships

        let trimmed = contactsSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let needle = trimmed.lowercased()
            result = result.filter { relationshipMatchesSearch($0, needle: needle) }
        }

        switch contactsFilter {
        case .all:
            break
        case .serviceBased:
            result = result.filter(isHomeServiceRelationship)
        case .utilitiesPolicies:
            result = result.filter(isUtilityPolicyRelationship)
        case .routine:
            result = result.filter(isRecurringRelationship)
        case .needsAttention:
            result = result.filter(isRelationshipNeedingReview)
        }

        return result
    }

    private var directorySummaryLine: String {
        let homeServices = directoryRelationships.filter(isHomeServiceRelationship).count
        let utilities = directoryRelationships.filter(isUtilityPolicyRelationship).count

        var parts: [String] = []
        if homeServices > 0 {
            parts.append("\(homeServices) home service\(homeServices == 1 ? "" : "s")")
        }
        if utilities > 0 {
            parts.append("\(utilities) utilit\(utilities == 1 ? "y" : "ies") & polic\(utilities == 1 ? "y" : "ies")")
        }

        if parts.isEmpty {
            return "Keep the companies and advisors for this property in one place."
        }

        return parts.joined(separator: " · ")
    }

    private func relationshipDisplayName(for relationship: PropertyRelationshipItem) -> String {
        switch relationship {
        case .contractor(let contractor):
            return displayName(for: contractor)
        case .utility(let account):
            return account.providerName
        }
    }

    private func relationshipMatchesSearch(_ relationship: PropertyRelationshipItem, needle: String) -> Bool {
        switch relationship {
        case .contractor(let contractor):
            if contractor.companyName.lowercased().contains(needle) { return true }
            if let name = contractor.contactName?.lowercased(), name.contains(needle) { return true }
            if let specialties = contractor.specialties,
               specialties.contains(where: { $0.lowercased().contains(needle) }) {
                return true
            }
            if let category = contractor.category?.lowercased(), category.contains(needle) { return true }
            return false

        case .utility(let account):
            if account.providerName.lowercased().contains(needle) { return true }
            if account.typeLabel.lowercased().contains(needle) { return true }
            if let planName = account.planName?.lowercased(), planName.contains(needle) { return true }
            if let accountNumber = account.accountNumber?.lowercased(), accountNumber.contains(needle) { return true }
            return false
        }
    }

    private func isHomeServiceRelationship(_ relationship: PropertyRelationshipItem) -> Bool {
        switch relationship {
        case .contractor:
            return true
        case .utility(let account):
            return UtilityContractorMirror.serviceCategory(forProviderType: account.providerType) != nil
        }
    }

    private func isUtilityPolicyRelationship(_ relationship: PropertyRelationshipItem) -> Bool {
        switch relationship {
        case .contractor:
            return false
        case .utility(let account):
            return UtilityContractorMirror.serviceCategory(forProviderType: account.providerType) == nil
        }
    }

    private func isRecurringRelationship(_ relationship: PropertyRelationshipItem) -> Bool {
        switch relationship {
        case .contractor(let contractor):
            return isRoutineServed(contractor)
        case .utility(let account):
            return isRecurringUtilityAccount(account)
        }
    }

    private func isRelationshipNeedingReview(_ relationship: PropertyRelationshipItem) -> Bool {
        switch relationship {
        case .contractor(let contractor):
            guard !attentionDismissedIds.contains(contractor.id) else { return false }
            return !missingFields(for: contractor).isEmpty
        case .utility(let account):
            return !missingFields(for: account).isEmpty
        }
    }

    private func matchedContractor(for account: UtilityAccountRow) -> ContractorRow? {
        if let providerId = account.providerId,
           let exact = viewModel.contractors.first(where: { $0.utilityProviderId == providerId }) {
            return exact
        }

        let loweredName = account.providerName.lowercased()
        return viewModel.contractors.first(where: { $0.companyName.lowercased() == loweredName })
    }

    private func shouldShowUtilityAccount(_ account: UtilityAccountRow) -> Bool {
        guard UtilityContractorMirror.serviceCategory(forProviderType: account.providerType) != nil else {
            return true
        }
        return matchedContractor(for: account) == nil
    }

    private func isRecurringUtilityAccount(_ account: UtilityAccountRow) -> Bool {
        UtilityContractorMirror.serviceCategory(forProviderType: account.providerType) != nil
    }

    private func utilityCategory(for account: UtilityAccountRow) -> String {
        UtilityContractorMirror.serviceCategory(forProviderType: account.providerType)
            ?? UtilityTypeMeta(account.providerType).label
    }

    private func utilityRoleLabel(for account: UtilityAccountRow) -> String {
        switch account.providerType {
        case "electric":
            return "Electric utility"
        case "internet_cable":
            return "Internet"
        case "home_insurance":
            return "Homeowners insurance"
        case "auto_insurance":
            return "Auto insurance"
        case "security":
            return "Security system"
        case "trash":
            return "Trash & recycling"
        case "natural_gas":
            return "Natural gas"
        case "pool_service":
            return "Pool service"
        default:
            return UtilityTypeMeta(account.providerType).label
        }
    }

    private func utilityActivitySubtitle(for account: UtilityAccountRow) -> String? {
        if let accountNumber = account.accountNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
           !accountNumber.isEmpty {
            return "Account ending \(String(accountNumber.suffix(4)))"
        }
        if let planName = account.planName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !planName.isEmpty {
            return planName
        }
        if let monthlyCost = account.monthlyCost, monthlyCost > 0 {
            return "\(monthlyCost.formattedCompactCurrency()) per month"
        }
        if let phone = account.phone?.trimmingCharacters(in: .whitespacesAndNewlines),
           !phone.isEmpty {
            return phone
        }
        return isRecurringUtilityAccount(account) ? "Active service relationship" : "Active"
    }

    private func missingFields(for account: UtilityAccountRow) -> [String] {
        var missing: [String] = []

        let hasAccountDetails =
            !(account.accountNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            || !(account.planName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            || (account.monthlyCost ?? 0) > 0
        if !hasAccountDetails {
            missing.append("account details")
        }

        let hasContactInfo =
            !(account.phone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            || !(account.website?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if !hasContactInfo {
            missing.append("contact info")
        }

        return missing
    }

    private func utilityAttentionReason(for account: UtilityAccountRow) -> String? {
        let fields = missingFields(for: account)
        guard !fields.isEmpty else { return nil }
        return "Needs \(fields.joined(separator: " \u{00B7} "))"
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
                    Text("Recent Services")
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
                            Text([
                                record.serviceDate.havenDateShort,
                                viewModel.contractor(for: record.contractorId)?.companyName,
                            ]
                            .compactMap { $0 }
                            .joined(separator: " · "))
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
                .foregroundStyle(HavenColors.textPrimary)
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
        if name.contains("Climate") { return "Climate" }
        if name.contains("Structure") { return "Exterior" }
        if name.contains("Plumbing") { return "Plumbing" }
        if name.contains("Electrical") { return "Safety" }
        if name.contains("Specialty") { return "Specialty" }
        return name
    }

    private func systemGroupCard(_ group: SystemGroup) -> some View {
        VStack(spacing: 8) {
            Image(systemName: group.icon)
                .font(.system(size: 22))
                .foregroundStyle(HavenColors.navy700)

            Text(group.name)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text("\(group.systems.count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.textPrimary)
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
