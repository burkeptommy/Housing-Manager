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

struct FamilyMemberRow: Codable, Identifiable, Hashable {
    let id: UUID
    let householdId: UUID
    let firstName: String
    let lastName: String
    let relationship: String
    let dateOfBirth: String?
    let email: String?
    let phone: String?
    let isMinor: Bool?
    let gender: String?
    let avatarColor: String?
    let expectedDate: String?
    let isExpecting: Bool?
    let legalName: String?
    let notes: String?
    let createdAt: Date?
    let linkedUserId: UUID?

    /// Whether this family member has a linked Haven account
    var isLinkedUser: Bool { linkedUserId != nil }

    enum CodingKeys: String, CodingKey {
        case id, relationship, email, phone, notes, gender
        case householdId = "household_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case isMinor = "is_minor"
        case avatarColor = "avatar_color"
        case expectedDate = "expected_date"
        case isExpecting = "is_expecting"
        case legalName = "legal_name"
        case createdAt = "created_at"
        case linkedUserId = "linked_user_id"
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
    var gender: String?
    var avatarColor: String?
    var expectedDate: String?
    var isExpecting: Bool?
    var legalName: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case relationship, email, phone, notes, gender
        case householdId = "household_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case isMinor = "is_minor"
        case avatarColor = "avatar_color"
        case expectedDate = "expected_date"
        case isExpecting = "is_expecting"
        case legalName = "legal_name"
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
    var gender: String?
    var avatarColor: String?
    var expectedDate: String?
    var isExpecting: Bool?
    var legalName: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case relationship, email, phone, notes, gender
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case isMinor = "is_minor"
        case avatarColor = "avatar_color"
        case expectedDate = "expected_date"
        case isExpecting = "is_expecting"
        case legalName = "legal_name"
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
    let vaultLocked: Bool?
    let vaultLockIv: String?
    let contentHash: String?
    let fileSize: Int?
    let deletedAt: String?
    let metadata: DocumentMetadata?

    enum CodingKeys: String, CodingKey {
        case id, title, category, status, notes, tags, metadata
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
        case vaultLocked = "vault_locked"
        case vaultLockIv = "vault_lock_iv"
        case contentHash = "content_hash"
        case fileSize = "file_size"
        case deletedAt = "deleted_at"
    }
}

struct DocumentMetadata: Codable {
    let crossReferences: [String]?
    let extractedMetadata: [String: FlexibleValue]?

    enum CodingKeys: String, CodingKey {
        case crossReferences = "cross_references"
        case extractedMetadata = "extracted_metadata"
    }

