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

    /// Apr 7, 2026: replaced the bare `try await HavenSupabase.auth.session.user.id`
    /// with the bounded `safeSession` helper. The original blocking lookup
    /// hung onboarding for 90+ seconds on a stalled supabase-swift refresh.
    /// If the bounded lookup times out we throw a user-friendly error
    /// instead of being trapped — the caller can retry or fall back.
    func fetchCurrentUser() async throws -> UserRow {
        guard let session = await HavenSupabase.safeSession(timeout: 3.0) else {
            throw NSError(
                domain: "DatabaseService",
                code: 408,
                userInfo: [NSLocalizedDescriptionKey: "Authentication is taking too long. Please try again."]
            )
        }
        let userId = session.user.id
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

    /// Revokes a linked user's access to the current household.
    ///
    /// Routed through the `remove_household_access` SECURITY DEFINER
    /// RPC (migration `20260703_remove_household_access_rpc.sql`)
    /// because the base RLS policy on `public.users` is
    /// `USING (id = auth.uid())` — a client-side UPDATE targeting
    /// another household member's `users.household_id` silently
    /// affects 0 rows. The RPC verifies caller + target share a
    /// household, then performs both writes atomically:
    ///   1. `family_members.linked_user_id = NULL` for any row
    ///      pointing at the target (the member card survives so the
    ///      homeowner can re-invite from the same profile).
    ///   2. `users.household_id = NULL` for the target so RLS stops
    ///      returning household data to them.
    ///
    /// Self-removal is rejected server-side with SQLSTATE `22023` —
    /// account deletion runs through the existing `delete-account`
    /// Edge Function, not this path.
    func removeHouseholdAccess(userId: UUID) async throws {
        _ = try await HavenSupabase.client
            .rpc("remove_household_access", params: ["target_user_id": userId.uuidString])
            .execute()
    }

    /// Insert a user row without returning the result (avoids RLS SELECT issues).
    func createUserWithoutReturn(_ user: UserInsert) async throws {
        try await from("users")
            .insert(user)
            .execute()
    }

    // MARK: - Family Members

    /// Build 87: filters out home managers and other staff so the dashboard
    /// HouseholdStrip and Settings → Family Members never accidentally
    /// surface a paid contractor in the family card list. The migration
    /// `20260437_add_family_member_type.sql` defaults every existing row
    /// to 'family' so this is a no-op for legacy installs. The OR-IS-NULL
    /// clause is defensive in case a row escapes the migration.
    func fetchFamilyMembers() async throws -> [FamilyMemberRow] {
        try await from("family_members")
            .select()
            .or("member_type.eq.family,member_type.is.null")
            .order("first_name")
            .execute()
            .value
    }

    /// Fetch all family members for a specific household. Used by
    /// `PropertyCreationService` to check if a primary family member already
    /// exists before auto-creating one for the current user.
    func fetchFamilyMembers(householdId: UUID) async throws -> [FamilyMemberRow] {
        try await from("family_members")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .or("member_type.eq.family,member_type.is.null")
            .order("first_name")
            .execute()
            .value
    }

    /// Build 87: returns paid household staff (home managers, future
    /// roles). Mirrors `fetchFamilyMembers` but filters by `member_type IN
    /// ('home_manager', 'staff')`. Used by `DashboardViewModel` to populate
    /// the new HouseholdStaffStrip and by `HouseholdStaffView` in Settings.
    func fetchHouseholdStaff() async throws -> [FamilyMemberRow] {
        try await from("family_members")
            .select()
            .in("member_type", values: ["home_manager", "staff"])
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

    /// Fetch household users AND augment with linked family members not
    /// already represented in the users table. Defensive against the
    /// case where a `users` row has a stale or NULL `household_id` but
    /// the same user IS in `family_members` with `linked_user_id` set —
    /// the wife sign-in scenario where Tom (homeowner) had vanished
    /// from the assignee picker because his users.household_id never
    /// got stamped after early-onboarding migrations. Synthesized rows
    /// carry `householdId: nil` (we don't actually know it); the
    /// downstream consumer only cares about `id` for `assigned_to_user_id`
    /// writes and `fullName`/`email` for display.
    func fetchHouseholdUsersAugmented() async throws -> [UserRow] {
        let users = (try? await fetchHouseholdUsers()) ?? []
        let family = (try? await fetchFamilyMembers()) ?? []
        let staff = (try? await fetchHouseholdStaff()) ?? []
        let presentIds = Set(users.map(\.id))
        let synthesized: [UserRow] = (family + staff).compactMap { member in
            guard let linked = member.linkedUserId, !presentIds.contains(linked) else { return nil }
            let fullName = [member.firstName, member.lastName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return UserRow(
                id: linked,
                householdId: nil,
                email: member.email ?? "",
                fullName: fullName.isEmpty ? nil : fullName,
                role: "member",
                createdAt: nil
            )
        }
        return users + synthesized
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

    /// Build 87 (Home Manager expansion): toggles whether household home
    /// managers can see this document. Called from `DocumentAccessSheet`
    /// when the homeowner overrides the category-based default. Returns
    /// the refreshed `DocumentRow` so the caller can update its local
    /// state without re-fetching the full list.
    @discardableResult
    func updateDocumentHomeManagerVisibility(documentId: UUID, visible: Bool) async throws -> DocumentRow {
        var update = DocumentUpdate()
        update.visibleToHomeManagers = visible
        return try await updateDocument(id: documentId, update)
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

    /// Phase 95 audit (Wave 3) — insert into `chez_assessment_waitlist`
    /// when a homeowner picks the waitlist tile on the mode-fork screen.
    /// Idempotent via the unique (property_id) constraint — re-running
    /// for the same property is a no-op.
    @discardableResult
    func insertChezAssessmentWaitlist(
        propertyId: UUID,
        householdId: UUID,
        userId: UUID,
        addressFull: String?,
        state: String?,
        zip: String?
    ) async throws -> [String: AnyJSON] {
        struct WaitlistInsert: Encodable {
            let propertyId: String
            let householdId: String
            let userId: String
            let addressFull: String?
            let state: String?
            let zip: String?
            enum CodingKeys: String, CodingKey {
                case propertyId = "property_id"
                case householdId = "household_id"
                case userId = "user_id"
                case addressFull = "address_full"
                case state, zip
            }
        }
        let body = WaitlistInsert(
            propertyId: propertyId.uuidString,
            householdId: householdId.uuidString,
            userId: userId.uuidString,
            addressFull: addressFull,
            state: state,
            zip: zip
        )
        return try await from("chez_assessment_waitlist")
            .upsert(body, onConflict: "property_id")
            .select()
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
        // Chez v1: archived rows (`archived_at IS NOT NULL`) are
        // hidden from every property-level read. Soft-deletes via
        // `archiveHomeSystem(id:)` — used by the "I don't have this"
        // affordance in SystemCoverageFlow and the legacy service-row
        // backfill — disappear from Browse Systems / Coverage / etc.
        // without losing the row.
        var query = from("home_systems")
            .select()
            .eq("property_id", value: propertyId.uuidString)
            .is("archived_at", value: nil)
        if topLevelOnly {
            query = query.is("parent_system_id", value: nil)
        }
        return try await query.order("name").execute().value
    }

    func fetchHomeSystems() async throws -> [HomeSystemRow] {
        try await from("home_systems")
            .select()
            .is("archived_at", value: nil)
            .order("name")
            .execute()
            .value
    }

    /// Variant that returns ALL rows including archived. Reserved for
    /// the legacy backfill + future "Hidden systems" settings page.
    /// Routine reads should keep using `fetchHomeSystems` so they
    /// auto-filter.
    func fetchHomeSystemsIncludingArchived(householdId: UUID) async throws -> [HomeSystemRow] {
        try await from("home_systems")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("name")
            .execute()
            .value
    }

    func fetchChildSystems(parentId: UUID) async throws -> [HomeSystemRow] {
        try await from("home_systems")
            .select()
            .eq("parent_system_id", value: parentId.uuidString)
            .is("archived_at", value: nil)
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

    /// Chez v1: soft-deletes a home_systems row. Used by the "I don't
    /// have this" affordance in SystemCoverageFlow and by the legacy
    /// service-row backfill. Sets `archived_at = NOW()`. Idempotent —
    /// re-archiving a row just updates the timestamp.
    func archiveHomeSystem(id: UUID) async throws {
        var update = HomeSystemUpdate()
        update.archivedAt = Date()
        _ = try await from("home_systems")
            .update(update)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 101 (E5) — moves every maintenance task from one system to
    /// another. Used when an invoice shows a NEW unit replacing an old one:
    /// open tasks follow the new equipment, the old row archives, and the
    /// completed tasks keep their history on whichever system they ran under.
    func repointTasksToSystem(from oldSystemId: UUID, to newSystemId: UUID) async throws {
        struct Repoint: Encodable { let system_id: String }
        _ = try await from("maintenance_tasks")
            .update(Repoint(system_id: newSystemId.uuidString))
            .eq("system_id", value: oldSystemId.uuidString)
            .is("archived_at", value: nil)
            .is("last_completed_date", value: nil)
            .execute()
    }

    /// Reverses `archiveHomeSystem`. Reserved for a future "Hidden
    /// systems" settings list where users can restore mistakenly-
    /// removed rows.
    func unarchiveHomeSystem(id: UUID) async throws {
        // Postgres NULL on update isn't expressible through
        // HomeSystemUpdate's Optional<Date> (nil omits the key per
        // synthesized encodeIfPresent). Fall back to a raw RPC-style
        // update via a tiny encodable struct.
        struct Unarchive: Encodable { let archived_at: String? = nil }
        _ = try await from("home_systems")
            .update(Unarchive())
            .eq("id", value: id.uuidString)
            .execute()
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

    /// Clear the `subtype` column to NULL. Same Postgres-NULL-via-
    /// Encodable workaround as `unarchiveHomeSystem` — synthesized
    /// `encodeIfPresent` on `HomeSystemUpdate.subtype: String?` omits
    /// the key when nil, so we route through a tiny encodable that the
    /// Postgrest client serializes as a JSON null. Used by the Phase
    /// 70-era chimney-evidence migration when a row no longer qualifies
    /// for any subtype.
    func clearHomeSystemSubtype(id: UUID) async throws {
        struct ClearSubtype: Encodable { let subtype: String? = nil }
        _ = try await from("home_systems")
            .update(ClearSubtype())
            .eq("id", value: id.uuidString)
            .execute()
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

    func fetchUtilityAccount(id: UUID) async throws -> UtilityAccountRow {
        try await from("utility_accounts")
            .select()
            .eq("id", value: id.uuidString)
            .single()
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

    /// Fetch utility providers, optionally filtered by one or more provider_type
    /// values. The DB enum has fixed strings ("electric", "internet_cable",
    /// "oil", "propane", etc) — callers should pass these exact tokens. Some
    /// quiz questions cover multiple types (e.g. heating fuel covers oil +
    /// propane + natural_gas) so the array variant is the canonical form.
    func fetchUtilityProviders(types: [String]? = nil) async throws -> [UtilityProviderRow] {
        var query = from("utility_providers").select()
        if let types, !types.isEmpty {
            query = query.in("provider_type", values: types)
        }
        return try await query.order("name", ascending: true).execute().value
    }

    /// Single-type convenience wrapper for `fetchUtilityProviders(types:)`.
    /// Note: there is no default value here so the no-arg call sites bind
    /// unambiguously to the array variant above.
    func fetchUtilityProviders(type: String) async throws -> [UtilityProviderRow] {
        try await fetchUtilityProviders(types: [type])
    }

    /// Look up a single utility provider row by its slug. Used to recover from
    /// unique-constraint races in `createUtilityProvider`.
    func fetchUtilityProviderBySlug(_ slug: String) async throws -> UtilityProviderRow? {
        let rows: [UtilityProviderRow] = try await from("utility_providers")
            .select()
            .eq("slug", value: slug)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Phase 18e: Look up a single utility provider row by its ID. Used by
    /// HouseQuizAnswerMapper to fetch the full record at apply time and
    /// snapshot it onto the resulting utility_account row.
    func fetchUtilityProvider(id: UUID) async throws -> UtilityProviderRow? {
        let rows: [UtilityProviderRow] = try await from("utility_providers")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Phase 18e: Update a utility_account row with snapshotted provider info.
    /// Used by the one-time backfill in AppState that walks existing rows and
    /// fuzzy-matches their provider_name against the catalog so old accounts
    /// pick up logos. Inline Encodable struct so the nil-omitting Codable
    /// doesn't accidentally drop the field.
    func updateUtilityAccountProviderSnapshot(
        id: UUID,
        providerId: UUID?,
        providerSlug: String?,
        logoUrl: String?,
        brandColor: String?
    ) async throws {
        struct SnapshotPayload: Encodable {
            let providerId: UUID?
            let providerSlug: String?
            let logoUrl: String?
            let brandColor: String?
            enum CodingKeys: String, CodingKey {
                case providerId = "provider_id"
                case providerSlug = "provider_slug"
                case logoUrl = "logo_url"
                case brandColor = "brand_color"
            }
        }
        let payload = SnapshotPayload(
            providerId: providerId,
            providerSlug: providerSlug,
            logoUrl: logoUrl,
            brandColor: brandColor
        )
        try await from("utility_accounts")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 18e: Walk every utility_account on a property, fuzzy-match
    /// each row's provider_name against the utility_providers catalog, and
    /// patch logo_url/brand_color/provider_id where missing. Returns the
    /// number of rows that were updated.
    func backfillUtilityAccountSnapshots(propertyId: UUID) async throws -> Int {
        let accounts = try await fetchUtilityAccounts(propertyId: propertyId)
        let needsBackfill = accounts.filter { $0.logoUrl == nil && $0.providerName.isEmpty == false }
        guard !needsBackfill.isEmpty else { return 0 }
        var updated = 0
        for account in needsBackfill {
            // Try slug first (cheap exact match), then fuzzy name lookup.
            var match: UtilityProviderRow?
            if let slug = account.providerSlug {
                match = try? await fetchUtilityProviderBySlug(slug)
            }
            if match == nil {
                match = try? await findUtilityProviderByNameOrSlug(account.providerName)
            }
            // Only patch if the matched provider has at least a logo or brand
            // color worth snapshotting — otherwise the row stays untouched and
            // the next backfill pass can try again.
            guard let provider = match,
                  provider.logoUrl != nil || provider.brandColor != nil else { continue }
            try? await updateUtilityAccountProviderSnapshot(
                id: account.id,
                providerId: provider.id,
                providerSlug: provider.slug,
                logoUrl: provider.logoUrl,
                brandColor: provider.brandColor
            )
            updated += 1
        }
        return updated
    }

    /// Fuzzy-find an existing utility provider by name (case-insensitive
    /// substring) or slug. Used by `UtilityProviderCustomAddSheet` to surface
    /// a "Did you mean?" suggestion before letting the user create a duplicate.
    func findUtilityProviderByNameOrSlug(_ name: String) async throws -> UtilityProviderRow? {
        let needle = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !needle.isEmpty else { return nil }
        let slug = needle.replacingOccurrences(of: " ", with: "-")
        let byName: [UtilityProviderRow] = try await from("utility_providers")
            .select()
            .ilike("name", pattern: "%\(needle)%")
            .limit(1)
            .execute()
            .value
        if let first = byName.first { return first }
        return try await fetchUtilityProviderBySlug(slug)
    }

    /// Phase 18d: Patch a utility_providers row with a fresh logo URL and
    /// brand color. Used by the picker's lazy enrichment path so visiting
    /// the picker for a category triggers Brandfetch backfills for any rows
    /// still missing logos. Server-side enrich-provider-logos handles bulk
    /// catch-up; this client-side path keeps the picker self-healing for
    /// new providers added after the bulk run.
    func updateUtilityProviderLogo(
        id: UUID,
        logoUrl: String?,
        brandColor: String?
    ) async throws {
        struct LogoPayload: Encodable {
            let logoUrl: String?
            let brandColor: String?
            enum CodingKeys: String, CodingKey {
                case logoUrl = "logo_url"
                case brandColor = "brand_color"
            }
        }
        let payload = LogoPayload(logoUrl: logoUrl, brandColor: brandColor)
        try await from("utility_providers")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Mirror of the edge function's `CATEGORY_TO_PROVIDER_TYPE`. Phase X+1:
    /// after a user creates a contractor via VendorReviewForm, we attempt
    /// to upsert a row into the global `utility_providers` catalog so the
    /// vendor benefits other households once 2+ independently add the same
    /// company. Mapping is by canonical contractor.category → catalog
    /// provider_type. Categories not in this map are user-pending only
    /// (no catalog contribution) — typical for free-text categories the
    /// user typed in.
    private static let categoryToProviderType: [String: String] = [
        "HVAC": "hvac",
        "Plumbing": "plumbing",
        "Electrical": "electrical",
        "Roofing": "roofing",
        "Tree Service": "tree_service",
        "Garage Door": "garage_door",
        "Well System": "well_water_service",
        "Septic System": "septic_pumper",
        "Chimney": "chimney_sweep",
        "Landscaping": "landscaping",
        "Pest Control": "pest_control",
        "Pool/Spa": "pool_service",
        "Solar": "solar",
        "Security System": "security",
        "Irrigation": "irrigation",
        "Waterproofing": "waterproofing"
    ]

    /// Categories where user-contributed rows would pollute the catalog
    /// (electric/gas/insurance carriers are dominated by 2-5 national
    /// brands; insurance "brokers" are a different product than carriers).
    /// Skip the contribution for these — keep them admin-curated only.
    private static let catalogContributionExcludedCategories: Set<String> = [
        "electric", "natural_gas", "home_insurance", "auto_insurance"
    ]

    /// Phase X+1: after a household creates a contractor, attempt to
    /// upsert a row into the global `utility_providers` catalog so real
    /// user activity grows the shared database. Network-effect gate
    /// keeps single-household contributions hidden from other
    /// households (source = 'user_pending', contribution_count = 1)
    /// until a second household adds the same vendor (matched by
    /// normalized phone OR website domain) at which point the row
    /// promotes to 'user_verified'.
    ///
    /// Silent failure — never block the contractor create on this. The
    /// household-scoped contractors row is the source of truth.
    func contributeToUtilityProvidersCatalog(
        contractor: ContractorRow,
        propertyTown: String,
        propertyState: String
    ) async {
        guard let rawCategory = contractor.category else { return }
        let category = rawCategory.trimmingCharacters(in: .whitespaces)
        guard !category.isEmpty else { return }
        guard let providerType = Self.categoryToProviderType[category] else { return }
        if Self.catalogContributionExcludedCategories.contains(providerType) { return }

        // Normalize identity keys so two households entering the same
        // vendor with slight formatting differences still match.
        let normalizedPhone = Self.normalizePhone(contractor.phone)
        let normalizedDomain = Self.normalizeDomain(contractor.website)

        // No identity signal → skip. Without phone OR website we'd
        // create a row that can never match a second contribution,
        // defeating the network-effect gate.
        if normalizedPhone.isEmpty && normalizedDomain.isEmpty { return }

        do {
            // Find existing row by phone OR website domain match,
            // scoped to the same provider_type so an electrician and
            // a plumber sharing a phone don't collide.
            let existing = try await findExistingCatalogContribution(
                providerType: providerType,
                normalizedPhone: normalizedPhone,
                normalizedDomain: normalizedDomain
            )
            let stateUpper = propertyState.uppercased()
            if let existing {
                // Bump count + union regions. Promote pending → verified
                // at count >= 2.
                var existingRegions = existing.regions ?? []
                if !existingRegions.contains(propertyTown) { existingRegions.append(propertyTown) }
                if !existingRegions.contains(stateUpper) { existingRegions.append(stateUpper) }
                let newCount = (existing.contributionCount ?? 1) + 1
                let newSource: String = {
                    let currentSource = existing.source ?? "user_pending"
                    if currentSource == "user_pending" && newCount >= 2 { return "user_verified" }
                    return currentSource
                }()
                struct ContributionUpdate: Encodable {
                    let regions: [String]
                    let contributionCount: Int
                    let source: String
                    enum CodingKeys: String, CodingKey {
                        case regions, source
                        case contributionCount = "contribution_count"
                    }
                }
                _ = try await from("utility_providers")
                    .update(ContributionUpdate(
                        regions: existingRegions,
                        contributionCount: newCount,
                        source: newSource
                    ))
                    .eq("id", value: existing.id.uuidString)
                    .execute()
            } else {
                // First-time contribution → insert as user_pending.
                let slug = Self.slugifyContribution(name: contractor.companyName)
                var insert = UtilityProviderInsert(
                    name: contractor.companyName,
                    slug: slug,
                    providerType: providerType
                )
                insert.website = contractor.website
                insert.phone = contractor.phone
                insert.logoUrl = contractor.logoUrl
                insert.brandColor = contractor.brandColor
                insert.regions = [propertyTown, stateUpper]
                insert.source = "user_pending"
                insert.contributionCount = 1
                _ = try await from("utility_providers")
                    .insert(insert)
                    .execute()
            }
        } catch {
            // Silent — contractor creation already succeeded; the
            // catalog contribution is best-effort.
            print("[contributeToUtilityProvidersCatalog] skipped: \(error)")
        }
    }

    /// Probe for an existing catalog row to attribute the new
    /// contribution to. Match strategy: same provider_type AND
    /// (phone match OR website-domain match). Phone is normalized to
    /// digits-only; domain is normalized to lowercased root host.
    private func findExistingCatalogContribution(
        providerType: String,
        normalizedPhone: String,
        normalizedDomain: String
    ) async throws -> UtilityProviderRow? {
        var matchers: [String] = []
        if !normalizedPhone.isEmpty {
            // PostgREST `like` filter on phone — strip non-digits at
            // query time would require an RPC; instead we fetch a
            // small candidate set by partial match then filter
            // client-side. Phone search by partial match is sufficient
            // since contractor.phone is small.
            matchers.append("phone.ilike.%\(normalizedPhone.suffix(7))%")
        }
        if !normalizedDomain.isEmpty {
            matchers.append("website.ilike.%\(normalizedDomain)%")
        }
        guard !matchers.isEmpty else { return nil }

        let candidates: [UtilityProviderRow] = try await from("utility_providers")
            .select()
            .eq("provider_type", value: providerType)
            .or(matchers.joined(separator: ","))
            .limit(10)
            .execute()
            .value

        return candidates.first(where: { row in
            let rowPhone = Self.normalizePhone(row.phone)
            let rowDomain = Self.normalizeDomain(row.website)
            if !normalizedPhone.isEmpty && rowPhone == normalizedPhone { return true }
            if !normalizedDomain.isEmpty && rowDomain == normalizedDomain { return true }
            return false
        })
    }

    private static func normalizePhone(_ raw: String?) -> String {
        guard let raw else { return "" }
        return raw.filter { $0.isNumber }
    }

    private static func normalizeDomain(_ raw: String?) -> String {
        guard let raw else { return "" }
        let trimmed = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return "" }
        var stripped = trimmed
        if stripped.hasPrefix("https://") { stripped.removeFirst("https://".count) }
        if stripped.hasPrefix("http://") { stripped.removeFirst("http://".count) }
        if stripped.hasPrefix("www.") { stripped.removeFirst("www.".count) }
        if let slash = stripped.firstIndex(of: "/") { stripped = String(stripped[..<slash]) }
        return stripped
    }

    private static func slugifyContribution(name: String) -> String {
        let base = name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        // Append a short UUID suffix so concurrent user contributions
        // with identical names don't collide on the slug UNIQUE index.
        let suffix = UUID().uuidString.prefix(6).lowercased()
        return "uc-\(base.isEmpty ? "vendor" : base)-\(suffix)"
    }

    /// Insert a user-supplied utility provider into the global catalog. Used
    /// by UtilityProviderCustomAddSheet for the "didn't find yours? Add it"
    /// path. Slug is derived from the name; if the insert hits a unique
    /// constraint violation (slug collision from a concurrent write), the
    /// existing row is fetched and returned instead so the caller still gets
    /// a usable provider.
    func createUtilityProvider(_ insert: UtilityProviderInsert) async throws -> UtilityProviderRow {
        do {
            return try await from("utility_providers")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value
        } catch {
            // Postgres unique constraint violation (code 23505) — fall back to
            // returning the existing row keyed by slug. Any other error
            // propagates so the UI can surface it.
            if let existing = try? await fetchUtilityProviderBySlug(insert.slug) {
                return existing
            }
            throw error
        }
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

    // MARK: - Household Advisors

    func fetchHouseholdAdvisors(householdId: UUID) async throws -> [HouseholdAdvisorRow] {
        try await from("household_advisors")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchHouseholdAdvisors(householdId: UUID, type: String) async throws -> [HouseholdAdvisorRow] {
        try await from("household_advisors")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("advisor_type", value: type)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createHouseholdAdvisor(_ advisor: HouseholdAdvisorInsert) async throws -> HouseholdAdvisorRow {
        try await from("household_advisors")
            .insert(advisor)
            .select()
            .single()
            .execute()
            .value
    }

    func updateHouseholdAdvisor(id: UUID, _ update: HouseholdAdvisorUpdate) async throws {
        try await from("household_advisors")
            .update(update)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteHouseholdAdvisor(id: UUID) async throws {
        try await from("household_advisors")
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

    func createContractor(
        _ contractor: ContractorInsert,
        skipRoutineSeed: Bool = false
    ) async throws -> ContractorRow {
        let created: ContractorRow = try await from("contractors")
            .insert(contractor)
            .select()
            .single()
            .execute()
            .value
        // Phase 58: seed a matching routine if this contractor falls into
        // one of the archetypal recurring-service categories (cleaning,
        // landscaping, pool, pest, pet waste, mosquito & tick).
        // Fire-and-forget — routine seeding should never block the
        // contractor creation itself.
        //
        // Round 4 (May 2026, friend feedback): the House Quiz's Q15b
        // mapper ALSO creates routines explicitly via
        // `ensureVendorRoutineForCategory` after creating contractors.
        // Both this fire-and-forget seeder AND the mapper's explicit
        // call would race on the dedup fetch+insert, producing TWO
        // active routines per Q15b vendor (Burke household had this
        // for Blue Fox / Orkin / ADT — 6 dupe routines total). The
        // quiz mapper now passes `skipRoutineSeed: true` so only the
        // explicit path runs; manual contractor adds outside the quiz
        // (Contacts directory, etc.) still fire the seeder as before.
        if !skipRoutineSeed {
            Task { @MainActor in
                await RoutineSeeder.shared.seedIfNeeded(for: created)
            }
        }
        // Phase 67 (C1): when a contractor is added in a category that had
        // gaps marked by the reconciler v2, clear the
        // `needs_vendor_coverage` flag on every home_systems row in the
        // matching category so VendorCoverageSheet drops the resolved gap.
        // Fire-and-forget for the same reason as routine seeding —
        // contractor creation never blocks on this side effect.
        Task { @MainActor in
            await Self.clearVendorCoverageGapsForCategory(
                created.category,
                householdId: created.householdId
            )
        }
        return created
    }

    /// Phase 67 (C1): clear `home_systems.needs_vendor_coverage = true` on
    /// every system in the matching canonical category. Called after a
    /// contractor is added so the dashboard's VendorCoverageSheet drops
    /// the resolved gap card. Best-effort — failures are swallowed. RLS
    /// scopes the read + writes to the caller's household automatically.
    @MainActor
    private static func clearVendorCoverageGapsForCategory(
        _ rawCategory: String?,
        householdId: UUID
    ) async {
        guard let raw = rawCategory, !raw.isEmpty else { return }
        let canonical = SystemCategoryRegistry.canonical(category: raw) ?? raw
        let systems: [HomeSystemRow]
        do {
            systems = try await DatabaseService.shared.fetchHomeSystems()
        } catch {
            return
        }
        for system in systems
        where system.householdId == householdId
            && system.needsVendorCoverage == true {
            let systemCanonical = SystemCategoryRegistry.canonical(category: system.category) ?? system.category
            guard systemCanonical.caseInsensitiveCompare(canonical) == .orderedSame else { continue }
            var update = HomeSystemUpdate()
            update.needsVendorCoverage = false
            _ = try? await DatabaseService.shared.updateHomeSystem(id: system.id, update)
        }
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

    func fetchContractor(id: UUID) async throws -> ContractorRow {
        try await from("contractors")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    private struct ContractorDisassociation: Encodable {
        let assigned_contractor_id: String? = nil
        let needs_vendor: Bool = true
        let assignment_type: String = "vendor"
    }

    func deleteContractor(id: UUID) async throws {
        // Disassociate any tasks assigned to this contractor before deleting
        // (FK constraint defaults to RESTRICT, so deletion would fail otherwise)
        try await from("maintenance_tasks")
            .update(ContractorDisassociation())
            .eq("assigned_contractor_id", value: id.uuidString)
            .execute()

        // Nullify service record references
        try await from("service_records")
            .update(["contractor_id": nil] as [String: String?])
            .eq("contractor_id", value: id.uuidString)
            .execute()

        // Nullify home system preferred contractor references
        try await from("home_systems")
            .update(["preferred_contractor_id": nil] as [String: String?])
            .eq("preferred_contractor_id", value: id.uuidString)
            .execute()

        // Now safe to delete the contractor row
        try await from("contractors")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Handyman Provider Directory

    private func makeHandymanProviderRequest(
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) async throws -> URLRequest {
        var components = URLComponents(string: "\(AppConfig.Supabase.url)/functions/v1/handyman-provider")
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "apikey")

        if let accessToken = await HavenSupabase.safeAccessToken(timeout: 3.0) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        return request
    }

    private func performHandymanProvider<T: Decodable>(
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        expecting: T.Type
    ) async throws -> T {
        let request = try await makeHandymanProviderRequest(
            method: method,
            queryItems: queryItems,
            body: body
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed"
            throw NSError(
                domain: "DatabaseService.HandymanProvider",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    func searchHandymanProviders(query: String, limit: Int = 18) async throws -> [HandymanProviderDirectoryRow] {
        let response: HandymanProviderDirectoryResponse = try await performHandymanProvider(
            method: "GET",
            queryItems: [
                URLQueryItem(name: "directory", value: "1"),
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit))
            ],
            expecting: HandymanProviderDirectoryResponse.self
        )
        return response.providers
    }

    func connectHandymanProviderToCurrentHousehold(
        workspaceId: String,
        setPreferred: Bool = true
    ) async throws -> ContractorRow {
        struct Request: Encodable {
            let action = "link_homeowner_contractor"
            let workspaceId: String
            let setPreferred: Bool
        }

        let body = try JSONEncoder().encode(
            Request(
                workspaceId: workspaceId,
                setPreferred: setPreferred
            )
        )

        let response: HandymanProviderLinkResponse = try await performHandymanProvider(
            method: "POST",
            body: body,
            expecting: HandymanProviderLinkResponse.self
        )
        return response.contractor
    }

    // MARK: - Maintenance Tasks

    func fetchMaintenanceTasks(propertyId: UUID? = nil, systemId: UUID? = nil, vehicleId: UUID? = nil, includeArchived: Bool = false) async throws -> [MaintenanceTaskDBRow] {
        var query = from("maintenance_tasks").select()
        if let propertyId { query = query.eq("property_id", value: propertyId.uuidString) }
        if let systemId { query = query.eq("system_id", value: systemId.uuidString) }
        if let vehicleId { query = query.eq("vehicle_id", value: vehicleId.uuidString) }
        if !includeArchived { query = query.eq("is_archived", value: false) }
        return try await query.order("next_due_date").execute().value
    }

    func fetchVehicleMaintenanceTasks(vehicleId: UUID, includeArchived: Bool = false) async throws -> [MaintenanceTaskDBRow] {
        var query = from("maintenance_tasks")
            .select()
            .eq("vehicle_id", value: vehicleId.uuidString)
        if !includeArchived { query = query.eq("is_archived", value: false) }
        return try await query
            .order("next_due_date")
            .execute()
            .value
    }

    /// Phase 58: fetches tasks assigned to a specific contractor, used by
    /// the vendor detail view's Upcoming + Recent Activity sections.
    func fetchMaintenanceTasksByContractor(_ contractorId: UUID, includeArchived: Bool = false) async throws -> [MaintenanceTaskDBRow] {
        var query = from("maintenance_tasks")
            .select()
            .eq("assigned_contractor_id", value: contractorId.uuidString)
        if !includeArchived { query = query.eq("is_archived", value: false) }
        return try await query.order("next_due_date").execute().value
    }

    /// Phase 58: fetches documents directly linked to a contractor via
    /// `documents.contractor_id`. Used by vendor detail's Recent Activity
    /// timeline. Does not include service-record invoices without the
    /// direct FK — caller should also query service_records if they want
    /// full coverage.
    func fetchDocumentsByContractor(_ contractorId: UUID) async throws -> [DocumentRow] {
        try await from("documents")
            .select()
            .eq("contractor_id", value: contractorId.uuidString)
            .is("deleted_at", value: nil)
            .order("uploaded_at", ascending: false)
            .execute()
            .value
    }

    func fetchAllMaintenanceTasks(includeArchived: Bool = false) async throws -> [MaintenanceTaskDBRow] {
        var query = from("maintenance_tasks").select()
        if !includeArchived { query = query.eq("is_archived", value: false) }
        return try await query
            .order("next_due_date")
            .execute()
            .value
    }

    /// Phase 70.A1 follow-on G3 — fetch the household's completed task
    /// history for the Completed sheet. Reads archived rows where the
    /// archive reason is "completed" (set by `MaintenanceViewModel.completeTask`
    /// at archive time). Sorted by `last_completed_date` descending so
    /// the most recent completion lands at the top. Limit defaults to
    /// 200 to keep payload small; the sheet caps visible rows + the
    /// homeowner reaches further via month grouping rather than a
    /// "load more" affordance (rare access pattern).
    func fetchCompletedMaintenanceTasks(
        householdId: UUID,
        limit: Int = 200
    ) async throws -> [MaintenanceTaskDBRow] {
        try await from("maintenance_tasks")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_archived", value: true)
            .eq("archived_reason", value: "completed")
            .order("last_completed_date", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Phase 70.A1 follow-on I2 — fetch archived (but NOT completed)
    /// task rows for the Archived tab of the Activity sheet. Catches
    /// swipe-dismissed work plus reconciler-pruned rows (e.g. orphans
    /// from the library reshape migrations). Sorted by `archived_at`
    /// descending so the most recent dismissal lands at the top.
    /// Pairs with `unarchiveMaintenanceTask(id:)` for the Restore action.
    func fetchArchivedMaintenanceTasks(
        householdId: UUID,
        limit: Int = 200
    ) async throws -> [MaintenanceTaskDBRow] {
        try await from("maintenance_tasks")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_archived", value: true)
            .neq("archived_reason", value: "completed")
            .order("archived_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func createMaintenanceTask(_ task: MaintenanceTaskInsert) async throws -> MaintenanceTaskDBRow {
        var task = task
        if task.serviceKey == nil {
            task.serviceKey = ServiceLibrary.serviceKey(for: task)
        }

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

    /// Soft-delete a maintenance task by setting `is_archived = true`.
    /// Used by `MaintenanceTaskReconciler` (Phase 17b) so the post-quiz
    /// task pruning never destroys history. The task stays in the DB and
    /// is hidden from default fetches via the `is_archived = false` filter.
    func archiveMaintenanceTask(id: UUID, reason: String? = nil) async throws {
        struct ArchivePayload: Encodable {
            let isArchived: Bool
            let archivedAt: String
            let archivedReason: String?
            enum CodingKeys: String, CodingKey {
                case isArchived = "is_archived"
                case archivedAt = "archived_at"
                case archivedReason = "archived_reason"
            }
        }
        let payload = ArchivePayload(
            isArchived: true,
            archivedAt: ISO8601DateFormatter().string(from: Date()),
            archivedReason: reason
        )
        try await from("maintenance_tasks")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// BUG-020 fix: counterpart to `archiveMaintenanceTask`. Lets users
    /// un-archive a task when the reconciler's heuristic was wrong (e.g.
    /// they added a hot tub later and want the hot-tub tasks back). Clears
    /// `is_archived`, `archived_at`, `archived_reason` in one update.
    func unarchiveMaintenanceTask(id: UUID) async throws {
        struct UnarchivePayload: Encodable {
            let isArchived: Bool
            let archivedAt: String?
            let archivedReason: String?
            enum CodingKeys: String, CodingKey {
                case isArchived = "is_archived"
                case archivedAt = "archived_at"
                case archivedReason = "archived_reason"
            }
        }
        let payload = UnarchivePayload(
            isArchived: false,
            archivedAt: nil,
            archivedReason: nil
        )
        try await from("maintenance_tasks")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 70.A1 follow-on I3 — reverse a G1 completion. Clears the
    /// archive trio (is_archived / archived_at / archived_reason) AND
    /// the last_completed_date stamp the G1 path wrote at completion
    /// time. Returns the restored row so callers can swap it back into
    /// their in-memory tasks array without a second fetch.
    func restoreCompletedMaintenanceTask(id: UUID) async throws -> MaintenanceTaskDBRow? {
        struct RestorePayload: Encodable {
            let isArchived: Bool
            let archivedAt: String?
            let archivedReason: String?
            let lastCompletedDate: String?
            enum CodingKeys: String, CodingKey {
                case isArchived = "is_archived"
                case archivedAt = "archived_at"
                case archivedReason = "archived_reason"
                case lastCompletedDate = "last_completed_date"
            }
        }
        let payload = RestorePayload(
            isArchived: false,
            archivedAt: nil,
            archivedReason: nil,
            lastCompletedDate: nil
        )
        let rows: [MaintenanceTaskDBRow] = try await from("maintenance_tasks")
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .execute()
            .value
        return rows.first
    }

    /// Phase 70.A1 follow-on I3 — fetch a single task by id for the
    /// undo path's local refresh. Bypasses the `is_archived=false`
    /// filter the other fetch helpers apply.
    func fetchMaintenanceTaskById(id: UUID) async throws -> MaintenanceTaskDBRow? {
        let rows: [MaintenanceTaskDBRow] = try await from("maintenance_tasks")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Handyman Punch Items (Phase 54B)

    // MARK: - Routing Preferences (Phase 65)

    /// Phase 65: Fetch all routing preferences for a household, optionally
    /// filtered to a specific property. Callers that resolve a task at
    /// creation time pass the property_id; the Settings screen passes nil
    /// to surface preferences across every property.
    func fetchRoutingPreferences(
        householdId: UUID,
        propertyId: UUID? = nil
    ) async throws -> [RoutingPreferenceRow] {
        var query = from("routing_preferences")
            .select()
            .eq("household_id", value: householdId.uuidString)
        if let propertyId {
            query = query.eq("property_id", value: propertyId.uuidString)
        }
        return try await query.execute().value
    }

    /// Phase 65: Upsert a category-level or template-level preference.
    /// Uses the unique index (household, property, category, scope_type)
    /// so re-calling with the same scope updates in place instead of
    /// creating a second row.
    @discardableResult
    func upsertRoutingPreference(_ insert: RoutingPreferenceInsert) async throws -> RoutingPreferenceRow {
        try await from("routing_preferences")
            .upsert(insert, onConflict: "household_id,property_id,task_category,scope_type", returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    /// Phase 65: Delete a single preference row. Used by the Settings
    /// reset affordance.
    func deleteRoutingPreference(id: UUID) async throws {
        try await from("routing_preferences")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 65: Stamp last_confirmed_at = now() across every preference
    /// row in the household. Called when the user taps "All good" on the
    /// annual re-confirm dashboard card.
    func confirmAllRoutingPreferences(householdId: UUID, propertyId: UUID?) async throws {
        struct ConfirmPayload: Encodable {
            let lastConfirmedAt: String
            enum CodingKeys: String, CodingKey {
                case lastConfirmedAt = "last_confirmed_at"
            }
        }
        let payload = ConfirmPayload(lastConfirmedAt: ISO8601DateFormatter().string(from: Date()))
        var query = try from("routing_preferences")
            .update(payload)
            .eq("household_id", value: householdId.uuidString)
        if let propertyId {
            query = query.eq("property_id", value: propertyId.uuidString)
        }
        try await query.execute()
    }

    /// Phase 64: Set the assigned_route on a maintenance task AND keep
    /// the handyman_punch_items surface in sync. Unifies Phase 54B's
    /// punch list with the routing column — tasks with route='handyman'
    /// materialize a punch item, and tasks routed away from handyman
    /// archive the corresponding punch item.
    ///
    /// Returns the updated task row for caller convenience.
    @discardableResult
    func setTaskRoute(
        taskId: UUID,
        route: String?,
        task: MaintenanceTaskDBRow? = nil
    ) async throws -> MaintenanceTaskDBRow? {
        // 1. Update the task's assigned_route.
        var update = MaintenanceTaskUpdate()
        update.assignedRoute = route
        let updatedTask = try await updateMaintenanceTask(id: taskId, update)

        // 2. Handyman punch-item synchronization.
        let resolvedTask = task ?? updatedTask
        let householdId = resolvedTask.householdId
        if route == "handyman" {
            // Materialize a punch item if there isn't one yet for this task.
            let existing = try? await fetchPendingHandymanPunchItems(householdId: householdId)
            let alreadyExists = existing?.contains { $0.maintenanceTaskId == taskId || $0.sourceTaskId == taskId } ?? false
            if !alreadyExists {
                var punch = HandymanPunchItemInsert(
                    householdId: householdId,
                    propertyId: resolvedTask.propertyId,
                    title: resolvedTask.title
                )
                punch.description = resolvedTask.description
                punch.source = "maintenance_task"
                punch.sourceTaskId = taskId
                punch.maintenanceTaskId = taskId
                punch.notes = "Routed from the task list via the routing picker."
                _ = try? await createHandymanPunchItem(punch)
            }
        } else {
            // Archive any pending punch item tied to this task — the user
            // chose a different route and we shouldn't leave stale items
            // on the list.
            if let existing = try? await fetchPendingHandymanPunchItems(householdId: householdId) {
                for item in existing where (item.maintenanceTaskId == taskId || item.sourceTaskId == taskId) {
                    try? await archiveHandymanPunchItem(id: item.id)
                }
            }
        }
        return updatedTask
    }

    /// Phase 54B: Fetch pending punch list items for a household — not
    /// yet folded into a scheduled handyman visit and not archived.
    /// Ordered by creation so oldest-added surfaces first (FIFO).
    func fetchPendingHandymanPunchItems(householdId: UUID) async throws -> [HandymanPunchItemRow] {
        try await from("handyman_punch_items")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .is("completed_at", value: nil)
            .is("archived_at", value: nil)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// Phase 78: punch items for a household scoped to one visit. The
    /// homeowner-side `HandymanVisitCard` reads this to render the
    /// punch list as checkable subitems under each visit row.
    func fetchHandymanPunchItemsForVisit(visitTaskId: UUID) async throws -> [HandymanPunchItemRow] {
        try await from("handyman_punch_items")
            .select()
            .eq("assigned_visit_task_id", value: visitTaskId.uuidString)
            .is("archived_at", value: nil)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// Phase 78: every punch item the household has, regardless of state.
    /// Lets the homeowner side bucket items by `assigned_visit_task_id`
    /// for the schedule-view rendering pass, AND surface pending items
    /// (proposal_status='pending', added_after_lock=true) in the inbox.
    func fetchAllHandymanPunchItems(householdId: UUID) async throws -> [HandymanPunchItemRow] {
        try await from("handyman_punch_items")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .is("archived_at", value: nil)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// Phase 78: handyman-flagged tasks awaiting homeowner accept/decline.
    /// `proposed_by_role='handyman'` AND `proposal_status='pending'`.
    /// Powers the Proposals Inbox in the homeowner Handyman tab.
    func fetchHandymanProposalTasks(householdId: UUID) async throws -> [MaintenanceTaskDBRow] {
        try await from("maintenance_tasks")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("proposed_by_role", value: "handyman")
            .eq("proposal_status", value: "pending")
            .order("proposed_at", ascending: false)
            .execute()
            .value
    }

    func createHandymanPunchItem(_ insert: HandymanPunchItemInsert) async throws -> HandymanPunchItemRow {
        try await from("handyman_punch_items")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    /// Phase 54B: Soft-delete a punch item (user tapped "Remove" or
    /// "Not relevant"). Sets `archived_at` instead of DELETE so we keep
    /// history for any future audit + undo affordance.
    ///
    /// Phase 67E/F: optional `reason` records WHY ("promoted_to_task"
    /// when the row was converted back into a scheduled task; nil for
    /// legacy user dismissals).
    func archiveHandymanPunchItem(id: UUID, reason: String? = nil) async throws {
        struct ArchivePayload: Encodable {
            let archivedAt: String
            let archiveReason: String?
            enum CodingKeys: String, CodingKey {
                case archivedAt = "archived_at"
                case archiveReason = "archive_reason"
            }
        }
        let payload = ArchivePayload(
            archivedAt: ISO8601DateFormatter().string(from: Date()),
            archiveReason: reason
        )
        try await from("handyman_punch_items")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 95: inline title edit for a manual punch item. Used by the
    /// long-press → "Edit title" affordance on `HandymanPunchListView`.
    /// Only the `title` column is updated; description / minutes / notes
    /// stay untouched (a heavier edit-sheet can land later if homeowners
    /// ask for it).
    func updateHandymanPunchItemTitle(id: UUID, title: String) async throws {
        struct TitleUpdate: Encodable {
            let title: String
        }
        try await from("handyman_punch_items")
            .update(TitleUpdate(title: title))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 54B: Mark a batch of punch items complete + link them to
    /// the handyman visit task they were rolled into. Called by
    /// `HandymanPunchListView` after it creates the Handyman:spring /
    /// Handyman:fall bundle task.
    func completePunchItems(ids: [UUID], visitTaskId: UUID) async throws {
        guard !ids.isEmpty else { return }
        struct CompletePayload: Encodable {
            let completedAt: String
            let completedVisitTaskId: String
            enum CodingKeys: String, CodingKey {
                case completedAt = "completed_at"
                case completedVisitTaskId = "completed_visit_task_id"
            }
        }
        let payload = CompletePayload(
            completedAt: ISO8601DateFormatter().string(from: Date()),
            completedVisitTaskId: visitTaskId.uuidString
        )
        try await from("handyman_punch_items")
            .update(payload)
            .in("id", values: ids.map { $0.uuidString })
            .execute()
    }

    // MARK: - Bundle Custom Subitems (Phase 67H)

    /// Active subitems for a (household, property, bundle). Excludes
    /// archived rows. The reconciler appends these to the bundle
    /// parent's "What's included" notes at every bundle fire.
    func fetchBundleCustomSubitems(
        householdId: UUID,
        propertyId: UUID,
        bundleId: String
    ) async throws -> [BundleCustomSubitemRow] {
        try await from("bundle_custom_subitems")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("property_id", value: propertyId.uuidString)
            .eq("bundle_id", value: bundleId)
            .is("archived_at", value: nil)
            .order("added_at", ascending: true)
            .execute()
            .value
    }

    /// Insert a homeowner-added subitem.
    func createBundleCustomSubitem(_ insert: BundleCustomSubitemInsert) async throws -> BundleCustomSubitemRow {
        try await from("bundle_custom_subitems")
            .insert(insert, returning: .representation)
            .single()
            .execute()
            .value
    }

    /// Soft-delete. Stays in the table for audit; just disappears
    /// from "Custom additions" lists and reconciler reads.
    func archiveBundleCustomSubitem(id: UUID) async throws {
        struct ArchivePayload: Encodable {
            let archivedAt: String
            enum CodingKeys: String, CodingKey {
                case archivedAt = "archived_at"
            }
        }
        let payload = ArchivePayload(archivedAt: ISO8601DateFormatter().string(from: Date()))
        try await from("bundle_custom_subitems")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Reconciler-side: when a bundle parent task is created, attach
    /// any pending `recurrence='once'` subitems to that task by
    /// stamping their `scope_task_id`. Once attached, they stop
    /// surfacing as pending so they can't double-attach to a later
    /// bundle fire if the user creates another bundle parent before
    /// the first one completes.
    func attachOnceSubitemsToBundleTask(ids: [UUID], taskId: UUID) async throws {
        guard !ids.isEmpty else { return }
        struct Payload: Encodable {
            let scopeTaskId: String
            enum CodingKeys: String, CodingKey {
                case scopeTaskId = "scope_task_id"
            }
        }
        let payload = Payload(scopeTaskId: taskId.uuidString)
        try await from("bundle_custom_subitems")
            .update(payload)
            .in("id", values: ids.map { $0.uuidString })
            .execute()
    }

    /// Bundle-parent-completion lifecycle: when the user marks a
    /// bundle parent task complete, archive any `recurrence='once'`
    /// subitems that were attached to it. They served their purpose
    /// for that visit; future bundle fires shouldn't re-show them.
    /// Idempotent — safe to call on completion of any task; rows that
    /// don't match scope_task_id stay untouched.
    func markOnceSubitemsUsed(taskId: UUID) async throws {
        struct Payload: Encodable {
            let usedAt: String
            let archivedAt: String
            enum CodingKeys: String, CodingKey {
                case usedAt = "used_at"
                case archivedAt = "archived_at"
            }
        }
        let now = ISO8601DateFormatter().string(from: Date())
        let payload = Payload(usedAt: now, archivedAt: now)
        try await from("bundle_custom_subitems")
            .update(payload)
            .eq("scope_task_id", value: taskId.uuidString)
            .eq("recurrence", value: "once")
            .is("archived_at", value: nil)
            .execute()
    }

    // MARK: - Premier Handyman Program

    func fetchHandymanRequests(
        householdId: UUID,
        propertyId: UUID? = nil,
        limit: Int? = nil
    ) async throws -> [HandymanRequestRow] {
        let filteredQuery = if let propertyId {
            from("handyman_requests")
                .select()
                .eq("household_id", value: householdId.uuidString)
                .eq("property_id", value: propertyId.uuidString)
        } else {
            from("handyman_requests")
                .select()
                .eq("household_id", value: householdId.uuidString)
        }

        if let limit {
            return try await filteredQuery
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
        }

        return try await filteredQuery
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createHandymanRequest(_ insert: HandymanRequestInsert) async throws -> HandymanRequestRow {
        try await from("handyman_requests")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchLatestHandymanRequest(visitTaskId: UUID) async throws -> HandymanRequestRow? {
        let rows: [HandymanRequestRow] = try await from("handyman_requests")
            .select()
            .eq("visit_task_id", value: visitTaskId.uuidString)
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Lookup a handyman_request by its primary key. Used by the iOS
    /// push handler to route a propose_time / accept_time / quote_sent
    /// event to the SPECIFIC visit it concerns instead of always
    /// opening the soonest visit.
    func fetchHandymanRequest(id: UUID) async throws -> HandymanRequestRow? {
        let rows: [HandymanRequestRow] = try await from("handyman_requests")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func updateHandymanRequest(id: UUID, _ update: HandymanRequestUpdate) async throws -> HandymanRequestRow {
        try await from("handyman_requests")
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchHandymanRequestMessages(requestId: UUID) async throws -> [HandymanRequestMessageRow] {
        try await from("handyman_request_messages")
            .select()
            .eq("request_id", value: requestId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func createHandymanRequestMessage(_ insert: HandymanRequestMessageInsert) async throws -> HandymanRequestMessageRow {
        try await from("handyman_request_messages")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Phase 95 (gap #47) — Service vendor inquiries

    /// Insert a homeowner-to-service-vendor inquiry. Returns the saved
    /// row so the caller can stamp `delivery_status` after the
    /// SendGrid send finishes.
    func createServiceVendorInquiry(_ insert: ServiceVendorInquiryInsert) async throws -> ServiceVendorInquiryRow {
        try await from("service_vendor_inquiries")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    /// Outreach history scoped to a single contractor. Most-recent first.
    /// Used by `ContractorDetailView` to show "Last contacted: X days ago".
    func fetchServiceVendorInquiries(contractorId: UUID) async throws -> [ServiceVendorInquiryRow] {
        try await from("service_vendor_inquiries")
            .select()
            .eq("contractor_id", value: contractorId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Phase 73 sub-phase A: propose a visit time. Both sides (homeowner
    /// from iOS, handyman from the dispatch board's REST endpoint) call
    /// this. Stamps `proposed_visit_at`, `proposed_by_role`, walks
    /// `status` to `alternate_dates_proposed`, and appends a system
    /// message to the request thread — all atomically. Returns the
    /// updated request row.
    func proposeVisitTime(
        requestId: UUID,
        proposedAt: Date,
        proposedBy: HandymanScheduleActor,
        note: String? = nil
    ) async throws -> HandymanRequestRow {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        var params: [String: String] = [
            "p_request_id": requestId.uuidString,
            "p_proposed_at": isoFormatter.string(from: proposedAt),
            "p_proposed_by_role": proposedBy.rawValue,
        ]
        if let note {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                params["p_note"] = trimmed
            }
        }

        let data = try await HavenSupabase.client
            .rpc("propose_visit_time", params: params)
            .execute()
            .data

        return try Self.handymanRequestDecoder.decode(HandymanRequestRow.self, from: data)
    }

    /// Phase 73 sub-phase A: accept the most recent proposal on a
    /// request. Stamps `confirmed_visit_at = proposed_visit_at`, walks
    /// status to `confirmed`, appends a confirmation message to the
    /// thread. The accepting side passes its own role; the RPC doesn't
    /// enforce "you can't accept your own proposal" because the UIs
    /// gate that — server-side it's just a state write.
    func acceptVisitTime(
        requestId: UUID,
        acceptedBy: HandymanScheduleActor,
        note: String? = nil
    ) async throws -> HandymanRequestRow {
        var params: [String: String] = [
            "p_request_id": requestId.uuidString,
            "p_accepted_by_role": acceptedBy.rawValue,
        ]
        if let note {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                params["p_note"] = trimmed
            }
        }

        let data = try await HavenSupabase.client
            .rpc("accept_visit_time", params: params)
            .execute()
            .data

        return try Self.handymanRequestDecoder.decode(HandymanRequestRow.self, from: data)
    }

    /// Decoder for RPCs that return `handyman_requests` rows. Postgres
    /// stamps timestamps with microsecond precision, so we accept both
    /// fractional and plain ISO-8601 forms — same pattern as
    /// `respondToProviderQuote`.
    private static let handymanRequestDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let withFractional = ISO8601DateFormatter()
            withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            for formatter in [withFractional, plain] {
                if let date = formatter.date(from: str) {
                    return date
                }
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(str)"
            )
        }
        return decoder
    }()

    func fetchHandymanPortalSession(visitTaskId: UUID) async throws -> HandymanPortalSessionRow? {
        let rows: [HandymanPortalSessionRow] = try await from("handyman_portal_sessions")
            .select()
            .eq("visit_task_id", value: visitTaskId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func createHandymanPortalSession(_ insert: HandymanPortalSessionInsert) async throws -> HandymanPortalSessionRow {
        try await from("handyman_portal_sessions")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateHandymanPortalSession(id: UUID, _ update: HandymanPortalSessionUpdate) async throws -> HandymanPortalSessionRow {
        try await from("handyman_portal_sessions")
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    /// Phase 73 sub-phase E: homeowner-side fetch for the after-visit
    /// report by visit_task_id. The technician's writes from the field
    /// PWA land in `handyman_visit_reports.visit_task_id`, so the iOS
    /// `HandymanVisitReportView` reads via this path. Returns the most
    /// recent report (the field PWA only writes one per portal session
    /// but a request that's been re-opened could have multiple).
    func fetchHandymanVisitReportByVisitTask(visitTaskId: UUID) async throws -> HandymanVisitReportRow? {
        let rows: [HandymanVisitReportRow] = try await from("handyman_visit_reports")
            .select()
            .eq("visit_task_id", value: visitTaskId.uuidString)
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchHandymanVisitReport(portalSessionId: UUID) async throws -> HandymanVisitReportRow? {
        let rows: [HandymanVisitReportRow] = try await from("handyman_visit_reports")
            .select()
            .eq("portal_session_id", value: portalSessionId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func createHandymanVisitReport(_ insert: HandymanVisitReportInsert) async throws -> HandymanVisitReportRow {
        try await from("handyman_visit_reports")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateHandymanVisitReport(id: UUID, _ update: HandymanVisitReportUpdate) async throws -> HandymanVisitReportRow {
        try await from("handyman_visit_reports")
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchProviderQuotes(requestId: UUID) async throws -> [ProviderQuoteRow] {
        try await from("provider_quotes")
            .select()
            .eq("request_id", value: requestId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    /// Fetch every provider quote tied to this property — used by the
    /// homeowner Handyman tab to surface a "Quotes for your home"
    /// section regardless of whether a quote was attached to a
    /// specific visit (request_id) or stood alone for the home.
    func fetchProviderQuotesForProperty(propertyId: UUID) async throws -> [ProviderQuoteRow] {
        try await from("provider_quotes")
            .select()
            .eq("property_id", value: propertyId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    /// Fetch a single provider quote by id. Used by the push handler
    /// when a `handyman_quote_sent` event lands carrying a quote_id —
    /// lets us deep-link straight into the review sheet without
    /// having to find it via request_id matching.
    func fetchProviderQuote(id: UUID) async throws -> ProviderQuoteRow? {
        let rows: [ProviderQuoteRow] = try await from("provider_quotes")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Phase 75h: per-line-item Q&A comments. Returns every comment
    /// on the quote (provider replies + homeowner questions),
    /// ordered oldest first so the UI can render threads top-down.
    func fetchProviderQuoteComments(quoteId: UUID) async throws -> [ProviderQuoteCommentRow] {
        try await from("provider_quote_comments")
            .select()
            .eq("quote_id", value: quoteId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// Insert a homeowner-authored question/comment. The provider side
    /// inserts via the handyman-provider edge function (service role)
    /// because RLS only grants insert to `author_role = 'homeowner'`.
    func createProviderQuoteComment(_ insert: ProviderQuoteCommentInsert) async throws -> ProviderQuoteCommentRow {
        try await from("provider_quote_comments")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    /// Secure homeowner-side quote collaboration path. Routed through the
    /// `respond_to_provider_quote` SECURITY DEFINER RPC so the app can mark a
    /// quote as viewed / approved / declined without opening broad direct
    /// UPDATE rights on `provider_quotes`.
    func respondToProviderQuote(
        id: UUID,
        status: ProviderQuoteStatus,
        homeownerNote: String? = nil
    ) async throws -> ProviderQuoteRow {
        var params: [String: String] = [
            "p_quote_id": id.uuidString,
            "p_response_status": status.rawValue,
        ]
        if let homeownerNote {
            let trimmed = homeownerNote.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                params["p_homeowner_note"] = trimmed
            }
        }

        let data = try await HavenSupabase.client
            .rpc("respond_to_provider_quote", params: params)
            .execute()
            .data

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let formatters: [ISO8601DateFormatter] = {
                let withFractional = ISO8601DateFormatter()
                withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let plain = ISO8601DateFormatter()
                plain.formatOptions = [.withInternetDateTime]
                return [withFractional, plain]
            }()

            for formatter in formatters {
                if let date = formatter.date(from: str) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(str)"
            )
        }

        return try decoder.decode(ProviderQuoteRow.self, from: data)
    }

    /// Phase 73 sub-phase B: homeowner edits line items + sends back as
    /// a counter-offer. Calls `counter_provider_quote` which clones
    /// the parent into a new row with `parent_quote_id` set + status
    /// `countered_by_homeowner`, marks the parent `superseded`, and
    /// appends a system event to the request thread. Returns the
    /// freshly-created counter quote.
    func counterProviderQuote(
        id: UUID,
        revisedLineItems: [ProviderQuoteLineItem],
        scopeNotesOverride: String? = nil,
        note: String? = nil
    ) async throws -> ProviderQuoteRow {
        // Re-encode the line items as JSON string. The RPC expects a
        // jsonb array — we send the camelCase shape that matches what
        // the provider PWA writes today (see line-item key fix in
        // migration 20260908).
        let encoder = JSONEncoder()
        let data = try encoder.encode(revisedLineItems)
        let lineItemsString = String(data: data, encoding: .utf8) ?? "[]"

        var params: [String: String] = [
            "p_quote_id": id.uuidString,
            "p_revised_line_items": lineItemsString,
        ]
        if let scopeNotesOverride {
            let trimmed = scopeNotesOverride.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                params["p_scope_notes_override"] = trimmed
            }
        }
        if let note {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                params["p_note"] = trimmed
            }
        }

        let dataResponse = try await HavenSupabase.client
            .rpc("counter_provider_quote", params: params)
            .execute()
            .data

        return try Self.providerQuoteDecoder.decode(ProviderQuoteRow.self, from: dataResponse)
    }

    /// Phase 73 sub-phase B: homeowner signs + approves the quote in
    /// one shot. Calls `sign_provider_quote` which walks status to
    /// `approved`, stamps `signed_at = now()` + `signed_name`, and
    /// appends a `kind = "quote_signed"` event to the request thread.
    func signProviderQuote(
        id: UUID,
        signedName: String,
        homeownerNote: String? = nil
    ) async throws -> ProviderQuoteRow {
        var params: [String: String] = [
            "p_quote_id": id.uuidString,
            "p_signed_name": signedName,
        ]
        if let homeownerNote {
            let trimmed = homeownerNote.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                params["p_homeowner_note"] = trimmed
            }
        }

        let data = try await HavenSupabase.client
            .rpc("sign_provider_quote", params: params)
            .execute()
            .data

        return try Self.providerQuoteDecoder.decode(ProviderQuoteRow.self, from: data)
    }

    /// Decoder for RPCs that return a single `provider_quotes` row.
    /// Postgres timestamps may carry fractional seconds; accept both.
    private static let providerQuoteDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let withFractional = ISO8601DateFormatter()
            withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            for formatter in [withFractional, plain] {
                if let date = formatter.date(from: str) {
                    return date
                }
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(str)"
            )
        }
        return decoder
    }()

    func fetchProviderSavedQuoteItems(workspaceId: UUID) async throws -> [ProviderSavedQuoteItemRow] {
        try await from("provider_saved_quote_items")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .order("sort_order", ascending: true)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // Phase 55.3: The Phase 54D household_cadences CRUD block and
    // the Phase 55.2.9 cadence → routine write bridge were removed.
    // Every writer now lives against `routines` directly via the
    // block below. The `household_cadences` table stays in place on
    // Supabase for rollback safety; a future Phase 55.4 drops it.

    // MARK: - Home Assessments (Phase 84.5)

    /// Fetch the most recent active assessment for a property. RLS scopes
    /// to the current user's household. Used by the Dashboard pending card
    /// and the post-visit `AssessmentReviewView`.
    func fetchActiveHomeAssessment(propertyId: UUID) async throws -> HomeAssessmentRow? {
        let rows: [HomeAssessmentRow] = try await from("home_assessments")
            .select()
            .eq("property_id", value: propertyId.uuidString)
            .not("status", operator: .in, value: "(completed,cancelled)")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Fetch the most recent ingested assessment so AssessmentReviewView
    /// can fire once on first launch after ingestion.
    func fetchLastIngestedAssessment(householdId: UUID) async throws -> HomeAssessmentRow? {
        let rows: [HomeAssessmentRow] = try await from("home_assessments")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .not("ingested_at", operator: .is, value: "null")
            .order("ingested_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Fetch all recommended tasks for an assessment, ordered with
    /// urgent items first. Used by AssessmentReviewView and the admin
    /// portal Pending Tasks dispatch view.
    func fetchAssessmentRecommendedTasks(assessmentId: UUID) async throws -> [AssessmentRecommendedTaskRow] {
        return try await from("assessment_recommended_tasks")
            .select()
            .eq("assessment_id", value: assessmentId.uuidString)
            .order("urgency", ascending: true)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    // MARK: - Routines (Phase 55)
    //
    // Unified recurring-event primitive replacing both household_cadences
    // and standing_appointments. The old methods above remain during
    // Section 55.1 so legacy views keep working; Section 55.2 repoints
    // every reader and the old tables become read-only mirrors.

    /// Phase 55: Fetches every active routine for a household, sorted by
    /// label. Archived rows (archived_at IS NOT NULL) are excluded server-
    /// side to match the Phase 51/54D pattern.
    func fetchRoutines(householdId: UUID) async throws -> [RoutineRow] {
        try await from("routines")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .is("archived_at", value: nil)
            .order("label", ascending: true)
            .execute()
            .value
    }

    func fetchRoutine(id: UUID) async throws -> RoutineRow {
        try await from("routines")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func createRoutine(_ insert: RoutineInsert) async throws -> RoutineRow {
        var insert = insert
        if insert.serviceKey == nil {
            insert.serviceKey = ServiceLibrary.serviceKey(for: insert)
        }

        return try await from("routines")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateRoutine(id: UUID, _ update: RoutineUpdate) async throws -> RoutineRow {
        try await from("routines")
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    /// Phase 55: Soft-delete a routine via archived_at. The list
    /// fetch filters on archived_at IS NULL so the row disappears
    /// everywhere without losing history or cascading to visits.
    func archiveRoutine(id: UUID) async throws {
        var update = RoutineUpdate()
        update.archivedAt = Date()
        _ = try await updateRoutine(id: id, update)
    }

    /// Phase 55: Hard delete. Use when the user explicitly wants the
    /// routine gone — cascades to routine_visits. Prefer archiveRoutine
    /// for user-initiated removals from the list UI.
    func deleteRoutine(id: UUID) async throws {
        try await from("routines")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 55: Per-visit instances attached to a routine. Mirrors
    /// `fetchStandingAppointmentVisits` — returns every visit for a
    /// routine, ordered by scheduled_date descending so the most recent
    /// is first.
    func fetchRoutineVisits(routineId: UUID) async throws -> [RoutineVisitRow] {
        try await from("routine_visits")
            .select()
            .eq("routine_id", value: routineId.uuidString)
            .order("scheduled_date", ascending: false)
            .execute()
            .value
    }

    // Phase 55.3: The 55.2.9 cadence → routine write bridge was
    // removed alongside the legacy CadenceEditSheet. Native writers
    // (RoutineEditSheet) go straight at `routines` via
    // `createRoutine` / `updateRoutine` above.

    // MARK: - Phase 85: Chez Activity Log

    /// Fetch the most-recent chez_activity_log rows for a household.
    /// Default `daysBack: 7` powers the Dashboard "This week with Chez"
    /// card; pass a larger window for the full activity history view.
    /// Set `dashboardOnly` to filter to rows flagged for surfacing.
    func fetchChezActivity(
        householdId: UUID,
        daysBack: Int = 7,
        dashboardOnly: Bool = false,
        limit: Int = 50
    ) async throws -> [ChezActivityLogRow] {
        let since = ISO8601DateFormatter().string(
            from: Date().addingTimeInterval(-Double(daysBack) * 24 * 60 * 60)
        )
        var query = from("chez_activity_log")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .gte("occurred_at", value: since)
        if dashboardOnly {
            query = query.eq("surface_on_dashboard", value: true)
        }
        return try await query
            .order("occurred_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Phase 85: latest unviewed monthly summary for a household. Returns
    /// nil if the most recent summary has been viewed already (the
    /// dashboard card auto-dismisses).
    func fetchLatestUnviewedMonthlySummary(
        householdId: UUID
    ) async throws -> ChezMonthlySummaryRow? {
        let rows: [ChezMonthlySummaryRow] = try await from("chez_monthly_summaries")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .is("viewed_at", value: nil)
            .order("period_start", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Marks a monthly summary as viewed. Idempotent.
    func markMonthlySummaryViewed(id: UUID) async throws {
        struct ViewedUpdate: Encodable {
            let viewed_at: String
        }
        _ = try await from("chez_monthly_summaries")
            .update(ViewedUpdate(viewed_at: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Phase 85: Handyman trust profile + reviews

    /// Fetch a handyman's trust profile by member ID. Reads the
    /// `handyman_member_stats` view which joins provider_workspace_members
    /// with aggregate review counts + avg rating.
    func fetchHandymanTrustProfile(memberId: UUID) async throws -> HandymanTrustProfile? {
        let rows: [HandymanTrustProfile] = try await from("handyman_member_stats")
            .select()
            .eq("handyman_member_id", value: memberId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Submit a homeowner's post-visit review. Caller is responsible
    /// for ensuring `homeownerId` matches `auth.uid()` (the RLS policy
    /// enforces this server-side regardless).
    func submitHandymanReview(
        handymanMemberId: UUID,
        assessmentId: UUID?,
        homeownerId: UUID,
        householdId: UUID,
        rating: Int,
        reviewText: String?,
        tags: [String] = []
    ) async throws {
        struct ReviewInsert: Encodable {
            let handyman_member_id: String
            let assessment_id: String?
            let homeowner_id: String
            let household_id: String
            let rating: Int
            let review_text: String?
            let tags: [String]
        }
        let insert = ReviewInsert(
            handyman_member_id: handymanMemberId.uuidString,
            assessment_id: assessmentId?.uuidString,
            homeowner_id: homeownerId.uuidString,
            household_id: householdId.uuidString,
            rating: max(1, min(5, rating)),
            review_text: (reviewText?.isEmpty == false) ? reviewText : nil,
            tags: tags
        )
        _ = try await from("handyman_reviews")
            .insert(insert)
            .execute()
    }

    // MARK: - Phase 66: Routines as first-class Services

    /// Phase 66: Fetch routines filtered by scope + setup state. Used by
    /// the Maintenance tab's Your Services section (scope='property',
    /// setupState IN active/pending_vendor) and the Vehicles section
    /// (scope='vehicle').
    func fetchRoutinesByScope(
        householdId: UUID,
        scope: RoutineScope,
        includingPaused: Bool = true
    ) async throws -> [RoutineRow] {
        var query = from("routines")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("scope", value: scope.rawValue)
            .is("archived_at", value: nil)

        if !includingPaused {
            query = query.neq("setup_state", value: "archived")
                .is("is_paused", value: false)
        }

        return try await query.order("label", ascending: true).execute().value
    }

    /// Phase 66: Fetch the singleton handyman routine for a property,
    /// or nil if none exists yet. Day1TaskCurator + the Next Handyman
    /// Visit section both call `fetchOrCreateHandymanRoutine` to lazy-
    /// create on first access.
    func fetchHandymanRoutine(
        householdId: UUID,
        propertyId: UUID
    ) async throws -> RoutineRow? {
        let rows: [RoutineRow] = try await from("routines")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("property_id", value: propertyId.uuidString)
            .eq("routine_kind", value: RoutineKind.handymanRecurring.rawValue)
            .eq("scope", value: RoutineScope.property.rawValue)
            .is("archived_at", value: nil)
            .execute()
            .value
        return rows.first
    }

    /// Phase 66: Return the existing handyman routine for a property, or
    /// lazy-create a new one with `setup_state = 'active'`. Pre-filled
    /// with the household's `preferredHandymanContractorId` when set so
    /// the card renders with a vendor logo + "Schedule visit" CTA out of
    /// the gate. Cadence is on-demand (uses customDays with a large
    /// interval so `isActive(on:)` never fires — the visit happens when
    /// enough work has accumulated, not on a calendar).
    func fetchOrCreateHandymanRoutine(
        householdId: UUID,
        propertyId: UUID,
        preferredHandymanContractorId: UUID? = nil
    ) async throws -> RoutineRow {
        if let existing = try await fetchHandymanRoutine(
            householdId: householdId, propertyId: propertyId
        ) {
            return existing
        }

        var insert = RoutineInsert(
            householdId: householdId,
            propertyId: propertyId,
            label: "Next handyman visit",
            routineKind: RoutineKind.handymanRecurring.rawValue,
            cadenceType: RoutineCadenceType.customDays.rawValue
        )
        insert.cadenceIntervalDays = 9999  // Effectively on-demand
        insert.vendorId = preferredHandymanContractorId
        insert.icon = "wrench.adjustable.fill"
        insert.setupState = "active"
        return try await createRoutine(insert)
    }

    /// Phase 66: Routines in the Your Services list where the user wants
    /// Haven to find them a vendor. Rendered with a "Chez helping" tag.
    func fetchPendingVendorRoutines(
        householdId: UUID,
        propertyId: UUID
    ) async throws -> [RoutineRow] {
        try await from("routines")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("property_id", value: propertyId.uuidString)
            .eq("setup_state", value: "pending_vendor")
            .is("archived_at", value: nil)
            .order("label", ascending: true)
            .execute()
            .value
    }

    /// Phase 66: Fetch the active routine for a specific vehicle, if any.
    /// Uses the partial unique index so we know there's at most one row.
    func fetchVehicleRoutine(vehicleId: UUID) async throws -> RoutineRow? {
        let rows: [RoutineRow] = try await from("routines")
            .select()
            .eq("vehicle_id", value: vehicleId.uuidString)
            .eq("scope", value: RoutineScope.vehicle.rawValue)
            .is("archived_at", value: nil)
            .in("setup_state", values: ["draft", "pending_vendor", "active", "paused"])
            .execute()
            .value
        return rows.first
    }

    /// Phase 66: All vehicle routines in the household. Used by the
    /// Maintenance tab's Vehicles section to render one summary card per
    /// vehicle (vehicles without a routine show an empty-state card).
    func fetchVehicleRoutines(householdId: UUID) async throws -> [RoutineRow] {
        try await fetchRoutinesByScope(householdId: householdId, scope: .vehicle)
    }

    /// Phase 66: Create a vehicle-scoped routine. Defaults to shop-managed
    /// mode since HNW users typically drop the car at the dealer and want
    /// the individual service items to hide under the shop.
    func createVehicleRoutine(
        vehicle: VehicleRow,
        householdId: UUID,
        shopContractorId: UUID?,
        programMode: RoutineProgramMode = .shopManaged,
        notes: String? = nil
    ) async throws -> RoutineRow {
        let label: String = {
            let make = vehicle.make ?? "Vehicle"
            let model = vehicle.model ?? ""
            return "\(make) \(model) service".trimmingCharacters(in: .whitespaces)
        }()
        var insert = RoutineInsert(
            householdId: householdId,
            propertyId: nil,
            label: label,
            routineKind: RoutineKind.otherService.rawValue,
            cadenceType: RoutineCadenceType.customDays.rawValue
        )
        insert.cadenceIntervalDays = 9999  // Vehicle cadence is mileage-driven
        insert.vendorId = shopContractorId
        insert.icon = "car.fill"
        insert.scope = RoutineScope.vehicle.rawValue
        insert.vehicleId = vehicle.id
        insert.programMode = programMode.rawValue
        insert.setupState = shopContractorId != nil ? "active" : "pending_vendor"
        insert.notes = notes
        return try await createRoutine(insert)
    }

    // MARK: - Phase 66: Routine visits write path

    /// Phase 66: Create a routine_visits row with the new visit_state
    /// machine. Use `visitState: "scheduled"` when the user confirms a
    /// date, "planned" for a bucket that exists but hasn't been scheduled.
    func createRoutineVisit(_ insert: RoutineVisitInsert) async throws -> RoutineVisitRow {
        var insert = insert
        if insert.visitTypeKey == nil,
           let routine = try? await fetchRoutine(id: insert.routineId) {
            insert.visitTypeKey = ServiceLibrary.visitTypeKey(
                for: routine,
                scheduledDate: insert.scheduledDate,
                notes: insert.notes
            )
        }

        return try await from("routine_visits")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateRoutineVisit(id: UUID, _ update: RoutineVisitUpdate) async throws -> RoutineVisitRow {
        try await from("routine_visits")
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    /// Phase 66: Fetch active visits (planned/scheduled/in_progress) for
    /// a specific routine. Powers the RoutineDetailView's upcoming-visits
    /// list and the Maintenance tab's "Upcoming Scheduled" section.
    func fetchActiveRoutineVisits(routineId: UUID) async throws -> [RoutineVisitRow] {
        try await from("routine_visits")
            .select()
            .eq("routine_id", value: routineId.uuidString)
            .in("visit_state", values: ["planned", "scheduled", "in_progress"])
            .order("scheduled_date", ascending: true)
            .execute()
            .value
    }

    /// Phase 66: Fetch every scheduled-or-in-progress visit across all
    /// routines for a household. Powers the "Upcoming Scheduled" section
    /// on the Maintenance tab in one DB round-trip instead of N+1.
    func fetchScheduledVisitsForHousehold(householdId: UUID) async throws -> [RoutineVisitRow] {
        // routine_visits doesn't carry household_id directly, so join via
        // routines. Supabase PostgREST embeds: select routine_visits with
        // routines joined, then filter on routines.household_id.
        struct VisitWithRoutine: Codable {
            let id: UUID
            let routineId: UUID
            let scheduledDate: String
            let status: String
            let visitState: String?
            let targetWindowStart: String?
            let targetWindowEnd: String?
            let actualCostCents: Int?
            let notes: String?
            let confirmedAt: Date?
            let confirmedBy: String?
            let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case id, status, notes
                case routineId = "routine_id"
                case scheduledDate = "scheduled_date"
                case visitState = "visit_state"
                case targetWindowStart = "target_window_start"
                case targetWindowEnd = "target_window_end"
                case actualCostCents = "actual_cost_cents"
                case confirmedAt = "confirmed_at"
                case confirmedBy = "confirmed_by"
                case createdAt = "created_at"
            }
        }
        // Phase 66: route through the existing active-visits path per
        // routine; household-wide aggregation happens client-side because
        // RLS + PostgREST embedded filtering is finicky with the routines
        // FK. At ~5-20 routines per household this is fine.
        let routines = try await fetchRoutines(householdId: householdId)
        var all: [RoutineVisitRow] = []
        for routine in routines {
            let visits = (try? await fetchActiveRoutineVisits(routineId: routine.id)) ?? []
            all.append(contentsOf: visits)
        }
        return all.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    // MARK: - Phase 66: Task ↔ routine linking

    /// Phase 66: Fetch every task whose parent_routine_id = the given
    /// routine. Used by RoutineDetailView and NextHandymanVisitSection
    /// to render the "What's included" list. Filters archived.
    func fetchTasksForRoutine(routineId: UUID) async throws -> [MaintenanceTaskDBRow] {
        try await from("maintenance_tasks")
            .select()
            .eq("parent_routine_id", value: routineId.uuidString)
            .or("is_archived.is.null,is_archived.eq.false")
            .execute()
            .value
    }

    /// Phase 66: Promote a DIY-default or `.either` task to the handyman
    /// routine. Used by the routing picker's "Add to handyman list"
    /// action. Creates the handyman routine lazily on first call.
    func assignTaskToHandymanRoutine(
        task: MaintenanceTaskDBRow,
        preferredHandymanContractorId: UUID? = nil
    ) async throws -> RoutineRow {
        guard let propertyId = task.propertyId else {
            throw NSError(
                domain: "DatabaseService",
                code: 66,
                userInfo: [NSLocalizedDescriptionKey: "Task has no property. Can't route to handyman"]
            )
        }
        let routine = try await fetchOrCreateHandymanRoutine(
            householdId: task.householdId,
            propertyId: propertyId,
            preferredHandymanContractorId: preferredHandymanContractorId
        )
        var update = MaintenanceTaskUpdate()
        update.parentRoutineId = routine.id
        update.assignedRoute = "handyman"
        _ = try await updateMaintenanceTask(id: task.id, update)
        return routine
    }

    // MARK: - Dismissed Recommendations (Phase 54C)

    /// Phase 54C: Returns the set of template ids the household has
    /// explicitly tapped "Hide" on in the Recommended for your home
    /// view. The set drives the filter that keeps dismissed items out
    /// of the browsing surface.
    func fetchDismissedRecommendations(householdId: UUID) async throws -> Set<String> {
        struct Row: Decodable {
            let templateId: String
            enum CodingKeys: String, CodingKey { case templateId = "template_id" }
        }
        let rows: [Row] = try await from("dismissed_recommendations")
            .select("template_id")
            .eq("household_id", value: householdId.uuidString)
            .execute()
            .value
        return Set(rows.map(\.templateId))
    }

    func dismissRecommendation(householdId: UUID, templateId: String, userId: UUID?) async throws {
        struct InsertPayload: Encodable {
            let householdId: String
            let templateId: String
            let dismissedByUserId: String?
            enum CodingKeys: String, CodingKey {
                case householdId = "household_id"
                case templateId = "template_id"
                case dismissedByUserId = "dismissed_by_user_id"
            }
        }
        let payload = InsertPayload(
            householdId: householdId.uuidString,
            templateId: templateId,
            dismissedByUserId: userId?.uuidString
        )
        try await from("dismissed_recommendations")
            .upsert(payload, onConflict: "household_id,template_id")
            .execute()
    }

    func resetDismissedRecommendations(householdId: UUID) async throws {
        try await from("dismissed_recommendations")
            .delete()
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    /// Phase 80 (Tom's prevention pass): per-template restore for the
    /// Task Library surface. The legacy `resetDismissedRecommendations`
    /// is bulk-only; users need granular control to bring back one
    /// recommendation at a time.
    func restoreRecommendation(householdId: UUID, templateKey: String) async throws {
        try await from("dismissed_recommendations")
            .delete()
            .eq("household_id", value: householdId.uuidString)
            .eq("template_id", value: templateKey)
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
            print("[Push] WARNING: Upsert returned 0 rows. RLS may be blocking the insert for user \(userId)")
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

    // MARK: - Dismissed Templates (Phase 80)

    func fetchDismissedTemplates(propertyId: UUID) async throws -> [DismissedTemplateRow] {
        try await from("dismissed_templates")
            .select()
            .eq("property_id", value: propertyId.uuidString)
            .execute()
            .value
    }

    /// Upsert by (property_id, template_key). Idempotent — calling twice
    /// on the same template no-ops the second time.
    func dismissTemplate(
        propertyId: UUID,
        householdId: UUID,
        templateKey: String,
        reason: String = "not_applicable"
    ) async throws {
        let insert = DismissedTemplateInsert(
            propertyId: propertyId,
            householdId: householdId,
            templateKey: templateKey,
            reason: reason
        )
        try await from("dismissed_templates")
            .upsert(insert, onConflict: "property_id,template_key")
            .execute()
    }

    func restoreTemplate(propertyId: UUID, templateKey: String) async throws {
        try await from("dismissed_templates")
            .delete()
            .eq("property_id", value: propertyId.uuidString)
            .eq("template_key", value: templateKey)
            .execute()
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

    /// Round 2 (May 2026): "Circle back" / Remind-me-later snooze for
    /// the Vendor Coverage Sheet. Same underlying table as the
    /// permanent dismissal but with `snoozed_until` set so the row
    /// resurfaces when the timestamp passes. Delete-then-insert so
    /// toggling between Not-applicable and Remind-me-later keeps one
    /// row per (household, category) instead of accumulating duplicates.
    func snoozeCategory(householdId: UUID, category: String, until: Date) async throws {
        try await from("dismissed_categories")
            .delete()
            .eq("household_id", value: householdId.uuidString)
            .eq("category", value: category)
            .execute()
        let insert = DismissedCategoryInsert(
            householdId: householdId,
            category: category,
            snoozedUntil: until
        )
        try await from("dismissed_categories")
            .insert(insert)
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

    /// Check if a user with this email already has a Haven account.
    ///
    /// Uses the `check_user_exists_by_email` SECURITY DEFINER function so the
    /// lookup works across households (the caller's RLS scope only covers their
    /// own household, but invitees may be in a different household or have no
    /// household at all).
    func checkExistingUser(email: String) async throws -> UserRow? {
        struct RpcResult: Decodable {
            let exists: Bool
            let userId: UUID?
            let householdId: UUID?

            enum CodingKeys: String, CodingKey {
                case exists
                case userId = "user_id"
                case householdId = "household_id"
            }
        }

        let data = try await HavenSupabase.client
            .rpc("check_user_exists_by_email", params: ["target_email": email.lowercased()])
            .execute()
            .data

        let decoded = try JSONDecoder().decode(RpcResult.self, from: data)
        guard decoded.exists, let userId = decoded.userId else { return nil }

        // Construct a minimal UserRow from the RPC result. Callers only use
        // `id` and `householdId` from this lookup, so the other fields are
        // set to safe defaults.
        return UserRow(
            id: userId,
            householdId: decoded.householdId,
            email: email.lowercased(),
            fullName: nil,
            role: "member",
            createdAt: nil
        )
    }

    /// Uses the `check_pending_invitation_by_email` SECURITY DEFINER function
    /// so the lookup works for newly authenticated users who don't have a
    /// public.users row yet (PostgREST's context resolution would otherwise
    /// throw "permission denied for table users").
    func checkPendingInvitation(email: String) async throws -> HouseholdInvitationRow? {
        struct RpcResult: Decodable {
            let found: Bool
        }

        let data = try await HavenSupabase.client
            .rpc("check_pending_invitation_by_email", params: ["target_email": email.lowercased()])
            .execute()
            .data

        // Quick check: if not found, return nil without full decode
        let check = try JSONDecoder().decode(RpcResult.self, from: data)
        guard check.found else { return nil }

        // Decode the full invitation row from the RPC result
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            // Try ISO 8601 with fractional seconds first, then without
            let formatters: [ISO8601DateFormatter] = {
                let withFrac = ISO8601DateFormatter()
                withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let plain = ISO8601DateFormatter()
                plain.formatOptions = [.withInternetDateTime]
                return [withFrac, plain]
            }()
            for formatter in formatters {
                if let date = formatter.date(from: str) { return date }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        // The RPC wraps the row in the same JSON shape as a direct table query,
        // plus a "found" key. Decode into a flexible container and extract the row.
        // The RPC returns the same column names as a direct table query,
        // plus a "found" key. HouseholdInvitationRow's CodingKeys already
        // map snake_case columns, so decode directly with an extra "found" wrapper.
        struct FoundWrapper: Decodable {
            let found: Bool
            let invitation: HouseholdInvitationRow

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                found = try container.decode(Bool.self, forKey: .found)
                // Decode the invitation from the same flat container
                invitation = try HouseholdInvitationRow(from: decoder)
            }

            enum CodingKeys: String, CodingKey {
                case found
            }
        }

        let result = try decoder.decode(FoundWrapper.self, from: data)
        return result.invitation
    }

    /// Accept an invitation — flip the invitation row to accepted and,
    /// when the invitation carries a `family_member_id`, stamp the
    /// accepting user onto that family_member row so their name, role,
    /// and task assignments all resolve back to the record the
    /// homeowner already typed in. Without this link the accepting
    /// user shows up as "Member" in task assignment and the dashboard
    /// greeting falls back to the household's Primary Client (i.e.
    /// the inviter's name).
    ///
    /// The family_member update is done second and tolerates failure —
    /// if RLS or a row mismatch blocks the write, the invitation is
    /// still accepted and the user still joins the household; they'll
    /// just need a manual profile link later. Failing the whole accept
    /// over a secondary write would be worse than a recoverable profile
    /// gap.
    func acceptInvitation(
        invitationId: UUID,
        userId: UUID,
        familyMemberId: UUID? = nil
    ) async throws {
        try await from("household_invitations")
            .update([
                "status": "accepted",
                "accepted_at": ISO8601DateFormatter().string(from: Date()),
                "accepted_by": userId.uuidString,
            ])
            .eq("id", value: invitationId.uuidString)
            .execute()

        if let memberId = familyMemberId {
            do {
                var update = FamilyMemberUpdate()
                update.linkedUserId = userId
                _ = try await updateFamilyMember(id: memberId, update)
            } catch {
                print("[Invites] acceptInvitation: family_member link write failed (invitation still accepted): \(error)")
            }
        }
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

    /// Phase 59: fetch service contracts scoped to a specific contractor —
    /// used by ContractorDetailView to surface the standing service
    /// relationships (HVAC plan, monitoring subscription, snow plow
    /// contract, salt delivery subscription) that define the vendor.
    func fetchServiceContracts(contractorId: UUID) async throws -> [ServiceContractRow] {
        try await from("service_contracts")
            .select()
            .eq("contractor_id", value: contractorId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
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
        /// Phase 80 — Chez Concierge: links a `chez_reply_*` inbox item back to
        /// its parent `chez_requests` row so tapping the inbox item deep-links
        /// to the correct request thread.
        let relatedChezRequestId: UUID?
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
            case relatedChezRequestId = "related_chez_request_id"
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
            relatedChezRequestId = try? c.decodeIfPresent(UUID.self, forKey: .relatedChezRequestId)
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
            // Wave Y2: contractor-side actions that mirror into the
            // homeowner's inbox so cross-app activity is visible.
            case "handyman_quote_received": return "doc.text.magnifyingglass"
            case "invoice_received": return "doc.plaintext"
            case "chez_reply_action_needed",
                 "chez_reply_informational",
                 "chez_status_change":
                return "person.fill.questionmark"
            default: return "envelope.fill"
            }
        }

        /// Phase 80 — true when the item is a Chez reply / status change
        /// that should deep-link into `ChezRequestDetailView` rather than
        /// rendering the standard inbox detail chrome.
        var isChezReply: Bool {
            type.hasPrefix("chez_reply_") || type == "chez_status_change"
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
        /// Phase 80 — Chez Concierge: belt-and-suspenders fallback for the
        /// `inbox_items.related_chez_request_id` column. The Edge Function
        /// stamps both, but if a row predates the column add we still
        /// fall back to the metadata blob.
        let chezRequestIdString: String?
        /// Wave Y2 — provider quote / invoice deep-link IDs. Stamped by
        /// the `handyman-provider` Edge Function when it ad-hoc inserts
        /// a `handyman_quote_received` / `invoice_received` mirror row
        /// for the homeowner's inbox.
        let quoteIdString: String?
        let invoiceIdString: String?
        let providerRequestIdString: String?
        /// Phase 101 — quote + warranty intelligence stamped by receive-email.
        let suggestedProject: SuggestedProjectInfo?
        let fairMarket: FairMarketHint?
        let warranty: WarrantyHint?
        let specialtySystemSuggestion: InboxSpecialtySuggestion?

        struct SuggestedProjectInfo: Decodable {
            let id: String?
            let name: String?
            let signal: String?
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                id = try? c.decodeIfPresent(String.self, forKey: .id)
                name = try? c.decodeIfPresent(String.self, forKey: .name)
                signal = try? c.decodeIfPresent(String.self, forKey: .signal)
            }
            enum CodingKeys: String, CodingKey { case id, name, signal }
        }

        struct FairMarketHint: Decodable {
            let lowCents: Int?
            let highCents: Int?
            let sampleSize: Int?
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                lowCents = try? c.decodeIfPresent(Int.self, forKey: .lowCents)
                highCents = try? c.decodeIfPresent(Int.self, forKey: .highCents)
                sampleSize = try? c.decodeIfPresent(Int.self, forKey: .sampleSize)
            }
            enum CodingKeys: String, CodingKey {
                case lowCents = "low_cents"
                case highCents = "high_cents"
                case sampleSize = "sample_size"
            }
        }

        struct WarrantyHint: Decodable {
            let provider: String?
            let coveredItem: String?
            let warrantyType: String?
            let startDate: String?
            let endDate: String?
            let matchedSystemId: String?
            let matchedSystemName: String?
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                provider = try? c.decodeIfPresent(String.self, forKey: .provider)
                coveredItem = try? c.decodeIfPresent(String.self, forKey: .coveredItem)
                warrantyType = try? c.decodeIfPresent(String.self, forKey: .warrantyType)
                startDate = try? c.decodeIfPresent(String.self, forKey: .startDate)
                endDate = try? c.decodeIfPresent(String.self, forKey: .endDate)
                matchedSystemId = try? c.decodeIfPresent(String.self, forKey: .matchedSystemId)
                matchedSystemName = try? c.decodeIfPresent(String.self, forKey: .matchedSystemName)
            }
            enum CodingKeys: String, CodingKey {
                case provider
                case coveredItem = "covered_item"
                case warrantyType = "warranty_type"
                case startDate = "start_date"
                case endDate = "end_date"
                case matchedSystemId = "matched_system_id"
                case matchedSystemName = "matched_system_name"
            }
        }

        struct InboxSpecialtySuggestion: Decodable {
            let category: String?
            let displayName: String?
            let evidence: String?
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                category = try? c.decodeIfPresent(String.self, forKey: .category)
                displayName = try? c.decodeIfPresent(String.self, forKey: .displayName)
                evidence = try? c.decodeIfPresent(String.self, forKey: .evidence)
            }
            enum CodingKeys: String, CodingKey {
                case category, evidence
                case displayName = "display_name"
            }
        }

        enum CodingKeys: String, CodingKey {
            case subject, classification, warranty
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
            case chezRequestIdString = "chez_request_id"
            case quoteIdString = "quote_id"
            case invoiceIdString = "invoice_id"
            case providerRequestIdString = "request_id"
            case suggestedProject = "suggested_project"
            case fairMarket = "fair_market"
            case specialtySystemSuggestion = "specialty_system_suggestion"
        }

        var chezRequestIdAsUUID: UUID? {
            guard let raw = chezRequestIdString else { return nil }
            return UUID(uuidString: raw)
        }

        var quoteIdAsUUID: UUID? {
            guard let raw = quoteIdString else { return nil }
            return UUID(uuidString: raw)
        }

        var invoiceIdAsUUID: UUID? {
            guard let raw = invoiceIdString else { return nil }
            return UUID(uuidString: raw)
        }

        var providerRequestIdAsUUID: UUID? {
            guard let raw = providerRequestIdString else { return nil }
            return UUID(uuidString: raw)
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
            chezRequestIdString = try? c.decodeIfPresent(String.self, forKey: .chezRequestIdString)
            quoteIdString = try? c.decodeIfPresent(String.self, forKey: .quoteIdString)
            invoiceIdString = try? c.decodeIfPresent(String.self, forKey: .invoiceIdString)
            providerRequestIdString = try? c.decodeIfPresent(String.self, forKey: .providerRequestIdString)
            suggestedProject = try? c.decodeIfPresent(SuggestedProjectInfo.self, forKey: .suggestedProject)
            fairMarket = try? c.decodeIfPresent(FairMarketHint.self, forKey: .fairMarket)
            warranty = try? c.decodeIfPresent(WarrantyHint.self, forKey: .warranty)
            specialtySystemSuggestion = try? c.decodeIfPresent(InboxSpecialtySuggestion.self, forKey: .specialtySystemSuggestion)
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
            throw NSError(domain: "Chez", code: 0, userInfo: [NSLocalizedDescriptionKey: "No household found"])
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
        // 1. burke@alfred.getchez.com
        // 2. 146burke@alfred.getchez.com (street number + last name)
        // 3. burke-<short uuid>@alfred.getchez.com (failsafe)
        var candidates: [String] = [
            "\(baseName)@alfred.getchez.com"
        ]

        if let num = streetNumber {
            candidates.append("\(num)\(baseName)@alfred.getchez.com")
        }

        // Failsafe: append short unique suffixes
        for i in 1...5 {
            let shortId = String(UUID().uuidString.prefix(4)).lowercased()
            // Use street number variants first, then random
            if let num = streetNumber, i <= 2 {
                candidates.append("\(num)\(baseName)\(i)@alfred.getchez.com")
            } else {
                candidates.append("\(baseName)-\(shortId)@alfred.getchez.com")
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

        throw NSError(domain: "Chez", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not generate a unique email address"])
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

    /// Phase 95 (gap #90) — active vehicles only. Archived rows
    /// (sold / traded / totaled) are filtered out at the query
    /// level so the active garage list never has to filter
    /// client-side.
    func fetchVehicles() async throws -> [VehicleRow] {
        try await from("vehicles")
            .select()
            .is("archived_at", value: nil)
            .order("name")
            .execute()
            .value
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

    /// Phase 95 (gap #90) — soft-delete. Stamps archived_at + reason
    /// so the vehicle drops off the active garage list while every
    /// service record, recall, and document linked via vehicle_id
    /// stays accessible via direct lookup. Use this for sold /
    /// traded / totaled cases; reserve `deleteVehicle` for true
    /// "I never owned this" mistakes.
    func archiveVehicle(id: UUID, reason: String) async throws {
        struct ArchiveUpdate: Codable {
            let archivedAt: Date
            let archiveReason: String
            enum CodingKeys: String, CodingKey {
                case archivedAt = "archived_at"
                case archiveReason = "archive_reason"
            }
        }
        try await from("vehicles")
            .update(ArchiveUpdate(archivedAt: Date(), archiveReason: reason))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 95 (gap #90) — restore. Clears the archive flags so
    /// the vehicle reappears in the active garage. Used by an
    /// "Undo archive" toast or the rare case of restoring a
    /// vehicle that was archived by mistake.
    func unarchiveVehicle(id: UUID) async throws {
        struct Unarchive: Codable {
            let archivedAt: Date?
            let archiveReason: String?
            enum CodingKeys: String, CodingKey {
                case archivedAt = "archived_at"
                case archiveReason = "archive_reason"
            }
        }
        try await from("vehicles")
            .update(Unarchive(archivedAt: nil, archiveReason: nil))
            .eq("id", value: id.uuidString)
            .execute()
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

    /// Phase 95 (gap #86) — stamp the "scheduled with dealer"
    /// intermediate state without resolving the recall. Pass nil to
    /// clear the timestamp (e.g. user un-schedules).
    func updateVehicleRecallScheduledWithDealer(id: UUID, scheduledAt: Date?) async throws {
        struct ScheduleUpdate: Codable {
            let scheduledWithDealerAt: Date?
            enum CodingKeys: String, CodingKey {
                case scheduledWithDealerAt = "scheduled_with_dealer_at"
            }
        }
        try await from("vehicle_recalls")
            .update(ScheduleUpdate(scheduledWithDealerAt: scheduledAt))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Phase 95 (gap #86) — link a vehicle service record to a
    /// recall as the resolution evidence. Sets `is_resolved = true`
    /// and `resolved_date = service_record.service_date` so the
    /// resolution maps cleanly onto the work that was actually
    /// done. Passing nil for `serviceRecordId` clears the link
    /// without touching resolved state.
    func linkVehicleRecallToServiceRecord(
        recallId: UUID,
        serviceRecordId: UUID?,
        resolvedDate: String? = nil
    ) async throws {
        struct LinkUpdate: Codable {
            let isResolved: Bool?
            let resolvedDate: String?
            let resolvedServiceRecordId: UUID?
            enum CodingKeys: String, CodingKey {
                case isResolved = "is_resolved"
                case resolvedDate = "resolved_date"
                case resolvedServiceRecordId = "resolved_service_record_id"
            }
        }
        let update = LinkUpdate(
            isResolved: serviceRecordId != nil ? true : nil,
            resolvedDate: serviceRecordId != nil ? resolvedDate : nil,
            resolvedServiceRecordId: serviceRecordId
        )
        try await from("vehicle_recalls")
            .update(update)
            .eq("id", value: recallId.uuidString)
            .execute()
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

    // MARK: - Standing Appointments (Phase 51)

    func fetchStandingAppointments(householdId: UUID, includeArchived: Bool = false) async throws -> [StandingAppointmentRow] {
        var query = from("standing_appointments")
            .select()
            .eq("household_id", value: householdId.uuidString)
        if !includeArchived {
            query = query.is("archived_at", value: nil)
        }
        return try await query
            .order("next_expected_date")
            .execute()
            .value
    }

    func fetchStandingAppointment(id: UUID) async throws -> StandingAppointmentRow {
        try await from("standing_appointments")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchStandingAppointmentsForVendor(vendorId: UUID) async throws -> [StandingAppointmentRow] {
        try await from("standing_appointments")
            .select()
            .eq("vendor_id", value: vendorId.uuidString)
            .is("archived_at", value: nil)
            .order("next_expected_date")
            .execute()
            .value
    }

    func createStandingAppointment(_ appointment: StandingAppointmentInsert) async throws -> StandingAppointmentRow {
        try await from("standing_appointments")
            .insert(appointment)
            .select()
            .single()
            .execute()
            .value
    }

    func updateStandingAppointment(id: UUID, _ updates: StandingAppointmentUpdate) async throws -> StandingAppointmentRow {
        try await from("standing_appointments")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Standing Appointment Visits (Phase 51)

    func fetchVisits(appointmentId: UUID, limit: Int = 20) async throws -> [StandingAppointmentVisitRow] {
        try await from("standing_appointment_visits")
            .select()
            .eq("standing_appointment_id", value: appointmentId.uuidString)
            .order("scheduled_date", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchUpcomingVisit(appointmentId: UUID) async throws -> StandingAppointmentVisitRow? {
        let rows: [StandingAppointmentVisitRow] = try await from("standing_appointment_visits")
            .select()
            .eq("standing_appointment_id", value: appointmentId.uuidString)
            .eq("status", value: "upcoming")
            .order("scheduled_date")
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchMostRecentPastVisit(appointmentId: UUID) async throws -> StandingAppointmentVisitRow? {
        let rows: [StandingAppointmentVisitRow] = try await from("standing_appointment_visits")
            .select()
            .eq("standing_appointment_id", value: appointmentId.uuidString)
            .neq("status", value: "upcoming")
            .order("scheduled_date", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func createVisit(_ visit: StandingAppointmentVisitInsert) async throws -> StandingAppointmentVisitRow {
        try await from("standing_appointment_visits")
            .insert(visit)
            .select()
            .single()
            .execute()
            .value
    }

    func updateVisit(id: UUID, _ updates: StandingAppointmentVisitUpdate) async throws -> StandingAppointmentVisitRow {
        try await from("standing_appointment_visits")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    /// Count consecutive assumed visits without a confirmed visit in between.
    func countConsecutiveAssumedVisits(appointmentId: UUID) async throws -> Int {
        let visits: [StandingAppointmentVisitRow] = try await from("standing_appointment_visits")
            .select()
            .eq("standing_appointment_id", value: appointmentId.uuidString)
            .order("scheduled_date", ascending: false)
            .limit(10)
            .execute()
            .value
        var count = 0
        for visit in visits {
            if visit.status == "assumed" { count += 1 }
            else if visit.status == "confirmed" { break }
            else { continue } // skip upcoming/skipped
        }
        return count
    }

    // MARK: - Category Cadence Defaults (Phase 51)

    func fetchCategoryCadenceDefaults() async throws -> [CategoryCadenceDefaultRow] {
        try await from("category_cadence_defaults")
            .select()
            .execute()
            .value
    }

    func fetchCadenceDefault(category: String) async throws -> CategoryCadenceDefaultRow? {
        let rows: [CategoryCadenceDefaultRow] = try await from("category_cadence_defaults")
            .select()
            .eq("category_key", value: category)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Dismissed Specialty Suggestions (Phase 52b)

    /// Record a dismissed specialty system suggestion so the server
    /// doesn't re-suggest the same category for this household.
    func dismissSpecialtySuggestion(householdId: UUID, category: String, evidence: String) async throws {
        struct Insert: Codable {
            let householdId: UUID
            let category: String
            let evidence: String

            enum CodingKeys: String, CodingKey {
                case householdId = "household_id"
                case category
                case evidence
            }
        }

        try await from("household_dismissed_suggestions")
            .insert(Insert(householdId: householdId, category: category, evidence: evidence))
            .execute()
    }
}
