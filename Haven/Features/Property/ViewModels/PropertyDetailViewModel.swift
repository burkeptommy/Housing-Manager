import SwiftUI
import UserNotifications

@MainActor
final class PropertyDetailViewModel: ObservableObject {
    @Published var property: PropertyRow?
    @Published var systems: [HomeSystemRow] = []
    @Published var maintenanceTasks: [MaintenanceTaskDBRow] = []
    @Published var warranties: [WarrantyRow] = []
    @Published var serviceRecords: [ServiceRecordRow] = []
    @Published var linkedDocuments: [DocumentRow] = []
    @Published var contractors: [ContractorRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var justCompletedTaskId: UUID?

    private let db = DatabaseService.shared

    var systemsByCategory: [(String, [HomeSystemRow])] {
        let groups = Dictionary(grouping: systems) { $0.category }
        return groups.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    var overdueTasks: [MaintenanceTaskDBRow] {
        maintenanceTasks.filter { task in
            guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
            return date < .now
        }
    }

    var dueThisMonthTasks: [MaintenanceTaskDBRow] {
        let cal = Calendar.current
        let now = Date.now
        let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: cal.startOfDay(for: now)) ?? now
        return maintenanceTasks.filter { task in
            guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
            return date >= now && date <= endOfMonth
        }
    }

    var upcomingTasks: [MaintenanceTaskDBRow] {
        let cal = Calendar.current
        let thirtyDays = cal.date(byAdding: .day, value: 30, to: .now) ?? .now
        return maintenanceTasks
            .filter { task in
                guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
                return date >= .now && date <= thirtyDays
            }
            .sorted { a, b in a.nextDueDate < b.nextDueDate }
    }

    var totalServiceCost: Double {
        serviceRecords.compactMap(\.cost).reduce(0, +)
    }

    var activeWarranties: [WarrantyRow] {
        warranties.filter { w in
            guard let end = dateFormatter.date(from: w.endDate) else { return false }
            return end > .now
        }
    }

    func systemName(for systemId: UUID?) -> String? {
        guard let id = systemId else { return nil }
        return systems.first { $0.id == id }?.name
    }

    /// Contractors assigned to systems on this property
    var assignedContractors: [(ContractorRow, [String])] {
        let contractorIds = Set(systems.compactMap(\.preferredContractorId))
        return contractors
            .filter { contractorIds.contains($0.id) }
            .map { contractor in
                let systemNames = systems
                    .filter { $0.preferredContractorId == contractor.id }
                    .map(\.name)
                return (contractor, systemNames)
            }
    }

    /// Common property documents that are missing
    var missingPropertyDocTypes: [(String, String)] {
        let existingCategories = Set(linkedDocuments.map(\.category))
        var missing: [(String, String)] = []
        if !existingCategories.contains("Deed") {
            missing.append(("Deed", "Add your deed"))
        }
        if !existingCategories.contains("Homeowners Insurance") {
            missing.append(("Homeowners Insurance", "Add your homeowners insurance"))
        }
        if !existingCategories.contains("Mortgage") {
            missing.append(("Mortgage", "Add your mortgage"))
        }
        if !existingCategories.contains("Title Insurance") {
            missing.append(("Title Insurance", "Add your title insurance"))
        }
        return missing
    }

    // MARK: - Vendor Helpers

    func vendorName(for systemId: UUID?) -> String? {
        guard let systemId,
              let system = systems.first(where: { $0.id == systemId }),
              let contractorId = system.preferredContractorId else { return nil }
        return contractors.first(where: { $0.id == contractorId })?.companyName
    }

    func vendorPhone(for systemId: UUID?) -> String? {
        guard let systemId,
              let system = systems.first(where: { $0.id == systemId }),
              let contractorId = system.preferredContractorId else { return nil }
        return contractors.first(where: { $0.id == contractorId })?.phone
    }

    func vendorEmail(for systemId: UUID?) -> String? {
        guard let systemId,
              let system = systems.first(where: { $0.id == systemId }),
              let contractorId = system.preferredContractorId else { return nil }
        return contractors.first(where: { $0.id == contractorId })?.email
    }

    // MARK: - Task Actions

    func snoozeTask(_ task: MaintenanceTaskDBRow, days: Int) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let newDate = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        do {
            _ = try await db.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(nextDueDate: formatter.string(from: newDate))
            )
            Haptics.success()
            guard let prop = property else { return }
            await loadProperty(id: prop.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func setReminder(for task: MaintenanceTaskDBRow?, option: String) async {
        guard let task else { return }
        let calendar = Calendar.current
        let reminderDate: Date
        switch option {
        case "Tomorrow": reminderDate = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        case "In 3 Days": reminderDate = calendar.date(byAdding: .day, value: 3, to: .now) ?? .now
        case "Next Week": reminderDate = calendar.date(byAdding: .weekOfYear, value: 1, to: .now) ?? .now
        case "Next Month": reminderDate = calendar.date(byAdding: .month, value: 1, to: .now) ?? .now
        default: reminderDate = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        }
        let content = UNMutableNotificationContent()
        content.title = "Maintenance Reminder"
        content.body = "\(task.title) needs attention."
        content.sound = .default
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "task-\(task.id.uuidString)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
        Haptics.success()
    }

    // MARK: - Seasonal

    var currentSeason: String {
        let month = Calendar.current.component(.month, from: .now)
        switch month {
        case 3...5: return "Spring"
        case 6...8: return "Summer"
        case 9...11: return "Fall"
        default: return "Winter"
        }
    }

    var nextSeason: String {
        switch currentSeason {
        case "Spring": return "Summer"
        case "Summer": return "Fall"
        case "Fall": return "Winter"
        default: return "Spring"
        }
    }

    var currentSeasonTasks: [MaintenanceTaskDBRow] {
        maintenanceTasks.filter { task in
            guard let timing = task.seasonalTiming?.lowercased() else { return false }
            return timing.contains(currentSeason.lowercased())
        }
    }

    var nextSeasonTasks: [MaintenanceTaskDBRow] {
        maintenanceTasks.filter { task in
            guard let timing = task.seasonalTiming?.lowercased() else { return false }
            return timing.contains(nextSeason.lowercased())
        }
    }

    var currentSeasonCompletedCount: Int {
        currentSeasonTasks.filter { $0.lastCompletedDate != nil }.count
    }

    func loadProperty(id: UUID) async {
        isLoading = true
        error = nil
        do {
            property = try await db.fetchProperty(id: id)

            async let systemsTask = db.fetchHomeSystems(propertyId: id)
            async let tasksTask = db.fetchMaintenanceTasks(propertyId: id)
            async let recordsTask = db.fetchServiceRecords(propertyId: id)

            let (sys, tasks, records) = try await (systemsTask, tasksTask, recordsTask)
            systems = sys
            maintenanceTasks = tasks
            serviceRecords = records

            // Fetch warranties for all systems
            var allWarranties: [WarrantyRow] = []
            for system in sys {
                let sysWarranties = try await db.fetchWarranties(systemId: system.id)
                allWarranties.append(contentsOf: sysWarranties)
            }
            warranties = allWarranties

            // Fetch linked documents
            linkedDocuments = try await db.fetchDocuments()
                .filter { $0.propertyId == id }

            // Fetch contractors
            contractors = try await db.fetchContractors()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteSystem(_ system: HomeSystemRow) async {
        do {
            try await db.deleteHomeSystem(id: system.id)
            systems.removeAll { $0.id == system.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func completeMaintenanceTask(_ task: MaintenanceTaskDBRow) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        do {
            // Mark as completed and calculate next due date
            let nextDate = calculateNextDueDate(frequency: task.frequency, from: .now)
            _ = try await db.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(
                    lastCompletedDate: formatter.string(from: .now),
                    nextDueDate: formatter.string(from: nextDate)
                )
            )

            // Update system's last_service_date and next_service_due
            if let systemId = task.systemId {
                let systemTasks = maintenanceTasks.filter { $0.systemId == systemId && $0.id != task.id }
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
            guard let prop = property else { return }
            _ = try await db.createServiceRecord(ServiceRecordInsert(
                propertyId: prop.id,
                householdId: prop.householdId,
                serviceDate: formatter.string(from: .now),
                serviceType: "maintenance",
                description: task.title,
                systemId: task.systemId
            ))

            justCompletedTaskId = task.id
            Haptics.success()

            // Reschedule notifications
            Task { await NotificationScheduler.shared.rescheduleAll() }

            // Clear animation after delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            justCompletedTaskId = nil

            // Reload
            await loadProperty(id: prop.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func calculateNextDueDate(frequency: String, from date: Date) -> Date {
        let cal = Calendar.current
        switch frequency.lowercased() {
        case "monthly": return cal.date(byAdding: .month, value: 1, to: date)!
        case "quarterly": return cal.date(byAdding: .month, value: 3, to: date)!
        case "semi-annually": return cal.date(byAdding: .month, value: 6, to: date)!
        case "annually": return cal.date(byAdding: .year, value: 1, to: date)!
        case "every 2 years": return cal.date(byAdding: .year, value: 2, to: date)!
        case "seasonal": return cal.date(byAdding: .month, value: 3, to: date)!
        default: return cal.date(byAdding: .year, value: 1, to: date)!
        }
    }
}
