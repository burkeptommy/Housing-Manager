import SwiftUI

/// Groups home systems into logical categories for the property detail grid.
struct SystemGroup: Identifiable {
    let id: String
    let name: String
    let icon: String
    let systems: [HomeSystemRow]

    /// Categories that belong to each group. Lowercased — `groupId(for:)`
    /// always lowercases incoming category strings.
    private static let climateCategories: Set<String> = [
        "hvac", "heating", "air conditioning", "water heater", "insulation", "electrical"
    ]

    private static let exteriorCategories: Set<String> = [
        "roofing", "siding/exterior", "windows", "doors", "garage door", "fencing",
        "foundation", "crawl space"
    ]

    private static let plumbingCategories: Set<String> = [
        "plumbing", "septic system", "well system", "water treatment", "water softener"
    ]

    private static let safetyCategories: Set<String> = [
        "fire protection", "elevator"
    ]

    private static let applianceCategories: Set<String> = [
        "appliance"
    ]

    /// Outdoor & landscaping — pulled out of plumbing/other so things like
    /// Landscaping, Pool/Spa, and Irrigation surface as their own group.
    private static let outdoorCategories: Set<String> = [
        "landscaping", "lawn care", "irrigation", "tree care", "pool/spa"
    ]

    /// Utilities & services — recurring services/providers the homeowner manages.
    private static let utilitiesCategories: Set<String> = [
        "internet", "electricity", "gas", "water service", "trash/recycling",
        "propane", "pest control", "security system"
    ]

    /// Backup & resilience — power continuity and water-out safeguards.
    private static let backupCategories: Set<String> = [
        "generator", "solar", "battery storage", "sump pump"
    ]

    static func groupId(for category: String) -> String {
        let cat = category.lowercased()
        if climateCategories.contains(cat) { return "climate" }
        if exteriorCategories.contains(cat) { return "exterior" }
        if plumbingCategories.contains(cat) { return "plumbing" }
        if outdoorCategories.contains(cat) { return "outdoor" }
        if utilitiesCategories.contains(cat) { return "utilities" }
        if backupCategories.contains(cat) { return "backup" }
        if safetyCategories.contains(cat) { return "safety" }
        if applianceCategories.contains(cat) { return "appliances" }
        return "other"
    }

    static func group(_ systems: [HomeSystemRow]) -> [SystemGroup] {
        var grouped: [String: [HomeSystemRow]] = [:]

        for system in systems {
            let gid = groupId(for: system.category)
            grouped[gid, default: []].append(system)
        }

        // Define display order and metadata. Order matters: real groups
        // appear before "Other Systems" so the user reads top→bottom in the
        // expected order.
        let definitions: [(id: String, name: String, icon: String)] = [
            ("climate", "Climate & Energy", "thermometer.sun.fill"),
            ("exterior", "Structure & Exterior", "house.fill"),
            ("plumbing", "Plumbing & Water", "drop.fill"),
            ("outdoor", "Outdoor & Landscaping", "leaf.fill"),
            ("backup", "Backup & Resilience", "powerplug.fill"),
            ("utilities", "Utilities & Services", "bolt.fill"),
            ("safety", "Safety", "flame.fill"),
            ("appliances", "Appliances", "refrigerator.fill"),
            ("other", "Other Systems", "gearshape.fill"),
        ]

        return definitions.compactMap { def in
            guard let systems = grouped[def.id], !systems.isEmpty else { return nil }
            return SystemGroup(id: def.id, name: def.name, icon: def.icon, systems: systems)
        }
    }
}
