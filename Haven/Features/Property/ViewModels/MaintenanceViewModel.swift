import SwiftUI
import Combine

@MainActor
final class MaintenanceViewModel: ObservableObject {
    /// Shared singleton so tasks remain cached across navigation.
    /// Pull-to-refresh and explicit reloads still hit the network.
    static let shared = MaintenanceViewModel()

    @Published var tasks: [MaintenanceTaskDBRow] = []
    @Published var properties: [PropertyRow] = []
    @Published var systems: [HomeSystemRow] = []
    @Published var contractors: [ContractorRow] = []
    @Published var users: [UserRow] = []
    @Published var vehicles: [VehicleRow] = []
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var filterPropertyId: UUID?
    @Published var filterCategory: String?
    @Published var filterStatus: TaskFilterStatus = .all
    @Published var recentlyCompletedIds: Set<UUID> = []
    @Published var completionToast: CompletionToast?
    /// Phase 66: The household's preferred handyman contractor, resolved
    /// from `households.preferred_handyman_contractor_id` (Phase 63). Used
    /// by the Maintenance tab's ownership sub-groups and the
    /// `TaskRoutingPicker` to render "Add to [Name]'s next visit" copy.
    @Published var preferredHandyman: ContractorRow?

    // MARK: - Phase 66 route sub-group computeds
    //
    // These are the ownership lenses Phase 66 renders inside the
    // Phase 56.5 state buckets. They read from the existing `tasks`
    // array and filter by `assignedRoute`. Empty arrays mean the
    // sub-section renders nothing (the Phase 66 layout hides empty
    // sub-sections to avoid chrome noise).

    /// Tasks with `assigned_route == 'vendor'` — vendor visits.
    var vendorRoutedTasks: [MaintenanceTaskDBRow] {
        baseFiltered.filter { $0.assignedRoute == "vendor" }
    }

    /// Tasks with `assigned_route == 'handyman'` — on the handyman list.
    var handymanRoutedTasks: [MaintenanceTaskDBRow] {
        baseFiltered.filter { $0.assignedRoute == "handyman" }
    }

    /// Tasks with `assigned_route == 'diy'` — personal to-dos.
    var diyRoutedTasks: [MaintenanceTaskDBRow] {
        baseFiltered.filter { $0.assignedRoute == "diy" }
    }

    /// Tasks with no assigned_route yet — picker should surface. These
    /// are typically vendor/either tasks waiting for the user or the
    /// reconciler to resolve routing.
    var unroutedTasks: [MaintenanceTaskDBRow] {
        baseFiltered.filter { $0.assignedRoute == nil }
    }

    private var cancellables = Set<AnyCancellable>()

    struct CompletionToast: Identifiable {
        let id = UUID()
        let taskTitle: String
        let nextDueDate: String
    }

    private let db = DatabaseService.shared
    /// Phase 95 (gap #94) — Realtime subscription for cross-device
    /// task sync. Stays nil until `startRealtimeIfNeeded()` resolves
    /// the household, then survives until the view model's deinit.
    /// On INSERT/UPDATE the local `tasks` array merges in place; on
    /// DELETE the row is removed. Drives "Spouse A completes a
    /// task → Spouse B's open Tasks tab updates within seconds"
    /// without manual refresh.
    private var realtime: MaintenanceRealtimeSubscription?
    private var systemsRealtime: HomeSystemRealtimeSubscription?
    private var contractorsRealtime: ContractorRealtimeSubscription?
    private var realtimeHouseholdId: UUID?

    enum TaskFilterStatus: String, CaseIterable {
        case all = "All"
        case overdue = "Overdue"
        case dueThisWeek = "This Week"
        case dueThisMonth = "This Month"
        case upcoming = "Upcoming"
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    private func dueDate(for task: MaintenanceTaskDBRow) -> Date? {
        dateFormatter.date(from: task.nextDueDate)
    }

    // MARK: - Grouped Tasks

