import Foundation

struct ServiceRecord: Identifiable, Codable {
    let id: UUID
    var systemId: UUID
    var propertyId: UUID
    var contractorId: UUID?
    var date: Date
    var type: ServiceType
    var description: String
    var cost: Decimal?
    var invoiceDocumentId: UUID?
    var warrantyClaimId: UUID?
    var notes: String?
    var beforeImageURLs: [URL]
    var afterImageURLs: [URL]
}

enum ServiceType: String, Codable, CaseIterable {
    case repair = "Repair"
    case maintenance = "Maintenance"
    case inspection = "Inspection"
    case installation = "Installation"
    case replacement = "Replacement"
    case emergency = "Emergency"
}
