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
    let avatarUrl: String?
    let expectedDate: String?
    let isExpecting: Bool?
    let legalName: String?
    let school: String?
    let notes: String?
    let createdAt: Date?
    let linkedUserId: UUID?

    /// Whether this family member has a linked Haven account
    var isLinkedUser: Bool { linkedUserId != nil }

    enum CodingKeys: String, CodingKey {
        case id, relationship, email, phone, notes, gender, school
        case householdId = "household_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case isMinor = "is_minor"
        case avatarColor = "avatar_color"
        case avatarUrl = "avatar_url"
        case expectedDate = "expected_date"
        case isExpecting = "is_expecting"
        case legalName = "legal_name"
        case createdAt = "created_at"
        case linkedUserId = "linked_user_id"
    }
}

extension Array where Element == FamilyMemberRow {
    /// Sort members by age (oldest first). Members without DOB go to the end, sorted alphabetically.
    func sortedByAge() -> [FamilyMemberRow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return sorted { a, b in
            let dateA = a.dateOfBirth.flatMap { formatter.date(from: $0) }
            let dateB = b.dateOfBirth.flatMap { formatter.date(from: $0) }
            switch (dateA, dateB) {
            case (.some(let dA), .some(let dB)):
                return dA < dB
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return a.firstName < b.firstName
            }
        }
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
    var school: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case relationship, email, phone, notes, gender, school
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
    var avatarUrl: String?
    var expectedDate: String?
    var isExpecting: Bool?
    var legalName: String?
    var school: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case relationship, email, phone, notes, gender, school
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case isMinor = "is_minor"
        case avatarColor = "avatar_color"
        case avatarUrl = "avatar_url"
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
    let vehicleId: UUID?
    let projectId: UUID?
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
        case vehicleId = "vehicle_id"
        case projectId = "project_id"
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
    // Vehicle VIN detection (populated by analyze-document edge function)
    let detectedVins: [String]?
    let matchedVehicleIds: [String]?
    let unmatchedVins: [String]?

    enum CodingKeys: String, CodingKey {
        case crossReferences = "cross_references"
        case extractedMetadata = "extracted_metadata"
        case detectedVins = "detected_vins"
        case matchedVehicleIds = "matched_vehicle_ids"
        case unmatchedVins = "unmatched_vins"
    }

    init(crossReferences: [String]? = nil, extractedMetadata: [String: FlexibleValue]? = nil,
         detectedVins: [String]? = nil, matchedVehicleIds: [String]? = nil, unmatchedVins: [String]? = nil) {
        self.crossReferences = crossReferences
        self.extractedMetadata = extractedMetadata
        self.detectedVins = detectedVins
        self.matchedVehicleIds = matchedVehicleIds
        self.unmatchedVins = unmatchedVins
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        crossReferences = try? container.decode([String].self, forKey: .crossReferences)
        extractedMetadata = try? container.decode([String: FlexibleValue].self, forKey: .extractedMetadata)
        detectedVins = try? container.decode([String].self, forKey: .detectedVins)
        matchedVehicleIds = try? container.decode([String].self, forKey: .matchedVehicleIds)
        unmatchedVins = try? container.decode([String].self, forKey: .unmatchedVins)
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
    var vehicleId: UUID?
    var projectId: UUID?
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
        case vehicleId = "vehicle_id"
        case projectId = "project_id"
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
    let houseQuizState: HouseQuizState?
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
        case houseQuizState = "house_quiz_state"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        name = try c.decode(String.self, forKey: .name)
        propertyType = try c.decode(String.self, forKey: .propertyType)
        street = try? c.decode(String.self, forKey: .street)
        unit = try? c.decode(String.self, forKey: .unit)
        city = try? c.decode(String.self, forKey: .city)
        state = try? c.decode(String.self, forKey: .state)
        zipCode = try? c.decode(String.self, forKey: .zipCode)
        country = try? c.decode(String.self, forKey: .country)
        purchaseDate = try? c.decode(String.self, forKey: .purchaseDate)
        purchasePrice = try? c.decode(Double.self, forKey: .purchasePrice)
        currentEstimatedValue = try? c.decode(Double.self, forKey: .currentEstimatedValue)
        squareFootage = try? c.decode(Int.self, forKey: .squareFootage)
        yearBuilt = try? c.decode(Int.self, forKey: .yearBuilt)
        ownershipEntity = try? c.decode(String.self, forKey: .ownershipEntity)
        notes = try? c.decode(String.self, forKey: .notes)
        attributes = try? c.decode([String: FlexibleValue].self, forKey: .attributes)
        houseQuizState = try? c.decode(HouseQuizState.self, forKey: .houseQuizState)
        createdAt = try? c.decode(Date.self, forKey: .createdAt)
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
    var purchaseDate: String?
    var purchasePrice: Double?
    var currentEstimatedValue: Double?
    var squareFootage: Int?
    var yearBuilt: Int?
    var ownershipEntity: String?
    var notes: String?
    var attributes: [String: FlexibleValue]?
    var houseQuizState: HouseQuizState?

    enum CodingKeys: String, CodingKey {
        case name, street, unit, city, state, notes, attributes
        case propertyType = "property_type"
        case zipCode = "zip_code"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentEstimatedValue = "current_estimated_value"
        case squareFootage = "square_footage"
        case yearBuilt = "year_built"
        case ownershipEntity = "ownership_entity"
        case houseQuizState = "house_quiz_state"
    }
}

// MARK: - Home System

struct HomeSystemRow: Identifiable {
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
    let catalogEntryId: UUID?
    let lastServiceDate: String?
    let nextServiceDue: String?
    let totalSpent: Double?
    // Cached catalog enrichment (avoids network calls on every page load)
    let catalogSeries: String?
    let catalogModelName: String?
    let catalogFeatures: [String]?
    let reliabilityScore: Int?
    let scoreSummary: String?
    let catalogFuelType: String?
    let catalogEnrichedAt: Date?
    let cachedManualLinks: [CachedManualLink]?
    let parentSystemId: UUID?
    let subtype: String?
    let customCategoryName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category, manufacturer, notes, status, subtype
        case customCategoryName = "custom_category_name"
        case propertyId = "property_id"
        case householdId = "household_id"
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case expectedLifespanYears = "expected_lifespan_years"
        case createdAt = "created_at"
        case preferredContractorId = "preferred_contractor_id"
        case catalogEntryId = "catalog_entry_id"
        case lastServiceDate = "last_service_date"
        case parentSystemId = "parent_system_id"
        case nextServiceDue = "next_service_due"
        case totalSpent = "total_spent"
        case catalogSeries = "catalog_series"
        case catalogModelName = "catalog_model_name"
        case catalogFeatures = "catalog_features"
        case reliabilityScore = "reliability_score"
        case scoreSummary = "score_summary"
        case catalogFuelType = "catalog_fuel_type"
        case catalogEnrichedAt = "catalog_enriched_at"
        case cachedManualLinks = "cached_manual_links"
    }
}

extension HomeSystemRow: Decodable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        propertyId = try c.decode(UUID.self, forKey: .propertyId)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        name = try c.decode(String.self, forKey: .name)
        category = try c.decode(String.self, forKey: .category)
        manufacturer = try? c.decodeIfPresent(String.self, forKey: .manufacturer)
        modelNumber = try? c.decodeIfPresent(String.self, forKey: .modelNumber)
        serialNumber = try? c.decodeIfPresent(String.self, forKey: .serialNumber)
        installDate = try? c.decodeIfPresent(String.self, forKey: .installDate)
        expectedLifespanYears = try? c.decodeIfPresent(Int.self, forKey: .expectedLifespanYears)
        status = try? c.decodeIfPresent(String.self, forKey: .status)
        notes = try? c.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        preferredContractorId = try? c.decodeIfPresent(UUID.self, forKey: .preferredContractorId)
        catalogEntryId = try? c.decodeIfPresent(UUID.self, forKey: .catalogEntryId)
        lastServiceDate = try? c.decodeIfPresent(String.self, forKey: .lastServiceDate)
        nextServiceDue = try? c.decodeIfPresent(String.self, forKey: .nextServiceDue)
        totalSpent = try? c.decodeIfPresent(Double.self, forKey: .totalSpent)
        // Cache fields — use try? so a decode failure never kills the row
        catalogSeries = try? c.decodeIfPresent(String.self, forKey: .catalogSeries)
        catalogModelName = try? c.decodeIfPresent(String.self, forKey: .catalogModelName)
        catalogFeatures = try? c.decodeIfPresent([String].self, forKey: .catalogFeatures)
        reliabilityScore = try? c.decodeIfPresent(Int.self, forKey: .reliabilityScore)
        scoreSummary = try? c.decodeIfPresent(String.self, forKey: .scoreSummary)
        catalogFuelType = try? c.decodeIfPresent(String.self, forKey: .catalogFuelType)
        catalogEnrichedAt = try? c.decodeIfPresent(Date.self, forKey: .catalogEnrichedAt)
        cachedManualLinks = try? c.decodeIfPresent([CachedManualLink].self, forKey: .cachedManualLinks)
        parentSystemId = try? c.decodeIfPresent(UUID.self, forKey: .parentSystemId)
        subtype = try? c.decodeIfPresent(String.self, forKey: .subtype)
        customCategoryName = try? c.decodeIfPresent(String.self, forKey: .customCategoryName)
    }
}

