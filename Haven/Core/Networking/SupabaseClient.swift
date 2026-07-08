import Foundation
import Supabase
import Auth

#if targetEnvironment(simulator)
/// Simulator-only auth storage that uses `UserDefaults` instead of the iOS
/// Keychain. The Supabase Swift SDK's default `KeychainLocalStorage` cannot
/// persist auth sessions on iOS Simulator builds because the Security
/// framework returns `errSecMissingEntitlement` (-34018) — Apple's
/// per-target keychain access groups are only injected on signed device
/// builds with valid provisioning, and adding explicit
/// `keychain-access-groups` to the entitlements file causes
/// FBSOpenApplicationServiceErrorDomain launch failures on the simulator
/// because iOS validates the prefix matches the team identifier (which
/// doesn't exist for simulator destinations).
///
/// Swapping to `UserDefaults` is gated on `targetEnvironment(simulator)`
/// so device + TestFlight + App Store builds continue to use the secure
/// Keychain path unchanged. Diagnosed 2026-05-08 from the simulator log:
///   ChezField (Security) errSecMissingEntitlement -34018:
///   "Client has neither application-identifier nor
///    keychain-access-groups entitlements"
final class HavenSimulatorAuthStorage: AuthLocalStorage, @unchecked Sendable {
    /// Shared singleton so the sign-out path can wipe stale entries on
    /// the SAME instance the SDK is reading + writing through. The
    /// Supabase Swift SDK's `signOut` only `remove`s the keys it's
    /// currently tracking — anything left over from a half-completed
    /// auth flow (token-refresh failure, partial session, race) stays
    /// in UserDefaults and gets read back on the next launch as if the
    /// user is still signed in. Confirmed 2026-05-08: post sign-out tap
    /// on the welcome screen popped into the previous signed-in view
    /// stack and a long-press on the email field triggered destructive
    /// actions on the previous session's screen. C-2 fix.
    static let shared = HavenSimulatorAuthStorage()

    private let defaults = UserDefaults.standard
    private let prefix = "supabase.auth."

    func store(key: String, value: Data) throws {
        defaults.set(value, forKey: prefix + key)
    }

    func retrieve(key: String) throws -> Data? {
        defaults.data(forKey: prefix + key)
    }

    func remove(key: String) throws {
        defaults.removeObject(forKey: prefix + key)
    }

    /// Wipe every UserDefaults key with the supabase.auth.* prefix.
    /// Called from the .signedOut event listener in AuthService so the
    /// next launch reads zero auth state and lands on the welcome
    /// screen instead of bouncing back into the previous session.
    func clearAll() {
        let snapshot = defaults.dictionaryRepresentation()
        for key in snapshot.keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
#endif

/// Singleton Supabase client for Haven.
/// Provides typed access to database, auth, storage, and Edge Functions.
enum HavenSupabase {
    static let client: SupabaseClient = {
        #if targetEnvironment(simulator)
        // Use the shared singleton so AuthService.signOut can call
        // clearAll() on the same instance the SDK reads + writes.
        let options = SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                storage: HavenSimulatorAuthStorage.shared
            )
        )
        return SupabaseClient(
            supabaseURL: URL(string: AppConfig.Supabase.url)!,
            supabaseKey: AppConfig.Supabase.anonKey,
            options: options
        )
        #else
        return SupabaseClient(
            supabaseURL: URL(string: AppConfig.Supabase.url)!,
            supabaseKey: AppConfig.Supabase.anonKey
        )
        #endif
    }()

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

    /// Tell the provider workspace serving a request that the
    /// homeowner just acted (accepted a time, proposed a counter).
    /// Routes through the handyman-provider edge function which
    /// resolves the contractor → workspace members and fires push.
    private struct HomeownerNotifyProviderRequest: Encodable {
        let action: String
        let requestId: String
        let eventType: String
        let title: String
        let body: String
        enum CodingKeys: String, CodingKey {
            case action, title, body
            case requestId, eventType
        }
    }

