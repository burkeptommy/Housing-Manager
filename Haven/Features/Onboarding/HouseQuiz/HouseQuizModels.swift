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
///
/// Phase 16d: `kids` and `expectingEntries` are populated by q28_household
/// when the user picks "Family with kids" — each entry creates a family_member
/// row in HouseQuizAnswerMapper.
struct HouseQuizAnswer: Codable, Equatable {
    var answerId: String?
    var customText: String?
    var selectedIds: [String]?
    var customEntries: [String]?
    var kids: [QuizKidEntry]?
    var expectingEntries: [QuizExpectingEntry]?
    /// Phase 18e: When the user picks a provider from the search picker,
    /// stash the catalog row's UUID here so the answer mapper can fetch
    /// the full record (logo, brand color, slug, website, phone) at apply
    /// time and snapshot it onto the resulting utility_account row.
    var selectedProviderId: UUID?
    var answeredAt: Date

    enum CodingKeys: String, CodingKey {
        case answerId = "answer_id"
        case customText = "custom_text"
        case selectedIds = "selected_ids"
        case customEntries = "custom_entries"
        case kids
        case expectingEntries = "expecting_entries"
        case selectedProviderId = "selected_provider_id"
        case answeredAt = "answered_at"
    }

    init(
        answerId: String? = nil,
        customText: String? = nil,
        selectedIds: [String]? = nil,
        customEntries: [String]? = nil,
        kids: [QuizKidEntry]? = nil,
        expectingEntries: [QuizExpectingEntry]? = nil,
        selectedProviderId: UUID? = nil,
        answeredAt: Date = Date()
    ) {
        self.answerId = answerId
        self.customText = customText
        self.selectedIds = selectedIds
        self.customEntries = customEntries
        self.kids = kids
        self.expectingEntries = expectingEntries
        self.selectedProviderId = selectedProviderId
        self.answeredAt = answeredAt
    }

    /// Resilient decoding so old persisted answers (no `custom_entries`,
    /// `kids`, `expecting_entries`, or `selected_provider_id` keys) still
    /// load cleanly after the schema bump.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.answerId = try c.decodeIfPresent(String.self, forKey: .answerId)
        self.customText = try c.decodeIfPresent(String.self, forKey: .customText)
        self.selectedIds = try c.decodeIfPresent([String].self, forKey: .selectedIds)
        self.customEntries = try c.decodeIfPresent([String].self, forKey: .customEntries)
        self.kids = try? c.decodeIfPresent([QuizKidEntry].self, forKey: .kids)
        self.expectingEntries = try? c.decodeIfPresent([QuizExpectingEntry].self, forKey: .expectingEntries)
        self.selectedProviderId = try? c.decodeIfPresent(UUID.self, forKey: .selectedProviderId)
        self.answeredAt = (try? c.decode(Date.self, forKey: .answeredAt)) ?? Date()
    }
}

/// A single kid captured by Q28's "Family with kids" expansion. Persisted as
/// JSONB on the property's house_quiz_state row and replayed by
/// HouseQuizAnswerMapper to create the matching family_members row.
struct QuizKidEntry: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var firstName: String
    /// ISO date string (YYYY-MM-DD). Optional so users who only know the year
    /// can still record something useful (the form defaults the day to 1).
    var dateOfBirth: String?

    init(id: UUID = UUID(), firstName: String, dateOfBirth: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.dateOfBirth = dateOfBirth
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case dateOfBirth = "date_of_birth"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        self.firstName = (try? c.decode(String.self, forKey: .firstName)) ?? ""
        self.dateOfBirth = try? c.decodeIfPresent(String.self, forKey: .dateOfBirth)
    }

    /// Convenience for the answer mapper — true when DOB makes the kid under
    /// 18 today. Used to set `is_minor` on the family_member insert.
    var isMinorFromDOB: Bool {
        guard let dob = dateOfBirth, let date = Self.dateFormatter.date(from: dob) else {
            return true // assume minor when DOB is unknown — safer default
        }
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        return years < 18
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}

/// A single expecting baby captured by Q28's expansion. Mapped to a
/// `family_members` row with `is_expecting: true` and `expected_date` set.
struct QuizExpectingEntry: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    /// Optional placeholder name (e.g. "Baby Smith"). Falls back to "Baby" in
    /// the answer mapper when blank.
    var name: String?
    /// ISO date string (YYYY-MM-DD) for the due date.
    var dueDate: String

    init(id: UUID = UUID(), name: String? = nil, dueDate: String) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case dueDate = "due_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        self.name = try? c.decodeIfPresent(String.self, forKey: .name)
        self.dueDate = (try? c.decode(String.self, forKey: .dueDate)) ?? ""
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
    /// Phase 18b: When non-nil, the picker uses this closure (called at
    /// render time) to compute provider types from the current quiz state
    /// instead of the static `providerTypes` array. Used by Q19 (heating
    /// fuel provider) so the picker only shows providers matching the fuel
    /// type from Q3. Returning an empty array means "skip this question
    /// entirely" — the view model auto-skips when the closure resolves
    /// to empty so users with electric/geothermal homes never see a
    /// fuel provider question.
    let dynamicProviderTypes: ((HouseQuizState) -> [String])?

    init(
        id: String,
        section: HouseQuizSection,
        title: String,
        subtitle: String? = nil,
        kind: HouseQuizQuestionKind,
        answerOptions: [AnswerOption] = [],
        documentUploadCategory: DocumentCategory? = nil,
        providerFollowUpAnswerIds: Set<String> = [],
        providerTypes: [String] = [],
        dynamicProviderTypes: ((HouseQuizState) -> [String])? = nil
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
        self.dynamicProviderTypes = dynamicProviderTypes
    }

    /// Convenience for picker code that wants the canonical "primary" type
    /// for create/update writes (the first entry, falling back to nil).
    var primaryProviderType: String? { providerTypes.first }

    /// Phase 18b: Resolve the live provider types for this question against
    /// the current quiz state. Falls back to the static `providerTypes` when
    /// no dynamic closure is set so existing question definitions still work.
    func resolvedProviderTypes(state: HouseQuizState) -> [String] {
        if let closure = dynamicProviderTypes {
            return closure(state)
        }
        return providerTypes
    }

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
