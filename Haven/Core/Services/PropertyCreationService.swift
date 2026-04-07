import Foundation

/// The single entry point for creating a property with full ATTOM enrichment,
/// home-system auto-creation, and 12-month maintenance task generation. Used
/// by `AddPropertyFlow` (the in-app sheet) and `AddressConfirmationIntercept`
/// (the post-purge / zero-property fallback). One code path, one set of bugs
/// to fix, one consistent experience.
///
/// The pre-auth `OnboardingViewModel.complete()` flow has its own variant
/// because it also creates the household + primary user; this service is
/// scoped to the simpler "household already exists, add a property to it"
/// case.
actor PropertyCreationService {
    static let shared = PropertyCreationService()

    private init() {}

    /// Performs the full property creation flow.
    /// - Parameters:
    ///   - address: Street/unit/city/state/zip the user typed.
    ///   - householdId: The household to attach the new property to.
    ///   - propertyType: "Primary Residence", "Vacation Home", "Rental Property", "Land", etc.
    ///   - lookupResult: Optional pre-fetched ATTOM result. Pass nil to fetch fresh.
    /// - Returns: The new PropertyRow plus counts of systems and tasks created.
    func createProperty(
        address: AddressInput,
        householdId: UUID,
        propertyType: String,
        lookupResult: PropertyLookupResult? = nil
    ) async throws -> PropertyCreationResult {
        // 1. ATTOM lookup if the caller didn't already do one.
        var resolvedLookup = lookupResult
        if resolvedLookup == nil {
            let fullAddress = address.formatted
            if !fullAddress.isEmpty,
               let data = try? await HavenSupabase.propertyLookup(address: fullAddress) {
                struct LookupResponse: Decodable {
                    let success: Bool
                    let property: PropertyLookupResult?
                }
                if let response = try? JSONDecoder().decode(LookupResponse.self, from: data),
                   response.success {
                    resolvedLookup = response.property
                }
            }
        }
        let lookupSucceeded = resolvedLookup != nil

        // 2. Build the property insert. ATTOM-enriched values fall back to
        // the user's typed values when ATTOM has nothing.
        let propertyName = [address.street, address.city]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        var insert = PropertyInsert(
            householdId: householdId,
            name: propertyName.isEmpty ? "My Home" : propertyName,
            propertyType: resolvedLookup?.propertyType ?? propertyType,
            street: address.street.isEmpty ? nil : address.street,
            unit: address.unit.isEmpty ? nil : address.unit,
            city: address.city.isEmpty ? nil : address.city,
            state: address.state.isEmpty ? nil : address.state,
            zipCode: address.zipCode.isEmpty ? nil : address.zipCode,
            country: "US"
        )
        insert.yearBuilt = resolvedLookup?.yearBuilt
        insert.squareFootage = resolvedLookup?.squareFootage
        insert.purchasePrice = resolvedLookup?.lastSalePrice
        insert.currentEstimatedValue = resolvedLookup?.estimatedValue

        let property = try await DatabaseService.shared.createProperty(insert)

        // 3. Auto-create home systems. Universal systems (HVAC, Roof, Water
        // Heater, Electrical Panel) are always created so the Maintenance tab
        // never looks empty. Feature-detected systems (pool, garage, etc.)
        // only appear when ATTOM confirmed them.
        var systemsCreated = 0
        let systems = systemsFromFeatures(
            resolvedLookup?.features,
            propertyId: property.id,
            householdId: householdId,
            yearBuilt: resolvedLookup?.yearBuilt
        )
        for system in systems {
            if (try? await DatabaseService.shared.createHomeSystem(system)) != nil {
                systemsCreated += 1
            }
        }

        // 4. Generate the 12-month maintenance plan.
        var tasksCreated = 0
        let schedule = OnboardingScheduleGenerator.generate(
            from: resolvedLookup,
            state: address.state
        )
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for item in schedule {
            let nextDue = nextDueDate(forMonth: item.month, formatter: formatter)
            let task = MaintenanceTaskInsert(
                propertyId: property.id,
                householdId: householdId,
                title: item.title,
                frequency: item.frequency,
                nextDueDate: nextDue,
                description: item.description,
                priority: item.category == "HVAC" || item.category == "Plumbing" ? "High" : "Medium",
                isTemplateBased: true,
                isDiy: item.isDIY,
                costRange: item.estimatedCost
            )
            if (try? await DatabaseService.shared.createMaintenanceTask(task)) != nil {
                tasksCreated += 1
            }
        }

        return PropertyCreationResult(
            property: property,
            systemsCreated: systemsCreated,
            tasksCreated: tasksCreated,
            lookupSucceeded: lookupSucceeded
        )
    }

    // MARK: - Helpers

    private func nextDueDate(forMonth month: Int, formatter: DateFormatter) -> String {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        var year = currentYear
        if month < currentMonth { year += 1 }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 15
        let date = calendar.date(from: components) ?? now
        return formatter.string(from: date)
    }

    private func systemsFromFeatures(
        _ features: PropertyLookupResult.PropertyFeatures?,
        propertyId: UUID,
        householdId: UUID,
        yearBuilt: Int?
    ) -> [HomeSystemInsert] {
        var systems: [HomeSystemInsert] = []
        let install = yearBuilt.map { "\($0)-01-01" }
        let universalNotes = "Auto-created from address lookup. Update with details after the House Quiz."

        // ── Universal systems: always created regardless of ATTOM result ──

        systems.append(HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: "HVAC System",
            category: "HVAC",
            installDate: install,
            notes: universalNotes
        ))

        let roofName = features?.roofType.map { "\($0) Roof" } ?? "Roof"
        systems.append(HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: roofName,
            category: "Roofing",
            installDate: install,
            notes: universalNotes
        ))

        systems.append(HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: "Water Heater",
            category: "Water Heater",
            notes: universalNotes
        ))

        systems.append(HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: "Electrical Panel",
            category: "Electrical",
            installDate: install,
            notes: universalNotes
        ))

        // ── Feature-detected systems: only when ATTOM confirmed them ──

        guard let features else { return systems }

        if features.pool == true {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: features.poolType.map { "\($0) Pool" } ?? "Swimming Pool",
                category: "Pool/Spa",
                notes: "Auto-created from address lookup."
            ))
        }
        if features.garage == true {
            let spaces = features.garageSpaces.map { "\($0)-Car " } ?? ""
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: "\(spaces)Garage",
                category: "Garage Door",
                notes: "Auto-created from address lookup."
            ))
        }
        if features.fireplace == true {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: features.fireplaceType.map { "\($0) Fireplace" } ?? "Fireplace",
                category: "Fire Protection",
                notes: "Auto-created from address lookup."
            ))
        }
        if let foundation = features.foundationType, !foundation.isEmpty {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: "\(foundation) Foundation",
                category: "Foundation",
                notes: "Auto-created from address lookup."
            ))
            let lowered = foundation.lowercased()
            if lowered.contains("crawl") {
                systems.append(HomeSystemInsert(
                    propertyId: propertyId,
                    householdId: householdId,
                    name: "Crawl Space",
                    category: "Crawl Space",
                    notes: "Auto-created from address lookup."
                ))
            }
            if lowered.contains("basement") {
                systems.append(HomeSystemInsert(
                    propertyId: propertyId,
                    householdId: householdId,
                    name: "Basement",
                    category: "Basement",
                    notes: "Auto-created from address lookup."
                ))
            }
        }
        return systems
    }
}

// MARK: - Inputs / Outputs

/// Lightweight container for the address fields the AddressAutocompleteField
/// captures. Used by `PropertyCreationService` so callers don't have to pass
/// five separate strings.
struct AddressInput {
    var street: String
    var unit: String
    var city: String
    var state: String
    var zipCode: String

    var formatted: String {
        [street, unit, city, state, zipCode]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var isUsable: Bool {
        !street.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && !state.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

struct PropertyCreationResult {
    let property: PropertyRow
    let systemsCreated: Int
    let tasksCreated: Int
    /// `false` when ATTOM/RentCast returned no usable record. Caller can use
    /// this to render a softer "we couldn't pull public records but here's
    /// the basics" confirmation.
    let lookupSucceeded: Bool
}
