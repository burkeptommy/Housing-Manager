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
    /// Phase 63: FK to the household's preferred handyman contractor.
    /// Null when the household hasn't captured one (either because they
    /// prefer DIY or they need help finding one — the preference string
    /// lives in `properties.attributes.handyman_preference`).
    let preferredHandymanContractorId: UUID?
    /// Phase 84: group-level Chez ownership flags. Shape:
    ///   { "all_routines": { "on": true, "set_at": "..." },
    ///     "all_systems":  { "on": false }, ... }
    /// Read by the "What Chez handles" iOS page to render the 8 group
    /// toggles. Written by the chez-concierge `set_ownership_group` action.
    let chezOwnershipGroups: [String: ChezOwnershipGroupFlag]?

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt = "created_at"
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
        case preferredHandymanContractorId = "preferred_handyman_contractor_id"
        case chezOwnershipGroups = "chez_ownership_groups"
    }

    /// Resilient decoder (CLAUDE.md requirement for externally-fed structs).
    /// Pre-Phase-63 rows won't have the preferred_handyman_contractor_id
    /// column, so we decodeIfPresent and fall back to nil. Same for
    /// Phase 84's chez_ownership_groups.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        subscriptionTier = try? c.decodeIfPresent(String.self, forKey: .subscriptionTier)
        subscriptionExpiresAt = try? c.decodeIfPresent(Date.self, forKey: .subscriptionExpiresAt)
        preferredHandymanContractorId = try? c.decodeIfPresent(UUID.self, forKey: .preferredHandymanContractorId)
        chezOwnershipGroups = try? c.decodeIfPresent([String: ChezOwnershipGroupFlag].self, forKey: .chezOwnershipGroups)
    }

    /// Convenience: is a given group ("all_routines", "all_systems", ...) on?
    func isOwnershipGroupOn(_ group: String) -> Bool {
        chezOwnershipGroups?[group]?.on ?? false
    }
}

/// Phase 84: per-group flag inside `households.chez_ownership_groups`.
/// Stores `on` (whether Chez handles the whole category) plus the
/// timestamp of the last change.
struct ChezOwnershipGroupFlag: Codable, Hashable {
    let on: Bool
    let setAt: Date?

    enum CodingKeys: String, CodingKey {
        case on
        case setAt = "set_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        on = (try? c.decodeIfPresent(Bool.self, forKey: .on)) ?? false
        setAt = try? c.decodeIfPresent(Date.self, forKey: .setAt)
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
    var preferredHandymanContractorId: UUID?

    enum CodingKeys: String, CodingKey {
        case name
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
        case preferredHandymanContractorId = "preferred_handyman_contractor_id"
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
    /// Build 87: discriminator added by migration
    /// `20260437_add_family_member_type.sql`. One of 'family' (default),
    /// 'home_manager', or 'staff'. Optional in Swift so legacy rows that
    /// somehow predate the migration still decode cleanly — the migration
    /// backfills every existing row to 'family' so this should be non-nil
    /// in practice.
    let memberType: String?

    /// Whether this family member has a linked Haven account
    var isLinkedUser: Bool { linkedUserId != nil }

    /// Build 87: convenience for distinguishing real family from paid
    /// staff. Defaults to `true` when `memberType` is nil so legacy data
    /// keeps its existing dashboard placement.
    var isStaff: Bool {
        let type = memberType ?? "family"
        return type == "home_manager" || type == "staff"
    }

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
        case memberType = "member_type"
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
    var linkedUserId: UUID?
    /// Build 87: 'family' (default), 'home_manager', or 'staff'.
    var memberType: String?

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
        case linkedUserId = "linked_user_id"
        case memberType = "member_type"
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
    /// Set when an invited user accepts their invitation — stamps the
    /// accepting auth user's id on the family_member row so task
    /// assignment, profile lookup, and the dashboard greeting all
    /// resolve back to the human record the homeowner already typed in.
    var linkedUserId: UUID?
    /// Build 87: 'family' (default), 'home_manager', or 'staff'. Update
    /// path is intentionally permissive — the form layer is responsible
    /// for not flipping a family member into a staff member after creation.
    var memberType: String?

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
        case linkedUserId = "linked_user_id"
        case memberType = "member_type"
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
    /// Build 87 (Home Manager expansion): when false, household members
    /// whose `family_members.member_type` is `home_manager` or `staff`
    /// cannot see this document via the `household_documents_select` RLS
    /// policy. Defaults to true at insert time for unknown categories;
    /// estate / legal / financial / medical categories default to false
    /// via `DocumentAccessDefaults.visibleToHomeManagers(for:)`.
    let visibleToHomeManagers: Bool?
    /// Phase 58: optional direct link to the vendor this document relates
    /// to. Populated by `process-invoice` + `receive-email` when the
    /// extracted/sender vendor matches an existing contractor, or set
    /// explicitly when uploading from a vendor-context entry point.
    let contractorId: UUID?
    /// Phase 59: total amount extracted by process-invoice. Drives the
    /// vendor detail spend hero.
    let invoiceAmount: Double?
    /// Phase 59: service / bill date extracted by process-invoice.
    /// Format: "yyyy-MM-dd".
    let invoiceDate: String?
    /// Phase 59: invoice number from the bill header.
    let invoiceNumber: String?
    /// Phase 59: extracted line items (JSONB array).
    let invoiceLineItems: [InvoiceLineItem]?
    /// Phase 59: "high" | "medium" | "low" | "ambiguous" — tier of the
    /// vendor match. Drives the auto-file vs inbox-fallback branch.
    let vendorMatchConfidence: String?
    /// Phase 84 — Chez delegation. When true the homeowner has handed
    /// this document over to Chez to file, organize, share with vendors,
    /// and scan for gaps.
    let chezOwned: Bool?
    let chezOwnedAt: Date?

    /// Convenience accessor that defaults to `true` when the column is nil
    /// (legacy rows from before build 87, or rows decoded without the
    /// column projection). The RLS migration backfilled every row to a
    /// concrete value so this should only matter in transient decode paths.
    var isVisibleToHomeManagers: Bool {
        visibleToHomeManagers ?? true
    }

    var isChezOwned: Bool { chezOwned ?? false }

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
        case visibleToHomeManagers = "visible_to_home_managers"
        case contractorId = "contractor_id"
        case invoiceAmount = "invoice_amount"
        case invoiceDate = "invoice_date"
        case invoiceNumber = "invoice_number"
        case invoiceLineItems = "invoice_line_items"
        case vendorMatchConfidence = "vendor_match_confidence"
        case chezOwned = "chez_owned"
        case chezOwnedAt = "chez_owned_at"
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
    /// Build 87 (Home Manager expansion): set via
    /// `DocumentAccessDefaults.visibleToHomeManagers(for: category)` at every
    /// insert callsite so estate / legal / financial / medical categories
    /// default to hidden from home managers. Optional so legacy callsites
    /// that haven't been updated still compile, but every iOS path should
    /// pass an explicit value.
    var visibleToHomeManagers: Bool?
    /// Phase 58: optional vendor link. Set when uploading from a vendor
    /// context (ContractorDetailView "Add a bill"), or populated later by
    /// `process-invoice` / `receive-email` when a match is detected.
    var contractorId: UUID?
    /// Phase 59: invoice metadata set by process-invoice after extraction.
    /// Callers usually leave these nil on initial insert — the edge function
    /// writes them back.
    var invoiceAmount: Double?
    var invoiceDate: String?
    var invoiceNumber: String?
    var invoiceLineItems: [InvoiceLineItem]?
    var vendorMatchConfidence: String?

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
        case visibleToHomeManagers = "visible_to_home_managers"
        case contractorId = "contractor_id"
        case invoiceAmount = "invoice_amount"
        case invoiceDate = "invoice_date"
        case invoiceNumber = "invoice_number"
        case invoiceLineItems = "invoice_line_items"
        case vendorMatchConfidence = "vendor_match_confidence"
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
    /// Build 87 (Home Manager expansion): toggled per-document via the
    /// Access pill in `DocumentDetailView` → `DocumentAccessSheet`.
    var visibleToHomeManagers: Bool?
    /// Phase 58: link/unlink a document to a vendor. Usually set
    /// automatically by the invoice or email pipelines, but can be edited
    /// manually via the document detail view.
    var contractorId: UUID?
    /// Phase 59: invoice metadata. Usually set by process-invoice but
    /// editable via document detail for user corrections.
    var invoiceAmount: Double?
    var invoiceDate: String?
    var invoiceNumber: String?
    var invoiceLineItems: [InvoiceLineItem]?
    var vendorMatchConfidence: String?

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
        case visibleToHomeManagers = "visible_to_home_managers"
        case contractorId = "contractor_id"
        case invoiceAmount = "invoice_amount"
        case invoiceDate = "invoice_date"
        case invoiceNumber = "invoice_number"
        case invoiceLineItems = "invoice_line_items"
        case vendorMatchConfidence = "vendor_match_confidence"
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
    /// Phase 56.2: Lower/upper band of the ATTOM/RentCast AVM range. Both
    /// nil when the lookup didn't supply a range or when the user manually
    /// overrode the value (the override flow clears the band so stale
    /// ranges don't bracket user-entered numbers).
    let currentEstimatedValueLow: Double?
    let currentEstimatedValueHigh: Double?
    /// Phase 16e: which fallback layer produced `currentEstimatedValue`. One of
    /// "attom" | "rentcast" | "computed" | "estimated" | "manual". Used by
    /// InvestmentSummaryCard to render a transparency caption beneath the value.
    let estimatedValueSource: String?
    /// 0-100 confidence score that pairs with the source. ATTOM ships its own
    /// AVM scr; ai_comps uses 60-80 depending on comp count; computed uses 40;
    /// estimated uses 25.
    let estimatedValueConfidence: Int?
    /// Phase 18g: When `estimatedValueSource == "ai_comps"`, this carries the
    /// short paragraph Claude returned explaining its methodology
    /// (comp count, range observed, key adjustments). InvestmentSummaryCard
    /// shows it in a tappable info modal so users understand where the
    /// number came from. Nil for every other source.
    let estimatedValueReasoning: String?
    let squareFootage: Int?
    let yearBuilt: Int?
    let ownershipEntity: String?
    let notes: String?
    let attributes: [String: FlexibleValue]?
    let houseQuizState: HouseQuizState?
    let createdAt: Date?
    /// Phase 57: Regional maintenance pack derived from `state`. Backfilled
    /// for every existing property by the migration. Nil when the property
    /// has no state on file.
    let regionalPack: String?

    enum CodingKeys: String, CodingKey {
        case id, name, street, unit, city, state, notes, attributes
        case householdId = "household_id"
        case propertyType = "property_type"
        case zipCode = "zip_code"
        case country
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentEstimatedValue = "current_estimated_value"
        case currentEstimatedValueLow = "current_estimated_value_low"
        case currentEstimatedValueHigh = "current_estimated_value_high"
        case estimatedValueSource = "estimated_value_source"
        case estimatedValueConfidence = "estimated_value_confidence"
        case estimatedValueReasoning = "estimated_value_reasoning"
        case squareFootage = "square_footage"
        case yearBuilt = "year_built"
        case ownershipEntity = "ownership_entity"
        case houseQuizState = "house_quiz_state"
        case createdAt = "created_at"
        case regionalPack = "regional_pack"
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
        currentEstimatedValueLow = try? c.decodeIfPresent(Double.self, forKey: .currentEstimatedValueLow)
        currentEstimatedValueHigh = try? c.decodeIfPresent(Double.self, forKey: .currentEstimatedValueHigh)
        estimatedValueSource = try? c.decodeIfPresent(String.self, forKey: .estimatedValueSource)
        estimatedValueConfidence = try? c.decodeIfPresent(Int.self, forKey: .estimatedValueConfidence)
        estimatedValueReasoning = try? c.decodeIfPresent(String.self, forKey: .estimatedValueReasoning)
        squareFootage = try? c.decode(Int.self, forKey: .squareFootage)
        yearBuilt = try? c.decode(Int.self, forKey: .yearBuilt)
        ownershipEntity = try? c.decode(String.self, forKey: .ownershipEntity)
        notes = try? c.decode(String.self, forKey: .notes)
        attributes = try? c.decode([String: FlexibleValue].self, forKey: .attributes)
        houseQuizState = try? c.decode(HouseQuizState.self, forKey: .houseQuizState)
        createdAt = try? c.decode(Date.self, forKey: .createdAt)
        regionalPack = try? c.decodeIfPresent(String.self, forKey: .regionalPack)
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
    /// Phase 56.2: ATTOM/RentCast AVM low/high band. Nil unless the
    /// lookup response supplied a range.
    var currentEstimatedValueLow: Double?
    var currentEstimatedValueHigh: Double?
    var estimatedValueSource: String?
    var estimatedValueConfidence: Int?
    /// Phase 18g: AI-derived value reasoning paragraph (only set when source = "ai_comps").
    var estimatedValueReasoning: String?
    var squareFootage: Int?
    var yearBuilt: Int?
    var ownershipEntity: String?
    var notes: String?
    /// Phase 57: Regional maintenance pack. Callers can pass this on insert
    /// when the region is known at creation time; otherwise the DB row stays
    /// nil until `PropertyUpdate` or the backfill fills it.
    var regionalPack: String?

