import Foundation

// MARK: - HouseQuizState (persisted to properties.house_quiz_state JSONB)

/// Per-property quiz state stored as JSONB on the properties row.
/// Tracks every question in one of three buckets: answered, saved-for-later, skipped.
///
/// Phase 85 — split completion into two milestones:
///   - `intakeCompletedAt`: all 28 quiz questions resolved (the homeowner has
///     given Chez everything Chez needs to do a pre-visit briefing)
///   - `walkthroughCompletedAt`: per-system detail capture done — either by
///     the homeowner walking the property themselves, or by a handyman doing
///     it during a free home assessment visit (via the chez-concierge
///     ingestion pipeline). Cinematic reveal fires here, NOT at intake.
///
/// `completedAt` is preserved for backward compatibility — older rows that
/// pre-date the split read `completedAt` as a synonym for both new fields.
struct HouseQuizState: Codable, Equatable {
    var startedAt: Date?
    var completedAt: Date?
    /// Phase 85: flips when all intake questions are resolved.
    var intakeCompletedAt: Date?
    /// Phase 85: flips when the walk-through (self-serve or handyman-led)
    /// finishes. For self-serve, set when the user finishes their per-
    /// system capture pass. For handyman path, set by the chez-concierge
    /// ingestion pipeline after the homeowner approves the assessment.
    var walkthroughCompletedAt: Date?
    /// Phase 85: which path the homeowner chose at the path-decision screen.
    /// "self" = continue walking through systems themselves.
    /// "handyman" = scheduled a Chez handyman home assessment.
    /// nil = haven't reached the decision yet.
    var chosenPath: String?
    /// Phase 85: walk-through render mode.
    /// "self_serve" = iOS WalkthroughView.
    /// "handyman_assessment" = handyman captures via operations SPA.
    var walkthroughMode: String?
    var answers: [String: HouseQuizAnswer]
    var savedForLater: [String]
    var skipped: [String]
    /// Stamped the first time the forwarding-email reveal interstitial
    /// fires (after q15b_household_contractors). Nil on rows saved before
    /// the reveal moved off the legacy milestone system, so pre-existing
    /// mid-quiz users who are already past q15b simply never see it.
    var forwardingRevealShownAt: Date?

    enum CodingKeys: String, CodingKey {
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case intakeCompletedAt = "intake_completed_at"
        case walkthroughCompletedAt = "walkthrough_completed_at"
        case chosenPath = "chosen_path"
        case walkthroughMode = "walkthrough_mode"
        case answers
        case savedForLater = "saved_for_later"
        case skipped
        case forwardingRevealShownAt = "forwarding_reveal_shown_at"
    }

    init(
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        intakeCompletedAt: Date? = nil,
        walkthroughCompletedAt: Date? = nil,
        chosenPath: String? = nil,
        walkthroughMode: String? = nil,
        answers: [String: HouseQuizAnswer] = [:],
        savedForLater: [String] = [],
        skipped: [String] = [],
        forwardingRevealShownAt: Date? = nil
    ) {
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.intakeCompletedAt = intakeCompletedAt
        self.walkthroughCompletedAt = walkthroughCompletedAt
        self.chosenPath = chosenPath
        self.walkthroughMode = walkthroughMode
        self.answers = answers
        self.savedForLater = savedForLater
        self.skipped = skipped
        self.forwardingRevealShownAt = forwardingRevealShownAt
    }

    /// Resilient decoder per CLAUDE.md rule for externally-fed Codable types.
    /// Pre-Phase-85 rows (rows that pre-date the intake/walkthrough split)
    /// only have `completed_at` set. Treat that as a back-compat signal —
    /// if `intake_completed_at` is missing but `completed_at` is present,
    /// assume both intake and walkthrough completed when `completed_at`
    /// flipped (the old single-completion semantic).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.startedAt = try? c.decodeIfPresent(Date.self, forKey: .startedAt)
        self.completedAt = try? c.decodeIfPresent(Date.self, forKey: .completedAt)
        self.intakeCompletedAt = try? c.decodeIfPresent(Date.self, forKey: .intakeCompletedAt)
        self.walkthroughCompletedAt = try? c.decodeIfPresent(Date.self, forKey: .walkthroughCompletedAt)
        self.chosenPath = try? c.decodeIfPresent(String.self, forKey: .chosenPath)
        self.walkthroughMode = try? c.decodeIfPresent(String.self, forKey: .walkthroughMode)
        self.answers = (try? c.decodeIfPresent([String: HouseQuizAnswer].self, forKey: .answers)) ?? [:]
        self.savedForLater = (try? c.decodeIfPresent([String].self, forKey: .savedForLater)) ?? []
        self.skipped = (try? c.decodeIfPresent([String].self, forKey: .skipped)) ?? []
        self.forwardingRevealShownAt = try? c.decodeIfPresent(Date.self, forKey: .forwardingRevealShownAt)

