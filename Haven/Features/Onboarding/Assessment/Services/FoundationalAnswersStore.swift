import Foundation

/// Phase 95 (audit gap #8) — read/write helper for foundational
/// answers, lifted out of `OnboardingViewModel` so the Settings
/// "Home details" entry can reuse the canonical persist path
/// without instantiating an onboarding view model.
///
/// Persists the same `properties.house_quiz_state.answers` map the
/// onboarding flow does, so the reconciler reads the answers as if
/// they came from the quiz regardless of which surface captured
/// them. Reading is the inverse — the same JSONB blob decoded back
/// into a `FoundationalAnswers` struct so the form can pre-fill.
enum FoundationalAnswersStore {

    /// Loads the user's persisted foundational answers from the
    /// property's `house_quiz_state.answers` map. Returns nil when
    /// nothing has been answered yet so the form starts empty.
    static func load(propertyId: UUID) async -> FoundationalAnswers? {
        guard let property = try? await DatabaseService.shared.fetchProperty(id: propertyId),
              let state = property.houseQuizState else {
            return nil
        }
        let answers = state.answers
        var result = FoundationalAnswers()
        var captured = false

        if let q28 = answers["q28_household"] {
            result.householdType = q28.answerId
            if let pets = q28.payload?["has_pets"] {
                result.hasPets = pets == "yes"
            }
            if let expecting = q28.payload?["expecting"] {
                result.expecting = expecting == "yes"
            }
            captured = true
        }
        if let q30 = answers["q30_priorities"] {
            result.topPriority = q30.answerId
            captured = true
        }
        if let q36 = answers["q36_diy_vs_vendor"] {
            result.preferenceTier = q36.answerId
            captured = true
        }
        if let q26 = answers["q26_insurance"] {
            result.autoInsuranceCarrier = q26.payload?["autoCarrier"]?.nonEmptyTrimmed
            result.homeInsuranceCarrier = q26.payload?["homeCarrier"]?.nonEmptyTrimmed
            captured = true
        }
        if let q18 = answers["q18_trash"], let raw = q18.payload?["days"] {
            result.trashPickupDays = raw
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            captured = true
        }
        return captured ? result : nil
    }

    /// Stamps the foundational answers back into
    /// `house_quiz_state.answers`. Mirrors the onboarding-path
    /// persist logic exactly so reconciler reads stay identical
    /// across both entry points. Pet flag also writes to property
    /// attributes for reconciler gating.
    static func save(_ answers: FoundationalAnswers, propertyId: UUID) async {
        var quizState: HouseQuizState
        do {
            let property = try await DatabaseService.shared.fetchProperty(id: propertyId)
            quizState = property.houseQuizState ?? HouseQuizState.empty
        } catch {
            quizState = HouseQuizState.empty
        }

        var existingAnswers = quizState.answers
        if let householdType = answers.householdType {
            existingAnswers["q28_household"] = HouseQuizAnswer(answerId: householdType, payload: [
                "has_pets": answers.hasPets ? "yes" : "no",
                "expecting": answers.expecting ? "yes" : "no"
            ])
        }
        if let priority = answers.topPriority {
            existingAnswers["q30_priorities"] = HouseQuizAnswer(answerId: priority, payload: nil)
        }
        if let tier = answers.preferenceTier {
            existingAnswers["q36_diy_vs_vendor"] = HouseQuizAnswer(answerId: tier, payload: nil)
        }
        if answers.autoInsuranceCarrier != nil || answers.homeInsuranceCarrier != nil {
            existingAnswers["q26_insurance"] = HouseQuizAnswer(
                answerId: "captured",
                payload: [
                    "autoCarrier": answers.autoInsuranceCarrier ?? "",
                    "homeCarrier": answers.homeInsuranceCarrier ?? ""
                ]
            )
        }
        if !answers.trashPickupDays.isEmpty {
            existingAnswers["q18_trash"] = HouseQuizAnswer(
                answerId: "captured",
                payload: ["days": answers.trashPickupDays.map(String.init).joined(separator: ",")]
            )
        }

        quizState.answers = existingAnswers

        _ = try? await DatabaseService.shared.updateProperty(
            id: propertyId,
            PropertyUpdate(houseQuizState: quizState)
        )

        if answers.hasPets {
            _ = try? await DatabaseService.shared.updatePropertyAttribute(
                propertyId: propertyId,
                key: "has_pets",
                value: .string("true")
            )
        }
    }
}

private extension String {
    var nonEmptyTrimmed: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
