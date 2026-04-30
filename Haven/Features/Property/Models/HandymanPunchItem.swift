import Foundation

/// Phase 54B: Handyman punch list item. Accumulating list of small items
/// the homeowner wants their handyman to handle on the next visit.
///
/// `source` values:
/// - "manual"                   — added directly from `HandymanPunchListView`
/// - "recommended"              — added from "Recommended for your home" (Phase 54C)
/// - "maintenance_task"         — legacy delegation from a task (pre-Phase 67E/F)
/// - "promoted_from_task"       — Phase 67E/F: replaces "maintenance_task"
///                                for new Add-to-punch-list actions in
///                                MaintenanceTaskDetailSheet
/// - "auto_seed_handyman_tier"  — Phase 67E/F: seeded directly by the
///                                reconciler when a template is handyman-
///                                tier (DIY-capable, ≤60 min, no safety
///                                floor, no bundleId)
/// - "migrated_from_task"       — Phase 67E/F: created by the one-time
///                                migration that converts pre-67E/F
///                                handyman-tier maintenance_tasks rows
///                                into punch items
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
    // MARK: - Phase 78 — proposal + visit-assignment fields
    /// The handyman visit this item is currently bundled into, before
    /// completion. Replaces the old "freeze into notes" handoff.
    let assignedVisitTaskId: UUID?
    /// When the homeowner converted a maintenance_task into this punch
    /// item via "Have my handyman do this →", this is the source task id.
    let delegatedFromTaskId: UUID?
    /// Optional FK to a `home_systems` row. Drives system-link chips and
    /// the trigger that bumps `home_systems.last_service_date` on done.
    let systemId: UUID?
    /// Frozen system label snapshot (lets archived/renamed systems still
    /// render a readable label like "Linked: Boiler").
    let systemLabelSnapshot: String?
    let templateId: UUID?
    /// Phase 67E/F: in-app `MaintenanceTemplate.templateKey` that seeded
    /// or migrated this row (e.g. "Plumbing:Test sump pump battery
    /// backup"). Used by the reconciler to dedupe handyman-tier templates
    /// across reruns so the same template never lands twice. Distinct
    /// from `templateId` (which is a UUID FK to `task_proposals` from
    /// Phase 78); kept as a separate text column so legacy paths don't
    /// have to load this string.
    let sourceTemplateKey: String?
    /// Lifecycle status. Distinct from completed_at/archived_at —
    /// "pending" / "assigned" / "in_progress" / "done" / "cancelled".
    let status: String?
    let priority: String?
    let materialRequired: Bool?
    let costBasis: String?
    /// True when the homeowner added this AFTER the handyman accepted
    /// the visit. Surfaces a "needs handyman confirmation" badge.
    let addedAfterLock: Bool?
    let proposedByUserId: UUID?
    let proposedByRole: String?
    let proposedAt: Date?
    let proposalMessage: String?
    let proposalStatus: String?
    let proposalExpiresAt: Date?
    let acceptedByUserId: UUID?
    let acceptedAt: Date?
    let declinedByUserId: UUID?
    let declinedAt: Date?
    let declinedReason: String?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, source, notes, status, priority
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
        case assignedVisitTaskId = "assigned_visit_task_id"
        case delegatedFromTaskId = "delegated_from_task_id"
        case systemId = "system_id"
        case systemLabelSnapshot = "system_label_snapshot"
        case templateId = "template_id"
        case sourceTemplateKey = "source_template_key"
        case materialRequired = "material_required"
        case costBasis = "cost_basis"
        case addedAfterLock = "added_after_lock"
        case proposedByUserId = "proposed_by_user_id"
        case proposedByRole = "proposed_by_role"
        case proposedAt = "proposed_at"
        case proposalMessage = "proposal_message"
        case proposalStatus = "proposal_status"
        case proposalExpiresAt = "proposal_expires_at"
        case acceptedByUserId = "accepted_by_user_id"
        case acceptedAt = "accepted_at"
        case declinedByUserId = "declined_by_user_id"
        case declinedAt = "declined_at"
        case declinedReason = "declined_reason"
        case updatedAt = "updated_at"
    }

    /// Resilient decoder per CLAUDE.md "every externally-fed struct"
    /// rule. Required fields (id, householdId, title, source, createdAt)
    /// stay strict; everything else degrades gracefully.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        title = try c.decode(String.self, forKey: .title)
        source = (try? c.decodeIfPresent(String.self, forKey: .source)) ?? "manual"
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        propertyId = (try? c.decodeIfPresent(UUID.self, forKey: .propertyId)) ?? nil
        description = (try? c.decodeIfPresent(String.self, forKey: .description)) ?? nil
        sourceTaskId = (try? c.decodeIfPresent(UUID.self, forKey: .sourceTaskId)) ?? nil
        addedByUserId = (try? c.decodeIfPresent(UUID.self, forKey: .addedByUserId)) ?? nil
        estimatedMinutes = (try? c.decodeIfPresent(Int.self, forKey: .estimatedMinutes)) ?? nil
        estimatedCostRange = (try? c.decodeIfPresent(String.self, forKey: .estimatedCostRange)) ?? nil
        notes = (try? c.decodeIfPresent(String.self, forKey: .notes)) ?? nil
        completedAt = (try? c.decodeIfPresent(Date.self, forKey: .completedAt)) ?? nil
        completedVisitTaskId = (try? c.decodeIfPresent(UUID.self, forKey: .completedVisitTaskId)) ?? nil
        archivedAt = (try? c.decodeIfPresent(Date.self, forKey: .archivedAt)) ?? nil
        maintenanceTaskId = (try? c.decodeIfPresent(UUID.self, forKey: .maintenanceTaskId)) ?? nil
        assignedVisitTaskId = (try? c.decodeIfPresent(UUID.self, forKey: .assignedVisitTaskId)) ?? nil
        delegatedFromTaskId = (try? c.decodeIfPresent(UUID.self, forKey: .delegatedFromTaskId)) ?? nil
        systemId = (try? c.decodeIfPresent(UUID.self, forKey: .systemId)) ?? nil
        systemLabelSnapshot = (try? c.decodeIfPresent(String.self, forKey: .systemLabelSnapshot)) ?? nil
        templateId = (try? c.decodeIfPresent(UUID.self, forKey: .templateId)) ?? nil
        sourceTemplateKey = (try? c.decodeIfPresent(String.self, forKey: .sourceTemplateKey)) ?? nil
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? nil
        priority = (try? c.decodeIfPresent(String.self, forKey: .priority)) ?? nil
        materialRequired = (try? c.decodeIfPresent(Bool.self, forKey: .materialRequired)) ?? nil
        costBasis = (try? c.decodeIfPresent(String.self, forKey: .costBasis)) ?? nil
        addedAfterLock = (try? c.decodeIfPresent(Bool.self, forKey: .addedAfterLock)) ?? nil
        proposedByUserId = (try? c.decodeIfPresent(UUID.self, forKey: .proposedByUserId)) ?? nil
        proposedByRole = (try? c.decodeIfPresent(String.self, forKey: .proposedByRole)) ?? nil
        proposedAt = (try? c.decodeIfPresent(Date.self, forKey: .proposedAt)) ?? nil
        proposalMessage = (try? c.decodeIfPresent(String.self, forKey: .proposalMessage)) ?? nil
        proposalStatus = (try? c.decodeIfPresent(String.self, forKey: .proposalStatus)) ?? nil
        proposalExpiresAt = (try? c.decodeIfPresent(Date.self, forKey: .proposalExpiresAt)) ?? nil
        acceptedByUserId = (try? c.decodeIfPresent(UUID.self, forKey: .acceptedByUserId)) ?? nil
        acceptedAt = (try? c.decodeIfPresent(Date.self, forKey: .acceptedAt)) ?? nil
        declinedByUserId = (try? c.decodeIfPresent(UUID.self, forKey: .declinedByUserId)) ?? nil
        declinedAt = (try? c.decodeIfPresent(Date.self, forKey: .declinedAt)) ?? nil
        declinedReason = (try? c.decodeIfPresent(String.self, forKey: .declinedReason)) ?? nil
        updatedAt = (try? c.decodeIfPresent(Date.self, forKey: .updatedAt)) ?? nil
    }

    /// Pending = not yet folded into a visit and not archived.
    var isPending: Bool {
        completedAt == nil && archivedAt == nil
    }

    /// Done resolves to true when status='done' OR completedAt is set.
    /// Bridges Phase 78 status enum with the legacy completion timestamp.
    var isDone: Bool {
        if let s = status, s == "done" { return true }
        return completedAt != nil
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
    /// Phase 67E/F: in-app `MaintenanceTemplate.templateKey` that seeded
    /// this row. Set on `auto_seed_handyman_tier` /
    /// `migrated_from_task` / `promoted_from_task` paths so the
    /// reconciler can dedupe across runs.
    var sourceTemplateKey: String? = nil

    enum CodingKeys: String, CodingKey {
        case title, description, source, notes
        case householdId = "household_id"
        case propertyId = "property_id"
        case sourceTaskId = "source_task_id"
        case addedByUserId = "added_by_user_id"
        case estimatedMinutes = "estimated_minutes"
        case estimatedCostRange = "estimated_cost_range"
        case maintenanceTaskId = "maintenance_task_id"
        case sourceTemplateKey = "source_template_key"
    }
}
