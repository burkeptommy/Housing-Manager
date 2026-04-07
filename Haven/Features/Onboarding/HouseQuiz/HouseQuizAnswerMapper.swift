import Foundation

/// Dispatcher that translates a HouseQuiz answer into the corresponding
/// database side-effects (properties.attributes, home_systems, vehicles,
/// utility_accounts, family_members, maintenance_tasks).
///
/// Real-time persistence: every question fires this immediately on tap so
/// progress is durable even if the user force-quits mid-quiz.
@MainActor
final class HouseQuizAnswerMapper {
    let householdId: UUID
    let propertyId: UUID
    private let db = DatabaseService.shared

    init(householdId: UUID, propertyId: UUID) {
        self.householdId = householdId
        self.propertyId = propertyId
    }

    /// Persist the answer's side effects. Errors are logged and swallowed —
    /// the quiz must keep moving even if a single side-effect write fails.
    func apply(question: HouseQuizQuestion, answer: HouseQuizAnswer) async {
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
                    if let subtype {
                        await MaintenanceTaskMigrator.addSubtypeTasks(
                            propertyId: propertyId,
                            householdId: householdId,
                            systemCategory: "Roofing",
                            systemId: systemId,
                            newSubtype: subtype
                        )
                    }
                }

            case "q2_siding":
                try await persistAttribute("siding_material", value: answer.answerId)

