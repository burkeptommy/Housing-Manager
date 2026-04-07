import SwiftUI

@MainActor
final class HouseQuizViewModel: ObservableObject {
    let property: PropertyRow
    let allQuestions: [HouseQuizQuestion]

    @Published var state: HouseQuizState
    @Published var currentIndex: Int = 0
    @Published var pendingFeedback: AnswerFeedback?
    @Published var showMilestoneCard: Bool = false
    @Published var showSkipForeverConfirm: Bool = false
    @Published var isSaving: Bool = false
    @Published var providerCaptureForAnswerId: String?
    @Published var providerCaptureText: String = ""

    /// Phase 17b — running totals from `MaintenanceTaskReconciler`. Each
    /// answer that touches a system subtype merges its result into this; the
    /// final `runFinalReconciliation()` pass after the last question merges
    /// the orphan/whole-property cleanup. The completion view reads this to
    /// show "we added X, removed Y" with REAL numbers, never fakes them.
    @Published var reconciliationTotals: MaintenanceTaskReconciler.ReconciliationResult = .empty
    /// Set to `true` after `runFinalReconciliation()` finishes so the
    /// completion view can swap from a brief loading caption to the real
    /// summary. Defaults to `false` so an unfinished quiz never shows stale
    /// numbers.
    @Published var finalReconciliationDidRun: Bool = false

    /// Phase 16c — when the user picks an auto carrier that also offers home
    /// insurance (per `bundles_with_home`), we stash the row here so the q27
    /// render can show a "Looks like {name} also does home" suggestion card
    /// instead of forcing a duplicate search.
    @Published var bundledHomeSuggestion: UtilityProviderRow?
    /// Mirror flow for the reverse direction: if the user somehow answers q27
    /// before q26, the home carrier with `bundles_with_auto` becomes the
    /// suggestion shown above q26's auto picker.
    @Published var bundledAutoSuggestion: UtilityProviderRow?

    private let mapper: HouseQuizAnswerMapper
    private let db = DatabaseService.shared

    init(property: PropertyRow) {
        self.property = property
        self.allQuestions = HouseQuizQuestionLibrary.allQuestions
        self.state = property.houseQuizState ?? HouseQuizState(startedAt: Date())
        self.mapper = HouseQuizAnswerMapper(householdId: property.householdId, propertyId: property.id)

        // Resume at the first unanswered+unsaved+unskipped question.
        self.currentIndex = firstUnresolvedIndex()
    }

    // MARK: - Derived

    var currentQuestion: HouseQuizQuestion? {
        guard currentIndex >= 0, currentIndex < allQuestions.count else { return nil }
        return allQuestions[currentIndex]
    }

    var progress: Double {
        let total = allQuestions.count - state.skipped.count
        guard total > 0 else { return 1 }
        let answered = state.answers.count
        return min(1.0, Double(answered) / Double(total))
    }

    var progressLabel: String {
        let answered = state.answers.count
        let saved = state.savedForLater.count
        let parts: [String] = [
            "\(answered) of \(allQuestions.count) done",
            saved > 0 ? "\(saved) saved for later" : nil,
        ].compactMap { $0 }
        return parts.joined(separator: " · ")
    }

    var isAtMilestone: Bool {
        HouseQuizQuestionLibrary.milestoneIndices.contains(currentIndex - 1)
    }

    var isComplete: Bool {
        state.completedAt != nil
    }

    // MARK: - Actions

    /// Persist a single-choice or yes/no answer and advance.
    func recordAnswer(_ answerId: String, customText: String? = nil) async {
        guard let q = currentQuestion else { return }
        let answer = HouseQuizAnswer(
            answerId: answerId,
            customText: customText,
            selectedIds: nil,
            answeredAt: Date()
        )
        await persist(answer: answer, for: q)

        // Show feedback if available; otherwise advance.
        if let fb = HouseQuizFeedbackLibrary.feedback(for: q.id, answerId: answerId) {
            pendingFeedback = fb
            Analytics.track(.quizFeedbackShown, [
                "question_id": q.id,
                "answer_id": answerId,
            ])
        } else {
            advance()
        }
    }

