import Foundation
import Supabase

/// Central service for estate planning state. Owns fetch, upsert,
/// concern ratings, intake answers, readiness score, and staleness.
/// Singleton following the `DatabaseService.shared` pattern.
@MainActor
final class EstateStateService: ObservableObject {
    static let shared = EstateStateService()

    @Published var estateState: EstateStateRow?

    private init() {}

    private func from(_ table: String) -> PostgrestQueryBuilder {
        HavenSupabase.from(table)
    }

    // MARK: - CRUD

    func fetch(householdId: UUID) async throws -> EstateStateRow? {
        let rows: [EstateStateRow] = try await from("estate_state")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .execute()
            .value
        let row = rows.first
        estateState = row
        return row
    }

    func upsert(_ update: EstateStateUpdate, householdId: UUID) async throws {
        // Try update first; if no rows affected, insert then update
        let existing = try await fetch(householdId: householdId)
        if existing != nil {
            try await from("estate_state")
                .update(update)
                .eq("household_id", value: householdId.uuidString)
                .execute()
        } else {
            // Insert a blank row, then apply the update
            let insert = EstateStateInsert(householdId: householdId)
            try await from("estate_state")
                .insert(insert)
                .execute()
            try await from("estate_state")
                .update(update)
                .eq("household_id", value: householdId.uuidString)
                .execute()
        }
        // Refresh local state
        _ = try await fetch(householdId: householdId)
    }

    /// Ensure an estate_state row exists for this household, creating one
    /// with defaults if needed. Returns the row.
    @discardableResult
    func ensureExists(householdId: UUID) async throws -> EstateStateRow {
        if let existing = try await fetch(householdId: householdId) {
            return existing
        }
        let insert = EstateStateInsert(householdId: householdId)
        let row: EstateStateRow = try await from("estate_state")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        estateState = row
        return row
    }

    // MARK: - Concern Ratings

    /// Record a single concern rating. Merges into the existing concerns
    /// array, replacing any prior rating for the same concern_id.
    func recordConcernRating(householdId: UUID, concernId: String, rating: String) async throws {
        let state = try await ensureExists(householdId: householdId)
        var concerns = state.concerns ?? []

        // Remove existing rating for this concern
        concerns.removeAll { $0.concernId == concernId }

        let formatter = ISO8601DateFormatter()
        let newRating = EstateConcernRating(
            concernId: concernId,
            rating: rating,
            ratedAt: formatter.string(from: Date())
        )
        concerns.append(newRating)

        var update = EstateStateUpdate()
        update.concerns = concerns
        try await from("estate_state")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
        _ = try await fetch(householdId: householdId)
    }

    // MARK: - Intake Answers

    /// Record a single intake answer. Same save-per-answer pattern as
    /// HouseQuizViewModel: read current intake_state, merge, write back.
    func recordIntakeAnswer(householdId: UUID, sectionId: String, answer: EstateIntakeAnswer) async throws {
        let state = try await ensureExists(householdId: householdId)
        var intake = state.intakeState ?? EstateIntakeState()

        if intake.startedAt == nil {
            let formatter = ISO8601DateFormatter()
            intake.startedAt = formatter.string(from: Date())
        }
        intake.currentSection = sectionId

        var answers = intake.answers ?? [:]
        answers[sectionId] = answer
        intake.answers = answers

        var update = EstateStateUpdate()
        update.intakeState = intake
        try await from("estate_state")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
        _ = try await fetch(householdId: householdId)
    }

    /// Mark the intake as complete.
    func completeIntake(householdId: UUID) async throws {
        let state = try await ensureExists(householdId: householdId)
        var intake = state.intakeState ?? EstateIntakeState()
        let formatter = ISO8601DateFormatter()
        intake.completedAt = formatter.string(from: Date())

        var update = EstateStateUpdate()
        update.intakeState = intake
        try await from("estate_state")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
        _ = try await fetch(householdId: householdId)
    }

    // MARK: - Readiness Score

