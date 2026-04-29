import Foundation
import SwiftUI

// MARK: - Tier Model

/// Three-tier system classification for vendor coverage and property setup.
/// Tier 1 (universal) systems are auto-backfilled to every property.
/// Tier 2 (conditional) systems are quiz-driven based on property type/location.
/// Tier 3 (specialty) systems are user-discovered via the Browse sheet.
/// Sub-system tier hides items from Vendor Coverage (they live under parents).
enum SystemTier: Int, Comparable {
    case universal = 1
    case conditional = 2
    case specialty = 3
    case subSystem = 99

    static func < (lhs: SystemTier, rhs: SystemTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayLabel: String {
        switch self {
        case .universal: return "Essential"
        case .conditional: return "Common"
        case .specialty: return "Specialty"
        case .subSystem: return "Component"
        }
    }
}

// MARK: - Category Metadata

/// Static metadata for a system category. Lives in Swift code, not in DB.
/// The category key matches the `home_systems.category` column value.
struct SystemCategoryMeta: Identifiable {
    let id: String  // == categoryKey
    let categoryKey: String
    let displayName: String
    let tier: SystemTier
    let displayPriority: Int
    let icon: String  // SF Symbol
    let defaultCadence: String?
    let showInVendorCoverage: Bool
    let specialtyGroup: String?  // grouping for Browse Specialty sheet

    init(
        categoryKey: String,
        displayName: String,
        tier: SystemTier,
        displayPriority: Int,
        icon: String,
        defaultCadence: String? = nil,
        showInVendorCoverage: Bool = true,
        specialtyGroup: String? = nil
    ) {
        self.id = categoryKey
        self.categoryKey = categoryKey
        self.displayName = displayName
        self.tier = tier
        self.displayPriority = displayPriority
        self.icon = icon
        self.defaultCadence = defaultCadence
        self.showInVendorCoverage = showInVendorCoverage
        self.specialtyGroup = specialtyGroup
    }
}

// MARK: - Registry

/// Swift-side source of truth for system tier classification, display order,
/// and vendor coverage visibility. No DB table needed -- categories remain
/// as strings on `home_systems.category`.
enum SystemCategoryRegistry {

    // MARK: - Tier 1: Universal (every home needs these)

    static let universal: [SystemCategoryMeta] = [
        .init(categoryKey: "Roofing", displayName: "Roof", tier: .universal,
              displayPriority: 10, icon: "house.fill", defaultCadence: "Annually"),
        .init(categoryKey: "HVAC", displayName: "Central HVAC", tier: .universal,
              displayPriority: 20, icon: "wind", defaultCadence: "Semi-annually"),
        .init(categoryKey: "Plumbing", displayName: "Plumbing", tier: .universal,
              displayPriority: 30, icon: "drop.fill", defaultCadence: nil),
        .init(categoryKey: "Electrical", displayName: "Electrical", tier: .universal,
              displayPriority: 40, icon: "bolt.fill", defaultCadence: nil),
        .init(categoryKey: "Water Heater", displayName: "Water Heater", tier: .universal,
              displayPriority: 50, icon: "flame.fill", defaultCadence: "Annually"),
        .init(categoryKey: "Pest Control", displayName: "Pest Control", tier: .universal,
              displayPriority: 60, icon: "ant", defaultCadence: "Quarterly"),
        .init(categoryKey: "Security System", displayName: "Security System", tier: .universal,
              displayPriority: 70, icon: "lock.shield", defaultCadence: "Annually"),
        .init(categoryKey: "Cleaning Service", displayName: "Cleaning Service", tier: .universal,
              displayPriority: 80, icon: "sparkles", defaultCadence: "Biweekly"),
        .init(categoryKey: "Handyman", displayName: "Handyman", tier: .universal,
              displayPriority: 85, icon: "hammer.fill", defaultCadence: "Semi-annually"),
        // Phase 54E.3: Trash & Recycling lives as a real category so
        // the hauler (Redding Sanitation, Waste Management, etc.) can
        // be saved as a contractor, linked from weekly cadences, and
        // assigned in the contractor directory's "Assign Systems" step.
        // No maintenance templates — this category is purely a
        // vendor-anchor, same pattern the Handyman category uses.
        .init(categoryKey: "Trash & Recycling", displayName: "Trash & Recycling", tier: .universal,
              displayPriority: 90, icon: "trash.fill", defaultCadence: "Weekly"),
    ]

