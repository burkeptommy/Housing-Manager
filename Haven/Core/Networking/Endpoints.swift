import Foundation

/// Legacy endpoints — replaced by DatabaseService + Supabase client.
/// Kept as stub to avoid breaking APIClient references during migration.
enum Endpoints {
    case getDocuments
    case getProperties
    case getProfile

    func urlRequest() throws -> URLRequest {
        URLRequest(url: URL(string: "https://api.havenhome.dev/api")!)
    }
}
