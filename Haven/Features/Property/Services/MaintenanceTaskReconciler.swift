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
        flags: [String: Bool] = [:]
    ) async -> ReconciliationResult {
        // 1. Compute the correct set of templates for the confirmed subtype.
        let activeSubtypes = MaintenanceTemplates.activeSubtypes(
            category: systemCategory,
            subtype: confirmedSubtype,
            fuelType: fuelType,
            flags: flags
        )
        let correctTemplates = MaintenanceTemplates.essentialTemplates(
            for: systemCategory,
            activeSubtypes: activeSubtypes
        )
        let correctTitles = Set(correctTemplates.map { $0.title.lowercased() })
        let knownTitlesForCategory = MaintenanceTemplates.knownTemplateTitles(forCategory: systemCategory)

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
        let existingTitles = Set(existing.map { $0.title.lowercased() })

        // 3. Templates to ADD: in the correct set but not yet present.
        var added: [String] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for template in correctTemplates where !existingTitles.contains(template.title.lowercased()) {
            let nextDue = calendar.date(byAdding: template.interval, to: Date()) ?? Date()
            var insert = MaintenanceTaskInsert(
                householdId: householdId,
                title: template.title,
                frequency: template.frequency,
                nextDueDate: formatter.string(from: nextDue)
            )
            insert.propertyId = propertyId
            insert.systemId = systemId
            insert.description = template.description
            insert.priority = template.priority
            insert.isTemplateBased = true
            insert.templateId = "\(template.systemCategory):\(template.title)"
            insert.seasonalTiming = template.seasonalTiming
            insert.isDiy = template.isDIY
            insert.professionalRequired = template.professionalRequired
            insert.costRange = template.estimatedCostRange
            if (try? await DatabaseService.shared.createMaintenanceTask(insert)) != nil {
                added.append(template.title)
            }
        }

        // 4. Tasks to REMOVE: existing rows that no longer match `correctTitles`.
        //    Soft-delete only — and only when we're confident the task is
        //    template-managed and the user hasn't touched it.
        var removed: [String] = []
        var preserved: [String] = []
        for task in existing where !correctTitles.contains(task.title.lowercased()) {
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