extension HomeSystemRow {
    /// Category to show in UI: prefers `customCategoryName` for "Other" systems.
    var displayCategory: String {
        if category.lowercased() == "other", let custom = customCategoryName, !custom.isEmpty {
            return custom
        }
        return category
    }

    /// Subtype tokens parsed from comma-joined `subtype` column.
    var subtypeTokens: Set<String> {
        guard let s = subtype, !s.isEmpty else { return [] }
        return Set(s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }
}

extension HomeSystemRow: Encodable {}

extension HomeSystemRow {
    /// Functional display name — strips manufacturer and model from the name if present.
    var displayName: String {
        var result = name
        if let mfr = manufacturer, !mfr.isEmpty {
            result = result.replacingOccurrences(of: mfr, with: "", options: .caseInsensitive)
        }
        if let model = modelNumber, !model.isEmpty {
            result = result.replacingOccurrences(of: model, with: "", options: .caseInsensitive)
        }
        result = result.replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "-\u{2014}")))
        return result.isEmpty ? name : result
    }
}

struct CachedManualLink: Codable {
    let type: String
    let url: String
    let cached: Bool?
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
    var catalogEntryId: UUID?
    var parentSystemId: UUID?
    var subtype: String?
    var customCategoryName: String?

    enum CodingKeys: String, CodingKey {
        case name, category, manufacturer, notes, status, subtype
        case customCategoryName = "custom_category_name"
        case propertyId = "property_id"
        case householdId = "household_id"
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case expectedLifespanYears = "expected_lifespan_years"
        case catalogEntryId = "catalog_entry_id"
        case parentSystemId = "parent_system_id"
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
    var catalogEntryId: UUID?
    var lastServiceDate: String?
    var nextServiceDue: String?
    var totalSpent: Double?
    // Catalog cache fields
    var catalogSeries: String?
    var catalogModelName: String?
    var catalogFeatures: [String]?
    var reliabilityScore: Int?
    var scoreSummary: String?
    var catalogFuelType: String?
    var catalogEnrichedAt: Date?
    var parentSystemId: UUID?
    var subtype: String?
    var customCategoryName: String?

    enum CodingKeys: String, CodingKey {
        case name, category, manufacturer, notes, status, subtype
        case customCategoryName = "custom_category_name"
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case expectedLifespanYears = "expected_lifespan_years"
        case preferredContractorId = "preferred_contractor_id"
        case catalogEntryId = "catalog_entry_id"
        case lastServiceDate = "last_service_date"
        case nextServiceDue = "next_service_due"
        case totalSpent = "total_spent"
        case catalogSeries = "catalog_series"
        case catalogModelName = "catalog_model_name"
        case catalogFeatures = "catalog_features"
        case reliabilityScore = "reliability_score"
        case scoreSummary = "score_summary"
        case catalogFuelType = "catalog_fuel_type"
        case catalogEnrichedAt = "catalog_enriched_at"
        case parentSystemId = "parent_system_id"
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
    let propertyId: UUID?
    let vehicleId: UUID?
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
    let scheduledDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, frequency, notes, priority
        case systemId = "system_id"
        case propertyId = "property_id"
        case vehicleId = "vehicle_id"
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
        case scheduledDate = "scheduled_date"
    }

