import Foundation

/// Owns the household-side adoption flow for a Chez Field directory
/// provider. Both `FindLocalVendorSheet` (auto-match path) and
/// `ChezDirectorySearchView` (active browse / search path) call into
/// this service so the side-effect chain — contractor insert,
/// matching-task sweep, notification posts, haptic — stays in one
/// place. The view remains responsible for sheet dismissal and
/// `onAdoptedVendor` plumbing because those are presentation concerns.
@MainActor
final class ChezDirectoryService {
    static let shared = ChezDirectoryService()

    private init() {}

    /// Adopts the given Chez Field provider as a contractor for this
    /// household. Stamps `source: "chez_field"` and stashes the workspace
    /// id in `notes` so a future provider-side flow can confirm the link
    /// via `provider_contractor_links` (RLS locks that table to workspace
    /// members, so we don't write to it from the homeowner side).
    ///
    /// After insert, walks every matching `needs_vendor` task in the
    /// household and reframes it via `MaintenanceViewModel.convertToVendorManaged`.
    /// Match rule: same household, no vehicle, `assignment_type == "vendor"`,
    /// `needs_vendor == true`, and the task's system category equals
    /// `systemCategory`. When a task has no resolvable system, the
    /// `triggeringTaskId` provides a fallback so the user always sees at
    /// least the task they tapped get converted.
    ///
    /// Result of an adoption attempt. The view layer shows the error
    /// message inline so a silent network/RLS failure doesn't leave
    /// the user staring at an unchanged sheet.
    enum AdoptResult {
        case success(ContractorRow)
        case failure(String)
    }

    /// Returns the freshly-created `ContractorRow` on success, or a
    /// human-readable error string on failure so the calling view can
    /// render an inline message. Both paths are explicit — there's no
    /// silent nil that looks like "nothing happened" from the user's
    /// side.
    func adopt(
        _ provider: HavenSupabase.ChezFieldProvider,
        householdId: UUID,
        systemCategory: String,
        triggeringTaskId: UUID?
    ) async -> AdoptResult {
        let db = DatabaseService.shared

        var insert = ContractorInsert(
            householdId: householdId,
            companyName: provider.name,
            phone: provider.phone ?? "Not provided"
        )
        insert.website = provider.website
        // July 2026 (audit F16): canonical category so the adopted vendor
        // matches coverage (Groton bug class).
        let canonicalCategory = SystemCategoryRegistry.canonical(category: systemCategory) ?? systemCategory
        insert.category = canonicalCategory
        insert.specialties = [canonicalCategory]
        insert.source = "chez_field"
        insert.notes = "Chez Field workspace: \(provider.workspaceId)"

        let createdContractor: ContractorRow
        do {
            createdContractor = try await createContractor(insert, db: db)
        } catch {
            print("[ChezDirectoryService] Failed to create contractor: \(error)")
            return .failure(Self.userFacingErrorMessage(for: error))
        }

        await MaintenanceViewModel.shared.loadTasks()
        let candidates = MaintenanceViewModel.shared.tasks.filter { row in
            guard row.vehicleId == nil else { return false }
            guard row.assignmentType?.lowercased() == "vendor" else { return false }
            guard row.needsVendor == true else { return false }
            guard let systemId = row.systemId,
                  let system = MaintenanceViewModel.shared.systems.first(where: { $0.id == systemId })
            else {
                if let triggeringTaskId {
                    return row.id == triggeringTaskId
                }
                return false
            }
            // July 2026 (audit F16): canonical match, not raw equality.
            return SystemCategoryRegistry.categoriesMatch(system.category, systemCategory)
        }

        for candidate in candidates {
            await MaintenanceViewModel.shared.convertToVendorManaged(
                taskId: candidate.id,
                contractor: createdContractor
            )
        }

        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .contractorChanged, object: nil)
        NotificationCenter.default.post(
            name: .contractorAdded,
            object: nil,
            userInfo: ["contractorId": createdContractor.id.uuidString]
        )
        Haptics.success()

        // Phase 73 follow-up: insert the workspace ↔ contractor link
        // server-side so the provider's dispatch surface (and any
        // future offline-visit website) immediately shows this
        // homeowner. Without this the workspace returns an empty
        // list of homes even though the contractor row exists.
        // Best-effort — adoption is already a success from the
        // homeowner's side even if the link insert fails or races.
        if let workspaceId = UUID(uuidString: provider.workspaceId) {
            do {
                _ = try await HavenSupabase.linkAdoptedHandymanProvider(
                    workspaceId: workspaceId,
                    contractorId: createdContractor.id
                )
            } catch {
                print("[ChezDirectoryService] Couldn't link workspace to contractor: \(error)")
            }
        }