            case "q3_heating_fuel":
                try await persistAttribute("heating_fuel", value: answer.answerId)
                let hvacSubtype = Self.hvacSubtype(forFuel: answer.answerId)
                let hvacSystemId = try await ensureHomeSystem(
                    name: "HVAC System",
                    category: "HVAC",
                    subtype: hvacSubtype,
                    matchByCategory: true
                )
                if let hvacSubtype {
                    await MaintenanceTaskMigrator.addSubtypeTasks(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemCategory: "HVAC",
                        systemId: hvacSystemId,
                        newSubtype: hvacSubtype
                    )
                }

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
                    try await ensureHomeSystem(name: "Well System", category: "Well System")
                }

            case "q7_sewer_septic":
                try await persistAttribute("sewer_or_septic", value: answer.answerId)
                if answer.answerId == "septic" {
                    try await ensureHomeSystem(name: "Septic System", category: "Septic System")
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
                if let heaterSubtype {
                    await MaintenanceTaskMigrator.addSubtypeTasks(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemCategory: "Water Heater",
                        systemId: heaterSystemId,
                        newSubtype: heaterSubtype
                    )
                }

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
                    await MaintenanceTaskMigrator.addSubtypeTasks(
                        propertyId: propertyId,
                        householdId: householdId,
                        systemCategory: "Landscaping",
                        systemId: lawnSystemId,
                        newSubtype: "lawn"
                    )
                    if answer.answerId == "pro", let provider = answer.customText, !provider.isEmpty {
                        try await createUtilityAccount(name: provider, type: "landscaping")
                    }
                }

            case "q12_pool":
                try await persistAttribute("pool_type", value: answer.answerId)
                if let id = answer.answerId, id != "none" {
                    let parentId = try await ensureHomeSystem(name: "Pool/Spa", category: "Pool/Spa")
                    if let parentId {
                        try await ensureChildSystem(parentId: parentId, name: "Pool Pump", category: "Pool/Spa")
                        try await ensureChildSystem(parentId: parentId, name: "Pool Filter", category: "Pool/Spa")
                        try await ensureChildSystem(parentId: parentId, name: "Pool Heater", category: "Pool/Spa")
                    }
                    if let provider = answer.customText, !provider.isEmpty {
                        try await createUtilityAccount(name: provider, type: "pool_service")
                    }
                }

            case "q13_pest":
                try await persistAttribute("pest_control", value: answer.answerId)
                if answer.answerId == "quarterly_pro" || answer.answerId == "termite_bond" {
                    try await ensureHomeSystem(name: "Pest Control", category: "Pest Control")
                    if let provider = answer.customText, !provider.isEmpty {
                        try await createUtilityAccount(name: provider, type: "pest_control")
                    }
                }

            case "q14_irrigation":
                try await persistAttribute("irrigation", value: answer.answerId)
                if answer.answerId == "full" || answer.answerId == "drip" {
                    try await ensureHomeSystem(name: "Irrigation System", category: "Irrigation")
                    if let provider = answer.customText, !provider.isEmpty {
                        try await createUtilityAccount(name: provider, type: "irrigation")
                    }
                }

            case "q15_security":
                try await persistAttribute("security_system", value: answer.answerId)
                if let id = answer.answerId, id != "none" {
                    try await ensureHomeSystem(name: "Security System", category: "Security System")
                    if let provider = answer.customText, !provider.isEmpty {
                        try await createUtilityAccount(name: provider, type: "security")
                    }
                }

            case "q16_electric":
                if let provider = answer.customText, !provider.isEmpty {
                    try await createUtilityAccount(name: provider, type: "electric")
                }

            case "q17_internet":
                if let provider = answer.customText, !provider.isEmpty {
                    try await createUtilityAccount(name: provider, type: "internet_cable")
                }

            case "q18_trash":
                try await persistAttribute("trash_service", value: answer.answerId)
                if answer.answerId == "private", let provider = answer.customText, !provider.isEmpty {
                    try await createUtilityAccount(name: provider, type: "trash")
                }

            case "q19_heating_provider":
                if let provider = answer.customText, !provider.isEmpty {
                    // Use the heating fuel attribute (q3) as a hint when known so
                    // the new utility account is filed under the right type.
                    var providerType = "oil"
                    if let property = try? await db.fetchProperty(id: propertyId),
                       let fuel = property.attributes?["heating_fuel"]?.stringValue {
                        switch fuel {
                        case "natural_gas": providerType = "natural_gas"
                        case "propane": providerType = "propane"
                        case "oil": providerType = "oil"
                        default: break
                        }
                    }
                    try await createUtilityAccount(name: provider, type: providerType)
                }

            case "q20_other_fuels":
                if let selected = answer.selectedIds {
                    try await persistAttribute("other_fuel_sources", value: selected.joined(separator: ","))
                }

            case "q21_solar":
                try await persistAttribute("solar", value: answer.answerId)
                if answer.answerId == "owned" || answer.answerId == "leased" {
                    try await ensureHomeSystem(name: "Solar Panels", category: "Solar")
                }

            case "q22_generator":
                try await persistAttribute("generator", value: answer.answerId)
                if answer.answerId == "whole_home" || answer.answerId == "portable" {
                    try await ensureHomeSystem(name: "Backup Generator", category: "Generator")
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
                try await persistAttribute("garage_type", value: answer.answerId)
                if let id = answer.answerId, id != "none", id != "ev_l2" {
                    try await ensureHomeSystem(name: "Garage Door", category: "Garage Door")
                }
                if answer.answerId == "ev_l2" || answer.selectedIds?.contains("ev_l2") == true {
                    try await ensureHomeSystem(name: "EV Charger (L2)", category: "Electrical")
                }

            case "q26_auto_insurance":
                if let provider = answer.customText, !provider.isEmpty {
                    try await createUtilityAccount(name: provider, type: "auto_insurance")
                }

            case "q27_homeowners_insurance":
                if let provider = answer.customText, !provider.isEmpty {
                    // Phase 16b: keep the utility_account row aligned with the
                    // seeded "home_insurance" provider_type from Phase 16a so
                    // search and write paths use the same vocabulary.
                    try await createUtilityAccount(name: provider, type: "home_insurance")
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

            case "q29_estate_docs":
                if let selected = answer.selectedIds {
                    try await persistAttribute("estate_documents_on_hand", value: selected.joined(separator: ","))
                }

            case "q30_priorities":
                if let selected = answer.selectedIds {
                    try await persistAttribute("priorities", value: selected.joined(separator: ","))
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
    @discardableResult
    private func ensureHomeSystem(
        name: String,
        category: String,
        subtype: String? = nil,
        matchByCategory: Bool = false
    ) async throws -> UUID? {
        let existing = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
        let match: HomeSystemRow? = matchByCategory
            ? existing.first(where: {
                $0.category.lowercased() == category.lowercased() && $0.parentSystemId == nil
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

    /// Translate a `q3_heating_fuel` answer id into an HVAC system subtype.
    /// Fuel type does not uniquely determine HVAC configuration, so this is
    /// a pragmatic heuristic the user can correct from the system detail
    /// screen if it's wrong. The goal is to surface relevant maintenance
    /// tasks (e.g. furnace tune-up for gas, heat pump service for electric)
    /// rather than nothing at all.
    fileprivate static func hvacSubtype(forFuel fuel: String?) -> String? {
        switch fuel {
        case "natural_gas", "propane": return "central_ducted"
        case "oil": return "boiler_radiant"
        case "electric": return "heat_pump"
        case "geothermal": return "geothermal"
        default: return nil
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

    private func createUtilityAccount(name: String, type: String) async throws {
        // Avoid duplicates: skip if an account with this provider name already exists.
        let existing = (try? await db.fetchUtilityAccounts(propertyId: propertyId)) ?? []
        if existing.contains(where: { $0.providerName.lowercased() == name.lowercased() }) {
            return
        }
        let insert = UtilityAccountInsert(
            propertyId: propertyId,
            householdId: householdId,
            providerType: type,
            providerName: name
        )
        _ = try await db.createUtilityAccount(insert)
    }

    private func digitsOnly(_ s: String) -> String {
        s.filter { $0.isNumber }
    }
}
