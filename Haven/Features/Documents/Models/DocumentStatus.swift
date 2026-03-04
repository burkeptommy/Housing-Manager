import Foundation

enum DocumentStatus: String, Codable {
    case active
    case expired
    case expiringSoon
    case needsReview
    case missing
    case superseded
    case archived
}
