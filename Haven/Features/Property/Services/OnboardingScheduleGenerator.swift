import Foundation

// MARK: - Property Lookup Result

struct PropertyLookupResult: Codable {
    var yearBuilt: Int?
    var squareFootage: Int?
    var lotSize: Int?
    var bedrooms: Int?
    /// Phase 20 polish: ATTOM returns bathrooms as a Double (e.g. 3.5) to
    /// represent half-baths. The previous `Int?` type caused the entire
    /// JSON decode to fail with "Number 3.5 is not representable in Swift"
    /// for any home with a half-bath, which silently dropped ALL property
    /// data on a huge fraction of CT/NY HNW homes. Type widened to Double?
    /// to match the upstream ATTOM contract.
    var bathrooms: Double?
    var propertyType: String?
    let lastSaleDate: String?
    let lastSalePrice: Double?
    var estimatedValue: Double?
    let estimatedValueLow: Double?
    let estimatedValueHigh: Double?
    let estimatedValueConfidence: Int?  // 0-100 (ATTOM AVM scr; ai_comps=60-80; computed=40; estimated=25)
    /// Phase 16e + 18g: which fallback layer produced `estimatedValue`. One of
    /// "attom" | "rentcast" | "ai_comps" | "computed" | "estimated". The
    /// Investment Summary surfaces this so users see *why* a number is what
    /// it is.
    let estimatedValueSource: String?
    /// Phase 18g: When `estimatedValueSource == "ai_comps"`, this carries
    /// the short paragraph Claude returned explaining its methodology
    /// (comp count, range observed, key adjustments). Surfaced in iOS via
    /// a tappable info modal beneath the value. Optional with `try?`
    /// resilient decoding so older cached lookups (from before Phase 18g)
    /// still load cleanly.
    let estimatedValueReasoning: String?
    let features: PropertyFeatures?
    let taxAssessment: TaxAssessment?
    let ownerInfo: OwnerInfo?
    let dataSource: String?  // "attom" or "rentcast"

    enum CodingKeys: String, CodingKey {
        case yearBuilt, squareFootage, lotSize, bedrooms, bathrooms
        case propertyType, lastSaleDate, lastSalePrice
        case estimatedValue, estimatedValueLow, estimatedValueHigh
        case estimatedValueConfidence, estimatedValueSource, estimatedValueReasoning
        case features, taxAssessment, ownerInfo, dataSource
    }

