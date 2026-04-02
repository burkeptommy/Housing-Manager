import SwiftUI
import Combine

@MainActor
final class MaintenanceViewModel: ObservableObject {
    @Published var tasks: [MaintenanceTaskDBRow] = []
    @Published var properties: [PropertyRow] = []
    @Published var systems: [HomeSystemRow] = []
    @Published var contractors: [ContractorRow] = []
    @Published var users: [UserRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var filterPropertyId: UUID?
    @Published var filterCategory: String?
    @Published var filterStatus: TaskFilterStatus = .all
    @Published var recentlyCompletedIds: Set<UUID> = []
    @Published var completionToast: CompletionToast?

    private var cancellables = Set<AnyCancellable>()

    struct CompletionToast: Identifiable {
        let id = UUID()
        let taskTitle: String
        let nextDueDate: String
    }

    private let db = DatabaseService.shared

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

            // Fetch systems for all properties
            var allSystems: [HomeSystemRow] = []
            for prop in p {
                let sys = try await db.fetchHomeSystems(propertyId: prop.id)
                allSystems.append(contentsOf: sys)
            }
            systems = allSystems
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
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

    func assignedUserName(for task: MaintenanceTaskDBRow) -> String? {
        guard let userId = task.assignedToUserId else { return nil }
        guard let user = users.first(where: { $0.id == userId }) else { return nil }
        return user.fullName?.components(separatedBy: " ").first ?? user.fullName
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

            // Log service record
            _ = try await db.createServiceRecord(ServiceRecordInsert(
                propertyId: task.propertyId,
                householdId: task.householdId,
                serviceDate: formatter.string(from: .now),
                serviceType: "maintenance",
                description: task.title,
                systemId: task.systemId
            ))

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

    private func calculateNextDueDate(frequency: String, from date: Date) -> Date {
        let cal = Calendar.current
        switch frequency.lowercased() {
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
