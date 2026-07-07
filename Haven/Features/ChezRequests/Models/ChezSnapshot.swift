import Foundation

/// Wave 4 — Delegation composer v2 read models.
///
/// `preview_snapshot` is the chez-concierge action that returns everything
/// Chez already knows about an entity (task / routine / contractor / system /
/// project / vehicle / document / utility / insurance / property / group)
/// before the homeowner hands it off. The confirm sheet and the manual
/// composer render it as the "What Chez already knows" card so the
/// homeowner never re-types facts the app already has.
///
/// EVERY field decodes resiliently (`try? c.decodeIfPresent`) per the
/// CLAUDE.md house rule — the snapshot shape evolves server-side and one
/// new or reshaped field must only take itself down, never the preview.
///
/// Date-ish fields are decoded as `String` on purpose: the server sends a
/// mix of date-only (`2019-06-01`) and full ISO timestamps, and a typed
/// `Date` field would silently drop the date-only variants under the
/// ISO8601 strategy. Display formatting parses the string prefix instead.

// MARK: - Top-level preview envelope

struct ChezSnapshotPreview: Codable {
    let snapshot: ChezSnapshot?
    let readiness: ChezSnapshotReadiness?
    let suggestedBudget: ChezSuggestedBudget?

    enum CodingKeys: String, CodingKey {
        case snapshot, readiness
        case suggestedBudget = "suggested_budget"
    }

    init(
        snapshot: ChezSnapshot? = nil,
        readiness: ChezSnapshotReadiness? = nil,
        suggestedBudget: ChezSuggestedBudget? = nil
    ) {
        self.snapshot = snapshot
        self.readiness = readiness
        self.suggestedBudget = suggestedBudget
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        snapshot = (try? c.decodeIfPresent(ChezSnapshot.self, forKey: .snapshot)) ?? nil
        readiness = (try? c.decodeIfPresent(ChezSnapshotReadiness.self, forKey: .readiness)) ?? nil
        suggestedBudget = (try? c.decodeIfPresent(ChezSuggestedBudget.self, forKey: .suggestedBudget)) ?? nil
    }
}

// MARK: - Snapshot body

struct ChezSnapshot: Codable {
    let kind: String?
    let household: ChezSnapshotHousehold?
    let property: ChezSnapshotProperty?
    let task: ChezSnapshotTask?
    let system: ChezSnapshotSystem?
    let serviceHistory: [ChezSnapshotServiceRecord]?
    let routine: ChezSnapshotRoutine?
    let vendor: ChezSnapshotVendor?
    let vehicle: ChezSnapshotVehicle?
    let project: ChezSnapshotProject?
    let utility: ChezSnapshotUtility?
    let documents: [ChezSnapshotDocument]?
    let group: ChezSnapshotGroup?
    let costReference: ChezSnapshotCostReference?

    enum CodingKeys: String, CodingKey {
        case kind, household, property, task, system, routine, vendor
        case vehicle, project, utility, documents, group
        case serviceHistory = "service_history"
        case costReference = "cost_reference"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = (try? c.decodeIfPresent(String.self, forKey: .kind)) ?? nil
        household = (try? c.decodeIfPresent(ChezSnapshotHousehold.self, forKey: .household)) ?? nil
        property = (try? c.decodeIfPresent(ChezSnapshotProperty.self, forKey: .property)) ?? nil
        task = (try? c.decodeIfPresent(ChezSnapshotTask.self, forKey: .task)) ?? nil
        system = (try? c.decodeIfPresent(ChezSnapshotSystem.self, forKey: .system)) ?? nil
        serviceHistory = (try? c.decodeIfPresent([ChezSnapshotServiceRecord].self, forKey: .serviceHistory)) ?? nil
        routine = (try? c.decodeIfPresent(ChezSnapshotRoutine.self, forKey: .routine)) ?? nil
        vendor = (try? c.decodeIfPresent(ChezSnapshotVendor.self, forKey: .vendor)) ?? nil
        vehicle = (try? c.decodeIfPresent(ChezSnapshotVehicle.self, forKey: .vehicle)) ?? nil
        project = (try? c.decodeIfPresent(ChezSnapshotProject.self, forKey: .project)) ?? nil
        utility = (try? c.decodeIfPresent(ChezSnapshotUtility.self, forKey: .utility)) ?? nil
        documents = (try? c.decodeIfPresent([ChezSnapshotDocument].self, forKey: .documents)) ?? nil
        group = (try? c.decodeIfPresent(ChezSnapshotGroup.self, forKey: .group)) ?? nil
        costReference = (try? c.decodeIfPresent(ChezSnapshotCostReference.self, forKey: .costReference)) ?? nil
    }
}

