import SwiftUI

/// Groups home systems into homeowner-friendly inventory categories.
struct SystemGroup: Identifiable {
    let id: String
    let name: String
    let icon: String
    let systems: [HomeSystemRow]

    /// Categories that belong to each group. Lowercased — `groupId(for:)`
    /// always lowercases incoming category strings.
    private static let climateCategories: Set<String> = [
        "hvac", "heating", "air conditioning", "heat pump", "thermostat",
        "ductwork", "boiler", "furnace", "mini split", "ventilation",
        "humidifier", "dehumidifier", "radiant heating", "radiant floor",
        "air quality"
    ]

    private static let structureCategories: Set<String> = [
        "roofing", "siding/exterior", "windows", "doors", "garage door", "fencing",
        "foundation", "crawl space", "chimney", "gutters", "gutter", "masonry",
        "attic & foundation", "painting"
    ]

    private static let plumbingCategories: Set<String> = [
        "plumbing", "septic system", "well system", "water treatment", "water softener",
        "water heater", "sump pump", "drainage"
    ]

    private static let electricalCategories: Set<String> = [
        "electrical", "electrical panel", "panel", "generator", "solar",
        "battery storage", "ev charger", "fire protection", "elevator"
    ]

    private static let applianceCategories: Set<String> = [
        "appliance"
    ]

    private static let outdoorCategories: Set<String> = [
        "landscaping", "lawn care", "irrigation", "tree care", "pool/spa",
        "hot tub", "deck/outdoor", "driveway sealcoating", "pressure washing",
        "snow removal", "mosquito & tick", "pet waste", "gutter cleaning"
    ]

    private static let securityCategories: Set<String> = [
        "security system", "smart home", "cameras", "alarm", "entry system"
    ]

    /// Categories that are recurring vendor SERVICES, not physical systems.
    /// Rows whose `category` falls in this set should never appear in the
    /// Systems grid — they live in the Services section (powered by routines)
    /// instead. The user's mental model: pet waste / pest control / cleaning
    /// are scheduled vendor visits, not equipment with brand/model/serial.
    static let serviceCategories: Set<String> = [
        "pet waste",
        "snow removal",
        "mosquito & tick",
        "pest control",
        "pressure washing",
        "gutter cleaning",
        "tree care",
        "tree service",
        "window cleaning",
        "cleaning",
        "cleaning service",        // legacy quiz writes this exact label
        "house cleaning",
        "trash & recycling",       // quiz auto-create label, services not systems
        "handyman"
    ]

    /// Returns true if the given system category represents a recurring
    /// vendor service rather than a physical system.
    static func isServiceCategory(_ category: String) -> Bool {
        serviceCategories.contains(category.lowercased())
    }

    static func groupId(for category: String) -> String {
        let cat = category.lowercased()
        if climateCategories.contains(cat) { return "climate" }
        if structureCategories.contains(cat) { return "structure" }
        if plumbingCategories.contains(cat) { return "plumbing" }
        if outdoorCategories.contains(cat) { return "outdoor" }
        if electricalCategories.contains(cat) { return "electrical" }
        if securityCategories.contains(cat) { return "security" }
        if applianceCategories.contains(cat) { return "appliances" }
        return "other"
    }

    static func group(_ systems: [HomeSystemRow]) -> [SystemGroup] {
        var grouped: [String: [HomeSystemRow]] = [:]

        for system in systems {
            // Service-typed rows (pet waste, snow removal, pest control,
            // etc.) live in the Services section as routines — never in the
            // physical Systems grid.
            if isServiceCategory(system.category) { continue }
            let gid = groupId(for: system.category)
            grouped[gid, default: []].append(system)
        }

        // Define display order and metadata. Order matters: real groups
        // appear before "Other Systems" so the user reads top→bottom in the
        // expected order.
        let definitions: [(id: String, name: String, icon: String)] = [
            ("climate", "Climate & HVAC", "thermometer.sun.fill"),
            ("structure", "Structure & Exterior", "house.fill"),
            ("plumbing", "Plumbing & Water", "drop.fill"),
            ("electrical", "Electrical & Safety", "bolt.fill"),
            ("outdoor", "Outdoor & Grounds", "leaf.fill"),
            ("security", "Security & Smart Home", "shield.lefthalf.filled"),
            ("appliances", "Appliances", "refrigerator.fill"),
            ("other", "Specialty Systems", "sparkles"),
        ]

        return definitions.compactMap { def in
            guard let systems = grouped[def.id], !systems.isEmpty else { return nil }
            return SystemGroup(id: def.id, name: def.name, icon: def.icon, systems: systems)
        }
    }
}

extension SystemGroup: Hashable {
    static func == (lhs: SystemGroup, rhs: SystemGroup) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