    /// Create a synthetic task row for vehicle alerts that don't have a stored task yet.
    /// These can be displayed in the task detail sheet and saved if the user assigns them.
    /// Generic synthetic factory used for optimistic UI placeholders.
    /// All fields are optional except title, nextDueDate, householdId.
    static func synthetic(
        id: UUID = UUID(),
        title: String,
        nextDueDate: String,
        propertyId: UUID? = nil,
        vehicleId: UUID? = nil,
        systemId: UUID? = nil,
        householdId: UUID,
        priority: String? = "medium",
        assignedToUserId: UUID? = nil,
        assignedContractorId: UUID? = nil,
        frequency: String = "As needed",
        notes: String? = nil
    ) -> MaintenanceTaskDBRow {
        MaintenanceTaskDBRow(
            id: id,
            systemId: systemId,
            propertyId: propertyId,
            vehicleId: vehicleId,
            householdId: householdId,
            title: title,
            description: nil,
            frequency: frequency,
            lastCompletedDate: nil,
            nextDueDate: nextDueDate,
            estimatedCost: nil,
            priority: priority,
            assignedContractorId: assignedContractorId,
            assignedToUserId: assignedToUserId,
            notes: notes,
            createdAt: nil,
            isTemplateBased: nil,
            templateId: nil,
            seasonalTiming: nil,
            isDiy: nil,
            professionalRequired: nil,
            costRange: nil,
            lastEmailSentAt: nil,
            recurrenceRule: nil,
            scheduledDate: nil
        )
    }

    static func synthetic(
        title: String,
        nextDueDate: String,
        vehicleId: UUID,
        householdId: UUID,
        priority: String? = "medium",
        templateId: String? = nil
    ) -> MaintenanceTaskDBRow {
        MaintenanceTaskDBRow(
            id: UUID(),
            systemId: nil,
            propertyId: nil,
            vehicleId: vehicleId,
            householdId: householdId,
            title: title,
            description: nil,
            frequency: "As needed",
            lastCompletedDate: nil,
            nextDueDate: nextDueDate,
            estimatedCost: nil,
            priority: priority,
            assignedContractorId: nil,
            assignedToUserId: nil,
            notes: nil,
            createdAt: nil,
            isTemplateBased: nil,
            templateId: templateId,
            seasonalTiming: nil,
            isDiy: nil,
            professionalRequired: nil,
            costRange: nil,
            lastEmailSentAt: nil,
            recurrenceRule: nil,
            scheduledDate: nil
        )
    }
}

struct MaintenanceTaskInsert: Codable {
    var propertyId: UUID?
    var vehicleId: UUID?
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
    var assignedToUserId: UUID?
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
        case vehicleId = "vehicle_id"
        case householdId = "household_id"
        case systemId = "system_id"
        case lastCompletedDate = "last_completed_date"
        case nextDueDate = "next_due_date"
        case estimatedCost = "estimated_cost"
        case assignedContractorId = "assigned_contractor_id"
        case assignedToUserId = "assigned_to_user_id"
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
    var systemId: UUID?
    var vehicleId: UUID?
    var notes: String?
    var lastEmailSentAt: Date?
    var scheduledDate: String?

    enum CodingKeys: String, CodingKey {
        case title, description, frequency, notes, priority
        case lastCompletedDate = "last_completed_date"
        case nextDueDate = "next_due_date"
        case estimatedCost = "estimated_cost"
        case assignedContractorId = "assigned_contractor_id"
        case assignedToUserId = "assigned_to_user_id"
        case systemId = "system_id"
        case vehicleId = "vehicle_id"
        case lastEmailSentAt = "last_email_sent_at"
        case scheduledDate = "scheduled_date"
    }
}

// MARK: - Device Token

struct DeviceTokenUpsert: Codable {
    let userId: UUID
    let token: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case token
        case platform
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

// MARK: - Property Projects

struct PropertyProjectRow: Codable, Identifiable, Hashable {
    static func == (lhs: PropertyProjectRow, rhs: PropertyProjectRow) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let householdId: UUID
    let propertyId: UUID
    let name: String
    let description: String?
    let category: String
    let status: String
    let projectType: String
    let priority: String?
    let estimatedBudget: Double?
    let actualSpend: Double?
    let aiEstimatedDiyCost: Double?
    let aiEstimatedProCost: Double?
    let targetStartDate: String?
    let targetEndDate: String?
    let actualStartDate: String?
    let actualEndDate: String?
    let aiResearch: ProjectAIResearch?
    let aiResearchUpdatedAt: Date?
    let estimatedTotal: Double?
    let notes: String?
    let parentProjectId: UUID?
    let personalPropertyAmount: Double?
    let createdAt: Date?
    let updatedAt: Date?
    let createdBy: UUID?
    let activeQuoteId: UUID?
    let entryType: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, status, priority, notes
        case householdId = "household_id"
        case propertyId = "property_id"
        case projectType = "project_type"
        case estimatedBudget = "estimated_budget"
        case actualSpend = "actual_spend"
        case aiEstimatedDiyCost = "ai_estimated_diy_cost"
        case aiEstimatedProCost = "ai_estimated_pro_cost"
        case estimatedTotal = "estimated_total"
        case targetStartDate = "target_start_date"
        case targetEndDate = "target_end_date"
        case actualStartDate = "actual_start_date"
        case actualEndDate = "actual_end_date"
        case aiResearch = "ai_research"
        case aiResearchUpdatedAt = "ai_research_updated_at"
        case parentProjectId = "parent_project_id"
        case personalPropertyAmount = "personal_property_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case activeQuoteId = "active_quote_id"
        case entryType = "entry_type"
    }

    var isInsuranceClaim: Bool { projectType == "insurance_claim" }
    var isChildProject: Bool { parentProjectId != nil }
    var isHistorical: Bool { (entryType ?? "planned") == "historical" }
}

struct PropertyProjectInsert: Codable {
    let householdId: UUID
    let propertyId: UUID
    let name: String
    var description: String?
    let category: String
    var status: String = "planning"
    var projectType: String = "diy"
    var priority: String? = "medium"
    var estimatedBudget: Double?
    var actualSpend: Double?
    var actualEndDate: String?
    var targetStartDate: String?
    var targetEndDate: String?
    var notes: String?
    var parentProjectId: UUID?
    var entryType: String = "planned"

