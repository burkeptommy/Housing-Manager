import Foundation
import Supabase

/// Singleton Supabase client for Haven.
/// Provides typed access to database, auth, storage, and Edge Functions.
enum HavenSupabase {
    static let client = SupabaseClient(
        supabaseURL: URL(string: AppConfig.Supabase.url)!,
        supabaseKey: AppConfig.Supabase.anonKey
    )

    static var db: PostgrestClient {
        client.database
    }

    static var auth: AuthClient {
        client.auth
    }

    static var storage: SupabaseStorageClient {
        client.storage
    }

    // MARK: - Edge Functions

    struct AnalyzeDocumentRequest: Encodable {
        let documentId: String
        let text: String?
        let imageBase64: String?
        let householdId: String

        enum CodingKeys: String, CodingKey {
            case documentId = "document_id"
            case text
            case imageBase64 = "image_base64"
            case householdId = "household_id"
        }
    }

    struct ChatRequest: Encodable {
        let message: String
        let conversationHistory: [[String: String]]
        let contextType: String?
        let contextId: String?
        let householdId: String

        enum CodingKeys: String, CodingKey {
            case message
            case conversationHistory = "conversation_history"
            case contextType = "context_type"
            case contextId = "context_id"
            case householdId = "household_id"
        }
    }

    struct GapAnalysisRequest: Encodable {
        let householdId: String

        enum CodingKeys: String, CodingKey {
            case householdId = "household_id"
        }
    }

    static func analyzeDocument(documentId: String, text: String?, imageBase64: String?, householdId: String) async throws -> Data {
        let body = AnalyzeDocumentRequest(
            documentId: documentId,
            text: text,
            imageBase64: imageBase64,
            householdId: householdId
        )
        return try await client.functions.invoke(
            "analyze-document",
            options: .init(body: body)
        )
    }

    static func chat(message: String, history: [[String: String]], contextType: String?, contextId: String?, householdId: String) async throws -> Data {
        let body = ChatRequest(
            message: message,
            conversationHistory: history,
            contextType: contextType,
            contextId: contextId,
            householdId: householdId
        )
        return try await client.functions.invoke(
            "chat",
            options: .init(body: body)
        )
    }

    static func gapAnalysis(householdId: String) async throws -> Data {
        let body = GapAnalysisRequest(householdId: householdId)
        return try await client.functions.invoke(
            "gap-analysis",
            options: .init(body: body)
        )
    }
}
