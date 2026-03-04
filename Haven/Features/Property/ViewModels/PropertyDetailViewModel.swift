import SwiftUI

@MainActor
final class PropertyDetailViewModel: ObservableObject {
    @Published var property: PropertyRow?
    @Published var systems: [HomeSystemRow] = []
    @Published var maintenanceTasks: [MaintenanceTaskDBRow] = []
    @Published var warranties: [WarrantyRow] = []
    @Published var serviceRecords: [ServiceRecordRow] = []
    @Published var linkedDocuments: [DocumentRow] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = DatabaseService.shared

    var systemsByCategory: [(String, [HomeSystemRow])] {
        let groups = Dictionary(grouping: systems) { $0.category }
        return groups.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    var overdueTasks: [MaintenanceTaskDBRow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return maintenanceTasks.filter { task in
            guard let date = formatter.date(from: task.nextDueDate) else { return false }
            return date < .now
        }
    }

    var activeWarranties: [WarrantyRow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return warranties.filter { w in
            guard let end = formatter.date(from: w.endDate) else { return false }
            return end > .now
        }
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