    enum CodingKeys: String, CodingKey {
        case name, description, category, status, priority, notes
        case householdId = "household_id"
        case propertyId = "property_id"
        case projectType = "project_type"
        case estimatedBudget = "estimated_budget"
        case actualSpend = "actual_spend"
        case actualEndDate = "actual_end_date"
        case targetStartDate = "target_start_date"
        case targetEndDate = "target_end_date"
        case parentProjectId = "parent_project_id"
        case entryType = "entry_type"
    }
}

struct PropertyProjectUpdate: Codable {
    var name: String?
    var description: String?
    var category: String?
    var status: String?
    var projectType: String?
    var priority: String?
    var estimatedBudget: Double?
    var actualSpend: Double?
    var aiEstimatedDiyCost: Double?
    var aiEstimatedProCost: Double?
    var targetStartDate: String?
    var targetEndDate: String?
    var actualStartDate: String?
    var actualEndDate: String?
    var aiResearch: ProjectAIResearch?
    var aiResearchUpdatedAt: Date?
    var estimatedTotal: Double?
    var notes: String?
    var parentProjectId: UUID?
    var personalPropertyAmount: Double?
    var activeQuoteId: UUID?

    enum CodingKeys: String, CodingKey {
        case name, description, category, status, priority, notes
        case projectType = "project_type"
        case estimatedBudget = "estimated_budget"
        case actualSpend = "actual_spend"
        case aiEstimatedDiyCost = "ai_estimated_diy_cost"
        case aiEstimatedProCost = "ai_estimated_pro_cost"
        case estimatedTotal = "estimated_total"
        case targetStartDate = "target_start_date"
        case targetEndDate = "target_end_date"
        case actualStartDate = "actual_start_date"
        case actualEndDate = "actual_end_date"
        case aiResearch = "ai_research"
        case aiResearchUpdatedAt = "ai_research_updated_at"
        case parentProjectId = "parent_project_id"
        case personalPropertyAmount = "personal_property_amount"
        case activeQuoteId = "active_quote_id"
    }
}

// MARK: - Project Files

struct ProjectFileRow: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let householdId: UUID
    let filePath: String
    let filename: String
    let contentType: String?
    let fileSize: Int?
    let thumbnailPath: String?
    let notes: String?
    let uploadedBy: UUID?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, filename, notes
        case projectId = "project_id"
        case householdId = "household_id"
        case filePath = "file_path"
        case contentType = "content_type"
        case fileSize = "file_size"
        case thumbnailPath = "thumbnail_path"
        case uploadedBy = "uploaded_by"
        case createdAt = "created_at"
    }

    var isImage: Bool {
        contentType?.hasPrefix("image/") == true
    }
}

struct ProjectFileInsert: Codable {
    let projectId: UUID
    let householdId: UUID
    let filePath: String
    let filename: String
    var contentType: String?
    var fileSize: Int?
    var thumbnailPath: String?
    var notes: String?
    var uploadedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case filename, notes
        case projectId = "project_id"
        case householdId = "household_id"
        case filePath = "file_path"
        case contentType = "content_type"
        case fileSize = "file_size"
        case thumbnailPath = "thumbnail_path"
        case uploadedBy = "uploaded_by"
    }
}

// MARK: - Project Quotes

struct ProjectQuoteRow: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let householdId: UUID
    let contractorId: UUID?
    let quoteDate: String?
    let quoteTotal: Double?
    let estimatedFairTotal: Double?
    let overallRating: String?
    let analysis: QuoteAnalysis
    let filePath: String?
    let notes: String?
    let trade: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, analysis, notes, trade
        case projectId = "project_id"
        case householdId = "household_id"
        case contractorId = "contractor_id"
        case quoteDate = "quote_date"
        case quoteTotal = "quote_total"
        case estimatedFairTotal = "estimated_fair_total"
        case overallRating = "overall_rating"
        case filePath = "file_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Vendor name from the quote analysis
    var vendorName: String? { analysis.vendor?.name }

    /// Display name for the trade, falling back to analysis vendor trade or "General"
    var tradeName: String {
        trade ?? analysis.vendor?.trade ?? "General"
    }
}

struct ProjectQuoteInsert: Codable {
    let projectId: UUID
    let householdId: UUID
    var contractorId: UUID?
    var quoteDate: String?
    var quoteTotal: Double?
    var estimatedFairTotal: Double?
    var overallRating: String?
    let analysis: QuoteAnalysis
    var filePath: String?
    var notes: String?
    var trade: String?

    enum CodingKeys: String, CodingKey {
        case analysis, notes, trade
        case projectId = "project_id"
        case householdId = "household_id"
        case contractorId = "contractor_id"
        case quoteDate = "quote_date"
        case quoteTotal = "quote_total"
        case estimatedFairTotal = "estimated_fair_total"
        case overallRating = "overall_rating"
        case filePath = "file_path"
    }
}

// MARK: - Quote Analysis Response

struct QuoteAnalysis: Codable {
    let vendor: QuoteVendor?
    let projectType: String?
    let quoteDate: String?
    let quoteTotal: Double?
    let hasItemizedPricing: Bool?
    let lineItems: [QuoteLineItem]?
    let overallAssessment: QuoteOverallAssessment?
    let suggestedDiyAlternative: QuoteDiyAlternative?
}

struct QuoteVendor: Codable {
    let name: String?
    let phone: String?
    let email: String?
    let address: String?
    let license: String?
    let trade: String?
}

struct QuoteLineItem: Codable, Identifiable {
    var id: String { description ?? UUID().uuidString }
    let description: String?
    let category: String?
    let quantity: Double?
    let unit: String?
    // Price from the contractor's quote (null if quote only has a lump sum total)
    let quotedPrice: Double?
    // Haven's independent cost estimates for this specific location
    let estimatedMaterialsCost: Double?
    let estimatedLaborCost: Double?
    // Total fair market estimate (materials + labor)
    let marketMedianPrice: Double?
    // Local county price range (low-high) adjusted for cost of living
    let localPriceRange: LocalPriceRange?
    // "quoted" if contractor provided the price, "estimated" if Haven researched it
    let priceSource: String?
    let rating: String?
    let ratingReason: String?

    // Backwards compat: old responses used unitPrice/totalPrice
    let unitPrice: Double?
    let totalPrice: Double?

    /// The price to display — prefers quotedPrice, falls back to totalPrice (old format)
    var displayPrice: Double? { quotedPrice ?? totalPrice }
    /// The combined Haven estimate
    var havenEstimate: Double? { marketMedianPrice ?? estimatedMaterialsCost.flatMap { m in estimatedLaborCost.map { l in m + l } } }
}

