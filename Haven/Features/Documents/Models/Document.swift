import Foundation

struct HavenDocument: Identifiable, Codable {
    let id: UUID
    var title: String
    var category: DocumentCategory
    var familyMemberIds: [UUID]
    var propertyId: UUID?
    var fileURL: URL
    var thumbnailURL: URL?
    var status: DocumentStatus
    var expirationDate: Date?
    var renewalDate: Date?
    var effectiveDate: Date?
    var issuingInstitution: String?
    var accountNumber: String?
    var notes: String?
    var tags: [String]
    var aiSummary: String?
    var aiFlags: [DocumentFlag]?
    var linkedDocumentIds: [UUID]
    var uploadedAt: Date
    var lastReviewedAt: Date?
    var metadata: [String: String]
}

struct DocumentFlag: Identifiable, Codable {
    let id: UUID
    let severity: FlagSeverity
    let message: String
    let relatedDocumentIds: [UUID]
    let createdAt: Date
    var resolvedAt: Date?
}

enum FlagSeverity: String, Codable {
    case critical
    case warning
    case info
}