    /// Recompute the estate readiness score based on current state and
    /// household composition. Household-composition-aware: single people
    /// are not penalized for missing guardian, unmarried for missing
    /// second POA/health proxy.
    func recomputeReadinessScore(householdId: UUID, isMarried: Bool, hasMinors: Bool, hasMultipleProperties: Bool, netWorthBucket: String?) async throws -> Int {
        let state = try await ensureExists(householdId: householdId)

        var score = 0
        let maxScore: Int

        // Has will: +20
        if state.hasWill { score += 20 }

        // Has trust (relevant for HNW or multi-property): +15
        let trustRelevant = hasMultipleProperties || isHighNetWorth(netWorthBucket)
        if trustRelevant {
            if state.hasRevocableTrust || state.hasIrrevocableTrust { score += 15 }
        }

        // Has POA (per spouse if married): +15
        if state.hasPoa { score += 15 }

        // Has health proxy (per spouse if married): +15
        if state.hasHealthProxy { score += 15 }

        // Has living will: +5
        if state.hasLivingWill { score += 5 }

        // Linked attorney: +10
        if state.estateAttorneyContactId != nil { score += 10 }

        // No staleness: +10
        if state.stalenessTier == "none" { score += 10 }

        // Fiduciaries named for applicable roles: +10
        let fiduciaryScore = computeFiduciaryScore(
            fiduciaries: state.fiduciaries,
            nominations: state.nominations,
            hasMinors: hasMinors
        )
        score += fiduciaryScore

        // Max score depends on composition
        var possibleMax = 100
        if !trustRelevant { possibleMax -= 15 }

        maxScore = max(possibleMax, 1)
        let normalizedScore = min(100, (score * 100) / maxScore)

        var update = EstateStateUpdate()
        update.estateReadinessScore = normalizedScore
        try await from("estate_state")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
        _ = try await fetch(householdId: householdId)

        return normalizedScore
    }

    private func isHighNetWorth(_ bucket: String?) -> Bool {
        guard let bucket else { return false }
        return bucket != "<1M"
    }

    private func computeFiduciaryScore(fiduciaries: [EstateFiduciary]?, nominations: EstateNominations?, hasMinors: Bool) -> Int {
        let allFiduciaries = fiduciaries ?? []
        let hasExecutor = allFiduciaries.contains { $0.role == "executor" } || nominations?.executor?.primary != nil
        let hasTrustee = allFiduciaries.contains { $0.role == "trustee" } || nominations?.trustee?.primary != nil
        let hasHealthProxy = allFiduciaries.contains { $0.role == "health_proxy" } || nominations?.healthProxy?.primary != nil
        let hasPoaAgent = allFiduciaries.contains { $0.role == "poa_agent" } || nominations?.poaAgent?.primary != nil
        let hasGuardian = allFiduciaries.contains { $0.role == "guardian" } || nominations?.guardian?.primary != nil

        var filled = 0
        var applicable = 0

        // Executor is always applicable
        applicable += 1
        if hasExecutor { filled += 1 }

        // Trustee applicable if trust exists
        if (estateState?.hasRevocableTrust ?? false) || (estateState?.hasIrrevocableTrust ?? false) {
            applicable += 1
            if hasTrustee { filled += 1 }
        }

        // Health proxy always applicable
        applicable += 1
        if hasHealthProxy { filled += 1 }

        // POA agent always applicable
        applicable += 1
        if hasPoaAgent { filled += 1 }

        // Guardian only applicable if minor children
        if hasMinors {
            applicable += 1
            if hasGuardian { filled += 1 }
        }

        guard applicable > 0 else { return 10 }
        return (filled * 10) / applicable
    }

    // MARK: - Staleness