    // MARK: - Tier 2: Conditional (depends on property type/location)

    static let conditional: [SystemCategoryMeta] = [
        .init(categoryKey: "Landscaping", displayName: "Landscaping", tier: .conditional,
              displayPriority: 10, icon: "leaf", defaultCadence: "Biweekly"),
        .init(categoryKey: "Snow Removal", displayName: "Snow Removal", tier: .conditional,
              displayPriority: 20, icon: "snowflake", defaultCadence: "Per event"),
        .init(categoryKey: "Gutter Cleaning", displayName: "Gutter Cleaning", tier: .conditional,
              displayPriority: 30, icon: "arrow.down.to.line", defaultCadence: "Semi-annually"),
        .init(categoryKey: "Chimney", displayName: "Chimney Service", tier: .conditional,
              displayPriority: 40, icon: "fireplace.fill", defaultCadence: "Annually"),
        .init(categoryKey: "Septic System", displayName: "Septic System", tier: .conditional,
              displayPriority: 50, icon: "arrow.down.to.line", defaultCadence: "Every 3 years"),
        .init(categoryKey: "Well System", displayName: "Well System", tier: .conditional,
              displayPriority: 60, icon: "drop.circle.fill", defaultCadence: "Annually"),
        .init(categoryKey: "Generator", displayName: "Backup Generator", tier: .conditional,
              displayPriority: 70, icon: "bolt.batteryblock.fill", defaultCadence: "Quarterly"),
        .init(categoryKey: "Tree Service", displayName: "Tree Service", tier: .conditional,
              displayPriority: 80, icon: "tree.fill", defaultCadence: "Annually"),
        .init(categoryKey: "Window Cleaning", displayName: "Window Cleaning", tier: .conditional,
              displayPriority: 90, icon: "window.vertical.open", defaultCadence: "Semi-annually"),
        .init(categoryKey: "Pet Waste", displayName: "Pet Waste Removal", tier: .conditional,
              displayPriority: 100, icon: "pawprint.fill", defaultCadence: "Weekly"),
        .init(categoryKey: "Mosquito & Tick", displayName: "Mosquito & Tick Spraying", tier: .conditional,
              displayPriority: 110, icon: "ladybug.fill", defaultCadence: "Every 3 weeks"),
        // Phase 57: Air Quality — the parent category for radon testing +
        // mitigation. Only auto-created for properties in the Northeast
        // regional pack (granite belt) via the quiz's missing-system
        // backfill; elsewhere it stays a user-added category via the
        // Browse Specialty sheet.
        .init(categoryKey: "Air Quality", displayName: "Air Quality", tier: .conditional,
              displayPriority: 140, icon: "wind", defaultCadence: "Every 2 years"),
    ]

    // MARK: - Tier 3: Specialty (user opt-in via Browse sheet)

