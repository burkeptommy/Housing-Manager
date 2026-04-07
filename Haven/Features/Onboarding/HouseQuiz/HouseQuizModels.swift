import Foundation

// MARK: - HouseQuizState (persisted to properties.house_quiz_state JSONB)

/// Per-property quiz state stored as JSONB on the properties row.
/// Tracks every question in one of three buckets: answered, saved-for-later, skipped.
struct HouseQuizState: Codable, Equatable {
    var startedAt: Date?
    var completedAt: Date?
    var answers: [String: HouseQuizAnswer]
    var savedForLater: [String]
    var skipped: [String]

    enum CodingKeys: String, CodingKey {
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case answers
        case savedForLater = "saved_for_later"
        case skipped
    }

    init(
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        answers: [String: HouseQuizAnswer] = [:],
        savedForLater: [String] = [],
        skipped: [String] = []
    ) {
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.answers = answers
        self.savedForLater = savedForLater
        self.skipped = skipped
    }

    static let empty = HouseQuizState()
}

/// A single recorded answer. `answerId` is the option key the user picked;
/// `customText` is filled in when the user uses a free-form input or "Other";
/// `selectedIds` is filled in for multi-select questions; `customEntries` is
/// filled in when a multi-select question has an "Other" option that accepts
/// one or more user-supplied free-form values (e.g. q10 appliances).
struct HouseQuizAnswer: Codable, Equatable {
    var answerId: String?
    var customText: String?
    var selectedIds: [String]?
    var customEntries: [String]?
    var answeredAt: Date

    enum CodingKeys: String, CodingKey {
        case answerId = "answer_id"
        case customText = "custom_text"
        case selectedIds = "selected_ids"
        case customEntries = "custom_entries"
        case answeredAt = "answered_at"
    }

    init(
        answerId: String? = nil,
        customText: String? = nil,
        selectedIds: [String]? = nil,
        customEntries: [String]? = nil,
        answeredAt: Date = Date()
    ) {
        self.answerId = answerId
        self.customText = customText
        self.selectedIds = selectedIds
        self.customEntries = customEntries
        self.answeredAt = answeredAt
    }

    /// Resilient decoding so old persisted answers (no `custom_entries` key)
    /// still load cleanly after the schema bump.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.answerId = try c.decodeIfPresent(String.self, forKey: .answerId)
        self.customText = try c.decodeIfPresent(String.self, forKey: .customText)
        self.selectedIds = try c.decodeIfPresent([String].self, forKey: .selectedIds)
        self.customEntries = try c.decodeIfPresent([String].self, forKey: .customEntries)
        self.answeredAt = (try? c.decode(Date.self, forKey: .answeredAt)) ?? Date()
    }
}

// MARK: - Question Library

enum HouseQuizSection: String, Codable, CaseIterable, Identifiable {
    case homeBasics
    case inside
    case outside
    case energyServices
    case backupEnergy
    case vehicles
    case protectionPeople

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homeBasics: return "Your Home Basics"
        case .inside: return "Inside Your Home"
        case .outside: return "Outside & Landscaping"
        case .energyServices: return "Energy & Services"
        case .backupEnergy: return "Backup & Energy"
        case .vehicles: return "Vehicles & Garage"
        case .protectionPeople: return "Protection & People"
        }
    }
}

enum HouseQuizQuestionKind: String, Codable {
    case singleChoice
    case multiSelect
    case currency
    case yesNoLender
    case vehicleCount
    case vehicleAdd
    case providerSearch
    case caretakers
}

/// One question in the House Quiz library. The library lives in
/// `HouseQuizQuestionLibrary` for easy editing.
struct HouseQuizQuestion: Identifiable, Hashable {
    let id: String
    let section: HouseQuizSection
    let title: String
    let subtitle: String?
    let kind: HouseQuizQuestionKind
    let answerOptions: [AnswerOption]
    /// Whether the user can upload a document instead of answering.
    let documentUploadCategory: DocumentCategory?
    /// Whether this question expects a follow-up provider capture step
    /// when the user picks a "yes — pro service" answer.
    let providerFollowUpAnswerIds: Set<String>
    /// One or more utility provider_type tokens fed into the search picker.
    /// These must match the values in `utility_providers.provider_type`
    /// (e.g. "electric", "internet_cable", ["oil","propane","natural_gas"]).
    let providerTypes: [String]

    init(
        id: String,
        section: HouseQuizSection,
        title: String,
        subtitle: String? = nil,
        kind: HouseQuizQuestionKind,
        answerOptions: [AnswerOption] = [],
        documentUploadCategory: DocumentCategory? = nil,
        providerFollowUpAnswerIds: Set<String> = [],
        providerTypes: [String] = []
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.answerOptions = answerOptions
        self.documentUploadCategory = documentUploadCategory
        self.providerFollowUpAnswerIds = providerFollowUpAnswerIds
        self.providerTypes = providerTypes
    }

    /// Convenience for picker code that wants the canonical "primary" type
    /// for create/update writes (the first entry, falling back to nil).
    var primaryProviderType: String? { providerTypes.first }

    static func == (lhs: HouseQuizQuestion, rhs: HouseQuizQuestion) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AnswerOption: Identifiable, Hashable {
    let id: String
    let label: String
    let icon: String?
    /// When `true`, selecting this option in a multi-select question reveals
    /// an inline text field where the user can type one or more custom
    /// values (e.g. "Sauna", "Pellet stove" for the appliances question).
    let acceptsCustomInput: Bool

    init(id: String, label: String, icon: String? = nil, acceptsCustomInput: Bool = false) {
        self.id = id
        self.label = label
        self.icon = icon
        self.acceptsCustomInput = acceptsCustomInput
    }
}

// MARK: - AnswerFeedback (per-answer insight card)

struct AnswerFeedback: Hashable {
    let badge: String
    let title: String
    let subhead: String?
    let citationName: String

    /// Render the title with `{city}` / `{state}` substitutions populated.
    func renderedTitle(city: String?, state: String?) -> String {
        var output = title
        output = output.replacingOccurrences(of: "{city}", with: city ?? "your area")
        output = output.replacingOccurrences(of: "{state}", with: state ?? "your state")
        return output
    }

    func renderedSubhead(city: String?, state: String?) -> String? {
        guard var output = subhead else { return nil }
        output = output.replacingOccurrences(of: "{city}", with: city ?? "your area")
        output = output.replacingOccurrences(of: "{state}", with: state ?? "your state")
        return output
    }
}
