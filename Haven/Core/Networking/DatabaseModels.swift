import Foundation

// MARK: - Database Row Types
// These match Supabase table columns (snake_case via CodingKeys).
// Used for decoding responses and encoding inserts/updates.

// MARK: - Household

struct HouseholdRow: Codable, Identifiable {
    let id: UUID
    let name: String
    let createdAt: Date?
    let subscriptionTier: String?
    let subscriptionExpiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt = "created_at"
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
    }
}

struct HouseholdInsert: Codable {
    let name: String
    let subscriptionTier: String?

    enum CodingKeys: String, CodingKey {
        case name
        case subscriptionTier = "subscription_tier"
    }
}

struct HouseholdUpdate: Codable {
    var name: String?
    var subscriptionTier: String?
    var subscriptionExpiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case name
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
    }
}

// MARK: - User

struct UserRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID?
    let email: String
    let fullName: String?
    let role: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case householdId = "household_id"
        case fullName = "full_name"
        case createdAt = "created_at"
    }
}

struct UserInsert: Codable {
    let id: UUID
    let householdId: UUID?
    let email: String
    let fullName: String?
    let role: String

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case householdId = "household_id"
        case fullName = "full_name"
    }
}

struct UserUpdate: Codable {
    var householdId: UUID?
    var fullName: String?
    var role: String?

    enum CodingKeys: String, CodingKey {
        case role
        case householdId = "household_id"
        case fullName = "full_name"
    }
}

// MARK: - Family Member

struct FamilyMemberRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let firstName: String
    let lastName: String
    let relationship: String
    let dateOfBirth: String?
    let email: String?
    let phone: String?
    let isMinor: Bool?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, relationship, email, phone, notes
        case householdId = "household_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case isMinor = "is_minor"
        case createdAt = "created_at"
    }
}

struct FamilyMemberInsert: Codable {
    let householdId: UUID
    let firstName: String
    let lastName: String
    let relationship: String
    var dateOfBirth: String?
    var email: String?
    var phone: String?
    var isMinor: Bool?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case relationship, email, phone, notes
        case householdId = "household_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case isMinor = "is_minor"
    }
}

struct FamilyMemberUpdate: Codable {
    var firstName: String?
    var lastName: String?
    var relationship: String?
    var dateOfBirth: String?
    var email: String?
    var phone: String?
    var isMinor: Bool?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case relationship, email, phone, notes
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case isMinor = "is_minor"
    }
}

// MARK: - Document

struct DocumentRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let title: String
    let category: String
    let status: String
    let filePath: String
    let thumbnailPath: String?
    let expirationDate: String?
    let renewalDate: String?
    let effectiveDate: String?
    let issuingInstitution: String?
    let accountNumberLast4: String?
    let notes: String?
    let tags: [String]?
    let aiSummary: String?
    let aiFlags: [AIFlag]?
    let propertyId: UUID?
    let uploadedAt: Date?
    let lastReviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, category, status, notes, tags
        case householdId = "household_id"
        case filePath = "file_path"
        case thumbnailPath = "thumbnail_path"
        case expirationDate = "expiration_date"
        case renewalDate = "renewal_date"
        case effectiveDate = "effective_date"
        case issuingInstitution = "issuing_institution"
        case accountNumberLast4 = "account_number_last4"
        case aiSummary = "ai_summary"
        case aiFlags = "ai_flags"
        case propertyId = "property_id"
        case uploadedAt = "uploaded_at"
        case lastReviewedAt = "last_reviewed_at"
    }
}

struct AIFlag: Codable, Identifiable {
    var id: String { message }
    let severity: String // "critical", "warning", "info"
    let message: String
}

struct DocumentInsert: Codable {
    let householdId: UUID
    let title: String
    let category: String
    let filePath: String
    var status: String?
    var thumbnailPath: String?
    var expirationDate: String?
    var renewalDate: String?
    var effectiveDate: String?
    var issuingInstitution: String?
    var accountNumberLast4: String?
    var notes: String?
    var tags: [String]?
    var propertyId: UUID?

