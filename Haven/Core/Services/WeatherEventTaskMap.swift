import Foundation

/// Phase 80 weather card prep checklist. One static array of items per
/// NWS event type. Items are read-only ("checked off" lives in
/// `WeatherPrepSheet`'s per-session state, not persisted) so the user
/// can quickly mark prep done during the alert window. Past-event recovery
/// items (e.g. "walk perimeter for downed limbs") are tagged
/// `phase: .post` so the sheet renders them under a "After the storm"
/// header.
struct WeatherPrepTask: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let phase: Phase
    let action: Action

    enum Phase {
        /// Do this before the alert window starts / during.
        case pre
        /// Do this after the alert ends.
        case post
    }

    enum Action: Hashable {
        /// Just mark done — no system integration.
        case markDone
        /// Open the Find-a-Pro flow with this system category pre-filled.
        case findVendor(category: String)
        /// Hand off to Chez via a concierge request.
        case askChez(category: String)
    }
}

enum WeatherEventTaskMap {
    /// Returns the prep checklist for the given NWS event type. Fallback
    /// to a single "review the alert" task when the event type isn't
    /// explicitly mapped (defense in depth — NWS evolves their event set
    /// occasionally; new events shouldn't break the sheet).
    static func tasks(for eventType: String) -> [WeatherPrepTask] {
        let lower = eventType.lowercased()
        if lower.contains("hard freeze") || lower.contains("extreme cold") {
            return hardFreezeTasks
        }
        if lower.contains("winter storm") || lower.contains("blizzard") || lower.contains("ice storm") {
            return winterStormTasks
        }
        if lower.contains("severe thunderstorm") || lower.contains("tornado") {
            return severeStormTasks
        }
        if lower.contains("hurricane") || lower.contains("tropical storm") {
            return hurricaneTasks
        }
        if lower.contains("excessive heat") {
            return heatTasks
        }
        if lower.contains("flash flood") || lower.contains("coastal flood") {
            return floodTasks
        }
        if lower.contains("red flag") {
            return redFlagTasks
        }
        return defaultTasks
    }

    // MARK: - Event-specific checklists

    private static let hardFreezeTasks: [WeatherPrepTask] = [
        .init(id: "freeze-drip", title: "Drip exposed faucets overnight",
              detail: "Bathroom + kitchen faucets on exterior walls. A pencil-thin trickle is enough. Running water doesn't freeze.",
              phase: .pre, action: .markDone),
        .init(id: "freeze-hoses", title: "Disconnect garden hoses",
              detail: "Drain and store. Cover outdoor spigots with foam covers if you have them.",
              phase: .pre, action: .markDone),
        .init(id: "freeze-cabinets", title: "Open cabinet doors on exterior walls",
              detail: "Lets the room's heat reach the plumbing inside the wall cavity.",
              phase: .pre, action: .markDone),
        .init(id: "freeze-heat-trace", title: "Verify heat trace cables are on",
              detail: "Check the breaker or switch for any heat tape on your gutters, roof edge, or exposed pipes.",
              phase: .pre, action: .markDone)
    ]

    private static let winterStormTasks: [WeatherPrepTask] = [
        .init(id: "storm-plow", title: "Confirm snow plow contractor for this storm",
              detail: "Call your plow vendor to confirm you're on the route. Don't assume. First-snow storms book out fast.",
              phase: .pre, action: .askChez(category: "Snow Removal")),
        .init(id: "storm-salt", title: "Stock salt and ice melt",
              detail: "Check the garage. Calcium chloride works down to -25°F; rock salt only to 5°F. Pet-safe brands available for around-the-walkway use.",
              phase: .pre, action: .markDone),
        .init(id: "storm-generator", title: "Test generator under load (30 min)",
              detail: "Run today so you know it's ready. Top off propane / verify natural-gas connection.",
              phase: .pre, action: .markDone),
        .init(id: "storm-charge", title: "Charge phones, flashlights, and battery packs",
              detail: "Pre-outage prep. Pull headlamps + battery lanterns out of storage too.",
              phase: .pre, action: .markDone),
        .init(id: "storm-after-walk", title: "After: walk perimeter for damage",
              detail: "Check the roof from the ground, look for downed limbs, confirm gutters are draining. Note anything that needs a vendor.",
              phase: .post, action: .markDone)
    ]

    private static let severeStormTasks: [WeatherPrepTask] = [
        .init(id: "storm-furniture", title: "Move outdoor furniture inside",
              detail: "Patio chairs, umbrellas, grills, planters, decor. Anything that could become a projectile in 60+ mph wind.",
              phase: .pre, action: .markDone),
        .init(id: "storm-generator-fuel", title: "Verify generator fuel + auto-transfer",
              detail: "Confirm propane level / natural-gas connection. If outage hits, the auto-transfer switch handles itself, but only if fuel is there.",
              phase: .pre, action: .markDone),
        .init(id: "storm-devices", title: "Charge devices + flashlights",
              detail: "Phones, tablets, portable power banks, headlamps. Plug in vehicles too if you have EVs.",
              phase: .pre, action: .markDone),
        .init(id: "storm-tree-cleanup", title: "After: arborist for downed limbs",
              detail: "Walk the property. Any limb above 4 inches in diameter or near power lines is an arborist call. Don't DIY it.",
              phase: .post, action: .findVendor(category: "Tree Service"))
    ]