    /// Phase 16c — variant that captures the full provider row alongside the
    /// answer. Lets us inspect bundle flags for auto/home insurance questions
    /// so q27 (home) can pre-fill from a q26 (auto) selection and vice versa.
    ///
    /// Phase 18e — also persists the catalog `provider.id` on the answer so
    /// the answer mapper can re-fetch the full record (logo, brand color,
    /// website, phone) at apply time and snapshot it onto the resulting
    /// utility_account row.
    func recordProviderAnswer(provider: UtilityProviderRow) async {
        guard let q = currentQuestion else { return }
        // Insurance bundle hint plumbing happens BEFORE persist so the q27
        // render after persist's advance() can read the flag immediately.
        switch q.id {
        case "q26_auto_insurance":
            if provider.bundlesWithHome == true {
                bundledHomeSuggestion = provider
            } else {
                bundledHomeSuggestion = nil
            }
        case "q27_homeowners_insurance":
            if provider.bundlesWithAuto == true {
                bundledAutoSuggestion = provider
            } else {
                bundledAutoSuggestion = nil
            }
        default:
            break
        }
        let answer = HouseQuizAnswer(
            answerId: "selected",
            customText: provider.name,
            selectedProviderId: provider.id,
            answeredAt: Date()
        )
        await persist(answer: answer, for: q)
        if let fb = HouseQuizFeedbackLibrary.feedback(for: q.id, answerId: "selected") {
            pendingFeedback = fb
            Analytics.track(.quizFeedbackShown, [
                "question_id": q.id,
                "answer_id": "selected",
            ])
        } else {
            advance()
        }
    }

    /// Phase 16c — user accepts the bundled suggestion at q27 (or q26 in the
    /// reverse case). Records the answer with the suggested provider's name
    /// and clears the suggestion so it doesn't bleed into a future quiz pass.
    func acceptBundledSuggestion() async {
        guard let q = currentQuestion else { return }
        let suggestion: UtilityProviderRow?
        switch q.id {
        case "q27_homeowners_insurance":
            suggestion = bundledHomeSuggestion
        case "q26_auto_insurance":
            suggestion = bundledAutoSuggestion
        default:
            suggestion = nil
        }
        guard let provider = suggestion else { return }
        bundledHomeSuggestion = nil
        bundledAutoSuggestion = nil
        await recordAnswer("selected", customText: provider.name)
    }

    /// Phase 16c — user rejected the bundled suggestion. Clear it so the
    /// regular search picker takes over without re-rendering the card.
    func dismissBundledSuggestion() {
        bundledHomeSuggestion = nil
        bundledAutoSuggestion = nil
    }

    /// Persist a multi-select answer and advance. `customEntries` carries any
    /// free-form values typed into an "Other"-style option (e.g. q10 appliances
    /// where users can add Sauna, Pellet stove, etc).
    func recordMultiSelect(_ ids: [String], customEntries: [String]? = nil) async {
        guard let q = currentQuestion else { return }
        let answer = HouseQuizAnswer(
            answerId: nil,
            customText: nil,
            selectedIds: ids,
            customEntries: customEntries,
            answeredAt: Date()
        )
        await persist(answer: answer, for: q)
        advance()
    }

    /// Phase 16d — Q28 specific: persist the household answer along with the
    /// kids and expecting entries captured by QuizKidsInlineForm. Caretakers
    /// already flow through `recordMultiSelect` after the inline form
    /// completes — this method only captures the residents type plus the
    /// kid/expecting payload, since those create real family_member rows.
    func recordHouseholdAnswer(
        residentsId: String,
        kids: [QuizKidEntry],
        expecting: [QuizExpectingEntry]
    ) async {
        guard let q = currentQuestion else { return }
        let answer = HouseQuizAnswer(
            answerId: residentsId,
            customText: nil,
            selectedIds: nil,
            customEntries: nil,
            kids: kids.isEmpty ? nil : kids,
            expectingEntries: expecting.isEmpty ? nil : expecting,
            answeredAt: Date()
        )
        await persist(answer: answer, for: q)
        advance()
    }

    /// Persist a currency-style answer (purchase price) and advance.
    func recordCurrencyAnswer(answerId: String, amount: Double) async {
        guard let q = currentQuestion else { return }
        let answer = HouseQuizAnswer(
            answerId: answerId,
            customText: String(Int(amount)),
            selectedIds: nil,
            answeredAt: Date()
        )
        await persist(answer: answer, for: q)
        advance()
    }