    enum CodingKeys: String, CodingKey {
        case title, category, status, notes, tags
        case householdId = "household_id"
        case filePath = "file_path"
        case thumbnailPath = "thumbnail_path"
        case expirationDate = "expiration_date"
        case renewalDate = "renewal_date"
        case effectiveDate = "effective_date"
        case issuingInstitution = "issuing_institution"
        case accountNumberLast4 = "account_number_last4"
        case propertyId = "property_id"
    }
}

struct DocumentUpdate: Codable {
    var title: String?
    var category: String?
    var status: String?
    var expirationDate: String?
    var renewalDate: String?
    var effectiveDate: String?
    var issuingInstitution: String?
    var accountNumberLast4: String?
    var notes: String?
    var tags: [String]?
    var aiSummary: String?
    var aiFlags: [AIFlag]?
    var lastReviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case title, category, status, notes, tags
        case expirationDate = "expiration_date"
        case renewalDate = "renewal_date"
        case effectiveDate = "effective_date"
        case issuingInstitution = "issuing_institution"
        case accountNumberLast4 = "account_number_last4"
        case aiSummary = "ai_summary"
        case aiFlags = "ai_flags"
        case lastReviewedAt = "last_reviewed_at"
    }
}

// MARK: - Property

struct PropertyRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let name: String
    let propertyType: String
    let street: String?
    let unit: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let purchaseDate: String?
    let purchasePrice: Double?
    let currentEstimatedValue: Double?
    let squareFootage: Int?
    let yearBuilt: Int?
    let ownershipEntity: String?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, street, unit, city, state, notes
        case householdId = "household_id"
        case propertyType = "property_type"
        case zipCode = "zip_code"
        case country
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentEstimatedValue = "current_estimated_value"
        case squareFootage = "square_footage"
        case yearBuilt = "year_built"
        case ownershipEntity = "ownership_entity"
        case createdAt = "created_at"
    }
}

struct PropertyInsert: Codable {
    let householdId: UUID
    let name: String
    let propertyType: String
    var street: String?
    var unit: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var purchaseDate: String?
    var purchasePrice: Double?
    var currentEstimatedValue: Double?
    var squareFootage: Int?
    var yearBuilt: Int?
    var ownershipEntity: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, street, unit, city, state, notes, country
        case householdId = "household_id"
        case propertyType = "property_type"
        case zipCode = "zip_code"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentEstimatedValue = "current_estimated_value"
        case squareFootage = "square_footage"
        case yearBuilt = "year_built"
        case ownershipEntity = "ownership_entity"
    }
}

struct PropertyUpdate: Codable {
    var name: String?
    var propertyType: String?
    var street: String?
    var unit: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var purchasePrice: Double?
    var currentEstimatedValue: Double?
    var squareFootage: Int?
    var yearBuilt: Int?
    var ownershipEntity: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, street, unit, city, state, notes
        case propertyType = "property_type"
        case zipCode = "zip_code"
        case purchasePrice = "purchase_price"
        case currentEstimatedValue = "current_estimated_value"
        case squareFootage = "square_footage"
        case yearBuilt = "year_built"
        case ownershipEntity = "ownership_entity"
    }
}

// MARK: - Home System

struct HomeSystemRow: Codable, Identifiable {
    let id: UUID
    let propertyId: UUID
    let householdId: UUID
    let name: String
    let category: String
    let manufacturer: String?
    let modelNumber: String?
    let serialNumber: String?
    let installDate: String?
    let expectedLifespanYears: Int?
    let status: String?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, category, manufacturer, notes, status
        case propertyId = "property_id"
        case householdId = "household_id"
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case expectedLifespanYears = "expected_lifespan_years"
        case createdAt = "created_at"
    }
}

struct HomeSystemInsert: Codable {
    let propertyId: UUID
    let householdId: UUID
    let name: String
    let category: String
    var manufacturer: String?
    var modelNumber: String?
    var serialNumber: String?
    var installDate: String?
    var expectedLifespanYears: Int?
    var status: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, category, manufacturer, notes, status
        case propertyId = "property_id"
        case householdId = "household_id"
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case expectedLifespanYears = "expected_lifespan_years"
    }
}

struct HomeSystemUpdate: Codable {
    var name: String?
    var category: String?
    var manufacturer: String?
    var modelNumber: String?
    var serialNumber: String?
    var installDate: String?
    var expectedLifespanYears: Int?
    var status: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, category, manufacturer, notes, status
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case expectedLifespanYears = "expected_lifespan_years"
    }
}