    enum CodingKeys: String, CodingKey {
        case name, street, unit, city, state, notes, country
        case householdId = "household_id"
        case propertyType = "property_type"
        case zipCode = "zip_code"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentEstimatedValue = "current_estimated_value"
        case currentEstimatedValueLow = "current_estimated_value_low"
        case currentEstimatedValueHigh = "current_estimated_value_high"
        case estimatedValueSource = "estimated_value_source"
        case estimatedValueConfidence = "estimated_value_confidence"
        case estimatedValueReasoning = "estimated_value_reasoning"
        case squareFootage = "square_footage"
        case yearBuilt = "year_built"
        case ownershipEntity = "ownership_entity"
        case regionalPack = "regional_pack"
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
    /// Phase 56.2: ATTOM/RentCast AVM low/high band. Writers set both
    /// when a lookup supplies a range, and set both to nil when the
    /// user manually overrides the value (the override invalidates the
    /// band so the card doesn't bracket a user-typed number with a
    /// stale machine-generated range).
    var currentEstimatedValueLow: Double?
    var currentEstimatedValueHigh: Double?
    var estimatedValueSource: String?
    var estimatedValueConfidence: Int?
    /// Phase 18g: AI-derived value reasoning paragraph (only set when source = "ai_comps").
    var estimatedValueReasoning: String?
    var squareFootage: Int?
    var yearBuilt: Int?
    var ownershipEntity: String?
    var notes: String?
    var attributes: [String: FlexibleValue]?
    var houseQuizState: HouseQuizState?
    /// Phase 57: Regional maintenance pack. Updating `state` via this
    /// struct does NOT recompute this; callers that change state also need
    /// to recompute via `RegionalPack(state:)` and pass the new value here.
    var regionalPack: String?

    enum CodingKeys: String, CodingKey {
        case name, street, unit, city, state, notes, attributes
        case propertyType = "property_type"
        case zipCode = "zip_code"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currentEstimatedValue = "current_estimated_value"
        case currentEstimatedValueLow = "current_estimated_value_low"
        case currentEstimatedValueHigh = "current_estimated_value_high"
        case estimatedValueSource = "estimated_value_source"
        case estimatedValueConfidence = "estimated_value_confidence"
        case estimatedValueReasoning = "estimated_value_reasoning"
        case squareFootage = "square_footage"
        case yearBuilt = "year_built"
        case ownershipEntity = "ownership_entity"
        case houseQuizState = "house_quiz_state"
        case regionalPack = "regional_pack"
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
    /// Phase 50: Per-system service interval override. When non-nil it
    /// supersedes the template's default frequency for due-date math.
    /// Set by the post-quiz cadence sheet, the system detail frequency
    /// editor, or the invoice cadence prompt.
    let serviceIntervalDays: Int?
    /// Phase 50: Provenance for `serviceIntervalDays`. One of "default"
    /// (no override), "onboarding" (post-quiz), "vendor_invoice" (from
    /// process-invoice cadence detection), "manual" (system detail
    /// frequency editor). Used to render the source caption.
    let serviceIntervalSource: String?
    /// Chez v1: provenance for `installDate`. One of `exact`,
    /// `estimated`, `unknown`, or nil (legacy rows). Drives the
    /// gamified system-coverage flow and the SystemProfileAudit so
    /// "I don't know" rows stop appearing in the missing-profile
    /// list for ~90 days.
    let installDateSource: String?
    /// Set when the user explicitly answers "I don't know". The audit
    /// treats systems with this stamp as satisfied for ~90 days, then
    /// re-surfaces them in case the homeowner found paperwork in the
    /// meantime.
    let installDateUnknownAt: Date?
    /// True when ATTOM (or another public-records source) pre-filled
    /// this system's install date. The coverage flow shows these as
    /// "estimated from public records. Confirm or correct".
    let installDateAttomPrefilled: Bool?
    /// Set when the user has confirmed an ATTOM pre-fill (or otherwise
    /// signed off). Lets us distinguish "user hasn't reviewed" from
    /// "user reviewed and kept it".
    let installDateConfirmedAt: Date?
    /// Chez v1: soft-delete timestamp. Set when the user picks "I
    /// don't have this" in `SystemCoverageFlow` or when the one-time
    /// backfill retires service-shaped rows. Every property-level
    /// read filters `archived_at IS NULL` so an archived row is
    /// invisible without being lost. Mirrors the routines pattern.
    let archivedAt: Date?
    /// Phase 67 (reconciler v2): set when a vendor-required template
    /// targets this system but no matching contractor exists. Replaces
    /// the legacy "Find a contractor for X" seeded task. Read by
    /// `VendorCoverageSheet` to surface the consolidated gap card.
    let needsVendorCoverage: Bool?
    /// Phase 84 — universal entity-level Chez delegation. When true the
    /// homeowner has handed this specific system over to Chez to manage
    /// end-to-end (service scheduling, warranty, parts, history).
    let chezOwned: Bool?
    let chezOwnedAt: Date?
    /// Phase 84.5 G18 — handyman-rated condition at last assessment.
    /// Values: good / fair / needs_attention / urgent.
    let conditionRating: String?
    let conditionNotes: String?
    let conditionPhotos: [String]?
    let lastAssessedAt: Date?
    /// Phase 84.5 G44 — false for decommissioned systems (e.g. old well
    /// after city water hookup). Reconciler skips inactive systems.
    let isActive: Bool?
    let decommissionedAt: Date?
    let decommissionedReason: String?
    /// Phase 84.5 G15 — display-only origin tag. self_quiz / handyman_assessment
    /// / manual / attom / invoice_extraction / chez_admin.
    let onboardedVia: String?

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
        case serviceIntervalDays = "service_interval_days"
        case serviceIntervalSource = "service_interval_source"
        case installDateSource = "install_date_source"
        case installDateUnknownAt = "install_date_unknown_at"
        case installDateAttomPrefilled = "install_date_attom_prefilled"
        case installDateConfirmedAt = "install_date_confirmed_at"
        case archivedAt = "archived_at"
        case needsVendorCoverage = "needs_vendor_coverage"
        case chezOwned = "chez_owned"
        case chezOwnedAt = "chez_owned_at"
        case conditionRating = "condition_rating"
        case conditionNotes = "condition_notes"
        case conditionPhotos = "condition_photos"
        case lastAssessedAt = "last_assessed_at"
        case isActive = "is_active"
        case decommissionedAt = "decommissioned_at"
        case decommissionedReason = "decommissioned_reason"
        case onboardedVia = "onboarded_via"
    }

    /// Convenience used across views/UI.
    var isChezOwned: Bool { chezOwned ?? false }

