import Foundation

// Phase 84.5 — `HomeAssessmentRow`, `HomeAssessmentStatus`, and
// `AssessmentMode` live in `Haven/Core/Networking/DatabaseModels.swift`
// (the canonical home for Codable types shared with PostgREST). This
// file holds feature-specific helpers (FoundationalAnswers,
// AssessmentRecommendedTaskRow + its enums) only.

// MARK: - AssessmentRecommendedTask

/// Phase 84.5 G19/G45/G46/G48 — handyman-captured recommendation row.
/// Fans out to chez_requests / property_projects / maintenance_tasks
/// at submit_assessment_data ingestion time.
enum AssessmentTaskUrgency: String, Codable {
    case urgent
    case soon
    case nextSeason = "next_season"
    case opportunistic
}

enum AssessmentTaskOwner: String, Codable {
    case homeownerDIY = "homeowner_diy"
    case chezHandyman = "chez_handyman"
    case chezVendor = "chez_vendor"
}

enum AssessmentTaskObservationSource: String, Codable {
    case handymanObserved = "handyman_observed"
    case homeownerReported = "homeowner_reported"
    case both
}

enum AssessmentTaskHomeownerResponse: String, Codable {
    case approved
    case declined
    case deferred
    case homeownerHandled = "homeowner_handled"
}

struct AssessmentRecommendedTaskRow: Identifiable, Decodable {
    let id: UUID
    let assessmentId: UUID
    let systemId: UUID?
    let zone: String?
    let title: String
    let description: String?
    let category: String?
    let urgency: AssessmentTaskUrgency
    let recommendedOwner: AssessmentTaskOwner
    let recommendedTemplateKey: String?
    let observationSource: AssessmentTaskObservationSource
    let needsVerification: Bool
    let estimatedCostCents: Int?
    let handymanNotes: String?
    let homeownerVisibleNotes: String?
    let photos: [String]?
    let homeownerResponse: AssessmentTaskHomeownerResponse?
    let homeownerHandledScheduledFor: String?
    let homeownerHandledVendor: String?
    let disputed: Bool
    let fixedDuringVisit: Bool
    let spawnedChezRequestId: UUID?
    let spawnedProjectId: UUID?
    let spawnedServiceRecordId: UUID?
    let spawnedMaintenanceTaskId: UUID?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, zone, title, description, category, urgency, photos, disputed
        case assessmentId = "assessment_id"
        case systemId = "system_id"
        case recommendedOwner = "recommended_owner"
        case recommendedTemplateKey = "recommended_template_key"
        case observationSource = "observation_source"
        case needsVerification = "needs_verification"
        case estimatedCostCents = "estimated_cost_cents"
        case handymanNotes = "handyman_notes"
        case homeownerVisibleNotes = "homeowner_visible_notes"
        case homeownerResponse = "homeowner_response"
        case homeownerHandledScheduledFor = "homeowner_handled_scheduled_for"
        case homeownerHandledVendor = "homeowner_handled_vendor"
        case fixedDuringVisit = "fixed_during_visit"
        case spawnedChezRequestId = "spawned_chez_request_id"
        case spawnedProjectId = "spawned_project_id"
        case spawnedServiceRecordId = "spawned_service_record_id"
        case spawnedMaintenanceTaskId = "spawned_maintenance_task_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        assessmentId = try c.decode(UUID.self, forKey: .assessmentId)
        title = try c.decode(String.self, forKey: .title)
        urgency = (try? c.decode(AssessmentTaskUrgency.self, forKey: .urgency)) ?? .soon
        recommendedOwner = (try? c.decode(AssessmentTaskOwner.self, forKey: .recommendedOwner)) ?? .chezVendor
        observationSource = (try? c.decode(AssessmentTaskObservationSource.self, forKey: .observationSource)) ?? .handymanObserved
        systemId = try? c.decodeIfPresent(UUID.self, forKey: .systemId)
        zone = try? c.decodeIfPresent(String.self, forKey: .zone)
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        category = try? c.decodeIfPresent(String.self, forKey: .category)
        recommendedTemplateKey = try? c.decodeIfPresent(String.self, forKey: .recommendedTemplateKey)
        needsVerification = (try? c.decodeIfPresent(Bool.self, forKey: .needsVerification)) ?? false
        estimatedCostCents = try? c.decodeIfPresent(Int.self, forKey: .estimatedCostCents)
        handymanNotes = try? c.decodeIfPresent(String.self, forKey: .handymanNotes)
        homeownerVisibleNotes = try? c.decodeIfPresent(String.self, forKey: .homeownerVisibleNotes)
        photos = try? c.decodeIfPresent([String].self, forKey: .photos)
        homeownerResponse = try? c.decodeIfPresent(AssessmentTaskHomeownerResponse.self, forKey: .homeownerResponse)
        homeownerHandledScheduledFor = try? c.decodeIfPresent(String.self, forKey: .homeownerHandledScheduledFor)
        homeownerHandledVendor = try? c.decodeIfPresent(String.self, forKey: .homeownerHandledVendor)
        disputed = (try? c.decodeIfPresent(Bool.self, forKey: .disputed)) ?? false
        fixedDuringVisit = (try? c.decodeIfPresent(Bool.self, forKey: .fixedDuringVisit)) ?? false
        spawnedChezRequestId = try? c.decodeIfPresent(UUID.self, forKey: .spawnedChezRequestId)
        spawnedProjectId = try? c.decodeIfPresent(UUID.self, forKey: .spawnedProjectId)
        spawnedServiceRecordId = try? c.decodeIfPresent(UUID.self, forKey: .spawnedServiceRecordId)
        spawnedMaintenanceTaskId = try? c.decodeIfPresent(UUID.self, forKey: .spawnedMaintenanceTaskId)
        createdAt = try? c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try? c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    /// Display label for urgency tier (homeowner-facing).
    var urgencyLabel: String {
        switch urgency {
        case .urgent: return "Urgent"
        case .soon: return "Soon"
        case .nextSeason: return "Next season"
        case .opportunistic: return "When you're ready"
        }
    }

