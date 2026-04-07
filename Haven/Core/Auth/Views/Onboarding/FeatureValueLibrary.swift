import Foundation

/// Per-feature value teasers shown on the AddressHookView preview.
/// Keyed by feature key — see `keys(from:)` for how `PropertyFeatures` maps in.
/// All copy uses the no-em-dashes house style.
enum FeatureValueLibrary {
    struct Entry {
        let key: String
        let title: String
        let icon: String
        let annualUpkeep: String
        let resaleImpact: String
    }

    static let entries: [String: Entry] = [
        "pool": Entry(
            key: "pool",
            title: "Your pool",
            icon: "drop.fill",
            annualUpkeep: "$4-7K/yr",
            resaleImpact: "+5% resale value"
        ),
        "fireplace": Entry(
            key: "fireplace",
            title: "Your fireplace",
            icon: "flame.fill",
            annualUpkeep: "$200/yr (chimney sweep)",
            resaleImpact: "Buyers pay 10% premium"
        ),
        "garage": Entry(
            key: "garage",
            title: "Your garage",
            icon: "car.fill",
            annualUpkeep: "$50/yr (door tune-up)",
            resaleImpact: "Essential for resale"
        ),
        "basement": Entry(
            key: "basement",
            title: "Your basement",
            icon: "rectangle.split.1x2.fill",
            annualUpkeep: "$100/yr (sump test)",
            resaleImpact: "Adds livable sq ft"
        ),
        "solar": Entry(
            key: "solar",
            title: "Your solar",
            icon: "sun.max.fill",
            annualUpkeep: "$200/yr (cleaning)",
            resaleImpact: "Adds $15K resale"
        ),
        "well": Entry(
            key: "well",
            title: "Your well",
            icon: "drop.triangle.fill",
            annualUpkeep: "$150/yr (annual test)",
            resaleImpact: "Independent water supply"
        ),
        "oilHeat": Entry(
            key: "oilHeat",
            title: "Your oil heat",
            icon: "fuelpump.fill",
            annualUpkeep: "$2-3K/yr (refills)",
            resaleImpact: "Tracking saves ~$400/yr"
        ),
        "asphaltRoof": Entry(
            key: "asphaltRoof",
            title: "Your asphalt roof",
            icon: "house.fill",
            annualUpkeep: "$200/yr (inspections)",
            resaleImpact: "Adds 3% to resale"
        ),
    ]

    /// Pull the relevant entry keys for a given `PropertyLookupResult.PropertyFeatures`.
    static func keys(from features: PropertyLookupResult.PropertyFeatures?) -> [String] {
        guard let features else { return [] }
        var keys: [String] = []

        if features.pool == true { keys.append("pool") }
        if features.fireplace == true { keys.append("fireplace") }
        if features.garage == true { keys.append("garage") }

        let foundation = (features.foundationType ?? "").lowercased()
        if foundation.contains("basement") { keys.append("basement") }

        let heatingFuel = (features.heatingFuel ?? "").lowercased()
        if heatingFuel.contains("oil") { keys.append("oilHeat") }

        let roofType = (features.roofType ?? "").lowercased()
        if roofType.contains("asphalt") || roofType.contains("composite") {
            keys.append("asphaltRoof")
        }

        return keys
    }

    static func resolve(keys: [String]) -> [Entry] {
        keys.compactMap { entries[$0] }
    }
}