    /// Phase 84.5 G44 — true unless the system has been explicitly
    /// decommissioned. Defaults to true for legacy rows missing the column.
    var isActiveOrDefault: Bool { isActive ?? true }
}

extension HomeSystemRow: Hashable {
    static func == (lhs: HomeSystemRow, rhs: HomeSystemRow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
        serviceIntervalDays = try? c.decodeIfPresent(Int.self, forKey: .serviceIntervalDays)
        serviceIntervalSource = try? c.decodeIfPresent(String.self, forKey: .serviceIntervalSource)
        installDateSource = try? c.decodeIfPresent(String.self, forKey: .installDateSource)
        installDateUnknownAt = try? c.decodeIfPresent(Date.self, forKey: .installDateUnknownAt)
        installDateAttomPrefilled = try? c.decodeIfPresent(Bool.self, forKey: .installDateAttomPrefilled)
        installDateConfirmedAt = try? c.decodeIfPresent(Date.self, forKey: .installDateConfirmedAt)
        archivedAt = try? c.decodeIfPresent(Date.self, forKey: .archivedAt)
        needsVendorCoverage = try? c.decodeIfPresent(Bool.self, forKey: .needsVendorCoverage)
        chezOwned = try? c.decodeIfPresent(Bool.self, forKey: .chezOwned)
        chezOwnedAt = try? c.decodeIfPresent(Date.self, forKey: .chezOwnedAt)
        conditionRating = try? c.decodeIfPresent(String.self, forKey: .conditionRating)
        conditionNotes = try? c.decodeIfPresent(String.self, forKey: .conditionNotes)
        conditionPhotos = try? c.decodeIfPresent([String].self, forKey: .conditionPhotos)
        lastAssessedAt = try? c.decodeIfPresent(Date.self, forKey: .lastAssessedAt)
        isActive = try? c.decodeIfPresent(Bool.self, forKey: .isActive)
        decommissionedAt = try? c.decodeIfPresent(Date.self, forKey: .decommissionedAt)
        decommissionedReason = try? c.decodeIfPresent(String.self, forKey: .decommissionedReason)
        onboardedVia = try? c.decodeIfPresent(String.self, forKey: .onboardedVia)
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
    /// Chez v1: source of the `installDate` value at insert time.
    /// `estimated` is set by the ATTOM pre-fill path; `exact` is used
    /// by manual-entry inserts when the user provided a date.
    var installDateSource: String?
    /// True for inserts where ATTOM (or another public-records source)
    /// supplied the install date — drives the "Confirm or correct"
    /// banner in the coverage flow.
    var installDateAttomPrefilled: Bool?

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
        case installDateSource = "install_date_source"
        case installDateAttomPrefilled = "install_date_attom_prefilled"
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
    /// Phase 50: Override service interval in days. Stored on the
    /// system row so all template-driven tasks attached to it can pull
    /// the same cadence.
    var serviceIntervalDays: Int?
    /// Phase 50: Provenance string — see HomeSystemRow.serviceIntervalSource.
    var serviceIntervalSource: String?
    /// Chez v1: provenance for `installDate`. `exact` / `estimated` /
    /// `unknown` / nil. Updated by the gamified coverage flow.
    var installDateSource: String?
    /// Set when the user explicitly answers "I don't know" so the
    /// audit gives the system a 90-day cooldown.
    var installDateUnknownAt: Date?
    /// Cleared (false) when the user manually edits the install date,
    /// or set true when ATTOM pre-fills.
    var installDateAttomPrefilled: Bool?
    /// Set when the user confirms an ATTOM pre-fill or saves an
    /// exact / estimated date.
    var installDateConfirmedAt: Date?
    /// Chez v1: soft-delete timestamp. Set when the user picks "I
    /// don't have this" in the coverage flow, or when the legacy
    /// service-row backfill retires Pet Waste / Cleaning / Trash &
    /// Recycling / etc. rows.
    var archivedAt: Date?
    /// Phase 67 (reconciler v2): toggled by the reconciler when a
    /// vendor-required template targets this system but no matching
    /// contractor exists. Cleared when a contractor is added.
    var needsVendorCoverage: Bool?

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
        case serviceIntervalDays = "service_interval_days"
        case serviceIntervalSource = "service_interval_source"
        case installDateSource = "install_date_source"
        case installDateUnknownAt = "install_date_unknown_at"
        case installDateAttomPrefilled = "install_date_attom_prefilled"
        case installDateConfirmedAt = "install_date_confirmed_at"
        case archivedAt = "archived_at"
        case needsVendorCoverage = "needs_vendor_coverage"
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
    /// Phase 19k: Primary category for fast reconciler lookup. Should match
    /// home_systems.category. Multi-discipline contractors keep their full
    /// list in `specialties` and use the most-relevant single value here.
    let category: String?
    /// Phase 19k: When the contractor was mirrored from a quiz utility_account
    /// pick, this points back at the source utility_providers row so we can
    /// keep logo/brand-color in sync.
    let utilityProviderId: UUID?
    /// Phase 19k: Snapshotted brand identity from the utility_providers row.
    let logoUrl: String?
    let brandColor: String?
    let website: String?
    /// Phase 19k: How this contractor was added — "manual", "quiz",
    /// "find_vendor" (Google Places), or "chez_field" (provider directory).
    let source: String?
    /// Phase 80.1: When true, Chez is the homeowner's point of contact
    /// for this vendor — handles scheduling and follow-ups directly with
    /// them. Stamped via `delegate_contractor` Edge Function action.
    let chezOwned: Bool?
    let chezOwnedAt: Date?

    /// Phase 80.1 helper: defaults nil → false. Use this everywhere in
    /// the UI to avoid optional-handling at every call site.
    var isChezOwned: Bool { chezOwned ?? false }

    enum CodingKeys: String, CodingKey {
        case id, phone, email, specialties, address, rating, notes, category, source, website
        case householdId = "household_id"
        case companyName = "company_name"
        case contactName = "contact_name"
        case licenseNumber = "license_number"
        case insuranceVerified = "insurance_verified"
        case createdAt = "created_at"
        case utilityProviderId = "utility_provider_id"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
        case chezOwned = "chez_owned"
        case chezOwnedAt = "chez_owned_at"
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
    var category: String?
    var utilityProviderId: UUID?
    var logoUrl: String?
    var brandColor: String?
    var website: String?
    var source: String?

    enum CodingKeys: String, CodingKey {
        case phone, email, specialties, address, rating, notes, category, source, website
        case householdId = "household_id"
        case companyName = "company_name"
        case contactName = "contact_name"
        case licenseNumber = "license_number"
        case insuranceVerified = "insurance_verified"
        case utilityProviderId = "utility_provider_id"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
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
    var category: String?
    var utilityProviderId: UUID?
    var logoUrl: String?
    var brandColor: String?
    var website: String?
    var source: String?

    enum CodingKeys: String, CodingKey {
        case phone, email, specialties, address, rating, notes, category, source, website
        case companyName = "company_name"
        case contactName = "contact_name"
        case licenseNumber = "license_number"
        case insuranceVerified = "insurance_verified"
        case utilityProviderId = "utility_provider_id"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
    }
}

struct HandymanProviderDirectoryRow: Codable, Identifiable, Hashable {
    let id: String
    let companyName: String
    let primaryEmail: String?
    let primaryPhone: String?
    let website: String?
    let activeMemberCount: Int?
    let invitedMemberCount: Int?
    let isLinked: Bool
    let isPreferred: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case companyName
        case primaryEmail
        case primaryPhone
        case website
        case activeMemberCount
        case invitedMemberCount
        case isLinked
        case isPreferred
    }
}

struct HandymanProviderDirectoryResponse: Codable {
    let providers: [HandymanProviderDirectoryRow]
}

struct HandymanProviderLinkResponse: Codable {
    let contractor: ContractorRow
    let workspace: HandymanProviderDirectoryRow?
}

// MARK: - Premier Handyman Program

enum HandymanRequestStatus: String, Codable, CaseIterable {
    case draft
    case submitted
    case scheduled
    case sentToHandyman = "sent_to_handyman"
    case alternateDatesProposed = "alternate_dates_proposed"
    case awaitingHomeowner = "awaiting_homeowner"
    case confirmed
    case onMyWay = "on_my_way"
    case checkedIn = "checked_in"
    case quoted
    case inProgress = "in_progress"
    case completed
    case followUpRecommended = "follow_up_recommended"
    case cancelled
    case declined

    var displayLabel: String {
        switch self {
        case .draft:
            return "Draft"
        case .submitted:
            return "Requested"
        case .scheduled:
            return "Scheduled"
        case .sentToHandyman:
            return "Sent to handyman"
        case .alternateDatesProposed:
            return "Dates proposed"
        case .awaitingHomeowner:
            return "Reply needed"
        case .confirmed:
            return "Confirmed"
        case .onMyWay:
            return "On my way"
        case .checkedIn:
            return "Checked in"
        case .quoted:
            return "Quoted"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .followUpRecommended:
            return "Follow-up recommended"
        case .cancelled:
            return "Cancelled"
        case .declined:
            return "Declined"
        }
    }

    var homeownerSummary: String {
        switch self {
        case .draft:
            return "This visit is still a draft."
        case .submitted:
            return "Chez saved the request and is getting it ready to send."
        case .scheduled:
            return "The visit has a date, but the handyman still needs the full Chez confirmation flow."
        case .sentToHandyman:
            return "The handyman has the visit link and still needs to confirm or suggest another date."
        case .alternateDatesProposed:
            return "The handyman asked for different timing."
        case .awaitingHomeowner:
            return "The handyman sent a question or note that needs a homeowner reply."
        case .confirmed:
            return "Both sides are aligned and the visit is confirmed."
        case .onMyWay:
            return "The handyman is on the way."
        case .checkedIn:
            return "The handyman has checked in and started the visit."
        case .quoted:
            return "A quote is ready for review."
        case .inProgress:
            return "The visit is actively in progress."
        case .completed:
            return "The visit is complete."
        case .followUpRecommended:
            return "The handyman finished and recommended follow-up work."
        case .cancelled:
            return "This request was cancelled."
        case .declined:
            return "The handyman declined this visit."
        }
    }

    var actionRequiredByHomeowner: Bool {
        self == .alternateDatesProposed || self == .awaitingHomeowner || self == .quoted || self == .followUpRecommended
    }
}

struct HandymanRequestRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let propertyId: UUID?
    let contractorId: UUID?
    let visitTaskId: UUID?
    let createdByUserId: UUID?
    let requestType: String
    let source: String
    let title: String
    let details: String?
    let preferredTiming: String?
    let urgency: String
    let status: String
    let firstVisitSetupRequested: Bool
    let recommendedLane: String?
    let quickUpsellTitles: [String]
    /// Phase 73 sub-phase A: most-recent-proposal columns. Both sides walk
    /// the schedule round-trip via `propose_visit_time`; the columns
    /// reflect the latest state. `confirmedVisitAt` is non-nil once one
    /// side accepts. Old rows (pre-Phase-73) read these as nil.
    let proposedVisitAt: Date?
    let proposedByRole: String?
    let proposedAt: Date?
    let confirmedVisitAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, source, title, details, urgency, status
        case householdId = "household_id"
        case propertyId = "property_id"
        case contractorId = "contractor_id"
        case visitTaskId = "visit_task_id"
        case createdByUserId = "created_by_user_id"
        case requestType = "request_type"
        case preferredTiming = "preferred_timing"
        case firstVisitSetupRequested = "first_visit_setup_requested"
        case recommendedLane = "recommended_lane"
        case quickUpsellTitles = "quick_upsell_titles"
        case proposedVisitAt = "proposed_visit_at"
        case proposedByRole = "proposed_by_role"
        case proposedAt = "proposed_at"
        case confirmedVisitAt = "confirmed_visit_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension HandymanRequestRow {
    var typedStatus: HandymanRequestStatus {
        HandymanRequestStatus(rawValue: status) ?? .submitted
    }

    /// Phase 73: which side proposed the most-recent time. Used by the
    /// scheduling UI to decide whether the current viewer should see
    /// "Accept / Counter" or just "Propose a date".
    var proposedByActor: HandymanScheduleActor? {
        guard let role = proposedByRole else { return nil }
        return HandymanScheduleActor(rawValue: role)
    }

    /// True when there's a proposal sitting on the request that's not yet
    /// been accepted. Drives the homeowner's "ball is in your court" UI.
    var hasOpenProposal: Bool {
        proposedVisitAt != nil && confirmedVisitAt == nil
    }
}

/// Mirrors the SQL CHECK constraint on `proposed_by_role` /
/// `accepted_by_role` and the message metadata's `proposed_by_role`
/// field. Use the raw value when calling the propose / accept RPCs.
enum HandymanScheduleActor: String, Codable {
    case homeowner
    case handyman
}

/// Discriminator for `handyman_request_messages.metadata.kind`. Both the
/// homeowner iOS thread view and the provider PWA thread view branch on
/// this to render system events (proposals, accepts) differently from
/// free-text replies. Unknown values fall back to `.text` so a future
/// new event type doesn't break older clients.
enum HandymanMessageKind: String, Codable {
    case text
    case proposeTime = "propose_time"
    case acceptTime = "accept_time"
    case declineTime = "decline_time"
    /// Provider sent a quote — message renders as a rich card with
    /// the dollar total and a "Review quote" CTA that opens the
    /// HandymanQuoteReviewSheet.
    case quoteSent = "quote_sent"
}

extension HandymanRequestMessageRow {
    /// Resolved discriminator. Returns `.text` for legacy messages whose
    /// `metadata` is empty or missing the `kind` field.
    var typedKind: HandymanMessageKind {
        guard let raw = metadata?["kind"]?.stringValue,
              let kind = HandymanMessageKind(rawValue: raw)
        else {
            return .text
        }
        return kind
    }

    /// For `.proposeTime` events, the proposed visit timestamp parsed
    /// out of metadata. Returns nil for any other event kind or when
    /// the metadata is malformed.
    var proposedTime: Date? {
        guard typedKind == .proposeTime,
              let iso = metadata?["proposed_at"]?.stringValue
        else {
            return nil
        }
        return ISO8601DateFormatter.handymanScheduleFormatter.date(from: iso)
    }

    /// For `.acceptTime` events, the confirmed visit timestamp.
    var confirmedTime: Date? {
        guard typedKind == .acceptTime,
              let iso = metadata?["confirmed_at"]?.stringValue
        else {
            return nil
        }
        return ISO8601DateFormatter.handymanScheduleFormatter.date(from: iso)
    }

    /// For `.quoteSent` events, the linked provider_quotes.id so the
    /// rich card can deep-link into the quote review sheet.
    var quoteId: UUID? {
        guard typedKind == .quoteSent,
              let raw = metadata?["quote_id"]?.stringValue
        else { return nil }
        return UUID(uuidString: raw)
    }

    /// For `.quoteSent` events, the dollar total parsed out of metadata.
    var quoteTotal: Double? {
        guard typedKind == .quoteSent, let value = metadata?["total"] else { return nil }
        switch value {
        case .double(let d): return d
        case .int(let i): return Double(i)
        case .string(let s): return Double(s)
        default: return nil
        }
    }

    /// For `.quoteSent` events, the line-item count for the card subtitle.
    var quoteLineItemCount: Int? {
        guard typedKind == .quoteSent, let value = metadata?["line_item_count"] else { return nil }
        switch value {
        case .int(let i): return i
        case .double(let d): return Int(d)
        case .string(let s): return Int(s)
        default: return nil
        }
    }
}

private extension ISO8601DateFormatter {
    /// Matches the `YYYY-MM-DD"T"HH24:MI:SS"Z"` to_char format used by
    /// the Phase 73 RPCs when stamping metadata. Standard ISO8601 sans
    /// fractional seconds.
    static let handymanScheduleFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

struct HandymanRequestInsert: Codable {
    let householdId: UUID
    var propertyId: UUID?
    var contractorId: UUID?
    var visitTaskId: UUID?
    var createdByUserId: UUID?
    let requestType: String
    var source: String = "homeowner"
    let title: String
    var details: String?
    var preferredTiming: String?
    var urgency: String = "routine"
    var status: String = "submitted"
    var firstVisitSetupRequested: Bool = false
    var recommendedLane: String?
    var quickUpsellTitles: [String] = []

    enum CodingKeys: String, CodingKey {
        case source, title, details, urgency, status
        case householdId = "household_id"
        case propertyId = "property_id"
        case contractorId = "contractor_id"
        case visitTaskId = "visit_task_id"
        case createdByUserId = "created_by_user_id"
        case requestType = "request_type"
        case preferredTiming = "preferred_timing"
        case firstVisitSetupRequested = "first_visit_setup_requested"
        case recommendedLane = "recommended_lane"
        case quickUpsellTitles = "quick_upsell_titles"
    }
}

struct HandymanRequestUpdate: Codable {
    var contractorId: UUID?
    var visitTaskId: UUID?
    var title: String?
    var details: String?
    var preferredTiming: String?
    var urgency: String?
    var status: String?
    var firstVisitSetupRequested: Bool?
    var recommendedLane: String?
    var quickUpsellTitles: [String]?
    var updatedAt: Date? = Date()

    enum CodingKeys: String, CodingKey {
        case title, details, urgency, status
        case contractorId = "contractor_id"
        case visitTaskId = "visit_task_id"
        case preferredTiming = "preferred_timing"
        case firstVisitSetupRequested = "first_visit_setup_requested"
        case recommendedLane = "recommended_lane"
        case quickUpsellTitles = "quick_upsell_titles"
        case updatedAt = "updated_at"
    }
}

struct HandymanRequestMessageRow: Codable, Identifiable {
    let id: UUID
    let requestId: UUID
    let householdId: UUID
    let senderRole: String
    let body: String
    let metadata: [String: FlexibleValue]?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, body, metadata
        case requestId = "request_id"
        case householdId = "household_id"
        case senderRole = "sender_role"
        case createdAt = "created_at"
    }
}

struct HandymanRequestMessageInsert: Codable {
    let requestId: UUID
    let householdId: UUID
    let senderRole: String
    let body: String
    var metadata: [String: String]? = nil

    enum CodingKeys: String, CodingKey {
        case body, metadata
        case requestId = "request_id"
        case householdId = "household_id"
        case senderRole = "sender_role"
    }
}

struct HandymanPortalChecklistItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let category: String?
    let status: String
    let source: String
    let recommended: Bool
}

struct HandymanPortalSetupPrompt: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let category: String
    let isRequired: Bool
}

struct HandymanPortalUpsell: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let category: String
    let priceHint: String?
    let minutesHint: Int?
}

struct HandymanPortalSystemRecord: Codable, Identifiable, Hashable {
    let id: String
    let systemId: UUID?
    let name: String
    let category: String
    let manufacturer: String?
    let modelNumber: String?
    let serialNumber: String?
    let installDate: String?
    let notes: String?
    let lastServiceDate: String?
    let nextServiceDue: String?
    let needsSetup: Bool
    let serviced: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, category, manufacturer, notes
        case systemId = "system_id"
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case lastServiceDate = "last_service_date"
        case nextServiceDue = "next_service_due"
        case needsSetup = "needs_setup"
        case serviced
    }
}

struct HandymanPortalRecommendation: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let category: String
    let priority: String
    let createFollowUp: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, detail, category, priority
        case createFollowUp = "create_follow_up"
    }
}

