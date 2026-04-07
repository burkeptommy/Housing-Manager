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

    func uploadInboxAttachment(path: String, data: Data, contentType: String) async throws {
        try await HavenSupabase.storage
            .from("inbox-attachments")
            .upload(path, data: data, options: .init(contentType: contentType))
    }

    func getInboxAttachmentSignedURL(path: String) async throws -> URL {
        try await HavenSupabase.storage
            .from("inbox-attachments")
            .createSignedURL(path: path, expiresIn: 3600)
    }

    func updateInboxItemTitle(id: UUID, title: String) async throws {
        struct Update: Encodable { let title: String }
        try await from("inbox_items")
            .update(Update(title: title))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateInboxItemType(id: UUID, type: String, familyCategory: String?) async throws {
        struct Update: Encodable {
            let type: String
            let familyCategory: String?
            enum CodingKeys: String, CodingKey {
                case type
                case familyCategory = "family_category"
            }
        }
        try await from("inbox_items")
            .update(Update(type: type, familyCategory: familyCategory))
            .eq("id", value: id.uuidString)
            .execute()
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

    func fetchHomeSystems(propertyId: UUID, topLevelOnly: Bool = false) async throws -> [HomeSystemRow] {
        var query = from("home_systems")
            .select()
            .eq("property_id", value: propertyId.uuidString)
        if topLevelOnly {
            query = query.is("parent_system_id", value: nil)
        }
        return try await query.order("name").execute().value
    }

    func fetchHomeSystems() async throws -> [HomeSystemRow] {
        try await from("home_systems")
            .select()
            .order("name")
            .execute()
            .value
    }

    func fetchChildSystems(parentId: UUID) async throws -> [HomeSystemRow] {
        try await from("home_systems")
            .select()
            .eq("parent_system_id", value: parentId.uuidString)
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

    // MARK: - Utility Accounts

    func fetchUtilityAccounts(propertyId: UUID) async throws -> [UtilityAccountRow] {
        try await from("utility_accounts")
            .select()
            .eq("property_id", value: propertyId.uuidString)
            .order("provider_type", ascending: true)
            .execute()
            .value
    }

    func createUtilityAccount(_ account: UtilityAccountInsert) async throws -> UtilityAccountRow {
        try await from("utility_accounts")
            .insert(account)
            .select()
            .single()
            .execute()
            .value
    }

    func updateUtilityAccount(id: UUID, _ updates: [String: String]) async throws {
        try await from("utility_accounts")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteUtilityAccount(id: UUID) async throws {
        try await from("utility_accounts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchUtilityProviders(type: String? = nil) async throws -> [UtilityProviderRow] {
        var query = from("utility_providers").select()
        if let type { query = query.eq("provider_type", value: type) }
        return try await query.order("name", ascending: true).execute().value
    }

    /// Insert a user-supplied utility provider into the global catalog. Used
    /// by UtilityProviderCustomAddSheet for the "didn't find yours? Add it"
    /// path. Slug is derived from the name; collisions silently retry by
    /// appending a short suffix.
    func createUtilityProvider(_ insert: UtilityProviderInsert) async throws -> UtilityProviderRow {
        try await from("utility_providers")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    /// Update home system manual links cache
    func updateHomeSystemManualCache(id: UUID, links: [CachedManualLink]) async throws {
        struct Update: Encodable {
            let cachedManualLinks: [CachedManualLink]
            enum CodingKeys: String, CodingKey {
                case cachedManualLinks = "cached_manual_links"
            }
        }
        try await from("home_systems")
            .update(Update(cachedManualLinks: links))
            .eq("id", value: id.uuidString)
            .execute()
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

    func fetchMaintenanceTasks(propertyId: UUID? = nil, systemId: UUID? = nil, vehicleId: UUID? = nil) async throws -> [MaintenanceTaskDBRow] {
        var query = from("maintenance_tasks").select()
        if let propertyId { query = query.eq("property_id", value: propertyId.uuidString) }
        if let systemId { query = query.eq("system_id", value: systemId.uuidString) }
        if let vehicleId { query = query.eq("vehicle_id", value: vehicleId.uuidString) }
        return try await query.order("next_due_date").execute().value
    }

    func fetchVehicleMaintenanceTasks(vehicleId: UUID) async throws -> [MaintenanceTaskDBRow] {
        try await from("maintenance_tasks")
            .select()
            .eq("vehicle_id", value: vehicleId.uuidString)
            .order("next_due_date")
            .execute()
            .value
    }

    func fetchAllMaintenanceTasks() async throws -> [MaintenanceTaskDBRow] {
        try await from("maintenance_tasks")
            .select()
            .order("next_due_date")
            .execute()
            .value
    }

    func createMaintenanceTask(_ task: MaintenanceTaskInsert) async throws -> MaintenanceTaskDBRow {
        // Dedup check: skip if a task with the same title already exists for this property/vehicle/system
        var query = from("maintenance_tasks")
            .select("id")
            .eq("household_id", value: task.householdId.uuidString)
            .ilike("title", pattern: task.title)

        if let propertyId = task.propertyId {
            query = query.eq("property_id", value: propertyId.uuidString)
        }
        if let vehicleId = task.vehicleId {
            query = query.eq("vehicle_id", value: vehicleId.uuidString)
        }
        if let systemId = task.systemId {
            query = query.eq("system_id", value: systemId.uuidString)
        }

        struct IdRow: Codable { let id: UUID }
        let existing: [IdRow] = (try? await query.limit(1).execute().value) ?? []
        if let existingId = existing.first?.id {
            // Return the existing task instead of creating a duplicate
            print("[DatabaseService] Skipping duplicate task: \(task.title)")
            return try await from("maintenance_tasks")
                .select()
                .eq("id", value: existingId.uuidString)
                .single()
                .execute()
                .value
        }

        return try await from("maintenance_tasks")
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

    /// Remove the assigned contractor from a task (sets to NULL)
    func clearMaintenanceTaskContractor(id: UUID) async throws {
        try await from("maintenance_tasks")
            .update(["assigned_contractor_id": nil] as [String: String?])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteMaintenanceTask(id: UUID) async throws {
        try await from("maintenance_tasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Batch-delete maintenance tasks in a single round-trip.
    func deleteMaintenanceTasks(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        try await from("maintenance_tasks")
            .delete()
            .in("id", values: ids.map(\.uuidString))
            .execute()
    }

    // MARK: - Device Tokens

    func upsertDeviceToken(userId: UUID, token: String) async throws {
        // Use select() to verify the row was actually written (RLS can silently block inserts)
        let response: [DeviceTokenUpsert] = try await from("device_tokens")
            .upsert(
                DeviceTokenUpsert(userId: userId, token: token, platform: "ios"),
                onConflict: "user_id,token"
            )
            .select("user_id,token,platform")
            .execute()
            .value
        if response.isEmpty {
            print("[Push] WARNING: Upsert returned 0 rows — RLS may be blocking the insert for user \(userId)")
        } else {
            print("[Push] Token upsert confirmed: \(response.count) row(s)")
        }
    }

    func deleteDeviceToken(token: String) async throws {
        try await from("device_tokens")
            .delete()
            .eq("token", value: token)
            .execute()
    }

    // MARK: - Service Records

    func fetchServiceRecords(systemId: UUID? = nil, propertyId: UUID? = nil) async throws -> [ServiceRecordRow] {
        var query = from("service_records").select()
        if let systemId { query = query.eq("system_id", value: systemId.uuidString) }
        if let propertyId { query = query.eq("property_id", value: propertyId.uuidString) }
        return try await query.order("service_date", ascending: false).execute().value
    }

    func fetchServiceRecordsForDocument(documentId: UUID) async throws -> [ServiceRecordRow] {
        try await from("service_records")
            .select()
            .eq("invoice_document_id", value: documentId.uuidString)
            .execute()
            .value
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

    /// Fetch only pending (not accepted, not revoked, not expired) invitations for the
    /// settings pending invitations section. Sorted oldest-first so the most-overdue
    /// ones surface first.
    func fetchPendingInvitationsForHousehold() async throws -> [HouseholdInvitationRow] {
        let rows: [HouseholdInvitationRow] = try await from("household_invitations")
            .select()
            .eq("status", value: "pending")
            .order("created_at", ascending: true)
            .execute()
            .value
        let now = Date()
        return rows.filter { row in
            guard let expiresAt = row.expiresAt else { return true }
            return expiresAt > now
        }
    }

    /// Mark the timestamp on an invitation when a manual or scheduled resend fires.
    /// Cooldown enforcement happens client-side: 10-minute cooldown for the manual
    /// resend button in the settings pending invitations row.
    func touchInvitationResent(id: UUID) async throws {
        let isoString = ISO8601DateFormatter().string(from: Date())
        struct ResentUpdate: Encodable {
            let reminderSentAt: String
            enum CodingKeys: String, CodingKey { case reminderSentAt = "reminder_sent_at" }
        }
        try await from("household_invitations")
            .update(ResentUpdate(reminderSentAt: isoString))
            .eq("id", value: id.uuidString)
            .execute()
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

    // MARK: - Property Projects

    func fetchProjects(propertyId: UUID) async throws -> [PropertyProjectRow] {
        try await from("property_projects")
            .select()
            .eq("property_id", value: propertyId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchProject(id: UUID) async throws -> PropertyProjectRow {
        try await from("property_projects")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func clearParentProject(id: UUID) async throws {
        struct NullParent: Codable {
            let parentProjectId: String? = nil
            enum CodingKeys: String, CodingKey {
                case parentProjectId = "parent_project_id"
            }
        }
        try await from("property_projects")
            .update(NullParent())
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Document-Project Linking

    func fetchDocuments(projectId: UUID) async throws -> [DocumentRow] {
        try await from("documents")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .is("deleted_at", value: nil)
            .order("uploaded_at", ascending: false)
            .execute()
            .value
    }

    func linkDocumentToProject(documentId: UUID, projectId: UUID) async throws {
        _ = try await from("documents")
            .update(["project_id": projectId.uuidString])
            .eq("id", value: documentId.uuidString)
            .execute()
    }

    func unlinkDocumentFromProject(documentId: UUID) async throws {
        struct NullProject: Codable {
            let projectId: String? = nil
            enum CodingKeys: String, CodingKey {
                case projectId = "project_id"
            }
        }
        try await from("documents")
            .update(NullProject())
            .eq("id", value: documentId.uuidString)
            .execute()
    }

    func fetchAllProjects() async throws -> [PropertyProjectRow] {
        try await from("property_projects")
            .select()
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Inbox Items (from forwarded emails)

    struct InboxItemRow: Decodable, Identifiable {
        let id: UUID
        let householdId: UUID
        let type: String
        let title: String
        let summary: String?
        let fromEmail: String?
        let relatedProjectId: UUID?
        let relatedDocumentId: UUID?
        let relatedContractorId: UUID?
        let seen: Bool
        let needsAction: Bool?
        let actionType: String?
        let actionCompleted: Bool?
        let attachmentPath: String?
        let attachmentContentType: String?
        let attachmentFilename: String?
        let status: String?  // "processing" or "ready"
        let familyCategory: String?
        let familyMemberName: String?
        let eventDate: Date?
        let taggedMemberIds: [UUID]?
        let metadata: InboxMetadata?
        let createdAt: Date?

        /// True if still processing AND less than 5 minutes old (stale items show as complete)
        var isProcessing: Bool {
            guard status == "processing" else { return false }
            guard let created = createdAt else { return false }
            return Date().timeIntervalSince(created) < 300 // 5 minutes
        }

        enum CodingKeys: String, CodingKey {
            case id, type, title, summary, seen, status
            case householdId = "household_id"
            case fromEmail = "from_email"
            case relatedProjectId = "related_project_id"
            case relatedDocumentId = "related_document_id"
            case relatedContractorId = "related_contractor_id"
            case needsAction = "needs_action"
            case actionType = "action_type"
            case actionCompleted = "action_completed"
            case attachmentPath = "attachment_path"
            case attachmentContentType = "attachment_content_type"
            case attachmentFilename = "attachment_filename"
            case familyCategory = "family_category"
            case familyMemberName = "family_member_name"
            case eventDate = "event_date"
            case taggedMemberIds = "tagged_member_ids"
            case metadata
            case createdAt = "created_at"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            // Required fields — these must exist or the row is invalid
            id = try c.decode(UUID.self, forKey: .id)
            householdId = try c.decode(UUID.self, forKey: .householdId)
            type = try c.decode(String.self, forKey: .type)
            title = try c.decode(String.self, forKey: .title)
            // Optional fields — use try? so one bad field doesn't kill the row
            summary = try? c.decodeIfPresent(String.self, forKey: .summary)
            fromEmail = try? c.decodeIfPresent(String.self, forKey: .fromEmail)
            relatedProjectId = try? c.decodeIfPresent(UUID.self, forKey: .relatedProjectId)
            relatedDocumentId = try? c.decodeIfPresent(UUID.self, forKey: .relatedDocumentId)
            relatedContractorId = try? c.decodeIfPresent(UUID.self, forKey: .relatedContractorId)
            seen = (try? c.decodeIfPresent(Bool.self, forKey: .seen)) ?? false
            needsAction = try? c.decodeIfPresent(Bool.self, forKey: .needsAction)
            actionType = try? c.decodeIfPresent(String.self, forKey: .actionType)
            actionCompleted = try? c.decodeIfPresent(Bool.self, forKey: .actionCompleted)
            attachmentPath = try? c.decodeIfPresent(String.self, forKey: .attachmentPath)
            attachmentContentType = try? c.decodeIfPresent(String.self, forKey: .attachmentContentType)
            attachmentFilename = try? c.decodeIfPresent(String.self, forKey: .attachmentFilename)
            status = try? c.decodeIfPresent(String.self, forKey: .status)
            familyCategory = try? c.decodeIfPresent(String.self, forKey: .familyCategory)
            familyMemberName = try? c.decodeIfPresent(String.self, forKey: .familyMemberName)
            eventDate = try? c.decodeIfPresent(Date.self, forKey: .eventDate)
            taggedMemberIds = try? c.decodeIfPresent([UUID].self, forKey: .taggedMemberIds)
            metadata = try? c.decodeIfPresent(InboxMetadata.self, forKey: .metadata)
            createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        }

        /// Whether this item requires user input before processing can complete
        var isPending: Bool {
            (needsAction ?? false) && !(actionCompleted ?? false)
        }

        /// Icon name for the item type
        var iconName: String {
            if isProcessing { return "arrow.trianglehead.2.clockwise" }
            switch type {
            case "project_created": return "hammer.fill"
            case "document_stored": return "doc.fill"
            case "vendor_added": return "person.crop.circle.badge.plus"
            case "contractor_quote": return "doc.text.magnifyingglass"
            case "insurance_claim": return "shield.fill"
            case "family": return "person.2.fill"
            default: return "envelope.fill"
            }
        }

        /// Color for the item status
        var statusColor: String {
            if isProcessing { return "navy" }
            if isPending { return "warning" }
            if type == "project_created" || type == "document_stored" || type == "vendor_added" { return "success" }
            return "secondary"
        }

        /// Raw email body from metadata (stored by receive-email)
        var rawEmailBody: String? { metadata?.emailBody }

        /// Email subject from metadata
        var emailSubject: String? { metadata?.subject }
    }

    /// Metadata JSONB stored on inbox items by the receive-email edge function
    struct UtilityProviderInfo: Decodable {
        let providerId: UUID?
        let providerName: String?
        let providerSlug: String?
        let providerType: String?
        let logoUrl: String?
        let brandColor: String?
        let website: String?
        let phone: String?

        enum CodingKeys: String, CodingKey {
            case website, phone
            case providerId = "provider_id"
            case providerName = "provider_name"
            case providerSlug = "provider_slug"
            case providerType = "provider_type"
            case logoUrl = "logo_url"
            case brandColor = "brand_color"
        }
    }

    struct UtilityProviderSuggestion: Decodable {
        let vendorName: String?
        let vendorPhone: String?
        let vendorEmail: String?

        enum CodingKeys: String, CodingKey {
            case vendorName = "vendor_name"
            case vendorPhone = "vendor_phone"
            case vendorEmail = "vendor_email"
        }
    }

    struct InboxMetadata: Decodable {
        let emailBody: String?
        let subject: String?
        let emailHash: String?
        // Vendor info from classification (for Save Contact)
        let vendorName: String?
        let vendorEmail: String?
        let vendorPhone: String?
        // Utility provider matching (for bill_invoice items)
        let utilityProvider: UtilityProviderInfo?
        let utilityProviderSuggestion: UtilityProviderSuggestion?
        let billAccountNumber: String?
        let billAmount: Double?
        // Document classification confidence
        let highConfidence: Bool?
        let suggestedCategory: String?
        let documentTitle: String?
        // Vehicle context
        let vehicleInvoice: Bool?
        // Analysis status
        let analysisSkipped: Bool?
        let analysisSkipReason: String?

        enum CodingKeys: String, CodingKey {
            case subject, classification
            case emailBody = "email_body"
            case emailHash = "email_hash"
            case utilityProvider = "utility_provider"
            case utilityProviderSuggestion = "utility_provider_suggestion"
            case billAccountNumber = "bill_account_number"
            case billAmount = "bill_amount"
            case highConfidence = "high_confidence"
            case suggestedCategory = "suggested_category"
            case documentTitle = "document_title"
            case vehicleInvoice = "vehicle_invoice"
            case analysisSkipped = "analysis_skipped"
            case analysisSkipReason = "analysis_skip_reason"
        }

        // The classification is nested inside metadata
        private enum ClassificationKeys: String, CodingKey {
            case vendorName, vendorEmail, vendorPhone
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            emailBody = try? c.decodeIfPresent(String.self, forKey: .emailBody)
            subject = try? c.decodeIfPresent(String.self, forKey: .subject)
            emailHash = try? c.decodeIfPresent(String.self, forKey: .emailHash)
            utilityProvider = try? c.decodeIfPresent(UtilityProviderInfo.self, forKey: .utilityProvider)
            utilityProviderSuggestion = try? c.decodeIfPresent(UtilityProviderSuggestion.self, forKey: .utilityProviderSuggestion)
            billAccountNumber = try? c.decodeIfPresent(String.self, forKey: .billAccountNumber)
            billAmount = try? c.decodeIfPresent(Double.self, forKey: .billAmount)
            highConfidence = try? c.decodeIfPresent(Bool.self, forKey: .highConfidence)
            suggestedCategory = try? c.decodeIfPresent(String.self, forKey: .suggestedCategory)
            documentTitle = try? c.decodeIfPresent(String.self, forKey: .documentTitle)
            vehicleInvoice = try? c.decodeIfPresent(Bool.self, forKey: .vehicleInvoice)
            analysisSkipped = try? c.decodeIfPresent(Bool.self, forKey: .analysisSkipped)
            analysisSkipReason = try? c.decodeIfPresent(String.self, forKey: .analysisSkipReason)
            // Extract vendor info from nested classification object
            if let classContainer = try? c.nestedContainer(keyedBy: ClassificationKeys.self, forKey: .classification) {
                vendorName = try? classContainer.decodeIfPresent(String.self, forKey: .vendorName)
                vendorEmail = try? classContainer.decodeIfPresent(String.self, forKey: .vendorEmail)
                vendorPhone = try? classContainer.decodeIfPresent(String.self, forKey: .vendorPhone)
            } else {
                vendorName = nil
                vendorEmail = nil
                vendorPhone = nil
            }
        }
    }

    func fetchUnseenInboxItems() async throws -> [InboxItemRow] {
        try await from("inbox_items")
            .select()
            .eq("seen", value: false)
            .order("created_at", ascending: false)
            .limit(10)
            .execute()
            .value
    }

    func fetchAllInboxItems() async throws -> [InboxItemRow] {
        try await from("inbox_items")
            .select()
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
    }

    func fetchPendingInboxItems() async throws -> [InboxItemRow] {
        try await from("inbox_items")
            .select()
            .eq("needs_action", value: true)
            .eq("action_completed", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createInboxItem(
        householdId: UUID,
        type: String,
        title: String,
        summary: String? = nil,
        relatedDocumentId: UUID? = nil,
        needsAction: Bool = false,
        actionType: String? = nil,
        status: String = "ready",
        attachmentFilename: String? = nil
    ) async throws {
        var row: [String: String?] = [
            "household_id": householdId.uuidString,
            "type": type,
            "title": title,
            "status": status,
        ]
        if let summary { row["summary"] = summary }
        if let relatedDocumentId { row["related_document_id"] = relatedDocumentId.uuidString }
        if let actionType { row["action_type"] = actionType }
        if let attachmentFilename { row["attachment_filename"] = attachmentFilename }

        try await from("inbox_items")
            .insert(row)
            .execute()

        // Set needs_action separately (bool vs string issue)
        if needsAction {
            // Get the most recent item for this document
            if let docId = relatedDocumentId {
                _ = try? await from("inbox_items")
                    .update(["needs_action": true])
                    .eq("related_document_id", value: docId.uuidString)
                    .execute()
            }
        }
    }

    func markInboxItemsSeen(ids: [UUID]) async throws {
        for id in ids {
            try await from("inbox_items")
                .update(["seen": true, "needs_action": false])
                .eq("id", value: id.uuidString)
                .execute()
        }
    }

    func deleteInboxItem(id: UUID) async throws {
        try await from("inbox_items")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateInboxItemEventDate(id: UUID, eventDate: Date?) async throws {
        struct Update: Encodable {
            let eventDate: Date?
            enum CodingKeys: String, CodingKey { case eventDate = "event_date" }
        }
        try await from("inbox_items")
            .update(Update(eventDate: eventDate))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateInboxItemTags(id: UUID, memberIds: [UUID]) async throws {
        struct Update: Encodable {
            let taggedMemberIds: [UUID]
            enum CodingKeys: String, CodingKey { case taggedMemberIds = "tagged_member_ids" }
        }
        try await from("inbox_items")
            .update(Update(taggedMemberIds: memberIds))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func insertFamilyInboxItem<T: Encodable>(_ item: T) async throws {
        try await from("inbox_items")
            .insert(item)
            .execute()
    }

    func fetchFamilyInboxItems() async throws -> [InboxItemRow] {
        // Fetch all inbox items and filter client-side for "family" type
        // (avoids any potential server-side filter issues)
        let all: [InboxItemRow] = try await from("inbox_items")
            .select()
            .order("created_at", ascending: false)
            .limit(500)
            .execute()
            .value
        print("[DB] fetchFamilyInboxItems: total=\(all.count), family=\(all.filter { $0.type == "family" }.count), types=\(Set(all.map { $0.type }))")
        return all.filter { $0.type == "family" }
    }

    // MARK: - Household Email Address

    func fetchHouseholdEmailAddress() async throws -> String? {
        struct EmailRow: Decodable {
            let uniqueAddress: String
            enum CodingKeys: String, CodingKey {
                case uniqueAddress = "unique_address"
            }
        }
        let rows: [EmailRow] = try await from("household_email_addresses")
            .select("unique_address")
            .limit(1)
            .execute()
            .value
        return rows.first?.uniqueAddress
    }

    func generateHouseholdEmailAddress() async throws -> String {
        // Get the current user's household
        let user = try await fetchCurrentUser()
        guard let householdId = user.householdId else {
            throw NSError(domain: "Haven", code: 0, userInfo: [NSLocalizedDescriptionKey: "No household found"])
        }

        // Get the household name to generate a readable email
        struct HouseholdRow: Decodable { let name: String? }
        let households: [HouseholdRow] = try await from("households")
            .select("name")
            .eq("id", value: householdId.uuidString)
            .limit(1)
            .execute()
            .value

        // Extract last name: "The Burke Family" -> "burke"
        var baseName = households.first?.name ?? ""
        baseName = baseName
            .replacingOccurrences(of: "The ", with: "")
            .replacingOccurrences(of: " Family", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }

        if baseName.isEmpty {
            baseName = String(householdId.uuidString.prefix(8)).lowercased()
        }

        // Get street number from primary property for collision resolution
        // e.g. "146 Oak Street" -> "146"
        struct PropertyStreet: Decodable { let street: String? }
        let properties: [PropertyStreet] = (try? await from("properties")
            .select("street")
            .eq("household_id", value: householdId.uuidString)
            .limit(1)
            .execute()
            .value) ?? []

        let streetNumber: String? = {
            guard let street = properties.first?.street else { return nil }
            // Extract leading digits: "146 Oak Street" -> "146"
            let digits = String(street.prefix(while: { $0.isNumber }))
            return digits.isEmpty ? nil : digits
        }()

        struct EmailInsert: Encodable {
            let householdId: UUID
            let uniqueAddress: String
            enum CodingKeys: String, CodingKey {
                case householdId = "household_id"
                case uniqueAddress = "unique_address"
            }
        }

        struct EmailRow: Decodable {
            let uniqueAddress: String
            enum CodingKeys: String, CodingKey {
                case uniqueAddress = "unique_address"
            }
        }

        // Build candidate addresses in priority order:
        // 1. burke@alfred.havenhome.dev
        // 2. 146burke@alfred.havenhome.dev (street number + last name)
        // 3. burke-<short uuid>@alfred.havenhome.dev (failsafe)
        var candidates: [String] = [
            "\(baseName)@alfred.havenhome.dev"
        ]

        if let num = streetNumber {
            candidates.append("\(num)\(baseName)@alfred.havenhome.dev")
        }

        // Failsafe: append short unique suffixes
        for i in 1...5 {
            let shortId = String(UUID().uuidString.prefix(4)).lowercased()
            // Use street number variants first, then random
            if let num = streetNumber, i <= 2 {
                candidates.append("\(num)\(baseName)\(i)@alfred.havenhome.dev")
            } else {
                candidates.append("\(baseName)-\(shortId)@alfred.havenhome.dev")
            }
        }

        // Try each candidate until one succeeds
        for candidate in candidates {
            do {
                let result: EmailRow = try await from("household_email_addresses")
                    .insert(EmailInsert(householdId: householdId, uniqueAddress: candidate))
                    .select("unique_address")
                    .single()
                    .execute()
                    .value
                return result.uniqueAddress
            } catch {
                // Collision — try next candidate
                continue
            }
        }

        throw NSError(domain: "Haven", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not generate a unique email address"])
    }

    // MARK: - Allowed Senders (Email Whitelist)

    struct AllowedSenderRow: Codable, Identifiable {
        let id: UUID
        let householdId: UUID
        let email: String
        let label: String?
        let isAutoAdded: Bool?
        let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, email, label
            case householdId = "household_id"
            case isAutoAdded = "is_auto_added"
            case createdAt = "created_at"
        }
    }

    func fetchAllowedSenders() async throws -> [AllowedSenderRow] {
        try await from("household_allowed_senders")
            .select()
            .order("created_at")
            .execute()
            .value
    }

    func addAllowedSender(householdId: UUID, email: String, label: String?) async throws -> AllowedSenderRow {
        struct Insert: Codable {
            let householdId: UUID
            let email: String
            let label: String?
            enum CodingKeys: String, CodingKey {
                case email, label
                case householdId = "household_id"
            }
        }
        return try await from("household_allowed_senders")
            .insert(Insert(householdId: householdId, email: email.lowercased().trimmingCharacters(in: .whitespaces), label: label))
            .select()
            .single()
            .execute()
            .value
    }

    func deleteAllowedSender(id: UUID) async throws {
        try await from("household_allowed_senders")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Projects

    func createProject(_ project: PropertyProjectInsert) async throws -> PropertyProjectRow {
        try await from("property_projects")
            .insert(project)
            .select()
            .single()
            .execute()
            .value
    }

    func updateProject(id: UUID, _ updates: PropertyProjectUpdate) async throws -> PropertyProjectRow {
        try await from("property_projects")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteProject(id: UUID) async throws {
        try await from("property_projects")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Project Line Items

    // MARK: - Project Quotes

    func createProjectQuote(_ quote: ProjectQuoteInsert) async throws -> ProjectQuoteRow {
        try await from("project_quotes")
            .insert(quote)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchProjectQuotes(projectId: UUID) async throws -> [ProjectQuoteRow] {
        try await from("project_quotes")
            .select()
            .eq("project_id", value: projectId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func deleteProjectQuote(id: UUID) async throws {
        try await from("project_quotes")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Project Contacts

    func fetchProjectContacts(projectId: UUID) async throws -> [ProjectContactRow] {
        try await from("project_contacts")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func addProjectContact(projectId: UUID, householdId: UUID, contractorId: UUID?, name: String?, email: String?, phone: String?, role: String = "contractor") async throws {
        struct Insert: Encodable {
            let projectId: UUID
            let householdId: UUID
            let contractorId: UUID?
            let contactName: String?
            let contactEmail: String?
            let contactPhone: String?
            let role: String
            let addedFrom: String

            enum CodingKeys: String, CodingKey {
                case role
                case projectId = "project_id"
                case householdId = "household_id"
                case contractorId = "contractor_id"
                case contactName = "contact_name"
                case contactEmail = "contact_email"
                case contactPhone = "contact_phone"
                case addedFrom = "added_from"
            }
        }
        try await from("project_contacts")
            .insert(Insert(
                projectId: projectId,
                householdId: householdId,
                contractorId: contractorId,
                contactName: name,
                contactEmail: email?.lowercased(),
                contactPhone: phone,
                role: role,
                addedFrom: "manual"
            ))
            .execute()
    }

    func deleteProjectContact(id: UUID) async throws {
        try await from("project_contacts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Find an existing contractor by name (case-insensitive) to avoid duplicates
    func findContractorByName(householdId: UUID, name: String) async throws -> ContractorRow? {
        let results: [ContractorRow] = try await from("contractors")
            .select()
            .eq("household_id", value: householdId)
            .ilike("company_name", pattern: "%\(name)%")
            .limit(1)
            .execute()
            .value
        return results.first
    }

    // MARK: - Project Files

    func fetchProjectFiles(projectId: UUID) async throws -> [ProjectFileRow] {
        try await from("project_files")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createProjectFile(_ file: ProjectFileInsert) async throws -> ProjectFileRow {
        try await from("project_files")
            .insert(file)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteProjectFile(id: UUID) async throws {
        try await from("project_files")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Family Events

    func fetchFamilyEvents(householdId: UUID) async throws -> [FamilyEventRow] {
        try await from("family_events")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("start_date", ascending: true)
            .execute()
            .value
    }

    func fetchUpcomingFamilyEvents(householdId: UUID, limit: Int = 50) async throws -> [FamilyEventRow] {
        let now = ISO8601DateFormatter().string(from: Date())
        return try await from("family_events")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .gte("start_date", value: now)
            .order("start_date", ascending: true)
            .limit(limit)
            .execute()
            .value
    }

    func insertFamilyEvent(_ event: FamilyEventInsert) async throws -> FamilyEventRow {
        try await from("family_events")
            .insert(event)
            .select()
            .single()
            .execute()
            .value
    }

    func insertFamilyEvents(_ events: [FamilyEventInsert]) async throws {
        // Use upsert to handle re-syncing the same calendar events
        try await from("family_events")
            .upsert(events, onConflict: "household_id,external_calendar_id,external_event_id")
            .execute()
    }

    func updateFamilyEvent(id: UUID, title: String?, startDate: Date?, endDate: Date?, allDay: Bool?, taggedMemberIds: [UUID]?) async throws {
        struct Update: Encodable {
            let title: String?
            let startDate: Date?
            let endDate: Date?
            let allDay: Bool?
            let taggedMemberIds: [UUID]?
            let updatedAt: Date

            enum CodingKeys: String, CodingKey {
                case title
                case startDate = "start_date"
                case endDate = "end_date"
                case allDay = "all_day"
                case taggedMemberIds = "tagged_member_ids"
                case updatedAt = "updated_at"
            }
        }
        try await from("family_events")
            .update(Update(
                title: title,
                startDate: startDate,
                endDate: endDate,
                allDay: allDay,
                taggedMemberIds: taggedMemberIds,
                updatedAt: Date()
            ))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteFamilyEvent(id: UUID) async throws {
        try await from("family_events")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteFamilyEvents(householdId: UUID, externalCalendarId: String) async throws {
        try await from("family_events")
            .delete()
            .eq("household_id", value: householdId.uuidString)
            .eq("external_calendar_id", value: externalCalendarId)
            .execute()
    }

    func fetchFamilyEventExternalIds(householdId: UUID, calendarId: String) async throws -> [String] {
        struct Row: Decodable {
            let externalEventId: String?
            enum CodingKeys: String, CodingKey {
                case externalEventId = "external_event_id"
            }
        }
        let rows: [Row] = try await from("family_events")
            .select("external_event_id")
            .eq("household_id", value: householdId.uuidString)
            .eq("external_calendar_id", value: calendarId)
            .execute()
            .value
        return rows.compactMap(\.externalEventId)
    }

    // MARK: - Synced Calendars

    func fetchSyncedCalendars() async throws -> [SyncedCalendarRow] {
        try await from("synced_calendars")
            .select()
            .order("calendar_title", ascending: true)
            .execute()
            .value
    }

    func upsertSyncedCalendar(
        householdId: UUID,
        userId: UUID,
        calendarIdentifier: String,
        calendarTitle: String,
        calendarColor: String?,
        isActive: Bool
    ) async throws {
        struct Upsert: Encodable {
            let householdId: UUID
            let userId: UUID
            let calendarIdentifier: String
            let calendarTitle: String
            let calendarColor: String?
            let isActive: Bool

            enum CodingKeys: String, CodingKey {
                case householdId = "household_id"
                case userId = "user_id"
                case calendarIdentifier = "calendar_identifier"
                case calendarTitle = "calendar_title"
                case calendarColor = "calendar_color"
                case isActive = "is_active"
            }
        }
        try await from("synced_calendars")
            .upsert(
                Upsert(
                    householdId: householdId,
                    userId: userId,
                    calendarIdentifier: calendarIdentifier,
                    calendarTitle: calendarTitle,
                    calendarColor: calendarColor,
                    isActive: isActive
                ),
                onConflict: "household_id,user_id,calendar_identifier"
            )
            .execute()
    }

    func deactivateSyncedCalendar(userId: UUID, calendarIdentifier: String) async throws {
        try await from("synced_calendars")
            .update(["is_active": false])
            .eq("user_id", value: userId.uuidString)
            .eq("calendar_identifier", value: calendarIdentifier)
            .execute()
    }

    func updateSyncedCalendarLastSync(id: UUID) async throws {
        struct Update: Encodable {
            let lastSyncedAt: Date
            enum CodingKeys: String, CodingKey {
                case lastSyncedAt = "last_synced_at"
            }
        }
        try await from("synced_calendars")
            .update(Update(lastSyncedAt: Date()))
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Vehicles

    func fetchVehicles() async throws -> [VehicleRow] {
        try await from("vehicles").select().order("name").execute().value
    }

    func fetchVehicle(id: UUID) async throws -> VehicleRow {
        try await from("vehicles").select().eq("id", value: id.uuidString).single().execute().value
    }

    func createVehicle(_ vehicle: VehicleInsert) async throws -> VehicleRow {
        try await from("vehicles").insert(vehicle).select().single().execute().value
    }

    func updateVehicle(id: UUID, _ updates: VehicleUpdate) async throws -> VehicleRow {
        try await from("vehicles").update(updates).eq("id", value: id.uuidString).select().single().execute().value
    }

    func deleteVehicle(id: UUID) async throws {
        try await from("vehicles").delete().eq("id", value: id.uuidString).execute()
    }

    // MARK: - Vehicle Service Records

    func fetchVehicleServiceRecords(vehicleId: UUID) async throws -> [VehicleServiceRecordRow] {
        try await from("vehicle_service_records").select().eq("vehicle_id", value: vehicleId.uuidString).order("service_date", ascending: false).execute().value
    }

    func createVehicleServiceRecord(_ record: VehicleServiceRecordInsert) async throws -> VehicleServiceRecordRow {
        try await from("vehicle_service_records").insert(record).select().single().execute().value
    }

    func deleteVehicleServiceRecord(id: UUID) async throws {
        try await from("vehicle_service_records").delete().eq("id", value: id.uuidString).execute()
    }

    // MARK: - Vehicle Recalls

    func fetchVehicleRecalls(vehicleId: UUID) async throws -> [VehicleRecallRow] {
        try await from("vehicle_recalls").select().eq("vehicle_id", value: vehicleId.uuidString).order("recall_date", ascending: false).execute().value
    }

    func createVehicleRecall(_ recall: VehicleRecallInsert) async throws -> VehicleRecallRow {
        try await from("vehicle_recalls").insert(recall).select().single().execute().value
    }

    func updateVehicleRecall(id: UUID, isResolved: Bool, resolvedDate: String?) async throws {
        struct RecallUpdate: Codable {
            let isResolved: Bool
            let resolvedDate: String?
            enum CodingKeys: String, CodingKey {
                case isResolved = "is_resolved"
                case resolvedDate = "resolved_date"
            }
        }
        try await from("vehicle_recalls").update(RecallUpdate(isResolved: isResolved, resolvedDate: resolvedDate)).eq("id", value: id.uuidString).execute()
    }

    // MARK: - Vehicle Documents

    func fetchVehicleDocuments(vehicleId: UUID) async throws -> [DocumentRow] {
        try await from("documents").select().eq("vehicle_id", value: vehicleId.uuidString).is("deleted_at", value: nil).order("uploaded_at", ascending: false).execute().value
    }

    // MARK: - App Config (force-update gate)

    /// Fetches the public `app_config` row for iOS. The table has a public
    /// SELECT policy so this works for both authenticated and unauthenticated
    /// callers. Used by `VersionCheckService` on every launch.
    func fetchAppConfig() async throws -> AppConfigRow {
        try await from("app_config")
            .select()
            .eq("id", value: "ios")
            .single()
            .execute()
            .value
    }
}