// MARK: - Nested sections

struct ChezSnapshotHousehold: Codable {
    let name: String?
    let town: String?
    let state: String?
    /// Standing instructions — reuses the Phase 80.1 resilient model so
    /// the confirm sheet can prefill the access note + budget authority
    /// rows without a second profile fetch.
    let chezProfile: ChezProfile?

    enum CodingKeys: String, CodingKey {
        case name, town, state
        case chezProfile = "chez_profile"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? nil
        town = (try? c.decodeIfPresent(String.self, forKey: .town)) ?? nil
        state = (try? c.decodeIfPresent(String.self, forKey: .state)) ?? nil
        chezProfile = (try? c.decodeIfPresent(ChezProfile.self, forKey: .chezProfile)) ?? nil
    }
}

struct ChezSnapshotProperty: Codable {
    let street: String?
    let city: String?
    let state: String?
    let yearBuilt: Int?
    let squareFootage: Int?

    enum CodingKeys: String, CodingKey {
        case street, city, state
        case yearBuilt = "year_built"
        case squareFootage = "square_footage"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        street = (try? c.decodeIfPresent(String.self, forKey: .street)) ?? nil
        city = (try? c.decodeIfPresent(String.self, forKey: .city)) ?? nil
        state = (try? c.decodeIfPresent(String.self, forKey: .state)) ?? nil
        yearBuilt = (try? c.decodeIfPresent(Int.self, forKey: .yearBuilt)) ?? nil
        squareFootage = (try? c.decodeIfPresent(Int.self, forKey: .squareFootage)) ?? nil
    }
}

struct ChezSnapshotTask: Codable {
    let title: String?
    let status: String?
    let frequency: String?
    let nextDueDate: String?
    let scheduledDate: String?
    let assignmentType: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case title, status, frequency, notes
        case nextDueDate = "next_due_date"
        case scheduledDate = "scheduled_date"
        case assignmentType = "assignment_type"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? nil
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? nil
        frequency = (try? c.decodeIfPresent(String.self, forKey: .frequency)) ?? nil
        nextDueDate = (try? c.decodeIfPresent(String.self, forKey: .nextDueDate)) ?? nil
        scheduledDate = (try? c.decodeIfPresent(String.self, forKey: .scheduledDate)) ?? nil
        assignmentType = (try? c.decodeIfPresent(String.self, forKey: .assignmentType)) ?? nil
        notes = (try? c.decodeIfPresent(String.self, forKey: .notes)) ?? nil
    }
}

struct ChezSnapshotSystem: Codable {
    let name: String?
    let category: String?
    let manufacturer: String?
    let modelNumber: String?
    let serialNumber: String?
    let installDate: String?
    let status: String?
    let conditionRating: Int?
    let warranties: [ChezSnapshotWarranty]?
    let manualLinks: [String]?
    let subsystems: [ChezSnapshotSubsystem]?

    enum CodingKeys: String, CodingKey {
        case name, category, manufacturer, status, warranties, subsystems
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case conditionRating = "condition_rating"
        case manualLinks = "manual_links"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? nil
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? nil
        manufacturer = (try? c.decodeIfPresent(String.self, forKey: .manufacturer)) ?? nil
        modelNumber = (try? c.decodeIfPresent(String.self, forKey: .modelNumber)) ?? nil
        serialNumber = (try? c.decodeIfPresent(String.self, forKey: .serialNumber)) ?? nil
        installDate = (try? c.decodeIfPresent(String.self, forKey: .installDate)) ?? nil
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? nil
        conditionRating = (try? c.decodeIfPresent(Int.self, forKey: .conditionRating)) ?? nil
        warranties = (try? c.decodeIfPresent([ChezSnapshotWarranty].self, forKey: .warranties)) ?? nil
        manualLinks = (try? c.decodeIfPresent([String].self, forKey: .manualLinks)) ?? nil
        subsystems = (try? c.decodeIfPresent([ChezSnapshotSubsystem].self, forKey: .subsystems)) ?? nil
    }
}