    /// Phase 60.1: Resilient decoder. Every field wrapped in `try?` so a
    /// single unexpected field (new ATTOM field, numeric-as-string,
    /// unexpected null) only takes itself down — not the entire struct.
    /// Matches the in-codebase pattern on `PropertyRow`, `UtilityAccountRow`,
    /// `HouseholdAdvisorRow`, `VehicleRow`, and `ProjectAIResearch`. Before
    /// this fix, any type-mismatch threw from the synthesized decoder and
    /// silently dropped the whole lookup, taking the $660K sale price with
    /// it — the onboarding trust bug Tom reported in April 2026.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        yearBuilt = try? c.decodeIfPresent(Int.self, forKey: .yearBuilt)
        squareFootage = try? c.decodeIfPresent(Int.self, forKey: .squareFootage)
        lotSize = try? c.decodeIfPresent(Int.self, forKey: .lotSize)
        bedrooms = try? c.decodeIfPresent(Int.self, forKey: .bedrooms)
        bathrooms = try? c.decodeIfPresent(Double.self, forKey: .bathrooms)
        propertyType = try? c.decodeIfPresent(String.self, forKey: .propertyType)
        lastSaleDate = try? c.decodeIfPresent(String.self, forKey: .lastSaleDate)
        lastSalePrice = try? c.decodeIfPresent(Double.self, forKey: .lastSalePrice)
        estimatedValue = try? c.decodeIfPresent(Double.self, forKey: .estimatedValue)
        estimatedValueLow = try? c.decodeIfPresent(Double.self, forKey: .estimatedValueLow)
        estimatedValueHigh = try? c.decodeIfPresent(Double.self, forKey: .estimatedValueHigh)
        estimatedValueConfidence = try? c.decodeIfPresent(Int.self, forKey: .estimatedValueConfidence)
        estimatedValueSource = try? c.decodeIfPresent(String.self, forKey: .estimatedValueSource)
        estimatedValueReasoning = try? c.decodeIfPresent(String.self, forKey: .estimatedValueReasoning)
        features = try? c.decodeIfPresent(PropertyFeatures.self, forKey: .features)
        taxAssessment = try? c.decodeIfPresent(TaxAssessment.self, forKey: .taxAssessment)
        ownerInfo = try? c.decodeIfPresent(OwnerInfo.self, forKey: .ownerInfo)
        dataSource = try? c.decodeIfPresent(String.self, forKey: .dataSource)
    }

    // NOTE: do NOT add a custom encode(to:). The synthesized encoder is
    // correct and we rely on it for UserDefaults round-tripping in
    // AddressHookViewModel.cacheToUserDefaults().

    struct PropertyFeatures: Codable {
        let roofType: String?
        let heatingType: String?
        let heatingFuel: String?
        let coolingType: String?
        let foundationType: String?
        let exteriorType: String?
        let architectureType: String?
        let pool: Bool?
        let poolType: String?
        let garage: Bool?
        let garageType: String?
        let garageSpaces: Int?
        let stories: Int?
        let fireplace: Bool?
        let fireplaceType: String?
        let basementSize: Int?
        let constructionCondition: String?
        let qualityRating: String?

        enum CodingKeys: String, CodingKey {
            case roofType, heatingType, heatingFuel, coolingType
            case foundationType, exteriorType, architectureType
            case pool, poolType, garage, garageType, garageSpaces
            case stories, fireplace, fireplaceType, basementSize
            case constructionCondition, qualityRating
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            roofType = try? c.decodeIfPresent(String.self, forKey: .roofType)
            heatingType = try? c.decodeIfPresent(String.self, forKey: .heatingType)
            heatingFuel = try? c.decodeIfPresent(String.self, forKey: .heatingFuel)
            coolingType = try? c.decodeIfPresent(String.self, forKey: .coolingType)
            foundationType = try? c.decodeIfPresent(String.self, forKey: .foundationType)
            exteriorType = try? c.decodeIfPresent(String.self, forKey: .exteriorType)
            architectureType = try? c.decodeIfPresent(String.self, forKey: .architectureType)
            pool = try? c.decodeIfPresent(Bool.self, forKey: .pool)
            poolType = try? c.decodeIfPresent(String.self, forKey: .poolType)
            garage = try? c.decodeIfPresent(Bool.self, forKey: .garage)
            garageType = try? c.decodeIfPresent(String.self, forKey: .garageType)
            garageSpaces = try? c.decodeIfPresent(Int.self, forKey: .garageSpaces)
            stories = try? c.decodeIfPresent(Int.self, forKey: .stories)
            fireplace = try? c.decodeIfPresent(Bool.self, forKey: .fireplace)
            fireplaceType = try? c.decodeIfPresent(String.self, forKey: .fireplaceType)
            basementSize = try? c.decodeIfPresent(Int.self, forKey: .basementSize)
            constructionCondition = try? c.decodeIfPresent(String.self, forKey: .constructionCondition)
            qualityRating = try? c.decodeIfPresent(String.self, forKey: .qualityRating)
        }
    }

    struct TaxAssessment: Codable {
        let year: Int?
        let assessedValue: Double?
        let marketValue: Double?
        let taxAmount: Double?
        let taxPerSqFt: Double?
        // Backward compat with old cached RentCast data
        let value: Double?

        enum CodingKeys: String, CodingKey {
            case year, assessedValue, marketValue, taxAmount, taxPerSqFt, value
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            year = try? c.decodeIfPresent(Int.self, forKey: .year)
            assessedValue = try? c.decodeIfPresent(Double.self, forKey: .assessedValue)
            marketValue = try? c.decodeIfPresent(Double.self, forKey: .marketValue)
            taxAmount = try? c.decodeIfPresent(Double.self, forKey: .taxAmount)
            taxPerSqFt = try? c.decodeIfPresent(Double.self, forKey: .taxPerSqFt)
            value = try? c.decodeIfPresent(Double.self, forKey: .value)
        }
    }

    struct OwnerInfo: Codable {
        let ownerName: String?
        let absenteeOwner: Bool?
        let mailingAddress: String?

        enum CodingKeys: String, CodingKey {
            case ownerName, absenteeOwner, mailingAddress
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            ownerName = try? c.decodeIfPresent(String.self, forKey: .ownerName)
            absenteeOwner = try? c.decodeIfPresent(Bool.self, forKey: .absenteeOwner)
            mailingAddress = try? c.decodeIfPresent(String.self, forKey: .mailingAddress)
        }
    }
}