        return .success(createdContractor)
    }

    /// Picks a short, actionable message out of a Supabase / network
    /// error. Falls back to `localizedDescription` so unrecognized
    /// shapes still surface something the user can act on (or report).
    private static func userFacingErrorMessage(for error: Error) -> String {
        let raw = error.localizedDescription
        let lowered = raw.lowercased()
        if lowered.contains("not authenticated") || lowered.contains("jwt") || lowered.contains("unauthorized") {
            return "Sign in expired. Pull to refresh and try again."
        }
        if lowered.contains("network") || lowered.contains("offline") || lowered.contains("internet") {
            return "Couldn't reach the server. Check your connection and try again."
        }
        if lowered.contains("contractors_source_check") {
            return "Sync issue: this build can't yet stamp Chez providers. Update the app and try again."
        }
        if lowered.contains("row-level security") || lowered.contains("rls") {
            return "Permission error. Sign out and back in, then retry."
        }
        return "Couldn't add this provider. \(raw)"
    }

    /// Two rollout guards layered on the bare insert:
    ///
    /// 1. **Legacy source CHECK** (Phase 73 sub-phase A rollout): if the
    ///    app lands before `contractors_source_check` was expanded to
    ///    accept `chez_field`, retry once with `find_vendor` so the
    ///    homeowner can still adopt the provider.
    /// 2. **Duplicate name** (`uniq_contractors_household_name`): a
    ///    contractor with the same household_id + normalized
    ///    `lower(trim(company_name))` already exists. This typically
    ///    means the homeowner adopted them earlier via Find a vendor
    ///    (or the source-CHECK fallback above), so re-adopting through
    ///    the Chez Field path should resolve to the same row, not
    ///    error. We fetch the existing row, refresh its Chez Field
    ///    metadata (source, notes, website, category), and return it
    ///    as if the insert succeeded.
    private func createContractor(
        _ insert: ContractorInsert,
        db: DatabaseService
    ) async throws -> ContractorRow {
        do {
            return try await db.createContractor(insert)
        } catch {
            if Self.isDuplicateNameConstraint(error) {
                if let existing = try? await Self.fetchExistingContractor(
                    db: db,
                    householdId: insert.householdId,
                    companyName: insert.companyName
                ) {
                    return try await Self.refreshChezFieldMetadata(
                        on: existing,
                        from: insert,
                        db: db
                    )
                }
                throw error
            }

            guard insert.source == "chez_field",
                  Self.isLegacySourceConstraint(error)
            else {
                throw error
            }

            var fallback = insert
            fallback.source = "find_vendor"
            do {
                return try await db.createContractor(fallback)
            } catch let fallbackError {
                if Self.isDuplicateNameConstraint(fallbackError),
                   let existing = try? await Self.fetchExistingContractor(
                       db: db,
                       householdId: insert.householdId,
                       companyName: insert.companyName
                   ) {
                    return try await Self.refreshChezFieldMetadata(
                        on: existing,
                        from: insert,
                        db: db
                    )
                }
                throw fallbackError
            }
        }
    }

    private static func isLegacySourceConstraint(_ error: Error) -> Bool {
        let description = String(describing: error)
        return description.contains("23514")
            && description.contains("contractors_source_check")
    }

    private static func isDuplicateNameConstraint(_ error: Error) -> Bool {
        let description = String(describing: error)
        return description.contains("23505")
            && description.contains("uniq_contractors_household_name")
    }

    /// Fetch a contractor by household + case/whitespace-insensitive
    /// company_name match. Mirrors the SQL unique index's normalization.
    /// `fetchContractors()` is already household-scoped via RLS — no
    /// explicit household filter needed.
    private static func fetchExistingContractor(
        db: DatabaseService,
        householdId: UUID,
        companyName: String
    ) async throws -> ContractorRow? {
        let normalized = companyName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let candidates = try await db.fetchContractors()
        return candidates.first { row in
            row.householdId == householdId &&
            row.companyName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }
    }

    /// Update an existing contractor row with the Chez Field provider's
    /// fresh metadata (source flag, workspace note, website, canonical
    /// category) and return the refreshed row. We don't overwrite the
    /// existing phone — the homeowner may have manually corrected it.
    private static func refreshChezFieldMetadata(
        on existing: ContractorRow,
        from insert: ContractorInsert,
        db: DatabaseService
    ) async throws -> ContractorRow {
        var update = ContractorUpdate()
        update.source = insert.source ?? "chez_field"
        update.notes = insert.notes
        if let website = insert.website, existing.website?.isEmpty != false {
            update.website = website
        }
        if let category = insert.category, existing.category?.isEmpty != false {
            update.category = category
        }
        if let specialties = insert.specialties,
           (existing.specialties ?? []).isEmpty {
            update.specialties = specialties
        }
        do {
            return try await db.updateContractor(id: existing.id, update)
        } catch {
            // If the metadata refresh fails (e.g. RLS edge), still
            // return the existing row — the homeowner's "Add" intent
            // is satisfied either way; the source flag is just a
            // bookkeeping nicety.
            print("[ChezDirectoryService] Couldn't refresh existing contractor metadata: \(error)")
            return existing
        }
    }
}