struct ChezSnapshotWarranty: Codable {
    let provider: String?
    let endDate: String?
    let active: Bool?
    let expiresWithin90d: Bool?
    let claimPhone: String?

    enum CodingKeys: String, CodingKey {
        case provider, active
        case endDate = "end_date"
        case expiresWithin90d = "expires_within_90d"
        case claimPhone = "claim_phone"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        provider = (try? c.decodeIfPresent(String.self, forKey: .provider)) ?? nil
        endDate = (try? c.decodeIfPresent(String.self, forKey: .endDate)) ?? nil
        active = (try? c.decodeIfPresent(Bool.self, forKey: .active)) ?? nil
        expiresWithin90d = (try? c.decodeIfPresent(Bool.self, forKey: .expiresWithin90d)) ?? nil
        claimPhone = (try? c.decodeIfPresent(String.self, forKey: .claimPhone)) ?? nil
    }
}

struct ChezSnapshotSubsystem: Codable {
    let name: String?
    let category: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? nil
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? nil
    }

    enum CodingKeys: String, CodingKey { case name, category }
}

struct ChezSnapshotServiceRecord: Codable {
    let serviceDate: String?
    let serviceType: String?
    let description: String?
    let cost: Double?
    let contractorName: String?

    enum CodingKeys: String, CodingKey {
        case description, cost
        case serviceDate = "service_date"
        case serviceType = "service_type"
        case contractorName = "contractor_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        serviceDate = (try? c.decodeIfPresent(String.self, forKey: .serviceDate)) ?? nil
        serviceType = (try? c.decodeIfPresent(String.self, forKey: .serviceType)) ?? nil
        description = (try? c.decodeIfPresent(String.self, forKey: .description)) ?? nil
        cost = (try? c.decodeIfPresent(Double.self, forKey: .cost)) ?? nil
        contractorName = (try? c.decodeIfPresent(String.self, forKey: .contractorName)) ?? nil
    }
}

struct ChezSnapshotRoutine: Codable {
    let label: String?
    let cadenceType: String?
    let daysOfWeek: [Int]?
    let activeMonths: [Int]?
    let estimatedCostPerVisitCents: Int?
    let nextExpectedDate: String?

    enum CodingKeys: String, CodingKey {
        case label
        case cadenceType = "cadence_type"
        case daysOfWeek = "days_of_week"
        case activeMonths = "active_months"
        case estimatedCostPerVisitCents = "estimated_cost_per_visit_cents"
        case nextExpectedDate = "next_expected_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = (try? c.decodeIfPresent(String.self, forKey: .label)) ?? nil
        cadenceType = (try? c.decodeIfPresent(String.self, forKey: .cadenceType)) ?? nil
        daysOfWeek = (try? c.decodeIfPresent([Int].self, forKey: .daysOfWeek)) ?? nil
        activeMonths = (try? c.decodeIfPresent([Int].self, forKey: .activeMonths)) ?? nil
        estimatedCostPerVisitCents = (try? c.decodeIfPresent(Int.self, forKey: .estimatedCostPerVisitCents)) ?? nil
        nextExpectedDate = (try? c.decodeIfPresent(String.self, forKey: .nextExpectedDate)) ?? nil
    }
}

struct ChezSnapshotVendor: Codable {
    let companyName: String?
    let phone: String?
    let category: String?
    let history: [ChezSnapshotServiceRecord]?
    let stats: ChezSnapshotVendorStats?

    enum CodingKeys: String, CodingKey {
        case phone, category, history, stats
        case companyName = "company_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        companyName = (try? c.decodeIfPresent(String.self, forKey: .companyName)) ?? nil
        phone = (try? c.decodeIfPresent(String.self, forKey: .phone)) ?? nil
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? nil
        history = (try? c.decodeIfPresent([ChezSnapshotServiceRecord].self, forKey: .history)) ?? nil
        stats = (try? c.decodeIfPresent(ChezSnapshotVendorStats.self, forKey: .stats)) ?? nil
    }
}

