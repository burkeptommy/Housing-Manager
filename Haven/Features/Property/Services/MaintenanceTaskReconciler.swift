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
    ///
    /// `preferredContractorId` lets the caller pass the system's explicit
    /// vendor pick (captured in `home_systems.preferred_contractor_id`) so
    /// the new-task path links that vendor even when its `category` string
    /// doesn't exactly match the system's category. This matches what the
    /// maintenance task detail sheet already does: it stamps the
    /// preferred_contractor_id on the system whenever a user assigns a
    /// vendor to any of its tasks. Before this hook, a Well System with
    /// "Rick's Pump" saved as its preferred contractor would still get
    /// "Find a contractor for:" tasks because the contractor's category
    /// was "Plumbing" or "Well" rather than "Well System".
    static func reconcile(
        propertyId: UUID,
        householdId: UUID,
        systemId: UUID?,
        systemCategory: String,
        confirmedSubtype: String?,
        fuelType: String? = nil,
        flags: [String: Bool] = [:],
        mode: ReconcileMode = .full,
        preferredContractorId: UUID? = nil
    ) async -> ReconciliationResult {
        // Phase 19j: Fetch the property once so template `{city}` and
        // `{state}` placeholders can be substituted with the user's actual
        // location before tasks are written. Failures fall back to generic
        // "your area" / "your state" so the reconciler still runs offline.
        // Also reads the vendor preference tier so the per-template
        // assignment for `.either` templates honors the user's choice.
        let property = try? await DatabaseService.shared.fetchProperty(id: propertyId)
        let preferenceTier = preferenceTierFromProperty(property)

        // Phase 57: Resolve the property's regional maintenance pack so the
        // template filter excludes regionally-gated templates that don't
        // apply here. The stored `regional_pack` column takes precedence;
        // we fall back to deriving it from state for properties saved
        // before the Phase 57 backfill ran.
        let regionalPack: RegionalPack? = {
            if let stored = property?.regionalPack,
               let parsed = RegionalPack(rawValue: stored) {
                return parsed
            }
            return RegionalPack(state: property?.state)
        }()

        // Phase 57: HNW subtype flags live in `properties.attributes` as
        // "true"/"false" strings. Merge them into the caller-supplied
        // `flags` dict so `activeSubtypes` can gate templates on property-
        // level state (has_humidifier, has_ev_charger, has_radon_mitigation,
        // has_central_vacuum, has_leak_detector, has_whole_house_filter,
        // has_built_in_grill, has_outdoor_lighting, has_pool_safety_fence,
        // has_pets). Caller flags win when both are present — the House
        // Quiz passes its own `has_pets` for Q28b's post-answer reconcile
        // before the attribute has been written.
        let propertyFlagKeys: [String] = [
            "has_humidifier", "has_ev_charger", "has_radon_mitigation",
            "has_central_vacuum", "has_leak_detector", "has_whole_house_filter",
            "has_built_in_grill", "has_outdoor_lighting", "has_pool_safety_fence",
            "has_pets",
            // Phase 62 additions
            "has_mature_trees", "has_fridge_water_dispenser", "has_sump_battery_backup"
        ]
        var mergedFlags = flags
        for key in propertyFlagKeys where mergedFlags[key] == nil {
            if property?.attributes?[key]?.stringValue == "true" {
                mergedFlags[key] = true
            }
        }
        // Phase 62: driveway_material is a single-choice attribute (not
        // yes/no), so translate "asphalt" → driveway_asphalt flag. All
        // other values (concrete / paver / gravel / other) leave the flag
        // unset so the seal-coat template stays gated to asphalt homes.
        if mergedFlags["driveway_asphalt"] == nil,
           property?.attributes?["driveway_material"]?.stringValue == "asphalt" {
            mergedFlags["driveway_asphalt"] = true
        }

        // 1. Compute the correct set of templates for the confirmed subtype.
        let activeSubtypes = MaintenanceTemplates.activeSubtypes(
            category: systemCategory,
            subtype: confirmedSubtype,
            fuelType: fuelType,
            flags: mergedFlags
        )
        let rawTemplates = MaintenanceTemplates.essentialTemplates(
            for: systemCategory,
            activeSubtypes: activeSubtypes,
            regionalPack: regionalPack
        )

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

        // Phase 67E/F: handyman-tier templates are routed to
        // `handyman_punch_items` instead of `maintenance_tasks`. Load
        // the household's pending punch items so we can dedupe by
        // `source_template_key` across reruns. RLS scopes to the
        // current household automatically. Best-effort — falls back to
        // an empty set if the fetch fails so the reconciler still makes
        // forward progress.
        let existingPunchItems = (try? await DatabaseService.shared.fetchPendingHandymanPunchItems(
            householdId: householdId
        )) ?? []
        let existingPunchItemTemplateKeys = Set(existingPunchItems.compactMap { $0.sourceTemplateKey })

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
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            // Find a matching contractor for the system's category (used
            // by both standalone and bundled paths).
            //
            // Precedence:
            //   1. The system's explicit `preferredContractorId` — honors
            //      whatever vendor the user last assigned via the task
            //      detail sheet, even when its stored category string
            //      doesn't line up with the system's category label.
            //   2. Category match on the contractor's `category` column.
            //   3. Specialty match on the contractor's `specialties` array.
            let matchingContractor: ContractorRow? = {
                if let prefId = preferredContractorId,
                   let pref = allContractors.first(where: { $0.id == prefId }) {
                    return pref
                }
                return allContractors.first { contractor in
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
            }()

            // Phase 65 read path: fetch routing_preferences for this
            // (household, property) once, then apply per-template within the
            // loop. Template-level overrides beat category-level, which in
            // turn beats the Q36 tier fallback. Nil if fetch fails — no
            // preferences applied in that case, existing behavior preserved.
            let routingPrefs: [RoutingPreferenceRow] = (try? await DatabaseService.shared.fetchRoutingPreferences(
                householdId: householdId,
                propertyId: propertyId
            )) ?? []
            // Phase 63 handyman preference for .diyDefault default-routing.
            let handymanPreference = property?.attributes?["handyman_preference"]?.stringValue

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

                // Phase 67E/F: handyman-tier templates land directly as
                // `handyman_punch_items` rows, never `maintenance_tasks`.
                // The five-tier model says small DIY-capable items
                // (≤60 min, no safety floor, no bundle) belong on the
                // single handyman rail, where the homeowner accumulates
                // them and the handyman handles the batch on a seasonal
                // visit. Routes here BEFORE assignment resolution so the
                // task table never sees them. Dedup by
                // `source_template_key` against pending punch items.
                let isHandymanTier =
                    !template.safetyFloor &&
                    template.bundleId == nil &&
                    (template.routingOverride == .diyDefault || template.routingOverride == .diyCapable) &&
                    (template.diyEffortMinutes ?? 0) <= 60

                if isHandymanTier {
                    if !existingPunchItemTemplateKeys.contains(templateKey) {
                        var punchInsert = HandymanPunchItemInsert(
                            householdId: householdId,
                            propertyId: propertyId,
                            title: template.title
                        )
                        punchInsert.description = template.description
                        punchInsert.notes = template.notes
                        punchInsert.estimatedMinutes = template.diyEffortMinutes
                        punchInsert.estimatedCostRange = template.estimatedCostRange
                        punchInsert.source = "auto_seed_handyman_tier"
                        punchInsert.sourceTemplateKey = templateKey
                        if (try? await DatabaseService.shared.createHandymanPunchItem(punchInsert)) != nil {
                            added.append(template.title)
                        }
                    }
                    continue
                }

                let result = createTaskFields(
                    template: template,
                    preferenceTier: preferenceTier,
                    matchingContractor: matchingContractor
                )

                let nextDue = initialDueDate(for: template)
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
                // Phase 64 + 65 route resolution: template-level override →
                // category-level preference → active contract → handyman-
                // preference default for .diyDefault → nil (picker shows).
                insert.assignedRoute = resolveAssignedRoute(
                    template: template,
                    templateKey: templateKey,
                    category: systemCategory,
                    preferences: routingPrefs,
                    matchingContractor: matchingContractor,
                    handymanPreference: handymanPreference,
                    assignmentType: result.assignmentType
                )
                if (try? await DatabaseService.shared.createMaintenanceTask(insert)) != nil {
                    added.append(result.title)
                }
            }

            // --- Bundled templates ---
            // Each bundle creates ONE parent task. The templateId is the bundleId
            // so dedup works at the bundle level.
            //
            // Phase 67 refactor: parent and child creation are now decoupled.
            // The parent is created when neither the bundleId nor any pre-
            // bundle member already exists. Children are created per-member
            // regardless of parent state, so existing bundles from Phase 58
            // get their Phase 67 children materialized on the next reconcile.
            for (bundleId, members) in bundleGroups {
                let parentExists = existingTemplateIds.contains(bundleId)
                // "Pre-bundle member exists" = some user has a legacy
                // standalone task for one of the bundle children from
                // before the bundle was introduced. In that case we skip
                // parent creation to avoid a duplicate visit, but we STILL
                // iterate children for per-member materialization below.
                let anyPreBundleMemberExists = members.contains { (_, raw, _) in
                    existingTemplateIds.contains(raw.templateKey)
                }

                guard let firstMember = members.first else { continue }
                let (_, _, firstTemplate) = firstMember

                // Only create parent when it's genuinely new.
                let shouldCreateParent = !parentExists && !anyPreBundleMemberExists

                // Resolve the bundle title from the first member that has one.
                let title = members.compactMap({ $0.2.bundleTitle }).first
                    ?? firstTemplate.title

                // Phase 67H: read homeowner-added custom subitems for
                // this bundle. Two flavors:
                //   * recurrence='always' — always-pending; appended on
                //     every fire of the bundle parent
                //   * recurrence='once' — pending only until attached
                //     to a specific bundle parent task; archived when
                //     that parent completes (see `markOnceSubitemsUsed`)
                // Both render as bullets under a "Custom additions"
                // sub-heading inside the parent task's notes.
                let customSubitems: [BundleCustomSubitemRow] = (try? await DatabaseService.shared.fetchBundleCustomSubitems(
                    householdId: householdId,
                    propertyId: propertyId,
                    bundleId: bundleId
                )) ?? []
                let pendingCustomSubitems = customSubitems.filter { $0.isPending }

                // Build the "What's included:" checklist from all member titles.
                let checklist = members.map { "- \($0.2.title)" }.joined(separator: "\n")
                var bundleNotes = "What's included:\n\(checklist)"
                if !pendingCustomSubitems.isEmpty {
                    let customLines = pendingCustomSubitems.map { "- \($0.title)" }.joined(separator: "\n")
                    bundleNotes += "\n\nCustom additions:\n\(customLines)"
                }

                // The bundle is always vendor (bundled = service visit).
                // Use the same contractor matching as standalone vendor tasks.
                let bundleTitle: String
                let bundleDescription: String
                let contractorId: UUID?
                let needsVendor: Bool

                if let contractor = matchingContractor {
                    bundleTitle = title
                    bundleDescription = "\(contractor.companyName) will handle the work.\n\n\(bundleNotes)"
                    contractorId = contractor.id
                    needsVendor = false
                } else {
                    bundleTitle = title
                    bundleDescription = bundleNotes
                    contractorId = nil
                    needsVendor = true
                }

                let nextDue = initialDueDate(for: firstTemplate)
                if shouldCreateParent {
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
                    // Phase 64: bundle tasks are always vendor-routed. Category
                    // preferences still apply (user may have overridden the
                    // category to handyman for small-bundle work).
                    insert.assignedRoute = resolveAssignedRoute(
                        template: firstTemplate,
                        templateKey: bundleId,
                        category: systemCategory,
                        preferences: routingPrefs,
                        matchingContractor: matchingContractor,
                        handymanPreference: handymanPreference,
                        assignmentType: "vendor"
                    )
                    if let createdParent = try? await DatabaseService.shared.createMaintenanceTask(insert) {
                        added.append(bundleTitle)
                        // Phase 67H: attach any pending recurrence='once'
                        // subitems to this newly-created bundle parent so
                        // the next bundle fire doesn't re-show them. They
                        // get archived when the parent completes.
                        let onceIds = pendingCustomSubitems
                            .filter { $0.recurrence == "once" }
                            .map { $0.id }
                        if !onceIds.isEmpty {
                            try? await DatabaseService.shared.attachOnceSubitemsToBundleTask(
                                ids: onceIds,
                                taskId: createdParent.id
                            )
                        }
                    }
                }

                // Phase 67: materialize each bundle MEMBER as its own
                // maintenance_tasks row so HandymanVisitDetailView can
                // query and render claims / upsells individually. Member
                // rows carry the bundleId, `.bundledIntoParent` routing
                // (hides from main lists until claimed), and default to
                // assigned_route="handyman" so the visit detail's
                // "What's included" section picks them up.
                //
                // Dedup: skip member insert if a row with that templateKey
                // already exists for this property OR if its stableId
                // conflicts. Reconciler's existing templateKey-based
                // matching handles re-runs cleanly.
                for (_, _, memberTemplate) in members {
                    let memberKey = memberTemplate.templateKey
                    if existingTemplateIds.contains(memberKey) { continue }
                    var childInsert = MaintenanceTaskInsert(
                        householdId: householdId,
                        title: memberTemplate.title,
                        frequency: memberTemplate.frequency,
                        nextDueDate: formatter.string(from: nextDue)
                    )
                    childInsert.propertyId = propertyId
                    childInsert.systemId = systemId
                    childInsert.description = memberTemplate.description
                    childInsert.priority = memberTemplate.priority
                    childInsert.isTemplateBased = true
                    childInsert.templateId = memberKey
                    childInsert.seasonalTiming = memberTemplate.seasonalTiming
                    childInsert.isDiy = memberTemplate.isDIY
                    childInsert.professionalRequired = memberTemplate.professionalRequired
                    childInsert.costRange = memberTemplate.estimatedCostRange
                    childInsert.assignmentType = "vendor"
                    childInsert.needsVendor = needsVendor
                    childInsert.assignedContractorId = contractorId
                    // Child is in the bundle → handyman route by default.
                    childInsert.assignedRoute = "handyman"
                    _ = try? await DatabaseService.shared.createMaintenanceTask(childInsert)
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
                // Phase 58 fix: previously this guard checked whether the
                // task's title was in the CURRENT template library for the
                // category — which meant fossils from deleted templates
                // (Phase 58 kills/demotes) and bundle parents whose DB
                // title is a bundleTitle not a template title, all got
                // skipped as "custom user tasks." Actual custom user tasks
                // never have `is_template_based = true` or a `template_id`,
                // so trust those flags first and fall back to title
                // matching only for pre-Phase-14 legacy rows that have
                // neither set.
                let isTemplateManaged: Bool = {
                    if task.isTemplateBased == true { return true }
                    if task.templateId != nil { return true }
                    return knownTitlesForCategory.contains(task.title.lowercased())
                }()
                guard isTemplateManaged else {
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
                flags: [:],
                preferredContractorId: system.preferredContractorId
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

        await ServiceOrchestrator.backfillServiceMetadata(
            propertyId: propertyId,
            householdId: householdId
        )

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
                    update.title = template.title
                    update.description = "\(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(template.description)"
                    update.assignedContractorId = contractor.id
                    update.needsVendor = false
                } else {
                    update.title = template.title
                    update.description = "What they'll do:\n\(template.description)"
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
    /// Phase 50: a `safetyFloor: true` template ALWAYS resolves to `.vendor`
    /// regardless of preference tier. This catches the small set of tasks
    /// that are flat-out unsafe to hand to a homeowner — gas, electrical
    /// panel, roof, septic, well, chimney — even if they've told us they
    /// like doing things themselves.
    ///
    /// - `.diy`: Everything stays personal — user handles it all.
    /// - `.mixed`: Tasks over 30 min effort go to vendor, quick ones stay personal.
    /// - `.hireOut`: Everything goes to vendor — user's list is just coordination.
    static func resolveAssignment(
        template: MaintenanceTemplate,
        preferenceTier: VendorPreferenceTier
    ) -> TaskAssignmentType {
        if template.safetyFloor { return .vendor }
        // Phase 55.2: `routingOverride: .diyDefault` is a hard floor
        // for the personal lane. Monthly filter swaps / weather-
        // stripping walks / generator oil checks / wine cellar reads
        // are quick, physical, and the-user-is-already-there chores
        // that shouldn't get flipped to a vendor for `.hireOut` users.
        // The 54A reframing was letting `.either + .diyDefault`
        // templates drift to vendor, producing "Tyler Heating ·
        // Twice a year" rows on a monthly DIY template.
        if template.routing == .diyDefault { return .personal }
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

    /// Phase 50: Centralized due-date computation. Resolves the next
    /// due date for a maintenance task by walking a fixed precedence:
    ///
    ///   1. The system's `service_interval_days` override (manual,
    ///      onboarding, or vendor_invoice provenance) — if set, the
    ///      template's frequency is bypassed entirely.
    ///   2. The matched template's `interval` (the canonical default).
    ///   3. The task row's `frequency` string parsed by
    ///      `MaintenanceTemplate.interval` semantics — handles legacy
    ///      and custom rows that have no template or system match.
    ///
    /// `from` is the baseline (typically the last completion date or
    /// today). Returns nil only when the inputs are catastrophically
    /// malformed; callers should fall back to today + 1 year.
    static func nextDueDate(
        for task: MaintenanceTaskDBRow,
        system: HomeSystemRow?,
        from baseline: Date
    ) -> Date? {
        // 1. System-level override
        if let interval = system?.serviceIntervalDays, interval > 0 {
            return Calendar.current.date(byAdding: .day, value: interval, to: baseline)
        }
        // 2. Matched template interval
        if let templateKey = task.templateId,
           let template = MaintenanceTemplates.template(forKey: templateKey) {
            return Calendar.current.date(byAdding: template.interval, to: baseline)
        }
        // 3. Parse the task's own frequency string. We synthesize a
        //    minimal placeholder template just to reuse the existing
        //    interval-from-string mapping.
        let placeholder = MaintenanceTemplate(
            systemCategory: "",
            title: task.title,
            description: "",
            frequency: task.frequency,
            priority: task.priority ?? "Medium",
            estimatedCostRange: "",
            isDIY: task.isDiy ?? false,
            seasonalTiming: nil,
            professionalRequired: task.professionalRequired ?? false,
            notes: nil
        )
        return Calendar.current.date(byAdding: placeholder.interval, to: baseline)
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

    /// Phase 67: One-time backfill that materializes bundle child rows for
    /// existing TestFlight users whose Handyman:spring / Handyman:fall parent
    /// tasks were created BEFORE children-as-rows shipped. Walks every
    /// property, re-runs `reconcileAll` which now creates bundle children
    /// alongside parents. The reconciler's templateKey dedup short-circuits
    /// on second-pass runs so this is idempotent.
    ///
    /// Gated via UserDefaults so it runs exactly once per install.
    @MainActor
    static func materializeHandymanBundleChildrenOnceIfNeeded() async {
        // v2: v1 shipped with a reconciler that skipped child creation when
        // the bundle parent already existed, so TestFlight users never got
        // their children materialized. Bumping the key force-runs the
        // fixed reconciler on every install to backfill.
        let key = "hasRunPhase67BundleChildBackfill_v2"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            return
        }
        guard !properties.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        var addedTotal = 0
        for property in properties {
            let result = await reconcileAll(
                propertyId: property.id,
                householdId: property.householdId
            )
            addedTotal += result.added.count
        }

        if addedTotal > 0 {
            print("[Phase67Backfill] Materialized \(addedTotal) bundle children across \(properties.count) properties.")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 64 + 65 read path: resolves the assigned_route for a new task
    /// at creation time. Precedence (highest → lowest):
    ///   1. Template-level override (`scope_type = 'template'`, category = templateKey).
    ///   2. Category-level preference (`scope_type = 'category'`).
    ///   3. Active service contract → 'vendor' (implicit via `matchingContractor`).
    ///   4. Handyman preference for `.diyDefault` templates (`has_one` → 'handyman', `does_diy` → 'diy').
    ///   5. Template assignment type → 'vendor' / 'diy' (either → nil).
    ///   6. nil — picker surfaces on the task.
    static func resolveAssignedRoute(
        template: MaintenanceTemplate,
        templateKey: String,
        category: String,
        preferences: [RoutingPreferenceRow],
        matchingContractor: ContractorRow?,
        handymanPreference: String?,
        assignmentType: String
    ) -> String? {
        // 1. Template override.
        if let templatePref = preferences.first(where: {
            $0.scopeType == "template" && $0.taskCategory == templateKey
        }) {
            return templatePref.preferredRoute
        }
        // 2. Category preference.
        if let categoryPref = preferences.first(where: {
            $0.scopeType == "category" && $0.taskCategory.caseInsensitiveCompare(category) == .orderedSame
        }) {
            return categoryPref.preferredRoute
        }
        // 3. Active contract via matchingContractor.
        if matchingContractor != nil && assignmentType == "vendor" {
            return "vendor"
        }
        // 4. Handyman-preference default for Bucket 3.
        if template.routing == .diyDefault {
            switch handymanPreference {
            case "has_one": return "handyman"
            case "does_diy": return "diy"
            default: break
            }
        }
        // 5. Template assignment type.
        switch assignmentType {
        case "vendor": return "vendor"
        case "personal": return "diy"
        default: return nil  // either → let picker show
        }
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
                    title: template.title,
                    description: "\(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(template.description)",
                    assignmentType: "vendor",
                    contractorId: contractor.id,
                    needsVendor: false
                )
            } else {
                return TaskFields(
                    title: template.title,
                    description: "What they'll do:\n\(template.description)",
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
                        title: template.title,
                        description: "\(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(template.description)",
                        assignmentType: "vendor",
                        contractorId: contractor.id,
                        needsVendor: false
                    )
                } else {
                    return TaskFields(
                        title: template.title,
                        description: "What they'll do:\n\(template.description)",
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

    /// Phase 54C: Opt-in "Schedule it" path for a single template.
    /// Called from "Recommended for your home" when the user taps
    /// "Schedule it" on a non-essential template. Creates (or finds)
    /// a `home_systems` row for the template's category, then inserts
    /// a matching `maintenance_tasks` row with the Phase-54A seasonal
    /// anchor. Returns the created task id on success.
    ///
    /// Unlike the reconciler's category-wide pass, this one never
    /// touches other tasks on the property — it only adds the one the
    /// user picked. Dedup is by templateKey so re-tapping the same
    /// recommendation is a no-op (returns the existing task's id).
    @MainActor
    static func scheduleOptInTemplate(
        _ template: MaintenanceTemplate,
        propertyId: UUID,
        householdId: UUID
    ) async -> UUID? {
        let db = DatabaseService.shared

        // 1. Find or create the home_systems row for this category.
        //    Auto-created rows match the Phase 54A auto-create pattern
        //    (name uses the registry's displayName fallback).
        let systems = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
        let category = template.systemCategory
        let existingSystem = systems.first(where: {
            $0.category.caseInsensitiveCompare(category) == .orderedSame
                && $0.parentSystemId == nil
        })

        let systemId: UUID?
        if let existingSystem {
            systemId = existingSystem.id
        } else {
            let displayName = SystemCategoryRegistry.metaForCategory(category)?.displayName
                ?? category
            let insert = HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: displayName,
                category: category,
                notes: "Auto-created from Recommended for your home."
            )
            if let created = try? await db.createHomeSystem(insert) {
                systemId = created.id
            } else {
                systemId = nil
            }
        }

        // 2. Check dedup — the user may tap "Schedule it" twice by
        //    accident, and a template already scheduled via the
        //    reconciler should stay one row.
        let existingTasks = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
        if let existing = existingTasks.first(where: {
            $0.templateId == template.templateKey && $0.isArchived != true
        }) {
            return existing.id
        }

        // 3. Interpolate and build the insert. Vendor-managed templates
        //    go to "Find a contractor" when there's no matching
        //    contractor on file, mirroring the reconciler's branch.
        let property = try? await db.fetchProperty(id: propertyId)
        let interpolated = template.interpolated(city: property?.city, state: property?.state)
        let contractors = (try? await db.fetchContractors()) ?? []
        let matching = contractors.first { contractor in
            if let cat = contractor.category,
               cat.caseInsensitiveCompare(category) == .orderedSame { return true }
            if let specs = contractor.specialties,
               specs.contains(where: { $0.caseInsensitiveCompare(category) == .orderedSame }) {
                return true
            }
            return false
        }

        let fields = createTaskFields(
            template: interpolated,
            preferenceTier: preferenceTierFromProperty(property),
            matchingContractor: matching
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nextDue = initialDueDate(for: interpolated)

        var insert = MaintenanceTaskInsert(
            householdId: householdId,
            title: fields.title,
            frequency: interpolated.frequency,
            nextDueDate: formatter.string(from: nextDue)
        )
        insert.propertyId = propertyId
        insert.systemId = systemId
        insert.description = fields.description
        insert.priority = interpolated.priority
        insert.isTemplateBased = true
        insert.templateId = interpolated.templateKey
        insert.seasonalTiming = interpolated.seasonalTiming
        insert.isDiy = interpolated.isDIY
        insert.professionalRequired = interpolated.professionalRequired
        insert.costRange = interpolated.estimatedCostRange
        insert.assignedContractorId = fields.contractorId
        insert.assignmentType = fields.assignmentType
        insert.needsVendor = fields.needsVendor

        guard let row = try? await db.createMaintenanceTask(insert) else { return nil }
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        return row.id
    }

    /// Phase 54A: Compute the next due date for a brand-new template-based
    /// task. When `template.seasonalTiming` is set ("Spring", "Summer",
    /// "Fall", "Winter", "Spring/Fall"), walk forward to the next occurrence
    /// of that season's anchor month rather than naively adding the
    /// template's interval to today. This distributes annual and
    /// semi-annual tasks across the year instead of bunching them on the
    /// reconciler-run anniversary.
    ///
    /// Anchor months (Northern Hemisphere defaults — fine for Northeast US):
    ///   Spring → April 1
    ///   Summer → July 1
    ///   Fall   → October 1
    ///   Winter → January 1
    ///   Spring/Fall (semi-annual) → next of April 1 or October 1
    ///
    /// For sub-annual frequencies (Weekly, Monthly, Quarterly, etc.),
    /// seasonal timing is ignored and the standard `today + interval` math
    /// applies — those are pace tasks, not seasonal tasks.
    static func initialDueDate(
        for template: MaintenanceTemplate,
        today: Date = Date()
    ) -> Date {
        let calendar = Calendar.current

        let isAnnualOrLonger: Bool = {
            switch template.frequency.lowercased() {
            case "annually", "annually (spring)", "annually (fall)",
                 "semi-annually", "twice yearly",
                 "every 2 years", "every 2-3 years", "every 3 years",
                 "every 3-5 years", "every 5 years", "every 5-7 years",
                 "every 10 years", "every 10-15 years":
                return true
            default:
                return false
            }
        }()

        guard isAnnualOrLonger,
              let timing = template.seasonalTiming?.lowercased(),
              !timing.isEmpty else {
            return calendar.date(byAdding: template.interval, to: today) ?? today
        }

        let candidateMonths: [Int] = {
            switch timing {
            case "spring":            return [4]
            case "summer":            return [7]
            case "fall", "autumn":    return [10]
            case "winter":            return [1]
            case "spring/fall":       return [4, 10]
            default:                  return []
            }
        }()

        guard !candidateMonths.isEmpty else {
            return calendar.date(byAdding: template.interval, to: today) ?? today
        }

        let currentYear = calendar.component(.year, from: today)
        var executionDates: [Date] = []
        for yearOffset in 0...1 {
            for month in candidateMonths {
                var comps = DateComponents()
                comps.year = currentYear + yearOffset
                comps.month = month
                comps.day = 1
                if let date = calendar.date(from: comps) {
                    executionDates.append(date)
                }
            }
        }

        // Phase 67C: PROACTIVE surfacing. Subtract the template's lead
        // time from each candidate execution anchor so the task appears
        // in the homeowner's list early enough to actually book a vendor
        // before peak-season slots fill up. A Spring HVAC tune-up
        // (Apr 1 anchor, 42-day lead) now surfaces around Feb 18 — the
        // homeowner has 6 weeks to schedule before April.
        let leadDays = template.effectiveLeadTimeDays
        let surfaceDates = executionDates.compactMap {
            calendar.date(byAdding: .day, value: -leadDays, to: $0)
        }

        // Earliest acceptable: at least 14 days out, so a freshly seeded
        // task isn't due tomorrow. If lead-time math produced a date in
        // the past for current-season tasks, accept the next future
        // surface date even if it's < 14 days out so the homeowner sees
        // the task surface as overdue, which is exactly right.
        let earliestAcceptable = calendar.date(byAdding: .day, value: 14, to: today) ?? today
        let valid = surfaceDates.filter { $0 >= earliestAcceptable }.sorted()
        if let pick = valid.first {
            return pick
        }
        if let nearest = surfaceDates.sorted().first(where: { $0 >= today }) {
            return nearest
        }
        return calendar.date(byAdding: template.interval, to: today) ?? today
    }

    /// Phase 54A: One-time re-dating pass for existing template-based tasks
    /// whose initial due dates were computed before the seasonal-seeding
    /// fix. Only touches tasks that are template-based, never been
    /// completed, never been manually rescheduled, and have a template
    /// with `seasonalTiming` set. Preserves user actions; the goal is
    /// strictly to redistribute the seed dates the buggy reconciler
    /// produced.
    @MainActor
    static func reseedSeasonalTasksOnceIfNeeded() async {
        let migrationKey = "hasRunSeasonalReseedP54A_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let db = DatabaseService.shared
        guard let tasks = try? await db.fetchAllMaintenanceTasks() else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var redated = 0
        for task in tasks {
            if let last = task.lastCompletedDate, !last.isEmpty { continue }
            if task.scheduledDate != nil { continue }
            if task.isArchived == true { continue }
            if task.vehicleId != nil { continue }

            guard let templateKey = task.templateId,
                  let template = MaintenanceTemplates.template(forKey: templateKey),
                  let timing = template.seasonalTiming,
                  !timing.isEmpty else { continue }

            let newDue = initialDueDate(for: template)
            let newDueString = formatter.string(from: newDue)

            if let currentDue = formatter.date(from: task.nextDueDate),
               abs(newDue.timeIntervalSince(currentDue)) < 30 * 86400 {
                continue
            }

            var update = MaintenanceTaskUpdate()
            update.nextDueDate = newDueString
            if (try? await db.updateMaintenanceTask(id: task.id, update)) != nil {
                redated += 1
            }
        }

        print("[Phase54A] Re-seeded \(redated) seasonal tasks")
        UserDefaults.standard.set(true, forKey: migrationKey)
        if redated > 0 {
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
    }

    /// Phase 54A: One-time backfill that consolidates pre-Phase-52
    /// individual tasks into the new bundle parents. Without this,
    /// existing TestFlight users see the old chore list forever because
    /// the reconciler refuses to create a bundle when any individual
    /// member exists.
    ///
    /// Phase 55.2: One-time fix for the HVAC filter-swap assignment
    /// leak. A Phase 54A regression let `assignmentType: .either` +
    /// `routingOverride: .diyDefault` templates drift to vendor for
    /// users on the `.hireOut` preference tier, so "Replace air
    /// filters" showed up as a Tyler-Heating twice-a-year task on
    /// some installs. The updated `resolveAssignment` now clamps
    /// `.diyDefault` to personal; this migration sweeps the
    /// previously-leaked rows back to personal / monthly / no vendor.
    @MainActor
    static func fixAirFilterAssignmentP55() async {
        let migrationKey = "hasFixedAirFilterAssignmentP55_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let db = DatabaseService.shared
        guard let tasks = try? await db.fetchAllMaintenanceTasks() else { return }

        var fixed = 0
        for task in tasks {
            let title = task.title.lowercased()
            // Match both the template's canonical title and the
            // "Schedule Tyler Heating:" reframe that the vendor flow
            // applied. Fallback: match on templateId prefix because
            // the title may drift.
            let isAirFilter =
                title.contains("replace air filter") ||
                title.contains("replace air filters") ||
                title.contains("hvac filter") ||
                (task.templateId?.lowercased() == "hvac:replace air filters")
            guard isAirFilter else { continue }
            guard task.assignmentType?.lowercased() == "vendor" else { continue }

            var update = MaintenanceTaskUpdate()
            update.assignmentType = "personal"
            update.frequency = "Monthly"
            update.assignedContractorId = nil
            update.needsVendor = false
            if (try? await db.updateMaintenanceTask(id: task.id, update)) != nil {
                fixed += 1
            }
        }

        print("[Phase55] Fixed \(fixed) air filter task assignments")
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    /// Strategy: per property, per known bundleId — find member tasks,
    /// archive them with a backfill reason, then create the bundle
    /// parent at the seasonally-correct date. Preserves user actions:
    /// any bundle that contains a user-touched member is left alone.
    @MainActor
    static func backfillBundlesOnceIfNeeded() async {
        let migrationKey = "hasRunBundleBackfillP54A_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let db = DatabaseService.shared
        guard let properties = try? await db.fetchProperties() else { return }

        // Build bundleId → [(templateKey, template)] index for every
        // bundled template across all categories.
        var bundleMembers: [String: [(String, MaintenanceTemplate)]] = [:]
        for (_, sectionTemplates) in MaintenanceTemplates.allTemplates {
            for template in sectionTemplates {
                guard let bid = template.bundleId else { continue }
                bundleMembers[bid, default: []].append((template.templateKey, template))
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var totalArchived = 0
        var totalCreated = 0

        let contractors = (try? await db.fetchContractors()) ?? []

        for property in properties {
            guard let tasks = try? await db.fetchMaintenanceTasks(propertyId: property.id) else { continue }
            let activeTasks = tasks.filter { $0.isArchived != true && $0.vehicleId == nil }
            let existingTemplateIds = Set(activeTasks.compactMap { $0.templateId })

            for (bundleId, members) in bundleMembers {
                // Skip if the bundle parent already exists
                if existingTemplateIds.contains(bundleId) { continue }

                // Find member tasks present today
                let memberTasks = activeTasks.filter { task in
                    guard let tid = task.templateId else { return false }
                    return members.contains(where: { $0.0 == tid })
                }
                guard !memberTasks.isEmpty else { continue }

                // Skip if any member is user-touched (completed, assigned,
                // or has notes that aren't a template checklist)
                let userTouched = memberTasks.contains { task in
                    if let last = task.lastCompletedDate, !last.isEmpty { return true }
                    if task.assignedToUserId != nil { return true }
                    if let notes = task.notes, !notes.isEmpty,
                       !notes.hasPrefix("What's included:") { return true }
                    return false
                }
                if userTouched { continue }

                // Pick the bundle's representative template
                let representative = members.first(where: { $0.1.bundleTitle != nil }) ?? members.first
                guard let (_, repTemplate) = representative else { continue }
                let bundleTitle = repTemplate.bundleTitle ?? repTemplate.title

                // Use the first member's systemId as the attach point
                let systemId: UUID? = memberTasks.first?.systemId

                // Category-match a contractor (same logic as reconciler)
                let category = repTemplate.systemCategory
                let matching = contractors.first { contractor in
                    if let cat = contractor.category,
                       cat.caseInsensitiveCompare(category) == .orderedSame { return true }
                    if let specs = contractor.specialties,
                       specs.contains(where: { $0.caseInsensitiveCompare(category) == .orderedSame }) { return true }
                    return false
                }

                let checklist = members.map { "- \($0.1.title)" }.joined(separator: "\n")
                let bundleNotes = "What's included:\n\(checklist)"

                let description: String
                let contractorId: UUID?
                let needsVendor: Bool
                if let contractor = matching {
                    description = "\(contractor.companyName) will handle the work.\n\n\(bundleNotes)"
                    contractorId = contractor.id
                    needsVendor = false
                } else {
                    description = bundleNotes
                    contractorId = nil
                    needsVendor = true
                }

                let nextDue = initialDueDate(for: repTemplate)

                var insert = MaintenanceTaskInsert(
                    householdId: property.householdId,
                    title: bundleTitle,
                    frequency: repTemplate.frequency,
                    nextDueDate: formatter.string(from: nextDue)
                )
                insert.propertyId = property.id
                insert.systemId = systemId
                insert.description = description
                insert.priority = repTemplate.priority
                insert.isTemplateBased = true
                insert.templateId = bundleId
                insert.seasonalTiming = repTemplate.seasonalTiming
                insert.isDiy = false
                insert.professionalRequired = true
                insert.costRange = repTemplate.estimatedCostRange
                insert.assignedContractorId = contractorId
                insert.assignmentType = "vendor"
                insert.needsVendor = needsVendor
                insert.notes = bundleNotes

                guard (try? await db.createMaintenanceTask(insert)) != nil else { continue }
                totalCreated += 1

                // Archive the individual member tasks
                for memberTask in memberTasks {
                    do {
                        try await db.archiveMaintenanceTask(
                            id: memberTask.id,
                            reason: "backfilled_to_bundle:\(bundleId)"
                        )
                        totalArchived += 1
                    } catch {
                        continue
                    }
                }
            }
        }

        print("[Phase54A] Bundle backfill: created \(totalCreated) bundles, archived \(totalArchived) members")
        UserDefaults.standard.set(true, forKey: migrationKey)
        if totalCreated > 0 || totalArchived > 0 {
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
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
