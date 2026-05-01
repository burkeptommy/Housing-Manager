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