struct LocalPriceRange: Codable {
    let low: Double?
    let high: Double?
    let countyName: String?
    let costIndex: String? // "low", "average", "high", "very_high"
}

struct QuoteOverallAssessment: Codable {
    let rating: String?
    let summary: String?
    let totalQuoted: Double?
    let estimatedFairTotal: Double?
    let estimatedMaterials: Double?
    let estimatedLabor: Double?
    let potentialSavings: Double?
    let negotiationTips: [String]?
}

struct QuoteDiyAlternative: Codable {
    let feasible: Bool?
    let estimatedDiyCost: Double?
    let notes: String?
}

// MARK: - AI Research Response (decoded from JSONB)

struct ProjectAIResearch: Codable {
    let projectSummary: String?
    let typicalItems: [ResearchLineItem]?
    let estimatedDiyCost: CostEstimate?
    let estimatedProCost: CostEstimate?
    let tipsAndWarnings: [String]?
    let suggestedVideoTopics: [String]?
    let permitNotes: String?
    let difficultyLevel: String?
    let estimatedTimeframe: FlexibleTimeframe?
    let dealRating: String?
    let dealRatingReason: String?
    let homeValueImpact: HomeValueImpact?
    // Style/design fields
    let designMoodDescription: String?
    let styleNotes: String?
    let colorPalette: [ColorSuggestion]?
    let materialPairings: [MaterialPairing]?
    // Insurance claim fields
    let claimNumber: String?
    let claimType: String?
    let policyNumber: String?
    let insuranceCompany: String?
    let adjuster: ClaimAdjuster?
    let emailSummaries: [ClaimEmailSummary]?

    /// Whether this research has style/design data
    var hasDesignData: Bool {
        designMoodDescription != nil || colorPalette?.isEmpty == false
    }

    /// Resilient decoder — any single field with an unexpected type
    /// silently becomes nil instead of failing the entire struct.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        projectSummary = try? c.decodeIfPresent(String.self, forKey: .projectSummary)
        typicalItems = try? c.decodeIfPresent([ResearchLineItem].self, forKey: .typicalItems)
        estimatedDiyCost = try? c.decodeIfPresent(CostEstimate.self, forKey: .estimatedDiyCost)
        estimatedProCost = try? c.decodeIfPresent(CostEstimate.self, forKey: .estimatedProCost)
        tipsAndWarnings = try? c.decodeIfPresent([String].self, forKey: .tipsAndWarnings)
        suggestedVideoTopics = try? c.decodeIfPresent([String].self, forKey: .suggestedVideoTopics)
        permitNotes = try? c.decodeIfPresent(String.self, forKey: .permitNotes)
        difficultyLevel = try? c.decodeIfPresent(String.self, forKey: .difficultyLevel)
        estimatedTimeframe = try? c.decodeIfPresent(FlexibleTimeframe.self, forKey: .estimatedTimeframe)
        dealRating = try? c.decodeIfPresent(String.self, forKey: .dealRating)
        dealRatingReason = try? c.decodeIfPresent(String.self, forKey: .dealRatingReason)
        homeValueImpact = try? c.decodeIfPresent(HomeValueImpact.self, forKey: .homeValueImpact)
        designMoodDescription = try? c.decodeIfPresent(String.self, forKey: .designMoodDescription)
        styleNotes = try? c.decodeIfPresent(String.self, forKey: .styleNotes)
        colorPalette = try? c.decodeIfPresent([ColorSuggestion].self, forKey: .colorPalette)
        materialPairings = try? c.decodeIfPresent([MaterialPairing].self, forKey: .materialPairings)
        claimNumber = try? c.decodeIfPresent(String.self, forKey: .claimNumber)
        claimType = try? c.decodeIfPresent(String.self, forKey: .claimType)
        policyNumber = try? c.decodeIfPresent(String.self, forKey: .policyNumber)
        insuranceCompany = try? c.decodeIfPresent(String.self, forKey: .insuranceCompany)
        adjuster = try? c.decodeIfPresent(ClaimAdjuster.self, forKey: .adjuster)
        emailSummaries = try? c.decodeIfPresent([ClaimEmailSummary].self, forKey: .emailSummaries)
    }

    private enum CodingKeys: String, CodingKey {
        case projectSummary, typicalItems, estimatedDiyCost, estimatedProCost
        case tipsAndWarnings, suggestedVideoTopics, permitNotes, difficultyLevel
        case estimatedTimeframe, dealRating, dealRatingReason, homeValueImpact
        case designMoodDescription, styleNotes, colorPalette, materialPairings
        case claimNumber, claimType, policyNumber, insuranceCompany, adjuster, emailSummaries
    }
}

struct ColorSuggestion: Codable {
    let name: String?
    let hex: String?
    let usage: String?
    let role: String? // primary, accent, neutral, trim

    /// Display-safe name — falls back to hex or "Color"
    var displayName: String { name ?? hex ?? "Color" }
    /// Display-safe hex — falls back to gray
    var displayHex: String { hex ?? "#999999" }
}

struct MaterialPairing: Codable {
    let primary: String?
    let secondary: String?
    let location: String?
}

struct ClaimAdjuster: Codable {
    let name: String?
    let phone: String?
    let email: String?
}

struct ClaimEmailSummary: Codable {
    let date: String?
    let summary: String?
    let subject: String?
    let rawBody: String?
}

struct HomeValueImpact: Codable {
    let score: Int?
    let label: String?
    let typicalRoi: String?
    let explanation: String?
}

struct ResearchLineItem: Codable {
    let name: String
    let category: String?
    let designGroup: String? // "design" or "construction"
    // Edge Function may return "estimatedQuantity" or "quantity"
    let estimatedQuantity: Double?
    let quantity: Double?
    let unit: String?
    // Edge Function may return "estimatedUnitPrice" or "price"
    let estimatedUnitPrice: Double?
    let price: Double?
    let notes: String?
    // Edge Function may return "typicalStore" or "store"
    let typicalStore: String?
    let store: String?
    let necessity: String?
    let multiProjectUseful: Bool?
    // Product image and link (enriched via Google Custom Search)
    let imageUrl: String?
    let productUrl: String?

    /// Whether this is a design/style item vs construction/utilitarian
    var isDesignItem: Bool { designGroup == "design" }

