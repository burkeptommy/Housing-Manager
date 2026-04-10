import Foundation

/// Dispatcher that translates a HouseQuiz answer into the corresponding
/// database side-effects (properties.attributes, home_systems, vehicles,
/// utility_accounts, family_members, maintenance_tasks).
///
/// Real-time persistence: every question fires this immediately on tap so
/// progress is durable even if the user force-quits mid-quiz.
///
/// Phase 17b: questions that confirm a system subtype route through
/// `MaintenanceTaskReconciler`, which adds newly-applicable templates AND
/// soft-deletes templates that no longer match the confirmed subtype. Each
/// apply call returns a `ReconciliationResult` so the quiz view model can
/// sum changes across the whole flow and surface a "we tailored your plan"
/// summary at the end.
@MainActor
final class HouseQuizAnswerMapper {
    let householdId: UUID
    let propertyId: UUID
    private let db = DatabaseService.shared

    init(householdId: UUID, propertyId: UUID) {
        self.householdId = householdId
        self.propertyId = propertyId
    }

    /// Persist the answer's side effects and return any task changes the
    /// reconciler made on this answer. Errors are logged and swallowed —
    /// the quiz must keep moving even if a single side-effect write fails.
    @discardableResult
    func apply(
        question: HouseQuizQuestion,
        answer: HouseQuizAnswer
    ) async -> MaintenanceTaskReconciler.ReconciliationResult {
        var reconciliationResult: MaintenanceTaskReconciler.ReconciliationResult = .empty
        do {
            switch question.id {
            case "q1_roof_material":
                try await persistAttribute("roof_material", value: answer.answerId)
                if let mat = answer.answerId, mat != "not_sure" {
                    let subtype = Self.roofingSubtype(forQuizAnswer: mat)
                    let systemId = try await ensureHomeSystem(
                        name: "\(mat.replacingOccurrences(of: "_", with: " ").capitalized) Roof",
                        category: "Roofing",
                        subtype: subtype,
                        matchByCategory: true
                    )
                    let result = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: systemId,
                        systemCategory: "Roofing",
                        confirmedSubtype: subtype
                    )
                    reconciliationResult = reconciliationResult.merging(result)
                }

            case "q2_siding":
                try await persistAttribute("siding_material", value: answer.answerId)

            case "q3_heating_fuel":
                // Phase 19b: HVAC subtype is now driven by q3b_hvac_type, not
                // by a fuel heuristic. We still persist the fuel attribute for
                // Alfred's chat context and for q19's heating fuel provider
                // filtering. The HVAC system row + reconcile happens in q3b.
                try await persistAttribute("heating_fuel", value: answer.answerId)

            case "q3b_hvac_type":
                // Phase 19b/19c: dedicated HVAC type question. The user picks
                // their actual HVAC configuration so we don't have to guess
                // from the fuel type. "Not sure" flows through the same path
                // as every other answer — we still ensure the HVAC system row
                // and run the reconciler — but the stored subtype is
                // "not_sure" which `MaintenanceTemplates.activeSubtypes` maps
                // to `["has_ac", "has_furnace"]`. That activates universal
                // tune-up templates without unlocking topology-specific tasks
                // (bleed radiators, mini-split filter cleaning, etc.). The
                // user can confirm a real type later from Property →
                // Maintenance and the reconciler will swap tasks then.
                guard let typeId = answer.answerId else { break }
                try await persistAttribute("hvac_type", value: typeId)
                // Read the heating fuel from the previous question so the
                // reconciler has both pieces of context for templates that key
                // off `fuelType` (none today, but the field is plumbed).
                let hvacFuel = (try? await db.fetchProperty(id: propertyId))?
                    .attributes?["heating_fuel"]?.stringValue
                let hvacSystemId = try await ensureHomeSystem(
                    name: Self.hvacSystemName(for: typeId),
                    category: "HVAC",
                    subtype: typeId,
                    matchByCategory: true
                )
                let hvacResult = await MaintenanceTaskReconciler.reconcile(
                    propertyId: propertyId,
                    householdId: householdId,
                    systemId: hvacSystemId,
                    systemCategory: "HVAC",
                    confirmedSubtype: typeId,
                    fuelType: hvacFuel
                )
                reconciliationResult = reconciliationResult.merging(hvacResult)

            case "q4_purchase":
                if let custom = answer.customText, let price = Double(digitsOnly(custom)) {
                    var update = PropertyUpdate()
                    update.purchasePrice = price
                    if let kind = answer.answerId {
                        try await persistAttribute("purchase_kind", value: kind)
                    }
                    _ = try await db.updateProperty(id: propertyId, update)
                }

            case "q5_mortgage":
                let hasMortgage = answer.answerId == "yes"
                try await persistAttribute("has_mortgage", value: hasMortgage ? "yes" : "no")

            case "q6_water_source":
                try await persistAttribute("water_source", value: answer.answerId)
                if answer.answerId == "private_well" || answer.answerId == "shared_well" {
                    let wellId = try await ensureHomeSystem(name: "Well System", category: "Well System")
                    let wellResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: wellId,
                        systemCategory: "Well System",
                        confirmedSubtype: nil
                    )
                    reconciliationResult = reconciliationResult.merging(wellResult)
                }

            case "q7_sewer_septic":
                try await persistAttribute("sewer_or_septic", value: answer.answerId)
                if answer.answerId == "septic" {
                    let septicId = try await ensureHomeSystem(name: "Septic System", category: "Septic System")
                    let septicResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: septicId,
                        systemCategory: "Septic System",
                        confirmedSubtype: nil
                    )
                    reconciliationResult = reconciliationResult.merging(septicResult)
                }

            case "q8_water_heater":
                try await persistAttribute("water_heater_type", value: answer.answerId)
                let heaterName: String
                let heaterSubtype: String?
                switch answer.answerId {
                case "tank_gas", "tank_electric":
                    heaterName = "Water Heater"
                    heaterSubtype = "tank"
                case "tankless_gas", "tankless_electric":
                    heaterName = "Tankless Water Heater"
                    heaterSubtype = "tankless"
                case "heat_pump":
                    heaterName = "Heat Pump Water Heater"
                    heaterSubtype = "hybrid_heat_pump"
                default:
                    heaterName = "Water Heater"
                    heaterSubtype = nil
                }
                let heaterSystemId = try await ensureHomeSystem(
                    name: heaterName,
                    category: "Water Heater",
                    subtype: heaterSubtype,
                    matchByCategory: true
                )
                let heaterResult = await MaintenanceTaskReconciler.reconcile(
                    propertyId: propertyId,
                    householdId: householdId,
                    systemId: heaterSystemId,
                    systemCategory: "Water Heater",
                    confirmedSubtype: heaterSubtype
                )
                reconciliationResult = reconciliationResult.merging(heaterResult)

            case "q9_basement":
                // Multi-select today; older quiz state may have a legacy
                // single-choice answer with `answerId` set instead of
                // `selectedIds`. Treat both shapes the same downstream.
                let basementSelections: [String] = {
                    if let ids = answer.selectedIds, !ids.isEmpty { return ids }
                    if let id = answer.answerId { return [id] }
                    return []
                }()
                if !basementSelections.isEmpty {
                    try await persistAttribute(
                        "basement_type",
                        value: basementSelections.joined(separator: ",")
                    )
                }
                // Sump pump only matters when there's an actual basement (not
                // a crawl-space-only or slab home).
                if basementSelections.contains("finished_basement")
                    || basementSelections.contains("unfinished_basement") {
                    try await ensureHomeSystem(name: "Sump Pump", category: "Sump Pump")
                }
                if basementSelections.contains("crawl_space") {
                    try await ensureHomeSystem(name: "Crawl Space", category: "Crawl Space")
                }

            case "q10_appliances":
                if let selected = answer.selectedIds {
                    // The "other" id is just a placeholder that triggers the
                    // free-form text input — never persist it as an appliance.
                    let realSelections = selected.filter { $0 != "other" }
                    let customEntries = answer.customEntries ?? []
                    let combined = realSelections + customEntries
                    if !combined.isEmpty {
                        try await persistAttribute(
                            "appliances_under_5_years",
                            value: combined.joined(separator: ",")
                        )
                    }
                    for appliance in realSelections where appliance != "none" {
                        try await ensureHomeSystem(
                            name: appliance.replacingOccurrences(of: "_", with: " ").capitalized,
                            category: "Appliance"
                        )
                    }
                    // Each custom appliance ("Sauna", "Pellet stove", ...) gets
                    // its own home_system row in the Appliances group so it
                    // shows up alongside the picker-based ones in the Property
                    // -> Maintenance tab.
                    for custom in customEntries {
                        let trimmed = custom.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { continue }
                        try await ensureHomeSystem(name: trimmed, category: "Appliance")
                    }
                }