    init(crossReferences: [String]? = nil, extractedMetadata: [String: FlexibleValue]? = nil) {
        self.crossReferences = crossReferences
        self.extractedMetadata = extractedMetadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        crossReferences = try? container.decode([String].self, forKey: .crossReferences)
        extractedMetadata = try? container.decode([String: FlexibleValue].self, forKey: .extractedMetadata)
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
    var contentHash: String?
    var fileSize: Int?

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
        case contentHash = "content_hash"
        case fileSize = "file_size"
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
    var vaultLocked: Bool?
    var vaultLockIv: String?
    var propertyId: UUID?
    var metadata: DocumentMetadata?
    var contentHash: String?
    var fileSize: Int?

    enum CodingKeys: String, CodingKey {
        case title, category, status, notes, tags, metadata
        case expirationDate = "expiration_date"
        case renewalDate = "renewal_date"
        case effectiveDate = "effective_date"
        case issuingInstitution = "issuing_institution"
        case accountNumberLast4 = "account_number_last4"
        case aiSummary = "ai_summary"
        case aiFlags = "ai_flags"
        case lastReviewedAt = "last_reviewed_at"
        case vaultLocked = "vault_locked"
        case vaultLockIv = "vault_lock_iv"
        case propertyId = "property_id"
        case contentHash = "content_hash"
        case fileSize = "file_size"
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
    let attributes: [String: FlexibleValue]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, street, unit, city, state, notes, attributes
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
    var attributes: [String: FlexibleValue]?

    enum CodingKeys: String, CodingKey {
        case name, street, unit, city, state, notes, attributes
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
    let preferredContractorId: UUID?
    let lastServiceDate: String?
    let nextServiceDue: String?
    let totalSpent: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, category, manufacturer, notes, status
        case propertyId = "property_id"
        case householdId = "household_id"
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case expectedLifespanYears = "expected_lifespan_years"
        case createdAt = "created_at"
        case preferredContractorId = "preferred_contractor_id"
        case lastServiceDate = "last_service_date"
        case nextServiceDue = "next_service_due"
        case totalSpent = "total_spent"
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
    var preferredContractorId: UUID?
    var lastServiceDate: String?
    var nextServiceDue: String?
    var totalSpent: Double?

    enum CodingKeys: String, CodingKey {
        case name, category, manufacturer, notes, status
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case expectedLifespanYears = "expected_lifespan_years"
        case preferredContractorId = "preferred_contractor_id"
        case lastServiceDate = "last_service_date"
        case nextServiceDue = "next_service_due"
        case totalSpent = "total_spent"
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
    let assignedToUserId: UUID?
    let notes: String?
    let createdAt: Date?
    let isTemplateBased: Bool?
    let templateId: String?
    let seasonalTiming: String?
    let isDiy: Bool?
    let professionalRequired: Bool?
    let costRange: String?
    let lastEmailSentAt: Date?
    let recurrenceRule: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, frequency, notes, priority
        case systemId = "system_id"
        case propertyId = "property_id"
        case householdId = "household_id"
        case lastCompletedDate = "last_completed_date"
        case nextDueDate = "next_due_date"
        case estimatedCost = "estimated_cost"
        case assignedContractorId = "assigned_contractor_id"
        case assignedToUserId = "assigned_to_user_id"
        case createdAt = "created_at"
        case isTemplateBased = "is_template_based"
        case templateId = "template_id"
        case seasonalTiming = "seasonal_timing"
        case isDiy = "is_diy"
        case professionalRequired = "professional_required"
        case costRange = "cost_range"
        case lastEmailSentAt = "last_email_sent_at"
        case recurrenceRule = "recurrence_rule"
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
    var isTemplateBased: Bool?
    var templateId: String?
    var seasonalTiming: String?
    var isDiy: Bool?
    var professionalRequired: Bool?
    var costRange: String?
    var recurrenceRule: String?

    enum CodingKeys: String, CodingKey {
        case title, description, frequency, notes, priority
        case propertyId = "property_id"
        case householdId = "household_id"
        case systemId = "system_id"
        case lastCompletedDate = "last_completed_date"
        case nextDueDate = "next_due_date"
        case estimatedCost = "estimated_cost"
        case assignedContractorId = "assigned_contractor_id"
        case isTemplateBased = "is_template_based"
        case templateId = "template_id"
        case seasonalTiming = "seasonal_timing"
        case isDiy = "is_diy"
        case professionalRequired = "professional_required"
        case costRange = "cost_range"
        case recurrenceRule = "recurrence_rule"
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
    var assignedToUserId: UUID?
    var notes: String?
    var lastEmailSentAt: Date?

    enum CodingKeys: String, CodingKey {
        case title, description, frequency, notes, priority
        case lastCompletedDate = "last_completed_date"
        case nextDueDate = "next_due_date"
        case estimatedCost = "estimated_cost"
        case assignedContractorId = "assigned_contractor_id"
        case assignedToUserId = "assigned_to_user_id"
        case lastEmailSentAt = "last_email_sent_at"
    }
}

// MARK: - Service Email

struct ServiceEmailRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let maintenanceTaskId: UUID?
    let contractorId: UUID?
    let propertyId: UUID?
    let subject: String
    let body: String
    let sentAt: Date?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, subject, body, status
        case householdId = "household_id"
        case maintenanceTaskId = "maintenance_task_id"
        case contractorId = "contractor_id"
        case propertyId = "property_id"
        case sentAt = "sent_at"
    }
}

struct ServiceEmailInsert: Codable {
    let householdId: UUID
    let subject: String
    let body: String
    var maintenanceTaskId: UUID?
    var contractorId: UUID?
    var propertyId: UUID?
    var status: String?

    enum CodingKeys: String, CodingKey {
        case subject, body, status
        case householdId = "household_id"
        case maintenanceTaskId = "maintenance_task_id"
        case contractorId = "contractor_id"
        case propertyId = "property_id"
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

// MARK: - Access Log

struct AccessLogRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID?
    let action: String
    let resourceType: String
    let resourceId: UUID?
    let resourceName: String?
    let actorType: String
    let ipAddress: String?
    let deviceInfo: String?
    let metadata: [String: FlexibleValue]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, action, metadata
        case householdId = "household_id"
        case userId = "user_id"
        case resourceType = "resource_type"
        case resourceId = "resource_id"
        case resourceName = "resource_name"
        case actorType = "actor_type"
        case ipAddress = "ip_address"
        case deviceInfo = "device_info"
        case createdAt = "created_at"
    }
}

// MARK: - Document Content

struct DocumentContentRow: Codable, Identifiable {
    let id: UUID
    let documentId: UUID
    let householdId: UUID
    let extractedText: String
    let extractionMethod: String?
    let extractedAt: Date?
    let lastAiAnalysisAt: Date?
    let aiModelVersion: String?

    enum CodingKeys: String, CodingKey {
        case id
        case documentId = "document_id"
        case householdId = "household_id"
        case extractedText = "extracted_text"
        case extractionMethod = "extraction_method"
        case extractedAt = "extracted_at"
        case lastAiAnalysisAt = "last_ai_analysis_at"
        case aiModelVersion = "ai_model_version"
    }
}

// MARK: - Document Party (AI-identified people in documents)

struct DocumentPartyRow: Codable, Identifiable {
    let id: UUID
    let documentId: UUID
    let householdId: UUID
    let name: String
    let role: String
    let familyMemberId: UUID?
    let trustedContactId: UUID?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, role
        case documentId = "document_id"
        case householdId = "household_id"
        case familyMemberId = "family_member_id"
        case trustedContactId = "trusted_contact_id"
        case createdAt = "created_at"
    }
}

struct DocumentPartyInsert: Codable {
    let documentId: UUID
    let householdId: UUID
    let name: String
    let role: String
    var familyMemberId: UUID?
    var trustedContactId: UUID?

    enum CodingKeys: String, CodingKey {
        case name, role
        case documentId = "document_id"
        case householdId = "household_id"
        case familyMemberId = "family_member_id"
        case trustedContactId = "trusted_contact_id"
    }
}

struct DocumentPartyUpdate: Codable {
    var familyMemberId: UUID?
    var trustedContactId: UUID?

    enum CodingKeys: String, CodingKey {
        case familyMemberId = "family_member_id"
        case trustedContactId = "trusted_contact_id"
    }
}

// MARK: - Trusted Contact

struct TrustedContactRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let name: String
    let email: String
    let phone: String?
    let role: String
    let company: String?
    let inviteStatus: String
    let inviteToken: UUID?
    let inviteSentAt: Date?
    let lastAccessedAt: Date?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, role, company, notes
        case householdId = "household_id"
        case inviteStatus = "invite_status"
        case inviteToken = "invite_token"
        case inviteSentAt = "invite_sent_at"
        case lastAccessedAt = "last_accessed_at"
        case createdAt = "created_at"
    }
}

struct TrustedContactInsert: Codable {
    let householdId: UUID
    let name: String
    let email: String
    let role: String
    var phone: String?
    var company: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, email, role, phone, company, notes
        case householdId = "household_id"
    }
}

