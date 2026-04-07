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
                if let mat = answer.answerId {
                    try await ensureHomeSystem(name: "\(mat.capitalized) Roof", category: "Roofing")
                }

            case "q2_siding":
                try await persistAttribute("siding_material", value: answer.answerId)

            case "q3_heating_fuel":
                try await persistAttribute("heating_fuel", value: answer.answerId)
                try await ensureHomeSystem(name: "HVAC System", category: "HVAC")

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
                let name: String
                switch answer.answerId {
                case "tankless_gas", "tankless_electric": name = "Tankless Water Heater"
                case "heat_pump": name = "Heat Pump Water Heater"
                default: name = "Water Heater"
                }
                try await ensureHomeSystem(name: name, category: "Water Heater")

            case "q9_basement":
                try await persistAttribute("basement_type", value: answer.answerId)
                if answer.answerId == "finished_basement" || answer.answerId == "unfinished_basement" {
                    try await ensureHomeSystem(name: "Sump Pump", category: "Sump Pump")
                }
                if answer.answerId == "crawl_space" {
                    try await ensureHomeSystem(name: "Crawl Space", category: "Crawl Space")
                }

            case "q10_appliances":
                if let selected = answer.selectedIds {
                    try await persistAttribute("appliances_under_5_years", value: selected.joined(separator: ","))
                    for appliance in selected where appliance != "none" {
                        try await ensureHomeSystem(name: appliance.replacingOccurrences(of: "_", with: " ").capitalized, category: "Appliance")
                    }
                }

            case "q11_lawn":
                try await persistAttribute("lawn_status", value: answer.answerId)
                if answer.answerId == "diy" || answer.answerId == "pro" {
                    try await ensureHomeSystem(name: "Landscaping", category: "Landscaping")
                    if answer.answerId == "pro", let provider = answer.customText, !provider.isEmpty {
                        try await createUtilityAccount(name: provider, type: "lawn_care")
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
                    try await createUtilityAccount(name: provider, type: "electricity")
                }

            case "q17_internet":
                if let provider = answer.customText, !provider.isEmpty {
                    try await createUtilityAccount(name: provider, type: "internet")
                }

            case "q18_trash":
                try await persistAttribute("trash_service", value: answer.answerId)
                if answer.answerId == "private", let provider = answer.customText, !provider.isEmpty {
                    try await createUtilityAccount(name: provider, type: "trash_recycling")
                }

            case "q19_heating_provider":
                if let provider = answer.customText, !provider.isEmpty {
                    try await createUtilityAccount(name: provider, type: "heating_fuel")
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
                    try await createUtilityAccount(name: provider, type: "homeowners_insurance")
                }

            case "q28_household":
                if let id = answer.answerId {
                    try await persistAttribute("household_residents", value: id)
                }
                if let caretakers = answer.selectedIds, !caretakers.isEmpty {
                    try await persistAttribute("caretakers", value: caretakers.joined(separator: ","))
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
    @discardableResult
    private func ensureHomeSystem(name: String, category: String) async throws -> UUID? {
        // Match by name + category to avoid duplicates if the user revisits a question.
        let existing = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []
        if let match = existing.first(where: {
            $0.name.lowercased() == name.lowercased() && $0.category.lowercased() == category.lowercased()
        }) {
            return match.id
        }
        let insert = HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: name,
            category: category,
            notes: "Created from House Quiz."
        )
        let row = try await db.createHomeSystem(insert)
        return row.id
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
