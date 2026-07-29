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

    /// May 2026 friend feedback Round 3: active find_vendor /
    /// find_handyman requests for use by the vendor-coverage gap list.
    /// When Chez is actively sourcing a vendor for a category, that
    /// category shouldn't render as an "uncovered" gap on the dashboard
    /// or property surface — the homeowner already delegated it and
    /// the Chez hero card communicates the state. Resolved requests
    /// fall out automatically; the gap re-appears so the homeowner
    /// sees the final assignment land.
    func fetchActiveChezVendorRequests(householdId: UUID) async throws -> [ChezRequestRow] {
        try await HavenSupabase.from("chez_requests")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .in("status", values: ["open", "waiting_customer"])
            .in("category", values: ["find_vendor", "find_handyman"])
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

    /// Wave 4 — Fetch the "What Chez already knows" preview for one
    /// entity (or ownership group) before the homeowner delegates it.
    /// `kind` is the contract discriminator (task / routine / contractor /
    /// system / project / vehicle / document / utility / insurance /
    /// property / group / general). Group previews pass `group` (e.g.
    /// "all_routines") instead of `entityId`.
    static func previewChezSnapshot(
        kind: String,
        entityId: String? = nil,
        propertyId: String? = nil,
        group: String? = nil
    ) async throws -> ChezSnapshotPreview {
        struct Body: Encodable {
            let action = "preview_snapshot"
            let kind: String
            let entity_id: String?
            let property_id: String?
            let group: String?
        }
        let data = try await callConciergeEdgeFunction(
            body: Body(kind: kind, entity_id: entityId, property_id: propertyId, group: group)
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .havenISO8601
        return try decoder.decode(ChezSnapshotPreview.self, from: data)
    }

    /// Submit a new request. Goes through the chez-concierge Edge
    /// Function so the SLA + admin push + admin email all fire
    /// atomically server-side. Wave 4: `intake` carries the homeowner's
    /// budget / urgency / windows / access-note answers when provided.
    static func submitChezRequest(
        category: ChezCategory,
        summary: String,
        description: String,
        context: [String: String]? = nil,
        attachments: [ChezAttachmentMeta]? = nil,
        intake: ChezDelegationIntake? = nil
    ) async throws -> ChezRequestRow {
        struct Wrapper: Decodable {
            let request: ChezRequestRow
        }
        let payload = ChezRequestSubmitPayload(
            category: category.rawValue,
            summary: summary,
            description: description,
            context: context,
            attachments: attachments,
            intake: intake
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
        notes: String? = nil,
        intake: ChezDelegationIntake? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "delegate_routine"
            let routine_id: String
            let delegated: Bool
            let notes: String?
            let intake: ChezDelegationIntake?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(routine_id: routineId.uuidString, delegated: delegated, notes: notes, intake: intake)
        )
    }

    /// Set Chez as the point of contact for a vendor (or revoke).
    static func delegateContractorToChez(
        contractorId: UUID,
        delegated: Bool,
        notes: String? = nil,
        intake: ChezDelegationIntake? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "delegate_contractor"
            let contractor_id: String
            let delegated: Bool
            let notes: String?
            let intake: ChezDelegationIntake?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(contractor_id: contractorId.uuidString, delegated: delegated, notes: notes, intake: intake)
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
        notes: String? = nil,
        intake: ChezDelegationIntake? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "delegate_task"
            let task_id: String
            let delegated: Bool
            let notes: String?
            let intake: ChezDelegationIntake?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(task_id: taskId.uuidString, delegated: delegated, notes: notes, intake: intake)
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
        propertyId: String? = nil,
        intake: ChezDelegationIntake? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "delegate_entity"
            let entity_type: String
            let entity_id: String
            let delegated: Bool
            let notes: String?
            let property_id: String?
            let intake: ChezDelegationIntake?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(
                entity_type: entityType,
                entity_id: entityId,
                delegated: delegated,
                notes: notes,
                property_id: propertyId,
                intake: intake
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
        notes: String? = nil,
        intake: ChezDelegationIntake? = nil
    ) async throws -> Int {
        struct Body: Encodable {
            let action = "set_ownership_group"
            let group: String
            let on: Bool
            let notes: String?
            let intake: ChezDelegationIntake?
        }
        struct Response: Decodable {
            let ok: Bool?
            let backfill_count: Int?
        }
        let data = try await callConciergeEdgeFunction(
            body: Body(group: group, on: on, notes: notes, intake: intake)
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

    // MARK: - Wave 6 — Info requests + progress timeline

    /// Answer a structured info_request proposal. `messageId` is the
    /// `concierge_messages.id` of the proposal-bearing message. Server
    /// flips `proposal.status` to "answered", posts a user-role summary
    /// message in the thread, and reopens the request for the operator.
    /// Answer conventions: choice / date_window → the selected option
    /// verbatim; budget_confirm → "yes" | "no"; photo → the uploaded
    /// attachment path (empty string when skipped).
    static func answerChezInfoRequest(
        messageId: UUID,
        answers: [String: String],
        attachments: [ChezAttachmentMeta]? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "answer_info_request"
            let message_id: String
            let answers: [String: String]
            let attachments: [ChezAttachmentMeta]?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(
                message_id: messageId.uuidString,
                answers: answers,
                attachments: attachments
            )
        )
    }

    /// Fetch the homeowner-safe progress timeline for one request.
    /// Labels never expose vendor names from the private call ledger.
    /// Every field is optional server-side — decode resiliently and let
    /// callers render nothing on failure (zero-noise degradation).
    static func fetchChezRequestProgress(requestId: UUID) async throws -> ChezRequestProgress {
        struct Body: Encodable {
            let action = "fetch_request_progress"
            let request_id: String
        }
        let data = try await callConciergeEdgeFunction(
            body: Body(request_id: requestId.uuidString)
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .havenISO8601
        return try decoder.decode(ChezRequestProgress.self, from: data)
    }

    /// Wave 6 — shared storage upload for Chez thread attachments.
    /// Same bucket + path convention the reply composer uses
    /// (`documents` bucket, `chez-requests/{userId}/...`), extracted so
    /// the info-request photo answer reuses the exact pipeline.
    static func uploadChezAttachment(
        data: Data,
        filename: String,
        mimeType: String
    ) async throws -> ChezAttachmentMeta {
        let userId = try await HavenSupabase.client.auth.session.user.id.uuidString
        let path = "chez-requests/\(userId)/\(UUID().uuidString.prefix(8))-\(filename)"
        _ = try await HavenSupabase.client.storage
            .from("documents")
            .upload(path, data: data, options: .init(contentType: mimeType, upsert: false))
        return ChezAttachmentMeta(
            path: path,
            filename: filename,
            mimeType: mimeType,
            sizeBytes: data.count,
            uploadedAt: Date()
        )
    }

    // MARK: - Phase 86B — Chez activity feed

    /// Fetch the recent Chez activity for the requesting user's household.
    /// Server returns the last N workbench actions denormalized with
    /// customer-facing verbs. Homeowner-only — admin override path is
    /// not exposed from iOS.
    ///
    /// Dashboard surfaces the top 5 in the "Recent Chez activity" card
    /// + offers a deep-link to the full timeline view (which calls this
    /// with `limit = 50` for the longer history).
    static func fetchChezActivityFeed(limit: Int = 25) async throws -> [ChezActivityRow] {
        struct Body: Encodable {
            let action = "fetch_activity_feed"
            let limit: Int
        }
        struct Wrapper: Decodable { let items: [ChezActivityRow] }
        let data = try await callConciergeEdgeFunction(body: Body(limit: limit))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .havenISO8601
        let wrapper = try decoder.decode(Wrapper.self, from: data)
        return wrapper.items
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

    /// Phase 84.5 — Posted whenever the homeowner's home_assessments row
    /// changes (status flip, captured data update, completion). Dashboard
    /// pending card and any other surface listening for assessment state
    /// reloads on this.
    static let chezHomeAssessmentChanged = Notification.Name("chezHomeAssessmentChanged")

    /// Phase 84.5 — Posted when a chez_assessment_complete push arrives
    /// so that the AssessmentReviewView auto-presents.
    static let openChezAssessmentReview = Notification.Name("openChezAssessmentReview")

    /// Phase 2.2 — Posted when ChezQuizRequestSubmitter finishes
    /// batch-creating chez_requests at quiz completion. The post-quiz
    /// summary card (Phase 2.4) listens for this to refresh its row
    /// count, but it's also a useful hook for any other surface that
    /// wants to react to the wave of new homeowner intents.
    static let chezQuizRequestsSubmitted = Notification.Name("chezQuizRequestsSubmitted")
}

// MARK: - Phase 84.5 — Home Assessment wrappers

extension HavenSupabase {

    /// Picks "Have Chez handle it" at signup. Creates (idempotent) a
    /// `home_assessments` row, stamps `properties.attributes['assessment_mode']
    /// = 'handyman'`, force-completes the quiz so the quiz card hides,
    /// notifies the operator side. The returned `assessmentId` is what
    /// the dashboard pending card should load.
    static func requestHomeAssessment(
        propertyId: UUID,
        notes: String? = nil,
        preVisitNotes: String? = nil,
        preVisitPhotos: [String]? = nil
    ) async throws -> RequestHomeAssessmentResponse {
        struct Body: Encodable {
            let action = "request_home_assessment"
            let property_id: String
            let notes: String?
            let pre_visit_notes: String?
            let pre_visit_photos: [String]?
        }
        let data = try await callConciergeEdgeFunction(
            body: Body(
                property_id: propertyId.uuidString,
                notes: notes,
                pre_visit_notes: preVisitNotes,
                pre_visit_photos: preVisitPhotos
            )
        )
        return try JSONDecoder().decode(RequestHomeAssessmentResponse.self, from: data)
    }

    /// Homeowner cancels their pending/in-flight assessment (mode switch
    /// to DIY, or any other reason). Releases `assessment_mode` so the
    /// quiz card returns; flips the assessment row to status='cancelled'.
    static func cancelHomeAssessment(
        assessmentId: UUID,
        reason: String? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "cancel_home_assessment"
            let assessment_id: String
            let reason: String?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(assessment_id: assessmentId.uuidString, reason: reason)
        )
    }

    /// Homeowner asks the operator to move the visit. Just flags the row
    /// — the operator handles the actual reschedule via the cockpit.
    static func requestAssessmentReschedule(
        assessmentId: UUID,
        notes: String? = nil,
        preferredDates: [String]? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "request_assessment_reschedule"
            let assessment_id: String
            let notes: String?
            let preferred_dates: [String]?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(
                assessment_id: assessmentId.uuidString,
                notes: notes,
                preferred_dates: preferredDates
            )
        )
    }

    /// Homeowner approves the captured data after handyman submits.
    /// Flips status='completed'.
    static func submitAssessmentReview(assessmentId: UUID) async throws {
        struct Body: Encodable {
            let action = "submit_assessment_review"
            let assessment_id: String
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(assessment_id: assessmentId.uuidString)
        )
    }

    /// Homeowner flags items the handyman missed or got wrong. Opens a
    /// follow-up chez_request thread + flips status='corrections_requested'.
    static func requestAssessmentCorrections(
        assessmentId: UUID,
        items: [AssessmentCorrectionItem]
    ) async throws {
        struct Body: Encodable {
            let action = "request_assessment_corrections"
            let assessment_id: String
            let items: [AssessmentCorrectionItem]
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(assessment_id: assessmentId.uuidString, items: items)
        )
    }

    /// Updates the homeowner's pre-visit prep — notes, photos,
    /// captured_attributes (year built corrections, has_pets, etc.).
    /// Deep-merges with whatever's already there.
    static func updatePreVisitData(
        assessmentId: UUID,
        notes: String? = nil,
        photos: [String]? = nil,
        attributes: [String: String]? = nil
    ) async throws {
        struct Body: Encodable {
            let action = "update_pre_visit_data"
            let assessment_id: String
            let pre_visit_notes: String?
            let pre_visit_photos: [String]?
            let captured_attributes: [String: String]?
        }
        _ = try await callConciergeEdgeFunction(
            body: Body(
                assessment_id: assessmentId.uuidString,
                pre_visit_notes: notes,
                pre_visit_photos: photos,
                captured_attributes: attributes
            )
        )
    }

    /// Reads the active home_assessments row for this household / property.
    /// Returns nil when no active assessment exists.
    static func fetchHomeAssessment(
        assessmentId: UUID? = nil,
        propertyId: UUID? = nil
    ) async throws -> HomeAssessmentRow? {
        struct Body: Encodable {
            let action = "fetch_home_assessment"
            let assessment_id: String?
            let property_id: String?
        }
        struct Response: Decodable {
            let ok: Bool
            let assessment: HomeAssessmentRow?
        }
        let data = try await callConciergeEdgeFunction(
            body: Body(
                assessment_id: assessmentId?.uuidString,
                property_id: propertyId?.uuidString
            )
        )
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.assessment
    }
}

/// Response from `request_home_assessment`.
struct RequestHomeAssessmentResponse: Decodable {
    let ok: Bool
    let assessmentId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case ok, status
        case assessmentId = "assessment_id"
    }
}