        // Back-compat: pre-Phase-85 rows only have completedAt. If the new
        // intake/walkthrough fields are nil but completedAt is set, fill
        // both forward so the path-decision screen doesn't re-fire for
        // a homeowner who already finished the old single-pass quiz.
        if completedAt != nil && intakeCompletedAt == nil {
            self.intakeCompletedAt = completedAt
        }
        if completedAt != nil && walkthroughCompletedAt == nil {
            self.walkthroughCompletedAt = completedAt
        }
    }

    static let empty = HouseQuizState()
}

// MARK: - Phase 85 path/mode enums (string-typed via JSONB but exposed as
// strongly-typed convenience accessors for the view model + view layer)

enum HouseQuizPath: String, Codable {
    case selfServe = "self"
    case handyman = "handyman"
}

enum HouseQuizWalkthroughMode: String, Codable {
    case selfServe = "self_serve"
    case handymanAssessment = "handyman_assessment"
}

extension HouseQuizState {
    /// Strongly-typed access to `chosenPath`. Reads/writes the underlying
    /// String so the JSONB representation stays human-readable.
    var typedChosenPath: HouseQuizPath? {
        get { chosenPath.flatMap(HouseQuizPath.init(rawValue:)) }
        set { chosenPath = newValue?.rawValue }
    }

    var typedWalkthroughMode: HouseQuizWalkthroughMode? {
        get { walkthroughMode.flatMap(HouseQuizWalkthroughMode.init(rawValue:)) }
        set { walkthroughMode = newValue?.rawValue }
    }

    /// Phase 85 derived flags used throughout the view model + view.
    var isIntakeComplete: Bool { intakeCompletedAt != nil }
    var isWalkthroughComplete: Bool { walkthroughCompletedAt != nil }
    var hasChosenPath: Bool { chosenPath != nil }
    /// The path-decision screen renders when intake is complete but the
    /// homeowner hasn't picked a path yet AND the walkthrough hasn't
    /// already finished (defensive against weird state).
    var shouldShowPathDecision: Bool {
        isIntakeComplete && !hasChosenPath && !isWalkthroughComplete
    }
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
    /// Build 87 (Home Manager expansion): when the user adds a home manager
    /// from the Q28 caretakers sub-step, the captured invite metadata is
    /// stored here so the form can re-hydrate "ALREADY INVITED" state on
    /// resume / back-navigation. The actual `family_members` row + invite
    /// are created at form submit time via `HouseholdInviteCoordinator`,
    /// not at quiz answer apply time, so the answer mapper has nothing to
    /// do with this field.
    var homeManagerEntry: HomeManagerEntry?
    /// Phase 18e: When the user picks a provider from the search picker,
    /// stash the catalog row's UUID here so the answer mapper can fetch
    /// the full record (logo, brand color, slug, website, phone) at apply
    /// time and snapshot it onto the resulting utility_account row.
    var selectedProviderId: UUID?
    /// Phase 18c: Q20 (other fuel sources) inline propane provider picker.
    /// When the user selects any propane option AND their primary heating
    /// fuel from Q3 isn't propane, the picker captures the propane supplier
    /// and stashes its catalog UUID here. The mapper reads this at apply
    /// time to create a fresh propane utility_account row.
    var secondaryFuelProviderId: UUID?
    /// Phase 19i: Q22 generator fuel type. One of "natural_gas", "propane",
    /// "diesel". Nil when generator is "none" or fuel wasn't asked yet.
    var generatorFuelType: String?
    /// Phase 19i: Q22 generator provider catalog UUID, only set when the
    /// user explicitly picked a provider for the generator's fuel AND that
    /// fuel differs from the primary heating fuel from Q3 (i.e. they need
    /// a separate utility_account row from the one Q19 created).
    var generatorProviderId: UUID?
    /// Build 87: Q36 DIY vs Vendor slider value (1-10 inclusive). Nil for
    /// every other question kind. Persisted alongside the other answer
    /// fields in the `house_quiz_state` JSONB column.
    var sliderValue: Int?
    /// Phase 67D: structured payload for progressive-disclosure question
    /// kinds (`progressiveLawn`, `progressivePool`, `trashWithDays`,
    /// `garageWithEV`, `dualInsurance`) that capture multiple pieces of
    /// data on one screen without dedicated typed fields per piece. Keys
    /// are kind-specific:
    ///
    ///   progressiveLawn → ["lawnType": "natural"|"turf"|"mixed"|"not_sure"]
    ///   progressivePool → ["chemistry": "saltwater"|"chlorine"|"not_sure"]
    ///   garageWithEV    → ["evCharger": "yes"|"no"]
    ///   dualInsurance   → ["autoProviderId": "<UUID>", "homeProviderId": "<UUID>"]
    ///   caretakers (Q28 pets sub-step) → ["petsAnswerId": "dogs"|"cats"|...]
    ///
    /// Resilient `try?` decode tolerates entirely-missing payloads on legacy
    /// answers and unknown future keys. New keys can be added without a
    /// JSONB schema change because the column is already JSONB.
    var payload: [String: String]?
    var answeredAt: Date

