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
    let kind: String           // "vendor" | "date_slot" | "cost" | "quote" | "info_request"
    let status: String         // "pending" | "approved" | "declined" | "countered" | "answered"
    let decidedAt: Date?
    let vendor: ChezProposalVendor?
    let dateSlot: ChezProposalDateSlot?
    let cost: ChezProposalCost?
    let quote: ChezProposalQuote?
    /// Wave 6 — structured info-request fields. Present when
    /// `kind == "info_request"`: Chez asks the homeowner for a few
    /// specifics (a time window, a budget confirmation, a photo) and
    /// the card renders one input per field.
    let infoRequestFields: [ChezInfoRequestField]?
    /// Wave 6 — the homeowner's answers, once sent. Non-nil means the
    /// card renders the quiet answered-summary state.
    let reply: ChezInfoRequestReply?

    enum CodingKeys: String, CodingKey {
        case kind, status, vendor, cost, quote, reply
        case decidedAt = "decided_at"
        case dateSlot = "date_slot"
        case infoRequestFields = "fields"
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
        infoRequestFields = (try? c.decodeIfPresent([ChezInfoRequestField].self, forKey: .infoRequestFields)) ?? nil
        reply = (try? c.decodeIfPresent(ChezInfoRequestReply.self, forKey: .reply)) ?? nil
    }

    /// Wave 6 back-compat change: unknown kinds used to fall back to
    /// `.vendor`, which rendered a broken vendor card with live Approve
    /// buttons. They now fall back to `.unknown`, which renders as plain
    /// message text with a quiet "Update from Chez" caption and no
    /// action buttons — so future proposal kinds degrade gracefully.
    var typedKind: ChezProposalKind {
        ChezProposalKind(rawValue: kind) ?? .unknown
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
    /// Wave 6 — Chez needs a few details from the homeowner.
    case infoRequest = "info_request"
    /// Wave 6 — safe fallback for kinds this build doesn't know about.
    /// Renders content-only, never live decision buttons.
    case unknown
}

enum ChezProposalStatusValue: String, Codable {
    case pending
    case approved
    case declined
    case countered
    /// Wave 6 — terminal state for info_request proposals.
    case answered
}

// MARK: - Wave 6 — info-request field + reply shapes

/// One input Chez asks for inside an info_request proposal. Types:
/// `date_window` / `choice` (single-select chips over `options`),
/// `budget_confirm` (yes/no on `amountCents`), `photo` (upload), and
/// anything else renders as a plain text input (forward compatible).
struct ChezInfoRequestField: Codable, Hashable, Identifiable {
    let id: String
    let type: String?
    let label: String?
    let options: [String]?
    let amountCents: Int?
    let isRequired: Bool

    enum CodingKeys: String, CodingKey {
        case id, type, label, options
        case amountCents = "amount_cents"
        case isRequired = "required"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        type = (try? c.decodeIfPresent(String.self, forKey: .type)) ?? nil
        label = (try? c.decodeIfPresent(String.self, forKey: .label)) ?? nil
        options = (try? c.decodeIfPresent([String].self, forKey: .options)) ?? nil
        amountCents = (try? c.decodeIfPresent(Int.self, forKey: .amountCents)) ?? nil
        isRequired = (try? c.decodeIfPresent(Bool.self, forKey: .isRequired)) ?? false
    }

    var typedFieldType: ChezInfoRequestFieldType? {
        ChezInfoRequestFieldType(rawValue: type ?? "")
    }
}

enum ChezInfoRequestFieldType: String {
    case dateWindow = "date_window"
    case choice
    case budgetConfirm = "budget_confirm"
    case photo
}

/// The homeowner's submitted answers on an info_request proposal.
/// Answer conventions: choice / date_window → the selected option
/// string verbatim; budget_confirm → "yes" | "no"; photo → the uploaded
/// attachment path (empty string when skipped).
struct ChezInfoRequestReply: Codable, Hashable {
    let answers: [String: String]
    let attachments: [ChezAttachmentMeta]
    let answeredAt: Date?

    enum CodingKeys: String, CodingKey {
        case answers, attachments
        case answeredAt = "answered_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        answers = (try? c.decodeIfPresent([String: String].self, forKey: .answers)) ?? [:]
        attachments = (try? c.decodeIfPresent([ChezAttachmentMeta].self, forKey: .attachments)) ?? []
        answeredAt = (try? c.decodeIfPresent(Date.self, forKey: .answeredAt)) ?? nil
    }

    /// Memberwise init for the optimistic local flip after a successful
    /// send (custom init(from:) suppresses the synthesized one).
    init(answers: [String: String], attachments: [ChezAttachmentMeta], answeredAt: Date?) {
        self.answers = answers
        self.attachments = attachments
        self.answeredAt = answeredAt
    }
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
    /// Phase 101 (C1) — fair-market price context from the operator or the
    /// cross-household Chez network. Cents.
    let fairMarketLowCents: Int?
    let fairMarketHighCents: Int?

    enum CodingKeys: String, CodingKey {
        case name, phone, rating, rationale
        case reviewCount = "review_count"
        case estimatedCost = "estimated_cost"
        case estimatedCostRange = "estimated_cost_range"
        case estimatedWindow = "estimated_window"
        case availabilitySlots = "availability_slots"
        case fairMarketLowCents = "fair_market_low_cents"
        case fairMarketHighCents = "fair_market_high_cents"
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
        fairMarketLowCents = (try? c.decodeIfPresent(Int.self, forKey: .fairMarketLowCents)) ?? nil
        fairMarketHighCents = (try? c.decodeIfPresent(Int.self, forKey: .fairMarketHighCents)) ?? nil
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
    /// Phase 101 (C1) — fair-market band in whole dollars.
    let fairMarketLow: Double?
    let fairMarketHigh: Double?
    /// Phase 101 (C2) — the other quotes Chez gathered, so the homeowner
    /// sees the comparison inside one card.
    let alternatives: [ChezQuoteAlternative]?

    enum CodingKeys: String, CodingKey {
        case total, alternatives
        case vendorName = "vendor_name"
        case validUntil = "valid_until"
        case fairMarketLow = "fair_market_low"
        case fairMarketHigh = "fair_market_high"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vendorName = (try? c.decodeIfPresent(String.self, forKey: .vendorName)) ?? nil
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? nil
        validUntil = (try? c.decodeIfPresent(String.self, forKey: .validUntil)) ?? nil
        fairMarketLow = (try? c.decodeIfPresent(Double.self, forKey: .fairMarketLow)) ?? nil
        fairMarketHigh = (try? c.decodeIfPresent(Double.self, forKey: .fairMarketHigh)) ?? nil
        alternatives = (try? c.decodeIfPresent([ChezQuoteAlternative].self, forKey: .alternatives)) ?? nil
    }
}

struct ChezQuoteAlternative: Codable, Hashable {
    let vendorName: String?
    let total: Double?

    enum CodingKeys: String, CodingKey {
        case total
        case vendorName = "vendor_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vendorName = (try? c.decodeIfPresent(String.self, forKey: .vendorName)) ?? nil
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? nil
    }
}
