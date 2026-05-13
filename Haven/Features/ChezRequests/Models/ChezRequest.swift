import Foundation
import SwiftUI

/// Phase 80 — Chez Concierge.
///
/// A homeowner-submitted request to Chez (the concierge service).
/// All user-facing copy refers to "Chez" — the homeowner never sees a
/// real human's name on the front-end, even though the admin portal
/// is operated by Tom. This keeps the brand consistent and lets the
/// service scale beyond a single operator without copy churn.
/// Categories cover the main "I need help with this" surfaces in the app
/// (find a vendor / get a quote / schedule a visit / coordinate a task /
/// find a handyman / general). Status is the lifecycle from submission
/// through resolution. The 24-hr SLA is computed business-hours-aware
/// server-side and rendered as a visual badge in the admin portal.

enum ChezCategory: String, Codable, CaseIterable, Identifiable {
    case findVendor = "find_vendor"
    case getQuote = "get_quote"
    case scheduleVisit = "schedule_visit"
    case coordinateTask = "coordinate_task"
    case findHandyman = "find_handyman"
    case general = "general"

    var id: String { rawValue }

    /// Plain-English label shown in the composer + detail header.
    var displayName: String {
        switch self {
        case .findVendor: return "Find a vendor"
        case .getQuote: return "Get a quote"
        case .scheduleVisit: return "Schedule a visit"
        case .coordinateTask: return "Coordinate a task"
        case .findHandyman: return "Find a handyman"
        case .general: return "General help"
        }
    }

    /// SF Symbol used on category chips and inbox rows.
    var iconName: String {
        switch self {
        case .findVendor: return "magnifyingglass.circle.fill"
        case .getQuote: return "doc.text.magnifyingglass"
        case .scheduleVisit: return "calendar.badge.plus"
        case .coordinateTask: return "checkmark.circle.fill"
        case .findHandyman: return "wrench.and.screwdriver.fill"
        case .general: return "bubble.left.and.bubble.right.fill"
        }
    }

    /// Shown under the title on the composer to set expectations.
    var promptCaption: String {
        switch self {
        case .findVendor:
            return "Tell us what you're looking for and any preferences. Chez researches vetted local options and replies with a few picks."
        case .getQuote:
            return "Share what you need quoted (and any quotes you've received). Chez gathers competitive numbers and a fair-market read."
        case .scheduleVisit:
            return "Tell us what's needed and your preferred timing. Chez coordinates with the right pro and proposes options."
        case .coordinateTask:
            return "Hand off the back-and-forth. Chez works with the vendor or pro on your behalf."
        case .findHandyman:
            return "Tell us what's on your punch list. Chez finds a handyman and books the visit."
        case .general:
            return "Anything else on your mind. Chez figures out the right next step."
        }
    }
}

enum ChezStatus: String, Codable {
    case open
    case waitingCustomer = "waiting_customer"
    case resolved

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .waitingCustomer: return "Waiting on you"
        case .resolved: return "Resolved"
        }
    }
}