struct ChezSnapshotVendorStats: Codable {
    let jobsOnFile: Int?
    let totalSpent: Double?
    let lastVisit: String?

    enum CodingKeys: String, CodingKey {
        case jobsOnFile = "jobs_on_file"
        case totalSpent = "total_spent"
        case lastVisit = "last_visit"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        jobsOnFile = (try? c.decodeIfPresent(Int.self, forKey: .jobsOnFile)) ?? nil
        totalSpent = (try? c.decodeIfPresent(Double.self, forKey: .totalSpent)) ?? nil
        lastVisit = (try? c.decodeIfPresent(String.self, forKey: .lastVisit)) ?? nil
    }
}

struct ChezSnapshotVehicle: Codable {
    let label: String?
    let year: Int?
    let make: String?
    let model: String?
    let trim: String?
    let mileage: Int?

    enum CodingKeys: String, CodingKey { case label, year, make, model, trim, mileage }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = (try? c.decodeIfPresent(String.self, forKey: .label)) ?? nil
        year = (try? c.decodeIfPresent(Int.self, forKey: .year)) ?? nil
        make = (try? c.decodeIfPresent(String.self, forKey: .make)) ?? nil
        model = (try? c.decodeIfPresent(String.self, forKey: .model)) ?? nil
        trim = (try? c.decodeIfPresent(String.self, forKey: .trim)) ?? nil
        mileage = (try? c.decodeIfPresent(Int.self, forKey: .mileage)) ?? nil
    }
}

struct ChezSnapshotProject: Codable {
    let name: String?
    let status: String?
    let quotes: [ChezSnapshotQuote]?

    enum CodingKeys: String, CodingKey { case name, status, quotes }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? nil
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? nil
        quotes = (try? c.decodeIfPresent([ChezSnapshotQuote].self, forKey: .quotes)) ?? nil
    }
}

struct ChezSnapshotQuote: Codable {
    let vendorName: String?
    let total: Double?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case total, status
        case vendorName = "vendor_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vendorName = (try? c.decodeIfPresent(String.self, forKey: .vendorName)) ?? nil
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? nil
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? nil
    }
}

struct ChezSnapshotUtility: Codable {
    let providerName: String?
    let providerType: String?
    let accountNumber: String?

    enum CodingKeys: String, CodingKey {
        case providerName = "provider_name"
        case providerType = "provider_type"
        case accountNumber = "account_number"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        providerName = (try? c.decodeIfPresent(String.self, forKey: .providerName)) ?? nil
        providerType = (try? c.decodeIfPresent(String.self, forKey: .providerType)) ?? nil
        accountNumber = (try? c.decodeIfPresent(String.self, forKey: .accountNumber)) ?? nil
    }
}

struct ChezSnapshotDocument: Codable {
    let filename: String?
    let category: String?

    enum CodingKeys: String, CodingKey { case filename, category }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        filename = (try? c.decodeIfPresent(String.self, forKey: .filename)) ?? nil
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? nil
    }
}

struct ChezSnapshotGroup: Codable {
    let group: String?
    let entities: [ChezSnapshotGroupEntity]?
    let totals: ChezSnapshotGroupTotals?

    enum CodingKeys: String, CodingKey { case group, entities, totals }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        group = (try? c.decodeIfPresent(String.self, forKey: .group)) ?? nil
        entities = (try? c.decodeIfPresent([ChezSnapshotGroupEntity].self, forKey: .entities)) ?? nil
        totals = (try? c.decodeIfPresent(ChezSnapshotGroupTotals.self, forKey: .totals)) ?? nil
    }
}

struct ChezSnapshotGroupEntity: Codable {
    let id: String?
    let label: String?

    enum CodingKeys: String, CodingKey { case id, label }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? nil
        label = (try? c.decodeIfPresent(String.self, forKey: .label)) ?? nil
    }
}

struct ChezSnapshotGroupTotals: Codable {
    let count: Int?
    let estMonthlySpendCents: Int?

    enum CodingKeys: String, CodingKey {
        case count
        case estMonthlySpendCents = "est_monthly_spend_cents"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        count = (try? c.decodeIfPresent(Int.self, forKey: .count)) ?? nil
        estMonthlySpendCents = (try? c.decodeIfPresent(Int.self, forKey: .estMonthlySpendCents)) ?? nil
    }
}

