import Foundation
import Supabase

/// Typed CRUD operations for all Haven database tables.
/// All methods use the Supabase PostgREST client with automatic RLS enforcement.
final class DatabaseService {
    static let shared = DatabaseService()

    private init() {}

    private func from(_ table: String) -> PostgrestQueryBuilder {
        HavenSupabase.from(table)
    }

    // MARK: - Households

    func fetchHousehold(id: UUID) async throws -> HouseholdRow {
        try await from("households")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func createHousehold(_ household: HouseholdInsert) async throws -> HouseholdRow {
        try await from("households")
            .insert(household)
            .select()
            .single()
            .execute()
            .value
    }

    /// Insert a household with a known ID (for onboarding).
    /// Avoids the `.select()` call which fails because the user's household_id
    /// hasn't been set yet (RLS SELECT policy can't match).
    func insertHousehold(id: UUID, name: String, subscriptionTier: String = "standard") async throws {
        struct HouseholdInsertWithId: Codable {
            let id: UUID
            let name: String
            let subscriptionTier: String

            enum CodingKeys: String, CodingKey {
                case id, name
                case subscriptionTier = "subscription_tier"
            }
        }

        try await from("households")
            .insert(HouseholdInsertWithId(id: id, name: name, subscriptionTier: subscriptionTier))
            .execute()
    }

    func updateHousehold(id: UUID, _ updates: HouseholdUpdate) async throws -> HouseholdRow {
        try await from("households")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Users

    func fetchCurrentUser() async throws -> UserRow {
        let userId = try await HavenSupabase.auth.session.user.id
        return try await from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func createUser(_ user: UserInsert) async throws -> UserRow {
        try await from("users")
            .insert(user)
            .select()
            .single()
            .execute()
            .value
    }

    func updateUser(id: UUID, _ updates: UserUpdate) async throws -> UserRow {
        try await from("users")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    /// Insert a user row without returning the result (avoids RLS SELECT issues).
    func createUserWithoutReturn(_ user: UserInsert) async throws {
        try await from("users")
            .insert(user)
            .execute()
    }

    // MARK: - Family Members

    func fetchFamilyMembers() async throws -> [FamilyMemberRow] {
        try await from("family_members")
            .select()
            .order("first_name")
            .execute()
            .value
    }

    func createFamilyMember(_ member: FamilyMemberInsert) async throws -> FamilyMemberRow {
        try await from("family_members")
            .insert(member)
            .select()
            .single()
            .execute()
            .value
    }

    func updateFamilyMember(id: UUID, _ updates: FamilyMemberUpdate) async throws -> FamilyMemberRow {
        try await from("family_members")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteFamilyMember(id: UUID) async throws {
        try await from("family_members")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Check if a family member has a linked Haven user account
    func isFamilyMemberLinked(id: UUID) async -> Bool {
        let members: [FamilyMemberRow]? = try? await from("family_members")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        return members?.first?.linkedUserId != nil
    }

    /// Fetch all users in the current user's household
    func fetchHouseholdUsers() async throws -> [UserRow] {
        let currentUser = try await fetchCurrentUser()
        guard let householdId = currentUser.householdId else { return [currentUser] }
        return try await from("users")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .execute()
            .value
    }

    // MARK: - Documents

    func fetchDocuments(category: String? = nil, status: String? = nil) async throws -> [DocumentRow] {
        var query = from("documents").select().is("deleted_at", value: nil)
        if let category { query = query.eq("category", value: category) }
        if let status { query = query.eq("status", value: status) }
        return try await query.order("uploaded_at", ascending: false).execute().value
    }

    func fetchDocument(id: UUID) async throws -> DocumentRow {
        try await from("documents")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func createDocument(_ doc: DocumentInsert) async throws -> DocumentRow {
        try await from("documents")
            .insert(doc)
            .select()
            .single()
            .execute()
            .value
    }

    func updateDocument(id: UUID, _ updates: DocumentUpdate) async throws -> DocumentRow {
        try await from("documents")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteDocument(id: UUID) async throws {
        try await from("documents")
            .update(["deleted_at": Date().ISO8601Format()])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func permanentlyDeleteDocument(id: UUID) async throws {
        try await from("documents")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchDeletedDocuments() async throws -> [DocumentRow] {
        try await from("documents")
            .select()
            .not("deleted_at", operator: .is, value: "null")
            .order("deleted_at", ascending: false)
            .execute()
            .value
    }

    func restoreDocument(id: UUID) async throws {
        try await from("documents")
            .update(["deleted_at": AnyJSON.null])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchDocumentsByCategory(category: String) async throws -> [DocumentRow] {
        try await from("documents")
            .select()
            .eq("category", value: category)
            .is("deleted_at", value: nil)
            .order("uploaded_at", ascending: false)
            .execute()
            .value
    }

    func fetchDocumentsByContentHash(hash: String) async throws -> [DocumentRow] {
        try await from("documents")
            .select()
            .eq("content_hash", value: hash)
            .is("deleted_at", value: nil)
            .execute()
            .value
    }

    // MARK: - Document Family Members

    func fetchAllDocumentFamilyMemberLinks() async throws -> [DocumentFamilyMemberRow] {
        try await from("document_family_members")
            .select()
            .execute()
            .value
    }

    func fetchDocumentFamilyMembers(documentId: UUID) async throws -> [DocumentFamilyMemberRow] {
        try await from("document_family_members")
            .select()
            .eq("document_id", value: documentId.uuidString)
            .execute()
            .value
    }

    func linkDocumentToFamilyMember(documentId: UUID, familyMemberId: UUID) async throws {
        let insert = DocumentFamilyMemberInsert(documentId: documentId, familyMemberId: familyMemberId)
        try await from("document_family_members")
            .upsert(insert, onConflict: "document_id,family_member_id")
            .execute()
    }

    func unlinkDocumentFromFamilyMember(documentId: UUID, familyMemberId: UUID) async throws {
        try await from("document_family_members")
            .delete()
            .eq("document_id", value: documentId.uuidString)
            .eq("family_member_id", value: familyMemberId.uuidString)
            .execute()
    }

    func fetchFamilyMembersForDocument(documentId: UUID) async throws -> [FamilyMemberRow] {
        let junctions: [DocumentFamilyMemberRow] = try await from("document_family_members")
            .select()
            .eq("document_id", value: documentId.uuidString)
            .execute()
            .value
        guard !junctions.isEmpty else { return [] }
        let ids = junctions.map { $0.familyMemberId.uuidString }
        return try await from("family_members")
            .select()
            .in("id", values: ids)
            .execute()
            .value
    }

    // MARK: - Storage Upload

    func uploadDocumentFile(householdId: UUID, fileName: String, data: Data, contentType: String) async throws -> String {
        let path = "\(householdId.uuidString.lowercased())/\(UUID().uuidString.lowercased())/\(fileName)"
        try await HavenSupabase.storage
            .from("documents")
            .upload(path, data: data, options: .init(contentType: contentType))
        return path
    }

    func getDocumentSignedURL(path: String) async throws -> URL {
        try await HavenSupabase.storage
            .from("documents")
            .createSignedURL(path: path, expiresIn: 3600)
    }

    // MARK: - Document Parties

    func fetchDocumentParties(documentId: UUID) async throws -> [DocumentPartyRow] {
        try await from("document_parties")
            .select()
            .eq("document_id", value: documentId.uuidString)
            .execute()
            .value
    }

    func insertDocumentParties(_ parties: [DocumentPartyInsert]) async throws {
        guard !parties.isEmpty else { return }
        try await from("document_parties")
            .insert(parties)
            .execute()
    }

    func updateDocumentParty(id: UUID, _ update: DocumentPartyUpdate) async throws {
        try await from("document_parties")
            .update(update)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchAllDocumentContent() async throws -> [DocumentContentRow] {
        try await from("document_content")
            .select()
            .execute()
            .value
    }

    func fetchAllDocumentParties() async throws -> [DocumentPartyRow] {
        try await from("document_parties")
            .select()
            .execute()
            .value
    }

    func deleteDocumentPartiesByDocument(documentId: UUID) async throws {
        try await from("document_parties")
            .delete()
            .eq("document_id", value: documentId.uuidString)
            .execute()
    }

    // MARK: - Trusted Contacts

    func fetchTrustedContacts() async throws -> [TrustedContactRow] {
        try await from("trusted_contacts")
            .select()
            .order("name")
            .execute()
            .value
    }

    func createTrustedContact(_ insert: TrustedContactInsert) async throws -> TrustedContactRow {
        try await from("trusted_contacts")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    func updateTrustedContact(id: UUID, _ update: TrustedContactUpdate) async throws -> TrustedContactRow {
        try await from("trusted_contacts")
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteTrustedContact(id: UUID) async throws {
        try await from("trusted_contacts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchDocumentsForTrustedContact(contactId: UUID) async throws -> [DocumentRow] {
        let junctions: [TrustedContactDocumentRow] = try await from("trusted_contact_documents")
            .select()
            .eq("trusted_contact_id", value: contactId.uuidString)
            .execute()
            .value
        guard !junctions.isEmpty else { return [] }
        let ids = junctions.map { $0.documentId.uuidString }
        return try await from("documents")
            .select()
            .in("id", values: ids)
            .is("deleted_at", value: nil)
            .execute()
            .value
    }

    func grantDocumentAccess(contactId: UUID, documentId: UUID) async throws {
        let insert = TrustedContactDocumentInsert(trustedContactId: contactId, documentId: documentId)
        try await from("trusted_contact_documents")
            .insert(insert)
            .execute()
    }

    func revokeDocumentAccess(contactId: UUID, documentId: UUID) async throws {
        try await from("trusted_contact_documents")
            .delete()
            .eq("trusted_contact_id", value: contactId.uuidString)
            .eq("document_id", value: documentId.uuidString)
            .execute()
    }

    func fetchTrustedContactsForDocument(documentId: UUID) async throws -> [TrustedContactRow] {
        let junctions: [TrustedContactDocumentRow] = try await from("trusted_contact_documents")
            .select()
            .eq("document_id", value: documentId.uuidString)
            .execute()
            .value
        guard !junctions.isEmpty else { return [] }
        let ids = junctions.map { $0.trustedContactId.uuidString }
        return try await from("trusted_contacts")
            .select()
            .in("id", values: ids)
            .execute()
            .value
    }

    // MARK: - Properties

    func fetchProperties() async throws -> [PropertyRow] {
        try await from("properties")
            .select()
            .order("name")
            .execute()
            .value
    }

    func fetchProperty(id: UUID) async throws -> PropertyRow {
        try await from("properties")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func createProperty(_ property: PropertyInsert) async throws -> PropertyRow {
        try await from("properties")
            .insert(property)
            .select()
            .single()
            .execute()
            .value
    }

    func updateProperty(id: UUID, _ updates: PropertyUpdate) async throws -> PropertyRow {
        try await from("properties")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteProperty(id: UUID) async throws {
        try await from("properties")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Home Systems

    func fetchHomeSystems(propertyId: UUID) async throws -> [HomeSystemRow] {
        try await from("home_systems")
            .select()
            .eq("property_id", value: propertyId.uuidString)
            .order("name")
            .execute()
            .value
    }

    func fetchHomeSystems() async throws -> [HomeSystemRow] {
        try await from("home_systems")
            .select()
            .order("name")
            .execute()
            .value
    }

    func createHomeSystem(_ system: HomeSystemInsert) async throws -> HomeSystemRow {
        try await from("home_systems")
            .insert(system)
            .select()
            .single()
            .execute()
            .value
    }

    func updateHomeSystem(id: UUID, _ updates: HomeSystemUpdate) async throws -> HomeSystemRow {
        try await from("home_systems")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteHomeSystem(id: UUID) async throws {
        try await from("home_systems")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Warranties

    func fetchWarranties(systemId: UUID? = nil) async throws -> [WarrantyRow] {
        var query = from("warranties").select()
        if let systemId { query = query.eq("system_id", value: systemId.uuidString) }
        return try await query.order("end_date").execute().value
    }

    func createWarranty(_ warranty: WarrantyInsert) async throws -> WarrantyRow {
        try await from("warranties")
            .insert(warranty)
            .select()
            .single()
            .execute()
            .value
    }

    func updateWarranty(id: UUID, _ updates: WarrantyUpdate) async throws -> WarrantyRow {
        try await from("warranties")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteWarranty(id: UUID) async throws {
        try await from("warranties")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Contractors

    func fetchContractors() async throws -> [ContractorRow] {
        try await from("contractors")
            .select()
            .order("company_name")
            .execute()
            .value
    }

    func createContractor(_ contractor: ContractorInsert) async throws -> ContractorRow {
        try await from("contractors")
            .insert(contractor)
            .select()
            .single()
            .execute()
            .value
    }

    func updateContractor(id: UUID, _ updates: ContractorUpdate) async throws -> ContractorRow {
        try await from("contractors")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteContractor(id: UUID) async throws {
        try await from("contractors")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Maintenance Tasks

    func fetchMaintenanceTasks(propertyId: UUID? = nil) async throws -> [MaintenanceTaskDBRow] {
        var query = from("maintenance_tasks").select()
        if let propertyId { query = query.eq("property_id", value: propertyId.uuidString) }
        return try await query.order("next_due_date").execute().value
    }

    func createMaintenanceTask(_ task: MaintenanceTaskInsert) async throws -> MaintenanceTaskDBRow {
        try await from("maintenance_tasks")
            .insert(task)
            .select()
            .single()
            .execute()
            .value
    }

    func updateMaintenanceTask(id: UUID, _ updates: MaintenanceTaskUpdate) async throws -> MaintenanceTaskDBRow {
        try await from("maintenance_tasks")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    /// Update or clear task user assignment
    func clearMaintenanceTaskAssignment(id: UUID, userId: UUID?) async throws -> MaintenanceTaskDBRow {
        if let userId {
            return try await updateMaintenanceTask(id: id, MaintenanceTaskUpdate(assignedToUserId: userId))
        } else {
            // Use raw dict to explicitly set NULL (Codable optionals omit nil)
            return try await from("maintenance_tasks")
                .update(["assigned_to_user_id": nil] as [String: String?])
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func deleteMaintenanceTask(id: UUID) async throws {
        try await from("maintenance_tasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Service Records

    func fetchServiceRecords(systemId: UUID? = nil, propertyId: UUID? = nil) async throws -> [ServiceRecordRow] {
        var query = from("service_records").select()
        if let systemId { query = query.eq("system_id", value: systemId.uuidString) }
        if let propertyId { query = query.eq("property_id", value: propertyId.uuidString) }
        return try await query.order("service_date", ascending: false).execute().value
    }

    func createServiceRecord(_ record: ServiceRecordInsert) async throws -> ServiceRecordRow {
        try await from("service_records")
            .insert(record)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteServiceRecord(id: UUID) async throws {
        try await from("service_records")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Chat Messages

    func fetchChatMessages(limit: Int = 50) async throws -> [ChatMessageRow] {
        try await from("chat_messages")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func createChatMessage(_ message: ChatMessageInsert) async throws -> ChatMessageRow {
        try await from("chat_messages")
            .insert(message)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteAllChatMessages() async throws {
        // Delete ALL chat messages for this household.
        // We use household_id (not user_id) because the edge function
        // may save messages with null or inconsistent user_id values.
        let user = try await fetchCurrentUser()
        guard let householdId = user.householdId else {
            throw NSError(domain: "DatabaseService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No household found"])
        }

        let result = try await from("chat_messages")
            .delete()
            .eq("household_id", value: householdId.uuidString)
            .execute()

        print("[Chat] Deleted chat messages for household \(householdId). Status: \(result.status)")
    }

    // MARK: - Completion Scores

    func fetchCompletionScores() async throws -> [CompletionScoreRow] {
        try await from("completion_scores")
            .select()
            .order("category")
            .execute()
            .value
    }

    func upsertCompletionScore(_ score: CompletionScoreInsert) async throws -> CompletionScoreRow {
        try await from("completion_scores")
            .upsert(score)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Access Log

    func fetchAccessLogs(limit: Int = 100) async throws -> [AccessLogRow] {
        try await from("access_log")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchAccessLogs(action: String, limit: Int = 50) async throws -> [AccessLogRow] {
        try await from("access_log")
            .select()
            .eq("action", value: action)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Access Log Write (client-side backup)

    func logAccess(
        action: String,
        resourceType: String,
        resourceId: UUID? = nil,
        resourceName: String? = nil,
        actorType: String = "user",
        metadata: [String: String] = [:]
    ) async {
        do {
            let user = try await fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            struct AccessLogInsert: Encodable {
                let householdId: UUID
                let userId: UUID
                let action: String
                let resourceType: String
                let resourceId: UUID?
                let resourceName: String?
                let actorType: String
                let metadata: [String: String]?

                enum CodingKeys: String, CodingKey {
                    case action, metadata
                    case householdId = "household_id"
                    case userId = "user_id"
                    case resourceType = "resource_type"
                    case resourceId = "resource_id"
                    case resourceName = "resource_name"
                    case actorType = "actor_type"
                }
            }

            let insert = AccessLogInsert(
                householdId: householdId,
                userId: user.id,
                action: action,
                resourceType: resourceType,
                resourceId: resourceId,
                resourceName: resourceName,
                actorType: actorType,
                metadata: metadata.isEmpty ? nil : metadata
            )

            try await from("access_log")
                .insert(insert)
                .execute()
        } catch {
            print("[AccessLog] Failed to log \(action): \(error.localizedDescription)")
        }
    }

    // MARK: - Estate Readiness Calculation

    struct EstateReadinessScore {
        let overallPercentage: Double
        let totalCategories: Int
        let filledCategories: Int
        let uploadedCount: Int
        let missingCount: Int
        let expiringCount: Int
        let sectionScores: [SectionScore]
    }

    struct SectionScore: Identifiable {
        var id: String { section }
        let section: String
        let categories: [String]
        let filledCategories: Int
        let totalCategories: Int
        var percentage: Double {
            totalCategories > 0 ? Double(filledCategories) / Double(totalCategories) * 100 : 0
        }
    }

    func calculateEstateReadiness() async throws -> EstateReadinessScore {
        let documents = try await fetchDocuments()
        let dismissed = (try? await fetchDismissedCategories()) ?? []
        let dismissedSet = Set(dismissed.map(\.category))

        let sectionMap: [(String, [String])] = [
            ("Estate Planning", ["Will", "Trust", "Power of Attorney", "Healthcare Directive", "Guardianship Designation", "Letter of Intent"]),
            ("Entity Documents", ["LLC Operating Agreement", "LP Agreement", "S-Corp Documents", "EIN Documentation", "Annual Filings", "Bylaws"]),
            ("Real Estate", ["Deed", "Mortgage", "Title Insurance", "Survey", "HOA Documents", "Lease Agreement", "Property Tax Records"]),
            ("Insurance", ["Life Insurance", "Umbrella Insurance", "Homeowners Insurance", "Auto Insurance", "Jewelry/Art Rider", "Long-Term Care Insurance", "Disability Insurance", "Directors & Officers Insurance"]),
            ("Financial Accounts", ["Brokerage Account", "Retirement Account (IRA/401k)", "Bank Account", "529 Plan", "Beneficiary Designation", "Stock Options/RSUs", "Crypto Wallet", "Alternative Investments"]),
            ("Tax Records", ["Federal Tax Return", "State Tax Return", "Gift Tax Return (Form 709)", "Property Tax Record", "Estate & Trust Return (Form 1041)"]),
            ("Personal Property", ["Vehicle Title", "Art Appraisal", "Jewelry Appraisal", "Collectibles Documentation", "Boat/Aircraft Registration"]),
            ("Digital Assets", ["Domain Names", "Digital Account Inventory", "Social Media Accounts", "Intellectual Property"]),
            ("Personal Identification", ["Passport", "Birth Certificate", "Marriage Certificate", "Divorce Decree", "Social Security Card", "Citizenship/Immigration", "Death Certificate"]),
            ("Professional & Business", ["Employment Agreement", "Non-Compete/NDA", "Partnership Agreement", "Buy-Sell Agreement", "Succession Plan"]),
        ]

        let existingCategories = Set(documents.map { $0.category })

        var sectionScores: [SectionScore] = []
        var totalCategories = 0
        var filledCategories = 0

        for (section, categories) in sectionMap {
            let activeCategories = categories.filter { !dismissedSet.contains($0) }
            let filled = activeCategories.filter { existingCategories.contains($0) }.count
            sectionScores.append(SectionScore(
                section: section,
                categories: activeCategories,
                filledCategories: filled,
                totalCategories: activeCategories.count
            ))
            totalCategories += activeCategories.count
            filledCategories += filled
        }

        // Count expiring (within 90 days)
        let now = Date()
        let ninetyDays = Calendar.current.date(byAdding: .day, value: 90, to: now) ?? now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let expiringCount = documents.filter { doc in
            guard let expStr = doc.expirationDate,
                  let expDate = dateFormatter.date(from: expStr) else { return false }
            return expDate > now && expDate < ninetyDays
        }.count

        let overallPct = totalCategories > 0 ? Double(filledCategories) / Double(totalCategories) * 100 : 0

        return EstateReadinessScore(
            overallPercentage: overallPct,
            totalCategories: totalCategories,
            filledCategories: filledCategories,
            uploadedCount: documents.count,
            missingCount: totalCategories - filledCategories,
            expiringCount: expiringCount,
            sectionScores: sectionScores
        )
    }

    // MARK: - Documents (vault lock helpers)

    func fetchDocumentCount() async throws -> Int {
        let docs: [DocumentRow] = try await from("documents")
            .select()
            .execute()
            .value
        return docs.count
    }

    func fetchVaultLockedDocuments() async throws -> [DocumentRow] {
        try await from("documents")
            .select()
            .eq("vault_locked", value: true)
            .order("title")
            .execute()
            .value
    }

    // MARK: - Dismissed Categories

    func fetchDismissedCategories() async throws -> [DismissedCategoryRow] {
        try await from("dismissed_categories")
            .select()
            .execute()
            .value
    }

    func dismissCategory(householdId: UUID, category: String) async throws {
        let insert = DismissedCategoryInsert(householdId: householdId, category: category)
        try await from("dismissed_categories")
            .upsert(insert)
            .execute()
    }

    func undismissCategory(category: String) async throws {
        let user = try await fetchCurrentUser()
        guard let householdId = user.householdId else { return }
        try await from("dismissed_categories")
            .delete()
            .eq("household_id", value: householdId.uuidString)
            .eq("category", value: category)
            .execute()
    }

    // MARK: - Concierge Messages

    func insertConciergeMessage(
        householdId: UUID,
        userId: UUID,
        role: String,
        content: String
    ) async throws {
        let insert = ConciergeMessageInsert(
            householdId: householdId,
            userId: userId,
            role: role,
            content: content
        )
        try await from("concierge_messages")
            .insert(insert)
            .execute()
    }

    func fetchConciergeMessages(limit: Int = 50) async throws -> [ConciergeMessageRow] {
        try await from("concierge_messages")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Household Invitations

    func createInvitation(_ insert: HouseholdInvitationInsert) async throws -> HouseholdInvitationRow {
        try await from("household_invitations")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchInvitationsForHousehold() async throws -> [HouseholdInvitationRow] {
        try await from("household_invitations")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Check if there's a pending invitation for the current user's email
    /// Check if a user with this email already has a Haven account
    func checkExistingUser(email: String) async throws -> UserRow? {
        let results: [UserRow] = try await from("users")
            .select()
            .eq("email", value: email.lowercased())
            .limit(1)
            .execute()
            .value
        return results.first
    }

    func checkPendingInvitation(email: String) async throws -> HouseholdInvitationRow? {
        let results: [HouseholdInvitationRow] = try await from("household_invitations")
            .select()
            .eq("invited_email", value: email)
            .eq("status", value: "pending")
            .execute()
            .value

        // Return the first non-expired invitation
        return results.first { invitation in
            guard let expiresAt = invitation.expiresAt else { return true }
            return expiresAt > Date()
        }
    }

    /// Accept an invitation — link user to household
    func acceptInvitation(invitationId: UUID, userId: UUID) async throws {
        try await from("household_invitations")
            .update(["status": "accepted", "accepted_at": ISO8601DateFormatter().string(from: Date()), "accepted_by": userId.uuidString])
            .eq("id", value: invitationId.uuidString)
            .execute()
    }

    /// Look up invitation by invite code
    func lookupInviteCode(_ code: String) async throws -> HouseholdInvitationRow? {
        let results: [HouseholdInvitationRow] = try await from("household_invitations")
            .select()
            .eq("invite_code", value: code.uppercased())
            .eq("status", value: "pending")
            .execute()
            .value
        return results.first
    }

    func revokeInvitation(id: UUID) async throws {
        try await from("household_invitations")
            .update(["status": "revoked"])
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Generate a random 6-character alphanumeric invite code
    static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No 0/O/1/I to avoid confusion
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    // MARK: - Property Attributes

    /// Merges a single key-value into the property's attributes JSONB column.
    func updatePropertyAttribute(propertyId: UUID, key: String, value: FlexibleValue) async throws -> PropertyRow {
        let current = try await fetchProperty(id: propertyId)
        var attrs = current.attributes ?? [:]
        attrs[key] = value
        return try await updateProperty(id: propertyId, PropertyUpdate(attributes: attrs))
    }

    // MARK: - Service Contracts

    func fetchServiceContracts(propertyId: UUID? = nil) async throws -> [ServiceContractRow] {
        var query = from("service_contracts").select()
        if let propertyId { query = query.eq("property_id", value: propertyId.uuidString) }
        return try await query.order("created_at", ascending: false).execute().value
    }

    func createServiceContract(_ contract: ServiceContractInsert) async throws -> ServiceContractRow {
        try await from("service_contracts")
            .insert(contract)
            .select()
            .single()
            .execute()
            .value
    }

    func updateServiceContract(id: UUID, _ updates: ServiceContractUpdate) async throws -> ServiceContractRow {
        try await from("service_contracts")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteServiceContract(id: UUID) async throws {
        try await from("service_contracts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
