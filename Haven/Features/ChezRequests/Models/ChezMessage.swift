import Foundation

/// Phase 80 — Per-request thread message. Stored in the existing
/// `concierge_messages` table, extended with `request_id` + `attachments`.

enum ChezMessageRole: String, Codable {
    case user        // homeowner-authored
    case concierge   // Tom-authored
    case system      // status changes ("Tom marked this resolved")
}

/// Attachment metadata serialized into `concierge_messages.attachments` JSONB.
/// Files live in the existing `documents` storage bucket; the path is the
/// full storage key. Both sides resolve to a signed URL via the standard
/// document-view helpers.
struct ChezAttachmentMeta: Codable, Hashable {
    let path: String
    let filename: String
    let mimeType: String
    let sizeBytes: Int
    let uploadedAt: Date

    enum CodingKeys: String, CodingKey {
        case path, filename
        case mimeType = "mime_type"
        case sizeBytes = "size_bytes"
        case uploadedAt = "uploaded_at"
    }

    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }
}

struct ChezMessageRow: Codable, Identifiable, Hashable {
    let id: UUID
    let requestId: UUID?
    let householdId: UUID
    let userId: UUID
    let role: String
    let content: String
    let attachments: [ChezAttachmentMeta]
    let readAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, role, content, attachments
        case requestId = "request_id"
        case householdId = "household_id"
        case userId = "user_id"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        requestId = (try? c.decodeIfPresent(UUID.self, forKey: .requestId)) ?? nil
        householdId = try c.decode(UUID.self, forKey: .householdId)
        userId = try c.decode(UUID.self, forKey: .userId)
        role = (try? c.decodeIfPresent(String.self, forKey: .role)) ?? "user"
        content = (try? c.decodeIfPresent(String.self, forKey: .content)) ?? ""
        attachments = (try? c.decodeIfPresent([ChezAttachmentMeta].self, forKey: .attachments)) ?? []
        readAt = (try? c.decodeIfPresent(Date.self, forKey: .readAt)) ?? nil
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
    }

    var typedRole: ChezMessageRole {
        ChezMessageRole(rawValue: role) ?? .user
    }
}
