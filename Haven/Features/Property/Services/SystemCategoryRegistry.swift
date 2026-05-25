import Foundation
import SwiftUI

// MARK: - Tier Model

/// Three-tier system classification for vendor coverage and property setup.
/// Tier 1 (universal) systems are auto-backfilled to every property.
/// Tier 2 (conditional) systems are quiz-driven based on property type/location.
/// Tier 3 (specialty) systems are user-discovered via the Browse sheet.
/// Sub-system tier hides items from Vendor Coverage (they live under parents).
///
/// NOTE: a subset of these categoryKeys is also exposed to vendors via the
/// public application form at getchez.com/vendor-apply.html. When you ADD or
/// RENAME a category here, also update:
///   1. website/admin-data/vendor-categories.json (form source of truth)
///   2. supabase/functions/submit-vendor-application/index.ts (VALID_CATEGORIES Set)
/// Otherwise vendors will be unable to submit, or worse, will submit values
/// that don't match an in-app system.
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
        // Phase 67E/F (admin feedback 05d688b7): Trash & Recycling kept
        // here as a vendor-anchor category (so haulers can be saved as
        // contractors with this category, linked from weekly routines,
        // and assigned in the contractor directory). No maintenance
        // templates anchor here. Existing legacy `home_systems` rows
        // for this category are archived by
        // `runServiceSystemArchiveOnceIfNeeded` (v2) — the registry
        // entry exists only for the contractor-side ergonomics.
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
        // Phase 67E/F (admin feedback ad88660b): renamed displayName
        // from "Pool Service" → "Pool". The actual recurring weekly
        // cleaning is a `pool_service` routine (RoutineKind.poolService),
        // not a system. The Pool/Spa SYSTEM holds physical pool tasks
        // (opening, closing, heater service, equipment inspection,
        // safety fence). Hot tub items live under the separate Hot Tub
        // category.
        .init(categoryKey: "Pool/Spa", displayName: "Pool", tier: .specialty,
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
        // Waterproofing covers basement, crawl space, and foundation
        // waterproofing work — vendors like American Dry market
        // themselves under this single trade. `showInVendorCoverage:
        // false` for v1 (Tom adds manually); surfacing as a coverage
        // gap gated on Crawl Space / Basement presence is a follow-up
        // phase. The companion `categoryRelations` entry
        // ("Waterproofing": ["Crawl Space"]) is what lets the
        // assignment sheet pre-select Crawl Space sub-system rows.
        .init(categoryKey: "Waterproofing", displayName: "Waterproofing", tier: .specialty,
              displayPriority: 100, icon: "drop.fill", defaultCadence: nil,
              showInVendorCoverage: false, specialtyGroup: "Exterior Services"),

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
    // MARK: - Related Categories

    /// Cross-category coverage: a contractor whose canonical category is the
    /// key implicitly covers home_systems whose category is in the value set.
    /// Used by both `vendorCoverageItems` (so a "Plumbing" contractor marks
    /// "Water Heater" systems covered) AND by `SystemAssignmentSheet`'s
    /// pre-selection (so adding a Plumbing vendor pre-checks the household's
    /// Water Heater rows).
    ///
    /// Keys + values are canonical registry keys, with two intentional
    /// aliases ("Heating"/"Air Conditioning") that catch legacy system rows
    /// whose category never canonicalized to "HVAC". Extending this map
    /// reshapes both vendor coverage and assignment pre-selection in one
    /// place — keep it tight.
    static let categoryRelations: [String: Set<String>] = [
        "Landscaping": ["Irrigation"],
        "HVAC": ["Water Heater", "Heating", "Air Conditioning"],
        "Plumbing": ["Water Heater"],
        "Electrical": ["Generator", "EV Charger"],
        "Roofing": ["Gutters", "Gutter Cleaning"],
        // Waterproofing contractors (American Dry et al.) service the
        // Crawl Space sub-system rows directly. Basement / Foundation
        // don't have dedicated home_systems categories yet — if they
        // do later, append here.
        "Waterproofing": ["Crawl Space"],
    ]

    /// May 2026 friend feedback Round 3: canonical category keys whose
    /// vendors don't bind to a specific physical `home_systems` row.
    /// A cleaning service cleans the whole house. A trash hauler picks
    /// up bins at the curb. A snow-plow vendor clears the driveway.
    /// Saving one of these contractors shouldn't pop the
    /// "Assign to Home Systems" sheet asking which systems they
    /// service — they don't.
    ///
    /// `vendorCoverageItems` already picks these up via the
    /// contractor's canonical `category` field (path 3 in the matcher),
    /// so skipping the per-system assignment is harmless. Vendors with
    /// system-anchored trades (Roofing, HVAC, Plumbing, Electrical,
    /// Generator, etc.) still see the sheet so the homeowner can
    /// pre-stamp `preferred_contractor_id` on the matching rows.
    static let serviceOnlyCategoryKeys: Set<String> = [
        "Cleaning Service",
        "Trash & Recycling",
        "Snow Removal",
        "Mosquito & Tick",
        "Pet Waste",
        "Handyman",
        "Tree Service",
        "Window Cleaning",
        "Pressure Washing",
        "Painting",
    ]

    /// The set of canonical category keys a contractor with the given
    /// canonical category implicitly covers — i.e. `{category} ∪
    /// categoryRelations[category]`. Returns `[category]` when the input
    /// isn't canonical or has no related entries.
    static func canonicalCoverageSet(for category: String?) -> Set<String> {
        guard let canonical = canonical(category: category) else { return [] }
        var set: Set<String> = [canonical]
        if let related = categoryRelations[canonical] {
            set.formUnion(related)
        }
        return set
    }

    /// Returns the specialty-picker registry key that fits the given
    /// (sub-)system category. Sub-systems like "Crawl Space" map to
    /// their parent vendor trade ("Waterproofing"); everything else
    /// passes through `canonical(category:)` unchanged. Used by
    /// propagation sites (FindLocalVendorSheet "Add my own", Vendor
    /// Coverage gap cards) so the downstream `VendorReviewForm`
    /// picker pre-selects a value the user can actually see.
    ///
    /// Distinct from `vendorCategoryFor(systemCategory:)`, which
    /// returns a descriptive vendor-TYPE label (e.g. "Plumber") for
    /// Google Places searches.
    static func pickerCategoryFor(systemCategory: String?) -> String? {
        guard let canonicalKey = canonical(category: systemCategory) else { return nil }
        let subSystemToPicker: [String: String] = [
            "Crawl Space": "Waterproofing",
            // Future mappings as new sub-systems get vendor trades:
            // "Gutters": "Roofing", "Sump Pump": "Plumbing", etc.
        ]
        return subSystemToPicker[canonicalKey] ?? canonicalKey
    }

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
            // Phase 67I: pool extra aliases (pool / pool service / spa
            // already mapped above; just fill in the gaps).
            "pool company":           "Pool/Spa",
            "pool maintenance":       "Pool/Spa",
            // Phase 67I: solar aliases.
            "solar service":          "Solar",
            "solar company":          "Solar",
            "solar panels":           "Solar",
            "solar pv":               "Solar",
            // Phase 67I: security aliases (security already mapped
            // above to "Security System"; just fill in the gaps).
            "security service":       "Security System",
            "alarm":                  "Security System",
            "alarm company":          "Security System",
            "alarm monitoring":       "Security System",
            // Waterproofing — service trade for vendors like American Dry,
            // Alpha Basement Waterproofing, Home Spark Construction.
            // Lands on the top-level "Waterproofing" registry key so
            // these contractors show up in the specialty picker and
            // the assignment sheet pre-selects their Crawl Space
            // sub-system rows via `categoryRelations`. "Basement" alone
            // maps here too — homeowners think "basement guy" but the
            // industry calls it waterproofing.
            "waterproofing":              "Waterproofing",
            "basement waterproofing":     "Waterproofing",
            "waterproofing & basement":   "Waterproofing",
            "waterproofing and basement": "Waterproofing",
            "basement systems":           "Waterproofing",
            "basement":                   "Waterproofing",
            "foundation waterproofing":   "Waterproofing",
            "foundation":                 "Waterproofing",
            "foundation repair":          "Waterproofing",
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

    /// Phase 67I.4: vendor-routing lookup. A system category answers
    /// "what kind of vendor services this?" — distinct from
    /// `canonical()` which preserves system identity. Example:
    /// `vendorCategoryFor("Water Heater")` → `"Plumber"` because a
    /// plumber services water heaters, but the Water Heater system
    /// row keeps its own identity in vendor coverage. Single source
    /// of truth lives at `website/admin-data/vendor-routing.json`,
    /// loaded by `RemoteConfig.shared.vendorRouting`. The same map
    /// drives admin's coverage audit (admin.js `SYSTEM_CATEGORY_TO_VENDOR`
    /// reads the identical file) so both consumers stay in lockstep.
    ///
    /// Returns nil for unmapped categories (caller falls back to
    /// direct category match against contractor.category). Lookup
    /// is case-insensitive on the canonical key.
    @MainActor
    static func vendorCategoryFor(systemCategory: String?) -> String? {
        guard let raw = systemCategory?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        let routing = RemoteConfig.shared.vendorRouting
        if let direct = routing[raw] { return direct }
        // Case-insensitive fallback so "water heater" matches the
        // canonical "Water Heater" key in the JSON.
        for (key, value) in routing where key.caseInsensitiveCompare(raw) == .orderedSame {
            return value
        }
        return nil
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
    ///
    /// May 2026 friend feedback Round 3: pass `activeChezVendorRequests`
    /// to suppress categories the homeowner has already delegated to
    /// Chez (find_vendor / find_handyman requests in status open or
    /// waiting_customer). The dashboard's Chez hero card already
    /// communicates state for those categories — duplicating them as
    /// uncovered gaps confuses the user.
    static func vendorCoverageItems(
        existingSystems: [HomeSystemRow],
        contractors: [ContractorRow],
        vendorTasks: [MaintenanceTaskDBRow],
        activeChezVendorRequests: [ChezRequestRow] = []
    ) -> (uncovered: [VendorCoverageItem], covered: [VendorCoverageItem]) {
        let contractorById = Dictionary(uniqueKeysWithValues: contractors.map { ($0.id, $0) })

        // Step 1: Build a map of category -> coverage info from existing systems
        var categoryCoverage: [String: VendorCoverageItem] = [:]

        // Shared with `SystemAssignmentSheet` pre-selection so both
        // surfaces agree on which categories a contractor implicitly
        // covers (e.g. a Plumbing vendor → Water Heater).
        let relatedCategories = SystemCategoryRegistry.categoryRelations
        // Phase X feedback: build a per-contractor SET of canonical
        // categories rather than a single value. The set unions:
        //   1. the contractor's primary `category` (canonicalized)
        //   2. every entry in `specialties[]` (canonicalized)
        //   3. every `relatedCategories` expansion of (1) + (2)
        // This is what makes a multi-trade vendor — an HVAC vendor who
        // also does Boiler + Plumbing — surface across all their trades
        // in Vendor Coverage instead of only their primary. Contractors
        // whose category AND specialties both canonicalize to nothing
        // are excluded (they can still cover via path 1 or 2 above).
        let canonicalContractorCategorySets: [UUID: Set<String>] = Dictionary(
            uniqueKeysWithValues: contractors.compactMap { c in
                var set: Set<String> = []
                if let canon = SystemCategoryRegistry.canonical(category: c.category) {
                    set.insert(canon)
                }
                for specialty in c.specialties ?? [] {
                    if let canon = SystemCategoryRegistry.canonical(category: specialty) {
                        set.insert(canon)
                    }
                }
                guard !set.isEmpty else { return nil }
                return (c.id, set)
            }
        )
        // Expand each contractor's set with `relatedCategories` so the
        // implicit cross-coverage (HVAC → Water Heater, Plumbing →
        // Water Heater, Waterproofing → Crawl Space, etc.) still
        // applies on top of the explicit category + specialties.
        let expandedContractorSets: [UUID: Set<String>] = canonicalContractorCategorySets.mapValues { directSet in
            var expanded = directSet
            for cat in directSet {
                if let related = relatedCategories[cat] {
                    expanded.formUnion(related)
                }
            }
            return expanded
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
            // Check if household has a contractor whose category OR any
            // specialty matches. Phase 60.6: both the system category and
            // the contractor categories are canonicalized before
            // comparison. The system side uses `canonical(category:)` so
            // legacy verbose system names ("Security" on an old row)
            // collapse to the registry key ("Security System"). The
            // contractor side uses the per-contractor set built above
            // (category + specialties + relatedCategories expansions).
            // Phase X feedback: this now picks up multi-trade vendors
            // who service multiple system categories — an HVAC company
            // that also does Boiler will surface as covering both.
            else if
                let canonicalSystemCategory = SystemCategoryRegistry.canonical(category: system.category),
                let match = expandedContractorSets.first(where: { _, set in
                    set.contains(canonicalSystemCategory)
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

            // Phase 67 (G2): the reconciler v2 explicitly flags systems
            // that had a vendor-required template fire with no matching
            // contractor. When that flag is true, treat the system as
            // uncovered regardless of what category-match logic above
            // would say — the column is the authoritative signal because
            // it was set at the moment the gap was identified. The
            // `createContractor` hook clears this flag back to false
            // when a contractor materializes in the matching category,
            // so the column stays current under normal flow.
            let needsCoverageColumn = system.needsVendorCoverage == true
            let finalIsCovered = isCovered && !needsCoverageColumn

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
                    vendorName: finalIsCovered ? vendorName : nil,
                    vendorLogoURL: finalIsCovered ? vendorLogoURL : nil,
                    vendorBrandColor: finalIsCovered ? vendorBrandColor : nil,
                    cadence: cadence,
                    isCovered: finalIsCovered,
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
        // reuse `expandedContractorSets` (already built above, includes
        // category + specialties + relatedCategories expansions) to
        // detect a matching contractor and stamp the row covered with
        // their name/logo/brand color.
        let existingCategories = Set(existingSystems.map(\.category))
        for meta in universal {
            if !existingCategories.contains(meta.categoryKey) && categoryCoverage[meta.categoryKey] == nil {
                let (isCovered, vendorName, vendorLogoURL, vendorBrandColor) = Self.resolveSynthesizedCoverage(
                    categoryKey: meta.categoryKey,
                    expandedContractorSets: expandedContractorSets,
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

        // May 2026 friend feedback Round 3: build the set of canonical
        // category keys with an active Chez request so we can hide them
        // from the uncovered list. The "Have Chez handle it" gap-card
        // entry point (VendorCoverageSheet) stamps the canonical
        // `system_category` into the request's context payload, so
        // matching on the canonicalized value lines up with the
        // VendorCoverageItem.id (also a canonical key).
        let chezHandledCategoryKeys: Set<String> = Set(
            activeChezVendorRequests.compactMap { req in
                guard let sysCat = req.context?["system_category"] else { return nil }
                return SystemCategoryRegistry.canonical(category: sysCat)
            }
        )

        // Step 3: Split and sort
        let items = Array(categoryCoverage.values)
        let uncovered = items
            .filter { !$0.isCovered }
            .filter { !chezHandledCategoryKeys.contains($0.id) }
            .sorted { ($0.tier, $0.displayPriority) < ($1.tier, $1.displayPriority) }
        let covered = items
            .filter { $0.isCovered }
            .sorted { ($0.tier, $0.displayPriority) < ($1.tier, $1.displayPriority) }

        return (uncovered: uncovered, covered: covered)
    }

    // MARK: - Helpers

    private static func resolveSynthesizedCoverage(
        categoryKey: String,
        expandedContractorSets: [UUID: Set<String>],
        contractorById: [UUID: ContractorRow]
    ) -> (Bool, String?, String?, String?) {
        // Phase X feedback: a contractor covers the synthesized gap if
        // the canonical category appears anywhere in their expanded
        // coverage set — the union of `category`, every `specialty`,
        // and any `relatedCategories` expansion. That's what makes
        // multi-trade vendors (HVAC + Boiler + Plumbing) cover all
        // their trades' synthesized gaps simultaneously.
        guard let canonicalCategory = SystemCategoryRegistry.canonical(category: categoryKey),
              let match = expandedContractorSets.first(where: { _, set in
                  set.contains(canonicalCategory)
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