    /// Display formatted cost.
    var costLabel: String? {
        guard let cents = estimatedCostCents, cents > 0 else { return nil }
        let dollars = Double(cents) / 100.0
        return String(format: "~$%.0f", dollars)
    }
}

extension AssessmentRecommendedTaskRow: Equatable, Hashable {
    static func == (lhs: AssessmentRecommendedTaskRow, rhs: AssessmentRecommendedTaskRow) -> Bool {
        lhs.id == rhs.id && lhs.updatedAt == rhs.updatedAt
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Foundational pre-visit form data

/// Phase 84.5 — the 7 universal questions every homeowner answers
/// regardless of onboarding path. Persists to
/// `properties.house_quiz_state.answers` so the existing reconciler
/// reads them as if they came from the quiz.
struct FoundationalAnswers: Codable, Equatable {
    /// Q28 family composition — couple / family_with_kids / multi_generational / just_me / other
    var householdType: String?
    var spouseFirstName: String?
    var spouseLastName: String?
    var children: [FoundationalChild]
    var hasPets: Bool
    var expecting: Bool

    /// Q30 priorities — one of: financial / safety / aesthetic / minimal_effort
    var topPriority: String?

    /// Q36 vendor preference tier — diy / mixed / hire_out
    var preferenceTier: String?

    /// Q24 vehicles — VINs and basic info
    var vehicles: [FoundationalVehicle]

    /// Q26 insurance carriers
    var autoInsuranceCarrier: String?
    var homeInsuranceCarrier: String?

    /// Q18 trash days (ISO 8601 weekday: 1=Sun ... 7=Sat)
    var trashPickupDays: [Int]

    /// G31 — only relevant for the handyman path.
    var willBeHomeForVisit: Bool
    var accessInstructions: String?

    init() {
        self.householdType = nil
        self.spouseFirstName = nil
        self.spouseLastName = nil
        self.children = []
        self.hasPets = false
        self.expecting = false
        self.topPriority = nil
        self.preferenceTier = nil
        self.vehicles = []
        self.autoInsuranceCarrier = nil
        self.homeInsuranceCarrier = nil
        self.trashPickupDays = []
        self.willBeHomeForVisit = true
        self.accessInstructions = nil
    }
}

struct FoundationalChild: Codable, Equatable, Hashable {
    var firstName: String
    var birthYear: Int?
}

struct FoundationalVehicle: Codable, Equatable, Hashable {
    var vin: String?
    var year: Int?
    var make: String?
    var model: String?
}

// `AssessmentMode` lives in DatabaseModels.swift. The mode-fork screen
// resolves "I'll finish setting up" → `.diy` (self-onboard) and
// "Send a Chez handyman" → `.handyman` (concierge-onboard). Phase 84's
// group toggles handle ongoing operating delegation independently.