    static func notifyProviderForRequest(
        requestId: UUID,
        eventType: String,
        title: String,
        body: String
    ) async throws {
        _ = try await callEdgeFunction(
            name: "handyman-provider",
            body: HomeownerNotifyProviderRequest(
                action: "homeowner_notify_provider",
                requestId: requestId.uuidString,
                eventType: eventType,
                title: title,
                body: body
            ),
            timeoutSeconds: 15
        )
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

    // MARK: - Phase 78 — Handyman coordination edge actions

    /// Convert a homeowner's `maintenance_tasks` row into a
    /// `handyman_punch_items` row delegated to the next upcoming
    /// handyman visit (or to the wishlist if none).
    struct DelegateTaskRequest: Encodable {
        let action = "delegate_task_to_punch_list"
        let taskId: String
        let targetVisitTaskId: String?
    }

    static func delegateTaskToPunchList(taskId: String, targetVisitTaskId: String? = nil) async throws -> Data {
        let body = DelegateTaskRequest(taskId: taskId, targetVisitTaskId: targetVisitTaskId)
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    /// Generic accept / decline / cancel for a proposal-bearing row.
    /// `kind` is "task" | "punch_item" | "request". Server enforces
    /// no-double-accept via DB unique partial index.
    struct RespondToProposalRequest: Encodable {
        let action = "respond_to_proposal"
        let kind: String
        let id: String
        let decision: String
        let reason: String?
    }

    static func respondToProposal(kind: String, id: String, decision: String, reason: String? = nil) async throws -> Data {
        let body = RespondToProposalRequest(
            kind: kind,
            id: id,
            decision: decision,
            reason: (reason?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
        )
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    /// Add ad-hoc punch items to a visit. Each item can carry a
    /// `templateId` (server auto-fills minutes/category) or be a
    /// free-text title. Visit-lock semantics applied server-side.
    struct AddPunchItemDraft: Encodable {
        let templateId: String?
        let title: String?
        let estimatedMinutes: Int?
        let priority: String?
        let materialRequired: Bool
        let systemId: String?
    }

    struct AddPunchItemsRequest: Encodable {
        let action = "add_punch_items_to_visit"
        let visitTaskId: String
        let items: [AddPunchItemDraft]
    }

    static func addPunchItemsToVisit(visitTaskId: String, items: [AddPunchItemDraft]) async throws -> Data {
        let body = AddPunchItemsRequest(visitTaskId: visitTaskId, items: items)
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 25)
    }

    /// Toggle status on a single punch item. Mirrors field-side method
    /// (homeowner can also mark items done if they handled it themselves).
    struct UpdatePunchItemStatusRequest: Encodable {
        let action = "update_punch_item_status"
        let itemId: String
        let status: String
    }

    static func updatePunchItemStatus(itemId: String, status: String) async throws -> Data {
        let body = UpdatePunchItemStatusRequest(itemId: itemId, status: status)
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 15)
    }

    /// Soft-cancel a `handyman_requests` row. Reverts attached punch
    /// items to wishlist (assigned_visit_task_id=null) server-side.
    struct CancelRequestRequest: Encodable {
        let action = "cancel_handyman_request"
        let requestId: String
        let reason: String?
    }

    static func cancelHandymanRequest(requestId: String, reason: String? = nil) async throws -> Data {
        let body = CancelRequestRequest(
            requestId: requestId,
            reason: (reason?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
        )
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    // MARK: - Phase 95 (gaps #29 / #68) — handyman email fallback

    private struct NotifyHandymanFallbackRequest: Encodable {
        let request_id: String
    }

    /// Phase 95 — fire-and-forget post-message fallback. Calls the
    /// `notify-handyman-message-fallback` Edge Function which checks
    /// portal activity + per-request rate limit and emails the
    /// handyman with the latest message body when in-app delivery is
    /// likely unread. No-op when the handyman has been active in the
    /// portal recently.
    static func notifyHandymanMessageFallback(requestId: UUID) async throws -> Data {
        let body = NotifyHandymanFallbackRequest(request_id: requestId.uuidString)
        return try await callEdgeFunction(
            name: "notify-handyman-message-fallback",
            body: body,
            timeoutSeconds: 10
        )
    }

    // MARK: - Phase 95 (gap #47) — service vendor inquiries

    private struct SendVendorInquiryRequest: Encodable {
        let inquiry_id: String
    }

    /// Phase 95 (audit gap #47) — deliver a service-vendor inquiry over
    /// SendGrid. Caller already inserted the
    /// `service_vendor_inquiries` row and passes its id; the Edge
    /// Function looks up contractor email + sender name + reply-to,
    /// renders the message, sends via SendGrid, and stamps
    /// delivery_status / sent_at. Fire-and-forget — the iOS sheet
    /// dismisses on row insert and the Edge Function runs in the
    /// background.
    static func sendVendorInquiry(inquiryId: UUID) async throws -> Data {
        let body = SendVendorInquiryRequest(inquiry_id: inquiryId.uuidString)
        return try await callEdgeFunction(
            name: "send-vendor-inquiry",
            body: body,
            timeoutSeconds: 15
        )
    }

    // MARK: - Phase 84.5: Home Assessment (free Chez handyman onboarding)

    /// Homeowner-side: create the pending assessment after the foundational
    /// 7-question form and the mode-fork screen. Idempotent — server reuses
    /// an existing active assessment for this property if one exists.
    struct RequestHomeAssessmentRequest: Encodable {
        let action = "request_home_assessment"
        let propertyId: String
        let householdId: String
        let homeownerConcerns: String?
        let homeownerPresent: Bool
        let homeownerAccessNotes: String?
        let isExistingUserSupplement: Bool
        // Phase 95 / gap #4: optional preferred-window fields. iOS booking
        // sheet writes these so the operator schedules within the
        // homeowner's range. Server stores them on `home_assessments`.
        let preferredWindowStart: String?
        let preferredTimeOfDay: String?

        // Phase 95 follow-up: the edge function (handyman-provider) parses
        // the request body as snake_case. The default `JSONEncoder()` we
        // use in `callEdgeFunction` has no `keyEncodingStrategy`, so we
        // need explicit CodingKeys to land on the wire as snake_case.
        // Without these, requests fail with
        // "property_id + household_id required" on the server. Caught by
        // the E2E onboarding test on 2026-05-05.
        enum CodingKeys: String, CodingKey {
            case action
            case propertyId = "property_id"
            case householdId = "household_id"
            case homeownerConcerns = "homeowner_concerns"
            case homeownerPresent = "homeowner_present"
            case homeownerAccessNotes = "homeowner_access_notes"
            case isExistingUserSupplement = "is_existing_user_supplement"
            case preferredWindowStart = "preferred_window_start"
            case preferredTimeOfDay = "preferred_time_of_day"
        }
    }

    static func requestHomeAssessment(
        propertyId: String,
        householdId: String,
        homeownerConcerns: String? = nil,
        homeownerPresent: Bool = true,
        homeownerAccessNotes: String? = nil,
        isExistingUserSupplement: Bool = false,
        preferredWindowStart: String? = nil,
        preferredTimeOfDay: String? = nil
    ) async throws -> Data {
        let body = RequestHomeAssessmentRequest(
            propertyId: propertyId,
            householdId: householdId,
            homeownerConcerns: homeownerConcerns,
            homeownerPresent: homeownerPresent,
            homeownerAccessNotes: homeownerAccessNotes,
            isExistingUserSupplement: isExistingUserSupplement,
            preferredWindowStart: preferredWindowStart,
            preferredTimeOfDay: preferredTimeOfDay
        )
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    /// Homeowner-side: cancel a pending/scheduled assessment before ingestion.
    struct CancelAssessmentRequest: Encodable {
        let action = "cancel_assessment"
        let assessmentId: String
        let reason: String?

        // See RequestHomeAssessmentRequest for the snake_case-on-the-wire
        // rationale. The edge function reads `body.assessment_id`.
        enum CodingKeys: String, CodingKey {
            case action, reason
            case assessmentId = "assessment_id"
        }
    }

    static func cancelHomeAssessment(assessmentId: String, reason: String? = nil) async throws -> Data {
        let body = CancelAssessmentRequest(
            assessmentId: assessmentId,
            reason: (reason?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
        )
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    /// Homeowner-side: request a different time window. Admin reviews +
    /// reassigns from Operations Desk.
    struct RescheduleAssessmentRequest: Encodable {
        let action = "reschedule_assessment"
        let assessmentId: String
        let notes: String?

        // See RequestHomeAssessmentRequest. Edge function reads
        // `body.assessment_id`.
        enum CodingKeys: String, CodingKey {
            case action, notes
            case assessmentId = "assessment_id"
        }
    }

    static func rescheduleHomeAssessment(assessmentId: String, notes: String? = nil) async throws -> Data {
        let body = RescheduleAssessmentRequest(assessmentId: assessmentId, notes: notes)
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    /// Handyman-side: capture a recommendation during the visit.
    /// Urgent recommendations fire admin push on the server side.
    struct AddRecommendedTaskRequest: Encodable {
        let action = "add_recommended_task"
        let assessmentId: String
        let systemId: String?
        let zone: String?
        let title: String
        let description: String?
        let category: String?
        let urgency: String
        let recommendedOwner: String
        let recommendedTemplateKey: String?
        let observationSource: String
        let needsVerification: Bool
        let estimatedCostCents: Int?
        let handymanNotes: String?
        let homeownerVisibleNotes: String?
        let photos: [String]?

        // See RequestHomeAssessmentRequest. Edge function reads snake_case
        // (`body.assessment_id`, `body.system_id`, `body.recommended_owner`,
        // etc.). Without these, urgency-tagged recommendations from the
        // handyman during a visit fail with the server's "<field> required"
        // errors. Caught by the Phase 95 audit on 2026-05-05.
        enum CodingKeys: String, CodingKey {
            case action, zone, title, description, category, urgency, photos
            case assessmentId = "assessment_id"
            case systemId = "system_id"
            case recommendedOwner = "recommended_owner"
            case recommendedTemplateKey = "recommended_template_key"
            case observationSource = "observation_source"
            case needsVerification = "needs_verification"
            case estimatedCostCents = "estimated_cost_cents"
            case handymanNotes = "handyman_notes"
            case homeownerVisibleNotes = "homeowner_visible_notes"
        }
    }

    static func addAssessmentRecommendedTask(
        assessmentId: String,
        title: String,
        urgency: AssessmentTaskUrgency,
        recommendedOwner: AssessmentTaskOwner,
        observationSource: AssessmentTaskObservationSource = .handymanObserved,
        zone: String? = nil,
        systemId: String? = nil,
        description: String? = nil,
        category: String? = nil,
        recommendedTemplateKey: String? = nil,
        needsVerification: Bool = false,
        estimatedCostCents: Int? = nil,
        handymanNotes: String? = nil,
        homeownerVisibleNotes: String? = nil,
        photos: [String]? = nil
    ) async throws -> Data {
        let body = AddRecommendedTaskRequest(
            assessmentId: assessmentId,
            systemId: systemId,
            zone: zone,
            title: title,
            description: description,
            category: category,
            urgency: urgency.rawValue,
            recommendedOwner: recommendedOwner.rawValue,
            recommendedTemplateKey: recommendedTemplateKey,
            observationSource: observationSource.rawValue,
            needsVerification: needsVerification,
            estimatedCostCents: estimatedCostCents,
            handymanNotes: handymanNotes,
            homeownerVisibleNotes: homeownerVisibleNotes,
            photos: photos
        )
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    /// Wrap-up: homeowner_response per recommendation. Including
    /// `homeownerHandled` with optional scheduled date + vendor (G46), and
    /// dispute flag (G48).
    struct UpdateRecommendedTaskRequest: Encodable {
        let action = "update_recommended_task"
        let taskId: String
        let homeownerResponse: String?
        let homeownerHandledScheduledFor: String?
        let homeownerHandledVendor: String?
        let disputed: Bool?
        let urgency: String?
        let estimatedCostCents: Int?

        // See RequestHomeAssessmentRequest. Edge function reads snake_case.
        enum CodingKeys: String, CodingKey {
            case action, disputed, urgency
            case taskId = "task_id"
            case homeownerResponse = "homeowner_response"
            case homeownerHandledScheduledFor = "homeowner_handled_scheduled_for"
            case homeownerHandledVendor = "homeowner_handled_vendor"
            case estimatedCostCents = "estimated_cost_cents"
        }
    }

    static func updateAssessmentRecommendedTask(
        taskId: String,
        homeownerResponse: AssessmentTaskHomeownerResponse? = nil,
        homeownerHandledScheduledFor: String? = nil,
        homeownerHandledVendor: String? = nil,
        disputed: Bool? = nil,
        urgency: AssessmentTaskUrgency? = nil,
        estimatedCostCents: Int? = nil
    ) async throws -> Data {
        let body = UpdateRecommendedTaskRequest(
            taskId: taskId,
            homeownerResponse: homeownerResponse?.rawValue,
            homeownerHandledScheduledFor: homeownerHandledScheduledFor,
            homeownerHandledVendor: homeownerHandledVendor,
            disputed: disputed,
            urgency: urgency?.rawValue,
            estimatedCostCents: estimatedCostCents
        )
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    /// Handyman quick-fix during the visit. Creates backdated
    /// `service_records` row + skips chez_request fan-out for that task.
    struct MarkTaskFixedRequest: Encodable {
        let action = "mark_task_fixed_during_visit"
        let taskId: String
        let costCents: Int

        // See RequestHomeAssessmentRequest. Edge function reads snake_case.
        enum CodingKeys: String, CodingKey {
            case action
            case taskId = "task_id"
            case costCents = "cost_cents"
        }
    }

    static func markAssessmentTaskFixedDuringVisit(taskId: String, costCents: Int = 0) async throws -> Data {
        let body = MarkTaskFixedRequest(taskId: taskId, costCents: costCents)
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 20)
    }

    /// G44: mark a system inactive without archiving.
    struct DecommissionSystemRequest: Encodable {
        let action = "decommission_system"
        let systemId: String
        let reason: String?

        // See RequestHomeAssessmentRequest. Edge function reads snake_case.
        enum CodingKeys: String, CodingKey {
            case action, reason
            case systemId = "system_id"
        }
    }

    static func decommissionHomeSystem(systemId: String, reason: String? = nil) async throws -> Data {
        let body = DecommissionSystemRequest(systemId: systemId, reason: reason)
        return try await callEdgeFunction(name: "handyman-provider", body: body, timeoutSeconds: 15)
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

    // MARK: - Phase 95 (gap #37) — draft-negotiation-email

    struct DraftNegotiationItem: Encodable {
        let description: String
        let quoted_price: Double
        let market_price: Double
        let rating_reason: String
    }

    struct DraftNegotiationRequest: Encodable {
        let vendor_name: String
        let vendor_email: String?
        let homeowner_name: String?
        let project_type: String?
        let quote_total: Double
        let estimated_fair_total: Double
        let potential_savings: Double
        let overpriced_items: [DraftNegotiationItem]
        let negotiation_tips: [String]
        let property_location: String?
    }

    struct DraftNegotiationResponse: Decodable {
        struct Email: Decodable {
            let subject: String
            let body: String
            let to: String?
            let savings: Double?
        }
        let success: Bool?
        let email: Email?
        let error: String?
    }

    /// Phase 95 (gap #37) — wraps the `draft-negotiation-email`
    /// Edge Function so QuoteAnalysisView can hand the parsed
    /// quote off and get back a Claude-drafted email body the
    /// homeowner can review, edit, and send via the iOS Mail
    /// composer.
    static func draftNegotiationEmail(
        request: DraftNegotiationRequest
    ) async throws -> DraftNegotiationResponse {
        let data = try await callEdgeFunction(
            name: "draft-negotiation-email",
            body: request,
            timeoutSeconds: 60
        )
        return try JSONDecoder().decode(DraftNegotiationResponse.self, from: data)
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

    // MARK: - Phase 7: Suggested-actions apply protocol

    /// One selected row for the server batch. `payloadOverrides` carries the
    /// card's inline edits (e.g. an adjusted due_date) as raw JSON values.
    struct SelectedActionPayload: Encodable {
        let id: String
        var payloadOverrides: [String: String?]? = nil

        enum CodingKeys: String, CodingKey {
            case id
            case payloadOverrides = "payload_overrides"
        }
    }

    struct ApplySuggestedActionsRequest: Encodable {
        let inboxItemId: String
        let action = "apply_suggested_actions"
        var propertyId: String?
        let selected: [SelectedActionPayload]
        var confirmedContractorId: String?

        enum CodingKeys: String, CodingKey {
            case action, selected
            case inboxItemId = "inbox_item_id"
            case propertyId = "property_id"
            case confirmedContractorId = "confirmed_contractor_id"
        }
    }

    struct AppliedActionResult: Decodable {
        let id: String
        let status: String
        let resultRef: String?

        enum CodingKeys: String, CodingKey {
            case id, status
            case resultRef = "result_ref"
        }

        // Resilient decode — server response shape may grow.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
            status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "failed"
            resultRef = try? c.decodeIfPresent(String.self, forKey: .resultRef)
        }
    }

    private struct ApplySuggestedActionsResponse: Decodable {
        let results: [AppliedActionResult]?
        init(from decoder: Decoder) throws {
            let c = try? decoder.container(keyedBy: CodingKeys.self)
            results = try? c?.decodeIfPresent([AppliedActionResult].self, forKey: .results) ?? nil
        }
        enum CodingKeys: String, CodingKey { case results }
    }

    /// Server batch: applies the server-side kinds (task/event/project) for
    /// the selected rows and self-records their ledger entries. Returns the
    /// per-action outcomes; iOS-side kinds come back "skipped".
    static func applySuggestedActions(
        inboxItemId: String,
        propertyId: String?,
        selected: [SelectedActionPayload],
        confirmedContractorId: String? = nil
    ) async throws -> [AppliedActionResult] {
        let body = ApplySuggestedActionsRequest(
            inboxItemId: inboxItemId,
            propertyId: propertyId,
            selected: selected,
            confirmedContractorId: confirmedContractorId
        )
        let data = try await callEdgeFunction(name: "process-inbox-item", body: body, timeoutSeconds: 120)
        let decoded = try? JSONDecoder().decode(ApplySuggestedActionsResponse.self, from: data)
        return decoded?.results ?? []
    }

    struct RecordAppliedEntry: Encodable {
        let id: String
        let status: String
        var resultRef: String? = nil

        enum CodingKeys: String, CodingKey {
            case id, status
            case resultRef = "result_ref"
        }
    }

    private struct RecordAppliedActionsRequest: Encodable {
        let inboxItemId: String
        let action = "record_applied_actions"
        let applied: [RecordAppliedEntry]
        let done: Bool

        enum CodingKeys: String, CodingKey {
            case action, applied, done
            case inboxItemId = "inbox_item_id"
        }
    }

    /// The ledger call: reports iOS-applied outcomes; `done: true` stamps
    /// the item complete. The whole apply flow is re-entrant until then.
    static func recordAppliedActions(
        inboxItemId: String,
        applied: [RecordAppliedEntry],
        done: Bool
    ) async throws {
        let body = RecordAppliedActionsRequest(inboxItemId: inboxItemId, applied: applied, done: done)
        _ = try await callEdgeFunction(name: "process-inbox-item", body: body, timeoutSeconds: 60)
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

        // July 2026 (audit — resilient-decoder sweep): this is decoded from
        // the merge-households check_user Edge Function. Before this, a
        // drifted optional field (e.g. household_name as a number) threw the
        // WHOLE decode; the caller's try? then read it as "no existing
        // account" and silently bypassed the merge-request flow — a real
        // spouse could be treated as a brand-new invite. `exists` stays the
        // load-bearing field (defaults false only if genuinely absent);
        // every optional is try? so one bad field can't sink a true match.
        init(from decoder: Decoder) throws {
            let c = try? decoder.container(keyedBy: CodingKeys.self)
            exists = (try? c?.decodeIfPresent(Bool.self, forKey: .exists) ?? nil) ?? false
            userId = try? c?.decodeIfPresent(String.self, forKey: .userId) ?? nil
            name = try? c?.decodeIfPresent(String.self, forKey: .name) ?? nil
            householdId = try? c?.decodeIfPresent(String.self, forKey: .householdId) ?? nil
            householdName = try? c?.decodeIfPresent(String.self, forKey: .householdName) ?? nil
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

    // MARK: - Vehicle Recalls (manual refresh)

    struct CheckVehicleRecallsRequest: Encodable {
        let vehicle_id: String?
    }

    struct CheckVehicleRecallsResponse: Decodable {
        let checked: Int?
        let new_recalls: Int?
    }

    /// Phase 95 — manual recall sweep, mirrors `check-vehicle-recalls`
    /// Edge Function. Pass `vehicleId` to refresh just one car or `nil`
    /// to refresh every vehicle in the household.
    static func checkVehicleRecalls(vehicleId: UUID? = nil) async throws -> CheckVehicleRecallsResponse {
        let body = CheckVehicleRecallsRequest(vehicle_id: vehicleId?.uuidString)
        let data = try await callEdgeFunction(name: "check-vehicle-recalls", body: body, timeoutSeconds: 30)
        return try JSONDecoder().decode(CheckVehicleRecallsResponse.self, from: data)
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
    //
    // Phase 4 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md):
    // dual-writes a row to equipment_catalog_requests AND emails tom@getchez.com.
    // Two trigger surfaces: photo-ID partial match (EquipmentIdentifySheet) and
    // text-search escape hatch (CatalogRequestSheet). Source field discriminates.

    struct CatalogRequestBody: Encodable {
        let brand: String?
        let systemType: String?      // Maps to submitted_product_type on the server
        let modelNumber: String?
        let serialNumber: String?    // Phase 4 — extracted by Claude Vision
        let notes: String?
        let source: String?          // "photo_label" / "text_search" / "manual"
        let imagePath: String?       // Phase 4 — Storage path of label photo
        let homeSystemId: String?    // Phase 4 — link to home_systems row that prompted this
        let userId: String?
        let householdId: String?
    }

    struct CatalogRequestResponse: Decodable {
        let success: Bool?
        let request_id: String?
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
            serialNumber: nil,
            notes: notes,
            source: "text_search",
            imagePath: nil,
            homeSystemId: nil,
            userId: currentUserId,
            householdId: user?.householdId?.uuidString
        )
        _ = try await callEdgeFunction(name: "send-catalog-request", body: body, timeoutSeconds: 15)
    }

    /// Phase 4 — submit a "Have Chez add this" request from the photo-ID
    /// partial-match flow. Claude Vision extracted brand/model/serial from
    /// the user's label photo but our catalog doesn't have that exact SKU.
    /// Returns the request_id so the caller can show "We're researching..." UX.
    static func submitPhotoCatalogRequest(
        brand: String?,
        modelNumber: String?,
        serialNumber: String?,
        productType: String?,
        imagePath: String? = nil,
        homeSystemId: String? = nil,
        notes: String? = nil
    ) async throws -> String? {
        let currentUserId = try? await client.auth.session.user.id.uuidString
        let user = try? await DatabaseService.shared.fetchCurrentUser()

        let body = CatalogRequestBody(
            brand: brand,
            systemType: productType,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            notes: notes,
            source: "photo_label",
            imagePath: imagePath,
            homeSystemId: homeSystemId,
            userId: currentUserId,
            householdId: user?.householdId?.uuidString
        )
        let data = try await callEdgeFunction(name: "send-catalog-request", body: body, timeoutSeconds: 15)
        let decoded = try? JSONDecoder().decode(CatalogRequestResponse.self, from: data)
        return decoded?.request_id
    }

    // MARK: - Process Invoice

    struct ProcessInvoiceRequest: Encodable {
        let documentId: String
        let propertyId: String?
        let householdId: String
        let vehicleId: String?
        /// Phase 59: optional vendor hint. When present (e.g. user uploads
        /// from ContractorDetailView), process-invoice skips vendor matching
        /// and stamps this contractor with "high" confidence.
        let preferredContractorId: String?

        enum CodingKeys: String, CodingKey {
            case documentId = "document_id"
            case propertyId = "property_id"
            case householdId = "household_id"
            case vehicleId = "vehicle_id"
            case preferredContractorId = "preferred_contractor_id"
        }
    }

    /// Process a home service invoice via AI to extract completed tasks, new systems, and service details.
    static func processInvoice(
        documentId: String,
        propertyId: String,
        householdId: String,
        preferredContractorId: String? = nil
    ) async throws -> InvoiceProcessingResult {
        let body = ProcessInvoiceRequest(
            documentId: documentId,
            propertyId: propertyId,
            householdId: householdId,
            vehicleId: nil,
            preferredContractorId: preferredContractorId
        )
        let data = try await callEdgeFunction(name: "process-invoice", body: body, timeoutSeconds: 120)
        return try JSONDecoder().decode(InvoiceProcessingResult.self, from: data)
    }

    /// Process a vehicle service invoice via AI to extract completed tasks, mileage, and service details.
    static func processVehicleInvoice(
        documentId: String,
        vehicleId: String,
        householdId: String,
        preferredContractorId: String? = nil
    ) async throws -> InvoiceProcessingResult {
        let body = ProcessInvoiceRequest(
            documentId: documentId,
            propertyId: nil,
            householdId: householdId,
            vehicleId: vehicleId,
            preferredContractorId: preferredContractorId
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

    /// Two-step brand logo lookup: try domain first, fall back to name search.
    /// Returns a response with logoUrl if found, nil if both attempts fail.
    static func fetchBrandLogoWithFallback(domain: String?, companyName: String) async -> BrandLogoResponse? {
        // Step 1: Try domain lookup if we have a website
        if let domain, !domain.isEmpty {
            let cleanDomain = domain
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .components(separatedBy: "/").first ?? domain
            if let response = try? await fetchBrandLogo(domain: cleanDomain),
               response.logoUrl != nil {
                return response
            }
        }
        // Step 2: Fall back to company name search (full name)
        if let response = try? await fetchBrandLogo(query: companyName),
           response.logoUrl != nil {
            return response
        }
        // Step 3: Try shortened name (strip LLC, Inc, suffixes, and text after commas)
        let shortened = companyName
            .components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces) ?? companyName
        if shortened != companyName, shortened.count >= 3 {
            if let response = try? await fetchBrandLogo(query: shortened),
               response.logoUrl != nil {
                return response
            }
        }
        return nil
    }

    // MARK: - Phase 19n: Find Local Vendors

    /// One vendor returned by `find-local-vendors`. The edge function caches
    /// these in `local_vendor_results` and refreshes via Google Places after
    /// 60 days. Top 2 are flagged `isTopRated` (>= 4.7 stars, >= 25
    /// reviews, no chain indicators); the next 2 are "Suggested".
    struct LocalVendorResult: Codable, Identifiable {
        let name: String
        let address: String?
        let phone: String?
        let website: String?
        let rating: Double?
        let reviewCount: Int?
        let googlePlaceId: String
        let isTopRated: Bool
        // Phase 72: real human-verified Chez Certified badge. True when this
        // vendor has status='chez_certified' in vendor_applications. Defaults
        // to false for backward compat with cached server responses that
        // pre-date the field.
        let isChezCertified: Bool
        // Phase X feedback: row sourced from the seeded `utility_providers`
        // catalog (the 15k+ regional vendors Tom sourced). When true,
        // FindLocalVendorSheet renders the row under a "FROM YOUR AREA"
        // section above the Google-derived tiers. Defaults to false so
        // cached responses that pre-date the field still decode cleanly.
        let isFromCatalog: Bool
        // Phase X feedback: logo + brand color carried through from the
        // catalog row when present. Lets the row card render the brand
        // identity without a fresh Brandfetch call — and lets the
        // adoption flow stamp the new contractor with the same assets.
        // Nil for Google-derived and vendor_application rows.
        let logoUrl: String?
        let brandColor: String?
        // Phase X+6: server-computed flag that the vendor actually
        // services the user's town (rather than just being state-wide).
        // For catalog rows: vendor's `regions` array contains the
        // user's town verbatim. For Google rows: vendor's formatted
        // address mentions the user's town. Drives both the "Top Picks"
        // sort boost and the on-card "Serves your area" pill. Defaults
        // to false for backward compat with cached server responses
        // pre-dating the field.
        let servesYourTown: Bool

        let rankPosition: Int

        var id: String { googlePlaceId }

        // Custom decoder gives the Phase 72 field a safe default so older
        // edge function payloads still round-trip cleanly.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try c.decode(String.self, forKey: .name)
            self.address = try? c.decodeIfPresent(String.self, forKey: .address)
            self.phone = try? c.decodeIfPresent(String.self, forKey: .phone)
            self.website = try? c.decodeIfPresent(String.self, forKey: .website)
            self.rating = try? c.decodeIfPresent(Double.self, forKey: .rating)
            self.reviewCount = try? c.decodeIfPresent(Int.self, forKey: .reviewCount)
            self.googlePlaceId = (try? c.decode(String.self, forKey: .googlePlaceId)) ?? ""
            self.isTopRated = (try? c.decode(Bool.self, forKey: .isTopRated)) ?? false
            self.isChezCertified = (try? c.decode(Bool.self, forKey: .isChezCertified)) ?? false
            self.isFromCatalog = (try? c.decode(Bool.self, forKey: .isFromCatalog)) ?? false
            self.logoUrl = try? c.decodeIfPresent(String.self, forKey: .logoUrl)
            self.brandColor = try? c.decodeIfPresent(String.self, forKey: .brandColor)
            self.servesYourTown = (try? c.decode(Bool.self, forKey: .servesYourTown)) ?? false
            self.rankPosition = (try? c.decode(Int.self, forKey: .rankPosition)) ?? 0
        }

        // Designated init for inline construction (e.g. quiz hydrate path).
        init(
            name: String,
            address: String?,
            phone: String?,
            website: String?,
            rating: Double?,
            reviewCount: Int?,
            googlePlaceId: String,
            isTopRated: Bool,
            isChezCertified: Bool = false,
            isFromCatalog: Bool = false,
            logoUrl: String? = nil,
            brandColor: String? = nil,
            servesYourTown: Bool = false,
            rankPosition: Int
        ) {
            self.name = name
            self.address = address
            self.phone = phone
            self.website = website
            self.rating = rating
            self.reviewCount = reviewCount
            self.googlePlaceId = googlePlaceId
            self.isTopRated = isTopRated
            self.isChezCertified = isChezCertified
            self.isFromCatalog = isFromCatalog
            self.logoUrl = logoUrl
            self.brandColor = brandColor
            self.servesYourTown = servesYourTown
            self.rankPosition = rankPosition
        }
    }

    struct LocalVendorResponse: Codable {
        let vendors: [LocalVendorResult]
        let cached: Bool?
    }

    private struct LocalVendorRequest: Encodable {
        let town: String
        let state: String
        let category: String
        /// Optional vendor-name filter. When set, the edge function
        /// ILIKE-matches `utility_providers.name` before town/state
        /// ranking — surfaces the catalog row first when a user types
        /// a specific vendor name in find-a-pro. Empty / nil → existing
        /// top-N-by-region behavior.
        let searchQuery: String?
    }

    /// Calls the `find-local-vendors` edge function. The function checks the
    /// cache first; on a miss it calls Google Places Text Search, ranks
    /// results, writes the cache, snapshots Google rows into the
    /// `utility_providers` catalog for permanence, and returns up to
    /// 10 catalog rows + up to 4 Google rows (2 Top-Rated + 2 Suggested).
    /// Empty `vendors` is a valid result — the iOS sheet renders an
    /// empty state in that case.
    ///
    /// `searchQuery` filters by vendor name (catalog ILIKE + Google
    /// Places "<query> in <town>, <state>" search). Used by the
    /// debounced search bar in FindLocalVendorSheet.
    static func findLocalVendors(
        town: String,
        state: String,
        category: String,
        searchQuery: String? = nil
    ) async throws -> LocalVendorResponse {
        let data = try await callEdgeFunction(
            name: "find-local-vendors",
            body: LocalVendorRequest(
                town: town,
                state: state,
                category: category,
                searchQuery: searchQuery
            ),
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
            body: LocalVendorRequest(
                town: town,
                state: state,
                category: advisorType,
                searchQuery: nil
            ),
            timeoutSeconds: 30
        )
        return try JSONDecoder().decode(LocalVendorResponse.self, from: data)
    }

    // MARK: - Chez v1: Find Network Handymen

    /// One Chez Field provider returned by `find-network-handymen`. These
    /// are companies who registered via the desktop command center
    /// (havenhome.dev/handyman) and explicitly opted into the homeowner
    /// directory. Surfaced ABOVE Google Places results in
    /// `FindLocalVendorSheet` because they're already in the network.
    struct ChezFieldProvider: Codable, Identifiable {
        let id: String
        let workspaceId: String
        let name: String
        let phone: String?
        let website: String?
        let city: String?
        let state: String?
        let blurb: String?
        let headshotUrl: String?
        let rating: Double?
        let reviewCount: Int
        let categories: [String]
        let source: String

        enum CodingKeys: String, CodingKey {
            case id, workspaceId, name, phone, website, city, state, blurb
            case headshotUrl, rating, reviewCount, categories, source
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
            workspaceId = (try? c.decodeIfPresent(String.self, forKey: .workspaceId)) ?? ""
            name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? ""
            phone = try? c.decodeIfPresent(String.self, forKey: .phone)
            website = try? c.decodeIfPresent(String.self, forKey: .website)
            city = try? c.decodeIfPresent(String.self, forKey: .city)
            state = try? c.decodeIfPresent(String.self, forKey: .state)
            blurb = try? c.decodeIfPresent(String.self, forKey: .blurb)
            headshotUrl = try? c.decodeIfPresent(String.self, forKey: .headshotUrl)
            rating = try? c.decodeIfPresent(Double.self, forKey: .rating)
            reviewCount = (try? c.decodeIfPresent(Int.self, forKey: .reviewCount)) ?? 0
            categories = (try? c.decodeIfPresent([String].self, forKey: .categories)) ?? []
            source = (try? c.decodeIfPresent(String.self, forKey: .source)) ?? "chez_field"
        }
    }

    struct ChezFieldProviderResponse: Codable {
        let providers: [ChezFieldProvider]
    }

    private struct NetworkHandymanRequest: Encodable {
        let town: String?
        let state: String?
        let zip: String?
        let category: String
        let searchQuery: String?
        let nationwide: Bool?

        enum CodingKeys: String, CodingKey {
            case town, state, zip, category, searchQuery, nationwide
        }
    }

    // MARK: - Phase 73 follow-up: link adopted handyman to workspace

    private struct LinkAdoptedProviderRequest: Encodable {
        let action = "link_adopted_provider"
        let workspaceId: String
        let contractorId: String
    }

    struct LinkAdoptedProviderResponse: Codable {
        let linked: Bool
        let alreadyLinked: Bool?
        let isPrimary: Bool?
    }

    /// Calls the `handyman-provider` edge function's
    /// `link_adopted_provider` action. Validates the homeowner adoption
    /// chain server-side (auth user owns contractor, contractor's notes
    /// reference the workspace, workspace is directory-listed) and then
    /// inserts the missing `provider_contractor_links` row so the
    /// provider's dispatch board surfaces the household. Idempotent.
    static func linkAdoptedHandymanProvider(
        workspaceId: UUID,
        contractorId: UUID
    ) async throws -> LinkAdoptedProviderResponse {
        let data = try await callEdgeFunction(
            name: "handyman-provider",
            body: LinkAdoptedProviderRequest(
                workspaceId: workspaceId.uuidString,
                contractorId: contractorId.uuidString
            ),
            timeoutSeconds: 15
        )
        return try JSONDecoder().decode(LinkAdoptedProviderResponse.self, from: data)
    }

    /// Calls the `find-network-handymen` edge function in either of two
    /// modes:
    ///
    /// - **Auto-match (default).** Pass `searchQuery == nil`. The function
    ///   filters by state + category + listed-flag, then drops providers
    ///   whose populated `service_zip_codes` don't match the homeowner's
    ///   zip-prefix or city. Capped at 5 results. This is the path the
    ///   `FindLocalVendorSheet` uses to render the ON CHEZ section
    ///   alongside Google Places.
    ///
    /// - **Directory search.** Pass any non-nil `searchQuery` (empty string
    ///   is fine for an unfiltered initial browse; non-empty triggers an
    ///   ILIKE filter across `company_name` + `display_blurb`). The
    ///   function skips the zip/city filter entirely and caps at 25. Set
    ///   `nationwide = true` to also drop the state filter — used by the
    ///   "Show pros nationwide" toggle in `ChezDirectorySearchView`.
    ///
    /// Empty `providers` is a valid result. Callers should render an empty
    /// state rather than treating it as an error.
    static func findNetworkHandymen(
        town: String? = nil,
        state: String,
        zip: String? = nil,
        category: String = "handyman",
        searchQuery: String? = nil,
        nationwide: Bool = false
    ) async throws -> ChezFieldProviderResponse {
        let data = try await callEdgeFunction(
            name: "find-network-handymen",
            body: NetworkHandymanRequest(
                town: town,
                state: state.isEmpty ? nil : state,
                zip: zip,
                category: category,
                searchQuery: searchQuery,
                nationwide: nationwide ? true : nil
            ),
            timeoutSeconds: 15
        )
        return try JSONDecoder().decode(ChezFieldProviderResponse.self, from: data)
    }
}