            case "q11_lawn":
                try await persistAttribute("lawn_status", value: answer.answerId)
                if answer.answerId == "diy" || answer.answerId == "pro" {
                    let lawnSystemId = try await ensureHomeSystem(
                        name: "Landscaping",
                        category: "Landscaping",
                        subtype: "lawn",
                        matchByCategory: true
                    )
                    // Build 87: mirror q13_pest ordering. Create the utility
                    // account + contractor BEFORE the reconciler runs so
                    // `.vendor`-tagged landscaping templates auto-link at
                    // task-creation time instead of landing as "Find a
                    // contractor for: ..." placeholders.
                    // Build 87 (search picker): use the catalog-aware path when
                    // the user picked from the search picker so the full brand
                    // identity (logo, brand color, website) lands on the row.
                    if answer.answerId == "pro", let provider = answer.customText, !provider.isEmpty {
                        if answer.selectedProviderId != nil {
                            try await createUtilityAccount(from: answer, fallbackType: "landscaping")
                        } else {
                            try await createUtilityAccount(name: provider, type: "landscaping")
                        }
                    }
                    let lawnResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: lawnSystemId,
                        systemCategory: "Landscaping",
                        confirmedSubtype: "lawn"
                    )
                    reconciliationResult = reconciliationResult.merging(lawnResult)
                    // Build 87: when the user explicitly hired a pro lawn
                    // service, the DIY walkthroughs (grade check, weed
                    // spot-treat, etc.) should flow through the vendor too —
                    // a landscaping contractor covers these during routine
                    // visits. Mirrors the q13_pest flip pattern.
                    if answer.answerId == "pro", let provider = answer.customText, !provider.isEmpty {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Landscaping",
                            providerName: provider
                        )
                    }
                }
                // Build 84: hardscape-heavy outdoor spaces (stone patio, gravel
                // drive, paver walkways) instead of a traditional lawn. We
                // create a dedicated "Outdoor Hardscape" system + 4 real
                // maintenance tasks so HNW homeowners with stone-and-paver
                // yards see Haven schedule the right upkeep instead of
                // dropping outdoor maintenance entirely. Q11b is auto-skipped
                // for hardscape via dynamicSkip — this is the only place
                // hardscape side-effects are created.
                if answer.answerId == "hardscape" {
                    if let hardscapeSystemId = try await ensureHomeSystem(
                        name: "Outdoor Hardscape",
                        category: "Landscaping",
                        subtype: "hardscape"
                    ) {
                        try await createHardscapeMaintenanceTasks(systemId: hardscapeSystemId)
                    }
                }

            case "q11b_lawn_type":
                // Phase 19j: lawn material — natural / turf / mixed / not_sure.
                // Drives the maintenance schedule:
                //   - natural → aerate, overseed, fertilize, weed control, leaf cleanup
                //   - turf    → brush, infill top-up, deep clean, drainage check
                //   - mixed   → both
                // Persists `lawn_type` attribute and creates a Synthetic Turf
                // system row when turf or mixed so MaintenanceTemplates targeting
                // subtype "synthetic_turf" picks up the right tasks.
                try await persistAttribute("lawn_type", value: answer.answerId)
                guard let lawnType = answer.answerId, lawnType != "not_sure" else { break }

                // Phase 19j defensive: read has_pets from property attributes
                // in case the user already answered Q28b (e.g. resumed quiz
                // with reordered answers). Pass through to the reconciler so
                // the pet sanitize task fires correctly on first creation.
                let propertyForFlags = try? await db.fetchProperty(id: propertyId)
                let hasPetsFlag = propertyForFlags?.attributes?["has_pets"]?.stringValue == "true"
                let lawnFlags: [String: Bool] = hasPetsFlag ? ["has_pets": true] : [:]

                if lawnType == "turf" || lawnType == "mixed" {
                    let turfSystemId = try await ensureHomeSystem(
                        name: "Synthetic Turf",
                        category: "Landscaping",
                        subtype: "synthetic_turf"
                    )
                    let turfResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: turfSystemId,
                        systemCategory: "Landscaping",
                        confirmedSubtype: "synthetic_turf",
                        flags: lawnFlags
                    )
                    reconciliationResult = reconciliationResult.merging(turfResult)
                }

                // Tag the existing Landscaping system (if any) with the lawn
                // type as a subtype hint so future template lookups can branch.
                if lawnType == "natural" || lawnType == "mixed" {
                    let naturalLawnId = try await ensureHomeSystem(
                        name: "Landscaping",
                        category: "Landscaping",
                        subtype: "natural_lawn",
                        matchByCategory: true
                    )
                    let naturalResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: naturalLawnId,
                        systemCategory: "Landscaping",
                        confirmedSubtype: "natural_lawn"
                    )
                    reconciliationResult = reconciliationResult.merging(naturalResult)
                }

                // Build 87: q11b's reconciles above create additional
                // Landscaping tasks (dethatch, overseed, fall leaf
                // cleanup, brush turf, etc.) AFTER q11_lawn's vendor
                // flip already ran. If the user picked q11 = "pro" and
                // a landscaping contractor was mirrored, re-fire the
                // flip so the new tasks also land as vendor-managed
                // instead of cluttering the personal to-do list.
                //
                // We gate on the `lawn_status` attribute + the presence
                // of a landscaping utility_account (which only q11's
                // createUtilityAccount creates) to avoid confusing a
                // q15b tree_service contractor — which also lives under
                // the "Landscaping" category — with a lawn-service
                // contractor. q15b doesn't create utility_accounts, so
                // the account presence is the unique q11 signal.
                let lawnStatus = (try? await db.fetchProperty(id: propertyId))?
                    .attributes?["lawn_status"]?.stringValue
                if lawnStatus == "pro" {
                    let accounts = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
                    if let lawnAccount = accounts.first(where: {
                        $0.providerType.lowercased() == "landscaping"
                    }) {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Landscaping",
                            providerName: lawnAccount.providerName
                        )
                    }
                }

            case "q12_pool":
                // Build 87 (Edit 2): Pool vs Hot Tub split. The previous
                // build collapsed every Q12 answer into a single "Pool/Spa"
                // parent system with three pool-specific children, which
                // meant hot-tub-only households got nonsense Pool Pump /
                // Filter / Heater rows AND chlorine/salt templates leaking
                // through the activeSubtypes empty-default. The new model
                // creates DIFFERENT systems based on the answer:
                //
                //   hot_tub      → ONE "Hot Tub" system, subtype "hot_tub",
                //                  no children, hot-tub-only templates
                //   in_ground    → ONE "Pool" system, subtype "pool_inground",
                //                  3 children, full pool template suite
                //   above_ground → ONE "Pool" system, subtype "pool_above_ground",
                //                  3 children, full pool template suite
                //   both         → BOTH systems created separately. The
                //                  Pool ensureHomeSystem call uses
                //                  excludeSubtype: "hot_tub" so it never
                //                  collapses into the Hot Tub row.
                //
                // Q12b (`q12b_pool_chemistry`) downstream updates the Pool
                // row's subtype to include chemistry (e.g.
                // "pool_inground_chlorine"). Hot Tub never visits Q12b —
                // its dynamicSkip closure hides chemistry for hot-tub-only.
                try await persistAttribute("pool_type", value: answer.answerId)
                guard let id = answer.answerId, id != "none" else { break }

                let hasPool = id == "in_ground" || id == "above_ground" || id == "both"
                let hasHotTub = id == "hot_tub" || id == "both"

                if hasPool {
                    let poolSubtype: String
                    switch id {
                    case "in_ground": poolSubtype = "pool_inground"
                    case "above_ground": poolSubtype = "pool_above_ground"
                    case "both": poolSubtype = "pool_inground"  // Q12b will refine
                    default: poolSubtype = "pool_inground"
                    }
                    let parentId = try await ensureHomeSystem(
                        name: "Pool",
                        category: "Pool/Spa",
                        subtype: poolSubtype,
                        matchByCategory: true,
                        excludeSubtype: "hot_tub"
                    )
                    if let parentId {
                        try await ensureChildSystem(parentId: parentId, name: "Pool Pump", category: "Pool/Spa")
                        try await ensureChildSystem(parentId: parentId, name: "Pool Filter", category: "Pool/Spa")
                        try await ensureChildSystem(parentId: parentId, name: "Pool Heater", category: "Pool/Spa")
                    }
                    // Mirror q11/q13/q14/q15 ordering: create the utility
                    // account + contractor BEFORE the reconciler runs so
                    // `.vendor`-tagged Pool/Spa templates auto-link at
                    // task-creation time instead of landing as "Find a
                    // contractor for: ..." placeholders.
                    // Build 87 (search picker): catalog-aware path when
                    // the user picked from the search picker.
                    if let provider = answer.customText, !provider.isEmpty {
                        if answer.selectedProviderId != nil {
                            try await createUtilityAccount(from: answer, fallbackType: "pool_service")
                        } else {
                            try await createUtilityAccount(name: provider, type: "pool_service")
                        }
                    }
                    let poolResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: parentId,
                        systemCategory: "Pool/Spa",
                        confirmedSubtype: poolSubtype
                    )
                    reconciliationResult = reconciliationResult.merging(poolResult)
                    if let provider = answer.customText, !provider.isEmpty {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Pool/Spa",
                            providerName: provider
                        )
                    }
                }

                if hasHotTub {
                    // matchByCategory: false ensures we match by name "Hot Tub"
                    // explicitly instead of grabbing the first Pool/Spa row,
                    // which would collide with the Pool row in the "both"
                    // case. Without this, ensureHomeSystem would rename the
                    // Pool row to "Hot Tub" and overwrite its subtype.
                    let hotTubId = try await ensureHomeSystem(
                        name: "Hot Tub",
                        category: "Pool/Spa",
                        subtype: "hot_tub",
                        matchByCategory: false
                    )
                    let hotTubResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: hotTubId,
                        systemCategory: "Pool/Spa",
                        confirmedSubtype: "hot_tub"
                    )
                    reconciliationResult = reconciliationResult.merging(hotTubResult)
                }

            case "q12b_pool_chemistry":
                // Build 87 (Edit 2): pool chemistry follow-up. With the new
                // Pool vs Hot Tub split, the Pool row already has a pool-type
                // subtype (`pool_inground` / `pool_above_ground`). This case
                // composes the chemistry token into the existing subtype so
                // both pieces of information survive (e.g.
                // "pool_inground_chlorine"). `MaintenanceTemplates.activeSubtypes`
                // parses the composite to emit the umbrella "pool" token plus
                // the specific facets, which is what the AND-matching
                // `requiredSubtypes` filter needs to gate templates correctly.
                //
                // The Pool lookup uses `excludeSubtype: "hot_tub"` so even in
                // the rare "both" household this updates the Pool row, never
                // the Hot Tub. The Q12b dynamicSkip closure also hides this
                // question for hot-tub-only users so we never reach here for
                // them.
                try await persistAttribute("pool_chemistry", value: answer.answerId)

                let chemistryToken: String? = {
                    switch answer.answerId {
                    case "saltwater": return "pool_salt"
                    case "chlorine":  return "pool_chlorine"
                    default:          return nil
                    }
                }()
                guard let chemistryToken else { break }

                // Find the existing Pool top-level system (Q12 created it,
                // possibly with name "Pool" on build 87 or legacy "Pool/Spa"
                // on build 86). matchByCategory + excludeSubtype: "hot_tub"
                // makes this resilient to either name.
                let allSystemsForPoolLookup = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
                let existingPool: HomeSystemRow? = allSystemsForPoolLookup.first(where: {
                    $0.category.lowercased() == "pool/spa"
                    && $0.parentSystemId == nil
                    && $0.subtype != "hot_tub"
                })

                // Compose the new subtype: keep the existing pool-type token
                // (pool_inground / pool_above_ground) AND append chemistry.
                // For legacy build 86 rows whose subtype was empty or just
                // "chlorine"/"saltwater", we synthesize a composite by
                // defaulting to in_ground (the most common case). The
                // pool-type information is then recoverable from the pool_type
                // property attribute via the migration if needed.
                let priorSubtype = (existingPool?.subtype ?? "").lowercased()
                let poolTypeToken: String = {
                    if priorSubtype.contains("inground") || priorSubtype == "pool_inground" {
                        return "pool_inground"
                    }
                    if priorSubtype.contains("above_ground") || priorSubtype == "pool_above_ground" {
                        return "pool_above_ground"
                    }
                    return "pool_inground"  // legacy default
                }()
                let composedSubtype = "\(poolTypeToken)_\(chemistryToken.replacingOccurrences(of: "pool_", with: ""))"

                let poolParentId = try await ensureHomeSystem(
                    name: "Pool",
                    category: "Pool/Spa",
                    subtype: composedSubtype,
                    matchByCategory: true,
                    excludeSubtype: "hot_tub"
                )

                // Re-run the reconciler with the new composite subtype so
                // chemistry-gated templates land (Shock pool for chlorine,
                // Clean salt cell for saltwater). Existing Pool/Spa tasks
                // from Q12's first reconcile are preserved — the reconciler
                // dedups by templateKey.
                let poolChemistryResult = await MaintenanceTaskReconciler.reconcile(
                    propertyId: propertyId,
                    householdId: householdId,
                    systemId: poolParentId,
                    systemCategory: "Pool/Spa",
                    confirmedSubtype: composedSubtype
                )
                reconciliationResult = reconciliationResult.merging(poolChemistryResult)

                // Build 87: re-fire the vendor flip since Q12b's reconcile
                // creates NEW Pool/Spa tasks AFTER Q12's flip already ran.
                // Mirrors the q11/q11b second-flip pattern exactly. We
                // can't read Q12's answer from this scope (`apply` doesn't
                // get `state`), so we gate on the `pool_type` attribute
                // Q12 persists + find the pool provider via the
                // utility_accounts table (Q12's createUtilityAccount is
                // the unique signal — q15b_household_contractors doesn't
                // create utility accounts).
                let poolType = (try? await db.fetchProperty(id: propertyId))?
                    .attributes?["pool_type"]?.stringValue
                let hasPoolProvider = poolType == "in_ground"
                    || poolType == "above_ground"
                    || poolType == "both"
                if hasPoolProvider {
                    let poolAccounts = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
                    if let poolAccount = poolAccounts.first(where: {
                        $0.providerType.lowercased() == "pool_service"
                    }) {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Pool/Spa",
                            providerName: poolAccount.providerName
                        )
                    }
                }

            case "q13_pest":
                try await persistAttribute("pest_control", value: answer.answerId)
                if answer.answerId == "quarterly_pro" || answer.answerId == "termite_bond" {
                    let pestSystemId = try await ensureHomeSystem(
                        name: "Pest Control",
                        category: "Pest Control"
                    )
                    // Create the utility account first so the contractor
                    // mirror lands in the DB BEFORE the reconciler runs.
                    // The reconciler reads the contractors table at task-
                    // creation time and auto-links vendor-tagged pest
                    // templates to the matching contractor in one shot.
                    // Build 87 (search picker): catalog-aware path when
                    // the user picked from the search picker.
                    if let provider = answer.customText, !provider.isEmpty {
                        if answer.selectedProviderId != nil {
                            try await createUtilityAccount(from: answer, fallbackType: "pest_control")
                        } else {
                            try await createUtilityAccount(name: provider, type: "pest_control")
                        }
                    }
                    // Run the reconciler so Pest Control templates become
                    // real tasks. With the contractor mirrored above, the
                    // two `.vendor`-tagged templates get reframed + linked
                    // automatically. The two `.personal` templates still
                    // land as DIY, and we flip them to vendor-managed next.
                    let pestResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: pestSystemId,
                        systemCategory: "Pest Control",
                        confirmedSubtype: nil
                    )
                    reconciliationResult = reconciliationResult.merging(pestResult)
                    // Build 86: when the user explicitly hired a pro for
                    // pest control, the Inspect Foundation + Seal Gaps DIY
                    // walkthroughs should flow through the vendor too — a
                    // quarterly exterminator covers these during their
                    // visit. Flip any still-personal pest control tasks to
                    // vendor-managed now so the user isn't stuck with DIY
                    // tasks for a service they're already paying for. The
                    // task-detail "I'll do this myself" toggle (Phase 19l)
                    // lets them flip individual tasks back if they want.
                    if let provider = answer.customText, !provider.isEmpty {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Pest Control",
                            providerName: provider
                        )
                    }
                }

            case "q14_irrigation":
                try await persistAttribute("irrigation", value: answer.answerId)
                if answer.answerId == "full" || answer.answerId == "drip" {
                    let irrigationSystemId = try await ensureHomeSystem(
                        name: "Irrigation System",
                        category: "Irrigation"
                    )
                    // Build 87: mirror q13_pest ordering. Create the
                    // utility account + contractor BEFORE the reconciler
                    // runs so the two `.vendor`-tagged irrigation
                    // templates (winterize, spring startup) auto-link
                    // at task-creation time. Both "full" and "drip"
                    // answers go through this flip — the service type
                    // doesn't change whether a pro is handling it.
                    // Build 87 (search picker): catalog-aware path when
                    // the user picked from the search picker.
                    if let provider = answer.customText, !provider.isEmpty {
                        if answer.selectedProviderId != nil {
                            try await createUtilityAccount(from: answer, fallbackType: "irrigation")
                        } else {
                            try await createUtilityAccount(name: provider, type: "irrigation")
                        }
                    }
                    let irrigationResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: irrigationSystemId,
                        systemCategory: "Irrigation",
                        confirmedSubtype: nil
                    )
                    reconciliationResult = reconciliationResult.merging(irrigationResult)
                    // Build 87: flip any still-personal irrigation tasks
                    // (walk the zones, check heads) to vendor-managed so
                    // the pro covers them during their routine visits.
                    if let provider = answer.customText, !provider.isEmpty {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Irrigation",
                            providerName: provider
                        )
                    }
                }

            case "q15_security":
                try await persistAttribute("security_system", value: answer.answerId)
                if let id = answer.answerId, id != "none" {
                    let securitySystemId = try await ensureHomeSystem(
                        name: "Security System",
                        category: "Security System"
                    )
                    // Build 87: mirror q13_pest ordering. Create the
                    // utility account + contractor BEFORE the reconciler
                    // runs so any `.vendor`-tagged security templates
                    // auto-link at task-creation time. The vendor flip
                    // only fires when the user said "monitored" — self-
                    // monitored / cameras-only households don't have an
                    // alarm company to delegate tasks to, so their DIY
                    // tasks stay DIY.
                    let hasMonitoredProvider = id == "monitored"
                        && (answer.customText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                    // Build 87 (search picker): catalog-aware path when
                    // the user picked from the search picker.
                    if hasMonitoredProvider, let provider = answer.customText {
                        if answer.selectedProviderId != nil {
                            try await createUtilityAccount(from: answer, fallbackType: "security")
                        } else {
                            try await createUtilityAccount(name: provider, type: "security")
                        }
                    }
                    let securityResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: securitySystemId,
                        systemCategory: "Security System",
                        confirmedSubtype: nil
                    )
                    reconciliationResult = reconciliationResult.merging(securityResult)
                    // Build 87: flip any still-personal security tasks
                    // (replace sensor batteries, confirm camera clarity,
                    // update alarm codes) to vendor-managed when the
                    // household is paying for professional monitoring.
                    if hasMonitoredProvider, let provider = answer.customText {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Security System",
                            providerName: provider
                        )
                    }
                }

            case "q15b_household_contractors":
                // Phase 19m: persist each selected chip as an attribute and
                // create contractor rows for any with provider data. Chips
                // selected without a provider become needs_vendor flags so
                // future tasks render as "Find a contractor for: X".
                //
                // Build 83 (Apr 7, 2026): the view now encodes Q15b chip
                // selections in three shapes (the encoder lives in
                // `HouseQuizView.encodedContractorChipsEntries`):
                //   - manual / legacy:  "chip|name"  (2 parts)
                //   - vendor:           "chip|name|rating|reviews|phone|website|haven_flag"
                //                        (7 parts; rating/reviews/phone/website
                //                         may be empty strings)
                // Both shapes are accepted here; the parser is forgiving so
                // older persisted answers continue to round-trip.
                if let selected = answer.selectedIds {
                    try await persistAttribute(
                        "household_contractor_chips",
                        value: selected.joined(separator: ",")
                    )

                    if let entries = answer.customEntries {
                        let existing = (try? await db.fetchContractors()) ?? []
                        for entry in entries {
                            guard let parsed = Self.parseContractorChipEntry(entry) else { continue }
                            let chipId = parsed.chipId
                            let providerName = parsed.name
                            guard let category = Self.householdContractorCategoryFor(chipId: chipId) else { continue }

                            // Skip if a contractor with this name already
                            // exists in the household — quiz mirroring should
                            // never create duplicates.
                            if existing.contains(where: { $0.companyName.lowercased() == providerName.lowercased() }) {
                                continue
                            }

                            var insert = ContractorInsert(
                                householdId: householdId,
                                companyName: providerName,
                                phone: parsed.phone ?? "Not provided"
                            )
                            insert.category = category
                            insert.specialties = [category]
                            // Polish pass: Places-sourced (7-part entries)
                            // get source: "find_vendor"; manual / legacy
                            // catalog (2-part entries) keep source: "quiz".
                            // Provenance is more analytically useful than
                            // timing — we can recover the during-quiz signal
                            // from contractors.created_at vs the property's
                            // house_quiz_state.started_at.
                            insert.source = parsed.source
                            insert.website = parsed.website
                            // Build 83: stash rating/reviews/Haven Certified
                            // tag in `notes` so the contractor list can show
                            // attribution without a schema migration. The
                            // contractors table has no rating/review/certified
                            // columns yet — when we add them, this can move.
                            insert.notes = parsed.attributionNotes()
                            _ = try? await db.createContractor(insert)
                        }
                    }

                    // For chips selected WITHOUT a provider, mark needs_vendor
                    // for the matching system category by writing an
                    // attribute. The reconciler reads this when creating
                    // tasks for those categories so the user gets a clear
                    // "Find a contractor for: X" CTA in the vendor bucket.
                    let attachedChipIds = Set(
                        (answer.customEntries ?? [])
                            .compactMap { Self.parseContractorChipEntry($0)?.chipId }
                    )
                    for chipId in selected where !attachedChipIds.contains(chipId) {
                        guard let category = Self.householdContractorCategoryFor(chipId: chipId) else { continue }
                        let existingForCategory = (try? await db.fetchContractors()) ?? []
                        let hasAny = existingForCategory.contains {
                            $0.category?.caseInsensitiveCompare(category) == .orderedSame
                        }
                        if !hasAny {
                            try await persistAttribute("needs_vendor_\(chipId)", value: "true")
                        }
                    }
                }

            case "q16_electric":
                // Phase 18e: picker selection threads selectedProviderId on the
                // answer; the helper looks it up and snapshots logo + brand.
                try await createUtilityAccount(from: answer, fallbackType: "electric")

            case "q17_internet":
                try await createUtilityAccount(from: answer, fallbackType: "internet_cable")

            case "q18_trash":
                try await persistAttribute("trash_service", value: answer.answerId)
                if answer.answerId == "private", let provider = answer.customText, !provider.isEmpty {
                    // Build 87 (search picker): catalog-aware path when
                    // the user picked from the search picker.
                    if answer.selectedProviderId != nil {
                        try await createUtilityAccount(from: answer, fallbackType: "trash")
                    } else {
                        try await createUtilityAccount(name: provider, type: "trash")
                    }
                }

            case "q19_heating_provider":
                // Use the heating fuel attribute (q3) as a hint when known so
                // the new utility account is filed under the right type when
                // the catalog row doesn't already supply it.
                var fallbackType = "oil"
                if let property = try? await db.fetchProperty(id: propertyId),
                   let fuel = property.attributes?["heating_fuel"]?.stringValue {
                    switch fuel {
                    case "natural_gas": fallbackType = "natural_gas"
                    case "propane": fallbackType = "propane"
                    case "oil": fallbackType = "oil"
                    default: break
                    }
                }
                try await createUtilityAccount(from: answer, fallbackType: fallbackType)

            case "q20_other_fuels":
                // Phase 19i: Q20 now covers fireplace + stove + wood + pellets
                // ONLY. Generator handling moved to Q22's dedicated inline form
                // so we can capture its fuel + provider explicitly.
                //
                // Each propane option creates a matching home_system row. The
                // propane provider account is either reused from Q19 (when Q3
                // was already propane) or created fresh from the inline
                // propane picker the user filled out. Wood/pellets create a
                // Fireplace system; only pellets get a vendor account (logs
                // are typically not on a recurring delivery contract).
                if let selected = answer.selectedIds {
                    try await persistAttribute("other_fuel_sources", value: selected.joined(separator: ","))

                    if selected.contains("propane_fireplace") {
                        try await ensureHomeSystem(name: "Propane Fireplace", category: "Fireplace")
                    }
                    if selected.contains("propane_stove") {
                        try await ensureHomeSystem(name: "Propane Cooktop", category: "Appliance")
                    }
                    if selected.contains("wood_logs") {
                        try await ensureHomeSystem(name: "Wood Burning Fireplace", category: "Fireplace")
                    }
                    if selected.contains("wood_pellets") {
                        try await ensureHomeSystem(name: "Pellet Stove", category: "Fireplace")
                    }
                    // Phase 18c backward-compat: still honor old "wood" answer.
                    if selected.contains("wood") {
                        try await ensureHomeSystem(name: "Wood Burning Fireplace", category: "Fireplace")
                    }
                    // Phase 18c backward-compat: still honor old propane_generator
                    // answer for users with persisted Q20 answers from before
                    // Phase 19i. The new Q22 form will overwrite/augment this.
                    if selected.contains("propane_generator") {
                        try await ensureHomeSystem(name: "Backup Generator", category: "Generator")
                    }

                    // Create a propane utility_account when any propane fixture
                    // is selected. Two paths:
                    //   1. Q3 was propane → Q19 already created the propane
                    //      account, so we don't need to do anything.
                    //   2. Q3 was NOT propane → use the inline picker
                    //      selection (secondaryFuelProviderId) or, as a
                    //      fallback, let the user add it later from the
                    //      Property → Utilities page.
                    let hasPropaneSystem = selected.contains("propane_fireplace")
                        || selected.contains("propane_stove")
                        || selected.contains("propane_generator")
                    if hasPropaneSystem {
                        let q3Fuel = (try? await db.fetchProperty(id: propertyId))?
                            .attributes?["heating_fuel"]?.stringValue
                        if q3Fuel != "propane", let propaneId = answer.secondaryFuelProviderId {
                            let propaneAnswer = HouseQuizAnswer(
                                answerId: "selected",
                                customText: answer.customText,
                                selectedProviderId: propaneId,
                                answeredAt: answer.answeredAt
                            )
                            try await createUtilityAccount(from: propaneAnswer, fallbackType: "propane")
                        }
                    }
                }

            case "q21_solar":
                try await persistAttribute("solar", value: answer.answerId)
                if answer.answerId == "owned" || answer.answerId == "leased" {
                    try await ensureHomeSystem(name: "Solar Panels", category: "Solar")
                }

            case "q22_generator":
                // Phase 19i: Q22 captures generator type + fuel + optional
                // provider in one screen. Three persistence steps:
                //   1. Persist generator_type and generator_fuel attributes.
                //   2. Ensure the Backup Generator home_system exists with
                //      the fuel as its subtype so MaintenanceTemplates picks
                //      the right load-test / refill / oil-change cadence.
                //   3. When the user explicitly picked a provider AND that
                //      fuel differs from Q3's primary heating fuel, create a
                //      new utility_account row tagged with the right type.
                //      When fuels match, the Q19 account already covers it.
                try await persistAttribute("generator", value: answer.answerId)

                guard let type = answer.answerId, type != "none" else {
                    // User said no generator. Nothing to create.
                    break
                }

                if let fuel = answer.generatorFuelType {
                    try await persistAttribute("generator_fuel", value: fuel)
                }

                let generatorSystemId = try await ensureHomeSystem(
                    name: "Backup Generator",
                    category: "Generator",
                    subtype: answer.generatorFuelType,
                    matchByCategory: true
                )
                _ = generatorSystemId

                // Build 86: provider account creation. The Build 85 path
                // gated this on `q3Fuel != fuel` to avoid duplicating Q19's
                // utility_account when the generator ran on the same fuel.
                // The new "same supplier?" confirmation card means
                // `generatorProviderId` is now set in BOTH the Yes-same case
                // (pointing at Q19's provider) AND the Different case
                // (pointing at a fresh pick). Rely on `createUtilityAccount`'s
                // name-based dedup at the household level so calling it for
                // the Yes-same case is a no-op against the existing Q19 row,
                // and the Different case creates a new row tagged with the
                // generator fuel.
                if let fuel = answer.generatorFuelType,
                   let providerId = answer.generatorProviderId {
                    let synthetic = HouseQuizAnswer(
                        answerId: "selected",
                        customText: answer.customText,
                        selectedProviderId: providerId,
                        answeredAt: answer.answeredAt
                    )
                    try await createUtilityAccount(from: synthetic, fallbackType: fuel)
                }

            case "q23_vehicle_count":
                if let id = answer.answerId {
                    try await persistAttribute("vehicle_count", value: id)
                }

            case "q24_vehicle_add":
                // Vehicle creation goes through the dedicated AddVehicleView /
                // VehicleLookupService flow. The mapper just records that the
                // user reached this step.
                try await persistAttribute("primary_vehicle_added", value: "true")

            case "q25_garage_ev":
                // Build 86: legacy answers from build 85 used "attached_1" /
                // "attached_2" — both normalize to the new "attached" id so
                // dashboards and `properties.attributes.garage_type` reads
                // see one canonical token. The legacy "ev_l2" answer that
                // was inlined into Q25 has moved to its own Q25b case below;
                // any persisted q25 row with that id is treated like
                // "attached" (best guess that the user had a charger and a
                // garage they didn't otherwise specify).
                let normalizedGarage: String? = {
                    switch answer.answerId {
                    case "attached_1", "attached_2", "ev_l2": return "attached"
                    default: return answer.answerId
                    }
                }()
                try await persistAttribute("garage_type", value: normalizedGarage)
                if let id = normalizedGarage, id != "none" {
                    try await ensureHomeSystem(name: "Garage Door", category: "Garage Door")
                }
                // Build 86: keep the legacy "ev_l2" answer producing the
                // EV charger system so users who answered the question on
                // build 85 don't lose that signal on the next quiz pass.
                if answer.answerId == "ev_l2" || answer.selectedIds?.contains("ev_l2") == true {
                    try await ensureHomeSystem(name: "EV Charger (L2)", category: "Electrical")
                }

            case "q25b_ev_charger":
                // Build 86: dedicated EV charger question. Persisted as a
                // separate `ev_charger_l2` attribute so the home dashboard
                // can render the right enrichment card without inferring
                // from the garage type. Only the explicit "yes" answer
                // creates the home_system row — "no" leaves it untouched.
                try await persistAttribute("ev_charger_l2", value: answer.answerId)
                if answer.answerId == "yes" {
                    try await ensureHomeSystem(name: "EV Charger (L2)", category: "Electrical")
                }

            case "q26_auto_insurance":
                // Phase 18e: snapshot the carrier's logo + brand color from
                // the catalog when the user picked from the search picker.
                try await createUtilityAccount(from: answer, fallbackType: "auto_insurance")

            case "q27_homeowners_insurance":
                // Phase 16b: keep the utility_account row aligned with the
                // seeded "home_insurance" provider_type from Phase 16a so
                // search and write paths use the same vocabulary.
                // Phase 18e: snapshot the picker selection.
                try await createUtilityAccount(from: answer, fallbackType: "home_insurance")

            case "q28_household":
                if let id = answer.answerId {
                    try await persistAttribute("household_residents", value: id)
                }
                if let caretakers = answer.selectedIds, !caretakers.isEmpty {
                    try await persistAttribute("caretakers", value: caretakers.joined(separator: ","))
                }
                // Phase 16d: when the user picked "Family with kids", each
                // kid entered in the inline form becomes a real family_member
                // row so the dashboard HouseholdStrip lights up. Failures
                // are logged-and-swallowed via the outer do/catch.
                if let kids = answer.kids {
                    for kid in kids {
                        let trimmed = kid.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { continue }
                        _ = try? await HouseholdInviteCoordinator.shared.addPersonToHousehold(
                            HouseholdInviteCoordinator.AddPersonRequest(
                                householdId: householdId,
                                firstName: trimmed,
                                relationship: "Child",
                                dateOfBirth: kid.dateOfBirth,
                                isMinor: kid.isMinorFromDOB,
                                sendInvite: false,
                                source: .childProfileAdd
                            )
                        )
                    }
                }
                // Expecting entries also become family_members but with the
                // is_expecting/expected_date columns set so the dashboard can
                // render the dashed avatar.
                if let expecting = answer.expectingEntries {
                    for entry in expecting {
                        let trimmedName = entry.name?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        let firstName = (trimmedName?.isEmpty == false ? trimmedName : nil) ?? "Baby"
                        var insert = FamilyMemberInsert(
                            householdId: householdId,
                            firstName: firstName,
                            lastName: "",
                            relationship: "Child"
                        )
                        insert.isExpecting = true
                        insert.expectedDate = entry.dueDate
                        insert.isMinor = true
                        insert.avatarColor = "sage"
                        _ = try? await db.createFamilyMember(insert)
                    }
                }

            case "q28b_pets":
                // Phase 19j — pet presence drives subtype-specific tasks like
                // the synthetic-turf "Sanitize pet areas" template. Persists
                // the raw answer plus a canonical `has_pets` boolean attribute,
                // then re-reconciles the Synthetic Turf system (if it exists)
                // so the pet sanitize task gets added now that has_pets is
                // known. Idempotent — no-op if no turf system exists.
                try await persistAttribute("pets", value: answer.answerId)
                let hasPets = (answer.answerId != "no_pets" && answer.answerId != nil)
                try await persistAttribute("has_pets", value: hasPets ? "true" : "false")

                if hasPets {
                    let existingSystems = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
                    let turfSystem = existingSystems.first { row in
                        row.category.lowercased() == "landscaping"
                            && (row.subtype?.lowercased() == "synthetic_turf")
                    }
                    if let turfSystem {
                        let petResult = await MaintenanceTaskReconciler.reconcile(
                            propertyId: propertyId,
                            householdId: householdId,
                            systemId: turfSystem.id,
                            systemCategory: "Landscaping",
                            confirmedSubtype: "synthetic_turf",
                            flags: ["has_pets": true]
                        )
                        reconciliationResult = reconciliationResult.merging(petResult)
                    }
                }

            case "q29_estate_docs":
                if let selected = answer.selectedIds {
                    try await persistAttribute("estate_documents_on_hand", value: selected.joined(separator: ","))
                }

            case "q30_priorities":
                if let selected = answer.selectedIds {
                    try await persistAttribute("priorities", value: selected.joined(separator: ","))
                }

            case "q36_diy_vs_vendor":
                // Build 88: 3-tier vendor preference picker. Persist the
                // tier string to the property attribute, then re-run the
                // reconciler for every property in the household so any
                // existing `either`-tagged tasks flip to match the new
                // tier.
                if let tierId = answer.answerId {
                    try await persistAttribute("vendor_preference_tier", value: tierId)
                    let result = await MaintenanceTaskReconciler.reconcileAllForHousehold(householdId: householdId)
                    reconciliationResult = reconciliationResult.merging(result)
                }

            default:
                // Unknown question — just record raw answer for forward compat.
                if let id = answer.answerId {
                    try await persistAttribute(question.id, value: id)
                }
            }
        } catch {
            print("[HouseQuizAnswerMapper] Failed for \(question.id): \(error)")
        }
        return reconciliationResult
    }

    // MARK: - Persistence helpers

    private func persistAttribute(_ key: String, value: String?) async throws {
        guard let value, !value.isEmpty else { return }
        _ = try await db.updatePropertyAttribute(
            propertyId: propertyId,
            key: key,
            value: .string(value)
        )
    }

    /// Ensure a top-level home system row exists for the given name+category.
    /// Returns the row id (existing or new).
    ///
    /// - Parameters:
    ///   - matchByCategory: When `true`, match the first top-level system of
    ///     the given category and update it (used for singleton categories
    ///     like HVAC, Roofing, Water Heater that `PropertyCreationService`
    ///     already auto-created at address lookup time — we want to
    ///     enhance that row, not create a duplicate).
    ///   - subtype: Optional subtype token. When provided, writes it to the
    ///     matched/created row so `MaintenanceTemplates.activeSubtypes`
    ///     picks it up on subsequent reads.
    ///   - excludeSubtype: Build 87 — when set, the `matchByCategory` lookup
    ///     skips rows whose `subtype` equals this value. Used by the Pool
    ///     vs Hot Tub split (Q12) so the Pool lookup doesn't accidentally
    ///     match the Hot Tub row in mixed households (both pool AND hot tub
    ///     share `category: "Pool/Spa"` but live in separate rows).
    @discardableResult
    private func ensureHomeSystem(
        name: String,
        category: String,
        subtype: String? = nil,
        matchByCategory: Bool = false,
        excludeSubtype: String? = nil
    ) async throws -> UUID? {
        let existing = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
        let match: HomeSystemRow? = matchByCategory
            ? existing.first(where: {
                $0.category.lowercased() == category.lowercased()
                && $0.parentSystemId == nil
                && (excludeSubtype == nil || $0.subtype != excludeSubtype)
            })
            : existing.first(where: {
                $0.name.lowercased() == name.lowercased()
                && $0.category.lowercased() == category.lowercased()
            })
        if let match {
            var update = HomeSystemUpdate()
            var needsUpdate = false
            if let subtype, match.subtype != subtype {
                update.subtype = subtype
                needsUpdate = true
            }
            if matchByCategory && match.name.lowercased() != name.lowercased() {
                update.name = name
                needsUpdate = true
            }
            if needsUpdate {
                _ = try? await db.updateHomeSystem(id: match.id, update)
            }
            return match.id
        }
        var insert = HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: name,
            category: category,
            notes: "Created from House Quiz."
        )
        insert.subtype = subtype
        let row = try await db.createHomeSystem(insert)
        return row.id
    }

    // MARK: - Quiz answer → subtype token mapping

    /// Translate a `q1_roof_material` answer id into the subtype token
    /// `MaintenanceTemplates.activeSubtypes` uses to unlock roof templates.
    /// Metal, tile, and slate have no subtype-tagged templates, so they
    /// return `nil` (universal templates still apply).
    fileprivate static func roofingSubtype(forQuizAnswer id: String) -> String? {
        switch id {
        case "asphalt": return "asphalt_shingle"
        case "flat_membrane": return "flat_membrane"
        case "wood_shake": return "wood_shake"
        default: return nil
        }
    }

    /// Phase 19b/19c: Friendly system name for the HVAC type the user picked
    /// in q3b. Used when the answer mapper creates or updates the HVAC system
    /// row so the Property → Maintenance list shows something more specific
    /// than "HVAC System" (e.g. "Boiler + Window AC", "Mini-Split HVAC"). The
    /// "not_sure" path lands on "HVAC System (unconfirmed)" so the user can
    /// see at a glance that they still need to confirm their configuration.
    fileprivate static func hvacSystemName(for typeId: String) -> String {
        switch typeId {
        case "central_ducted":          return "Central HVAC"
        case "mini_split":              return "Mini-Split HVAC"
        case "boiler_with_central_ac":  return "Boiler + Central AC"
        case "boiler_radiant":          return "Boiler / Radiators"
        case "boiler_with_window_ac":   return "Boiler + Window AC"
        case "heat_pump":               return "Heat Pump"
        case "geothermal":              return "Geothermal HVAC"
        case "not_sure":                return "HVAC System (unconfirmed)"
        default:                        return "HVAC System"
        }
    }

    private func ensureChildSystem(parentId: UUID, name: String, category: String) async throws {
        let existing = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
        if existing.contains(where: {
            $0.name.lowercased() == name.lowercased() && $0.parentSystemId == parentId
        }) {
            return
        }
        var insert = HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: name,
            category: category,
            notes: "Created from House Quiz."
        )
        insert.parentSystemId = parentId
        _ = try await db.createHomeSystem(insert)
    }

    /// Phase 18e: When the answer carries a `selectedProviderId` (set by the
    /// quiz picker via `recordProviderAnswer`), look up the catalog row and
    /// snapshot its logo, brand color, slug, website, and phone onto the new
    /// utility_account row. Falls back to a name-only insert when the user
    /// typed a custom provider in a follow-up text field (q11 pro lawn,
    /// q12 pool, q13 pest, q14 irrigation, q15 security, q18 trash).
    ///
    /// `fallbackType` is the canonical provider_type to use if the catalog
    /// row didn't supply one (or when the answer is name-only). For q19 the
    /// caller threads in the heating fuel attribute so the new row is filed
    /// under the right type.
    ///
    /// Phase 19k: For service-category provider types (landscaping, pool,
    /// pest, irrigation, security, etc.), ALSO mirror the vendor into the
    /// `contractors` table so the maintenance task reconciler can find them
    /// at task-creation time and auto-assign vendor-managed tasks.
    private func createUtilityAccount(from answer: HouseQuizAnswer, fallbackType: String) async throws {
        // Resolve the catalog provider record (if any) so we can snapshot it.
        var catalogProvider: UtilityProviderRow?
        if let providerId = answer.selectedProviderId {
            catalogProvider = try? await db.fetchUtilityProvider(id: providerId)
        }

        let resolvedName: String
        if let catalog = catalogProvider, !catalog.name.isEmpty {
            resolvedName = catalog.name
        } else if let typed = answer.customText?.trimmingCharacters(in: .whitespacesAndNewlines), !typed.isEmpty {
            resolvedName = typed
        } else {
            return
        }

        let resolvedType = catalogProvider?.providerType ?? fallbackType

        // Avoid duplicates: skip if an account with this provider name already exists.
        let existing = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
        if existing.contains(where: { $0.providerName.lowercased() == resolvedName.lowercased() }) {
            // Even if the utility_account already exists, ensure the contractor
            // mirror is up to date for service categories.
            try? await mirrorContractorIfNeeded(name: resolvedName, providerType: resolvedType, catalogProvider: catalogProvider)
            return
        }

        var insert = UtilityAccountInsert(
            propertyId: propertyId,
            householdId: householdId,
            providerType: resolvedType,
            providerName: resolvedName
        )
        if let catalog = catalogProvider {
            insert.providerId = catalog.id
            insert.providerSlug = catalog.slug
            insert.logoUrl = catalog.logoUrl
            insert.brandColor = catalog.brandColor
            insert.website = catalog.website
            insert.phone = catalog.phone
        }
        _ = try await db.createUtilityAccount(insert)

        // Phase 19k: Mirror the vendor into the contractors table when this
        // is a service category. The reconciler picks up the row by category
        // match at task-creation time and auto-assigns vendor-managed tasks.
        try? await mirrorContractorIfNeeded(name: resolvedName, providerType: resolvedType, catalogProvider: catalogProvider)
    }

    /// Phase 18e: Name-only convenience wrapper for the legacy follow-up path
    /// (q11 lawn pro, q12 pool, q13 pest, q14 irrigation, q15 security,
    /// q18 trash). These questions are .singleChoice, not .providerSearch, so
    /// the user types a free-form name with no catalog ID.
    ///
    /// Phase 19k: Same contractor mirror as the picker-driven helper.
    private func createUtilityAccount(name: String, type: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let existing = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
        if existing.contains(where: { $0.providerName.lowercased() == trimmed.lowercased() }) {
            try? await mirrorContractorIfNeeded(name: trimmed, providerType: type, catalogProvider: nil)
            return
        }
        let insert = UtilityAccountInsert(
            propertyId: propertyId,
            householdId: householdId,
            providerType: type,
            providerName: trimmed
        )
        _ = try await db.createUtilityAccount(insert)

        try? await mirrorContractorIfNeeded(name: trimmed, providerType: type, catalogProvider: nil)
    }

    /// Build 83 (Apr 7, 2026): Q15b customEntries are pipe-delimited strings.
    /// Two shapes are accepted to keep older persisted answers round-tripping:
    ///   - 2 parts: "chip|name"  (manual + legacy catalog flow)
    ///   - 7 parts: "chip|name|rating|reviews|phone|website|haven_certified"
    ///              (Build 83's find-local-vendors flow; rating/reviews/phone/
    ///               website may be empty strings; the 7th slot is the literal
    ///               "haven_certified" or empty)
    /// Returns nil when the entry is malformed (no chip id or empty name).
    ///
    /// Polish pass: `source` is now populated based on part count so the
    /// mapper can write the right `contractors.source` discriminator. 7-part
    /// entries (Places-sourced via `QuizLocalContractorPicker`) get
    /// `find_vendor`. 2-part entries (manual add or legacy catalog) keep the
    /// existing `quiz` value.
    /// Build 85: promoted from `fileprivate` to internal so
    /// `HouseQuizView.hydrateEntryState` can reuse the parser when
    /// re-hydrating Q15b chips on back-navigation. Both shapes (manual /
    /// 7-part Places-sourced) round-trip cleanly through the same parser.
    struct ParsedContractorEntry {
        let chipId: String
        let name: String
        let rating: Double?
        let reviewCount: Int?
        let phone: String?
        let website: String?
        let isHavenCertified: Bool
        let source: String

        /// Render a human caption for the contractor `notes` column so we can
        /// surface "Haven Certified \u{2022} 4.7 \u{2022} 120 reviews" without
        /// adding new columns. Returns nil when there's nothing to attribute
        /// (e.g. a manual-add row with no rating).
        func attributionNotes() -> String? {
            var parts: [String] = []
            if isHavenCertified {
                parts.append("Haven Certified")
            }
            if let rating {
                parts.append(String(format: "%.1f stars", rating))
            }
            if let reviewCount {
                parts.append("\(reviewCount) reviews")
            }
            if parts.isEmpty {
                return "Added from House Quiz."
            }
            return "Added from House Quiz \u{2022} " + parts.joined(separator: " \u{2022} ")
        }
    }

    /// Build 85: promoted from `fileprivate` to internal so the view
    /// can reuse it when hydrating Q15b's chip state on back-navigation.
    static func parseContractorChipEntry(_ raw: String) -> ParsedContractorEntry? {
        let parts = raw.components(separatedBy: "|")
        guard parts.count >= 2 else { return nil }
        let chipId = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let name = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !chipId.isEmpty, !name.isEmpty else { return nil }

        if parts.count >= 7 {
            let rating: Double? = {
                let trimmed = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : Double(trimmed)
            }()
            let reviews: Int? = {
                let trimmed = parts[3].trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : Int(trimmed)
            }()
            let phone: String? = {
                let trimmed = parts[4].trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }()
            let website: String? = {
                let trimmed = parts[5].trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }()
            let certified = parts[6].trimmingCharacters(in: .whitespacesAndNewlines) == "haven_certified"
            // 7-part entries are produced by QuizLocalContractorPicker's
            // Google Places adoption path. Tag them as find_vendor so the
            // contractors.source discriminator carries the provenance.
            return ParsedContractorEntry(
                chipId: chipId,
                name: name,
                rating: rating,
                reviewCount: reviews,
                phone: phone,
                website: website,
                isHavenCertified: certified,
                source: "find_vendor"
            )
        }

        // 2-part legacy / manual entry — no rating/review metadata. Source
        // stays "quiz" because these came from either the catalog picker
        // (legacy) or the inline "Add it manually" textfield, neither of
        // which carries Google Places provenance.
        return ParsedContractorEntry(
            chipId: chipId,
            name: name,
            rating: nil,
            reviewCount: nil,
            phone: nil,
            website: nil,
            isHavenCertified: false,
            source: "quiz"
        )
    }

    /// Phase 19m: Map a Q15b chip id to the matching `home_systems.category`
    /// so the contractor mirror files the row under the right specialty.
    /// `handyman` returns nil because the chip is multi-purpose and doesn't
    /// map cleanly to one home system category — we still record the
    /// `household_contractor_chips` attribute so it survives, but no
    /// contractor row gets created until the user assigns the handyman to
    /// a specific task themselves.
    private static func householdContractorCategoryFor(chipId: String) -> String? {
        switch chipId {
        case "hvac_service":       return "HVAC"
        case "plumber":            return "Plumbing"
        case "electrician":        return "Electrical"
        case "roofer":             return "Roofing"
        case "septic_pumper":      return "Septic System"
        case "well_water_service": return "Well System"
        case "chimney_sweep":      return "Fire Protection"
        case "tree_service":       return "Landscaping"
        case "handyman":           return nil
        default:                   return nil
        }
    }

    /// Phase 19k: Service-category provider_types that should also create a
    /// contractor row mirror. Utility-bill types (electric, internet, oil,
    /// gas, water, propane, trash) are excluded — those don't represent
    /// human contractors who do recurring maintenance work.
    private static let serviceCategoryProviderTypes: [String: String] = [
        "landscaping":   "Landscaping",
        "pool_service":  "Pool/Spa",
        "pest_control":  "Pest Control",
        "irrigation":    "Irrigation",
        "security":      "Security System",
        "solar":         "Solar",
        "hvac":          "HVAC",
        "plumbing":      "Plumbing",
        "roofing":       "Roofing",
        "electrical":    "Electrical",
    ]

    /// Mirrors a quiz-captured service vendor into the `contractors` table.
    /// Idempotent — skips if a contractor with the same name already exists
    /// for this household. Maps the provider_type to the matching home_systems
    /// category so the reconciler's category-based lookup finds the row.
    private func mirrorContractorIfNeeded(
        name: String,
        providerType: String,
        catalogProvider: UtilityProviderRow?
    ) async throws {
        let lowerType = providerType.lowercased()
        guard let category = Self.serviceCategoryProviderTypes[lowerType] else {
            // Not a service category — utility bill, no contractor needed.
            return
        }

        // Skip if a contractor with this name already exists in the household.
        let existing = (try? await db.fetchContractors()) ?? []
        if existing.contains(where: { $0.companyName.lowercased() == name.lowercased() }) {
            return
        }

        var insert = ContractorInsert(
            householdId: householdId,
            companyName: name,
            phone: catalogProvider?.phone ?? "Not provided"
        )
        insert.category = category
        insert.specialties = [category]
        insert.utilityProviderId = catalogProvider?.id
        insert.logoUrl = catalogProvider?.logoUrl
        insert.brandColor = catalogProvider?.brandColor
        insert.website = catalogProvider?.website
        insert.source = "quiz"
        _ = try? await db.createContractor(insert)
    }

    /// Build 86: Flip every task in `systemCategory` on this property to
    /// vendor-managed, linking them to the named contractor and reframing
    /// the title + description in Haven's standard "Schedule Vendor: ..."
    /// voice. Used by q13_pest (and reusable for q11 lawn, q14 irrigation,
    /// q15 security) when the user explicitly hires a pro for an entire
    /// service category — at that point even the DIY templates like
    /// "Inspect foundation for entry points" should flow through the vendor
    /// because the pro is already walking the property.
    ///
    /// Mirrors the `MaintenanceViewModel.convertToVendorManaged` reframing
    /// pattern (Phase 19l) but runs directly against the DB so the quiz
    /// flow doesn't need the view model's cached state. Idempotent — tasks
    /// already tagged `vendor` are left alone so re-running the quiz won't
    /// double-reframe titles.
    ///
    /// Errors are logged and swallowed: the quiz must keep moving even if
    /// one task update fails.
    private func flipCategoryTasksToVendor(
        systemCategory: String,
        providerName: String
    ) async {
        do {
            // Find the contractor mirrored by createUtilityAccount.
            // Match on (name, category) or (name, specialties contains) to
            // handle both the Phase 19k `.category` column and the legacy
            // `.specialties` array.
            let contractors = (try? await db.fetchContractors()) ?? []
            let normalizedName = providerName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard let contractor = contractors.first(where: { row in
                let nameMatches = row.companyName.lowercased() == normalizedName
                let categoryMatches = row.category?
                    .caseInsensitiveCompare(systemCategory) == .orderedSame
                let specialtyMatches = row.specialties?
                    .contains(where: { $0.caseInsensitiveCompare(systemCategory) == .orderedSame }) == true
                return nameMatches && (categoryMatches || specialtyMatches)
            }) else {
                // Mirror didn't land (utility-bill-only category, or the
                // name didn't survive the trim). Nothing to flip.
                return
            }

            // Fetch every property-scoped task and narrow to this category.
            // Match via templateId prefix (fast path, covers post-Phase-14
            // rows) with a fallback to the template catalog lookup for
            // legacy rows that never got a prefixed templateId.
            let allTasks = try await db.fetchMaintenanceTasks(propertyId: propertyId)
            let categoryPrefix = systemCategory.lowercased() + ":"
            let categoryTasks = allTasks.filter { task in
                if task.vehicleId != nil { return false }
                if let templateId = task.templateId {
                    if templateId.lowercased().hasPrefix(categoryPrefix) {
                        return true
                    }
                    if let template = MaintenanceTemplates.template(forKey: templateId),
                       template.systemCategory.caseInsensitiveCompare(systemCategory) == .orderedSame {
                        return true
                    }
                }
                return false
            }

            // Flip every task that isn't already vendor-managed.
            for task in categoryTasks where task.assignmentType?.lowercased() != "vendor" {
                let originalTemplate = task.templateId
                    .flatMap { MaintenanceTemplates.template(forKey: $0) }
                let originalTitle = originalTemplate?.title ?? task.title
                let originalDescription = originalTemplate?.description ?? task.description ?? ""

                let newTitle = "Schedule \(contractor.companyName): \(originalTitle.lowercased())"
                let newDescription: String = {
                    if originalDescription.isEmpty {
                        return "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work."
                    }
                    return "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(originalDescription)"
                }()

                var update = MaintenanceTaskUpdate()
                update.title = newTitle
                update.description = newDescription
                update.assignedContractorId = contractor.id
                update.assignmentType = "vendor"
                update.needsVendor = false
                _ = try? await db.updateMaintenanceTask(id: task.id, update)
            }
        } catch {
            print("[HouseQuizAnswerMapper] flipCategoryTasksToVendor(\(systemCategory)) failed: \(error)")
        }
    }

    private func digitsOnly(_ s: String) -> String {
        s.filter { $0.isNumber }
    }

    /// Build 84: Hardscape maintenance set. Q11 = "hardscape" routes here to
    /// create 4 real maintenance tasks tied to the new "Outdoor Hardscape"
    /// system so HNW homeowners with paver/stone/gravel yards aren't dropped
    /// off the maintenance schedule entirely. Created directly here (not
    /// via MaintenanceTemplates) because these are one-off branch tasks
    /// that don't need template reconciliation. `createMaintenanceTask`
    /// already dedups by title within property/system, so re-running the
    /// quiz won't create duplicates.
    ///
    /// Build 84 polish (Tom's Item 3 call): pressure washing is now
    /// `either` so the post-quiz vendor delegation sheet (Phase 19l) can
    /// offer to flip it to vendor-managed when a landscaping or
    /// pressure-wash contractor is added later. The other three (joint
    /// sand, weed treatment, drainage check) stay `personal` because
    /// they're DIY-only by nature for HNW homeowners.
    private func createHardscapeMaintenanceTasks(systemId: UUID) async throws {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()

        struct HardscapeTaskSpec {
            let title: String
            let description: String
            let frequency: String
            let monthsUntilDue: Int
            let priority: String
            let seasonalTiming: String?
            let templateKey: String
            let diyEffortLabel: String
            let assignmentType: String
        }

        let specs: [HardscapeTaskSpec] = [
            HardscapeTaskSpec(
                title: "Pressure wash patio and walkways",
                description: "Pressure wash stone, paver, and concrete hardscape surfaces to clear winter grime, mildew, and algae. Use a fan tip and avoid stripping joint sand.",
                frequency: "Annually",
                monthsUntilDue: 1,
                priority: "Medium",
                seasonalTiming: "Spring",
                templateKey: "landscaping:hardscape_pressure_wash",
                diyEffortLabel: "About 2 hours",
                // Build 84 polish: flippable via the Phase 19l delegation
                // sheet so a landscaping contractor on file can take it
                // over without forcing the user to recreate the task.
                assignmentType: "either"
            ),
            HardscapeTaskSpec(
                title: "Top up joint sand in pavers",
                description: "Sweep polymeric joint sand into paver gaps where it has washed out. Mist lightly to set the polymer. Prevents weed germination and keeps pavers locked.",
                frequency: "Every 2 years",
                monthsUntilDue: 4,
                priority: "Low",
                seasonalTiming: "Summer",
                templateKey: "landscaping:hardscape_joint_sand",
                diyEffortLabel: "About 1 hour",
                assignmentType: "personal"
            ),
            HardscapeTaskSpec(
                title: "Treat weeds between pavers",
                description: "Spot-treat weeds growing between pavers and along hardscape edges. Pull large clumps by hand first, then apply a targeted herbicide or boiling water.",
                frequency: "Quarterly",
                monthsUntilDue: 1,
                priority: "Low",
                seasonalTiming: "Spring",
                templateKey: "landscaping:hardscape_weed_treatment",
                diyEffortLabel: "About 30 minutes",
                assignmentType: "personal"
            ),
            HardscapeTaskSpec(
                title: "Check hardscape drainage and grading",
                description: "Walk hardscape edges after a rain to confirm water is moving away from the house. Look for sunken pavers, ponding, and drainage swales that have silted in.",
                frequency: "Annually",
                monthsUntilDue: 7,
                priority: "Medium",
                seasonalTiming: "Fall",
                templateKey: "landscaping:hardscape_drainage_check",
                diyEffortLabel: "About 30 minutes",
                assignmentType: "personal"
            ),
        ]

        for spec in specs {
            let nextDue = calendar.date(byAdding: .month, value: spec.monthsUntilDue, to: now) ?? now
            var insert = MaintenanceTaskInsert(
                householdId: householdId,
                title: spec.title,
                frequency: spec.frequency,
                nextDueDate: formatter.string(from: nextDue)
            )
            insert.propertyId = propertyId
            insert.systemId = systemId
            insert.description = spec.description
            insert.priority = spec.priority
            insert.isTemplateBased = true
            insert.templateId = spec.templateKey
            insert.seasonalTiming = spec.seasonalTiming
            insert.isDiy = true
            insert.professionalRequired = false
            insert.costRange = "$0 (DIY)"
            insert.assignmentType = spec.assignmentType
            insert.needsVendor = false
            insert.notes = spec.diyEffortLabel
            _ = try? await db.createMaintenanceTask(insert)
        }
    }
}
