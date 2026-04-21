import Foundation

/// Phase 65: Sticky per-category routing preference. Layered on top of
/// Q36's global `vendor_preference_tier` — tier is the baseline, these
/// rows are overrides. A `scope_type = 'category'` row changes the
/// default for all tasks in that category; a `scope_type = 'template'`
/// row overrides a single template without disturbing the category.
struct RoutingPreferenceRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let propertyId: UUID
    let taskCategory: String
    let scopeType: String          // "category" | "template"
    let preferredRoute: String     // "vendor" | "handyman" | "diy"
    let preferredVendorId: UUID?
    let createdAt: Date?
    let updatedAt: Date?
    let lastConfirmedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case propertyId = "property_id"
        case taskCategory = "task_category"
        case scopeType = "scope_type"
        case preferredRoute = "preferred_route"
        case preferredVendorId = "preferred_vendor_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastConfirmedAt = "last_confirmed_at"
    }

    /// Memberwise init restored for test fixtures. Swift's implicit
    /// synthesis is suppressed whenever a type defines its own
    /// `init(from decoder:)`, so we add this explicit version so
    /// HavenTests can build preference rows without going through JSON.
    init(
        id: UUID,
        householdId: UUID,
        propertyId: UUID,
        taskCategory: String,
        scopeType: String,
        preferredRoute: String,
        preferredVendorId: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        lastConfirmedAt: Date? = nil
    ) {
        self.id = id
        self.householdId = householdId
        self.propertyId = propertyId
        self.taskCategory = taskCategory
        self.scopeType = scopeType
        self.preferredRoute = preferredRoute
        self.preferredVendorId = preferredVendorId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastConfirmedAt = lastConfirmedAt
    }

    /// Resilient decoder (CLAUDE.md requirement).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        propertyId = try c.decode(UUID.self, forKey: .propertyId)
        taskCategory = try c.decode(String.self, forKey: .taskCategory)
        scopeType = (try? c.decodeIfPresent(String.self, forKey: .scopeType)) ?? "category"
        preferredRoute = try c.decode(String.self, forKey: .preferredRoute)
        preferredVendorId = try? c.decodeIfPresent(UUID.self, forKey: .preferredVendorId)
        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try? c.decodeIfPresent(Date.self, forKey: .updatedAt)
        lastConfirmedAt = try? c.decodeIfPresent(Date.self, forKey: .lastConfirmedAt)
    }
}

struct RoutingPreferenceInsert: Codable {
    let householdId: UUID
    let propertyId: UUID
    let taskCategory: String
    var scopeType: String = "category"
    let preferredRoute: String
    var preferredVendorId: UUID? = nil

    enum CodingKeys: String, CodingKey {
        case householdId = "household_id"
        case propertyId = "property_id"
        case taskCategory = "task_category"
        case scopeType = "scope_type"
        case preferredRoute = "preferred_route"
        case preferredVendorId = "preferred_vendor_id"
    }
}
