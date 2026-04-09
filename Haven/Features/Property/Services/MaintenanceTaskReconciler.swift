import Foundation

/// Reconciles maintenance tasks for a home system to match the currently
/// confirmed subtype. Replaces the one-way `MaintenanceTaskMigrator`: this
/// service adds newly-applicable templates AND soft-deletes templates that
/// stopped applying when the user confirmed a different subtype in the House
/// Quiz (or via a manual edit).
///
/// **User work is always preserved.** A task is considered "user-touched" and
/// kept in place if any of these are true:
///   - It has a `lastCompletedDate` (the user marked it complete at least once)
///   - It has an `assignedToUserId` (the user reassigned it)
///   - It has non-empty `notes`
///   - It is NOT a known template title for this category (i.e. user-added
///     custom task whose name doesn't match anything Haven knows about)
///
/// **Deletes are soft.** The reconciler calls
/// `DatabaseService.archiveMaintenanceTask(id:reason:)` which sets
/// `is_archived = true` rather than removing the row, so history is
/// recoverable and any cross-references (warranties, service emails, etc.)
/// stay intact.
@MainActor
enum MaintenanceTaskReconciler {

    /// Phase 19d: controls which half of the reconcile pass runs. `EditSystemSheet`
    /// uses `.addOnly` after its existing orphan-confirmation dialog completes so
    /// the reconciler inserts newly-applicable templates without stomping the
    /// user's explicit "keep these tasks" choices.
    enum ReconcileMode {
        /// Add newly-applicable templates AND soft-delete orphans (preserving
        /// user-touched tasks). The default, used by the House Quiz path.
        case full
        /// Only insert templates that became newly applicable. Existing tasks
        /// are never touched. Used by `EditSystemSheet` after its own orphan
        /// dialog decides the removal half.
        case addOnly
        /// Only soft-delete orphans, never add. Rarely needed; included for
        /// symmetry so callers that already inserted templates via another
        /// path can still run a cleanup pass.
        case removeOnly
    }

    /// Result of a single reconciliation pass. Each list contains the human
    /// titles of the affected tasks. Use `merging(_:)` to accumulate results
    /// across multiple `reconcile` calls (e.g. inside `reconcileAll`).
    struct ReconciliationResult {
        let added: [String]
        let removed: [String]
        let preserved: [String]

        static let empty = ReconciliationResult(added: [], removed: [], preserved: [])

        var totalChanged: Int { added.count + removed.count }
        var isEmpty: Bool { added.isEmpty && removed.isEmpty }

        func merging(_ other: ReconciliationResult) -> ReconciliationResult {
            ReconciliationResult(
                added: added + other.added,
                removed: removed + other.removed,
                preserved: preserved + other.preserved
            )
        }
    }

    // MARK: - Single-system reconcile

