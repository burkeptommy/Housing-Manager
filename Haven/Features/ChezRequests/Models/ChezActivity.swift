import Foundation

/// Phase 86B — one Chez-side action on the homeowner's home.
///
/// Powers the "Recent Chez activity" feed on the iOS Dashboard so the
/// homeowner sees the work Chez does on their behalf — scheduled visits,
/// logged service, completed tasks, audited bills — without having to
/// notice that a row in their task list changed state.
///
/// The server (chez-concierge `fetch_activity_feed` action) reads from
/// `chez_workbench_actions` (admin-written audit trail) and denormalizes
/// each row into the shape below:
///
///   {
///     "id": "<uuid>",
///     "verb": "Scheduled a vendor visit",
///     "entity_type": "routine",
///     "entity_id": "<uuid>",
///     "entity_label": "Petro Heating",   // optional
///     "request_id": "<uuid> or null",
///     "occurred_at": "ISO timestamp"
///   }
///
/// Resilient decoder per CLAUDE.md hard rule: every field that originates
/// outside the app is `try?` so one missing key (e.g. server schema drift)
/// can't sink the whole feed.
struct ChezActivityRow: Codable, Identifiable, Hashable {
    let id: UUID
    /// Customer-facing verb: "Scheduled a vendor visit", "Completed this for you".
    let verb: String
    /// Entity type slug — `routine` / `contractor` / `task` / `system` / etc.
    let entityType: String
    let entityId: UUID?
    /// Optional friendly label extracted from the payload server-side.
    let entityLabel: String?
    /// Optional case linkage so tap → opens the case detail thread.
    let requestId: UUID?
    let occurredAt: Date

    init(
        id: UUID,
        verb: String,
        entityType: String,
        entityId: UUID?,
        entityLabel: String?,
        requestId: UUID?,
        occurredAt: Date
    ) {
        self.id = id
        self.verb = verb
        self.entityType = entityType
        self.entityId = entityId
        self.entityLabel = entityLabel
        self.requestId = requestId
        self.occurredAt = occurredAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case verb
        case entityType = "entity_type"
        case entityId = "entity_id"
        case entityLabel = "entity_label"
        case requestId = "request_id"
        case occurredAt = "occurred_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        self.verb = (try? c.decodeIfPresent(String.self, forKey: .verb)) ?? "Took action"
        self.entityType = (try? c.decodeIfPresent(String.self, forKey: .entityType)) ?? "unknown"
        self.entityId = try? c.decodeIfPresent(UUID.self, forKey: .entityId)
        self.entityLabel = try? c.decodeIfPresent(String.self, forKey: .entityLabel)
        self.requestId = try? c.decodeIfPresent(UUID.self, forKey: .requestId)
        if let date = try? c.decodeIfPresent(Date.self, forKey: .occurredAt) {
            self.occurredAt = date
        } else if let iso = try? c.decodeIfPresent(String.self, forKey: .occurredAt),
                  let parsed = ISO8601DateFormatter().date(from: iso) {
            self.occurredAt = parsed
        } else {
            self.occurredAt = Date.distantPast
        }
    }

    /// SF Symbol icon mapped from entity type. Keep aligned with other
    /// Chez surfaces — entities are color-coded indigo across the app.
    var iconName: String {
        switch entityType {
        case "routine":    return "arrow.triangle.2.circlepath"
        case "contractor": return "person.crop.square"
        case "task":       return "checkmark.circle"
        case "system":     return "house.fill"
        case "project":    return "hammer"
        case "document":   return "doc.text"
        case "utility":    return "bolt"
        case "insurance":  return "shield"
        case "vehicle":    return "car.fill"
        default:           return "sparkles"
        }
    }

    /// Render-ready label: "Scheduled a vendor visit: Petro Heating".
    var displayLabel: String {
        guard let label = entityLabel, !label.isEmpty else { return verb }
        return "\(verb): \(label)"
    }
}
