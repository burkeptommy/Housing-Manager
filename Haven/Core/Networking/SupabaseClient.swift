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

    // MARK: - Edge Function Direct Caller

    /// Call a Supabase Edge Function directly via URLRequest, bypassing the SDK's invoke method
    /// which can fail to parse certain response formats.
    private static func callEdgeFunction(
        name: String,
        body: Encodable,
        timeoutSeconds: TimeInterval = 120
    ) async throws -> Data {
        // Refresh session first
        _ = try? await client.auth.refreshSession()

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

        // Add auth token if available
        if let accessToken = try? await client.auth.session.accessToken {
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

        enum CodingKeys: String, CodingKey {
            case message
            case conversationHistory = "conversation_history"
            case contextType = "context_type"
            case contextId = "context_id"
            case householdId = "household_id"
            case encryptionKey = "encryption_key"
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

    static func chat(message: String, history: [[String: String]], contextType: String?, contextId: String?, householdId: String, encryptionKey: String? = nil) async throws -> Data {
        let body = ChatRequest(
            message: message,
            conversationHistory: history,
            contextType: contextType,
            contextId: contextId,
            householdId: householdId,
            encryptionKey: encryptionKey
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

        enum CodingKeys: String, CodingKey {
            case action
            case inboxItemId = "inbox_item_id"
            case propertyId = "property_id"
            case documentCategory = "document_category"
        }
    }

    static func processInboxItem(
        inboxItemId: String,
        propertyId: String? = nil,
        action: String,
        documentCategory: String? = nil
    ) async throws -> Data {
        let body = ProcessInboxItemRequest(
            inboxItemId: inboxItemId,
            propertyId: propertyId,
            action: action,
            documentCategory: documentCategory
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
}