/// Read-side row from `chez_requests`. Resilient decoding per CLAUDE.md.
///
/// Not Hashable — context is a JSON-shaped dictionary that can't conform.
/// SwiftUI ForEach uses Identifiable, which is fine.
struct ChezRequestRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    let category: String  // ChezCategory raw — keep as string so unknown values decode
    let summary: String
    /// Stored as a `[String: String]` — we lose number/bool fidelity but
    /// the iOS side only renders the context as a pretty-printed key/value
    /// list ("Re: Furnace, Carrier 58STA"). Server-side stays JSONB.
    let context: [String: String]?
    let status: String
    let slaDueAt: Date
    let lastMessageAt: Date
    let unreadForUser: Bool
    let unreadForAdmin: Bool
    let resolvedAt: Date?
    let createdAt: Date
    let updatedAt: Date?
    /// Phase 86E.3 — when the operator merges a stray duplicate case
    /// into this one's "twin", the duplicate row gets this column
    /// pointed at the surviving case. iOS shows a "merged into…" banner
    /// + tap-to-jump so the homeowner doesn't get a 404 if they have a
    /// link bookmarked to the old conversation.
    let mergedIntoRequestId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, category, summary, context, status
        case householdId = "household_id"
        case userId = "user_id"
        case slaDueAt = "sla_due_at"
        case lastMessageAt = "last_message_at"
        case unreadForUser = "unread_for_user"
        case unreadForAdmin = "unread_for_admin"
        case resolvedAt = "resolved_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case mergedIntoRequestId = "merged_into_request_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        userId = try c.decode(UUID.self, forKey: .userId)
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? "general"
        summary = (try? c.decodeIfPresent(String.self, forKey: .summary)) ?? "(no summary)"
        // Context comes back as a JSONB object. Edge Function writes
        // string values exclusively (iOS only displays them), so we
        // decode directly as [String: String] without the FlexibleValue
        // indirection. If a non-string value sneaks in, the whole
        // dictionary decode fails and we fall back to nil — graceful.
        context = (try? c.decodeIfPresent([String: String].self, forKey: .context)) ?? nil
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "open"
        slaDueAt = (try? c.decodeIfPresent(Date.self, forKey: .slaDueAt)) ?? Date()
        lastMessageAt = (try? c.decodeIfPresent(Date.self, forKey: .lastMessageAt)) ?? Date()
        unreadForUser = (try? c.decodeIfPresent(Bool.self, forKey: .unreadForUser)) ?? false
        unreadForAdmin = (try? c.decodeIfPresent(Bool.self, forKey: .unreadForAdmin)) ?? false
        resolvedAt = (try? c.decodeIfPresent(Date.self, forKey: .resolvedAt)) ?? nil
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        updatedAt = (try? c.decodeIfPresent(Date.self, forKey: .updatedAt)) ?? nil
        mergedIntoRequestId = (try? c.decodeIfPresent(UUID.self, forKey: .mergedIntoRequestId)) ?? nil
    }

    /// Encode context back as a dict of strings — sufficient for any
    /// places we re-serialize (test fixtures, etc.).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(householdId, forKey: .householdId)
        try c.encode(userId, forKey: .userId)
        try c.encode(category, forKey: .category)
        try c.encode(summary, forKey: .summary)
        try c.encodeIfPresent(context, forKey: .context)
        try c.encode(status, forKey: .status)
        try c.encode(slaDueAt, forKey: .slaDueAt)
        try c.encode(lastMessageAt, forKey: .lastMessageAt)
        try c.encode(unreadForUser, forKey: .unreadForUser)
        try c.encode(unreadForAdmin, forKey: .unreadForAdmin)
        try c.encodeIfPresent(resolvedAt, forKey: .resolvedAt)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(mergedIntoRequestId, forKey: .mergedIntoRequestId)
    }

    var typedCategory: ChezCategory {
        ChezCategory(rawValue: category) ?? .general
    }

    var typedStatus: ChezStatus {
        ChezStatus(rawValue: status) ?? .open
    }

    /// Friendly relative-time caption for the SLA, from the homeowner's
    /// point of view. Chez replies within 1 business day.
    var homeownerSlaCaption: String {
        if typedStatus == .resolved {
            if let resolvedAt {
                return "Resolved \(Self.relativeFormatter.localizedString(for: resolvedAt, relativeTo: Date()))"
            }
            return "Resolved"
        }
        if typedStatus == .waitingCustomer {
            return "Chez needs your answer"
        }
        let now = Date()
        if slaDueAt < now {
            return "Chez is on it"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let cal = Calendar.current
        if cal.isDateInToday(slaDueAt) {
            return "Chez replies by \(formatter.string(from: slaDueAt)) today"
        }
        if cal.isDateInTomorrow(slaDueAt) {
            return "Chez replies by \(formatter.string(from: slaDueAt)) tomorrow"
        }
        let dayFormatter = DateFormatter()
        dayFormatter.dateStyle = .medium
        return "Chez replies by \(dayFormatter.string(from: slaDueAt))"
    }

    static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()
}

/// Insert payload for the `submit` Edge Function action. The mirror
/// pattern from `DelegateTaskRequest` etc. in `SupabaseClient.swift`:
/// constant `action` field, the rest are the user-facing fields.
struct ChezRequestSubmitPayload: Encodable {
    let action = "submit"
    let category: String
    let summary: String
    let description: String
    let context: [String: String]?
    let attachments: [ChezAttachmentMeta]?
}

/// Reply payload — homeowner OR admin (admin path goes through the
/// admin portal, not the iOS app, so this is homeowner-only on iOS).
struct ChezRequestReplyPayload: Encodable {
    let action = "reply"
    let requestId: String
    let content: String
    let attachments: [ChezAttachmentMeta]?

    enum CodingKeys: String, CodingKey {
        case action, content, attachments
        case requestId = "request_id"
    }
}

/// mark_read payload — clears unread flag for the caller's side.
struct ChezRequestMarkReadPayload: Encodable {
    let action = "mark_read"
    let requestId: String

    enum CodingKeys: String, CodingKey {
        case action
        case requestId = "request_id"
    }
}

/// Reopen-from-resolved payload (homeowner can transition resolved → open).
struct ChezRequestReopenPayload: Encodable {
    let action = "transition_status"
    let requestId: String
    let toStatus: String = "open"

    enum CodingKeys: String, CodingKey {
        case action
        case requestId = "request_id"
        case toStatus = "to_status"
    }
}
