import Foundation

// MARK: - Vendor Preference Tiers

/// Three clear tiers for how hands-on the user wants to be with home
/// maintenance. Replaces the old 1-10 slider that users found confusing
/// ("what's the difference between 7 and 8?"). Stored as a string in
/// `properties.attributes["vendor_preference_tier"]`.
enum VendorPreferenceTier: Int, Codable, CaseIterable, Identifiable {
    case diy = 1        // "I handle most things myself"
    case mixed = 2      // "I do some, hire some"
    case hireOut = 3    // "I hire everything out"

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .diy: return "I handle it"
        case .mixed: return "Mix of both"
        case .hireOut: return "Hire it out"
        }
    }

    var subtitle: String {
        switch self {
        case .diy: return "You'll see every task as a personal to-do. Vendors only for things that require a licensed pro."
        case .mixed: return "Quick tasks stay on your list. Bigger jobs get routed to your vendors or we'll help you find one."
        case .hireOut: return "Almost everything goes to a vendor. Your list becomes a coordination dashboard, not a to-do list."
        }
    }

    /// Map from the old 1-10 slider int to the new 3-tier model.
    /// 1-3 → .diy, 4-7 → .mixed, 8-10 → .hireOut
    static func fromLegacyLevel(_ level: Int) -> VendorPreferenceTier {
        switch level {
        case 1...3: return .diy
        case 4...7: return .mixed
        default:    return .hireOut
        }
    }

    /// Map from a persisted string ("diy", "mixed", "hire_out") or legacy int.
    static func fromAttribute(_ value: String?) -> VendorPreferenceTier {
        guard let value, !value.isEmpty else { return .mixed }
        switch value.lowercased() {
        case "diy":      return .diy
        case "mixed":    return .mixed
        case "hire_out": return .hireOut
        default:
            // Legacy int path: parse the old 1-10 value
            if let intVal = Int(value) {
                return fromLegacyLevel(intVal)
            }
            return .mixed
        }
    }

    /// The string persisted to `properties.attributes["vendor_preference_tier"]`.
    var attributeValue: String {
        switch self {
        case .diy: return "diy"
        case .mixed: return "mixed"
        case .hireOut: return "hire_out"
        }
    }
}

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
        // Also reads the vendor preference tier so the per-template
        // assignment for `.either` templates honors the user's choice.
        let property = try? await DatabaseService.shared.fetchProperty(id: propertyId)
        let preferenceTier = preferenceTierFromProperty(property)
        let correctTemplates = rawTemplates.map {
            $0.interpolated(city: property?.city, state: property?.state)
        }

        // Phase 19k: dedup by templateKey (stable) instead of title (mutable
        // because vendor reframing changes it). Both correctTemplates and
        // existing tasks compare against the underlying template identity.
        // Build 88: also include bundleIds so the remove pass recognizes
        // bundled tasks as still-correct.
        var correctTemplateKeys = Set(rawTemplates.map { $0.templateKey })
        for t in rawTemplates {
            if let bid = t.bundleId { correctTemplateKeys.insert(bid) }
        }
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
        //
        //    Build 88: Templates are split into standalone (bundleId == nil)
        //    and bundled (bundleId != nil). Standalone templates create one
        //    task each as before. Bundled templates are grouped by bundleId
        //    and create ONE task per bundle with a "What's included:"
        //    checklist in the notes field.
        var added: [String] = []
        if mode != .removeOnly {
            let calendar = Calendar.current
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            // Find a matching contractor for the system's category (used
            // by both standalone and bundled paths).
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

            // Partition templates into standalone vs bundled.
            var standaloneIndices: [Int] = []
            // bundleId → [(rawIndex, rawTemplate, interpolatedTemplate)]
            var bundleGroups: [String: [(Int, MaintenanceTemplate, MaintenanceTemplate)]] = [:]

            for (index, rawTemplate) in rawTemplates.enumerated() {
                if let bid = rawTemplate.bundleId {
                    bundleGroups[bid, default: []].append((index, rawTemplate, correctTemplates[index]))
                } else {
                    standaloneIndices.append(index)
                }
            }

            // --- Standalone templates (unchanged logic) ---
            for index in standaloneIndices {
                let rawTemplate = rawTemplates[index]
                let templateKey = rawTemplate.templateKey
                guard !existingTemplateIds.contains(templateKey) else { continue }

                let template = correctTemplates[index]
                let result = createTaskFields(
                    template: template,
                    preferenceTier: preferenceTier,
                    matchingContractor: matchingContractor
                )

                let nextDue = calendar.date(byAdding: template.interval, to: Date()) ?? Date()
                var insert = MaintenanceTaskInsert(
                    householdId: householdId,
                    title: result.title,
                    frequency: template.frequency,
                    nextDueDate: formatter.string(from: nextDue)
                )
                insert.propertyId = propertyId
                insert.systemId = systemId
                insert.description = result.description
                insert.priority = template.priority
                insert.isTemplateBased = true
                insert.templateId = templateKey
                insert.seasonalTiming = template.seasonalTiming
                insert.isDiy = template.isDIY
                insert.professionalRequired = template.professionalRequired
                insert.costRange = template.estimatedCostRange
                insert.assignedContractorId = result.contractorId
                insert.assignmentType = result.assignmentType
                insert.needsVendor = result.needsVendor
                if (try? await DatabaseService.shared.createMaintenanceTask(insert)) != nil {
                    added.append(result.title)
                }
            }

            // --- Bundled templates ---
            // Each bundle creates ONE task. The templateId is the bundleId
            // so dedup works at the bundle level. If the bundle already
            // exists (any individual template key OR the bundleId itself is
            // in existingTemplateIds), skip the whole bundle.
            for (bundleId, members) in bundleGroups {
                // Skip if the bundle task already exists.
                if existingTemplateIds.contains(bundleId) { continue }
                // Also skip if ANY individual template in the bundle already
                // exists as a standalone task (from a pre-bundle build).
                let anyMemberExists = members.contains { (_, raw, _) in
                    existingTemplateIds.contains(raw.templateKey)
                }
                if anyMemberExists { continue }

                guard let firstMember = members.first else { continue }
                let (_, _, firstTemplate) = firstMember

                // Resolve the bundle title from the first member that has one.
                let title = members.compactMap({ $0.2.bundleTitle }).first
                    ?? firstTemplate.title

                // Build the "What's included:" checklist from all member titles.
                let checklist = members.map { "- \($0.2.title)" }.joined(separator: "\n")
                let bundleNotes = "What's included:\n\(checklist)"

                // The bundle is always vendor (bundled = service visit).
                // Use the same contractor matching as standalone vendor tasks.
                let bundleTitle: String
                let bundleDescription: String
                let contractorId: UUID?
                let needsVendor: Bool

                if let contractor = matchingContractor {
                    bundleTitle = "Schedule \(contractor.companyName): \(title.lowercased())"
                    bundleDescription = "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work.\n\n\(bundleNotes)"
                    contractorId = contractor.id
                    needsVendor = false
                } else {
                    bundleTitle = title
                    bundleDescription = bundleNotes
                    contractorId = nil
                    needsVendor = true
                }

                let nextDue = calendar.date(byAdding: firstTemplate.interval, to: Date()) ?? Date()
                var insert = MaintenanceTaskInsert(
                    householdId: householdId,
                    title: bundleTitle,
                    frequency: firstTemplate.frequency,
                    nextDueDate: formatter.string(from: nextDue)
                )
                insert.propertyId = propertyId
                insert.systemId = systemId
                insert.description = bundleDescription
                insert.priority = firstTemplate.priority
                insert.isTemplateBased = true
                insert.templateId = bundleId
                insert.seasonalTiming = firstTemplate.seasonalTiming
                insert.isDiy = false
                insert.professionalRequired = true
                insert.costRange = firstTemplate.estimatedCostRange
                insert.assignedContractorId = contractorId
                insert.assignmentType = "vendor"
                insert.needsVendor = needsVendor
                insert.notes = bundleNotes
                if (try? await DatabaseService.shared.createMaintenanceTask(insert)) != nil {
                    added.append(bundleTitle)
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

    // MARK: - Build 87: household-wide reconcile

    /// Build 87: walks every property in the household and reconciles each
    /// one. Used by the DIY vs Vendor slider commit path (Q36 + Settings →
    /// Preferences → Save) so a single value change rebalances every
    /// `either`-tagged task across the household. Also flips existing rows
    /// in place via `flipEitherTasksForPreference` since `reconcile` only
    /// touches the create-side decision and the user already has a real
    /// task list at this point.
    static func reconcileAllForHousehold(householdId: UUID) async -> ReconciliationResult {
        var aggregate = ReconciliationResult.empty
        let properties: [PropertyRow]
        do {
            properties = try await DatabaseService.shared.fetchProperties()
        } catch {
            return aggregate
        }
        for property in properties where property.householdId == householdId {
            let result = await reconcileAll(propertyId: property.id, householdId: property.householdId)
            aggregate = aggregate.merging(result)

            // Flip pre-existing `either`-tagged rows to match the new
            // preference. The reconciler's create-side decision only fires
            // for newly inserted templates; this pass updates the rows that
            // were already created at a different preference level.
            let flipResult = await flipEitherTasksForPreference(
                propertyId: property.id,
                householdId: property.householdId
            )
            aggregate = aggregate.merging(flipResult)
        }
        return aggregate
    }

    /// Build 87: per-property pass that walks existing maintenance_tasks
    /// and flips any `either`-tagged row whose computed assignment changed
    /// because of a new `vendor_preference_level`. Strictly preserves
    /// user-touched tasks (assigned, has notes, has completion history)
    /// AND tasks that already have an explicit contractor link from the
    /// post-quiz delegation flow (`assigned_contractor_id IS NOT NULL`).
    /// The reframing voice matches Phase 19l's `convertToVendorManaged` so
    /// flipped tasks read identically to the post-quiz delegation path.
    static func flipEitherTasksForPreference(
        propertyId: UUID,
        householdId: UUID
    ) async -> ReconciliationResult {
        var added: [String] = []
        var removed: [String] = []
        var preserved: [String] = []

        let property = try? await DatabaseService.shared.fetchProperty(id: propertyId)
        let preferenceTier = preferenceTierFromProperty(property)

        let tasks: [MaintenanceTaskDBRow]
        do {
            tasks = try await DatabaseService.shared.fetchMaintenanceTasks(propertyId: propertyId)
        } catch {
            return .empty
        }

        // Build a templateKey → MaintenanceTemplate index of `.either`
        // templates only. Anything else (.personal / .vendor) is fixed and
        // doesn't get touched by the slider.
        var eitherTemplates: [String: MaintenanceTemplate] = [:]
        for (_, sectionTemplates) in MaintenanceTemplates.allTemplates {
            for template in sectionTemplates where template.assignmentType == .either {
                eitherTemplates[template.templateKey] = template
            }
        }

        // Cache contractors once. Used to link a flipped task to a vendor
        // in the matching system category at flip time, mirroring the
        // create-side branch in `reconcile`.
        let contractors = (try? await DatabaseService.shared.fetchContractors()) ?? []

        for task in tasks {
            // Vehicle tasks are out of scope for the home reconciler.
            if task.vehicleId != nil { continue }
            // Must be a known either template.
            guard let templateKey = task.templateId,
                  let template = eitherTemplates[templateKey] else { continue }
            // Skip rows the user has manually edited (notes, reassignment,
            // completion history).
            if isUserTouched(task) { continue }
            // Skip rows that already have an explicit contractor link from
            // the post-quiz delegation flow — those represent a real
            // commitment we shouldn't second-guess.
            if task.assignedContractorId != nil { continue }

            let resolved = resolveAssignment(template: template, preferenceTier: preferenceTier)
            let currentAssignment = (task.assignmentType ?? "either").lowercased()

            if resolved == .vendor && currentAssignment != "vendor" {
                // Flip personal/either → vendor. Look up a matching
                // contractor for the system category and reframe via
                // Phase 19l's voice. When no contractor exists, mark
                // needs_vendor and reframe as a "Find a contractor" CTA.
                let category = template.systemCategory
                let matching = contractors.first { contractor in
                    if let cat = contractor.category,
                       cat.caseInsensitiveCompare(category) == .orderedSame {
                        return true
                    }
                    if let specs = contractor.specialties,
                       specs.contains(where: { $0.caseInsensitiveCompare(category) == .orderedSame }) {
                        return true
                    }
                    return false
                }
                var update = MaintenanceTaskUpdate()
                update.assignmentType = "vendor"
                if let contractor = matching {
                    update.title = "Schedule \(contractor.companyName): \(template.title.lowercased())"
                    update.description = "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(template.description)"
                    update.assignedContractorId = contractor.id
                    update.needsVendor = false
                } else {
                    update.title = "Find a contractor for: \(template.title.lowercased())"
                    update.description = "We'll find you a vetted local pro for this. In the meantime, here's what they'll do:\n\n\(template.description)"
                    update.needsVendor = true
                }
                if (try? await DatabaseService.shared.updateMaintenanceTask(id: task.id, update)) != nil {
                    added.append(update.title ?? task.title)
                } else {
                    preserved.append(task.title)
                }
            } else if resolved == .personal && currentAssignment == "vendor" {
                // Flip vendor → personal. Restore the original template
                // title and description so the row reads like the canonical
                // personal task. Clear the needs_vendor flag.
                var update = MaintenanceTaskUpdate()
                update.assignmentType = "either"
                update.title = template.title
                update.description = template.description
                update.needsVendor = false
                if (try? await DatabaseService.shared.updateMaintenanceTask(id: task.id, update)) != nil {
                    removed.append(task.title)
                } else {
                    preserved.append(task.title)
                }
            }
        }

        return ReconciliationResult(added: added, removed: removed, preserved: preserved)
    }

    /// Deterministic personal vs vendor decision for `.either` templates
    /// given the user's 3-tier preference. Templates outside `.either`
    /// short-circuit to their hardcoded type.
    ///
    /// - `.diy`: Everything stays personal — user handles it all.
    /// - `.mixed`: Tasks over 30 min effort go to vendor, quick ones stay personal.
    /// - `.hireOut`: Everything goes to vendor — user's list is just coordination.
    static func resolveAssignment(
        template: MaintenanceTemplate,
        preferenceTier: VendorPreferenceTier
    ) -> TaskAssignmentType {
        guard template.assignmentType == .either else {
            return template.assignmentType
        }
        switch preferenceTier {
        case .diy:
            return .personal
        case .mixed:
            let effort = template.diyEffortMinutes ?? 60
            return effort > 30 ? .vendor : .personal
        case .hireOut:
            return .vendor
        }
    }

    /// Extract the user's vendor preference tier from a `PropertyRow`'s
    /// attributes JSONB. Reads the new `vendor_preference_tier` string
    /// first, falls back to the legacy `vendor_preference_level` int,
    /// defaults to `.mixed` when neither is set.
    static func preferenceTierFromProperty(_ property: PropertyRow?) -> VendorPreferenceTier {
        // New string attribute takes priority
        if let tierAttr = property?.attributes?["vendor_preference_tier"] {
            let tier = VendorPreferenceTier.fromAttribute(tierAttr.stringValue)
            return tier
        }
        // Legacy int fallback
        if let levelAttr = property?.attributes?["vendor_preference_level"] {
            return VendorPreferenceTier.fromAttribute(levelAttr.stringValue)
        }
        return .mixed
    }

    // MARK: - Helpers

    /// Build 88: factored-out title/description/assignment resolution for
    /// a single standalone template. Returns the final fields the insert
    /// row needs. Used by both the standalone and (indirectly) bundled
    /// creation paths.
    private struct TaskFields {
        let title: String
        let description: String
        let assignmentType: String
        let contractorId: UUID?
        let needsVendor: Bool
    }

    private static func createTaskFields(
        template: MaintenanceTemplate,
        preferenceTier: VendorPreferenceTier,
        matchingContractor: ContractorRow?
    ) -> TaskFields {
        switch template.assignmentType {
        case .personal:
            return TaskFields(
                title: template.title,
                description: template.description,
                assignmentType: "personal",
                contractorId: nil,
                needsVendor: false
            )

        case .vendor:
            if let contractor = matchingContractor {
                return TaskFields(
                    title: "Schedule \(contractor.companyName): \(template.title.lowercased())",
                    description: "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(template.description)",
                    assignmentType: "vendor",
                    contractorId: contractor.id,
                    needsVendor: false
                )
            } else {
                return TaskFields(
                    title: "Find a contractor for: \(template.title.lowercased())",
                    description: "We'll find you a vetted local pro for this. In the meantime, here's what they'll do:\n\n\(template.description)",
                    assignmentType: "vendor",
                    contractorId: nil,
                    needsVendor: true
                )
            }

        case .either:
            let resolved = resolveAssignment(
                template: template,
                preferenceTier: preferenceTier
            )
            if resolved == .vendor {
                if let contractor = matchingContractor {
                    return TaskFields(
                        title: "Schedule \(contractor.companyName): \(template.title.lowercased())",
                        description: "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(template.description)",
                        assignmentType: "vendor",
                        contractorId: contractor.id,
                        needsVendor: false
                    )
                } else {
                    return TaskFields(
                        title: "Find a contractor for: \(template.title.lowercased())",
                        description: "We'll find you a vetted local pro for this. In the meantime, here's what they'll do:\n\n\(template.description)",
                        assignmentType: "vendor",
                        contractorId: nil,
                        needsVendor: true
                    )
                }
            } else {
                return TaskFields(
                    title: template.title,
                    description: template.description,
                    assignmentType: "either",
                    contractorId: nil,
                    needsVendor: false
                )
            }
        }
    }

    /// `true` if the user has clearly engaged with the task in a way the
    /// reconciler must not stomp on. Reconciler-driven deletions only run
    /// when this returns `false`.
    private static func isUserTouched(_ task: MaintenanceTaskDBRow) -> Bool {
        if let last = task.lastCompletedDate, !last.isEmpty { return true }
        if task.assignedToUserId != nil { return true }
        // Build 88: bundled tasks store their checklist in notes
        // ("What's included:\n- ...") — that's template-generated, not
        // user-authored. Only treat notes as user-touched when they
        // DON'T start with the bundle checklist prefix.
        if let notes = task.notes, !notes.isEmpty,
           !notes.hasPrefix("What's included:") { return true }
        return false
    }
}