struct HandymanPortalCoordinationState: Codable, Hashable {
    let requestId: UUID?
    let status: String
    let statusLabel: String
    let intro: String
    let lastMessage: String?
    let scheduledDate: String?
    let requestTitle: String?
    let needsHomeownerReply: Bool

    enum CodingKeys: String, CodingKey {
        case status, intro
        case requestId = "request_id"
        case statusLabel = "status_label"
        case lastMessage = "last_message"
        case scheduledDate = "scheduled_date"
        case requestTitle = "request_title"
        case needsHomeownerReply = "needs_homeowner_reply"
    }
}

struct HandymanPortalPropertySnapshot: Codable, Hashable {
    let name: String
    let addressLine: String?
    let propertyType: String
    let squareFootage: Int?
    let yearBuilt: Int?
    let systemCount: Int
    let knownSystems: [String]
    let systems: [HandymanPortalSystemRecord]?

    enum CodingKeys: String, CodingKey {
        case name
        case addressLine = "address_line"
        case propertyType = "property_type"
        case squareFootage = "square_footage"
        case yearBuilt = "year_built"
        case systemCount = "system_count"
        case knownSystems = "known_systems"
        case systems
    }
}

struct HandymanPortalSeedPayload: Codable, Hashable {
    let visitId: UUID?
    let visitTitle: String
    let scheduledDate: String?
    let dueDate: String?
    let firstVisit: Bool
    let property: HandymanPortalPropertySnapshot
    let contractorName: String?
    let contractorPhone: String?
    let contractorEmail: String?
    let homeownerNotes: String?
    let checklist: [HandymanPortalChecklistItem]
    let diyClaims: [HandymanPortalChecklistItem]
    let quickUpsells: [HandymanPortalUpsell]
    let setupPrompts: [HandymanPortalSetupPrompt]
    let coordination: HandymanPortalCoordinationState?
    let recommendations: [HandymanPortalRecommendation]?

    enum CodingKeys: String, CodingKey {
        case visitId = "visit_id"
        case visitTitle = "visit_title"
        case scheduledDate = "scheduled_date"
        case dueDate = "due_date"
        case firstVisit = "first_visit"
        case property
        case contractorName = "contractor_name"
        case contractorPhone = "contractor_phone"
        case contractorEmail = "contractor_email"
        case homeownerNotes = "homeowner_notes"
        case checklist
        case diyClaims = "diy_claims"
        case quickUpsells = "quick_upsells"
        case setupPrompts = "setup_prompts"
        case coordination
        case recommendations
    }
}

struct HandymanPortalSessionRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let propertyId: UUID?
    let contractorId: UUID?
    let visitTaskId: UUID?
    let createdByUserId: UUID?
    let title: String
    let portalToken: String
    let status: String
    let firstVisit: Bool
    let seedPayload: HandymanPortalSeedPayload
    let lastOpenedAt: Date?
    /// Phase 95 (gap #67): timestamp of the most recent successful
    /// Messages-composer SMS invite send. Set by iOS when the user
    /// taps Send in MFMessageComposeViewController. Combined with
    /// `lastOpenedAt` lets the visit detail view surface "Invite sent
    /// 6h ago, no opens yet" so the homeowner can re-send, switch
    /// channels, or escalate.
    let lastInviteSentAt: Date?
    let expiresAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case householdId = "household_id"
        case propertyId = "property_id"
        case contractorId = "contractor_id"
        case visitTaskId = "visit_task_id"
        case createdByUserId = "created_by_user_id"
        case portalToken = "portal_token"
        case firstVisit = "first_visit"
        case seedPayload = "seed_payload"
        case lastOpenedAt = "last_opened_at"
        case lastInviteSentAt = "last_invite_sent_at"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct HandymanPortalSessionInsert: Codable {
    let householdId: UUID
    var propertyId: UUID?
    var contractorId: UUID?
    var visitTaskId: UUID?
    var createdByUserId: UUID?
    let title: String
    let portalToken: String
    var status: String = "active"
    var firstVisit: Bool = false
    let seedPayload: HandymanPortalSeedPayload
    var expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case title, status
        case householdId = "household_id"
        case propertyId = "property_id"
        case contractorId = "contractor_id"
        case visitTaskId = "visit_task_id"
        case createdByUserId = "created_by_user_id"
        case portalToken = "portal_token"
        case firstVisit = "first_visit"
        case seedPayload = "seed_payload"
        case expiresAt = "expires_at"
    }
}

struct HandymanPortalSessionUpdate: Codable {
    var status: String?
    var portalToken: String?
    var seedPayload: HandymanPortalSeedPayload?
    var lastOpenedAt: Date?
    var lastInviteSentAt: Date?
    var expiresAt: Date?
    var updatedAt: Date? = Date()

    enum CodingKeys: String, CodingKey {
        case status
        case portalToken = "portal_token"
        case seedPayload = "seed_payload"
        case lastOpenedAt = "last_opened_at"
        case lastInviteSentAt = "last_invite_sent_at"
        case expiresAt = "expires_at"
        case updatedAt = "updated_at"
    }
}

struct HandymanVisitReportRow: Codable, Identifiable {
    let id: UUID
    let portalSessionId: UUID
    let householdId: UUID
    let propertyId: UUID?
    let contractorId: UUID?
    let visitTaskId: UUID?
    let requestId: UUID?
    let reportStatus: String
    let checklist: [HandymanPortalChecklistItem]
    let setupPrompts: [HandymanPortalSetupPrompt]
    let quickUpsells: [HandymanPortalUpsell]
    let homeownerNotes: String?
    let fieldNotes: String?
    let systemsSnapshot: [HandymanPortalSystemRecord]?
    let recommendations: [HandymanPortalRecommendation]?
    let coordinationStatus: String?
    let startedAt: Date?
    let completedAt: Date?
    let lastSyncedAt: Date
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, checklist
        case portalSessionId = "portal_session_id"
        case householdId = "household_id"
        case propertyId = "property_id"
        case contractorId = "contractor_id"
        case visitTaskId = "visit_task_id"
        case requestId = "request_id"
        case reportStatus = "report_status"
        case setupPrompts = "setup_prompts"
        case quickUpsells = "quick_upsells"
        case homeownerNotes = "homeowner_notes"
        case fieldNotes = "field_notes"
        case systemsSnapshot = "systems_snapshot"
        case recommendations
        case coordinationStatus = "coordination_status"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case lastSyncedAt = "last_synced_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct HandymanVisitReportInsert: Codable {
    let portalSessionId: UUID
    let householdId: UUID
    var propertyId: UUID?
    var contractorId: UUID?
    var visitTaskId: UUID?
    var requestId: UUID?
    var reportStatus: String = "draft"
    var checklist: [HandymanPortalChecklistItem] = []
    var setupPrompts: [HandymanPortalSetupPrompt] = []
    var quickUpsells: [HandymanPortalUpsell] = []
    var homeownerNotes: String?
    var fieldNotes: String?
    var systemsSnapshot: [HandymanPortalSystemRecord]?
    var recommendations: [HandymanPortalRecommendation]?
    var coordinationStatus: String?
    var startedAt: Date?
    var completedAt: Date?
    var lastSyncedAt: Date? = Date()

    enum CodingKeys: String, CodingKey {
        case checklist
        case portalSessionId = "portal_session_id"
        case householdId = "household_id"
        case propertyId = "property_id"
        case contractorId = "contractor_id"
        case visitTaskId = "visit_task_id"
        case requestId = "request_id"
        case reportStatus = "report_status"
        case setupPrompts = "setup_prompts"
        case quickUpsells = "quick_upsells"
        case homeownerNotes = "homeowner_notes"
        case fieldNotes = "field_notes"
        case systemsSnapshot = "systems_snapshot"
        case recommendations
        case coordinationStatus = "coordination_status"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case lastSyncedAt = "last_synced_at"
    }
}

struct HandymanVisitReportUpdate: Codable {
    var reportStatus: String?
    var checklist: [HandymanPortalChecklistItem]?
    var setupPrompts: [HandymanPortalSetupPrompt]?
    var quickUpsells: [HandymanPortalUpsell]?
    var homeownerNotes: String?
    var fieldNotes: String?
    var systemsSnapshot: [HandymanPortalSystemRecord]?
    var recommendations: [HandymanPortalRecommendation]?
    var coordinationStatus: String?
    var startedAt: Date?
    var completedAt: Date?
    var lastSyncedAt: Date? = Date()
    var updatedAt: Date? = Date()

    enum CodingKeys: String, CodingKey {
        case checklist
        case reportStatus = "report_status"
        case setupPrompts = "setup_prompts"
        case quickUpsells = "quick_upsells"
        case homeownerNotes = "homeowner_notes"
        case fieldNotes = "field_notes"
        case systemsSnapshot = "systems_snapshot"
        case recommendations
        case coordinationStatus = "coordination_status"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case lastSyncedAt = "last_synced_at"
        case updatedAt = "updated_at"
    }
}

struct ProviderQuoteLineItem: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var description: String?
    var unit: String
    /// Phase 73 sub-phase B: mutable so the homeowner counter sheet can
    /// bind `$item.quantity` / `$item.unitPrice` via SwiftUI's Form
    /// inputs and recompute totals live.
    var quantity: Double
    var unitPrice: Double

    enum CodingKeys: String, CodingKey {
        case id, name, description, unit, quantity
        case unitPrice = "unit_price"
    }
}

enum ProviderQuoteStatus: String, Codable, CaseIterable {
    case draft
    case sent
    case viewed
    case approved
    case declined
    case withdrawn
    /// Phase 73 sub-phase B: homeowner edited line items and sent the
    /// quote back to the provider. The countered row is the new active
    /// quote in the chain; its `parent_quote_id` points at the version
    /// the homeowner started from. Provider re-quotes by inserting a
    /// fresh draft pointing at the countered row, OR approves it as-is.
    case counteredByHomeowner = "countered_by_homeowner"
    /// Phase 73 sub-phase B: terminal state for any quote that's been
    /// replaced by a child revision. Hidden from "active" filters but
    /// kept for the audit trail.
    case superseded

    var displayLabel: String {
        switch self {
        case .draft:
            return "Draft"
        case .sent:
            return "Sent"
        case .viewed:
            return "Viewed"
        case .approved:
            return "Approved"
        case .declined:
            return "Declined"
        case .withdrawn:
            return "Withdrawn"
        case .counteredByHomeowner:
            return "Countered"
        case .superseded:
            return "Superseded"
        }
    }

    var homeownerActionRequired: Bool {
        self == .sent || self == .viewed
    }

    /// True when the homeowner can edit + counter from this state.
    var allowsCounter: Bool {
        self == .sent || self == .viewed
    }

    /// True when the homeowner can sign-and-approve from this state.
    /// Includes `counteredByHomeowner` so the homeowner can sign their
    /// own counter without waiting for provider re-quote.
    var allowsSign: Bool {
        self == .sent || self == .viewed || self == .counteredByHomeowner
    }
}

/// One Q&A entry on a quote — either a homeowner question or a
/// provider reply. `lineItemId` is null for quote-level comments.
/// Phase 75h.
struct ProviderQuoteCommentRow: Codable, Identifiable {
    let id: UUID
    let quoteId: UUID
    let lineItemId: String?
    let parentCommentId: UUID?
    let authorRole: String
    let authorUserId: UUID?
    let body: String
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, body, status
        case quoteId = "quote_id"
        case lineItemId = "line_item_id"
        case parentCommentId = "parent_comment_id"
        case authorRole = "author_role"
        case authorUserId = "author_user_id"
        case createdAt = "created_at"
    }

    var isHomeowner: Bool { authorRole == "homeowner" }
    var isProvider: Bool { authorRole == "provider" }
}

struct ProviderQuoteCommentInsert: Codable {
    let quoteId: UUID
    let lineItemId: String?
    let body: String
    var parentCommentId: UUID? = nil
    let authorRole: String

    enum CodingKeys: String, CodingKey {
        case body
        case quoteId = "quote_id"
        case lineItemId = "line_item_id"
        case parentCommentId = "parent_comment_id"
        case authorRole = "author_role"
    }
}