    private static let hurricaneTasks: [WeatherPrepTask] = [
        .init(id: "hurricane-shutters", title: "Close storm shutters / board windows",
              detail: "If you have storm shutters, close them now. Otherwise plywood + screws over windows facing the storm.",
              phase: .pre, action: .markDone),
        .init(id: "hurricane-outdoor", title: "Move everything outdoor inside or anchor it",
              detail: "Furniture, grills, planters, decorative items, anything not bolted down.",
              phase: .pre, action: .markDone),
        .init(id: "hurricane-generator", title: "Top off generator fuel + test",
              detail: "Hurricane outages last days, not hours. Make sure you have enough propane / fuel for 72+ hours.",
              phase: .pre, action: .markDone),
        .init(id: "hurricane-water", title: "Stock drinking water + non-perishables",
              detail: "1 gallon per person per day, minimum 3 days. Plus shelf-stable food.",
              phase: .pre, action: .markDone),
        .init(id: "hurricane-evacuation", title: "Confirm evacuation plan if in flood zone",
              detail: "Know your route + destination. Inland family or hotel reservation if needed.",
              phase: .pre, action: .markDone),
        .init(id: "hurricane-after", title: "After: full property inspection",
              detail: "Roof, gutters, trees, foundation, basement, fence. Document everything for insurance before cleanup.",
              phase: .post, action: .askChez(category: "Roofing"))
    ]

    private static let heatTasks: [WeatherPrepTask] = [
        .init(id: "heat-ac", title: "Verify AC is keeping up",
              detail: "Walk every room with the thermostat set to 72°F. If any room is 4+°F over, the system is struggling. Call your HVAC tech.",
              phase: .pre, action: .findVendor(category: "HVAC")),
        .init(id: "heat-irrigation", title: "Bump irrigation runtime up 30-50%",
              detail: "Check local water restrictions first. Lawns and beds use significantly more water in 95°F+ heat.",
              phase: .pre, action: .markDone),
        .init(id: "heat-elderly", title: "Check on elderly family + pets",
              detail: "Make sure outdoor pets have water + shade. Bring small / elderly pets inside if 95°F+. Check elderly family members daily during heat events.",
              phase: .pre, action: .markDone),
        .init(id: "heat-condensate", title: "Check AC condensate drain pan",
              detail: "If you see standing water, the drain is clogging. Pour distilled vinegar down the access tee or call your HVAC tech.",
              phase: .pre, action: .markDone)
    ]

    private static let floodTasks: [WeatherPrepTask] = [
        .init(id: "flood-sump", title: "Test sump pump + battery backup",
              detail: "Pour a bucket of water into the sump pit. Confirm the pump kicks on, water clears, pump shuts off. Test backup by unplugging the primary briefly.",
              phase: .pre, action: .markDone),
        .init(id: "flood-gutters", title: "Clear gutter downspouts + extensions",
              detail: "Make sure water has a path away from the foundation. Extensions should reach 4-6 feet out.",
              phase: .pre, action: .markDone),
        .init(id: "flood-valuables", title: "Move basement valuables off the floor",
              detail: "Boxes onto shelving, electronics into the upper level. Anything water-sensitive goes up.",
              phase: .pre, action: .markDone),
        .init(id: "flood-after-foundation", title: "After: inspect basement + foundation",
              detail: "Look for water marks, new cracks, damp wall sections. Schedule a waterproofing pro if you see anything new.",
              phase: .post, action: .findVendor(category: "Crawl Space"))
    ]

    private static let redFlagTasks: [WeatherPrepTask] = [
        .init(id: "redflag-defensible", title: "Clear flammable debris from defensible space",
              detail: "Rake leaves, dead branches, pine needles within 30 ft of structures. Move firewood at least 30 ft from the house.",
              phase: .pre, action: .markDone),
        .init(id: "redflag-trees", title: "Inspect mature trees for stress",
              detail: "Drought-stressed limbs fall easily. Schedule an arborist if you see any brittle deadwood.",
              phase: .pre, action: .findVendor(category: "Tree Service")),
        .init(id: "redflag-irrigation", title: "Check irrigation against local water restrictions",
              detail: "Most fire-risk regions limit irrigation during Red Flag conditions. Adjust accordingly.",
              phase: .pre, action: .markDone)
    ]

    private static let defaultTasks: [WeatherPrepTask] = [
        .init(id: "default-review", title: "Review the NWS alert details",
              detail: "Open the National Weather Service forecast for specifics about timing, expected conditions, and recommended preparation.",
              phase: .pre, action: .markDone)
    ]
}