    /// Save the current question for later — appears in the dashboard
    /// "X saved questions" hint and resurfaces next launch.
    func saveForLater() {
        guard let q = currentQuestion else { return }
        if !state.savedForLater.contains(q.id) {
            state.savedForLater.append(q.id)
        }
        Analytics.track(.quizSavedForLater, ["question_id": q.id])
        Task { await persistState() }
        advance()
    }

    /// Skip forever — never resurface, user will add the data manually.
    func skipForever() {
        guard let q = currentQuestion else { return }
        if !state.skipped.contains(q.id) {
            state.skipped.append(q.id)
        }
        // Remove from savedForLater if present.
        state.savedForLater.removeAll { $0 == q.id }
        Analytics.track(.quizSkippedForever, ["question_id": q.id])
        Task { await persistState() }
        advance()
    }

    /// Dismiss the inline feedback card and advance to the next question.
    func dismissFeedback() {
        pendingFeedback = nil
        advance()
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        pendingFeedback = nil
    }

    func skipQuestionsAfterZeroVehicles() {
        // If user picked "0 cars" on Q23, skip Q24 (vehicle add) automatically.
        guard let q = currentQuestion, q.id == "q24_vehicle_add" else { return }
        if let prior = state.answers["q23_vehicle_count"], prior.answerId == "0" {
            state.skipped.append("q24_vehicle_add")
            advance()
        }
    }

    // MARK: - Internals

    private func persist(answer: HouseQuizAnswer, for question: HouseQuizQuestion) async {
        isSaving = true
        defer { isSaving = false }

        // 1. Update local state immediately.
        state.answers[question.id] = answer
        state.savedForLater.removeAll { $0 == question.id }
        state.skipped.removeAll { $0 == question.id }

        // 2. Fire the answer mapper for DB side-effects. Capture any
        //    reconciler changes so the completion summary can show real
        //    numbers without faking them.
        let result = await mapper.apply(question: question, answer: answer)
        if !result.isEmpty {
            reconciliationTotals = reconciliationTotals.merging(result)
        }

        // 3. Persist quiz state JSONB.
        await persistState()

        // 4. Phase 17b — once the user has answered everything, run a
        //    full-property reconcile pass to catch any system whose subtype
        //    was inferred from sibling answers but never directly confirmed,
        //    plus orphaned legacy tasks. Notification posts so the dashboard
        //    refreshes its task counts.
        if state.completedAt != nil && !finalReconciliationDidRun {
            await runFinalReconciliation()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }

        Analytics.track(.quizQuestionAnswered, [
            "question_id": question.id,
            "section": question.section.rawValue,
        ])
    }

    private func persistState() async {
        // Mark complete if every non-skipped question has an answer.
        let total = allQuestions.count - state.skipped.count
        if state.answers.count >= total, total > 0, state.completedAt == nil {
            state.completedAt = Date()
            Analytics.track(.quizCompleted)
        }

        var update = PropertyUpdate()
        update.houseQuizState = state
        do {
            _ = try await db.updateProperty(id: property.id, update)
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
        } catch {
            print("[HouseQuizViewModel] Failed to persist quiz state: \(error)")
        }
    }

    /// Phase 17b — runs `MaintenanceTaskReconciler.reconcileAll` on the
    /// quiz's property, merges the result into `reconciliationTotals`, and
    /// flips `finalReconciliationDidRun` so the completion view can render
    /// its real-numbers summary. Idempotent: subsequent calls are no-ops
    /// because of the flag check in `persist`.
    private func runFinalReconciliation() async {
        let result = await MaintenanceTaskReconciler.reconcileAll(
            propertyId: property.id,
            householdId: property.householdId
        )
        if !result.isEmpty {
            reconciliationTotals = reconciliationTotals.merging(result)
        }
        finalReconciliationDidRun = true
    }

    private func advance() {
        // Show milestone card after questions 5, 10, 15, 20, 25, 30.
        if HouseQuizQuestionLibrary.milestoneIndices.contains(currentIndex) {
            showMilestoneCard = true
            return
        }
        moveNext()
    }

    func dismissMilestoneAndContinue() {
        showMilestoneCard = false
        moveNext()
    }

    private func moveNext() {
        currentIndex += 1
        skipQuestionsAfterZeroVehicles()
    }

    private func firstUnresolvedIndex() -> Int {
        for (index, q) in allQuestions.enumerated() {
            if state.answers[q.id] == nil
                && !state.skipped.contains(q.id) {
                return index
            }
        }
        return allQuestions.count
    }
}