    static let specialty: [SystemCategoryMeta] = [
        // Outdoor Amenities
        .init(categoryKey: "Pool/Spa", displayName: "Pool Service", tier: .specialty,
              displayPriority: 10, icon: "drop.triangle.fill", defaultCadence: "Weekly",
              specialtyGroup: "Outdoor Amenities"),
        .init(categoryKey: "Hot Tub", displayName: "Spa / Hot Tub", tier: .specialty,
              displayPriority: 15, icon: "bathtub.fill", defaultCadence: "Monthly",
              specialtyGroup: "Outdoor Amenities"),
        .init(categoryKey: "Deck/Outdoor", displayName: "Deck / Outdoor Maintenance", tier: .specialty,
              displayPriority: 20, icon: "square.split.bottomrightquarter.fill", defaultCadence: "Annually",
              specialtyGroup: "Outdoor Amenities"),
        .init(categoryKey: "Driveway Sealcoating", displayName: "Driveway Sealcoating", tier: .specialty,
              displayPriority: 25, icon: "road.lanes", defaultCadence: "Every 3 years",
              specialtyGroup: "Outdoor Amenities"),
        .init(categoryKey: "Pressure Washing", displayName: "Pressure Washing", tier: .specialty,
              displayPriority: 30, icon: "drop.degreesign.fill", defaultCadence: "Annually",
              specialtyGroup: "Outdoor Amenities"),

        // Smart Home & Energy
        .init(categoryKey: "Solar", displayName: "Solar Panels", tier: .specialty,
              displayPriority: 40, icon: "sun.max.fill", defaultCadence: "Annually",
              specialtyGroup: "Smart Home & Energy"),
        .init(categoryKey: "EV Charger", displayName: "EV Charger Maintenance", tier: .specialty,
              displayPriority: 45, icon: "ev.charger.fill", defaultCadence: "Annually",
              specialtyGroup: "Smart Home & Energy"),
        .init(categoryKey: "Smart Home", displayName: "Smart Home Network", tier: .specialty,
              displayPriority: 50, icon: "wifi.router.fill", defaultCadence: nil,
              specialtyGroup: "Smart Home & Energy"),

        // Water & Climate
        .init(categoryKey: "Water Treatment", displayName: "Water Softener / Filtration", tier: .specialty,
              displayPriority: 60, icon: "drop.halffull", defaultCadence: "Annually",
              specialtyGroup: "Water & Climate"),
        .init(categoryKey: "Boiler", displayName: "Boiler (Steam Heat)", tier: .specialty,
              displayPriority: 65, icon: "flame.fill", defaultCadence: "Annually",
              specialtyGroup: "Water & Climate"),
        .init(categoryKey: "Radiant Floor", displayName: "Radiant Floor Heating", tier: .specialty,
              displayPriority: 70, icon: "thermometer.medium", defaultCadence: "Annually",
              specialtyGroup: "Water & Climate"),

        // Exterior Services
        .init(categoryKey: "Painting", displayName: "Painting (Interior/Exterior)", tier: .specialty,
              displayPriority: 80, icon: "paintbrush.fill", defaultCadence: nil,
              specialtyGroup: "Exterior Services"),
        .init(categoryKey: "Siding/Exterior", displayName: "Siding / Exterior", tier: .specialty,
              displayPriority: 85, icon: "building.2.fill", defaultCadence: "Annually",
              specialtyGroup: "Exterior Services"),

        // Lifestyle Amenities
        .init(categoryKey: "Elevator", displayName: "Residential Elevator", tier: .specialty,
              displayPriority: 90, icon: "arrow.up.and.down.circle.fill", defaultCadence: "Annually",
              specialtyGroup: "Lifestyle Amenities"),
        .init(categoryKey: "Wine Cellar", displayName: "Wine Cellar", tier: .specialty,
              displayPriority: 95, icon: "wineglass.fill", defaultCadence: "Annually",
              specialtyGroup: "Lifestyle Amenities"),

        // Phase 54C: Attic & Foundation as an opt-in category for
        // value-preservation annual inspections (arborist, grading,
        // foundation walkaround). Not auto-seeded because the rows
        // users add show up in their schedule — let them pick.
        .init(categoryKey: "Attic & Foundation", displayName: "Attic & Foundation", tier: .specialty,
              displayPriority: 105, icon: "house.lodge.fill", defaultCadence: "Annually",
              specialtyGroup: "Exterior Services"),
    ]

    // MARK: - Sub-systems (hidden from Vendor Coverage)

    static let subSystems: [SystemCategoryMeta] = [
        .init(categoryKey: "Appliance", displayName: "Appliance", tier: .subSystem,
              displayPriority: 0, icon: "refrigerator.fill", showInVendorCoverage: false),
        .init(categoryKey: "Crawl Space", displayName: "Crawl Space", tier: .subSystem,
              displayPriority: 0, icon: "square.bottomhalf.filled", showInVendorCoverage: false),
        .init(categoryKey: "Garage Door", displayName: "Garage Door", tier: .subSystem,
              displayPriority: 0, icon: "door.garage.closed", showInVendorCoverage: false),
        .init(categoryKey: "Sump Pump", displayName: "Sump Pump", tier: .subSystem,
              displayPriority: 0, icon: "arrow.up.circle.fill", showInVendorCoverage: false),
        .init(categoryKey: "Irrigation", displayName: "Sprinkler / Irrigation", tier: .subSystem,
              displayPriority: 0, icon: "sprinkler.and.droplets.fill", showInVendorCoverage: false),
        .init(categoryKey: "Fire Protection", displayName: "Fire Protection", tier: .subSystem,
              displayPriority: 0, icon: "flame.circle.fill", showInVendorCoverage: false),
    ]