// MARK: - Warranty

struct WarrantyRow: Codable, Identifiable {
    let id: UUID
    let systemId: UUID?
    let householdId: UUID
    let provider: String
    let warrantyType: String
    let startDate: String
    let endDate: String
    let coverageDetails: String?
    let claimPhone: String?
    let policyNumber: String?
    let linkedDocumentId: UUID?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, provider
        case systemId = "system_id"
        case householdId = "household_id"
        case warrantyType = "warranty_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case coverageDetails = "coverage_details"
        case claimPhone = "claim_phone"
        case policyNumber = "policy_number"
        case linkedDocumentId = "linked_document_id"
        case createdAt = "created_at"
    }
}

struct WarrantyInsert: Codable {
    let householdId: UUID
    let provider: String
    let warrantyType: String
    let startDate: String
    let endDate: String
    var systemId: UUID?
    var coverageDetails: String?
    var claimPhone: String?
    var policyNumber: String?
    var linkedDocumentId: UUID?

    enum CodingKeys: String, CodingKey {
        case provider
        case householdId = "household_id"
        case systemId = "system_id"
        case warrantyType = "warranty_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case coverageDetails = "coverage_details"
        case claimPhone = "claim_phone"
        case policyNumber = "policy_number"
        case linkedDocumentId = "linked_document_id"
    }
}

struct WarrantyUpdate: Codable {
    var provider: String?
    var warrantyType: String?
    var startDate: String?
    var endDate: String?
    var coverageDetails: String?
    var claimPhone: String?
    var policyNumber: String?
    var linkedDocumentId: UUID?

    enum CodingKeys: String, CodingKey {
        case provider
        case warrantyType = "warranty_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case coverageDetails = "coverage_details"
        case claimPhone = "claim_phone"
        case policyNumber = "policy_number"
        case linkedDocumentId = "linked_document_id"
    }
}

// MARK: - Contractor

struct ContractorRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let companyName: String
    let contactName: String?
    let phone: String
    let email: String?
    let specialties: [String]?
    let address: String?
    let licenseNumber: String?
    let insuranceVerified: Bool?
    let rating: Int?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, phone, email, specialties, address, rating, notes
        case householdId = "household_id"
        case companyName = "company_name"
        case contactName = "contact_name"
        case licenseNumber = "license_number"
        case insuranceVerified = "insurance_verified"
        case createdAt = "created_at"
    }
}

struct ContractorInsert: Codable {
    let householdId: UUID
    let companyName: String
    let phone: String
    var contactName: String?
    var email: String?
    var specialties: [String]?
    var address: String?
    var licenseNumber: String?
    var insuranceVerified: Bool?
    var rating: Int?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case phone, email, specialties, address, rating, notes
        case householdId = "household_id"
        case companyName = "company_name"
        case contactName = "contact_name"
        case licenseNumber = "license_number"
        case insuranceVerified = "insurance_verified"
    }
}

struct ContractorUpdate: Codable {
    var companyName: String?
    var contactName: String?
    var phone: String?
    var email: String?
    var specialties: [String]?
    var address: String?
    var licenseNumber: String?
    var insuranceVerified: Bool?
    var rating: Int?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case phone, email, specialties, address, rating, notes
        case companyName = "company_name"
        case contactName = "contact_name"
        case licenseNumber = "license_number"
        case insuranceVerified = "insurance_verified"
    }
}

// MARK: - Maintenance Task

struct MaintenanceTaskDBRow: Codable, Identifiable {
    let id: UUID
    let systemId: UUID?
    let propertyId: UUID
    let householdId: UUID
    let title: String
    let description: String?
    let frequency: String
    let lastCompletedDate: String?
    let nextDueDate: String
    let estimatedCost: Double?
    let priority: String?
    let assignedContractorId: UUID?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, frequency, notes, priority
        case systemId = "system_id"
        case propertyId = "property_id"
        case householdId = "household_id"
        case lastCompletedDate = "last_completed_date"
        case nextDueDate = "next_due_date"
        case estimatedCost = "estimated_cost"
        case assignedContractorId = "assigned_contractor_id"
        case createdAt = "created_at"
    }
}

