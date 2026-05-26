import SwiftUI

enum MaintenanceDateFormatting {
    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func date(from isoDate: String) -> Date? {
        isoFormatter.date(from: isoDate)
    }

    private static let shortWithYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    static func shortDate(_ isoDate: String) -> String {
        guard let date = date(from: isoDate) else { return isoDate }
        return shortFormatter.string(from: date)
    }

    /// Round 4 (May 2026, friend feedback): the friend saw "May 16" and
    /// "May 15" back-to-back on the ADT routine detail and reasonably
    /// read them as duplicate-day visits. They were actually a year apart
    /// (2027-05-16 and 2028-05-15 — the latter wrong by 1 day, fixed
    /// separately by the leap-year math change). For projected routine
    /// visits and any date that might be >12 months out, prefer this
    /// formatter so the year is visible when it matters. Returns "MMM d"
    /// for dates in the current year, "MMM d, yyyy" otherwise.
    static func shortDateSmart(_ isoDate: String) -> String {
        guard let date = date(from: isoDate) else { return isoDate }
        let calendar = Calendar.current
        if calendar.component(.year, from: date) == calendar.component(.year, from: Date()) {
            return shortFormatter.string(from: date)
        }
        return shortWithYearFormatter.string(from: date)
    }

    static func dueLabel(for isoDate: String) -> String {
        guard let dueDate = date(from: isoDate) else { return "Due \(isoDate)" }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0

        switch days {
        case ..<0:
            return days == -1 ? "Overdue by 1 day" : "Overdue by \(abs(days)) days"
        case 0:
            return "Due today"
        case 1:
            return "Due tomorrow"
        case 2...6:
            return "Due in \(days) days"
        default:
            return "Due \(shortDate(isoDate))"
        }
    }
}

enum MaintenanceActionAccent: Hashable {
    case coral
    case navy
    case gold
    case green
}

struct SeasonalServiceSummary: Identifiable {
    enum Status: Equatable {
        case needsRouting
        case handymanRecommended
        case vendorAssigned(String)
        case diy
    }

    let groupKey: String
    let serviceKey: String
    let title: String
    let dueDate: String
    let representativeTask: MaintenanceTaskDBRow
    let tasks: [MaintenanceTaskDBRow]
    let definition: ServiceDefinition?
    let status: Status

    var id: String { groupKey }
    var includedCount: Int { tasks.count }
    var dueLabel: String { MaintenanceDateFormatting.dueLabel(for: dueDate) }
    var shortDueDate: String { MaintenanceDateFormatting.shortDate(dueDate) }

    var statusLabel: String {
        switch status {
        case .needsRouting:
            return "Needs a vendor"
        case .handymanRecommended:
            return "Ready to bundle"
        case .vendorAssigned:
            return "Scheduled"
        case .diy:
            return "You're handling this"
        }
    }

    var ownerLabel: String {
        switch status {
        case .needsRouting:
            return "You"
        case .handymanRecommended:
            return "Chez"
        case .vendorAssigned(let vendorName):
            return vendorName.isEmpty ? "Vendor" : vendorName
        case .diy:
            return "You"
        }
    }

    var ownershipSummary: String {
        switch status {
        case .needsRouting:
            return "You need to choose a vendor before Chez can schedule this."
        case .handymanRecommended:
            return "Chez can likely bundle this into one contractor visit."
        case .vendorAssigned(let vendorName):
            let name = vendorName.isEmpty ? "Your vendor" : vendorName
            return "\(name) is handling this."
        case .diy:
            return "This stays on your list until you mark it done."
        }
    }

    var ctaTitle: String {
        switch status {
        case .needsRouting:
            return "Choose vendor"
        case .handymanRecommended:
            return "Add to bundle"
        case .vendorAssigned, .diy:
            return "View"
        }
    }

    var needsDecision: Bool {
        if case .needsRouting = status {
            return true
        }
        return false
    }

    var isReadyToBundle: Bool {
        if case .handymanRecommended = status {
            return true
        }
        return false
    }

    var isCovered: Bool {
        switch status {
        case .vendorAssigned, .diy:
            return true
        case .needsRouting, .handymanRecommended:
            return false
        }
    }

    var needsAttention: Bool {
        needsDecision || isReadyToBundle
    }
}

struct MaintenanceSeasonPlan {
    let season: YearAtAGlanceCard.Season
    let pendingProgramBundles: [PendingProgramBundleSummary]
    let activeRoutines: [RoutineRow]
    let services: [SeasonalServiceSummary]
}

extension MaintenanceSeasonPlan {
    var decisionServices: [SeasonalServiceSummary] {
        services.filter(\.needsDecision)
    }

    var bundleServices: [SeasonalServiceSummary] {
        services.filter(\.isReadyToBundle)
    }

    var coveredServices: [SeasonalServiceSummary] {
        services.filter(\.isCovered)
    }

    var totalItemCount: Int {
        pendingProgramBundles.count + activeRoutines.count + services.count
    }

    var coveredItemCount: Int {
        activeRoutines.count + coveredServices.count
    }

    var decisionCount: Int {
        pendingProgramBundles.count + decisionServices.count
    }

    var bundleOpportunityCount: Int {
        bundleServices.count
    }

    var openActionCount: Int {
        decisionCount + bundleOpportunityCount
    }

    var coverageRatio: Double {
        guard totalItemCount > 0 else { return 1 }
        return Double(coveredItemCount) / Double(totalItemCount)
    }

    var coveragePercent: Int {
        Int((coverageRatio * 100).rounded())
    }

    var readinessHeadline: String {
        guard totalItemCount > 0 else {
            return "\(season.displayLabel) maintenance is clear."
        }

        switch coverageRatio {
        case 0.9...:
            return "\(season.displayLabel) maintenance is well scheduled."
        case 0.65...:
            return "\(season.displayLabel) maintenance is mostly scheduled."
        default:
            return "\(season.displayLabel) maintenance needs a few decisions."
        }
    }

    var readinessSubheadline: String {
        // Phase 95.1 fix: relabel "items" → "tasks" to disambiguate from
        // the Dashboard HomeCoverageHero metric which counts vendor
        // coverage CATEGORIES (e.g. "5 of 14 systems covered"). Tapping
        // the dashboard hero lands here and previously showed a wildly
        // different number ("97 of 124 covered") with the same word
        // "covered" — read as a contradiction. New copy uses "tasks
        // scheduled / on track" so it's clearly a different unit.
        // Caught by overnight E2E (W4S16 Dashboard usefulness review).
        guard totalItemCount > 0 else {
            return "Chez will surface work here as the season fills in."
        }

        if openActionCount == 0 {
            return "\(coveredItemCount) of \(totalItemCount) tasks scheduled and on track."
        }

        return "\(coveredItemCount) of \(totalItemCount) tasks scheduled. \(openActionCount) still need attention."
    }

    var earliestActionDate: String? {
        (
            pendingProgramBundles.map(\.earliestNextDate) +
            decisionServices.map(\.dueDate) +
            bundleServices.map(\.dueDate)
        )
        .filter { !$0.isEmpty }
        .sorted()
        .first
    }

    var actionSummary: String {
        guard openActionCount > 0 else {
            return "Nothing is blocking Chez right now."
        }

        if let earliestActionDate {
            return "\(openActionCount) need action before \(MaintenanceDateFormatting.shortDate(earliestActionDate))."
        }

        return "\(openActionCount) need action."
    }
}

struct PendingProgramBundleSummary: Identifiable {
    let key: String
    let title: String
    let subtitle: String
    let vendorSearchCategory: String
    let routines: [RoutineRow]

    var id: String { key }
    var primaryRoutine: RoutineRow { routines[0] }
    var earliestNextDate: String {
        routines
            .map(\.nextExpectedDate)
            .filter { !$0.isEmpty }
            .sorted()
            .first ?? ""
    }
    var includedProgramTitles: [String] {
        routines.map { ServiceLibrary.homeownerTitle(for: $0) }
    }
}

struct SmartRoutineSetupContext: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let serviceKey: String
    let draftPreset: RoutineDraftPreset
    let sourceUtilityAccount: UtilityAccountRow?
    let promptTitle: String
    let promptBody: String
    let navigationTitle: String
    let ctaTitle: String
    let icon: String
    let showsWeekdayPicker: Bool
    let showsCadencePicker: Bool
    let showsActiveMonths: Bool
    let defaultEveningBeforeReminder: Bool
    let defaultMorningOfReminder: Bool
    let allowedCadenceTypes: [RoutineCadenceType]
    let weekdaySectionTitle: String
    let weekdayHelperText: String
}

struct SmartDocumentSetupContext: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let providerName: String
    let contractorId: UUID?
    let propertyId: UUID?
    let preselectedCategory: DocumentCategory
}

struct SmartSetupCard: Identifiable {
    enum Completion {
        case routine(SmartRoutineSetupContext)
        case document(SmartDocumentSetupContext)
    }

    let id: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let ctaTitle: String
    let icon: String
    let accent: MaintenanceActionAccent
    let completion: Completion
}

struct MaintenanceActionItem: Identifiable {
    enum Destination {
        case pendingProgram(PendingProgramBundleSummary)
        case routine(RoutineRow)
        case seasonalService(SeasonalServiceSummary)
        case smartSetupCard(SmartSetupCard)
        case handymanQueue
        case projects
    }

    let id: String
    let accent: MaintenanceActionAccent
    let icon: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let ctaTitle: String
    let destination: Destination
}

/// Phase 66: The new Maintenance tab. Five sections on top of the existing
/// `routines` + `maintenance_tasks` tables. Replaces the Phase 56.5
/// Scheduled/To-Schedule bucket layout as the default entry point;
/// MaintenanceScheduleView continues to exist as the Timeline / full-
/// schedule push destination accessed via "See full year ↗" at the top.
///
/// Data flow:
///   1. Load active + pending-vendor routines for the property (Your Services)
///   2. Load the singleton handyman routine + its child tasks
///   3. Load vehicle-scoped routines for the household
///   4. Load unparented tasks due within 90 days (This Season)
///   5. Load scheduled routine_visits (Upcoming Scheduled)
///
/// The parent nav stack owns routing. We use NavigationLink(value:) with
/// hashable destinations so the same push target can be reached from
/// multiple sections.
struct MaintenanceHubView: View {
    /// Optional property filter. When nil, uses the household's primary
    /// property. Set by callers that already know the property.
    let filterPropertyId: UUID?
    let embedded: Bool

    init(filterPropertyId: UUID? = nil, embedded: Bool = false) {
        self.filterPropertyId = filterPropertyId
        self.embedded = embedded
    }

    @StateObject private var viewModel = MaintenanceHubViewModel()
    @State private var editingRoutine: RoutineRow?
    @State private var selectedTaskDetail: MaintenanceTaskDBRow?
    @State private var selectedPendingProgramBundle: PendingProgramBundleSummary?
    @State private var pendingProgramVendorSearch: PendingProgramBundleSummary?
    @State private var pendingProgramManualVendorPicker: PendingProgramBundleSummary?
    @State private var pendingProgramSearchAppliesToRelated = true
    @State private var showHandymanQueue = false
    @State private var showHandymanPunchList = false
    @State private var showProjects = false
    @State private var showAddTaskSheet = false
    @State private var showAddRoutineSheet = false
    @State private var showAddVendorSheet = false
    @State private var addSheetMode: AddMaintenanceTaskSheet.EntryMode = .seasonalService
    @State private var routineDraftPreset: RoutineDraftPreset?
    @State private var selectedSmartRoutineSetup: SmartRoutineSetupContext?
    @State private var selectedSmartDocumentSetup: SmartDocumentSetupContext?
    /// Phase 67C: Season selected from Year at a Glance — opens a
    /// season-scoped list sheet. Nil when not looking at a specific season.
    @State private var expandedSeason: YearAtAGlanceCard.Season?
    /// Phase 67D: Task selected for orchestration — presents the unified
    /// routing menu in a sheet. Nil when not routing.
    @State private var orchestratingTask: MaintenanceTaskDBRow?
    /// BUG-013 fix: Vehicle pending shop setup. Was previously a dead
    /// notification post that nothing observed.
    @State private var setupVehicle: VehicleRow?