    /// Compute staleness tier and reasons from estate state and household
    /// composition. Returns the tier and an array of human-readable reasons.
    ///
    /// - Info (3yr): docs are aging, no life changes
    /// - Amber (5yr OR life changes post-execution): time to review
    /// - Critical (7yr OR major events OR 2026 TCJA sunset): urgent review needed
    func computeStaleness(estateState: EstateStateRow, memberCount: Int, propertyCount: Int, vehicleCount: Int) -> (tier: String, reasons: [String]) {
        var reasons: [String] = []
        var tier = "none"

        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Check each document date for age
        let datePairs: [(String, String?)] = [
            ("Will", estateState.willDate),
            ("Trust", estateState.trustDate),
            ("Power of Attorney", estateState.poaDate),
            ("Healthcare Proxy", estateState.healthProxyDate),
        ]

        for (docName, dateStr) in datePairs {
            guard let dateStr, let docDate = dateFormatter.date(from: dateStr) else { continue }
            let years = calendar.dateComponents([.year], from: docDate, to: now).year ?? 0

            if years >= 7 {
                reasons.append("\(docName) is \(years) years old")
                tier = "critical"
            } else if years >= 5 {
                reasons.append("\(docName) is \(years) years old")
                if tier != "critical" { tier = "amber" }
            } else if years >= 3 {
                reasons.append("\(docName) is \(years) years old")
                if tier == "none" { tier = "info" }
            }
        }

        // 2026 TCJA sunset check
        let currentYear = calendar.component(.year, from: now)
        if currentYear >= 2025 {
            let hasHighNetWorth = isHighNetWorth(estateState.assetsSummary?.netWorthBucket)
            if hasHighNetWorth {
                reasons.append("2026 tax law changes may affect your estate plan")
                if tier != "critical" { tier = "amber" }
            }
        }

        // Snapshot comparison for life changes (if we have a previous snapshot)
        if let snapshot = estateState.householdSnapshot {
            let prevMembers = snapshot.memberCount ?? 0
            let prevProperties = snapshot.propertyCount ?? 0
            let prevVehicles = snapshot.vehicleCount ?? 0

            if memberCount > prevMembers {
                reasons.append("New family members added since last review")
                if tier == "none" || tier == "info" { tier = "amber" }
            }
            if propertyCount > prevProperties {
                reasons.append("New property added since last review")
                if tier == "none" || tier == "info" { tier = "amber" }
            }
            if vehicleCount > prevVehicles && vehicleCount > prevVehicles + 1 {
                // Only flag significant vehicle changes (2+)
                reasons.append("Significant vehicle changes since last review")
                if tier == "none" { tier = "info" }
            }
        }

        return (tier: tier, reasons: reasons)
    }

    // MARK: - Auto-Populate

    /// Pre-fill estate intake fields from existing household data.
    /// Returns (number of fields auto-filled, total fields checked).
    func autoPopulateFromHousehold(householdId: UUID) async throws -> (answeredCount: Int, totalCount: Int) {
        let db = DatabaseService.shared

        // Fetch household data in parallel (RLS scopes to current user's household)
        async let membersTask = db.fetchFamilyMembers(householdId: householdId)
        async let propertiesTask = db.fetchProperties()
        async let vehiclesTask = db.fetchVehicles()
        async let contactsTask = db.fetchTrustedContacts()

        let members = (try? await membersTask) ?? []
        let properties = (try? await propertiesTask) ?? []
        let vehicles = (try? await vehiclesTask) ?? []
        let contacts = (try? await contactsTask) ?? []

        var answered = 0
        let total = 6 // household, advisors, assets (the auto-fillable sections)

        // Build assets summary from existing data
        let assetsSummary = EstateAssetsSummary(
            realEstateCount: properties.count > 0 ? properties.count : nil,
            vehicleCount: vehicles.count > 0 ? vehicles.count : nil,
            businessCount: nil,
            financialAccountsCount: nil,
            lifeInsuranceCount: nil,
            netWorthBucket: nil
        )

        if properties.count > 0 || vehicles.count > 0 {
            answered += 1
        }

        // Check for estate attorney in trusted contacts
        let estateAttorney = contacts.first { $0.role.lowercased().contains("attorney") || $0.role.lowercased().contains("estate") }

        // Build household snapshot
        let snapshot = EstateHouseholdSnapshot(
            memberCount: members.count,
            propertyCount: properties.count,
            vehicleCount: vehicles.count,
            snapshotDate: ISO8601DateFormatter().string(from: Date())
        )

        if members.count > 0 { answered += 1 }
        if estateAttorney != nil { answered += 1 }

        var update = EstateStateUpdate()
        update.assetsSummary = assetsSummary
        update.householdSnapshot = snapshot
        if let attorney = estateAttorney {
            update.estateAttorneyContactId = attorney.id
        }

        try await upsert(update, householdId: householdId)

        return (answeredCount: answered, totalCount: total)
    }

    // MARK: - Core Seven Estate Documents (Build 89)