    enum CodingKeys: String, CodingKey {
        case answerId = "answer_id"
        case customText = "custom_text"
        case selectedIds = "selected_ids"
        case customEntries = "custom_entries"
        case kids
        case expectingEntries = "expecting_entries"
        case homeManagerEntry = "home_manager_entry"
        case selectedProviderId = "selected_provider_id"
        case secondaryFuelProviderId = "secondary_fuel_provider_id"
        case generatorFuelType = "generator_fuel_type"
        case generatorProviderId = "generator_provider_id"
        case sliderValue = "slider_value"
        case payload
        case answeredAt = "answered_at"
    }

    init(
        answerId: String? = nil,
        customText: String? = nil,
        selectedIds: [String]? = nil,
        customEntries: [String]? = nil,
        kids: [QuizKidEntry]? = nil,
        expectingEntries: [QuizExpectingEntry]? = nil,
        homeManagerEntry: HomeManagerEntry? = nil,
        selectedProviderId: UUID? = nil,
        secondaryFuelProviderId: UUID? = nil,
        generatorFuelType: String? = nil,
        generatorProviderId: UUID? = nil,
        sliderValue: Int? = nil,
        payload: [String: String]? = nil,
        answeredAt: Date = Date()
    ) {
        self.answerId = answerId
        self.customText = customText
        self.selectedIds = selectedIds
        self.customEntries = customEntries
        self.kids = kids
        self.expectingEntries = expectingEntries
        self.homeManagerEntry = homeManagerEntry
        self.selectedProviderId = selectedProviderId
        self.secondaryFuelProviderId = secondaryFuelProviderId
        self.generatorFuelType = generatorFuelType
        self.generatorProviderId = generatorProviderId
        self.sliderValue = sliderValue
        self.payload = payload
        self.answeredAt = answeredAt
    }

    /// Resilient decoding so old persisted answers (no `custom_entries`,
    /// `kids`, `expecting_entries`, `home_manager_entry`,
    /// `selected_provider_id`, `secondary_fuel_provider_id`,
    /// `generator_fuel_type`, `generator_provider_id`, `slider_value`,
    /// or `payload` keys) still load cleanly after the schema bump.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.answerId = try c.decodeIfPresent(String.self, forKey: .answerId)
        self.customText = try c.decodeIfPresent(String.self, forKey: .customText)
        self.selectedIds = try c.decodeIfPresent([String].self, forKey: .selectedIds)
        self.customEntries = try c.decodeIfPresent([String].self, forKey: .customEntries)
        self.kids = try? c.decodeIfPresent([QuizKidEntry].self, forKey: .kids)
        self.expectingEntries = try? c.decodeIfPresent([QuizExpectingEntry].self, forKey: .expectingEntries)
        self.homeManagerEntry = try? c.decodeIfPresent(HomeManagerEntry.self, forKey: .homeManagerEntry)
        self.selectedProviderId = try? c.decodeIfPresent(UUID.self, forKey: .selectedProviderId)
        self.secondaryFuelProviderId = try? c.decodeIfPresent(UUID.self, forKey: .secondaryFuelProviderId)
        self.generatorFuelType = try? c.decodeIfPresent(String.self, forKey: .generatorFuelType)
        self.generatorProviderId = try? c.decodeIfPresent(UUID.self, forKey: .generatorProviderId)
        self.sliderValue = try? c.decodeIfPresent(Int.self, forKey: .sliderValue)
        self.payload = try? c.decodeIfPresent([String: String].self, forKey: .payload)
        self.answeredAt = (try? c.decode(Date.self, forKey: .answeredAt)) ?? Date()
    }
}