    /// Resolved quantity from whichever field is present
    var resolvedQuantity: Double { estimatedQuantity ?? quantity ?? 1 }
    /// Resolved unit price from whichever field is present
    var resolvedPrice: Double? { estimatedUnitPrice ?? price }
    /// Resolved store from whichever field is present
    var resolvedStore: String? { typicalStore ?? store }
}

struct CostEstimate: Codable {
    // Edge Function may return "lowRange"/"highRange" or "low"/"high"
    let lowRange: Double?
    let highRange: Double?
    let low: Double?
    let high: Double?
    let breakdown: [CostBreakdownItem]?
    let notes: String?

    /// Resolved low value from whichever field is present
    var resolvedLow: Double { lowRange ?? low ?? 0 }
    /// Resolved high value from whichever field is present
    var resolvedHigh: Double { highRange ?? high ?? 0 }
}

/// Handles estimatedTimeframe which can be a string or an object {diy, professional}.
enum FlexibleTimeframe: Codable {
    case string(String)
    case object(diy: String?, professional: String?)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .string(s)
            return
        }
        // Try as object
        struct TimeframeObj: Decodable {
            let diy: String?
            let professional: String?
        }
        if let obj = try? container.decode(TimeframeObj.self) {
            self = .object(diy: obj.diy, professional: obj.professional)
            return
        }
        self = .string("Unknown")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .object(let diy, let pro):
            try container.encode(["diy": diy ?? "", "professional": pro ?? ""])
        }
    }

    var displayString: String {
        switch self {
        case .string(let s): return s
        case .object(let diy, let pro):
            let parts = [diy.map { "DIY: \($0)" }, pro.map { "Pro: \($0)" }].compactMap { $0 }
            return parts.joined(separator: " / ")
        }
    }
}

struct CostBreakdownItem: Codable {
    let category: String?
    // Amount can be a number or a string like "$400-$800"
    let amount: FlexibleValue?
    let description: String?

    var displayAmount: String {
        switch amount {
        case .string(let s): return s
        case .double(let d): return "$\(Int(d))"
        case .int(let i): return "$\(i)"
        default: return ""
        }
    }
}

// MARK: - Project Feasibility Response

struct ProjectFeasibility: Codable {
    let projectName: String?
    let estimatedCostRange: FeasibilityCostRange?
    let estimatedDiyCostRange: FeasibilityCostRange?
    let estimatedMaterialsCost: FeasibilityCostRange?
    let complexity: String?
    let complexityNote: String?
    let estimatedTimeframe: String?
    let roi: FeasibilityROI?
    let valueIncrease: FeasibilityValueIncrease?
    let marketDemand: String?
    let marketDemandNote: String?
    let quickTip: String?
}

struct FeasibilityCostRange: Codable {
    let low: Double?
    let high: Double?

    var displayRange: String {
        guard let low, let high else { return "N/A" }
        return "$\(Int(low).formatted()) – $\(Int(high).formatted())"
    }
}

struct FeasibilityROI: Codable {
    let score: Int?
    let label: String?
    let typicalReturn: String?
    let explanation: String?
}

struct FeasibilityValueIncrease: Codable {
    let estimatedDollarIncrease: Double?
    let percentageIncrease: String?
    let timeToRecoup: String?
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

// MARK: - Family Events

struct FamilyEventRow: Codable, Identifiable, Equatable, Hashable {
    static func == (lhs: FamilyEventRow, rhs: FamilyEventRow) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let householdId: UUID
    let title: String
    let startDate: Date
    let endDate: Date?
    let allDay: Bool
    let location: String?
    let notes: String?
    let source: String
    let externalCalendarId: String?
    let externalEventId: String?
    let sourceInboxItemId: UUID?
    let taggedMemberIds: [UUID]?
    let recurrenceRule: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, location, notes, source
        case householdId = "household_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case allDay = "all_day"
        case externalCalendarId = "external_calendar_id"
        case externalEventId = "external_event_id"
        case sourceInboxItemId = "source_inbox_item_id"
        case taggedMemberIds = "tagged_member_ids"
        case recurrenceRule = "recurrence_rule"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct FamilyEventInsert: Encodable {
    let householdId: UUID
    let title: String
    let startDate: Date
    let endDate: Date?
    let allDay: Bool?
    let location: String?
    let notes: String?
    let source: String
    let externalCalendarId: String?
    let externalEventId: String?
    let recurrenceRule: String?

    enum CodingKeys: String, CodingKey {
        case title, location, notes, source
        case householdId = "household_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case allDay = "all_day"
        case externalCalendarId = "external_calendar_id"
        case externalEventId = "external_event_id"
        case recurrenceRule = "recurrence_rule"
    }
}

// MARK: - Synced Calendars

struct SyncedCalendarRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    let calendarIdentifier: String
    let calendarTitle: String
    let calendarColor: String?
    let isActive: Bool
    let lastSyncedAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case userId = "user_id"
        case calendarIdentifier = "calendar_identifier"
        case calendarTitle = "calendar_title"
        case calendarColor = "calendar_color"
        case isActive = "is_active"
        case lastSyncedAt = "last_synced_at"
        case createdAt = "created_at"
    }
}

// MARK: - Project Contacts

struct ProjectContactRow: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let householdId: UUID
    let contractorId: UUID?
    let contactName: String?
    let contactEmail: String?
    let contactPhone: String?
    let role: String?
    let addedFrom: String?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, notes, role
        case projectId = "project_id"
        case householdId = "household_id"
        case contractorId = "contractor_id"
        case contactName = "contact_name"
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case addedFrom = "added_from"
        case createdAt = "created_at"
    }

    var displayName: String {
        contactName ?? contactEmail ?? "Unknown Contact"
    }

    var roleLabel: String {
        switch role {
        case "adjuster": return "Insurance Adjuster"
        case "inspector": return "Inspector"
        case "architect": return "Architect"
        default: return "Contractor"
        }
    }
}

// MARK: - Utility Accounts