    /// One row in the canonical "core seven" estate document checklist.
    /// `present` reflects whether the corresponding `estate_state.has_*`
    /// boolean flag is true. Used by `EstateOverviewCard` and
    /// `EstateSnapshotView` to render "what's on file" / "what's missing"
    /// breakdowns without each callsite having to know the field mapping.
    struct CoreEstateDoc: Identifiable {
        let label: String
        let key: String
        let present: Bool
        var id: String { key }
    }

    /// Returns the seven canonical estate documents Haven tracks for
    /// readiness scoring (Will, Revocable Trust, Irrevocable Trust, POA,
    /// Healthcare Proxy, Living Will, HIPAA Authorization). Pass nil to
    /// get the empty checklist (all `present = false`) when no
    /// `estate_state` row exists yet.
    static func coreSevenDocs(in state: EstateStateRow?) -> [CoreEstateDoc] {
        [
            CoreEstateDoc(label: "Will", key: "has_will", present: state?.hasWill ?? false),
            CoreEstateDoc(label: "Revocable Trust", key: "has_revocable_trust", present: state?.hasRevocableTrust ?? false),
            CoreEstateDoc(label: "Irrevocable Trust", key: "has_irrevocable_trust", present: state?.hasIrrevocableTrust ?? false),
            CoreEstateDoc(label: "Power of Attorney", key: "has_poa", present: state?.hasPoa ?? false),
            CoreEstateDoc(label: "Healthcare Proxy", key: "has_health_proxy", present: state?.hasHealthProxy ?? false),
            CoreEstateDoc(label: "Living Will", key: "has_living_will", present: state?.hasLivingWill ?? false),
            CoreEstateDoc(label: "HIPAA Authorization", key: "has_hipaa_auth", present: state?.hasHipaaAuth ?? false),
        ]
    }

    // MARK: - Document Presence Flags

    /// Map a document category string to the corresponding estate_state
    /// boolean flag name, if any. Returns nil for non-estate categories.
    /// Pass `estateSubType` from AI extraction to distinguish revocable vs irrevocable trusts.
    static func presenceFlagKey(for category: String, estateSubType: String? = nil) -> String? {
        switch category.lowercased() {
        case "will": return "hasWill"
        case "trust":
            if let subType = estateSubType?.lowercased(), subType.contains("irrevocable") {
                return "hasIrrevocableTrust"
            }
            return "hasRevocableTrust"
        case "power of attorney": return "hasPoa"
        case "healthcare directive", "healthcare proxy": return "hasHealthProxy"
        case "living will": return "hasLivingWill"
        case "hipaa authorization": return "hasHipaaAuth"
        case "pre-nuptial agreement": return "hasPrenup"
        case "post-nuptial agreement": return "hasPrenup"
        case "disposition of remains": return "hasDispositionOfRemains"
        case "guardianship designation": return nil // tracked via fiduciaries
        case "letter of intent": return nil // tracked via wishes
        case "deed in trust": return nil // tracked via trust flag
        case "buy-sell agreement", "succession plan": return "hasBusinessAgreement"
        default: return nil
        }
    }

    /// Update the appropriate presence flag on estate_state when a
    /// document of the given category is uploaded/analyzed.
    func markDocumentPresent(householdId: UUID, category: String, executionDate: String?) async throws {
        var update = EstateStateUpdate()

        switch category.lowercased() {
        case "will":
            update.hasWill = true
            if let date = executionDate { update.willDate = date }
        case "trust":
            update.hasRevocableTrust = true
            if let date = executionDate { update.trustDate = date }
        case "power of attorney":
            update.hasPoa = true
            if let date = executionDate { update.poaDate = date }
        case "healthcare directive", "healthcare proxy":
            update.hasHealthProxy = true
            if let date = executionDate { update.healthProxyDate = date }
        case "living will":
            update.hasLivingWill = true
        case "hipaa authorization":
            update.hasHipaaAuth = true
        case "pre-nuptial agreement", "post-nuptial agreement":
            update.hasPrenup = true
        case "disposition of remains":
            update.hasDispositionOfRemains = true
        case "buy-sell agreement", "succession plan":
            update.hasBusinessAgreement = true
        case "deed in trust":
            // Deed in trust implies a trust exists
            update.hasRevocableTrust = true
        default:
            return // Not an estate category
        }

        try await upsert(update, householdId: householdId)
    }
}
