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

    // MARK: - Documents

    func fetchDocuments(category: String? = nil, status: String? = nil) async throws -> [DocumentRow] {
        var query = from("documents").select()
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
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Document Family Members

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
            .insert(insert)
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
        let path = "\(householdId.uuidString)/\(UUID().uuidString)/\(fileName)"
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
}