struct UtilityAccountRow: Codable, Identifiable {
    let id: UUID
    let propertyId: UUID
    let householdId: UUID
    let providerType: String
    let providerName: String
    let providerSlug: String?
    let accountNumber: String?
    let phone: String?
    let website: String?
    let monthlyCost: Double?
    let planName: String?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, phone, website, notes
        case propertyId = "property_id"
        case householdId = "household_id"
        case providerType = "provider_type"
        case providerName = "provider_name"
        case providerSlug = "provider_slug"
        case accountNumber = "account_number"
        case monthlyCost = "monthly_cost"
        case planName = "plan_name"
        case createdAt = "created_at"
    }

    var typeIcon: String {
        switch providerType {
        case "electric": return "bolt.fill"
        case "internet_cable": return "wifi"
        case "security": return "lock.shield.fill"
        case "natural_gas": return "flame.fill"
        case "water": return "drop.fill"
        case "trash": return "trash.fill"
        case "propane": return "fuelpump.fill"
        case "oil": return "fuelpump.fill"
        case "solar": return "sun.max.fill"
        default: return "building.2.fill"
        }
    }

    var typeLabel: String {
        switch providerType {
        case "electric": return "Electric"
        case "internet_cable": return "Internet / Cable"
        case "security": return "Security"
        case "natural_gas": return "Natural Gas"
        case "water": return "Water"
        case "trash": return "Trash / Recycling"
        case "propane": return "Propane"
        case "oil": return "Oil"
        case "solar": return "Solar"
        default: return "Utility"
        }
    }
}

struct UtilityAccountInsert: Encodable {
    let propertyId: UUID
    let householdId: UUID
    let providerType: String
    let providerName: String
    var providerSlug: String?
    var accountNumber: String?
    var phone: String?
    var website: String?
    var monthlyCost: Double?
    var planName: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case phone, website, notes
        case propertyId = "property_id"
        case householdId = "household_id"
        case providerType = "provider_type"
        case providerName = "provider_name"
        case providerSlug = "provider_slug"
        case accountNumber = "account_number"
        case monthlyCost = "monthly_cost"
        case planName = "plan_name"
    }
}

struct UtilityProviderRow: Codable, Identifiable {
    let id: UUID
    let name: String
    let slug: String
    let providerType: String
    let logoUrl: String?
    let brandColor: String?
    let website: String?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, website, phone
        case providerType = "provider_type"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
    }
}

// MARK: - Vehicle

struct VehicleRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let name: String
    let year: Int?
    let make: String?
    let model: String?
    let trim: String?
    let color: String?
    let vin: String?
    let licensePlate: String?
    let currentMileage: Int?
    let ownershipType: String?
    let purchaseDate: String?
    let purchasePrice: Double?
    let currentValue: Double?
    let leaseEndDate: String?
    let loanPayoffDate: String?
    let registrationExpiry: String?
    let inspectionExpiry: String?
    let primaryDriverId: UUID?
    let preferredMechanicId: UUID?
    let coveredDriverIds: [UUID]?
    let maintenanceSchedule: [VehicleMaintenanceInterval]?
    let photoPath: String?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    let estimatedValue: Double?
    let estimatedValueLow: Double?
    let estimatedValueHigh: Double?
    let estimatedValueUpdatedAt: Date?
    let estimatedValueSource: String?

    enum CodingKeys: String, CodingKey {
        case id, name, year, make, model, trim, color, vin, notes
        case householdId = "household_id"
        case licensePlate = "license_plate"
        case currentMileage = "current_mileage"
        case ownershipType = "ownership_type"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentValue = "current_value"
        case leaseEndDate = "lease_end_date"
        case loanPayoffDate = "loan_payoff_date"
        case registrationExpiry = "registration_expiry"
        case inspectionExpiry = "inspection_expiry"
        case primaryDriverId = "primary_driver_id"
        case preferredMechanicId = "preferred_mechanic_id"
        case coveredDriverIds = "covered_driver_ids"
        case maintenanceSchedule = "maintenance_schedule"
        case photoPath = "photo_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case estimatedValue = "estimated_value"
        case estimatedValueLow = "estimated_value_low"
        case estimatedValueHigh = "estimated_value_high"
        case estimatedValueUpdatedAt = "estimated_value_updated_at"
        case estimatedValueSource = "estimated_value_source"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        name = try c.decode(String.self, forKey: .name)
        year = try? c.decodeIfPresent(Int.self, forKey: .year)
        make = try? c.decodeIfPresent(String.self, forKey: .make)
        model = try? c.decodeIfPresent(String.self, forKey: .model)
        trim = try? c.decodeIfPresent(String.self, forKey: .trim)
        color = try? c.decodeIfPresent(String.self, forKey: .color)
        vin = try? c.decodeIfPresent(String.self, forKey: .vin)
        licensePlate = try? c.decodeIfPresent(String.self, forKey: .licensePlate)
        currentMileage = try? c.decodeIfPresent(Int.self, forKey: .currentMileage)
        ownershipType = try? c.decodeIfPresent(String.self, forKey: .ownershipType)
        purchaseDate = try? c.decodeIfPresent(String.self, forKey: .purchaseDate)
        purchasePrice = try? c.decodeIfPresent(Double.self, forKey: .purchasePrice)
        currentValue = try? c.decodeIfPresent(Double.self, forKey: .currentValue)
        leaseEndDate = try? c.decodeIfPresent(String.self, forKey: .leaseEndDate)
        loanPayoffDate = try? c.decodeIfPresent(String.self, forKey: .loanPayoffDate)
        registrationExpiry = try? c.decodeIfPresent(String.self, forKey: .registrationExpiry)
        inspectionExpiry = try? c.decodeIfPresent(String.self, forKey: .inspectionExpiry)
        primaryDriverId = try? c.decodeIfPresent(UUID.self, forKey: .primaryDriverId)
        preferredMechanicId = try? c.decodeIfPresent(UUID.self, forKey: .preferredMechanicId)
        coveredDriverIds = try? c.decodeIfPresent([UUID].self, forKey: .coveredDriverIds)
        maintenanceSchedule = try? c.decodeIfPresent([VehicleMaintenanceInterval].self, forKey: .maintenanceSchedule)
        photoPath = try? c.decodeIfPresent(String.self, forKey: .photoPath)
        notes = try? c.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try? c.decodeIfPresent(Date.self, forKey: .updatedAt)
        estimatedValue = try? c.decodeIfPresent(Double.self, forKey: .estimatedValue)
        estimatedValueLow = try? c.decodeIfPresent(Double.self, forKey: .estimatedValueLow)
        estimatedValueHigh = try? c.decodeIfPresent(Double.self, forKey: .estimatedValueHigh)
        estimatedValueUpdatedAt = try? c.decodeIfPresent(Date.self, forKey: .estimatedValueUpdatedAt)
        estimatedValueSource = try? c.decodeIfPresent(String.self, forKey: .estimatedValueSource)
    }

    var displayName: String {
        [year.map { String($0) }, make, model].compactMap { $0 }.joined(separator: " ")
    }
}

