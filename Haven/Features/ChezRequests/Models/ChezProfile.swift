import Foundation

/// Phase 80.1 — Standing instructions Chez reads on every request.
/// Stored as a JSONB blob on `households.chez_profile`. The shape is
/// intentionally flexible — every field is optional and the iOS side
/// treats anything missing as "not set yet" so partial fills work.
///
/// Mental model: this is the homeowner's "About us, for Chez" page.
/// The first time they hand off a request, Chez reads this and acts
/// like it already knows them.

struct ChezProfile: Codable, Equatable {
    var aboutUs: String?
    var communication: ChezCommunicationPrefs?
    var vendorPreferences: ChezVendorPrefs?
    var logistics: ChezLogistics?
    var spendingTiers: ChezSpendingTiers?
    var completion: ChezProfileCompletion?

    enum CodingKeys: String, CodingKey {
        case aboutUs = "about_us"
        case communication
        case vendorPreferences = "vendor_preferences"
        case logistics
        case spendingTiers = "spending_tiers"
        case completion = "_completion"
    }

    init(
        aboutUs: String? = nil,
        communication: ChezCommunicationPrefs? = nil,
        vendorPreferences: ChezVendorPrefs? = nil,
        logistics: ChezLogistics? = nil,
        spendingTiers: ChezSpendingTiers? = nil,
        completion: ChezProfileCompletion? = nil
    ) {
        self.aboutUs = aboutUs
        self.communication = communication
        self.vendorPreferences = vendorPreferences
        self.logistics = logistics
        self.spendingTiers = spendingTiers
        self.completion = completion
    }

    /// Resilient decoder per CLAUDE.md — every field optional via try?.
    /// Lets unknown new fields land cleanly without breaking the read path.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        aboutUs = (try? c.decodeIfPresent(String.self, forKey: .aboutUs)) ?? nil
        communication = (try? c.decodeIfPresent(ChezCommunicationPrefs.self, forKey: .communication)) ?? nil
        vendorPreferences = (try? c.decodeIfPresent(ChezVendorPrefs.self, forKey: .vendorPreferences)) ?? nil
        logistics = (try? c.decodeIfPresent(ChezLogistics.self, forKey: .logistics)) ?? nil
        spendingTiers = (try? c.decodeIfPresent(ChezSpendingTiers.self, forKey: .spendingTiers)) ?? nil
        completion = (try? c.decodeIfPresent(ChezProfileCompletion.self, forKey: .completion)) ?? nil
    }

    /// Whether the profile has any user-set content (i.e. has been filled
    /// at least partially). Drives the "Set up your Chez profile"
    /// nudge cards across the app.
    var isEmpty: Bool {
        let aboutEmpty = (aboutUs ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let commEmpty = communication == nil || communication?.isEmpty == true
        let vendorEmpty = vendorPreferences == nil || vendorPreferences?.isEmpty == true
        let logisticsEmpty = logistics == nil || logistics?.isEmpty == true
        let tiersEmpty = spendingTiers == nil
        return aboutEmpty && commEmpty && vendorEmpty && logisticsEmpty && tiersEmpty
    }

    /// Crude completeness score 0...1 used by the dashboard nudge to
    /// shrink as the user fills more sections.
    var completenessScore: Double {
        var score = 0.0
        let total = 5.0
        if !(aboutUs ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += 1 }
        if let c = communication, !c.isEmpty { score += 1 }
        if let v = vendorPreferences, !v.isEmpty { score += 1 }
        if let l = logistics, !l.isEmpty { score += 1 }
        if spendingTiers != nil { score += 1 }
        return score / total
    }
}

struct ChezCommunicationPrefs: Codable, Equatable {
    var preferredChannel: String?      // "email" | "sms" | "either"
    var noCallsBefore: String?          // "09:00"
    var noCallsAfter: String?           // "20:00"
    var vacationMode: Bool?
    var vacationNotes: String?

    enum CodingKeys: String, CodingKey {
        case preferredChannel = "preferred_channel"
        case noCallsBefore = "no_calls_before"
        case noCallsAfter = "no_calls_after"
        case vacationMode = "vacation_mode"
        case vacationNotes = "vacation_notes"
    }

    init(
        preferredChannel: String? = nil,
        noCallsBefore: String? = nil,
        noCallsAfter: String? = nil,
        vacationMode: Bool? = nil,
        vacationNotes: String? = nil
    ) {
        self.preferredChannel = preferredChannel
        self.noCallsBefore = noCallsBefore
        self.noCallsAfter = noCallsAfter
        self.vacationMode = vacationMode
        self.vacationNotes = vacationNotes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        preferredChannel = try? c.decodeIfPresent(String.self, forKey: .preferredChannel)
        noCallsBefore = try? c.decodeIfPresent(String.self, forKey: .noCallsBefore)
        noCallsAfter = try? c.decodeIfPresent(String.self, forKey: .noCallsAfter)
        vacationMode = try? c.decodeIfPresent(Bool.self, forKey: .vacationMode)
        vacationNotes = try? c.decodeIfPresent(String.self, forKey: .vacationNotes)
    }