// MARK: - Schedule Preview Item

struct SchedulePreviewItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let month: Int // 1-12
    let frequency: String
    let estimatedCost: String
    let isDIY: Bool
    let icon: String // SF Symbol name

    static let categoryIcons: [String: String] = [
        "Roofing": "house.fill",
        "Siding/Exterior": "building.2.fill",
        "HVAC": "fan.fill",
        "Plumbing": "drop.fill",
        "Water Heater": "flame.fill",
        "Electrical": "bolt.fill",
        "Fire Protection": "flame.circle.fill",
        "Windows": "window.vertical.open",
        "Garage Door": "door.garage.closed",
        "Landscaping": "leaf.fill",
        "Pool/Spa": "figure.pool.swim",
        "Pest Control": "ant.fill",
        "Generator": "powerplug.fill",
        "Security System": "lock.shield.fill",
        "Solar": "sun.max.fill",
        "Appliance": "washer.fill",
        "Septic System": "arrow.down.to.line",
        "Well System": "drop.triangle.fill",
        "Irrigation": "sprinkler.and.droplets.fill",
        "Doors": "door.left.hand.closed",
        "Crawl Space": "rectangle.split.1x2.fill",
        "Water Treatment": "drop.degreesign.fill",
    ]
}

// MARK: - Climate Zone

enum ClimateZone: String {
    case northeast
    case southeast
    case midwest
    case southwest
    case pacificNW
    case mountain

    static func from(state: String) -> ClimateZone {
        let s = state.uppercased().trimmingCharacters(in: .whitespaces)
        switch s {
        case "ME", "NH", "VT", "MA", "RI", "CT", "NY", "NJ", "PA", "DE", "MD", "DC":
            return .northeast
        case "VA", "WV", "NC", "SC", "GA", "FL", "AL", "MS", "LA", "AR", "TN", "KY":
            return .southeast
        case "OH", "MI", "IN", "IL", "WI", "MN", "IA", "MO", "ND", "SD", "NE", "KS":
            return .midwest
        case "TX", "OK", "NM", "AZ", "NV":
            return .southwest
        case "WA", "OR":
            return .pacificNW
        case "CA", "HI":
            return .southwest // CA is mostly warm/dry
        case "MT", "ID", "WY", "CO", "UT", "AK":
            return .mountain
        default:
            return .northeast // safe default
        }
    }
}

// MARK: - Generator

enum OnboardingScheduleGenerator {

