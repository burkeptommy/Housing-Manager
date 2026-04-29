import Foundation

/// Chez v1: pre-fills `home_systems.install_date` from the property's
/// ATTOM-sourced `year_built` for system categories that almost always
/// match the home's age.
///
/// Three rules guide the list:
///   1. The system must have a meaningful "install date" — service-shaped
///      rows (pet waste, snow removal) have no install. Skip those.
///   2. The system must reasonably correlate with the home's age — roof,
///      foundation, original windows, and insulation usually do. HVAC,
///      water heaters, and appliances get replaced too often to anchor
///      to year-built — skip those.
///   3. Stamp `install_date_source = 'estimated'` and
///      `install_date_attom_prefilled = true` so the gamified coverage
///      flow reads "estimated from public records — confirm or correct".
///      User confirmation flips `install_date_confirmed_at`.
enum InstallDatePrefiller {
    /// Categories where year-built is a sensible default — structural
    /// shells and original cladding that almost always match the home's
    /// age unless explicitly replaced. Lowercased for case-insensitive
    /// `home_systems.category` matching.
    static let structuralPrefillCategories: Set<String> = [
        "roofing",
        "foundation",
        "attic & foundation",
        "crawl space",
        "attic",
        "basement",
        "insulation",
        "siding/exterior",
        "windows",
        "doors",
        "fencing",
    ]

    /// Categories where the PURCHASE date is often the better anchor —
    /// equipment that frequently gets replaced during the home-purchase
    /// process or shortly after (sellers replace on listing prep,
    /// inspectors flag, buyers refresh as a closing condition). Falls
    /// back to year-built when no purchase_date is on file.
    static let purchaseDateAnchoredCategories: Set<String> = [
        "hvac",
        "heating",
        "air conditioning",
        "water heater",
        "generator",
        "appliance",
        "garage door",
        "security system",
    ]

    /// Returns true if a given system row is eligible for pre-fill —
    /// matches a category set AND has no install date yet AND wasn't
    /// already pre-filled (idempotent).
    static func isEligibleForPrefill(_ system: HomeSystemRow) -> Bool {
        let category = system.category.lowercased()
        let inSet = structuralPrefillCategories.contains(category)
            || purchaseDateAnchoredCategories.contains(category)
        guard inSet else { return false }
        if let installDate = system.installDate, !installDate.isEmpty { return false }
        if system.installDateAttomPrefilled == true { return false }
        return true
    }

    /// Walks every home system on a property and pre-fills install_date
    /// for eligible rows. Two anchor strategies:
    ///   - Structural categories → property's `year_built`
    ///   - Replaceable equipment → property's `purchase_date` year
    ///     (falls back to `year_built` when no purchase date is on
    ///     file; never stamps when both are missing or invalid).
    ///
    /// All pre-filled rows land with `source = 'estimated'` and
    /// `attom_prefilled = true`, so the gamified coverage flow shows
    /// them as "Estimated from public records — confirm or correct"
    /// with a one-tap accept.
    @discardableResult
    static func prefill(
        propertyId: UUID,
        yearBuilt: Int,
        db: DatabaseService = .shared
    ) async -> Int {
        // Sanity: ATTOM occasionally returns garbage (year 1, 9999) for
        // properties without records. Bail rather than stamp nonsense.
        let currentYear = Calendar.current.component(.year, from: Date())
        guard yearBuilt >= 1700, yearBuilt <= currentYear else { return 0 }

        let yearBuiltDate = "\(yearBuilt)-01-01"

        // Read the purchase date so the second tier has its anchor.
        // Single property fetch — same DB hit count as the original
        // implementation since the sweep prep already does this.
        let property = try? await db.fetchProperty(id: propertyId)
        let purchaseYear: Int? = {
            guard let raw = property?.purchaseDate, raw.count >= 4,
                  let y = Int(raw.prefix(4)),
                  y >= 1700, y <= currentYear else { return nil }
            return y
        }()
        let purchaseAnchorDate: String = purchaseYear.map { "\($0)-01-01" } ?? yearBuiltDate

        do {
            let systems = try await db.fetchHomeSystems(propertyId: propertyId)
            let eligible = systems.filter(isEligibleForPrefill)
            guard !eligible.isEmpty else { return 0 }

            for system in eligible {
                let category = system.category.lowercased()
                let isoDate: String
                if structuralPrefillCategories.contains(category) {
                    isoDate = yearBuiltDate
                } else if purchaseDateAnchoredCategories.contains(category) {
                    isoDate = purchaseAnchorDate
                } else {
                    continue  // unreachable given isEligibleForPrefill
                }

                var update = HomeSystemUpdate()
                update.installDate = isoDate
                update.installDateSource = "estimated"
                update.installDateAttomPrefilled = true
                _ = try? await db.updateHomeSystem(id: system.id, update)
            }
            return eligible.count
        } catch {
            print("[InstallDatePrefiller] failed propertyId=\(propertyId.uuidString) error=\(error)")
            return 0
        }
    }
}