struct ProviderQuoteRow: Codable, Identifiable {
    let id: UUID
    let workspaceId: UUID
    let contractorId: UUID?
    let householdId: UUID
    let propertyId: UUID?
    let requestId: UUID?
    let visitTaskId: UUID?
    let title: String
    let status: String
    let currency: String
    let lineItems: [ProviderQuoteLineItem]
    let scopeNotes: String?
    let homeownerMessage: String?
    let subtotal: Double
    let taxTotal: Double
    let total: Double
    let sentAt: Date?
    let viewedAt: Date?
    let approvedAt: Date?
    let declinedAt: Date?
    /// Phase 73 sub-phase B: revision chain pointer. Non-nil when this
    /// row was created by `counter_provider_quote` or by a provider
    /// re-quote. Walk parent_quote_id to render history.
    let parentQuoteId: UUID?
    /// Phase 73 sub-phase B: stamped when a homeowner signs the quote.
    let signedAt: Date?
    let signedName: String?
    /// Phase 73 sub-phase B: stamped when the homeowner submits a
    /// counter (lets the provider sort countered quotes that need a
    /// re-quote).
    let homeownerRevisedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, status, currency, subtotal, total
        case workspaceId = "workspace_id"
        case contractorId = "contractor_id"
        case householdId = "household_id"
        case propertyId = "property_id"
        case requestId = "request_id"
        case visitTaskId = "visit_task_id"
        case lineItems = "line_items"
        case scopeNotes = "scope_notes"
        case homeownerMessage = "homeowner_message"
        case taxTotal = "tax_total"
        case sentAt = "sent_at"
        case viewedAt = "viewed_at"
        case approvedAt = "approved_at"
        case declinedAt = "declined_at"
        case parentQuoteId = "parent_quote_id"
        case signedAt = "signed_at"
        case signedName = "signed_name"
        case homeownerRevisedAt = "homeowner_revised_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension ProviderQuoteRow {
    var typedStatus: ProviderQuoteStatus {
        ProviderQuoteStatus(rawValue: status) ?? .draft
    }
}

struct ProviderSavedQuoteItemRow: Codable, Identifiable {
    let id: UUID
    let workspaceId: UUID
    let createdByUserId: UUID?
    let name: String
    let description: String?
    let unit: String
    let defaultQuantity: Double
    let defaultUnitPrice: Double
    let sortOrder: Int
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, unit
        case workspaceId = "workspace_id"
        case createdByUserId = "created_by_user_id"
        case defaultQuantity = "default_quantity"
        case defaultUnitPrice = "default_unit_price"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
    /// Soft-delete flag (Phase 17b). Tasks the reconciler prunes are marked
    /// archived rather than deleted so history is recoverable. Optional so
    /// pre-migration responses still decode cleanly.
    let isArchived: Bool?
    let archivedAt: Date?
    /// Phase 61: Human-readable archive reason (e.g. `subtype_mismatch:HVAC:ducted`,
    /// `backfilled_to_bundle:Generator:annual`, `template_retired_p61:<templateKey>`).
    /// Surfaced in the LegacyTasksView so users can see WHY Haven tidied a task.
    let archivedReason: String?
    /// Phase 19k: How the task should be presented in the UI.
    /// "personal" → user does it themselves (default for DIY tasks)
    /// "vendor"   → a contractor handles the work, user just confirms/schedules
    /// "either"   → could be either, default to personal until reassigned
    let assignmentType: String?
    /// Phase 19k: Vendor-managed task with no contractor on file yet.
    /// UI renders these as "Find a contractor for: X" with an orange CTA.
    /// Cleared when the user picks a vendor.
    let needsVendor: Bool?
    /// Phase 51: Links this task to a standing appointment for recurring vendor visits.
    let standingAppointmentId: UUID?
    /// Phase 64: Persisted routing decision — "vendor" | "handyman" | "diy"
    /// | nil. nil means the TaskRoutingPicker should surface (no
    /// preference resolved yet). Complements `assignmentType` by tracking
    /// the user's explicit choice separately from the template default.
    let assignedRoute: String?
    /// Phase 66: Links a task to a Routine (active vendor service, pending-
    /// vendor routine, or the singleton handyman routine). When set on an
    /// `assignmentType = 'vendor'` task, the task hides from the primary
    /// "This Season" list and renders under its parent routine instead.
    /// DIY-default tasks CAN also have parent_routine_id set (to the
    /// handyman routine) — they hide from This Season but surface under
    /// "Next Handyman Visit."
    let parentRoutineId: UUID?
    /// Phase 66: Runtime bundle grouping. When the RoutineGroupingEngine
    /// creates a bundle parent task, each child row gets its
    /// `bundle_parent_task_id` set to the parent's id. Promotes the Phase
    /// 54A template-time `bundleId` pattern to runtime — existing bundles
    /// continue to work via `templateId` matching, new ones use this FK.
    let bundleParentTaskId: UUID?
    /// Phase 68: Canonical service-library identifier used by the new
    /// vendor-orchestration model. `template_id` remains as a legacy
    /// back-reference while `service_key` powers homeowner grouping.
    let serviceKey: String?
    /// Phase 80.2: When true, Chez owns coordination for this task —
    /// finding a vendor (if needed), scheduling, follow-up, and
    /// reporting back. Stamped via `delegate_task` Edge Function.
    let chezOwned: Bool?
    let chezOwnedAt: Date?
    /// Phase 80.2: FK back to the parent `chez_requests` thread that
    /// owns this task. Lets Chez surface task changes (mark complete,
    /// reschedule, link a vendor) directly inside the request.
    let chezRequestId: UUID?

    /// Phase 80.2 helper: defaults nil → false. Use everywhere in the
    /// UI to skip the optional-handling boilerplate.
    var isChezOwned: Bool { chezOwned ?? false }

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
        case isArchived = "is_archived"
        case archivedAt = "archived_at"
        case archivedReason = "archived_reason"
        case assignmentType = "assignment_type"
        case needsVendor = "needs_vendor"
        case standingAppointmentId = "standing_appointment_id"
        case assignedRoute = "assigned_route"
        case parentRoutineId = "parent_routine_id"
        case bundleParentTaskId = "bundle_parent_task_id"
        case serviceKey = "service_key"
        case chezOwned = "chez_owned"
        case chezOwnedAt = "chez_owned_at"
        case chezRequestId = "chez_request_id"
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
            scheduledDate: nil,
            isArchived: nil,
            archivedAt: nil,
            archivedReason: nil,
            assignmentType: nil,
            needsVendor: nil,
            standingAppointmentId: nil,
            assignedRoute: nil,
            parentRoutineId: nil,
            bundleParentTaskId: nil,
            serviceKey: nil,
            chezOwned: nil,
            chezOwnedAt: nil,
            chezRequestId: nil
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
            scheduledDate: nil,
            isArchived: nil,
            archivedAt: nil,
            archivedReason: nil,
            assignmentType: nil,
            needsVendor: nil,
            standingAppointmentId: nil,
            assignedRoute: nil,
            parentRoutineId: nil,
            bundleParentTaskId: nil,
            serviceKey: templateId.flatMap { ServiceLibrary.serviceKey(forLegacyTemplateKey: $0) },
            chezOwned: nil,
            chezOwnedAt: nil,
            chezRequestId: nil
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
    /// Phase 19k: Personal / vendor / either. See MaintenanceTaskDBRow.
    var assignmentType: String?
    /// Phase 19k: True for vendor-managed tasks with no contractor on file.
    var needsVendor: Bool?
    /// Phase 51B: Confirmed visit date. When set, the task moves to the "Scheduled" bucket.
    var scheduledDate: String?
    /// Phase 51: Links to a standing appointment for recurring vendor visits.
    var standingAppointmentId: UUID?
    /// Phase 64: Persisted routing choice — "vendor" | "handyman" | "diy".
    var assignedRoute: String?
    /// Phase 66: Link to parent routine at creation time. Set by
    /// Day1TaskCurator and RoutineGroupingEngine when a task is routed to
    /// a vendor routine / pending-vendor routine / handyman routine.
    var parentRoutineId: UUID?
    /// Phase 66: Link to bundle parent task at creation time. Set by
    /// RoutineGroupingEngine when a child row is created under a bundle
    /// parent. Parent rows leave this nil.
    var bundleParentTaskId: UUID?
    /// Phase 68: Canonical service-library identifier.
    var serviceKey: String?

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
        case assignmentType = "assignment_type"
        case needsVendor = "needs_vendor"
        case standingAppointmentId = "standing_appointment_id"
        case scheduledDate = "scheduled_date"
        case assignedRoute = "assigned_route"
        case parentRoutineId = "parent_routine_id"
        case bundleParentTaskId = "bundle_parent_task_id"
        case serviceKey = "service_key"
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
    var isArchived: Bool?
    var archivedAt: Date?
    var archivedReason: String?
    /// Phase 19k: Allows the bidirectional toggle (Phase 19l UI) to flip a
    /// task between personal and vendor-managed in place. Also lets the
    /// vendor delegation sheet promote multiple tasks at once.
    var assignmentType: String?
    var needsVendor: Bool?
    /// Phase 51: Links to a standing appointment for recurring vendor visits.
    var standingAppointmentId: UUID?
    /// Phase 64: Persisted routing choice — "vendor" | "handyman" | "diy" | nil.
    var assignedRoute: String?
    /// Phase 66: Link / unlink from a routine. Set by the curator when
    /// pulling a task out of the handyman visit ("I'll actually do this
    /// myself"), or by routine activation when matching tasks should be
    /// grouped under a vendor routine.
    var parentRoutineId: UUID?
    /// Phase 66: Link / unlink from a bundle parent row. Runtime bundle
    /// rearrangement uses this to re-parent a task when the user promotes
    /// a bundle member to a standalone task.
    var bundleParentTaskId: UUID?
    /// Phase 68: Canonical service-library identifier.
    var serviceKey: String?

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
        case isArchived = "is_archived"
        case archivedAt = "archived_at"
        case archivedReason = "archived_reason"
        case assignmentType = "assignment_type"
        case needsVendor = "needs_vendor"
        case standingAppointmentId = "standing_appointment_id"
        case assignedRoute = "assigned_route"
        case parentRoutineId = "parent_routine_id"
        case bundleParentTaskId = "bundle_parent_task_id"
        case serviceKey = "service_key"
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

// MARK: - Estate State [REMOVED — Chez v1 estate intelligence cut]
/* Phase 48 EstateStateRow / Insert / Update + supporting types
   (EstateFiduciary, EstateConcernRating, EstateWish,
   EstateAssetsSummary, EstateIntakeState, EstateIntakeAnswer,
   EstateNominations, FiduciaryNomination, NominatedPerson,
   EstateHouseholdSnapshot) and EstatePdfExport* removed for the
   Chez v1 release. The underlying tables were dropped via
   migration 20260901_chez_v1_estate_removal.sql.
*/

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
    let personalMessage: String?
    let reminderSentAt: Date?
    let reminderCount: Int?
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
        case personalMessage = "personal_message"
        case reminderSentAt = "reminder_sent_at"
        case reminderCount = "reminder_count"
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
    var personalMessage: String?

    enum CodingKeys: String, CodingKey {
        case role
        case householdId = "household_id"
        case invitedBy = "invited_by"
        case invitedEmail = "invited_email"
        case inviteCode = "invite_code"
        case familyMemberId = "family_member_id"
        case personalMessage = "personal_message"
    }
}

// MARK: - Household Merge Request

