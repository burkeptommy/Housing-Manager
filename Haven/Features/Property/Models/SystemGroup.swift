import SwiftUI

/// Groups home systems into logical categories for the property detail grid.
struct SystemGroup: Identifiable {
    let id: String
    let name: String
    let icon: String
    let systems: [HomeSystemRow]

    /// Categories that belong to each group
    private static let climateCategories: Set<String> = [
        "hvac", "heating", "air conditioning", "water heater", "solar", "generator", "insulation"
    ]

    private static let exteriorCategories: Set<String> = [
        "roofing", "siding/exterior", "windows", "doors", "garage door",
        "landscaping", "irrigation", "fencing", "pest control"
    ]

    private static let plumbingCategories: Set<String> = [
        "plumbing", "septic system", "well system", "pool/spa"
    ]

    private static let safetyCategories: Set<String> = [
        "electrical", "security system", "fire protection", "elevator"
    ]

    private static let applianceCategories: Set<String> = [
        "appliance"
    ]

    static func groupId(for category: String) -> String {
        let cat = category.lowercased()
        if climateCategories.contains(cat) { return "climate" }
        if exteriorCategories.contains(cat) { return "exterior" }
        if plumbingCategories.contains(cat) { return "plumbing" }
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

        // Define display order and metadata
        let definitions: [(id: String, name: String, icon: String)] = [
            ("climate", "Climate & Energy", "thermometer.sun.fill"),
            ("exterior", "Structure & Exterior", "house.fill"),
            ("plumbing", "Plumbing & Water", "drop.fill"),
            ("safety", "Safety & Electrical", "bolt.shield.fill"),
            ("appliances", "Appliances", "refrigerator.fill"),
            ("other", "Other Systems", "gearshape.fill"),
        ]

        return definitions.compactMap { def in
            guard let systems = grouped[def.id], !systems.isEmpty else { return nil }
            return SystemGroup(id: def.id, name: def.name, icon: def.icon, systems: systems)
        }
    }
}
