import Foundation

/// Phase 80 — Per-request thread message. Stored in the existing
/// `concierge_messages` table, extended with `request_id` + `attachments`.

enum ChezMessageRole: String, Codable {
    case user        // homeowner-authored
    case concierge   // Tom-authored
    case system      // status changes ("Chez marked this resolved")
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
    /// Phase 80.1 — Structured proposal payload (vendor / date_slot /
    /// cost / quote variants). When non-nil, the message bubble
    /// renders an inline `ChezProposalCard` with Approve / Counter /
    /// Decline buttons.
    let proposal: ChezProposal?

    enum CodingKeys: String, CodingKey {
        case id, role, content, attachments, proposal
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
        proposal = (try? c.decodeIfPresent(ChezProposal.self, forKey: .proposal)) ?? nil
    }

    var typedRole: ChezMessageRole {
        ChezMessageRole(rawValue: role) ?? .user
    }
}

// MARK: - Phase 80.1 structured proposals

/// A structured proposal Chez sends in the thread. Renders as an
/// inline `ChezProposalCard` with Approve / Counter / Decline actions
/// when the homeowner views it. Server-side this is a JSONB blob on
/// `concierge_messages.proposal`; here it's a typed Codable.
struct ChezProposal: Codable, Hashable {
    let kind: String           // "vendor" | "date_slot" | "cost" | "quote"
    let status: String         // "pending" | "approved" | "declined" | "countered"
    let decidedAt: Date?
    let vendor: ChezProposalVendor?
    let dateSlot: ChezProposalDateSlot?
    let cost: ChezProposalCost?
    let quote: ChezProposalQuote?

    enum CodingKeys: String, CodingKey {
        case kind, status, vendor, cost, quote
        case decidedAt = "decided_at"
        case dateSlot = "date_slot"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = (try? c.decodeIfPresent(String.self, forKey: .kind)) ?? ""
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "pending"
        decidedAt = (try? c.decodeIfPresent(Date.self, forKey: .decidedAt)) ?? nil
        vendor = (try? c.decodeIfPresent(ChezProposalVendor.self, forKey: .vendor)) ?? nil
        dateSlot = (try? c.decodeIfPresent(ChezProposalDateSlot.self, forKey: .dateSlot)) ?? nil
        cost = (try? c.decodeIfPresent(ChezProposalCost.self, forKey: .cost)) ?? nil
        quote = (try? c.decodeIfPresent(ChezProposalQuote.self, forKey: .quote)) ?? nil
    }

    var typedKind: ChezProposalKind {
        ChezProposalKind(rawValue: kind) ?? .vendor
    }

    var typedStatus: ChezProposalStatusValue {
        ChezProposalStatusValue(rawValue: status) ?? .pending
    }

    var isPending: Bool { typedStatus == .pending }
}

enum ChezProposalKind: String, Codable {
    case vendor
    case dateSlot = "date_slot"
    case cost
    case quote
}

enum ChezProposalStatusValue: String, Codable {
    case pending
    case approved
    case declined
    case countered
}

struct ChezProposalVendor: Codable, Hashable {
    let name: String?
    let phone: String?
    let rating: Double?
    let reviewCount: Int?
    let estimatedCost: Double?
    /// Phase 81.2 — When the admin picked a range from the cost
    /// combobox ("$1,000–2,500", "Will quote on site visit"), the
    /// homeowner sees the verbatim range string instead of a fake-
    /// precise dollar amount. Falls back to estimatedCost if absent.
    let estimatedCostRange: String?
    let estimatedWindow: String?
    /// Phase 81.2 — Multi-slot availability ("Tue PM", "Wed AM",
    /// "Fri after 2"). Renders as a bulleted list under "Times
    /// offered" so the homeowner sees every option the vendor gave.
    /// `estimatedWindow` mirrors the first slot for legacy clients.
    let availabilitySlots: [String]?
    let rationale: String?

    enum CodingKeys: String, CodingKey {
        case name, phone, rating, rationale
        case reviewCount = "review_count"
        case estimatedCost = "estimated_cost"
        case estimatedCostRange = "estimated_cost_range"
        case estimatedWindow = "estimated_window"
        case availabilitySlots = "availability_slots"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? nil
        phone = (try? c.decodeIfPresent(String.self, forKey: .phone)) ?? nil
        rating = (try? c.decodeIfPresent(Double.self, forKey: .rating)) ?? nil
        reviewCount = (try? c.decodeIfPresent(Int.self, forKey: .reviewCount)) ?? nil
        estimatedCost = (try? c.decodeIfPresent(Double.self, forKey: .estimatedCost)) ?? nil
        estimatedCostRange = (try? c.decodeIfPresent(String.self, forKey: .estimatedCostRange)) ?? nil
        estimatedWindow = (try? c.decodeIfPresent(String.self, forKey: .estimatedWindow)) ?? nil
        availabilitySlots = (try? c.decodeIfPresent([String].self, forKey: .availabilitySlots)) ?? nil
        rationale = (try? c.decodeIfPresent(String.self, forKey: .rationale)) ?? nil
    }
}

struct ChezProposalDateSlot: Codable, Hashable {
    let options: [ChezProposalDateOption]?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        options = (try? c.decodeIfPresent([ChezProposalDateOption].self, forKey: .options)) ?? nil
    }

    enum CodingKeys: String, CodingKey { case options }
}

struct ChezProposalDateOption: Codable, Hashable {
    let label: String?
    let iso: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = (try? c.decodeIfPresent(String.self, forKey: .label)) ?? nil
        iso = (try? c.decodeIfPresent(String.self, forKey: .iso)) ?? nil
    }

    enum CodingKeys: String, CodingKey { case label, iso }
}

struct ChezProposalCost: Codable, Hashable {
    let amount: Double?
    let currency: String?
    let scope: String?
    let vendorName: String?

    enum CodingKeys: String, CodingKey {
        case amount, currency, scope
        case vendorName = "vendor_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        amount = (try? c.decodeIfPresent(Double.self, forKey: .amount)) ?? nil
        currency = (try? c.decodeIfPresent(String.self, forKey: .currency)) ?? nil
        scope = (try? c.decodeIfPresent(String.self, forKey: .scope)) ?? nil
        vendorName = (try? c.decodeIfPresent(String.self, forKey: .vendorName)) ?? nil
    }
}

struct ChezProposalQuote: Codable, Hashable {
    let vendorName: String?
    let total: Double?
    let validUntil: String?

    enum CodingKeys: String, CodingKey {
        case total
        case vendorName = "vendor_name"
        case validUntil = "valid_until"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vendorName = (try? c.decodeIfPresent(String.self, forKey: .vendorName)) ?? nil
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? nil
        validUntil = (try? c.decodeIfPresent(String.self, forKey: .validUntil)) ?? nil
    }
}