/// Lightweight row representation of a household_merge_requests record. The
/// merge-households edge function owns the full lifecycle (preview, accept,
/// execute); iOS only needs enough fields to display "request sent" trust
/// moments and surface inbound merge requests in the household access view.
struct HouseholdMergeRequestRow: Codable, Identifiable {
    let id: UUID
    let requesterUserId: UUID?
    let requesterHouseholdId: UUID?
    let targetUserId: UUID?
    let targetHouseholdId: UUID?
    let status: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, status
        case requesterUserId = "requester_user_id"
        case requesterHouseholdId = "requester_household_id"
        case targetUserId = "target_user_id"
        case targetHouseholdId = "target_household_id"
        case createdAt = "created_at"
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
    /// Phase 84 — Chez delegation. When true the homeowner has handed
    /// this project to Chez to run end-to-end (vendor sourcing,
    /// negotiation, budget tracking, timeline coordination).
    let chezOwned: Bool?
    let chezOwnedAt: Date?

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
        case chezOwned = "chez_owned"
        case chezOwnedAt = "chez_owned_at"
    }

    /// Resilient decoder so new fields don't break legacy rows.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        propertyId = try c.decode(UUID.self, forKey: .propertyId)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        category = (try? c.decode(String.self, forKey: .category)) ?? ""
        status = (try? c.decode(String.self, forKey: .status)) ?? "planning"
        projectType = (try? c.decode(String.self, forKey: .projectType)) ?? "diy"
        priority = try? c.decodeIfPresent(String.self, forKey: .priority)
        estimatedBudget = try? c.decodeIfPresent(Double.self, forKey: .estimatedBudget)
        actualSpend = try? c.decodeIfPresent(Double.self, forKey: .actualSpend)
        aiEstimatedDiyCost = try? c.decodeIfPresent(Double.self, forKey: .aiEstimatedDiyCost)
        aiEstimatedProCost = try? c.decodeIfPresent(Double.self, forKey: .aiEstimatedProCost)
        targetStartDate = try? c.decodeIfPresent(String.self, forKey: .targetStartDate)
        targetEndDate = try? c.decodeIfPresent(String.self, forKey: .targetEndDate)
        actualStartDate = try? c.decodeIfPresent(String.self, forKey: .actualStartDate)
        actualEndDate = try? c.decodeIfPresent(String.self, forKey: .actualEndDate)
        aiResearch = try? c.decodeIfPresent(ProjectAIResearch.self, forKey: .aiResearch)
        aiResearchUpdatedAt = try? c.decodeIfPresent(Date.self, forKey: .aiResearchUpdatedAt)
        estimatedTotal = try? c.decodeIfPresent(Double.self, forKey: .estimatedTotal)
        notes = try? c.decodeIfPresent(String.self, forKey: .notes)
        parentProjectId = try? c.decodeIfPresent(UUID.self, forKey: .parentProjectId)
        personalPropertyAmount = try? c.decodeIfPresent(Double.self, forKey: .personalPropertyAmount)
        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try? c.decodeIfPresent(Date.self, forKey: .updatedAt)
        createdBy = try? c.decodeIfPresent(UUID.self, forKey: .createdBy)
        activeQuoteId = try? c.decodeIfPresent(UUID.self, forKey: .activeQuoteId)
        entryType = try? c.decodeIfPresent(String.self, forKey: .entryType)
        chezOwned = try? c.decodeIfPresent(Bool.self, forKey: .chezOwned)
        chezOwnedAt = try? c.decodeIfPresent(Date.self, forKey: .chezOwnedAt)
    }

    var isInsuranceClaim: Bool { projectType == "insurance_claim" }
    var isChildProject: Bool { parentProjectId != nil }
    var isHistorical: Bool { (entryType ?? "planned") == "historical" }
    var isChezOwned: Bool { chezOwned ?? false }
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
    /// Phase 18e: Snapshot of the catalog provider record at write time so
    /// the Property → Overview cards can render the brand logo and accent
    /// without a runtime JOIN. Nil for custom-typed providers that aren't in
    /// the catalog.
    let providerId: UUID?
    let logoUrl: String?
    let brandColor: String?
    /// Phase 84 — universal entity-level Chez delegation. When true the
    /// homeowner has handed this utility account to Chez to audit bills,
    /// negotiate rates, and switch providers when better.
    let chezOwned: Bool?
    let chezOwnedAt: Date?

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
        case providerId = "provider_id"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
        case chezOwned = "chez_owned"
        case chezOwnedAt = "chez_owned_at"
    }

    /// Phase 18e: resilient init so older deploys (pre-snapshot columns)
    /// still decode cleanly. The new columns default to nil when missing.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        propertyId = try c.decode(UUID.self, forKey: .propertyId)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        providerType = try c.decode(String.self, forKey: .providerType)
        providerName = try c.decode(String.self, forKey: .providerName)
        providerSlug = try? c.decodeIfPresent(String.self, forKey: .providerSlug)
        accountNumber = try? c.decodeIfPresent(String.self, forKey: .accountNumber)
        phone = try? c.decodeIfPresent(String.self, forKey: .phone)
        website = try? c.decodeIfPresent(String.self, forKey: .website)
        monthlyCost = try? c.decodeIfPresent(Double.self, forKey: .monthlyCost)
        planName = try? c.decodeIfPresent(String.self, forKey: .planName)
        notes = try? c.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        providerId = try? c.decodeIfPresent(UUID.self, forKey: .providerId)
        logoUrl = try? c.decodeIfPresent(String.self, forKey: .logoUrl)
        brandColor = try? c.decodeIfPresent(String.self, forKey: .brandColor)
        chezOwned = try? c.decodeIfPresent(Bool.self, forKey: .chezOwned)
        chezOwnedAt = try? c.decodeIfPresent(Date.self, forKey: .chezOwnedAt)
    }

    /// Phase 84 — convenience getter for delegation status.
    var isChezOwned: Bool { chezOwned ?? false }

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
    /// Phase 18e: snapshot of catalog provider record (logo, brand color, ID).
    var providerId: UUID?
    var logoUrl: String?
    var brandColor: String?

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
        case providerId = "provider_id"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
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
    /// True when the carrier also offers home insurance (Phase 16c). Only set
    /// for `auto_insurance` rows; nil/false everywhere else.
    let bundlesWithHome: Bool?
    /// True when the carrier also offers auto insurance (Phase 16c). Only set
    /// for `home_insurance` rows; nil/false everywhere else.
    let bundlesWithAuto: Bool?
    /// Phase 19h: Service area tags. Mix of state codes ('NY', 'CT'),
    /// county names ('Westchester', 'Fairfield'), and town/city/hamlet
    /// names ('Bedford Hills', 'Greenwich', 'Sherman'). Used by the quiz
    /// picker to rank regional matches above generic ones.
    let regions: [String]?
    /// Phase 50 (advisor picker fix): smaller = more prominent. The Life
    /// tab advisor picker uses 1..10 to surface the biggest national
    /// brands first across estate attorney / CPA / financial advisor /
    /// life insurance categories. Nil for everything else (utilities
    /// don't use prominence ordering — they keep the Phase 19h region
    /// score). Backed by `utility_providers.prominence_rank` from
    /// migration `20260468_utility_provider_prominence.sql`. Resilient
    /// decoding so older rows pre-migration just fall back to the
    /// alphabetical bucket.
    let prominenceRank: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, website, phone, regions
        case providerType = "provider_type"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
        case bundlesWithHome = "bundles_with_home"
        case bundlesWithAuto = "bundles_with_auto"
        case prominenceRank = "prominence_rank"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decode(String.self, forKey: .slug)
        providerType = try c.decode(String.self, forKey: .providerType)
        logoUrl = try? c.decodeIfPresent(String.self, forKey: .logoUrl)
        brandColor = try? c.decodeIfPresent(String.self, forKey: .brandColor)
        website = try? c.decodeIfPresent(String.self, forKey: .website)
        phone = try? c.decodeIfPresent(String.self, forKey: .phone)
        bundlesWithHome = try? c.decodeIfPresent(Bool.self, forKey: .bundlesWithHome)
        bundlesWithAuto = try? c.decodeIfPresent(Bool.self, forKey: .bundlesWithAuto)
        regions = try? c.decodeIfPresent([String].self, forKey: .regions)
        prominenceRank = try? c.decodeIfPresent(Int.self, forKey: .prominenceRank)
    }
}

struct UtilityProviderInsert: Codable {
    let name: String
    let slug: String
    let providerType: String
    var logoUrl: String?
    var brandColor: String?
    var website: String?
    var phone: String?

    enum CodingKeys: String, CodingKey {
        case name, slug, website, phone
        case providerType = "provider_type"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
    }
}

// MARK: - Household Advisors

struct HouseholdAdvisorRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let advisorType: String
    let providerName: String
    let providerSlug: String?
    let providerId: UUID?
    let logoUrl: String?
    let brandColor: String?
    let website: String?
    let phone: String?
    let email: String?
    let contactName: String?
    let companyName: String?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, website, phone, email, notes
        case householdId = "household_id"
        case advisorType = "advisor_type"
        case providerName = "provider_name"
        case providerSlug = "provider_slug"
        case providerId = "provider_id"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
        case contactName = "contact_name"
        case companyName = "company_name"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        advisorType = try c.decode(String.self, forKey: .advisorType)
        providerName = try c.decode(String.self, forKey: .providerName)
        providerSlug = try? c.decodeIfPresent(String.self, forKey: .providerSlug)
        providerId = try? c.decodeIfPresent(UUID.self, forKey: .providerId)
        logoUrl = try? c.decodeIfPresent(String.self, forKey: .logoUrl)
        brandColor = try? c.decodeIfPresent(String.self, forKey: .brandColor)
        website = try? c.decodeIfPresent(String.self, forKey: .website)
        phone = try? c.decodeIfPresent(String.self, forKey: .phone)
        email = try? c.decodeIfPresent(String.self, forKey: .email)
        contactName = try? c.decodeIfPresent(String.self, forKey: .contactName)
        companyName = try? c.decodeIfPresent(String.self, forKey: .companyName)
        notes = try? c.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    var typeIcon: String {
        switch advisorType {
        case "cpa_tax": return "dollarsign.circle.fill"
        case "financial_advisor": return "chart.line.uptrend.xyaxis"
        case "life_insurance": return "heart.text.square.fill"
        default: return "person.fill"
        }
    }

    var typeLabel: String {
        switch advisorType {
        case "cpa_tax": return "CPA / Tax Advisor"
        case "financial_advisor": return "Financial Advisor"
        case "life_insurance": return "Life Insurance"
        default: return "Advisor"
        }
    }

    /// Display name: prefers contact_name if set, otherwise provider_name
    var displayName: String {
        if let contactName, !contactName.isEmpty {
            return contactName
        }
        return providerName
    }

    /// Subtitle: shows firm/company when contact_name is the primary display
    var displaySubtitle: String? {
        if contactName != nil, !contactName!.isEmpty {
            if let companyName, !companyName.isEmpty {
                return companyName
            }
            return providerName
        }
        return companyName
    }
}

struct HouseholdAdvisorInsert: Encodable {
    let householdId: UUID
    let advisorType: String
    let providerName: String
    var providerSlug: String?
    var providerId: UUID?
    var logoUrl: String?
    var brandColor: String?
    var website: String?
    var phone: String?
    var email: String?
    var contactName: String?
    var companyName: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case website, phone, email, notes
        case householdId = "household_id"
        case advisorType = "advisor_type"
        case providerName = "provider_name"
        case providerSlug = "provider_slug"
        case providerId = "provider_id"
        case logoUrl = "logo_url"
        case brandColor = "brand_color"
        case contactName = "contact_name"
        case companyName = "company_name"
    }
}

struct HouseholdAdvisorUpdate: Encodable {
    var providerName: String?
    var phone: String?
    var email: String?
    var website: String?
    var contactName: String?
    var companyName: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case phone, email, website, notes
        case providerName = "provider_name"
        case contactName = "contact_name"
        case companyName = "company_name"
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
    /// Phase 84 — Chez delegation. When true the homeowner has handed this
    /// vehicle to Chez to manage end-to-end (service scheduling, recalls,
    /// registration, insurance).
    let chezOwned: Bool?
    let chezOwnedAt: Date?
    /// Phase 95 (gap #91) — EV-specific signals. `isEv` is the
    /// authoritative flag the maintenance template gates check; the
    /// other two are descriptive. All nullable so legacy ICE-only rows
    /// decode without touching anything.
    let isEv: Bool?
    let batteryCapacityKwh: Double?
    let chargerType: String?
    /// Phase 95 (gap #90) — soft-delete. Non-nil = vehicle has been
    /// sold / traded / totaled. Active garage queries filter these
    /// out; service history reads via direct id keep working.
    let archivedAt: Date?
    let archiveReason: String?
    /// Phase 95 (gap #78) — insurance policy fields. Mirror the
    /// registration_expiry pattern so the insurance card has
    /// dedicated columns instead of being purely document-driven.
    /// Nil = nothing stamped; the card falls back to reading the
    /// linked auto-insurance document's metadata.
    let insuranceExpiry: String?
    let insurancePolicyNum: String?
    let insuranceCarrier: String?

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
        case chezOwned = "chez_owned"
        case chezOwnedAt = "chez_owned_at"
        case isEv = "is_ev"
        case batteryCapacityKwh = "battery_capacity_kwh"
        case chargerType = "charger_type"
        case archivedAt = "archived_at"
        case archiveReason = "archive_reason"
        case insuranceExpiry = "insurance_expiry"
        case insurancePolicyNum = "insurance_policy_num"
        case insuranceCarrier = "insurance_carrier"
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
        chezOwned = try? c.decodeIfPresent(Bool.self, forKey: .chezOwned)
        chezOwnedAt = try? c.decodeIfPresent(Date.self, forKey: .chezOwnedAt)
        isEv = try? c.decodeIfPresent(Bool.self, forKey: .isEv)
        batteryCapacityKwh = try? c.decodeIfPresent(Double.self, forKey: .batteryCapacityKwh)
        chargerType = try? c.decodeIfPresent(String.self, forKey: .chargerType)
        archivedAt = try? c.decodeIfPresent(Date.self, forKey: .archivedAt)
        archiveReason = try? c.decodeIfPresent(String.self, forKey: .archiveReason)
        insuranceExpiry = try? c.decodeIfPresent(String.self, forKey: .insuranceExpiry)
        insurancePolicyNum = try? c.decodeIfPresent(String.self, forKey: .insurancePolicyNum)
        insuranceCarrier = try? c.decodeIfPresent(String.self, forKey: .insuranceCarrier)
    }

    /// Phase 84 — convenience getter for delegation status.
    var isChezOwned: Bool { chezOwned ?? false }

    /// Phase 95 (gap #90) — convenience getter for archived state.
    var isArchived: Bool { archivedAt != nil }

    /// Phase 95 (gap #91) — convenience getter for the EV flag. Treats
    /// nil as false so callers can branch without unwrapping.
    var isElectric: Bool { isEv ?? false }

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
    /// Phase 95 (gap #91) — EV-specific signals.
    var isEv: Bool?
    var batteryCapacityKwh: Double?
    var chargerType: String?

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
        case isEv = "is_ev"
        case batteryCapacityKwh = "battery_capacity_kwh"
        case chargerType = "charger_type"
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
    /// Phase 95 (gap #91) — EV-specific signals.
    var isEv: Bool?
    var batteryCapacityKwh: Double?
    var chargerType: String?
    /// Phase 95 (gap #78) — insurance policy fields. Set via the
    /// new EditInsuranceSheet on VehicleDetailView's insurance card.
    var insuranceExpiry: String?
    var insurancePolicyNum: String?
    var insuranceCarrier: String?

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
        case isEv = "is_ev"
        case batteryCapacityKwh = "battery_capacity_kwh"
        case chargerType = "charger_type"
        case insuranceExpiry = "insurance_expiry"
        case insurancePolicyNum = "insurance_policy_num"
        case insuranceCarrier = "insurance_carrier"
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
    /// Phase 95 (gap #86) — intermediate "scheduled with dealer"
    /// timestamp. Non-nil + isResolved=false means the homeowner
    /// has booked the appointment but the work isn't complete yet.
    /// UI surfaces a "Scheduled" pill in this state. Persists past
    /// resolution as audit history.
    let scheduledWithDealerAt: Date?
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
        case scheduledWithDealerAt = "scheduled_with_dealer_at"
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

