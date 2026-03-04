import Foundation

struct MaintenanceTask: Identifiable, Codable {
    let id: UUID
    var systemId: UUID
    var propertyId: UUID
    var title: String
    var description: String?
    var frequency: MaintenanceFrequency
    var lastCompletedDate: Date?
    var nextDueDate: Date
    var estimatedCost: Decimal?
    var priority: TaskPriority
    var assignedContractorId: UUID?
    var notes: String?

    var isOverdue: Bool { Date() > nextDueDate }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
    }
}

enum MaintenanceFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnually = "Semi-Annually"
    case annually = "Annually"
    case biAnnually = "Every 2 Years"
    case asNeeded = "As Needed"
    case seasonal = "Seasonal"
}

enum TaskPriority: String, Codable, CaseIterable {
    case urgent = "Urgent"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}
