import Foundation

/// Phase 54B: Handyman punch list item. Accumulating list of small items
/// the homeowner wants their handyman to handle on the next visit.
///
/// `source` values:
/// - "manual"           — added directly from `HandymanPunchListView`
/// - "recommended"      — added from "Recommended for your home" (Phase 54C)
/// - "maintenance_task" — delegated from a maintenance task via the
///                        "Add to handyman list" action on the task card
struct HandymanPunchItemRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let propertyId: UUID?
    let title: String
    let description: String?
    let source: String
    let sourceTaskId: UUID?
    let addedByUserId: UUID?
    let estimatedMinutes: Int?
    let estimatedCostRange: String?
    let notes: String?
    let createdAt: Date
    let completedAt: Date?
    let completedVisitTaskId: UUID?
    let archivedAt: Date?
    /// Phase 64 unification: direct FK to the maintenance_tasks row this
    /// punch item mirrors. When `assigned_route = 'handyman'` on the
    /// task, a row with `maintenance_task_id` set is present. Kept
    /// alongside `sourceTaskId` (legacy from 54B); the migration
    /// backfills this from sourceTaskId for existing rows.
    let maintenanceTaskId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, title, description, source, notes
        case householdId = "household_id"
        case propertyId = "property_id"
        case sourceTaskId = "source_task_id"
        case addedByUserId = "added_by_user_id"
        case estimatedMinutes = "estimated_minutes"
        case estimatedCostRange = "estimated_cost_range"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case completedVisitTaskId = "completed_visit_task_id"
        case archivedAt = "archived_at"
        case maintenanceTaskId = "maintenance_task_id"
    }

    /// Pending = not yet folded into a visit and not archived.
    var isPending: Bool {
        completedAt == nil && archivedAt == nil
    }
}

struct HandymanPunchItemInsert: Codable {
    let householdId: UUID
    let propertyId: UUID?
    let title: String
    var description: String? = nil
    var source: String = "manual"
    var sourceTaskId: UUID? = nil
    var addedByUserId: UUID? = nil
    var estimatedMinutes: Int? = nil
    var estimatedCostRange: String? = nil
    var notes: String? = nil
    /// Phase 64: FK to maintenance_tasks row. When inserting a punch
    /// item from a route=handyman task, set this to the task id so the
    /// punch list + task stay in sync.
    var maintenanceTaskId: UUID? = nil

    enum CodingKeys: String, CodingKey {
        case title, description, source, notes
        case householdId = "household_id"
        case propertyId = "property_id"
        case sourceTaskId = "source_task_id"
        case addedByUserId = "added_by_user_id"
        case estimatedMinutes = "estimated_minutes"
        case estimatedCostRange = "estimated_cost_range"
        case maintenanceTaskId = "maintenance_task_id"
    }
}
