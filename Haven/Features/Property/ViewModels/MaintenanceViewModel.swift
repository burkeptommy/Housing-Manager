import SwiftUI

@MainActor
final class MaintenanceViewModel: ObservableObject {
    @Published var tasks: [MaintenanceTaskDBRow] = []
    @Published var properties: [PropertyRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var filterPropertyId: UUID?
    @Published var showOverdueOnly = false

    private let db = DatabaseService.shared

    var filteredTasks: [MaintenanceTaskDBRow] {
        tasks.filter { task in
            let matchesProperty = filterPropertyId == nil || task.propertyId == filterPropertyId
            if showOverdueOnly {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                guard let date = formatter.date(from: task.nextDueDate) else { return false }
                return matchesProperty && date < .now
            }
            return matchesProperty
        }
    }

    var overdueCount: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return tasks.filter { task in
            guard let date = formatter.date(from: task.nextDueDate) else { return false }
            return date < .now
        }.count
    }

    func loadTasks() async {
        isLoading = true
        do {
            async let tasksResult = db.fetchMaintenanceTasks()
            async let propsResult = db.fetchProperties()
            let (t, p) = try await (tasksResult, propsResult)
            tasks = t
            properties = p
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func propertyName(for id: UUID) -> String {
        properties.first { $0.id == id }?.name ?? "Unknown"
    }

    func completeTask(_ task: MaintenanceTaskDBRow) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nextDate = calculateNextDueDate(frequency: task.frequency, from: .now)
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
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
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