    /// Reconciles tasks for a single system based on its current subtype.
    /// Idempotent — safe to call repeatedly with the same inputs.
    static func reconcile(
        propertyId: UUID,
        householdId: UUID,
        systemId: UUID?,
        systemCategory: String,
        confirmedSubtype: String?,
        fuelType: String? = nil,
        flags: [String: Bool] = [:],
        mode: ReconcileMode = .full
    ) async -> ReconciliationResult {
        // 1. Compute the correct set of templates for the confirmed subtype.
        let activeSubtypes = MaintenanceTemplates.activeSubtypes(
            category: systemCategory,
            subtype: confirmedSubtype,
            fuelType: fuelType,
            flags: flags
        )
        let rawTemplates = MaintenanceTemplates.essentialTemplates(
            for: systemCategory,
            activeSubtypes: activeSubtypes
        )

        // Phase 19j: Fetch the property once so template `{city}` and
        // `{state}` placeholders can be substituted with the user's actual
        // location before tasks are written. Failures fall back to generic
        // "your area" / "your state" so the reconciler still runs offline.
        let property = try? await DatabaseService.shared.fetchProperty(id: propertyId)
        let correctTemplates = rawTemplates.map {
            $0.interpolated(city: property?.city, state: property?.state)
        }

        // Phase 19k: dedup by templateKey (stable) instead of title (mutable
        // because vendor reframing changes it). Both correctTemplates and
        // existing tasks compare against the underlying template identity.
        let correctTemplateKeys = Set(rawTemplates.map { $0.templateKey })
        let knownTitlesForCategory = MaintenanceTemplates.knownTemplateTitles(forCategory: systemCategory)

        // Phase 19k: Look up household contractors so we can decide, per
        // template, whether to create the task as personal, vendor-managed
        // (linked to a contractor), or "find a contractor" (vendor template
        // with no contractor on file). One DB call up front, in-memory
        // matching after. RLS scopes the result to this household automatically.
        let allContractors = (try? await DatabaseService.shared.fetchContractors()) ?? []

        // 2. Fetch existing active (non-archived) tasks for this property and
        //    narrow them to the ones that belong to the system being
        //    reconciled. Match by `systemId` first (the strong signal); fall
        //    back to template-id prefix or title-based heuristic for legacy
        //    tasks that have no system attachment.
        let allExisting: [MaintenanceTaskDBRow]
        do {
            allExisting = try await DatabaseService.shared.fetchMaintenanceTasks(
                propertyId: propertyId
            )
        } catch {
            return .empty
        }
        let categoryPrefix = systemCategory.lowercased() + ":"
        let existing = allExisting.filter { task in
            // Vehicle tasks are out of scope for the home reconciler.
            if task.vehicleId != nil { return false }
            // Strong match: task explicitly attached to this system.
            if let systemId, task.systemId == systemId { return true }
            // Template prefix fallback (post-Phase-14 task with templateId set).
            if let templateId = task.templateId,
               templateId.lowercased().hasPrefix(categoryPrefix) {
                return true
            }
            // Legacy fallback: orphaned task whose title is a known template
            // title for this category. Catches pre-Phase-14 rows that have
            // neither systemId nor templateId set.
            if task.systemId == nil,
               knownTitlesForCategory.contains(task.title.lowercased()) {
                return true
            }
            return false
        }
        // Phase 19k: existing dedup keys are templateIds, not titles.
        let existingTemplateIds = Set(existing.compactMap { $0.templateId })

        // 3. Templates to ADD: in the correct set but not yet present.
        //    Gated on mode — `.removeOnly` skips this half entirely.
        var added: [String] = []
        if mode != .removeOnly {
            let calendar = Calendar.current
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            // Iterate raw templates (not interpolated) so templateKey is stable.
            // Then look up the matching interpolated version for actual content.
            for (index, rawTemplate) in rawTemplates.enumerated() {
                let templateKey = rawTemplate.templateKey
                guard !existingTemplateIds.contains(templateKey) else { continue }

                let template = correctTemplates[index]
                let nextDue = calendar.date(byAdding: template.interval, to: Date()) ?? Date()

                // Phase 19k: vendor-aware task creation.
                // Find a matching contractor for the system's category. Match
                // is case-insensitive on contractor.category, with a fallback
                // to the legacy specialties array if category is unset.
                let matchingContractor = allContractors.first { contractor in
                    if let cat = contractor.category,
                       cat.caseInsensitiveCompare(systemCategory) == .orderedSame {
                        return true
                    }
                    if let specs = contractor.specialties,
                       specs.contains(where: { $0.caseInsensitiveCompare(systemCategory) == .orderedSame }) {
                        return true
                    }
                    return false
                }

                // Decide assignment + framing based on the template's
                // assignmentType and whether a contractor exists.
                let finalTitle: String
                let finalDescription: String
                let assignmentTypeString: String
                let assignedContractorId: UUID?
                let needsVendor: Bool

                switch template.assignmentType {
                case .personal:
                    // Always personal, no vendor lookup needed.
                    finalTitle = template.title
                    finalDescription = template.description
                    assignmentTypeString = "personal"
                    assignedContractorId = nil
                    needsVendor = false

                case .vendor:
                    // Always vendor-managed. If contractor exists, link and
                    // reframe the title. If not, mark as needs_vendor and
                    // reframe as "Find a contractor for: ...".
                    if let contractor = matchingContractor {
                        finalTitle = "Schedule \(contractor.companyName): \(template.title.lowercased())"
                        finalDescription = "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(template.description)"
                        assignmentTypeString = "vendor"
                        assignedContractorId = contractor.id
                        needsVendor = false
                    } else {
                        finalTitle = "Find a contractor for: \(template.title.lowercased())"
                        finalDescription = "We'll find you a vetted local pro for this. In the meantime, here's what they'll do:\n\n\(template.description)"
                        assignmentTypeString = "vendor"
                        assignedContractorId = nil
                        needsVendor = true
                    }

                case .either:
                    // Default to personal. Phase 19l's UI surfaces the
                    // bidirectional toggle so users can flip to vendor later.
                    // The post-quiz delegation sheet also offers to bulk-flip
                    // these when a vendor for the category exists.
                    finalTitle = template.title
                    finalDescription = template.description
                    assignmentTypeString = "either"
                    assignedContractorId = nil
                    needsVendor = false
                }

                var insert = MaintenanceTaskInsert(
                    householdId: householdId,
                    title: finalTitle,
                    frequency: template.frequency,
                    nextDueDate: formatter.string(from: nextDue)
                )
                insert.propertyId = propertyId
                insert.systemId = systemId
                insert.description = finalDescription
                insert.priority = template.priority
                insert.isTemplateBased = true
                insert.templateId = templateKey
                insert.seasonalTiming = template.seasonalTiming
                insert.isDiy = template.isDIY
                insert.professionalRequired = template.professionalRequired
                insert.costRange = template.estimatedCostRange
                insert.assignedContractorId = assignedContractorId
                insert.assignmentType = assignmentTypeString
                insert.needsVendor = needsVendor
                if (try? await DatabaseService.shared.createMaintenanceTask(insert)) != nil {
                    added.append(finalTitle)
                }
            }
        }

        // 4. Tasks to REMOVE: existing rows whose templateId no longer matches
        //    the correct set. Soft-delete only — and only when we're confident
        //    the task is template-managed and the user hasn't touched it.
        //    Gated on mode — `.addOnly` skips this half entirely so callers
        //    that have their own removal UX (e.g. EditSystemSheet's orphan
        //    dialog) keep authority over what gets deleted.
        var removed: [String] = []
        var preserved: [String] = []
        if mode != .addOnly {
            for task in existing {
                // Phase 19k: dedup by templateId, not title (since vendor
                // reframing means the title can drift from the original).
                if let tid = task.templateId, correctTemplateKeys.contains(tid) {
                    continue
                }
                // Skip rows that aren't template-managed at all (custom user task
                // whose title doesn't match anything Haven knows about).
                let isKnownTemplate = knownTitlesForCategory.contains(task.title.lowercased())
                guard isKnownTemplate else {
                    preserved.append(task.title)
                    continue
                }
                // Preserve any task the user has clearly engaged with.
                if isUserTouched(task) {
                    preserved.append(task.title)
                    continue
                }
                do {
                    try await DatabaseService.shared.archiveMaintenanceTask(
                        id: task.id,
                        reason: "subtype_mismatch:\(systemCategory):\(confirmedSubtype ?? "nil")"
                    )
                    removed.append(task.title)
                } catch {
                    preserved.append(task.title)
                }
            }
        }

        return ReconciliationResult(added: added, removed: removed, preserved: preserved)
    }

