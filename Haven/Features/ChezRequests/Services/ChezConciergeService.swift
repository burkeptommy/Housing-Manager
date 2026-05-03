import Foundation
import Supabase

/// Phase 80 — Chez Concierge service. Wraps the iOS-side reads (direct
/// PostgREST against `chez_requests` + `concierge_messages` with RLS
/// enforcement) and writes (through the `chez-concierge` Edge Function
/// for atomic side effects + push notifications).

extension DatabaseService {

    // MARK: - Reads

    /// Fetch every chez request the homeowner can see (RLS scopes by
    /// household). Newest activity first.
    func fetchChezRequests(householdId: UUID) async throws -> [ChezRequestRow] {
        try await HavenSupabase.from("chez_requests")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("last_message_at", ascending: false)
            .execute()
            .value
    }

    /// Fetch a single request by id.
    func fetchChezRequest(id: UUID) async throws -> ChezRequestRow? {
        let rows: [ChezRequestRow] = try await HavenSupabase.from("chez_requests")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Fetch the message thread for one request, oldest first.
    func fetchChezMessages(requestId: UUID) async throws -> [ChezMessageRow] {
        try await HavenSupabase.from("concierge_messages")
            .select()
            .eq("request_id", value: requestId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }
}

// MARK: - Edge Function wrappers (writes)

extension HavenSupabase {

    /// Submit a new request. Goes through the chez-concierge Edge
    /// Function so the SLA + admin push + admin email all fire
    /// atomically server-side.
    static func submitChezRequest(
        category: ChezCategory,
        summary: String,
        description: String,
        context: [String: String]? = nil,
        attachments: [ChezAttachmentMeta]? = nil
    ) async throws -> ChezRequestRow {
        struct Wrapper: Decodable {
            let request: ChezRequestRow
        }
        let payload = ChezRequestSubmitPayload(
            category: category.rawValue,
            summary: summary,
            description: description,
            context: context,
            attachments: attachments
        )
        let data = try await callConciergeEdgeFunction(body: payload)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .havenISO8601
        let wrapper = try decoder.decode(Wrapper.self, from: data)
        return wrapper.request
    }

    /// Reply to an existing request from the homeowner side.
    static func replyToChezRequest(
        requestId: UUID,
        content: String,
        attachments: [ChezAttachmentMeta]? = nil
    ) async throws {
        let payload = ChezRequestReplyPayload(
            requestId: requestId.uuidString,
            content: content,
            attachments: attachments
        )
        _ = try await callConciergeEdgeFunction(body: payload)
    }

    /// Mark messages as read so the unread badge clears for the user.
    static func markChezRequestRead(requestId: UUID) async throws {
        let payload = ChezRequestMarkReadPayload(requestId: requestId.uuidString)
        _ = try await callConciergeEdgeFunction(body: payload)
    }

    /// Reopen a resolved request (homeowner-initiated). Server sets
    /// status='open' + bumps unread_for_admin.
    static func reopenChezRequest(requestId: UUID) async throws {
        let payload = ChezRequestReopenPayload(requestId: requestId.uuidString)
        _ = try await callConciergeEdgeFunction(body: payload)
    }

    // MARK: - Phase 80.1 — Standing instructions / household profile

    /// Read the household's Chez profile. Returns an empty profile if
    /// nothing is set yet (vs. throwing) so the calling UI shows the
    /// "set up your profile" empty state cleanly.
    static func fetchChezProfile() async throws -> ChezProfile {
        struct Wrapper: Decodable { let profile: ChezProfile? }
        struct Body: Encodable { let action = "fetch_profile" }
        let data = try await callConciergeEdgeFunction(body: Body())
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .havenISO8601
        let wrapper = try decoder.decode(Wrapper.self, from: data)
        return wrapper.profile ?? ChezProfile()
    }

    /// Update the household's Chez profile. Server-side does a deep
    /// merge by default — pass `replace: true` to wipe and replace.
    @discardableResult
    static func updateChezProfile(
        _ profile: ChezProfile,
        replace: Bool = false
    ) async throws -> ChezProfile {
        struct Body: Encodable {
            let action = "update_profile"
            let profile: ChezProfile
            let replace: Bool
        }
        struct Wrapper: Decodable { let profile: ChezProfile? }
        let data = try await callConciergeEdgeFunction(body: Body(profile: profile, replace: replace))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .havenISO8601
        let wrapper = try decoder.decode(Wrapper.self, from: data)
        return wrapper.profile ?? profile
    }

    // MARK: - Phase 80.1 — Recurring delegation

    /// Hand a routine off to Chez (or revoke). Server creates a
    /// "Standing engagement" parent request + system message + push.
    static func delegateRoutineToChez(
        routineId: UUID,
        delegated: Bool,
        notes: String? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "delegate_routine"
            let routine_id: String
            let delegated: Bool
            let notes: String?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(routine_id: routineId.uuidString, delegated: delegated, notes: notes)
        )
    }

    /// Set Chez as the point of contact for a vendor (or revoke).
    static func delegateContractorToChez(
        contractorId: UUID,
        delegated: Bool,
        notes: String? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "delegate_contractor"
            let contractor_id: String
            let delegated: Bool
            let notes: String?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(contractor_id: contractorId.uuidString, delegated: delegated, notes: notes)
        )
    }