struct ChezSnapshotCostReference: Codable {
    let category: String?
    let medianCents: Int?
    let lowCents: Int?
    let highCents: Int?
    let sample: Int?

    enum CodingKeys: String, CodingKey {
        case category, sample
        case medianCents = "median_cents"
        case lowCents = "low_cents"
        case highCents = "high_cents"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? nil
        medianCents = (try? c.decodeIfPresent(Int.self, forKey: .medianCents)) ?? nil
        lowCents = (try? c.decodeIfPresent(Int.self, forKey: .lowCents)) ?? nil
        highCents = (try? c.decodeIfPresent(Int.self, forKey: .highCents)) ?? nil
        sample = (try? c.decodeIfPresent(Int.self, forKey: .sample)) ?? nil
    }
}

// MARK: - Readiness

struct ChezSnapshotReadiness: Codable {
    let score: Int?
    let missing: [ChezSnapshotReadinessGap]?

    enum CodingKeys: String, CodingKey { case score, missing }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        score = (try? c.decodeIfPresent(Int.self, forKey: .score)) ?? nil
        missing = (try? c.decodeIfPresent([ChezSnapshotReadinessGap].self, forKey: .missing)) ?? nil
    }
}

struct ChezSnapshotReadinessGap: Codable, Identifiable {
    let key: String?
    let label: String?

    var id: String { key ?? label ?? "gap" }

    enum CodingKeys: String, CodingKey { case key, label }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = (try? c.decodeIfPresent(String.self, forKey: .key)) ?? nil
        label = (try? c.decodeIfPresent(String.self, forKey: .label)) ?? nil
    }
}

// MARK: - Suggested budget

struct ChezSuggestedBudget: Codable {
    let lowCents: Int?
    let highCents: Int?
    /// "household_history" | "orientation_default" | "household_history_general"
    let basis: String?

    enum CodingKeys: String, CodingKey {
        case basis
        case lowCents = "low_cents"
        case highCents = "high_cents"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lowCents = (try? c.decodeIfPresent(Int.self, forKey: .lowCents)) ?? nil
        highCents = (try? c.decodeIfPresent(Int.self, forKey: .highCents)) ?? nil
        basis = (try? c.decodeIfPresent(String.self, forKey: .basis)) ?? nil
    }

    /// "Similar jobs have run $350 to $600." — household_history basis
    /// appends "in your home" per the Wave 4 contract copy.
    var captionText: String? {
        guard let lowCents, let highCents, highCents > 0 else { return nil }
        let low = ChezIntakeCurrency.wholeDollars(fromCents: lowCents)
        let high = ChezIntakeCurrency.wholeDollars(fromCents: highCents)
        if basis == "household_history" {
            return "Similar jobs have run \(low) to \(high) in your home."
        }
        return "Similar jobs have run \(low) to \(high)."
    }
}

// MARK: - Homeowner intake (write side)

/// The five budget bands the homeowner can pick from on any delegation.
/// Raw values match the server contract exactly.
enum ChezBudgetBand: String, CaseIterable, Identifiable {
    case under250 = "under_250"
    case band250to750 = "250_750"
    case band750to2000 = "750_2000"
    case band2000plus = "2000_plus"
    case optionsFirst = "options_first"

    var id: String { rawValue }

    /// Contract display copy — exact strings, no em dashes.
    var displayLabel: String {
        switch self {
        case .under250: return "Under $250"
        case .band250to750: return "$250 to $750"
        case .band750to2000: return "$750 to $2,000"
        case .band2000plus: return "$2,000 plus"
        case .optionsFirst: return "Show me options first"
        }
    }

    /// Band-derived cents bounds sent alongside the band per contract
    /// ("budget_low_cents ... optional, band-derived or custom").
    var derivedLowCents: Int? {
        switch self {
        case .under250: return nil
        case .band250to750: return 25_000
        case .band750to2000: return 75_000
        case .band2000plus: return 200_000
        case .optionsFirst: return nil
        }
    }

    var derivedHighCents: Int? {
        switch self {
        case .under250: return 25_000
        case .band250to750: return 75_000
        case .band750to2000: return 200_000
        case .band2000plus: return nil
        case .optionsFirst: return nil
        }
    }