struct TrustedContactUpdate: Codable {
    var name: String?
    var email: String?
    var phone: String?
    var role: String?
    var company: String?
    var inviteStatus: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, email, phone, role, company, notes
        case inviteStatus = "invite_status"
    }
}

// MARK: - Trusted Contact Documents (junction)

struct TrustedContactDocumentRow: Codable {
    let trustedContactId: UUID
    let documentId: UUID
    let grantedAt: Date?
    let grantedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case trustedContactId = "trusted_contact_id"
        case documentId = "document_id"
        case grantedAt = "granted_at"
        case grantedBy = "granted_by"
    }
}

struct TrustedContactDocumentInsert: Codable {
    let trustedContactId: UUID
    let documentId: UUID

    enum CodingKeys: String, CodingKey {
        case trustedContactId = "trusted_contact_id"
        case documentId = "document_id"
    }
}

// MARK: - Dismissed Category

struct DismissedCategoryRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let category: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, category
        case householdId = "household_id"
        case createdAt = "created_at"
    }
}

struct DismissedCategoryInsert: Codable {
    let householdId: UUID
    let category: String

    enum CodingKeys: String, CodingKey {
        case householdId = "household_id"
        case category
    }
}

// MARK: - Concierge Message

struct ConciergeMessageRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    let role: String
    let content: String
    let readAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case householdId = "household_id"
        case userId = "user_id"
        case readAt = "read_at"
        case createdAt = "created_at"
    }
}

struct ConciergeMessageInsert: Codable {
    let householdId: UUID
    let userId: UUID
    let role: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case role, content
        case householdId = "household_id"
        case userId = "user_id"
    }
}

// MARK: - Household Invitation

struct HouseholdInvitationRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let invitedBy: UUID
    let invitedEmail: String
    let inviteCode: String
    let role: String
    let familyMemberId: UUID?
    let status: String
    let createdAt: Date?
    let expiresAt: Date?
    let acceptedAt: Date?
    let acceptedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id, role, status
        case householdId = "household_id"
        case invitedBy = "invited_by"
        case invitedEmail = "invited_email"
        case inviteCode = "invite_code"
        case familyMemberId = "family_member_id"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case acceptedAt = "accepted_at"
        case acceptedBy = "accepted_by"
    }
}

