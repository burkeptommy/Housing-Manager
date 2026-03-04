import Foundation

struct Warranty: Identifiable, Codable {
    let id: UUID
    var provider: String
    var type: WarrantyType
    var startDate: Date
    var endDate: Date
    var coverageDetails: String?
    var claimPhone: String?
    var policyNumber: String?
    var linkedDocumentId: UUID?

    var isActive: Bool { Date() < endDate }

    var isExpiringSoon: Bool {
        guard let ninetyDays = Calendar.current.date(byAdding: .day, value: 90, to: Date()) else { return false }
        return Date() < endDate && endDate < ninetyDays
    }

    var daysRemaining: Int? {
        guard isActive else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
    }
}

enum WarrantyType: String, Codable {
    case manufacturer = "Manufacturer"
    case extended = "Extended"
    case homeWarranty = "Home Warranty"
    case laborWarranty = "Labor Warranty"
}