struct MaintenanceTaskInsert: Codable {
    let propertyId: UUID
    let householdId: UUID
    let title: String
    let frequency: String
    let nextDueDate: String
    var systemId: UUID?
    var description: String?
    var lastCompletedDate: String?
    var estimatedCost: Double?
    var priority: String?
    var assignedContractorId: UUID?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case title, description, frequency, notes, priority
        case propertyId = "property_id"
        case householdId = "household_id"
        case systemId = "system_id"
        case lastCompletedDate = "last_completed_date"
        case nextDueDate = "next_due_date"
        case estimatedCost = "estimated_cost"
        case assignedContractorId = "assigned_contractor_id"
    }
}

struct MaintenanceTaskUpdate: Codable {
    var title: String?
    var description: String?
    var frequency: String?
    var lastCompletedDate: String?
    var nextDueDate: String?
    var estimatedCost: Double?
    var priority: String?
    var assignedContractorId: UUID?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case title, description, frequency, notes, priority
        case lastCompletedDate = "last_completed_date"
        case nextDueDate = "next_due_date"
        case estimatedCost = "estimated_cost"
        case assignedContractorId = "assigned_contractor_id"
    }
}

// MARK: - Service Record

struct ServiceRecordRow: Codable, Identifiable {
    let id: UUID
    let systemId: UUID?
    let propertyId: UUID
    let householdId: UUID
    let contractorId: UUID?
    let serviceDate: String
    let serviceType: String
    let description: String
    let cost: Double?
    let invoiceDocumentId: UUID?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, description, cost, notes
        case systemId = "system_id"
        case propertyId = "property_id"
        case householdId = "household_id"
        case contractorId = "contractor_id"
        case serviceDate = "service_date"
        case serviceType = "service_type"
        case invoiceDocumentId = "invoice_document_id"
        case createdAt = "created_at"
    }
}

struct ServiceRecordInsert: Codable {
    let propertyId: UUID
    let householdId: UUID
    let serviceDate: String
    let serviceType: String
    let description: String
    var systemId: UUID?
    var contractorId: UUID?
    var cost: Double?
    var invoiceDocumentId: UUID?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case description, cost, notes
        case propertyId = "property_id"
        case householdId = "household_id"
        case systemId = "system_id"
        case contractorId = "contractor_id"
        case serviceDate = "service_date"
        case serviceType = "service_type"
        case invoiceDocumentId = "invoice_document_id"
    }
}

// MARK: - Chat Message

struct ChatMessageRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    let role: String
    let content: String
    let contextType: String?
    let contextId: UUID?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case householdId = "household_id"
        case userId = "user_id"
        case contextType = "context_type"
        case contextId = "context_id"
        case createdAt = "created_at"
    }
}

struct ChatMessageInsert: Codable {
    let householdId: UUID
    let userId: UUID
    let role: String
    let content: String
    var contextType: String?
    var contextId: UUID?

    enum CodingKeys: String, CodingKey {
        case role, content
        case householdId = "household_id"
        case userId = "user_id"
        case contextType = "context_type"
        case contextId = "context_id"
    }
}

// MARK: - Document Family Member Junction

struct DocumentFamilyMemberRow: Codable {
    let documentId: UUID
    let familyMemberId: UUID

    enum CodingKeys: String, CodingKey {
        case documentId = "document_id"
        case familyMemberId = "family_member_id"
    }
}

struct DocumentFamilyMemberInsert: Codable {
    let documentId: UUID
    let familyMemberId: UUID

    enum CodingKeys: String, CodingKey {
        case documentId = "document_id"
        case familyMemberId = "family_member_id"
    }
}

// MARK: - Completion Score

struct CompletionScoreRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let category: String
    let expectedCount: Int?
    let actualCount: Int?
    let completionPercentage: Double?
    let lastCalculatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, category
        case householdId = "household_id"
        case expectedCount = "expected_count"
        case actualCount = "actual_count"
        case completionPercentage = "completion_percentage"
        case lastCalculatedAt = "last_calculated_at"
    }
}

struct CompletionScoreInsert: Codable {
    let householdId: UUID
    let category: String
    var expectedCount: Int?
    var actualCount: Int?
    var completionPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case category
        case householdId = "household_id"
        case expectedCount = "expected_count"
        case actualCount = "actual_count"
        case completionPercentage = "completion_percentage"
    }
}
