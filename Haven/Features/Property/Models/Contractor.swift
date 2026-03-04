import Foundation

struct Contractor: Identifiable, Codable {
    let id: UUID
    var companyName: String
    var contactName: String?
    var phone: String
    var email: String?
    var specialty: [SystemCategory]
    var address: String?
    var licenseNumber: String?
    var insuranceVerified: Bool
    var rating: Int?
    var notes: String?
    var serviceHistory: [ServiceRecord]
}