    // MARK: - Combined Registry

    /// All categories flattened. Keyed by `categoryKey` for O(1) lookup.
    static let all: [SystemCategoryMeta] = universal + conditional + specialty + subSystems

    static let byCategoryKey: [String: SystemCategoryMeta] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.categoryKey, $0) })
    }()

    // MARK: - Public API

    /// Returns the tier for a given category string, defaulting to `.specialty`
    /// for unrecognized categories (custom user-added systems).
    static func tier(for categoryKey: String) -> SystemTier {
        byCategoryKey[categoryKey]?.tier ?? .specialty
    }

    /// Phase 54A: Case-insensitive category metadata lookup. Used by the
    /// missing-system auto-create path at quiz completion so
    /// Handyman / Mosquito & Tick / Pet Waste / Chimney / Snow Removal
    /// rows pick up the registry's display name and icon without
    /// duplicating constants.
    static func metaForCategory(_ category: String) -> SystemCategoryMeta? {
        if let exact = byCategoryKey[category] { return exact }
        return all.first { $0.categoryKey.caseInsensitiveCompare(category) == .orderedSame }
    }

    /// Phase 60.6: Normalize a raw category string into the registry's
    /// canonical `categoryKey` form so vendor-coverage matching survives
    /// case drift, verbose labels, and legacy variants.
    ///
    /// Why: `contractors.category` is stamped from many sources —
    /// `HouseQuizAnswerMapper.householdContractorCategoryFor` (canonical),
    /// `UtilityContractorMirror.serviceCategoryByProviderType` (canonical),
    /// `VendorReviewForm.matchServiceToCategory` (close but not identical —
    /// uses "Painting/Exterior" / "General Handyman"), and manual free-text
    /// at creation time. `home_systems.category` is similarly user-authored
    /// for custom systems. An exact-string match at read time (the old
    /// `vendorCoverageItems` line 358 behavior) silently drops contractors
    /// whose stored category differs by a space, a suffix, or a case.
    ///
    /// The resolution order:
    /// 1. Trim + exact key match (fastest path — most quiz-written rows).
    /// 2. Case-insensitive key match.
    /// 3. Known-variant map (verbose labels, legacy forms, partial trades).
    /// 4. Prefix-match: take everything before the first " & ", " / ", or
    ///    comma and retry — "Plumbing & Heating" → "Plumbing".
    /// 5. Return the trimmed original so custom user categories pass through.
    ///
    /// Returns nil only when the input is nil/empty after trimming.
    static func canonical(category raw: String?) -> String? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }

        // 1. Exact match
        if byCategoryKey[raw] != nil { return raw }

        // 2. Case-insensitive match
        if let hit = all.first(where: { $0.categoryKey.caseInsensitiveCompare(raw) == .orderedSame }) {
            return hit.categoryKey
        }

        // 3. Known-variant map. Keys are lowercased; values are canonical
        //    registry keys. Covers: legacy form-strings from VendorReviewForm,
        //    common verbose free-text ("Plumbing & Heating"), abbreviated
        //    trades ("Security" → "Security System", "Well" → "Well System"),
        //    chimney alias ("Fire Protection" pre-Phase-60.6 → "Chimney"),
        //    and pool variants ("Pool" / "Pool Service" → "Pool/Spa").
        let lower = raw.lowercased()
        let variantMap: [String: String] = [
            // Legacy VendorReviewForm.matchServiceToCategory strings
            "painting/exterior":      "Painting",
            "general handyman":       "Handyman",
            // Phase 60.6 verbose / HNW free-text
            "plumbing & heating":     "Plumbing",
            "heating & plumbing":     "Plumbing",
            "plumbing and heating":   "Plumbing",
            "heating & cooling":      "HVAC",
            "heating and cooling":    "HVAC",
            "heating":                "HVAC",
            "cooling":                "HVAC",
            "ac":                     "HVAC",
            "air conditioning":       "HVAC",
            "hvac service":           "HVAC",
            "boiler service":         "HVAC",
            // Abbreviated trades (system category has a suffix we drop)
            "security":               "Security System",
            "well":                   "Well System",
            "septic":                 "Septic System",
            "pool":                   "Pool/Spa",
            "pool service":           "Pool/Spa",
            "spa":                    "Pool/Spa",
            // Chimney alias — chimney_sweep chip used to map to Fire
            // Protection (a sub-system with showInVendorCoverage=false).
            // Phase 60.6 remaps the chip to "Chimney"; this entry catches
            // already-saved rows on the old mapping.
            "fire protection":        "Chimney",
            "chimney sweep":          "Chimney",
            "chimney service":        "Chimney",
            // Trash & Recycling — common aliases
            "trash":                  "Trash & Recycling",
            "recycling":              "Trash & Recycling",
            "trash and recycling":    "Trash & Recycling",
            "waste":                  "Trash & Recycling",
            "waste removal":          "Trash & Recycling",
            // Pest/mosquito — common aliases
            "pest":                   "Pest Control",
            "extermination":          "Pest Control",
            "mosquito":               "Mosquito & Tick",
            "tick":                   "Mosquito & Tick",
            "mosquito and tick":      "Mosquito & Tick",
            // Generator — "Backup Generator" is the display name, "Generator"
            // is the registry key.
            "backup generator":       "Generator",
            "generator service":      "Generator",
            // Cleaning — common aliases
            "cleaning":               "Cleaning Service",
            "house cleaner":          "Cleaning Service",
            "housekeeping":           "Cleaning Service",
            "maid":                   "Cleaning Service",
            "maid service":           "Cleaning Service",
            // Landscaping aliases
            "lawn":                   "Landscaping",
            "lawn care":              "Landscaping",
            "lawn service":           "Landscaping",
            "landscaper":             "Landscaping",
            "hardscape":              "Landscaping",
            "masonry":                "Landscaping",
            // Tree service
            "arborist":               "Tree Service",
            "tree":                   "Tree Service",
            // Snow / winter
            "snow":                   "Snow Removal",
            "snow plow":              "Snow Removal",
            "snow plowing":           "Snow Removal",
            "plowing":                "Snow Removal",
            // Pet waste
            "pet waste removal":      "Pet Waste",
            "dog waste":              "Pet Waste",
            "dog poop":               "Pet Waste",
        ]
        if let mapped = variantMap[lower] {
            return mapped
        }

        // 4. Prefix split. "Plumbing & Heating" / "Plumbing / Heating" /
        //    "Plumbing, Heating" → try the lead segment.
        let splitters = [" & ", " / ", ", ", " and "]
        for splitter in splitters {
            if let range = lower.range(of: splitter) {
                let lead = String(lower[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let mapped = variantMap[lead] { return mapped }
                if let hit = all.first(where: { $0.categoryKey.caseInsensitiveCompare(lead) == .orderedSame }) {
                    return hit.categoryKey
                }
            }
        }

        // 5. Unknown — return trimmed original so custom user categories
        //    still work in downstream equality checks (a user-authored
        //    category will equal itself on both sides).
        return raw
    }

    /// Phase 60.6: canonical equality. Both sides normalized via
    /// `canonical(category:)` so "Plumbing" matches "plumbing", "Plumbing
    /// & Heating", and "PLUMBING" alike. Nil handling: two nils are not
    /// equal (a contractor with no category isn't a match for anything).
    static func categoriesMatch(_ a: String?, _ b: String?) -> Bool {
        guard let ca = canonical(category: a),
              let cb = canonical(category: b) else { return false }
        return ca == cb
    }

    /// Whether a system category should appear in the Vendor Coverage list.
    /// Sub-systems and child systems (parentSystemId != nil) are excluded.
    static func showInVendorCoverage(category: String, parentSystemId: UUID?) -> Bool {
        if parentSystemId != nil { return false }
        if let meta = byCategoryKey[category] {
            return meta.showInVendorCoverage
        }
        // Unknown/custom categories: exclude common sub-system names that
        // may have been created as top-level rows before sub-system support
        // existed (e.g. "Washer & Dryer" uploaded via an early invoice).
        // These don't warrant their own vendor coverage row — they live
        // under a parent system or don't need a dedicated pro at all.
        let hiddenCategoryNames: Set<String> = [
            "appliance", "appliances",
            "garage door", "sump pump", "irrigation",
            "fire protection", "crawl space",
            "washer", "dryer", "washer & dryer", "washer/dryer",
            "washer and dryer", "laundry"
        ]
        if hiddenCategoryNames.contains(category.lowercased()) { return false }
        return true
    }

    /// Categories for the Tier 1 backfill. Returns category keys that every
    /// property should have, regardless of quiz answers.
    static var universalCategoryKeys: [String] {
        universal.map(\.categoryKey)
    }

    /// Tier 3 categories grouped for the Browse Specialty Systems sheet.
    /// Returns groups sorted by display priority, excluding items the user
    /// already has on their property.
    static func specialtyGroups(excluding existingCategories: Set<String>) -> [(group: String, items: [SystemCategoryMeta])] {
        let available = specialty.filter { !existingCategories.contains($0.categoryKey) }
        let grouped = Dictionary(grouping: available) { $0.specialtyGroup ?? "Other" }
        let groupOrder = ["Outdoor Amenities", "Smart Home & Energy", "Water & Climate", "Exterior Services", "Lifestyle Amenities", "Other"]
        return groupOrder.compactMap { groupName in
            guard let items = grouped[groupName], !items.isEmpty else { return nil }
            return (group: groupName, items: items.sorted { $0.displayPriority < $1.displayPriority })
        }
    }

    /// Build the full vendor coverage list for a property. Merges:
    /// 1. Tier 1 systems that SHOULD exist (even if no DB row yet)
    /// 2. Existing systems from the DB that qualify for coverage
    /// Excludes sub-systems and child systems.
    static func vendorCoverageItems(
        existingSystems: [HomeSystemRow],
        contractors: [ContractorRow],
        vendorTasks: [MaintenanceTaskDBRow]
    ) -> (uncovered: [VendorCoverageItem], covered: [VendorCoverageItem]) {
        let contractorById = Dictionary(uniqueKeysWithValues: contractors.map { ($0.id, $0) })

        // Step 1: Build a map of category -> coverage info from existing systems
        var categoryCoverage: [String: VendorCoverageItem] = [:]

        // Related categories (contractor for one covers related systems).
        // Phase 60.6: keys and values here are canonical registry keys
        // (or intentional aliases like "Heating"/"Air Conditioning" for
        // legacy system rows whose category didn't canonicalize to "HVAC").
        let relatedCategories: [String: Set<String>] = [
            "Landscaping": ["Irrigation"],
            "HVAC": ["Water Heater", "Heating", "Air Conditioning"],
            "Plumbing": ["Water Heater"],
            "Electrical": ["Generator", "EV Charger"],
            "Roofing": ["Gutters", "Gutter Cleaning"],
        ]
        // Phase 60.6: canonicalize every contractor category before
        // matching so "Plumbing & Heating" / "plumbing" / nil-vs-set
        // variants all collapse to a single registry key. Contractors
        // with a nil category (never stamped at save time) are excluded
        // from category-based matching here; they can still cover a
        // system via `preferredContractorId` (path 1) or an explicit
        // task assignment (path 2) above.
        let canonicalContractorCategories: [UUID: String] = Dictionary(
            uniqueKeysWithValues: contractors.compactMap { c in
                guard let canonical = SystemCategoryRegistry.canonical(category: c.category) else { return nil }
                return (c.id, canonical)
            }
        )
        let directCategories = Set(canonicalContractorCategories.values)
        var expandedContractorCategories = directCategories
        for cat in directCategories {
            if let related = relatedCategories[cat] {
                expandedContractorCategories.formUnion(related)
            }
        }

        for system in existingSystems {
            // Skip child systems and sub-system tier
            guard system.parentSystemId == nil,
                  showInVendorCoverage(category: system.category, parentSystemId: system.parentSystemId)
            else { continue }

            let meta = byCategoryKey[system.category]
            let tier = meta?.tier ?? .specialty
            let priority = meta?.displayPriority ?? 999
            let icon = meta?.icon ?? "wrench.and.screwdriver"

            // Determine if covered
            let isCovered: Bool
            let vendorName: String?
            let vendorLogoURL: String?
            let vendorBrandColor: String?

            // Check preferred contractor on the system itself
            if let prefId = system.preferredContractorId, let contractor = contractorById[prefId] {
                isCovered = true
                vendorName = contractor.companyName
                vendorLogoURL = contractor.logoUrl
                vendorBrandColor = contractor.brandColor
            }
            // Check if any vendor task for this system has a linked contractor
            else if let task = vendorTasks.first(where: { $0.systemId == system.id && $0.assignedContractorId != nil }),
                    let cId = task.assignedContractorId,
                    let contractor = contractorById[cId] {
                isCovered = true
                vendorName = contractor.companyName
                vendorLogoURL = contractor.logoUrl
                vendorBrandColor = contractor.brandColor
            }
            // Check if household has a contractor whose category matches.
            // Phase 60.6: both the system category and the contractor
            // category are canonicalized before comparison. The system
            // side uses `canonical(category:)` so legacy verbose system
            // names ("Security" on an old row) collapse to the registry
            // key ("Security System"). The contractor side uses the
            // pre-canonicalized map built above. Expansion runs on the
            // canonical system key so Water Heater systems match a
            // Plumbing-category contractor via `relatedCategories`.
            else if
                let canonicalSystemCategory = SystemCategoryRegistry.canonical(category: system.category),
                expandedContractorCategories.contains(canonicalSystemCategory),
                let match = canonicalContractorCategories.first(where: { entry in
                    entry.value == canonicalSystemCategory
                        || (relatedCategories[entry.value]?.contains(canonicalSystemCategory) ?? false)
                }),
                let contractor = contractorById[match.key]
            {
                isCovered = true
                vendorName = contractor.companyName
                vendorLogoURL = contractor.logoUrl
                vendorBrandColor = contractor.brandColor
            }
            else {
                isCovered = false
                vendorName = nil
                vendorLogoURL = nil
                vendorBrandColor = nil
            }

            // Cadence
            let cadence: String?
            if let days = system.serviceIntervalDays, days > 0 {
                cadence = humanCadence(days: days)
            } else if let defaultCadence = meta?.defaultCadence {
                cadence = defaultCadence
            } else {
                cadence = nil
            }

            // Dedup by category (keep first encountered)
            if categoryCoverage[system.category] == nil {
                categoryCoverage[system.category] = VendorCoverageItem(
                    id: system.category,
                    systemName: system.name,
                    tier: tier,
                    displayPriority: priority,
                    icon: icon,
                    vendorName: vendorName,
                    vendorLogoURL: vendorLogoURL,
                    vendorBrandColor: vendorBrandColor,
                    cadence: cadence,
                    isCovered: isCovered,
                    systemId: system.id
                )
            }
        }

        // Step 2: Add Tier 1 gaps (categories that SHOULD exist but don't have a DB row).
        //
        // Build 90 fix: previously hardcoded `isCovered: false` for every
        // synthesized row. That caused the Groton-Plumbing bug — contractor
        // had `category = "Plumbing"` but no Plumbing home_system existed,
        // so the synthesized Plumbing gap always rendered uncovered. Fix:
        // reuse `expandedContractorCategories` + `canonicalContractorCategories`
        // (already built above) to detect a matching contractor and stamp
        // the row covered with their name/logo/brand color.
        let existingCategories = Set(existingSystems.map(\.category))
        for meta in universal {
            if !existingCategories.contains(meta.categoryKey) && categoryCoverage[meta.categoryKey] == nil {
                let (isCovered, vendorName, vendorLogoURL, vendorBrandColor) = Self.resolveSynthesizedCoverage(
                    categoryKey: meta.categoryKey,
                    canonicalContractorCategories: canonicalContractorCategories,
                    expandedContractorCategories: expandedContractorCategories,
                    relatedCategories: relatedCategories,
                    contractorById: contractorById
                )
                categoryCoverage[meta.categoryKey] = VendorCoverageItem(
                    id: meta.categoryKey,
                    systemName: meta.displayName,
                    tier: .universal,
                    displayPriority: meta.displayPriority,
                    icon: meta.icon,
                    vendorName: vendorName,
                    vendorLogoURL: vendorLogoURL,
                    vendorBrandColor: vendorBrandColor,
                    cadence: meta.defaultCadence,
                    isCovered: isCovered,
                    systemId: nil
                )
            }
        }

        // Step 2b: Add conditional Tier 2 gaps when trigger conditions are met
        let outdoorCategories: Set<String> = ["Landscaping", "Pool/Spa", "Pool", "Deck/Outdoor"]
        let hasOutdoorLiving = existingCategories.contains(where: { outdoorCategories.contains($0) })
        let hasPets = existingSystems.contains { $0.subtype?.contains("has_pets") == true }

        let conditionalBackfill: [(key: String, condition: Bool)] = [
            ("Pet Waste", hasPets),
            ("Mosquito & Tick", hasOutdoorLiving),
        ]
        for (catKey, condition) in conditionalBackfill {
            guard condition,
                  !existingCategories.contains(catKey),
                  categoryCoverage[catKey] == nil,
                  let meta = byCategoryKey[catKey]
            else { continue }
            categoryCoverage[catKey] = VendorCoverageItem(
                id: meta.categoryKey,
                systemName: meta.displayName,
                tier: meta.tier,
                displayPriority: meta.displayPriority,
                icon: meta.icon,
                vendorName: nil,
                vendorLogoURL: nil,
                vendorBrandColor: nil,
                cadence: meta.defaultCadence,
                isCovered: false,
                systemId: nil
            )
        }

        // Step 3: Split and sort
        let items = Array(categoryCoverage.values)
        let uncovered = items
            .filter { !$0.isCovered }
            .sorted { ($0.tier, $0.displayPriority) < ($1.tier, $1.displayPriority) }
        let covered = items
            .filter { $0.isCovered }
            .sorted { ($0.tier, $0.displayPriority) < ($1.tier, $1.displayPriority) }

        return (uncovered: uncovered, covered: covered)
    }

    // MARK: - Helpers

    private static func resolveSynthesizedCoverage(
        categoryKey: String,
        canonicalContractorCategories: [UUID: String],
        expandedContractorCategories: Set<String>,
        relatedCategories: [String: Set<String>],
        contractorById: [UUID: ContractorRow]
    ) -> (Bool, String?, String?, String?) {
        guard let canonicalCategory = SystemCategoryRegistry.canonical(category: categoryKey),
              expandedContractorCategories.contains(canonicalCategory),
              let match = canonicalContractorCategories.first(where: { entry in
                  entry.value == canonicalCategory
                      || (relatedCategories[entry.value]?.contains(canonicalCategory) ?? false)
              }),
              let contractor = contractorById[match.key] else {
            return (false, nil, nil, nil)
        }

        return (true, contractor.companyName, contractor.logoUrl, contractor.brandColor)
    }

    static func humanCadence(days: Int) -> String {
        switch days {
        case 1...6: return "Every \(days) days"
        case 7: return "Weekly"
        case 8...13: return "Every \(days) days"
        case 14: return "Biweekly"
        case 15...27: return "Every \(days) days"
        case 28...31: return "Monthly"
        case 32...85: return "Every \(Int(round(Double(days) / 30.0))) months"
        case 86...95: return "Quarterly"
        case 96...170: return "Every \(Int(round(Double(days) / 30.0))) months"
        case 171...195: return "Semi-annually"
        case 196...350: return "Every \(Int(round(Double(days) / 30.0))) months"
        case 351...380: return "Annually"
        case 381...730: return "Every \(Int(round(Double(days) / 365.0))) years"
        case 731...1100: return "Every 3 years"
        default: return "Every \(Int(round(Double(days) / 365.0))) years"
        }
    }
}

// MARK: - Coverage Item Model

/// Single row in the redesigned Vendor Coverage sheet.
struct VendorCoverageItem: Identifiable {
    let id: String
    let systemName: String
    let tier: SystemTier
    let displayPriority: Int
    let icon: String
    let vendorName: String?
    let vendorLogoURL: String?
    let vendorBrandColor: String?
    let cadence: String?
    let isCovered: Bool
    let systemId: UUID?  // nil for Tier 1 gaps that don't have a DB row yet
}