    /// Maps a server suggestion to the band containing its midpoint so
    /// the picker can pre-select ("$350 to $600" lands on "$250 to $750").
    static func containing(suggested: ChezSuggestedBudget) -> ChezBudgetBand? {
        guard let low = suggested.lowCents, let high = suggested.highCents, high > 0 else { return nil }
        let midpoint = (low + high) / 2
        switch midpoint {
        case ..<25_000: return .under250
        case 25_000..<75_000: return .band250to750
        case 75_000..<200_000: return .band750to2000
        default: return .band2000plus
        }
    }
}

enum ChezUrgency: String, CaseIterable, Identifiable {
    case asap
    case thisWeek = "this_week"
    case twoWeeks = "two_weeks"
    case flexible

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .asap: return "As soon as possible"
        case .thisWeek: return "This week"
        case .twoWeeks: return "Within two weeks"
        case .flexible: return "Flexible"
        }
    }
}

enum ChezPreferredWindow: String, CaseIterable, Identifiable {
    case weekdayAM = "weekday_am"
    case weekdayPM = "weekday_pm"
    case weekend

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .weekdayAM: return "Weekday mornings"
        case .weekdayPM: return "Weekday afternoons"
        case .weekend: return "Weekends"
        }
    }
}

/// Wave 4 — the OPTIONAL `intake` object that rides every delegation
/// write (`submit`, `delegate_task`, `delegate_routine`,
/// `delegate_contractor`, `delegate_entity`, `set_ownership_group`).
/// Server stores it at `snapshot.homeowner_intake` and mirrors display
/// strings into the request `context` (`budget` + `timing`).
struct ChezDelegationIntake: Encodable {
    let budgetBand: String?
    let budgetLowCents: Int?
    let budgetHighCents: Int?
    let urgency: String?
    let preferredWindows: [String]?
    let accessNoteOverride: String?

    enum CodingKeys: String, CodingKey {
        case urgency
        case budgetBand = "budget_band"
        case budgetLowCents = "budget_low_cents"
        case budgetHighCents = "budget_high_cents"
        case preferredWindows = "preferred_windows"
        case accessNoteOverride = "access_note_override"
    }

    /// Builds an intake from the ChezIntakeForm's bindings. Returns nil
    /// when the homeowner touched nothing so callers can skip the field
    /// entirely (shipped clients + server treat missing intake as
    /// "no preferences stated").
    ///
    /// The access note only rides as an OVERRIDE: it's prefilled from
    /// `chez_profile.logistics.entry_instructions`, so an unedited value
    /// (or a cleared field) sends nothing and the standing instructions
    /// stay authoritative.
    static func make(
        budgetBand: ChezBudgetBand?,
        urgency: ChezUrgency?,
        preferredWindows: Set<ChezPreferredWindow>,
        accessNote: String,
        initialAccessNote: String
    ) -> ChezDelegationIntake? {
        let trimmedNote = accessNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInitial = initialAccessNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteOverride: String? = (!trimmedNote.isEmpty && trimmedNote != trimmedInitial) ? trimmedNote : nil

        let orderedWindows = ChezPreferredWindow.allCases
            .filter { preferredWindows.contains($0) }
            .map(\.rawValue)

        if budgetBand == nil && urgency == nil && orderedWindows.isEmpty && noteOverride == nil {
            return nil
        }
        return ChezDelegationIntake(
            budgetBand: budgetBand?.rawValue,
            budgetLowCents: budgetBand?.derivedLowCents,
            budgetHighCents: budgetBand?.derivedHighCents,
            urgency: urgency?.rawValue,
            preferredWindows: orderedWindows.isEmpty ? nil : orderedWindows,
            accessNoteOverride: noteOverride
        )
    }
}

// MARK: - Shared formatting

/// Whole-dollar currency formatting shared by the snapshot card, the
/// budget picker caption, and the group enumeration ("$1,450", "$850").
enum ChezIntakeCurrency {
    static func wholeDollars(fromCents cents: Int) -> String {
        wholeDollars(fromDollars: Double(cents) / 100.0)
    }

    static func wholeDollars(fromDollars dollars: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(Int(dollars.rounded()))"
    }
}