struct HouseholdInvitationInsert: Codable {
    let householdId: UUID
    let invitedBy: UUID
    let invitedEmail: String
    let inviteCode: String
    var role: String = "member"
    var familyMemberId: UUID?

    enum CodingKeys: String, CodingKey {
        case role
        case householdId = "household_id"
        case invitedBy = "invited_by"
        case invitedEmail = "invited_email"
        case inviteCode = "invite_code"
        case familyMemberId = "family_member_id"
    }
}

// MARK: - Service Contracts

struct ServiceContractRow: Codable, Identifiable {
    let id: UUID
    let propertyId: UUID
    let householdId: UUID
    let serviceType: String
    let providerName: String?
    let contractorId: UUID?
    let frequency: String?
    let details: [String: FlexibleValue]?
    let annualCost: Double?
    let startDate: String?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, frequency, details, notes
        case propertyId = "property_id"
        case householdId = "household_id"
        case serviceType = "service_type"
        case providerName = "provider_name"
        case contractorId = "contractor_id"
        case annualCost = "annual_cost"
        case startDate = "start_date"
        case createdAt = "created_at"
    }
}

struct ServiceContractInsert: Codable {
    let propertyId: UUID
    let householdId: UUID
    let serviceType: String
    var providerName: String?
    var contractorId: UUID?
    var frequency: String?
    var details: [String: FlexibleValue]?
    var annualCost: Double?
    var startDate: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case frequency, details, notes
        case propertyId = "property_id"
        case householdId = "household_id"
        case serviceType = "service_type"
        case providerName = "provider_name"
        case contractorId = "contractor_id"
        case annualCost = "annual_cost"
        case startDate = "start_date"
    }
}

struct ServiceContractUpdate: Codable {
    var serviceType: String?
    var providerName: String?
    var contractorId: UUID?
    var frequency: String?
    var details: [String: FlexibleValue]?
    var annualCost: Double?
    var startDate: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case frequency, details, notes
        case serviceType = "service_type"
        case providerName = "provider_name"
        case contractorId = "contractor_id"
        case annualCost = "annual_cost"
        case startDate = "start_date"
    }
}

// MARK: - Merge Preview Models

struct MergeDuplicate<T: Codable>: Codable {
    let source: T
    let target: T
    let matchReason: String

    enum CodingKeys: String, CodingKey {
        case source, target
        case matchReason = "match_reason"
    }
}

struct MergeCategoryPreview<T: Codable>: Codable {
    let duplicates: [MergeDuplicate<T>]
    let sourceOnly: [T]
    let targetOnly: [T]

    enum CodingKeys: String, CodingKey {
        case duplicates
        case sourceOnly = "source_only"
        case targetOnly = "target_only"
    }
}

struct MergePreview: Codable {
    let properties: MergeCategoryPreview<PropertyRow>
    let homeSystems: MergeCategoryPreview<HomeSystemRow>
    let maintenanceTasks: MergeCategoryPreview<MaintenanceTaskDBRow>
    let contractors: MergeCategoryPreview<ContractorRow>
    let documents: MergeCategoryPreview<DocumentRow>
    let familyMembers: MergeCategoryPreview<FamilyMemberRow>

    enum CodingKeys: String, CodingKey {
        case properties, contractors, documents
        case homeSystems = "home_systems"
        case maintenanceTasks = "maintenance_tasks"
        case familyMembers = "family_members"
    }
}

struct MergeSummary: Codable {
    let totalDuplicates: Int
    let sourceOnly: Int
    let targetOnly: Int
    let categoriesWithConflicts: [String]

    enum CodingKeys: String, CodingKey {
        case categoriesWithConflicts = "categories_with_conflicts"
        case totalDuplicates = "total_duplicates"
        case sourceOnly = "source_only"
        case targetOnly = "target_only"
    }
}

struct MergePreviewResponse: Codable {
    let preview: MergePreview
    let summary: MergeSummary
    let sourceHouseholdName: String
    let targetHouseholdName: String

    enum CodingKeys: String, CodingKey {
        case preview, summary
        case sourceHouseholdName = "source_household_name"
        case targetHouseholdName = "target_household_name"
    }
}

struct MergeResolutions: Codable {
    var properties: [String: String]?
    var homeSystems: [String: String]?
    var maintenanceTasks: [String: String]?
    var contractors: [String: String]?
    var documents: [String: String]?
    var familyMembers: [String: String]?

    enum CodingKeys: String, CodingKey {
        case properties, contractors, documents
        case homeSystems = "home_systems"
        case maintenanceTasks = "maintenance_tasks"
        case familyMembers = "family_members"
    }
}
