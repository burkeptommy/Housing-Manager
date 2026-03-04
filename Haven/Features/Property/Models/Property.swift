import Foundation

struct Property: Identifiable, Codable {
    let id: UUID
    var name: String
    var address: PropertyAddress
    var propertyType: PropertyType
    var purchaseDate: Date?
    var purchasePrice: Decimal?
    var currentEstimatedValue: Decimal?
    var squareFootage: Int?
    var yearBuilt: Int?
    var ownershipEntity: String?
    var linkedDocumentIds: [UUID]
    var systems: [HomeSystem]
    var imageURLs: [URL]
    var notes: String?
}

enum PropertyType: String, Codable, CaseIterable {
    case primaryResidence = "Primary Residence"
    case vacationHome = "Vacation Home"
    case rentalProperty = "Rental Property"
    case commercial = "Commercial"
    case land = "Land"
}

struct PropertyAddress: Codable {
    var street: String
    var unit: String?
    var city: String
    var state: String
    var zipCode: String
    var country: String

    var formatted: String {
        let parts = [street, unit, city, "\(state) \(zipCode)"].compactMap { $0 }
        return parts.joined(separator: ", ")
    }
}