// MARK: - App Config (force-update gate)

/// Mirrors the `app_config` table. One row per platform (today only `ios`).
/// Read on every launch via `DatabaseService.fetchAppConfig()`.
struct AppConfigRow: Codable {
    let id: String
    let minimumRequiredVersion: String
    let minimumRequiredBuild: Int
    let latestVersion: String
    let latestBuild: Int
    let forceUpdateMessage: String?
    let optionalUpdateMessage: String?
    let appStoreURL: String
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case minimumRequiredVersion = "minimum_required_version"
        case minimumRequiredBuild = "minimum_required_build"
        case latestVersion = "latest_version"
        case latestBuild = "latest_build"
        case forceUpdateMessage = "force_update_message"
        case optionalUpdateMessage = "optional_update_message"
        case appStoreURL = "app_store_url"
        case updatedAt = "updated_at"
    }
}

// MARK: - Local Vendor Results (Phase 19n)

/// One cached Google Places business listing for the find-local-vendors flow.
/// The iOS client never reads this table directly — the edge function checks
/// the cache, refreshes via Google Places when stale, and returns the results
/// shaped as `LocalVendorResult` (see SupabaseClient.swift) — but the row
/// type is here so future tooling (catalog cleanup, ops dashboard, etc.)
/// can decode rows from the table without redefining the schema.
struct LocalVendorResultRow: Codable, Identifiable {
    let id: UUID
    let town: String
    let state: String
    let category: String
    let vendorName: String
    let googlePlaceId: String
    let address: String?
    let phone: String?
    let website: String?
    let rating: Double?
    let reviewCount: Int?
    let isTopRated: Bool?
    let rankPosition: Int?
    let fetchedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, town, state, category, address, phone, website, rating
        case vendorName = "vendor_name"
        case googlePlaceId = "google_place_id"
        case reviewCount = "review_count"
        case isTopRated = "is_top_rated"
        case rankPosition = "rank_position"
        case fetchedAt = "fetched_at"
    }
}

struct LocalVendorResultInsert: Codable {
    let town: String
    let state: String
    let category: String
    let vendorName: String
    let googlePlaceId: String
    var address: String?
    var phone: String?
    var website: String?
    var rating: Double?
    var reviewCount: Int?
    var isTopRated: Bool?
    var rankPosition: Int?

    enum CodingKeys: String, CodingKey {
        case town, state, category, address, phone, website, rating
        case vendorName = "vendor_name"
        case googlePlaceId = "google_place_id"
        case reviewCount = "review_count"
        case isTopRated = "is_top_rated"
        case rankPosition = "rank_position"
    }
}

// MARK: - Standing Appointments (Phase 51)

struct StandingAppointmentRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let propertyId: UUID?
    let vendorId: UUID?
    let systemId: UUID

    let cadenceType: String
    let cadenceIntervalDays: Int?

    let startDate: String
    let nextExpectedDate: String
    let lastConfirmedDate: String?
    let lastAssumedDate: String?

    let isPaused: Bool
    let pausedAt: Date?
    let pauseReason: String?
    let autoResumeDate: String?

    let cadenceSource: String
    let confidenceScore: Double?

    let serviceDescription: String?
    let notes: String?
    let archivedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, notes
        case householdId = "household_id"
        case propertyId = "property_id"
        case vendorId = "vendor_id"
        case systemId = "system_id"
        case cadenceType = "cadence_type"
        case cadenceIntervalDays = "cadence_interval_days"
        case startDate = "start_date"
        case nextExpectedDate = "next_expected_date"
        case lastConfirmedDate = "last_confirmed_date"
        case lastAssumedDate = "last_assumed_date"
        case isPaused = "is_paused"
        case pausedAt = "paused_at"
        case pauseReason = "pause_reason"
        case autoResumeDate = "auto_resume_date"
        case cadenceSource = "cadence_source"
        case confidenceScore = "confidence_score"
        case serviceDescription = "service_description"
        case archivedAt = "archived_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Effective interval in days for any cadence type.
    var effectiveIntervalDays: Int {
        if let cadenceIntervalDays { return cadenceIntervalDays }
        switch cadenceType {
        case "weekly": return 7
        case "biweekly": return 14
        case "triweekly": return 21
        case "monthly": return 30
        case "bimonthly": return 60
        case "quarterly": return 91
        case "semiannual": return 182
        case "annual": return 365
        default: return 30
        }
    }

    /// Human-readable cadence label.
    var cadenceLabel: String {
        switch cadenceType {
        case "weekly": return "Weekly"
        case "biweekly": return "Every 2 weeks"
        case "triweekly": return "Every 3 weeks"
        case "monthly": return "Monthly"
        case "bimonthly": return "Every 2 months"
        case "quarterly": return "Quarterly"
        case "semiannual": return "Twice a year"
        case "annual": return "Annually"
        case "custom_days":
            if let days = cadenceIntervalDays {
                if days % 7 == 0 { return "Every \(days / 7) weeks" }
                return "Every \(days) days"
            }
            return "Custom"
        default: return cadenceType.capitalized
        }
    }
}

struct StandingAppointmentInsert: Codable {
    let householdId: UUID
    var propertyId: UUID?
    var vendorId: UUID?
    let systemId: UUID
    let cadenceType: String
    var cadenceIntervalDays: Int?
    let startDate: String
    let nextExpectedDate: String
    var lastConfirmedDate: String?
    var isPaused: Bool = false
    let cadenceSource: String
    var confidenceScore: Double?
    var serviceDescription: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case householdId = "household_id"
        case propertyId = "property_id"
        case vendorId = "vendor_id"
        case systemId = "system_id"
        case cadenceType = "cadence_type"
        case cadenceIntervalDays = "cadence_interval_days"
        case startDate = "start_date"
        case nextExpectedDate = "next_expected_date"
        case lastConfirmedDate = "last_confirmed_date"
        case isPaused = "is_paused"
        case cadenceSource = "cadence_source"
        case confidenceScore = "confidence_score"
        case serviceDescription = "service_description"
    }
}

struct StandingAppointmentUpdate: Codable {
    var cadenceType: String?
    var cadenceIntervalDays: Int?
    var nextExpectedDate: String?
    var lastConfirmedDate: String?
    var lastAssumedDate: String?
    var isPaused: Bool?
    var pausedAt: Date?
    var pauseReason: String?
    var autoResumeDate: String?
    var cadenceSource: String?
    var confidenceScore: Double?
    var serviceDescription: String?
    var notes: String?
    var archivedAt: Date?

    enum CodingKeys: String, CodingKey {
        case notes
        case cadenceType = "cadence_type"
        case cadenceIntervalDays = "cadence_interval_days"
        case nextExpectedDate = "next_expected_date"
        case lastConfirmedDate = "last_confirmed_date"
        case lastAssumedDate = "last_assumed_date"
        case isPaused = "is_paused"
        case pausedAt = "paused_at"
        case pauseReason = "pause_reason"
        case autoResumeDate = "auto_resume_date"
        case cadenceSource = "cadence_source"
        case confidenceScore = "confidence_score"
        case serviceDescription = "service_description"
        case archivedAt = "archived_at"
    }
}

// MARK: - Standing Appointment Visits (Phase 51)

struct StandingAppointmentVisitRow: Codable, Identifiable {
    let id: UUID
    let standingAppointmentId: UUID
    let scheduledDate: String
    let status: String
    let confirmedAt: Date?
    let confirmedBy: String?
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case standingAppointmentId = "standing_appointment_id"
        case scheduledDate = "scheduled_date"
        case confirmedAt = "confirmed_at"
        case confirmedBy = "confirmed_by"
        case createdAt = "created_at"
    }
}

struct StandingAppointmentVisitInsert: Codable {
    let standingAppointmentId: UUID
    let scheduledDate: String
    let status: String
    var confirmedAt: Date?
    var confirmedBy: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case status, notes
        case standingAppointmentId = "standing_appointment_id"
        case scheduledDate = "scheduled_date"
        case confirmedAt = "confirmed_at"
        case confirmedBy = "confirmed_by"
    }
}

struct StandingAppointmentVisitUpdate: Codable {
    var status: String?
    var confirmedAt: Date?
    var confirmedBy: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case status, notes
        case confirmedAt = "confirmed_at"
        case confirmedBy = "confirmed_by"
    }
}

// MARK: - Category Cadence Defaults (Phase 51)

struct CategoryCadenceDefaultRow: Codable, Identifiable {
    var id: String { categoryKey }
    let categoryKey: String
    let defaultCadenceType: String
    let defaultIntervalDays: Int?
    let seasonalPauseMonths: [Int]?
    let serviceDescriptionTemplate: String?

    enum CodingKeys: String, CodingKey {
        case categoryKey = "category_key"
        case defaultCadenceType = "default_cadence_type"
        case defaultIntervalDays = "default_interval_days"
        case seasonalPauseMonths = "seasonal_pause_months"
        case serviceDescriptionTemplate = "service_description_template"
    }
}

// MARK: - Phase 84.5 — Home Assessment (Free Handyman Assessment + 3-Mode Onboarding)

/// One of the three modes a homeowner can pick at signup.
/// Stored as `properties.attributes["assessment_mode"]` (a JSONB string key).
enum AssessmentMode: String, Codable, CaseIterable {
    case diy
    case blended
    case handyman
}

/// Lifecycle of a `home_assessments` row.
enum HomeAssessmentStatus: String, Codable {
    case pending
    case scheduled
    case enRoute = "en_route"
    case inProgress = "in_progress"
    case submitted
    case awaitingReview = "awaiting_review"
    case correctionsRequested = "corrections_requested"
    /// G3 — added round 2: rolled back ingestion needs admin manual replay.
    case ingestionFailed = "ingestion_failed"
    case completed
    case cancelled

    /// True when the homeowner should still see the pending dashboard
    /// card. False once the assessment is closed (completed / cancelled).
    var isActive: Bool {
        switch self {
        case .completed, .cancelled: return false
        default: return true
        }
    }

    /// True when the homeowner should be prompted to review captured data.
    var needsReview: Bool { self == .awaitingReview }
}

/// A single captured-system entry inside `home_assessments.captured_systems`.
struct HomeAssessmentSystemEntry: Codable, Hashable {
    let category: String
    let manufacturer: String?
    let model: String?
    let installYear: Int?
    let subtype: String?
    let photos: [String]?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case category, manufacturer, model, subtype, photos, notes
        case installYear = "install_year"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? ""
        manufacturer = try? c.decodeIfPresent(String.self, forKey: .manufacturer)
        model = try? c.decodeIfPresent(String.self, forKey: .model)
        installYear = try? c.decodeIfPresent(Int.self, forKey: .installYear)
        subtype = try? c.decodeIfPresent(String.self, forKey: .subtype)
        photos = try? c.decodeIfPresent([String].self, forKey: .photos)
        notes = try? c.decodeIfPresent(String.self, forKey: .notes)
    }

    init(category: String, manufacturer: String? = nil, model: String? = nil,
         installYear: Int? = nil, subtype: String? = nil, photos: [String]? = nil,
         notes: String? = nil) {
        self.category = category
        self.manufacturer = manufacturer
        self.model = model
        self.installYear = installYear
        self.subtype = subtype
        self.photos = photos
        self.notes = notes
    }
}