    /// Phase 80.2 — Hand a single maintenance task off to Chez (or
    /// revoke). Server-side smart routing: tasks without a vendor get
    /// a `find_vendor` request, tasks with one get `coordinate_task`.
    /// The parent `chez_request_id` is stamped back onto the task so
    /// updates can flow through the conversation thread.
    static func delegateTaskToChez(
        taskId: UUID,
        delegated: Bool,
        notes: String? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "delegate_task"
            let task_id: String
            let delegated: Bool
            let notes: String?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(task_id: taskId.uuidString, delegated: delegated, notes: notes)
        )
    }

    /// Phase 84 — Universal entity-level delegation. One wrapper covers
    /// every new entity type (system, project, document, utility,
    /// vehicle, insurance) via the generic `delegate_entity` Edge
    /// Function action. Insurance carries a `propertyId` because the
    /// flag lives on the parent property, not its own table.
    static func delegateEntityToChez(
        entityType: String,
        entityId: String,
        delegated: Bool,
        notes: String? = nil,
        propertyId: String? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "delegate_entity"
            let entity_type: String
            let entity_id: String
            let delegated: Bool
            let notes: String?
            let property_id: String?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(
                entity_type: entityType,
                entity_id: entityId,
                delegated: delegated,
                notes: notes,
                property_id: propertyId
            )
        )
    }

    /// Phase 84 — Group-level delegation. Flips one of:
    /// `all_routines`, `all_systems`, `all_vendors`, `all_projects`,
    /// `all_bills`, `all_documents`, `all_insurance`, `all_vehicles`.
    /// Server backfills every existing entity in that category +
    /// posts a single summary system message in the chez_request thread.
    static func setChezOwnershipGroup(
        group: String,
        on: Bool,
        notes: String? = nil
    ) async throws -> Int {
        struct Body: Encodable {
            let action = "set_ownership_group"
            let group: String
            let on: Bool
            let notes: String?
        }
        struct Response: Decodable {
            let ok: Bool?
            let backfill_count: Int?
        }
        let data = try await callConciergeEdgeFunction(
            body: Body(group: group, on: on, notes: notes)
        )
        let parsed = (try? JSONDecoder().decode(Response.self, from: data)) ?? Response(ok: nil, backfill_count: nil)
        return parsed.backfill_count ?? 0
    }

    // MARK: - Phase 80.1 — Structured proposal decisions

    /// Approve / decline / counter a structured proposal. `messageId`
    /// is the `concierge_messages.id` of the proposal-bearing message.
    static func decideChezProposal(
        messageId: UUID,
        decision: ChezProposalDecision,
        note: String? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "decide_proposal"
            let message_id: String
            let decision: String
            let note: String?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(
                message_id: messageId.uuidString,
                decision: decision.rawValue,
                note: note
            )
        )
    }

    // MARK: - Internal

    /// Direct fetch to the chez-concierge Edge Function. Mirrors the
    /// pattern in `callEdgeFunction(name:body:)` — bypasses the
    /// supabase-swift `invoke` because that wrapper has historical
    /// parsing issues. Auth header carries the homeowner's JWT so the
    /// server can verify ownership.
    private static func callConciergeEdgeFunction(
        body: Encodable,
        timeoutSeconds: TimeInterval = 30
    ) async throws -> Data {
        let baseURL = AppConfig.Supabase.url
        guard let url = URL(string: "\(baseURL)/functions/v1/chez-concierge") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "apikey")
        if let token = await safeAccessToken(timeout: 3.0) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        }
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if !(200...299).contains(http.statusCode) {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            print("[chez-concierge] \(http.statusCode): \(bodyString.prefix(500))")
            let message: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = json["error"] as? String {
                message = err
            } else {
                message = "Request failed (\(http.statusCode))"
            }
            throw NSError(
                domain: "ChezConcierge",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
        return data
    }
}

// MARK: - Date decoding helper

extension JSONDecoder.DateDecodingStrategy {
    /// Postgres returns ISO-8601 with various fractional-second
    /// precisions; this matches the strategy used elsewhere in
    /// the codebase for resilient decoding.
    static var havenISO8601: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFractional.date(from: raw) { return d }
            let isoPlain = ISO8601DateFormatter()
            isoPlain.formatOptions = [.withInternetDateTime]
            if let d = isoPlain.date(from: raw) { return d }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date format: \(raw)"
            )
        }
    }
}

// MARK: - Phase 80.1 types

enum ChezProposalDecision: String {
    case approved
    case declined
    case countered
}

extension Notification.Name {
    /// Phase 80.1 — Posted whenever the Chez profile changes. Listeners
    /// (composer footer caption, dashboard nudge, settings preview)
    /// reload to reflect the new state.
    static let chezProfileChanged = Notification.Name("chezProfileChanged")

    /// Phase 80.1 — Posted when a routine or contractor is delegated
    /// to (or revoked from) Chez. Listeners refresh badges + the
    /// "Standing engagements" surfaces.
    static let chezDelegationChanged = Notification.Name("chezDelegationChanged")
}
