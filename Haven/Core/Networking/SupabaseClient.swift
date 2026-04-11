import Foundation
import Supabase

/// Singleton Supabase client for Haven.
/// Provides typed access to database, auth, storage, and Edge Functions.
enum HavenSupabase {
    static let client = SupabaseClient(
        supabaseURL: URL(string: AppConfig.Supabase.url)!,
        supabaseKey: AppConfig.Supabase.anonKey
    )

    static func from(_ table: String) -> PostgrestQueryBuilder {
        client.from(table)
    }

    static var auth: AuthClient {
        client.auth
    }

    static var storage: SupabaseStorageClient {
        client.storage
    }

    // MARK: - Safe Session Lookup (Apr 7, 2026)

    /// Bounded session lookup. supabase-swift's `AuthClient.session` getter
    /// can hang indefinitely if a token refresh stalls (we observed this on
    /// Tom's wife's account during onboarding: the splash sat for 90+
    /// seconds with no recovery, multiple times, even after my v1 fix).
    /// Every call site that reads `HavenSupabase.auth.session` directly
    /// inherits that hang.
    ///
    /// **Why this uses `withCheckedContinuation` + `DispatchQueue` instead
    /// of `withTaskGroup`:** the obvious implementation is to race the
    /// session lookup against `Task.sleep` inside a task group. That
    /// implementation is broken in this exact failure mode. `withTaskGroup`
    /// waits for ALL child tasks to finish before returning, even after
    /// `cancelAll()`. Cooperative cancellation requires the cancelled task
    /// to actually check `Task.isCancelled`. If supabase-swift's session
    /// getter is blocked on a synchronous lock or a network call that
    /// will never return, the child task CAN'T check cancellation, so
    /// the entire task group hangs forever waiting for it to die.
    ///
    /// The bulletproof fix is to use a `DispatchQueue` timer (implemented
    /// in libdispatch at the C level — cannot be blocked by Swift task
    /// state) and a checked continuation. Whichever side fires first
    /// resumes the continuation; the other side becomes a no-op. The
    /// hung session task gets LEAKED — it sits there forever, but it
    /// doesn't block anything because we never await it.
    ///
    /// Use this from anywhere user-facing — onboarding, dashboard refresh,
    /// account flows. The bare `HavenSupabase.auth.session` should only be
    /// used in background services that can tolerate an indefinite wait
    /// (push notification registration, analytics flush, etc.).
    static func safeSession(timeout: TimeInterval = 3.0) async -> Session? {
        let startTime = Date()
        let callerTag = "safeSession[\(UUID().uuidString.prefix(6))]"
        print("[\(callerTag)] Starting session lookup with \(timeout)s deadline")

        return await withCheckedContinuation { (continuation: CheckedContinuation<Session?, Never>) in
            // Single-resume guard. We use a class wrapper around an
            // NSLock instead of an actor because the resume call has to
            // be synchronous from inside both the dispatch handler and
            // the detached task — we can't await an actor here without
            // reintroducing the same hang risk we're trying to fix.
            final class ResumeGuard: @unchecked Sendable {
                let lock = NSLock()
                var didResume = false
            }
            let guardState = ResumeGuard()

            @Sendable func resumeOnce(_ value: Session?, source: String) {
                guardState.lock.lock()
                let shouldResume = !guardState.didResume
                if shouldResume { guardState.didResume = true }
                guardState.lock.unlock()
                if shouldResume {
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("[\(callerTag)] Resumed via \(source) after \(String(format: "%.2f", elapsed))s, session=\(value != nil ? "yes" : "nil")")
                    continuation.resume(returning: value)
                } else {
                    print("[\(callerTag)] \(source) tried to resume but already resolved (ignored)")
                }
            }

            // Schedule the wall-clock deadline FIRST so it's armed before
            // we kick off the (potentially hanging) session lookup. The
            // dispatch timer fires on a background queue at the libdispatch
            // level — no Swift task state is involved, so it cannot be
            // blocked by anything happening in supabase-swift's actors.
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + timeout) {
                resumeOnce(nil, source: "deadline")
            }

            // Spawn the session lookup in a detached task. If it returns
            // before the deadline, great — we resume with the session. If
            // it hangs, the deadline above takes over and this task gets
            // leaked (still running, but ignored). The leak is the price
            // we pay to avoid trapping the user.
            Task.detached(priority: .userInitiated) {
                do {
                    let session = try await client.auth.session
                    resumeOnce(session, source: "session-fetch")
                } catch {
                    print("[\(callerTag)] session fetch threw: \(error)")
                    resumeOnce(nil, source: "session-fetch-error")
                }
            }
        }
    }

    /// Bounded access-token lookup. Convenience around `safeSession` that
    /// returns just the bearer token. Returns nil on timeout or when the
    /// session has no access token.
    static func safeAccessToken(timeout: TimeInterval = 3.0) async -> String? {
        await safeSession(timeout: timeout)?.accessToken
    }

    // MARK: - Edge Function Direct Caller

    /// Call a Supabase Edge Function directly via URLRequest, bypassing the SDK's invoke method
    /// which can fail to parse certain response formats.
    private static func callEdgeFunction(
        name: String,
        body: Encodable,
        timeoutSeconds: TimeInterval = 120
    ) async throws -> Data {
        // Apr 7, 2026: skip the proactive `refreshSession()` call. supabase-swift
        // will refresh on its own when the token expires, and the explicit call
        // can hang indefinitely on a stalled refresh — which trapped onboarding
        // for Tom's wife. The access-token read below is bounded by a 3-second
        // deadline so even if the underlying session is broken, we fall back
        // cleanly to anon-key auth and let the Edge Function reject the
        // request with a clear 401 instead of hanging.

        // Build the URL: https://<project>.supabase.co/functions/v1/<function_name>
        let baseURL = AppConfig.Supabase.url
        guard let url = URL(string: "\(baseURL)/functions/v1/\(name)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "apikey")

        // Add auth token if available, bounded by a 3-second deadline so a
        // stalled supabase-swift session refresh can't hang every Edge
        // Function call. Falls back to the anon key on timeout.
        if let accessToken = await safeAccessToken(timeout: 3.0) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            // Fallback: use anon key as auth
            request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        }

        // Encode body
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Log for debugging
        print("[EdgeFunction:\(name)] Status: \(httpResponse.statusCode), Body size: \(data.count) bytes")
        if httpResponse.statusCode != 200 {
            let bodyString = String(data: data, encoding: .utf8) ?? "non-utf8"
            print("[EdgeFunction:\(name)] Error body: \(bodyString.prefix(500))")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to extract error message from response
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String {
                errorMsg = error
                if let hint = json["hint"] as? String {
                    print("[EdgeFunction:\(name)] Hint: \(hint)")
                }
            } else {
                errorMsg = "Edge function returned status \(httpResponse.statusCode)"
            }
            throw NSError(
                domain: "EdgeFunction",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMsg]
            )
        }

        return data
    }

    // MARK: - Push Notifications

    struct PushNotificationRequest: Encodable {
        let recipientUserIds: [String]
        let title: String
        let body: String
        let data: [String: String]?

        enum CodingKeys: String, CodingKey {
            case recipientUserIds = "recipient_user_ids"
            case title, body, data
        }
    }

    static func sendPushNotification(
        recipientUserIds: [String],
        title: String,
        body: String,
        data: [String: String]? = nil
    ) async throws {
        let responseData = try await callEdgeFunction(
            name: "send-push-notification",
            body: PushNotificationRequest(
                recipientUserIds: recipientUserIds,
                title: title,
                body: body,
                data: data
            ),
            timeoutSeconds: 30
        )
        if let responseStr = String(data: responseData, encoding: .utf8) {
            print("[Push] Response: \(responseStr)")
        }
    }

    // MARK: - Edge Functions

    struct AnalyzeDocumentRequest: Encodable {
        let documentId: String
        let text: String?
        let imageBase64: String?
        let householdId: String
        let category: String?
        let documentTitle: String?
        let userId: String?

        enum CodingKeys: String, CodingKey {
            case documentId = "document_id"
            case text
            case imageBase64 = "image_base64"
            case householdId = "household_id"
            case category
            case documentTitle = "document_title"
            case userId = "user_id"
        }
    }

    struct ChatRequest: Encodable {
        let message: String
        let conversationHistory: [[String: String]]
        let contextType: String?
        let contextId: String?
        let householdId: String
        let encryptionKey: String?
        let systemContext: String?

        enum CodingKeys: String, CodingKey {
            case message
            case conversationHistory = "conversation_history"
            case contextType = "context_type"
            case contextId = "context_id"
            case householdId = "household_id"
            case encryptionKey = "encryption_key"
            case systemContext = "system_context"
        }
    }

    struct GapAnalysisRequest: Encodable {
        let householdId: String

        enum CodingKeys: String, CodingKey {
            case householdId = "household_id"
        }
    }

    static func analyzeDocument(
        documentId: String,
        text: String?,
        imageBase64: String?,
        householdId: String,
        category: String? = nil,
        documentTitle: String? = nil
    ) async throws -> Data {
        let currentUserId = try? await client.auth.session.user.id.uuidString

        let body = AnalyzeDocumentRequest(
            documentId: documentId,
            text: text,
            imageBase64: imageBase64,
            householdId: householdId,
            category: category,
            documentTitle: documentTitle,
            userId: currentUserId
        )
        return try await callEdgeFunction(name: "analyze-document", body: body)
    }

    static func chat(message: String, history: [[String: String]], contextType: String?, contextId: String?, householdId: String, encryptionKey: String? = nil, systemContext: String? = nil) async throws -> Data {
        let body = ChatRequest(
            message: message,
            conversationHistory: history,
            contextType: contextType,
            contextId: contextId,
            householdId: householdId,
            encryptionKey: encryptionKey,
            systemContext: systemContext
        )
        return try await callEdgeFunction(name: "chat", body: body)
    }

    static func gapAnalysis(householdId: String) async throws -> Data {
        let body = GapAnalysisRequest(householdId: householdId)
        return try await callEdgeFunction(name: "gap-analysis", body: body)
    }

    // MARK: - Extract Vendor from Website

    struct ExtractVendorRequest: Encodable {
        let url: String
        let householdId: String

        enum CodingKeys: String, CodingKey {
            case url
            case householdId = "household_id"
        }
    }

    static func extractVendorFromWebsite(url: String, householdId: String) async throws -> Data {
        let body = ExtractVendorRequest(url: url, householdId: householdId)
        return try await callEdgeFunction(name: "extract-vendor", body: body, timeoutSeconds: 30)
    }

    // MARK: - Simulate Scenario

    struct ScenarioRequest: Encodable {
        let scenarioId: String?
        let customQuery: String?
        let householdId: String
        let params: [String: String]?

        enum CodingKeys: String, CodingKey {
            case scenarioId = "scenario_id"
            case customQuery = "custom_query"
            case householdId = "household_id"
            case params
        }
    }

    static func simulateScenario(
        scenarioId: String? = nil,
        customQuery: String? = nil,
        householdId: String,
        params: [String: String]? = nil
    ) async throws -> Data {
        let body = ScenarioRequest(
            scenarioId: scenarioId,
            customQuery: customQuery,
            householdId: householdId,
            params: params
        )
        return try await callEdgeFunction(name: "simulate-scenario", body: body, timeoutSeconds: 180)
    }

    // MARK: - Analyze Quote

    struct AnalyzeQuoteRequest: Encodable {
        let imageBase64: String?
        let text: String?
        let projectName: String?
        let projectCategory: String?
        let propertyLocation: String?

        enum CodingKeys: String, CodingKey {
            case text
            case imageBase64 = "image_base64"
            case projectName = "project_name"
            case projectCategory = "project_category"
            case propertyLocation = "property_location"
        }
    }

    static func analyzeQuote(
        imageBase64: String? = nil,
        text: String? = nil,
        projectName: String? = nil,
        projectCategory: String? = nil,
        propertyLocation: String? = nil
    ) async throws -> Data {
        let body = AnalyzeQuoteRequest(
            imageBase64: imageBase64,
            text: text,
            projectName: projectName,
            projectCategory: projectCategory,
            propertyLocation: propertyLocation
        )
        return try await callEdgeFunction(name: "analyze-quote", body: body, timeoutSeconds: 120)
    }

    // MARK: - Property Lookup

    struct PropertyLookupRequest: Encodable {
        let address: String
    }

    static func propertyLookup(address: String) async throws -> Data {
        let body = PropertyLookupRequest(address: address)
        return try await callEdgeFunction(name: "property-lookup", body: body, timeoutSeconds: 15)
    }

    // MARK: - Project Feasibility (ROI)

    struct ProjectFeasibilityRequest: Encodable {
        let projectType: String
        let propertyLocation: String?
        let yearBuilt: Int?
        let squareFootage: Int?
        let propertyValue: Double?

        enum CodingKeys: String, CodingKey {
            case projectType = "project_type"
            case propertyLocation = "property_location"
            case yearBuilt = "year_built"
            case squareFootage = "square_footage"
            case propertyValue = "property_value"
        }
    }

    static func projectFeasibility(
        projectType: String,
        propertyLocation: String? = nil,
        yearBuilt: Int? = nil,
        squareFootage: Int? = nil,
        propertyValue: Double? = nil
    ) async throws -> Data {
        let body = ProjectFeasibilityRequest(
            projectType: projectType,
            propertyLocation: propertyLocation,
            yearBuilt: yearBuilt,
            squareFootage: squareFootage,
            propertyValue: propertyValue
        )
        return try await callEdgeFunction(name: "project-feasibility", body: body, timeoutSeconds: 30)
    }

    // MARK: - Process Inbox Item

    struct ProcessInboxItemRequest: Encodable {
        let inboxItemId: String
        let propertyId: String?
        let action: String
        let documentCategory: String?
        let targetProjectId: String?
        let vehicleId: String?

        enum CodingKeys: String, CodingKey {
            case action
            case inboxItemId = "inbox_item_id"
            case propertyId = "property_id"
            case documentCategory = "document_category"
            case targetProjectId = "target_project_id"
            case vehicleId = "vehicle_id"
        }
    }

    static func processInboxItem(
        inboxItemId: String,
        propertyId: String? = nil,
        action: String,
        documentCategory: String? = nil,
        targetProjectId: String? = nil,
        vehicleId: String? = nil
    ) async throws -> Data {
        let body = ProcessInboxItemRequest(
            inboxItemId: inboxItemId,
            propertyId: propertyId,
            action: action,
            documentCategory: documentCategory,
            targetProjectId: targetProjectId,
            vehicleId: vehicleId
        )
        return try await callEdgeFunction(name: "process-inbox-item", body: body, timeoutSeconds: 120)
    }

    // MARK: - View Document (Zero-Access Model)

    struct ViewDocumentRequest: Encodable {
        let documentId: String

        enum CodingKeys: String, CodingKey {
            case documentId = "document_id"
        }
    }

    /// Fetches a decrypted document via the view-document Edge Function.
    /// The file is decrypted server-side in an isolated environment and streamed back.
    static func viewDocument(documentId: String) async throws -> Data {
        let body = ViewDocumentRequest(documentId: documentId)
        return try await callEdgeFunction(name: "view-document", body: body)
    }

    // MARK: - Delete Account

    static func deleteAccount() async throws -> Data {
        // Empty body — the Edge Function uses the auth token to identify the user
        struct EmptyBody: Encodable {}
        return try await callEdgeFunction(name: "delete-account", body: EmptyBody(), timeoutSeconds: 60)
    }

    // MARK: - Household Merge

    struct MergeHouseholdRequest: Encodable {
        let action: String
        let email: String?
        let mergeRequestId: String?
        let sourceHouseholdId: String?
        let targetHouseholdId: String?
        let resolutions: MergeResolutions?

        enum CodingKeys: String, CodingKey {
            case action, email, resolutions
            case mergeRequestId = "merge_request_id"
            case sourceHouseholdId = "source_household_id"
            case targetHouseholdId = "target_household_id"
        }
    }

    static func mergeHouseholds(
        action: String,
        email: String? = nil,
        mergeRequestId: String? = nil,
        sourceHouseholdId: String? = nil,
        targetHouseholdId: String? = nil,
        resolutions: MergeResolutions? = nil
    ) async throws -> Data {
        let body = MergeHouseholdRequest(
            action: action,
            email: email,
            mergeRequestId: mergeRequestId,
            sourceHouseholdId: sourceHouseholdId,
            targetHouseholdId: targetHouseholdId,
            resolutions: resolutions
        )
        return try await callEdgeFunction(name: "merge-households", body: body)
    }

    /// Typed wrapper around the merge-households "check_user" action used by the
    /// HouseholdInviteCoordinator. Returns nil when no Haven user exists for the
    /// given email; returns a populated record when a Haven user is already on file.
    struct CheckUserResult: Decodable {
        let exists: Bool
        let userId: String?
        let name: String?
        let householdId: String?
        let householdName: String?

        enum CodingKeys: String, CodingKey {
            case exists
            case userId = "user_id"
            case name
            case householdId = "household_id"
            case householdName = "household_name"
        }
    }

    static func mergeHouseholdsCheckUser(email: String) async throws -> CheckUserResult? {
        let data = try await mergeHouseholds(action: "check_user", email: email)
        let decoded = try JSONDecoder().decode(CheckUserResult.self, from: data)
        return decoded.exists ? decoded : nil
    }

    // MARK: - Household Invite (SendGrid)

    struct SendHouseholdInviteRequest: Encodable {
        let to: String
        let inviteCode: String
        let inviteUrl: String
        let inviterName: String
        let inviterAvatarUrl: String?
        let householdName: String?
        let householdAddress: String?
        let systemCount: Int?
        let taskCount: Int?
        let memberCount: Int?
        let personalMessage: String?
        let inviteeFirstName: String?

        enum CodingKeys: String, CodingKey {
            case to
            case inviteCode = "invite_code"
            case inviteUrl = "invite_url"
            case inviterName = "inviter_name"
            case inviterAvatarUrl = "inviter_avatar_url"
            case householdName = "household_name"
            case householdAddress = "household_address"
            case systemCount = "system_count"
            case taskCount = "task_count"
            case memberCount = "member_count"
            case personalMessage = "personal_message"
            case inviteeFirstName = "invitee_first_name"
        }
    }

    static func sendHouseholdInvite(_ payload: SendHouseholdInviteRequest) async throws {
        _ = try await callEdgeFunction(name: "send-household-invite", body: payload, timeoutSeconds: 30)
    }

    struct ResendHouseholdInviteRequest: Encodable {
        let invitationId: String
        enum CodingKeys: String, CodingKey { case invitationId = "invitation_id" }
    }

    static func resendHouseholdInvite(invitationId: UUID) async throws {
        _ = try await callEdgeFunction(
            name: "resend-household-invite",
            body: ResendHouseholdInviteRequest(invitationId: invitationId.uuidString),
            timeoutSeconds: 30
        )
    }

    struct GetInvitationPreviewRequest: Encodable {
        let inviteCode: String
        enum CodingKeys: String, CodingKey { case inviteCode = "invite_code" }
    }

    struct InvitationPreview: Decodable {
        let inviteCode: String
        let inviterName: String?
        let inviterAvatarUrl: String?
        let householdName: String?
        let householdAddress: String?
        let inviteeFirstName: String?
        let inviteeEmail: String?
        let personalMessage: String?
        let systemCount: Int?
        let taskCount: Int?
        let memberCount: Int?
        let propertyCount: Int?
        let expiresAt: String?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case inviteCode = "invite_code"
            case inviterName = "inviter_name"
            case inviterAvatarUrl = "inviter_avatar_url"
            case householdName = "household_name"
            case householdAddress = "household_address"
            case inviteeFirstName = "invitee_first_name"
            case inviteeEmail = "invitee_email"
            case personalMessage = "personal_message"
            case systemCount = "system_count"
            case taskCount = "task_count"
            case memberCount = "member_count"
            case propertyCount = "property_count"
            case expiresAt = "expires_at"
            case status
        }
    }

    static func getInvitationPreview(inviteCode: String) async throws -> InvitationPreview {
        let data = try await callEdgeFunction(
            name: "get-invitation-preview",
            body: GetInvitationPreviewRequest(inviteCode: inviteCode),
            timeoutSeconds: 30
        )
        return try JSONDecoder().decode(InvitationPreview.self, from: data)
    }

    // MARK: - Vehicle Value (Estimated current market value)

    struct VehicleValueRequest: Encodable {
        let year: Int
        let make: String
        let model: String
        let trim: String?
        let mileage: Int?
        let condition: String?
    }

    struct VehicleValueResponse: Decodable {
        let low: Double
        let mid: Double
        let high: Double
        let currency: String
        let confidence: Double
        let notes: String?
        let source: String
    }

    static func vehicleValue(
        year: Int,
        make: String,
        model: String,
        trim: String? = nil,
        mileage: Int? = nil,
        condition: String? = nil
    ) async throws -> VehicleValueResponse {
        let body = VehicleValueRequest(year: year, make: make, model: model, trim: trim, mileage: mileage, condition: condition)
        let data = try await callEdgeFunction(name: "vehicle-value", body: body, timeoutSeconds: 30)
        return try JSONDecoder().decode(VehicleValueResponse.self, from: data)
    }

    // MARK: - Equipment Catalog Search

    struct EquipmentSearchRequest: Encodable {
        let query: String
        let limit: Int?
        let category: String?
    }

    /// Search the equipment catalog for models matching a natural language query.
    /// Supports queries like "bosch stove", "samsung fridge", "carrier ac", or model numbers.
    static func searchEquipment(query: String, limit: Int? = 15, category: String? = nil) async throws -> EquipmentSearchResponse {
        let body = EquipmentSearchRequest(query: query, limit: limit, category: category)
        let data = try await callEdgeFunction(name: "search-equipment", body: body, timeoutSeconds: 15)
        return try JSONDecoder().decode(EquipmentSearchResponse.self, from: data)
    }

    // MARK: - Equipment Photo Identification

    struct IdentifyEquipmentRequest: Encodable {
        let imageBase64: String
        let category: String?

        enum CodingKeys: String, CodingKey {
            case imageBase64 = "image_base64"
            case category
        }
    }

    /// Identify equipment from a photo of the model/serial plate.
    /// Uses Claude Vision to extract manufacturer, model number, and serial number,
    /// then matches against the equipment catalog.
    static func identifyEquipment(imageBase64: String, category: String? = nil) async throws -> EquipmentIdentifyResponse {
        let body = IdentifyEquipmentRequest(imageBase64: imageBase64, category: category)
        let data = try await callEdgeFunction(name: "identify-equipment", body: body, timeoutSeconds: 30)
        return try JSONDecoder().decode(EquipmentIdentifyResponse.self, from: data)
    }

    // MARK: - Manual Lookup

    /// Look up manuals, common issues, and maintenance schedules for a model number.
    static func lookupManual(modelNumber: String) async throws -> [String: Any] {
        let body: [String: String] = ["model_number": modelNumber]
        let data = try await callEdgeFunction(name: "lookup-manual", body: body, timeoutSeconds: 15)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }

    // MARK: - Catalog Request

    struct CatalogRequestBody: Encodable {
        let brand: String
        let systemType: String
        let modelNumber: String?
        let notes: String?
        let userId: String?
        let householdId: String?
    }

    static func sendCatalogRequest(
        brand: String,
        systemType: String,
        modelNumber: String? = nil,
        notes: String? = nil
    ) async throws {
        let currentUserId = try? await client.auth.session.user.id.uuidString
        let user = try? await DatabaseService.shared.fetchCurrentUser()

        let body = CatalogRequestBody(
            brand: brand,
            systemType: systemType,
            modelNumber: modelNumber,
            notes: notes,
            userId: currentUserId,
            householdId: user?.householdId?.uuidString
        )
        _ = try await callEdgeFunction(name: "send-catalog-request", body: body, timeoutSeconds: 15)
    }

    // MARK: - Process Invoice

    struct ProcessInvoiceRequest: Encodable {
        let documentId: String
        let propertyId: String?
        let householdId: String
        let vehicleId: String?

        enum CodingKeys: String, CodingKey {
            case documentId = "document_id"
            case propertyId = "property_id"
            case householdId = "household_id"
            case vehicleId = "vehicle_id"
        }
    }

    /// Process a home service invoice via AI to extract completed tasks, new systems, and service details.
    static func processInvoice(documentId: String, propertyId: String, householdId: String) async throws -> InvoiceProcessingResult {
        let body = ProcessInvoiceRequest(
            documentId: documentId,
            propertyId: propertyId,
            householdId: householdId,
            vehicleId: nil
        )
        let data = try await callEdgeFunction(name: "process-invoice", body: body, timeoutSeconds: 120)
        return try JSONDecoder().decode(InvoiceProcessingResult.self, from: data)
    }

    /// Process a vehicle service invoice via AI to extract completed tasks, mileage, and service details.
    static func processVehicleInvoice(documentId: String, vehicleId: String, householdId: String) async throws -> InvoiceProcessingResult {
        let body = ProcessInvoiceRequest(
            documentId: documentId,
            propertyId: nil,
            householdId: householdId,
            vehicleId: vehicleId
        )
        let data = try await callEdgeFunction(name: "process-invoice", body: body, timeoutSeconds: 120)
        return try JSONDecoder().decode(InvoiceProcessingResult.self, from: data)
    }

    // MARK: - Brand Logo (Brandfetch)

    struct BrandLogoRequest: Encodable {
        let query: String?
        let domain: String?
    }

    struct BrandLogoResponse: Decodable {
        let name: String?
        let domain: String?
        let brandId: String?
        let logoUrl: String?
        let iconUrl: String?
        let brandColor: String?
        let logos: [BrandAsset]?
        let icons: [BrandAsset]?
        let colors: [BrandColor]?

        struct BrandAsset: Decodable {
            let url: String
            let format: String?
            let theme: String?
            let type: String?
        }

        struct BrandColor: Decodable {
            let hex: String
            let type: String?
        }
    }

    /// Fetch brand logo/colors by company name (search) or domain (direct lookup).
    /// Use `domain` when you have a website URL, `query` when searching by name.
    static func fetchBrandLogo(query: String? = nil, domain: String? = nil) async throws -> BrandLogoResponse {
        let data = try await callEdgeFunction(
            name: "brand-logo",
            body: BrandLogoRequest(query: query, domain: domain),
            timeoutSeconds: 15
        )
        return try JSONDecoder().decode(BrandLogoResponse.self, from: data)
    }

    // MARK: - Phase 19n: Find Local Vendors

    /// One vendor returned by `find-local-vendors`. The edge function caches
    /// these in `local_vendor_results` and refreshes via Google Places after
    /// 60 days. Top 2 are flagged `isHavenCertified` (>= 4.7 stars, >= 25
    /// reviews, no chain indicators); the next 2 are "Suggested".
    struct LocalVendorResult: Codable, Identifiable {
        let name: String
        let address: String?
        let phone: String?
        let website: String?
        let rating: Double?
        let reviewCount: Int?
        let googlePlaceId: String
        let isHavenCertified: Bool
        let rankPosition: Int

        var id: String { googlePlaceId }
    }

    struct LocalVendorResponse: Codable {
        let vendors: [LocalVendorResult]
        let cached: Bool?
    }

    private struct LocalVendorRequest: Encodable {
        let town: String
        let state: String
        let category: String
    }

    /// Calls the `find-local-vendors` edge function. The function checks the
    /// cache first; on a miss it calls Google Places Text Search, ranks
    /// results, writes the cache, and returns up to 4 vendors total
    /// (2 Haven Certified + 2 Suggested). Empty `vendors` is a valid result —
    /// the iOS sheet renders an empty state in that case.
    static func findLocalVendors(
        town: String,
        state: String,
        category: String
    ) async throws -> LocalVendorResponse {
        let data = try await callEdgeFunction(
            name: "find-local-vendors",
            body: LocalVendorRequest(town: town, state: state, category: category),
            timeoutSeconds: 30
        )
        return try JSONDecoder().decode(LocalVendorResponse.self, from: data)
    }

    /// Find local professional advisors (estate attorneys, CPAs, financial
    /// advisors, life insurance agents) via Google Places. Same response
    /// shape as findLocalVendors — reuses LocalVendorResponse.
    static func findLocalAdvisors(
        town: String,
        state: String,
        advisorType: String
    ) async throws -> LocalVendorResponse {
        let data = try await callEdgeFunction(
            name: "find-local-advisors",
            body: LocalVendorRequest(town: town, state: state, category: advisorType),
            timeoutSeconds: 30
        )
        return try JSONDecoder().decode(LocalVendorResponse.self, from: data)
    }
}