    var body: some View {
        Group {
            if embedded {
                embeddedContent
            } else {
                standaloneContent
            }
        }
        .task {
            await viewModel.load(filterPropertyId: filterPropertyId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openManualContractorAdd)) { _ in
            if let bundle = pendingProgramVendorSearch {
                pendingProgramVendorSearch = nil
                pendingProgramManualVendorPicker = bundle
            }
        }
        .sheet(isPresented: $showAddTaskSheet, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) {
            NavigationStack {
                AddMaintenanceTaskSheet(
                    properties: viewModel.properties,
                    systems: viewModel.systems,
                    vehicles: viewModel.vehicles,
                    contractors: Array(viewModel.vendorsById.values).sorted {
                        $0.companyName.localizedCaseInsensitiveCompare($1.companyName) == .orderedAscending
                    },
                    householdUsers: viewModel.householdUsers,
                    householdFamilyMembers: viewModel.householdFamilyMembers,
                    viewModel: nil,
                    onSave: { Task { await viewModel.load(filterPropertyId: filterPropertyId) } },
                    initialEntryMode: addSheetMode,
                    initialPropertyId: viewModel.resolvedPropertyId
                )
            }
        }
        .sheet(isPresented: $showAddRoutineSheet, onDismiss: {
            routineDraftPreset = nil
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) {
            if let householdId = viewModel.householdId {
                NavigationStack {
                    RoutineEditSheet(
                        householdId: householdId,
                        propertyId: viewModel.resolvedPropertyId,
                        preset: routineDraftPreset,
                        onSaved: {
                            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showAddVendorSheet, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) {
            AddVendorSheet(onComplete: {
                Task { await viewModel.load(filterPropertyId: filterPropertyId) }
            })
        }
        .sheet(item: $selectedSmartRoutineSetup, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) { context in
            if let householdId = viewModel.householdId {
                NavigationStack {
                    SmartRoutineSetupSheet(
                        context: context,
                        householdId: householdId,
                        propertyId: viewModel.resolvedPropertyId,
                        onSaved: {
                            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
                        }
                    )
                }
            }
        }
        .sheet(item: $selectedSmartDocumentSetup, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) { context in
            DocumentUploadView(
                preselectedCategory: context.preselectedCategory,
                preselectedPropertyId: context.propertyId ?? viewModel.resolvedPropertyId,
                preselectedContractorId: context.contractorId,
                onComplete: {
                    Task { await viewModel.load(filterPropertyId: filterPropertyId) }
                }
            )
        }
        .sheet(item: $editingRoutine, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) { routine in
            NavigationStack {
                RoutineDetailView(
                    routine: routine,
                    householdId: viewModel.householdId ?? routine.householdId
                )
            }
        }
        .sheet(item: $selectedPendingProgramBundle, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) { bundle in
            NavigationStack {
                PendingProgramSetupSheet(
                    bundle: bundle,
                    property: viewModel.activeProperty,
                    vendors: Array(viewModel.vendorsById.values),
                    onAssignedVendor: { contractor, applyToRelatedPrograms in
                        Task {
                            await viewModel.assignVendor(
                                contractor,
                                to: bundle,
                                applyToRelatedPrograms: applyToRelatedPrograms
                            )
                            selectedPendingProgramBundle = nil
                        }
                    },
                    onSearchLocally: { applyToRelatedPrograms in
                        pendingProgramSearchAppliesToRelated = applyToRelatedPrograms
                        selectedPendingProgramBundle = nil
                        pendingProgramVendorSearch = bundle
                    },
                    onHandleMyself: { applyToRelatedPrograms in
                        Task {
                            await viewModel.activatePendingPrograms(
                                bundle,
                                vendor: nil,
                                applyToRelatedPrograms: applyToRelatedPrograms
                            )
                            selectedPendingProgramBundle = nil
                        }
                    },
                    onAskAlfred: {
                        viewModel.askAlfredAboutPendingProgram(bundle)
                        selectedPendingProgramBundle = nil
                    }
                )
            }
        }
        .sheet(item: $pendingProgramVendorSearch, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) { bundle in
            if let property = viewModel.activeProperty,
               let town = property.city,
               let state = property.state,
               !town.isEmpty,
               !state.isEmpty {
                FindLocalVendorSheet(
                    task: nil,
                    householdId: property.householdId,
                    town: town,
                    state: state,
                    systemCategory: bundle.vendorSearchCategory,
                    categoryDisplayName: bundle.vendorSearchCategory.lowercased(),
                    onComplete: {
                        Task { await viewModel.load(filterPropertyId: filterPropertyId) }
                    },
                    onAdoptedVendor: { contractor in
                        Task {
                            await viewModel.assignVendor(
                                contractor,
                                to: bundle,
                                applyToRelatedPrograms: pendingProgramSearchAppliesToRelated
                            )
                            pendingProgramVendorSearch = nil
                        }
                    }
                )
            } else {
                AddVendorSheet(onComplete: {
                    pendingProgramVendorSearch = nil
                    pendingProgramManualVendorPicker = bundle
                }, prefilledCategory: bundle.vendorSearchCategory)
            }
        }
        .sheet(item: $pendingProgramManualVendorPicker, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) { bundle in
            NavigationStack {
                ContractorDirectoryView(onSelect: { contractor in
                    pendingProgramManualVendorPicker = nil
                    Task {
                        await viewModel.assignVendor(
                            contractor,
                            to: bundle,
                            applyToRelatedPrograms: pendingProgramSearchAppliesToRelated
                        )
                    }
                })
            }
        }
        .sheet(item: $selectedTaskDetail) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(
                    task: task,
                    onDeleteTask: {
                        let taskId = task.id
                        Task {
                            try? await DatabaseService.shared.deleteMaintenanceTask(id: taskId)
                            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $expandedSeason) { season in
            NavigationStack {
                SeasonTasksSheet(
                    season: season,
                    plan: viewModel.seasonPlan(for: season),
                    onTapPendingProgram: { selectedPendingProgramBundle = $0 },
                    onTapRoutine: handleRoutineTap,
                    onTapService: { selectedTaskDetail = $0.representativeTask },
                    onTapRoute: { orchestratingTask = $0.representativeTask },
                    onOpenHandymanQueue: { showHandymanQueue = true },
                    onAskHaven: { viewModel.askHavenToHandle(season: season) }
                )
            }
        }
        .sheet(isPresented: $showHandymanQueue, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) {
            if let householdId = viewModel.householdId {
                NavigationStack {
                    HandymanQueueView(
                        householdId: householdId,
                        propertyId: viewModel.resolvedPropertyId,
                        routine: viewModel.handymanRoutine,
                        queuedTasks: viewModel.handymanTasks,
                        seasonalVisitPlans: viewModel.handymanSeasonalPlans,
                        suggestedTasks: viewModel.handymanSuggestedTasks,
                        preferredHandyman: viewModel.preferredHandyman,
                        nextVisit: viewModel.nextHandymanVisit,
                        onFindHandyman: { viewModel.openFindHandyman() },
                        onChanged: {
                            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showHandymanPunchList, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) {
            if let householdId = viewModel.householdId {
                NavigationStack {
                    HandymanPunchListView(
                        householdId: householdId,
                        propertyId: viewModel.resolvedPropertyId
                    )
                }
            }
        }
        .sheet(isPresented: $showProjects, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) {
            if let propertyId = viewModel.resolvedPropertyId {
                NavigationStack {
                    PropertyProjectsView(
                        propertyID: propertyId,
                        householdId: viewModel.householdId
                    )
                }
            }
        }
        .sheet(item: $setupVehicle, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) { vehicle in
            VehicleProgramSetupSheet(
                vehicle: vehicle,
                householdId: viewModel.householdId ?? vehicle.householdId,
                onSaved: {
                    Task { await viewModel.load(filterPropertyId: filterPropertyId) }
                }
            )
        }
        .sheet(item: $orchestratingTask) { task in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(HavenTypography.headline)
                            Text("Due \(task.nextDueDate)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        UnifiedRoutingMenu(
                            task: task,
                            taskCategory: viewModel.categoryForTask(task),
                            handymanVendor: viewModel.preferredHandyman,
                            categoryVendorRoutine: viewModel.vendorRoutineForCategory(
                                viewModel.categoryForTask(task)
                            ),
                            categoryVendor: viewModel.vendorForCategory(
                                viewModel.categoryForTask(task)
                            ),
                            onRouteToHandyman: {
                                Task {
                                    try? await UnifiedRoutingActions.routeToHandyman(
                                        task: task,
                                        category: viewModel.categoryForTask(task)
                                    )
                                    orchestratingTask = nil
                                }
                            },
                            onRouteToVendor: {
                                Task {
                                    guard let routine = viewModel.vendorRoutineForCategory(
                                        viewModel.categoryForTask(task)
                                    ) else {
                                        orchestratingTask = nil
                                        return
                                    }
                                    try? await UnifiedRoutingActions.routeToVendor(
                                        task: task,
                                        routine: routine,
                                        category: viewModel.categoryForTask(task)
                                    )
                                    orchestratingTask = nil
                                }
                            },
                            onFindDifferentVendor: {
                                orchestratingTask = nil
                                selectedTaskDetail = task
                            },
                            onDIYMyself: {
                                Task {
                                    try? await UnifiedRoutingActions.markDIY(
                                        task: task,
                                        category: viewModel.categoryForTask(task)
                                    )
                                    orchestratingTask = nil
                                }
                            },
                            onAskAlfred: {
                                orchestratingTask = nil
                                NotificationCenter.default.post(
                                    name: .openAlfredWithContext,
                                    object: nil,
                                    userInfo: [
                                        "message": "Who should handle this task: \(task.title)?"
                                    ]
                                )
                            }
                        )
                    }
                    .padding(HavenTheme.spacing20)
                }
                .navigationTitle("Who handles this?")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { orchestratingTask = nil }
                    }
                }
                .onAppear {
                    Analytics.track(.unifiedRoutingPickerOpened, [
                        "task_id": task.id.uuidString,
                        "source": "this_season_chip"
                    ])
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var standaloneContent: some View {
        ScrollView {
            hubSections
                .padding(.horizontal, HavenTheme.spacing20)
                .padding(.vertical, HavenTheme.spacing16)
                .padding(.bottom, 120)
        }
        .background(HavenColors.background)
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        addSheetMode = .seasonalService
                        showAddTaskSheet = true
                    } label: {
                        Label("Add a task", systemImage: "checklist")
                    }

                    Button {
                        routineDraftPreset = nil
                        showAddRoutineSheet = true
                    } label: {
                        Label("Add a recurring program", systemImage: "calendar.badge.plus")
                    }

                    // Chez v1: handyman item add lives in Tasks → Handyman.
                    // The maintenance toolbar focuses on vendor + routine
                    // orchestration only.

                    Divider()

                    Button {
                        showAddVendorSheet = true
                    } label: {
                        Label("Add a vendor", systemImage: "person.crop.rectangle.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .refreshable {
            await viewModel.load(filterPropertyId: filterPropertyId)
        }
    }

    private var embeddedContent: some View {
        hubSections
            .padding(.vertical, HavenTheme.spacing8)
            .background(HavenColors.background)
    }

    @ViewBuilder
    private var hubSections: some View {
        if viewModel.isLoading && viewModel.hasNoContent {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                // Chez v1: NextHandymanVisitSection moved to the Tasks tab's
                // Handyman segment (HandymanHubView) so this surface is
                // purely about vendor orchestration. Handyman state on the
                // view model stays loaded for the action-center "Pick a
                // pro" cards but doesn't render its own card here.

                ActionCenterSection(
                    items: viewModel.actionItems,
                    setupCards: viewModel.smartSetupCards,
                    onTapItem: handleActionItemTap,
                    onTapSetup: handleSmartSetupTap
                )

                UpcomingScheduledSection(
                    visits: viewModel.scheduledVisits,
                    routinesById: viewModel.allRoutinesById,
                    onTapVisit: { visit in
                        if let routine = viewModel.allRoutinesById[visit.routineId] {
                            handleRoutineTap(routine)
                        }
                    }
                )

                ThisSeasonSection(
                    plan: viewModel.currentSeasonPlan,
                    onOpenFullSeason: {
                        expandedSeason = viewModel.currentSeason
                    },
                    onAskHaven: {
                        viewModel.askHavenToHandle(season: viewModel.currentSeason)
                    }
                )

                YourServicesSection(
                    activeRoutines: viewModel.activeRoutines,
                    vendorsById: viewModel.vendorsById,
                    utilityAccountsById: viewModel.utilityAccountsById,
                    nextVisitsByRoutineId: viewModel.nextVisitsByRoutineId,
                    nextVisitPreviewsByRoutineId: viewModel.nextVisitPreviewsByRoutineId,
                    onTapRoutine: handleRoutineTap,
                    onSetupRoutine: {
                        routineDraftPreset = nil
                        showAddRoutineSheet = true
                    }
                )

                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    seeFullYearLink

                    YearAtAGlanceCard(
                        seasons: viewModel.seasonSummaries,
                        onTapSeason: { season in
                            expandedSeason = season
                            Analytics.track(.yearAtAGlanceSeasonOpened, [
                                "season": season.rawValue,
                                "count": viewModel.seasonSummaries.first(where: { $0.season == season })?.count ?? 0
                            ])
                        }
                    )

                    browseRecommendedServicesLink
                }

                if !embedded {
                    ProjectsAndQuotesSection(
                        projects: viewModel.activeProjects,
                        onOpenProjects: {
                            guard viewModel.resolvedPropertyId != nil else { return }
                            showProjects = true
                        }
                    )

                    VehiclesSection(
                        vehicles: viewModel.vehicles,
                        routinesByVehicle: viewModel.vehicleRoutinesByVehicle,
                        tasksByVehicle: viewModel.tasksByVehicle,
                        shopsById: viewModel.vendorsById,
                        onTapVehicle: handleVehicleTap,
                        onSetupVehicle: handleVehicleSetup
                    )
                }
            }
            .padding(.bottom, embedded ? HavenTheme.spacing8 : 120)
        }
    }

    private func handleActionItemTap(_ item: MaintenanceActionItem) {
        switch item.destination {
        case .pendingProgram(let bundle):
            selectedPendingProgramBundle = bundle
        case .routine(let routine):
            handleRoutineTap(routine)
        case .seasonalService(let service):
            if service.needsDecision || service.isReadyToBundle {
                orchestratingTask = service.representativeTask
            } else {
                selectedTaskDetail = service.representativeTask
            }
        case .smartSetupCard(let card):
            handleSmartSetupTap(card)
        case .handymanQueue:
            showHandymanQueue = true
        case .projects:
            guard viewModel.resolvedPropertyId != nil else { return }
            showProjects = true
        }
    }

    private func handleSmartSetupTap(_ card: SmartSetupCard) {
        switch card.completion {
        case .routine(let context):
            selectedSmartRoutineSetup = context
        case .document(let context):
            selectedSmartDocumentSetup = context
        }
    }

    private func handleRoutineTap(_ routine: RoutineRow) {
        if routine.typedSetupState == .pendingVendor,
           let bundle = viewModel.pendingProgramBundle(containing: routine) {
            selectedPendingProgramBundle = bundle
        } else {
            editingRoutine = routine
        }
    }

    private func handleVehicleTap(_ vehicle: VehicleRow) {
        if let routine = viewModel.vehicleRoutinesByVehicle[vehicle.id] {
            editingRoutine = routine
            Analytics.track(.vehicleRoutineOpened, [
                "vehicle_id": vehicle.id.uuidString,
                "routine_id": routine.id.uuidString
            ])
        } else {
            setupVehicle = vehicle
        }
    }

    private func handleVehicleSetup(_ vehicle: VehicleRow) {
        setupVehicle = vehicle
    }

    /// Discovery hop into the Phase 54C "Recommended for your home"
    /// catalog — seasonal services the household hasn't activated yet
    /// (pressure washing, deck staining, tree service, attic walk-down,
    /// etc.). Hidden when we don't have a household + property context
    /// because RecommendedServicesView requires both to load.
    @ViewBuilder
    private var browseRecommendedServicesLink: some View {
        if let householdId = viewModel.householdId,
           let propertyId = viewModel.resolvedPropertyId {
            NavigationLink {
                RecommendedServicesView(
                    householdId: householdId,
                    propertyId: propertyId
                )
            } label: {
                HavenCard(padding: HavenTheme.spacing12) {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(HavenColors.action)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .fill(HavenColors.actionPale)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Browse seasonal services")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Pressure washing, chimney sweeping, deck staining, tree service. Add what your home needs.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.textSoft)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var seeFullYearLink: some View {
        NavigationLink {
            MaintenanceYearPlanView(
                seasons: YearAtAGlanceCard.Season.allCases,
                planForSeason: { viewModel.seasonPlan(for: $0) },
                onTapPendingProgram: { selectedPendingProgramBundle = $0 },
                onTapRoutine: handleRoutineTap,
                onTapService: { selectedTaskDetail = $0.representativeTask },
                onTapRoute: { orchestratingTask = $0.representativeTask },
                onOpenHandymanQueue: { showHandymanQueue = true }
            )
            .onAppear { Analytics.track(.seeFullYearTapped, [:]) }
        } label: {
            HStack {
                Text("See full year")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.navy700)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HavenColors.navy700)
            }
            .padding(.vertical, HavenTheme.spacing8)
        }
    }
}

enum MaintenanceHubIcon {
    static func icon(for serviceKey: String?) -> String {
        switch serviceKey {
        case "roof_and_gutter_service":
            return "house.fill"
        case "exterior_envelope_and_sealant_service":
            return "paintbrush.fill"
        case "exterior_wash_and_facade_care":
            return "sparkles"
        case "deck_fence_and_hardscape_preservation":
            return "tree.fill"
        case "driveway_preservation_service":
            return "road.lanes"
        case "plumbing_risk_inspection", "water_protection_and_drainage_service", "well_and_pump_service", "water_treatment_service":
            return "drop.fill"
        case "water_heater_service":
            return "drop.degreesign.fill"
        case "hvac_program", "indoor_air_duct_and_humidity_service":
            return "wind"
        case "electrical_safety_and_backup_power_service", "security_and_smart_home_program":
            return "bolt.fill"
        case "garage_door_service", "garage_door_tune_up":
            return "door.garage.closed"
        case "fireplace_and_chimney_service":
            return "fireplace.fill"
        case "generator_program":
            return "bolt.batteryblock.fill"
        case "irrigation_program":
            return "sprinkler.and.droplets.fill"
        case "pool_program":
            return "drop.triangle.fill"
        case "hot_tub_program":
            return "bathtub.fill"
        case "waste_program":
            return "trash.fill"
        case "window_cleaning_program":
            return "window.vertical.open"
        case "mosquito_and_tick_program":
            return "ladybug.fill"
        case "pest_and_termite_program":
            return "ant.fill"
        case "tree_and_arborist_service":
            return "tree.circle.fill"
        case "handyman_program":
            return "hammer.fill"
        default:
            return "wrench.and.screwdriver.fill"
        }
    }
}

// MARK: - View Model

@MainActor
final class MaintenanceHubViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var activeRoutines: [RoutineRow] = []
    @Published var pendingRoutines: [RoutineRow] = []
    @Published var handymanRoutine: RoutineRow?
    @Published var handymanTasks: [MaintenanceTaskDBRow] = []
    @Published var handymanPunchItems: [HandymanPunchItemRow] = []
    @Published var handymanSuggestedTasks: [MaintenanceTaskDBRow] = []
    @Published var handymanSeasonalPlans: [HandymanSeasonalPlan] = []
    @Published var handymanRequests: [HandymanRequestRow] = []
    @Published var handymanPortalSession: HandymanPortalSessionRow?
    @Published var preferredHandyman: ContractorRow?
    @Published var vehicles: [VehicleRow] = []
    @Published var vehicleRoutinesByVehicle: [UUID: RoutineRow] = [:]
    @Published var tasksByVehicle: [UUID: [MaintenanceTaskDBRow]] = [:]
    @Published var thisSeasonTaskPool: [MaintenanceTaskDBRow] = []
    @Published var scheduledVisits: [RoutineVisitRow] = []
    @Published var vendorsById: [UUID: ContractorRow] = [:]
    @Published var allRoutinesById: [UUID: RoutineRow] = [:]
    @Published var activeProjects: [PropertyProjectRow] = []
    @Published var utilityAccounts: [UtilityAccountRow] = []
    @Published var smartSetupCards: [SmartSetupCard] = []
    @Published var householdId: UUID?
    @Published var resolvedPropertyId: UUID?
    @Published var properties: [PropertyRow] = []
    @Published var systems: [HomeSystemRow] = []
    @Published var householdUsers: [UserRow] = []
    @Published var householdFamilyMembers: [FamilyMemberRow] = []
    /// Phase 67C: All tasks for the current property (parented + unparented
    /// + vehicle) combined, used by Year at a Glance aggregation.
    @Published var allTaskList: [MaintenanceTaskDBRow] = []
    /// Phase 67C: Tasks grouped by their parent routine. Used to attribute
    /// routine-linked tasks to the routine's seasonal active_months.
    @Published var tasksByRoutine: [UUID: [MaintenanceTaskDBRow]] = [:]

    private let db = DatabaseService.shared

    /// Phase 67C: Seasonal aggregation for the Year at a Glance card.
    /// Recomputes cheaply from already-loaded state.
    var seasonSummaries: [YearAtAGlanceCard.SeasonSummary] {
        YearAtAGlanceCard.Season.allCases.map { season in
            let plan = seasonPlan(for: season)
            let titles = (
                plan.pendingProgramBundles.map(\.title) +
                plan.activeRoutines.map { ServiceLibrary.homeownerTitle(for: $0) } +
                plan.services.map(\.title)
            ).sorted()
            return YearAtAGlanceCard.SeasonSummary(
                season: season,
                count: titles.count,
                actionCount: plan.openActionCount,
                coveredCount: plan.coveredItemCount,
                previewTitles: Array(titles.prefix(3))
            )
        }
    }

    var currentSeasonPlan: MaintenanceSeasonPlan {
        seasonPlan(for: currentSeason)
    }

    var blockingDecisionCount: Int {
        pendingProgramBundles.count + currentSeasonPlan.decisionServices.count
    }

    var thisSeasonServices: [SeasonalServiceSummary] {
        Array(seasonPlan(for: currentSeason).services.prefix(5))
    }

    var currentSeason: YearAtAGlanceCard.Season {
        .current
    }

    var currentSeasonServiceCount: Int {
        seasonPlan(for: currentSeason).services.count
    }

    var activeProperty: PropertyRow? {
        guard let resolvedPropertyId else { return properties.first }
        return properties.first(where: { $0.id == resolvedPropertyId }) ?? properties.first
    }

    var nextVisitsByRoutineId: [UUID: RoutineVisitRow] {
        Dictionary(
            uniqueKeysWithValues: allRoutinesById.keys.compactMap { routineId in
                guard let visit = scheduledVisits
                    .filter({ $0.routineId == routineId && $0.typedVisitState.isScheduledOrActive })
                    .sorted(by: { $0.scheduledDate < $1.scheduledDate })
                    .first
                else {
                    return nil
                }
                return (routineId, visit)
            }
        )
    }

    var nextVisitPreviewsByRoutineId: [UUID: RoutineUpcomingVisitPreview] {
        let today = Calendar.current.startOfDay(for: Date())
        return Dictionary(
            uniqueKeysWithValues: activeRoutines.compactMap { routine in
                let existingVisits = scheduledVisits.filter { $0.routineId == routine.id }
                guard let preview = routine.upcomingVisitPreviews(
                    existingVisits: existingVisits,
                    limit: 1,
                    from: today
                ).first else {
                    return nil
                }
                return (routine.id, preview)
            }
        )
    }

    var utilityAccountsById: [UUID: UtilityAccountRow] {
        Dictionary(uniqueKeysWithValues: utilityAccounts.map { ($0.id, $0) })
    }

    var pendingProgramBundles: [PendingProgramBundleSummary] {
        pendingProgramBundles(from: pendingRoutines)
    }

    private func pendingProgramBundles(
        from pendingRoutines: [RoutineRow]
    ) -> [PendingProgramBundleSummary] {
        let groups = Dictionary(grouping: pendingRoutines, by: pendingProgramGroupKey(for:))

        return groups.compactMap { key, routines in
            let sorted = routines.sorted { lhs, rhs in
                if lhs.nextExpectedDate != rhs.nextExpectedDate {
                    return lhs.nextExpectedDate < rhs.nextExpectedDate
                }
                return ServiceLibrary.homeownerTitle(for: lhs) < ServiceLibrary.homeownerTitle(for: rhs)
            }
            guard !sorted.isEmpty else { return nil }

            return PendingProgramBundleSummary(
                key: key,
                title: pendingProgramTitle(for: key, routines: sorted),
                subtitle: pendingProgramSubtitle(for: key, routines: sorted),
                vendorSearchCategory: pendingProgramSearchCategory(for: key, routines: sorted),
                routines: sorted
            )
        }
        .sorted { lhs, rhs in
            if lhs.earliestNextDate != rhs.earliestNextDate {
                return lhs.earliestNextDate < rhs.earliestNextDate
            }
            return lhs.title < rhs.title
        }
    }

    var nextHandymanVisit: RoutineVisitRow? {
        guard let routine = handymanRoutine else { return nil }
        return scheduledVisits
            .filter { $0.routineId == routine.id && $0.typedVisitState.isScheduledOrActive }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }

    var primaryHandymanVisitTask: MaintenanceTaskDBRow? {
        handymanSeasonalPlans
            .compactMap(\.visitTask)
            .sorted { lhs, rhs in
                let left = lhs.scheduledDate ?? lhs.nextDueDate
                let right = rhs.scheduledDate ?? rhs.nextDueDate
                if left != right { return left < right }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            .first
    }

    var latestHandymanRequest: HandymanRequestRow? {
        if let visitTaskId = primaryHandymanVisitTask?.id,
           let visitRequest = handymanRequests.first(where: { $0.visitTaskId == visitTaskId }) {
            return visitRequest
        }
        return handymanRequests.first
    }

    var actionItems: [MaintenanceActionItem] {
        var items: [MaintenanceActionItem] = []

        for bundle in pendingProgramBundles.prefix(3) {
            let subtitle: String
            if !bundle.earliestNextDate.isEmpty {
                subtitle = "\(bundle.subtitle) Best to decide before \(MaintenanceDateFormatting.shortDate(bundle.earliestNextDate))."
            } else {
                subtitle = bundle.subtitle
            }

            items.append(
                MaintenanceActionItem(
                    id: "pending-\(bundle.id)",
                    accent: .coral,
                    icon: MaintenanceHubIcon.icon(for: bundle.primaryRoutine.resolvedServiceKey),
                    eyebrow: "Needs your decision",
                    title: bundle.title,
                    subtitle: subtitle,
                    ctaTitle: "Choose vendor",
                    destination: .pendingProgram(bundle)
                )
            )
        }

        for service in currentSeasonPlan.decisionServices.prefix(3) {
            items.append(
                MaintenanceActionItem(
                    id: "season-decision-\(service.id)",
                    accent: .coral,
                    icon: MaintenanceHubIcon.icon(for: service.serviceKey),
                    eyebrow: "Needs your decision",
                    title: service.title,
                    subtitle: "Due \(service.shortDueDate) · \(service.ownershipSummary)",
                    ctaTitle: service.ctaTitle,
                    destination: .seasonalService(service)
                )
            )
        }

        return Array(items.prefix(6))
    }

    private var proactiveRoutineActionItems: [MaintenanceActionItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let upcomingWindowDays = 120

        return activeRoutines.compactMap { routine in
            let existingVisits = scheduledVisits.filter { $0.routineId == routine.id }
            guard let preview = routine.upcomingVisitPreviews(existingVisits: existingVisits, limit: 6, from: today)
                .first(where: { preview in
                    guard preview.isProjected,
                          let visitTypeKey = preview.visitTypeKey,
                          routine.proactiveForecastVisitTypeKeys.contains(visitTypeKey),
                          let date = MaintenanceDateFormatting.date(from: preview.scheduledDate)
                    else {
                        return false
                    }

                    let daysUntil = Calendar.current.dateComponents(
                        [.day],
                        from: today,
                        to: Calendar.current.startOfDay(for: date)
                    ).day ?? 999

                    return daysUntil >= 0 && daysUntil <= upcomingWindowDays
                })
            else {
                return nil
            }

            let providerName: String? = {
                if let vendorId = routine.vendorId {
                    return vendorsById[vendorId]?.companyName
                }
                if let sourceUtilityAccountId = routine.sourceUtilityAccountId {
                    return utilityAccountsById[sourceUtilityAccountId]?.providerName
                }
                return nil
            }()

            let routineTitle = ServiceLibrary.homeownerTitle(for: routine)
            let subtitle: String
            if let providerName, !providerName.isEmpty {
                subtitle = "\(routineTitle) with \(providerName) is coming up around \(MaintenanceDateFormatting.shortDate(preview.scheduledDate))."
            } else {
                subtitle = "\(routineTitle) is coming up around \(MaintenanceDateFormatting.shortDate(preview.scheduledDate))."
            }

            return MaintenanceActionItem(
                id: "proactive-\(routine.id.uuidString)-\(preview.visitTypeKey ?? "visit")-\(preview.scheduledDate)",
                accent: .green,
                icon: MaintenanceHubIcon.icon(for: routine.resolvedServiceKey),
                eyebrow: "Coming up",
                title: preview.title,
                subtitle: subtitle,
                ctaTitle: "Open routine",
                    destination: .routine(routine)
            )
        }
        .sorted { lhs, rhs in
            let lhsDate = extractISODate(from: lhs.id)
            let rhsDate = extractISODate(from: rhs.id)
            if lhsDate != rhsDate {
                return lhsDate < rhsDate
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private func extractISODate(from actionId: String) -> String {
        actionId.split(separator: "-").suffix(3).joined(separator: "-")
    }

    func seasonPlan(for season: YearAtAGlanceCard.Season) -> MaintenanceSeasonPlan {
        let seasonalTasks = upcomingSeasonalTasks(withinDays: 365)
            .filter { inferSeason(for: $0) == season }
        let routines = allRoutinesById.values.filter { routine in
            !Set(routine.activeMonths).isDisjoint(with: season.months)
        }

        return MaintenanceSeasonPlan(
            season: season,
            pendingProgramBundles: pendingProgramBundles(
                from: routines.filter { $0.typedSetupState == .pendingVendor }
            ),
            activeRoutines: routines
                .filter { $0.typedSetupState == .active && $0.typedKind != .handymanRecurring }
                .sorted { $0.label < $1.label },
            services: seasonalServiceSummaries(from: seasonalTasks)
        )
    }

    /// Phase 67B: Resolve a task's category for routing-menu context.
    /// Walks template id → "Category:title" prefix, then falls back to
    /// the system's canonical category, then nil.
    func categoryForTask(_ task: MaintenanceTaskDBRow) -> String? {
        if let templateId = task.templateId,
           let prefix = templateId.split(separator: ":").first {
            return SystemCategoryRegistry.canonical(category: String(prefix))
                ?? String(prefix)
        }
        return nil
    }

    /// Phase 67B: Find an active vendor routine for a category — what
    /// the UnifiedRoutingMenu presents as "Assign to [Tyler]". Returns
    /// nil when the user has no vendor on file for this category.
    func vendorRoutineForCategory(_ category: String?) -> RoutineRow? {
        guard let category else { return nil }
        guard let canonical = SystemCategoryRegistry.canonical(category: category) else { return nil }
        guard let kind = RoutineGroupingEngine.routineKindFor(systemCategory: canonical) else { return nil }
        return allRoutinesById.values.first { routine in
            routine.typedKind == kind
                && routine.typedSetupState == .active
                && routine.vendorId != nil
        }
    }

    func vendorForCategory(_ category: String?) -> ContractorRow? {
        guard let routine = vendorRoutineForCategory(category),
              let vendorId = routine.vendorId
        else { return nil }
        return vendorsById[vendorId]
    }

    func pendingProgramBundle(containing routine: RoutineRow) -> PendingProgramBundleSummary? {
        pendingProgramBundles.first { bundle in
            bundle.routines.contains(where: { $0.id == routine.id })
        }
    }

    func assignVendor(
        _ contractor: ContractorRow,
        to bundle: PendingProgramBundleSummary,
        applyToRelatedPrograms: Bool
    ) async {
        await activatePendingPrograms(
            bundle,
            vendor: contractor,
            applyToRelatedPrograms: applyToRelatedPrograms
        )
    }

    func activatePendingPrograms(
        _ bundle: PendingProgramBundleSummary,
        vendor: ContractorRow?,
        applyToRelatedPrograms: Bool
    ) async {
        let targetRoutines = applyToRelatedPrograms ? bundle.routines : [bundle.primaryRoutine]

        for routine in targetRoutines {
            var routineUpdate = RoutineUpdate()
            routineUpdate.vendorId = vendor?.id
            routineUpdate.setupState = RoutineSetupState.active.rawValue
            if routine.shouldUseCanonicalServiceTitle {
                routineUpdate.label = routine.presentationLabel
            }
            _ = try? await db.updateRoutine(id: routine.id, routineUpdate)

            let childTasks = (try? await db.fetchTasksForRoutine(routineId: routine.id)) ?? []
            for task in childTasks where task.isArchived != true {
                if vendor == nil {
                    try? await db.clearMaintenanceTaskContractor(id: task.id)
                }

                var taskUpdate = MaintenanceTaskUpdate()
                taskUpdate.parentRoutineId = routine.id
                taskUpdate.needsVendor = false
                taskUpdate.assignedRoute = vendor == nil ? "diy" : "vendor"
                taskUpdate.assignmentType = vendor == nil ? "either" : "vendor"
                taskUpdate.assignedContractorId = vendor?.id
                _ = try? await db.updateMaintenanceTask(id: task.id, taskUpdate)
            }
        }

        NotificationCenter.default.post(name: .routineChanged, object: nil)
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        await load(filterPropertyId: resolvedPropertyId)
    }

    func askAlfredAboutPendingProgram(_ bundle: PendingProgramBundleSummary) {
        let included = bundle.includedProgramTitles.joined(separator: ", ")
        NotificationCenter.default.post(
            name: .switchToTab,
            object: nil,
            userInfo: ["tab": 3]
        )
        NotificationCenter.default.post(
            name: .openAlfredWithContext,
            object: nil,
            userInfo: [
                "message": "Help me decide who should handle these maintenance programs: \(included). If one vendor can usually cover multiple of them, recommend that."
            ]
        )
    }

    func askHavenToHandle(season: YearAtAGlanceCard.Season) {
        let plan = seasonPlan(for: season)
        let openTitles = Array(
            (
                plan.pendingProgramBundles.map(\.title) +
                plan.decisionServices.map(\.title) +
                plan.bundleServices.map(\.title)
            )
            .prefix(6)
        )

        let summary: String
        if openTitles.isEmpty {
            summary = "Review the \(season.displayLabel.lowercased()) maintenance plan and tell me if anything still needs my attention."
        } else {
            summary = "Please help me handle these \(season.displayLabel.lowercased()) home maintenance items: \(openTitles.joined(separator: ", ")). Tell me what Chez can coordinate and what decisions you still need from me."
        }

        NotificationCenter.default.post(
            name: .switchToTab,
            object: nil,
            userInfo: ["tab": 3]
        )
        NotificationCenter.default.post(
            name: .openAlfredWithContext,
            object: nil,
            userInfo: ["message": summary]
        )
    }

    private func inferSeason(for task: MaintenanceTaskDBRow) -> YearAtAGlanceCard.Season {
        if let timing = task.seasonalTiming?.lowercased() {
            if timing.contains("spring") { return .spring }
            if timing.contains("summer") { return .summer }
            if timing.contains("fall") { return .fall }
            if timing.contains("winter") { return .winter }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: task.nextDueDate) {
            let month = Calendar.current.component(.month, from: date)
            for season in YearAtAGlanceCard.Season.allCases where season.months.contains(month) {
                return season
            }
        }
        return .current
    }

    var hasNoContent: Bool {
        activeRoutines.isEmpty
            && pendingRoutines.isEmpty
            && smartSetupCards.isEmpty
            && handymanTasks.isEmpty
            && handymanPunchItems.isEmpty
            && vehicles.isEmpty
            && thisSeasonTaskPool.isEmpty
            && scheduledVisits.isEmpty
            && activeProjects.isEmpty
    }

    func load(filterPropertyId: UUID?) async {
        isLoading = true
        defer { isLoading = false }

        // Resolve household + property via the property list. Each
        // PropertyRow carries householdId; we assume all properties in
        // the list share a household (which is Haven's invariant).
        let fetchedProperties = (try? await db.fetchProperties()) ?? []
        properties = fetchedProperties
        guard let firstProperty = fetchedProperties.first else {
            // No properties yet — nothing to render. Reset state.
            resetToEmpty()
            return
        }
        let hhId = firstProperty.householdId
        householdId = hhId

        let propertyId: UUID? = filterPropertyId ?? firstProperty.id
        resolvedPropertyId = propertyId
        let currentProperty = fetchedProperties.first(where: { $0.id == propertyId }) ?? firstProperty

        // Fetch the household for the preferred handyman pointer.
        let household = try? await db.fetchHousehold(id: hhId)
        householdUsers = (try? await db.fetchHouseholdUsers()) ?? []
        let family = (try? await db.fetchFamilyMembers()) ?? []
        let staff = (try? await db.fetchHouseholdStaff()) ?? []
        householdFamilyMembers = family + staff
        systems = (try? await db.fetchHomeSystems()) ?? []

        // Load contractors once — used by all sections for vendor logos
        let contractors = (try? await db.fetchContractors()) ?? []
        vendorsById = Dictionary(uniqueKeysWithValues: contractors.map { ($0.id, $0) })
        if let propertyId {
            utilityAccounts = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
        } else {
            utilityAccounts = []
        }
        let documents = (try? await db.fetchDocuments()) ?? []
        let propertyTasks: [MaintenanceTaskDBRow]
        if let propertyId {
            propertyTasks = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
        } else {
            propertyTasks = []
        }

        // Preferred handyman from household
        if let handymanId = household?.preferredHandymanContractorId {
            preferredHandyman = vendorsById[handymanId]
        } else {
            preferredHandyman = nil
        }

        // Routines
        let routines = (try? await db.fetchRoutines(householdId: hhId)) ?? []
        allRoutinesById = Dictionary(uniqueKeysWithValues: routines.map { ($0.id, $0) })

        let propertyRoutines = filterPropertyScoped(routines: routines, propertyId: propertyId)
        activeRoutines = collapseRoutinePrograms(filterActive(routines: propertyRoutines))
        pendingRoutines = collapseRoutinePrograms(filterPending(routines: propertyRoutines))
        smartSetupCards = buildSmartSetupCards(
            contractors: contractors,
            utilityAccounts: utilityAccounts,
            existingRoutines: propertyRoutines,
            documents: documents,
            propertyId: propertyId
        )

        // Handyman routine — exists after Day1TaskCurator runs, OR
        // user taps "Add to handyman list" on a task. Don't lazy-create
        // on mere view-load.
        handymanRoutine = findHandymanRoutine(in: propertyRoutines)
        if let routine = handymanRoutine {
            let tasks = (try? await db.fetchTasksForRoutine(routineId: routine.id)) ?? []
            handymanTasks = tasks.filter { $0.isArchived != true }
        } else {
            handymanTasks = []
        }

        handymanPunchItems = HandymanPunchListViewModel.deduplicated(
            (try? await db.fetchPendingHandymanPunchItems(householdId: hhId)) ?? []
        )
        handymanSeasonalPlans = buildHandymanSeasonalPlans(
            property: currentProperty,
            tasks: propertyTasks
        )
        handymanRequests = (try? await db.fetchHandymanRequests(
            householdId: hhId,
            propertyId: propertyId,
            limit: 6
        )) ?? []
        if let visitTaskId = primaryHandymanVisitTask?.id {
            handymanPortalSession = try? await db.fetchHandymanPortalSession(visitTaskId: visitTaskId)
        } else {
            handymanPortalSession = nil
        }

        // Vehicle routines
        vehicles = (try? await db.fetchVehicles()) ?? []
        vehicleRoutinesByVehicle = buildVehicleRoutineMap(routines: routines)

        // Tasks per vehicle — sequential fetch (~5 vehicles max typical)
        var perVehicleTasks: [UUID: [MaintenanceTaskDBRow]] = [:]
        for vehicle in vehicles {
            let tasks = (try? await db.fetchMaintenanceTasks(vehicleId: vehicle.id)) ?? []
            perVehicleTasks[vehicle.id] = tasks.filter { $0.isArchived != true }
        }
        tasksByVehicle = perVehicleTasks

        // This Season: actionable grouped services plus recurring
        // programs that haven't been properly set up yet.
        thisSeasonTaskPool = seasonalTaskCandidates(from: propertyTasks, withinDays: 120)
        let queuedTaskIds = Set(handymanTasks.map(\.id))
        let punchSourceIds = Set(handymanPunchItems.compactMap(\.sourceTaskId))
        let queuedSuggestionKeys = Set(
            handymanTasks.map(handymanSuggestionKey(for:))
                + handymanPunchItems.map { normalizedSuggestionText($0.title) }
        )
        handymanSuggestedTasks = deduplicatedHandymanSuggestions(
            handymanSuggestionCandidates(from: propertyTasks, withinDays: 180)
        )
            .filter {
                !queuedTaskIds.contains($0.id)
                    && !punchSourceIds.contains($0.id)
                    && !queuedSuggestionKeys.contains(handymanSuggestionKey(for: $0))
            }

        // Phase 67C: Year at a Glance aggregation source — all property
        // tasks (parented + unparented) + tasks linked per routine.
        allTaskList = propertyTasks.filter { $0.isArchived != true }
        var perRoutineTasks: [UUID: [MaintenanceTaskDBRow]] = [:]
        for routine in allRoutinesById.values {
            let tasks = (try? await db.fetchTasksForRoutine(routineId: routine.id)) ?? []
            perRoutineTasks[routine.id] = tasks.filter { $0.isArchived != true }
        }
        tasksByRoutine = perRoutineTasks

        // Scheduled visits
        scheduledVisits = (try? await db.fetchScheduledVisitsForHousehold(householdId: hhId)) ?? []

        if let propertyId {
            let projects = (try? await db.fetchProjects(propertyId: propertyId)) ?? []
            activeProjects = projects.filter { $0.status == "planning" || $0.status == "in_progress" }
        } else {
            activeProjects = []
        }
    }

    private func resetToEmpty() {
        activeRoutines = []
        pendingRoutines = []
        handymanRoutine = nil
        handymanTasks = []
        handymanPunchItems = []
        handymanSuggestedTasks = []
        handymanSeasonalPlans = []
        handymanRequests = []
        handymanPortalSession = nil
        preferredHandyman = nil
        vehicles = []
        vehicleRoutinesByVehicle = [:]
        tasksByVehicle = [:]
        thisSeasonTaskPool = []
        scheduledVisits = []
        vendorsById = [:]
        allRoutinesById = [:]
        activeProjects = []
        utilityAccounts = []
        smartSetupCards = []
        householdId = nil
        resolvedPropertyId = nil
        properties = []
        systems = []
        householdUsers = []
        householdFamilyMembers = []
    }

    // MARK: - Small helpers (split to keep Swift type-checker happy)

    private func filterPropertyScoped(
        routines: [RoutineRow],
        propertyId: UUID?
    ) -> [RoutineRow] {
        routines.filter { routine in
            guard routine.typedScope == RoutineScope.property else { return false }
            guard routine.archivedAt == nil else { return false }
            // Allow routines attached to the current property OR
            // unattached (nil property_id — household-scoped).
            if let propertyId {
                return routine.propertyId == propertyId || routine.propertyId == nil
            }
            return true
        }
    }

    private func filterActive(routines: [RoutineRow]) -> [RoutineRow] {
        routines.filter { routine in
            guard routine.typedSetupState == RoutineSetupState.active else { return false }
            // Handyman routine has its own dedicated section — not
            // part of Your Services.
            return routine.typedKind != RoutineKind.handymanRecurring
        }
    }

    private func filterPending(routines: [RoutineRow]) -> [RoutineRow] {
        routines.filter { $0.typedSetupState == RoutineSetupState.pendingVendor }
    }

    private func collapseRoutinePrograms(_ routines: [RoutineRow]) -> [RoutineRow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let groups = Dictionary(grouping: routines) { routine in
            switch routine.resolvedServiceKey {
            case "custom_routine_program":
                return routine.id.uuidString
            default:
                return routine.resolvedServiceKey ?? routine.id.uuidString
            }
        }

        return groups.values.compactMap { group in
            group.sorted { lhs, rhs in
                let leftDate = formatter.date(from: lhs.nextExpectedDate) ?? .distantFuture
                let rightDate = formatter.date(from: rhs.nextExpectedDate) ?? .distantFuture
                if leftDate != rightDate { return leftDate < rightDate }
                return lhs.label < rhs.label
            }.first
        }
        .sorted { $0.label < $1.label }
    }

    private func pendingProgramGroupKey(for routine: RoutineRow) -> String {
        switch routine.resolvedServiceKey {
        case "pest_and_termite_program", "mosquito_and_tick_program":
            return "outdoor_pest_bundle"
        default:
            return routine.resolvedServiceKey ?? routine.id.uuidString
        }
    }

    private func pendingProgramTitle(for key: String, routines: [RoutineRow]) -> String {
        switch key {
        case "outdoor_pest_bundle":
            return "Pest, Termite & Mosquito Coverage"
        default:
            if let first = routines.first {
                return ServiceLibrary.homeownerTitle(for: first)
            }
            return "Maintenance program"
        }
    }

    private func pendingProgramSubtitle(for key: String, routines: [RoutineRow]) -> String {
        switch key {
        case "outdoor_pest_bundle":
            return "One pest vendor usually covers both your core pest service and mosquito season."
        default:
            if routines.count > 1 {
                return "We'll set these up together so one vendor can cover the full service bundle."
            }
            return "Choose someone you already use, add a new contact, or search local pros."
        }
    }

    private func pendingProgramSearchCategory(for key: String, routines: [RoutineRow]) -> String {
        switch key {
        case "outdoor_pest_bundle":
            return "Pest control"
        default:
            if let first = routines.first,
               let vendorCategory = ServiceLibrary.serviceDefinition(for: first)?.vendorCategory,
               !vendorCategory.isEmpty {
                return vendorCategory
            }
            return "Home service"
        }
    }

    private func buildSmartSetupCards(
        contractors: [ContractorRow],
        utilityAccounts: [UtilityAccountRow],
        existingRoutines: [RoutineRow],
        documents: [DocumentRow],
        propertyId: UUID?
    ) -> [SmartSetupCard] {
        let visibleRoutines = existingRoutines.filter { $0.archivedAt == nil }
        var cards: [SmartSetupCard] = []
        var coveredRoutineServices: Set<String> = []

        let utilityGroups = Dictionary(grouping: utilityAccounts) { account in
            smartSetupServiceKey(forProviderType: account.providerType) ?? "__none__"
        }

        let utilityServiceKeys = utilityGroups.keys
            .filter { $0 != "__none__" }
            .sorted { smartSetupServiceSort(lhs: $0, rhs: $1) }

        for serviceKey in utilityServiceKeys {
            guard let accounts = utilityGroups[serviceKey],
                  let card = smartRoutineSetupCard(
                    utilityAccounts: accounts,
                    contractors: contractors,
                    existingRoutines: visibleRoutines
                  ) else { continue }

            cards.append(card)
            coveredRoutineServices.insert(serviceKey)
        }

        let contractorGroups = Dictionary(
            grouping: contractors.compactMap { contractor -> (String, RoutineSeeder.SeedDefaults, ContractorRow)? in
                guard let category = contractor.category,
                      let defaults = RoutineSeeder.shared.defaults(for: category) else {
                    return nil
                }
                return (defaults.serviceKey, defaults, contractor)
            },
            by: { $0.0 }
        )

        for serviceKey in contractorGroups.keys.sorted(by: { smartSetupServiceSort(lhs: $0, rhs: $1) }) {
            guard !coveredRoutineServices.contains(serviceKey),
                  let group = contractorGroups[serviceKey],
                  let card = smartRoutineSetupCard(
                    contractorGroup: group,
                    existingRoutines: visibleRoutines
                  ) else { continue }

            cards.append(card)
            coveredRoutineServices.insert(serviceKey)
        }

        for account in utilityAccounts.sorted(by: { utilityAccountSort(lhs: $0, rhs: $1) }) {
            guard let card = smartDocumentSetupCard(
                for: account,
                contractors: contractors,
                documents: documents,
                propertyId: propertyId
            ) else { continue }
            cards.append(card)
        }

        return Array(cards.sorted(by: { smartSetupCardSort(lhs: $0, rhs: $1) }).prefix(5))
    }

    private func smartRoutineSetupCard(
        utilityAccounts: [UtilityAccountRow],
        contractors: [ContractorRow],
        existingRoutines: [RoutineRow]
    ) -> SmartSetupCard? {
        let sortedAccounts = utilityAccounts.sorted(by: { utilityAccountSort(lhs: $0, rhs: $1) })
        guard let primary = sortedAccounts.first,
              let defaults = RoutineSeeder.shared.defaults(forProviderType: primary.providerType) else {
            return nil
        }

        guard !hasConfiguredRoutine(
            kind: defaults.kind,
            serviceKey: defaults.serviceKey,
            existingRoutines: existingRoutines
        ) else {
            return nil
        }

        let matched = matchedContractors(for: sortedAccounts, contractors: contractors)
        let selectedVendor = matched.count == 1 ? matched.first : nil
        let cardId = "routine-utility-\(defaults.serviceKey)"
        let providerName = primary.providerName

        let routineTitle: String
        let routineSubtitle: String
        let promptTitle: String
        let promptBody: String
        let ctaTitle: String
        let showsWeekdayPicker: Bool
        let showsCadencePicker: Bool
        let showsActiveMonths: Bool
        let allowedCadenceTypes: [RoutineCadenceType]
        let weekdaySectionTitle: String
        let weekdayHelperText: String

        switch defaults.serviceKey {
        case "waste_program":
            routineTitle = "\(providerName) is already on file for trash & recycling"
            routineSubtitle = "Tell Chez which days pickup happens and we'll turn it into a year-round routine."
            promptTitle = "What days are pickup?"
            promptBody = "We'll use this to save a recurring waste routine linked to \(providerName) so Chez can remind you the evening before."
            ctaTitle = "Set pickup day"
            showsWeekdayPicker = true
            showsCadencePicker = false
            showsActiveMonths = false
            allowedCadenceTypes = [.weekly, .biweekly, .triweekly]
            weekdaySectionTitle = "PICKUP DAYS"
            weekdayHelperText = "Pick every day bins go out. Trash and recycling can live in one routine when the same hauler handles both."
        case "landscaping_program":
            routineTitle = "\(providerName) is already on file for landscaping"
            routineSubtitle = "Pick the active months once and Chez will keep the program running inside Your Services."
            promptTitle = "When does the landscaping season run?"
            promptBody = "We'll save a recurring landscaping routine linked to \(providerName) so seasonal visits don't live as loose tasks."
            ctaTitle = "Set season"
            showsWeekdayPicker = false
            showsCadencePicker = true
            showsActiveMonths = true
            allowedCadenceTypes = [.weekly, .biweekly, .triweekly, .monthly]
            weekdaySectionTitle = "SERVICE DAYS"
            weekdayHelperText = "Pick the day they usually come if the schedule is predictable."
        case "pool_program":
            routineTitle = "\(providerName) is already on file for pool service"
            routineSubtitle = "Set the active months and visit rhythm once so opening, weekly care, and closing stay organized."
            promptTitle = "How does this pool program run?"
            promptBody = "We'll track the seasonal pool rhythm with \(providerName) so the routine shows up clearly in Maintenance."
            ctaTitle = "Set pool routine"
            showsWeekdayPicker = false
            showsCadencePicker = true
            showsActiveMonths = true
            allowedCadenceTypes = [.weekly, .biweekly, .monthly]
            weekdaySectionTitle = "VISIT DAY"
            weekdayHelperText = "Pick the day they typically service the pool when that's consistent."
        case "irrigation_program":
            routineTitle = "\(providerName) is already on file for irrigation"
            routineSubtitle = "Set the active months once so startup and winterization live under one recurring program."
            promptTitle = "What months does irrigation run?"
            promptBody = "We'll save a recurring irrigation program linked to \(providerName) so Chez can track the season instead of separate loose tasks."
            ctaTitle = "Set irrigation season"
            showsWeekdayPicker = false
            showsCadencePicker = false
            showsActiveMonths = true
            allowedCadenceTypes = [.annual]
            weekdaySectionTitle = "SERVICE DAYS"
            weekdayHelperText = "Pick the regular day only if your vendor follows a weekly cadence."
        case "pest_and_termite_program", "mosquito_and_tick_program":
            routineTitle = "\(providerName) is already on file for pest coverage"
            routineSubtitle = "Set the cadence once and Chez will keep the whole pest program organized."
            promptTitle = "How often should Chez expect visits?"
            promptBody = "We'll use this cadence to save the recurring pest program linked to \(providerName)."
            ctaTitle = "Set cadence"
            showsWeekdayPicker = false
            showsCadencePicker = true
            showsActiveMonths = defaults.serviceKey == "mosquito_and_tick_program"
            allowedCadenceTypes = [.monthly, .biweekly, .triweekly, .quarterly, .customDays]
            weekdaySectionTitle = "VISIT DAY"
            weekdayHelperText = "Pick the day if their visits are usually on the same weekday."
        default:
            let homeownerTitle = ServiceLibrary.serviceDefinition(forKey: defaults.serviceKey)?.homeownerTitle
                ?? defaults.label.capitalized
            routineTitle = "\(providerName) is already on file for \(homeownerTitle.lowercased())"
            routineSubtitle = "Finish the missing setup details once and Chez will save it as a recurring routine."
            promptTitle = "Finish the routine setup"
            promptBody = "We'll link the recurring routine to \(providerName) so the provider you already entered becomes operational in Maintenance."
            ctaTitle = "Finish setup"
            showsWeekdayPicker = false
            showsCadencePicker = true
            showsActiveMonths = defaults.activeMonths != Array(1...12)
            allowedCadenceTypes = [.monthly, .quarterly, .semiannual, .annual, .customDays]
            weekdaySectionTitle = "SERVICE DAY"
            weekdayHelperText = "Pick the weekday if the vendor usually comes on a predictable cadence."
        }

        let context = SmartRoutineSetupContext(
            id: cardId,
            title: ServiceLibrary.serviceDefinition(forKey: defaults.serviceKey)?.homeownerTitle ?? defaults.label.capitalized,
            subtitle: providerName,
            serviceKey: defaults.serviceKey,
            draftPreset: draftPreset(
                title: ServiceLibrary.serviceDefinition(forKey: defaults.serviceKey)?.homeownerTitle ?? defaults.label.capitalized,
                defaults: defaults,
                selectedVendor: selectedVendor
            ),
            sourceUtilityAccount: primary,
            promptTitle: promptTitle,
            promptBody: promptBody,
            navigationTitle: "Finish setup",
            ctaTitle: "Save routine",
            icon: MaintenanceHubIcon.icon(for: defaults.serviceKey),
            showsWeekdayPicker: showsWeekdayPicker,
            showsCadencePicker: showsCadencePicker,
            showsActiveMonths: showsActiveMonths,
            defaultEveningBeforeReminder: defaults.eveningBeforeReminder,
            defaultMorningOfReminder: defaults.morningOfReminder,
            allowedCadenceTypes: allowedCadenceTypes,
            weekdaySectionTitle: weekdaySectionTitle,
            weekdayHelperText: weekdayHelperText
        )

        return SmartSetupCard(
            id: cardId,
            eyebrow: "Smart setup",
            title: routineTitle,
            subtitle: routineSubtitle,
            ctaTitle: ctaTitle,
            icon: MaintenanceHubIcon.icon(for: defaults.serviceKey),
            accent: defaults.serviceKey == "waste_program" ? .navy : .green,
            completion: .routine(context)
        )
    }

    private func smartRoutineSetupCard(
        contractorGroup: [(String, RoutineSeeder.SeedDefaults, ContractorRow)],
        existingRoutines: [RoutineRow]
    ) -> SmartSetupCard? {
        guard let first = contractorGroup.first else { return nil }
        let serviceKey = first.0
        let defaults = first.1
        let vendors = contractorGroup
            .map(\.2)
            .sorted { $0.companyName.localizedCaseInsensitiveCompare($1.companyName) == .orderedAscending }

        guard !hasConfiguredRoutine(
            kind: defaults.kind,
            serviceKey: serviceKey,
            existingRoutines: existingRoutines
        ) else {
            return nil
        }

        let primaryVendor = vendors.first
        let title = ServiceLibrary.serviceDefinition(forKey: serviceKey)?.homeownerTitle ?? defaults.label.capitalized
        let providerLine = primaryVendor?.companyName ?? "your vendor"

        let context = SmartRoutineSetupContext(
            id: "routine-contractor-\(serviceKey)",
            title: title,
            subtitle: providerLine,
            serviceKey: serviceKey,
            draftPreset: draftPreset(
                title: title,
                defaults: defaults,
                selectedVendor: vendors.count == 1 ? primaryVendor : nil
            ),
            sourceUtilityAccount: nil,
            promptTitle: "Finish the missing routine details",
            promptBody: "We already have \(providerLine) on file. Set the rhythm once and Chez will turn this into a recurring routine.",
            navigationTitle: "Finish setup",
            ctaTitle: "Save routine",
            icon: MaintenanceHubIcon.icon(for: serviceKey),
            showsWeekdayPicker: false,
            showsCadencePicker: true,
            showsActiveMonths: defaults.activeMonths != Array(1...12),
            defaultEveningBeforeReminder: defaults.eveningBeforeReminder,
            defaultMorningOfReminder: defaults.morningOfReminder,
            allowedCadenceTypes: [.weekly, .biweekly, .monthly, .quarterly, .semiannual, .annual, .customDays],
            weekdaySectionTitle: "SERVICE DAY",
            weekdayHelperText: "Pick the weekday if visits usually happen on the same day."
        )

        return SmartSetupCard(
            id: "routine-contractor-\(serviceKey)",
            eyebrow: "Smart setup",
            title: "Turn \(providerLine) into your \(title)",
            subtitle: "We already know the provider. Finish the cadence details once so the routine lives in Your Services.",
            ctaTitle: "Finish setup",
            icon: MaintenanceHubIcon.icon(for: serviceKey),
            accent: .green,
            completion: .routine(context)
        )
    }

    private func smartDocumentSetupCard(
        for account: UtilityAccountRow,
        contractors: [ContractorRow],
        documents: [DocumentRow],
        propertyId: UUID?
    ) -> SmartSetupCard? {
        let normalizedType = account.providerType.lowercased()
        guard ["oil", "propane"].contains(normalizedType) else { return nil }

        let contractor = matchedContractor(for: account, contractors: contractors)
        guard !hasRelatedSupportingDocument(
            for: account,
            contractor: contractor,
            documents: documents,
            propertyId: propertyId
        ) else {
            return nil
        }

        let context = SmartDocumentSetupContext(
            id: "document-\(account.id.uuidString)",
            title: "Upload your \(account.providerName) service contract",
            subtitle: "We already know the provider. Add the paperwork once so Chez can reference pricing, terms, and emergency contacts.",
            providerName: account.providerName,
            contractorId: contractor?.id,
            propertyId: propertyId,
            preselectedCategory: .vendorContract
        )

        return SmartSetupCard(
            id: context.id,
            eyebrow: "Missing document",
            title: "\(account.providerName) is on file for \(normalizedType == "oil" ? "heating oil" : "propane")",
            subtitle: "Upload the current service agreement or delivery paperwork so Chez can keep the provider context complete.",
            ctaTitle: "Upload contract",
            icon: normalizedType == "oil" ? "fuelpump.fill" : "doc.text.fill",
            accent: .gold,
            completion: .document(context)
        )
    }

    private func smartSetupServiceKey(forProviderType providerType: String) -> String? {
        RoutineSeeder.shared.defaults(forProviderType: providerType)?.serviceKey
    }

    private func matchedContractors(
        for accounts: [UtilityAccountRow],
        contractors: [ContractorRow]
    ) -> [ContractorRow] {
        let providerIds = Set(accounts.compactMap(\.providerId))
        let names = Set(accounts.map { $0.providerName.lowercased() })

        return contractors.filter { contractor in
            if let utilityProviderId = contractor.utilityProviderId,
               providerIds.contains(utilityProviderId) {
                return true
            }
            return names.contains(contractor.companyName.lowercased())
        }
        .sorted { $0.companyName.localizedCaseInsensitiveCompare($1.companyName) == .orderedAscending }
    }

    private func matchedContractor(
        for account: UtilityAccountRow,
        contractors: [ContractorRow]
    ) -> ContractorRow? {
        matchedContractors(for: [account], contractors: contractors).first
    }

    private func hasRelatedSupportingDocument(
        for account: UtilityAccountRow,
        contractor: ContractorRow?,
        documents: [DocumentRow],
        propertyId: UUID?
    ) -> Bool {
        let providerName = account.providerName.lowercased()
        return documents.contains { document in
            if document.deletedAt != nil { return false }
            if let propertyId, let docPropertyId = document.propertyId, docPropertyId != propertyId {
                return false
            }

            let category = document.category.lowercased()
            let relevantCategory = category == DocumentCategory.vendorContract.rawValue.lowercased()
                || category == DocumentCategory.utilityBill.rawValue.lowercased()
                || category == DocumentCategory.homeBillInvoice.rawValue.lowercased()
            guard relevantCategory else { return false }

            if let contractor, document.contractorId == contractor.id {
                return true
            }

            let haystack = [
                document.title,
                document.issuingInstitution,
                document.notes,
                document.aiSummary
            ]
                .compactMap { $0?.lowercased() }
                .joined(separator: " ")
            return haystack.contains(providerName)
        }
    }

    private func hasConfiguredRoutine(
        kind: RoutineKind,
        serviceKey: String,
        existingRoutines: [RoutineRow]
    ) -> Bool {
        existingRoutines.contains { routine in
            guard routine.archivedAt == nil else { return false }
            if serviceKey == "waste_program" {
                return routine.resolvedServiceKey == "waste_program"
            }
            return routine.typedKind == kind || routine.resolvedServiceKey == serviceKey
        }
    }

    private func isWasteUtilityAccount(_ account: UtilityAccountRow) -> Bool {
        let normalized = account.providerType.lowercased()
        return ["trash", "recycling", "compost", "yard_waste", "yardwaste"].contains(normalized)
    }

    private func utilityAccountSort(lhs: UtilityAccountRow, rhs: UtilityAccountRow) -> Bool {
        lhs.providerName.localizedCaseInsensitiveCompare(rhs.providerName) == .orderedAscending
    }

    private func smartSetupServiceSort(lhs: String, rhs: String) -> Bool {
        let priority: [String: Int] = [
            "waste_program": 0,
            "landscaping_program": 1,
            "pool_program": 2,
            "pest_and_termite_program": 3,
            "mosquito_and_tick_program": 4,
            "irrigation_program": 5,
            "hvac_program": 6,
            "generator_program": 7,
            "security_and_smart_home_program": 8
        ]
        let leftRank = priority[lhs] ?? 100
        let rightRank = priority[rhs] ?? 100
        if leftRank != rightRank { return leftRank < rightRank }
        return lhs < rhs
    }

    private func smartSetupCardSort(lhs: SmartSetupCard, rhs: SmartSetupCard) -> Bool {
        let leftKindRank = smartSetupCardRank(lhs)
        let rightKindRank = smartSetupCardRank(rhs)
        if leftKindRank != rightKindRank { return leftKindRank < rightKindRank }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }

    private func smartSetupCardRank(_ card: SmartSetupCard) -> Int {
        switch card.completion {
        case .routine(let context):
            switch context.serviceKey {
            case "waste_program": return 0
            case "landscaping_program": return 1
            case "pool_program": return 2
            case "pest_and_termite_program": return 3
            case "mosquito_and_tick_program": return 4
            case "irrigation_program": return 5
            case "hvac_program": return 6
            case "generator_program": return 7
            case "security_and_smart_home_program": return 8
            default: return 20
            }
        case .document:
            return 40
        }
    }

    private func draftPreset(
        title: String,
        defaults: RoutineSeeder.SeedDefaults,
        selectedVendor: ContractorRow?
    ) -> RoutineDraftPreset {
        RoutineDraftPreset(
            routineKind: defaults.kind,
            label: title,
            cadenceType: defaults.cadenceType,
            customIntervalDays: defaults.cadenceIntervalDays,
            selectedWeekdays: Set(defaults.daysOfWeek ?? []),
            hasTimeOfDay: defaults.timeOfDay != nil,
            timeOfDay: timeOfDay(from: defaults.timeOfDay),
            activeMonths: Set(defaults.activeMonths),
            startDate: Calendar.current.startOfDay(for: Date()),
            selectedVendor: selectedVendor,
            notes: ""
        )
    }

    private func timeOfDay(from value: String?) -> Date {
        guard let value, !value.isEmpty else {
            return Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let parsed = formatter.date(from: value) {
            return parsed
        }
        formatter.dateFormat = "HH:mm:ss"
        return formatter.date(from: value)
            ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 0))
            ?? Date()
    }

    private func deduplicatedHandymanSuggestions(
        _ tasks: [MaintenanceTaskDBRow]
    ) -> [MaintenanceTaskDBRow] {
        var seen: Set<String> = []
        return tasks.filter { task in
            let key = handymanSuggestionKey(for: task)
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
        .sorted { lhs, rhs in
            if lhs.nextDueDate != rhs.nextDueDate { return lhs.nextDueDate < rhs.nextDueDate }
            return lhs.title < rhs.title
        }
    }

    private func seasonalServiceSummaries(from tasks: [MaintenanceTaskDBRow]) -> [SeasonalServiceSummary] {
        let groups = Dictionary(grouping: tasks, by: serviceGroupKey(for:))

        return groups.compactMap { key, group in
            guard let representative = representativeTask(in: group) else { return nil }
            let serviceKey = representative.resolvedServiceKey ?? "custom_seasonal_service"
            let definition = ServiceLibrary.serviceDefinition(for: representative)
            let status: SeasonalServiceSummary.Status

            if let vendorId = representative.assignedContractorId {
                let vendorName = vendorsById[vendorId]?.companyName
                    ?? vendorsById[vendorId]?.contactName
                    ?? "Vendor assigned"
                status = .vendorAssigned(vendorName)
            } else if representative.assignedRoute == "diy" {
                status = .diy
            } else if isHandymanFriendly(representative) {
                status = .handymanRecommended
            } else {
                status = .needsRouting
            }

            return SeasonalServiceSummary(
                groupKey: key,
                serviceKey: serviceKey,
                title: displayTitle(for: group, representative: representative),
                dueDate: representative.nextDueDate,
                representativeTask: representative,
                tasks: group.sorted { $0.nextDueDate < $1.nextDueDate },
                definition: definition,
                status: status
            )
        }
        .sorted { lhs, rhs in
            if lhs.needsAttention != rhs.needsAttention {
                return lhs.needsAttention && !rhs.needsAttention
            }
            let lhsRank = sortRank(for: lhs)
            let rhsRank = sortRank(for: rhs)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            if lhs.dueDate != rhs.dueDate { return lhs.dueDate < rhs.dueDate }
            return lhs.title < rhs.title
        }
    }

    private func representativeTask(in group: [MaintenanceTaskDBRow]) -> MaintenanceTaskDBRow? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return group.sorted { lhs, rhs in
            if lhs.bundleParentTaskId == nil && rhs.bundleParentTaskId != nil { return true }
            if lhs.bundleParentTaskId != nil && rhs.bundleParentTaskId == nil { return false }
            let leftDate = formatter.date(from: lhs.nextDueDate) ?? .distantFuture
            let rightDate = formatter.date(from: rhs.nextDueDate) ?? .distantFuture
            if leftDate != rightDate { return leftDate < rightDate }
            return lhs.title < rhs.title
        }.first
    }

    private func serviceGroupKey(for task: MaintenanceTaskDBRow) -> String {
        switch task.resolvedServiceKey {
        case "custom_seasonal_service":
            return task.id.uuidString
        default:
            return task.resolvedServiceKey ?? task.id.uuidString
        }
    }

    private func findHandymanRoutine(in routines: [RoutineRow]) -> RoutineRow? {
        routines.first { routine in
            routine.typedKind == RoutineKind.handymanRecurring && routine.archivedAt == nil
        }
    }

    private func buildVehicleRoutineMap(routines: [RoutineRow]) -> [UUID: RoutineRow] {
        var result: [UUID: RoutineRow] = [:]
        for routine in routines {
            guard routine.typedScope == RoutineScope.vehicle else { continue }
            guard routine.archivedAt == nil else { continue }
            guard let vehicleId = routine.vehicleId else { continue }
            result[vehicleId] = routine
        }
        return result
    }

    private func upcomingSeasonalTasks(withinDays days: Int) -> [MaintenanceTaskDBRow] {
        seasonalTaskCandidates(from: allTaskList, withinDays: days)
    }

    private func seasonalTaskCandidates(
        from tasks: [MaintenanceTaskDBRow],
        withinDays days: Int
    ) -> [MaintenanceTaskDBRow] {
        let today = Date()
        let window = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        return tasks
            .filter { task in
                guard task.isArchived != true else { return false }
                guard task.parentRoutineId == nil else { return false }
                guard task.vehicleId == nil else { return false }
                guard task.bundleParentTaskId == nil else { return false }
                guard task.assignedRoute != "handyman" else { return false }
                guard shouldSurfaceInThisSeason(task) else { return false }
                guard let due = MaintenanceDateFormatting.date(from: task.nextDueDate) else { return false }
                return due <= window
            }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }

    private func handymanSuggestionCandidates(
        from tasks: [MaintenanceTaskDBRow],
        withinDays days: Int
    ) -> [MaintenanceTaskDBRow] {
        let today = Date()
        let window = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        return tasks
            .filter { task in
                guard task.isArchived != true else { return false }
                guard task.parentRoutineId == nil else { return false }
                guard task.vehicleId == nil else { return false }
                guard task.bundleParentTaskId == nil else { return false }
                guard task.assignedRoute != "handyman" else { return false }
                guard task.assignedContractorId == nil else { return false }
                guard !isBuiltInHandymanProgramTask(task) else { return false }
                guard let due = MaintenanceDateFormatting.date(from: task.nextDueDate) else { return false }
                guard due <= window else { return false }
                return isHandymanFriendly(task)
            }
            .sorted { lhs, rhs in
                if lhs.nextDueDate != rhs.nextDueDate { return lhs.nextDueDate < rhs.nextDueDate }
                return lhs.title < rhs.title
            }
    }

    private func shouldSurfaceInThisSeason(_ task: MaintenanceTaskDBRow) -> Bool {
        switch ServiceLibrary.serviceKind(for: task) {
        case .some(.seasonalService):
            return true
        case .some(.routineProgram):
            guard let serviceKey = task.resolvedServiceKey else { return false }
            return !hasConfiguredRoutine(for: serviceKey)
        default:
            return false
        }
    }

    private func hasConfiguredRoutine(for serviceKey: String) -> Bool {
        allRoutinesById.values.contains { routine in
            routine.archivedAt == nil
                && routine.typedKind != .handymanRecurring
                && routine.resolvedServiceKey == serviceKey
        }
    }

    private func sortRank(for summary: SeasonalServiceSummary) -> Int {
        switch summary.definition?.serviceKind {
        case .some(.routineProgram):
            return 0
        case .some(.seasonalService):
            return 1
        default:
            return 2
        }
    }

    private func displayTitle(
        for group: [MaintenanceTaskDBRow],
        representative: MaintenanceTaskDBRow
    ) -> String {
        let normalizedTitles = group
            .map(\.title)
            .joined(separator: " ")
            .lowercased()

        switch representative.resolvedServiceKey {
        case "deck_fence_and_hardscape_preservation":
            let mentionsDeckOrFence = normalizedTitles.contains("deck") || normalizedTitles.contains("fence")
            if !mentionsDeckOrFence {
                if normalizedTitles.contains("paver")
                    || normalizedTitles.contains("patio")
                    || normalizedTitles.contains("walkway") {
                    return "Patio & Hardscape Care"
                }
                return "Outdoor Hardscape Care"
            }
        case "hvac_program":
            if normalizedTitles.contains("cool")
                || normalizedTitles.contains("ac")
                || normalizedTitles.contains("condensate") {
                return "Spring HVAC Check"
            }
            if normalizedTitles.contains("heat")
                || normalizedTitles.contains("boiler")
                || normalizedTitles.contains("furnace") {
                return "Heating Service"
            }
        case "landscaping_program":
            if normalizedTitles.contains("spring")
                || normalizedTitles.contains("cleanup")
                || normalizedTitles.contains("mulch") {
                return "Spring Landscaping Cleanup"
            }
            if normalizedTitles.contains("fall")
                || normalizedTitles.contains("leaf") {
                return "Fall Landscaping Cleanup"
            }
        default:
            break
        }

        return ServiceLibrary.homeownerTitle(for: representative)
    }

    private func handymanSuggestionKey(for task: MaintenanceTaskDBRow) -> String {
        normalizedSuggestionText(task.title)
    }

    private func normalizedSuggestionText(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "annual ", with: "")
            .replacingOccurrences(of: "routine ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isBuiltInHandymanProgramTask(_ task: MaintenanceTaskDBRow) -> Bool {
        if let templateId = task.templateId,
           templateId.hasPrefix("Handyman:") {
            return true
        }
        return task.resolvedServiceKey == "handyman_program"
    }

    private func buildHandymanSeasonalPlans(
        property: PropertyRow,
        tasks: [MaintenanceTaskDBRow]
    ) -> [HandymanSeasonalPlan] {
        let activeSubtypes = MaintenanceTemplates.activeSubtypes(
            category: "Handyman",
            subtype: nil,
            flags: handymanPropertyFlags(for: property)
        )
        let templates = MaintenanceTemplates.templates(
            for: "Handyman",
            activeSubtypes: activeSubtypes,
            regionalPack: handymanRegionalPack(for: property)
        )

        let bundleOrder = prioritizedHandymanBundles()
        let bundledTemplates = Dictionary(grouping: templates.compactMap { template -> (String, MaintenanceTemplate)? in
            guard let bundleId = template.bundleId,
                  bundleId == "Handyman:spring" || bundleId == "Handyman:fall" else {
                return nil
            }
            return (bundleId, template)
        }, by: \.0)

        return bundleOrder.compactMap { bundleId in
            guard let matches = bundledTemplates[bundleId]?.map(\.1),
                  let parentTemplate = matches.first(where: { $0.bundleTitle != nil }) else {
                return nil
            }

            let childItems = matches
                .filter { $0.bundleTitle == nil }
                .map(\.title)
            let checklistItems = parsedHandymanChecklistItems(from: parentTemplate.notes)
            let mergedItems = mergedHandymanPlanItems(
                primary: childItems,
                secondary: checklistItems
            )
            let visitTask = tasks
                .filter { $0.isArchived != true && $0.templateId == bundleId }
                .sorted { $0.nextDueDate < $1.nextDueDate }
                .first

            return HandymanSeasonalPlan(
                id: bundleId,
                title: parentTemplate.bundleTitle ?? parentTemplate.title,
                subtitle: parentTemplate.description,
                reviewLabel: bundleId.hasSuffix(":spring") ? "SPRING DEFAULTS" : "FALL DEFAULTS",
                defaultItems: Array(mergedItems.prefix(5)),
                overflowCount: max(0, mergedItems.count - 5),
                visitTask: visitTask
            )
        }
    }

    private func prioritizedHandymanBundles() -> [String] {
        let month = Calendar.current.component(.month, from: Date())
        if (3...8).contains(month) {
            return ["Handyman:spring", "Handyman:fall"]
        }
        return ["Handyman:fall", "Handyman:spring"]
    }

    private func handymanRegionalPack(for property: PropertyRow) -> RegionalPack? {
        if let stored = property.regionalPack,
           let parsed = RegionalPack(rawValue: stored) {
            return parsed
        }
        return RegionalPack(state: property.state)
    }

    private func handymanPropertyFlags(for property: PropertyRow) -> [String: Bool] {
        let propertyFlagKeys = [
            "has_humidifier",
            "has_ev_charger",
            "has_radon_mitigation",
            "has_central_vacuum",
            "has_leak_detector",
            "has_whole_house_filter",
            "has_built_in_grill",
            "has_outdoor_lighting",
            "has_pool_safety_fence",
            "has_pets",
            "has_mature_trees",
            "has_fridge_water_dispenser",
            "has_sump_battery_backup",
            "has_dehumidifier"
        ]

        var flags: [String: Bool] = [:]
        for key in propertyFlagKeys where property.attributes?[key]?.stringValue == "true" {
            flags[key] = true
        }
        if property.attributes?["driveway_material"]?.stringValue == "asphalt" {
            flags["driveway_asphalt"] = true
        }
        return flags
    }

    private func parsedHandymanChecklistItems(from notes: String?) -> [String] {
        guard let notes, !notes.isEmpty else { return [] }
        return notes
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("•") || $0.hasPrefix("- ") }
            .map {
                $0
                    .replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "- ", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }

    private func mergedHandymanPlanItems(
        primary: [String],
        secondary: [String]
    ) -> [String] {
        var results: [String] = []

        func appendUnique(_ item: String) {
            let normalized = normalizedHandymanPlanItem(item)
            guard !results.contains(where: {
                let existing = normalizedHandymanPlanItem($0)
                return existing == normalized
                    || existing.contains(normalized)
                    || normalized.contains(existing)
            }) else { return }
            results.append(item)
        }

        primary.forEach(appendUnique)
        secondary.forEach(appendUnique)
        return results
    }

    private func normalizedHandymanPlanItem(_ item: String) -> String {
        item
            .lowercased()
            .replacingOccurrences(of: "throughout house", with: "")
            .replacingOccurrences(of: "pre-heating season", with: "")
            .replacingOccurrences(of: "post-winter", with: "")
            .replacingOccurrences(of: " (if applicable)", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isHandymanFriendly(_ task: MaintenanceTaskDBRow) -> Bool {
        guard task.vehicleId == nil else { return false }

        if ServiceLibrary.serviceDefinition(for: task)?.defaultRoutingStrategy == .handymanDefault {
            return true
        }

        if let serviceKey = task.resolvedServiceKey,
           ["garage_door_tune_up"].contains(serviceKey) {
            return true
        }

        let normalized = [task.title, task.notes, task.description]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        let keywordMatches = [
            "garage door",
            "sensor batter",
            "smoke and co",
            "smoke & co",
            "gfci",
            "weatherstrip",
            "weather stripping",
            "caulk",
            "recaulk",
            "re-caulk",
            "touch-up",
            "touch up",
            "touch up paint",
            "dryer vent",
            "hose bib",
            "door hardware",
            "door sweep",
            "lubricate",
            "window screen",
            "screen repair",
            "filter replacement",
            "replace filter",
            "light bulb",
            "outlet cover",
            "paver",
            "patio",
            "walkway"
        ]
        if keywordMatches.contains(where: normalized.contains) {
            return true
        }

        if let templateKey = task.templateId,
           let template = MaintenanceTemplates.template(forKey: templateKey),
           let minutes = template.diyEffortMinutes {
            return minutes <= 90
        }

        return false
    }

    // MARK: - Actions

    func scheduleHandymanVisit() {
        // Phase 66 scope: deferred — surfaces the existing HandymanVisitDetailView
        // (or a new scheduling flow). For now post a notification and let the
        // parent handle routing.
        NotificationCenter.default.post(
            name: Notification.Name("requestHandymanScheduleVisit"),
            object: nil
        )
    }

    func openFindHandyman() {
        // BUG-017 fix: Switch to Alfred tab first so the context message
        // actually lands in a visible chat composer (not a background tab).
        NotificationCenter.default.post(
            name: .switchToTab,
            object: nil,
            userInfo: ["tab": 3]
        )
        NotificationCenter.default.post(
            name: .openAlfredWithContext,
            object: nil,
            userInfo: [
                "message": "I need a contractor for routine home maintenance. Can you help me find a vetted local pro?"
            ]
        )
    }

    /// Deprecated: the vehicle card in MaintenanceHubView now drives the
    /// sheet directly via @State. Kept as a no-op for any stragglers that
    /// still post the dead notification.
    func openVehicleSetup(vehicle: VehicleRow) {
        // No-op. The caller should set `setupVehicle` on the view instead.
    }

}

struct HandymanSeasonalPlan: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let reviewLabel: String
    let defaultItems: [String]
    let overflowCount: Int
    let visitTask: MaintenanceTaskDBRow?
}

struct HandymanQueueView: View {
    let householdId: UUID
    let propertyId: UUID?
    let routine: RoutineRow?
    let queuedTasks: [MaintenanceTaskDBRow]
    let seasonalVisitPlans: [HandymanSeasonalPlan]
    let suggestedTasks: [MaintenanceTaskDBRow]
    let preferredHandyman: ContractorRow?
    let nextVisit: RoutineVisitRow?
    let onFindHandyman: () -> Void
    let onChanged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var punchItems: [HandymanPunchItemRow] = []
    @State private var isLoading = true
    @State private var showScheduleSheet = false
    @State private var showPunchList = false
    @State private var showAddHandymanItem = false
    @State private var hiddenSuggestedTaskIds: Set<UUID> = []
    @State private var statusToast: String?
    @State private var selectedQueuedTask: MaintenanceTaskDBRow?
    @State private var requests: [HandymanRequestRow] = []
    @State private var property: PropertyRow?
    @State private var systems: [HomeSystemRow] = []
    @State private var allTasksForProperty: [MaintenanceTaskDBRow] = []
    @State private var portalSession: HandymanPortalSessionRow?
    @State private var showRequestComposer = false
    @State private var selectedRequestKind: HandymanRequestKind = .standardVisit
    @State private var isPreparingMicrosite = false
    @State private var showProviderPicker = false
    @State private var localPreferredHandyman: ContractorRow?

    private let db = DatabaseService.shared

    private var activePreferredHandyman: ContractorRow? {
        localPreferredHandyman ?? preferredHandyman
    }

    private var visibleSuggestedTasks: [MaintenanceTaskDBRow] {
        suggestedTasks.filter { !hiddenSuggestedTaskIds.contains($0.id) }
    }

    private var visibleManualPunchItems: [HandymanPunchItemRow] {
        let queuedTitles = Set(queuedTasks.map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        return punchItems.filter { item in
            let normalized = item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !queuedTitles.contains(normalized)
        }
    }

    private var primaryVisitTask: MaintenanceTaskDBRow? {
        seasonalVisitPlans
            .compactMap(\.visitTask)
            .sorted { $0.nextDueDate < $1.nextDueDate }
            .first
    }

    private var shouldPromptFirstVisitSetup: Bool {
        HandymanVisitService.isFirstVisitSetupRecommended(
            systems: systems,
            property: property
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                headerCard
                programActionsSection

                if shouldPromptFirstVisitSetup {
                    firstVisitSetupCard
                }

                if !requests.isEmpty {
                    recentRequestsSection
                }

                if !seasonalVisitPlans.isEmpty {
                    seasonalPlanSection
                }

                if !queuedTasks.isEmpty || !visibleManualPunchItems.isEmpty {
                    jobsForNextVisitSection
                }

                if !visibleSuggestedTasks.isEmpty {
                    suggestedSection
                }

                if queuedTasks.isEmpty
                    && visibleManualPunchItems.isEmpty
                    && visibleSuggestedTasks.isEmpty
                    && seasonalVisitPlans.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing in the contractor bundle", systemImage: "hammer.fill")
                    } description: {
                        Text("Chez will keep your spring and fall contractor walkthroughs here, along with any odd jobs that are worth batching into those visits.")
                    }
                }
            }
            .padding(HavenTheme.spacing20)
        }
        .background(HavenColors.background)
        .navigationTitle("Contractor Bundle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddHandymanItem = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if activePreferredHandyman == nil && !seasonalVisitPlans.isEmpty {
                footerButton(title: "Choose contractor", action: { showProviderPicker = true })
            } else if !seasonalVisitPlans.isEmpty || !queuedTasks.isEmpty {
                footerButton(title: nextVisit == nil ? "Schedule next visit" : "Visit scheduled", action: {
                    guard nextVisit == nil else { return }
                    showScheduleSheet = true
                }, disabled: nextVisit != nil)
            } else if !punchItems.isEmpty {
                footerButton(title: "Open punch list", action: { showPunchList = true })
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleHandymanVisitSheet(
                itemCount: queuedTasks.count,
                householdId: householdId,
                propertyId: propertyId,
                onSchedule: { date, contractor in
                    Task { await scheduleVisit(on: date, contractor: contractor) }
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showProviderPicker) {
            NavigationStack {
                HandymanProviderPickerSheet(
                    onFallback: {
                        showProviderPicker = false
                        onFindHandyman()
                    },
                    onSelected: { contractor in
                        localPreferredHandyman = contractor
                        selectedRequestKind = .standardVisit
                        showProviderPicker = false
                        showRequestComposer = true
                        showToast("Contractor connected to this home")
                        Task { await loadProgramContext() }
                        onChanged()
                    }
                )
            }
        }
        .sheet(isPresented: $showPunchList, onDismiss: {
            Task { await loadProgramContext() }
            onChanged()
        }) {
            NavigationStack {
                HandymanPunchListView(
                    householdId: householdId,
                    propertyId: propertyId
                )
            }
        }
        .sheet(isPresented: $showAddHandymanItem, onDismiss: {
            Task { await loadProgramContext() }
            onChanged()
        }) {
            NavigationStack {
                QuickAddHandymanItemSheet(
                    householdId: householdId,
                    propertyId: propertyId,
                    onAdded: {
                        Task { await loadProgramContext() }
                        onChanged()
                    }
                )
            }
        }
        .sheet(item: $selectedQueuedTask) { task in
            Group {
                if let templateId = task.templateId,
                   templateId.hasPrefix("Handyman:") {
                    NavigationStack {
                        HandymanVisitDetailView(
                            parentTask: task,
                            onDismiss: {
                                Task { await loadProgramContext() }
                                onChanged()
                            }
                        )
                    }
                } else {
                    NavigationStack {
                        MaintenanceTaskDetailSheet(
                            task: task,
                            onDeleteTask: {
                                let taskId = task.id
                                Task {
                                    try? await DatabaseService.shared.deleteMaintenanceTask(id: taskId)
                                    NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                                }
                            }
                        )
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
        .sheet(isPresented: $showRequestComposer, onDismiss: {
            Task { await loadProgramContext() }
        }) {
            NavigationStack {
                HandymanRequestComposerSheet(
                    householdId: householdId,
                    propertyId: propertyId,
                    contractor: activePreferredHandyman,
                    visitTaskId: primaryVisitTask?.id,
                    initialKind: selectedRequestKind,
                    defaultFirstVisitSetup: shouldPromptFirstVisitSetup,
                    quickUpsellTitles: Array(visibleSuggestedTasks.prefix(3)).map(\.title),
                    onSaved: {
                        Task { await loadProgramContext() }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            await loadProgramContext()
        }
        .overlay(alignment: .bottom) {
            if let statusToast {
                Text(statusToast)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .havenShadow()
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: statusToast != nil)
    }

    private var headerCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing12) {
                    if let activePreferredHandyman {
                        VendorLogoView(contractor: activePreferredHandyman, size: 42)
                    } else {
                        Image(systemName: "wrench.adjustable.fill")
                            .font(.title2)
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 42, height: 42)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activePreferredHandyman?.companyName.isEmpty == false ? activePreferredHandyman?.companyName ?? "Contractor bundle" : "Contractor bundle")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(headerSubtitle)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                if let nextVisit {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                        Text("Visit scheduled for \(MaintenanceDateFormatting.shortDate(nextVisit.scheduledDate))")
                    }
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.success)
                }

                HStack {
                    Button {
                        showAddHandymanItem = true
                    } label: {
                        Label("Add custom item", systemImage: "plus.circle.fill")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(HavenColors.action)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if !punchItems.isEmpty {
                        Button("Manage punch list") {
                            showPunchList = true
                        }
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                    } else if activePreferredHandyman == nil {
                        Button("Choose contractor") {
                            showProviderPicker = true
                        }
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.action)
                    }
                }
            }
        }
    }

    private var headerSubtitle: String {
        let count = queuedTasks.count + punchItems.count
        if !seasonalVisitPlans.isEmpty {
            if count > 0 {
                return "Chez assumes a spring and fall contractor walkthrough. These are the extra jobs you've already batched onto that maintenance rhythm."
            }
            return "Chez assumes a spring and fall contractor walkthrough. Review the default checklist below, then add odd jobs and touch-ups anytime."
        }
        if count > 0 {
            return "\(count) small job\(count == 1 ? "" : "s") are batched here instead of showing up as individual chore-like tasks."
        }
        return "Use this bundle for small repairs, touch-ups, and one-offs that are cheaper to batch than to hire out separately."
    }

    private var programActionsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionTitle("How should your contractor help?")

            Text("Choose the kind of work you want this provider to handle. Quotes, installs, repairs, and first-visit setup all route through the same Chez Contractor program.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: HavenTheme.spacing8),
                GridItem(.flexible(), spacing: HavenTheme.spacing8),
            ], spacing: HavenTheme.spacing8) {
                ForEach(shouldPromptFirstVisitSetup
                    ? [HandymanRequestKind.standardVisit, .quote, .repair, .install, .assembly, .question, .setup]
                    : [HandymanRequestKind.standardVisit, .quote, .repair, .install, .assembly, .question]) { kind in
                    Button {
                        selectedRequestKind = kind
                        showRequestComposer = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: kind.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white)
                            Text(kind.title)
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(Color.white)
                                .multilineTextAlignment(.leading)
                            Text(kind.helperText)
                                .font(HavenTypography.caption)
                                .foregroundStyle(Color.white.opacity(0.78))
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 176, alignment: .topLeading)
                        .padding(HavenTheme.spacing16)
                        .background(
                            LinearGradient(
                                colors: [HavenColors.navy900, HavenColors.navy700],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .overlay {
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var firstVisitSetupCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: "house.and.flag.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy700)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First visit should improve the data too")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("When this house still has setup gaps, the contractor should leave it easier to service next time by capturing systems, labels, manuals, and practical service details.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    private var micrositeSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionTitle("Field microsite")

            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    Text("Generate the visit microsite")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("The contractor gets a clean, offline-capable page with the checklist, quick upsells, and first-visit setup prompts for the house.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)

                    if activePreferredHandyman == nil {
                        Text("Pick a preferred contractor first so Chez knows who this should be routed to.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else if primaryVisitTask == nil {
                        Text("Open a spring or fall visit to create the microsite for that specific stop.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        HStack(spacing: HavenTheme.spacing8) {
                            HavenButton(
                                title: portalSession == nil ? "Prepare microsite" : "Open microsite",
                                action: {
                                    Task { await openMicrosite() }
                                },
                                style: .primary,
                                icon: "arrow.up.forward.app",
                                isLoading: isPreparingMicrosite
                            )

                            if portalSession != nil {
                                Button("Refresh") {
                                    Task { await regenerateMicrosite() }
                                }
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(HavenColors.navy700)
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentRequestsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionTitle("Recent requests")
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(requests.prefix(4)) { request in
                    HavenCard {
                        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(request.title)
                                    .font(HavenTypography.body.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text([
                                    HandymanRequestKind(rawValue: request.requestType)?.title,
                                    request.preferredTiming
                                ].compactMap { $0 }.joined(separator: " · "))
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Text(request.typedStatus.displayLabel)
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                                .background(HavenColors.beige200)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var seasonalPlanSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionTitle("Spring & fall walkthroughs")

            Text("These are the default maintenance checks Chez expects your contractor to review each visit. Add any odd jobs on top, and let them flag bigger issues that need a specialist.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            VStack(spacing: HavenTheme.spacing8) {
                ForEach(seasonalVisitPlans) { plan in
                    seasonalPlanCard(plan)
                }
            }
        }
    }

    private var jobsForNextVisitSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionTitle("Jobs for next visit")
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(queuedTasks) { task in
                    Button {
                        selectedQueuedTask = task
                    } label: {
                        HavenCard {
                            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(HavenTypography.body.weight(.semibold))
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text(MaintenanceDateFormatting.dueLabel(for: task.nextDueDate))
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                Spacer(minLength: 0)
                                Text("Ready")
                                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                    .foregroundStyle(HavenColors.navy700)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(HavenColors.beige200)
                                    .clipShape(Capsule())
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                ForEach(visibleManualPunchItems.prefix(6)) { item in
                    Button {
                        showPunchList = true
                    } label: {
                        HavenCard {
                            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(HavenTypography.body.weight(.semibold))
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text(item.description?.isEmpty == false ? item.description ?? "Added from the punch list." : "Added from the punch list.")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .lineLimit(2)
                                }
                                Spacer(minLength: 0)
                                Text("You added")
                                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                    .foregroundStyle(HavenColors.action)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(HavenColors.action.opacity(0.08))
                                    .clipShape(Capsule())
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionTitle("Optional add-ons")
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(visibleSuggestedTasks.prefix(6)) { task in
                    HavenCard {
                        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(HavenTypography.body.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(MaintenanceDateFormatting.dueLabel(for: task.nextDueDate))
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            Button {
                                Task { await addToQueue(task) }
                            } label: {
                                Text("Add")
                                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                    .foregroundStyle(HavenColors.navy700)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .overlay(
                                        Capsule()
                                            .stroke(HavenColors.navy.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func seasonalPlanCard(_ plan: HandymanSeasonalPlan) -> some View {
        if let visitTask = plan.visitTask {
            Button {
                selectedQueuedTask = visitTask
            } label: {
                seasonalPlanCardBody(plan)
            }
            .buttonStyle(.plain)
        } else {
            seasonalPlanCardBody(plan)
        }
    }

    private func seasonalPlanCardBody(_ plan: HandymanSeasonalPlan) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.reviewLabel)
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(plan.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(plan.subtitle)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    if let visitTask = plan.visitTask {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Review")
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(HavenColors.navy700)
                            Text(MaintenanceDateFormatting.dueLabel(for: visitTask.nextDueDate))
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(plan.defaultItems.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.top, 2)
                            Text(item)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if plan.overflowCount > 0 {
                        Text("+ \(plan.overflowCount) more default checks based on your home")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(HavenTypography.uiSectionHeader)
            .tracking(1.5)
            .foregroundStyle(HavenColors.textTertiary)
    }

    private func footerButton(title: String, action: @escaping () -> Void, disabled: Bool = false) -> some View {
        HavenButton(
            title: title,
            action: action,
            style: .primary,
            icon: disabled ? "checkmark.circle.fill" : "calendar.badge.plus",
            isDisabled: disabled
        )
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.vertical, HavenTheme.spacing12)
        .background(.ultraThinMaterial)
    }

    private func loadProgramContext() async {
        isLoading = true
        defer { isLoading = false }
        punchItems = HandymanPunchListViewModel.deduplicated(
            (try? await db.fetchPendingHandymanPunchItems(householdId: householdId)) ?? []
        )
        requests = (try? await db.fetchHandymanRequests(
            householdId: householdId,
            propertyId: propertyId,
            limit: 6
        )) ?? []
        if let propertyId {
            property = try? await db.fetchProperty(id: propertyId)
            systems = (try? await db.fetchHomeSystems(propertyId: propertyId)) ?? []
            allTasksForProperty = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
        } else {
            property = nil
            systems = []
            allTasksForProperty = []
        }
        if let visitTask = primaryVisitTask {
            portalSession = try? await db.fetchHandymanPortalSession(visitTaskId: visitTask.id)
        } else {
            portalSession = nil
        }
    }

    private func addToQueue(_ task: MaintenanceTaskDBRow) async {
        try? await UnifiedRoutingActions.routeToHandyman(task: task, category: nil)
        hiddenSuggestedTaskIds.insert(task.id)
        showToast("Added to contractor bundle")
        onChanged()
    }

    private func checklistTasks(for visitTask: MaintenanceTaskDBRow) -> [MaintenanceTaskDBRow] {
        guard let bundleKey = visitTask.templateId else { return [] }
        return allTasksForProperty.filter { task in
            guard task.id != visitTask.id,
                  task.isArchived != true,
                  let templateId = task.templateId,
                  let template = MaintenanceTemplates.template(forKey: templateId) else {
                return false
            }
            return template.bundleId == bundleKey && task.assignedRoute != "diy"
        }
    }

    private func diyClaims(for visitTask: MaintenanceTaskDBRow) -> [MaintenanceTaskDBRow] {
        guard let bundleKey = visitTask.templateId else { return [] }
        return allTasksForProperty.filter { task in
            guard task.id != visitTask.id,
                  task.isArchived != true,
                  let templateId = task.templateId,
                  let template = MaintenanceTemplates.template(forKey: templateId) else {
                return false
            }
            return template.bundleId == bundleKey && task.assignedRoute == "diy"
        }
    }

    private func scheduleVisit(on date: Date, contractor: ContractorRow?) async {
        guard let propertyId else {
            showToast("Pick a property before scheduling a contractor visit.")
            return
        }

        var activeRoutine = routine
        if activeRoutine == nil {
            activeRoutine = try? await db.fetchOrCreateHandymanRoutine(
                householdId: householdId,
                propertyId: propertyId,
                preferredHandymanContractorId: contractor?.id ?? activePreferredHandyman?.id
            )
        }
        guard var activeRoutine else {
            showToast("Couldn't create a contractor routine.")
            return
        }

        if let contractor {
            var householdUpdate = HouseholdUpdate()
            householdUpdate.preferredHandymanContractorId = contractor.id
            _ = try? await db.updateHousehold(id: householdId, householdUpdate)

            if activeRoutine.vendorId != contractor.id {
                var routineUpdate = RoutineUpdate()
                routineUpdate.vendorId = contractor.id
                activeRoutine = (try? await db.updateRoutine(id: activeRoutine.id, routineUpdate)) ?? activeRoutine
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        _ = try? await ServiceOrchestrator.recordVisit(
            routine: activeRoutine,
            scheduledDate: dateString,
            visitState: .scheduled
        )
        showToast("Contractor visit scheduled for \(MaintenanceDateFormatting.shortDate(dateString))")
        onChanged()
    }

    private func openMicrosite() async {
        guard let visitTask = primaryVisitTask, activePreferredHandyman != nil else { return }
        isPreparingMicrosite = true
        defer { isPreparingMicrosite = false }

        do {
            let session = try await HandymanVisitService.ensurePortalSession(
                parentTask: visitTask,
                property: property,
                systems: systems,
                checklistTasks: checklistTasks(for: visitTask),
                diyClaims: diyClaims(for: visitTask),
                punchItems: punchItems,
                upsellCandidates: visibleSuggestedTasks.prefix(6).map { task in
                    HandymanVisitService.UpsellCandidate(
                        id: task.id,
                        title: task.title,
                        subtitle: MaintenanceDateFormatting.dueLabel(for: task.nextDueDate),
                        urgencyDays: nil,
                        source: .task(task)
                    )
                },
                preferredHandyman: activePreferredHandyman
            )
            portalSession = session
            if let url = HandymanVisitService.portalURL(for: session.portalToken, visitId: visitTask.id) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
                showToast("Microsite ready")
            }
        } catch {
            showToast("Couldn't prepare microsite")
        }
    }

    private func regenerateMicrosite() async {
        guard let visitTask = primaryVisitTask, activePreferredHandyman != nil else { return }
        isPreparingMicrosite = true
        defer { isPreparingMicrosite = false }

        do {
            let session = try await HandymanVisitService.ensurePortalSession(
                parentTask: visitTask,
                property: property,
                systems: systems,
                checklistTasks: checklistTasks(for: visitTask),
                diyClaims: diyClaims(for: visitTask),
                punchItems: punchItems,
                upsellCandidates: visibleSuggestedTasks.prefix(6).map { task in
                    HandymanVisitService.UpsellCandidate(
                        id: task.id,
                        title: task.title,
                        subtitle: MaintenanceDateFormatting.dueLabel(for: task.nextDueDate),
                        urgencyDays: nil,
                        source: .task(task)
                    )
                },
                preferredHandyman: activePreferredHandyman,
                rotateAccessToken: true
            )
            portalSession = session
            if let url = HandymanVisitService.portalURL(for: session.portalToken, visitId: visitTask.id) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
                showToast("Microsite link refreshed")
            }
        } catch {
            showToast("Couldn't refresh microsite")
        }
    }

    private func showToast(_ message: String) {
        statusToast = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { statusToast = nil }
            }
        }
    }
}

private struct HandymanProviderPickerSheet: View {
    let onFallback: () -> Void
    let onSelected: (ContractorRow) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var providers: [HandymanProviderDirectoryRow] = []
    @State private var isLoading = false
    @State private var connectingWorkspaceId: String?
    @State private var errorMessage: String?

    private let db = DatabaseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        Text("Choose a Chez Field contractor")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Search the Chez Field directory, connect a contractor to this home, and start scheduling visits right away.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        HStack(spacing: HavenTheme.spacing8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(HavenColors.textSecondary)
                            TextField("Search companies", text: $query)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, HavenTheme.spacing16)
                        .padding(.vertical, HavenTheme.spacing12)
                        .background(HavenColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                        .padding(.horizontal, HavenTheme.spacing4)
                }

                if isLoading && providers.isEmpty {
                    ProgressView("Loading contractors…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, HavenTheme.spacing24)
                } else if providers.isEmpty {
                    ContentUnavailableView(
                        "No contractors found",
                        systemImage: "wrench.adjustable.fill",
                        description: Text("Try another search, or use Alfred to look outside the Chez Field directory.")
                    )
                    .padding(.top, HavenTheme.spacing24)
                } else {
                    VStack(spacing: HavenTheme.spacing12) {
                        ForEach(providers) { provider in
                            HavenCard {
                                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                                    HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(HavenColors.action.opacity(0.12))
                                            .frame(width: 42, height: 42)
                                            .overlay {
                                                Image(systemName: "wrench.adjustable.fill")
                                                    .foregroundStyle(HavenColors.action)
                                            }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(provider.companyName)
                                                .font(HavenTypography.headline)
                                                .foregroundStyle(HavenColors.textPrimary)

                                            Text(providerContactLine(provider))
                                                .font(HavenTypography.caption)
                                                .foregroundStyle(HavenColors.textSecondary)
                                        }

                                        Spacer(minLength: 0)

                                        VStack(alignment: .trailing, spacing: 6) {
                                            if provider.isPreferred {
                                                statusBadge("Preferred", color: HavenColors.success)
                                            } else if provider.isLinked {
                                                statusBadge("Linked", color: HavenColors.navy700)
                                            }

                                            if let activeMemberCount = provider.activeMemberCount, activeMemberCount > 0 {
                                                Text(memberCountLabel(activeMemberCount))
                                                    .font(HavenTypography.caption)
                                                    .foregroundStyle(HavenColors.textSecondary)
                                            }
                                        }
                                    }

                                    HStack(spacing: HavenTheme.spacing8) {
                                        Button {
                                            Task { await choose(provider) }
                                        } label: {
                                            HStack(spacing: 8) {
                                                if connectingWorkspaceId == provider.id {
                                                    ProgressView()
                                                        .progressViewStyle(.circular)
                                                        .tint(HavenColors.textOnAction)
                                                }
                                                Text(provider.isLinked ? "Use this contractor" : "Connect & use")
                                                    .font(HavenTypography.uiButton)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, HavenTheme.spacing12)
                                            .background(HavenColors.action)
                                            .foregroundStyle(HavenColors.textOnAction)
                                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(connectingWorkspaceId != nil)

                                        if let website = normalized(provider.website),
                                           let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                                            Link(destination: url) {
                                                Text("Website")
                                                    .font(HavenTypography.uiButton)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, HavenTheme.spacing12)
                                                    .background(HavenColors.surfaceSecondary)
                                                    .foregroundStyle(HavenColors.navy700)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                                            .stroke(HavenColors.border, lineWidth: 1)
                                                    )
                                                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(HavenTheme.spacing20)
        }
        .background(HavenColors.background)
        .navigationTitle("Choose Contractor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Use Alfred") {
                    dismiss()
                    onFallback()
                }
                .foregroundStyle(HavenColors.action)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
        .task {
            await loadProviders()
        }
        .onChange(of: query) { _, _ in
            Task { await loadProviders() }
        }
    }

    private func loadProviders() async {
        isLoading = true
        defer { isLoading = false }
        do {
            providers = try await db.searchHandymanProviders(query: query, limit: 18)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func providerContactLine(_ provider: HandymanProviderDirectoryRow) -> String {
        let parts = [
            normalized(provider.primaryPhone),
            normalized(provider.primaryEmail)
        ]
            .compactMap { $0 }
        let joined = parts.joined(separator: " • ")
        return joined.isEmpty ? "Chez Field provider" : joined
    }

    private func memberCountLabel(_ count: Int) -> String {
        "\(count) tech\(count == 1 ? "" : "s")"
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func choose(_ provider: HandymanProviderDirectoryRow) async {
        connectingWorkspaceId = provider.id
        defer { connectingWorkspaceId = nil }
        do {
            let contractor = try await db.connectHandymanProviderToCurrentHousehold(
                workspaceId: provider.id,
                setPreferred: true
            )
            errorMessage = nil
            dismiss()
            onSelected(contractor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func statusBadge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(HavenTypography.uiLabelSmall.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

private struct QuickAddHandymanItemSheet: View {
    let householdId: UUID
    let propertyId: UUID?
    let onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("What should the contractor handle?") {
                TextField("Title", text: $title)
            }

            Section("Notes (optional)") {
                TextField("Anything they should know?", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
        .navigationTitle("Add Contractor Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(HavenColors.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(HavenColors.textPrimary)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await ServiceOrchestrator.createHandymanItem(
                householdId: householdId,
                propertyId: propertyId,
                title: trimmed,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
            )
            Haptics.success()
            onAdded()
            dismiss()
        } catch {
            Haptics.error()
        }
    }
}
