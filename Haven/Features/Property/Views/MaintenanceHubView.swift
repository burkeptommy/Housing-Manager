import SwiftUI

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

    init(filterPropertyId: UUID? = nil) {
        self.filterPropertyId = filterPropertyId
    }

    @StateObject private var viewModel = MaintenanceHubViewModel()
    @State private var showAddRoutineSheet = false
    @State private var editingRoutine: RoutineRow?
    /// Phase 67C: Season selected from Year at a Glance — opens a
    /// season-scoped list sheet. Nil when not looking at a specific season.
    @State private var expandedSeason: YearAtAGlanceCard.Season?
    /// Phase 67D: Task selected for orchestration — presents the unified
    /// routing menu in a sheet. Nil when not routing.
    @State private var orchestratingTask: MaintenanceTaskDBRow?

    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.hasNoContent {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
            } else {
                VStack(alignment: .leading, spacing: HavenTheme.spacing32) {
                    seeFullYearLink

                    // Phase 67C: Year at a Glance — solves the
                    // "spring looks empty" complaint by showing the
                    // full year's maintenance load upfront. Users can
                    // tap any season to drill in.
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

                    YourServicesSection(
                        activeRoutines: viewModel.activeRoutines,
                        pendingRoutines: viewModel.pendingRoutines,
                        vendorsById: viewModel.vendorsById,
                        onTapRoutine: { editingRoutine = $0 },
                        onSetupRoutine: { showAddRoutineSheet = true }
                    )

                    NextHandymanVisitSection(
                        routine: viewModel.handymanRoutine,
                        childTasks: viewModel.handymanTasks,
                        preferredHandyman: viewModel.preferredHandyman,
                        onTap: {
                            if let routine = viewModel.handymanRoutine {
                                editingRoutine = routine
                                Analytics.track(.nextHandymanVisitOpened, [
                                    "routine_id": routine.id.uuidString,
                                    "task_count": viewModel.handymanTasks.count
                                ])
                            }
                        },
                        onScheduleVisit: { viewModel.scheduleHandymanVisit() },
                        onFindHandyman: { viewModel.openFindHandyman() }
                    )

                    VehiclesSection(
                        vehicles: viewModel.vehicles,
                        routinesByVehicle: viewModel.vehicleRoutinesByVehicle,
                        tasksByVehicle: viewModel.tasksByVehicle,
                        shopsById: viewModel.vendorsById,
                        onTapVehicle: { vehicle in
                            if let routine = viewModel.vehicleRoutinesByVehicle[vehicle.id] {
                                editingRoutine = routine
                                Analytics.track(.vehicleRoutineOpened, [
                                    "vehicle_id": vehicle.id.uuidString,
                                    "routine_id": routine.id.uuidString
                                ])
                            } else {
                                viewModel.openVehicleSetup(vehicle: vehicle)
                            }
                        },
                        onSetupVehicle: { vehicle in
                            viewModel.openVehicleSetup(vehicle: vehicle)
                        }
                    )

                    ThisSeasonSection(
                        tasks: viewModel.thisSeasonTasks,
                        onTapTask: { viewModel.openTask($0) },
                        onRouteTask: { task in
                            orchestratingTask = task
                        }
                    )

                    UpcomingScheduledSection(
                        visits: viewModel.scheduledVisits,
                        routinesById: viewModel.allRoutinesById,
                        onTapVisit: { visit in
                            if let routine = viewModel.allRoutinesById[visit.routineId] {
                                editingRoutine = routine
                            }
                        }
                    )
                }
                .padding(.horizontal, HavenTheme.spacing20)
                .padding(.vertical, HavenTheme.spacing16)
            }
        }
        .background(HavenColors.background)
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddRoutineSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .task {
            await viewModel.load(filterPropertyId: filterPropertyId)
        }
        .refreshable {
            await viewModel.load(filterPropertyId: filterPropertyId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }
        .sheet(isPresented: $showAddRoutineSheet, onDismiss: {
            Task { await viewModel.load(filterPropertyId: filterPropertyId) }
        }) {
            NavigationStack {
                RoutineEditSheet(
                    householdId: viewModel.householdId ?? UUID(),
                    propertyId: viewModel.resolvedPropertyId,
                    existing: nil,
                    onSaved: { Task { await viewModel.load(filterPropertyId: filterPropertyId) } }
                )
            }
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
        .sheet(item: $expandedSeason) { season in
            NavigationStack {
                SeasonTasksSheet(
                    season: season,
                    tasks: viewModel.tasksForSeason(season),
                    routines: viewModel.routinesForSeason(season)
                )
            }
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
                                NotificationCenter.default.post(
                                    name: Notification.Name("requestFindVendor"),
                                    object: nil,
                                    userInfo: ["taskId": task.id.uuidString]
                                )
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
                .navigationTitle("Route task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { orchestratingTask = nil }
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

    private var seeFullYearLink: some View {
        NavigationLink {
            MaintenanceScheduleView(
                filterPropertyId: filterPropertyId,
                initialLayout: .calendar
            )
            .onAppear {
                Analytics.track(.seeFullYearTapped, [:])
            }
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

// MARK: - View Model

@MainActor
final class MaintenanceHubViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var activeRoutines: [RoutineRow] = []
    @Published var pendingRoutines: [RoutineRow] = []
    @Published var handymanRoutine: RoutineRow?
    @Published var handymanTasks: [MaintenanceTaskDBRow] = []
    @Published var preferredHandyman: ContractorRow?
    @Published var vehicles: [VehicleRow] = []
    @Published var vehicleRoutinesByVehicle: [UUID: RoutineRow] = [:]
    @Published var tasksByVehicle: [UUID: [MaintenanceTaskDBRow]] = [:]
    @Published var thisSeasonTasks: [MaintenanceTaskDBRow] = []
    @Published var scheduledVisits: [RoutineVisitRow] = []
    @Published var vendorsById: [UUID: ContractorRow] = [:]
    @Published var allRoutinesById: [UUID: RoutineRow] = [:]
    @Published var householdId: UUID?
    @Published var resolvedPropertyId: UUID?
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
        let allRoutines = Array(allRoutinesById.values)
        return YearAtAGlanceAggregator.summarize(
            tasks: allTaskList,
            routines: allRoutines,
            routineTasks: tasksByRoutine
        )
    }

    /// Phase 67C: Surface the list of tasks for a single season when the
    /// user taps a season tile. Rolls up the same pool Year at a Glance
    /// counts.
    func tasksForSeason(_ season: YearAtAGlanceCard.Season) -> [MaintenanceTaskDBRow] {
        var seen: Set<UUID> = []
        var result: [MaintenanceTaskDBRow] = []

        // Tasks via routines
        for (routineId, routineTasks) in tasksByRoutine {
            guard let routine = allRoutinesById[routineId] else { continue }
            let months = Set(routine.activeMonths)
            if !months.isDisjoint(with: season.months) {
                for task in routineTasks where !seen.contains(task.id) && task.isArchived != true {
                    seen.insert(task.id)
                    result.append(task)
                }
            }
        }

        // Unparented tasks
        for task in allTaskList where !seen.contains(task.id) && task.isArchived != true {
            seen.insert(task.id)
            let taskSeason = inferSeason(for: task)
            if taskSeason == season {
                result.append(task)
            }
        }

        return result.sorted { $0.nextDueDate < $1.nextDueDate }
    }

    /// Phase 67C: Routines active in the given season, surfaced as part
    /// of the season-drilldown sheet.
    func routinesForSeason(_ season: YearAtAGlanceCard.Season) -> [RoutineRow] {
        allRoutinesById.values.filter { routine in
            !Set(routine.activeMonths).isDisjoint(with: season.months)
        }.sorted { $0.label < $1.label }
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
            && (handymanRoutine == nil || handymanTasks.isEmpty)
            && vehicles.isEmpty
            && thisSeasonTasks.isEmpty
            && scheduledVisits.isEmpty
    }

    func load(filterPropertyId: UUID?) async {
        isLoading = true
        defer { isLoading = false }

        // Resolve household + property via the property list. Each
        // PropertyRow carries householdId; we assume all properties in
        // the list share a household (which is Haven's invariant).
        let properties = (try? await db.fetchProperties()) ?? []
        guard let firstProperty = properties.first else {
            // No properties yet — nothing to render. Reset state.
            resetToEmpty()
            return
        }
        let hhId = firstProperty.householdId
        householdId = hhId

        let propertyId: UUID? = filterPropertyId ?? firstProperty.id
        resolvedPropertyId = propertyId

        // Fetch the household for the preferred handyman pointer.
        let household = try? await db.fetchHousehold(id: hhId)

        // Load contractors once — used by all sections for vendor logos
        let contractors = (try? await db.fetchContractors()) ?? []
        vendorsById = Dictionary(uniqueKeysWithValues: contractors.map { ($0.id, $0) })

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
        activeRoutines = filterActive(routines: propertyRoutines)
        pendingRoutines = filterPending(routines: propertyRoutines)

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

        // This Season: property tasks with no parent_routine_id, no
        // vehicle_id, due within 90 days.
        thisSeasonTasks = await loadThisSeasonTasks(propertyId: propertyId)

        // Phase 67C: Year at a Glance aggregation source — all property
        // tasks (parented + unparented) + tasks linked per routine.
        if let propertyId {
            let everything = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
            allTaskList = everything.filter { $0.isArchived != true }
        } else {
            allTaskList = []
        }
        var perRoutineTasks: [UUID: [MaintenanceTaskDBRow]] = [:]
        for routine in allRoutinesById.values {
            let tasks = (try? await db.fetchTasksForRoutine(routineId: routine.id)) ?? []
            perRoutineTasks[routine.id] = tasks.filter { $0.isArchived != true }
        }
        tasksByRoutine = perRoutineTasks

        // Scheduled visits
        scheduledVisits = (try? await db.fetchScheduledVisitsForHousehold(householdId: hhId)) ?? []
    }

    private func resetToEmpty() {
        activeRoutines = []
        pendingRoutines = []
        handymanRoutine = nil
        handymanTasks = []
        preferredHandyman = nil
        vehicles = []
        vehicleRoutinesByVehicle = [:]
        tasksByVehicle = [:]
        thisSeasonTasks = []
        scheduledVisits = []
        vendorsById = [:]
        allRoutinesById = [:]
        householdId = nil
        resolvedPropertyId = nil
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

    private func loadThisSeasonTasks(propertyId: UUID?) async -> [MaintenanceTaskDBRow] {
        guard let propertyId else { return [] }
        let tasks = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
        let today = Date()
        let window = Calendar.current.date(byAdding: .day, value: 90, to: today) ?? today

        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"

        return tasks
            .filter { task in
                guard task.isArchived != true else { return false }
                guard task.parentRoutineId == nil else { return false }
                guard task.vehicleId == nil else { return false }
                guard let due = isoFormatter.date(from: task.nextDueDate) else { return false }
                return due <= window
            }
            .sorted { $0.nextDueDate < $1.nextDueDate }
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
        // Surfaces the existing FindHandymanCard / Alfred flow.
        NotificationCenter.default.post(
            name: .openAlfredWithContext,
            object: nil,
            userInfo: [
                "message": "Help me find a handyman"
            ]
        )
    }

    func openVehicleSetup(vehicle: VehicleRow) {
        // Deferred to a shared vehicle-program setup sheet. For now the
        // edit routine sheet handles it (RoutineEditSheet is scope-aware
        // once we extend it in a subsequent pass).
        NotificationCenter.default.post(
            name: Notification.Name("requestVehicleProgramSetup"),
            object: nil,
            userInfo: ["vehicleId": vehicle.id.uuidString]
        )
    }

    func openTask(_ task: MaintenanceTaskDBRow) {
        NotificationCenter.default.post(
            name: Notification.Name("requestTaskDetail"),
            object: nil,
            userInfo: ["taskId": task.id.uuidString]
        )
    }
}