    var overdueTasks: [MaintenanceTaskDBRow] {
        baseFiltered.filter { dueDate(for: $0).map { $0 < .now } ?? false }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }

    var dueThisWeekTasks: [MaintenanceTaskDBRow] {
        let cal = Calendar.current
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: .now) ?? .now
        return baseFiltered.filter { task in
            guard let date = dueDate(for: task) else { return false }
            return date >= .now && date <= endOfWeek
        }.sorted { $0.nextDueDate < $1.nextDueDate }
    }

    var dueThisMonthTasks: [MaintenanceTaskDBRow] {
        let cal = Calendar.current
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: .now) ?? .now
        let endOfMonth = cal.date(byAdding: .month, value: 1, to: .now) ?? .now
        return baseFiltered.filter { task in
            guard let date = dueDate(for: task) else { return false }
            return date > endOfWeek && date <= endOfMonth
        }.sorted { $0.nextDueDate < $1.nextDueDate }
    }

    var upcomingTasks: [MaintenanceTaskDBRow] {
        let cal = Calendar.current
        let endOfMonth = cal.date(byAdding: .month, value: 1, to: .now) ?? .now
        return baseFiltered.filter { task in
            guard let date = dueDate(for: task) else { return false }
            return date > endOfMonth
        }.sorted { $0.nextDueDate < $1.nextDueDate }
    }

    var filteredTasks: [MaintenanceTaskDBRow] {
        switch filterStatus {
        case .all: return baseFiltered.sorted { $0.nextDueDate < $1.nextDueDate }
        case .overdue: return overdueTasks
        case .dueThisWeek: return dueThisWeekTasks
        case .dueThisMonth: return dueThisMonthTasks
        case .upcoming: return upcomingTasks
        }
    }

    private var baseFiltered: [MaintenanceTaskDBRow] {
        tasks.filter { task in
            // Hide recently completed tasks until next refresh
            guard !recentlyCompletedIds.contains(task.id) else { return false }
            // Phase 67: hide bundle children from the main task list. They
            // render only inside the parent bundle's HandymanVisitDetailView
            // (or other bundle detail surface). Detected via the template's
            // `.bundledIntoParent` routing — a child template always has a
            // non-nil bundleId which makes its `routing` getter return this
            // value. Tasks without a template_id (custom tasks) are never
            // bundled and pass through. Once a user claims a child as DIY
            // (assigned_route == "diy"), the child escapes the bundle and
            // surfaces in main lists.
            if task.assignedRoute != "diy",
               let templateId = task.templateId,
               let template = MaintenanceTemplates.template(forKey: templateId),
               template.routing == .bundledIntoParent {
                return false
            }
            let matchesProperty = filterPropertyId == nil || task.propertyId == filterPropertyId
            let matchesCategory: Bool = {
                guard let cat = filterCategory else { return true }
                guard let systemId = task.systemId else { return false }
                guard let system = systems.first(where: { $0.id == systemId }) else { return false }
                return system.category == cat
            }()
            return matchesProperty && matchesCategory
        }
    }

    var overdueCount: Int { overdueTasks.count }

    var availableCategories: [String] {
        Array(Set(systems.map(\.category))).sorted()
    }

    // MARK: - By System Grouping

    var tasksBySystem: [(systemName: String, tasks: [MaintenanceTaskDBRow])] {
        let sorted = baseFiltered.sorted { $0.nextDueDate < $1.nextDueDate }
        var groups: [String: [MaintenanceTaskDBRow]] = [:]
        for task in sorted {
            let name = systemName(for: task.systemId) ?? "General"
            groups[name, default: []].append(task)
        }
        return groups.sorted { $0.key < $1.key }.map { (systemName: $0.key, tasks: $0.value) }
    }

    // MARK: - By Type Grouping

    enum MaintenanceType: String, CaseIterable {
        case quickDIY = "Quick DIY"
        case scheduledService = "Scheduled Service"
        case seasonal = "Seasonal"
        case major = "Major"

        var icon: String {
            switch self {
            case .quickDIY: return "hand.raised.fill"
            case .scheduledService: return "person.badge.key.fill"
            case .seasonal: return "leaf"
            case .major: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .quickDIY: return HavenColors.success
            case .scheduledService: return HavenColors.info
            case .seasonal: return HavenColors.warning
            case .major: return HavenColors.critical
            }
        }
    }

    func maintenanceType(for task: MaintenanceTaskDBRow) -> MaintenanceType {
        if task.isDiy == true { return .quickDIY }
        if let season = task.seasonalTiming, !season.isEmpty { return .seasonal }
        if task.professionalRequired == true { return .scheduledService }
        if let cost = task.costRange, cost.contains("$$$") { return .major }
        return .scheduledService
    }

    var tasksByType: [(type: MaintenanceType, tasks: [MaintenanceTaskDBRow])] {
        let sorted = baseFiltered.sorted { $0.nextDueDate < $1.nextDueDate }
        var groups: [MaintenanceType: [MaintenanceTaskDBRow]] = [:]
        for task in sorted {
            let type = maintenanceType(for: task)
            groups[type, default: []].append(task)
        }
        return MaintenanceType.allCases.compactMap { type in
            guard let tasks = groups[type], !tasks.isEmpty else { return nil }
            return (type: type, tasks: tasks)
        }
    }

    // MARK: - Loading

    func subscribeToExternalChanges() {
        guard cancellables.isEmpty else { return }
        NotificationCenter.default.publisher(for: .maintenanceTaskChanged)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { [weak self] in await self?.loadTasks() }
            }
            .store(in: &cancellables)
    }

    func loadTasks() async {
        isLoading = true
        recentlyCompletedIds.removeAll()
        completionToast = nil
        do {
            async let tasksResult = db.fetchMaintenanceTasks()
            async let propsResult = db.fetchProperties()
            async let contractorsResult = db.fetchContractors()
            let (t, p, c) = try await (tasksResult, propsResult, contractorsResult)
            tasks = t
            properties = p
            contractors = c
            users = (try? await db.fetchHouseholdUsers()) ?? []
            vehicles = (try? await db.fetchVehicles()) ?? []
            // Build 87 (Home Manager expansion): merge family + staff into
            // a single `familyMembers` array so the existing `linkedUserId`
            // lookups in `assignedUserName` and `assignedUserAvatarColor`
            // can also resolve home manager / staff rows. The previous
            // `fetchFamilyMembers` query filters out staff server-side, so
            // we have to ask for both buckets and concatenate.
            let family = (try? await db.fetchFamilyMembers()) ?? []
            let staff = (try? await db.fetchHouseholdStaff()) ?? []
            familyMembers = family + staff

            // Fetch systems for all properties
            var allSystems: [HomeSystemRow] = []
            for prop in p {
                let sys = try await db.fetchHomeSystems(propertyId: prop.id)
                allSystems.append(contentsOf: sys)
            }
            systems = allSystems

            // Phase 66: resolve the preferred handyman so every
            // route-picker surface can render "Add to [Name]'s next
            // visit" without a separate fetch. Ignores fetch failures
            // silently — the Maintenance tab should render regardless.
            if let primary = p.first,
               let household = try? await db.fetchHousehold(id: primary.householdId),
               let handymanId = household.preferredHandymanContractorId {
                preferredHandyman = c.first { $0.id == handymanId }
            } else {
                preferredHandyman = nil
            }

            // Phase 95 (gap #94) — start (or refresh) the Realtime
            // subscription using the resolved household. The
            // subscription is idempotent: re-calling start() against
            // the same household no-ops, while a household switch
            // tears down + re-subscribes on the new id.
            if let primary = p.first {
                await startRealtimeIfNeeded(householdId: primary.householdId)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// Phase 95 (gap #94) — opens the Realtime subscription for
    /// `maintenance_tasks` filtered by household. Wired into the
    /// initial `loadTasks` pass so the channel is live by the
    /// time the user reaches the Maintenance tab. The subscription
    /// merges live INSERT / UPDATE / DELETE events into the local
    /// `tasks` array on the main actor.
    private func startRealtimeIfNeeded(householdId: UUID) async {
        if realtimeHouseholdId == householdId,
           realtime != nil,
           systemsRealtime != nil,
           contractorsRealtime != nil { return }

        // Tear down any prior subscriptions (household switch).
        if let prior = realtime { await prior.stop() }
        if let prior = systemsRealtime { await prior.stop() }
        if let prior = contractorsRealtime { await prior.stop() }

        // --- Tasks
        let taskSub = MaintenanceRealtimeSubscription(householdId: householdId)
        taskSub.onInsert = { [weak self] row in
            guard let self else { return }
            if !self.tasks.contains(where: { $0.id == row.id }) {
                self.tasks.append(row)
            }
        }
        taskSub.onUpdate = { [weak self] row in
            guard let self else { return }
            if let idx = self.tasks.firstIndex(where: { $0.id == row.id }) {
                self.tasks[idx] = row
            } else {
                self.tasks.append(row)
            }
        }
        taskSub.onDelete = { [weak self] taskId in
            guard let self else { return }
            self.tasks.removeAll { $0.id == taskId }
        }

        // --- Home systems (PR 45)
        let systemSub = HomeSystemRealtimeSubscription(householdId: householdId)
        systemSub.onInsert = { [weak self] row in
            guard let self else { return }
            if !self.systems.contains(where: { $0.id == row.id }) {
                self.systems.append(row)
            }
        }
        systemSub.onUpdate = { [weak self] row in
            guard let self else { return }
            if let idx = self.systems.firstIndex(where: { $0.id == row.id }) {
                self.systems[idx] = row
            } else {
                self.systems.append(row)
            }
        }
        systemSub.onDelete = { [weak self] systemId in
            guard let self else { return }
            self.systems.removeAll { $0.id == systemId }
        }

        // --- Contractors (PR 45)
        let contractorSub = ContractorRealtimeSubscription(householdId: householdId)
        contractorSub.onInsert = { [weak self] row in
            guard let self else { return }
            if !self.contractors.contains(where: { $0.id == row.id }) {
                self.contractors.append(row)
            }
        }
        contractorSub.onUpdate = { [weak self] row in
            guard let self else { return }
            if let idx = self.contractors.firstIndex(where: { $0.id == row.id }) {
                self.contractors[idx] = row
            } else {
                self.contractors.append(row)
            }
        }
        contractorSub.onDelete = { [weak self] contractorId in
            guard let self else { return }
            self.contractors.removeAll { $0.id == contractorId }
        }

        realtime = taskSub
        systemsRealtime = systemSub
        contractorsRealtime = contractorSub
        realtimeHouseholdId = householdId

        await taskSub.start()
        await systemSub.start()
        await contractorSub.start()
    }

    func propertyName(for id: UUID) -> String {
        properties.first { $0.id == id }?.name ?? "Unknown"
    }

    // MARK: - Property Color Coding

    private static let propertyColorPalette: [Color] = [
        Color(red: 0.27, green: 0.52, blue: 0.68),  // Slate blue
        Color(red: 0.55, green: 0.71, blue: 0.52),  // Sage green
        Color(red: 0.80, green: 0.60, blue: 0.36),  // Warm amber
        Color(red: 0.65, green: 0.45, blue: 0.62),  // Muted plum
        Color(red: 0.60, green: 0.72, blue: 0.74),  // Dusty teal
        Color(red: 0.78, green: 0.55, blue: 0.55),  // Rose clay
        Color(red: 0.50, green: 0.62, blue: 0.45),  // Forest moss
        Color(red: 0.72, green: 0.62, blue: 0.48),  // Sand
    ]

    /// Returns a consistent color for each property based on its position in the properties array.
    func propertyColor(for propertyId: UUID) -> Color {
        guard let index = properties.firstIndex(where: { $0.id == propertyId }) else {
            return HavenColors.navy700
        }
        return Self.propertyColorPalette[index % Self.propertyColorPalette.count]
    }

    /// Returns all properties with their assigned colors for the filter bar.
    var propertiesWithColors: [(property: PropertyRow, color: Color)] {
        properties.enumerated().map { index, prop in
            (property: prop, color: Self.propertyColorPalette[index % Self.propertyColorPalette.count])
        }
    }

    func systemName(for id: UUID?) -> String? {
        guard let id else { return nil }
        return systems.first { $0.id == id }?.name
    }

    /// Build 90: Resolve the system's category string (e.g. "HVAC",
    /// "Landscaping") for vendor card branding. Used by UnifiedTaskCard
    /// to pick trade-specific accent colors when no vendor brand is set.
    func systemCategory(for id: UUID?) -> String? {
        guard let id else { return nil }
        return systems.first { $0.id == id }?.category
    }

    func vehicleName(for id: UUID?) -> String? {
        guard let id else { return nil }
        return vehicles.first { $0.id == id }?.displayName
    }

    func assignedUserName(for task: MaintenanceTaskDBRow) -> String? {
        guard let userId = task.assignedToUserId else { return nil }
        guard let user = users.first(where: { $0.id == userId }) else { return nil }
        let firstName = user.fullName?.components(separatedBy: " ").first ?? user.fullName ?? "Assigned"
        // Build 87 (Home Manager expansion): append " · Home Manager"
        // when the assignee is a linked staff user. Family members render
        // without a suffix to keep their pill compact (the "couple"
        // chip already implies the relationship).
        if let member = familyMembers.first(where: { $0.linkedUserId == userId }) {
            switch member.memberType {
            case "home_manager": return "\(firstName) · Home Manager"
            case "staff": return "\(firstName) · Staff"
            default: break
            }
        }
        return firstName
    }

    func assignedUserAvatarColor(for task: MaintenanceTaskDBRow) -> AvatarColor? {
        guard let userId = task.assignedToUserId else { return nil }
        guard let member = familyMembers.first(where: { $0.linkedUserId == userId }) else { return nil }
        return member.avatarColor.flatMap { AvatarColor(rawValue: $0) }
    }

    func assignedContractorName(for task: MaintenanceTaskDBRow) -> String? {
        // Check direct assignment first
        if let contractorId = task.assignedContractorId {
            return contractors.first(where: { $0.id == contractorId })?.companyName
        }
        // Fall back to system's preferred contractor
        guard let systemId = task.systemId,
              let system = systems.first(where: { $0.id == systemId }),
              let prefId = system.preferredContractorId else { return nil }
        return contractors.first(where: { $0.id == prefId })?.companyName
    }

    func completeTask(_ task: MaintenanceTaskDBRow) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nextDate = calculateNextDueDate(frequency: task.frequency, from: .now)

        // Optimistic: hide task and show toast immediately
        recentlyCompletedIds.insert(task.id)
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        completionToast = CompletionToast(
            taskTitle: task.title,
            nextDueDate: displayFormatter.string(from: nextDate)
        )
        Haptics.success()

        do {
            let updated = try await db.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(
                    lastCompletedDate: formatter.string(from: .now),
                    nextDueDate: formatter.string(from: nextDate)
                )
            )
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx] = updated
            }

            // Update system's last_service_date and next_service_due
            if let systemId = task.systemId {
                let systemTasks = tasks.filter { $0.systemId == systemId && $0.id != task.id }
                let nextSystemDue = systemTasks
                    .compactMap { formatter.date(from: $0.nextDueDate) }
                    .filter { $0 > .now }
                    .min()
                let nextDueStr = nextSystemDue.map { formatter.string(from: $0) } ?? formatter.string(from: nextDate)

                _ = try await db.updateHomeSystem(
                    id: systemId,
                    HomeSystemUpdate(
                        lastServiceDate: formatter.string(from: .now),
                        nextServiceDue: nextDueStr
                    )
                )
            }

            // Log service record (only for property-linked tasks)
            if let propertyId = task.propertyId {
                _ = try await db.createServiceRecord(ServiceRecordInsert(
                    propertyId: propertyId,
                    householdId: task.householdId,
                    serviceDate: formatter.string(from: .now),
                    serviceType: "maintenance",
                    description: task.title,
                    systemId: task.systemId,
                    contractorId: MaintenanceTaskRoutingSupport.resolvedContractorId(
                        for: task,
                        systems: systems
                    )
                ))
            }

            // Phase 95 (audit gap #89) — capture mileage at completion
            // for vehicle-linked tasks so the next mileage-trigger
            // recalc (Phase 95 PR 11) has an accurate baseline. We use
            // the vehicle's current odometer as the proxy — better than
            // nothing, and the user can correct later via
            // MileageUpdateSheet. Without this, every-N-miles tasks
            // never accumulate baseline mileage and the scheduler
            // perpetually treats the entire current_mileage as accrued
            // service distance after the first completion.
            if let vehicleId = task.vehicleId {
                let vehicle = try? await db.fetchVehicle(id: vehicleId)
                _ = try? await db.createVehicleServiceRecord(VehicleServiceRecordInsert(
                    vehicleId: vehicleId,
                    householdId: task.householdId,
                    serviceDate: formatter.string(from: .now),
                    serviceType: task.templateId ?? "maintenance",
                    description: task.title,
                    cost: nil,
                    mileageAtService: vehicle?.currentMileage,
                    contractorId: task.assignedContractorId,
                    invoiceDocumentId: nil,
                    notes: nil
                ))
            }

            // Phase 67H: archive any `recurrence='once'` bundle custom
            // subitems that were attached to this task. They served
            // their purpose for this visit; future bundle fires
            // shouldn't re-show them. Idempotent — no-op for non-bundle
            // tasks (no rows match scope_task_id).
            try? await db.markOnceSubitemsUsed(taskId: task.id)

            // Reschedule notifications
            Task { await NotificationScheduler.shared.rescheduleAll() }

            // Notify other tabs
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "completed", "id": task.id.uuidString])

            // Push notification to all household members
            Task {
                let users = try? await db.fetchHouseholdUsers()
                let currentUser = try? await db.fetchCurrentUser()
                let completedBy = currentUser?.fullName?.components(separatedBy: " ").first ?? "Someone"
                let recipientIds = (users ?? []).map(\.id)
                await PushNotificationService.shared.sendTaskCompletedNotification(
                    taskTitle: task.title,
                    completedByName: completedBy,
                    recipientUserIds: recipientIds,
                    taskId: task.id
                )
            }
        } catch {
            // Rollback: show the task again
            recentlyCompletedIds.remove(task.id)
            completionToast = nil
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    /// Optimistically create a custom maintenance task. Inserts a placeholder into
    /// `tasks` immediately, then writes to the database. On success, the placeholder
    /// is replaced with the real row. On failure, the placeholder is removed.
    func createTask(_ insert: MaintenanceTaskInsert) async {
        // Build a synthetic row for immediate display
        let placeholderId = UUID()
        let placeholder = MaintenanceTaskDBRow.synthetic(
            id: placeholderId,
            title: insert.title,
            nextDueDate: insert.nextDueDate,
            propertyId: insert.propertyId,
            vehicleId: insert.vehicleId,
            systemId: insert.systemId,
            householdId: insert.householdId,
            priority: insert.priority,
            assignedToUserId: insert.assignedToUserId,
            assignedContractorId: insert.assignedContractorId,
            frequency: insert.frequency,
            notes: insert.notes
        )
        tasks.insert(placeholder, at: 0)
        Haptics.success()

        do {
            let saved = try await db.createMaintenanceTask(insert)
            // Replace placeholder with real row
            if let idx = tasks.firstIndex(where: { $0.id == placeholderId }) {
                tasks[idx] = saved
            }
            Task { await NotificationScheduler.shared.rescheduleAll() }
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "created", "id": saved.id.uuidString])
        } catch {
            // Rollback
            tasks.removeAll { $0.id == placeholderId }
            self.error = "Failed to create task: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    /// Optimistically batch-delete a set of tasks. Rolls back on failure.
    func bulkDelete(ids: [UUID]) async {
        guard !ids.isEmpty else { return }
        let snapshot = tasks
        let idSet = Set(ids)
        tasks.removeAll { idSet.contains($0.id) }
        Haptics.success()
        do {
            try await db.deleteMaintenanceTasks(ids: ids)
            Task { await NotificationScheduler.shared.rescheduleAll() }
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "bulk_deleted", "count": ids.count])
        } catch {
            tasks = snapshot
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    /// Delete all template-based tasks for a system, then re-create from `MaintenanceTemplates`
    /// using the system's stored subtype. Custom (non-template) tasks are preserved.
    func resetTemplates(for system: HomeSystemRow) async {
        let activeSubs = MaintenanceTemplates.activeSubtypes(
            category: system.category,
            subtype: system.subtype,
            fuelType: system.catalogFuelType
        )
        let templates = MaintenanceTemplates.templates(for: system.category, activeSubtypes: activeSubs)

        let systemTasks = tasks.filter { $0.systemId == system.id }
        let templateTaskIds = systemTasks.filter { $0.isTemplateBased == true }.map(\.id)

        // Optimistic delete
        let snapshot = tasks
        let removeSet = Set(templateTaskIds)
        tasks.removeAll { removeSet.contains($0.id) }

        do {
            try await db.deleteMaintenanceTasks(ids: templateTaskIds)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            for t in templates {
                let nextDue = Calendar.current.date(byAdding: t.interval, to: .now) ?? .now
                let insert = MaintenanceTaskInsert(
                    propertyId: system.propertyId,
                    householdId: system.householdId,
                    title: t.title,
                    frequency: t.frequency,
                    nextDueDate: formatter.string(from: nextDue),
                    systemId: system.id,
                    description: t.description,
                    priority: t.priority,
                    notes: t.notes,
                    isTemplateBased: true,
                    templateId: t.systemCategory + ":" + t.title,
                    seasonalTiming: t.seasonalTiming,
                    isDiy: t.isDIY,
                    professionalRequired: t.professionalRequired,
                    costRange: t.estimatedCostRange,
                    recurrenceRule: t.frequency
                )
                if let saved = try? await db.createMaintenanceTask(insert) {
                    tasks.append(saved)
                }
            }
            Haptics.success()
            Task { await NotificationScheduler.shared.rescheduleAll() }
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "reset_templates", "system_id": system.id.uuidString])
        } catch {
            tasks = snapshot
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    func deleteTask(_ task: MaintenanceTaskDBRow) async {
        let snapshot = tasks
        tasks.removeAll { $0.id == task.id }
        Haptics.success()

        do {
            try await db.deleteMaintenanceTask(id: task.id)
            Task { await NotificationScheduler.shared.rescheduleAll() }
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "deleted", "id": task.id.uuidString])
        } catch {
            tasks = snapshot
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - Phase 19l: Bidirectional Personal ↔ Vendor Toggle

    /// Convert a personal/either task to vendor-managed by linking it to a
    /// contractor and reframing the title + description in Haven's standard
    /// "Schedule Vendor: ..." voice.
    ///
    /// The original wording is sourced from the template (via `templateId`)
    /// rather than the live row, so a previous reframe doesn't pollute the
    /// new one. If the task has no template, falls back to the row's title
    /// (lowercased) so user-added custom tasks still flip cleanly.
    /// Short display name for task titles — strips suffixes like LLC, Inc, and
    /// truncates after the first comma if the result is still over 25 chars.
    static func vendorDisplayName(_ fullName: String) -> String {
        var name = fullName
        // Strip common legal suffixes
        for suffix in [" LLC", " Inc.", " Inc", " Corp.", " Corp", " Co.", " Ltd.", " Ltd", " LP", " LLP"] {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
            }
        }
        // If still long, truncate at first comma
        if name.count > 25, let commaIdx = name.firstIndex(of: ",") {
            name = String(name[name.startIndex..<commaIdx])
        }
        return name.trimmingCharacters(in: .whitespaces)
    }

    func convertToVendorManaged(taskId: UUID, contractor: ContractorRow) async {
        let task: MaintenanceTaskDBRow
        if let cached = tasks.first(where: { $0.id == taskId }) {
            task = cached
        } else {
            do {
                guard let fetched = try await db.fetchAllMaintenanceTasks()
                    .first(where: { $0.id == taskId })
                else { return }
                task = fetched
            } catch {
                self.error = error.localizedDescription
                Haptics.error()
                return
            }
        }

        let originalTemplate = task.templateId.flatMap { MaintenanceTemplates.template(forKey: $0) }
        let originalTitle = originalTemplate?.title ?? task.title
        let originalDescription = originalTemplate?.description ?? task.description ?? ""

        let newTitle = originalTitle
        let newDescription: String = {
            if originalDescription.isEmpty {
                return "\(contractor.companyName) will handle the work."
            }
            return "\(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(originalDescription)"
        }()

        var update = MaintenanceTaskUpdate()
        update.title = newTitle
        update.description = newDescription
        update.assignedContractorId = contractor.id
        update.assignmentType = "vendor"
        update.needsVendor = false

        do {
            let saved = try await db.updateMaintenanceTask(id: taskId, update)
            if let idx = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[idx] = saved
            } else {
                tasks.append(saved)
            }
            Haptics.success()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "convert_to_vendor", "id": taskId.uuidString])
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    /// Convert a vendor-managed task back to personal. Restores the original
    /// template wording from `templateId`, clears the contractor link, and
    /// resets `assignmentType` to "personal".
    ///
    /// If the task isn't template-based, the live title is kept as-is — it
    /// wasn't reframed by Haven so there's nothing to restore.
    func convertToPersonal(taskId: UUID) async {
        guard let task = tasks.first(where: { $0.id == taskId }) else { return }

        var update = MaintenanceTaskUpdate()
        update.assignedContractorId = nil
        update.assignmentType = "personal"
        update.needsVendor = false

        if let templateId = task.templateId,
           let template = MaintenanceTemplates.template(forKey: templateId) {
            update.title = template.title
            update.description = template.description
        }

        do {
            let saved = try await db.updateMaintenanceTask(id: taskId, update)
            if let idx = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[idx] = saved
            }
            Haptics.success()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "convert_to_personal", "id": taskId.uuidString])
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    private func calculateNextDueDate(frequency: String, from date: Date) -> Date {
        let cal = Calendar.current
        switch frequency.lowercased() {
        case "weekly": return cal.date(byAdding: .day, value: 7, to: date)!
        case "every 2 weeks", "biweekly": return cal.date(byAdding: .day, value: 14, to: date)!
        case "every 3 weeks": return cal.date(byAdding: .day, value: 21, to: date)!
        case "monthly": return cal.date(byAdding: .month, value: 1, to: date)!
        case "every 2 months": return cal.date(byAdding: .month, value: 2, to: date)!
        case "quarterly": return cal.date(byAdding: .month, value: 3, to: date)!
        case "every 4 months": return cal.date(byAdding: .month, value: 4, to: date)!
        case "semi-annually": return cal.date(byAdding: .month, value: 6, to: date)!
        case "annually": return cal.date(byAdding: .year, value: 1, to: date)!
        case "every 2 years": return cal.date(byAdding: .year, value: 2, to: date)!
        case "every 3 years": return cal.date(byAdding: .year, value: 3, to: date)!
        case "every 5 years": return cal.date(byAdding: .year, value: 5, to: date)!
        case "every 10 years": return cal.date(byAdding: .year, value: 10, to: date)!
        case "seasonal": return cal.date(byAdding: .month, value: 3, to: date)!
        default: return cal.date(byAdding: .year, value: 1, to: date)!
        }
    }
}
