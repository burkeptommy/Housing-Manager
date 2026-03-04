import Foundation

struct FamilyMember: Identifiable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var relationship: FamilyRelationship
    var dateOfBirth: Date?
    var email: String?
    var phone: String?
    var isMinor: Bool
    var notes: String?

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

enum FamilyRelationship: String, Codable, CaseIterable {
    case primary = "Primary Client"
    case spouse = "Spouse/Partner"
    case child = "Child"
    case grandchild = "Grandchild"
    case parent = "Parent"
    case sibling = "Sibling"
    case trustee = "Trustee"
    case executor = "Executor"
    case beneficiary = "Beneficiary"
    case guardian = "Guardian"
    case other = "Other"
}