    /// Generate a 12-month maintenance preview from property lookup data.
    /// Works with nil input (uses sensible defaults for an "average" home).
    static func generate(from lookup: PropertyLookupResult?, state: String?) -> [SchedulePreviewItem] {
        let yearBuilt = lookup?.yearBuilt ?? 2000
        let propertyType = (lookup?.propertyType ?? "Single Family").lowercased()
        let climate = ClimateZone.from(state: state ?? "NY")
        let hasPool = lookup?.features?.pool ?? false
        let hasGarage = lookup?.features?.garage ?? false
        let hasFireplace = lookup?.features?.fireplace ?? false
        let foundationType = lookup?.features?.foundationType?.lowercased() ?? ""
        let hasCrawlSpace = foundationType.contains("crawl")
        let hasBasement = foundationType.contains("basement")

        let isCondo = propertyType.contains("condo") || propertyType.contains("apartment")
        let isTownhouse = propertyType.contains("townhouse") || propertyType.contains("town house")
        let currentYear = Calendar.current.component(.year, from: Date())
        let homeAge = currentYear - yearBuilt

        // Step 1: Collect essential universal templates (no subtype requirements)
        var candidates: [MaintenanceTemplate] = []

        let universalCategories = ["HVAC", "Plumbing", "Water Heater", "Electrical", "Fire Protection", "Appliance"]
        for cat in universalCategories {
            candidates.append(contentsOf: MaintenanceTemplates.essentialTemplates(for: cat))
        }

        // Step 2: Exterior tasks (skip for condos)
        if !isCondo {
            candidates.append(contentsOf: MaintenanceTemplates.essentialTemplates(for: "Roofing"))
            candidates.append(contentsOf: MaintenanceTemplates.essentialTemplates(for: "Siding/Exterior"))
            candidates.append(contentsOf: MaintenanceTemplates.essentialTemplates(for: "Landscaping"))
        }
        if !isCondo && !isTownhouse {
            candidates.append(contentsOf: MaintenanceTemplates.essentialTemplates(for: "Windows"))
        }

        // Step 3: Feature-based additions
        if hasPool {
            candidates.append(contentsOf: MaintenanceTemplates.essentialTemplates(for: "Pool/Spa"))
        }
        if hasGarage && !isCondo {
            candidates.append(contentsOf: MaintenanceTemplates.essentialTemplates(for: "Garage Door"))
        }
        if hasFireplace {
            // Chimney/fireplace already included in Fire Protection above
        }
        if hasCrawlSpace || hasBasement {
            candidates.append(contentsOf: MaintenanceTemplates.essentialTemplates(for: "Crawl Space"))
        }

        // Step 4: Age-based additions
        if homeAge > 25 {
            // Older homes need electrical panel inspection
            let electricalAll = MaintenanceTemplates.templates(for: "Electrical")
            for t in electricalAll where t.title.lowercased().contains("panel") || t.title.lowercased().contains("wiring") {
                if !candidates.contains(where: { $0.title == t.title }) {
                    candidates.append(t)
                }
            }
        }
        if homeAge > 20 {
            // Window seal checks
            let windowAll = MaintenanceTemplates.templates(for: "Windows")
            for t in windowAll where t.title.lowercased().contains("seal") || t.title.lowercased().contains("weather") {
                if !candidates.contains(where: { $0.title == t.title }) {
                    candidates.append(t)
                }
            }
        }

        // Step 5: Climate-based additions
        switch climate {
        case .northeast, .midwest, .mountain:
            // Winterization tasks
            let plumbingAll = MaintenanceTemplates.templates(for: "Plumbing")
            for t in plumbingAll where t.title.lowercased().contains("winter") || t.title.lowercased().contains("freeze") || t.title.lowercased().contains("insul") {
                if !candidates.contains(where: { $0.title == t.title }) {
                    candidates.append(t)
                }
            }
        case .southeast:
            // Humidity/mold checks — included in general exterior
            let pestAll = MaintenanceTemplates.essentialTemplates(for: "Pest Control")
            for t in pestAll where !candidates.contains(where: { $0.title == t.title }) {
                candidates.append(t)
            }
        case .southwest:
            // AC emphasis already covered by HVAC essentials
            break
        case .pacificNW:
            // Moss/moisture — covered by roofing and exterior
            break
        }

        // Step 6: Deduplicate by title
        var seen = Set<String>()
        candidates = candidates.filter { seen.insert($0.title).inserted }

        // Step 7: Sort by priority and cap at 15
        let priorityOrder = ["Urgent": 0, "High": 1, "Medium": 2, "Low": 3]
        candidates.sort { (priorityOrder[$0.priority] ?? 3) < (priorityOrder[$1.priority] ?? 3) }
        if candidates.count > 15 {
            candidates = Array(candidates.prefix(15))
        }

        // Step 8: Assign months based on seasonal timing
        let currentMonth = Calendar.current.component(.month, from: Date())
        var items: [SchedulePreviewItem] = []

        for (index, template) in candidates.enumerated() {
            let month = assignMonth(template: template, index: index, currentMonth: currentMonth, totalTasks: candidates.count)
            let icon = SchedulePreviewItem.categoryIcons[template.systemCategory] ?? "wrench.fill"

            items.append(SchedulePreviewItem(
                title: template.title,
                description: template.description,
                category: template.systemCategory,
                month: month,
                frequency: template.frequency,
                estimatedCost: template.estimatedCostRange,
                isDIY: template.isDIY,
                icon: icon
            ))
        }

        // Sort by month (starting from current month, wrapping around)
        items.sort { monthDistance($0.month, from: currentMonth) < monthDistance($1.month, from: currentMonth) }

        return items
    }