/// A single captured-contractor entry inside `home_assessments.captured_contractors`.
struct HomeAssessmentContractorEntry: Codable, Hashable {
    let companyName: String
    let category: String?
    let phone: String?
    let email: String?
    let source: String?

    enum CodingKeys: String, CodingKey {
        case category, phone, email, source
        case companyName = "company_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        companyName = (try? c.decodeIfPresent(String.self, forKey: .companyName)) ?? ""
        category = try? c.decodeIfPresent(String.self, forKey: .category)
        phone = try? c.decodeIfPresent(String.self, forKey: .phone)
        email = try? c.decodeIfPresent(String.self, forKey: .email)
        source = try? c.decodeIfPresent(String.self, forKey: .source)
    }

    init(companyName: String, category: String? = nil, phone: String? = nil,
         email: String? = nil, source: String? = "homeowner_uses") {
        self.companyName = companyName
        self.category = category
        self.phone = phone
        self.email = email
        self.source = source
    }
}

/// A single captured-routine entry inside `home_assessments.captured_routines`.
struct HomeAssessmentRoutineEntry: Codable, Hashable {
    let kind: String
    let label: String?
    let vendorName: String?
    let cadence: String?
    let dayOfWeek: Int?
    let activeMonths: [Int]?

    enum CodingKeys: String, CodingKey {
        case kind, label, cadence
        case vendorName = "vendor_name"
        case dayOfWeek = "day_of_week"
        case activeMonths = "active_months"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = (try? c.decodeIfPresent(String.self, forKey: .kind)) ?? ""
        label = try? c.decodeIfPresent(String.self, forKey: .label)
        vendorName = try? c.decodeIfPresent(String.self, forKey: .vendorName)
        cadence = try? c.decodeIfPresent(String.self, forKey: .cadence)
        dayOfWeek = try? c.decodeIfPresent(Int.self, forKey: .dayOfWeek)
        activeMonths = try? c.decodeIfPresent([Int].self, forKey: .activeMonths)
    }

    init(kind: String, label: String? = nil, vendorName: String? = nil,
         cadence: String? = nil, dayOfWeek: Int? = nil, activeMonths: [Int]? = nil) {
        self.kind = kind
        self.label = label
        self.vendorName = vendorName
        self.cadence = cadence
        self.dayOfWeek = dayOfWeek
        self.activeMonths = activeMonths
    }
}

/// One row of `public.home_assessments`. Externally-fed → resilient decoder.
struct HomeAssessmentRow: Codable, Identifiable {
    let id: UUID
    let propertyId: UUID
    let householdId: UUID
    let visitAssignmentId: UUID?
    let handymanMemberId: UUID?

    let status: HomeAssessmentStatus

    /// Phase 84.5 G16/G32 — multi-session and existing-user supplement metadata.
    let assessmentRound: Int
    let sessionCount: Int
    let isExistingUserSupplement: Bool

    /// Phase 84.5 G24/G31/G34 — pre-visit homeowner-supplied context.
    let homeownerPresent: Bool
    let homeownerAccessNotes: String?
    let homeownerConcerns: String?
    let homeownerWrapupNotes: String?

    let capturedQuizState: [String: FlexibleValue]?
    let capturedSystems: [HomeAssessmentSystemEntry]?
    let capturedContractors: [HomeAssessmentContractorEntry]?
    let capturedRoutines: [HomeAssessmentRoutineEntry]?
    let capturedDocumentPaths: [String]?
    let capturedAttributes: [String: FlexibleValue]?

    let preVisitNotes: String?
    let preVisitPhotos: [String]?

    let scheduledAt: Date?
    let enRouteAt: Date?
    let startedAt: Date?
    let submittedAt: Date?
    let ingestedAt: Date?
    let reviewedAt: Date?
    let completedAt: Date?
    let cancelledAt: Date?
    let cancellationReason: String?

    let rescheduleRequestedAt: Date?
    let rescheduleRequestNotes: String?

    let handymanNotes: String?
    let adminNotes: String?

    let isFree: Bool
    let chargeableCostCents: Int?
    let paymentStatus: String?

    /// Phase 84.5 — server-rendered PDF export of the captured assessment,
    /// plus error message when ingestion fails.
    let pdfExportPath: String?
    let ingestionError: String?

    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, status
        case propertyId = "property_id"
        case householdId = "household_id"
        case visitAssignmentId = "visit_assignment_id"
        case handymanMemberId = "handyman_member_id"
        case assessmentRound = "assessment_round"
        case sessionCount = "session_count"
        case isExistingUserSupplement = "is_existing_user_supplement"
        case homeownerPresent = "homeowner_present"
        case homeownerAccessNotes = "homeowner_access_notes"
        case homeownerConcerns = "homeowner_concerns"
        case homeownerWrapupNotes = "homeowner_wrapup_notes"
        case capturedQuizState = "captured_quiz_state"
        case capturedSystems = "captured_systems"
        case capturedContractors = "captured_contractors"
        case capturedRoutines = "captured_routines"
        case capturedDocumentPaths = "captured_document_paths"
        case capturedAttributes = "captured_attributes"
        case preVisitNotes = "pre_visit_notes"
        case preVisitPhotos = "pre_visit_photos"
        case scheduledAt = "scheduled_at"
        case enRouteAt = "en_route_at"
        case startedAt = "started_at"
        case submittedAt = "submitted_at"
        case ingestedAt = "ingested_at"
        case reviewedAt = "reviewed_at"
        case completedAt = "completed_at"
        case cancelledAt = "cancelled_at"
        case cancellationReason = "cancellation_reason"
        case rescheduleRequestedAt = "reschedule_requested_at"
        case rescheduleRequestNotes = "reschedule_request_notes"
        case handymanNotes = "handyman_notes"
        case adminNotes = "admin_notes"
        case isFree = "is_free"
        case chargeableCostCents = "chargeable_cost_cents"
        case paymentStatus = "payment_status"
        case pdfExportPath = "pdf_export_path"
        case ingestionError = "ingestion_error"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        propertyId = try c.decode(UUID.self, forKey: .propertyId)
        householdId = try c.decode(UUID.self, forKey: .householdId)
        visitAssignmentId = try? c.decodeIfPresent(UUID.self, forKey: .visitAssignmentId)
        handymanMemberId = try? c.decodeIfPresent(UUID.self, forKey: .handymanMemberId)

        // Status falls back to .pending if decode fails (e.g. server adds a
        // new status value before the iOS app catches up).
        let rawStatus = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "pending"
        status = HomeAssessmentStatus(rawValue: rawStatus) ?? .pending

        assessmentRound = (try? c.decodeIfPresent(Int.self, forKey: .assessmentRound)) ?? 1
        sessionCount = (try? c.decodeIfPresent(Int.self, forKey: .sessionCount)) ?? 1
        isExistingUserSupplement = (try? c.decodeIfPresent(Bool.self, forKey: .isExistingUserSupplement)) ?? false

        homeownerPresent = (try? c.decodeIfPresent(Bool.self, forKey: .homeownerPresent)) ?? true
        homeownerAccessNotes = try? c.decodeIfPresent(String.self, forKey: .homeownerAccessNotes)
        homeownerConcerns = try? c.decodeIfPresent(String.self, forKey: .homeownerConcerns)
        homeownerWrapupNotes = try? c.decodeIfPresent(String.self, forKey: .homeownerWrapupNotes)

        capturedQuizState = try? c.decodeIfPresent([String: FlexibleValue].self, forKey: .capturedQuizState)
        capturedSystems = try? c.decodeIfPresent([HomeAssessmentSystemEntry].self, forKey: .capturedSystems)
        capturedContractors = try? c.decodeIfPresent([HomeAssessmentContractorEntry].self, forKey: .capturedContractors)
        capturedRoutines = try? c.decodeIfPresent([HomeAssessmentRoutineEntry].self, forKey: .capturedRoutines)
        capturedDocumentPaths = try? c.decodeIfPresent([String].self, forKey: .capturedDocumentPaths)
        capturedAttributes = try? c.decodeIfPresent([String: FlexibleValue].self, forKey: .capturedAttributes)

        preVisitNotes = try? c.decodeIfPresent(String.self, forKey: .preVisitNotes)
        preVisitPhotos = try? c.decodeIfPresent([String].self, forKey: .preVisitPhotos)

        scheduledAt = try? c.decodeIfPresent(Date.self, forKey: .scheduledAt)
        enRouteAt = try? c.decodeIfPresent(Date.self, forKey: .enRouteAt)
        startedAt = try? c.decodeIfPresent(Date.self, forKey: .startedAt)
        submittedAt = try? c.decodeIfPresent(Date.self, forKey: .submittedAt)
        ingestedAt = try? c.decodeIfPresent(Date.self, forKey: .ingestedAt)
        reviewedAt = try? c.decodeIfPresent(Date.self, forKey: .reviewedAt)
        completedAt = try? c.decodeIfPresent(Date.self, forKey: .completedAt)
        cancelledAt = try? c.decodeIfPresent(Date.self, forKey: .cancelledAt)
        cancellationReason = try? c.decodeIfPresent(String.self, forKey: .cancellationReason)

        rescheduleRequestedAt = try? c.decodeIfPresent(Date.self, forKey: .rescheduleRequestedAt)
        rescheduleRequestNotes = try? c.decodeIfPresent(String.self, forKey: .rescheduleRequestNotes)

        handymanNotes = try? c.decodeIfPresent(String.self, forKey: .handymanNotes)
        adminNotes = try? c.decodeIfPresent(String.self, forKey: .adminNotes)

        isFree = (try? c.decodeIfPresent(Bool.self, forKey: .isFree)) ?? true
        chargeableCostCents = try? c.decodeIfPresent(Int.self, forKey: .chargeableCostCents)
        paymentStatus = try? c.decodeIfPresent(String.self, forKey: .paymentStatus)

        pdfExportPath = try? c.decodeIfPresent(String.self, forKey: .pdfExportPath)
        ingestionError = try? c.decodeIfPresent(String.self, forKey: .ingestionError)

        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try? c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    /// Pre-visit display: is the visit still pending (no submission yet)?
    var isPendingVisit: Bool {
        switch status {
        case .pending, .scheduled, .enRoute:
            return true
        default:
            return false
        }
    }

    /// Post-visit display: has the homeowner not yet reviewed the captured data?
    var isAwaitingReview: Bool {
        status == .awaitingReview || status == .submitted
    }

    /// Visit is fully closed.
    var isClosed: Bool {
        status == .completed || status == .cancelled
    }
}

extension HomeAssessmentRow: Equatable, Hashable {
    static func == (lhs: HomeAssessmentRow, rhs: HomeAssessmentRow) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.updatedAt == rhs.updatedAt
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Item in a homeowner's "request_assessment_corrections" payload —
/// flagging something the handyman missed or got wrong.
struct AssessmentCorrectionItem: Codable, Hashable {
    let section: String   // "system" | "contractor" | "routine" | "document" | "attribute"
    let entityId: String?
    let note: String

    enum CodingKeys: String, CodingKey {
        case section, note
        case entityId = "entity_id"
    }
}

// MARK: - Phase 95 (gap #47) — Service vendor inquiries

/// Outbound inquiry from the homeowner to a service-vendor contractor
/// (HVAC, plumber, electrician, roofer, septic, well, chimney, tree).
/// Persisted alongside the SendGrid email send so the contractor
/// detail view can show outreach history without poking the email
/// pipeline directly.
struct ServiceVendorInquiryRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let contractorId: UUID
    let senderUserId: UUID
    let subject: String
    let body: String
    let deliveryStatus: String
    let deliveryError: String?
    let sentAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, subject, body
        case householdId = "household_id"
        case contractorId = "contractor_id"
        case senderUserId = "sender_user_id"
        case deliveryStatus = "delivery_status"
        case deliveryError = "delivery_error"
        case sentAt = "sent_at"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        householdId = (try? c.decode(UUID.self, forKey: .householdId)) ?? UUID()
        contractorId = (try? c.decode(UUID.self, forKey: .contractorId)) ?? UUID()
        senderUserId = (try? c.decode(UUID.self, forKey: .senderUserId)) ?? UUID()
        subject = (try? c.decodeIfPresent(String.self, forKey: .subject)) ?? ""
        body = (try? c.decodeIfPresent(String.self, forKey: .body)) ?? ""
        deliveryStatus = (try? c.decodeIfPresent(String.self, forKey: .deliveryStatus)) ?? "pending"
        deliveryError = try? c.decodeIfPresent(String.self, forKey: .deliveryError)
        sentAt = try? c.decodeIfPresent(Date.self, forKey: .sentAt)
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
    }
}

struct ServiceVendorInquiryInsert: Codable {
    let householdId: UUID
    let contractorId: UUID
    let senderUserId: UUID
    let subject: String
    let body: String
    var deliveryStatus: String = "pending"

    enum CodingKeys: String, CodingKey {
        case subject, body
        case householdId = "household_id"
        case contractorId = "contractor_id"
        case senderUserId = "sender_user_id"
        case deliveryStatus = "delivery_status"
    }
}