    // MARK: - Whole-property reconcile

    /// Reconciles every system on the property, plus a final pass for
    /// orphaned tasks (no system attachment) keyed by their template title.
    /// Used by:
    ///   - The post-quiz cleanup pass (catches systems that weren't touched
    ///     by a specific quiz answer but had their subtype inferred).
    ///   - The one-time legacy migration in `AppState.initialize()`.
    static func reconcileAll(propertyId: UUID, householdId: UUID) async -> ReconciliationResult {
        var aggregate = ReconciliationResult.empty
        let systems: [HomeSystemRow]
        do {
            systems = try await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)
        } catch {
            return aggregate
        }

        // Track categories we've already reconciled so the orphan pass at the
        // end doesn't double-process tasks that were just handled inline.
        var processedCategories = Set<String>()

        for system in systems {
            let result = await reconcile(
                propertyId: propertyId,
                householdId: householdId,
                systemId: system.id,
                systemCategory: system.category,
                confirmedSubtype: system.subtype,
                fuelType: system.catalogFuelType,
                flags: [:]
            )
            aggregate = aggregate.merging(result)
            processedCategories.insert(system.category.lowercased())
        }

        // Orphan pass: legacy tasks that have no `systemId` and no matching
        // category-prefix on their templateId. We need a system-less reconcile
        // path for those, but only for categories that don't already have a
        // system row (otherwise the per-system call already handled them).
        let allCategories: [String] = ["Roofing", "HVAC", "Plumbing", "Water Heater", "Septic System", "Well System", "Electrical", "Fire Protection", "Landscaping", "Pool/Spa", "Garage Door", "Irrigation"]
        for category in allCategories where !processedCategories.contains(category.lowercased()) {
            let result = await reconcile(
                propertyId: propertyId,
                householdId: householdId,
                systemId: nil,
                systemCategory: category,
                confirmedSubtype: nil,
                fuelType: nil,
                flags: [:]
            )
            aggregate = aggregate.merging(result)
        }

        return aggregate
    }

    // MARK: - Helpers

    /// `true` if the user has clearly engaged with the task in a way the
    /// reconciler must not stomp on. Reconciler-driven deletions only run
    /// when this returns `false`.
    private static func isUserTouched(_ task: MaintenanceTaskDBRow) -> Bool {
        if let last = task.lastCompletedDate, !last.isEmpty { return true }
        if task.assignedToUserId != nil { return true }
        if let notes = task.notes, !notes.isEmpty { return true }
        return false
    }
}