    // MARK: - Helpers

    private static func assignMonth(template: MaintenanceTemplate, index: Int, currentMonth: Int, totalTasks: Int) -> Int {
        // Use seasonal timing if available
        if let season = template.seasonalTiming?.lowercased() {
            if season.contains("spring") { return [3, 4, 5].randomElement()! }
            if season.contains("summer") { return [6, 7, 8].randomElement()! }
            if season.contains("fall") || season.contains("autumn") { return [9, 10, 11].randomElement()! }
            if season.contains("winter") { return [12, 1, 2].randomElement()! }
        }

        // For monthly/quarterly tasks, assign to next upcoming month
        let freq = template.frequency.lowercased()
        if freq.contains("monthly") || freq.contains("quarterly") {
            return currentMonth
        }

        // Distribute remaining tasks evenly across the year
        let spread = (index * 12) / max(totalTasks, 1)
        return ((currentMonth - 1 + spread) % 12) + 1
    }

    private static func monthDistance(_ month: Int, from currentMonth: Int) -> Int {
        let diff = month - currentMonth
        return diff >= 0 ? diff : diff + 12
    }

    // MARK: - Value Protection

    /// Estimate the dollar value preserved over 10 years by maintaining the home
    /// on schedule. Industry estimates from Remodeling Magazine + NAR studies put
    /// this at roughly 12% of current value vs. neglected homes.
    ///
    /// Falls back to projecting `lastSalePrice` forward at ~5% appreciation/year
    /// when `estimatedValue` is missing.
    static func computeValueProtection(from lookup: PropertyLookupResult?) -> Double? {
        guard let lookup else { return nil }

        if let value = lookup.estimatedValue, value > 0 {
            return value * 0.12
        }

        // Fallback: project last sale price forward at 5% appreciation/year.
        if let salePrice = lookup.lastSalePrice, salePrice > 0 {
            let yearsHeld = yearsSince(lookup.lastSaleDate) ?? 0
            let projected = salePrice * pow(1.05, Double(yearsHeld))
            return projected * 0.12
        }

        return nil
    }

    private static func yearsSince(_ dateString: String?) -> Int? {
        guard let dateString else { return nil }
        let formatter = DateFormatter()
        for format in ["yyyy-MM-dd", "MM/dd/yyyy", "yyyy"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let components = Calendar.current.dateComponents([.year], from: date, to: Date())
                return max(0, components.year ?? 0)
            }
        }
        return nil
    }
}