struct VehicleMaintenanceInterval: Codable, Identifiable {
    var id: String { type }
    let type: String
    let intervalMiles: Int?
    let intervalMonths: Int?
    let estimatedCost: Double?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case type, description
        case intervalMiles = "interval_miles"
        case intervalMonths = "interval_months"
        case estimatedCost = "estimated_cost"
    }

    var estimatedCostDisplay: String? {
        estimatedCost.map { "$\(Int($0))" }
    }
}

struct VehicleInsert: Codable {
    let householdId: UUID
    let name: String
    var year: Int?
    var make: String?
    var model: String?
    var trim: String?
    var color: String?
    var vin: String?
    var licensePlate: String?
    var currentMileage: Int?
    var ownershipType: String?
    var purchaseDate: String?
    var purchasePrice: Double?
    var currentValue: Double?
    var leaseEndDate: String?
    var loanPayoffDate: String?
    var registrationExpiry: String?
    var inspectionExpiry: String?
    var primaryDriverId: UUID?
    var preferredMechanicId: UUID?
    var coveredDriverIds: [UUID]?
    var maintenanceSchedule: [VehicleMaintenanceInterval]?
    var photoPath: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, year, make, model, trim, color, vin, notes
        case householdId = "household_id"
        case licensePlate = "license_plate"
        case currentMileage = "current_mileage"
        case ownershipType = "ownership_type"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentValue = "current_value"
        case leaseEndDate = "lease_end_date"
        case loanPayoffDate = "loan_payoff_date"
        case registrationExpiry = "registration_expiry"
        case inspectionExpiry = "inspection_expiry"
        case primaryDriverId = "primary_driver_id"
        case preferredMechanicId = "preferred_mechanic_id"
        case coveredDriverIds = "covered_driver_ids"
        case maintenanceSchedule = "maintenance_schedule"
        case photoPath = "photo_path"
    }
}

struct VehicleUpdate: Codable {
    var name: String?
    var year: Int?
    var make: String?
    var model: String?
    var trim: String?
    var color: String?
    var vin: String?
    var licensePlate: String?
    var currentMileage: Int?
    var ownershipType: String?
    var purchaseDate: String?
    var purchasePrice: Double?
    var currentValue: Double?
    var leaseEndDate: String?
    var loanPayoffDate: String?
    var registrationExpiry: String?
    var inspectionExpiry: String?
    var primaryDriverId: UUID?
    var preferredMechanicId: UUID?
    var coveredDriverIds: [UUID]?
    var maintenanceSchedule: [VehicleMaintenanceInterval]?
    var photoPath: String?
    var notes: String?
    var estimatedValue: Double?
    var estimatedValueLow: Double?
    var estimatedValueHigh: Double?
    var estimatedValueUpdatedAt: Date?
    var estimatedValueSource: String?

    enum CodingKeys: String, CodingKey {
        case name, year, make, model, trim, color, vin, notes
        case licensePlate = "license_plate"
        case currentMileage = "current_mileage"
        case ownershipType = "ownership_type"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentValue = "current_value"
        case leaseEndDate = "lease_end_date"
        case loanPayoffDate = "loan_payoff_date"
        case registrationExpiry = "registration_expiry"
        case inspectionExpiry = "inspection_expiry"
        case primaryDriverId = "primary_driver_id"
        case preferredMechanicId = "preferred_mechanic_id"
        case coveredDriverIds = "covered_driver_ids"
        case maintenanceSchedule = "maintenance_schedule"
        case photoPath = "photo_path"
        case estimatedValue = "estimated_value"
        case estimatedValueLow = "estimated_value_low"
        case estimatedValueHigh = "estimated_value_high"
        case estimatedValueUpdatedAt = "estimated_value_updated_at"
        case estimatedValueSource = "estimated_value_source"
    }
}

// MARK: - Vehicle Service Record

struct VehicleServiceRecordRow: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let householdId: UUID
    let serviceDate: String
    let serviceType: String
    let description: String
    let cost: Double?
    let mileageAtService: Int?
    let contractorId: UUID?
    let invoiceDocumentId: UUID?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, description, cost, notes
        case vehicleId = "vehicle_id"
        case householdId = "household_id"
        case serviceDate = "service_date"
        case serviceType = "service_type"
        case mileageAtService = "mileage_at_service"
        case contractorId = "contractor_id"
        case invoiceDocumentId = "invoice_document_id"
        case createdAt = "created_at"
    }
}

struct VehicleServiceRecordInsert: Codable {
    let vehicleId: UUID
    let householdId: UUID
    let serviceDate: String
    let serviceType: String
    let description: String
    var cost: Double?
    var mileageAtService: Int?
    var contractorId: UUID?
    var invoiceDocumentId: UUID?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case description, cost, notes
        case vehicleId = "vehicle_id"
        case householdId = "household_id"
        case serviceDate = "service_date"
        case serviceType = "service_type"
        case mileageAtService = "mileage_at_service"
        case contractorId = "contractor_id"
        case invoiceDocumentId = "invoice_document_id"
    }
}

// MARK: - Vehicle Recall

struct VehicleRecallRow: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let householdId: UUID
    let nhtsaCampaignNumber: String?
    let component: String?
    let summary: String?
    let consequence: String?
    let remedy: String?
    let recallDate: String?
    let isResolved: Bool
    let resolvedDate: String?
    let resolvedServiceRecordId: UUID?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, component, summary, consequence, remedy, notes
        case vehicleId = "vehicle_id"
        case householdId = "household_id"
        case nhtsaCampaignNumber = "nhtsa_campaign_number"
        case recallDate = "recall_date"
        case isResolved = "is_resolved"
        case resolvedDate = "resolved_date"
        case resolvedServiceRecordId = "resolved_service_record_id"
        case createdAt = "created_at"
    }
}

struct VehicleRecallInsert: Codable {
    let vehicleId: UUID
    let householdId: UUID
    var nhtsaCampaignNumber: String?
    var component: String?
    var summary: String?
    var consequence: String?
    var remedy: String?
    var recallDate: String?
    var isResolved: Bool?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case component, summary, consequence, remedy, notes
        case vehicleId = "vehicle_id"
        case householdId = "household_id"
        case nhtsaCampaignNumber = "nhtsa_campaign_number"
        case recallDate = "recall_date"
        case isResolved = "is_resolved"
    }
}