    var isEmpty: Bool {
        preferredChannel == nil
            && noCallsBefore == nil
            && noCallsAfter == nil
            && vacationMode != true
            && (vacationNotes ?? "").isEmpty
    }
}

struct ChezVendorPrefs: Codable, Equatable {
    var budgetOrientation: String?      // "budget" | "standard" | "premium"
    var preferLocalOwned: Bool?
    var avoidChains: Bool?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case budgetOrientation = "budget_orientation"
        case preferLocalOwned = "prefer_local_owned"
        case avoidChains = "avoid_chains"
        case notes
    }

    init(
        budgetOrientation: String? = nil,
        preferLocalOwned: Bool? = nil,
        avoidChains: Bool? = nil,
        notes: String? = nil
    ) {
        self.budgetOrientation = budgetOrientation
        self.preferLocalOwned = preferLocalOwned
        self.avoidChains = avoidChains
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        budgetOrientation = try? c.decodeIfPresent(String.self, forKey: .budgetOrientation)
        preferLocalOwned = try? c.decodeIfPresent(Bool.self, forKey: .preferLocalOwned)
        avoidChains = try? c.decodeIfPresent(Bool.self, forKey: .avoidChains)
        notes = try? c.decodeIfPresent(String.self, forKey: .notes)
    }

    var isEmpty: Bool {
        budgetOrientation == nil
            && preferLocalOwned == nil
            && avoidChains == nil
            && (notes ?? "").isEmpty
    }
}

struct ChezLogistics: Codable, Equatable {
    var hasPets: Bool?
    var petNotes: String?
    var entryInstructions: String?
    var vendorAccessNotes: String?

    enum CodingKeys: String, CodingKey {
        case hasPets = "has_pets"
        case petNotes = "pet_notes"
        case entryInstructions = "entry_instructions"
        case vendorAccessNotes = "vendor_access_notes"
    }

    init(
        hasPets: Bool? = nil,
        petNotes: String? = nil,
        entryInstructions: String? = nil,
        vendorAccessNotes: String? = nil
    ) {
        self.hasPets = hasPets
        self.petNotes = petNotes
        self.entryInstructions = entryInstructions
        self.vendorAccessNotes = vendorAccessNotes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hasPets = try? c.decodeIfPresent(Bool.self, forKey: .hasPets)
        petNotes = try? c.decodeIfPresent(String.self, forKey: .petNotes)
        entryInstructions = try? c.decodeIfPresent(String.self, forKey: .entryInstructions)
        vendorAccessNotes = try? c.decodeIfPresent(String.self, forKey: .vendorAccessNotes)
    }

    var isEmpty: Bool {
        hasPets == nil
            && (petNotes ?? "").isEmpty
            && (entryInstructions ?? "").isEmpty
            && (vendorAccessNotes ?? "").isEmpty
    }
}

/// Spending tiers are stored as integer USD amounts (whole dollars).
/// These thresholds tell Chez what authority the homeowner has
/// granted: act independently below `autoApproveUnder`, ping for
/// approval between `autoApproveUnder` and `pingUnder`, require
/// explicit yes above `explicitAbove`. Default tuple is (200, 500, 500)
/// — applied client-side when the field is nil.
struct ChezSpendingTiers: Codable, Equatable {
    var autoApproveUnder: Int
    var pingUnder: Int
    var explicitAbove: Int
    var currency: String

    enum CodingKeys: String, CodingKey {
        case autoApproveUnder = "auto_approve_under"
        case pingUnder = "ping_under"
        case explicitAbove = "explicit_above"
        case currency
    }

    init(
        autoApproveUnder: Int = 200,
        pingUnder: Int = 500,
        explicitAbove: Int = 500,
        currency: String = "USD"
    ) {
        self.autoApproveUnder = autoApproveUnder
        self.pingUnder = pingUnder
        self.explicitAbove = explicitAbove
        self.currency = currency
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        autoApproveUnder = (try? c.decodeIfPresent(Int.self, forKey: .autoApproveUnder)) ?? 200
        pingUnder = (try? c.decodeIfPresent(Int.self, forKey: .pingUnder)) ?? 500
        explicitAbove = (try? c.decodeIfPresent(Int.self, forKey: .explicitAbove)) ?? 500
        currency = (try? c.decodeIfPresent(String.self, forKey: .currency)) ?? "USD"
    }

    static let `default` = ChezSpendingTiers()

    var autoApproveLabel: String {
        "Chez can act up to $\(autoApproveUnder) without checking with you."
    }

    var pingLabel: String {
        "Above $\(autoApproveUnder), Chez pings you before booking."
    }
}

struct ChezProfileCompletion: Codable, Equatable {
    var filledAt: String?
    var lastEditedAt: String?

    enum CodingKeys: String, CodingKey {
        case filledAt = "filled_at"
        case lastEditedAt = "last_edited_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        filledAt = try? c.decodeIfPresent(String.self, forKey: .filledAt)
        lastEditedAt = try? c.decodeIfPresent(String.self, forKey: .lastEditedAt)
    }
}