/// Build 87 (Home Manager expansion):
/// Home manager invite metadata captured by the Q28 caretakers sub-step.
/// Stored on `HouseQuizAnswer.homeManagerEntry` so the form can re-hydrate
/// "ALREADY INVITED" state when the user back-navigates to Q28 or resumes
/// the quiz. The actual `family_members` row + invite are created at form
/// submit time via `HouseholdInviteCoordinator.addPersonToHousehold`, not
/// at quiz answer apply time.
struct HomeManagerEntry: Codable, Equatable, Hashable {
    var firstName: String
    var lastName: String
    var email: String
    var sentInvite: Bool
    var inviteCode: String?

    init(
        firstName: String,
        lastName: String,
        email: String,
        sentInvite: Bool,
        inviteCode: String? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.sentInvite = sentInvite
        self.inviteCode = inviteCode
    }

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case sentInvite = "sent_invite"
        case inviteCode = "invite_code"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.firstName = (try? c.decode(String.self, forKey: .firstName)) ?? ""
        self.lastName = (try? c.decode(String.self, forKey: .lastName)) ?? ""
        self.email = (try? c.decode(String.self, forKey: .email)) ?? ""
        self.sentInvite = (try? c.decode(Bool.self, forKey: .sentInvite)) ?? false
        self.inviteCode = try? c.decodeIfPresent(String.self, forKey: .inviteCode)
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

// MARK: - Phase 60.3 Chapters

/// Phase 60.3: Three-chapter grouping over the 37 quiz questions. Drives
/// the chapter intro card, the chapter progress pill, and determines
/// where Q36 (preference tier) lands so it fires BEFORE Q11/Q13/Q14/Q15
/// vendor branches. The underlying `HouseQuizSection` enum stays —
/// chapters are a higher-order grouping that doesn't replace it.
enum HouseQuizChapter: String, Codable, CaseIterable, Identifiable {
    case yourHome   = "your_home"
    case yourPros   = "your_pros"
    case yourPeople = "your_people"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yourHome:   return "Your Home"
        case .yourPros:   return "Your Pros"
        case .yourPeople: return "Your People"
        }
    }

    var subtitle: String {
        switch self {
        case .yourHome:   return "The bones, the systems, the facts."
        case .yourPros:   return "Who helps you keep it running."
        case .yourPeople: return "The folks this home protects."
        }
    }

    var icon: String {
        switch self {
        case .yourHome:   return "house.fill"
        case .yourPros:   return "person.2.wave.2.fill"
        case .yourPeople: return "heart.circle.fill"
        }
    }

    var chapterNumber: Int {
        switch self {
        case .yourHome:   return 1
        case .yourPros:   return 2
        case .yourPeople: return 3
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
    /// Phase 19i: Q22 generator inline form. Captures generator type
    /// (whole-home / portable / none), fuel type (natural gas / propane /
    /// diesel), and an optional provider when the fuel differs from Q3's
    /// primary heating fuel.
    case generatorAdd
    /// Phase 19m: Q15b multi-select contractor chips with inline picker per
    /// chip. Lets the user add HVAC service, plumber, electrician, etc. in
    /// one screen. Each selected chip reveals a UtilityProviderSearchPicker
    /// scoped to that contractor type. Saved chips become contractor rows
    /// via the household-contractor mirror in the answer mapper.
    case householdContractors
    /// Build 87 legacy: was used for Q36 slider. Build 88 converted to
    /// `.singleChoice`. Kept for backward-compatible decoding of persisted
    /// quiz state from build 87 users — the view model treats it as
    /// `.singleChoice` at render time.
    case slider
    /// Phase 67D (A4): Q11 progressive disclosure — lawn handler chips
    /// always visible; lawn type chips revealed below when handler is not
    /// no_lawn / garden / hardscape. `answerId` carries the primary
    /// (handler) choice; `payload["lawnType"]` carries the secondary.
    case progressiveLawn
    /// Phase 67D (A5): Q12 progressive disclosure — pool/hot-tub kind chips
    /// always visible; chemistry chips revealed below when kind is
    /// in_ground / above_ground / both. Hot-tub-only and none paths skip
    /// the chemistry sub-step entirely. `answerId` is the kind;
    /// `payload["chemistry"]` is the saltwater/chlorine choice.
    case progressivePool
    /// Phase 67D (A7): Q18 trash service + pickup days on one screen.
    /// `answerId` is the service kind (municipal / private / not_sure);
    /// `selectedIds` is the multi-select day chips (sun…sat); `customText`
    /// is the optional private hauler name.
    case trashWithDays
    /// Phase 67D (A8): Q25 garage type + EV charger on one screen.
    /// `answerId` is the garage type (attached / semi_attached / detached
    /// / carport / none); `payload["evCharger"]` is yes/no, hidden when
    /// garage type is "none".
    case garageWithEV
    /// Phase 67D (A9): Q26+Q27 combined into one screen with two
    /// independently-skippable provider slots (auto + home).
    /// `payload["autoProviderId"]` and `payload["homeProviderId"]` carry
    /// the catalog UUIDs; either can be nil when the user skipped that
    /// slot. Free-form fallback names land in `customEntries` keyed by
    /// "auto:NAME" / "home:NAME".
    case dualInsurance
    /// Phase 67D (B2): Q4b purchase date. Renders a DatePicker (.date
    /// style) with optional Skip secondary button. `customText`
    /// carries the ISO date string ("yyyy-MM-dd") so resilient
    /// JSONB decoding doesn't fight a Date-typed field.
    case dateOnly
    /// Phase 67D (B3): Q9b recent renovations. Multi-select chips with
    /// inline year pickers per selected option. `selectedIds` carries
    /// the renovation type ids (roof_replaced, kitchen_renovated, …);
    /// `customEntries` carries "type:year" pipe-delimited entries
    /// (e.g. "roof_replaced:2019") so the mapper can push
    /// `last_replaced_date` to matching home_systems.
    case renovationsMultiSelect
}

/// One question in the House Quiz library. The library lives in
/// `HouseQuizQuestionLibrary` for easy editing.
struct HouseQuizQuestion: Identifiable, Hashable {
    let id: String
    let section: HouseQuizSection
    /// Phase 60.3: higher-order grouping used for chapter intro cards,
    /// chapter progress pill, and Q36 repositioning. Every question in
    /// the library must declare a chapter; Section 1/2 → yourHome,
    /// Q36 + Section 3/4 → yourPros, Section 5/6 → yourPeople.
    let chapter: HouseQuizChapter
    let title: String
    let subtitle: String?
    let kind: HouseQuizQuestionKind
    let answerOptions: [AnswerOption]
    /// Whether the user can upload a document instead of answering.
    let documentUploadCategory: DocumentCategory?
    /// Whether this question expects a follow-up provider capture step
    /// when the user picks a "yes. Pro service" answer.
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

    /// Phase 19j: Conditional skip closure. Called at advance time with the
    /// current quiz state. Returning `true` causes the view model to mark
    /// this question as skipped and move to the next one. Used by Q11b
    /// (lawn type) and Q14 (irrigation) to skip when prior answers make
    /// the question irrelevant — e.g. a user who said "no_lawn" in Q11
    /// shouldn't be asked about lawn type or sprinklers.
    let dynamicSkip: ((HouseQuizState) -> Bool)?

    /// Build 86: Opt-in flag for `multiSelect` questions that should expose a
    /// "Select all" / "Deselect all" pill above the option list. Currently
    /// only Q10 (appliances) uses this — Tom flagged that asking users to
    /// individually pick every appliance they own was friction when "all
    /// of them" is the common case. Other multi-select questions (Q20 fuels,
    /// Q15b contractors, etc.) intentionally keep the chip-by-chip flow.
    let supportsSelectAll: Bool

    /// Build 87: Per-question placeholder for the inline provider search
    /// picker shown by `providerCaptureInline` (Q11 lawn, Q12 pool, Q13
    /// pest, Q14 irrigation, Q15 security). Static string so callers don't
    /// need to compute it at render time. Nil means the picker uses its
    /// built-in default.
    let providerSearchPlaceholder: String?

    /// Build 87 legacy: slider fields. Kept for source compat with any code
    /// that references them during the transition. No longer set on new
    /// questions — Q36 is now `.singleChoice`.
    let sliderMin: Int
    let sliderMax: Int
    let sliderLeftLabel: String?
    let sliderRightLabel: String?

    /// Phase 60.4: Generic fallback title used when `title` contains
    /// personalization tokens (`{yearBuilt}`, `{street}`, etc.) and the
    /// token can't be resolved against the current property. Nil for
    /// questions that don't use tokens. The resolver NEVER ships literal
    /// braces to the UI.
    let fallbackTitle: String?

    /// Optional "why we ask" rationale. When non-nil, the question renders
    /// a small info-circle icon next to the title; tapping opens a sheet
    /// with this text. Populate for questions where the purpose isn't
    /// already obvious from the title or subtitle (e.g. Q4 purchase price,
    /// Q7 sewer source, Q36 vendor preference tier). Nil = no icon.
    let whyAsked: String?

    init(
        id: String,
        section: HouseQuizSection,
        chapter: HouseQuizChapter? = nil,
        title: String,
        fallbackTitle: String? = nil,
        subtitle: String? = nil,
        kind: HouseQuizQuestionKind,
        answerOptions: [AnswerOption] = [],
        documentUploadCategory: DocumentCategory? = nil,
        providerFollowUpAnswerIds: Set<String> = [],
        providerTypes: [String] = [],
        dynamicProviderTypes: ((HouseQuizState) -> [String])? = nil,
        dynamicSkip: ((HouseQuizState) -> Bool)? = nil,
        supportsSelectAll: Bool = false,
        providerSearchPlaceholder: String? = nil,
        sliderMin: Int = 1,
        sliderMax: Int = 10,
        sliderLeftLabel: String? = nil,
        sliderRightLabel: String? = nil,
        whyAsked: String? = nil
    ) {
        self.id = id
        self.section = section
        // Phase 60.3: derive chapter from section when not supplied so
        // existing call sites keep compiling. New call sites should pass
        // chapter explicitly.
        self.chapter = chapter ?? Self.defaultChapter(for: section)
        self.title = title
        self.fallbackTitle = fallbackTitle
        self.subtitle = subtitle
        self.kind = kind
        self.answerOptions = answerOptions
        self.documentUploadCategory = documentUploadCategory
        self.providerFollowUpAnswerIds = providerFollowUpAnswerIds
        self.providerTypes = providerTypes
        self.dynamicProviderTypes = dynamicProviderTypes
        self.dynamicSkip = dynamicSkip
        self.supportsSelectAll = supportsSelectAll
        self.providerSearchPlaceholder = providerSearchPlaceholder
        self.sliderMin = sliderMin
        self.sliderMax = sliderMax
        self.sliderLeftLabel = sliderLeftLabel
        self.sliderRightLabel = sliderRightLabel
        self.whyAsked = whyAsked
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

    /// Phase 60.3: Default chapter derivation used when an existing
    /// `HouseQuizQuestion` initializer didn't pass a chapter explicitly.
    /// The Phase 60.3 reorder moves Q36 into yourPros explicitly so
    /// the default here is never consulted for it.
    ///
    /// - homeBasics / inside → yourHome
    /// - outside / energyServices → yourPros
    /// - backupEnergy → yourHome (generator + solar are home systems)
    /// - vehicles / protectionPeople → yourPeople
    static func defaultChapter(for section: HouseQuizSection) -> HouseQuizChapter {
        switch section {
        case .homeBasics, .inside, .backupEnergy:
            return .yourHome
        case .outside, .energyServices:
            return .yourPros
        case .vehicles, .protectionPeople:
            return .yourPeople
        }
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
    /// Phase 60.2: made optional so entries without a cited study (e.g.
    /// the Q11 DIY feedback that no longer cheerleads with pricing
    /// claims) can omit the "Source:" line entirely.
    let citationName: String?

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
