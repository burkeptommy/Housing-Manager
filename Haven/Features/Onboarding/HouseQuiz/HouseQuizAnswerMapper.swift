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
                // Phase 67E/F (admin feedback bc224f35): Q2 is multiSelect.
                // Persist the comma-joined sorted list under the existing
                // `siding_material` attribute key so single-material homes
                // keep matching their previous value (e.g. "vinyl"). Mixed
                // homes write something like "brick,vinyl" — downstream
                // template gating that checks for a substring (e.g.
                // siding-material-aware power-wash cadence) can split on
                // comma. The legacy "mixed" sentinel is dropped from Q2's
                // options since multiSelect captures the actual mix.
                let sidingValue: String? = {
                    if let ids = answer.selectedIds, !ids.isEmpty {
                        return ids.sorted().joined(separator: ",")
                    }
                    return answer.answerId
                }()
                try await persistAttribute("siding_material", value: sidingValue)

            case "q3_heating_system":
                // Phase 67D (A3): merged Q3 + Q3b. The user picks one of 12
                // fuel+system combos; we derive both `heating_fuel` and
                // `hvac_type` attributes from it via HouseQuizFuelDerivation
                // so existing template gating (which keys off `hvac_type`
                // subtype) and downstream Q19 fuel-provider filtering keep
                // working. Reconciler fires once with both pieces of context.
                guard let comboId = answer.answerId else { break }
                if let fuel = HouseQuizFuelDerivation.heatingFuel(from: comboId) {
                    try await persistAttribute("heating_fuel", value: fuel)
                }
                let hvacSubtype = HouseQuizFuelDerivation.hvacSubtype(from: comboId) ?? "not_sure"
                try await persistAttribute("hvac_type", value: hvacSubtype)
                let hvacFuel = HouseQuizFuelDerivation.heatingFuel(from: comboId)
                let hvacSystemId = try await ensureHomeSystem(
                    name: Self.hvacSystemName(for: hvacSubtype),
                    category: "HVAC",
                    subtype: hvacSubtype,
                    matchByCategory: true
                )
                let hvacResult = await MaintenanceTaskReconciler.reconcile(
                    propertyId: propertyId,
                    householdId: householdId,
                    systemId: hvacSystemId,
                    systemCategory: "HVAC",
                    confirmedSubtype: hvacSubtype,
                    fuelType: hvacFuel
                )
                reconciliationResult = reconciliationResult.merging(hvacResult)

            // Phase 67E/F admin feedback (f2d119cc + b348f04c + f5992eea):
            // Q4 "How did you get this home?" and Q5 "Do you have a mortgage?"
            // were dropped from the quiz library. Their handlers are kept
            // here as no-ops so any saved-for-later quiz state with those
            // answer ids round-trips cleanly through the mapper instead of
            // falling into the unhandled-case path.
            case "q4_purchase", "q5_mortgage":
                break

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
                // Sump pump is only auto-created when the user EXPLICITLY
                // ticks the sump_pump checkbox. Phase 95.1 fix: previously
                // any basement (finished or unfinished) auto-created a Sump
                // Pump system even when the user did NOT select the sump
                // pump option, which was a false positive for the
                // ~50% of basement homes that don't have one. Caught by
                // overnight E2E (Tests/e2e UI Wave 1 Subagent 3). The
                // sump_pump option in q9_basement is a separate selectable
                // ID alongside finished_basement / unfinished_basement /
                // crawl_space / slab — basement type and sump-pump
                // presence are independent facts.
                if basementSelections.contains("sump_pump") {
                    try await ensureHomeSystem(name: "Sump Pump", category: "Sump Pump")
                }
                if basementSelections.contains("crawl_space") {
                    try await ensureHomeSystem(name: "Crawl Space", category: "Crawl Space")
                }

            case "q9b_renovations":
                // Phase 67D (B3): captured renovations push
                // `last_replaced_date` to matching home_systems rows so
                // the reconciler suppresses recently-replaced
                // "replace your X" tasks. selectedIds carries the
                // renovation type list; customEntries holds "type:year"
                // entries (year=0 sentinel = "roughly / unknown" → falls
                // back to today − 5y per the plan's edge case).
                let renovationIds = answer.selectedIds ?? []
                guard !renovationIds.contains("none") && !renovationIds.isEmpty else {
                    try await persistAttribute("renovations", value: "none")
                    break
                }
                // Persist the comma-joined list as a property attribute
                // so future reasoning can read it without parsing
                // customEntries.
                try await persistAttribute(
                    "renovations",
                    value: renovationIds.filter { $0 != "none" }.sorted().joined(separator: ",")
                )

                // Parse "type:year" entries into a per-type year map.
                var yearByType: [String: Int] = [:]
                for entry in answer.customEntries ?? [] {
                    let parts = entry.split(separator: ":", maxSplits: 1).map(String.init)
                    guard parts.count == 2, let year = Int(parts[1]) else { continue }
                    yearByType[parts[0]] = year
                }

                let categoryMapping: [String: String] = [
                    "roof_replaced": "Roofing",
                    "hvac_replaced": "HVAC",
                    "water_heater_replaced": "Water Heater",
                    "windows_replaced": "Windows",
                    "siding_replaced": "Siding/Exterior",
                ]
                let calendar = Calendar.current
                let now = Date()
                let estimatedFallback = calendar.date(byAdding: .year, value: -5, to: now) ?? now

                let allSystems = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
                for renovation in renovationIds {
                    guard let category = categoryMapping[renovation] else { continue }
                    let matching = allSystems.filter {
                        $0.category.lowercased() == category.lowercased()
                            && $0.parentSystemId == nil
                    }
                    let pickedYear = yearByType[renovation] ?? 0
                    let replacedDate: Date = {
                        if pickedYear > 0,
                           let date = calendar.date(from: DateComponents(year: pickedYear, month: 6, day: 15)) {
                            return date
                        }
                        return estimatedFallback
                    }()
                    let source = pickedYear > 0 ? "user_renovation" : "estimated"
                    // Phase 1.6: Propagate captured renovation year to
                    // home_systems.install_date. The original TODO
                    // referenced a `last_replaced_date` column that was
                    // never shipped — install_date with provenance is
                    // the canonical place. Guards:
                    //   1. Never overwrite a user-confirmed install
                    //      date (installDateConfirmedAt set).
                    //   2. Only overwrite if the new date is more
                    //      recent than the existing one (back-nav with
                    //      an older year shouldn't regress data).
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withFullDate]
                    let newDateString = formatter.string(from: replacedDate)
                    for system in matching {
                        let shouldOverwrite: Bool = {
                            if system.installDateConfirmedAt != nil { return false }
                            guard let existingISO = system.installDate,
                                  let existingDate = formatter.date(from: existingISO) else {
                                return true
                            }
                            return replacedDate > existingDate
                        }()
                        guard shouldOverwrite else { continue }
                        var update = HomeSystemUpdate()
                        update.installDate = newDateString
                        update.installDateSource = source
                        _ = try? await db.updateHomeSystem(id: system.id, update)
                    }
                }

            case "q10_appliances":
                if let selected = answer.selectedIds {
                    // The "other" id is just a placeholder that triggers the
                    // free-form text input — never persist it as an appliance.
                    // Phase 1.4: same treatment for `anything_else_appliance`,
                    // which is a UI trigger for the LibraryPicker sheet. Its
                    // chip should never become a home_systems row.
                    let realSelections = selected.filter {
                        $0 != "other" && $0 != "anything_else_appliance"
                    }
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
                    // Phase 1.4: library-sourced entries arrive with a "lib:"
                    // forward-compat prefix that we strip before creating
                    // the row. Stale clients that don't strip the prefix
                    // would still create a `lib:Wine cellar / cooler`
                    // home_system — annoying but non-fatal.
                    for custom in customEntries {
                        let cleaned: String
                        if custom.hasPrefix("lib:") {
                            cleaned = String(custom.dropFirst(4))
                        } else {
                            cleaned = custom
                        }
                        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { continue }
                        try await ensureHomeSystem(name: trimmed, category: "Appliance")
                    }
                }

            case "q11_lawn":
                // Phase 67D (A4): Q11 + Q11b merged. Q11's primary answer is
                // the handler choice (diy / pro / no_lawn / garden /
                // hardscape); Q11b's lawn type is now in
                // `answer.payload["lawnType"]`. Q11c (months) is gone — the
                // attribute stamping for landscaping_active_months moved to
                // Phase C3's AnnualRhythmScreen.
                try await persistAttribute("lawn_status", value: answer.answerId)
                if answer.answerId == "diy" || answer.answerId == "pro" {
                    let lawnSystemId = try await ensureHomeSystem(
                        name: "Landscaping",
                        category: "Landscaping",
                        subtype: "lawn",
                        matchByCategory: true
                    )
                    var landscapingRoutine: RoutineRow?
                    if answer.answerId == "pro", let provider = answer.customText, !provider.isEmpty {
                        let utilityAccount: UtilityAccountRow?
                        if answer.selectedProviderId != nil {
                            utilityAccount = try await createUtilityAccount(from: answer, fallbackType: "landscaping")
                        } else {
                            utilityAccount = try await createUtilityAccount(name: provider, type: "landscaping")
                        }
                        let contractor = await matchedContractor(for: utilityAccount)
                        landscapingRoutine = await ensureLinkedRoutineForProviderContext(
                            providerType: "landscaping",
                            utilityAccount: utilityAccount,
                            contractor: contractor
                        )
                    }
                    let lawnResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: lawnSystemId,
                        systemCategory: "Landscaping",
                        confirmedSubtype: "lawn"
                    )
                    reconciliationResult = reconciliationResult.merging(lawnResult)
                    if answer.answerId == "pro", let provider = answer.customText, !provider.isEmpty {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Landscaping",
                            providerName: provider
                        )
                    }
                    if let landscapingRoutine {
                        _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                            landscapingRoutine,
                            in: householdId,
                            propertyId: propertyId
                        )
                    }
                }
                // Phase 60.2 (F13) / 67D (A4): hardscape branch. Creates an
                // "Outdoor Hardscape" system row + reconcile so the four
                // hardscape templates (pressure wash, joint sand, weed
                // treatment, drainage check) land as `.either` (flippable
                // by Q36 preference tier) instead of stamped `.personal`.
                if answer.answerId == "hardscape" {
                    if let hardscapeSystemId = try await ensureHomeSystem(
                        name: "Outdoor Hardscape",
                        category: "Landscaping",
                        subtype: "hardscape"
                    ) {
                        let hardscapeResult = await MaintenanceTaskReconciler.reconcile(
                            propertyId: propertyId,
                            householdId: householdId,
                            systemId: hardscapeSystemId,
                            systemCategory: "Landscaping",
                            confirmedSubtype: "hardscape"
                        )
                        reconciliationResult = reconciliationResult.merging(hardscapeResult)
                    }
                }

                // Phase 67D (A4): Q11b lawn type folded into payload.
                // Persist `lawn_type` attribute and run the matching
                // synthetic-turf / natural-lawn reconciles when the
                // primary handler isn't no_lawn / garden / hardscape.
                if let lawnType = answer.payload?["lawnType"], lawnType != "not_sure" {
                    try await persistAttribute("lawn_type", value: lawnType)

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

                    // Build 87 second-flip pattern preserved: Q11b's
                    // reconciles above create new Landscaping tasks AFTER
                    // Q11's vendor flip already ran. Re-fire the flip when
                    // the user picked "pro" so the new tasks land as
                    // vendor-managed instead of cluttering the personal
                    // to-do list.
                    if answer.answerId == "pro" {
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
                }

            case "q12_pool":
                // Phase 67D (A5): Q12 + Q12b merged. Primary `answerId` is
                // the pool/hot-tub kind; chemistry lives in
                // `payload["chemistry"]` and is hidden in UI for hot-tub-only
                // and none paths. Q12c (months) is gone — pool_active_months
                // attribute moved to Phase C3's AnnualRhythmScreen.
                try await persistAttribute("pool_type", value: answer.answerId)
                guard let id = answer.answerId, id != "none" else { break }

                let hasPool = id == "in_ground" || id == "above_ground" || id == "both"
                let hasHotTub = id == "hot_tub" || id == "both"
                let providerName = answer.customText?.trimmingCharacters(in: .whitespacesAndNewlines)
                let hasProvider = providerName?.isEmpty == false
                let poolUtilityAccount: UtilityAccountRow?
                if hasProvider {
                    if answer.selectedProviderId != nil {
                        poolUtilityAccount = try await createUtilityAccount(from: answer, fallbackType: "pool_service")
                    } else {
                        poolUtilityAccount = try await createUtilityAccount(name: providerName ?? "", type: "pool_service")
                    }
                } else {
                    poolUtilityAccount = nil
                }
                let poolContractor = await matchedContractor(for: poolUtilityAccount)

                // Phase 67D (A5): chemistry token computed once for use in
                // both the initial reconcile (composite subtype) and the
                // attribute stamping. Hot-tub-only paths and answers without
                // a chemistry payload yield nil → fall back to the
                // pool-type-only subtype.
                let chemistryAnswerId = answer.payload?["chemistry"]
                let chemistryToken: String? = {
                    switch chemistryAnswerId {
                    case "saltwater": return "pool_salt"
                    case "chlorine":  return "pool_chlorine"
                    default:          return nil
                    }
                }()
                if let chemistryAnswerId, chemistryAnswerId != "not_sure" {
                    try await persistAttribute("pool_chemistry", value: chemistryAnswerId)
                }

                if hasPool {
                    var poolRoutine: RoutineRow?
                    let basePoolSubtype: String
                    switch id {
                    case "in_ground": basePoolSubtype = "pool_inground"
                    case "above_ground": basePoolSubtype = "pool_above_ground"
                    case "both": basePoolSubtype = "pool_inground"
                    default: basePoolSubtype = "pool_inground"
                    }
                    // Compose chemistry into the subtype when present so
                    // chemistry-gated templates fire on the first reconcile
                    // (no second-flip needed when Q12b is folded in).
                    let poolSubtype: String = {
                        if let chemistry = chemistryToken {
                            let suffix = chemistry.replacingOccurrences(of: "pool_", with: "")
                            return "\(basePoolSubtype)_\(suffix)"
                        }
                        return basePoolSubtype
                    }()
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
                    if hasProvider {
                        poolRoutine = await ensureLinkedRoutineForProviderContext(
                            providerType: "pool_service",
                            utilityAccount: poolUtilityAccount,
                            contractor: poolContractor
                        )
                    }
                    let poolResult = await MaintenanceTaskReconciler.reconcile(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemId: parentId,
                        systemCategory: "Pool/Spa",
                        confirmedSubtype: poolSubtype
                    )
                    reconciliationResult = reconciliationResult.merging(poolResult)
                    if let provider = providerName, !provider.isEmpty {
                        await flipCategoryTasksToVendor(
                            systemCategory: "Pool/Spa",
                            providerName: provider
                        )
                    }
                    if let poolRoutine {
                        _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                            poolRoutine,
                            in: householdId,
                            propertyId: propertyId
                        )
                    }
                }

                if hasHotTub {
                    // matchByCategory: false matches by name "Hot Tub"
                    // explicitly so the "both" case doesn't collapse the
                    // Hot Tub into the Pool row.
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
                    var pestRoutine: RoutineRow?
                    if let provider = answer.customText, !provider.isEmpty {
                        let utilityAccount: UtilityAccountRow?
                        if answer.selectedProviderId != nil {
                            utilityAccount = try await createUtilityAccount(from: answer, fallbackType: "pest_control")
                        } else {
                            utilityAccount = try await createUtilityAccount(name: provider, type: "pest_control")
                        }
                        let contractor = await matchedContractor(for: utilityAccount)
                        pestRoutine = await ensureLinkedRoutineForProviderContext(
                            providerType: "pest_control",
                            utilityAccount: utilityAccount,
                            contractor: contractor
                        )
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
                    if let pestRoutine {
                        _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                            pestRoutine,
                            in: householdId,
                            propertyId: propertyId
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
                    var irrigationRoutine: RoutineRow?
                    if let provider = answer.customText, !provider.isEmpty {
                        let utilityAccount: UtilityAccountRow?
                        if answer.selectedProviderId != nil {
                            utilityAccount = try await createUtilityAccount(from: answer, fallbackType: "irrigation")
                        } else {
                            utilityAccount = try await createUtilityAccount(name: provider, type: "irrigation")
                        }
                        let contractor = await matchedContractor(for: utilityAccount)
                        irrigationRoutine = await ensureLinkedRoutineForProviderContext(
                            providerType: "irrigation",
                            utilityAccount: utilityAccount,
                            contractor: contractor
                        )
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
                    if let irrigationRoutine {
                        _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                            irrigationRoutine,
                            in: householdId,
                            propertyId: propertyId
                        )
                    }
                }

            // Phase 67D (A6): Q14b irrigation_months dropped — months
            // capture moves to Phase C3's AnnualRhythmScreen. The
            // `irrigation_active_months` attribute stays alive (preserved
            // by migration) for AnnualRhythmScreen pre-fill.

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
                    var securityRoutine: RoutineRow?
                    let hasMonitoredProvider = id == "monitored"
                        && (answer.customText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                    // Build 87 (search picker): catalog-aware path when
                    // the user picked from the search picker.
                    if hasMonitoredProvider, let provider = answer.customText {
                        let utilityAccount: UtilityAccountRow?
                        if answer.selectedProviderId != nil {
                            utilityAccount = try await createUtilityAccount(from: answer, fallbackType: "security")
                        } else {
                            utilityAccount = try await createUtilityAccount(name: provider, type: "security")
                        }
                        let contractor = await matchedContractor(for: utilityAccount)
                        securityRoutine = await ensureLinkedRoutineForProviderContext(
                            providerType: "security",
                            utilityAccount: utilityAccount,
                            contractor: contractor
                        )
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
                    if let securityRoutine {
                        _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                            securityRoutine,
                            in: householdId,
                            propertyId: propertyId
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

                    // Phase 63 (+ Bug B5 refinement): derive 3-way handyman
                    // preference from chip state + existing household state.
                    // Captured as `properties.attributes.handyman_preference`:
                    //   - "has_one"    → handyman chip selected with a provider
                    //                    OR a Handyman-category contractor
                    //                    already exists in the household
                    //                    (from a prior quiz / manual add)
                    //   - "needs_help" → handyman chip selected WITHOUT a
                    //                    provider and no existing handyman
                    //   - "does_diy"   → no handyman chip, no existing handyman
                    // Users can override this later from Settings → Task
                    // Preferences → Handyman preference.
                    let handymanSelected = selected.contains("handyman")
                    let handymanProviderCaptured = (answer.customEntries ?? [])
                        .compactMap { Self.parseContractorChipEntry($0) }
                        .contains { $0.chipId == "handyman" }
                    let preExistingContractors = (try? await db.fetchContractors()) ?? []
                    let existingHandymanContractor = preExistingContractors.contains {
                        $0.category?.caseInsensitiveCompare("Handyman") == .orderedSame
                    }
                    let handymanPreference: String
                    if (handymanSelected && handymanProviderCaptured) || existingHandymanContractor {
                        handymanPreference = "has_one"
                    } else if handymanSelected {
                        handymanPreference = "needs_help"
                    } else {
                        handymanPreference = "does_diy"
                    }
                    try await persistAttribute("handyman_preference", value: handymanPreference)

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
                            // Build 83: stash rating/reviews/Top-Rated
                            // tag in `notes` so the contractor list can show
                            // attribution without a schema migration. The
                            // contractors table has no rating/review/certified
                            // columns yet — when we add them, this can move.
                            insert.notes = parsed.attributionNotes()
                            // Round 4: pass `skipRoutineSeed: true` so
                            // `RoutineSeeder.seedIfNeeded` does NOT
                            // fire-and-forget alongside our explicit
                            // `ensureVendorRoutineForCategory` below.
                            // Without this skip, both paths race on the
                            // dedup fetch+insert and Burke-style duplicate
                            // routines land in the routines table.
                            let createdContractor = try? await db.createContractor(insert, skipRoutineSeed: true)

                            // Phase 63: the handyman chip is special — when
                            // the user provides a named handyman, link them
                            // to the household as the preferred one. Used by
                            // the routing affordance ("Add to Mike's list"),
                            // Alfred context, and the FindHandymanCard.
                            if chipId == "handyman", let contractor = createdContractor {
                                var update = HouseholdUpdate()
                                update.preferredHandymanContractorId = contractor.id
                                _ = try? await db.updateHousehold(id: householdId, update)
                            }

                            // Phase 66: create an ACTIVE routine for this
                            // category with the captured contractor as
                            // vendor_id. Day1TaskCurator finds active
                            // routines here when routing vendor tasks —
                            // creating the routine at Q15b means the
                            // curator routes into it instead of falling
                            // back to a pending-vendor routine.
                            //
                            // The handyman chip is intentionally excluded:
                            // handyman routines are on-demand singletons
                            // created lazily by `fetchOrCreateHandymanRoutine`
                            // (with the preferred handyman vendor linked
                            // via the household's preferred_handyman_contractor_id
                            // that we just stamped above).
                            if let contractor = createdContractor,
                               chipId != "handyman",
                               let kind = RoutineGroupingEngine.routineKindFor(systemCategory: category) {
                                await ensureVendorRoutineForCategory(
                                    kind: kind,
                                    category: category,
                                    contractor: contractor
                                )
                            }

                            // Round 5 (May 2026, friend feedback): the
                            // vendor was getting linked to the ROUTINE
                            // but NOT to the matching home_systems row.
                            // Result: PropertyDetailView's "Systems
                            // needing details" sheet kept showing
                            // "Landscaping — needs Service vendor" even
                            // though Blue Fox was captured in Q15b and
                            // surfaced everywhere else. Stamp
                            // home_systems.preferred_contractor_id so
                            // every surface that reads from the system
                            // (system details, gap sweeps, task
                            // reconciler) sees the vendor link.
                            if let contractor = createdContractor {
                                await linkContractorToMatchingSystems(
                                    contractor: contractor,
                                    category: category
                                )
                            }

                            // Phase 60.2 (F2): flip any already-materialized
                            // maintenance tasks in this category to vendor-
                            // managed now that the contractor is captured.
                            // Most categories create tasks AFTER Q15b (via
                            // reconcileAll at quiz completion) so this flip
                            // is typically a no-op during the first quiz
                            // pass. But on re-entry / back-nav / quiz-resume
                            // when tasks already exist, this catches them.
                            // The reconciler's `.vendor`-template path
                            // handles the auto-link case on fresh task
                            // creation via `matchingContractor`.
                            await flipCategoryTasksToVendor(
                                systemCategory: category,
                                providerName: providerName
                            )
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
                _ = try await createUtilityAccount(from: answer, fallbackType: "electric")

            case "q17_internet":
                _ = try await createUtilityAccount(from: answer, fallbackType: "internet_cable")

            case "q18_trash":
                // Phase 67D (A7): Q18 + Q18b merged. Service kind in
                // `answerId`; pickup day chips in `selectedIds`; optional
                // private hauler name in `customText`.
                try await persistAttribute("trash_service", value: answer.answerId)
                if answer.answerId == "private", let provider = answer.customText, !provider.isEmpty {
                    if answer.selectedProviderId != nil {
                        _ = try await createUtilityAccount(from: answer, fallbackType: "trash")
                    } else {
                        _ = try await createUtilityAccount(name: provider, type: "trash")
                    }
                }
                // Pickup days (formerly Q18b): only stamp + create routine
                // when the user picked at least one day. "Not sure" service
                // skips this entirely so we don't create a routine with no
                // days set.
                let trashDays = answer.selectedIds ?? []
                if !trashDays.isEmpty, answer.answerId != "not_sure" {
                    try await persistAttribute("trash_pickup_days", value: trashDays.joined(separator: ","))
                    let weekdays = weekdaysForTrashAnswer(trashDays)
                    let utilityAccounts = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
                    let wasteAccount = utilityAccounts.first(where: {
                        ["trash", "recycling", "compost", "yard_waste", "yardwaste"].contains($0.providerType.lowercased())
                    })
                    let contractor = await matchedContractor(for: wasteAccount)
                    _ = await ensureLinkedRoutineForProviderContext(
                        providerType: "trash",
                        utilityAccount: wasteAccount,
                        contractor: contractor,
                        weekdayOverride: weekdays
                    )
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
                _ = try await createUtilityAccount(from: answer, fallbackType: fallbackType)

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
                            _ = try await createUtilityAccount(from: propaneAnswer, fallbackType: "propane")
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
                    _ = try await createUtilityAccount(from: synthetic, fallbackType: fuel)
                }

            // Phase 67D (A2): Q23 vehicle count dropped — count is implicit
            // in the vehicle-add flow.

            case "q24_vehicle_add":
                // Vehicle creation goes through the dedicated AddVehicleView /
                // VehicleLookupService flow. The mapper just records whether
                // the user added a primary vehicle or skipped the step.
                // Phase 67D (A2): "skipped" path persists `false` so the
                // dashboard "no vehicles yet" empty state still surfaces.
                let added = answer.answerId == "skipped" ? "false" : "true"
                try await persistAttribute("primary_vehicle_added", value: added)

            case "q25_garage_ev":
                // Phase 67D (A8): Q25 + Q25b merged. Garage type in
                // `answerId`; EV charger yes/no in `payload["evCharger"]`.
                // Legacy build 85 answers ("attached_1" / "attached_2" /
                // "ev_l2") still normalize to "attached" so persisted
                // pre-67D rows round-trip cleanly.
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
                // EV charger from payload, with legacy "ev_l2" + selectedIds
                // fallbacks for pre-67D persisted answers. Only "yes" or
                // legacy ev_l2 creates the home_system row.
                let evCharger = answer.payload?["evCharger"]
                let legacyEv = answer.answerId == "ev_l2" || answer.selectedIds?.contains("ev_l2") == true
                if evCharger != nil {
                    try await persistAttribute("ev_charger_l2", value: evCharger)
                }
                if evCharger == "yes" || legacyEv {
                    try await ensureHomeSystem(name: "EV Charger (L2)", category: "Electrical")
                }

            case "q26_insurance":
                // Phase 67D (A9): Q26 + Q27 merged. Two independent provider
                // slots. Build a synthetic per-slot answer keeping
                // selectedProviderId for the catalog lookup, fall back to a
                // free-form name from `customEntries` when no catalog row
                // was picked.
                if let autoIdString = answer.payload?["autoProviderId"],
                   let autoId = UUID(uuidString: autoIdString) {
                    let synthetic = HouseQuizAnswer(
                        answerId: "selected",
                        selectedProviderId: autoId,
                        answeredAt: answer.answeredAt
                    )
                    _ = try await createUtilityAccount(from: synthetic, fallbackType: "auto_insurance")
                } else if let autoName = answer.customEntries?
                    .first(where: { $0.hasPrefix("auto:") })
                    .map({ String($0.dropFirst("auto:".count)) }), !autoName.isEmpty {
                    _ = try await createUtilityAccount(name: autoName, type: "auto_insurance")
                }
                if let homeIdString = answer.payload?["homeProviderId"],
                   let homeId = UUID(uuidString: homeIdString) {
                    let synthetic = HouseQuizAnswer(
                        answerId: "selected",
                        selectedProviderId: homeId,
                        answeredAt: answer.answeredAt
                    )
                    _ = try await createUtilityAccount(from: synthetic, fallbackType: "home_insurance")
                } else if let homeName = answer.customEntries?
                    .first(where: { $0.hasPrefix("home:") })
                    .map({ String($0.dropFirst("home:".count)) }), !homeName.isEmpty {
                    _ = try await createUtilityAccount(name: homeName, type: "home_insurance")
                }

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
                // Phase 67D (A10): Q28b pets folded into Q28's caretakers
                // chain via `payload["petsAnswerId"]`. Persists `pets` +
                // `has_pets` attributes and re-reconciles Synthetic Turf
                // (if any) so the pet sanitize task fires immediately.
                if let petsAnswerId = answer.payload?["petsAnswerId"] {
                    try await persistAttribute("pets", value: petsAnswerId)
                    let hasPets = petsAnswerId != "no_pets"
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
                }

            // Phase 67E/F admin feedback (06bceba6): Q29 "Estate documents
            // you have on hand?" was removed from the quiz library —
            // estate management moved to a future release. The case stays
            // here as a no-op so saved-for-later quiz state with the
            // legacy answer ID round-trips cleanly through the mapper.
            case "q29_estate_docs":
                break

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
                //
                // Phase 95.4 (2026-05-13): the full-household reconciler
                // does one sequential `updateMaintenanceTask` per
                // `.either` task in the household. On a mid-quiz user
                // who already has 30-60 either-tagged tasks, that's
                // 30-60 sequential round trips to Supabase — 5 to 10
                // seconds of perceived freeze on the question screen
                // because the answer's `persist(answer:)` path awaits
                // the mapper before calling `advance()`. Same pattern
                // Build 90 already detached for the completion-time
                // reconciler ("so the completion screen appears
                // immediately"); Q36 just never got the same treatment
                // because it was originally the LAST question and
                // didn't bottleneck UX. Now that it's the first
                // question of Chapter 2 (Phase 60-something quiz
                // reordering — display position 13/28), the block is
                // smack in the middle of the quiz and very visible.
                //
                // Fix: detach the reconciler. The tier attribute write
                // is still awaited so the next answer's mapper sees
                // the new tier. The detached pass posts the standard
                // refresh notifications when it finishes so any
                // background-visible maintenance surface picks up the
                // flipped rows. The completion screen counts tasks
                // straight from the DB (Build 90 fix), so dropping the
                // reconciliation totals from `reconciliationResult`
                // here doesn't affect the final reveal numbers.
                if let tierId = answer.answerId {
                    try await persistAttribute("vendor_preference_tier", value: tierId)
                    let householdIdCopy = householdId
                    Task.detached(priority: .utility) {
                        let result = await MaintenanceTaskReconciler.reconcileAllForHousehold(
                            householdId: householdIdCopy
                        )
                        await MainActor.run {
                            print("[HouseQuizAnswerMapper] q36 background reconcile done: added=\(result.added.count) removed=\(result.removed.count) preserved=\(result.preserved.count)")
                            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
                        }
                    }
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

    private func matchedContractor(for utilityAccount: UtilityAccountRow?) async -> ContractorRow? {
        guard let utilityAccount else { return nil }
        let contractors = (try? await db.fetchContractors()) ?? []

        if let providerId = utilityAccount.providerId,
           let exactProviderMatch = contractors.first(where: { $0.utilityProviderId == providerId }) {
            return exactProviderMatch
        }

        let normalizedName = utilityAccount.providerName.lowercased()
        let expectedCategory = UtilityContractorMirror.serviceCategory(forProviderType: utilityAccount.providerType)

        return contractors.first { contractor in
            guard contractor.companyName.lowercased() == normalizedName else { return false }
            guard let expectedCategory else { return true }

            let categoryMatches = contractor.category?.caseInsensitiveCompare(expectedCategory) == .orderedSame
            let specialtyMatches = contractor.specialties?.contains {
                $0.caseInsensitiveCompare(expectedCategory) == .orderedSame
            } == true
            return categoryMatches || specialtyMatches
        }
    }

    @discardableResult
    private func ensureLinkedRoutineForProviderContext(
        providerType: String,
        utilityAccount: UtilityAccountRow?,
        contractor: ContractorRow?,
        weekdayOverride: [Int]? = nil,
        activeMonthsOverride: [Int]? = nil
    ) async -> RoutineRow? {
        guard let defaults = RoutineSeeder.shared.defaults(forProviderType: providerType) else {
            return nil
        }

        let routineTitle = ServiceLibrary.serviceDefinition(forKey: defaults.serviceKey)?.homeownerTitle
            ?? defaults.label.replacingOccurrences(of: "_", with: " ").capitalized
        let shouldBeActive = utilityAccount != nil || contractor != nil || !defaults.kind.isVendorBased
        let icon = defaults.kind == .otherService
            ? MaintenanceHubIcon.icon(for: defaults.serviceKey)
            : defaults.kind.icon

        let routines = (try? await db.fetchRoutines(householdId: householdId)) ?? []
        let existing = routines.first { routine in
            guard routine.archivedAt == nil else { return false }
            guard routine.typedScope == .property else { return false }
            guard routine.propertyId == propertyId || routine.propertyId == nil else { return false }
            if defaults.kind == .otherService {
                return routine.resolvedServiceKey == defaults.serviceKey
            }
            return routine.resolvedServiceKey == defaults.serviceKey || routine.typedKind == defaults.kind
        }

        let resolvedWeekdays = weekdayOverride ?? defaults.daysOfWeek
        let resolvedActiveMonths = {
            guard let activeMonthsOverride, !activeMonthsOverride.isEmpty else {
                return defaults.activeMonths
            }
            return activeMonthsOverride.sorted()
        }()

        do {
            let routine: RoutineRow
            if let existing {
                var update = RoutineUpdate()
                update.label = routineTitle
                update.serviceKey = defaults.serviceKey
                update.sourceUtilityAccountId = utilityAccount?.id ?? existing.sourceUtilityAccountId
                if let contractor {
                    update.vendorId = contractor.id
                }
                update.icon = icon
                update.cadenceType = defaults.cadenceType.rawValue
                update.cadenceIntervalDays = defaults.cadenceIntervalDays
                update.daysOfWeek = resolvedWeekdays
                update.timeOfDay = defaults.timeOfDay
                update.activeMonths = resolvedActiveMonths
                update.eveningBeforeReminder = defaults.eveningBeforeReminder
                update.morningOfReminder = defaults.morningOfReminder
                update.setupState = shouldBeActive
                    ? RoutineSetupState.active.rawValue
                    : RoutineSetupState.pendingVendor.rawValue
                routine = try await db.updateRoutine(id: existing.id, update)
            } else {
                var insert = RoutineInsert(
                    householdId: householdId,
                    propertyId: propertyId,
                    label: routineTitle,
                    routineKind: defaults.kind.rawValue,
                    cadenceType: defaults.cadenceType.rawValue
                )
                insert.serviceKey = defaults.serviceKey
                insert.sourceUtilityAccountId = utilityAccount?.id
                insert.vendorId = contractor?.id
                insert.icon = icon
                insert.cadenceIntervalDays = defaults.cadenceIntervalDays
                insert.daysOfWeek = resolvedWeekdays
                insert.timeOfDay = defaults.timeOfDay
                insert.activeMonths = resolvedActiveMonths
                insert.eveningBeforeReminder = defaults.eveningBeforeReminder
                insert.morningOfReminder = defaults.morningOfReminder
                insert.cadenceSource = "quiz"
                insert.setupState = shouldBeActive
                    ? RoutineSetupState.active.rawValue
                    : RoutineSetupState.pendingVendor.rawValue
                routine = try await db.createRoutine(insert)
            }

            if shouldBeActive {
                _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                    routine,
                    in: householdId,
                    propertyId: propertyId
                )
            }
            return routine
        } catch {
            print("[HouseQuizAnswerMapper] Failed to ensure linked routine for \(providerType): \(error)")
            return nil
        }
    }

    private func weekdaysForTrashAnswer(_ selectedIds: [String]) -> [Int] {
        let mapping: [String: Int] = [
            "sun": 1,
            "mon": 2,
            "tue": 3,
            "wed": 4,
            "thu": 5,
            "fri": 6,
            "sat": 7,
        ]
        return selectedIds.compactMap { mapping[$0] }.sorted()
    }

    private func monthsForRoutineSeasonAnswer(_ selectedIds: [String]) -> [Int] {
        let mapping: [String: Int] = [
            "jan": 1,
            "feb": 2,
            "mar": 3,
            "apr": 4,
            "may": 5,
            "jun": 6,
            "jul": 7,
            "aug": 8,
            "sep": 9,
            "oct": 10,
            "nov": 11,
            "dec": 12,
        ]
        return selectedIds.compactMap { mapping[$0] }.sorted()
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
    private func createUtilityAccount(from answer: HouseQuizAnswer, fallbackType: String) async throws -> UtilityAccountRow? {
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
            return nil
        }

        let resolvedType = catalogProvider?.providerType ?? fallbackType

        // Avoid duplicates: skip if an account with this provider name already exists.
        let existing = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
        if let match = existing.first(where: { $0.providerName.lowercased() == resolvedName.lowercased() }) {
            // Even if the utility_account already exists, ensure the contractor
            // mirror is up to date for service categories.
            try? await mirrorContractorIfNeeded(name: resolvedName, providerType: resolvedType, catalogProvider: catalogProvider)
            return match
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
        let created = try await db.createUtilityAccount(insert)

        // Phase 19k: Mirror the vendor into the contractors table when this
        // is a service category. The reconciler picks up the row by category
        // match at task-creation time and auto-assigns vendor-managed tasks.
        try? await mirrorContractorIfNeeded(name: resolvedName, providerType: resolvedType, catalogProvider: catalogProvider)
        return created
    }

    /// Phase 18e: Name-only convenience wrapper for the legacy follow-up path
    /// (q11 lawn pro, q12 pool, q13 pest, q14 irrigation, q15 security,
    /// q18 trash). These questions are .singleChoice, not .providerSearch, so
    /// the user types a free-form name with no catalog ID.
    ///
    /// Phase 19k: Same contractor mirror as the picker-driven helper.
    private func createUtilityAccount(name: String, type: String) async throws -> UtilityAccountRow? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let existing = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
        if let match = existing.first(where: { $0.providerName.lowercased() == trimmed.lowercased() }) {
            try? await mirrorContractorIfNeeded(name: trimmed, providerType: type, catalogProvider: nil)
            return match
        }
        let insert = UtilityAccountInsert(
            propertyId: propertyId,
            householdId: householdId,
            providerType: type,
            providerName: trimmed
        )
        let created = try await db.createUtilityAccount(insert)

        try? await mirrorContractorIfNeeded(name: trimmed, providerType: type, catalogProvider: nil)
        return created
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
        let isTopRated: Bool
        let source: String

        /// Render a human caption for the contractor `notes` column so we can
        /// surface "Top-Rated \u{2022} 4.7 \u{2022} 120 reviews" without
        /// adding new columns. Returns nil when there's nothing to attribute
        /// (e.g. a manual-add row with no rating). The phrase "Chez Certified"
        /// is intentionally reserved for the upcoming human-verified vendor
        /// pipeline — never use it for the rating-derived heuristic.
        func attributionNotes() -> String? {
            var parts: [String] = []
            if isTopRated {
                parts.append("Top-Rated")
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
        // Phase 2.1: "chez:<chipId>" markers signal that the user
        // wants Chez to find a vendor for this category at quiz
        // completion. They never carry a vendor name and should
        // never produce a contractor row here. The Phase 2.2
        // submitter walks customEntries separately to extract these
        // markers and create the corresponding chez_requests. Prefix
        // ordering matters: "chez:lib:..." entries also start with
        // "chez:" so this check correctly catches both shapes.
        if raw.hasPrefix("chez:") { return nil }
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
            // Backward-compat: pre-Phase-71 entries serialized this slot as
            // "haven_certified". New entries use "top_rated". Accept either.
            let topRatedMarker = parts[6].trimmingCharacters(in: .whitespacesAndNewlines)
            let certified = topRatedMarker == "top_rated" || topRatedMarker == "haven_certified"
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
                isTopRated: certified,
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
            isTopRated: false,
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
    /// Phase 1.3: Public wrapper for the file-private chip → category
    /// switch. HouseQuizView uses it at render time to decide which
    /// SystemCategoryRegistry categories are already covered by a Q15b
    /// chip (so the LibraryPicker can omit them).
    static func householdContractorCategoryForExternal(chipId: String) -> String? {
        return householdContractorCategoryFor(chipId: chipId)
    }

    private static func householdContractorCategoryFor(chipId: String) -> String? {
        // Phase 1.3: library-sourced chip IDs carry a "lib:" prefix and
        // the canonical category key as the suffix. Route them through
        // SystemCategoryRegistry.canonical so verbose / aliased / cased
        // variants collapse to the same canonical category that the
        // existing contractor mirroring + vendor coverage flow expects.
        // Older clients that don't know the prefix harmlessly return nil
        // and skip the chip at apply time.
        if chipId.hasPrefix("lib:") {
            let raw = String(chipId.dropFirst(4))
            return SystemCategoryRegistry.canonical(category: raw) ?? raw
        }
        switch chipId {
        case "hvac_service":       return "HVAC"
        case "plumber":            return "Plumbing"
        case "electrician":        return "Electrical"
        case "roofer":             return "Roofing"
        case "septic_pumper":      return "Septic System"
        case "well_water_service": return "Well System"
        // Phase 60.6: chimney_sweep now maps to the "Chimney" registry
        // category (Tier 2, showInVendorCoverage: true). The previous
        // "Fire Protection" mapping pointed at a sub-system category
        // with `showInVendorCoverage: false`, so every chimney_sweep
        // chip the user picked was captured as a contractor but never
        // visible in Vendor Coverage. `canonicalizeContractorCategoriesOnceIfNeeded`
        // heals pre-60.6 rows by migrating "Fire Protection" → "Chimney".
        case "chimney_sweep":      return "Chimney"
        // Phase 60.6: tree_service maps to the dedicated "Tree Service"
        // Tier 2 registry category so arborist vendors show up on their
        // own row in Vendor Coverage instead of collapsing into
        // Landscaping. The `canonicalizeContractorCategoriesOnceIfNeeded`
        // backfill also migrates legacy "Landscaping"-stamped tree rows
        // only when specialties explicitly mention tree/arborist.
        case "tree_service":       return "Tree Service"
        // Phase 60.6: new chips. hardscape maps to Landscaping because
        // masonry/paver pros are usually Landscaping-category contractors
        // (and the Outdoor Hardscape system is created with subtype
        // "hardscape" under Landscaping). generator_service maps to
        // Generator so the backup-generator service vendor shows up in
        // Vendor Coverage instead of orphaning on "Electrical".
        case "hardscape":          return "Landscaping"
        case "generator_service":  return "Generator"
        // Phase 60.2 (F1): Handyman is a Tier 1 category post-Phase-58 with
        // spring/fall punch-list bundles. This mapping was silently nil for
        // weeks — users who picked a handyman at Q15b had their vendor
        // captured but zero handyman tasks were flipped to vendor-managed
        // (because flipCategoryTasksToVendor also didn't know about this
        // category; see flipCategoryTasksToVendor for the companion fix).
        case "handyman":           return "Handyman"
        // Phase 60.2 (F5): new vendor categories with RoutineSeeder wiring.
        // Each chip id maps to the canonical SystemCategoryRegistry key so
        // a contractor mirror lands with a recognized category string and
        // the matching RoutineSeeder archetype fires automatically (on
        // DatabaseService.createContractor → seedIfNeeded).
        case "cleaning":           return "Cleaning Service"
        case "snow_removal":       return "Snow Removal"
        case "mosquito_tick":      return "Mosquito & Tick"
        case "pet_waste":          return "Pet Waste"
        // Phase 67I new chips: pool / solar / security / waterproofing.
        // Each mirrors the captured contractor with a category that
        // matches existing template + system rows so the reconciler
        // auto-links them at task creation time.
        case "pool_service":       return "Pool/Spa"
        case "solar_service":      return "Solar"
        case "security_service":   return "Security System"
        // Waterproofing maps to "Crawl Space" — the only category in the
        // registry whose templates (foundation cracks, mold, vapor
        // barrier) match what a basement / waterproofing contractor
        // actually services. SystemCategoryRegistry aliases route
        // verbose contractor labels ("Waterproofing & Basement",
        // "Basement Waterproofing") onto the same canonical key.
        case "waterproofing":      return "Crawl Space"
        // Phase 1.1: gutter_cleaning and painter chips. Both categories
        // already live in SystemCategoryRegistry; the canonical key here
        // routes vendor coverage, routine seeding, and contractor
        // mirroring without any registry change.
        case "gutter_cleaning":    return "Gutter Cleaning"
        case "painter":            return "Painting"
        default:                   return nil
        }
    }

    /// Phase 66: Ensure an ACTIVE vendor routine exists for a category
    /// after Q15b captures a contractor. Idempotent — if a routine with
    /// this `(household, property, routine_kind)` is already active, we
    /// just update its vendor_id to point at the newly-captured contractor.
    ///
    /// This is what lets Day1TaskCurator route vendor tasks into the
    /// routine at quiz completion. Without an active routine for the
    /// category, the curator falls back to a pending-vendor routine —
    /// correct behavior, but we can do better when Q15b gave us the vendor.
    ///
    /// The handyman chip is excluded by the caller because the handyman
    /// routine is a lazy-created singleton managed by
    /// `fetchOrCreateHandymanRoutine` (seeded from the household's
    /// `preferred_handyman_contractor_id`).
    /// Round 5 (May 2026, friend feedback): stamp
    /// `home_systems.preferred_contractor_id` on every top-level system
    /// whose canonical category matches the contractor's. Burke saw
    /// "Landscaping needs a service vendor" in the Systems Needing
    /// Details sheet even after capturing Blue Fox in Q15b — the chip
    /// flow created the contractor and a vendor-linked routine but
    /// never set `preferred_contractor_id` on the existing
    /// home_systems row. Surfaces that read from the system (the
    /// recap sheet, vendor coverage sheet, task reconciler's matching
    /// contractor lookup, ContractorDetailView's "X system covered by
    /// this vendor" line) all key off this column.
    ///
    /// Skips systems that already have a `preferred_contractor_id` so
    /// re-runs / back-nav don't clobber a user's explicit pick. Uses
    /// `SystemCategoryRegistry.canonical(category:)` on both sides so
    /// "Plumbing & Heating" / "Plumbing" / "plumbing" variants all
    /// collapse to a single match.
    private func linkContractorToMatchingSystems(
        contractor: ContractorRow,
        category: String
    ) async {
        guard let targetCanonical = SystemCategoryRegistry.canonical(category: category) else { return }

        let systems = (try? await db.fetchHomeSystems(propertyId: propertyId)) ?? []
        for system in systems {
            // Top-level only; child systems inherit coverage from their parent.
            guard system.parentSystemId == nil else { continue }
            // Don't clobber a user's explicit pick.
            guard system.preferredContractorId == nil else { continue }
            guard let systemCanonical = SystemCategoryRegistry.canonical(category: system.category),
                  systemCanonical == targetCanonical else { continue }

            var update = HomeSystemUpdate()
            update.preferredContractorId = contractor.id
            _ = try? await db.updateHomeSystem(id: system.id, update)
        }
    }

    private func ensureVendorRoutineForCategory(
        kind: RoutineKind,
        category: String,
        contractor: ContractorRow
    ) async {
        do {
            let allRoutines = (try? await db.fetchRoutines(householdId: householdId)) ?? []
            // Find an existing routine of this kind for this property. If
            // the user re-enters the quiz with a different vendor pick,
            // update the existing routine's vendor_id in place.
            if let existing = allRoutines.first(where: {
                $0.typedKind == kind
                    && $0.typedScope == .property
                    && ($0.propertyId == propertyId || $0.propertyId == nil)
                    && $0.archivedAt == nil
            }) {
                // Only update if the vendor actually changed.
                if existing.vendorId != contractor.id || existing.typedSetupState != .active {
                    var update = RoutineUpdate()
                    update.vendorId = contractor.id
                    update.setupState = "active"
                    _ = try? await db.updateRoutine(id: existing.id, update)
                }
                return
            }

            // No existing routine — create one. Default cadence comes
            // from the routine kind's expected rhythm. The user can
            // refine later via the setup sheet.
            let (cadenceType, cadenceInterval, activeMonths) = defaultCadenceForQuizRoutine(kind: kind)
            var insert = RoutineInsert(
                householdId: householdId,
                propertyId: propertyId,
                label: routineLabel(kind: kind, vendor: contractor),
                routineKind: kind.rawValue,
                cadenceType: cadenceType.rawValue
            )
            if cadenceType == .customDays {
                insert.cadenceIntervalDays = cadenceInterval
            }
            insert.vendorId = contractor.id
            insert.icon = kind.icon
            insert.setupState = "active"
            insert.activeMonths = activeMonths
            let created = try? await db.createRoutine(insert)
            Analytics.track(.routineActivated, [
                "source": "q15b",
                "routine_kind": kind.rawValue,
                "category": category
            ])

            // Phase 66: run the grouping engine so any pre-existing
            // vendor tasks in this category get linked to the new
            // routine. Day1TaskCurator handles fresh reconcile-created
            // tasks; this covers the back-nav / re-answer case where
            // tasks already existed before the routine.
            if let routine = created {
                _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                    routine,
                    in: householdId,
                    propertyId: propertyId
                )
            }
        }
    }

    /// Phase 66: Default cadence per routine kind for routines created at
    /// Q15b. Matches Day1TaskCurator.defaultCadence but has category-
    /// specific active_months overrides for seasonal services (snow
    /// removal December-April, lawn care April-November, etc.).
    private func defaultCadenceForQuizRoutine(
        kind: RoutineKind
    ) -> (RoutineCadenceType, Int, [Int]) {
        let yearRound = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        switch kind {
        case .cleaning: return (.biweekly, 14, yearRound)
        case .landscaping: return (.weekly, 7, [4, 5, 6, 7, 8, 9, 10, 11])
        case .poolService: return (.weekly, 7, [5, 6, 7, 8, 9])
        case .pestControl: return (.quarterly, 91, yearRound)
        case .petWaste: return (.weekly, 7, yearRound)
        case .mosquitoTick: return (.monthly, 30, [4, 5, 6, 7, 8, 9, 10])
        case .snowRemoval: return (.annual, 365, [12, 1, 2, 3, 4])
        case .gutterCleaning: return (.semiannual, 182, yearRound)
        case .windowCleaning: return (.semiannual, 182, yearRound)
        case .treeService: return (.annual, 365, yearRound)
        case .handymanRecurring: return (.customDays, 9999, yearRound)
        default: return (.annual, 365, yearRound)
        }
    }

    /// Phase 66: Human-readable routine label for the Your Services card.
    /// Format: "Landscaping · Blue Fox" — reads naturally in the routines
    /// list and the services section.
    private func routineLabel(kind: RoutineKind, vendor: ContractorRow) -> String {
        let vendorLabel = vendor.companyName.isEmpty
            ? (vendor.contactName ?? kind.displayLabel)
            : vendor.companyName
        return "\(kind.displayLabel) · \(vendorLabel)"
    }

    /// Phase 19k / 54E.3: Mirrors a quiz-captured service vendor into
    /// the `contractors` table via the shared `UtilityContractorMirror`
    /// so the quiz, manual Add Utility sheet, and backfill all share
    /// one implementation. Idempotent. Errors are swallowed — the quiz
    /// must keep moving even if a mirror fails.
    private func mirrorContractorIfNeeded(
        name: String,
        providerType: String,
        catalogProvider: UtilityProviderRow?
    ) async throws {
        _ = try? await UtilityContractorMirror.mirrorIfNeeded(
            name: name,
            providerType: providerType,
            catalogProvider: catalogProvider,
            householdId: householdId,
            db: db
        )
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

                let newTitle = originalTitle
                let newDescription: String = {
                    if originalDescription.isEmpty {
                        return "\(contractor.companyName) will handle the work."
                    }
                    return "\(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(originalDescription)"
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

    // Phase 60.2 (F13): `createHardscapeMaintenanceTasks` was deleted.
    // Hardscape tasks now live in `MaintenanceTemplates.swift` with
    // `requiredSubtypes: ["hardscape"]` so they flow through the normal
    // reconciler path — dedup by templateKey, honor Q36 preference tier,
    // interpolate city/state, and flip to vendor cleanly when a
    // landscaping contractor is captured. The Q11 hardscape branch in
    // `apply(question:answer:)` now calls `MaintenanceTaskReconciler.reconcile`
    // directly with `confirmedSubtype: "hardscape"` instead of constructing
    // the four tasks inline.

    // MARK: - Phase 54A: Missing-system auto-create

    /// Phase 54A: US states where snow removal is a standing winter
    /// contract decision. Defines the "Northeast / Upper Midwest / Mountain
    /// West + Alaska" band where a plowing contract is a default-on
    /// expectation rather than a specialty opt-in.
    static let snowStates: Set<String> = [
        "MA", "CT", "RI", "NY", "NH", "VT", "ME", "NJ", "PA",
        "OH", "MI", "WI", "MN", "IA", "IL", "IN",
        "CO", "UT", "WY", "ID", "MT", "ND", "SD", "NE", "AK"
    ]

    static func isSnowState(_ state: String?) -> Bool {
        guard let raw = state?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return false }
        return snowStates.contains(raw.uppercased())
    }

    /// Outcome of `resolveChimneyRule`. `evidence` is for analytics/
    /// debug only and is never persisted to the home_system row.
    struct ChimneyRule {
        let shouldCreate: Bool
        let subtype: String?
        let evidence: String
    }

    /// Decide whether to auto-create a Chimney home_system row and
    /// which subtype it should carry. Single source of truth shared
    /// between the live quiz-completion path and the one-time
    /// migration in `AppState.migrateChimneyEvidenceOnceIfNeeded`.
    ///
    /// Precedence (Q20 fireplace evidence beats Q3 fuel evidence):
    ///   1. Fireplace row, name contains "wood"/"pellet" → `wood`
    ///   2. Fireplace row, name contains "propane"/"gas"  → `gas`
    ///   3. Fireplace row, name unclassifiable            → `wood` (defensive)
    ///   4. No fireplace, fossil-fuel heat
    ///      (natural_gas / oil / propane / not_sure)      → `furnace_flue`
    ///   5. Otherwise (electric, heat pump, geothermal,
    ///      electric baseboard, nil)                      → don't create
    ///
    /// `not_sure` on Q3 is treated as fossil because the NE TestFlight
    /// cohort overwhelmingly skews oil/gas. Worst case for the wrong
    /// guess: one harmless fall flue-inspection task the user dismisses.
    static func resolveChimneyRule(
        property: PropertyRow?,
        fireplaceSystem: HomeSystemRow?
    ) -> ChimneyRule {
        if let fireplace = fireplaceSystem {
            let name = fireplace.name.lowercased()
            if name.contains("wood") || name.contains("pellet") {
                return ChimneyRule(shouldCreate: true, subtype: "wood", evidence: "q20_wood")
            }
            if name.contains("propane") || name.contains("gas") {
                return ChimneyRule(shouldCreate: true, subtype: "gas", evidence: "q20_gas")
            }
            // Fireplace row with an unrecognized name — default to wood
            // since that's the safer assumption (creosote is a fire risk
            // we'd rather over-warn than miss).
            return ChimneyRule(shouldCreate: true, subtype: "wood", evidence: "q20_unknown")
        }

        let heatingFuel = property?.attributes?["heating_fuel"]?.stringValue.lowercased()
        let fossilFuels: Set<String> = ["natural_gas", "oil", "propane", "not_sure"]
        if let fuel = heatingFuel, fossilFuels.contains(fuel) {
            return ChimneyRule(shouldCreate: true, subtype: "furnace_flue", evidence: "q3_fossil")
        }

        return ChimneyRule(shouldCreate: false, subtype: nil, evidence: "none")
    }

    /// Phase 54A: Instance entry point used by the quiz completion path.
    /// Delegates to the static helper so existing-user backfill on
    /// `AppState` can share the same rules without duplicating logic.
    func ensureAutoCreatedSystemsAtCompletion() async {
        await Self.ensureAutoCreatedSystems(
            propertyId: propertyId,
            householdId: householdId,
            db: db
        )
    }

    /// Phase 54A: Creates the `home_systems` rows that Vendor Coverage knows
    /// about but the quiz didn't directly ask for. Without these rows,
    /// the reconciler has no attach point for Handyman, Pet Waste,
    /// Mosquito & Tick, Chimney, or Snow Removal templates — so they
    /// stay invisible even when the gap-detection logic flags them as
    /// missing.
    ///
    /// Rules:
    /// - Always create: Siding/Exterior, Window Cleaning, Tree Service,
    ///   Driveway Sealcoating (most NE HNW homes have all four; Vendor
    ///   Coverage gives a one-tap "Not applicable" for exceptions).
    /// - Chimney — evidence-based via `resolveChimneyRule`:
    ///     - `wood` subtype if Q20 wood/pellet fireplace
    ///     - `gas` subtype if Q20 propane/gas fireplace
    ///     - `furnace_flue` subtype if Q3 = fossil-fuel heat
    ///       (natural_gas / oil / propane / not_sure) and no Q20 fireplace
    ///     - No row at all if all-electric (heat pump / geothermal /
    ///       electric baseboard) AND no fireplace
    /// - Pending-vendor routines (Handyman / Mosquito & Tick / Snow
    ///   Removal / Pet Waste) are seeded by
    ///   `RoutineSeeder.ensureSystemlessRoutines` further down, no
    ///   longer as `home_systems` rows.
    ///
    /// Idempotent: categories that already have a top-level system row
    /// are skipped. Callers should run the reconciler afterward so
    /// templates attach to the new rows.
    @MainActor
    static func ensureAutoCreatedSystems(
        propertyId: UUID,
        householdId: UUID,
        db: DatabaseService = .shared
    ) async {
        let property = try? await db.fetchProperty(id: propertyId)
        let systems = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
        let existingCategories: Set<String> = Set(systems.map { $0.category.lowercased() })

        let hasPets = property?.attributes?["has_pets"]?.stringValue == "true"

        let fireplaceSystem = systems.first { $0.category.caseInsensitiveCompare("Fireplace") == .orderedSame }
        let chimneyRule = Self.resolveChimneyRule(property: property, fireplaceSystem: fireplaceSystem)

        let isSnow = isSnowState(property?.state)

        struct Rule {
            let category: String
            let subtype: String?
            let shouldCreate: Bool
            let evidence: String?
        }

        // Chez v1: service-shaped categories (Handyman, Mosquito &
        // Tick, Trash & Recycling, Pet Waste, Snow Removal) are no
        // longer auto-created as `home_systems` rows — they're
        // recurring vendor visits, not equipment with brand/model/
        // serial. Instead they become pending-vendor routines via
        // `RoutineSeeder.ensureSystemlessRoutines` below.
        //
        // Chimney is evidence-based: we create the row only when
        // positive evidence exists (Q20 fireplace OR Q3 fossil-fuel
        // heat). See `resolveChimneyRule` for the decision tree.
        // An all-electric townhome with no fireplace gets no chimney
        // row at all — the prior "default to wood" behavior shipped
        // a creosote warning to households with no flue, which read
        // as the app not understanding the home.
        //
        // The remaining universal rules (Siding/Exterior, Window
        // Cleaning, Tree Service, Driveway Sealcoating) are kept from
        // the Phase 70.A1 H4 over-populate-by-default approach — most
        // NE HNW homes have siding, windows, trees, and a driveway,
        // and Vendor Coverage gives a one-tap "Not applicable" for
        // the rare exception. We deliberately skip Deck/Outdoor,
        // Painting, and Gutter Cleaning — their work items live under
        // Siding/Exterior + Roofing bundles, so auto-creating empty
        // system rows would be noise without any seeded tasks.
        let rules: [Rule] = [
            .init(category: "Chimney", subtype: chimneyRule.subtype, shouldCreate: chimneyRule.shouldCreate, evidence: chimneyRule.evidence),
            .init(category: "Siding/Exterior", subtype: nil, shouldCreate: true, evidence: nil),
            .init(category: "Window Cleaning", subtype: nil, shouldCreate: true, evidence: nil),
            .init(category: "Tree Service", subtype: nil, shouldCreate: true, evidence: nil),
            .init(category: "Driveway Sealcoating", subtype: nil, shouldCreate: true, evidence: nil),
            // Phase 67 fix: Air Quality removed — see prior comment.
        ]

        for rule in rules {
            guard rule.shouldCreate,
                  !existingCategories.contains(rule.category.lowercased()) else { continue }

            let displayName = SystemCategoryRegistry.metaForCategory(rule.category)?.displayName
                ?? rule.category

            var insert = HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: displayName,
                category: rule.category,
                notes: "Auto-created by Chez so vendor coverage stays complete."
            )
            insert.subtype = rule.subtype
            if rule.category == "Chimney", let evidence = rule.evidence {
                Analytics.track(.chimneyAutoCreated, ["evidence": evidence])
            }
            _ = try? await db.createHomeSystem(insert)
        }

        // Chez v1: seed pending-vendor routines for the service-shaped
        // categories that used to live as home_systems rows. Idempotent
        // — `RoutineSeeder.ensureSystemlessRoutines` skips any kind for
        // which a routine already exists.
        await RoutineSeeder.shared.ensureSystemlessRoutines(
            propertyId: propertyId,
            householdId: householdId,
            hasPets: hasPets,
            isSnowState: isSnow
        )
    }
}
