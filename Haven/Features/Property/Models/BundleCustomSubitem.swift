import Foundation

/// Phase 67H: homeowner-added line item that surfaces in a bundle's
/// "What's included" list at the next (or every) firing.
///
/// `recurrence` semantics:
/// - `"always"` — appended to every future bundle parent task at
///   reconcile time. Persists until the user archives it.
/// - `"once"` — attached to the next bundle parent that fires, then
///   archived when that parent completes. Use case: "ask the chimney
///   sweep about the slow draft this fall" — one-shot reminder.
///
/// `scope_task_id`:
/// - For `"always"` rows: always nil (the row applies to ALL future
///   bundle parents).
/// - For `"once"` rows: nil while queued, set to a specific
///   `maintenance_tasks` row when the reconciler attaches it to the
///   next bundle parent. After that parent completes,
///   `markOnceSubitemsUsed(taskId:)` flips `used_at` + `archived_at`
///   to retire the row.
struct BundleCustomSubitemRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let propertyId: UUID
    let bundleId: String
    let title: String
    let recurrence: String
    let scopeTaskId: UUID?
    let addedByUserId: UUID?
    let addedAt: Date
    let archivedAt: Date?
    let usedAt: Date?
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, recurrence
        case householdId = "household_id"
        case propertyId = "property_id"
        case bundleId = "bundle_id"
        case scopeTaskId = "scope_task_id"
        case addedByUserId = "added_by_user_id"
        case addedAt = "added_at"
        case archivedAt = "archived_at"
        case usedAt = "used_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Resilient decoder per CLAUDE.md "every externally-fed struct"
    /// rule. Required: id / householdId / propertyId / bundleId /
    /// title / recurrence / addedAt / createdAt. Everything else
    /// degrades gracefully so a stale field never takes down the
    /// whole row.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        propertyId = try c.decode(UUID.self, forKey: .propertyId)
        bundleId = try c.decode(String.self, forKey: .bundleId)
        title = try c.decode(String.self, forKey: .title)
        recurrence = (try? c.decodeIfPresent(String.self, forKey: .recurrence)) ?? "always"
        addedAt = (try? c.decodeIfPresent(Date.self, forKey: .addedAt)) ?? Date()
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        scopeTaskId = (try? c.decodeIfPresent(UUID.self, forKey: .scopeTaskId)) ?? nil
        addedByUserId = (try? c.decodeIfPresent(UUID.self, forKey: .addedByUserId)) ?? nil
        archivedAt = (try? c.decodeIfPresent(Date.self, forKey: .archivedAt)) ?? nil
        usedAt = (try? c.decodeIfPresent(Date.self, forKey: .usedAt)) ?? nil
        updatedAt = (try? c.decodeIfPresent(Date.self, forKey: .updatedAt)) ?? nil
    }

    /// True when the row should appear in the next bundle parent
    /// task's notes. Always rows are always pending; once rows are
    /// pending only while waiting for their first bundle fire.
    var isPending: Bool {
        guard archivedAt == nil else { return false }
        if recurrence == "once" {
            return scopeTaskId == nil && usedAt == nil
        }
        return true
    }
}

struct BundleCustomSubitemInsert: Codable {
    let householdId: UUID
    let propertyId: UUID
    let bundleId: String
    let title: String
    var recurrence: String = "always"
    var addedByUserId: UUID? = nil

    enum CodingKeys: String, CodingKey {
        case title, recurrence
        case householdId = "household_id"
        case propertyId = "property_id"
        case bundleId = "bundle_id"
        case addedByUserId = "added_by_user_id"
    }
}
